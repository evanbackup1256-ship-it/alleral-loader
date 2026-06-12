return function(deps)
	deps = type(deps) == "table" and deps or {}
	local spr = deps.Vendor and deps.Vendor.spr

	local Spring = {}

	local function mapProfile(damping, frequency)
		local ratio = tonumber(damping) or 1
		local freq = tonumber(frequency) or 6
		if ratio > 1.5 then
			ratio = ratio / 10
		end
		ratio = math.clamp(ratio, 0.05, 1.25)
		freq = math.clamp(freq, 0.5, 24)
		return ratio, freq
	end

	function Spring.target(instance, damping, frequency, goals, onComplete)
		if not instance or type(goals) ~= "table" then
			if onComplete then
				task.defer(onComplete)
			end
			return
		end
		if spr and type(spr.target) == "function" then
			local ratio, freq = mapProfile(damping, frequency)
			spr.target(instance, ratio, freq, goals)
			if onComplete and type(spr.completed) == "function" then
				spr.completed(instance, onComplete)
			elseif onComplete then
				task.defer(onComplete)
			end
			return
		end
		for prop, goal in pairs(goals) do
			instance[prop] = goal
		end
		if onComplete then
			task.defer(onComplete)
		end
	end

	function Spring.stop(instance, property)
		if spr and type(spr.stop) == "function" then
			spr.stop(instance, property)
		end
	end

	function Spring.completed(instance, callback)
		if spr and type(spr.completed) == "function" then
			spr.completed(instance, callback)
		elseif type(callback) == "function" then
			task.defer(callback)
		end
	end

	return Spring
end
