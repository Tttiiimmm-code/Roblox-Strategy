-- Werte WIP: Platzhalter für Phase 1, noch kein finales Balancing.
local RunConfig = {}

RunConfig.START_TEAM = 3
RunConfig.MAX_TEAM = 6
RunConfig.LEVELS_PER_REGION = 5
RunConfig.REGIONS = { "greenland" }
RunConfig.REGION_NAMES = { greenland = "Grasland" }
RunConfig.PARTIAL_HEAL = 0.3
RunConfig.OPTIONS_MIN = 2
RunConfig.OPTIONS_MAX = 3
RunConfig.BOARD_WIDTH = 10
RunConfig.BOARD_HEIGHT = 8
RunConfig.CHUNK_WIDTH = 5
RunConfig.CHUNK_HEIGHT = 4
RunConfig.START_ROWS = 2
RunConfig.ENEMY_ROWS = 4
RunConfig.MIN_ENEMY_DISTANCE = 4
RunConfig.MAX_BLOCKED_SHARE = 0.25
RunConfig.MAX_ATTEMPTS = 50
-- WIP: Flüsse liegen vor der Startzone, Querungen umfassen die volle Breite.
RunConfig.RIVER_CHANCE = 0.4
RunConfig.RIVER_WIDTH = { min = 1, max = 2 }
RunConfig.BRIDGES_MIN = 1
RunConfig.BRIDGES_MAX = 2
RunConfig.ENEMY_COUNT_BASE = 4
RunConfig.ENEMY_COUNT_PER_DEPTH = 1
RunConfig.ENEMY_LEVEL_BASE = 1
RunConfig.ENEMY_LEVEL_PER_DEPTH = 1
RunConfig.REWARDS = {
	gold = { name = "Gold", symbol = "🪙", base = 80, perDepth = 40 },
	gems = { name = "Edelsteine", symbol = "💎", base = 4, perDepth = 2 },
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

function RunConfig.enemyCount(depth)
	return RunConfig.ENEMY_COUNT_BASE + depth * RunConfig.ENEMY_COUNT_PER_DEPTH
end

function RunConfig.enemyLevel(depth)
	return RunConfig.ENEMY_LEVEL_BASE + depth * RunConfig.ENEMY_LEVEL_PER_DEPTH
end

function RunConfig.rewardAmount(kind, depth)
	local reward = RunConfig.REWARDS[kind]
	return reward.base + reward.perDepth * depth
end

return RunConfig
