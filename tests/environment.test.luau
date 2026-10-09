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
