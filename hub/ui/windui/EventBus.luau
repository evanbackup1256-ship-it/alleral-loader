-- Alleral V12 — lightweight event bus (reentrancy-safe)
return function()
	local EventBus = {}
	local listeners = {}
	local depth = 0
	local MAX_DEPTH = 6

	function EventBus.on(event, handler)
		event = tostring(event or "")
		if event == "" or type(handler) ~= "function" then
			return function() end
		end
		listeners[event] = listeners[event] or {}
		table.insert(listeners[event], handler)
		local idx = #listeners[event]
		return function()
			local list = listeners[event]
			if list and list[idx] then
				list[idx] = nil
			end
		end
	end

	function EventBus.emit(event, ...)
		event = tostring(event or "")
		local list = listeners[event]
		if not list or depth >= MAX_DEPTH then
			return
		end
		depth = depth + 1
		for _, handler in ipairs(list) do
			if type(handler) == "function" then
				pcall(handler, ...)
			end
		end
		depth = depth - 1
	end

	function EventBus.clear(event)
		if event == nil then
			listeners = {}
			return
		end
		listeners[tostring(event)] = nil
	end

	function EventBus.getDepth()
		return depth
	end

	return EventBus
end