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
		chunk({ "........", ".FFFF...", "..F.F...", "........" }),
		chunk({ "........", "..F.FFF.", ".FFFF...", "........" }),
		chunk({ "........", ".M.M.FF.", "..F.F...", "........" }),
		chunk({ "........", ".MMMM...", "..F.F...", "........" }),
		chunk({ "........", ".FHFHFF.", "..F.F...", "........" }),
		chunk({ "........", ".FFFFHH.", ".F.F.FF.", "........" }),
		chunk({ "........", ".F.F.FF.", ".F.F.FF.", "........" }),
		chunk({ "........", ".FMFM...", "..M.MFF.", "........" }),
		-- Waldränder, durchgehende Waldzüge und bewaldete Höfe.
		chunk({ ".FFFFFF.", ".FFFF...", "..F.F...", "........" }),
		chunk({ ".FFFFFF.", "..F.FFF.", ".FHFH...", "........" }),
		chunk({ "........", "FFFFF...", "FF.F....", "........" }),
		chunk({ "........", "FFHFH...", "FFFFF...", "........" }),
		chunk({ ".FFFFFF.", "FFFFF...", "FF.F....", "........" }),
		chunk({ ".FFFFFF.", ".FHFHFF.", "..F.FFF.", ".FFFFFF." }),
		chunk({ "........", "FF.F.FFF", "FFFFFFFF", "........" }),
		chunk({ ".FFFFFF.", "FF.F.FFF", "FF.F.FFF", ".FFFFFF." }),
		-- Felsketten und Hügel am Waldsaum; Felsanschlüsse bleiben schmal.
		chunk({ "........", "MM.M....", "MF.F....", "........" }),
		chunk({ "........", "M.F.F...", "MMFMF...", "........" }),
		chunk({ ".MMMMMM.", "..M.M...", "..F.F...", "........" }),
		chunk({ ".MMMMMM.", "..F.FFF.", ".FHFH...", "........" }),
		chunk({ "........", "MM.M.MMM", "MF.F.FFM", "........" }),
		chunk({ ".MMMMMM.", "..F.F...", "..F.F...", ".MMMMMM." }),
		chunk({ ".MMMMMM.", "M.......", "M.F.F...", "........" }),
		chunk({ ".FFFFFF.", "MF.F....", "MF.F....", "........" }),
		chunk({ ".MMMMMM.", "FF.F....", "FFHFH...", "........" }),
		chunk({ "........", "MF.F.FFF", "MMFMFFFF", "........" }),
		chunk({ ".FFFFFF.", "FFFFF...", "FFHFH...", ".FFFFFF." }),
		chunk({ "........", "FFFFFFFF", "FFHFHFFF", "........" }),
	},
}

-- Garricks Festung: Leibwache davor, freie Ankunftsfelder am Rand, sechs Starts unten.
MapChunks.bossMaps = {
	greenland = {
		map = { ".....MM..MM.....", "....F..H...F....", ".......FF.......", "....F......F....", ".....F....F.....", "................", "................", "................", "................", "................", "................", "................" },
		boss = { x = 8, y = 2 },
		guards = { { x = 7, y = 3 }, { x = 9, y = 3 }, { x = 8, y = 4 } },
		slots = { { x = 5, y = 12 }, { x = 6, y = 12 }, { x = 7, y = 12 }, { x = 9, y = 12 }, { x = 10, y = 12 }, { x = 11, y = 12 } },
		reinforcementFields = { { x = 4, y = 2 }, { x = 13, y = 2 }, { x = 4, y = 4 }, { x = 13, y = 4 } },
	},
}
return MapChunks
