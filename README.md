# Alleral Hub

Roblox automation hub — one loader, five games, private owner telemetry.

**Supported games:** Kick a Lucky Block · Speed Keyboard Escape · Slime RNG · Build A Ring Farm · Survive a Zombie Arena

## Load Alleral

Join a supported game, paste this into your executor, and click **Execute**:

```lua
(getgenv().loadstring or loadstring or load)(game.HttpGet(game, "https://cdn.jsdelivr.net/gh/evanbackup1256-ship-it/kick@main/run.luau?t=" .. tick(), true))()
```

Save that line to your executor **Scripts** tab for one-click loading. No autoexec needed.

**Same session reload:** `Alleral_Load()` or `getgenv().Alleral_Reload()`

**Dev / local workspace:**

```lua
loadstring(readfile("loader.luau"))()
```

Debug: `getgenv().Alleral_LoaderInfo()`

## How it stays reliable

- `run.luau` tries 3 CDN mirrors and validates the download before running
- `load.luau` ships with the full loader embedded — stale CDN can’t brick startup
- Old `loader.luau` links auto-redirect through the same bootstrap chain

## Project layout

```
Alleral Hub/
├── run.luau                    # Player entry (paste or HttpGet this)
├── load.luau                   # Full bootstrap + embedded loader
├── loader.luau                 # Dev entry point
├── core/
│   ├── alleral_core.luau       # Rayfield UI, RoScripts, supervisors
│   ├── game_helpers.luau       # Shared combat/movement/remote helpers
│   ├── internal/               # Readable telemetry/analytics sources
│   ├── analytics.luau          # Protected (obfuscated) — do not edit
│   └── telemetry.luau          # Protected (obfuscated) — do not edit
├── config/
│   └── scripts_manifest.json   # Script status source (also served by relay /scripts)
├── games/
│   ├── kick_a_lucky_block.luau
│   ├── speed_keyboard_escape.luau
│   ├── slime_rng.luau
│   ├── build_a_ring_farm.luau
│   ├── survive_a_zombie_arena.luau
│   └── data/
│       └── kickblox.luau       # Kick brainrot name list
├── docs/
│   ├── ARCHITECTURE.md
│   ├── GAMES.md
│   ├── SECURITY.md
│   └── WEBHOOK_SETUP.md
├── config/
│   ├── owner_telemetry.example.luau
│   └── SECURITY.md             # Pointer → docs/
├── backend/
│   └── telemetry_relay.py      # Private Discord relay (host this)
├── tools/
```

## Owner webhook (secure)

**If others can read this folder**, read [docs/SECURITY.md](docs/SECURITY.md) first.

- Discord webhook → `backend/.env` on **your server only**
- Relay API key → `../Alleral-Private/owner_telemetry.luau` (**outside** shared hub)
- Before sharing: `powershell tools/prepare_distribution.ps1`

Setup: [docs/WEBHOOK_SETUP.md](docs/WEBHOOK_SETUP.md)

## Luxy sync (dev)

```bash
python tools/luxy_sync.py
python tools/luxy_sync.py --check
```

## Docs

- [Architecture](docs/ARCHITECTURE.md) — loader boot chain and path resolution
- [Games](docs/GAMES.md) — per-game feature summary
