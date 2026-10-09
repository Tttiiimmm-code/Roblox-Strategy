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
			expect(Runs.leaveCamp(run) and run.depth == 5 and run.phase == "choice", "Extra-Lager z?hlt als Level")
		end
		local index = 1
		for i, option in ipairs(run.options) do if option.kind == "camp" then index = i end end
		expect(Runs.choose(run, index), "Option w?hlen")
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
