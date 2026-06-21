-- Alleral V12 — game-specific navigation schemas
return function()
	local Schemas = {}

	Schemas.GAMES = {
		kick_a_lucky_block = {
			{ name = "Kick", icon = "sword" },
			{ name = "Plot", icon = "layout-grid" },
			{ name = "Events", icon = "calendar" },
			{ name = "Inventory", icon = "package" },
			{ name = "Misc", icon = "settings-2" },
			{ name = "Settings", icon = "settings" },
			{ name = "Dashboard", icon = "layout-dashboard" },
			{ name = "Tools", icon = "terminal" },
		},
		sell_lemons = {
			{ name = "Farming", icon = "sprout" },
			{ name = "Trees", icon = "tree-pine" },
			{ name = "Selling", icon = "coins" },
			{ name = "Upgrades", icon = "trending-up" },
			{ name = "Events", icon = "sparkles" },
			{ name = "Stats", icon = "bar-chart-3" },
			{ name = "Dashboard", icon = "layout-dashboard" },
			{ name = "Tools", icon = "terminal" },
		},
		build_a_ring_farm = {
			{ name = "Farm", icon = "sprout" },
			{ name = "Seeds", icon = "leaf" },
			{ name = "Upgrade", icon = "arrow-up" },
			{ name = "Shop", icon = "shopping-cart" },
			{ name = "Events", icon = "calendar" },
			{ name = "Pets", icon = "paw-print" },
			{ name = "Misc", icon = "settings-2" },
			{ name = "Settings", icon = "settings" },
		},
		grow_a_garden_2 = {
			{ name = "Farm", icon = "sprout" },
			{ name = "Water", icon = "droplets" },
			{ name = "Shop", icon = "shopping-cart" },
			{ name = "Settings", icon = "settings" },
		},
		slime_rng = {
			{ name = "Main", icon = "home" },
			{ name = "Auto", icon = "zap" },
			{ name = "Inventory", icon = "package" },
			{ name = "Misc", icon = "settings-2" },
			{ name = "Settings", icon = "settings" },
		},
		survive_a_zombie_arena = {
			{ name = "Farm", icon = "sprout" },
			{ name = "Combat", icon = "sword" },
			{ name = "Player", icon = "user" },
			{ name = "Visual", icon = "eye" },
			{ name = "Misc", icon = "settings-2" },
			{ name = "Settings", icon = "settings" },
		},
		speed_keyboard_escape = {
			{ name = "Main", icon = "home" },
			{ name = "Auto", icon = "zap" },
			{ name = "Shop", icon = "shopping-cart" },
			{ name = "Misc", icon = "settings-2" },
			{ name = "Settings", icon = "settings" },
		},
		blox_fruit = {
			{ name = "Status", icon = "activity" },
			{ name = "Dashboard", icon = "layout-dashboard" },
			{ name = "Tools", icon = "terminal" },
		},
	}

	function Schemas.get(gameId)
		return Schemas.GAMES[tostring(gameId or "")]
	end

	function Schemas.names(gameId)
		local schema = Schemas.get(gameId)
		if not schema then
			return {}
		end
		local out = {}
		for _, tab in ipairs(schema) do
			table.insert(out, tab.name)
		end
		return out
	end

	return Schemas
end