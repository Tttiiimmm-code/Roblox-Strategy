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
	expect(profile.run == nil and run.cleared == 5, "Laufabschluss")
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
