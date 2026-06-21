-- Alleral V11.3 — lightweight window drag
return function(Motion, TooltipManager)
	local UserInputService = game:GetService("UserInputService")
	local Drag = {}
	local state = {
		active = false,
		conn = nil,
		endConn = nil,
		root = nil,
		start = nil,
		origin = nil,
		bound = false,
	}

	local function findRoot(windWindow)
		if not windWindow then
			return nil
		end
		if typeof(windWindow) == "Instance" and windWindow:IsA("GuiObject") then
			return windWindow
		end
		if type(windWindow) == "table" then
			local candidates = {
				windWindow.UIElements and windWindow.UIElements.Main,
				windWindow.Main,
				windWindow.Frame,
			}
			for _, c in ipairs(candidates) do
				if typeof(c) == "Instance" and c:IsA("GuiObject") then
					return c
				end
			end
		end
		return nil
	end

	function Drag.cleanup()
		if state.conn then
			pcall(function() state.conn:Disconnect() end)
			state.conn = nil
		end
		if state.endConn then
			pcall(function() state.endConn:Disconnect() end)
			state.endConn = nil
		end
		state.active = false
		if Motion and Motion.setDragMode then
			pcall(Motion.setDragMode, false)
		end
	end

	function Drag.isDragging()
		return state.active
	end

	function Drag.bind(windWindow, handle)
		if state.bound then
			return true
		end
		local root = findRoot(windWindow)
		if not root then
			return false
		end
		state.root = root

		local dragHandle = handle
		if typeof(dragHandle) ~= "Instance" then
			dragHandle = root:FindFirstChild("Topbar", true) or root
		end
		if not dragHandle:IsA("GuiObject") then
			return false
		end

		dragHandle.InputBegan:Connect(function(input)
			if state.active then
				return
			end
			if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then
				return
			end
			state.active = true
			state.start = input.Position
			state.origin = root.Position
			if TooltipManager and TooltipManager.suppressDuringDrag then
				pcall(TooltipManager.suppressDuringDrag)
			end
			if Motion and Motion.setDragMode then
				pcall(Motion.setDragMode, true)
			end
			state.conn = UserInputService.InputChanged:Connect(function(changed)
				if not state.active or changed.UserInputType ~= input.UserInputType then
					return
				end
				local delta = changed.Position - state.start
				root.Position = UDim2.new(
					state.origin.X.Scale,
					state.origin.X.Offset + delta.X,
					state.origin.Y.Scale,
					state.origin.Y.Offset + delta.Y
				)
			end)
			state.endConn = input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					Drag.cleanup()
				end
			end)
		end)

		state.bound = true
		return true
	end

	function Drag.logReady()
		pcall(function()
			local Log = getgenv and getgenv().Alleral_Log
			if Log and Log.info then
				Log.info("Drag optimization active")
			end
		end)
	end

	return Drag
end