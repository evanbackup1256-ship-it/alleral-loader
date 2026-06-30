-- Back-compat redirect — forwards to root bootstrap.luau (thin entry, merged gate in loader.luau)
local REPO = "evanbackup1256-ship-it/alleral-loader"
local MERGED_URLS = {
	"https://raw.githubusercontent.com/" .. REPO .. "/main/bootstrap.luau",
	"https://alleral-telemetry-production.up.railway.app/api/loader/file/bootstrap.luau",
	"https://cdn.jsdelivr.net/gh/" .. REPO .. "@main/bootstrap.luau",
}

local function genv()
	local ok, env = pcall(function()
		return getgenv and getgenv() or getfenv()
	end)
	return ok and env or {}
end

local ENV = genv()

local function pickRequest()
	for _, name in ipairs({ "request", "http_request", "httprequest", "syn_request" }) do
		local fn = ENV[name] or (_G and _G[name])
		if type(fn) == "function" then
			return fn
		end
	end
	if type(syn) == "table" and type(syn.request) == "function" then
		return syn.request
	end
	if type(http) == "table" and type(http.request) == "function" then
		return http.request
	end
	return nil
end

local function fetchMerged()
	local requestFn = pickRequest()
	for _, baseUrl in ipairs(MERGED_URLS) do
		local url = baseUrl .. (baseUrl:find("?") and "&" or "?") .. "t=" .. tostring(tick())
		if requestFn then
			local ok, body = pcall(function()
				local res = requestFn({ Url = url, Method = "GET", Headers = { ["Cache-Control"] = "no-cache" } })
				if type(res) == "table" then
					return res.Body or res.body
				end
				return type(res) == "string" and res or nil
			end)
			if ok and type(body) == "string" and body:find("BOOTSTRAP_VERSION", 1, true) then
				return body
			end
		end
		if typeof(game) == "Instance" and type(game.HttpGet) == "function" then
			local ok, body = pcall(game.HttpGet, game, url, true)
			if ok and type(body) == "string" and body:find("BOOTSTRAP_VERSION", 1, true) then
				return body
			end
		end
	end
	return nil
end

local src = fetchMerged()
if not src then
	error("[Alleral] Could not fetch bootstrap.luau")
end

local loadFn = ENV.loadstring or ENV.LoadString or loadstring or load
if type(loadFn) ~= "function" then
	error("[Alleral] loadstring unavailable")
end

local chunk = loadFn(src, "@Alleral/bootstrap")
if type(chunk) ~= "function" then
	error("[Alleral] Bootstrap compile failed")
end
if setfenv then
	pcall(setfenv, chunk, ENV)
end

local ok, err = pcall(chunk)
if not ok then
	error("[Alleral] " .. tostring(err))
end