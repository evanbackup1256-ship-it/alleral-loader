-- Alleral V12 — window lifecycle (drag, resize, layout, polish)
return function(EventBus, ConnectionTracker, PerformanceManager, AnimationManager, DragManager, ResizeManager, LayoutManager, ThemeManager, ElementPolish, VisualPolish, SearchGlow)
	local WindowManager = {}
	local bound = {}

	local function getOwner(windWindow)
		return windWindow
	end

	function WindowManager.setup(windWindow, options)
		options = type(options) == "table" and options or {}
		local owner = getOwner(windWindow)
		if bound[owner] then
			return true
		end
		bound[owner] = true

		if PerformanceManager and PerformanceManager.guard then
			PerformanceManager.guard("window-setup", function()
				if ThemeManager then
					pcall(ThemeManager.applyToWindow, windWindow)
				end
				if LayoutManager and LayoutManager.apply then
					pcall(LayoutManager.apply, windWindow)
				end
				if DragManager and DragManager.bind then
					pcall(DragManager.bind, windWindow, { gameId = options.gameId })
				end
				if ResizeManager and ResizeManager.bind then
					pcall(ResizeManager.bind, windWindow, { gameId = options.gameId })
				end
				if SearchGlow and SearchGlow.bind then
					pcall(SearchGlow.bind, windWindow)
				end
				if VisualPolish and VisualPolish.bind then
					pcall(VisualPolish.bind, windWindow)
				end
				if ElementPolish and ElementPolish.bind then
					pcall(ElementPolish.bind, windWindow)
				end
			end)
		end

		if EventBus then
			EventBus.emit("window:setup", owner, options.gameId)
		end
		return true
	end

	function WindowManager.teardown(windWindow)
		local owner = getOwner(windWindow)
		if not bound[owner] then
			return
		end
		bound[owner] = nil

		if DragManager and DragManager.cleanup then
			pcall(DragManager.cleanup, owner)
		end
		if ResizeManager and ResizeManager.cleanup then
			pcall(ResizeManager.cleanup, owner)
		end
		if AnimationManager and AnimationManager.cancel then
			pcall(AnimationManager.cancel, windWindow)
		end
		if ConnectionTracker then
			pcall(ConnectionTracker.disconnectAll, owner)
		end
		if EventBus then
			EventBus.emit("window:teardown", owner)
		end
	end

	function WindowManager.show(windUI, windWindow, onDone)
		if AnimationManager and AnimationManager.animateWindowShow then
			AnimationManager.animateWindowShow(windUI, windWindow, onDone)
		elseif onDone then
			onDone()
		end
	end

	function WindowManager.hide(windUI, windWindow, onDone)
		if AnimationManager and AnimationManager.animateWindowHide then
			AnimationManager.animateWindowHide(windUI, windWindow, onDone)
		elseif onDone then
			onDone()
		end
	end

	function WindowManager.isAnimating()
		return AnimationManager and AnimationManager.isAnimatingWindow and AnimationManager.isAnimatingWindow() or false
	end

	function WindowManager.logReady()
		pcall(function()
			local Log = getgenv and getgenv().Alleral_Log
			if Log and Log.info then
				Log.info("Window manager active (drag, resize, layout, animation)")
			end
		end)
	end

	return WindowManager
end