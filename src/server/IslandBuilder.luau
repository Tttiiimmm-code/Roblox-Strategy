-- Facetten teilen denselben Umriss wie das Terrain; keine Texturen oder Partikel.
local Config = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared").Config)
local EnvironmentAssets = require(script.Parent.EnvironmentAssets)
local IslandBuilder = {}

local function hash(key)
	local value = 0
	for i = 1, #key do value = (value * 131 + key:byte(i)) % 2147483647 end
	return value
end

local function part(parent, name, size, cf, color, class, material)
	local object = Instance.new(class or "Part")
	object.Name, object.Size, object.CFrame = name, size, cf
	object.Color, object.Material = color, material or Enum.Material.SmoothPlastic
	object.Anchored, object.CanCollide, object.CanTouch, object.CanQuery, object.CastShadow = true, false, false, false, false
	object:SetAttribute("IslandPart", true)
	object.Parent = parent
	return object
end

-- Ein Dreieck wird entlang seiner längsten Seite in zwei rechtwinklige Keile geteilt.
local function triangle(parent, name, a, b, c, color, material)
	local ab, ac, bc = b - a, c - a, c - b
	if ab:Dot(ab) > ac:Dot(ac) and ab:Dot(ab) > bc:Dot(bc) then a, c = c, a
	elseif ac:Dot(ac) > bc:Dot(bc) then a, b = b, a end
	ab, ac, bc = b - a, c - a, c - b
	local cross = ac:Cross(ab)
	if cross.Magnitude < 0.001 then return end
	local right, back = cross.Unit, bc.Unit
	local up = back:Cross(right).Unit
	local height = math.abs(ab:Dot(up))
	local thickness = Config.ISLAND.facetThickness
	for _, data in { { b, right, back, math.abs(ab:Dot(back)) }, { c, right * -1, back * -1, math.abs(ac:Dot(back)) } } do
		if data[4] > 0.001 then
			part(parent, name, Vector3.new(thickness, height, data[4]), CFrame.fromMatrix((a + data[1]) / 2, data[2], up, data[3]), color, "WedgePart", material)
		end
	end
end

local function crystal(parent, center, width, height, color)
	local ring = { Vector3.new(width, 0, 0), Vector3.new(0, 0, width), Vector3.new(-width, 0, 0), Vector3.new(0, 0, -width) }
	local top, bottom = center + Vector3.new(0, height / 2, 0), center - Vector3.new(0, height / 2, 0)
	for index, offset in ring do
		local a, b = center + offset, center + ring[index % #ring + 1]
		triangle(parent, "ThroneCrystal", top, a, b, color, Enum.Material.Neon)
		triangle(parent, "ThroneCrystal", bottom, b, a, color, Enum.Material.Neon)
	end
	triangle(parent, "CrystalGlint", top + Vector3.new(0.04, 0, 0.04), center + Vector3.new(width + 0.04, 0, 0.04),
		center + Vector3.new(width * 0.55 + 0.04, 0, width * 0.45 + 0.04), Color3.fromRGB(255, 255, 255), Enum.Material.Neon)
end

local function shell(parent, points, center, earthDepth, depth, riverCuts)
	local s = Config.ISLAND
	local top = points[1].Y + s.edgeLip
	local earthBottom = points[1].Y - earthDepth
	for index, a in points do
		local b = points[index % #points + 1]
		local delta = b - a
		local inward = Vector3.new(-delta.Z, 0, delta.X).Unit
		local breaks = { 0, delta.Magnitude }
		local cuts = {}
		for _, cut in riverCuts or {} do
			local offset = cut.position - a
			local projected = offset:Dot(delta.Unit)
			if math.abs(offset:Dot(inward)) < s.edgeReserve and projected >= 0 and projected <= delta.Magnitude then
				local lo, hi = math.max(0, projected - cut.width / 2), math.min(delta.Magnitude, projected + cut.width / 2)
				table.insert(breaks, lo); table.insert(breaks, hi)
				table.insert(cuts, { lo, hi })
			end
		end
		table.sort(breaks)
		for segment = 1, #breaks - 1 do
			local lo, hi = breaks[segment], breaks[segment + 1]
			if hi - lo < 0.001 then continue end
			local segmentTop = top
			for _, cut in cuts do
				if (lo + hi) / 2 >= cut[1] and (lo + hi) / 2 <= cut[2] then segmentTop = Config.TERRAIN.W.height - Config.FEEL.waterfallSurfaceClearance end
			end
			local midpoint = a + delta.Unit * ((lo + hi) / 2) + inward * (s.edgeReserve - s.facetThickness)
			part(parent, "IslandEarth", Vector3.new(hi - lo + s.edgeOverlap, segmentTop - earthBottom, s.edgeReserve * 2),
				CFrame.new(midpoint.X, (segmentTop + earthBottom) / 2, midpoint.Z) * CFrame.Angles(0, -math.atan2(delta.Z, delta.X), 0), s.earthColor)
		end
		for layer = 1, #s.layerScales - 1 do
			local function point(v, level)
				local scale = s.layerScales[level]
				return Vector3.new(center.X + (v.X - center.X) * scale,
					earthBottom - (depth - earthDepth) * (level - 1) / (#s.layerScales - 1), center.Z + (v.Z - center.Z) * scale)
			end
			local p, q, r, t = point(a, layer), point(b, layer), point(a, layer + 1), point(b, layer + 1)
			local color = s.stoneColor:Lerp(s.earthColor, layer == 1 and 0.12 or 0)
			triangle(parent, "IslandStone", p, q, r, color)
			triangle(parent, "IslandStone", q, t, r, color)
		end
	end
end

-- Kleine Inseln verwenden nur eine Steinstufe und eine einfache, rasterlose Kappe.
local function satellite(parent, state, center, radius, index)
	local s = Config.ISLAND
	local earth = Config.TILE_SIZE * s.earthTiles * 0.5
	local points = {}
	for _, offset in { Vector3.new(-radius, 0, -radius), Vector3.new(radius, 0, -radius),
		Vector3.new(radius, 0, radius), Vector3.new(-radius, 0, radius) } do table.insert(points, center + offset) end
	local grass = state.palette.colors[state.palette.grass]
	part(parent, "SatelliteTop", Vector3.new(radius * 2, s.facetThickness, radius * 2), CFrame.new(center), grass)
	part(parent, "SatelliteEarth", Vector3.new(radius * 2, earth, radius * 2), CFrame.new(center - Vector3.new(0, earth / 2, 0)), s.earthColor)
	local tip = center - Vector3.new(0, earth + radius * s.satelliteDepthScale, 0)
	for i, a in points do
		triangle(parent, "SatelliteStone", a - Vector3.new(0, earth, 0),
			points[i % #points + 1] - Vector3.new(0, earth, 0), tip, s.stoneColor)
	end
	local accent = s.accents[state.region and state.region.id or "greenland"] or s.accents.greenland
	crystal(parent, tip + Vector3.new(radius * 0.35, s.crystalHeight * 0.25, 0), s.crystalWidth * 0.5, s.crystalHeight * 0.7, accent)
	local trunk = center + Vector3.new(-radius * 0.3, s.satelliteTreeHeight / 2, radius * 0.2)
	local crown = EnvironmentAssets.crownColor(state.key .. ":satellite:" .. index, state.region and state.region.treePalette)
	part(parent, "SatelliteTrunk", Vector3.new(1, s.satelliteTreeHeight, 1), CFrame.new(trunk), s.earthColor)
	part(parent, "SatelliteCrown", Vector3.new(s.satelliteTreeWidth, s.satelliteTreeHeight * 0.65, s.satelliteTreeWidth),
		CFrame.new(trunk + Vector3.new(0, s.satelliteTreeHeight * 0.4, 0)) * CFrame.Angles(0, math.pi / 4, 0), crown)
end

local function skyIslands(board, parent, state, random)
	local s, T = Config.ISLAND, Config.TILE_SIZE
	local center = Vector3.new(state.w / 2, s.cloudHeight, state.h / 2)
	-- Kacheln begrenzen einzelne Teilgroessen; gemeinsam decken sie alle unteren Sichtstrahlen ab.
	local cells = math.ceil(s.cloudReachTiles * T * 2 / s.cloudTileSize)
	local baseParts = cells * cells
	local riverParts = Config.FEEL.waterfallsEnabled and #state.rivers * (2 + Config.FEEL.waterfallFoamCount) or 0
	local remaining = s.partBudget - IslandBuilder.measure(board) - riverParts - baseParts
	local count = math.min(random:NextInteger(s.satelliteCount.min, s.satelliteCount.max), math.floor((remaining - 4) / 28))
	assert(count >= s.satelliteCount.min, "Inselbudget reicht nicht fuer Nebeninseln")
	local phase = random:NextNumber(0, math.pi * 2)
	for index = 1, count do
		local angle = phase + (index - 1) * math.pi * 2 / count
		local distance = math.max(state.w, state.h) / 2 + random:NextNumber(s.satelliteDistanceTiles.min, s.satelliteDistanceTiles.max) * T
		local position = Vector3.new(center.X + math.cos(angle) * distance, random:NextNumber(s.satelliteHeight.min, s.satelliteHeight.max),
			center.Z + math.sin(angle) * distance)
		satellite(parent, state, position, random:NextNumber(s.satelliteRadiusTiles.min, s.satelliteRadiusTiles.max) * T, index)
	end
	board:SetAttribute("IslandSatellites", count)
	for x = 1, cells do for z = 1, cells do
		part(parent, "CloudSea", Vector3.new(s.cloudTileSize, s.cloudThickness, s.cloudTileSize),
			CFrame.new(center + Vector3.new((x - (cells + 1) / 2) * s.cloudTileSize, -s.cloudThickness / 2,
				(z - (cells + 1) / 2) * s.cloudTileSize)), s.cloudColor)
	end end
	local mountainCount = math.min(s.cloudCount, math.floor((s.partBudget - IslandBuilder.measure(board) - riverParts) / 2))
	for index = 1, mountainCount do
		local angle = random:NextNumber(0, math.pi * 2)
		local distance = random:NextNumber(s.cloudInnerTiles * T, s.cloudReachTiles * T * 0.8)
		local width = random:NextNumber(s.cloudWidthTiles.min, s.cloudWidthTiles.max) * T
		local height = random:NextNumber(s.cloudHeightTiles.min, s.cloudHeightTiles.max) * T
		local cf = CFrame.new(center + Vector3.new(math.cos(angle) * distance, height / 2 - s.facetThickness, math.sin(angle) * distance))
			* CFrame.Angles(0, angle, 0)
		local color = s.cloudColor:Lerp(s.horizonColor, distance / (s.cloudReachTiles * T) * 0.3)
		for _, sign in { -1, 1 } do
			part(parent, "CloudMountain", Vector3.new(width, height, width / 2), cf * CFrame.new(0, 0, sign * width / 4)
				* CFrame.Angles(0, sign == 1 and math.pi or 0, 0), color, "WedgePart")
		end
	end
	board:SetAttribute("IslandCloudMountains", mountainCount)
end

function IslandBuilder.measure(board)
	local count, triangles = 0, 0
	for _, object in board:GetDescendants() do
		if object:IsA("BasePart") and object:GetAttribute("IslandPart") then
			count += 1
			triangles += object:IsA("WedgePart") and 8 or 12
		end
	end
	board:SetAttribute("IslandParts", count)
	board:SetAttribute("IslandEstimatedTriangles", triangles)
	return count
end

function IslandBuilder.build(board, state)
	if not state.island then return end
	local s, T = Config.ISLAND, Config.TILE_SIZE
	local folder = Instance.new("Folder")
	folder.Name, folder.Parent = "Island", board
	local center = Vector3.new(state.w / 2, s.surfaceHeight, state.h / 2)
	shell(folder, state.outline, center, s.earthTiles * T, s.depthTiles * T, state.riverCuts)
	local random = Random.new(hash(state.key .. ":island"))
	local count = random:NextInteger(s.crystalCount.min, s.crystalCount.max)
	local accent = s.accents[state.region and state.region.id or "greenland"] or s.accents.greenland
	for index = 1, count do
		local angle = (index - 1) * math.pi * 2 / count + random:NextNumber(-0.3, 0.3)
		local position = center + Vector3.new(math.cos(angle) * state.w * 0.32, -s.depthTiles * T * s.crystalDepth, math.sin(angle) * state.h * 0.32)
		crystal(folder, position, s.crystalWidth, s.crystalHeight, accent)
	end
	board:SetAttribute("IslandCrystals", count)
	skyIslands(board, folder, state, random)
	IslandBuilder.measure(board)
end

return IslandBuilder
