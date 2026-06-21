-- Alleral Noble V10 — smooth scroll container
return function(deps)
	local Layout = deps.Layout
	local Theme = deps.Theme

	return function(opts)
		opts = opts or {}
		local sf = Layout.make("ScrollingFrame", {
			Name = opts.Name or "ScrollContainer",
			Size = opts.Size or UDim2.new(1, 0, 1, 0),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			ScrollBarThickness = 4,
			ScrollBarImageColor3 = Theme.COLOR.SCROLL,
			ScrollBarImageTransparency = 0.45,
			CanvasSize = UDim2.new(0, 0, 0, 0),
			AutomaticCanvasSize = opts.AutomaticCanvasSize or Enum.AutomaticSize.Y,
			ScrollingDirection = opts.ScrollingDirection or Enum.ScrollingDirection.Y,
			ElasticBehavior = Enum.ElasticBehavior.Always,
			ClipsDescendants = true,
			CanvasPosition = Vector2.new(0, 0),
			Parent = opts.Parent,
		})
		Layout.styleScroll(sf)
		if opts.Padding then
			Layout.padding(sf, opts.Padding, opts.Padding, opts.Padding, opts.Padding)
		end
		return sf
	end
end