-- Noble V8 — minimal Fusion-style reactive UI (loadstring-safe)
return function(Spr)
	local Fusion = {}
	local RunService = game:GetService("RunService")
	local captureStack = {}
	local specialMeta = { __tostring = function() return "FusionSpecialKey" end }

	local function isState(v)
		return type(v) == "table" and (v._isState or v._isComputed)
	end

	local function peekCapture(state)
		local frame = captureStack[#captureStack]
		if frame then frame[state] = true end
	end

	local function notify(observers, ...)
		for token, fn in pairs(observers) do
			if fn then task.spawn(fn, ...) else observers[token] = nil end
		end
	end

	local function capture(fn)
		local frame = {}
		table.insert(captureStack, frame)
		local ok, result = pcall(fn)
		table.remove(captureStack)
		if not ok then error(result, 0) end
		return result, frame
	end

	local function disconnectAll(list)
		for i = #list, 1, -1 do
			local conn = list[i]
			list[i] = nil
			if conn then
				if typeof(conn) == "RBXScriptConnection" then pcall(function() conn:Disconnect() end)
				elseif type(conn) == "table" and conn.Disconnect then pcall(conn.Disconnect, conn)
				elseif type(conn) == "function" then pcall(conn) end
			end
		end
	end

	local function subscribe(state, fn)
		if type(fn) ~= "function" then return { Disconnect = function() end } end
		local token = {}
		state._observers[token] = fn
		task.defer(fn, state._value)
		return { Disconnect = function() state._observers[token] = nil end }
	end

	local function bind(inst, prop, value, connections)
		local function apply(v)
			if inst.Parent ~= nil or prop == "Parent" then inst[prop] = v end
		end
		if isState(value) then
			apply(value:get())
			table.insert(connections, value:observe(apply))
		else
			apply(value)
		end
	end

	local function special(kind, data)
		local key = { _special = true, kind = kind }
		if data then for k, v in pairs(data) do key[k] = v end end
		return setmetatable(key, specialMeta)
	end

	local function flattenInto(child, out)
		if child == nil then return end
		if type(child) == "table" and child._flatten then
			for i = 1, #child do flattenInto(child[i], out) end
			return
		end
		if type(child) == "table" and child.kind == "Cleanup" then
			table.insert(out, child)
			return
		end
		if isState(child) or typeof(child) == "Instance" then
			table.insert(out, child)
			return
		end
		if type(child) == "table" then
			if child.ClassName then table.insert(out, child) return end
			for i = 1, #child do flattenInto(child[i], out) end
		end
	end

	local function flatten(...)
		local out = {}
		for i = 1, select("#", ...) do flattenInto(select(i, ...), out) end
		return out
	end

	local function resolveChildren(children)
		if type(children) == "table" and children._flatten then return children end
		return flatten(children)
	end

	local function Value(initial)
		local self = { _value = initial, _observers = {}, _isState = true }
		function self:get()
			peekCapture(self)
			return self._value
		end
		function self:set(v)
			if self._value == v then return end
			self._value = v
			notify(self._observers, v)
		end
		function self:observe(fn) return subscribe(self, fn) end
		return self
	end

	local function Computed(fn)
		local self = {
			_fn = fn, _value = nil, _valid = false, _observers = {},
			_deps = {}, _isComputed = true,
		}

		local recompute
		local function invalidate()
			if not self._valid then return end
			self._valid = false
			recompute()
		end

		recompute = function()
			disconnectAll(self._deps)
			local value, frame = capture(self._fn)
			self._value = value
			self._valid = true
			for dep in pairs(frame) do
				if dep.observe then table.insert(self._deps, dep:observe(invalidate)) end
			end
			notify(self._observers, self._value)
		end

		function self:get()
			if not self._valid then recompute() end
			peekCapture(self)
			return self._value
		end
		function self:observe(fn)
			if type(fn) ~= "function" then return { Disconnect = function() end } end
			local token = {}
			self._observers[token] = fn
			task.defer(function() fn(self:get()) end)
			return { Disconnect = function() self._observers[token] = nil end }
		end

		recompute()
		return self
	end

	local function springStep(pos, vel, target, speed, damping, dt)
		if Spr and type(Spr.spring) == "function" then
			local p, v = Spr.spring(pos, target, speed, damping, dt)
			return p, v or vel
		end
		if Spr and type(Spr.update) == "function" then
			return Spr.update(pos, target, speed, damping, dt), vel
		end
		local omega = speed * 2 * math.pi
		local x = pos - target
		local f = -omega * omega * x - 2 * damping * omega * vel
		local newVel = vel + f * dt
		return pos + newVel * dt, newVel
	end

	local function Spring(goal, speed, damping)
		speed = speed or 30
		damping = damping or 1
		local current = Value(tonumber(goal:get()) or 0)
		local velocity = 0
		local conn = RunService.Heartbeat:Connect(function(dt)
			local pos = current:get()
			local target = tonumber(goal:get()) or 0
			local nextPos, nextVel = springStep(pos, velocity, target, speed, damping, dt)
			velocity = nextVel
			if nextPos ~= pos then current:set(nextPos) end
		end)
		local spring = Computed(function() return current:get() end)
		spring._destroy = function()
			if conn then conn:Disconnect() conn = nil end
		end
		return spring
	end

	local function applyChildren(parent, children, connections, cleanups)
		local mounted, childConns = {}, {}

		local function drop(entry)
			if typeof(entry) == "Instance" then entry.Parent = nil
			elseif type(entry) == "table" and entry.kind == "Cleanup" then pcall(entry.fn)
			elseif isState(entry) and entry._destroy then pcall(entry._destroy) end
		end

		local function mountList(list)
			for i = #mounted, 1, -1 do drop(mounted[i]) mounted[i] = nil end
			disconnectAll(childConns)
			for _, entry in ipairs(list) do
				if type(entry) == "table" and entry.kind == "Cleanup" then
					table.insert(mounted, entry)
					table.insert(cleanups, entry.fn)
				elseif typeof(entry) == "Instance" then
					entry.Parent = parent
					table.insert(mounted, entry)
				elseif isState(entry) then
					local function apply()
						local v = entry:get()
						if typeof(v) == "Instance" then v.Parent = parent end
					end
					apply()
					table.insert(childConns, entry:observe(apply))
					table.insert(mounted, entry)
				end
			end
		end

		if isState(children) then
			local function update() mountList(resolveChildren(children:get())) end
			update()
			table.insert(connections, children:observe(update))
		else
			mountList(resolveChildren(children))
		end
	end

	local function New(className, props)
		props = props or {}
		local inst = Instance.new(className)
		local connections, cleanups = {}, {}

		local function destroy()
			disconnectAll(connections)
			for i = #cleanups, 1, -1 do pcall(cleanups[i]) cleanups[i] = nil end
		end

		table.insert(connections, inst.AncestryChanged:Connect(function(_, p)
			if p == nil then destroy() end
		end))

		for key, value in pairs(props) do
			if type(key) == "table" and key._special then
				if key.kind == "OnEvent" then
					local event = inst[key.name]
					if event and event.Connect and type(value) == "function" then
						table.insert(connections, event:Connect(value))
					end
				elseif key.kind == "OnChange" then
					if type(value) == "function" then
						table.insert(connections, inst:GetPropertyChangedSignal(key.name):Connect(function()
							value(inst[key.name])
						end))
					end
				elseif key.kind == "Children" then
					applyChildren(inst, value, connections, cleanups)
				end
			elseif key == "Parent" then
				bind(inst, "Parent", value, connections)
			elseif key == "Children" then
				applyChildren(inst, value, connections, cleanups)
			else
				bind(inst, key, value, connections)
			end
		end

		return inst
	end

	function Fusion.Children(...)
		local packed = { _flatten = true }
		for i = 1, select("#", ...) do packed[i] = select(i, ...) end
		return packed
	end

	function Fusion.Cleanup(fn) return { kind = "Cleanup", fn = fn } end
	function Fusion.OnEvent(name) return special("OnEvent", { name = name }) end
	function Fusion.OnChange(name) return special("OnChange", { name = name }) end
	function Fusion.Value(initial) return Value(initial) end
	function Fusion.Computed(fn) return Computed(fn) end
	function Fusion.Spring(goal, speed, damping) return Spring(goal, speed, damping) end
	function Fusion.Observer(state, fn)
		if state and state.observe then return state:observe(fn) end
		return { Disconnect = function() end }
	end

	Fusion.New = New
	return Fusion
end