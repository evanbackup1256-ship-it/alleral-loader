local ALLERAL_FLUENT_VERSION = 1
local FLUENT_SOURCE_URL = "https://github.com/ActualMasterOogway/Fluent-Renewed/releases/download/v1.0.8/Fluent.luau"
local FLUENT_FALLBACK_URLS = {
	"https://raw.githubusercontent.com/ActualMasterOogway/Fluent-Renewed/main/Fluent.luau",
}

local ENV = (function()
	local ok, env = pcall(function()
		return getgenv and getgenv() or getfenv()
	end)
	return ok and env or {}
end)()

local Fluent = nil
local fluentBooted = false
local configFolder = "Alleral_Configs"

local function deepClone(value, seen)
	if type(value) ~= "table" then return value end
	seen = seen or {}
	if seen[value] then return seen[value] end
	local copy = {}
	seen[value] = copy
	for k, v in pairs(value) do
		copy[deepClone(k, seen)] = deepClone(v, seen)
	end
	return copy
end

local function sanitizeFluentSource(src)
	if type(src) ~= "string" then return src end
	src = src:gsub("table%.freeze%b()", "function(t) return t end")
	src = src:gsub("table%.freeze", "function(t) return t end")
	src = src:gsub("setreadonly%b()", "function(t) return t end")
	src = src:gsub("make_readonly%b()", "function(t) return t end")
	src = src:gsub("set_read_only%b()", "function(t) return t end")
	return src
end

local function createFluentSandbox(baseEnv)
	local sandbox = {}
	local protected = {
		getgenv = true, getfenv = true, setfenv = true,
		getrawmetatable = true, setrawmetatable = true,
	}
	setmetatable(sandbox, {
		__index = function(_, k)
			if protected[k] then return nil end
			local tv = baseEnv[k]
			if tv ~= nil then return tv end
			return rawget(_G, k)
		end,
		__newindex = function(_, k, v)
			rawset(sandbox, k, v)
		end,
	})
	return sandbox
end

local function fetchFluentSource()
	if type(ENV._AlleralFluentBundle) == "string" and #ENV._AlleralFluentBundle > 1000 then
		return ENV._AlleralFluentBundle, "cached bundle"
	end
	if type(ENV._AlleralFluentSource) == "string" and #ENV._AlleralFluentSource > 1000 then
		return ENV._AlleralFluentSource, "loader cache"
	end

	for attempt = 1, 3 do
		local urls = { FLUENT_SOURCE_URL }
		for _, url in ipairs(FLUENT_FALLBACK_URLS) do
			table.insert(urls, url)
		end

		for _, url in ipairs(urls) do
			local bust = "?t=" .. tostring(tick()) .. "&attempt=" .. tostring(attempt)

			if type(game) == "Instance" and type(game.HttpGet) == "function" then
				local ok, body = pcall(game.HttpGet, game, url .. bust, true)
				if ok and type(body) == "string" and #body > 1000 then
					body = body:gsub("^%s+", ""):gsub("%s+$", "")
					if not body:find("<!DOCTYPE", 1, true) and not body:find("<html", 1, true) then
						ENV._AlleralFluentBundle = body
						return body, url
					end
				end
				ok, body = pcall(game.HttpGet, game, url .. bust)
				if ok and type(body) == "string" and #body > 1000 then
					body = body:gsub("^%s+", ""):gsub("%s+$", "")
					if not body:find("<!DOCTYPE", 1, true) and not body:find("<html", 1, true) then
						ENV._AlleralFluentBundle = body
						return body, url
					end
				end
			end

			if type(ENV.Alleral_HTTP) == "table" and type(ENV.Alleral_HTTP.get) == "function" then
				local ok, body = pcall(ENV.Alleral_HTTP.get, url .. bust, 5000)
				if ok and type(body) == "string" and #body > 1000 then
					body = body:gsub("^%s+", ""):gsub("%s+$", "")
					if not body:find("<!DOCTYPE", 1, true) and not body:find("<html", 1, true) then
						ENV._AlleralFluentBundle = body
						return body, url
					end
				end
			end
		end

		if attempt < 3 then task.wait(0.5 * attempt) end
	end

	return nil
end

local function bootFluent()
	if fluentBooted and Fluent then
		return Fluent
	end

	local loadStringFn = ENV.loadstring or loadstring or load
	if type(loadStringFn) ~= "function" then
		return nil, "loadstring not available"
	end

	local src, sourceLabel = fetchFluentSource()
	if type(src) ~= "string" or #src <= 100 then
		return nil, "Fluent source download empty (HTTP blocked or URLs unreachable)"
	end

	src = sanitizeFluentSource(src)

	local chunk, err = loadStringFn(src, "@Fluent/source")
	if type(chunk) ~= "function" then
		if type(load) == "function" then
			chunk, err = load(src, "@Fluent/source")
		end
		if type(chunk) ~= "function" then
			return nil, "Fluent compile failed: " .. tostring(err)
		end
	end

	local sandbox = createFluentSandbox(ENV)
	sandbox.game = sandbox.game or game
	sandbox.loadstring = loadStringFn
	if type(task) == "table" then
		sandbox.task = task
		sandbox.task.spawn = sandbox.task.spawn or function(f) coroutine.wrap(f)() end
		sandbox.task.delay = sandbox.task.delay or function(t, f) sandbox.task.spawn(function() task.wait(t); f() end) end
		sandbox.task.wait = sandbox.task.wait or task.wait
		sandbox.task.cancel = sandbox.task.cancel or function() end
	end

	if setfenv then pcall(setfenv, chunk, sandbox) end

	local ok, pkg = pcall(chunk)
	if not ok then
		ENV._AlleralFluentBundle = nil
		warn("[Alleral Fluent Error] Runtime: " .. tostring(pkg))
		warn("[Alleral Fluent Error] " .. tostring(debug.traceback()))
		return nil, "Fluent runtime failed: " .. tostring(pkg)
	end

	if type(pkg) ~= "table" then
		return nil, "Fluent returned non-table: " .. type(pkg)
	end

	if type(pkg.CreateWindow) ~= "function" then
		return nil, "Fluent missing CreateWindow"
	end

	Fluent = pkg
	fluentBooted = true
	ENV._AlleralFluent = pkg
	return Fluent
end

return {
	Version = ALLERAL_FLUENT_VERSION,
	boot = bootFluent,
	get = function() return bootFluent() end,
	isBooted = function() return fluentBooted end,
	setConfigFolder = function(f) configFolder = f or configFolder end,
	getConfigFolder = function() return configFolder end,
	getLayoutInfo = function()
		return { profile = "fluent", engine = "Fluent", version = tostring(ALLERAL_FLUENT_VERSION) }
	end,
}
