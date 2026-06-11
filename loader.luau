--[[
	Alleral Hub — single entry point.
	Detects game.PlaceId, loads core + matching games/*.luau script.
]]
do
	local okBoot, bootErr = pcall(function()
		local g = (typeof(getgenv) == "function" and getgenv()) or _G
		local core = g.Alleral_Core
		if type(core) == "table" and type(core.loadRayfield) == "function" then
			return
		end
		local L = g.loadstring or g.LoadString or loadstring or load
		if type(L) ~= "function" then
			return
		end
		local urls = {
			"https://cdn.jsdelivr.net/gh/evanbackup1256-ship-it/kick@main/core/alleral_core.luau",
			"https://raw.githubusercontent.com/evanbackup1256-ship-it/kick/main/core/alleral_core.luau",
		}
		local function pull(url)
			url = url .. "?t=" .. tostring(tick())
			if type(g.Volt) == "table" and type(g.Volt.request) == "function" then
				local rok, res = pcall(g.Volt.request, { Url = url, Method = "GET" })
				if rok and res then
					return res.Body or res.body
				end
			end
			if type(g.request) == "function" then
				local rok, res = pcall(g.request, { Url = url, Method = "GET" })
				if rok and res then
					return res.Body or res.body
				end
			end
			if type(game.HttpGet) == "function" then
				local rok, body = pcall(game.HttpGet, game, url, true)
				if rok then
					return body
				end
			end
			return nil
		end
		for _, url in ipairs(urls) do
			local src = pull(url)
			if type(src) == "string" and #src > 5000 and src:find("loadRayfield", 1, true) then
				local fn = L(src, "Alleral/core-bootstrap")
				if type(fn) == "function" then
					fn()
				end
				if type(g.Alleral_Core) == "table" and type(g.Alleral_Core.loadRayfield) == "function" then
					print("[Alleral] Core ready (bootstrap prefetch)")
					return
				end
			end
		end
	end)
	if not okBoot and bootErr then
		warn("[Alleral] Core bootstrap: " .. tostring(bootErr))
	end
end

local LOADER_VERSION = "3.9.0"
local REQUIRED_CORE_VERSION = "1.18"
local MIN_CORE_VERSION = "1.17"
local REQUIRED_UI_LIBRARY = "Rayfield"
local GITHUB_REPO = "evanbackup1256-ship-it/kick"
local REPO_BRANCH = "main"
local REPO_BASE = "https://raw.githubusercontent.com/" .. GITHUB_REPO .. "/" .. REPO_BRANCH
local JSDELIVR_BASE = "https://cdn.jsdelivr.net/gh/" .. GITHUB_REPO .. "@" .. REPO_BRANCH
local GITHUB_WEB_RAW = "https://github.com/" .. GITHUB_REPO .. "/raw/" .. REPO_BRANCH
local SCRIPT_MANIFEST_PATH = "config/scripts_manifest.json"
local SCRIPT_MANIFEST_URL = JSDELIVR_BASE .. "/" .. SCRIPT_MANIFEST_PATH
local FETCH_RETRIES = 2
local FETCH_BACKOFF = 0.35
local MIN_SCRIPT_BYTES = 1000
local PINNED_COMMITS = {
	"a9f1a86",
	"369c8a7",
	"ee04d1b",
	"c6191aa",
	"d9441a1",
	"df472aa",
	"55d3f68",
	"6a1b22c",
}

local EMBEDDED_CORE_VERSION = "1.18"
local EMBEDDED_CORE = [=
local Core = {}
Core.VERSION = "1.18"
Core.UI_LIBRARY = "Rayfield"

local HttpService = game:GetService("HttpService")
local StarterGui = game:GetService("StarterGui")
local RAYFIELD_SOURCE_URL = "https://raw.githubusercontent.com/SiriusSoftwareLtd/Rayfield/main/source.lua"
local RAYFIELD_MIRROR_URLS = {
	"https://raw.githubusercontent.com/SiriusSoftwareLtd/Rayfield/main/source.lua",
	"https://cdn.jsdelivr.net/gh/SiriusSoftwareLtd/Rayfield@main/source.lua",
	"https://raw.githubusercontent.com/evanbackup1256-ship-it/kick/main/vendor/rayfield/source.lua",
	"https://cdn.jsdelivr.net/gh/evanbackup1256-ship-it/kick@main/vendor/rayfield/source.lua",
}
local RAYFIELD_MIN_BYTES = 50000
local RAYFIELD_LOCAL_FILES = {
	"vendor/rayfield/source.lua",
	"rayfield/source.lua",
}
local RAYFIELD_THEME_NAMES = {
	"Default",
	"Ocean",
	"AmberGlow",
	"Light",
	"Amethyst",
	"Green",
	"Bloom",
	"DarkBlue",
	"Serenity",
}
local ROSCRIPTS_SEARCH_URL = "https://rscripts.net/api/v2/scripts"
local ROSCRIPTS_SCRIPT_URL = "https://rscripts.net/api/v2/script"
local ROSCRIPTS_WEB_HOME = "https://roscripts.io/"
local ROSCRIPTS_WEB_SCRIPT = "https://rscripts.net/script/"

local function genv()
	local ok, env = pcall(function()
		return getgenv and getgenv() or getfenv()
	end)
	return ok and env or {}
end

local ENV = genv()

function Core.notify(title, text, duration)
	pcall(function()
		StarterGui:SetCore("SendNotification", {
			Title = title or "Alleral",
			Text = text or "",
			Duration = duration or 4,
		})
	end)
end

function Core.requestFunction()
	local sharedEnv = ENV.shared or (typeof(shared) == "table" and shared) or nil
	local solaraLib = sharedEnv and type(sharedEnv.solara) == "table" and sharedEnv.solara or nil
	local soloraLib = sharedEnv and type(sharedEnv.Solora) == "table" and sharedEnv.Solora or nil
	local candidates = {
		solaraLib and solaraLib.request,
		soloraLib and soloraLib.request,
		type(ENV.Solara) == "table" and ENV.Solara.request or nil,
		type(ENV.Solora) == "table" and ENV.Solora.request or nil,
		type(ENV.syn) == "table" and ENV.syn.request or nil,
		type(ENV.fluxus) == "table" and ENV.fluxus.request or nil,
		type(ENV.http) == "table" and ENV.http.request or nil,
		type(ENV.http_service) == "table" and ENV.http_service.request or nil,
		type(ENV.Xeno) == "table" and ENV.Xeno.request or nil,
		type(ENV.Volt) == "table" and ENV.Volt.request or nil,
		type(ENV.Madium) == "table" and ENV.Madium.request or nil,
		type(ENV.Nihon) == "table" and ENV.Nihon.request or nil,
		type(ENV.Cryptic) == "table" and ENV.Cryptic.request or nil,
		type(ENV.Sentinel) == "table" and ENV.Sentinel.request or nil,
		type(ENV.Serenity) == "table" and ENV.Serenity.request or nil,
		type(ENV.Atlantis) == "table" and ENV.Atlantis.request or nil,
		type(ENV.Zorara) == "table" and ENV.Zorara.request or nil,
		type(ENV.Wave) == "table" and ENV.Wave.request or nil,
		type(ENV.Electron) == "table" and ENV.Electron.request or nil,
		type(ENV.Potassium) == "table" and ENV.Potassium.request or nil,
		type(ENV.Velocity) == "table" and ENV.Velocity.request or nil,
		type(ENV.Krnl) == "table" and ENV.Krnl.request or nil,
		type(ENV.jjsploit) == "table" and ENV.jjsploit.request or nil,
		type(ENV.Bunni) == "table" and ENV.Bunni.request or nil,
		type(ENV.Valyse) == "table" and ENV.Valyse.request or nil,
		type(ENV.Krypton) == "table" and ENV.Krypton.request or nil,
		type(ENV.Evon) == "table" and ENV.Evon.request or nil,
		type(ENV.delta) == "table" and ENV.delta.request or nil,
		type(ENV.celery) == "table" and ENV.celery.request or nil,
		type(ENV.Codex) == "table" and ENV.Codex.request or nil,
		type(ENV.Hydrogen) == "table" and ENV.Hydrogen.request or nil,
		type(ENV.Ronix) == "table" and ENV.Ronix.request or nil,
		type(ENV.Macsploit) == "table" and ENV.Macsploit.request or nil,
		type(ENV.Oxygen) == "table" and ENV.Oxygen.request or nil,
		type(ENV.http) == "table" and ENV.http.request or nil,
		ENV.request,
		ENV.Request,
	}
	for _, name in ipairs({ "http_request", "request", "Request" }) do
		local fn = ENV[name]
		if type(fn) == "function" then
			table.insert(candidates, 1, fn)
		end
	end
	for _, candidate in ipairs(candidates) do
		if type(candidate) == "function" then
			return candidate
		end
	end
	if type(HttpService.RequestAsync) == "function" then
		return function(opts)
			return HttpService:RequestAsync({
				Url = opts.Url,
				Method = opts.Method or "GET",
				Headers = opts.Headers,
				Body = opts.Body,
			})
		end
	end
	return nil
end

function Core.firstExecFunc(...)
	for index = 1, select("#", ...) do
		local name = select(index, ...)
		local fn = ENV[name] or (getfenv and getfenv()[name])
		if type(fn) == "function" then
			return fn
		end
	end
	return nil
end

function Core.execFunction(name, requireFilesystem)
	if requireFilesystem then
		local profile = Core.executorProfile()
		if not profile.fsOk and not profile.hasFilesystem then
			return nil
		end
	end
	local aliases = Core.EXEC_ALIASES and Core.EXEC_ALIASES[name]
	if aliases then
		for _, alias in ipairs(aliases) do
			local fn = ENV[alias]
			if type(fn) ~= "function" then
				fn = Core.firstExecFunc(alias)
			end
			if type(fn) == "function" then
				return fn
			end
		end
	end
	local fn = ENV[name]
	if type(fn) ~= "function" then
		fn = Core.firstExecFunc(name)
	end
	return type(fn) == "function" and fn or nil
end

Core.EXEC_ALIASES = {
	readfile = { "readfile", "read_file", "ReadFile" },
	writefile = { "writefile", "write_file", "WriteFile" },
	isfile = { "isfile", "is_file", "IsFile" },
	listfiles = { "listfiles", "list_files", "ListFiles" },
	makefolder = { "makefolder", "make_folder", "MakeFolder" },
	isfolder = { "isfolder", "is_folder", "IsFolder" },
	loadstring = { "loadstring", "LoadString" },
	setclipboard = { "setclipboard", "toclipboard", "setrbxclipboard" },
	getconnections = { "getconnections", "get_signal_cons" },
	firetouchinterest = { "firetouchinterest", "FireTouchInterest", "touchinterest" },
	identifyexecutor = { "identifyexecutor", "getexecutorname", "whatexecutor", "getexecutor" },
}

local function inferSlugFromText(text)
	local lower = tostring(text or ""):lower()
	local map = {
		{ "synapse z", "synapsez" },
		{ "synapse", "synapsez" },
		{ "potassium", "potassium" },
		{ "matcha", "matcha" },
		{ "photon", "photon" },
		{ "volt", "volt" },
		{ "awp", "volt" },
		{ "velocity", "velocity" },
		{ "solara", "solara" },
		{ "solora", "solara" },
		{ "xeno", "xeno" },
		{ "wave", "wave" },
		{ "delta", "delta" },
		{ "codex", "codex" },
		{ "cryptic", "cryptic" },
		{ "sirhurt", "sirhurt" },
		{ "seliware", "seliware" },
		{ "swift", "swift" },
		{ "volcano", "volcano" },
		{ "electron", "electron" },
		{ "ronin", "ronin" },
		{ "bunni", "bunni" },
		{ "serotonin", "serotonin" },
		{ "cosmic", "cosmic" },
		{ "opiumware", "opiumware" },
		{ "lumen", "lumen" },
		{ "severe", "severe" },
		{ "isaeva", "isaeva" },
		{ "nihon", "nihon" },
		{ "zenith", "zenith" },
		{ "macsploit", "macsploit" },
		{ "vega x", "vegax" },
		{ "vega", "vegax" },
		{ "madium", "madium" },
		{ "rbxcli", "rbxcli" },
		{ "krnl", "krnl" },
		{ "fluxus", "fluxus" },
		{ "jjsploit", "jjsploit" },
		{ "comet", "comet" },
		{ "trigon", "trigon" },
		{ "hydrogen", "hydrogen" },
		{ "arceus", "arceus" },
		{ "oxygen", "oxygenu" },
	}
	for _, pair in ipairs(map) do
		if lower:find(pair[1], 1, true) then
			return pair[2]
		end
	end
	return nil
end

function Core.detectExecutor()
	local rawName = ""
	for _, id in ipairs({
		"identifyexecutor",
		"getexecutorname",
		"whatexecutor",
		"getexecutor",
		"getexecutorinfo",
	}) do
		local fn = Core.firstExecFunc(id)
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

	local slug = inferSlugFromText(rawName) or rawName:lower():gsub("%s+", ""):match("^[%a][%w%-_%.]*") or ""
	local function hasTable(key)
		local value = ENV[key]
		return type(value) == "table" and value or nil
	end
	local sharedEnv = ENV.shared or (typeof(shared) == "table" and shared) or nil

	if slug == "" then
		if hasTable("syn") and type(ENV.syn.request) == "function" then
			slug = "synapse"
		elseif ENV.KRNL_LOADED == true then
			slug = "krnl"
		elseif hasTable("fluxus") and type(ENV.fluxus.request) == "function" then
			slug = "fluxus"
		elseif hasTable("sw") then
			slug = "scriptware"
		elseif hasTable("celery") then
			slug = "celery"
		elseif hasTable("delta") then
			slug = "delta"
		elseif ENV.OXYGEN_U == true then
			slug = "oxygenu"
		elseif hasTable("Electron") then
			slug = "electron"
		elseif hasTable("Wave") and type(ENV.Wave.setclipboard) == "function" then
			slug = "wave"
		elseif sharedEnv and type(sharedEnv.solara) == "table" then
			slug = "solara"
		elseif sharedEnv and type(sharedEnv.Solora) == "table" then
			slug = "solora"
		elseif hasTable("Solara") or hasTable("solara") then
			slug = "solara"
		elseif hasTable("Solora") or hasTable("solora") then
			slug = "solora"
		elseif hasTable("Xeno") then
			slug = "xeno"
		elseif hasTable("Volt") and type(ENV.Volt.request) == "function" then
			slug = "volt"
		elseif hasTable("Potassium") then
			slug = "potassium"
		elseif hasTable("Madium") then
			slug = "madium"
		elseif hasTable("Velocity") then
			slug = "velocity"
		elseif hasTable("Codex") then
			slug = "codex"
		elseif hasTable("Ronix") then
			slug = "ronix"
		elseif hasTable("Nihon") then
			slug = "nihon"
		elseif hasTable("Vega") or hasTable("VegaX") then
			slug = "vegax"
		elseif hasTable("Comet") then
			slug = "comet"
		elseif hasTable("Trigon") then
			slug = "trigon"
		elseif hasTable("Cryptic") then
			slug = "cryptic"
		elseif hasTable("Hydrogen") then
			slug = "hydrogen"
		elseif hasTable("Sentinel") then
			slug = "sentinel"
		elseif hasTable("Serenity") then
			slug = "serenity"
		elseif hasTable("Atlantis") then
			slug = "atlantis"
		elseif hasTable("Zorara") then
			slug = "zorara"
		elseif hasTable("Aztup") then
			slug = "aztup"
		elseif hasTable("Nixware") then
			slug = "nixware"
		elseif ENV.IS_JJSLOIT == true or hasTable("jjsploit") then
			slug = "jjsploit"
		elseif hasTable("Bunni") or hasTable("bunni") then
			slug = "bunni"
		elseif hasTable("Valyse") or hasTable("valyse") then
			slug = "valyse"
		elseif hasTable("Krypton") or hasTable("krypton") then
			slug = "krypton"
		elseif hasTable("SirHurt") or hasTable("sirhurt") then
			slug = "sirhurt"
		elseif hasTable("Temple") or hasTable("temple") then
			slug = "temple"
		elseif hasTable("Evon") or hasTable("evon") then
			slug = "evon"
		elseif hasTable("AWP") or hasTable("awp") then
			slug = "awp"
		elseif hasTable("Pebble") or hasTable("pebble") then
			slug = "pebble"
		elseif hasTable("Nzxt") or hasTable("nzxt") then
			slug = "nzxt"
		elseif hasTable("Nezur") or hasTable("nezur") then
			slug = "nezur"
		elseif hasTable("Seliware") or hasTable("seliware") then
			slug = "seliware"
		elseif hasTable("Luna") or hasTable("luna") then
			slug = "luna"
		elseif hasTable("Macsploit") or hasTable("macsploit") then
			slug = "macsploit"
		elseif hasTable("Potassium") or hasTable("potassium") then
			slug = "potassium"
		elseif hasTable("Cosmic") or hasTable("cosmic") then
			slug = "cosmic"
		elseif hasTable("Opiumware") or hasTable("opiumware") then
			slug = "opiumware"
		elseif hasTable("Volcano") or hasTable("volcano") then
			slug = "volcano"
		elseif hasTable("Swift") or hasTable("swift") then
			slug = "swift"
		elseif hasTable("Ronin") or hasTable("ronin") then
			slug = "ronin"
		elseif hasTable("Synapse") or ENV.SynapseZ == true then
			slug = "synapsez"
		elseif hasTable("Arceus") or ENV.ARCEUS_LOADED == true then
			slug = "arceus"
		elseif Core.firstExecFunc("queue_on_teleport") and Core.firstExecFunc("getgc") then
			slug = "synapse"
		else
			slug = "unknown"
		end
	end

	if slug == "solora" then
		slug = "solara"
	end

	local display = slug:sub(1, 1):upper() .. slug:sub(2)
	if slug == "synapsez" then
		display = "Synapse Z"
	elseif slug == "synapse" then
		display = "Synapse"
	elseif slug == "jjsploit" then
		display = "JJSploit"
	elseif slug == "solara" then
		display = "Solara"
	elseif slug == "vegax" then
		display = "Vega X"
	elseif slug == "macsploit" then
		display = "MacSploit"
	elseif slug == "oxygenu" then
		display = "Oxygen U"
	elseif slug == "bunni" then
		display = "Bunni"
	end

	return {
		slug = slug,
		name = display,
		rawName = rawName,
		isKnown = slug ~= "unknown",
	}
end

Core.WEAO_API_URLS = {
	"https://api.weao.xyz/api/status/exploits",
	"https://whatexpsare.online/api/status/exploits",
	"https://api.whatexpsare.online/api/status/exploits",
	"http://api.weao.xyz/api/status/exploits",
}

function Core.normalizeExecutorKey(text)
	local key = tostring(text or ""):lower()
	key = key:gsub("synapse%s*z", "synapsez")
	key = key:gsub("awp%.?gg?", "volt")
	key = key:gsub("bunni%.?fun", "bunni")
	key = key:gsub("vega%s*x", "vegax")
	key = key:gsub("[^a-z0-9]", "")
	return key
end

function Core.formatWeaoEntry(entry)
	if type(entry) ~= "table" then
		return nil
	end
	return {
		title = entry.title,
		version = entry.version,
		detected = entry.detected == true,
		updateStatus = entry.updateStatus ~= false,
		uncStatus = entry.uncStatus == true,
		platform = entry.platform,
		extype = entry.extype,
		free = entry.free == true,
		suncPercentage = tonumber(entry.suncPercentage),
		uncPercentage = tonumber(entry.uncPercentage),
		updatedDate = entry.updatedDate,
		websitelink = entry.websitelink,
	}
end

function Core.matchWeaoExploit(profile, exploits)
	if type(exploits) ~= "table" then
		return nil
	end
	local slugKey = Core.normalizeExecutorKey(profile and (profile.name or profile.slug))
	local rawKey = Core.normalizeExecutorKey(profile and profile.rawName)
	if slugKey == "" and rawKey == "" then
		return nil
	end
	local best
	local bestScore = 0
	for _, entry in ipairs(exploits) do
		if type(entry) == "table" and type(entry.title) == "string" then
			local titleKey = Core.normalizeExecutorKey(entry.title)
			local score = 0
			if titleKey ~= "" then
				if titleKey == slugKey or titleKey == rawKey then
					score = 100
				elseif slugKey ~= "" and (titleKey:find(slugKey, 1, true) or slugKey:find(titleKey, 1, true)) then
					score = 80
				elseif rawKey ~= "" and (titleKey:find(rawKey, 1, true) or rawKey:find(titleKey, 1, true)) then
					score = 70
				end
			end
			if score > bestScore then
				bestScore = score
				best = entry
			end
		end
	end
	return bestScore >= 70 and best or nil
end

function Core.fetchWeaoExploits(forceRefresh)
	local cache = ENV.Alleral_WeaoCache
	if not forceRefresh and type(cache) == "table" and cache.fetchedAt and (tick() - cache.fetchedAt) < 300 then
		return cache.data, cache.source
	end

	local function decodeBody(body)
		if type(body) ~= "string" or body == "" then
			return nil
		end
		local ok, decoded = pcall(function()
			return HttpService:JSONDecode(body)
		end)
		if ok and type(decoded) == "table" then
			return decoded
		end
		return nil
	end

	local function fetchUrl(url)
		local headers = {
			["User-Agent"] = "WEAO-3PService",
			["Accept"] = "application/json",
			["Cache-Control"] = "no-cache",
		}
		local requestFn = Core.requestFunction()
		if requestFn then
			local ok, response = pcall(function()
				return requestFn({
					Url = url .. (url:find("?") and "&" or "?") .. "t=" .. tostring(math.random(10000, 99999)),
					Method = "GET",
					Headers = headers,
				})
			end)
			if ok then
				local body = type(response) == "table" and (response.Body or response.body) or (type(response) == "string" and response)
				local decoded = decodeBody(body)
				if decoded then
					return decoded, url
				end
			end
		end
		if type(game.HttpGet) == "function" then
			local ok, body = pcall(game.HttpGet, game, url, true)
			local decoded = decodeBody(ok and body or nil)
			if decoded then
				return decoded, url
			end
		end
		return nil
	end

	for _, url in ipairs(Core.WEAO_API_URLS) do
		local data, source = fetchUrl(url)
		if data then
			ENV.Alleral_WeaoCache = {
				fetchedAt = tick(),
				data = data,
				source = source,
			}
			return data, source
		end
	end

	if type(cache) == "table" and cache.data then
		return cache.data, cache.source
	end
	return nil, "WEAO exploit list unavailable"
end

function Core.fetchWeaoExecutorStatus(profile)
	profile = profile or Core.executorProfile()
	local exploits, err = Core.fetchWeaoExploits(false)
	local entry = Core.matchWeaoExploit(profile, exploits)
	if entry then
		return Core.formatWeaoEntry(entry)
	end
	return nil, err
end

function Core.weaoStatusLabel(weao)
	if type(weao) ~= "table" then
		return "Unknown (see whatexpsare.online)"
	end
	local parts = {}
	if weao.updateStatus then
		table.insert(parts, "Updated")
	else
		table.insert(parts, "Outdated")
	end
	if weao.detected then
		table.insert(parts, "Detected")
	else
		table.insert(parts, "Undetected")
	end
	if weao.suncPercentage then
		table.insert(parts, tostring(weao.suncPercentage) .. "% sUNC")
	end
	return table.concat(parts, " · ")
end

Core.EXECUTOR_FS_BROKEN = {
	yub = true,
	yubx = true,
	arceus = true,
	vegax = true,
	comet = true,
}

Core.EXECUTOR_COMPAT = {
	synapse = true,
	krnl = true,
	fluxus = true,
	scriptware = true,
	celery = true,
	delta = true,
	oxygenu = true,
	electron = true,
	wave = true,
	solara = true,
	solora = true,
	xeno = true,
	volt = true,
	potassium = true,
	madium = true,
	velocity = true,
	codex = true,
	ronix = true,
	nihon = true,
	trigon = true,
	cryptic = true,
	hydrogen = true,
	sentinel = true,
	serenity = true,
	atlantis = true,
	zorara = true,
	aztup = true,
	nixware = true,
	jjsploit = true,
	bunni = true,
	valyse = true,
	krypton = true,
	sirhurt = true,
	temple = true,
	evon = true,
	awp = true,
	pebble = true,
	nzxt = true,
	nezur = true,
	seliware = true,
	luna = true,
	macsploit = true,
	synapsez = true,
	potassium = true,
	matcha = true,
	photon = true,
	cosmic = true,
	opiumware = true,
	volcano = true,
	swift = true,
	ronin = true,
	serotonin = true,
	lumen = true,
	severe = true,
	isaeva = true,
	rbxcli = true,
	unknown = true,
}

function Core.executorProfile()
	local detected = Core.detectExecutor()
	local slug = detected.slug
	local fsOk = not Core.EXECUTOR_FS_BROKEN[slug]
	local sharedEnv = ENV.shared or (typeof(shared) == "table" and shared) or nil
	local solaraLib = sharedEnv and type(sharedEnv.solara) == "table" and sharedEnv.solara or nil
	local soloraLib = sharedEnv and type(sharedEnv.Solora) == "table" and sharedEnv.Solora or nil

	local hasHttp = Core.requestFunction() ~= nil
	local hasFilesystem = fsOk
		and type(ENV.writefile) == "function"
		and type(ENV.readfile) == "function"
	local hasGetConn = type(ENV.getconnections) == "function" or type(ENV.get_signal_cons) == "function"
	local hasClipboard = type(ENV.setclipboard) == "function"
		or type(ENV.toclipboard) == "function"
		or (type(ENV.Wave) == "table" and type(ENV.Wave.setclipboard) == "function")
		or (type(ENV.Electron) == "table" and type(ENV.Electron.setclipboard) == "function")
	local hasFireTouch = type(ENV.firetouchinterest) == "function"
		or type(ENV.FireTouchInterest) == "function"
		or type(ENV.touchinterest) == "function"

	return {
		name = slug,
		displayName = detected.name,
		rawName = detected.rawName,
		isKnown = detected.isKnown,
		fsOk = fsOk,
		hasFilesystem = hasFilesystem,
		hasHttp = hasHttp,
		hasGetConn = hasGetConn,
		hasClipboard = hasClipboard,
		hasFireTouch = hasFireTouch,
		hasLoadstring = type(ENV.loadstring or loadstring) == "function",
		env = ENV,
		solara = solaraLib ~= nil or soloraLib ~= nil or slug == "solara",
		weao = Core.formatWeaoEntry(Core.matchWeaoExploit(detected, ENV.Alleral_WeaoCache and ENV.Alleral_WeaoCache.data)),
	}
end

function Core.executorTelemetryProfile()
	local profile = Core.executorProfile()
	local apis = {}
	for _, pair in ipairs({
		{ "http_request", "http_request" },
		{ "request", "request" },
		{ "readfile", "readfile" },
		{ "writefile", "writefile" },
		{ "loadstring", "loadstring" },
		{ "getconnections", "getconnections" },
		{ "firetouchinterest", "firetouchinterest" },
		{ "identifyexecutor", "identifyexecutor" },
		{ "gethui", "gethui" },
	}) do
		if type(ENV[pair[2]]) == "function" then
			table.insert(apis, pair[1])
		end
	end
	if profile.solara then
		table.insert(apis, "solara")
	end
	table.sort(apis)
	local loaderCaps = ENV.Alleral_LoaderCapabilities or {}
	return {
		name = profile.displayName,
		version = profile.rawName,
		http = profile.hasHttp or loaderCaps.http == true,
		loadstring = loaderCaps.loadstring == true or type(ENV.loadstring) == "function",
		readfile = profile.hasFilesystem or loaderCaps.readfile == true,
		apis = apis,
		weao = profile.weao,
	}
end

function Core.refreshLoaderCapabilities()
	local profile = Core.executorProfile()
	local caps = {
		executor = profile.displayName,
		executorSlug = profile.name,
		http = profile.hasHttp,
		loadstring = type(ENV.loadstring or loadstring) == "function",
		readfile = profile.hasFilesystem,
		isfile = type(ENV.isfile) == "function",
		listfiles = type(ENV.listfiles) == "function",
		solara = profile.solara,
		hasClipboard = profile.hasClipboard,
		hasFireTouch = profile.hasFireTouch,
		hasGetConn = profile.hasGetConn,
	}
	ENV.Alleral_LoaderCapabilities = caps
	pcall(function()
		if shared then
			shared.Alleral_LoaderCapabilities = caps
		end
	end)
	return caps
end

function Core.notifyExecutorCompat(profile)
	profile = profile or Core.executorProfile()
	local caps = {}
	if profile.hasLoadstring ~= false then
		table.insert(caps, "Lua")
	end
	if profile.hasHttp then
		table.insert(caps, "HTTP")
	end
	if profile.hasFilesystem then
		table.insert(caps, "FS")
	end
	if profile.hasFireTouch then
		table.insert(caps, "Touch")
	end
	if profile.hasGetConn then
		table.insert(caps, "Signals")
	end
	if profile.hasClipboard then
		table.insert(caps, "Clipboard")
	end
	local capText = #caps > 0 and (" | " .. table.concat(caps, ", ")) or ""
	local display = profile.displayName
	local msg = display .. capText
	if profile.weao then
		msg = msg .. " — WEAO: " .. Core.weaoStatusLabel(profile.weao)
		if profile.weao.detected then
			msg = msg .. ". Consider a different executor if you get banned."
		elseif not profile.weao.updateStatus then
			msg = msg .. ". Update your executor for best results."
		end
	elseif not profile.isKnown then
		msg = msg .. " — universal mode (any executor with loadstring)."
	else
		msg = msg .. " — ready."
	end
	Core.notify("Executor", msg, 5)
end

local SCRIPT_STATUS_META = {
	working = { label = "Working", icon = "✅" },
	detected = { label = "Detected / unstable", icon = "⚠️" },
	broken = { label = "Broken", icon = "❌" },
	maintenance = { label = "Maintenance", icon = "🛠️" },
	testing = { label = "Testing", icon = "🧪" },
}

function Core.scriptStatusMeta(status)
	return SCRIPT_STATUS_META[tostring(status or ""):lower()] or { label = tostring(status or "Unknown"), icon = "❔" }
end

function Core.defaultScriptManifestUrls()
	local urls = {}
	if ENV.Alleral_ScriptManifestUrl and ENV.Alleral_ScriptManifestUrl ~= "" then
		table.insert(urls, ENV.Alleral_ScriptManifestUrl)
	end
	local ownerCfg = ENV.Alleral_OwnerTelemetry
	if type(ownerCfg) == "table" and type(ownerCfg.relayUrl) == "string" and ownerCfg.relayUrl ~= "" then
		local relay = ownerCfg.relayUrl:gsub("/+$", "")
		table.insert(urls, relay:gsub("/ingest$", "") .. "/scripts")
		if not relay:find("/scripts$") then
			table.insert(urls, relay .. "/scripts")
		end
	end
	table.insert(urls, "https://cdn.jsdelivr.net/gh/evanbackup1256-ship-it/kick@main/config/scripts_manifest.json")
	table.insert(urls, "https://github.com/evanbackup1256-ship-it/kick/raw/main/config/scripts_manifest.json")
	table.insert(urls, "https://raw.githubusercontent.com/evanbackup1256-ship-it/kick/main/config/scripts_manifest.json")
	return urls
end

function Core.fetchScriptManifest(forceRefresh)
	local cache = ENV.Alleral_ScriptManifestCache
	if not forceRefresh and type(cache) == "table" and cache.fetchedAt and (tick() - cache.fetchedAt) < 60 then
		return cache.data, nil
	end

	local requestFn = Core.requestFunction()
	local readFileFn = ENV.readfile
	local isFileFn = ENV.isfile
	local lastErr = "Script manifest unavailable"

	for _, path in ipairs({
		"config/scripts_manifest.json",
		"kick/config/scripts_manifest.json",
	}) do
		if type(readFileFn) == "function" and type(isFileFn) == "function" and isFileFn(path) then
			local ok, raw = pcall(readFileFn, path)
			if ok and type(raw) == "string" and raw ~= "" then
				local decodedOk, decoded = pcall(function()
					return HttpService:JSONDecode(raw)
				end)
				if decodedOk and type(decoded) == "table" then
					ENV.Alleral_ScriptManifestCache = { fetchedAt = tick(), data = decoded, source = "local:" .. path }
					ENV.Alleral_ScriptManifest = decoded
					return decoded, nil
				end
			end
		end
	end

	if requestFn then
		for _, url in ipairs(Core.defaultScriptManifestUrls()) do
			local ok, response = pcall(function()
				return requestFn({
					Url = url .. (url:find("?") and "&" or "?") .. "t=" .. tostring(math.random(10000, 99999)),
					Method = "GET",
					Headers = { ["Cache-Control"] = "no-cache" },
				})
			end)
			if ok then
				local body = type(response) == "table" and (response.Body or response.body) or (type(response) == "string" and response)
				if type(body) == "string" and body ~= "" and not body:find("404") then
					local decodedOk, decoded = pcall(function()
						return HttpService:JSONDecode(body)
					end)
					if decodedOk and type(decoded) == "table" and type(decoded.scripts) == "table" then
						ENV.Alleral_ScriptManifestCache = { fetchedAt = tick(), data = decoded, source = url }
						ENV.Alleral_ScriptManifest = decoded
						return decoded, nil
					end
				end
			end
			lastErr = "Manifest fetch failed: " .. url
		end
	end

	if type(cache) == "table" and cache.data then
		return cache.data, lastErr
	end
	return nil, lastErr
end

function Core.getScriptStatus(scriptId, profileVersion)
	scriptId = tostring(scriptId or ENV.Alleral_ActiveScriptId or "")
	local manifest = ENV.Alleral_ScriptManifest
	if not manifest then
		manifest = Core.fetchScriptManifest()
	end
	local entry = manifest and manifest.scripts and manifest.scripts[scriptId]
	if type(entry) ~= "table" then
		return {
			id = scriptId,
			status = "working",
			label = "Working",
			icon = "✅",
			message = "No remote status entry — running local build.",
			version = profileVersion or "?",
		}
	end
	local meta = Core.scriptStatusMeta(entry.status)
	return {
		id = scriptId,
		status = tostring(entry.status or "working"):lower(),
		label = meta.label,
		icon = meta.icon,
		message = tostring(entry.message or ""),
		version = tostring(entry.version or profileVersion or "?"),
		name = tostring(entry.name or scriptId),
		updatedAt = entry.updatedAt,
		updatedBy = entry.updatedBy,
	}
end

function Core.evaluateScriptStatus(scriptId, profileVersion)
	local status = Core.getScriptStatus(scriptId, profileVersion)
	local blocked = status.status == "broken" or status.status == "maintenance"
	local warn = status.status == "detected" or status.status == "testing"
	local force = ENV.Alleral_ForceLoad == true
	return {
		status = status,
		allowed = not blocked or force,
		warn = warn and not blocked,
		force = force,
	}
end

function Core.buildScriptStatusGroupbox(tab, column, scriptId, profileVersion)
	scriptId = scriptId or ENV.Alleral_ActiveScriptId
	local evaluation = Core.evaluateScriptStatus(scriptId, profileVersion)
	local status = evaluation.status
	local groupbox = tab:CreateGroupbox({
		Name = "Script status",
		Column = column or 1,
		Icon = 6031075938,
	}, "ScriptStatus")

	local labels = {}
	local function addRow(key, value)
		labels[key] = groupbox:CreateLabel({
			Name = tostring(key) .. ": " .. tostring(value),
		}, "Status_" .. tostring(key))
	end

	addRow("Status", status.icon .. " " .. status.label)
	addRow("Script", status.name)
	addRow("Version", status.version)
	addRow("Executor", (Core.executorProfile().displayName))
	local weao = Core.fetchWeaoExecutorStatus()
	if weao then
		addRow("WEAO", Core.weaoStatusLabel(weao))
		if weao.version then
			addRow("Exec version", tostring(weao.version))
		end
	end
	if status.message ~= "" then
		addRow("Notice", status.message)
	end
	if evaluation.force then
		addRow("Force load", "Enabled")
	end

	groupbox:CreateButton({
		Name = "Refresh status",
		Callback = function()
			Core.fetchScriptManifest(true)
			Core.fetchWeaoExploits(true)
			local nextEval = Core.evaluateScriptStatus(scriptId, profileVersion)
			local nextStatus = nextEval.status
			if labels.Status and labels.Status.Set then
				labels.Status:Set({ Name = "Status: " .. nextStatus.icon .. " " .. nextStatus.label })
			end
			if labels.Notice and nextStatus.message ~= "" then
				labels.Notice:Set({ Name = "Notice: " .. nextStatus.message })
			elseif labels.Notice and labels.Notice.Instance then
				labels.Notice.Instance.Visible = nextStatus.message ~= ""
			end
			local refreshedWeao = Core.fetchWeaoExecutorStatus()
			if refreshedWeao and labels.WEAO and labels.WEAO.Set then
				labels.WEAO:Set({ Name = "WEAO: " .. Core.weaoStatusLabel(refreshedWeao) })
			end
			Core.notify("Alleral", "Status refreshed — " .. nextStatus.label, 3)
		end,
	}, "RefreshStatus")

	Core._scriptStatusUI = {
		groupbox = groupbox,
		labels = labels,
		scriptId = scriptId,
		profileVersion = profileVersion,
	}
	return groupbox, evaluation
end

local function trimText(value)
	return tostring(value or ""):gsub("^%s*(.-)%s*$", "%1")
end

function Core.normalizeWebhookUrl(url)
	local text = trimText(url)
	if text == "" then
		return nil, "Webhook URL is empty."
	end
	if not text:find("^https://") and not text:find("^http://") then
		text = "https://" .. text
	end
	if
		not text:find("discord%.com/api/webhooks/")
		and not text:find("discordapp%.com/api/webhooks/")
	then
		return nil, "That doesn't look like a Discord webhook URL."
	end
	return text, nil
end

function Core.postWebhook(url, payload)
	local sender = Core.requestFunction()
	if not sender then
		return false, "HTTP is not available in this executor."
	end
	local postUrl, urlError = Core.normalizeWebhookUrl(url)
	if not postUrl then
		return false, urlError
	end
	local ok, response = pcall(function()
		return sender({
			Url = postUrl,
			Method = "POST",
			Headers = { ["Content-Type"] = "application/json" },
			Body = HttpService:JSONEncode(payload),
		})
	end)
	if not ok then
		return false, tostring(response)
	end
	if type(response) == "table" then
		if response.Success == false then
			local code = response.StatusCode or response.Status or response.status_code
			return false, "Webhook failed (HTTP " .. tostring(code or "?") .. ")"
		end
		local code = response.StatusCode or response.Status or response.status_code
		if type(code) == "number" and (code < 200 or code >= 300) then
			return false, "Webhook returned HTTP " .. tostring(code)
		end
	end
	return true, nil
end

function Core.loadStringFn()
	local candidates = {
		ENV.loadstring,
		ENV.LoadString,
		ENV.load,
		ENV.Load,
		loadstring,
		load,
	}
	for _, candidate in ipairs(candidates) do
		if type(candidate) == "function" then
			return candidate
		end
	end
	return Core.firstExecFunc("loadstring", "LoadString", "load", "Load")
end

function Core.readFile(path)
	local readFile = Core.execFunction("readfile")
	local isFile = Core.execFunction("isfile")
	if type(readFile) ~= "function" or type(isFile) ~= "function" or not isFile(path) then
		return nil
	end
	local ok, data = pcall(readFile, path)
	return ok and data or nil
end

function Core.writeFile(path, data)
	local writeFile = Core.execFunction("writefile")
	local makeFolder = ENV.makefolder
	if type(writeFile) ~= "function" then
		return false
	end
	pcall(function()
		if type(makeFolder) == "function" then
			makeFolder("Alleral_Configs")
		end
	end)
	return pcall(writeFile, path, data)
end

local function rayfieldOk(library)
	return type(library) == "table"
		and type(library.CreateWindow) == "function"
		and type(library.Notify) == "function"
end

local function stampRayfield(library)
	if type(library) ~= "table" then
		return library
	end
	library.InterfaceBuild = Core.UI_LIBRARY
	library.UI_LIBRARY = Core.UI_LIBRARY
	return library
end

local function rayfieldSourceValid(body)
	return type(body) == "string"
		and #body >= RAYFIELD_MIN_BYTES
		and (body:find("RayfieldLibrary", 1, true) or body:find("CreateWindow", 1, true))
end

local function compileRayfieldSource(source, label)
	local loadStringFn = Core.loadStringFn()
	if not loadStringFn or not source or source == "" then
		return nil, "Empty Rayfield source"
	end
	if not rayfieldSourceValid(source) then
		return nil, "Rayfield source too small or invalid (" .. tostring(#source) .. " bytes)"
	end
	local compiled, compileErr = loadStringFn(source, label)
	if not compiled and type(load) == "function" and load ~= loadStringFn then
		compiled, compileErr = load(source, label)
	end
	if not compiled then
		return nil, tostring(compileErr)
	end
	local ok, result = pcall(compiled)
	if ok and rayfieldOk(result) then
		return stampRayfield(result)
	end
	if not ok then
		warn("[Alleral] Rayfield runtime error: " .. tostring(result))
	end
	return nil, ok and "Invalid Rayfield library" or tostring(result)
end

local function fetchRayfieldSourceFromUrl(url)
	local sep = url:find("?") and "&" or "?"
	local nonce = tick()
	local fetchUrl = url .. sep .. "nocache=" .. tostring(nonce)
	return Core.httpGet(fetchUrl)
end

local function fetchRayfieldSource()
	for _, url in ipairs(RAYFIELD_MIRROR_URLS) do
		local body = fetchRayfieldSourceFromUrl(url)
		if rayfieldSourceValid(body) then
			return body, url
		end
	end
	return nil, nil
end

local function cacheRayfield(library)
	stampRayfield(library)
	ENV.Alleral_Rayfield = library
	ENV.Alleral_UI = library
	return library
end

function Core.loadRayfield()
	local cached = ENV.Alleral_Rayfield or ENV.Alleral_UI
	if rayfieldOk(cached) then
		return cacheRayfield(cached)
	end
	ENV.Alleral_Rayfield = nil
	ENV.Alleral_UI = nil

	local loadStringFn = Core.loadStringFn()
	if not loadStringFn then
		return nil, "loadstring unavailable"
	end

	local function loadLocalRayfield()
		local roots = { "", "kick/", "kick/kick/", "workspace/", "scripts/" }
		for _, root in ipairs(roots) do
			for _, path in ipairs(RAYFIELD_LOCAL_FILES) do
				local fullPath = root .. path
				local source = Core.readFile(fullPath)
				if source then
					local library, err = compileRayfieldSource(source, "@Rayfield/local:" .. fullPath)
					if library then
						warn("[Alleral] Rayfield loaded from " .. fullPath)
						return cacheRayfield(library)
					end
					warn("[Alleral] Local Rayfield failed (" .. fullPath .. "): " .. tostring(err))
				end
			end
		end
		return nil
	end

	local localLibrary = loadLocalRayfield()
	if localLibrary then
		return localLibrary
	end

	local source, sourceUrl = fetchRayfieldSource()
	if source then
		local library, err = compileRayfieldSource(source, "@Rayfield/remote")
		if library then
			warn("[Alleral] Rayfield loaded from " .. tostring(sourceUrl or RAYFIELD_SOURCE_URL))
			return cacheRayfield(library)
		end
		warn("[Alleral] Rayfield compile failed: " .. tostring(err))
		return nil, err or "Invalid Rayfield library"
	end

	localLibrary = loadLocalRayfield()
	if localLibrary then
		return localLibrary
	end

	return nil, "Rayfield download failed — check HTTP or docs.sirius.menu/rayfield"
end

function Core.httpGet(url)
	if type(url) ~= "string" or url == "" then
		return nil
	end
	local function accept(body)
		if type(body) ~= "string" or body == "" then
			return false
		end
		if body:find("404: Not Found", 1, true) then
			return false
		end
		if body:find("<!DOCTYPE html>", 1, true) or body:find("<html", 1, true) then
			return body:find("function ", 1, true) ~= nil
		end
		return true
	end
	local function extractBody(response)
		if type(response) == "string" then
			return response
		end
		if type(response) == "table" then
			return response.Body or response.body or response.Data or response.data
		end
		return nil
	end

	if type(game.HttpGet) == "function" then
		local ok, body = pcall(game.HttpGet, game, url, true)
		if ok and accept(body) then
			return body
		end
		ok, body = pcall(game.HttpGet, game, url)
		if ok and accept(body) then
			return body
		end
	end

	local ok, body = pcall(function()
		return game:HttpGet(url, true)
	end)
	if ok and accept(body) then
		return body
	end

	ok, body = pcall(function()
		return game:HttpGet(url)
	end)
	if ok and accept(body) then
		return body
	end

	if type(HttpService.GetAsync) == "function" then
		ok, body = pcall(function()
			return HttpService:GetAsync(url, true)
		end)
		if ok and accept(body) then
			return body
		end
	end

	local httpGet = Core.requestFunction()
	if httpGet then
		for _, spec in ipairs({
			{
				Url = url,
				Method = "GET",
				Headers = {
					["Cache-Control"] = "no-cache, no-store, must-revalidate",
					["Pragma"] = "no-cache",
				},
			},
			{
				url = url,
				method = "GET",
				headers = {
					["Cache-Control"] = "no-cache, no-store, must-revalidate",
					["Pragma"] = "no-cache",
				},
			},
		}) do
			local reqOk, response = pcall(httpGet, spec)
			if reqOk then
				body = extractBody(response)
				local status = type(response) == "table" and (response.StatusCode or response.status or response.Status or 200) or 200
				if accept(body) and (status == 0 or (status >= 200 and status < 300)) then
					return body
				end
			end
		end
	end

	return nil
end

function Core.httpGetJson(url)
	local body = Core.httpGet(url)
	if not body then
		return nil, "HTTP unavailable"
	end
	local ok, decoded = pcall(function()
		return HttpService:JSONDecode(body)
	end)
	if not ok or type(decoded) ~= "table" then
		return nil, "Invalid response from RoScripts"
	end
	return decoded
end

function Core.setClipboard(text)
	local clip = Core.execFunction("setclipboard") or Core.execFunction("toclipboard")
	if clip then
		pcall(clip, tostring(text or ""))
		return true
	end
	return false
end

function Core.searchRoScripts(query, options)
	options = options or {}
	query = trimText(query)
	if query == "" then
		return nil, "Enter a search term"
	end
	local params = {
		"page=" .. tostring(options.page or 1),
		"orderBy=" .. HttpService:UrlEncode(options.orderBy or "views"),
		"sort=desc",
		"q=" .. HttpService:UrlEncode(query),
	}
	if options.freeOnly ~= false then
		table.insert(params, "notPaid=true")
	end
	if options.noKey then
		table.insert(params, "noKeySystem=true")
	end
	if options.unpatched then
		table.insert(params, "unpatched=true")
	end
	local url = ROSCRIPTS_SEARCH_URL .. "?" .. table.concat(params, "&")
	local data, err = Core.httpGetJson(url)
	if not data then
		return nil, err
	end
	if type(data.scripts) ~= "table" then
		return nil, "RoScripts returned no results"
	end
	return {
		scripts = data.scripts,
		page = data.info and data.info.currentPage or 1,
		maxPages = data.info and data.info.maxPages or 1,
	}, nil
end

function Core.formatRoScriptLabel(entry)
	local title = tostring(entry.title or "Untitled")
	if #title > 46 then
		title = title:sub(1, 43) .. "..."
	end
	local gameTitle = entry.game and entry.game.title or "Universal"
	local author = entry.user and entry.user.username or "unknown"
	local suffix = entry.keySystem and " [Key]" or ""
	return title .. " — " .. gameTitle .. " (@" .. author .. ")" .. suffix
end

function Core.roScriptWebUrl(entry)
	if type(entry) ~= "table" then
		return ROSCRIPTS_WEB_HOME
	end
	if entry.slug and entry.slug ~= "" then
		return ROSCRIPTS_WEB_SCRIPT .. entry.slug
	end
	if entry._id then
		return ROSCRIPTS_WEB_SCRIPT .. tostring(entry._id)
	end
	return ROSCRIPTS_WEB_HOME
end

function Core.executeRoScript(entry, rayfield)
	if type(entry) ~= "table" or type(entry.rawScript) ~= "string" or entry.rawScript == "" then
		return false, "No script selected"
	end
	local notify = rayfield and rayfield.Notify
	if notify then
		pcall(notify, rayfield, {
			Title = "RoScripts",
			Content = "Loading: " .. tostring(entry.title or "script"),
			Duration = 4,
		})
	end
	local source = Core.httpGet(entry.rawScript)
	if not source or source == "" then
		return false, "Could not download script source"
	end
	local loadStringFn = Core.loadStringFn()
	if not loadStringFn then
		return false, "loadstring unavailable"
	end
	local compiled, compileErr = loadStringFn(source, "@RoScripts/" .. tostring(entry.slug or entry._id or "script"))
	if not compiled then
		return false, tostring(compileErr)
	end
	local ok, runErr = pcall(compiled)
	if not ok then
		return false, tostring(runErr)
	end
	return true
end

function Core.buildRoScriptsSearch(tab, column, rayfield)
	local group = Core.buildRayfieldGroup(tab, "RoScripts", column or 2)
	local browser = {
		query = "",
		freeOnly = true,
		noKey = false,
		entries = {},
		byLabel = {},
		selected = nil,
	}

	local status = group:CreateStatus("RoScripts", {
		Status = "Ready",
		Results = "0",
		Selected = "None",
	})

	group:CreateToggle("Free scripts only", true, nil, function(value)
		browser.freeOnly = value == true
	end)
	group:CreateToggle("No key system", false, nil, function(value)
		browser.noKey = value == true
	end)

	local queryInput = group:CreateInput("Search query", "auto farm, hub, ESP...", "", function(text)
		browser.query = tostring(text or "")
	end)

	local resultsDropdown

	local function applyResults(entries)
		browser.entries = entries or {}
		browser.byLabel = {}
		local labels = {}
		for index, entry in ipairs(browser.entries) do
			local label = Core.formatRoScriptLabel(entry)
			browser.byLabel[label] = entry
			labels[index] = label
		end
		if #labels == 0 then
			labels = { "No results" }
			browser.selected = nil
		else
			browser.selected = browser.entries[1]
		end
		if resultsDropdown then
			resultsDropdown:Refresh(labels, labels[1])
		end
		status:Update("Results", tostring(#browser.entries))
		status:Update("Selected", browser.selected and browser.selected.title or "None")
	end

	local function runSearch(query)
		query = trimText(query)
		if query == "" then
			status:Update("Status", "Enter a search term")
			return
		end
		status:Update("Status", "Searching...")
		task.spawn(function()
			local data, err = Core.searchRoScripts(query, {
				freeOnly = browser.freeOnly,
				noKey = browser.noKey,
			})
			if not data then
				status:Update("Status", tostring(err or "Search failed"))
				applyResults({})
				return
			end
			status:Update("Status", "Found " .. tostring(#data.scripts) .. " script(s)")
			applyResults(data.scripts)
		end)
	end

	resultsDropdown = group:AddDropdown("roscripts_results", {
		Text = "Results",
		Values = { "Search to populate" },
		Default = "Search to populate",
		Callback = function(selected)
			browser.selected = browser.byLabel[selected]
			status:Update("Selected", browser.selected and browser.selected.title or "None")
		end,
	})

	group:CreateButton("Search RoScripts", function()
		runSearch(browser.query)
	end, "Query RoScripts.io via rscripts.net API")

	group:CreateButton("Search this game", function()
		local gameName = ""
		pcall(function()
			gameName = game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId).Name
		end)
		if gameName == "" then
			gameName = tostring(game.PlaceId)
		end
		browser.query = gameName
		if queryInput and queryInput.Set then
			queryInput:Set({ CurrentValue = gameName })
		end
		runSearch(gameName)
	end, "Find scripts for the current place")

	group:CreateButton("Load selected script", function()
		local ok, err = Core.executeRoScript(browser.selected, rayfield)
		if ok then
			status:Update("Status", "Script loaded")
			Core.notify("RoScripts", "Script executed.", 3)
		else
			status:Update("Status", tostring(err or "Load failed"))
			Core.notify("RoScripts", tostring(err or "Load failed"), 5)
		end
	end, "Runs the selected script in your executor")

	group:CreateButton("Copy RoScripts link", function()
		local url = Core.roScriptWebUrl(browser.selected)
		if Core.setClipboard(url) then
			status:Update("Status", "Link copied")
			Core.notify("RoScripts", "Link copied to clipboard.", 3)
		else
			status:Update("Status", "Clipboard unavailable")
		end
	end)

	group:CreateButton("Open RoScripts.io", function()
		if Core.setClipboard(ROSCRIPTS_WEB_HOME) then
			Core.notify("RoScripts", "Open roscripts.io in your browser.", 4)
		end
	end)

	group:CreateLabel("Powered by RoScripts.io")
	return group
end

local function fakeUiInstance(visible)
	return {
		Visible = visible ~= false,
		Name = "AlleralGroupShell",
	}
end

function Core.createRayfieldGroupbox(tab, sectionName)
	if sectionName and sectionName ~= "" then
		tab:CreateSection(sectionName)
	end

	local shell = fakeUiInstance(true)
	local groupbox = {
		Instance = shell,
		ParentingItem = shell,
	}
	local serial = 0

	local function nextFlag(name, explicit)
		serial += 1
		return explicit or Core.uiElementId(name) .. "_" .. serial
	end

	local function wrapElement(elem, applySet)
		return {
			Instance = shell,
			Set = function(_, settings)
				if type(settings) == "table" then
					applySet(settings, elem)
				else
					applySet({ CurrentValue = settings }, elem)
				end
			end,
		}
	end

	function groupbox:CreateToggle(settings, id)
		local elem = tab:CreateToggle({
			Name = settings.Name,
			CurrentValue = settings.CurrentValue == true,
			Flag = nextFlag(settings.Name, id),
			Callback = settings.Callback or function() end,
		})
		return wrapElement(elem, function(nextSettings)
			if nextSettings.CurrentValue ~= nil then
				elem:Set(nextSettings.CurrentValue == true)
			end
		end)
	end

	function groupbox:CreateSlider(settings, id)
		local range = settings.Range or { 0, 100 }
		local elem = tab:CreateSlider({
			Name = settings.Name,
			Range = range,
			Increment = settings.Increment or (range[2] <= 5 and 0.05 or 1),
			Suffix = settings.Suffix,
			CurrentValue = tonumber(settings.CurrentValue) or range[1],
			Flag = nextFlag(settings.Name, id),
			Callback = settings.Callback or function() end,
		})
		return wrapElement(elem, function(nextSettings)
			if nextSettings.CurrentValue ~= nil then
				elem:Set(tonumber(nextSettings.CurrentValue) or range[1])
			end
		end)
	end

	function groupbox:CreateButton(settings, id)
		local elem = tab:CreateButton({
			Name = settings.Name,
			Callback = settings.Callback or function() end,
		})
		return wrapElement(elem, function(nextSettings)
			if nextSettings.Name then
				elem:Set(nextSettings.Name)
			end
		end)
	end

	function groupbox:CreateInput(settings, id)
		local elem = tab:CreateInput({
			Name = settings.Name,
			PlaceholderText = settings.PlaceholderText or settings.Placeholder or "",
			CurrentValue = settings.CurrentValue or "",
			RemoveTextAfterFocusLost = settings.RemoveTextOnFocus == true,
			Flag = nextFlag(settings.Name, id),
			Callback = settings.Callback or function() end,
		})
		return wrapElement(elem, function(nextSettings)
			if nextSettings.CurrentValue ~= nil then
				elem:Set(tostring(nextSettings.CurrentValue))
			end
		end)
	end

	function groupbox:CreateDropdown(settings, id)
		local current = settings.CurrentOption
		if type(current) ~= "table" then
			current = current and current ~= "" and { tostring(current) } or {}
		end
		local elem = tab:CreateDropdown({
			Name = settings.Name,
			Options = settings.Options or settings.Values or {},
			CurrentOption = current,
			MultipleOptions = settings.MultipleOptions == true,
			Flag = nextFlag(settings.Name, id),
			Callback = settings.Callback or function() end,
		})
		return wrapElement(elem, function(nextSettings)
			if nextSettings.CurrentOption or nextSettings.CurrentOptions then
				elem:Set(nextSettings.CurrentOption or nextSettings.CurrentOptions)
			end
		end)
	end

	function groupbox:CreateLabel(settings, id)
		local text = type(settings) == "table" and (settings.Name or settings.Text) or tostring(settings or "")
		local elem = tab:CreateLabel(text)
		return {
			Instance = shell,
			Set = function(_, nextSettings)
				local nextText = type(nextSettings) == "table" and (nextSettings.Name or nextSettings.Text)
					or tostring(nextSettings or "")
				elem:Set(nextText)
			end,
			AddDropdown = function(_, nestedSettings, nestedId)
				return groupbox:CreateDropdown({
					Name = nestedSettings.Name or text,
					Options = nestedSettings.Options or nestedSettings.Values or {},
					CurrentOption = nestedSettings.CurrentOption,
					MultipleOptions = nestedSettings.MultipleOptions,
					Callback = nestedSettings.Callback,
				}, nestedId)
			end,
		}
	end

	function groupbox:CreateDivider()
		tab:CreateDivider()
		return { Instance = shell }
	end

	return groupbox
end

function Core.wrapRayfieldTab(rawTab, rayfield, window)
	local tab = {
		_rawTab = rawTab,
		_rayfield = rayfield,
		_window = window,
	}

	function tab:CreateGroupbox(settings)
		return Core.createRayfieldGroupbox(rawTab, settings and settings.Name)
	end

	function tab:BuildThemeGroupbox(column)
		local group = Core.buildRayfieldGroup(tab, "Appearance", column or 1)
		group:CreateDropdown("Theme preset", RAYFIELD_THEME_NAMES, "Default", function(selected)
			if window and type(window.ModifyTheme) == "function" then
				window:ModifyTheme(selected)
			elseif rayfield and rayfield.Notify then
				rayfield:Notify({
					Title = "Theme",
					Content = "Applied " .. tostring(selected),
					Duration = 2,
				})
			end
		end)
		return group
	end

	return tab
end

function Core.ensureCore()
	if ENV.Alleral_Core then
		return ENV.Alleral_Core
	end
	local loadStringFn = Core.loadStringFn()
	local isFile = ENV.isfile
	local readFile = ENV.readfile
	if type(loadStringFn) ~= "function" or type(isFile) ~= "function" or type(readFile) ~= "function" then
		return nil
	end
	for _, path in ipairs({ "core/alleral_core.luau", "src/alleral_core.luau", "alleral_core.luau" }) do
		if isFile(path) then
			local ok = pcall(loadStringFn(readFile(path), "Alleral/core")())
			if ok and ENV.Alleral_Core then
				return ENV.Alleral_Core
			end
		end
	end
	return nil
end

local function signalBootFailure(message)
	ENV.Alleral_StartupFailed = message
	if ENV.Alleral_State then
		ENV.Alleral_State.StartupFailed = message
	end
	pcall(function()
		if shared then
			shared.Alleral_StartupFailed = message
		end
	end)
	local report = ENV.Alleral_ReportError
	if type(report) == "function" then
		pcall(report, "boot", message)
	end
end

function Core.prepareGame(state)
	state = state or ENV.Alleral_State
	if not state then
		local msg = "Alleral_State missing"
		signalBootFailure(msg)
		return nil, nil, msg
	end
	local core = Core.ensureCore()
	if not core then
		local msg = "Alleral_Core missing, run loader.luau first"
		signalBootFailure(msg)
		return nil, nil, msg
	end
	state.HubRunning = state.HubRunning ~= false
	core.initAnalytics()
	if state.AntiAFK ~= false then
		core.setupAntiAfk(game:GetService("Players").LocalPlayer)
	end
	local uiLibrary, err = core.loadRayfield()
	if not uiLibrary then
		local msg = err or "Rayfield unavailable"
		signalBootFailure(msg)
		return nil, nil, msg
	end
	pcall(function()
		if core.refreshLoaderCapabilities then
			core.refreshLoaderCapabilities()
		end
		if core.fetchScriptManifest then
			core.fetchScriptManifest(false)
		end
		if core.fetchWeaoExploits then
			task.spawn(function()
				core.fetchWeaoExploits(false)
				if core.refreshLoaderCapabilities then
					core.refreshLoaderCapabilities()
				end
			end)
		end
		if core.notifyExecutorCompat then
			core.notifyExecutorCompat()
		end
	end)
	return core, uiLibrary
end

function Core.stopAutomation(state, connections, loopControllers, loops, onStop)
	state.HubRunning = false
	for name, controller in pairs(loopControllers) do
		if controller then
			controller.enabled = false
		end
		loopControllers[name] = nil
	end
	for _, loopState in pairs(loops) do
		loopState.enabled = false
	end
	for key, connection in pairs(connections) do
		if connection and connection.Disconnect then
			pcall(function()
				connection:Disconnect()
			end)
		end
		connections[key] = nil
	end
	if onStop then
		pcall(onStop)
	end
end

function Core.saveSettings(state, keys, filename)
	local payload = {}
	for _, key in ipairs(keys) do
		payload[key] = state[key]
	end
	Core.writeFile("Alleral_Configs/" .. filename, HttpService:JSONEncode(payload))
end

function Core.loadSettings(state, keys, filename)
	local raw = Core.readFile("Alleral_Configs/" .. filename)
	if not raw then
		return
	end
	local ok, decoded = pcall(function()
		return HttpService:JSONDecode(raw)
	end)
	if not ok or type(decoded) ~= "table" then
		return
	end
	for _, key in ipairs(keys) do
		if decoded[key] ~= nil then
			state[key] = decoded[key]
		end
	end
end

function Core.wrapUiGroup(groupbox, callbackWrapper)
	local group = {}
	local serial = 0
	local MAX_RENDERED_DROPDOWN_OPTIONS = 50

	local function nextId(name)
		serial += 1
		return tostring(name) .. "_" .. HttpService:GenerateGUID(false):sub(1, 8) .. "_" .. serial
	end

	local function wrap(label, callback)
		callback = callback or function() end
		if not callbackWrapper then
			return callback
		end
		for _, args in ipairs({ { label, callback }, { callback } }) do
			local ok, wrapped = pcall(callbackWrapper, table.unpack(args))
			if ok and type(wrapped) == "function" then
				return wrapped
			end
		end
		return callback
	end

	local function normalizeOptions(values)
		local output = {}
		local seen = {}
		for _, value in ipairs(values or {}) do
			local text = tostring(value)
			if text ~= "" and not seen[text] then
				seen[text] = true
				table.insert(output, text)
			end
		end
		return output
	end

	local function currentSelection(default, multi)
		if type(default) == "table" then
			local copy = {}
			for i, v in ipairs(default) do
				copy[i] = v
			end
			for k, v in pairs(default) do
				if type(k) ~= "number" then
					copy[k] = v
				end
			end
			return copy
		end
		if multi then
			return default and { tostring(default) } or {}
		end
		return tostring(default or "")
	end

	local function compactOptions(values, selected, limit)
		values = normalizeOptions(values)
		limit = limit or MAX_RENDERED_DROPDOWN_OPTIONS
		if #values <= limit then
			return values
		end
		local output = {}
		local seen = {}
		local selectedList = type(selected) == "table" and selected or { selected }
		for _, value in ipairs(selectedList) do
			local text = tostring(value)
			if text ~= "" and not seen[text] then
				seen[text] = true
				table.insert(output, text)
			end
		end
		for _, value in ipairs(values) do
			if #output >= limit then
				break
			end
			if not seen[value] then
				table.insert(output, value)
			end
		end
		return output
	end

	local function waitForElement(element, timeout)
		local started = tick()
		repeat
			if element and element.Instance then
				return true
			end
			task.wait()
		until tick() - started >= (timeout or 3)
		return element and element.Instance ~= nil
	end

	local function setVisible(element, visible)
		waitForElement(element, 1)
		if element and element.Instance then
			element.Instance.Visible = visible
		end
	end

	function group:CreateToggle(name, default, tooltip, callback)
		return groupbox:CreateToggle({
			Name = name,
			CurrentValue = default == true,
			Tooltip = tooltip,
			Callback = wrap(name, callback),
		}, nextId(name))
	end

	function group:CreateSlider(name, min, max, default, callback, tooltip)
		return groupbox:CreateSlider({
			Name = name,
			Range = { min, max },
			Increment = max <= 5 and 0.05 or 1,
			CurrentValue = tonumber(default) or min,
			Tooltip = tooltip,
			Callback = wrap(name, callback),
		}, nextId(name))
	end

	function group:CreateButton(name, callback, tooltip)
		return groupbox:CreateButton({
			Name = name,
			Tooltip = tooltip,
			Callback = wrap(name, callback),
		}, nextId(name))
	end

	function group:CreateInput(name, placeholder, arg3, arg4, arg5)
		local icon, default, callback, tip
		local function isIcon(value)
			local text = tostring(value or "")
			return text:find("rbxassetid") ~= nil or text:match("^%d+$") ~= nil
		end
		if type(arg3) == "function" then
			callback = arg3
			tip = arg4
		elseif type(arg4) == "function" and isIcon(arg3) then
			icon = Core.uiIcon(arg3)
			callback = arg4
			tip = arg5
		elseif type(arg4) == "function" then
			default = tostring(arg3 or "")
			callback = arg4
			tip = arg5
		else
			icon = Core.uiIcon(arg3)
			callback = arg4
			tip = arg5
		end
		return groupbox:CreateInput({
			Name = name,
			Icon = icon,
			Placeholder = placeholder,
			PlaceholderText = placeholder,
			CurrentValue = default or "",
			RemoveTextOnFocus = false,
			Tooltip = tip,
			Callback = wrap(name, callback),
		}, nextId(name))
	end

	function group:CreateDropdown(name, options, default, callback, tooltip)
		return groupbox:CreateDropdown({
			Name = name,
			Options = normalizeOptions(options),
			CurrentOption = default,
			Tooltip = tooltip,
			Callback = wrap(name, callback),
		}, nextId(name))
	end

	function group:AddDropdown(id, config)
		config = config or {}
		local multi = config.Multi == true or config.MultiSelection == true
		local values = normalizeOptions(config.Values or config.Options)
		local current = currentSelection(config.Default or config.CurrentValue or config.CurrentOption, multi)
		local label = groupbox:CreateLabel({
			Name = config.Text or config.Name or id,
			Tooltip = config.Tooltip or config.Description,
		}, nextId(id))
		local handle = {
			Values = values,
			Selection = current,
			Dropdown = nil,
			Label = label,
			LastSearch = "",
		}
		local function safeCallback(selection)
			handle.Selection = currentSelection(selection, multi)
			wrap(config.Text or config.Name or id, config.Callback or function() end)(selection)
		end
		local function rebuild(currentValues)
			local nextValues = currentValues or handle.Values
			if config.Searchable then
				nextValues = compactOptions(nextValues, handle.Selection)
			end
			if handle.Dropdown and handle.Dropdown.Set then
				handle.Dropdown:Set({
					Options = nextValues,
					Values = nextValues,
					CurrentOption = handle.Selection,
					CurrentOptions = type(handle.Selection) == "table" and handle.Selection or nil,
					MultipleOptions = multi,
					Placeholder = config.Placeholder or "--",
					Callback = safeCallback,
				})
			end
		end
		if not waitForElement(label, 3) or not (label.Instance and label.Instance:FindFirstChild("DropdownHolder")) then
			local renderedValues = config.Searchable and compactOptions(values, current) or values
			local dropdown = groupbox:CreateDropdown({
				Name = config.Text or config.Name or id,
				Options = renderedValues,
				Values = renderedValues,
				CurrentOption = current,
				MultipleOptions = multi,
				Callback = safeCallback,
			}, nextId(id .. "_dd"))
			handle.Dropdown = dropdown
			function handle:SetValues(newValues, newDefault)
				self.Values = normalizeOptions(newValues)
				self.Selection = currentSelection(newDefault or self.Selection, multi)
				rebuild(self.Values)
			end
			function handle:Refresh(newValues, newDefault)
				self:SetValues(newValues, newDefault)
			end
			function handle:Search(query)
				self.LastSearch = tostring(query or "")
				local filtered = self.LastSearch == "" and self.Values
					or compactOptions(Core.filterDropdownOptions(self.Values, self.LastSearch), self.Selection)
				rebuild(filtered)
			end
			if config.Searchable then
				groupbox:CreateInput({
					Name = (config.Text or config.Name or id) .. " filter",
					PlaceholderText = "search...",
					RemoveTextOnFocus = false,
					Callback = wrap((config.Text or config.Name or id) .. " Search", function(text)
						handle:Search(text)
					end),
				}, nextId(id .. "_search"))
			end
			return handle
		end
		local renderedValues = config.Searchable and compactOptions(values, current) or values
		local dropdown = label:AddDropdown({
			Options = renderedValues,
			Values = renderedValues,
			CurrentOption = current,
			CurrentOptions = multi and current or nil,
			MultipleOptions = multi,
			Placeholder = config.Placeholder or "--",
			Callback = safeCallback,
		}, nextId(id .. "_dd"))
		handle.Dropdown = dropdown
		function handle:SetValues(newValues, newDefault)
			self.Values = normalizeOptions(newValues)
			self.Selection = currentSelection(newDefault or self.Selection, multi)
			rebuild(self.Values)
		end
		function handle:Refresh(newValues, newDefault)
			self:SetValues(newValues, newDefault)
		end
		function handle:Search(query)
			self.LastSearch = tostring(query or "")
			local filtered = self.LastSearch == "" and self.Values
				or compactOptions(Core.filterDropdownOptions(self.Values, self.LastSearch), self.Selection)
			rebuild(filtered)
		end
		if config.Searchable then
			groupbox:CreateInput({
				Name = (config.Text or config.Name or id) .. " filter",
				PlaceholderText = "search...",
				RemoveTextOnFocus = false,
				Callback = wrap((config.Text or config.Name or id) .. " Search", function(text)
					handle:Search(text)
				end),
			}, nextId(id .. "_search"))
		end
		return handle
	end

	function group:CreateLabel(text)
		return groupbox:CreateLabel({
			Name = text,
		}, nextId("label"))
	end

	function group:CreateStatus(label, fields)
		local status = {
			Labels = {},
			LastValues = {},
			Visible = true,
		}
		for key, value in pairs(fields or {}) do
			local rendered = tostring(value)
			status.LastValues[key] = rendered
			status.Labels[key] = groupbox:CreateLabel({
				Name = tostring(key) .. ": " .. rendered,
			}, nextId(label .. "_" .. tostring(key)))
		end
		function status:Update(key, value)
			local rendered = tostring(value)
			if self.LastValues[key] == rendered then
				return
			end
			self.LastValues[key] = rendered
			local row = self.Labels[key]
			if row and row.Set then
				row:Set({ Name = tostring(key) .. ": " .. rendered })
			end
		end
		function status:SetVisible(visible)
			self.Visible = visible
			for _, row in pairs(self.Labels) do
				setVisible(row, visible)
			end
		end
		return status
	end

	function group:CreateDivider()
		return groupbox:CreateDivider()
	end

	return group
end

function Core.uiIcon(icon)
	return tostring(icon or ""):match("%d+$") or ""
end

function Core.uiElementId(text)
	return (tostring(text or "Element"):gsub("[^%w_]", "_"))
end

function Core.buildRayfieldWindow(rayfield, settings)
	settings = settings or {}
	local fileSettings = settings.FileSettings or {}
	local window = rayfield:CreateWindow({
		Name = settings.Name or "Alleral",
		LoadingTitle = settings.Name or "Alleral",
		LoadingSubtitle = settings.Subtitle or "",
		Icon = tonumber(Core.uiIcon(settings.Icon or 10723407389)) or 10723407389,
		ConfigurationSaving = {
			Enabled = fileSettings.Enabled ~= false,
			FolderName = fileSettings.RootFolder or fileSettings.ConfigFolder or "Alleral_Configs",
			FileName = fileSettings.FileName or tostring(game.PlaceId),
		},
		DisableRayfieldPrompts = true,
		DisableBuildWarnings = true,
		KeySystem = false,
	})
	window._rayfield = rayfield
	return window
end

function Core.buildRayfieldSection(window, name, expanded)
	return {
		_window = window,
		_rayfield = window._rayfield,
	}
end

function Core.buildRayfieldTab(section, name, icon, columns, id)
	local window = section._window or section
	local rawTab = window:CreateTab(name, tonumber(Core.uiIcon(icon or 10723407389)) or 10723407389)
	return Core.wrapRayfieldTab(rawTab, window._rayfield or section._rayfield, window)
end

function Core.onUiSave(saveFn)
	return function(_, callback)
		return function(...)
			local result = callback(...)
			if type(saveFn) == "function" then
				saveFn()
			end
			return result
		end
	end
end

function Core.buildRayfieldGroup(tab, name, column, callbackWrapper, icon, id)
	local groupbox = tab:CreateGroupbox({
		Name = name,
		Column = column or 1,
		Icon = icon and Core.uiIcon(icon) or nil,
	}, id or Core.uiElementId(name))
	if callbackWrapper then
		return Core.wrapUiGroup(groupbox, callbackWrapper)
	end
	return Core.wrapUiGroup(groupbox)
end

function Core.filterDropdownOptions(values, query)
	query = tostring(query or ""):lower()
	if query == "" then
		return values
	end
	local filtered = {}
	for _, value in ipairs(values or {}) do
		if tostring(value):lower():find(query, 1, true) then
			table.insert(filtered, value)
		end
	end
	return filtered
end

function Core.makeSupervisor(state, loops, controllers, name, interval, callback)
	if controllers[name] then
		controllers[name].enabled = false
		controllers[name] = nil
	end
	local loopState = {
		enabled = true,
		token = HttpService:GenerateGUID(false),
	}
	loops[name] = loopState
	controllers[name] = loopState
	task.spawn(function()
		local token = loopState.token
		while state.HubRunning and loopState.enabled and controllers[name] == loopState and loopState.token == token do
			local ok, err = pcall(callback)
			if not ok then
				Core.reportError("Loop:" .. name, err)
				warn("[Alleral:" .. name .. "] " .. tostring(err))
				task.wait(math.min(5, interval * 2))
			else
				task.wait(interval)
			end
		end
	end)
end

function Core.setupAntiAfk(player)
	local getConnections = ENV.getconnections or ENV.get_signal_cons
	if getConnections then
		for _, connection in ipairs(getConnections(player.Idled)) do
			if connection.Disable then
				connection:Disable()
			elseif connection.Disconnect then
				connection:Disconnect()
			end
		end
	else
		local VirtualUser = game:GetService("VirtualUser")
		player.Idled:Connect(function()
			pcall(function()
				VirtualUser:CaptureController()
				VirtualUser:ClickButton2(Vector2.new(0, 0))
			end)
		end)
	end
	task.spawn(function()
		local VirtualUser = game:GetService("VirtualUser")
		while player.Parent do
			task.wait(120)
			pcall(function()
				local camera = workspace.CurrentCamera
				if not camera then
					return
				end
				VirtualUser:Button2Down(Vector2.new(100, 100), camera.CFrame)
				task.wait(0.2)
				VirtualUser:Button2Up(Vector2.new(100, 100), camera.CFrame)
			end)
		end
	end)
end

function Core.initAnalytics()
	local tracker = ENV.Alleral_Analytics
	if tracker and tracker.Track then
		tracker:Track()
	end
	return tracker
end

function Core.reportError(scope, err, details)
	local reporter = ENV.Alleral_ReportError
	if type(reporter) == "function" then
		pcall(reporter, scope, err, details)
	end
end

function Core.logEvent(category, message, data)
	local logger = ENV.Alleral_LogEvent
	if type(logger) == "function" then
		pcall(logger, category, message, data)
	end
end

ENV.Alleral_Core = Core
return Core

=]

local SHARED_CORE_FILES = {
	"core/alleral_core.luau",
	"src/alleral_core.luau",
	"alleral_core.luau",
}
local SHARED_ANALYTICS_FILES = {
	"core/analytics.luau",
	"src/analytics.luau",
	"analytics.luau",
}
local SHARED_TELEMETRY_FILES = {
	"core/telemetry.luau",
	"src/telemetry.luau",
	"telemetry.luau",
}
local SHARED_HELPERS_FILES = {
	"core/game_helpers.luau",
	"src/game_helpers.luau",
	"game_helpers.luau",
}
local DEFAULT_TELEMETRY_RELAY = "https://alleral-telemetry-production.up.railway.app/ingest"

local OWNER_TELEMETRY_FILES = {
	"../Alleral-Private/owner_telemetry.luau",
	"Alleral-Private/owner_telemetry.luau",
	"kick/Alleral-Private/owner_telemetry.luau",
	"kick/../Alleral-Private/owner_telemetry.luau",
	"config/owner_telemetry.luau",
	"kick/kick/config/owner_telemetry.luau",
	"../../Alleral-Private/owner_telemetry.luau",
	"kick/kick/../Alleral-Private/owner_telemetry.luau",
	"workspace/Alleral-Private/owner_telemetry.luau",
	"workspace/../Alleral-Private/owner_telemetry.luau",
	"owner_telemetry.luau",
}
local OWNER_TELEMETRY_ENV_FILES = {
	"backend/.env",
	"kick/kick/backend/.env",
	"../backend/.env",
	"config/telemetry.env",
}
local TELEMETRY_MODULE_VERSION = "2.2"
local SHARED_CORE_PATH = "core/alleral_core.luau"
local SHARED_ANALYTICS_PATH = "core/analytics.luau"
local SHARED_TELEMETRY_PATH = "core/telemetry.luau"
local SHARED_HELPERS_PATH = "core/game_helpers.luau"

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = nil
pcall(function()
	HttpService = game:GetService("HttpService")
end)
local Workspace = game:GetService("Workspace")

local function genv()
	local ok, env = pcall(function()
		return getgenv and getgenv() or getfenv()
	end)
	return ok and env or {}
end

local ENV = genv()

local function safeTime()
	if type(os) == "table" and type(os.time) == "function" then
		local ok, value = pcall(os.time)
		if ok and type(value) == "number" then
			return value
		end
	end
	return typeof(tick) == "function" and tick() or 0
end

local function safeWait(seconds)
	if typeof(task) == "table" and type(task.wait) == "function" then
		task.wait(seconds)
	elseif type(wait) == "function" then
		wait(seconds)
	end
end

local function firstExecFunc(...)
	for i = 1, select("#", ...) do
		local name = select(i, ...)
		if type(name) == "function" then
			return name
		end
		if type(name) == "string" then
			local fn = ENV[name] or (_G and _G[name]) or (getfenv and getfenv()[name])
			if type(fn) == "function" then
				return fn
			end
		end
	end
	return nil
end

local function resolveHttpRequest()
	local sharedEnv = ENV.shared or (typeof(shared) == "table" and shared) or nil
	local solaraLib = sharedEnv and type(sharedEnv.solara) == "table" and sharedEnv.solara or nil
	local soloraLib = sharedEnv and type(sharedEnv.Solora) == "table" and sharedEnv.Solora or nil
	local candidates = {
		solaraLib and solaraLib.request,
		soloraLib and soloraLib.request,
		type(ENV.Solara) == "table" and ENV.Solara.request or nil,
		type(ENV.Solora) == "table" and ENV.Solora.request or nil,
		type(ENV.Volt) == "table" and ENV.Volt.request or nil,
		type(ENV.Wave) == "table" and ENV.Wave.request or nil,
		type(ENV.Xeno) == "table" and ENV.Xeno.request or nil,
		type(ENV.Krnl) == "table" and ENV.Krnl.request or nil,
		type(ENV.syn) == "table" and ENV.syn.request or nil,
		type(ENV.fluxus) == "table" and ENV.fluxus.request or nil,
		type(ENV.http) == "table" and ENV.http.request or nil,
		type(ENV.http_service) == "table" and ENV.http_service.request or nil,
		type(ENV.Electron) == "table" and ENV.Electron.request or nil,
		type(ENV.Potassium) == "table" and ENV.Potassium.request or nil,
		type(ENV.Velocity) == "table" and ENV.Velocity.request or nil,
		type(ENV.delta) == "table" and ENV.delta.request or nil,
		type(ENV.Codex) == "table" and ENV.Codex.request or nil,
		type(ENV.Hydrogen) == "table" and ENV.Hydrogen.request or nil,
		ENV.request,
		ENV.Request,
		firstExecFunc("http_request", "request", "Request", "httprequest"),
	}
	for _, candidate in ipairs(candidates) do
		if type(candidate) == "function" then
			return candidate
		end
	end
	if HttpService and type(HttpService.RequestAsync) == "function" then
		return function(opts)
			return HttpService:RequestAsync({
				Url = opts.Url or opts.url,
				Method = opts.Method or opts.method or "GET",
				Headers = opts.Headers or opts.headers,
				Body = opts.Body or opts.body,
			})
		end
	end
	return nil
end

local function resolveLoadString()
	local candidates = {
		ENV.loadstring,
		ENV.LoadString,
		ENV.load,
		ENV.Load,
		loadstring,
		load,
	}
	for _, candidate in ipairs(candidates) do
		if type(candidate) == "function" then
			return candidate
		end
	end
	return firstExecFunc("loadstring", "LoadString", "load", "Load", "compile")
end

local httpRequest = resolveHttpRequest()
local readFile = firstExecFunc("readfile", "read_file", "ReadFile")
local isFile = firstExecFunc("isfile", "is_file", "IsFile")
local listFiles = firstExecFunc("listfiles", "list_files", "ListFiles")
local loadStringFn = resolveLoadString()

local function hasHttp()
	if type(game.HttpGet) == "function" then
		return true
	end
	if httpRequest then
		return true
	end
	if HttpService and type(HttpService.GetAsync) == "function" then
		return true
	end
	return false
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

local function trim(value)
	return tostring(value or ""):gsub("^%s*(.-)%s*$", "%1")
end

local function log(level, message)
	local prefix = string.format("[Alleral Loader v%s]", LOADER_VERSION)
	if level == "warn" then
		warn(prefix .. " " .. message)
	else
		print(prefix .. " " .. message)
	end
end

local function detectExecutor()
	for _, id in ipairs({
		"identifyexecutor",
		"getexecutorname",
		"whatexecutor",
		"getexecutor",
	}) do
		local fn = firstExecFunc(id)
		if fn then
			local ok, name = pcall(fn)
			if ok and type(name) == "string" and name ~= "" then
				return name
			end
		end
	end
	if ENV.syn then
		return "Synapse"
	end
	if ENV.KRNL_LOADED then
		return "Krnl"
	end
	return "Unknown"
end

local CAPABILITIES = {
	executor = detectExecutor(),
	http = hasHttp(),
	loadstring = loadStringFn ~= nil,
	readfile = readFile ~= nil,
	isfile = isFile ~= nil,
	listfiles = listFiles ~= nil,
}

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

local function placeIdMatches(profile, placeId)
	for _, id in ipairs(profile.placeIds or {}) do
		if id == placeId then
			return true
		end
	end
	return false
end

local function universeIdMatches(profile, universeId)
	for _, id in ipairs(profile.universeIds or {}) do
		if id == universeId then
			return true
		end
	end
	return false
end

local GAMES = {
	{
		id = "kick_a_lucky_block",
		name = "Kick a Lucky Block",
		version = "6.6",
		needsCore = true,
		placeIds = { 89469502395769 },
		universeIds = { 10004244222 },
		scriptFiles = {
			"games/kick_a_lucky_block.luau",
			"src/kick_a_lucky_block.luau",
			"kick_a_lucky_block.luau",
			"kick a lucky block.luau",
		},
		scriptUrl = "games/kick_a_lucky_block.luau",
		sourceMarker = "Alleral_Rayfield",
		preload = function()
			waitForPath(ReplicatedStorage, { "Shared" }, 20)
			local areas = Workspace:WaitForChild("Areas", 20)
			if not areas or not areas:WaitForChild("KickReady", 10) then
				return false, "KickReady pad not found, are you in the main world?"
			end
			return true
		end,
		validate = function()
			local shared = ReplicatedStorage:FindFirstChild("Shared")
			local network = shared
				and shared:FindFirstChild("Packages")
				and shared.Packages:FindFirstChild("Network")
			local kickReady = Workspace:FindFirstChild("Areas")
				and Workspace.Areas:FindFirstChild("KickReady")
			return network ~= nil and kickReady ~= nil
		end,
	},
	{
		id = "speed_keyboard_escape",
		name = "Speed Keyboard Escape",
		version = "1.2",
		needsCore = true,
		placeIds = { 95082159892680 },
		scriptFiles = {
			"games/speed_keyboard_escape.luau",
			"src/speed_keyboard_escape.luau",
			"speed_keyboard_escape.luau",
		},
		scriptUrl = "games/speed_keyboard_escape.luau",
		preload = function()
			waitForPath(ReplicatedStorage, { "Remotes" }, 20)
			return true
		end,
		validate = function()
			local remotes = ReplicatedStorage:FindFirstChild("Remotes")
			return remotes ~= nil
				and remotes:FindFirstChild("UpdateSpeed") ~= nil
				and ReplicatedStorage:FindFirstChild("ClientState") ~= nil
		end,
	},
	{
		id = "slime_rng",
		name = "Slime RNG",
		version = "1.2",
		needsCore = true,
		placeIds = { 92416421522960 },
		universeIds = { 9792947201 },
		scriptFiles = {
			"games/slime_rng.luau",
			"src/slime_rng.luau",
			"slime_rng.luau",
		},
		scriptUrl = "games/slime_rng.luau",
		preload = function()
			waitForPath(ReplicatedStorage, { "Packages", "DataService" }, 25)
			return true
		end,
		validate = function()
			local packages = ReplicatedStorage:FindFirstChild("Packages")
			return packages ~= nil
				and packages:FindFirstChild("DataService") ~= nil
				and ReplicatedStorage:FindFirstChild("Source") ~= nil
		end,
	},
	{
		id = "build_a_ring_farm",
		name = "Build A Ring Farm",
		version = "1.2",
		needsCore = true,
		placeIds = { 107646426076756 },
		scriptFiles = {
			"games/build_a_ring_farm.luau",
			"src/build_a_ring_farm.luau",
			"build_a_ring_farm.luau",
		},
		scriptUrl = REPO_BASE .. "/games/build_a_ring_farm.luau",
		preload = function()
			waitForPath(ReplicatedStorage, { "Shared" }, 20)
			waitForPath(ReplicatedStorage, { "Remotes", "PlantSeed" }, 15)
			return true
		end,
		validate = function()
			local shared = ReplicatedStorage:FindFirstChild("Shared")
			local remotes = ReplicatedStorage:FindFirstChild("Remotes")
			return shared ~= nil
				and remotes ~= nil
				and remotes:FindFirstChild("PlantSeed") ~= nil
				and remotes:FindFirstChild("Plot") ~= nil
		end,
	},
	{
		id = "survive_a_zombie_arena",
		name = "Survive a Zombie Arena",
		version = "2.1",
		needsCore = true,
		placeIds = { 114204398207377 },
		scriptFiles = {
			"games/survive_a_zombie_arena.luau",
			"src/survive_a_zombie_arena.luau",
			"survive_a_zombie_arena.luau",
		},
		scriptUrl = "games/survive_a_zombie_arena.luau",
		preload = function()
			waitForPath(ReplicatedStorage, { "ZombieRemotes", "ZombieDamage" }, 20)
			waitForPath(ReplicatedStorage, { "WaveRemotes", "SkipVote" }, 15)
			return true
		end,
		validate = function()
			local zombieRemotes = ReplicatedStorage:FindFirstChild("ZombieRemotes")
			local waveRemotes = ReplicatedStorage:FindFirstChild("WaveRemotes")
			return zombieRemotes ~= nil
				and zombieRemotes:FindFirstChild("ZombieDamage") ~= nil
				and waveRemotes ~= nil
				and waveRemotes:FindFirstChild("SkipVote") ~= nil
		end,
	},
}

local function resolveUniverseId()
	local ok, id = pcall(function()
		return game.GameId
	end)
	if ok and type(id) == "number" and id > 0 then
		return id
	end
	return nil
end

local function scoreProfile(profile, placeId, universeId)
	local score = 0
	if placeIdMatches(profile, placeId) then
		score = score + 100
	end
	if universeId and universeIdMatches(profile, universeId) then
		score = score + 50
	end
	if profile.validate and profile.validate() then
		score = score + 25
	end
	return score
end

local function detectGame()
	local placeId = game.PlaceId
	local universeId = resolveUniverseId()
	local bestProfile, bestScore = nil, 0

	for _, profile in ipairs(GAMES) do
		local score = scoreProfile(profile, placeId, universeId)
		if score > bestScore then
			bestScore = score
			bestProfile = profile
		end
	end

	if not bestProfile or bestScore < 25 then
		return nil, string.format("No supported game detected (PlaceId %s).", tostring(placeId))
	end

	if bestScore < 100 and not (bestProfile.validate and bestProfile.validate()) then
		return nil, string.format("%s markers not found in this server.", bestProfile.name)
	end

	return bestProfile
end

local function readLocalFile(path)
	if not readFile or not isFile then
		return nil
	end
	local okExists, exists = pcall(isFile, path)
	if not okExists or not exists then
		return nil
	end
	local okRead, source = pcall(readFile, path)
	if okRead and type(source) == "string" and source ~= "" then
		return source
	end
	return nil
end

local function discoverLocalFiles(fileNames)
	local found = {}
	if not readFile then
		return found
	end
	local roots = {
		"",
		"kick/",
		"kick/kick/",
		"Alleral Hub/",
		"kick/Alleral Hub/",
		"workspace/",
		"scripts/",
	}
	for _, root in ipairs(roots) do
		for _, name in ipairs(fileNames) do
			local path = root .. name
			local source = readLocalFile(path)
			if source then
				table.insert(found, { path = path, source = source })
			end
		end
	end
	if listFiles then
		local searchDirs = { "", "kick", "kick/kick", "workspace", "scripts", "autoexec" }
		for _, dir in ipairs(searchDirs) do
			local ok, entries = pcall(listFiles, dir)
			if ok and type(entries) == "table" then
				for _, entry in ipairs(entries) do
					for _, name in ipairs(fileNames) do
						local baseName = name:match("([^/]+)$") or name
						if entry == baseName or entry == name then
							local path = (dir ~= "" and (dir .. "/") or "") .. name
							local source = readLocalFile(path)
							if not source and entry == baseName then
								path = (dir ~= "" and (dir .. "/") or "") .. entry
								source = readLocalFile(path)
							end
							if source then
								local duplicate = false
								for _, hit in ipairs(found) do
									if hit.path == path then
										duplicate = true
										break
									end
								end
								if not duplicate then
									table.insert(found, { path = path, source = source })
								end
							end
						elseif entry == "core" and name:find("core/", 1, true) then
							local path = (dir ~= "" and (dir .. "/") or "") .. name
							local source = readLocalFile(path)
							if source then
								table.insert(found, { path = path, source = source })
							end
						end
					end
				end
			end
		end
	end
	return found
end

local function logLocalCoreHints()
	if not CAPABILITIES.readfile then
		return
	end
	local hints = {}
	for _, hit in ipairs(discoverLocalFiles(SHARED_CORE_FILES)) do
		table.insert(hints, hit.path)
	end
	if #hints > 0 then
		log("info", "Local core candidates: " .. table.concat(hints, ", "))
		return
	end
	local tried = {}
	for _, root in ipairs({ "", "kick/", "kick/kick/" }) do
		for _, name in ipairs(SHARED_CORE_FILES) do
			table.insert(tried, root .. name)
		end
	end
	log("warn", "No local core on disk. Checked: " .. table.concat(tried, ", "))
	if listFiles then
		local ok, entries = pcall(listFiles, "")
		if ok and type(entries) == "table" and #entries > 0 then
			local names = {}
			for i = 1, math.min(#entries, 12) do
				table.insert(names, tostring(entries[i]))
			end
			log("info", "Workspace root: " .. table.concat(names, ", "))
		end
	end
	log("warn", "Sync the full repo (core/ folder) or use the remote load snippet in README once.")
end

local function telemetrySourceMarker()
	return 'Telemetry.Version = "' .. TELEMETRY_MODULE_VERSION .. '"'
end

local function coreVersionParts(version)
	local major, minor, patch = tostring(version or ""):match("^(%d+)%.(%d+)%.?(%d*)")
	return tonumber(major), tonumber(minor), tonumber(patch) or 0
end

local function coreVersionAtLeast(version, minimum)
	local vMaj, vMin, vPatch = coreVersionParts(version)
	local mMaj, mMin, mPatch = coreVersionParts(minimum)
	if not vMaj or not mMaj then
		return false
	end
	if vMaj ~= mMaj then
		return vMaj > mMaj
	end
	if vMin ~= mMin then
		return vMin > mMin
	end
	return vPatch >= mPatch
end

local function coreVersionCompatible(version)
	return coreVersionAtLeast(version, MIN_CORE_VERSION)
end

local function coreBodyValid(body)
	if type(body) ~= "string" or #body < MIN_SCRIPT_BYTES then
		return false
	end
	if not body:find("loadRayfield", 1, true) then
		return false
	end
	local version = body:match('Core%.VERSION%s*=%s*"([%d%.]+)"')
		or body:match("Core%.VERSION%s*=%s*'([%d%.]+)'")
	return coreVersionCompatible(version)
end

local function coreSourceMarker()
	return coreBodyValid
end

local function markerMatches(body, marker)
	if not marker then
		return true
	end
	if type(marker) == "function" then
		return marker(body) == true
	end
	if type(marker) == "table" then
		for _, entry in ipairs(marker) do
			if body:find(entry, 1, true) then
				return true
			end
		end
		return false
	end
	return body:find(marker, 1, true) ~= nil
end

local function repoRelativePath(urlOrPath)
	local path = tostring(urlOrPath or "")
	if path:find("^https?://") then
		local stripped = path
			:gsub("^https://raw%.githubusercontent%.com/" .. GITHUB_REPO:gsub("%-", "%%-") .. "/[^/]+/", "")
			:gsub("^https://cdn%.jsdelivr%.net/gh/" .. GITHUB_REPO:gsub("%-", "%%-") .. "/@[^/]+/", "")
			:gsub("^https://github%.com/" .. GITHUB_REPO:gsub("%-", "%%-") .. "/raw/[^/]+/", "")
		if stripped ~= path then
			return stripped
		end
	end
	return path:gsub("^/", "")
end

local function mirrorLabel(url)
	if url:find("jsdelivr", 1, true) then
		return "jsdelivr"
	end
	if url:find("github%.com/.+/raw/", 1) then
		return "github-web"
	end
	if url:find("raw%.githubusercontent%.com", 1) then
		return "github-raw"
	end
	return "remote"
end

local function withCacheBust(url, nonce)
	local sep = url:find("?") and "&" or "?"
	return url .. sep .. "t=" .. tostring(nonce or tick())
end

local function executorFetch(url)
	local candidates = { url }
	local plain = url:gsub("%?.*$", "")
	if plain ~= url then
		table.insert(candidates, plain)
	end
	table.insert(candidates, withCacheBust(plain, tick()))

	for _, fetchUrl in ipairs(candidates) do
		if type(ENV.Volt) == "table" and type(ENV.Volt.request) == "function" then
			local ok, res = pcall(ENV.Volt.request, { Url = fetchUrl, Method = "GET" })
			if ok and res then
				local body = res.Body or res.body
				if type(body) == "string" and body ~= "" then
					return body, "volt"
				end
			end
		end
		if type(ENV.request) == "function" then
			local ok, res = pcall(ENV.request, { Url = fetchUrl, Method = "GET" })
			if ok and res then
				local body = res.Body or res.body
				if type(body) == "string" and body ~= "" then
					return body, "request"
				end
			end
		end
		if type(game.HttpGet) == "function" then
			local ok, body = pcall(game.HttpGet, game, fetchUrl, true)
			if ok and type(body) == "string" and body ~= "" then
				return body, "HttpGet"
			end
		end
	end
	return nil, nil
end

local function buildMirrorUrls(relativePath)
	relativePath = repoRelativePath(relativePath)
	local urls = {}
	local seen = {}
	local function add(url)
		if not seen[url] then
			seen[url] = true
			table.insert(urls, url)
		end
	end

	add(REPO_BASE .. "/" .. relativePath)
	add(GITHUB_WEB_RAW .. "/" .. relativePath)

	local commit = ENV._Alleral_ReleaseCommit
	if type(commit) == "string" and commit ~= "" and commit ~= "HEAD" then
		add("https://raw.githubusercontent.com/" .. GITHUB_REPO .. "/" .. commit .. "/" .. relativePath)
		add("https://cdn.jsdelivr.net/gh/" .. GITHUB_REPO .. "@" .. commit .. "/" .. relativePath)
	end

	for _, pinned in ipairs(PINNED_COMMITS) do
		if pinned ~= commit then
			add("https://raw.githubusercontent.com/" .. GITHUB_REPO .. "/" .. pinned .. "/" .. relativePath)
		end
	end

	add(JSDELIVR_BASE .. "/" .. relativePath)
	return urls
end

local function httpFetchBody(url, nonce)
	local function accept(body)
		if type(body) ~= "string" or body == "" then
			return false
		end
		if body:find("404: Not Found", 1, true) then
			return false
		end
		if body:find("<!DOCTYPE html>", 1, true) or body:find("<html", 1, true) then
			return body:find("local ", 1, true)
				or body:find("function ", 1, true)
				or body:find("Core%.VERSION", 1, true)
				or body:find("LOADER_VERSION", 1, true)
		end
		return true
	end

	local function extractBody(response)
		if type(response) == "string" then
			return response
		end
		if type(response) == "table" then
			return response.Body or response.body or response.Data or response.data
		end
		return nil
	end

	local plainBody, plainVia = executorFetch(url)
	if accept(plainBody) then
		return plainBody
	end

	local fetchUrl = withCacheBust(url, nonce)

	if httpRequest then
		for _, spec in ipairs({
			{
				Url = fetchUrl,
				Method = "GET",
				Headers = {
					["Cache-Control"] = "no-cache, no-store, must-revalidate",
					["Pragma"] = "no-cache",
				},
			},
			{
				url = fetchUrl,
				method = "GET",
				headers = {
					["Cache-Control"] = "no-cache, no-store, must-revalidate",
					["Pragma"] = "no-cache",
				},
			},
		}) do
			local reqOk, response = pcall(httpRequest, spec)
			if reqOk then
				local body = extractBody(response)
				local status = type(response) == "table" and (response.StatusCode or response.status or response.Status or 200) or 200
				if accept(body) and (status == 0 or (status >= 200 and status < 300)) then
					return body
				end
			end
		end
	end

	if type(game.HttpGet) == "function" then
		local ok, body = pcall(game.HttpGet, game, fetchUrl, true)
		if ok and accept(body) then
			return body
		end
		ok, body = pcall(game.HttpGet, game, fetchUrl)
		if ok and accept(body) then
			return body
		end
	end

	local ok, body = pcall(function()
		return game:HttpGet(fetchUrl, true)
	end)
	if ok and accept(body) then
		return body
	end

	ok, body = pcall(function()
		return game:HttpGet(fetchUrl)
	end)
	if ok and accept(body) then
		return body
	end

	if HttpService and type(HttpService.GetAsync) == "function" then
		ok, body = pcall(function()
			return HttpService:GetAsync(fetchUrl, true)
		end)
		if ok and accept(body) then
			return body
		end
	end

	return nil
end

local function ensureReleaseManifest(forceRefresh)
	if ENV._Alleral_ReleaseLoaded and not forceRefresh then
		return
	end
	for _, url in ipairs(buildMirrorUrls("config/release.json")) do
		for attempt = 1, 2 do
			local body = httpFetchBody(url, tick() + attempt)
			if body and not body:find("404: Not Found", 1, true) then
				local commit = body:match('"commit"%s*:%s*"([^"]+)"')
				if commit and commit ~= "" and commit ~= "HEAD" then
					ENV._Alleral_ReleaseCommit = commit
				end
				if HttpService then
					local ok, decoded = pcall(function()
						return HttpService:JSONDecode(body)
					end)
					if ok and type(decoded) == "table" and type(decoded.commit) == "string" then
						if decoded.commit ~= "" and decoded.commit ~= "HEAD" then
							ENV._Alleral_ReleaseCommit = decoded.commit
						end
					end
				end
				ENV._Alleral_ReleaseLoaded = true
				return
			end
		end
	end
	if not ENV._Alleral_ReleaseCommit and PINNED_COMMITS[1] then
		ENV._Alleral_ReleaseCommit = PINNED_COMMITS[1]
	end
	ENV._Alleral_ReleaseLoaded = true
end

local function fetchRemoteMirrors(urls, label, marker)
	local lastErr = nil
	local nonces = {
		tick(),
		tick() + 1,
		safeTime(),
		safeTime() + 1,
		math.random(100000, 999999),
		math.random(100000, 999999),
	}

	for _, baseUrl in ipairs(urls) do
		for attempt = 1, math.min(FETCH_RETRIES, #nonces) do
			local body = httpFetchBody(baseUrl, nonces[attempt])
			if body and body ~= "" then
				if markerMatches(body, marker) then
					return body, mirrorLabel(baseUrl)
				end
				lastErr = label .. " mirror returned stale payload (" .. mirrorLabel(baseUrl) .. ")"
			else
				lastErr = label .. " download failed (" .. mirrorLabel(baseUrl) .. ")"
			end
			if attempt < FETCH_RETRIES then
				safeWait(FETCH_BACKOFF * attempt)
			end
		end
	end

	return nil, lastErr or (label .. " download failed")
end

local function resolveLocalMarked(files, marker)
	if not CAPABILITIES.readfile then
		return nil, nil
	end
	for _, file in ipairs(files) do
		local source = readLocalFile(file)
		if source and markerMatches(source, marker) then
			return source, "local:" .. file
		elseif source and marker then
			log("warn", "Local file skipped (version/content mismatch): " .. file)
		end
	end
	for _, hit in ipairs(discoverLocalFiles(files)) do
		if markerMatches(hit.source, marker) then
			return hit.source, "discovered:" .. hit.path
		end
	end
	return nil, nil
end

local function resolveFromFiles(files, label, urlOrPath, marker)
	if CAPABILITIES.readfile then
		local localSource, localLabel = resolveLocalMarked(files, marker)
		if localSource then
			return localSource, localLabel
		end
	end

	local devMode = ENV.Alleral_DevMode == true
	local preferLocal = devMode or ENV.Alleral_PreferLocal == true
	if preferLocal and CAPABILITIES.readfile then
		for _, hit in ipairs(discoverLocalFiles(files)) do
			if markerMatches(hit.source, marker) then
				return hit.source, "discovered:" .. hit.path
			end
		end
	end

	ensureReleaseManifest(false)
	local mirrors = buildMirrorUrls(urlOrPath)
	local source, mirrorLabelName = fetchRemoteMirrors(mirrors, label, marker)
	if source then
		return source, mirrorLabelName
	end

	if CAPABILITIES.readfile then
		local localSource, localLabel = resolveLocalMarked(files, marker)
		if localSource then
			log("info", label .. " loaded from " .. localLabel .. " (remote mirrors stale)")
			return localSource, localLabel
		end
		for _, hit in ipairs(discoverLocalFiles(files)) do
			if markerMatches(hit.source, marker) then
				log("info", label .. " loaded from discovered:" .. hit.path .. " (remote mirrors stale)")
				return hit.source, "discovered:" .. hit.path
			end
		end
	end

	if devMode and CAPABILITIES.readfile then
		for _, hit in ipairs(discoverLocalFiles(files)) do
			return hit.source, "discovered:" .. hit.path
		end
	end

	if label == "core" and CAPABILITIES.readfile then
		for _, hit in ipairs(discoverLocalFiles(files)) do
			if type(hit.source) == "string" and #hit.source >= MIN_SCRIPT_BYTES and hit.source:find("loadRayfield", 1, true) then
				log("info", "Using local core without strict version pin: " .. hit.path)
				return hit.source, "discovered:" .. hit.path
			end
		end
	end

	return nil, label .. " unavailable after mirror retries"
end

local ENV_BRIDGE = [=[
do
	local bridge = shared
	if type(bridge) == "table" and getgenv then
		local g = getgenv()
		if type(g) == "table" then
			if bridge.Alleral_Rayfield
				and bridge.Alleral_Rayfield.InterfaceBuild == "Rayfield"
				and type(bridge.Alleral_Rayfield.CreateWindow) == "function" then
				g.Alleral_Rayfield = bridge.Alleral_Rayfield
				g.Alleral_UI = bridge.Alleral_Rayfield
			end
			if bridge.Alleral_UI and type(bridge.Alleral_UI.CreateWindow) == "function" then
				g.Alleral_UI = bridge.Alleral_UI
				g.Alleral_Rayfield = bridge.Alleral_UI
			end
			if bridge.Alleral_Core then g.Alleral_Core = bridge.Alleral_Core end
			if bridge.Alleral_Analytics then g.Alleral_Analytics = bridge.Alleral_Analytics end
			if bridge.Alleral_Telemetry then g.Alleral_Telemetry = bridge.Alleral_Telemetry end
			if bridge.Alleral_LoaderMeta then g.Alleral_LoaderMeta = bridge.Alleral_LoaderMeta end
			if bridge.Alleral_LoaderCapabilities then g.Alleral_LoaderCapabilities = bridge.Alleral_LoaderCapabilities end
			if bridge.Alleral_ReportError then g.Alleral_ReportError = bridge.Alleral_ReportError end
			if bridge.Alleral_LogEvent then g.Alleral_LogEvent = bridge.Alleral_LogEvent end
			if bridge.Alleral_Boot then g.Alleral_Boot = bridge.Alleral_Boot end
			g.Alleral_State = g.Alleral_State or bridge.Alleral_State or {}
			if type(bridge.Alleral_State) == "table" then
				for key, value in pairs(bridge.Alleral_State) do
					if g.Alleral_State[key] == nil then
						g.Alleral_State[key] = value
					end
				end
			end
			bridge.Alleral_State = g.Alleral_State
		end
	end
end
]=]

local function publishBridge()
	ENV.Alleral_State = ENV.Alleral_State or {}
	pcall(function()
		shared.Alleral_Rayfield = ENV.Alleral_Rayfield
		shared.Alleral_UI = ENV.Alleral_UI
		shared.Alleral_Core = ENV.Alleral_Core
		shared.Alleral_Analytics = ENV.Alleral_Analytics
		shared.Alleral_Telemetry = ENV.Alleral_Telemetry
		shared.Alleral_LoaderMeta = ENV.Alleral_LoaderMeta
		shared.Alleral_LoaderCapabilities = ENV.Alleral_LoaderCapabilities
		shared.Alleral_ReportError = ENV.Alleral_ReportError
		shared.Alleral_LogEvent = ENV.Alleral_LogEvent
		shared.Alleral_State = ENV.Alleral_State
		shared.Alleral_Boot = true
		shared.Alleral_StartupFailed = nil
	end)
end

local function patchGameSource(profile, source)
	return ENV_BRIDGE .. "\n" .. source
end

local function compileAndRun(source, chunkName, runEnv)
	local compiled, compileErr = nil, "loadstring unavailable"
	if loadStringFn then
		compiled, compileErr = loadStringFn(source, chunkName)
	end
	if not compiled and type(load) == "function" and load ~= loadStringFn then
		compiled, compileErr = load(source, chunkName)
	end
	if not compiled then
		return false, "Compile failed: " .. tostring(compileErr)
	end
	if runEnv and setfenv then
		pcall(setfenv, compiled, runEnv)
	end
	local ok, runErr = pcall(compiled)
	if not ok then
		return false, "Runtime error: " .. tostring(runErr)
	end
	return true
end

local function readStartupFailure()
	local fail = ENV.Alleral_StartupFailed
	pcall(function()
		if shared and shared.Alleral_StartupFailed then
			fail = fail or shared.Alleral_StartupFailed
		end
	end)
	if ENV.Alleral_State and ENV.Alleral_State.StartupFailed then
		fail = fail or ENV.Alleral_State.StartupFailed
	end
	ENV.Alleral_StartupFailed = nil
	pcall(function()
		shared.Alleral_StartupFailed = nil
	end)
	if ENV.Alleral_State then
		ENV.Alleral_State.StartupFailed = nil
	end
	return fail
end

local function unloadPrevious()
	local state = ENV.Alleral_State
	if state and type(state.Alleral_Unload) == "function" then
		pcall(state.Alleral_Unload)
	end
	ENV.Alleral_Boot = nil
	ENV.Alleral_LoaderRunning = false
end

local function clearSharedBridge()
	pcall(function()
		if typeof(shared) == "table" then
			shared.Alleral_Rayfield = nil
			shared.Alleral_UI = nil
			shared.Alleral_Core = nil
			shared.Alleral_Analytics = nil
			shared.Alleral_Telemetry = nil
			shared.Alleral_GameHelpers = nil
		end
	end)
end

local function invalidateStaleModules()
	if ENV.Alleral_LoaderVersion == LOADER_VERSION then
		return
	end
	ENV.Alleral_Core = nil
	ENV.Alleral_Rayfield = nil
	ENV.Alleral_UI = nil
	ENV.Alleral_Analytics = nil
	ENV.Alleral_Telemetry = nil
	ENV.Alleral_ReportError = nil
	ENV.Alleral_LogEvent = nil
	ENV.Alleral_GameHelpers = nil
	ENV.Alleral_LoaderVersion = LOADER_VERSION
	log("info", "Cleared cached modules for loader " .. LOADER_VERSION)
end

local function coreVersionOk(core)
	return core
		and type(core.loadRayfield) == "function"
		and coreVersionCompatible(core.VERSION)
		and core.UI_LIBRARY == REQUIRED_UI_LIBRARY
end

local function loaderVersionNewer(remote, localVersion)
	return type(remote) == "string"
		and type(localVersion) == "string"
		and remote ~= localVersion
		and coreVersionAtLeast(remote, localVersion)
end

local function trySelfUpgrade()
	if ENV.Alleral_DevMode == true or ENV._Alleral_UpgradeRan == true then
		return false
	end
	ENV._Alleral_UpgradeRan = true
	if not CAPABILITIES.http or not loadStringFn then
		return false
	end
	local nonce = tick()
	for _, base in ipairs({
		REPO_BASE .. "/loader.luau",
		GITHUB_WEB_RAW .. "/loader.luau",
		JSDELIVR_BASE .. "/loader.luau",
	}) do
		local body = select(1, executorFetch(base))
		if type(body) ~= "string" or #body < 8000 then
			body = httpFetchBody(base, nonce)
		end
		if type(body) == "string" and #body > 8000 and body:find("Alleral Hub", 1, true) then
			local remoteVersion = body:match('LOADER_VERSION%s*=%s*"([%d%.]+)"')
			if loaderVersionNewer(remoteVersion, LOADER_VERSION) then
				print("[Alleral] Upgrading loader " .. LOADER_VERSION .. " -> " .. tostring(remoteVersion))
				ENV.Alleral_LoaderRunning = false
				local writeFile = firstExecFunc("writefile")
				if type(writeFile) == "function" then
					pcall(writeFile, "loader.luau", body)
				end
				local ok, err = compileAndRun(body, "Alleral/loader-upgrade")
				if not ok then
					warn("[Alleral] Self-upgrade failed: " .. tostring(err))
				end
				return ok
			end
		end
	end
	return false
end

local main

local function tryLocalCoreLoad()
	if not CAPABILITIES.readfile then
		return false
	end
	for _, hit in ipairs(discoverLocalFiles(SHARED_CORE_FILES)) do
		if coreBodyValid(hit.source) then
			local ok, err = compileAndRun(hit.source, "Alleral/core-local")
			if ok and coreVersionOk(ENV.Alleral_Core) then
				log("info", "Core loaded from " .. hit.path .. " (v" .. tostring(ENV.Alleral_Core.VERSION) .. ")")
				return true
			end
			ENV.Alleral_Core = nil
			log("warn", "Local core rejected from " .. hit.path .. ": " .. tostring(err or "version mismatch"))
		end
	end
	for _, hit in ipairs(discoverLocalFiles(SHARED_CORE_FILES)) do
		if type(hit.source) == "string" and #hit.source >= MIN_SCRIPT_BYTES and hit.source:find("loadRayfield", 1, true) then
			local ok, err = compileAndRun(hit.source, "Alleral/core-local-relaxed")
			if ok and ENV.Alleral_Core and type(ENV.Alleral_Core.loadRayfield) == "function" then
				log("info", "Core loaded from " .. hit.path .. " (v" .. tostring(ENV.Alleral_Core.VERSION) .. ", relaxed)")
				return true
			end
			ENV.Alleral_Core = nil
			log("warn", "Relaxed local core failed from " .. hit.path .. ": " .. tostring(err))
		end
	end
	return false
end

local function tryEmbeddedCoreLoad()
	if type(EMBEDDED_CORE) ~= "string" or #EMBEDDED_CORE < MIN_SCRIPT_BYTES then
		return false
	end
	if not EMBEDDED_CORE:find("loadRayfield", 1, true) then
		return false
	end
	local ok, err = compileAndRun(EMBEDDED_CORE, "Alleral/core-embedded")
	if ok and ENV.Alleral_Core and type(ENV.Alleral_Core.loadRayfield) == "function" then
		log("info", "Core loaded from embedded bundle (v" .. tostring(ENV.Alleral_Core.VERSION) .. ")")
		return true
	end
	ENV.Alleral_Core = nil
	log("warn", "Embedded core failed: " .. tostring(err))
	return false
end

local function tryDirectCoreLoad()
	if coreVersionOk(ENV.Alleral_Core) then
		return true
	end
	if tryEmbeddedCoreLoad() then
		return true
	end
	if tryLocalCoreLoad() then
		return true
	end
	if not CAPABILITIES.http then
		return tryEmbeddedCoreLoad()
	end

	local priorityCoreUrls = {
		REPO_BASE .. "/" .. SHARED_CORE_PATH,
		JSDELIVR_BASE .. "/" .. SHARED_CORE_PATH,
		GITHUB_WEB_RAW .. "/" .. SHARED_CORE_PATH,
	}
	for _, url in ipairs(priorityCoreUrls) do
		local body, via = executorFetch(url)
		if type(body) == "string" and #body > 0 then
			if coreBodyValid(body) then
				local ok, err = compileAndRun(body, "Alleral/core-volt")
				if ok and coreVersionOk(ENV.Alleral_Core) then
					log("info", "Core loaded via " .. tostring(via or "executor") .. " (" .. mirrorLabel(url) .. ")")
					return true
				end
				ENV.Alleral_Core = nil
				log("warn", "Core from " .. tostring(via) .. " rejected: " .. tostring(err or "version mismatch"))
			else
				log("warn", "Core via " .. tostring(via) .. " invalid (" .. tostring(#body) .. " bytes)")
			end
		else
			log("warn", "Core fetch empty via executor (" .. mirrorLabel(url) .. ")")
		end
	end

	ensureReleaseManifest(false)
	local nonce = tick()
	for _, url in ipairs(buildMirrorUrls(SHARED_CORE_PATH)) do
		local body = httpFetchBody(url, nonce)
		local label = mirrorLabel(url)
		if type(body) == "string" and #body > 0 then
			if coreBodyValid(body) then
				local ok, err = compileAndRun(body, "Alleral/core-direct")
				if ok and coreVersionOk(ENV.Alleral_Core) then
					log("info", "Core loaded via " .. label)
					return true
				end
				ENV.Alleral_Core = nil
				ENV.Alleral_Rayfield = nil
				ENV.Alleral_UI = nil
				log("warn", "Core from " .. label .. " rejected: " .. tostring(err or "version mismatch"))
			else
				log("warn", "Core from " .. label .. " invalid (" .. tostring(#body) .. " bytes)")
			end
		else
			log("warn", "Core download failed from " .. label)
		end
	end
	return tryEmbeddedCoreLoad()
end

local function tryRecoveryLoaderBootstrap()
	if not CAPABILITIES.http then
		return false
	end
	local nonce = tick()
	local loaderUrls = {
		REPO_BASE .. "/loader.luau",
		GITHUB_WEB_RAW .. "/loader.luau",
	}
	for _, url in ipairs(loaderUrls) do
		local body = httpFetchBody(url .. "?recover=" .. nonce, nonce)
		if type(body) == "string" and #body > 8000 and body:find("Alleral Hub", 1, true) then
			log("info", "Bootstrapping latest loader from GitHub...")
			ENV.Alleral_LoaderRunning = false
			local ok, err = compileAndRun(body, "Alleral/loader-recover")
			if ok then
				return true
			end
			log("warn", "Recovery loader failed: " .. tostring(err))
		end
	end
	return false
end

local function runAutoRecovery()
	if ENV._Alleral_AutoRecoveryAttempted then
		return false
	end
	ENV._Alleral_AutoRecoveryAttempted = true
	log("info", "Auto-recovering Alleral modules...")
	ENV.Alleral_LoaderRunning = false
	ENV._Alleral_ReleaseLoaded = nil
	ENV.Alleral_Core = nil
	ENV.Alleral_Rayfield = nil
	ENV.Alleral_UI = nil

	if tryDirectCoreLoad() then
		ENV.Alleral_LoaderRunning = false
		if type(main) == "function" then
			main()
		end
		return true
	end

	if tryRecoveryLoaderBootstrap() then
		return true
	end

	safeWait(1)
	ENV.Alleral_LoaderRunning = false
	if type(main) == "function" then
		main()
	end
	return true
end

local function preloadCore(required)
	local core = ENV.Alleral_Core
	if coreVersionOk(core) then
		return true
	end
	ENV.Alleral_Core = nil
	ENV.Alleral_Rayfield = nil
	ENV.Alleral_UI = nil

	if coreVersionOk(ENV.Alleral_Core) then
		return true
	end

	if tryEmbeddedCoreLoad() then
		return true
	end

	if tryLocalCoreLoad() then
		return true
	end

	if tryDirectCoreLoad() then
		return true
	end

	for attempt = 1, 2 do
		if attempt > 1 then
			log("info", "Retrying core download from alternate mirrors...")
			ENV._Alleral_ReleaseLoaded = nil
			ensureReleaseManifest(true)
			safeWait(FETCH_BACKOFF * 2)
		end

		local source, sourceLabel = resolveFromFiles(
			SHARED_CORE_FILES,
			"core",
			SHARED_CORE_PATH,
			coreSourceMarker()
		)
		if source then
			local ok, err = compileAndRun(source, "Alleral/core")
			if ok and coreVersionOk(ENV.Alleral_Core) then
				log("info", "Core loaded from " .. sourceLabel .. " (v" .. tostring(ENV.Alleral_Core.VERSION) .. ")")
				return true
			end
			ENV.Alleral_Core = nil
			log("warn", "Core rejected from " .. tostring(sourceLabel) .. ": " .. tostring(err or "version mismatch"))
			if required and attempt == 2 then
				return false, err or "Core failed to initialize"
			end
		elseif required then
			log("warn", "Core fetch failed: " .. tostring(sourceLabel))
			if attempt == 1 then
				logLocalCoreHints()
			end
			if attempt == 2 then
				return false, sourceLabel
			end
		end
	end

	if required then
		return false, "Core unavailable"
	end
	log("warn", "Core skipped")
	return false
end

local function preloadAnalytics()
	local source, sourceLabel = resolveFromFiles(SHARED_ANALYTICS_FILES, "analytics", SHARED_ANALYTICS_PATH, "Alleral_Analytics")
	if not source then
		log("warn", "Analytics skipped: " .. tostring(sourceLabel))
		return false
	end
	local ok, err = compileAndRun(source, "Alleral/analytics")
	if not ok then
		log("warn", "Analytics failed: " .. tostring(err))
		return false
	end
	log("info", "Analytics loaded from " .. sourceLabel)
	return ENV.Alleral_Analytics ~= nil
end

local function ownerTelemetryValid(cfg)
	return type(cfg) == "table"
		and cfg.enabled ~= false
		and trim(cfg.relayUrl or "") ~= ""
		and trim(cfg.apiKey or "") ~= ""
		and trim(cfg.apiKey) ~= "aller_CHANGE_ME"
		and not trim(cfg.apiKey):find("paste%-", 1, true)
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

local function buildTelemetryConfigFromEnv(env)
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
		if publicUrl:find("/ingest$") then
			relayUrl = publicUrl
		else
			relayUrl = publicUrl .. "/ingest"
		end
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

local function bootstrapTelemetryFromEnvFiles()
	for _, path in ipairs(OWNER_TELEMETRY_ENV_FILES) do
		local raw = readLocalFile(path)
		if raw then
			local cfg = buildTelemetryConfigFromEnv(parseEnvFile(raw))
			if ownerTelemetryValid(cfg) then
				ENV.Alleral_OwnerTelemetry = cfg
				log("info", "Telemetry config auto-loaded from " .. path)
				return true
			end
		end
	end
	if CAPABILITIES.readfile then
		for _, hit in ipairs(discoverLocalFiles(OWNER_TELEMETRY_ENV_FILES)) do
			local cfg = buildTelemetryConfigFromEnv(parseEnvFile(hit.source))
			if ownerTelemetryValid(cfg) then
				ENV.Alleral_OwnerTelemetry = cfg
				log("info", "Telemetry config auto-loaded from " .. hit.path)
				return true
			end
		end
	end
	return false
end

local function loadOwnerTelemetryTable(raw, label)
	if type(raw) ~= "string" or raw == "" or not loadStringFn then
		return nil
	end
	local compiled = loadStringFn(raw, "Alleral/owner_telemetry")
	if not compiled then
		return nil
	end
	local ok, result = pcall(compiled)
	if ok and ownerTelemetryValid(result) then
		return result, label
	end
	return nil
end

local function loadOwnerTelemetryConfig()
	if ownerTelemetryValid(ENV.Alleral_OwnerTelemetry) then
		return true
	end

	for _, path in ipairs(OWNER_TELEMETRY_FILES) do
		local raw = readLocalFile(path)
		if raw then
			local cfg, label = loadOwnerTelemetryTable(raw, path)
			if cfg then
				ENV.Alleral_OwnerTelemetry = cfg
				log("info", "Telemetry config loaded from " .. label)
				return true
			elseif raw:find("enabled%s*=%s*false") or raw:find('apiKey%s*=%s*""') then
				log("warn", "Skipping disabled/empty telemetry config: " .. path)
			end
		end
	end

	if bootstrapTelemetryFromEnvFiles() then
		return true
	end

	if CAPABILITIES.readfile then
		for _, hit in ipairs(discoverLocalFiles({
			"../Alleral-Private/owner_telemetry.luau",
			"Alleral-Private/owner_telemetry.luau",
			"config/owner_telemetry.luau",
			"owner_telemetry.luau",
		})) do
			local cfg, label = loadOwnerTelemetryTable(hit.source, hit.path)
			if cfg then
				ENV.Alleral_OwnerTelemetry = cfg
				log("info", "Telemetry config loaded from " .. label)
				return true
			end
		end
	end

	ENV.Alleral_OwnerTelemetry = nil
	return false
end

local function preloadHelpers()
	if ENV.Alleral_GameHelpers and ENV.Alleral_GameHelpers.VERSION == "1.0" then
		return true
	end
	local source, sourceLabel = resolveFromFiles(SHARED_HELPERS_FILES, "helpers", SHARED_HELPERS_PATH, "Alleral_GameHelpers")
	if not source then
		log("warn", "Game helpers skipped: " .. tostring(sourceLabel))
		return false
	end
	local ok, err = compileAndRun(source, "Alleral/helpers")
	if ok and ENV.Alleral_GameHelpers then
		log("info", "Game helpers loaded from " .. sourceLabel)
		return true
	end
	log("warn", "Game helpers failed: " .. tostring(err))
	return false
end

local function preloadTelemetry()
	loadOwnerTelemetryConfig()

	local source, sourceLabel = resolveFromFiles(
		SHARED_TELEMETRY_FILES,
		"telemetry",
		SHARED_TELEMETRY_PATH,
		telemetrySourceMarker()
	)
	if not source then
		log("warn", "Telemetry skipped: " .. tostring(sourceLabel))
		return false
	end
	local ok, err = compileAndRun(source, "Alleral/telemetry")
	if not ok then
		log("warn", "Telemetry failed: " .. tostring(err))
		return false
	end
	local telemetry = ENV.Alleral_Telemetry
	if telemetry and telemetry.Version ~= TELEMETRY_MODULE_VERSION then
		log("warn", "Telemetry version mismatch (expected " .. TELEMETRY_MODULE_VERSION .. ")")
	end
	loadOwnerTelemetryConfig()
	if type(ENV.Alleral_OwnerTelemetry) == "table" then
		local ownerCfg = ENV.Alleral_OwnerTelemetry
		if ownerCfg.shareKickWebhook == true then
			local ownerWebhook = ownerCfg.kickWebhookUrl
			if type(ownerWebhook) == "string" and ownerWebhook ~= "" then
				ENV.Alleral_DefaultWebhook = ownerWebhook
			end
		end
	end
	telemetry = ENV.Alleral_Telemetry
	if telemetry and type(telemetry.Configure) == "function" and type(ENV.Alleral_OwnerTelemetry) == "table" then
		telemetry:Configure(ENV.Alleral_OwnerTelemetry)
	end
	if telemetry and type(telemetry.InstallBridge) == "function" then
		pcall(function()
			telemetry:InstallBridge()
		end)
	end
	ENV.Alleral_ReportError = ENV.Alleral_ReportError or (telemetry and telemetry.ReportError and function(scope, err, details)
		telemetry:ReportError(scope, err, details)
	end)
	ENV.Alleral_LogEvent = ENV.Alleral_LogEvent or (telemetry and telemetry.ReportEvent and function(category, message, data)
		telemetry:ReportEvent(category, message, data)
	end)
	if telemetry and telemetry.IsEnabled and telemetry:IsEnabled() then
		if type(telemetry.ReportSessionStart) == "function" then
			pcall(function()
				telemetry:ReportSessionStart({
					loaderVersion = LOADER_VERSION,
					executor = CAPABILITIES.executor,
				})
			end)
		end
		if type(telemetry.HookLifecycle) == "function" then
			pcall(function()
				telemetry:HookLifecycle()
			end)
		end
		if type(telemetry.StartHeartbeat) == "function" then
			pcall(function()
				telemetry:StartHeartbeat()
			end)
		end
		local relayHost = ""
		pcall(function()
			local cfg = telemetry._config or ENV.Alleral_OwnerTelemetry or {}
			relayHost = tostring(cfg.relayUrl or ""):match("^https?://([^/]+)") or ""
		end)
		log("info", "Telemetry on" .. (relayHost ~= "" and (" (" .. relayHost .. ")") or ""))
	else
		log("info", "Telemetry off — run tools/sync_telemetry_config.ps1 or add config/owner_telemetry.luau")
	end
	return telemetry ~= nil
end

local function telemetryReport(phase, extra)
	local telemetry = ENV.Alleral_Telemetry
	if telemetry and type(telemetry.ReportInject) == "function" then
		pcall(function()
			telemetry:ReportInject(phase, extra)
		end)
	end
end

local function runGameScript(profile)
	local source, sourceLabel = resolveFromFiles(profile.scriptFiles, "script", profile.scriptUrl, profile.sourceMarker)
	if not source then
		return false, sourceLabel
	end

	if #source < MIN_SCRIPT_BYTES then
		return false, "Downloaded script looks truncated (" .. tostring(#source) .. " bytes)"
	end

	if profile.sourceMarker and not source:find(profile.sourceMarker, 1, true) then
		log("warn", profile.name .. " download may be outdated (missing " .. profile.sourceMarker .. ")")
	end

	log("info", string.format("Loading %s v%s from %s", profile.name, profile.version or "?", sourceLabel))

	telemetryReport("start", {
		scriptName = profile.id,
		scriptVersion = profile.version,
		gameName = profile.name,
	})

	publishBridge()
	ENV.Alleral_Boot = true
	ENV.Alleral_LoaderCapabilities = CAPABILITIES
	ENV.Alleral_LoaderMeta = {
		version = LOADER_VERSION,
		profile = profile.id,
		scriptVersion = profile.version,
		source = sourceLabel,
		executor = CAPABILITIES.executor,
		capabilities = CAPABILITIES,
		loadedAt = os.time(),
	}

	source = patchGameSource(profile, source)
	local ok, runErr = compileAndRun(source, "Alleral/" .. profile.id, ENV)
	ENV.Alleral_Boot = nil
	pcall(function()
		shared.Alleral_Boot = nil
	end)

	if not ok then
		telemetryReport("failed", {
			scriptName = profile.id,
			scriptVersion = profile.version,
			gameName = profile.name,
			error = tostring(runErr),
		})
		return false, runErr
	end
	local failMsg = readStartupFailure()
	if failMsg then
		telemetryReport("failed", {
			scriptName = profile.id,
			scriptVersion = profile.version,
			gameName = profile.name,
			error = tostring(failMsg),
		})
		return false, tostring(failMsg)
	end
	telemetryReport("loaded", {
		scriptName = profile.id,
		scriptVersion = profile.version,
		gameName = profile.name,
	})
	local telemetry = ENV.Alleral_Telemetry
	if telemetry and type(telemetry.StartHeartbeat) == "function" then
		pcall(function()
			telemetry:StartHeartbeat()
		end)
	end
	return true
end

local function preflight()
	if not CAPABILITIES.loadstring then
		return false, "This executor needs loadstring (or load) to run Alleral."
	end
	if not CAPABILITIES.http and not CAPABILITIES.readfile then
		return false, "This executor needs HTTP or readfile to download Alleral modules."
	end
	return true
end

local function applyCoreCapabilities()
	local core = ENV.Alleral_Core
	if core and type(core.refreshLoaderCapabilities) == "function" then
		local caps = core.refreshLoaderCapabilities()
		if type(caps) == "table" then
			CAPABILITIES.executor = caps.executor or CAPABILITIES.executor
			CAPABILITIES.http = caps.http == true or hasHttp()
			CAPABILITIES.readfile = caps.readfile == true or readFile ~= nil
			CAPABILITIES.isfile = type(firstExecFunc("isfile", "is_file", "IsFile")) ~= nil
			CAPABILITIES.listfiles = type(firstExecFunc("listfiles", "list_files", "ListFiles")) ~= nil
			CAPABILITIES.solara = caps.solara == true
		end
	end
end

local function resolveScriptGate(profile)
	local core = ENV.Alleral_Core
	if not core or type(core.fetchScriptManifest) ~= "function" then
		return { allowed = true, status = { label = "Working", icon = "✅", message = "" } }
	end
	ENV.Alleral_ActiveScriptId = profile.id
	ENV.Alleral_ScriptManifestUrl = ENV.Alleral_ScriptManifestUrl or SCRIPT_MANIFEST_URL
	core.fetchScriptManifest(false)
	local evaluation = core.evaluateScriptStatus(profile.id, profile.version)
	local status = evaluation.status
	if not evaluation.allowed then
		local message = string.format(
			"%s is %s. %s Set getgenv().Alleral_ForceLoad = true to override.",
			profile.name,
			status.label,
			status.message ~= "" and status.message or "Script is temporarily unavailable."
		)
		return evaluation, message
	end
	if evaluation.warn then
		notify("Alleral", string.format(
			"%s — %s%s",
			profile.name,
			status.label,
			status.message ~= "" and (": " .. status.message) or ""
		), 7)
	end
	return evaluation
end

main = function()
	log("info", "Alleral loader " .. LOADER_VERSION)
	if ENV.Alleral_LoaderRunning then
		log("warn", "Already running, call getgenv().Alleral_Reload() after unload")
		return
	end
	ENV.Alleral_LoaderRunning = true

	local ready, preflightErr = preflight()
	if not ready then
		notify("Alleral", preflightErr, 8)
		log("warn", preflightErr)
		ENV.Alleral_LoaderRunning = false
		return
	end

	invalidateStaleModules()
	clearSharedBridge()
	ensureReleaseManifest(false)
	loadOwnerTelemetryConfig()
	ENV.Alleral_StartupFailed = nil
	ENV.Alleral_Rayfield = nil
	ENV.Alleral_UI = nil
	ENV.Alleral_Core = nil
	unloadPrevious()

	local profile, detectErr = detectGame()
	if not profile then
		notify("Alleral", tostring(detectErr), 8)
		log("warn", tostring(detectErr))
		ENV.Alleral_LoaderRunning = false
		return
	end

	log("info", string.format(
		"Detected %s | executor=%s | http=%s | local=%s",
		profile.name,
		CAPABILITIES.executor,
		tostring(CAPABILITIES.http),
		tostring(CAPABILITIES.readfile)
	))

	if profile.preload then
		local preloadReady, preloadErr = profile.preload()
		if not preloadReady then
			notify("Alleral", tostring(preloadErr), 8)
			log("warn", "Preload failed: " .. tostring(preloadErr))
			ENV.Alleral_LoaderRunning = false
			return
		end
	end

	local coreOk, coreErr = preloadCore(true)
	if not coreOk then
		if runAutoRecovery() then
			return
		end
		notify("Alleral", "Alleral could not start. Please rejoin and try again.", 8)
		log("warn", "Core required but unavailable: " .. tostring(coreErr))
		telemetryReport("failed", {
			scriptName = profile.id,
			scriptVersion = profile.version,
			gameName = profile.name,
			error = "Core failed: " .. tostring(coreErr),
		})
		ENV.Alleral_LoaderRunning = false
		return
	end

	preloadAnalytics()
	preloadHelpers()
	applyCoreCapabilities()
	preloadTelemetry()

	if ENV.Alleral_Core and type(ENV.Alleral_Core.fetchWeaoExploits) == "function" then
		task.spawn(function()
			local exploits, source = ENV.Alleral_Core.fetchWeaoExploits(false)
			if exploits then
				local profile = ENV.Alleral_Core.executorProfile and ENV.Alleral_Core.executorProfile()
				local weao = profile and profile.weao
				if weao then
					log("info", string.format(
						"WEAO: %s — %s (via %s)",
						tostring(weao.title),
						ENV.Alleral_Core.weaoStatusLabel and ENV.Alleral_Core.weaoStatusLabel(weao) or "",
						tostring(source or "api")
					))
				else
					log("info", "WEAO exploit list loaded (" .. tostring(source or "api") .. ")")
				end
			end
		end)
	end

	local gateEval, gateErr = resolveScriptGate(profile)
	if gateEval and gateEval.allowed == false then
		local message = gateErr or "Script blocked by status manifest."
		notify("Alleral", message, 10)
		log("warn", tostring(message))
		telemetryReport("failed", {
			scriptName = profile.id,
			scriptVersion = profile.version,
			gameName = profile.name,
			error = message,
		})
		ENV.Alleral_LoaderRunning = false
		return
	end

	if ENV.Alleral_Core and type(ENV.Alleral_Core.loadRayfield) == "function" then
		local uiLibrary, uiErr = ENV.Alleral_Core.loadRayfield()
		if uiLibrary and uiLibrary.InterfaceBuild == REQUIRED_UI_LIBRARY then
			ENV.Alleral_Rayfield = uiLibrary
			ENV.Alleral_UI = uiLibrary
			log("info", "Rayfield preloaded (" .. tostring(uiLibrary.InterfaceBuild) .. ")")
		else
			ENV.Alleral_Rayfield = nil
			ENV.Alleral_UI = nil
			local detail = uiErr
				or ("UI library mismatch: " .. tostring(uiLibrary and uiLibrary.InterfaceBuild or "nil"))
			log("warn", "Rayfield preload skipped: " .. detail .. " (game script will retry)")
		end
	end

	local ok, runErr = runGameScript(profile)
	ENV.Alleral_LoaderRunning = false

	if not ok then
		notify("Alleral", tostring(runErr), 8)
		log("warn", tostring(runErr))
		telemetryReport("failed", {
			scriptName = profile.id,
			scriptVersion = profile.version,
			gameName = profile.name,
			error = tostring(runErr),
		})
		return
	end

	notify("Alleral", profile.name .. " loaded.", 4)
	log("info", "Ready")
	ENV._Alleral_AutoRecoveryAttempted = nil
end

ENV.Alleral_Reload = function()
	local telemetry = ENV.Alleral_Telemetry
	if telemetry and type(telemetry.ReportSessionEnd) == "function" then
		pcall(function()
			telemetry:ReportSessionEnd("reload")
			telemetry._sessionEnded = false
			telemetry._sessionId = nil
			telemetry._heartbeatRunning = false
		end)
	end
	unloadPrevious()
	if typeof(task) == "table" and type(task.defer) == "function" then
		task.defer(main)
	else
		main()
	end
end

ENV.Alleral_LoaderInfo = function()
	return {
		version = LOADER_VERSION,
		capabilities = CAPABILITIES,
		games = GAMES,
	}
end

print("[Alleral] v" .. LOADER_VERSION .. " | PlaceId " .. tostring(game.PlaceId) .. " | executor=" .. tostring(CAPABILITIES.executor))

if trySelfUpgrade() then
	return
end

local okBoot, bootErr = pcall(main)
if not okBoot then
	local message = tostring(bootErr)
	warn("[Alleral Loader] " .. message)
	notify("Alleral", message, 10)
	ENV.Alleral_LoaderRunning = false
end
