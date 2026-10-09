-- Geprüfte Umgebungs-Vorlagen bleiben serverseitig; fehlende Kategorien liefern nil.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local MaterialService = game:GetService("MaterialService")
local Config = require(ReplicatedStorage:WaitForChild("Shared").Config)

local EnvironmentAssets = {}
local folder
local connections = {}
local cache = {}
local warned = {}

local function warnOnce(name, reason)
	if warned[name] then return end
	warned[name] = true
	warn(("Umgebungs-Asset %s: %s"):format(name, reason))
end

local function clearCache()
	for _, variants in cache do
		for _, template in variants do template:Destroy() end
	end
	cache = {}
end

local function assetFolder()
	local current = ServerStorage:FindFirstChild("EnvironmentModels")
	if current ~= folder then
		for _, connection in connections do connection:Disconnect() end
		connections = {}
		clearCache()
		folder = current
		if folder then
			table.insert(connections, folder.DescendantAdded:Connect(clearCache))
			table.insert(connections, folder.DescendantRemoving:Connect(clearCache))
		end
	end
	return folder
end

local function unsafe(object)
	return object:IsA("BaseScript") or object:IsA("ModuleScript") or object:IsA("Sound")
		or object:IsA("ClickDetector") or object:IsA("ProximityPrompt")
		or object:IsA("ParticleEmitter") or object:IsA("Fire") or object:IsA("Smoke")
		or object:IsA("Sparkles") or object:IsA("Trail") or object:IsA("Beam")
end

local function prepare(source)
	if not source:IsA("Model") and not source:IsA("BasePart") then
		warnOnce(source.Name, "nur Model oder BasePart erlaubt")
		return nil
	end
	local ok, copy = pcall(function() return source:Clone() end)
	if not ok or not copy then
		warnOnce(source.Name, "Vorlage ist nicht klonbar")
		return nil
	end
	local template = Instance.new("Model")
	template.Name = source.Name
	copy.Parent = template
	local count, removed = 0, 0
	for _, object in template:GetDescendants() do
		if unsafe(object) then
			object:Destroy()
			removed += 1
		elseif object:IsA("BasePart") then
			count += 1
			object.Anchored = true
			object.CanCollide = false
			object.CanQuery = false
			object.CanTouch = false
			object.CastShadow = false
		end
	end
	if count == 0 then
		warnOnce(source.Name, "keine Teile enthalten")
		template:Destroy()
		return nil
	end
	local _, size = template:GetBoundingBox()
	if size.X <= 0 or size.Y <= 0 or size.Z <= 0 or size.Magnitude >= math.huge then
		warnOnce(source.Name, "ungültige Abmessungen")
		template:Destroy()
		return nil
	end
	if removed > 0 then warnOnce(source.Name, ("%d Skripte/Effekte/Interaktionen entfernt"):format(removed)) end
	return template
end

function EnvironmentAssets.variants(category)
	local current = assetFolder()
	if cache[category] then return cache[category] end
	local result = {}
	if current then
		-- Pakete dürfen als Ordner in einer Datei liegen; Materialien (z. B. Rinde) wirken nur im MaterialService.
		local sources = {}
		for _, source in current:GetDescendants() do
			if source:IsA("MaterialVariant") then
				if not MaterialService:FindFirstChild(source.Name) then
					local ok, material = pcall(function() return source:Clone() end)
					if ok and material then material.Parent = MaterialService
					else warnOnce(source.Name, "Materialvorlage ist nicht klonbar") end
				end
			elseif source.Parent:IsA("Folder") then
				table.insert(sources, source)
			end
		end
		table.sort(sources, function(a, b) return a.Name < b.Name end)
		for _, source in sources do
			local kind, number = source.Name:match("^([%l_]+)_(%d+)$")
			if kind == category and tonumber(number) > 0 then
				local template = prepare(source)
				if template then table.insert(result, template) end
			end
		end
	end
	cache[category] = result
	return result
end

local function randomFor(key)
	local seed = 0
	for i = 1, #key do seed = (seed * 131 + string.byte(key, i)) % 2147483647 end
	return Random.new(seed)
end

function EnvironmentAssets.crownColor(key, palette)
	palette = palette or Config.TREE_PALETTES.greenland
	local total = 0
	for _, entry in palette do total += entry.weight end
	local choice = randomFor(tostring(key) .. ":crown"):NextNumber(0, total)
	for _, entry in palette do
		choice -= entry.weight
		if choice <= 0 then return entry.color end
	end
	return palette[#palette].color
end

function EnvironmentAssets.tintCrowns(model, color)
	for _, part in model:GetDescendants() do
		if not part:IsA("MeshPart") then continue end
		local appearance
		for _, child in part:GetChildren() do if child:IsA("SurfaceAppearance") then appearance = child; break end end
		if part.Material == Enum.Material.LeafyGrass or (appearance and appearance.AlphaMode == Enum.AlphaMode.Transparency) then
			local ok = appearance and pcall(function() appearance.Color = color end)
			if not ok then
				if appearance then warnOnce("SurfaceAppearance.Color", "Kronenfärbung nicht verfügbar; MeshPart.Color als Ersatz") end
				part.Color = color
			end
		end
	end
end

function EnvironmentAssets.attachRoot(tree, key)
	local trunk
	for _, part in tree:GetDescendants() do
		if part:IsA("MeshPart") and part.Material == Enum.Material.Wood
			and (not trunk or part.Size.Y > trunk.Size.Y) then trunk = part end
	end
	if not trunk then return nil end
	local settings = Config.ENVIRONMENT.rootFoot
	local foot = trunk.CFrame:PointToWorldSpace(Vector3.new(0, -trunk.Size.Y / 2, 0))
	local width = math.max(trunk.Size.X, trunk.Size.Z) * settings.widthScale
	local root = EnvironmentAssets.place("deco_root", CFrame.new(foot - Vector3.new(0, settings.sink, 0)), {
		parent = tree, key = tostring(key) .. ":foot", width = width / Config.TILE_SIZE,
		height = width / Config.TILE_SIZE, sizeVariation = 0,
	})
	if root then root:SetAttribute("RootFoot", true) end
	return root
end

function EnvironmentAssets.place(category, cframe, opts)
	opts = opts or {}
	local variants = EnvironmentAssets.variants(category)
	if category == "deco_stone" and #variants == 0 then variants = EnvironmentAssets.variants("rock") end
	local definition = Config.ENVIRONMENT.categories[category]
	if #variants == 0 or not definition then return nil end
	local random = randomFor(tostring(opts.key or cframe.Position) .. ":" .. category)
	local model = variants[random:NextInteger(1, #variants)]:Clone()
	if category == "tree" or category == "bush" then
		EnvironmentAssets.tintCrowns(model, EnvironmentAssets.crownColor(opts.key or tostring(cframe.Position), opts.palette))
	end
	local _, size = model:GetBoundingBox()
	local height = (opts.height or definition.height) * Config.TILE_SIZE
	local width = (opts.width or definition.width) * Config.TILE_SIZE
	local angle = opts.rotation
	if angle == nil then
		local mode = opts.rotationMode or definition.rotation
		angle = mode == "quarter" and random:NextInteger(0, 3) * math.pi / 2
			or mode == "free" and random:NextNumber(0, math.pi * 2) or 0
	end
	local spread = opts.sizeVariation or Config.ENVIRONMENT.sizeVariation
	-- Auch die größte Zufallsvariante bleibt innerhalb der konfigurierten Grenzen.
	local scale = math.min(height / size.Y, width / math.max(math.abs(math.cos(angle)) * size.X + math.abs(math.sin(angle)) * size.Z,
			math.abs(math.sin(angle)) * size.X + math.abs(math.cos(angle)) * size.Z))
		* random:NextNumber(1 - spread, 1 + spread) / (1 + spread)
	-- Die Vorlage verläuft entlang X; jede Querung bekommt exakt ihre Spannweite.
	-- Wald: Höhe bestimmt die Stammskalierung; schmale Kronen erhalten ihre eigene Breite.
	if category == "tree" and opts.crownWidth then scale = height / size.Y end
	if category == "archbridge" and opts.length then scale = opts.length * Config.TILE_SIZE / size.X end
	model:ScaleTo(scale)
	local box, scaledSize = model:GetBoundingBox()
	local transform = cframe * CFrame.Angles(0, angle, 0) * CFrame.new(0, scaledSize.Y / 2, 0) * box:Inverse()
	model:PivotTo(transform * model:GetPivot())
	for _, object in model:GetDescendants() do
		if object:IsA("BasePart") then
			local appearance = object:FindFirstChildOfClass("SurfaceAppearance")
			if opts.crownWidth and object:IsA("MeshPart") and (object.Material == Enum.Material.LeafyGrass
				or (appearance and appearance.AlphaMode == Enum.AlphaMode.Transparency)) then
				local lo, hi = Vector3.new(math.huge, 0, math.huge), Vector3.new(-math.huge, 0, -math.huge)
				for _, x in { -1, 1 } do for _, z in { -1, 1 } do
					local p = object.CFrame:PointToWorldSpace(Vector3.new(x * object.Size.X / 2, 0, z * object.Size.Z / 2))
					lo = Vector3.new(math.min(lo.X, p.X), 0, math.min(lo.Z, p.Z))
					hi = Vector3.new(math.max(hi.X, p.X), 0, math.max(hi.Z, p.Z))
				end end
				local factor = opts.crownWidth * Config.TILE_SIZE / math.max(hi.X - lo.X, hi.Z - lo.Z)
				object.Size = Vector3.new(object.Size.X * factor, object.Size.Y, object.Size.Z * factor)
			end
			object.CastShadow = Config.ENVIRONMENT.castShadows and scaledSize.Y >= Config.ENVIRONMENT.shadowHeight * Config.TILE_SIZE
		end
	end
	model.Parent = opts.parent
	if category == "tree" then EnvironmentAssets.attachRoot(model, opts.key or tostring(cframe.Position)) end
	return model
end

return EnvironmentAssets
