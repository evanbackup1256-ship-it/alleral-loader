-- Alleral V11.6 — window frame polish (no backdrop overflow)
return function(Theme)
	local VisualPolish = {}
	local bound = {}

	local function colors()
		if Theme and Theme.colors then
			return Theme.colors()
		end
		return {
			Accent = "#7C3AED",
			Cyan = "#06B6D4",
			Background = "#020308",
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
			corner.CornerRadius = UDim.new(0, radius or 14)
			return corner
		end
		corner = Instance.new("UICorner")
		corner.Name = "AlleralCorner"
		corner.CornerRadius = UDim.new(0, radius or 14)
		corner.Parent = frame
		return corner
	end

	local function removeOverflowLayers(root)
		local glow = root:FindFirstChild("AlleralAmbientGlow")
		if glow then
			glow:Destroy()
		end
		local sheen = root:FindFirstChild("AlleralContentSheen", true)
		if sheen then
			sheen:Destroy()
		end
	end

	local function addWindowBorder(root, C)
		local stroke = root:FindFirstChild("AlleralWindowBorder")
		if not stroke or not stroke:IsA("UIStroke") then
			stroke = Instance.new("UIStroke")
			stroke.Name = "AlleralWindowBorder"
			stroke.Parent = root
		end
		stroke.Color = hex(C.Accent)
		stroke.Thickness = 1
		stroke.Transparency = 0.62
		stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		stroke.LineJoinMode = Enum.LineJoinMode.Round
	end

	local function addSidebarAccent(root, C)
		if root:FindFirstChild("AlleralSidebarAccent", true) then
			return
		end
		local sidebar
		for _, desc in ipairs(root:GetDescendants()) do
			if desc:IsA("GuiObject") then
				local name = desc.Name:lower()
				if name:find("sidebar", 1, true) or name == "side" then
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
		accent.Position = UDim2.new(1, -1, 0, 8)
		accent.Size = UDim2.new(0, 1, 1, -16)
		accent.BackgroundColor3 = hex(C.Cyan)
		accent.BackgroundTransparency = 0.55
		accent.BorderSizePixel = 0
		accent.ZIndex = (sidebar.ZIndex or 1) + 2
		accent.Parent = sidebar

		local grad = Instance.new("UIGradient")
		grad.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, hex(C.Cyan)),
			ColorSequenceKeypoint.new(0.5, hex(C.Accent)),
			ColorSequenceKeypoint.new(1, hex(C.Accent)),
		})
		grad.Rotation = 90
		grad.Parent = accent
	end

	local function solidifyPanels(root, C)
		for _, desc in ipairs(root:GetDescendants()) do
			if desc:IsA("Frame") or desc:IsA("ImageLabel") then
				local name = desc.Name:lower()
				if name:find("background", 1, true)
					or name:find("panel", 1, true)
					or name == "main"
					or name:find("window", 1, true) then
					if desc.BackgroundTransparency > 0.35 then
						desc.BackgroundTransparency = math.min(desc.BackgroundTransparency, 0.12)
					end
					if desc.BackgroundTransparency > 0.08 and desc.BackgroundTransparency <= 0.35 then
						desc.BackgroundColor3 = hex(C.Panel)
						desc.BackgroundTransparency = 0.04
					end
				end
			end
		end
	end

	local function applyLayers(windWindow)
		local root = getRoot(windWindow)
		if not root then
			return false
		end
		local C = colors()
		pcall(removeOverflowLayers, root)
		pcall(solidifyPanels, root, C)
		pcall(addWindowBorder, root, C)
		pcall(addSidebarAccent, root, C)
		ensureCorner(root, 14)
		root.ClipsDescendants = true
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
							Log.info("Visual polish active (EXE-6 frame, no backdrop overflow)")
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