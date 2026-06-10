--[[
	Alleral Universal Loader
	Detects the current Roblox game and injects the matching script.

	Usage (executor):
		loadstring(readfile("loader.luau"))()

	Or remote:
		loadstring(game:HttpGet("YOUR_LOADER_URL"))()
]]

local LOADER_VERSION = "1.0"

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local function firstExecFunc(...)
	for _, name in ipairs({ ... }) do
		local fn = getfenv()[name] or (getgenv and getgenv()[name])
		if type(fn) == "function" then
			return fn
		end
	end
	return nil
end

local httpRequest = firstExecFunc("http_request", "request") or (syn and syn.request)
local readFile = firstExecFunc("readfile")
local loadStringFn = firstExecFunc("loadstring", "LoadString") or loadstring
local isFile = firstExecFunc("isfile")

local function notify(title, text, duration)
	pcall(function()
		game:GetService("StarterGui"):SetCore("SendNotification", {
			Title = title,
			Text = text,
			Duration = duration or 5,
		})
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
		placeIds = { 89469502395769 },
		universeIds = { 10004244222 },
		scriptFile = "kick a lucky block.luau",
		scriptUrl = "https://raw.githubusercontent.com/evanbackup1256-ship-it/kick/main/kick%20a%20lucky%20block.luau",
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
			local network = shared
				and shared:FindFirstChild("Packages")
				and shared.Packages:FindFirstChild("Network")
			local kickReady = Workspace:FindFirstChild("Areas")
				and Workspace.Areas:FindFirstChild("KickReady")
			return network ~= nil and kickReady ~= nil
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
		return nil, string.format(
			"No supported game detected (PlaceId %s).",
			tostring(placeId)
		)
	end

	if bestScore < 100 and not (bestProfile.validate and bestProfile.validate()) then
		return nil, string.format(
			"%s markers not found in this server.",
			bestProfile.name
		)
	end

	return bestProfile
end

local function fetchScript(profile)
	if readFile and isFile and profile.scriptFile then
		local ok, exists = pcall(isFile, profile.scriptFile)
		if ok and exists then
			local okRead, source = pcall(readFile, profile.scriptFile)
			if okRead and type(source) == "string" and source ~= "" then
				return source, "local:" .. profile.scriptFile
			end
		end
	end

	if not profile.scriptUrl then
		return nil, "No script URL configured for " .. profile.name
	end
	if not httpRequest then
		return nil, "HTTP is not available in this executor"
	end

	local ok, response = pcall(httpRequest, {
		Url = profile.scriptUrl,
		Method = "GET",
	})
	if not ok then
		return nil, "HTTP request failed: " .. tostring(response)
	end

	local status = response.StatusCode or response.status or 0
	local body = response.Body or response.body or ""
	if status == 404 or body == "" then
		return nil, "Script download returned empty (HTTP " .. tostring(status) .. ")"
	end

	return body, profile.scriptUrl
end

local function runScript(source, label)
	if not loadStringFn then
		return false, "loadstring is not available"
	end

	local compiled, compileErr = loadStringFn(source, "Alleral/" .. label)
	if not compiled then
		return false, "Compile failed: " .. tostring(compileErr)
	end

	getgenv().Alleral_Boot = true
	local ok, runErr = pcall(compiled)
	getgenv().Alleral_Boot = nil
	if not ok then
		return false, "Runtime error: " .. tostring(runErr)
	end
	return true
end

local function main()
	if getgenv().Alleral_LoaderRunning then
		warn("[Alleral Loader] Already running")
		return
	end
	getgenv().Alleral_LoaderRunning = true

	local profile, detectErr = detectGame()
	if not profile then
		warn("[Alleral Loader] " .. tostring(detectErr))
		notify("Alleral", tostring(detectErr), 8)
		getgenv().Alleral_LoaderRunning = false
		return
	end

	if profile.preload then
		local ready, preloadErr = profile.preload()
		if not ready then
			warn("[Alleral Loader] Preload failed: " .. tostring(preloadErr))
			notify("Alleral", tostring(preloadErr), 8)
			getgenv().Alleral_LoaderRunning = false
			return
		end
	end

	local source, sourceLabel = fetchScript(profile)
	if not source then
		warn("[Alleral Loader] " .. tostring(sourceLabel))
		notify("Alleral", tostring(sourceLabel), 8)
		getgenv().Alleral_LoaderRunning = false
		return
	end

	print(string.format(
		"[Alleral Loader v%s] Loading %s from %s",
		LOADER_VERSION,
		profile.name,
		sourceLabel
	))

	local ok, runErr = runScript(source, profile.id)
	getgenv().Alleral_LoaderRunning = false

	if not ok then
		warn("[Alleral Loader] " .. tostring(runErr))
		notify("Alleral", tostring(runErr), 8)
		return
	end

	notify("Alleral", profile.name .. " loaded.", 4)
end

main()
