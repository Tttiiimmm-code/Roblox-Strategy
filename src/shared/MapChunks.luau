-- Rand-Kennungen beschreiben das genaue Geländeprofil; gleiche Profile schließen nahtlos an.
local function chunk(rows)
	local west, east = "", ""
	for _, row in ipairs(rows) do
		west ..= row:sub(1, 1)
		east ..= row:sub(-1)
	end
	return { rows = rows, edges = { north = rows[1], south = rows[#rows], west = west, east = east } }
end

-- Vier handgezeichnete Kerne × neun Randkombinationen: 36 größere Stücke.
-- Alle Nord-/Westkombinationen existieren, deshalb braucht compose keinen Notanschluss.
local northProfiles = { "........", ".FFFFFF.", "...MM..." }
local westProfiles = { "....", ".FF.", ".MM." }
local cores = {
	{ "FFFF..", "FFFFF." }, -- zusammenhängender Wald mit Lichtung
	{ "MMM.FF", ".MMFFF" }, -- Felsgruppe mit dichtem Waldsaum
	{ ".FHHF.", "FF..FF" }, -- Ruine/Festung zwischen Gehölzen
	{ "FF.MMF", "F..MM." }, -- gemischter Wald-Fels-Rand
}
local MapChunks = { greenland = {} }
for _, north in ipairs(northProfiles) do
	for _, west in ipairs(westProfiles) do
		for i, core in ipairs(cores) do
			local south = i % 2 == 1 and north or northProfiles[1]
			local east = i == 2 or i == 3
			table.insert(MapChunks.greenland, chunk({ north,
				west:sub(2, 2) .. core[1] .. (east and west:sub(2, 2) or "."),
				west:sub(3, 3) .. core[2] .. (east and west:sub(3, 3) or "."), south }))
		end
	end
end

-- Garricks Festung: Leibwache davor, freie Ankunftsfelder am Rand, sechs Starts unten.
MapChunks.bossMaps = {
	greenland = {
		map = { ".....MM..MM.....", "....F..H...F....", ".......FF.......", "....F......F....", ".....F....F.....", "................", "................", "................", "................", "................", "................", "................" },
		boss = { x = 8, y = 2 },
		guards = { { x = 7, y = 3 }, { x = 9, y = 3 }, { x = 8, y = 4 } },
		slots = { { x = 5, y = 12 }, { x = 6, y = 12 }, { x = 7, y = 12 }, { x = 9, y = 12 }, { x = 10, y = 12 }, { x = 11, y = 12 } },
		reinforcementFields = { { x = 1, y = 2 }, { x = 16, y = 2 }, { x = 1, y = 4 }, { x = 16, y = 4 } },
	},
}
return MapChunks
