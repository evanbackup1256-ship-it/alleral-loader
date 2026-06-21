-- Alleral V11.3.1 — instant window visibility (zero open/close lag)
return function()
	local Motion = {}
	local DRAG_MODE = false

	function Motion.cancel(_) end

	function Motion.tween(inst, props, duration, style, dir)
		if typeof(inst) ~= "Instance" then
			return
		end
		duration = duration or 0
		pcall(function()
			for key, value in pairs(props) do
				inst[key] = value
			end
		end)
	end

	function Motion.setDragMode(enabled)
		DRAG_MODE = enabled == true
	end

	function Motion.isAnimatingWindow()
		return false
	end

	function Motion.getActiveTweenCount()
		return 0
	end

	function Motion.animateWindowShow(_windUI, windWindow, onDone)
		pcall(function()
			if windWindow and windWindow.UIElements and windWindow.UIElements.Main then
				windWindow.UIElements.Main.Visible = true
			end
		end)
		if onDone then
			onDone()
		end
	end

	function Motion.animateWindowHide(_windUI, windWindow, onDone)
		pcall(function()
			if windWindow and windWindow.UIElements and windWindow.UIElements.Main then
				windWindow.UIElements.Main.Visible = false
			end
		end)
		if onDone then
			onDone()
		end
	end

	function Motion.cleanup() end

	function Motion.logPerformance()
		warn("[WindUI] Window open/close instant (no descendant tweens)")
		warn("[WindUI] Duplicate connection guard active")
	end

	return Motion
end