return function(deps)
	local Utils = deps.Utils
	local Motion = deps.Motion
	local Theme = deps.Theme
	local Icons = deps.Icons
	local Config = deps.Config
	local Tooltip = deps.Tooltip

	local Components = {}

	local function rowFrame(parent, theme, height)
		local frame = Utils.new("Frame", {
			Name = "Row",
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 0, height or theme.RowHeight),
			Parent = parent,
		})
		return frame
	end

	local function rowLabel(parent, text, theme, desc)
		Utils.new("TextLabel", {
			Name = "Label",
			BackgroundTransparency = 1,
			Font = theme.Font,
			Text = tostring(text),
			TextColor3 = theme.Text,
			TextSize = 13,
			TextXAlignment = Enum.TextXAlignment.Left,
			Position = UDim2.fromOffset(0, desc and 2 or 8),
			Size = UDim2.new(1, -120, 0, 18),
			Parent = parent,
		})
		if desc and desc ~= "" then
			Utils.new("TextLabel", {
				Name = "Desc",
				BackgroundTransparency = 1,
				Font = theme.Font,
				Text = tostring(desc),
				TextColor3 = theme.Muted,
				TextSize = 11,
				TextXAlignment = Enum.TextXAlignment.Left,
				Position = UDim2.fromOffset(0, 20),
				Size = UDim2.new(1, -120, 0, 14),
				Parent = parent,
			})
		end
	end

	function Components.Toggle(ctx, opts)
		opts = opts or {}
		local theme = ctx.theme
		local row = rowFrame(ctx.parent, theme, opts.Description and 40 or theme.RowHeight)
		rowLabel(row, opts.Name, theme, opts.Description or opts.Desc)
		local track = Utils.new("TextButton", {
			Name = "Track",
			AnchorPoint = Vector2.new(1, 0.5),
			AutoButtonColor = false,
			BackgroundColor3 = opts.Default and theme.TrackOn or theme.TrackOff,
			BorderSizePixel = 0,
			Position = UDim2.new(1, 0, 0.5, 0),
			Size = UDim2.fromOffset(38, 18),
			Text = "",
			Parent = row,
		})
		Utils.corner(track, 9)
		local glow = Utils.neonGlow(track, theme, { transparency = 0.92, expand = 2, radius = 9 })
		glow.Visible = opts.Default == true
		local knob = Utils.new("Frame", {
			Name = "Knob",
			BackgroundColor3 = theme.Knob,
			BorderSizePixel = 0,
			Position = opts.Default and UDim2.fromOffset(20, 2) or UDim2.fromOffset(2, 2),
			Size = UDim2.fromOffset(14, 14),
			Parent = track,
		})
		Utils.corner(knob, 7)
		local value = opts.Default == true
		local flag = opts.Flag
		local function apply(v, silent)
			value = v == true
			glow.Visible = value
			Motion.to(track, { BackgroundColor3 = value and theme.TrackOn or theme.TrackOff }, "micro")
			Motion.to(knob, { Position = value and UDim2.fromOffset(20, 2) or UDim2.fromOffset(2, 2) }, "bouncy")
			if value then
				Motion.to(glow, { BackgroundTransparency = 0.78 }, "micro")
			end
			if flag then
				Config.set(flag, value)
			end
			if not silent and opts.Callback then
				opts.Callback(value)
			end
		end
		track.MouseButton1Click:Connect(function()
			Motion.pressBounce(track)
			apply(not value)
		end)
		if opts.Tooltip or opts.Desc then
			Tooltip.attach(track, opts.Tooltip or opts.Desc, theme)
		end
		if flag and Config.get(flag) ~= nil then
			apply(Config.get(flag), true)
		end
		return {
			_instance = track,
			Set = function(_, v, silent)
				apply(type(v) == "table" and v.CurrentValue or v, silent)
			end,
			Get = function()
				return value
			end,
		}
	end

	function Components.Slider(ctx, opts)
		opts = opts or {}
		local theme = ctx.theme
		local minV = (opts.Min or (opts.Range and opts.Range[1])) or 0
		local maxV = (opts.Max or (opts.Range and opts.Range[2])) or 100
		local inc = opts.Increment or opts.Decimals or 1
		local row = rowFrame(ctx.parent, theme, opts.Description and 52 or 44)
		rowLabel(row, opts.Name, theme, opts.Description or opts.Desc)
		local valueLabel = Utils.new("TextLabel", {
			AnchorPoint = Vector2.new(1, 0),
			BackgroundTransparency = 1,
			Font = theme.Font,
			Text = tostring(opts.Default or minV) .. (opts.Suffix or ""),
			TextColor3 = theme.Muted,
			TextSize = 12,
			Position = UDim2.new(1, 0, 0, 6),
			Size = UDim2.fromOffset(60, 16),
			TextXAlignment = Enum.TextXAlignment.Right,
			Parent = row,
		})
		local track = Utils.new("Frame", {
			BackgroundColor3 = theme.TrackOff,
			BorderSizePixel = 0,
			Position = UDim2.new(0, 0, 1, -16),
			Size = UDim2.new(1, 0, 0, 6),
			Parent = row,
		})
		Utils.corner(track, 3)
		local fill = Utils.new("Frame", {
			BackgroundColor3 = theme.Accent,
			BorderSizePixel = 0,
			Size = UDim2.new(0, 0, 1, 0),
			Parent = track,
		})
		Utils.corner(fill, 3)
		Utils.neonGlow(fill, theme, { transparency = 0.82, expand = 2, radius = 3 })
		local knob = Utils.new("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundColor3 = theme.Knob,
			BorderSizePixel = 0,
			Position = UDim2.new(0, 0, 0.5, 0),
			Size = UDim2.fromOffset(14, 14),
			ZIndex = 2,
			Parent = track,
		})
		Utils.corner(knob, 7)
		local value = tonumber(opts.Default) or minV
		local flag = opts.Flag
		local dragging = false
		local function pct(v)
			return Utils.clamp((v - minV) / math.max(maxV - minV, 0.001), 0, 1)
		end
		local function apply(v, silent)
			value = Utils.clamp(Utils.round(v, 2), minV, maxV)
			local p = pct(value)
			Motion.to(fill, { Size = UDim2.new(p, 0, 1, 0) }, "micro")
			Motion.to(knob, { Position = UDim2.new(p, 0, 0.5, 0) }, "micro")
			valueLabel.Text = tostring(value) .. (opts.Suffix or "")
			if flag then
				Config.set(flag, value)
			end
			if not silent and opts.Callback then
				opts.Callback(value)
			end
		end
		local function updateFromInput(input)
			local rel = Utils.clamp((input.Position.X - track.AbsolutePosition.X) / math.max(track.AbsoluteSize.X, 1), 0, 1)
			apply(minV + (maxV - minV) * rel)
		end
		track.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				dragging = true
				updateFromInput(input)
			end
		end)
		track.InputEnded:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				dragging = false
			end
		end)
		game:GetService("UserInputService").InputChanged:Connect(function(input)
			if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
				updateFromInput(input)
			end
		end)
		if opts.Tooltip or opts.Desc then
			Tooltip.attach(row, opts.Tooltip or opts.Desc, theme)
		end
		apply(value, true)
		return {
			_instance = row,
			Set = function(_, v, silent)
				apply(type(v) == "table" and tonumber(v.CurrentValue) or tonumber(v) or minV, silent)
			end,
			Get = function()
				return value
			end,
		}
	end

	function Components.Button(ctx, opts)
		opts = opts or {}
		local theme = ctx.theme
		local btn = Utils.new("TextButton", {
			Name = opts.Name or "Button",
			AutoButtonColor = false,
			BackgroundColor3 = theme.Elevated,
			Font = theme.Font,
			Text = tostring(opts.Name or "Button"),
			TextColor3 = theme.Text,
			TextSize = 12,
			Size = UDim2.new(1, 0, 0, theme.RowHeight),
			Parent = ctx.parent,
		})
		Utils.corner(btn, theme.CornerSm)
		Utils.stroke(btn, theme.Border, 1, 0.93)
		Utils.bindHoverTint(Motion, btn, theme, false)
		btn.MouseButton1Click:Connect(function(input)
			Motion.pressBounce(btn)
			if input and btn.Parent then
				Utils.ripple(Motion, btn, input, theme.Accent)
			end
			if opts.Callback then
				opts.Callback()
			end
		end)
		if opts.Tooltip or opts.Desc then
			Tooltip.attach(btn, opts.Tooltip or opts.Desc, theme)
		end
		return { _instance = btn, Set = function() end }
	end

	function Components.Label(ctx, text)
		local theme = ctx.theme
		local label = Utils.new("TextLabel", {
			BackgroundTransparency = 1,
			Font = theme.Font,
			Text = tostring(text),
			TextColor3 = theme.Muted,
			TextSize = 12,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextWrapped = true,
			Size = UDim2.new(1, 0, 0, 20),
			Parent = ctx.parent,
		})
		return {
			Set = function(_, v)
				label.Text = type(v) == "table" and tostring(v.Name or v.Text or "") or tostring(v or "")
			end,
			SetText = function(_, v)
				label.Text = tostring(v or "")
			end,
		}
	end

	function Components.Separator(ctx)
		local theme = ctx.theme
		Utils.new("Frame", {
			BackgroundColor3 = theme.Divider,
			BorderSizePixel = 0,
			Size = UDim2.new(1, 0, 0, 1),
			Parent = ctx.parent,
		})
		return {}
	end

	function Components.Textbox(ctx, opts)
		opts = opts or {}
		local theme = ctx.theme
		local row = rowFrame(ctx.parent, theme, 44)
		rowLabel(row, opts.Name, theme, opts.Desc)
		local box = Utils.new("TextBox", {
			AnchorPoint = Vector2.new(1, 0.5),
			BackgroundColor3 = theme.TrackOff,
			BorderSizePixel = 0,
			ClearTextOnFocus = opts.RemoveTextOnFocus ~= false,
			Font = theme.Font,
			PlaceholderText = opts.Placeholder or opts.PlaceholderText or "",
			Text = tostring(opts.Default or opts.CurrentValue or ""),
			TextColor3 = theme.Text,
			TextSize = 13,
			Position = UDim2.new(1, 0, 0.5, 0),
			Size = UDim2.fromOffset(160, 30),
			Parent = row,
		})
		Utils.corner(box, theme.CornerSm)
		local flag = opts.Flag
		box.FocusLost:Connect(function()
			if flag then
				Config.set(flag, box.Text)
			end
			if opts.Callback then
				opts.Callback(box.Text)
			end
		end)
		if opts.Tooltip or opts.Desc then
			Tooltip.attach(box, opts.Tooltip or opts.Desc, theme)
		end
		return {
			_instance = box,
			Set = function(_, v)
				box.Text = type(v) == "table" and tostring(v.CurrentValue or "") or tostring(v or "")
			end,
		}
	end

	function Components.Dropdown(ctx, opts)
		opts = opts or {}
		local theme = ctx.theme
		local options = opts.Options or opts.Items or {}
		local multi = opts.Multi == true or opts.MultipleOptions == true
		local open = false
		local row = rowFrame(ctx.parent, theme, 44)
		rowLabel(row, opts.Name, theme, opts.Desc)
		local btn = Utils.new("TextButton", {
			AnchorPoint = Vector2.new(1, 0.5),
			AutoButtonColor = false,
			BackgroundColor3 = theme.Elevated,
			Font = theme.Font,
			Text = tostring(opts.Default or options[1] or "Select"),
			TextColor3 = theme.Text,
			TextSize = 11,
			Position = UDim2.new(1, 0, 0.5, 0),
			Size = UDim2.fromOffset(148, 26),
			TextTruncate = Enum.TextTruncate.AtEnd,
			Parent = row,
		})
		Utils.corner(btn, theme.CornerSm)
		Utils.stroke(btn, theme.Border, 1, 0.94)
		Icons.image(btn, "chevron-down", UDim2.fromOffset(12, 12)).Position = UDim2.new(1, -18, 0.5, -6)
		local menu
		local value = opts.Default or options[1]
		local flag = opts.Flag
		local function setDisplay(v)
			if multi and type(v) == "table" then
				btn.Text = table.concat(v, ", ")
			else
				btn.Text = tostring(v or "")
			end
		end
		local function closeMenu()
			if menu then
				Motion.to(menu, { Size = UDim2.fromOffset(160, 0), BackgroundTransparency = 1 }, "dropdown", function()
					if menu then
						menu:Destroy()
						menu = nil
					end
				end)
			end
			open = false
		end
		local function openMenu()
			if open then
				closeMenu()
				return
			end
			open = true
			menu = Utils.new("Frame", {
				BackgroundColor3 = theme.Card,
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				ClipsDescendants = true,
				Position = UDim2.new(1, -160, 1, 4),
				Size = UDim2.fromOffset(160, 0),
				ZIndex = 20,
				Parent = row,
			})
			Utils.corner(menu, theme.CornerSm)
			Utils.stroke(menu, theme.Border, 1, 0.9)
			local list = Utils.new("ScrollingFrame", {
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				CanvasSize = UDim2.fromOffset(0, #options * 28),
				ScrollBarThickness = 2,
				Size = UDim2.fromScale(1, 1),
				Parent = menu,
			})
			Utils.list(list, 0)
			for i, opt in ipairs(options) do
				local item = Utils.new("TextButton", {
					AutoButtonColor = false,
					BackgroundColor3 = theme.Surface,
					BackgroundTransparency = 1,
					Font = theme.Font,
					Text = tostring(opt),
					TextColor3 = theme.Text,
					TextSize = 12,
					Size = UDim2.new(1, 0, 0, 28),
					LayoutOrder = i,
					Parent = list,
				})
				item.MouseEnter:Connect(function()
					Motion.to(item, { BackgroundTransparency = 0.5 }, "micro")
				end)
				item.MouseLeave:Connect(function()
					Motion.to(item, { BackgroundTransparency = 1 }, "micro")
				end)
				item.MouseButton1Click:Connect(function()
					value = opt
					setDisplay(value)
					if flag then
						Config.set(flag, value)
					end
					if opts.Callback then
						opts.Callback(value)
					end
					closeMenu()
				end)
			end
			Utils.neonGlow(menu, theme, { transparency = 0.88, expand = 4, radius = theme.CornerSm })
			Motion.to(menu, { BackgroundTransparency = 0.04, Size = UDim2.fromOffset(148, math.min(#options * 26, 130)) }, "dropdown")
		end
		btn.MouseButton1Click:Connect(openMenu)
		if opts.Tooltip or opts.Desc then
			Tooltip.attach(btn, opts.Tooltip or opts.Desc, theme)
		end
		setDisplay(value)
		return {
			_instance = btn,
			Set = function(_, v)
				if type(v) == "table" then
					if v.Options or v.Values then
						options = v.Options or v.Values
					end
					value = v.CurrentOption or v.CurrentOptions or v[1] or value
				else
					value = v
				end
				setDisplay(value)
			end,
			Refresh = function(_, newOptions, selected)
				options = newOptions or options
				value = selected or value
				setDisplay(value)
			end,
		}
	end

	function Components.Keybind(ctx, opts)
		opts = opts or {}
		local theme = ctx.theme
		local row = rowFrame(ctx.parent, theme, 44)
		rowLabel(row, opts.Name, theme, opts.Desc)
		local btn = Utils.new("TextButton", {
			AnchorPoint = Vector2.new(1, 0.5),
			AutoButtonColor = false,
			BackgroundColor3 = theme.Elevated,
			Font = theme.FontMono,
			Text = tostring(opts.Default or "None"),
			TextColor3 = theme.AccentSoft,
			TextSize = 11,
			Position = UDim2.new(1, 0, 0.5, 0),
			Size = UDim2.fromOffset(88, 24),
			Parent = row,
		})
		Utils.corner(btn, theme.CornerSm)
		Utils.stroke(btn, theme.Accent, 1, 0.88)
		local listening = false
		local value = opts.Default
		btn.MouseButton1Click:Connect(function()
			listening = true
			btn.Text = "..."
		end)
		game:GetService("UserInputService").InputBegan:Connect(function(input, processed)
			if not listening or processed then
				return
			end
			if input.UserInputType == Enum.UserInputType.Keyboard then
				value = input.KeyCode.Name
				btn.Text = value
				listening = false
				if opts.Flag then
					Config.set(opts.Flag, value)
				end
				if opts.Callback then
					opts.Callback(value)
				end
			end
		end)
		return { Set = function(_, v)
			value = type(v) == "table" and v.CurrentValue or v
			btn.Text = tostring(value or "None")
		end }
	end

	function Components.Colorpicker(ctx, opts)
		opts = opts or {}
		local theme = ctx.theme
		local row = rowFrame(ctx.parent, theme, 44)
		rowLabel(row, opts.Name, theme, opts.Desc)
		local swatch = Utils.new("TextButton", {
			AnchorPoint = Vector2.new(1, 0.5),
			AutoButtonColor = false,
			BackgroundColor3 = opts.Default or theme.Accent,
			BorderSizePixel = 0,
			Text = "",
			Position = UDim2.new(1, 0, 0.5, 0),
			Size = UDim2.fromOffset(36, 30),
			Parent = row,
		})
		Utils.corner(swatch, theme.CornerSm)
		local value = opts.Default or theme.Accent
		swatch.MouseButton1Click:Connect(function()
			Motion.pressBounce(swatch)
			if opts.Callback then
				opts.Callback(value)
			end
		end)
		return {
			Set = function(_, v)
				value = type(v) == "table" and v.CurrentValue or v
				if typeof(value) == "Color3" then
					Motion.to(swatch, { BackgroundColor3 = value }, "soft")
				end
			end,
		}
	end

	function Components.StatusCard(ctx, opts)
		local theme = ctx.theme
		local card = Utils.new("Frame", {
			BackgroundColor3 = theme.Card,
			BackgroundTransparency = 0.02,
			BorderSizePixel = 0,
			Size = UDim2.new(1, 0, 0, 72),
			Parent = ctx.parent,
		})
		Utils.corner(card, theme.Corner)
		Utils.stroke(card, theme.Border, 1, 0.9)
		Utils.new("TextLabel", {
			Name = "Title",
			BackgroundTransparency = 1,
			Font = theme.FontBold,
			Text = tostring(opts.Name or opts.Title or "Status"),
			TextColor3 = theme.Text,
			TextSize = 13,
			Position = UDim2.fromOffset(14, 10),
			Size = UDim2.new(1, -28, 0, 18),
			TextXAlignment = Enum.TextXAlignment.Left,
			Parent = card,
		})
		local summary = Utils.new("TextLabel", {
			Name = "Summary",
			BackgroundTransparency = 1,
			Font = theme.Font,
			Text = tostring(opts.Summary or opts.Value or ""),
			TextColor3 = theme.Muted,
			TextSize = 12,
			Position = UDim2.fromOffset(14, 34),
			Size = UDim2.new(1, -28, 0, 28),
			TextXAlignment = Enum.TextXAlignment.Left,
			TextWrapped = true,
			Parent = card,
		})
		Motion.to(card, { BackgroundTransparency = 0.02 }, "open")
		return {
			_frame = card,
			SetSummary = function(_, text)
				summary.Text = tostring(text or "")
			end,
			Update = function(_, fields)
				if type(fields) == "table" then
					local parts = {}
					for k, v in pairs(fields) do
						table.insert(parts, tostring(k) .. ": " .. tostring(v))
					end
					summary.Text = table.concat(parts, " · ")
				end
			end,
			SetVisible = function(_, visible)
				card.Visible = visible == true
			end,
		}
	end

	function Components.DashboardCard(ctx, opts)
		local theme = ctx.theme
		local card = Utils.new("Frame", {
			BackgroundColor3 = theme.Card,
			BorderSizePixel = 0,
			Size = UDim2.new(0.5, -6, 0, 88),
			Parent = ctx.parent,
		})
		Utils.corner(card, theme.Corner)
		Utils.stroke(card, theme.Border, 1, 0.9)
		Utils.gradient(card, { theme.Card, theme.Elevated }, 135)
		Utils.new("TextLabel", {
			BackgroundTransparency = 1,
			Font = theme.Font,
			Text = tostring(opts.Label or opts.Name or ""),
			TextColor3 = theme.Muted,
			TextSize = 11,
			Position = UDim2.fromOffset(14, 12),
			Size = UDim2.new(1, -28, 0, 16),
			TextXAlignment = Enum.TextXAlignment.Left,
			Parent = card,
		})
		local val = Utils.new("TextLabel", {
			Name = "Value",
			BackgroundTransparency = 1,
			Font = theme.FontBold,
			Text = tostring(opts.Value or "—"),
			TextColor3 = theme.Text,
			TextSize = 22,
			Position = UDim2.fromOffset(14, 34),
			Size = UDim2.new(1, -28, 0, 28),
			TextXAlignment = Enum.TextXAlignment.Left,
			Parent = card,
		})
		card.BackgroundTransparency = 1
		Motion.to(card, { BackgroundTransparency = 0.04 }, "stagger")
		return {
			Set = function(_, v)
				val.Text = tostring(v or "—")
			end,
		}
	end

	function Components.PlayerList(ctx, opts)
		local theme = ctx.theme
		local frame = Utils.new("ScrollingFrame", {
			BackgroundColor3 = theme.Card,
			BackgroundTransparency = 0.02,
			BorderSizePixel = 0,
			CanvasSize = UDim2.fromOffset(0, 0),
			ScrollBarThickness = 3,
			Size = UDim2.new(1, 0, 0, opts.Height or 200),
			Parent = ctx.parent,
		})
		Utils.corner(frame, theme.Corner)
		Utils.list(frame, 4)
		local rows = {}
		local function refresh()
			for _, r in ipairs(rows) do
				r:Destroy()
			end
			table.clear(rows)
			local players = game:GetService("Players"):GetPlayers()
			for i, plr in ipairs(players) do
				local row = Utils.new("TextButton", {
					AutoButtonColor = false,
					BackgroundColor3 = theme.Surface,
					BackgroundTransparency = 0.5,
					Font = theme.Font,
					Text = plr.DisplayName ~= "" and plr.DisplayName or plr.Name,
					TextColor3 = theme.Text,
					TextSize = 12,
					Size = UDim2.new(1, -8, 0, 32),
					LayoutOrder = i,
					Parent = frame,
				})
				Utils.corner(row, theme.CornerSm)
				row.MouseButton1Click:Connect(function()
					if opts.OnSelect then
						opts.OnSelect(plr)
					end
				end)
				table.insert(rows, row)
			end
			frame.CanvasSize = UDim2.fromOffset(0, #players * 36)
		end
		refresh()
		game:GetService("Players").PlayerAdded:Connect(refresh)
		game:GetService("Players").PlayerRemoving:Connect(refresh)
		return { Refresh = refresh }
	end

	function Components.LogPanel(ctx, opts)
		local theme = ctx.theme
		local frame = Utils.new("ScrollingFrame", {
			BackgroundColor3 = theme.Canvas,
			BackgroundTransparency = 0.1,
			BorderSizePixel = 0,
			CanvasSize = UDim2.fromOffset(0, 0),
			ScrollBarThickness = 3,
			Size = UDim2.new(1, 0, 0, opts.Height or 160),
			Parent = ctx.parent,
		})
		Utils.corner(frame, theme.CornerSm)
		local list = Utils.list(frame, 2)
		local lines = {}
		return {
			Append = function(_, text)
				local line = Utils.new("TextLabel", {
					BackgroundTransparency = 1,
					Font = theme.FontMono,
					Text = tostring(text),
					TextColor3 = theme.Muted,
					TextSize = 11,
					TextXAlignment = Enum.TextXAlignment.Left,
					TextWrapped = true,
					Size = UDim2.new(1, -8, 0, 16),
					LayoutOrder = #lines + 1,
					Parent = frame,
				})
				table.insert(lines, line)
				if #lines > (opts.MaxLines or 100) then
					lines[1]:Destroy()
					table.remove(lines, 1)
				end
				frame.CanvasSize = UDim2.fromOffset(0, #lines * 18)
				frame.CanvasPosition = Vector2.new(0, math.max(0, frame.CanvasSize.Y.Offset - frame.AbsoluteSize.Y))
			end,
		}
	end

	return Components
end
