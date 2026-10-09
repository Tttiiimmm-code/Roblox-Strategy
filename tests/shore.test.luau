do
	freshAssets()
	Grid.setMap({ ".WW", "..W", "..." })
	local shore = Board.build("greenland")
	local strips, convex, concave, count = 0, 0, 0, 0
	for _, part in shore:GetDescendants() do
		if part.Name:match("^Shore") then
			count += 1
			expect(not part.CanQuery and not part.CanCollide, "Ufer blockiert Klick")
			if part.Name == "ShoreStrip" then strips += 1 end
			if part.Name == "ShoreConvexSand" then convex += 1 end
			if part.Name == "ShoreConcaveSand" then concave += 1 end
		end
	end
	expect(strips > 0 and convex > 0 and concave > 0, "Gerade/runde/konkave Ufer fehlen")
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
	print("OK: Ufer (Streifen, konvex/konkav, Teilebudget, Klickbarkeit, freie Brückenenden, Abschaltung).")
end
