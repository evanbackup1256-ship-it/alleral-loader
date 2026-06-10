local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local GuiService = game:GetService("GuiService")
local TweenService = game:GetService("TweenService")

local Util = require(script.Parent.util)
local Theme = require(script.Parent.theme)
local Tween = require(script.Parent.tween)
local Elements = require(script.Parent.elements)
local Notification = require(script.Parent.notification)

local WindowBuilder = {}
WindowBuilder._themeListeners = {}

function WindowBuilder.addThemeListener(callback)
	table.insert(WindowBuilder._themeListeners, callback)
end

function WindowBuilder.refreshTheme(root)
	local theme = Theme.current()
	for _, listener in ipairs(WindowBuilder._themeListeners) do
		listener(theme)
	end
	if root then
		root:SetAttribute("ThemeVersion", tick())
	end
end

local function parentGui(screenGui)
	if gethui then
		screenGui.Parent = gethui()
	elseif RunService:IsStudio() then
		screenGui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")
	else
		local coreGui = game:GetService("CoreGui")
		screenGui.Parent = coreGui:FindFirstChild("RobloxGui") or coreGui
	end
end

function WindowBuilder.create(library, windowSettings)
	windowSettings = windowSettings or {}
	windowSettings.NotifyOnCallbackError = windowSettings.NotifyOnCallbackError ~= false

	local player = Players.LocalPlayer
	local guiInset = GuiService:GetGuiInset()
	local theme = Theme.current()

	local screenGui = Util.new("ScreenGui", {
		Name = (getgenv and getgenv().InterfaceName) or windowSettings.Name or "Starlight Interface Suite",
		ResetOnSpawn = false,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		IgnoreGuiInset = true,
	})
	parentGui(screenGui)
	library.Instance = screenGui
	Notification.init(screenGui, library)

	local overlay = Util.new("Frame", {
		Name = "Overlay",
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
	}, { screenGui })

	local blur = Instance.new("BlurEffect")
	blur.Name = "StarlightBlur"
	blur.Size = Theme.Visual.BlurEnabled and Theme.Visual.BlurSize or 0
	blur.Parent = game:GetService("Lighting")

	local main = Util.new("Frame", {
		Name = "MainWindow",
		BackgroundColor3 = theme.Backgrounds.Medium,
		BackgroundTransparency = Theme.Visual.WindowTransparency,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = windowSettings.DefaultSize or UDim2.fromOffset(860, 520),
		Visible = false,
		ClipsDescendants = true,
	}, { overlay })
	main:SetAttribute("TargetTransparency", Theme.Visual.WindowTransparency)
	Util.corner(Theme.Visual.GroupboxRadius + 4, main)
	if Theme.Visual.ShowShadows then
		Util.stroke(theme.Miscellaneous.Divider, 1, 0.5, main)
	end

	local sidebar = Util.new("Frame", {
		Name = "Sidebar",
		BackgroundColor3 = theme.Backgrounds.Dark,
		BackgroundTransparency = 0.05,
		Size = UDim2.new(0, Theme.Visual.SidebarWidth, 1, 0),
	}, { main })
	Util.padding(16, 14, 16, 14, sidebar)
	Util.list(12, false, sidebar)

	local brand = Util.new("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 52),
	}, { sidebar })
	Util.list(4, false, brand)

	if not Util.isEmpty(windowSettings.Icon) then
		Util.new("ImageLabel", {
			BackgroundTransparency = 1,
			Image = Util.iconAsset(windowSettings.Icon),
			Size = UDim2.fromOffset(28, 28),
			ImageColor3 = theme.Accent,
		}, { brand })
	end

	Util.text({
		Parent = brand,
		Text = windowSettings.Name or "Starlight",
		Font = Enum.Font.GothamBold,
		TextSize = 18 * Theme.Visual.FontScale,
		TextColor3 = theme.Foregrounds.Light,
	})
	Util.text({
		Parent = brand,
		Text = windowSettings.Subtitle or "Alleral Interface",
		TextSize = 12 * Theme.Visual.FontScale,
		TextColor3 = theme.Foregrounds.Medium,
	})

	local navHolder = Util.new("ScrollingFrame", {
		Name = "Navigation",
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 1, -120),
		CanvasSize = UDim2.new(),
		ScrollBarThickness = 0,
	}, { sidebar })
	Util.list(8, false, navHolder)

	local content = Util.new("Frame", {
		Name = "Content",
		BackgroundTransparency = 1,
		Position = UDim2.new(0, Theme.Visual.SidebarWidth, 0, 0),
		Size = UDim2.new(1, -Theme.Visual.SidebarWidth, 1, 0),
	}, { main })

	local topBar = Util.new("Frame", {
		Name = "TopBar",
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 44),
	}, { content })
	Util.padding(0, 16, 0, 16, topBar)

	local titleLabel = Util.text({
		Parent = topBar,
		Text = "Dashboard",
		Font = Enum.Font.GothamBold,
		TextSize = 18 * Theme.Visual.FontScale,
		TextColor3 = theme.Foregrounds.Light,
		Size = UDim2.new(1, -120, 1, 0),
	})

	local controls = Util.new("Frame", {
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, 0, 0.5, 0),
		Size = UDim2.fromOffset(96, 28),
	}, { topBar })
	Util.list(8, true, controls)

	local function controlButton(text, color)
		local btn = Util.button({
			Parent = controls,
			Size = UDim2.fromOffset(28, 28),
			BackgroundColor3 = theme.Backgrounds.Highlight,
			Radius = 8,
		})
		Util.text({
			Parent = btn,
			Text = text,
			TextXAlignment = Enum.TextXAlignment.Center,
			TextSize = 16,
			TextColor3 = color or theme.Foregrounds.Light,
			Size = UDim2.fromScale(1, 1),
		})
		return btn
	end

	local minimizeBtn = controlButton("—")
	local closeBtn = controlButton("×", theme.Miscellaneous.Danger)

	local pages = Util.new("Frame", {
		Name = "Pages",
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 0, 0, 44),
		Size = UDim2.new(1, 0, 1, -44),
	}, { content })

	local window = {
		Settings = windowSettings,
		TabSections = {},
		CurrentTab = nil,
		Instance = main,
		Visible = false,
	}

	local dragging = false
	local dragInput
	local dragStart
	local startPos

	topBar.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			dragStart = input.Position
			startPos = main.Position
		end
	end)
	topBar.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = false
		end
	end)
	UserInputService.InputChanged:Connect(function(input)
		if dragging and input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
			local delta = input.Position - dragStart
			main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
		end
	end)

	local function setVisible(state)
		window.Visible = state
		main.Visible = state
		blur.Enabled = state and Theme.Visual.BlurEnabled
		if state then
			main.BackgroundTransparency = 1
			Tween.play(main, { BackgroundTransparency = Theme.Visual.WindowTransparency }, nil, Theme.tweenInfo(0.22))
		end
	end

	closeBtn.MouseButton1Click:Connect(function()
		setVisible(false)
	end)
	minimizeBtn.MouseButton1Click:Connect(function()
		setVisible(false)
	end)

	library.Minimized = false
	library.Window = window

	function window:Toggle()
		setVisible(not self.Visible)
	end

	function window:Destroy()
		screenGui:Destroy()
		blur:Destroy()
	end

	function window:CreateTabSection(name, expanded)
		local section = {
			Name = name,
			Tabs = {},
			Expanded = expanded ~= false,
		}

		local sectionFrame = Util.new("Frame", {
			Name = name,
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
		}, { navHolder })
		Util.list(4, false, sectionFrame)

		if name and name ~= "" then
			Util.text({
				Parent = sectionFrame,
				Text = string.upper(name),
				TextSize = 11 * Theme.Visual.FontScale,
				TextColor3 = theme.Foregrounds.Dark,
				Size = UDim2.new(1, 0, 0, 16),
			})
		end

		local tabsFrame = Util.new("Frame", {
			Name = "Tabs",
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
		}, { sectionFrame })

		function section:CreateTab(tabSettings, tabIndex)
			tabSettings = tabSettings or {}
			tabIndex = tabIndex or tostring(#self.Tabs + 1)
			local tab = {
				Index = tabIndex,
				Values = tabSettings,
				Groupboxes = {},
				Active = false,
			}

			local navButton = Util.button({
				Parent = tabsFrame,
				BackgroundColor3 = theme.Backgrounds.Highlight,
				BackgroundTransparency = 1,
				Size = UDim2.new(1, 0, 0, 36),
				Radius = 10,
			})

			local navRow = Util.new("Frame", {
				BackgroundTransparency = 1,
				Size = UDim2.fromScale(1, 1),
			}, { navButton })
			Util.list(10, true, navRow)
			Util.padding(0, 10, 0, 10, navRow)

			if not Util.isEmpty(tabSettings.Icon) then
				Util.new("ImageLabel", {
					BackgroundTransparency = 1,
					Image = Util.iconAsset(tabSettings.Icon),
					Size = UDim2.fromOffset(16, 16),
					ImageColor3 = theme.Foregrounds.Medium,
				}, { navRow })
			end

			local navLabel = Util.text({
				Parent = navRow,
				Text = tabSettings.Name or tabIndex,
				TextSize = 14 * Theme.Visual.FontScale,
				TextColor3 = theme.Foregrounds.Medium,
				Size = UDim2.new(1, 0, 1, 0),
			})

			local page = Util.new("ScrollingFrame", {
				Name = tabIndex,
				BackgroundTransparency = 1,
				Size = UDim2.fromScale(1, 1),
				CanvasSize = UDim2.new(),
				ScrollBarThickness = 4,
				Visible = false,
			}, { pages })
			Util.padding(16, 16, 16, 16, page)

			local columns = tabSettings.Columns or 2
			local columnsFrame = Util.new("Frame", {
				Name = "Columns",
				BackgroundTransparency = 1,
				Size = UDim2.new(1, 0, 0, 0),
				AutomaticSize = Enum.AutomaticSize.Y,
			}, { page })
			Util.list(14, true, columnsFrame)

			local columnFrames = {}
			for i = 1, columns do
				columnFrames[i] = Util.new("Frame", {
					Name = "Column" .. i,
					BackgroundTransparency = 1,
					Size = UDim2.new(1 / columns, -8, 0, 0),
					AutomaticSize = Enum.AutomaticSize.Y,
				}, { columnsFrame })
				Util.list(12, false, columnFrames[i])
			end

			local function activate()
				for _, other in pairs(self.Tabs) do
					other.Active = false
					if other.Page then
						other.Page.Visible = false
					end
					if other.NavButton then
						Tween.play(other.NavButton, { BackgroundTransparency = 1 })
						if other.NavLabel then
							Tween.play(other.NavLabel, { TextColor3 = theme.Foregrounds.Medium })
						end
					end
				end
				tab.Active = true
				tab.Page.Visible = true
				titleLabel.Text = tabSettings.Name or tabIndex
				Tween.play(navButton, { BackgroundTransparency = 0.35 })
				Tween.play(navLabel, { TextColor3 = theme.Foregrounds.Light })
				window.CurrentTab = tab
			end

			tab.Page = page
			tab.NavButton = navButton
			tab.NavLabel = navLabel
			navButton.MouseButton1Click:Connect(activate)
			self.Tabs[tabIndex] = tab
			table.insert(self.Tabs, tab)

			if not window.CurrentTab then
				task.defer(activate)
			end

			function tab:CreateGroupbox(groupSettings, groupIndex)
				groupSettings = groupSettings or {}
				groupIndex = groupIndex or tostring(#self.Groupboxes + 1)
				local column = groupSettings.Column or 1
				local holder = columnFrames[column] or columnFrames[1]

				local groupbox = {
					Index = groupIndex,
					Values = groupSettings,
					Elements = {},
				}

				local box = Util.new("Frame", {
					Name = groupIndex,
					BackgroundColor3 = theme.Backgrounds.Groupbox,
					BackgroundTransparency = Theme.Visual.GroupboxTransparency,
					Size = UDim2.new(1, 0, 0, 0),
					AutomaticSize = Enum.AutomaticSize.Y,
				}, { holder })
				Util.corner(Theme.Visual.GroupboxRadius, box)
				if Theme.Visual.ShowShadows then
					Util.stroke(theme.Miscellaneous.Divider, 1, 0.55, box)
				end
				Util.padding(12, 12, 12, 12, box)
				Util.list(8, false, box)

				local header = Util.new("Frame", {
					BackgroundTransparency = 1,
					Size = UDim2.new(1, 0, 0, 22),
				}, { box })
				Util.list(8, true, header)

				if not Util.isEmpty(groupSettings.Icon) then
					Util.new("ImageLabel", {
						BackgroundTransparency = 1,
						Image = Util.iconAsset(groupSettings.Icon),
						Size = UDim2.fromOffset(16, 16),
						ImageColor3 = theme.Accent,
					}, { header })
				end

				Util.text({
					Parent = header,
					Text = groupSettings.Name or groupIndex,
					Font = Enum.Font.GothamBold,
					TextSize = 14 * Theme.Visual.FontScale,
					TextColor3 = theme.Foregrounds.Light,
					Size = UDim2.new(1, 0, 1, 0),
				})

				local parentingItem = Util.new("Frame", {
					Name = "Elements",
					BackgroundTransparency = 1,
					Size = UDim2.new(1, 0, 0, 0),
					AutomaticSize = Enum.AutomaticSize.Y,
				}, { box })
				Util.list(6, false, parentingItem)

				groupbox.Instance = box
				groupbox.ParentingItem = parentingItem
				self.Groupboxes[groupIndex] = groupbox

				function groupbox:CreateToggle(s, i)
					return Elements.createToggle(self, s, i, windowSettings)
				end
				function groupbox:CreateSlider(s, i)
					return Elements.createSlider(self, s, i, windowSettings)
				end
				function groupbox:CreateButton(s, i)
					return Elements.createButton(self, s, i, windowSettings)
				end
				function groupbox:CreateInput(s, i)
					return Elements.createInput(self, s, i, windowSettings)
				end
				function groupbox:CreateLabel(s, i)
					return Elements.createLabel(self, s, i, windowSettings)
				end
				function groupbox:CreateDivider()
					return Elements.createDivider(self)
				end
				function groupbox:CreateParagraph(s, i)
					return Elements.createParagraph(self, s, i)
				end
				function groupbox:CreateDropdown(s, i)
					return Elements.createDropdown(self, s, i, windowSettings)
				end
				function groupbox:Set(newSettings)
					self.Values = Util.merge(self.Values, newSettings)
				end
				function groupbox:Destroy()
					box:Destroy()
				end

				return groupbox
			end

			function tab:BuildThemeGroupbox(column, style, buttonsCentered)
				local groupbox = self:CreateGroupbox({ Name = "Appearance", Column = column or 1 }, "Theme")
				local themeGroup = {
					CreateToggle = function(_, ...) return groupbox:CreateToggle(...) end,
					CreateSlider = function(_, ...) return groupbox:CreateSlider(...) end,
					CreateDropdown = function(_, ...) return groupbox:CreateDropdown(...) end,
					CreateButton = function(_, ...) return groupbox:CreateButton(...) end,
					CreateLabel = function(_, text)
						return groupbox:CreateLabel({ Name = text })
					end,
				}

				groupbox:CreateDropdown({
					Name = "Theme preset",
					Options = { "Starlight", "Midnight", "Aurora", "Rose" },
					CurrentOption = Theme.Visual.ThemeName,
					Callback = function(selected)
						Theme.setTheme(selected)
						WindowBuilder.refreshTheme(main)
						library:Notification({ Title = "Theme", Content = "Applied " .. selected .. " theme.", Duration = 2 })
					end,
				}, "ThemePreset")

				groupbox:CreateSlider({
					Name = "Corner radius",
					Range = { 4, 18 },
					Increment = 1,
					CurrentValue = Theme.Visual.CornerRadius,
					Callback = function(value)
						Theme.Visual.CornerRadius = value
						Theme.Visual.GroupboxRadius = value + 2
					end,
				}, "CornerRadius")

				groupbox:CreateSlider({
					Name = "Animation speed",
					Range = { 0.5, 2 },
					Increment = 0.1,
					CurrentValue = Theme.Visual.AnimationSpeed,
					Callback = function(value)
						Theme.Visual.AnimationSpeed = value
					end,
				}, "AnimSpeed")

				groupbox:CreateToggle({
					Name = "Background blur",
					CurrentValue = Theme.Visual.BlurEnabled,
					Callback = function(value)
						Theme.Visual.BlurEnabled = value
						blur.Enabled = value and window.Visible
					end,
				}, "Blur")

				groupbox:CreateToggle({
					Name = "Compact layout",
					CurrentValue = Theme.Visual.CompactMode,
					Callback = function(value)
						Theme.Visual.CompactMode = value
					end,
				}, "Compact")

				groupbox:CreateToggle({
					Name = "Soft shadows",
					CurrentValue = Theme.Visual.ShowShadows,
					Callback = function(value)
						Theme.Visual.ShowShadows = value
					end,
				}, "Shadows")

				return themeGroup
			end

			function tab:BuildConfigGroupbox(column, style, buttonsCentered)
				local groupbox = self:CreateGroupbox({ Name = "Configuration", Column = column or 1 }, "Config")
				local configName = "default"
				local nameInput = groupbox:CreateInput({
					Name = "Config name",
					Placeholder = "default",
					CurrentValue = configName,
					Callback = function(value)
						configName = Util.trim(value) ~= "" and Util.trim(value) or "default"
					end,
				}, "ConfigName")

				groupbox:CreateButton({
					Name = "Save config",
					Callback = function()
						library.FileSystem:SaveConfig(configName)
						library:Notification({ Title = "Saved", Content = "Config '" .. configName .. "' saved.", Duration = 3 })
					end,
				}, "SaveConfig")

				groupbox:CreateButton({
					Name = "Load config",
					Callback = function()
						local ok = library.FileSystem:LoadConfig(configName)
						library:Notification({
							Title = ok and "Loaded" or "Failed",
							Content = ok and ("Config '" .. configName .. "' loaded.") or "Could not load config.",
							Duration = 3,
						})
					end,
				}, "LoadConfig")

				return groupbox
			end

			function tab:Set(newSettings)
				tab.Values = Util.merge(tab.Values, newSettings)
				navLabel.Text = tab.Values.Name or tabIndex
			end
			function tab:Destroy()
				page:Destroy()
				navButton:Destroy()
			end

			return tab
		end

		function section:Set(newName)
			self.Name = newName
		end
		function section:Destroy()
			sectionFrame:Destroy()
		end

		window.TabSections[name] = section
		return section
	end

	local keybind = library.WindowKeybind or "K"
	UserInputService.InputBegan:Connect(function(input, processed)
		if processed then
			return
		end
		if input.KeyCode == Enum.KeyCode[keybind] then
			window:Toggle()
		end
	end)

	if windowSettings.LoadingEnabled ~= false then
		task.defer(function()
			task.wait(0.15)
			setVisible(true)
		end)
	else
		setVisible(true)
	end

	library.OnDestroy = function()
		window:Destroy()
	end

	return window
end

return WindowBuilder
