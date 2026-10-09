-- Raster-Logik: Gelände, Reichweiten, Wegfindung (von Server und Client genutzt)
local Config = require(script.Parent.Config)
local UnitData = require(script.Parent.UnitData)

local Grid = {}

local DIRS = { { 1, 0 }, { -1, 0 }, { 0, 1 }, { 0, -1 } }
local map = { "." } -- aktuelle Karte (Zeilen aus Stages), wird per Grid.setMap gesetzt
local heights = {}

function Grid.setMap(rows)
	map = rows
	heights = {}
end

function Grid.setHeights(values)
	heights = table.clone(values or {})
end

function Grid.getHeights()
	return table.clone(heights)
end

function Grid.getMap()
	return map
end

function Grid.key(x, y)
	return x .. "," .. y
end

function Grid.width()
	return #map[1]
end

function Grid.height()
	return #map
end

function Grid.inBounds(x, y)
	return x >= 1 and y >= 1 and x <= Grid.width() and y <= Grid.height()
end

function Grid.terrainAt(x, y)
	if not Grid.inBounds(x, y) then
		return nil
	end
	return Config.TERRAIN[string.sub(map[y], x, x)]
end

-- Mittelpunkt der Feld-Oberseite in Weltkoordinaten
function Grid.tileHeight(x, y)
	local override = heights[Grid.key(x, y)]
	if override ~= nil then return override end
	local terrain = Grid.terrainAt(x, y)
	return terrain and terrain.height or 0
end

function Grid.bridgeCrossings()
	local crossings, seen = {}, {}
	local function char(x, y) return Grid.inBounds(x, y) and map[y]:sub(x, x) or "" end
	for y = 1, Grid.height() do for x = 1, Grid.width() do
		if char(x, y) ~= "B" or seen[Grid.key(x, y)] then continue end
		local cells = { { x = x, y = y } }
		local minX, maxX, minY, maxY = x, x, y, y
		seen[Grid.key(x, y)] = true
		local index = 1
		while index <= #cells do
			local cell = cells[index]; index += 1
			for _, d in DIRS do
				local nx, ny = cell.x + d[1], cell.y + d[2]
				if char(nx, ny) == "B" and not seen[Grid.key(nx, ny)] then
					seen[Grid.key(nx, ny)] = true
					table.insert(cells, { x = nx, y = ny })
					minX, maxX, minY, maxY = math.min(minX, nx), math.max(maxX, nx), math.min(minY, ny), math.max(maxY, ny)
				end
			end
		end
		local alongX = maxX - minX > maxY - minY
		if maxX - minX == maxY - minY then
			local sideX, sideY = 0, 0
			for _, cell in cells do
				for _, d in DIRS do
					local ch = char(cell.x + d[1], cell.y + d[2])
					if ch == "W" or ch == "D" then if d[1] ~= 0 then sideX += 1 else sideY += 1 end end
				end
			end
			alongX = sideY > sideX
		end
		local banks = {}
		if alongX then
			for yy = minY, maxY do table.insert(banks, { x = minX - 1, y = yy }); table.insert(banks, { x = maxX + 1, y = yy }) end
		else
			for xx = minX, maxX do table.insert(banks, { x = xx, y = minY - 1 }); table.insert(banks, { x = xx, y = maxY + 1 }) end
		end
		table.insert(crossings, { cells = cells, banks = banks, x = (minX + maxX) / 2, y = (minY + maxY) / 2,
			length = alongX and maxX - minX + 1 or maxY - minY + 1, alongX = alongX, angle = alongX and 0 or math.pi / 2 })
	end end
	return crossings
end

function Grid.toWorld(x, y)
	local t = Config.TILE_SIZE
	return Vector3.new((x - 0.5) * t, Grid.tileHeight(x, y), (y - 0.5) * t)
end

function Grid.dist(ax, ay, bx, by)
	return math.abs(ax - bx) + math.abs(ay - by)
end

function Grid.unitAt(units, x, y)
	for _, u in units do
		if u.x == x and u.y == y then
			return u
		end
	end
	return nil
end

function Grid.moveCost(unit, x, y)
	local terrain = Grid.terrainAt(x, y)
	if not terrain then
		return nil
	end
	return terrain.cost[UnitData.Classes[unit.class].moveType]
end

-- Dijkstra: alle erreichbaren Felder. Verbündete dürfen durchquert, aber nicht als Ziel gewählt werden;
-- Feinde blockieren. Ergebnis: key -> { x, y, cost, prev, canStop }
function Grid.reachable(unit, units, movOverride)
	local mov = movOverride or unit.mov or UnitData.Classes[unit.class].mov
	if (unit.ai == "stationary" or (unit.ai == "hold_until_hurt" and not unit.awakened and unit.hp == unit.maxHp)) and not movOverride then
		mov = 0
	end

	local occupied = {}
	for _, u in units do
		occupied[Grid.key(u.x, u.y)] = u
	end

	local start = { x = unit.x, y = unit.y, cost = 0, canStop = true }
	local nodes = { [Grid.key(unit.x, unit.y)] = start }
	local open = { start }

	while #open > 0 do
		local bestIndex = 1
		for i = 2, #open do
			if open[i].cost < open[bestIndex].cost then
				bestIndex = i
			end
		end
		local node = table.remove(open, bestIndex)

		if nodes[Grid.key(node.x, node.y)] == node then
			for _, d in DIRS do
				local nx, ny = node.x + d[1], node.y + d[2]
				local cost = Grid.moveCost(unit, nx, ny)
				local k = Grid.key(nx, ny)
				local other = occupied[k]
				if cost and not (other and other.team ~= unit.team) then
					local newCost = node.cost + cost
					local existing = nodes[k]
					if newCost <= mov and (not existing or newCost < existing.cost) then
						local n = {
							x = nx, y = ny, cost = newCost,
							prev = Grid.key(node.x, node.y),
							canStop = other == nil,
						}
						nodes[k] = n
						table.insert(open, n)
					end
				end
			end
		end
	end

	return nodes
end

-- Pfad vom Start zum Ziel als Liste von { x, y } (inklusive Start)
function Grid.pathTo(nodes, x, y)
	local path = {}
	local node = nodes[Grid.key(x, y)]
	while node do
		table.insert(path, 1, { x = node.x, y = node.y })
		node = node.prev and nodes[node.prev]
	end
	return path
end

function Grid.tilesInRange(x, y, minRange, maxRange)
	local out = {}
	for dx = -maxRange, maxRange do
		for dy = -maxRange, maxRange do
			local d = math.abs(dx) + math.abs(dy)
			if d >= minRange and d <= maxRange and Grid.inBounds(x + dx, y + dy) then
				table.insert(out, { x = x + dx, y = y + dy })
			end
		end
	end
	return out
end

-- Für die Anzeige: Bewegungsfelder (blau) und zusätzlich angreifbare Felder (rot)
function Grid.ranges(unit, units, nodes)
	nodes = nodes or Grid.reachable(unit, units)
	local weapon = UnitData.Weapons[unit.weapon]
	local move, attack, seen = {}, {}, {}

	for k, n in nodes do
		seen[k] = true
		if n.canStop then
			table.insert(move, n)
		end
	end
	for _, n in move do
		for _, t in Grid.tilesInRange(n.x, n.y, weapon.minRange, weapon.maxRange) do
			local k = Grid.key(t.x, t.y)
			if not seen[k] then
				seen[k] = true
				table.insert(attack, t)
			end
		end
	end

	return move, attack
end

-- Feinde, die eine Einheit von Feld (x, y) aus angreifen kann
function Grid.targetsFrom(unit, units, x, y)
	local weapon = UnitData.Weapons[unit.weapon]
	local out = {}
	for _, other in units do
		if other.team ~= unit.team then
			local d = Grid.dist(x, y, other.x, other.y)
			if d >= weapon.minRange and d <= weapon.maxRange then
				table.insert(out, other)
			end
		end
	end
	return out
end

return Grid
