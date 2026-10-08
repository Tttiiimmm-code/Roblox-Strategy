-- Feste Bodenschatten für Brett und Kampfszene; Vorlagen und Saal bleiben unverändert.
local Config = require(script.Parent.Config)
local Grid = require(script.Parent.Grid)

local UnitShadow = {}
local cache = setmetatable({}, { __mode = "k" })

function UnitShadow.remove(model)
	local shadow = model:FindFirstChild("UnitShadow")
	if shadow then shadow:Destroy() end
	cache[model] = nil
end

function UnitShadow.update(model, groundHeight)
	local root = model.PrimaryPart
	local shadow = model:FindFirstChild("UnitShadow")
	if not root or not shadow then return end
	local parts = cache[model]
	if not parts then
		parts = shadow:GetChildren()
		cache[model] = parts
	end
	local position = root.Position
	if groundHeight == nil then
		local x = math.floor(position.X / Config.TILE_SIZE) + 1
		local y = math.floor(position.Z / Config.TILE_SIZE) + 1
		groundHeight = Grid.tileHeight(x, y)
	end
	if parts.x == position.X and parts.z == position.Z and parts.height == groundHeight then return end
	parts.x, parts.z, parts.height = position.X, position.Z, groundHeight
	-- Root-Höhe und -Neigung ignorieren: Angriffe/Sprünge/Tod heben den Schatten nicht an.
	for i = 1, #parts do
		local part = parts[i]
		local height = groundHeight + part:GetAttribute("SurfaceOffset")
		part.CFrame = CFrame.new(position.X, height, position.Z) * CFrame.Angles(0, 0, math.pi / 2)
	end
end

function UnitShadow.create(model, groundHeight)
	UnitShadow.remove(model)
	local body = model:FindFirstChild("UpperTorso") or model:FindFirstChild("Torso") or model.PrimaryPart
	if not body then return end
	local feel = Config.FEEL
	local diameter = body.Size.X * feel.unitShadowWidth
	local horse = model:FindFirstChild("HorseBody")
	if horse then diameter = math.max(diameter, math.max(horse.Size.X, horse.Size.Z) * feel.unitShadowHorseWidth) end
	local shadow = Instance.new("Folder")
	shadow.Name = "UnitShadow"
	for i, layer in feel.unitShadowLayers do
		local part = Instance.new("Part")
		part.Name = "Scheibe" .. i
		part.Shape = Enum.PartType.Cylinder
		part.Size = Vector3.new(feel.unitShadowThickness, diameter * layer.size, diameter * layer.size)
		part.Color = feel.unitShadowColor
		part.Material = Enum.Material.SmoothPlastic
		part.Transparency = layer.transparency
		part.Anchored = true
		part.CanCollide = false
		part.CanQuery = false
		part.CanTouch = false
		part.CastShadow = false
		-- Die innere Scheibe liegt oben; sämtliche Schichten bleiben unter den Overlays.
		part:SetAttribute("SurfaceOffset", feel.unitShadowSurfaceOffset + (#feel.unitShadowLayers - i) * feel.unitShadowThickness)
		part.Parent = shadow
	end
	shadow.Parent = model
	UnitShadow.update(model, groundHeight)
end

return UnitShadow
