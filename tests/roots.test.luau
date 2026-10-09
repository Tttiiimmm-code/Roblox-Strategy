-- Original-Paketbäume auf Brett und Landschaft: exakt ein zentrierter Wurzelfuß.
do
	metricAssets()
	local function rootSignature()
		Grid.setMap({ "FFF", "FFF", "FFF" })
		local board, rows, forest, landscape = Board.build("greenland"), {}, 0, 0
		for _, tree in board:GetChildren() do
			if not tree.Name:match("^tree_") then continue end
			local trunk, roots = nil, {}
			for _, part in tree:GetDescendants() do
				if part:GetAttribute("RootFoot") then table.insert(roots,part) end
				if part:IsA("MeshPart") and part.Material==Enum.Material.Wood and not (part.Parent:GetAttribute("RootFoot")) then trunk=part end
			end
			expect(trunk and #roots==1, "Paketbaum ohne genau einen Wurzelfuß")
			local root, settings = roots[1], Config.ENVIRONMENT.rootFoot
			local box,size = root:GetBoundingBox()
			local foot = trunk.CFrame:PointToWorldSpace(Vector3.new(0,-trunk.Size.Y/2,0))
			expect(math.abs(box.Position.X-foot.X)<=settings.centerTolerance and math.abs(box.Position.Z-foot.Z)<=settings.centerTolerance, "Wurzel nicht auf Stammfuß")
			expect(math.abs(box.Position.Y-size.Y/2-foot.Y+settings.sink)<0.001, "Wurzel nicht leicht eingesunken")
			local width=math.max(trunk.Size.X,trunk.Size.Z)*settings.widthScale
			expect(math.abs(math.max(size.X,size.Z)-width)<0.001, "Wurzel nicht relativ zur Stammbreite skaliert")
			for _, part in root:GetDescendants() do if part:IsA("BasePart") then expect(not part.CanQuery and not part.CanCollide, "Wurzel blockiert Eingabe") end end
			if tree:GetAttribute("ForestTile") then forest+=1 end
			if tree:GetAttribute("LandscapeDetail")=="tree" then landscape+=1 end
			table.insert(rows,tree.Name .. ":" .. root.Name .. ":" .. tostring(box.Position) .. ":" .. tostring(size))
		end
		for _, part in board:GetChildren() do expect(not part.Name:match("^deco_root_"), "Lose Wurzeldeko") end
		expect(forest>0 and landscape>0, "Wurzeltest ohne Brett-/Landschaftsbäume")
		return table.concat(rows,"|")
	end
	expect(rootSignature()==rootSignature(), "Wurzelfüße nicht deterministisch")
	freshAssets()
	Grid.setMap({ "F" })
	local board=Board.build("greenland")
	for _, part in board:GetDescendants() do expect(not part:GetAttribute("RootFoot"), "Part-Fallback um Wurzeln erweitert") end
	metricAssets()
	print("OK: Wurzelfüße (Original-Paket, Brett/Landschaft, Stammzentrum, Skalierung, Einsinken, Determinismus, Fallback).")
end
