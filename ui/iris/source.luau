-- Alleral Iris — ImGui overlay (GhostDuckyy Iris 2.0.4) + MacLib adapter
-- Patch: safer Iris Begin/End stack handling + fixed dropdown selection
local ALLERAL_IRIS_VERSION = 4
local IRIS_VERSION = "2.0.4"
local IRIS_BUNDLE_URL =
	"https://raw.githubusercontent.com/GhostDuckyy/UI-Libraries/main/ImGui/Iris/Versions/2.0.4/Source.lua"
local IRIS_BUNDLE_MIN_BYTES = 250000

local MacLib = {}
MacLib.__AlleralPatch = ALLERAL_IRIS_VERSION
MacLib.__IrisUi = true
MacLib.__IrisExploitUi = true
MacLib.__AlleralVersion = IRIS_VERSION

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local StarterGui = game:GetService("StarterGui")
local UserInputService = game:GetService("UserInputService")

local ENV = (function()
	local ok, env = pcall(function()
		return getgenv and getgenv() or getfenv()
	end)
	return ok and env or {}
end)()

local IrisModule = nil
local Iris = nil
local irisBooted = false
local configFolder = "Alleral_Configs"
local windows = {}
local menuKey = Enum.KeyCode.RightControl
local exploitOverlayKey = Enum.KeyCode.RightShift
local mirrorWindows = {}

local function stateValue(state)
	if type(state) == "table" and type(state.get) == "function" then
		local ok, value = pcall(function()
			return state:get()
		end)
		if ok then
			return value
		end
	end
	if type(state) == "table" and state.value ~= nil then
		return state.value
	end
	return nil
end

local function safeCall(fn, ...)
	if type(fn) ~= "function" then
		return false, nil
	end
	return pcall(fn, ...)
end

local function safeEnd()
	pcall(function()
		Iris.End()
	end)
end

local function wasClicked(widget)
	if type(widget) ~= "table" then
		return false
	end
	if type(widget.clicked) == "function" then
		local ok, result = pcall(widget.clicked, widget)
		if ok then
			return result == true
		end
		ok, result = pcall(widget.clicked)
		return ok and result == true
	end
	if type(widget.selected) == "function" then
		local ok, result = pcall(widget.selected, widget)
		if ok then
			return result == true
		end
		ok, result = pcall(widget.selected)
		return ok and result == true
	end
	return false
end

local function fetchBundle()
	if type(ENV._AlleralIrisBundle) == "string" and #ENV._AlleralIrisBundle >= IRIS_BUNDLE_MIN_BYTES then
		return ENV._AlleralIrisBundle
	end
	if type(ENV.Alleral_HTTP) == "table" and type(ENV.Alleral_HTTP.get) == "function" then
		local src = ENV.Alleral_HTTP.get(IRIS_BUNDLE_URL .. "?t=" .. tostring(tick()), IRIS_BUNDLE_MIN_BYTES)
		if type(src) == "string" and #src >= IRIS_BUNDLE_MIN_BYTES then
			ENV._AlleralIrisBundle = src
			return src
		end
	end
	return nil
end

local function renderDropdown(element)
	local options = type(element.options) == "table" and element.options or {}
	local previewText = "Select"
	if type(element.previewFn) == "function" then
		local ok, value = pcall(element.previewFn)
		if ok and value ~= nil and tostring(value) ~= "" then
			previewText = tostring(value)
		end
	elseif element.preview ~= nil then
		previewText = tostring(element.preview)
	end

	Iris.Text({ tostring(element.name or "Dropdown") })

	-- Iris 2.x Combo should receive the preview text directly. Do not pass indexState here;
	-- the Selectable calls handle selection. Passing the wrong state shape can corrupt Iris internals.
	local combo = Iris.Combo({ previewText }, { isOpened = element.openState })
	local isOpen = combo and combo.state and combo.state.isOpened and stateValue(combo.state.isOpened) == true
	if not isOpen then
		return
	end

	for optIndex, option in ipairs(options) do
		local optionText = tostring(option)
		local selectedNow = false

		if element.multi then
			for _, value in ipairs(element.selectedValues or {}) do
				if tostring(value) == optionText then
					selectedNow = true
					break
				end
			end
		else
			selectedNow = tostring(element.selectedSingle or "") == optionText
		end

		local selectedState = Iris.State(selectedNow)
		local selectable = Iris.Selectable({ optionText }, { selected = selectedState })

		if wasClicked(selectable) then
			if element.multi then
				element.selectedValues = element.selectedValues or {}
				local foundIndex = nil
				for index, value in ipairs(element.selectedValues) do
					if tostring(value) == optionText then
						foundIndex = index
						break
					end
				end

				if foundIndex then
					table.remove(element.selectedValues, foundIndex)
				else
					table.insert(element.selectedValues, optionText)
				end

				if type(element.callback) == "function" then
					element.callback(element.selectedValues)
				end
			else
				element.selectedSingle = optionText
				if element.indexState then
					element.indexState:set(optIndex)
				end
				if element.openState then
					element.openState:set(false)
				end
				if type(element.callback) == "function" then
					element.callback(optionText)
				end
			end
		end
	end

	safeEnd()
end

local function renderElement(element)
	if type(element) ~= "table" then
		return
	end

	if element.kind == "toggle" then
		Iris.Checkbox({ tostring(element.name or "Toggle") }, { isChecked = element.state })
		local value = element.state and element.state:get()
		if value ~= element.last then
			element.last = value
			if type(element.callback) == "function" then
				element.callback(value)
			end
		end
	elseif element.kind == "slider" then
		Iris.SliderNum({
			Text = tostring(element.name or "Slider"),
			Min = element.min,
			Max = element.max,
			Increment = element.step,
		}, { number = element.state })
		local value = element.state and element.state:get()
		if value ~= element.last then
			element.last = value
			if type(element.callback) == "function" then
				element.callback(value)
			end
		end
	elseif element.kind == "button" then
		local button = Iris.Button({ tostring(element.name or "Button") })
		if wasClicked(button) and type(element.callback) == "function" then
			element.callback()
		end
	elseif element.kind == "input" then
		Iris.InputText({ Text = tostring(element.name or "Input") }, { text = element.state })
		local value = element.state and element.state:get()
		if value ~= element.last then
			element.last = value
			if type(element.callback) == "function" then
				element.callback(value)
			end
		end
	elseif element.kind == "label" then
		Iris.Text({ tostring(element.text or "") })
	elseif element.kind == "divider" then
		Iris.Separator()
	elseif element.kind == "dropdown" then
		renderDropdown(element)
	elseif element.kind == "keybind" then
		if element.listening then
			Iris.Text({ tostring(element.name or "Keybind") .. ": press a key..." })
		else
			local keyButton = Iris.Button({ tostring(element.name or "Keybind") .. ": " .. tostring(element.keyName or "None") })
			if wasClicked(keyButton) then
				element.listening = true
			end
		end
	end
end

local function renderWindow(win)
	if type(win) ~= "table" or win.visible == false then
		return
	end

	local opened = Iris.Window({
		Title = tostring(win.title or "Alleral"),
		NoClose = false,
		NoResize = false,
	}, { isOpened = win.openState })

	local windowOpen = true
	if opened and opened.state and opened.state.isOpened then
		windowOpen = stateValue(opened.state.isOpened) ~= false
	end

	if windowOpen then
		for index, tab in ipairs(win.tabs or {}) do
			local tabButton = Iris.Button({ tostring(tab.name or "Tab") .. "##tab_" .. tostring(index) })
			if wasClicked(tabButton) then
				win.activeTab = index
			end
			if index < #(win.tabs or {}) then
				pcall(function()
					Iris.SameLine()
				end)
			end
		end

		Iris.Separator()

		local tab = win.tabs and win.tabs[win.activeTab]
		if tab and type(tab.sections) == "table" then
			for _, section in ipairs(tab.sections) do
				local expanded = Iris.CollapsingHeader({ tostring(section.name or "Section") }, { isUncollapsed = section.openState })
				local isExpanded = expanded and expanded.state and expanded.state.isUncollapsed and stateValue(expanded.state.isUncollapsed) == true

				if isExpanded then
					for _, element in ipairs(section.elements or {}) do
						local ok, err = pcall(function()
							renderElement(element)
						end)
						if not ok then
							warn("[Alleral Iris] element render failed: " .. tostring(err))
						end
					end
					safeEnd()
				end
			end
		end
	end

	safeEnd()
end

local function bootIris()
	if irisBooted and Iris then
		return Iris
	end

	local src = fetchBundle()
	if not src then
		return nil, "Iris bundle missing"
	end

	local chunk = loadstring or load
	if type(chunk) ~= "function" then
		return nil, "loadstring unavailable"
	end

	local compiled, err = chunk(src, "@Iris/bundle")
	if not compiled then
		return nil, tostring(err or "Iris compile failed")
	end

	local ok, pkg = pcall(compiled)
	if not ok or type(pkg) ~= "table" then
		return nil, tostring(pkg or "Iris bundle runtime failed")
	end

	IrisModule = pkg

	local player = Players.LocalPlayer
	local parent = player and player:FindFirstChildOfClass("PlayerGui") or nil
	if not parent then
		return nil, "PlayerGui unavailable"
	end

	Iris = pkg.Init(parent, RunService.Heartbeat)
	if type(Iris) ~= "table" then
		return nil, "Iris.Init failed"
	end

	pcall(function()
		Iris.UpdateGlobalConfig({
			Color = {
				TextColor = Color3.fromRGB(235, 235, 235),
				TextDisabledColor = Color3.fromRGB(150, 150, 150),
				WindowBgColor = Color3.fromRGB(18, 18, 20),
				PopupBgColor = Color3.fromRGB(22, 22, 26),
				BorderColor = Color3.fromRGB(60, 60, 66),
				BorderShadowColor = Color3.fromRGB(0, 0, 0),
				ResizeGripColor = Color3.fromRGB(83, 252, 24),
				ResizeGripHoveredColor = Color3.fromRGB(110, 255, 60),
				ResizeGripActiveColor = Color3.fromRGB(83, 252, 24),
				ScrollbarBgColor = Color3.fromRGB(14, 14, 16),
				ScrollbarGrabColor = Color3.fromRGB(70, 70, 74),
				ScrollbarGrabHoveredColor = Color3.fromRGB(90, 90, 96),
				ScrollbarGrabActiveColor = Color3.fromRGB(83, 252, 24),
				SliderGrabColor = Color3.fromRGB(83, 252, 24),
				SliderGrabActiveColor = Color3.fromRGB(110, 255, 60),
				ButtonColor = Color3.fromRGB(34, 34, 38),
				ButtonHoveredColor = Color3.fromRGB(48, 48, 54),
				ButtonActiveColor = Color3.fromRGB(83, 252, 24),
				HeaderColor = Color3.fromRGB(34, 34, 38),
				HeaderHoveredColor = Color3.fromRGB(48, 48, 54),
				HeaderActiveColor = Color3.fromRGB(83, 252, 24),
				TabColor = Color3.fromRGB(28, 28, 32),
				TabHoveredColor = Color3.fromRGB(48, 48, 54),
				TabActiveColor = Color3.fromRGB(34, 34, 38),
				TableHeaderBgColor = Color3.fromRGB(28, 28, 32),
				TableBorderStrongColor = Color3.fromRGB(60, 60, 66),
				TableBorderLightColor = Color3.fromRGB(44, 44, 48),
				TableRowBgColor = Color3.fromRGB(0, 0, 0),
				TableRowBgAltColor = Color3.fromRGB(255, 255, 255),
				TextSelectedBgColor = Color3.fromRGB(83, 252, 24),
				DragDropTargetColor = Color3.fromRGB(83, 252, 24),
				NavHighlightColor = Color3.fromRGB(83, 252, 24),
				NavWindowingHighlightColor = Color3.fromRGB(255, 255, 255),
				NavWindowingDimBgColor = Color3.fromRGB(0, 0, 0),
				ModalWindowDimBgColor = Color3.fromRGB(0, 0, 0),
			},
		})
	end)

	Iris:Connect(function()
		for _, win in ipairs(windows) do
			local okRender, renderErr = pcall(function()
				renderWindow(win)
			end)
			if not okRender then
				warn("[Alleral Iris] window render failed: " .. tostring(renderErr))
			end
		end
	end)

	irisBooted = true

	UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed or not irisBooted then
			return
		end
		for _, win in ipairs(windows) do
			for _, tab in ipairs(win.tabs or {}) do
				for _, section in ipairs(tab.sections or {}) do
					for _, element in ipairs(section.elements or {}) do
						if element.kind == "keybind" and element.listening and input.UserInputType == Enum.UserInputType.Keyboard then
							element.keyName = input.KeyCode.Name
							element.listening = false
							if type(element.callback) == "function" then
								element.callback(input.KeyCode)
							end
						end
					end
				end
			end
		end
	end)

	return Iris
end

local function sideOrder(side)
	if side == "Right" then
		return 300
	end
	if side == "Center" then
		return 200
	end
	return 100
end

function MacLib.SetFolder(_self, folder)
	if type(folder) == "string" and folder ~= "" then
		configFolder = folder
	end
end

function MacLib.ApplyEffectsFromEnv(_self, _env)
	return true
end

function MacLib.SetAutoResize(_self, _state)
	return true
end

function MacLib.GetAutoResize(_self)
	return true
end

function MacLib.GetUiScale(_self)
	return 1
end

function MacLib.GetLayoutInfo(_self)
	return { profile = "iris", engine = "Iris", version = IRIS_VERSION, exploitOverlay = true }
end

function MacLib.AttachExploitMirror(_self, onyxWindow)
	if type(onyxWindow) ~= "table" then
		return false
	end
	table.insert(mirrorWindows, onyxWindow)
	return true
end

function MacLib:Window(Settings)
	Settings = Settings or {}
	local ir, err = bootIris()
	if not ir then
		warn("[Alleral Iris] " .. tostring(err))
		return nil
	end

	local WindowFunctions = {
		Settings = Settings,
		_tabs = {},
		_activeTab = nil,
		visible = true,
		title = Settings.Title or "Alleral",
		openState = Iris.State(true),
		activeTab = 1,
		tabs = {},
	}

	if Settings.Keybind then
		menuKey = Settings.Keybind
	end

	table.insert(windows, WindowFunctions)

	function WindowFunctions:TabGroup()
		local TabGroupFunctions = {}

		function TabGroupFunctions:Tab(TabSettings)
			TabSettings = TabSettings or {}
			local TabFunctions = { Settings = TabSettings, _sections = {} }
			local tabData = {
				name = TabSettings.Name or "Tab",
				sections = {},
			}
			TabFunctions._tabData = tabData

			function TabFunctions:Select()
				for index, tab in ipairs(WindowFunctions.tabs) do
					if tab == tabData then
						WindowFunctions.activeTab = index
						break
					end
				end
			end

			function TabFunctions:Section(SectionSettings)
				SectionSettings = SectionSettings or {}
				local SectionFunctions = {}
				local sectionData = {
					name = SectionSettings.Name or SectionSettings.Text or "Section",
					openState = Iris.State(true),
					elements = {},
					order = sideOrder(SectionSettings.Side),
				}

				local function addElement(element)
					element.order = element.order or (#sectionData.elements + 1)
					table.insert(sectionData.elements, element)
					return element
				end

				function SectionFunctions:Header(HS, _flag)
					local element = addElement({
						kind = "label",
						text = (HS and (HS.Text or HS.Name)) or "",
						order = 0,
					})
					return {
						UpdateName = function(_, value)
							element.text = tostring(value or "")
						end,
					}
				end

				function SectionFunctions:Label(LS, _flag)
					local element = addElement({
						kind = "label",
						text = (LS and (LS.Text or LS.Name)) or "",
					})
					return {
						UpdateName = function(_, value)
							element.text = tostring(value or "")
						end,
					}
				end

				function SectionFunctions:Divider()
					addElement({ kind = "divider" })
					return {}
				end

				function SectionFunctions:Button(BS, _flag)
					local element = addElement({
						kind = "button",
						name = BS and BS.Name or "Button",
						callback = BS and BS.Callback,
					})
					return {
						UpdateName = function(_, value)
							element.name = tostring(value or "Button")
						end,
					}
				end

				function SectionFunctions:Toggle(TS, _flag)
					TS = TS or {}
					local state = Iris.State(TS.Default == true)
					local element = addElement({
						kind = "toggle",
						name = TS.Name or "Toggle",
						state = state,
						last = state:get(),
						callback = TS.Callback,
					})
					return {
						UpdateState = function(_, value)
							state:set(value == true)
							element.last = state:get()
						end,
						GetState = function()
							return state:get()
						end,
					}
				end

				function SectionFunctions:Slider(SS, _flag)
					SS = SS or {}
					local minV = tonumber(SS.Minimum) or 0
					local maxV = tonumber(SS.Maximum) or 100
					local default = tonumber(SS.Default) or minV
					local state = Iris.State(default)
					local element = addElement({
						kind = "slider",
						name = SS.Name or "Slider",
						min = minV,
						max = maxV,
						step = tonumber(SS.Increment) or 1,
						state = state,
						last = state:get(),
						callback = SS.Callback,
					})
					return {
						UpdateValue = function(_, value)
							state:set(tonumber(value) or minV)
							element.last = state:get()
						end,
						GetValue = function()
							return state:get()
						end,
					}
				end

				function SectionFunctions:Input(IS, _flag)
					IS = IS or {}
					local state = Iris.State(IS.Default or "")
					local element = addElement({
						kind = "input",
						name = IS.Name or "Input",
						state = state,
						last = state:get(),
						callback = IS.Callback,
					})
					return {
						UpdateText = function(_, value)
							state:set(tostring(value or ""))
							element.last = state:get()
						end,
						GetText = function()
							return state:get()
						end,
					}
				end

				function SectionFunctions:Dropdown(DS, _flag)
					DS = DS or {}
					local options = type(DS.Options) == "table" and DS.Options or {}
					local multi = DS.Multi == true
					local indexState = Iris.State(1)
					local openState = Iris.State(false)
					local selected = {}

					if multi and type(DS.Default) == "table" then
						for _, value in ipairs(DS.Default) do
							table.insert(selected, tostring(value))
						end
					elseif DS.Default ~= nil then
						selected = { tostring(DS.Default) }
					elseif options[1] ~= nil then
						selected = { tostring(options[1]) }
					end

					local element
					local function previewText()
						if multi then
							if #(element and element.selectedValues or selected) == 0 then
								return "Select"
							end
							return table.concat(element and element.selectedValues or selected, ", ")
						end
						return tostring((element and element.selectedSingle) or selected[1] or options[1] or "Select")
					end

					element = addElement({
						kind = "dropdown",
						name = DS.Name or "Dropdown",
						options = options,
						multi = multi,
						openState = openState,
						indexState = indexState,
						previewFn = previewText,
						selectedSingle = selected[1],
						selectedValues = selected,
						selected = function()
							if multi then
								return element.selectedValues
							end
							return element.selectedSingle
						end,
						callback = DS.Callback,
					})

					return {
						Refresh = function(_, values)
							if type(values) == "table" then
								element.options = values
							end
						end,
						SetValues = function(_, values)
							if type(values) == "table" then
								element.options = values
							end
						end,
						SetValue = function(_, value)
							if multi and type(value) == "table" then
								element.selectedValues = {}
								for _, v in ipairs(value) do
									table.insert(element.selectedValues, tostring(v))
								end
							else
								element.selectedSingle = tostring(value)
							end
						end,
						GetValue = function()
							return element.selected()
						end,
					}
				end

				function SectionFunctions:Keybind(KS, _flag)
					KS = KS or {}
					local element = addElement({
						kind = "keybind",
						name = KS.Name or "Keybind",
						keyName = tostring((KS.Default and KS.Default.Name) or menuKey.Name),
						listening = false,
						callback = KS.Callback,
					})
					return {
						SetKey = function(_, keyCode)
							element.keyName = tostring(keyCode and keyCode.Name or keyCode or "None")
						end,
					}
				end

				table.insert(tabData.sections, sectionData)
				table.sort(tabData.sections, function(a, b)
					return (a.order or 0) < (b.order or 0)
				end)
				table.insert(TabFunctions._sections, SectionFunctions)
				return SectionFunctions
			end

			table.insert(WindowFunctions.tabs, tabData)
			if #WindowFunctions.tabs == 1 then
				WindowFunctions.activeTab = 1
			end
			table.insert(WindowFunctions._tabs, TabFunctions)
			return TabFunctions
		end

		return TabGroupFunctions
	end

	function WindowFunctions:Notify(payload)
		payload = type(payload) == "table" and payload or {}
		pcall(function()
			StarterGui:SetCore("SendNotification", {
				Title = payload.Title or "Alleral",
				Text = payload.Description or payload.Content or "",
				Duration = payload.Lifetime or payload.Duration or 4,
			})
		end)
	end

	function WindowFunctions:SetState(state)
		WindowFunctions.visible = state ~= false
		WindowFunctions.openState:set(WindowFunctions.visible)
	end

	function WindowFunctions:GetState()
		return WindowFunctions.visible
	end

	function WindowFunctions:Unload()
		WindowFunctions.visible = false
		if WindowFunctions.openState then
			WindowFunctions.openState:set(false)
		end
		for index, win in ipairs(windows) do
			if win == WindowFunctions then
				table.remove(windows, index)
				break
			end
		end
	end

	WindowFunctions._macTabGroup = WindowFunctions:TabGroup()
	return WindowFunctions
end

return MacLib
