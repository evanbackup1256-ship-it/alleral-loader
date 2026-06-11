--[[
	Alleral bootstrap — single entry point for players.
	Always fetches fresh modules via multiple CDN mirrors automatically.
]]
local GITHUB_REPO = "evanbackup1256-ship-it/kick"
local REPO_BRANCH = "main"
local REPO = "https://raw.githubusercontent.com/" .. GITHUB_REPO .. "/" .. REPO_BRANCH
local JSdelivr = "https://cdn.jsdelivr.net/gh/" .. GITHUB_REPO .. "@" .. REPO_BRANCH
local GITHUB_WEB_RAW = "https://github.com/" .. GITHUB_REPO .. "/raw/" .. REPO_BRANCH
local DEFAULT_TELEMETRY_RELAY = "https://alleral-telemetry-production.up.railway.app/ingest"
local MIN_LOADER_PARTS = { 3, 7, 0 }

local TELEMETRY_CONFIG_PATHS = {
	"../Alleral-Private/owner_telemetry.luau",
	"Alleral-Private/owner_telemetry.luau",
	"config/owner_telemetry.luau",
	"kick/kick/config/owner_telemetry.luau",
	"owner_telemetry.luau",
}
local TELEMETRY_ENV_PATHS = {
	"backend/.env",
	"kick/kick/backend/.env",
}
local LOCAL_LOADER_PATHS = {
	"loader.luau",
	"kick/kick/loader.luau",
	"kick/loader.luau",
	"src/loader.luau",
}

local function cacheBust(url)
	local sep = url:find("?") and "&" or "?"
	return url
		.. sep
		.. "t="
		.. tostring(tick())
		.. "&r="
		.. tostring(math.random(100000, 999999))
		.. "&nocache="
		.. tostring(os.time())
end

local function trim(s)
	return type(s) == "string" and s:match("^%s*(.-)%s*$") or ""
end

local function parseVersionParts(version)
	local parts = {}
	for piece in tostring(version or ""):gmatch("%d+") do
		table.insert(parts, tonumber(piece) or 0)
	end
	return parts
end

local function versionAtLeast(version, minimumParts)
	local current = parseVersionParts(version)
	for index, minimum in ipairs(minimumParts) do
		local value = current[index] or 0
		if value > minimum then
			return true
		end
		if value < minimum then
			return false
		end
	end
	return true
end

local function loaderBodyValid(body)
	if type(body) ~= "string" or #body < 1000 then
		return false, nil, "response too small"
	end
	if body:find("404: Not Found", 1, true) then
		return false, nil, "404"
	end
	local version = body:match('LOADER_VERSION%s*=%s*"([%d%.]+)"')
	if not version then
		return false, nil, "missing LOADER_VERSION"
	end
	if not versionAtLeast(version, MIN_LOADER_PARTS) then
		return false, version, "stale loader v" .. version
	end
	if not body:find('REQUIRED_UI_LIBRARY%s*=%s*"Rayfield"', 1) then
		return false, version, "not Rayfield loader"
	end
	if body:find("loadStarlight", 1, true) or body:find('REQUIRED_UI_LIBRARY%s*=%s*"Starlight"', 1) then
		return false, version, "Starlight loader rejected"
	end
	return true, version, nil
end

local function ownerTelemetryValid(cfg)
	return type(cfg) == "table"
		and cfg.enabled ~= false
		and trim(cfg.relayUrl or "") ~= ""
		and trim(cfg.apiKey or "") ~= ""
		and trim(cfg.apiKey) ~= "aller_CHANGE_ME"
end

local function parseEnvFile(raw)
	local out = {}
	for line in tostring(raw or ""):gmatch("[^\r\n]+") do
		line = trim(line)
		if line ~= "" and not line:match("^#") and line:find("=") then
			local key, value = line:match("^([^=]+)=(.*)$")
			if key then
				out[trim(key)] = trim(value)
			end
		end
	end
	return out
end

local function buildTelemetryFromEnv(env)
	if type(env) ~= "table" then
		return nil
	end
	local apiKey = trim(env.TELEMETRY_API_KEY or env.ADMIN_API_KEY or "")
	if apiKey == "" or apiKey == "aller_CHANGE_ME" or #apiKey < 24 then
		return nil
	end
	local relayUrl = DEFAULT_TELEMETRY_RELAY
	local publicUrl = trim(env.TELEMETRY_PUBLIC_URL or env.TELEMETRY_RELAY_URL or "")
	if publicUrl ~= "" then
		publicUrl = publicUrl:gsub("/+$", "")
		relayUrl = publicUrl:find("/ingest$") and publicUrl or (publicUrl .. "/ingest")
	end
	return {
		enabled = true,
		relayUrl = relayUrl,
		apiKey = apiKey,
		brand = trim(env.TELEMETRY_BRAND) ~= "" and trim(env.TELEMETRY_BRAND) or "Alleral Ops",
		heartbeatMinutes = tonumber(env.TELEMETRY_HEARTBEAT_MINUTES) or 15,
		logLevel = trim(env.TELEMETRY_LOG_LEVEL) ~= "" and trim(env.TELEMETRY_LOG_LEVEL) or "info",
	}
end

local function preloadOwnerTelemetry(g)
	if ownerTelemetryValid(g.Alleral_OwnerTelemetry) then
		return
	end
	if typeof(isfile) ~= "function" or typeof(readfile) ~= "function" then
		return
	end
	for _, path in ipairs(TELEMETRY_CONFIG_PATHS) do
		if isfile(path) then
			local ok, fn = pcall(loadstring, readfile(path), "Alleral/owner_telemetry@" .. path)
			if ok and type(fn) == "function" then
				local ok2, cfg = pcall(fn)
				if ok2 and ownerTelemetryValid(cfg) then
					g.Alleral_OwnerTelemetry = cfg
					print("[Alleral Bootstrap] Telemetry config from " .. path)
					return
				end
			end
		end
	end
	for _, path in ipairs(TELEMETRY_ENV_PATHS) do
		if isfile(path) then
			local cfg = buildTelemetryFromEnv(parseEnvFile(readfile(path)))
			if ownerTelemetryValid(cfg) then
				g.Alleral_OwnerTelemetry = cfg
				print("[Alleral Bootstrap] Telemetry config from " .. path)
				return
			end
		end
	end
end

local function fetchRemote(url)
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
			if type(body) == "string" then
				return body
			end
		end
	end
	if typeof(game.HttpGet) == "function" then
		local ok, body = pcall(game.HttpGet, game, url, true)
		if ok and type(body) == "string" then
			return body
		end
	end
	return nil
end

local function readLocalLoader()
	if typeof(isfile) ~= "function" or typeof(readfile) ~= "function" then
		return nil, nil
	end
	for _, path in ipairs(LOCAL_LOADER_PATHS) do
		if isfile(path) then
			local ok, body = pcall(readfile, path)
			if ok and type(body) == "string" then
				local valid, version = loaderBodyValid(body)
				if valid then
					return body, "local:" .. path, version
				end
			end
		end
	end
	return nil, nil, nil
end

local function releaseCommit()
	for _, source in ipairs({
		JSdelivr .. "/config/release.json",
		REPO .. "/config/release.json",
		GITHUB_WEB_RAW .. "/config/release.json",
	}) do
		local body = fetchRemote(source)
		if body then
			local commit = body:match('"commit"%s*:%s*"([^"]+)"')
			if commit and commit ~= "" and commit ~= "HEAD" then
				return commit
			end
		end
	end
	return nil
end

local function buildLoaderSources(commit)
	local sources = {}
	if commit then
		table.insert(sources, "https://cdn.jsdelivr.net/gh/" .. GITHUB_REPO .. "@" .. commit .. "/loader.luau")
		table.insert(sources, "https://raw.githubusercontent.com/" .. GITHUB_REPO .. "/" .. commit .. "/loader.luau")
	end
	table.insert(sources, JSdelivr .. "/loader.luau")
	table.insert(sources, GITHUB_WEB_RAW .. "/loader.luau")
	table.insert(sources, REPO .. "/loader.luau")
	return sources
end

local function fetchLoaderBody()
	local localBody, localLabel, localVersion = readLocalLoader()
	if localBody then
		return localBody, localLabel, localVersion
	end

	local commit = releaseCommit()
	local remoteSources = buildLoaderSources(commit)
	local lastReason = "download failed"

	for round = 1, 2 do
		for _, source in ipairs(remoteSources) do
			for attempt = 1, 3 do
				local body = fetchRemote(source)
				if body then
					local valid, version, reason = loaderBodyValid(body)
					if valid then
						local label = source:find("jsdelivr", 1, true) and "jsdelivr"
							or (source:find("/raw/", 1, true) and "github-web" or "github-raw")
						return body, label, version
					end
					lastReason = reason or ("invalid v" .. tostring(version))
				end
				if typeof(task) == "table" and type(task.wait) == "function" then
					task.wait(0.35 * attempt)
				end
			end
		end
		if round == 1 then
			commit = releaseCommit()
			remoteSources = buildLoaderSources(commit)
		end
	end

	error("[Alleral Bootstrap] Could not load Alleral. Please rejoin and try again.")
end

local g = typeof(getgenv) == "function" and getgenv() or {}
if type(g) == "table" then
	g.Alleral_Core = nil
	g.Alleral_Rayfield = nil
	g.Alleral_UI = nil
	g.Alleral_Starlight = nil
	g.Alleral_LoaderVersion = nil
	g._Alleral_AutoRecoveryAttempted = nil
	preloadOwnerTelemetry(g)
end

local body, sourceLabel, version = fetchLoaderBody()
print("[Alleral Bootstrap] Using loader v" .. version .. " from " .. sourceLabel)

local fn = loadstring(body, "Alleral/loader@" .. version)
if not fn then
	error("[Alleral] Loader failed to compile.")
end
fn()
