-- Alleral V12 — layout density + scroll fixes (one-shot, no listeners)
return function()
	local LayoutManager = {}
	local patched = {}

	local function mark(root)
		if patched[root] then
			return false
		end
		patched[root] = true
		return true
	end

	function LayoutManager.apply(windWindow)
		local root
		if type(windWindow) == "table" then
			root = windWindow.UIElements and windWindow.UIElements.Main
		end
		if typeof(root) ~= "Instance" or not mark(root) then
			return false
		end

		root.ClipsDescendants = true

		for _, desc in ipairs(root:GetDescendants()) do
			if desc:IsA("ScrollingFrame") then
				desc.ScrollBarThickness = 4
				desc.ScrollBarImageTransparency = 0.55
				desc.BorderSizePixel = 0
				desc.AutomaticCanvasSize = Enum.AutomaticSize.Y

				local pad = desc:FindFirstChild("AlleralLayoutPad")
				if not pad then
					pad = Instance.new("UIPadding")
					pad.Name = "AlleralLayoutPad"
					pad.PaddingTop = UDim.new(0, 6)
					pad.PaddingBottom = UDim.new(0, 18)
					pad.PaddingLeft = UDim.new(0, 8)
					pad.PaddingRight = UDim.new(0, 10)
					pad.Parent = desc
				end

				local parent = desc.Parent
				if parent and parent:IsA("GuiObject") then
					desc.Size = UDim2.new(1, -6, 1, -10)
				end
			end

			if desc:IsA("UIListLayout") then
				if desc.Padding.Offset < 4 then
					desc.Padding = UDim.new(0, 6)
				end
			end
		end

		return true
	end

	function LayoutManager.logReady()
		pcall(function()
			local Log = getgenv and getgenv().Alleral_Log
			if Log and Log.info then
				Log.info("Layout manager active (density + scroll padding)")
			end
		end)
	end

	return LayoutManager
end