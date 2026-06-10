local HttpService = game:GetService("HttpService")

local FileSystem = {}
FileSystem.Folder = "Starlight Interface Suite"
FileSystem.FileExtension = ".starlight"
FileSystem.AutoloadConfigPath = nil
FileSystem.AutoloadThemePath = nil

local function hasFileApi()
	return type(writefile) == "function"
end

local function writeFile(path, data)
	local fn = writefile
	if fn then
		return pcall(fn, path, data)
	end
	return false
end

local function readFile(path)
	local fn = readfile
	if fn and isfile and isfile(path) then
		local ok, data = pcall(fn, path)
		return ok and data or nil
	end
	return nil
end

local function makeFolder(path)
	local fn = makefolder
	if not fn or not path or path == "" then
		return
	end
	local parts = string.split(path:gsub("\\", "/"), "/")
	local built = ""
	for _, part in ipairs(parts) do
		if part ~= "" then
			built = built == "" and part or (built .. "/" .. part)
			pcall(fn, built)
		end
	end
end

function FileSystem:BuildFolderTree(fileSettings)
	if not hasFileApi() then
		return
	end
	local root = fileSettings and fileSettings.RootFolder
	local configFolder = fileSettings and fileSettings.ConfigFolder or "configs"
	local base = self.Folder
	if root then
		base = base .. "/" .. root
	end
	makeFolder(self.Folder)
	makeFolder(base)
	makeFolder(base .. "/" .. configFolder)
	makeFolder(base .. "/" .. configFolder .. "/configs")
	makeFolder(base .. "/themes")
	self.AutoloadConfigPath = base .. "/" .. configFolder .. "/configs/"
	self.AutoloadThemePath = base .. "/themes/"
end

function FileSystem:SaveConfig(file, path, library)
	if not hasFileApi() then
		return false
	end
	local payload = {}
	local window = library and library.Window
	for sectionName, section in pairs((window and window.TabSections) or {}) do
		for _, tab in pairs(section.Tabs or {}) do
			for _, groupbox in pairs(tab.Groupboxes or {}) do
				for index, element in pairs(groupbox.Elements or {}) do
					if element.Class and element.Values and not element.IgnoreConfig then
						local data = {}
						if element.Class == "Toggle" or element.Class == "Slider" or element.Class == "Input" then
							data.CurrentValue = element.Values.CurrentValue
						elseif element.Class == "Dropdown" then
							data.CurrentOption = element.Values.CurrentOption or element.Values.CurrentOptions
						elseif element.Class == "ColorPicker" then
							local c = element.Values.CurrentValue
							data.CurrentValue = { c.R, c.G, c.B }
							data.Transparency = element.Values.Transparency
						end
						table.insert(payload, {
							path = sectionName .. "." .. (tab.Index or "") .. "." .. (groupbox.Index or "") .. "." .. tostring(index),
							type = element.Class,
							data = data,
						})
					end
				end
			end
		end
	end
	local target = (path or self.AutoloadConfigPath or "") .. file .. self.FileExtension
	local folder = (path or self.AutoloadConfigPath or ""):gsub("/+$", "")
	if folder ~= "" then
		makeFolder(folder)
	end
	return writeFile(target, HttpService:JSONEncode(payload))
end

function FileSystem:LoadConfig(file, path, library)
	local target = (path or self.AutoloadConfigPath or "") .. file .. self.FileExtension
	local raw = readFile(target)
	if not raw then
		return false
	end
	local ok, decoded = pcall(function()
		return HttpService:JSONDecode(raw)
	end)
	if not ok or type(decoded) ~= "table" then
		return false
	end
	local window = library and library.Window
	for _, entry in ipairs(decoded) do
		local parts = string.split(entry.path or "", ".")
		local section = window and window.TabSections[parts[1]]
		local tab = section and section.Tabs[parts[2]]
		local groupbox = tab and tab.Groupboxes[parts[3]]
		local element = groupbox and groupbox.Elements[parts[4]]
		if element and element.Set and entry.data then
			if entry.type == "ColorPicker" and type(entry.data.CurrentValue) == "table" then
				local c = entry.data.CurrentValue
				entry.data.CurrentValue = Color3.new(c[1], c[2], c[3])
			end
			element:Set(entry.data)
		end
	end
	return true
end

function FileSystem:RefreshConfigList(path)
	local folder = path or self.AutoloadConfigPath
	if not listfiles or not folder then
		return {}
	end
	local ok, files = pcall(listfiles, folder)
	if not ok or type(files) ~= "table" then
		return {}
	end
	local names = {}
	for _, file in ipairs(files) do
		if file:sub(-#self.FileExtension) == self.FileExtension then
			table.insert(names, file:match("([^/\\]+)" .. self.FileExtension:gsub("%.", "%%.") .. "$") or file)
		end
	end
	table.sort(names)
	return names
end

return FileSystem
