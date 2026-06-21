-- Alleral V12 — UI validation + guards
return function(EventBus, Validate, TabManager, PerformanceManager)
	local ValidationManager = {}

	function ValidationManager.inspect(window, state)
		if Validate and Validate.inspect then
			return Validate.inspect(window, state)
		end
		return { ok = true, issues = {}, tabs = 0, controls = 0 }
	end

	function ValidationManager.run(window, state)
		local ok, report = true, nil
		if Validate and Validate.run then
			ok, report = Validate.run(window, state)
		end
		if TabManager and state and state.gameId then
			pcall(TabManager.validate, window, state.gameId)
		end
		if EventBus then
			EventBus.emit("validation:done", ok, report)
		end
		return ok, report
	end

	function ValidationManager.guard(key, fn)
		if PerformanceManager and PerformanceManager.guard then
			return PerformanceManager.guard(key, fn)
		end
		return pcall(fn)
	end

	return ValidationManager
end