-- Spielerprofile und Tutorial-Fortschritt per DataStore.
-- Ohne API-Zugriff (z. B. unveröffentlichter Ort in Studio) läuft alles im Speicher weiter; saveOk = false.
local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local UnitData = require(Shared.UnitData)
local RunConfig = require(Shared.RunConfig)
local LevelGen = require(Shared.LevelGen)
local Recruit = require(Shared.Recruit)

local ProfileStore = {}

-- Profil v4 (zusätzlich tutorial; stars nur als Altdaten): { gold, gems, stars, heroes = { [heroId] = { level, xp, merges, stats? } }, pity = { since4, since5 } }
local STORE_NAME = "TacticsProfiles_v1"
local START_GEMS = 300 -- GRUNDGERÜST: Startguthaben zum Ausprobieren der Rekrutierung
local store = nil
pcall(function()
	store = DataStoreService:GetDataStore(STORE_NAME)
end)

local profiles = {}
local writing = {}

local function key(player)
	return "p_" .. player.UserId
end

function ProfileStore.newHeroEntry()
	return { level = 1, xp = 0, merges = 0 }
end

local function newProfile()
	return { gold = 0, gems = START_GEMS, stars = {}, heroes = {}, pity = { since4 = 0, since5 = 0 }, settings = { battleScenes = true }, tutorial = { state = "new" } }
end

local function integer(value, low, high)
	return type(value) == "number" and value == value and value % 1 == 0 and value >= low and value <= high
end

local function arraySize(list)
	if type(list) ~= "table" then return nil end
	local count = 0
	for index in pairs(list) do
		if not integer(index, 1, #list) then return nil end
		count += 1
	end
	return count == #list and count or nil
end

-- Unbekannte/kaputte Läufe verwerfen; nur geprüfte Felder weiterführen.
local function normalizeRun(run, heroes)
	-- Phase-1-L?ufe haben andere feste Optionen; sie werden ohne Profilverlust verworfen.
	if type(run) ~= "table" or run.version ~= RunConfig.VERSION or not integer(run.seed, 1, 2147483646)
		or not integer(run.depth, 1, RunConfig.totalLevels()) or run.region ~= RunConfig.regionAt(run.depth)
		or not integer(run.cleared, 0, RunConfig.totalLevels() - 1) or run.cleared ~= run.depth - 1
		or type(run.team) ~= "table" or type(run.earned) ~= "table"
		or (run.phase ~= "choice" and run.phase ~= "camp") or type(run.campExtra) ~= "boolean" then return nil end
	local maxTeam = math.min(RunConfig.MAX_TEAM, RunConfig.START_TEAM + math.floor(run.cleared / RunConfig.LEVELS_PER_REGION))
	local size = arraySize(run.order)
	if run.maxTeam ~= maxTeam or not size or size < 1 or size > maxTeam then return nil end
	local earned = {}
	for _, kind in ipairs(RunConfig.REWARD_ORDER) do
		local maximum = 0
		for depth = 1, run.cleared do maximum += RunConfig.rewardAmount(kind, depth) end
		if not integer(run.earned[kind], 0, maximum) then return nil end
		earned[kind] = run.earned[kind]
	end
	local order, team, seen, alive = {}, {}, {}, 0
	-- Auch ausgewechselte Helden behalten ihre KP und ihren Todesstatus.
	for id, member in pairs(run.team) do
		local entry, def = heroes[id], UnitData.Heroes[id]
		if type(id) ~= "string" or not def or type(entry) ~= "table"
			or type(member) ~= "table" or type(member.alive) ~= "boolean" then return nil end
		local stats = type(entry.stats) == "table" and entry.stats or def.stats
		local hp, merges = stats.hp, entry.merges or 0
		if not integer(hp, 1, math.huge) or not integer(merges, 0, Recruit.MAX_MERGES) then return nil end
		local maximum = hp + merges * Recruit.MERGE_HP
		if not integer(member.hp, 0, maximum) or member.alive ~= (member.hp > 0) then return nil end
		team[id] = { hp = member.hp, alive = member.alive }
	end
	for _, id in ipairs(run.order) do
		if not team[id] or seen[id] then return nil end
		seen[id] = true
		table.insert(order, id)
		if team[id].alive then alive += 1 end
	end
	if alive == 0 then return nil end
	local expected = LevelGen.makeOptions(run.seed, run.depth, run.region)
	if arraySize(run.options) ~= #expected then return nil end
	for i, option in ipairs(expected) do
		local saved = run.options[i]
		if type(saved) ~= "table" or saved.kind ~= option.kind or saved.themeId ~= option.themeId
			or saved.seed ~= option.seed or saved.bossId ~= option.bossId then return nil end
		if option.reward and (type(saved.reward) ~= "table" or saved.reward.kind ~= option.reward.kind
			or saved.reward.amount ~= option.reward.amount) then return nil end
	end
	if run.current ~= nil and not integer(run.current, 1, #expected) then return nil end
	if run.campExtra then
		if run.phase ~= "camp" or RunConfig.levelKind(run.depth) ~= "boss" or run.current ~= nil then return nil end
	elseif run.phase == "camp" then
		if not run.current or expected[run.current].kind ~= "camp" then return nil end
	elseif run.current and expected[run.current].kind == "camp" then return nil end
	return {
		version = RunConfig.VERSION, phase = run.phase, campExtra = run.campExtra, maxTeam = maxTeam,
		seed = run.seed, region = run.region, depth = run.depth, cleared = run.cleared,
		order = order, team = team, options = expected, current = run.current, earned = earned,
	}
end

-- Fehlende Felder ergänzen, Starthelden sicherstellen, unbekannte Helden entfernen
local function normalize(profile)
	local tutorialState = type(profile.tutorial) == "table" and profile.tutorial.state
	if tutorialState ~= "new" and tutorialState ~= "done" and tutorialState ~= "skipped" then
		-- Vor dem Ergänzen der Starter prüfen: gespeicherte Helden-Level kennzeichnen Bestandsspieler.
		local existing = type(profile.stars) == "table" and next(profile.stars) ~= nil
		for id, entry in (type(profile.heroes) == "table" and profile.heroes or {}) do
			if UnitData.Heroes[id] and type(entry) == "table" and type(entry.level) == "number" then existing = true end
		end
		tutorialState = existing and "done" or "new"
	end
	profile.tutorial = { state = tutorialState }
	profile.settings = type(profile.settings) == "table" and profile.settings or {}
	if type(profile.settings.battleScenes) ~= "boolean" then profile.settings.battleScenes = true end
	profile.heroes = type(profile.heroes) == "table" and profile.heroes or {}
	profile.pity = type(profile.pity) == "table" and profile.pity or { since4 = 0, since5 = 0 }
	for id in profile.heroes do
		if not UnitData.Heroes[id] then
			profile.heroes[id] = nil
		end
	end
	for _, id in UnitData.STARTER_HEROES do
		profile.heroes[id] = profile.heroes[id] or ProfileStore.newHeroEntry()
	end
	profile.run = normalizeRun(profile.run, profile.heroes)
end

function ProfileStore.load(player)
	local data, ok = nil, false
	if store then
		ok, data = pcall(function()
			return store:GetAsync(key(player))
		end)
		if not ok then
			warn("[ProfileStore] Laden fehlgeschlagen, Fortschritt wird nicht gespeichert:", data)
			data = nil
		end
	end
	local profile = newProfile()
	if type(data) == "table" then
		profile.gold = tonumber(data.gold) or 0
		profile.gems = tonumber(data.gems) or 0
		profile.stars = type(data.stars) == "table" and data.stars or {}
		profile.heroes = data.heroes
		profile.pity = data.pity
		profile.settings = data.settings
		profile.run = data.run
		profile.tutorial = data.tutorial
	end
	normalize(profile)
	profile.saveOk = ok
	profiles[player] = profile
	return profile
end

function ProfileStore.get(player)
	return profiles[player]
end

local function write(player, profile)
	-- Laufwahl und Abschluss müssen in derselben Reihenfolge im DataStore ankommen.
	while writing[player] do task.wait() end
	if profiles[player] ~= profile then return end
	writing[player] = true
	local ok, err = pcall(function()
		store:SetAsync(key(player), {
			gold = profile.gold,
			gems = profile.gems,
			stars = profile.stars,
			heroes = profile.heroes,
			pity = profile.pity,
			settings = profile.settings,
			run = profile.run,
			tutorial = profile.tutorial,
		})
	end)
	writing[player] = nil
	if not ok then
		warn("[ProfileStore] Speichern fehlgeschlagen:", err)
	end
end

-- Lauf-Übergänge warten auf das Speichern; sonst im Hintergrund.
function ProfileStore.save(player, waitForSave)
	local profile = profiles[player]
	if profile and store and profile.saveOk then
		if waitForSave then write(player, profile) else task.spawn(write, player, profile) end
	end
end

function ProfileStore.release(player)
	local profile = profiles[player]
	if profile and store and profile.saveOk then
		write(player, profile)
	end
	profiles[player] = nil
end

-- Beim Herunterfahren alle synchron speichern
function ProfileStore.saveAll()
	for player, profile in profiles do
		if store and profile.saveOk then
			write(player, profile)
		end
	end
end

return ProfileStore
