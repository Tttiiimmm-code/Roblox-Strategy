-- Wasserfelder, Fortsetzung, regionale Einstellungen und vollstaendiges Aufraeumen.
do
	freshAssets()
	Grid.setMap({ "..W..", "..B..", "..W.." })
	local board = Board.build("greenland")
	for y = 1, 3 do
		local height, material = terrainHeightAt(20, (y - 0.5) * 8)
		expect(material == Enum.Material.Water and math.abs(height - Config.TERRAIN.W.height) < 0.001, "Terrain-Wasser fehlt")
		local tile = board:FindFirstChild(("Tile_3_%d"):format(y))
		expect(tile and tile.CanQuery and tile.Transparency == 1, "Wasser nicht anklickbar")
	end
	local _, material = terrainHeightAt(20, -12)
	expect(material == Enum.Material.Water, "Fluss endet am Brettrand")
	local region = modules.Stages.getRegion("greenland")
	expect(workspace.Terrain.WaterColor == region.water.color and workspace.Terrain.WaterWaveSize == region.water.waveSize, "Regionale Wasserwerte fehlen")
	Grid.setMap({ ".....", ".....", "....." })
	Board.build("greenland")
	expect(terrainHeightAt(20, 4) == nil, "Altes Wasser auf Brett vorhanden")
	local _, outside = terrainHeightAt(20, -12)
	expect(outside ~= Enum.Material.Water, "Alte Flussfortsetzung vorhanden")
	local enabled = region.water.extendRivers
	region.water.extendRivers = false
	Grid.setMap({ "W" }); Board.build("greenland")
	local _, disabled = terrainHeightAt(4, -12)
	expect(disabled ~= Enum.Material.Water, "Flussfortsetzung nicht abschaltbar")
	region.water.extendRivers = enabled
	print("OK: Terrain-Wasser (Felder, Bruecken, Klicks, Region, Fortsetzung/Schalter, Kartenwechsel).")
end
