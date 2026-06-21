-- Alleral V11.3 — WindUI control builders (compact, guarded, tooltips)
return function(Bootstrap, Motion, Text, Guards, TooltipManager)
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

		local function bindTooltip(el, kind, title, props, flagKey)
			if not TooltipManager or not el then
				return
			end
			local desc = props.Tooltip or props.Description or props.Desc or ""
			if desc == "" and title ~= "" then
				desc = "Toggle, adjust, or interact with " .. title .. "."
			end
			local meta = type(props.TooltipMeta) == "table" and props.TooltipMeta or {
				title = title,
				description = desc,
				configKey = flagKey,
				value = props.Default,
			}
			task.defer(function()
				pcall(function()
					TooltipManager.attach(el, meta, kind, groupName, title)
				end)
			end)
		end

		local function track(el, kind, flag, title, props)
			if el then
				group._controlCount = group._controlCount + 1
				bindTooltip(el, kind, title, props or {}, flag)
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
					Color = Color3.fromHex("#8B5CF6"),
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