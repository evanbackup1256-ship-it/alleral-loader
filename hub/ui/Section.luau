return function(deps)
	local Utils = deps.Utils
	local Motion = deps.Motion
	local Components = deps.Components

	return function(ctx, opts)
		opts = opts or {}
		local theme = ctx.theme
		local section = { _ctx = ctx, _widgets = {} }

		local wrap = Utils.new("Frame", {
			Name = "Groupbox_" .. tostring(opts.Name or "Section"),
			BackgroundTransparency = 1,
			AutomaticSize = Enum.AutomaticSize.Y,
			Size = UDim2.new(1, 0, 0, 0),
			Parent = ctx.scroll or ctx.parent,
		})
		Utils.list(wrap, theme.Gap)

		Utils.groupboxHeader(wrap, theme, opts.Name or "Section")

		local body = Utils.new("Frame", {
			Name = "SectionBody",
			BackgroundColor3 = theme.Card,
			BackgroundTransparency = 0.08,
			BorderSizePixel = 0,
			AutomaticSize = Enum.AutomaticSize.Y,
			Size = UDim2.new(1, 0, 0, 0),
			LayoutOrder = 2,
			Parent = wrap,
		})
		Utils.corner(body, theme.CornerSm)
		Utils.stroke(body, theme.Border, 1, theme.BorderAlpha or 0.93)
		Utils.accentEdge(body, theme, "left")
		Utils.list(body, 4)
		Utils.new("UIPadding", {
			PaddingTop = UDim.new(0, 8),
			PaddingBottom = UDim.new(0, 8),
			PaddingLeft = UDim.new(0, 10),
			PaddingRight = UDim.new(0, 8),
			Parent = body,
		})

		local innerCtx = {
			parent = body,
			theme = theme,
			window = ctx.window,
			config = ctx.config,
		}

		function section:Toggle(o) return Components.Toggle(innerCtx, o) end
		function section:Slider(o) return Components.Slider(innerCtx, o) end
		function section:Button(o) return Components.Button(innerCtx, o) end
		function section:Label(t) return Components.Label(innerCtx, t) end
		function section:Space(o)
			Utils.new("Frame", {
				BackgroundTransparency = 1,
				Size = UDim2.new(1, 0, 0, (o and o.Size) or 6),
				Parent = body,
			})
		end
		function section:Textbox(o) return Components.Textbox(innerCtx, o) end
		function section:Dropdown(o) return Components.Dropdown(innerCtx, o) end
		function section:Keybind(o) return Components.Keybind(innerCtx, o) end
		function section:Colorpicker(o) return Components.Colorpicker(innerCtx, o) end
		function section:StatusCard(o) return Components.StatusCard(innerCtx, o) end

		section.CreateToggle = section.Toggle
		section.CreateSlider = section.Slider
		section.CreateButton = section.Button
		section.CreateLabel = section.Label
		section.CreateDivider = function() return Components.Separator(innerCtx) end
		section.CreateInput = section.Textbox
		section.CreateDropdown = section.Dropdown

		body.BackgroundTransparency = 1
		Motion.to(body, { BackgroundTransparency = 0.08 }, "open")

		section._body = body
		section._wrap = wrap
		return section
	end
end
