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

local function shell(parent, points, center, depth, riverCuts)
	local s = Config.ISLAND
	local top = points[1].Y + s.edgeLip
	local earthBottom = points[1].Y - s.cliffEarthTiles * Config.TILE_SIZE
	local stoneBottom = earthBottom - s.cliffStoneTiles * Config.TILE_SIZE
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
			part(parent, "IslandCliffStone", Vector3.new(hi - lo + s.edgeOverlap, earthBottom - stoneBottom, s.edgeReserve * 2),
				CFrame.new(midpoint.X, (earthBottom + stoneBottom) / 2, midpoint.Z) * CFrame.Angles(0, -math.atan2(delta.Z, delta.X), 0), s.stoneColor)
		end
		for layer = 1, #s.layerScales - 1 do
			local function point(v, level)
				local scale = s.layerScales[level]
				return Vector3.new(center.X + (v.X - center.X) * scale,
					stoneBottom - (depth + stoneBottom - points[1].Y) * (level - 1) / (#s.layerScales - 1), center.Z + (v.Z - center.Z) * scale)
			end
			local p, q, r, t = point(a, layer), point(b, layer), point(a, layer + 1), point(b, layer + 1)
			local color = s.stoneColor:Lerp(s.earthColor, layer == 1 and 0.12 or 0)
			triangle(parent, "IslandStone", p, q, r, color)
			triangle(parent, "IslandStone", q, t, r, color)
		end
	end
end

-- Kleine Polygoninseln teilen Kappe, kurze Wand und Spitze; die Wolken verdecken den unteren Teil.
local function satellite(parent, state, center, radius, index, random)
	local s = Config.ISLAND
	local folder = Instance.new("Folder")
	folder.Name, folder.Parent = "Satellite_" .. index, parent
	folder:SetAttribute("Satellite", true)
	folder:SetAttribute("OutlinePoints", s.satelliteOutlinePoints)
	folder:SetAttribute("CenterX", center.X)
	folder:SetAttribute("CenterZ", center.Z)
	folder:SetAttribute("SurfaceHeight", center.Y)
	parent = folder
	local earth = Config.TILE_SIZE * s.satelliteEarthTiles
	local points = {}
	local phase = random:NextNumber(0, math.pi * 2)
	for i = 1, s.satelliteOutlinePoints do
		local angle = phase + (i - 1) * math.pi * 2 / s.satelliteOutlinePoints
		local r = radius * random:NextNumber(s.satelliteOutlineRadius.min, s.satelliteOutlineRadius.max)
		table.insert(points, center + Vector3.new(math.cos(angle) * r, 0, math.sin(angle) * r))
	end
	local grass = state.palette.colors[state.palette.grass]
	for i = 2, #points - 1 do triangle(parent, "SatelliteTop", points[1], points[i], points[i + 1], grass) end
	local tip = center - Vector3.new(0, earth + radius * s.satelliteDepthScale, 0)
	for i, a in points do
		local b = points[i % #points + 1]
		local delta = b - a
		local inward = Vector3.new(-delta.Z, 0, delta.X).Unit
		local midpoint = (a + b) / 2 + inward * s.satelliteWallThickness / 2
		part(parent, "SatelliteEarth", Vector3.new(delta.Magnitude + s.edgeOverlap, earth, s.satelliteWallThickness),
			CFrame.new(midpoint - Vector3.new(0, earth / 2, 0)) * CFrame.Angles(0, -math.atan2(delta.Z, delta.X), 0), s.earthColor)
		triangle(parent, "SatelliteStone", a - Vector3.new(0, earth, 0),
			b - Vector3.new(0, earth, 0), tip, s.stoneColor)
	end
	local accent = s.accents[state.region and state.region.id or "greenland"] or s.accents.greenland
	local offset = s.satelliteCrystalOffset
	crystal(parent, center + Vector3.new(radius * offset.X, s.crystalHeight * offset.Y, radius * offset.Z), s.crystalWidth * 0.5, s.crystalHeight * 0.7, accent)
	local trunk = center + Vector3.new(-radius * 0.3, s.satelliteTreeHeight / 2, radius * 0.2)
	local crown = EnvironmentAssets.crownColor(state.key .. ":satellite:" .. index, state.region and state.region.treePalette)
	part(parent, "SatelliteTrunk", Vector3.new(1, s.satelliteTreeHeight, 1), CFrame.new(trunk), s.earthColor)
	part(parent, "SatelliteCrown", Vector3.new(s.satelliteTreeWidth, s.satelliteTreeHeight * 0.65, s.satelliteTreeWidth),
		CFrame.new(trunk + Vector3.new(0, s.satelliteTreeHeight * 0.4, 0)) * CFrame.Angles(0, math.pi / 4, 0), crown)
end

local function cloudCluster(parent, position, width, height, count, tint, index, random)
	local s, puff = Config.ISLAND, Config.ISLAND.cloudPuff
	local folder = Instance.new("Folder")
	folder.Name, folder.Parent = "CloudCluster_" .. index, parent
	folder:SetAttribute("CloudCluster", true)
	for i = 1, count do
		local top = i == 1
		local angle = (i - 2) * math.pi * 2 / (count - 1)
		local scale = top and puff.topWidth or random:NextNumber(puff.shadeWidth.min, puff.shadeWidth.max)
		local offset = top and Vector3.zero or Vector3.new(math.cos(angle), 0, math.sin(angle)) * width * puff.spread
		local diameter = width * scale
		local lift = height * (top and puff.topLift or puff.shadeLift) - diameter / 2
		local color = top and s.cloudColor or s.cloudCyanColor:Lerp(s.cloudLilacColor, tint)
		local ball = part(folder, top and "CloudTop" or "CloudShade", Vector3.new(diameter, diameter, diameter),
			CFrame.new(position + offset + Vector3.new(0, lift, 0)), color)
		ball.Shape = Enum.PartType.Ball
	end
end

local function skyIslands(board, parent, state, random)
	local s, T = Config.ISLAND, Config.TILE_SIZE
	local center = Vector3.new(state.w / 2, s.cloudHeight, state.h / 2)
	-- Kacheln begrenzen einzelne Teilgroessen; gemeinsam decken sie alle unteren Sichtstrahlen ab.
	local cells = math.ceil(s.cloudReachTiles * T * 2 / s.cloudTileSize)
	local baseParts = cells * cells
	local riverParts = Config.FEEL.waterfallsEnabled and #state.rivers * (2 + Config.FEEL.waterfallFoamCount) or 0
	local remaining = s.partBudget - IslandBuilder.measure(board) - riverParts - baseParts
	local cloudReserve = s.cloudCount * s.cloudParts.min
	-- Kappenfan 2*(n-2), Wand n, Spitze 2*n, Kristall 18 und Baum 2 Teile.
	local satelliteCost = s.satelliteOutlinePoints * 5 + 16
	local count = math.max(0, math.min(random:NextInteger(s.satelliteCount.min, s.satelliteCount.max), math.floor((remaining - cloudReserve) / satelliteCost)))
	local phase = random:NextNumber(0, math.pi * 2)
	local satelliteClouds = {}
	for index = 1, count do
		local side = index % 2 == 1 and -1 or 1
		local distance = state.w / 2 + random:NextNumber(s.satelliteDistanceTiles.min, s.satelliteDistanceTiles.max) * T
		local z = center.Z + state.h * s.satelliteZSpread * (index <= 2 and -1 or 1)
		local position = Vector3.new(center.X + side * distance, random:NextNumber(s.satelliteHeight.min, s.satelliteHeight.max), z)
		satellite(parent, state, position, random:NextNumber(s.satelliteRadiusTiles.min, s.satelliteRadiusTiles.max) * T, index, random)
		table.insert(satelliteClouds, Vector3.new(position.X, s.cloudHeight, position.Z))
	end
	board:SetAttribute("IslandSatellites", count)
	for x = 1, cells do for z = 1, cells do
		part(parent, "CloudSea", Vector3.new(s.cloudTileSize, s.cloudThickness, s.cloudTileSize),
			CFrame.new(center + Vector3.new((x - (cells + 1) / 2) * s.cloudTileSize, -s.cloudThickness / 2,
				(z - (cells + 1) / 2) * s.cloudTileSize)), s.cloudCyanColor:Lerp(s.cloudBaseColor,
				math.max(math.abs(x - (cells + 1) / 2), math.abs(z - (cells + 1) / 2)) / (cells / 2)))
	end end
	local available = s.partBudget - IslandBuilder.measure(board) - riverParts
	local clusterCount = math.max(0, math.min(s.cloudCount, math.floor(available / s.cloudParts.min)))
	local perRing = math.ceil(math.max(0, clusterCount - count) / #s.cloudRings)
	for index = 1, clusterCount do
		local ringIndex = math.max(1, math.ceil((index - count) / math.max(1, perRing)))
		local ring = s.cloudRings[ringIndex]
		local angle = phase + (index - count - 1) * math.pi * 2 / math.max(1, perRing)
		local gap = random:NextNumber(s.cloudGapTiles.min, s.cloudGapTiles.max) * T
		local position = center + Vector3.new(math.cos(angle) * (state.w / 2 + s.rimTiles.max * T + gap) * ring, 0,
			math.sin(angle) * (state.h / 2 + s.rimTiles.max * T + gap) * ring)
		local width = random:NextNumber(s.cloudWidthTiles.min, s.cloudWidthTiles.max) * T
		local height = random:NextNumber(s.cloudHeightTiles.min, s.cloudHeightTiles.max) * T
		if satelliteClouds[index] then
			position = satelliteClouds[index]
			height = math.min(height, s.satelliteCloudRiseTiles * T)
		end
		local balls = math.min(random:NextInteger(s.cloudParts.min, s.cloudParts.max), available - (clusterCount - index) * s.cloudParts.min)
		local tint = satelliteClouds[index] and 1 or math.clamp((ring - 1) / (s.cloudRings[#s.cloudRings] - 1) + random:NextNumber(0, s.cloudPuff.edgeTint), 0, 1)
		cloudCluster(parent, position, width, height, balls, tint, index, random)
		available -= balls
	end
	board:SetAttribute("IslandCloudClusters", clusterCount)
end

function IslandBuilder.measure(board)
	local count, triangles = 0, 0
	for _, object in board:GetDescendants() do
		if object:IsA("BasePart") and object:GetAttribute("IslandPart") then
			count += 1
			triangles += object:IsA("WedgePart") and 8 or (object.Shape == Enum.PartType.Ball and Config.ISLAND.cloudBallEstimatedTriangles or 12)
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
	shell(folder, state.outline, center, s.depthTiles * T, state.riverCuts)
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
