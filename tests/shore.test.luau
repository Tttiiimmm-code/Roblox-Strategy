do
	freshAssets()
	Grid.setMap({ ".WW", "..W", "..." })
	local shore = Board.build("greenland")
	local strips, count = 0, 0
	for _, part in shore:GetDescendants() do
		if part.Name:match("^Shore") then
			count += 1
			expect(not part.CanQuery and not part.CanCollide, "Ufer blockiert Klick")
			if part.Name == "ShoreStrip" then strips += 1 end
			expect(part.Name == "ShoreStrip" and part.Shape == Enum.PartType.Block, "Ufer mit Scheibe oder Maske")
			local x, y = part:GetAttribute("ShoreX"), part:GetAttribute("ShoreY")
			local wx, wy = part:GetAttribute("WaterX"), part:GetAttribute("WaterY")
			expect(Grid.getMap()[y]:sub(x, x) ~= "W" and Grid.getMap()[wy]:sub(wx, wx) == "W", "Ufer ohne Landanschluss")
			expect(math.abs(wx - x) + math.abs(wy - y) == 1, "Ufer nicht direkt an Wasser")
			expect(part.Position.X - part.Size.X / 2 >= (x - 1) * Config.TILE_SIZE - 0.001
				and part.Position.X + part.Size.X / 2 <= x * Config.TILE_SIZE + 0.001
				and part.Position.Z - part.Size.Z / 2 >= (y - 1) * Config.TILE_SIZE - 0.001
				and part.Position.Z + part.Size.Z / 2 <= y * Config.TILE_SIZE + 0.001, "Sand liegt frei auf Wasser")
		end
	end
	expect(strips == 4 and count == 4, "Landufer fehlen oder zusaetzliche Masken")
	expect(count <= 9 * Config.FEEL.shore.maxPartsPerTile and count == shore:GetAttribute("ShoreParts"), "Uferteilebudget")
	Grid.setMap({ "...", "WBW", "..." })
	local bridge = Board.build("greenland")
	for _, part in bridge:GetDescendants() do
		if part.Name:match("^Shore") then
			local x, y = math.floor(part.Position.X / Config.TILE_SIZE) + 1, math.floor(part.Position.Z / Config.TILE_SIZE) + 1
			expect(not (x == 2 and (y == 1 or y == 3)), "Brückenenden nicht frei")
		end
	end
	Config.FEEL.shore.enabled = false
	Grid.setMap({ ".W", ".." }); local disabled = Board.build("greenland")
	expect(disabled:GetAttribute("ShoreParts") == 0, "Ufer nicht abschaltbar")
	Config.FEEL.shore.enabled = true
	print("OK: Ufer (Landstreifen ohne Ringe/Masken, Teilebudget, Klickbarkeit, freie Brückenenden, Abschaltung).")
end
