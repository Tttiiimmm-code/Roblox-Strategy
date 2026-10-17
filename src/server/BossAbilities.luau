-- Datengetriebene Fähigkeiten; Darstellung und Erzeugung über Server-Callbacks.
local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Grid = require(Shared.Grid)
local UnitData = require(Shared.UnitData)
local BossAbilities = {}

local function free(state, cell, kind)
	local terrain = Grid.terrainAt(cell.x, cell.y)
	local movement = UnitData.Classes[UnitData.Enemies[kind].class].moveType
	local cost = terrain and terrain.cost[movement]
	return cost and cost > 0 and cost < math.huge and not Grid.unitAt(state.units, cell.x, cell.y)
end

local function candidates(state, boss, ability)
	local cells = ability.type == "reinforce" and (state.reinforcementFields or {})
		or Grid.tilesInRange(boss.x, boss.y, 1, ability.radius)
	local result = {}
	for _, cell in ipairs(cells) do if free(state, cell, ability.kind) then table.insert(result, cell) end end
	table.sort(result, function(a, b)
		local da, db = Grid.dist(boss.x, boss.y, a.x, a.y), Grid.dist(boss.x, boss.y, b.x, b.y)
		if da ~= db then return da < db end
		if a.y ~= b.y then return a.y < b.y end
		return a.x < b.x
	end)
	return result
end

function BossAbilities.process(state, spawn, emit, random)
	-- Ein Buff hält Gegnerphase und folgende Spielerphase; vor der nächsten Anwendung entfernen.
	for _, unit in pairs(state.units) do
		if unit.warcry and state.turn >= unit.warcry.expiresTurn then
			unit.str -= unit.warcry.amount
			unit.warcry = nil
		end
	end
	local bosses = {}
	for _, unit in pairs(state.units) do
		if unit.team == "Enemy" and unit.hp > 0 and unit.abilities then table.insert(bosses, unit) end
	end
	table.sort(bosses, function(a, b) return a.id < b.id end)
	state.reinforcementMarks = {}
	for _, boss in ipairs(bosses) do
		boss.abilityState = boss.abilityState or {}
		for index, ability in ipairs(boss.abilities) do
			local memory = boss.abilityState[index] or {}
			boss.abilityState[index] = memory
			if ability.type == "warcry" then
				if (state.turn - 1) % ability.interval == 0 and memory.turn ~= state.turn then
					memory.turn = state.turn
					local affected = {}
					for _, unit in pairs(state.units) do
						if unit.team == boss.team and unit.family == ability.family and unit.hp > 0
							and Grid.dist(boss.x, boss.y, unit.x, unit.y) <= ability.radius then
							-- Mehrere Bosse stapeln denselben Buff nicht.
							if unit.warcry then unit.str -= unit.warcry.amount end
							unit.str += ability.strength
							unit.warcry = { amount = ability.strength, expiresTurn = state.turn + ability.duration }
							table.insert(affected, unit.id)
						end
					end
					emit({ type = "warcry", text = boss.name .. ": " .. ability.name .. " (+" .. ability.strength .. " Stärke)", units = affected })
				end
			elseif not memory.used then
				if ability.type == "summon" and boss.hp <= boss.maxHp * ability.threshold then
					local cells = candidates(state, boss, ability)
					local count = math.min(#cells, random:NextInteger(ability.count.min, ability.count.max))
					if count > 0 then
						memory.used = true
						for i = 1, count do spawn(ability.kind, cells[i]) end
						emit({ type = "summon", text = boss.name .. ": " .. ability.name })
					end
				elseif ability.type == "reinforce" then
					if not memory.pending and boss.hp <= boss.maxHp * ability.threshold then
						local cells = candidates(state, boss, ability)
						local count = math.min(#cells, random:NextInteger(ability.count.min, ability.count.max))
						if count > 0 then
							memory.pending = { turn = state.turn + ability.delay, cells = {} }
							for i = 1, count do table.insert(memory.pending.cells, cells[i]) end
							emit({ type = "reinforce", text = ability.name, cells = memory.pending.cells })
						end
					elseif memory.pending and state.turn >= memory.pending.turn then
						local blocked = {}
						for _, cell in ipairs(memory.pending.cells) do
							if free(state, cell, ability.kind) then spawn(ability.kind, cell)
							else table.insert(blocked, cell) end
						end
						memory.pending.cells = blocked
						if #blocked == 0 then
							memory.used, memory.pending = true, nil
							emit({ type = "arrival", text = "Die Verstärkung ist eingetroffen!" })
						end
					end
				end
			end
			if memory.pending then
				for _, cell in ipairs(memory.pending.cells) do table.insert(state.reinforcementMarks, cell) end
			end
		end
	end
end

return BossAbilities
