return function(deps)
	local Utils = deps.Utils
	local Motion = deps.Motion
	local Theme = deps.Theme

	local active
	local maid

	return {
		attach = function(target, text, theme)
			if not target or not text or text == "" then
				return
			end
			theme = theme or Theme.Current or Theme.get("Midnight")
			local show
			local hide
			show = function()
				if active then
					active:Destroy()
				end
				local tip = Utils.new("Frame", {
					Name = "Tooltip",
					AnchorPoint = Vector2.new(0, 0),
					BackgroundColor3 = theme.Elevated,
					BackgroundTransparency = 1,
					BorderSizePixel = 0,
					Position = UDim2.fromOffset(target.AbsolutePosition.X, target.AbsolutePosition.Y - 28),
					Size = UDim2.fromOffset(0, 24),
					ZIndex = 500,
					Parent = target:FindFirstAncestorOfClass("ScreenGui") or target,
				})
				Utils.corner(tip, theme.CornerSm)
				Utils.stroke(tip, theme.Border, 1, 0.9)
				local label = Utils.new("TextLabel", {
					BackgroundTransparency = 1,
					Font = theme.Font,
					Text = tostring(text),
					TextColor3 = theme.Text,
					TextSize = 12,
					TextTransparency = 1,
					Size = UDim2.new(1, -12, 1, 0),
					Position = UDim2.fromOffset(6, 0),
					TextXAlignment = Enum.TextXAlignment.Left,
					Parent = tip,
				})
				active = tip
				Motion.to(tip, { BackgroundTransparency = 0.05, Size = UDim2.fromOffset(math.max(80, label.TextBounds.X + 16), 24) }, "micro")
				Motion.to(label, { TextTransparency = 0 }, "micro")
			end
			hide = function()
				if active then
					Motion.to(active, { BackgroundTransparency = 1 }, "micro", function()
						if active then
							active:Destroy()
							active = nil
						end
					end)
				end
			end
			target.MouseEnter:Connect(show)
			target.MouseLeave:Connect(hide)
		end,
	}
end
