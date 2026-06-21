-- Alleral V11.2 — game-specific registry (PlaceId resolution, no cross-game bleed)
return function(Core)
	local GameRegistry = {}

	local ENTRIES = {
		kick_a_lucky_block = {
			id = "kick_a_lucky_block",
			name = "Kick a Lucky Block",
			placeIds = { 89469502395769 },
			universeIds = { 10004244222 },
		},
		speed_keyboard_escape = {
			id = "speed_keyboard_escape",
			name = "Speed Keyboard Escape",
			placeIds = { 95082159892680 },
		},
		slime_rng = {
			id = "slime_rng",
			name = "Slime RNG",
			placeIds = { 92416421522960 },
			universeIds = { 9792947201 },
		},
		build_a_ring_farm = {
			id = "build_a_ring_farm",
			name = "Build A Ring Farm",
			placeIds = { 107646426076756 },
		},
		survive_a_zombie_arena = {
			id = "survive_a_zombie_arena",
			name = "Survive a Zombie Arena",
			placeIds = { 114204398207377 },
		},
		sell_lemons = {
			id = "sell_lemons",
			name = "Sell Lemons",
			placeIds = { 79268393072444 },
		},
		grow_a_garden_2 = {
			id = "grow_a_garden_2",
			name = "Grow a Garden 2",
			placeIds = { 95204935687527 },
		},
		blox_fruit = {
			id = "blox_fruit",
			name = "Blox Fruit",
			placeIds = { 2753915549 },
		},
	}

	if Core and type(Core.GAME_REGISTRY) == "table" then
		for id, meta in pairs(Core.GAME_REGISTRY) do
			if type(meta) == "table" then
				ENTRIES[tostring(id)] = ENTRIES[tostring(id)] or {}
				for k, v in pairs(meta) do
					if ENTRIES[tostring(id)][k] == nil then
						ENTRIES[tostring(id)][k] = v
					end
				end
				ENTRIES[tostring(id)].id = tostring(id)
			end
		end
	end

	local function env()
		local ok, e = pcall(function()
			return getgenv and getgenv() or {}
		end)
		return ok and e or {}
	end

	function GameRegistry.list()
		local out = {}
		for id in pairs(ENTRIES) do
			table.insert(out, id)
		end
		table.sort(out)
		return out
	end

	function GameRegistry.get(gameId)
		if not gameId then
			return nil
		end
		return ENTRIES[tostring(gameId)]
	end

	function GameRegistry.resolve(options)
		options = type(options) == "table" and options or {}
		local placeId = tonumber(options.placeId) or game.PlaceId
		local universeId = tonumber(options.universeId) or game.GameId

		for id, meta in pairs(ENTRIES) do
			if type(meta.placeIds) == "table" then
				for _, pid in ipairs(meta.placeIds) do
					if pid == placeId then
						return id, meta
					end
				end
			end
			if type(meta.universeIds) == "table" then
				for _, uid in ipairs(meta.universeIds) do
					if uid == universeId then
						return id, meta
					end
				end
			end
		end

		local explicit = options.scriptId or options.gameId or options.id
		if explicit and tostring(explicit) ~= "" then
			local meta = ENTRIES[tostring(explicit)]
			if meta then
				return tostring(explicit), meta
			end
		end

		local ENV = env()
		local active = ENV.Alleral_ActiveScriptId
		if active and tostring(active) ~= "" then
			local meta = ENTRIES[tostring(active)]
			if meta then
				return tostring(active), meta
			end
		end

		if Core and type(Core.resolveActiveGameId) == "function" then
			local id = Core.resolveActiveGameId(options)
			if id and ENTRIES[tostring(id)] then
				return tostring(id), ENTRIES[tostring(id)]
			end
		end

		return nil, nil
	end

	function GameRegistry.isSupported(gameId)
		return ENTRIES[tostring(gameId or "")] ~= nil
	end

	function GameRegistry.configNamespace(gameId)
		gameId = tostring(gameId or "unsupported")
		return "configs/" .. gameId
	end

	return GameRegistry
end