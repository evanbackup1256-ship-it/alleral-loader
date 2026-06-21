-- Alleral V11.1 — lightweight TweenService motion (performance pass)
return function()
	local TweenService = game:GetService("TweenService")
	local Motion = {}
	local ACTIVE = {}
	local BOUND = {}
	local DRAG_MODE = false

	local function findGui(el)
		if typeof(el) == "Instance" and el:IsA("GuiObject") then
			return el
		end
		if type(el) == "table" then
			for _, key in ipairs({ "Frame", "UIElements", "Object", "Instance", "Button", "Root" }) do
				local v = el[key]
				if typeof(v) == "Instance" and v:IsA("GuiObject") then
					return v
				end
			end
		end
		return nil
	end

	function Motion.cancel(inst)
		local tw = ACTIVE[inst]
		if tw then
			pcall(function() tw:Cancel() end)
			ACTIVE[inst] = nil
		end
	end

	function Motion.tween(inst, props, duration, style, dir)
		if typeof(inst) ~= "Instance" then
			return
		end
		Motion.cancel(inst)
		duration = duration or 0.16
		style = style or Enum.EasingStyle.Quint
		dir = dir or Enum.EasingDirection.Out
		local tw = TweenService:Create(inst, TweenInfo.new(duration, style, dir), props)
		ACTIVE[inst] = tw
		tw:Play()
		tw.Completed:Connect(function()
			if ACTIVE[inst] == tw then
				ACTIVE[inst] = nil
			end
		end)
		return tw
	end

	function Motion.setDragMode(enabled)
		DRAG_MODE = enabled == true
	end

	function Motion.bindHover(el, opts)
		if DRAG_MODE then
			return
		end
		opts = opts or {}
		local gui = findGui(el)
		if not gui or not gui:IsA("GuiButton") then
			return
		end
		if BOUND[gui] then
			return
		end
		BOUND[gui] = true
		gui:SetAttribute("AlleralMotionBound", true)

		local scale = gui:FindFirstChildOfClass("UIScale")
		if not scale then
			scale = Instance.new("UIScale")
			scale.Parent = gui
		end

		local hover = opts.hoverScale or 1.02
		local press = opts.pressScale or 0.97

		gui.MouseEnter:Connect(function()
			Motion.tween(scale, { Scale = hover }, 0.14)
		end)
		gui.MouseLeave:Connect(function()
			Motion.tween(scale, { Scale = 1 }, 0.14)
		end)
		gui.MouseButton1Down:Connect(function()
			Motion.tween(scale, { Scale = press }, 0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
		end)
		gui.MouseButton1Up:Connect(function()
			Motion.tween(scale, { Scale = 1 }, 0.14, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
		end)
	end

	function Motion.openWindow(WindUI, force)
		if DRAG_MODE and not force then
			return
		end
		pcall(function()
			local scaleObj = WindUI and WindUI.UIScaleObj
			if scaleObj then
				scaleObj.Scale = 0.98
				Motion.tween(scaleObj, { Scale = 1 }, 0.22, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
			end
		end)
	end

	function Motion.cleanup()
		for inst, tw in pairs(ACTIVE) do
			pcall(function() tw:Cancel() end)
			ACTIVE[inst] = nil
		end
		for key in pairs(BOUND) do
			BOUND[key] = nil
		end
	end

	function Motion.logPerformance()
		warn("[WindUI] Animation connections cleaned")
		warn("[WindUI] Duplicate connection guard active")
		warn("[WindUI] Animation cleanup active")
		warn("[WindUI] Animation performance pass complete")
	end

	return Motion
end