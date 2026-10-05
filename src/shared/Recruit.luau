-- Rekrutierung (Gacha): Raten, Pity, Kosten, Verschmelzungen.
-- GRUNDGERÜST – alle Zahlen sind Platzhalter und können frei angepasst werden.
-- Hinweis Roblox-Regeln: Sobald Edelsteine mit Robux kaufbar sind, MÜSSEN alle Wahrscheinlichkeiten
-- vor dem Kauf sichtbar sein (siehe Recruit.odds + Anzeige in CollectionUI).
local UnitData = require(script.Parent.UnitData)

local Recruit = {}

-- Grundchance je Seltenheit in Prozent (Summe = 100)
Recruit.RATES = { [5] = 2, [4] = 8, [3] = 20, [2] = 30, [1] = 40 }

-- Pity: spätestens beim N-ten Ruf ohne entsprechende Seltenheit ist sie garantiert
Recruit.PITY_4 = 30 -- ★4 oder besser
Recruit.PITY_5 = 80 -- ★5

-- Doppelte Helden werden verschmolzen (Platzhalter-Effekt: +1 KP pro Verschmelzung)
Recruit.MAX_MERGES = 10
Recruit.MERGE_HP = 1

Recruit.Banners = {
	{
		id = "standard",
		name = "Heldenruf",
		description = "Rufe Helden aus allen Ecken des Reiches zu deinen Bannern.",
		costSingle = 50,
		costMulti = 450, -- 10 Rufe zum Preis von 9
		featured = { "aurelia", "siegfried" }, -- nur Anzeige, keine erhöhte Chance
	},
}

function Recruit.getBanner(id)
	for _, b in Recruit.Banners do
		if b.id == id then
			return b
		end
	end
	return nil
end

-- Alle rekrutierbaren Helden einer Seltenheit (alphabetisch, damit Anzeige und Wurf übereinstimmen)
function Recruit.pool(rarity)
	local list = {}
	for id, def in UnitData.Heroes do
		if def.rarity == rarity and def.recruitable ~= false then
			table.insert(list, id)
		end
	end
	table.sort(list)
	return list
end

-- Wahrscheinlichkeiten für die Anzeige: { { rarity, percent, heroes = { {id, percent} } } }
function Recruit.odds()
	local out = {}
	for rarity = 5, 1, -1 do
		local pool = Recruit.pool(rarity)
		local entry = { rarity = rarity, percent = Recruit.RATES[rarity], heroes = {} }
		for _, id in pool do
			table.insert(entry.heroes, { id = id, percent = Recruit.RATES[rarity] / #pool })
		end
		table.insert(out, entry)
	end
	return out
end

-- Noch so viele Rufe bis zur Garantie
function Recruit.pityRemaining(pity)
	return Recruit.PITY_4 - (pity.since4 or 0), Recruit.PITY_5 - (pity.since5 or 0)
end

local function rollRarity(rng)
	local r = rng:NextNumber() * 100
	local acc = 0
	for rarity = 5, 1, -1 do
		acc += Recruit.RATES[rarity]
		if r < acc then
			return rarity
		end
	end
	return 1
end

-- Ein Ruf. Verändert pity = { since4, since5 }. Liefert rarity, heroId.
function Recruit.roll(pity, rng)
	pity.since4 = (pity.since4 or 0) + 1
	pity.since5 = (pity.since5 or 0) + 1

	local rarity = rollRarity(rng)
	if pity.since5 >= Recruit.PITY_5 then
		rarity = 5
	elseif pity.since4 >= Recruit.PITY_4 and rarity < 4 then
		rarity = 4
	end

	-- Leere Stufe (sollte nicht vorkommen): nächstniedrigere nehmen
	local pool = Recruit.pool(rarity)
	while #pool == 0 and rarity > 1 do
		rarity -= 1
		pool = Recruit.pool(rarity)
	end

	if rarity >= 4 then
		pity.since4 = 0
	end
	if rarity >= 5 then
		pity.since5 = 0
	end
	return rarity, pool[rng:NextInteger(1, #pool)]
end

return Recruit
