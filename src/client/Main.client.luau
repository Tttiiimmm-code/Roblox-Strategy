-- Client: Eingabe (Maus & Touch), Reichweiten, Bewegungsvorschau, Kampfvorschau, Menüs, Animationen
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Grid = require(Shared:WaitForChild("Grid"))
local UnitData = require(Shared:WaitForChild("UnitData"))
local Combat = require(Shared:WaitForChild("Combat"))
local Stages = require(Shared:WaitForChild("Stages"))

local Atmosphere = require(script.Parent:WaitForChild("Atmosphere"))
local SoundPlayer = require(script.Parent:WaitForChild("SoundPlayer"))
local UI = require(script.Parent:WaitForChild("UI"))
local MenuUI = require(script.Parent:WaitForChild("MenuUI"))
local CameraController = require(script.Parent:WaitForChild("CameraController"))
local UnitAnimator = require(script.Parent:WaitForChild("UnitAnimator"))
local Hub = require(script.Parent:WaitForChild("Hub"))

local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local StateUpdate = Remotes:WaitForChild("StateUpdate")
local Command = Remotes:WaitForChild("Command")
local BattleEvent = Remotes:WaitForChild("BattleEvent")
local ProfileUpdate = Remotes:WaitForChild("ProfileUpdate")
local GetState = Remotes:WaitForChild("GetState")
local GetProfile = Remotes:WaitForChild("GetProfile")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera
local unitsFolder = workspace:WaitForChild("Units")

local fxFolder = Instance.new("Folder")
fxFolder.Name = "ClientFX"
fxFolder.Parent = workspace

UnitAnimator.init(unitsFolder, fxFolder)

local TOUCH = UserInputService.TouchEnabled and not UserInputService.MouseEnabled
local TAP = TOUCH and "Tippe" or "Klicke"

-- Zustand -------------------------------------------------------------------
local state = nil -- letzter Snapshot vom Server
local profile = nil
local mode = "Busy" -- Idle | Selected | Menu | Target | Busy
local selectedId = nil
local nodes = nil
local dest = nil
local targets = {}
local pendingTargetId = nil
local inspectedId = nil
local dangerOn = false

local overlays = {}
local dangerOverlays = {}
local ghost = nil
local fadedModel = nil

-- Hilfsfunktionen -----------------------------------------------------------
local function send(cmd)
	Command:FireServer(cmd)
end

-- Eigener Kampf? Andere Spieler bleiben während eines fremden Kampfes im Thronsaal.
local function isMine()
	return state ~= nil and state.mode == "Battle" and state.ownerUserId == player.UserId
end

local function inBattle()
	return isMine() and state.phase ~= "Prep"
end

local function canControl()
	return inBattle() and state.phase == "Player" and not state.busy and not state.result
end

local function makeFxPart(size, color, transparency)
	local p = Instance.new("Part")
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.CastShadow = false
	p.Material = Enum.Material.Neon
	p.Size = size
	p.Color = color
	p.Transparency = transparency
	p.Parent = fxFolder
	return p
end

local function addOverlay(list, x, y, color, transparency, height)
	local T = Config.TILE_SIZE
	local p = makeFxPart(Vector3.new(T - 0.8, 0.1, T - 0.8), color, transparency or 0.5)
	p.Position = Grid.toWorld(x, y) + Vector3.new(0, height or 0.06, 0)
	local target = transparency or 0.5
	p.Transparency = 1
	local fade = TweenService:Create(p, TweenInfo.new(Config.FEEL.overlayFade), { Transparency = target })
	fade:Play()
	if color == Config.OVERLAY.Attack or color == Config.OVERLAY.Danger then
		fade.Completed:Once(function(status)
			if status == Enum.PlaybackState.Completed and p.Parent then
				TweenService:Create(p, TweenInfo.new(Config.FEEL.overlayPulseDuration, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), { Transparency = math.min(1, target + Config.FEEL.overlayPulseAmount) }):Play()
			end
		end)
	end
	table.insert(list, p)
	return p
end

local function clearList(list)
	for _, p in list do
		p:Destroy()
	end
	table.clear(list)
end

local cursor = makeFxPart(Vector3.new(Config.TILE_SIZE - 0.2, 0.15, Config.TILE_SIZE - 0.2), Config.OVERLAY.Cursor, 1)

local function setLocalFade(model, amount)
	for _, d in model:GetDescendants() do
		if d:IsA("BasePart") then
			d.LocalTransparencyModifier = amount
		end
	end
end

local function clearGhost()
	if ghost then
		ghost:Destroy()
		ghost = nil
	end
	if fadedModel then
		setLocalFade(fadedModel, 0)
		fadedModel = nil
	end
end

-- Halbdurchsichtige Kopie der Figur am Zielfeld, in Laufrichtung gedreht
local function showGhost(unit, x, y)
	clearGhost()
	local model = unitsFolder:FindFirstChild(unit.id)
	if not model then
		return
	end
	local moved = x ~= unit.x or y ~= unit.y
	local rotation = model:GetPivot().Rotation
	if moved then
		local d = Grid.toWorld(x, y) - Grid.toWorld(unit.x, unit.y)
		rotation = CFrame.Angles(0, math.atan2(-d.X, -d.Z), 0)
	end

	ghost = model:Clone()
	for _, d in ghost:GetDescendants() do
		if d:IsA("BasePart") then
			d.CanQuery = false
			if d.Transparency < 1 then
				d.Transparency = 0.45
			end
		elseif d:IsA("Decal") then
			d.Transparency = 0.45
		elseif d:IsA("BillboardGui") or d:IsA("ParticleEmitter") then
			d:Destroy()
		end
	end
	ghost:PivotTo(CFrame.new(Grid.toWorld(x, y) + Vector3.new(0, (model:GetAttribute("GroundOffset") or 0) + 0.1, 0)) * rotation)
	ghost.Parent = fxFolder

	if moved then
		fadedModel = model
		setLocalFade(model, 0.75)
	end
end

local function showRanges(unit, moveColor)
	local n = Grid.reachable(unit, state.units)
	local move, attack = Grid.ranges(unit, state.units, n)
	-- Gelände erklärt sich über sein Aussehen; keine Kosten-Beschriftungen auf den Feldern
	for _, t in move do
		addOverlay(overlays, t.x, t.y, moveColor)
	end
	for _, t in attack do
		addOverlay(overlays, t.x, t.y, Config.OVERLAY.Attack)
	end
	return n
end

-- Gefahrenzone: alle Felder, die irgendein Gegner nächste Runde angreifen kann
local function redrawDanger()
	clearList(dangerOverlays)
	if not dangerOn or not inBattle() or state.result then
		return
	end
	local seen = {}
	for _, enemy in state.units do
		if enemy.team == "Enemy" then
			local move, attack = Grid.ranges(enemy, state.units)
			for _, list in { move, attack } do
				for _, t in list do
					local k = Grid.key(t.x, t.y)
					if not seen[k] then
						seen[k] = true
						addOverlay(dangerOverlays, t.x, t.y, Config.OVERLAY.Danger, 0.78, 0.03)
					end
				end
			end
		end
	end
end

-- Kontext-Hinweis für Einsteiger
local function updateHint()
	if not inBattle() then
		return
	end
	local text
	if state.result then
		text = ""
	elseif state.phase == "Enemy" then
		text = "<b>Der Gegner ist am Zug …</b>\nBeobachte, wohin er zieht."
	elseif state.busy or mode == "Busy" then
		text = "…"
	elseif mode == "Idle" then
		text = ("<b>%s auf eine blaue Einheit</b>, um sie zu bewegen.\nRote Gegner antippen zeigt ihre Reichweite."):format(TAP)
	elseif mode == "Selected" then
		text = ("<b>%s auf ein blaues Feld</b> als Ziel.\nOder %s direkt auf einen Gegner zum Angreifen."):format(TAP, string.lower(TAP))
	elseif mode == "Menu" then
		text = "<b>Wähle eine Aktion</b> rechts.\nAngriff ist nur möglich, wenn ein Gegner in Reichweite ist."
	elseif mode == "Target" then
		text = ("<b>%s auf einen Gegner</b> für die Kampfvorschau.\nNochmal %s greift an."):format(TAP, string.lower(TAP))
	end
	UI.setHint(text)
end

local function updateTools()
	if not inBattle() then
		return
	end
	UI.setTools({
		back = mode == "Selected" or mode == "Menu" or mode == "Target" or inspectedId ~= nil,
		undoLeft = state.undoLeft or 0,
		canUndo = state.canUndo,
		danger = dangerOn,
		speed = state.speed or 1,
		controllable = canControl(),
		enemyPhase = state.phase == "Enemy" and not state.result,
	})
end

local function setMode(newMode)
	mode = newMode
	updateHint()
	updateTools()
end

local function resetSelection()
	UnitAnimator.select(nil)
	selectedId, nodes, dest, pendingTargetId, inspectedId = nil, nil, nil, nil, nil
	targets = {}
	clearList(overlays)
	clearGhost()
	UI.hideMenu()
	UI.hideForecast()
	setMode(canControl() and "Idle" or "Busy")
end

-- Aktionen ------------------------------------------------------------------
local function sendAct(action, targetId)
	send({
		type = "Act",
		unitId = selectedId,
		x = dest.x,
		y = dest.y,
		action = action,
		targetId = targetId,
	})
	resetSelection()
	setMode("Busy")
end

local function selectUnit(unit)
	resetSelection()
	selectedId = unit.id
	UnitAnimator.select(unit.id)
	nodes = showRanges(unit, Config.OVERLAY.Move)
	setMode("Selected")
end

local function startTargeting()
	UI.hideMenu()
	clearList(overlays)
	for _, t in targets do
		addOverlay(overlays, t.x, t.y, Config.OVERLAY.Attack)
	end
	setMode("Target")
end

local function openMenu(x, y)
	local unit = state.units[selectedId]
	dest = { x = x, y = y }
	pendingTargetId = nil
	clearList(overlays)
	UI.hideForecast()
	addOverlay(overlays, x, y, Config.OVERLAY.Move)
	showGhost(unit, x, y)
	targets = Grid.targetsFrom(unit, state.units, x, y)
	UI.showMenu(#targets > 0, {
		onAttack = startTargeting,
		onWait = function()
			sendAct("Wait")
		end,
		onCancel = function()
			selectUnit(unit)
		end,
	})
	setMode("Menu")
end

local function previewAttack(target)
	local unit = state.units[selectedId]
	pendingTargetId = target.id
	local forecast = Combat.forecast(unit, target, dest.x, dest.y)
	UI.showForecast(unit, target, forecast, {
		onConfirm = function()
			sendAct("Attack", target.id)
		end,
		onCancel = function()
			pendingTargetId = nil
			UI.hideForecast()
		end,
	})
end

local function toggleInspect(enemy)
	local same = inspectedId == enemy.id
	resetSelection()
	if not same then
		inspectedId = enemy.id
		showRanges(enemy, Config.OVERLAY.EnemyMove)
		updateTools()
	end
end

-- Bestes Angriffsfeld: stehen bleiben, wenn möglich; sonst ein Feld ohne Konter des Gegners,
-- dann größere Distanz, dann bestes Gelände, dann kürzester Weg
local function bestAttackTile(unit, enemy)
	local weapon = UnitData.Weapons[unit.weapon]
	local enemyWeapon = UnitData.Weapons[enemy.weapon]
	local best, bestScore
	for _, node in nodes or {} do
		local d = Grid.dist(node.x, node.y, enemy.x, enemy.y)
		if node.canStop and d >= weapon.minRange and d <= weapon.maxRange then
			local terrain = Grid.terrainAt(node.x, node.y)
			local stay = (node.x == unit.x and node.y == unit.y) and 100000 or 0
			local safe = not (enemyWeapon and d >= enemyWeapon.minRange and d <= enemyWeapon.maxRange) and 10000 or 0
			local score = stay + safe + d * 1000 + terrain.avoid + terrain.def * 5 - node.cost
			if not bestScore or score > bestScore then
				best, bestScore = node, score
			end
		end
	end
	return best
end

local function isTarget(unit)
	for _, t in targets do
		if t.id == unit.id then
			return true
		end
	end
	return false
end

local function onClick(x, y)
	if mode == "Busy" or not canControl() then
		return
	end
	local unit = Grid.unitAt(state.units, x, y)

	if mode == "Idle" then
		if unit and unit.team == "Player" and not unit.done then
			selectUnit(unit)
		elseif unit and unit.team ~= "Player" then
			toggleInspect(unit)
		else
			resetSelection()
		end
	elseif mode == "Selected" then
		local node = nodes[Grid.key(x, y)]
		if unit and unit.team ~= "Player" then
			-- Direktangriff: passendes Feld automatisch wählen und gleich die Kampfvorschau zeigen
			local tile = bestAttackTile(state.units[selectedId], unit)
			if tile then
				openMenu(tile.x, tile.y)
				startTargeting()
				previewAttack(unit)
				return
			end
			UI.toast("Gegner außer Reichweite")
		end
		if not node or not node.canStop then
			local selected = state.units[selectedId]
			if unit and (unit.team ~= "Player" or not unit.done) then
				-- Eigene Einheit antippen wählt um; Gegner wurde oben behandelt
			elseif unit then
				UI.toast("Feld besetzt")
			elseif selected and Grid.moveCost(selected, x, y) == nil then
				local terrain = Grid.terrainAt(x, y)
				local moveType = UnitData.Classes[selected.class].moveType
				local troops = moveType == "horse" and "Reiter" or "Fußtruppen"
				if terrain then
					UI.toast(terrain.name .. (terrain.name == "Wasser" and " – nicht betretbar" or " – für " .. troops .. " unpassierbar"))
				end
			else
				UI.toast("Zu weit – Bewegung reicht nicht")
			end
		end
		if node and node.canStop then
			openMenu(x, y)
		elseif unit and unit.team == "Player" and not unit.done then
			selectUnit(unit)
		else
			resetSelection()
		end
	elseif mode == "Target" then
		if unit and isTarget(unit) then
			if pendingTargetId == unit.id then
				sendAct("Attack", unit.id) -- zweites Antippen bestätigt
			else
				previewAttack(unit)
			end
		end
	end
end

local function goBack()
	if mode == "Target" then
		openMenu(dest.x, dest.y)
	elseif mode == "Menu" then
		selectUnit(state.units[selectedId])
	elseif mode == "Selected" or inspectedId then
		resetSelection()
	end
end

-- Eingabe: Tippen/Klicken wählt, Ziehen verschiebt die Kamera ----------------
local raycastParams = RaycastParams.new()
raycastParams.FilterType = Enum.RaycastFilterType.Include

-- Direktes Kind von "Units" = Figur einer Einheit (Name = Unit-ID)
local function unitModelOf(inst)
	while inst and inst.Parent ~= unitsFolder do
		inst = inst.Parent
	end
	return inst
end

local function tileFromRay(ray)
	raycastParams.FilterDescendantsInstances = { workspace:FindFirstChild("Board"), unitsFolder }
	local result = workspace:Raycast(ray.Origin, ray.Direction * 1000, raycastParams)
	if not result then
		return nil
	end
	local model = unitModelOf(result.Instance)
	if model and state and state.units[model.Name] then
		local u = state.units[model.Name]
		return u.x, u.y
	end
	return result.Instance:GetAttribute("X"), result.Instance:GetAttribute("Y")
end

local DRAG_THRESHOLD = 12
local press = nil -- Maus: { start, last, dragged }
local touches = {} -- InputObject -> eigene Start-/Letzte-Position
local activeTouches = 0
local touchOrder = 0
local gesture = nil

local function touchPosition(input)
	return Vector2.new(input.Position.X, input.Position.Y)
end

local function pairGeometry(first, second)
	local a, b = touchPosition(first), touchPosition(second)
	local delta = b - a
	return delta.Magnitude, (a + b) / 2, math.atan2(delta.Y, delta.X)
end

local function resetTouchBasis()
	activeTouches = 0
	local pair = {}
	for input, touch in touches do
		activeTouches += 1
		touch.last = touchPosition(input)
		table.insert(pair, input)
	end
	gesture = nil
	if activeTouches > 1 then
		for _, touch in touches do touch.dragged = true end
	end
	if activeTouches == 2 then
		table.sort(pair, function(a, b) return touches[a].order < touches[b].order end)
		if touches[pair[1]].blocked or touches[pair[2]].blocked then return end
		local distance, midpoint, angle = pairGeometry(pair[1], pair[2])
		gesture = { first = pair[1], second = pair[2], distance = distance, midpoint = midpoint,
			angle = angle, rotation = 0, rotating = false }
	end
end

UserInputService.InputBegan:Connect(function(input, processed)
	local t = input.UserInputType
	if t == Enum.UserInputType.Touch then
		local pos = touchPosition(input)
		touchOrder += 1
		touches[input] = { start = pos, last = pos, dragged = false, order = touchOrder,
			blocked = processed or not CameraController.isActive() }
		resetTouchBasis()
		return
	end
	if processed then
		return
	end
	if t == Enum.UserInputType.MouseButton1 then
		local pos = Vector2.new(input.Position.X, input.Position.Y)
		press = { start = pos, last = pos, dragged = false }
	elseif t == Enum.UserInputType.MouseButton2 then
		goBack()
	end
end)

UserInputService.InputChanged:Connect(function(input)
	local t = input.UserInputType
	if t == Enum.UserInputType.Touch then
		local touch = touches[input]
		if not touch then return end
		local pos = touchPosition(input)
		if CameraController.isActive() and not touch.blocked then
			if activeTouches == 1 then
				if not touch.dragged and (pos - touch.start).Magnitude > DRAG_THRESHOLD then
					touch.dragged = true
				end
				if touch.dragged then CameraController.panBy((pos - touch.last) * Config.FEEL.touchPanScale) end
			elseif activeTouches == 2 and gesture then
				local distance, midpoint, angle = pairGeometry(gesture.first, gesture.second)
				if gesture.distance > 0 and distance > 0 then CameraController.zoomBy(distance / gesture.distance) end
				CameraController.panBy((midpoint - gesture.midpoint) * Config.FEEL.touchPanScale)
				local rotation = math.atan2(math.sin(angle - gesture.angle), math.cos(angle - gesture.angle))
				gesture.rotation += rotation
				if gesture.rotating then
					CameraController.rotateBy(rotation)
				elseif math.abs(gesture.rotation) > math.rad(Config.FEEL.touchRotateThreshold) then
					gesture.rotating = true
				end
				gesture.distance, gesture.midpoint, gesture.angle = distance, midpoint, angle
			end
		end
		touch.last = pos
		return
	end
	if not press then
		return
	end
	if t ~= Enum.UserInputType.MouseMovement then
		return
	end
	local pos = Vector2.new(input.Position.X, input.Position.Y)
	if not press.dragged and (pos - press.start).Magnitude > DRAG_THRESHOLD then
		press.dragged = true
	end
	if press.dragged and CameraController.isActive() then
		CameraController.panBy(pos - press.last)
	end
	press.last = pos
end)

UserInputService.InputEnded:Connect(function(input)
	local t = input.UserInputType
	if t == Enum.UserInputType.Touch then
		local touch = touches[input]
		if not touch then return end
		touches[input] = nil
		resetTouchBasis()
		if not touch.blocked and not touch.dragged and CameraController.isActive()
			and input.UserInputState ~= Enum.UserInputState.Cancel then
			local x, y = tileFromRay(camera:ScreenPointToRay(input.Position.X, input.Position.Y))
			if x then onClick(x, y) end
		end
		return
	end
	if t == Enum.UserInputType.MouseButton1 and press then
		if not press.dragged then
			local x, y = tileFromRay(camera:ScreenPointToRay(input.Position.X, input.Position.Y))
			if x then
				onClick(x, y)
			end
		end
		press = nil
	end
end)

-- Cursor, Info-Panel und Geländeanzeige folgen der Maus (am Handy: Auswahl)
RunService.RenderStepped:Connect(function()
	if not isMine() then
		cursor.Transparency = 1
		UI.hideInfo()
		return
	end
	local x, y
	if not TOUCH then
		local mouse = UserInputService:GetMouseLocation()
		x, y = tileFromRay(camera:ViewportPointToRay(mouse.X, mouse.Y))
	end
	if x then
		cursor.Position = Grid.toWorld(x, y) + Vector3.new(0, 0.1, 0)
		cursor.Transparency = 0.65
		UI.showTerrain(Grid.terrainAt(x, y))
	else
		cursor.Transparency = 1
		local selected = TOUCH and selectedId and state.units[selectedId]
		if selected then
			UI.showTerrain(Grid.terrainAt(selected.x, selected.y))
		else
			UI.hideTerrain()
		end
	end

	local hovered = x and Grid.unitAt(state.units, x, y)
	local shown = hovered or (selectedId and state.units[selectedId]) or (inspectedId and state.units[inspectedId])
	if shown and not state.result and state.phase ~= "Prep" then
		UI.showInfo(shown, Grid.terrainAt(shown.x, shown.y))
	else
		UI.hideInfo()
	end
end)

-- Schadenszahlen über den Einheiten
local function floatText(unitId, text, color, size)
	local model = unitsFolder:FindFirstChild(unitId)
	local root = model and model.PrimaryPart
	if not root then
		return
	end
	local top = model:GetAttribute("TopY") or 6
	local bb = Instance.new("BillboardGui")
	bb.Adornee = root
	bb.Size = UDim2.fromOffset(size or 160, 44)
	bb.StudsOffsetWorldSpace = Vector3.new(0, top + 2, 0)
	bb.AlwaysOnTop = true
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.GothamBlack
	label.TextScaled = true
	label.TextColor3 = color
	label.TextStrokeTransparency = 0
	label.Text = text
	label.Parent = bb
	local scale = Instance.new("UIScale")
	scale.Scale = 1.6
	scale.Parent = label
	bb.Parent = player:WaitForChild("PlayerGui")

	TweenService:Create(scale, TweenInfo.new(0.2, Enum.EasingStyle.Back), { Scale = 1 }):Play()
	local info = TweenInfo.new(1.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	TweenService:Create(bb, info, { StudsOffsetWorldSpace = Vector3.new(0, top + 5, 0) }):Play()
	TweenService:Create(label, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.In, 0, false, 0.6), {
		TextTransparency = 1, TextStrokeTransparency = 1,
	}):Play()
	Debris:AddItem(bb, 1.2)
end

local hapticToken = 0
local function impactHaptic(critical, speed)
	if not TOUCH then return end
	hapticToken += 1
	local token = hapticToken
	pcall(function()
		local service = game:GetService("HapticService")
		local input = Enum.UserInputType.Touch
		local motor = Enum.VibrationMotor.Small
		if not service:IsVibrationSupported(input) or not service:IsMotorSupported(input, motor) then return end
		service:SetMotor(input, motor, critical and Config.FEEL.hapticCrit or Config.FEEL.hapticHit)
		task.delay(Config.FEEL.hapticDuration / speed, function()
			if token == hapticToken then pcall(function() service:SetMotor(input, motor, 0) end) end
		end)
	end)
end

local cameraEvent = 0
BattleEvent.OnClientEvent:Connect(function(payload)
	if not isMine() then return end
	if payload.enemyMove then
		cameraEvent += 1
		local move = payload.enemyMove
		CameraController.focusOn(Grid.toWorld(move.x, move.y), Config.FEEL.battleZoom, Config.FEEL.cameraFocusTime / (state.speed or 1))
	elseif payload.strikes then
		cameraEvent += 1
		local token = cameraEvent
		local first = payload.strikes[1]
		local a = first and state.units[first.attackerId]
		local b = first and state.units[first.targetId]
		if a and b then
			CameraController.focusOn((Grid.toWorld(a.x, a.y) + Grid.toWorld(b.x, b.y)) / 2, Config.FEEL.battleZoom, Config.FEEL.cameraFocusTime / (state.speed or 1))
		end
		local speed = state and state.speed or 1
		for i, s in payload.strikes do
			task.delay((i - 1) * Config.STRIKE_TIME / speed, function()
				local attacker = state and state.units[s.attackerId]
				local weaponKey = attacker and attacker.weapon or "IronSword"
				UnitAnimator.playStrike(s, weaponKey, function()
					SoundPlayer.play(not s.hit and "miss" or s.crit and "crit" or "hit", { varyPitch = true })
					if s.hpAfter == 0 then SoundPlayer.play("death") end
					if s.hit then
						impactHaptic(s.crit, speed)
						CameraController.shake(s.crit and Config.FEEL.critShakeStrength or Config.FEEL.shakeStrength, (s.crit and Config.FEEL.critShakeDuration or Config.FEEL.shakeDuration) / speed)
						if s.crit then UI.flashCrit(speed) end
					end
					if not s.hit then
						floatText(s.targetId, "Verfehlt", Color3.fromRGB(190, 196, 210), 140)
					elseif s.crit then
						floatText(s.targetId, "KRITISCH! " .. s.damage, Color3.fromRGB(255, 170, 40), 220)
					elseif s.damage == 0 then
						floatText(s.targetId, "Kein Schaden", Color3.fromRGB(190, 196, 210), 160)
					else
						floatText(s.targetId, tostring(s.damage), Color3.new(1, 1, 1), 110)
					end
				end)
			end)
		end
		task.delay(#payload.strikes * Config.STRIKE_TIME / speed, function()
			if token == cameraEvent then CameraController.restore(Config.FEEL.cameraRestoreTime / speed) end
		end)
	elseif payload.exp and isMine() then
		local e = payload.exp
		if e.level then
			UI.showLevelUp(e)
		elseif e.exp > 0 then
			UI.toast(("%s erhält <b>%d EP</b>"):format(e.unitName, e.exp), 2)
		end
	end
end)

-- Zustand vom Server übernehmen
local function applyState(newState)
	if not newState then
		return
	end
	local previous = state
	state = newState

	if state.stageId and (not previous or previous.stageId ~= state.stageId or previous.mode ~= "Battle") then
		Grid.setMap(Stages.get(state.stageId).map)
		local T = Config.TILE_SIZE
		local size = Vector3.new(Grid.width() * T, 0, Grid.height() * T)
		CameraController.setBounds(size / 2, size)
	end
	if state.phase == "Prep" then
		UI.resetPhaseBanner()
		if profile then
			profile.reward = nil
		end
	end

	UnitAnimator.setSpeed(state.speed or 1)
	if previous and previous.phase == "Enemy" and state.phase ~= "Enemy" then
		cameraEvent += 1
		CameraController.restore(Config.FEEL.cameraRestoreTime / (state.speed or 1))
	end
	-- Kamera und Avatar: Taktik-Ansicht nur im eigenen Kampf, sonst frei im Thronsaal
	CameraController.setActive(isMine())
	Hub.setBattleView(isMine())
	local atmosphere = "hall"
	if isMine() then
		local stage = Stages.get(state.stageId)
		local region = stage and Stages.getRegion(stage.region)
		atmosphere = region and region.atmosphere or "battle"
	end
	Atmosphere.set(atmosphere)
	SoundPlayer.playMusic(isMine() and (state.result and (state.result == "Victory" and "musicVictory" or "musicDefeat") or "musicBattle") or "musicHub", { loop = not (isMine() and state.result ~= nil) })
	resetSelection()
	UI.setHudVisible(inBattle() and not state.result)
	if inBattle() then
		UI.setPhase(state)
	end
	updateHint()
	updateTools()
	redrawDanger()
	MenuUI.update(state, profile)
end

ProfileUpdate.OnClientEvent:Connect(function(newProfile)
	profile = newProfile
	MenuUI.update(state, profile)
	if newProfile.recruitResult then
		MenuUI.showRecruitResults(newProfile.recruitResult)
	end
end)

local root = UI.init({
	onEndTurn = function()
		if canControl() then
			resetSelection()
			setMode("Busy")
			send({ type = "EndTurn" })
		end
	end,
	onBack = goBack,
	onUndo = function()
		if canControl() then
			send({ type = "Undo" })
		end
	end,
	onDanger = function()
		dangerOn = not dangerOn
		redrawDanger()
		updateTools()
	end,
	onSpeed = function()
		send({ type = "SetSpeed", speed = (state and state.speed == 2) and 1 or 2 })
	end,
	onSkipEnemy = function()
		if isMine() and state.phase == "Enemy" then send({ type = "SetSpeed", speed = 3 }) end
	end,
	onForfeit = function()
		send({ type = "ToLobby" })
	end,
})

MenuUI.init(root, {
	onStart = function(stageId, difficulty)
		send({ type = "StartStage", stageId = stageId, difficulty = difficulty })
	end,
	onBegin = function(heroIds)
		send({ type = "BeginBattle", heroes = heroIds })
	end,
	onRecruit = function(bannerId, count)
		send({ type = "Recruit", bannerId = bannerId, count = count })
	end,
	onRetry = function()
		send({ type = "Retry" })
	end,
	onLobby = function()
		send({ type = "ToLobby" })
	end,
	onStandUp = function()
		Hub.standUp()
	end,
})

Hub.init({
	onStation = function(tab)
		MenuUI.openLobby(tab)
	end,
	onThrone = function(seated)
		MenuUI.setThrone(seated)
	end,
})

Grid.setMap(Stages.List[1].map)
local T = Config.TILE_SIZE
local boardSize = Vector3.new(Grid.width() * T, 0, Grid.height() * T)
CameraController.setBounds(boardSize / 2, boardSize)
CameraController.start()

StateUpdate.OnClientEvent:Connect(applyState)
applyState(GetState:InvokeServer())
task.spawn(function()
	local p = GetProfile:InvokeServer()
	if p then
		profile = p
		MenuUI.update(state, profile)
	end
end)
