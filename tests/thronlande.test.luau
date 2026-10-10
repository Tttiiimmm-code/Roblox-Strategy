-- Abmessungen aus dem tatsächlichen Studio-Import; Mesh-Raycasts separat in Studio prüfen.
do
	local Assets, Landscape = modules.EnvironmentAssets, modules.LandscapeBuilder
	local samples = {
		{ "archbridge_2", 0.821777, 0.510242, 0.999512 }, { "deco_flower_4", 0.976837, 0.657153, 0.925400 },
		{ "deco_grass_2", 0.999499, 0.704590, 0.215752 }, { "deco_stone_1", 0.999337, 0.388435, 0.915690 },
		{ "rim_banner_1", 0.510560, 0.999568, 0.090820 }, { "rim_barrels_1", 0.985067, 0.674494, 0.925154 },
		{ "rim_crystal_pedestal_1", 0.746655, 0.999582, 0.641994 }, { "rim_crystal_shrine_1", 0.592705, 0.999512, 0.594046 },
		{ "rim_lantern_1", 0.530267, 0.999543, 0.326458 }, { "rim_ruin_arch_1", 0.936004, 0.521965, 0.406241 },
		{ "rim_ruin_column_1", 0.665495, 0.999719, 0.668392 }, { "rock_50", 0.981335, 0.870589, 1.000441 },
	}
	local function ownAssets()
		local package = Instance.new("Folder"); package.Name, package.Parent = "thronlande_pack", models
		for _, sample in samples do assetModel(package, sample[1], Vector3.new(sample[2], sample[3], sample[4])) end
		return package
	end
	originalMetricAssets()
	local package = ownAssets()
	for _, sample in samples do
		local category = sample[1]:match("^(.*)_%d+$")
		local model = Assets.place(category, CFrame.new(), { variant = sample[1], parent = workspace })
		expect(model and model.Name == sample[1], "D2-Vorlage fehlt: " .. sample[1])
		for _, part in model:GetDescendants() do if part:IsA("BasePart") then
			expect(part.Anchored and not part.CanCollide and not part.CanQuery and not part.CanTouch, "D2 fängt Eingaben ab")
		end end
		model:Destroy()
	end
	for category, dimensions in Config.ISLAND.rimScatter.sizes do
		for seed = 1, 30 do
			local board = Assets.place(category, CFrame.new(), { parent = workspace, key = tostring(seed) })
			local _, boardSize = board:GetBoundingBox()
			local limits = Config.ENVIRONMENT.categories[category]
			expect(boardSize.Y <= limits.height * Config.TILE_SIZE, "Brettdeko vergrößert")
			local rim = Assets.place(category, CFrame.new(), { parent = workspace, key = tostring(seed),
				height = dimensions.height, width = dimensions.width, rimSize = true, sizeVariation = 0.15 })
			local _, size = rim:GetBoundingBox()
			expect(size.Y >= dimensions.height * Config.TILE_SIZE * 0.85 - 0.001
				and size.Y <= dimensions.height * Config.TILE_SIZE * 1.15 + 0.001, "Randhöhe überschrieben")
			rim:Destroy(); board:Destroy()
		end
	end
	for category, name in Config.ENVIRONMENT.preferred do
		local model = Assets.place(category, CFrame.new(), { parent = workspace })
		expect(model and model.Name == name, "Bevorzugte Variante fehlt")
		model:Destroy()
	end
	for index = 1, 30 do
		local rock = Assets.place("rock", CFrame.new(), { key = tostring(index), parent = workspace })
		expect(rock and rock.Name ~= "rock_50", "Randfelsen in Brettmischung")
		rock:Destroy()
	end
	package:Destroy()
	for _, category in { "deco_grass", "deco_flower", "deco_stone" } do
		local model = Assets.place(category, CFrame.new(), { parent = workspace })
		expect(model ~= nil and model.Name ~= Config.ENVIRONMENT.preferred[category], "Alter Deko-Rückfall fehlt")
		model:Destroy()
	end
	package = ownAssets()
	local function signature(board, state)
		local rows, triangles, count = {}, 0, 0
		for _, asset in board:GetChildren() do if asset:GetAttribute("RimCategory") then
			local box, size = asset:GetBoundingBox()
			expect(Landscape.rimFits(state, box.Position - size / 2, box.Position + size / 2), "Randmodell auf Brett/Kante/Wasser")
			table.insert(rows, asset.Name .. ":" .. tostring(box.Position) .. ":" .. tostring(size))
			count += 1; triangles += asset:GetAttribute("EstimatedTriangles") or 0
		end end
		expect(count == board:GetAttribute("IslandProps") and count >= Config.ISLAND.rimScatter.count, "Rand zu leer/Zähler falsch")
		expect(triangles == board:GetAttribute("IslandPropEstimatedTriangles") and triangles > 0, "Dreiecksmessung fehlt")
		table.sort(rows); return table.concat(rows, "|")
	end
	Config.ISLAND.enabled = true
	for _, regionId in { "greenland", "swamp", "ice", "volcano" } do for seed = 1, 3 do
		local stage = Gen.generate(seed, "greenland", 1, "axe", RC.MAX_TEAM)
		Grid.setMap(stage.map)
		local board = Board.build(regionId, stage.features, stage)
		local state = Landscape.prepare(regionId .. ":" .. table.concat(stage.map, "|"), modules.Stages.getRegion(regionId), stage.features)
		local original = signature(board, state)
		expect(original == signature(Board.build(regionId, stage.features, stage), state), "D2-Rand nicht deterministisch")
	end end
	-- Unabhängige Negativproben: Brett, Inselkante, Flusskorridor, hohe Vorderobjekte.
	Grid.setMap({ "...", "W..", "..." })
	local state = Landscape.prepare("negativ", modules.Stages.getRegion("greenland"))
	expect(not Landscape.rimFits(state, Vector3.new(1, -1, 1), Vector3.new(3, 1, 3)), "Brettschutz fehlt")
	expect(not Landscape.rimFits(state, Vector3.new(-99, -1, 0), Vector3.new(-95, 1, 2)), "Kantenschutz fehlt")
	expect(not Landscape.rimFits(state, Vector3.new(-18, -1, 10), Vector3.new(-14, 1, 14)), "Flussabstand fehlt")
	expect(not Landscape.rimFits(state, Vector3.new(10, -1, 40), Vector3.new(12, 8, 42)), "Vorderkante verdeckt Brett")
	-- Stub-Profil absichtlich frei vorgeben: Übergang, fehlender Raycast und starke Asymmetrie.
	local previousRaycast = workspace.Raycast
	local mode = "pass"
	function workspace:Raycast(origin, direction, params)
		local model = params and params.FilterDescendantsInstances and params.FilterDescendantsInstances[1]
		if model and model.Name == "archbridge_2" then
			if mode == "miss" then return nil end
			local box, size = model:GetBoundingBox()
			local delta = model:GetAttribute("BridgeAlongX") and origin.X - box.Position.X or origin.Z - box.Position.Z
			return { Position = Vector3.new(origin.X, box.Position.Y - size.Y / 2 + 1 + delta * (mode == "slope" and 0.5 or 0.01), origin.Z) }
		end
		return previousRaycast(self, origin, direction, params)
	end
	for _, map in { { ".W.", ".B.", ".W." }, { "...", "WBW", "..." },
		{ ".WW.", ".BB.", ".WW." }, { "...", "WBW", "WBW", "..." } } do
		Grid.setMap(map)
		local own = Config.ENVIRONMENT.bridge.ownModel
		Config.ENVIRONMENT.bridge.ownModel = "fehlend"
		Board.build("greenland")
		local baseline = table.clone(Grid.getHeights())
		Config.ENVIRONMENT.bridge.ownModel = own
		for _, result in { "pass", "miss", "slope" } do
			mode = result
			local board = Board.build("greenland")
			expect((board:FindFirstChild("archbridge_2") ~= nil) == (result == "pass"), "Brückenfreigabe/Rückfall falsch")
			for _, crossing in Grid.bridgeCrossings() do
				for _, bank in crossing.banks do
					expect(Grid.getHeights()[Grid.key(bank.x, bank.y)] == baseline[Grid.key(bank.x, bank.y)], "Uferhöhe verändert")
				end
				for _, cell in crossing.cells do
					local key = Grid.key(cell.x, cell.y)
					expect(Grid.terrainAt(cell.x, cell.y).cost.foot == 1, "Brückenweg verändert")
					if result ~= "pass" then expect(Grid.getHeights()[key] == baseline[key], "Rückfall verändert Brückenprofil") end
				end
			end
			for key, value in baseline do
				local x, y = key:match("(%d+),(%d+)")
				if map[tonumber(y)]:sub(tonumber(x), tonumber(x)) ~= "B" then expect(Grid.getHeights()[key] == value, "Nachbarhöhe verändert") end
			end
			local visual = board:FindFirstChild("archbridge_2")
			if visual then for _, part in visual:GetDescendants() do if part:IsA("BasePart") then
				expect(not part.CanQuery and not part.CanCollide, "Brücke fängt Klick ab")
			end end end
		end
	end
	workspace.Raycast = previousRaycast
	print("OK: D2 (12 Vorlagen, bevorzugte Deko/Rückfall, 4 Gebiete × 3 Seeds, Randfreiheit/Determinismus, Brückenprofil/Ufer/Klickbarkeit/Rückfall).")
end
