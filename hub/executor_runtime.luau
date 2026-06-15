-- Alleral executor detection, capability matrix, and per-injector UI/runtime quirks.
local ExecutorRuntime = {}
ExecutorRuntime.VERSION = "1.0.0"

local function genv()
	local ok, env = pcall(function()
		return getgenv and getgenv() or getfenv()
	end)
	return ok and env or {}
end

local ENV = genv()

local function trim(value)
	return tostring(value or ""):gsub("^%s*(.-)%s*$", "%1")
end

local function normalizeSlug(text)
	local key = trim(text):lower()
	key = key:gsub("synapse%s*z", "synapsez")
	key = key:gsub("awp%.?gg?", "volt")
	key = key:gsub("bunni%.?fun", "bunni")
	key = key:gsub("vega%s*x", "vegax")
	key = key:gsub("[^a-z0-9]+", "")
	return key
end

local function hasFn(name)
	local fn = ENV[name]
	if type(fn) == "function" then
		return true
	end
	if _G and type(_G[name]) == "function" then
		return true
	end
	return false
end

local function hasTable(key)
	local value = ENV[key]
	if type(value) == "table" then
		return true
	end
	local sharedEnv = ENV.shared or (typeof(shared) == "table" and shared) or nil
	return type(sharedEnv) == "table" and type(sharedEnv[key]) == "table"
end

local function firstFn(names)
	for _, name in ipairs(names) do
		if hasFn(name) then
			return ENV[name] or (_G and _G[name])
		end
	end
	return nil
end

-- slug -> { display, aliases, envKeys, envFlags, fsBroken, mobile, ui = { min, max, rail, scale } }
ExecutorRuntime.REGISTRY = {
	synapsez = {
		display = "Synapse Z",
		aliases = { "synapse z", "synz" },
		envKeys = { "syn", "Synapse" },
		envFlags = { SynapseZ = true },
		tier = "premium",
		ui = { min = Vector2.new(520, 380), max = Vector2.new(980, 760), rail = 68, scale = 1, mobile = false },
	},
	synapse = {
		display = "Synapse",
		aliases = { "synapse x", "synapse" },
		envKeys = { "syn" },
		tier = "premium",
		ui = { min = Vector2.new(520, 380), max = Vector2.new(960, 720), rail = 68, scale = 1, mobile = false },
	},
	krnl = {
		display = "KRNL",
		aliases = { "krnl" },
		envFlags = { KRNL_LOADED = true },
		tier = "standard",
		ui = { min = Vector2.new(480, 360), max = Vector2.new(900, 680), rail = 64, scale = 0.98, mobile = false },
	},
	fluxus = {
		display = "Fluxus",
		aliases = { "fluxus" },
		envKeys = { "fluxus" },
		tier = "standard",
		ui = { min = Vector2.new(480, 360), max = Vector2.new(920, 700), rail = 64, scale = 0.98, mobile = false },
	},
	scriptware = {
		display = "Script-Ware",
		aliases = { "script ware", "scriptware" },
		envKeys = { "sw" },
		tier = "premium",
		ui = { min = Vector2.new(500, 370), max = Vector2.new(940, 720), rail = 66, scale = 1, mobile = false },
	},
	celery = {
		display = "Celery",
		aliases = { "celery" },
		envKeys = { "celery" },
		tier = "standard",
		ui = { min = Vector2.new(460, 340), max = Vector2.new(880, 660), rail = 62, scale = 0.96, mobile = false },
	},
	delta = {
		display = "Delta",
		aliases = { "delta" },
		envKeys = { "delta" },
		tier = "mobile",
		ui = { min = Vector2.new(420, 320), max = Vector2.new(820, 620), rail = 58, scale = 0.92, mobile = true },
	},
	wave = {
		display = "Wave",
		aliases = { "wave" },
		envKeys = { "Wave" },
		tier = "premium",
		ui = { min = Vector2.new(500, 380), max = Vector2.new(960, 740), rail = 66, scale = 1, mobile = false },
	},
	electron = {
		display = "Electron",
		aliases = { "electron" },
		envKeys = { "Electron" },
		tier = "standard",
		ui = { min = Vector2.new(480, 360), max = Vector2.new(900, 680), rail = 64, scale = 0.98, mobile = false },
	},
	solara = {
		display = "Solara",
		aliases = { "solara", "solora" },
		envKeys = { "Solara", "solara" },
		tier = "mobile",
		ui = { min = Vector2.new(400, 300), max = Vector2.new(760, 580), rail = 54, scale = 0.88, mobile = true },
	},
	xeno = {
		display = "Xeno",
		aliases = { "xeno" },
		envKeys = { "Xeno" },
		tier = "mobile",
		ui = { min = Vector2.new(520, 360), max = Vector2.new(960, 680), rail = 108, scale = 0.96, mobile = false },
	},
	volt = {
		display = "Volt",
		aliases = { "volt", "awp", "awp.gg" },
		envKeys = { "Volt", "AWP", "awp" },
		tier = "standard",
		ui = { min = Vector2.new(480, 360), max = Vector2.new(920, 700), rail = 64, scale = 0.96, mobile = false },
	},
	potassium = {
		display = "Potassium",
		aliases = { "potassium" },
		envKeys = { "Potassium", "potassium" },
		tier = "standard",
		ui = { min = Vector2.new(460, 340), max = Vector2.new(880, 660), rail = 62, scale = 0.94, mobile = false },
	},
	velocity = {
		display = "Velocity",
		aliases = { "velocity" },
		envKeys = { "Velocity" },
		tier = "standard",
		ui = { min = Vector2.new(480, 360), max = Vector2.new(900, 680), rail = 64, scale = 0.96, mobile = false },
	},
	codex = {
		display = "Codex",
		aliases = { "codex" },
		envKeys = { "Codex" },
		tier = "standard",
		ui = { min = Vector2.new(480, 360), max = Vector2.new(900, 680), rail = 64, scale = 0.96, mobile = false },
	},
	hydrogen = {
		display = "Hydrogen",
		aliases = { "hydrogen" },
		envKeys = { "Hydrogen" },
		tier = "mobile",
		ui = { min = Vector2.new(420, 320), max = Vector2.new(820, 620), rail = 58, scale = 0.9, mobile = true },
	},
	oxygenu = {
		display = "Oxygen U",
		aliases = { "oxygen u", "oxygen" },
		envFlags = { OXYGEN_U = true },
		tier = "mobile",
		ui = { min = Vector2.new(420, 320), max = Vector2.new(820, 620), rail = 58, scale = 0.9, mobile = true },
	},
	matcha = {
		display = "Matcha",
		aliases = { "matcha" },
		tier = "standard",
		ui = { min = Vector2.new(460, 340), max = Vector2.new(880, 660), rail = 62, scale = 0.94, mobile = false },
	},
	photon = {
		display = "Photon",
		aliases = { "photon" },
		tier = "standard",
		ui = { min = Vector2.new(460, 340), max = Vector2.new(880, 660), rail = 62, scale = 0.94, mobile = false },
	},
	cryptic = {
		display = "Cryptic",
		aliases = { "cryptic" },
		envKeys = { "Cryptic" },
		tier = "standard",
		ui = { min = Vector2.new(460, 340), max = Vector2.new(880, 660), rail = 62, scale = 0.94, mobile = false },
	},
	ronix = {
		display = "Ronix",
		aliases = { "ronix" },
		envKeys = { "Ronix" },
		tier = "standard",
		ui = { min = Vector2.new(460, 340), max = Vector2.new(880, 660), rail = 62, scale = 0.94, mobile = false },
	},
	trigon = {
		display = "Trigon",
		aliases = { "trigon" },
		envKeys = { "Trigon" },
		tier = "standard",
		ui = { min = Vector2.new(460, 340), max = Vector2.new(880, 660), rail = 62, scale = 0.94, mobile = false },
	},
	jjsploit = {
		display = "JJSploit",
		aliases = { "jjsploit", "jj sploit" },
		envFlags = { IS_JJSLOIT = true },
		envKeys = { "jjsploit" },
		tier = "mobile",
		ui = { min = Vector2.new(400, 300), max = Vector2.new(760, 560), rail = 52, scale = 0.86, mobile = true },
	},
	swift = {
		display = "Swift",
		aliases = { "swift" },
		envKeys = { "Swift", "swift" },
		tier = "standard",
		ui = { min = Vector2.new(460, 340), max = Vector2.new(880, 660), rail = 62, scale = 0.94, mobile = false },
	},
	evon = {
		display = "Evon",
		aliases = { "evon" },
		envKeys = { "Evon", "evon" },
		tier = "mobile",
		ui = { min = Vector2.new(420, 320), max = Vector2.new(800, 600), rail = 56, scale = 0.9, mobile = true },
	},
	seliware = {
		display = "Seliware",
		aliases = { "seliware" },
		envKeys = { "Seliware", "seliware" },
		tier = "standard",
		ui = { min = Vector2.new(460, 340), max = Vector2.new(880, 660), rail = 62, scale = 0.94, mobile = false },
	},
	macsploit = {
		display = "MacSploit",
		aliases = { "macsploit", "mac sploit" },
		envKeys = { "Macsploit", "macsploit" },
		tier = "standard",
		ui = { min = Vector2.new(480, 360), max = Vector2.new(900, 680), rail = 64, scale = 0.96, mobile = false },
	},
	cosmic = {
		display = "Cosmic",
		aliases = { "cosmic" },
		envKeys = { "Cosmic", "cosmic" },
		tier = "standard",
		ui = { min = Vector2.new(460, 340), max = Vector2.new(880, 660), rail = 62, scale = 0.94, mobile = false },
	},
	serotonin = {
		display = "Serotonin",
		aliases = { "serotonin" },
		tier = "premium",
		ui = { min = Vector2.new(500, 380), max = Vector2.new(960, 740), rail = 66, scale = 1, mobile = false },
	},
	lumen = {
		display = "Lumen",
		aliases = { "lumen" },
		tier = "standard",
		ui = { min = Vector2.new(460, 340), max = Vector2.new(880, 660), rail = 62, scale = 0.94, mobile = false },
	},
	sentinel = {
		display = "Sentinel",
		aliases = { "sentinel" },
		envKeys = { "Sentinel" },
		tier = "standard",
		ui = { min = Vector2.new(460, 340), max = Vector2.new(880, 660), rail = 62, scale = 0.94, mobile = false },
	},
	arceus = {
		display = "Arceus X",
		aliases = { "arceus" },
		envFlags = { ARCEUS_LOADED = true },
		fsBroken = true,
		tier = "mobile",
		ui = { min = Vector2.new(400, 300), max = Vector2.new(740, 560), rail = 52, scale = 0.85, mobile = true },
	},
	comet = {
		display = "Comet",
		aliases = { "comet" },
		envKeys = { "Comet" },
		fsBroken = true,
		tier = "mobile",
		ui = { min = Vector2.new(400, 300), max = Vector2.new(740, 560), rail = 52, scale = 0.85, mobile = true },
	},
	vegax = {
		display = "Vega X",
		aliases = { "vega x", "vega" },
		envKeys = { "Vega", "VegaX" },
		fsBroken = true,
		tier = "mobile",
		ui = { min = Vector2.new(400, 300), max = Vector2.new(740, 560), rail = 52, scale = 0.85, mobile = true },
	},
	bunni = {
		display = "Bunni",
		aliases = { "bunni", "bunni.fun" },
		envKeys = { "Bunni", "bunni" },
		tier = "standard",
		ui = { min = Vector2.new(460, 340), max = Vector2.new(880, 660), rail = 62, scale = 0.94, mobile = false },
	},
	volcano = {
		display = "Volcano",
		aliases = { "volcano" },
		envKeys = { "Volcano", "volcano" },
		tier = "standard",
		ui = { min = Vector2.new(460, 340), max = Vector2.new(880, 660), rail = 62, scale = 0.94, mobile = false },
	},
	ronin = {
		display = "Ronin",
		aliases = { "ronin" },
		envKeys = { "Ronin", "ronin" },
		tier = "standard",
		ui = { min = Vector2.new(460, 340), max = Vector2.new(880, 660), rail = 62, scale = 0.94, mobile = false },
	},
	opiumware = {
		display = "Opiumware",
		aliases = { "opiumware" },
		envKeys = { "Opiumware", "opiumware" },
		tier = "standard",
		ui = { min = Vector2.new(460, 340), max = Vector2.new(880, 660), rail = 62, scale = 0.94, mobile = false },
	},
	madium = {
		display = "Madium",
		aliases = { "madium" },
		envKeys = { "Madium" },
		tier = "standard",
		ui = { min = Vector2.new(460, 340), max = Vector2.new(880, 660), rail = 62, scale = 0.94, mobile = false },
	},
	nihon = {
		display = "Nihon",
		aliases = { "nihon" },
		envKeys = { "Nihon" },
		tier = "standard",
		ui = { min = Vector2.new(460, 340), max = Vector2.new(880, 660), rail = 62, scale = 0.94, mobile = false },
	},
	zenith = {
		display = "Zenith",
		aliases = { "zenith" },
		tier = "standard",
		ui = { min = Vector2.new(480, 360), max = Vector2.new(900, 680), rail = 64, scale = 0.96, mobile = false },
	},
	rbxcli = {
		display = "RBXCLI",
		aliases = { "rbxcli", "rbx cli" },
		tier = "standard",
		ui = { min = Vector2.new(480, 360), max = Vector2.new(900, 680), rail = 64, scale = 0.96, mobile = false },
	},
	sirhurt = {
		display = "SirHurt",
		aliases = { "sirhurt", "sir hurt" },
		envKeys = { "SirHurt", "sirhurt" },
		tier = "standard",
		ui = { min = Vector2.new(460, 340), max = Vector2.new(880, 660), rail = 62, scale = 0.94, mobile = false },
	},
	unknown = {
		display = "Unknown",
		aliases = {},
		tier = "unknown",
		ui = { min = Vector2.new(440, 330), max = Vector2.new(860, 640), rail = 60, scale = 0.92, mobile = false },
	},
}

local ALIAS_INDEX = {}
for slug, entry in pairs(ExecutorRuntime.REGISTRY) do
	for _, alias in ipairs(entry.aliases or {}) do
		ALIAS_INDEX[alias:lower()] = slug
	end
	ALIAS_INDEX[slug] = slug
end

function ExecutorRuntime.resolveSlug(rawName, envSlugs)
	local fromText = normalizeSlug(rawName or "")
	if fromText ~= "" and ExecutorRuntime.REGISTRY[fromText] then
		return fromText
	end
	for alias, slug in pairs(ALIAS_INDEX) do
		if rawName and tostring(rawName):lower():find(alias, 1, true) then
			return slug
		end
	end
	if type(envSlugs) == "table" then
		for _, slug in ipairs(envSlugs) do
			if ExecutorRuntime.REGISTRY[slug] then
				return slug
			end
		end
	end
	for slug, entry in pairs(ExecutorRuntime.REGISTRY) do
		if slug == "unknown" then
			continue
		end
		for _, key in ipairs(entry.envKeys or {}) do
			if hasTable(key) then
				return slug
			end
		end
		for flag, expected in pairs(entry.envFlags or {}) do
			if ENV[flag] == expected then
				return slug
			end
		end
	end
	if fromText ~= "" then
		return fromText
	end
	return "unknown"
end

function ExecutorRuntime.detectRawName()
	for _, id in ipairs({
		"identifyexecutor",
		"getexecutorname",
		"whatexecutor",
		"getexecutor",
		"getexecutorinfo",
	}) do
		local fn = firstFn({ id })
		if fn then
			local ok, result, version = pcall(fn)
			if ok and type(result) == "string" and result ~= "" then
				if type(version) == "string" and version ~= "" then
					return result .. " " .. version, result, version
				end
				return result, result, nil
			end
		end
	end
	return "", "", nil
end

function ExecutorRuntime.probeCapabilities(entry)
	entry = entry or ExecutorRuntime.REGISTRY.unknown
	local fsBroken = entry.fsBroken == true
	local hasFilesystem = not fsBroken
		and hasFn("writefile")
		and hasFn("readfile")
		and hasFn("isfile")
	local hasHttp = firstFn({ "request", "http_request", "httprequest" }) ~= nil or hasFn("HttpGet") or hasFn("httpget")
	local hasLoadstring = hasFn("loadstring") or hasFn("LoadString") or hasFn("load")
	local hasGetConn = hasFn("getconnections") or hasFn("get_signal_cons")
	local hasClipboard = hasFn("setclipboard")
		or hasFn("toclipboard")
		or (hasTable("Wave") and type(ENV.Wave.setclipboard) == "function")
		or (hasTable("Electron") and type(ENV.Electron.setclipboard) == "function")
	local hasFireTouch = hasFn("firetouchinterest") or hasFn("FireTouchInterest") or hasFn("touchinterest")
	local hasHook = hasFn("hookfunction") or hasFn("hookmetamethod") or hasFn("replaceclosure")
	local hasDrawing = hasFn("Drawing") or hasTable("Drawing")
	local hasCrypt = hasFn("crypt") or hasTable("crypt")
	return {
		fsOk = not fsBroken,
		hasFilesystem = hasFilesystem,
		hasHttp = hasHttp,
		hasLoadstring = hasLoadstring,
		hasGetConn = hasGetConn,
		hasClipboard = hasClipboard,
		hasFireTouch = hasFireTouch,
		hasHook = hasHook,
		hasDrawing = hasDrawing,
		hasCrypt = hasCrypt,
	}
end

function ExecutorRuntime.buildProfile(detected)
	detected = type(detected) == "table" and detected or {}
	local rawName = detected.rawName or ExecutorRuntime.detectRawName()
	local slug = ExecutorRuntime.resolveSlug(rawName, detected.envSlugs)
	if slug == "solora" then
		slug = "solara"
	end
	local entry = ExecutorRuntime.REGISTRY[slug] or ExecutorRuntime.REGISTRY.unknown
	local caps = ExecutorRuntime.probeCapabilities(entry)
	local display = entry.display or (slug:sub(1, 1):upper() .. slug:sub(2))
	if rawName ~= "" and slug == "unknown" then
		display = trim(rawName)
	end
	local sharedEnv = ENV.shared or (typeof(shared) == "table" and shared) or nil
	local solaraLib = sharedEnv and type(sharedEnv.solara) == "table" and sharedEnv.solara or nil
	return {
		slug = slug,
		name = slug,
		displayName = display,
		rawName = rawName,
		isKnown = slug ~= "unknown",
		tier = entry.tier or "standard",
		ui = entry.ui or ExecutorRuntime.REGISTRY.unknown.ui,
		layoutMode = "studio",
		env = ENV,
		solara = solaraLib ~= nil or slug == "solara",
		weao = detected.weao,
		weaoVerified = detected.weaoVerified,
		envSlugs = detected.envSlugs,
	}, caps
end

function ExecutorRuntime.enrichProfile(detected, caps)
	local profile, probed = ExecutorRuntime.buildProfile(detected)
	caps = type(caps) == "table" and caps or probed
	for key, value in pairs(caps) do
		profile[key] = value
	end
	profile.capabilities = caps
	ENV._AlleralExecutorProfile = profile
	return profile
end

function ExecutorRuntime.listSlugs()
	local list = {}
	for slug in pairs(ExecutorRuntime.REGISTRY) do
		if slug ~= "unknown" then
			table.insert(list, slug)
		end
	end
	table.sort(list)
	return list
end

ENV.Alleral_ExecutorRuntime = ExecutorRuntime
if getgenv then
	pcall(function()
		getgenv().Alleral_ExecutorRuntime = ExecutorRuntime
	end)
end

return ExecutorRuntime
