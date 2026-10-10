-- Inselpfad mit echten Modulen; Talregressionen laufen zuvor mit deaktivierter Insel.
do
	local Landscape, Island = modules.LandscapeBuilder, modules.IslandBuilder
	local s, T = Config.ISLAND, Config.TILE_SIZE
	s.enabled = true
	local beforeChecks, maxParts, rivers, duration = checks, 0, 0, 0
	local function signature(board)
		local rows = {}
		for _, p in board:GetDescendants() do if p:GetAttribute("IslandPart") then
			table.insert(rows, p.Name .. ":" .. tostring(p.Position) .. ":" .. tostring(p.Size) .. ":" .. p.Color.R .. ":" .. p.Color.G .. ":" .. p.Color.B
				.. ":" .. tostring(p.Shape) .. ":" .. tostring(p.Material))
		end end
		for key, column in terrainColumns do if column.height then
			table.insert(rows, key .. ":" .. column.height .. ":" .. tostring(column.material))
		end end
		table.sort(rows)
		return table.concat(rows, "|")
	end
	local function validate(board, region)
		local originalGrass = region.landscape.colors[region.landscape.grass]
		local state = Landscape.prepare(region.id .. ":" .. table.concat(Grid.getMap(), "|"), region)
		expect(board:GetAttribute("IslandEnabled"), "Inselpfad fehlt")
		local grass = region.terrainColors and region.terrainColors["."] or Config.TERRAIN["."].color
		local rim = state.palette.colors[state.palette.grass]
		expect(rim.R >= grass.R and rim.G >= grass.G and rim.B >= grass.B, "Inselrand dunkler als Brettgras")
		expect(rim.R >= originalGrass.R and rim.G >= originalGrass.G and rim.B >= originalGrass.B, "Helle Gebietspalette durch Gras ersetzt")
		expect(region.landscape.colors[region.landscape.grass] == originalGrass, "Insel veraendert Talpalette")
		expect(Island.measure(board) <= s.partBudget, "Inselteilebudget ueberschritten")
		maxParts = math.max(maxParts, board:GetAttribute("IslandParts"))
		local satellites = board:GetAttribute("IslandSatellites")
		expect(satellites >= s.satelliteCount.min and satellites <= s.satelliteCount.max, "Nebeninselzahl")
		local satelliteFolders = 0
		for _, folder in board:GetDescendants() do if folder:GetAttribute("Satellite") then
			satelliteFolders += 1
			expect(folder:GetAttribute("OutlinePoints") >= 6 and folder:GetAttribute("OutlinePoints") <= 8, "Nebeninsel nicht polygonal")
			expect(folder:GetAttribute("SurfaceHeight") >= s.satelliteHeight.min and folder:GetAttribute("SurfaceHeight") <= s.satelliteHeight.max, "Nebeninsel nicht tiefer")
			expect(math.abs(folder:GetAttribute("CenterX") - state.w / 2) >= state.w / 2 + s.satelliteDistanceTiles.min * T, "Nebeninsel vor Kamera")
			local walls, stones, trunks, crowns, crystals = 0, 0, 0, 0, 0
			for _, p in folder:GetChildren() do
				if p.Name == "SatelliteEarth" then walls += 1
				elseif p.Name == "SatelliteStone" then stones += 1
				elseif p.Name == "SatelliteTrunk" then trunks += 1
				elseif p.Name == "SatelliteCrown" then crowns += 1
				elseif p.Name == "ThroneCrystal" then
					crystals += 1
					local accent = s.accents[region.id]
					expect(p.Color.R == accent.R and p.Color.G == accent.G and p.Color.B == accent.B, "Nebeninsel ohne Gebietskristall")
				end
			end
			expect(walls == s.satelliteOutlinePoints and stones >= walls and trunks == 1 and crowns == 1 and crystals > 0, "Nebeninsel unvollstaendig")
		end end
		expect(satelliteFolders == satellites, "Nebeninselzahl falsch gemeldet")
		expect(board:GetAttribute("IslandCloudClusters") > 0, "Wolkenhaufen fehlen")
		local clusters, near = 0, 0
		local cloudTops = {}
		for _, folder in board:GetDescendants() do if folder:GetAttribute("CloudCluster") then
			clusters += 1
			local balls = folder:GetChildren()
			expect(#balls >= s.cloudParts.min and #balls <= s.cloudParts.max, "Wolkenhaufen ohne 3-6 Kugeln")
			local top = folder:FindFirstChild("CloudTop")
			table.insert(cloudTops, top.Position + Vector3.new(0, top.Size.Y / 2, 0))
			local dx, dz = math.abs(top.Position.X - state.w / 2), math.abs(top.Position.Z - state.h / 2)
			if dx <= state.w / 2 + (s.rimTiles.max + s.cloudGapTiles.max) * T
				and dz <= state.h / 2 + (s.rimTiles.max + s.cloudGapTiles.max) * T then near += 1 end
			for _, ball in balls do
				expect(ball.Size.X == ball.Size.Y and ball.Size.Y == ball.Size.Z, "Wolkenkugel flach skaliert")
				expect((ball.Position - top.Position).Magnitude < (ball.Size.X + top.Size.X) / 2, "Wolkenkugeln getrennt")
			end
		end end
		expect(clusters == board:GetAttribute("IslandCloudClusters") and near >= math.floor((clusters - satellites) / #s.cloudRings), "Wolkenhaufen nur weit draussen")
		-- Tatsächliche Spielneigung: Wolkenkappen müssen in beiden Zoomstufen ins Bild fallen.
		local c = Config.CAMERA
		local up, back = 1 / math.sqrt(1 + c.tilt ^ 2), c.tilt / math.sqrt(1 + c.tilt ^ 2)
		local tangent = math.tan(math.rad(70 / 2))
		for _, aspect in { 4 / 3, 16 / 9, c.aspectMax } do
			local overview = Config.overviewZoom(Vector3.new(state.w, 0, state.h), 70, aspect)
			local normal = math.clamp(math.max(state.w, state.h) * c.zoomDefaultScale, c.zoomDefaultMin, math.min(c.zoomDefaultMax, overview))
			for _, view in { { normal, state.h - T }, { overview, math.clamp(state.h - T, state.h * s.panInset, state.h * (1 - s.panInset)) } } do
				local visible = 0
				for _, point in cloudTops do
					local x, z = point.X - state.w / 2, point.Z - view[2]
					local depth = view[1] - point.Y * up - z * back
					local vertical = point.Y * back - z * up
					if depth > 0 and math.abs(x) < depth * tangent * aspect and math.abs(vertical) < depth * tangent
						and not Landscape.contains(state, point.X, point.Z) then visible += 1 end
				end
				expect(visible > 0, "Wolkenhaufen ausserhalb Normal-/Uebersichtsbild")
			end
		end
		for _, x in { 0, state.w } do for _, z in { 0, state.h } do
			expect(Landscape.contains(state, x, z), "Insel umschliesst Brett nicht")
		end end
		for _, column in terrainColumns do
			local inHub = math.abs(column.x - Config.HUB_ORIGIN.X) <= Config.LANDSCAPE.hubHalfWidth
				and math.abs(column.z - Config.HUB_ORIGIN.Z) <= Config.LANDSCAPE.hubHalfDepth
			if column.height and not inHub then expect(Landscape.contains(state, column.x, column.z), "Terrain ausserhalb Insel") end
		end
		local falls, foam, tops, cloudTiles, tiles, earthWalls, stoneWalls = 0, 0, 0, 0, 0, 0, 0
		for _, p in board:GetDescendants() do
			if p.Name:sub(1, 5) == "Tile_" then
				tiles += 1
				expect(p.CanQuery and not p.CanCollide, "Klickfeld fehlt")
				expect(p.Position.Y == Grid.tileHeight(p:GetAttribute("X"), p:GetAttribute("Y")) - 0.1, "Figuren-/Klickhoehe geaendert")
			end
			if not p:GetAttribute("IslandPart") then continue end
			expect(p.Name ~= "CloudMountain", "Kantiger Wolkenberg bleibt")
			if p.Name == "CloudTop" or p.Name == "CloudShade" then
				expect(p.Shape == Enum.PartType.Ball and p.Position.Y + p.Size.Y / 2 < s.surfaceHeight, "Wolkenkugel fehlt/ueber Insel")
			end
			expect(p:IsA("BasePart") and not p.CanQuery and not p.CanTouch and not p.CanCollide and not p.CastShadow, "Insel faengt Eingaben ab")
			expect(p.Size.X > 0 and p.Size.Y > 0 and p.Size.Z > 0, "Ungueltige Inselfacette")
			expect(p.Material == Enum.Material.SmoothPlastic or p.Material == Enum.Material.Neon, "Inselteil mit Materialtextur")
			if p.Name == "IslandEarth" then
				earthWalls += 1
				expect(math.abs(p.Position.Y - p.Size.Y / 2 - (s.surfaceHeight - s.cliffEarthTiles * T)) < 0.001, "Erdwand endet falsch")
			elseif p.Name == "IslandCliffStone" then
				stoneWalls += 1
				expect(math.abs(p.Size.Y - s.cliffStoneTiles * T) < 0.001, "Steinwandhoehe falsch")
				expect(math.abs(p.Position.Y + p.Size.Y / 2 - (s.surfaceHeight - s.cliffEarthTiles * T)) < 0.001, "Luecke zwischen Erde und Stein")
			elseif p.Name == "IslandWaterfall" then
				falls += 1
				expect(math.abs(p.Position.Y - p.Size.Y / 2 - s.cloudHeight) < 0.001, "Fall endet nicht in Wolken")
				expect(p.Size.Y >= (s.earthTiles + s.depthTiles) * T, "Fall kuerzer als Inselschale")
			elseif p.Name == "WaterfallFoam" then foam += 1; expect(p.Shape == Enum.PartType.Block, "Randgischt nicht kantig")
			elseif p.Name == "SatelliteTop" then
				tops += 1
				expect(p:IsA("WedgePart"), "Nebeninsel bleibt quadratisches Brett")
				local color = state.palette.colors[state.palette.grass]
				expect(p.Color.R == color.R and p.Color.G == color.G and p.Color.B == color.B, "Nebeninsel ohne Gebietspalette")
				expect(p.Position.X + p.Size.X / 2 < 0 or p.Position.X - p.Size.X / 2 > state.w
					or p.Position.Z + p.Size.Z / 2 < 0 or p.Position.Z - p.Size.Z / 2 > state.h, "Nebeninsel im Schwenkbereich")
			elseif p.Name == "CloudSea" then
				cloudTiles += 1
				expect(p.Size.X <= s.cloudTileSize and p.Size.Z <= s.cloudTileSize, "Wolkenteil zu gross")
				expect(math.abs(p.Position.Y + p.Size.Y / 2 - s.cloudHeight) < 0.001, "Wolkendecke verschoben")
			end
		end
			expect(tiles == Grid.width() * Grid.height(), "Spielbare Felder fehlen")
		expect(earthWalls >= #state.outline and earthWalls == stoneWalls, "Senkrechte Inselwand fehlt")
		expect(tops >= satellites * (s.satelliteOutlinePoints - 2) and cloudTiles > 0, "Nebeninseln/Wolken unvollstaendig")
		local expected = Config.FEEL.waterfallsEnabled and #state.rivers or 0
		expect(falls == expected and foam == expected * Config.FEEL.waterfallFoamCount, "Randfluss ohne Fall/Gischt")
		rivers += falls
		for _, river in state.rivers do
			local point = Landscape.riverEnd(state, river)
			expect(point ~= nil, "Randfluss endet nicht an Kante")
			expect(Landscape.contains(state, point.X - river.dx * 0.1, point.Z - river.dz * 0.1)
				and not Landscape.contains(state, point.X + river.dx * 0.1, point.Z + river.dz * 0.1), "Falscher Polygon-Schnitt")
			local height, material = Landscape.surface(state, point.X - river.dx * 2, point.Z - river.dz * 2)
			expect(height == Config.TERRAIN.W.height and material == Enum.Material.Water, "Fluss vor Kante verengt/verschlossen")
		end
		return state
	end
	metricAssets()
	for _, regionId in { "greenland", "swamp" } do
		local region = modules.Stages.getRegion(regionId)
		-- Der Generator bietet bisher nur Grasland; dieselben Karten pruefen beide Landschaftspaletten.
		for seed = 1, 100 do
			local stage = Gen.generate(seed, "greenland", 1, "axe", RC.MAX_TEAM)
			Grid.setMap(stage.map)
			local start = os.clock()
			local board = Board.build(regionId, stage.features, stage)
			duration += os.clock() - start
			validate(board, region)
			if seed <= 3 then
				local original = signature(board)
				expect(original == signature(Board.build(regionId, stage.features, stage)), "Insel nicht deterministisch")
			end
		end
	end
	-- Feste Tutorials sowie Hauptmann/Festung verwenden denselben Inselpfad.
	for _, stage in modules.Stages.List do
		Grid.setMap(stage.map)
		validate(Board.build(stage.region, stage.features, stage), modules.Stages.getRegion(stage.region))
	end
	for _, kind in { "miniboss", "boss" } do
		local stage = Gen.generate(1, "greenland", kind == "boss" and 5 or 3, "axe", RC.MAX_TEAM, kind)
		Grid.setMap(stage.map)
		validate(Board.build("greenland", stage.features, stage), modules.Stages.getRegion("greenland"))
	end
	for _, region in modules.Stages.Regions do
		Grid.setMap({ "...", "...", "..." })
		local board = Board.build(region.id)
		validate(board, region)
	end
	-- Kamera passt alle Polygonpunkte bei jedem Bildformat und jeder Drehung ins Bild.
	Grid.setMap(Gen.generate(1, "greenland", 1, "axe", RC.MAX_TEAM).map)
	local region = modules.Stages.getRegion("greenland")
	-- Ein knappes Dekobudget darf den Levelaufbau nicht abbrechen.
	local budget = s.partBudget
	s.partBudget = 1
	local limited = Board.build("greenland")
	expect(limited:GetAttribute("IslandSatellites") == 0, "Budget-Fallback ohne Nebeninseln fehlt")
	expect(limited:FindFirstChild("Island") ~= nil, "Knappes Budget bricht Inselaufbau ab")
	s.partBudget = budget
	local state = Landscape.prepare("Kamera", region)
	local size = Vector3.new(state.w, 0, state.h)
	local c = Config.CAMERA
	for _, fov in { 60, 70, 75 } do for _, aspect in { 4 / 3, 16 / 9, 21 / 9 } do for yaw = 0, 7 do
		local zoom = Config.overviewZoom(size, fov, aspect)
		local up, back = 1 / math.sqrt(1 + c.tilt ^ 2), c.tilt / math.sqrt(1 + c.tilt ^ 2)
		local angle, tangent = yaw * math.pi / 4, math.tan(math.rad(fov / 2))
		for _, point in state.outline do
			local x, z = point.X - size.X / 2, point.Z - size.Z / 2
			local right, along = x * math.cos(angle) - z * math.sin(angle), x * math.sin(angle) + z * math.cos(angle)
			local depth = zoom - along * back
			expect(math.abs(right) < depth * tangent * aspect and math.abs(along * up) < depth * tangent, "Insel passt nicht in Uebersicht")
		end
		-- Wolkendecke deckt alle unteren Sichtstrahlen auch am erlaubten Schwenkrand ab.
		for _, fx in { size.X * s.panInset, size.X * (1 - s.panInset) } do
		for _, fz in { size.Z * s.panInset, size.Z * (1 - s.panInset) } do
		for _, sx in { -1, 1 } do for _, sy in { -1, 1 } do
			local time = (zoom * up + c.focusHeightReserve - s.cloudHeight) / (up - back * sy * tangent)
			local dx, dz = sx * aspect * tangent * time, zoom * back + (-back - up * sy * tangent) * time
			local x, z = fx + dx * math.cos(angle) + dz * math.sin(angle), fz - dx * math.sin(angle) + dz * math.cos(angle)
			expect(math.abs(x - size.X / 2) <= s.cloudReachTiles * T and math.abs(z - size.Z / 2) <= s.cloudReachTiles * T, "Sichtstrahl ausserhalb Wolkendecke")
		end end end end
	end end end
	Camera.setBounds(size / 2, size, Vector3.new(size.X / 2, 0, size.Z - T))
	render(0)
	expect(workspace.CurrentCamera.CFrame.target.Z == size.Z - T, "Normalfokus geaendert")
	Camera.zoomBy(0.0001)
	for _, corner in { {-1,-1}, {-1,1}, {1,-1}, {1,1} } do
		Camera.panBy({ X = corner[1] * 100000, Y = corner[2] * 100000 })
		render(0)
		local focus = workspace.CurrentCamera.CFrame.target
		expect(focus.X >= size.X * s.panInset and focus.X <= size.X * (1 - s.panInset)
			and focus.Z >= size.Z * s.panInset and focus.Z <= size.Z * (1 - s.panInset), "Schwenken zeigt nur Wolken")
	end
	-- Insel -> Tal -> kleine Insel: alter Fernboden muss komplett verschwinden, Hub bleibt.
	s.enabled = false
	Grid.setMap({ "...", "...", "..." })
	local valley = Board.build("greenland")
	expect(not valley:GetAttribute("IslandEnabled") and not valley:FindFirstChild("Island"), "Tal-Rueckfall hat Inselteile")
	expect(terrainHeightAt(-100, -100) ~= nil, "Tal-Rueckfall ohne Fernboden")
	s.enabled = true
	freshAssets()
	local board = Board.build("greenland")
	validate(board, region)
	expect(terrainHeightAt(-100, -100) == nil, "Alter Talboden bleibt ausserhalb Insel")
	local height, material = terrainHeightAt(Config.HUB_ORIGIN.X, Config.HUB_ORIGIN.Z)
	expect(height == 2 and material == Enum.Material.Brick, "Inselaufbau veraendert Hub-Terrain")
	print(string.format("OK: %d Inselpruefungen; 200 Gebiets-Seeds, alle vier Paletten, Paket/Fallback, Determinismus, Terrainwechsel, Hub, Randfaelle %d, Teilemaximum %d/%d, Stub-Aufbau Mittel %.2f ms.",
		checks - beforeChecks, rivers, maxParts, s.partBudget, duration * 5))
end
