return function(deps)
	local Utils = deps.Utils
	local Motion = deps.Motion
	local Theme = deps.Theme
	local Maid = deps.Maid
	local Page = deps.Page
	local Navigation = deps.Navigation
	local Notification = deps.Notification
	local Modal = deps.Modal
	local CommandPalette = deps.CommandPalette

	return function(library, opts)
		opts = opts or {}
		local theme = Theme.get(opts.Theme or "Private")
		local maid = Maid.new()
		local size = opts.Size or UDim2.fromOffset(860, 580)

		local window = {
			IsOpen = true,
			_pages = {},
			_theme = theme,
			_maid = maid,
		}

		local root = library.EnsureGuiRoot()
		local shell = Utils.new("Frame", {
			Name = "AlleralWindow",
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundColor3 = theme.Canvas,
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			Position = UDim2.fromScale(0.5, 0.54),
			Size = size,
			ClipsDescendants = true,
			Parent = root,
		})
		Utils.corner(shell, theme.CornerLg)
		Utils.stroke(shell, theme.Border, 1, theme.BorderAlpha or 0.9)
		Utils.acrylicLayer(shell, theme, theme.CornerLg)
		Utils.gradient(shell, { theme.Canvas, theme.Surface }, 145)
		Utils.noiseOverlay(shell, 0.94)

		local topGlow = Utils.neonGlow(shell, theme, { transparency = 0.9, expand = 0, radius = theme.CornerLg })
		topGlow.Size = UDim2.new(0.6, 0, 0, 2)
		topGlow.AnchorPoint = Vector2.new(0.5, 0)
		topGlow.Position = UDim2.new(0.5, 0, 0, 1)

		local bottomGlow = Utils.neonGlow(shell, theme, { transparency = 0.93, expand = 0, radius = 0 })
		bottomGlow.Size = UDim2.new(0.4, 0, 0, 1)
		bottomGlow.AnchorPoint = Vector2.new(0.5, 1)
		bottomGlow.Position = UDim2.new(0.5, 0, 1, -1)

		local topbar = Utils.new("Frame", {
			Name = "Topbar",
			BackgroundTransparency = 1,
			Position = UDim2.fromOffset(theme.SidebarWidth, 0),
			Size = UDim2.new(1, -theme.SidebarWidth, 0, theme.TopbarHeight),
			Parent = shell,
		})
		Utils.new("TextLabel", {
			BackgroundTransparency = 1,
			Font = theme.FontBold,
			Text = opts.Title or opts.Name or "Alleral",
			TextColor3 = theme.Text,
			TextSize = 14,
			Position = UDim2.fromOffset(12, 10),
			Size = UDim2.new(0.55, 0, 0, 18),
			TextXAlignment = Enum.TextXAlignment.Left,
			Parent = topbar,
		})
		if opts.Subtitle or opts.SubName then
			Utils.new("TextLabel", {
				BackgroundTransparency = 1,
				Font = theme.Font,
				Text = opts.Subtitle or opts.SubName or "",
				TextColor3 = theme.Muted,
				TextSize = 10,
				Position = UDim2.fromOffset(12, 26),
				Size = UDim2.new(0.55, 0, 0, 12),
				TextXAlignment = Enum.TextXAlignment.Left,
				TextTruncate = Enum.TextTruncate.AtEnd,
				Parent = topbar,
			})
		end

		local content = Utils.new("Frame", {
			Name = "Content",
			BackgroundTransparency = 1,
			ClipsDescendants = true,
			Position = UDim2.fromOffset(theme.SidebarWidth, theme.TopbarHeight),
			Size = UDim2.new(1, -theme.SidebarWidth, 1, -theme.TopbarHeight),
			Parent = shell,
		})

		local windowCtx = {
			shell = shell,
			content = content,
			theme = theme,
			config = library.Config,
			title = opts.Title or opts.Name,
			subtitle = opts.Subtitle or opts.SubName,
			root = root,
		}

		local nav = Navigation(windowCtx)
		window._nav = nav
		window._shell = shell
		window._root = root
		window._content = content

		Motion.to(shell, {
			BackgroundTransparency = opts.Acrylic ~= false and 0.03 or 0.01,
			Position = UDim2.fromScale(0.5, 0.5),
		}, "open")

		shell.InputChanged:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseMovement then
				Motion.cursorGlow(shell, theme, input)
			end
		end)

		function window:CreatePage(o)
			local page = Page(windowCtx, o)
			table.insert(window._pages, page)
			nav:AddItem(page, function(p)
				nav:SetActive(p)
			end)
			if #window._pages == 1 then
				nav:SetActive(page)
			end
			return page
		end

		function window:AddTab(name, icon)
			return window:CreatePage({ Name = name, Icon = icon, Columns = 2 })
		end

		function window:Page(o)
			return window:CreatePage(o)
		end

		function window:Notify(data)
			Notification.push(root, data, theme)
		end

		function window:Modal(data)
			return Modal.open(root, data, theme)
		end

		function window:CommandPalette()
			CommandPalette.toggle(root, theme)
		end

		function window:SetOpen(open)
			self.IsOpen = open ~= false
			Motion.to(shell, {
				Position = self.IsOpen and UDim2.fromScale(0.5, 0.5) or UDim2.fromScale(0.5, 0.56),
				BackgroundTransparency = self.IsOpen and 0.03 or 1,
			}, self.IsOpen and "open" or "close")
		end

		function window:Toggle()
			self:SetOpen(not self.IsOpen)
		end

		function window:Init() end

		function window:Destroy()
			if library._windows then
				for i, entry in ipairs(library._windows) do
					if entry == window then
						table.remove(library._windows, i)
						break
					end
				end
			end
			Motion.to(shell, { BackgroundTransparency = 1, Position = UDim2.fromScale(0.5, 0.56) }, "close", function()
				maid:Destroy()
				Notification.destroy()
			end)
		end

		function window:SetTheme(name)
			Theme.applyPreset(theme, name)
			window._theme = theme
			windowCtx.theme = theme
			Theme.repaint(shell, theme)
			if nav and nav._active and nav.SetActive then
				nav:SetActive(nav._active)
			end
		end

		window.Instance = shell
		window.Holder = { Instance = root }
		library._windows = library._windows or {}
		table.insert(library._windows, window)
		return window
	end
end
