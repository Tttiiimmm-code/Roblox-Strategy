do
	local Outlines = modules.ForestOutlines
	local folder = Instance.new("Folder"); folder.Parent = workspace
	local figures = {}
	Grid.setMap({ "...", ".F.", "..." })
	for i = 1, 25 do
		local model, root = assetModel(folder, tostring(i))
		root.Position = Grid.toWorld(2, 2)
		model.PrimaryPart = root
		model:SetAttribute("UnitId", tostring(i))
		model:SetAttribute("Team", i > 20 and "Player" or "Enemy")
		table.insert(figures, model)
	end
	local tutorial = Instance.new("Highlight"); tutorial.Parent = workspace
	local function update(on) Outlines.update(figures, Vector3.new(0, -1, -1), {}, on) end
	update(true)
	local count, players = 0, 0
	for _, model in figures do if model:FindFirstChild("ForestOutline") then count += 1; if model:GetAttribute("Team") == "Player" then players += 1 end end end
	expect(count == Config.FOREST_OUTLINES.maxCount and players == 5, "Wald-Budget oder Spielervorrang")
	expect(tutorial.Parent == workspace, "Tutorial-Highlight verdrängt")
	local reserved = {}
	for _ = 1, 25 do local h = Instance.new("Highlight"); h.Parent = workspace; table.insert(reserved, h) end
	update(true)
	count, players = 0, 0
	for _, model in figures do if model:FindFirstChild("ForestOutline") then count += 1; if model:GetAttribute("Team") == "Player" then players += 1 end end end
	expect(count == 5 and players == 5, "Fremde Highlights ohne Budgetreserve/Spielervorrang")
	for _, h in reserved do h:Destroy() end
	update(true)
	figures[25].PrimaryPart.Position = Grid.toWorld(2, 1); update(true)
	expect(figures[25]:FindFirstChild("ForestOutline"), "Feld hinter Wald ohne Umriss")
	figures[25].PrimaryPart.Position = Grid.toWorld(2, 3); update(true)
	expect(not figures[25]:FindFirstChild("ForestOutline"), "Umriss bleibt nach Bewegung")
	Outlines.update(figures, Vector3.new(0, -1, 1), {}, true)
	expect(figures[25]:FindFirstChild("ForestOutline"), "Gedrehte Kamera ohne neuen verdeckten Nachbarn")
	figures[25].PrimaryPart.Position = Grid.toWorld(1, 2)
	Outlines.update(figures, Vector3.new(-1, -1, 0), {}, true)
	expect(figures[25]:FindFirstChild("ForestOutline"), "X-Blickachse ohne Waldnachbar")
	figures[25].PrimaryPart.Position = Grid.toWorld(3, 2)
	Outlines.update(figures, Vector3.new(1, -1, 0), {}, true)
	expect(figures[25]:FindFirstChild("ForestOutline"), "Gegenüberliegende X-Blickachse")
	figures[22].Parent = nil; update(true)
	expect(not figures[22]:FindFirstChild("ForestOutline"), "Entfernte Figur behält Umriss")
	figures[24]:SetAttribute("Hp", 0); update(true)
	expect(not figures[24]:FindFirstChild("ForestOutline"), "Toter behält Umriss")
	local dying = { [figures[23]] = true }
	Outlines.update(figures, Vector3.new(0, -1, -1), dying, true)
	expect(not figures[23]:FindFirstChild("ForestOutline"), "Todesanimation behält Umriss")
	update(false)
	for _, model in figures do expect(not model:FindFirstChild("ForestOutline"), "Umriss bleibt beim Verlassen des Kampfes") end
	tutorial:Destroy(); folder:Destroy()
	print("OK: Wald-Umrisse (Budget, Spielervorrang, Kameranachbar, Bewegung, Tod, Kampfende).")
end
