-- Globale Einstellungen: Karte, Gelände, Farben, Timings
local Config = {}

Config.CHARACTER_STYLE = "mesh" -- "chibi", "avatar" oder "mesh"; auf "mesh" umstellen, sobald R15-Modelle vorliegen.

Config.CHIBI = {
	legSize = Vector3.new(0.7, 1.0, 0.7), hipY = 1.0, legX = 0.45, bootHeight = 0.35,
	torsoSize = Vector3.new(1.7, 1.5, 1.1), torsoY = 1.75,
	armSize = Vector3.new(0.55, 1.1, 0.55), shoulderX = 1.15, shoulderY = 2.35,
	handDiameter = 0.6, headDiameter = 2.6, headY = 3.7, neckY = 2.5,
	eyeSize = Vector3.new(0.38, 0.6, 0.1), eyeX = 0.48, eyeY = 3.6,
	riderLift = 2.6, riderHipAngle = -35,
}

Config.FEEL = {
	battleSceneIntro = 0.45, battleSceneOutro = 0.5,
	battleSceneHpTime = 0.25, battleSceneTextTime = 0.4, battleSceneDeathDelay = 0.1,
	avatarIdle = "rbxassetid://507766388", avatarWalk = "rbxassetid://507777826",
	avatarAnimationFade = 0.15, riderLift = 3.2, capeAngle = 8,
	meshArmDrop = 75, -- Grad: T-Pose-Arme importierter Figuren in Ruhepose absenken
	meshTargetHeight = 5.5, -- Studs: importierte 3D-Figuren werden auf diese Höhe skaliert
	touchEndGrace = 0.25, -- Sekunden, bevor ein Touch ohne InputEnded aufgeräumt wird
	boardUnitScale = 1.35, turnRingRadius = 2.3, turnRingWidth = 0.3, turnRingTransparency = 0.2, turnRingPulse = 0.45, turnRingPulseRate = 3, -- Zug-Ring (blau/rot)
	terrainDepth = 12, terrainClearTop = 20, terrainSurfaceMargin = 0.15, gridLineWidth = 0.045, gridTransparency = 0.5,
	gridSurfaceOffset = 0.005, gridShade = 0.3, groundCapHeight = 0.12, groundDepth = 4, groundSideShade = 0.22,
	surroundHeight = -0.4, waterTransparency = 0.18,
	hallBrightness = 1.2, hallExposure = -0.35, candleBrightness = 1.2,
	hallWhite = Color3.fromRGB(225, 218, 205), hallMarble = Color3.fromRGB(205, 198, 186),
	hoverSoundCooldown = 0.08,
	buttonPressScale = 0.94, buttonHoverScale = 1.04, buttonPressTime = 0.08, buttonReleaseTime = 0.2,
	menuOpenTime = 0.22, menuCloseTime = 0.16, menuOpenScale = 0.9, menuCloseScale = 0.94, menuSlide = 18,
	loadingFade = 0.25, loadingTimeout = 15,
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
	swampPuddleSize = Vector3.new(3, 0.6, 3), swampPuddleSurfaceOffset = 0.005,
	grassColor = Color3.fromRGB(106, 127, 63), waterColor = Color3.fromRGB(12, 84, 91), -- Roblox-Standard, je Gebiet überschreibbar
	shakeStrength = 0.28, critShakeStrength = 0.7, shakeDuration = 0.18, critShakeDuration = 0.38,
	hitStop = 0.06, critFlashTransparency = 0.65, critFlashDuration = 0.2,
	volume = 1, pitchVariation = 0.05, musicFade = 1, soundLifetime = 30,
	atmosphereFade = 0.8, flickerStrength = 0.12, flickerRate = 7,
	hallDustRate = 12, hallDustLifetime = 14, hallDustSpeed = 0.3,
	-- Zoom 140, Blickwinkel 70°, bis 21:9 und Boden bis -terrainDepth: 609,32 Studs, auf Voxelbreite gerundet.
	environmentMargin = 72, environmentCount = 16, -- klein halten: Rand besteht aus vier Parts; Ferne verdeckt der Dunst
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

-- Werte WIP: Bild-ID leer/nil = prozedurale Flecken; Seitenbilder sind unabhängig.
Config.GROUND_TEXTURES = {
	["."] = { top = nil, side = nil, studsPerTile = 8, transparency = 0.65 },
	F = { top = nil, side = nil, studsPerTile = 8, transparency = 0.65 },
	M = { top = nil, side = nil, studsPerTile = 8, transparency = 0.65 },
	W = { top = nil, side = nil, studsPerTile = 8, transparency = 0.7 },
	S = { top = nil, side = nil, studsPerTile = 8, transparency = 0.65 },
	D = { top = nil, side = nil, studsPerTile = 8, transparency = 0.7 },
	H = { top = nil, side = nil, studsPerTile = 8, transparency = 0.65 },
	B = { top = nil, side = nil, studsPerTile = 8, transparency = 0.65 },
}
Config.GROUND_FLECKS = {
	maxPartsPerTile = 3, patchCount = 2, detailChance = 0.35,
	thickness = 0.003, surfaceOffset = 0.001, transparency = 0.35,
	shade = 0.12, light = 0.06, centerClearance = 2.3, edgeInset = 0.25,
	minSize = 0.55, maxSize = 1, detailWidth = 0.12, detailLength = 0.65,
}

-- Maximalmaße in Feldern; auf dem Brett bleibt die Figurenmitte frei.
Config.ENVIRONMENT = {
	sizeVariation = 0.1, shadowHeight = 0.6,
	decoChance = 0.08, bushChance = 0.25, edgeInset = 1.3,
	terrainCategories = { F = "tree", M = "rock", H = "fortress", B = "bridge" },
	decoCategories = { "deco_flower", "deco_stone", "deco_grass", "deco_fence" },
	categories = {
		tree = { height = 0.55, width = 0.22, rotation = "free" },
		bush = { height = 0.16, width = 0.2, rotation = "free" },
		rock = { height = 0.28, width = 0.22, rotation = "quarter" },
		fortress = { height = 0.38, width = 0.2, rotation = "quarter" },
		bridge = { height = 0.16, width = 1, rotation = "none" },
		ruins = { height = 0.38, width = 0.2, rotation = "quarter" },
		deco_flower = { height = 0.08, width = 0.14, rotation = "free" },
		deco_stone = { height = 0.08, width = 0.14, rotation = "free" },
		deco_grass = { height = 0.12, width = 0.14, rotation = "free" },
		deco_fence = { height = 0.12, width = 0.24, rotation = "quarter" },
	},
	outer = {
		tree = { height = 2.25, width = 1.4 },
		rock = { height = 0.75, width = 0.9 },
		bush = { height = 0.45, width = 0.7 },
	},
}
Config.TILE_THICKNESS = 1
Config.MOVE_STEP_TIME = 0.16
Config.STRIKE_TIME = 0.85 -- Dauer eines Schlags inkl. Animation
Config.IMPACT_TIME = 0.4 -- Zeitpunkt des Treffers innerhalb eines Schlags
Config.MAX_LEVEL = 20

-- Karten liegen in Stages.luau. Zeichen: .  Ebene  F Wald  M Berg  W Wasser  H Festung  B Brücke
-- cost: Bewegungskosten je Bewegungstyp (fehlt = unpassierbar)
-- avoid: Ausweich-Bonus, def: Verteidigungs-Bonus, heal: Heilung pro Runde (Anteil der Max-KP)
-- Werte WIP: Bodenfarben in HSV um etwa 30 % entsättigt und 25 % abgedunkelt.
Config.TERRAIN = {
	["."] = {
		height = 0, terrainMaterial = Enum.Material.Grass,
		name = "Ebene", avoid = 0, def = 0,
		cost = { foot = 1, horse = 1 },
		color = Color3.fromRGB(108, 138, 90), material = Enum.Material.SmoothPlastic,
	},
	F = {
		height = 0.4, terrainMaterial = Enum.Material.LeafyGrass,
		name = "Wald", avoid = 20, def = 1,
		cost = { foot = 2, horse = 3 },
		color = Color3.fromRGB(68, 99, 62), material = Enum.Material.SmoothPlastic,
	},
	M = {
		height = 4, terrainMaterial = Enum.Material.Rock,
		name = "Berg", avoid = 30, def = 2,
		cost = { foot = 4 },
		color = Color3.fromRGB(105, 96, 83), material = Enum.Material.SmoothPlastic,
	},
	W = {
		height = -1.2, terrainMaterial = Enum.Material.Water,
		name = "Wasser", avoid = 0, def = 0,
		cost = {},
		color = Color3.fromRGB(77, 108, 150), material = Enum.Material.SmoothPlastic,
	},
	S = {
		height = -0.2, terrainMaterial = Enum.Material.Mud,
		name = "Morast", avoid = -15, def = 0,
		cost = { foot = 2, horse = 3 },
		color = Color3.fromRGB(71, 66, 53), material = Enum.Material.SmoothPlastic,
	},
	D = {
		height = -0.8, terrainMaterial = Enum.Material.Mud,
		name = "Tiefer Morast", avoid = 0, def = 0,
		cost = {}, -- Später fly = 1 für Flieger.
		color = Color3.fromRGB(54, 75, 83), material = Enum.Material.SmoothPlastic,
	},
	H = {
		height = 1, terrainMaterial = Enum.Material.Cobblestone,
		name = "Festung", avoid = 20, def = 3, heal = 0.2,
		cost = { foot = 2, horse = 2 },
		color = Color3.fromRGB(128, 122, 117), material = Enum.Material.SmoothPlastic,
	},
	B = {
		height = 0.2, terrainMaterial = Enum.Material.WoodPlanks,
		name = "Brücke", avoid = 0, def = 0,
		cost = { foot = 1, horse = 1 },
		color = Color3.fromRGB(113, 92, 71), material = Enum.Material.SmoothPlastic,
	},
}

Config.TEAM_COLORS = {
	Player = Color3.fromRGB(70, 130, 240),
	Enemy = Color3.fromRGB(220, 60, 60),
	Royal = Color3.fromRGB(165, 28, 40), -- Figuren im Thronsaal (Farbpalette weiß/rot/gold)
}

-- Thronsaal: liegt weit hinter dem Schlachtfeld, damit die Taktik-Kamera ihn nicht sieht
Config.HUB_ORIGIN = Vector3.new(0, 0, 420)

Config.OVERLAY = {
	Move = Color3.fromRGB(60, 140, 255),
	Attack = Color3.fromRGB(255, 70, 70),
	EnemyMove = Color3.fromRGB(200, 90, 230),
	Danger = Color3.fromRGB(255, 40, 40),
	Cursor = Color3.fromRGB(255, 220, 80),
}

return Config
