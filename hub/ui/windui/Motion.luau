-- Alleral V11.4 — lightweight window open/close (single UIScale tween, no descendant walks)
return function()
	local Motion = {}
	local TweenService = game:GetService("TweenService")

	local OPEN_DURATION = 0.2
	local CLOSE_DURATION = 0.14
	local OPEN_SCALE = 0.94
	local CLOSE_SCALE = 0.96

	local activeTweens = {}
	local windowAnimating = false

	local function getRoot(windWindow)
		if not windWindow then
			return nil
		end
		local root = windWindow.UIElements and windWindow.UIElements.Main
		if typeof(root) == "Instance" then
			return root
		end
		return nil
	end

	local function getScale(root)
		local scale = root:FindFirstChild("AlleralMotionScale")
		if not scale then
			scale = Instance.new("UIScale")
			scale.Name = "AlleralMotionScale"
			scale.Scale = 1
			scale.Parent = root
		end
		return scale
	end

	function Motion.cancel(windWindow)
		local tween = activeTweens[windWindow]
		if tween then
			pcall(function()
				tween:Cancel()
			end)
			activeTweens[windWindow] = nil
		end
		windowAnimating = false
	end

	function Motion.isAnimatingWindow()
		return windowAnimating
	end

	function Motion.getActiveTweenCount()
		local n = 0
		for _ in pairs(activeTweens) do
			n = n + 1
		end
		return n
	end

	function Motion.tween(inst, props, duration, style, dir)
		if typeof(inst) ~= "Instance" then
			return
		end
		duration = duration or 0.15
		style = style or Enum.EasingStyle.Quint
		dir = dir or Enum.EasingDirection.Out
		local tween = TweenService:Create(inst, TweenInfo.new(duration, style, dir), props)
		tween:Play()
		return tween
	end

	function Motion.setDragMode(_) end

	function Motion.animateWindowShow(_windUI, windWindow, onDone)
		local root = getRoot(windWindow)
		if not root then
			windowAnimating = false
			if onDone then
				onDone()
			end
			return
		end

		Motion.cancel(windWindow)
		windowAnimating = true
		root.Visible = true

		local scale = getScale(root)
		scale.Scale = OPEN_SCALE

		local tween = TweenService:Create(
			scale,
			TweenInfo.new(OPEN_DURATION, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
			{ Scale = 1 }
		)
		activeTweens[windWindow] = tween
		tween:Play()
		tween.Completed:Connect(function()
			if activeTweens[windWindow] == tween then
				activeTweens[windWindow] = nil
			end
			windowAnimating = false
			if onDone then
				onDone()
			end
		end)
	end

	function Motion.animateWindowHide(_windUI, windWindow, onDone)
		local root = getRoot(windWindow)
		if not root then
			windowAnimating = false
			if onDone then
				onDone()
			end
			return
		end

		Motion.cancel(windWindow)
		windowAnimating = true

		local scale = getScale(root)
		local tween = TweenService:Create(
			scale,
			TweenInfo.new(CLOSE_DURATION, Enum.EasingStyle.Quint, Enum.EasingDirection.In),
			{ Scale = CLOSE_SCALE }
		)
		activeTweens[windWindow] = tween
		tween:Play()
		tween.Completed:Connect(function()
			root.Visible = false
			scale.Scale = 1
			if activeTweens[windWindow] == tween then
				activeTweens[windWindow] = nil
			end
			windowAnimating = false
			if onDone then
				onDone()
			end
		end)
	end

	function Motion.cleanup()
		for windWindow in pairs(activeTweens) do
			Motion.cancel(windWindow)
		end
	end

	function Motion.logPerformance()
		pcall(function()
			local Log = getgenv and getgenv().Alleral_Log
			if Log and Log.info then
				Log.info("Window open/close animation active (UIScale only)")
			end
		end)
	end

	return Motion
end