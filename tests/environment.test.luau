-- Creator-Store-Pakete mit den echten Laderfunktionen prüfen.
local Assets = modules.EnvironmentAssets
local function assetModel(parent, name, size)
	local model = Instance.new("Model")
	model.Name, model.Parent = name, parent
	local part = Instance.new("MeshPart")
	part.Size, part.Parent = size or Vector3.new(3, 8, 3), model
	return model, part
end
local function freshAssets()
	models:Destroy()
	models = Instance.new("Folder")
	models.Name, models.Parent = "EnvironmentModels", services.ServerStorage
	return models
end
local package = Instance.new("Folder")
package.Name, package.Parent = "grasland_pack", freshAssets()
assetModel(package, "tree_1")
assetModel(package, "tree_2")
assetModel(models, "rock_1", Vector3.new(7.5, 1.6, 8))
for _, name in { "tree", "tree_0", "Tree_3", "tree_4_extra" } do assetModel(package, name) end
local material = Instance.new("MaterialVariant")
material.Name, material.Parent = "Rinde", package
expect(#Assets.variants("tree") == 2, "Paket-Bäume oder Namensfilter")
expect(#Assets.variants("rock") == 1, "Loser Fels nicht erkannt")
Assets.variants("bush")
expect(#services.MaterialService:GetChildren() == 1, "Material fehlt oder doppelt")
local tree = Assets.place("tree", CFrame.new(), { parent = workspace, key = "test" })
expect(tree ~= nil, "Paket-Baum nicht platzierbar")
for _, part in tree:GetDescendants() do
	if part:IsA("BasePart") then expect(part.Anchored and not part.CanCollide and not part.CanQuery and not part.CanTouch, "Asset fängt Eingaben ab") end
end
tree:Destroy()
local invalidMaterial = Instance.new("MaterialVariant")
invalidMaterial.Name, invalidMaterial.Archivable, invalidMaterial.Parent = "NichtKlonbar", false, package
local unsafeTree = assetModel(package, "tree_3")
local scriptPart = Instance.new("Script"); scriptPart.Parent = unsafeTree
local sound = Instance.new("Sound"); sound.Parent = unsafeTree
local cleanTree = Assets.place("tree", CFrame.new(), { key = "sauber", parent = workspace })
for _, variant in Assets.variants("tree") do for _, object in variant:GetDescendants() do
	expect(not object:IsA("BaseScript") and not object:IsA("Sound"), "Asset nicht bereinigt")
end end
expect(cleanTree ~= nil, "Nicht klonbares Material blockiert den Lader")
cleanTree:Destroy()
freshAssets()
expect(#Assets.variants("tree") == 0, "Paketwechsel lässt alte Vorlagen hängen")
print("OK: Creator-Store-Lader (Ordner, lose Modelle, Namen, Materialien, Klickbarkeit, Cachewechsel).")

do
	local model, crown = assetModel(workspace, "Kronentest")
	crown.Material = Enum.Material.LeafyGrass
	local appearance = Instance.new("SurfaceAppearance")
	appearance.AlphaMode, appearance.Parent = Enum.AlphaMode.Transparency, crown
	local trunk = Instance.new("MeshPart"); trunk.Material, trunk.Parent = Enum.Material.Wood, model
	local bark = Instance.new("SurfaceAppearance"); bark.AlphaMode, bark.Parent = Enum.AlphaMode.Overlay, trunk
	local oldTrunk = trunk.Color
	local tint = Assets.crownColor("gleiche Platzierung", Config.TREE_PALETTES.swamp)
	expect(tint == Assets.crownColor("gleiche Platzierung", Config.TREE_PALETTES.swamp), "Kronenfarbe nicht deterministisch")
	Assets.tintCrowns(model, tint)
	expect(appearance.Color == tint and trunk.Color == oldTrunk and bark.Color ~= tint, "Kronen-/Stammfärbung")
	appearance:SetAttribute("RejectColor", true)
	Assets.tintCrowns(model, tint)
	expect(crown.Color == tint and trunk.Color == oldTrunk, "MeshPart-Farbersatz fehlt")
	model:Destroy()
	local autumn = 0
	for i = 1, 1000 do
		local color = Assets.crownColor(tostring(i), Config.TREE_PALETTES.greenland)
		if color == Config.TREE_PALETTES.greenland[3].color or color == Config.TREE_PALETTES.greenland[4].color then autumn += 1 end
	end
	expect(autumn >= 60 and autumn <= 140, "Herbstmischung ohne ungefähr 10 Prozent")
	print("OK: Kronenfarben (Region, Determinismus, Stamm unverändert, SurfaceAppearance/Farbersatz, Herbstquote).")
end

-- Der Schalter stellt ausschließlich die bisherige Modell-Höhenschwelle wieder her.
do
	local oldShadows = Config.ENVIRONMENT.castShadows
	freshAssets()
	for _, category in { "tree", "bush", "rock", "deco_root", "deco_flower", "deco_grass", "deco_fence", "deco_stone" } do
		assetModel(models, category .. "_1", Vector3.new(4, 8, 4))
	end
	for _, enabled in { false, true } do
		Config.ENVIRONMENT.castShadows = enabled
		for _, category in { "tree", "bush", "rock", "deco_root", "deco_flower", "deco_grass", "deco_fence", "deco_stone" } do
			for _, height in { 0.3, 1.2 } do
				local model = Assets.place(category, CFrame.new(), { parent = workspace, key = "Schatten", height = height, width = 2, rotation = 0 })
				local _, size = model:GetBoundingBox()
				for _, part in model:GetDescendants() do if part:IsA("BasePart") then
					expect(part.CastShadow == (enabled and size.Y >= Config.ENVIRONMENT.shadowHeight * Config.TILE_SIZE), "Schatten-Schalter/Höhenschwelle")
				end end
				model:Destroy()
			end
		end
	end
	Config.ENVIRONMENT.castShadows = false
	Grid.setMap({ "F.MH", "...." })
	local function checkBoard(regionId)
		local board = Board.build(regionId)
		for _, part in board:GetDescendants() do if part:IsA("BasePart") then
			expect(part.CastShadow == false, "Umgebungsteil wirft echten Schatten")
		end end
		local ground = board:FindFirstChild("Ground"):FindFirstChild("Ground_1")
		local region = modules.Stages.getRegion(regionId)
		local baseColor = region.terrainColors and region.terrainColors.F or Config.TERRAIN.F.color
		local expected = baseColor:Lerp(Color3.fromRGB(0, 0, 0), Config.ENVIRONMENT.forest.groundShade)
		expect(math.abs(ground.Color.R - expected.R) < 0.000001 and math.abs(ground.Color.G - expected.G) < 0.000001
			and math.abs(ground.Color.B - expected.B) < 0.000001, "Waldboden nicht regional abgedunkelt")
	end
	checkBoard("greenland"); checkBoard("swamp")
	freshAssets()
	checkBoard("greenland"); checkBoard("swamp")
	Config.ENVIRONMENT.castShadows = oldShadows
	print("OK: Umgebung ohne Schatten (Modelle/Part-Fallback), alter Höhenschalter, ruhiger Waldboden.")
end
