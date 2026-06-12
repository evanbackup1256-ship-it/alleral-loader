local Utils = {}

function Utils.hex(hex)
	return Color3.fromHex(hex)
end

function Utils.lerp(a, b, t)
	return a + (b - a) * t
end

function Utils.clamp(n, min, max)
	return math.clamp(n, min, max)
end

function Utils.round(n, decimals)
	local m = 10 ^ (decimals or 0)
	return math.floor(n * m + 0.5) / m
end

function Utils.new(className, props, children)
	local inst = Instance.new(className)
	if props then
		for k, v in pairs(props) do
			if k ~= "Parent" and k:sub(1, 1) ~= "_" then
				if k == "Size" or k == "Position" or k == "AnchorPoint" then
					inst[k] = v
				elseif typeof(inst[k]) == "Color3" or typeof(v) == "Color3" then
					inst[k] = v
				elseif typeof(v) == "UDim" or typeof(v) == "UDim2" then
					inst[k] = v
				else
					pcall(function()
						inst[k] = v
					end)
				end
			end
		end
	end
	if children then
		for _, child in ipairs(children) do
			if typeof(child) == "Instance" then
				child.Parent = inst
			end
		end
	end
	if props and props.Parent then
		inst.Parent = props.Parent
	end
	return inst
end

function Utils.padding(px)
	return UDim.new(0, px)
end

function Utils.offset(w, h)
	return UDim2.fromOffset(w, h)
end

function Utils.scale(x, y)
	return UDim2.fromScale(x, y or x)
end

function Utils.corner(parent, radius)
	return Utils.new("UICorner", { CornerRadius = UDim.new(0, radius), Parent = parent })
end

function Utils.stroke(parent, color, thickness, transparency)
	return Utils.new("UIStroke", {
		Color = color,
		Thickness = thickness or 1,
		Transparency = transparency or 0.9,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		Parent = parent,
	})
end

function Utils.list(parent, padding, fill)
	return Utils.new("UIListLayout", {
		SortOrder = Enum.SortOrder.LayoutOrder,
		Padding = UDim.new(0, padding or 6),
		FillDirection = fill or Enum.FillDirection.Vertical,
		Parent = parent,
	})
end

function Utils.gradient(parent, colors, rotation)
	return Utils.new("UIGradient", {
		Color = ColorSequence.new(colors),
		Rotation = rotation or 0,
		Parent = parent,
	})
end

function Utils.noiseOverlay(parent, transparency)
	local noise = Utils.new("ImageLabel", {
		Name = "Noise",
		BackgroundTransparency = 1,
		Image = "rbxassetid://6015897845",
		ImageTransparency = transparency or 0.94,
		ScaleType = Enum.ScaleType.Tile,
		TileSize = UDim2.fromOffset(128, 128),
		Size = UDim2.fromScale(1, 1),
		ZIndex = parent.ZIndex + 1,
		Parent = parent,
	})
	noise.ImageColor3 = Color3.new(1, 1, 1)
	return noise
end

function Utils.neonGlow(parent, theme, opts)
	opts = opts or {}
	local glow = Utils.new("Frame", {
		Name = "NeonGlow",
		BackgroundColor3 = theme.AccentGlow,
		BackgroundTransparency = opts.transparency or 0.88,
		BorderSizePixel = 0,
		Size = UDim2.new(1, opts.expand or 8, 1, opts.expand or 8),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		ZIndex = math.max(0, parent.ZIndex - 1),
		Parent = parent,
	})
	Utils.corner(glow, (opts.radius or theme.CornerSm) + 4)
	return glow
end

function Utils.acrylicLayer(parent, theme, radius)
	local veil = Utils.new("Frame", {
		Name = "Acrylic",
		BackgroundColor3 = theme.Surface,
		BackgroundTransparency = theme.GlassTransparency or 0.12,
		BorderSizePixel = 0,
		Size = UDim2.fromScale(1, 1),
		ZIndex = parent.ZIndex,
		Parent = parent,
	})
	Utils.corner(veil, radius or theme.Corner)
	Utils.gradient(veil, {
		Color3.fromRGB(255, 255, 255),
		Color3.fromRGB(255, 255, 255),
	}, 90).Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.96),
		NumberSequenceKeypoint.new(0.5, 0.98),
		NumberSequenceKeypoint.new(1, 0.94),
	})
	Utils.stroke(veil, theme.Border, 1, theme.BorderAlpha or 0.92)
	Utils.noiseOverlay(veil, 0.95)
	return veil
end

function Utils.glassPanel(parent, theme, cornerRadius)
	return Utils.acrylicLayer(parent, theme, cornerRadius)
end

function Utils.accentEdge(parent, theme, side)
	side = side or "left"
	local edge = Utils.new("Frame", {
		Name = "AccentEdge",
		BackgroundColor3 = theme.Accent,
		BorderSizePixel = 0,
		ZIndex = parent.ZIndex + 2,
		Parent = parent,
	})
	Utils.gradient(edge, { theme.Accent, theme.AccentSoft }, 90)
	if side == "left" then
		edge.Size = UDim2.new(0, 2, 1, -8)
		edge.Position = UDim2.fromOffset(0, 4)
	elseif side == "top" then
		edge.Size = UDim2.new(1, -8, 0, 2)
		edge.Position = UDim2.fromOffset(4, 0)
	end
	Utils.corner(edge, 2)
	return edge
end

function Utils.groupboxHeader(parent, theme, title)
	local header = Utils.new("Frame", {
		Name = "GroupHeader",
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 22),
		Parent = parent,
	})
	Utils.accentEdge(header, theme, "top")
	Utils.new("TextLabel", {
		BackgroundTransparency = 1,
		Font = theme.FontBold,
		Text = tostring(title or "Section"),
		TextColor3 = theme.Text,
		TextSize = 12,
		TextXAlignment = Enum.TextXAlignment.Left,
		Position = UDim2.fromOffset(2, 6),
		Size = UDim2.new(1, -4, 0, 14),
		Parent = header,
	})
	return header
end

function Utils.bindHoverScale(motion, instance, scale, profile)
	local base = instance.Size
	local hover = UDim2.fromOffset(math.floor(base.X.Offset * scale), math.floor(base.Y.Offset * scale))
	local enter = function()
		motion.to(instance, { Size = hover }, profile or "hover")
	end
	local leave = function()
		motion.to(instance, { Size = base }, profile or "soft")
	end
	instance.MouseEnter:Connect(enter)
	instance.MouseLeave:Connect(leave)
	return { enter = enter, leave = leave }
end

function Utils.bindHoverTint(motion, instance, theme, active)
	local off = theme.Elevated
	local on = theme.CardHover
	instance.MouseEnter:Connect(function()
		motion.to(instance, { BackgroundColor3 = on }, "micro")
	end)
	instance.MouseLeave:Connect(function()
		if not active then
			motion.to(instance, { BackgroundColor3 = off }, "micro")
		end
	end)
end

function Utils.ripple(motion, parent, input, color)
	local ripple = Utils.new("Frame", {
		Name = "Ripple",
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundColor3 = color,
		BackgroundTransparency = 0.65,
		BorderSizePixel = 0,
		Position = UDim2.fromOffset(
			input.Position.X - parent.AbsolutePosition.X,
			input.Position.Y - parent.AbsolutePosition.Y
		),
		Size = UDim2.fromOffset(2, 2),
		ZIndex = parent.ZIndex + 3,
		Parent = parent,
	})
	Utils.corner(ripple, 999)
	motion.to(ripple, { Size = UDim2.fromOffset(90, 90), BackgroundTransparency = 1 }, "micro", function()
		ripple:Destroy()
	end)
end

function Utils.safeCallback(label, fn)
	return function(...)
		local ok, err = pcall(fn, ...)
		if not ok then
			warn("[Alleral UI:" .. tostring(label) .. "] " .. tostring(err))
		end
	end
end

return Utils
