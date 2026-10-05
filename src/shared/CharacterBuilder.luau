-- Baut Block-Figuren mit Gelenken (Motor6D), die der Client animiert.
-- Die Figur schaut entlang -Z; Root liegt am Boden und ist unsichtbar.
-- Liegt in Shared: Server baut die Spielfiguren, Client baut Porträts (Kaserne, Rekrutierung).
local Config = require(script.Parent.Config)
local UnitData = require(script.Parent.UnitData)

local CharacterBuilder = {}

local SKIN = Color3.fromRGB(236, 196, 164)
local METAL = Color3.fromRGB(185, 192, 204)
local DARK_METAL = Color3.fromRGB(105, 110, 124)
local WOOD = Color3.fromRGB(112, 76, 46)
local LEATHER = Color3.fromRGB(92, 64, 44)
local GOLD = Color3.fromRGB(232, 188, 74)
local PANTS = Color3.fromRGB(58, 52, 64)
local HORSE = Color3.fromRGB(128, 86, 54)
local HORSE_HAIR = Color3.fromRGB(50, 35, 25)
local BONE = Color3.fromRGB(235, 225, 200)

-- "team" = Teamfarbe (wird grau, wenn die Einheit fertig ist)
local LOOKS = {
	Lord = { torso = "team", arms = "team", legs = PANTS, hair = Color3.fromRGB(70, 48, 32), headgear = "circlet", cape = true },
	Cavalier = { torso = METAL, arms = "team", legs = PANTS, headgear = "helmet", mount = true, pads = true },
	Archer = { torso = "team", arms = "team", legs = LEATHER, hair = Color3.fromRGB(196, 150, 80), headgear = "hood", quiver = true },
	Mage = { torso = "team", arms = "team", legs = "team", hair = Color3.fromRGB(150, 60, 50), headgear = "wizard" },
	Fighter = { torso = "team", arms = SKIN, legs = LEATHER, hair = Color3.fromRGB(40, 30, 25), headgear = "bandana" },
	Brigand = { torso = "team", arms = SKIN, legs = LEATHER, hair = Color3.fromRGB(40, 30, 25), headgear = "bandana" },
	Soldier = { torso = METAL, arms = "team", legs = PANTS, headgear = "helmet", pads = true },
	EnemyArcher = { torso = "team", arms = "team", legs = LEATHER, hair = Color3.fromRGB(60, 40, 30), headgear = "hood", quiver = true },
	Chieftain = { torso = "team", arms = SKIN, legs = LEATHER, headgear = "horned", pads = true, scale = 1.2 },
}

function CharacterBuilder.build(unit)
	local look = LOOKS[unit.class] or LOOKS.Fighter
	local s = look.scale or 1
	local teamColor = Config.TEAM_COLORS[unit.team]
	local weapon = UnitData.Weapons[unit.weapon]

	local model = Instance.new("Model")
	model.Name = unit.id

	local function at(x, y, z)
		return CFrame.new(x * s, y * s, z * s)
	end

	local function part(name, size, cf, color, props)
		local p = Instance.new("Part")
		p.Name = name
		p.Size = size * s
		p.CFrame = cf
		p.Anchored = false
		p.CanCollide = false
		p.CanTouch = false
		p.Massless = true
		p.TopSurface = Enum.SurfaceType.Smooth
		p.BottomSurface = Enum.SurfaceType.Smooth
		p.Material = Enum.Material.SmoothPlastic
		if color == "team" then
			p.Color = teamColor
			p:SetAttribute("Tint", true)
		else
			p.Color = color
		end
		if props then
			for k, v in props do
				p[k] = v
			end
		end
		p.Parent = model
		return p
	end

	local function weld(p0, p1)
		local w = Instance.new("WeldConstraint")
		w.Part0 = p0
		w.Part1 = p1
		w.Parent = p1
	end

	-- Gelenk an der Weltposition jointCF (C0/C1 so, dass die aktuelle Pose die Ruhepose ist)
	local function motor(name, p0, p1, jointCF)
		local m = Instance.new("Motor6D")
		m.Name = name
		m.Part0 = p0
		m.Part1 = p1
		m.C0 = p0.CFrame:ToObjectSpace(jointCF)
		m.C1 = p1.CFrame:ToObjectSpace(jointCF)
		m.Parent = p0
	end

	local root = part("Root", Vector3.new(1, 0.2, 1), CFrame.new(), Color3.new(), {
		Anchored = true, Transparency = 1, CanQuery = false,
	})
	model.PrimaryPart = root

	local mounted = look.mount == true
	local hipY = mounted and 4.2 or 2

	-- Pferd ------------------------------------------------------------------
	if mounted then
		local horse = {
			part("HorseBody", Vector3.new(2, 2, 4.2), at(0, 3.1, 0.2), HORSE),
			part("HorseNeck", Vector3.new(0.9, 2.2, 1), at(0, 4.4, -1.9) * CFrame.Angles(math.rad(-35), 0, 0), HORSE),
			part("HorseHead", Vector3.new(0.85, 0.85, 1.7), at(0, 5.4, -2.75), HORSE),
			part("HorseMane", Vector3.new(0.3, 1.9, 0.5), at(0, 4.7, -1.55) * CFrame.Angles(math.rad(-35), 0, 0), HORSE_HAIR),
			part("HorseTail", Vector3.new(0.35, 1.6, 0.35), at(0, 3.3, 2.5) * CFrame.Angles(math.rad(30), 0, 0), HORSE_HAIR),
			part("Saddle", Vector3.new(2.1, 0.3, 1.6), at(0, 4.15, 0.2), "team"),
		}
		for _, dx in { -0.65, 0.65 } do
			for _, dz in { -1.5, 1.8 } do
				table.insert(horse, part("HorseLeg", Vector3.new(0.55, 2.1, 0.55), at(dx, 1.05, dz), HORSE))
			end
		end
		for _, p in horse do
			weld(root, p)
		end
		for _, dx in { -1.15, 1.15 } do
			weld(root, part("RiderLeg", Vector3.new(0.8, 1.8, 0.8), at(dx, 3.7, -0.1), look.legs))
		end
	end

	-- Körper -----------------------------------------------------------------
	local torso = part("Torso", Vector3.new(2, 2, 1), at(0, hipY + 1, 0), look.torso)
	motor("RootJoint", root, torso, at(0, hipY, 0))
	weld(torso, part("Belt", Vector3.new(2.05, 0.3, 1.05), at(0, hipY + 0.15, 0), LEATHER))

	if not mounted then
		local lLeg = part("LeftLeg", Vector3.new(0.95, 2, 0.95), at(-0.5, 1, 0), look.legs)
		local rLeg = part("RightLeg", Vector3.new(0.95, 2, 0.95), at(0.5, 1, 0), look.legs)
		motor("LeftHip", root, lLeg, at(-0.5, 2, 0))
		motor("RightHip", root, rLeg, at(0.5, 2, 0))
	end

	local hy = hipY + 2.8
	local head = part("Head", Vector3.new(1.6, 1.6, 1.6), at(0, hy, 0), SKIN)
	motor("Neck", torso, head, at(0, hipY + 2, 0))
	local face = Instance.new("Decal")
	face.Texture = "rbxasset://textures/face.png"
	face.Face = Enum.NormalId.Front
	face.Parent = head

	local rArm = part("RightArm", Vector3.new(0.8, 2, 0.8), at(1.4, hipY + 1, 0), look.arms)
	local lArm = part("LeftArm", Vector3.new(0.8, 2, 0.8), at(-1.4, hipY + 1, 0), look.arms)
	motor("RightShoulder", torso, rArm, at(1.4, hipY + 1.9, 0))
	motor("LeftShoulder", torso, lArm, at(-1.4, hipY + 1.9, 0))

	-- Zubehör (nicht anklickbar) ----------------------------------------------
	local function extra(name, size, cf, color, attachTo, props)
		local p = part(name, size, cf, color, props)
		p.CanQuery = false
		weld(attachTo, p)
		return p
	end

	local heroDef = unit.heroId and UnitData.Heroes[unit.heroId]
	local hair = (heroDef and heroDef.hair) or look.hair
	if hair then
		extra("Hair", Vector3.new(1.7, 0.45, 1.7), at(0, hy + 0.7, 0.05), hair, head)
		extra("HairBack", Vector3.new(1.7, 1.1, 0.4), at(0, hy + 0.2, 0.7), hair, head)
	end

	local g = look.headgear
	if g == "circlet" then
		extra("Circlet", Vector3.new(1.72, 0.18, 1.72), at(0, hy + 0.45, 0), GOLD, head, { Material = Enum.Material.Metal })
		extra("Gem", Vector3.new(0.28, 0.28, 0.1), at(0, hy + 0.45, -0.88), Color3.fromRGB(80, 200, 255), head, { Material = Enum.Material.Neon })
	elseif g == "helmet" then
		extra("Helmet", Vector3.new(1.8, 0.9, 1.8), at(0, hy + 0.5, 0), METAL, head, { Material = Enum.Material.Metal })
		extra("Plume", Vector3.new(0.3, 0.7, 1.4), at(0, hy + 1.2, 0.1), "team", head)
	elseif g == "hood" then
		extra("Hood", Vector3.new(1.8, 0.5, 1.8), at(0, hy + 0.65, 0.05), "team", head)
		extra("HoodBack", Vector3.new(1.8, 1.6, 0.45), at(0, hy + 0.05, 0.7), "team", head)
	elseif g == "wizard" then
		extra("Brim", Vector3.new(0.15, 2.6, 2.6), at(0, hy + 0.75, 0) * CFrame.Angles(0, 0, math.rad(90)), "team", head,
			{ Shape = Enum.PartType.Cylinder })
		extra("Cone1", Vector3.new(1.3, 0.6, 1.3), at(0, hy + 1.1, 0) * CFrame.Angles(0, math.rad(45), 0), "team", head)
		extra("Cone2", Vector3.new(0.85, 0.6, 0.85), at(0.1, hy + 1.65, 0.1) * CFrame.Angles(0, math.rad(45), 0), "team", head)
		extra("Cone3", Vector3.new(0.4, 0.6, 0.4), at(0.25, hy + 2.15, 0.25) * CFrame.Angles(0, math.rad(45), 0), "team", head)
	elseif g == "bandana" then
		extra("Bandana", Vector3.new(1.7, 0.4, 1.7), at(0, hy + 0.4, 0), "team", head)
		extra("Knot", Vector3.new(0.3, 0.5, 0.5), at(0, hy + 0.3, 0.95), "team", head)
	elseif g == "horned" then
		extra("Helmet", Vector3.new(1.8, 0.9, 1.8), at(0, hy + 0.5, 0), DARK_METAL, head, { Material = Enum.Material.Metal })
		extra("HornL", Vector3.new(0.3, 1.1, 0.3), at(-1.0, hy + 1.1, 0) * CFrame.Angles(0, 0, math.rad(30)), BONE, head)
		extra("HornR", Vector3.new(0.3, 1.1, 0.3), at(1.0, hy + 1.1, 0) * CFrame.Angles(0, 0, math.rad(-30)), BONE, head)
	end

	if look.cape then
		extra("Cape", Vector3.new(1.9, 2.4, 0.15), at(0, hipY + 0.9, 0.62) * CFrame.Angles(math.rad(8), 0, 0), "team", torso,
			{ Material = Enum.Material.Fabric })
	end
	if look.pads then
		extra("PadR", Vector3.new(1.0, 0.5, 1.0), at(1.4, hipY + 2.0, 0), METAL, rArm, { Material = Enum.Material.Metal })
		extra("PadL", Vector3.new(1.0, 0.5, 1.0), at(-1.4, hipY + 2.0, 0), METAL, lArm, { Material = Enum.Material.Metal })
	end
	if look.quiver then
		extra("Quiver", Vector3.new(0.6, 1.8, 0.6), at(0.5, hipY + 1.3, 0.75) * CFrame.Angles(0, 0, math.rad(-25)), LEATHER, torso)
	end

	-- Waffe: in Ruhepose nach vorne (-Z) aus der Hand -------------------------
	local metal = { Material = Enum.Material.Metal }
	local hx, hY = 1.4, hipY + 0.1
	local t = weapon.type
	if t == "Sword" then
		extra("Grip", Vector3.new(0.2, 0.2, 0.6), at(hx, hY, 0), LEATHER, rArm)
		extra("Guard", Vector3.new(0.9, 0.18, 0.2), at(hx, hY, -0.35), unit.isLord and GOLD or DARK_METAL, rArm, metal)
		extra("Blade", Vector3.new(0.14, 0.32, 2.6), at(hx, hY, -1.75), METAL, rArm, metal)
	elseif t == "Axe" then
		local big = weapon.might >= 10
		extra("Haft", Vector3.new(0.2, 0.2, big and 2.8 or 2.4), at(hx, hY, big and -1.0 or -0.8), WOOD, rArm)
		extra("AxeHead", Vector3.new(0.15, big and 1.3 or 1.0, big and 1.0 or 0.8), at(hx, hY + 0.45, big and -2.1 or -1.7),
			big and DARK_METAL or METAL, rArm, metal)
	elseif t == "Lance" then
		local len = unit.weapon == "Javelin" and 3.4 or 5
		extra("Shaft", Vector3.new(0.18, 0.18, len), at(hx, hY, -len / 2 + 0.8), WOOD, rArm)
		extra("Tip", Vector3.new(0.3, 0.3, 0.8), at(hx, hY, -len + 0.4) * CFrame.Angles(0, 0, math.rad(45)), METAL, rArm, metal)
	elseif t == "Bow" then
		-- liegt waagerecht in der linken Hand; beim Anheben des Arms steht er senkrecht
		extra("Bow", Vector3.new(0.15, 0.25, 3.2), at(-hx, hY, -0.3), WOOD, lArm)
		extra("String", Vector3.new(0.05, 0.05, 3.0), at(-hx, hY + 0.35, -0.3), Color3.fromRGB(240, 240, 230), lArm)
	elseif t == "Anima" then
		extra("Tome", Vector3.new(0.25, 1.1, 0.9), at(-hx, hY - 0.1, -0.35), Color3.fromRGB(180, 40, 30), lArm)
		extra("Pages", Vector3.new(0.3, 0.95, 0.8), at(-hx, hY - 0.1, -0.33), Color3.fromRGB(245, 240, 225), lArm)
	end

	-- Seltenheit: jede Stufe legt sichtbar etwas drauf ----------------------
	local rarity = unit.rarity or 1
	local rarityColor = UnitData.Rarities[rarity].color
	local function sparkles(parent, rate, size, lifetime, speed)
		local e = Instance.new("ParticleEmitter")
		e.Color = ColorSequence.new(rarityColor)
		e.LightEmission = 1
		e.Rate = rate
		e.Lifetime = NumberRange.new(lifetime * 0.7, lifetime)
		e.Speed = NumberRange.new(speed * 0.5, speed)
		e.Size = NumberSequence.new(size, 0)
		e.Transparency = NumberSequence.new(0.1, 1)
		e.SpreadAngle = Vector2.new(25, 25)
		e.Parent = parent
		return e
	end

	if rarity >= 2 then -- Ungewöhnlich: farbige Gürtelschnalle
		extra("Buckle", Vector3.new(0.5, 0.35, 0.1), at(0, hipY + 0.15, -0.55), rarityColor, torso,
			{ Material = Enum.Material.Neon })
	end
	if rarity >= 3 then -- Selten: Kragen-Verzierung
		extra("Collar", Vector3.new(2.1, 0.25, 1.1), at(0, hipY + 1.9, 0), rarity >= 5 and GOLD or METAL, torso,
			{ Material = Enum.Material.Metal })
	end
	if rarity >= 4 then -- Episch: leuchtende Waffe mit Funken, Umhang mit Saum
		local weaponPart = model:FindFirstChild("Blade") or model:FindFirstChild("AxeHead") or model:FindFirstChild("Tip")
			or model:FindFirstChild("Bow") or model:FindFirstChild("Tome")
		if weaponPart then
			local light = Instance.new("PointLight")
			light.Color = rarityColor
			light.Brightness = 1.5
			light.Range = 7
			light.Parent = weaponPart
			sparkles(weaponPart, 4, 0.25 * s, 0.8, 1)
		end
		if not look.cape and not mounted then
			extra("Cape", Vector3.new(1.9, 2.4, 0.15), at(0, hipY + 0.9, 0.62) * CFrame.Angles(math.rad(8), 0, 0), "team",
				torso, { Material = Enum.Material.Fabric })
		end
		extra("CapeTrim", Vector3.new(1.95, 0.25, 0.18), at(0, hipY - 0.25, 0.79) * CFrame.Angles(math.rad(8), 0, 0),
			rarityColor, torso, { Material = Enum.Material.Neon })
	end
	if rarity >= 5 then -- Legendär: goldenes Wappen und Aura am Boden
		extra("Crest", Vector3.new(0.7, 0.7, 0.1), at(0, hipY + 1.2, -0.55) * CFrame.Angles(0, 0, math.rad(45)), GOLD,
			torso, { Material = Enum.Material.Neon })
		extra("AuraRing", Vector3.new(0.1, 5.5, 5.5), at(0, 0.08, 0) * CFrame.Angles(0, 0, math.rad(90)), rarityColor, root,
			{ Material = Enum.Material.Neon, Shape = Enum.PartType.Cylinder, Transparency = 0.65, CastShadow = false })
		local emitter = extra("AuraEmitter", Vector3.new(4, 0.1, 4), at(0, 0.1, 0), rarityColor, root,
			{ Transparency = 1, CastShadow = false })
		local e = sparkles(emitter, 8, 0.4, 1.4, 3)
		e.EmissionDirection = Enum.NormalId.Top
	end

	local topY = hipY + 3.8 + (g == "wizard" and 1.4 or 0) + (g == "horned" and 0.6 or 0)
	model:SetAttribute("TopY", topY * s)
	model:SetAttribute("HeadY", hy * s)

	return model
end

return CharacterBuilder
