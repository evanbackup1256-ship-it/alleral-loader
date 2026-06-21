-- Alleral V11.6 — search bar polish (matched to card style)
return function(Theme)
	local SearchGlow = {}
	local TweenService = game:GetService("TweenService")

	local ACCENT = Color3.fromHex("#7C3AED")
	local CYAN = Color3.fromHex("#06B6D4")
	local CARD = Color3.fromHex("#080D16")
	local IDLE_TRANSPARENCY = 0.72
	local FOCUS_TRANSPARENCY = 0.2
	local TWEEN_TIME = 0.2

	local bound = {}

	if Theme then
		pcall(function()
			if Theme.accent then ACCENT = Theme.accent() end
			if Theme.cyan then CYAN = Theme.cyan() end
			if Theme.card then CARD = Theme.card() end
		end)
	end

	local function getRoot(windWindow)
		local root = windWindow and windWindow.UIElements and windWindow.UIElements.Main
		if typeof(root) == "Instance" then
			return root
		end
		return nil
	end

	local function findSearchTargets(windWindow)
		local root = getRoot(windWindow)
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
		for _, desc in ipairs(root:GetDescendants()) do
			if desc:IsA("TextBox") then
				local placeholder = tostring(desc.PlaceholderText or ""):lower()
				if placeholder:find("search", 1, true) or desc.Name:lower():find("search", 1, true) then
					return desc, desc.Parent
				end
			end
		end
		return nil, nil
	end

	local function ensureStroke(frame)
		local stroke = frame:FindFirstChild("AlleralSearchGlow")
		if not stroke or not stroke:IsA("UIStroke") then
			stroke = Instance.new("UIStroke")
			stroke.Name = "AlleralSearchGlow"
			stroke.Parent = frame
		end
		stroke.Color = ACCENT
		stroke.Thickness = 1
		stroke.Transparency = IDLE_TRANSPARENCY
		stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		stroke.LineJoinMode = Enum.LineJoinMode.Round
		return stroke
	end

	local function styleFrame(frame)
		if frame:IsA("Frame") or frame:IsA("TextBox") then
			frame.BackgroundColor3 = CARD
			frame.BackgroundTransparency = 0.06
		end
		local corner = frame:FindFirstChild("AlleralSearchCorner")
		if not corner then
			corner = Instance.new("UICorner")
			corner.Name = "AlleralSearchCorner"
			corner.CornerRadius = UDim.new(0, 10)
			corner.Parent = frame
		end
	end

	local function bindTarget(textBox, frame)
		if not textBox or not frame or bound[textBox] then
			return false
		end
		bound[textBox] = true

		styleFrame(frame)
		local stroke = ensureStroke(frame)
		local glowTween

		local function tweenGlow(focused)
			if glowTween then
				pcall(function() glowTween:Cancel() end)
			end
			glowTween = TweenService:Create(
				stroke,
				TweenInfo.new(TWEEN_TIME, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
				{
					Transparency = focused and FOCUS_TRANSPARENCY or IDLE_TRANSPARENCY,
					Color = focused and CYAN or ACCENT,
					Thickness = focused and 1.4 or 1,
				}
			)
			glowTween:Play()
		end

		textBox.BackgroundTransparency = 1
		textBox.ClipsDescendants = false
		textBox.MouseButton1Click:Connect(function()
			tweenGlow(true)
		end)
		textBox.FocusLost:Connect(function()
			tweenGlow(#textBox.Text > 0)
		end)
		textBox:GetPropertyChangedSignal("Text"):Connect(function()
			if #textBox.Text > 0 then
				tweenGlow(true)
			end
		end)

		return true
	end

	function SearchGlow.bind(windWindow)
		if not windWindow or bound[windWindow] then
			return
		end
		bound[windWindow] = true

		task.spawn(function()
			for _ = 1, 50 do
				local textBox, frame = findSearchTargets(windWindow)
				if bindTarget(textBox, frame) then
					return
				end
				task.wait(0.1)
			end
		end)
	end

	return SearchGlow
end