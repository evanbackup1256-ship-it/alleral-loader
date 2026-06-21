-- Alleral Noble V10 — application shell (EXE-6 / VisionOS premium desktop)
return function(deps)
	local Theme = deps.Theme
	local Spr = deps.Spr
	local Util = deps.Util
	local Layout = deps.Layout or deps.Util
	local Motion = deps.Motion
	local Components = deps.Components
	local Janitor = deps.Janitor
	local Signal = deps.Signal
	local Fusion = deps.Fusion
	local Validation = deps.Validation
	local DropdownManager = deps.DropdownManager
	local AnimationManager = deps.AnimationManager
	local ZIndex = deps.ZIndex

	local UserInputService = game:GetService("UserInputService")
	local Players = game:GetService("Players")
	local RunService = game:GetService("RunService")
	local Stats = game:GetService("Stats")

	local Window = {}
	Window.__index = Window

	local SIDEBAR_ICONS = {
		Dashboard = "◌",
		Kick = "⌂",
		Plot = "▷",
		Events = "▣",
		Inventory = "▣",
		Misc = "⚙",
		Settings = "⚙",
		Configs = "◈",
		Tools = "✦",
	}

	local function debounce(fn, delay)
		delay = delay or 0.03
		local scheduled = false
		local argsCache
		return function(...)
			argsCache = { ... }
			if scheduled then return end
			scheduled = true
			task.delay(delay, function()
				scheduled = false
				pcall(fn, table.unpack(argsCache))
			end)
		end
	end

	local function safeVis(obj, vis)
		if typeof(obj) == "Instance" and obj:IsA("GuiObject") then
			obj.Visible = vis == true
		end
	end

	local function keyName(keyCode)
		local name = tostring(keyCode):gsub("Enum.KeyCode.", "")
		if name == "LeftControl" or name == "RightControl" then return "Ctrl" end
		if name == "LeftShift" or name == "RightShift" then return "Shift" end
		if name == "RightShift" then return "RightShift" end
		return name
	end

	local function num(value, fallback, label)
		if Layout and Layout.num then return Layout.num(value, fallback, label) end
		local n = tonumber(value)
		if n == nil then
			if label then warn("[Alleral V10] Missing numeric:", label, "→", fallback) end
			return fallback
		end
		return n
	end

	local function absSize(gui, fw, fh)
		if Layout and Layout.absSize then return Layout.absSize(gui, fw, fh) end
		fw, fh = num(fw, 1200, nil), num(fh, 720, nil)
		if typeof(gui) ~= "Instance" or not gui:IsA("GuiObject") then return fw, fh end
		local w = num(gui.AbsoluteSize.X, 0, nil)
		local h = num(gui.AbsoluteSize.Y, 0, nil)
		if w <= 0 then w = fw end
		if h <= 0 then h = fh end
		return w, h
	end

	local function getViewport()
		local cam = workspace.CurrentCamera
		if cam then
			local vp = cam.ViewportSize
			return num(vp.X, 1920, "ViewportSize.X"), num(vp.Y, 1080, "ViewportSize.Y")
		end
		return 1920, 1080
	end

	local function computeResponsiveScale(vpX, vpY)
		vpX = num(vpX, 1920, "vpX")
		vpY = num(vpY, 1080, "vpY")
		local baseW, baseH = 1180, 700
		local scaleX = vpX / baseW
		local scaleY = vpY / baseH
		local scale = math.min(scaleX, scaleY)
		if vpX < 900 or vpY < 600 then
			scale = math.min(scale, 0.72)
		elseif vpX < 1100 then
			scale = math.min(scale, 0.82)
		elseif vpX > 2200 then
			scale = math.min(scale, 1.08)
		end
		return Util.clamp(scale, 0.58, 1.12)
	end

	local function formatUptime(seconds)
		seconds = math.floor(tonumber(seconds) or 0)
		local h = math.floor(seconds / 3600)
		local m = math.floor((seconds % 3600) / 60)
		local s = seconds % 60
		return string.format("%02d:%02d:%02d", h, m, s)
	end

	local function formatMemory()
		local kb = collectgarbage("count")
		if kb > 1024 then
			return string.format("%.1f MB", kb / 1024)
		end
		return string.format("%.0f KB", kb)
	end

	local function getExecutorName()
		local ok, name = pcall(function()
			if identifyexecutor then
				return identifyexecutor()
			end
			return nil
		end)
		if ok and type(name) == "string" and name ~= "" then
			return name
		end
		return "Unknown"
	end

	local function callComponent(kind, parent, ...)
		if not Components or type(Components[kind]) ~= "function" then return nil end
		local args = { ... }
		if kind == "Label" then
			return Components.Label({ Parent = parent, Text = args[1] })
		elseif kind == "Divider" then
			return Components.Divider({ Parent = parent })
		elseif kind == "Button" then
			local props = args[1] or {}
			return Components.Button({ Parent = parent, Text = props.Text, Callback = props.Func or props.Callback })
		elseif kind == "Toggle" then
			local flag, props = args[1], args[2] or {}
			return Components.Toggle({ Parent = parent, Text = props.Text or flag, Default = props.Default, Callback = props.Callback })
		elseif kind == "Slider" then
			local flag, props = args[1], args[2] or {}
			return Components.Slider({
				Parent = parent,
				Text = props.Text or flag,
				Min = props.Min or 0,
				Max = props.Max or 100,
				Default = props.Default or props.Min or 0,
				Suffix = props.Suffix,
				Rounding = props.Rounding or 1,
				Callback = props.Callback,
			})
		elseif kind == "Input" then
			local flag, props = args[1], args[2] or {}
			return Components.Input({
				Parent = parent,
				Text = props.Text or flag,
				Default = props.Default,
				Placeholder = props.Placeholder,
				Callback = props.Callback,
			})
		elseif kind == "Dropdown" then
			local flag, props, dropLayer = args[1], args[2] or {}, args[3]
			return Components.Dropdown({
				Parent = parent,
				DropLayer = dropLayer,
				Text = props.Text or flag,
				Values = props.Values or props.Options,
				Default = props.Default,
				Multi = props.Multi,
				Searchable = props.Searchable,
				Callback = props.Callback,
			})
		end
		return nil
	end

	local function stubControl()
		return {
			Set = function() end,
			SetText = function() end,
			SetVisible = function() end,
			SetValue = function() end,
			Refresh = function() end,
		}
	end

	local function createGroup(ctx, parent, title, columnWidth)
		local width = num(columnWidth, 360, "columnWidth")
		local card = Util.make("Frame", {
			Size = UDim2.fromOffset(width, 0),
			BackgroundColor3 = Theme.COLOR.Surface1,
			BackgroundTransparency = 0.02,
			BorderSizePixel = 0,
			AutomaticSize = Enum.AutomaticSize.Y,
			ClipsDescendants = true,
			Parent = parent,
		})
		Util.corner(card, Theme.RADIUS.Card)
		if Layout and Layout.shadow then Layout.shadow(card, Theme.RADIUS.Card, 2, 0.65) end
		Util.make("Frame", {
			Size = UDim2.new(1, 0, 0, 1),
			BackgroundColor3 = Theme.COLOR.Accent,
			BackgroundTransparency = 0.6,
			BorderSizePixel = 0,
			ZIndex = 2,
			Parent = card,
		})
		card.MouseEnter:Connect(function()
			Util.safeSprTarget(card, Theme.SPRING.SNAPPY[1], Theme.SPRING.SNAPPY[2], { BackgroundTransparency = 0 })
		end)
		card.MouseLeave:Connect(function()
			Util.safeSprTarget(card, Theme.SPRING.SNAPPY[1], Theme.SPRING.SNAPPY[2], { BackgroundTransparency = 0.02 })
		end)

		local titleBar = Util.make("Frame", {
			Size = UDim2.new(1, 0, 0, Theme.CARD.TITLE_H),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			Parent = card,
		})
		Util.make("TextLabel", {
			Size = UDim2.new(1, -Theme.CARD.PAD * 2, 1, 0),
			Position = UDim2.new(0, Theme.CARD.PAD, 0, 0),
			BackgroundTransparency = 1,
			Text = tostring(title or "Group"),
			TextColor3 = Theme.COLOR.TEXT,
			Font = Theme.FONT_BOLD,
			TextSize = Theme.TEXT_TITLE,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextYAlignment = Enum.TextYAlignment.Center,
			Parent = titleBar,
		})

		local content = Util.make("Frame", {
			Size = UDim2.new(1, 0, 0, 0),
			Position = UDim2.new(0, 0, 0, Theme.CARD.TITLE_H),
			BackgroundTransparency = 1,
			AutomaticSize = Enum.AutomaticSize.Y,
			Parent = card,
		})
		Util.padding(content, Theme.CARD.PAD, Theme.CARD.PAD, 0, Theme.CARD.PAD)

		local list = Util.make("UIListLayout", {
			Padding = UDim.new(0, Theme.CONTROL.GAP),
			SortOrder = Enum.SortOrder.LayoutOrder,
			Parent = content,
		})

		local function calculateHeight()
			local contentH = num(list.AbsoluteContentSize.Y, 0, "groupContentH")
			return math.max(96, num(Theme.CARD.TITLE_H, 40, nil) + contentH + num(Theme.CARD.PAD, 16, nil) * 2 + 4)
		end

		local updateSize = debounce(function()
			if not card.Parent then return end
			card.Size = UDim2.fromOffset(width, calculateHeight())
		end, 0.025)

		list:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(updateSize)
		if parent and parent.GetPropertyChangedSignal then
			parent:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
				local newW = absSize(parent, width, 0)
				if newW > 80 then
					width = newW
					updateSize()
				end
			end)
		end
		task.defer(updateSize)

		local groupPath = (ctx.tabName or "Tab") .. " / " .. tostring(title or "Group")

		local function registerControl(label, action)
			if ctx.search and type(ctx.search.register) == "function" then
				ctx.search:register({
					label = label,
					path = groupPath,
					keywords = groupPath .. " " .. Util.textOf(label),
					action = action,
				})
			end
		end

		local groupAPI = {
			_card = card,
			_content = content,
			ForceResize = updateSize,
			UpdateSize = updateSize,
			AddLabel = function(_, text)
				local ctrl = callComponent("Label", content, text) or stubControl()
				registerControl(text, nil)
				updateSize()
				return ctrl
			end,
			CreateLabel = function(_, spec)
				local text = type(spec) == "table" and (spec.Name or spec.Text) or tostring(spec or "")
				return groupAPI:AddLabel(text)
			end,
			AddToggle = function(_, flag, props)
				props = type(props) == "table" and props or {}
				local label = props.Text or flag
				local ctrl = callComponent("Toggle", content, flag, props) or stubControl()
				registerControl(label, function()
					if type(props.Callback) == "function" then props.Callback(not props.Default) end
				end)
				updateSize()
				return ctrl
			end,
			AddSlider = function(_, flag, props)
				props = type(props) == "table" and props or {}
				local ctrl = callComponent("Slider", content, flag, props) or stubControl()
				registerControl(props.Text or flag, nil)
				updateSize()
				return ctrl
			end,
			AddButton = function(_, props)
				props = type(props) == "table" and props or {}
				local label = props.Text or "Button"
				local ctrl = callComponent("Button", content, props) or stubControl()
				registerControl(label, props.Func or props.Callback)
				updateSize()
				return ctrl
			end,
			AddInput = function(_, flag, props)
				props = type(props) == "table" and props or {}
				local ctrl = callComponent("Input", content, flag, props) or stubControl()
				registerControl(props.Text or flag, nil)
				updateSize()
				return ctrl
			end,
			AddDropdown = function(_, flag, props)
				props = type(props) == "table" and props or {}
				local ctrl = callComponent("Dropdown", content, flag, props, ctx.dropLayer) or stubControl()
				registerControl(props.Text or flag, nil)
				updateSize()
				return ctrl
			end,
			AddDivider = function()
				callComponent("Divider", content)
				updateSize()
				return {}
			end,
		}

		return groupAPI
	end

	local function createTab(window, name, iconId, columns)
		columns = Util.clamp(tonumber(columns) or 2, 1, 3)
		local contentArea = window._contentArea

		local panel = Util.make("Frame", {
			Size = UDim2.new(1, 0, 1, 0),
			BackgroundTransparency = 1,
			Visible = false,
			Parent = contentArea,
		})

		local scroll = Util.make("ScrollingFrame", {
			Size = UDim2.new(1, 0, 1, 0),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			CanvasSize = UDim2.new(0, 0, 0, 0),
			AutomaticCanvasSize = Enum.AutomaticSize.Y,
			ScrollingDirection = Enum.ScrollingDirection.Y,
			ClipsDescendants = true,
			Parent = panel,
		})
		Util.styleScroll(scroll)
		Util.padding(scroll, Theme.WINDOW.PADDING, Theme.WINDOW.PADDING, Theme.WINDOW.PADDING, Theme.WINDOW.PADDING)

		local holder = Util.make("Frame", {
			Size = UDim2.new(1, 0, 0, 0),
			BackgroundTransparency = 1,
			AutomaticSize = Enum.AutomaticSize.Y,
			Parent = scroll,
		})

		Util.make("UIListLayout", {
			Padding = UDim.new(0, Theme.CARD.GAP),
			SortOrder = Enum.SortOrder.LayoutOrder,
			FillDirection = Enum.FillDirection.Horizontal,
			Parent = holder,
		})

		local colFrames = {}
		local function computeColumnWidths()
			if not contentArea or not contentArea.Parent then return end
			local areaW = absSize(contentArea, 900, 0)
			local pad = num(Theme.WINDOW.PADDING, 16, "WINDOW.PADDING")
			local gap = num(Theme.CARD.GAP, 14, "CARD.GAP")
			local available = math.max(520, areaW - pad * 2)
			local gapTotal = (columns - 1) * gap
			local cw = math.floor((available - gapTotal) / columns)
			cw = Util.clamp(cw, 220, 500)
			for _, cf in ipairs(colFrames) do
				cf.Size = UDim2.fromOffset(cw, 0)
			end
		end

		local areaW0 = absSize(contentArea, 900, 0)
		local pad0 = num(Theme.WINDOW.PADDING, 16, nil)
		local gap0 = num(Theme.CARD.GAP, 14, nil)
		local initialCW = math.max(260, math.floor((areaW0 - pad0 * 2 - (columns - 1) * gap0) / columns))
		for i = 1, columns do
			local cf = Util.make("Frame", {
				Size = UDim2.fromOffset(initialCW, 0),
				BackgroundTransparency = 1,
				AutomaticSize = Enum.AutomaticSize.Y,
				LayoutOrder = i,
				Parent = holder,
			})
			Util.make("UIListLayout", {
				Padding = UDim.new(0, Theme.CARD.GAP),
				SortOrder = Enum.SortOrder.LayoutOrder,
				Parent = cf,
			})
			colFrames[i] = cf
		end

		contentArea:GetPropertyChangedSignal("AbsoluteSize"):Connect(computeColumnWidths)
		task.defer(computeColumnWidths)

		local ctx = {
			tabName = name,
			search = window._search,
			dropLayer = window._dropLayer,
		}

		local tabAPI = {
			_panel = panel,
			_scroll = scroll,
			_columns = columns,
			_colFrames = colFrames,
			_name = name,
			_icon = iconId,
			_window = window,
			ForceColumnResize = computeColumnWidths,
			Select = function(self)
				window:selectTab(self)
			end,
			AddLeftGroupbox = function(_, groupName)
				if not colFrames[1] then return nil end
				local w = absSize(colFrames[1], initialCW, 0)
				return createGroup(ctx, colFrames[1], groupName, w)
			end,
			AddRightGroupbox = function(_, groupName)
				local idx = math.min(2, #colFrames)
				if not colFrames[idx] then return nil end
				local w = absSize(colFrames[idx], initialCW, 0)
				return createGroup(ctx, colFrames[idx], groupName, w)
			end,
			AddGroupbox = function(_, groupName)
				local shortest = colFrames[1]
				for _, cf in ipairs(colFrames) do
					local _, sh = absSize(shortest, 0, 9999)
					local _, ch = absSize(cf, 0, 9999)
					if ch < sh then shortest = cf end
				end
				local w = absSize(shortest, initialCW, 0)
				return createGroup(ctx, shortest, groupName, w)
			end,
		}

		return tabAPI
	end

	function Window.new(settings)
		settings = type(settings) == "table" and settings or {}
		local self = setmetatable({}, Window)
		self._janitor = Janitor.new()
		self._settings = settings
		self._tabs = {}
		self._activeTab = nil
		self._hidden = false
		self._toggleKey = settings.Keybind or Theme.KEYBIND
		self._openedAt = os.clock()
		self.TabAdded = Signal.new()
		self.TabSelected = Signal.new()
		self.VisibilityChanged = Signal.new()

		local size = settings.Size or Theme.WINDOW.DEFAULT
		local title = settings.Title or settings.Name or "Alleral"

		local screen = Util.make("ScreenGui", {
			Name = settings.ScreenName or "AlleralV10",
			ResetOnSpawn = false,
			IgnoreGuiInset = true,
			ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
			DisplayOrder = settings.DisplayOrder or 100,
			Parent = settings.Parent or game:GetService("CoreGui"),
		})

		if Validation and not Validation.isScreenGui(screen) then
			Validation.bootPrint("ScreenGui must be parented before building window UI")
		end

		local dropdownManager = DropdownManager and DropdownManager.new(screen) or nil
		local dropLayer = dropdownManager and dropdownManager:getLayer() or nil

		local dim = Util.make("Frame", {
			Name = "Dim",
			Size = UDim2.new(1, 0, 1, 0),
			BackgroundColor3 = Color3.fromRGB(3, 6, 14),
			BackgroundTransparency = 0.38,
			BorderSizePixel = 0,
			ZIndex = 1,
			Parent = screen,
		})

		local rootScale = Util.make("UIScale", { Scale = 1, Parent = screen })

		local main = Util.make("Frame", {
			Name = "Main",
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = size,
			BackgroundColor3 = Theme.COLOR.BG1,
			BorderSizePixel = 0,
			ClipsDescendants = true,
			ZIndex = 2,
			Parent = screen,
		})
		Util.corner(main, Theme.RADIUS.Window)
		if Layout and Layout.shadow then Layout.shadow(main, Theme.RADIUS.Window, 3, 0.5) end
		Util.gradient(main, Theme.COLOR.BG1, Theme.COLOR.BG2, 180)

		local mainScale = Util.scale(main)
		mainScale.Scale = settings.StartHidden and 0.92 or 1

		local topH = num(Theme.TOPBAR.H, 64, "TOPBAR.H")
		local winPad = num(Theme.WINDOW.PADDING, 16, "WINDOW.PADDING")

		local topBar = Util.make("Frame", {
			Name = "TopBar",
			Size = UDim2.new(1, 0, 0, topH),
			BackgroundColor3 = Theme.COLOR.BG1,
			BackgroundTransparency = 0.04,
			BorderSizePixel = 0,
			ZIndex = 10,
			Parent = main,
		})
		Util.make("Frame", {
			Size = UDim2.new(1, 0, 0, 1),
			Position = UDim2.new(0, 0, 1, 0),
			BackgroundColor3 = Theme.COLOR.BorderSoft,
			BackgroundTransparency = 0.55,
			BorderSizePixel = 0,
			ZIndex = 11,
			Parent = topBar,
		})

		local logo = Util.make("Frame", {
			Size = UDim2.fromOffset(32, 32),
			Position = UDim2.new(0, winPad, 0.5, -16),
			BackgroundColor3 = Theme.COLOR.Surface1,
			BorderSizePixel = 0,
			ZIndex = 12,
			Parent = topBar,
		})
		Util.corner(logo, Theme.RADIUS.Button)
		if Layout and Layout.softStroke then Layout.softStroke(logo, Theme.COLOR.AccentSoft) end
		Util.make("TextLabel", {
			Size = UDim2.new(1, 0, 1, 0),
			BackgroundTransparency = 1,
			Text = string.sub(title, 1, 1):upper(),
			TextColor3 = Theme.COLOR.Accent,
			Font = Theme.FONT_BOLD,
			TextSize = 15,
			TextXAlignment = Enum.TextXAlignment.Center,
			TextYAlignment = Enum.TextYAlignment.Center,
			ZIndex = 13,
			Parent = logo,
		})

		local titleLabel = Util.make("TextLabel", {
			Size = UDim2.new(0, 0, 1, 0),
			Position = UDim2.new(0, winPad + 40, 0, 0),
			BackgroundTransparency = 1,
			Text = title,
			TextColor3 = Theme.COLOR.Text,
			Font = Theme.FONT_BOLD,
			TextSize = Theme.TEXT_HEADER,
			AutomaticSize = Enum.AutomaticSize.X,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextYAlignment = Enum.TextYAlignment.Center,
			ZIndex = 12,
			Parent = topBar,
		})

		local verBadge = Util.make("Frame", {
			Size = UDim2.fromOffset(46, 18),
			Position = UDim2.new(0, winPad + 120, 0.5, -9),
			BackgroundColor3 = Theme.COLOR.Surface2,
			BackgroundTransparency = 0.15,
			BorderSizePixel = 0,
			ZIndex = 12,
			Parent = topBar,
		})
		Util.corner(verBadge, Theme.RADIUS.Pill)
		Util.make("TextLabel", {
			Size = UDim2.new(1, 0, 1, 0),
			BackgroundTransparency = 1,
			Text = "v" .. Theme.VERSION,
			TextColor3 = Theme.COLOR.Accent,
			Font = Theme.FONT_BOLD,
			TextSize = 10,
			TextXAlignment = Enum.TextXAlignment.Center,
			TextYAlignment = Enum.TextYAlignment.Center,
			ZIndex = 13,
			Parent = verBadge,
		})

		local function createChip(parent, text, x, dotColor)
			local chip = Util.make("Frame", {
				Size = UDim2.fromOffset(0, 22),
				Position = UDim2.new(0, num(x, 0, "chipX"), 0.5, -11),
				BackgroundColor3 = Theme.COLOR.Surface1,
				BackgroundTransparency = 0.2,
				BorderSizePixel = 0,
				AutomaticSize = Enum.AutomaticSize.X,
				ZIndex = 12,
				Parent = parent,
			})
			Util.corner(chip, Theme.RADIUS.Pill)
			Util.padding(chip, 8, 10, 0, 0)
			Util.make("Frame", {
				Size = UDim2.fromOffset(6, 6),
				Position = UDim2.new(0, 8, 0.5, -3),
				BackgroundColor3 = dotColor or Theme.COLOR.Green,
				BorderSizePixel = 0,
				ZIndex = 13,
				Parent = chip,
			})
			local lbl = Util.make("TextLabel", {
				Size = UDim2.new(0, 0, 1, 0),
				Position = UDim2.new(0, 18, 0, 0),
				BackgroundTransparency = 1,
				Text = text,
				TextColor3 = Theme.COLOR.TextMuted,
				Font = Theme.FONT,
				TextSize = 10,
				AutomaticSize = Enum.AutomaticSize.X,
				TextXAlignment = Enum.TextXAlignment.Left,
				TextYAlignment = Enum.TextYAlignment.Center,
				ZIndex = 13,
				Parent = chip,
			})
			return chip, lbl
		end

		local chipStart = winPad + 200
		local playerPill, playerLabel = createChip(topBar, "0 Players", chipStart, Theme.COLOR.Green)
		local uptimePill, uptimeLabel = createChip(topBar, "00:00:00", chipStart + 108, Theme.COLOR.Blue)
		local readyPill, readyLabel = createChip(topBar, "Ready", chipStart + 200, Theme.COLOR.Green)

		local keybindLabel = Util.make("TextLabel", {
			Size = UDim2.fromOffset(120, topH),
			Position = UDim2.new(0, chipStart + 290, 0, 0),
			BackgroundTransparency = 1,
			Text = keyName(self._toggleKey),
			TextColor3 = Theme.COLOR.TextDim,
			Font = Theme.FONT,
			TextSize = 10,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextYAlignment = Enum.TextYAlignment.Center,
			ZIndex = 12,
			Parent = topBar,
		})

		local closeBtn = Util.make("TextButton", {
			Size = UDim2.fromOffset(28, 28),
			Position = UDim2.new(1, -winPad - 4, 0.5, -14),
			BackgroundColor3 = Theme.COLOR.Surface2,
			BorderSizePixel = 0,
			Text = "✕",
			TextColor3 = Theme.COLOR.TextMuted,
			Font = Theme.FONT_BOLD,
			TextSize = 14,
			AutoButtonColor = false,
			ZIndex = 12,
			Parent = topBar,
		})
		Util.corner(closeBtn, Theme.RADIUS.Button)
		local closeScale = Util.scale(closeBtn)

		local miniBtn = Util.make("TextButton", {
			Size = UDim2.fromOffset(28, 28),
			Position = UDim2.new(1, -winPad - 36, 0.5, -14),
			BackgroundColor3 = Theme.COLOR.Surface1,
			BorderSizePixel = 0,
			Text = "–",
			TextColor3 = Theme.COLOR.TextMuted,
			Font = Theme.FONT_BOLD,
			TextSize = 16,
			AutoButtonColor = false,
			ZIndex = 12,
			Parent = topBar,
		})
		Util.corner(miniBtn, Theme.RADIUS.Button)
		local miniScale = Util.scale(miniBtn)

		closeBtn.MouseEnter:Connect(function()
			Util.safeSprTarget(closeScale, Theme.SPRING.SNAPPY[1], Theme.SPRING.SNAPPY[2], { Scale = 1.04 })
			Util.safeSprTarget(closeBtn, Theme.SPRING.SNAPPY[1], Theme.SPRING.SNAPPY[2], { BackgroundColor3 = Theme.COLOR.Red, TextColor3 = Theme.COLOR.White })
		end)
		closeBtn.MouseLeave:Connect(function()
			Util.safeSprTarget(closeScale, Theme.SPRING.SNAPPY[1], Theme.SPRING.SNAPPY[2], { Scale = 1 })
			Util.safeSprTarget(closeBtn, Theme.SPRING.SNAPPY[1], Theme.SPRING.SNAPPY[2], { BackgroundColor3 = Theme.COLOR.Surface2, TextColor3 = Theme.COLOR.TextMuted })
		end)
		miniBtn.MouseEnter:Connect(function()
			Util.safeSprTarget(miniScale, Theme.SPRING.SNAPPY[1], Theme.SPRING.SNAPPY[2], { Scale = 1.03 })
			Util.safeSprTarget(miniBtn, Theme.SPRING.SNAPPY[1], Theme.SPRING.SNAPPY[2], { BackgroundColor3 = Theme.COLOR.Surface2 })
		end)
		miniBtn.MouseLeave:Connect(function()
			Util.safeSprTarget(miniScale, Theme.SPRING.SNAPPY[1], Theme.SPRING.SNAPPY[2], { Scale = 1 })
			Util.safeSprTarget(miniBtn, Theme.SPRING.SNAPPY[1], Theme.SPRING.SNAPPY[2], { BackgroundColor3 = Theme.COLOR.Surface1 })
		end)

		local tabH = num(Theme.TOPBAR.TAB_H, 36, "TOPBAR.TAB_H")
		local sideW = num(Theme.SIDEBAR.W, 196, "SIDEBAR.W")
		local statusH = num(Theme.STATUSBAR.H, 36, "STATUSBAR.H")
		local bodyTop = topH + tabH + 12

		local tabStrip = Util.make("ScrollingFrame", {
			Name = "TabStrip",
			Size = UDim2.new(1, -(sideW + winPad * 3), 0, tabH + 4),
			Position = UDim2.new(0, sideW + winPad * 2, 0, topH + 6),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			ScrollBarThickness = 0,
			CanvasSize = UDim2.new(0, 0, 0, 0),
			AutomaticCanvasSize = Enum.AutomaticSize.X,
			ScrollingDirection = Enum.ScrollingDirection.X,
			ClipsDescendants = true,
			ZIndex = 8,
			Parent = main,
		})
		local tabList = Util.make("UIListLayout", {
			Padding = UDim.new(0, 8),
			FillDirection = Enum.FillDirection.Horizontal,
			VerticalAlignment = Enum.VerticalAlignment.Center,
			SortOrder = Enum.SortOrder.LayoutOrder,
			Parent = tabStrip,
		})
		Util.padding(tabStrip, 0, 0, 4, 0)

		local sidebar = Util.make("ScrollingFrame", {
			Name = "Sidebar",
			Size = UDim2.new(0, sideW, 1, -(bodyTop + statusH + winPad)),
			Position = UDim2.new(0, winPad, 0, bodyTop),
			BackgroundColor3 = Theme.COLOR.BG1,
			BackgroundTransparency = 0.08,
			BorderSizePixel = 0,
			ScrollBarThickness = 0,
			CanvasSize = UDim2.new(0, 0, 0, 0),
			AutomaticCanvasSize = Enum.AutomaticSize.Y,
			ScrollingDirection = Enum.ScrollingDirection.Y,
			ClipsDescendants = true,
			ZIndex = 7,
			Parent = main,
		})
		Util.make("Frame", {
			Size = UDim2.new(0, 1, 1, 0),
			Position = UDim2.new(1, 0, 0, 0),
			BackgroundColor3 = Theme.COLOR.BorderSoft,
			BackgroundTransparency = 0.6,
			BorderSizePixel = 0,
			ZIndex = 8,
			Parent = sidebar,
		})
		Util.styleScroll(sidebar)
		Util.make("UIListLayout", {
			Padding = UDim.new(0, 8),
			SortOrder = Enum.SortOrder.LayoutOrder,
			Parent = sidebar,
		})
		Util.padding(sidebar, Theme.SIDEBAR.PAD, Theme.SIDEBAR.PAD, Theme.SIDEBAR.PAD, Theme.SIDEBAR.PAD)

		local contentArea = Util.make("Frame", {
			Name = "Content",
			Size = UDim2.new(1, -(sideW + winPad * 3), 1, -(bodyTop + statusH + winPad)),
			Position = UDim2.new(0, sideW + winPad * 2, 0, bodyTop),
			BackgroundColor3 = Theme.COLOR.Background0,
			BackgroundTransparency = 0,
			BorderSizePixel = 0,
			ClipsDescendants = false,
			ZIndex = ZIndex and ZIndex.Cards or 20,
			Parent = main,
		})

		if not dropLayer then
			dropLayer = Util.make("Frame", {
				Name = "DropLayer",
				Size = UDim2.new(1, 0, 1, 0),
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				ClipsDescendants = false,
				ZIndex = ZIndex and ZIndex.DropdownOverlay or 100,
				Parent = screen,
			})
		end

		local statusBar = Util.make("Frame", {
			Name = "StatusBar",
			Size = UDim2.new(1, -winPad * 2, 0, statusH),
			Position = UDim2.new(0, winPad, 1, -statusH - 6),
			BackgroundColor3 = Theme.COLOR.BG1,
			BackgroundTransparency = 0.12,
			BorderSizePixel = 0,
			ZIndex = 9,
			Parent = main,
		})
		Util.make("Frame", {
			Size = UDim2.new(1, 0, 0, 1),
			BackgroundColor3 = Theme.COLOR.BorderSoft,
			BackgroundTransparency = 0.55,
			BorderSizePixel = 0,
			ZIndex = 10,
			Parent = statusBar,
		})

		local statusLeft = Util.make("TextLabel", {
			Size = UDim2.new(0.22, 0, 1, 0),
			Position = UDim2.new(0, 14, 0, 0),
			BackgroundTransparency = 1,
			Text = "● UI Ready",
			TextColor3 = Theme.COLOR.GREEN,
			Font = Theme.FONT_BOLD,
			TextSize = Theme.TEXT_SM,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextYAlignment = Enum.TextYAlignment.Center,
			ZIndex = 10,
			Parent = statusBar,
		})

		local statusCenter = Util.make("TextLabel", {
			Size = UDim2.new(0.36, 0, 1, 0),
			Position = UDim2.new(0.22, 0, 0, 0),
			BackgroundTransparency = 1,
			Text = getExecutorName(),
			TextColor3 = Theme.COLOR.TEXT2,
			Font = Theme.FONT,
			TextSize = Theme.TEXT_SM,
			TextXAlignment = Enum.TextXAlignment.Center,
			TextYAlignment = Enum.TextYAlignment.Center,
			ZIndex = 10,
			Parent = statusBar,
		})

		local statusRight = Util.make("TextLabel", {
			Size = UDim2.new(0.42, -14, 1, 0),
			Position = UDim2.new(0.58, 0, 0, 0),
			BackgroundTransparency = 1,
			Text = "",
			TextColor3 = Theme.COLOR.TEXT3,
			Font = Theme.FONT,
			TextSize = Theme.TEXT_SM,
			TextXAlignment = Enum.TextXAlignment.Right,
			TextYAlignment = Enum.TextYAlignment.Center,
			ZIndex = 10,
			Parent = statusBar,
		})

		self._screen = screen
		self._dim = dim
		self._main = main
		self._mainScale = mainScale
		self._rootScale = rootScale
		self._topBar = topBar
		self._sidebar = sidebar
		self._tabStrip = tabStrip
		self._contentArea = contentArea
		self._dropLayer = dropLayer
		self._dropdownManager = dropdownManager
		self._statusBar = statusBar
		self._keybindLabel = keybindLabel

		sidebar.CanvasPosition = Vector2.new(0, 0)
		tabStrip.CanvasPosition = Vector2.new(0, 0)

		-- Search overlay (optional dep passed via settings.Search factory)
		if settings.Search and type(settings.Search.new) == "function" then
			self._search = settings.Search.new({
				parent = screen,
				keybind = settings.SearchKeybind or Theme.SEARCH_KEY or Enum.KeyCode.K,
				modifiers = settings.SearchModifiers or { Ctrl = true },
			})
			if settings.Search.setInstance then
				settings.Search.setInstance(self._search)
			end
			self._janitor:Add(self._search, "Destroy")
		end

		local function styleTab(tab, active)
			if tab._sidebarBtn then
				Util.safeSprTarget(tab._sidebarBtn, Theme.SPRING.SNAPPY[1], Theme.SPRING.SNAPPY[2], {
					BackgroundColor3 = Theme.COLOR.Surface1,
					BackgroundTransparency = active and 0.35 or 0.85,
				})
			end
			if tab._sidebarBar then
				Util.safeSprTarget(tab._sidebarBar, Theme.SPRING.SMOOTH[1], Theme.SPRING.SMOOTH[2], {
					BackgroundTransparency = active and 0 or 1,
					BackgroundColor3 = Theme.COLOR.Accent,
					Size = UDim2.new(0, 3, 1, -12),
				})
			end
			if tab._sidebarGlow then
				Util.safeSprTarget(tab._sidebarGlow, Theme.SPRING.SNAPPY[1], Theme.SPRING.SNAPPY[2], {
					BackgroundTransparency = active and 0.92 or 1,
				})
			end
			if tab._sidebarLabel then
				Util.safeSprTarget(tab._sidebarLabel, Theme.SPRING.SNAPPY[1], Theme.SPRING.SNAPPY[2], {
					TextColor3 = active and Theme.COLOR.Text or Theme.COLOR.TextMuted,
				})
			end
			if tab._sidebarIcon then
				Util.safeSprTarget(tab._sidebarIcon, Theme.SPRING.SNAPPY[1], Theme.SPRING.SNAPPY[2], {
					TextColor3 = active and Theme.COLOR.Accent or Theme.COLOR.TextDim,
				})
			end
			if tab._topBtn then
				Util.safeSprTarget(tab._topBtn, Theme.SPRING.SNAPPY[1], Theme.SPRING.SNAPPY[2], {
					BackgroundTransparency = active and 0.25 or 0.7,
					BackgroundColor3 = Theme.COLOR.Surface1,
				})
			end
			if tab._topLabel then
				Util.safeSprTarget(tab._topLabel, Theme.SPRING.SNAPPY[1], Theme.SPRING.SNAPPY[2], {
					TextColor3 = active and Theme.COLOR.Text or Theme.COLOR.TextMuted,
				})
			end
			if tab._topGlow then
				Util.safeSprTarget(tab._topGlow, Theme.SPRING.SMOOTH[1], Theme.SPRING.SMOOTH[2], {
					BackgroundTransparency = active and 0.2 or 1,
					BackgroundColor3 = Theme.COLOR.Accent,
					Size = UDim2.new(0.7, 0, 0, 2),
				})
			end
		end

		function self:selectTab(tab)
			if self._activeTab == tab then return end
			if self._activeTab then
				safeVis(self._activeTab._panel, false)
				styleTab(self._activeTab, false)
			end
			safeVis(tab._panel, true)
			styleTab(tab, true)
			self._activeTab = tab
			self.TabSelected:Fire(tab)
		end

		function self:Hide()
			if self._hidden then return end
			self._hidden = true
			Util.safeSprTarget(self._mainScale, Theme.SPRING.SNAPPY[1], Theme.SPRING.SNAPPY[2], { Scale = 0.9 })
			Util.safeSprTarget(main, Theme.SPRING.SNAPPY[1], Theme.SPRING.SNAPPY[2], { BackgroundTransparency = 0.2 })
			Util.safeSprTarget(dim, Theme.SPRING.SNAPPY[1], Theme.SPRING.SNAPPY[2], { BackgroundTransparency = 1 })
			self.VisibilityChanged:Fire(false)
		end

		function self:Show()
			if not self._hidden then return end
			self._hidden = false
			dim.Visible = true
			Util.safeSprTarget(self._mainScale, Theme.SPRING.BOUNCY[1], Theme.SPRING.BOUNCY[2], { Scale = 1 })
			Util.safeSprTarget(main, Theme.SPRING.SMOOTH[1], Theme.SPRING.SMOOTH[2], { BackgroundTransparency = 0 })
			Util.safeSprTarget(dim, Theme.SPRING.SMOOTH[1], Theme.SPRING.SMOOTH[2], { BackgroundTransparency = 0.38 })
			self.VisibilityChanged:Fire(true)
		end

		function self:Toggle()
			if self._hidden then self:Show() else self:Hide() end
		end

		function self:SetKeybind(keyCode)
			if typeof(keyCode) == "EnumItem" then
				self._toggleKey = keyCode
				keybindLabel.Text = "Toggle: " .. keyName(keyCode)
				if statusRight then
					-- refresh on next tick
				end
			end
		end

		function self:AddTab(name, iconId, columns)
			if Validation then
				name = Validation.sanitizeText(name, 48)
				iconId = Validation.sanitizeIcon(iconId, SIDEBAR_ICONS[tostring(name)] or "•")
			else
				name = tostring(name or "Tab")
			end
			local tab = createTab(self, name, iconId, columns)
			local iconText = iconId or SIDEBAR_ICONS[tostring(name)] or "•"

			local topBtn = Util.make("TextButton", {
				Size = UDim2.fromOffset(92, tabH),
				BackgroundColor3 = Theme.COLOR.Surface1,
				BackgroundTransparency = 0.7,
				BorderSizePixel = 0,
				Text = "",
				AutoButtonColor = false,
				LayoutOrder = #self._tabs + 1,
				ZIndex = 9,
				Parent = tabStrip,
			})
			Util.corner(topBtn, Theme.RADIUS.Tab)

			local topGlow = Util.make("Frame", {
				Size = UDim2.new(0.6, 0, 0, 2),
				AnchorPoint = Vector2.new(0.5, 1),
				Position = UDim2.new(0.5, 0, 1, 4),
				BackgroundColor3 = Theme.COLOR.Accent,
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				ZIndex = 8,
				Parent = topBtn,
			})

			local topLabel = Util.make("TextLabel", {
				Size = UDim2.new(1, 0, 1, 0),
				BackgroundTransparency = 1,
				Text = Validation and Validation.sanitizeText(name, 32) or tostring(name),
				TextColor3 = Theme.COLOR.TEXT2,
				Font = Theme.FONT_BOLD,
				TextSize = Theme.TEXT,
				TextXAlignment = Enum.TextXAlignment.Center,
				TextYAlignment = Enum.TextYAlignment.Center,
				ZIndex = 10,
				Parent = topBtn,
			})

			local itemH = num(Theme.SIDEBAR.ITEM_H, 44, "SIDEBAR.ITEM_H")
			local sidebarBtn = Util.make("TextButton", {
				Size = UDim2.new(1, 0, 0, itemH),
				BackgroundColor3 = Theme.COLOR.Surface1,
				BackgroundTransparency = 0.85,
				BorderSizePixel = 0,
				Text = "",
				AutoButtonColor = false,
				LayoutOrder = #self._tabs + 1,
				ZIndex = 8,
				Parent = sidebar,
			})
			Util.corner(sidebarBtn, Theme.RADIUS.Sidebar)

			local sidebarGlow = Util.make("Frame", {
				Size = UDim2.new(1, 0, 1, 0),
				BackgroundColor3 = Theme.COLOR.Accent,
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				ZIndex = 7,
				Parent = sidebarBtn,
			})

			local sidebarBar = Util.make("Frame", {
				Size = UDim2.new(0, 3, 1, -12),
				Position = UDim2.new(0, 4, 0, 6),
				BackgroundColor3 = Theme.COLOR.Accent,
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				ZIndex = 10,
				Parent = sidebarBtn,
			})

			local sidebarIcon = Util.make("TextLabel", {
				Size = UDim2.fromOffset(32, Theme.SIDEBAR.ITEM_H),
				Position = UDim2.new(0, Theme.SIDEBAR.PAD, 0, 0),
				BackgroundTransparency = 1,
				Text = iconText,
				TextColor3 = Theme.COLOR.TEXT3,
				Font = Theme.FONT_BOLD,
				TextSize = Theme.SIDEBAR.ICON,
				TextXAlignment = Enum.TextXAlignment.Center,
				TextYAlignment = Enum.TextYAlignment.Center,
				ZIndex = 10,
				Parent = sidebarBtn,
			})

			local sidebarLabel = Util.make("TextLabel", {
				Size = UDim2.new(1, -56, 1, 0),
				Position = UDim2.new(0, 52, 0, 0),
				BackgroundTransparency = 1,
				Text = Validation and Validation.sanitizeText(name, 32) or tostring(name),
				TextColor3 = Theme.COLOR.TEXT2,
				Font = Theme.FONT,
				TextSize = Theme.TEXT,
				TextXAlignment = Enum.TextXAlignment.Left,
				TextYAlignment = Enum.TextYAlignment.Center,
				TextTruncate = Enum.TextTruncate.AtEnd,
				ZIndex = 10,
				Parent = sidebarBtn,
			})

			tab._topBtn = topBtn
			tab._topGlow = topGlow
			tab._topLabel = topLabel
			tab._sidebarBtn = sidebarBtn
			tab._sidebarGlow = sidebarGlow
			tab._sidebarBar = sidebarBar
			tab._sidebarIcon = sidebarIcon
			tab._sidebarLabel = sidebarLabel

			local function hoverSidebar(on)
				if self._activeTab ~= tab then
					Util.safeSprTarget(sidebarBtn, Theme.SPRING.SNAPPY[1], Theme.SPRING.SNAPPY[2], {
						BackgroundTransparency = on and 0.1 or 0.2,
					})
					Util.safeSprTarget(sidebarGlow, Theme.SPRING.SNAPPY[1], Theme.SPRING.SNAPPY[2], {
						BackgroundTransparency = on and 0.92 or 1,
					})
				end
			end

			sidebarBtn.MouseEnter:Connect(function() hoverSidebar(true) end)
			sidebarBtn.MouseLeave:Connect(function() hoverSidebar(false) end)
			sidebarBtn.MouseButton1Click:Connect(function() self:selectTab(tab) end)

			topBtn.MouseEnter:Connect(function()
				if self._activeTab ~= tab then
					Util.safeSprTarget(topBtn, Theme.SPRING.SNAPPY[1], Theme.SPRING.SNAPPY[2], { BackgroundTransparency = 0.2 })
				end
			end)
			topBtn.MouseLeave:Connect(function()
				if self._activeTab ~= tab then
					Util.safeSprTarget(topBtn, Theme.SPRING.SNAPPY[1], Theme.SPRING.SNAPPY[2], { BackgroundTransparency = 0.45 })
				end
			end)
			topBtn.MouseButton1Click:Connect(function() self:selectTab(tab) end)

			if self._search then
				self._search:register({
					label = "Open tab: " .. tostring(name),
					path = "Navigation / " .. tostring(name),
					action = function() self:selectTab(tab) end,
				})
			end

			table.insert(self._tabs, tab)
			self.TabAdded:Fire(tab)
			if #self._tabs == 1 then
				task.defer(function() self:selectTab(tab) end)
			end
			return tab
		end

		function self:Destroy()
			self._janitor:Destroy()
			if self.TabAdded then self.TabAdded:Destroy() end
			if self.TabSelected then self.TabSelected:Destroy() end
			if self.VisibilityChanged then self.VisibilityChanged:Destroy() end
			pcall(function() screen:Destroy() end)
		end

		closeBtn.MouseButton1Click:Connect(function() self:Hide() end)
		miniBtn.MouseButton1Click:Connect(function() self:Hide() end)

		-- Draggable top bar
		local dragging = false
		local dragStart, startPos
		topBar.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 then
				dragging = true
				dragStart = input.Position
				startPos = main.Position
			end
		end)
		UserInputService.InputChanged:Connect(function(input)
			if dragging and input.UserInputType == Enum.UserInputType.MouseMovement and dragStart and startPos then
				local delta = input.Position - dragStart
				local vpX, vpY = getViewport()
				local mainW, mainH = absSize(main, 1200, 720)
				local startX = num(startPos.X.Offset, 0, "dragStartX")
				local startY = num(startPos.Y.Offset, 0, "dragStartY")
				local newX = Util.clamp(startX + num(delta.X, 0, nil), -mainW * 0.25, vpX - mainW * 0.75)
				local newY = Util.clamp(startY + num(delta.Y, 0, nil), -mainH * 0.15, vpY - mainH * 0.7)
				main.Position = UDim2.new(startPos.X.Scale, newX, startPos.Y.Scale, newY)
			end
		end)
		topBar.InputEnded:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 then
				dragging = false
			end
		end)

		-- Toggle keybind
		local keyConn = UserInputService.InputBegan:Connect(function(input, gpe)
			if gpe then return end
			if input.KeyCode == self._toggleKey then
				self:Toggle()
			end
		end)
		self._janitor:Add(keyConn, "Disconnect")

		-- Responsive root scale
		local function applyResponsive()
			local vpX, vpY = getViewport()
			local scale = computeResponsiveScale(vpX, vpY)
			Util.safeSprTarget(rootScale, Theme.SPRING.GENTLE[1], Theme.SPRING.GENTLE[2], { Scale = scale })

			local minW = num(Theme.WINDOW.MIN_W, 760, nil) * scale
			local minH = num(Theme.WINDOW.MIN_H, 520, nil) * scale
			local defW = num(Theme.WINDOW.DEFAULT and Theme.WINDOW.DEFAULT.X.Offset, 1280, "DEFAULT.W")
			local defH = num(Theme.WINDOW.DEFAULT and Theme.WINDOW.DEFAULT.Y.Offset, 760, "DEFAULT.H")
			if vpX < minW or vpY < minH then
				main.Size = UDim2.fromOffset(math.min(vpX - 24, defW), math.min(vpY - 24, defH))
			elseif settings.Size then
				main.Size = settings.Size
			else
				main.Size = Theme.WINDOW.DEFAULT
			end
		end

		local cam = workspace.CurrentCamera
		if cam then
			self._janitor:Add(cam:GetPropertyChangedSignal("ViewportSize"):Connect(applyResponsive), "Disconnect")
		end
		applyResponsive()

		-- Live status / pill animations
		local pulseUp = true
		local uptimeSec = 0
		local fpsAccum, fpsFrames, fpsValue = 0, 0, 60

		local heartbeat = RunService.Heartbeat:Connect(function(dt)
			uptimeSec = uptimeSec + dt
			fpsAccum = fpsAccum + dt
			fpsFrames = fpsFrames + 1
			if fpsAccum >= 0.5 then
				fpsValue = math.floor(fpsFrames / fpsAccum)
				fpsAccum = 0
				fpsFrames = 0
			end

			if uptimeLabel then
				uptimeLabel.Text = formatUptime(uptimeSec)
			end

			local playerCount = #Players:GetPlayers()
			if playerLabel then
				playerLabel.Text = tostring(playerCount) .. " Players"
			end

			local connected = "Online"
			pcall(function()
				local ok = Players.LocalPlayer and Players.LocalPlayer:GetNetworkPing() ~= nil
				if not ok then connected = "Offline" end
			end)

			statusRight.Text = string.format(
				"Noble v%s  •  %s  •  %s  •  %s FPS  •  %s",
				Theme.VERSION,
				keyName(self._toggleKey),
				formatMemory(),
				tostring(fpsValue),
				connected
			)
		end)
		self._janitor:Add(heartbeat, "Disconnect")

		task.spawn(function()
			while screen.Parent and readyPill do
				local t = pulseUp and 0.12 or 0.22
				Util.safeSprTarget(readyPill, Theme.SPRING.GENTLE[1], Theme.SPRING.GENTLE[2], { BackgroundTransparency = t })
				pulseUp = not pulseUp
				task.wait(1.4)
			end
		end)

		if settings.StartHidden then
			self._hidden = true
			dim.BackgroundTransparency = 1
			mainScale.Scale = 0.9
		elseif AnimationManager then
			AnimationManager.openWindow(main, mainScale, dim)
		else
			Util.safeSprTarget(mainScale, Theme.SPRING.BOUNCY[1], Theme.SPRING.BOUNCY[2], { Scale = 1 })
		end

		self._janitor:Add(screen, "Destroy")
		return self
	end

	Window.createTab = createTab
	Window.createGroup = function(ctx, parent, title, width)
		return createGroup(ctx or {}, parent, title, width)
	end

	return Window
end