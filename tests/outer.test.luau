-- Seitenprojektionen echter Bounding-Boxen, mit und ohne Paket.
local function validateOuter(board)
	local T, w, h = Config.TILE_SIZE, Grid.width() * Config.TILE_SIZE, Grid.height() * Config.TILE_SIZE
	local intervals = { {}, {}, {}, {} }
	for _, asset in board:GetChildren() do
		local edge, layer = asset:GetAttribute("OuterEdge"), asset:GetAttribute("OuterLayer")
		if not edge then continue end
		local box, size
		if asset:IsA("Model") then box, size = asset:GetBoundingBox()
		else box, size = asset.CFrame, asset.Size end
		local p = box.Position
		expect(p.X + size.X / 2 <= 0 or p.X - size.X / 2 >= w
			or p.Z + size.Z / 2 <= 0 or p.Z - size.Z / 2 >= h, "Umgebungsobjekt ragt auf Brett")
		local objects = asset:IsA("Model") and asset:GetDescendants() or { asset }
		for _, part in objects do
			if part:IsA("BasePart") then expect(not part.CanQuery and not part.CanCollide, "Waldrand blockiert Klicks") end
		end
		if layer ~= 1 then continue end
		local center, extent = edge <= 2 and p.X or p.Z, edge <= 2 and size.X or size.Z
		table.insert(intervals[edge], { center - extent / 2, center + extent / 2 })
	end
	for edge, spans in intervals do
		table.sort(spans, function(a, b) return a[1] < b[1] end)
		local finish, length = 0, edge <= 2 and w or h
		expect(#spans > 0, "Waldrandseite fehlt")
		for _, span in spans do
			if span[2] < 0 or span[1] > length then continue end
			expect(span[1] - finish <= Config.ENVIRONMENT.outer.maxSideGap * T, "Grosse Luecke im Waldrand")
			finish = math.max(finish, span[2])
		end
		expect(finish >= length, "Waldrand reicht nicht bis zur Ecke")
	end
end
