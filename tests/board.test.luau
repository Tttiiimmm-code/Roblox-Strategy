-- Echte Brett-/Kameramodule mit Geometrie-Stubs, getrennt vom Server-Testzustand.
local Board, Grid, RC = modules.BoardBuilder, modules.Grid, modules.RunConfig
local Config, Gen, Camera = modules.Config, modules.LevelGen, modules.CameraController
local checks, falls, parts, elapsed, low, high = 0, 0, 0, 0, math.huge, 0
local function expect(value, message) checks += 1; assert(value, message) end
local function checkBoard(stage)
	Grid.setMap(stage.map)
	local start = os.clock()
	local board = Board.build("greenland", stage.features)
	local duration = os.clock() - start
	local count, tiles, planes, foam, source = 0, 0, 0, 0, 0
	for _, p in ipairs(board:GetDescendants()) do
		if p:IsA("BasePart") then
			count += 1
			expect(p.Size.X > 0 and p.Size.Y > 0 and p.Size.Z > 0, "Ungültige Teilgröße")
			expect(not p.CastShadow and not p.CanTouch, "Brettteil mit Schatten/Touch")
		end
		if p.Name == "Waterfall" then
			planes += 1
			expect(p.Size.Y == Config.TERRAIN.C.height - Config.TERRAIN.W.height, "Fallhöhe")
			expect(not p.CanQuery, "Wasserfall fängt Klick ab")
		elseif p.Name == "WaterfallFoam" then foam += 1
		elseif p.Name == "WaterfallSource" then source += 1 end
		if p.Name:sub(1, 5) == "Tile_" then
			tiles += 1
			local x, y = p:GetAttribute("X"), p:GetAttribute("Y")
			expect(p.CanQuery and not p.CanCollide, "Klickfeld fehlt")
			expect(p.Position.Y == Grid.tileHeight(x, y) - 0.1, "Klickhöhe")
			if stage.map[y]:sub(x, x) == "C" then
				expect(p.Position.Y > Config.TERRAIN.M.height, "Klippe zu niedrig")
			end
		end
	end
	local expected = stage.features and stage.features.waterfall and Config.FEEL.waterfallsEnabled and 1 or 0
	expect(planes == expected and source == expected, "Wasserfall fehlt/Abschaltung")
	expect(foam == expected * Config.FEEL.waterfallFoamCount, "Gischtanzahl")
	expect(tiles == #stage.map * #stage.map[1], "Klickfeldzahl")
	return count, duration, expected
end
for seed = 1, 100 do
	local stage = Gen.generate(seed, "greenland", 1, "axe", RC.MAX_TEAM)
	local count, duration, fall = checkBoard(stage)
	parts += count; elapsed += duration; low = math.min(low, count); high = math.max(high, count)
	falls += fall
	if fall > 0 then
		Config.FEEL.waterfallsEnabled = false
		checkBoard(stage)
		Config.FEEL.waterfallsEnabled = true
	end
end
expect(falls > 0, "Keine Wasserfälle in der Brettprobe")
for _, stage in ipairs(modules.Stages.List) do checkBoard(stage) end
checkBoard(Gen.generate(1, "greenland", 5, "axe", RC.MAX_TEAM, "boss"))
expect(#terrainClears >= 4, "Terrain bei Größenwechsel nicht freigeräumt")
for _, clear in ipairs(terrainClears) do
	expect(clear.material == Enum.Material.Air, "Terrain nicht gelöscht")
	expect(clear.size.Y >= Config.FEEL.terrainClearTop + Config.FEEL.terrainDepth, "Freiraum zu niedrig")
end
-- Klippen sperren auch die echte Wegfindung, unabhängig von der Generatorprüfung.
Grid.setMap({ "...", ".C.", "..." })
for _, class in ipairs({ "Lord", "Cavalier" }) do
	local unit = { id = class, x = 1, y = 2, team = "Player", class = class, mov = 20 }
	expect(Grid.moveCost(unit, 2, 2) == nil, "Klippe betretbar")
	local cells = Grid.reachable(unit, { [class] = unit })
	expect(cells[Grid.key(2, 2)] == nil and cells[Grid.key(3, 2)], "Klippen-Wegfindung")
end
Camera.start()
Camera.setActive(true)
local size = Vector3.new(16 * Config.TILE_SIZE, 0, 12 * Config.TILE_SIZE)
Camera.setBounds(size / 2, size, Vector3.new(size.X / 2, 0, size.Z - Config.TILE_SIZE))
render(0)
expect(workspace.CurrentCamera.CFrame.target.Z == size.Z - Config.TILE_SIZE, "Startkamera nicht bei Truppe")
Camera.zoomBy(0.0001)
render(0)
local overview = (workspace.CurrentCamera.CFrame.Position - workspace.CurrentCamera.CFrame.target).Magnitude
expect(math.abs(overview - size.Magnitude * Config.CAMERA.zoomOverviewScale) < 0.001, "Großes Brett ohne Übersichtszoom")
for _, corner in ipairs({ { -1, -1 }, { -1, 1 }, { 1, -1 }, { 1, 1 } }) do
	Camera.panBy({ X = corner[1] * 100000, Y = corner[2] * 100000 })
	render(0)
	local focus = workspace.CurrentCamera.CFrame.target
	expect(focus.X == (corner[1] < 0 and size.X or 0) and focus.Z == (corner[2] < 0 and size.Z or 0), "Brettecke nicht erreichbar")
end
Camera.zoomBy(100000)
render(0)
expect(math.abs((workspace.CurrentCamera.CFrame.Position - workspace.CurrentCamera.CFrame.target).Magnitude - Config.CAMERA.zoomMin) < 0.001, "Zoomminimum")
wheel({ UserInputType = Enum.UserInputType.MouseWheel, Position = { Z = -100000 } }, false)
render(0)
expect(math.abs((workspace.CurrentCamera.CFrame.Position - workspace.CurrentCamera.CFrame.target).Magnitude - overview) < 0.001, "Mausrad-Zoomgrenze")
local tutorial = modules.Stages.List[1]
local small = Vector3.new(#tutorial.map[1] * Config.TILE_SIZE, 0, #tutorial.map * Config.TILE_SIZE)
Camera.setBounds(small / 2, small)
render(0)
expect(workspace.CurrentCamera.CFrame.target.X == small.X / 2 and workspace.CurrentCamera.CFrame.target.Z == small.Z / 2, "Tutorialkamera geändert")
expect(math.abs((workspace.CurrentCamera.CFrame.Position - workspace.CurrentCamera.CFrame.target).Magnitude - math.clamp(math.max(small.X, small.Z) * 0.85, 45, 120)) < 0.001, "Tutorialzoom geändert")
print(string.format("Brett 16x12: 100 Seeds, Teile Mittel %.1f (min %d, max %d); Stub-Aufbau Mittel %.2f ms; %d Wasserfaelle.", parts / 100, low, high, elapsed * 10, falls))
print(string.format("OK: %d Brett-/Kamerapruefungen (Klippen, Wasserfaelle/Abschaltung, kleine/grosse Karten, alle Ecken, Zoom). Studio/Handy ungetestet.", checks))
