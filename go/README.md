# Alleral Go Relay

High-performance HTTP front for the Alleral hub: static site export, public JSON APIs, optional Python telemetry proxy.

## Run locally

```bash
cd go
go mod tidy
go run ./cmd/alleral
```

Environment:

| Variable | Default | Purpose |
|----------|---------|---------|
| `ALLERAL_ADDR` | `:8080` | Listen address |
| `ALLERAL_SITE_DIR` | `./site` | Next.js static export |
| `SITE_CONFIG_PATH` | `./site.json` | Public site payload |
| `RELEASE_CONFIG_PATH` | `./release.json` | Release manifest |
| `ALLERAL_PYTHON_UPSTREAM` | _(empty)_ | When set (e.g. `http://127.0.0.1:8081`), telemetry/support POST routes proxy to Python |

## Docker (Go + Python)

Set `ALLERAL_PYTHON_UPSTREAM=http://127.0.0.1:8081` and run Python gunicorn on 8081 alongside this binary on 8080.
