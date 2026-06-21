-- Alleral V11.2 — per-game config namespaces for WindUI
return function(Bootstrap, GameRegistry)
	local Configs = {}

	function Configs.getNamespace(gameId)
		gameId = tostring(gameId or Bootstrap.resolveGameId() or "unsupported")
		if GameRegistry and type(GameRegistry.configNamespace) == "function" then
			return GameRegistry.configNamespace(gameId)
		end
		return "configs/" .. gameId
	end

	function Configs.listGames()
		if GameRegistry and type(GameRegistry.list) == "function" then
			return GameRegistry.list()
		end
		return {
			"blox_fruit",
			"build_a_ring_farm",
			"grow_a_garden_2",
			"kick_a_lucky_block",
			"sell_lemons",
			"slime_rng",
			"speed_keyboard_escape",
			"survive_a_zombie_arena",
		}
	end

	return Configs
end