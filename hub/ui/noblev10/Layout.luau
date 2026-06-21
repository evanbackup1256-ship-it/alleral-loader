-- Alleral Noble V10 — layout utilities, instance helpers, responsive sizing
return function(Theme, Motion)
	local Layout = {}
	local TextService = game:GetService("TextService")

	function Layout.make(className, props)
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

	function Layout.num(value, fallback, label)
		local n = tonumber(value)
		if n == nil then
			if label then warn("[Alleral V10] Missing numeric:", label, "→", fallback) end
			return fallback
		end
		return n
	end

	function Layout.radius(token, fallback)
		if type(token) == "number" then return token end
		return fallback or Theme.RADIUS.Card or 12
	end

	function Layout.absSize(gui, fallbackW, fallbackH)
		fallbackW = Layout.num(fallbackW, 1200, nil)
		fallbackH = Layout.num(fallbackH, 720, nil)
		if typeof(gui) ~= "Instance" or not gui:IsA("GuiObject") then
			return fallbackW, fallbackH
		end
		local w = Layout.num(gui.AbsoluteSize.X, 0, nil)
		local h = Layout.num(gui.AbsoluteSize.Y, 0, nil)
		if w <= 0 then w = fallbackW end
		if h <= 0 then h = fallbackH end
		return w, h
	end

	function Layout.corner(obj, radius)
		if not obj then return nil end
		radius = Layout.radius(radius, Theme.RADIUS.Card)
		if radius >= 900 then
			local existing = obj:FindFirstChildOfClass("UICorner")
			if existing then existing:Destroy() end
			return nil
		end
		local existing = obj:FindFirstChildOfClass("UICorner")
		if existing then existing:Destroy() end
		return Layout.make("UICorner", { CornerRadius = UDim.new(0, radius), Parent = obj })
	end

	function Layout.stroke(obj, color, thickness, transparency)
		if not obj then return nil end
		local existing = obj:FindFirstChildOfClass("UIStroke")
		if existing then existing:Destroy() end
		return Layout.make("UIStroke", {
			Color = color or Theme.COLOR.Border,
			Thickness = thickness or Theme.STROKE.Thickness or 1,
			Transparency = transparency or Theme.STROKE.Transparency or 0.82,
			Parent = obj,
		})
	end

	function Layout.softStroke(obj, color)
		return Layout.stroke(obj, color or Theme.COLOR.BorderSoft, 1, Theme.STROKE.Transparency or 0.82)
	end

	function Layout.shadow(parent, radius, offset, transparency)
		if not parent then return nil end
		radius = Layout.radius(radius, Theme.RADIUS.Card)
		local shadow = Layout.make("Frame", {
			Size = UDim2.new(1, 8, 1, 8),
			Position = UDim2.new(0, Layout.num(offset, 2, nil), 0, Layout.num(offset, 3, nil)),
			BackgroundColor3 = Theme.COLOR.Shadow,
			BackgroundTransparency = Layout.num(transparency, 0.55, nil),
			BorderSizePixel = 0,
			ZIndex = math.max(0, (parent.ZIndex or 1) - 1),
			Parent = parent,
		})
		Layout.corner(shadow, radius)
		return shadow
	end

	function Layout.padding(obj, l, r, t, b)
		local existing = obj:FindFirstChildOfClass("UIPadding")
		if existing then existing:Destroy() end
		return Layout.make("UIPadding", {
			PaddingLeft = UDim.new(0, l or 0),
			PaddingRight = UDim.new(0, r or 0),
			PaddingTop = UDim.new(0, t or 0),
			PaddingBottom = UDim.new(0, b or 0),
			Parent = obj,
		})
	end

	function Layout.gradient(obj, c1, c2, rot)
		local existing = obj:FindFirstChildOfClass("UIGradient")
		if existing then existing:Destroy() end
		return Layout.make("UIGradient", {
			Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0, c1 or Theme.COLOR.Accent),
				ColorSequenceKeypoint.new(1, c2 or Theme.COLOR.Accent2),
			}),
			Rotation = rot or 90,
			Parent = obj,
		})
	end

	function Layout.scale(obj)
		local u = obj:FindFirstChildOfClass("UIScale")
		if not u then
			u = Instance.new("UIScale")
			u.Parent = obj
		end
		return u
	end

	function Layout.clamp(n, a, b)
		return math.max(a, math.min(b, n))
	end

	function Layout.clone(t, seen)
		if type(t) ~= "table" then return t end
		seen = seen or {}
		if seen[t] then return seen[t] end
		local c = {}
		seen[t] = c
		for k, v in pairs(t) do c[Layout.clone(k, seen)] = Layout.clone(v, seen) end
		return c
	end

	function Layout.textOf(v)
		if v == nil then return "" end
		if type(v) == "table" then
			for _, k in ipairs({ "Text", "Content", "Description", "Message", "Title", "Name" }) do
				if v[k] ~= nil then return Layout.textOf(v[k]) end
			end
		end
		return tostring(v)
	end

	function Layout.textSize(text, size, font, width)
		return TextService:GetTextSize(tostring(text or ""), size or Theme.TEXT_SM, font or Theme.FONT, Vector2.new(width or 200, 200))
	end

	function Layout.getViewport()
		local cam = workspace.CurrentCamera
		if cam then return cam.ViewportSize.X, cam.ViewportSize.Y end
		return 1920, 1080
	end

	function Layout.computeWindowSize(vpX, vpY, settings)
		settings = settings or {}
		if settings.Size then return settings.Size end
		local w = Layout.clamp(math.floor(vpX * Theme.WINDOW.WIDTH_PCT), Theme.WINDOW.MIN_W, Theme.WINDOW.MAX_W)
		local h = Layout.clamp(math.floor(vpY * Theme.WINDOW.HEIGHT_PCT), Theme.WINDOW.MIN_H, math.floor(vpY * 0.9))
		return UDim2.fromOffset(w, h)
	end

	function Layout.computeResponsiveScale(vpX, vpY)
		local baseW, baseH = 1280, 760
		local scale = math.min(vpX / baseW, vpY / baseH)
		if vpX < 900 or vpY < 600 then scale = math.min(scale, 0.72)
		elseif vpX < 1100 then scale = math.min(scale, 0.82)
		elseif vpX > 2200 then scale = math.min(scale, 1.06) end
		return Layout.clamp(scale, 0.58, 1.08)
	end

	function Layout.styleScroll(sf)
		if not sf or not sf:IsA("ScrollingFrame") then return end
		sf.ScrollBarThickness = 4
		sf.ScrollBarImageColor3 = Theme.COLOR.SCROLL
		sf.ScrollBarImageTransparency = 0.45
		sf.ElasticBehavior = Enum.ElasticBehavior.Always
		sf.ScrollingEnabled = true
		sf.Active = true
		sf.BorderSizePixel = 0
		sf.CanvasPosition = Vector2.new(0, 0)
		sf.MouseEnter:Connect(function()
			Motion.spring(sf, { ScrollBarImageColor3 = Theme.COLOR.SCROLL_HOVER, ScrollBarImageTransparency = 0.12 })
		end)
		sf.MouseLeave:Connect(function()
			Motion.spring(sf, { ScrollBarImageColor3 = Theme.COLOR.SCROLL, ScrollBarImageTransparency = 0.45 })
		end)
	end

	function Layout.createGlassCard(parent, opts)
		opts = opts or {}
		local r = Layout.radius(opts.Radius or Theme.CARD.RADIUS, 12)
		local card = Layout.make("Frame", {
			Size = opts.Size or UDim2.new(1, 0, 0, 0),
			AutomaticSize = opts.AutomaticSize or Enum.AutomaticSize.Y,
			BackgroundColor3 = Theme.COLOR.Surface1,
			BackgroundTransparency = opts.Transparency or 0.04,
			BorderSizePixel = 0,
			ClipsDescendants = true,
			ZIndex = opts.ZIndex or 20,
			Parent = parent,
		})
		Layout.corner(card, r)
		Layout.shadow(card, r, 2, 0.62)
		Layout.make("Frame", {
			Size = UDim2.new(1, 0, 0, 1),
			Position = UDim2.new(0, 0, 0, 0),
			BackgroundColor3 = Theme.COLOR.Accent,
			BackgroundTransparency = 0.55,
			BorderSizePixel = 0,
			ZIndex = card.ZIndex + 1,
			Parent = card,
		})
		Layout.gradient(card, Theme.COLOR.Surface1, Theme.COLOR.Surface0, 180)
		card.MouseEnter:Connect(function()
			Motion.spring(card, { BackgroundTransparency = 0.01 })
		end)
		card.MouseLeave:Connect(function()
			Motion.spring(card, { BackgroundTransparency = opts.Transparency or 0.04 })
		end)
		return card
	end

	return Layout
end