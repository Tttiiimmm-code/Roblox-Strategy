-- Nur Roblox-Dienste und Darstellung ersetzen; Spiel-, Profil- und Kampfcode bleiben echt.
local function copy(value)
	if type(value) ~= "table" then return value end
	local result = {}
	for key, item in pairs(value) do result[key] = copy(item) end
	return result
end
local Color3 = { fromRGB = function(...) return { ... } end }
local Vector3 = { new = function(...) return { ... } end }
local Vector2 = { new = function(...) return { ... } end }
local Enum = { Material = setmetatable({}, { __index = function(_, key) return key end }) }
local task = { wait = function() end, spawn = function(fn, ...) fn(...) end }
local warn = function() end
local Random = { new = function() return { NextInteger = function(_, low) return low end } end }
local player = { UserId = 1, DisplayName = "Testspieler" }
local other = { UserId = 2, DisplayName = "Zuschauer" }
local records, remotes, strikes = {}, {}, {}
local function event()
	return { Connect = function(self, fn) self.callback = fn end }
end
local function folder()
	return { WaitForChild = function(_, name) return { Name = name } end }
end
local board = { SetAttribute = function() end }
local workspace = { FindFirstChild = function(_, name) return name == "Board" and board or nil end }
local services = {
	Players = { GetPlayers = function() return { player, other } end, PlayerAdded = event(), PlayerRemoving = event() },
	ReplicatedStorage = folder(),
	TweenService = {},
	DataStoreService = { GetDataStore = function() return {
		GetAsync = function(_, key) return copy(records[key]) end,
		SetAsync = function(_, key, value) records[key] = copy(value) end,
	} end },
}
local game = { GetService = function(_, name) return services[name] end, BindToClose = function() end }
local Instance = { new = function()
	local instance = { OnServerEvent = event() }
	function instance:FireAllClients(payload)
		if self.Name == "BattleEvent" and payload.strikes then strikes = copy(payload.strikes) end
	end
	function instance:FireClient() end
	setmetatable(instance, { __newindex = function(t, key, value)
		rawset(t, key, value)
		if key == "Name" then remotes[value] = t end
	end })
	return instance
end }
local testModules = {}
local visuals = setmetatable({}, { __index = function() return function() end end })
testModules.UnitVisuals = visuals
testModules.BoardBuilder = { ensureUnitsFolder = folder, build = function() end }
testModules.HubBuilder = { build = function() end }
testModules.EnemyAI = { plan = function() return nil end }
