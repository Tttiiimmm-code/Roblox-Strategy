-- Wird vom PowerShell-Runner mit den echten Shared-Modulen verbunden.
local Config = testModules.Config
local RunConfig = testModules.RunConfig
local LevelGen = testModules.LevelGen
local checks, fallbacks = 0, 0

local function same(a, b)
	if type(a) ~= type(b) then return false end
	if type(a) ~= "table" then return a == b end
	for k, v in pairs(a) do if not same(v, b[k]) then return false end end
	for k in pairs(b) do if a[k] == nil then return false end end
	return true
end

local function canWalk(map, x, y)
	local row = map[y]
	local terrain = row and Config.TERRAIN[string.sub(row, x, x)]
	local cost = terrain and terrain.cost.foot
	return cost and cost > 0 and cost < math.huge
end

local function cellKey(cell)
	return cell.x .. ":" .. cell.y
end

-- Unabhängige Flutsuche von jedem Start, ohne die Generatorprüfung aufzurufen.
local function flood(map, start)
	local seen = { [cellKey(start)] = true }
	local queue, head = { start }, 1
	while head <= #queue do
		local cell = queue[head]
		head += 1
		for _, neighbor in ipairs({
			{ x = cell.x - 1, y = cell.y }, { x = cell.x + 1, y = cell.y },
			{ x = cell.x, y = cell.y - 1 }, { x = cell.x, y = cell.y + 1 },
		}) do
			local id = cellKey(neighbor)
			if canWalk(map, neighbor.x, neighbor.y) and not seen[id] then
				seen[id] = true
				table.insert(queue, neighbor)
			end
		end
	end
	return seen
end

local function validate(stage, themeId, depth, teamSize)
	assert(#stage.map == RunConfig.BOARD_HEIGHT, "Kartenhöhe")
	local blocked = 0
	for _, row in ipairs(stage.map) do
		assert(#row == RunConfig.BOARD_WIDTH, "Kartenbreite")
		assert(not string.find(row, "[^.FMW HB]"), "Unbekanntes Gelände")
		assert(not string.find(row, " "), "Leerzeichen im Gelände")
		for x = 1, #row do
			if not Config.TERRAIN[string.sub(row, x, x)].cost.foot then blocked += 1 end
		end
	end
	assert(blocked / (RunConfig.BOARD_WIDTH * RunConfig.BOARD_HEIGHT) <= RunConfig.MAX_BLOCKED_SHARE, "Hindernisanteil")
	assert(stage.theme == themeId and stage.region == "greenland", "Gebiet/Thema")
	assert(#stage.slots == teamSize, "Startfeldanzahl")
	local occupied, floods = {}, {}
	for i, slot in ipairs(stage.slots) do
		assert(slot.y > RunConfig.BOARD_HEIGHT - RunConfig.START_ROWS, "Startzone")
		assert(canWalk(stage.map, slot.x, slot.y), "Startfeld unpassierbar")
		assert(not occupied[cellKey(slot)], "Doppeltes Startfeld")
		occupied[cellKey(slot)] = true
		floods[i] = flood(stage.map, slot)
	end
	local theme = RunConfig.THEMES[themeId]
	local focus, focusCount = {}, 0
	for _, kind in ipairs(theme.enemies) do focus[kind] = true end
	assert(#stage.enemies == RunConfig.enemyCount(depth), "Gegneranzahl")
	for _, enemy in ipairs(stage.enemies) do
		assert(enemy.y <= RunConfig.ENEMY_ROWS, "Gegnerzone")
		assert(canWalk(stage.map, enemy.x, enemy.y), "Gegner unpassierbar")
		assert(not occupied[cellKey(enemy)], "Doppeltes Gegnerfeld")
		occupied[cellKey(enemy)] = true
		assert(enemy.level == RunConfig.enemyLevel(depth), "Gegnerlevel")
		assert(table.find(RunConfig.ENEMY_POOL, enemy.kind), "Unbekannter Gegner")
		if focus[enemy.kind] then focusCount += 1 end
		for i, slot in ipairs(stage.slots) do
			assert(math.abs(slot.x - enemy.x) + math.abs(slot.y - enemy.y) >= RunConfig.MIN_ENEMY_DISTANCE, "Mindestabstand")
			assert(floods[i][cellKey(enemy)], "Gegner nicht erreichbar")
		end
	end
	assert(math.abs(focusCount - #stage.enemies * theme.share) < 1, "Schwerpunktanteil")
end

for _, chunks in pairs(testModules.MapChunks) do
	assert(#chunks >= 10, "Zu wenige Bausteine")
	for _, chunk in ipairs(chunks) do
		assert(#chunk == RunConfig.CHUNK_HEIGHT, "Bausteinhöhe")
		for _, row in ipairs(chunk) do assert(#row == RunConfig.CHUNK_WIDTH, "Bausteinbreite") end
	end
end

for seed = 1, 1000 do
	for depth = 1, RunConfig.LEVELS_PER_REGION do
		local options = LevelGen.makeOptions(seed, depth, "greenland")
		assert(same(options, LevelGen.makeOptions(seed, depth, "greenland")), "Optionen nicht deterministisch")
		assert(#options >= RunConfig.OPTIONS_MIN and #options <= RunConfig.OPTIONS_MAX, "Optionsanzahl")
		local themes = {}
		for _, option in ipairs(options) do
			assert(not themes[option.themeId], "Doppeltes Thema")
			themes[option.themeId] = true
			assert(RunConfig.THEMES[option.themeId], "Unbekanntes Optionsthema")
			assert(option.reward.amount == RunConfig.rewardAmount(option.reward.kind, depth), "Belohnungsmenge")
		end
		for _, themeId in ipairs(RunConfig.THEME_ORDER) do
			local teamSize = (seed - 1) % RunConfig.MAX_TEAM + 1
			local stage = LevelGen.generate(seed, "greenland", depth, themeId, teamSize)
			assert(same(stage, LevelGen.generate(seed, "greenland", depth, themeId, teamSize)), "Level nicht deterministisch")
			validate(stage, themeId, depth, teamSize)
			checks += 1
			if stage.fallback then fallbacks += 1 end
		end
	end
end

local attempts = RunConfig.MAX_ATTEMPTS
RunConfig.MAX_ATTEMPTS = 0
local fallback = LevelGen.generate(17, "greenland", 5, "bow", RunConfig.MAX_TEAM)
assert(fallback.fallback, "Rückfall-Level fehlt")
validate(fallback, "bow", 5, RunConfig.MAX_TEAM)
RunConfig.MAX_ATTEMPTS = attempts
print(string.format("OK: %d Levelpruefungen, 5000 Optionspruefungen; Rueckfall-Level: %d (%.2f%%); erzwungener Rueckfall OK.", checks, fallbacks, fallbacks / checks * 100))
