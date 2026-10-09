-- Wird vom PowerShell-Runner mit den echten Shared-Modulen verbunden.
local Config = testModules.Config
local RunConfig = testModules.RunConfig
local LevelGen = testModules.LevelGen
local checks, fallbacks = 0, 0
local riverChecks, bridgeCounts, riverWidths = 0, {}, {}

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

local function charAt(map, x, y)
	local row = map[y]
	return row and row:sub(x, x) or ""
end

local function validateRiver(stage)
	local map = stage.map
	local river = stage.features and stage.features.river
	if not river then
		for _, row in ipairs(map) do assert(not row:find("B"), "Brücke ohne Fluss") end
		return false
	end
	local riverCells, first = {}, river.cells[1]
	local low, high = math.huge, 0
	for _, cell in ipairs(river.cells) do
		local char = charAt(map, cell.x, cell.y)
		assert(char == "W" or char == "B", "Flussbett überschrieben")
		assert(cell.y < RunConfig.BOARD_HEIGHT - RunConfig.START_ROWS, "Fluss in/an Startzone")
		riverCells[cellKey(cell)] = true
		low, high = math.min(low, cell.y), math.max(high, cell.y)
	end
	assert(high - low >= RunConfig.RIVER_MIN_SWING, "Zu wenig Mäander")
	assert(river.width >= 1 and river.width <= 2, "Flussbreite")
	riverWidths[river.width] = true
	local crossingSet = {}
	for _, x in ipairs(river.crossings) do crossingSet[x] = true end
	for x = 1, RunConfig.BOARD_WIDTH do
		local bank = river.banks[x]
		assert(bank and bank.last - bank.first + 1 >= 1 and bank.last - bank.first + 1 <= 2, "Flussquerschnitt")
		for y = bank.first, bank.last do
			assert(riverCells[cellKey({ x = x, y = y })], "Lücke im Flussbett")
			assert(charAt(map, x, y) == (crossingSet[x] and "B" or "W"), "Brücke überspannt nicht volle Breite")
			if crossingSet[x] then
				assert(charAt(map, x - 1, y) == "W" and charAt(map, x + 1, y) == "W", "Brücke ohne seitliches Wasser")
			end
		end
		if crossingSet[x] then
			assert(canWalk(map, x, bank.first - 1) and canWalk(map, x, bank.last + 1), "Unpassierbares Brückenufer")
		end
	end
	local count = #river.crossings
	assert(count >= RunConfig.BRIDGES_MIN and count <= RunConfig.BRIDGES_MAX, "Brückenanzahl")
	bridgeCounts[count] = true
	local seen, queue, head = { [cellKey(first)] = true }, { first }, 1
	while head <= #queue do
		local cell = queue[head]
		head += 1
		for _, offset in ipairs({ { -1, 0 }, { 1, 0 }, { 0, -1 }, { 0, 1 } }) do
			local nextCell = { x = cell.x + offset[1], y = cell.y + offset[2] }
			local id = cellKey(nextCell)
			if riverCells[id] and not seen[id] then seen[id] = true; table.insert(queue, nextCell) end
		end
	end
	local left, right = false, false
	for id in pairs(riverCells) do assert(seen[id], "Unterbrochener Fluss") end
	for _, cell in ipairs(queue) do
		if cell.x == 1 then left = true end
		if cell.x == RunConfig.BOARD_WIDTH then right = true end
	end
	assert(left and right, "Fluss erreicht nicht beide Ränder")
	return true
end

local function validateLakes(stage, floods)
	local features = stage.features or {}
	local lake = features.lake
	if lake then
		assert(lake.width >= 3 and lake.width <= 5 and lake.height >= 3 and lake.height <= 4, "Seegröße")
		local island = {}
		assert(#lake.island <= 2, "Inselgröße")
		for _, cell in ipairs(lake.island) do
			island[cellKey(cell)] = true
			assert(canWalk(stage.map, cell.x, cell.y), "Insel ohne Land/Wald")
			for _, enemy in ipairs(stage.enemies) do
				if cellKey(cell) == cellKey(enemy) then
					for _, seen in ipairs(floods) do assert(seen[cellKey(cell)], "Gegner auf unerreichbarer Insel") end
				end
			end
		end
		local water = 0
		for _, cell in ipairs(lake.cells) do
			if not island[cellKey(cell)] then
				assert(charAt(stage.map, cell.x, cell.y) == "W", "See überschrieben")
				water += 1
			end
		end
		assert(water >= 4, "See ohne Wasser")
	end
	for _, pond in ipairs(features.ponds or {}) do
		assert(#pond.cells >= 1 and #pond.cells <= 2, "Teichgröße")
		for _, cell in ipairs(pond.cells) do assert(charAt(stage.map, cell.x, cell.y) == "W", "Teich überschrieben") end
	end
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
		local char = charAt(stage.map, slot.x, slot.y)
		assert(char == "." or char == "F", "Startfeld auf Brücke/Festung/Wasser/Fels")
		assert(canWalk(stage.map, slot.x, slot.y - 1), "Start ohne Weg nach vorn")
		assert(not occupied[cellKey(slot)], "Doppeltes Startfeld")
		occupied[cellKey(slot)] = true
		floods[i] = flood(stage.map, slot)
	end
	for _, slot in ipairs(stage.slots) do
		assert(not occupied[cellKey({ x = slot.x, y = slot.y - 1 })], "Mitspieler blockiert Weg nach vorn")
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
	if validateRiver(stage) then riverChecks += 1 end
	validateLakes(stage, floods)
end

for region, chunks in pairs(testModules.MapChunks) do
	if region == "bossMaps" then continue end
	assert(#chunks >= 30, "Zu wenige Bausteine")
	local distinct = {}
	for _, chunk in ipairs(chunks) do
		assert(#chunk.rows == RunConfig.CHUNK_HEIGHT, "Bausteinhöhe")
		local west, east = "", ""
		for _, row in ipairs(chunk.rows) do
			assert(#row == RunConfig.CHUNK_WIDTH, "Bausteinbreite")
			assert(not row:find("[^.FMH]"), "Wasser/Brücke oder unbekanntes Gelände im Baustein")
			west ..= row:sub(1, 1)
			east ..= row:sub(-1)
		end
		assert(chunk.edges.north == chunk.rows[1] and chunk.edges.south == chunk.rows[#chunk.rows], "Nord-/Südkennung")
		assert(chunk.edges.west == west and chunk.edges.east == east, "West-/Ostkennung")
		local id = table.concat(chunk.rows, "/")
		assert(not distinct[id], "Doppelter Baustein")
		distinct[id] = true
	end
end

local maps, uniqueMaps, terrainCells, sampleRivers = {}, 0, 0, 0
local sampleLakes, sampleIslands, samplePonds = 0, 0, 0
for seed = 1, 200 do
	local sample = LevelGen.generate(seed, "greenland", 1, "axe", RunConfig.START_TEAM)
	local id = table.concat(sample.map, "/")
	if not maps[id] then maps[id] = true; uniqueMaps += 1 end
	local hasRiver = sample.features and sample.features.river ~= nil
	if sample.features and sample.features.lake then
		sampleLakes += 1
		if #sample.features.lake.island > 0 then sampleIslands += 1 end
	end
	if sample.features and sample.features.ponds and #sample.features.ponds > 0 then samplePonds += 1 end
	for _, row in ipairs(sample.map) do
		for x = 1, #row do
			local char = row:sub(x, x)
			if char ~= "." then terrainCells += 1 end
			
		end
	end
	if hasRiver then sampleRivers += 1 end
	for depth = 1, RunConfig.LEVELS_PER_REGION do
		local options = LevelGen.makeOptions(seed, depth, "greenland")
		assert(same(options, LevelGen.makeOptions(seed, depth, "greenland")), "Optionen nicht deterministisch")
		local bossKind = RunConfig.levelKind(depth)
		assert(bossKind == "battle" and #options >= RunConfig.OPTIONS_MIN and #options <= RunConfig.OPTIONS_MAX
			or bossKind ~= "battle" and #options == 1, "Optionsanzahl")
		local camps = 0
		local themes = {}
		for _, option in ipairs(options) do
			if option.kind == "camp" then
				camps += 1
				assert(bossKind == "battle" and not option.reward, "Lager an Bosslevel/mit Belohnung")
				continue
			end
			assert(option.kind == bossKind, "Falsche Bossabfolge")
			if bossKind ~= "battle" then assert(option.bossId == RunConfig.BOSSES.greenland[bossKind], "Boss-ID") end
			assert(not themes[option.themeId], "Doppeltes Thema")
			themes[option.themeId] = true
			assert(RunConfig.THEMES[option.themeId], "Unbekanntes Optionsthema")
			assert(option.reward.amount == RunConfig.rewardAmount(option.reward.kind, depth), "Belohnungsmenge")
		end
		assert(camps <= 1, "Mehrere Lager in einer Wahl")
		for _, themeId in ipairs(RunConfig.THEME_ORDER) do
			for teamSize = 1, RunConfig.MAX_TEAM do
				local stage = LevelGen.generate(seed, "greenland", depth, themeId, teamSize)
				assert(same(stage, LevelGen.generate(seed, "greenland", depth, themeId, teamSize)), "Level nicht deterministisch")
				validate(stage, themeId, depth, teamSize)
				checks += 1
				if stage.fallback then fallbacks += 1 end
			end
		end
	end
end

assert(uniqueMaps >= 180, "Zu wenig Kartenvielfalt")
assert(terrainCells / (200 * RunConfig.BOARD_WIDTH * RunConfig.BOARD_HEIGHT) >= 0.2, "Zu wenig Gelände")
assert(fallbacks / checks <= 0.001, "Zu viele Rückfall-Level")
assert(bridgeCounts[2] and bridgeCounts[3] and riverWidths[1] and riverWidths[2], "Fluss-/Brückenvarianten fehlen")

-- Ohne Fluss müssen alle gespiegelten Nachbarn exakt gleiche Anschlussprofile haben.
local chance = RunConfig.RIVER_CHANCE
local lakeChance, pondChance = RunConfig.LAKE_CHANCE, RunConfig.POND_CHANCE
RunConfig.LAKE_CHANCE, RunConfig.POND_CHANCE = 0, 0
RunConfig.RIVER_CHANCE = 0
local forestJoins, rockJoins = 0, 0
for seed = 1, 200 do
	local stage = LevelGen.generate(seed, "greenland", 1, "axe", RunConfig.MAX_TEAM)
	for y = 1, #stage.map do
		local left, right = charAt(stage.map, RunConfig.CHUNK_WIDTH, y), charAt(stage.map, RunConfig.CHUNK_WIDTH + 1, y)
		assert(left == right, "West-/Ostanschluss nach Spiegelung")
		if left == "F" then forestJoins += 1 elseif left == "M" then rockJoins += 1 end
	end
	for x = 1, RunConfig.BOARD_WIDTH do
		local top, bottom = charAt(stage.map, x, RunConfig.CHUNK_HEIGHT), charAt(stage.map, x, RunConfig.CHUNK_HEIGHT + 1)
		assert(top == bottom, "Nord-/Südanschluss nach Spiegelung")
		if top == "F" then forestJoins += 1 elseif top == "M" then rockJoins += 1 end
	end
	assert(not validateRiver(stage), "Fluss trotz Chance 0")
end
assert(forestJoins > 0 and rockJoins > 0, "Keine Wald-/Felsanschlüsse")
RunConfig.RIVER_CHANCE = 1
for _, seed in ipairs({ 0, -1, 2147483646, 987654321 }) do
	for teamSize = 1, RunConfig.MAX_TEAM do
		local stage = LevelGen.generate(seed, "greenland", 5, "bow", teamSize)
		assert(validateRiver(stage), "Fluss trotz Chance 1 fehlt")
		validate(stage, "bow", 5, teamSize)
		assert(same(stage, LevelGen.generate(seed, "greenland", 5, "bow", teamSize)), "Randseed nicht deterministisch")
	end
end
RunConfig.RIVER_CHANCE = chance
RunConfig.LAKE_CHANCE, RunConfig.POND_CHANCE = lakeChance, pondChance

local attempts = RunConfig.MAX_ATTEMPTS
RunConfig.MAX_ATTEMPTS = 0
local fallback = LevelGen.generate(17, "greenland", 5, "bow", RunConfig.MAX_TEAM)
assert(fallback.fallback, "Rückfall-Level fehlt")
validate(fallback, "bow", 5, RunConfig.MAX_TEAM)
RunConfig.MAX_ATTEMPTS = attempts
print(string.format("OK: %d Levelpruefungen, 1000 Optionspruefungen; Rueckfall-Level: %d (%.2f%%); erzwungener Rueckfall OK.", checks, fallbacks, fallbacks / checks * 100))
print(string.format("Vielfalt: %d/200 verschiedene Karten; Gelaendeanteil %.2f%%; Flussquote %.2f%%; %d Flusspruefungen; Anschluesse Wald/Fels: %d/%d.", uniqueMaps, terrainCells / (200 * RunConfig.BOARD_WIDTH * RunConfig.BOARD_HEIGHT) * 100, sampleRivers / 2, riverChecks, forestJoins, rockJoins))

print(string.format("Wasser: Seen %.2f%%; Inselkarten %.2f%%; Teiche %.2f%%.", sampleLakes / 2, sampleIslands / 2, samplePonds / 2))

local bossChecks = 0
for seed = 1, 200 do
	for _, kind in ipairs({ "miniboss", "boss" }) do
		local depth = kind == "miniboss" and 3 or 5
		for size = 1, RunConfig.MAX_TEAM do
			local stage = LevelGen.generate(seed, "greenland", depth, "axe", size, kind)
			assert(same(stage, LevelGen.generate(seed, "greenland", depth, "axe", size, kind)), "Bosskarte nicht deterministisch")
			assert(#stage.slots == size and stage.enemies[1].kind == RunConfig.BOSSES.greenland[kind], "Boss/Startzahl")
			assert(stage.kind == kind and stage.bossId == stage.enemies[1].kind, "Bossmetadaten")
			assert(#stage.enemies == (kind == "boss" and 4 or RunConfig.MINIBOSS_GUARDS + 1), "Leibwache")
			local occupied = {}
			for _, pos in ipairs(stage.slots) do
				assert(pos.y >= 7 and canWalk(stage.map, pos.x, pos.y - 1), "Bossstart ohne Weg")
				assert(not occupied[cellKey(pos)], "Doppelter Bossstart")
				occupied[cellKey(pos)] = true
				local seen = flood(stage.map, pos)
				for _, enemy in ipairs(stage.enemies) do assert(seen[cellKey(enemy)], "Boss/Leibwache nicht erreichbar") end
				for _, field in ipairs(stage.reinforcementFields or {}) do assert(seen[cellKey(field)], "Ankunft nicht erreichbar") end
			end
			for _, enemy in ipairs(stage.enemies) do
				assert(not occupied[cellKey(enemy)], "Doppeltes Bossgegnerfeld")
				occupied[cellKey(enemy)] = true
			end
			if kind == "boss" then
				local boss = stage.enemies[1]
				assert(charAt(stage.map, boss.x, boss.y) == "H", "Garrick ohne Festung")
				assert(#stage.reinforcementFields >= 3, "Zu wenig Randfelder")
				for _, field in ipairs(stage.reinforcementFields) do
					assert(field.x == 1 or field.x == RunConfig.BOARD_WIDTH, "Ankunft nicht am Rand")
					assert(canWalk(stage.map, field.x, field.y) and not occupied[cellKey(field)], "Ankunft belegt")
					occupied[cellKey(field)] = true
				end
			end
			bossChecks += 1
		end
	end
end
print("OK: " .. bossChecks .. " Boss-/Minibosskarten (Festung, Starts, Erreichbarkeit, freie Randfelder).")
