-- Alleral V11.5 — search bar aurora glow (dual stroke + idle shimmer)
return function(Theme)
	local SearchGlow = {}
	local TweenService = game:GetService("TweenService")

	local ACCENT = Color3.fromHex("#8B5CF6")
	local ACCENT_BRIGHT = Color3.fromHex("#A78BFA")
	local CYAN = Color3.fromHex("#22D3EE")
	local IDLE_TRANSPARENCY = 0.9
	local FOCUS_TRANSPARENCY = 0.08
	local TWEEN_TIME = 0.26

	local bound = {}

	if Theme then
		pcall(function()
			if Theme.accent then
				ACCENT = Theme.accent()
			end
			if Theme.accentBright then
				ACCENT_BRIGHT = Theme.accentBright()
			end
			if Theme.cyan then
				CYAN = Theme.cyan()
			end
		end)
	end

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

	local function ensureStrokes(frame)
		local outer = frame:FindFirstChild("AlleralSearchGlow")
		if not outer or not outer:IsA("UIStroke") then
			outer = Instance.new("UIStroke")
			outer.Name = "AlleralSearchGlow"
			outer.Parent = frame
		end
		outer.Color = ACCENT
		outer.Thickness = 1.8
		outer.Transparency = IDLE_TRANSPARENCY
		outer.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		outer.LineJoinMode = Enum.LineJoinMode.Round

		local inner = frame:FindFirstChild("AlleralSearchGlowInner")
		if not inner or not inner:IsA("UIStroke") then
			inner = Instance.new("UIStroke")
			inner.Name = "AlleralSearchGlowInner"
			inner.Parent = frame
		end
		inner.Color = CYAN
		inner.Thickness = 3.6
		inner.Transparency = 0.96
		inner.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		inner.LineJoinMode = Enum.LineJoinMode.Round

		return outer, inner
	end

	local function bindTarget(textBox, frame)
		if not textBox or not frame or bound[textBox] then
			return false
		end
		bound[textBox] = true

		local outer, inner = ensureStrokes(frame)
		local glowTween
		local idleTween

		local function stopIdle()
			if idleTween then
				pcall(function()
					idleTween:Cancel()
				end)
				idleTween = nil
			end
		end

		local function startIdle()
			stopIdle()
			idleTween = TweenService:Create(
				outer,
				TweenInfo.new(2.4, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
				{
					Transparency = 0.82,
					Color = ACCENT_BRIGHT,
				}
			)
			idleTween:Play()
		end

		local function tweenGlow(focused)
			stopIdle()
			if glowTween then
				pcall(function()
					glowTween:Cancel()
				end)
			end
			glowTween = TweenService:Create(
				outer,
				TweenInfo.new(TWEEN_TIME, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
				{
					Transparency = focused and FOCUS_TRANSPARENCY or IDLE_TRANSPARENCY,
					Color = focused and ACCENT_BRIGHT or ACCENT,
					Thickness = focused and 2.4 or 1.8,
				}
			)
			glowTween:Play()

			local innerTween = TweenService:Create(
				inner,
				TweenInfo.new(TWEEN_TIME, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
				{
					Transparency = focused and 0.78 or 0.96,
					Thickness = focused and 5 or 3.6,
				}
			)
			innerTween:Play()

			if not focused then
				task.delay(TWEEN_TIME, startIdle)
			end
		end

		textBox.MouseButton1Click:Connect(function()
			tweenGlow(true)
		end)
		textBox.FocusLost:Connect(function()
			if #textBox.Text == 0 then
				tweenGlow(false)
			end
		end)
		textBox:GetPropertyChangedSignal("Text"):Connect(function()
			tweenGlow(#textBox.Text > 0)
		end)

		startIdle()
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
							Log.info("Search bar aurora glow active")
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