-- Facetten teilen denselben Umriss wie das Terrain; keine Texturen oder Partikel.
local Config = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared").Config)
local IslandBuilder = {}

local function hash(key)
	local value = 0
	for i = 1, #key do value = (value * 131 + key:byte(i)) % 2147483647 end
	return value
end

local function part(parent, name, size, cf, color, class, material)
	local object = Instance.new(class or "Part")
	object.Name, object.Size, object.CFrame = name, size, cf
	object.Color, object.Material = color, material or Enum.Material.SmoothPlastic
	object.Anchored, object.CanCollide, object.CanTouch, object.CanQuery, object.CastShadow = true, false, false, false, false
	object:SetAttribute("IslandPart", true)
	object.Parent = parent
	return object
end

-- Ein Dreieck wird entlang seiner längsten Seite in zwei rechtwinklige Keile geteilt.
local function triangle(parent, name, a, b, c, color, material)
	local ab, ac, bc = b - a, c - a, c - b
	if ab:Dot(ab) > ac:Dot(ac) and ab:Dot(ab) > bc:Dot(bc) then a, c = c, a
	elseif ac:Dot(ac) > bc:Dot(bc) then a, b = b, a end
	ab, ac, bc = b - a, c - a, c - b
	local cross = ac:Cross(ab)
	if cross.Magnitude < 0.001 then return end
	local right, back = cross.Unit, bc.Unit
	local up = back:Cross(right).Unit
	local height = math.abs(ab:Dot(up))
	local thickness = Config.ISLAND.facetThickness
	for _, data in { { b, right, back, math.abs(ab:Dot(back)) }, { c, right * -1, back * -1, math.abs(ac:Dot(back)) } } do
		if data[4] > 0.001 then
			part(parent, name, Vector3.new(thickness, height, data[4]), CFrame.fromMatrix((a + data[1]) / 2, data[2], up, data[3]), color, "WedgePart", material)
		end
	end
end

local function crystal(parent, center, width, height, color)
	local ring = { Vector3.new(width, 0, 0), Vector3.new(0, 0, width), Vector3.new(-width, 0, 0), Vector3.new(0, 0, -width) }
	local top, bottom = center + Vector3.new(0, height / 2, 0), center - Vector3.new(0, height / 2, 0)
	for index, offset in ring do
		local a, b = center + offset, center + ring[index % #ring + 1]
		triangle(parent, "ThroneCrystal", top, a, b, color, Enum.Material.Neon)
		triangle(parent, "ThroneCrystal", bottom, b, a, color, Enum.Material.Neon)
	end
	triangle(parent, "CrystalGlint", top + Vector3.new(0.04, 0, 0.04), center + Vector3.new(width + 0.04, 0, 0.04),
		center + Vector3.new(width * 0.55 + 0.04, 0, width * 0.45 + 0.04), Color3.fromRGB(255, 255, 255), Enum.Material.Neon)
end

local function shell(parent, points, center, earthDepth, depth)
	local s = Config.ISLAND
	local top = points[1].Y + s.edgeLip
	local earthBottom = points[1].Y - earthDepth
	for index, a in points do
		local b = points[index % #points + 1]
		local delta = b - a
		local inward = Vector3.new(-delta.Z, 0, delta.X).Unit
		local midpoint = (a + b) / 2 + inward * (s.edgeReserve - s.facetThickness)
		part(parent, "IslandEarth", Vector3.new(delta.Magnitude + s.edgeOverlap, top - earthBottom, s.edgeReserve * 2),
			CFrame.new(midpoint.X, (top + earthBottom) / 2, midpoint.Z) * CFrame.Angles(0, -math.atan2(delta.Z, delta.X), 0), s.earthColor)
		for layer = 1, #s.layerScales - 1 do
			local function point(v, level)
				local scale = s.layerScales[level]
				return Vector3.new(center.X + (v.X - center.X) * scale,
					earthBottom - (depth - earthDepth) * (level - 1) / (#s.layerScales - 1), center.Z + (v.Z - center.Z) * scale)
			end
			local p, q, r, t = point(a, layer), point(b, layer), point(a, layer + 1), point(b, layer + 1)
			local color = s.stoneColor:Lerp(s.earthColor, layer == 1 and 0.12 or 0)
			triangle(parent, "IslandStone", p, q, r, color)
			triangle(parent, "IslandStone", q, t, r, color)
		end
	end
end

function IslandBuilder.measure(board)
	local count, triangles = 0, 0
	for _, object in board:GetDescendants() do
		if object:IsA("BasePart") and object:GetAttribute("IslandPart") then
			count += 1
			triangles += object:IsA("WedgePart") and 8 or 12
		end
	end
	board:SetAttribute("IslandParts", count)
	board:SetAttribute("IslandEstimatedTriangles", triangles)
	return count
end

function IslandBuilder.build(board, state)
	if not state.island then return end
	local s, T = Config.ISLAND, Config.TILE_SIZE
	local folder = Instance.new("Folder")
	folder.Name, folder.Parent = "Island", board
	local center = Vector3.new(state.w / 2, s.surfaceHeight, state.h / 2)
	shell(folder, state.outline, center, s.earthTiles * T, s.depthTiles * T)
	local random = Random.new(hash(state.key .. ":island"))
	local count = random:NextInteger(s.crystalCount.min, s.crystalCount.max)
	local accent = s.accents[state.region and state.region.id or "greenland"] or s.accents.greenland
	for index = 1, count do
		local angle = (index - 1) * math.pi * 2 / count + random:NextNumber(-0.3, 0.3)
		local position = center + Vector3.new(math.cos(angle) * state.w * 0.32, -s.depthTiles * T * s.crystalDepth, math.sin(angle) * state.h * 0.32)
		crystal(folder, position, s.crystalWidth, s.crystalHeight, accent)
	end
	board:SetAttribute("IslandCrystals", count)
	IslandBuilder.measure(board)
end

return IslandBuilder
