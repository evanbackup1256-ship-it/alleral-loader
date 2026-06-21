-- Alleral V11.1 — reentrancy + silent-set guards (prevents WindUI stack overflow)
return function()
	local Guards = {}
	local BUSY = {}
	local SILENT = {}

	function Guards.isBusy(key)
		return BUSY[key] == true
	end

	function Guards.wrap(fn, key)
		if type(fn) ~= "function" then
			return function() end
		end
		key = tostring(key or fn)
		return function(...)
			if BUSY[key] then
				return
			end
			BUSY[key] = true
			local results = { pcall(fn, ...) }
			BUSY[key] = false
			if not results[1] then
				warn("[Alleral] callback error (" .. key .. "): " .. tostring(results[2]))
				return
			end
			return table.unpack(results, 2)
		end
	end

	function Guards.run(key, fn)
		if BUSY[key] then
			return false
		end
		BUSY[key] = true
		local ok, res = pcall(fn)
		BUSY[key] = false
		return ok, res
	end

	function Guards.silent(key, fn)
		SILENT[key] = true
		local ok, res = pcall(fn)
		SILENT[key] = false
		return ok, res
	end

	function Guards.isSilent(key)
		return SILENT[key] == true
	end

	function Guards.silentSet(raw, value, kind)
		if not raw then
			return false
		end
		return Guards.silent(tostring(raw) .. ":set", function()
			if type(raw.Set) == "function" then
				local prev = raw.Callback
				raw.Callback = function() end
				if kind == "toggle" then
					raw:Set(value == true)
				elseif kind == "slider" then
					raw:Set(tonumber(value) or 0)
				else
					raw:Set(value)
				end
				raw.Callback = prev
				return true
			end
			if type(raw.SetValue) == "function" then
				raw:SetValue(value)
				return true
			end
			return false
		end)
	end

	return Guards
end