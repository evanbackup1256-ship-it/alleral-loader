package api

import (
	"encoding/json"
	"io"
	"net/http"
	"strings"
	"time"

	"github.com/evanbackup1256-ship-it/kick/go/internal/config"
)

type Server struct {
	cfg config.Config
}

func New(cfg config.Config) *Server {
	return &Server{cfg: cfg}
}

func (s *Server) Health(w http.ResponseWriter, r *http.Request) {
	writeJSON(w, http.StatusOK, map[string]any{
		"ok":      true,
		"service": "alleral-go",
		"at":      time.Now().UTC().Format(time.RFC3339),
	})
}

func (s *Server) Site(w http.ResponseWriter, r *http.Request) {
	var site map[string]any
	if err := config.ReadJSON(s.cfg.SiteJSON, &site); err != nil {
		writeJSON(w, http.StatusInternalServerError, map[string]any{"ok": false, "error": "site_unavailable"})
		return
	}
	site["ok"] = true
	writeJSON(w, http.StatusOK, site)
}

func (s *Server) LiveStatus(w http.ResponseWriter, r *http.Request) {
	var site map[string]any
	if err := config.ReadJSON(s.cfg.SiteJSON, &site); err != nil {
		writeJSON(w, http.StatusInternalServerError, map[string]any{"ok": false, "error": "site_unavailable"})
		return
	}

	gamesRaw, _ := site["games"].(map[string]any)
	working := 0
	items := make([]map[string]any, 0)
	for gid, meta := range gamesRaw {
		game, ok := meta.(map[string]any)
		if !ok {
			continue
		}
		status := strings.ToLower(asString(game["status"], "working"))
		if status == "working" {
			working++
		}
		items = append(items, map[string]any{
			"id":      gid,
			"name":    firstNonEmpty(asString(game["name"], ""), gid),
			"status":  status,
			"version": game["version"],
			"message": game["message"],
		})
	}

	var release map[string]any
	_ = config.ReadJSON(s.cfg.ReleaseJSON, &release)

	writeJSON(w, http.StatusOK, map[string]any{
		"ok": true,
		"at": time.Now().UTC().Format(time.RFC3339),
		"versions": map[string]any{
			"loader":    site["loaderVersion"],
			"core":      site["coreVersion"],
			"ui":        site["uiLibrary"],
			"uiVersion": site["uiVersion"],
			"sydePatch": site["sydePatch"],
		},
		"release": map[string]any{
			"commit":    firstNonEmpty(asString(release["commit"], ""), asString(site["githubCommit"], "")),
			"branch":    "main",
			"updatedAt": firstNonEmpty(asString(site["updatedAt"], ""), asString(release["updatedAt"], "")),
		},
		"sync": map[string]any{
			"enabled":    true,
			"autoStatus": true,
			"lastSyncAt": site["updatedAt"],
		},
		"games": map[string]any{
			"total":   len(gamesRaw),
			"working": working,
			"items":   items,
		},
		"relay": map[string]any{
			"online":   true,
			"autoSync": true,
			"engine":   "go",
		},
	})
}

func (s *Server) SyncStatus(w http.ResponseWriter, r *http.Request) {
	var release map[string]any
	_ = config.ReadJSON(s.cfg.ReleaseJSON, &release)
	writeJSON(w, http.StatusOK, map[string]any{
		"ok":         true,
		"enabled":    true,
		"autoStatus": true,
		"commit":     release["commit"],
		"updatedAt":  release["updatedAt"],
		"engine":     "go",
	})
}

func (s *Server) HubVisit(w http.ResponseWriter, r *http.Request) {
	io.Copy(io.Discard, r.Body)
	writeJSON(w, http.StatusOK, map[string]any{"ok": true})
}

func (s *Server) ProxyPython(upstream string) http.Handler {
	target := strings.TrimRight(upstream, "/")
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		url := target + r.URL.Path
		if r.URL.RawQuery != "" {
			url += "?" + r.URL.RawQuery
		}
		req, err := http.NewRequestWithContext(r.Context(), r.Method, url, r.Body)
		if err != nil {
			writeJSON(w, http.StatusBadGateway, map[string]any{"ok": false, "error": "proxy_error"})
			return
		}
		for k, vals := range r.Header {
			for _, v := range vals {
				req.Header.Add(k, v)
			}
		}
		res, err := http.DefaultClient.Do(req)
		if err != nil {
			writeJSON(w, http.StatusBadGateway, map[string]any{"ok": false, "error": "upstream_unavailable"})
			return
		}
		defer res.Body.Close()
		for k, vals := range res.Header {
			for _, v := range vals {
				w.Header().Add(k, v)
			}
		}
		w.WriteHeader(res.StatusCode)
		io.Copy(w, res.Body)
	})
}

func writeJSON(w http.ResponseWriter, status int, payload any) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(status)
	_ = json.NewEncoder(w).Encode(payload)
}

func asString(v any, fallback string) string {
	if s, ok := v.(string); ok && s != "" {
		return s
	}
	return fallback
}

func firstNonEmpty(values ...string) string {
	for _, v := range values {
		if v != "" {
			return v
		}
	}
	return ""
}
