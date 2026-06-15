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
	r.Get("/api/health", srv.Health)
	r.Get("/api/site", srv.Site)
	r.Get("/api/live/status", srv.LiveStatus)
	r.Get("/api/sync/status", srv.SyncStatus)
	r.Post("/api/hub/visit", srv.HubVisit)

	if cfg.PythonUpstream != "" {
		proxy := srv.ProxyPython(cfg.PythonUpstream)
		r.Handle("/ingest", proxy)
		r.Handle("/ingest/*", proxy)
		r.Handle("/api/telemetry", proxy)
		r.Handle("/api/telemetry/*", proxy)
		r.Handle("/api/support", proxy)
		r.Handle("/api/bug-report", proxy)
		r.Handle("/api/feature-request", proxy)
		r.Handle("/api/faq-feedback", proxy)
		r.Handle("/api/gate/*", proxy)
		r.Handle("/api/weao/*", proxy)
		r.Handle("/api/admin/*", proxy)
		r.Handle("/api/bootstrap", proxy)
		r.Handle("/api/games/*", proxy)
		r.Handle("/api/credits/*", proxy)
		r.Handle("/api/manage/*", proxy)
		r.Handle("/api/dev/*", proxy)
		r.Handle("/api/v1/*", proxy)
		r.Handle("/api/ban/check", proxy)
		r.Handle("/api/ban/status", proxy)
		r.Handle("/api/ban/roblox/*", proxy)
		r.Handle("/api/ban/*", proxy)
		r.Handle("/gate/*", proxy)
		r.Handle("/scripts", proxy)
		r.Handle("/scripts/*", proxy)
		r.Handle("/admin/bans", proxy)
		r.Handle("/admin/bans/*", proxy)
	}

	fileServer := spaFileServer(cfg.SiteDir)
	r.Handle("/*", fileServer)

	log.Printf("Alleral Go relay listening on %s (site=%s)", cfg.Addr, cfg.SiteDir)
	if err := http.ListenAndServe(cfg.Addr, r); err != nil {
		log.Fatal(err)
	}
}

func spaFileServer(root string) http.Handler {
	root = filepath.Clean(root)
	fs := http.FileServer(http.Dir(root))
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
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
