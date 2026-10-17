-- Throne Tales: ausgewählte Creator-Store-Modelle als ein Paket laden.
-- In Studio: gesamten Inhalt in die Befehlsleiste (Ansicht → Befehlsleiste) einfügen, Enter.
-- Ergebnis: Workspace.grasland_pack (Ordner). Prüfen, dann Rechtsklick → Save to File →
-- assets/environment/grasland_pack.rbxm und den Ordner danach aus dem Workspace löschen.

local PACK_NAME = "grasland_pack"
local PREVIEW_SIZE = 8 -- Vorschau: größte Seite in Studs; das Spiel skaliert später selbst
local PACKS = {
	{ id = 79689531752352, mode = "yasu" }, -- Yasu's Stylized Tree Pack (mvyasu)
	{ id = 139056934028989, category = "rock", split = true }, -- Stylized Rock Pack (nizendo)
	{ id = 7874817366, category = "deco_flower" }, -- Blue Flowers (Galaxy_girl644YT)
	{ id = 7874807261, category = "deco_flower" }, -- Red Flowers (Galaxy_girl644YT)
	{ id = 7874815586, category = "deco_flower" }, -- Yellow Flowers (Galaxy_girl644YT)
	{ id = 284474671, category = "deco_grass" }, -- Grass (Mistertitanic44)
	{ id = 3630530894, category = "deco_fence" }, -- Wooden Fence (Eikezan)
	{ id = 5239084052, category = "archbridge" }, -- Wooden Bridge (Justinnk231), gewölbt: Einbau in C2
}

local MaterialService = game:GetService("MaterialService")
local InsertService = game:GetService("InsertService")

local function unsafe(object)
	return object:IsA("BaseScript") or object:IsA("ModuleScript") or object:IsA("Sound")
		or object:IsA("ClickDetector") or object:IsA("ProximityPrompt")
		or object:IsA("ParticleEmitter") or object:IsA("Fire") or object:IsA("Smoke")
		or object:IsA("Sparkles") or object:IsA("Trail") or object:IsA("Beam")
end

local function load(id)
	local ok, objects = pcall(function() return game:GetObjects("rbxassetid://" .. id) end)
	if ok and objects and #objects > 0 then return objects end
	local ok2, model = pcall(function() return InsertService:LoadAsset(id) end)
	if ok2 and model then return model:GetChildren() end
	warn(("[Import] %d konnte nicht geladen werden"):format(id))
	return {}
end

local function hasDirectPart(model)
	for _, child in model:GetChildren() do
		if child:IsA("BasePart") then return true end
	end
	return false
end

-- Ein Eintrag = Model mit eigenen Teilen oder einzelner Part; Ordner/Hüllen werden durchlaufen.
local function collect(object, items, materials, split)
	if object:IsA("MaterialVariant") then
		table.insert(materials, object)
	elseif object:IsA("BasePart") then
		table.insert(items, object)
	elseif object:IsA("Model") and hasDirectPart(object) and not split then
		table.insert(items, object)
	elseif object:IsA("Model") or object:IsA("Folder") then
		for _, child in object:GetChildren() do collect(child, items, materials, split) end
	end
end

local function yasuCategory(item, roots)
	local parentName = roots[item.Parent] and "" or item.Parent.Name
	local text = (parentName .. "/" .. item.Name):lower()
	if text:find("bush") then return "bush" end
	if text:find("root") then return "deco_root" end
	if text:find("leaf") and not text:find("tree") then return nil end
	if text:find("tree") then return "tree" end
	return nil
end

local old = workspace:FindFirstChild(PACK_NAME)
if old then old:Destroy() end
local pack = Instance.new("Folder")
pack.Name = PACK_NAME
local materialFolder = Instance.new("Folder")
materialFolder.Name = "materials"
materialFolder.Parent = pack

local counts, skipped, removed = {}, {}, 0
local row = 0
for _, entry in PACKS do
	local roots, items, materials = {}, {}, {}
	for _, root in load(entry.id) do
		roots[root] = true
		collect(root, items, materials, entry.split)
	end
	for _, material in materials do
		material.Parent = materialFolder
		if not MaterialService:FindFirstChild(material.Name) then material:Clone().Parent = MaterialService end
	end
	local column = 0
	for _, item in items do
		local category = entry.category or yasuCategory(item, roots)
		if not category then
			table.insert(skipped, item:GetFullName())
			continue
		end
		counts[category] = (counts[category] or 0) + 1
		local model = Instance.new("Model")
		model.Name = ("%s_%d"):format(category, counts[category])
		item.Parent = model
		for _, object in model:GetDescendants() do
			if unsafe(object) then
				object:Destroy()
				removed += 1
			elseif object:IsA("BasePart") then
				object.Anchored = true
			end
		end
		local _, size = model:GetBoundingBox()
		local largest = math.max(size.X, size.Y, size.Z)
		if largest > 0 then model:ScaleTo(PREVIEW_SIZE / largest) end
		local box, scaled = model:GetBoundingBox()
		local target = Vector3.new(5000 + column * (PREVIEW_SIZE + 4), scaled.Y / 2, row * (PREVIEW_SIZE + 6))
		model:PivotTo(model:GetPivot() + (target - box.Position))
		model.Parent = pack
		column += 1
	end
	row += 1
end
pack.Parent = workspace

local lines = {}
for category, count in counts do table.insert(lines, ("%s: %d"):format(category, count)) end
table.sort(lines)
print("[Import] Fertig – " .. table.concat(lines, ", ") .. (" | Materialien: %d | entfernt: %d"):format(#materialFolder:GetChildren(), removed))
if #skipped > 0 then print("[Import] Übersprungen: " .. table.concat(skipped, "; ")) end
local camera = workspace.CurrentCamera
camera.CFrame = CFrame.lookAt(Vector3.new(5000 - 20, 40, -30), Vector3.new(5000 + 40, 0, 30))
