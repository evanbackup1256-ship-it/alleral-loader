-- Alleral V11.3 — premium dynamic tooltips (guarded, readable, positioned)
return function(Bootstrap, Motion, Text)
	local TooltipManager = {}
	local UserInputService = game:GetService("UserInputService")
	local TextService = game:GetService("TextService")
	local Players = game:GetService("Players")

	local HOVER_DELAY = 0.25
	local FADE_IN = 0.1
	local FADE_OUT = 0.08
	local MIN_WIDTH = 180
	local MAX_WIDTH = 300

	local gui
	local overlay
	local frame
	local accentBar
	local titleLabel
	local descLabel
	local metaLabel
	local uiScale

	local visible = false
	local isShowingTooltip = false
	local isHiding = false
	local activeTooltipId = nil
	local registeredTooltips = {}
	local connectedControls = {}
	local showThread = nil
	local hideThread = nil
	local stats = { attached = 0, shown = 0, connections = 0 }

	local COLORS = {
		bg = Color3.fromHex("#0B1020"),
		border = Color3.fromHex("#25304A"),
		accent = Color3.fromHex("#8B5CF6"),
		text = Color3.fromHex("#F8FAFC"),
		muted = Color3.fromHex("#94A3B8"),
	}

	local function cancelShowThread()
		if showThread then
			task.cancel(showThread)
			showThread = nil
		end
	end

	local function cancelHideThread()
		if hideThread then
			task.cancel(hideThread)
			hideThread = nil
		end
	end

	local function sanitizeLine(value, maxLen, fallback)
		local s = Bootstrap.sanitize(value, maxLen)
		if s == "" or s == "--" or s == "—" then
			return fallback
		end
		return s
	end

	local function textHeight(text, width, fontSize)
		local ok, size = pcall(function()
			return TextService:GetTextSize(
				text,
				fontSize,
				Enum.Font.Gotham,
				Vector2.new(width, 1000)
			)
		end)
		if ok and size then
			return size.Y
		end
		return fontSize * math.max(1, math.ceil(#text / 32))
	end

	local function ensureGui()
		if gui and gui.Parent then
			return true
		end
		local player = Players.LocalPlayer
		if not player then
			return false
		end
		local pg = player:FindFirstChildOfClass("PlayerGui")
		if not pg then
			return false
		end

		gui = Instance.new("ScreenGui")
		gui.Name = "AlleralTooltipOverlay"
		gui.ResetOnSpawn = false
		gui.DisplayOrder = 500
		gui.IgnoreGuiInset = true
		gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
		gui.Parent = pg

		overlay = Instance.new("Frame")
		overlay.Name = "TooltipOverlay"
		overlay.BackgroundTransparency = 1
		overlay.BorderSizePixel = 0
		overlay.Size = UDim2.fromScale(1, 1)
		overlay.ZIndex = 500
		overlay.Parent = gui

		frame = Instance.new("Frame")
		frame.Name = "TooltipFrame"
		frame.BackgroundColor3 = COLORS.bg
		frame.BackgroundTransparency = 0.04
		frame.BorderSizePixel = 0
		frame.Visible = false
		frame.ZIndex = 501
		frame.Parent = overlay

		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0, 10)
		corner.Parent = frame

		local stroke = Instance.new("UIStroke")
		stroke.Color = COLORS.border
		stroke.Transparency = 0.3
		stroke.Thickness = 1
		stroke.Parent = frame

		accentBar = Instance.new("Frame")
		accentBar.Name = "AccentBar"
		accentBar.BackgroundColor3 = COLORS.accent
		accentBar.BorderSizePixel = 0
		accentBar.Size = UDim2.new(1, 0, 0, 2)
		accentBar.ZIndex = 502
		accentBar.Parent = frame

		local pad = Instance.new("UIPadding")
		pad.PaddingTop = UDim.new(0, 12)
		pad.PaddingBottom = UDim.new(0, 12)
		pad.PaddingLeft = UDim.new(0, 12)
		pad.PaddingRight = UDim.new(0, 12)
		pad.Parent = frame

		titleLabel = Instance.new("TextLabel")
		titleLabel.Name = "TitleLabel"
		titleLabel.BackgroundTransparency = 1
		titleLabel.Font = Enum.Font.GothamMedium
		titleLabel.TextSize = 14
		titleLabel.TextColor3 = COLORS.text
		titleLabel.TextTransparency = 0
		titleLabel.TextXAlignment = Enum.TextXAlignment.Left
		titleLabel.TextYAlignment = Enum.TextYAlignment.Top
		titleLabel.TextWrapped = true
		titleLabel.AutomaticSize = Enum.AutomaticSize.Y
		titleLabel.Size = UDim2.new(1, 0, 0, 0)
		titleLabel.Position = UDim2.fromOffset(0, 4)
		titleLabel.ZIndex = 503
		titleLabel.Parent = frame

		descLabel = Instance.new("TextLabel")
		descLabel.Name = "DescriptionLabel"
		descLabel.BackgroundTransparency = 1
		descLabel.Font = Enum.Font.Gotham
		descLabel.TextSize = 12
		descLabel.TextColor3 = COLORS.muted
		descLabel.TextTransparency = 0
		descLabel.TextXAlignment = Enum.TextXAlignment.Left
		descLabel.TextYAlignment = Enum.TextYAlignment.Top
		descLabel.TextWrapped = true
		descLabel.AutomaticSize = Enum.AutomaticSize.Y
		descLabel.Size = UDim2.new(1, 0, 0, 0)
		descLabel.Position = UDim2.fromOffset(0, 24)
		descLabel.ZIndex = 503
		descLabel.Parent = frame

		metaLabel = Instance.new("TextLabel")
		metaLabel.Name = "MetadataLabel"
		metaLabel.BackgroundTransparency = 1
		metaLabel.Font = Enum.Font.Gotham
		metaLabel.TextSize = 11
		metaLabel.TextColor3 = COLORS.muted
		metaLabel.TextTransparency = 0.15
		metaLabel.TextXAlignment = Enum.TextXAlignment.Left
		metaLabel.TextYAlignment = Enum.TextYAlignment.Top
		metaLabel.TextWrapped = true
		metaLabel.AutomaticSize = Enum.AutomaticSize.Y
		metaLabel.Size = UDim2.new(1, 0, 0, 0)
		metaLabel.Position = UDim2.fromOffset(0, 44)
		metaLabel.ZIndex = 503
		metaLabel.Parent = frame

		uiScale = Instance.new("UIScale")
		uiScale.Scale = 0.96
		uiScale.Parent = frame

		return true
	end

	function TooltipManager.resolve(meta, controlType, sectionName, label)
		meta = type(meta) == "table" and meta or {}
		local title = sanitizeLine(meta.title or meta.Title or label or controlType, 80, "Info")
		local desc = sanitizeLine(meta.description or meta.Description or meta.Desc or meta.Tooltip, 220, "")
		local metaLines = {}

		if desc == "" then
			if sectionName and tostring(sectionName) ~= "" then
				desc = "Controls in " .. sanitizeLine(sectionName, 64, "this section") .. "."
			else
				desc = "No details available."
			end
		end

		local value = meta.value
		if type(value) == "function" then
			local ok, res = pcall(value)
			if ok and res ~= nil then
				table.insert(metaLines, "Value: " .. sanitizeLine(res, 80, "--"))
			end
		elseif value ~= nil then
			table.insert(metaLines, "Value: " .. sanitizeLine(value, 80, "--"))
		end
		if meta.hotkey and tostring(meta.hotkey) ~= "" and tostring(meta.hotkey) ~= "None" then
			table.insert(metaLines, "Hotkey: " .. sanitizeLine(meta.hotkey, 32, "None"))
		end
		if meta.configKey and tostring(meta.configKey) ~= "" then
			table.insert(metaLines, "Config: " .. sanitizeLine(meta.configKey, 64, ""))
		end
		if meta.warning and tostring(meta.warning) ~= "" then
			table.insert(metaLines, "Warning: " .. sanitizeLine(meta.warning, 120, ""))
		end
		if meta.state and tostring(meta.state) ~= "" then
			table.insert(metaLines, "State: " .. sanitizeLine(meta.state, 40, ""))
		end

		return title, desc, table.concat(metaLines, "\n")
	end

	local function layoutFrame(title, desc, metaText)
		local innerWidth = MAX_WIDTH - 24
		title = sanitizeLine(title, 80, "Info")
		desc = sanitizeLine(desc, 240, "No details available.")
		metaText = Bootstrap.sanitize(metaText or "", 160)

		titleLabel.Text = title
		descLabel.Text = desc
		metaLabel.Text = metaText
		metaLabel.Visible = metaText ~= ""

		local titleH = textHeight(title, innerWidth, 14)
		local descH = textHeight(desc, innerWidth, 12)
		local metaH = metaLabel.Visible and textHeight(metaText, innerWidth, 11) or 0

		descLabel.Position = UDim2.fromOffset(0, titleH + 8)
		metaLabel.Position = UDim2.fromOffset(0, titleH + descH + 14)

		local contentW = math.max(
			MIN_WIDTH,
			math.min(MAX_WIDTH, math.max(textHeight(title, 9999, 14) > 0 and #title * 6 or MIN_WIDTH, innerWidth))
		)
		local width = math.clamp(contentW, MIN_WIDTH, MAX_WIDTH)
		local totalH = 28 + titleH + descH + (metaH > 0 and (metaH + 8) or 0)
		frame.Size = UDim2.fromOffset(width, totalH)
	end

	local function placeNear(guiObj, opts)
		opts = opts or {}
		if not frame or not guiObj then
			return
		end
		local cam = workspace.CurrentCamera
		if not cam then
			return
		end
		local vp = cam.ViewportSize
		local abs = guiObj.AbsolutePosition
		local size = guiObj.AbsoluteSize
		local fw = frame.AbsoluteSize.X > 0 and frame.AbsoluteSize.X or frame.Size.X.Offset
		if fw < MIN_WIDTH then
			fw = MIN_WIDTH
		end
		local fh = frame.AbsoluteSize.Y > 0 and frame.AbsoluteSize.Y or frame.Size.Y.Offset
		if fh < 48 then
			fh = 72
		end

		local pos
		if opts.placement == "sidebar" or abs.X < vp.X * 0.28 then
			pos = Vector2.new(abs.X + size.X + 14, abs.Y + math.max(0, (size.Y - fh) * 0.5))
		elseif opts.followMouse then
			pos = UserInputService:GetMouseLocation() + Vector2.new(16, 16)
		else
			pos = Vector2.new(abs.X + size.X + 12, abs.Y + math.max(0, (size.Y - fh) * 0.5))
		end

		if pos.X + fw > vp.X - 10 then
			pos = Vector2.new(math.max(10, abs.X - fw - 12), pos.Y)
		end
		if pos.Y + fh > vp.Y - 10 then
			pos = Vector2.new(pos.X, math.max(10, vp.Y - fh - 10))
		end
		if pos.X < 10 then
			pos = Vector2.new(10, pos.Y)
		end
		if pos.Y < 10 then
			pos = Vector2.new(pos.X, 10)
		end

		frame.Position = UDim2.fromOffset(pos.X, pos.Y)
	end

	function TooltipManager.hide()
		if isHiding or not visible then
			return
		end
		isHiding = true
		cancelShowThread()

		if frame and uiScale then
			if Motion then
				pcall(function()
					Motion.tween(uiScale, { Scale = 0.96 }, FADE_OUT)
					Motion.tween(frame, { BackgroundTransparency = 1 }, FADE_OUT)
				end)
			end
			cancelHideThread()
			hideThread = task.delay(FADE_OUT + 0.02, function()
				if frame then
					frame.Visible = false
					frame.BackgroundTransparency = 0.04
				end
				visible = false
				activeTooltipId = nil
				isHiding = false
			end)
		else
			visible = false
			activeTooltipId = nil
			isHiding = false
		end
	end

	function TooltipManager.show(guiObj, title, desc, metaText, opts)
		if isShowingTooltip or isHiding then
			return
		end
		if not guiObj or not guiObj.Parent then
			return
		end

		local targetId = tostring(guiObj)
		if visible and activeTooltipId == targetId then
			placeNear(guiObj, opts)
			return
		end

		isShowingTooltip = true
		cancelShowThread()
		cancelHideThread()

		if visible and activeTooltipId ~= targetId then
			frame.Visible = false
			visible = false
		end

		if not ensureGui() then
			isShowingTooltip = false
			return
		end

		layoutFrame(title, desc, metaText)
		frame.Visible = true
		task.defer(function()
			if not guiObj.Parent then
				isShowingTooltip = false
				return
			end
			placeNear(guiObj, opts)
		end)
		placeNear(guiObj, opts)

		visible = true
		activeTooltipId = targetId
		stats.shown = stats.shown + 1

		if uiScale and Motion then
			uiScale.Scale = 0.96
			titleLabel.TextTransparency = 0
			descLabel.TextTransparency = 0
			frame.BackgroundTransparency = 1
			pcall(function()
				Motion.tween(uiScale, { Scale = 1 }, FADE_IN)
				Motion.tween(frame, { BackgroundTransparency = 0.04 }, FADE_IN)
			end)
		end

		isShowingTooltip = false
	end

	local FRAME_KEYS = {
		"ToggleFrame",
		"ButtonFrame",
		"SliderFrame",
		"ParagraphFrame",
		"DropdownFrame",
		"InputFrame",
		"CheckboxFrame",
	}

	local function findHoverTarget(el)
		if typeof(el) == "Instance" and el:IsA("GuiObject") then
			if el:IsA("GuiButton") then
				return el
			end
			if el:IsA("TextButton") or el:IsA("ImageButton") then
				return el
			end
			for _, child in ipairs(el:GetChildren()) do
				local found = findHoverTarget(child)
				if found then
					return found
				end
			end
			if el.AbsoluteSize.X >= 24 and el.AbsoluteSize.Y >= 16 then
				return el
			end
			return el
		end
		if type(el) == "table" then
			if el.UIElements and typeof(el.UIElements.Main) == "Instance" then
				return findHoverTarget(el.UIElements.Main)
			end
			for _, key in ipairs(FRAME_KEYS) do
				local frameObj = el[key]
				if type(frameObj) == "table" and frameObj.UIElements and typeof(frameObj.UIElements.Main) == "Instance" then
					return findHoverTarget(frameObj.UIElements.Main)
				end
			end
			for _, key in ipairs({ "Button", "Frame", "Holder", "Root", "Object", "Instance", "Main" }) do
				local v = el[key]
				if typeof(v) == "Instance" then
					local found = findHoverTarget(v)
					if found then
						return found
					end
				end
			end
		end
		return nil
	end

	function TooltipManager.attach(el, meta, controlType, sectionName, label)
		local guiObj = findHoverTarget(el)
		if not guiObj then
			return
		end
		local key = tostring(guiObj)
		if registeredTooltips[key] or connectedControls[key] then
			return
		end
		registeredTooltips[key] = true
		connectedControls[key] = true
		guiObj:SetAttribute("AlleralTooltipBound", true)
		stats.attached = stats.attached + 1

		local opts = type(meta) == "table" and meta or {}
		if controlType == "tab" or opts.placement == "sidebar" then
			opts.placement = "sidebar"
		end

		local enterConn = guiObj.MouseEnter:Connect(function()
			if isShowingTooltip or isHiding then
				return
			end
			cancelShowThread()
			showThread = task.delay(HOVER_DELAY, function()
				if not guiObj.Parent then
					return
				end
				if isShowingTooltip or isHiding then
					return
				end
				local title, desc, metaText = TooltipManager.resolve(opts, controlType, sectionName, label)
				TooltipManager.show(guiObj, title, desc, metaText, opts)
			end)
		end)
		stats.connections = stats.connections + 1

		local leaveConn = guiObj.MouseLeave:Connect(function()
			cancelShowThread()
			if activeTooltipId == key then
				TooltipManager.hide()
			end
		end)
		stats.connections = stats.connections + 1

		connectedControls[key .. ":enter"] = enterConn
		connectedControls[key .. ":leave"] = leaveConn
	end

	function TooltipManager.attachTab(windTab, name)
		if not windTab then
			return
		end
		task.defer(function()
			local target = windTab
			if windTab.UIElements and windTab.UIElements.Main then
				target = windTab.UIElements.Main
			end
			TooltipManager.attach(target, {
				title = name,
				description = "Switch to the " .. Bootstrap.sanitize(name, 48) .. " tab.",
				placement = "sidebar",
			}, "tab", nil, name)
		end)
	end

	function TooltipManager.init()
		ensureGui()
		warn("[WindUI] TooltipManager ready")
		warn("[WindUI] Tooltip recursion guard active")
	end

	function TooltipManager.getStats()
		return {
			attached = stats.attached,
			shown = stats.shown,
			visible = visible,
			connections = stats.connections,
			activeId = activeTooltipId,
			registered = stats.attached,
		}
	end

	function TooltipManager.suppressDuringDrag()
		cancelShowThread()
		TooltipManager.hide()
	end

	return TooltipManager
end