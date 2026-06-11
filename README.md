# Alleral Hub

One script. Detects your game and runs it.

**Games:** Kick a Lucky Block · Speed Keyboard Escape · Slime RNG · Build A Ring Farm · Survive a Zombie Arena

## Load

Paste this in your executor and **Execute**:

```lua
(function()
	local url = "https://cdn.jsdelivr.net/gh/evanbackup1256-ship-it/kick@main/loader.luau?t=" .. tick()
	local src
	if type(game.HttpGet) == "function" then
		pcall(function() src = game:HttpGet(url, true) end)
	end
	if type(src) ~= "string" or not src:find('LOADER_VERSION = "5.3', 1, true) then
		local g = getgenv and getgenv() or {}
		local req = type(g.request) == "function" and g.request or type(g.http_request) == "function" and g.http_request
		if req then
			pcall(function()
				local r = req({ Url = url, Method = "GET" })
				src = type(r) == "string" and r or (r and (r.Body or r.body))
			end)
		end
	end
	if type(src) ~= "string" or not src:find('LOADER_VERSION = "5.3', 1, true) then
		return warn("[Alleral] Download failed — delete old loader.luau from workspace/autoexec")
	end
	loadstring(src)()
end)()
```

**Important:** If you see `[Alleral Loader v3.x]` instead of `=== Alleral loader 5.3.x active ===`, you are **not** running the current loader.

Common causes (even with empty Autoexec):

1. **Saved Scripts tab** — old Alleral one-liner saved there (especially `readfile("loader.luau")` or `launch.luau` URLs)
2. **Workspace file** — old `loader.luau` in Volt's workspace folder on disk
3. **Stale console** — scroll down; old logs stay visible from earlier injects

**Find workspace copies** (after loading v5.3 once):

```lua
getgenv().Alleral_ScanLegacy()
```

**Correct load** (always fetches latest from GitHub):

```lua
loadstring(game:HttpGet("https://cdn.jsdelivr.net/gh/evanbackup1256-ship-it/kick@main/loader.luau?t=" .. tick()))()
```

Reload: `getgenv().Alleral_Reload()`
