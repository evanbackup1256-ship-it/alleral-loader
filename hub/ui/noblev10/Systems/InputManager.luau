-- Alleral Noble V10 — keybind and input routing
return function(deps)
	local Janitor = deps.Janitor
	local UserInputService = game:GetService("UserInputService")

	local InputManager = {}
	InputManager.__index = InputManager

	function InputManager.new()
		return setmetatable({ _janitor = Janitor.new(), _handlers = {} }, InputManager)
	end

	function InputManager:bindToggle(keyCode, callback)
		local conn = UserInputService.InputBegan:Connect(function(input, gpe)
			if gpe then return end
			if input.KeyCode == keyCode and callback then
				callback()
			end
		end)
		self._janitor:Add(conn, "Disconnect")
		return conn
	end

	function InputManager:bindSearch(keyCode, modifiers, callback)
		local conn = UserInputService.InputBegan:Connect(function(input, gpe)
			if gpe then return end
			if input.KeyCode ~= keyCode then return end
			modifiers = modifiers or { Ctrl = true }
			local ctrl = UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) or UserInputService:IsKeyDown(Enum.KeyCode.RightControl)
			local shift = UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) or UserInputService:IsKeyDown(Enum.KeyCode.RightShift)
			local alt = UserInputService:IsKeyDown(Enum.KeyCode.LeftAlt) or UserInputService:IsKeyDown(Enum.KeyCode.RightAlt)
			if (not modifiers.Ctrl or ctrl) and (not modifiers.Shift or shift) and (not modifiers.Alt or alt) then
				if callback then callback() end
			end
		end)
		self._janitor:Add(conn, "Disconnect")
		return conn
	end

	function InputManager:Destroy()
		self._janitor:Destroy()
	end

	return InputManager
end