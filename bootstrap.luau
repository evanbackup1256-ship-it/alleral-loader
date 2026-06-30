-- Alleral entry v2.3.1 — thin bootstrap (gate + release pin live in loader.luau)
-- Edit loader.luau for logic; this file fetches release.json, pins loader commit, runs loader.
local BOOTSTRAP_VERSION = "2.3.1"
local REPO = "evanbackup1256-ship-it/alleral-loader"
local BRANCH = "main"
local CFG = "cfg"
local LOADER_MIN_BYTES = 50000
local DEFAULT_RELAY = "https://alleral-telemetry-production.up.railway.app"
local GITHUB_RAW = "https://raw.githubusercontent.com/" .. REPO

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

local function parseRelease(body)
	if type(body) ~= "string" then
		return nil
	end
	local commit = body:match('"commit"%s*:%s*"([^"]+)"')
	local loader = body:match('"loader"%s*:%s*"([^"]+)"')
	local protect = body:match('"protectScripts"%s*:%s*true') ~= nil
	return {
		commit = commit,
		loader = loader,
		protectScripts = protect,
	}
end

local function versionParts(ver)
	local parts = {}
	for num in tostring(ver or ""):gmatch("%d+") do
		table.insert(parts, tonumber(num) or 0)
	end
	return parts
end

local function versionGte(left, right)
	if type(left) ~= "string" or left == "" or type(right) ~= "string" or right == "" then
		return true
	end
	local a = versionParts(left)
	local b = versionParts(right)
	local maxLen = math.max(#a, #b)
	for i = 1, maxLen do
		local av = a[i] or 0
		local bv = b[i] or 0
		if av > bv then
			return true
		end
		if av < bv then
			return false
		end
	end
	return true
end

local function loaderBodyAccepts(body, minLoader)
	if type(body) ~= "string" then
		return false
	end
	if not body:find("LOADER_VERSION", 1, true) or not body:find("runMergedBootstrapGate", 1, true) then
		return false
	end
	if type(minLoader) == "string" and minLoader ~= "" then
		local found = body:match('LOADER_VERSION%s*=%s*"([^"]+)"')
		if type(found) == "string" and found ~= "" and not versionGte(found, minLoader) then
			return false
		end
	end
	return true
end

local releaseBody = fetchUrl(GITHUB_RAW .. "/" .. BRANCH .. "/" .. CFG .. "/release.json", 20)
local release = parseRelease(releaseBody) or {}
local pin = (type(release.commit) == "string" and release.commit ~= "") and release.commit or BRANCH

ENV._Alleral_BootstrapVersion = BOOTSTRAP_VERSION
ENV._Alleral_ReleaseCommit = pin
ENV._Alleral_ProtectScripts = release.protectScripts == true

print("[Alleral Bootstrap v" .. BOOTSTRAP_VERSION .. "] Pin commit " .. pin .. " · fetching loader...")

local relayBase = DEFAULT_RELAY
local bootBody = fetchUrl(relayBase .. "/api/bootstrap", 20)
if type(bootBody) == "string" then
	local relayUrl = bootBody:match('"relayUrl"%s*:%s*"([^"]+)"')
	local loaderCdn = bootBody:match('"loaderCdnBase"%s*:%s*"([^"]+)"')
	local apiKey = bootBody:match('"apiKey"%s*:%s*"([^"]+)"')
	if type(loaderCdn) == "string" and loaderCdn ~= "" then
		relayBase = loaderCdn:gsub("/+$", "")
		ENV._Alleral_LoaderCdnBase = relayBase
	end
	if type(apiKey) == "string" and apiKey ~= "" then
		ENV.Alleral_TelemetryApiKey = apiKey
		if getgenv then
			getgenv().Alleral_TelemetryApiKey = apiKey
		end
	end
	if type(relayUrl) == "string" and relayUrl ~= "" then
		ENV.Alleral_OwnerTelemetry = ENV.Alleral_OwnerTelemetry or {}
		ENV.Alleral_OwnerTelemetry.relayUrl = relayUrl
	end
	local relayProtect = bootBody:match('"protectScripts"%s*:%s*true') ~= nil
	if relayProtect then
		ENV._Alleral_ProtectScripts = true
	end
end

local minLoader = release.loader
local sources = {
	GITHUB_RAW .. "/" .. pin .. "/loader.luau",
	"https://github.com/" .. REPO .. "/raw/" .. pin .. "/loader.luau",
	"https://cdn.jsdelivr.net/gh/" .. REPO .. "@" .. pin .. "/loader.luau",
	GITHUB_RAW .. "/" .. BRANCH .. "/loader.luau",
	relayBase .. "/api/loader/file/loader.luau",
}

local src
for _, url in ipairs(sources) do
	local body = fetchUrl(url, LOADER_MIN_BYTES)
	if loaderBodyAccepts(body, minLoader) then
		src = body
		break
	end
end

if not src then
	ENV._Alleral_BootstrapRunning = false
	error("[Alleral Bootstrap] Could not download loader.luau (commit " .. pin .. ") — enable HTTP and retry.")
end

ENV._Alleral_MergedBootstrapEntry = true
ENV._Alleral_Bootstrapped = true
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