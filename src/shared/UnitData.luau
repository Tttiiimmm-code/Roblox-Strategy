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
	Javelin = { name = "Wurfspeer", type = "Lance", might = 6, hit = 65, crit = 0, minRange = 1, maxRange = 2 },
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
	Chieftain = { name = "Bandenführer", mov = 5, moveType = "foot", growths = {} },
}

-- Offizielle Roblox-Accessoires aus PLAN.md; nur Aussehen, keine Spielwerte.
UnitData.Classes.Lord.look = { hat = 3756500192 }
UnitData.Classes.Cavalier.look = { hat = 98450287 }
UnitData.Classes.Soldier.look = { hat = 8796225 }
UnitData.Classes.Archer.look = { hat = 102623080 }
UnitData.Classes.EnemyArcher.look = { hat = 102623080 }
UnitData.Classes.Mage.look = { hat = 13121508 }
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

UnitData.Heroes.leon.hairAccessory = 12819292
UnitData.Heroes.mira.hairAccessory = 1513252656
UnitData.Heroes.selina.hairAccessory = 376527350
UnitData.Heroes.aurelia.hairAccessory = 398673196
UnitData.Heroes.ida.hairAccessory = 398673196
UnitData.Heroes.greta.hairAccessory = 1708329071

-- Startaufstellung neuer Profile; weitere Helden über Story (Stages.unlockHero) und Rekrutierung
UnitData.STARTER_HEROES = { "leon", "bruno", "tobi" }

-- Gegnertypen. ai: "aggressive" (rückt vor) oder "stationary" (greift nur in Reichweite an)
UnitData.Enemies = {
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
