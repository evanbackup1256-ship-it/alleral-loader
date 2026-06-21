-- Alleral Noble V10 — ScreenGui-level dropdown overlay (never inside scroll/cards)
return function(deps)
	local Theme = deps.Theme
	local Layout = deps.Layout
	local Motion = deps.Motion
	local ZIndex = deps.ZIndex
	local Janitor = deps.Janitor

	local UIS = game:GetService("UserInputService")

	local DropdownManager = {}
	DropdownManager.__index = DropdownManager

	local ACTIVE_CLOSE = nil

	function DropdownManager.new(screenGui)
		local self = setmetatable({}, DropdownManager)
		self._janitor = Janitor.new()
		self._screen = screenGui
		self._overlay = Layout.make("Frame", {
			Name = "DropdownOverlay",
			Size = UDim2.new(1, 0, 1, 0),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			ZIndex = ZIndex.DropdownOverlay,
			Parent = screenGui,
		})
		self._janitor:Add(self._overlay, "Destroy")
		return self
	end

	function DropdownManager:getLayer()
		return self._overlay
	end

	function DropdownManager:registerClose(fn)
		if ACTIVE_CLOSE and ACTIVE_CLOSE ~= fn then
			pcall(ACTIVE_CLOSE)
		end
		ACTIVE_CLOSE = fn
	end

	function DropdownManager:clearClose(fn)
		if ACTIVE_CLOSE == fn then ACTIVE_CLOSE = nil end
	end

	function DropdownManager:clampToWindow(panel, trigger, windowFrame)
		if not panel or not trigger or not windowFrame then return end
		local wp = windowFrame.AbsolutePosition
		local ws = windowFrame.AbsoluteSize
		local ap = trigger.AbsolutePosition
		local as = trigger.AbsoluteSize
		local relX = ap.X - wp.X
		local relY = ap.Y - wp.Y + as.Y + 6
		local dw = as.X
		local maxH = 280
		local spaceBelow = ws.Y - relY - 8
		local spaceAbove = ap.Y - wp.Y - 8
		if spaceBelow < 120 and spaceAbove > spaceBelow then
			relY = ap.Y - wp.Y - math.min(maxH, spaceAbove) - 6
		end
		local dh = math.min(maxH, math.max(spaceBelow, spaceAbove, 80))
		relX = Layout.clamp(relX, 8, math.max(8, ws.X - dw - 8))
		panel.Position = UDim2.fromOffset(wp.X + relX, wp.Y + relY)
		panel.Size = UDim2.fromOffset(dw, dh)
	end

	function DropdownManager:bindOutsideClick(panel, trigger, closeFn)
		local conn = UIS.InputBegan:Connect(function(input, gpe)
			if input.KeyCode == Enum.KeyCode.Escape then
				closeFn()
				return
			end
			if input.UserInputType == Enum.UserInputType.MouseButton1 then
				local p = input.Position
				local function inside(gui)
					if not gui or not gui.Parent then return false end
					local gp = gui.AbsolutePosition
					local gs = gui.AbsoluteSize
					return p.X >= gp.X and p.X <= gp.X + gs.X and p.Y >= gp.Y and p.Y <= gp.Y + gs.Y
				end
				if not inside(panel) and not inside(trigger) then
					closeFn()
				end
			end
		end)
		self._janitor:Add(conn, "Disconnect")
	end

	function DropdownManager:animateOpen(panel, panelScale)
		panel.Visible = true
		panel.BackgroundTransparency = 0.15
		if panelScale then panelScale.Scale = 0.97 end
		Motion.spring(panel, { BackgroundTransparency = 0.04 }, Theme.SPRING.DROPDOWN)
		if panelScale then Motion.spring(panelScale, { Scale = 1 }, Theme.SPRING.DROPDOWN) end
	end

	function DropdownManager:animateClose(panel, panelScale, onDone)
		Motion.spring(panel, { BackgroundTransparency = 1 }, Theme.SPRING.DROPDOWN)
		if panelScale then Motion.spring(panelScale, { Scale = 0.97 }, Theme.SPRING.DROPDOWN) end
		task.delay(0.22, function()
			if panel.Parent then
				panel.Visible = false
			end
			if onDone then onDone() end
		end)
	end

	function DropdownManager:Destroy()
		ACTIVE_CLOSE = nil
		self._janitor:Destroy()
	end

	return DropdownManager
end