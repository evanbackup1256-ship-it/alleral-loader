-- Alleral V11.1 — WindUI control builders (compact, guarded, no empty rows)
return function(Bootstrap, Motion, Text, Guards)
	local Controls = {}
	Text = Text or Bootstrap
	Guards = Guards or { wrap = function(fn) return fn or function() end end }

	local LAYOUT = {
		SLIDER_WIDTH = 220,
	}

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

	local function wrapElement(el, kind, flag)
		if not el then
			return stub()
		end
		if Motion and kind == "button" then
			pcall(function()
				Motion.bindHover(el, { hoverScale = 1.02, pressScale = 0.97 })
			end)
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
			if shouldSkipText(clean) then
				return
			end
			pcall(function()
				if el.Set then
					el:Set(clean)
				elseif el.SetTitle then
					el:SetTitle(clean)
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

		local function track(el, kind, flag)
			if el then
				group._controlCount = group._controlCount + 1
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
			return track(el, "label", text)
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
					Desc = Bootstrap.sanitize(props.Tooltip or props.Description or "", 100),
					Value = props.Default == true,
					Callback = Guards.wrap(props.Callback or function() end, "toggle:" .. flagKey),
				})
			end)
			return track(el, "toggle", flagKey)
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
					Desc = Bootstrap.sanitize(props.Tooltip or "", 100),
					Color = Color3.fromHex("#8B5CF6"),
					Justify = "Center",
					Callback = Guards.wrap(props.Func or props.Callback or function() end, "button:" .. title),
				})
			end)
			return track(el, "button", title)
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
					Desc = Bootstrap.sanitize(props.Tooltip or "", 100),
					Step = tonumber(props.Rounding) or 1,
					Width = LAYOUT.SLIDER_WIDTH,
					IsTooltip = true,
					IsTextbox = true,
					DisplayInTooltip = true,
					Value = {
						Min = minV,
						Max = maxV,
						Default = defV,
						DisplayMethod = "Value",
					},
					Callback = Guards.wrap(props.Callback or function() end, "slider:" .. flagKey),
				})
			end)
			return track(el, "slider", flagKey)
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
					Desc = Bootstrap.sanitize(props.Tooltip or "", 100),
					Value = Bootstrap.sanitize(props.Default or "", 120),
					Placeholder = Bootstrap.sanitize(props.Placeholder or "Enter...", 80),
					Callback = Guards.wrap(props.Callback or function() end, "input:" .. flagKey),
				})
			end)
			return track(el, "input", flagKey)
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
					Desc = Bootstrap.sanitize(props.Tooltip or "", 100),
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
			local w = track(el, "dropdown", flagKey)
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