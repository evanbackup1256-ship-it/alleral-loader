-- Alleral — paste in your executor and click Execute. Save to Scripts tab (not autoexec).
local REPO = "evanbackup1256-ship-it/kick"
local BRANCH = "main"
local ENTRY_FILES = { "loader.luau", "load.luau", "launch.luau" }
local MIRROR_BASES = {
	"https://raw.githubusercontent.com/" .. REPO .. "/" .. BRANCH .. "/",
	"https://cdn.jsdelivr.net/gh/" .. REPO .. "@" .. BRANCH .. "/",
	"https://github.com/" .. REPO .. "/raw/" .. BRANCH .. "/",
}

local HttpService = nil
pcall(function()
	HttpService = game:GetService("HttpService")
end)

local function genv()
	local ok, env = pcall(function()
		return (getgenv and getgenv()) or getfenv(0)
	end)
	return ok and env or _G
end

local ENV = genv()

local function firstFunc(...)
	for i = 1, select("#", ...) do
		local candidate = select(i, ...)
		if type(candidate) == "function" then
			return candidate
		end
		if type(candidate) == "string" then
			local fn = ENV[candidate] or _G[candidate]
			if type(fn) == "function" then
				return fn
			end
		end
	end
	return nil
end

local function resolveRequest()
	local candidates = {
		ENV.Volt and ENV.Volt.request,
		ENV.Wave and ENV.Wave.request,
		ENV.Solara and ENV.Solara.request,
		ENV.Xeno and ENV.Xeno.request,
		ENV.Krnl and ENV.Krnl.request,
		ENV.syn and ENV.syn.request,
		ENV.http and ENV.http.request,
		firstFunc("http_request", "request", "Request", "httprequest"),
	}
	for _, fn in ipairs(candidates) do
		if type(fn) == "function" then
			return fn
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

local loadFn = firstFunc("loadstring", "LoadString", load, loadstring)
local httpRequest = resolveRequest()

local function notify(title, text, duration)
	pcall(function()
		game:GetService("StarterGui"):SetCore("SendNotification", {
			Title = title,
			Text = text,
			Duration = duration or 6,
		})
	end)
end

local function cacheBust(url)
	local nonce = typeof(tick) == "function" and tick() or math.random()
	return url .. (url:find("?", 1, true) and "&" or "?") .. "t=" .. tostring(nonce) .. "&r=" .. tostring(math.random(100000, 999999))
end

local function extractBody(response)
	if type(response) == "string" and response ~= "" then
		return response
	end
	if type(response) == "table" then
		local body = response.Body or response.body or response.Data or response.data
		if type(body) == "string" and body ~= "" then
			return body
		end
	end
	return nil
end

local function responseOk(response, body)
	if type(body) ~= "string" or body == "" then
		return false
	end
	if type(response) == "table" then
		local status = response.StatusCode or response.status or response.Status or 200
		if type(status) == "number" and (status < 200 or status >= 300) then
			return false
		end
	end
	return true
end

local function httpGet(url)
	url = cacheBust(url)
	local headers = {
		["Cache-Control"] = "no-cache, no-store, must-revalidate",
		["Pragma"] = "no-cache",
		["Accept"] = "text/plain, application/json, */*",
	}

	if httpRequest then
		for _, spec in ipairs({
			{ Url = url, Method = "GET", Headers = headers },
			{ url = url, method = "GET", headers = headers },
		}) do
			local ok, res = pcall(httpRequest, spec)
			local body = ok and extractBody(res)
			if body and responseOk(res, body) then
				return body
			end
		end
	end

	if type(game.HttpGet) == "function" then
		local ok, body = pcall(game.HttpGet, game, url, true)
		if ok and type(body) == "string" and body ~= "" then
			return body
		end
		ok, body = pcall(game.HttpGet, game, url)
		if ok and type(body) == "string" and body ~= "" then
			return body
		end
	end

	local ok, body = pcall(function()
		return game:HttpGet(url, true)
	end)
	if ok and type(body) == "string" and body ~= "" then
		return body
	end

	ok, body = pcall(function()
		return game:HttpGet(url)
	end)
	if ok and type(body) == "string" and body ~= "" then
		return body
	end

	if HttpService and type(HttpService.GetAsync) == "function" then
		ok, body = pcall(function()
			return HttpService:GetAsync(url, true)
		end)
		if ok and type(body) == "string" and body ~= "" then
			return body
		end
	end

	return nil
end

local function entryBodyValid(body)
	if type(body) ~= "string" or #body < 1000 then
		return false
	end
	if body:find("404: Not Found", 1, true) then
		return false
	end
	if body:find("<!DOCTYPE html>", 1, true) and not body:find("LOADER_VERSION", 1, true) then
		return false
	end
	if body:find("EMBEDDED_LOADER", 1, true) and #body > 10000 then
		return true
	end
	if body:find('LOADER_VERSION%s*=%s*"[%d%.]+"', 1) and body:find("loadRayfield", 1, true) then
		return true
	end
	if body:find("bootstrapViaLaunch", 1, true) and body:find("Alleral", 1, true) then
		return true
	end
	return false
end

local function fetchLaunch()
	local lastSize = 0
	for _, base in ipairs(MIRROR_BASES) do
		for _, file in ipairs(ENTRY_FILES) do
			for attempt = 1, 3 do
				local body = httpGet(base .. file)
				if type(body) == "string" then
					lastSize = math.max(lastSize, #body)
				end
				if entryBodyValid(body) then
					return body
				end
				if typeof(task) == "table" and type(task.wait) == "function" then
					task.wait(0.3 * attempt)
				end
			end
		end
	end
	if lastSize > 0 then
		warn("[Alleral] Downloaded " .. tostring(lastSize) .. " bytes but payload failed validation.")
	else
		warn("[Alleral] HTTP unavailable — enable HttpService in your executor.")
	end
	return nil
end

local function Alleral_Load()
	if type(ENV.Alleral_Load) == "function" and ENV.Alleral_Load ~= Alleral_Load then
		return ENV.Alleral_Load()
	end

	if type(loadFn) ~= "function" then
		notify("Alleral", "Executor needs loadstring")
		warn("[Alleral] This executor needs loadstring.")
		return false
	end

	_G.__Alleral_LaunchHandled = nil
	if type(ENV) == "table" then
		ENV.Alleral_LoaderRunning = nil
		ENV._Alleral_AutoRecoveryAttempted = nil
	end

	local source = fetchLaunch()
	if type(source) ~= "string" then
		notify("Alleral", "Download failed — try again")
		warn("[Alleral] Could not download Alleral from any mirror.")
		return false
	end

	local fn, compileErr = loadFn(source, "Alleral/load")
	if type(fn) ~= "function" then
		notify("Alleral", "Failed to compile — try again")
		warn("[Alleral] Launch failed to compile" .. (compileErr and (": " .. tostring(compileErr)) or "."))
		return false
	end

	local ok, runErr = pcall(fn)
	if not ok then
		notify("Alleral", "Startup error — run Alleral_Load() again")
		warn("[Alleral] " .. tostring(runErr))
		return false
	end
	return true
end

ENV.Alleral_Load = Alleral_Load
Alleral_Load()
