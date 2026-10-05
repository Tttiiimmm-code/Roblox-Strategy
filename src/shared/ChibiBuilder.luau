-- Eigene Teile-Figuren für Server und Porträts; Blickrichtung -Z, Wurzel am Boden.
local Config = require(script.Parent.Config)
local UnitData = require(script.Parent.UnitData)
local ChibiBuilder = {}

local METAL = Color3.fromRGB(185, 192, 204)
local DARK_METAL = Color3.fromRGB(105, 110, 124)
local WOOD = Color3.fromRGB(112, 76, 46)
local LEATHER = Color3.fromRGB(92, 64, 44)
local GOLD = Color3.fromRGB(232, 188, 74)
local HORSE = Color3.fromRGB(128, 86, 54)
local HORSE_HAIR = Color3.fromRGB(50, 35, 25)
local BONE = Color3.fromRGB(235, 225, 200)
local DARK = Color3.fromRGB(65, 35, 35)

function ChibiBuilder.build(unit)
	local hero = unit.heroId and UnitData.Heroes[unit.heroId]
	local look = (hero and hero.chibi) or UnitData.Classes[unit.class].chibi
	local s, body = look.scale or 1, Config.CHIBI
	local weapon = UnitData.Weapons[unit.weapon]
	local rarity = unit.rarity or 1
	local rarityColor = UnitData.Rarities[rarity].color
	local mounted = unit.class == "Cavalier"
	local lift = mounted and body.riderLift or 0
	local model = Instance.new("Model")
	model.Name = unit.id

	local function at(x, y, z)
		return CFrame.new(x * s, y * s, z * s)
	end
	local function part(name, size, cf, color, props, tint)
		local p = Instance.new(props and props.Wedge and "WedgePart" or "Part")
		p.Name, p.Size, p.CFrame = name, size * s, cf
		p.CanCollide, p.CanTouch, p.Massless = false, false, true
		p.TopSurface, p.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
		p.Material = Enum.Material.SmoothPlastic
		p.Color = color == "team" and Config.TEAM_COLORS[unit.team] or color
		if color == "team" or tint then p:SetAttribute("Tint", true) end
		if tint and color ~= "team" then p:SetAttribute("BaseColor", color) end
		-- Kugel-Teile erzwingen gleiche Achsen; Ellipsen (Augen, Helm, Pferd) daher als Block mit Kugel-Mesh.
		local ellipsoid = props and props.Shape == Enum.PartType.Ball and (size.X ~= size.Y or size.Y ~= size.Z)
		if props then
			for k, v in props do
				if k ~= "Wedge" and not (ellipsoid and k == "Shape") then p[k] = v end
			end
		end
		if ellipsoid then
			local mesh = Instance.new("SpecialMesh")
			mesh.MeshType = Enum.MeshType.Sphere
			mesh.Parent = p
		end
		p.Parent = model
		return p
	end
	local function weld(p0, p1)
		local w = Instance.new("WeldConstraint")
		w.Part0, w.Part1, w.Parent = p0, p1, p1
	end
	local function motor(name, p0, p1, jointCF)
		local m = Instance.new("Motor6D")
		m.Name, m.Part0, m.Part1 = name, p0, p1
		m.C0 = p0.CFrame:ToObjectSpace(jointCF)
		m.C1 = p1.CFrame:ToObjectSpace(jointCF)
		m.Parent = p0
	end
	local function extra(name, size, cf, color, attachTo, props, tint)
		local p = part(name, size, cf, color, props, tint)
		p.CanQuery = false
		weld(attachTo, p)
		return p
	end
	local fabric = { Material = Enum.Material.Fabric }
	local metal = { Material = Enum.Material.Metal }
	local ball = { Shape = Enum.PartType.Ball }
	local function sphere(name, diameter, cf, color, attachTo, props)
		local options = table.clone(props or {})
		options.Shape = Enum.PartType.Ball
		return extra(name, Vector3.new(diameter, diameter, diameter), cf, color, attachTo, options)
	end
	local root = part("HumanoidRootPart", Vector3.new(1, 0.2, 1), CFrame.new(), Color3.new(), {
		Anchored = true, Transparency = 1, CanQuery = false,
	})
	model.PrimaryPart = root
	model:SetAttribute("GroundOffset", 0)
	model:SetAttribute("Mounted", mounted)

	-- Pferd aus dem alten Baukasten, mit kürzerem Körper für den großen Reiterkopf.
	if mounted then
		extra("HorseBody", Vector3.new(2, 1.7, 3.8), at(0, 2.65, 0.2), HORSE, root, ball)
		extra("HorseNeck", Vector3.new(0.9, 1.9, 1), at(0, 3.6, -1.6) * CFrame.Angles(math.rad(-35), 0, 0), HORSE, root)
		extra("HorseHead", Vector3.new(1, 1, 1.7), at(0, 4.35, -2.3), HORSE, root, ball)
		extra("HorseMane", Vector3.new(0.3, 1.6, 0.5), at(0, 3.8, -1.25) * CFrame.Angles(math.rad(-35), 0, 0), HORSE_HAIR, root)
		extra("HorseTail", Vector3.new(0.35, 1.5, 0.35), at(0, 2.8, 2.25) * CFrame.Angles(math.rad(30), 0, 0), HORSE_HAIR, root)
		extra("Saddle", Vector3.new(2.1, 0.3, 1.6), at(0, 3.55, 0.2), "team", root, fabric)
		for _, dx in { -0.65, 0.65 } do
			for _, dz in { -1.2, 1.6 } do
				extra("HorseLeg", Vector3.new(0.55, 1.9, 0.55), at(dx, 0.95, dz), HORSE, root)
				extra("Hoof", Vector3.new(0.58, 0.3, 0.6), at(dx, 0.15, dz), HORSE_HAIR, root)
			end
		end
		for _, sign in { -1, 1 } do
			sphere("HorseEye", 0.18, at(sign * 0.48, 4.5, -2.65), DARK, root)
		end
	end

	local hipY = body.hipY + lift
	local torso = part("UpperTorso", body.torsoSize, at(0, body.torsoY + lift, 0), look.outfit.primary, fabric, true)
	motor("Root", root, torso, at(0, hipY, 0))
	extra("Belt", Vector3.new(body.torsoSize.X + 0.05, 0.22, body.torsoSize.Z + 0.05), at(0, hipY + 0.12, 0), look.outfit.trim, torso, fabric, true)
	if look.robe then
		extra("Robe", Vector3.new(1.8, 0.9, 1.2), at(0, hipY - 0.05, 0), look.outfit.primary, torso, fabric, true)
		extra("RobeHem", Vector3.new(1.85, 0.15, 1.25), at(0, hipY - 0.45, 0), look.outfit.trim, torso, fabric, true)
	end
	for _, sign in { -1, 1 } do
		local side = sign == 1 and "Right" or "Left"
		local x = sign * (mounted and 1.1 or body.legX)
		local legCF = at(x, hipY - body.legSize.Y / 2, 0)
		local jointCF = at(x, hipY, 0)
		if mounted then
			legCF = jointCF * CFrame.Angles(math.rad(body.riderHipAngle), 0, sign * math.rad(12)) * at(0, -body.legSize.Y / 2, 0)
		end
		local leg = part(side .. "Leg", body.legSize, legCF, look.outfit.secondary, fabric, true)
		motor(side .. "Hip", torso, leg, jointCF)
		extra(side .. "Boot", Vector3.new(body.legSize.X + 0.03, body.bootHeight, body.legSize.Z + 0.08),
			legCF * at(0, -body.legSize.Y / 2 + body.bootHeight / 2, -0.03), look.outfit.trim, leg, nil, true)
	end

	local headY = body.headY + lift
	local head = part("Head", Vector3.new(body.headDiameter, body.headDiameter, body.headDiameter), at(0, headY, 0), look.skin, ball)
	motor("Neck", torso, head, at(0, body.neckY + lift, 0))
	local hands = {}
	for _, sign in { -1, 1 } do
		local side = sign == 1 and "Right" or "Left"
		local x = sign * body.shoulderX
		local armY = body.shoulderY + lift - body.armSize.Y / 2
		local arm = part(side .. "Arm", body.armSize, at(x, armY, 0), look.outfit.secondary, fabric, true)
		motor(side .. "Shoulder", torso, arm, at(x, body.shoulderY + lift, 0))
		hands[side] = sphere(side .. "Hand", body.handDiameter, at(x, armY - body.armSize.Y / 2, 0), look.skin, arm)
		extra(side .. "ShoulderPad", Vector3.new(0.75, 0.3, 0.75), at(x, body.shoulderY + lift, 0), "team", arm, metal)
	end
	extra("Sash", Vector3.new(0.24, 1.35, 0.08), at(0, body.torsoY + lift, -0.59) * CFrame.Angles(0, 0, math.rad(-28)), "team", torso, fabric)

	-- Gesichtsteile liegen entlang der Kugelnormale, damit Haare die Augen freilassen.
	local function faceCF(x, y)
		local dy = y - body.headY
		local radius = body.headDiameter / 2
		local z = -math.sqrt(radius * radius - x * x - dy * dy)
		local normal = Vector3.new(x, dy, z).Unit
		local position = Vector3.new(x, y + lift, z) * s + normal * 0.04 * s
		return CFrame.lookAt(position, position + normal)
	end
	for _, sign in { -1, 1 } do
		local cf = faceCF(sign * body.eyeX, body.eyeY)
		extra("Eye", body.eyeSize, cf, look.eyes, head, ball)
		extra("EyeShine", Vector3.new(0.14, 0.14, 0.06), cf * at(-sign * 0.07, 0.15, -0.075), Color3.new(1, 1, 1), head,
			{ Material = Enum.Material.Neon, Shape = Enum.PartType.Ball })
		extra("Blush", Vector3.new(0.3, 0.12, 0.08), faceCF(sign * 0.75, 3.35), Color3.fromRGB(245, 140, 145), head,
			{ Transparency = 0.4, Shape = Enum.PartType.Ball })
		if unit.class == "Chieftain" then
			extra("Eyebrow", Vector3.new(0.48, 0.1, 0.08), faceCF(sign * body.eyeX, 4.02) * CFrame.Angles(0, 0, sign * math.rad(18)), look.hairColor, head)
		end
	end
	extra("Mouth", Vector3.new(0.3, 0.06, 0.08), faceCF(0, 3.15), DARK, head, ball)
	if look.beard then
		extra("Beard", Vector3.new(1.1, 0.65, 0.65), at(0, headY - 1.05, -0.45), look.hairColor, head)
	end

	local hair = look.hairStyle
	if hair ~= "none" then
		sphere("HairCap", 2.75, at(0, 3.85 + lift, 0.15), look.hairColor, head)
		if hair == "spiky" then
			for i = 1, 5 do
				extra("HairSpike", Vector3.new(0.55, 0.9, 0.65), at((i - 3) * 0.38, 4.95 + lift, 0.35 + math.abs(i - 3) * 0.1)
					* CFrame.Angles(math.rad(-20), 0, math.rad((3 - i) * 16)), look.hairColor, head, { Wedge = true })
			end
		elseif hair == "long" then
			extra("HairBack", Vector3.new(2.2, 2.2, 0.5), at(0, 3.2 + lift, 0.9), look.hairColor, head)
		elseif hair == "ponytail" then
			sphere("PonytailTie", 0.9, at(0, 4.2 + lift, 1.4), look.hairColor, head)
			extra("Ponytail", Vector3.new(0.6, 1.6, 0.6), at(0, 3.3 + lift, 1.55) * CFrame.Angles(math.rad(12), 0, 0), look.hairColor, head)
		elseif hair == "bun" then
			sphere("HairBun", 1, at(0, 5 + lift, 0.8), look.hairColor, head)
		end
	end

	local g, gear = look.headgear, look.headgearColor
	local function band(name, y, radius, height, color, material)
		for i = 1, 16 do
			local angle = i * math.pi / 8
			extra(name, Vector3.new(radius * 0.4, height, 0.12), at(math.sin(angle) * radius, y + lift, math.cos(angle) * radius)
				* CFrame.Angles(0, angle, 0), color, head, { Material = material })
		end
	end
	local function brim(name, diameter, y, color)
		return extra(name, Vector3.new(0.15, diameter, diameter), at(0, y + lift, 0.15) * CFrame.Angles(0, 0, math.rad(90)), color, head,
			{ Shape = Enum.PartType.Cylinder, Material = g == "kettle" and Enum.Material.Metal or Enum.Material.Fabric })
	end
	if g == "crown" or g == "tiara" then
		band("CrownBand", 4.65, 1.05, g == "crown" and 0.25 or 0.12, gear, Enum.Material.Metal)
		if g == "crown" then
			for i = 1, 5 do
				local angle = i * math.pi * 2 / 5
				extra("CrownPoint", Vector3.new(0.3, 0.6, 0.3), at(math.sin(angle), 5 + lift, math.cos(angle))
					* CFrame.Angles(0, angle, 0), gear, head, { Wedge = true, Material = Enum.Material.Metal })
			end
		end
		sphere("TiaraGem", 0.3, at(0, 4.65 + lift, -1.12), rarityColor, head, { Material = Enum.Material.Neon })
	elseif g == "headband" or g == "bandana" then
		band("Headband", 4.28, 1.26, g == "bandana" and 0.28 or 0.15, gear, g == "headband" and Enum.Material.Metal or Enum.Material.Fabric)
		if g == "bandana" then
			extra("BandanaKnot", Vector3.new(0.4, 0.45, 0.5), at(0, 4.2 + lift, 1.5), gear, head, fabric)
		end
	elseif g == "wizard" then
		brim("WizardBrim", 3.4, 4.75, gear)
		for i = 1, 3 do
			local diameter = 2.1 - (i - 1) * 0.65
			extra("WizardTier", Vector3.new(0.55, diameter, diameter), at((i - 1) * 0.12, 4.98 + i * 0.45 + lift, 0.15)
				* CFrame.Angles(0, 0, math.rad(90 + (i == 3 and -15 or 0))), gear, head,
				{ Shape = Enum.PartType.Cylinder, Material = Enum.Material.Fabric })
		end
	elseif g == "hood" then
		sphere("Hood", 2.95, at(0, 4.05 + lift, 0.65), gear, head, fabric)
	elseif g == "helmet" or g == "kettle" or g == "horned" then
		-- Die Schale sitzt oben/hinten; Mund und Augen bleiben vor ihrer Vorderkante.
		extra("HelmetShell", Vector3.new(2.85, 1.65, 2.85), at(0, 4.45 + lift, 0.4), gear, head,
			{ Shape = Enum.PartType.Ball, Material = Enum.Material.Metal })
		if g == "helmet" then
			extra("Plume", Vector3.new(0.35, 0.75, 1.4), at(0, 5.35 + lift, 0.4), look.plumeColor or "team", head, fabric)
		elseif g == "kettle" then
			brim("KettleBrim", 3.3, 4.35, gear)
		else
			for _, sign in { -1, 1 } do
				extra("Horn", Vector3.new(0.35, 1.1, 0.35), at(sign * 1.4, 5.15 + lift, 0.25)
					* CFrame.Angles(0, 0, -sign * math.rad(35)), BONE, head)
			end
		end
	end

	-- Waffen aus dem alten Baukasten, an die kleineren Hände angepasst.
	local hx, hY = body.shoulderX, body.shoulderY + lift - body.armSize.Y
	local rHand, lHand = hands.Right, hands.Left
	local t = weapon.type
	if t == "Sword" then
		extra("Grip", Vector3.new(0.2, 0.2, 0.5), at(hx, hY, 0), LEATHER, rHand)
		extra("Guard", Vector3.new(0.75, 0.16, 0.2), at(hx, hY, -0.3), unit.isLord and GOLD or DARK_METAL, rHand, metal)
		extra("Blade", Vector3.new(0.14, 0.28, 2.1), at(hx, hY, -1.4), METAL, rHand, metal)
	elseif t == "Axe" then
		local big = weapon.might >= 10
		extra("Haft", Vector3.new(0.2, 0.2, big and 2.6 or 2.1), at(hx, hY, -0.8), WOOD, rHand)
		extra("AxeHead", Vector3.new(0.18, big and 1.2 or 0.9, big and 0.9 or 0.7), at(hx, hY + 0.4, big and -1.8 or -1.5),
			big and DARK_METAL or METAL, rHand, metal)
	elseif t == "Lance" then
		local len = unit.weapon == "Javelin" and 3 or 4.2
		extra("Shaft", Vector3.new(0.18, 0.18, len), at(hx, hY, -len / 2 + 0.7), WOOD, rHand)
		extra("Tip", Vector3.new(0.3, 0.3, 0.7), at(hx, hY, -len + 0.35) * CFrame.Angles(0, 0, math.rad(45)), METAL, rHand, metal)
	elseif t == "Bow" then
		extra("Bow", Vector3.new(0.15, 0.25, 2.5), at(-hx, hY, -0.3), WOOD, lHand)
		extra("String", Vector3.new(0.04, 0.04, 2.4), at(-hx, hY + 0.3, -0.3), Color3.fromRGB(240, 240, 230), lHand)
	elseif t == "Anima" then
		extra("Tome", Vector3.new(0.3, 0.9, 0.8), at(-hx, hY - 0.1, -0.35), look.outfit.primary, lHand, fabric, true)
		extra("Pages", Vector3.new(0.32, 0.75, 0.7), at(-hx, hY - 0.1, -0.33), Color3.fromRGB(245, 240, 225), lHand)
	end

	local function sparkles(parent, rate, size, lifetime, speed)
		local e = Instance.new("ParticleEmitter")
		e.Color = ColorSequence.new(rarityColor)
		e.LightEmission, e.Rate = 1, rate
		e.Lifetime = NumberRange.new(lifetime * 0.7, lifetime)
		e.Speed = NumberRange.new(speed * 0.5, speed)
		e.Size = NumberSequence.new(size * s, 0)
		e.Transparency = NumberSequence.new(0.1, 1)
		e.SpreadAngle = Vector2.new(25, 25)
		e.Parent = parent
		return e
	end
	if rarity >= 2 then
		extra("Buckle", Vector3.new(0.4, 0.25, 0.1), at(0, hipY + 0.12, -0.61), rarityColor, torso, { Material = Enum.Material.Neon })
	end
	if rarity >= 3 then
		extra("Collar", Vector3.new(1.75, 0.18, 1.15), at(0, body.neckY + lift - 0.1, 0), rarity >= 5 and GOLD or METAL, torso, metal)
	end
	local cape
	if unit.class == "Lord" or rarity >= 4 then
		cape = part("Cape", Vector3.new(1.65, 1.75, 0.12), at(0, hipY + 0.55, 0.68)
			* CFrame.Angles(math.rad(Config.FEEL.capeAngle), 0, 0), look.outfit.primary, fabric, true)
		cape.CanQuery = false
		motor("CapeJoint", torso, cape, at(0, body.neckY + lift - 0.05, 0.62))
	end
	if rarity >= 4 then
		local weaponPart = model:FindFirstChild("Blade") or model:FindFirstChild("AxeHead") or model:FindFirstChild("Tip")
			or model:FindFirstChild("Bow") or model:FindFirstChild("Tome")
		if weaponPart then
			local light = Instance.new("PointLight")
			light.Color, light.Brightness, light.Range = rarityColor, 1.5, 7
			light.Parent = weaponPart
			sparkles(weaponPart, 4, 0.25, 0.8, 1)
		end
		if cape then
			extra("CapeTrim", Vector3.new(1.7, 0.18, 0.15), cape.CFrame * at(0, -0.8, 0), rarityColor, cape, { Material = Enum.Material.Neon })
		end
	end
	if rarity >= 5 then
		extra("Crest", Vector3.new(0.5, 0.5, 0.1), at(0, body.torsoY + lift + 0.2, -0.64) * CFrame.Angles(0, 0, math.rad(45)), GOLD,
			torso, { Material = Enum.Material.Neon })
		-- Einzelne Segmente lassen die Mitte des Aura-Rings frei.
		for i = 1, 24 do
			local angle = i * math.pi / 12
			extra("AuraRing", Vector3.new(0.64, 0.08, 0.12), at(math.sin(angle) * 2.5, 0.08, math.cos(angle) * 2.5)
				* CFrame.Angles(0, angle, 0), rarityColor, root, { Material = Enum.Material.Neon, Transparency = 0.65, CastShadow = false })
		end
		local emitter = extra("AuraEmitter", Vector3.new(4, 0.1, 4), at(0, 0.1, 0), rarityColor, root, { Transparency = 1, CastShadow = false })
		local e = sparkles(emitter, 8, 0.4, 1.4, 3)
		e.EmissionDirection = Enum.NormalId.Top
	end
	local topY = 0
	for _, p in model:GetChildren() do
		if p:IsA("BasePart") and p.Transparency < 1 then
			local cf, size = p.CFrame, p.Size
			local extent = (math.abs(cf.RightVector.Y) * size.X + math.abs(cf.UpVector.Y) * size.Y + math.abs(cf.LookVector.Y) * size.Z) / 2
			topY = math.max(topY, p.Position.Y + extent)
		end
	end
	model:SetAttribute("HeadY", headY * s)
	model:SetAttribute("TopY", topY)
	return model
end

return ChibiBuilder
