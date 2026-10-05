-- Einfache Gegner-KI: bester Angriff in Reichweite, sonst auf den nächsten Spieler zubewegen
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local UnitData = require(Shared.UnitData)
local Grid = require(Shared.Grid)
local Combat = require(Shared.Combat)

local EnemyAI = {}

local function scoreAttack(enemy, target, x, y)
	local f = Combat.forecast(enemy, target, x, y)
	local a, d = f.attacker, f.defender
	local score = a.dmg * a.count * a.hit / 100
	if a.dmg * a.count >= target.hp then
		score += 40 * a.hit / 100 -- Kills bevorzugen
	end
	if target.isLord then
		score += 5
	end
	score -= d.dmg * d.count * d.hit / 100 * 0.5 -- Gegenangriff scheuen
	return score
end

-- Liefert { x, y, path, targetId? } oder nil (stehen bleiben)
function EnemyAI.plan(enemy, units)
	local weapon = UnitData.Weapons[enemy.weapon]
	local nodes = Grid.reachable(enemy, units)

	local best, bestScore = nil, -math.huge
	for _, node in nodes do
		if node.canStop then
			for _, target in Grid.targetsFrom(enemy, units, node.x, node.y) do
				local score = scoreAttack(enemy, target, node.x, node.y) - node.cost * 0.01
				if score > bestScore then
					bestScore = score
					best = { x = node.x, y = node.y, targetId = target.id }
				end
			end
		end
	end
	if best then
		best.path = Grid.pathTo(nodes, best.x, best.y)
		return best
	end

	if enemy.ai == "stationary" then
		return nil
	end

	-- Kein Ziel erreichbar: echten Weg zum nächstgelegenen Angriffsfeld suchen
	local far = Grid.reachable(enemy, units, 99)
	local goal
	for _, target in units do
		if target.team ~= enemy.team then
			for _, t in Grid.tilesInRange(target.x, target.y, weapon.minRange, weapon.maxRange) do
				local n = far[Grid.key(t.x, t.y)]
				if n and n.canStop and (not goal or n.cost < goal.cost) then
					goal = n
				end
			end
		end
	end
	if not goal then
		return nil
	end

	-- Dem Weg so weit folgen, wie die Bewegung reicht, und auf einem freien Feld anhalten
	local mov = UnitData.Classes[enemy.class].mov
	local path = Grid.pathTo(far, goal.x, goal.y)
	local stopIndex = 1
	for i, step in path do
		local n = far[Grid.key(step.x, step.y)]
		if n.cost > mov then
			break
		end
		if n.canStop then
			stopIndex = i
		end
	end
	local trimmed = table.move(path, 1, stopIndex, 1, {})
	local last = trimmed[#trimmed]
	return { x = last.x, y = last.y, path = trimmed }
end

return EnemyAI
