-- Alleral V12 — dashboard section registry (session, automation, game, executor, health)
return function(EventBus, Bootstrap)
	local DashboardBuilder = {}
	local SECTIONS = {
		"Session Stats",
		"Automation Stats",
		"Game Stats",
		"Executor Stats",
		"System Health",
	}

	function DashboardBuilder.sections()
		local out = {}
		for _, name in ipairs(SECTIONS) do
			table.insert(out, name)
		end
		return out
	end

	function DashboardBuilder.createStatusLabels(group, keys)
		if type(group) ~= "table" or type(group.AddLabel) ~= "function" then
			return {}
		end
		keys = type(keys) == "table" and keys or {}
		local labels = {}
		for _, key in ipairs(keys) do
			local text = Bootstrap and Bootstrap.sanitize and Bootstrap.sanitize(key .. ": --", 80) or (key .. ": --")
			labels[key] = group:AddLabel(text)
		end
		if EventBus then
			EventBus.emit("dashboard:labels", keys)
		end
		return labels
	end

	function DashboardBuilder.defaultSessionKeys()
		return { "FPS", "Ping", "Memory", "Runtime", "Players" }
	end

	function DashboardBuilder.defaultAutomationKeys()
		return { "Enabled Features", "Active Modules", "Current Tasks" }
	end

	function DashboardBuilder.defaultGameKeys()
		return { "Cash", "Level", "Progress" }
	end

	function DashboardBuilder.defaultExecutorKeys()
		return { "Executor", "Capabilities", "Environment" }
	end

	function DashboardBuilder.defaultHealthKeys()
		return { "Validation", "Performance", "Connection State" }
	end

	return DashboardBuilder
end