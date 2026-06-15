package config

import (
	"encoding/json"
	"os"
	"path/filepath"
)

type Config struct {
	Addr            string
	SiteDir         string
	SiteJSON        string
	ReleaseJSON     string
	ScriptsManifest string
	PythonUpstream  string
}

func Load() Config {
	cfg := Config{
		Addr:            env("ALLERAL_ADDR", ":8080"),
		SiteDir:         env("ALLERAL_SITE_DIR", "./site"),
		SiteJSON:        env("SITE_CONFIG_PATH", "./site.json"),
		ReleaseJSON:     env("RELEASE_CONFIG_PATH", "./release.json"),
		ScriptsManifest: env("SCRIPTS_MANIFEST_PATH", "./scripts_manifest.json"),
		PythonUpstream:  env("ALLERAL_PYTHON_UPSTREAM", ""),
	}
	return cfg
}

func env(key, fallback string) string {
	if v := os.Getenv(key); v != "" {
		return v
	}
	return fallback
}

func ReadJSON(path string, out any) error {
	raw, err := os.ReadFile(filepath.Clean(path))
	if err != nil {
		return err
	}
	return json.Unmarshal(raw, out)
}
