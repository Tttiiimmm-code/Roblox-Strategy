-- Globale Einstellungen: Karte, Gelände, Farben, Timings
local Config = {}

Config.ICONS = { gold = "💰", gems = "💎" }

Config.INPUT_DIAGNOSTICS = false -- Vorübergehend für Handy-/Mausfehler einschalten; Ausgabe im Client-Output.

Config.CHARACTER_STYLE = "mesh" -- "chibi", "avatar" oder "mesh"; auf "mesh" umstellen, sobald R15-Modelle vorliegen.

Config.CHIBI = {
	legSize = Vector3.new(0.7, 1.0, 0.7), hipY = 1.0, legX = 0.45, bootHeight = 0.35,
	torsoSize = Vector3.new(1.7, 1.5, 1.1), torsoY = 1.75,
	armSize = Vector3.new(0.55, 1.1, 0.55), shoulderX = 1.15, shoulderY = 2.35,
	handDiameter = 0.6, headDiameter = 2.6, headY = 3.7, neckY = 2.5,
	eyeSize = Vector3.new(0.38, 0.6, 0.1), eyeX = 0.48, eyeY = 3.6,
	riderLift = 2.6, riderHipAngle = -35,
}

Config.CAMERA = { zoomMin = 30, zoomDefaultMin = 45, zoomDefaultMax = 120,
	zoomDefaultScale = 0.85, overviewPadding = 1.08, tilt = 0.75,
	fovMin = 60, fovMax = 75, aspectMin = 4 / 3, aspectMax = 21 / 9, focusHeightReserve = 12 }

-- Die Brettdiagonale als Umkreis passt bei jeder Drehung in beide Bildachsen.
function Config.overviewZoom(size, fov, aspect, includeIsland)
	local c = Config.CAMERA
	local vertical = math.rad(math.clamp(fov, c.fovMin, c.fovMax)) / 2
	local horizontal = math.atan(math.tan(vertical) * aspect)
	local rim = Config.ISLAND and Config.ISLAND.enabled and includeIsland ~= false and Config.ISLAND.rimTiles.max * Config.TILE_SIZE or 0
	local padding = rim > 0 and Config.ISLAND.overviewPadding or 1
	return math.max(c.zoomMin, math.sqrt((size.X + rim * 2) ^ 2 + (size.Z + rim * 2) ^ 2) / 2
		/ math.sin(math.min(vertical, horizontal)) * c.overviewPadding * padding)
end

-- Reichweite des fernsten unteren Sichtstrahls auf dem flachen Fernboden.
function Config.viewReach(distance, fov, aspect)
	local c = Config.CAMERA
	local up = 1 / math.sqrt(1 + c.tilt ^ 2)
	local back = c.tilt * up
	local tangent = math.tan(math.rad(fov) / 2)
	local time = (distance * up + c.focusHeightReserve - Config.LANDSCAPE.foundationTop) / (up - back * tangent)
	return math.sqrt((aspect * tangent * time) ^ 2 + (distance * back - (back + up * tangent) * time) ^ 2)
end

function Config.landscapeMargin(size)
	local c = Config.CAMERA
	local distance = Config.overviewZoom(size, c.fovMin, c.aspectMin, false)
	return Config.viewReach(distance, c.fovMax, c.aspectMax) + Config.LANDSCAPE.viewSafetyTiles * Config.TILE_SIZE
end

Config.FEEL = {
	battleSceneIntro = 0.45, battleSceneOutro = 0.5,
	battleSceneHpTime = 0.25, battleSceneTextTime = 0.4, battleSceneDeathDelay = 0.1,
	avatarIdle = "rbxassetid://507766388", avatarWalk = "rbxassetid://507777826",
	avatarAnimationFade = 0.15, riderLift = 3.2, capeAngle = 8,
	meshArmDrop = 75, -- Grad: T-Pose-Arme importierter Figuren in Ruhepose absenken
	meshTargetHeight = 5.5, -- Studs: importierte 3D-Figuren werden auf diese Höhe skaliert
	touchEndGrace = 0.25, -- Sekunden, bevor ein Touch ohne InputEnded aufgeräumt wird
	boardUnitScale = 1.35, turnRingRadius = 2.3, turnRingWidth = 0.3, turnRingTransparency = 0.2, turnRingPulse = 0.45, turnRingPulseRate = 3, -- Zug-Ring (blau/rot)
	-- WIP: drei weiche Schichten, über Raster/Flecken und unter Overlays/Zug-Ring.
	unitShadowWidth = 1.8, unitShadowHorseWidth = 1.15, unitShadowColor = Color3.fromRGB(15, 18, 24),
	unitShadowSurfaceOffset = 0.022, unitShadowThickness = 0.003, -- über den Bodenflecken (bis 0,015), Schichten mit Abstand gegen Flackern
	unitShadowLayers = { { size = 0.65, transparency = 0.70 }, { size = 0.82, transparency = 0.84 }, { size = 1, transparency = 0.93 } },
	terrainDepth = 12, terrainClearTop = 20, terrainSurfaceMargin = 0.15, gridLineWidth = 0.045, gridTransparency = 0.5,
	gridSurfaceOffset = 0.005, gridShade = 0.22, groundCapHeight = 0.12, groundDepth = 4, groundSideShade = 0.22,
	surroundHeight = -0.4, waterTransparency = 0.18,
	cliffSideShade = 0.42,
	shore = { enabled = true, width = 0.1, maxPartsPerTile = 4,
		thickness = 0.01, surfaceOffset = 0.018, color = Color3.fromRGB(104, 95, 75) }, -- WIP: gedämpfter Erdton
	waterfallsEnabled = true, waterfallWidth = 0.76, waterfallThickness = 0.18, waterfallSurfaceClearance = 0.05,
	waterfallFaceOffset = 0.35, waterfallChannelDepth = 4,
	waterfallColor = Color3.fromRGB(161, 207, 235), waterfallFoamColor = Color3.fromRGB(230, 242, 250),
	waterfallTransparency = 0.12, waterfallFoamCount = 3, waterfallFoamSize = 0.65,
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
	atmosphereFade = 0.8,
	rarityEffects = false, -- Nutzer 08.10.2026: Seltenheits-Leuchten/-Partikel (Waffe ★4, Bodenaura ★5) vorerst aus
	flickerStrength = 0.12, flickerRate = 7,
	hallDustRate = 12, hallDustLifetime = 14, hallDustSpeed = 0.3,
	environmentMargin = 72, -- Terrain-Freiraum; sichtbarer Boden separat bis zum Übersichtszoom.
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

Config.FOREST_OUTLINES = { -- WIP: Reserven für Tutorial/Auswahl/Kampfeffekte
	maxCount = 20, totalBudget = 31, reserved = 8, updateInterval = 0.1,
	fillTransparency = 0.8, outlineTransparency = 0,
	canopyNeighborRadius = 1, sightDistance = 2, -- WIP: Kronenüberhang und perspektivische Verdeckung
	colors = { Player = Color3.fromRGB(70, 155, 255), Enemy = Color3.fromRGB(255, 80, 70) },
}

Config.TREE_PALETTES = { -- WIP: Gewichte pro Region
	greenland = {
		{ weight = 65, color = Color3.fromRGB(74, 128, 64) }, { weight = 25, color = Color3.fromRGB(112, 157, 74) },
		{ weight = 7, color = Color3.fromRGB(192, 115, 49) }, { weight = 3, color = Color3.fromRGB(158, 70, 46) },
	},
	swamp = { { weight = 80, color = Color3.fromRGB(44, 78, 48) }, { weight = 20, color = Color3.fromRGB(69, 94, 50) } },
	ice = { { weight = 85, color = Color3.fromRGB(226, 235, 239) }, { weight = 15, color = Color3.fromRGB(169, 200, 208) } },
	volcano = { { weight = 85, color = Color3.fromRGB(54, 49, 43) }, { weight = 15, color = Color3.fromRGB(91, 61, 44) } },
}

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
	enabled = false, -- WIP: Roblox-Materialien liefern bereits Bodendetail.
	maxPartsPerTile = 3, patchCount = 2, detailChance = 0.35,
	thickness = 0.003, surfaceOffset = 0.012, transparency = 0, -- deckend und mit Abstand: kein Flackern, keine Transparenz-Kosten am Handy
	shade = 0.12, light = 0.06, centerClearance = 2.3, edgeInset = 0.25,
	minSize = 0.55, maxSize = 1, detailWidth = 0.12, detailLength = 0.65,
}

-- Maximalmaße in Feldern; auf dem Brett bleibt die Figurenmitte frei.
Config.ENVIRONMENT = {
	rootFoot = { widthScale = 1.1, sink = 0.12, centerTolerance = 0.05 }, -- WIP: relativ zur Wood-Stammbreite.
	sizeVariation = 0.1, castShadows = false, shadowHeight = 0.6, -- WIP: alte Höhenschwelle nur bei aktivierten Schatten
	decoChance = 0.08, bushChance = 0.25, edgeInset = 1.3,
	treesPerForestTile = { min = 1, max = 2 }, -- WIP: lichter Wald
	forest = {
		groundShade = 0.1, groundFleckContrast = 0.5, -- WIP: ruhige Tiefe ohne Baumschatten
		treeHeight = { min = 1.2, max = 1.5 }, treeWidth = { min = 1.1, max = 1.2 },
		bush = { height = 0.3, width = 0.45 }, deco_root = { height = 0.2, width = 0.5 },
		secondTreeChance = 0.35, singleTreeOffset = 0.22, understoryChance = 0.2, positionJitter = 0.1, -- WIP: Mengen für Handy-Budget
	},
	rocks = { -- WIP: große Felsen und kleine Begleiter
		centerClearance = 2.3, centerEdgeInset = 0.8, surfaceSink = 0.2,
		mountain = { height = 0.2, width = 0.175 }, largeScale = { min = 0.8, max = 1 },
		smallScale = { min = 0.5, max = 0.85 }, smallCount = { min = 0, max = 0 }, secondSmallChance = 0,
		cliff = { height = 0.2, width = 0.175 }, cliffCount = { min = 0, max = 1 },

	},
	estimatedTriangleBudget = 350000, -- WIP: C3 inklusive dichtem Rand; Ferne aus günstigen Parts
	bridge = { bankOverlap = 0.65, rayMargin = 2, footTolerance = 0.3,
		ownModel = "archbridge_2", ownWidth = 5.2, ownHeight = 4.8 }, -- WIP: nur Optik/Brückenprofil, Ufer bleiben erhalten.
	preferred = { deco_grass = "deco_grass_2", deco_flower = "deco_flower_4", deco_stone = "deco_stone_1", archbridge = "archbridge_1" },
	triangles = { rim_ruin_column_1 = 1500, rim_banner_1 = 998, rim_crystal_shrine_1 = 1500,
		rim_ruin_arch_1 = 2999, rim_lantern_1 = 998, rim_crystal_pedestal_1 = 999, archbridge_2 = 3000,
		deco_grass_2 = 299, deco_flower_4 = 798, rim_barrels_1 = 1000, deco_stone_1 = 300, rock_50 = 1499 },
	meadow = { chance = 0.5, grassCount = { min = 1, max = 2 }, flowerChance = 0.18, stoneChance = 0.16,
		fenceChance = 0.025, centerClearance = 2.3 }, -- WIP: mittlere Dichte, freie Figurenmitte
	terrainCategories = { F = "tree", M = "rock", H = "fortress", B = "bridge" },
	decoCategories = { "deco_flower", "deco_stone", "deco_grass", "deco_fence" },
	categories = {
		tree = { height = 0.55, width = 0.22, rotation = "free" },
		bush = { height = 0.16, width = 0.2, rotation = "free" },
		deco_root = { height = 0.2, width = 0.4, rotation = "free" },
		rock = { height = 0.28, width = 0.22, rotation = "quarter" },
		fortress = { height = 0.38, width = 0.2, rotation = "quarter" },
		bridge = { height = 0.16, width = 1, rotation = "none" },
		archbridge = { height = 1, width = 1, rotation = "none" },
		rim_ruin_column = { height = 1, width = 0.85, rotation = "quarter" },
		rim_banner = { height = 1.1, width = 0.7, rotation = "none" },
		rim_crystal_shrine = { height = 0.85, width = 0.8, rotation = "quarter" },
		rim_ruin_arch = { height = 1, width = 1.5, rotation = "none" },
		rim_lantern = { height = 0.8, width = 0.65, rotation = "quarter" },
		rim_crystal_pedestal = { height = 0.8, width = 0.8, rotation = "quarter" },
		rim_barrels = { height = 0.6, width = 0.7, rotation = "quarter" },
		ruins = { height = 0.38, width = 0.2, rotation = "quarter" },
		deco_flower = { height = 0.08, width = 0.14, rotation = "free" },
		deco_stone = { height = 0.08, width = 0.14, rotation = "free" },
		deco_grass = { height = 0.12, width = 0.14, rotation = "free" },
		deco_fence = { height = 0.12, width = 0.24, rotation = "quarter" },
	},
}
-- WIP: Distanzen in Feldern, Höhen/Skalen in Studs; Terrainauflösung von Roblox fest vorgegeben.
Config.WATER = { -- WIP: ruhiges Terrain-Wasser, Fortsetzung bis zur Senke.
	color = Color3.fromRGB(64, 105, 113), transparency = 0.35, reflectance = 0.12, waveSize = 0.08, waveSpeed = 3,
	extendRivers = true, extensionTiles = 10, extensionWidth = 0.65,
}

Config.ISLAND = { -- WIP: schwebende Thronlande, false erhält das bisherige Tal.
	enabled = true, rimTiles = { min = 3.4, max = 4 }, outlineSteps = 4,
	surfaceHeight = -1, edgeReserve = 4, earthTiles = 1, depthTiles = 4.5,
	rimBrighten = 0.3, -- WIP: Brett-Gras als Mindesthelligkeit, frischer heller Inselrand.
	cliffEarthTiles = 0.6, cliffStoneTiles = 1, -- WIP: senkrechtes Band vor der Verjüngung.
	layerScales = { 1, 0.46, 0 }, partBudget = 450, -- WIP: zwei Steinstufen sparen Teile für runde Wolken.
	facetThickness = 0.16, edgeLip = 0.2, edgeOverlap = 1,
	clusterCount = 10, clusterSize = 3, clusterSpread = 0.45, maxTrees = 18,
	tree = { height = 1.15, crownWidth = 1.35 }, rock = { height = 0.45, width = 0.65 }, bush = { height = 0.3, width = 0.5 },
	rimGroups = { { "rim_ruin_column", "rim_ruin_arch", "deco_stone" },
		{ "rim_barrels", "rim_lantern", "deco_grass" },
		{ "rim_crystal_shrine", "rim_crystal_pedestal", "deco_flower" }, { "rim_banner", "deco_grass" },
		{ "rim_banner", "deco_stone" } },
	rimScatter = { count = 36, categories = { "deco_grass", "deco_flower", "deco_stone", "rock" },
		height = 0.28, width = 0.45, rockHeight = 0.45, rockWidth = 0.65 },
	rimPlacement = { attempts = 16, distance = 2.2, groupSpacing = 1.35, jitter = 1.5,
		scatterDistance = { min = 1.5, inset = 0.5 }, edgeClearance = 2,
		waterClearance = 3, overlapClearance = 0.4, frontHeight = 2.6 },
	earthColor = Color3.fromRGB(154, 106, 72), stoneColor = Color3.fromRGB(109, 100, 128),
	crystalCount = { min = 2, max = 4 }, crystalWidth = 3, crystalHeight = 9, crystalDepth = 0.75,
	accents = { greenland = Color3.fromRGB(124, 194, 66), swamp = Color3.fromRGB(180, 107, 224),
		ice = Color3.fromRGB(111, 211, 255), volcano = Color3.fromRGB(255, 122, 26) },
	cloudHeight = -48, cloudThickness = 8, cloudReachTiles = 224, cloudTileSize = 1024, cloudCount = 16,
	cloudWidthTiles = { min = 8, max = 14 }, cloudHeightTiles = { min = 2, max = 3.2 },
	cloudRings = { 1, 1.8 }, cloudGapTiles = { min = 2, max = 4 }, cloudParts = { min = 3, max = 6 },
	cloudPuff = { spread = 0.25, topLift = 1, shadeLift = 0.72, topWidth = 0.9,
		shadeWidth = { min = 0.55, max = 0.85 }, edgeTint = 0.2 },
	cloudBallEstimatedTriangles = 240, -- WIP: grobe Kugelschätzung, tatsächliches LOD ist geräteabhängig.
	cloudColor = Color3.fromRGB(249, 248, 255), cloudBaseColor = Color3.fromRGB(194, 183, 224),
	cloudCyanColor = Color3.fromRGB(186, 221, 232), horizonColor = Color3.fromRGB(201, 168, 255),
	cloudLilacColor = Color3.fromRGB(222, 207, 239), -- WIP: sanfte Schatten trotz Nutzer-ColorGrading.
	battleDensity = 0.08, battleHaze = 0.15, -- WIP: Wolkenfarben aus der steilen Spielkamera erhalten.
	satelliteDepthScale = 1.4, satelliteTreeHeight = 7, satelliteTreeWidth = 5,
	satelliteOutlinePoints = 6, satelliteOutlineRadius = { min = 0.78, max = 1 }, satelliteEarthTiles = 0.35,
	satelliteWallThickness = 1.2, satelliteZSpread = 0.22, satelliteCloudRiseTiles = 2.2,
	satelliteCrystalOffset = Vector3.new(0.82, 0.15, -0.5), -- WIP: Kristall sichtbar an der Kappe.
	skyColor = Color3.fromRGB(157, 221, 230), foamColor = Color3.fromRGB(242, 251, 255),
	satelliteCount = { min = 2, max = 3 }, satelliteDistanceTiles = { min = 29, max = 31 },
	satelliteRadiusTiles = { min = 1.8, max = 2.6 }, satelliteHeight = { min = -23, max = -19 },
	overviewPadding = 1.06, panInset = 0.3,
}

Config.LANDSCAPE = {
	resolution = 4, chunkCells = 32, viewSafetyTiles = 2, sculptDistance = 18,
	rockFields = { mountainHeight = 8, mountainEdgeHeight = -2, edgeFalloff = 4, edgeDensity = 0.35, mountainRoughness = 1.5, roughnessScale = 7,
		cliffRoughness = 3, cliffScale = 5, grassChance = 0.16 }, -- WIP: natuerliche Felshoehen werden am Terrain gemessen.
	cliffWalls = { enabled = true, terrainInset = 8, ridgeDepth = 0.22, segments = 2 }, -- WIP: kantige Wände begrenzen den geglätteten Terrainkern.
	hubHalfWidth = 80, hubHalfDepth = 100, foundationTop = -4,
	rimWidth = 1.5, hillRise = 7, hillHeight = 28, valleyFloor = 0.2,
	mountainStart = 7, mountainRise = 10, mountainHeight = 76,
	broadScale = 47, detailScale = 29, edgeFade = 5,
	frontTransition = 4, frontMaxHeight = 4, rockHeight = 27, slateThreshold = 0.55, groundThreshold = 0.18,
	maxTrees = 32, clusterCount = 12, clusterSize = 4, clusterSpread = 2,
	clusterDistance = { min = 4, max = 15 }, objectClearance = 4, rootSink = 0.8,
	tree = { height = 1.8, crownWidth = 2 }, rock = { height = 0.8, width = 1.3, rotationMode = "free" },
	bush = { height = 0.4, width = 0.8 },
	palette = {
		grass = Enum.Material.Grass, ground = Enum.Material.Ground, rock = Enum.Material.Rock, slate = Enum.Material.Slate,
		colors = { [Enum.Material.Grass] = Color3.fromRGB(88, 115, 72), [Enum.Material.Ground] = Color3.fromRGB(96, 85, 64),
			[Enum.Material.Rock] = Color3.fromRGB(91, 96, 94), [Enum.Material.Slate] = Color3.fromRGB(71, 80, 85) },
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
-- Parts ben?tigen hellere Farben als Terrain mit demselben Material.
Config.GROUND_COLORS = { grassLighten = 0.4, groundLighten = 0.2 }

Config.TERRAIN = {
	["."] = {
		height = 0, terrainMaterial = Enum.Material.Grass,
		name = "Ebene", avoid = 0, def = 0,
		cost = { foot = 1, horse = 1 },
		color = Color3.fromRGB(108, 138, 90), material = Enum.Material.Grass, paletteKey = "grass",
	},
	F = {
		height = 0.4, terrainMaterial = Enum.Material.LeafyGrass,
		name = "Wald", avoid = 20, def = 1,
		cost = { foot = 2, horse = 3 },
		color = Color3.fromRGB(68, 99, 62), material = Enum.Material.Grass, paletteKey = "grass",
	},
	M = {
		height = 4, terrainMaterial = Enum.Material.Rock,
		name = "Berg", avoid = 30, def = 2,
		cost = { foot = 4 },
		color = Color3.fromRGB(105, 96, 83), material = Enum.Material.Rock, paletteKey = "rock",
	},
	C = {
		height = 8, terrainMaterial = Enum.Material.Rock,
		name = "Klippe", avoid = 0, def = 0,
		cost = {},
		color = Color3.fromRGB(99, 96, 91), material = Enum.Material.Slate, paletteKey = "slate",
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
		color = Color3.fromRGB(71, 66, 53), material = Enum.Material.Mud, paletteKey = "ground",
	},
	D = {
		height = -0.8, terrainMaterial = Enum.Material.Mud,
		name = "Tiefer Morast", avoid = 0, def = 0,
		cost = {}, -- Später fly = 1 für Flieger.
		color = Color3.fromRGB(54, 75, 83), material = Enum.Material.Mud, paletteKey = "ground",
	},
	H = {
		height = 1, terrainMaterial = Enum.Material.Cobblestone,
		name = "Festung", avoid = 20, def = 3, heal = 0.2,
		cost = { foot = 2, horse = 2 },
		color = Color3.fromRGB(128, 122, 117), material = Enum.Material.Cobblestone, paletteKey = "slate",
	},
	B = {
		height = 0.2, terrainMaterial = Enum.Material.WoodPlanks,
		name = "Brücke", avoid = 0, def = 0,
		cost = { foot = 1, horse = 1 },
		color = Color3.fromRGB(113, 92, 71), material = Enum.Material.WoodPlanks,
	},
}

Config.TEAM_COLORS = {
	Player = Color3.fromRGB(70, 130, 240),
	Enemy = Color3.fromRGB(220, 60, 60),
	Royal = Color3.fromRGB(165, 28, 40), -- Figuren im Thronsaal (Farbpalette weiß/rot/gold)
}

-- Thronsaal: liegt weit hinter dem Schlachtfeld, damit die Taktik-Kamera ihn nicht sieht
-- Größtes aktuelles Brett (Lauf: 16×12); Sichtreichweite plus Hub-Halbtiefe und Sicherheitsrand.
Config.HUB_BOARD_TILES = Vector3.new(16, 0, 12)
local hubBoardSize = Vector3.new(Config.HUB_BOARD_TILES.X * Config.TILE_SIZE, 0, Config.HUB_BOARD_TILES.Z * Config.TILE_SIZE)
Config.HUB_ORIGIN = Vector3.new(0, 0, math.ceil((hubBoardSize.Z + Config.landscapeMargin(hubBoardSize)
	+ Config.LANDSCAPE.hubHalfDepth + Config.LANDSCAPE.viewSafetyTiles * Config.TILE_SIZE) / Config.LANDSCAPE.resolution)
	* Config.LANDSCAPE.resolution)

Config.OVERLAY = {
	Move = Color3.fromRGB(60, 140, 255),
	Attack = Color3.fromRGB(255, 70, 70),
	EnemyMove = Color3.fromRGB(200, 90, 230),
	Danger = Color3.fromRGB(255, 40, 40),
	Cursor = Color3.fromRGB(255, 220, 80),
}

-- UI-Werte WIP: HUD-Spalten und das 640 Punkte hohe Kasernenfenster müssen Platz behalten.
Config.UI_SCALE = { desktopFactor = 1.25, desktopMinWidth = 1184, desktopMinHeight = 664 }

-- Tutorial-Werte WIP: feste Übungswerte verhindern, dass alte Profile die Führung überspringen.
Config.TUTORIAL = {
	hintTextSize = 31, hintMinHeight = 92, -- WIP: etwa 1,4-mal größer als bisher.
	targetColor = Color3.fromRGB(255, 225, 0), targetTransparency = 0.03, -- WIP
	gold = 150, alwaysHit = true, criticals = false, speed = 1, battleScenes = false,
	enemyStats = { hp = 10, str = 1, mag = 0, skl = 0, spd = 0, lck = 0, def = 0, res = 0 },
}

return Config
