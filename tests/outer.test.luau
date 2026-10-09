-- Seitenprojektionen echter Bounding-Boxen, mit und ohne Paket.
local function validateOuter(board)
	local T, w, h = Config.TILE_SIZE, Grid.width() * Config.TILE_SIZE, Grid.height() * Config.TILE_SIZE
	local intervals = { {}, {}, {}, {} }
	local tall = { 0, 0, 0, 0 }
	for _, asset in board:GetChildren() do
		local edge, layer = asset:GetAttribute("OuterEdge"), asset:GetAttribute("OuterLayer")
		if not edge then continue end
		local box, size
		if asset:IsA("Model") then box, size = asset:GetBoundingBox()
		else box, size = asset.CFrame, asset.Size end
		local lo, hi = Vector3.new(math.huge, math.huge, math.huge), Vector3.new(-math.huge, -math.huge, -math.huge)
		for _, dx in { -1, 1 } do for _, dy in { -1, 1 } do for _, dz in { -1, 1 } do
			local point = box:PointToWorldSpace(Vector3.new(dx * size.X / 2, dy * size.Y / 2, dz * size.Z / 2))
			lo = Vector3.new(math.min(lo.X, point.X), math.min(lo.Y, point.Y), math.min(lo.Z, point.Z))
			hi = Vector3.new(math.max(hi.X, point.X), math.max(hi.Y, point.Y), math.max(hi.Z, point.Z))
		end end end
		local p = (lo + hi) / 2; size = hi - lo
		if hi.Z >= h - Config.ENVIRONMENT.outer.front.cornerDepth * T then
			expect(hi.Y <= Config.FEEL.surroundHeight + Config.ENVIRONMENT.outer.front.maxHeight * T + 0.001, "Vorderer Waldrand zu hoch")
		end
		if asset.Name == "OuterLeaves" then
			expect(edge == 1 and layer == 2 and hi.Z <= -(Config.ENVIRONMENT.outer.farDistance - Config.ENVIRONMENT.outer.farWidth / 2) * T + 0.001,
				"Ersatzkrone nicht weit hinter dem Brett")
		end
		expect(p.X + size.X / 2 <= 0 or p.X - size.X / 2 >= w
			or p.Z + size.Z / 2 <= 0 or p.Z - size.Z / 2 >= h, "Umgebungsobjekt ragt auf Brett")
		local objects = asset:IsA("Model") and asset:GetDescendants() or { asset }
		for _, part in objects do
			if part:IsA("BasePart") then expect(not part.CanQuery and not part.CanCollide, "Waldrand blockiert Klicks") end
		end
		if layer ~= 1 then continue end
		if size.Y > Config.ENVIRONMENT.outer.front.maxHeight * T then tall[edge] += 1 end
		local center, extent = edge <= 2 and p.X or p.Z, edge <= 2 and size.X or size.Z
		table.insert(intervals[edge], { center - extent / 2, center + extent / 2 })
	end
	if Grid.width() >= 6 and Grid.height() >= 6 then
		for _, edge in { 1, 3, 4 } do expect(tall[edge] > 0, "Hohe Bäume hinten/seitlich fehlen") end
	end
	for edge, spans in intervals do
		table.sort(spans, function(a, b) return a[1] < b[1] end)
		local finish, length = 0, edge <= 2 and w or h
		expect(#spans > 0, "Waldrandseite fehlt")
		for _, span in spans do
			if span[2] < 0 or span[1] > length then continue end
			expect(span[1] - finish <= Config.ENVIRONMENT.outer.maxSideGap * T, string.format("Grosse Luecke im Waldrand: Seite %d, Ende %.4f, Beginn %.4f", edge, finish, span[1]))
			finish = math.max(finish, span[2])
		end
		expect(finish >= length - 0.001, "Waldrand reicht nicht bis zur Ecke")
	end
end

local function validateZoomGround(board)
	local w, h = Grid.width() * Config.TILE_SIZE, Grid.height() * Config.TILE_SIZE
	local overview = math.max(Config.CAMERA.zoomOverviewMin, math.sqrt(w * w + h * h) * Config.CAMERA.zoomOverviewScale)
	local floor = {}
	for _, part in board:GetChildren() do if part.Name == "Surround" then
		expect(part.Size.X <= Config.ENVIRONMENT.outer.maxGroundPartSpan and part.Size.Z <= Config.ENVIRONMENT.outer.maxGroundPartSpan,
			"Umgebungsboden mit uebergrossem Part")
		table.insert(floor, part)
	end end
	-- Strahl/Schnitt mit y=surroundHeight: tatsächliche C1-Neigung (0,1,0.75), Standard-FOV 70°.
	for _, aspect in { 4 / 3, 16 / 9, 21 / 9 } do for yaw = 0, 7 do
		local angle, tangent = yaw * math.pi / 4, math.tan(math.rad(35))
		for _, fx in { 0, w } do for _, fz in { 0, h } do
			for _, sx in { -1, 1 } do for _, sy in { -1, 1 } do
				local dy = -0.8 + 0.6 * sy * tangent
				local time = (overview * 0.8 - Config.FEEL.surroundHeight) / -dy
				local dx, dz = sx * aspect * tangent * time, overview * 0.6 + (-0.6 - 0.8 * sy * tangent) * time
				local x, z = fx + dx * math.cos(angle) + dz * math.sin(angle), fz - dx * math.sin(angle) + dz * math.cos(angle)
				local covered = x >= 0 and x <= w and z >= 0 and z <= h
				for _, part in floor do
					if math.abs(x - part.Position.X) <= part.Size.X / 2 and math.abs(z - part.Position.Z) <= part.Size.Z / 2 then covered = true; break end
				end
				expect(covered, "Leerer Bodenrand bei C1-Maximalzoom")
			end end
		end end
	end end
end
