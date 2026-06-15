package main

import (
	"log"
	"net/http"
	"os"
	"path/filepath"
	"strings"

	"github.com/go-chi/chi/v5"
	"github.com/go-chi/chi/v5/middleware"
	"github.com/go-chi/cors"

	"github.com/evanbackup1256-ship-it/kick/go/internal/api"
	"github.com/evanbackup1256-ship-it/kick/go/internal/config"
)

func main() {
	cfg := config.Load()
	srv := api.New(cfg)

	r := chi.NewRouter()
	r.Use(middleware.RequestID)
	r.Use(middleware.RealIP)
	r.Use(middleware.Logger)
	r.Use(middleware.Recoverer)
	r.Use(cors.Handler(cors.Options{
		AllowedOrigins:   []string{"*"},
		AllowedMethods:   []string{"GET", "POST", "PUT", "PATCH", "DELETE", "OPTIONS"},
		AllowedHeaders:   []string{"Accept", "Authorization", "Content-Type", "X-Requested-With"},
		AllowCredentials: false,
		MaxAge:           300,
	}))

	r.Get("/health", srv.Health)

	r.Route("/api", func(r chi.Router) {
		r.Get("/health", srv.Health)
		r.Get("/site", srv.Site)
		r.Get("/live/status", srv.LiveStatus)
		r.Get("/sync/status", srv.SyncStatus)
		r.Post("/hub/visit", srv.HubVisit)

		if cfg.PythonUpstream != "" {
			proxy := srv.ProxyPython(cfg.PythonUpstream)
			r.Handle("/", proxy)
			r.Handle("/*", proxy)
		} else {
			r.NotFound(srv.ApiNotFound)
		}
	})

	if cfg.PythonUpstream != "" {
		proxy := srv.ProxyPython(cfg.PythonUpstream)
		r.Handle("/ingest", proxy)
		r.Handle("/ingest/*", proxy)
		r.Handle("/gate/*", proxy)
		r.Handle("/scripts", proxy)
		r.Handle("/scripts/*", proxy)
		r.Handle("/admin/bans", proxy)
		r.Handle("/admin/bans/*", proxy)
	}

	fileServer := spaFileServer(cfg.SiteDir)
	r.Handle("/*", fileServer)

	log.Printf("Alleral Go relay listening on %s (site=%s python=%q)", cfg.Addr, cfg.SiteDir, cfg.PythonUpstream)
	if err := http.ListenAndServe(cfg.Addr, r); err != nil {
		log.Fatal(err)
	}
}

func spaFileServer(root string) http.Handler {
	root = filepath.Clean(root)
	fs := http.FileServer(http.Dir(root))
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		if strings.HasPrefix(r.URL.Path, "/api/") || r.URL.Path == "/api" {
			w.Header().Set("Content-Type", "application/json")
			w.WriteHeader(http.StatusNotFound)
			_, _ = w.Write([]byte(`{"ok":false,"error":"api_not_found"}`))
			return
		}

		raw := strings.TrimPrefix(r.URL.Path, "/")
		raw = strings.TrimSuffix(raw, "/")
		if raw == "" {
			r.URL.Path = "/index.html"
			fs.ServeHTTP(w, r)
			return
		}

		// Legacy static HTML pages (admin.html, dev.html, manage.html)
		if !strings.Contains(raw, ".") {
			htmlPath := filepath.Join(root, raw+".html")
			if info, err := os.Stat(htmlPath); err == nil && !info.IsDir() {
				r.URL.Path = "/" + raw + ".html"
				fs.ServeHTTP(w, r)
				return
			}
		}

		full := filepath.Join(root, filepath.FromSlash(raw))
		if info, err := os.Stat(full); err == nil && !info.IsDir() {
			fs.ServeHTTP(w, r)
			return
		}

		indexNested := filepath.Join(root, raw, "index.html")
		if info, err := os.Stat(indexNested); err == nil && !info.IsDir() {
			r.URL.Path = "/" + raw + "/index.html"
			fs.ServeHTTP(w, r)
			return
		}

		r.URL.Path = "/index.html"
		fs.ServeHTTP(w, r)
	})
}
