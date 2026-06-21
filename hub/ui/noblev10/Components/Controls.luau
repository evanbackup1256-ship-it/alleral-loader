-- Alleral Noble V10 — premium desktop UI controls (Spr-driven, Janitor-managed)
return function(deps)
	local Theme = deps.Theme
	local Spr = deps.Spr
	local Util = deps.Util
	local Janitor = deps.Janitor

	local UIS = game:GetService("UserInputService")

	local TOGGLE_W, TOGGLE_H, TOGGLE_THUMB = 52, 28, 22
	local SLIDER_TRACK_H, SLIDER_THUMB = 6, 18
	local ROW_H = Theme.CONTROL.ROW_H

	local OPEN_DROPDOWN = nil

	local function spring(obj, props, preset)
		preset = preset or Theme.SPRING.SNAPPY
		Util.safeSprTarget(obj, preset[1], preset[2], props)
	end

	local function pointInGui(pos, gui)
		if not gui or not gui.Parent then return false end
		local ap = gui.AbsolutePosition
		local as = gui.AbsoluteSize
		return pos.X >= ap.X and pos.X <= ap.X + as.X and pos.Y >= ap.Y and pos.Y <= ap.Y + as.Y
	end

	local function formatSliderValue(val, rounding)
		if rounding and rounding >= 1 then
			return math.floor(val / rounding + 0.5) * rounding
		elseif rounding and rounding > 0 then
			local mul = 1 / rounding
			return math.floor(val * mul + 0.5) / mul
		end
		return val
	end

	-- BUTTON ----------------------------------------------------------------
	local function Button(cfg)
		cfg = cfg or {}
		local janitor = Janitor.new()
		local parent = cfg.Parent or cfg.parent
		local text = Util.textOf(cfg.Text or cfg.text or "Button")
		local callback = cfg.Callback or cfg.callback

		local root = Util.make("Frame", {
			Size = cfg.Size or UDim2.new(1, 0, 0, 40),
			BackgroundTransparency = 1,
			Parent = parent,
		})
		janitor:Add(root)

		local btn = Util.make("TextButton", {
			Size = UDim2.new(1, 0, 1, 0),
			BackgroundColor3 = Theme.COLOR.BG3,
			BorderSizePixel = 0,
			Text = text,
			TextColor3 = Theme.COLOR.TEXT,
			Font = Theme.FONT_BOLD,
			TextSize = Theme.TEXT,
			AutoButtonColor = false,
			ClipsDescendants = true,
			Parent = root,
		})
		Util.corner(btn, Theme.RADIUS.Button)
		local scale = Util.scale(btn)
		scale.Scale = 1

		local rippleHost = Util.make("Frame", {
			Size = UDim2.new(1, 0, 1, 0),
			BackgroundTransparency = 1,
			ClipsDescendants = true,
			ZIndex = 2,
			Parent = btn,
		})

		local hovered = false
		local pressed = false

		local function spawnRipple(input)
			local rel = btn.AbsolutePosition
			local size = btn.AbsoluteSize
			if size.X <= 0 or size.Y <= 0 then return end
			local px = input.Position.X - rel.X
			local py = input.Position.Y - rel.Y
			local ripple = Util.make("Frame", {
				Size = UDim2.fromOffset(0, 0),
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.fromOffset(px, py),
				BackgroundColor3 = Theme.COLOR.WHITE,
				BackgroundTransparency = 0.55,
				BorderSizePixel = 0,
				ZIndex = 3,
				Parent = rippleHost,
			})
			Util.corner(ripple, 999)
			local maxDim = math.max(size.X, size.Y) * 2.2
			spring(ripple, {
				Size = UDim2.fromOffset(maxDim, maxDim),
				BackgroundTransparency = 1,
			}, Theme.SPRING.SMOOTH)
			task.delay(0.45, function()
				if ripple.Parent then ripple:Destroy() end
			end)
		end

		local function refreshVisual()
			if pressed then
				spring(scale, { Scale = 0.97 })
				spring(btn, { BackgroundColor3 = Theme.COLOR.Surface0 })
			elseif hovered then
				spring(scale, { Scale = 1.025 })
				spring(btn, { BackgroundColor3 = Theme.COLOR.Surface2, TextColor3 = Theme.COLOR.Text })
			else
				spring(scale, { Scale = 1 })
				spring(btn, { BackgroundColor3 = Theme.COLOR.Surface1, TextColor3 = Theme.COLOR.Text })
			end
		end

		janitor:Connect(btn.MouseEnter, function()
			hovered = true
			refreshVisual()
		end)
		janitor:Connect(btn.MouseLeave, function()
			hovered = false
			pressed = false
			refreshVisual()
		end)
		janitor:Connect(btn.MouseButton1Down, function()
			pressed = true
			refreshVisual()
		end)
		janitor:Connect(btn.MouseButton1Up, function()
			pressed = false
			refreshVisual()
		end)
		janitor:Connect(btn.MouseButton1Click, function(input)
			spawnRipple(input)
			if callback then callback() end
		end)

		local api = {
			Container = root,
			Destroy = function()
				janitor:Destroy()
			end,
			Set = function(_, v)
				if type(v) == "table" then
					v = v.Text or v.Name or v.text
				end
				if v ~= nil then btn.Text = Util.textOf(v) end
			end,
			SetText = function(_, v)
				btn.Text = Util.textOf(v)
			end,
		}
		return api
	end

	-- TOGGLE ----------------------------------------------------------------
	local function Toggle(cfg)
		cfg = cfg or {}
		local janitor = Janitor.new()
		local parent = cfg.Parent or cfg.parent
		local name = Util.textOf(cfg.Text or cfg.Name or cfg.text or "Toggle")
		local callback = cfg.Callback or cfg.callback
		local enabled = cfg.Value == true or cfg.Default == true or cfg.default == true

		local root = Util.make("Frame", {
			Size = UDim2.new(1, 0, 0, ROW_H),
			BackgroundTransparency = 1,
			Parent = parent,
		})
		janitor:Add(root)

		Util.make("TextLabel", {
			Size = UDim2.new(1, -TOGGLE_W - 12, 1, 0),
			BackgroundTransparency = 1,
			Text = name,
			TextColor3 = Theme.COLOR.TEXT,
			Font = Theme.FONT,
			TextSize = Theme.TEXT,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextYAlignment = Enum.TextYAlignment.Center,
			TextTruncate = Enum.TextTruncate.AtEnd,
			Parent = root,
		})

		local track = Util.make("TextButton", {
			Size = UDim2.fromOffset(TOGGLE_W, TOGGLE_H),
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.new(1, 0, 0.5, 0),
			BackgroundColor3 = enabled and Theme.COLOR.ACCENT or Theme.COLOR.BG4,
			BorderSizePixel = 0,
			Text = "",
			AutoButtonColor = false,
			Parent = root,
		})
		Util.corner(track, TOGGLE_H / 2)

		local glow = Util.make("Frame", {
			Size = UDim2.new(1, 14, 1, 14),
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.new(0.5, 0, 0.5, 0),
			BackgroundColor3 = Theme.COLOR.GLOW,
			BackgroundTransparency = enabled and 0.7 or 1,
			BorderSizePixel = 0,
			ZIndex = 0,
			Parent = track,
		})
		Util.corner(glow, TOGGLE_H / 2 + 7)

		local thumb = Util.make("Frame", {
			Size = UDim2.fromOffset(TOGGLE_THUMB, TOGGLE_THUMB),
			AnchorPoint = Vector2.new(0, 0.5),
			Position = enabled and UDim2.new(1, -TOGGLE_THUMB - 3, 0.5, 0) or UDim2.new(0, 3, 0.5, 0),
			BackgroundColor3 = Theme.COLOR.WHITE,
			BorderSizePixel = 0,
			ZIndex = 2,
			Parent = track,
		})
		Util.corner(thumb, TOGGLE_THUMB / 2)

		local function pulseGlow()
			if not enabled then return end
			spring(glow, { Size = UDim2.new(1, 18, 1, 18) }, Theme.SPRING.TOGGLE)
			task.delay(0.14, function()
				if glow.Parent then
					spring(glow, { Size = UDim2.new(1, 14, 1, 14) }, Theme.SPRING.TOGGLE)
				end
			end)
		end

		local function apply(val, fire)
			enabled = val == true
			spring(track, { BackgroundColor3 = enabled and Theme.COLOR.ACCENT or Theme.COLOR.BG4 }, Theme.SPRING.TOGGLE)
			spring(thumb, {
				Position = enabled and UDim2.new(1, -TOGGLE_THUMB - 3, 0.5, 0) or UDim2.new(0, 3, 0.5, 0),
			}, Theme.SPRING.TOGGLE)
			spring(glow, { BackgroundTransparency = enabled and 0.68 or 1 }, Theme.SPRING.TOGGLE)
			if enabled then pulseGlow() end
			if fire and callback then callback(enabled) end
		end

		janitor:Connect(track.MouseEnter, function()
			spring(glow, { BackgroundTransparency = enabled and 0.58 or 0.88 }, Theme.SPRING.TOGGLE)
		end)
		janitor:Connect(track.MouseLeave, function()
			spring(glow, { BackgroundTransparency = enabled and 0.68 or 1 }, Theme.SPRING.TOGGLE)
		end)
		janitor:Connect(track.MouseButton1Click, function()
			apply(not enabled, true)
		end)

		local api = {
			Container = root,
			Destroy = function()
				janitor:Destroy()
			end,
			Set = function(_, v)
				if type(v) == "table" then v = v.Value or v.CurrentValue or v.value end
				if v ~= nil then apply(v == true, false) end
			end,
			SetValue = function(_, v)
				if v ~= nil then apply(v == true, false) end
			end,
		}
		return api
	end

	-- SLIDER ----------------------------------------------------------------
	local function Slider(cfg)
		cfg = cfg or {}
		local janitor = Janitor.new()
		local parent = cfg.Parent or cfg.parent
		local name = Util.textOf(cfg.Text or cfg.Name or cfg.text or "Slider")
		local minVal = cfg.Min or cfg.min or 0
		local maxVal = cfg.Max or cfg.max or 100
		local suffix = cfg.Suffix or cfg.suffix or ""
		local rounding = cfg.Rounding or cfg.rounding or 1
		local callback = cfg.Callback or cfg.callback
		local default = cfg.Default or cfg.default or minVal
		if maxVal < minVal then minVal, maxVal = maxVal, minVal end

		local root = Util.make("Frame", {
			Size = UDim2.new(1, 0, 0, ROW_H + 14),
			BackgroundTransparency = 1,
			Parent = parent,
		})
		janitor:Add(root)

		Util.make("TextLabel", {
			Size = UDim2.new(1, -56, 0, ROW_H),
			BackgroundTransparency = 1,
			Text = name,
			TextColor3 = Theme.COLOR.TEXT,
			Font = Theme.FONT,
			TextSize = Theme.TEXT,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextYAlignment = Enum.TextYAlignment.Center,
			TextTruncate = Enum.TextTruncate.AtEnd,
			Parent = root,
		})

		local valLabel = Util.make("TextLabel", {
			Size = UDim2.fromOffset(56, ROW_H),
			AnchorPoint = Vector2.new(1, 0),
			Position = UDim2.new(1, 0, 0, 0),
			BackgroundTransparency = 1,
			Text = tostring(formatSliderValue(default, rounding)) .. suffix,
			TextColor3 = Theme.COLOR.ACCENT_LIGHT,
			Font = Theme.FONT_BOLD,
			TextSize = Theme.TEXT_SM,
			TextXAlignment = Enum.TextXAlignment.Right,
			TextYAlignment = Enum.TextYAlignment.Center,
			Parent = root,
		})

		local track = Util.make("Frame", {
			Size = UDim2.new(1, 0, 0, SLIDER_TRACK_H),
			AnchorPoint = Vector2.new(0, 1),
			Position = UDim2.new(0, 0, 1, -2),
			BackgroundColor3 = Theme.COLOR.BG4,
			BorderSizePixel = 0,
			Parent = root,
		})
		Util.corner(track, SLIDER_TRACK_H / 2)

		local fill = Util.make("Frame", {
			Size = UDim2.new(0, 0, 1, 0),
			BackgroundColor3 = Theme.COLOR.ACCENT,
			BorderSizePixel = 0,
			ZIndex = 1,
			Parent = track,
		})
		Util.corner(fill, SLIDER_TRACK_H / 2)
		Util.gradient(fill, Theme.COLOR.ACCENT_LIGHT, Theme.COLOR.ACCENT, 0)

		local thumbGlow = Util.make("Frame", {
			Size = UDim2.fromOffset(SLIDER_THUMB + 10, SLIDER_THUMB + 10),
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.new(0, 0, 0.5, 0),
			BackgroundColor3 = Theme.COLOR.GLOW,
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			ZIndex = 2,
			Parent = track,
		})
		Util.corner(thumbGlow, (SLIDER_THUMB + 10) / 2)

		local thumb = Util.make("Frame", {
			Size = UDim2.fromOffset(SLIDER_THUMB, SLIDER_THUMB),
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.new(0, 0, 0.5, 0),
			BackgroundColor3 = Theme.COLOR.WHITE,
			BorderSizePixel = 0,
			ZIndex = 3,
			Parent = track,
		})
		Util.corner(thumb, SLIDER_THUMB / 2)

		local counter = Util.make("NumberValue", { Value = default })
		janitor:Add(counter)
		janitor:Connect(counter.Changed, function()
			valLabel.Text = tostring(formatSliderValue(counter.Value, rounding)) .. suffix
		end)

		local currentVal = default
		local dragging = false

		local function fractionFromValue(v)
			if maxVal == minVal then return 0 end
			return Util.clamp((v - minVal) / (maxVal - minVal), 0, 1)
		end

		local function setValue(fraction, smoothLabel, fireCallback)
			fraction = Util.clamp(fraction, 0, 1)
			local raw = minVal + fraction * (maxVal - minVal)
			currentVal = formatSliderValue(raw, rounding)
			currentVal = Util.clamp(currentVal, minVal, maxVal)
			local fr = fractionFromValue(currentVal)

			spring(fill, { Size = UDim2.new(fr, 0, 1, 0) }, Theme.SPRING.SNAPPY)
			spring(thumb, { Position = UDim2.new(fr, 0, 0.5, 0) }, Theme.SPRING.SNAPPY)
			spring(thumbGlow, { Position = UDim2.new(fr, 0, 0.5, 0) }, Theme.SPRING.SNAPPY)

			if smoothLabel then
				spring(counter, { Value = currentVal }, Theme.SPRING.SMOOTH)
			else
				counter.Value = currentVal
			end

			if fireCallback and callback then callback(currentVal) end
		end

		local function updateFromX(x, smooth)
			local ap = track.AbsolutePosition.X
			local as = track.AbsoluteSize.X
			if as <= 1 then return end
			setValue((x - ap) / as, smooth == true, not smooth)
		end

		setValue(fractionFromValue(default), false, false)

		janitor:Connect(track.InputBegan, function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				dragging = true
				spring(thumb, { Size = UDim2.fromOffset(SLIDER_THUMB + 6, SLIDER_THUMB + 6) }, Theme.SPRING.SNAPPY)
				spring(thumbGlow, { BackgroundTransparency = 0.72, Size = UDim2.fromOffset(SLIDER_THUMB + 14, SLIDER_THUMB + 14) }, Theme.SPRING.SNAPPY)
				updateFromX(input.Position.X, false)
			end
		end)
		janitor:Connect(track.InputEnded, function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				dragging = false
				spring(thumb, { Size = UDim2.fromOffset(SLIDER_THUMB, SLIDER_THUMB) }, Theme.SPRING.SNAPPY)
				spring(thumbGlow, { BackgroundTransparency = 1, Size = UDim2.fromOffset(SLIDER_THUMB + 10, SLIDER_THUMB + 10) }, Theme.SPRING.SMOOTH)
				if callback then callback(currentVal) end
			end
		end)
		janitor:Connect(UIS.InputChanged, function(input)
			if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
				updateFromX(input.Position.X, true)
			end
		end)

		local api = {
			Container = root,
			Destroy = function()
				janitor:Destroy()
			end,
			Set = function(_, v)
				if type(v) == "table" then v = v.Value or v.CurrentValue or v.value end
				if tonumber(v) then setValue(fractionFromValue(tonumber(v)), true, false) end
			end,
			SetValue = function(_, v)
				if tonumber(v) then setValue(fractionFromValue(tonumber(v)), true, false) end
			end,
		}
		return api
	end

	-- DROPDOWN --------------------------------------------------------------
	local function Dropdown(cfg)
		cfg = cfg or {}
		local janitor = Janitor.new()
		local parent = cfg.Parent or cfg.parent
		local dropLayer = cfg.DropLayer or cfg.dropLayer or parent
		local name = Util.textOf(cfg.Text or cfg.Name or cfg.text or "Dropdown")
		local options = type(cfg.Options or cfg.Values or cfg.options) == "table" and (cfg.Options or cfg.Values or cfg.options) or {}
		local multi = cfg.Multi == true or cfg.multi == true
		local searchable = cfg.Searchable == true or cfg.searchable == true or multi
		local callback = cfg.Callback or cfg.callback
		local maxMenuH = cfg.MaxHeight or cfg.maxHeight or 220

		local selected = multi and {} or Util.textOf(cfg.Default or cfg.default or options[1] or "")
		if multi and type(cfg.Default) == "table" then selected = cfg.Default end
		if multi and type(cfg.default) == "table" then selected = cfg.default end

		local root = Util.make("Frame", {
			Size = UDim2.new(1, 0, 0, ROW_H),
			BackgroundTransparency = 1,
			ClipsDescendants = false,
			ZIndex = 2,
			Parent = parent,
		})
		janitor:Add(root)

		Util.make("TextLabel", {
			Size = UDim2.fromOffset(108, ROW_H),
			BackgroundTransparency = 1,
			Text = name,
			TextColor3 = Theme.COLOR.TEXT2,
			Font = Theme.FONT,
			TextSize = Theme.TEXT_SM,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextYAlignment = Enum.TextYAlignment.Center,
			TextTruncate = Enum.TextTruncate.AtEnd,
			Parent = root,
		})

		local function displayText()
			if multi then
				if #selected == 0 then return "None selected" end
				if #selected == 1 then return tostring(selected[1]) end
				return tostring(#selected) .. " selected"
			end
			return tostring(selected or "")
		end

		local trigger = Util.make("TextButton", {
			Size = UDim2.new(1, -112, 1, 0),
			Position = UDim2.new(0, 112, 0, 0),
			BackgroundColor3 = Theme.COLOR.BG3,
			BorderSizePixel = 0,
			Text = displayText(),
			TextColor3 = Theme.COLOR.TEXT,
			Font = Theme.FONT,
			TextSize = Theme.TEXT_SM,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextTruncate = Enum.TextTruncate.AtEnd,
			AutoButtonColor = false,
			ClipsDescendants = true,
			ZIndex = 3,
			Parent = root,
		})
		Util.corner(trigger, Theme.RADIUS.Input)
		local triggerStroke = Util.stroke(trigger, Theme.COLOR.BorderSoft, 1, 0.82)
		Util.padding(trigger, 12, 34, 0, 0)

		local arrow = Util.make("TextLabel", {
			Size = UDim2.fromOffset(20, 20),
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.new(1, -20, 0.5, 0),
			BackgroundTransparency = 1,
			Text = "\226\140\132",
			TextColor3 = Theme.COLOR.TEXT3,
			Font = Theme.FONT_BOLD,
			TextSize = 14,
			Rotation = 0,
			ZIndex = 4,
			Parent = trigger,
		})

		local panel = Util.make("Frame", {
			Size = UDim2.fromOffset(0, 0),
			BackgroundColor3 = Theme.COLOR.Glass,
			BackgroundTransparency = 0.06,
			BorderSizePixel = 0,
			Visible = false,
			ClipsDescendants = true,
			ZIndex = 40,
			Parent = dropLayer,
		})
		janitor:Add(panel)
		Util.corner(panel, Theme.RADIUS.Dropdown)
		if deps.Layout and deps.Layout.shadow then deps.Layout.shadow(panel, Theme.RADIUS.Dropdown, 2, 0.65) end

		local body = Util.make("Frame", {
			Size = UDim2.new(1, 0, 1, 0),
			BackgroundTransparency = 1,
			ClipsDescendants = true,
			ZIndex = 41,
			Parent = panel,
		})
		Util.padding(body, 4, 4, 4, 4)

		local searchBox
		local searchStroke
		local searchPad = 0
		if searchable then
			searchPad = 36
			local searchWrap = Util.make("Frame", {
				Size = UDim2.new(1, 0, 0, 32),
				BackgroundTransparency = 1,
				ZIndex = 43,
				Parent = body,
			})
			searchBox = Util.make("TextBox", {
				Size = UDim2.new(1, 0, 1, 0),
				BackgroundColor3 = Theme.COLOR.SEARCH_BG,
				BorderSizePixel = 0,
				PlaceholderText = "Search...",
				PlaceholderColor3 = Theme.COLOR.TEXT3,
				Text = "",
				TextColor3 = Theme.COLOR.TEXT,
				Font = Theme.FONT,
				TextSize = Theme.TEXT_SM,
				TextXAlignment = Enum.TextXAlignment.Left,
				ClearTextOnFocus = false,
				ZIndex = 44,
				Parent = searchWrap,
			})
			Util.corner(searchBox, Theme.RADIUS.Input)
			searchStroke = Util.stroke(searchBox, Theme.COLOR.BorderSoft, 1, 0.82)
			Util.padding(searchBox, 28, 10, 0, 0)
			Util.make("TextLabel", {
				Size = UDim2.fromOffset(18, 36),
				Position = UDim2.new(0, 12, 0, 0),
				BackgroundTransparency = 1,
				Text = "\226\140\149",
				TextColor3 = Theme.COLOR.TEXT3,
				Font = Theme.FONT,
				TextSize = 15,
				ZIndex = 45,
				Parent = searchWrap,
			})
			janitor:Connect(searchBox.Focused, function()
				spring(searchStroke, { Color = Theme.COLOR.AccentSoft, Transparency = 0.5 }, Theme.SPRING.SNAPPY)
				spring(searchBox, { BackgroundColor3 = Theme.COLOR.Surface2 }, Theme.SPRING.SNAPPY)
			end)
			janitor:Connect(searchBox.FocusLost, function()
				spring(searchStroke, { Color = Theme.COLOR.BorderSoft, Transparency = 0.82 }, Theme.SPRING.SNAPPY)
				spring(searchBox, { BackgroundColor3 = Theme.COLOR.SEARCH_BG }, Theme.SPRING.SNAPPY)
			end)
		end

		local scroll = Util.make("ScrollingFrame", {
			Size = UDim2.new(1, 0, 1, -searchPad),
			Position = UDim2.new(0, 0, 0, searchPad),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			CanvasSize = UDim2.new(0, 0, 0, 0),
			AutomaticCanvasSize = Enum.AutomaticSize.Y,
			ScrollingDirection = Enum.ScrollingDirection.Y,
			ScrollBarThickness = 4,
			ClipsDescendants = true,
			ZIndex = 42,
			Parent = body,
		})
		Util.styleScroll(scroll)
		Util.make("UIListLayout", {
			Padding = UDim.new(0, 4),
			SortOrder = Enum.SortOrder.LayoutOrder,
			Parent = scroll,
		})

		local optionRows = {}
		local isOpen = false
		local targetMenuH = 0
		local closeDropdown

		local function rebuildList(filterText)
			for _, row in ipairs(optionRows) do
				if row.Parent then row:Destroy() end
			end
			optionRows = {}
			filterText = filterText and string.lower(filterText) or nil

			local filtered = {}
			for _, opt in ipairs(options) do
				local txt = tostring(opt)
				if not filterText or string.find(string.lower(txt), filterText, 1, true) then
					table.insert(filtered, opt)
				end
			end

			for idx, opt in ipairs(filtered) do
				local picked = false
				if multi then
					for _, s in ipairs(selected) do
						if s == opt then picked = true break end
					end
				else
					picked = (selected == opt)
				end

				local row = Util.make("TextButton", {
					Size = UDim2.new(1, -4, 0, 40),
					BackgroundColor3 = picked and Theme.COLOR.AccentSoft or Theme.COLOR.Surface1,
					BackgroundTransparency = picked and 0.55 or 0.75,
					BorderSizePixel = 0,
					Text = tostring(opt),
					TextColor3 = picked and Theme.COLOR.Text or Theme.COLOR.TextMuted,
					Font = Theme.FONT,
					TextSize = Theme.TEXT_SM,
					TextXAlignment = Enum.TextXAlignment.Left,
					AutoButtonColor = false,
					LayoutOrder = idx,
					ClipsDescendants = true,
					ZIndex = 43,
					Parent = scroll,
				})
				Util.padding(row, 10, 8, 0, 0)

				if isOpen then
					row.BackgroundTransparency = 1
					row.TextTransparency = 1
					task.delay(idx * 0.028, function()
						if row.Parent then
							spring(row, {
								BackgroundTransparency = picked and 0.08 or 0.15,
								TextTransparency = 0,
							}, Theme.SPRING.SNAPPY)
						end
					end)
				end

				row.MouseEnter:Connect(function()
					if not picked then
						spring(row, { BackgroundColor3 = Theme.COLOR.Surface2, BackgroundTransparency = 0.5 }, Theme.SPRING.SNAPPY)
					end
				end)
				row.MouseLeave:Connect(function()
					if not picked then
						spring(row, { BackgroundColor3 = Theme.COLOR.Surface1, BackgroundTransparency = 0.75 }, Theme.SPRING.SNAPPY)
					end
				end)
				row.MouseButton1Click:Connect(function()
					if multi then
						local found = false
						for j, s in ipairs(selected) do
							if s == opt then
								table.remove(selected, j)
								found = true
								break
							end
						end
						if not found then table.insert(selected, opt) end
					else
						selected = opt
						closeDropdown()
					end
					trigger.Text = displayText()
					rebuildList(searchBox and searchBox.Text or nil)
					if callback then callback(multi and selected or selected) end
				end)

				table.insert(optionRows, row)
			end

			local listH = math.max(40, math.min(#filtered * 44 + 4, maxMenuH))
			targetMenuH = listH + searchPad + 12
		end

		local function positionPanel(animateH)
			if not dropLayer or not dropLayer.Parent then return end
			local layerPos = dropLayer.AbsolutePosition
			local layerSize = dropLayer.AbsoluteSize
			local ap = trigger.AbsolutePosition
			local as = trigger.AbsoluteSize
			if as.X <= 0 then return end

			local relX = ap.X - layerPos.X
			local relY = ap.Y - layerPos.Y + as.Y + 4
			local dw = as.X
			local maxH = math.max(80, layerSize.Y - relY - 8)
			local dh = math.min(targetMenuH, maxH)
			relX = Util.clamp(relX, 4, math.max(4, layerSize.X - dw - 4))

			panel.Position = UDim2.fromOffset(relX, relY)
			if animateH and isOpen then
				spring(panel, { Size = UDim2.fromOffset(dw, dh) }, Theme.SPRING.DROPDOWN)
			else
				panel.Size = UDim2.fromOffset(dw, isOpen and dh or 0)
			end
		end

		closeDropdown = function()
			if not isOpen then return end
			isOpen = false
			if OPEN_DROPDOWN == closeDropdown then OPEN_DROPDOWN = nil end
			spring(arrow, { Rotation = 0 }, Theme.SPRING.DROPDOWN)
			spring(trigger, { BackgroundColor3 = Theme.COLOR.BG3 }, Theme.SPRING.DROPDOWN)
			spring(panel, { Size = UDim2.fromOffset(panel.AbsoluteSize.X, 0), BackgroundTransparency = 1 }, Theme.SPRING.DROPDOWN)
			task.delay(0.22, function()
				if not isOpen and panel.Parent then panel.Visible = false end
			end)
			if multi and callback then callback(selected) end
		end

		local function openDropdown()
			if OPEN_DROPDOWN and OPEN_DROPDOWN ~= closeDropdown then
				pcall(OPEN_DROPDOWN)
			end
			isOpen = true
			OPEN_DROPDOWN = closeDropdown
			rebuildList(searchBox and searchBox.Text or nil)
			positionPanel(false)
			panel.Visible = true
			panel.BackgroundTransparency = 0.12
			local dw = trigger.AbsoluteSize.X
			panel.Size = UDim2.fromOffset(dw, 0)
			positionPanel(true)
			spring(panel, { BackgroundTransparency = 0.04 }, Theme.SPRING.DROPDOWN)
			spring(arrow, { Rotation = 180 }, Theme.SPRING.DROPDOWN)
			spring(trigger, { BackgroundColor3 = Theme.COLOR.BG4 }, Theme.SPRING.DROPDOWN)
			if searchBox then
				searchBox.TextTransparency = 1
				spring(searchBox, { TextTransparency = 0 }, Theme.SPRING.SNAPPY)
			end
		end

		rebuildList()

		janitor:Connect(trigger.MouseButton1Click, function()
			if isOpen then closeDropdown() else openDropdown() end
		end)
		janitor:Connect(trigger.MouseEnter, function()
			if not isOpen then spring(trigger, { BackgroundColor3 = Theme.COLOR.BG4 }, Theme.SPRING.SNAPPY) end
		end)
		janitor:Connect(trigger.MouseLeave, function()
			if not isOpen then spring(trigger, { BackgroundColor3 = Theme.COLOR.BG3 }, Theme.SPRING.SNAPPY) end
		end)
		janitor:Connect(trigger:GetPropertyChangedSignal("AbsolutePosition"), function()
			if isOpen then positionPanel(false) end
		end)
		janitor:Connect(trigger:GetPropertyChangedSignal("AbsoluteSize"), function()
			if isOpen then positionPanel(false) end
		end)
		if searchBox then
			janitor:Connect(searchBox:GetPropertyChangedSignal("Text"), function()
				rebuildList(searchBox.Text)
				if isOpen then positionPanel(true) end
			end)
		end
		janitor:Connect(UIS.InputBegan, function(input)
			if input.KeyCode == Enum.KeyCode.Escape and isOpen then
				closeDropdown()
				return
			end
			if input.UserInputType == Enum.UserInputType.MouseButton1 and isOpen then
				local p = input.Position
				if not pointInGui(p, panel) and not pointInGui(p, trigger) then
					closeDropdown()
				end
			end
		end)

		local api = {
			Container = root,
			Destroy = function()
				if OPEN_DROPDOWN == closeDropdown then OPEN_DROPDOWN = nil end
				janitor:Destroy()
			end,
			Set = function(_, v)
				if type(v) ~= "table" then return end
				if v.Options or v.Values then
					options = v.Options or v.Values or options
					rebuildList(searchBox and searchBox.Text or nil)
				end
				local pick = v.CurrentOption or v.CurrentOptions or v.Value
				if pick ~= nil then
					if multi then
						selected = type(pick) == "table" and pick or { tostring(pick) }
					else
						selected = tostring(pick)
					end
					trigger.Text = displayText()
					rebuildList(searchBox and searchBox.Text or nil)
				end
			end,
			SetValue = function(_, v)
				if v == nil then return end
				if multi then
					selected = type(v) == "table" and v or { tostring(v) }
				else
					selected = tostring(v)
				end
				trigger.Text = displayText()
				rebuildList(searchBox and searchBox.Text or nil)
			end,
			Refresh = function(_, newOpts)
				if type(newOpts) == "table" then options = newOpts end
				rebuildList(searchBox and searchBox.Text or nil)
			end,
		}
		return api
	end

	-- INPUT -----------------------------------------------------------------
	local function Input(cfg)
		cfg = cfg or {}
		local janitor = Janitor.new()
		local parent = cfg.Parent or cfg.parent
		local name = Util.textOf(cfg.Text or cfg.Name or cfg.text or "Input")
		local placeholder = cfg.Placeholder or cfg.placeholder or "Enter..."
		local default = Util.textOf(cfg.Default or cfg.default or "")
		local callback = cfg.Callback or cfg.callback

		local root = Util.make("Frame", {
			Size = UDim2.new(1, 0, 0, 56),
			BackgroundTransparency = 1,
			Parent = parent,
		})
		janitor:Add(root)

		Util.make("TextLabel", {
			Size = UDim2.new(1, 0, 0, 24),
			BackgroundTransparency = 1,
			Text = name,
			TextColor3 = Theme.COLOR.TEXT2,
			Font = Theme.FONT,
			TextSize = Theme.TEXT_SM,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextYAlignment = Enum.TextYAlignment.Center,
			Parent = root,
		})

		local box = Util.make("TextBox", {
			Size = UDim2.new(1, 0, 0, 28),
			Position = UDim2.new(0, 0, 0, 24),
			BackgroundColor3 = Theme.COLOR.BG3,
			BorderSizePixel = 0,
			PlaceholderText = placeholder,
			PlaceholderColor3 = Theme.COLOR.TEXT3,
			Text = default,
			TextColor3 = Theme.COLOR.TEXT,
			Font = Theme.FONT,
			TextSize = Theme.TEXT_SM,
			TextXAlignment = Enum.TextXAlignment.Left,
			ClearTextOnFocus = false,
			Parent = root,
		})
		Util.corner(box, Theme.CONTROL.RADIUS)
		local stroke = Util.stroke(box, Theme.COLOR.BORDER, 1, 0.88)

		janitor:Connect(box.Focused, function()
			spring(box, { BackgroundColor3 = Theme.COLOR.BG4 }, Theme.SPRING.SNAPPY)
			spring(stroke, { Color = Theme.COLOR.ACCENT, Thickness = 1.5, Transparency = 0 }, Theme.SPRING.SNAPPY)
		end)
		janitor:Connect(box.FocusLost, function(enterPressed)
			spring(box, { BackgroundColor3 = Theme.COLOR.BG3 }, Theme.SPRING.SNAPPY)
			spring(stroke, { Color = Theme.COLOR.BORDER, Thickness = 1, Transparency = 0.88 }, Theme.SPRING.SNAPPY)
			if callback then callback(box.Text, enterPressed) end
		end)

		local api = {
			Container = root,
			Destroy = function()
				janitor:Destroy()
			end,
			Set = function(_, v)
				if type(v) == "table" then v = v.Text or v.Value or v.CurrentValue end
				box.Text = Util.textOf(v)
			end,
			SetText = function(_, v)
				box.Text = Util.textOf(v)
			end,
			SetValue = function(_, v)
				box.Text = Util.textOf(v)
			end,
		}
		return api
	end

	-- LABEL -----------------------------------------------------------------
	local function Label(cfg)
		cfg = cfg or {}
		local janitor = Janitor.new()
		local parent = cfg.Parent or cfg.parent
		local text = Util.textOf(cfg.Text or cfg.text or "")

		local root = Util.make("TextLabel", {
			Size = cfg.Size or UDim2.new(1, 0, 0, ROW_H),
			BackgroundTransparency = 1,
			Text = text,
			TextColor3 = cfg.Color or Theme.COLOR.TEXT2,
			Font = cfg.Bold and Theme.FONT_BOLD or Theme.FONT,
			TextSize = cfg.TextSize or Theme.TEXT_SM,
			TextXAlignment = cfg.Align or Enum.TextXAlignment.Left,
			TextYAlignment = Enum.TextYAlignment.Center,
			TextWrapped = cfg.Wrap == true,
			TextTruncate = Enum.TextTruncate.AtEnd,
			Parent = parent,
		})
		janitor:Add(root)

		return {
			Container = root,
			Destroy = function()
				janitor:Destroy()
			end,
			Set = function(_, v)
				if type(v) == "table" then v = v.Text or v.Name end
				root.Text = Util.textOf(v)
			end,
			SetText = function(_, v)
				root.Text = Util.textOf(v)
			end,
		}
	end

	-- DIVIDER ---------------------------------------------------------------
	local function Divider(cfg)
		cfg = cfg or {}
		local janitor = Janitor.new()
		local parent = cfg.Parent or cfg.parent

		local root = Util.make("Frame", {
			Size = UDim2.new(1, 0, 0, cfg.Height or 16),
			BackgroundTransparency = 1,
			Parent = parent,
		})
		janitor:Add(root)

		local line = Util.make("Frame", {
			Size = UDim2.new(1, 0, 0, 1),
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.new(0.5, 0, 0.5, 0),
			BackgroundColor3 = Theme.COLOR.BORDER_SOFT,
			BackgroundTransparency = 0.35,
			BorderSizePixel = 0,
			Parent = root,
		})

		return {
			Container = root,
			Destroy = function()
				janitor:Destroy()
			end,
			Set = function() end,
		}
	end

	-- CARD ------------------------------------------------------------------
	local function Card(cfg)
		cfg = cfg or {}
		local janitor = Janitor.new()
		local parent = cfg.Parent or cfg.parent
		local title = Util.textOf(cfg.Title or cfg.title or "")
		local width = cfg.Width or cfg.width or 360

		local root = Util.make("Frame", {
			Size = UDim2.new(0, width, 0, 0),
			BackgroundTransparency = 1,
			AutomaticSize = Enum.AutomaticSize.Y,
			Parent = parent,
		})
		janitor:Add(root)

		if deps.Layout and deps.Layout.shadow then deps.Layout.shadow(root, Theme.RADIUS.Card, 2, 0.68) end

		local card = Util.make("Frame", {
			Size = UDim2.new(1, 0, 0, 0),
			BackgroundColor3 = Theme.COLOR.Surface1,
			BackgroundTransparency = 0.04,
			BorderSizePixel = 0,
			AutomaticSize = Enum.AutomaticSize.Y,
			ClipsDescendants = true,
			ZIndex = 2,
			Parent = root,
		})
		Util.corner(card, Theme.RADIUS.Card)
		Util.gradient(card, Theme.COLOR.Surface1, Theme.COLOR.Surface0, 180)

		Util.make("Frame", {
			Size = UDim2.new(1, -24, 0, 1),
			Position = UDim2.new(0, 12, 0, 0),
			BackgroundColor3 = Theme.COLOR.Accent,
			BackgroundTransparency = 0.55,
			BorderSizePixel = 0,
			ZIndex = 4,
			Parent = card,
		})

		local header = Util.make("TextLabel", {
			Size = UDim2.new(1, -Theme.CARD.PAD * 2, 0, Theme.CARD.TITLE_H),
			Position = UDim2.new(0, Theme.CARD.PAD, 0, Theme.CARD.PAD / 2),
			BackgroundTransparency = 1,
			Text = title,
			TextColor3 = Theme.COLOR.TEXT,
			Font = Theme.FONT_BOLD,
			TextSize = Theme.TEXT_TITLE,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextYAlignment = Enum.TextYAlignment.Center,
			Parent = card,
		})

		local content = Util.make("Frame", {
			Size = UDim2.new(1, -Theme.CARD.PAD * 2, 0, 0),
			Position = UDim2.new(0, Theme.CARD.PAD, 0, Theme.CARD.TITLE_H + Theme.CARD.PAD),
			BackgroundTransparency = 1,
			AutomaticSize = Enum.AutomaticSize.Y,
			Parent = card,
		})
		Util.make("UIListLayout", {
			Padding = UDim.new(0, Theme.CARD.GAP),
			SortOrder = Enum.SortOrder.LayoutOrder,
			Parent = content,
		})
		Util.padding(card, Theme.CARD.PAD, Theme.CARD.PAD, 0, Theme.CARD.PAD)

		return {
			Container = root,
			Content = content,
			Destroy = function()
				janitor:Destroy()
			end,
			Set = function(_, v)
				if type(v) == "table" then v = v.Title or v.title or v.Text end
				if v ~= nil then header.Text = Util.textOf(v) end
			end,
			SetText = function(_, v)
				header.Text = Util.textOf(v)
			end,
			Refresh = function() end,
		}
	end

	return {
		Button = Button,
		Toggle = Toggle,
		Slider = Slider,
		Dropdown = Dropdown,
		Input = Input,
		Label = Label,
		Divider = Divider,
		Card = Card,
	}
end