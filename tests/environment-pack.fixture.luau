-- Teilema?e/-klassen/-rotationen aus dem Nutzerpaket vom 09.10.2026, keine Mesh-Geometrie.
-- Dreiecke sind unver?nderte Kategorie-Sch?tzwerte; reale GPU-Geometrie bleibt Studio-Pr?fung.
local packageSamples = {
	{ name = "archbridge_1", parts = {
		{ class = "MeshPart", size = { 8, 2.1276531, 2.25143 }, position = { 0, 0, 0 }, rotation = { 1, 0, 0, 0, 1, 0, 0, 0, 1 }, material = "Rock", triangles = 2000 },
	} },
	{ name = "bush_1", parts = {
		{ class = "MeshPart", size = { 8, 6.3350205, 7.3361993 }, position = { -0.051, 0.78962475, -0.13858 }, rotation = { 1, 0, 0, 0, 1, 0, 0, 0, 1 }, material = "LeafyGrass", triangles = 1200, alpha = "Transparency" },
		{ class = "MeshPart", size = { 4.3759975, 6.0639596, 3.0756035 }, position = { 0.051, -0.78962475, 0.13858 }, rotation = { 1, 0, 0, 0, 1, 0, 0, 0, 1 }, material = "Wood", triangles = 300, alpha = "Overlay" },
	} },
	{ name = "bush_2", parts = {
		{ class = "MeshPart", size = { 3.9106884, 6.3281865, 3.497125 }, position = { 0.30785, -1.04843555, 0.064871175 }, rotation = { 1, 0, 0, 0, 1, 0, 0, 0, 1 }, material = "Wood", triangles = 300, alpha = "Overlay" },
		{ class = "MeshPart", size = { 8, 5.321089, 7.8143296 }, position = { -0.30785, 1.04843555, -0.064871175 }, rotation = { 1, 0, 0, 0, 1, 0, 0, 0, 1 }, material = "LeafyGrass", triangles = 1200, alpha = "Transparency" },
	} },
	{ name = "bush_3", parts = {
		{ class = "MeshPart", size = { 8, 5.1432114, 7.294096 }, position = { -0.12, 0.61264015, 0.026124245 }, rotation = { 1, 0, 0, 0, 1, 0, 0, 0, 1 }, material = "LeafyGrass", triangles = 1200, alpha = "Transparency" },
		{ class = "MeshPart", size = { 3.3587987, 3.865439, 2.4176905 }, position = { 0.12, -0.61264015, -0.026124245 }, rotation = { 1, 0, 0, 0, 1, 0, 0, 0, 1 }, material = "Wood", triangles = 300, alpha = "Overlay" },
	} },
	{ name = "deco_fence_1", parts = {
		{ class = "UnionOperation", size = { 0.24490355, 2.3673418, 0.32653028 }, position = { 0.0268, -0.00875916, -3.4253091 }, rotation = { 1, 0, 0, 0, 1, 0, 0, 0, 1 }, material = "Wood", triangles = 200 },
		{ class = "UnionOperation", size = { 0.24490355, 2.3673418, 0.32653028 }, position = { 0.0268, -0.00875916, -2.4457191 }, rotation = { 1, 0, 0, 0, 1, 0, 0, 0, 1 }, material = "Wood", triangles = 200 },
		{ class = "UnionOperation", size = { 0.24490355, 2.3673418, 0.32653028 }, position = { 0.0268, -0.00875916, -1.4661191 }, rotation = { 1, 0, 0, 0, 1, 0, 0, 0, 1 }, material = "Wood", triangles = 200 },
		{ class = "UnionOperation", size = { 0.24490355, 2.3673418, 0.32653028 }, position = { 0.0268, -0.00875916, -0.4865291 }, rotation = { 1, 0, 0, 0, 1, 0, 0, 0, 1 }, material = "Wood", triangles = 200 },
		{ class = "UnionOperation", size = { 0.24490355, 2.3673418, 0.32653028 }, position = { 0.0268, -0.00875916, 0.4930609 }, rotation = { 1, 0, 0, 0, 1, 0, 0, 0, 1 }, material = "Wood", triangles = 200 },
		{ class = "UnionOperation", size = { 0.24490355, 2.3673418, 0.32653028 }, position = { 0.0268, -0.00875916, 1.4726559 }, rotation = { 1, 0, 0, 0, 1, 0, 0, 0, 1 }, material = "Wood", triangles = 200 },
		{ class = "UnionOperation", size = { 0.24490355, 2.3673418, 0.32653028 }, position = { 0.0268, -0.00875916, 2.4522509 }, rotation = { 1, 0, 0, 0, 1, 0, 0, 0, 1 }, material = "Wood", triangles = 200 },
		{ class = "UnionOperation", size = { 0.24490355, 2.3673418, 0.32653028 }, position = { 0.0268, -0.00875916, 3.4318469 }, rotation = { 1, 0, 0, 0, 1, 0, 0, 0, 1 }, material = "Wood", triangles = 200 },
		{ class = "Part", size = { 0.08163252, 0.24489796, 8 }, position = { -0.1072, 0.46473654, -0.0130691 }, rotation = { 1, 0, 0, 0, 1, 0, 0, 0, 1 }, material = "Wood", triangles = 12 },
		{ class = "Part", size = { 0.08163252, 0.24489796, 8 }, position = { -0.1072, -0.39466326, -0.0130691 }, rotation = { 1, 0, 0, 0, 1, 0, 0, 0, 1 }, material = "Wood", triangles = 12 },
	} },
	{ name = "deco_flower_1", parts = {
		{ class = "MeshPart", size = { 8, 3.5446491, 7.708548 }, position = { -0.05615, -0.9633282, -0.1449465 }, rotation = { 0.8561094, 0.030218279, -0.5159104, -0.08603201, 0.9926922, -0.084618025, 0.50958335, 0.11682712, 0.85245305 }, material = "SmoothPlastic", triangles = 150 },
		{ class = "MeshPart", size = { 5.461998, 0.97395325, 4.8695855 }, position = { 0.05615, 0.9633282, 0.1449465 }, rotation = { 0.8561094, 0.030218279, -0.5159104, -0.08603201, 0.9926922, -0.084618025, 0.50958335, 0.11682712, 0.85245305 }, material = "SmoothPlastic", triangles = 200 },
	} },
	{ name = "deco_flower_2", parts = {
		{ class = "MeshPart", size = { 7.999998, 3.5446482, 7.708546 }, position = { -0.0166, -0.96337465, -0.154588 }, rotation = { 0.694995, -0.0010279553, -0.7190146, -0.086060524, 0.9926911, -0.084604986, 0.7138471, 0.120678775, 0.68982613 }, material = "SmoothPlastic", triangles = 150 },
		{ class = "MeshPart", size = { 5.461996, 0.973953, 4.8695846 }, position = { 0.0166, 0.96337465, 0.154588 }, rotation = { 0.694995, -0.0010279553, -0.7190146, -0.086060524, 0.9926911, -0.084604986, 0.7138471, 0.120678775, 0.68982613 }, material = "SmoothPlastic", triangles = 200 },
	} },
	{ name = "deco_flower_3", parts = {
		{ class = "MeshPart", size = { 8, 3.5446491, 7.7085476 }, position = { -0.1362, -0.9633848, -0.0750975 }, rotation = { 0.9833693, 0.09827683, 0.15273024, -0.08605773, 0.99268585, -0.08466885, -0.15993415, 0.0701172, 0.9846343 }, material = "SmoothPlastic", triangles = 150 },
		{ class = "MeshPart", size = { 5.4619975, 0.97395325, 4.8695855 }, position = { 0.1362, 0.9633848, 0.0750975 }, rotation = { 0.9833693, 0.09827683, 0.15273024, -0.08605773, 0.99268585, -0.08466885, -0.15993415, 0.0701172, 0.9846343 }, material = "SmoothPlastic", triangles = 200 },
	} },
	{ name = "deco_grass_1", parts = {
		{ class = "UnionOperation", size = { 4.6974845, 8, 4.7766523 }, position = { 0, 0, 0 }, rotation = { 1, 0, 0, 0, 1, 0, 0, 0, 1 }, material = "Rock", triangles = 300 },
	} },
	{ name = "deco_root_1", parts = {
		{ class = "MeshPart", size = { 8.00016, 3.3830092, 6.7916985 }, position = { 0, 0, 0 }, rotation = { 1, 0, 0, 0, 1, 0, 0, 0, 1 }, material = "Rock", triangles = 500, alpha = "Overlay" },
	} },
	{ name = "deco_root_2", parts = {
		{ class = "MeshPart", size = { 8.0001955, 6.4019356, 6.730896 }, position = { 0, 0, 0 }, rotation = { 1, 0, 0, 0, 1, 0, 0, 0, 1 }, material = "Rock", triangles = 500, alpha = "Overlay" },
	} },
	{ name = "deco_root_3", parts = {
		{ class = "MeshPart", size = { 8.000298, 5.5470977, 5.497707 }, position = { 0, 0, 0 }, rotation = { 1, 0, 0, 0, 1, 0, 0, 0, 1 }, material = "Rock", triangles = 500, alpha = "Overlay" },
	} },
	{ name = "deco_root_4", parts = {
		{ class = "MeshPart", size = { 8.000302, 5.3415504, 5.617521 }, position = { 0, 0, 0 }, rotation = { 1, 0, 0, 0, 1, 0, 0, 0, 1 }, material = "Rock", triangles = 500, alpha = "Overlay" },
	} },
	{ name = "deco_root_5", parts = {
		{ class = "MeshPart", size = { 7.3589478, 7.548081, 8 }, position = { 0, 0, 0 }, rotation = { 1, 0, 0, 0, 1, 0, 0, 0, 1 }, material = "Rock", triangles = 500, alpha = "Overlay" },
	} },
	{ name = "rock_1", parts = {
		{ class = "MeshPart", size = { 7.510312, 1.6262145, 8.0001955 }, position = { 0, 0, 0 }, rotation = { 1, 0, 0, 0, 1, 0, 0, 0, 1 }, material = "Rock", triangles = 800 },
	} },
	{ name = "rock_10", parts = {
		{ class = "MeshPart", size = { 4.977342, 8.0005865, 5.0122104 }, position = { 0, 0, 0 }, rotation = { 1, 0, 0, 0, 1, 0, 0, 0, 1 }, material = "Rock", triangles = 800 },
	} },
	{ name = "rock_11", parts = {
		{ class = "MeshPart", size = { 8, 3.1728854, 7.41803 }, position = { 0, 0, 0 }, rotation = { 1, 0, 0, 0, 1, 0, 0, 0, 1 }, material = "Rock", triangles = 800 },
	} },
	{ name = "rock_12", parts = {
		{ class = "MeshPart", size = { 8, 3.9648106, 6.6890535 }, position = { 0, 0, 0 }, rotation = { 1, 0, 0, 0, 1, 0, 0, 0, 1 }, material = "Rock", triangles = 800 },
	} },
	{ name = "rock_13", parts = {
		{ class = "MeshPart", size = { 8.0001955, 4.8365912, 6.8125043 }, position = { 0, 0, 0 }, rotation = { 1, 0, 0, 0, 1, 0, 0, 0, 1 }, material = "Rock", triangles = 800 },
	} },
	{ name = "rock_14", parts = {
		{ class = "MeshPart", size = { 7.083673, 5.974621, 8.000196 }, position = { 0, 0, 0 }, rotation = { 1, 0, 0, 0, 1, 0, 0, 0, 1 }, material = "Rock", triangles = 800 },
	} },
	{ name = "rock_15", parts = {
		{ class = "MeshPart", size = { 5.985323, 4.6307516, 8.000782 }, position = { 0, 0, 0 }, rotation = { 1, 0, 0, 0, 1, 0, 0, 0, 1 }, material = "Rock", triangles = 800 },
	} },
	{ name = "rock_16", parts = {
		{ class = "MeshPart", size = { 6.9144835, 7.9555073, 8.0001955 }, position = { 0, 0, 0 }, rotation = { 1, 0, 0, 0, 1, 0, 0, 0, 1 }, material = "Rock", triangles = 800 },
	} },
	{ name = "rock_17", parts = {
		{ class = "MeshPart", size = { 6.2188654, 6.0943336, 8.000196 }, position = { 0, 0, 0 }, rotation = { 1, 0, 0, 0, 1, 0, 0, 0, 1 }, material = "Rock", triangles = 800 },
	} },
	{ name = "rock_18", parts = {
		{ class = "MeshPart", size = { 7.415146, 6.9823847, 8.0001955 }, position = { 0, 0, 0 }, rotation = { 1, 0, 0, 0, 1, 0, 0, 0, 1 }, material = "Rock", triangles = 800 },
	} },
	{ name = "rock_19", parts = {
		{ class = "MeshPart", size = { 7.167509, 8, 7.2522497 }, position = { 0, 0, 0 }, rotation = { 1, 0, 0, 0, 1, 0, 0, 0, 1 }, material = "Rock", triangles = 800 },
	} },
	{ name = "rock_2", parts = {
		{ class = "MeshPart", size = { 4.650516, 4.320303, 8 }, position = { 0, 0, 0 }, rotation = { 1, 0, 0, 0, 1, 0, 0, 0, 1 }, material = "Rock", triangles = 800 },
	} },
	{ name = "rock_20", parts = {
		{ class = "MeshPart", size = { 8.000783, 5.568282, 7.7863016 }, position = { 0, 0, 0 }, rotation = { 1, 0, 0, 0, 1, 0, 0, 0, 1 }, material = "Rock", triangles = 800 },
	} },
	{ name = "rock_21", parts = {
		{ class = "MeshPart", size = { 8, 4.782571, 7.9729867 }, position = { 0, 0, 0 }, rotation = { 1, 0, 0, 0, 1, 0, 0, 0, 1 }, material = "Rock", triangles = 800 },
	} },
	{ name = "rock_22", parts = {
		{ class = "MeshPart", size = { 8.000196, 4.431237, 6.4733357 }, position = { 0, 0, 0 }, rotation = { 1, 0, 0, 0, 1, 0, 0, 0, 1 }, material = "Rock", triangles = 800 },
	} },
	{ name = "rock_23", parts = {
		{ class = "MeshPart", size = { 7.3428974, 6.876541, 8 }, position = { 0, 0, 0 }, rotation = { 1, 0, 0, 0, 1, 0, 0, 0, 1 }, material = "Rock", triangles = 800 },
	} },
	{ name = "rock_24", parts = {
		{ class = "MeshPart", size = { 6.7568016, 7.2141175, 8 }, position = { 0, 0, 0 }, rotation = { 1, 0, 0, 0, 1, 0, 0, 0, 1 }, material = "Rock", triangles = 800 },
	} },
	{ name = "rock_25", parts = {
		{ class = "MeshPart", size = { 7.5565143, 5.755163, 8 }, position = { 0, 0, 0 }, rotation = { 1, 0, 0, 0, 1, 0, 0, 0, 1 }, material = "Rock", triangles = 800 },
	} },
	{ name = "rock_26", parts = {
		{ class = "MeshPart", size = { 7.159605, 5.452967, 8 }, position = { 0, 0, 0 }, rotation = { 1, 0, 0, 0, 1, 0, 0, 0, 1 }, material = "Rock", triangles = 800 },
	} },
	{ name = "rock_27", parts = {
		{ class = "MeshPart", size = { 8, 4.673073, 7.1976233 }, position = { 0, 0, 0 }, rotation = { 1, 0, 0, 0, 1, 0, 0, 0, 1 }, material = "Rock", triangles = 800 },
	} },
	{ name = "rock_28", parts = {
		{ class = "MeshPart", size = { 7.3758626, 6.9682093, 8 }, position = { 0, 0, 0 }, rotation = { 1, 0, 0, 0, 1, 0, 0, 0, 1 }, material = "Rock", triangles = 800 },
	} },
	{ name = "rock_29", parts = {
		{ class = "MeshPart", size = { 8.000978, 5.3939104, 7.89155 }, position = { 0, 0, 0 }, rotation = { 1, 0, 0, 0, 1, 0, 0, 0, 1 }, material = "Rock", triangles = 800 },
	} },
	{ name = "rock_3", parts = {
		{ class = "MeshPart", size = { 7.443881, 4.4982185, 8.000196 }, position = { 0, 0, 0 }, rotation = { 1, 0, 0, 0, 1, 0, 0, 0, 1 }, material = "Rock", triangles = 800 },
	} },
	{ name = "rock_30", parts = {
		{ class = "MeshPart", size = { 8.000391, 4.341261, 7.739383 }, position = { 0, 0, 0 }, rotation = { 1, 0, 0, 0, 1, 0, 0, 0, 1 }, material = "Rock", triangles = 800 },
	} },
	{ name = "rock_31", parts = {
		{ class = "MeshPart", size = { 8, 5.711503, 7.347551 }, position = { 0, 0, 0 }, rotation = { 1, 0, 0, 0, 1, 0, 0, 0, 1 }, material = "Rock", triangles = 800 },
	} },
	{ name = "rock_32", parts = {
		{ class = "MeshPart", size = { 5.130086, 8.000196, 3.8536043 }, position = { 0, 0, 0 }, rotation = { 1, 0, 0, 0, 1, 0, 0, 0, 1 }, material = "Rock", triangles = 800 },
	} },
	{ name = "rock_33", parts = {
		{ class = "MeshPart", size = { 7.0686927, 6.638809, 8 }, position = { 0, 0, 0 }, rotation = { 1, 0, 0, 0, 1, 0, 0, 0, 1 }, material = "Rock", triangles = 800 },
	} },
	{ name = "rock_34", parts = {
		{ class = "MeshPart", size = { 5.889462, 8, 7.5977736 }, position = { 0, 0, 0 }, rotation = { 1, 0, 0, 0, 1, 0, 0, 0, 1 }, material = "Rock", triangles = 800 },
	} },
	{ name = "rock_35", parts = {
		{ class = "MeshPart", size = { 8, 4.9472356, 7.4190497 }, position = { 0, 0, 0 }, rotation = { 1, 0, 0, 0, 1, 0, 0, 0, 1 }, material = "Rock", triangles = 800 },
	} },
	{ name = "rock_36", parts = {
		{ class = "MeshPart", size = { 5.1133237, 8, 4.6377563 }, position = { 0, 0, 0 }, rotation = { 1, 0, 0, 0, 1, 0, 0, 0, 1 }, material = "Rock", triangles = 800 },
	} },
	{ name = "rock_37", parts = {
		{ class = "MeshPart", size = { 7.370669, 5.5280657, 8 }, position = { 0, 0, 0 }, rotation = { 1, 0, 0, 0, 1, 0, 0, 0, 1 }, material = "Rock", triangles = 800 },
	} },
	{ name = "rock_38", parts = {
		{ class = "MeshPart", size = { 6.7959046, 8.000391, 7.228667 }, position = { 0, 0, 0 }, rotation = { 1, 0, 0, 0, 1, 0, 0, 0, 1 }, material = "Rock", triangles = 800 },
	} },
	{ name = "rock_39", parts = {
		{ class = "MeshPart", size = { 8, 6.642792, 6.9471927 }, position = { 0, 0, 0 }, rotation = { 1, 0, 0, 0, 1, 0, 0, 0, 1 }, material = "Rock", triangles = 800 },
	} },
	{ name = "rock_4", parts = {
		{ class = "MeshPart", size = { 8, 7.58878, 6.589417 }, position = { 0, 0, 0 }, rotation = { 1, 0, 0, 0, 1, 0, 0, 0, 1 }, material = "Rock", triangles = 800 },
	} },
	{ name = "rock_40", parts = {
		{ class = "MeshPart", size = { 7.311695, 6.107521, 8 }, position = { 0, 0, 0 }, rotation = { 1, 0, 0, 0, 1, 0, 0, 0, 1 }, material = "Rock", triangles = 800 },
	} },
	{ name = "rock_41", parts = {
		{ class = "MeshPart", size = { 5.4330363, 8, 4.4564743 }, position = { 0, 0, 0 }, rotation = { 1, 0, 0, 0, 1, 0, 0, 0, 1 }, material = "Rock", triangles = 800 },
	} },
	{ name = "rock_42", parts = {
		{ class = "MeshPart", size = { 5.007542, 3.6908848, 8 }, position = { 0, 0, 0 }, rotation = { 1, 0, 0, 0, 1, 0, 0, 0, 1 }, material = "Rock", triangles = 800 },
	} },
	{ name = "rock_43", parts = {
		{ class = "MeshPart", size = { 8.000392, 3.2843592, 5.4602356 }, position = { 0, 0, 0 }, rotation = { 1, 0, 0, 0, 1, 0, 0, 0, 1 }, material = "Rock", triangles = 800 },
	} },
	{ name = "rock_44", parts = {
		{ class = "MeshPart", size = { 8, 5.560181, 7.4523735 }, position = { 0, 0, 0 }, rotation = { 1, 0, 0, 0, 1, 0, 0, 0, 1 }, material = "Rock", triangles = 800 },
	} },
	{ name = "rock_45", parts = {
		{ class = "MeshPart", size = { 8, 6.9461937, 7.008265 }, position = { 0, 0, 0 }, rotation = { 1, 0, 0, 0, 1, 0, 0, 0, 1 }, material = "Rock", triangles = 800 },
	} },
	{ name = "rock_46", parts = {
		{ class = "MeshPart", size = { 8, 4.495345, 6.279809 }, position = { 0, 0, 0 }, rotation = { 1, 0, 0, 0, 1, 0, 0, 0, 1 }, material = "Rock", triangles = 800 },
	} },
	{ name = "rock_47", parts = {
		{ class = "MeshPart", size = { 8, 5.1384153, 7.015895 }, position = { 0, 0, 0 }, rotation = { 1, 0, 0, 0, 1, 0, 0, 0, 1 }, material = "Rock", triangles = 800 },
	} },
	{ name = "rock_48", parts = {
		{ class = "MeshPart", size = { 6.0425386, 4.036798, 8 }, position = { 0, 0, 0 }, rotation = { 1, 0, 0, 0, 1, 0, 0, 0, 1 }, material = "Rock", triangles = 800 },
	} },
	{ name = "rock_49", parts = {
		{ class = "MeshPart", size = { 8, 4.1703644, 7.388587 }, position = { 0, 0, 0 }, rotation = { 1, 0, 0, 0, 1, 0, 0, 0, 1 }, material = "Rock", triangles = 800 },
	} },
	{ name = "rock_5", parts = {
		{ class = "MeshPart", size = { 8, 2.977866, 6.8121877 }, position = { 0, 0, 0 }, rotation = { 1, 0, 0, 0, 1, 0, 0, 0, 1 }, material = "Rock", triangles = 800 },
	} },
	{ name = "rock_6", parts = {
		{ class = "MeshPart", size = { 6.622171, 6.768947, 8.000196 }, position = { 0, 0, 0 }, rotation = { 1, 0, 0, 0, 1, 0, 0, 0, 1 }, material = "Rock", triangles = 800 },
	} },
	{ name = "rock_7", parts = {
		{ class = "MeshPart", size = { 7.4710007, 4.332163, 8 }, position = { 0, 0, 0 }, rotation = { 1, 0, 0, 0, 1, 0, 0, 0, 1 }, material = "Rock", triangles = 800 },
	} },
	{ name = "rock_8", parts = {
		{ class = "MeshPart", size = { 6.7154307, 4.3816915, 7.9999995 }, position = { 0, 0, 0 }, rotation = { 1, 0, 0, 0, 1, 0, 0, 0, 1 }, material = "Rock", triangles = 800 },
	} },
	{ name = "rock_9", parts = {
		{ class = "MeshPart", size = { 8, 5.6979265, 7.997538 }, position = { 0, 0, 0 }, rotation = { 1, 0, 0, 0, 1, 0, 0, 0, 1 }, material = "Rock", triangles = 800 },
	} },
	{ name = "tree_1", parts = {
		{ class = "MeshPart", size = { 3.714088, 7.1151223, 3.1262467 }, position = { 0.1428, -0.8391288, 0.056080222 }, rotation = { 1, 0, 0, 0, 1, 0, 0, 0, 1 }, material = "Wood", triangles = 300, alpha = "Overlay" },
		{ class = "MeshPart", size = { 5.7983375, 5.5283623, 5.346836 }, position = { -0.1428, 0.8391288, -0.056080222 }, rotation = { 1, 0, 0, 0, 1, 0, 0, 0, 1 }, material = "LeafyGrass", triangles = 1200, alpha = "Transparency" },
	} },
	{ name = "tree_10", parts = {
		{ class = "MeshPart", size = { 3.6491559, 5.3568583, 3.433696 }, position = { -0.052, 0.6713156, 0.067384145 }, rotation = { 1, 0, 0, 0, 1, 0, 0, 0, 1 }, material = "LeafyGrass", triangles = 1200, alpha = "Transparency" },
		{ class = "MeshPart", size = { 2.6174936, 7.95827, 2.6335895 }, position = { 0.052, -0.6713156, -0.067384145 }, rotation = { 1, 0, 0, 0, 1, 0, 0, 0, 1 }, material = "Wood", triangles = 300, alpha = "Overlay" },
	} },
	{ name = "tree_11", parts = {
		{ class = "MeshPart", size = { 4.836712, 5.836539, 4.3222957 }, position = { -0.0178, 0.75524485, 0.03398515 }, rotation = { 0, 0, -1, 0, 1, 0, 1, 0, 0 }, material = "LeafyGrass", triangles = 1200, alpha = "Transparency" },
		{ class = "MeshPart", size = { 4.0333724, 7.142831, 3.5635238 }, position = { 0.0178, -0.75524485, -0.03398515 }, rotation = { 0, 0, -1, 0, 1, 0, 1, 0, 0 }, material = "Wood", triangles = 300, alpha = "Overlay" },
	} },
	{ name = "tree_12", parts = {
		{ class = "MeshPart", size = { 3.5058682, 7.0942554, 2.5873005 }, position = { -0.1128, -1.0647124, -0.007323069 }, rotation = { -1, 0, 0, 0, 1, 0, 0, 0, -1 }, material = "Wood", triangles = 300, alpha = "Overlay" },
		{ class = "MeshPart", size = { 5.0288577, 4.6472416, 4.1693993 }, position = { 0.1128, 1.0647124, 0.007323069 }, rotation = { -1, 0, 0, 0, 1, 0, 0, 0, -1 }, material = "LeafyGrass", triangles = 1200, alpha = "Transparency" },
	} },
	{ name = "tree_13", parts = {
		{ class = "MeshPart", size = { 2.922697, 7.1538177, 1.8946699 }, position = { -0.01415, -1.21758735, 0.00206787115 }, rotation = { 1, 0, 0, 0, 1, 0, 0, 0, 1 }, material = "Wood", triangles = 300, alpha = "Overlay" },
		{ class = "MeshPart", size = { 4.4988046, 3.976181, 4.4752903 }, position = { 0.01415, 1.21758735, -0.00206787115 }, rotation = { 1, 0, 0, 0, 1, 0, 0, 0, 1 }, material = "LeafyGrass", triangles = 1200, alpha = "Transparency" },
	} },
	{ name = "tree_14", parts = {
		{ class = "MeshPart", size = { 4.6242995, 3.6767225, 4.248249 }, position = { 0.03075, 1.43880355, 0.174127175 }, rotation = { 1, 0, 0, 0, 1, 0, 0, 0, 1 }, material = "LeafyGrass", triangles = 1200, alpha = "Transparency" },
		{ class = "MeshPart", size = { 1.8661745, 6.5680637, 1.5564022 }, position = { -0.03075, -1.43880355, -0.174127175 }, rotation = { 1, 0, 0, 0, 1, 0, 0, 0, 1 }, material = "Wood", triangles = 300, alpha = "Overlay" },
	} },
	{ name = "tree_15", parts = {
		{ class = "MeshPart", size = { 5.218521, 4.9906855, 5.2585144 }, position = { 0.11815, 1.0477115, 0.095491155 }, rotation = { 1, 0, 0, 0, 1, 0, 0, 0, 1 }, material = "LeafyGrass", triangles = 1200, alpha = "Transparency" },
		{ class = "MeshPart", size = { 2.967373, 6.818802, 2.1384764 }, position = { -0.11815, -1.0477115, -0.095491155 }, rotation = { 1, 0, 0, 0, 1, 0, 0, 0, 1 }, material = "Wood", triangles = 300, alpha = "Overlay" },
	} },
	{ name = "tree_16", parts = {
		{ class = "MeshPart", size = { 3.5858245, 5.409511, 3.4218879 }, position = { -0.06885, 0.771948, -0.0104452895 }, rotation = { 1, 0, 0, 0, 1, 0, 0, 0, 1 }, material = "LeafyGrass", triangles = 1200, alpha = "Transparency" },
		{ class = "MeshPart", size = { 1.0882317, 7.5030646, 0.8349466 }, position = { 0.06885, -0.771948, 0.0104452895 }, rotation = { 1, 0, 0, 0, 1, 0, 0, 0, 1 }, material = "Wood", triangles = 300, alpha = "Overlay" },
	} },
	{ name = "tree_17", parts = {
		{ class = "MeshPart", size = { 6.3550043, 6.8025255, 2.9040346 }, position = { 0.4535, -1.3165349, 0.4051921 }, rotation = { 0.70710516, 0, -0.70710516, 0, 1, 0, 0.70710516, 0, 0.70710516 }, material = "Wood", triangles = 300, alpha = "Overlay" },
		{ class = "MeshPart", size = { 7.2173357, 3.3154557, 5.5687532 }, position = { -0.4535, 1.3165349, -0.4051921 }, rotation = { 0.70710516, 0, -0.70710516, 0, 1, 0, 0.70710516, 0, 0.70710516 }, material = "LeafyGrass", triangles = 1200, alpha = "Transparency" },
	} },
	{ name = "tree_18", parts = {
		{ class = "MeshPart", size = { 6.089092, 4.0223994, 5.8960934 }, position = { 0.04125, 1.2262756, 0.12414 }, rotation = { 1, 0, 0, 0, 1, 0, 0, 0, 1 }, material = "LeafyGrass", triangles = 1200, alpha = "Transparency" },
		{ class = "MeshPart", size = { 5.099271, 7.0724983, 3.7742152 }, position = { -0.04125, -1.2262756, -0.12414 }, rotation = { 1, 0, 0, 0, 1, 0, 0, 0, 1 }, material = "Wood", triangles = 300, alpha = "Overlay" },
	} },
	{ name = "tree_19", parts = {
		{ class = "MeshPart", size = { 6.4182177, 4.813759, 5.7709193 }, position = { -0.038, 0.8938589, 0.106541545 }, rotation = { 1, 0, 0, 0, 1, 0, 0, 0, 1 }, material = "LeafyGrass", triangles = 1200, alpha = "Transparency" },
		{ class = "MeshPart", size = { 4.9782825, 7.610806, 4.7859917 }, position = { 0.038, -0.8938589, -0.106541545 }, rotation = { 1, 0, 0, 0, 1, 0, 0, 0, 1 }, material = "Wood", triangles = 300, alpha = "Overlay" },
	} },
	{ name = "tree_2", parts = {
		{ class = "MeshPart", size = { 7.179485, 6.6316185, 5.1471477 }, position = { -0.07935, 0.6310101, 0.0410408825 }, rotation = { 0.70710516, 0, 0.70710516, 0, 1, 0, -0.70710516, 0, 0.70710516 }, material = "LeafyGrass", triangles = 1200, alpha = "Transparency" },
		{ class = "MeshPart", size = { 5.075625, 6.8443418, 2.8646617 }, position = { 0.07935, -0.6310101, -0.0410408825 }, rotation = { 0.70710516, 0, 0.70710516, 0, 1, 0, -0.70710516, 0, 0.70710516 }, material = "Wood", triangles = 300, alpha = "Overlay" },
	} },
	{ name = "tree_20", parts = {
		{ class = "MeshPart", size = { 2.7914195, 4.7074566, 2.7177622 }, position = { -0.0135, 0.8425611, 0.0023158686 }, rotation = { 1, 0, 0, 0, 1, 0, 0, 0, 1 }, material = "LeafyGrass", triangles = 1200, alpha = "Transparency" },
		{ class = "MeshPart", size = { 2.0665944, 7.922299, 2.0939617 }, position = { 0.0135, -0.8425611, -0.0023158686 }, rotation = { 1, 0, 0, 0, 1, 0, 0, 0, 1 }, material = "Wood", triangles = 300, alpha = "Overlay" },
	} },
	{ name = "tree_3", parts = {
		{ class = "MeshPart", size = { 8.000004, 4.655986, 6.201814 }, position = { 0.1625, 0.86455295, -0.094403475 }, rotation = { 0.70710516, 0, 0.70710516, 0, 1, 0, -0.70710516, 0, 0.70710516 }, material = "LeafyGrass", triangles = 1200, alpha = "Transparency" },
		{ class = "MeshPart", size = { 6.150532, 6.3890343, 4.1012106 }, position = { -0.1625, -0.86455295, 0.094403475 }, rotation = { 0.70710516, 0, 0.70710516, 0, 1, 0, -0.70710516, 0, 0.70710516 }, material = "Wood", triangles = 300, alpha = "Overlay" },
	} },
	{ name = "tree_4", parts = {
		{ class = "MeshPart", size = { 3.212643, 6.7841697, 1.967936 }, position = { -0.0715, -0.95815565, -0.051953867 }, rotation = { 1, 0, 0, 0, 1, 0, 0, 0, 1 }, material = "Wood", triangles = 300, alpha = "Overlay" },
		{ class = "MeshPart", size = { 5.6702986, 5.3832073, 4.6037354 }, position = { 0.0715, 0.95815565, 0.051953867 }, rotation = { 1, 0, 0, 0, 1, 0, 0, 0, 1 }, material = "LeafyGrass", triangles = 1200, alpha = "Transparency" },
	} },
	{ name = "tree_5", parts = {
		{ class = "MeshPart", size = { 3.7254553, 6.8674417, 2.9072874 }, position = { -0.00075, -0.77988435, 0.071030535 }, rotation = { 0.70710516, 0, 0.70710516, 0, 1, 0, -0.70710516, 0, 0.70710516 }, material = "Wood", triangles = 300, alpha = "Overlay" },
		{ class = "MeshPart", size = { 5.8861494, 6.0133557, 5.1396084 }, position = { 0.00075, 0.77988435, -0.071030535 }, rotation = { 0.70710516, 0, 0.70710516, 0, 1, 0, -0.70710516, 0, 0.70710516 }, material = "LeafyGrass", triangles = 1200, alpha = "Transparency" },
	} },
	{ name = "tree_6", parts = {
		{ class = "MeshPart", size = { 5.5808883, 6.5236764, 3.5416005 }, position = { -0.12475, -0.9068718, 0.17227145 }, rotation = { 0, 0, 0.9999952, 0, 1, 0, -0.9999952, 0, 0 }, material = "Wood", triangles = 300, alpha = "Overlay" },
		{ class = "MeshPart", size = { 8.000009, 5.4303956, 5.418286 }, position = { 0.12475, 0.9068718, -0.17227145 }, rotation = { 0, 0, 0.9999952, 0, 1, 0, -0.9999952, 0, 0 }, material = "LeafyGrass", triangles = 1200, alpha = "Transparency" },
	} },
	{ name = "tree_7", parts = {
		{ class = "MeshPart", size = { 3.0452924, 7.2228527, 2.7082927 }, position = { 0.09325, -0.78145885, -0.093420825 }, rotation = { 1, 0, 0, 0, 1, 0, 0, 0, 1 }, material = "Wood", triangles = 300, alpha = "Overlay" },
		{ class = "MeshPart", size = { 4.548897, 5.651313, 4.475803 }, position = { -0.09325, 0.78145885, 0.093420825 }, rotation = { 1, 0, 0, 0, 1, 0, 0, 0, 1 }, material = "LeafyGrass", triangles = 1200, alpha = "Transparency" },
	} },
	{ name = "tree_8", parts = {
		{ class = "MeshPart", size = { 1.8881558, 7.38687, 1.7685708 }, position = { -0.03175, -0.794719, -0.0038226445 }, rotation = { 1, 0, 0, 0, 1, 0, 0, 0, 1 }, material = "Wood", triangles = 300, alpha = "Overlay" },
		{ class = "MeshPart", size = { 3.1430633, 5.4342546, 2.9264138 }, position = { 0.03175, 0.794719, 0.0038226445 }, rotation = { 1, 0, 0, 0, 1, 0, 0, 0, 1 }, material = "LeafyGrass", triangles = 1200, alpha = "Transparency" },
	} },
	{ name = "tree_9", parts = {
		{ class = "MeshPart", size = { 7.8561707, 3.3642967, 5.869587 }, position = { 0.0635, 1.49509295, 0.072498785 }, rotation = { 1, 0, 0, 0, 1, 0, 0, 0, 1 }, material = "LeafyGrass", triangles = 1200, alpha = "Transparency" },
		{ class = "MeshPart", size = { 5.32165, 6.6553307, 3.221512 }, position = { -0.0635, -1.49509295, -0.072498785 }, rotation = { 1, 0, 0, 0, 1, 0, 0, 0, 1 }, material = "Wood", triangles = 300, alpha = "Overlay" },
	} },
}
local function originalMetricAssets()
	freshAssets()
	local package = Instance.new("Folder"); package.Name, package.Parent = "grasland_pack", models
	for _, sample in packageSamples do
		local model = Instance.new("Model"); model.Name, model.Parent = sample.name, package
		for _, data in sample.parts do
			local part = Instance.new(data.class)
			part.Size = Vector3.new(table.unpack(data.size))
			local cf = CFrame.new(table.unpack(data.position)); cf.rotation = data.rotation
			part.CFrame, part.Material, part.Parent = cf, Enum.Material[data.material], model
			part:SetAttribute("EstimatedTriangles", data.triangles)
			if data.alpha then
				local appearance = Instance.new("SurfaceAppearance")
				appearance.AlphaMode, appearance.Parent = Enum.AlphaMode[data.alpha], part
			end
		end
	end
end
