-- Berg- und Klippenterrain, Standkappen und unveränderte Klick-/Spielhöhen.
local function validateWalls(withPackage)
	if withPackage then metricAssets() else freshAssets() end
	Grid.setMap({ "MM.CC", "M.C.C", ".CW..", "..M.." })
	local fall = { x = 2, y = 3, dx = 1, dy = 0 }
	local board, rocks, stands = Board.build("greenland", { waterfall = fall }), {}, {}
	local minCliff, maxCliff = math.huge, 0
	for _, asset in board:GetDescendants() do
		expect(asset.Name ~= "WallFacet" and not asset:GetAttribute("WallX"), "Alte Felsfacetten vorhanden")
		if asset:GetAttribute("StandTile") then stands[asset:GetAttribute("StandTile")] = asset end
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
			expect(asset.Position.Y + asset.Size.Y / 2 == Config.TERRAIN.C.height, "Wasserfall nicht an Klippenoberkante")
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
			local stand = stands[Grid.key(x, y)]
			expect(stand and stand.Position.Y + stand.Size.Y / 2 == center.Y, "Ebene Standfläche fehlt")
			expect(height and height + Config.LANDSCAPE.rockFields.smoothingReserve < center.Y, "Terrain-Bergmitte nicht in Feldhöhe")
			for _, dx in { -2, 0, 2 } do for _, dz in { -2, 0, 2 } do
				local top = terrainHeightAt(center.X + dx, center.Z + dz)
				expect(top and top + Config.LANDSCAPE.rockFields.smoothingReserve < center.Y, "Terrain durchdringt Overlay auf M")
			end end
			for _, rock in rocks do
				local p, size = rock[1], rock[2]
				expect(math.abs(p.X - center.X) - size.X / 2 >= Config.ENVIRONMENT.rocks.centerClearance - 0.001
					or math.abs(p.Z - center.Z) - size.Z / 2 >= Config.ENVIRONMENT.rocks.centerClearance - 0.001, "Fels auf Standfläche")
			end
		else
			expect(height and height >= Config.TERRAIN.C.height and height > Config.TERRAIN.M.height, "Klippe nicht höher als Berg")
			expect(next(Config.TERRAIN.C.cost) == nil, "Klippe passierbar")
			minCliff, maxCliff = math.min(minCliff, height), math.max(maxCliff, height)
		end
	end end
	expect(maxCliff - minCliff > 0.2, "Klippen ohne unregelmäßige Oberkante")
	expect(terrainHeightAt(Config.TILE_SIZE - 0.01, 4) ~= nil and terrainHeightAt(Config.TILE_SIZE + 0.01, 4) ~= nil,
		"Zusammenhängender M-Hügel an Feldgrenze unterbrochen")
	local top = terrainHeightAt((fall.x - 0.5) * Config.TILE_SIZE + fall.dx * (Config.TILE_SIZE / 2 - 2), (fall.y - 0.5) * Config.TILE_SIZE)
	expect(top == Config.TERRAIN.C.height, "Terrain am Wasserfallanschluss hat andere Höhe")
	local cells = 0
	for y, row in Grid.getMap() do for x=1,#row do
		local ch=row:sub(x,x)
		if ch=="M" or ch=="C" then cells+=1 else
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
print("OK: Felshügel (Terrain, ebene Standflächen, Overlayfreiheit, höhere unpassierbare Klippen, freie Felsmitten, Klickfelder, Wasserfall, Aufräumen, Paket/Fallback).")
