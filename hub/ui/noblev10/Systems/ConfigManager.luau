-- Alleral Noble V10 — config persistence hooks (premium config page support)
return function(deps)
	local HttpService = game:GetService("HttpService")
	local ConfigManager = {}
	ConfigManager.__index = ConfigManager

	function ConfigManager.new(options)
		options = type(options) == "table" and options or {}
		return setmetatable({
			folder = options.folder or "Alleral_Configs",
			fileName = options.fileName or "Interface",
		}, ConfigManager)
	end

	function ConfigManager:getPath()
		return self.folder .. "/" .. self.fileName .. ".json"
	end

	function ConfigManager:save(data)
		data = type(data) == "table" and data or {}
		local ok, encoded = pcall(function()
			return HttpService:JSONEncode(data)
		end)
		if not ok or not encoded then return false end
		if writefile then
			pcall(writefile, self:getPath(), encoded)
			return true
		end
		return false
	end

	function ConfigManager:load()
		if not readfile or not isfile then return {} end
		local path = self:getPath()
		local ok, exists = pcall(isfile, path)
		if not ok or not exists then return {} end
		local rok, raw = pcall(readfile, path)
		if not rok or type(raw) ~= "string" then return {} end
		local dok, data = pcall(function()
			return HttpService:JSONDecode(raw)
		end)
		return dok and type(data) == "table" and data or {}
	end

	return ConfigManager
end