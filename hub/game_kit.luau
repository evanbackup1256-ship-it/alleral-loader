-- Shared game-script helpers (LuxyHub-style parity utilities)
return function(Core)
	local GameKit = {}

	function GameKit.mergeDefaults(defaults)
		defaults = type(defaults) == "table" and defaults or {}
		if defaults.HubRunning == nil then
			defaults.HubRunning = true
		end
		if defaults.AntiAFK == nil then
			defaults.AntiAFK = true
		end
		if defaults.ABoostFPS == nil then
			defaults.ABoostFPS = false
		end
		if defaults.ARTXMod == nil then
			defaults.ARTXMod = false
		end
		if defaults.ABlackScreen == nil then
			defaults.ABlackScreen = false
		end
		if defaults.AutoRejoin == nil then
			defaults.AutoRejoin = false
		end
		if defaults.AAutoLoadConfig == nil then
			defaults.AAutoLoadConfig = false
		end
		if defaults.AutoLoadProfile == nil then
			defaults.AutoLoadProfile = "default"
		end
		return defaults
	end

	function GameKit.rejoinCurrentServer()
		local TeleportService = game:GetService("TeleportService")
		local Players = game:GetService("Players")
		local lp = Players.LocalPlayer
		if not lp then
			return false
		end
		local ok = pcall(function()
			TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, lp)
		end)
		return ok
	end

	function GameKit.tickAutoRejoin(state, runtime, delaySec)
		if not state or state.AutoRejoin ~= true then
			return
		end
		runtime = type(runtime) == "table" and runtime or {}
		if runtime.rejoinQueued then
			return
		end
		runtime.rejoinQueued = true
		task.delay(tonumber(delaySec) or 2, function()
			GameKit.rejoinCurrentServer()
		end)
	end

	function GameKit.leaderstat(player, names)
		player = player or game:GetService("Players").LocalPlayer
		names = type(names) == "table" and names or { names }
		local folder = player and player:FindFirstChild("leaderstats")
		if not folder then
			return "?"
		end
		for _, name in ipairs(names) do
			local value = folder:FindFirstChild(name)
			if value and (value:IsA("IntValue") or value:IsA("NumberValue") or value:IsA("StringValue")) then
				return tostring(value.Value)
			end
		end
		return "?"
	end

	function GameKit.applyPerfState(state)
		if type(Core.applyPerformanceState) == "function" then
			pcall(Core.applyPerformanceState, state)
		end
	end

	return GameKit
end