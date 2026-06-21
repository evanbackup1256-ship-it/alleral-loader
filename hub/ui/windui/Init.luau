-- Alleral V11 — WindUI framework entry (sole UI stack)
return function(loadModule, Core)
	local Text = loadModule("Text")()
	local Bootstrap = loadModule("Bootstrap")(Core, Text)
	local WindUI = Bootstrap.loadWindUI()
	local Theme = loadModule("Theme")(WindUI, Bootstrap)
	local Motion = loadModule("Motion")()
	local Notifications = loadModule("Notifications")(WindUI, Bootstrap)
	local Controls = loadModule("Controls")(Bootstrap, Motion, Text)
	local WindowMod = loadModule("Window")(WindUI, Bootstrap, Controls, Notifications, Theme, Motion)
	local Configs = loadModule("Configs")(Bootstrap)
	local Tabs = loadModule("Tabs")()

	pcall(function() Theme.register() end)

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
		Theme = Theme.NAME,
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
			Bootstrap.sanitize(info.Title or info.Name or "Alleral", 80),
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

	function Library:SetTheme(name)
		pcall(function()
			if WindUI.SetTheme then WindUI:SetTheme(Bootstrap.sanitize(name, 32)) end
		end)
	end

	function Library:GetLayoutInfo()
		return {
			profile = "windui-v11-premium",
			engine = Bootstrap.ENGINE,
			version = Bootstrap.VERSION,
			stack = "WindUI",
			theme = Theme.NAME,
		}
	end

	function Library:OpenSearch()
		pcall(function()
			if STATE.activeWindow and STATE.activeWindow._wind and STATE.activeWindow._wind.OpenSearch then
				STATE.activeWindow._wind:OpenSearch()
			end
		end)
	end

	return {
		Library = Library,
		STATE = STATE,
		Bootstrap = Bootstrap,
		Text = Text,
		Theme = Theme,
		Motion = Motion,
		Configs = Configs,
		Tabs = Tabs,
		WindUI = WindUI,
		sanitize = Bootstrap.sanitize,
		log = function(lvl, msg)
			warn("[Alleral] [" .. tostring(lvl) .. "] " .. tostring(msg))
		end,
	}
end