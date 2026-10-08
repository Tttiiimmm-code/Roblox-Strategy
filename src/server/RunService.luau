-- Laufdaten und Übergänge; Kampf und Figuren bleiben im bestehenden Serverablauf.
local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local RunConfig = require(Shared.RunConfig)
local LevelGen = require(Shared.LevelGen)
local UnitData = require(Shared.UnitData)
local Recruit = require(Shared.Recruit)
local RunService = {}

function RunService.maxHp(heroId, entry)
	return (entry.stats or UnitData.Heroes[heroId].stats).hp + (entry.merges or 0) * Recruit.MERGE_HP
end

function RunService.start(profile, heroes, seed)
	if profile.run or type(heroes) ~= "table" or #heroes ~= RunConfig.START_TEAM then return false end
	local count, seen = 0, {}
	for index, id in pairs(heroes) do
		if type(index) ~= "number" or index % 1 ~= 0 or index < 1 or index > RunConfig.START_TEAM
			or type(id) ~= "string" or seen[id] or type(profile.heroes[id]) ~= "table"
			or not UnitData.Heroes[id] then return false end
		seen[id] = true
		count += 1
	end
	if count ~= RunConfig.START_TEAM then return false end
	local team, order = {}, {}
	for _, id in ipairs(heroes) do
		team[id] = { hp = RunService.maxHp(id, profile.heroes[id]), alive = true }
		table.insert(order, id)
	end
	local region = RunConfig.regionAt(1)
	profile.run = {
		seed = seed, region = region, depth = 1, team = team, order = order,
		options = LevelGen.makeOptions(seed, 1, region), current = nil,
		earned = { gold = 0, gems = 0 }, cleared = 0,
	}
	return true
end

function RunService.choose(run, index)
	if not run or run.current ~= nil or type(index) ~= "number" or index % 1 ~= 0
		or index < 1 or index > #run.options then return false end
	run.current = index
	return true
end

function RunService.stage(run)
	local option = run.options[run.current]
	local living = {}
	for _, id in ipairs(run.order) do if run.team[id].alive then table.insert(living, id) end end
	return LevelGen.generate(option.seed, run.region, run.depth, option.themeId, #living), living
end

local function summary(run, outcome)
	return {
		run = true, ended = true, outcome = outcome, victory = outcome == "Completed",
		cleared = run.cleared, totalLevels = RunConfig.totalLevels(),
		earned = table.clone(run.earned), depth = run.depth, region = run.region,
		reward = { gold = 0, gems = 0 }, healed = {},
	}
end

function RunService.abandon(profile)
	local info = summary(profile.run, "Abandoned")
	profile.run = nil
	return info
end

function RunService.finish(profile, heroUnits, victory)
	local run = profile.run
	local info = summary(run, victory and "Victory" or "Defeat")
	info.victory = victory
	if victory then
		for _, id in ipairs(run.order) do
			local member, unit = run.team[id], heroUnits[id]
			if member.alive then
				member.alive = unit ~= nil and unit.hp > 0
				local before = member.alive and unit.hp or 0
				member.hp = member.alive and math.min(unit.maxHp, before + math.ceil(unit.maxHp * RunConfig.PARTIAL_HEAL)) or 0
				info.healed[id] = { before = before, after = member.hp, amount = member.hp - before, alive = member.alive, maxHp = unit and unit.maxHp or RunService.maxHp(id, profile.heroes[id]) }
			end
		end
		local reward = run.options[run.current].reward
		profile[reward.kind] += reward.amount
		run.earned[reward.kind] += reward.amount
		info.reward[reward.kind] = reward.amount
		run.cleared += 1
		info.cleared = run.cleared
		info.earned = table.clone(run.earned)
		run.depth += 1
		run.current = nil
		info.ended = run.cleared >= RunConfig.totalLevels()
		if info.ended then
			info.outcome = "Completed"
			profile.run = nil
		else
			run.region = RunConfig.regionAt(run.depth)
			run.options = LevelGen.makeOptions(run.seed, run.depth, run.region)
		end
	else
		profile.run = nil
	end
	return info
end

return RunService
