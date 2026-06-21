-- Alleral V11 — WindUI window shell (premium layout)
return function(WindUI, Bootstrap, Controls, Notifications, Theme, Motion)
	local WindowMod = {}

	function WindowMod.create(settings, state)
		settings = type(settings) == "table" and settings or {}
		state = state or {}

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
				Size = settings.Size or UDim2.fromOffset(1200, 740),
				OpenButton = { Enabled = false },
				Topbar = {
					Height = 48,
					ButtonsType = "Mac",
				},
				SideBarWidth = 244,
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
		if Motion then
			pcall(function() Motion.openWindow(WindUI) end)
		end
		pcall(function()
			if WindUI.ToggleAcrylic then WindUI:ToggleAcrylic(true) end
		end)

		local self = {
			_wind = windWindow,
			_windUI = WindUI,
			_tabs = {},
			_activeTab = nil,
			_hidden = false,
			_keybind = keybind,
			_settings = settings,
			_gameId = Bootstrap.resolveGameId(),
		}

		function self:SetTheme(name)
			pcall(function()
				if WindUI.SetTheme then
					WindUI:SetTheme(Bootstrap.sanitize(name, 32))
				end
			end)
		end

		function self:Hide()
			self._hidden = true
			pcall(function()
				if self._wind.Close then
					self._wind:Close()
				elseif self._wind.Hide then
					self._wind:Hide()
				elseif self._wind.SetVisible then
					self._wind:SetVisible(false)
				end
			end)
		end

		function self:Show()
			self._hidden = false
			pcall(function()
				if self._wind.Open then
					self._wind:Open()
				elseif self._wind.Show then
					self._wind:Show()
				elseif self._wind.SetVisible then
					self._wind:SetVisible(true)
				end
			end)
			if Motion then
				pcall(function() Motion.openWindow(WindUI) end)
			end
		end

		function self:Toggle()
			if self._hidden then self:Show() else self:Hide() end
		end

		function self:selectTab(tab)
			if self._activeTab == tab then return end
			self._activeTab = tab
			pcall(function()
				if tab and tab._windTab and tab._windTab.Select then
					tab._windTab:Select()
				end
			end)
		end

		function self:AddTab(name, iconId, _columns)
			name = Bootstrap.sanitize(name, 48)
			local icon = Bootstrap.mapIcon(iconId)

			local windTab
			pcall(function()
				windTab = self._wind:Tab({
					Title = name,
					Icon = icon,
					IconColor = Color3.fromHex("#8B5CF6"),
					Border = true,
					Desc = "",
					FontWeight = "Medium",
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
				return Controls.createGroup(windTab, groupName)
			end
			tab.AddRightGroupbox = tab.AddLeftGroupbox
			tab.AddGroupbox = tab.AddLeftGroupbox

			table.insert(self._tabs, tab)
			state.tabCount = (state.tabCount or 0) + 1

			if #self._tabs == 1 then
				task.defer(function() self:selectTab(tab) end)
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
			Bootstrap.runValidation(self._gameId, #self._tabs)
			return #self._tabs > 0
		end

		pcall(function()
			if self._wind.OnClose then
				self._wind:OnClose(function()
					self:Hide()
					return false
				end)
			end
		end)

		return self
	end

	return WindowMod
end