-- Terrain-Schreibdaten und echte Modell-Bounding-Boxen, kein Roblox-Rendering.
local function validateOuter(board)
	local s, T = Config.LANDSCAPE, Config.TILE_SIZE
	local w, h = Grid.width() * T, Grid.height() * T
	local highest = 0
	for _, column in terrainColumns do
		if column.x >= 0 and column.x < w and column.z >= 0 and column.z < h then
			local x, y = math.floor(column.x / T) + 1, math.floor(column.z / T) + 1
			local ch = Grid.getMap()[y]:sub(x, x)
			if ch ~= "M" and ch ~= "C" then expect(not column.height, "Terrain ?berdeckt Brettfeld") end
		elseif column.height then
			if column.z >= h then expect(column.height <= Config.FEEL.surroundHeight + s.frontMaxHeight, "Vorderes Terrain zu hoch") end
			highest = math.max(highest, column.height)
		end
	end
	expect(highest > s.rockHeight, "Hintere/seitliche Terrainberge fehlen")
	for _, asset in board:GetChildren() do
		expect(not asset:GetAttribute("OuterEdge") and asset.Name ~= "OuterLeaves" and asset.Name ~= "OuterTreeCrown", "Alter Umgebungsring/Platzhalter vorhanden")
		if not asset:GetAttribute("LandscapeDetail") then continue end
		local box, size = asset:GetBoundingBox()
		local lo, hi = Vector3.new(math.huge, math.huge, math.huge), Vector3.new(-math.huge, -math.huge, -math.huge)
		for _, dx in { -1, 1 } do for _, dy in { -1, 1 } do for _, dz in { -1, 1 } do
			local p = box:PointToWorldSpace(Vector3.new(dx * size.X / 2, dy * size.Y / 2, dz * size.Z / 2))
			lo = Vector3.new(math.min(lo.X, p.X), math.min(lo.Y, p.Y), math.min(lo.Z, p.Z))
			hi = Vector3.new(math.max(hi.X, p.X), math.max(hi.Y, p.Y), math.max(hi.Z, p.Z))
		end end end
		expect(hi.X <= 0 or lo.X >= w or hi.Z <= 0 or lo.Z >= h, "Landschaftsobjekt ragt auf Brett")
		expect(hi.X <= Config.HUB_ORIGIN.X - s.hubHalfWidth or lo.X >= Config.HUB_ORIGIN.X + s.hubHalfWidth
			or hi.Z <= Config.HUB_ORIGIN.Z - s.hubHalfDepth or lo.Z >= Config.HUB_ORIGIN.Z + s.hubHalfDepth, "Landschaftsobjekt im Hub")
		for _, part in asset:GetDescendants() do if part:IsA("BasePart") then expect(not part.CanQuery and not part.CanCollide, "Landschaft f?ngt Klicks ab") end end
	end
	expect(board:GetAttribute("LandscapeTrees") <= s.maxTrees, "Baumbudget ?berschritten")
end
local function validateZoomGround(_board)
	local w, h = Grid.width() * Config.TILE_SIZE, Grid.height() * Config.TILE_SIZE
	local overview = math.max(Config.CAMERA.zoomOverviewMin, math.sqrt(w * w + h * h) * Config.CAMERA.zoomOverviewScale)
	for _, aspect in { 4 / 3, 16 / 9, 21 / 9 } do for yaw = 0, 7 do
		local angle, tangent = yaw * math.pi / 4, math.tan(math.rad(35))
		for _, fx in { 0, w } do for _, fz in { 0, h } do
			for _, sx in { -1, 1 } do for _, sy in { -1, 1 } do
				local dy = -0.8 + 0.6 * sy * tangent
				local time = (overview * 0.8 - Config.LANDSCAPE.foundationTop) / -dy
				local dx, dz = sx * aspect * tangent * time, overview * 0.6 + (-0.6 - 0.8 * sy * tangent) * time
				local x, z = fx + dx * math.cos(angle) + dz * math.sin(angle), fz - dx * math.sin(angle) + dz * math.cos(angle)
				local hub = Config.HUB_ORIGIN
				local inHub = math.abs(x - hub.X) < Config.LANDSCAPE.hubHalfWidth and math.abs(z - hub.Z) < Config.LANDSCAPE.hubHalfDepth
				local covered = x >= 0 and x <= w and z >= 0 and z <= h
				expect(covered or inHub or terrainHeightAt(x, z) ~= nil, "Leerer Terrainrand bei Maximalzoom")
			end end
		end end
	end end
end
