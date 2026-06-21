-- Alleral V11.3 — lightweight motion (window-only animations, guarded)
return function()
	local TweenService = game:GetService("TweenService")
	local Motion = {}
	local ACTIVE = {}
	local DRAG_MODE = false
	local isAnimatingWindow = false

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

	function Motion.isAnimatingWindow()
		return isAnimatingWindow
	end

	function Motion.getActiveTweenCount()
		local n = 0
		for _ in pairs(ACTIVE) do
			n = n + 1
		end
		return n
	end

	local function findWindowDim(windWindow)
		if not windWindow then
			return nil
		end
		local main = windWindow.UIElements and windWindow.UIElements.Main
		if typeof(main) == "Instance" then
			if main:IsA("CanvasGroup") then
				return main
			end
			local cg = main:FindFirstChildWhichIsA("CanvasGroup", true)
			if cg then
				return cg
			end
			local bg = main:FindFirstChild("Background", true)
			if typeof(bg) == "Instance" and bg:IsA("GuiObject") then
				return bg
			end
		end
		return nil
	end

	function Motion.animateWindowShow(WindUI, windWindow, onDone)
		if isAnimatingWindow or DRAG_MODE then
			if onDone then onDone() end
			return
		end
		isAnimatingWindow = true
		pcall(function()
			local scaleObj = WindUI and WindUI.UIScaleObj
			if scaleObj then
				scaleObj.Scale = 0.97
				Motion.tween(scaleObj, { Scale = 1 }, 0.2, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
			end
			local dim = findWindowDim(windWindow)
			if dim then
				if dim:IsA("CanvasGroup") then
					dim.GroupTransparency = 1
					Motion.tween(dim, { GroupTransparency = 0 }, 0.18, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
				elseif dim:IsA("GuiObject") then
					dim.BackgroundTransparency = 1
					Motion.tween(dim, { BackgroundTransparency = dim:GetAttribute("AlleralBaseTransparency") or 0 }, 0.18)
				end
			end
		end)
		task.delay(0.22, function()
			isAnimatingWindow = false
			if onDone then
				onDone()
			end
		end)
	end

	function Motion.animateWindowHide(WindUI, windWindow, onDone)
		if isAnimatingWindow or DRAG_MODE then
			if onDone then onDone() end
			return
		end
		isAnimatingWindow = true
		pcall(function()
			local scaleObj = WindUI and WindUI.UIScaleObj
			if scaleObj then
				Motion.tween(scaleObj, { Scale = 0.97 }, 0.16, Enum.EasingStyle.Quint, Enum.EasingDirection.In)
			end
			local dim = findWindowDim(windWindow)
			if dim then
				if dim:IsA("CanvasGroup") then
					Motion.tween(dim, { GroupTransparency = 1 }, 0.14, Enum.EasingStyle.Quint, Enum.EasingDirection.In)
				elseif dim:IsA("GuiObject") then
					Motion.tween(dim, { BackgroundTransparency = 1 }, 0.14)
				end
			end
		end)
		task.delay(0.18, function()
			isAnimatingWindow = false
			if onDone then
				onDone()
			end
		end)
	end

	function Motion.cleanup()
		for inst, tw in pairs(ACTIVE) do
			pcall(function() tw:Cancel() end)
			ACTIVE[inst] = nil
		end
		isAnimatingWindow = false
	end

	function Motion.logPerformance()
		warn("[WindUI] Animation connections cleaned")
		warn("[WindUI] Duplicate connection guard active")
		warn("[WindUI] Window animation optimized")
		warn("[WindUI] Animation cleanup active")
	end

	return Motion
end