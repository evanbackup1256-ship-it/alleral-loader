-- Noble V8 — vendored spring animation (Fraktality/spr-style API)
-- Spring-driven motion for UI properties. No TweenService.

local SLEEP_OFFSET_SQ_LIMIT = (1 / 3840) ^ 2
local SLEEP_VELOCITY_SQ_LIMIT = 0.01 ^ 2
local EPS = 1e-5

local RunService = game:GetService("RunService")

local pi = math.pi
local exp = math.exp
local sin = math.sin
local cos = math.cos
local sqrt = math.sqrt
local round = math.round

local function magnitudeSq(vec)
	local out = 0
	for i = 1, #vec do
		out = out + vec[i] ^ 2
	end
	return out
end

local function distanceSq(vec0, vec1)
	local out = 0
	for i = 1, #vec0 do
		local delta = vec1[i] - vec0[i]
		out = out + delta * delta
	end
	return out
end

local LinearSpring = {}
LinearSpring.__index = LinearSpring

function LinearSpring.new(dampingRatio, frequency, pos, rawGoal, typedat)
	local linearPos = typedat.toIntermediate(pos)
	local velocity = {}
	for i = 1, #linearPos do
		velocity[i] = 0
	end
	return setmetatable({
		d = dampingRatio,
		f = frequency,
		g = linearPos,
		p = linearPos,
		v = velocity,
		typedat = typedat,
		rawGoal = rawGoal,
	}, LinearSpring)
end

function LinearSpring:setGoal(goal)
	self.rawGoal = goal
	self.g = self.typedat.toIntermediate(goal)
end

function LinearSpring:setDampingRatio(dampingRatio)
	self.d = dampingRatio
end

function LinearSpring:setFrequency(frequency)
	self.f = frequency
end

function LinearSpring:canSleep()
	if magnitudeSq(self.v) > SLEEP_VELOCITY_SQ_LIMIT then
		return false
	end
	if distanceSq(self.p, self.g) > SLEEP_OFFSET_SQ_LIMIT then
		return false
	end
	return true
end

function LinearSpring:step(dt)
	local d = self.d
	local f = self.f * (2 * pi)
	local g = self.g
	local p = self.p
	local v = self.v

	if d == 1 then
		local q = exp(-f * dt)
		local w = dt * q
		local c0 = q + w * f
		local c2 = q - w * f
		local c3 = w * f * f

		for idx = 1, #p do
			local o = p[idx] - g[idx]
			p[idx] = o * c0 + v[idx] * w + g[idx]
			v[idx] = v[idx] * c2 - o * c3
		end
	elseif d < 1 then
		local q = exp(-d * f * dt)
		local c = sqrt(1 - d * d)
		local i = cos(dt * f * c)
		local j = sin(dt * f * c)

		local z
		if c > EPS then
			z = j / c
		else
			local a = dt * f
			z = a + ((a * a) * (c * c) * (c * c) / 20 - c * c) * (a * a * a) / 6
		end

		local y
		if f * c > EPS then
			y = j / (f * c)
		else
			local b = f * c
			y = dt + ((dt * dt) * (b * b) * (b * b) / 20 - b * b) * (dt * dt * dt) / 6
		end

		for idx = 1, #p do
			local o = p[idx] - g[idx]
			p[idx] = (o * (i + z * d) + v[idx] * y) * q + g[idx]
			v[idx] = (v[idx] * (i - z * d) - o * (z * f)) * q
		end
	else
		local c = sqrt(d * d - 1)
		local r1 = -f * (d + c)
		local r2 = -f * (d - c)
		local ec1 = exp(r1 * dt)
		local ec2 = exp(r2 * dt)

		for idx = 1, #p do
			local o = p[idx] - g[idx]
			local co2 = (v[idx] - o * r1) / (2 * f * c)
			local co1 = ec1 * (o - co2)
			p[idx] = co1 + co2 * ec2 + g[idx]
			v[idx] = co1 * r1 + co2 * ec2 * r2
		end
	end

	return self.typedat.fromIntermediate(self.p)
end

local typeMetadata = {
	boolean = {
		springType = LinearSpring.new,
		toIntermediate = function(value)
			return { value and 1 or 0 }
		end,
		fromIntermediate = function(value)
			return value[1] >= 0.5
		end,
	},
	number = {
		springType = LinearSpring.new,
		toIntermediate = function(value)
			return { value }
		end,
		fromIntermediate = function(value)
			return value[1]
		end,
	},
	UDim2 = {
		springType = LinearSpring.new,
		toIntermediate = function(value)
			return { value.X.Scale, value.X.Offset, value.Y.Scale, value.Y.Offset }
		end,
		fromIntermediate = function(value)
			return UDim2.new(value[1], round(value[2]), value[3], round(value[4]))
		end,
	},
	Vector2 = {
		springType = LinearSpring.new,
		toIntermediate = function(value)
			return { value.X, value.Y }
		end,
		fromIntermediate = function(value)
			return Vector2.new(value[1], value[2])
		end,
	},
	Vector3 = {
		springType = LinearSpring.new,
		toIntermediate = function(value)
			return { value.X, value.Y, value.Z }
		end,
		fromIntermediate = function(value)
			return Vector3.new(value[1], value[2], value[3])
		end,
	},
	Color3 = {
		springType = LinearSpring.new,
		toIntermediate = function(value)
			return { value.R, value.G, value.B }
		end,
		fromIntermediate = function(value)
			return Color3.new(value[1], value[2], value[3])
		end,
	},
}

local PSEUDO_PROPERTIES = {
	Scale = {
		class = "GuiObject",
		get = function(inst)
			local uiScale = inst:FindFirstChildOfClass("UIScale")
			if uiScale then
				return uiScale.Scale
			end
			return 1
		end,
		set = function(inst, value)
			local uiScale = inst:FindFirstChildOfClass("UIScale")
			if not uiScale then
				uiScale = Instance.new("UIScale")
				uiScale.Parent = inst
			end
			uiScale.Scale = value
		end,
	},
}

local function getProperty(instance, property)
	local override = PSEUDO_PROPERTIES[property]
	if override and instance:IsA(override.class) then
		return override.get(instance)
	end
	return instance[property]
end

local function setProperty(instance, property, value)
	local override = PSEUDO_PROPERTIES[property]
	if override and instance:IsA(override.class) then
		override.set(instance, value)
	else
		instance[property] = value
	end
end

local springStates = {}
local completedCallbacks = {}

local function flushCompleted(instance)
	local callbackList = completedCallbacks[instance]
	if not callbackList then
		return
	end
	completedCallbacks[instance] = nil
	for i = 1, #callbackList do
		task.spawn(callbackList[i])
	end
end

local function processSprings(dt)
	for instance, state in pairs(springStates) do
		for propName, spring in pairs(state) do
			if spring:canSleep() then
				state[propName] = nil
				setProperty(instance, propName, spring.rawGoal)
			else
				setProperty(instance, propName, spring:step(dt))
			end
		end

		if next(state) == nil then
			springStates[instance] = nil
			flushCompleted(instance)
		end
	end
end

RunService.PreSimulation:Connect(function(dt)
	processSprings(dt)
end)

local Spr = {}

function Spr.target(instance, dampingRatio, frequency, properties)
	if typeof(instance) ~= "Instance" then
		error("bad argument #1 to Spr.target (Instance expected)", 2)
	end
	if type(dampingRatio) ~= "number" then
		error("bad argument #2 to Spr.target (number expected)", 2)
	end
	if type(frequency) ~= "number" then
		error("bad argument #3 to Spr.target (number expected)", 2)
	end
	if type(properties) ~= "table" then
		error("bad argument #4 to Spr.target (table expected)", 2)
	end

	if dampingRatio ~= dampingRatio or dampingRatio < 0 then
		error("expected damping ratio >= 0", 2)
	end
	if frequency ~= frequency or frequency < 0 then
		error("expected undamped frequency >= 0", 2)
	end

	local state = springStates[instance]
	if not state then
		state = {}
		springStates[instance] = state
	end

	for propName, propTarget in pairs(properties) do
		local propValue = getProperty(instance, propName)

		if frequency == math.huge then
			setProperty(instance, propName, propTarget)
			state[propName] = nil
		else
			local spring = state[propName]
			if not spring then
				local md = typeMetadata[typeof(propTarget)]
				if not md then
					error("unsupported type: " .. typeof(propTarget), 2)
				end
				spring = md.springType(dampingRatio, frequency, propValue, propTarget, md)
				state[propName] = spring
			end
			spring:setGoal(propTarget)
			spring:setDampingRatio(dampingRatio)
			spring:setFrequency(frequency)
		end
	end

	if next(state) == nil then
		springStates[instance] = nil
	end
end

function Spr.stop(instance, property)
	if typeof(instance) ~= "Instance" then
		error("bad argument #1 to Spr.stop (Instance expected)", 2)
	end

	if property then
		local state = springStates[instance]
		if state then
			state[property] = nil
			if next(state) == nil then
				springStates[instance] = nil
			end
		end
	else
		springStates[instance] = nil
	end
end

function Spr.completed(instance, callback)
	if typeof(instance) ~= "Instance" then
		error("bad argument #1 to Spr.completed (Instance expected)", 2)
	end
	if type(callback) ~= "function" then
		error("bad argument #2 to Spr.completed (function expected)", 2)
	end

	local callbackList = completedCallbacks[instance]
	if callbackList then
		table.insert(callbackList, callback)
	else
		completedCallbacks[instance] = { callback }
	end
end

return Spr