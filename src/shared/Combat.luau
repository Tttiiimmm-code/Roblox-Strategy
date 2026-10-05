-- Kampfformeln im Stil der GBA-Fire-Emblem-Teile
local Config = require(script.Parent.Config)
local Grid = require(script.Parent.Grid)
local UnitData = require(script.Parent.UnitData)

local Combat = {}

-- Schwert > Axt > Lanze > Schwert
local BEATS = { Sword = "Axe", Axe = "Lance", Lance = "Sword" }
local DOUBLE_THRESHOLD = 4

function Combat.triangle(attackType, defendType)
	if BEATS[attackType] == defendType then
		return 1
	elseif BEATS[defendType] == attackType then
		return -1
	end
	return 0
end

local function clamp100(v)
	return math.clamp(math.floor(v), 0, 100)
end

local function sideStats(unit, weapon, foe, foeWeapon, foeTerrain)
	local tri = Combat.triangle(weapon.type, foeWeapon.type)
	local power = (weapon.magic and unit.mag or unit.str) + weapon.might + tri
	local defense = (weapon.magic and foe.res or foe.def) + foeTerrain.def
	local hit = weapon.hit + unit.skl * 2 + math.floor(unit.lck / 2) + tri * 15
	local avoid = foe.spd * 2 + foe.lck + foeTerrain.avoid
	local crit = weapon.crit + math.floor(unit.skl / 2) - foe.lck
	return {
		dmg = math.max(0, power - defense),
		hit = clamp100(hit - avoid),
		crit = clamp100(crit),
		tri = tri,
	}
end

-- Vorschau, wenn `attacker` von Feld (ax, ay) aus `defender` angreift
function Combat.forecast(attacker, defender, ax, ay)
	local aw = UnitData.Weapons[attacker.weapon]
	local dw = UnitData.Weapons[defender.weapon]
	local attackerTerrain = Grid.terrainAt(ax, ay)
	local defenderTerrain = Grid.terrainAt(defender.x, defender.y)
	local dist = Grid.dist(ax, ay, defender.x, defender.y)

	local a = sideStats(attacker, aw, defender, dw, defenderTerrain)
	local d = sideStats(defender, dw, attacker, aw, attackerTerrain)

	a.hp = attacker.hp
	a.count = (attacker.spd - defender.spd >= DOUBLE_THRESHOLD) and 2 or 1

	d.hp = defender.hp
	d.canCounter = dist >= dw.minRange and dist <= dw.maxRange
	if not d.canCounter then
		d.count = 0
	else
		d.count = (defender.spd - attacker.spd >= DOUBLE_THRESHOLD) and 2 or 1
	end

	return { attacker = a, defender = d }
end

-- Führt den Kampf aus (verändert hp), liefert die einzelnen Schläge für die Animation
function Combat.resolve(attacker, defender, ax, ay, rng)
	local f = Combat.forecast(attacker, defender, ax, ay)
	local strikes = {}

	local function strike(user, target, s)
		if user.hp <= 0 or target.hp <= 0 then
			return
		end
		-- "2RN": Mittelwert zweier Zufallszahlen, wie in FE6-FE13
		local roll = (rng:NextInteger(0, 99) + rng:NextInteger(0, 99)) / 2
		local hit = roll < s.hit
		local crit = hit and rng:NextInteger(0, 99) < s.crit
		local damage = 0
		if hit then
			damage = crit and s.dmg * 3 or s.dmg
		end
		target.hp = math.max(0, target.hp - damage)
		table.insert(strikes, {
			attackerId = user.id,
			targetId = target.id,
			hit = hit,
			crit = crit,
			damage = damage,
			hpAfter = target.hp,
		})
	end

	local a, d = f.attacker, f.defender
	strike(attacker, defender, a)
	if d.count >= 1 then
		strike(defender, attacker, d)
	end
	if a.count >= 2 then
		strike(attacker, defender, a)
	end
	if d.count >= 2 then
		strike(defender, attacker, d)
	end

	return { strikes = strikes, forecast = f }
end

function Combat.gainExperience(unit, foe, killed, dealtDamage, rng)
	local levelDiff = (foe.level or 1) - (unit.level or 1)
	local exp
	if killed then
		exp = 30 + levelDiff * 4
	elseif dealtDamage then
		exp = 10 + levelDiff
	else
		exp = 1
	end
	exp = math.clamp(exp, 1, 100)

	local result = { unitId = unit.id, unitName = unit.name, exp = exp }
	if unit.level >= Config.MAX_LEVEL then
		result.exp = 0
		return result
	end

	unit.xp += exp
	if unit.xp >= 100 then
		unit.xp -= 100
		unit.level += 1
		local gains = {}
		local growths = UnitData.Classes[unit.class].growths
		for _, stat in UnitData.STAT_ORDER do
			if rng:NextInteger(1, 100) <= (growths[stat] or 0) then
				gains[stat] = 1
				if stat == "hp" then
					unit.maxHp += 1
					unit.hp += 1
				else
					unit[stat] += 1
				end
			end
		end
		result.level = unit.level
		result.gains = gains
		result.stats = {}
		for _, stat in UnitData.STAT_ORDER do
			result.stats[stat] = stat == "hp" and unit.maxHp or unit[stat]
		end
	end

	return result
end

return Combat
