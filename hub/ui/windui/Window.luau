-- Alleral V11.2 — WindUI window (cached show/hide, drag, tooltips)
return function(WindUI, Bootstrap, Controls, Notifications, Theme, Motion, Validate, Drag, TooltipManager, Cache)
	local WindowMod = {}

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
		local folder = settings.ConfigFolder or Bootstrap.configFolder()

		if Theme and Theme.register then
			pcall(Theme.register)
		end

		local windWindow
		local ok, err = pcall(function()
			windWindow = WindUI:CreateWindow({
				Title = title,
				Folder = folder,
				Icon = "sparkles",
				Theme = Theme and Theme.NAME or "Violet",
				NewElements = true,
				HideSearchBar = false,
				Transparent = true,
				Acrylic = true,
				Size = settings.Size or UDim2.fromOffset(1180, 700),
				OpenButton = { Enabled = false },
				Topbar = {
					Height = 44,
					ButtonsType = "Mac",
				},
				SideBarWidth = 232,
			})
		end)
		if not ok or not windWindow then
			error("WindUI CreateWindow failed: " .. tostring(err))
		end

		pcall(function()
			if windWindow.SetToggleKey and typeof(keybind) == "EnumItem" then
				windWindow:SetToggleKey(keybind)
			end
		end)

		if Theme then
			pcall(function() Theme.applyToWindow(windWindow) end)
		end
		if Drag then
			pcall(function() Drag.bind(windWindow) end)
		end
		if TooltipManager and TooltipManager.init then
			pcall(TooltipManager.init)
		end

		local self = {
			_wind = windWindow,
			_windUI = WindUI,
			_tabs = {},
			_activeTab = nil,
			_hidden = true,
			_keybind = keybind,
			_settings = settings,
			_gameId = gameId,
			_validated = false,
			_built = true,
			_openedOnce = false,
		}

		function self:SetTheme(name)
			pcall(function()
				if WindUI.SetTheme then
					WindUI:SetTheme(Bootstrap.sanitize(name, 32))
				end
			end)
		end

		function self:_setVisible(show)
			pcall(function()
				if self._wind.SetVisible then
					self._wind:SetVisible(show)
				elseif show and self._wind.Open then
					self._wind:Open()
				elseif not show and self._wind.Close then
					self._wind:Close()
				elseif show and self._wind.Show then
					self._wind:Show()
				elseif not show and self._wind.Hide then
					self._wind:Hide()
				end
			end)
		end

		function self:Hide()
			self._hidden = true
			self:_setVisible(false)
		end

		function self:Show()
			self._hidden = false
			self:_setVisible(true)
			if not self._openedOnce then
				self._openedOnce = true
				if Motion then
					pcall(function() Motion.openWindow(WindUI, true) end)
				end
			end
		end

		function self:Toggle()
			if self._hidden then
				self:Show()
			else
				self:Hide()
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
					IconColor = Color3.fromHex("#8B5CF6"),
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
			if Drag and Drag.cleanup then
				pcall(Drag.cleanup)
			end
			if Motion and Motion.cleanup then
				pcall(Motion.cleanup)
			end
			if TooltipManager and TooltipManager.hide then
				pcall(TooltipManager.hide)
			end
			pcall(function()
				if self._wind.Destroy then
					self._wind:Destroy()
				end
			end)
		end

		function self:Destroy()
			self:Unload()
		end

		function self:Validate()
			if self._validated then
				return true
			end
			local passed = true
			if Validate and Validate.run then
				passed = select(1, Validate.run(self, state))
			elseif #self._tabs < 1 or (state.controls or 0) < 1 then
				passed = false
			end
			if passed then
				Bootstrap.runValidation(state)
				self._validated = true
			end
			return passed
		end

		pcall(function()
			if self._wind.OnClose then
				self._wind:OnClose(function()
					self:Hide()
					return false
				end)
			end
		end)

		if Cache then
			Cache.setWindow(gameId, self)
		end

		self:Hide()
		return self
	end

	return WindowMod
end