-- Alleral V11.5.3 — WindUI control builders (aurora accents, ripple press)
return function(Bootstrap, Motion, Text, Guards, _TooltipManager, Theme)
	local Controls = {}
	Text = Text or Bootstrap
	Guards = Guards or { wrap = function(fn) return fn or function() end end }
	local TweenService = game:GetService("TweenService")
	local rippleTargets = {}

	local LAYOUT = {
		SLIDER_WIDTH = 240,
	}

	local ACCENT = Color3.fromHex("#7C3AED")
	local ACCENT_BRIGHT = Color3.fromHex("#A78BFA")
	local CYAN = Color3.fromHex("#22D3EE")

	if Theme then
		pcall(function()
			if Theme.accent then
				ACCENT = Theme.accent()
			end
			if Theme.accentBright then
				ACCENT_BRIGHT = Theme.accentBright()
			end
			if Theme.cyan then
				CYAN = Theme.cyan()
			end
		end)
	end

	local function stub()
		return {
			Set = function() end,
			SetText = function() end,
			SetVisible = function() end,
			SetValue = function() end,
			SetValueSilent = function() end,
			Refresh = function() end,
		}
	end

	local function shouldSkipText(text)
		text = Bootstrap.sanitize(text, 200)
		return text == "" or text == "--" or text == "—"
	end

	local function findRippleHost(el)
		if typeof(el) ~= "Instance" then
			if type(el) == "table" and el.UIElements then
				local main = el.UIElements.Main or el.UIElements.Button
				if typeof(main) == "Instance" then
					return main
				end
			end
			return nil
		end
		if el:IsA("GuiButton") then
			return el
		end
		return el:FindFirstChildWhichIsA("GuiButton", true) or el:FindFirstChildWhichIsA("TextButton", true) or el:FindFirstChildWhichIsA("ImageButton", true)
	end

	local function attachRipple(el)
		local host = findRippleHost(el)
		if not host or rippleTargets[host] then
			return
		end
		rippleTargets[host] = true
		pcall(function()
			if not host:FindFirstChild("AlleralRipple") then
				local ripple = Instance.new("Frame")
				ripple.Name = "AlleralRipple"
				ripple.BackgroundColor3 = ACCENT_BRIGHT
				ripple.BackgroundTransparency = 0.55
				ripple.BorderSizePixel = 0
				ripple.Size = UDim2.fromScale(0, 0)
				ripple.AnchorPoint = Vector2.new(0.5, 0.5)
				ripple.Position = UDim2.fromScale(0.5, 0.5)
				ripple.ZIndex = (host.ZIndex or 1) + 2
				ripple.Visible = false
				ripple.Parent = host
				local corner = Instance.new("UICorner")
				corner.CornerRadius = UDim.new(1, 0)
				corner.Parent = ripple
			end
			host.InputBegan:Connect(function(input)
				if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then
					return
				end
				local ripple = host:FindFirstChild("AlleralRipple")
				if not ripple then
					return
				end
				local rel = Vector2.new(0.5, 0.5)
				pcall(function()
					rel = Vector2.new(
						(input.Position.X - host.AbsolutePosition.X) / math.max(host.AbsoluteSize.X, 1),
						(input.Position.Y - host.AbsolutePosition.Y) / math.max(host.AbsoluteSize.Y, 1)
					)
				end)
				ripple.Position = UDim2.fromScale(rel.X, rel.Y)
				ripple.Size = UDim2.fromScale(0, 0)
				ripple.Visible = true
				ripple.BackgroundTransparency = 0.45
				local grow = TweenService:Create(ripple, TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
					Size = UDim2.fromScale(2.4, 2.4),
					BackgroundTransparency = 1,
				})
				grow:Play()
				grow.Completed:Connect(function()
					ripple.Visible = false
				end)
				TweenService:Create(host, TweenInfo.new(0.08, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
					Size = host.Size - UDim2.fromOffset(1, 1),
				}):Play()
				task.delay(0.08, function()
					if host.Parent then
						TweenService:Create(host, TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
							Size = host.Size + UDim2.fromOffset(1, 1),
						}):Play()
					end
				end)
			end)
		end)
	end

	local function wrapElement(el, kind, flag)
		if not el then
			return stub()
		end
		local api = { _raw = el, _kind = kind, _setting = false }

		function api:SetValueSilent(_, v)
			if api._setting then
				return
			end
			api._setting = true
			Guards.silentSet(el, v, kind)
			pcall(function()
				if el.SetValue then
					el:SetValue(v)
				elseif el.Set then
					local prev = el.Callback
					el.Callback = function() end
					el:Set(v)
					el.Callback = prev
				end
			end)
			api._setting = false
		end

		function api:SetValue(_, v)
			if api._setting or Guards.isSilent(flag or kind) then
				return api:SetValueSilent(nil, v)
			end
			api._setting = true
			pcall(function()
				if el.Set then
					el:Set(v)
				elseif el.SetValue then
					el:SetValue(v)
				end
			end)
			api._setting = false
		end

		function api:Set(_, v)
			api:SetValue(nil, v)
		end

		function api:SetText(_, t)
			local clean = Bootstrap.sanitize(t, 200)
			if clean == "" then
				return
			end
			pcall(function()
				if el.SetTitle then
					el:SetTitle(clean)
				elseif el.Set then
					el:Set(clean)
				elseif el.Title ~= nil then
					el.Title = clean
				end
			end)
		end

		function api:SetVisible() end

		function api:Refresh(_, values)
			pcall(function()
				if el.Refresh then
					el:Refresh(Text.sanitizeList and Text.sanitizeList(values) or values)
				end
			end)
		end

		return api
	end

	function Controls.createGroup(section, groupName)
		if not section then
			return nil
		end
		groupName = Bootstrap.sanitize(groupName, 64)
		if groupName == "" then
			return nil
		end

		local box = section
		if type(section.Section) == "function" then
			local ok, created = pcall(function()
				return section:Section({
					Title = groupName,
					Desc = "",
					Box = true,
					BoxBorder = true,
					Opened = true,
				})
			end)
			if ok and created then
				box = created
			end
		end

		local group = { _controlCount = 0 }

		local function track(el, kind, flag, title, props)
			if el then
				group._controlCount = group._controlCount + 1
				if kind == "button" then
					attachRipple(el)
				end
			end
			return wrapElement(el, kind, flag)
		end

		function group:AddLabel(text)
			text = Bootstrap.sanitize(text, 200)
			if shouldSkipText(text) then
				return stub()
			end
			local el
			pcall(function()
				if type(box.Paragraph) == "function" then
					el = box:Paragraph({
						Title = text,
						Desc = "",
					})
				end
			end)
			return track(el, "label", text, text, {})
		end

		function group:AddDivider()
			return {}
		end

		function group:AddToggle(flag, props)
			props = type(props) == "table" and props or {}
			local title = Bootstrap.sanitize(props.Text or flag or "Toggle", 80)
			if shouldSkipText(title) then
				return stub()
			end
			local flagKey = Bootstrap.sanitize(flag or title, 48)
			local el
			pcall(function()
				el = box:Toggle({
					Flag = flagKey,
					Title = title,
					Desc = "",
					Value = props.Default == true,
					Callback = Guards.wrap(props.Callback or function() end, "toggle:" .. flagKey),
				})
			end)
			return track(el, "toggle", flagKey, title, props)
		end

		function group:AddButton(props)
			props = type(props) == "table" and props or {}
			local title = Bootstrap.sanitize(props.Text or "Button", 80)
			if shouldSkipText(title) then
				return stub()
			end
			local el
			pcall(function()
				el = box:Button({
					Title = title,
					Desc = "",
					Color = props.Primary and ACCENT_BRIGHT or ACCENT,
					Icon = props.Icon,
					IconColor = props.Icon and CYAN or nil,
					Justify = "Center",
					Callback = Guards.wrap(props.Func or props.Callback or function() end, "button:" .. title),
				})
			end)
			return track(el, "button", title, title, props)
		end

		function group:AddSlider(flag, props)
			props = type(props) == "table" and props or {}
			local title = Bootstrap.sanitize(props.Text or flag or "Slider", 80)
			if shouldSkipText(title) then
				return stub()
			end
			local minV = tonumber(props.Min) or 0
			local maxV = tonumber(props.Max) or 100
			local defV = tonumber(props.Default) or minV
			local flagKey = Bootstrap.sanitize(flag or title, 48)
			local el
			pcall(function()
				el = box:Slider({
					Flag = flagKey,
					Title = title,
					Desc = "",
					Step = tonumber(props.Rounding) or 1,
					Width = LAYOUT.SLIDER_WIDTH,
					IsTooltip = false,
					IsTextbox = true,
					DisplayInTooltip = false,
					Value = {
						Min = minV,
						Max = maxV,
						Default = defV,
						DisplayMethod = "Value",
					},
					Callback = Guards.wrap(props.Callback or function() end, "slider:" .. flagKey),
				})
			end)
			return track(el, "slider", flagKey, title, props)
		end

		function group:AddInput(flag, props)
			props = type(props) == "table" and props or {}
			local title = Bootstrap.sanitize(props.Text or flag or "Input", 80)
			if shouldSkipText(title) then
				return stub()
			end
			local flagKey = Bootstrap.sanitize(flag or title, 48)
			local el
			pcall(function()
				el = box:Input({
					Flag = flagKey,
					Title = title,
					Desc = "",
					Value = Bootstrap.sanitize(props.Default or "", 120),
					Placeholder = Bootstrap.sanitize(props.Placeholder or "Enter...", 80),
					Callback = Guards.wrap(props.Callback or function() end, "input:" .. flagKey),
				})
			end)
			return track(el, "input", flagKey, title, props)
		end

		function group:AddDropdown(flag, props)
			props = type(props) == "table" and props or {}
			local values = Text.sanitizeList and Text.sanitizeList(props.Values or props.Options or {}) or (props.Values or props.Options or {})
			if #values < 1 then
				return stub()
			end
			local title = Bootstrap.sanitize(props.Text or flag or "Dropdown", 80)
			if shouldSkipText(title) then
				return stub()
			end
			local defaultVal = props.Default
			if type(defaultVal) == "string" then
				defaultVal = Bootstrap.sanitize(defaultVal, 80)
			elseif type(values[1]) == "table" then
				defaultVal = values[1]
			else
				defaultVal = Bootstrap.sanitize(values[1] or "", 80)
			end
			local flagKey = Bootstrap.sanitize(flag or title, 48)
			local el
			pcall(function()
				el = box:Dropdown({
					Flag = flagKey,
					Title = title,
					Desc = "",
					Values = values,
					Value = defaultVal,
					Multi = props.Multi == true,
					Callback = Guards.wrap(props.Callback or function() end, "dropdown:" .. flagKey),
				})
			end)
			if #values > 8 and el then
				pcall(function()
					if el.SetSearchable then
						el:SetSearchable(true)
					end
				end)
			end
			local w = track(el, "dropdown", flagKey, title, props)
			function w:Refresh(_, newValues)
				pcall(function()
					local clean = Text.sanitizeList and Text.sanitizeList(newValues) or newValues
					if el and el.Refresh and type(clean) == "table" and #clean > 0 then
						el:Refresh(clean)
					end
				end)
			end
			return w
		end

		group.ForceResize = function() end
		group.UpdateSize = group.ForceResize

		return group
	end

	return Controls
end