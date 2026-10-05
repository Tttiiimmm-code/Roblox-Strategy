-- Baut das Spielfeld aus Parts auf
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)
local Grid = require(Shared.Grid)

local BoardBuilder = {}
local lastTerrainRegion

local function deco(props, parent)
	local p = Instance.new("Part")
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false -- Klicks sollen das Feld darunter treffen
	p.CanTouch = false
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	for k, v in props do
		p[k] = v
	end
	p.Parent = parent
	return p
end

-- Dekoration in den Ecken, damit die Einheit in der Mitte sichtbar bleibt
local function decorate(ch, x, y, parent)
	local center = Grid.toWorld(x, y)
	local c = Config.TILE_SIZE / 2 - 1.3
	if ch == "F" then
		for _, off in { Vector3.new(-c, 0, -c), Vector3.new(c, 0, c) } do
			local base = center + off
			deco({ Shape = Enum.PartType.Cylinder, Size = Vector3.new(2, 0.6, 0.6),
				CFrame = CFrame.new(base + Vector3.new(0, 1, 0)) * CFrame.Angles(0, 0, math.rad(90)),
				Color = Color3.fromRGB(100, 70, 40), Material = Enum.Material.Wood }, parent)
			for layer = 1, 3 do
				local diameter = 3.2 - layer * 0.5
				deco({ Shape = Enum.PartType.Ball, Size = Vector3.new(diameter, 1.6, diameter), Position = base + Vector3.new(0, 1.8 + layer * 0.7, 0), Color = Color3.fromRGB(40, 100, 45), Material = Enum.Material.Grass }, parent)
			end
		end
	elseif ch == "M" then
		for _, off in { Vector3.new(-c, 0, -c), Vector3.new(c, 0, -c), Vector3.new(-c, 0, c) } do
			deco({ Size = Vector3.new(2.4, 2.2, 2.4),
				CFrame = CFrame.new(center + off + Vector3.new(0, 1.1, 0)) * CFrame.Angles(0, math.rad(45), 0),
				Color = Color3.fromRGB(120, 110, 100), Material = Enum.Material.Rock }, parent)
		end
	elseif ch == "B" then
		for _, side in { -1, 1 } do
			deco({ Size = Vector3.new(0.4, 1, Config.TILE_SIZE - 0.2),
				Position = center + Vector3.new(side * (Config.TILE_SIZE / 2 - 0.4), 0.5, 0),
				Color = Color3.fromRGB(110, 76, 46), Material = Enum.Material.Wood }, parent)
		end
	elseif ch == "H" then
		for _, off in { Vector3.new(-c, 0, -c), Vector3.new(c, 0, -c), Vector3.new(-c, 0, c), Vector3.new(c, 0, c) } do
			deco({ Size = Vector3.new(1.2, 3, 1.2), Position = center + off + Vector3.new(0, 1.5, 0),
				Color = Color3.fromRGB(150, 140, 130), Material = Enum.Material.Brick }, parent)
		end
	end
end

-- Einmal anlegen und behalten: Clients halten eine Referenz auf diesen Ordner
function BoardBuilder.ensureUnitsFolder()
	local units = workspace:FindFirstChild("Units")
	if not units then
		units = Instance.new("Folder")
		units.Name = "Units"
		units.Parent = workspace
	end
	return units
end

-- Baut die aktuelle Karte aus Grid.getMap() (vorher Grid.setMap aufrufen)
function BoardBuilder.build()
	-- Standard-Baseplate/Spawn würden mit dem Brett kollidieren
	for _, name in { "Baseplate", "SpawnLocation", "Board" } do
		local old = workspace:FindFirstChild(name)
		if old then
			old:Destroy()
		end
	end

	local T = Config.TILE_SIZE
	local terrain = workspace.Terrain
	local margin, depth = Config.FEEL.environmentMargin, Config.FEEL.terrainDepth
	local w, h = Grid.width() * T, Grid.height() * T
	if lastTerrainRegion then terrain:FillBlock(lastTerrainRegion.cf, lastTerrainRegion.size, Enum.Material.Air) end
	local size = Vector3.new(w + margin * 2, depth + Config.FEEL.terrainClearTop, h + margin * 2)
	local cf = CFrame.new(w / 2, (Config.FEEL.terrainClearTop - depth) / 2, h / 2)
	terrain:FillBlock(cf, size, Enum.Material.Air)
	lastTerrainRegion = { cf = cf, size = size }
	pcall(function() terrain.Decoration = false end)
	local function fillTerrain(sinkByChar)
		local groundSink = sinkByChar["."] or 0
		terrain:FillBlock(CFrame.new(w / 2, -depth / 2 - groundSink, h / 2), Vector3.new(w + margin * 2, depth, h + margin * 2), Enum.Material.Ground)
		terrain:FillBlock(CFrame.new(w / 2, -2 - groundSink, h / 2), Vector3.new(w + margin * 2, 4, h + margin * 2), Enum.Material.Grass)
		for y = 1, Grid.height() do
			for x = 1, Grid.width() do
				local definition = Grid.terrainAt(x, y)
				local center = Grid.toWorld(x, y)
				local ch = string.sub(Grid.getMap()[y], x, x)
				center -= Vector3.new(0, sinkByChar[ch] or 0, 0)
				terrain:FillBlock(CFrame.new(center.X, 2, center.Z), Vector3.new(T, 12, T), Enum.Material.Air)
				if definition.terrainMaterial == Enum.Material.Water then
					terrain:FillBlock(CFrame.new(center.X, -6, center.Z), Vector3.new(T, 4, T), Enum.Material.Sand)
					terrain:FillBlock(CFrame.new(center.X, (-4 + center.Y) / 2, center.Z), Vector3.new(T, 4 + center.Y, T), Enum.Material.Water)
				else
					terrain:FillBlock(CFrame.new(center.X, (-4 + center.Y) / 2, center.Z), Vector3.new(T, 4 + center.Y, T), definition.terrainMaterial)
					if definition.terrainMaterial == Enum.Material.Rock then
						for _, sign in { -1, 1 } do
							terrain:FillBall(center + Vector3.new(sign * 2.8, -1.3, ((x * 17 + y * 11) % 3) - 1), 2, Enum.Material.Rock)
						end
					end
				end
			end
		end
		end
	fillTerrain({})
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Include
	params.FilterDescendantsInstances = { terrain }
	local sink, measured, calibration = {}, {}, {}
	for y = 1, Grid.height() do
		for x = 1, Grid.width() do
			local ch = string.sub(Grid.getMap()[y], x, x)
			if ch ~= "W" and not measured[ch] then
				measured[ch] = true
				local center = Grid.toWorld(x, y)
				local hit = workspace:Raycast(center + Vector3.new(0, 20, 0), Vector3.new(0, -40, 0), params)
				if hit then
					local amount = hit.Position.Y - center.Y + Config.FEEL.terrainSurfaceMargin
					if amount > 0 then sink[ch] = amount end
				end
				table.insert(calibration, ("%s=%.3f"):format(ch, sink[ch] or 0))
			end
		end
	end
	terrain:FillBlock(cf, size, Enum.Material.Air)
	fillTerrain(sink)
	print("Terrain-Kalibrierung: " .. table.concat(calibration, ", "))
	local board = Instance.new("Folder")
	board.Name = "Board"

	for y = 1, Grid.height() do
		for x = 1, Grid.width() do
			local ch = string.sub(Grid.getMap()[y], x, x)
			local terrain = Config.TERRAIN[ch]
			local tile = Instance.new("Part")
			tile.Name = ("Tile_%d_%d"):format(x, y)
			tile.Anchored = true
			tile.Size = Vector3.new(T, 0.2, T)
			tile.Position = Grid.toWorld(x, y) - Vector3.new(0, 0.1, 0)
			tile.Transparency = 1
			tile.CanCollide = false
			tile.CanQuery = true
			tile.Color = terrain.color
			tile.Material = terrain.material
			tile.TopSurface = Enum.SurfaceType.Smooth
			tile:SetAttribute("X", x)
			tile:SetAttribute("Y", y)
			tile.Parent = board
			decorate(ch, x, y, board)
			local center = Grid.toWorld(x, y)
			for _, offset in { Vector3.new(-T / 2, 0, 0), Vector3.new(T / 2, 0, 0), Vector3.new(0, 0, -T / 2), Vector3.new(0, 0, T / 2) } do
				deco({ Name = "GridLine", Size = offset.X ~= 0 and Vector3.new(Config.FEEL.gridLineWidth, Config.FEEL.gridLineWidth, T) or Vector3.new(T, Config.FEEL.gridLineWidth, Config.FEEL.gridLineWidth), Position = center + offset + Vector3.new(0, 0.08, 0), Color = Color3.fromRGB(40, 45, 35), Transparency = Config.FEEL.gridTransparency }, board)
			end
		end
	end

	for i = 1, Config.FEEL.environmentCount do
		local edge = i % 4
		local fraction = ((i * 37) % 97) / 97
		local x = edge < 2 and (-16 - i % 3 * 7) or (w + 16 + i % 3 * 7)
		local z = fraction * h
		if edge % 2 == 1 then x, z = fraction * w, edge == 1 and -18 or h + 18 end
		if i % 3 == 0 then
			deco({ Name = "OuterRock", Size = Vector3.new(7, 6, 5), Position = Vector3.new(x, 2, z), Color = Config.TERRAIN.M.color, Material = Enum.Material.Rock }, board)
		else
			deco({ Name = "OuterTrunk", Size = Vector3.new(2, 9, 2), Position = Vector3.new(x, 4.5, z), Color = Color3.fromRGB(98, 70, 43), Material = Enum.Material.Wood }, board)
			deco({ Name = "OuterLeaves", Shape = Enum.PartType.Ball, Size = Vector3.new(11, 12, 11), Position = Vector3.new(x, 12, z), Color = Config.TERRAIN.F.color, Material = Enum.Material.Grass }, board)
		end
	end
	board.Parent = workspace
	return board
end

return BoardBuilder
