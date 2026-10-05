-- Globale Einstellungen: Karte, Gelände, Farben, Timings
local Config = {}

Config.FEEL = {
	volume = 1, pitchVariation = 0.05, musicFade = 1, soundLifetime = 30,
}

Config.TILE_SIZE = 8
Config.TILE_THICKNESS = 1
Config.MOVE_STEP_TIME = 0.16
Config.STRIKE_TIME = 0.85 -- Dauer eines Schlags inkl. Animation
Config.IMPACT_TIME = 0.4 -- Zeitpunkt des Treffers innerhalb eines Schlags
Config.MAX_LEVEL = 20

-- Karten liegen in Stages.luau. Zeichen: .  Ebene  F Wald  M Berg  W Wasser  H Festung  B Brücke
-- cost: Bewegungskosten je Bewegungstyp (fehlt = unpassierbar)
-- avoid: Ausweich-Bonus, def: Verteidigungs-Bonus, heal: Heilung pro Runde (Anteil der Max-KP)
Config.TERRAIN = {
	["."] = {
		name = "Ebene", avoid = 0, def = 0,
		cost = { foot = 1, horse = 1 },
		color = Color3.fromRGB(126, 184, 92), material = Enum.Material.Grass,
	},
	F = {
		name = "Wald", avoid = 20, def = 1,
		cost = { foot = 2, horse = 3 },
		color = Color3.fromRGB(72, 132, 62), material = Enum.Material.Grass,
	},
	M = {
		name = "Berg", avoid = 30, def = 2,
		cost = { foot = 4 },
		color = Color3.fromRGB(140, 122, 98), material = Enum.Material.Rock,
	},
	W = {
		name = "Wasser", avoid = 0, def = 0,
		cost = {},
		color = Color3.fromRGB(60, 120, 200), material = Enum.Material.SmoothPlastic,
	},
	H = {
		name = "Festung", avoid = 20, def = 3, heal = 0.2,
		cost = { foot = 2, horse = 2 },
		color = Color3.fromRGB(170, 160, 150), material = Enum.Material.Cobblestone,
	},
	B = {
		name = "Brücke", avoid = 0, def = 0,
		cost = { foot = 1, horse = 1 },
		color = Color3.fromRGB(150, 110, 70), material = Enum.Material.WoodPlanks,
	},
}

Config.TEAM_COLORS = {
	Player = Color3.fromRGB(70, 130, 240),
	Enemy = Color3.fromRGB(220, 60, 60),
	Royal = Color3.fromRGB(165, 28, 40), -- Figuren im Thronsaal (Farbpalette weiß/rot/gold)
}

-- Thronsaal: liegt weit hinter dem Schlachtfeld, damit die Taktik-Kamera ihn nicht sieht
Config.HUB_ORIGIN = Vector3.new(0, 0, 420)
Config.DONE_COLOR = Color3.fromRGB(110, 110, 120)

Config.OVERLAY = {
	Move = Color3.fromRGB(60, 140, 255),
	Attack = Color3.fromRGB(255, 70, 70),
	EnemyMove = Color3.fromRGB(200, 90, 230),
	Danger = Color3.fromRGB(255, 40, 40),
	Cursor = Color3.fromRGB(255, 220, 80),
}

return Config
