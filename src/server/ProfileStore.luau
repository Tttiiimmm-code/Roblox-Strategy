-- Spielerprofile (Gold, Edelsteine, Sterne) per DataStore.
-- Ohne API-Zugriff (z. B. unveröffentlichter Ort in Studio) läuft alles im Speicher weiter; saveOk = false.
local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local UnitData = require(ReplicatedStorage:WaitForChild("Shared").UnitData)

local ProfileStore = {}

-- Profil v2: { gold, gems, stars, heroes = { [heroId] = { level, xp, merges, stats? } }, pity = { since4, since5 } }
local STORE_NAME = "TacticsProfiles_v1"
local START_GEMS = 300 -- GRUNDGERÜST: Startguthaben zum Ausprobieren der Rekrutierung
local store = nil
pcall(function()
	store = DataStoreService:GetDataStore(STORE_NAME)
end)

local profiles = {}

local function key(player)
	return "p_" .. player.UserId
end

function ProfileStore.newHeroEntry()
	return { level = 1, xp = 0, merges = 0 }
end

local function newProfile()
	return { gold = 0, gems = START_GEMS, stars = {}, heroes = {}, pity = { since4 = 0, since5 = 0 }, settings = { battleScenes = true } }
end

-- Fehlende Felder ergänzen, Starthelden sicherstellen, unbekannte Helden entfernen
local function normalize(profile)
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
	local ok, err = pcall(function()
		store:SetAsync(key(player), {
			gold = profile.gold,
			gems = profile.gems,
			stars = profile.stars,
			heroes = profile.heroes,
			pity = profile.pity,
			settings = profile.settings,
		})
	end)
	if not ok then
		warn("[ProfileStore] Speichern fehlgeschlagen:", err)
	end
end

-- Speichert im Hintergrund (blockiert den Aufrufer nicht)
function ProfileStore.save(player)
	local profile = profiles[player]
	if profile and store and profile.saveOk then
		task.spawn(write, player, profile)
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
