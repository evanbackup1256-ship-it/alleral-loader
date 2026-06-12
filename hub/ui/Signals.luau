local Signals = {}
Signals.__index = Signals

function Signals.new()
	return setmetatable({ _listeners = {} }, Signals)
end

function Signals:Connect(fn)
	if type(fn) ~= "function" then
		return { Disconnect = function() end }
	end
	local id = #self._listeners + 1
	self._listeners[id] = fn
	return {
		Disconnect = function()
			self._listeners[id] = nil
		end,
	}
end

function Signals:Fire(...)
	for _, fn in pairs(self._listeners) do
		task.spawn(fn, ...)
	end
end

function Signals:Wait()
	local thread = coroutine.running()
	local conn
	conn = self:Connect(function(...)
		conn:Disconnect()
		task.spawn(thread, ...)
	end)
	return coroutine.yield()
end

function Signals:Destroy()
	self._listeners = {}
end

return Signals
