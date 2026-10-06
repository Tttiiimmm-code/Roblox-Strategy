-- R15-Modelle mit Waffen und Seltenheits-Deko; Avatar-Netzaufrufe nur auf dem Server.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Config = require(script.Parent.Config)
local UnitData = require(script.Parent.UnitData)
local ChibiBuilder = require(script.Parent.ChibiBuilder)
local CharacterBuilder = {}
local bases = {}
local templates = {}
local warned = {}
-- Standardlänge eigener Waffenmodelle in Studs (überschreibbar per Attribut "Laenge" am Modell)
local WEAPON_LENGTH = { Sword = 2.8, Axe = 3, Lance = 5, Bow = 3.2, Anima = 1.1 }
local SKIN = Color3.fromRGB(236, 196, 164)
local METAL = Color3.fromRGB(185, 192, 204)
local DARK_METAL = Color3.fromRGB(105, 110, 124)
local WOOD = Color3.fromRGB(112, 76, 46)
local LEATHER = Color3.fromRGB(92, 64, 44)
local GOLD = Color3.fromRGB(232, 188, 74)
local PANTS = Color3.fromRGB(58, 52, 64)
local HORSE = Color3.fromRGB(128, 86, 54)
local HORSE_HAIR = Color3.fromRGB(50, 35, 25)

local function avatar(unit)
	local look = UnitData.Classes[unit.class].look or {}
	local hero = unit.heroId and UnitData.Heroes[unit.heroId]
	local hair = hero and hero.hairAccessory
	local color = Config.TEAM_COLORS[unit.team]
	local key = unit.class .. ":" .. unit.team .. ":" .. tostring(hair)
	if bases[key] then return bases[key]:Clone() end
	local description = Instance.new("HumanoidDescription")
	description.HeadColor = SKIN
	description.TorsoColor = color
	description.LeftArmColor, description.RightArmColor = color, color
	description.LeftLegColor, description.RightLegColor = PANTS, PANTS
	if look.hat then
		if unit.class == "Fighter" or unit.class == "Brigand" then
			description.FaceAccessory = tostring(look.hat)
		else
			description.HatAccessory = tostring(look.hat)
		end
	end
	if hair then description.HairAccessory = tostring(hair) end
	if look.face then description.Face = look.face end
	local ok, result = pcall(function()
		return Players:CreateHumanoidModelFromDescriptionAsync(description, Enum.HumanoidRigType.R15)
	end)
	if not ok then
		warn(("Avatar %s: Accessoires %s/%s konnten nicht geladen werden; versuche ohne Accessoires. %s"):format(unit.class, tostring(look.hat), tostring(hair), tostring(result)))
		description.HatAccessory, description.HairAccessory, description.FaceAccessory = "", "", ""
		ok, result = pcall(function()
			return Players:CreateHumanoidModelFromDescriptionAsync(description, Enum.HumanoidRigType.R15)
		end)
	end
	if not ok or not result or not result:IsA("Model") then
		description:Destroy()
		local message = ("Avatar %s konnte auch ohne Accessoires nicht gebaut werden: %s"):format(unit.class, tostring(result))
		warn(message)
		error(message)
	end
	local expected = (look.hat and 1 or 0) + (hair and 1 or 0)
	local loaded = 0
	for _, child in result:GetChildren() do
		if child:IsA("Accessory") then loaded += 1 end
	end
	if loaded < expected then
		warn(("Avatar %s: Accessoires unvollstaendig; IDs %s / %s in Studio pruefen."):format(unit.class, tostring(look.hat), tostring(hair)))
	end
	description:Destroy()
	result.Archivable = true
	bases[key] = result
	return result:Clone()
end

-- Avatar Auto Setup erzeugt physikbasierte AnimationConstraint-Gelenke; Animator und
-- eigene Posen arbeiten mit Motor6D. Gleichnamige Motor6D an denselben Attachments anlegen.
local function convertJoints(model)
	for _, joint in model:GetDescendants() do
		if joint:IsA("AnimationConstraint") and joint.Attachment0 and joint.Attachment1 then
			local a0, a1 = joint.Attachment0, joint.Attachment1
			local motor = Instance.new("Motor6D")
			motor.Name = joint.Name
			motor.Part0, motor.Part1 = a0.Parent, a1.Parent
			-- Gelenkachsen an den Weltachsen ausrichten (wie Standard-R15): Auto Setup dreht sie
			-- entlang der Gliedmaßen, dann würden unsere Posen den Arm nur um sich selbst drehen.
			local jointFrame = CFrame.new(a0.WorldPosition)
			motor.C0 = a0.Parent.CFrame:ToObjectSpace(jointFrame)
			motor.C1 = a1.Parent.CFrame:ToObjectSpace(jointFrame)
			motor.Parent = a1.Parent
			joint:Destroy()
		end
	end
	for _, d in model:GetDescendants() do
		if d:IsA("BallSocketConstraint") or d:IsA("NoCollisionConstraint") then d:Destroy() end
	end
	-- Bild-zu-3D-Modelle stehen oft in T-Pose; Roblox-Animationen erwarten hängende Arme als Ruhepose.
	-- Nur absenken, wenn die Hand höchstens 30° unter der Schulter liegt (fertige Ruheposen bleiben).
	-- Drehung in C1, damit C0 an den Weltachsen bleibt und Posen den Arm quer zum Körper schwingen.
	local drop = math.rad(Config.FEEL.meshArmDrop)
	for side, sign in { Right = -1, Left = 1 } do
		local motor = model:FindFirstChild(side .. "Shoulder", true)
		local hand, upper = model:FindFirstChild(side .. "Hand"), model:FindFirstChild(side .. "UpperArm")
		if motor and motor:IsA("Motor6D") and hand and upper then
			local arm = hand.Position - upper.Position
			if arm.Magnitude > 0 and -arm.Y < arm.Magnitude * 0.5 then motor.C1 *= CFrame.Angles(0, 0, -sign * drop) end
		end
	end
	-- Teile entlang der Gelenkkette neu setzen, damit Maße (Bodenhöhe, Hand für Waffen) zur Ruhepose passen
	local byChild = {}
	for _, d in model:GetDescendants() do
		if d:IsA("Motor6D") and d.Part0 and d.Part1 then byChild[d.Part1] = d end
	end
	local function place(part, depth)
		local motor = byChild[part]
		if not motor or depth > 20 then return end
		place(motor.Part0, depth + 1)
		part.CFrame = motor.Part0.CFrame * motor.C0 * motor.C1:Inverse()
	end
	for part in byChild do place(part, 0) end
end

local function prepareRig(model, unit, mesh, modelId)
	model.Name = unit.id
	if mesh then
		model:SetAttribute("MeshRig", true)
		-- Automatische Humanoid-Skalierung würde unsere Größenangleichung später überschreiben (Figur sinkt ein)
		local rigHumanoid = model:FindFirstChildOfClass("Humanoid")
		if rigHumanoid then rigHumanoid.AutomaticScalingEnabled = false end
		convertJoints(model)
		-- Importgröße angleichen, damit alle Modelle gleich groß auf dem Brett stehen
		local height = model:GetExtentsSize().Y
		if height > 0 then model:ScaleTo(model:GetScale() * Config.FEEL.meshTargetHeight / height) end
		model:SetAttribute("BaseScale", model:GetScale())
		-- Posen-Speicher von Avatar Setup wird im Spiel nicht gebraucht und bläht jede Kopie auf
		local poses = model:FindFirstChild("InitialPoses")
		if poses then poses:Destroy() end
	end
	local root = model:FindFirstChild("HumanoidRootPart")
	model.PrimaryPart = root
	-- Drehpunkt in die Hüfte: importierte Modelle haben ihn oft an den Füßen, der Server setzt beim Laufen aber die Wurzel
	if root then root.PivotOffset = CFrame.new() end
	model:PivotTo(CFrame.new())
	local humanoid = model:FindFirstChildOfClass("Humanoid")
	humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
	humanoid.HealthDisplayType = Enum.HumanoidHealthDisplayType.AlwaysOff
	humanoid.EvaluateStateMachine = false
	local animator = humanoid:FindFirstChildOfClass("Animator") or Instance.new("Animator")
	animator.Parent = humanoid
	for _, d in model:GetDescendants() do
		if d:IsA("BasePart") then
			d.Anchored = d == root
			d.CanCollide, d.CanTouch, d.Massless = false, false, true
			if mesh then
				d:SetAttribute("Tint", nil)
			elseif d ~= root and not d:FindFirstAncestorOfClass("Accessory") then
				d:SetAttribute("Tint", d.Name ~= "Head" and not string.find(d.Name, "Leg") and not string.find(d.Name, "Foot") and not string.find(d.Name, "Hand"))
			end
		elseif d:IsA("LuaSourceContainer") then d:Destroy() end
	end
	local mounted = unit.class == "Cavalier"
	local low = math.min(model.LeftFoot.Position.Y - model.LeftFoot.Size.Y / 2, model.RightFoot.Position.Y - model.RightFoot.Size.Y / 2)
	local groundOffset = -low + (mounted and Config.FEEL.riderLift or 0)
	model:SetAttribute("GroundOffset", groundOffset)
	model:SetAttribute("Mounted", mounted)
	local torso, lower = model.UpperTorso, model.LowerTorso
	local head = model.Head
	local rArm, lArm = model.RightHand, model.LeftHand
	if not mesh then rArm.Color, lArm.Color = SKIN, SKIN end
	local weapon = UnitData.Weapons[unit.weapon]
	local s = 1
	local look = { cape = unit.class == "Lord" }
	local function at(x, y, z) return CFrame.new(x, y, z) end
	local function part(name, size, cf, color, props)
		local p = Instance.new("Part")
		p.Name, p.Size, p.CFrame = name, size, cf
		p.CanCollide, p.CanQuery, p.CanTouch, p.Massless = false, false, false, true
		p.Color = color == "team" and Config.TEAM_COLORS[unit.team] or color
		if color == "team" then p:SetAttribute("Tint", true) end
		p.Material = Enum.Material.SmoothPlastic
		for k, v in props or {} do p[k] = v end
		p.Parent = model
		return p
	end
	local function weld(p0, p1)
		local w = Instance.new("WeldConstraint")
		w.Part0, w.Part1, w.Parent = p0, p1, p1
	end
	local function extra(name, size, cf, color, attachTo, props)
		local p = part(name, size, cf, color, props)
		weld(attachTo, p)
		return p
	end
	local function makeCape(size, cf, color)
		local cape = part("Cape", size, cf, color, { Material = Enum.Material.Fabric })
		local joint = Instance.new("Motor6D")
		joint.Name, joint.Part0, joint.Part1 = "CapeJoint", torso, cape
		local pivot = torso.CFrame * CFrame.new(0, torso.Size.Y / 2, torso.Size.Z / 2)
		joint.C0, joint.C1 = torso.CFrame:ToObjectSpace(pivot), cape.CFrame:ToObjectSpace(pivot)
		joint.Parent = torso
		return cape
	end
	-- Importierte Kleidung und Texturen bleiben sichtbar.
	if not mesh then
		extra("Surcoat", torso.Size + Vector3.new(0.1, 0.05, 0.12), torso.CFrame, "team", torso, { Material = Enum.Material.Fabric })
	end
	if look.cape and not mesh then
		makeCape(Vector3.new(1.9, 2.4, 0.15), torso.CFrame * CFrame.new(0, -0.6, torso.Size.Z / 2 + 0.2) * CFrame.Angles(math.rad(Config.FEEL.capeAngle), 0, 0), "team")
	end
	if mounted then
		for _, name in { "RightHip", "LeftHip" } do
			local joint = model:FindFirstChild(name, true)
			if joint then joint.C0 *= CFrame.Angles(-math.pi / 2, 0, 0) end
		end
		local horse = {
			part("HorseBody", Vector3.new(2, 2, 4.2), at(0, 3.1 - groundOffset, 0.2), HORSE),
			part("HorseNeck", Vector3.new(0.9, 2.2, 1), at(0, 4.4 - groundOffset, -1.9) * CFrame.Angles(math.rad(-35), 0, 0), HORSE),
			part("HorseHead", Vector3.new(0.85, 0.85, 1.7), at(0, 5.4 - groundOffset, -2.75), HORSE),
			part("HorseMane", Vector3.new(0.3, 1.9, 0.5), at(0, 4.7 - groundOffset, -1.55), HORSE_HAIR),
			part("HorseTail", Vector3.new(0.35, 1.6, 0.35), at(0, 3.3 - groundOffset, 2.5), HORSE_HAIR),
			part("Saddle", Vector3.new(2.1, 0.3, 1.6), at(0, 4.15 - groundOffset, 0.2), "team"),
		}
		for _, x in { -0.65, 0.65 } do
			for _, z in { -1.5, 1.8 } do table.insert(horse, part("HorseLeg", Vector3.new(0.55, 2.1, 0.55), at(x, 1.05 - groundOffset, z), HORSE)) end
		end
		for _, p in horse do weld(root, p) end
	end
	-- Waffe: in Ruhepose nach vorne (-Z) aus der Hand -------------------------
	local metal = { Material = Enum.Material.Metal }
	local hx, hY = rArm.Position.X, rArm.Position.Y
	local function weaponAt(x, y, z)
		if mesh then return rArm.CFrame * CFrame.new(x - hx, y - hY, z) end
		return at(x, y, z)
	end
	local t = weapon.type
	-- Eigene Waffe der Figur (CharacterModels.<id>_waffe): Pivot = Griff, -Z = Klingenrichtung
	local own = modelId and ReplicatedStorage.CharacterModels:FindFirstChild(modelId .. "_waffe")
	if own and own:IsA("Model") then
		local w = own:Clone()
		w.Name = "Waffe"
		local length = w:GetAttribute("Laenge") or WEAPON_LENGTH[t] or 2.8
		local size = w:GetExtentsSize()
		w:ScaleTo(w:GetScale() * length / math.max(size.X, size.Y, size.Z))
		local hand = t == "Bow" and lArm or rArm
		w:PivotTo(hand.CFrame)
		for _, p in w:GetDescendants() do
			if p:IsA("BasePart") then
				p.Anchored, p.CanCollide, p.CanQuery, p.CanTouch, p.Massless = false, false, false, false, true
				weld(hand, p)
			end
		end
		w.Parent = model
	elseif t == "Sword" then
		extra("Grip", Vector3.new(0.2, 0.2, 0.6), weaponAt(hx, hY, 0), LEATHER, rArm)
		extra("Guard", Vector3.new(0.9, 0.18, 0.2), weaponAt(hx, hY, -0.35), unit.isLord and GOLD or DARK_METAL, rArm, metal)
		extra("Blade", Vector3.new(0.14, 0.32, 2.6), weaponAt(hx, hY, -1.75), METAL, rArm, metal)
	elseif t == "Axe" then
		local big = weapon.might >= 10
		extra("Haft", Vector3.new(0.2, 0.2, big and 2.8 or 2.4), weaponAt(hx, hY, big and -1.0 or -0.8), WOOD, rArm)
		extra("AxeHead", Vector3.new(0.15, big and 1.3 or 1.0, big and 1.0 or 0.8), weaponAt(hx, hY + 0.45, big and -2.1 or -1.7),
			big and DARK_METAL or METAL, rArm, metal)
	elseif t == "Lance" then
		local len = unit.weapon == "Javelin" and 3.4 or 5
		extra("Shaft", Vector3.new(0.18, 0.18, len), weaponAt(hx, hY, -len / 2 + 0.8), WOOD, rArm)
		extra("Tip", Vector3.new(0.3, 0.3, 0.8), weaponAt(hx, hY, -len + 0.4) * CFrame.Angles(0, 0, math.rad(45)), METAL, rArm, metal)
	elseif t == "Bow" then
		-- liegt waagerecht in der linken Hand; beim Anheben des Arms steht er senkrecht
		extra("Bow", Vector3.new(0.15, 0.25, 3.2), lArm.CFrame * CFrame.new(0, 0, -0.3), WOOD, lArm)
		extra("String", Vector3.new(0.05, 0.05, 3.0), lArm.CFrame * CFrame.new(0, 0.35, -0.3), Color3.fromRGB(240, 240, 230), lArm)
	elseif t == "Anima" then
		extra("Tome", Vector3.new(0.25, 1.1, 0.9), lArm.CFrame * CFrame.new(0, -0.1, -0.35), Color3.fromRGB(180, 40, 30), lArm)
		extra("Pages", Vector3.new(0.3, 0.95, 0.8), lArm.CFrame * CFrame.new(0, -0.1, -0.33), Color3.fromRGB(245, 240, 225), lArm)
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

	if rarity >= 2 and not mesh then -- Ungewöhnlich: farbige Gürtelschnalle
		extra("Buckle", Vector3.new(0.5, 0.35, 0.1), lower.CFrame * CFrame.new(0, 0, -lower.Size.Z / 2 - 0.1), rarityColor, lower,
			{ Material = Enum.Material.Neon })
	end
	if rarity >= 3 and not mesh then -- Selten: Kragen-Verzierung
		extra("Collar", Vector3.new(2.1, 0.25, 1.1), torso.CFrame * CFrame.new(0, torso.Size.Y / 2, 0), rarity >= 5 and GOLD or METAL, torso,
			{ Material = Enum.Material.Metal })
	end
	if rarity >= 4 then -- Episch: leuchtende Waffe mit Funken, Umhang mit Saum
		local own = model:FindFirstChild("Waffe")
		local weaponPart = own and own:FindFirstChildWhichIsA("BasePart", true) or model:FindFirstChild("Blade") or model:FindFirstChild("AxeHead") or model:FindFirstChild("Tip")
			or model:FindFirstChild("Bow") or model:FindFirstChild("Tome")
		if weaponPart then
			local light = Instance.new("PointLight")
			light.Color = rarityColor
			light.Brightness = 1.5
			light.Range = 7
			light.Parent = weaponPart
			sparkles(weaponPart, 4, 0.25 * s, 0.8, 1)
		end
		if not mesh and not look.cape and not mounted then
			makeCape(Vector3.new(1.9, 2.4, 0.15), torso.CFrame * CFrame.new(0, -0.6, torso.Size.Z / 2 + 0.2) * CFrame.Angles(math.rad(Config.FEEL.capeAngle), 0, 0), "team")
		end
		local cape = model:FindFirstChild("Cape")
		if cape then
			extra("CapeTrim", Vector3.new(1.95, 0.25, 0.18), cape.CFrame * CFrame.new(0, -cape.Size.Y / 2, 0), rarityColor, cape, { Material = Enum.Material.Neon })
		end
	end
	if rarity >= 5 then -- Legendär: goldenes Wappen und Aura am Boden
		-- Mesh-Designs haben eigene Ornamente; dort nur Partikel-Aura, kein Wappen/keine Bodenscheibe
		if not mesh then
			extra("Crest", Vector3.new(0.7, 0.7, 0.1), torso.CFrame * CFrame.new(0, 0, -torso.Size.Z / 2 - 0.12) * CFrame.Angles(0, 0, math.rad(45)), GOLD,
				torso, { Material = Enum.Material.Neon })
			extra("AuraRing", Vector3.new(0.1, 5.5, 5.5), at(0, -groundOffset + 0.08, 0) * CFrame.Angles(0, 0, math.rad(90)), rarityColor, root,
				{ Material = Enum.Material.Neon, Shape = Enum.PartType.Cylinder, Transparency = 0.65, CastShadow = false })
		end
		local emitter = extra("AuraEmitter", Vector3.new(4, 0.1, 4), at(0, -groundOffset + 0.1, 0), rarityColor, root,
			{ Transparency = 1, CastShadow = false })
		local e = sparkles(emitter, 8, 0.4, 1.4, 3)
		e.EmissionDirection = Enum.NormalId.Top
	end

	model:SetAttribute("HeadY", head.Position.Y)
	local topY = head.Position.Y + head.Size.Y / 2
	if mesh then
		for _, p in model:GetDescendants() do
			if p:IsA("BasePart") and p.Transparency < 1 then
				local cf, size = p.CFrame, p.Size
				local extent = (math.abs(cf.RightVector.Y) * size.X + math.abs(cf.UpVector.Y) * size.Y + math.abs(cf.LookVector.Y) * size.Z) / 2
				topY = math.max(topY, p.Position.Y + extent)
			end
		end
	end
	model:SetAttribute("TopY", topY)
	return model
end

local function warnOnce(id, reason)
	if warned[id] then return end
	warned[id] = true
	warn(("Figurenmodell %s: %s; verwende Chibi."):format(id, reason))
end

local function meshModel(unit)
	local folder = ReplicatedStorage:FindFirstChild("CharacterModels")
	local source = folder and unit.heroId and folder:FindFirstChild(unit.heroId)
	if not source or not source:IsA("Model") then
		source = folder and folder:FindFirstChild(unit.class)
	end
	local id = source and source:IsA("Model") and source.Name or unit.heroId or unit.class
	if not source or not source:IsA("Model") then
		warnOnce(id, "kein Modell vorhanden")
		return ChibiBuilder.build(unit)
	end
	local key = table.concat({ id, unit.class, unit.team, unit.weapon,
		tostring(unit.rarity or 1), tostring(unit.isLord == true) }, "|")
	local template = templates[key]
	if not template then
		for _, name in { "HumanoidRootPart", "Humanoid", "Head", "UpperTorso", "LowerTorso", "RightHand", "LeftHand", "LeftFoot", "RightFoot" } do
			local child = source:FindFirstChild(name)
			if not child or not child:IsA(name == "Humanoid" and "Humanoid" or "BasePart") then
				warnOnce(id, "Pflichtteil fehlt oder hat falschen Typ: " .. name)
				return ChibiBuilder.build(unit)
			end
		end
		local model = source:Clone()
		if not model then
			warnOnce(id, "Vorlage ist nicht klonbar (Archivable)")
			return ChibiBuilder.build(unit)
		end
		template = prepareRig(model, unit, true, id)
		templates[key] = template
	end
	local model = template:Clone()
	model.Name = unit.id
	return model
end

function CharacterBuilder.build(unit)
	if Config.CHARACTER_STYLE == "chibi" then return ChibiBuilder.build(unit) end
	if Config.CHARACTER_STYLE == "mesh" then return meshModel(unit) end
	assert(RunService:IsServer(), "Avatar-Vorlagen werden nur auf dem Server gebaut")
	return prepareRig(avatar(unit), unit, false)
end
return CharacterBuilder
