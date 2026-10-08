-- Gemeinsame Schritt-Daten und serverseitig verwendete Prüfungen der Tutorial-Wünsche.
local Stages = require(script.Parent.Stages)
local Grid = require(script.Parent.Grid)
local UnitData = require(script.Parent.UnitData)
local Tutorial = {}

Tutorial.Steps = {
	{
		{ kind = "Select", hero = "leon", mark = "hero", text = "Tippe auf den markierten Leon." },
		{ kind = "Move", hero = "leon", position = "move", mark = "tile", text = "Blaue Felder zeigen deine Bewegung. Tippe auf das goldene Feld." },
		{ kind = "Wait", hero = "leon", position = "move", mark = "wait", text = "Tippe auf Warten. Leon bewegt sich zum Feld und beendet seinen Zug." },
		{ kind = "Enemy", text = "Jetzt ist der Gegner am Zug. Beobachte, wie der Bandit näher kommt." },
		{ kind = "Select", hero = "leon", mark = "hero", text = "Du bist wieder am Zug. Tippe auf Leon." },
		{ kind = "Target", hero = "leon", target = "bandit", position = "move", mark = "target", text = "Tippe auf den Banditen neben Leon, um den Angriff vorzubereiten." },
		{ kind = "Forecast", hero = "leon", target = "bandit", position = "move", mark = "continue", text = "Die Vorschau zeigt Schaden und Trefferchance. Im Tutorial treffen deine Angriffe immer. Tippe auf Weiter." },
		{ kind = "Confirm", hero = "leon", target = "bandit", position = "move", mark = "confirm", text = "Tippe auf Angreifen, um den Kampf zu bestätigen." },
		{ kind = "Free", text = "Besiege die übrigen Gegner. Leon muss überleben." },
	},
	{
		{ kind = "Select", hero = "starter_mage", mark = "hero", text = "Helden haben verschiedene Stärken. Tippe auf die Magierin." },
		{ kind = "Target", hero = "starter_mage", target = "mage", position = "start", mark = "target", text = "Feuer hat Reichweite 1–2. Tippe auf den Banditen zwei Felder rechts von ihr." },
		{ kind = "Forecast", hero = "starter_mage", target = "mage", position = "start", mark = "continue", text = "Aus zwei Feldern kann dieser Nahkämpfer nicht kontern. In seiner Vorschau steht —. Tippe auf Weiter." },
		{ kind = "Confirm", hero = "starter_mage", target = "mage", position = "start", mark = "confirm", text = "Tippe auf Angreifen. Die Magierin bleibt außerhalb seiner Nahkampfreichweite." },
		{ kind = "Select", hero = "starter_knight", mark = "hero", text = "Der Ritter kann sieben Felder ziehen, Fußtruppen nur fünf. Tippe auf den Ritter." },
		{ kind = "Move", hero = "starter_knight", position = "move", mark = "tile", text = "Tippe auf das goldene Feld beim fernen Schützen. Deine Fußtruppen kommen in diesem Zug nicht so weit." },
		{ kind = "AttackMenu", hero = "starter_knight", position = "move", mark = "attack", text = "Der Ritter erreicht den Schützen. Tippe auf Angriff." },
		{ kind = "Target", hero = "starter_knight", target = "knight", position = "move", mark = "target", text = "Tippe auf den markierten Schützen." },
		{ kind = "Forecast", hero = "starter_knight", target = "knight", position = "move", mark = "continue", text = "Bögen haben Reichweite 2. Direkt neben dem Schützen kann er nicht kontern. Tippe auf Weiter." },
		{ kind = "Confirm", hero = "starter_knight", target = "knight", position = "move", mark = "confirm", text = "Bestätige den Angriff des Ritters." },
		{ kind = "Free", text = "Jetzt spielst du frei: Besiege den letzten Banditen mit deinem Team. Leon muss überleben." },
	},
}

function Tutorial.unlocked(profile)
	local status = profile and profile.tutorial and profile.tutorial.state
	return status == "done" or status == "skipped"
end

function Tutorial.step(tutorial)
	local list = tutorial and Tutorial.Steps[tutorial.mission]
	return list and list[tutorial.step]
end

function Tutorial.hero(state, id)
	for _, unit in state.units do
		if unit.heroId == id and unit.team == "Player" then return unit end
	end
	return nil
end

function Tutorial.target(state, id)
	for _, unit in state.units do
		if unit.tutorialTarget == id and unit.team == "Enemy" then return unit end
	end
	return nil
end

function Tutorial.position(state, step)
	local stage = Stages.List[state.tutorial.mission]
	if step.position == "move" then return stage.move end
	local index = table.find(stage.heroes, step.hero)
	return index and stage.slots[index]
end

local function readyHero(state, step, unitId)
	local unit = Tutorial.hero(state, step.hero)
	return unit and unit.id == unitId and unit.hp > 0 and not unit.done and unit or nil
end

local function destination(state, step, unit, x, y)
	local pos = Tutorial.position(state, step)
	if not pos or x ~= pos.x or y ~= pos.y then return false end
	local node = Grid.reachable(unit, state.units)[Grid.key(x, y)]
	return node and node.canStop == true
end

local function validTarget(state, step, unit, targetId, x, y)
	local target = Tutorial.target(state, step.target)
	if not target or target.id ~= targetId or target.hp <= 0 then return false end
	local weapon = UnitData.Weapons[unit.weapon]
	local distance = Grid.dist(x, y, target.x, target.y)
	return distance >= weapon.minRange and distance <= weapon.maxRange
end

-- Auswahl und Vorschau sind nur Schritte; Bewegung/Schaden entstehen ausschließlich durch Act.
function Tutorial.checkpoint(state, cmd)
	local step = Tutorial.step(state.tutorial)
	if not step or step.kind ~= cmd.action or step.kind == "Free" or step.kind == "Enemy"
		or step.kind == "Wait" or step.kind == "Confirm" then return false end
	local unit = readyHero(state, step, cmd.unitId)
	if not unit then return false end
	if step.kind ~= "Select" and not destination(state, step, unit, cmd.x, cmd.y) then return false end
	if step.target and not validTarget(state, step, unit, cmd.targetId, cmd.x, cmd.y) then return false end
	state.tutorial.step += 1
	return true
end

function Tutorial.allowsAct(state, cmd)
	local step = Tutorial.step(state.tutorial)
	if not step then return false end
	if step.kind == "Free" then return true end
	local unit = readyHero(state, step, cmd.unitId)
	if not unit or not destination(state, step, unit, cmd.x, cmd.y) then return false end
	if step.kind == "Wait" then return cmd.action == "Wait" and cmd.targetId == nil end
	return step.kind == "Confirm" and cmd.action == "Attack"
		and validTarget(state, step, unit, cmd.targetId, cmd.x, cmd.y)
end

function Tutorial.afterAct(tutorial)
	local step = Tutorial.step(tutorial)
	if step and step.kind ~= "Free" then tutorial.step += 1 end
end

return Tutorial
