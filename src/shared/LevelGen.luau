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

local function setCell(map, x, y, char)
	local row = map[y]
	map[y] = row:sub(1, x - 1) .. char .. row:sub(x + 1)
end

local function mirror(chunk, flipX, flipY)
	local rows, edges = {}, chunk.edges
	for y = 1, #chunk.rows do
		local row = chunk.rows[flipY and (#chunk.rows + 1 - y) or y]
		rows[y] = flipX and string.reverse(row) or row
	end
	local north, south = flipY and edges.south or edges.north, flipY and edges.north or edges.south
	local west, east = flipX and edges.east or edges.west, flipX and edges.west or edges.east
	return { rows = rows, edges = {
		north = flipX and string.reverse(north) or north,
		south = flipX and string.reverse(south) or south,
		west = flipY and string.reverse(west) or west,
		east = flipY and string.reverse(east) or east,
	} }
end

local variants = {}
for regionId, chunks in pairs(MapChunks) do
	variants[regionId] = {}
	for _, chunk in ipairs(chunks) do
		for flipX = 0, 1 do
			for flipY = 0, 1 do
				table.insert(variants[regionId], mirror(chunk, flipX == 1, flipY == 1))
			end
		end
	end
end

local function compose(regionId, random)
	local rows, placed = {}, {}
	for cy = 1, RunConfig.BOARD_HEIGHT / RunConfig.CHUNK_HEIGHT do
		placed[cy] = {}
		for cx = 1, RunConfig.BOARD_WIDTH / RunConfig.CHUNK_WIDTH do
			local left = placed[cy][cx - 1]
			local above = placed[cy - 1] and placed[cy - 1][cx]
			local candidates = {}
			for _, variant in ipairs(variants[regionId]) do
				if (not left or left.edges.east == variant.edges.west)
					and (not above or above.edges.south == variant.edges.north) then
					table.insert(candidates, variant)
				end
			end
			local chunk
			if #candidates > 0 then
				chunk = candidates[random(1, #candidates)]
			else
				-- Bei späteren unvollständigen Katalogen beide Seiten des Anschlusses öffnen.
				local openRows = {}
				for y = 1, RunConfig.CHUNK_HEIGHT do
					openRows[y] = string.rep(".", RunConfig.CHUNK_WIDTH)
					if left then setCell(rows, (cx - 1) * RunConfig.CHUNK_WIDTH, (cy - 1) * RunConfig.CHUNK_HEIGHT + y, ".") end
				end
				if above then
					for x = 1, RunConfig.CHUNK_WIDTH do
						setCell(rows, (cx - 1) * RunConfig.CHUNK_WIDTH + x, (cy - 1) * RunConfig.CHUNK_HEIGHT, ".")
					end
				end
				chunk = { rows = openRows, edges = {
					north = openRows[1], south = openRows[1],
					west = string.rep(".", RunConfig.CHUNK_HEIGHT), east = string.rep(".", RunConfig.CHUNK_HEIGHT),
				} }
			end
			placed[cy][cx] = chunk
			for y, row in ipairs(chunk.rows) do
				local targetY = (cy - 1) * RunConfig.CHUNK_HEIGHT + y
				rows[targetY] = (rows[targetY] or "") .. row
			end
		end
	end
	return rows
end

local function river(map, random)
	local width = random(RunConfig.RIVER_WIDTH.min, RunConfig.RIVER_WIDTH.max)
	local crossings, protected = {}, {}
	local count = random(RunConfig.BRIDGES_MIN, RunConfig.BRIDGES_MAX)
	-- Gleichmäßig verteilte Querungen lassen zwischen ihren geraden Ufern Kurven frei.
	for i = 1, count do
		local x = math.floor(i * RunConfig.BOARD_WIDTH / (count + 1))
		table.insert(crossings, x)
		protected[x - 1], protected[x], protected[x + 1] = true, true, true
	end
	local lastRow = RunConfig.BOARD_HEIGHT - RunConfig.START_ROWS - 1
	local top = random(2, lastRow - width + 1)
	local direction = random(0, 1) == 0 and -1 or 1
	local length = random(RunConfig.RIVER_BEND_LENGTH.min, RunConfig.RIVER_BEND_LENGTH.max)
	local banks, cells, reserved = {}, {}, {}
	local low, high = top, top
	for x = 1, RunConfig.BOARD_WIDTH do
		local previous = top
		if x > 1 and not protected[x] then
			if top + direction < 2 or top + direction > lastRow - width + 1 or length == 0 then
				direction = -direction
				length = random(RunConfig.RIVER_BEND_LENGTH.min, RunConfig.RIVER_BEND_LENGTH.max)
			end
			top = math.clamp(top + direction, 2, lastRow - width + 1)
			length -= 1
		end
		low, high = math.min(low, top), math.max(high, top)
		-- Ein schmaler Knick erhält eine zweite Zelle für den orthogonalen Anschluss.
		local first = width == 1 and math.min(previous, top) or top
		local last = width == 1 and math.max(previous, top) or top + width - 1
		banks[x] = { first = first, last = last }
		for y = first, last do
			setCell(map, x, y, "W")
			table.insert(cells, { x = x, y = y })
		end
	end
	if high - low < RunConfig.RIVER_MIN_SWING then return nil end
	for _, x in ipairs(crossings) do
		local bank = banks[x]
		for y = bank.first, bank.last do setCell(map, x, y, "B") end
		setCell(map, x, bank.first - 1, ".")
		setCell(map, x, bank.last + 1, ".")
		-- Seen/Teiche dürfen Brücken, Ufer und seitliches Wasser nicht überschreiben.
		for xx = x - 1, x + 1 do
			for y = bank.first - 1, bank.last + 1 do reserved[key(xx, y)] = true end
		end
	end
	return { width = width, banks = banks, crossings = crossings, cells = cells }, reserved
end

local function lake(map, random, riverFeature, reserved)
	local width = random(RunConfig.LAKE_WIDTH.min, RunConfig.LAKE_WIDTH.max)
	local height = random(RunConfig.LAKE_HEIGHT.min, RunConfig.LAKE_HEIGHT.max)
	local withIsland = random(1, 10000) <= RunConfig.ISLAND_CHANCE * 10000
	local riverCells = {}
	for _, cell in ipairs(riverFeature and riverFeature.cells or {}) do riverCells[key(cell.x, cell.y)] = true end
	for _ = 1, RunConfig.WATER_PLACEMENT_ATTEMPTS do
		local left = random(2, RunConfig.BOARD_WIDTH - width)
		local top = random(1, RunConfig.BOARD_HEIGHT - RunConfig.START_ROWS - height)
		local valid = true
		for y = top, top + height - 1 do
			for x = left, left + width - 1 do
				if reserved[key(x, y)] then valid = false end
			end
		end
		local island = {}
		if withIsland then
			local x, y = left + math.floor((width - 1) / 2), top + 1
			table.insert(island, { x = x, y = y })
			if width >= 4 and random(0, 1) == 1 then table.insert(island, { x = x + 1, y = y }) end
			for _, cell in ipairs(island) do if riverCells[key(cell.x, cell.y)] then valid = false end end
		end
		if not valid then continue end
		local cells = {}
		-- Nur eine Ecke ausschneiden, damit auch kleine Seen um Inseln verbunden bleiben.
		local cutCorner = random(1, 4)
		for y = top, top + height - 1 do
			for x = left, left + width - 1 do
				local corner = (x == left or x == left + width - 1) and (y == top or y == top + height - 1)
				local cornerId = (x == left and 1 or 2) + (y == top and 0 or 2)
				if not corner or cornerId ~= cutCorner then
					setCell(map, x, y, "W")
					table.insert(cells, { x = x, y = y })
				end
				reserved[key(x, y)] = true
			end
		end
		for _, cell in ipairs(island) do setCell(map, cell.x, cell.y, random(0, 1) == 0 and "." or "F") end
		return { x = left, y = top, width = width, height = height, cells = cells, island = island }
	end
	return nil
end

local function ponds(map, random, reserved)
	local result = {}
	for _ = 1, random(RunConfig.POND_COUNT.min, RunConfig.POND_COUNT.max) do
		for _ = 1, RunConfig.WATER_PLACEMENT_ATTEMPTS do
			local x = random(2, RunConfig.BOARD_WIDTH - 2)
			local y = random(1, RunConfig.BOARD_HEIGHT - RunConfig.START_ROWS - 1)
			local count = random(1, 2)
			local valid = true
			for xx = x, x + count - 1 do
				if reserved[key(xx, y)] or not passable(map, xx, y, "foot") then valid = false end
			end
			if not valid then continue end
			local cells = {}
			for xx = x, x + count - 1 do
				setCell(map, xx, y, "W")
				reserved[key(xx, y)] = true
				table.insert(cells, { x = xx, y = y })
			end
			table.insert(result, { cells = cells })
			break
		end
	end
	return result
end

local function cliffs(map, random, reserved, withWaterfall)
	local lastRow = RunConfig.BOARD_HEIGHT - RunConfig.START_ROWS - 1
	if withWaterfall then
		local candidates = {}
		for y = 1, lastRow do for x = 1, RunConfig.BOARD_WIDTH do
			if map[y]:sub(x, x) ~= "W" then continue end
			for _, d in { { 1, 0 }, { -1, 0 }, { 0, 1 }, { 0, -1 } } do
				local sx, sy = x - d[1], y - d[2]
				if sx >= 1 and sx <= RunConfig.BOARD_WIDTH and sy >= 1 and sy <= lastRow then
					local ch = map[sy]:sub(sx, sx)
					if ch ~= "W" and ch ~= "B" and ch ~= "D" and not reserved[key(sx, sy)] then
						table.insert(candidates, { x = sx, y = sy, dx = d[1], dy = d[2] })
					end
				end
			end
		end end
		shuffle(candidates, random)
		for i = 1, math.min(#candidates, RunConfig.WATER_PLACEMENT_ATTEMPTS) do
			local fall = candidates[i]
			local width = random(RunConfig.CLIFF_WIDTH.min, RunConfig.CLIFF_WIDTH.max)
			local height = random(RunConfig.CLIFF_HEIGHT.min, RunConfig.CLIFF_HEIGHT.max)
			local left = fall.dx == 1 and fall.x - width + 1 or fall.dx == -1 and fall.x or fall.x - random(0, width - 1)
			local top = fall.dy == 1 and fall.y - height + 1 or fall.dy == -1 and fall.y or fall.y - random(0, height - 1)
			local cells, valid = {}, true
			if left < 1 or left + width - 1 > RunConfig.BOARD_WIDTH or top < 1 or top + height - 1 > lastRow then continue end
			for yy = top, top + height - 1 do for xx = left, left + width - 1 do
				local ch = map[yy]:sub(xx, xx)
				if reserved[key(xx, yy)] or ch == "W" or ch == "B" or ch == "D" then valid = false end
				table.insert(cells, { x = xx, y = yy })
			end end
			if valid then
				for _, cell in cells do setCell(map, cell.x, cell.y, "C") end
				return { cells = cells }, fall
			end
		end
	end
	for _ = 1, RunConfig.WATER_PLACEMENT_ATTEMPTS do
		local width = random(RunConfig.CLIFF_WIDTH.min, RunConfig.CLIFF_WIDTH.max)
		local height = random(RunConfig.CLIFF_HEIGHT.min, RunConfig.CLIFF_HEIGHT.max)
		local edge = random(1, 3)
		local left = edge == 1 and 1 or edge == 2 and RunConfig.BOARD_WIDTH - width + 1
			or random(1, RunConfig.BOARD_WIDTH - width + 1)
		local top = edge == 3 and 1 or random(1, lastRow - height + 1)
		local cells, valid = {}, true
		for y = top, top + height - 1 do
			for x = left, left + width - 1 do
				local char = map[y]:sub(x, x)
				if reserved[key(x, y)] or char == "W" or char == "B" then valid = false end
				table.insert(cells, { x = x, y = y })
			end
		end
		if valid then
			for _, cell in ipairs(cells) do setCell(map, cell.x, cell.y, "C") end
			return { cells = cells }, nil
		end
	end
	return nil, nil
end

local function populate(map, regionId, depth, themeId, teamSize, random)
	local starts, forestStarts = {}, {}
	local blocked = 0
	for y, row in ipairs(map) do
		for x = 1, #row do
			if not passable(map, x, y, "foot") then blocked += 1 end
			local char = row:sub(x, x)
			if y > RunConfig.BOARD_HEIGHT - RunConfig.START_ROWS and (char == "." or char == "F")
				and passable(map, x, y - 1, "horse") then
				table.insert(char == "." and starts or forestStarts, { x = x, y = y })
			end
		end
	end
	if blocked / (RunConfig.BOARD_WIDTH * RunConfig.BOARD_HEIGHT) > RunConfig.MAX_BLOCKED_SHARE
		or #starts + #forestStarts < teamSize then return nil end
	shuffle(starts, random)
	shuffle(forestStarts, random)
	for _, slot in ipairs(forestStarts) do table.insert(starts, slot) end
	-- Erst die Mitte belegen; die ganze Startzone bleibt für spätere Teamgrößen nutzbar.
	table.sort(starts, function(a, b)
		local center = (RunConfig.BOARD_WIDTH + 1) / 2
		local scoreA = math.abs(a.x - center) * 10 + RunConfig.BOARD_HEIGHT - a.y
		local scoreB = math.abs(b.x - center) * 10 + RunConfig.BOARD_HEIGHT - b.y
		return scoreA < scoreB
	end)
	local slots = {}
	for _, candidate in ipairs(starts) do
		local free = true
		for _, slot in ipairs(slots) do
			if slot.x == candidate.x and math.abs(slot.y - candidate.y) == 1 then free = false end
		end
		if free then table.insert(slots, candidate) end
		if #slots == teamSize then break end
	end
	if #slots < teamSize then return nil end
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

local function bossStage(seed, regionId, depth, teamSize)
	local source = assert(MapChunks.bossMaps[regionId], "Bosskarte fehlt")
	local flipped = randomSource(seed)(0, 1) == 1
	local function cell(pos)
		return { x = flipped and RunConfig.BOARD_WIDTH + 1 - pos.x or pos.x, y = pos.y }
	end
	local map, slots, fields, enemies = {}, {}, {}, {}
	for y, row in ipairs(source.map) do map[y] = flipped and row:reverse() or row end
	for i = 1, teamSize do table.insert(slots, cell(source.slots[i])) end
	for _, pos in ipairs(source.reinforcementFields) do table.insert(fields, cell(pos)) end
	local boss = cell(source.boss)
	boss.kind, boss.level = RunConfig.BOSSES[regionId].boss, RunConfig.enemyLevel(depth)
	table.insert(enemies, boss)
	for _, pos in ipairs(source.guards) do
		local guard = cell(pos)
		guard.kind, guard.level = "brigand", RunConfig.enemyLevel(depth)
		table.insert(enemies, guard)
	end
	local visited = reachable(map, slots[1])
	for _, list in ipairs({ slots, fields, enemies }) do
		for _, pos in ipairs(list) do assert(visited[key(pos.x, pos.y)], "Bosskarte nicht erreichbar") end
	end
	return { map = map, slots = slots, enemies = enemies, region = regionId, theme = "axe", kind = "boss",
		bossId = boss.kind, reinforcementFields = fields, fallback = false }
end

local function withMiniboss(stage, regionId)
	stage.kind, stage.bossId = "miniboss", RunConfig.BOSSES[regionId].miniboss
	stage.enemies[1].kind = stage.bossId
	for i = #stage.enemies, RunConfig.MINIBOSS_GUARDS + 2, -1 do table.remove(stage.enemies, i) end
	for i = 2, #stage.enemies do stage.enemies[i].kind = "brigand" end
	return stage
end

function LevelGen.generate(seed, regionId, depth, themeId, teamSize, levelKind)
	assert(MapChunks[regionId] and RunConfig.THEMES[themeId], "Unbekanntes Gebiet oder Thema")
	assert(teamSize >= 1 and teamSize <= RunConfig.MAX_TEAM and teamSize % 1 == 0, "Ungültige Teamgröße")
	if levelKind == "boss" then return bossStage(seed, regionId, depth, teamSize) end
	-- Die Flussentscheidung bleibt bei Neuversuchen erhalten, damit die Quote nicht absinkt.
	local featuresRandom = randomSource(seed)
	local withRiver = featuresRandom(1, 10000) <= RunConfig.RIVER_CHANCE * 10000
	local withLake = featuresRandom(1, 10000) <= RunConfig.LAKE_CHANCE * 10000
	local withPonds = featuresRandom(1, 10000) <= RunConfig.POND_CHANCE * 10000
	local withCliffs = featuresRandom(1, 10000) <= RunConfig.CLIFF_CHANCE * 10000
	local withWaterfall = featuresRandom(1, 10000) <= RunConfig.WATERFALL_CHANCE * 10000
	for attempt = 1, RunConfig.MAX_ATTEMPTS do
		local random = randomSource(seed + (attempt - 1) * 7919)
		local map = compose(regionId, random)
		local features, reserved = {}, {}
		if withRiver then
			features.river, reserved = river(map, random)
			if not features.river then continue end
		end
		if withLake then
			features.lake = lake(map, random, features.river, reserved)
			if not features.lake then continue end
		end
		if withPonds then features.ponds = ponds(map, random, reserved) end
		if withCliffs then
			features.cliffs, features.waterfall = cliffs(map, random, reserved, withWaterfall)
			if not features.cliffs then continue end
		end
		local stage = populate(map, regionId, depth, themeId, teamSize, random)
		if stage then
			stage.features = features
			stage.fallback = false
			return levelKind == "miniboss" and withMiniboss(stage, regionId) or stage
		end
	end
	local map = {}
	for y = 1, RunConfig.BOARD_HEIGHT do map[y] = string.rep(".", RunConfig.BOARD_WIDTH) end
	local stage = populate(map, regionId, depth, themeId, teamSize, randomSource(seed))
	assert(stage, "Rückfall-Level konnte nicht erzeugt werden")
	stage.fallback = true
	return levelKind == "miniboss" and withMiniboss(stage, regionId) or stage
end

function LevelGen.makeOptions(runSeed, depth, regionId)
	assert(MapChunks[regionId], "Unbekanntes Gebiet")
	local random = randomSource(runSeed + depth * 104729)
	local levelKind = RunConfig.levelKind(depth)
	if levelKind ~= "battle" then
		return { { kind = levelKind, bossId = RunConfig.BOSSES[regionId][levelKind], themeId = "axe",
			reward = { kind = "gold", amount = RunConfig.rewardAmount("gold", depth) }, seed = random(1, MODULUS - 1) } }
	end
	local themes = table.clone(RunConfig.THEME_ORDER)
	shuffle(themes, random)
	local count = random(RunConfig.OPTIONS_MIN, math.min(RunConfig.OPTIONS_MAX, #themes))
	local options = {}
	for i = 1, count do
		local kind = RunConfig.REWARD_ORDER[random(1, #RunConfig.REWARD_ORDER)]
		options[i] = { kind = "battle", themeId = themes[i], reward = { kind = kind, amount = RunConfig.rewardAmount(kind, depth) }, seed = random(1, MODULUS - 1) }
	end
	if random(1, 10000) <= RunConfig.CAMP_CHANCE * 10000 then
		options[random(1, count)] = { kind = "camp", seed = random(1, MODULUS - 1) }
	end
	return options
end

return LevelGen
