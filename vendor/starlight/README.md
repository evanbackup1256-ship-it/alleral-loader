# Starlight — Alleral UI

Programmatic UI library for Alleral game scripts. No Roblox asset model required.

## Protected artifacts

Critical runtime modules are **obfuscated** before distribution. Edit readable sources, then rebuild:

| Edit | Command |
|------|---------|
| Starlight UI (`vendor/starlight/lib/`) | `python vendor/starlight/bundle.py` |
| Telemetry / analytics (`core/internal/`) | `python tools/obfuscate_critical.py` |
| Verify all protected outputs | `python tools/verify_obfuscation.py` |

Loader and game scripts stay readable. `core/alleral_core.luau` and `loader.luau` are not obfuscated (they change often and glue everything together).

## Layout

```
vendor/starlight/
  lib/           Source modules (edit these)
  init.luau      Studio require entry
  Source.lua     Bundled output for executors
  bundle.py      Rebuild Source.lua after lib changes
```

## Rebuild

```bash
python vendor/starlight/bundle.py
```

This writes:
- `Source.plain.lua` — readable bundle (edit `lib/` instead)
- `Source.lua` — **obfuscated** distribution build (what executors load)

To re-protect telemetry/analytics after editing `core/internal/`:

```bash
python tools/obfuscate_critical.py
python tools/verify_obfuscation.py
```

## Usage

Loaded automatically via `Alleral_Core.loadStarlight()` → `vendor/starlight/Source.lua`.

```lua
local window = Starlight:CreateWindow({
    Name = "Alleral",
    Subtitle = "My Game",
    Icon = 10723407389,
    LoadingEnabled = false,
    NotifyOnCallbackError = true,
})

local section = window:CreateTabSection("Main", true)
local tab = section:CreateTab({ Name = "Farm", Columns = 2 }, "farm")
local group = tab:CreateGroupbox({ Name = "Auto", Column = 1 }, "auto")

group:CreateToggle({
    Name = "Auto farm",
    CurrentValue = false,
    Callback = function(on) end,
}, "AutoFarm")
```

Use `Core.wrapStarlightGroup(groupbox, callbackWrapper)` in game scripts for shorthand helpers (`CreateToggle`, `AddDropdown`, etc.).

Press **K** to toggle the window (configurable via `Starlight.WindowKeybind`).
