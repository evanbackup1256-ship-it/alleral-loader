-- Alleral V12 — unified WindUI runtime (event bus + managers)
return function(loadModule, Core)
	local EventBus = loadModule("EventBus")()
	local ConnectionTracker = loadModule("ConnectionTracker")(EventBus)
	local PerformanceManager = loadModule("managers/PerformanceManager")(EventBus, ConnectionTracker)
	local AnimationManager = loadModule("managers/AnimationManager")(EventBus)
	local LayoutManager = loadModule("managers/LayoutManager")()
	local GameTabSchemas = loadModule("GameTabSchemas")()

	local Runtime = {
		EventBus = EventBus,
		ConnectionTracker = ConnectionTracker,
		PerformanceManager = PerformanceManager,
		AnimationManager = AnimationManager,
		Motion = AnimationManager,
		LayoutManager = LayoutManager,
		GameTabSchemas = GameTabSchemas,
		_core = Core,
		_modules = {},
	}

	function Runtime.load(name, ...)
		if Runtime._modules[name] then
			return Runtime._modules[name]
		end
		local mod = loadModule(name)
		if type(mod) == "function" then
			mod = mod(...)
		end
		Runtime._modules[name] = mod
		return mod
	end

	return Runtime
end