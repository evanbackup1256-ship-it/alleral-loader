return function(deps)
	local Utils = deps.Utils
	local Motion = deps.Motion
	local Section = deps.Section
	local Components = deps.Components

	return function(windowCtx, opts)
		opts = opts or {}
		local theme = windowCtx.theme
		local columns = math.max(1, tonumber(opts.Columns) or 2)

		local page = {
			Name = opts.Name or "Page",
			Icon = opts.Icon,
			Columns = columns,
			_visible = false,
			_sections = {},
		}

		local container = Utils.new("Frame", {
			Name = "Page_" .. tostring(opts.Name or "Main"),
			BackgroundTransparency = 1,
			Size = UDim2.fromScale(1, 1),
			Visible = false,
			Parent = windowCtx.content,
		})

		local scroll = Utils.new("ScrollingFrame", {
			Name = "Scroll",
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			CanvasSize = UDim2.fromOffset(0, 0),
			ScrollBarThickness = 3,
			Size = UDim2.fromScale(1, 1),
			Parent = container,
		})
		Utils.new("UIPadding", {
			PaddingTop = UDim.new(0, math.max(8, theme.Padding)),
			PaddingBottom = UDim.new(0, math.max(8, theme.Padding)),
			PaddingLeft = UDim.new(0, math.max(8, theme.Padding - 2)),
			PaddingRight = UDim.new(0, math.max(8, theme.Padding - 2)),
			Parent = scroll,
		})

		local grid = Utils.new("Frame", {
			Name = "Grid",
			BackgroundTransparency = 1,
			AutomaticSize = Enum.AutomaticSize.Y,
			Size = UDim2.new(1, 0, 0, 0),
			Parent = scroll,
		})
		Utils.list(grid, theme.Gap, Enum.FillDirection.Horizontal)

		local columnFrames = {}
		for i = 1, columns do
			local col = Utils.new("Frame", {
				Name = "Column" .. i,
				BackgroundTransparency = 1,
				LayoutOrder = i,
				Size = UDim2.new(1 / columns, -(theme.Gap * (columns - 1) / columns), 0, 0),
				AutomaticSize = Enum.AutomaticSize.Y,
				Parent = grid,
			})
			Utils.list(col, theme.Gap)
			columnFrames[i] = col
		end

		local ctx = {
			theme = theme,
			window = windowCtx,
			config = windowCtx.config,
			scroll = nil,
			parent = nil,
		}

		function page:Show()
			if self._visible then
				return
			end
			self._visible = true
			container.Visible = true
			container.Position = UDim2.fromScale(0.02, 0)
			Motion.to(container, { Position = UDim2.fromScale(0, 0) }, "tab")
			for _, child in ipairs(grid:GetChildren()) do
				if child:IsA("Frame") then
					child.BackgroundTransparency = 1
				end
			end
			Motion.stagger(columnFrames, function()
				return { Position = UDim2.fromOffset(0, 0) }
			end, "stagger", 0.03)
		end

		function page:Hide()
			self._visible = false
			Motion.to(container, { Position = UDim2.fromScale(-0.02, 0) }, "tab", function()
				container.Visible = false
			end)
		end

		function page:Section(o)
			o = o or {}
			local col = math.clamp(tonumber(o.Side or o.Column) or 1, 1, columns)
			ctx.parent = columnFrames[col]
			ctx.scroll = columnFrames[col]
			local sec = Section(ctx, o)
			table.insert(page._sections, sec)
			return sec
		end

		function page:CreateSection(o) return page:Section(o) end

		function page:CreateToggle(o)
			ctx.parent = columnFrames[1]
			ctx.scroll = columnFrames[1]
			return Components.Toggle(ctx, o)
		end
		function page:CreateSlider(o)
			ctx.parent = columnFrames[1]
			return Components.Slider(ctx, o)
		end
		function page:CreateDropdown(o)
			ctx.parent = columnFrames[1]
			return Components.Dropdown(ctx, o)
		end
		function page:CreateButton(o)
			ctx.parent = columnFrames[1]
			return Components.Button(ctx, o)
		end
		function page:CreateLabel(t)
			ctx.parent = columnFrames[1]
			return Components.Label(ctx, t)
		end

		function page:CreateDashboardRow(cards)
			local row = Utils.new("Frame", {
				BackgroundTransparency = 1,
				Size = UDim2.new(1, 0, 0, 96),
				Parent = columnFrames[1],
			})
			Utils.list(row, 12, Enum.FillDirection.Horizontal)
			local built = {}
			for _, cardOpts in ipairs(cards or {}) do
				ctx.parent = row
				table.insert(built, Components.DashboardCard(ctx, cardOpts))
			end
			return built
		end

		page._container = container
		page._scroll = scroll
		page._columnFrames = columnFrames
		return page
	end
end
