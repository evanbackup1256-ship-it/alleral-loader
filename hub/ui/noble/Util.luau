-- Noble V8 — instance utilities, scroll, anchoring helpers
return function(Theme, Spr)
	local Util = {}
	local TextService = game:GetService("TextService")

	function Util.make(className, props)
		local obj = Instance.new(className)
		for k, v in pairs(props or {}) do
			if k == "Parent" then
				if typeof(v) == "Instance" then obj.Parent = v end
			elseif k == "Children" then
				for _, child in ipairs(v) do
					if typeof(child) == "Instance" then child.Parent = obj end
				end
			else
				pcall(function() obj[k] = v end)
			end
		end
		return obj
	end

	function Util.corner(obj, radius)
		local existing = obj:FindFirstChildOfClass("UICorner")
		if existing then existing:Destroy() end
		return Util.make("UICorner", { CornerRadius = UDim.new(0, radius or Theme.RADIUS.CARD), Parent = obj })
	end

	function Util.stroke(obj, color, thickness, transparency)
		local existing = obj:FindFirstChildOfClass("UIStroke")
		if existing then existing:Destroy() end
		return Util.make("UIStroke", {
			Color = color or Theme.COLOR.BORDER,
			Thickness = thickness or 1,
			Transparency = transparency or 0.5,
			Parent = obj,
		})
	end

	function Util.padding(obj, l, r, t, b)
		local existing = obj:FindFirstChildOfClass("UIPadding")
		if existing then existing:Destroy() end
		return Util.make("UIPadding", {
			PaddingLeft = UDim.new(0, l or 0),
			PaddingRight = UDim.new(0, r or 0),
			PaddingTop = UDim.new(0, t or 0),
			PaddingBottom = UDim.new(0, b or 0),
			Parent = obj,
		})
	end

	function Util.gradient(obj, c1, c2, rot)
		local existing = obj:FindFirstChildOfClass("UIGradient")
		if existing then existing:Destroy() end
		return Util.make("UIGradient", {
			Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0, c1 or Theme.COLOR.ACCENT),
				ColorSequenceKeypoint.new(1, c2 or Theme.COLOR.ACCENT_DARK),
			}),
			Rotation = rot or 90,
			Parent = obj,
		})
	end

	function Util.scale(obj)
		local u = obj:FindFirstChildOfClass("UIScale")
		if not u then
			u = Instance.new("UIScale")
			u.Parent = obj
		end
		return u
	end

	function Util.anchorCenter(obj)
		obj.AnchorPoint = Vector2.new(0.5, 0.5)
		return obj
	end

	function Util.spring(obj, props, preset)
		preset = preset or Theme.SPRING.SNAPPY
		Spr.target(obj, preset[1], preset[2], props)
	end

	function Util.styleScroll(sf)
		if not sf or not sf:IsA("ScrollingFrame") then return end
		sf.ScrollBarThickness = 4
		sf.ScrollBarImageColor3 = Theme.COLOR.SCROLL
		sf.ScrollBarImageTransparency = 0.4
		sf.ElasticBehavior = Enum.ElasticBehavior.Always
		sf.ScrollingEnabled = true
		sf.Active = true
		sf.BorderSizePixel = 0
		sf.MouseEnter:Connect(function()
			Spr.target(sf, 0.9, 6, { ScrollBarImageColor3 = Theme.COLOR.SCROLL_HOVER, ScrollBarImageTransparency = 0.15 })
		end)
		sf.MouseLeave:Connect(function()
			Spr.target(sf, 0.9, 6, { ScrollBarImageColor3 = Theme.COLOR.SCROLL, ScrollBarImageTransparency = 0.4 })
		end)
	end

	function Util.textSize(text, size, font, width)
		return TextService:GetTextSize(tostring(text or ""), size or Theme.TEXT_SM, font or Theme.FONT, Vector2.new(width or 200, 200))
	end

	function Util.clamp(n, a, b)
		return math.max(a, math.min(b, n))
	end

	function Util.clone(t, seen)
		if type(t) ~= "table" then return t end
		seen = seen or {}
		if seen[t] then return seen[t] end
		local c = {}
		seen[t] = c
		for k, v in pairs(t) do c[Util.clone(k, seen)] = Util.clone(v, seen) end
		return c
	end

	function Util.textOf(v)
		if v == nil then return "" end
		if type(v) == "table" then
			for _, k in ipairs({ "Text", "Content", "Description", "Message", "Title", "Name" }) do
				if v[k] ~= nil then return Util.textOf(v[k]) end
			end
		end
		return tostring(v)
	end

	return Util
end