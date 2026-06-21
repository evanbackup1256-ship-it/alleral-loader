-- Alleral V11 — per-game config namespaces for WindUI
return function(Bootstrap)
	local Configs = {}

	function Configs.getNamespace(gameId)
		gameId = tostring(gameId or Bootstrap.resolveGameId() or "alleral")
		return "configs/" .. gameId
	end

	function Configs.listGames()
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