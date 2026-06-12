return function(deps)
	local Utils = deps.Utils
	local Motion = deps.Motion
	local Theme = deps.Theme
	local Maid = deps.Maid

	local holder
	local maid = Maid.new()

	local function ensureHolder(root)
		if holder and holder.Parent then
			return holder
		end
		holder = Utils.new("Frame", {
			Name = "Notifications",
			BackgroundTransparency = 1,
			Position = UDim2.new(1, -10, 0, 10),
			AnchorPoint = Vector2.new(1, 0),
			Size = UDim2.fromOffset(300, 420),
			ZIndex = 400,
			Parent = root,
		})
		Utils.list(holder, 6)
		maid:GiveInstance(holder)
		return holder
	end

	local Notification = {}

	function Notification.push(root, data, theme)
		theme = theme or Theme.Current or Theme.get("Private")
		local host = ensureHolder(root)
		local accent = theme.Accent
		if data.Type == "error" or data.type == "error" then
			accent = theme.Error
		elseif data.Type == "warning" or data.type == "warning" then
			accent = theme.Warning
		elseif data.Type == "success" or data.type == "success" then
			accent = theme.Success
		end

		local card = Utils.new("Frame", {
			Name = "Notification",
			BackgroundColor3 = theme.Card,
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			Size = UDim2.new(1, 0, 0, 56),
			LayoutOrder = math.floor(tick() * 1000),
			Parent = host,
		})
		Utils.corner(card, theme.CornerSm)
		Utils.stroke(card, theme.Border, 1, 0.92)
		Utils.acrylicLayer(card, theme, theme.CornerSm)

		local bar = Utils.new("Frame", {
			BackgroundColor3 = accent,
			BorderSizePixel = 0,
			Size = UDim2.new(0, 2, 1, -10),
			Position = UDim2.fromOffset(5, 5),
			ZIndex = 2,
			Parent = card,
		})
		Utils.corner(bar, 2)
		Utils.neonGlow(bar, theme, { transparency = 0.5, expand = 3, radius = 2 })
		bar.BackgroundColor3 = accent

		Utils.new("TextLabel", {
			Name = "Title",
			BackgroundTransparency = 1,
			Font = theme.FontBold,
			Text = tostring(data.Title or "Alleral"),
			TextColor3 = theme.Text,
			TextSize = 12,
			TextXAlignment = Enum.TextXAlignment.Left,
			Position = UDim2.fromOffset(14, 7),
			Size = UDim2.new(1, -20, 0, 16),
			Parent = card,
		})
		Utils.new("TextLabel", {
			Name = "Body",
			BackgroundTransparency = 1,
			Font = theme.Font,
			Text = tostring(data.Description or data.Content or data.Text or ""),
			TextColor3 = theme.Muted,
			TextSize = 11,
			TextWrapped = true,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextYAlignment = Enum.TextYAlignment.Top,
			Position = UDim2.fromOffset(14, 22),
			Size = UDim2.new(1, -20, 1, -26),
			Parent = card,
		})

		card.Position = UDim2.new(1, 32, 0, 0)
		local baseSize = card.Size
		card.Size = UDim2.new(1, 0, 0, 48)
		Motion.to(card, {
			BackgroundTransparency = 0.06,
			Position = UDim2.new(0, 0, 0, 0),
			Size = baseSize,
		}, "notify")

		local duration = tonumber(data.Duration or data.Time) or 4
		task.delay(duration, function()
			if card.Parent then
				Motion.to(card, {
					BackgroundTransparency = 1,
					Position = UDim2.new(1, 32, 0, 0),
					Size = UDim2.new(1, 0, 0, 40),
				}, "close", function()
					card:Destroy()
				end)
			end
		end)
		return card
	end

	function Notification.destroy()
		maid:Destroy()
		holder = nil
	end

	return Notification
end
