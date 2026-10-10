-- Berge ohne Standplatten mit gemessener Figurenhoehe und freien Nachbarn.
local function validateWalls(withPackage)
	if withPackage then metricAssets() else freshAssets() end
	Grid.setMap({ "MM.CC", "M.C.C", ".CW..", "..M.." })
	local fall = { x = 2, y = 3, dx = 1, dy = 0 }
	local board, rocks, stands = Board.build("greenland", { waterfall = fall }), {}, {}
	local minCliff, maxCliff, cores, ridges = math.huge, 0, {}, 0
	for _, asset in board:GetDescendants() do
		expect(asset.Name ~= "WallFacet" and not asset:GetAttribute("WallX"), "Alte Felsfacetten vorhanden")
		if asset:GetAttribute("StandTile") then stands[asset:GetAttribute("StandTile")] = asset end
		if asset.Name == "CliffCore" then
			cores[asset:GetAttribute("CliffTile")] = asset
			expect(asset.Position.Y + asset.Size.Y / 2 == Config.TERRAIN.C.height, "Klippenwand ohne feste Oberkante")
		end
		if asset.Name == "CliffRidge" then
			ridges += 1
			minCliff, maxCliff = math.min(minCliff, asset.Size.Y), math.max(maxCliff, asset.Size.Y)
		end
		if asset:GetAttribute("CliffTile") then
			expect(not asset.CanQuery and not asset.CanCollide, "Felswand blockiert Feldklick")
		end
	end
	for _, asset in board:GetChildren() do
		if asset:GetAttribute("TopRockX") then
			local box, size = asset:GetBoundingBox()
			table.insert(rocks, { box.Position, size })
			local surface = asset:GetAttribute("RockSurface")
			expect(surface and math.abs(box.Position.Y - size.Y/2 - surface + Config.ENVIRONMENT.rocks.surfaceSink) < 0.001, "Fels schwebt")
			local rx, ry = asset:GetAttribute("TopRockX"), asset:GetAttribute("TopRockY")
			expect(box.Position.X-size.X/2 >= (rx-1)*Config.TILE_SIZE and box.Position.X+size.X/2 <= rx*Config.TILE_SIZE
				and box.Position.Z-size.Z/2 >= (ry-1)*Config.TILE_SIZE and box.Position.Z+size.Z/2 <= ry*Config.TILE_SIZE, "Felsdetail verdeckt Nachbarfeld")
			local ch = Grid.getMap()[ry]:sub(rx,rx)
			local palette = modules.Stages.getRegion("greenland").landscape
			local material = ch=="M" and palette.rock or palette.slate
			for _, p in asset:GetDescendants() do if p:IsA("BasePart") then expect(p.Material==material and p.Color==palette.colors[material], "Felsfarbe/Material") end end
		end
		if asset.Name == "Waterfall" then
			expect(math.abs(asset.Position.Y + asset.Size.Y / 2 - Config.TERRAIN.C.height - Config.FEEL.waterfallSurfaceClearance - Config.FEEL.waterfallThickness) < 0.001, "Wasserfall nicht an Klippenoberkante")
		end
	end
	for y, row in Grid.getMap() do for x = 1, #row do
		local ch = row:sub(x, x)
		local tile = board:FindFirstChild(("Tile_%d_%d"):format(x, y))
		expect(tile and tile.CanQuery and tile.Position.Y == Grid.tileHeight(x, y) - 0.1, "Klickfeld verändert")
		if ch ~= "M" and ch ~= "C" then continue end
		local center = Grid.toWorld(x, y)
		local height = terrainHeightAt(center.X, center.Z)
		if ch == "M" then
			expect(not stands[Grid.key(x, y)], "Berg hat Standplatte")
			expect(height and math.abs(height - center.Y) < 0.001, "Figur schwebt oder clippt am Berg")
			expect(Grid.getHeights()[Grid.key(x, y)] == height, "Berg ohne gemessene Snapshot-Hoehe")
			for _, rock in rocks do
				local p, size = rock[1], rock[2]
				expect(math.abs(p.X - center.X) - size.X / 2 >= Config.ENVIRONMENT.rocks.centerClearance - 0.001
					or math.abs(p.Z - center.Z) - size.Z / 2 >= Config.ENVIRONMENT.rocks.centerClearance - 0.001, "Fels auf Standfläche")
			end
		else
			expect(height and height < Config.TERRAIN.C.height, "Terrainkern ragt aus Klippenwand")
			expect(cores[Grid.key(x,y)], "Klippenfeld ohne senkrechte Felswand")
			expect(next(Config.TERRAIN.C.cost) == nil, "Klippe passierbar")
			
		end
	end end
	expect(ridges > 0 and maxCliff - minCliff > 0.2, "Klippen ohne unregelmäßige Oberkante")
	expect(terrainHeightAt(Config.TILE_SIZE - 0.01, 4) ~= nil and terrainHeightAt(Config.TILE_SIZE + 0.01, 4) ~= nil,
		"Zusammenhängender M-Hügel an Feldgrenze unterbrochen")
	local top = terrainHeightAt((fall.x - 0.5) * Config.TILE_SIZE + fall.dx * (Config.TILE_SIZE / 2 - 2), (fall.y - 0.5) * Config.TILE_SIZE)
	expect(top == Config.TERRAIN.C.height - Config.LANDSCAPE.cliffWalls.terrainInset, "Terrain am Wasserfallanschluss hat andere Höhe")
	local cells = 0
	for y, row in Grid.getMap() do for x=1,#row do
		local ch=row:sub(x,x)
		if ch=="M" or ch=="C" then cells+=1 elseif ch~="W" and ch~="B" then
			for dx=0.5,Config.TILE_SIZE-0.5,1 do for dz=0.5,Config.TILE_SIZE-0.5,1 do
				expect(terrainHeightAt((x-1)*Config.TILE_SIZE+dx,(y-1)*Config.TILE_SIZE+dz)==nil, "Terrainbelegung im Nachbarfeld")
			end end
		end
	end end
	expect(#rocks <= cells, "Zu viele Felsdetails")
	validateOuter(board)
	Grid.setMap({ ".....", ".....", ".....", "....." })
	Board.build("greenland")
	expect(terrainHeightAt(4, 4) == nil, "Bergterrain nach gleich großem Kartenwechsel vorhanden")
end
validateWalls(true)
validateWalls(false)
print("OK: Felshügel (Terrain, gemessene Figurenhoehen, Overlayfreiheit, höhere unpassierbare Klippen, freie Felsmitten, Klickfelder, Wasserfall, Aufräumen, Paket/Fallback).")
