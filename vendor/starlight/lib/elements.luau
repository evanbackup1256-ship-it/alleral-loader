local UserInputService = game:GetService("UserInputService")
local Util = require(script.Parent.util)
local Theme = require(script.Parent.theme)
local Tween = require(script.Parent.tween)

local Elements = {}

function Elements.makeTooltip(text, parent, theme)
	if Util.isEmpty(text) then
		return { Text = "" }
	end
	local tip = Util.new("TextLabel", {
		Name = "Tooltip",
		BackgroundColor3 = theme.Backgrounds.Highlight,
		BackgroundTransparency = 0.1,
		TextColor3 = theme.Foregrounds.Light,
		Font = Enum.Font.Gotham,
		TextSize = 12,
		Text = text,
		TextWrapped = true,
		Size = UDim2.fromOffset(180, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		Visible = false,
		ZIndex = 100,
	}, { parent })
	Util.corner(6, tip)
	Util.padding(6, 8, 6, 8, tip)
	return tip
end

function Elements.runCallback(windowSettings, label, callback, library)
	local ok, err = pcall(callback)
	if not ok and windowSettings.NotifyOnCallbackError ~= false then
		warn("[Starlight] Callback error:", err)
		if library and library.Notification then
			library:Notification({
				Title = label .. " Error",
				Content = tostring(err),
				Icon = 6031075938,
			})
		end
	end
	return ok, err
end

function Elements.createRow(parent, settings, theme)
	local height = Theme.Visual.CompactMode and 34 or 38
	local row = Util.new("Frame", {
		Name = settings.Name or "Row",
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, height),
		LayoutOrder = settings.LayoutOrder or 0,
	}, { parent })

	local label = Util.text({
		Parent = row,
		Text = settings.Name or "",
		TextSize = 14 * Theme.Visual.FontScale,
		TextColor3 = theme.Foregrounds.Light,
		Size = UDim2.new(1, -120, 1, 0),
	})
	label.Name = "Header"

	if not Util.isEmpty(settings.Icon) then
		local icon = Util.new("ImageLabel", {
			BackgroundTransparency = 1,
			Image = Util.iconAsset(settings.Icon),
			Size = UDim2.fromOffset(16, 16),
			Position = UDim2.fromOffset(0, 10),
			ImageColor3 = theme.Accent,
		}, { row })
		label.Position = UDim2.fromOffset(22, 0)
		label.Size = UDim2.new(1, -142, 1, 0)
	end

	local slot = Util.new("Frame", {
		Name = "ElementContainer",
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, 0, 0.5, 0),
		Size = UDim2.fromOffset(110, 24),
	}, { row })

	local dropdownHolder = Util.new("Frame", {
		Name = "DropdownHolder",
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 0, 1, 4),
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		Visible = true,
	}, { row })
	Util.list(6, false, dropdownHolder)

	return row, label, slot, dropdownHolder
end

function Elements.createToggle(groupbox, settings, index, windowSettings, library)
	local theme = Theme.current()
	local element = {
		Class = "Toggle",
		Values = settings,
		NestedElements = {},
	}
	settings.CurrentValue = settings.CurrentValue == true

	local row, label, slot = Elements.createRow(groupbox.ParentingItem, settings, theme)
	element.Instance = row

	local track = Util.new("Frame", {
		BackgroundColor3 = theme.Backgrounds.Highlight,
		Size = UDim2.fromOffset(44, 24),
	}, { slot })
	Util.corner(999, track)

	local knob = Util.new("Frame", {
		BackgroundColor3 = theme.Foregrounds.Medium,
		Size = UDim2.fromOffset(18, 18),
		Position = UDim2.fromOffset(3, 3),
	}, { track })
	Util.corner(999, knob)

	local function paint(on)
		Tween.play(track, {
			BackgroundColor3 = on and theme.Accent or theme.Backgrounds.Highlight,
		}, nil, Theme.tweenInfo(0.15))
		Tween.play(knob, {
			BackgroundColor3 = on and theme.Foregrounds.Active or theme.Foregrounds.Medium,
			Position = on and UDim2.fromOffset(23, 3) or UDim2.fromOffset(3, 3),
		}, nil, Theme.tweenInfo(0.15))
	end
	paint(settings.CurrentValue)

	local button = Util.button({
		Parent = row,
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundTransparency = 1,
		Radius = 0,
	})
	button.ZIndex = 5
	button.MouseButton1Click:Connect(function()
		settings.CurrentValue = not settings.CurrentValue
		paint(settings.CurrentValue)
		Elements.runCallback(windowSettings, settings.Name or "Toggle", function()
			settings.Callback(settings.CurrentValue)
		end)
	end)

	function element:Set(newSettings)
		for key, value in pairs(element.Values) do
			newSettings[key] = newSettings[key] ~= nil and newSettings[key] or value
		end
		element.Values = newSettings
		settings = newSettings
		label.Text = settings.Name or label.Text
		paint(settings.CurrentValue == true)
	end

	function element:Destroy()
		row:Destroy()
	end

	groupbox.Elements[index] = element
	return element
end

function Elements.createSlider(groupbox, settings, index, windowSettings)
	local theme = Theme.current()
	local element = { Class = "Slider", Values = settings, NestedElements = {} }
	local minValue = settings.Range and settings.Range[1] or 0
	local maxValue = settings.Range and settings.Range[2] or 100
	local increment = settings.Increment or 1
	settings.CurrentValue = Util.clamp(settings.CurrentValue or minValue, minValue, maxValue)

	local row, label, slot = Elements.createRow(groupbox.ParentingItem, settings, theme)
	element.Instance = row
	slot.Size = UDim2.fromOffset(140, 24)

	local bar = Util.new("Frame", {
		BackgroundColor3 = theme.Backgrounds.Highlight,
		Size = UDim2.new(1, -36, 0, 6),
		Position = UDim2.new(0, 0, 0.5, -3),
	}, { slot })
	Util.corner(999, bar)

	local fill = Util.new("Frame", {
		BackgroundColor3 = theme.Accent,
		Size = UDim2.new(0, 0, 1, 0),
	}, { bar })
	Util.corner(999, fill)

	local valueLabel = Util.text({
		Parent = slot,
		Text = tostring(settings.CurrentValue),
		TextXAlignment = Enum.TextXAlignment.Right,
		TextSize = 12 * Theme.Visual.FontScale,
		TextColor3 = theme.Foregrounds.Medium,
		Size = UDim2.fromOffset(32, 24),
		Position = UDim2.new(1, -32, 0, 0),
	})

	local dragging = false
	local function setValue(raw, fire)
		local stepped = minValue + math.floor(((raw - minValue) / increment) + 0.5) * increment
		settings.CurrentValue = Util.clamp(stepped, minValue, maxValue)
		local alpha = (settings.CurrentValue - minValue) / math.max(maxValue - minValue, 1)
		fill.Size = UDim2.new(alpha, 0, 1, 0)
		valueLabel.Text = tostring(settings.CurrentValue)
		if fire then
			Elements.runCallback(windowSettings, settings.Name or "Slider", function()
				settings.Callback(settings.CurrentValue)
			end)
		end
	end
	setValue(settings.CurrentValue, false)

	local hit = Util.button({ Parent = bar, Size = UDim2.fromScale(1, 3), Position = UDim2.fromScale(0, -1), BackgroundTransparency = 1, Radius = 999 })
	hit.MouseButton1Down:Connect(function()
		dragging = true
	end)
	UserInputService.InputEnded:Connect(function(input)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) then
			dragging = false
		end
	end)
	bar.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			local rel = Util.clamp((input.Position.X - bar.AbsolutePosition.X) / math.max(bar.AbsoluteSize.X, 1), 0, 1)
			setValue(minValue + (maxValue - minValue) * rel, true)
		end
	end)

	function element:Set(newSettings)
		for key, value in pairs(element.Values) do
			newSettings[key] = newSettings[key] ~= nil and newSettings[key] or value
		end
		element.Values = newSettings
		settings = newSettings
		label.Text = settings.Name or label.Text
		setValue(settings.CurrentValue, false)
	end

	function element:Destroy()
		row:Destroy()
	end

	groupbox.Elements[index] = element
	return element
end

function Elements.createButton(groupbox, settings, index, windowSettings)
	local theme = Theme.current()
	local element = { Class = "Button", Values = settings, NestedElements = {} }
	local row = Util.button({
		Parent = groupbox.ParentingItem,
		BackgroundColor3 = theme.Backgrounds.Highlight,
		Size = UDim2.new(1, 0, 0, Theme.Visual.CompactMode and 32 or 36),
		Radius = Theme.Visual.CornerRadius - 2,
	})
	element.Instance = row
	Util.text({
		Parent = row,
		Text = settings.Name or "Button",
		TextXAlignment = Enum.TextXAlignment.Center,
		TextSize = 14 * Theme.Visual.FontScale,
		TextColor3 = theme.Foregrounds.Light,
		Size = UDim2.fromScale(1, 1),
	})
	row.MouseEnter:Connect(function()
		Tween.play(row, { BackgroundColor3 = theme.AccentSoft }, nil, Theme.tweenInfo(0.12))
	end)
	row.MouseLeave:Connect(function()
		Tween.play(row, { BackgroundColor3 = theme.Backgrounds.Highlight }, nil, Theme.tweenInfo(0.12))
	end)
	row.MouseButton1Click:Connect(function()
		Elements.runCallback(windowSettings, settings.Name or "Button", settings.Callback or function() end)
	end)

	function element:Set(newSettings)
		element.Values = Util.merge(element.Values, newSettings)
		row:FindFirstChildOfClass("TextLabel").Text = element.Values.Name or "Button"
	end
	function element:Destroy()
		row:Destroy()
	end
	groupbox.Elements[index] = element
	return element
end

function Elements.createInput(groupbox, settings, index, windowSettings)
	local theme = Theme.current()
	local element = { Class = "Input", Values = settings, NestedElements = {} }
	settings.CurrentValue = settings.CurrentValue or settings.Placeholder or ""

	local row, label, slot = Elements.createRow(groupbox.ParentingItem, settings, theme)
	element.Instance = row
	slot.Size = UDim2.fromOffset(150, 28)

	local box = Util.new("TextBox", {
		BackgroundColor3 = theme.Backgrounds.Highlight,
		BorderSizePixel = 0,
		ClearTextOnFocus = settings.RemoveTextOnFocus == true,
		Font = Enum.Font.Gotham,
		PlaceholderText = settings.PlaceholderText or settings.Placeholder or "",
		Text = settings.CurrentValue,
		TextColor3 = theme.Foregrounds.Light,
		TextSize = 13 * Theme.Visual.FontScale,
		Size = UDim2.fromScale(1, 1),
	}, { slot })
	Util.corner(8, box)
	Util.padding(0, 8, 0, 8, box)

	box.FocusLost:Connect(function()
		settings.CurrentValue = box.Text
		Elements.runCallback(windowSettings, settings.Name or "Input", function()
			if settings.Callback then
				settings.Callback(settings.CurrentValue)
			end
		end)
	end)

	function element:Set(newSettings)
		element.Values = Util.merge(element.Values, newSettings)
		label.Text = element.Values.Name or label.Text
		if newSettings.CurrentValue ~= nil then
			box.Text = newSettings.CurrentValue
		end
	end
	function element:Destroy()
		row:Destroy()
	end
	groupbox.Elements[index] = element
	return element
end

function Elements.createLabel(groupbox, settings, index, windowSettings)
	local theme = Theme.current()
	local element = { Class = "Label", Values = settings, NestedElements = {} }
	local row, label, slot, dropdownHolder = Elements.createRow(groupbox.ParentingItem, settings, theme)
	element.Instance = row
	slot:Destroy()

	function element:Set(newSettings)
		element.Values = Util.merge(element.Values, newSettings)
		label.Text = element.Values.Name or ""
	end
	function element:Destroy()
		row:Destroy()
	end
	function element:AddDropdown(nestedSettings, nestedIndex)
		return Elements.createDropdown(groupbox, nestedSettings, nestedIndex or #element.NestedElements + 1, windowSettings, element, dropdownHolder)
	end
	function element:AddBind(nestedSettings, nestedIndex)
		return Elements.createBind(groupbox, nestedSettings, nestedIndex or #element.NestedElements + 1, windowSettings, element, slot)
	end
	function element:AddColorPicker(nestedSettings, nestedIndex)
		return Elements.createColorPicker(groupbox, nestedSettings, nestedIndex or #element.NestedElements + 1, windowSettings, element, slot)
	end

	groupbox.Elements[index] = element
	return element
end

function Elements.createDivider(groupbox)
	local theme = Theme.current()
	local line = Util.new("Frame", {
		BackgroundColor3 = theme.Miscellaneous.Divider,
		BackgroundTransparency = 0.35,
		BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 0, 1),
	}, { groupbox.ParentingItem })
	return { Class = "Divider", Instance = line, Destroy = function()
		line:Destroy()
	end }
end

function Elements.createParagraph(groupbox, settings, index)
	local theme = Theme.current()
	local element = { Class = "Paragraph", Values = settings, NestedElements = {} }
	local frame = Util.new("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
	}, { groupbox.ParentingItem })
	Util.list(4, false, frame)
	Util.text({
		Parent = frame,
		Text = settings.Name or settings.Title or "",
		Font = Enum.Font.GothamBold,
		TextSize = 15 * Theme.Visual.FontScale,
		TextColor3 = theme.Foregrounds.Light,
	})
	Util.text({
		Parent = frame,
		Text = settings.Content or settings.Description or "",
		TextWrapped = true,
		TextSize = 13 * Theme.Visual.FontScale,
		TextColor3 = theme.Foregrounds.Medium,
		Size = UDim2.new(1, 0, 0, 0),
	}).AutomaticSize = Enum.AutomaticSize.Y
	element.Instance = frame
	function element:Set(newSettings)
		element.Values = Util.merge(element.Values, newSettings)
	end
	function element:Destroy()
		frame:Destroy()
	end
	groupbox.Elements[index] = element
	return element
end

function Elements.createDropdown(groupbox, settings, index, windowSettings, parentElement, holderOverride)
	local theme = Theme.current()
	local element = { Class = "Dropdown", Values = settings, NestedElements = {} }
	settings.Options = settings.Options or settings.Values or {}
	settings.Multi = settings.Multi == true or settings.MultiSelection == true
	if settings.Multi then
		settings.CurrentOptions = settings.CurrentOptions or settings.CurrentOption or settings.Default or {}
		if type(settings.CurrentOptions) ~= "table" then
			settings.CurrentOptions = { settings.CurrentOptions }
		end
	else
		settings.CurrentOption = settings.CurrentOption or settings.Default or settings.Options[1] or ""
	end

	local parentFrame = holderOverride
	if not parentFrame then
		local row, label, slot = Elements.createRow(groupbox.ParentingItem, settings, theme)
		element.Instance = row
		parentFrame = slot
		parentFrame.Size = UDim2.fromOffset(150, 28)
	else
		local wrapper = Util.new("Frame", {
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 0, 32),
		}, { holderOverride })
		parentFrame = wrapper
		element.Instance = wrapper
	end

	local closed = Util.button({
		Parent = parentFrame,
		BackgroundColor3 = theme.Backgrounds.Highlight,
		Size = UDim2.fromScale(1, 1),
		Radius = 8,
	})
	local valueText = Util.text({
		Parent = closed,
		Text = "",
		TextSize = 13 * Theme.Visual.FontScale,
		TextColor3 = theme.Foregrounds.Light,
		Size = UDim2.new(1, -24, 1, 0),
	})
	Util.padding(0, 10, 0, 10, closed)

	local popup = Util.new("ScrollingFrame", {
		BackgroundColor3 = theme.Backgrounds.Elevated,
		BorderSizePixel = 0,
		Size = UDim2.fromOffset(parentFrame.AbsoluteSize.X > 0 and parentFrame.AbsoluteSize.X or 180, 160),
		Position = UDim2.fromOffset(0, 34),
		Visible = false,
		CanvasSize = UDim2.new(),
		ScrollBarThickness = 4,
		ZIndex = 50,
	}, { parentFrame })
	Util.corner(8, popup)
	Util.list(2, false, popup)
	Util.stroke(theme.Miscellaneous.Divider, 1, 0.4, popup)

	local function displayValue()
		if settings.Multi then
			valueText.Text = #settings.CurrentOptions == 0 and "None" or table.concat(settings.CurrentOptions, ", ")
		else
			valueText.Text = tostring(settings.CurrentOption or "")
		end
	end

	local function rebuildOptions(filtered)
		for _, child in ipairs(popup:GetChildren()) do
			if child:IsA("GuiObject") and child.Name == "Option" then
				child:Destroy()
			end
		end
		local options = filtered or settings.Options
		for i, option in ipairs(options) do
			local opt = Util.button({
				Name = "Option",
				Parent = popup,
				BackgroundColor3 = theme.Backgrounds.Light,
				Size = UDim2.new(1, -8, 0, 28),
				Radius = 6,
			})
			opt.LayoutOrder = i
			Util.text({
				Parent = opt,
				Text = tostring(option),
				TextSize = 13 * Theme.Visual.FontScale,
				TextColor3 = theme.Foregrounds.Light,
				Size = UDim2.fromScale(1, 1),
			})
			opt.MouseButton1Click:Connect(function()
				if settings.Multi then
					local found = table.find(settings.CurrentOptions, option)
					if found then
						table.remove(settings.CurrentOptions, found)
					else
						table.insert(settings.CurrentOptions, option)
					end
					Elements.runCallback(windowSettings, settings.Name or "Dropdown", function()
						settings.Callback(settings.CurrentOptions)
					end)
				else
					settings.CurrentOption = option
					popup.Visible = false
					Elements.runCallback(windowSettings, settings.Name or "Dropdown", function()
						settings.Callback(option)
					end)
				end
				displayValue()
			end)
		end
		popup.CanvasSize = UDim2.new(0, 0, 0, #options * 30)
	end

	displayValue()
	rebuildOptions()

	closed.MouseButton1Click:Connect(function()
		popup.Visible = not popup.Visible
		if popup.Visible then
			popup.Size = UDim2.fromOffset(closed.AbsoluteSize.X, 160)
		end
	end)

	function element:Set(newSettings)
		element.Values = Util.merge(element.Values, newSettings)
		settings = element.Values
		if newSettings.Options or newSettings.Values then
			settings.Options = newSettings.Options or newSettings.Values
		end
		if newSettings.CurrentOption ~= nil then
			settings.CurrentOption = newSettings.CurrentOption
		end
		if newSettings.CurrentOptions ~= nil then
			settings.CurrentOptions = newSettings.CurrentOptions
		end
		label = label
		displayValue()
		rebuildOptions()
	end
	function element:Destroy()
		if element.Instance then
			element.Instance:Destroy()
		end
	end

	if parentElement then
		parentElement.NestedElements[index] = element
	else
		groupbox.Elements[index] = element
	end
	return element
end

function Elements.createBind(groupbox, settings, index, windowSettings, parentElement, slot)
	local theme = Theme.current()
	local element = { Class = "Bind", Values = settings, NestedElements = {} }
	settings.CurrentValue = settings.CurrentValue or "No Bind"
	local bindButton = Util.button({
		Parent = slot or groupbox.ParentingItem,
		Size = UDim2.fromOffset(80, 24),
		Radius = 6,
	})
	element.Instance = bindButton
	Util.text({
		Parent = bindButton,
		Text = tostring(settings.CurrentValue),
		TextXAlignment = Enum.TextXAlignment.Center,
		TextSize = 12,
		TextColor3 = theme.Foregrounds.Medium,
		Size = UDim2.fromScale(1, 1),
	})
	local listening = false
	bindButton.MouseButton1Click:Connect(function()
		listening = true
		bindButton:FindFirstChildOfClass("TextLabel").Text = "..."
	end)
	UserInputService.InputBegan:Connect(function(input, processed)
		if not listening or processed then
			return
		end
		if input.UserInputType == Enum.UserInputType.Keyboard then
			settings.CurrentValue = input.KeyCode.Name
			listening = false
			bindButton:FindFirstChildOfClass("TextLabel").Text = settings.CurrentValue
			if settings.OnChangedCallback then
				settings.OnChangedCallback(settings.CurrentValue)
			end
		end
	end)
	parentElement.NestedElements[index] = element
	return element
end

function Elements.createColorPicker(groupbox, settings, index, windowSettings, parentElement, slot)
	local theme = Theme.current()
	local element = { Class = "ColorPicker", Values = settings, NestedElements = {} }
	settings.CurrentValue = settings.CurrentValue or Color3.fromRGB(255, 255, 255)
	settings.Transparency = settings.Transparency or 0
	local swatch = Util.new("TextButton", {
		AutoButtonColor = false,
		BackgroundColor3 = settings.CurrentValue,
		BackgroundTransparency = settings.Transparency,
		BorderSizePixel = 0,
		Size = UDim2.fromOffset(24, 24),
		Text = "",
	}, { slot or groupbox.ParentingItem })
	Util.corner(6, swatch)
	element.Instance = swatch
	swatch.MouseButton1Click:Connect(function()
		local presets = {
			Color3.fromRGB(99, 132, 255),
			Color3.fromRGB(72, 199, 142),
			Color3.fromRGB(255, 184, 77),
			Color3.fromRGB(255, 96, 112),
			Color3.fromRGB(168, 85, 247),
		}
		local nextIndex = (table.find(presets, settings.CurrentValue) or 0) % #presets + 1
		settings.CurrentValue = presets[nextIndex]
		swatch.BackgroundColor3 = settings.CurrentValue
		if settings.Callback then
			settings.Callback(settings.CurrentValue, settings.Transparency)
		end
	end)
	parentElement.NestedElements[index] = element
	return element
end

return Elements
