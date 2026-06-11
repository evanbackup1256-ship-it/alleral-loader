--[[
	Alleral one-time fix — paste in Volt and Execute ONCE.
	Downloads core + loader, saves to workspace, runs Alleral.
	After: loadstring(readfile("loader.luau"))()
]]
local g = (getgenv and getgenv()) or {}
local L = g.loadstring or g.LoadString or loadstring or load
if type(L) ~= "function" then
	return warn("[Alleral] loadstring unavailable")
end

local function fetch(url)
	url = url .. "?t=" .. tostring(tick())
	if type(g.Volt) == "table" and type(g.Volt.request) == "function" then
		local ok, res = pcall(g.Volt.request, { Url = url, Method = "GET" })
		if ok and res then
			return res.Body or res.body
		end
	end
	if type(g.request) == "function" then
		local ok, res = pcall(g.request, { Url = url, Method = "GET" })
		if ok and res then
			return res.Body or res.body
		end
	end
	if type(game.HttpGet) == "function" then
		local ok, body = pcall(game.HttpGet, game, url, true)
		if ok and type(body) == "string" then
			return body
		end
	end
	return nil
end

local base = "https://cdn.jsdelivr.net/gh/evanbackup1256-ship-it/kick@main"
local coreSrc = fetch(base .. "/core/alleral_core.luau")
local writeFile = g.writefile or writefile
local makeFolder = g.makefolder or makefolder

if type(coreSrc) == "string" and coreSrc:find("loadRayfield", 1, true) then
	if type(makeFolder) == "function" then
		pcall(makeFolder, "core")
	end
	if type(writeFile) == "function" then
		pcall(writeFile, "core/alleral_core.luau", coreSrc)
		print("[Alleral] Saved core/alleral_core.luau")
	end
	local coreFn = L(coreSrc, "Alleral/core-rescue")
	if type(coreFn) == "function" then
		coreFn()
	end
else
	warn("[Alleral] Core download failed")
end

local loaderSrc = fetch(base .. "/loader.luau")
if type(loaderSrc) ~= "string" or not loaderSrc:find("Alleral Hub", 1, true) then
	loaderSrc = fetch("https://raw.githubusercontent.com/evanbackup1256-ship-it/kick/main/loader.luau")
end
if type(loaderSrc) ~= "string" or loaderSrc:find("EMBEDDED_CORE = [=", 1, true) then
	return warn("[Alleral] Loader download failed or corrupted — retry")
end
if type(writeFile) == "function" then
	pcall(writeFile, "loader.luau", loaderSrc)
	print("[Alleral] Saved loader.luau")
end

local fn, err = L(loaderSrc, "Alleral/loader")
if type(fn) ~= "function" then
	return warn("[Alleral] Loader compile failed: " .. tostring(err))
end
fn()
