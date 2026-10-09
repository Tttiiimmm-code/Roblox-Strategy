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
	local possible = {}
	for x = 2, RunConfig.BOARD_WIDTH - 1 do table.insert(possible, x) end
	shuffle(possible, random)
	local count = random(RunConfig.BRIDGES_MIN, RunConfig.BRIDGES_MAX)
	for _, x in ipairs(possible) do
		local spaced = true
		for _, crossing in ipairs(crossings) do
			if math.abs(x - crossing) < 3 then spaced = false end
		end
		if spaced then
			table.insert(crossings, x)
			protected[x - 1], protected[x], protected[x + 1] = true, true, true
			if #crossings == count then break end
		end
	end
	-- Ein Längsfluss würde die unteren Startreihen schneiden: daher links nach rechts.
	local lastRow = RunConfig.BOARD_HEIGHT - RunConfig.START_ROWS - 1
	local top = random(2, lastRow - width + 1)
	local banks = {}
	for x = 1, RunConfig.BOARD_WIDTH do
		local previous = top
		if x > 1 and not protected[x] then
			top = math.clamp(top + random(-1, 1), 2, lastRow - width + 1)
		end
		-- Ein einfeldbreiter Knick braucht eine zweite Zelle für orthogonalen Anschluss.
		local first = width == 1 and math.min(previous, top) or top
		local last = width == 1 and math.max(previous, top) or top + width - 1
		banks[x] = { first = first, last = last }
		for y = first, last do setCell(map, x, y, "W") end
	end
	for _, x in ipairs(crossings) do
		local bank = banks[x]
		for y = bank.first, bank.last do setCell(map, x, y, "B") end
		setCell(map, x, bank.first - 1, ".")
		setCell(map, x, bank.last + 1, ".")
	end
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

function LevelGen.generate(seed, regionId, depth, themeId, teamSize)
	assert(MapChunks[regionId] and RunConfig.THEMES[themeId], "Unbekanntes Gebiet oder Thema")
	assert(teamSize >= 1 and teamSize <= RunConfig.MAX_TEAM and teamSize % 1 == 0, "Ungültige Teamgröße")
	-- Die Flussentscheidung bleibt bei Neuversuchen erhalten, damit die Quote nicht absinkt.
	local withRiver = randomSource(seed)(1, 10000) <= RunConfig.RIVER_CHANCE * 10000
	for attempt = 1, RunConfig.MAX_ATTEMPTS do
		local random = randomSource(seed + (attempt - 1) * 7919)
		local map = compose(regionId, random)
		if withRiver then river(map, random) end
		local stage = populate(map, regionId, depth, themeId, teamSize, random)
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
