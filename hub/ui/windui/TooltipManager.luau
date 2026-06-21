-- Alleral V11.3.1 — tooltips via hover registry + mouse polling (WindUI-safe)
return function(Bootstrap, Motion, Text)
	local TooltipManager = {}
	local UserInputService = game:GetService("UserInputService")
	local TextService = game:GetService("TextService")
	local RunService = game:GetService("RunService")
	local Players = game:GetService("Players")

	local HOVER_DELAY = 0.25
	local POLL_INTERVAL = 1 / 30
	local MIN_WIDTH = 180
	local MAX_WIDTH = 300

	local gui
	local overlay
	local frame
	local titleLabel
	local descLabel
	local metaLabel
	local uiScale

	local visible = false
	local isHiding = false
	local activeTarget = nil
	local registryList = {}
	local registryMap = {}
	local pollConn = nil
	local lastPoll = 0
	local pendingTarget = nil
	local pendingSince = 0
	local showThread = nil
	local hideThread = nil
	local stats = { attached = 0, shown = 0, connections = 0, failed = 0 }

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
			return TextService:GetTextSize(text, fontSize, Enum.Font.Gotham, Vector2.new(width, 1000))
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
		gui.DisplayOrder = 10000
		gui.IgnoreGuiInset = true
		gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
		gui.Parent = pg

		overlay = Instance.new("Frame")
		overlay.Name = "TooltipOverlay"
		overlay.BackgroundTransparency = 1
		overlay.BorderSizePixel = 0
		overlay.Size = UDim2.fromScale(1, 1)
		overlay.Active = false
		overlay.ZIndex = 1
		overlay.Parent = gui

		frame = Instance.new("Frame")
		frame.Name = "TooltipFrame"
		frame.BackgroundColor3 = COLORS.bg
		frame.BackgroundTransparency = 0.04
		frame.BorderSizePixel = 0
		frame.Visible = false
		frame.ZIndex = 2
		frame.Parent = overlay

		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0, 10)
		corner.Parent = frame

		local stroke = Instance.new("UIStroke")
		stroke.Color = COLORS.border
		stroke.Transparency = 0.3
		stroke.Thickness = 1
		stroke.Parent = frame

		local accentBar = Instance.new("Frame")
		accentBar.Name = "AccentBar"
		accentBar.BackgroundColor3 = COLORS.accent
		accentBar.BorderSizePixel = 0
		accentBar.Size = UDim2.new(1, 0, 0, 2)
		accentBar.ZIndex = 3
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
		titleLabel.TextWrapped = true
		titleLabel.AutomaticSize = Enum.AutomaticSize.Y
		titleLabel.Size = UDim2.new(1, 0, 0, 0)
		titleLabel.ZIndex = 4
		titleLabel.Parent = frame

		descLabel = Instance.new("TextLabel")
		descLabel.Name = "DescriptionLabel"
		descLabel.BackgroundTransparency = 1
		descLabel.Font = Enum.Font.Gotham
		descLabel.TextSize = 12
		descLabel.TextColor3 = COLORS.muted
		descLabel.TextTransparency = 0
		descLabel.TextXAlignment = Enum.TextXAlignment.Left
		descLabel.TextWrapped = true
		descLabel.AutomaticSize = Enum.AutomaticSize.Y
		descLabel.Size = UDim2.new(1, 0, 0, 0)
		descLabel.ZIndex = 4
		descLabel.Parent = frame

		metaLabel = Instance.new("TextLabel")
		metaLabel.Name = "MetadataLabel"
		metaLabel.BackgroundTransparency = 1
		metaLabel.Font = Enum.Font.Gotham
		metaLabel.TextSize = 11
		metaLabel.TextColor3 = COLORS.muted
		metaLabel.TextTransparency = 0.1
		metaLabel.TextXAlignment = Enum.TextXAlignment.Left
		metaLabel.TextWrapped = true
		metaLabel.AutomaticSize = Enum.AutomaticSize.Y
		metaLabel.Size = UDim2.new(1, 0, 0, 0)
		metaLabel.ZIndex = 4
		metaLabel.Parent = frame

		uiScale = Instance.new("UIScale")
		uiScale.Scale = 1
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

		local totalH = 28 + titleH + descH + (metaH > 0 and (metaH + 8) or 0)
		frame.Size = UDim2.fromOffset(MAX_WIDTH, totalH)
	end

	local function placeNear(guiObj, opts)
		opts = opts or {}
		if not frame or not guiObj or not guiObj.Parent then
			return
		end
		local cam = workspace.CurrentCamera
		if not cam then
			return
		end
		local vp = cam.ViewportSize
		local abs = guiObj.AbsolutePosition
		local size = guiObj.AbsoluteSize
		local fw = frame.AbsoluteSize.X > 0 and frame.AbsoluteSize.X or MAX_WIDTH
		local fh = frame.AbsoluteSize.Y > 0 and frame.AbsoluteSize.Y or 72

		local pos
		if opts.placement == "sidebar" or abs.X < vp.X * 0.3 then
			pos = Vector2.new(abs.X + size.X + 14, abs.Y + math.max(0, (size.Y - fh) * 0.5))
		else
			pos = Vector2.new(abs.X + size.X + 12, abs.Y + math.max(0, (size.Y - fh) * 0.5))
		end

		if pos.X + fw > vp.X - 10 then
			pos = Vector2.new(math.max(10, abs.X - fw - 12), pos.Y)
		end
		if pos.Y + fh > vp.Y - 10 then
			pos = Vector2.new(pos.X, math.max(10, vp.Y - fh - 10))
		end
		pos = Vector2.new(math.clamp(pos.X, 10, vp.X - fw - 10), math.clamp(pos.Y, 10, vp.Y - fh - 10))
		frame.Position = UDim2.fromOffset(pos.X, pos.Y)
	end

	function TooltipManager.hide()
		if not visible and not activeTarget then
			isHiding = false
			return
		end
		if isHiding then
			return
		end
		isHiding = true
		cancelShowThread()
		pendingTarget = nil
		pendingSince = 0

		cancelHideThread()
		hideThread = task.delay(0.05, function()
			if frame then
				frame.Visible = false
			end
			visible = false
			activeTarget = nil
			isHiding = false
		end)
	end

	function TooltipManager.show(guiObj, title, desc, metaText, opts)
		if not guiObj or not guiObj.Parent then
			return
		end
		if isHiding then
			return
		end
		if visible and activeTarget == guiObj then
			placeNear(guiObj, opts)
			return
		end

		cancelShowThread()
		cancelHideThread()
		isHiding = false

		if not ensureGui() then
			return
		end

		layoutFrame(title, desc, metaText)
		frame.Visible = true
		frame.BackgroundTransparency = 0.04
		titleLabel.TextTransparency = 0
		descLabel.TextTransparency = 0
		uiScale.Scale = 1
		placeNear(guiObj, opts)
		task.defer(function()
			if guiObj.Parent and activeTarget == guiObj then
				placeNear(guiObj, opts)
			end
		end)

		visible = true
		activeTarget = guiObj
		stats.shown = stats.shown + 1
	end

	local FRAME_KEYS = {
		"ElementFrame",
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
			return el
		end
		if type(el) ~= "table" then
			return nil
		end

		if typeof(el.ElementFrame) == "Instance" then
			return el.ElementFrame
		end
		if el.UIElements and typeof(el.UIElements.Main) == "Instance" then
			return el.UIElements.Main
		end
		for _, key in ipairs(FRAME_KEYS) do
			local frameObj = el[key]
			if typeof(frameObj) == "Instance" then
				return frameObj
			end
			if type(frameObj) == "table" and frameObj.UIElements and typeof(frameObj.UIElements.Main) == "Instance" then
				return frameObj.UIElements.Main
			end
		end
		for _, key in ipairs({ "Main", "Frame", "Button", "Holder", "Root" }) do
			if typeof(el[key]) == "Instance" then
				return el[key]
			end
		end
		return nil
	end

	local function prepareTarget(guiObj)
		if not guiObj or not guiObj:IsA("GuiObject") then
			return
		end
		pcall(function()
			guiObj.Active = true
		end)
	end

	local function pointInside(guiObj, mousePos)
		if not guiObj or not guiObj.Parent or not guiObj.Visible then
			return false
		end
		local ap = guiObj.AbsolutePosition
		local as = guiObj.AbsoluteSize
		if as.X < 2 or as.Y < 2 then
			return false
		end
		return mousePos.X >= ap.X and mousePos.X <= ap.X + as.X
			and mousePos.Y >= ap.Y and mousePos.Y <= ap.Y + as.Y
	end

	local function startPolling()
		if pollConn then
			return
		end
		pollConn = RunService.Heartbeat:Connect(function()
			local now = tick()
			if now - lastPoll < POLL_INTERVAL then
				return
			end
			lastPoll = now

			if #registryList < 1 then
				return
			end

			local mousePos = UserInputService:GetMouseLocation()
			local hit = nil
			local hitDepth = -1

			for i = #registryList, 1, -1 do
				local entry = registryList[i]
				local obj = entry.target
				if obj and obj.Parent and pointInside(obj, mousePos) then
					local depth = 0
					pcall(function()
						local n = obj
						while n and n.Parent do
							depth = depth + 1
							n = n.Parent
						end
					end)
					if depth > hitDepth then
						hitDepth = depth
						hit = entry
					end
				end
			end

			if not hit then
				pendingTarget = nil
				pendingSince = 0
				if visible then
					TooltipManager.hide()
				end
				return
			end

			if pendingTarget ~= hit.target then
				pendingTarget = hit.target
				pendingSince = now
				cancelShowThread()
				return
			end

			if not visible and (now - pendingSince) >= HOVER_DELAY then
				local title, desc, metaText = TooltipManager.resolve(hit.meta, hit.kind, hit.section, hit.label)
				TooltipManager.show(hit.target, title, desc, metaText, hit.opts)
			elseif visible and activeTarget == hit.target then
				placeNear(hit.target, hit.opts)
			end
		end)
		stats.connections = stats.connections + 1
	end

	function TooltipManager.attach(el, meta, controlType, sectionName, label)
		local function tryRegister()
			local guiObj = findHoverTarget(el)
			if not guiObj or not guiObj.Parent then
				return false
			end
			if registryMap[guiObj] then
				return true
			end

			prepareTarget(guiObj)
			local opts = {}
			if type(meta) == "table" then
				for k, v in pairs(meta) do
					opts[k] = v
				end
			end
			if controlType == "tab" or opts.placement == "sidebar" then
				opts.placement = "sidebar"
			end

			local entry = {
				target = guiObj,
				meta = meta,
				opts = opts,
				kind = controlType,
				section = sectionName,
				label = label,
			}
			registryMap[guiObj] = entry
			table.insert(registryList, entry)
			stats.attached = stats.attached + 1
			guiObj:SetAttribute("AlleralTooltipBound", true)
			startPolling()
			return true
		end

		if tryRegister() then
			return
		end

		task.spawn(function()
			for _ = 1, 30 do
				if tryRegister() then
					return
				end
				task.wait(0.1)
			end
			stats.failed = stats.failed + 1
		end)
	end

	function TooltipManager.attachTab(windTab, name)
		if not windTab then
			return
		end
		task.defer(function()
			TooltipManager.attach(windTab, {
				title = name,
				description = "Switch to the " .. Bootstrap.sanitize(name, 48) .. " tab.",
				placement = "sidebar",
			}, "tab", nil, name)
		end)
	end

	function TooltipManager.init()
		ensureGui()
		startPolling()
		pcall(function()
			local Log = getgenv and getgenv().Alleral_Log
			if Log and Log.info then
				Log.info("TooltipManager ready (mouse polling)")
				Log.info("Tooltip recursion guard active")
			end
		end)
	end

	function TooltipManager.getStats()
		return {
			attached = stats.attached,
			shown = stats.shown,
			visible = visible,
			connections = stats.connections,
			failed = stats.failed,
			registered = stats.attached,
			activeId = activeTarget and tostring(activeTarget) or nil,
		}
	end

	function TooltipManager.suppressDuringDrag()
		cancelShowThread()
		pendingTarget = nil
		TooltipManager.hide()
	end

	return TooltipManager
end