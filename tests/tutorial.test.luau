-- Beide geführten Missionen, Fehltipps, Profilschutz und Neustarts ohne Studio.
local Tutorial, Guide = testModules.Tutorial, testModules.TutorialGuide
local Profiles, Config, Grid = testModules.ProfileStore, testModules.Config, testModules.Grid
local checks = 0
local function expect(ok, message)
	checks += 1
	assert(ok, message)
end
local function command(cmd, who)
	local accepted = testServer.command(who or player, cmd)
	Guide.update(testServer.snapshot())
	return accepted
end
local ui = { toast = function() end }
Guide.init(ui, function(cmd) expect(command(cmd), "Client-Schritt abgelehnt") end, nil)
local function state() return testServer.state() end
local function hero(id) return Tutorial.hero(state(), id) end
local function checkpoint(kind, id, pos, target)
	local data = { unitId = hero(id).id, x = pos and pos.x, y = pos and pos.y, targetId = target and target.id }
	expect(Guide.allow(kind, data), "Client-Schritt gesperrt: " .. kind)
	Guide.checkpoint(kind, data)
end
local function act(id, pos, action, target)
	local cmd = { type = "Act", unitId = hero(id).id, x = pos.x, y = pos.y, action = action,
		targetId = target and target.id, tutorialId = state().tutorial.id, step = state().tutorial.step }
	expect(Guide.allow(action == "Wait" and "Wait" or "Confirm", cmd), "Client-Aktion gesperrt")
	expect(command(cmd), "Server-Aktion abgelehnt")
end
local profile = Profiles.get(player)
expect(profile.tutorial.state == "new", "Neues Profil braucht Tutorial")
local count = 0
for _ in pairs(profile.heroes) do count += 1 end
expect(count == 3 and profile.heroes.leon and profile.heroes.starter_mage and profile.heroes.starter_knight, "Genau drei neue Starter")
expect(not table.find(testModules.Recruit.pool(3), "starter_mage"), "Starter im Gacha")
expect(table.find(testModules.Recruit.pool(3), "tobi") and table.find(testModules.Recruit.pool(2), "bruno"), "Alte Starter fehlen im Gacha")
records.p_3 = { gold = 42, gems = 7, heroes = { bruno = { level = 1, xp = 0, merges = 0 }, tobi = { level = 4, xp = 3, merges = 0 } }, stars = { s1 = { Easy = 2 } } }
local old = { UserId = 3 }
local existing = Profiles.load(old)
expect(existing.tutorial.state == "done" and existing.heroes.bruno and existing.heroes.tobi.level == 4, "Altprofil beschädigt")
expect(existing.heroes.starter_mage and existing.heroes.starter_knight and existing.stars.s1.Easy == 2, "Migration ergänzt nicht")
records.p_4 = { heroes = { leon = { level = 1 } } }
expect(Profiles.load({ UserId = 4 }).tutorial.state == "done", "Gespeicherte Level-1-Helden erkennen")
records.p_5 = { stars = { s2 = { Normal = 1 } } }
expect(Profiles.load({ UserId = 5 }).tutorial.state == "done", "Alte Sterne erkennen")
expect(not command({ type = "StartRun", heroes = testModules.UnitData.STARTER_HEROES }), "Lauf vor Tutorial erlaubt")
expect(not command({ type = "TutorialChoice", play = "ja" }), "Ungültige Wahl akzeptiert")
expect(not command({ type = "StartTutorial", mission = 2, replay = false }), "M2 ohne M1 erlaubt")
expect(command({ type = "TutorialChoice", play = true }), "Tutorial startet nicht")
expect(hero("leon") and not hero("starter_mage"), "M1-Team falsch")
expect(not command({ type = "EndTurn" }) and not command({ type = "SetSpeed", speed = 2 }) and not command({ type = "SetBattleScenes", on = true }), "Tutorial-Sperre fehlt")
expect(not command({ type = "TutorialChoice", play = false }, other), "Zuschauer verändert Kampf")
local function playMission1(expectedGold, expectedState)
	expectedGold, expectedState = expectedGold or 0, expectedState or "new"
	local stage = testModules.Stages.List[1]
	expect(not Guide.allow("Move", { unitId = hero("leon").id, x = 1, y = 1 }), "Fehltipp freigegeben")
	expect(not command({ type = "Act", unitId = hero("leon").id, x = 2, y = 3, action = "Wait" }), "Direktaktion umgeht Schritte")
	checkpoint("Select", "leon")
	expect(not Guide.allow("Move", { unitId = hero("leon").id, x = 1, y = 1 }), "Falsches Feld freigegeben")
	expect(not command({ type = "TutorialStep", action = "Move", unitId = hero("leon").id, x = 1, y = 1,
		tutorialId = state().tutorial.id, step = state().tutorial.step }), "Server akzeptiert falsches Feld")
	checkpoint("Move", "leon", stage.move)
	act("leon", stage.move, "Wait")
	expect(state().tutorial.step == 5 and state().turn == 2, "Gegnerzug endet nicht am Auswahl-Schritt")
	local target = Tutorial.target(state(), "bandit")
	expect(target.x == stage.enemyMove.x and target.y == stage.enemyMove.y and hero("leon").hp == hero("leon").maxHp, ("Gegnerzug nicht sicher: %d,%d; KP %d/%d"):format(target.x, target.y, hero("leon").hp, hero("leon").maxHp))
	checkpoint("Select", "leon")
	checkpoint("Target", "leon", stage.move, target)
	expect(not command({ type = "Act", unitId = hero("leon").id, x = stage.move.x, y = stage.move.y, action = "Attack", targetId = target.id,
		tutorialId = state().tutorial.id, step = state().tutorial.step }), "Vorschau übersprungen")
	checkpoint("Forecast", "leon", stage.move, target)
	act("leon", stage.move, "Attack", target)
	expect(state().result == "Victory" and profile.tutorial.state == expectedState and profile.gold == expectedGold, "M1 belohnt vorzeitig")
end
-- Niederlage und Neustart setzen Schritte, Aufstellung und KP zurück.
local firstId = state().tutorial.id
state().units[hero("leon").id] = nil
testServer.checkResult()
expect(state().result == "Defeat", "Lord-Niederlage fehlt")
expect(command({ type = "StartTutorial", mission = 1, replay = false }), "M1-Neustart fehlt")
expect(state().tutorial.id ~= firstId and state().tutorial.step == 1, "Neustart übernimmt alte Schritte")
expect(not command({ type = "TutorialStep", action = "Select", unitId = hero("leon").id, tutorialId = firstId, step = 1 }), "Veralteter Wunsch akzeptiert")
playMission1()
local function playMission2(expectGold, testDefeat)
	expect(command({ type = "StartTutorial", mission = 2, replay = state().tutorial.replay }), "M2 startet nicht")
	local stage = testModules.Stages.List[2]
	local mage, knight, target = hero("starter_mage"), hero("starter_knight"), Tutorial.target(state(), "mage")
	expect(mage and knight and hero("leon"), "M2-Team falsch")
	expect(not Guide.allow("Select", { unitId = knight.id }), "Falscher Held freigegeben")
	checkpoint("Select", "starter_mage")
	checkpoint("Target", "starter_mage", stage.slots[2], target)
	local forecast = testModules.Combat.forecast(mage, target, mage.x, mage.y)
	expect(forecast.attacker.hit == 100 and forecast.defender.count == 0 and Grid.dist(mage.x, mage.y, target.x, target.y) == 2, "Magier-Reichweite/Konter falsch")
	checkpoint("Forecast", "starter_mage", stage.slots[2], target)
	act("starter_mage", stage.slots[2], "Attack", target)
	expect(#strikes == 1 and strikes[1].hit and mage.hp == mage.maxHp, "Magierin wird gekontert")
	local pos = stage.move
	expect(Grid.reachable(knight, state().units)[Grid.key(pos.x, pos.y)].canStop, "Ritter erreicht Ziel nicht")
	local foot = table.clone(knight); foot.class = "Lord"
	expect(not Grid.reachable(foot, state().units)[Grid.key(pos.x, pos.y)], "Fußtruppe erreicht Ritter-Ziel")
	checkpoint("Select", "starter_knight")
	checkpoint("Move", "starter_knight", pos)
	checkpoint("AttackMenu", "starter_knight", pos)
	target = Tutorial.target(state(), "knight")
	checkpoint("Target", "starter_knight", pos, target)
	checkpoint("Forecast", "starter_knight", pos, target)
	act("starter_knight", pos, "Attack", target)
	expect(state().tutorial.step == 11 and not Guide.guided(), "Freier Abschnitt fehlt")
	for _, unit in state().units do if unit.team == "Enemy" then target = unit end end
	if testDefeat then
		local oldId = state().tutorial.id
		state().units[hero("leon").id] = nil
		testServer.checkResult()
		expect(state().result == "Defeat" and profile.gold == 0, "M2-Niederlage belohnt")
		playMission2(expectGold, false)
		expect(state().tutorial.id ~= oldId, "M2-Neustart übernimmt Schritte")
		return
	end
	act("leon", { x = 4, y = 3 }, "Attack", target)
	expect(state().result == "Victory" and profile.gold == expectGold, "M2-Abschluss/Belohnung falsch")
end
playMission2(Config.TUTORIAL.gold, true)
expect(profile.tutorial.state == "done" and profile.heroes.leon.level == 1 and profile.heroes.leon.xp == 0, "Tutorial-Fortschritt oder EP falsch")
expect(records.p_1.tutorial.state == "done", "Tutorial nicht gespeichert")
expect(not command({ type = "TutorialChoice", play = true }), "Wahl nach Abschluss erlaubt")
expect(command({ type = "StartTutorial", mission = 1, replay = true }), "Wiederholung fehlt")
-- Wiederholung mit hohem Profillevel bleibt bei den Übungswerten.
profile.heroes.leon.level = 30
expect(hero("leon").level == 1, "Wiederholung übernimmt Profilwerte")
local before = profile.gold
playMission1(before, "done")
playMission2(before)
expect(profile.heroes.leon.level == 30 and profile.heroes.leon.xp == 0, "Wiederholung verändert Profil")
expect(command({ type = "ToLobby" }), "Thronsaal fehlt")
expect(command({ type = "StartRun", heroes = testModules.UnitData.STARTER_HEROES }), "Lauf nach Tutorial fehlt")
expect(command({ type = "AbandonRun" }), "Lauf beenden fehlt")
expect(command({ type = "ToLobby" }), "Lauf-Ergebnis schließen fehlt")
expect(command({ type = "TutorialChoice", play = false }, other), "Überspringen fehlt")
expect(Profiles.get(other).tutorial.state == "skipped", "Skip nicht gespeichert")
expect(command({ type = "StartRun", heroes = testModules.UnitData.STARTER_HEROES }, other), "Lauf nach Skip fehlt")
print(("OK: %d Tutorial-Prüfungen (Missionen, Fehltipps, Migration, Neustart, Wiederholung, Lauf-Sperre). Studio/Handy ungetestet."):format(checks))
