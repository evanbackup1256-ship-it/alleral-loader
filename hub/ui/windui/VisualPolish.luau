-- Alleral V11.5 — ambient window polish (border glow, sidebar accent, depth layers)
return function(Theme)
	local VisualPolish = {}
	local TweenService = game:GetService("TweenService")

	local bound = {}

	local function colors()
		if Theme and Theme.colors then
			return Theme.colors()
		end
		return {
			Accent = "#8B5CF6",
			Cyan = "#22D3EE",
			Glow = "#6366F1",
			Background = "#030508",
		}
	end

	local function hex(h)
		return Color3.fromHex(h)
	end

	local function getRoot(windWindow)
		local root = windWindow and windWindow.UIElements and windWindow.UIElements.Main
		if typeof(root) == "Instance" then
			return root
		end
		return nil
	end

	local function ensureCorner(frame, radius)
		local corner = frame:FindFirstChild("AlleralCorner")
		if corner and corner:IsA("UICorner") then
			return corner
		end
		corner = Instance.new("UICorner")
		corner.Name = "AlleralCorner"
		corner.CornerRadius = UDim.new(0, radius or 10)
		corner.Parent = frame
		return corner
	end

	local function addAmbientGlow(root, C)
		if root:FindFirstChild("AlleralAmbientGlow") then
			return
		end
		local glow = Instance.new("Frame")
		glow.Name = "AlleralAmbientGlow"
		glow.AnchorPoint = Vector2.new(0.5, 0.5)
		glow.Position = UDim2.fromScale(0.5, 0.5)
		glow.Size = UDim2.new(1, 48, 1, 48)
		glow.BackgroundColor3 = hex(C.Glow)
		glow.BackgroundTransparency = 0.82
		glow.BorderSizePixel = 0
		glow.ZIndex = math.max(0, (root.ZIndex or 1) - 2)
		glow.Parent = root

		local grad = Instance.new("UIGradient")
		grad.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, hex(C.Accent)),
			ColorSequenceKeypoint.new(0.5, hex(C.Glow)),
			ColorSequenceKeypoint.new(1, hex(C.Cyan)),
		})
		grad.Rotation = 135
		grad.Parent = glow

		ensureCorner(glow, 14)

		local pulse = TweenService:Create(
			glow,
			TweenInfo.new(3.2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
			{ BackgroundTransparency = 0.9 }
		)
		pulse:Play()
	end

	local function addWindowBorder(root, C)
		if root:FindFirstChild("AlleralWindowBorder") then
			return
		end
		local stroke = Instance.new("UIStroke")
		stroke.Name = "AlleralWindowBorder"
		stroke.Color = hex(C.Accent)
		stroke.Thickness = 1.4
		stroke.Transparency = 0.55
		stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		stroke.LineJoinMode = Enum.LineJoinMode.Round
		stroke.Parent = root

		local shimmer = TweenService:Create(
			stroke,
			TweenInfo.new(2.8, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
			{
				Transparency = 0.72,
				Color = hex(C.Cyan),
			}
		)
		shimmer:Play()
	end

	local function addSidebarAccent(root, C)
		if root:FindFirstChild("AlleralSidebarAccent") then
			return
		end
		local sidebar
		for _, desc in ipairs(root:GetDescendants()) do
			if desc:IsA("GuiObject") then
				local name = desc.Name:lower()
				if name:find("sidebar", 1, true) or name:find("side bar", 1, true) then
					sidebar = desc
					break
				end
			end
		end
		if not sidebar then
			return
		end

		local accent = Instance.new("Frame")
		accent.Name = "AlleralSidebarAccent"
		accent.AnchorPoint = Vector2.new(1, 0)
		accent.Position = UDim2.new(1, 0, 0, 12)
		accent.Size = UDim2.new(0, 2, 1, -24)
		accent.BackgroundColor3 = hex(C.Accent)
		accent.BackgroundTransparency = 0.35
		accent.BorderSizePixel = 0
		accent.ZIndex = (sidebar.ZIndex or 1) + 2
		accent.Parent = sidebar

		local grad = Instance.new("UIGradient")
		grad.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, hex(C.Cyan)),
			ColorSequenceKeypoint.new(0.5, hex(C.Accent)),
			ColorSequenceKeypoint.new(1, hex(C.Glow)),
		})
		grad.Rotation = 90
		grad.Parent = accent

		ensureCorner(accent, 2)
	end

	local function addContentSheen(root, C)
		if root:FindFirstChild("AlleralContentSheen") then
			return
		end
		local panel
		for _, desc in ipairs(root:GetDescendants()) do
			if desc:IsA("GuiObject") then
				local name = desc.Name:lower()
				if name:find("content", 1, true) or name:find("mainpanel", 1, true) or name:find("tabcontent", 1, true) then
					panel = desc
					break
				end
			end
		end
		if not panel then
			panel = root
		end

		local sheen = Instance.new("Frame")
		sheen.Name = "AlleralContentSheen"
		sheen.AnchorPoint = Vector2.new(0.5, 0)
		sheen.Position = UDim2.fromScale(0.5, 0)
		sheen.Size = UDim2.new(1, 0, 0, 120)
		sheen.BackgroundColor3 = hex(C.Cyan)
		sheen.BackgroundTransparency = 0.94
		sheen.BorderSizePixel = 0
		sheen.ZIndex = (panel.ZIndex or 1) + 1
		sheen.Parent = panel

		local grad = Instance.new("UIGradient")
		grad.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.2),
			NumberSequenceKeypoint.new(1, 1),
		})
		grad.Rotation = 90
		grad.Parent = sheen
	end

	local function applyLayers(windWindow)
		local root = getRoot(windWindow)
		if not root then
			return false
		end
		local C = colors()
		pcall(function() addAmbientGlow(root, C) end)
		pcall(function() addWindowBorder(root, C) end)
		pcall(function() addSidebarAccent(root, C) end)
		pcall(function() addContentSheen(root, C) end)
		ensureCorner(root, 10)
		return true
	end

	function VisualPolish.bind(windWindow)
		if not windWindow or bound[windWindow] then
			return
		end
		bound[windWindow] = true

		task.spawn(function()
			for _ = 1, 60 do
				if applyLayers(windWindow) then
					pcall(function()
						local Log = getgenv and getgenv().Alleral_Log
						if Log and Log.info then
							Log.info("Visual polish active (aurora glass)")
						end
					end)
					return
				end
				task.wait(0.1)
			end
		end)
	end

	return VisualPolish
end