-- Alleral V12 — WindUI window (manager-driven lifecycle)
return function(WindUI, Bootstrap, Controls, Notifications, Theme, WindowManager, ValidationManager, TabManager, _TooltipManager, Cache, Patch)
	local WindowMod = {}

	local STATES = {
		Hidden = "Hidden",
		Showing = "Showing",
		Visible = "Visible",
		Hiding = "Hiding",
	}

	function WindowMod.create(settings, state)
		settings = type(settings) == "table" and settings or {}
		state = state or {}

		local gameId = tostring(settings.GameId or state.gameId or Bootstrap.resolveGameId() or "unsupported")
		state.gameId = gameId
		if Cache then
			Cache.setGame(gameId)
		end

		local title = Bootstrap.sanitize(settings.Title or settings.Name or "Alleral", 64)
		local keybind = settings.Keybind or Enum.KeyCode.RightShift
		local folder = settings.ConfigFolder or settings.Folder or Bootstrap.configFolder()
		if type(folder) ~= "string" or folder == "" then
			folder = "Alleral_" .. gameId:gsub("[^%w_%-]", "_")
		end
		folder = folder:gsub("[^%w_%-/]", "_")
		if folder == "" then
			folder = "Alleral"
		end

		local tabIcon = Theme and Theme.cyan and Theme.cyan() or Color3.fromHex("#22D3EE")

		local windowConfig = {
			Title = title,
			Author = Bootstrap.sanitize(settings.Author or "Alleral", 48),
			Icon = settings.Icon or "sparkles",
			Folder = folder,
			Theme = Theme and Theme.NAME or "Dark",
			NewElements = true,
			HideSearchBar = false,
			Transparent = false,
			Acrylic = false,
			Size = settings.Size or UDim2.fromOffset(1080, 620),
			OpenButton = { Enabled = false },
			Topbar = {
				Height = 48,
				ButtonsType = "Mac",
			},
			SideBarWidth = settings.SideBarWidth or 228,
		}
		if type(windowConfig) ~= "table" then
			error("[WindUI] windowConfig missing")
		end
		windowConfig.Folder = windowConfig.Folder or "Alleral"

		local windWindow
		local ok, err = pcall(function()
			windWindow = WindUI:CreateWindow(windowConfig)
		end)
		if not ok or not windWindow then
			error("WindUI CreateWindow failed: " .. tostring(err))
		end

		local self
		local function bindWindPatches()
			if Patch and Patch.applyWindow then
				pcall(Patch.applyWindow, windWindow, {
					onHide = function()
						if self then
							self:Hide()
						end
					end,
					onToggle = function()
						if self then
							self:Toggle()
						end
					end,
				})
			end
		end

		self = {
			_wind = windWindow,
			_windUI = WindUI,
			_tabs = {},
			_activeTab = nil,
			_keybind = keybind,
			_settings = settings,
			_gameId = gameId,
			_validated = false,
			_built = true,
			_windowState = STATES.Hidden,
			_lastOpen = 0,
			_lastClose = 0,
		}

		local function setRootVisible(show)
			pcall(function()
				if self._wind.SetVisible then
					self._wind:SetVisible(show)
				end
				local root = self._wind.UIElements and self._wind.UIElements.Main
				if typeof(root) == "Instance" then
					root.Visible = show
				end
				if self._wind then
					self._wind.Closed = not show
				end
			end)
		end

		function self:SetTheme(name)
			pcall(function()
				if WindUI.SetTheme then
					WindUI:SetTheme(Bootstrap.sanitize(name, 32))
				end
			end)
		end

		function self:GetWindowState()
			return self._windowState
		end

		function self:Hide()
			if self._windowState == STATES.Hidden or self._windowState == STATES.Hiding then
				return
			end
			if self._windowState == STATES.Showing then
				return
			end
			self._windowState = STATES.Hiding
			self._lastClose = tick()
			if WindowManager and WindowManager.hide then
				WindowManager.hide(self._windUI, self._wind, function()
					pcall(function()
						if self._wind then
							self._wind.Closed = true
						end
					end)
					self._windowState = STATES.Hidden
				end)
			else
				setRootVisible(false)
				self._windowState = STATES.Hidden
			end
		end

		function self:Show()
			if self._windowState == STATES.Visible or self._windowState == STATES.Showing then
				return
			end
			if self._windowState == STATES.Hiding then
				return
			end
			self._windowState = STATES.Showing
			self._lastOpen = tick()
			pcall(function()
				if self._wind then
					self._wind.Closed = false
				end
			end)
			if WindowManager and WindowManager.show then
				WindowManager.show(self._windUI, self._wind, function()
					self._windowState = STATES.Visible
				end)
			else
				setRootVisible(true)
				self._windowState = STATES.Visible
			end
		end

		function self:Toggle()
			if self._windowState == STATES.Showing or self._windowState == STATES.Hiding then
				return
			end
			if self._windowState == STATES.Visible then
				self:Hide()
			else
				self:Show()
			end
		end

		function self:selectTab(tab)
			if self._activeTab == tab then
				return
			end
			self._activeTab = tab
			pcall(function()
				if tab and tab._windTab and tab._windTab.Select then
					tab._windTab:Select()
				end
			end)
		end

		function self:AddTab(name, iconId, _columns)
			name = Bootstrap.sanitize(name, 48)
			if name == "" then
				return nil
			end
			local icon = Bootstrap.mapIcon(iconId)

			local windTab
			pcall(function()
				windTab = self._wind:Tab({
					Title = name,
					Icon = icon,
					IconColor = tabIcon,
					Border = true,
					Desc = "",
				})
			end)
			if not windTab then
				return nil
			end

			local tab = {
				_windTab = windTab,
				_window = self,
				_name = name,
				Select = function(t)
					self:selectTab(t or tab)
				end,
			}

			function tab:AddLeftGroupbox(groupName)
				state.groupCount = (state.groupCount or 0) + 1
				return Controls.createGroup(windTab, groupName)
			end
			tab.AddRightGroupbox = tab.AddLeftGroupbox
			tab.AddGroupbox = tab.AddLeftGroupbox

			table.insert(self._tabs, tab)
			state.tabCount = (state.tabCount or 0) + 1
			if Cache then
				Cache.trackTab(self._gameId, tab)
			end
			if TabManager and TabManager.onTabAdded then
				pcall(TabManager.onTabAdded, self, tab)
			end

			if #self._tabs == 1 then
				task.defer(function()
					self:selectTab(tab)
				end)
			end

			return tab
		end

		function self:Notify(payload)
			payload = type(payload) == "table" and payload or { Description = payload }
			return Notifications.push(
				WindUI,
				payload.Title or payload.Name or "Alleral",
				payload.Description or payload.Content or payload.Text or "",
				payload.Type or "info",
				payload.Duration or payload.Lifetime or 4
			)
		end

		function self:Unload()
			if WindowManager and WindowManager.teardown then
				pcall(WindowManager.teardown, self._wind)
			end
			if self._toggleConn then
				pcall(function() self._toggleConn:Disconnect() end)
				self._toggleConn = nil
			end
			pcall(function()
				if self._wind.Destroy then
					self._wind:Destroy()
				end
			end)
			self._windowState = STATES.Hidden
		end

		function self:Destroy()
			self:Unload()
		end

		function self:Validate()
			if self._validated then
				return true
			end
			local passed = true
			if ValidationManager and ValidationManager.run then
				passed = select(1, ValidationManager.run(self, state))
			elseif #self._tabs < 1 or (state.controls or 0) < 1 then
				passed = false
			end
			if passed then
				Bootstrap.runValidation(state)
				self._validated = true
			end
			return passed
		end

		bindWindPatches()

		local UIS = game:GetService("UserInputService")
		if not self._toggleConn then
			self._toggleConn = UIS.InputBegan:Connect(function(input, processed)
				if processed then
					return
				end
				if input.UserInputType ~= Enum.UserInputType.Keyboard then
					return
				end
				if input.KeyCode ~= keybind then
					return
				end
				self:Toggle()
			end)
		end

		if WindowManager and WindowManager.setup then
			pcall(WindowManager.setup, windWindow, { gameId = gameId })
		end

		if Cache then
			Cache.setWindow(gameId, self)
		end

		setRootVisible(false)
		return self
	end

	return WindowMod
end