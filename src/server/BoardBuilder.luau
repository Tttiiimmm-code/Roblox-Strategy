-- Baut das Spielfeld aus Parts auf
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)
local Grid = require(Shared.Grid)
local Stages = require(Shared.Stages)
local EnvironmentAssets = require(script.Parent.EnvironmentAssets)

local BoardBuilder = {}
local LandscapeBuilder = require(script.Parent.LandscapeBuilder)

local function deco(props, parent, className)
	local p = Instance.new(className or "Part")
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false -- Klicks sollen das Feld darunter treffen (wirkt nur zusammen mit CanCollide = false)
	p.CanTouch = false
	p.CastShadow = false
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	for k, v in props do
		p[k] = v
	end
	p.Parent = parent
	return p
end

local function hash(key)
	local value = 0
	for i = 1, #key do value = (value * 131 + key:byte(i)) % 2147483647 end
	return value
end

local function imageId(id)
	if not id or id == "" then return nil end
	return tostring(id):match("^%d+$") and "rbxassetid://" .. id or id
end

local function groundTexture(part, face, id, settings)
	id = imageId(id)
	if not id then return end
	local texture = Instance.new("Texture")
	texture.Name = "GroundTexture"
	texture.Face = face
	texture.Texture = id
	texture.StudsPerTileU = settings.studsPerTile
	texture.StudsPerTileV = settings.studsPerTile
	texture.Color3 = part.Color
	texture.Transparency = settings.transparency
	texture.Parent = part
end

local function groundFlecks(ch, x, y, parent, mapKey, color)
	local settings = Config.GROUND_TEXTURES[ch]
	if settings and imageId(settings.top) then return end
	local feel = Config.GROUND_FLECKS
	if not feel.enabled then return end
	-- Karteninhalt nur einmal hashen, statt für jedes Fleckmerkmal erneut.
	local key = tostring(hash(mapKey .. ":" .. Grid.key(x, y))) .. ":ground:"
	local center = Grid.toWorld(x, y)
	local count = 0
	local function random(label)
		return hash(key .. label) % 10000 / 10000
	end
	local function patch(label, width, length, detail)
		if count >= feel.maxPartsPerTile then return end
		-- Umkreis der gedrehten Flecken hält Mitte und Rasterkanten frei.
		local radius = math.sqrt(width * width + length * length) / 2
		local inner = feel.centerClearance + radius
		local outer = Config.TILE_SIZE / 2 - feel.edgeInset - radius
		if inner > outer then return end
		local distance = inner + (outer - inner) * random(label .. ":distance")
		local along = (random(label .. ":along") * 2 - 1) * outer
		local edge = hash(key .. label .. ":edge") % 4
		local offset = edge < 2 and Vector3.new(edge == 0 and -distance or distance, 0, along)
			or Vector3.new(along, 0, edge == 2 and -distance or distance)
		local cf = CFrame.new(center + offset + Vector3.new(0, feel.surfaceOffset + feel.thickness / 2, 0))
			* CFrame.Angles(0, random(label .. ":angle") * math.pi * 2, 0)
		local shade = random(label .. ":shade") < 0.5
		local contrast = ch == "F" and Config.ENVIRONMENT.forest.groundFleckContrast or 1
		local tint = color:Lerp(shade and Color3.fromRGB(0, 0, 0) or Color3.fromRGB(255, 255, 255), (shade and feel.shade or feel.light) * contrast)
		local grass = detail and random(label .. ":kind") < 0.5
		deco({ Name = grass and "GroundGrassFleck" or (detail and "GroundStoneFleck" or "GroundFleck"),
			Size = grass and Vector3.new(width, feel.thickness, length) or Vector3.new(feel.thickness, width, length),
			CFrame = grass and cf or cf * CFrame.Angles(0, 0, math.pi / 2),
			Color = tint, Transparency = feel.transparency, Material = Enum.Material.SmoothPlastic }, parent, grass and "Part" or "WedgePart")
		count += 1
	end
	for i = 1, math.min(feel.patchCount, feel.maxPartsPerTile) do
		local label = tostring(i)
		local width = feel.minSize + (feel.maxSize - feel.minSize) * random(label .. ":width")
		local length = feel.minSize + (feel.maxSize - feel.minSize) * random(label .. ":length")
		patch(label, width, length, false)
	end
	if (ch == "." or ch == "F") and random("detail") < feel.detailChance then
		patch("detail", feel.detailWidth, feel.detailLength, true)
	end
end

local function bridgeAngle(x, y)
	local function charAt(xx, yy)
		return Grid.inBounds(xx, yy) and Grid.getMap()[yy]:sub(xx, xx) or ""
	end
	local left, right = charAt(x - 1, y), charAt(x + 1, y)
	local up, down = charAt(x, y - 1), charAt(x, y + 1)
	if left == "B" or right == "B" then return math.pi / 2 end
	if up == "B" or down == "B" then return 0 end
	if (up == "W" or up == "D" or down == "W" or down == "D") and left ~= "W" and right ~= "W" then return math.pi / 2 end
	return 0
end

local function place(category, base, parent, key, opts)
	opts = table.clone(opts or {})
	opts.parent, opts.key = parent, key
	return EnvironmentAssets.place(category, CFrame.new(base), opts)
end

local bridgeWarning = false
local function buildBridges(parent, mapKey)
	local bridgeTiles, heights, count = {}, {}, 0
	if #EnvironmentAssets.variants("archbridge") == 0 then return bridgeTiles end
	local T, settings = Config.TILE_SIZE, Config.ENVIRONMENT.bridge
	for i, crossing in Grid.bridgeCrossings() do
		local base = math.huge
		for _, bank in crossing.banks do
			local terrain = Grid.terrainAt(bank.x, bank.y)
			if terrain and terrain.cost.foot then base = math.min(base, terrain.height) end
		end
		if base == math.huge then continue end
		local length = crossing.length + 2 * settings.bankOverlap
		local model = place("archbridge", Vector3.new((crossing.x - 0.5) * T, base, (crossing.y - 0.5) * T), parent,
			mapKey .. ":crossing:" .. i, { length = length, rotation = crossing.angle })
		if not model then continue end
		model:SetAttribute("BridgeLength", length * T)
		model:SetAttribute("BridgeAlongX", crossing.alongX)
		local parts = {}
		for _, object in model:GetDescendants() do
			if object:IsA("BasePart") then
				table.insert(parts, object)
				object.CanQuery = true -- Nur während der synchronen Höhenmessung.
				if object:IsA("MeshPart") then pcall(function() object.CollisionFidelity = Enum.CollisionFidelity.PreciseConvexDecomposition end) end
			end
		end
		local box, size = model:GetBoundingBox()
		local params = RaycastParams.new()
		params.FilterType = Enum.RaycastFilterType.Include
		params.FilterDescendantsInstances = { model }
		local top = box.Position.Y + size.Y / 2 + settings.rayMargin
		local drop = size.Y + settings.rayMargin * 2
		local samples, valid = {}, true
		local function sample(cell, required)
			if not Grid.inBounds(cell.x, cell.y) then return end
			local ray = workspace:Raycast(Vector3.new((cell.x - 0.5) * T, top, (cell.y - 0.5) * T), Vector3.new(0, -drop, 0), params)
			if ray then samples[Grid.key(cell.x, cell.y)] = ray.Position.Y
			elseif required then valid = false end
		end
		for _, cell in crossing.cells do sample(cell, true) end
		for _, bank in crossing.banks do
			local terrain = Grid.terrainAt(bank.x, bank.y)
			if terrain and terrain.cost.foot then sample(bank, false) end
		end
		for _, object in parts do object.CanQuery = false end
		if not valid then
			model:Destroy()
			if not bridgeWarning then bridgeWarning = true; warn("Brückenboden nicht messbar; bisherige Part-Brücke als Ersatz") end
			continue
		end
		for key, value in samples do heights[key] = value end
		for _, cell in crossing.cells do bridgeTiles[Grid.key(cell.x, cell.y)] = true end
		count += 1
	end
	Grid.setHeights(heights)
	parent:SetAttribute("BridgeCount", count)
	return bridgeTiles
end

-- Dekoration in den Ecken, damit die Einheit in der Mitte sichtbar bleibt
local function decorate(ch, x, y, parent, mapKey, palette, bridgeTiles, occupied, landscape)
	local center = Grid.toWorld(x, y)
	local c = Config.TILE_SIZE / 2 - Config.ENVIRONMENT.edgeInset
	local key = mapKey .. ":" .. Grid.key(x, y)
	local category = Config.ENVIRONMENT.terrainCategories[ch]
	if ch == "F" then
		if #EnvironmentAssets.variants("tree") > 0 then
			local random = Random.new(hash(key .. ":forest"))
			local settings = Config.ENVIRONMENT.forest
			local range = Config.ENVIRONMENT.treesPerForestTile
			local count = random:NextNumber(0, 1) < settings.secondTreeChance and range.max or range.min
			local startAngle = random:NextNumber(0, math.pi * 2)
			for i = 1, count do
				local angle = startAngle + (i - 1) * math.pi * 2 / count
				local jitter = settings.positionJitter * Config.TILE_SIZE
				local distance = count == 1 and settings.singleTreeOffset * Config.TILE_SIZE or c
				local off = Vector3.new(math.cos(angle) * distance + random:NextNumber(-jitter, jitter), 0,
					math.sin(angle) * distance + random:NextNumber(-jitter, jitter))
				local tree = place("tree", center + off, parent, key .. ":tree:" .. i, {
					palette = palette,
					height = random:NextNumber(settings.treeHeight.min, settings.treeHeight.max),
					crownWidth = random:NextNumber(settings.treeWidth.min, settings.treeWidth.max),
				})
				if tree then tree:SetAttribute("ForestTile", Grid.key(x, y)) end
			end
			if random:NextNumber(0, 1) < settings.understoryChance then
				local limits = table.clone(settings.bush); limits.palette = palette
				place("bush", center + Vector3.new(c, 0, -c), parent, key .. ":understory", limits)
			end
			return
		end
		local settings = Config.ENVIRONMENT.forest
		local random = Random.new(hash(key .. ":forest"))
		local count = random:NextNumber(0, 1) < settings.secondTreeChance and 2 or 1
		local angle = random:NextNumber(0, math.pi * 2)
		for i = 1, count do
			local distance = count == 1 and settings.singleTreeOffset * Config.TILE_SIZE or c
			local direction = angle + (i - 1) * math.pi
			local base = center + Vector3.new(math.cos(direction) * distance, 0, math.sin(direction) * distance)
			local tree = Instance.new("Model")
			tree.Name, tree.Parent = "ForestTreeFallback", parent
			tree:SetAttribute("ForestTile", Grid.key(x, y))
			deco({ Shape = Enum.PartType.Cylinder, Size = Vector3.new(2, 0.6, 0.6),
				CFrame = CFrame.new(base + Vector3.new(0, 1, 0)) * CFrame.Angles(0, 0, math.rad(90)),
				Color = Color3.fromRGB(100, 70, 40), Material = Enum.Material.Wood }, tree)
			-- Kantige Tannensilhouette statt Kugel-Kronen, falls das Paket fehlt.
			for layer = 1, 3 do
				local diameter = 3.2 - layer * 0.5
				deco({ Size = Vector3.new(diameter, 2.2, diameter), Position = base + Vector3.new(0, 1.8 + layer * 0.7, 0),
					Color = Color3.fromRGB(40, 100, 45), Material = Enum.Material.Grass }, tree, "WedgePart")
			end
		end
		if hash(key .. ":bush") % 10000 / 10000 < Config.ENVIRONMENT.bushChance then
			place("bush", center + Vector3.new(c, 0, -c), parent, key .. ":bush", { palette = palette })
		end
	elseif ch == "S" then
		local puddle = center + Vector3.new(((x * 17 + y * 11) % 5 - 2) * 0.5, 0, ((x * 13 + y * 19) % 5 - 2) * 0.5)
		deco({ Name = "SwampPuddle", Size = Vector3.new(Config.FEEL.swampPuddleSize.X, Config.FEEL.groundCapHeight, Config.FEEL.swampPuddleSize.Z),
			Position = puddle + Vector3.new(0, Config.FEEL.swampPuddleSurfaceOffset - Config.FEEL.groundCapHeight / 2, 0),
			Color = Config.TERRAIN.D.color, Material = Enum.Material.SmoothPlastic }, parent)
		for i = 1, 3 + (x + y) % 2 do
			local off = Vector3.new(((x * 17 + y * 11 + i * 7) % 2 == 0 and -1 or 1) * c, 0,
				((x * 13 + y * 19 + i * 5) % 7 / 3 - 1) * c)
			local stalk = CFrame.new(center + off + Vector3.new(0, 0.8, 0)) * CFrame.Angles(math.rad(i * 7), 0, math.rad(80 + i * 4))
			deco({ Shape = Enum.PartType.Cylinder, Size = Vector3.new(1.6, 0.15, 0.15), CFrame = stalk,
				Color = Color3.fromRGB(110, 120, 60), Material = Enum.Material.Grass }, parent)
			deco({ Name = "ReedTip", Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.5, 0.25, 0.25),
				CFrame = stalk * CFrame.new(0.8, 0, 0), Color = Color3.fromRGB(80, 50, 30), Material = Enum.Material.Wood }, parent)
		end
	elseif ch == "D" then
		local waterY = center.Y
		for i = 1, 3 do
			local off = Vector3.new(((x * 7 + y * 3 + i * 5) % 5 - 2) * 0.9, 0, ((x * 5 + y * 11 + i * 3) % 5 - 2) * 0.9)
			deco({ Name = "LilyPad", Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.08, 1.3, 1.3),
				CFrame = CFrame.new(center.X + off.X, waterY + 0.04, center.Z + off.Z) * CFrame.Angles(0, 0, math.rad(90)),
				Color = Color3.fromRGB(70, 120, 55), Material = Enum.Material.SmoothPlastic }, parent)
		end
		for i = 1, 1 + (x + y) % 2 do
			local off = Vector3.new(i == 1 and -c or c, 0.6, ((x * 17 + y * 11) % 3 - 1) * c)
			deco({ Shape = Enum.PartType.Cylinder, Size = Vector3.new(1.6, 0.7, 0.7),
				CFrame = CFrame.new(center + off) * CFrame.Angles(math.rad(15), 0, math.rad(65)),
				Color = Color3.fromRGB(55, 45, 35), Material = Enum.Material.Wood }, parent)
		end
	elseif ch == "M" or ch == "C" then
		local settings = Config.ENVIRONMENT.rocks
		local random = Random.new(hash(key .. ":rocks"))
		local count = ch == "M" and (1 + random:NextInteger(settings.smallCount.min, settings.smallCount.max))
			or random:NextInteger(settings.cliffCount.min, settings.cliffCount.max)
		local corner = Config.TILE_SIZE / 2 - settings.centerEdgeInset
		for i = 1, count do
			local base = center + Vector3.new(i % 2 == 1 and -corner or corner, 0, -corner)
			local limits = ch == "M" and settings.mountain or settings.cliff
			local scale = random:NextNumber(settings.largeScale.min, settings.largeScale.max)
			local asset = place("rock", base, parent, key .. ":rock:" .. i, {
				height = limits.height * scale, width = limits.width * scale, rotationMode = "free",
			})
			if not asset then continue end
			local box, size = asset:GetBoundingBox()
			local surface, valid = math.huge, true
			-- Niedrigste Auflage unter dem Modell: auch auf schrägen Klippen kein Schweben.
			for _, dx in { -1, 0, 1 } do for _, dz in { -1, 0, 1 } do
				local height = LandscapeBuilder.groundHeight(landscape, box.Position.X + dx * size.X / 2, box.Position.Z + dz * size.Z / 2)
				if height then surface = math.min(surface, height) else valid = false end
			end end
			if not valid then asset:Destroy(); continue end
			local offset = surface - settings.surfaceSink - (box.Position.Y - size.Y / 2)
			asset:PivotTo(CFrame.new(0, offset, 0) * asset:GetPivot())
			local material = ch == "M" and landscape.palette.rock or landscape.palette.slate
			for _, part in asset:GetDescendants() do if part:IsA("BasePart") then
				part.Material, part.Color = material, landscape.palette.colors[material]
				part.MaterialVariant = ""
				if part:IsA("MeshPart") then part.TextureID = "" end
				local appearance = part:FindFirstChildOfClass("SurfaceAppearance")
				if appearance then appearance:Destroy() end
			end end
			asset:SetAttribute("TopRockX", x); asset:SetAttribute("TopRockY", y)
			asset:SetAttribute("RockSurface", surface)
		end
	elseif ch == "B" then
		if bridgeTiles[Grid.key(x, y)] then return end
		local angle = bridgeAngle(x, y)
		if place(category, center, parent, key, { rotation = angle }) then return end
		for _, side in { -1, 1 } do
			deco({ Size = Vector3.new(0.4, 1, Config.TILE_SIZE - 0.2),
				CFrame = CFrame.new(center) * CFrame.Angles(0, angle, 0)
					* CFrame.new(side * (Config.TILE_SIZE / 2 - 0.4), 0.5, 0),
				Color = Color3.fromRGB(110, 76, 46), Material = Enum.Material.Wood }, parent)
		end
	elseif ch == "H" then
		for _, off in { Vector3.new(-c, 0, -c), Vector3.new(c, 0, -c), Vector3.new(-c, 0, c), Vector3.new(c, 0, c) } do
			if place(category, center + off, parent, key .. tostring(off)) then continue end
			deco({ Size = Vector3.new(1.2, 3, 1.2), Position = center + off + Vector3.new(0, 1.5, 0),
				Color = Color3.fromRGB(150, 140, 130), Material = Enum.Material.Brick }, parent)
		end
	elseif ch == "." then
		if occupied[Grid.key(x, y)] then return end
		local settings = Config.ENVIRONMENT.meadow
		local random = Random.new(hash(key .. ":meadow"))
		if random:NextNumber(0, 1) >= settings.chance then return end
		local corner = random:NextInteger(0, 3)
		local function meadow(kind, index)
			local edge = (corner + index) % 4
			local base = center + Vector3.new(edge < 2 and -c or c, 0, edge % 2 == 0 and -c or c)
			local asset = place(kind, base, parent, key .. ":meadow:" .. kind .. ":" .. index)
			if not asset and kind == "deco_grass" then
				local size = Config.ENVIRONMENT.categories.deco_grass
				asset = deco({ Name = "MeadowGrass", Size = Vector3.new(size.width, size.height, size.width) * Config.TILE_SIZE,
					Position = base + Vector3.new(0, size.height * Config.TILE_SIZE / 2, 0),
					Color = Config.FEEL.grassColor, Material = Enum.Material.Grass }, parent, "WedgePart")
			end
			if asset then asset:SetAttribute("MeadowTile", Grid.key(x, y)); asset:SetAttribute("MeadowKind", kind) end
		end
		for i = 1, random:NextInteger(settings.grassCount.min, settings.grassCount.max) do meadow("deco_grass", i) end
		if random:NextNumber(0, 1) < settings.flowerChance then meadow("deco_flower", 2) end
		if random:NextNumber(0, 1) < settings.stoneChance then meadow("deco_stone", 3) end
		if random:NextNumber(0, 1) < settings.fenceChance then meadow("deco_fence", 0) end
	end
end

local function shoreline(ch, x, y, parent, bridgeTiles)
	local settings, T = Config.FEEL.shore, Config.TILE_SIZE
	if not settings.enabled or (ch ~= "." and ch ~= "F" and ch ~= "S" and ch ~= "H") then return 0 end
	local key = Grid.key(x, y)
	if bridgeTiles[key] or Grid.tileHeight(x, y) ~= Config.TERRAIN[ch].height then return 0 end
	local function char(xx, yy) return Grid.inBounds(xx, yy) and Grid.getMap()[yy]:sub(xx, xx) or "" end
	local function water(xx, yy) local c = char(xx, yy); return c == "W" or c == "D" end
	for _, d in { { 1, 0 }, { -1, 0 }, { 0, 1 }, { 0, -1 } } do if char(x + d[1], y + d[2]) == "B" then return 0 end end
	local center, half, width = Grid.toWorld(x, y), T / 2, T * settings.width
	local count = 0
	-- Sand bleibt vollst?ndig auf Land: keine Scheiben oder optischen Masken im Wasser.
	for _, d in { { 1, 0 }, { -1, 0 }, { 0, 1 }, { 0, -1 } } do
		if not water(x + d[1], y + d[2]) or count >= settings.maxPartsPerTile then continue end
		local horizontal = d[1] ~= 0
		local edge = half - width / 2
		local part = deco({ Name = "ShoreStrip", Shape = Enum.PartType.Block,
			Size = Vector3.new(horizontal and width or T, settings.thickness, horizontal and T or width),
			Position = center + Vector3.new(d[1] * edge, settings.surfaceOffset, d[2] * edge),
			Color = settings.color, Material = Enum.Material.Ground }, parent)
		part:SetAttribute("ShoreX", x); part:SetAttribute("ShoreY", y)
		part:SetAttribute("WaterX", x + d[1]); part:SetAttribute("WaterY", y + d[2])
		count += 1
	end
	return count
end

local function waterfall(feature, parent)
	if not feature or not Config.FEEL.waterfallsEnabled then return end
	local x, y = feature.x, feature.y
	local nx, ny = x + feature.dx, y + feature.dy
	if not Grid.inBounds(x, y) or not Grid.inBounds(nx, ny)
		or Grid.getMap()[y]:sub(x, x) ~= "C" or Grid.getMap()[ny]:sub(nx, nx) ~= "W" then return end
	local feel, T = Config.FEEL, Config.TILE_SIZE
	local top, bottom = Grid.tileHeight(x, y) + feel.waterfallSurfaceClearance, Grid.tileHeight(nx, ny)
	local center = Grid.toWorld(x, y)
	local normal = Vector3.new(feature.dx, 0, feature.dy)
	local along = Vector3.new(-feature.dy, 0, feature.dx)
	local edge = center + normal * (T / 2 + feel.waterfallThickness / 2)
	local width = T * feel.waterfallWidth
	local horizontal = feature.dx ~= 0
	local length = T + feel.waterfallThickness
	deco({ Name = "WaterfallSource", Size = Vector3.new(horizontal and length or width, feel.waterfallThickness, horizontal and width or length),
		Position = Vector3.new(center.X, top + feel.waterfallThickness / 2, center.Z) + normal * (feel.waterfallThickness / 2), Color = feel.waterfallColor,
		Transparency = feel.waterfallTransparency, Material = Enum.Material.SmoothPlastic }, parent)
	deco({ Name = "Waterfall", Size = Vector3.new(horizontal and feel.waterfallThickness or width, top + feel.waterfallThickness - bottom, horizontal and width or feel.waterfallThickness),
		Position = Vector3.new(edge.X, (top + feel.waterfallThickness + bottom) / 2, edge.Z), Color = feel.waterfallColor,
		Transparency = feel.waterfallTransparency, Material = Enum.Material.SmoothPlastic }, parent)
	for i = 1, feel.waterfallFoamCount do
		local offset = (i - (feel.waterfallFoamCount + 1) / 2) * width / feel.waterfallFoamCount
		deco({ Name = "WaterfallFoam", Shape = Enum.PartType.Ball,
			Size = Vector3.new(feel.waterfallFoamSize * 2, feel.waterfallFoamSize, feel.waterfallFoamSize * 2),
			Position = Vector3.new(edge.X, bottom + feel.waterfallFoamSize / 2, edge.Z) + along * offset + normal * feel.waterfallFoamSize,
			Color = feel.waterfallFoamColor, Material = Enum.Material.SmoothPlastic }, parent)
	end
end

-- Einmal anlegen und behalten: Clients halten eine Referenz auf diesen Ordner
function BoardBuilder.ensureUnitsFolder()
	local units = workspace:FindFirstChild("Units")
	if not units then
		units = Instance.new("Folder")
		units.Name = "Units"
		units.Parent = workspace
	end
	return units
end

-- Baut die aktuelle Karte aus Grid.getMap() (vorher Grid.setMap aufrufen)
function BoardBuilder.build(regionId, features, stage)
	Grid.setHeights({})
	local region = Stages.getRegion(regionId)
	for _, name in { "Baseplate", "SpawnLocation", "Board" } do
		local old = workspace:FindFirstChild(name)
		if old then old:Destroy() end
	end
	local mapKey = (regionId or "") .. ":" .. table.concat(Grid.getMap(), "|")
	local T = Config.TILE_SIZE
	local board = Instance.new("Folder")
	board.Name = "Board"
	board.Parent = workspace
	local bridgeTiles = buildBridges(board, mapKey)
	local occupied = {}
	for _, cells in { stage and stage.slots or {}, stage and stage.enemies or {} } do
		for _, cell in cells do occupied[Grid.key(cell.x, cell.y)] = true end
	end

	local ground = Instance.new("Folder")
	ground.Name = "Ground"
	ground.Parent = board
	local function colorFor(ch)
		local terrain = Config.TERRAIN[ch]
		local palette = region and region.landscape or Config.LANDSCAPE.palette
		local color = (region and region.terrainColors and region.terrainColors[ch])
			or (terrain.paletteKey and palette.colors[palette[terrain.paletteKey]]) or terrain.color
		local correction = region and region.groundColors or Config.GROUND_COLORS
		if terrain.paletteKey == "grass" then
			color = color:Lerp(Color3.fromRGB(255, 255, 255), correction.grassLighten)
		elseif terrain.material == Enum.Material.Ground then
			color = color:Lerp(Color3.fromRGB(255, 255, 255), correction.groundLighten)
		end
		return ch == "F" and color:Lerp(Color3.fromRGB(0, 0, 0), Config.ENVIRONMENT.forest.groundShade) or color
	end
	local landscape = LandscapeBuilder.build(board, mapKey, region, features)
	local heights = Grid.getHeights()
	for y, row in Grid.getMap() do for x = 1, #row do
		if row:sub(x, x) ~= "M" then continue end
		local height = LandscapeBuilder.groundHeight(landscape, (x - 0.5) * T, (y - 0.5) * T)
		if height then heights[Grid.key(x, y)] = height end
	end end
	Grid.setHeights(heights)
	-- Gleiche Zeichen bilden einfache Rechtecke statt eines sichtbaren Blocks pro Feld.
	local used, groundCount = {}, 0
	local shoreCount = 0
	for y = 1, Grid.height() do
		for x = 1, Grid.width() do
			local key = Grid.key(x, y)
			local fieldCh = Grid.getMap()[y]:sub(x, x)
			if fieldCh == "M" or fieldCh == "C" or fieldCh == "W" or (fieldCh == "B" and bridgeTiles[key]) then continue end
			if used[key] then continue end
			local ch = Grid.getMap()[y]:sub(x, x)
			local right = x
			while right < Grid.width() and not used[Grid.key(right + 1, y)] and Grid.getMap()[y]:sub(right + 1, right + 1) == ch do right += 1 end
			local bottom = y
			while bottom < Grid.height() do
				local same = true
				for xx = x, right do
					if used[Grid.key(xx, bottom + 1)] or Grid.getMap()[bottom + 1]:sub(xx, xx) ~= ch then same = false; break end
				end
				if not same then break end
				bottom += 1
			end
			for yy = y, bottom do for xx = x, right do used[Grid.key(xx, yy)] = true end end
			groundCount += 1
			local groundCh = ch == "B" and bridgeTiles[key] and "W" or ch
			local height = Config.TERRAIN[groundCh].height
			local cap = Config.FEEL.groundCapHeight
			local color = colorFor(groundCh)
			local cx, cz = (x + right - 1) * T / 2, (y + bottom - 1) * T / 2
			local width, length = (right - x + 1) * T, (bottom - y + 1) * T
			local side = deco({ Name = "Side_" .. groundCount, Size = Vector3.new(width, Config.FEEL.groundDepth + height - cap, length),
				Position = Vector3.new(cx, (height - cap - Config.FEEL.groundDepth) / 2, cz),
				Color = color:Lerp(Color3.fromRGB(0, 0, 0), Config.FEEL.groundSideShade),
				Material = Config.TERRAIN[groundCh].material }, ground)
			local surface = deco({ Name = "Ground_" .. groundCount, Size = Vector3.new(width, cap, length),
				Position = Vector3.new(cx, height - cap / 2, cz), Color = color,
				Transparency = (groundCh == "W" or groundCh == "D") and Config.FEEL.waterTransparency or 0,
				Material = (groundCh == "." or groundCh == "F") and landscape.palette.grass or Config.TERRAIN[groundCh].material }, ground)
			local textures = Config.GROUND_TEXTURES[groundCh]
			if textures then
				groundTexture(surface, Enum.NormalId.Top, textures.top, textures)
				for _, face in { Enum.NormalId.Front, Enum.NormalId.Back, Enum.NormalId.Left, Enum.NormalId.Right } do
					groundTexture(side, face, textures.side, textures)
					groundTexture(surface, face, textures.side, textures)
				end
			end
		end
	end
	board:SetAttribute("GroundCount", groundCount)
	board:SetAttribute("MapKey", table.concat(Grid.getMap(), "|"))

	for y = 1, Grid.height() do
		for x = 1, Grid.width() do
			local ch = string.sub(Grid.getMap()[y], x, x)
			local terrain = Config.TERRAIN[ch]

			shoreCount += shoreline(ch, x, y, ground, bridgeTiles)
			local tile = Instance.new("Part")
			tile.Name = ("Tile_%d_%d"):format(x, y)
			tile.Anchored = true
			tile.Size = Vector3.new(T, 0.2, T)
			tile.Position = Grid.toWorld(x, y) - Vector3.new(0, 0.1, 0)
			tile.Transparency = 1
			tile.CanCollide = false
			tile.CanQuery = true
			tile.CanTouch = false
			tile.CastShadow = false
			tile.Color = terrain.color
			tile.Material = terrain.material
			tile.TopSurface = Enum.SurfaceType.Smooth
			tile:SetAttribute("X", x)
			tile:SetAttribute("Y", y)
			tile.Parent = board
			if ch ~= "M" and ch ~= "C" and not bridgeTiles[Grid.key(x, y)] and not occupied[Grid.key(x, y)] then groundFlecks(ch, x, y, ground, mapKey, colorFor(ch)) end
			decorate(ch, x, y, board, mapKey, region and region.treePalette, bridgeTiles, occupied, landscape)
			local center = Grid.toWorld(x, y)
			local offsets = { Vector3.new(-T / 2, 0, 0), Vector3.new(0, 0, -T / 2) }
			-- Gemeinsame Kanten nur einmal; an Höhenstufen bleibt jede Oberkante sichtbar.
			if x == Grid.width() or Grid.tileHeight(x + 1, y) ~= center.Y then table.insert(offsets, Vector3.new(T / 2, 0, 0)) end
			if y == Grid.height() or Grid.tileHeight(x, y + 1) ~= center.Y then table.insert(offsets, Vector3.new(0, 0, T / 2)) end
			for _, offset in offsets do
				deco({ Name = "GridLine", Size = offset.X ~= 0 and Vector3.new(Config.FEEL.gridLineWidth, Config.FEEL.gridLineWidth, T) or Vector3.new(T, Config.FEEL.gridLineWidth, Config.FEEL.gridLineWidth),
					Position = center + offset + Vector3.new(0, Config.FEEL.gridLineWidth / 2 + Config.FEEL.gridSurfaceOffset, 0),
					Color = colorFor(ch):Lerp(Color3.fromRGB(0, 0, 0), Config.FEEL.gridShade), Transparency = Config.FEEL.gridTransparency,
					Material = Enum.Material.SmoothPlastic }, board)
			end
		end
	end

	board:SetAttribute("ShoreParts", shoreCount)
	waterfall(features and features.waterfall, board)
	board.Parent = workspace
	return board
end

return BoardBuilder
