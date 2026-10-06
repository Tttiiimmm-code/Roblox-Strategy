-- Server: Kartenauswahl, Aufstellung, Kampfablauf, Gegnerphase, Sterne & Belohnungen
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

Players.CharacterAutoLoads = true -- Avatare laufen im Thronsaal

local Shared = ReplicatedStorage:WaitForChild("Shared")
local UnitData = require(Shared.UnitData)
local Grid = require(Shared.Grid)
local Combat = require(Shared.Combat)
local Stages = require(Shared.Stages)
local Recruit = require(Shared.Recruit)

local BoardBuilder = require(script.Parent.BoardBuilder)
local UnitVisuals = require(script.Parent.UnitVisuals)
local EnemyAI = require(script.Parent.EnemyAI)
local ProfileStore = require(script.Parent.ProfileStore)
local HubBuilder = require(script.Parent.HubBuilder)
local Config = require(Shared.Config)

-- Remotes ------------------------------------------------------------------
local remotes = Instance.new("Folder")
remotes.Name = "Remotes"

local function remote(className, name)
	local r = Instance.new(className)
	r.Name = name
	r.Parent = remotes
	return r
end

local StateUpdate = remote("RemoteEvent", "StateUpdate")
local Command = remote("RemoteEvent", "Command")
local BattleEvent = remote("RemoteEvent", "BattleEvent")
local ProfileUpdate = remote("RemoteEvent", "ProfileUpdate")
local GetState = remote("RemoteFunction", "GetState")
local GetProfile = remote("RemoteFunction", "GetProfile")

-- Zustand ------------------------------------------------------------------
local unitsFolder = BoardBuilder.ensureUnitsFolder()
UnitVisuals.init(unitsFolder)
Grid.setMap(Stages.List[1].map) -- Kulisse für die Kartenauswahl
BoardBuilder.build()
HubBuilder.build()
task.spawn(UnitVisuals.buildHeroTemplates)

local rng = Random.new()
local nextUnitId = 0
local undoStack = {}
local enemySpeedBefore

local function lobbyState(speed)
	return { mode = "Lobby", units = {}, phase = "Prep", turn = 1, busy = false, speed = speed or 1, undoLeft = 0, lost = 0 }
end

local state = lobbyState()

local function snapshot()
	return {
		mode = state.mode,
		stageId = state.stageId,
		difficulty = state.difficulty,
		units = state.units,
		phase = state.phase,
		turn = state.turn,
		busy = state.busy,
		result = state.result,
		resultInfo = state.resultInfo,
		speed = state.speed,
		undoLeft = state.undoLeft,
		canUndo = #undoStack > 0,
		lost = state.lost,
		turnGoal = state.turnGoal,
		maxUnits = state.maxUnits,
		ownerUserId = state.ownerUserId,
		ownerName = state.ownerName,
	}
end

local function broadcast()
	StateUpdate:FireAllClients(snapshot())
end

-- Wartezeiten richten sich nach dem gewählten Tempo
local function pause(t)
	task.wait(t / state.speed)
end

local function profilePayload(profile)
	return {
		gold = profile.gold,
		gems = profile.gems,
		stars = profile.stars,
		heroes = profile.heroes,
		pity = profile.pity,
		saveOk = profile.saveOk,
	}
end

-- extra: optionale Zusatzfelder (reward nach Kampf, recruitResult nach Rekrutierung)
local function sendProfile(player, extra)
	local profile = ProfileStore.get(player)
	if profile then
		local payload = profilePayload(profile)
		for k, v in extra or {} do
			payload[k] = v
		end
		ProfileUpdate:FireClient(player, payload)
	end
end

local function clearUnits()
	for id in state.units do
		UnitVisuals.remove(id, true)
	end
	state.units = {}
	table.clear(undoStack)
end

local function makeUnit(def, x, y, team, level, bonus)
	nextUnitId += 1
	local unit = {
		id = "u" .. nextUnitId,
		name = def.name,
		team = team,
		class = def.class,
		weapon = def.weapon,
		x = x,
		y = y,
		level = level or 1,
		xp = 0,
		rarity = def.rarity or 1,
		isLord = def.isLord or false,
		ai = def.ai or "aggressive",
		done = false,
		deployed = true,
		maxHp = def.stats.hp,
		hp = def.stats.hp,
	}
	for stat, value in def.stats do
		if stat ~= "hp" then
			unit[stat] = value
		end
	end
	for stat, b in bonus or {} do
		if stat == "hp" then
			unit.maxHp = math.max(1, unit.maxHp + b)
			unit.hp = unit.maxHp
		else
			unit[stat] = math.max(0, unit[stat] + b)
		end
	end
	return unit
end

local function setupStage(stageId, diffId)
	enemySpeedBefore = nil
	local stage = Stages.get(stageId)
	local diff = Stages.getDifficulty(diffId)
	clearUnits()
	Grid.setMap(stage.map)
	local boardStart = os.clock()
	BoardBuilder.build(stage.region)
	local boardDuration = os.clock() - boardStart

	-- Eigene Helden werden erst bei "BeginBattle" aus dem Profil des Spielers aufgestellt
	state = {
		mode = "Battle",
		ownerUserId = state.ownerUserId,
		ownerName = state.ownerName,
		stageId = stageId,
		difficulty = diffId,
		units = {},
		heroUnits = {}, -- heroId -> Einheit (auch gefallene), für das Zurückschreiben des Fortschritts
		phase = "Prep",
		turn = 1,
		busy = false,
		speed = state.speed,
		undoLeft = diff.undo,
		lost = 0,
		turnGoal = Stages.turnGoal(stage, diff),
		maxUnits = Stages.unitLimit(stage, diff),
	}

	local unitsStart = os.clock()
	local enemies = table.clone(stage.enemies)
	if diff.extraEnemies then
		for _, e in stage.hardEnemies do
			table.insert(enemies, e)
		end
	end
	for _, e in enemies do
		local unit = makeUnit(UnitData.Enemies[e.kind], e.x, e.y, "Enemy", e.level, diff.enemyBonus)
		state.units[unit.id] = unit
		UnitVisuals.create(unit)
	end
	print(("Missionsaufbau %s: Brett %.0f ms, Figuren %.0f ms"):format(stageId, boardDuration * 1000, (os.clock() - unitsStart) * 1000))

	broadcast()
end

-- Held aus dem Profil auf ein Startfeld stellen (gespeicherte Werte, Level, Verschmelzungen)
local function spawnHero(heroId, entry, x, y)
	local def = UnitData.Heroes[heroId]
	local unitDef = {
		name = def.name,
		class = def.class,
		weapon = def.weapon,
		rarity = def.rarity,
		isLord = def.isLord,
		stats = entry.stats or def.stats,
	}
	local unit = makeUnit(unitDef, x, y, "Player", entry.level or 1)
	unit.heroId = heroId
	unit.xp = entry.xp or 0
	unit.mergeHp = (entry.merges or 0) * Recruit.MERGE_HP
	unit.maxHp += unit.mergeHp
	unit.hp = unit.maxHp
	state.units[unit.id] = unit
	state.heroUnits[heroId] = unit
	UnitVisuals.create(unit)
end

-- Level, EP und Werte der eingesetzten Helden ins Profil übernehmen
local function writeBackHeroes(profile)
	for heroId, unit in state.heroUnits do
		local entry = profile.heroes[heroId]
		if entry then
			entry.level = unit.level
			entry.xp = unit.xp
			local stats = {}
			for _, stat in UnitData.STAT_ORDER do
				stats[stat] = stat == "hp" and (unit.maxHp - (unit.mergeHp or 0)) or unit[stat]
			end
			entry.stats = stats
		end
	end
end

-- Ergebnis: Sterne zählen, Gold + Edelsteine für neue Sterne vergeben, speichern
local function finishBattle()
	local stage = Stages.get(state.stageId)
	local diff = Stages.getDifficulty(state.difficulty)
	local victory = state.result == "Victory"
	local done = { victory, victory and state.lost == 0, victory and state.turn <= state.turnGoal }
	local stars = 0
	for _, d in done do
		if d then
			stars += 1
		end
	end
	state.resultInfo = { victory = victory, done = done, stars = stars }

	local gold = victory and math.floor(stage.baseGold * diff.rewardMul * (1 + 0.25 * (stars - 1)))
		or math.floor(stage.baseGold * 0.1)
	for _, player in Players:GetPlayers() do
		local profile = ProfileStore.get(player)
		if profile then
			local previous = Stages.bestStars(profile, stage.id, diff.id)
			local newStars = math.max(0, stars - previous)
			local gems = newStars * diff.gemsPerStar
			profile.gold += gold
			profile.gems += gems
			if stars > previous then
				profile.stars[stage.id] = profile.stars[stage.id] or {}
				profile.stars[stage.id][diff.id] = stars
			end

			-- Helden-Fortschritt gehört dem Spieler, der den Trupp aufgestellt hat
			if player.UserId == state.ownerUserId then
				writeBackHeroes(profile)
			end
			-- Story: neuer Held beim ersten Sieg
			local newHero
			if victory and stage.unlockHero and not profile.heroes[stage.unlockHero] then
				profile.heroes[stage.unlockHero] = ProfileStore.newHeroEntry()
				newHero = stage.unlockHero
			end

			ProfileStore.save(player)
			sendProfile(player, { reward = { gold = gold, gems = gems, newStars = newStars, newHero = newHero } })
		end
	end
end

local function checkResult()
	if state.result then
		return true
	end
	local enemies, lordAlive = 0, false
	for _, u in state.units do
		if u.team == "Enemy" then
			enemies += 1
		end
		if u.isLord then
			lordAlive = true
		end
	end
	if not lordAlive then
		state.result = "Defeat"
	elseif enemies == 0 then
		state.result = "Victory"
	end
	if state.result then
		finishBattle()
		return true
	end
	return false
end

local function healOnForts(team)
	for _, u in state.units do
		local terrain = Grid.terrainAt(u.x, u.y)
		if u.team == team and terrain.heal and u.hp < u.maxHp then
			u.hp = math.min(u.maxHp, u.hp + math.ceil(u.maxHp * terrain.heal))
			UnitVisuals.update(u)
		end
	end
end

-- Kampf ausführen; die Clients animieren, der Server setzt die KP im Moment des Treffers
local function battle(attacker, defender)
	UnitVisuals.face(attacker.id, defender.x, defender.y)
	UnitVisuals.face(defender.id, attacker.x, attacker.y)
	pause(0.2)

	local result = Combat.resolve(attacker, defender, attacker.x, attacker.y, rng)
	BattleEvent:FireAllClients({ strikes = result.strikes })

	for _, s in result.strikes do
		pause(Config.IMPACT_TIME)
		local target = s.targetId == attacker.id and attacker or defender
		UnitVisuals.setHp(s.targetId, s.hpAfter, target.maxHp)
		pause(Config.STRIKE_TIME - Config.IMPACT_TIME)
	end
	pause(0.3)

	for _, pair in { { attacker, defender }, { defender, attacker } } do
		local unit, foe = pair[1], pair[2]
		if unit.team == "Player" and unit.hp > 0 then
			local dealt = false
			for _, s in result.strikes do
				if s.attackerId == unit.id and s.damage > 0 then
					dealt = true
				end
			end
			BattleEvent:FireAllClients({ exp = Combat.gainExperience(unit, foe, foe.hp <= 0, dealt, rng) })
		end
	end

	for _, u in { attacker, defender } do
		if u.hp <= 0 then
			if u.team == "Player" then
				state.lost += 1
			end
			state.units[u.id] = nil
			UnitVisuals.remove(u.id)
		else
			UnitVisuals.update(u)
		end
	end
end

local function runEnemyPhase()
	table.clear(undoStack)
	state.phase = "Enemy"
	state.busy = true
	for _, u in state.units do
		u.done = false
		UnitVisuals.update(u)
	end
	healOnForts("Enemy")
	broadcast()
	pause(1)

	local ids = {}
	for id, u in state.units do
		if u.team == "Enemy" then
			table.insert(ids, id)
		end
	end
	table.sort(ids, function(a, b)
		return tonumber(string.sub(a, 2)) < tonumber(string.sub(b, 2))
	end)

	for _, id in ids do
		local enemy = state.units[id]
		if enemy and not state.result then
			local plan = EnemyAI.plan(enemy, state.units)
			if plan then
				if #plan.path > 1 then
					BattleEvent:FireAllClients({ enemyMove = { unitId = enemy.id, x = plan.x, y = plan.y } })
					UnitVisuals.moveAlong(enemy, plan.path)
					enemy.x, enemy.y = plan.x, plan.y
				end
				local target = plan.targetId and state.units[plan.targetId]
				if target then
					battle(enemy, target)
				end
			end
			if state.units[id] then
				enemy.done = true
				UnitVisuals.update(enemy)
			end
			checkResult()
			broadcast()
			pause(0.25)
		end
	end

	if not state.result then
		state.turn += 1
		state.phase = "Player"
		for _, u in state.units do
			u.done = false
			UnitVisuals.update(u)
		end
		healOnForts("Player")
	end
	if enemySpeedBefore then
		state.speed = enemySpeedBefore
		UnitVisuals.setSpeed(state.speed)
		enemySpeedBefore = nil
	end
	state.busy = false
	broadcast()
end

-- Rückblende: Zustand vor der Aktion merken
local function pushUndo()
	if state.undoLeft <= 0 then
		return
	end
	local copy = {}
	for id, u in state.units do
		copy[id] = table.clone(u)
	end
	table.insert(undoStack, { units = copy, lost = state.lost })
end

local function undo()
	local snap = table.remove(undoStack)
	for id in state.units do
		UnitVisuals.remove(id, true)
	end
	state.units = snap.units
	state.lost = snap.lost
	for _, u in state.units do
		UnitVisuals.create(u)
		if u.heroId then
			state.heroUnits[u.heroId] = u -- Kopien ersetzen die alten Tabellen
		end
	end
	state.undoLeft -= 1
end

-- Bewegen + Aktion als ein Befehl; der Client zeigt die Bewegung vorher nur als Vorschau
local function handleAct(cmd)
	local unit = state.units[cmd.unitId]
	if not unit or unit.team ~= "Player" or unit.done then
		return false
	end
	if typeof(cmd.x) ~= "number" or typeof(cmd.y) ~= "number" then
		return false
	end

	local nodes = Grid.reachable(unit, state.units)
	local node = nodes[Grid.key(cmd.x, cmd.y)]
	if not node or not node.canStop then
		return false
	end

	local target
	if cmd.action == "Attack" then
		target = state.units[cmd.targetId]
		if not target or target.team == unit.team then
			return false
		end
		local weapon = UnitData.Weapons[unit.weapon]
		local d = Grid.dist(cmd.x, cmd.y, target.x, target.y)
		if d < weapon.minRange or d > weapon.maxRange then
			return false
		end
	elseif cmd.action ~= "Wait" then
		return false
	end

	pushUndo()
	state.busy = true
	broadcast()

	UnitVisuals.moveAlong(unit, Grid.pathTo(nodes, cmd.x, cmd.y))
	unit.x, unit.y = cmd.x, cmd.y
	if target then
		battle(unit, target)
	end
	if state.units[unit.id] then
		unit.done = true
		UnitVisuals.update(unit)
	end

	state.busy = false
	return true
end

local function afterAct()
	if checkResult() then
		broadcast()
		return
	end
	for _, u in state.units do
		if u.team == "Player" and not u.done then
			broadcast()
			return
		end
	end
	runEnemyPhase()
end

-- Befehle ------------------------------------------------------------------
local function handleCommand(player, cmd)
	local t = cmd.type

	if t == "SetSpeed" then
		if state.mode == "Battle" and state.ownerUserId ~= player.UserId then return false end
		if cmd.speed == 1 or cmd.speed == 2 or cmd.speed == 3 then
			if cmd.speed == 3 and state.phase == "Enemy" and not enemySpeedBefore then
				enemySpeedBefore = state.speed
			end
			state.speed = cmd.speed
			UnitVisuals.setSpeed(cmd.speed)
			broadcast()
			return true
		end
		return false
	end

	if state.busy then
		return false
	end

	-- Während eines Kampfes darf nur dessen Besitzer Kampfbefehle senden
	local battleCommand = t ~= "StartStage" and t ~= "Recruit"
	if state.mode == "Battle" and battleCommand and state.ownerUserId ~= player.UserId then
		return false
	end

	if t == "StartStage" then
		local index = Stages.indexOf(cmd.stageId)
		local profile = ProfileStore.get(player)
		local free = state.mode == "Lobby" or (state.result and state.ownerUserId == player.UserId)
		if free and index and profile and Stages.isUnlocked(profile, index, cmd.difficulty) then
			setupStage(cmd.stageId, cmd.difficulty)
			state.ownerUserId = player.UserId -- nur dieser Spieler steuert den Kampf
			state.ownerName = player.DisplayName
			broadcast()
			return true
		end
	elseif t == "Retry" then
		if state.result then
			setupStage(state.stageId, state.difficulty)
			return true
		end
	elseif t == "ToLobby" then
		if state.mode == "Battle" then
			clearUnits()
			enemySpeedBefore = nil
			state = lobbyState(state.speed)
			broadcast()
			return true
		end
	elseif t == "Recruit" then
		local profile = ProfileStore.get(player)
		local banner = Recruit.getBanner(cmd.bannerId)
		local count = cmd.count
		local inOwnBattle = state.mode == "Battle" and state.ownerUserId == player.UserId
		if inOwnBattle or not profile or not banner or (count ~= 1 and count ~= 10) then
			return false
		end
		local cost = count == 10 and banner.costMulti or banner.costSingle
		if profile.gems < cost then
			return false
		end
		profile.gems -= cost
		local results = {}
		for _ = 1, count do
			local rarity, heroId = Recruit.roll(profile.pity, rng)
			local entry = profile.heroes[heroId]
			local isNew = entry == nil
			if isNew then
				profile.heroes[heroId] = ProfileStore.newHeroEntry()
			else
				entry.merges = math.min(Recruit.MAX_MERGES, (entry.merges or 0) + 1)
			end
			table.insert(results, { heroId = heroId, rarity = rarity, isNew = isNew })
		end
		ProfileStore.save(player)
		sendProfile(player, { recruitResult = results })
		return true
	elseif state.mode == "Battle" and state.phase == "Prep" then
		if t == "BeginBattle" then
			local profile = ProfileStore.get(player)
			if not profile or type(cmd.heroes) ~= "table" then
				return false
			end
			-- Gewählte Helden prüfen: im Besitz, keine Doppelten, Leon immer dabei und vorne
			local chosen, seen = { "leon" }, { leon = true }
			for _, id in cmd.heroes do
				if type(id) == "string" and not seen[id] and profile.heroes[id] and UnitData.Heroes[id]
					and #chosen < state.maxUnits then
					seen[id] = true
					table.insert(chosen, id)
				end
			end
			local stage = Stages.get(state.stageId)
			local unitsStart = os.clock()
			for i, heroId in chosen do
				local slot = stage.slots[i]
				spawnHero(heroId, profile.heroes[heroId], slot.x, slot.y)
			end
			print(("Missionsaufbau %s (Helden): Brett 0 ms, Figuren %.0f ms"):format(state.stageId, (os.clock() - unitsStart) * 1000))
			state.ownerUserId = player.UserId
			state.phase = "Player"
			broadcast()
			return true
		end
	elseif state.mode == "Battle" and state.phase == "Player" and not state.result then
		if t == "Undo" then
			if state.undoLeft > 0 and #undoStack > 0 then
				undo()
				broadcast()
				return true
			end
		elseif t == "EndTurn" then
			runEnemyPhase()
			return true
		elseif t == "Act" then
			if handleAct(cmd) then
				afterAct()
				return true
			end
		end
	end
	return false
end

Command.OnServerEvent:Connect(function(player, cmd)
	if typeof(cmd) ~= "table" then
		return
	end
	if not handleCommand(player, cmd) then
		StateUpdate:FireClient(player, snapshot()) -- abgelehnt: Client wieder synchronisieren
	end
end)

GetState.OnServerInvoke = function()
	return snapshot()
end

GetProfile.OnServerInvoke = function(player)
	local deadline = os.clock() + 15
	while not ProfileStore.get(player) and os.clock() < deadline do
		task.wait(0.1)
	end
	local profile = ProfileStore.get(player)
	return profile and profilePayload(profile)
end

-- Profile laden/speichern ----------------------------------------------------
local function onPlayerAdded(player)
	ProfileStore.load(player)
	sendProfile(player)
end

Players.PlayerAdded:Connect(onPlayerAdded)
for _, player in Players:GetPlayers() do
	task.spawn(onPlayerAdded, player)
end
Players.PlayerRemoving:Connect(function(player)
	-- Kampf-Besitzer geht: Kampf beenden, damit andere wieder Missionen starten können
	if state.mode == "Battle" and state.ownerUserId == player.UserId then
		task.spawn(function()
			while state.busy do
				task.wait(0.2)
			end
			clearUnits()
			enemySpeedBefore = nil
			state = lobbyState(state.speed)
			broadcast()
		end)
	end
	ProfileStore.release(player)
end)
game:BindToClose(function()
	ProfileStore.saveAll()
end)

remotes.Parent = ReplicatedStorage
