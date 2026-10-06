-- Client-Animationen: Wippen im Stand, Laufen, Angriffe je Waffentyp, Treffer-/Ausweich-Reaktionen
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local UnitData = require(Shared:WaitForChild("UnitData"))

local Animator = {}

local unitsFolder, fxFolder
local MOTOR_NAMES = { "RootJoint", "Neck", "RightShoulder", "LeftShoulder", "RightHip", "LeftHip", "CapeJoint" }
local motorCache = setmetatable({}, { __mode = "k" })
local baseC0 = setmetatable({}, { __mode = "k" })
local busy = setmetatable({}, { __mode = "k" }) -- Modelle in einer Kampfanimation
local life = setmetatable({}, { __mode = "k" })
local random = Random.new()
local selected, selectedAt, selectionRing

-- Alle Zeiten laufen über diese Helfer, damit das Tempo (1×/2×) überall wirkt
local speed = 1

local function info(t, ...)
	return TweenInfo.new(t / speed, ...)
end

local function pause(t)
	task.wait(t / speed)
end

local function later(t, fn)
	task.delay(t / speed, fn)
end

function Animator.setSpeed(s)
	speed = s
end

local function motors(model)
	local m = motorCache[model]
	if m then
		return m
	end
	m = {}
	for _, name in MOTOR_NAMES do
		local motor = model:FindFirstChild(name == "RootJoint" and "Root" or name, true)
		if motor and not motor:IsA("Motor6D") then motor = nil end
		if motor then
			m[name] = motor
			baseC0[motor] = motor.C0
		end
	end
	if m.RootJoint then -- erst cachen, wenn das Modell vollständig repliziert ist
		motorCache[model] = m
	end
	return m
end

local function pose(motor, cf)
	if motor then
		motor.C0 = baseC0[motor] * cf
	end
end

local function tweenPose(motor, cf, time, style)
	if motor then
		local tweenInfo = info(time, style or Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
		TweenService:Create(motor, tweenInfo, { C0 = baseC0[motor] * cf }):Play()
	end
end

local function tweenRoot(root, cf, time, style)
	local tweenInfo = info(time, style or Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	TweenService:Create(root, tweenInfo, { CFrame = cf }):Play()
end

local rad = math.rad

-- Waagerechte Richtung von Modell a zu Modell b
local function towards(a, b)
	local ra = a.PrimaryPart
	local rb = b and b.PrimaryPart
	if rb then
		local d = (rb.Position - ra.Position) * Vector3.new(1, 0, 1)
		if d.Magnitude > 0.01 then
			return d.Unit
		end
	end
	return ra.CFrame.LookVector
end

local function chest(model)
	local torso = model and model:FindFirstChild("UpperTorso")
	return torso and torso.Position
end

local function hand(model, side)
	local arm = model:FindFirstChild(side .. "Hand")
	return arm and (arm.CFrame * CFrame.new(0, -arm.Size.Y / 2, 0)).Position or chest(model)
end

local function flash(model, color)
	local h = Instance.new("Highlight")
	h.Adornee = model
	h.FillColor = color
	h.FillTransparency = 0.15
	h.OutlineColor = Color3.new(1, 1, 1)
	h.OutlineTransparency = 0.2
	h.Parent = fxFolder
	TweenService:Create(h, info(0.35), { FillTransparency = 1, OutlineTransparency = 1 }):Play()
	Debris:AddItem(h, 0.4)
end

local function fxPart(props)
	local p = Instance.new("Part")
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.CastShadow = false
	for k, v in props do
		p[k] = v
	end
	p.Parent = fxFolder
	return p
end

local function explosion(pos, color)
	local ball = fxPart({
		Shape = Enum.PartType.Ball, Size = Vector3.one, Position = pos,
		Material = Enum.Material.Neon, Color = color, Transparency = 0.1,
	})
	local light = Instance.new("PointLight")
	light.Color = color
	light.Brightness = 4
	light.Range = 14
	light.Parent = ball
	TweenService:Create(ball, info(0.35), { Size = Vector3.one * 6, Transparency = 1 }):Play()
	TweenService:Create(light, info(0.35), { Brightness = 0 }):Play()
	Debris:AddItem(ball, 0.4)
end

-- Ruhepose zurück
local function recover(model, root, origin, time)
	local m = motors(model)
	for _, name in MOTOR_NAMES do
		tweenPose(m[name], CFrame.identity, time)
	end
	tweenRoot(root, origin, time)
end

-- Angriffsstile: der Treffer liegt jeweils bei Config.IMPACT_TIME (0.4 s) ---------
local function melee(windAngle, hitAngle, reach)
	return function(a, b, strike)
		local m = motors(a)
		local root = a.PrimaryPart
		local origin = root.CFrame
		local dir = towards(a, b)
		local lift = strike.crit and Vector3.new(0, 1.6, 0) or Vector3.zero
		if strike.crit then
			flash(a, Color3.fromRGB(255, 220, 120))
		end

		-- Ausholen
		tweenPose(m.RightShoulder, CFrame.Angles(rad(windAngle), 0, 0), 0.22)
		tweenPose(m.LeftShoulder, CFrame.Angles(rad(-20), 0, 0), 0.22)
		tweenPose(m.RootJoint, CFrame.Angles(rad(10), 0, 0), 0.22)
		tweenRoot(root, origin - dir * 0.5 + lift, 0.22)
		pause(0.22)

		-- Zuschlagen
		tweenPose(m.RightShoulder, CFrame.Angles(rad(hitAngle), 0, 0), 0.14, Enum.EasingStyle.Quart)
		tweenPose(m.RootJoint, CFrame.Angles(rad(-15), 0, 0), 0.14)
		tweenRoot(root, origin + dir * reach, 0.14, Enum.EasingStyle.Quart)
		pause(0.36)

		recover(a, root, origin, 0.22)
	end
end

local function thrust(a, b, strike)
	local m = motors(a)
	local root = a.PrimaryPart
	local origin = root.CFrame
	local dir = towards(a, b)
	if strike.crit then
		flash(a, Color3.fromRGB(255, 220, 120))
	end

	tweenPose(m.RightShoulder, CFrame.Angles(rad(70), 0, 0), 0.22)
	tweenPose(m.RootJoint, CFrame.Angles(rad(8), 0, 0), 0.22)
	tweenRoot(root, origin - dir * 0.8, 0.22)
	pause(0.24)

	tweenPose(m.RightShoulder, CFrame.Angles(rad(95), 0, 0), 0.12, Enum.EasingStyle.Quart)
	tweenPose(m.RootJoint, CFrame.Angles(rad(-12), 0, 0), 0.12)
	tweenRoot(root, origin + dir * (strike.crit and 3.2 or 2.6), 0.12, Enum.EasingStyle.Quart)
	pause(0.34)

	recover(a, root, origin, 0.22)
end

local function shootArrow(a, b, strike)
	local m = motors(a)
	local root = a.PrimaryPart
	local origin = root.CFrame
	local dir = towards(a, b)

	-- Bogen heben und Sehne spannen
	tweenPose(m.LeftShoulder, CFrame.Angles(rad(90), 0, 0), 0.18)
	tweenPose(m.RightShoulder, CFrame.Angles(rad(95), rad(-25), 0), 0.18)
	tweenPose(m.RootJoint, CFrame.Angles(0, rad(-15), 0), 0.18)
	tweenRoot(root, origin - dir * 0.3, 0.18)
	pause(0.22)

	local from = hand(a, "Left")
	local to = chest(b) or from + dir * 10
	local arrow = fxPart({
		Size = Vector3.new(0.12, 0.12, 1.8), Color = Color3.fromRGB(112, 76, 46),
		Material = Enum.Material.Wood, CFrame = CFrame.lookAt(from, to),
	})
	if strike.crit then
		arrow.Material = Enum.Material.Neon
		arrow.Color = Color3.fromRGB(255, 200, 90)
	end
	TweenService:Create(arrow, info(0.18, Enum.EasingStyle.Linear), {
		CFrame = CFrame.lookAt(to, to + (to - from)),
	}):Play()
	Debris:AddItem(arrow, 0.2)
	tweenPose(m.RightShoulder, CFrame.Angles(rad(70), rad(-45), 0), 0.08)
	pause(0.36)

	recover(a, root, origin, 0.22)
end

local function castFire(a, b, strike)
	local m = motors(a)
	local root = a.PrimaryPart
	local origin = root.CFrame
	local dir = towards(a, b)

	-- Arme heben, Feuer sammeln
	tweenPose(m.RightShoulder, CFrame.Angles(rad(160), 0, rad(-10)), 0.2)
	tweenPose(m.LeftShoulder, CFrame.Angles(rad(160), 0, rad(10)), 0.2)
	tweenPose(m.RootJoint, CFrame.Angles(rad(8), 0, 0), 0.2)
	local spawnPos = chest(a) + Vector3.new(0, 3, 0) + dir * 0.5
	local fire = fxPart({
		Shape = Enum.PartType.Ball, Size = Vector3.one * 0.3, Position = spawnPos,
		Material = Enum.Material.Neon, Color = Color3.fromRGB(255, 120, 40),
	})
	local light = Instance.new("PointLight")
	light.Color = fire.Color
	light.Brightness = 3
	light.Range = 10
	light.Parent = fire
	TweenService:Create(fire, info(0.2), { Size = Vector3.one * (strike.crit and 1.8 or 1.2) }):Play()
	pause(0.2)

	-- Werfen
	tweenPose(m.RightShoulder, CFrame.Angles(rad(100), 0, 0), 0.1)
	tweenPose(m.LeftShoulder, CFrame.Angles(rad(100), 0, 0), 0.1)
	tweenPose(m.RootJoint, CFrame.Angles(rad(-10), 0, 0), 0.1)
	local to = chest(b) or spawnPos + dir * 10
	TweenService:Create(fire, info(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { Position = to }):Play()
	pause(0.2)
	fire:Destroy()
	explosion(to, strike.crit and Color3.fromRGB(255, 220, 90) or Color3.fromRGB(255, 110, 40))
	pause(0.18)

	recover(a, root, origin, 0.22)
end

local STYLES = {
	Sword = melee(160, 35, 2.0),
	Axe = melee(170, 30, 1.8),
	Lance = thrust,
	Bow = shootArrow,
	Anima = castFire,
}

-- Reaktion des Ziels im Moment des Treffers
local function react(target, attacker, strike)
	local root = target.PrimaryPart
	if not root then
		return
	end
	local m = motors(target)
	local origin = root.CFrame
	local dir = attacker and towards(attacker, target) or -origin.LookVector
	busy[target] = true

	if not strike.hit then
		local sign = math.random() < 0.5 and -1 or 1
		tweenRoot(root, origin + origin.RightVector * sign * 1.6, 0.12)
		tweenPose(m.RootJoint, CFrame.Angles(0, 0, rad(-12 * sign)), 0.12)
		later(0.2, function()
			recover(target, root, origin, 0.2)
		end)
	else
		local color = strike.crit and Color3.fromRGB(255, 150, 40)
			or (strike.damage > 0 and Color3.fromRGB(255, 60, 60) or Color3.fromRGB(180, 180, 200))
		flash(target, color)
		local push = strike.crit and 1.5 or (strike.damage > 0 and 0.7 or 0.2)
		tweenRoot(root, origin + dir * push, 0.08)
		tweenPose(m.RootJoint, CFrame.Angles(rad(strike.crit and 25 or 15), 0, 0), 0.08)
		tweenPose(m.Neck, CFrame.Angles(rad(15), 0, 0), 0.08)
		later(0.12, function()
			recover(target, root, origin, 0.25)
		end)
	end

	later(0.42, function()
		busy[target] = nil
	end)
end

-- Öffentliche API ---------------------------------------------------------------
function Animator.playStrike(strike, weaponKey, onImpact)
	local a = unitsFolder:FindFirstChild(strike.attackerId)
	local b = unitsFolder:FindFirstChild(strike.targetId)

	later(Config.IMPACT_TIME, function()
		onImpact()
		if b and b.Parent then
			later(strike.hit and Config.FEEL.hitStop or 0, function()
				if b.Parent then react(b, a, strike) end
			end)
		end
	end)

	if not a or not a.PrimaryPart then
		return
	end
	local weapon = UnitData.Weapons[weaponKey]
	local style = STYLES[weapon and weapon.type] or STYLES.Sword
	busy[a] = true
	task.spawn(style, a, b, strike)
	later(Config.STRIKE_TIME, function()
		busy[a] = nil
	end)
end

function Animator.select(id)
	if selectionRing then selectionRing:Destroy(); selectionRing = nil end
	selected = id and unitsFolder:FindFirstChild(id)
	selectedAt = os.clock()
	if not selected then return end
	selectionRing = Instance.new("Model")
	selectionRing.Name = "SelectionRing"
	for i = 1, Config.FEEL.selectionRingSegments do
		local angle = i / Config.FEEL.selectionRingSegments * math.pi * 2
		local radius = Config.FEEL.selectionRingRadius
		local segment = fxPart({ Size = Vector3.new(0.12, 0.12, radius * math.pi * 2 / Config.FEEL.selectionRingSegments), Color = Config.OVERLAY.Cursor, Material = Enum.Material.Neon, Transparency = Config.FEEL.selectionRingTransparency })
		segment.CFrame = CFrame.new(math.cos(angle) * radius, 0.13, math.sin(angle) * radius) * CFrame.Angles(0, -angle, 0)
		segment.Parent = selectionRing
	end
	selectionRing.WorldPivot = CFrame.new()
	selectionRing.Parent = fxFolder
end

local function livingState(model, t)
	local data = life[model]
	if not data then
		data = { phase = random:NextNumber(0, math.pi * 2), nextGesture = t + random:NextNumber(Config.FEEL.idleGestureMin, Config.FEEL.idleGestureMax), gesture = 0, dustAt = 0, cape = 0 }
		life[model] = data
	end
	return data
end

local function standardAnimation(model, data)
	if not data.animationAttempted then
		local humanoid = model:FindFirstChildOfClass("Humanoid")
		local animator = humanoid and humanoid:FindFirstChildOfClass("Animator")
		if not animator then return end
		data.animationAttempted = true
		data.tracks = {}
		for name, id in { idle = Config.FEEL.avatarIdle, walk = Config.FEEL.avatarWalk } do
			local animation = Instance.new("Animation")
			animation.AnimationId = id
			local ok, track = pcall(function() return animator:LoadAnimation(animation) end)
			animation:Destroy()
			if ok then
				track.Looped = true
				track.Priority = name == "walk" and Enum.AnimationPriority.Movement or Enum.AnimationPriority.Idle
				data.tracks[name] = track
			else warn("Avatar-Animation konnte nicht geladen werden: " .. id) end
		end
		model.Destroying:Once(function()
			for _, track in data.tracks do track:Stop(0); track:Destroy() end
		end)
	end
	local name = model:GetAttribute("Moving") and not model:GetAttribute("Mounted") and "walk" or "idle"
	if data.trackName ~= name then
		for key, track in data.tracks do
			if key == name then track:Play(Config.FEEL.avatarAnimationFade / speed) else track:Stop(Config.FEEL.avatarAnimationFade / speed) end
		end
		data.trackName = name
	end
	local track = data.tracks[name]
	if track then track:AdjustSpeed(name == "walk" and speed or 1) end
end

local function dust(model, data, t)
	local root = model.PrimaryPart
	if not root or t < data.dustAt then return end
	data.dustAt = t + Config.FEEL.stepDustInterval / speed
	if not data.emitter then
		local attachment = Instance.new("Attachment")
		attachment.Position = Vector3.new(0, -(model:GetAttribute("GroundOffset") or 0), 0)
		attachment.Parent = root
		local emitter = Instance.new("ParticleEmitter")
		emitter.Texture = "rbxasset://textures/particles/smoke_main.dds"
		emitter.Color = ColorSequence.new(Color3.fromRGB(193, 176, 144))
		emitter.Rate = 0
		emitter.SpreadAngle = Vector2.new(65, 65)
		emitter.Size = NumberSequence.new(Config.FEEL.stepDustSize, 0)
		emitter.Transparency = NumberSequence.new(0.6, 1)
		emitter.Parent = attachment
		data.emitter = emitter
	end
	data.emitter.Lifetime = NumberRange.new(Config.FEEL.stepDustLifetime / speed)
	data.emitter.Speed = NumberRange.new(Config.FEEL.stepDustSpeed * speed)
	data.emitter:Emit(Config.FEEL.stepDustCount)
end

-- Zug-Ring: blau (eigene) bzw. rot (Gegner), pulsiert, verschwindet nach dem Zug
local function turnRing(model, data, t)
	if not data.turnRing then
		local ring = Instance.new("Model")
		ring.Name = "TurnRing"
		local color = Config.TEAM_COLORS[model:GetAttribute("Team") or "Player"]
		local segments, radius = Config.FEEL.selectionRingSegments, Config.FEEL.turnRingRadius
		for i = 1, segments do
			local angle = i / segments * math.pi * 2
			local segment = fxPart({ Size = Vector3.new(0.1, 0.1, radius * math.pi * 2 / segments), Color = color, Material = Enum.Material.Neon })
			segment.CFrame = CFrame.new(math.cos(angle) * radius, 0.1, math.sin(angle) * radius) * CFrame.Angles(0, -angle, 0)
			segment.Parent = ring
		end
		ring.WorldPivot = CFrame.new()
		ring.Parent = fxFolder
		data.turnRing, data.turnSegments = ring, ring:GetChildren()
		model.Destroying:Once(function() ring:Destroy() end)
	end
	local root = model.PrimaryPart
	local hidden = model:GetAttribute("Done") or not root or not model.Parent or model.Name ~= model:GetAttribute("UnitId") -- gefallen
	-- Versteckte Ringe nur beim Wechsel anfassen; sichtbare pulsieren und folgen der Figur
	if hidden and data.turnHidden then return end
	data.turnHidden = hidden
	local alpha = hidden and 1 or Config.FEEL.turnRingTransparency + Config.FEEL.turnRingPulse * (0.5 + 0.5 * math.sin(t * Config.FEEL.turnRingPulseRate))
	for _, segment in data.turnSegments do segment.Transparency = alpha end
	if not hidden then
		local pivot = CFrame.new(root.Position - Vector3.new(0, model:GetAttribute("GroundOffset") or 0, 0))
		if data.turnPivot ~= pivot then
			data.turnPivot = pivot
			data.turnRing:PivotTo(pivot)
		end
	end
end

local function idle(dt)
	local t = os.clock()
	if selected and selected.Parent and selectionRing then
		local root = selected.PrimaryPart
		if root then selectionRing:PivotTo(CFrame.new(root.Position - Vector3.new(0, selected:GetAttribute("GroundOffset") or 0, 0))) end
	elseif selectionRing then
		Animator.select(nil)
	end
	local models = unitsFolder:GetChildren()
	local hall = workspace:FindFirstChild("Hub")
	if hall then
		for _, model in hall:GetChildren() do
			if model:IsA("Model") and model.PrimaryPart then table.insert(models, model) end
		end
	end
	for _, model in models do
		local data = livingState(model, t)
		if model:GetAttribute("UnitId") then turnRing(model, data, t) end
		standardAnimation(model, data)
		if not busy[model] then
			local m = motors(model)
			if m.RootJoint then
				local jump = 0
				if model == selected then
					local alpha = (t - selectedAt) * speed / Config.FEEL.selectionJumpDuration
					if alpha < 1 then jump = math.sin(alpha * math.pi) * Config.FEEL.selectionJumpHeight end
				end
				local moving = model:GetAttribute("Moving")
				local capeTarget = moving and Config.FEEL.capeMovingAngle or Config.FEEL.capeIdleAngle * math.sin(t * Config.FEEL.breathRate + data.phase)
				data.cape += (capeTarget - data.cape) * (1 - math.exp(-dt * Config.FEEL.capeSmoothness * speed))
				pose(m.CapeJoint, CFrame.Angles(-data.cape, 0, 0))
				if model:GetAttribute("Moving") then
					dust(model, data, t)
					local w = math.sin(t * 14 * speed)
					pose(m.RootJoint, CFrame.new(0, math.abs(w) * 0.2 + jump, 0))
					pose(m.RightShoulder, CFrame.Angles(w * 0.6, 0, 0))
					pose(m.LeftShoulder, CFrame.Angles(-w * 0.6, 0, 0))
					pose(m.RightHip, CFrame.Angles(-w * 0.7, 0, 0))
					pose(m.LeftHip, CFrame.Angles(w * 0.7, 0, 0))
					pose(m.Neck, CFrame.identity)
				else
					if t >= data.nextGesture then
						data.gesture = t
						data.kind = random:NextInteger(1, 2)
						data.nextGesture = t + random:NextNumber(Config.FEEL.idleGestureMin, Config.FEEL.idleGestureMax)
					end
					local alpha = math.clamp((t - data.gesture) * speed / Config.FEEL.idleGestureDuration, 0, 1)
					local gesture = math.sin(alpha * math.pi) * Config.FEEL.idleGestureAngle
					local phase = data.phase
					local b = math.sin(t * Config.FEEL.breathRate + phase)
					pose(m.RootJoint, CFrame.new(0, b * Config.FEEL.breathHeight + jump, 0))
					pose(m.RightShoulder, CFrame.Angles(b * 0.05 - (data.kind == 2 and gesture or 0), 0, 0))
					pose(m.LeftShoulder, CFrame.Angles(-b * 0.05, 0, 0))
					pose(m.RightHip, CFrame.identity)
					pose(m.LeftHip, CFrame.identity)
					pose(m.Neck, CFrame.Angles(0, math.sin(t * 0.7 + phase) * 0.12 + (data.kind == 1 and gesture or 0), 0))
				end
			end
		end
	end
end

function Animator.init(units, fx)
	unitsFolder = units
	fxFolder = fx
	RunService.RenderStepped:Connect(idle)
end

return Animator
