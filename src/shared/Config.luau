-- Globale Einstellungen: Karte, Gelände, Farben, Timings
local Config = {}

Config.CHARACTER_STYLE = "chibi" -- "chibi" oder "avatar"

Config.CHIBI = {
	legSize = Vector3.new(0.7, 1.0, 0.7), hipY = 1.0, legX = 0.45, bootHeight = 0.35,
	torsoSize = Vector3.new(1.7, 1.5, 1.1), torsoY = 1.75,
	armSize = Vector3.new(0.55, 1.1, 0.55), shoulderX = 1.15, shoulderY = 2.35,
	handDiameter = 0.6, headDiameter = 2.6, headY = 3.7, neckY = 2.5,
	eyeSize = Vector3.new(0.38, 0.6, 0.1), eyeX = 0.48, eyeY = 3.6,
	riderLift = 2.6, riderHipAngle = -35,
}

Config.FEEL = {
	avatarIdle = "rbxassetid://507766388", avatarWalk = "rbxassetid://507777826",
	avatarAnimationFade = 0.15, riderLift = 3.2, capeAngle = 8,
	boardUnitScale = 1.35,
	terrainDepth = 12, terrainClearTop = 20, terrainSurfaceMargin = 0.15, gridLineWidth = 0.06, gridTransparency = 0.75,
	hallBrightness = 1.2, hallExposure = -0.35, candleBrightness = 1.2,
	hallWhite = Color3.fromRGB(225, 218, 205), hallMarble = Color3.fromRGB(205, 198, 186),
	hoverSoundCooldown = 0.08,
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
	touchRotateThreshold = 18, touchPanScale = 1,
	mudColor = Color3.fromRGB(70, 58, 38),
	swampPuddleSize = Vector3.new(3, 0.6, 3), swampPuddleSurfaceOffset = 0.08,
	costOverlayTransparency = 0.65, blockedOverlayTransparency = 0.55,
	shakeStrength = 0.28, critShakeStrength = 0.7, shakeDuration = 0.18, critShakeDuration = 0.38,
	hitStop = 0.06, critFlashTransparency = 0.65, critFlashDuration = 0.2,
	volume = 1, pitchVariation = 0.05, musicFade = 1, soundLifetime = 30,
	atmosphereFade = 0.8, flickerStrength = 0.12, flickerRate = 7,
	hallDustRate = 12, hallDustLifetime = 14, hallDustSpeed = 0.3,
	environmentMargin = 100, environmentCount = 16,
	atmosphere = {
		hall = {
			bloom = { Intensity = 0.18, Size = 28, Threshold = 1.4 },
			color = { TintColor = Color3.fromRGB(255, 235, 211), Saturation = 0.12, Contrast = 0.12, Brightness = -0.02 },
			rays = { Intensity = 0.035, Spread = 0.6 },
			haze = { Density = 0.18, Offset = 0.1, Color = Color3.fromRGB(240, 220, 195), Decay = Color3.fromRGB(175, 151, 124), Haze = 0.7, Glare = 0.1 },
			depth = { FarIntensity = 0.08, NearIntensity = 0, FocusDistance = 45, InFocusRadius = 38 },
			lighting = { Brightness = 1.2, ExposureCompensation = -0.35 },
		},
		battle = {
			bloom = { Intensity = 0.12, Size = 20, Threshold = 1.5 },
			color = { TintColor = Color3.fromRGB(245, 250, 255), Saturation = 0.18, Contrast = 0.1, Brightness = 0 },
			rays = { Intensity = 0.02, Spread = 0.8 },
			haze = { Density = 0.22, Offset = 0.15, Color = Color3.fromRGB(210, 230, 245), Decay = Color3.fromRGB(145, 165, 180), Haze = 0.8, Glare = 0 },
			depth = { FarIntensity = 0, NearIntensity = 0, FocusDistance = 75, InFocusRadius = 100 },
			lighting = { Brightness = 2.2, ExposureCompensation = 0.1 },
		},
		swamp = {
			bloom = { Intensity = 0.12, Size = 20, Threshold = 1.5 },
			color = { TintColor = Color3.fromRGB(225, 240, 220), Saturation = 0.05, Contrast = 0.1, Brightness = 0 },
			rays = { Intensity = 0.02, Spread = 0.8 },
			haze = { Density = 0.38, Offset = 0.15, Color = Color3.fromRGB(170, 195, 160), Decay = Color3.fromRGB(110, 130, 100), Haze = 1.2, Glare = 0 },
			depth = { FarIntensity = 0, NearIntensity = 0, FocusDistance = 75, InFocusRadius = 100 },
			lighting = { Brightness = 1.8, ExposureCompensation = 0 },
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
		height = 0, terrainMaterial = Enum.Material.Grass,
		name = "Ebene", avoid = 0, def = 0,
		cost = { foot = 1, horse = 1 },
		color = Color3.fromRGB(126, 184, 92), material = Enum.Material.Grass,
	},
	F = {
		height = 0.4, terrainMaterial = Enum.Material.LeafyGrass,
		name = "Wald", avoid = 20, def = 1,
		cost = { foot = 2, horse = 3 },
		color = Color3.fromRGB(72, 132, 62), material = Enum.Material.Grass,
	},
	M = {
		height = 4, terrainMaterial = Enum.Material.Rock,
		name = "Berg", avoid = 30, def = 2,
		cost = { foot = 4 },
		color = Color3.fromRGB(140, 122, 98), material = Enum.Material.Rock,
	},
	W = {
		height = -1.2, terrainMaterial = Enum.Material.Water,
		name = "Wasser", avoid = 0, def = 0,
		cost = {},
		color = Color3.fromRGB(60, 120, 200), material = Enum.Material.SmoothPlastic,
	},
	S = {
		height = -0.2, terrainMaterial = Enum.Material.Mud,
		name = "Morast", avoid = -15, def = 0,
		cost = { foot = 2, horse = 3 },
		color = Color3.fromRGB(95, 85, 60), material = Enum.Material.Mud,
	},
	D = {
		height = -0.8, terrainMaterial = Enum.Material.Mud,
		name = "Tiefer Morast", avoid = 0, def = 0,
		cost = {}, -- Später fly = 1 für Flieger.
		color = Color3.fromRGB(60, 55, 40), material = Enum.Material.Mud,
	},
	H = {
		height = 1, terrainMaterial = Enum.Material.Cobblestone,
		name = "Festung", avoid = 20, def = 3, heal = 0.2,
		cost = { foot = 2, horse = 2 },
		color = Color3.fromRGB(170, 160, 150), material = Enum.Material.Cobblestone,
	},
	B = {
		height = 0.2, terrainMaterial = Enum.Material.WoodPlanks,
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
	Blocked = Color3.fromRGB(115, 120, 130),
	Attack = Color3.fromRGB(255, 70, 70),
	EnemyMove = Color3.fromRGB(200, 90, 230),
	Danger = Color3.fromRGB(255, 40, 40),
	Cursor = Color3.fromRGB(255, 220, 80),
}

return Config
