-- Werte WIP: Platzhalter für Phase 1, noch kein finales Balancing.
local Config = require(script.Parent.Config)
local RunConfig = {}

RunConfig.START_TEAM = 3
RunConfig.MAX_TEAM = 6
RunConfig.LEVELS_PER_REGION = 5
RunConfig.REGIONS = { "greenland" }
RunConfig.REGION_NAMES = { greenland = "Grasland" }
RunConfig.PARTIAL_HEAL = 0.3
RunConfig.VERSION = 2
RunConfig.CAMP_CHANCE = 0.3
RunConfig.MINIBOSS_LEVEL = 3
RunConfig.MINIBOSS_GUARDS = 2
RunConfig.MINIBOSS_REWARD_MULTIPLIER = 2
RunConfig.BOSS_REWARD_MULTIPLIER = 3
RunConfig.REVIVE_GOLD_BASE = 100
RunConfig.REVIVE_GOLD_PER_LEVEL = 25
RunConfig.REVIVE_GEMS = 15
RunConfig.ENEMY_STAT_PER_LEVEL = { hp = 2, str = 1, def = 1 }
RunConfig.BOSSES = { greenland = { miniboss = "brigand_captain", boss = "chieftain" } }
RunConfig.OPTIONS_MIN = 2
RunConfig.OPTIONS_MAX = 3
RunConfig.BOARD_WIDTH = 16
RunConfig.BOARD_HEIGHT = 12
RunConfig.CHUNK_WIDTH = 8
RunConfig.CHUNK_HEIGHT = 4
RunConfig.START_ROWS = 2
RunConfig.ENEMY_ROWS = 6
RunConfig.MIN_ENEMY_DISTANCE = 4
RunConfig.MAX_BLOCKED_SHARE = 0.32
RunConfig.MAX_ATTEMPTS = 50
-- WIP: Flüsse liegen vor der Startzone, Querungen umfassen die volle Breite.
RunConfig.RIVER_CHANCE = 0.4
RunConfig.RIVER_MIN_SWING = 3
RunConfig.RIVER_BEND_LENGTH = { min = 2, max = 4 }
RunConfig.LAKE_CHANCE = 0.3
RunConfig.LAKE_WIDTH = { min = 3, max = 5 }
RunConfig.LAKE_HEIGHT = { min = 3, max = 4 }
RunConfig.ISLAND_CHANCE = 0.5
RunConfig.POND_CHANCE = 0.35
RunConfig.POND_COUNT = { min = 1, max = 2 }
RunConfig.WATER_PLACEMENT_ATTEMPTS = 40
RunConfig.CLIFF_CHANCE = 0.4
RunConfig.CLIFF_WIDTH = { min = 2, max = 4 }
RunConfig.CLIFF_HEIGHT = { min = 2, max = 3 }
RunConfig.WATERFALL_CHANCE = 0.56 -- WIP: bedingt durch Klippe und erreichbares Wasser; Ziel insgesamt 12–17 %
RunConfig.RIVER_WIDTH = { min = 1, max = 2 }
RunConfig.BRIDGES_MIN = 2
RunConfig.BRIDGES_MAX = 3
RunConfig.ENEMY_COUNT_BASE = 6
RunConfig.ENEMY_COUNT_PER_DEPTH = 1
RunConfig.ENEMY_COUNT_MAX = 12
RunConfig.ENEMY_LEVEL_BASE = 1
RunConfig.ENEMY_LEVEL_PER_DEPTH = 1
RunConfig.REWARDS = {
	gold = { name = "Gold", symbol = Config.ICONS.gold, base = 80, perDepth = 40 },
	gems = { name = "Edelsteine", symbol = Config.ICONS.gems, base = 4, perDepth = 2 },
}
RunConfig.REWARD_ORDER = { "gold", "gems" }
RunConfig.THEME_ORDER = { "axe", "lance", "bow" }
RunConfig.THEMES = {
	axe = { name = "Axttrupp", symbol = "🪓", enemies = { "brigand" }, share = 0.6 },
	lance = { name = "Lanzentrupp", symbol = "⚔", enemies = { "soldier", "javelin" }, share = 0.6 },
	bow = { name = "Bogenschützen", symbol = "🏹", enemies = { "archer" }, share = 0.6 },
}
RunConfig.ENEMY_POOL = { "brigand", "soldier", "javelin", "archer" }

function RunConfig.totalLevels()
	return RunConfig.LEVELS_PER_REGION * #RunConfig.REGIONS
end

function RunConfig.regionAt(depth)
	return RunConfig.REGIONS[math.ceil(depth / RunConfig.LEVELS_PER_REGION)]
end

function RunConfig.levelInRegion(depth)
	return (depth - 1) % RunConfig.LEVELS_PER_REGION + 1
end

function RunConfig.levelKind(depth)
	local level = RunConfig.levelInRegion(depth)
	if level == RunConfig.MINIBOSS_LEVEL then return "miniboss" end
	if level == RunConfig.LEVELS_PER_REGION then return "boss" end
	return "battle"
end

function RunConfig.enemyBonus(depth)
	local bonus = {}
	for stat, amount in pairs(RunConfig.ENEMY_STAT_PER_LEVEL) do
		bonus[stat] = (RunConfig.enemyLevel(depth) - 1) * amount
	end
	return bonus
end

function RunConfig.revivePrice(level, currency)
	if currency == "gold" then return RunConfig.REVIVE_GOLD_BASE + RunConfig.REVIVE_GOLD_PER_LEVEL * level end
	if currency == "gems" then return RunConfig.REVIVE_GEMS end
	return nil
end

function RunConfig.enemyCount(depth)
	return math.min(RunConfig.ENEMY_COUNT_MAX, RunConfig.ENEMY_COUNT_BASE + depth * RunConfig.ENEMY_COUNT_PER_DEPTH)
end

function RunConfig.enemyLevel(depth)
	return RunConfig.ENEMY_LEVEL_BASE + depth * RunConfig.ENEMY_LEVEL_PER_DEPTH
end

function RunConfig.rewardAmount(kind, depth)
	local reward = RunConfig.REWARDS[kind]
	local levelKind = RunConfig.levelKind(depth)
	local multiplier = levelKind == "boss" and RunConfig.BOSS_REWARD_MULTIPLIER
		or levelKind == "miniboss" and RunConfig.MINIBOSS_REWARD_MULTIPLIER or 1
	return (reward.base + reward.perDepth * depth) * multiplier
end

return RunConfig
