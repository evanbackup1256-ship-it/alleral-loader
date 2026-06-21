-- Alleral V11 — WindUI control builders (groupbox API for games)
return function(Bootstrap)
	local Controls = {}

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
				if el.Set then el:Set(tostring(t or ""))
				elseif el.SetTitle then el:SetTitle(tostring(t or "")) end
			end)
		end
		function api:SetVisible() end
		function api:Refresh(_, values)
			pcall(function()
				if el.Refresh then el:Refresh(values) end
			end)
		end
		api._raw = el
		api._kind = kind
		return api
	end

	function Controls.createGroup(section, groupName)
		if not section then return nil end

		local box = section
		if type(section.Section) == "function" then
			local ok, created = pcall(function()
				return section:Section({
					Title = tostring(groupName or "Group"),
					Box = true,
					BoxBorder = true,
					Opened = true,
				})
			end)
			if ok and created then
				box = created
			end
		end

		local group = {}

		function group:AddLabel(text)
			text = Bootstrap.safeText(text, 200)
			local el
			pcall(function()
				if type(box.Section) == "function" then
					el = box:Section({ Title = text, TextSize = 13 })
				elseif type(box.Paragraph) == "function" then
					el = box:Paragraph({ Title = text })
				end
			end)
			return wrapElement(el, "label")
		end

		function group:AddDivider()
			pcall(function()
				if type(box.Space) == "function" then box:Space() end
			end)
			return {}
		end

		function group:AddToggle(flag, props)
			props = type(props) == "table" and props or {}
			local el
			pcall(function()
				el = box:Toggle({
					Flag = tostring(flag or props.Text or "toggle"),
					Title = Bootstrap.safeText(props.Text or flag or "Toggle", 80),
					Value = props.Default == true,
					Callback = props.Callback or function() end,
				})
			end)
			return wrapElement(el, "toggle")
		end

		function group:AddButton(props)
			props = type(props) == "table" and props or {}
			local el
			pcall(function()
				el = box:Button({
					Title = Bootstrap.safeText(props.Text or "Button", 80),
					Callback = props.Func or props.Callback or function() end,
				})
			end)
			return wrapElement(el, "button")
		end

		function group:AddSlider(flag, props)
			props = type(props) == "table" and props or {}
			local minV = tonumber(props.Min) or 0
			local maxV = tonumber(props.Max) or 100
			local defV = tonumber(props.Default) or minV
			local el
			pcall(function()
				el = box:Slider({
					Flag = tostring(flag or props.Text or "slider"),
					Title = Bootstrap.safeText(props.Text or flag or "Slider", 80),
					Step = tonumber(props.Rounding) or 1,
					Value = { Min = minV, Max = maxV, Default = defV },
					Callback = props.Callback or function() end,
				})
			end)
			return wrapElement(el, "slider")
		end

		function group:AddInput(flag, props)
			props = type(props) == "table" and props or {}
			local el
			pcall(function()
				el = box:Input({
					Flag = tostring(flag or props.Text or "input"),
					Title = Bootstrap.safeText(props.Text or flag or "Input", 80),
					Value = tostring(props.Default or ""),
					Placeholder = tostring(props.Placeholder or "Enter..."),
					Callback = props.Callback or function() end,
				})
			end)
			return wrapElement(el, "input")
		end

		function group:AddDropdown(flag, props)
			props = type(props) == "table" and props or {}
			local values = props.Values or props.Options or {}
			local el
			pcall(function()
				el = box:Dropdown({
					Flag = tostring(flag or props.Text or "dropdown"),
					Title = Bootstrap.safeText(props.Text or flag or "Dropdown", 80),
					Values = values,
					Value = props.Default or (type(values[1]) == "table" and values[1].Title or values[1]),
					Multi = props.Multi == true,
					Callback = props.Callback or function() end,
				})
			end)
			local w = wrapElement(el, "dropdown")
			function w:Refresh(_, newValues)
				pcall(function()
					if el and el.Refresh then el:Refresh(newValues or values) end
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