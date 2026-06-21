-- Alleral V12 — connection registry (no leaks, single owner)
return function(EventBus)
	local ConnectionTracker = {}
	local buckets = {}

	function ConnectionTracker.track(owner, conn, label)
		if not owner or not conn or type(conn.Disconnect) ~= "function" then
			return conn
		end
		local key = tostring(owner)
		buckets[key] = buckets[key] or {}
		table.insert(buckets[key], { conn = conn, label = tostring(label or "conn") })
		if EventBus then
			EventBus.emit("connection:track", key, label)
		end
		return conn
	end

	function ConnectionTracker.disconnect(owner, label)
		local key = tostring(owner)
		local list = buckets[key]
		if not list then
			return 0
		end
		local n = 0
		for i = #list, 1, -1 do
			local entry = list[i]
			if not label or entry.label == label then
				pcall(function() entry.conn:Disconnect() end)
				table.remove(list, i)
				n = n + 1
			end
		end
		return n
	end

	function ConnectionTracker.disconnectAll(owner)
		return ConnectionTracker.disconnect(owner, nil)
	end

	function ConnectionTracker.count(owner)
		if owner == nil then
			local total = 0
			for _, list in pairs(buckets) do
				total = total + #list
			end
			return total
		end
		local list = buckets[tostring(owner)]
		return list and #list or 0
	end

	function ConnectionTracker.clearAll()
		for key in pairs(buckets) do
			ConnectionTracker.disconnectAll(key)
		end
		buckets = {}
	end

	return ConnectionTracker
end