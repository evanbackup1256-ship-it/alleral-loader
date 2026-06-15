local Access = {}
Access.VERSION = "1.1"

local function genv()
	local ok, env = pcall(function()
		return getgenv and getgenv() or getfenv()
	end)
	return ok and env or {}
end

local ENV = genv()

local function trim(value)
	if value == nil then
		return ""
	end
	return tostring(value):match("^%s*(.-)%s*$") or ""
end

local function normalizeSlug(text)
	local key = trim(text):lower()
	key = key:gsub("synapse%s*z", "synapsez")
	key = key:gsub("awp%.?gg?", "volt")
	key = key:gsub("[^a-z0-9]+", "")
	return key
end

local function listHasSlug(list, slug)
	if type(list) ~= "table" then
		return false
	end
	for _, entry in ipairs(list) do
		if normalizeSlug(entry) == slug then
			return true
		end
	end
	return false
end

function Access.getConfig()
	local cfg = ENV.Alleral_OwnerAccess
	if type(cfg) ~= "table" then
		cfg = {}
	end
	cfg.mode = cfg.mode or "public"
	cfg.publicKey = cfg.publicKey or "PUBLIC"
	if cfg.blockUnknownExecutor == nil then
		cfg.blockUnknownExecutor = false
	end
	if cfg.requireLoadstring == nil then
		cfg.requireLoadstring = true
	end
	if cfg.requireHttp == nil then
		cfg.requireHttp = false
	end
	cfg.blockWeaoDetected = cfg.blockWeaoDetected == true
	return cfg
end

function Access.resolveExecutorProfile(options)
	options = type(options) == "table" and options or {}
	if type(options.executor) == "table" then
		return options.executor
	end
	local caps = ENV.Alleral_LoaderCapabilities
	if type(caps) == "table" then
		return {
			slug = caps.executorSlug or caps.executor,
			name = caps.executor or caps.executorSlug,
			hasLoadstring = caps.loadstring ~= false,
			hasHttp = caps.http ~= false,
			weao = caps.weao,
		}
	end
	return { slug = "unknown", name = "unknown" }
end

function Access.checkExecutor(options)
	local cfg = Access.getConfig()
	local profile = Access.resolveExecutorProfile(options)
	local slug = normalizeSlug(profile.slug or profile.name or "unknown")
	if slug == "" then
		slug = "unknown"
	end

	if cfg.blockUnknownExecutor and slug == "unknown" then
		return false, "Unknown executor — use a supported injector"
	end

	if type(cfg.deniedExecutors) == "table" and listHasSlug(cfg.deniedExecutors, slug) then
		return false, "Executor blocked: " .. slug
	end

	if type(cfg.allowedExecutors) == "table" and #cfg.allowedExecutors > 0 and not listHasSlug(cfg.allowedExecutors, slug) then
		local runtime = ENV.Alleral_ExecutorRuntime
		if type(runtime) == "table" and type(runtime.REGISTRY) == "table" and runtime.REGISTRY[slug] then
			-- Known executor from runtime registry — allow even if remote allowlist is stale.
		elseif cfg.blockUnknownExecutor then
			return false, "Executor not supported: " .. slug
		end
	end

	if cfg.requireLoadstring and profile.hasLoadstring == false then
		return false, "Executor missing loadstring"
	end

	if cfg.requireHttp and profile.hasHttp == false then
		return false, "Executor missing HTTP request support"
	end

	if cfg.blockWeaoDetected then
		local weao = profile.weao or (type(ENV.Alleral_LoaderCapabilities) == "table" and ENV.Alleral_LoaderCapabilities.weao)
		if type(weao) == "table" and weao.detected then
			return false, "Executor flagged detected by WEAO"
		end
	end

	return true, slug
end

function Access.grant()
	local cfg = Access.getConfig()
	local key = tostring(cfg.publicKey or "PUBLIC")
	ENV.SCRIPT_KEY = key
	getgenv().SCRIPT_KEY = key
	getgenv().JD_IS_PREMIUM = true
	getgenv().JD_REASON = "Public access"
	ENV.Alleral_AccessSession = {
		mode = cfg.mode,
		key = key,
		grantedAt = os.time(),
		isPremium = true,
	}
	return true, cfg.mode
end

function Access.ensureAccess(options)
	local okExecutor, reason = Access.checkExecutor(options)
	if not okExecutor then
		return false, reason
	end
	return Access.grant()
end

function Access.isPremium()
	return true
end

function Access.mode()
	return Access.getConfig().mode
end

function Access.installBridge()
	ENV.Alleral_Access = Access
	ENV.Alleral_EnsureAccess = function(opts)
		return Access.ensureAccess(opts)
	end
	pcall(function()
		if shared then
			shared.Alleral_Access = Access
		end
	end)
end

Access.installBridge()
return Access
