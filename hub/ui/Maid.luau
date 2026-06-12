local Maid = {}
Maid.__index = Maid

function Maid.new()
	return setmetatable({ _tasks = {} }, Maid)
end

function Maid:Give(task)
	if task == nil then
		return
	end
	local id = #self._tasks + 1
	self._tasks[id] = task
	return id
end

function Maid:GiveTask(fn)
	if type(fn) == "function" then
		return self:Give(fn)
	end
end

function Maid:GiveConnection(conn)
	if typeof(conn) == "RBXScriptConnection" then
		return self:Give(function()
			conn:Disconnect()
		end)
	end
end

function Maid:GiveInstance(inst)
	if typeof(inst) == "Instance" then
		return self:Give(function()
			if inst.Parent then
				inst:Destroy()
			end
		end)
	end
end

function Maid:DoCleaning()
	for i = #self._tasks, 1, -1 do
		local task = self._tasks[i]
		self._tasks[i] = nil
		if type(task) == "function" then
			pcall(task)
		elseif typeof(task) == "RBXScriptConnection" then
			pcall(function()
				task:Disconnect()
			end)
		elseif typeof(task) == "Instance" then
			pcall(function()
				task:Destroy()
			end)
		elseif type(task) == "table" and type(task.Destroy) == "function" then
			pcall(function()
				task:Destroy()
			end)
		end
	end
end

function Maid:Destroy()
	self:DoCleaning()
end

return Maid
