-- Noble V8 — main application shell (EXE-6 sidebar, Arc top bar, responsive scale)
return function(deps)
	local Theme = deps.Theme
	local Spr = deps.Spr
	local Util = deps.Util
	local Components = deps.Components
	local Janitor = deps.Janitor
	local Signal = deps.Signal
	local Fusion = deps.Fusion

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

	local function getViewport()
		local cam = workspace.CurrentCamera
		if cam then
			return cam.ViewportSize.X, cam.ViewportSize.Y
		end
		return 1920, 1080
	end

	local function computeResponsiveScale(vpX, vpY)
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
		local width = columnWidth or 360
		local card = Util.make("Frame", {
			Size = UDim2.fromOffset(width, 0),
			BackgroundColor3 = Theme.COLOR.BG2,
			BackgroundTransparency = 0.04,
			BorderSizePixel = 0,
			AutomaticSize = Enum.AutomaticSize.Y,
			ClipsDescendants = false,
			Parent = parent,
		})
		Util.corner(card, Theme.CARD.RADIUS)
		Util.stroke(card, Theme.COLOR.BORDER, 1, 0.38)

		local glow = Util.make("Frame", {
			Size = UDim2.new(1, 10, 1, 10),
			Position = UDim2.new(0, -5, 0, -5),
			BackgroundColor3 = Theme.COLOR.GLOW,
			BackgroundTransparency = 0.94,
			BorderSizePixel = 0,
			ZIndex = 0,
			Parent = card,
		})
		Util.corner(glow, Theme.CARD.RADIUS + 4)

		local shine = Util.make("Frame", {
			Size = UDim2.new(1, -28, 0, 3),
			Position = UDim2.new(0, 14, 0, 0),
			BackgroundColor3 = Theme.COLOR.ACCENT,
			BackgroundTransparency = 0.12,
			BorderSizePixel = 0,
			ZIndex = 3,
			Parent = card,
		})
		Util.gradient(shine, Theme.COLOR.ACCENT_LIGHT, Theme.COLOR.ACCENT, 0)
		Util.corner(shine, 2)

		card.MouseEnter:Connect(function()
			Util.safeSprTarget(glow, Theme.SPRING.SNAPPY[1], Theme.SPRING.SNAPPY[2], { BackgroundTransparency = 0.88 })
			Util.safeSprTarget(card, Theme.SPRING.SNAPPY[1], Theme.SPRING.SNAPPY[2], { BackgroundTransparency = 0.02 })
		end)
		card.MouseLeave:Connect(function()
			Util.safeSprTarget(glow, Theme.SPRING.SNAPPY[1], Theme.SPRING.SNAPPY[2], { BackgroundTransparency = 0.94 })
			Util.safeSprTarget(card, Theme.SPRING.SNAPPY[1], Theme.SPRING.SNAPPY[2], { BackgroundTransparency = 0.04 })
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
			local contentH = list.AbsoluteContentSize.Y
			return math.max(96, Theme.CARD.TITLE_H + contentH + Theme.CARD.PAD * 2 + 4)
		end

		local updateSize = debounce(function()
			if not card.Parent then return end
			card.Size = UDim2.fromOffset(width, calculateHeight())
		end, 0.025)

		list:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(updateSize)
		if parent and parent.GetPropertyChangedSignal then
			parent:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
				local newW = parent.AbsoluteSize.X
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
			local available = math.max(520, contentArea.AbsoluteSize.X - Theme.WINDOW.PADDING * 2)
			local gapTotal = (columns - 1) * Theme.CARD.GAP
			local cw = math.floor((available - gapTotal) / columns)
			cw = Util.clamp(cw, 220, 500)
			for _, cf in ipairs(colFrames) do
				cf.Size = UDim2.fromOffset(cw, 0)
			end
		end

		local initialCW = math.max(260, math.floor(((contentArea.AbsoluteSize.X > 0 and contentArea.AbsoluteSize.X or 900) - Theme.WINDOW.PADDING * 2 - (columns - 1) * Theme.CARD.GAP) / columns))
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
				local w = colFrames[1].AbsoluteSize.X > 0 and colFrames[1].AbsoluteSize.X or initialCW
				return createGroup(ctx, colFrames[1], groupName, w)
			end,
			AddRightGroupbox = function(_, groupName)
				local idx = math.min(2, #colFrames)
				if not colFrames[idx] then return nil end
				local w = colFrames[idx].AbsoluteSize.X > 0 and colFrames[idx].AbsoluteSize.X or initialCW
				return createGroup(ctx, colFrames[idx], groupName, w)
			end,
			AddGroupbox = function(_, groupName)
				local shortest, best = colFrames[1], 1
				for i, cf in ipairs(colFrames) do
					if cf.AbsoluteSize.Y < shortest.AbsoluteSize.Y then
						shortest = cf
						best = i
					end
				end
				local w = shortest.AbsoluteSize.X > 0 and shortest.AbsoluteSize.X or initialCW
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
			Name = settings.ScreenName or "NobleWindow",
			ResetOnSpawn = false,
			IgnoreGuiInset = true,
			ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
			DisplayOrder = settings.DisplayOrder or 100,
			Parent = settings.Parent or game:GetService("CoreGui"),
		})

		if typeof(screen) ~= "Instance" or not screen:IsA("ScreenGui") or not screen.Parent then
			warn("[NobleV8] ScreenGui must be parented before building window UI")
		end

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
		Util.corner(main, Theme.WINDOW.RADIUS)
		Util.stroke(main, Theme.COLOR.BORDER, 1, 0.42)

		local mainScale = Util.scale(main)
		mainScale.Scale = settings.StartHidden and 0.92 or 1

		-- Top bar
		local topBar = Util.make("Frame", {
			Name = "TopBar",
			Size = UDim2.new(1, 0, 0, Theme.TOPBAR.H),
			BackgroundColor3 = Theme.COLOR.BG1,
			BorderSizePixel = 0,
			ZIndex = 10,
			Parent = main,
		})
		Util.corner(topBar, Theme.WINDOW.RADIUS)

		Util.make("Frame", {
			Size = UDim2.new(1, 0, 0, 1),
			Position = UDim2.new(0, 0, 1, 0),
			BackgroundColor3 = Theme.COLOR.BORDER,
			BackgroundTransparency = 0.9,
			BorderSizePixel = 0,
			ZIndex = 11,
			Parent = topBar,
		})

		local logo = Util.make("Frame", {
			Size = UDim2.fromOffset(40, 40),
			Position = UDim2.new(0, Theme.WINDOW.PADDING, 0.5, -20),
			BackgroundColor3 = Theme.COLOR.ACCENT,
			BorderSizePixel = 0,
			ZIndex = 12,
			Parent = topBar,
		})
		Util.corner(logo, 12)
		Util.gradient(logo, Theme.COLOR.ACCENT_LIGHT, Theme.COLOR.ACCENT_DARK, 135)
		Util.make("TextLabel", {
			Size = UDim2.new(1, 0, 1, 0),
			BackgroundTransparency = 1,
			Text = string.sub(title, 1, 1):upper(),
			TextColor3 = Theme.COLOR.WHITE,
			Font = Theme.FONT_BOLD,
			TextSize = 18,
			TextXAlignment = Enum.TextXAlignment.Center,
			TextYAlignment = Enum.TextYAlignment.Center,
			ZIndex = 13,
			Parent = logo,
		})

		Util.make("TextLabel", {
			Size = UDim2.new(0, 0, 1, 0),
			Position = UDim2.new(0, 68, 0, 0),
			BackgroundTransparency = 1,
			Text = title,
			TextColor3 = Theme.COLOR.TEXT,
			Font = Theme.FONT_BOLD,
			TextSize = Theme.TEXT_HEADER,
			AutomaticSize = Enum.AutomaticSize.X,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextYAlignment = Enum.TextYAlignment.Center,
			ZIndex = 12,
			Parent = topBar,
		})

		local verBadge = Util.make("Frame", {
			Size = UDim2.fromOffset(68, 22),
			Position = UDim2.new(0, 168, 0.5, -11),
			BackgroundColor3 = Theme.COLOR.ACCENT,
			BorderSizePixel = 0,
			ZIndex = 12,
			Parent = topBar,
		})
		Util.corner(verBadge, Theme.RADIUS.PILL)
		Util.gradient(verBadge, Theme.COLOR.ACCENT_LIGHT, Theme.COLOR.ACCENT, 0)
		local verGlow = Util.make("Frame", {
			Size = UDim2.new(1, 8, 1, 8),
			Position = UDim2.new(0, -4, 0, -4),
			BackgroundColor3 = Theme.COLOR.ACCENT,
			BackgroundTransparency = 0.84,
			BorderSizePixel = 0,
			ZIndex = 11,
			Parent = verBadge,
		})
		Util.corner(verGlow, Theme.RADIUS.PILL + 2)
		Util.make("TextLabel", {
			Size = UDim2.new(1, 0, 1, 0),
			BackgroundTransparency = 1,
			Text = "v" .. Theme.VERSION,
			TextColor3 = Theme.COLOR.WHITE,
			Font = Theme.FONT_BOLD,
			TextSize = 11,
			TextXAlignment = Enum.TextXAlignment.Center,
			TextYAlignment = Enum.TextYAlignment.Center,
			ZIndex = 13,
			Parent = verBadge,
		})

		local function createPill(parent, text, x, color)
			local pill = Util.make("Frame", {
				Size = UDim2.fromOffset(0, 26),
				Position = UDim2.new(0, x, 0.5, -13),
				BackgroundColor3 = Theme.COLOR.BG3,
				BackgroundTransparency = 0.08,
				BorderSizePixel = 0,
				AutomaticSize = Enum.AutomaticSize.X,
				ZIndex = 12,
				Parent = parent,
			})
			Util.corner(pill, Theme.RADIUS.PILL)
			Util.stroke(pill, color or Theme.COLOR.BORDER_SOFT, 1, 0.55)
			Util.padding(pill, 12, 12, 0, 0)
			local dot = Util.make("Frame", {
				Size = UDim2.fromOffset(8, 8),
				Position = UDim2.new(0, 10, 0.5, -4),
				BackgroundColor3 = color or Theme.COLOR.GREEN,
				BorderSizePixel = 0,
				ZIndex = 13,
				Parent = pill,
			})
			Util.corner(dot, 4)
			local lbl = Util.make("TextLabel", {
				Size = UDim2.new(0, 0, 1, 0),
				Position = UDim2.new(0, 24, 0, 0),
				BackgroundTransparency = 1,
				Text = text,
				TextColor3 = Theme.COLOR.TEXT2,
				Font = Theme.FONT,
				TextSize = Theme.TEXT_SM,
				AutomaticSize = Enum.AutomaticSize.X,
				TextXAlignment = Enum.TextXAlignment.Left,
				TextYAlignment = Enum.TextYAlignment.Center,
				ZIndex = 13,
				Parent = pill,
			})
			return pill, lbl, dot
		end

		local playerPill, playerLabel, playerDot = createPill(topBar, "0 Players", 280, Theme.COLOR.GREEN)
		local uptimePill, uptimeLabel = createPill(topBar, "Uptime 00:00:00", 430, Theme.COLOR.BLUE)
		local readyPill, readyLabel = createPill(topBar, "UI Ready", 590, Theme.COLOR.GREEN)
		local readyGlow = Util.make("Frame", {
			Size = UDim2.new(1, 6, 1, 6),
			Position = UDim2.new(0, -3, 0, -3),
			BackgroundColor3 = Theme.COLOR.GREEN,
			BackgroundTransparency = 0.9,
			BorderSizePixel = 0,
			ZIndex = 11,
			Parent = readyPill,
		})
		Util.corner(readyGlow, Theme.RADIUS.PILL + 2)

		local keybindLabel = Util.make("TextLabel", {
			Size = UDim2.fromOffset(150, Theme.TOPBAR.H),
			Position = UDim2.new(0, 250, 0, 0),
			BackgroundTransparency = 1,
			Text = "Toggle: " .. keyName(self._toggleKey),
			TextColor3 = Theme.COLOR.TEXT3,
			Font = Theme.FONT,
			TextSize = Theme.TEXT_SM,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextYAlignment = Enum.TextYAlignment.Center,
			ZIndex = 12,
			Parent = topBar,
		})

		local closeBtn = Util.make("TextButton", {
			Size = UDim2.fromOffset(36, 36),
			Position = UDim2.new(1, -Theme.WINDOW.PADDING - 4, 0.5, -18),
			BackgroundColor3 = Theme.COLOR.ACCENT,
			BorderSizePixel = 0,
			Text = "✕",
			TextColor3 = Theme.COLOR.WHITE,
			Font = Theme.FONT_BOLD,
			TextSize = 16,
			AutoButtonColor = false,
			ZIndex = 12,
			Parent = topBar,
		})
		Util.corner(closeBtn, Theme.RADIUS.BUTTON)
		Util.gradient(closeBtn, Theme.COLOR.ACCENT_LIGHT, Theme.COLOR.ACCENT, 90)
		local closeScale = Util.scale(closeBtn)

		local miniBtn = Util.make("TextButton", {
			Size = UDim2.fromOffset(34, 34),
			Position = UDim2.new(1, -Theme.WINDOW.PADDING - 46, 0.5, -17),
			BackgroundColor3 = Theme.COLOR.BG3,
			BorderSizePixel = 0,
			Text = "–",
			TextColor3 = Theme.COLOR.TEXT2,
			Font = Theme.FONT_BOLD,
			TextSize = 18,
			AutoButtonColor = false,
			ZIndex = 12,
			Parent = topBar,
		})
		Util.corner(miniBtn, 17)
		Util.stroke(miniBtn, Theme.COLOR.BORDER, 1, 0.55)
		local miniScale = Util.scale(miniBtn)

		closeBtn.MouseEnter:Connect(function()
			Util.safeSprTarget(closeScale, Theme.SPRING.SNAPPY[1], Theme.SPRING.SNAPPY[2], { Scale = 1.08 })
		end)
		closeBtn.MouseLeave:Connect(function()
			Util.safeSprTarget(closeScale, Theme.SPRING.SNAPPY[1], Theme.SPRING.SNAPPY[2], { Scale = 1 })
		end)
		miniBtn.MouseEnter:Connect(function()
			Util.safeSprTarget(miniScale, Theme.SPRING.SNAPPY[1], Theme.SPRING.SNAPPY[2], { Scale = 1.06 })
			Util.safeSprTarget(miniBtn, Theme.SPRING.SNAPPY[1], Theme.SPRING.SNAPPY[2], { BackgroundColor3 = Theme.COLOR.BG4 })
		end)
		miniBtn.MouseLeave:Connect(function()
			Util.safeSprTarget(miniScale, Theme.SPRING.SNAPPY[1], Theme.SPRING.SNAPPY[2], { Scale = 1 })
			Util.safeSprTarget(miniBtn, Theme.SPRING.SNAPPY[1], Theme.SPRING.SNAPPY[2], { BackgroundColor3 = Theme.COLOR.BG3 })
		end)

		-- Tab strip
		local tabStrip = Util.make("ScrollingFrame", {
			Name = "TabStrip",
			Size = UDim2.new(1, -Theme.SIDEBAR.W - Theme.WINDOW.PADDING * 3, 0, Theme.TOPBAR.TAB_H + 8),
			Position = UDim2.new(0, Theme.SIDEBAR.W + Theme.WINDOW.PADDING * 2, 0, Theme.TOPBAR.H + 8),
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

		-- Sidebar (EXE-6 64px rows)
		local bodyTop = Theme.TOPBAR.H + Theme.TOPBAR.TAB_H + 20
		local sidebar = Util.make("ScrollingFrame", {
			Name = "Sidebar",
			Size = UDim2.new(0, Theme.SIDEBAR.W, 1, -(bodyTop + Theme.STATUSBAR.H + Theme.WINDOW.PADDING)),
			Position = UDim2.new(0, Theme.WINDOW.PADDING, 0, bodyTop),
			BackgroundColor3 = Theme.COLOR.BG2,
			BackgroundTransparency = 0.12,
			BorderSizePixel = 0,
			ScrollBarThickness = 0,
			CanvasSize = UDim2.new(0, 0, 0, 0),
			AutomaticCanvasSize = Enum.AutomaticSize.Y,
			ScrollingDirection = Enum.ScrollingDirection.Y,
			ClipsDescendants = true,
			ZIndex = 7,
			Parent = main,
		})
		Util.corner(sidebar, Theme.SIDEBAR.RADIUS)
		Util.stroke(sidebar, Theme.COLOR.BORDER, 1, 0.48)
		Util.styleScroll(sidebar)
		Util.make("UIListLayout", {
			Padding = UDim.new(0, 8),
			SortOrder = Enum.SortOrder.LayoutOrder,
			Parent = sidebar,
		})
		Util.padding(sidebar, Theme.SIDEBAR.PAD, Theme.SIDEBAR.PAD, Theme.SIDEBAR.PAD, Theme.SIDEBAR.PAD)

		-- Content area (BG0, no gray fill)
		local contentArea = Util.make("Frame", {
			Name = "Content",
			Size = UDim2.new(1, -(Theme.SIDEBAR.W + Theme.WINDOW.PADDING * 3), 1, -(bodyTop + Theme.STATUSBAR.H + Theme.WINDOW.PADDING)),
			Position = UDim2.new(0, Theme.SIDEBAR.W + Theme.WINDOW.PADDING * 2, 0, bodyTop),
			BackgroundColor3 = Theme.COLOR.BG0,
			BackgroundTransparency = 0,
			BorderSizePixel = 0,
			ClipsDescendants = true,
			ZIndex = 6,
			Parent = main,
		})
		Util.corner(contentArea, Theme.CARD.RADIUS)
		Util.stroke(contentArea, Theme.COLOR.BORDER, 1, 0.55)

		local dropLayer = Util.make("Frame", {
			Name = "DropLayer",
			Size = UDim2.new(1, 0, 1, 0),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			ClipsDescendants = true,
			ZIndex = 40,
			Parent = contentArea,
		})

		-- Status bar
		local statusBar = Util.make("Frame", {
			Name = "StatusBar",
			Size = UDim2.new(1, -Theme.WINDOW.PADDING * 2, 0, Theme.STATUSBAR.H),
			Position = UDim2.new(0, Theme.WINDOW.PADDING, 1, -Theme.STATUSBAR.H - 8),
			BackgroundColor3 = Theme.COLOR.BG2,
			BackgroundTransparency = 0.1,
			BorderSizePixel = 0,
			ZIndex = 9,
			Parent = main,
		})
		Util.corner(statusBar, Theme.RADIUS.PILL)
		Util.stroke(statusBar, Theme.COLOR.BORDER, 1, 0.6)

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
		self._statusBar = statusBar
		self._keybindLabel = keybindLabel

		-- Search overlay (optional dep passed via settings.Search factory)
		if settings.Search and type(settings.Search.new) == "function" then
			self._search = settings.Search.new({
				parent = screen,
				keybind = settings.SearchKeybind or Enum.KeyCode.K,
				modifiers = settings.SearchModifiers or { Ctrl = true },
			})
			self._janitor:Add(self._search, "Destroy")
		end

		local function styleTab(tab, active)
			if tab._sidebarBtn then
				Util.safeSprTarget(tab._sidebarBtn, Theme.SPRING.SNAPPY[1], Theme.SPRING.SNAPPY[2], {
					BackgroundColor3 = active and Theme.COLOR.BG4 or Theme.COLOR.BG3,
					BackgroundTransparency = active and 0.06 or 0.2,
				})
			end
			if tab._sidebarBar then
				Util.safeSprTarget(tab._sidebarBar, Theme.SPRING.SMOOTH[1], Theme.SPRING.SMOOTH[2], {
					BackgroundTransparency = active and 0.02 or 1,
					Size = active and UDim2.new(0, 4, 1, -16) or UDim2.new(0, 3, 1, -24),
				})
			end
			if tab._sidebarGlow then
				Util.safeSprTarget(tab._sidebarGlow, Theme.SPRING.SNAPPY[1], Theme.SPRING.SNAPPY[2], {
					BackgroundTransparency = active and 0.86 or 1,
				})
			end
			if tab._sidebarLabel then
				Util.safeSprTarget(tab._sidebarLabel, Theme.SPRING.SNAPPY[1], Theme.SPRING.SNAPPY[2], {
					TextColor3 = active and Theme.COLOR.TEXT or Theme.COLOR.TEXT2,
				})
			end
			if tab._sidebarIcon then
				Util.safeSprTarget(tab._sidebarIcon, Theme.SPRING.SNAPPY[1], Theme.SPRING.SNAPPY[2], {
					TextColor3 = active and Theme.COLOR.ACCENT_LIGHT or Theme.COLOR.TEXT3,
				})
			end
			if tab._topBtn then
				Util.safeSprTarget(tab._topBtn, Theme.SPRING.SNAPPY[1], Theme.SPRING.SNAPPY[2], {
					BackgroundTransparency = active and 0.04 or 0.45,
					BackgroundColor3 = active and Theme.COLOR.BG4 or Theme.COLOR.BG3,
				})
			end
			if tab._topLabel then
				Util.safeSprTarget(tab._topLabel, Theme.SPRING.SNAPPY[1], Theme.SPRING.SNAPPY[2], {
					TextColor3 = active and Theme.COLOR.TEXT or Theme.COLOR.TEXT2,
				})
			end
			if tab._topGlow then
				Util.safeSprTarget(tab._topGlow, Theme.SPRING.BOUNCY[1], Theme.SPRING.BOUNCY[2], {
					BackgroundTransparency = active and 0.35 or 1,
					Size = active and UDim2.new(0.82, 0, 0, 3) or UDim2.new(0.35, 0, 0, 2),
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
			local tab = createTab(self, name, iconId, columns)
			local iconText = iconId or SIDEBAR_ICONS[tostring(name)] or "•"

			local topBtn = Util.make("TextButton", {
				Size = UDim2.fromOffset(104, Theme.TOPBAR.TAB_H),
				BackgroundColor3 = Theme.COLOR.BG3,
				BackgroundTransparency = 0.45,
				BorderSizePixel = 0,
				Text = "",
				AutoButtonColor = false,
				LayoutOrder = #self._tabs + 1,
				ZIndex = 9,
				Parent = tabStrip,
			})
			Util.corner(topBtn, Theme.RADIUS.BUTTON)
			Util.stroke(topBtn, Theme.COLOR.BORDER, 1, 0.55)

			local topGlow = Util.make("Frame", {
				Size = UDim2.new(0.35, 0, 0, 2),
				AnchorPoint = Vector2.new(0.5, 1),
				Position = UDim2.new(0.5, 0, 1, 5),
				BackgroundColor3 = Theme.COLOR.ACCENT,
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				ZIndex = 8,
				Parent = topBtn,
			})
			Util.corner(topGlow, 2)
			Util.gradient(topGlow, Theme.COLOR.ACCENT_LIGHT, Theme.COLOR.ACCENT, 0)

			local topLabel = Util.make("TextLabel", {
				Size = UDim2.new(1, 0, 1, 0),
				BackgroundTransparency = 1,
				Text = tostring(name),
				TextColor3 = Theme.COLOR.TEXT2,
				Font = Theme.FONT_BOLD,
				TextSize = Theme.TEXT,
				TextXAlignment = Enum.TextXAlignment.Center,
				TextYAlignment = Enum.TextYAlignment.Center,
				ZIndex = 10,
				Parent = topBtn,
			})

			local sidebarBtn = Util.make("TextButton", {
				Size = UDim2.new(1, 0, 0, Theme.SIDEBAR.ITEM_H),
				BackgroundColor3 = Theme.COLOR.BG3,
				BackgroundTransparency = 0.2,
				BorderSizePixel = 0,
				Text = "",
				AutoButtonColor = false,
				LayoutOrder = #self._tabs + 1,
				ZIndex = 8,
				Parent = sidebar,
			})
			Util.corner(sidebarBtn, Theme.SIDEBAR.RADIUS)

			local sidebarGlow = Util.make("Frame", {
				Size = UDim2.new(1, 0, 1, 0),
				BackgroundColor3 = Theme.COLOR.ACCENT,
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				ZIndex = 7,
				Parent = sidebarBtn,
			})
			Util.corner(sidebarGlow, Theme.SIDEBAR.RADIUS)

			local sidebarBar = Util.make("Frame", {
				Size = UDim2.new(0, 3, 1, -24),
				Position = UDim2.new(0, 6, 0, 12),
				BackgroundColor3 = Theme.COLOR.ACCENT,
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				ZIndex = 10,
				Parent = sidebarBtn,
			})
			Util.corner(sidebarBar, 2)

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
				Text = tostring(name),
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
			if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
				local delta = input.Position - dragStart
				local vpX, vpY = getViewport()
				local newX = Util.clamp(startPos.X.Offset + delta.X, -main.AbsoluteSize.X * 0.25, vpX - main.AbsoluteSize.X * 0.75)
				local newY = Util.clamp(startPos.Y.Offset + delta.Y, -main.AbsoluteSize.Y * 0.15, vpY - main.AbsoluteSize.Y * 0.7)
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

			local minW = Theme.WINDOW.MIN_W * scale
			local minH = Theme.WINDOW.MIN_H * scale
			if vpX < minW or vpY < minH then
				main.Size = UDim2.fromOffset(math.min(vpX - 24, Theme.WINDOW.DEFAULT.X.Offset), math.min(vpY - 24, Theme.WINDOW.DEFAULT.Y.Offset))
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
		local glowUp = true
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
				uptimeLabel.Text = "Uptime " .. formatUptime(uptimeSec)
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
			while screen.Parent do
				if pulseUp then
					Util.safeSprTarget(playerDot, Theme.SPRING.GENTLE[1], Theme.SPRING.GENTLE[2], { BackgroundTransparency = 0.15 })
					Util.safeSprTarget(playerPill, Theme.SPRING.GENTLE[1], Theme.SPRING.GENTLE[2], { BackgroundTransparency = 0.02 })
				else
					Util.safeSprTarget(playerDot, Theme.SPRING.GENTLE[1], Theme.SPRING.GENTLE[2], { BackgroundTransparency = 0.45 })
					Util.safeSprTarget(playerPill, Theme.SPRING.GENTLE[1], Theme.SPRING.GENTLE[2], { BackgroundTransparency = 0.1 })
				end
				pulseUp = not pulseUp
				task.wait(1)
			end
		end)

		task.spawn(function()
			while screen.Parent do
				if glowUp then
					Util.safeSprTarget(verGlow, Theme.SPRING.GENTLE[1], Theme.SPRING.GENTLE[2], { BackgroundTransparency = 0.68 })
					Util.safeSprTarget(readyGlow, Theme.SPRING.GENTLE[1], Theme.SPRING.GENTLE[2], { BackgroundTransparency = 0.55 })
				else
					Util.safeSprTarget(verGlow, Theme.SPRING.GENTLE[1], Theme.SPRING.GENTLE[2], { BackgroundTransparency = 0.88 })
					Util.safeSprTarget(readyGlow, Theme.SPRING.GENTLE[1], Theme.SPRING.GENTLE[2], { BackgroundTransparency = 0.9 })
				end
				glowUp = not glowUp
				task.wait(1.2)
			end
		end)

		if settings.StartHidden then
			self._hidden = true
			dim.BackgroundTransparency = 1
			mainScale.Scale = 0.9
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