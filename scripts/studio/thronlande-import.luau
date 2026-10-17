-- D2: importiertes FBX als zwölf Vorlagen für ServerStorage.EnvironmentModels vorbereiten.
-- Import-Model im Explorer auswählen, dieses Skript in der Studio-Befehlsleiste ausführen.
-- Danach Workspace.thronlande_pack → Save to File → assets/environment/thronlande_pack.rbxm.

local Selection = game:GetService("Selection")
local RunService = game:GetService("RunService")
local PACK_NAME = "thronlande_pack"
local NAMES = {
	"rim_ruin_column_1", "rim_banner_1", "rim_crystal_shrine_1", "rim_ruin_arch_1",
	"rim_lantern_1", "rim_crystal_pedestal_1", "archbridge_2", "deco_grass_2",
	"deco_flower_4", "rim_barrels_1", "deco_stone_1", "rock_50",
}

assert(not RunService:IsRunning(), "[D2-Import] Play/Run zuerst stoppen; Import nur im Edit-Modus.")
local selected = Selection:Get()
assert(#selected == 1 and selected[1]:IsA("Model") and selected[1]:IsDescendantOf(workspace),
	"[D2-Import] Genau das importierte Model im Workspace auswählen (Edit-Modus).")
local source = selected[1]
local existing = workspace:FindFirstChild(PACK_NAME)
assert(not existing or existing == source,
	"[D2-Import] Ein fertiger Paketordner existiert bereits. Erst speichern und aus dem Workspace entfernen.")

-- Erst alles prüfen; bei Importfehlern bleiben Quelle und Workspace unverändert.
local expected, found = {}, {}
for _, name in NAMES do expected[name] = true end
for _, object in source:GetDescendants() do
	if object:IsA("BasePart") then
		assert(object:IsA("MeshPart") and expected[object.Name],
			"[D2-Import] Unerwartetes Teil: " .. object.Name .. ". Objektnamen im 3D-Importer beibehalten.")
		assert(not found[object.Name], "[D2-Import] Doppeltes Modell: " .. object.Name)
		found[object.Name] = object
	end
end
for _, name in NAMES do
	assert(found[name], "[D2-Import] Modell fehlt: " .. name .. ". Alle zwölf Objekte importieren.")
end

local pack = Instance.new("Folder")
pack.Name = PACK_NAME
local ok, problem = pcall(function()
	for _, name in NAMES do
		local model = Instance.new("Model")
		model.Name = name
		model.Parent = pack
		local mesh = found[name]:Clone()
		mesh.Name = "Mesh"
		mesh.Parent = model
		-- Nur Bild-/Oberflächendaten gehören in die lokale Vorlage.
		for _, object in mesh:GetDescendants() do
			if not object:IsA("SurfaceAppearance") and not object:IsA("Decal") and not object:IsA("Texture") then
				object:Destroy()
			end
		end
		mesh.Anchored = true
		mesh.CanCollide = false
		mesh.CanQuery = false
		mesh.CanTouch = false
		mesh.Material = Enum.Material.SmoothPlastic
		mesh.Reflectance = 0
		local box, size = model:GetBoundingBox()
		assert(size.X > 0 and size.Y > 0 and size.Z > 0, "[D2-Import] Leeres Modell: " .. name)
		model.PrimaryPart = nil
		model.WorldPivot = CFrame.new(box.Position - Vector3.new(0, size.Y / 2, 0))
	end
end)
if not ok then
	pack:Destroy()
	error(problem)
end
pack.Parent = workspace
Selection:Set({ pack })
print("[D2-Import] Zwölf Vorlagen fertig, Pivot unten Mitte, verankert und ohne Kollision/Query.")
print("[D2-Import] Ausgewählten Ordner als assets/environment/thronlande_pack.rbxm speichern.")
print("[D2-Import] Das ursprüngliche Import-Model bleibt zur Sichtprüfung erhalten; danach beide aus dem Workspace entfernen.")
