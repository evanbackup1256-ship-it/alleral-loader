-- Alleral V11.5.3 — search focus stroke (one-shot, no idle loops)
return function(Theme)
	local SearchGlow = {}
	local TweenService = game:GetService("TweenService")
	local bound = {}

	local ACCENT = Color3.fromHex("#8B5CF6")
	local CYAN = Color3.fromHex("#22D3EE")

	if Theme then
		pcall(function()
			if Theme.accent then ACCENT = Theme.accent() end
			if Theme.cyan then CYAN = Theme.cyan() end
		end)
	end

	local function findSearch(windWindow)
		local root = windWindow and windWindow.UIElements and windWindow.UIElements.Main
		if not root then
			return nil, nil
		end
		local searchBar = root:FindFirstChild("SearchBar", true)
		if searchBar then
			local textBox = searchBar:FindFirstChildWhichIsA("TextBox", true)
			if textBox then
				return textBox, searchBar
			end
		end
		return nil, nil
	end

	function SearchGlow.bind(windWindow)
		if not windWindow or bound[windWindow] then
			return
		end
		bound[windWindow] = true

		task.defer(function()
			local textBox, frame = findSearch(windWindow)
			if not textBox or not frame or bound[textBox] then
				return
			end
			bound[textBox] = true

			local stroke = frame:FindFirstChild("AlleralSearchGlow")
			if not stroke then
				stroke = Instance.new("UIStroke")
				stroke.Name = "AlleralSearchGlow"
				stroke.Color = ACCENT
				stroke.Thickness = 1.5
				stroke.Transparency = 0.88
				stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
				stroke.Parent = frame
			end

			local function setFocused(on)
				TweenService:Create(stroke, TweenInfo.new(0.15, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
					Transparency = on and 0.35 or 0.88,
					Color = on and CYAN or ACCENT,
				}):Play()
			end

			textBox.MouseButton1Click:Connect(function() setFocused(true) end)
			textBox.FocusLost:Connect(function()
				if #textBox.Text == 0 then
					setFocused(false)
				end
			end)
		end)
	end

	return SearchGlow
end