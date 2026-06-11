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

**Important:** If you still see `[Alleral Loader v3.x]` in the console, that is an **old script in Volt Autoexec** — not this loader.

1. Open **Volt → Settings → Autoexec**
2. **Delete** any Alleral / loader scripts (v3.7.4, bootstrap, launch, etc.)
3. Paste and **Execute** the snippet above once

Reload: `getgenv().Alleral_Reload()`
