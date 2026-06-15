#!/bin/sh
set -e
PORT="${PORT:-8080}"
gunicorn -w 1 -b "127.0.0.1:8081" --timeout 120 telemetry_relay:app &
export ALLERAL_PYTHON_UPSTREAM=http://127.0.0.1:8081
export ALLERAL_ADDR="0.0.0.0:${PORT}"
export ALLERAL_SITE_DIR=/app/site
export SITE_CONFIG_PATH=/app/site.json
export RELEASE_CONFIG_PATH=/app/release.json
exec alleral
