-- Alleral V12 — topbar drag (clamped, persisted, FPS-safe)
return function(EventBus, ConnectionTracker, PerformanceManager)
	local UserInputService = game:GetService("UserInputService")
	local DragManager = {}

	local MIN_X, MIN_Y = 8, 8
	local states = {}

	local function getRoot(windWindow)
		if not windWindow then
			return nil
		end
		if typeof(windWindow) == "Instance" and windWindow:IsA("GuiObject") then
			return windWindow
		end
		if type(windWindow) == "table" then
			local root = windWindow.UIElements and windWindow.UIElements.Main
			if typeof(root) == "Instance" then
				return root
			end
		end
		return nil
	end

	local function findTopbar(root)
		for _, name in ipairs({ "Topbar", "TopBar", "TitleBar", "Header" }) do
			local bar = root:FindFirstChild(name, true)
			if bar and bar:IsA("GuiObject") then
				return bar
			end
		end
		return root
	end

	local function storageKey(gameId)
		return "Alleral_WindowPos_" .. tostring(gameId or "default")
	end

	local function loadPosition(gameId)
		local key = storageKey(gameId)
		local env = getgenv and getgenv() or {}
		local saved = env[key]
		if type(saved) == "table" and saved.X and saved.Y then
			return UDim2.new(saved.X.Scale or 0.5, saved.X.Offset or 0, saved.Y.Scale or 0.5, saved.Y.Offset or 0)
		end
		return nil
	end

	local function savePosition(gameId, pos)
		local key = storageKey(gameId)
		local env = getgenv and getgenv() or {}
		env[key] = {
			X = { Scale = pos.X.Scale, Offset = pos.X.Offset },
			Y = { Scale = pos.Y.Scale, Offset = pos.Y.Offset },
		}
	end

	local function clampPosition(root, pos)
		local camera = workspace.CurrentCamera
		if not camera then
			return pos
		end
		local vp = camera.ViewportSize
		local size = root.AbsoluteSize
		local x = pos.X.Offset
		local y = pos.Y.Offset
		if pos.X.Scale ~= 0 or pos.Y.Scale ~= 0 then
			x = pos.X.Scale * vp.X + pos.X.Offset
			y = pos.Y.Scale * vp.Y + pos.Y.Offset
		end
		x = math.clamp(x, MIN_X, math.max(MIN_X, vp.X - size.X - MIN_X))
		y = math.clamp(y, MIN_Y, math.max(MIN_Y, vp.Y - size.Y - MIN_Y))
		return UDim2.fromOffset(x, y)
	end

	function DragManager.cleanup(owner)
		local st = states[owner]
		if not st then
			return
		end
		if ConnectionTracker then
			ConnectionTracker.disconnectAll(owner)
		end
		st.active = false
		states[owner] = nil
		if EventBus then
			EventBus.emit("drag:end", owner)
		end
	end

	function DragManager.isDragging(owner)
		local st = states[owner]
		return st and st.active or false
	end

	function DragManager.bind(windWindow, options)
		options = type(options) == "table" and options or {}
		local owner = windWindow
		if states[owner] then
			return true
		end

		local root = getRoot(windWindow)
		if not root then
			return false
		end

		local gameId = options.gameId or "default"
		local saved = loadPosition(gameId)
		if saved then
			pcall(function()
				root.Position = clampPosition(root, saved)
			end)
		end

		local handle = findTopbar(root)
		local st = {
			active = false,
			root = root,
			start = nil,
			origin = nil,
			inputType = nil,
		}
		states[owner] = st

		local function endDrag()
			if not st.active then
				return
			end
			st.active = false
			if PerformanceManager and PerformanceManager.setBusy then
				PerformanceManager.setBusy("drag", false)
			end
			savePosition(gameId, root.Position)
			if ConnectionTracker then
				ConnectionTracker.disconnect(owner, "drag-move")
			end
			if EventBus then
				EventBus.emit("drag:end", owner)
			end
		end

		local began = handle.InputBegan:Connect(function(input)
			if st.active then
				return
			end
			if input.UserInputType ~= Enum.UserInputType.MouseButton1
				and input.UserInputType ~= Enum.UserInputType.Touch then
				return
			end
			if PerformanceManager and PerformanceManager.isBusy("resize") then
				return
			end

			st.active = true
			if PerformanceManager and PerformanceManager.setBusy then
				PerformanceManager.setBusy("drag", true)
			end
			st.start = input.Position
			st.origin = root.Position
			st.inputType = input.UserInputType

			if EventBus then
				EventBus.emit("drag:start", owner)
			end

			if ConnectionTracker then
				ConnectionTracker.track(owner, UserInputService.InputChanged:Connect(function(changed)
					if not st.active or changed.UserInputType ~= st.inputType then
						return
					end
					local delta = changed.Position - st.start
					local nextPos = UDim2.new(
						st.origin.X.Scale,
						st.origin.X.Offset + delta.X,
						st.origin.Y.Scale,
						st.origin.Y.Offset + delta.Y
					)
					root.Position = clampPosition(root, nextPos)
				end), "drag-move")
			end

			ConnectionTracker.track(owner, input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					endDrag()
				end
			end), "drag-end")
		end)

		if ConnectionTracker then
			ConnectionTracker.track(owner, began, "drag-began")
		end

		return true
	end

	function DragManager.logReady()
		pcall(function()
			local Log = getgenv and getgenv().Alleral_Log
			if Log and Log.info then
				Log.info("Drag manager active (topbar, clamped, persisted)")
			end
		end)
	end

	return DragManager
end