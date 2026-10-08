-- Server: Tutorial, Läufe, Kampfablauf und Gegnerphase
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

Players.CharacterAutoLoads = true -- Avatare laufen im Thronsaal

local Shared = ReplicatedStorage:WaitForChild("Shared")
local UnitData = require(Shared.UnitData)
local Grid = require(Shared.Grid)
local Combat = require(Shared.Combat)
local Stages = require(Shared.Stages)
local Recruit = require(Shared.Recruit)
local RunConfig = require(Shared.RunConfig)
local RunService = require(script.Parent.RunService)

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
Grid.setMap(Stages.List[1].map) -- Kulisse vor dem ersten Kampf
BoardBuilder.build()
HubBuilder.build()
task.spawn(UnitVisuals.buildHeroTemplates)

local rng = Random.new()
local nextUnitId = 0
local undoStack = {}
local enemySpeedBefore
local pendingAbandon = {}

local function lobbyState(speed)
	return { mode = "Lobby", units = {}, phase = "Prep", turn = 1, busy = false, speed = speed or 1, undoLeft = 0, lost = 0 }
end

local state = lobbyState()

local function snapshot()
	return {
		mode = state.mode,
		stageId = state.stageId,
		units = state.units,
		phase = state.phase,
		turn = state.turn,
		busy = state.busy,
		result = state.result,
		resultInfo = state.resultInfo,
		speed = state.speed,
		battleScenes = state.battleScenes,
		undoLeft = state.undoLeft,
		canUndo = #undoStack > 0,
		lost = state.lost,
		maxUnits = state.maxUnits,
		ownerUserId = state.ownerUserId,
		ownerName = state.ownerName,
		run = state.run,
		map = state.map,
	}
end

local function broadcast()
	StateUpdate:FireAllClients(snapshot())
end

-- Wartezeiten richten sich nach dem gewählten Tempo
local function pause(t)
	task.wait(t / state.speed)
end

local function copyRun(value)
	if type(value) ~= "table" then return value end
	local copy = {}
	for key, item in pairs(value) do copy[key] = copyRun(item) end
	return copy
end

local function profilePayload(profile)
	return {
		gold = profile.gold,
		gems = profile.gems,
		heroes = profile.heroes,
		pity = profile.pity,
		settings = profile.settings,
		saveOk = profile.saveOk,
		run = copyRun(profile.run),
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

local function setupBattle(stage, opts)
	enemySpeedBefore = nil
	clearUnits()
	Grid.setMap(stage.map)
	local boardStart = os.clock()
	BoardBuilder.build(stage.region)
	local board = workspace:FindFirstChild("Board")
	if board then board:SetAttribute("RunSeed", opts.run and opts.run.seed) end
	local boardDuration = os.clock() - boardStart

	-- Eigene Helden werden nach dem Brettaufbau aufgestellt
	state = {
		mode = "Battle",
		ownerUserId = state.ownerUserId,
		ownerName = state.ownerName,
		ownerPlayer = state.ownerPlayer,
		stageId = opts.stageId,
		run = opts.run,
		map = stage.map,
		units = {},
		heroUnits = {}, -- heroId -> Einheit (auch gefallene), für das Zurückschreiben des Fortschritts
		phase = "Prep",
		turn = 1,
		busy = true, -- Aufbau sperren, bis Gegner und Helden bereit sind
		speed = state.speed,
		battleScenes = state.battleScenes,
		undoLeft = 0,
		lost = 0,
		maxUnits = #stage.slots,
	}

	local unitsStart = os.clock()
	local enemies = table.clone(stage.enemies)
	for _, e in enemies do
		local unit = makeUnit(UnitData.Enemies[e.kind], e.x, e.y, "Enemy", e.level)
		state.units[unit.id] = unit
		UnitVisuals.create(unit)
	end
	print(("Missionsaufbau %s: Brett %.0f ms, Figuren %.0f ms"):format(opts.stageId or "Lauf", boardDuration * 1000, (os.clock() - unitsStart) * 1000))

end

-- Held aus dem Profil auf ein Startfeld stellen (gespeicherte Werte, Level, Verschmelzungen)
local function spawnHero(heroId, entry, x, y, hp)
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
	unit.hp = hp and math.clamp(hp, 1, unit.maxHp) or unit.maxHp
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

local function beginRunLevel(player, profile)
	local run = profile.run
	local stage, living = RunService.stage(run)
	local option = run.options[run.current]
	state.ownerUserId = player.UserId
	state.ownerName = player.DisplayName
	state.ownerPlayer = player
	state.battleScenes = profile.settings.battleScenes
	setupBattle(stage, { run = {
		depth = run.depth, region = run.region, themeId = option.themeId,
		totalLevels = RunConfig.totalLevels(), seed = option.seed,
	} })
	for i, id in ipairs(living) do
		local slot = stage.slots[i]
		spawnHero(id, profile.heroes[id], slot.x, slot.y, run.team[id].hp)
	end
	state.phase = "Player"
	state.busy = false
	broadcast()
end

local function finishRunBattle()
	local player = state.ownerPlayer
	local profile = player and ProfileStore.get(player)
	if not profile or not profile.run then return end
	writeBackHeroes(profile)
	state.resultInfo = RunService.finish(profile, state.heroUnits, state.result == "Victory")
	local wasBusy = state.busy
	state.busy = true
	ProfileStore.save(player, true)
	state.busy = wasBusy
	sendProfile(player)
end

-- Tutorial-Abschluss wird im nächsten Planschritt an das Profil angebunden.
local function finishBattle()
	if state.run then finishRunBattle(); return end
	state.resultInfo = { victory = state.result == "Victory" }
end

local function checkResult()
	if state.result then
		return true
	end
	local enemies, players, lordAlive = 0, 0, false
	for _, u in state.units do
		if u.team == "Enemy" then
			enemies += 1
		end
		if u.team == "Player" then players += 1 end
		if u.team == "Player" and u.isLord then
			lordAlive = true
		end
	end
	if (state.run and players == 0) or (not state.run and not lordAlive) then
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
	-- Diese Einstellung gilt für die gesamte Schlagfolge, auch beim Umschalten.
	local scenes = state.battleScenes ~= false
	BattleEvent:FireAllClients({
		strikes = result.strikes, battleScenes = scenes, speed = state.speed,
		positions = { [attacker.id] = { x = attacker.x, y = attacker.y }, [defender.id] = { x = defender.x, y = defender.y } },
	})
	if scenes then pause(Config.FEEL.battleSceneIntro) end

	for _, s in result.strikes do
		pause(Config.IMPACT_TIME)
		local target = s.targetId == attacker.id and attacker or defender
		UnitVisuals.setHp(s.targetId, s.hpAfter, target.maxHp)
		pause(Config.STRIKE_TIME - Config.IMPACT_TIME)
	end
	if scenes then pause(Config.FEEL.battleSceneOutro) end
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
				-- Im Lauf sofort festhalten: Abbrechen und Neustarten belebt Gefallene nicht wieder.
				local owner = state.run and u.heroId and state.ownerPlayer
				local profile = owner and ProfileStore.get(owner)
				local member = profile and profile.run and profile.run.team[u.heroId]
				if member then
					member.alive = false
					member.hp = 0
					ProfileStore.save(owner)
				end
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

local function abandonRun(player)
	local profile = ProfileStore.get(player)
	if not profile or not profile.run or pendingAbandon[player]
		or (state.mode == "Battle" and state.ownerUserId ~= player.UserId) then return false end
	pendingAbandon[player] = true
	task.spawn(function()
		while state.busy do task.wait(0.2) end
		if ProfileStore.get(player) == profile and profile.run then
			if state.mode == "Battle" and state.ownerUserId == player.UserId and not state.result then
				writeBackHeroes(profile)
			end
			local info = RunService.abandon(profile)
			clearUnits()
			enemySpeedBefore = nil
			state = lobbyState(state.speed)
			state.result = "Abandoned"
			state.resultInfo = info
			state.ownerUserId = player.UserId
			state.ownerName = player.DisplayName
			state.busy = true
			ProfileStore.save(player, true)
			state.busy = false
			sendProfile(player)
			broadcast()
		end
		pendingAbandon[player] = nil
	end)
	return true
end

-- Befehle ------------------------------------------------------------------
local function handleCommand(player, cmd)
	local t = cmd.type
	if t == "AbandonRun" then return abandonRun(player) end
	if pendingAbandon[player] then return false end
	if t == "SetBattleScenes" then
		if state.mode == "Battle" and state.ownerUserId ~= player.UserId then return false end
		local profile = ProfileStore.get(player)
		if not profile or typeof(cmd.on) ~= "boolean" then return false end
		profile.settings.battleScenes = cmd.on
		state.battleScenes = cmd.on
		ProfileStore.save(player)
		sendProfile(player)
		broadcast()
		return true
	end

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
	local battleCommand = t ~= "Recruit"
	if state.mode == "Battle" and battleCommand and state.ownerUserId ~= player.UserId then
		return false
	end

	local profile = ProfileStore.get(player)
	local free = state.mode == "Lobby" or (state.result and state.ownerUserId == player.UserId)
	if t == "StartRun" then
		if state.mode ~= "Lobby" or not profile or not RunService.start(profile, cmd.heroes, rng:NextInteger(1, 2147483646)) then return false end
		state = lobbyState(state.speed)
		state.ownerUserId = player.UserId
		state.ownerPlayer = player
		state.busy = true
		ProfileStore.save(player, true)
		state.busy = false
		sendProfile(player)
		broadcast()
		return true
	elseif t == "ChooseLevel" then
		if not free or not profile or not RunService.choose(profile.run, cmd.index) then return false end
		state.ownerUserId = player.UserId
		state.ownerPlayer = player
		state.busy = true
		ProfileStore.save(player, true) -- Wahl festhalten, bevor das Brett entsteht
		sendProfile(player)
		beginRunLevel(player, profile)
		return true
	elseif t == "ResumeLevel" then
		if not free or not profile or not profile.run or not profile.run.current then return false end
		state.busy = true
		beginRunLevel(player, profile)
		return true
	elseif t == "ToLobby" then
		-- Bei Ladefehlern zurück zur Laufwahl; current und die KP vor dem Level bleiben erhalten.
		if state.mode == "Battle" or state.result then
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
		if inOwnBattle or not profile or profile.run or not banner or (count ~= 1 and count ~= 10) then
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
	elseif state.mode == "Battle" and state.phase == "Player" and not state.result then
		if t == "Undo" then
			if not state.run and state.undoLeft > 0 and #undoStack > 0 then
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
	-- Erst die laufende Aktion abwarten; Lauf-KP bleiben beim Stand vor dem Level.
	if state.ownerUserId == player.UserId then
		while state.busy or pendingAbandon[player] do task.wait(0.2) end
		clearUnits()
		enemySpeedBefore = nil
		state = lobbyState(state.speed)
		broadcast()
	end
	ProfileStore.release(player)
end)
game:BindToClose(function()
	ProfileStore.saveAll()
end)

remotes.Parent = ReplicatedStorage
