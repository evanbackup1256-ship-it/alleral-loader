-- Alleral V11.5.3 — lightweight border polish (no backdrop, no loops)
return function(Theme)
	local VisualPolish = {}
	local bound = {}

	local function colors()
		if Theme and Theme.colors then
			return Theme.colors()
		end
		return { Accent = "#8B5CF6", Cyan = "#22D3EE" }
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

	local function applyOnce(windWindow)
		local root = getRoot(windWindow)
		if not root then
			return false
		end
		local C = colors()

		if not root:FindFirstChild("AlleralWindowBorder") then
			local stroke = Instance.new("UIStroke")
			stroke.Name = "AlleralWindowBorder"
			stroke.Color = hex(C.Accent)
			stroke.Thickness = 1
			stroke.Transparency = 0.6
			stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
			stroke.Parent = root
		end

		local corner = root:FindFirstChild("AlleralCorner")
		if not corner then
			corner = Instance.new("UICorner")
			corner.Name = "AlleralCorner"
			corner.CornerRadius = UDim.new(0, 10)
			corner.Parent = root
		end

		return true
	end

	function VisualPolish.bind(windWindow)
		if not windWindow or bound[windWindow] then
			return
		end
		bound[windWindow] = true
		task.defer(function()
			pcall(applyOnce, windWindow)
		end)
	end

	return VisualPolish
end