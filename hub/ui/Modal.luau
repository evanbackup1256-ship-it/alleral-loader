return function(deps)
	local Utils = deps.Utils
	local Motion = deps.Motion
	local Theme = deps.Theme
	local Maid = deps.Maid

	return {
		open = function(root, data, theme)
			theme = theme or Theme.Current or Theme.get("Midnight")
			local maid = Maid.new()
			local veil = Utils.new("TextButton", {
				Name = "ModalVeil",
				AutoButtonColor = false,
				BackgroundColor3 = Color3.new(0, 0, 0),
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				Size = UDim2.fromScale(1, 1),
				Text = "",
				ZIndex = 300,
				Parent = root,
			})
			local panel = Utils.new("Frame", {
				Name = "Modal",
				AnchorPoint = Vector2.new(0.5, 0.5),
				BackgroundColor3 = theme.Card,
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				Position = UDim2.fromScale(0.5, 0.52),
				Size = UDim2.fromOffset(360, 180),
				ZIndex = 301,
				Parent = root,
			})
			Utils.corner(panel, theme.CornerLg)
			Utils.stroke(panel, theme.Border, 1, 0.88)
			Utils.glassPanel(panel, theme, theme.CornerLg)
			Utils.new("TextLabel", {
				BackgroundTransparency = 1,
				Font = theme.FontBold,
				Text = tostring(data.Title or "Confirm"),
				TextColor3 = theme.Text,
				TextSize = 16,
				Position = UDim2.fromOffset(20, 16),
				Size = UDim2.new(1, -40, 0, 24),
				TextXAlignment = Enum.TextXAlignment.Left,
				Parent = panel,
			})
			Utils.new("TextLabel", {
				BackgroundTransparency = 1,
				Font = theme.Font,
				Text = tostring(data.Description or data.Content or ""),
				TextColor3 = theme.Muted,
				TextSize = 13,
				TextWrapped = true,
				Position = UDim2.fromOffset(20, 48),
				Size = UDim2.new(1, -40, 1, -90),
				TextXAlignment = Enum.TextXAlignment.Left,
				TextYAlignment = Enum.TextYAlignment.Top,
				Parent = panel,
			})
			local actions = Utils.new("Frame", {
				BackgroundTransparency = 1,
				Position = UDim2.new(0, 20, 1, -52),
				Size = UDim2.new(1, -40, 0, 36),
				Parent = panel,
			})
			Utils.list(actions, 8, Enum.FillDirection.Horizontal)
			local function close()
				Motion.to(veil, { BackgroundTransparency = 1 }, "close")
				Motion.to(panel, { BackgroundTransparency = 1, Position = UDim2.fromScale(0.5, 0.56) }, "modal", function()
					maid:Destroy()
				end)
			end
			local cancel = Utils.new("TextButton", {
				BackgroundColor3 = theme.TrackOff,
				AutoButtonColor = false,
				Font = theme.Font,
				Text = data.CancelText or "Cancel",
				TextColor3 = theme.Text,
				TextSize = 13,
				Size = UDim2.new(0.5, -4, 1, 0),
				Parent = actions,
			})
			Utils.corner(cancel, theme.CornerSm)
			local confirm = Utils.new("TextButton", {
				BackgroundColor3 = theme.Accent,
				AutoButtonColor = false,
				Font = theme.FontBold,
				Text = data.ConfirmText or "Confirm",
				TextColor3 = theme.Canvas,
				TextSize = 13,
				Size = UDim2.new(0.5, -4, 1, 0),
				Parent = actions,
			})
			Utils.corner(confirm, theme.CornerSm)
			cancel.MouseButton1Click:Connect(close)
			confirm.MouseButton1Click:Connect(function()
				if data.OnConfirm then
					data.OnConfirm()
				end
				close()
			end)
			veil.MouseButton1Click:Connect(close)
			Motion.to(veil, { BackgroundTransparency = 0.45 }, "open")
			Motion.to(panel, { BackgroundTransparency = 0.02, Position = UDim2.fromScale(0.5, 0.5) }, "modal")
			maid:GiveInstance(veil)
			maid:GiveInstance(panel)
			return { Close = close, Maid = maid }
		end,
	}
end
