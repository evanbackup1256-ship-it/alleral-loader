-- Alleral Rayfield — MacLib adapter using Rayfield UI library
local ALLERAL_RAYFIELD_VERSION = 1
local RAYFIELD_VERSION = "1.0.0"
local RAYFIELD_SOURCE_URL =
	"https://raw.githubusercontent.com/shlexware/Rayfield/main/source"

local MacLib = {}
MacLib.__AlleralPatch = ALLERAL_RAYFIELD_VERSION
MacLib.__RayfieldUi = true
MacLib.__AlleralVersion = RAYFIELD_VERSION

local Players = game:GetService("Players")
local StarterGui = game:GetService("StarterGui")
local UserInputService = game:GetService("UserInputService")

local ENV = (function()
	local ok, env = pcall(function()
		return getgenv and getgenv() or getfenv()
	end)
	return ok and env or {}
end)()

local Rayfield = nil
local rayfieldBooted = false
local configFolder = "Alleral_Configs"
local windows = {}
local menuKey = Enum.KeyCode.RightControl

local function fetchRayfield()
	if type(ENV._AlleralRayfieldBundle) == "string" and #ENV._AlleralRayfieldBundle > 1000 then
		return ENV._AlleralRayfieldBundle
	end
	if type(ENV.Alleral_HTTP) == "table" and type(ENV.Alleral_HTTP.get) == "function" then
		local src = ENV.Alleral_HTTP.get(RAYFIELD_SOURCE_URL .. "?t=" .. tostring(tick()), 1000)
		if type(src) == "string" and #src > 1000 then
			ENV._AlleralRayfieldBundle = src
			return src
		end
	end
	return nil
end

local function bootRayfield()
	if rayfieldBooted and Rayfield then
		return Rayfield
	end

	local src = fetchRayfield()
	if not src then
		return nil, "Rayfield source missing"
	end

	local chunk = loadstring or load
	if type(chunk) ~= "function" then
		return nil, "loadstring unavailable"
	end

	local compiled, err = chunk(src, "@Rayfield/source")
	if not compiled then
		return nil, tostring(err or "Rayfield compile failed")
	end

	local ok, pkg = pcall(compiled)
	if not ok or type(pkg) ~= "table" then
		return nil, tostring(pkg or "Rayfield runtime failed")
	end

	Rayfield = pkg
	rayfieldBooted = true
	return Rayfield
end

function MacLib.SetFolder(_, folder)
	if type(folder) == "string" and folder ~= "" then
		configFolder = folder
	end
end

function MacLib.ApplyEffectsFromEnv(_, _env)
	return true
end

function MacLib.SetAutoResize(_, _state)
	return true
end

function MacLib.GetAutoResize(_)
	return true
end

function MacLib.GetUiScale(_)
	return 1
end

function MacLib.GetLayoutInfo(_)
	return { profile = "rayfield", engine = "Rayfield", version = RAYFIELD_VERSION, exploitOverlay = false }
end

function MacLib.AttachExploitMirror(_, _onyxWindow)
	return false
end

function MacLib:Window(Settings)
	Settings = Settings or {}
	local rf, err = bootRayfield()
	if not rf then
		warn("[Alleral Rayfield] " .. tostring(err))
		return nil
	end

	local WindowFunctions = {
		Settings = Settings,
		_tabs = {},
		_activeTab = nil,
		visible = true,
		title = Settings.Title or "Alleral",
		_rfWindow = nil,
		_rfTabs = {},
	}

	if Settings.Keybind then
		menuKey = Settings.Keybind
	end

	local success, rfWindow = pcall(function()
		return rf:CreateWindow({
			Name = Settings.Title or "Alleral",
			Subtitle = Settings.Subtitle or "",
			LoadingTitle = "Alleral",
			LoadingSubtitle = "Loading...",
			ConfigurationSaving = {
				Enabled = true,
				FolderName = configFolder,
			},
			Discord = {
				Enabled = false,
			},
			KeySystem = false,
		})
	end)

	if not success or not rfWindow then
		warn("[Alleral Rayfield] Window creation failed")
		return nil
	end

	WindowFunctions._rfWindow = rfWindow
	table.insert(windows, WindowFunctions)

	function WindowFunctions:TabGroup()
		local TabGroupFunctions = {}

		function TabGroupFunctions:Tab(TabSettings)
			TabSettings = TabSettings or {}
			local TabFunctions = {}
			local tabName = TabSettings.Name or "Tab"

			local rfTab = rfWindow:CreateTab({
				Name = tabName,
			})

			table.insert(WindowFunctions._rfTabs, rfTab)

			function TabFunctions:Select()
				-- Rayfield doesn't support programmatic tab switching
			end

			function TabFunctions:Section(SectionSettings)
				SectionSettings = SectionSettings or {}
				local SectionFunctions = {}
				local sectionName = SectionSettings.Name or SectionSettings.Text or "Section"

				-- Create a Rayfield section header
				rfTab:CreateSection(sectionName)

				function SectionFunctions:CreateToggle(settings, id)
					local state = settings.Default == true
					local toggle = rfTab:CreateToggle({
						Name = settings.Name or "Toggle",
						CurrentValue = state,
						Callback = function(value)
							if type(settings.Callback) == "function" then
								settings.Callback(value)
							end
						end,
					})
					return {
						UpdateState = function(_, value)
							if toggle and type(toggle.Set) == "function" then
								pcall(toggle.Set, toggle, value == true)
							end
						end,
						GetState = function()
							return state
						end,
					}
				end

				function SectionFunctions:CreateSlider(settings, id)
					local minV = tonumber(settings.Minimum) or 0
					local maxV = tonumber(settings.Maximum) or 100
					local defV = tonumber(settings.Default) or minV
					local slider = rfTab:CreateSlider({
						Name = settings.Name or "Slider",
						Min = minV,
						Max = maxV,
						Default = defV,
						Increment = tonumber(settings.Increment) or 1,
						Callback = function(value)
							if type(settings.Callback) == "function" then
								settings.Callback(value)
							end
						end,
					})
					return {
						UpdateValue = function(_, value)
							if slider and type(slider.Set) == "function" then
								pcall(slider.Set, slider, tonumber(value) or minV)
							end
						end,
						GetValue = function()
							return defV
						end,
					}
				end

				function SectionFunctions:CreateButton(settings, id)
					rfTab:CreateButton({
						Name = settings.Name or "Button",
						Callback = function()
							if type(settings.Callback) == "function" then
								settings.Callback()
							end
						end,
					})
					return {}
				end

				function SectionFunctions:CreateInput(settings, id)
					local input = rfTab:CreateInput({
						Name = settings.Name or "Input",
						PlaceholderText = settings.Placeholder or "",
						CurrentValue = settings.Default or "",
						Callback = function(value)
							if type(settings.Callback) == "function" then
								settings.Callback(value)
							end
						end,
					})
					return {
						UpdateText = function(_, value)
							if input and type(input.Set) == "function" then
								pcall(input.Set, input, tostring(value or ""))
							end
						end,
						GetText = function()
							return settings.Default or ""
						end,
					}
				end

				function SectionFunctions:CreateDropdown(settings, id)
					local options = type(settings.Options) == "table" and settings.Options or {}
					local multi = settings.Multi == true or settings.MultipleOptions == true
					local current = settings.CurrentOption or settings.Default or (options[1] or "")
					local dropdown = rfTab:CreateDropdown({
						Name = settings.Name or "Dropdown",
						Options = options,
						CurrentOption = current,
						MultipleOptions = multi,
						Callback = function(option)
							if type(settings.Callback) == "function" then
								settings.Callback(option)
							end
						end,
					})
					return {
						Refresh = function(_, values)
							if type(values) ~= "table" then return end
							if dropdown and type(dropdown.Set) == "function" then
								pcall(dropdown.Set, dropdown, { Options = values })
							end
						end,
						SetValues = function(_, values)
							if type(values) ~= "table" then return end
							if dropdown and type(dropdown.Set) == "function" then
								pcall(dropdown.Set, dropdown, { Options = values })
							end
						end,
						SetValue = function(_, value)
							if dropdown and type(dropdown.Set) == "function" then
								pcall(dropdown.Set, dropdown, { CurrentOption = tostring(value) })
							end
						end,
						GetValue = function()
							return current
						end,
					}
				end

				function SectionFunctions:CreateKeybind(settings, id)
					local keyName = settings.Default and settings.Default.Name or "RightControl"
					local keybind = rfTab:CreateKeybind({
						Name = settings.Name or "Keybind",
						CurrentKeybind = keyName,
						Callback = function(key)
							if type(settings.Callback) == "function" then
								settings.Callback(key)
							end
						end,
					})
					return {
						SetKey = function(_, keyCode)
							if keybind and type(keybind.Set) == "function" then
								pcall(keybind.Set, keybind, tostring(keyCode and keyCode.Name or keyCode or "None"))
							end
						end,
					}
				end

				function SectionFunctions:CreateLabel(settings, id)
					rfTab:CreateLabel(tostring(settings.Text or settings.Name or ""))
					return {}
				end

				function SectionFunctions:CreateDivider()
					rfTab:CreateDivider()
					return {}
				end

				return SectionFunctions
			end

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
		if WindowFunctions._rfWindow then
			WindowFunctions._rfWindow:SetState(state ~= false)
		end
	end

	function WindowFunctions:GetState()
		return WindowFunctions.visible
	end

	function WindowFunctions:Unload()
		WindowFunctions.visible = false
		if WindowFunctions._rfWindow and type(WindowFunctions._rfWindow.Destroy) == "function" then
			pcall(WindowFunctions._rfWindow.Destroy, WindowFunctions._rfWindow)
		end
		for i, w in ipairs(windows) do
			if w == WindowFunctions then
				table.remove(windows, i)
				break
			end
		end
	end

	WindowFunctions._macTabGroup = WindowFunctions:TabGroup()
	return WindowFunctions
end

return MacLib
