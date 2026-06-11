# Alleral Hub

One loader — detects your game by PlaceId and runs the matching script.

**Supported games:** Kick a Lucky Block · Speed Keyboard Escape · Slime RNG · Build A Ring Farm · Survive a Zombie Arena

## Load

### Stuck on v3.8.6 / core fetch fails? (Volt)

**Paste `load.luau` once** — open the file, copy all, Execute in Volt. It downloads core + latest loader, saves `loader.luau` to your workspace, and runs.

```lua
loadstring(readfile("load.luau"))()
```

Or copy/paste the contents of [load.luau](load.luau) directly into Volt and click Execute.

After that works, use:

```lua
loadstring(readfile("loader.luau"))()
```

### Normal load

**Local workspace** (full repo with `core/` optional — core is embedded in loader v3.9.0+):

```lua
loadstring(readfile("loader.luau"))()
```

**Remote (works on Volt, Synapse, Krnl, Solara, Wave, etc.):**

```lua
(function()
	local g = (getgenv and getgenv()) or {}
	local L = g.loadstring or g.LoadString or loadstring or load
	local url = "https://cdn.jsdelivr.net/gh/evanbackup1256-ship-it/kick@main/loader.luau?t=" .. tick()
	local src
	if type(L) ~= "function" then
		return warn("[Alleral] This executor needs loadstring.")
	end
	if type(g.Volt) == "table" and type(g.Volt.request) == "function" then
		pcall(function()
			local res = g.Volt.request({ Url = url, Method = "GET" })
			src = res and (res.Body or res.body)
		end)
	end
	if type(src) ~= "string" and type(game.HttpGet) == "function" then
		pcall(function()
			src = game.HttpGet(game, url, true)
		end)
	end
	if type(src) ~= "string" then
		pcall(function()
			src = game:HttpGet(url, true)
		end)
	end
	if type(src) ~= "string" and type(g.request) == "function" then
		pcall(function()
			local res = g.request({ Url = url, Method = "GET" })
			src = res and (res.Body or res.body)
		end)
	end
	if type(src) ~= "string" then
		return warn("[Alleral] HTTP failed — enable HttpService in your executor.")
	end
	local fn, err = L(src, "Alleral/loader")
	if type(fn) ~= "function" then
		return warn("[Alleral] Compile failed: " .. tostring(err))
	end
	fn()
end)()
```

Reload: `getgenv().Alleral_Reload()` · Debug: `getgenv().Alleral_LoaderInfo()`

## Layout

```
loader.luau          ← main entry (core embedded)
load.luau            ← one-time Volt rescue script
core/                ← shared UI, helpers, telemetry
games/               ← one script per supported game
```

## Docs

- [Architecture](docs/ARCHITECTURE.md)
- [Games](docs/GAMES.md)
