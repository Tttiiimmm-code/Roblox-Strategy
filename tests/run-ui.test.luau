local count = 0
local function check(ok, message) count += 1; assert(ok, message) end
local root = Instance.new("Frame")
local home = Instance.new("Frame"); home.Parent = root
local collection = Instance.new("Frame"); collection.Name = "TestKaserne"; collection.Parent = home
local recruitFrame = Instance.new("Frame"); recruitFrame.Parent = home
local state = { mode = "Lobby", busy = false }
local profile = { gold = 125, gems = 15, heroes = {}, tutorial = { state = "skipped" }, pity = {} }
for _, id in ipairs({ "leon", "starter_knight", "starter_mage", "bruno" }) do profile.heroes[id] = { level = 1, xp = 0, merges = 0 } end
local run = { seed = 1, depth = 5, cleared = 4, region = "greenland", phase = "camp", campExtra = true, maxTeam = 3,
	order = { "leon", "starter_knight", "bruno" }, team = { leon = { alive = true, hp = 20 }, starter_knight = { alive = true, hp = 20 }, bruno = { alive = false, hp = 0 } } }
profile.run = run
local messages = {}
local function render() modules.RunUI.update(state, profile, false) end
local callbacks = {
	onChanged = render,
	onCampSwap = function(slot, id, outgoing) table.insert(messages, { type = "swap", slot = slot, id = id, outgoing = outgoing }) end,
	onCampRevive = function(id, currency) table.insert(messages, { type = "revive", id = id, currency = currency }) end,
	onLeaveCamp = function() table.insert(messages, { type = "leave" }) end,
	onAbandonRun = function() end,
	onChooseLevel = function(index) table.insert(messages, { type = "choose", index = index }) end,
	onResumeLevel = function() table.insert(messages, { type = "resume" }) end,
	onLobby = function() end,
}
modules.CollectionUI.build(recruitFrame, collection, root, { onRecruit = function() error("Gacha im Lager") end })
modules.RunUI.init(root, callbacks)
local window = root:FindFirstChild("RunWindow")
local function object(text, class, parent)
	for _, o in (parent or window):GetDescendants() do
		if o.Text == text and (not class or o.ClassName == class) then return o end
	end
	error("UI fehlt: " .. text)
end
render()
check(object("Extra-Lager vor Garrick", "TextLabel") ~= nil, "Extra-Lager fehlt")
local gold, gems = object("🪙 125 Gold", "TextButton"), object("💎 15 Edelsteine", "TextButton")
check(gold.Size.Y.Offset >= 64 and gems.Size.Y.Offset >= 64, "Touchflächen zu klein")
gold.Activated:Fire(); gems.Activated:Fire()
check(messages[1].id == "bruno" and messages[1].currency == "gold" and messages[2].currency == "gems", "Währungswahl falsch")
profile.gold, profile.gems = 0, 0
render()
check(object("🪙 125 Gold", "TextButton"):GetAttribute("Style") == "disabled", "Fehlendes Guthaben nicht sichtbar")
local before = #messages
object("🪙 125 Gold", "TextButton").Activated:Fire()
check(#messages == before, "Unbezahlbaren Kauf gesendet")
object("Kaserne · Tausch", "TextButton").Activated:Fire()
check(collection.Parent ~= home and collection:FindFirstAncestorOfClass("Frame") ~= home, "Vorhandene Kaserne nicht wiederverwendet")
check(object("Kaserne im Lager", "TextLabel") ~= nil, "Kasernenüberschrift")
object("Magierin", "TextLabel", collection).Parent.Activated:Fire()
object("Einsetzen: Magierin", "TextButton").Activated:Fire()
check(messages[#messages].type == "swap" and messages[#messages].slot == 1 and messages[#messages].id == "starter_mage" and messages[#messages].outgoing == "leon", "Kasernentausch falsch")
run.order[1] = "starter_mage"
run.team.starter_mage = { alive = true, hp = 20 }
render()
check(collection.Parent == home, "Kaserne beim Lagerwechsel zerstört")
object("Kaserne · Tausch", "TextButton").Activated:Fire()
check(collection.Parent ~= home, "Kaserne nicht erneut öffnbar")
object("Zurück zum Lager", "TextButton").Activated:Fire()
check(collection.Parent == home and not collection.Visible, "Kaserne nicht zurückgegeben")
object("Weiter zu Garrick", "TextButton").Activated:Fire()
check(messages[#messages].type == "leave", "Lager verlassen nicht angebunden")
for _, id in ipairs(run.order) do run.team[id].alive, run.team[id].hp = false, 0 end
render()
check(object("Weiter zu Garrick", "TextButton"):GetAttribute("Style") == "disabled", "Team ohne Lebende kann fortsetzen")
print("OK: " .. count .. " Lager-UI-Prüfungen (Preise, Touchflächen, Währungen, Kasernenwiederverwendung und Tausch). Studio/Handy ungetestet.")
