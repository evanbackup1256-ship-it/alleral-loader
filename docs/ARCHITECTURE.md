# Alleral Architecture

## Boot chain

```
loader.luau (remote or readfile)
    ├── detect executor (identifyexecutor + WEAO when available)
    ├── detect game by PlaceId
    ├── download core/alleral_core.luau (HttpGet → request → mirrors)
    ├── load analytics, helpers, telemetry
    ├── preload Rayfield
    └── run games/*.luau
```

## Entry point

| File | Purpose |
|------|---------|
| `loader.luau` | Single entry — v5.2.2+ |

There is no `load.luau` rescue script. Load from GitHub or `readfile("loader.luau")`.

## Core loading

1. Try local `core/alleral_core.luau` if valid (v1.18+, compile check)
2. Download from jsDelivr → GitHub raw
3. `coreValid()` rejects broken cores (missing `AlleralGroupShell`, version < 1.18)
4. Cache successful download to workspace via `writefile`

## Version sources

| Component | Version | File |
|-----------|---------|------|
| Loader | 5.2.2 | `loader.luau`, `config/release.json` |
| Core | 1.18 | `core/alleral_core.luau` |
| Analytics | 1.0 | `core/analytics.luau` |
| Telemetry | 2.2 | `core/telemetry.luau` |
| Helpers | 1.0 | `core/game_helpers.luau` |
| Game scripts | per-game | `games/*.luau`, `config/scripts_manifest.json` |

Run `powershell tools/verify_versions.ps1` to check all versions match.

## Never do

- Embed core in loader with `[=[` long strings (breaks Volt parser)
- Commit output from `tools/bundle_core.ps1` (embedded core)
- Keep old loader versions in workspace autoexec (v3.x conflicts with v5.x)
