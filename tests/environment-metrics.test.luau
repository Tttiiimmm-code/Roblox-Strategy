-- Originalmaße aus PLAN.md; Mesh-Dreiecke sind ausdrücklich Schätzwerte je Vorlage.
local function metricAssets()
	if originalMetricAssets then originalMetricAssets(); return end
	freshAssets()
	local function sample(name, size, triangles)
		local model, part = assetModel(models, name, size)
		part:SetAttribute("EstimatedTriangles", triangles)
		return model, part
	end
	for _, category in { "tree", "bush" } do
		local model, crown = sample(category .. "_1", category == "tree" and Vector3.new(4, 6, 4) or Vector3.new(8, 5, 8), 1200)
		crown.Position, crown.Material = Vector3.new(0, category == "tree" and 5 or 5.5, 0), Enum.Material.LeafyGrass
		local appearance = Instance.new("SurfaceAppearance")
		appearance.AlphaMode, appearance.Parent = Enum.AlphaMode.Transparency, crown
		local trunk = Instance.new("MeshPart")
		trunk.Size, trunk.Position, trunk.Material, trunk.Parent = Vector3.new(0.8, 5, 0.8), Vector3.new(0, 2.5, 0), Enum.Material.Wood, model
		trunk:SetAttribute("EstimatedTriangles", 300)
	end
	sample("rock_1", Vector3.new(7.5, 1.6, 8), 800)
	sample("rock_2", Vector3.new(5, 8, 6), 800)
	sample("deco_root_1", Vector3.new(8, 2, 5), 500)
	sample("deco_grass_1", Vector3.new(4.7, 8, 4.8), 300)
	sample("deco_stone_1", Vector3.new(8, 2, 5), 800)
	local flower, stem = sample("deco_flower_1", Vector3.new(1, 7, 1), 150)
	local petals = Instance.new("MeshPart")
	petals.Size, petals.Position, petals.Parent = Vector3.new(4, 1, 4), Vector3.new(0, 4, 0), flower
	petals:SetAttribute("EstimatedTriangles", 200)
	local fence, first = sample("deco_fence_1", Vector3.new(0.2, 3, 8), 200)
	for i = 1, 9 do local p = first:Clone(); p.Parent = fence end
	sample("archbridge_1", Vector3.new(8, 2.1, 2.3), 2000)
end
local function boardMetrics(label)
	local sumParts, maxParts, sumTriangles, maxTriangles, seconds = 0, 0, 0, 0, 0
	for seed = 1, 100 do
		local stage = Gen.generate(seed, "greenland", 1, "axe", RC.MAX_TEAM)
		Grid.setMap(stage.map)
		local start = os.clock()
		local board = Board.build("greenland", stage.features, stage)
		validateOuter(board)
		seconds += os.clock() - start
		local count, triangles = 0, 0
		for _, p in board:GetDescendants() do
			if p:IsA("BasePart") then
				count += 1
				triangles += p:GetAttribute("EstimatedTriangles") or (p.Shape == Enum.PartType.Ball and 288 or p.Shape == Enum.PartType.Cylinder and 128 or p:IsA("WedgePart") and 8 or 12)
			end
		end
		sumParts += count; maxParts = math.max(maxParts, count)
		sumTriangles += triangles; maxTriangles = math.max(maxTriangles, triangles)
	end
	print(string.format("C2-Messung %s: 100 Seeds, Teile Mittel %.1f / Max %d; Dreiecke geschaetzt Mittel %.0f / Max %d; Stub-Aufbau Mittel %.2f ms.", label, sumParts / 100, maxParts, sumTriangles / 100, maxTriangles, seconds * 10))
	return maxTriangles, sumTriangles / 100
end
metricAssets()
do
	freshAssets()
	assetModel(models, "rock_1", Vector3.new(8, 8, 8))
	Grid.setMap({ "MMMM", "CCCC" })
	local rocks = Board.build("greenland")
	local minWidth, maxWidth, count = math.huge, 0, 0
	for _, object in rocks:GetChildren() do
		if object:IsA("Model") and object.Name == "rock_1" then
			local box, size = object:GetBoundingBox()
			if box.Position.X >= 0 and box.Position.X <= 32 and box.Position.Z >= 0 and box.Position.Z <= 16 then
				minWidth, maxWidth, count = math.min(minWidth, size.X), math.max(maxWidth, size.X), count + 1
				for _, p in object:GetDescendants() do if p:IsA("BasePart") then expect(not p.CanQuery, "Fels blockiert Feldklick") end end
			end
		end
	end
	expect(count >= 12 and maxWidth / minWidth > 1.7, "Felsen ohne sichtbare Größenstreuung")
	local stone = Assets.place("deco_stone", CFrame.new(), { key = "Steinchen", parent = workspace })
	local _, size = stone:GetBoundingBox()
	expect(size.X <= Config.ENVIRONMENT.categories.deco_stone.width * Config.TILE_SIZE * 1.01, "Felsersatz ist kein Steinchen")
	stone:Destroy()
	print("OK: Felsen (Größenstreuung, Klippen, Klickbarkeit, Steinchen aus Felsvarianten).")
end
metricAssets()
Grid.setMap({ "F" })
local forest = Board.build("greenland")
local forestTrees = 0
for _, object in forest:GetChildren() do
	if object:IsA("Model") and object.Name:match("^tree_") and object:GetPivot().Position.X >= 0 and object:GetPivot().Position.X <= Config.TILE_SIZE
		and object:GetPivot().Position.Z >= 0 and object:GetPivot().Position.Z <= Config.TILE_SIZE then forestTrees += 1 end
end
expect(forestTrees >= 2 and forestTrees <= 3, "Dichter Wald ohne 2–3 Bäume")
-- Union der tats?chlichen Kronen-AABBs: gleichm??iges 32x32-Sampling je Waldfeld.
local function forestCoverage(baseline)
	local oldForest, originalPlace = Config.ENVIRONMENT.forest, Assets.place
	if baseline then
		Config.ENVIRONMENT.forest = table.clone(oldForest)
		Config.ENVIRONMENT.forest.treeHeight = { min = 1, max = 1.4 }
		Config.ENVIRONMENT.forest.treeWidth = { min = 0.6, max = 0.9 }
		Assets.place = function(category, cf, opts)
			if opts.crownWidth then opts.width, opts.crownWidth = opts.crownWidth, nil end
			return originalPlace(category, cf, opts)
		end
	end
	Grid.setMap({ "FFFF", "FFFF", "FFFF", "FFFF" })
	local board, boxes = Board.build("greenland"), {}
	local minWidth, maxWidth, minHeight, maxHeight = math.huge, 0, math.huge, 0
	for _, model in board:GetChildren() do
		if not model:IsA("Model") or not model.Name:match("^tree_") then continue end
		local box, size = model:GetBoundingBox()
		if box.Position.X < 0 or box.Position.X > 32 or box.Position.Z < 0 or box.Position.Z > 32 then continue end
		minHeight, maxHeight = math.min(minHeight, size.Y), math.max(maxHeight, size.Y)
		for _, part in model:GetDescendants() do
			if not part:IsA("BasePart") or part.Material ~= Enum.Material.LeafyGrass then continue end
			local loX, hiX, loZ, hiZ = math.huge, -math.huge, math.huge, -math.huge
			for _, dx in { -1, 1 } do for _, dz in { -1, 1 } do
				local p = part.CFrame:PointToWorldSpace(Vector3.new(dx * part.Size.X / 2, 0, dz * part.Size.Z / 2))
				loX, hiX, loZ, hiZ = math.min(loX, p.X), math.max(hiX, p.X), math.min(loZ, p.Z), math.max(hiZ, p.Z)
			end end
			local width = math.max(hiX - loX, hiZ - loZ)
			minWidth, maxWidth = math.min(minWidth, width), math.max(maxWidth, width)
			table.insert(boxes, { loX, hiX, loZ, hiZ })
		end
	end
	local covered = 0
	for y = 1, 128 do for x = 1, 128 do
		local px, pz = (x - 0.5) / 4, (y - 0.5) / 4
		for _, b in boxes do if px >= b[1] and px <= b[2] and pz >= b[3] and pz <= b[4] then covered += 1; break end end
	end end
	Config.ENVIRONMENT.forest, Assets.place = oldForest, originalPlace
	local coverage = covered / (128 * 128)
	print(string.format("Wald %s: Kronen %.2f-%.2f Felder; Hoehe %.2f-%.2f; AABB-Abdeckung %.2f%%.", baseline and "vorher" or "nachher", minWidth / 8, maxWidth / 8, minHeight / 8, maxHeight / 8, coverage * 100))
	return coverage, minWidth / 8, maxWidth / 8, minHeight / 8, maxHeight / 8
end
local oldCoverage = forestCoverage(true)
local coverage, minCrown, maxCrown, minTree, maxTree = forestCoverage(false)
expect(coverage >= 0.85 and coverage > oldCoverage, "Wald ohne geschlossenes Kronendach")
expect(minCrown >= 1.1 and maxCrown <= 1.501 and minTree >= 1.299 and maxTree <= 1.801, "Waldmasse ausserhalb WIP-Ziel")

do
	local stage = Gen.generate(17, "greenland", 1, "axe", RC.MAX_TEAM)
	local function signature()
		Grid.setMap(stage.map)
		local board = Board.build("greenland", stage.features, stage)
		local rows = {}
		for _, object in board:GetDescendants() do
			if object:IsA("BasePart") then table.insert(rows, object.Name .. ":" .. tostring(object.Position) .. ":" .. tostring(object.Size)) end
		end
		return table.concat(rows, "|")
	end
	expect(signature() == signature(), "Brett-Deko mit Originalvarianten nicht deterministisch")
end
local _, meanTriangles = boardMetrics("mit Paket-Fixtures")
expect(meanTriangles <= Config.ENVIRONMENT.estimatedTriangleBudget, "Typisches Dreieckbudget überschritten: " .. meanTriangles)
freshAssets()
Grid.setMap({ "......", "......", "......" })
validateOuter(Board.build("greenland"))
print("OK: Waldrand (100 Paket-Seeds, Part-Fallback, alle Seiten geschlossen, kein Brettueberhang).")
