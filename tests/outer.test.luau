-- Terrain-Schreibdaten und echte Modell-Bounding-Boxen, kein Roblox-Rendering.
local function validateOuter(board)
	local s, T = Config.LANDSCAPE, Config.TILE_SIZE
	local w, h = Grid.width() * T, Grid.height() * T
	local highest = 0
	for _, column in terrainColumns do
		if column.x >= 0 and column.x < w and column.z >= 0 and column.z < h then
			local x, y = math.floor(column.x / T) + 1, math.floor(column.z / T) + 1
			local ch = Grid.getMap()[y]:sub(x, x)
			if ch == "W" or ch == "B" then
				expect(column.material == Enum.Material.Water and column.height <= Config.TERRAIN.W.height + 0.001, "Wasser ueberdeckt Nachbarfeld")
			elseif ch ~= "M" and ch ~= "C" then expect(not column.height, "Terrain verdeckt Brettfeld") end
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
		for _, part in asset:GetDescendants() do if part:IsA("BasePart") then expect(not part.CanQuery and not part.CanCollide, "Landschaft fängt Klicks ab") end end
	end
	expect(board:GetAttribute("LandscapeTrees") <= s.maxTrees, "Baumbudget überschritten")
end
local function validateZoomGround(_board)
	local w, h = Grid.width() * Config.TILE_SIZE, Grid.height() * Config.TILE_SIZE
	local size, c = Vector3.new(w, 0, h), Config.CAMERA
	local up, back = 1 / math.sqrt(1 + c.tilt ^ 2), c.tilt / math.sqrt(1 + c.tilt ^ 2)
	for _, fov in { 60, 70, 75 } do for _, aspect in { 4 / 3, 16 / 9, 21 / 9 } do for yaw = 0, 7 do
		local overview = Config.overviewZoom(size, fov, aspect)
		local angle, tangent = yaw * math.pi / 4, math.tan(math.rad(fov / 2))
		for _, fx in { 0, w } do for _, fz in { 0, h } do
			for _, sx in { -1, 0, 1 } do for _, sy in { -1, 0, 1 } do
				local dy = -up + back * sy * tangent
				local time = (overview * up + c.focusHeightReserve - Config.LANDSCAPE.foundationTop) / -dy
				local dx, dz = sx * aspect * tangent * time, overview * back + (-back - up * sy * tangent) * time
				local x, z = fx + dx * math.cos(angle) + dz * math.sin(angle), fz - dx * math.sin(angle) + dz * math.cos(angle)
				local covered = x >= 0 and x <= w and z >= 0 and z <= h
				expect(covered or terrainHeightAt(x, z) ~= nil, string.format("Leerer Terrainrand: Brett %dx%d FOV %d Format %.2f Zoom %.2f Strahl %.2f/%.2f Margin %.2f", w, h, fov, aspect, overview, x, z, Config.landscapeMargin(size)))
			end end
		end end
		-- Projektion aller Brett-Ecken bei zentralem Fokus: bequem im Bild.
		for _, x in { -w / 2, w / 2 } do for _, z in { -h / 2, h / 2 } do
			local right = x * math.cos(angle) - z * math.sin(angle)
			local along = x * math.sin(angle) + z * math.cos(angle)
			local depth = overview - along * back
			expect(math.abs(right) < depth * tangent * aspect and math.abs(along * up) < depth * tangent,
				"Ganzes Brett passt bei ?bersichtszoom nicht ins Bild")
		end end
	end end end
end
