-- Alleral V12 — performance guards (reentrancy, spam filter)
return function(EventBus, ConnectionTracker)
	local PerformanceManager = {}
	local busy = {}
	local logCooldown = {}
	local COOLDOWN = 1.5

	local function logOnce(key, msg, level)
		local now = tick()
		if logCooldown[key] and now - logCooldown[key] < COOLDOWN then
			return
		end
		logCooldown[key] = now
		local Log = getgenv and getgenv().Alleral_Log
		if Log then
			if level == "warn" and Log.warn then
				Log.warn(msg)
			elseif Log.info then
				Log.info(msg)
			end
		end
	end

	function PerformanceManager.guard(key, fn)
		key = tostring(key or "op")
		if busy[key] then
			return false
		end
		busy[key] = true
		local ok, res = pcall(fn)
		busy[key] = false
		return ok, res
	end

	function PerformanceManager.isBusy(key)
		return busy[tostring(key or "")] == true
	end

	function PerformanceManager.setBusy(key, value)
		key = tostring(key or "")
		if value then
			busy[key] = true
		else
			busy[key] = nil
		end
	end

	function PerformanceManager.stats()
		return {
			connections = ConnectionTracker and ConnectionTracker.count() or 0,
			busyKeys = busy,
			eventDepth = EventBus and EventBus.getDepth and EventBus.getDepth() or 0,
		}
	end

	function PerformanceManager.logReady()
		logOnce("perf", "Performance manager active", "info")
	end

	return PerformanceManager
end