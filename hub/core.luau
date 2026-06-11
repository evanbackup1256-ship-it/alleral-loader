local Core = {}
Core.VERSION = "2.7.3"
Core.UI_LIBRARY = "Alleral"
Core.ALLERAL_UI_VERSION = "2.0.0-alleral-v2"
Core.WINDUI_VERSION = Core.ALLERAL_UI_VERSION

local HttpService = game:GetService("HttpService")
local StarterGui = game:GetService("StarterGui")
local WINDUI_MIRROR_URLS = {
	"https://raw.githubusercontent.com/evanbackup1256-ship-it/kick/main/ui/windui/",
	"https://github.com/evanbackup1256-ship-it/kick/raw/main/ui/windui/",
	"https://github.com/Footagesus/WindUI/releases/download/1.6.64-fix/",
	"https://raw.githubusercontent.com/Footagesus/WindUI/1.6.64-fix/dist/",
}
local WINDUI_LOCAL_ROOTS = {
	"ui/windui/",
	"kick/ui/windui/",
	"kick/kick/ui/windui/",
	"windui/",
}
local WINDUI_FILE = "main.lua"
local WINDUI_PATCH_FILE = "arrrel.luau"
local WINDUI_PATCH_FALLBACK = "aller.luau"
local WINDUI_MIN_BYTES = 50000
local ALLERAL_ACCENT = Color3.fromHex("#53fc18")
local ALLERAL_ACCENT_ALT = Color3.fromHex("#30ff6a")

-- Keep in sync with loader.luau GAMES (place/universe ids for runtime resolution).
Core.GAME_REGISTRY = {
	kick_a_lucky_block = {
		name = "Kick a Lucky Block",
		placeIds = { 89469502395769 },
		universeIds = { 10004244222 },
	},
	speed_keyboard_escape = {
		name = "Speed Keyboard Escape",
		placeIds = { 95082159892680 },
	},
	slime_rng = {
		name = "Slime RNG",
		placeIds = { 92416421522960 },
		universeIds = { 9792947201 },
	},
	build_a_ring_farm = {
		name = "Build A Ring Farm",
		placeIds = { 107646426076756 },
	},
	survive_a_zombie_arena = {
		name = "Survive a Zombie Arena",
		placeIds = { 114204398207377 },
	},
}

function Core.resolveActiveGameId(options)
	options = type(options) == "table" and options or {}
	local explicit = options.scriptId or options.gameId or options.id
	if explicit and tostring(explicit) ~= "" then
		return tostring(explicit)
	end
	if ENV.Alleral_ActiveScriptId and tostring(ENV.Alleral_ActiveScriptId) ~= "" then
		return tostring(ENV.Alleral_ActiveScriptId)
	end
	local placeId = game.PlaceId
	local universeId = game.GameId
	for gameId, meta in pairs(Core.GAME_REGISTRY) do
		if type(meta.placeIds) == "table" then
			for _, pid in ipairs(meta.placeIds) do
				if pid == placeId then
					return gameId
				end
			end
		end
		if type(meta.universeIds) == "table" then
			for _, uid in ipairs(meta.universeIds) do
				if uid == universeId then
					return gameId
				end
			end
		end
	end
	return nil
end

local function genv()
	local ok, env = pcall(function()
		return getgenv and getgenv() or getfenv()
	end)
	return ok and env or {}
end

local ENV = genv()
local LOG_TAG = "[Alleral]"

function Core.say(msg)
	print(LOG_TAG .. " " .. tostring(msg))
end

function Core.logWarn(msg)
	warn(LOG_TAG .. " " .. tostring(msg))
end

function Core.assertLoader()
	if not getgenv().Alleral_Boot then
		Core.logWarn("run the loader before this script")
		return false
	end
	getgenv().Alleral_Boot = nil
	return true
end

function Core.boot(state)
	state = state or ENV.Alleral_State or getgenv().Alleral_State
	if type(state) ~= "table" then
		return nil, nil, "state missing"
	end
	if type(state.Alleral_Unload) == "function" then
		pcall(state.Alleral_Unload)
	end
	if type(Core.prepareGame) ~= "function" then
		return nil, nil, "core missing"
	end
	return Core.prepareGame(state)
end

function Core.safeCall(scope, fn, ...)
	if type(fn) ~= "function" then
		return nil
	end
	local packed = table.pack(pcall(fn, ...))
	if packed[1] then
		return table.unpack(packed, 2, packed.n)
	end
	local err = packed[2]
	if Core.pushErrorLog then
		Core.pushErrorLog(tostring(scope or "Core"), err)
	else
		ENV.Alleral_ErrorLog = ENV.Alleral_ErrorLog or {}
		table.insert(ENV.Alleral_ErrorLog, 1, {
			at = os.date("%H:%M:%S"),
			scope = tostring(scope or "Core"),
			message = tostring(err or "?"),
		})
	end
	Core.reportError(tostring(scope or "Core"), err)
	Core.logWarn(tostring(scope or "Core") .. ": " .. tostring(err))
	return nil
end

function Core.guard(scope, fn)
	scope = tostring(scope or "Core")
	return function(...)
		return Core.safeCall(scope, fn, ...)
	end
end

function Core.coerceSettingsTable(decoded, keys, defaults)
	if type(decoded) ~= "table" then
		return nil
	end
	local output = {}
	for _, key in ipairs(keys or {}) do
		if decoded[key] ~= nil then
			output[key] = decoded[key]
		elseif type(defaults) == "table" and defaults[key] ~= nil then
			output[key] = Core.copyValue(defaults[key])
		end
	end
	return output
end

function Core.restoreSettingsFromBackup(filename, state, keys, defaults)
	local listFiles = Core.execFunction("listfiles")
	local readFile = Core.execFunction("readfile")
	local isFile = Core.execFunction("isfile")
	if type(listFiles) ~= "function" or type(readFile) ~= "function" or type(isFile) ~= "function" then
		return false
	end
	local base = tostring(filename or "settings.json"):gsub("%.json$", ""):gsub("[^%w%-_]", "_")
	local matches = {}
	for _, filePath in ipairs(listFiles("Alleral_Configs/backups")) do
		local name = tostring(filePath):match("([^/\\]+)$")
		if name and name:find("^" .. base .. "_", 1, true) then
			table.insert(matches, tostring(filePath))
		end
	end
	table.sort(matches, function(a, b)
		return a > b
	end)
	for _, backupPath in ipairs(matches) do
		if isFile(backupPath) then
			local raw = readFile(backupPath)
			local ok, decoded = pcall(function()
				return HttpService:JSONDecode(raw)
			end)
			local coerced = Core.coerceSettingsTable(decoded, keys, defaults)
			if coerced then
				for _, key in ipairs(keys) do
					if coerced[key] ~= nil then
						state[key] = Core.copyValue(coerced[key])
					end
				end
				return true
			end
		end
	end
	return false
end

function Core.installResilience()
	if ENV._Alleral_CoreResilience then
		return
	end
	ENV._Alleral_CoreResilience = true
	local guarded = {
		"prepareGame",
		"loadUi",
		"preloadUi",
		"buildUiWindow",
		"buildUiTab",
		"buildUiGroup",
		"saveSettings",
		"loadSettings",
		"initSettings",
		"makeSupervisor",
		"fetchScriptManifest",
		"fetchWeaoExploits",
		"fetchWeaoExecutorStatus",
		"buildHubActionsGroup",
		"buildThemeStudioGroup",
		"buildCustomizationStudioGroup",
		"buildSystemPanelGroup",
		"buildAdvancedHubGroup",
		"buildStandardSettingsExtras",
		"resolveActiveGameId",
		"buildUiPreferencesGroup",
		"buildConfigProfileGroup",
		"buildCloudConfigStudio",
		"buildCloudConfigTab",
		"repairUiWindow",
		"finalizeGameUi",
		"gameUiSettings",
		"buildScriptStatusGroupbox",
		"postWebhook",
		"writeFile",
	}
	for _, name in ipairs(guarded) do
		local fn = Core[name]
		if type(fn) == "function" and Core["_raw_" .. name] == nil then
			Core["_raw_" .. name] = fn
			Core[name] = Core.guard(name, fn)
		end
	end
end

function Core.getWindUi()
	local ui = ENV.Alleral_UI
	if type(ui) ~= "table" then
		return nil
	end
	return ui.WindUI or ui.Library
end

function Core.notifyWindUi(payload)
	local windUi = Core.getWindUi()
	if not windUi or type(windUi.Notify) ~= "function" then
		return false
	end
	local ok = pcall(function()
		windUi:Notify(payload)
	end)
	return ok == true
end

function Core.queueNotification(payload)
	if type(payload) ~= "table" then
		return
	end
	ENV._AlleralPendingNotifies = ENV._AlleralPendingNotifies or {}
	table.insert(ENV._AlleralPendingNotifies, payload)
end

function Core.flushPendingNotifications()
	local queue = ENV._AlleralPendingNotifies
	if type(queue) ~= "table" or #queue == 0 then
		return
	end
	ENV._AlleralPendingNotifies = {}
	for _, payload in ipairs(queue) do
		Core.notifyWindUi(payload)
	end
end

function Core.notifyBootReady(settings)
	settings = type(settings) == "table" and settings or {}
	local profile = Core.executorProfile()
	local scriptVer = ENV.Alleral_ActiveScriptVersion
		or (type(ENV.Alleral_LoaderMeta) == "table" and ENV.Alleral_LoaderMeta.scriptVersion)
	local loaderVer = ENV.Alleral_LoaderVersion
		or (type(ENV.Alleral_LoaderMeta) == "table" and ENV.Alleral_LoaderMeta.version)
	local lines = {}
	if settings.Subtitle and settings.Subtitle ~= "" then
		table.insert(lines, tostring(settings.Subtitle))
	end
	if scriptVer then
		table.insert(lines, "Script v" .. tostring(scriptVer))
	elseif loaderVer then
		table.insert(lines, "Loader v" .. tostring(loaderVer))
	end
	table.insert(lines, profile.displayName .. " ready · tabs on the left")
	Core.notify(settings.Name or "Alleral", table.concat(lines, "\n"), 5, "success")
end

function Core.notify(title, text, duration, notifyType)
	title = title or "Alleral"
	text = text or ""
	duration = duration or 4
	notifyType = notifyType or "info"

	local payload = {
		Title = title,
		Content = text,
		Duration = duration,
		Type = notifyType,
	}

	if Core.notifyWindUi(payload) then
		return
	end

	if Core.getWindUi() then
		Core.queueNotification(payload)
		return
	end

	pcall(function()
		StarterGui:SetCore("SendNotification", {
			Title = title,
			Text = text,
			Duration = duration,
		})
	end)
end

function Core.requestFunction()
	local fn = Core.firstExecFunc("request", "http_request", "Request", "httprequest")
	if fn then
		return fn
	end

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
	}
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

function Core.weaoClient()
	local client = ENV.Alleral_Weao
	if client and type(client.fetchExploits) == "function" then
		return client
	end
	return nil
end

function Core.weaoRequestHeaders()
	local client = Core.weaoClient()
	if client and client.requestHeaders then
		return client.requestHeaders()
	end
	return {
		["User-Agent"] = "WEAO-3PService",
		["Accept"] = "application/json",
		["Cache-Control"] = "no-cache",
	}
end

function Core.fetchWeaoExploits(forceRefresh)
	local Weao = Core.weaoClient()
	if not Weao then
		return nil, "WEAO module missing"
	end
	local profile = Core.detectExecutor()
	return Weao.fetchExploits({
		forceRefresh = forceRefresh == true,
		httpFetch = function(url)
			return Core.httpGet(url)
		end,
		requestFn = Core.requestFunction(),
		config = ENV.Alleral_WeaoConfig or ENV._Alleral_WeaoConfigRemote,
		executorSlug = profile and profile.slug,
	})
end

function Core.formatWeaoEntry(entry)
	local Weao = Core.weaoClient()
	if Weao and Weao.formatEntry then
		return Weao.formatEntry(entry)
	end
	return nil
end

function Core.matchWeaoExploit(profile, exploits)
	local Weao = Core.weaoClient()
	if Weao and Weao.matchExploit then
		return Weao.matchExploit(profile, exploits)
	end
	return nil
end

function Core.fetchWeaoExecutorStatus(profile)
	profile = profile or Core.executorProfile()
	local Weao = Core.weaoClient()
	if not Weao then
		return nil, "WEAO module missing"
	end
	local weao, err = Weao.executorStatus(profile, {
		forceRefresh = false,
		httpFetch = function(url)
			return Core.httpGet(url)
		end,
		requestFn = Core.requestFunction(),
		config = ENV.Alleral_WeaoConfig or ENV._Alleral_WeaoConfigRemote,
	})
	if weao then
		return weao, nil
	end
	return nil, err
end

function Core.weaoStatusLabel(weao)
	local Weao = Core.weaoClient()
	if Weao and Weao.statusLabel then
		return Weao.statusLabel(weao)
	end
	if type(weao) ~= "table" then
		return "Unknown (see docs.weao.xyz)"
	end
	return "Unknown"
end

function Core.normalizeExecutorKey(text)
	local key = tostring(text or ""):lower()
	key = key:gsub("synapse%s*z", "synapsez")
	key = key:gsub("awp%.?gg?", "volt")
	key = key:gsub("bunni%.?fun", "bunni")
	key = key:gsub("vega%s*x", "vegax")
	key = key:gsub("[^a-z0-9]", "")
	return key
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
	Core.say("Executor: " .. msg)
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
	table.insert(urls, "https://raw.githubusercontent.com/evanbackup1256-ship-it/kick/main/cfg/scripts_manifest.json")
	table.insert(urls, "https://github.com/evanbackup1256-ship-it/kick/raw/main/cfg/scripts_manifest.json")
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
		"cfg/scripts_manifest.json",
		"config/scripts_manifest.json",
		"kick/cfg/scripts_manifest.json",
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
			local fetchUrl = url .. (url:find("?") and "&" or "?") .. "t=" .. tostring(math.random(10000, 99999))
			local ok, response = pcall(function()
				return requestFn({
					Url = fetchUrl,
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
			local decoded, jsonErr = Core.httpGetJson(fetchUrl)
			if type(decoded) == "table" and type(decoded.scripts) == "table" then
				ENV.Alleral_ScriptManifestCache = { fetchedAt = tick(), data = decoded, source = url }
				ENV.Alleral_ScriptManifest = decoded
				return decoded, nil
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
			message = "No remote status; local build.",
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
	addRow("Access", "Public · no key required")
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

	if not evaluation.allowed then
		groupbox:CreateToggle({
			Name = "Force load anyway",
			Value = ENV.Alleral_ForceLoad == true,
			Tooltip = "Skip maintenance gate this session.",
			Callback = function(value)
				ENV.Alleral_ForceLoad = value == true
				getgenv().Alleral_ForceLoad = value == true
				Core.notify("Alleral", value and "force load on — reload to use it" or "force load off", 4)
			end,
		}, "ForceLoadToggle")
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
			end
			local refreshedWeao = Core.fetchWeaoExecutorStatus()
			if refreshedWeao and labels.WEAO and labels.WEAO.Set then
				labels.WEAO:Set({ Name = "WEAO: " .. Core.weaoStatusLabel(refreshedWeao) })
			end
			Core.notify("Alleral", "status: " .. nextStatus.label, 3)
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

function Core.buildHubActionsGroup(tab, column)
	local groupbox = tab:CreateGroupbox({
		Name = "Hub controls",
		Column = column or 2,
		Icon = 6031075938,
	}, "HubActions")
	local group = Core.wrapUiGroup(groupbox)

	group:CreateButton("Reload script", function()
		local reload = getgenv().Alleral_Reload
		if type(reload) == "function" then
			Core.notify("Alleral", "reloading...", 3)
			task.defer(reload)
		else
			Core.notify("Alleral", "can't reload here — run the loadstring again", 5)
		end
	end, "Runs getgenv().Alleral_Reload().")

	group:CreateButton("Check for update", function()
		local check = getgenv().Alleral_CheckUpdate
		if type(check) == "function" then
			check()
		else
			Core.notify("Alleral", "Update check unavailable.", 4)
		end
	end, "Pulls the latest loader/core from GitHub.")

	group:CreateButton("Stop automation", function()
		stateHubStop()
	end, "Stops loops without closing the UI.")

	group:CreateButton("Purge cache", function()
		local purge = getgenv().Alleral_PurgeCache
		if type(purge) == "function" then
			purge()
			Core.notify("Alleral", "cache cleared", 4)
		else
			Core.notify("Alleral", "Purge unavailable.", 4)
		end
	end, "Clears cached hub files and reloads fresh.")

	group:CreateButton("Sync WEAO config", function()
		Core.syncWeaoConfigNow()
	end, "Pulls the latest WEAO API endpoints without reloading.")

	group:CreateButton("Copy JobId", function()
		Core.copyJobId()
	end, "Copies this server's JobId to clipboard.")

	group:CreateButton("Copy join link", function()
		Core.copyPlaceJoinLink()
	end, "Copies a roblox:// link for this server.")

	group:CreateButton("Copy web join link", function()
		Core.copyWebJoinLink()
	end, "Copies the https:// join link for this server.")

	group:CreateButton("Rejoin server", function()
		Core.rejoinServer()
	end, "Teleports you back into this same server instance.")

	Core.buildJoinServerControls(group, { dividerFirst = true })

	return group
end

local ERROR_LOG_MAX = 40
ENV.Alleral_ErrorLog = ENV.Alleral_ErrorLog or {}

function Core.pushErrorLog(scope, err, details)
	local entry = {
		at = os.date("%H:%M:%S"),
		scope = tostring(scope or "Runtime"),
		message = tostring(err or "?"),
		details = details and tostring(details) or nil,
	}
	local log = ENV.Alleral_ErrorLog
	table.insert(log, 1, entry)
	while #log > ERROR_LOG_MAX do
		table.remove(log)
	end
	if Core._errorLogStatus then
		pcall(function()
			Core._errorLogStatus:Update("Latest", entry.scope .. ": " .. entry.message:sub(1, 80))
			Core._errorLogStatus:Update("Count", tostring(#log))
		end)
	end
end

function Core.installErrorLogHook()
	if ENV._Alleral_ErrorLogHooked then
		return
	end
	ENV._Alleral_ErrorLogHooked = true
	local previous = ENV.Alleral_ReportError
	ENV.Alleral_ReportError = function(scope, err, details)
		Core.pushErrorLog(scope, err, details)
		if type(previous) == "function" then
			pcall(previous, scope, err, details)
		end
	end
	getgenv().Alleral_ReportError = ENV.Alleral_ReportError
end

function Core.getErrorLogText(limit)
	limit = limit or 20
	local lines = {}
	for index, entry in ipairs(ENV.Alleral_ErrorLog or {}) do
		if index > limit then
			break
		end
		table.insert(lines, string.format("[%s] %s: %s", entry.at, entry.scope, entry.message))
	end
	return #lines > 0 and table.concat(lines, "\n") or "No errors logged this session."
end

function Core.registerUiWindow(window)
	if type(window) == "table" and window._rawWindow then
		ENV.Alleral_UiWindow = window
		getgenv().Alleral_UiWindow = window
	end
	return window
end

function Core.repairUiWindow(window)
	window = window or ENV.Alleral_UiWindow
	if type(window) ~= "table" or not window._rawWindow then
		return false
	end
	local lib = window._library or Core.getWindUi()
	if not lib or type(lib.RepairWindow) ~= "function" then
		return false
	end
	local ok = pcall(function()
		lib:RepairWindow(window._rawWindow)
	end)
	return ok == true
end

Core._UiStateBindings = Core._UiStateBindings or {}

function Core.clearUiStateBindings()
	Core._UiStateBindings = {}
end

function Core.bindUiState(stateKey, widget, kind, rawHandle)
	if type(stateKey) ~= "string" or stateKey == "" then
		return widget
	end
	Core._UiStateBindings[stateKey] = {
		widget = widget,
		kind = kind or "toggle",
		raw = rawHandle,
	}
	return widget
end

function Core.sliderIncrement(minValue, maxValue, explicit)
	if explicit ~= nil then
		return explicit
	end
	minValue = tonumber(minValue) or 0
	maxValue = tonumber(maxValue) or 100
	local range = maxValue - minValue
	if range <= 0 then
		return 1
	end
	if range <= 1 then
		return 0.01
	end
	if range <= 5 then
		return 0.05
	end
	if range <= 10 then
		return 0.1
	end
	if range <= 50 then
		return 0.5
	end
	if range <= 200 then
		return 1
	end
	return math.max(1, math.floor(range / 80))
end

function Core.syncUiState(state, options)
	if type(state) ~= "table" then
		return 0
	end
	options = type(options) == "table" and options or {}
	local synced = 0
	for key, entry in pairs(Core._UiStateBindings or {}) do
		local value = state[key]
		if value ~= nil then
			local raw = entry.raw
			if not raw and type(entry.widget) == "table" then
				raw = entry.widget._raw
			end
			if entry.kind == "toggle" and raw and type(raw.Set) == "function" then
				pcall(function()
					local prev = raw.Callback
					raw.Callback = function() end
					raw:Set(value == true, nil, false)
					raw.Callback = prev
				end)
				synced += 1
			elseif entry.kind == "slider" and raw and type(raw.Set) == "function" then
				pcall(function()
					local prev = raw.Callback
					raw.Callback = function() end
					raw:Set(tonumber(value) or 0)
					raw.Callback = prev
				end)
				synced += 1
			elseif entry.kind == "dropdown" and raw then
				pcall(function()
					if raw.Select then
						raw:Select(value)
					elseif raw.Set then
						raw:Set(value)
					elseif entry.widget and entry.widget.Set then
						entry.widget:Set({ CurrentOption = value })
					end
				end)
				synced += 1
			elseif entry.widget and type(entry.widget.Set) == "function" then
				pcall(function()
					if entry.kind == "toggle" then
						entry.widget:Set({ CurrentValue = value == true })
					elseif entry.kind == "slider" then
						entry.widget:Set({ CurrentValue = tonumber(value) or 0 })
					else
						entry.widget:Set({ CurrentOption = value })
					end
				end)
				synced += 1
			end
		end
	end
	if options.notify == true and synced > 0 then
		Core.notify("UI", "Synced " .. tostring(synced) .. " controls.", 2, "info")
	end
	return synced
end

function Core.releaseUiWindow()
	local ui = ENV.Alleral_UI
	local wind = ui and (ui.WindUI or ui.Library)
	if type(wind) == "table" and type(wind.ReleaseWindow) == "function" then
		pcall(function()
			wind:ReleaseWindow(wind.Window)
		end)
	end
	ENV.Alleral_UiWindow = nil
	getgenv().Alleral_UiWindow = nil
end

function Core.toggleUiVisibility()
	local window = ENV.Alleral_UiWindow
	if not window or not window._rawWindow then
		return false
	end
	local raw = window._rawWindow
	if type(raw.Toggle) == "function" then
		pcall(raw.Toggle, raw)
		return true
	end
	return false
end

function Core.setGlobalMusicMuted(muted)
	muted = muted == true
	local SoundService = game:GetService("SoundService")
	ENV._AlleralMutedSounds = ENV._AlleralMutedSounds or {}

	local function muteSound(sound)
		if not sound or not sound:IsA("Sound") then
			return
		end
		if ENV._AlleralMutedSounds[sound] == nil then
			ENV._AlleralMutedSounds[sound] = sound.Volume
		end
		pcall(function()
			sound.Volume = 0
		end)
	end

	local function restoreSound(sound, volume)
		if not sound or not sound:IsA("Sound") then
			return
		end
		pcall(function()
			sound.Volume = tonumber(volume) or 0.5
		end)
	end

	if muted then
		for _, desc in ipairs(game:GetDescendants()) do
			if desc:IsA("Sound") then
				muteSound(desc)
			end
		end
		if not ENV._AlleralSoundMuteConn then
			ENV._AlleralSoundMuteConn = game.DescendantAdded:Connect(function(desc)
				if ENV.Alleral_MusicMuted == true and desc:IsA("Sound") then
					muteSound(desc)
				end
			end)
		end
	else
		for sound, volume in pairs(ENV._AlleralMutedSounds) do
			if typeof(sound) == "Instance" and sound.Parent then
				restoreSound(sound, volume)
			end
		end
		table.clear(ENV._AlleralMutedSounds)
		if ENV._AlleralSoundMuteConn then
			pcall(function()
				ENV._AlleralSoundMuteConn:Disconnect()
			end)
			ENV._AlleralSoundMuteConn = nil
		end
	end

	-- Legacy path: some executors expose a master SoundGroup or deprecated Volume.
	pcall(function()
		local master = SoundService:FindFirstChild("AlleralMaster")
		if not master then
			master = Instance.new("SoundGroup")
			master.Name = "AlleralMaster"
			master.Volume = 1
			master.Parent = SoundService
		end
		if muted then
			if ENV._Alleral_PrevMasterVolume == nil then
				ENV._Alleral_PrevMasterVolume = master.Volume
			end
			master.Volume = 0
		else
			master.Volume = ENV._Alleral_PrevMasterVolume or 1
		end
	end)

	ENV.Alleral_MusicMuted = muted
end

function Core.setLowGraphics(enabled)
	enabled = enabled == true
	local Lighting = game:GetService("Lighting")
	local Terrain = workspace:FindFirstChildOfClass("Terrain")
	ENV._AlleralDisabledEffects = ENV._AlleralDisabledEffects or {}

	local function setQuality(enabledNow)
		pcall(function()
			local gameSettings = UserSettings():GetService("UserGameSettings")
			if enabledNow then
				if ENV._Alleral_PrevQuality == nil then
					ENV._Alleral_PrevQuality = gameSettings.SavedQualityLevel
				end
				gameSettings.SavedQualityLevel = Enum.SavedQualitySetting.QualityLevel1
			elseif ENV._Alleral_PrevQuality ~= nil then
				gameSettings.SavedQualityLevel = ENV._Alleral_PrevQuality
			end
		end)
		pcall(function()
			if enabledNow then
				settings().Rendering.QualityLevel = Enum.QualityLevel.Level01
				settings().Rendering.MeshPartDetailLevel = Enum.MeshPartDetailLevel.Level01
			end
		end)
	end

	if enabled then
		ENV._Alleral_PrevShadows = Lighting.GlobalShadows
		Lighting.GlobalShadows = false
		pcall(function()
			if ENV._Alleral_PrevTechnology == nil then
				ENV._Alleral_PrevTechnology = Lighting.Technology
			end
			Lighting.Technology = Enum.Technology.Compatibility
		end)
		pcall(function()
			if Terrain and ENV._Alleral_PrevDecoration == nil then
				ENV._Alleral_PrevDecoration = Terrain.Decoration
				Terrain.Decoration = false
			end
		end)
		for _, effect in ipairs(Lighting:GetDescendants()) do
			if effect:IsA("PostEffect") and effect.Enabled then
				ENV._AlleralDisabledEffects[effect] = true
				effect.Enabled = false
			end
		end
		setQuality(true)
	else
		if ENV._Alleral_PrevShadows ~= nil then
			Lighting.GlobalShadows = ENV._Alleral_PrevShadows
		else
			Lighting.GlobalShadows = true
		end
		pcall(function()
			if ENV._Alleral_PrevTechnology ~= nil then
				Lighting.Technology = ENV._Alleral_PrevTechnology
			end
		end)
		pcall(function()
			if Terrain and ENV._Alleral_PrevDecoration ~= nil then
				Terrain.Decoration = ENV._Alleral_PrevDecoration
			end
		end)
		for effect in pairs(ENV._AlleralDisabledEffects) do
			if typeof(effect) == "Instance" and effect.Parent then
				pcall(function()
					effect.Enabled = true
				end)
			end
		end
		table.clear(ENV._AlleralDisabledEffects)
		setQuality(false)
	end

	ENV.Alleral_LowGraphics = enabled
end

function Core.buildWebJoinUrl(placeId, jobId)
	placeId = tonumber(placeId) or game.PlaceId
	jobId = tostring(jobId or game.JobId or "")
	return string.format(
		"https://www.roblox.com/games/start?placeId=%s&gameInstanceId=%s",
		tostring(placeId),
		jobId
	)
end

function Core.buildRobloxJoinUrl(placeId, jobId)
	placeId = tonumber(placeId) or game.PlaceId
	jobId = tostring(jobId or game.JobId or "")
	return string.format(
		"roblox://experiences/start?placeId=%s&gameInstanceId=%s",
		tostring(placeId),
		jobId
	)
end

function Core.currentWebJoinUrl()
	return Core.buildWebJoinUrl(game.PlaceId, game.JobId)
end

local function decodeLuxyJoinPayload(raw)
	local luxyPayload = tostring(raw or ""):match("LUXY:<([^>]+)>")
	if not luxyPayload then
		return nil
	end
	local alphabet = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
	local cleaned = luxyPayload:gsub("[^" .. alphabet .. "=]", "")
	local bits = cleaned:gsub(".", function(char)
		if char == "=" then
			return ""
		end
		local index = alphabet:find(char, 1, true)
		if not index then
			return ""
		end
		local output = ""
		for bitIndex = 6, 1, -1 do
			output = output .. (((index % (2 ^ bitIndex)) - (index % (2 ^ (bitIndex - 1))) > 0) and "1" or "0")
		end
		return output
	end)
	local decoded = bits:gsub("%d%d%d?%d?%d?%d?%d?%d?", function(chunk)
		if #chunk ~= 8 then
			return ""
		end
		local value = 0
		for bitIndex = 1, 8 do
			if chunk:sub(bitIndex, bitIndex) == "1" then
				value = value + (2 ^ (8 - bitIndex))
			end
		end
		return string.char(value)
	end)
	if decoded == "" then
		return nil
	end
	return decoded
end

function Core.parseJoinJobId(raw, defaultPlaceId)
	raw = tostring(raw or ""):gsub("^%s*(.-)%s*$", "%1")
	local placeId = tonumber(defaultPlaceId) or game.PlaceId
	if raw == "" then
		return nil, placeId
	end
	local luxyDecoded = decodeLuxyJoinPayload(raw)
	if luxyDecoded then
		raw = luxyDecoded
	end
	placeId = tonumber(raw:match("placeId=(%d+)")) or placeId
	local jobId = raw:match("gameInstanceId=([%w%-]+)")
		or raw:match("instanceId=([^&%s]+)")
		or raw:match("(%x%x%x%x%x%x%x%x%-%x%x%x%x%-%x%x%x%x%-%x%x%x%x%-%x%x%x%x%x%x%x%x%x%x%x%x)")
		or raw:match("([%w]+%-[%w]+%-[%w]+%-[%w]+%-[%w]+)")
		or raw
	jobId = tostring(jobId or ""):gsub("^%s*(.-)%s*$", "%1")
	if jobId == "" then
		return nil, placeId
	end
	return jobId, placeId
end

function Core.teleportToJoinInput(raw, defaultPlaceId)
	local jobId, placeId = Core.parseJoinJobId(raw, defaultPlaceId)
	if not jobId or jobId == "" then
		return false, "invalid_join_input"
	end
	local TeleportService = game:GetService("TeleportService")
	local Players = game:GetService("Players")
	local ok, err = pcall(function()
		TeleportService:TeleportToPlaceInstance(placeId or game.PlaceId, jobId, Players.LocalPlayer)
	end)
	if not ok then
		return false, tostring(err)
	end
	return true
end

function Core.buildJoinServerControls(group, options)
	options = options or {}
	local key = options.key or "JoinJobId"
	local state = type(options.state) == "table" and options.state or getgenv().Alleral_State
	local saveSettings = options.saveSettings
	local inputLabel = options.inputLabel or "Server link or job id"
	local inputPlaceholder = options.inputPlaceholder or "paste invite link"
	local buttonLabel = options.buttonLabel or "Hop to server"
	local buttonTooltip = options.buttonTooltip or "Full roblox share link or raw job id both work."

	local function readJoinInput()
		if type(state) == "table" and state[key] ~= nil then
			return tostring(state[key])
		end
		local g = getgenv()
		g.Alleral_JoinJobId = g.Alleral_JoinJobId or ""
		return g.Alleral_JoinJobId
	end

	local function writeJoinInput(value)
		value = tostring(value or ""):gsub("^%s*(.-)%s*$", "%1")
		if type(state) == "table" then
			state[key] = value
		end
		getgenv().Alleral_JoinJobId = value
		if type(saveSettings) == "function" then
			saveSettings()
		end
	end

	if options.dividerFirst == true then
		group:CreateDivider()
	end
	group:CreateInput(
		inputLabel,
		inputPlaceholder,
		readJoinInput(),
		function(value)
			writeJoinInput(value)
		end,
		buttonTooltip
	)
	group:CreateButton(buttonLabel, function()
		local ok, err = Core.teleportToJoinInput(readJoinInput())
		if not ok then
			Core.notify("Alleral", "That doesn't look like a valid link or job id.", 3, "warn")
			if err and err ~= "invalid_join_input" and ENV.Alleral_TelemetryDebug == true then
				warn("[Alleral] Join hop failed: " .. tostring(err))
			end
		end
	end, buttonTooltip)
end

function Core.copyJobId()
	local clip = Core.execFunction("setclipboard") or Core.execFunction("setclipboard", true)
	if type(clip) == "function" then
		pcall(clip, game.JobId)
		Core.notify("Alleral", "JobId copied.", 3)
		return true
	end
	Core.notify("Alleral", game.JobId, 8)
	return false
end

function Core.copyPlaceJoinLink()
	local link = Core.buildRobloxJoinUrl(game.PlaceId, game.JobId)
	local clip = Core.execFunction("setclipboard") or Core.execFunction("setclipboard", true)
	if type(clip) == "function" then
		pcall(clip, link)
		Core.notify("Alleral", "Join link copied.", 3)
		return true
	end
	Core.notify("Alleral", link, 8)
	return false
end

function Core.copyWebJoinLink()
	local link = Core.currentWebJoinUrl()
	local clip = Core.execFunction("setclipboard") or Core.execFunction("setclipboard", true)
	if type(clip) == "function" then
		pcall(clip, link)
		Core.notify("Alleral", "Web join link copied.", 3)
		return true
	end
	Core.notify("Alleral", link, 8)
	return false
end

function Core.rejoinServer()
	local TeleportService = game:GetService("TeleportService")
	local Players = game:GetService("Players")
	pcall(function()
		TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, Players.LocalPlayer)
	end)
end

function Core.syncWeaoConfigNow()
	local sync = getgenv().Alleral_SyncWeao
	if type(sync) == "function" then
		local ok = sync(false)
		Core.notify(
			"Alleral",
			ok and "WEAO config updated" or "WEAO config unchanged (or offline)",
			4
		)
		return ok
	end
	Core.notify("Alleral", "WEAO sync unavailable — reload the loader.", 5)
	return false
end

function Core.backupSettings(filename, jsonBody)
	local writeFile = Core.execFunction("writefile")
	local makeFolder = Core.execFunction("makefolder")
	local listFiles = Core.execFunction("listfiles")
	local deleteFile = Core.execFunction("delfile")
	if type(writeFile) ~= "function" then
		return false
	end
	pcall(makeFolder, "Alleral_Configs")
	pcall(makeFolder, "Alleral_Configs/backups")
	local base = tostring(filename or "settings.json"):gsub("%.json$", ""):gsub("[^%w%-_]", "_")
	local stamp = os.date("!%Y%m%d-%H%M%S")
	local path = "Alleral_Configs/backups/" .. base .. "_" .. stamp .. ".json"
	pcall(writeFile, path, jsonBody)
	if type(listFiles) == "function" and type(deleteFile) == "function" then
		local matches = {}
		for _, filePath in ipairs(listFiles("Alleral_Configs/backups")) do
			if tostring(filePath):find(base .. "_", 1, true) then
				table.insert(matches, tostring(filePath))
			end
		end
		table.sort(matches)
		while #matches > 8 do
			pcall(deleteFile, matches[1])
			table.remove(matches, 1)
		end
	end
	return true
end

function Core.settingsFilePath(options)
	options = type(options) == "table" and options or {}
	if type(options.settingsPath) == "string" and options.settingsPath ~= "" then
		return options.settingsPath
	end
	local file = options.settingsFile or "settings.json"
	if file:find("/", 1, true) or file:find("\\", 1, true) then
		return file
	end
	return "Alleral_Configs/" .. file
end

function Core.buildSessionStatsGroup(tab, column)
	local RunService = game:GetService("RunService")
	local Stats = game:GetService("Stats")
	local Players = game:GetService("Players")
	local startedAt = tick()
	local frameCount = 0
	local frameConn = RunService.RenderStepped:Connect(function()
		frameCount += 1
	end)
	local group = Core.buildUiGroup(tab, "Session stats", column or 1, nil, nil, "SessionStats")
	local status = group:CreateStatus("Live", {
		FPS = "--",
		Ping = "--",
		Players = "--",
		Uptime = "0s",
		Memory = "--",
	})
	task.spawn(function()
		local lastTick = tick()
		while ENV.Alleral_State and ENV.Alleral_State.HubRunning ~= false do
			local now = tick()
			local elapsed = math.max(now - lastTick, 0.001)
			local fps = math.floor(frameCount / elapsed)
			frameCount = 0
			lastTick = now
			local ping = "--"
			pcall(function()
				local item = Stats.Network.ServerStatsItem["Data Ping"]
				if item then
					ping = item:GetValueString()
				end
			end)
			local memory = "--"
			pcall(function()
				memory = string.format("%.0f MB", Stats:GetTotalMemoryUsageMb())
			end)
			local uptime = math.floor(tick() - startedAt)
			status:Update("FPS", tostring(fps))
			status:Update("Ping", ping)
			status:Update("Players", tostring(#Players:GetPlayers()))
			status:Update("Uptime", uptime .. "s")
			status:Update("Memory", memory)
			task.wait(2)
		end
		if frameConn then
			frameConn:Disconnect()
		end
	end)
	return group, status
end

function Core.buildQuickTogglesGroup(tab, options)
	options = type(options) == "table" and options or {}
	local state = options.state or ENV.Alleral_State or {}
	local saveFn = options.saveFn
	local column = options.column or 2
	local group = Core.buildUiGroup(tab, "Quick toggles", column, nil, nil, "QuickToggles")

	group:CreateToggle("Mute all audio", ENV.Alleral_MusicMuted == true, "Mutes in-game Sound instances.", function(value)
		Core.setGlobalMusicMuted(value)
		if type(saveFn) == "function" then
			saveFn()
		end
	end)

	group:CreateToggle("Low graphics", ENV.Alleral_LowGraphics == true, "Lowest quality, no shadows, fewer effects.", function(value)
		Core.setLowGraphics(value)
		if type(saveFn) == "function" then
			saveFn()
		end
	end)

	if ENV.Alleral_MusicMuted == true then
		pcall(Core.setGlobalMusicMuted, true)
	end
	if ENV.Alleral_LowGraphics == true then
		pcall(Core.setLowGraphics, true)
	end

	group:CreateToggle(
		"Auto relaunch on teleport",
		getgenv().Alleral_AutoRelaunch ~= false,
		"Reload the hub after server hops (loader setting).",
		function(value)
			getgenv().Alleral_AutoRelaunch = value == true
			ENV.Alleral_AutoRelaunch = value == true
		end
	)

	if state.AntiAFK ~= nil then
		group:CreateToggle("Anti AFK", state.AntiAFK ~= false, "Prevents idle kick.", function(value)
			state.AntiAFK = value
			if value then
				Core.setupAntiAfk(game:GetService("Players").LocalPlayer)
			end
			if type(saveFn) == "function" then
				saveFn()
			end
		end)
	end

	return group
end

function Core.buildServerToolsGroup(tab, column)
	local group = Core.buildUiGroup(tab, "Server tools", column or 1, nil, nil, "ServerTools")
	group:CreateButton("Copy JobId", Core.copyJobId, "Copy this server's instance id.")
	group:CreateButton("Copy join link", Core.copyPlaceJoinLink, "Share a direct join link.")
	group:CreateButton("Rejoin server", Core.rejoinServer, "Reconnect to this exact server.")
	group:CreateButton("Copy PlaceId", function()
		local clip = Core.execFunction("setclipboard") or Core.execFunction("setclipboard", true)
		if type(clip) == "function" then
			pcall(clip, tostring(game.PlaceId))
			Core.notify("Alleral", "PlaceId copied.", 3)
		else
			Core.notify("Alleral", tostring(game.PlaceId), 5)
		end
	end, "Copy the experience PlaceId.")
	return group
end

function Core.buildErrorLogGroup(tab, column)
	local group = Core.buildUiGroup(tab, "Error log", column or 2, nil, nil, "ErrorLog")
	Core.installErrorLogHook()
	local status = group:CreateStatus("Errors", {
		Count = tostring(#(ENV.Alleral_ErrorLog or {})),
		Latest = "None",
	})
	Core._errorLogStatus = status
	if #(ENV.Alleral_ErrorLog or {}) > 0 then
		local latest = ENV.Alleral_ErrorLog[1]
		status:Update("Latest", latest.scope .. ": " .. latest.message:sub(1, 80))
	end
	group:CreateButton("Copy log", function()
		local clip = Core.execFunction("setclipboard") or Core.execFunction("setclipboard", true)
		if type(clip) ~= "function" then
			Core.notify("Alleral", "Clipboard not supported.", 4)
			return
		end
		pcall(clip, Core.getErrorLogText(25))
		Core.notify("Alleral", "Error log copied.", 3)
	end, "Copy the last 25 errors.")
	group:CreateButton("Clear log", function()
		table.clear(ENV.Alleral_ErrorLog)
		status:Update("Count", "0")
		status:Update("Latest", "None")
		Core.notify("Alleral", "Error log cleared.", 3)
	end)
	return group, status
end

function Core.buildSettingsBackupGroup(tab, options)
	options = type(options) == "table" and options or {}
	local column = options.column or 2
	local settingsPath = Core.settingsFilePath(options)
	local readFile = Core.execFunction("readfile")
	local writeFile = Core.execFunction("writefile")
	local isFile = Core.execFunction("isfile")
	local listFiles = Core.execFunction("listfiles")
	local group = Core.buildUiGroup(tab, "Settings backup", column, nil, nil, "SettingsBackup")

	local function listBackups()
		local names = {}
		if type(listFiles) == "function" then
			local base = (options.settingsFile or "settings"):gsub("%.json$", ""):gsub("[^%w%-_]", "_")
			for _, path in ipairs(listFiles("Alleral_Configs/backups")) do
				local name = tostring(path):match("([^/\\]+)$")
				if name and name:find("^" .. base .. "_", 1, true) then
					table.insert(names, name)
				end
			end
		end
		table.sort(names, function(a, b)
			return a > b
		end)
		if #names == 0 then
			table.insert(names, "(none yet)")
		end
		return names
	end

	local selected = listBackups()[1]
	group:CreateDropdown("Backups", listBackups(), selected, function(value)
		selected = value
	end, "Rolling backups created whenever settings save.")

	group:CreateButton("Restore backup", function()
		if selected == "(none yet)" then
			Core.notify("Alleral", "No backups found yet.", 4)
			return
		end
		if type(readFile) ~= "function" or type(writeFile) ~= "function" or type(isFile) ~= "function" then
			Core.notify("Alleral", "Filesystem not supported.", 5)
			return
		end
		local backupPath = "Alleral_Configs/backups/" .. selected
		if not isFile(backupPath) then
			Core.notify("Alleral", "Backup missing.", 4)
			return
		end
		local raw = readFile(backupPath)
		pcall(writeFile, settingsPath, raw)
		Core.notify("Alleral", "Backup restored — reload the script.", 5)
	end, "Overwrites your current settings file.")

	group:CreateButton("Backup now", function()
		if type(readFile) ~= "function" or not isFile or not isFile(settingsPath) then
			Core.notify("Alleral", "Nothing to backup yet.", 4)
			return
		end
		local raw = readFile(settingsPath)
		Core.backupSettings(options.settingsFile or settingsPath, raw)
		Core.notify("Alleral", "Manual backup saved.", 3)
	end)

	return group
end

function Core.setupHubKeybinds(options)
	options = type(options) == "table" and options or {}
	if ENV._Alleral_KeybindConn then
		pcall(function()
			ENV._Alleral_KeybindConn:Disconnect()
		end)
		ENV._Alleral_KeybindConn = nil
	end
	local UserInputService = game:GetService("UserInputService")
	local panicKey = options.panicKey or Enum.KeyCode.Delete
	local uiKey = options.uiKey or Enum.KeyCode.RightControl
	ENV._Alleral_KeybindConn = UserInputService.InputBegan:Connect(function(input, processed)
		if processed or input.UserInputType ~= Enum.UserInputType.Keyboard then
			return
		end
		if input.KeyCode == panicKey then
			Core.stateHubStop()
			Core.notify("Alleral", "everything stopped", 4)
		elseif input.KeyCode == uiKey then
			if Core.toggleUiVisibility() then
				Core.notify("Alleral", "UI toggled.", 2)
			end
		end
	end)
end

function Core.buildUiPreferencesGroup(tab, options)
	options = type(options) == "table" and options or {}
	local column = options.column or 2
	local uiBundle = options.uiBundle
	if not uiBundle and type(options.window) == "table" then
		uiBundle = options.window._ui
	end
	local windUi = uiBundle and (uiBundle.WindUI or uiBundle.Library)
	local group = Core.buildUiGroup(tab, "UI tools", column, nil, nil, "UiPreferences")

	group:CreateButton("Test success toast", function()
		Core.notify("Alleral", "Success toast.", 4, "success")
	end, "Fire a success toast.")

	group:CreateButton("Test warning toast", function()
		Core.notify("Alleral", "Warning toast.", 4, "warn")
	end, "Fire a warning toast.")

	group:CreateButton("Clear all toasts", function()
		if windUi and type(windUi.ClearNotifications) == "function" then
			local cleared = windUi:ClearNotifications()
			Core.notify("Alleral", "cleared " .. tostring(cleared or 0), 2, "info")
		else
			Core.notify("Alleral", "Clear unavailable.", 3, "warn")
		end
	end, "Dismiss visible toasts.")

	group:CreateButton("Repair UI chrome", function()
		if windUi and type(windUi.RepairWindow) == "function" then
			local ok = windUi:RepairWindow()
			Core.notify("Alleral", ok and "UI repaired." or "Repair failed.", 3, ok and "success" or "error")
		else
			Core.notify("Alleral", "Repair unavailable.", 3, "warn")
		end
	end, "Re-apply theme rails and polish.")

	group:CreateToggle(
		"Bottom notifications",
		ENV.Alleral_NotifyLower == true,
		"Move toasts to the bottom-right.",
		function(value)
			ENV.Alleral_NotifyLower = value == true
			if windUi and type(windUi.SetNotificationLower) == "function" then
				pcall(function()
					windUi:SetNotificationLower(value)
				end)
			end
		end
	)

	return group
end

function Core.buildAutomationStatusGroup(tab, options)
	options = type(options) == "table" and options or {}
	local state = options.state or ENV.Alleral_State or {}
	local loops = options.loops or {}
	local column = options.column or 1
	local flags = options.flags or {
		{ key = "AFarm", label = "Auto kick" },
		{ key = "APlaceBest", label = "Auto place" },
		{ key = "AAutoUpgrade", label = "Auto upgrade" },
		{ key = "AAutoFav", label = "Auto favorite" },
		{ key = "ATrain", label = "Auto train" },
		{ key = "ACollect", label = "Auto collect" },
		{ key = "AAutoBattle", label = "Auto battle" },
		{ key = "AAutoMastery", label = "Auto mastery" },
	}

	local group = Core.buildUiGroup(tab, "Automation", column, nil, nil, "AutomationStatus")
	local status = group:CreateStatus("Live loops", {
		Active = "0",
		Total = tostring(#flags),
		Hub = state.HubRunning ~= false and "running" or "stopped",
	})

	local function refresh()
		local active = 0
		local lines = {}
		for _, entry in ipairs(flags) do
			local on = state[entry.key] == true
			if on then
				active += 1
			end
			local loopState = loops[entry.key] or loops[entry.label]
			local pulse = on and (loopState and loopState.enabled ~= false and "●" or "○") or "·"
			table.insert(lines, pulse .. " " .. entry.label)
		end
		status:Update("Active", tostring(active))
		status:Update("Hub", state.HubRunning ~= false and "running" or "stopped")
		if status.SetSummary and type(status.SetSummary) == "function" then
			status:SetSummary(table.concat(lines, "  "))
		end
	end

	group:CreateButton("Refresh status", refresh, "Update loop indicators.")
	task.spawn(function()
		while state.HubRunning ~= false do
			refresh()
			task.wait(2)
		end
	end)

	return group, status, refresh
end

function Core.hsvToColor(h, s, v)
	h = (tonumber(h) or 0) % 360
	s = math.clamp(tonumber(s) or 0, 0, 1)
	v = math.clamp(tonumber(v) or 0, 0, 1)
	local c = v * s
	local x = c * (1 - math.abs((h / 60) % 2 - 1))
	local m = v - c
	local r, g, b = 0, 0, 0
	if h < 60 then
		r, g, b = c, x, 0
	elseif h < 120 then
		r, g, b = x, c, 0
	elseif h < 180 then
		r, g, b = 0, c, x
	elseif h < 240 then
		r, g, b = 0, x, c
	elseif h < 300 then
		r, g, b = x, 0, c
	else
		r, g, b = c, 0, x
	end
	return Color3.new(r + m, g + m, b + m)
end

function Core.applyThemeAccent(windUi, color)
	if type(windUi) ~= "table" or typeof(color) ~= "Color3" then
		return false
	end
	if type(windUi.SetAccentColor) == "function" then
		pcall(function()
			windUi:SetAccentColor(color)
			if type(windUi.FlashAccent) == "function" then
				windUi:FlashAccent()
			end
		end)
		return true
	end
	return false
end

function Core.buildThemeStudioGroup(tab, options)
	options = type(options) == "table" and options or {}
	local column = options.column or 1
	local uiBundle = options.uiBundle
	if not uiBundle and type(options.window) == "table" then
		uiBundle = options.window._ui
	end
	local windUi = uiBundle and (uiBundle.WindUI or uiBundle.Library)
	local group = Core.buildUiGroup(tab, "Theme studio", column, nil, nil, "ThemeStudio")

	ENV.Alleral_AccentHue = tonumber(ENV.Alleral_AccentHue) or 108
	ENV.Alleral_AccentSat = tonumber(ENV.Alleral_AccentSat) or 0.92
	ENV.Alleral_AccentVal = tonumber(ENV.Alleral_AccentVal) or 0.96
	ENV.Alleral_UiRgbLive = ENV.Alleral_UiRgbLive ~= false

	local function pushAccent()
		local color = Core.hsvToColor(ENV.Alleral_AccentHue, ENV.Alleral_AccentSat, ENV.Alleral_AccentVal)
		Core.applyThemeAccent(windUi, color)
	end

	group:CreateToggle("Live preview", ENV.Alleral_UiRgbLive ~= false, "Update accent while dragging sliders.", function(value)
		ENV.Alleral_UiRgbLive = value ~= false
	end)

	group:CreateSlider("Hue", 0, 360, ENV.Alleral_AccentHue, function(value)
		ENV.Alleral_AccentHue = value
		if ENV.Alleral_UiRgbLive ~= false then
			pushAccent()
		end
	end, "Accent hue on the color wheel.", 1)

	group:CreateSlider("Saturation", 0, 100, math.floor(ENV.Alleral_AccentSat * 100), function(value)
		ENV.Alleral_AccentSat = value / 100
		if ENV.Alleral_UiRgbLive ~= false then
			pushAccent()
		end
	end, "Color intensity.", 1)

	group:CreateSlider("Brightness", 0, 100, math.floor(ENV.Alleral_AccentVal * 100), function(value)
		ENV.Alleral_AccentVal = value / 100
		if ENV.Alleral_UiRgbLive ~= false then
			pushAccent()
		end
	end, "How bright the accent reads.", 1)

	group:CreateButton("Apply accent", pushAccent, "Commit the wheel color to the UI.")
	group:CreateButton("Reset to mint", function()
		ENV.Alleral_AccentHue = 108
		ENV.Alleral_AccentSat = 0.92
		ENV.Alleral_AccentVal = 0.96
		if windUi and type(windUi.ApplyAccentPreset) == "function" then
			pcall(function()
				windUi:ApplyAccentPreset("Mint")
				if type(windUi.FlashAccent) == "function" then
					windUi:FlashAccent()
				end
			end)
		else
			pushAccent()
		end
	end, "Restore the default Arrrel mint accent.")

	return group
end

function Core.buildCustomizationStudioGroup(tab, options)
	options = type(options) == "table" and options or {}
	local column = options.customizationColumn or options.column or 2
	local uiBundle = options.uiBundle
	if not uiBundle and type(options.window) == "table" then
		uiBundle = options.window._ui
	end
	local windUi = uiBundle and (uiBundle.WindUI or uiBundle.Library)
	local group = Core.buildUiGroup(tab, "Customization V2", column, nil, nil, "CustomizationV2")

	if not windUi or windUi.ALLERAL_UI_V2 ~= true then
		group:CreateLabel("Alleral UI V2 layer not loaded — sync ui/windui/v2/boost.luau")
		return group
	end

	local motionProfiles = { "fluid", "snappy", "bouncy", "cinematic", "reduced" }
	if type(windUi.ListMotionProfiles) == "function" then
		local ok, listed = pcall(function()
			return windUi:ListMotionProfiles()
		end)
		if ok and type(listed) == "table" and #listed > 0 then
			motionProfiles = listed
		end
	end

	local layoutProfiles = { "auto", "desktop", "mobile", "compact", "cinema", "ultrawide", "minimal", "accessibility", "performance" }
	if type(windUi.ListProfiles) == "function" then
		local ok, listed = pcall(function()
			return windUi:ListProfiles()
		end)
		if ok and type(listed) == "table" and #listed > 0 then
			layoutProfiles = { "auto" }
			for _, entry in ipairs(listed) do
				if type(entry) == "table" and entry.id then
					table.insert(layoutProfiles, entry.id)
				elseif type(entry) == "string" then
					table.insert(layoutProfiles, entry)
				end
			end
		end
	end

	local v2Themes = {
		"Arrrel",
		"ArrrelNeon",
		"ArrrelMidnight",
		"ArrrelAurora",
		"ArrrelObsidian",
		"ArrrelSynth",
		"ArrrelOcean",
		"ArrrelEmber",
		"ArrrelStealth",
		"ArrrelPaper",
		"ArrrelVoid",
	}
	if type(windUi.ListThemeNames) == "function" then
		local ok, listed = pcall(function()
			return windUi:ListThemeNames()
		end)
		if ok and type(listed) == "table" and #listed > 0 then
			v2Themes = listed
		end
	end

	group:CreateDropdown("Layout profile", layoutProfiles, ENV.Alleral_UiProfile or "auto", function(selected)
		ENV.Alleral_UiProfile = tostring(selected or "auto")
		if type(windUi.ApplyProfile) == "function" then
			pcall(function()
				windUi:ApplyProfile(ENV.Alleral_UiProfile)
			end)
		end
		Core.notify("Alleral V2", "Layout: " .. tostring(selected), 2, "success")
	end, "Device-aware spacing and scale presets.")

	group:CreateDropdown("Motion feel", motionProfiles, windUi:GetMotionProfile and windUi:GetMotionProfile() or "fluid", function(selected)
		if type(windUi.SetMotionProfile) == "function" then
			windUi:SetMotionProfile(selected)
		end
		Core.notify("Alleral V2", "Motion: " .. tostring(selected), 2, "info")
	end, "Spring personality for tabs, toggles, and panels.")

	group:CreateSlider("Glass intensity", 0, 100, math.floor((windUi:GetGlassIntensity and windUi:GetGlassIntensity() or 0.55) * 100), function(value)
		if type(windUi.SetGlassIntensity) == "function" then
			windUi:SetGlassIntensity(value / 100)
		end
	end, "Sidebar veil and ambient glass strength.", 1)

	group:CreateSlider("Chrome depth", 0, 100, math.floor((tonumber(ENV.Alleral_ChromeDepth) or 0.65) * 100), function(value)
		ENV.Alleral_ChromeDepth = value / 100
		if type(windUi.SetChromeDepth) == "function" then
			windUi:SetChromeDepth(value / 100)
		end
	end, "Glow spread and section elevation.", 1)

	group:CreateDropdown("Tooltip style", { "minimal", "card", "rich" }, windUi:GetTooltipStyle and windUi:GetTooltipStyle() or "rich", function(selected)
		if type(windUi.SetTooltipStyle) == "function" then
			windUi:SetTooltipStyle(selected)
		end
	end, "Hover hint presentation.")

	group:CreateDropdown("Toast style", { "glass", "rail", "banner", "pill" }, windUi:GetNotificationStyle and windUi:GetNotificationStyle() or "glass", function(selected)
		if type(windUi.SetNotificationStyle) == "function" then
			windUi:SetNotificationStyle(selected)
		end
	end, "Notification chrome variant.")

	group:CreateToggle("Ambient window glow", ENV.Alleral_AmbientGlow ~= false, "Soft accent halo behind the window.", function(value)
		ENV.Alleral_AmbientGlow = value ~= false
		if type(windUi.SetAmbientGlow) == "function" then
			windUi:SetAmbientGlow(value)
		end
	end)

	group:CreateToggle("Tab aurora rail", ENV.Alleral_TabAurora ~= false, "Accent pulse on sidebar tabs.", function(value)
		ENV.Alleral_TabAurora = value ~= false
		if type(windUi.SetTabAurora) == "function" then
			windUi:SetTabAurora(value)
		end
	end)

	group:CreateToggle("Section lift", ENV.Alleral_SectionLift ~= false, "Elevated cards with accent edge glow.", function(value)
		ENV.Alleral_SectionLift = value ~= false
		if type(windUi.SetSectionLift) == "function" then
			windUi:SetSectionLift(value)
		end
	end)

	group:CreateDropdown("V2 theme", v2Themes, "Arrrel", function(selected)
		if type(windUi.SetTheme) == "function" then
			pcall(function()
				windUi:SetTheme(selected)
				if type(windUi.FlashAccent) == "function" then
					windUi:FlashAccent()
				end
			end)
		end
	end, "Full V2 theme presets including Synth, Ocean, and Void.")

	group:CreateButton("Cycle V2 themes", function()
		if type(windUi.CycleV2Theme) == "function" then
			local ok, nextTheme = pcall(function()
				return windUi:CycleV2Theme(1)
			end)
			if ok and nextTheme then
				Core.notify("Alleral V2", "Theme: " .. tostring(nextTheme), 2, "success")
			end
		end
	end, "Step through the expanded V2 palette.")

	group:CreateButton("Export look", function()
		if type(windUi.ExportCustomization) == "function" then
			local ok, payload = pcall(function()
				return windUi:ExportCustomization()
			end)
			if ok and type(payload) == "table" and Core.setClipboard then
				local encoded = game:GetService("HttpService"):JSONEncode(payload)
				pcall(Core.setClipboard, encoded)
				Core.notify("Alleral V2", "Customization copied to clipboard.", 3, "success")
			end
		end
	end, "Copy your current UI settings as JSON.")

	return group
end

function Core.buildSystemPanelGroup(tab, options)
	options = type(options) == "table" and options or {}
	local column = options.column or 2
	local group = Core.buildUiGroup(tab, "System", column, nil, nil, "SystemPanel")
	local Players = game:GetService("Players")
	local lp = Players.LocalPlayer
	local stats = {
		Hub = Core.UI_LIBRARY or "Alleral",
		UI = Core.ALLERAL_UI_VERSION or "--",
		Core = Core.VERSION or "--",
		Loader = tostring(ENV.Alleral_LoaderVersion or "--"),
		Player = lp and lp.Name or "--",
		Display = lp and lp.DisplayName or "--",
	}
	local status = group:CreateStatus("Runtime", stats)
	group:CreateButton("Refresh system info", function()
		status:Update("Hub", Core.UI_LIBRARY or "Arrrel")
		status:Update("UI", Core.ALLERAL_UI_VERSION or "--")
		status:Update("Core", Core.VERSION or "--")
		status:Update("Loader", tostring(ENV.Alleral_LoaderVersion or "--"))
		status:Update("Player", lp and lp.Name or "--")
		status:Update("Display", lp and lp.DisplayName or "--")
	end, "Refresh version and player labels.")
	return group, status
end

function Core.buildAdvancedHubGroup(tab, options)
	options = type(options) == "table" and options or {}
	local column = options.column or 1
	local group = Core.buildUiGroup(tab, "Advanced", column, nil, nil, "AdvancedHub")
	group:CreateToggle(
		"Force script load",
		ENV.Alleral_ForceLoad == true,
		"Skip manifest version checks on next reload.",
		function(value)
			ENV.Alleral_ForceLoad = value == true
			getgenv().Alleral_ForceLoad = value == true
		end
	)
	group:CreateButton("Repair UI", function()
		local ui = ENV.Alleral_UI
		local windUi = ui and (ui.WindUI or ui.Library)
		if windUi and type(windUi.RepairWindow) == "function" then
			local ok = windUi:RepairWindow()
			Core.notify("Arrrel", ok and "UI repaired." or "Repair failed.", 3, ok and "success" or "error")
		else
			Core.notify("Arrrel", "Repair unavailable.", 3, "warn")
		end
	end, "Re-apply Arrrel chrome and polish.")
	group:CreateButton("Stop hub loops", Core.stateHubStop, "Stop automation loops tied to this session.")
	return group
end

function Core.buildStandardSettingsExtras(tab, options)
	options = type(options) == "table" and options or {}
	Core.installErrorLogHook()
	if type(options.window) == "table" then
		Core.registerUiWindow(options.window)
	end
	local scriptId = Core.resolveActiveGameId(options)
	local profileVersion = options.version or options.profileVersion
	if scriptId and options.skipScriptStatus ~= true then
		Core.buildScriptStatusGroupbox(tab, options.scriptStatusColumn or 1, scriptId, profileVersion)
	end
	if options.skipHubActions ~= true then
		Core.buildHubActionsGroup(tab, options.hubActionsColumn or 2)
	end
	if options.skipCloudConfig ~= true and type(options.savedKeys) == "table" and #options.savedKeys > 0 then
		if type(options.window) == "table" then
			Core.buildCloudConfigTab(options.window, options)
			if options.cloudOnlyTab ~= true then
				Core.buildCloudConfigStudio(tab, options)
			end
		else
			Core.buildCloudConfigStudio(tab, options)
		end
	end
	Core.buildSessionStatsGroup(tab, options.sessionColumn or 1)
	Core.buildServerToolsGroup(tab, options.serverColumn or 1)
	Core.buildThemeStudioGroup(tab, options)
	Core.buildCustomizationStudioGroup(tab, options)
	Core.buildSystemPanelGroup(tab, options)
	Core.buildAdvancedHubGroup(tab, options)
	Core.buildQuickTogglesGroup(tab, options)
	Core.buildUiPreferencesGroup(tab, options)
	Core.buildErrorLogGroup(tab, options.errorColumn or 2)
	Core.buildSettingsBackupGroup(tab, options)
	if options.setupKeybinds ~= false then
		Core.setupHubKeybinds(options)
	end
	if type(options.window) == "table" then
		task.defer(function()
			Core.repairUiWindow(options.window)
		end)
	end
end

function stateHubStop()
	local state = ENV.Alleral_State
	if type(state) == "table" then
		state.HubRunning = false
		if type(state.Alleral_Unload) == "function" then
			pcall(state.Alleral_Unload)
		end
	end
	local telemetry = ENV.Alleral_Telemetry
	if type(telemetry) == "table" and type(telemetry.ReportSessionEnd) == "function" then
		telemetry:ReportSessionEnd("stopped")
	end
	Core.notify("Alleral", "loops stopped", 3)
end

Core.stateHubStop = stateHubStop

local function trimText(value)
	return tostring(value or ""):gsub("^%s*(.-)%s*$", "%1")
end

function Core.sanitizeProfileName(name)
	name = trimText(name):gsub("[^%w%-_%s]", ""):gsub("%s+", "_")
	if name == "" then
		return "Default"
	end
	return name:sub(1, 32)
end

function Core.buildConfigProfileGroup(tab, options)
	options = type(options) == "table" and options or {}
	local state = options.state or ENV.Alleral_State or {}
	local savedKeys = options.savedKeys or {}
	local profileFolder = options.profileFolder or "Alleral_Configs/Profiles"
	local saveFn = options.saveFn or function() end
	local onApply = options.onApply
	local scriptVersion = options.version or "1.0"
	local column = options.column or 2

	local writeFile = Core.execFunction("writefile")
	local readFile = Core.execFunction("readfile")
	local isFile = Core.execFunction("isfile")
	local isFolder = Core.execFunction("isfolder")
	local makeFolder = Core.execFunction("makefolder")
	local listFiles = Core.execFunction("listfiles")
	local deleteFile = Core.execFunction("delfile")
	local setClipboard = Core.execFunction("setclipboard") or Core.execFunction("setclipboard", true)

	local function ensureFolder()
		if type(makeFolder) ~= "function" then
			return false
		end
		pcall(makeFolder, "Alleral_Configs")
		pcall(makeFolder, profileFolder)
		return true
	end

	local function profilePath(name)
		return profileFolder .. "/" .. Core.sanitizeProfileName(name) .. ".json"
	end

	local function collectSnapshot()
		local snapshot = {}
		for _, key in ipairs(savedKeys) do
			snapshot[key] = Core.copyValue(state[key])
		end
		snapshot.__meta = {
			version = scriptVersion,
			createdAt = os.date("!%Y-%m-%dT%H:%M:%SZ"),
		}
		return snapshot
	end

	local function applySnapshot(snapshot)
		if type(snapshot) ~= "table" then
			return false, "Invalid profile file."
		end
		for _, key in ipairs(savedKeys) do
			if snapshot[key] ~= nil then
				state[key] = Core.copyValue(snapshot[key])
			end
		end
		if type(onApply) == "function" then
			pcall(onApply, snapshot)
		end
		saveFn()
		return true, nil
	end

	local function listProfiles()
		local names = {}
		if type(listFiles) == "function" and type(isFolder) == "function" and isFolder(profileFolder) then
			for _, path in ipairs(listFiles(profileFolder)) do
				local name = tostring(path):match("([^/\\]+)%.json$")
				if name then
					table.insert(names, name)
				end
			end
		end
		table.sort(names)
		if #names == 0 then
			table.insert(names, "Default")
		end
		return names
	end

	local profileName = Core.sanitizeProfileName(state.ActiveProfileName or "Default")
	local groupbox = tab:CreateGroupbox({
		Name = "Config profiles",
		Column = column,
		Icon = 6031075938,
	}, "ConfigProfiles")
	local group = Core.wrapUiGroup(groupbox)

	group:CreateInput("Profile name", "my setup", profileName, function(value)
		profileName = Core.sanitizeProfileName(value)
		state.ActiveProfileName = profileName
		saveFn()
	end, "Name used when saving or loading.")

	group:CreateButton("Save profile", function()
		if type(writeFile) ~= "function" then
			Core.notify("Alleral", "Your executor can't save files.", 5)
			return
		end
		ensureFolder()
		local ok = Core.writeFile(profilePath(profileName), HttpService:JSONEncode(collectSnapshot()))
		if ok then
			state.ActiveProfileName = profileName
			saveFn()
			Core.notify("Alleral", "Saved '" .. profileName .. "'.", 4)
		end
	end, "Writes all settings to disk under this name.")

	group:CreateButton("Load profile", function()
		if type(readFile) ~= "function" or type(isFile) ~= "function" then
			Core.notify("Alleral", "Your executor can't read files.", 5)
			return
		end
		local path = profilePath(profileName)
		if not isFile(path) then
			Core.notify("Alleral", "No profile named '" .. profileName .. "'.", 5)
			return
		end
		local raw = readFile(path)
		local decodedOk, decoded = pcall(function()
			return HttpService:JSONDecode(raw)
		end)
		if not decodedOk then
			Core.notify("Alleral", "Profile JSON is corrupt.", 5)
			return
		end
		local applied, err = applySnapshot(decoded)
		if applied then
			Core.notify("Alleral", "Loaded '" .. profileName .. "'. Reload to refresh UI.", 5)
		else
			Core.notify("Alleral", tostring(err), 5)
		end
	end, "Applies a saved profile to this session.")

	group:CreateButton("Delete profile", function()
		if type(deleteFile) ~= "function" then
			Core.notify("Alleral", "Your executor can't delete files.", 5)
			return
		end
		local path = profilePath(profileName)
		if type(isFile) == "function" and not isFile(path) then
			Core.notify("Alleral", "Nothing to delete.", 4)
			return
		end
		pcall(deleteFile, path)
		Core.notify("Alleral", "Deleted '" .. profileName .. "'.", 4)
	end)

	group:CreateButton("Copy to clipboard", function()
		if type(setClipboard) ~= "function" then
			Core.notify("Alleral", "Clipboard not supported.", 4)
			return
		end
		pcall(setClipboard, HttpService:JSONEncode(collectSnapshot()))
		Core.notify("Alleral", "Profile copied — paste to share.", 4)
	end)

	group:CreateButton("Paste from clipboard", function()
		local clip = Core.execFunction("getclipboard") or Core.execFunction("getclipboard", true)
		if type(clip) ~= "function" then
			Core.notify("Alleral", "Clipboard not supported.", 4)
			return
		end
		local ok, raw = pcall(clip)
		if not ok or type(raw) ~= "string" or raw == "" then
			Core.notify("Alleral", "Clipboard is empty.", 4)
			return
		end
		local decodedOk, decoded = pcall(function()
			return HttpService:JSONDecode(raw)
		end)
		if not decodedOk then
			Core.notify("Alleral", "Clipboard doesn't contain valid JSON.", 5)
			return
		end
		local applied, err = applySnapshot(decoded)
		if applied then
			Core.notify("Alleral", "Imported profile from clipboard.", 4)
		else
			Core.notify("Alleral", tostring(err), 5)
		end
	end)

	local names = listProfiles()
	group:CreateDropdown("Saved profiles", names, profileName, function(value)
		profileName = Core.sanitizeProfileName(value)
		state.ActiveProfileName = profileName
		saveFn()
	end, "Quick-pick a profile you've saved before.")

	return group
end

function Core.buildCloudConfigStudio(tab, options)
	options = type(options) == "table" and options or {}
	local state = options.state or ENV.Alleral_State or {}
	local savedKeys = options.savedKeys or {}
	local saveFn = options.saveFn or function() end
	local onApply = options.onApply
	local scriptVersion = options.version or options.profileVersion or "1.0"
	local gameId = Core.resolveActiveGameId(options) or options.gameId or "unknown"
	local libraryColumn = options.cloudLibraryColumn or 1
	local communityColumn = options.cloudCommunityColumn or 2
	local shareCode = tostring(state.Alleral_CloudConfigCode or "")
	local sharePublic = state.Alleral_CloudConfigPublic ~= false
	local browseEntries = {}
	local browseLabels = { "Refresh community list" }
	local selectedBrowseCode = shareCode
	local previewCache = nil

	local function collectSnapshot()
		local snapshot = {}
		for _, key in ipairs(savedKeys) do
			snapshot[key] = Core.copyValue(state[key])
		end
		snapshot.__meta = {
			version = scriptVersion,
			gameId = gameId,
			createdAt = os.date("!%Y-%m-%dT%H:%M:%SZ"),
			brand = "Alleral",
		}
		return snapshot
	end

	local function applySnapshot(snapshot)
		if type(snapshot) ~= "table" then
			return false, "Invalid cloud config."
		end
		for _, key in ipairs(savedKeys) do
			if snapshot[key] ~= nil then
				state[key] = Core.copyValue(snapshot[key])
			end
		end
		if type(onApply) == "function" then
			pcall(onApply, snapshot)
		end
		saveFn()
		return true, nil
	end

	local function countDiff(remote)
		if type(remote) ~= "table" then
			return 0
		end
		local changed = 0
		for _, key in ipairs(savedKeys) do
			local localValue = state[key]
			local remoteValue = remote[key]
			if remoteValue ~= nil and HttpService:JSONEncode(localValue) ~= HttpService:JSONEncode(remoteValue) then
				changed += 1
			end
		end
		return changed
	end

	local function formatBrowseLabel(entry)
		return string.format(
			"[%s] %s · %s · %s dl",
			tostring(entry.code or "??????"),
			tostring(entry.name or "Untitled"),
			tostring(entry.author or "?"),
			tostring(entry.downloads or 0)
		)
	end

	local library = Core.buildUiGroup(tab, "Cloud library", libraryColumn, nil, nil, "CloudLibrary")
	local community = Core.buildUiGroup(tab, "Community browser", communityColumn, nil, nil, "CloudCommunity")

	local cloudStatus = library:CreateStatus("Cloud", {
		Code = shareCode ~= "" and shareCode or "--",
		Setup = state.Alleral_CloudConfigName or "My setup",
		DNA = "--",
		Diff = "--",
		Downloads = "--",
		Status = "Ready",
	})
	cloudStatus:SetSummary("Upload, preview DNA, then import when you're happy.")

	local function setStatus(message, tone)
		cloudStatus:Update("Status", message or "Ready")
		if tone then
			Core.notify("Alleral Cloud", tostring(message or ""), 5, tone)
		end
	end

	local function updatePreviewStatus(decoded)
		previewCache = decoded
		if type(decoded) ~= "table" then
			cloudStatus:Update("DNA", "--")
			cloudStatus:Update("Diff", "--")
			cloudStatus:Update("Downloads", "--")
			return
		end
		local diff = countDiff(decoded.data)
		cloudStatus:Update("Code", tostring(decoded.code or shareCode or "--"))
		cloudStatus:Update("Setup", tostring(decoded.name or state.Alleral_CloudConfigName or "My setup"))
		cloudStatus:Update("DNA", tostring(decoded.dna or "?"))
		cloudStatus:Update("Diff", tostring(diff) .. " keys")
		cloudStatus:Update("Downloads", tostring(decoded.downloads or 0))
		cloudStatus:SetSummary(
			string.format(
				"%s by %s · v%s · DNA %s · %s keys would change",
				tostring(decoded.name or "Untitled"),
				tostring(decoded.author or "?"),
				tostring(decoded.scriptVersion or "?"),
				tostring(decoded.dna or "?"),
				tostring(diff)
			)
		)
	end

	local function fetchRemote(code)
		code = trimText(code):upper()
		if code == "" then
			return nil, "Enter a share code."
		end
		local base = Core.resolveRelayBase()
		local decoded = Core.httpGetJson(base .. "/api/configs/" .. code)
		if not decoded or decoded.ok ~= true or type(decoded.data) ~= "table" then
			return nil, decoded and decoded.error or "Config not found."
		end
		return decoded, nil
	end

	library:CreateLabel("Publish your current setup to the Alleral cloud. Each upload gets a DNA fingerprint so you can preview before importing.")
	library:CreateInput("Setup name", "my public build", state.Alleral_CloudConfigName or "My setup", function(value)
		state.Alleral_CloudConfigName = trimText(value)
		cloudStatus:Update("Setup", state.Alleral_CloudConfigName)
		saveFn()
	end, "Shown in the community browser when public.")
	library:CreateToggle(
		"List publicly",
		sharePublic,
		"Public configs appear in the community browser for this game.",
		function(value)
			sharePublic = value ~= false
			state.Alleral_CloudConfigPublic = sharePublic
			saveFn()
		end
	)
	library:CreateButton("Upload current setup", function()
		setStatus("Uploading...", nil)
		local base = Core.resolveRelayBase()
		local payload = {
			gameId = gameId,
			name = state.Alleral_CloudConfigName or "My setup",
			author = (game:GetService("Players").LocalPlayer and game:GetService("Players").LocalPlayer.DisplayName) or "Player",
			scriptVersion = scriptVersion,
			public = sharePublic,
			tags = { "alleral", gameId },
			data = collectSnapshot(),
		}
		local decoded, err = Core.httpPostJson(base .. "/api/configs/publish", payload)
		if not decoded or decoded.ok ~= true or not decoded.code then
			setStatus("Upload failed", "error")
			return
		end
		shareCode = tostring(decoded.code)
		state.Alleral_CloudConfigCode = shareCode
		saveFn()
		cloudStatus:Update("Code", shareCode)
		cloudStatus:Update("DNA", tostring(decoded.dna or "?"))
		cloudStatus:Update("Diff", "0 keys")
		cloudStatus:SetSummary("Uploaded " .. shareCode .. " · DNA " .. tostring(decoded.dna or "?"))
		setStatus("Uploaded " .. shareCode, "success")
		if Core.setClipboard then
			pcall(Core.setClipboard, shareCode)
		end
		task.defer(refreshBrowse)
	end, "Uploads this session and copies the share code.")
	library:CreateDivider()
	library:CreateInput("Share code", "ABC123", shareCode, function(value)
		shareCode = trimText(value):upper()
		state.Alleral_CloudConfigCode = shareCode
		cloudStatus:Update("Code", shareCode ~= "" and shareCode or "--")
		saveFn()
	end, "Paste a friend's 6-character code.")
	library:CreateButton("Preview DNA", function()
		if shareCode == "" then
			setStatus("Enter a share code first.", "warn")
			return
		end
		setStatus("Fetching preview...", nil)
		local decoded, err = fetchRemote(shareCode)
		if not decoded then
			setStatus(tostring(err or "Preview failed."), "error")
			return
		end
		updatePreviewStatus(decoded)
		setStatus("Preview ready", "info")
	end, "Loads remote DNA and shows how many keys would change.")
	library:CreateButton("Import selected setup", function()
		if shareCode == "" then
			setStatus("Enter a share code first.", "warn")
			return
		end
		setStatus("Importing...", nil)
		local decoded = previewCache
		if not decoded or tostring(decoded.code or ""):upper() ~= shareCode then
			local remote, err = fetchRemote(shareCode)
			if not remote then
				setStatus(tostring(err or "Import failed."), "error")
				return
			end
			decoded = remote
		end
		local applied, err = applySnapshot(decoded.data)
		if applied then
			updatePreviewStatus(decoded)
			setStatus("Imported " .. tostring(decoded.name or shareCode), "success")
		else
			setStatus(tostring(err or "Import failed."), "error")
		end
	end, "Applies the previewed cloud config to this session.")

	local communityStatus = community:CreateStatus("Browse", {
		Game = gameId,
		Listed = "0",
		Selected = shareCode ~= "" and shareCode or "--",
	})
	communityStatus:SetSummary("Pick a public setup, preview it, then import from the library panel.")

	local browseDropdown
	local function refreshBrowse()
		local base = Core.resolveRelayBase()
		local decoded = Core.httpGetJson(base .. "/api/configs/browse?game=" .. HttpService:UrlEncode(gameId) .. "&limit=20")
		browseEntries = {}
		browseLabels = {}
		if decoded and decoded.ok == true and type(decoded.configs) == "table" then
			for _, entry in ipairs(decoded.configs) do
				if type(entry) == "table" and entry.code then
					table.insert(browseEntries, entry)
					table.insert(browseLabels, formatBrowseLabel(entry))
				end
			end
		end
		if #browseLabels == 0 then
			table.insert(browseLabels, "No public configs yet")
		end
		communityStatus:Update("Listed", tostring(#browseEntries))
		if browseDropdown and browseDropdown.Refresh then
			browseDropdown:Refresh(browseLabels, browseLabels[1])
		end
		if #browseEntries > 0 then
			selectedBrowseCode = tostring(browseEntries[1].code or "")
			communityStatus:Update("Selected", selectedBrowseCode)
		end
	end

	community:CreateLabel("Browse player-uploaded setups for this game. Select one to load its share code into the library panel.")
	browseDropdown = community:AddDropdown("CloudBrowse", {
		Text = "Public setups",
		Values = browseLabels,
		Default = browseLabels[1],
		Tooltip = "Sorted by downloads.",
		Callback = function(selected)
			local label = type(selected) == "table" and selected[1] or selected
			for index, entry in ipairs(browseEntries) do
				if browseLabels[index] == label then
					selectedBrowseCode = tostring(entry.code or "")
					shareCode = selectedBrowseCode
					state.Alleral_CloudConfigCode = shareCode
					cloudStatus:Update("Code", shareCode)
					communityStatus:Update("Selected", shareCode)
					saveFn()
					task.defer(function()
						local decoded, err = fetchRemote(shareCode)
						if decoded then
							updatePreviewStatus(decoded)
							communityStatus:SetSummary(formatBrowseLabel(entry))
						else
							communityStatus:SetSummary(tostring(err or "Preview failed."))
						end
					end)
					return
				end
			end
		end,
	})
	community:CreateButton("Refresh community list", refreshBrowse, "Pull the latest public configs from the relay.")
	community:CreateButton("Load into library", function()
		if selectedBrowseCode == "" or selectedBrowseCode == "No public configs yet" then
			setStatus("Pick a public setup first.", "warn")
			return
		end
		shareCode = selectedBrowseCode
		state.Alleral_CloudConfigCode = shareCode
		cloudStatus:Update("Code", shareCode)
		saveFn()
		task.defer(function()
			local decoded, err = fetchRemote(shareCode)
			if decoded then
				updatePreviewStatus(decoded)
				setStatus("Loaded " .. shareCode .. " into library.", "success")
			else
				setStatus(tostring(err or "Load failed."), "error")
			end
		end)
	end, "Copies the selected community code into the library panel.")
	community:CreateButton("Import selected setup", function()
		if selectedBrowseCode == "" then
			setStatus("Pick a public setup first.", "warn")
			return
		end
		shareCode = selectedBrowseCode
		state.Alleral_CloudConfigCode = shareCode
		local decoded, err = fetchRemote(shareCode)
		if not decoded then
			setStatus(tostring(err or "Import failed."), "error")
			return
		end
		local applied, applyErr = applySnapshot(decoded.data)
		if applied then
			updatePreviewStatus(decoded)
			setStatus("Imported " .. tostring(decoded.name or shareCode), "success")
		else
			setStatus(tostring(applyErr or "Import failed."), "error")
		end
	end, "Imports the highlighted community setup immediately.")

	task.defer(refreshBrowse)

	return library, community, cloudStatus, communityStatus
end

Core.buildCloudConfigGroup = Core.buildCloudConfigStudio

function Core.buildCloudConfigTab(window, options)
	options = type(options) == "table" and options or {}
	window = window or options.window
	if not window then
		return nil
	end
	local tab = Core.buildUiTab(
		{ _window = window, _ui = options.uiBundle or window._ui },
		options.cloudTabName or "Configs",
		options.cloudTabIcon or "cloud",
		2
	)
	Core.buildCloudConfigStudio(tab, options)
	return tab
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

function Core.buildDiscordEmbed(opts)
	opts = type(opts) == "table" and opts or {}
	local embed = {
		title = opts.title,
		description = opts.description,
		color = opts.color or 5489688,
		fields = opts.fields,
		footer = opts.footer or { text = opts.brand or "Alleral" },
		timestamp = opts.timestamp,
		thumbnail = opts.thumbnail,
		image = opts.image,
		author = opts.author,
	}
	if embed.fields == nil then
		embed.fields = {}
	end
	return embed
end

function Core.buildDiscordPayload(opts)
	opts = type(opts) == "table" and opts or {}
	local embeds = opts.embeds
	if type(embeds) ~= "table" or #embeds == 0 then
		embeds = { Core.buildDiscordEmbed(opts) }
	end
	return {
		username = opts.username or opts.brand or "Alleral",
		avatar_url = opts.avatarUrl,
		content = opts.content,
		embeds = embeds,
	}
end

function Core.discordField(name, value, inline)
	local text = trimText(value)
	if text == "" then
		text = "—"
	end
	if #text > 1024 then
		text = text:sub(1, 1021) .. "..."
	end
	return {
		name = tostring(name or "Field"),
		value = "```" .. text .. "```",
		inline = inline == true,
	}
end

function Core.discordLinkField(name, label, url, inline)
	url = trimText(url)
	if url == "" then
		return Core.discordField(name, "—", inline)
	end
	return {
		name = tostring(name or "Link"),
		value = string.format("[%s](%s)", label or "Open", url),
		inline = inline == true,
	}
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

function Core.applyUiLayer(source, label)
	if Core._UiLayerReady then
		return true
	end
	if type(source) ~= "string" or source == "" then
		return false, "empty ui layer"
	end
	local loadFn = Core.loadStringFn()
	if not loadFn then
		return false, "loadstring unavailable"
	end
	local chunk, compileErr = loadFn(source, label or "@Alleral/core_ui")
	if not chunk then
		return false, tostring(compileErr)
	end
	local ok, layer = pcall(chunk)
	if not ok or type(layer) ~= "function" then
		return false, ok and "ui layer must return function(Core)" or tostring(layer)
	end
	local applied, applyErr = pcall(layer, Core)
	if not applied then
		return false, tostring(applyErr)
	end
	if type(Core.loadUi) ~= "function" or type(Core.buildUiGroup) ~= "function" then
		return false, "ui layer incomplete"
	end
	Core._UiLayerReady = true
	return true
end

Core.installResilience()

ENV.Alleral_Core = Core
return Core