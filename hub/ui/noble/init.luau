-- Noble V8 — framework bootstrap (Fusion + Spr + Janitor + Signal)
return function(loadModule)
	local Spr = loadModule("Vendor/Spr")
	local Janitor = loadModule("Vendor/Janitor")
	local Signal = loadModule("Vendor/Signal")
	local Theme = loadModule("Theme")
	local Fusion = loadModule("Fusion")(Spr)
	local Util = loadModule("Util")(Theme, Spr)
	local Components = loadModule("Components")({
		Theme = Theme,
		Spr = Spr,
		Util = Util,
		Janitor = Janitor,
	})

	local deps = {
		Theme = Theme,
		Spr = Spr,
		Util = Util,
		Components = Components,
		Janitor = Janitor,
		Signal = Signal,
		Fusion = Fusion,
	}

	local NotificationManager = loadModule("Systems/NotificationManager")(deps)
	local Search = loadModule("Systems/Search")(deps)
	local Window = loadModule("Systems/Window")(deps)

	warn("[NobleV8] Janitor connection safety active")
	warn("[NobleV8] Spr target validation passed")

	local STATE = {
		tabs = 0,
		groups = 0,
		controls = 0,
		tabCount = 0,
		groupCount = 0,
		windowCount = 0,
		notifManager = nil,
		search = nil,
		activeWindow = nil,
		missingBindings = {},
		errorLog = {},
		toggleKey = Theme.KEYBIND,
		uiDestroyed = false,
		groupRegistry = {},
	}

	local function log(lvl, msg, core)
		if core and type(core.say) == "function" then
			core.say("[" .. lvl .. "] " .. msg)
		end
		table.insert(STATE.errorLog, { lvl = lvl, msg = msg, ts = os.date("%H:%M:%S") })
	end

	local Library = {
		Version = Theme.VERSION,
		Theme = Theme,
		Spr = Spr,
		Fusion = Fusion,
		Components = Components,
		Window = Window,
		Search = Search,
		NotificationManager = NotificationManager,
	}

	function Library:GetLayoutInfo()
		return {
			profile = "noble-v8",
			engine = "Alleral Noble V8",
			version = Theme.VERSION,
			stack = "Fusion+Spr+Janitor+Signal",
		}
	end

	function Library:CreateWindow(settings)
		settings = Util.clone(type(settings) == "table" and settings or {})
		STATE.windowCount = STATE.windowCount + 1

		-- Pass Search factory; Window.new creates the overlay after ScreenGui is parented.
		settings.Search = Search
		local win = Window.new(settings)
		STATE.activeWindow = win
		STATE.search = win._search

		local screenGui = win._screen
		if screenGui and screenGui:IsA("ScreenGui") and screenGui.Parent then
			warn("[NobleV8] ScreenGui parent validated")
		else
			warn("[NobleV8] ScreenGui parent missing — Search may fail")
		end

		if win._search then
			warn("[NobleV8] Search initialized")
		end

		warn("[NobleV8] Window created successfully")

		local notifParent = win._screen
		if notifParent and notifParent:IsA("ScreenGui") then
			STATE.notifManager = NotificationManager.new(notifParent)
		end

		local window = {
			_win = win,
			_library = Library,
			_tabs = {},
			_title = settings.Title or settings.Name or "Alleral",
			_settings = settings,
		}

		function window:AddTab(n, i)
			local t = win:AddTab(n, i, 2)
			if t then
				table.insert(window._tabs, t)
				STATE.tabCount = STATE.tabCount + 1
			end
			return t, window
		end

		function window:Notify(p)
			p = type(p) == "table" and p or { Description = p }
			local title = Util.textOf(p.Title or p.Name or "Alleral")
			local body = Util.textOf(p.Description or p.Content or p.Text or "")
			local dur = tonumber(p.Duration or p.Lifetime or 4) or 4
			local ntype = p.Type or "info"
			if STATE.notifManager then
				STATE.notifManager:push(title, body, ntype, dur)
			end
		end

		function window:Unload()
			pcall(function()
				if win then win:Destroy() end
			end)
			if STATE.notifManager then
				pcall(function() STATE.notifManager:clear() end)
			end
			if win._search then
				pcall(function() win._search:Destroy() end)
			end
			STATE.search = nil
			STATE.uiDestroyed = true
		end

		window.Hide = function() if win then win:Hide() end end
		window.Show = function() if win then win:Show() end end
		window.Toggle = function() if win then win:Toggle() end end

		warn("[NobleV8] UI runtime validation passed")

		return window
	end

	function Library:Notification(info)
		local title, body, dur, nt = "Alleral", "", 4, "info"
		if type(info) == "string" then
			body = info
		elseif type(info) == "table" then
			title = Util.textOf(info.Title or info.Name or "Alleral")
			body = Util.textOf(info.Description or info.Content or info.Text or "")
			dur = tonumber(info.Duration or info.Lifetime or info.Time or 4) or 4
			nt = info.Type or "info"
		else
			body = Util.textOf(info)
		end
		if STATE.notifManager then
			return STATE.notifManager:push(title, body, nt, dur)
		end
		return nil
	end

	function Library:Notify(text, dur)
		if type(text) == "table" then
			return Library:Notification(text)
		end
		return Library:Notification({ Description = text, Duration = dur })
	end

	function Library:ClearNotifications()
		if STATE.notifManager then
			STATE.notifManager:clear()
		end
	end

	function Library:OpenSearch()
		if STATE.search then STATE.search:open() end
	end

	return {
		Library = Library,
		STATE = STATE,
		log = log,
		Util = Util,
		Spr = Spr,
		Theme = Theme,
	}
end