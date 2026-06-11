# Alleral Telemetry Relay v3

Server-side Discord webhook proxy. Clients never see your webhook URL.

## Run locally

```bash
cp .env.example .env   # fill DISCORD_WEBHOOK_URL + TELEMETRY_API_KEY
pip install -r requirements.txt
python telemetry_relay.py
```

## Deploy (Railway)

1. New project → deploy from `backend/` (uses `Dockerfile` + `railway.toml`)
2. Set env vars from `.env.example`
3. Use `https://YOUR-APP.up.railway.app/ingest` in `config/owner_telemetry.luau`

## Endpoints

| Method | Path | Auth |
|--------|------|------|
| GET | `/health` | None |
| POST | `/ingest` | Header `X-Alleral-Key` |
| GET | `/scripts` | None (public manifest for loader) |
| GET | `/scripts/<id>` | None |
| PATCH | `/scripts/<id>` | Header `X-Admin-Key` |
| GET | `/admin` | None (browser UI; saves require admin key) |

Returns `202 Accepted` on ingest — work is queued so bursts don't drop events.

## Script status admin

1. Open `https://YOUR-APP.up.railway.app/admin`
2. Paste `ADMIN_API_KEY` from `.env` (defaults to `TELEMETRY_API_KEY` if unset)
3. Set status: `working`, `detected`, `broken`, `maintenance`, or `testing`
4. Loader + in-game UI read from `GET /scripts` (GitHub manifest is fallback)

Manifest file: `config/scripts_manifest.json` (override path with `SCRIPTS_MANIFEST_PATH`).

## Scale defaults

- Queue: 5000 events
- Discord: ~1 post / 0.55s with retry on 429
- Heartbeats: batched every 90s into one embed
- Per-IP: 120 requests/min

See [../config/WEBHOOK_SETUP.md](../config/WEBHOOK_SETUP.md) for the full guide.
