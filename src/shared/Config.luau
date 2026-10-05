-- Globale Einstellungen: Karte, Gelände, Farben, Timings
local Config = {}

Config.FEEL = {
	buttonPressScale = 0.94, buttonHoverScale = 1.04, buttonPressTime = 0.08, buttonReleaseTime = 0.2,
	menuOpenTime = 0.22, menuCloseTime = 0.16, menuOpenScale = 0.9, menuCloseScale = 0.94, menuSlide = 18,
	tabFadeTime = 0.12, countUpTime = 0.6, hapticHit = 0.25, hapticCrit = 0.6, hapticDuration = 0.07,
	faceTexture = "rbxasset://textures/face.png",
	moveEaseFraction = 0.12, turnSmoothness = 14,
	stepDustInterval = 0.25, stepDustCount = 4, stepDustLifetime = 0.45, stepDustSize = 0.6, stepDustSpeed = 1.4,
	idleGestureMin = 6, idleGestureMax = 12, idleGestureDuration = 1.3, idleGestureAngle = 0.3,
	breathHeight = 0.09, breathRate = 2, capeMovingAngle = 0.25, capeIdleAngle = 0.04, capeSmoothness = 8,
	selectionJumpHeight = 0.5, selectionJumpDuration = 0.3, selectionRingRadius = 2.6, selectionRingSegments = 24,
	selectionRingTransparency = 0.2, overlayFade = 0.18, overlayPulseDuration = 0.8, overlayPulseAmount = 0.12,
	battleZoom = 42, cameraFocusTime = 0.22, cameraRestoreTime = 0.3,
	shakeStrength = 0.28, critShakeStrength = 0.7, shakeDuration = 0.18, critShakeDuration = 0.38,
	hitStop = 0.06, critFlashTransparency = 0.65, critFlashDuration = 0.2,
	volume = 1, pitchVariation = 0.05, musicFade = 1, soundLifetime = 30,
	atmosphereFade = 0.8, flickerStrength = 0.12, flickerRate = 7,
	hallDustRate = 12, hallDustLifetime = 14, hallDustSpeed = 0.3,
	environmentMargin = 100, environmentCount = 16,
	atmosphere = {
		hall = {
			bloom = { Intensity = 0.35, Size = 28, Threshold = 1.1 },
			color = { TintColor = Color3.fromRGB(255, 235, 211), Saturation = 0.12, Contrast = 0.05, Brightness = 0.02 },
			rays = { Intensity = 0.035, Spread = 0.6 },
			haze = { Density = 0.18, Offset = 0.1, Color = Color3.fromRGB(240, 220, 195), Decay = Color3.fromRGB(175, 151, 124), Haze = 0.7, Glare = 0.1 },
			depth = { FarIntensity = 0.08, NearIntensity = 0, FocusDistance = 45, InFocusRadius = 38 },
		},
		battle = {
			bloom = { Intensity = 0.12, Size = 20, Threshold = 1.5 },
			color = { TintColor = Color3.fromRGB(245, 250, 255), Saturation = 0.18, Contrast = 0.1, Brightness = 0 },
			rays = { Intensity = 0.02, Spread = 0.8 },
			haze = { Density = 0.22, Offset = 0.15, Color = Color3.fromRGB(210, 230, 245), Decay = Color3.fromRGB(145, 165, 180), Haze = 0.8, Glare = 0 },
			depth = { FarIntensity = 0, NearIntensity = 0, FocusDistance = 75, InFocusRadius = 100 },
		},
	},
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
