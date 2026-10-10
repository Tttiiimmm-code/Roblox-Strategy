-- Terrain trägt die Landschaft; Paketmodelle setzen nur wenige Akzente.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)
local Grid = require(Shared.Grid)
local EnvironmentAssets = require(script.Parent.EnvironmentAssets)
local IslandBuilder = require(script.Parent.IslandBuilder)

local LandscapeBuilder = {}
local previous = { rects = {}, top = 0 }

local function hash(key)
	local value = 0
	for i = 1, #key do value = (value * 131 + key:byte(i)) % 2147483647 end
	return value
end

-- Gerade Segmentkanten bleiben für Terrain, Schale und Flussausgänge identisch.
local function outline(w, h, random)
	local points, settings, T = {}, Config.ISLAND, Config.TILE_SIZE
	for side = 1, 4 do
		for index = 0, settings.outlineSteps - 1 do
			local t = index / (settings.outlineSteps - 1)
			local margin = random:NextNumber(settings.rimTiles.min, settings.rimTiles.max) * T
			local x, z
			if side == 1 then x, z = -2 * T + (w + 4 * T) * t, -margin
			elseif side == 2 then x, z = w + margin, -2 * T + (h + 4 * T) * t
			elseif side == 3 then x, z = w + 2 * T - (w + 4 * T) * t, h + margin
			else x, z = -margin, h + 2 * T - (h + 4 * T) * t end
			table.insert(points, Vector3.new(x, settings.surfaceHeight, z))
		end
	end
	return points
end

function LandscapeBuilder.contains(state, x, z)
	if not state.island then return true end
	local inside = false
	for i, a in state.outline do
		local b = state.outline[i % #state.outline + 1]
		if (a.Z > z) ~= (b.Z > z) and x < (b.X - a.X) * (z - a.Z) / (b.Z - a.Z) + a.X then inside = not inside end
	end
	return inside
end

local function smooth(value)
	value = math.clamp(value, 0, 1)
	return value * value * (3 - 2 * value)
end

local function aligned(value, up)
	local resolution = Config.LANDSCAPE.resolution
	return (up and math.ceil(value / resolution) or math.floor(value / resolution)) * resolution
end

-- Auch große Sichtflächen dürfen das räumlich getrennte Hub-Terrain nie berühren.
local function withoutHub(rect)
	local s, hub = Config.LANDSCAPE, Config.HUB_ORIGIN
	local x0, x1 = aligned(hub.X - s.hubHalfWidth), aligned(hub.X + s.hubHalfWidth, true)
	local z0, z1 = aligned(hub.Z - s.hubHalfDepth), aligned(hub.Z + s.hubHalfDepth, true)
	if rect.x1 <= x0 or rect.x0 >= x1 or rect.z1 <= z0 or rect.z0 >= z1 then return { rect } end
	local result = {}
	local function add(a, b, c, d)
		if b > a and d > c then table.insert(result, { x0 = a, x1 = b, z0 = c, z1 = d }) end
	end
	add(rect.x0, math.max(rect.x0, x0), rect.z0, rect.z1)
	add(math.min(rect.x1, x1), rect.x1, rect.z0, rect.z1)
	add(math.max(rect.x0, x0), math.min(rect.x1, x1), rect.z0, math.max(rect.z0, z0))
	add(math.max(rect.x0, x0), math.min(rect.x1, x1), math.min(rect.z1, z1), rect.z1)
	return result
end

local function fill(rect, bottom, top, material, stats)
	if top <= bottom then return end
	workspace.Terrain:FillBlock(CFrame.new((rect.x0 + rect.x1) / 2, (bottom + top) / 2, (rect.z0 + rect.z1) / 2),
		Vector3.new(rect.x1 - rect.x0, top - bottom, rect.z1 - rect.z0), material)
	stats.calls += 1
	local volume = (rect.x1 - rect.x0) * (top - bottom) * (rect.z1 - rect.z0)
	if material == Enum.Material.Air then
		stats.clearVolume += volume
		stats.clearCalls += 1
	else stats.volume += volume end
end

function LandscapeBuilder.prepare(mapKey, region, features)
	local s, T = Config.LANDSCAPE, Config.TILE_SIZE
	local w, h = Grid.width() * T, Grid.height() * T
	local margin = aligned(Config.ISLAND.enabled and Config.ISLAND.rimTiles.max * T + Config.ISLAND.edgeReserve or Config.landscapeMargin(Vector3.new(w, 0, h)), true)
	local random = Random.new(hash(mapKey .. ":landscape"))
	local state = { w = w, h = h, region = region, key = mapKey, waterfall = features and features.waterfall, phase = random:NextNumber(0, math.pi * 2),
		margin = margin, sculptMargin = math.min(margin, aligned(s.sculptDistance * T, true)),
		palette = region and region.landscape or s.palette }
	state.island = Config.ISLAND.enabled
	if state.island then
		state.outline = outline(w, h, random)
		state.sculptMargin = margin
		-- Eigene Palette: Tal, Brettfarben und die Gebietsdaten bleiben unverändert.
		state.palette = table.clone(state.palette)
		state.palette.colors = table.clone(state.palette.colors)
		local grass = region and region.terrainColors and region.terrainColors["."] or Config.TERRAIN["."].color
		local rim = state.palette.colors[state.palette.grass]
		local bright = Color3.fromRGB(math.max(rim.R, grass.R) * 255, math.max(rim.G, grass.G) * 255, math.max(rim.B, grass.B) * 255)
		state.palette.colors[state.palette.grass] = bright:Lerp(Color3.fromRGB(255, 255, 255), Config.ISLAND.rimBrighten)
	end
	state.rivers = {}
	local water = region and region.water or Config.WATER
	if water.extendRivers then
		for y, row in Grid.getMap() do for x = 1, #row do
			local ch = row:sub(x, x)
			if ch ~= "W" and ch ~= "B" then continue end
			for _, d in { { -1, 0 }, { 1, 0 }, { 0, -1 }, { 0, 1 } } do
				if Grid.inBounds(x + d[1], y + d[2]) then continue end
				table.insert(state.rivers, { x = (x - 0.5) * T + d[1] * T / 2, z = (y - 0.5) * T + d[2] * T / 2, dx = d[1], dz = d[2] })
			end
		end end
	end
	state.rects = withoutHub({ x0 = -margin, x1 = w + margin, z0 = -margin, z1 = h + margin })
	return state
end

-- Strahl-/Segment-Schnitt: dieselbe Polygonkante begrenzt Terrain und Wasserfall.
function LandscapeBuilder.riverEnd(state, river)
	if not state.island then return nil end
	local nearest
	for index, a in state.outline do
		local b = state.outline[index % #state.outline + 1]
		local ex, ez = b.X - a.X, b.Z - a.Z
		local determinant = river.dx * ez - river.dz * ex
		if math.abs(determinant) < 0.001 then continue end
		local ox, oz = a.X - river.x, a.Z - river.z
		local distance = (ox * ez - oz * ex) / determinant
		local segment = (ox * river.dz - oz * river.dx) / determinant
		if distance >= 0 and segment >= 0 and segment <= 1 and (not nearest or distance < nearest) then nearest = distance end
	end
	return nearest and Vector3.new(river.x + river.dx * nearest, Config.TERRAIN.W.height, river.z + river.dz * nearest)
end

function LandscapeBuilder.surface(state, x, z)
	local s, T = Config.LANDSCAPE, Config.TILE_SIZE
	if x >= 0 and x < state.w and z >= 0 and z < state.h then
		local tx, ty = math.floor(x / T) + 1, math.floor(z / T) + 1
		local ch = Grid.getMap()[ty]:sub(tx, tx)
		if ch == "W" or ch == "B" then return Config.TERRAIN.W.height, Enum.Material.Water end
		if ch ~= "M" and ch ~= "C" then return nil end
		local settings = s.rockFields
		if ch == "M" then
			-- Nur Aussenraender fallen ab; benachbarte M-Felder bilden einen Huegel.
			local edge = T
			for oy = -1, 1 do for ox = -1, 1 do
				local nx, ny = tx + ox, ty + oy
				if Grid.inBounds(nx, ny) and Grid.getMap()[ny]:sub(nx, nx) == "M" then continue end
				local dx = math.max((nx - 1) * T - x, x - nx * T, 0)
				local dz = math.max((ny - 1) * T - z, z - ny * T, 0)
				edge = math.min(edge, math.max(dx, dz))
			end end
			local wave = (math.sin(x / settings.roughnessScale + state.phase) * math.cos(z / settings.roughnessScale - state.phase) + 1) / 2
			local peak = settings.mountainHeight + wave * settings.mountainRoughness
			return settings.mountainEdgeHeight + (peak - settings.mountainEdgeHeight) * smooth(edge / settings.edgeFalloff),
				wave < settings.grassChance and state.palette.grass or state.palette.rock,
				settings.edgeDensity + (1 - settings.edgeDensity) * smooth((edge - T / 4) / settings.edgeFalloff)
		end
		local wave = (math.sin(x / settings.cliffScale + state.phase) * math.sin(z / settings.cliffScale - state.phase) + 1) / 2
		local height = Config.TERRAIN.C.height + wave * settings.cliffRoughness
		local fall = state.waterfall
		if fall then
			local fx, fz = (fall.x - 0.5) * T, (fall.y - 0.5) * T
			local longitudinal = (x - fx) * fall.dx + (z - fz) * fall.dy
			local lateral = math.abs((x - fx) * fall.dy - (z - fz) * fall.dx)
			-- Reserve auch im stromaufwärtigen/seitlichen C-Nachbarvoxel gegen Glättung.
			if longitudinal >= -T / 2 - s.resolution and longitudinal <= T / 2 + s.resolution
				and lateral <= T * Config.FEEL.waterfallWidth / 2 + s.resolution then height = Config.TERRAIN.C.height - Config.FEEL.waterfallChannelDepth end
		end
		return height - (s.cliffWalls.enabled and s.cliffWalls.terrainInset or 0), state.palette.slate
	end
	if state.island and not LandscapeBuilder.contains(state, x, z) then return nil end
	local water = state.region and state.region.water or Config.WATER
	for _, river in state.rivers do
		local along = (x - river.x) * river.dx + (z - river.z) * river.dz
		local across = math.abs((x - river.x) * river.dz - (z - river.z) * river.dx)
		local length = math.min(water.extensionTiles * T, state.sculptMargin - T)
		local width = T * water.extensionWidth * (state.island and 1 or math.sqrt(math.clamp((length - along) / T, 0, 1)))
		if along >= 0 and (state.island or along < length) and across < width then return Config.TERRAIN.W.height, Enum.Material.Water end
	end
	if state.island then return Config.ISLAND.surfaceHeight, state.palette.grass end
	local dx = math.max(-x, x - state.w, 0)
	local dz = math.max(-z, z - state.h, 0)
	local distance = math.sqrt(dx * dx + dz * dz)
	local rim = s.rimWidth * T
	local rise = smooth((distance - rim) / (s.hillRise * T))
	local front = smooth((state.h - z) / (s.frontTransition * T))
	local phase = state.phase
	local broad = (math.sin(x / s.broadScale + phase) * math.cos(z / s.broadScale - phase) + 1) / 2
	local detail = (math.sin(x / s.detailScale - phase) * math.sin(z / s.detailScale + phase) + 1) / 2
	local mountain = smooth((distance - s.mountainStart * T) / (s.mountainRise * T))
	local height = Config.FEEL.surroundHeight + rise * front
		* (s.hillHeight * (s.valleyFloor + broad * (1 - s.valleyFloor)) + mountain * s.mountainHeight * detail)
	-- Vorne bleibt die Grundausrichtung flach; der Horizont ist in der Welt verankert.
	height = math.min(height, Config.FEEL.surroundHeight + (front == 0 and s.frontMaxHeight or s.hillHeight + s.mountainHeight))
	local fade = smooth((state.sculptMargin - distance) / (s.edgeFade * T))
	height = s.foundationTop + (height - s.foundationTop) * fade
	local material = height > s.rockHeight and (detail > s.slateThreshold and state.palette.slate or state.palette.rock)
		or (broad < s.groundThreshold and state.palette.ground or state.palette.grass)
	return height, material
end

-- Detailunterkante auf dem von Roblox gerenderten Terrain, nicht nur der Sollhöhe.
function LandscapeBuilder.groundHeight(state, x, z)
	local height = LandscapeBuilder.surface(state, x, z)
	if not height then return nil end
	local reserve = Config.LANDSCAPE.resolution
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Include
	params.FilterDescendantsInstances = { workspace.Terrain }
	local rocks = Config.LANDSCAPE.rockFields
	local top = math.max(height, rocks.mountainHeight + rocks.mountainRoughness, Config.TERRAIN.C.height + rocks.cliffRoughness) + reserve
	local hit = workspace:Raycast(Vector3.new(x, top, z), Vector3.new(0, -Config.FEEL.terrainDepth - top - reserve, 0), params)
	return hit and hit.Position.Y
end

local function writeSurface(state, rect, stats)
	local s, R = Config.LANDSCAPE, Config.LANDSCAPE.resolution
	local chunk = s.chunkCells * R
	for x0 = rect.x0, rect.x1 - R, chunk do for z0 = rect.z0, rect.z1 - R, chunk do
		local x1, z1 = math.min(x0 + chunk, rect.x1), math.min(z0 + chunk, rect.z1)
		local nx, nz = (x1 - x0) / R, (z1 - z0) / R
		local heights, kinds, densities, top = {}, {}, {}, s.foundationTop
		for ix = 1, nx do
			heights[ix], kinds[ix], densities[ix] = {}, {}, {}
			for iz = 1, nz do
				local x, z = x0 + (ix - 0.5) * R, z0 + (iz - 0.5) * R
				local height, kind, density = LandscapeBuilder.surface(state, x, z)
				heights[ix][iz], kinds[ix][iz], densities[ix][iz] = height, kind, density
				top = math.max(top, height or s.foundationTop)
				if not state.island and (x < 0 or x >= state.w or z < 0 or z >= state.h) then
					-- Der Nahblock ersetzt diesen Teil des bereits gezählten Fernbodens.
					stats.volume -= (s.foundationTop + Config.FEEL.terrainDepth) * R * R
				end
			end
		end
		top = aligned(top, true) + R -- Luft über jeder Oberfläche ist Teil desselben Schreibblocks.
		-- Die Insel braucht nur eine dünne Terrainkappe; darunter liegt die facettierte Schale.
		local bottom = state.island and aligned(Config.ISLAND.surfaceHeight - Config.ISLAND.earthTiles * Config.TILE_SIZE + R, true)
			or -Config.FEEL.terrainDepth
		local ny = (top - bottom) / R
		local materials, occupancies = {}, {}
		for ix = 1, nx do
			materials[ix], occupancies[ix] = {}, {}
			for iy = 1, ny do
				materials[ix][iy], occupancies[ix][iy] = {}, {}
				local y = bottom + (iy - 1) * R
				for iz = 1, nz do
					local height = heights[ix][iz]
					local occupancy = height and math.clamp((height - y) / R, 0, 1) or 0
					-- Geringere Randdichte zieht den Mesher innerhalb des M-Felds zurueck.
					if y >= -R and densities[ix][iz] then
						local density = densities[ix][iz]
						-- Unter Null bleibt der Rand frei, damit die Glättung kein Nachbarfeld anhebt.
						if y < 0 then density = math.max(0, (density - s.rockFields.edgeDensity) / (1 - s.rockFields.edgeDensity)) end
						occupancy = math.min(occupancy, density)
					end
					materials[ix][iy][iz] = occupancy > 0 and kinds[ix][iz] or Enum.Material.Air
					occupancies[ix][iy][iz] = occupancy
					stats.volume += occupancy * R ^ 3
				end
			end
		end
		workspace.Terrain:WriteVoxels(Region3.new(Vector3.new(x0, bottom, z0), Vector3.new(x1, top, z1)), R, materials, occupancies)
		stats.calls += 1
		stats.voxelCalls += 1
		stats.voxels += nx * ny * nz
	end end
end

local function bounds(asset)
	local box, size = asset:GetBoundingBox()
	local lo, hi = Vector3.new(math.huge, math.huge, math.huge), Vector3.new(-math.huge, -math.huge, -math.huge)
	for _, dx in { -1, 1 } do for _, dy in { -1, 1 } do for _, dz in { -1, 1 } do
		local p = box:PointToWorldSpace(Vector3.new(dx * size.X / 2, dy * size.Y / 2, dz * size.Z / 2))
		lo = Vector3.new(math.min(lo.X, p.X), math.min(lo.Y, p.Y), math.min(lo.Z, p.Z))
		hi = Vector3.new(math.max(hi.X, p.X), math.max(hi.Y, p.Y), math.max(hi.Z, p.Z))
	end end end
	return lo, hi
end

function LandscapeBuilder.rimFits(state, lo, hi)
	local s = Config.ISLAND.rimPlacement
	local clearance = Config.LANDSCAPE.objectClearance
	if hi.X > -clearance and lo.X < state.w + clearance and hi.Z > -clearance and lo.Z < state.h + clearance then return false end
	if hi.Z > state.h and hi.Y > Config.ISLAND.surfaceHeight + s.frontHeight then return false end
	local hub = Config.HUB_ORIGIN
	if hi.X > hub.X - Config.LANDSCAPE.hubHalfWidth and lo.X < hub.X + Config.LANDSCAPE.hubHalfWidth
		and hi.Z > hub.Z - Config.LANDSCAPE.hubHalfDepth and lo.Z < hub.Z + Config.LANDSCAPE.hubHalfDepth then return false end
	for _, x in { lo.X - s.edgeClearance, hi.X + s.edgeClearance } do
		for _, z in { lo.Z - s.edgeClearance, hi.Z + s.edgeClearance } do
			if not LandscapeBuilder.contains(state, x, z) then return false end
		end
	end
	local water = state.region and state.region.water or Config.WATER
	local function nearChannel(x, z, dx, dz, width)
		local alongMax, acrossMin, acrossMax = -math.huge, math.huge, -math.huge
		for _, px in { lo.X, hi.X } do for _, pz in { lo.Z, hi.Z } do
			alongMax = math.max(alongMax, (px - x) * dx + (pz - z) * dz)
			local across = (px - x) * dz - (pz - z) * dx
			acrossMin, acrossMax = math.min(acrossMin, across), math.max(acrossMax, across)
		end end
		return alongMax >= -s.waterClearance and acrossMin < width + s.waterClearance and acrossMax > -width - s.waterClearance
	end
	for _, river in state.rivers do
		if nearChannel(river.x, river.z, river.dx, river.dz, Config.TILE_SIZE * water.extensionWidth) then return false end
	end
	local fall = state.waterfall
	if fall and nearChannel((fall.x - 0.5) * Config.TILE_SIZE, (fall.y - 0.5) * Config.TILE_SIZE,
		fall.dx, fall.dy, Config.TILE_SIZE * Config.FEEL.waterfallWidth / 2) then return false end
	return true
end

local function rimDetails(state, board)
	local started, s, T = os.clock(), Config.ISLAND, Config.TILE_SIZE
	local random = Random.new(hash(state.key .. ":rim"))
	local occupied, centers, placed, triangles, trees = {}, {}, 0, 0, 0
	local groups = { 0, 0, 0, 0 }
	local function point(edge, along, distance)
		if edge == 1 then return along, -distance end
		if edge == 4 then return along, state.h + distance end
		return edge == 2 and -distance or state.w + distance, along
	end
	local function put(category, x, z, key, group, edge)
		if placed >= s.rimBudget.objects then return nil end
		local height, material = LandscapeBuilder.surface(state, x, z)
		if not height or material == Enum.Material.Water then return nil end
		local center = Vector3.new(x, height, z)
		if not LandscapeBuilder.rimFits(state, center, center) then return nil end
		for _, other in occupied do
			local gap = s.rimPlacement.overlapClearance
			if x + gap > other.lo.X and x - gap < other.hi.X and z + gap > other.lo.Z and z - gap < other.hi.Z then return nil end
		end
		local opts = { parent = board, key = key, sizeVariation = s.rimScatter.sizeVariation }
		local dimensions = s.rimScatter.sizes[category]
		if dimensions then
			opts.height, opts.width, opts.rimSize = dimensions.height, dimensions.width, true
		elseif category == "tree" then
			opts.height, opts.crownWidth, opts.palette = s.tree.height, s.tree.crownWidth, state.region and state.region.treePalette
		elseif category == "bush" then
			opts.height, opts.width = s.bush.height, s.bush.width
		elseif category == "rock" then
			opts.height, opts.width, opts.preferred = s.rimScatter.rockHeight, s.rimScatter.rockWidth, "rock_50"
		elseif category == "rim_barrels" and edge == 4 then
			opts.height, opts.width = s.frontBarrels.height, s.frontBarrels.width
		else
			opts.rotationMode = "quarter"
		end
		local asset = EnvironmentAssets.place(category, CFrame.new(x, height, z), opts)
		if not asset then return nil end
		local lo, hi = bounds(asset)
		local estimate = asset:GetAttribute("EstimatedTriangles") or 0
		if estimate == 0 then estimate = s.rimBudget.estimates[category] or 0 end
		local safe = triangles + estimate <= s.rimBudget.triangles and LandscapeBuilder.rimFits(state, lo, hi)
		if hi.Z > state.h and not s.frontCategories[category] then safe = false end
		for _, other in occupied do
			local gap = s.rimPlacement.overlapClearance
			if hi.X + gap > other.lo.X and lo.X - gap < other.hi.X and hi.Z + gap > other.lo.Z and lo.Z - gap < other.hi.Z then safe = false; break end
		end
		if not safe then asset:Destroy(); return nil end
		asset:SetAttribute("LandscapeDetail", category == "tree" and "tree" or "prop")
		asset:SetAttribute("RimCategory", category)
		asset:SetAttribute("RimGroup", group)
		asset:SetAttribute("RimEdge", edge)
		asset:SetAttribute("EstimatedTriangles", estimate)
		table.insert(occupied, { lo = lo, hi = hi })
		placed += 1; triangles += estimate
		if category == "tree" then trees += 1 end
		return asset
	end
	local sequence = random:NextInteger(1, #s.rimGroups.categories)
	for edge = 1, 4 do
		local limits = edge == 4 and s.rimGroups.front or s.rimGroups.sides
		local count = random:NextInteger(limits.min, limits.max)
		local length = (edge == 1 or edge == 4) and state.w or state.h
		for index = 1, count do
			local categories = edge == 4 and s.rimGroups.frontCategories or s.rimGroups.categories
			local category = edge == 4 and categories[(index - 1) % #categories + 1] or categories[(sequence - 1) % #categories + 1]
			sequence += 1
			local group = edge .. ":" .. index
			local companions = random:NextInteger(s.rimGroups.companions.min, s.rimGroups.companions.max)
			for placement = 1, s.rimPlacement.attempts do
				local along = length * index / (count + 1) + random:NextNumber(-s.rimPlacement.jitter, s.rimPlacement.jitter) * T
				if placement > s.rimPlacement.attempts / 2 then along = random:NextNumber(0, length) end
				local distance = random:NextNumber(s.rimGroups.mainDistance.min, s.rimGroups.mainDistance.max)
				local x, z = point(edge, along, distance * T)
				local before, beforeTriangles = placed, triangles
				if not put(category, x, z, state.key .. ":rim:main:" .. group, group, edge) then continue end
				for companion = 1, companions do
					local kind = s.rimGroups.companionCategories[(companion - 1) % #s.rimGroups.companionCategories + 1]
					for attempt = 1, s.rimPlacement.attempts do
						local offset = random:NextNumber(-s.rimGroups.radius, s.rimGroups.radius) * T
						local depth = random:NextNumber(-s.rimGroups.depthSpread, s.rimGroups.depthSpread) * T
						local px = x + ((edge == 1 or edge == 4) and offset or depth)
						local pz = z + ((edge == 1 or edge == 4) and depth or offset)
						if put(kind, px, pz, state.key .. ":rim:companion:" .. group .. ":" .. companion, group, edge) then break end
					end
				end
				if placed - before >= s.rimGroups.companions.min + 1 then
					table.insert(centers, { x = x, z = z, edge = edge })
					groups[edge] += 1
					break
				end
				-- Unvollständige Szenen verlegen, statt einzelne Hauptobjekte zurückzulassen.
				for _, asset in board:GetChildren() do if asset:GetAttribute("RimGroup") == group then asset:Destroy() end end
				while #occupied > before do table.remove(occupied) end
				placed, triangles = before, beforeTriangles
			end
		end
	end
	-- Bäume nutzen verbleibende Hinter-/Seitenplätze, bevor die flache Streuung auffüllt.
	for group = 1, s.clusterCount do
		local edge = group % 3 + 1
		local length = edge == 1 and state.w or state.h
		for index = 1, s.clusterSize do
			local category = index == s.clusterSize and "bush" or "tree"
			if category == "tree" and trees >= s.maxTrees then continue end
			for attempt = 1, s.rimPlacement.attempts do
				local x, z = point(edge, random:NextNumber(0, length), random:NextNumber(s.clusterDistance.min, s.clusterDistance.max) * T)
				if put(category, x, z, state.key .. ":rim:tree:" .. group .. ":" .. index, nil, edge) then break end
			end
		end
	end
	local rimArea = 2 * (state.w + state.h) / T * s.rimTiles.min + 4 * s.rimTiles.min ^ 2
	local count = math.min(s.rimScatter.count, math.ceil(rimArea * s.rimScatter.objectsPerTile), s.rimBudget.objects - placed)
	for index = 1, count do
		local category = s.rimScatter.categories[(index - 1) % #s.rimScatter.categories + 1]
		for attempt = 1, s.rimPlacement.attempts do
			local edge = random:NextInteger(1, 4)
			local length = (edge == 1 or edge == 4) and state.w or state.h
			local along = random:NextNumber(0, length)
			local outer = s.rimTiles.min - s.rimPlacement.scatterDistance.inset
			local distance = random:NextNumber(s.rimPlacement.scatterDistance.min, outer)
			if random:NextNumber(0, 1) < s.rimScatter.edgeChance then distance = outer end
			local x, z = point(edge, along, distance * T)
			if #centers > 0 and random:NextNumber(0, 1) < s.rimScatter.clusterChance then
				local center = centers[random:NextInteger(1, #centers)]
				edge = center.edge
				local offset = random:NextNumber(-s.rimGroups.radius, s.rimGroups.radius) * T
				local depth = random:NextNumber(-s.rimGroups.depthSpread, s.rimGroups.depthSpread) * T
				x = center.x + ((edge == 1 or edge == 4) and offset or depth)
				z = center.z + ((edge == 1 or edge == 4) and depth or offset)
			end
			if put(category, x, z, state.key .. ":rim:scatter:" .. index, nil, edge) then break end
		end
	end
	for edge, countGroups in groups do board:SetAttribute("IslandGroups" .. edge, countGroups) end
	board:SetAttribute("LandscapeTrees", trees)
	board:SetAttribute("IslandProps", placed)
	board:SetAttribute("IslandPropEstimatedTriangles", triangles)
	board:SetAttribute("IslandPropBuildMs", (os.clock() - started) * 1000)
end

local function details(state, board)
	if state.island then rimDetails(state, board); return end
	local s, T = Config.LANDSCAPE, Config.TILE_SIZE
	local random = Random.new(hash(state.key .. ":clusters"))
	if state.island then s = setmetatable(table.clone(Config.ISLAND), { __index = s }) end
	local trees = 0
	for group = 1, s.clusterCount do
		local edge = random:NextInteger(1, 3)
		local distance = random:NextNumber(s.clusterDistance.min, s.clusterDistance.max) * T
		local x = edge == 1 and random:NextNumber(-distance, state.w + distance) or (edge == 2 and -distance or state.w + distance)
		local z = edge == 1 and -distance or random:NextNumber(0, math.max(0, state.h - (state.island and 0 or s.frontTransition) * T))
		for index = 1, s.clusterSize do
			local px, pz = x + random:NextNumber(-s.clusterSpread, s.clusterSpread) * T, z + random:NextNumber(-s.clusterSpread, s.clusterSpread) * T
			local height, material = LandscapeBuilder.surface(state, px, pz)
			if material == Enum.Material.Water then continue end
			if not height then continue end
			local kind = index == s.clusterSize and (group % 2 == 0 and "rock" or "bush") or "tree"
			if kind == "tree" and trees >= s.maxTrees then continue end
			local options = table.clone(s[kind])
			options.parent, options.key, options.palette = board, state.key .. ":landscape:" .. group .. ":" .. index, state.region and state.region.treePalette
			local asset = EnvironmentAssets.place(kind, CFrame.new(px, height - s.rootSink, pz), options)
			if not asset then continue end -- Ohne Paket bleibt das Terrain die vollständige Landschaft.
			local lo, hi = bounds(asset)
			local hub = Config.HUB_ORIGIN
			local boardOverlap = hi.X > -s.objectClearance and lo.X < state.w + s.objectClearance
				and hi.Z > -s.objectClearance and lo.Z < state.h + s.objectClearance
			local hubOverlap = hi.X > hub.X - s.hubHalfWidth and lo.X < hub.X + s.hubHalfWidth
				and hi.Z > hub.Z - s.hubHalfDepth and lo.Z < hub.Z + s.hubHalfDepth
			if state.island and not LandscapeBuilder.rimFits(state, lo, hi) then asset:Destroy(); continue end
			if boardOverlap or hubOverlap or (hi.Z >= state.h and hi.Y > Config.FEEL.surroundHeight + s.frontMaxHeight) then asset:Destroy(); continue end
			asset:SetAttribute("LandscapeDetail", kind)
			if kind == "tree" then trees += 1 end
		end
	end
	board:SetAttribute("LandscapeTrees", trees)
end

function LandscapeBuilder.build(board, mapKey, region, features)
	local s = Config.LANDSCAPE
	local stats = { calls = 0, clearCalls = 0, voxelCalls = 0, volume = 0, clearVolume = 0, voxels = 0 }
	local state = LandscapeBuilder.prepare(mapKey, region, features)
	local clearTop = aligned(math.max(Config.FEEL.terrainClearTop, s.hillHeight + s.mountainHeight + s.resolution), true)
	for _, rect in previous.rects do fill(rect, -Config.FEEL.terrainDepth, math.max(previous.top, clearTop), Enum.Material.Air, stats) end
	for _, rect in state.rects do fill(rect, -Config.FEEL.terrainDepth, clearTop, Enum.Material.Air, stats) end
	previous = { rects = state.rects, top = clearTop }
	local water = region and region.water or Config.WATER
	workspace.Terrain.WaterColor = water.color
	workspace.Terrain.WaterTransparency = water.transparency
	workspace.Terrain.WaterReflectance = water.reflectance
	workspace.Terrain.WaterWaveSize = water.waveSize
	workspace.Terrain.WaterWaveSpeed = water.waveSpeed
	for material, color in state.palette.colors do workspace.Terrain:SetMaterialColor(material, color) end
	-- Fernboden in wenigen großen Blöcken; das Brett selbst bleibt frei.
	if not state.island then
	for _, rect in {
		{ x0 = -state.margin, x1 = 0, z0 = -state.margin, z1 = state.h + state.margin },
		{ x0 = state.w, x1 = state.w + state.margin, z0 = -state.margin, z1 = state.h + state.margin },
		{ x0 = 0, x1 = state.w, z0 = -state.margin, z1 = 0 },
		{ x0 = 0, x1 = state.w, z0 = state.h, z1 = state.h + state.margin },
	} do
		for _, safe in withoutHub(rect) do fill(safe, -Config.FEEL.terrainDepth, s.foundationTop, state.palette.grass, stats) end
	end
	end
	for _, rect in withoutHub({ x0 = -state.sculptMargin, x1 = state.w + state.sculptMargin, z0 = -state.sculptMargin, z1 = state.h + state.sculptMargin }) do
		writeSurface(state, rect, stats)
	end
	details(state, board)
	if state.island then
		state.riverCuts = {}
		for _, river in state.rivers do
			local position = LandscapeBuilder.riverEnd(state, river)
			if position then table.insert(state.riverCuts, { position = position, width = Config.TILE_SIZE * water.extensionWidth * 2 }) end
		end
	end
	IslandBuilder.build(board, state)
	board:SetAttribute("IslandEnabled", state.island)
	board:SetAttribute("TerrainWriteCalls", stats.calls)
	board:SetAttribute("TerrainClearCalls", stats.clearCalls)
	board:SetAttribute("TerrainVoxelCalls", stats.voxelCalls)
	board:SetAttribute("TerrainVolume", stats.volume)
	board:SetAttribute("TerrainClearVolume", stats.clearVolume)
	board:SetAttribute("TerrainVoxels", stats.voxels)
	return state
end

return LandscapeBuilder
