--[[
	Alleral WindUI revamp (Footagesus 1.6.64-fix base)
	Loaded by ui/windui/main.lua after upstream WindUI initializes.
]]

return function(WindUI)
	if type(WindUI) ~= "table" then
		return WindUI
	end

	-- -------------------------------------------------------------------------
	-- Tokens
	-- -------------------------------------------------------------------------

	local TweenService = game:GetService("TweenService")

	local ACCENT = Color3.fromHex("#53fc18")
	local ACCENT_SOFT = Color3.fromHex("#30ff6a")
	local ACCENT_HOT = Color3.fromHex("#7dff35")
	local INK = Color3.fromHex("#050805")
	local PANEL = Color3.fromHex("#0f1a0c")

	WindUI.ALLERAL_UI_VERSION = "1.6.64-fix-aller4"
	WindUI._AlleralNotifyCount = 0
	WindUI._AlleralMaxNotify = 8
	WindUI._AlleralWatchdogToken = 0
	WindUI._AlleralReducedMotion = WindUI._AlleralReducedMotion == true
	WindUI._AlleralNotifyCompact = WindUI._AlleralNotifyCompact == true
	WindUI._AlleralNotifyHolder = WindUI._AlleralNotifyHolder
	WindUI._AlleralPendingNotifyStyle = nil

	local NOTIFY_STYLES = {
		info = {
			accent = ACCENT,
			icon = "leaf",
		},
		success = {
			accent = ACCENT_SOFT,
			icon = "check",
		},
		warn = {
			accent = Color3.fromHex("#ffd166"),
			icon = "triangle-alert",
		},
		error = {
			accent = Color3.fromHex("#ff5c5c"),
			icon = "x",
		},
	}

	local function resolveNotifyStyle(payload)
		local key = string.lower(tostring(payload.Type or payload.Level or payload.Style or "info"))
		if key == "warning" then
			key = "warn"
		elseif key == "danger" or key == "fail" or key == "failed" then
			key = "error"
		elseif key == "ok" or key == "done" then
			key = "success"
		end
		return NOTIFY_STYLES[key] or NOTIFY_STYLES.info, key
	end

	local WINDOW_DEFAULTS = {
		Theme = "Alleral",
		NewElements = true,
		UICorner = 16,
		UIPadding = 14,
		SideBarWidth = 232,
		ElementPadding = 10,
		Resizable = true,
		HideSearchBar = false,
	}

	local function uiWarn(scope, err)
		warn(string.format("[Alleral UI/%s] %s", tostring(scope), tostring(err)))
	end

	local function tween(instance, info, props)
		if WindUI._AlleralReducedMotion or not instance or not instance.Parent then
			return
		end
		pcall(function()
			TweenService:Create(instance, info, props):Play()
		end)
	end

	local function mergeTokens(base, extra)
		local out = {}
		for key, value in pairs(base) do
			out[key] = value
		end
		for key, value in pairs(extra or {}) do
			out[key] = value
		end
		return out
	end

	local SHARED_CHROME = {
		WindowShadow = Color3.fromHex("#000000"),
		WindowTopbarButtonIcon = ACCENT,
		SearchBarBorder = ACCENT,
		SectionExpandIcon = ACCENT,
		DropdownTabBorder = ACCENT,
		CheckboxBorder = ACCENT,
		SliderThumb = Color3.fromHex("#ffffff"),
		Hover = ACCENT,
		BackgroundTransparency = 0,
	}

	local function fullTheme(name, accent, bg, panel, text, muted, button, tabActive)
		return mergeTokens(SHARED_CHROME, {
			Name = name,
			Accent = accent,
			Primary = accent,
			Outline = accent,
			Icon = accent,
			Toggle = accent,
			Slider = button,
			Checkbox = accent,
			SliderIcon = button,
			Dialog = panel,
			Background = bg,
			Button = button,
			Text = text,
			Placeholder = muted,
			PanelBackground = panel,
			PanelBackgroundTransparency = 0.86,
			LabelBackground = Color3.fromHex("#000000"),
			LabelBackgroundTransparency = 0.84,
			ElementBackground = panel,
			ElementBackgroundTransparency = 0.08,
			ElementTitle = text,
			ElementDesc = muted,
			ElementIcon = accent,
			TabBackground = bg,
			TabBackgroundHover = panel,
			TabBackgroundHoverTransparency = 0.76,
			TabBackgroundActive = tabActive,
			TabBackgroundActiveTransparency = 0.62,
			TabText = text,
			TabTextTransparency = 0.28,
			TabTextTransparencyActive = 0,
			TabIcon = accent,
			TabIconTransparency = 0.32,
			TabIconTransparencyActive = 0,
			TabBorder = accent,
			TabBorderTransparency = 0.86,
			TabBorderTransparencyActive = 0.38,
			WindowBackground = bg,
			WindowTopbarTitle = text,
			WindowTopbarAuthor = muted,
			WindowTopbarIcon = accent,
			WindowSearchBarBackground = panel,
			SearchBarBorderTransparency = 0.62,
			SectionBoxBackground = panel,
			SectionBoxBackgroundTransparency = 0.84,
			SectionBoxBorder = accent,
			SectionBoxBorderTransparency = 0.7,
			SectionExpandIconTransparency = 0.28,
			Notification = panel,
			NotificationTitle = text,
			NotificationContent = muted,
			NotificationBorder = accent,
			NotificationBorderTransparency = 0.5,
			PopupBackground = panel,
			DialogBackground = panel,
			ToggleBar = tabActive,
			CheckboxBorderTransparency = 0.48,
			Tooltip = panel,
			TooltipText = text,
		})
	end

	local THEME_PACK = {
		Alleral = fullTheme(
			"Alleral",
			ACCENT,
			INK,
			PANEL,
			Color3.fromHex("#f0fff0"),
			Color3.fromHex("#6b9e5a"),
			ACCENT_SOFT,
			Color3.fromHex("#183018")
		),
		AlleralNeon = fullTheme(
			"AlleralNeon",
			ACCENT_HOT,
			Color3.fromHex("#020402"),
			Color3.fromHex("#0a1808"),
			Color3.fromHex("#f6fff0"),
			Color3.fromHex("#5ecf45"),
			ACCENT,
			Color3.fromHex("#183820")
		),
		AlleralMidnight = fullTheme(
			"AlleralMidnight",
			Color3.fromHex("#3ddc84"),
			Color3.fromHex("#020302"),
			Color3.fromHex("#081008"),
			Color3.fromHex("#dfeedd"),
			Color3.fromHex("#4a7a42"),
			Color3.fromHex("#2ecc71"),
			Color3.fromHex("#102818")
		),
		Dark = fullTheme(
			"Dark",
			ACCENT,
			Color3.fromHex("#080a08"),
			Color3.fromHex("#101810"),
			Color3.fromHex("#f4fff0"),
			Color3.fromHex("#7a9a72"),
			ACCENT_SOFT,
			Color3.fromHex("#1a2814")
		),
	}

	local function installThemes()
		for themeName, tokens in pairs(THEME_PACK) do
			if WindUI.Themes then
				WindUI.Themes[themeName] = mergeTokens(WindUI.Themes[themeName] or {}, tokens)
				WindUI.Themes[themeName].Name = themeName
			end
			if WindUI.AddTheme then
				pcall(WindUI.AddTheme, WindUI, tokens)
			end
		end
	end

	installThemes()

	local function resolveThemeName(requested)
		local themes = WindUI.Themes or {}
		if type(requested) == "string" and themes[requested] then
			return requested
		end
		if themes.Alleral then
			return "Alleral"
		end
		if themes.Dark then
			return "Dark"
		end
		for name in pairs(themes) do
			return name
		end
		return "Dark"
	end

	-- -------------------------------------------------------------------------
	-- Visual polish
	-- -------------------------------------------------------------------------

	local function ensureStroke(frame, name, color, transparency, thickness)
		if not frame or not frame:IsA("GuiObject") then
			return nil
		end
		local stroke = frame:FindFirstChild(name)
		if not stroke then
			stroke = Instance.new("UIStroke")
			stroke.Name = name
			stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
			stroke.Parent = frame
		end
		stroke.Color = color or ACCENT
		stroke.Thickness = thickness or 1
		stroke.Transparency = transparency or 0.55
		return stroke
	end

	local function addTopGlow(topbarFrame)
		if not topbarFrame or not topbarFrame:IsA("GuiObject") then
			return
		end
		if topbarFrame:FindFirstChild("AlleralTopGlow") then
			return
		end

		local glow = Instance.new("Frame")
		glow.Name = "AlleralTopGlow"
		glow.BackgroundColor3 = ACCENT
		glow.BackgroundTransparency = 0.86
		glow.BorderSizePixel = 0
		glow.Size = UDim2.new(1, 0, 0, 2)
		glow.Position = UDim2.new(0, 0, 1, -1)
		glow.ZIndex = topbarFrame.ZIndex + 2
		glow.Parent = topbarFrame

		local grad = Instance.new("UIGradient")
		grad.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, ACCENT),
			ColorSequenceKeypoint.new(0.5, ACCENT_SOFT),
			ColorSequenceKeypoint.new(1, ACCENT),
		})
		grad.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.35),
			NumberSequenceKeypoint.new(0.5, 0.12),
			NumberSequenceKeypoint.new(1, 0.35),
		})
		grad.Parent = glow
	end

	local function addSidebarRail(sidebar)
		if not sidebar or not sidebar:IsA("GuiObject") then
			return
		end
		if sidebar:FindFirstChild("AlleralSidebarRail") then
			return
		end

		local rail = Instance.new("Frame")
		rail.Name = "AlleralSidebarRail"
		rail.BackgroundColor3 = ACCENT
		rail.BackgroundTransparency = 0.25
		rail.BorderSizePixel = 0
		rail.Size = UDim2.new(0, 2, 1, -12)
		rail.Position = UDim2.new(0, 4, 0, 6)
		rail.ZIndex = sidebar.ZIndex + 3
		rail.Parent = sidebar

		local grad = Instance.new("UIGradient")
		grad.Rotation = 90
		grad.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, ACCENT_SOFT),
			ColorSequenceKeypoint.new(0.5, ACCENT),
			ColorSequenceKeypoint.new(1, ACCENT_SOFT),
		})
		grad.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.55),
			NumberSequenceKeypoint.new(0.5, 0.1),
			NumberSequenceKeypoint.new(1, 0.55),
		})
		grad.Parent = rail
	end

	local function addBackdrop(window)
		if not WindUI.ScreenGui or not window or not window.UIElements or not window.UIElements.Main then
			return
		end
		local main = window.UIElements.Main
		local host = main.Parent
		if not host or host:FindFirstChild("AlleralBackdrop") then
			return
		end

		local backdrop = Instance.new("Frame")
		backdrop.Name = "AlleralBackdrop"
		backdrop.BackgroundColor3 = Color3.new(0, 0, 0)
		backdrop.BackgroundTransparency = 0.45
		backdrop.BorderSizePixel = 0
		backdrop.Size = UDim2.new(1, 0, 1, 0)
		backdrop.ZIndex = math.max(0, main.ZIndex - 1)
		backdrop.Visible = main.Visible
		backdrop.Parent = host

		pcall(function()
			main:GetPropertyChangedSignal("Visible"):Connect(function()
				backdrop.Visible = main.Visible
			end)
		end)
	end

	function WindUI.PolishWindow(_self, window)
		if type(window) ~= "table" or type(window.UIElements) ~= "table" then
			return window
		end

		pcall(function()
			local main = window.UIElements.Main
			if main then
				ensureStroke(main, "AlleralAccentStroke", ACCENT, 0.56, 1)
			end

			local topbar = window.UIElements.Topbar
			if topbar and topbar.Main then
				addTopGlow(topbar.Main)
				ensureStroke(topbar.Main, "AlleralTopbarStroke", ACCENT, 0.82, 1)
			end

			local sidebar = window.UIElements.SideBar
			if sidebar then
				addSidebarRail(sidebar)
				ensureStroke(sidebar, "AlleralSidebarStroke", ACCENT, 0.84, 1)
			end

			if window.SearchBar and window.SearchBar.Frame then
				ensureStroke(window.SearchBar.Frame, "AlleralSearchStroke", ACCENT, 0.74, 1)
			end

			window.CanDropdown = true
			addBackdrop(window)
		end)

		return window
	end

	local function normalizeWindowSettings(settings)
		settings = type(settings) == "table" and settings or {}
		for key, value in pairs(WINDOW_DEFAULTS) do
			if settings[key] == nil then
				settings[key] = value
			end
		end
		settings.Theme = resolveThemeName(settings.Theme)
		settings.NewElements = settings.NewElements ~= false
		settings.Resizable = settings.Resizable ~= false
		settings.HideSearchBar = settings.HideSearchBar == true

		settings.OpenButton = type(settings.OpenButton) == "table" and settings.OpenButton or {}
		if settings.OpenButton.Color == nil then
			settings.OpenButton.Color = ColorSequence.new(ACCENT, ACCENT_SOFT)
		end
		if settings.OpenButton.Enabled == nil then
			settings.OpenButton.Enabled = true
		end
		if settings.OpenButton.Draggable == nil then
			settings.OpenButton.Draggable = true
		end
		if settings.OpenButton.OnlyMobile == nil then
			settings.OpenButton.OnlyMobile = false
		end

		return settings
	end

	-- -------------------------------------------------------------------------
	-- Notification polish
	-- -------------------------------------------------------------------------

	local function findNotificationCard(wrapper)
		if not wrapper then
			return nil
		end
		for _, child in ipairs(wrapper:GetDescendants()) do
			if child.Name == "DurationFrame" and child.Parent then
				return child.Parent
			end
		end
		return wrapper:FindFirstChildWhichIsA("Frame", true)
	end

	local function polishNotificationWrapper(wrapper, style)
		if not wrapper or wrapper:FindFirstChild("AlleralNotifyRail") then
			return
		end

		local card = findNotificationCard(wrapper)
		if not card or not card:IsA("GuiObject") then
			return
		end

		local rail = Instance.new("Frame")
		rail.Name = "AlleralNotifyRail"
		rail.BackgroundColor3 = style.accent
		rail.BackgroundTransparency = 0.12
		rail.BorderSizePixel = 0
		rail.Size = UDim2.new(0, 3, 1, -10)
		rail.Position = UDim2.new(0, 6, 0, 5)
		rail.ZIndex = card.ZIndex + 4
		rail.Parent = card

		ensureStroke(card, "AlleralNotifyStroke", style.accent, 0.62, 1)

		if WindUI._AlleralNotifyCompact then
			for _, label in ipairs(card:GetDescendants()) do
				if label:IsA("TextLabel") then
					label.TextSize = math.max(13, label.TextSize - 2)
				end
			end
		end
	end

	local function ensureNotificationHook()
		if WindUI._AlleralNotifyHook then
			return
		end

		local gui = WindUI.NotificationGui
		if not gui then
			return
		end

		for _, child in ipairs(gui:GetDescendants()) do
			if child:IsA("UIListLayout") and child.Parent and child.Parent:IsA("Frame") then
				WindUI._AlleralNotifyHolder = child.Parent
				break
			end
		end

		local holder = WindUI._AlleralNotifyHolder
		if not holder then
			return
		end

		WindUI._AlleralNotifyHook = true
		holder.ChildAdded:Connect(function(wrapper)
			local style = WindUI._AlleralPendingNotifyStyle or NOTIFY_STYLES.info
			task.defer(function()
				polishNotificationWrapper(wrapper, style)
			end)
		end)
	end

	local function wrapWindowElements(window)
		if type(window) ~= "table" or window._AlleralWrapped then
			return window
		end
		window._AlleralWrapped = true

		local function polishToggleElement(elem)
			if type(elem) ~= "table" or elem._AlleralToggleDone then
				return elem
			end
			elem._AlleralToggleDone = true

			pcall(function()
				local row = elem.ToggleFrame and elem.ToggleFrame.UIElements and elem.ToggleFrame.UIElements.Main
				if not row then
					return
				end

				local track
				for _, child in ipairs(row:GetChildren()) do
					if child:FindFirstChild("Frame", true) then
						track = child
						break
					end
				end
				if not track then
					return
				end

				local stroke = ensureStroke(track, "AlleralToggleStroke", ACCENT, 0.68, 1)
				local glow = track:FindFirstChild("AlleralToggleGlow")
				if not glow then
					glow = Instance.new("Frame")
					glow.Name = "AlleralToggleGlow"
					glow.BackgroundColor3 = ACCENT
					glow.BackgroundTransparency = 0.82
					glow.BorderSizePixel = 0
					glow.Size = UDim2.new(1, 4, 1, 4)
					glow.Position = UDim2.new(0.5, 0, 0.5, 0)
					glow.AnchorPoint = Vector2.new(0.5, 0.5)
					glow.ZIndex = track.ZIndex - 1
					glow.Parent = track
					local corner = Instance.new("UICorner")
					corner.CornerRadius = UDim.new(1, 0)
					corner.Parent = glow
				end

				local function syncToggleVisual(on)
					if stroke then
						stroke.Color = on and ACCENT or Color3.fromHex("#4a6a42")
						stroke.Transparency = on and 0.28 or 0.72
					end
					if glow then
						glow.BackgroundTransparency = on and 0.72 or 0.92
					end
				end

				syncToggleVisual(elem.Value == true)

				if type(elem.Set) == "function" and not elem._AlleralSetWrapped then
					elem._AlleralSetWrapped = true
					local origSet = elem.Set
					function elem:Set(value, ...)
						local result = origSet(self, value, ...)
						syncToggleVisual(value == true)
						return result
					end
				end
			end)

			return elem
		end

		local function wrapSection(section)
			if type(section) ~= "table" or section._AlleralSectionWrapped then
				return section
			end
			section._AlleralSectionWrapped = true

			local methods = { "Toggle", "Checkbox", "Slider", "Button", "Dropdown", "Input", "Keybind" }
			for _, methodName in ipairs(methods) do
				local original = section[methodName]
				if type(original) == "function" then
					section[methodName] = function(self, opts, ...)
						local elem = original(self, opts, ...)
						if methodName == "Toggle" or methodName == "Checkbox" then
							polishToggleElement(elem)
						end
						return elem
					end
				end
			end

			return section
		end

		local function wrapTab(tab)
			if type(tab) ~= "table" or tab._AlleralTabWrapped then
				return tab
			end
			tab._AlleralTabWrapped = true

			if type(tab.Section) == "function" then
				local origSection = tab.Section
				function tab:Section(opts)
					return wrapSection(origSection(self, opts))
				end
			end

			return tab
		end

		if type(window.Tab) == "function" then
			local origTab = window.Tab
			function window:Tab(opts)
				return wrapTab(origTab(self, opts))
			end
		end

		if type(window.Section) == "function" then
			local origSection = window.Section
			function window:Section(opts)
				return wrapSection(origSection(self, opts))
			end
		end

		return window
	end

	local function startWatchdog(window)
		WindUI._AlleralWatchdogToken += 1
		local token = WindUI._AlleralWatchdogToken

		task.spawn(function()
			while WindUI._AlleralWatchdogToken == token and WindUI.Window == window do
				task.wait(18)
				if WindUI._AlleralWatchdogToken ~= token or WindUI.Window ~= window then
					break
				end
				pcall(function()
					if window.UIElements and window.UIElements.Main and window.UIElements.Main.Parent then
						WindUI:PolishWindow(window)
					else
						WindUI._AlleralWatchdogToken += 1
					end
				end)
			end
		end)
	end

	-- -------------------------------------------------------------------------
	-- Safe API wrappers
	-- -------------------------------------------------------------------------

	local _CreateWindow = WindUI.CreateWindow
	function WindUI.CreateWindow(self, settings)
		settings = normalizeWindowSettings(settings)

		local window
		for attempt = 1, 2 do
			local ok, result = pcall(function()
				return _CreateWindow(self, settings)
			end)
			if ok and result then
				window = result
				break
			end
			uiWarn("window", result)
			settings.Theme = resolveThemeName(attempt == 1 and "Alleral" or "Dark")
			task.wait(0.05)
		end

		if window then
			task.defer(function()
				wrapWindowElements(window)
				WindUI:PolishWindow(window)
				startWatchdog(window)
			end)
		end

		return window
	end

	local _Notify = WindUI.Notify
	function WindUI.Notify(self, payload)
		if type(payload) ~= "table" then
			payload = { Content = tostring(payload or "") }
		end

		local style = resolveNotifyStyle(payload)
		payload.Title = payload.Title or payload.Name or "Alleral"
		payload.Content = payload.Content or payload.Text or payload.Description or ""
		payload.Duration = math.clamp(tonumber(payload.Duration or payload.Time) or 4, 1, 30)
		if not payload.Icon and style.icon then
			payload.Icon = style.icon
			payload.IconThemed = false
		end

		ensureNotificationHook()
		WindUI._AlleralPendingNotifyStyle = style

		local waited = 0
		while WindUI._AlleralNotifyCount >= WindUI._AlleralMaxNotify and waited < 3 do
			task.wait(0.12)
			waited += 0.12
		end
		WindUI._AlleralNotifyCount += 1

		local ok, result = pcall(function()
			return _Notify(self, payload)
		end)

		if not ok and payload.Icon then
			local retryPayload = {}
			for key, value in pairs(payload) do
				retryPayload[key] = value
			end
			retryPayload.Icon = nil
			ok, result = pcall(function()
				return _Notify(self, retryPayload)
			end)
		end

		task.delay(payload.Duration + 0.35, function()
			WindUI._AlleralNotifyCount = math.max(0, WindUI._AlleralNotifyCount - 1)
		end)
		WindUI._AlleralPendingNotifyStyle = nil

		if not ok then
			uiWarn("notify", result)
			return nil
		end
		return result
	end

	local _SetNotificationLower = WindUI.SetNotificationLower
	function WindUI.SetNotificationLower(self, enabled)
		if type(_SetNotificationLower) == "function" then
			pcall(_SetNotificationLower, self, enabled == true)
		end
		WindUI._AlleralNotifyLower = enabled == true
	end

	function WindUI.SetNotificationCompact(_self, enabled)
		WindUI._AlleralNotifyCompact = enabled == true
		local holder = WindUI._AlleralNotifyHolder
		if holder then
			local layout = holder:FindFirstChildWhichIsA("UIListLayout")
			if layout then
				layout.Padding = UDim.new(0, enabled and 5 or 8)
			end
		end
	end

	function WindUI.ClearNotifications(_self)
		local mod = WindUI.NotificationModule
		local cleared = 0
		if mod and type(mod.Notifications) == "table" then
			for index, notif in pairs(mod.Notifications) do
				if type(notif) == "table" and type(notif.Close) == "function" and not notif.Closed then
					pcall(function()
						notif:Close()
					end)
					cleared += 1
				end
				mod.Notifications[index] = nil
			end
			mod.NotificationIndex = 0
		end
		WindUI._AlleralNotifyCount = 0
		return cleared
	end

	local _SetTheme = WindUI.SetTheme
	function WindUI.SetTheme(self, themeName)
		themeName = resolveThemeName(themeName)
		local theme

		pcall(function()
			theme = _SetTheme(self, themeName)
		end)
		if not theme then
			pcall(function()
				theme = _SetTheme(self, "Alleral")
			end)
		end
		if not theme then
			pcall(function()
				theme = _SetTheme(self, "Dark")
			end)
		end

		if theme and WindUI.Window then
			task.defer(function()
				WindUI:PolishWindow(WindUI.Window)
			end)
		end
		return theme
	end

	local _AddTheme = WindUI.AddTheme
	function WindUI.AddTheme(self, themeTable)
		if type(themeTable) ~= "table" or type(themeTable.Name) ~= "string" then
			return nil
		end
		local ok, result = pcall(function()
			return _AddTheme(self, themeTable)
		end)
		if not ok then
			uiWarn("theme", result)
			return nil
		end
		if WindUI.Themes and themeTable.Name then
			WindUI.Themes[themeTable.Name] = mergeTokens(WindUI.Themes[themeTable.Name] or {}, themeTable)
		end
		return result
	end

	local _Popup = WindUI.Popup
	function WindUI.Popup(self, payload)
		payload = type(payload) == "table" and payload or {}
		local ok, result = pcall(function()
			return _Popup(self, payload)
		end)
		if not ok then
			uiWarn("popup", result)
			return nil
		end
		return result
	end

	-- -------------------------------------------------------------------------
	-- Public helpers
	-- -------------------------------------------------------------------------

	function WindUI.GetAlleralVersion(_self)
		return WindUI.ALLERAL_UI_VERSION
	end

	function WindUI.SafeNotify(self, title, content, duration, notifyType)
		return WindUI:Notify({
			Title = title,
			Content = content,
			Duration = duration or 4,
			Type = notifyType or "info",
		})
	end

	function WindUI.NotifySuccess(self, title, content, duration)
		return WindUI:Notify({
			Title = title,
			Content = content,
			Duration = duration or 4,
			Type = "success",
		})
	end

	function WindUI.NotifyWarn(self, title, content, duration)
		return WindUI:Notify({
			Title = title,
			Content = content,
			Duration = duration or 5,
			Type = "warn",
		})
	end

	function WindUI.NotifyError(self, title, content, duration)
		return WindUI:Notify({
			Title = title,
			Content = content,
			Duration = duration or 6,
			Type = "error",
		})
	end

	function WindUI.ListThemeNames(_self)
		local names = {}
		for name in pairs(WindUI.Themes or {}) do
			table.insert(names, name)
		end
		table.sort(names, function(a, b)
			if a == "Alleral" then
				return true
			end
			if b == "Alleral" then
				return false
			end
			return a < b
		end)
		return names
	end

	function WindUI.CycleTheme(self, delta)
		delta = tonumber(delta) or 1
		local names = WindUI:ListThemeNames()
		if #names == 0 then
			return nil
		end

		local current = "Alleral"
		if WindUI.GetCurrentTheme then
			local ok, value = pcall(function()
				return WindUI:GetCurrentTheme()
			end)
			if ok and value then
				current = value
			end
		end

		local index = 1
		for i, name in ipairs(names) do
			if name == current then
				index = i
				break
			end
		end
		index = ((index - 1 + delta) % #names) + 1
		local nextTheme = WindUI:SetTheme(names[index])
		WindUI:FlashAccent()
		return nextTheme
	end

	function WindUI.FlashAccent(self, window)
		if WindUI._AlleralReducedMotion then
			return
		end

		window = window or WindUI.Window
		if not window or not window.UIElements or not window.UIElements.Main then
			return
		end

		local main = window.UIElements.Main
		local stroke = main:FindFirstChild("AlleralAccentStroke")
		if not stroke then
			stroke = ensureStroke(main, "AlleralAccentStroke", ACCENT, 0.2, 2)
		end

		if stroke then
			tween(stroke, TweenInfo.new(0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
				Transparency = 0.12,
				Thickness = 2,
			})
			task.delay(0.2, function()
				tween(stroke, TweenInfo.new(0.32, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
					Transparency = 0.56,
					Thickness = 1,
				})
			end)
		end
	end

	function WindUI.SetReducedMotion(_self, enabled)
		WindUI._AlleralReducedMotion = enabled == true
	end

	function WindUI.RepairWindow(self, window)
		window = window or WindUI.Window
		if not window then
			return false
		end
		local ok = pcall(function()
			installThemes()
			wrapWindowElements(window)
			WindUI:PolishWindow(window)
			if type(window.CanDropdown) ~= "boolean" then
				window.CanDropdown = true
			end
			ensureNotificationHook()
		end)
		return ok == true
	end

	function WindUI.SelfTest(_self)
		local checks = {
			create = type(WindUI.CreateWindow) == "function",
			theme = WindUI.Themes and WindUI.Themes.Alleral ~= nil,
			patch = WindUI.ALLERAL_UI_VERSION ~= nil,
			notify = type(WindUI.Notify) == "function",
			clear = type(WindUI.ClearNotifications) == "function",
		}
		local ok = checks.create and checks.theme and checks.patch and checks.notify
		return ok, checks
	end

	pcall(function()
		WindUI:OnThemeChange(function()
			if WindUI.Window then
				task.defer(function()
					WindUI:PolishWindow(WindUI.Window)
				end)
			end
		end)
	end)

	pcall(function()
		WindUI:SetTheme("Alleral")
	end)

	ensureNotificationHook()
	if WindUI._AlleralNotifyCompact then
		WindUI:SetNotificationCompact(true)
	end

	local passed = WindUI:SelfTest()
	if not passed then
		uiWarn("selftest", "theme bootstrap incomplete")
	end

	return WindUI
end
