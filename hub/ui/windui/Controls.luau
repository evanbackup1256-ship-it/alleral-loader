-- Alleral V11 — WindUI control builders (premium spacing + sanitized text)
return function(Bootstrap, Motion, Text)
	local Controls = {}
	Text = Text or Bootstrap

	local LAYOUT = {
		SECTION_GAP = 18,
		CONTROL_GAP = 12,
		SLIDER_WIDTH = 240,
		ROW_HEIGHT = 48,
	}

	local function stub()
		return {
			Set = function() end,
			SetText = function() end,
			SetVisible = function() end,
			SetValue = function() end,
			Refresh = function() end,
		}
	end

	local function wrapElement(el, kind)
		if not el then return stub() end
		if Motion then
			if kind == "button" then
				pcall(function() Motion.bindHover(el, { hoverScale = 1.02, pressScale = 0.97, brighten = true }) end)
			elseif kind == "toggle" or kind == "dropdown" then
				pcall(function() Motion.bindHover(el, { hoverScale = 1.01, pressScale = 0.98, brighten = false }) end)
			end
		end
		local api = {}
		function api:SetValue(_, v)
			pcall(function()
				if el.Set then el:Set(v)
				elseif el.SetValue then el:SetValue(v) end
			end)
		end
		function api:Set(_, v) api:SetValue(nil, v) end
		function api:SetText(_, t)
			pcall(function()
				local clean = Bootstrap.sanitize(t, 200)
				if el.Set then el:Set(clean)
				elseif el.SetTitle then el:SetTitle(clean) end
			end)
		end
		function api:SetVisible() end
		function api:Refresh(_, values)
			pcall(function()
				if el.Refresh then el:Refresh(Text.sanitizeList and Text.sanitizeList(values) or values) end
			end)
		end
		api._raw = el
		api._kind = kind
		return api
	end

	local function addSpace(box)
		pcall(function()
			if type(box.Space) == "function" then
				box:Space({ Columns = 1 })
			end
		end)
	end

	function Controls.createGroup(section, groupName)
		if not section then return nil end
		groupName = Bootstrap.sanitize(groupName, 64)

		local box = section
		if type(section.Section) == "function" then
			local ok, created = pcall(function()
				return section:Section({
					Title = groupName,
					Desc = "",
					Box = true,
					BoxBorder = true,
					Opened = true,
					FontWeight = "SemiBold",
				})
			end)
			if ok and created then
				box = created
			end
		end

		local group = {}

		function group:AddLabel(text)
			text = Bootstrap.sanitize(text, 200)
			local el
			pcall(function()
				if type(box.Paragraph) == "function" then
					el = box:Paragraph({
						Title = text,
						Desc = "",
					})
				elseif type(box.Section) == "function" then
					el = box:Section({
						Title = text,
						TextSize = 13,
						TextTransparency = 0.2,
					})
				end
			end)
			addSpace(box)
			return wrapElement(el, "label")
		end

		function group:AddDivider()
			addSpace(box)
			return {}
		end

		function group:AddToggle(flag, props)
			props = type(props) == "table" and props or {}
			local title = Bootstrap.sanitize(props.Text or flag or "Toggle", 80)
			local el
			pcall(function()
				el = box:Toggle({
					Flag = Bootstrap.sanitize(flag or title, 48),
					Title = title,
					Desc = Bootstrap.sanitize(props.Tooltip or props.Description or "", 120),
					Value = props.Default == true,
					Callback = props.Callback or function() end,
				})
			end)
			addSpace(box)
			return wrapElement(el, "toggle")
		end

		function group:AddButton(props)
			props = type(props) == "table" and props or {}
			local el
			pcall(function()
				el = box:Button({
					Title = Bootstrap.sanitize(props.Text or "Button", 80),
					Desc = Bootstrap.sanitize(props.Tooltip or "", 120),
					Color = Color3.fromHex("#8B5CF6"),
					Justify = "Center",
					Callback = props.Func or props.Callback or function() end,
				})
			end)
			addSpace(box)
			return wrapElement(el, "button")
		end

		function group:AddSlider(flag, props)
			props = type(props) == "table" and props or {}
			local minV = tonumber(props.Min) or 0
			local maxV = tonumber(props.Max) or 100
			local defV = tonumber(props.Default) or minV
			local suffix = Bootstrap.sanitize(props.Suffix or "", 16)
			local el
			pcall(function()
				el = box:Slider({
					Flag = Bootstrap.sanitize(flag or props.Text or "slider", 48),
					Title = Bootstrap.sanitize(props.Text or flag or "Slider", 80),
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
					Callback = props.Callback or function() end,
				})
			end)
			if suffix ~= "" and el and type(box.Section) == "function" then
				pcall(function()
					box:Section({
						Title = "",
						TextSize = 11,
					})
				end)
			end
			addSpace(box)
			return wrapElement(el, "slider")
		end

		function group:AddInput(flag, props)
			props = type(props) == "table" and props or {}
			local el
			pcall(function()
				el = box:Input({
					Flag = Bootstrap.sanitize(flag or props.Text or "input", 48),
					Title = Bootstrap.sanitize(props.Text or flag or "Input", 80),
					Desc = Bootstrap.sanitize(props.Tooltip or "", 100),
					Value = Bootstrap.sanitize(props.Default or "", 120),
					Placeholder = Bootstrap.sanitize(props.Placeholder or "Enter...", 80),
					Callback = props.Callback or function() end,
				})
			end)
			addSpace(box)
			return wrapElement(el, "input")
		end

		function group:AddDropdown(flag, props)
			props = type(props) == "table" and props or {}
			local values = Text.sanitizeList and Text.sanitizeList(props.Values or props.Options or {}) or (props.Values or props.Options or {})
			local defaultVal = props.Default
			if type(defaultVal) == "string" then
				defaultVal = Bootstrap.sanitize(defaultVal, 80)
			elseif type(values[1]) == "table" then
				defaultVal = values[1]
			else
				defaultVal = Bootstrap.sanitize(values[1] or "", 80)
			end
			local el
			pcall(function()
				el = box:Dropdown({
					Flag = Bootstrap.sanitize(flag or props.Text or "dropdown", 48),
					Title = Bootstrap.sanitize(props.Text or flag or "Dropdown", 80),
					Desc = Bootstrap.sanitize(props.Tooltip or "", 100),
					Values = values,
					Value = defaultVal,
					Multi = props.Multi == true,
					Callback = props.Callback or function() end,
				})
			end)
			if #values > 8 and el then
				pcall(function()
					if el.SetSearchable then el:SetSearchable(true) end
				end)
			end
			addSpace(box)
			local w = wrapElement(el, "dropdown")
			function w:Refresh(_, newValues)
				pcall(function()
					local clean = Text.sanitizeList and Text.sanitizeList(newValues) or newValues
					if el and el.Refresh then el:Refresh(clean or values) end
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