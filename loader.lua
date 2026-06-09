--[[
	Alleral Loader v1.1
	loadstring(game:HttpGet("https://raw.githubusercontent.com/evanbackup1256-ship-it/kick/main/loader.lua"))()
]]
local RepoRoot = "https://raw.githubusercontent.com/evanbackup1256-ship-it/kick/main/"

local Games = {
	[89469502395769] = RepoRoot .. "kick%20a%20lucky%20block.luau",
}

local url = Games[game.PlaceId]
if not url then
	warn("Alleral: unsupported game (" .. game.PlaceId .. ")")
	return
end

local src = game:HttpGet(url)
if not src or src == "" then
	warn("[Alleral] empty response for", url)
	return
end
local fn, err = loadstring(src)
if not fn then
	warn("[Alleral] compile error:", err)
	return
end
fn()
