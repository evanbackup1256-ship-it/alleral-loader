-- Alleral V12 — one-shot element polish (no DescendantAdded recursion)
return function(Theme, Motion)
	local ElementPolish = {}
	local TweenService = game:GetService("TweenService")

	local patched = {}
	local bound = {}

	local ACCENT = Color3.fromHex("#7C3AED")
	local CYAN = Color3.fromHex("#06B6D4")
	local CARD = Color3.fromHex("#080D16")
	local CARD2 = Color3.fromHex("#0C121C")
	local TEXT = Color3.fromHex("#F8FAFC")

	if Theme then
		pcall(function()
			if Theme.accent then ACCENT = Theme.accent() end
			if Theme.cyan then CYAN = Theme.cyan() end
			if Theme.card then CARD = Theme.card() end
			if Theme.card2 then CARD2 = Theme.card2() end
		end)
	end

	local function getRoot(windWindow)
		local root = windWindow and windWindow.UIElements and windWindow.UIElements.Main
		if typeof(root) == "Instance" then
			return root
		end
		return nil
	end

	local function mark(inst, key)
		patched[inst] = patched[inst] or {}
		if patched[inst][key] then
			return false
		end
		patched[inst][key] = true
		return true
	end

	local function corner(frame, radius)
		local c = frame:FindFirstChild("AlleralElCorner")
		if not c then
			c = Instance.new("UICorner")
			c.Name = "AlleralElCorner"
			c.Parent = frame
		end
		c.CornerRadius = UDim.new(0, radius or 14)
	end

	local function isSectionBox(inst)
		if not inst:IsA("GuiObject") then
			return false
		end
		local name = inst.Name:lower()
		return name:find("section", 1, true) ~= nil
			or name:find("group", 1, true) ~= nil
			or inst:FindFirstChild("Section", true) ~= nil
	end

	local function patchSection(inst)
		if not mark(inst, "section") then
			return
		end
		if inst:IsA("Frame") or inst:IsA("ImageLabel") then
			inst.BackgroundColor3 = CARD
			inst.BackgroundTransparency = 0
			corner(inst, 15)
		end

		local accent = inst:FindFirstChild("AlleralCardAccent")
		if not accent then
			accent = Instance.new("Frame")
			accent.Name = "AlleralCardAccent"
			accent.AnchorPoint = Vector2.new(0, 0)
			accent.Position = UDim2.fromOffset(0, 0)
			accent.Size = UDim2.new(1, 0, 0, 2)
			accent.BackgroundColor3 = CYAN
			accent.BackgroundTransparency = 0.35
			accent.BorderSizePixel = 0
			accent.ZIndex = (inst.ZIndex or 1) + 3
			accent.Parent = inst
			local grad = Instance.new("UIGradient")
			grad.Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0, CYAN),
				ColorSequenceKeypoint.new(0.5, ACCENT),
				ColorSequenceKeypoint.new(1, ACCENT),
			})
			grad.Parent = accent
		end

		local shadow = inst:FindFirstChild("AlleralCardShadow")
		if not shadow then
			shadow = Instance.new("UIStroke")
			shadow.Name = "AlleralCardShadow"
			shadow.Color = Color3.fromRGB(0, 0, 0)
			shadow.Thickness = 1
			shadow.Transparency = 0.82
			shadow.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
			shadow.Parent = inst
		end

		local inner = inst:FindFirstChild("AlleralCardGradient")
		if not inner and (inst:IsA("Frame") or inst:IsA("ImageLabel")) then
			inner = Instance.new("UIGradient")
			inner.Name = "AlleralCardGradient"
			inner.Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0, CARD2),
				ColorSequenceKeypoint.new(1, CARD),
			})
			inner.Rotation = 180
			inner.Parent = inst
		end

		local layout = inst:FindFirstChildWhichIsA("UIListLayout", true)
		if layout then
			layout.Padding = UDim.new(0, 6)
		end
	end

	local function patchScrollingFrame(sf)
		if not sf:IsA("ScrollingFrame") or not mark(sf, "scroll") then
			return
		end

		sf.ScrollBarThickness = 4
		sf.ScrollBarImageColor3 = ACCENT
		sf.ScrollBarImageTransparency = 0.55
		sf.BorderSizePixel = 0
		sf.ClipsDescendants = true
		sf.ScrollingDirection = Enum.ScrollingDirection.Y

		local pad = sf:FindFirstChild("AlleralScrollPad")
		if not pad then
			pad = Instance.new("UIPadding")
			pad.Name = "AlleralScrollPad"
			pad.PaddingTop = UDim.new(0, 4)
			pad.PaddingBottom = UDim.new(0, 16)
			pad.PaddingLeft = UDim.new(0, 8)
			pad.PaddingRight = UDim.new(0, 12)
			pad.Parent = sf
		end

		if not mark(sf, "scroll-fade") then
			return
		end
		local lastScroll = 0
		local fadeTween
		sf:GetPropertyChangedSignal("CanvasPosition"):Connect(function()
			lastScroll = tick()
			sf.ScrollBarImageTransparency = 0.25
			if fadeTween then
				pcall(function() fadeTween:Cancel() end)
			end
			fadeTween = TweenService:Create(
				sf,
				TweenInfo.new(0.8, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
				{ ScrollBarImageTransparency = 0.72 }
			)
			task.delay(0.6, function()
				if tick() - lastScroll >= 0.55 and fadeTween then
					fadeTween:Play()
				end
			end)
		end)
	end

	local function patchTab(tabInst)
		if not tabInst:IsA("GuiButton") and not tabInst:IsA("Frame") then
			return
		end
		if not mark(tabInst, "tab") then
			return
		end

		local name = tabInst.Name:lower()
		if not name:find("tab", 1, true) and tabInst.Parent then
			local parentName = tabInst.Parent.Name:lower()
			if not parentName:find("tab", 1, true) and not parentName:find("sidebar", 1, true) then
				return
			end
		end

		tabInst.ClipsDescendants = false
		for _, label in ipairs(tabInst:GetDescendants()) do
			if label:IsA("TextLabel") or label:IsA("TextButton") then
				label.TextTruncate = Enum.TextTruncate.AtEnd
				label.TextWrapped = false
				label.TextXAlignment = Enum.TextXAlignment.Left
			end
		end

		local stroke = tabInst:FindFirstChild("AlleralTabStroke")
		if not stroke then
			stroke = Instance.new("UIStroke")
			stroke.Name = "AlleralTabStroke"
			stroke.Color = ACCENT
			stroke.Thickness = 1
			stroke.Transparency = 0.92
			stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
			stroke.Parent = tabInst
		end

		local activeBar = tabInst:FindFirstChild("AlleralTabActive")
		if not activeBar then
			activeBar = Instance.new("Frame")
			activeBar.Name = "AlleralTabActive"
			activeBar.AnchorPoint = Vector2.new(0, 0.5)
			activeBar.Position = UDim2.new(0, 0, 0.5, 0)
			activeBar.Size = UDim2.new(0, 3, 0.7, 0)
			activeBar.BackgroundColor3 = CYAN
			activeBar.BackgroundTransparency = 0.2
			activeBar.BorderSizePixel = 0
			activeBar.Visible = false
			activeBar.ZIndex = (tabInst.ZIndex or 1) + 2
			activeBar.Parent = tabInst
			corner(activeBar, 2)
		end

		local function refreshActive()
			local bg = tabInst.BackgroundTransparency or 1
			local active = bg < 0.15
			activeBar.Visible = active
			if active then
				tabInst.BackgroundColor3 = CARD2
				tabInst.BackgroundTransparency = 0
				stroke.Transparency = 0.55
				stroke.Color = ACCENT
			else
				stroke.Transparency = 0.92
			end
		end

		tabInst:GetPropertyChangedSignal("BackgroundTransparency"):Connect(refreshActive)
		refreshActive()

		if tabInst:IsA("GuiButton") then
			tabInst.MouseEnter:Connect(function()
				if activeBar.Visible then
					return
				end
				TweenService:Create(stroke, TweenInfo.new(0.18, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
					Transparency = 0.65,
					Color = CYAN,
				}):Play()
			end)
			tabInst.MouseLeave:Connect(function()
				if activeBar.Visible then
					return
				end
				TweenService:Create(stroke, TweenInfo.new(0.18, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
					Transparency = 0.92,
					Color = ACCENT,
				}):Play()
			end)
		end
	end

	local function findToggleThumb(container)
		for _, child in ipairs(container:GetDescendants()) do
			if child:IsA("GuiObject") then
				local n = child.Name:lower()
				if n == "circle" or n == "thumb" or n == "togglethumb" or n == "knob" then
					return child, container:FindFirstChild("Bar") or container:FindFirstChild("ToggleBar")
				end
			end
		end
		return nil, nil
	end

	local function patchToggle(container)
		if not mark(container, "toggle") then
			return
		end
		local thumb, bar = findToggleThumb(container)
		if not thumb or not bar then
			return
		end

		thumb.AnchorPoint = Vector2.new(0.5, 0.5)

		local glow = bar:FindFirstChild("AlleralToggleGlow")
		if not glow then
			glow = Instance.new("UIStroke")
			glow.Name = "AlleralToggleGlow"
			glow.Color = CYAN
			glow.Thickness = 2
			glow.Transparency = 1
			glow.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
			glow.Parent = bar
			corner(bar, 10)
		end

		local animating = false
		local function tweenTo(on, instant)
			if animating and not instant then
				return
			end
			animating = not instant
			local trackW = math.max(bar.AbsoluteSize.X, 36)
			local thumbW = math.max(thumb.AbsoluteSize.X, 14)
			local pad = 3
			local goalX = on and (trackW - thumbW - pad) or pad
			local goal = UDim2.new(0, goalX, 0.5, 0)
			if instant then
				thumb.Position = goal
				glow.Transparency = on and 0.55 or 1
				glow.Color = on and CYAN or ACCENT
				animating = false
				return
			end
			local tween = TweenService:Create(
				thumb,
				TweenInfo.new(0.22, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
				{ Position = goal }
			)
			local glowTween = TweenService:Create(
				glow,
				TweenInfo.new(0.22, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
				{ Transparency = on and 0.55 or 1, Color = on and CYAN or ACCENT }
			)
			tween:Play()
			glowTween:Play()
			tween.Completed:Connect(function()
				animating = false
			end)
		end

		local function readOn()
			local px = thumb.Position.X.Offset
			local trackW = math.max(bar.AbsoluteSize.X, 36)
			return px > trackW * 0.45
		end

		local lastOn = readOn()
		tweenTo(lastOn, true)

		local clickTarget = container:IsA("GuiButton") and container
			or container:FindFirstChildWhichIsA("GuiButton", true)
		if clickTarget then
			clickTarget.MouseButton1Click:Connect(function()
				task.defer(function()
					local on = not lastOn
					lastOn = on
					tweenTo(on)
				end)
			end)
		end
	end

	local function patchDropdown(header)
		if not mark(header, "dropdown") then
			return
		end
		local arrow = nil
		for _, child in ipairs(header:GetDescendants()) do
			if child:IsA("ImageLabel") or child:IsA("ImageButton") then
				local n = child.Name:lower()
				if n:find("arrow", 1, true) or n:find("chevron", 1, true) or n:find("icon", 1, true) then
					arrow = child
					break
				end
			end
		end
		if not arrow then
			return
		end

		arrow.ImageColor3 = CYAN
		arrow.Rotation = 0

		local open = false
		local function setOpen(isOpen)
			open = isOpen
			TweenService:Create(arrow, TweenInfo.new(0.2, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
				Rotation = isOpen and 180 or 0,
			}):Play()
		end

		local btn = header:IsA("GuiButton") and header or header:FindFirstChildWhichIsA("GuiButton", true)
		if btn then
			btn.MouseButton1Click:Connect(function()
				setOpen(not open)
			end)
		end
	end

	local function patchSearchBar(bar)
		if not mark(bar, "search") then
			return
		end
		if bar:IsA("Frame") or bar:IsA("TextBox") then
			bar.BackgroundColor3 = CARD
			bar.BackgroundTransparency = 0.06
			corner(bar, 10)
		end
		for _, child in ipairs(bar:GetDescendants()) do
			if child:IsA("TextBox") then
				child.BackgroundTransparency = 1
				child.TextColor3 = TEXT
				child.ClipsDescendants = false
			end
		end
	end

	local function patchLayout(root)
		if not mark(root, "layout") then
			return
		end
		for _, desc in ipairs(root:GetDescendants()) do
			if desc:IsA("ScrollingFrame") then
				local parent = desc.Parent
				if parent and parent:IsA("GuiObject") then
					desc.Size = UDim2.new(1, -4, 1, -8)
				end
			end
			if desc:IsA("Frame") then
				local name = desc.Name:lower()
				if name:find("content", 1, true) or name:find("elements", 1, true) or name:find("columns", 1, true) then
					desc.Size = UDim2.new(1, 0, 1, 0)
				end
			end
			if desc:IsA("UIListLayout") and desc.FillDirection == Enum.FillDirection.Horizontal then
				desc.Padding = UDim.new(0, 10)
				desc.HorizontalAlignment = Enum.HorizontalAlignment.Left
				desc.VerticalAlignment = Enum.VerticalAlignment.Top
			end
		end
	end

	local function walk(inst)
		if inst:IsA("ScrollingFrame") then
			patchScrollingFrame(inst)
		end
		if isSectionBox(inst) then
			patchSection(inst)
		end
		if inst:IsA("GuiButton") or (inst:IsA("Frame") and inst.Name:lower():find("tab", 1, true)) then
			patchTab(inst)
		end
		if inst.Name:lower():find("toggle", 1, true) then
			patchToggle(inst)
		end
		if inst.Name:lower():find("dropdown", 1, true) then
			patchDropdown(inst)
		end
		if inst.Name:lower():find("search", 1, true) then
			patchSearchBar(inst)
		end
	end

	local function applyAll(windWindow)
		local root = getRoot(windWindow)
		if not root then
			return false
		end
		patchLayout(root)
		for _, desc in ipairs(root:GetDescendants()) do
			pcall(walk, desc)
		end
		return true
	end

	function ElementPolish.bind(windWindow)
		if not windWindow or bound[windWindow] then
			return
		end
		bound[windWindow] = true

		local passes = 0
		local function runPass()
			passes = passes + 1
			pcall(applyAll, windWindow)
			if passes < 4 then
				task.defer(runPass)
			end
		end
		task.defer(runPass)

		pcall(function()
			local Log = getgenv and getgenv().Alleral_Log
			if Log and Log.info then
				Log.info("Element polish active (one-shot, no recursion)")
			end
		end)
	end

	return ElementPolish
end