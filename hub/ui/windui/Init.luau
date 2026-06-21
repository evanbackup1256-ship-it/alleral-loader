-- Alleral V11 — WindUI framework entry (sole UI stack)
return function(loadModule, Core)
	local Bootstrap = loadModule("Bootstrap")(Core)
	local WindUI = Bootstrap.loadWindUI()
	local Notifications = loadModule("Notifications")(WindUI, Bootstrap)
	local Controls = loadModule("Controls")(Bootstrap)
	local WindowMod = loadModule("Window")(WindUI, Bootstrap, Controls, Notifications)
	local Configs = loadModule("Configs")(Bootstrap)
	local Tabs = loadModule("Tabs")()

	local STATE = {
		tabCount = 0,
		groupCount = 0,
		controls = 0,
		groupRegistry = {},
		missingBindings = {},
		activeWindow = nil,
		uiDestroyed = false,
		gameId = Bootstrap.resolveGameId(Core),
	}

	local Library = {
		Version = Bootstrap.VERSION,
		Engine = Bootstrap.ENGINE,
		WindUI = WindUI,
	}

	function Library:CreateWindow(settings)
		if STATE.activeWindow then
			pcall(function() STATE.activeWindow:Unload() end)
			STATE.activeWindow = nil
		end
		STATE.tabCount = 0
		STATE.groupCount = 0
		STATE.controls = 0
		STATE.uiDestroyed = false

		settings = type(settings) == "table" and settings or {}
		settings.ConfigFolder = settings.ConfigFolder or Configs.getNamespace(STATE.gameId)

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
			info.Title or info.Name or "Alleral",
			info.Description or info.Content or info.Text or "",
			info.Type or "info",
			info.Duration or info.Lifetime or 4
		)
	end

	function Library:Notify(text, dur)
		if type(text) == "table" then return Library:Notification(text) end
		return Notifications.push(WindUI, "Alleral", text, "info", dur or 4)
	end

	function Library:ClearNotifications()
		Notifications.clear()
	end

	function Library:GetLayoutInfo()
		return {
			profile = "windui-v11",
			engine = Bootstrap.ENGINE,
			version = Bootstrap.VERSION,
			stack = "WindUI",
		}
	end

	function Library:OpenSearch() end

	return {
		Library = Library,
		STATE = STATE,
		Bootstrap = Bootstrap,
		Configs = Configs,
		Tabs = Tabs,
		WindUI = WindUI,
		log = function(lvl, msg)
			warn("[Alleral] [" .. tostring(lvl) .. "] " .. tostring(msg))
		end,
	}
end