--[[
	Alleral WindUI revamp (Footagesus 1.6.64-fix base)
	Exe 6-inspired bento layout + motion: neutral dark canvas, solid section cards, Quint page transitions.
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

	-- Exe 6-inspired tokens: neutral dark canvas, accent used sparingly (see devforum Exe 6 bento layout).
	local palette = {
		accent = Color3.fromHex("#53fc18"),
		accentSoft = Color3.fromHex("#7dff35"),
		accentHot = Color3.fromHex("#30ff6a"),
		canvas = Color3.fromHex("#0b0b0d"),
		surface = Color3.fromHex("#141418"),
		card = Color3.fromHex("#1c1c22"),
		cardHover = Color3.fromHex("#22222a"),
		line = Color3.fromHex("#2a2a32"),
		text = Color3.fromHex("#f2f2f7"),
		muted = Color3.fromHex("#8e8e93"),
	}

	local function accent()
		return palette.accent
	end
	local function accentSoft()
		return palette.accentSoft
	end
	local function accentHot()
		return palette.accentHot
	end

	WindUI.ALLERAL_UI_VERSION = "1.6.64-fix-aller8"
	WindUI._AlleralNotifyCount = 0
	WindUI._AlleralMaxNotify = 8
	WindUI._AlleralWatchdogToken = 0
	WindUI._AlleralReducedMotion = WindUI._AlleralReducedMotion == true
	WindUI._AlleralNotifyCompact = WindUI._AlleralNotifyCompact == true
	WindUI._AlleralNotifyHolder = WindUI._AlleralNotifyHolder
	WindUI._AlleralPendingNotifyStyle = nil

	local NOTIFY_STYLES = {
		info = {
			accent = palette.text,
			icon = "info",
		},
		success = {
			accent = accent(),
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

	-- Exe 6-style motion (Quint/Quart/Exponential — matches Flare page + menu easing).
	local ANIM = {
		open = TweenInfo.new(0.42, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
		close = TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.In),
		page = TweenInfo.new(0.28, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
		pageOut = TweenInfo.new(0.16, Enum.EasingStyle.Quart, Enum.EasingDirection.In),
		micro = TweenInfo.new(0.2, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
		notify = TweenInfo.new(0.34, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
		dropdown = TweenInfo.new(0.26, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
		sweep = TweenInfo.new(0.52, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out),
	}

	WindUI._AlleralStartupEffect = WindUI._AlleralStartupEffect ~= false

	local POLISH_SKIP = {
		AlleralPageFade = true,
		AlleralStartupSweep = true,
		AlleralSidebarDivider = true,
		AlleralToggleGlow = true,
		AlleralNotifyRail = true,
		AlleralTopbarLine = true,
		MenuCanvas = true,
		Menu = true,
	}

	local function motionEnabled()
		return WindUI._AlleralReducedMotion ~= true
	end

	local function isDropdownDescendant(gui)
		local dropdownGui = WindUI.DropdownGui
		return dropdownGui and gui and gui:IsDescendantOf(dropdownGui)
	end

	local function cleanupLegacyPolish(root)
		if not root then
			return
		end
		for _, desc in ipairs(root:GetDescendants()) do
			if desc.Name == "AlleralMenuScale" or desc.Name == "AlleralNotifyScale" then
				desc:Destroy()
			end
		end
	end

	local function ensureUiScale(gui, name)
		if not gui or not gui:IsA("GuiObject") then
			return nil
		end
		local scale = gui:FindFirstChild(name)
		if not scale then
			scale = Instance.new("UIScale")
			scale.Name = name
			scale.Parent = gui
		end
		return scale
	end

	local function ensurePageFade(container)
		if not container or not container:IsA("GuiObject") then
			return nil
		end
		local fade = container:FindFirstChild("AlleralPageFade")
		if not fade then
			fade = Instance.new("Frame")
			fade.Name = "AlleralPageFade"
			fade.BackgroundColor3 = palette.canvas
			fade.BackgroundTransparency = 1
			fade.BorderSizePixel = 0
			fade.Size = UDim2.fromScale(1, 1)
			fade.Position = UDim2.fromOffset(0, 0)
			fade.ZIndex = 8
			fade.Active = false
			fade.Selectable = false
			fade.Parent = container
		end
		return fade
	end

	local function playStartupEffect(window)
		if not motionEnabled() or WindUI._AlleralStartupEffect == false then
			return
		end
		local main = window.UIElements and window.UIElements.Main
		if not main then
			return
		end

		cleanupLegacyPolish(main)

		local scale = ensureUiScale(main, "AlleralStartupScale")
		if scale then
			scale.Scale = 0.968
			tween(scale, ANIM.open, { Scale = 1 })
		end

		local topbar = window.UIElements.Topbar and window.UIElements.Topbar.Main
		if topbar then
			local sweep = topbar:FindFirstChild("AlleralStartupSweep")
			if not sweep then
				sweep = Instance.new("Frame")
				sweep.Name = "AlleralStartupSweep"
				sweep.BackgroundColor3 = accent()
				sweep.BorderSizePixel = 0
				sweep.Size = UDim2.new(0, 0, 0, 2)
				sweep.Position = UDim2.new(0, 0, 1, -1)
				sweep.ZIndex = topbar.ZIndex + 5
				sweep.Parent = topbar
			end
			sweep.BackgroundTransparency = 0.35
			sweep.Size = UDim2.new(0, 0, 0, 2)
			tween(sweep, ANIM.sweep, {
				Size = UDim2.new(1, 0, 0, 2),
				BackgroundTransparency = 0.78,
			})
		end

		WindUI:FlashAccent(window)
	end

	local function animateNotificationIn(card, rail)
		if not motionEnabled() or not card then
			return
		end
		cleanupLegacyPolish(card)
		if card:IsA("ImageLabel") or card:IsA("ImageButton") then
			local target = card.ImageTransparency
			card.ImageTransparency = math.clamp(target + 0.18, 0, 1)
			tween(card, ANIM.notify, { ImageTransparency = target })
		end
		local stroke = card:FindFirstChild("AlleralNotifyStroke")
		if stroke then
			stroke.Transparency = 0.88
			tween(stroke, ANIM.micro, { Transparency = 0.62 })
		end
		if rail then
			local full = rail.Size
			rail.Size = UDim2.new(0, 0, full.Y.Scale, full.Y.Offset)
			tween(rail, ANIM.micro, { Size = full })
		end
	end

	local function animateDropdownMenu(canvas)
		if not motionEnabled() or not canvas then
			return
		end
		cleanupLegacyPolish(canvas)

		local menu = canvas:FindFirstChild("Menu")
		if not menu or not menu:IsA("GuiObject") then
			return
		end

		if menu:IsA("ImageLabel") then
			local target = menu.ImageTransparency
			menu.ImageTransparency = math.clamp(target + 0.22, 0, 1)
			tween(menu, ANIM.dropdown, { ImageTransparency = target })
		end

		local stroke = menu:FindFirstChild("AlleralMenuStroke")
		if not stroke then
			stroke = Instance.new("UIStroke")
			stroke.Name = "AlleralMenuStroke"
			stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
			stroke.BorderStrokePosition = Enum.BorderStrokePosition.Inner
			stroke.LineJoinMode = Enum.LineJoinMode.Round
			stroke.Color = palette.line
			stroke.Thickness = 1
			stroke.Parent = menu
		end
		stroke.Transparency = 0.82
		tween(stroke, ANIM.dropdown, { Transparency = 0.52 })
	end

	local function resetDropdownMenu(canvas)
		if not canvas then
			return
		end
		cleanupLegacyPolish(canvas)
		local menu = canvas:FindFirstChild("Menu")
		if menu and menu:IsA("ImageLabel") then
			menu.ImageTransparency = 0.05
		end
	end

	local function trackDropdownCanvas(canvas)
		if not canvas or canvas._AlleralDropdownTracked then
			return
		end
		canvas._AlleralDropdownTracked = true
		pcall(function()
			canvas:GetPropertyChangedSignal("Visible"):Connect(function()
				if canvas.Visible then
					task.defer(function()
						animateDropdownMenu(canvas)
					end)
				else
					resetDropdownMenu(canvas)
				end
			end)
		end)
	end

	local function installDropdownAnimations()
		if WindUI._AlleralDropdownHook then
			return
		end
		local gui = WindUI.DropdownGui
		if not gui then
			WindUI._AlleralDropdownRetries = (WindUI._AlleralDropdownRetries or 0) + 1
			if WindUI._AlleralDropdownRetries < 12 then
				task.delay(0.35, installDropdownAnimations)
			end
			return
		end
		WindUI._AlleralDropdownHook = true
		for _, desc in ipairs(gui:GetDescendants()) do
			if desc.Name == "MenuCanvas" then
				trackDropdownCanvas(desc)
			end
		end
		gui.DescendantAdded:Connect(function(desc)
			if desc.Name == "MenuCanvas" then
				trackDropdownCanvas(desc)
			end
		end)
	end

	local function installWindowAnimations(window)
		if type(window) ~= "table" or window._AlleralAnimWrapped then
			return window
		end
		window._AlleralAnimWrapped = true

		if type(window.Open) == "function" and not window._AlleralOpenWrapped then
			window._AlleralOpenWrapped = true
			local origOpen = window.Open
			function window:Open(...)
				local result = origOpen(self, ...)
				if WindUI._AlleralStartupEffect ~= false then
					task.defer(function()
						task.wait(0.06)
						playStartupEffect(self)
					end)
				end
				return result
			end
		end

		if type(window.Close) == "function" and not window._AlleralCloseWrapped then
			window._AlleralCloseWrapped = true
			local origClose = window.Close
			function window:Close(...)
				if motionEnabled() then
					local main = self.UIElements and self.UIElements.Main
					local scale = main and main:FindFirstChild("AlleralStartupScale")
					if scale then
						tween(scale, ANIM.close, { Scale = 0.988 })
					end
				end
				local result = origClose(self, ...)
				task.delay(0.45, function()
					local main = self.UIElements and self.UIElements.Main
					local scale = main and main:FindFirstChild("AlleralStartupScale")
					if scale then
						scale.Scale = 1
					end
				end)
				return result
			end
		end

		if type(window.SelectTab) == "function" and not window._AlleralSelectTabWrapped then
			window._AlleralSelectTabWrapped = true
			local origSelectTab = window.SelectTab
			function window:SelectTab(index)
				if not motionEnabled() then
					return origSelectTab(self, index)
				end
				local result = origSelectTab(self, index)
				local tabMod = self.TabModule
				local nextContainer = tabMod and tabMod.Containers and tabMod.Containers[index]
				if nextContainer then
					local fade = ensurePageFade(nextContainer)
					if fade then
						fade.BackgroundTransparency = 0.22
						tween(fade, ANIM.page, { BackgroundTransparency = 1 })
					end
				end
				return result
			end
		end

		return window
	end

	local WINDOW_DEFAULTS = {
		Theme = "Alleral",
		NewElements = true,
		UICorner = 18,
		UIPadding = 18,
		SideBarWidth = 248,
		ElementPadding = 12,
		Resizable = true,
		HideSearchBar = false,
	}

	local function getSharedChrome()
		return {
			WindowShadow = Color3.fromHex("#000000"),
			WindowTopbarButtonIcon = palette.muted,
			SearchBarBorder = palette.line,
			SectionExpandIcon = palette.muted,
			DropdownTabBorder = palette.line,
			CheckboxBorder = palette.line,
			SliderThumb = Color3.fromHex("#ffffff"),
			Hover = accent(),
			BackgroundTransparency = 0,
		}
	end

	local function fullTheme(name, accentCol, bg, panel, text, muted, button, tabActive)
		return mergeTokens(getSharedChrome(), {
			Name = name,
			Accent = accentCol,
			Primary = accentCol,
			Outline = palette.line,
			Icon = accentCol,
			Toggle = accentCol,
			Slider = button,
			Checkbox = accentCol,
			SliderIcon = button,
			Dialog = panel,
			Background = bg,
			Button = button,
			Text = text,
			Placeholder = muted,
			PanelBackground = panel,
			PanelBackgroundTransparency = 0.04,
			LabelBackground = palette.surface,
			LabelBackgroundTransparency = 0.08,
			ElementBackground = palette.card,
			ElementBackgroundTransparency = 0.02,
			ElementTitle = text,
			ElementDesc = muted,
			ElementIcon = accentCol,
			TabBackground = bg,
			TabBackgroundHover = palette.cardHover,
			TabBackgroundHoverTransparency = 0.12,
			TabBackgroundActive = tabActive,
			TabBackgroundActiveTransparency = 0.06,
			TabText = text,
			TabTextTransparency = 0.22,
			TabTextTransparencyActive = 0,
			TabIcon = muted,
			TabIconTransparency = 0.18,
			TabIconTransparencyActive = 0,
			TabBorder = palette.line,
			TabBorderTransparency = 0.72,
			TabBorderTransparencyActive = 0.42,
			WindowBackground = bg,
			WindowTopbarTitle = text,
			WindowTopbarAuthor = muted,
			WindowTopbarIcon = accentCol,
			WindowSearchBarBackground = palette.surface,
			SearchBarBorderTransparency = 0.55,
			SectionBoxBackground = palette.card,
			SectionBoxBackgroundTransparency = 0.04,
			SectionBoxBorder = palette.line,
			SectionBoxBorderTransparency = 0.58,
			SectionExpandIconTransparency = 0.12,
			Notification = palette.card,
			NotificationTitle = text,
			NotificationContent = muted,
			NotificationBorder = palette.line,
			NotificationBorderTransparency = 0.45,
			PopupBackground = palette.card,
			DialogBackground = palette.card,
			ToggleBar = accentCol,
			CheckboxBorderTransparency = 0.55,
			Tooltip = palette.card,
			TooltipText = text,
		})
	end

	local function buildThemePack()
		return {
			Alleral = fullTheme(
				"Alleral",
				accent(),
				palette.canvas,
				palette.surface,
				palette.text,
				palette.muted,
				accentSoft(),
				palette.cardHover
			),
			AlleralNeon = fullTheme(
				"AlleralNeon",
				accentHot(),
				Color3.fromHex("#070708"),
				Color3.fromHex("#101014"),
				palette.text,
				palette.muted,
				accent(),
				Color3.fromHex("#26262e")
			),
			AlleralMidnight = fullTheme(
				"AlleralMidnight",
				Color3.fromHex("#3ddc84"),
				Color3.fromHex("#050506"),
				Color3.fromHex("#0e0e12"),
				Color3.fromHex("#ececf1"),
				Color3.fromHex("#7c7c86"),
				Color3.fromHex("#2ecc71"),
				Color3.fromHex("#1a1a22")
			),
			Dark = fullTheme(
				"Dark",
				accent(),
				palette.canvas,
				palette.surface,
				palette.text,
				palette.muted,
				accentSoft(),
				palette.cardHover
			),
		}
	end

	local THEME_PACK = buildThemePack()

	local function installThemes()
		local pack = buildThemePack()
		for themeName, tokens in pairs(pack) do
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

	local function ensureStroke(frame, name, color, transparency, thickness, opts)
		opts = opts or {}
		if not frame or not frame:IsA("GuiObject") then
			return nil
		end
		if isDropdownDescendant(frame) then
			return nil
		end
		local stroke = frame:FindFirstChild(name)
		if not stroke and opts.reuseExisting ~= false then
			stroke = frame:FindFirstChildOfClass("UIStroke")
			if stroke and stroke.Name:sub(1, 7) ~= "Alleral" then
				stroke.Name = name
			end
		end
		if not stroke then
			stroke = Instance.new("UIStroke")
			stroke.Name = name
			stroke.Parent = frame
		end
		stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		stroke.BorderStrokePosition = opts.inner == false and Enum.BorderStrokePosition.Center
			or Enum.BorderStrokePosition.Inner
		stroke.LineJoinMode = Enum.LineJoinMode.Round
		stroke.Color = color or palette.line
		stroke.Thickness = thickness or 1
		stroke.Transparency = transparency or 0.55
		return stroke
	end

	local function ensureCorner(frame, radius)
		if not frame or not frame:IsA("GuiObject") then
			return nil
		end
		local corner = frame:FindFirstChildOfClass("UICorner")
		if not corner then
			corner = Instance.new("UICorner")
			corner.CornerRadius = radius or UDim.new(0, 10)
			corner.Parent = frame
		end
		return corner
	end

	local function polishSectionOutlines(root)
		if not root then
			return
		end
		for _, desc in ipairs(root:GetDescendants()) do
			if desc.Name == "Outline" and desc:IsA("ImageLabel") and not isDropdownDescendant(desc) then
				ensureStroke(desc, "AlleralOutlineStroke", palette.line, 0.78, 1, {
					inner = true,
					reuseExisting = false,
				})
			end
		end
	end

	local function addTopbarLine(topbar)
		if not topbar or not topbar:IsA("GuiObject") then
			return
		end
		if topbar:FindFirstChild("AlleralTopbarLine") then
			return
		end
		local line = Instance.new("Frame")
		line.Name = "AlleralTopbarLine"
		line.BackgroundColor3 = palette.line
		line.BackgroundTransparency = 0.55
		line.BorderSizePixel = 0
		line.Size = UDim2.new(1, -24, 0, 1)
		line.Position = UDim2.new(0, 12, 1, -1)
		line.ZIndex = topbar.ZIndex + 2
		line.Parent = topbar
	end

	local function syncWindowStroke(main)
		if not main then
			return nil
		end
		ensureCorner(main, UDim.new(0, WINDOW_DEFAULTS.UICorner))
		return ensureStroke(main, "AlleralWindowStroke", palette.line, 0.58, 1, { inner = true })
	end

	local function addSidebarDivider(sidebar)
		if not sidebar or not sidebar:IsA("GuiObject") then
			return
		end
		if sidebar:FindFirstChild("AlleralSidebarDivider") then
			return
		end

		local divider = Instance.new("Frame")
		divider.Name = "AlleralSidebarDivider"
		divider.BackgroundColor3 = palette.line
		divider.BackgroundTransparency = 0.35
		divider.BorderSizePixel = 0
		divider.Size = UDim2.new(0, 1, 1, -16)
		divider.Position = UDim2.new(1, -1, 0, 8)
		divider.ZIndex = sidebar.ZIndex + 2
		divider.Parent = sidebar
	end

	function WindUI.PolishWindow(_self, window)
		if type(window) ~= "table" or type(window.UIElements) ~= "table" then
			return window
		end

		pcall(function()
			local main = window.UIElements.Main
			if main then
				cleanupLegacyPolish(main)
				syncWindowStroke(main)
			end

			local topbar = window.UIElements.Topbar
			if topbar and topbar.Main then
				addTopbarLine(topbar.Main)
			end

			local sidebar = window.UIElements.SideBar
			if sidebar then
				addSidebarDivider(sidebar)
			end

			if window.SearchBar and window.SearchBar.Frame then
				local search = window.SearchBar.Frame
				ensureCorner(search, UDim.new(0, 10))
				ensureStroke(search, "AlleralSearchStroke", palette.line, 0.64, 1, { inner = true })
			end

			if window.UIElements.MainBar then
				polishSectionOutlines(window.UIElements.MainBar)
			end
			if main then
				task.defer(function()
					if window.UIElements and window.UIElements.Main == main and main.Parent then
						polishSectionOutlines(main)
					end
				end)
			end

			window.CanDropdown = true
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
			settings.OpenButton.Color = ColorSequence.new(accent(), accentSoft())
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

		ensureStroke(card, "AlleralNotifyStroke", style.accent, 0.62, 1, { inner = true })

		animateNotificationIn(card, rail)

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

				ensureCorner(track, UDim.new(1, 0))
				local stroke = ensureStroke(track, "AlleralToggleStroke", palette.line, 0.62, 1, { inner = true })
				local glow = track:FindFirstChild("AlleralToggleGlow")
				if not glow then
					glow = Instance.new("Frame")
					glow.Name = "AlleralToggleGlow"
					glow.BackgroundColor3 = accent()
					glow.BackgroundTransparency = 0.9
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
						tween(stroke, ANIM.micro, {
							Color = on and accent() or palette.line,
							Transparency = on and 0.35 or 0.68,
						})
					end
					if glow then
						tween(glow, ANIM.micro, {
							BackgroundTransparency = on and 0.82 or 0.96,
						})
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

	function WindUI.ReleaseWindow(self, window)
		window = window or WindUI.Window
		if not window then
			return false
		end
		WindUI._AlleralWatchdogToken = (WindUI._AlleralWatchdogToken or 0) + 1
		pcall(function()
			if type(window.Close) == "function" then
				window:Close()
			end
		end)
		if WindUI.Window == window then
			WindUI.Window = nil
		end
		return true
	end

	function WindUI.CreateWindow(self, settings)
		settings = normalizeWindowSettings(settings)

		if WindUI.Window then
			WindUI:ReleaseWindow(WindUI.Window)
			task.wait(0.05)
		end

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
			if WindUI.Window then
				WindUI:ReleaseWindow(WindUI.Window)
				task.wait(0.05)
			end
			settings.Theme = resolveThemeName(attempt == 1 and "Alleral" or "Dark")
			task.wait(0.05)
		end

		if window then
			wrapWindowElements(window)
			installWindowAnimations(window)
			task.defer(function()
				installDropdownAnimations()
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
		if result and motionEnabled() then
			task.defer(function()
				local main = type(result) == "table" and result.UIElements and result.UIElements.Main
				if main and main:IsA("GuiObject") then
					ensureCorner(main, UDim.new(0, 14))
					local stroke = ensureStroke(main, "AlleralPopupStroke", palette.line, 0.72, 1, { inner = true })
					if main:IsA("ImageLabel") then
						local target = main.ImageTransparency
						main.ImageTransparency = math.clamp(target + 0.2, 0, 1)
						tween(main, ANIM.open, { ImageTransparency = target })
					end
					if stroke then
						stroke.Transparency = 0.9
						tween(stroke, ANIM.open, { Transparency = 0.58 })
					end
				end
			end)
		end
		return result
	end

	-- -------------------------------------------------------------------------
	-- Public helpers
	-- -------------------------------------------------------------------------

	function WindUI.GetAlleralVersion(_self)
		return WindUI.ALLERAL_UI_VERSION
	end

	function WindUI.SetAccentColor(_self, color)
		if typeof(color) ~= "Color3" then
			return false
		end
		palette.accent = color
		palette.accentSoft = color:Lerp(Color3.new(1, 1, 1), 0.28)
		palette.accentHot = color:Lerp(Color3.new(0, 0, 0), 0.12)
		NOTIFY_STYLES.success.accent = palette.accent
		installThemes()
		if WindUI.Window then
			WindUI:RepairWindow(WindUI.Window)
		end
		return true
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
		local stroke = main:FindFirstChild("AlleralWindowStroke")
		if not stroke then
			stroke = syncWindowStroke(main)
		end

		if stroke then
			tween(stroke, ANIM.micro, {
				Color = accent(),
				Transparency = 0.28,
				Thickness = 1.5,
			})
			task.delay(0.2, function()
				tween(stroke, TweenInfo.new(0.32, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
					Color = palette.line,
					Transparency = 0.62,
					Thickness = 1,
				})
			end)
		end
	end

	function WindUI.SetReducedMotion(_self, enabled)
		WindUI._AlleralReducedMotion = enabled == true
	end

	function WindUI.SetStartupEffect(_self, enabled)
		WindUI._AlleralStartupEffect = enabled ~= false
	end

	function WindUI.RepairWindow(self, window)
		window = window or WindUI.Window
		if not window then
			return false
		end
		local ok = pcall(function()
			installThemes()
			cleanupLegacyPolish(WindUI.DropdownGui)
			wrapWindowElements(window)
			installWindowAnimations(window)
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
	task.defer(function()
		installDropdownAnimations()
	end)
	if WindUI._AlleralNotifyCompact then
		WindUI:SetNotificationCompact(true)
	end

	local passed = WindUI:SelfTest()
	if not passed then
		uiWarn("selftest", "theme bootstrap incomplete")
	end

	return WindUI
end
