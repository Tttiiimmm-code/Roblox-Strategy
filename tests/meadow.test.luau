do
	metricAssets()
	local map = {}
	for y = 1, 12 do map[y] = string.rep(".", 16) end
	local stage = { map = map, slots = { { x = 1, y = 1 } }, enemies = { { x = 2, y = 1 } } }
	local function meadowData()
		Grid.setMap(map)
		local board = Board.build("greenland", nil, stage)
		local decorated, counts, signature = {}, {}, {}
		for _, object in board:GetChildren() do
			local key, kind = object:GetAttribute("MeadowTile"), object:GetAttribute("MeadowKind")
			if key then
				expect(key ~= "1,1" and key ~= "2,1", "Start-/Gegnerfeld mit Wiesen-Deko")
				decorated[key] = true; counts[kind] = (counts[kind] or 0) + 1
				local x, y = key:match("(%d+),(%d+)"); local center = Grid.toWorld(tonumber(x), tonumber(y))
				local box, size
				if object:IsA("Model") then box, size = object:GetBoundingBox() else box, size = object.CFrame, object.Size end
				local dx = math.max(math.abs(box.Position.X - center.X) - size.X / 2, 0)
				local dz = math.max(math.abs(box.Position.Z - center.Z) - size.Z / 2, 0)
				expect(math.sqrt(dx * dx + dz * dz) >= Config.ENVIRONMENT.meadow.centerClearance, "Wiesen-Deko verdeckt Feldmitte")
				table.insert(signature, key .. ":" .. kind .. ":" .. tostring(size))
			end
		end
		local tiles = 0; for _ in decorated do tiles += 1 end
		expect(tiles >= 70 and tiles <= 120 and counts.deco_grass >= tiles and counts.deco_grass <= tiles * 2, "Wiesendichte/Grasanzahl")
		return table.concat(signature, "|"), counts
	end
	local first, kinds = meadowData(); local second = meadowData()
	expect(first == second and kinds.deco_flower and kinds.deco_stone and kinds.deco_fence, "Wiesendeko nicht deterministisch oder Kategorien fehlen")
	freshAssets()
	meadowData()
	print("OK: Wiesen (mittlere Dichte, 1–2 Grasbüschel, Blumen/Steine/Zaun, Feldmitte, Starts, Determinismus, Part-Fallback).")
end
