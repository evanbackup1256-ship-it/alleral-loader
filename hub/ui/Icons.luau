local Icons = {
	["layout-dashboard"] = "10723407389",
	["settings"] = "6031280882",
	["users"] = "6034509993",
	["terminal"] = "6034452643",
	["search"] = "6031229326",
	["bell"] = "6031068427",
	["palette"] = "6031280882",
	["sparkles"] = "10723407389",
	["zap"] = "6031225819",
	["shield"] = "6031280882",
	["cloud"] = "6031280882",
	["command"] = "6034452643",
	["sliders"] = "6031280882",
	["toggle-left"] = "6031280882",
	["home"] = "6031280882",
	["gamepad-2"] = "6031280882",
	["cpu"] = "6031280882",
	["activity"] = "6031280882",
	["layers"] = "6031280882",
	["box"] = "6031280882",
	["chevron-down"] = "6031091004",
	["chevron-right"] = "6031094676",
	["x"] = "6031095166",
	["check"] = "6031097225",
	["plus"] = "6031095976",
	["minus"] = "6031095976",
	["info"] = "6031280882",
	["alert-triangle"] = "6031280882",
	["moon"] = "6031280882",
	["sun"] = "6031280882",
}

function Icons.resolve(name)
	if type(name) == "number" then
		return "rbxassetid://" .. tostring(name)
	end
	if type(name) ~= "string" or name == "" then
		return "rbxassetid://10723407389"
	end
	if name:find("rbxassetid") then
		return name
	end
	if name:match("^%d+$") then
		return "rbxassetid://" .. name
	end
	local id = Icons[name:lower()] or Icons["layout-dashboard"]
	return "rbxassetid://" .. id
end

function Icons.image(parent, name, size)
	local img = Instance.new("ImageLabel")
	img.Name = "Icon"
	img.BackgroundTransparency = 1
	img.Image = Icons.resolve(name)
	img.Size = size or UDim2.fromOffset(16, 16)
	img.Parent = parent
	return img
end

return Icons
