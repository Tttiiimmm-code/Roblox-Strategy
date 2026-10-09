-- Originalmaße aus PLAN.md; Mesh-Dreiecke sind ausdrücklich Schätzwerte je Vorlage.
local function metricAssets()
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
	return maxTriangles
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
boardMetrics("mit Kategorie-Stubs")
freshAssets()
