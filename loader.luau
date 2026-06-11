--[[
	Alleral Hub — one script.
	Detects game, fetches core + game script, runs.
]]

local LOADER_VERSION = "5.1.0"
local MIN_CORE = "1.18"
local REPO = "evanbackup1256-ship-it/kick"
local BRANCH = "main"
local RAW = "https://raw.githubusercontent.com/" .. REPO .. "/" .. BRANCH
local GH_WEB = "https://github.com/" .. REPO .. "/raw/" .. BRANCH
local CDN = "https://cdn.jsdelivr.net/gh/" .. REPO .. "@" .. BRANCH

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local HttpService = nil
pcall(function()
	HttpService = game:GetService("HttpService")
end)

local function genv()
	local ok, env = pcall(function()
		return getgenv and getgenv() or getfenv()
	end)
	return ok and env or {}
end

local ENV = genv()

local function firstExecFunc(...)
	for i = 1, select("#", ...) do
		local name = select(i, ...)
		if type(name) == "function" then
			return name
		end
		if type(name) == "string" then
			local fn = ENV[name] or (_G and _G[name])
			if type(fn) == "function" then
				return fn
			end
		end
	end
	return nil
end

local loadStringFn = firstExecFunc(ENV.loadstring, ENV.LoadString, loadstring, load)
local readFile = firstExecFunc("readfile", "read_file", "ReadFile")
local isFile = firstExecFunc("isfile", "is_file", "IsFile")

local function log(msg, isWarn)
	local line = "[Alleral v" .. LOADER_VERSION .. "] " .. msg
	if isWarn then
		warn(line)
	else
		print(line)
	end
end

local function notify(title, text, duration)
	pcall(function()
		game:GetService("StarterGui"):SetCore("SendNotification", {
			Title = title,
			Text = text,
			Duration = duration or 5,
		})
	end)
end

local function normalizeSlug(text)
	local key = tostring(text or ""):lower()
	key = key:gsub("synapse%s*z", "synapsez")
	key = key:gsub("awp%.?gg?", "volt")
	key = key:gsub("vega%s*x", "vegax")
	key = key:gsub("[^a-z0-9]", "")
	return key
end

local function detectExecutorProfile()
	local rawName = ""
	for _, id in ipairs({ "identifyexecutor", "getexecutorname", "whatexecutor", "getexecutor" }) do
		local fn = firstExecFunc(id)
		if fn then
			local ok, result, version = pcall(fn)
			if ok and type(result) == "string" and result ~= "" then
				rawName = result
				if type(version) == "string" and version ~= "" then
					rawName = rawName .. " " .. version
				end
				break
			end
		end
	end

	local slug = normalizeSlug(rawName)
	if slug == "" or slug == "unknown" then
		if type(ENV.Volt) == "table" and type(ENV.Volt.request) == "function" then
			slug = "volt"
		elseif type(ENV.syn) == "table" and type(ENV.syn.request) == "function" then
			slug = "synapse"
		elseif ENV.KRNL_LOADED then
			slug = "krnl"
		elseif type(ENV.fluxus) == "table" then
			slug = "fluxus"
		elseif type(ENV.Xeno) == "table" then
			slug = "xeno"
		elseif type(ENV.Wave) == "table" then
			slug = "wave"
		elseif type(ENV.Electron) == "table" then
			slug = "electron"
		elseif type(ENV.Solara) == "table" or (ENV.shared and ENV.shared.solara) then
			slug = "solara"
		else
			slug = "unknown"
		end
	end

	local display = rawName ~= "" and rawName or slug:sub(1, 1):upper() .. slug:sub(2)
	if slug == "synapsez" then
		display = "Synapse Z"
	elseif slug == "volt" and display:lower():find("volt", 1, true) == nil then
		display = "Volt"
	end

	return { slug = slug, name = display, rawName = rawName }
end

local EXECUTOR = detectExecutorProfile()

-- Per-executor HTTP transport order (first = preferred for that injector)
local HTTP_STRATEGIES = {
	volt = { "volt", "request", "httpget", "httpservice" },
	awp = { "volt", "request", "httpget", "httpservice" },
	synapse = { "syn", "request", "httpget", "httpservice" },
	synapsez = { "syn", "request", "httpget", "httpservice" },
	krnl = { "request", "httpget", "httpservice" },
	fluxus = { "fluxus", "request", "httpget", "httpservice" },
	solara = { "solara", "request", "httpget", "httpservice" },
	solora = { "solara", "request", "httpget", "httpservice" },
	xeno = { "xeno", "request", "httpget", "httpservice" },
	wave = { "wave", "request", "httpget", "httpservice" },
	electron = { "electron", "request", "httpget", "httpservice" },
	potassium = { "potassium", "request", "httpget", "httpservice" },
	velocity = { "velocity", "request", "httpget", "httpservice" },
	codex = { "codex", "request", "httpget", "httpservice" },
	hydrogen = { "hydrogen", "request", "httpget", "httpservice" },
	delta = { "delta", "request", "httpget", "httpservice" },
	celery = { "celery", "request", "httpget", "httpservice" },
	jjsploit = { "httpget", "request", "httpservice" },
	default = { "request", "httpget", "httpservice" },
}

local function extractResponseBody(response)
	if type(response) == "string" then
		return response
	end
	if type(response) == "table" then
		return response.Body or response.body or response.Data or response.data
	end
	return nil
end

local function requestVia(fn, url)
	if type(fn) ~= "function" then
		return nil
	end
	for _, spec in ipairs({
		{ Url = url, Method = "GET", Headers = { ["Cache-Control"] = "no-cache" } },
		{ url = url, method = "GET", headers = { ["Cache-Control"] = "no-cache" } },
	}) do
		local ok, res = pcall(fn, spec)
		if ok then
			local body = extractResponseBody(res)
			if type(body) == "string" and #body > 0 then
				return body
			end
		end
	end
	return nil
end

local function buildHttpTransports(slug)
	local sharedEnv = ENV.shared or (typeof(shared) == "table" and shared) or nil
	local solaraLib = sharedEnv and type(sharedEnv.solara) == "table" and sharedEnv.solara or nil
	local transports = {
		volt = function(url)
			return ENV.Volt and requestVia(ENV.Volt.request, url)
		end,
		syn = function(url)
			return ENV.syn and requestVia(ENV.syn.request, url)
		end,
		fluxus = function(url)
			return ENV.fluxus and requestVia(ENV.fluxus.request, url)
		end,
		solara = function(url)
			if solaraLib and type(solaraLib.request) == "function" then
				return requestVia(solaraLib.request, url)
			end
			if type(ENV.Solara) == "table" then
				return requestVia(ENV.Solara.request, url)
			end
			return nil
		end,
		xeno = function(url)
			return type(ENV.Xeno) == "table" and requestVia(ENV.Xeno.request, url)
		end,
		wave = function(url)
			return type(ENV.Wave) == "table" and requestVia(ENV.Wave.request, url)
		end,
		electron = function(url)
			return type(ENV.Electron) == "table" and requestVia(ENV.Electron.request, url)
		end,
		potassium = function(url)
			return type(ENV.Potassium) == "table" and requestVia(ENV.Potassium.request, url)
		end,
		velocity = function(url)
			return type(ENV.Velocity) == "table" and requestVia(ENV.Velocity.request, url)
		end,
		codex = function(url)
			return type(ENV.Codex) == "table" and requestVia(ENV.Codex.request, url)
		end,
		hydrogen = function(url)
			return type(ENV.Hydrogen) == "table" and requestVia(ENV.Hydrogen.request, url)
		end,
		delta = function(url)
			return type(ENV.delta) == "table" and requestVia(ENV.delta.request, url)
		end,
		celery = function(url)
			return type(ENV.celery) == "table" and requestVia(ENV.celery.request, url)
		end,
		request = function(url)
			return requestVia(ENV.request, url) or requestVia(ENV.http_request, url) or requestVia(ENV.Request, url)
		end,
		httpget = function(url)
			if type(game.HttpGet) == "function" then
				local ok, body = pcall(game.HttpGet, game, url, true)
				if type(body) == "string" and #body > 0 then
					return body
				end
				ok, body = pcall(game.HttpGet, game, url)
				if type(body) == "string" and #body > 0 then
					return body
				end
			end
			local ok, body = pcall(function()
				return game:HttpGet(url, true)
			end)
			if ok and type(body) == "string" and #body > 0 then
				return body
			end
			ok, body = pcall(function()
				return game:HttpGet(url)
			end)
			if ok and type(body) == "string" and #body > 0 then
				return body
			end
			return nil
		end,
		httpservice = function(url)
			if HttpService and type(HttpService.GetAsync) == "function" then
				local ok, body = pcall(function()
					return HttpService:GetAsync(url, true)
				end)
				if ok and type(body) == "string" and #body > 0 then
					return body
				end
			end
			return nil
		end,
	}

	local order = HTTP_STRATEGIES[slug] or HTTP_STRATEGIES.default
	local list, seen = {}, {}
	for _, id in ipairs(order) do
		if transports[id] and not seen[id] then
			seen[id] = true
			table.insert(list, { id = id, fetch = transports[id] })
		end
	end
	for id, fetch in pairs(transports) do
		if not seen[id] then
			table.insert(list, { id = id, fetch = fetch })
		end
	end
	return list
end

local HTTP_TRANSPORTS = buildHttpTransports(EXECUTOR.slug)

local CAPABILITIES = {
	executor = EXECUTOR.name,
	executorSlug = EXECUTOR.slug,
	loadstring = loadStringFn ~= nil,
	readfile = readFile ~= nil,
}

local function httpGet(url, minBytes)
	minBytes = minBytes or 0
	local bust = url .. (url:find("?") and "&" or "?") .. "t=" .. tostring(tick())

	local core = ENV.Alleral_Core
	if core and type(core.httpGet) == "function" then
		local body = core.httpGet(bust)
		if type(body) == "string" and #body >= minBytes then
			return body, "core"
		end
	end

	local bestBody, bestVia, bestLen = nil, nil, 0
	for _, transport in ipairs(HTTP_TRANSPORTS) do
		local body = transport.fetch(bust)
		if type(body) == "string" and #body >= minBytes and #body > bestLen then
			bestBody, bestVia, bestLen = body, transport.id, #body
		end
	end
	return bestBody, bestVia
end

local function looksLikeLua(body)
	if type(body) ~= "string" or #body < 50 then
		return false
	end
	if body:find("<!DOCTYPE", 1, true) or body:find("<html", 1, true) then
		return body:find("function", 1, true) ~= nil or body:find("local ", 1, true) ~= nil
	end
	return true
end

local function readLocal(paths, minBytes)
	minBytes = minBytes or 0
	if not readFile or not isFile then
		return nil
	end
	local bestSrc, bestPath, bestLen = nil, nil, 0
	local roots = { "", "kick/", "kick/kick/", "workspace/" }
	for _, root in ipairs(roots) do
		for _, path in ipairs(paths) do
			local full = root .. path
			local okExists, exists = pcall(isFile, full)
			if okExists and exists then
				local okRead, src = pcall(readFile, full)
				if okRead and type(src) == "string" and #src >= minBytes and #src > bestLen then
					bestSrc, bestPath, bestLen = src, full, #src
				end
			end
		end
	end
	return bestSrc, bestPath
end

local function fetchRemote(relativePath, minBytes)
	minBytes = minBytes or 0
	for _, base in ipairs({ RAW, GH_WEB, CDN }) do
		local body, via = httpGet(base .. "/" .. relativePath, minBytes)
		if body and looksLikeLua(body) and not body:find("404: Not Found", 1, true) then
			local label = base
			if via then
				label = label .. " via " .. via
			end
			return body, label
		end
	end
	return nil
end

local function cacheRemote(relativePath, src)
	local writeFile = firstExecFunc("writefile")
	local makeFolder = firstExecFunc("makefolder")
	if type(writeFile) ~= "function" then
		return
	end
	local dir = relativePath:match("^(.+)/[^/]+$")
	if dir and makeFolder then
		pcall(makeFolder, dir)
	end
	pcall(writeFile, relativePath, src)
end

local function getSource(localPaths, remotePath, opts)
	opts = type(opts) == "table" and opts or { marker = opts }
	local minBytes = opts.minBytes or 0
	local marker = opts.marker

	local src, path = readLocal(localPaths, minBytes)
	if src then
		if marker and not src:find(marker, 1, true) then
			log("Skipping outdated local " .. path, true)
		else
			return src, "local:" .. path
		end
	end

	src, path = fetchRemote(remotePath, minBytes)
	if src then
		if marker and not src:find(marker, 1, true) then
			log("Script may be outdated (missing " .. marker .. ")", true)
		end
		cacheRemote(remotePath, src)
		return src, "remote" .. (path and (" (" .. path .. ")") or "")
	end

	return nil, "Could not load " .. remotePath
end

local function compileAndRun(source, chunkName, runEnv)
	if not loadStringFn then
		return false, "loadstring unavailable"
	end
	local fn, err = loadStringFn(source, chunkName)
	if not fn and type(load) == "function" then
		fn, err = load(source, chunkName)
	end
	if not fn then
		return false, "Compile: " .. tostring(err)
	end
	if runEnv and setfenv then
		pcall(setfenv, fn, runEnv)
	end
	local ok, runErr = pcall(fn)
	if not ok then
		return false, "Runtime: " .. tostring(runErr)
	end
	return true
end

local function coreVersionOk(v)
	return type(v) == "string" and v >= MIN_CORE
end

local function coreValid(src)
	if type(src) ~= "string" or #src < 5000 or not src:find("loadRayfield", 1, true) then
		return false
	end
	local ver = src:match('Core%.VERSION%s*=%s*"([%d%.]+)"')
	if not coreVersionOk(ver) then
		return false
	end
	if src:find("fakeUiInstance", 1, true) and not src:find("AlleralGroupShell", 1, true) then
		return false
	end
	if not loadStringFn then
		return true
	end
	local fn = loadStringFn(src, "Alleral/core-check")
	return type(fn) == "function"
end

local function loadCore()
	if ENV.Alleral_Core and type(ENV.Alleral_Core.loadRayfield) == "function" and coreVersionOk(ENV.Alleral_Core.VERSION) then
		return true
	end
	ENV.Alleral_Core = nil

	local src, label = getSource(
		{ "core/alleral_core.luau", "alleral_core.luau" },
		"core/alleral_core.luau",
		{ minBytes = 5000 }
	)
	if not src or not coreValid(src) then
		return false, label or "Core download failed"
	end
	local ok, err = compileAndRun(src, "Alleral/core")
	if not ok then
		ENV.Alleral_Core = nil
		return false, err
	end
	if not ENV.Alleral_Core or type(ENV.Alleral_Core.loadRayfield) ~= "function" then
		return false, "Core did not initialize"
	end
	log("Core v" .. tostring(ENV.Alleral_Core.VERSION) .. " from " .. label)
	return true
end

local function loadModule(localPaths, remotePath, marker, chunkName)
	local src, label = getSource(localPaths, remotePath, { marker = marker, minBytes = 500 })
	if not src then
		return false
	end
	local ok = compileAndRun(src, chunkName)
	if ok then
		log(chunkName .. " from " .. label)
	end
	return ok
end

local ENV_BRIDGE = [=[
do
	local bridge = shared
	if type(bridge) == "table" and getgenv then
		local g = getgenv()
		if type(g) == "table" then
			if bridge.Alleral_Rayfield then g.Alleral_Rayfield = bridge.Alleral_Rayfield; g.Alleral_UI = bridge.Alleral_Rayfield end
			if bridge.Alleral_Core then g.Alleral_Core = bridge.Alleral_Core end
			if bridge.Alleral_Analytics then g.Alleral_Analytics = bridge.Alleral_Analytics end
			if bridge.Alleral_Telemetry then g.Alleral_Telemetry = bridge.Alleral_Telemetry end
			g.Alleral_State = g.Alleral_State or bridge.Alleral_State or {}
			bridge.Alleral_State = g.Alleral_State
		end
	end
end
]=]

local function publishBridge()
	pcall(function()
		shared.Alleral_Rayfield = ENV.Alleral_Rayfield
		shared.Alleral_UI = ENV.Alleral_UI
		shared.Alleral_Core = ENV.Alleral_Core
		shared.Alleral_Analytics = ENV.Alleral_Analytics
		shared.Alleral_Telemetry = ENV.Alleral_Telemetry
		shared.Alleral_State = ENV.Alleral_State or {}
	end)
end

local function waitForPath(root, path, timeout)
	local current = root
	for _, name in ipairs(path) do
		if not current then
			return nil
		end
		current = current:WaitForChild(name, timeout or 15)
	end
	return current
end

local GAMES = {
	{
		id = "kick_a_lucky_block",
		name = "Kick a Lucky Block",
		version = "6.6",
		placeIds = { 89469502395769 },
		universeIds = { 10004244222 },
		scriptFiles = { "games/kick_a_lucky_block.luau", "kick_a_lucky_block.luau" },
		scriptUrl = "games/kick_a_lucky_block.luau",
		sourceMarker = "Alleral_Rayfield",
		preload = function()
			waitForPath(ReplicatedStorage, { "Shared" }, 20)
			local areas = Workspace:WaitForChild("Areas", 20)
			if not areas or not areas:WaitForChild("KickReady", 10) then
				return false, "KickReady pad not found — are you in the main world?"
			end
			return true
		end,
		validate = function()
			local shared = ReplicatedStorage:FindFirstChild("Shared")
			local network = shared and shared:FindFirstChild("Packages") and shared.Packages:FindFirstChild("Network")
			local kickReady = Workspace:FindFirstChild("Areas") and Workspace.Areas:FindFirstChild("KickReady")
			return network ~= nil and kickReady ~= nil
		end,
	},
	{
		id = "speed_keyboard_escape",
		name = "Speed Keyboard Escape",
		version = "1.2",
		placeIds = { 95082159892680 },
		scriptFiles = { "games/speed_keyboard_escape.luau", "speed_keyboard_escape.luau" },
		scriptUrl = "games/speed_keyboard_escape.luau",
		preload = function()
			waitForPath(ReplicatedStorage, { "Remotes" }, 20)
			return true
		end,
		validate = function()
			local remotes = ReplicatedStorage:FindFirstChild("Remotes")
			return remotes ~= nil and remotes:FindFirstChild("UpdateSpeed") ~= nil
		end,
	},
	{
		id = "slime_rng",
		name = "Slime RNG",
		version = "1.2",
		placeIds = { 92416421522960 },
		universeIds = { 9792947201 },
		scriptFiles = { "games/slime_rng.luau", "slime_rng.luau" },
		scriptUrl = "games/slime_rng.luau",
		preload = function()
			waitForPath(ReplicatedStorage, { "Packages", "DataService" }, 25)
			return true
		end,
		validate = function()
			local packages = ReplicatedStorage:FindFirstChild("Packages")
			return packages and packages:FindFirstChild("DataService") ~= nil
		end,
	},
	{
		id = "build_a_ring_farm",
		name = "Build A Ring Farm",
		version = "1.2",
		placeIds = { 107646426076756 },
		scriptFiles = { "games/build_a_ring_farm.luau", "build_a_ring_farm.luau" },
		scriptUrl = "games/build_a_ring_farm.luau",
		preload = function()
			waitForPath(ReplicatedStorage, { "Shared" }, 20)
			waitForPath(ReplicatedStorage, { "Remotes", "PlantSeed" }, 15)
			return true
		end,
		validate = function()
			local remotes = ReplicatedStorage:FindFirstChild("Remotes")
			return remotes and remotes:FindFirstChild("PlantSeed") ~= nil
		end,
	},
	{
		id = "survive_a_zombie_arena",
		name = "Survive a Zombie Arena",
		version = "2.1",
		placeIds = { 114204398207377 },
		scriptFiles = { "games/survive_a_zombie_arena.luau", "survive_a_zombie_arena.luau" },
		scriptUrl = "games/survive_a_zombie_arena.luau",
		preload = function()
			waitForPath(ReplicatedStorage, { "ZombieRemotes", "ZombieDamage" }, 20)
			return true
		end,
		validate = function()
			local zombieRemotes = ReplicatedStorage:FindFirstChild("ZombieRemotes")
			return zombieRemotes and zombieRemotes:FindFirstChild("ZombieDamage") ~= nil
		end,
	},
}

local function detectGame()
	local placeId = game.PlaceId
	local universeId = nil
	do
		local ok, id = pcall(function()
			return game.GameId
		end)
		if ok and type(id) == "number" and id > 0 then
			universeId = id
		end
	end
	local best, bestScore = nil, 0

	for _, profile in ipairs(GAMES) do
		local score = 0
		for _, id in ipairs(profile.placeIds or {}) do
			if id == placeId then
				score = score + 100
			end
		end
		for _, id in ipairs(profile.universeIds or {}) do
			if id == universeId then
				score = score + 50
			end
		end
		if profile.validate and profile.validate() then
			score = score + 25
		end
		if score > bestScore then
			bestScore = score
			best = profile
		end
	end

	if not best or bestScore < 25 then
		return nil, "No supported game (PlaceId " .. tostring(placeId) .. ")"
	end
	if bestScore < 100 and not (best.validate and best.validate()) then
		return nil, best.name .. " markers not found in this server"
	end
	return best
end

local function main()
	if ENV.Alleral_LoaderRunning then
		log("Already running — use getgenv().Alleral_Reload()", true)
		return
	end
	ENV.Alleral_LoaderRunning = true

	if not loadStringFn then
		notify("Alleral", "This executor needs loadstring.", 8)
		ENV.Alleral_LoaderRunning = false
		return
	end

	ENV.Alleral_Core = nil
	ENV.Alleral_Rayfield = nil
	ENV.Alleral_UI = nil
	ENV.Alleral_StartupFailed = nil
	ENV.Alleral_ScriptManifestUrl = CDN .. "/config/scripts_manifest.json"

	local profile, err = detectGame()
	if not profile then
		notify("Alleral", tostring(err), 8)
		log(tostring(err), true)
		ENV.Alleral_LoaderRunning = false
		return
	end

	log("Game: " .. profile.name .. " | executor=" .. EXECUTOR.name .. " (" .. EXECUTOR.slug .. ")")

	if profile.preload then
		local ready, preloadErr = profile.preload()
		if not ready then
			notify("Alleral", tostring(preloadErr), 8)
			ENV.Alleral_LoaderRunning = false
			return
		end
	end

	local coreOk, coreErr = loadCore()
	if not coreOk then
		notify("Alleral", "Core failed: " .. tostring(coreErr), 8)
		log("Core failed: " .. tostring(coreErr), true)
		ENV.Alleral_LoaderRunning = false
		return
	end

	loadModule({ "core/analytics.luau" }, "core/analytics.luau", "Alleral_Analytics", "Alleral/analytics")
	loadModule({ "core/game_helpers.luau" }, "core/game_helpers.luau", "GameHelpers", "Alleral/helpers")
	loadModule({ "config/owner_telemetry.luau" }, "config/owner_telemetry.luau", nil, "Alleral/owner-telemetry")
	loadModule({ "core/telemetry.luau" }, "core/telemetry.luau", "Alleral_Telemetry", "Alleral/telemetry")

	if ENV.Alleral_Core and type(ENV.Alleral_Core.loadRayfield) == "function" then
		local ui, uiErr = ENV.Alleral_Core.loadRayfield()
		if ui then
			ENV.Alleral_Rayfield = ui
			ENV.Alleral_UI = ui
			log("Rayfield ready")
		else
			log("Rayfield skipped: " .. tostring(uiErr), true)
		end
	end

	local src, label = getSource(profile.scriptFiles, profile.scriptUrl, {
		marker = profile.sourceMarker,
		minBytes = 40000,
	})
	if not src then
		notify("Alleral", "Game script failed: " .. tostring(label), 8)
		log("Game script failed: " .. tostring(label), true)
		ENV.Alleral_LoaderRunning = false
		return
	end

	log("Loading " .. profile.name .. " v" .. profile.version .. " from " .. label)
	publishBridge()
	ENV.Alleral_LoaderMeta = { version = LOADER_VERSION, profile = profile.id, source = label }
	src = ENV_BRIDGE .. "\n" .. src

	local ok, runErr = compileAndRun(src, "Alleral/" .. profile.id, ENV)
	ENV.Alleral_LoaderRunning = false

	if not ok then
		notify("Alleral", tostring(runErr), 8)
		log(tostring(runErr), true)
		return
	end
	if ENV.Alleral_StartupFailed then
		notify("Alleral", tostring(ENV.Alleral_StartupFailed), 8)
		return
	end

	notify("Alleral", profile.name .. " loaded.", 4)
	log("Ready")
end

ENV.Alleral_Reload = function()
	if ENV.Alleral_State and type(ENV.Alleral_State.Alleral_Unload) == "function" then
		pcall(ENV.Alleral_State.Alleral_Unload)
	end
	if typeof(task) == "table" and task.defer then
		task.defer(main)
	else
		main()
	end
end

ENV.Alleral_LoaderInfo = function()
	return { version = LOADER_VERSION, capabilities = CAPABILITIES, games = GAMES }
end

print("[Alleral] v" .. LOADER_VERSION .. " | PlaceId " .. tostring(game.PlaceId) .. " | executor=" .. EXECUTOR.slug)

local ok, err = pcall(main)
if not ok then
	warn("[Alleral] " .. tostring(err))
	notify("Alleral", tostring(err), 10)
	ENV.Alleral_LoaderRunning = false
end
