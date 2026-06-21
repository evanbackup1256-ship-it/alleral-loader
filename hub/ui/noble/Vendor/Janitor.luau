-- Noble V8 — Janitor lifecycle cleanup
local Janitor = {}
Janitor.__index = Janitor
Janitor.ClassName = "Janitor"

function Janitor.new()
	return setmetatable({ _tasks = {}, _destroyed = false }, Janitor)
end

function Janitor:Add(object, methodName, index)
	if self._destroyed then return object end
	if index then
		self:Remove(index)
	end
	table.insert(self._tasks, {
		object = object,
		method = methodName or "Destroy",
		index = index,
	})
	return object
end

function Janitor:AddPromise(promise)
	return self:Add(promise, "cancel")
end

function Janitor:GiveTask(task)
	return self:Add(task)
end

function Janitor:Connect(signal, fn)
	if signal and signal.Connect then
		return self:Add(signal:Connect(fn), "Disconnect")
	end
	return nil
end

function Janitor:Remove(index)
	for i, entry in ipairs(self._tasks) do
		if entry.index == index then
			table.remove(self._tasks, i)
			return true
		end
	end
	return false
end

local function cleanupEntry(entry)
	local obj = entry.object
	if not obj then return end
	local method = entry.method
	if type(method) == "string" then
		local fn = obj[method]
		if type(fn) == "function" then
			pcall(fn, obj)
		end
	elseif type(method) == "function" then
		pcall(method, obj)
	end
end

function Janitor:Cleanup()
	if self._destroyed then return end
	for i = #self._tasks, 1, -1 do
		cleanupEntry(self._tasks[i])
		self._tasks[i] = nil
	end
end

function Janitor:Destroy()
	self:Cleanup()
	self._destroyed = true
end

return Janitor