do
	local maps = {
		{ map = { "...", "WBW", "..." }, alongX = false, length = 1 },
		{ map = { "...", "WBW", "WBW", "..." }, alongX = false, length = 2 },
		{ map = { ".W.", ".B.", ".W." }, alongX = true, length = 1 },
		{ map = { ".WW.", ".BB.", ".WW." }, alongX = true, length = 2 },
	}
	freshAssets(); assetModel(models, "archbridge_1", Vector3.new(8, 2.1, 2.3))
	for _, case in maps do
		Grid.setMap(case.map)
		local crossings = Grid.bridgeCrossings()
		expect(#crossings == 1 and crossings[1].alongX == case.alongX and crossings[1].length == case.length, "Brückenquerung/Ausrichtung")
		bridgeSamples = {}
		local board = Board.build("greenland")
		local count = 0
		for _, object in board:GetChildren() do if object.Name == "archbridge_1" then
			count += 1
			local _, size = object:GetBoundingBox()
			expect(math.abs((case.alongX and size.X or size.Z) - (case.length + Config.ENVIRONMENT.bridge.bankOverlap * 2) * Config.TILE_SIZE) < 0.01, "Brücke reicht nicht von Ufer zu Ufer")
			for _, part in object:GetDescendants() do if part:IsA("BasePart") then expect(not part.CanQuery, "Brücke fängt Feldklick ab") end end
		end end
		expect(count == 1, "Mehrere Modelle pro Querung")
		for _, sample in bridgeSamples do
			local x, y = sample.x / Config.TILE_SIZE + 0.5, sample.z / Config.TILE_SIZE + 0.5
			expect(math.abs(Grid.toWorld(x, y).Y - sample.height) <= Config.ENVIRONMENT.bridge.footTolerance, "Figuren-/Overlay-Höhe neben Brückenboden")
		end
		local heights = Grid.getHeights(); Grid.setMap(case.map); Grid.setHeights(heights)
		for key, value in heights do local x, y = key:match("(%d+),(%d+)"); expect(Grid.tileHeight(tonumber(x), tonumber(y)) == value, "Höhenübertragung an Client") end
		for _, crossing in crossings do for _, cell in crossing.cells do
			local height, material = terrainHeightAt((cell.x - 0.5) * Config.TILE_SIZE, (cell.y - 0.5) * Config.TILE_SIZE)
			expect(material == Enum.Material.Water and math.abs(height - Config.TERRAIN.W.height) < 0.01, "Terrain-Wasser unter Bruecke fehlt")
		end end
	end
	bridgeRayMiss = true
	Grid.setMap(maps[1].map)
	local failed = Board.build("greenland")
	expect(not failed:FindFirstChild("archbridge_1") and Grid.tileHeight(2, 2) == Config.TERRAIN.B.height, "Messfehler ohne sichere Part-Brücke")
	bridgeRayMiss = false
	freshAssets(); Grid.setMap(maps[1].map); Board.build("greenland")
	expect(Grid.tileHeight(2, 2) == Config.TERRAIN.B.height and next(Grid.getHeights()) == nil, "Brückenfallback/Höhenreset")
	print("OK: Brücken (ein Modell, 1/2 Felder, beide Achsen, Ufer, Wasser, Höhenübertragung, Raycast-/Paketfallback).")
end
