-- Baut das Spielfeld aus Parts auf
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)
local Grid = require(Shared.Grid)
local Stages = require(Shared.Stages)

local BoardBuilder = {}
local lastTerrainRegion

local function deco(props, parent)
	local p = Instance.new("Part")
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false -- Klicks sollen das Feld darunter treffen
	p.CanTouch = false
	p.CastShadow = false
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
	elseif ch == "S" then
		local puddle = center + Vector3.new(((x * 17 + y * 11) % 5 - 2) * 0.5, 0, ((x * 13 + y * 19) % 5 - 2) * 0.5)
		deco({ Name = "SwampPuddle", Size = Vector3.new(Config.FEEL.swampPuddleSize.X, Config.FEEL.groundCapHeight, Config.FEEL.swampPuddleSize.Z),
			Position = puddle + Vector3.new(0, Config.FEEL.swampPuddleSurfaceOffset - Config.FEEL.groundCapHeight / 2, 0),
			Color = Config.TERRAIN.D.color, Material = Enum.Material.SmoothPlastic }, parent)
		for i = 1, 3 + (x + y) % 2 do
			local off = Vector3.new(((x * 17 + y * 11 + i * 7) % 2 == 0 and -1 or 1) * c, 0,
				((x * 13 + y * 19 + i * 5) % 7 / 3 - 1) * c)
			local stalk = CFrame.new(center + off + Vector3.new(0, 0.8, 0)) * CFrame.Angles(math.rad(i * 7), 0, math.rad(80 + i * 4))
			deco({ Shape = Enum.PartType.Cylinder, Size = Vector3.new(1.6, 0.15, 0.15), CFrame = stalk,
				Color = Color3.fromRGB(110, 120, 60), Material = Enum.Material.Grass }, parent)
			deco({ Name = "ReedTip", Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.5, 0.25, 0.25),
				CFrame = stalk * CFrame.new(0.8, 0, 0), Color = Color3.fromRGB(80, 50, 30), Material = Enum.Material.Wood }, parent)
		end
	elseif ch == "D" then
		local waterY = center.Y
		for i = 1, 3 do
			local off = Vector3.new(((x * 7 + y * 3 + i * 5) % 5 - 2) * 0.9, 0, ((x * 5 + y * 11 + i * 3) % 5 - 2) * 0.9)
			deco({ Name = "LilyPad", Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.08, 1.3, 1.3),
				CFrame = CFrame.new(center.X + off.X, waterY + 0.04, center.Z + off.Z) * CFrame.Angles(0, 0, math.rad(90)),
				Color = Color3.fromRGB(70, 120, 55), Material = Enum.Material.SmoothPlastic }, parent)
		end
		for i = 1, 1 + (x + y) % 2 do
			local off = Vector3.new(i == 1 and -c or c, 0.6, ((x * 17 + y * 11) % 3 - 1) * c)
			deco({ Shape = Enum.PartType.Cylinder, Size = Vector3.new(1.6, 0.7, 0.7),
				CFrame = CFrame.new(center + off) * CFrame.Angles(math.rad(15), 0, math.rad(65)),
				Color = Color3.fromRGB(55, 45, 35), Material = Enum.Material.Wood }, parent)
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
function BoardBuilder.build(regionId)
	local region = Stages.getRegion(regionId)
	local treeColor = region and region.treeColor or Config.TERRAIN.F.color
	for _, name in { "Baseplate", "SpawnLocation", "Board" } do
		local old = workspace:FindFirstChild(name)
		if old then old:Destroy() end
	end
	local T = Config.TILE_SIZE
	local margin, depth = Config.FEEL.environmentMargin, Config.FEEL.terrainDepth
	local w, h = Grid.width() * T, Grid.height() * T
	local size = Vector3.new(w + margin * 2, depth + Config.FEEL.terrainClearTop, h + margin * 2)
	local cf = CFrame.new(w / 2, (Config.FEEL.terrainClearTop - depth) / 2, h / 2)
	-- Auch Terrain aus früheren Karten entfernen; der Thronsaal liegt außerhalb.
	if not lastTerrainRegion or lastTerrainRegion.w ~= w or lastTerrainRegion.h ~= h then
		if lastTerrainRegion then workspace.Terrain:FillBlock(lastTerrainRegion.cf, lastTerrainRegion.size, Enum.Material.Air) end
		workspace.Terrain:FillBlock(cf, size, Enum.Material.Air)
		lastTerrainRegion = { cf = cf, size = size, w = w, h = h }
	end
	local board = Instance.new("Folder")
	board.Name = "Board"

	local ground = Instance.new("Folder")
	ground.Name = "Ground"
	ground.Parent = board
	local function colorFor(ch)
		return region and region.terrainColors and region.terrainColors[ch] or Config.TERRAIN[ch].color
	end
	local top = Config.FEEL.surroundHeight
	local surroundColor = region and region.surroundColor or Config.TERRAIN["."].color
	for _, rect in {
		{ -margin / 2, h / 2, margin, h + margin * 2 },
		{ w + margin / 2, h / 2, margin, h + margin * 2 },
		{ w / 2, -margin / 2, w, margin },
		{ w / 2, h + margin / 2, w, margin },
	} do
		deco({ Name = "Surround", Size = Vector3.new(rect[3], Config.FEEL.groundDepth + top, rect[4]),
			Position = Vector3.new(rect[1], (top - Config.FEEL.groundDepth) / 2, rect[2]),
			Color = surroundColor, Material = Enum.Material.SmoothPlastic, CanCollide = true }, board)
	end
	-- Gleiche Zeichen bilden einfache Rechtecke statt eines sichtbaren Blocks pro Feld.
	local used, groundCount = {}, 0
	for y = 1, Grid.height() do
		for x = 1, Grid.width() do
			local key = Grid.key(x, y)
			if used[key] then continue end
			local ch = Grid.getMap()[y]:sub(x, x)
			local right = x
			while right < Grid.width() and not used[Grid.key(right + 1, y)] and Grid.getMap()[y]:sub(right + 1, right + 1) == ch do right += 1 end
			local bottom = y
			while bottom < Grid.height() do
				local same = true
				for xx = x, right do
					if used[Grid.key(xx, bottom + 1)] or Grid.getMap()[bottom + 1]:sub(xx, xx) ~= ch then same = false; break end
				end
				if not same then break end
				bottom += 1
			end
			for yy = y, bottom do for xx = x, right do used[Grid.key(xx, yy)] = true end end
			groundCount += 1
			local height = Config.TERRAIN[ch].height
			local cap = Config.FEEL.groundCapHeight
			local color = colorFor(ch)
			local cx, cz = (x + right - 1) * T / 2, (y + bottom - 1) * T / 2
			local width, length = (right - x + 1) * T, (bottom - y + 1) * T
			deco({ Name = "Side_" .. groundCount, Size = Vector3.new(width, Config.FEEL.groundDepth + height - cap, length),
				Position = Vector3.new(cx, (height - cap - Config.FEEL.groundDepth) / 2, cz),
				Color = color:Lerp(Color3.fromRGB(0, 0, 0), Config.FEEL.groundSideShade),
				Material = Enum.Material.SmoothPlastic, CanCollide = true }, ground)
			deco({ Name = "Ground_" .. groundCount, Size = Vector3.new(width, cap, length),
				Position = Vector3.new(cx, height - cap / 2, cz), Color = color,
				Transparency = (ch == "W" or ch == "D") and Config.FEEL.waterTransparency or 0,
				Material = Enum.Material.SmoothPlastic, CanCollide = true }, ground)
		end
	end
	board:SetAttribute("GroundCount", groundCount)
	board:SetAttribute("MapKey", table.concat(Grid.getMap(), "|"))

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
			tile.CanTouch = false
			tile.CastShadow = false
			tile.Color = terrain.color
			tile.Material = terrain.material
			tile.TopSurface = Enum.SurfaceType.Smooth
			tile:SetAttribute("X", x)
			tile:SetAttribute("Y", y)
			tile.Parent = board
			decorate(ch, x, y, board)
			local center = Grid.toWorld(x, y)
			local offsets = { Vector3.new(-T / 2, 0, 0), Vector3.new(0, 0, -T / 2) }
			-- Gemeinsame Kanten nur einmal; an Höhenstufen bleibt jede Oberkante sichtbar.
			if x == Grid.width() or Grid.tileHeight(x + 1, y) ~= center.Y then table.insert(offsets, Vector3.new(T / 2, 0, 0)) end
			if y == Grid.height() or Grid.tileHeight(x, y + 1) ~= center.Y then table.insert(offsets, Vector3.new(0, 0, T / 2)) end
			for _, offset in offsets do
				deco({ Name = "GridLine", Size = offset.X ~= 0 and Vector3.new(Config.FEEL.gridLineWidth, Config.FEEL.gridLineWidth, T) or Vector3.new(T, Config.FEEL.gridLineWidth, Config.FEEL.gridLineWidth),
					Position = center + offset + Vector3.new(0, Config.FEEL.gridLineWidth / 2 + Config.FEEL.gridSurfaceOffset, 0),
					Color = colorFor(ch):Lerp(Color3.fromRGB(0, 0, 0), Config.FEEL.gridShade), Transparency = Config.FEEL.gridTransparency,
					Material = Enum.Material.SmoothPlastic }, board)
			end
		end
	end

	for i = 1, Config.FEEL.environmentCount do
		local edge = i % 4
		local fraction = ((i * 37) % 97) / 97
		local distance = margin * (0.15 + (i % 3) * 0.15)
		local x = edge < 2 and -distance or (w + distance)
		local z = fraction * h
		if edge % 2 == 1 then x, z = fraction * w, edge == 1 and -distance or h + distance end
		if i % 3 == 0 then
			deco({ Name = "OuterRock", Size = Vector3.new(7, 6, 5), Position = Vector3.new(x, top + 3, z), Color = Config.TERRAIN.M.color, Material = Enum.Material.Rock }, board)
		else
			deco({ Name = "OuterTrunk", Size = Vector3.new(2, 9, 2), Position = Vector3.new(x, top + 4.5, z), Color = Color3.fromRGB(98, 70, 43), Material = Enum.Material.Wood }, board)
			deco({ Name = "OuterLeaves", Shape = Enum.PartType.Ball, Size = Vector3.new(11, 12, 11), Position = Vector3.new(x, top + 12, z), Color = treeColor, Material = Enum.Material.Grass }, board)
		end
	end
	board.Parent = workspace
	return board
end

return BoardBuilder
