-- Alleral V11.5 — window motion (UIScale + single CanvasGroup fade)
return function()
	local Motion = {}
	local TweenService = game:GetService("TweenService")

	local OPEN_DURATION = 0.24
	local CLOSE_DURATION = 0.16
	local OPEN_SCALE = 0.92
	local CLOSE_SCALE = 0.95
	local OPEN_FADE = 0.18
	local CLOSE_FADE = 0.14

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

	local SKIP_FADE = {
		AlleralMotionScale = true,
		AlleralMotionFade = true,
		AlleralAmbientGlow = true,
	}

	local function getFade(root)
		local fade = root:FindFirstChild("AlleralMotionFade")
		if not fade then
			fade = Instance.new("CanvasGroup")
			fade.Name = "AlleralMotionFade"
			fade.Size = UDim2.fromScale(1, 1)
			fade.BackgroundTransparency = 1
			fade.GroupTransparency = 0
			fade.Parent = root
			for _, child in ipairs(root:GetChildren()) do
				if child ~= fade and not SKIP_FADE[child.Name] then
					child.Parent = fade
				end
			end
		end
		return fade
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
		local fade = getFade(root)
		scale.Scale = OPEN_SCALE
		fade.GroupTransparency = OPEN_FADE

		local tween = TweenService:Create(
			scale,
			TweenInfo.new(OPEN_DURATION, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
			{ Scale = 1 }
		)
		local fadeTween = TweenService:Create(
			fade,
			TweenInfo.new(OPEN_DURATION, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
			{ GroupTransparency = 0 }
		)
		activeTweens[windWindow] = tween
		tween:Play()
		fadeTween:Play()
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
		local fade = getFade(root)
		local tween = TweenService:Create(
			scale,
			TweenInfo.new(CLOSE_DURATION, Enum.EasingStyle.Quint, Enum.EasingDirection.In),
			{ Scale = CLOSE_SCALE }
		)
		local fadeTween = TweenService:Create(
			fade,
			TweenInfo.new(CLOSE_DURATION, Enum.EasingStyle.Quint, Enum.EasingDirection.In),
			{ GroupTransparency = CLOSE_FADE }
		)
		activeTweens[windWindow] = tween
		tween:Play()
		fadeTween:Play()
		tween.Completed:Connect(function()
			root.Visible = false
			scale.Scale = 1
			fade.GroupTransparency = 0
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
				Log.info("Window motion active (UIScale + CanvasGroup fade)")
			end
		end)
	end

	return Motion
end