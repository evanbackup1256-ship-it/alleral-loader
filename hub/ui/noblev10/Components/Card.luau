-- Alleral Noble V10 — glass dashboard card
return function(deps)
	local Layout = deps.Layout
	local Theme = deps.Theme

	return function(opts)
		opts = opts or {}
		local parent = opts.Parent or opts.parent
		local card = Layout.createGlassCard(parent, opts)
		if opts.Title and card then
			local title = Layout.make("TextLabel", {
				Size = UDim2.new(1, -Theme.CARD.PAD * 2, 0, Theme.CARD.TITLE_H),
				Position = UDim2.new(0, Theme.CARD.PAD, 0, Theme.SPACE.MD),
				BackgroundTransparency = 1,
				Text = deps.Validation and deps.Validation.sanitizeText(opts.Title) or tostring(opts.Title),
				TextColor3 = Theme.COLOR.Text,
				Font = Theme.FONT_BOLD,
				TextSize = Theme.TEXT_TITLE,
				TextXAlignment = Enum.TextXAlignment.Left,
				ZIndex = (opts.ZIndex or 20) + 2,
				Parent = card,
			})
			return card, title
		end
		return card
	end
end