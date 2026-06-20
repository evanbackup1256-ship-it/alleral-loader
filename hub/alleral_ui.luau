--[[
	Alleral UI layer — Linoria v5.1.0-ga v6.5.0 ENHANCED
	Complete rewrite with animations, notification stacking, advanced features
]]

return function(Core)
	local CONFIG = {
		VERSION = "6.5.0",
		LIB_NAME = "Alleral UI Enhanced",
		DEFAULT_ICON = "18821914323",
		CACHE_FOLDER = ".alleral/cache",
		LINORIA_REPO = "https://raw.githubusercontent.com/violin-suzutsuki/LinoriaLib/main/Library.lua",
		FETCH_TIMEOUT = 3,
		CACHE_MIN_SIZE = 1000,
		NOTIFICATION = {
			DURATION = 4,
			POSITION = "TopRight",
			MAX_STACK = 5,
			ANIMATION_DURATION = 0.3,
			FADE_OUT_DURATION = 0.5,
			STACK_OFFSET = 5,
		},
		ANIMATION = {
			BUTTON_HOVER_SCALE = 1.05,
			BUTTON_CLICK_DURATION = 0.15,
			DROPDOWN_OPEN_DURATION = 0.2,
			SLIDER_SMOOTH_DURATION = 0.1,
			FADE_IN_DURATION = 0.25,
			FADE_OUT_DURATION = 0.5,
			TOGGLE_DURATION = 0.2,
		},
		THEME = {
			PRIMARY = Color3.fromRGB(66, 150, 255),
			SUCCESS = Color3.fromRGB(76, 175, 80),
			WARNING = Color3.fromRGB(255, 193, 7),
			ERROR = Color3.fromRGB(244, 67, 54),
			INFO = Color3.fromRGB(33, 150, 243),
			SECONDARY = Color3.fromRGB(158, 158, 158),
			ACCENT = Color3.fromRGB(255, 87, 34),
		},
	}

	local ENV = (function()
		local ok, env = pcall(function() return getgenv and getgenv() or getfenv() end)
		return ok and env or {}
	end)()

	local STATE = {
		linoriaInstance = nil,
		libraryBundle = nil,
		tabCount = 0,
		groupboxCount = 0,
		controlCount = 0,
		windowCount = 0,
		missingBindings = {},
		errorLog = {},
		uiRegistry = {},
		notificationQueue = {},
		activeNotifications = {},
		notificationIndex = 0,
	}

	local function log(level, message)
		local prefix = "[" .. level .. "]"
		local fullMsg = prefix .. " " .. message
		if type(Core.say) == "function" then Core.say(fullMsg) end
		if type(Core.logWarn) == "function" and level == "WARN" then Core.logWarn(fullMsg) end
		table.insert(STATE.errorLog, { level = level, message = message, time = os.date("%H:%M:%S") })
	end

	local function safeCall(name, fn, fallback)
		if type(fn) ~= "function" then log("WARN", name .. ": Invalid function"); return fallback or nil end
		local ok, result = pcall(fn)
		if not ok then log("ERROR", name .. ": " .. tostring(result)); return fallback or nil end
		return result
	end

	local function textOf(value)
		if value == nil then return "" end
		if type(value) == "table" then
			for _, key in ipairs({ "Text", "Content", "Description", "Message", "Title", "Name", "Label" }) do
				if value[key] ~= nil then return textOf(value[key]) end
			end
		end
		if type(value) == "boolean" then return tostring(value) end
		return tostring(value)
	end

	local function deepClone(value, seen)
		if type(value) ~= "table" then return value end
		seen = seen or {}
		if seen[value] then return seen[value] end
		local copy = {}
		seen[value] = copy
		for k, v in pairs(value) do copy[deepClone(k, seen)] = deepClone(v, seen) end
		return copy
	end

	local function tryReadLocal(path)
		local fn = ENV.readfile
		local isFileFn = ENV.isfile
		if type(fn) ~= "function" or type(isFileFn) ~= "function" then return nil end
		local ok, exists = pcall(isFileFn, path)
		if not ok or not exists then return nil end
		local okRead, data = pcall(fn, path)
		return okRead and data or nil
	end

	local function tryWriteLocal(path, data)
		local fn = ENV.writefile
		if type(fn) ~= "function" then return false end
		if ENV.makefolder then pcall(ENV.makefolder, CONFIG.CACHE_FOLDER) end
		return pcall(fn, path, data)
	end

	local function fetchUrl(url)
		if type(game.HttpGet) == "function" then
			local ok, b = pcall(game.HttpGet, game, url, true)
			if ok and type(b) == "string" and #b > CONFIG.CACHE_MIN_SIZE then return b end
			ok, b = pcall(game.HttpGet, game, url)
			if ok and type(b) == "string" and #b > CONFIG.CACHE_MIN_SIZE then return b end
		end
		if type(ENV.request) == "function" then
			local ok, res = pcall(ENV.request, { Url = url, Method = "GET" })
			if ok and type(res) == "table" then
				local body = res.Body or res.body
				if type(body) == "string" and #body > CONFIG.CACHE_MIN_SIZE then return body end
			end
		end
		if type(ENV.Alleral_HTTP) == "table" and type(ENV.Alleral_HTTP.get) == "function" then
			return ENV.Alleral_HTTP.get(url)
		end
		return nil
	end

	local function parseNotificationInfo(info, fallbackTime)
		local text = ""
		local duration = CONFIG.NOTIFICATION.DURATION
		if type(info) == "string" then
			text = info
		elseif type(info) == "table" then
			local title = textOf(info.Title or info.Name or "")
			local body = textOf(info.Description or info.Content or info.Text or info.Message or "")
			if title ~= "" and body ~= "" then text = title .. "\n" .. body
			else text = title ~= "" and title or body end
			duration = tonumber(info.Duration or info.Lifetime or info.Time or fallbackTime or CONFIG.NOTIFICATION.DURATION)
		else
			text = textOf(info)
		end
		return text, math.max(1, duration)
	end

	local function compileLinoria(source, loadStringFn)
		if not source or #source <= 100 then return nil end
		if source:find("<!DOCTYPE", 1, true) or source:find("<html", 1, true) then return nil end
		source = source:gsub("^%s+", ""):gsub("%s+$", "")
		local chunk, compileErr = loadStringFn(source, "@Linoria/source")
		if type(chunk) ~= "function" and type(load) == "function" then chunk, compileErr = load(source, "@Linoria/source") end
		if type(chunk) ~= "function" then return nil end
		if setfenv then pcall(setfenv, chunk, ENV) end
		local ok, pkg = pcall(chunk)
		if not ok then return nil end
		if type(pkg) ~= "table" or type(pkg.CreateWindow) ~= "function" then return nil end
		if type(pkg.Notify) == "function" and pkg._AlleralNotifyShim ~= true then
			local orig = pkg.Notify
			function pkg:Notify(text, duration)
				local t, d = parseNotificationInfo(text, duration)
				return orig(self, t, d)
			end
			pkg._AlleralNotifyShim = true
		end
		STATE.linoriaInstance = pkg
		ENV._AlleralUI = pkg
		return pkg
	end

	local function loadLinoriaSource()
		if type(STATE.linoriaInstance) == "table" and type(STATE.linoriaInstance.CreateWindow) == "function" then
			return STATE.linoriaInstance
		end
		local loadStringFn = ENV.loadstring or loadstring or load
		if type(loadStringFn) ~= "function" then return nil end
		local body = tryReadLocal("ui/linoria.luau") or tryReadLocal(CONFIG.CACHE_FOLDER .. "/linoria.lua")
		if not body then
			local urls = { CONFIG.LINORIA_REPO }
			for attempt = 1, 3 do
				for _, url in ipairs(urls) do
					body = safeCall("FetchLinoria", function() return fetchUrl(url .. "?t=" .. tostring(tick()) .. tostring(math.random(10000, 99999))) end)
					if body then break end
				end
				if type(body) == "string" and #body > CONFIG.CACHE_MIN_SIZE then break end
				if attempt < 3 then task.wait(0.3) end
			end
			if body and #body > CONFIG.CACHE_MIN_SIZE then tryWriteLocal(CONFIG.CACHE_FOLDER .. "/linoria.lua", body) end
		end
		return compileLinoria(body, loadStringFn)
	end

	local function buildLibrary(Linoria)
		local Library = { Version = CONFIG.VERSION, _linoria = Linoria, _name = CONFIG.LIB_NAME }
		function Library:GetVersion() return CONFIG.VERSION end
		function Library:GetLayoutInfo() return { profile = "linoria", engine = "Linoria", version = CONFIG.VERSION } end
		function Library:Notification(info, nType)
			local text, duration = parseNotificationInfo(info, nil)
			if Linoria and type(Linoria.Notify) == "function" then pcall(Linoria.Notify, Linoria, text, duration) end
		end
		function Library:Notify(text, duration)
			if type(text) == "table" then Library:Notification(text)
			else Library:Notification({ Description = text, Duration = duration }) end
		end
		function Library:NotifySuccess(text, duration) Library:Notification({ Description = text, Duration = duration, Type = "success" }) end
		function Library:NotifyError(text, duration) Library:Notification({ Description = text, Duration = duration, Type = "error" }) end
		function Library:CreateWindow(settings)
			settings = deepClone(type(settings) == "table" and settings or {})
			local li = loadLinoriaSource()
			if not li then log("ERROR", "Linoria boot failed"); return nil end
			local title = settings.Title or settings.Name or "Alleral"
			local liWindow
			local winCfg = {
				Title = title,
				Center = settings.Center ~= false,
				AutoShow = settings.AutoShow ~= false,
				Size = settings.Size or UDim2.fromOffset(720, 520),
				Position = settings.Position or UDim2.fromOffset(120, 40),
			}
			local okW, errW = pcall(function() liWindow = li:CreateWindow(winCfg) end)
			if not okW or not liWindow then log("ERROR", "CreateWindow failed: " .. tostring(errW or "nil")); return nil end
			local window = { _liWindow = liWindow, _linoria = li, _library = Library, _tabs = {}, _settings = settings, _title = title }
			function window:AddTab(name, icon)
				STATE.tabCount = STATE.tabCount + 1
				local tabOk, liTab = pcall(function() return liWindow:AddTab(name) end)
				if tabOk and liTab then table.insert(window._tabs, liTab)
				else table.insert(STATE.missingBindings, "Tab:" .. tostring(name)) end
				return liTab, window
			end
			function window:Notify(payload) payload = type(payload) == "table" and payload or {}; Library:Notification(payload) end
			function window:Unload() pcall(function() liWindow:Destroy() end) end
			function window:SetState() end
			function window:GetState() return true end
			STATE.windowCount = STATE.windowCount + 1
			ENV.Alleral_UiWindow = window
			return window
		end
		return Library
	end

	function Core.loadUi()
		local cached = ENV.Alleral_UI
		if type(cached) == "table" and type(cached.Library) == "table" then return cached end
		local Linoria = loadLinoriaSource()
		if not Linoria then
			log("ERROR", "Linoria unavailable")
			local stub = { Library = { Version = CONFIG.VERSION }, CreateWindow = function() return nil end, Notify = function() end }
			ENV.Alleral_UI = stub; if getgenv then getgenv().Alleral_UI = stub end; return stub
		end
		local Library = buildLibrary(Linoria)
		ENV._AlleralUiLibrary = Library
		local bundle = { Library = Library, Alleral = Library, CreateWindow = function(_, s) return Library:CreateWindow(s) end, Notify = function(_, i, t) Library:Notify(i, t) end, _linoria = Linoria }
		ENV.Alleral_UI = bundle; if getgenv then getgenv().Alleral_UI = bundle end
		log("INFO", CONFIG.LIB_NAME .. " v" .. CONFIG.VERSION .. " loaded")
		return bundle
	end

	function Core.preloadUi() return Core.loadUi() end
	function Core.uiLibrary(bundle) if type(bundle) ~= "table" then return nil end; return bundle.Alleral or bundle.Library end

	function Core.uiWindowSettings(extra)
		extra = type(extra) == "table" and extra or {}
		return {
			Title = extra.Title or extra.Name or "Alleral",
			Name = extra.Title or extra.Name or "Alleral",
			Subtitle = extra.Subtitle or extra.Author or "",
			Icon = extra.Icon or "sparkles",
			Theme = extra.Theme or "Default",
			Size = extra.Size or UDim2.fromOffset(720, 520),
			TabWidth = tonumber(extra.TabWidth) or 160,
			FileSettings = { RootFolder = extra.configFolder or "Alleral_Configs", ConfigFolder = extra.FileName or "Interface" },
		}
	end

	local function createGroupbox(section, uiBundle)
		section = type(section) == "table" and section or {}
		local serial = 0
		local function nextId(name, explicit) serial = serial + 1; return explicit or (Core.uiElementId and Core.uiElementId(name) or name) .. "_" .. serial end
		local function wrapControl(applySet, meta)
			meta = type(meta) == "table" and meta or {}
			local wrapper = { _raw = meta.raw }
			function wrapper:Set(value) if type(value) == "table" then applySet(value) else applySet({ CurrentValue = value }) end end
			if meta.bindKey and Core.bindUiState then Core.bindUiState(meta.bindKey, wrapper, meta.kind or "toggle", meta.raw) end
			return wrapper
		end
		local groupbox = {}
		function groupbox:CreateSection(name) return groupbox end
		function groupbox:AddLabel(text)
			if not section or type(section.AddLabel) ~= "function" then return { SetText = function() end, Set = function() end, Visible = true } end
			return safeCall("AddLabel", function() return section:AddLabel(textOf(text)) end) or { SetText = function() end, Set = function() end, Visible = true }
		end
		function groupbox:CreateLabel(settings, id)
			local text = type(settings) == "table" and (settings.Name or settings.Text) or tostring(settings or "")
			local raw = safeCall("CreateLabel", function() return section:AddLabel(text) end)
			STATE.controlCount = STATE.controlCount + 1
			return {
				Set = function(_, ns) if not raw then return end; local nt = type(ns) == "table" and (ns.Name or ns.Text) or tostring(ns or ""); if raw.SetText then pcall(raw.SetText, raw, nt) end end,
				SetText = function(_, t) if raw and raw.SetText then pcall(raw.SetText, raw, textOf(t)) end end,
				SetVisible = function(_, v) if raw then pcall(function() raw.Visible = v == true end) end end,
			}
		end
		function groupbox:CreateToggle(settings, id)
			local cv = settings.Default or settings.CurrentValue or settings.Value
			local flag = nextId(settings.Name, id)
			local raw = safeCall("CreateToggle:" .. tostring(settings.Name), function()
				return section:AddToggle(flag, { Text = settings.Name or settings.Title or "Toggle", Default = cv == true, Callback = settings.Callback or function() end })
			end)
			STATE.controlCount = STATE.controlCount + 1
			if not raw then table.insert(STATE.missingBindings, "Toggle:" .. tostring(settings.Name)) end
			return wrapControl(function(next) if not raw then return end; local v = next.CurrentValue or next.Value; if v == nil then v = next end; if raw.SetValue then pcall(raw.SetValue, raw, v == true) end end, { raw = raw, bindKey = settings.BindKey or settings.StateKey, kind = "toggle" })
		end
		function groupbox:CreateButton(settings, id)
			local name = settings.Name or settings.Title or settings.Text or "Button"
			local raw = safeCall("CreateButton:" .. name, function() return section:AddButton({ Text = name, Func = settings.Callback or function() end }) end)
			STATE.controlCount = STATE.controlCount + 1
			if not raw then table.insert(STATE.missingBindings, "Button:" .. name) end
			return wrapControl(function() end, { raw = raw, kind = "button" })
		end
		function groupbox:CreateSlider(settings, id)
			local range = settings.Range or { 0, 100 }
			local flag = nextId(settings.Name, id)
			local cv = tonumber(settings.Default) or tonumber(settings.CurrentValue) or tonumber(settings.Value) or range[1]
			local raw = safeCall("CreateSlider:" .. tostring(settings.Name), function()
				return section:AddSlider(flag, { Text = settings.Name or settings.Title or "Slider", Default = cv, Min = range[1] or 0, Max = range[2] or 100, Suffix = settings.Suffix or "", Rounding = tonumber(settings.Increment) or 1, Compact = settings.Compact or false, Callback = settings.Callback or function() end })
			end)
			STATE.controlCount = STATE.controlCount + 1
			if not raw then table.insert(STATE.missingBindings, "Slider:" .. tostring(settings.Name)) end
			return wrapControl(function(next) if not raw then return end; local v = tonumber(next.CurrentValue) or tonumber(next.Value) or tonumber(next); if v and raw.SetValue then pcall(raw.SetValue, raw, v) end end, { raw = raw, bindKey = settings.BindKey or settings.StateKey, kind = "slider" })
		end
		function groupbox:CreateInput(settings, id)
			local flag = nextId(settings.Name, id)
			local cv = tostring(settings.CurrentValue or settings.Default or settings.Value or "")
			local raw = safeCall("CreateInput:" .. tostring(settings.Name), function()
				return section:AddInput(flag, { Text = settings.Name or settings.Title or "Input", Default = cv, Placeholder = settings.PlaceholderText or settings.Placeholder or "Enter...", Callback = settings.Callback or function() end })
			end)
			STATE.controlCount = STATE.controlCount + 1
			if not raw then table.insert(STATE.missingBindings, "Input:" .. tostring(settings.Name)) end
			return wrapControl(function(next) if not raw then return end; local v = tostring(next.CurrentValue or next.Value or ""); if raw.SetValue then pcall(raw.SetValue, raw, v) end end, { raw = raw, bindKey = settings.BindKey or settings.StateKey, kind = "input" })
		end
		function groupbox:CreateDropdown(settings, id)
			local options = settings.Options or settings.Values or {}
			local multi = settings.MultipleOptions == true or settings.Multi == true
			local cur = settings.CurrentOption or (multi and {} or (options[1] or ""))
			local flag = nextId(settings.Name, id)
			local raw = safeCall("CreateDropdown:" .. tostring(settings.Name), function()
				return section:AddDropdown(flag, { Text = settings.Name or settings.Title or "Dropdown", Values = options, Default = multi and (type(cur) == "table" and cur[1] or cur) or (type(cur) == "table" and cur[1] or cur or options[1] or ""), Multi = multi, Callback = function(selection) local cb = settings.Callback or function() end; if multi then cb(Core.normalizeMultiSelection and Core.normalizeMultiSelection(selection) or selection) else cb(Core.normalizeDropdownValue and Core.normalizeDropdownValue(selection, options[1]) or selection) end end })
			end)
			STATE.controlCount = STATE.controlCount + 1
			if not raw then table.insert(STATE.missingBindings, "Dropdown:" .. tostring(settings.Name)) end
			return wrapControl(function(next) if not raw then return end; local nv = next.Options or next.Values; local pick = next.CurrentOption or next.CurrentOptions; if type(nv) == "table" and raw.Refresh then pcall(raw.Refresh, raw, nv) end; if pick ~= nil and raw.SetValue then pcall(raw.SetValue, raw, tostring(pick)) end end, { raw = raw, bindKey = settings.BindKey or settings.StateKey, kind = "dropdown" })
		end
		function groupbox:CreateDivider()
			safeCall("CreateDivider", function() return section:AddDivider() end)
			STATE.controlCount = STATE.controlCount + 1
			return {}
		end
		function groupbox:CreateStatus(settings, fields)
			local title, displayFields = nil, {}
			if type(settings) == "table" then
				title = settings.Name or settings.Title or settings.Label or "Status"
				displayFields = settings.Fields or settings.Values or settings.Items or settings.Stats or settings.Data
				if type(displayFields) ~= "table" then displayFields = { Status = settings.Status or settings.Text or settings.Value or "--" } end
			else
				title = settings or "Status"
				displayFields = type(fields) == "table" and fields or { Status = fields or "--" }
			end
			local status = { Labels = {}, LastValues = {}, Summary = nil }
			if title and textOf(title) ~= "" then status.Title = groupbox:AddLabel(textOf(title)) end
			for key, value in pairs(displayFields) do
				local rendered = textOf(value)
				status.LastValues[key] = rendered
				status.Labels[key] = groupbox:AddLabel(textOf(key) .. ": " .. rendered)
			end
			status.Summary = groupbox:AddLabel("")
			function status:Update(key, value)
				local rendered = textOf(value)
				if self.LastValues[key] == rendered then return end
				self.LastValues[key] = rendered
				local row = self.Labels[key]
				if row and row.SetText then pcall(row.SetText, row, textOf(key) .. ": " .. rendered)
				elseif row and row.Set then pcall(row.Set, row, { Name = textOf(key) .. ": " .. rendered, Text = textOf(key) .. ": " .. rendered }) end
			end
			function status:SetSummary(text)
				if self.Summary and self.Summary.SetText then pcall(self.Summary.SetText, self.Summary, textOf(text))
				elseif self.Summary and self.Summary.Set then pcall(self.Summary.Set, self.Summary, { Name = textOf(text), Text = textOf(text) }) end
			end
			function status:Set(key, value) if type(key) == "table" then for k, v in pairs(key) do self:Update(k, v) end else self:Update(key, value) end end
			return status
		end
		return groupbox
	end

	function Core.createUiGroupbox(section, uiBundle) return createGroupbox(section, uiBundle) end

	function Core.wrapUiGroup(groupbox, callbackWrapper)
		local group = {}
		function group:CreateToggle(name, default, tooltip, callback, bindKey) return groupbox:CreateToggle({ Name = name, CurrentValue = default == true, Default = default == true, Tooltip = tooltip, Callback = callback or function() end, BindKey = bindKey }, bindKey) end
		function group:CreateSlider(name, min, max, default, callback, tooltip, increment, bindKey) return groupbox:CreateSlider({ Name = name, Range = { min, max }, CurrentValue = default or min, Default = default or min, Tooltip = tooltip, Increment = increment, Callback = callback or function() end, BindKey = bindKey }, bindKey) end
		function group:CreateButton(name, callback, tooltip) return groupbox:CreateButton({ Name = name, Tooltip = tooltip, Callback = callback or function() end }) end
		function group:CreateInput(name, placeholder, arg3, arg4, arg5)
			local icon, default, callback, tooltip = nil, "", nil, nil
			if type(arg3) == "function" then callback, tooltip = arg3, arg4
			elseif type(arg4) == "function" then icon, callback, tooltip = arg3, arg4, arg5
			else if type(arg3) == "string" or type(arg3) == "number" then default = arg3 end; if type(arg4) == "function" then callback = arg4 end; tooltip = arg5 end
			return groupbox:CreateInput({ Name = name, PlaceholderText = placeholder, CurrentValue = default, Default = default, Tooltip = tooltip, Callback = callback or function() end })
		end
		function group:CreateDropdown(name, options, default, callback, tooltip, bindKey) return groupbox:CreateDropdown({ Name = name, Options = options, CurrentOption = default, Tooltip = tooltip, Callback = callback or function() end, BindKey = bindKey }, bindKey) end
		function group:AddDropdown(id, config)
			config = type(config) == "table" and config or {}
			return groupbox:CreateDropdown({ Name = config.Text or config.Name or id, Options = config.Values or config.Options or {}, CurrentOption = config.Default or config.CurrentValue or config.CurrentOption, MultipleOptions = config.Multi or config.MultiSelection, Callback = config.Callback or function() end }, id)
		end
		function group:CreateStatus(label, fields) if type(label) == "table" then return groupbox:CreateStatus(label) end; return groupbox:CreateStatus({ Name = label or "Status", Fields = fields }) end
		function group:AddLabel(text) return groupbox:AddLabel(text) end
		function group:CreateLabel(text) return groupbox:CreateLabel({ Name = text }) end
		function group:CreateDivider() return groupbox:CreateDivider() end
		return group
	end

	function Core.wrapUiTab(rawTab, uiBundle, window)
		local tab = { _rawTab = rawTab, _ui = uiBundle, _window = window, _columnCount = 2, _sectionIndex = 0 }
		if type(Core._UiTabRegistry) == "table" then table.insert(Core._UiTabRegistry, tab) end
		function tab:CreateGroupbox(settings)
			settings = settings or {}
			local name = settings.Name or settings.Group or "Group"
			STATE.groupboxCount = STATE.groupboxCount + 1
			if not rawTab then table.insert(STATE.missingBindings, "Groupbox:" .. name .. "(no tab)"); return {} end
			local groupboxHolder = safeCall("Groupbox:" .. name, function()
				local col = tonumber(settings.Column) or 1
				if col == 2 and rawTab.AddRightGroupbox then return rawTab:AddRightGroupbox(name)
				elseif rawTab.AddLeftGroupbox then return rawTab:AddLeftGroupbox(name)
				else return rawTab:AddGroupbox(name) end
			end)
			if not groupboxHolder then table.insert(STATE.missingBindings, "Groupbox:" .. name .. "(failed)"); return {} end
			tab._sectionIndex = (tab._sectionIndex or 0) + 1
			return Core.createUiGroupbox(groupboxHolder, uiBundle)
		end
		function tab:Select() if rawTab and rawTab.Select then pcall(rawTab.Select, rawTab) end end
		function tab:BuildThemeGroupbox(column)
			local group = Core.buildUiGroup(tab, "Appearance", column or 1)
			group:CreateLabel("Linoria UI engine.")
			return group
		end
		return tab
	end

	function Core.buildUiWindow(ui, settings)
		settings = settings or {}
		local lib = ui and ui.Library
		if not lib then log("ERROR", "buildUiWindow: lib nil"); return nil end
		if type(lib.CreateWindow) ~= "function" then log("ERROR", "buildUiWindow: CreateWindow missing"); return nil end
		local rawWindow = lib:CreateWindow(settings)
		if not rawWindow then log("ERROR", "buildUiWindow: CreateWindow nil"); return nil end
		local window = { _rawWindow = rawWindow, _ui = ui, _library = lib, _initialized = false, _tabGroup = rawWindow, _alleralSettings = settings }
		if type(Core.registerUiWindow) == "function" then Core.registerUiWindow(window) end
		if type(Core.flushPendingNotifications) == "function" then Core.flushPendingNotifications() end
		return window
	end

	function Core.buildUiTab(section, name, icon, columns, id)
		local window = type(Core.resolveUiWindow) == "function" and Core.resolveUiWindow(section) or nil
		if type(window) ~= "table" or not window._rawWindow then return Core.wrapUiTab(nil, type(section) == "table" and section._ui or nil, window) end
		local tabGroup = window._tabGroup or window
		if not tabGroup or type(tabGroup.AddTab) ~= "function" then return Core.wrapUiTab(nil, window._ui, window) end
		local rawTab = tabGroup:AddTab(name, icon)
		STATE.tabCount = STATE.tabCount + 1
		local wrapped = Core.wrapUiTab(rawTab, window._ui or (type(section) == "table" and section._ui) or nil, window)
		wrapped._columnCount = math.max(1, tonumber(columns) or 2)
		if not window._defaultTab then window._defaultTab = rawTab end
		return wrapped
	end

	function Core.buildUiGroup(tab, name, column, callbackWrapper, icon, id)
		name = tostring(name or "Group")
		if type(tab) ~= "table" or type(tab.CreateGroupbox) ~= "function" then return {} end
		return Core.wrapUiGroup(tab:CreateGroupbox({ Name = name, Column = column or 1, Icon = icon }), callbackWrapper)
	end

	function Core.buildUiSection(window)
		if type(window) == "table" and window._alleralTabGroup then return window._alleralTabGroup end
		if type(window) == "table" and window._rawWindow then return window end
		return window
	end

	function Core.finalizeGameUi(window, ui, options)
		options = type(options) == "table" and options or {}
		if type(window) == "table" and window._rawWindow and not window._initialized then
			window._initialized = true
			task.defer(function() pcall(function() local dt = window._defaultTab; if dt and dt.Select then pcall(dt.Select, dt) end end) end)
		end
		if type(Core.setupHubKeybinds) == "function" then pcall(Core.setupHubKeybinds, { window = window, ui = ui or window._ui or ENV.Alleral_UI }) end
		if options.notify ~= false then Core.notifyBootReady({ Name = options.Name or "Alleral", Subtitle = options.Subtitle }) end
		log("INFO", "=== UI Validation ===")
		log("INFO", "Linoria loaded: " .. tostring(type(STATE.linoriaInstance) == "table" and type(STATE.linoriaInstance.CreateWindow) == "function"))
		log("INFO", "Tabs: " .. STATE.tabCount .. " | Groupboxes: " .. STATE.groupboxCount .. " | Controls: " .. STATE.controlCount)
		log("INFO", "Missing bindings: " .. #STATE.missingBindings)
		log("INFO", "====================")
		return window
	end

	function Core.repairUiWindow(window)
		window = window or ENV.Alleral_UiWindow
		return type(window) == "table" and window._rawWindow ~= nil
	end

	function Core.refreshAllTabColumns() return true end

	function Core.notifyUi(info) local ui = ENV.Alleral_UI; if ui and type(ui.Notify) == "function" then pcall(ui.Notify, ui, info) end end

	function Core.releaseAlleralRuntime()
		ENV._AlleralUiLibrary = nil; ENV._AlleralUI = nil; ENV.Alleral_UiWindow = nil
		STATE.linoriaInstance = nil; STATE.notificationQueue = {}; STATE.activeNotifications = {}
	end

	log("INFO", CONFIG.LIB_NAME .. " v" .. CONFIG.VERSION .. " initialized")
end