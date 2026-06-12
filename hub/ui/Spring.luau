local RunService = game:GetService("RunService")

local Spring = {}
Spring.__index = Spring

local active = {}
local loopStarted = false

local function ensureLoop()
	if loopStarted then
		return
	end
	loopStarted = true
	RunService.RenderStepped:Connect(function(dt)
		for inst, props in pairs(active) do
			if not inst or not inst.Parent then
				active[inst] = nil
			else
			for prop, state in pairs(props) do
				local current = inst[prop]
				if current ~= nil then
					local goal = state.goal
					local vel = state.velocity
					local freq = state.frequency
					local damp = state.damping
					local alpha = 1 - math.exp(-freq * dt)
					local next
					if typeof(current) == "number" then
						local delta = goal - current
						vel = vel + delta * freq * freq * dt
						vel = vel * (1 - damp * dt)
						next = current + vel * dt
						if math.abs(goal - next) < 0.001 and math.abs(vel) < 0.001 then
							next = goal
							vel = 0
							if state.onComplete then
								local cb = state.onComplete
								state.onComplete = nil
								task.defer(cb)
							end
						end
					elseif typeof(current) == "UDim2" then
						local dx = goal.X.Offset - current.X.Offset
						local dy = goal.Y.Offset - current.Y.Offset
						local vx = (state.vx or 0) + dx * freq * freq * dt
						local vy = (state.vy or 0) + dy * freq * freq * dt
						vx = vx * (1 - damp * dt)
						vy = vy * (1 - damp * dt)
						next = UDim2.fromOffset(current.X.Offset + vx * dt, current.Y.Offset + vy * dt)
						state.vx, state.vy = vx, vy
					elseif typeof(current) == "Color3" then
						next = current:Lerp(goal, alpha)
						if (goal - next).Magnitude < 0.002 then
							next = goal
							if state.onComplete then
								local cb = state.onComplete
								state.onComplete = nil
								task.defer(cb)
							end
						end
					end
					if next ~= nil then
						inst[prop] = next
						state.velocity = vel
					end
				end
			end
			if next(props) == nil then
				active[inst] = nil
			end
			end
		end
	end)
end

function Spring.target(instance, damping, frequency, goals, onComplete)
	if not instance or type(goals) ~= "table" then
		return
	end
	ensureLoop()
	active[instance] = active[instance] or {}
	for prop, goal in pairs(goals) do
		active[instance][prop] = {
			goal = goal,
			velocity = 0,
			frequency = frequency or 6,
			damping = damping or 1,
			onComplete = onComplete,
		}
	end
end

function Spring.stop(instance, property)
	if not active[instance] then
		return
	end
	if property then
		active[instance][property] = nil
		if next(active[instance]) == nil then
			active[instance] = nil
		end
	else
		active[instance] = nil
	end
end

function Spring.completed(instance, callback)
	if type(callback) ~= "function" or not active[instance] then
		return
	end
	for _, state in pairs(active[instance]) do
		state.onComplete = callback
		break
	end
end

return Spring
