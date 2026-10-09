-- Rand-Kennungen beschreiben das genaue Geländeprofil; gleiche Profile schließen nahtlos an.
local function chunk(rows)
	local west, east = "", ""
	for _, row in ipairs(rows) do
		west ..= row:sub(1, 1)
		east ..= row:sub(-1)
	end
	return { rows = rows, edges = { north = rows[1], south = rows[#rows], west = west, east = east } }
end

local MapChunks = {
	greenland = {
		-- Lichtungen, Gehölze und kleine Gehöfte mit offenen Anschlüssen.
		chunk({ ".....", ".FF..", "..F..", "....." }),
		chunk({ ".....", "..FF.", ".FF..", "....." }),
		chunk({ ".....", ".M.F.", "..F..", "....." }),
		chunk({ ".....", ".MM..", "..F..", "....." }),
		chunk({ ".....", ".FHF.", "..F..", "....." }),
		chunk({ ".....", ".FFH.", ".F.F.", "....." }),
		chunk({ ".....", ".F.F.", ".F.F.", "....." }),
		chunk({ ".....", ".FM..", "..MF.", "....." }),
		-- Waldränder, durchgehende Waldzüge und bewaldete Höfe.
		chunk({ ".FFF.", ".FF..", "..F..", "....." }),
		chunk({ ".FFF.", "..FF.", ".FH..", "....." }),
		chunk({ ".....", "FFF..", "FF...", "....." }),
		chunk({ ".....", "FFH..", "FFF..", "....." }),
		chunk({ ".FFF.", "FFF..", "FF...", "....." }),
		chunk({ ".FFF.", ".FHF.", "..FF.", ".FFF." }),
		chunk({ ".....", "FF.FF", "FFFFF", "....." }),
		chunk({ ".FFF.", "FF.FF", "FF.FF", ".FFF." }),
		-- Felsketten und Hügel am Waldsaum; Felsanschlüsse bleiben schmal.
		chunk({ ".....", "MM...", "MF...", "....." }),
		chunk({ ".....", "M.F..", "MMF..", "....." }),
		chunk({ ".MMM.", "..M..", "..F..", "....." }),
		chunk({ ".MMM.", "..FF.", ".FH..", "....." }),
		chunk({ ".....", "MM.MM", "MF.FM", "....." }),
		chunk({ ".MMM.", "..F..", "..F..", ".MMM." }),
		chunk({ ".MMM.", "M....", "M.F..", "....." }),
		chunk({ ".FFF.", "MF...", "MF...", "....." }),
		chunk({ ".MMM.", "FF...", "FFH..", "....." }),
		chunk({ ".....", "MF.FF", "MMFFF", "....." }),
		chunk({ ".FFF.", "FFF..", "FFH..", ".FFF." }),
		chunk({ ".....", "FFFFF", "FFHFF", "....." }),
	},
}

-- Garricks Festung: Leibwache davor, freie Ankunftsfelder am Rand, sechs Starts unten.
MapChunks.bossMaps = {
	greenland = {
		map = { "..MM..MM..", ".F..H...F.", "....FF....", ".F......F.", "..F....F..", "..........", "..........", ".........." },
		boss = { x = 5, y = 2 },
		guards = { { x = 4, y = 3 }, { x = 6, y = 3 }, { x = 5, y = 4 } },
		slots = { { x = 2, y = 8 }, { x = 3, y = 8 }, { x = 4, y = 8 }, { x = 6, y = 8 }, { x = 7, y = 8 }, { x = 8, y = 8 } },
		reinforcementFields = { { x = 1, y = 2 }, { x = 10, y = 2 }, { x = 1, y = 4 }, { x = 10, y = 4 } },
	},
}
return MapChunks
