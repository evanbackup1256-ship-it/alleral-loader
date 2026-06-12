return function(deps)
	local Utils = deps.Utils
	local Motion = deps.Motion
	local Theme = deps.Theme
	local Maid = deps.Maid
	local Icons = deps.Icons

	local palette
	local maid
	local commands = {}

	return {
		register = function(cmd)
			if type(cmd) == "table" and cmd.Name then
				table.insert(commands, cmd)
			end
		end,
		toggle = function(root, theme)
			theme = theme or Theme.Current or Theme.get("Midnight")
			if palette and palette.Parent then
				Motion.to(palette, { Position = UDim2.fromScale(0.5, 0.46), BackgroundTransparency = 1 }, "close", function()
					palette:Destroy()
					palette = nil
				end)
				return
			end
			maid = Maid.new()
			palette = Utils.new("Frame", {
				Name = "CommandPalette",
				AnchorPoint = Vector2.new(0.5, 0.5),
				BackgroundColor3 = theme.Card,
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				Position = UDim2.fromScale(0.5, 0.46),
				Size = UDim2.fromOffset(420, 280),
				ZIndex = 350,
				Parent = root,
			})
			Utils.corner(palette, theme.CornerLg)
			Utils.stroke(palette, theme.Border, 1, 0.88)
			Utils.glassPanel(palette, theme, theme.CornerLg)
			local search = Utils.new("TextBox", {
				BackgroundTransparency = 1,
				Font = theme.Font,
				PlaceholderText = "Search commands...",
				Text = "",
				TextColor3 = theme.Text,
				TextSize = 14,
				Position = UDim2.fromOffset(40, 12),
				Size = UDim2.new(1, -52, 0, 32),
				Parent = palette,
			})
			local searchIcon = Icons.image(palette, "search", UDim2.fromOffset(16, 16))
			searchIcon.Position = UDim2.fromOffset(14, 20)
			local list = Utils.new("ScrollingFrame", {
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				CanvasSize = UDim2.fromOffset(0, 0),
				Position = UDim2.fromOffset(8, 52),
				ScrollBarThickness = 2,
				Size = UDim2.new(1, -16, 1, -60),
				Parent = palette,
			})
			Utils.list(list, 2)
			local function render(filter)
				for _, child in ipairs(list:GetChildren()) do
					if child:IsA("GuiObject") and child.Name == "Cmd" then
						child:Destroy()
					end
				end
				local shown = 0
				for i, cmd in ipairs(commands) do
					local name = tostring(cmd.Name)
					if filter == "" or name:lower():find(filter:lower(), 1, true) then
						shown += 1
						local item = Utils.new("TextButton", {
							Name = "Cmd",
							AutoButtonColor = false,
							BackgroundColor3 = theme.Surface,
							BackgroundTransparency = 0.5,
							Font = theme.Font,
							Text = "  " .. name,
							TextColor3 = theme.Text,
							TextSize = 13,
							TextXAlignment = Enum.TextXAlignment.Left,
							Size = UDim2.new(1, 0, 0, 32),
							LayoutOrder = shown,
							Parent = list,
						})
						Utils.corner(item, theme.CornerSm)
						item.MouseButton1Click:Connect(function()
							if cmd.Callback then
								cmd.Callback()
							end
							palette:Destroy()
							palette = nil
						end)
					end
				end
				list.CanvasSize = UDim2.fromOffset(0, shown * 34)
			end
			search:GetPropertyChangedSignal("Text"):Connect(function()
				render(search.Text)
			end)
			render("")
			Motion.to(palette, { BackgroundTransparency = 0.02, Position = UDim2.fromScale(0.5, 0.5) }, "modal")
			maid:GiveInstance(palette)
		end,
	}
end
