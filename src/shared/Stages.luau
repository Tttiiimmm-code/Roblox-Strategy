-- Tutorial-Missionen und Gebiete für Tutorial, Läufe und Brett
local Config = require(script.Parent.Config)
local Stages = {}

Stages.Regions = {
	{ id = "greenland", name = "Grünland", color = Color3.fromRGB(110, 170, 90), area = { 0.02, 0.38, 0.42, 0.58 }, atmosphere = "battle", surroundMaterial = Enum.Material.Grass, surroundColor = Color3.fromRGB(73, 86, 64), treeColor = Config.TERRAIN.F.color },
	{ id = "swamp", name = "Nebelsumpf", color = Color3.fromRGB(85, 115, 85), area = { 0.40, 0.45, 0.30, 0.50 }, atmosphere = "swamp", surroundMaterial = Enum.Material.Grass, treeColor = Color3.fromRGB(55, 75, 45),
		grassColor = Color3.fromRGB(62, 69, 48), waterColor = Color3.fromRGB(41, 47, 34),
		surroundColor = Color3.fromRGB(55, 67, 49), terrainColors = { ["."] = Color3.fromRGB(86, 107, 73), F = Color3.fromRGB(57, 78, 53), W = Color3.fromRGB(63, 88, 98), D = Config.TERRAIN.D.color } },
	{ id = "ice", name = "Frostgipfel", color = Color3.fromRGB(175, 205, 235), area = { 0.30, 0.02, 0.40, 0.38 }, surroundColor = Color3.fromRGB(107, 119, 123), comingSoon = true },
	{ id = "volcano", name = "Glutberg", color = Color3.fromRGB(175, 75, 50), area = { 0.70, 0.30, 0.28, 0.65 }, surroundColor = Color3.fromRGB(63, 58, 54), comingSoon = true },
}

for _, region in Stages.Regions do
	region.groundColors = table.clone(Config.GROUND_COLORS)
	region.treePalette = Config.TREE_PALETTES[region.id]
	region.landscape = table.clone(Config.LANDSCAPE.palette)
	region.landscape.colors = table.clone(Config.LANDSCAPE.palette.colors)
	region.landscape.colors[Enum.Material.Grass] = region.surroundColor
end
Stages.Regions[2].groundColors.grassLighten = 0.42
Stages.Regions[3].groundColors.grassLighten = 0.12
Stages.Regions[4].groundColors.grassLighten = 0.42
Stages.Regions[2].landscape.ground = Enum.Material.Mud
Stages.Regions[2].landscape.colors[Enum.Material.Mud] = Color3.fromRGB(62, 59, 43)
Stages.Regions[3].landscape.grass = Enum.Material.Snow
Stages.Regions[3].landscape.colors[Enum.Material.Snow] = Color3.fromRGB(196, 213, 218)
Stages.Regions[4].landscape.grass = Enum.Material.Ground

Stages.List = {
	{
		id = "tutorial1", name = "Tutorial 1 – Leon", region = "greenland",
		map = { "......", "......", "......", "......", "......" },
		heroes = { "leon" }, slots = { { x = 2, y = 5 } },
		enemies = { { kind = "brigand", x = 3, y = 2, tutorialTarget = "bandit" } },
		move = { x = 2, y = 3 }, enemyMove = { x = 3, y = 3 },
	},
	{
		id = "tutorial2", name = "Tutorial 2 – Dein Team", region = "greenland",
		map = { "..........", "..........", "..........", "..........", "..........", ".........." },
		heroes = { "leon", "starter_mage", "starter_knight" },
		slots = { { x = 1, y = 5 }, { x = 2, y = 4 }, { x = 3, y = 3 } },
		enemies = {
			{ kind = "brigand", x = 4, y = 4, tutorialTarget = "mage" },
			{ kind = "archer", x = 10, y = 2, tutorialTarget = "knight" },
			{ kind = "brigand", x = 5, y = 3 },
		},
		move = { x = 9, y = 2 },
	},
}

function Stages.get(id)
	for _, stage in Stages.List do
		if stage.id == id then return stage end
	end
	return nil
end

function Stages.getRegion(id)
	for _, region in Stages.Regions do
		if region.id == id then return region end
	end
	return nil
end

return Stages
