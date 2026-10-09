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
