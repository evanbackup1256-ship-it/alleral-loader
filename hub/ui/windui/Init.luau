-- Alleral V12 — WindUI framework entry (unified manager architecture)
return function(loadModule, Core)
	local Text = loadModule("Text")()
	local Guards = loadModule("Guards")()
	local GameTabSchemasEarly = loadModule("GameTabSchemas")()
	local GameRegistry = loadModule("GameRegistry")(Core, GameTabSchemasEarly)
	local Cache = loadModule("Cache")()
	local Bootstrap = loadModule("Bootstrap")(Core, Text, GameRegistry)
	local WindUI = Bootstrap.loadWindUI()
	local Patch = loadModule("Patch")(WindUI)
	local Theme = loadModule("Theme")(WindUI, Bootstrap)

	local Runtime = loadModule("Runtime")(loadModule, Core)
	local EventBus = Runtime.EventBus
	local ConnectionTracker = Runtime.ConnectionTracker
	local PerformanceManager = Runtime.PerformanceManager
	local AnimationManager = Runtime.AnimationManager
	local LayoutManager = Runtime.LayoutManager
	local GameTabSchemas = Runtime.GameTabSchemas

	local DragManager = loadModule("managers/DragManager")(EventBus, ConnectionTracker, PerformanceManager)
	local ResizeManager = loadModule("managers/ResizeManager")(EventBus, ConnectionTracker, PerformanceManager, Theme)
	local ThemeManager = loadModule("managers/ThemeManager")(EventBus, Theme, Bootstrap)
	local TabManager = loadModule("managers/TabManager")(EventBus, GameTabSchemas, Bootstrap, GameRegistry)
	local NotificationManager = loadModule("managers/NotificationManager")(EventBus, Bootstrap)
	local GameUIBuilder = loadModule("managers/GameUIBuilder")(EventBus, GameTabSchemas, TabManager, Bootstrap)
	local ConfigUIBuilder = loadModule("managers/ConfigUIBuilder")(EventBus, GameRegistry, Bootstrap)
	local DashboardBuilder = loadModule("managers/DashboardBuilder")(EventBus, Bootstrap)

	local Motion = AnimationManager
	local TooltipManager = loadModule("TooltipManager")()
	local SearchGlow = loadModule("SearchGlow")(Theme)
	local VisualPolish = loadModule("VisualPolish")(Theme)
	local ElementPolish = loadModule("ElementPolish")(Theme, Motion)
	local Validate = loadModule("Validate")(Bootstrap, GameRegistry)
	local ValidationManager = loadModule("managers/ValidationManager")(EventBus, Validate, TabManager, PerformanceManager)
	local Notifications = NotificationManager
	local Controls = loadModule("Controls")(Bootstrap, Motion, Text, Guards, TooltipManager, Theme)

	local WindowManager = loadModule("managers/WindowManager")(
		EventBus,
		ConnectionTracker,
		PerformanceManager,
		AnimationManager,
		DragManager,
		ResizeManager,
		LayoutManager,
		ThemeManager,
		ElementPolish,
		VisualPolish,
		SearchGlow
	)

	local WindowMod = loadModule("Window")(
		WindUI,
		Bootstrap,
		Controls,
		Notifications,
		Theme,
		WindowManager,
		ValidationManager,
		TabManager,
		TooltipManager,
		Cache,
		Patch
	)

	local Configs = loadModule("Configs")(Bootstrap, GameRegistry)
	local Tabs = loadModule("Tabs")(GameRegistry, Cache, GameTabSchemas)

	local gameId, gameMeta = GameRegistry.resolve({})
	gameId = tostring(gameId or Bootstrap.resolveGameId(Core) or "unsupported")
	Cache.setGame(gameId)

	pcall(ThemeManager.register)
	pcall(AnimationManager.logPerformance)
	pcall(DragManager.logReady)
	pcall(ResizeManager.logReady)
	pcall(LayoutManager.logReady)
	pcall(WindowManager.logReady)
	pcall(PerformanceManager.logReady)
	pcall(function()
		local Log = getgenv and getgenv().Alleral_Log
		if Log and Log.info then
			Log.info("V12 runtime active; event bus + managers online")
		end
	end)

	local STATE = {
		tabCount = 0,
		groupCount = 0,
		controls = 0,
		groupRegistry = {},
		missingBindings = {},
		activeWindow = nil,
		uiDestroyed = false,
		gameId = gameId,
		gameName = gameMeta and gameMeta.name or "Unsupported",
		placeId = game.PlaceId,
	}

	local Library = {
		Version = Bootstrap.VERSION,
		Engine = Bootstrap.ENGINE,
		WindUI = WindUI,
		Theme = Theme.NAME,
	}

	function Library:CreateWindow(settings)
		settings = type(settings) == "table" and settings or {}
		local resolvedId = tostring(settings.GameId or GameRegistry.resolve({}) or STATE.gameId or "unsupported")
		if STATE.gameId and STATE.gameId ~= resolvedId then
			if STATE.activeWindow then
				pcall(function() STATE.activeWindow:Unload() end)
			end
			Cache.clearGame(STATE.gameId)
			TabManager.clearCache(STATE.gameId)
			STATE.tabCount = 0
			STATE.groupCount = 0
			STATE.controls = 0
			STATE.groupRegistry = {}
			STATE.missingBindings = {}
			if Core and type(Core.clearUiStateBindings) == "function" then
				pcall(Core.clearUiStateBindings)
			end
			if Core then
				Core._UiTabRegistry = {}
			end
		end
		STATE.gameId = resolvedId
		Cache.setGame(resolvedId)
		local meta = GameRegistry.get(resolvedId)
		STATE.gameName = meta and meta.name or "Unsupported"
		STATE.placeId = game.PlaceId

		if STATE.activeWindow and STATE.activeWindow._gameId == resolvedId and STATE.activeWindow._built then
			return STATE.activeWindow
		end
		if STATE.activeWindow then
			pcall(function() STATE.activeWindow:Unload() end)
			STATE.activeWindow = nil
		end
		STATE.tabCount = 0
		STATE.groupCount = 0
		STATE.controls = 0
		STATE.uiDestroyed = false

		settings.GameId = resolvedId
		settings.ConfigFolder = settings.ConfigFolder or ConfigUIBuilder.namespace(resolvedId)

		local win = WindowMod.create(settings, STATE)
		STATE.activeWindow = win
		return win
	end

	function Library:Notification(info)
		if type(info) == "string" then
			return Notifications.push(WindUI, "Alleral", info, "info", 4)
		end
		info = type(info) == "table" and info or {}
		return Notifications.push(
			WindUI,
			Bootstrap.sanitize(info.Title or info.Name or "Alleral", 80),
			info.Description or info.Content or info.Text or "",
			info.Type or "info",
			info.Duration or info.Lifetime or 4
		)
	end

	function Library:Notify(text, dur)
		if type(text) == "table" then
			return Library:Notification(text)
		end
		return Notifications.push(WindUI, "Alleral", text, "info", dur or 4)
	end

	function Library:ClearNotifications()
		Notifications.clear()
	end

	function Library:SetTheme(name)
		pcall(function()
			if WindUI.SetTheme then
				WindUI:SetTheme(Bootstrap.sanitize(name, 32))
			end
		end)
	end

	function Library:GetLayoutInfo()
		return {
			profile = "windui-v12-unified",
			engine = Bootstrap.ENGINE,
			version = Bootstrap.VERSION,
			stack = "WindUI",
			theme = Theme.NAME,
			gameId = STATE.gameId,
			gameName = STATE.gameName,
			navigation = GameUIBuilder.suggestTabOrder(STATE.gameId),
		}
	end

	function Library:OpenSearch()
		pcall(function()
			if STATE.activeWindow and STATE.activeWindow._wind and STATE.activeWindow._wind.OpenSearch then
				STATE.activeWindow._wind:OpenSearch()
			end
		end)
	end

	function Library:GetPerfStats()
		local win = STATE.activeWindow
		return {
			cache = Cache.stats(),
			tooltips = TooltipManager.getStats and TooltipManager.getStats() or {},
			dragging = DragManager.isDragging and DragManager.isDragging(win and win._wind) or false,
			windowState = win and win.GetWindowState and win:GetWindowState() or "Unknown",
			tweens = AnimationManager.getActiveTweenCount and AnimationManager.getActiveTweenCount() or 0,
			animatingWindow = WindowManager.isAnimating and WindowManager.isAnimating() or false,
			gameId = STATE.gameId,
			tabId = win and win._activeTab and win._activeTab._name or nil,
			lastOpen = win and win._lastOpen or 0,
			lastClose = win and win._lastClose or 0,
			connections = ConnectionTracker.count(),
			notifications = Notifications.stats and Notifications.stats() or {},
			performance = PerformanceManager.stats and PerformanceManager.stats() or {},
		}
	end

	return {
		Library = Library,
		STATE = STATE,
		Runtime = Runtime,
		EventBus = EventBus,
		ConnectionTracker = ConnectionTracker,
		PerformanceManager = PerformanceManager,
		WindowManager = WindowManager,
		DragManager = DragManager,
		ResizeManager = ResizeManager,
		AnimationManager = AnimationManager,
		LayoutManager = LayoutManager,
		TabManager = TabManager,
		ThemeManager = ThemeManager,
		NotificationManager = NotificationManager,
		ValidationManager = ValidationManager,
		GameUIBuilder = GameUIBuilder,
		ConfigUIBuilder = ConfigUIBuilder,
		DashboardBuilder = DashboardBuilder,
		Bootstrap = Bootstrap,
		Text = Text,
		Theme = Theme,
		Motion = Motion,
		Drag = DragManager,
		TooltipManager = TooltipManager,
		Guards = Guards,
		Validate = Validate,
		Configs = Configs,
		Tabs = Tabs,
		Cache = Cache,
		GameRegistry = GameRegistry,
		GameTabSchemas = GameTabSchemas,
		Patch = Patch,
		WindUI = WindUI,
		sanitize = Bootstrap.sanitize,
		log = function(lvl, msg)
			if msg == nil then
				msg = lvl
				lvl = "INFO"
			end
			local Log = nil
			pcall(function()
				if getgenv then
					Log = getgenv().Alleral_Log
				end
			end)
			if Log then
				if lvl == "WARN" or lvl == "ERROR" then
					Log.warn(msg)
				else
					Log.info(msg)
				end
				return
			end
			warn("[Alleral] [" .. tostring(lvl) .. "] " .. Bootstrap.sanitize(msg, 500))
		end,
	}
end