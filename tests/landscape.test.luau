do
	local Landscape = modules.LandscapeBuilder
	local s, hub = Config.LANDSCAPE, Config.HUB_ORIGIN
	local function signature(board)
		local rows = {}
		for key, column in terrainColumns do
			table.insert(rows, key .. ":" .. tostring(column.height) .. ":" .. tostring(column.material))
		end
		for _, asset in board:GetChildren() do if asset:GetAttribute("LandscapeDetail") then
			local cf, size = asset:GetBoundingBox()
			table.insert(rows, asset.Name .. ":" .. tostring(cf.Position) .. ":" .. tostring(size))
		end end
		table.sort(rows)
		return table.concat(rows, "|")
	end
	for _, withPackage in { true, false } do
		if withPackage then metricAssets() else freshAssets() end
		Grid.setMap({ "......", "......", "......" })
		local first = Board.build("greenland")
		validateOuter(first)
		local original = signature(first)
		expect(original == signature(Board.build("greenland")), "Terrain/Modelle nicht deterministisch")
		Grid.setMap({ ".....F", "......", "......" })
		expect(original ~= signature(Board.build("greenland")), "Andere Karte ohne neue Landschaft")
	end
	-- Vorhandenes Hub-Terrain bleibt auch beim großen Brettwechsel bestehen.
	workspace.Terrain:FillBlock(CFrame.new(hub.X, 0, hub.Z), Vector3.new(4, 4, 4), Enum.Material.Brick)
	local start = #terrainBlocks
	Grid.setMap(Gen.generate(4, "greenland", 1, "axe", RC.MAX_TEAM).map)
	local large = Board.build("greenland")
	local oldMargin = Landscape.prepare("Test", nil).margin
	expect(terrainHeightAt(-oldMargin + 2, -oldMargin + 2) ~= nil, "Großer Fernboden fehlt")
	for _, stage in modules.Stages.List do
		Grid.setMap(stage.map)
		validateOuter(Board.build(stage.region))
	end
	Grid.setMap({ "." })
	validateOuter(Board.build("swamp"))
	expect(terrainHeightAt(-oldMargin + 2, -oldMargin + 2) == nil, "Alter Fernboden nach kleiner Karte vorhanden")
	local height, material = terrainHeightAt(hub.X, hub.Z)
	expect(height == 2 and material == Enum.Material.Brick, "Hub-Terrain beim Aufbau/Löschen verändert")
	for index = start + 1, #terrainBlocks do
		local block = terrainBlocks[index]
		expect(block.hi.X <= hub.X - s.hubHalfWidth or block.lo.X >= hub.X + s.hubHalfWidth
			or block.hi.Z <= hub.Z - s.hubHalfDepth or block.lo.Z >= hub.Z + s.hubHalfDepth, "FillBlock berührt Hub-Schutzbereich")
	end
	local state = Landscape.prepare("Tal-Test", nil)
	for z = state.h, state.h + state.sculptMargin, 4 do
		local surface = Landscape.surface(state, state.w / 2, z)
		expect(surface <= Config.FEEL.surroundHeight + s.frontMaxHeight, "Flache Vorderseite fehlt")
	end
	metricAssets()
	print("OK: Terrain-Tal (echte Schreibdaten, Determinismus, Kartenwechsel gleicher/anderer Größe, Tutorial, Hub-Schutz, Vorderhöhe, Paket/Fallback).")
end
