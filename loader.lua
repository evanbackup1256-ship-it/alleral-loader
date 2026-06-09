
local function addCache(url) return url .. "?t=" .. tostring(tick()) end
local HUB_URL = addCache("https://raw.githubusercontent.com/evanbackup1256-ship-it/kick/main/hub.luau")

local function SafeGet(url)
	if type(url) ~= "string" or url == "" then
		warn("[Loader] Invalid URL:", url)
		return nil
	end
	local httpReq = syn and syn.request or http_request or request or (http and http.request)
	if httpReq then
		local ok, resp = pcall(httpReq, {Url = url, Method = "GET"})
		if ok and resp and resp.Body and resp.Body ~= "" then
			return resp.Body
		end
	end
	local success, result = pcall(function()
		if type(game.HttpGet) == "function" then return game:HttpGet(url) end
		return nil
	end)
	if not success then
		warn("[Loader] HttpGet failed:", result)
		return nil
	end
	if not result then return nil end
	return result
end

local code = SafeGet(HUB_URL)
if not code then
	warn("[Loader] Failed to fetch Alleral Hub.")
	return
end

local fn, err = loadstring(code)
if not fn then
	warn("[Loader] Failed to compile hub:", err)
	return
end

fn()