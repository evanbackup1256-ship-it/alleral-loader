return function(deps)
	local Utils = deps.Utils
	local Motion = deps.Motion
	local Icons = deps.Icons

	return function(windowCtx)
		local theme = windowCtx.theme
		local nav = { _items = {}, _active = nil }

		local sidebar = Utils.new("Frame", {
			Name = "Sidebar",
			BackgroundColor3 = theme.Surface,
			BackgroundTransparency = 0.04,
			BorderSizePixel = 0,
			Size = UDim2.new(0, theme.SidebarWidth, 1, 0),
			ZIndex = 2,
			Parent = windowCtx.shell,
		})
		Utils.acrylicLayer(sidebar, theme, 0)

		local divider = Utils.new("Frame", {
			Name = "Divider",
			AnchorPoint = Vector2.new(1, 0),
			BackgroundColor3 = theme.Divider,
			BorderSizePixel = 0,
			Position = UDim2.new(1, 0, 0, 0),
			Size = UDim2.new(0, 1, 1, 0),
			ZIndex = 3,
			Parent = sidebar,
		})

		local brand = Utils.new("Frame", {
			Name = "Brand",
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 0, theme.TopbarHeight),
			Parent = sidebar,
		})
		local brandGlow = Utils.neonGlow(brand, theme, { transparency = 0.94, expand = 0, radius = 0 })
		brandGlow.Size = UDim2.new(0, 48, 0, 3)
		brandGlow.AnchorPoint = Vector2.new(0, 1)
		brandGlow.Position = UDim2.new(0, 14, 1, -1)

		Utils.new("TextLabel", {
			BackgroundTransparency = 1,
			Font = theme.FontBold,
			Text = windowCtx.title or "Alleral",
			TextColor3 = theme.Text,
			TextSize = 13,
			Position = UDim2.fromOffset(14, 10),
			Size = UDim2.new(1, -28, 0, 16),
			TextXAlignment = Enum.TextXAlignment.Left,
			Parent = brand,
		})
		if windowCtx.subtitle then
			Utils.new("TextLabel", {
				BackgroundTransparency = 1,
				Font = theme.Font,
				Text = windowCtx.subtitle,
				TextColor3 = theme.Muted,
				TextSize = 10,
				Position = UDim2.fromOffset(14, 26),
				Size = UDim2.new(1, -28, 0, 12),
				TextXAlignment = Enum.TextXAlignment.Left,
				TextTruncate = Enum.TextTruncate.AtEnd,
				Parent = brand,
			})
		end

		local listHost = Utils.new("ScrollingFrame", {
			Name = "NavList",
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			CanvasSize = UDim2.fromOffset(0, 0),
			Position = UDim2.fromOffset(0, theme.TopbarHeight),
			ScrollBarThickness = 0,
			Size = UDim2.new(1, 0, 1, -theme.TopbarHeight - 8),
			Parent = sidebar,
		})
		Utils.new("UIPadding", {
			PaddingTop = UDim.new(0, 6),
			PaddingLeft = UDim.new(0, 6),
			PaddingRight = UDim.new(0, 6),
			Parent = listHost,
		})
		Utils.list(listHost, 3)

		local indicator = Utils.new("Frame", {
			Name = "TabIndicator",
			BackgroundColor3 = theme.Accent,
			BorderSizePixel = 0,
			Position = UDim2.fromOffset(6, 6),
			Size = UDim2.new(0, 2, 0, 30),
			ZIndex = 4,
			Parent = listHost,
		})
		Utils.corner(indicator, 2)
		Utils.neonGlow(indicator, theme, { transparency = 0.55, expand = 4, radius = 2 })

		local indicatorFill = Utils.new("Frame", {
			Name = "TabIndicatorFill",
			BackgroundColor3 = theme.Accent,
			BackgroundTransparency = 0.9,
			BorderSizePixel = 0,
			Position = UDim2.fromOffset(6, 6),
			Size = UDim2.new(1, -12, 0, 30),
			ZIndex = 0,
			Parent = listHost,
		})
		Utils.corner(indicatorFill, theme.CornerSm)

		sidebar.Position = UDim2.fromOffset(-theme.SidebarWidth - 8, 0)
		Motion.to(sidebar, { Position = UDim2.fromOffset(0, 0) }, "sidebar")

		function nav:AddItem(page, onClick)
			local itemH = 30
			local btn = Utils.new("TextButton", {
				Name = "Nav_" .. tostring(page.Name),
				AutoButtonColor = false,
				BackgroundTransparency = 1,
				Font = theme.Font,
				Text = "   " .. tostring(page.Name),
				TextColor3 = theme.Muted,
				TextSize = 12,
				TextXAlignment = Enum.TextXAlignment.Left,
				Size = UDim2.new(1, 0, 0, itemH),
				LayoutOrder = #nav._items + 1,
				ZIndex = 2,
				Parent = listHost,
			})
			local icon = Icons.image(btn, page.Icon or "layout-dashboard", UDim2.fromOffset(14, 14))
			icon.Position = UDim2.fromOffset(8, 8)
			icon.ImageColor3 = theme.Muted

			btn.MouseEnter:Connect(function()
				if nav._active ~= page then
					Motion.to(btn, { TextColor3 = theme.Text }, "micro")
					Motion.to(icon, { ImageColor3 = theme.AccentSoft }, "micro")
				end
			end)
			btn.MouseLeave:Connect(function()
				if nav._active ~= page then
					Motion.to(btn, { TextColor3 = theme.Muted }, "micro")
					Motion.to(icon, { ImageColor3 = theme.Muted }, "micro")
				end
			end)
			btn.MouseButton1Click:Connect(function()
				Motion.pressBounce(btn)
				if onClick then
					onClick(page)
				end
			end)
			table.insert(nav._items, { page = page, btn = btn, icon = icon })
			listHost.CanvasSize = UDim2.fromOffset(0, #nav._items * (itemH + 3) + 12)
			return btn
		end

		function nav:SetActive(page)
			if nav._active and nav._active.Hide then
				nav._active:Hide()
			end
			nav._active = page
			for _, item in ipairs(nav._items) do
				local active = item.page == page
				Motion.to(item.btn, { TextColor3 = active and theme.Text or theme.Muted }, "tab")
				Motion.to(item.icon, { ImageColor3 = active and theme.Accent or theme.Muted }, "tab")
				if active then
					local y = item.btn.AbsolutePosition.Y - listHost.AbsolutePosition.Y
					Motion.to(indicator, { Position = UDim2.new(0, 6, 0, y) }, "tab")
					Motion.to(indicatorFill, {
						Position = UDim2.new(0, 6, 0, y),
						BackgroundTransparency = 0.86,
					}, "tab")
				end
			end
			if page and page.Show then
				page:Show()
			end
		end

		nav._sidebar = sidebar
		nav._indicator = indicator
		return nav
	end
end
