-- Alleral UI layer — v11.1.0 WindUI (sole framework)
--[[
	WindUI bootstrap — https://github.com/Footagesus/WindUI
	No Noble, Fusion, Spr, Linoria, or legacy renderers.

	Module roots:
	  hub/ui/windui/{path}.luau
	  kick/hub/ui/windui/{path}.luau
	  .alleral/cache/hub/ui/windui/{path}.luau
	  GITHUB_RAW remote fallback via Core.httpGet
]]
return function(Core)
	Core.ALLERAL_UI_VERSION = "11.1.0"
	Core.UI_VERSION = "11.1.0"
	Core.UI_LIBRARY = "WindUI"

	local GITHUB_RAW = "https://raw.githubusercontent.com/evanbackup1256-ship-it/-kick-loader/main"

	local ENV = (function()
		local ok, e = pcall(function()
			if getgenv then return getgenv() end
			return getfenv and getfenv() or {}
		end)
		return ok and e or {}
	end)()

	local getGenv = getgenv or function() return ENV end
	local WINDUI_CACHE_VERSION = "11.1.0"
	getGenv()._NobleV8Modules = nil
	getGenv()._NobleV8CacheVersion = nil
	getGenv()._NobleV10Modules = nil
	getGenv()._NobleV10CacheVersion = nil
	if getGenv()._WindUIModulesCacheVersion ~= WINDUI_CACHE_VERSION then
		getGenv()._WindUIModules = nil
		getGenv()._WindUIModulesCacheVersion = WINDUI_CACHE_VERSION
	end
	local moduleCache = getGenv()._WindUIModules
	if type(moduleCache) ~= "table" then
		moduleCache = {}
		getGenv()._WindUIModules = moduleCache
	end

	Core.loadLinoriaSource = Core.loadLinoriaSource or function()
		return nil, "Linoria removed — WindUI is the sole UI framework"
	end

	-- ========== WINDUI MODULE LOADER ==========
	local function resolveReadfile()
		if Core and type(Core.execFunction) == "function" then
			local rf = Core.execFunction("readfile")
			if type(rf) == "function" then return rf end
		end
		if type(ENV.readfile) == "function" then return ENV.readfile end
		return nil
	end

	local function resolveIsfile()
		if Core and type(Core.execFunction) == "function" then
			local iff = Core.execFunction("isfile")
			if type(iff) == "function" then return iff end
		end
		if type(ENV.isfile) == "function" then return ENV.isfile end
		return nil
	end

	local function modulePaths(path)
		local rel = "hub/ui/windui/" .. path .. ".luau"
		return {
			rel,
			"kick/" .. rel,
			".alleral/cache/" .. rel,
		}
	end

	local function readModuleSource(path)
		path = tostring(path or ""):gsub("^%s+", ""):gsub("%s+$", "")
		if path == "" then return nil, "empty module path" end

		local readFn = resolveReadfile()
		local isFn = resolveIsfile()
		if type(readFn) == "function" and type(isFn) == "function" then
			for _, localPath in ipairs(modulePaths(path)) do
				local existsOk, exists = pcall(isFn, localPath)
				if existsOk and exists then
					local readOk, src = pcall(readFn, localPath)
					if readOk and type(src) == "string" and #src > 16 then
						return src, localPath
					end
				end
			end
		end

		local remote = GITHUB_RAW .. "/hub/ui/windui/" .. path .. ".luau"
		if Core and type(Core.httpGet) == "function" then
			local ok, src = pcall(Core.httpGet, remote)
			if ok and type(src) == "string" and #src > 32 then
				return src, remote
			end
		end
		return nil, "Noble module not found: " .. path
	end

	local function loadModule(path)
		if moduleCache[path] ~= nil then
			return moduleCache[path]
		end
		local src, via = readModuleSource(path)
		if not src then
			error(via or ("failed to load WindUI module: " .. tostring(path)))
		end
		local loadFn = Core and Core.loadStringFn and Core.loadStringFn()
		if type(loadFn) ~= "function" and type(ENV.loadstring) == "function" then
			loadFn = ENV.loadstring
		end
		if type(loadFn) ~= "function" and type(loadstring) == "function" then
			loadFn = loadstring
		end
		if type(loadFn) ~= "function" then
			error("loadstring unavailable for WindUI module: " .. tostring(path))
		end
		local chunkName = "@WindUI/" .. tostring(path)
		local chunk, compileErr = loadFn(src, chunkName)
		if not chunk then
			error("[" .. chunkName .. "] " .. tostring(compileErr))
		end
		local ok, result = pcall(chunk)
		if not ok then
			error("[" .. chunkName .. "] runtime: " .. tostring(result))
		end
		moduleCache[path] = result
		return result
	end

	-- Bootstrap WindUI framework (Init.luau returns factory(loadModule, Core))
	local winduiFactory = loadModule("Init")
	if type(winduiFactory) ~= "function" then
		error("WindUI Init.luau must return function(loadModule, Core)")
	end
	local windui = winduiFactory(loadModule, Core)
	if type(windui) ~= "table" then
		error("WindUI init factory must return bundle table")
	end

	local Library = windui.Library
	local STATE = windui.STATE
	local Bootstrap = windui.Bootstrap
	local sanitizeFn = windui.sanitize
		or (Bootstrap and Bootstrap.sanitize)
		or function(v, m)
			if v == nil then return "" end
			return tostring(v)
		end

	local Util = {
		textOf = function(v, maxLen)
			return sanitizeFn(v, maxLen or 240)
		end,
		sanitize = sanitizeFn,
	}

	local function log(lvl, msg)
		if type(windui.log) == "function" then
			windui.log(lvl, msg)
		elseif Core and type(Core.say) == "function" then
			Core.say("[" .. lvl .. "] " .. msg)
		end
	end

	local function textOf(v, maxLen)
		if Util and type(Util.textOf) == "function" then
			return Util.textOf(v, maxLen)
		end
		if v == nil then return "" end
		return tostring(v)
	end

	local function sc(name, fn, fallback)
		if type(fn) ~= "function" then return fallback end
		local ok, res = pcall(fn)
		if not ok then
			log("WARN", name .. ": " .. tostring(res))
			return fallback
		end
		return res
	end

	local keybindConn = nil

	local function showNotification(info, duration, ntype)
		if not Library or type(Library.Notification) ~= "function" then return nil end
		if type(info) == "table" then
			return Library:Notification(info)
		end
		local payload = {
			Description = textOf(info),
			Duration = duration or 4,
			Type = ntype or "info",
		}
		return Library:Notification(payload)
	end

	-- ========== EMPTY STUB ==========
	local function emptyGroupStub()
		local function s()
			return {
				Set = function() end,
				SetText = function() end,
				SetVisible = function() end,
				SetValue = function() end,
				Refresh = function() end,
				Container = nil,
			}
		end
		local function l()
			return { Set = function() end, SetText = function() end, SetVisible = function() end }
		end
		return {
			AddLabel = l,
			CreateLabel = l,
			AddToggle = s,
			AddSlider = s,
			AddButton = s,
			AddInput = s,
			AddDropdown = s,
			AddDivider = function() return {} end,
			AddLeftGroupbox = s,
			AddRightGroupbox = s,
			AddGroupbox = s,
			Select = function() end,
		}
	end

	-- ========== GROUPBOX WRAPPER (hardened) ==========
	local function createGroupbox(section, uiBundle)
		section = type(section) == "table" and section or {}
		if not section.AddLabel and not section.AddToggle then
			return emptyGroupStub()
		end

		if section.ForceResize and type(STATE.groupRegistry) == "table" then
			local already = false
			for _, entry in ipairs(STATE.groupRegistry) do
				if entry.section == section then
					already = true
					break
				end
			end
			if not already then
				table.insert(STATE.groupRegistry, {
					section = section,
					update = function()
						pcall(section.ForceResize)
					end,
				})
			end
		end

		local s = 0
		local function ni(n, e)
			s = s + 1
			local base = e
			if not base and Core and type(Core.uiElementId) == "function" then
				base = Core.uiElementId(n)
			end
			if not base then
				base = tostring(n):gsub("[^%w]", "_")
			end
			return base .. "_" .. s
		end

		local function wc(_as, m)
			m = type(m) == "table" and m or {}
			local w = { _busy = false }
			function w:Set(v)
				if w._busy then
					return
				end
				w._busy = true
				local raw = m.raw
				if raw then
					local val = v
					if type(v) == "table" then
						val = v.CurrentValue or v.Value or v.CurrentOption or v
					end
					if m.kind == "toggle" then
						val = val == true
					elseif m.kind == "slider" then
						val = tonumber(val) or 0
					elseif m.kind == "input" then
						val = tostring(val or "")
					end
					if raw.SetValueSilent then
						raw:SetValueSilent(nil, val)
					elseif raw.SetValue then
						raw:SetValue(nil, val)
					elseif raw.Set then
						raw:Set(nil, val)
					end
				end
				w._busy = false
			end
			if m.bindKey and Core and type(Core.bindUiState) == "function" then
				Core.bindUiState(m.bindKey, w, m.kind or "toggle", m.raw)
			end
			return w
		end

		local gb = {}

		function gb:CreateSection(n)
			return gb
		end

		function gb:AddLabel(t)
			if type(section.AddLabel) ~= "function" then
				return { SetText = function() end, Set = function() end, SetVisible = function() end }
			end
			return sc("AddLabel", function()
				return section:AddLabel(textOf(t))
			end) or { SetText = function() end, Set = function() end, SetVisible = function() end }
		end

		function gb:CreateLabel(st, id)
			if type(section.AddLabel) ~= "function" then
				return { Set = function() end, SetText = function() end, SetVisible = function() end }
			end
			local t = textOf(type(st) == "table" and (st.Name or st.Text) or st, 200)
			local r = sc("CreateLabel", function()
				return section:AddLabel(t)
			end)
			STATE.controls = (STATE.controls or 0) + 1
			return {
				Set = function(_, ns)
					if not r then return end
					local nt = textOf(type(ns) == "table" and (ns.Name or ns.Text) or ns, 200)
					if r.SetText then r.SetText(nil, nt) end
					if r.Set then r.Set(nil, { Text = nt, Name = nt }) end
				end,
				SetText = function(_, tv)
					if r and r.SetText then r.SetText(nil, textOf(tv)) end
				end,
				SetVisible = function(_, v)
					if r and r.SetVisible then r.SetVisible(nil, v == true) end
				end,
			}
		end

		function gb:CreateToggle(st, id)
			if type(section.AddToggle) ~= "function" then
				table.insert(STATE.missingBindings, "Toggle:" .. tostring(st.Name or "?"))
				return wc(function() end, {})
			end
			local cv = st.Default or st.CurrentValue or st.Value
			local fl = ni(st.Name, id)
			local r = sc("Toggle:" .. tostring(st.Name), function()
				return section:AddToggle(fl, {
					Text = textOf(st.Name or st.Title or "Toggle", 80),
					Default = cv == true,
					Callback = st.Callback or function() end,
				})
			end)
			STATE.controls = (STATE.controls or 0) + 1
			if not r then table.insert(STATE.missingBindings, "Toggle:" .. tostring(st.Name)) end
			return wc(function(n)
				if not r then return end
				local v = n.CurrentValue or n.Value
				if v == nil then v = n end
				if r.SetValue then r.SetValue(nil, v == true) end
				if r.Set then r.Set(nil, v == true) end
			end, { raw = r, bindKey = st.BindKey or st.StateKey, kind = "toggle" })
		end

		function gb:CreateButton(st, id)
			if type(section.AddButton) ~= "function" then
				table.insert(STATE.missingBindings, "Button:" .. tostring(st.Name or "?"))
				return wc(function() end, {})
			end
			local nm = textOf(st.Name or st.Title or st.Text or "Button", 80)
			local r = sc("Button:" .. nm, function()
				return section:AddButton({ Text = nm, Func = st.Callback or function() end })
			end)
			STATE.controls = (STATE.controls or 0) + 1
			if not r then table.insert(STATE.missingBindings, "Button:" .. nm) end
			return wc(function() end, { raw = r, kind = "button" })
		end

		function gb:CreateSlider(st, id)
			if type(section.AddSlider) ~= "function" then
				table.insert(STATE.missingBindings, "Slider:" .. tostring(st.Name or "?"))
				return wc(function() end, {})
			end
			local rn = st.Range or { 0, 100 }
			local fl = ni(st.Name, id)
			local cv = tonumber(st.Default) or tonumber(st.CurrentValue) or tonumber(st.Value) or rn[1]
			local r = sc("Slider:" .. tostring(st.Name), function()
				return section:AddSlider(fl, {
					Text = textOf(st.Name or st.Title or "Slider", 80),
					Default = cv,
					Min = rn[1] or 0,
					Max = rn[2] or 100,
					Suffix = textOf(st.Suffix or "", 16),
					Rounding = tonumber(st.Increment) or 1,
					Callback = st.Callback or function() end,
				})
			end)
			STATE.controls = (STATE.controls or 0) + 1
			if not r then table.insert(STATE.missingBindings, "Slider:" .. tostring(st.Name)) end
			return wc(function(n)
				if not r then return end
				local v = tonumber(n.CurrentValue) or tonumber(n.Value) or tonumber(n)
				if r.SetValue then r.SetValue(nil, v) end
				if r.Set then r.Set(nil, v) end
			end, { raw = r, bindKey = st.BindKey or st.StateKey, kind = "slider" })
		end

		function gb:CreateInput(st, id)
			if type(section.AddInput) ~= "function" then
				table.insert(STATE.missingBindings, "Input:" .. tostring(st.Name or "?"))
				return wc(function() end, {})
			end
			local fl = ni(st.Name, id)
			local cv = tostring(st.CurrentValue or st.Default or st.Value or "")
			local r = sc("Input:" .. tostring(st.Name), function()
				return section:AddInput(fl, {
					Text = textOf(st.Name or st.Title or "Input", 80),
					Default = textOf(cv, 120),
					Placeholder = textOf(st.PlaceholderText or st.Placeholder or "Enter...", 80),
					Callback = st.Callback or function() end,
				})
			end)
			STATE.controls = (STATE.controls or 0) + 1
			if not r then table.insert(STATE.missingBindings, "Input:" .. tostring(st.Name)) end
			return wc(function(n)
				if not r then return end
				local val = tostring(n.CurrentValue or n.Value or "")
				if r.SetValue then r.SetValue(nil, val) end
				if r.Set then r.Set(nil, val) end
			end, { raw = r, bindKey = st.BindKey or st.StateKey, kind = "input" })
		end

		function gb:CreateDropdown(st, id)
			if type(section.AddDropdown) ~= "function" then
				table.insert(STATE.missingBindings, "Dropdown:" .. tostring(st.Name or "?"))
				return wc(function() end, {})
			end
			local op = st.Options or st.Values or {}
			local mu = st.MultipleOptions == true or st.Multi == true
			local cu = st.CurrentOption or (mu and {} or (op[1] or ""))
			local fl = ni(st.Name, id)
			local r = sc("Dropdown:" .. tostring(st.Name), function()
				return section:AddDropdown(fl, {
					Text = textOf(st.Name or st.Title or "Dropdown", 80),
					Values = op,
					Default = mu and (type(cu) == "table" and cu[1] or cu) or (type(cu) == "table" and cu[1] or cu or op[1] or ""),
					Multi = mu,
					Callback = function(sel)
						local cb = st.Callback or function() end
						if mu then
							cb(Core.normalizeMultiSelection and Core.normalizeMultiSelection(sel) or sel)
						else
							cb(Core.normalizeDropdownValue and Core.normalizeDropdownValue(sel, op[1]) or sel)
						end
					end,
				})
			end)
			STATE.controls = (STATE.controls or 0) + 1
			if not r then table.insert(STATE.missingBindings, "Dropdown:" .. tostring(st.Name)) end
			return wc(function(n)
				if not r then return end
				local nv = n.Options or n.Values
				if type(nv) == "table" and r.Refresh then r.Refresh(nil, nv) end
				local p = n.CurrentOption or n.CurrentOptions
				if p ~= nil then
					if r.SetValue then r.SetValue(nil, tostring(p)) end
					if r.Set then r.Set(nil, tostring(p)) end
				end
			end, { raw = r, bindKey = st.BindKey or st.StateKey, kind = "dropdown" })
		end

		function gb:CreateDivider()
			if type(section.AddDivider) == "function" then
				sc("Divider", function()
					return section:AddDivider()
				end)
			end
			STATE.controls = (STATE.controls or 0) + 1
			return {}
		end

		function gb:CreateStatus(settings, fields)
			local title, dfs = nil, {}
			if type(settings) == "table" then
				title = settings.Name or settings.Title or settings.Label or "Status"
				dfs = settings.Fields or settings.Values or settings.Items or settings.Stats or settings.Data
				if type(dfs) ~= "table" then
					dfs = { Status = settings.Status or settings.Text or settings.Value or "--" }
				end
			else
				title = settings or "Status"
				dfs = type(fields) == "table" and fields or { Status = fields or "--" }
			end
			local st = { Labels = {}, LastValues = {}, Summary = nil }
			if title and textOf(title) ~= "" then
				st.Title = gb:AddLabel(textOf(title))
			end
			for k, v in pairs(dfs) do
				local r = textOf(v)
				st.LastValues[k] = r
				st.Labels[k] = gb:AddLabel(textOf(k) .. ": " .. r)
			end
			st.Summary = gb:AddLabel("")
			function st:Update(key, value)
				local r = textOf(value)
				if self.LastValues[key] == r then return end
				self.LastValues[key] = r
				local row = self.Labels[key]
				if row and row.SetText then
					row.SetText(nil, textOf(key) .. ": " .. r)
				elseif row and row.Set then
					row.Set(nil, { Name = textOf(key) .. ": " .. r, Text = textOf(key) .. ": " .. r })
				end
			end
			function st:SetSummary(text)
				if self.Summary and self.Summary.SetText then
					self.Summary.SetText(nil, textOf(text))
				elseif self.Summary and self.Summary.Set then
					self.Summary.Set(nil, { Name = textOf(text), Text = textOf(text) })
				end
			end
			function st:Set(key, value)
				if type(key) == "table" then
					for k, v in pairs(key) do
						self:Update(k, v)
					end
				else
					self:Update(key, value)
				end
			end
			return st
		end

		return gb
	end

	function Core.createUiGroupbox(s, u)
		return createGroupbox(s, u)
	end

	-- ========== UI WRAPPERS ==========
	function Core.wrapUiGroup(g, cb)
		if not g or (type(g.AddLabel) ~= "function" and type(g.AddToggle) ~= "function" and type(g.CreateToggle) ~= "function") then
			local function s()
				return { Set = function() end, SetText = function() end, SetVisible = function() end }
			end
			return {
				CreateToggle = function() return { Set = function() end } end,
				CreateSlider = function() return { Set = function() end } end,
				CreateButton = function() return { Set = function() end } end,
				CreateInput = function() return { Set = function() end } end,
				CreateDropdown = function() return { Set = function() end } end,
				AddDropdown = function() return { Set = function() end } end,
				CreateStatus = function()
					return { Update = function() end, Set = function() end, SetSummary = function() end }
				end,
				AddLabel = s,
				CreateLabel = s,
				CreateDivider = function() return {} end,
			}
		end
		local gr = {}
		function gr:CreateToggle(n, d, t, c, b)
			if type(g.CreateToggle) == "function" then
				return g:CreateToggle({
					Name = n,
					CurrentValue = d == true,
					Default = d == true,
					Tooltip = t,
					Callback = c or function() end,
					BindKey = b,
				}, b)
			end
			return { Set = function() end }
		end
		function gr:CreateSlider(n, mn, mx, d, c, t, i, b)
			if type(g.CreateSlider) == "function" then
				return g:CreateSlider({
					Name = n,
					Range = { mn, mx },
					CurrentValue = d or mn,
					Default = d or mn,
					Tooltip = t,
					Increment = i,
					Callback = c or function() end,
					BindKey = b,
				}, b)
			end
			return { Set = function() end }
		end
		function gr:CreateButton(n, c, t)
			if type(g.CreateButton) == "function" then
				return g:CreateButton({ Name = n, Tooltip = t, Callback = c or function() end })
			end
			return { Set = function() end }
		end
		function gr:CreateInput(n, ph, a3, a4, a5)
			if type(g.CreateInput) ~= "function" then return { Set = function() end } end
			local ic, df, cb, tp = nil, "", nil, nil
			if type(a3) == "function" then
				cb, tp = a3, a4
			elseif type(a4) == "function" then
				ic, cb, tp = a3, a4, a5
			else
				if type(a3) == "string" or type(a3) == "number" then df = a3 end
				if type(a4) == "function" then cb = a4 end
				tp = a5
			end
			return g:CreateInput({
				Name = n,
				PlaceholderText = ph,
				CurrentValue = df,
				Default = df,
				Tooltip = tp,
				Callback = cb or function() end,
			})
		end
		function gr:CreateDropdown(n, o, d, c, t, b)
			if type(g.CreateDropdown) == "function" then
				return g:CreateDropdown({
					Name = n,
					Options = o,
					CurrentOption = d,
					Tooltip = t,
					Callback = c or function() end,
					BindKey = b,
				}, b)
			end
			return { Set = function() end }
		end
		function gr:AddDropdown(id, c)
			if type(g.CreateDropdown) ~= "function" then return { Set = function() end } end
			c = type(c) == "table" and c or {}
			return g:CreateDropdown({
				Name = c.Text or c.Name or id,
				Options = c.Values or c.Options or {},
				CurrentOption = c.Default or c.CurrentValue or c.CurrentOption,
				MultipleOptions = c.Multi or c.MultiSelection,
				Callback = c.Callback or function() end,
			}, id)
		end
		function gr:CreateStatus(l, f)
			if type(g.CreateStatus) == "function" then
				if type(l) == "table" then return g:CreateStatus(l) end
				return g:CreateStatus({ Name = l or "Status", Fields = f })
			end
			return { Update = function() end, Set = function() end, SetSummary = function() end }
		end
		function gr:AddLabel(t)
			if type(g.AddLabel) == "function" then return g:AddLabel(t) end
			return { SetText = function() end, Set = function() end, SetVisible = function() end }
		end
		function gr:CreateLabel(t)
			if type(g.AddLabel) == "function" then
				local tx = type(t) == "table" and (t.Text or t.Name or t.Title) or tostring(t or "")
				return g:AddLabel(tx)
			end
			return { SetText = function() end, Set = function() end, SetVisible = function() end }
		end
		function gr:CreateDivider()
			if type(g.CreateDivider) == "function" then return g:CreateDivider() end
			return {}
		end
		if type(cb) == "function" then
			pcall(cb, gr)
		end
		return gr
	end

	function Core.wrapUiTab(rt, ub, w)
		local tab = { _rawTab = rt, _ui = ub, _window = w, _columnCount = 2, _sectionIndex = 0 }
		if type(Core._UiTabRegistry) == "table" then
			table.insert(Core._UiTabRegistry, tab)
		end
		function tab:CreateGroupbox(settings)
			settings = settings or {}
			local name = settings.Name or settings.Group or "Group"
			STATE.groupCount = (STATE.groupCount or 0) + 1
			if not rt then
				table.insert(STATE.missingBindings, "Groupbox:" .. name .. "(no tab)")
				return {}
			end
			local h = sc("Groupbox:" .. name, function()
				local col = tonumber(settings.Column) or 1
				if col == 2 and rt.AddRightGroupbox then
					return rt:AddRightGroupbox(name)
				elseif rt.AddLeftGroupbox then
					return rt:AddLeftGroupbox(name)
				elseif rt.AddGroupbox then
					return rt:AddGroupbox(name)
				end
				return nil
			end)
			if not h then
				table.insert(STATE.missingBindings, "Groupbox:" .. name .. "(failed)")
				return {}
			end
			tab._sectionIndex = (tab._sectionIndex or 0) + 1
			return Core.createUiGroupbox(h, ub)
		end
		function tab:Select()
			if rt and rt.Select then rt:Select() end
		end
		function tab:BuildThemeGroupbox(col)
			local g2 = Core.buildUiGroup(tab, "Appearance", col or 1)
			if g2 and type(g2.CreateLabel) == "function" then
				g2:CreateLabel("Alleral WindUI v11")
			end
			return g2
		end
		return tab
	end

	function Core.buildUiWindow(ui, settings)
		settings = settings or {}
		local lib = ui and ui.Library
		if not lib or type(lib.CreateWindow) ~= "function" then return nil end
		local rw = lib:CreateWindow(settings)
		if not rw then return nil end
		local w = {
			_rawWindow = rw,
			_ui = ui,
			_library = lib,
			_initialized = false,
			_tabGroup = rw,
			_alleralSettings = settings,
		}
		function w:Notify(p)
			if rw and type(rw.Notify) == "function" then
				return rw:Notify(p)
			end
			if lib and type(lib.Notify) == "function" then
				return lib:Notify(p)
			end
		end
		function w:Unload()
			if rw and type(rw.Unload) == "function" then
				pcall(function() rw:Unload() end)
			end
		end
		w.Hide = function()
			if rw and rw.Hide then rw:Hide() end
		end
		w.Show = function()
			if rw and rw.Show then rw:Show() end
		end
		w.Toggle = function()
			if rw and rw.Toggle then rw:Toggle() end
		end
		function w:Validate()
			if rw and type(rw.Validate) == "function" then
				return rw:Validate()
			end
			return false
		end
		function w:SetTheme(name)
			if rw and type(rw.SetTheme) == "function" then
				pcall(function() rw:SetTheme(name) end)
			elseif lib and type(lib.SetTheme) == "function" then
				pcall(function() lib:SetTheme(name) end)
			end
		end
		ENV.Alleral_UiWindow = w
		if type(Core.registerUiWindow) == "function" then
			Core.registerUiWindow(w)
		end
		if type(Core.flushPendingNotifications) == "function" then
			Core.flushPendingNotifications()
		end
		return w
	end

	function Core.buildUiTab(section, name, icon, columns, id)
		local w2 = type(Core.resolveUiWindow) == "function" and Core.resolveUiWindow(section) or nil
		if type(w2) ~= "table" or not w2._rawWindow then
			return Core.wrapUiTab(nil, type(section) == "table" and section._ui or nil, w2)
		end
		local tg = w2._tabGroup or w2._rawWindow or w2
		if not tg or type(tg.AddTab) ~= "function" then
			return Core.wrapUiTab(nil, w2._ui, w2)
		end
		local rt = tg:AddTab(name, icon)
		STATE.tabCount = (STATE.tabCount or 0) + 1
		local wr = Core.wrapUiTab(rt, w2._ui or (type(section) == "table" and section._ui) or nil, w2)
		wr._columnCount = math.max(1, tonumber(columns) or 2)
		if not w2._defaultTab then w2._defaultTab = rt end
		return wr
	end

	function Core.buildUiGroup(tab, name, column, cb, icon, id)
		name = tostring(name or "Group")
		if type(tab) ~= "table" or type(tab.CreateGroupbox) ~= "function" then return {} end
		return Core.wrapUiGroup(tab:CreateGroupbox({ Name = name, Column = column or 1, Icon = icon }), cb)
	end

	function Core.buildUiSection(w2)
		if type(w2) == "table" and w2._alleralTabGroup then return w2._alleralTabGroup end
		if type(w2) == "table" and w2._rawWindow then return w2 end
		return w2
	end

	function Core.finalizeGameUi(window, ui, options)
		options = type(options) == "table" and options or {}
		if type(window) == "table" and window._rawWindow and not window._initialized then
			window._initialized = true
			task.defer(function()
				pcall(function()
					if window._defaultTab and window._defaultTab.Select then
						window._defaultTab:Select()
					end
				end)
			end)
		end
		task.defer(function()
			pcall(function()
				local raw = type(window) == "table" and (window._rawWindow or window) or nil
				if raw and type(raw.Validate) == "function" then
					raw:Validate()
				end
			end)
		end)
		if type(Core.setupHubKeybinds) == "function" then
			pcall(Core.setupHubKeybinds, { window = window, ui = ui or window._ui or ENV.Alleral_UI })
		end
		if options.notify ~= false and type(Core.notifyBootReady) == "function" then
			Core.notifyBootReady({ Name = options.Name or "Alleral", Subtitle = options.Subtitle })
		end
		log("INFO", "=== Alleral WindUI v" .. (Library and Library.Version or "11.0.0") .. " ===")
		log("INFO", "Tabs: " .. tostring(STATE.tabCount or 0) .. " | Groups: " .. tostring(STATE.groupCount or 0) .. " | Controls: " .. tostring(STATE.controls or 0))
		if type(STATE.missingBindings) == "table" and #STATE.missingBindings > 0 then
			log("WARN", "Missing bindings: " .. #STATE.missingBindings)
		end
		return window
	end

	function Core.repairUiWindow(w3)
		w3 = w3 or ENV.Alleral_UiWindow
		return type(w3) == "table" and w3._rawWindow ~= nil
	end

	function Core.refreshAllTabColumns()
		if type(STATE.groupRegistry) ~= "table" then return true end
		for _, entry in ipairs(STATE.groupRegistry) do
			if entry.update then pcall(entry.update) end
			if entry.section and entry.section.ForceColumnResize then
				pcall(entry.section.ForceColumnResize)
			end
		end
		local win = STATE.activeWindow
		if win and type(win._win) == "table" and win._win.ForceColumnResize then
			pcall(function() win._win:ForceColumnResize() end)
		end
		return true
	end

	-- ========== CORE API ==========
	function Core.loadUi()
		local c = ENV.Alleral_UI
		if type(c) == "table" and type(c.Library) == "table" then return c end
		local b = {
			Library = Library,
			Alleral = Library,
			STATE = STATE,
			Util = Util,
			CreateWindow = function(_, s)
				return Library:CreateWindow(s)
			end,
			Notify = function(_, t, d)
				return Library:Notify(t, d)
			end,
			ClearNotifications = function()
				if Library.ClearNotifications then Library:ClearNotifications() end
			end,
		}
		ENV.Alleral_UI = b
		ENV._AlleralUiLibrary = Library
		ENV._AlleralUI = b
		ENV._WindUIBundle = windui
		if getgenv then getgenv().Alleral_UI = b end
		log("INFO", "[UI] WindUI renderer v" .. (Library.Version or "11.0.0") .. " ready")
		return b
	end

	function Core.preloadUi()
		return Core.loadUi()
	end

	function Core.uiLibrary(b)
		if type(b) ~= "table" then return nil end
		return b.Alleral or b.Library
	end

	function Core.uiWindowSettings(extra)
		extra = type(extra) == "table" and extra or {}
		local gameId = STATE and STATE.gameId or (Bootstrap and Bootstrap.resolveGameId(Core)) or "alleral"
		return {
			Title = extra.Title or extra.Name or "Alleral",
			Name = extra.Title or extra.Name or "Alleral",
			Subtitle = extra.Subtitle or extra.Author or "",
			Icon = extra.Icon or "sparkles",
			Theme = extra.Theme or "WindUI",
			Keybind = extra.Keybind or Enum.KeyCode.RightShift,
			ConfigFolder = extra.ConfigFolder or (Bootstrap and Bootstrap.configFolder(Core)) or ("configs/" .. gameId),
			FileSettings = {
				RootFolder = extra.configFolder or "configs",
				ConfigFolder = gameId,
			},
		}
	end

	Core.notifyUi = function(i)
		if type(i) == "table" then
			return showNotification(i)
		end
		return showNotification(textOf(i), 4)
	end

	function Core.releaseAlleralRuntime()
		if keybindConn then
			pcall(function() keybindConn:Disconnect() end)
			keybindConn = nil
		end
		if Library and type(Library.ClearNotifications) == "function" then
			pcall(function() Library:ClearNotifications() end)
		end
		local active = STATE and STATE.activeWindow
		if active then
			pcall(function()
				if active.Unload then active:Unload()
				elseif active.Destroy then active:Destroy() end
			end)
			STATE.activeWindow = nil
		end
		local uiWin = ENV.Alleral_UiWindow
		if type(uiWin) == "table" and uiWin._rawWindow then
			pcall(function()
				if uiWin._rawWindow.Unload then uiWin._rawWindow:Unload() end
			end)
		end
		ENV._AlleralUiLibrary = nil
		ENV._AlleralUI = nil
		ENV._WindUIBundle = nil
		ENV.Alleral_UiWindow = nil
		if STATE then
			STATE.groupRegistry = {}
			STATE.uiDestroyed = true
		end
	end

	ENV.AnimatedNotification = showNotification

	Core._WindUI = windui
	ENV._NobleV10Bundle = nil
	ENV._NobleV8Bundle = nil
	Core._NobleV10 = nil
	Core._NobleV8 = nil

	log("INFO", "Alleral WindUI v11.1.0 — sole UI framework loaded")
end