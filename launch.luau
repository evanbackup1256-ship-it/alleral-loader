--[[
	Alleral bootstrap — always run THIS via loadstring + HttpGet.
	Do not save/cache loader.luau in your executor; GitHub serves the latest copy.
]]
local REPO = "https://raw.githubusercontent.com/evanbackup1256-ship-it/kick/main"
local LOADER_URL = REPO .. "/loader.luau"

local function cacheBust(url)
	local sep = url:find("?") and "&" or "?"
	return url .. sep .. "t=" .. tostring(tick()) .. "&r=" .. tostring(math.random(100000, 999999))
end

local function fetch(url)
	url = cacheBust(url)
	if typeof(request) == "function" then
		local ok, res = pcall(request, {
			Url = url,
			Method = "GET",
			Headers = {
				["Cache-Control"] = "no-cache, no-store, must-revalidate",
				["Pragma"] = "no-cache",
			},
		})
		if ok and res then
			local body = res.Body or res.body
			if type(body) == "string" and #body > 500 then
				return body
			end
		end
	end
	if typeof(game.HttpGet) == "function" then
		local ok, body = pcall(game.HttpGet, game, url, true)
		if ok and type(body) == "string" and #body > 500 then
			return body
		end
	end
	return nil
end

local g = typeof(getgenv) == "function" and getgenv() or {}
if type(g) == "table" then
	g.Alleral_Core = nil
	g.Alleral_Starlight = nil
	g.Alleral_LoaderVersion = nil
end

local body = fetch(LOADER_URL)
if not body then
	error("[Alleral] Could not download loader from GitHub. Check HTTP/request support.")
end

local version = body:match('LOADER_VERSION%s*=%s*"([%d%.]+)"')
if not version then
	error("[Alleral] Downloaded payload is not a valid loader script.")
end

print("[Alleral Bootstrap] Fetched loader v" .. version .. " from GitHub")

local fn = loadstring(body, "Alleral/loader@" .. version)
if not fn then
	error("[Alleral] Loader failed to compile.")
end
fn()
