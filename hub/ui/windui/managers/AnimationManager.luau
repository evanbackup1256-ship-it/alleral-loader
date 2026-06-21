-- Alleral V12 — root-only UIScale animation (60fps, no reparent)
return function(EventBus)
	local AnimationManager = {}
	local TweenService = game:GetService("TweenService")

	local OPEN_DURATION = 0.18
	local CLOSE_DURATION = 0.12
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

	function AnimationManager.cancel(windWindow)
		local tween = activeTweens[windWindow]
		if tween then
			pcall(function() tween:Cancel() end)
			activeTweens[windWindow] = nil
		end
		windowAnimating = false
	end

	function AnimationManager.isAnimatingWindow()
		return windowAnimating
	end

	function AnimationManager.getActiveTweenCount()
		local n = 0
		for _ in pairs(activeTweens) do
			n = n + 1
		end
		return n
	end

	function AnimationManager.setDragMode(_) end

	function AnimationManager.tween(inst, props, duration, style, dir)
		if typeof(inst) ~= "Instance" then
			return
		end
		local tween = TweenService:Create(
			inst,
			TweenInfo.new(duration or 0.15, style or Enum.EasingStyle.Quint, dir or Enum.EasingDirection.Out),
			props
		)
		tween:Play()
		return tween
	end

	function AnimationManager.animateWindowShow(_windUI, windWindow, onDone)
		local root = getRoot(windWindow)
		if not root then
			windowAnimating = false
			if onDone then onDone() end
			return
		end

		AnimationManager.cancel(windWindow)
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
		if EventBus then EventBus.emit("window:showing") end
		tween:Play()
		tween.Completed:Connect(function()
			activeTweens[windWindow] = nil
			windowAnimating = false
			if EventBus then EventBus.emit("window:visible") end
			if onDone then onDone() end
		end)
	end

	function AnimationManager.animateWindowHide(_windUI, windWindow, onDone)
		local root = getRoot(windWindow)
		if not root then
			windowAnimating = false
			if onDone then onDone() end
			return
		end

		AnimationManager.cancel(windWindow)
		windowAnimating = true

		local scale = getScale(root)
		local tween = TweenService:Create(
			scale,
			TweenInfo.new(CLOSE_DURATION, Enum.EasingStyle.Quint, Enum.EasingDirection.In),
			{ Scale = CLOSE_SCALE }
		)
		activeTweens[windWindow] = tween
		if EventBus then EventBus.emit("window:hiding") end
		tween:Play()
		tween.Completed:Connect(function()
			root.Visible = false
			scale.Scale = 1
			activeTweens[windWindow] = nil
			windowAnimating = false
			if EventBus then EventBus.emit("window:hidden") end
			if onDone then onDone() end
		end)
	end

	function AnimationManager.cleanup()
		for windWindow in pairs(activeTweens) do
			AnimationManager.cancel(windWindow)
		end
	end

	function AnimationManager.logPerformance()
		pcall(function()
			local Log = getgenv and getgenv().Alleral_Log
			if Log and Log.info then
				Log.info("Animation manager active (UIScale root only)")
			end
		end)
	end

	return AnimationManager
end