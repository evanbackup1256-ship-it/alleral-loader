-- Alleral V11.4 — WindUI framework entry (sole UI stack)
return function(loadModule, Core)
	local Text = loadModule("Text")()
	local Guards = loadModule("Guards")()
	local GameRegistry = loadModule("GameRegistry")(Core)
	local Cache = loadModule("Cache")()
	local Bootstrap = loadModule("Bootstrap")(Core, Text, GameRegistry)
	local WindUI = Bootstrap.loadWindUI()
	local Patch = loadModule("Patch")(WindUI)
	local Theme = loadModule("Theme")(WindUI, Bootstrap)
	local Motion = loadModule("Motion")()
	local TooltipManager = loadModule("TooltipManager")()
	local SearchGlow = loadModule("SearchGlow")()
	local Drag = loadModule("Drag")(Motion, TooltipManager)
	local Validate = loadModule("Validate")(Bootstrap, GameRegistry)
	local Notifications = loadModule("Notifications")(WindUI, Bootstrap)
	local Controls = loadModule("Controls")(Bootstrap, Motion, Text, Guards, TooltipManager)
	local WindowMod = loadModule("Window")(WindUI, Bootstrap, Controls, Notifications, Theme, Motion, Validate, Drag, TooltipManager, Cache, Patch, SearchGlow)
	local Configs = loadModule("Configs")(Bootstrap, GameRegistry)
	local Tabs = loadModule("Tabs")(GameRegistry, Cache)

	local gameId, gameMeta = GameRegistry.resolve({})
	gameId = tostring(gameId or Bootstrap.resolveGameId(Core) or "unsupported")
	Cache.setGame(gameId)

	pcall(function() Theme.register() end)
	pcall(function() Motion.logPerformance() end)
	pcall(function() Drag.logReady() end)
	pcall(function()
		local Log = getgenv and getgenv().Alleral_Log
		if Log and Log.info then
			Log.info("UI cached; toggles do not rebuild")
			Log.info("Tab cache active")
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
		settings.ConfigFolder = settings.ConfigFolder or Configs.getNamespace(resolvedId)

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
			profile = "windui-v11.4-premium",
			engine = Bootstrap.ENGINE,
			version = Bootstrap.VERSION,
			stack = "WindUI",
			theme = Theme.NAME,
			gameId = STATE.gameId,
			gameName = STATE.gameName,
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
			dragging = Drag.isDragging and Drag.isDragging() or false,
			windowState = win and win.GetWindowState and win:GetWindowState() or "Unknown",
			tweens = Motion.getActiveTweenCount and Motion.getActiveTweenCount() or 0,
			animatingWindow = Motion.isAnimatingWindow and Motion.isAnimatingWindow() or false,
			gameId = STATE.gameId,
			tabId = win and win._activeTab and win._activeTab._name or nil,
			lastOpen = win and win._lastOpen or 0,
			lastClose = win and win._lastClose or 0,
			connections = (TooltipManager.getStats and TooltipManager.getStats().connections) or 0,
		}
	end

	return {
		Library = Library,
		STATE = STATE,
		Bootstrap = Bootstrap,
		Text = Text,
		Theme = Theme,
		Motion = Motion,
		Drag = Drag,
		TooltipManager = TooltipManager,
		Guards = Guards,
		Validate = Validate,
		Configs = Configs,
		Tabs = Tabs,
		Cache = Cache,
		GameRegistry = GameRegistry,
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