-- Alleral entry v2.2.0 — thin wrapper (bootstrap logic lives in loader.luau)
-- Edit loader.luau only; this file just fetches and runs it.
local BOOTSTRAP_VERSION = "2.2.0"
local REPO = "evanbackup1256-ship-it/-kick-loader"
local BRANCH = "main"
local LOADER_MIN_BYTES = 50000

local function genv()
	local ok, env = pcall(function()
		return getgenv and getgenv() or getfenv()
	end)
	return ok and env or {}
end

local ENV = genv()

if ENV._Alleral_BootstrapRunning then
	return
end
ENV._Alleral_BootstrapRunning = true

local function resolveGame()
	if typeof(game) == "Instance" then
		return game
	end
	if _G and typeof(_G.game) == "Instance" then
		return _G.game
	end
	if typeof(ENV.game) == "Instance" then
		return ENV.game
	end
	return nil
end

local game = resolveGame()
if not game then
	error("[Alleral Bootstrap] Run inside a Roblox game, not the executor menu.")
end
ENV.game = game

print("[Alleral Bootstrap v" .. BOOTSTRAP_VERSION .. "] Fetching merged loader...")

local loadFn = ENV.loadstring or ENV.LoadString or ENV.load or loadstring or load
if type(loadFn) ~= "function" then
	error("[Alleral Bootstrap] loadstring unavailable.")
end

local function pickRequest()
	for _, name in ipairs({ "request", "http_request", "httprequest", "syn_request" }) do
		local fn = ENV[name] or (_G and _G[name])
		if type(fn) == "function" then
			return fn
		end
	end
	if type(syn) == "table" and type(syn.request) == "function" then
		return syn.request
	end
	if type(http) == "table" and type(http.request) == "function" then
		return http.request
	end
	return nil
end

local function fetchUrl(url, minBytes)
	minBytes = minBytes or 0
	local bust = (url:find("?") and "&" or "?") .. "t=" .. tostring(tick())
	local fullUrl = url .. bust
	local requestFn = pickRequest()
	if requestFn then
		local ok, body = pcall(function()
			local res = requestFn({
				Url = fullUrl,
				Method = "GET",
				Headers = { ["Cache-Control"] = "no-cache" },
			})
			if type(res) == "table" then
				return res.Body or res.body
			end
			return type(res) == "string" and res or nil
		end)
		if ok and type(body) == "string" and #body >= minBytes then
			return body
		end
	end
	if type(game.HttpGet) == "function" then
		local ok, body = pcall(game.HttpGet, game, fullUrl, true)
		if ok and type(body) == "string" and #body >= minBytes then
			return body
		end
		ok, body = pcall(game.HttpGet, game, fullUrl)
		if ok and type(body) == "string" and #body >= minBytes then
			return body
		end
	end
	return nil
end

local sources = {
	"https://raw.githubusercontent.com/" .. REPO .. "/" .. BRANCH .. "/loader.luau",
	"https://alleral-telemetry-production.up.railway.app/api/loader/file/loader.luau",
	"https://cdn.jsdelivr.net/gh/" .. REPO .. "@" .. BRANCH .. "/loader.luau",
}

local src
for _, url in ipairs(sources) do
	local body = fetchUrl(url, LOADER_MIN_BYTES)
	if type(body) == "string" and body:find("LOADER_VERSION", 1, true) then
		src = body
		break
	end
end

if not src then
	ENV._Alleral_BootstrapRunning = false
	error("[Alleral Bootstrap] Could not download loader.luau — enable HTTP and retry.")
end

ENV._Alleral_MergedBootstrapEntry = true
local chunk = loadFn(src, "@Alleral/loader")
if type(chunk) ~= "function" then
	ENV._Alleral_BootstrapRunning = false
	error("[Alleral Bootstrap] Loader compile failed.")
end
if setfenv then
	pcall(setfenv, chunk, ENV)
end

local ok, err = pcall(chunk)
ENV._Alleral_BootstrapRunning = false
if not ok then
	error("[Alleral Bootstrap] " .. tostring(err))
end