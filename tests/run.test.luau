local Runs = testModules.RunService
local Profiles = testModules.ProfileStore
local RC = testModules.RunConfig
local function expect(value, message) assert(value, message) end
local function newRun(seed)
	local profile = { heroes = {}, gold = 0, gems = 0 }
	for _, id in ipairs({ "leon", "bruno", "tobi" }) do profile.heroes[id] = Profiles.newHeroEntry() end
	expect(Runs.start(profile, { "leon", "bruno", "tobi" }, seed), "Laufstart")
	return profile
end
for seed = 1, 1000 do
	local profile = newRun(seed)
	local run = profile.run
	for depth = 1, RC.totalLevels() do
		expect(run.depth == depth, "Falsche Tiefe")
		if depth == 5 then
			expect(run.phase == "camp" and run.campExtra and run.cleared == 4, "Extra-Lager vor Boss fehlt")
			expect(not Runs.choose(run, 1), "Wahl im Lager")
			expect(Runs.leaveCamp(run) and run.depth == 5 and run.phase == "choice", "Extra-Lager zählt als Level")
		end
		local index = 1
		for i, option in ipairs(run.options) do if option.kind == "camp" then index = i end end
		expect(Runs.choose(run, index), "Option wählen")
		expect(not Runs.choose(run, index), "Doppelte Wahl")
		if run.phase == "camp" then
			local before = profile.gold + profile.gems
			expect(Runs.leaveCamp(run), "Wahllager verlassen")
			expect(profile.gold + profile.gems == before, "Lager gibt Kampfbelohnung")
		else
			local units = {}
			for _, id in ipairs(run.order) do
				local hp = Runs.maxHp(id, profile.heroes[id])
				units[id] = { hp = hp, maxHp = hp }
			end
			local info = Runs.finish(profile, units, true)
			expect(info.victory, "Sieg verloren")
		end
	end
	expect(profile.run == nil and run.cleared == 5 and run.maxTeam == 4, "Laufabschluss/Teamplatz")
end
print("OK: 1000 Laufabfolgen mit festen Bossen, Wahllagern und Extra-Lager.")

local Abilities = testModules.BossAbilities
local Grid = testModules.Grid
local Data = testModules.UnitData
local function enemy(kind, id, x, y)
	local def = Data.Enemies[kind]
	local unit = { id = id, name = def.name, class = def.class, family = def.family, weapon = def.weapon,
		x = x, y = y, hp = def.stats.hp, maxHp = def.stats.hp, str = def.stats.str,
		team = "Enemy", ai = def.ai, mov = def.mov, abilities = def.abilities }
	for stat, value in pairs(def.stats) do if stat ~= "hp" then unit[stat] = value end end
	return unit
end
Grid.setMap({ "........", "........", "........", "........", "........", "........" })
local captain = enemy("brigand_captain", "captain", 4, 3)
local abilityState = { units = { captain = captain }, turn = 1, reinforcementFields = { { x = 1, y = 1 }, { x = 8, y = 1 }, { x = 1, y = 2 } } }
local spawned, events = 0, {}
local function spawn(kind, cell)
	expect(not Grid.unitAt(abilityState.units, cell.x, cell.y), "Beschwörung auf belegtem Feld")
	spawned += 1
	local unit = enemy(kind, "spawn" .. spawned, cell.x, cell.y)
	abilityState.units[unit.id] = unit
end
local function emit(event) table.insert(events, copy(event)) end
local randomMax = { NextInteger = function(_, _, high) return high end }
local function process() Abilities.process(abilityState, spawn, emit, randomMax) end
process()
expect(spawned == 0, "Hauptmann ruft zu früh")
captain.hp = captain.maxHp * 0.4
process()
expect(spawned == 2 and events[1].type == "summon", "Hauptmann ruft nicht an Schwelle")
abilityState.turn = 2
process()
expect(spawned == 2, "Beschwörung mehrfach")
-- Ohne freie Felder darf der Auslöser nicht verbraucht werden.
local blockedCaptain = enemy("brigand_captain", "blocked", 1, 1)
blockedCaptain.hp = 1
Grid.setMap({ "." })
abilityState.units = { blocked = blockedCaptain }
process()
expect(not blockedCaptain.abilityState[1].used, "Volles Brett verbraucht Beschwörung")
Grid.setMap({ "........", "........", "........", "........", "........", "........" })
local boss = enemy("chieftain", "boss", 4, 3)
local near, far = enemy("brigand", "near", 4, 4), enemy("brigand", "far", 8, 6)
abilityState.units, abilityState.turn, spawned, events = { boss = boss, near = near, far = far }, 1, 0, {}
process()
expect(near.str == Data.Enemies.brigand.stats.str + 3 and far.str == Data.Enemies.brigand.stats.str, "Kriegsschrei-Radius")
expect(near.warcry and near.warcry.expiresTurn == 2, "Buffdauer")
process()
expect(near.str == Data.Enemies.brigand.stats.str + 3, "Kriegsschrei stapelt im selben Zug")
abilityState.turn = 2
boss.hp = boss.maxHp * 0.5
process()
expect(not near.warcry and near.str == Data.Enemies.brigand.stats.str, "Buff bleibt zu lange")
expect(spawned == 0 and #abilityState.reinforcementMarks == 3 and events[#events].type == "reinforce", "Vorwarnung fehlt")
process()
expect(spawned == 0, "Verstärkung erscheint in Ankündigungsphase")
-- Ein besetztes markiertes Feld bleibt markiert; keine Einheit überschreiben.
local marked = abilityState.reinforcementMarks[1]
abilityState.units.blocker = { id = "blocker", x = marked.x, y = marked.y, team = "Player", hp = 1 }
abilityState.turn = 3
process()
expect(spawned == 2 and #abilityState.reinforcementMarks == 1, "Belegtes Ankunftsfeld")
abilityState.units.blocker = nil
abilityState.turn = 4
process()
expect(spawned == 3 and #abilityState.reinforcementMarks == 0, "Ausstehende Verstärkung")
abilityState.turn = 5
process()
expect(spawned == 3, "Phase 2 wiederholt")
-- Festung halten bis zum ersten Treffer, auch nach vollständiger Heilung.
local target = { id = "hero", team = "Player", class = "Knight", weapon = "IronLance", x = 4, y = 6, hp = 30, maxHp = 30,
	str = 5, mag = 0, skl = 3, spd = 3, lck = 1, def = 4, res = 1, level = 1 }
boss.hp = boss.maxHp
expect(testModules.EnemyAI.plan(boss, { boss = boss, hero = target }) == nil, "Unverletzter Garrick bewegt sich")
boss.hp -= 1
local plan = testModules.EnemyAI.plan(boss, { boss = boss, hero = target })
expect(plan and (plan.x ~= boss.x or plan.y ~= boss.y), "Verletzter Garrick bleibt stehen")
boss.hp, boss.awakened = boss.maxHp, true
expect(testModules.EnemyAI.plan(boss, { boss = boss, hero = target }) ~= nil, "Geheilter Garrick schläft wieder ein")
local nodes = Grid.reachable(captain, { captain = captain })
for _, node in pairs(nodes) do expect(node.cost <= 3, "Hauptmann bewegt sich zu weit") end
print("OK: Bossfähigkeiten (Schwellen, Einmaligkeit, freie Felder, Vorwarnung, Buffdauer) und Boss-KI.")

for seed = 1, 1000 do
	for _, depth in ipairs({ 3, 5 }) do
		local profile = newRun(seed)
		local run = profile.run
		run.depth, run.region = depth, "greenland"
		run.options = testModules.LevelGen.makeOptions(seed, depth, "greenland")
		expect(Runs.choose(run, 1), "Bosswahl")
		local stage, living = Runs.stage(run)
		expect(#living == 3 and #stage.slots == RC.MAX_TEAM, "Boss-Aufstellung")
		expect(stage.enemies[1].kind == (depth == 3 and "brigand_captain" or "chieftain"), "Bosskarte über RunService")
	end
end
print("OK: 2000 Bosskarten über die echte Laufanbindung.")

local serverProfile = Profiles.get(player)
serverProfile.tutorial.state = "skipped"
serverProfile.heroes.bruno, serverProfile.heroes.tobi = Profiles.newHeroEntry(), Profiles.newHeroEntry()
for _, depth in ipairs({ 3, 5 }) do
	expect(testServer.command(player, { type = "StartRun", heroes = { "leon", "bruno", "tobi" } }), "Server-Laufstart")
	local run = serverProfile.run
	run.depth, run.cleared = depth, depth - 1
	run.options = testModules.LevelGen.makeOptions(run.seed, depth, "greenland")
	expect(testServer.command(player, { type = "ChooseLevel", index = 1 }), "Server-Bosswahl")
	local state = testServer.state()
	local bossId, guardAlive
	for id, unit in pairs(state.units) do
		if unit.enemyKind == state.run.bossId then bossId = id
		elseif unit.team == "Enemy" then guardAlive = true end
	end
	expect(bossId and guardAlive and not testServer.checkResult(), "Boss fehlt/Sieg zu früh")
	state.units[bossId] = nil
	expect(testServer.checkResult() and state.result == "Victory", "Kein sofortiger Bosssieg")
	for _, unit in pairs(state.units) do expect(unit.team ~= "Enemy", "Leibwache flieht nicht") end
	expect(state.resultInfo.reward.gold == RC.rewardAmount("gold", depth), "Bossbelohnung")
	if depth == 5 then
		expect(run.maxTeam == 4 and state.resultInfo.teamPlaceGained == 1 and not serverProfile.run, "Teamplatz bei Laufende")
	else expect(run.maxTeam == 3 and state.resultInfo.teamPlaceGained == 0, "Teamplatz beim Miniboss") end
	expect(testServer.command(player, { type = "ToLobby" }), "Ergebnis verlassen")
	serverProfile.run = nil
end
print("OK: Sofortiger Boss-/Miniboss-Sieg mit lebender Leibwache, Belohnung und Teamplatz.")

local campProfile = newRun(77)
local camp = campProfile.run
camp.phase, camp.campExtra, camp.depth, camp.cleared = "camp", true, 5, 4
camp.options = testModules.LevelGen.makeOptions(camp.seed, 5, "greenland")
camp.team.leon.hp = 1
camp.team.bruno.hp, camp.team.bruno.alive = 0, false
campProfile.heroes.starter_mage = Profiles.newHeroEntry()
expect(Runs.enterCamp(campProfile) and camp.team.leon.hp == Runs.maxHp("leon", campProfile.heroes.leon), "Lager heilt nicht voll")
expect(camp.team.bruno.hp == 0 and not camp.team.bruno.alive, "Lager belebt kostenlos wieder")
expect(not Runs.swap(campProfile, 1, "starter_mage", "tobi"), "Veralteter Tausch akzeptiert")
expect(not Runs.swap(campProfile, 4, "starter_mage", nil), "Teamgrenze überschritten")
expect(not Runs.swap(campProfile, 0, "starter_mage", nil) and not Runs.swap(campProfile, 1.5, "starter_mage", "leon"), "Ungültiger Platz")
expect(not Runs.swap(campProfile, 1, "tobi", "leon") and not Runs.swap(campProfile, 1, "unknown", "leon"), "Doppelter/unbekannter Held")
expect(not Runs.swap(campProfile, 1, "alina", "leon"), "Nicht besessener Held")
expect(Runs.swap(campProfile, 2, "starter_mage", "bruno"), "Gefallenen austauschen")
expect(not camp.team.bruno.alive and camp.team.starter_mage.hp == Runs.maxHp("starter_mage", campProfile.heroes.starter_mage), "Todesstatus/neuer Held")
expect(Runs.swap(campProfile, 2, "bruno", "starter_mage") and not camp.team.bruno.alive, "Gefallener kehrt lebendig zurück")
local goldPrice = RC.revivePrice(1, "gold")
campProfile.gold, campProfile.gems = goldPrice - 1, RC.REVIVE_GEMS - 1
expect(not Runs.revive(campProfile, "bruno", "gold") and not Runs.revive(campProfile, "bruno", "gems"), "Zu wenig Guthaben")
expect(campProfile.gold == goldPrice - 1 and campProfile.gems == RC.REVIVE_GEMS - 1 and not camp.team.bruno.alive, "Abgelehnter Kauf verändert Profil")
expect(not Runs.revive(campProfile, "bruno", "earned") and not Runs.revive(campProfile, "unknown", "gold"), "Ungültige Wiederbelebung")
campProfile.gold = goldPrice
expect(Runs.revive(campProfile, "bruno", "gold") and campProfile.gold == 0 and camp.team.bruno.hp == Runs.maxHp("bruno", campProfile.heroes.bruno), "Gold-Wiederbelebung")
expect(not Runs.revive(campProfile, "bruno", "gold"), "Lebenden erneut kaufen")
camp.team.bruno.alive, camp.team.bruno.hp = false, 0
campProfile.gems = RC.REVIVE_GEMS
expect(Runs.revive(campProfile, "bruno", "gems") and campProfile.gems == 0 and camp.team.bruno.alive, "Edelstein-Wiederbelebung")
expect(RC.revivePrice(7, "gold") == RC.REVIVE_GOLD_BASE + 7 * RC.REVIVE_GOLD_PER_LEVEL, "Levelpreis")
camp.maxTeam = 4
expect(Runs.swap(campProfile, 4, "starter_mage", nil) and #camp.order == 4, "Leeren neuen Teamplatz füllen")
camp.maxTeam = 3
table.remove(camp.order, 4)
-- Echte Profilnormalisierung über Save/Load, mit inaktivem gefallenem Helden.
camp.team.starter_mage.alive, camp.team.starter_mage.hp = false, 0
local reloadPlayer = { UserId = 88 }
records.p_88 = copy(campProfile)
local loaded = Profiles.load(reloadPlayer)
expect(loaded.run and loaded.run.phase == "camp" and loaded.run.campExtra and not loaded.run.team.starter_mage.alive, "Extra-Lager/Todeshistorie nicht wiederhergestellt")
expect(Runs.leaveCamp(loaded.run) and loaded.run.depth == 5 and loaded.run.cleared == 4, "Extra-Lager beim Wiederkommen")
local optionProfile, campIndex
for seed = 1, 1000 do
	local candidate = newRun(seed)
	for i, option in ipairs(candidate.run.options) do
		if option.kind == "camp" then optionProfile, campIndex = candidate, i; break end
	end
	if optionProfile then break end
end
expect(optionProfile and Runs.choose(optionProfile.run, campIndex), "Kein Wahllager")
Runs.enterCamp(optionProfile)
records.p_89 = copy(optionProfile)
loaded = Profiles.load({ UserId = 89 })
expect(loaded.run and loaded.run.phase == "camp" and not loaded.run.campExtra, "Wahllager nicht wiederhergestellt")
expect(Runs.leaveCamp(loaded.run) and loaded.run.depth == 2 and loaded.run.cleared == 1 and loaded.gold == 0, "Wahllager zählt falsch")
local broken = copy(campProfile)
broken.run.version = nil
records.p_90 = broken
loaded = Profiles.load({ UserId = 90 })
expect(not loaded.run and loaded.heroes.bruno and loaded.gems == broken.gems, "Altlauf beschädigt Sammlung")
broken = copy(campProfile)
broken.run.maxTeam = RC.MAX_TEAM
records.p_91 = broken
expect(not Profiles.load({ UserId = 91 }).run, "Gefälschte Teamgröße bleibt erhalten")
-- Ein Lager darf vorübergehend nur Tote enthalten, aber ohne lebenden Helden nicht weitergehen.
for _, id in ipairs(camp.order) do camp.team[id].hp, camp.team[id].alive = 0, false end
expect(not Runs.leaveCamp(camp), "Nur Tote verlassen das Lager")
records.p_92 = copy(campProfile)
expect(Profiles.load({ UserId = 92 }).run ~= nil, "Lager mit ausschließlich Gefallenen verworfen")
camp.phase = "choice"
expect(not Runs.swap(campProfile, 1, "starter_mage", "leon") and not Runs.revive(campProfile, "leon", "gold"), "Lageraktion außerhalb Lager")
-- Serverbefehle: Phase, fremder Spieler, Heilung, kein Brettaufbau und keine Belohnung.
serverProfile.run = copy(optionProfile.run)
serverProfile.run.depth, serverProfile.run.cleared, serverProfile.run.phase = 1, 0, "choice"
serverProfile.run.options = testModules.LevelGen.makeOptions(optionProfile.run.seed, 1, "greenland")
serverProfile.run.current, serverProfile.run.campExtra = nil, false
serverProfile.run.team.leon.hp = 1
expect(testServer.command(player, { type = "ChooseLevel", index = campIndex }), "Server-Lagerwahl")
expect(testServer.state().mode == "Lobby" and serverProfile.run.phase == "camp" and serverProfile.run.team.leon.hp > 1, "Lager startet Kampf/heilt nicht")
expect(not testServer.command(player, { type = "ResumeLevel" }), "Kampf im Lager fortsetzen")
expect(not testServer.command(other, { type = "CampSwap", slot = 1, heroId = "bruno", outgoing = "leon" }), "Fremdes Lager verändert")
expect(testServer.command(player, { type = "CampSwap", slot = 2, heroId = "starter_mage", outgoing = "bruno" }), "Server-Tausch")
serverProfile.run.team.starter_mage.hp, serverProfile.run.team.starter_mage.alive = 0, false
serverProfile.gold = RC.revivePrice(1, "gold")
expect(testServer.command(player, { type = "CampRevive", heroId = "starter_mage", currency = "gold" }), "Server-Wiederbelebung")
expect(testServer.command(player, { type = "LeaveCamp" }) and serverProfile.run.depth == 2, "Server-Lager verlassen")
expect(not testServer.command(player, { type = "CampRevive", heroId = "starter_mage", currency = "gold" }), "Server-Lagerphase umgangen")
serverProfile.run = nil
print("OK: Lagerheilung, Wechsel/Todeshistorie, beide Währungen, Guthaben/Preise, Teamgrenze, Wiederkommen und Serverbefehle.")
