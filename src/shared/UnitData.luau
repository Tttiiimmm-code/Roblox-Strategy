-- Waffen, Klassen, Seltenheiten, Helden und Gegnertypen
local UnitData = {}

UnitData.STAT_ORDER = { "hp", "str", "mag", "skl", "spd", "lck", "def", "res" }
UnitData.STAT_NAMES = {
	hp = "KP", str = "Str", mag = "Mag", skl = "Ges",
	spd = "Tmp", lck = "Glk", def = "Vert", res = "Res",
}

-- Seltenheit 1–5: Farbe für Namen, Kartenrahmen und Effekte
UnitData.Rarities = {
	{ name = "Gewöhnlich", color = Color3.fromRGB(170, 176, 188), hex = "#aab0bc" },
	{ name = "Ungewöhnlich", color = Color3.fromRGB(110, 214, 120), hex = "#6ed678" },
	{ name = "Selten", color = Color3.fromRGB(90, 160, 255), hex = "#5aa0ff" },
	{ name = "Episch", color = Color3.fromRGB(190, 110, 255), hex = "#be6eff" },
	{ name = "Legendär", color = Color3.fromRGB(255, 200, 70), hex = "#ffc846" },
}

-- type: Sword/Lance/Axe bilden das Waffendreieck, Bow/Anima sind neutral
UnitData.Weapons = {
	IronSword = { name = "Eisenschwert", type = "Sword", might = 5, hit = 90, crit = 0, minRange = 1, maxRange = 1 },
	IronLance = { name = "Eisenlanze", type = "Lance", might = 7, hit = 80, crit = 0, minRange = 1, maxRange = 1 },
	-- farMight/farHit: Abzug bei Angriff aus 2 Feldern (Werte WIP)
	Javelin = { name = "Wurfspeer", type = "Lance", might = 6, hit = 65, crit = 0, minRange = 1, maxRange = 2, farMight = -3, farHit = -20 },
	IronAxe = { name = "Eisenaxt", type = "Axe", might = 8, hit = 75, crit = 0, minRange = 1, maxRange = 1 },
	SteelAxe = { name = "Stahlaxt", type = "Axe", might = 11, hit = 65, crit = 0, minRange = 1, maxRange = 1 },
	IronBow = { name = "Eisenbogen", type = "Bow", might = 6, hit = 85, crit = 0, minRange = 2, maxRange = 2 },
	Fire = { name = "Feuer", type = "Anima", might = 5, hit = 90, crit = 0, minRange = 1, maxRange = 2, magic = true },
}

-- growths: Wahrscheinlichkeit (%) pro Level-Up, dass der Wert um 1 steigt
UnitData.Classes = {
	Lord = {
		name = "Fürst", mov = 5, moveType = "foot",
		growths = { hp = 70, str = 45, mag = 10, skl = 50, spd = 55, lck = 50, def = 30, res = 25 },
	},
	Cavalier = {
		name = "Kavalier", mov = 7, moveType = "horse",
		growths = { hp = 75, str = 40, mag = 5, skl = 40, spd = 40, lck = 35, def = 30, res = 15 },
	},
	Archer = {
		name = "Bogenschütze", mov = 5, moveType = "foot",
		growths = { hp = 60, str = 40, mag = 5, skl = 55, spd = 45, lck = 40, def = 20, res = 20 },
	},
	Mage = {
		name = "Magier", mov = 5, moveType = "foot",
		growths = { hp = 55, str = 5, mag = 55, skl = 40, spd = 45, lck = 40, def = 15, res = 45 },
	},
	Fighter = {
		name = "Kämpfer", mov = 5, moveType = "foot",
		growths = { hp = 85, str = 55, mag = 0, skl = 35, spd = 30, lck = 30, def = 25, res = 10 },
	},
	Brigand = { name = "Bandit", mov = 5, moveType = "foot", growths = {} },
	Soldier = { name = "Soldat", mov = 5, moveType = "foot", growths = {} },
	EnemyArcher = { name = "Bogenschütze", mov = 5, moveType = "foot", growths = {} },
	EnemyMage = { name = "Hexe", mov = 5, moveType = "foot", growths = {} },
	Chieftain = { name = "Bandenführer", mov = 5, moveType = "foot", growths = {} },
}

-- Offizielle Roblox-Accessoires aus PLAN.md; nur Aussehen, keine Spielwerte.
UnitData.Classes.Lord.look = { hat = 3756500192 }
UnitData.Classes.Cavalier.look = { hat = 98450287 }
UnitData.Classes.Soldier.look = { hat = 8796225 }
UnitData.Classes.Archer.look = { hat = 102623080 }
UnitData.Classes.EnemyArcher.look = { hat = 102623080 }
UnitData.Classes.Mage.look = { hat = 13121508 }
UnitData.Classes.EnemyMage.look = { hat = 13121508 }
UnitData.Classes.Fighter.look = { hat = 74221074 }
UnitData.Classes.Brigand.look = { hat = 74221074 }
UnitData.Classes.Chieftain.look = { hat = 108829551 }

-- Spielbare Helden (Schlüssel = Helden-ID). GRUNDGERÜST – Werte/Namen/Looks frei änderbar.
-- recruitable = false: nicht im Rekrutierungs-Pool · hair: optionale Haarfarbe (sonst Klassen-Standard)
UnitData.Heroes = {
	leon = { name = "Leon", class = "Lord", weapon = "IronSword", rarity = 5, isLord = true, recruitable = false,
		stats = { hp = 20, str = 6, mag = 1, skl = 7, spd = 8, lck = 7, def = 5, res = 3 } },

	-- ★5
	aurelia = { name = "Aurelia", class = "Mage", weapon = "Fire", rarity = 5, hair = Color3.fromRGB(240, 240, 250),
		stats = { hp = 19, str = 1, mag = 9, skl = 7, spd = 8, lck = 7, def = 3, res = 8 } },
	siegfried = { name = "Siegfried", class = "Cavalier", weapon = "IronLance", rarity = 5,
		stats = { hp = 25, str = 9, mag = 0, skl = 7, spd = 7, lck = 5, def = 8, res = 3 } },
	-- ★4
	mira = { name = "Mira", class = "Cavalier", weapon = "IronLance", rarity = 4,
		stats = { hp = 21, str = 6, mag = 0, skl = 5, spd = 6, lck = 4, def = 6, res = 2 } },
	selina = { name = "Selina", class = "Mage", weapon = "Fire", rarity = 4,
		stats = { hp = 16, str = 1, mag = 7, skl = 5, spd = 6, lck = 5, def = 2, res = 6 } },
	-- Platzhalter – Design/Name vom Nutzer
	starter_mage = { name = "Magierin", class = "Mage", weapon = "Fire", rarity = 3, recruitable = false,
		stats = { hp = 16, str = 0, mag = 6, skl = 6, spd = 5, lck = 4, def = 2, res = 5 } },
	starter_knight = { name = "Ritter", class = "Cavalier", weapon = "IronLance", rarity = 3, recruitable = false,
		stats = { hp = 21, str = 6, mag = 0, skl = 5, spd = 6, lck = 4, def = 6, res = 2 } },
	-- ★3
	tobi = { name = "Tobi", class = "Archer", weapon = "IronBow", rarity = 3,
		stats = { hp = 17, str = 5, mag = 0, skl = 6, spd = 6, lck = 4, def = 4, res = 2 } },
	greta = { name = "Greta", class = "Mage", weapon = "Fire", rarity = 3, hair = Color3.fromRGB(120, 130, 170),
		stats = { hp = 16, str = 0, mag = 6, skl = 6, spd = 5, lck = 4, def = 2, res = 5 } },
	-- ★2
	bruno = { name = "Bruno", class = "Fighter", weapon = "IronAxe", rarity = 2,
		stats = { hp = 26, str = 8, mag = 0, skl = 4, spd = 4, lck = 3, def = 4, res = 0 } },
	kai = { name = "Kai", class = "Cavalier", weapon = "IronLance", rarity = 2,
		stats = { hp = 19, str = 5, mag = 0, skl = 4, spd = 5, lck = 3, def = 5, res = 1 } },
	-- ★1
	finn = { name = "Finn", class = "Fighter", weapon = "IronAxe", rarity = 1, hair = Color3.fromRGB(190, 80, 40),
		stats = { hp = 22, str = 6, mag = 0, skl = 3, spd = 3, lck = 2, def = 3, res = 0 } },
	ida = { name = "Ida", class = "Archer", weapon = "IronBow", rarity = 1, hair = Color3.fromRGB(235, 205, 120),
		stats = { hp = 15, str = 4, mag = 0, skl = 5, spd = 5, lck = 3, def = 2, res = 1 } },
}

-- Chibi-Aussehen bleibt unabhängig von Spielwerten und Avatar-Accessoires.
local rgb = Color3.fromRGB
local S1, S2, S3 = rgb(236, 196, 164), rgb(205, 150, 110), rgb(150, 100, 70)
local GOLD, METAL = rgb(232, 188, 74), rgb(185, 192, 204)
local function chibi(skin, eyes, hairStyle, hairColor, headgear, headgearColor, primary, secondary, trim, robe, beard, scale)
	return {
		skin = skin, eyes = eyes, hairStyle = hairStyle, hairColor = hairColor,
		headgear = headgear, headgearColor = headgearColor,
		outfit = { primary = primary, secondary = secondary, trim = trim },
		robe = robe == true, beard = beard == true, scale = scale or 1,
	}
end

UnitData.Heroes.leon.chibi = chibi(S1, rgb(60, 110, 200), "spiky", rgb(90, 58, 36), "crown", GOLD,
	rgb(40, 70, 160), rgb(235, 235, 240), GOLD)
UnitData.Heroes.aurelia.chibi = chibi(S1, rgb(150, 90, 210), "long", rgb(240, 240, 250), "tiara", GOLD,
	rgb(245, 245, 250), rgb(220, 190, 110), GOLD, true)
UnitData.Heroes.siegfried.chibi = chibi(S1, rgb(60, 150, 90), "short", rgb(230, 200, 120), "helmet", METAL,
	rgb(190, 195, 205), rgb(150, 25, 35), GOLD)
UnitData.Heroes.siegfried.chibi.plumeColor = GOLD
UnitData.Heroes.mira.chibi = chibi(S2, rgb(60, 140, 120), "ponytail", rgb(200, 60, 50), "headband", METAL,
	rgb(40, 140, 140), rgb(190, 195, 205), rgb(230, 230, 235))
UnitData.Heroes.selina.chibi = chibi(S1, rgb(230, 180, 60), "long", rgb(35, 30, 40), "wizard", rgb(110, 60, 160),
	rgb(110, 60, 160), rgb(40, 35, 50), GOLD, true)
UnitData.Heroes.tobi.chibi = chibi(S2, rgb(110, 80, 50), "short", rgb(100, 70, 45), "hood", rgb(70, 120, 60),
	rgb(70, 120, 60), rgb(120, 90, 60), rgb(60, 45, 35))
UnitData.Heroes.greta.chibi = chibi(S1, rgb(90, 100, 160), "bun", rgb(120, 130, 170), "wizard", rgb(40, 50, 100),
	rgb(40, 50, 100), rgb(235, 225, 200), rgb(200, 170, 90), true)
UnitData.Heroes.bruno.chibi = chibi(S3, rgb(70, 50, 40), "spiky", rgb(30, 25, 25), "bandana", rgb(170, 40, 40),
	rgb(120, 85, 55), rgb(170, 40, 40), rgb(60, 45, 35))
UnitData.Heroes.kai.chibi = chibi(S1, rgb(80, 100, 140), "short", rgb(70, 50, 35), "helmet", METAL,
	rgb(60, 90, 150), rgb(150, 155, 165), rgb(200, 200, 210))
UnitData.Heroes.finn.chibi = chibi(S1, rgb(80, 130, 70), "spiky", rgb(190, 80, 40), "bandana", rgb(70, 130, 70),
	rgb(200, 180, 140), rgb(70, 130, 70), rgb(110, 80, 55))
UnitData.Heroes.ida.chibi = chibi(S2, rgb(110, 80, 50), "ponytail", rgb(235, 205, 120), "headband", rgb(80, 130, 70),
	rgb(130, 100, 70), rgb(80, 130, 70), rgb(70, 50, 35))

for class, heroId in { Lord = "leon", Cavalier = "kai", Archer = "tobi", Mage = "greta", Fighter = "finn" } do
	UnitData.Classes[class].chibi = UnitData.Heroes[heroId].chibi
end
UnitData.Classes.Brigand.chibi = chibi(S2, rgb(70, 50, 40), "short", rgb(30, 25, 25), "bandana", rgb(110, 25, 30),
	rgb(110, 25, 30), rgb(90, 70, 50), rgb(50, 40, 30))
UnitData.Classes.Soldier.chibi = chibi(S1, rgb(80, 100, 140), "short", rgb(90, 60, 40), "kettle", METAL,
	rgb(150, 155, 165), rgb(120, 30, 35), rgb(80, 80, 90))
UnitData.Classes.EnemyArcher.chibi = chibi(S2, rgb(110, 80, 50), "short", rgb(90, 60, 40), "hood", rgb(110, 25, 30),
	rgb(110, 25, 30), rgb(90, 70, 50), rgb(50, 40, 30))
UnitData.Classes.Chieftain.chibi = chibi(S3, rgb(70, 50, 40), "none", rgb(30, 25, 25), "horned", METAL,
	rgb(40, 35, 35), rgb(130, 25, 30), rgb(170, 140, 80), false, true, 1.2)
UnitData.Classes.EnemyMage.chibi = chibi(S2, rgb(150, 60, 160), "long", rgb(60, 40, 70), "wizard", rgb(50, 80, 50),
	rgb(50, 80, 50), rgb(40, 35, 45), rgb(150, 120, 60), true)

UnitData.Heroes.leon.hairAccessory = 12819292
UnitData.Heroes.mira.hairAccessory = 1513252656
UnitData.Heroes.selina.hairAccessory = 376527350
UnitData.Heroes.aurelia.hairAccessory = 398673196
UnitData.Heroes.ida.hairAccessory = 398673196
UnitData.Heroes.greta.hairAccessory = 1708329071

-- Startaufstellung neuer Profile; weitere Helden über Rekrutierung
UnitData.STARTER_HEROES = { "leon", "starter_mage", "starter_knight" }

-- Gegnertypen. ai: "aggressive" (rückt vor) oder "stationary" (greift nur in Reichweite an)
UnitData.Enemies = {
	witch = { name = "Sumpfhexe", class = "EnemyMage", weapon = "Fire",
		stats = { hp = 16, str = 0, mag = 5, skl = 5, spd = 5, lck = 2, def = 1, res = 5 } },
	morwen = { name = "Morwen", class = "EnemyMage", weapon = "Fire", rarity = 4, ai = "stationary",
		stats = { hp = 26, str = 0, mag = 8, skl = 7, spd = 6, lck = 4, def = 3, res = 7 } },
	brigand = { name = "Bandit", class = "Brigand", weapon = "IronAxe",
		stats = { hp = 18, str = 5, mag = 0, skl = 2, spd = 3, lck = 0, def = 2, res = 0 } },
	soldier = { name = "Soldat", class = "Soldier", weapon = "IronLance",
		stats = { hp = 17, str = 5, mag = 0, skl = 3, spd = 3, lck = 1, def = 4, res = 1 } },
	javelin = { name = "Speerträger", class = "Soldier", weapon = "Javelin",
		stats = { hp = 18, str = 5, mag = 0, skl = 3, spd = 3, lck = 1, def = 4, res = 1 } },
	archer = { name = "Schütze", class = "EnemyArcher", weapon = "IronBow",
		stats = { hp = 16, str = 4, mag = 0, skl = 4, spd = 4, lck = 1, def = 2, res = 1 } },
	chieftain = { name = "Garrick", class = "Chieftain", weapon = "SteelAxe", rarity = 4, ai = "stationary",
		stats = { hp = 28, str = 8, mag = 0, skl = 5, spd = 5, lck = 2, def = 7, res = 3 } },
}

return UnitData
