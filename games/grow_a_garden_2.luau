getgenv().Alleral_State = getgenv().Alleral_State or {}

local Core = getgenv().Alleral_Core
if not Core or not Core.assertLoader or not Core.assertLoader() then
	return
end

local VERSION = "2.3.0"
local PLACE_ID = 95204935687527
local state = getgenv().Alleral_State
local G = (Core and Core.Game) or getgenv().Alleral_GameHelpers or {}
local connections = {}
local loops = {}
local loopControllers = {}

local ui
local bootErr
Core, ui, bootErr = Core.boot(state)
if not Core or not ui then
	getgenv().Alleral_StartupFailed = bootErr or "boot failed"
	return
end
G = Core.Game or G

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local TeleportService = game:GetService("TeleportService")
local LocalPlayer = Players.LocalPlayer

local SETTINGS_FILE = "grow_a_garden_2.json"
local SETTINGS_EXCLUDE = { HubRunning = true, PlayerPlot = true }
local defaults = {
	HubRunning = true,
	AntiAFK = true,
	AAutoLoadConfig = false,
	AutoLoadProfile = "default",
	AutoPlantSeed = false,
	AutoPlantAllSeeds = false,
	AutoShovelSeed = false,
	AutoCollectSeeds = false,
	StopCollectWhenFull = true,
	AutoCollectGoldSeeds = false,
	AutoCollectRainbowSeeds = false,
	AutoCollectAllDrops = false,
	AutoWateringCan = false,
	AutoSprinklerSystem = false,
	AutoBuySeedShop = false,
	AutoBuyCrate = false,
	AutoBuyGearShop = false,
	AutoBuyPet = false,
	AutoBlacklist = false,
	AutoBlacklistAll = false,
	AutoBlacklistBest = false,
	AutoSellSelectedFruits = false,
	AutoSellAllSeeds = false,
	AutoStealFruits = false,
	AutoWeatherPredictor = false,
	AutoSeedPredictor = false,
	AutoGearPredictor = false,
	AutoRejoin = false,
	PlantSpeed = 1,
	PlantInterval = 1,
	ShovelInterval = 2,
	CollectInterval = 0.75,
	WaterAmount = 1,
	WaterDelay = 1.5,
	SprinklerAmount = 1,
	SprinklerDelay = 2,
	ShopInterval = 3,
	PetBuyInterval = 4,
	BlacklistInterval = 2,
	AutoSellDelay = 3,
	StealInterval = 2,
	ReturnAfterSteal = 2,
	PredictorInterval = 10,
	TargetSeeds = { "Any" },
	TargetRarities = { "Any" },
	TargetMutations = { "Any" },
	BlacklistSeeds = { "Any" },
	BlacklistMutations = { "Any" },
	BlacklistRarities = { "Any" },
	TargetSprinklerSeeds = { "Any" },
	TargetSeedShop = { "Any" },
	TargetCrates = { "Any" },
	TargetGearShop = { "Any" },
	TargetPets = { "Any" },
	TargetSellSeeds = { "Any" },
	TargetSellRarities = { "Any" },
	TargetSellMutations = { "Any" },
	SprinklerVariant = "Any",
}
defaults = Core.mergeGameDefaults(defaults)

local savedKeys
local saveSettings
saveSettings, savedKeys = Core.initSettings(state, defaults, SETTINGS_FILE, SETTINGS_EXCLUDE)
state.HubRunning = true

local function notify(title, text, duration, notifyType)
	Core.notify(title, text, duration, notifyType)
end

local function waitChild(parent, name, timeout)
	if G.waitChild then return G.waitChild(parent, name, timeout) end
	return Core.waitChild(parent, name, timeout)
end

local function leaderstat(name)
	if G.leaderstatValue then return G.leaderstatValue(LocalPlayer, name) end
	local folder = LocalPlayer:FindFirstChild("leaderstats")
	local value = folder and folder:FindFirstChild(name)
	if value and (value:IsA("IntValue") or value:IsA("NumberValue") or value:IsA("StringValue")) then
		return tostring(value.Value)
	end
	return "?"
end

local DEFAULT_CATALOG = {
	seeds = {
		"Any", "Carrot", "Strawberry", "Blueberry", "Tomato", "Corn", "Pumpkin", "Watermelon",
		"Cactus", "Sunflower", "Mushroom", "Bamboo", "Coconut", "Mango", "Grape", "Pepper",
		"Eggplant", "Rose", "Daffodil", "Lotus", "Dragon Fruit", "Sugar Apple", "Beanstalk",
	},
	mutations = {
		"Any", "Normal", "Gold", "Rainbow", "Wet", "Shiny", "Frozen", "Moonlit", "Chilled",
		"Sundried", "Celestial", "Pollinated", "Voidtouched",
	},
	rarities = {
		"Any", "Common", "Uncommon", "Rare", "Epic", "Legendary", "Mythic", "Divine", "Prismatic",
	},
	gears = {
		"Any", "Shovel", "Watering Can", "Sprinkler", "Backpack", "Speed Boots", "Harvest Tool",
		"Golden Shovel", "Advanced Sprinkler",
	},
	pets = {
		"Any", "Common Egg", "Rare Egg", "Legendary Egg", "Dog", "Cat", "Bunny", "Dragon", "Fox", "Owl",
	},
	crates = { "Any", "Basic", "Premium", "Golden", "Diamond", "Mythic", "Seed Pack" },
	sprinklers = { "Any", "Basic", "Advanced", "Golden", "Diamond" },
}

local runtime = {
	remotes = {},
	timers = {},
	playerPlot = nil,
	catalog = nil,
	dropdowns = {},
}

local REMOTE_ALIASES = {
	PlantSeed = { "PlantSeed", "Plant", "PlantCrop", "PlantAll" },
	ShovelSeed = { "ShovelSeed", "Shovel", "RemoveSeed", "ClearSeed" },
	CollectSeed = { "CollectSeed", "CollectSeeds", "PickupSeed", "HarvestSeed" },
	Water = { "Water", "WateringCan", "UseWateringCan", "WaterPlot" },
	Sprinkler = { "Sprinkler", "PlaceSprinkler", "UseSprinkler", "SprinklerSystem" },
	BuySeed = { "BuySeed", "PurchaseSeed", "SeedShop", "BuySeedShop" },
	BuyCrate = { "BuyCrate", "PurchaseCrate", "CrateShop" },
	BuyGear = { "BuyGear", "PurchaseGear", "GearShop" },
	BuyPet = { "BuyPet", "PurchasePet", "PetShop", "BuyPetShop" },
	BlacklistSeed = { "BlacklistSeed", "SeedBlacklist", "BlackListSeed", "ToggleBlacklist", "SetBlacklist" },
	SellFruit = { "SellFruit", "SellFruits", "SellSeed", "SellSeeds", "SellInventory" },
	CollectDrop = { "CollectDrop", "CollectDrops", "PickupDrop", "PickupDrops", "CollectItem", "CollectItems" },
	StealFruit = { "StealFruit", "StealFruits", "StealSeed", "StealSeeds" },
	WeatherPredict = { "WeatherPredict", "PredictWeather", "GetWeatherPrediction" },
	SeedPredict = { "SeedPredict", "PredictSeed", "GetSeedPrediction" },
	GearPredict = { "GearPredict", "PredictGear", "GetGearPrediction" },
}

local function refreshRemotes()
	if G.bindRemoteAliases then
		runtime.remotes = G.bindRemoteAliases(ReplicatedStorage, runtime.remotes, REMOTE_ALIASES)
		return
	end
	runtime.remotes = G.indexRemotes and G.indexRemotes(ReplicatedStorage, runtime.remotes) or runtime.remotes
	for key, names in pairs(REMOTE_ALIASES) do
		local remote = G.findRemote and G.findRemote(runtime.remotes, names)
		if remote then
			runtime.remotes[key] = remote
		end
	end
end
refreshRemotes()

local function fireKey(key, ...)
	local remote = runtime.remotes[key]
	if remote and G.fireRemote then return G.fireRemote(remote, ...) end
	if remote then
		local ok = pcall(function()
			if remote:IsA("RemoteEvent") then
				remote:FireServer(...)
			elseif remote:IsA("RemoteFunction") then
				remote:InvokeServer(...)
			end
		end)
		return ok
	end
	return G.probeRemote and G.probeRemote(runtime.remotes, REMOTE_ALIASES[key] or { key }, { ... }) or false
end

local function tickEvery(key, interval, fn)
	runtime.timers[key] = runtime.timers[key] or 0
	if tick() < runtime.timers[key] then return end
	runtime.timers[key] = tick() + interval
	fn()
end

local function resolvePlayerPlot()
	if runtime.playerPlot and runtime.playerPlot.Parent then return runtime.playerPlot end
	local plots = Workspace:FindFirstChild("Plots") or Workspace:FindFirstChild("Farms") or Workspace:FindFirstChild("Gardens")
	if not plots then return nil end
	for _, plot in ipairs(plots:GetChildren()) do
		local owner = plot:GetAttribute("Owner") or plot:GetAttribute("UserId") or plot:GetAttribute("Player")
		if owner == LocalPlayer.Name or owner == LocalPlayer.UserId or owner == tostring(LocalPlayer.UserId) then
			runtime.playerPlot = plot
			state.PlayerPlot = plot.Name
			return plot
		end
	end
	local tagged = plots:FindFirstChild(LocalPlayer.Name)
	if tagged then
		runtime.playerPlot = tagged
		state.PlayerPlot = tagged.Name
		return tagged
	end
	return nil
end

local function inventoryFull()
	local backpack = LocalPlayer:FindFirstChild("Backpack")
	local char = LocalPlayer.Character
	local count = 0
	if backpack then count += #backpack:GetChildren() end
	if char then
		for _, item in ipairs(char:GetChildren()) do
			if item:IsA("Tool") then count += 1 end
		end
	end
	local max = LocalPlayer:GetAttribute("MaxInventory") or LocalPlayer:GetAttribute("InventoryCap") or 999
	return count >= max
end

local function characterRoot()
	local character = LocalPlayer.Character
	return character and character:FindFirstChild("HumanoidRootPart")
end

local function selectionOk(selected, value)
	local list = Core.normalizeMultiSelection(selected)
	if #list == 0 or list[1] == "Any" then return true end
	local lower = string.lower(tostring(value or ""))
	for _, item in ipairs(list) do
		if string.lower(item) == lower then return true end
	end
	return false
end

local function selectionValues(selected)
	local values = Core.normalizeMultiSelection(selected)
	if #values == 0 then return { "Any" } end
	return values
end

local function uniqueList(base, extra)
	local seen = {}
	local out = {}
	for _, name in ipairs(base or {}) do
		local key = string.lower(tostring(name))
		if not seen[key] then
			seen[key] = true
			table.insert(out, tostring(name))
		end
	end
	if type(extra) == "table" then
		for _, name in ipairs(extra) do
			local text = tostring(name or "")
			if text ~= "" then
				local key = string.lower(text)
				if not seen[key] then
					seen[key] = true
					table.insert(out, text)
				end
			end
		end
	end
	table.sort(out, function(a, b)
		if a == "Any" then return true end
		if b == "Any" then return false end
		return a < b
	end)
	if out[1] ~= "Any" then
		table.insert(out, 1, "Any")
	end
	return out
end

local function namesFromData(data)
	local names = {}
	if type(data) ~= "table" then
		return names
	end
	for key, value in pairs(data) do
		if type(key) == "string" and key ~= "" then
			table.insert(names, key)
		elseif type(value) == "table" then
			local label = value.Name or value.DisplayName or value.Id or value.id
			if type(label) == "string" and label ~= "" then
				table.insert(names, label)
			end
		end
	end
	return names
end

local function tryModuleData(...)
	for i = 1, select("#", ...) do
		local mod = select(i, ...)
		if typeof(mod) == "Instance" and mod:IsA("ModuleScript") then
			local data
			if G.registryGameModule then
				data = G.registryGameModule(mod, 6)
			else
				local ok, result = pcall(require, mod)
				data = ok and result or nil
			end
			if type(data) == "table" then
				return data
			end
		end
	end
	return nil
end

local function syncGameCatalog()
	local catalog = {
		seeds = table.clone(DEFAULT_CATALOG.seeds),
		mutations = table.clone(DEFAULT_CATALOG.mutations),
		rarities = table.clone(DEFAULT_CATALOG.rarities),
		gears = table.clone(DEFAULT_CATALOG.gears),
		pets = table.clone(DEFAULT_CATALOG.pets),
		crates = table.clone(DEFAULT_CATALOG.crates),
		sprinklers = table.clone(DEFAULT_CATALOG.sprinklers),
	}
	local roots = {
		ReplicatedStorage:FindFirstChild("SeedData"),
		ReplicatedStorage:FindFirstChild("Seeds"),
		ReplicatedStorage:FindFirstChild("Data"),
		ReplicatedStorage:FindFirstChild("Shared") and ReplicatedStorage.Shared:FindFirstChild("Seeds"),
		ReplicatedStorage:FindFirstChild("Modules") and ReplicatedStorage.Modules:FindFirstChild("SeedData"),
		ReplicatedStorage:FindFirstChild("Modules") and ReplicatedStorage.Modules:FindFirstChild("GearData"),
		ReplicatedStorage:FindFirstChild("Modules") and ReplicatedStorage.Modules:FindFirstChild("PetData"),
	}
	local seedData = tryModuleData(table.unpack(roots))
	if seedData then
		catalog.seeds = uniqueList(DEFAULT_CATALOG.seeds, namesFromData(seedData.Seeds or seedData.seeds or seedData))
	end
	local gearData = tryModuleData(
		ReplicatedStorage:FindFirstChild("GearData"),
		ReplicatedStorage:FindFirstChild("Modules") and ReplicatedStorage.Modules:FindFirstChild("GearData")
	)
	if gearData then
		catalog.gears = uniqueList(DEFAULT_CATALOG.gears, namesFromData(gearData.Gears or gearData.gears or gearData))
	end
	local petData = tryModuleData(
		ReplicatedStorage:FindFirstChild("PetData"),
		ReplicatedStorage:FindFirstChild("Modules") and ReplicatedStorage.Modules:FindFirstChild("PetData")
	)
	if petData then
		catalog.pets = uniqueList(DEFAULT_CATALOG.pets, namesFromData(petData.Pets or petData.pets or petData.Eggs or petData))
	end
	runtime.catalog = catalog
	return catalog
end

local function refreshCatalogDropdowns()
	local catalog = runtime.catalog or syncGameCatalog()
	local function refresh(dropdown, values, current)
		if not dropdown then
			return
		end
		pcall(function()
			if dropdown.Refresh then
				dropdown:Refresh(values)
			elseif dropdown.SetValues then
				dropdown:SetValues(values)
			end
		end)
		if type(current) == "table" and dropdown.SetValue then
			pcall(function()
				dropdown:SetValue(current)
			end)
		end
	end
	refresh(runtime.dropdowns.plantSeeds, catalog.seeds, state.TargetSeeds)
	refresh(runtime.dropdowns.plantRarities, catalog.rarities, state.TargetRarities)
	refresh(runtime.dropdowns.plantMutations, catalog.mutations, state.TargetMutations)
	refresh(runtime.dropdowns.sprinklerSeeds, catalog.seeds, state.TargetSprinklerSeeds)
	refresh(runtime.dropdowns.seedShop, catalog.seeds, state.TargetSeedShop)
	refresh(runtime.dropdowns.crateShop, catalog.crates, state.TargetCrates)
	refresh(runtime.dropdowns.gearShop, catalog.gears, state.TargetGearShop)
	refresh(runtime.dropdowns.petShop, catalog.pets, state.TargetPets)
	refresh(runtime.dropdowns.blacklistSeeds, catalog.seeds, state.BlacklistSeeds)
	refresh(runtime.dropdowns.blacklistMutations, catalog.mutations, state.BlacklistMutations)
	refresh(runtime.dropdowns.blacklistRarities, catalog.rarities, state.BlacklistRarities)
	refresh(runtime.dropdowns.sellSeeds, catalog.seeds, state.TargetSellSeeds)
	refresh(runtime.dropdowns.sellRarities, catalog.rarities, state.TargetSellRarities)
	refresh(runtime.dropdowns.sellMutations, catalog.mutations, state.TargetSellMutations)
end

local function plotContext()
	local plot = resolvePlayerPlot()
	return plot and plot.Name or nil
end

local function partPosition(inst)
	if inst:IsA("BasePart") then
		return inst.Position
	end
	if inst:IsA("Model") then
		local ok, pivot = pcall(function()
			return inst:GetPivot()
		end)
		if ok and pivot then
			return pivot.Position
		end
		local part = inst.PrimaryPart or inst:FindFirstChildWhichIsA("BasePart")
		return part and part.Position or nil
	end
	return nil
end

local function targetPart(inst)
	if inst:IsA("BasePart") then
		return inst
	end
	if inst:IsA("Model") then
		return inst.PrimaryPart or inst:FindFirstChildWhichIsA("BasePart")
	end
	return nil
end

local function touchOrMoveTo(inst)
	local root = characterRoot()
	local part = targetPart(inst)
	if not root or not part then
		return false
	end
	if G.touchPart then
		return G.touchPart(root, part)
	end
	root.CFrame = part.CFrame + Vector3.new(0, 2.5, 0)
	return true
end

local function collectDrops(kind)
	local root = characterRoot()
	if not root then return end
	local patterns = {
		all = { "drop", "seed", "fruit", "item", "gold", "rainbow" },
		gold = { "gold" },
		rainbow = { "rainbow" },
	}
	local wanted = patterns[kind or "all"] or patterns.all
	local scanned = 0
	for _, inst in ipairs(Workspace:GetDescendants()) do
		scanned += 1
		if scanned > 900 then break end
		if inst:IsA("BasePart") or inst:IsA("Model") then
			local name = string.lower(inst.Name)
			for _, pattern in ipairs(wanted) do
				if name:find(pattern, 1, true) then
					local pos = partPosition(inst)
					if pos and (pos - root.Position).Magnitude <= 160 then
						if fireKey("CollectDrop", inst.Name) then
							break
						end
						touchOrMoveTo(inst)
					end
					break
				end
			end
		end
	end
end

local function fireForSelections(key, selections, ...)
	local values = selectionValues(selections)
	if values[1] == "Any" then
		fireKey(key, ...)
		return
	end
	for _, value in ipairs(values) do
		fireKey(key, value, ...)
	end
end

local function autoBlacklistTick(mode)
	if mode == "all" then
		fireKey("BlacklistSeed", "All")
		return
	end
	if mode == "best" then
		fireKey("BlacklistSeed", "Best")
		return
	end
	local seeds = selectionValues(state.BlacklistSeeds)
	local mutations = selectionValues(state.BlacklistMutations)
	local rarities = selectionValues(state.BlacklistRarities)
	if seeds[1] == "Any" and mutations[1] == "Any" and rarities[1] == "Any" then
		fireKey("BlacklistSeed")
		return
	end
	for _, seed in ipairs(seeds) do
		for _, mutation in ipairs(mutations) do
			for _, rarity in ipairs(rarities) do
				fireKey("BlacklistSeed", seed, mutation, rarity)
			end
		end
	end
end

local function autoSellTick()
	if state.AutoSellAllSeeds then
		fireKey("SellFruit", "All")
		return
	end
	if not state.AutoSellSelectedFruits then
		return
	end
	local seeds = selectionValues(state.TargetSellSeeds)
	local rarities = selectionValues(state.TargetSellRarities)
	local mutations = selectionValues(state.TargetSellMutations)
	if seeds[1] == "Any" and rarities[1] == "Any" and mutations[1] == "Any" then
		fireKey("SellFruit")
		return
	end
	for _, seed in ipairs(seeds) do
		for _, rarity in ipairs(rarities) do
			for _, mutation in ipairs(mutations) do
				fireKey("SellFruit", seed, rarity, mutation)
			end
		end
	end
end

local function stealFruitTick()
	local root = characterRoot()
	if not root then return end
	local original = root.CFrame
	local stolen = fireKey("StealFruit")
	if not stolen then
		local scanned = 0
		for _, inst in ipairs(Workspace:GetDescendants()) do
			scanned += 1
			if scanned > 700 then break end
			if (inst:IsA("BasePart") or inst:IsA("Model")) and string.lower(inst.Name):find("fruit", 1, true) then
				local pos = partPosition(inst)
				if pos and (pos - root.Position).Magnitude <= 260 then
					stolen = touchOrMoveTo(inst)
					break
				end
			end
		end
	end
	if stolen and tonumber(state.ReturnAfterSteal) and tonumber(state.ReturnAfterSteal) >= 0 then
		task.delay(tonumber(state.ReturnAfterSteal), function()
			local currentRoot = characterRoot()
			if currentRoot and state.HubRunning and state.AutoStealFruits then
				currentRoot.CFrame = original
			end
		end)
	end
end

local function predictorTick()
	if state.AutoWeatherPredictor then
		fireKey("WeatherPredict")
	end
	if state.AutoSeedPredictor then
		fireKey("SeedPredict")
	end
	if state.AutoGearPredictor then
		fireKey("GearPredict")
	end
end

local function rejoinCurrentServer()
	pcall(function()
		TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer)
	end)
end

local function plantWithFilters(seed, rarity, mutation)
	local plotName = plotContext()
	if plotName then
		return fireKey("PlantSeed", seed, rarity, mutation, plotName)
			or fireKey("PlantSeed", seed, plotName)
			or fireKey("PlantSeed", plotName)
	end
	return fireKey("PlantSeed", seed, rarity, mutation) or fireKey("PlantSeed", seed)
end

local function collectSeedsOnPlot()
	local plot = resolvePlayerPlot()
	local root = characterRoot()
	if plot and root then
		local scanned = 0
		for _, inst in ipairs(plot:GetDescendants()) do
			scanned += 1
			if scanned > 500 then
				break
			end
			if inst:IsA("BasePart") or inst:IsA("Model") then
				local name = string.lower(inst.Name)
				if name:find("seed", 1, true) or name:find("fruit", 1, true) or name:find("drop", 1, true) then
					local pos = partPosition(inst)
					if pos and (pos - root.Position).Magnitude <= 140 then
						if fireKey("CollectSeed", inst.Name) or fireKey("CollectDrop", inst.Name) then
							return true
						end
						touchOrMoveTo(inst)
						return true
					end
				end
			end
		end
	end
	return fireKey("CollectSeed") or fireKey("CollectDrop")
end

local function plantTick()
	if not (state.AutoPlantSeed or state.AutoPlantAllSeeds) then return end
	local interval = math.max(0.25, (state.PlantInterval or 1) / math.max(state.PlantSpeed or 1, 0.1))
	tickEvery("plant", interval, function()
		if state.AutoPlantAllSeeds then
			fireKey("PlantSeed", "All", plotContext())
			return
		end
		local seeds = selectionValues(state.TargetSeeds)
		local rarities = selectionValues(state.TargetRarities)
		local mutations = selectionValues(state.TargetMutations)
		if seeds[1] == "Any" and rarities[1] == "Any" and mutations[1] == "Any" then
			plantWithFilters(nil, nil, nil)
			return
		end
		for _, seed in ipairs(seeds) do
			for _, rarity in ipairs(rarities) do
				for _, mutation in ipairs(mutations) do
					plantWithFilters(seed == "Any" and nil or seed, rarity == "Any" and nil or rarity, mutation == "Any" and nil or mutation)
				end
			end
		end
	end)
end

local function runAutomation()
	if not state.HubRunning then return end
	refreshRemotes()
	plantTick()

	if state.AutoShovelSeed then
		tickEvery("shovel", state.ShovelInterval or 2, function()
			local plot = resolvePlayerPlot()
			if plot then
				for _, slot in ipairs(plot:GetChildren()) do
					fireKey("ShovelSeed", slot.Name, plot.Name)
				end
			end
			fireKey("ShovelSeed", plotContext())
		end)
	end
	if state.AutoCollectSeeds then
		tickEvery("collect", state.CollectInterval or 0.75, function()
			if state.StopCollectWhenFull and inventoryFull() then return end
			collectSeedsOnPlot()
		end)
	end
	if state.AutoCollectGoldSeeds then
		tickEvery("goldDrops", state.CollectInterval or 0.75, function() collectDrops("gold") end)
	end
	if state.AutoCollectRainbowSeeds then
		tickEvery("rainbowDrops", state.CollectInterval or 0.75, function() collectDrops("rainbow") end)
	end
	if state.AutoCollectAllDrops then
		tickEvery("allDrops", state.CollectInterval or 0.75, function() collectDrops("all") end)
	end
	if state.AutoWateringCan then
		tickEvery("water", state.WaterDelay or 1.5, function()
			local plotName = plotContext()
			for _ = 1, math.max(1, math.floor(state.WaterAmount or 1)) do
				if plotName then
					fireKey("Water", plotName) or fireKey("Water", state.WaterAmount, plotName)
				else
					fireKey("Water")
				end
			end
		end)
	end
	if state.AutoSprinklerSystem then
		tickEvery("sprinkler", state.SprinklerDelay or 2, function()
			local seeds = selectionValues(state.TargetSprinklerSeeds)
			local variant = state.SprinklerVariant or "Any"
			local plotName = plotContext()
			for _ = 1, math.max(1, math.floor(state.SprinklerAmount or 1)) do
				if seeds[1] ~= "Any" then
					for _, seed in ipairs(seeds) do
						if plotName then
							fireKey("Sprinkler", seed, variant, plotName)
						else
							fireKey("Sprinkler", seed, variant)
						end
					end
				elseif plotName then
					fireKey("Sprinkler", variant, plotName)
				else
					fireKey("Sprinkler", variant)
				end
			end
		end)
	end
	if state.AutoBuySeedShop then
		tickEvery("seedShop", state.ShopInterval or 3, function()
			local targets = Core.normalizeMultiSelection(state.TargetSeedShop)
			if targets[1] == "Any" or #targets == 0 then fireKey("BuySeed") else
				for _, seed in ipairs(targets) do fireKey("BuySeed", seed) end
			end
		end)
	end
	if state.AutoBuyCrate then
		tickEvery("crate", state.ShopInterval or 3, function()
			local targets = Core.normalizeMultiSelection(state.TargetCrates)
			if targets[1] == "Any" or #targets == 0 then fireKey("BuyCrate") else
				for _, crate in ipairs(targets) do fireKey("BuyCrate", crate) end
			end
		end)
	end
	if state.AutoBuyGearShop then
		tickEvery("gear", state.ShopInterval or 3, function()
			local targets = selectionValues(state.TargetGearShop)
			if targets[1] == "Any" then
				fireKey("BuyGear") or fireKey("BuyGear", "Any")
			else
				for _, gear in ipairs(targets) do
					fireKey("BuyGear", gear)
				end
			end
		end)
	end
	if state.AutoBuyPet then
		tickEvery("petShop", state.PetBuyInterval or 4, function()
			fireForSelections("BuyPet", state.TargetPets)
		end)
	end
	if state.AutoBlacklist then
		tickEvery("blacklist", state.BlacklistInterval or 2, function() autoBlacklistTick("selected") end)
	end
	if state.AutoBlacklistAll then
		tickEvery("blacklistAll", state.BlacklistInterval or 2, function() autoBlacklistTick("all") end)
	end
	if state.AutoBlacklistBest then
		tickEvery("blacklistBest", state.BlacklistInterval or 2, function() autoBlacklistTick("best") end)
	end
	if state.AutoSellSelectedFruits or state.AutoSellAllSeeds then
		tickEvery("sell", state.AutoSellDelay or 3, autoSellTick)
	end
	if state.AutoStealFruits then
		tickEvery("steal", state.StealInterval or 2, stealFruitTick)
	end
	if state.AutoWeatherPredictor or state.AutoSeedPredictor or state.AutoGearPredictor then
		tickEvery("predictors", state.PredictorInterval or 10, predictorTick)
	end
	Core.tickAutoRejoin(state, runtime, 1)
end

Core.makeSupervisor(state, loops, loopControllers, "mainLoop", 0.25, runAutomation)
if state.AntiAFK ~= false then Core.setupAntiAfk(LocalPlayer) end

local window = Core.buildUiWindow(ui, Core.uiWindowSettings({
	Subtitle = "Grow a Garden 2 · v" .. VERSION,
	Icon = "seedling",
	Theme = "Default",
}))
if not window or not window._rawWindow then
	getgenv().Alleral_StartupFailed = "UI window failed"
	return
end

local section = Core.buildUiSection(window)
Core.buildExploitHub(section, {
	window = window, ui = ui, state = state, loops = loopControllers,
	version = VERSION, scriptId = "grow_a_garden_2", gameName = "Grow a Garden 2",
	gameStats = { Coins = "?", Seeds = "?", Plot = "?" },
	statsTick = function(status)
		status:Update("Coins", leaderstat("Coins") or leaderstat("Money") or "?")
		status:Update("Seeds", leaderstat("Seeds") or "?")
		status:Update("Plot", (resolvePlayerPlot() and state.PlayerPlot) or "?")
	end,
	automationFlags = {
		{ key = "AutoPlantSeed", label = "Plant" },
		{ key = "AutoCollectSeeds", label = "Collect seeds" },
		{ key = "AutoCollectAllDrops", label = "All drops" },
		{ key = "AutoBlacklist", label = "Blacklist" },
		{ key = "AutoSellSelectedFruits", label = "Sell fruits" },
		{ key = "AutoStealFruits", label = "Steal" },
		{ key = "AutoBuyPet", label = "Buy pet" },
		{ key = "AutoWateringCan", label = "Water" },
		{ key = "AutoSprinklerSystem", label = "Sprinkler" },
	},
	saveFn = saveSettings,
	onRemoteScan = function()
		refreshRemotes()
		syncGameCatalog()
		refreshCatalogDropdowns()
	end,
})

local farmTab = Core.buildUiTab(section, "Farm", 10734923214, 2, "farm")
local waterTab = Core.buildUiTab(section, "Water", 10723407389, 1, "water")
local shopTab = Core.buildUiTab(section, "Shop", 10734952479, 1, "shop")
local updateTab = Core.buildUiTab(section, "LuxyHub", 10709788505, 2, "update")
local settingsTab = Core.buildUiTab(section, "Settings", 10734950309, 1, "settings")
local saveWrap = Core.onUiSave(saveSettings)

local plantGroup = Core.buildUiGroup(farmTab, "Planting", 1, saveWrap, nil, "plant")
local collectGroup = Core.buildUiGroup(farmTab, "Seeds", 2, saveWrap, nil, "collect")
local waterGroup = Core.buildUiGroup(waterTab, "Watering Can", 1, saveWrap, nil, "water")
local sprinklerGroup = Core.buildUiGroup(waterTab, "Sprinkler", 2, saveWrap, nil, "sprinkler")
local seedShop = Core.buildUiGroup(shopTab, "Seed Shop", 1, saveWrap, nil, "seedshop")
local crateShop = Core.buildUiGroup(shopTab, "Crates", 2, saveWrap, nil, "crate")
local gearShop = Core.buildUiGroup(shopTab, "Gear", 1, saveWrap, nil, "gear")
local petShop = Core.buildUiGroup(shopTab, "Pets", 2, saveWrap, nil, "pets")
local blacklistGroup = Core.buildUiGroup(updateTab, "Blacklist", 1, saveWrap, nil, "blacklist")
local sellGroup = Core.buildUiGroup(updateTab, "Selling", 2, saveWrap, nil, "selling")
local dropsGroup = Core.buildUiGroup(updateTab, "Drops & Steal", 1, saveWrap, nil, "drops")
local predictGroup = Core.buildUiGroup(updateTab, "Predictors", 2, saveWrap, nil, "predict")

plantGroup:CreateToggle("Auto plant seed", state.AutoPlantSeed, "Plants selected seeds on open slots.", function(v) state.AutoPlantSeed = v end)
plantGroup:CreateToggle("Auto plant all seeds", state.AutoPlantAllSeeds, "Plants every seed in inventory.", function(v) state.AutoPlantAllSeeds = v end)
plantGroup:CreateToggle("Auto shovel seed", state.AutoShovelSeed, "Removes unwanted planted seeds.", function(v) state.AutoShovelSeed = v end)
syncGameCatalog()
runtime.dropdowns.plantSeeds = plantGroup:AddDropdown("Seed filter", {
	Text = "Seeds to plant",
	Values = runtime.catalog.seeds,
	Default = state.TargetSeeds, Multi = true,
	Callback = function(s) state.TargetSeeds = Core.normalizeMultiSelection(s) if #state.TargetSeeds == 0 then state.TargetSeeds = { "Any" } end end,
})
runtime.dropdowns.plantRarities = plantGroup:AddDropdown("Rarity filter", {
	Text = "Rarity",
	Values = runtime.catalog.rarities,
	Default = state.TargetRarities, Multi = true,
	Callback = function(s) state.TargetRarities = Core.normalizeMultiSelection(s) if #state.TargetRarities == 0 then state.TargetRarities = { "Any" } end end,
})
runtime.dropdowns.plantMutations = plantGroup:AddDropdown("Mutation filter", {
	Text = "Mutation",
	Values = runtime.catalog.mutations,
	Default = state.TargetMutations, Multi = true,
	Callback = function(s) state.TargetMutations = Core.normalizeMultiSelection(s) if #state.TargetMutations == 0 then state.TargetMutations = { "Any" } end end,
})
plantGroup:CreateSlider("Custom plant speed", 0.5, 5, state.PlantSpeed, function(v) state.PlantSpeed = v end, "Multiplier for plant loop speed.")
plantGroup:CreateSlider("Plant delay", 0.25, 5, state.PlantInterval, function(v) state.PlantInterval = v end, "Base seconds between plant attempts.")

collectGroup:CreateToggle("Auto collect seeds", state.AutoCollectSeeds, "Picks up seed drops on your plot.", function(v) state.AutoCollectSeeds = v end)
collectGroup:CreateToggle("Stop when inventory full", state.StopCollectWhenFull, "Pauses seed collection at cap.", function(v) state.StopCollectWhenFull = v end)
collectGroup:CreateSlider("Collect delay", 0.2, 5, state.CollectInterval, function(v) state.CollectInterval = v end, "Seconds between collection passes.")
collectGroup:CreateToggle("Auto collect all drops", state.AutoCollectAllDrops, "Collects visible seed and item drops.", function(v) state.AutoCollectAllDrops = v end)
collectGroup:CreateToggle("Auto collect gold seeds", state.AutoCollectGoldSeeds, "Prioritizes gold seed drops.", function(v) state.AutoCollectGoldSeeds = v end)
collectGroup:CreateToggle("Auto collect rainbow seeds", state.AutoCollectRainbowSeeds, "Prioritizes rainbow seed drops.", function(v) state.AutoCollectRainbowSeeds = v end)

waterGroup:CreateToggle("Auto watering can", state.AutoWateringCan, "Waters crops automatically.", function(v) state.AutoWateringCan = v end)
waterGroup:CreateSlider("Water amount", 1, 10, state.WaterAmount, function(v) state.WaterAmount = v end, "Uses per watering pass.")
waterGroup:CreateSlider("Water delay", 0.5, 10, state.WaterDelay, function(v) state.WaterDelay = v end, "Seconds between watering passes.")

sprinklerGroup:CreateToggle("Auto sprinkler system", state.AutoSprinklerSystem, "Places sprinklers on your plot.", function(v) state.AutoSprinklerSystem = v end)
runtime.dropdowns.sprinklerSeeds = sprinklerGroup:AddDropdown("Sprinkler seeds", {
	Text = "Seed selection",
	Values = runtime.catalog.seeds,
	Default = state.TargetSprinklerSeeds, Multi = true,
	Callback = function(s) state.TargetSprinklerSeeds = Core.normalizeMultiSelection(s) if #state.TargetSprinklerSeeds == 0 then state.TargetSprinklerSeeds = { "Any" } end end,
})
sprinklerGroup:CreateDropdown("Sprinkler variant", runtime.catalog.sprinklers, state.SprinklerVariant, function(v) state.SprinklerVariant = v end, "Sprinkler type to place.")
sprinklerGroup:CreateSlider("Sprinkler amount", 1, 10, state.SprinklerAmount, function(v) state.SprinklerAmount = v end, "Placements per pass.")
sprinklerGroup:CreateSlider("Sprinkler delay", 0.5, 15, state.SprinklerDelay, function(v) state.SprinklerDelay = v end, "Seconds between sprinkler passes.")

seedShop:CreateToggle("Auto buy seed shop", state.AutoBuySeedShop, "Purchases seeds from the shop.", function(v) state.AutoBuySeedShop = v end)
runtime.dropdowns.seedShop = seedShop:AddDropdown("Target seeds", {
	Text = "Seeds to buy",
	Values = runtime.catalog.seeds,
	Default = state.TargetSeedShop, Multi = true,
	Callback = function(s) state.TargetSeedShop = Core.normalizeMultiSelection(s) if #state.TargetSeedShop == 0 then state.TargetSeedShop = { "Any" } end end,
})

crateShop:CreateToggle("Auto buy crate", state.AutoBuyCrate, "Purchases crates from the shop.", function(v) state.AutoBuyCrate = v end)
runtime.dropdowns.crateShop = crateShop:AddDropdown("Target crates", {
	Text = "Crates to buy",
	Values = runtime.catalog.crates,
	Default = state.TargetCrates, Multi = true,
	Callback = function(s) state.TargetCrates = Core.normalizeMultiSelection(s) if #state.TargetCrates == 0 then state.TargetCrates = { "Any" } end end,
})

gearShop:CreateToggle("Auto buy gear shop", state.AutoBuyGearShop, "Purchases gear upgrades.", function(v) state.AutoBuyGearShop = v end)
runtime.dropdowns.gearShop = gearShop:AddDropdown("Target gear", {
	Text = "Gear to buy",
	Values = runtime.catalog.gears,
	Default = state.TargetGearShop, Multi = true,
	Callback = function(s) state.TargetGearShop = Core.normalizeMultiSelection(s) if #state.TargetGearShop == 0 then state.TargetGearShop = { "Any" } end end,
})
gearShop:CreateSlider("Shop delay", 1, 15, state.ShopInterval, function(v) state.ShopInterval = v end, "Seconds between shop purchase attempts.")

petShop:CreateToggle("Auto buy pet", state.AutoBuyPet, "Purchases selected pets from the pet shop.", function(v) state.AutoBuyPet = v end)
runtime.dropdowns.petShop = petShop:AddDropdown("Pet selection", {
	Text = "Pets to buy",
	Values = runtime.catalog.pets,
	Default = state.TargetPets, Multi = true,
	Callback = function(s) state.TargetPets = Core.normalizeMultiSelection(s) if #state.TargetPets == 0 then state.TargetPets = { "Any" } end end,
})
petShop:CreateSlider("Pet buy delay", 1, 30, state.PetBuyInterval, function(v) state.PetBuyInterval = v end, "Seconds between pet purchases.")

blacklistGroup:CreateToggle("Auto blacklist", state.AutoBlacklist, "Blacklists selected seed/mutation/rarity combos.", function(v) state.AutoBlacklist = v end)
blacklistGroup:CreateToggle("Auto blacklist all", state.AutoBlacklistAll, "Runs the game's all-blacklist action.", function(v) state.AutoBlacklistAll = v end)
blacklistGroup:CreateToggle("Auto blacklist best", state.AutoBlacklistBest, "Runs the game's best-blacklist action.", function(v) state.AutoBlacklistBest = v end)
runtime.dropdowns.blacklistSeeds = blacklistGroup:AddDropdown("Blacklist seeds", {
	Text = "Seeds",
	Values = runtime.catalog.seeds,
	Default = state.BlacklistSeeds, Multi = true,
	Callback = function(s) state.BlacklistSeeds = Core.normalizeMultiSelection(s) if #state.BlacklistSeeds == 0 then state.BlacklistSeeds = { "Any" } end end,
})
runtime.dropdowns.blacklistMutations = blacklistGroup:AddDropdown("Blacklist mutation", {
	Text = "Mutation",
	Values = runtime.catalog.mutations,
	Default = state.BlacklistMutations, Multi = true,
	Callback = function(s) state.BlacklistMutations = Core.normalizeMultiSelection(s) if #state.BlacklistMutations == 0 then state.BlacklistMutations = { "Any" } end end,
})
runtime.dropdowns.blacklistRarities = blacklistGroup:AddDropdown("Blacklist rarity", {
	Text = "Rarity",
	Values = runtime.catalog.rarities,
	Default = state.BlacklistRarities, Multi = true,
	Callback = function(s) state.BlacklistRarities = Core.normalizeMultiSelection(s) if #state.BlacklistRarities == 0 then state.BlacklistRarities = { "Any" } end end,
})

sellGroup:CreateToggle("Auto sell selected fruits", state.AutoSellSelectedFruits, "Sells fruits matching selected filters.", function(v) state.AutoSellSelectedFruits = v end)
sellGroup:CreateToggle("Auto sell all seeds", state.AutoSellAllSeeds, "Runs the game's sell-all seeds action.", function(v) state.AutoSellAllSeeds = v end)
runtime.dropdowns.sellSeeds = sellGroup:AddDropdown("Seed sell filter", {
	Text = "Seeds",
	Values = runtime.catalog.seeds,
	Default = state.TargetSellSeeds, Multi = true,
	Callback = function(s) state.TargetSellSeeds = Core.normalizeMultiSelection(s) if #state.TargetSellSeeds == 0 then state.TargetSellSeeds = { "Any" } end end,
})
runtime.dropdowns.sellRarities = sellGroup:AddDropdown("Rarity sell filter", {
	Text = "Rarity",
	Values = runtime.catalog.rarities,
	Default = state.TargetSellRarities, Multi = true,
	Callback = function(s) state.TargetSellRarities = Core.normalizeMultiSelection(s) if #state.TargetSellRarities == 0 then state.TargetSellRarities = { "Any" } end end,
})
runtime.dropdowns.sellMutations = sellGroup:AddDropdown("Mutation sell filter", {
	Text = "Mutation",
	Values = runtime.catalog.mutations,
	Default = state.TargetSellMutations, Multi = true,
	Callback = function(s) state.TargetSellMutations = Core.normalizeMultiSelection(s) if #state.TargetSellMutations == 0 then state.TargetSellMutations = { "Any" } end end,
})
sellGroup:CreateSlider("Auto sell delay", 1, 30, state.AutoSellDelay, function(v) state.AutoSellDelay = v end, "Seconds between sell attempts.")

dropsGroup:CreateToggle("Auto steal fruits", state.AutoStealFruits, "Attempts public fruit steal remotes and nearby fruit pickups.", function(v) state.AutoStealFruits = v end)
dropsGroup:CreateSlider("Return after", 0, 20, state.ReturnAfterSteal, function(v) state.ReturnAfterSteal = v end, "Seconds before returning after a steal attempt.")
dropsGroup:CreateToggle("Auto rejoin", state.AutoRejoin, "Queues a same-server rejoin for update recovery.", function(v) state.AutoRejoin = v end)

predictGroup:CreateToggle("Weather predictor", state.AutoWeatherPredictor, "Pings the game's weather prediction remote when present.", function(v) state.AutoWeatherPredictor = v end)
predictGroup:CreateToggle("Seed predictor", state.AutoSeedPredictor, "Pings the game's seed prediction remote when present.", function(v) state.AutoSeedPredictor = v end)
predictGroup:CreateToggle("Gear predictor", state.AutoGearPredictor, "Pings the game's gear prediction remote when present.", function(v) state.AutoGearPredictor = v end)
predictGroup:CreateSlider("Predictor delay", 5, 60, state.PredictorInterval, function(v) state.PredictorInterval = v end, "Seconds between predictor checks.")

settingsTab:BuildThemeGroupbox(1)
Core.buildConfigProfileGroup(settingsTab, {
	state = state, savedKeys = savedKeys, saveFn = saveSettings, version = VERSION, column = 1,
})
Core.buildStandardSettingsExtras(settingsTab, Core.settingsExtrasOptions(window, ui, state, savedKeys, saveSettings, SETTINGS_FILE, VERSION, {
	gameId = "grow_a_garden_2", placeId = PLACE_ID,
}))

Core.finalizeGameUi(window, ui, { Subtitle = "Grow a Garden 2 · v" .. VERSION })
saveSettings()

task.spawn(function()
	task.wait(4)
	if G.invalidateGameRequire then
		G.invalidateGameRequire()
	end
	syncGameCatalog()
	refreshCatalogDropdowns()
end)

state.Alleral_Unload = function()
	state.HubRunning = false
	Core.stopAutomation(state, connections, loopControllers, loops)
end
