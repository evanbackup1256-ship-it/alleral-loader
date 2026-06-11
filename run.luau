-- Alleral — paste in your executor and click Execute. Save to Scripts tab (not autoexec).
local REPO = "evanbackup1256-ship-it/kick"
local BRANCH = "main"
local ENTRY_FILES = { "load.luau", "launch.luau" }
local MIRROR_BASES = {
	"https://cdn.jsdelivr.net/gh/" .. REPO .. "@" .. BRANCH .. "/",
	"https://raw.githubusercontent.com/" .. REPO .. "/" .. BRANCH .. "/",
	"https://github.com/" .. REPO .. "/raw/" .. BRANCH .. "/",
}

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

local loadFn = firstFunc("loadstring", "LoadString", load, loadstring)
local httpRequest = firstFunc("http_request", "request") or (ENV.syn and ENV.syn.request)

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

local function httpGet(url)
	url = cacheBust(url)
	if httpRequest then
		local ok, res = pcall(httpRequest, {
			Url = url,
			Method = "GET",
			Headers = {
				["Cache-Control"] = "no-cache, no-store, must-revalidate",
				["Pragma"] = "no-cache",
			},
		})
		if ok and res then
			local status = res.StatusCode or res.status or 200
			local body = res.Body or res.body
			if status >= 200 and status < 300 and type(body) == "string" and body ~= "" then
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
	return nil
end

local function launchBodyValid(body)
	return type(body) == "string"
		and #body > 10000
		and body:find("EMBEDDED_LOADER", 1, true)
		and not body:find("404: Not Found", 1, true)
		and not body:find("<!DOCTYPE html>", 1, true)
end

local function fetchLaunch()
	for _, base in ipairs(MIRROR_BASES) do
		for _, file in ipairs(ENTRY_FILES) do
			for attempt = 1, 2 do
				local body = httpGet(base .. file)
				if launchBodyValid(body) then
					return body
				end
				if typeof(task) == "table" and type(task.wait) == "function" then
					task.wait(0.25 * attempt)
				end
			end
		end
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
