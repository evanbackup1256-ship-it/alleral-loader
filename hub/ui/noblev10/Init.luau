-- Alleral Noble V10 — framework bootstrap
return function(loadModule)
	local Theme = loadModule("Theme")
	local ZIndex = loadModule("ZIndex")
	local State = loadModule("State")
	local Spr = loadModule("Vendor/Spr")
	local Janitor = loadModule("Vendor/Janitor")
	local Signal = loadModule("Vendor/Signal")
	local Fusion = loadModule("Vendor/Fusion")(Spr)
	local Motion = loadModule("Motion")(Theme, Spr)
	local Layout = loadModule("Layout")(Theme, Motion)
	local Validation = loadModule("Systems/Validation")(Theme)

	-- Util compat shim for migrated V8 components
	Layout.safeSprTarget = Motion.safeSprTarget
	Layout.spring = Motion.spring
	local Util = Layout

	local deps = {
		Theme = Theme,
		ZIndex = ZIndex,
		Spr = Spr,
		Util = Util,
		Layout = Layout,
		Motion = Motion,
		Janitor = Janitor,
		Signal = Signal,
		Fusion = Fusion,
		Validation = Validation,
	}

	local DropdownManager = loadModule("Systems/DropdownManager")(deps)
	local InputManager = loadModule("Systems/InputManager")(deps)
	local AnimationManager = loadModule("Systems/AnimationManager")(deps)
	local ConfigManager = loadModule("Systems/ConfigManager")(deps)
	local NotificationManager = loadModule("Systems/NotificationManager")(deps)
	local SearchManager = loadModule("Systems/SearchManager")(deps)

	deps.DropdownManager = DropdownManager
	deps.InputManager = InputManager
	deps.AnimationManager = AnimationManager
	deps.ConfigManager = ConfigManager
	deps.NotificationManager = NotificationManager
	deps.SearchManager = SearchManager

	local Components = loadModule("Components/Controls")(deps)
	deps.Components = Components

	local WindowManager = loadModule("Systems/WindowManager")(deps)

	Validation.runBootSequence({
		Fusion = Fusion,
		Motion = Motion,
		DropdownManager = DropdownManager,
		NotificationManager = NotificationManager,
	})

	local function log(lvl, msg, core)
		State:log(lvl, msg, core)
	end

	local Library = {
		Version = Theme.VERSION,
		Engine = Theme.ENGINE,
		Theme = Theme,
		Spr = Spr,
		Fusion = Fusion,
		Components = Components,
		Window = WindowManager,
		Search = SearchManager,
		NotificationManager = NotificationManager,
		DropdownManager = DropdownManager,
		CommandPalette = SearchManager,
	}

	function Library:GetLayoutInfo()
		return {
			profile = "noble-v10",
			engine = Theme.ENGINE,
			version = Theme.VERSION,
			stack = "Fusion+Spr+Janitor+Signal",
		}
	end

	function Library:CreateWindow(settings)
		settings = Util.clone(type(settings) == "table" and settings or {})
		State.windowCount = State.windowCount + 1
		State.toggleKey = settings.Keybind or Theme.KEYBIND

		settings.Search = SearchManager
		settings.DropdownManager = DropdownManager
		settings.AnimationManager = AnimationManager

		local win = WindowManager.new(settings)
		State.activeWindow = win
		State.search = win._search
		State.dropdownManager = win._dropdownManager

		Validation.runLayoutChecks(win)

		local notifParent = win._screen
		if Validation.isScreenGui(notifParent) then
			State.notifManager = NotificationManager.new(notifParent)
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
				State.tabCount = State.tabCount + 1
			end
			return t, window
		end

		function window:Notify(p)
			p = type(p) == "table" and p or { Description = p }
			local title = Util.textOf(p.Title or p.Name or "Alleral")
			local body = Util.textOf(p.Description or p.Content or p.Text or "")
			local dur = tonumber(p.Duration or p.Lifetime or 4) or 4
			local ntype = p.Type or "info"
			if State.notifManager then
				State.notifManager:push(title, body, ntype, dur)
			end
		end

		function window:Unload()
			pcall(function() if win then win:Destroy() end end)
			if State.notifManager then pcall(function() State.notifManager:clear() end) end
			if win._search then pcall(function() win._search:Destroy() end) end
			if win._dropdownManager then pcall(function() win._dropdownManager:Destroy() end) end
			State.search = nil
			State.dropdownManager = nil
			State.uiDestroyed = true
		end

		window.Hide = function() if win then win:Hide() end end
		window.Show = function() if win then win:Show() end end
		window.Toggle = function() if win then win:Toggle() end end

		function window:Validate()
			return Validation.runRuntimeChecks(win, window._tabs)
		end

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
		if State.notifManager then
			return State.notifManager:push(title, body, nt, dur)
		end
		return nil
	end

	function Library:Notify(text, dur)
		if type(text) == "table" then return Library:Notification(text) end
		return Library:Notification({ Description = text, Duration = dur })
	end

	function Library:ClearNotifications()
		if State.notifManager then State.notifManager:clear() end
	end

	function Library:OpenSearch()
		if State.search then State.search:open() end
	end

	return {
		Library = Library,
		STATE = State,
		log = log,
		Util = Util,
		Layout = Layout,
		Motion = Motion,
		Spr = Spr,
		Theme = Theme,
		Validation = Validation,
	}
end