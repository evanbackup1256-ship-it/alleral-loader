-- Alleral V11.4 — search bar focus glow
return function()
	local SearchGlow = {}
	local TweenService = game:GetService("TweenService")

	local ACCENT = Color3.fromHex("#8B5CF6")
	local ACCENT_BRIGHT = Color3.fromHex("#A855F7")
	local IDLE_TRANSPARENCY = 0.88
	local FOCUS_TRANSPARENCY = 0.12
	local TWEEN_TIME = 0.22

	local bound = {}

	local function getRoot(windWindow)
		local root = windWindow and windWindow.UIElements and windWindow.UIElements.Main
		if typeof(root) == "Instance" then
			return root
		end
		return nil
	end

	local function collectRoots(windWindow)
		local roots = {}
		local elements = windWindow and windWindow.UIElements
		if type(elements) == "table" then
			for _, value in pairs(elements) do
				if typeof(value) == "Instance" then
					table.insert(roots, value)
				end
			end
		end
		local main = getRoot(windWindow)
		if main then
			table.insert(roots, main)
		end
		return roots
	end

	local function isSearchTextBox(instance)
		if not instance or not instance:IsA("TextBox") then
			return false
		end
		local name = instance.Name:lower()
		local placeholder = tostring(instance.PlaceholderText or ""):lower()
		return name:find("search", 1, true) ~= nil
			or placeholder:find("search", 1, true) ~= nil
			or instance:FindFirstAncestor("SearchBar") ~= nil
	end

	local function findSearchTargets(windWindow)
		local textBox
		local frame
		for _, root in ipairs(collectRoots(windWindow)) do
			local searchBar = root:FindFirstChild("SearchBar", true)
			if searchBar then
				textBox = searchBar:FindFirstChildWhichIsA("TextBox", true)
				frame = searchBar
				if textBox then
					return textBox, frame
				end
			end
			for _, desc in ipairs(root:GetDescendants()) do
				if isSearchTextBox(desc) then
					return desc, desc.Parent
				end
			end
		end
		return nil, nil
	end

	local function ensureStroke(frame)
		local stroke = frame:FindFirstChild("AlleralSearchGlow")
		if stroke and stroke:IsA("UIStroke") then
			return stroke
		end
		stroke = Instance.new("UIStroke")
		stroke.Name = "AlleralSearchGlow"
		stroke.Color = ACCENT
		stroke.Thickness = 1.6
		stroke.Transparency = IDLE_TRANSPARENCY
		stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		stroke.LineJoinMode = Enum.LineJoinMode.Round
		stroke.Parent = frame
		return stroke
	end

	local function bindTarget(textBox, frame)
		if not textBox or not frame or bound[textBox] then
			return false
		end
		bound[textBox] = true

		local stroke = ensureStroke(frame)
		local glowTween

		local function tweenGlow(focused)
			if glowTween then
				pcall(function()
					glowTween:Cancel()
				end)
			end
			glowTween = TweenService:Create(
				stroke,
				TweenInfo.new(TWEEN_TIME, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
				{
					Transparency = focused and FOCUS_TRANSPARENCY or IDLE_TRANSPARENCY,
					Color = focused and ACCENT_BRIGHT or ACCENT,
					Thickness = focused and 2.2 or 1.6,
				}
			)
			glowTween:Play()
		end

		textBox.MouseButton1Click:Connect(function()
			tweenGlow(true)
		end)
		textBox.FocusLost:Connect(function()
			tweenGlow(false)
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
					pcall(function()
						local Log = getgenv and getgenv().Alleral_Log
						if Log and Log.info then
							Log.info("Search bar glow active")
						end
					end)
					return
				end
				task.wait(0.1)
			end
		end)
	end

	return SearchGlow
end