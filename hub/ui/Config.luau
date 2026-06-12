local HttpService = game:GetService("HttpService")

return function(deps)
	deps = type(deps) == "table" and deps or {}
	local flags = {}
	local listeners = {}

	local Config = {
		Flags = flags,
		Path = "Alleral/Configs/",
	}

	function Config.set(flag, value)
		if not flag then
			return
		end
		flags[flag] = value
		if listeners[flag] then
			for _, fn in ipairs(listeners[flag]) do
				task.spawn(fn, value)
			end
		end
	end

	function Config.get(flag, default)
		if flags[flag] == nil then
			return default
		end
		return flags[flag]
	end

	function Config.onChange(flag, fn)
		listeners[flag] = listeners[flag] or {}
		table.insert(listeners[flag], fn)
	end

	function Config.loadJson(json)
		if type(json) ~= "string" or json == "" then
			return false
		end
		local ok, decoded = pcall(function()
			return HttpService:JSONDecode(json)
		end)
		if not ok or type(decoded) ~= "table" then
			return false
		end
		for k, v in pairs(decoded) do
			flags[k] = v
		end
		return true
	end

	function Config.exportJson()
		local ok, encoded = pcall(function()
			return HttpService:JSONEncode(flags)
		end)
		if ok then
			return encoded
		end
		return "{}"
	end

	function Config.bindWidget(flag, widget, kind)
		if not flag or not widget then
			return
		end
		Config.onChange(flag, function(value)
			if widget.Set then
				pcall(function()
					if kind == "toggle" then
						widget:Set({ CurrentValue = value == true })
					elseif kind == "slider" then
						widget:Set({ CurrentValue = tonumber(value) })
					elseif kind == "dropdown" then
						widget:Set({ CurrentOption = value })
					else
						widget:Set(value)
					end
				end)
			end
		end)
	end

	function Config.reset()
		table.clear(flags)
	end

	return Config
end
