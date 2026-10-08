-- Deterministische Erzeugung ohne Roblox-Zufallsgenerator.
local Config = require(script.Parent.Config)
local RunConfig = require(script.Parent.RunConfig)
local MapChunks = require(script.Parent.MapChunks)
local LevelGen = {}

-- Park-Miller: auch im Luau-CLI identische, exakt darstellbare Produkte.
local MODULUS = 2147483647
local function randomSource(seed)
	local value = math.floor(seed) % (MODULUS - 1) + 1
	return function(low, high)
		value = (value * 16807) % MODULUS
		return low + value % (high - low + 1)
	end
end

local function shuffle(list, random)
	for i = #list, 2, -1 do
		local j = random(1, i)
		list[i], list[j] = list[j], list[i]
	end
end

local function passable(map, x, y, movement)
	local row = map[y]
	local terrain = row and Config.TERRAIN[string.sub(row, x, x)]
	local cost = terrain and terrain.cost[movement]
	return cost ~= nil and cost > 0 and cost < math.huge
end

local function key(x, y)
	return (y - 1) * RunConfig.BOARD_WIDTH + x
end

local function reachable(map, slot)
	local visited = { [key(slot.x, slot.y)] = true }
	local queue = { slot }
	local head = 1
	local directions = { { 1, 0 }, { -1, 0 }, { 0, 1 }, { 0, -1 } }
	while head <= #queue do
		local cell = queue[head]
		head += 1
		for _, direction in ipairs(directions) do
			local x, y = cell.x + direction[1], cell.y + direction[2]
			if x >= 1 and x <= RunConfig.BOARD_WIDTH and y >= 1 and y <= #map
				and passable(map, x, y, "foot") and not visited[key(x, y)] then
				visited[key(x, y)] = true
				table.insert(queue, { x = x, y = y })
			end
		end
	end
	return visited
end

local function compose(regionId, random)
	local chunks = MapChunks[regionId]
	local rows = {}
	for cy = 1, RunConfig.BOARD_HEIGHT / RunConfig.CHUNK_HEIGHT do
		for cx = 1, RunConfig.BOARD_WIDTH / RunConfig.CHUNK_WIDTH do
			local chunk = chunks[random(1, #chunks)]
			local flipX, flipY = random(0, 1) == 1, random(0, 1) == 1
			for y = 1, RunConfig.CHUNK_HEIGHT do
				local row = chunk[flipY and (RunConfig.CHUNK_HEIGHT + 1 - y) or y]
				if flipX then row = string.reverse(row) end
				local targetY = (cy - 1) * RunConfig.CHUNK_HEIGHT + y
				rows[targetY] = (rows[targetY] or "") .. row
			end
		end
	end
	return rows
end

local function populate(map, regionId, depth, themeId, teamSize, random)
	local starts = {}
	local blocked = 0
	for y, row in ipairs(map) do
		for x = 1, #row do
			if not passable(map, x, y, "foot") then blocked += 1 end
			if y > RunConfig.BOARD_HEIGHT - RunConfig.START_ROWS and passable(map, x, y, "horse") then
				table.insert(starts, { x = x, y = y })
			end
		end
	end
	if blocked / (RunConfig.BOARD_WIDTH * RunConfig.BOARD_HEIGHT) > RunConfig.MAX_BLOCKED_SHARE
		or #starts < teamSize then return nil end
	shuffle(starts, random)
	local slots = {}
	for i = 1, teamSize do slots[i] = starts[i] end
	local visited = reachable(map, slots[1])
	for _, slot in ipairs(slots) do
		if not visited[key(slot.x, slot.y)] then return nil end
	end
	local candidates = {}
	for y = 1, RunConfig.ENEMY_ROWS do
		for x = 1, RunConfig.BOARD_WIDTH do
			local valid = passable(map, x, y, "foot") and visited[key(x, y)]
			for _, slot in ipairs(slots) do
				if math.abs(x - slot.x) + math.abs(y - slot.y) < RunConfig.MIN_ENEMY_DISTANCE then valid = false end
			end
			if valid then table.insert(candidates, { x = x, y = y }) end
		end
	end
	local count = RunConfig.enemyCount(depth)
	if #candidates < count then return nil end
	shuffle(candidates, random)
	local theme = RunConfig.THEMES[themeId]
	local focus = {}
	for _, kind in ipairs(theme.enemies) do focus[kind] = true end
	local others = {}
	for _, kind in ipairs(RunConfig.ENEMY_POOL) do
		if not focus[kind] then table.insert(others, kind) end
	end
	local enemies = {}
	for i = 1, count do
		local pool = i <= math.ceil(count * theme.share) and theme.enemies or others
		local cell = candidates[i]
		enemies[i] = { kind = pool[random(1, #pool)], x = cell.x, y = cell.y, level = RunConfig.enemyLevel(depth) }
	end
	return { map = map, slots = slots, enemies = enemies, region = regionId, theme = themeId }
end

function LevelGen.generate(seed, regionId, depth, themeId, teamSize)
	assert(MapChunks[regionId] and RunConfig.THEMES[themeId], "Unbekanntes Gebiet oder Thema")
	assert(teamSize >= 1 and teamSize <= RunConfig.MAX_TEAM and teamSize % 1 == 0, "Ungültige Teamgröße")
	for attempt = 1, RunConfig.MAX_ATTEMPTS do
		local random = randomSource(seed + (attempt - 1) * 7919)
		local stage = populate(compose(regionId, random), regionId, depth, themeId, teamSize, random)
		if stage then
			stage.fallback = false
			return stage
		end
	end
	local map = {}
	for y = 1, RunConfig.BOARD_HEIGHT do map[y] = string.rep(".", RunConfig.BOARD_WIDTH) end
	local stage = populate(map, regionId, depth, themeId, teamSize, randomSource(seed))
	assert(stage, "Rückfall-Level konnte nicht erzeugt werden")
	stage.fallback = true
	return stage
end

function LevelGen.makeOptions(runSeed, depth, regionId)
	assert(MapChunks[regionId], "Unbekanntes Gebiet")
	local random = randomSource(runSeed + depth * 104729)
	local themes = table.clone(RunConfig.THEME_ORDER)
	shuffle(themes, random)
	local count = random(RunConfig.OPTIONS_MIN, math.min(RunConfig.OPTIONS_MAX, #themes))
	local options = {}
	for i = 1, count do
		local kind = RunConfig.REWARD_ORDER[random(1, #RunConfig.REWARD_ORDER)]
		options[i] = { themeId = themes[i], reward = { kind = kind, amount = RunConfig.rewardAmount(kind, depth) }, seed = random(1, MODULUS - 1) }
	end
	return options
end

return LevelGen
