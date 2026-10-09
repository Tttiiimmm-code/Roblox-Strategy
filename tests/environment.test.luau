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
