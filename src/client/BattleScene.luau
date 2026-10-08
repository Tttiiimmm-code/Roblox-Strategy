-- Eigene Kampfkulisse; alle Modelle und Animationen gehören nur dieser Darstellung.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Stages = require(Shared:WaitForChild("Stages"))
local UnitData = require(Shared:WaitForChild("UnitData"))
local UnitShadow = require(Shared:WaitForChild("UnitShadow"))
local UIKit = require(script.Parent:WaitForChild("UIKit"))
local UnitAnimator = require(script.Parent:WaitForChild("UnitAnimator"))
local SoundPlayer = require(script.Parent:WaitForChild("SoundPlayer"))
local UI = require(script.Parent:WaitForChild("UI"))

local BattleScene = {}
local active
local make, label = UIKit.make, UIKit.label
local THEME = UIKit.THEME

function BattleScene.isPlaying()
	return active ~= nil
end

function BattleScene.stop()
	if active then active.finish() end
end

local function coloredPanel(parent, position, size, color)
	local panel = UIKit.panel({ Position = position, Size = size }, parent)
	panel.Background.UIGradient.Color = ColorSequence.new(color:Lerp(THEME.bottom, 0.35), THEME.bottom)
	return panel
end

local function buildSide(parent, side, x, color)
	local unit, forecast = side.unit, side.forecast
	local panel = coloredPanel(parent, UDim2.new(x, 4, 1, -174), UDim2.new(0.5, -8, 0, 166), color)
	label({ Text = unit.name, Font = THEME.title, TextSize = 32, Position = UDim2.fromOffset(18, 8), Size = UDim2.new(1, -36, 0, 36), TextXAlignment = Enum.TextXAlignment.Left }, panel)
	local weapon = UnitData.Weapons[unit.weapon]
	label({ Text = weapon and weapon.name or unit.weapon, TextSize = 20, TextColor3 = THEME.dim, Position = UDim2.fromOffset(18, 45), Size = UDim2.new(1, -36, 0, 26), TextXAlignment = Enum.TextXAlignment.Left }, panel)
	local stats = forecast and forecast.count ~= 0 and ("HIT %d    DMG %d    CRT %d"):format(forecast.hit, forecast.dmg, forecast.crit) or "HIT --    DMG --    CRT --"
	label({ Text = stats, Font = THEME.bold, TextSize = 23, Position = UDim2.fromOffset(18, 76), Size = UDim2.new(1, -36, 0, 30), TextXAlignment = Enum.TextXAlignment.Left }, panel)
	local hp = label({ Text = ("KP %d / %d"):format(unit.hp, unit.maxHp), Font = THEME.bold, TextSize = 22, Position = UDim2.fromOffset(18, 115), Size = UDim2.fromOffset(170, 30), TextXAlignment = Enum.TextXAlignment.Left }, panel)
	local bar = make("Frame", { Position = UDim2.fromOffset(194, 118), Size = UDim2.new(1, -212, 0, 25), BackgroundColor3 = THEME.barBg, BorderSizePixel = 0, ClipsDescendants = true }, panel)
	UIKit.stroke(bar, THEME.goldDark, 1)
	local fill = make("Frame", { Size = UDim2.fromScale(unit.hp / unit.maxHp, 1), BackgroundColor3 = UIKit.hpColor(unit.hp / unit.maxHp), BorderSizePixel = 0 }, bar)
	-- Eine Trennlinie je KP; die Füllung läuft kontinuierlich darunter zurück.
	for i = 1, unit.maxHp - 1 do
		make("Frame", { Position = UDim2.fromScale(i / unit.maxHp, 0), Size = UDim2.new(0, 1, 1, 0), BackgroundColor3 = THEME.barBg, BackgroundTransparency = 0.3, BorderSizePixel = 0 }, bar)
	end
	local shield = coloredPanel(parent, UDim2.new(x, 18, 0, 18), UDim2.new(0.5, -36, 0, 54), color)
	label({ Text = unit.name, Font = THEME.title, TextSize = 30, Size = UDim2.fromScale(1, 1) }, shield)
	return { unit = unit, model = side.model, hp = hp, fill = fill, x = x == 0 and 0.28 or 0.72 }
end

function BattleScene.play(info)
	BattleScene.stop()
	if not info.left or not info.right or #info.strikes == 0 then return false end
	for _, side in { info.left, info.right } do
		if not side.model or not side.model.PrimaryPart then
			for _, other in { info.left, info.right } do
				if other.model then other.model:Destroy() end
			end
			return false
		end
	end
	local speed = info.speed or 1
	local scene = { connections = {}, threads = {}, tweens = {}, animations = {} }
	active = scene
	-- Das HUD wird währenddessen versteckt; Meldungen im HUD-Gui bleiben darüber.
	local gui = make("ScreenGui", {
		Name = "BattleScene", ResetOnSpawn = false, ScreenInsets = Enum.ScreenInsets.CoreUISafeInsets,
		SafeAreaCompatibility = Enum.SafeAreaCompatibility.None, DisplayOrder = -1, ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	}, Players.LocalPlayer:WaitForChild("PlayerGui"))
	local group = make("CanvasGroup", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, GroupTransparency = 1 }, gui)
	local surface = make("Frame", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1 }, group)
	local root = make("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0, ClipsDescendants = true }, surface)
	local scale = make("UIScale", {}, root)
	local function resize()
		local size = surface.AbsoluteSize
		if size.X <= 0 or size.Y <= 0 then return end
		local value = math.min(size.X / 1280, size.Y / 720)
		scale.Scale = value
		root.Size = UDim2.fromScale(1 / value, 1 / value)
	end
	table.insert(scene.connections, surface:GetPropertyChangedSignal("AbsoluteSize"):Connect(resize))
	resize()
	local function tween(object, time, props)
		local animation = TweenService:Create(object, TweenInfo.new(time / speed), props)
		table.insert(scene.tweens, animation)
		animation:Play()
		return animation
	end
	local function later(time, callback)
		local thread = task.delay(time / speed, function()
			if active == scene then callback() end
		end)
		table.insert(scene.threads, thread)
	end
	function scene.finish()
		if active ~= scene then return end
		active = nil
		for _, connection in scene.connections do connection:Disconnect() end
		for _, thread in scene.threads do
			if coroutine.status(thread) ~= "dead" and thread ~= coroutine.running() then task.cancel(thread) end
		end
		for _, cancel in scene.animations do cancel() end
		for _, animation in scene.tweens do animation:Cancel() end
		gui:Destroy()
		if info.onDone then info.onDone() end
	end
	local stage = info.stageId and Stages.get(info.stageId)
	local region = Stages.getRegion(stage and stage.region)
	local regionColor = region and region.color or Config.TERRAIN["."].color
	make("UIGradient", { Color = ColorSequence.new(Color3.fromRGB(153, 197, 230), regionColor), Rotation = 90 }, root)
	for i = 1, 3 do
		local hill = make("Frame", { Position = UDim2.fromScale((i - 1) * 0.38 - 0.12, 0.45 + (i % 2) * 0.07), Size = UDim2.fromScale(0.65, 0.45), BackgroundColor3 = regionColor:Lerp(THEME.bottom, 0.15 + i * 0.1), BorderSizePixel = 0 }, root)
		UIKit.corner(hill, 260)
	end
	local viewport = make("ViewportFrame", { Size = UDim2.new(1, 0, 1, -170), BackgroundTransparency = 1, Ambient = Color3.fromRGB(190, 190, 190), LightColor = Color3.fromRGB(255, 242, 218), LightDirection = Vector3.new(-1, -1, -1) }, root)
	local world = make("WorldModel", {}, viewport)
	local camera = make("Camera", { FieldOfView = 35, CFrame = CFrame.lookAt(Vector3.new(0, 8, 23), Vector3.new(0, 2.5, 0)) }, viewport)
	viewport.CurrentCamera = camera
	local first = info.strikes[1]
	local defender = first.targetId == info.left.unit.id and info.left or info.right
	local terrain = defender.terrain or Config.TERRAIN["."]
	make("Part", { Name = "Plattformrand", Anchored = true, Size = Vector3.new(16.4, 1, 6.4), Position = Vector3.new(0, -0.3, 0), Color = terrain.color:Lerp(Color3.new(0, 0, 0), 0.3), Material = terrain.material }, world)
	make("Part", { Name = "Gelände", Anchored = true, Size = Vector3.new(16, 0.3, 6), Position = Vector3.new(0, 0.25, 0), Color = terrain.color, Material = terrain.material }, world)
	for i, side in { info.left, info.right } do
		local model = side.model
		local base = model:GetAttribute("BaseScale") or 1
		local sourceScale = model:GetScale() / base
		local ground = (model:GetAttribute("GroundOffset") or 0) / sourceScale
		UnitShadow.remove(model)
		model:ScaleTo(base)
		for _, child in model:GetDescendants() do
			if child:IsA("BillboardGui") or child:IsA("Script") or child:IsA("LocalScript") then child:Destroy() end
		end
		local x = i == 1 and -3 or 3
		model:PivotTo(CFrame.lookAt(Vector3.new(x, 0.4 + ground, 0), Vector3.new(-x, 0.4 + ground, 0)))
		UnitShadow.create(model, 0.4)
		model.Parent = world
	end
	table.insert(scene.connections, RunService.RenderStepped:Connect(function()
		for _, side in { info.left, info.right } do
			UnitShadow.update(side.model, 0.4)
		end
	end))
	local left = buildSide(root, info.left, 0, THEME.enemy)
	local right = buildSide(root, info.right, 0.5, THEME.player)
	local sides = { [left.unit.id] = left, [right.unit.id] = right }
	label({ Text = "Tippen zum Überspringen", TextSize = 22, TextColor3 = THEME.gold, Position = UDim2.new(0, 0, 1, -210), Size = UDim2.new(1, 0, 0, 30), TextStrokeTransparency = 0.3 }, root)
	local skip = make("TextButton", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = "", ZIndex = 10, AutoButtonColor = false }, root)
	table.insert(scene.connections, skip.Activated:Connect(scene.finish))
	local originalCamera = camera.CFrame
	local shakeUntil, shakeStrength = 0, 0
	table.insert(scene.connections, RunService.RenderStepped:Connect(function()
		if os.clock() < shakeUntil then
			camera.CFrame = originalCamera * CFrame.new((math.random() - 0.5) * shakeStrength, (math.random() - 0.5) * shakeStrength, 0)
		else
			camera.CFrame = originalCamera
		end
	end))
	tween(group, Config.FEEL.battleSceneIntro, { GroupTransparency = 0 })
	for i, strike in info.strikes do
		later(Config.FEEL.battleSceneIntro + (i - 1) * Config.STRIKE_TIME, function()
			local attacker, target = sides[strike.attackerId], sides[strike.targetId]
			local cancel = UnitAnimator.playStrike(strike, attacker.unit.weapon, function()
				if active ~= scene then return end
				SoundPlayer.play(not strike.hit and "miss" or strike.crit and "crit" or "hit", { varyPitch = true })
				if info.onImpact then info.onImpact(strike) end
				local text = not strike.hit and "Verfehlt" or strike.crit and ("KRITISCH! " .. strike.damage) or strike.damage == 0 and "Kein Schaden" or tostring(strike.damage)
				local number = label({ Text = text, Font = THEME.bold, TextSize = strike.crit and 36 or 30, TextColor3 = strike.crit and THEME.warn or THEME.text, TextStrokeTransparency = 0.2, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(target.x, 0.3), Size = UDim2.fromOffset(360, 58), ZIndex = 4 }, root)
				tween(number, Config.FEEL.battleSceneTextTime, { Position = UDim2.fromScale(target.x, 0.23), TextTransparency = 1, TextStrokeTransparency = 1 })
				later(Config.FEEL.battleSceneTextTime, function() number:Destroy() end)
				target.hp.Text = ("KP %d / %d"):format(strike.hpAfter, target.unit.maxHp)
				tween(target.fill, Config.FEEL.battleSceneHpTime, { Size = UDim2.fromScale(strike.hpAfter / target.unit.maxHp, 1), BackgroundColor3 = UIKit.hpColor(strike.hpAfter / target.unit.maxHp) })
				if strike.hit then
					shakeStrength = strike.crit and Config.FEEL.critShakeStrength or Config.FEEL.shakeStrength
					shakeUntil = os.clock() + (strike.crit and Config.FEEL.critShakeDuration or Config.FEEL.shakeDuration) / speed
					if strike.crit then UI.flashCrit(speed) end
				end
				if strike.hpAfter == 0 then
					SoundPlayer.play("death")
					later(Config.FEEL.hitStop + Config.FEEL.battleSceneDeathDelay, function()
						local death = UnitAnimator.playDeath(target.model, { speed = speed, fxParent = world })
						if death then table.insert(scene.animations, death) end
					end)
				end
			end, { attacker = attacker.model, target = target.model, fxParent = world, speed = speed })
			if cancel then table.insert(scene.animations, cancel) end
		end)
	end
	later(Config.FEEL.battleSceneIntro + #info.strikes * Config.STRIKE_TIME, function()
		tween(group, Config.FEEL.battleSceneOutro, { GroupTransparency = 1 })
	end)
	later(Config.FEEL.battleSceneIntro + #info.strikes * Config.STRIKE_TIME + Config.FEEL.battleSceneOutro, scene.finish)
	return true
end

return BattleScene
