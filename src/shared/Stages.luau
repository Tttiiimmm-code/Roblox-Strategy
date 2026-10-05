-- Missionen, Schwierigkeitsstufen, Sterneziele und Freischaltregeln
local Stages = {}

-- enemyBonus: Wertänderung für alle Gegner · undo: Anzahl Rückblenden · turnBonus: Änderung am Rundenziel
-- maxUnits: höchstens so viele eigene Einheiten · requires: diese Stufe muss vorher geschafft sein
Stages.Difficulties = {
	{
		id = "Easy", name = "Leicht", color = Color3.fromRGB(110, 214, 120),
		enemyBonus = { hp = -3, str = -1, skl = -1, spd = -1, def = -1 },
		rewardMul = 1, gemsPerStar = 5, undo = 3, turnBonus = 4,
		rules = { "Schwächere Gegner", "3× Rückblende (Zug zurücknehmen)", "Großzügiges Rundenziel" },
	},
	{
		id = "Normal", name = "Normal", color = Color3.fromRGB(90, 160, 255),
		enemyBonus = {},
		rewardMul = 2, gemsPerStar = 10, undo = 1, turnBonus = 0,
		rules = { "Ausgewogene Gegner", "1× Rückblende" },
	},
	{
		id = "Hard", name = "Schwer", color = Color3.fromRGB(255, 110, 110),
		enemyBonus = { hp = 4, str = 2, skl = 2, spd = 1, def = 1 },
		rewardMul = 3, gemsPerStar = 20, undo = 0, turnBonus = -1,
		maxUnits = 4, extraEnemies = true, requires = "Normal",
		rules = { "Stärkere und zusätzliche Gegner", "Höchstens 4 Einheiten", "Keine Rückblende" },
	},
}

Stages.Regions = {
	{ id = "greenland", name = "Gr?nland", color = Color3.fromRGB(110, 170, 90), area = { 0.02, 0.38, 0.42, 0.58 }, atmosphere = "battle" },
	{ id = "swamp", name = "Nebelsumpf", color = Color3.fromRGB(85, 115, 85), area = { 0.40, 0.45, 0.30, 0.50 }, atmosphere = "swamp" },
	{ id = "ice", name = "Frostgipfel", color = Color3.fromRGB(175, 205, 235), area = { 0.30, 0.02, 0.40, 0.38 }, comingSoon = true },
	{ id = "volcano", name = "Glutberg", color = Color3.fromRGB(175, 75, 50), area = { 0.70, 0.30, 0.28, 0.65 }, comingSoon = true },
}

Stages.List = {
	{
		id = "s1", name = "Grenzdorf", baseGold = 100, turnGoal = 6,
		region = "greenland", mapPos = Vector2.new(0.10, 0.80), requires = {  },
		description = "Banditen plündern ein Dorf an der Grenze. Vertreibe sie, bevor sie mit der Beute verschwinden!",
		map = {
			"..F....F..",
			"....H.....",
			".F....F...",
			"...F......",
			"......M...",
			".F.....F..",
			"..........",
			"....F.....",
		},
		unlockHero = "mira",
		slots = {
			{ x = 2, y = 7 },
			{ x = 1, y = 8 },
			{ x = 3, y = 8 },
		},
		enemies = {
			{ kind = "brigand", x = 5, y = 2 },
			{ kind = "brigand", x = 8, y = 3 },
			{ kind = "brigand", x = 3, y = 1 },
		},
		hardEnemies = {
			{ kind = "brigand", x = 9, y = 5 },
			{ kind = "archer", x = 6, y = 1 },
		},
	},
	{
		id = "s2", name = "Waldpass", baseGold = 150, turnGoal = 8,
		region = "greenland", mapPos = Vector2.new(0.22, 0.58), requires = { "s1" },
		description = "Soldaten des Grafen bewachen die Brücken über den Fluss. Nur wer den Pass hält, kommt weiter.",
		map = {
			"FF..F..FF..F",
			"F...FF....F.",
			"..F.....F...",
			"WWWWBWWWWBWW",
			"...F....F...",
			".F...FF....F",
			"....F....F..",
			"F.........F.",
			"..F..H...F..",
		},
		unlockHero = "selina",
		slots = {
			{ x = 6, y = 9 },
			{ x = 5, y = 8 },
			{ x = 7, y = 8 },
			{ x = 6, y = 7 },
		},
		enemies = {
			{ kind = "brigand", x = 3, y = 1, level = 2 },
			{ kind = "brigand", x = 10, y = 1, level = 2 },
			{ kind = "soldier", x = 6, y = 2, level = 2 },
			{ kind = "archer", x = 8, y = 3, level = 2 },
			{ kind = "javelin", x = 11, y = 2, level = 2 },
		},
		hardEnemies = {
			{ kind = "brigand", x = 2, y = 5, level = 2 },
			{ kind = "archer", x = 12, y = 5, level = 2 },
		},
	},
	{
		id = "s3", name = "Banditenfestung", baseGold = 220, turnGoal = 10,
		region = "greenland", mapPos = Vector2.new(0.32, 0.82), requires = { "s2" },
		description = "Garrick, der Anführer der Banditen, verschanzt sich in seiner Festung. Zeit, das zu beenden.",
		map = {
			"....F..MM.H.",
			".F.....M....",
			"...WW....F..",
			"..FWW..F....",
			"...WW.....M.",
			".......F....",
			"..F...M..F..",
			".....FF.....",
			".H..........",
			"......F..M..",
		},
		slots = {
			{ x = 2, y = 9 },
			{ x = 3, y = 10 },
			{ x = 3, y = 9 },
			{ x = 1, y = 10 },
			{ x = 1, y = 8 },
		},
		enemies = {
			{ kind = "brigand", x = 6, y = 4, level = 3 },
			{ kind = "brigand", x = 9, y = 3, level = 3 },
			{ kind = "brigand", x = 8, y = 6, level = 3 },
			{ kind = "soldier", x = 10, y = 4, level = 3 },
			{ kind = "javelin", x = 12, y = 2, level = 3 },
			{ kind = "archer", x = 10, y = 1, level = 3 },
			{ kind = "chieftain", x = 11, y = 1, level = 5 },
		},
		hardEnemies = {
			{ kind = "soldier", x = 7, y = 2, level = 3 },
			{ kind = "brigand", x = 12, y = 5, level = 3 },
		},
	},
}

function Stages.get(id)
	for _, stage in Stages.List do
		if stage.id == id then
			return stage
		end
	end
	return nil
end

function Stages.getRegion(id)
	for _, region in Stages.Regions do
		if region.id == id then
			return region
		end
	end
	return nil
end

function Stages.indexOf(id)
	for i, stage in Stages.List do
		if stage.id == id then
			return i
		end
	end
	return nil
end

function Stages.getDifficulty(id)
	for _, diff in Stages.Difficulties do
		if diff.id == id then
			return diff
		end
	end
	return nil
end

-- Texte der drei Sterneziele
function Stages.goalTexts(turnGoal)
	return {
		"Sieg",
		"Keine Einheit verloren",
		("Sieg in höchstens %d Runden"):format(turnGoal),
	}
end

-- Wie viele eigene Einheiten aufgestellt werden dürfen (Felder der Karte, ggf. durch die Stufe begrenzt)
function Stages.unitLimit(stage, diff)
	return math.min(#stage.slots, diff.maxUnits or #stage.slots)
end

function Stages.turnGoal(stage, diff)
	return math.max(1, stage.turnGoal + diff.turnBonus)
end

-- Profil: { stars = { [stageId] = { [difficultyId] = 0..3 } } }
function Stages.bestStars(profile, stageId, diffId)
	local s = profile and profile.stars and profile.stars[stageId]
	return s and s[diffId] or 0
end

function Stages.isCleared(profile, stageId)
	for _, diff in Stages.Difficulties do
		if Stages.bestStars(profile, stageId, diff.id) > 0 then
			return true
		end
	end
	return false
end

-- Eine erf?llte Vorg?ngermission gen?gt; Schwer erst nach Normal
function Stages.isUnlocked(profile, index, diffId)
	local stage = Stages.List[index]
	local diff = Stages.getDifficulty(diffId)
	if not stage or not diff then
		return false
	end
	local unlocked = #stage.requires == 0
	for _, requiredId in stage.requires do
		if Stages.isCleared(profile, requiredId) then
			unlocked = true
			break
		end
	end
	if not unlocked then
		return false
	end
	if diff.requires and Stages.bestStars(profile, stage.id, diff.requires) == 0 then
		return false
	end
	return true
end

return Stages
