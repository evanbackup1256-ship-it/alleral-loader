-- Noble V8 — lightweight Signal (Nevermore-style event)
local Signal = {}
Signal.__index = Signal

function Signal.new()
	return setmetatable({ _binds = {}, _once = {} }, Signal)
end

function Signal:Connect(fn)
	if type(fn) ~= "function" then return { Disconnect = function() end } end
	local id = #self._binds + 1
	self._binds[id] = fn
	return {
		Disconnect = function()
			if self._binds[id] then
				self._binds[id] = nil
			end
		end,
	}
end

function Signal:Once(fn)
	if type(fn) ~= "function" then return { Disconnect = function() end } end
	local conn
	conn = self:Connect(function(...)
		conn.Disconnect()
		fn(...)
	end)
	return conn
end

function Signal:Fire(...)
	for _, fn in pairs(self._binds) do
		if fn then
			pcall(fn, ...)
		end
	end
end

function Signal:Wait()
	local thread = coroutine.running()
	local conn
	conn = self:Connect(function(...)
		conn.Disconnect()
		task.spawn(thread, ...)
	end)
	return coroutine.yield()
end

function Signal:Destroy()
	self._binds = {}
end

return Signal