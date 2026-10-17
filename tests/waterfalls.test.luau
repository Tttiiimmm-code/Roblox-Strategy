-- Alle vier Fallrichtungen: freie Quellfläche, bündiger Fall, Gischt ohne Terrain.
do
	for _, package in { true,false } do
		if package then metricAssets() else freshAssets() end
		for _, d in { {1,0}, {-1,0}, {0,1}, {0,-1} } do
			local rows={ ".....", ".CCC.", ".CCC.", ".CCC.", "....." }
			local fall={x=3,y=3,dx=d[1],dy=d[2]}
			local wx,wy=3+d[1],3+d[2]
			rows[wy]=rows[wy]:sub(1,wx-1).."W"..rows[wy]:sub(wx+1)
			Grid.setMap(rows)
			local board=Board.build("greenland", {waterfall=fall})
			local source,sheet=board:FindFirstChild("WaterfallSource"),board:FindFirstChild("Waterfall")
			expect(source and sheet, "Wasserfallrichtung fehlt")
			local center=Grid.toWorld(3,3)
			local edge=(d[1]~=0 and center.X*d[1] or center.Z*d[2])+Config.TILE_SIZE/2+Config.FEEL.waterfallFaceOffset
			local near=(d[1]~=0 and sheet.Position.X*d[1]-sheet.Size.X/2 or sheet.Position.Z*d[2]-sheet.Size.Z/2)
			expect(math.abs(near-edge)<0.001, "Fallfläche nicht an sichtbarer Klippenkante")
			expect(math.abs(source.Position.Y+source.Size.Y/2-sheet.Position.Y-sheet.Size.Y/2)<0.001, "Quelle und Fall ohne bündigen Anschluss")
			local farSource=d[1]~=0 and source.Position.X*d[1]+source.Size.X/2 or source.Position.Z*d[2]+source.Size.Z/2
			local farSheet=d[1]~=0 and sheet.Position.X*d[1]+sheet.Size.X/2 or sheet.Position.Z*d[2]+sheet.Size.Z/2
			expect(math.abs(farSource-farSheet)<0.001, "Quellstreifen endet vor Fallfläche")
			for _, part in board:GetChildren() do if part.Name:match("^Waterfall") then
				local lo,hi=part.Position-part.Size/2,part.Position+part.Size/2
				for ix=0,16 do for iz=0,16 do
					-- Offenes Volumen: bündiger Kontakt an der Klippenkante ist erlaubt.
					local epsilon=0.0001
					local x,z=lo.X+epsilon+(hi.X-lo.X-2*epsilon)*ix/16,lo.Z+epsilon+(hi.Z-lo.Z-2*epsilon)*iz/16
					local height,material=terrainHeightAt(x,z)
					expect(material==Enum.Material.Water or not height or height<lo.Y-0.001, "Wasserfallteil im Terrain: "..part.Name)
				end end
			end end
		end
	end
	metricAssets()
	print("OK: Wasserfälle (vier Richtungen, freie Terrainkanäle, Quelle/Fall bündig, Fall/Gischt außerhalb Terrain, Paket/Fallback).")
end

-- Die gemessene Wasseroberfläche darf vom Sollwert der Karte abweichen.
do
	freshAssets()
	Grid.setMap({ ".....", ".CCC.", ".CWC.", "....." })
	local raycast = workspace.Raycast
	function workspace:Raycast(origin, direction, params)
		local hit = raycast(self, origin, direction, params)
		local _, material = terrainHeightAt(origin.X, origin.Z)
		if hit and params.FilterDescendantsInstances[1] == self.Terrain and material == Enum.Material.Water then
			hit.Position = hit.Position + Vector3.new(0, 0.4, 0)
		end
		return hit
	end
	local board = Board.build("greenland", { waterfall = { x = 3, y = 2, dx = 0, dy = 1 } })
	local sheet = board:FindFirstChild("Waterfall")
	local measured = Config.TERRAIN.W.height + 0.4
	expect(math.abs(sheet.Position.Y - sheet.Size.Y / 2 - measured) < 0.001, "Fallende ignoriert gemessene Wasseroberfläche")
	for _, part in board:GetChildren() do if part.Name == "WaterfallFoam" then
		expect(math.abs(part.Position.Y - part.Size.Y / 2 - measured) < 0.001, "Gischt schwebt über der Wasseroberfläche")
	end end
	workspace.Raycast = raycast
	metricAssets()
	print("OK: Wasserfallanschluss an abweichende gemessene Wasseroberfläche.")
end
