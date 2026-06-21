-- Alleral Noble V10 — animation orchestration
return function(deps)
	local Theme = deps.Theme
	local Motion = deps.Motion

	local AnimationManager = {}

	function AnimationManager.openWindow(main, mainScale, dim)
		if mainScale then mainScale.Scale = 0.94 end
		if dim then dim.BackgroundTransparency = 1 end
		if main then main.BackgroundTransparency = 0.25 end
		Motion.spring(mainScale, { Scale = 1 }, Theme.SPRING.WINDOW_OPEN)
		Motion.spring(main, { BackgroundTransparency = 0 }, Theme.SPRING.SMOOTH)
		if dim then Motion.spring(dim, { BackgroundTransparency = 0.42 }, Theme.SPRING.SMOOTH) end
	end

	function AnimationManager.closeWindow(main, mainScale, dim)
		Motion.spring(mainScale, { Scale = 0.9 }, Theme.SPRING.SNAPPY)
		Motion.spring(main, { BackgroundTransparency = 0.2 }, Theme.SPRING.SNAPPY)
		if dim then Motion.spring(dim, { BackgroundTransparency = 1 }, Theme.SPRING.SNAPPY) end
	end

	function AnimationManager.showWindow(main, mainScale, dim)
		AnimationManager.openWindow(main, mainScale, dim)
	end

	function AnimationManager.hideWindow(main, mainScale, dim)
		AnimationManager.closeWindow(main, mainScale, dim)
	end

	return AnimationManager
end