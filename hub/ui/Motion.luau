local TweenService = game:GetService("TweenService")

return function(deps)
	deps = type(deps) == "table" and deps or {}
	local Spring = deps.Spring
	local Utils = deps.Utils

	local profiles = {
		snappy = { frequency = 7.5, damping = 1 },
		soft = { frequency = 4.8, damping = 1.12 },
		bouncy = { frequency = 5.8, damping = 0.72 },
		pop = { frequency = 6.4, damping = 0.82 },
		micro = { frequency = 9.5, damping = 1 },
		open = { frequency = 5.6, damping = 0.88 },
		close = { frequency = 7.2, damping = 1.05 },
		notify = { frequency = 6.2, damping = 0.9 },
		hover = { frequency = 8.5, damping = 1 },
		tab = { frequency = 6.8, damping = 0.95 },
		sidebar = { frequency = 5.2, damping = 0.9 },
		modal = { frequency = 5.4, damping = 0.78 },
		dropdown = { frequency = 7, damping = 0.85 },
		stagger = { frequency = 6, damping = 0.92 },
	}

	local Motion = {}

	function Motion.profile(name)
		return profiles[name] or profiles.soft
	end

	function Motion.to(instance, goals, profileName, onComplete)
		if not instance or type(goals) ~= "table" then
			if onComplete then
				task.defer(onComplete)
			end
			return
		end
		local profile = type(profileName) == "table" and profileName or Motion.profile(profileName or "soft")
		if Spring and type(Spring.target) == "function" then
			Spring.target(instance, profile.damping, profile.frequency, goals, onComplete)
			return
		end
		local info = TweenInfo.new(0.22, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
		local tween = TweenService:Create(instance, info, goals)
		if onComplete then
			tween.Completed:Once(onComplete)
		end
		tween:Play()
	end

	function Motion.cancel(instance, property)
		if Spring and type(Spring.stop) == "function" then
			Spring.stop(instance, property)
		end
	end

	function Motion.fade(instance, visible, profileName, onComplete)
		if not instance then
			return
		end
		local goals = { BackgroundTransparency = visible and 0 or 1 }
		if instance:IsA("TextLabel") or instance:IsA("TextButton") then
			goals.TextTransparency = visible and 0 or 1
		end
		if instance:IsA("ImageLabel") or instance:IsA("ImageButton") then
			goals.ImageTransparency = visible and 0 or 1
		end
		Motion.to(instance, goals, profileName or "soft", function()
			if not visible then
				instance.Visible = false
			end
			if onComplete then
				onComplete()
			end
		end)
		if visible then
			instance.Visible = true
		end
	end

	function Motion.stagger(children, buildGoals, profileName, delay)
		delay = delay or 0.04
		for i, child in ipairs(children) do
			task.delay((i - 1) * delay, function()
				if child and child.Parent then
					Motion.to(child, buildGoals(child, i), profileName or "stagger")
				end
			end)
		end
	end

	function Motion.pressBounce(instance, profileName)
		local base = instance.Size
		local shrunk = UDim2.new(
			base.X.Scale * 0.96,
			math.floor(base.X.Offset * 0.96),
			base.Y.Scale * 0.96,
			math.floor(base.Y.Offset * 0.96)
		)
		Motion.to(instance, { Size = shrunk }, profileName or "micro", function()
			Motion.to(instance, { Size = base }, "bouncy")
		end)
	end

	function Motion.cursorGlow(frame, theme, input)
		if not frame or not theme then
			return
		end
		local glow = frame:FindFirstChild("CursorGlow")
		if not glow then
			glow = Utils.new("Frame", {
				Name = "CursorGlow",
				AnchorPoint = Vector2.new(0.5, 0.5),
				BackgroundColor3 = theme.Accent,
				BackgroundTransparency = 0.88,
				BorderSizePixel = 0,
				Size = UDim2.fromOffset(180, 180),
				ZIndex = 0,
				Parent = frame,
			})
			Utils.corner(glow, 999)
		end
		local pos = input and input.Position or Vector2.new(frame.AbsolutePosition.X + frame.AbsoluteSize.X / 2, frame.AbsolutePosition.Y + frame.AbsoluteSize.Y / 2)
		Motion.to(glow, {
			Position = UDim2.fromOffset(pos.X - frame.AbsolutePosition.X, pos.Y - frame.AbsolutePosition.Y),
		}, "soft")
	end

	return Motion
end
