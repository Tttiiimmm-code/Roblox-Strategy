local function validateWalls(withPackage)
	if withPackage then metricAssets() else freshAssets() end
	Grid.setMap({ "MM.CC", "M.C.C", ".CW..", "..M.." })
	local board, edges, rocks = Board.build("greenland"), {}, {}
	for _, asset in board:GetChildren() do
		local x, y = asset:GetAttribute("WallX"), asset:GetAttribute("WallY")
		if x then
			local dx, dy = asset:GetAttribute("WallDX"), asset:GetAttribute("WallDY")
			local nx, ny = x + dx, y + dy
			local ch = Grid.inBounds(nx, ny) and Grid.getMap()[ny]:sub(nx, nx) or ""
			expect(ch ~= "M" and ch ~= "C", "Felsen an innerer M/C-Kante")
			local bottom = ch == "" and Config.FEEL.surroundHeight or Grid.tileHeight(nx, ny)
			expect(bottom < Grid.tileHeight(x, y), "Felsen ohne freiliegende Wand")
			local parts = asset:IsA("Model") and asset:GetDescendants() or { asset }
			for _, part in parts do if part:IsA("BasePart") then
				expect(not part.CanQuery and not part.CanCollide, "Felswand blockiert Klick")
			end end
			if asset.Name == "WallFacet" then
				local key = Grid.key(x, y) .. ":" .. dx .. ":" .. dy
				edges[key] = (edges[key] or 0) + 1
				expect(asset.Position.Y + asset.Size.Y / 2 >= Grid.tileHeight(x, y), "Felswand ohne Oberkante")
			end
		end
		if asset:GetAttribute("TopRockX") then
			local box, size
			if asset:IsA("Model") then box, size = asset:GetBoundingBox()
			else
				-- Part-Fallback: quadratische Steine um 45 Grad gedreht.
				box, size = asset.CFrame, Vector3.new(asset.Size.X * math.sqrt(2), asset.Size.Y, asset.Size.Z * math.sqrt(2))
			end
			table.insert(rocks, { box.Position, size })
		end
	end
	for y, row in Grid.getMap() do for x = 1, #row do
		local ch = row:sub(x, x)
		local tile = board:FindFirstChild(("Tile_%d_%d"):format(x, y))
		expect(tile and tile.CanQuery and tile.Position.Y == Grid.tileHeight(x, y) - 0.1, "Klickfeld veraendert")
		if ch ~= "M" and ch ~= "C" then continue end
		for _, d in { { 1, 0 }, { -1, 0 }, { 0, 1 }, { 0, -1 } } do
			local nx, ny = x + d[1], y + d[2]
			local neighbour = Grid.inBounds(nx, ny) and Grid.getMap()[ny]:sub(nx, nx) or ""
			local bottom = neighbour == "" and Config.FEEL.surroundHeight or Grid.tileHeight(nx, ny)
			local exposed = neighbour ~= "M" and neighbour ~= "C" and bottom < Grid.tileHeight(x, y)
			local count = edges[Grid.key(x, y) .. ":" .. d[1] .. ":" .. d[2]] or 0
			expect(count == (exposed and Config.ENVIRONMENT.rocks.walls.facetsPerEdge or 0), "Aussenkante fehlt oder Innenkante dekoriert")
		end
		if ch == "M" then
			local center, clearance = Grid.toWorld(x, y), Config.ENVIRONMENT.rocks.centerClearance
			for _, rock in rocks do
				local p, size = rock[1], rock[2]
				expect(math.abs(p.X - center.X) - size.X / 2 >= clearance - 0.001
					or math.abs(p.Z - center.Z) - size.Z / 2 >= clearance - 0.001, "Bergmitte von oberem Fels verdeckt")
			end
		end
	end end
end
validateWalls(true)
validateWalls(false)
Config.ENVIRONMENT.rocks.walls.enabled = false
local disabled = Board.build("greenland")
for _, asset in disabled:GetChildren() do expect(not asset:GetAttribute("WallX"), "Felswaende nicht abschaltbar") end
Config.ENVIRONMENT.rocks.walls.enabled = true
print("OK: Felswaende (alle Aussenkanten, keine M/C-Innenkanten, Oberkante, freie Bergmitte, Klickfelder, Paket/Fallback, Abschaltung).")
