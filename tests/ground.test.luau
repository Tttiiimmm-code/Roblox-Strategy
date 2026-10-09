-- Materialfarben kommen vom selben regionalen Terrain wie die Landschaft.
do
	freshAssets()
	local function same(a, b) return math.abs(a.R-b.R)<0.000001 and math.abs(a.G-b.G)<0.000001 and math.abs(a.B-b.B)<0.000001 end
	for _, region in modules.Stages.Regions do
		Grid.setMap({ ".FSMCDHBW" })
		local board = Board.build(region.id)
		local ground = board:FindFirstChild("Ground")
		for _, part in ground:GetChildren() do if part.Name:match("^Ground_") then
			local x = math.floor(part.Position.X / Config.TILE_SIZE) + 1
			local ch = Grid.getMap()[1]:sub(x,x)
			local terrain, palette = Config.TERRAIN[ch], region.landscape
			local expected = terrain.paletteKey and palette.colors[palette[terrain.paletteKey]] or (region.terrainColors and region.terrainColors[ch]) or terrain.color
			if ch == "F" then expected = expected:Lerp(Color3.fromRGB(0,0,0), Config.ENVIRONMENT.forest.groundShade) end
			expect(same(part.Color, expected), "Bodenfarbe passt nicht zur Regionspalette: " .. region.id .. "/" .. ch)
			expect(part.Material == ((ch=="." or ch=="F") and palette.grass or terrain.material), "Bodenmaterial: " .. ch)
		end end
		for _, part in board:GetDescendants() do expect(not part.Name:match("Fleck"), "Materialboden mit aktiven Flecken") end
	end
	local saved, enabled = Config.GROUND_TEXTURES["."].top, Config.GROUND_FLECKS.enabled
	Config.GROUND_TEXTURES["."].top, Config.GROUND_FLECKS.enabled = "12345", true
	Grid.setMap({ "." })
	local board, textures = Board.build("greenland"), 0
	for _, part in board:GetDescendants() do
		if part.Name == "GroundTexture" then textures += 1; expect(part.Texture=="rbxassetid://12345" and part.Face==Enum.NormalId.Top, "Eigene Bodentextur fehlt") end
		expect(not part.Name:match("Fleck"), "Eigene Bodentextur ohne Vorrang")
	end
	expect(textures==1, "Bodentextur nicht auf Oberfläche")
	Config.GROUND_TEXTURES["."].top, Config.GROUND_FLECKS.enabled = saved, enabled
	local mountainTop = Config.GROUND_TEXTURES.M.top
	Config.GROUND_TEXTURES.M.top = "67890"
	Grid.setMap({ "M" })
	local mountain = Board.build("greenland"):FindFirstChild("Ground"):FindFirstChild("MountainStand")
	local texture = mountain:FindFirstChild("GroundTexture")
	expect(texture and texture.Texture=="rbxassetid://67890", "Eigene Bergtextur ohne Vorrang auf Standfläche")
	Config.GROUND_TEXTURES.M.top = mountainTop
	print("OK: Materialboden (Regionspaletten, Waldkontrast, alle Geländearten, Flecken aus, Texturvorrang).")
end
