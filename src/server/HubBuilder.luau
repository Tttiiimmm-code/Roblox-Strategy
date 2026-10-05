-- Thronsaal (Hub): weiß/rot/gold, Einrichtungen mit ProximityPrompts, Thron als Schnellmenü.
-- GRUNDGERÜST – Maße, Positionen und Deko sind Platzhalter und können frei umgebaut werden.
local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)
local Stages = require(Shared.Stages)
local CharacterBuilder = require(Shared.CharacterBuilder)

local HubBuilder = {}

local WHITE = Config.FEEL.hallWhite
local MARBLE = Config.FEEL.hallMarble
local RED = Color3.fromRGB(150, 22, 34)
local DARK_RED = Color3.fromRGB(105, 14, 24)
local GOLD = Color3.fromRGB(226, 182, 72)
local WOOD = Color3.fromRGB(96, 62, 38)
local METAL = Color3.fromRGB(190, 196, 206)
local ARCANE = Color3.fromRGB(170, 110, 255)

local origin = Config.HUB_ORIGIN
local hub

-- Lokale Koordinaten relativ zur Saalmitte (Thron im Norden = -Z, Eingang im Süden = +Z)
local function at(x, y, z)
	return CFrame.new(origin + Vector3.new(x, y, z))
end

local function part(name, size, cf, color, props)
	local p = Instance.new("Part")
	p.Name = name
	p.Anchored = true
	p.Size = size
	p.CFrame = cf
	p.Color = color
	p.Material = Enum.Material.SmoothPlastic
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	for k, v in props or {} do
		p[k] = v
	end
	p.Parent = props and props.Parent or hub
	return p
end

local function deco(name, size, cf, color, props)
	props = props or {}
	props.CanCollide = false
	props.CanQuery = false
	props.CanTouch = false
	return part(name, size, cf, color, props)
end

local function label(anchor, title, subtitle, height)
	-- Ein eigener aufrechter Anker vermeidet gedrehte Beschriftungen bei Zylindern.
	local upright = deco("LabelAnchor", Vector3.one, CFrame.new(anchor.Position), WHITE, { Transparency = 1 })
	local bb = Instance.new("BillboardGui")
	bb.Size = UDim2.fromOffset(240, 60)
	bb.StudsOffsetWorldSpace = Vector3.new(0, height or 6, 0)
	bb.MaxDistance = 70
	bb.LightInfluence = 0
	local t = Instance.new("TextLabel")
	t.Size = UDim2.new(1, 0, 0.6, 0)
	t.BackgroundTransparency = 1
	t.Font = Enum.Font.Fondamento
	t.TextScaled = true
	t.TextColor3 = GOLD
	t.TextStrokeTransparency = 0.3
	t.Text = title
	t.Parent = bb
	local s = t:Clone()
	s.Position = UDim2.fromScale(0, 0.6)
	s.Size = UDim2.new(1, 0, 0.4, 0)
	s.Font = Enum.Font.GothamBold
	s.TextColor3 = Color3.new(1, 1, 1)
	s.Text = subtitle
	s.Parent = bb
	bb.Parent = upright
end

local function prompt(anchor, station, action, object)
	local p = Instance.new("ProximityPrompt")
	p.ActionText = action
	p.ObjectText = object
	p.KeyboardKeyCode = Enum.KeyCode.E
	p.HoldDuration = 0
	p.MaxActivationDistance = 14
	p.RequiresLineOfSight = false
	p:SetAttribute("Station", station)
	p.Parent = anchor
end

-- Statische Figur aus dem Charakter-Baukasten (Hauptmann, Magier)
local function npc(class, weapon, rarity, x, z, yaw, hair)
	local ok, model = pcall(CharacterBuilder.build, {
		id = "NPC", team = "Royal", class = class, weapon = weapon, rarity = rarity,
	})
	if not ok then
		warn(("Saal-NPC %s wird weggelassen: %s"):format(class, tostring(model)))
		return nil
	end
	if hair then
		for _, name in { "Hair", "HairBack" } do
			local p = model:FindFirstChild(name)
			if p then
				p.Color = hair
			end
		end
	end
	model:PivotTo(at(x, (model:GetAttribute("GroundOffset") or 0) + 0.1, z) * CFrame.Angles(0, yaw, 0))
	model.Parent = hub
	return model
end

-- Raum -----------------------------------------------------------------------------------
local function buildRoom()
	part("Floor", Vector3.new(100, 2, 150), at(0, -1, 0), MARBLE, { Material = Enum.Material.Marble })
	-- roter Teppich mit Goldkanten vom Eingang bis zum Thron
	deco("Carpet", Vector3.new(12, 0.2, 128), at(0, 0.1, 6), RED, { Material = Enum.Material.Fabric })
	for _, x in { -6.4, 6.4 } do
		deco("CarpetTrim", Vector3.new(0.8, 0.25, 128), at(x, 0.12, 6), GOLD, { Material = Enum.Material.Metal })
	end

	-- Wände, Eingang im Süden
	local H = 44
	part("WallN", Vector3.new(100, H, 2), at(0, H / 2, -76), WHITE, { Material = Enum.Material.Marble })
	part("WallE", Vector3.new(2, H, 150), at(51, H / 2, 0), WHITE, { Material = Enum.Material.Marble })
	part("WallW", Vector3.new(2, H, 150), at(-51, H / 2, 0), WHITE, { Material = Enum.Material.Marble })
	for _, x in { -30, 30 } do
		part("WallS", Vector3.new(40, H, 2), at(x, H / 2, 76), WHITE, { Material = Enum.Material.Marble })
	end
	part("Lintel", Vector3.new(20, 16, 2), at(0, H - 8, 76), WHITE, { Material = Enum.Material.Marble })
	for _, x in { -5, 5 } do
		part("Door", Vector3.new(10, 28, 1), at(x, 14, 76.5), DARK_RED, { Material = Enum.Material.Wood })
		deco("DoorTrim", Vector3.new(10.4, 1, 1.2), at(x, 20, 76.4), GOLD, { Material = Enum.Material.Metal })
	end
	part("Ceiling", Vector3.new(104, 2, 154), at(0, H + 1, 0), WHITE)

	-- Goldene Sockel- und Deckenleisten
	for _, y in { 0.75, H - 0.75 } do
		deco("TrimN", Vector3.new(100, 1.5, 0.6), at(0, y, -74.8), GOLD, { Material = Enum.Material.Metal })
		deco("TrimE", Vector3.new(0.6, 1.5, 150), at(49.8, y, 0), GOLD, { Material = Enum.Material.Metal })
		deco("TrimW", Vector3.new(0.6, 1.5, 150), at(-49.8, y, 0), GOLD, { Material = Enum.Material.Metal })
	end

	-- Säulen
	for _, x in { -32, 32 } do
		for _, z in { -50, -25, 0, 25, 50 } do
			part("Column", Vector3.new(H - 4, 4, 4), at(x, H / 2, z) * CFrame.Angles(0, 0, math.rad(90)), WHITE,
				{ Shape = Enum.PartType.Cylinder, Material = Enum.Material.Marble })
			part("ColumnBase", Vector3.new(6, 2, 6), at(x, 1, z), GOLD, { Material = Enum.Material.Metal })
			deco("ColumnCap", Vector3.new(6, 2, 6), at(x, H - 1, z), GOLD, { Material = Enum.Material.Metal })
		end
	end

	-- Wandbanner
	for _, side in { -1, 1 } do
		for _, z in { -37.5, -12.5, 12.5, 37.5 } do
			local x = side * 49.6
			deco("Banner", Vector3.new(0.3, 18, 7), at(x, 28, z), RED, { Material = Enum.Material.Fabric })
			deco("BannerRod", Vector3.new(0.6, 0.6, 8), at(x, 37.2, z), GOLD, { Material = Enum.Material.Metal })
			deco("BannerFringe", Vector3.new(0.35, 0.6, 7), at(x, 18.8, z), GOLD, { Material = Enum.Material.Metal })
			deco("BannerEmblem", Vector3.new(0.4, 3, 3), at(x - side * 0.1, 29, z) * CFrame.Angles(math.rad(45), 0, 0), GOLD,
				{ Material = Enum.Material.Neon })
		end
	end

	local dust = deco("HallDust", Vector3.new(85, 30, 130), at(0, 20, 0), WHITE, { Transparency = 1 })
	local emitter = Instance.new("ParticleEmitter")
	emitter.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	emitter.Rate = Config.FEEL.hallDustRate
	emitter.Lifetime = NumberRange.new(Config.FEEL.hallDustLifetime)
	emitter.Speed = NumberRange.new(Config.FEEL.hallDustSpeed)
	emitter.SpreadAngle = Vector2.new(180, 180)
	emitter.Size = NumberSequence.new(0.06)
	emitter.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.2, 0.8), NumberSequenceKeypoint.new(0.8, 0.8), NumberSequenceKeypoint.new(1, 1) })
	emitter.LightEmission = 0.3
	emitter.Parent = dust
	for _, side in { -1, 1 } do
		for _, z in { -55, 55 } do
			local window = deco("HighWindow", Vector3.new(0.2, 18, 8), at(side * 49.8, 29, z), Color3.fromRGB(255, 239, 196), { Material = Enum.Material.Neon, Transparency = 0.25 })
			local source = Instance.new("Attachment")
			source.Parent = window
			local target = Instance.new("Attachment")
			target.Position = Vector3.new(-side * 32, -26, 12)
			target.Parent = window
			local beam = Instance.new("Beam")
			beam.Attachment0, beam.Attachment1 = source, target
			beam.Width0, beam.Width1 = 6, 14
			beam.FaceCamera = true
			beam.LightEmission = 1
			beam.Color = ColorSequence.new(Color3.fromRGB(255, 235, 185))
			beam.Transparency = NumberSequence.new(0.93)
			beam.Parent = window
		end
	end

	-- Kronleuchter
	for _, z in { -40, 0, 40 } do
		deco("Chain", Vector3.new(0.4, 8, 0.4), at(0, H - 4, z), GOLD, { Material = Enum.Material.Metal })
		local ring = deco("Chandelier", Vector3.new(0.8, 9, 9), at(0, H - 8, z) * CFrame.Angles(0, 0, math.rad(90)), GOLD,
			{ Shape = Enum.PartType.Cylinder, Material = Enum.Material.Metal })
		for i = 0, 7 do
			local a = i / 8 * math.pi * 2
			deco("Candle", Vector3.new(0.5, 1.2, 0.5), at(math.cos(a) * 4, H - 7, z + math.sin(a) * 4),
				Color3.fromRGB(255, 220, 150), { Material = Enum.Material.Neon })
		end
		local light = Instance.new("PointLight")
		light.Color = Color3.fromRGB(255, 220, 170)
		light.Brightness = Config.FEEL.candleBrightness
		light.Range = 45
		light:SetAttribute("Flicker", light.Brightness)
		light:SetAttribute("FlickerPhase", z * 0.17)
		light.Parent = ring
	end
end

-- Thron auf der Empore -----------------------------------------------------------------------
local function buildThrone()
	for i, step in { { 40, 22, -62 }, { 32, 17, -64.5 }, { 24, 12, -67 } } do
		local y = (i - 0.5) * 1.2
		part("Dais", Vector3.new(step[1], 1.2, step[2]), at(0, y, step[3]), WHITE, { Material = Enum.Material.Marble })
		deco("DaisTrim", Vector3.new(step[1], 0.3, 0.4), at(0, y + 0.45, step[3] + step[2] / 2), GOLD,
			{ Material = Enum.Material.Metal })
	end
	deco("DaisCarpet", Vector3.new(22, 0.2, 10), at(0, 3.7, -67), RED, { Material = Enum.Material.Fabric })

	part("ThroneBase", Vector3.new(9, 2, 7), at(0, 4.6, -68), GOLD, { Material = Enum.Material.Metal })
	-- Sitz schaut in den Saal (+Z)
	local seat = Instance.new("Seat")
	seat.Name = "Throne"
	seat.Anchored = true
	seat.Size = Vector3.new(5, 1.2, 5)
	seat.CFrame = at(0, 6.2, -68) * CFrame.Angles(0, math.pi, 0)
	seat.Color = RED
	seat.Material = Enum.Material.Fabric
	seat.TopSurface = Enum.SurfaceType.Smooth
	seat.Parent = hub
	for _, x in { -3.5, 3.5 } do
		part("Armrest", Vector3.new(1, 3, 6), at(x, 6.6, -68), GOLD, { Material = Enum.Material.Metal })
	end
	part("ThroneBack", Vector3.new(6, 9, 1), at(0, 11, -70.6), RED, { Material = Enum.Material.Fabric })
	part("ThroneFrame", Vector3.new(7.5, 11, 0.8), at(0, 11, -71.2), GOLD, { Material = Enum.Material.Metal })
	for _, x in { -2, 0, 2 } do
		deco("CrownSpike", Vector3.new(1, x == 0 and 3.2 or 2.4, 1), at(x, 17.4, -71.2), GOLD, { Material = Enum.Material.Metal })
	end
	deco("CrownGem", Vector3.new(1.2, 1.2, 1.2), at(0, 16.2, -70.7), Color3.fromRGB(230, 30, 50),
		{ Shape = Enum.PartType.Ball, Material = Enum.Material.Neon })
	label(seat, "Thron", "Draufspringen: Schnellmenü", 9)

	-- Banner und Wappen hinter dem Thron
	for _, x in { -14, 14 } do
		deco("ThroneBanner", Vector3.new(10, 30, 0.3), at(x, 24, -74.7), RED, { Material = Enum.Material.Fabric })
		deco("ThroneBannerTrim", Vector3.new(10, 0.8, 0.4), at(x, 9.4, -74.6), GOLD, { Material = Enum.Material.Metal })
	end
	deco("Crest", Vector3.new(0.4, 10, 10), at(0, 30, -74.6) * CFrame.Angles(0, math.rad(90), 0), GOLD,
		{ Shape = Enum.PartType.Cylinder, Material = Enum.Material.Metal })
	deco("CrestInner", Vector3.new(0.5, 7, 7), at(0, 30, -74.4) * CFrame.Angles(0, math.rad(90), 0), RED,
		{ Shape = Enum.PartType.Cylinder, Material = Enum.Material.Fabric })
end

-- Einrichtungen ----------------------------------------------------------------------------
local function buildWarTable(x, z)
	local top = part("WarTable", Vector3.new(13, 1, 10), at(x, 4, z), WOOD, { Material = Enum.Material.Wood })
	for _, dx in { -5.5, 5.5 } do
		for _, dz in { -4, 4 } do
			part("TableLeg", Vector3.new(1, 3.5, 1), at(x + dx, 1.75, z + dz), WOOD, { Material = Enum.Material.Wood })
		end
	end
	-- Mini-Lageplan aus der ersten Missionskarte
	local map = Stages.List[1].map
	local h, w = #map, #map[1]
	for row = 1, h do
		for col = 1, w do
			local terrain = Config.TERRAIN[string.sub(map[row], col, col)]
			deco("MapTile", Vector3.new(0.95, 0.15, 0.95),
				at(x + (col - (w + 1) / 2), 4.58, z + (row - (h + 1) / 2)), terrain.color)
		end
	end
	deco("FigureBlue", Vector3.new(0.6, 0.9, 0.6), at(x - 3.5, 5.1, z + 2.5), Color3.fromRGB(70, 130, 240))
	deco("FigureRed", Vector3.new(0.6, 0.9, 0.6), at(x + 2.5, 5.1, z - 2.5), RED)
	label(top, "Kriegstisch", "Missionen", 6)
	prompt(top, "missions", "Missionen", "Kriegstisch")
end

local function buildBarracks(x, z)
	local rack = part("WeaponRack", Vector3.new(1, 7, 12), at(x + 6, 3.5, z), WOOD, { Material = Enum.Material.Wood })
	for i = -2, 2 do
		local lance = i % 2 == 0
		deco("RackWeapon", Vector3.new(0.3, lance and 9 or 5, 0.3), at(x + 5.2, lance and 4.5 or 3, z + i * 2.2), METAL,
			{ Material = Enum.Material.Metal })
	end
	part("ArmorStand", Vector3.new(2, 4, 1.2), at(x + 2, 4, z + 6), METAL, { Material = Enum.Material.Metal })
	deco("ArmorHelm", Vector3.new(1.6, 1.4, 1.6), at(x + 2, 6.8, z + 6), METAL, { Material = Enum.Material.Metal })
	deco("BarracksBanner", Vector3.new(0.3, 10, 6), at(x + 6.6, 11, z), RED, { Material = Enum.Material.Fabric })
	task.defer(npc, "Soldier", "IronLance", 3, x, z, math.rad(90))
	label(rack, "Soldatenquartier", "Kaserne", 9)
	prompt(rack, "barracks", "Kaserne", "Soldatenquartier")
end

local function buildSummoningCircle(x, z)
	local circle = part("SummoningCircle", Vector3.new(0.2, 14, 14), at(x, 0.15, z) * CFrame.Angles(0, 0, math.rad(90)), ARCANE,
		{ Shape = Enum.PartType.Cylinder, Material = Enum.Material.Neon, Transparency = 0.55, CanCollide = false })
	local inner = deco("CircleInner", Vector3.new(0.25, 9, 9), at(x, 0.2, z) * CFrame.Angles(0, 0, math.rad(90)), GOLD,
		{ Shape = Enum.PartType.Cylinder, Material = Enum.Material.Neon, Transparency = 0.4 })
	inner:SetAttribute("Spin", 25)
	-- Runensteine rund um den Kreis, drehen sich langsam (Client)
	local runes = Instance.new("Model")
	runes.Name = "Runes"
	for i = 0, 7 do
		local a = i / 8 * math.pi * 2
		deco("Rune", Vector3.new(0.8, 0.3, 0.8), at(x + math.cos(a) * 6, 0.35, z + math.sin(a) * 6) * CFrame.Angles(0, a, 0),
			GOLD, { Material = Enum.Material.Neon, Parent = runes })
	end
	runes.Parent = hub
	runes:SetAttribute("SpinCenter", origin + Vector3.new(x, 0, z))
	runes:SetAttribute("Spin", -15)

	local emitter = Instance.new("ParticleEmitter")
	emitter.Color = ColorSequence.new(ARCANE, GOLD)
	emitter.LightEmission = 1
	emitter.Rate = 12
	emitter.Lifetime = NumberRange.new(1.5, 2.5)
	emitter.Speed = NumberRange.new(2, 4)
	emitter.Size = NumberSequence.new(0.5, 0)
	emitter.Transparency = NumberSequence.new(0.1, 1)
	emitter.EmissionDirection = Enum.NormalId.Right -- Zylinderachse zeigt nach oben
	emitter.Parent = circle
	local light = Instance.new("PointLight")
	light.Color = ARCANE
	light.Brightness = 2
	light.Range = 18
	light.Parent = circle

	task.defer(npc, "Mage", "Fire", 5, x - 9, z, math.rad(-90), Color3.fromRGB(240, 240, 250))
	label(circle, "Beschwörungskreis", "Rekrutieren", 8)
	prompt(circle, "recruit", "Beschwören", "Hofmagier")
end

-- Öffentliche API ---------------------------------------------------------------------------
function HubBuilder.build()
	local old = workspace:FindFirstChild("Hub")
	if old then
		old:Destroy()
	end
	hub = Instance.new("Model")
	hub.Name = "Hub"

	buildRoom()
	buildThrone()
	buildWarTable(-18, -20)
	buildBarracks(20, -20)
	buildSummoningCircle(-18, 28)

	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "HubSpawn"
	spawn.Anchored = true
	spawn.Size = Vector3.new(10, 1, 10)
	spawn.CFrame = at(0, 0.1, 60)
	spawn.Transparency = 1
	spawn.CanCollide = false
	spawn.Neutral = true
	spawn.Duration = 0
	spawn.Parent = hub

	hub.Parent = workspace

	Lighting.Ambient = Color3.fromRGB(120, 110, 100)
	Lighting.OutdoorAmbient = Color3.fromRGB(150, 140, 130)
	Lighting.LightingStyle = Enum.LightingStyle.Realistic
	Lighting.PrioritizeLightingQuality = true
	Lighting.Brightness = Config.FEEL.hallBrightness
	Lighting.ExposureCompensation = Config.FEEL.hallExposure
	Lighting.GlobalShadows = true
	Lighting.ClockTime = 14
	return hub
end

return HubBuilder
