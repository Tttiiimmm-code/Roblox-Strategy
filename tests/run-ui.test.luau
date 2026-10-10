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
local gold, gems = object("💰 125 Gold", "TextButton"), object("💎 15 Edelsteine", "TextButton")
check(gold.Size.Y.Offset >= 64 and gems.Size.Y.Offset >= 64, "Touchflächen zu klein")
gold.Activated:Fire(); gems.Activated:Fire()
check(messages[1].id == "bruno" and messages[1].currency == "gold" and messages[2].currency == "gems", "Währungswahl falsch")
profile.gold, profile.gems = 0, 0
render()
check(object("💰 125 Gold", "TextButton"):GetAttribute("Style") == "disabled", "Fehlendes Guthaben nicht sichtbar")
local before = #messages
object("💰 125 Gold", "TextButton").Activated:Fire()
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

run.phase, run.campExtra, run.current = "choice", false, nil
for _, id in ipairs(run.order) do run.team[id].hp, run.team[id].alive = 20, true end
for _, depth in ipairs({ 3, 5 }) do
	run.depth = depth
	run.options = modules.LevelGen.makeOptions(run.seed, depth, "greenland")
	render()
	local title = depth == 3 and "Miniboss: Banditenhauptmann" or "Boss: Garrick"
	local card = object(title, "TextLabel").Parent
	check(#run.options == 1 and card.ClassName == "TextButton", "Bosskarte fehlt")
	flushDeferred()
	card.Activated:Fire()
	check(messages[#messages].type == "choose" and messages[#messages].index == 1, "Bossstart falsch")
	run.current = 1
	render()
	object("Level erneut starten", "TextButton").Activated:Fire()
	check(messages[#messages].type == "resume", "Bossneustart falsch")
	run.current = nil
end
local campOption
for seed = 1, 1000 do
	run.seed, run.depth = seed, 1
	run.options = modules.LevelGen.makeOptions(seed, 1, "greenland")
	for i, option in ipairs(run.options) do if option.kind == "camp" then campOption = i; break end end
	if campOption then break end
end
render()
local campCard = object("Lager", "TextLabel").Parent
check(object("⛺", "TextLabel").Parent == campCard, "Lagersymbol fehlt")
check(object("Heilung & Teamwechsel\nKeine Kampfbelohnung", "TextLabel").Parent == campCard, "Lagerinfo fehlt")
-- Echte Hover-/Loslass-Ereignisse; Geometrie bei schmalen und breiten Auswahlbereichen.
services.UserInputService.MouseEnabled = true
local optionCards = {}
for _, child in campCard.Parent.Parent:GetChildren() do
	if child.Name == "LevelChoice" then table.insert(optionCards, child) end
end
table.sort(optionCards, function(a, b) return a.Position.X.Scale < b.Position.X.Scale end)
for _, width in { 480, 900, 1600 } do
	local right = -math.huge
	for _, card in optionCards do
		local action = card.ChooseCard.ChooseButton
		action.MouseEnter:Fire()
		action.InputBegan:Fire({ UserInputType = Enum.UserInputType.MouseButton1 })
		action.InputEnded:Fire({ UserInputType = Enum.UserInputType.MouseButton1 })
		local scale = action.ButtonScale.Scale
		local size = card.Size.X.Scale * width + card.Size.X.Offset
		local left = card.Position.X.Scale * width + card.Position.X.Offset - size * (scale - 1) / 2
		check(left >= right and scale == 1, "Auswahlkarten ueberlappen beim Hover/Loslassen")
		right = left + size * scale
		action.MouseLeave:Fire()
	end
end
local small = modules.UIKit.button("Hover-Test", root)
small.MouseEnter:Fire()
check(small:FindFirstChild("ButtonScale").Scale == modules.Config.FEEL.buttonHoverScale, "Kleine Buttons ohne Hoverfeedback")
local clickSize = small.Size
small.Text = "Geänderter Knopftext"
small.InputBegan:Fire({ UserInputType = Enum.UserInputType.Touch })
check(small.Size == clickSize and small.Text == "Geänderter Knopftext", "Jelly-Dekoration verändert TextButton-Vertrag")
check(small.ButtonFace.Position.Y.Offset + small.UIPadding.PaddingTop.Offset == 4, "Gedrückte Fläche senkt sich nicht um vier Pixel")
check(small.ButtonEdge.Position.Y.Offset + small.UIPadding.PaddingTop.Offset == 5, "Drücken verschiebt die Kante statt nur der Fläche")
small.InputEnded:Fire({ UserInputType = Enum.UserInputType.Touch })
check(small.ButtonFace.Position.Y.Offset == 0 and small.Size == clickSize, "Loslassen verändert Klickfläche oder Layoutgröße")
modules.UIKit.setButtonStyle(small, "holo")
check(small:GetAttribute("Style") == "holo" and small.ButtonFace.UIGradient.Enabled, "Holo-Stil nicht aktiv")
modules.UIKit.setButtonStyle(small, "disabled")
small.InputBegan:Fire({ UserInputType = Enum.UserInputType.Touch })
check(not small.ButtonEdge.Visible and small.ButtonFace.Position.Y.Offset == 0, "Deaktivierter Knopf bekommt eine gedrückte Kante")
check(small.TextOutline.Transparency == small.TextTransparency and small.TextTransparency == 0.4, "Deaktivierter Text und Kontur blenden unterschiedlich aus")
small:Destroy()
local changingFont = modules.UIKit.label({ Text = "Dynamische Schrift", TextSize = 20 }, root)
check(not changingFont.TextOutline.Enabled, "Fließtext bekommt eine Kontur")
changingFont.Font = modules.UIKit.THEME.bold
check(changingFont.TextOutline.Enabled and changingFont.TextOutline.Thickness == 2, "Später gesetzte UI-Schrift bekommt keine Kontur")
changingFont.TextSize = 14
changingFont.TextTransparency = 0.8
check(changingFont.TextOutline.Thickness == 1.5 and changingFont.TextOutline.Transparency == 0.8, "Größe/Fade der Kontur folgt nicht dem Text")
local plain = modules.UIKit.label({ Text = "Ohne Kontur", Font = modules.UIKit.THEME.display, Outline = false }, root)
check(not plain.TextOutline.Enabled, "Outline=false wird ignoriert")
local legendary = modules.UIKit.heroCard(root, "leon", {})
legendary.stroke.Color = modules.UIKit.THEME.good
check(not legendary.stroke.UIGradient.Enabled, "Auswahlfarbe wird vom Holo-Rahmen verdeckt")
legendary.stroke.Color = legendary.rarity.color
check(legendary.stroke.UIGradient.Enabled and legendary.stroke.Color == modules.UIKit.THEME.text, "Abwahl stellt Holo nicht wieder her")
changingFont:Destroy(); plain:Destroy(); legendary.card:Destroy()
flushDeferred()
campCard.Activated:Fire()
check(messages[#messages].type == "choose" and messages[#messages].index == campOption, "Wahllager falsch angebunden")
-- Die ausgeliehene Kaserne bleibt im Hub verwendbar und enthält keine Lagerstatus-Texte.
profile.run = nil
render()
modules.CollectionUI.update(profile)
check(collection.Parent == home, "Kaserne nach Lauf verloren")
for _, label in collection:GetDescendants() do check(label.Text ~= "Im Laufteam", "Lagerstatus im Hub") end
print("OK: " .. count .. " gesamte Lauf-UI-Prüfungen (Lager, Kaserne, Boss-/Lagerkarten, Neustart, Rückkehr). Studio/Handy ungetestet.")

-- Fensterregressionen: echte Bausteine, Ebenenwechsel und umgehängter Inhalt.
for _, behavior in { Enum.ZIndexBehavior.Global, Enum.ZIndexBehavior.Sibling } do
	local gui = modules.UIKit.make("ScreenGui", { ZIndexBehavior = behavior }, playerGui)
	local window = modules.UIKit.panel({ ZIndex = 21, Jewel = true }, gui)
	local title = modules.UIKit.label({ Text = "Standardebene" }, window)
	local same = modules.UIKit.label({ Text = "Gleiche Ebene", ZIndex = 21 }, window)
	local button = modules.UIKit.button("Knopf über Fläche", window)
	check(window.Background.ZIndex == 21 and title.ZIndex > 21 and same.ZIndex > 21, "Dialoghintergrund liegt unter Overlay oder über Standardinhalt")
	check(button.ZIndex > button.ButtonFace.ZIndex and button.ButtonFace.ZIndex > window.ZIndex, "Knopffläche verdeckt Text oder liegt unter Fenster")
	for _, z in { 40, 9 } do
		window.ZIndex = z
		for _, decoration in window.Background:GetDescendants() do
			if decoration:IsA("GuiObject") then check(decoration.ZIndex == z, "Deko folgt Fenster-ZIndex nicht") end
		end
		check(window.Background.ZIndex == z and window.Shadow.ZIndex == z, "Fläche/Schatten folgen ZIndex nicht")
		check(title.ZIndex > z and button.ZIndex > button.ButtonFace.ZIndex, "Inhalt bei späterem ZIndex verdeckt")
	end
	title.ZIndex = 1; button.ZIndex = window.ZIndex
	check(title.ZIndex > window.ZIndex and button.ZIndex > button.ButtonFace.ZIndex, "Spätere Inhaltszuweisung verletzt Ebenenvertrag")
	local subtree = modules.UIKit.make("Frame", {}, nil)
	local nested = modules.UIKit.label({ Text = "Umgehängter Inhalt" }, subtree)
	subtree.Parent = window
	check(nested.ZIndex > window.ZIndex, "Bereits bestehender Unterbaum bleibt unter Hintergrund")
	subtree.Parent = gui
	window.ZIndex = 60; nested.ZIndex = 1
	check(nested.ZIndex == 1, "Altes Fenster verändert entfernten Inhalt")
	gui:Destroy()
end
local plainPanel = modules.UIKit.panel({}, root)
check(not plainPanel.Background:FindFirstChild("CrownJewel"), "Fenster bekommen standardmäßig ein Juwel")
check(plainPanel.Background.BackgroundTransparency == 0, "Standardfenster lässt Text dahinter durchscheinen")
plainPanel.AutomaticSize = Enum.AutomaticSize.Y
check(not plainPanel.Background.Visible and plainPanel.AutomaticGradient.Enabled and plainPanel.BackgroundTransparency == 0, "Automatische Fensterfläche beeinflusst weiterhin Größe")
check(not plainPanel.Shadow.Visible and plainPanel.Shadow.Size.Y.Scale == 0 and plainPanel.Shadow.Size.Y.Offset == 0 and plainPanel.Shadow.Position.Y.Offset == 0, "Nachträgliches AutomaticSize behält versetzten Schatten")
plainPanel.AutomaticSize = Enum.AutomaticSize.None
check(plainPanel.Background.Visible and plainPanel.Shadow.Visible and not plainPanel.AutomaticGradient.Enabled, "Feste Größe stellt Deko nicht wieder her")
local autoPanel = modules.UIKit.panel({ AutomaticSize = Enum.AutomaticSize.Y }, root)
modules.UIKit.padding(autoPanel, 8)
check(not autoPanel:FindFirstChild("Shadow") and not autoPanel.Background.Visible and autoPanel.AutomaticGradient.Enabled, "Anfangs automatisches Fenster hat größenwirksame Deko")
plainPanel:Destroy(); autoPanel:Destroy()
-- Gerenderte Schriftgröße trotz großer TextSize; auch explizite Konturen werden gedeckelt.
local scaled = modules.UIKit.label({ Text = "Skalierung", TextSize = 38, Font = modules.UIKit.THEME.bold, OutlineThickness = 3 }, root)
for _, example in { {10,1}, {16,1.5}, {24,2}, {32,3} } do
	scaled.TextBounds = Vector2.new(80, example[1]); flushDeferred()
	check(scaled.TextOutline.Thickness == example[2], "Kontur ignoriert gerenderte Schriftgröße")
end
scaled.Text = "Zwei\nZeilen"; scaled.TextBounds = Vector2.new(80, 20); flushDeferred()
check(scaled.TextOutline.Thickness == 1, "Mehrzeiliger Text wird als große Schrift behandelt")
local wrapped = modules.UIKit.label({ Text = "abcdefghijklmnopqrst", TextSize = 38, Font = modules.UIKit.THEME.bold, OutlineThickness = 3, wrap = true }, root)
wrapped.TextBounds = Vector2.new(50, 20); flushDeferred()
check(wrapped.TextOutline.Thickness == 1 and services.TextService.calls > 0, "Umgebrochene kleine Schrift bekommt zu dicke Kontur")
local measuredBeforeFade = services.TextService.calls
wrapped.TextTransparency = 0.6
check(wrapped.TextOutline.Transparency == 0.6, "Kontur-Fade nicht synchron")
check(services.TextService.calls == measuredBeforeFade, "Transparenz-Fade löst unnötige Schriftmessung aus")
scaled:Destroy(); wrapped:Destroy()
print("OK: " .. count .. " gesamte Lauf-UI-Prüfungen inklusive Fenster-/Konturregressionen. Renderer durch Studio-Bildtests ergänzt.")

-- Levelwahl: Panel/Klickfläche, Knopfstile, zwei/drei Optionen und einmalige Eingabe.
profile.run = run
run.phase, run.current = "choice", nil
local battle
-- Ein echtes generiertes Kampfthema verwenden.
for _, option in run.options do if option.kind == "battle" then battle = option; break end end
check(battle ~= nil, "Generierte Kampfoption fehlt")
for _, number in { 2, 3 } do
	run.seed += 1
	run.options = { battle, { kind = "camp" } }
	if number == 3 then table.insert(run.options, battle) end
	render()
	local cards = window:FindFirstChild("LevelChoice", true).Parent:GetChildren()
	check(#cards == number, "Falsche Anzahl Levelwahl-Karten")
	for _, card in cards do
		check(card.ClassName == "Frame" and card.Background and not card.Background:FindFirstChild("CrownJewel"), "Levelwahl ist kein Panel ohne Juwel")
		check(not card:FindFirstChild("ButtonFace"), "Jelly-Fläche überzieht die Karte") -- Knopf hat seine eigene Fläche.
		for _, height in { 240, 296 } do
			local hit = card.ChooseCard
			local action = hit.ChooseButton
			local detail = hit:FindFirstChild("RewardPill") or object("Heilung & Teamwechsel\nKeine Kampfbelohnung", "TextLabel", hit)
			local detailBottom = height + detail.Position.Y.Offset
			local detailTop = detailBottom - detail.Size.Y.Offset
			local actionTop = height + action.Position.Y.Offset - action.Size.Y.Offset
			check(detailTop >= 122 and detailBottom < actionTop, "Titel/Detail/Knopf überlappen bei kleiner Kartenhöhe")
			check(actionTop >= 0 and height + action.Position.Y.Offset <= height, "Knopf außerhalb der Karte")
		end
	end
end
local choice = window:FindFirstChild("LevelChoice", true)
local hit, action = choice.ChooseCard, choice.ChooseCard.ChooseButton
check(action.Text == "Wählen" and action:GetAttribute("Style") == "default" and action.Size.Y.Offset == 48, "Kampfknopf falsch")
check(hit.RewardPill.BackgroundColor3 == modules.UIKit.THEME.panelInset and hit.RewardPill.UIStroke.Thickness == 2, "Belohnungspille ohne dunkle Fläche/ink-Rand")
check(hit.RewardPill.TextLabel.TextColor3 == modules.UIKit.THEME.text, "Belohnung nicht weiß")
local campHit = object("Lager", "TextLabel").Parent
check(campHit.ChooseButton.Text == "Rasten" and campHit.ChooseButton:GetAttribute("Style") == "active" and not campHit:FindFirstChild("RewardPill"), "Lager unterscheidet sich nicht vom Kampf")
check(object("RAST", "TextLabel").Font == modules.UIKit.THEME.tech, "Lager-Kennzeile ohne Michroma")
local beforeChoice = #messages
state.busy = true
hit.Activated:Fire({}); action.Activated:Fire({})
check(#messages == beforeChoice, "Wahl ignoriert Busy")
state.busy = false
flushDeferred()
local input = { UserInputType = Enum.UserInputType.Touch }
action.Activated:Fire(input)
flushDeferred()
hit.Activated:Fire(input)
check(#messages == beforeChoice + 1 and messages[#messages].index == 1, "Ein Tipp löst Karte und Knopf doppelt aus")
flushDeferred()
hit.Activated:Fire({ UserInputType = Enum.UserInputType.Touch })
check(#messages == beforeChoice + 2, "Nächster Kartentipp wird blockiert")
flushDeferred()
campHit.ChooseButton.Activated:Fire({})
check(#messages == beforeChoice + 3 and messages[#messages].index == 2, "Lagerknopf startet falsche Wahl")
for _, depth in { 3, 5 } do
	run.depth = depth
	run.options = modules.LevelGen.makeOptions(run.seed, depth, "greenland")
	render()
	local boss = window:FindFirstChild("LevelChoice", true).ChooseCard.ChooseButton
	check(boss.Text == "Kampf!" and boss:GetAttribute("Style") == "primary", "Boss-/Minibossknopf falsch")
end

-- Lobbywechsel schließen nur die Wahrscheinlichkeiten, auch ohne closeLobby-Aufruf.
profile.run = nil
local function finishTweens()
	for _, animation in testTweens do animation.Completed:Fire(Enum.PlaybackState.Completed) end
end
local menuRoot = Instance.new("Frame")
modules.MenuUI.init(menuRoot, callbacks)
modules.MenuUI.update(state, profile)
modules.MenuUI.openLobby("recruit")
local oddsButton = object("ⓘ  Alle Wahrscheinlichkeiten", "TextButton", menuRoot)
local odds = object("Wahrscheinlichkeiten", "TextLabel", menuRoot).Parent.Parent
oddsButton.Activated:Fire()
check(odds.Visible, "Wahrscheinlichkeiten nicht öffnbar")
modules.MenuUI.closeLobby()
finishTweens()
check(not odds.Visible, "closeLobby lässt Wahrscheinlichkeiten offen")
modules.MenuUI.openLobby("recruit"); oddsButton.Activated:Fire()
modules.MenuUI.openLobby("barracks")
finishTweens()
check(not odds.Visible, "Kasernenwechsel lässt Wahrscheinlichkeiten offen")
modules.MenuUI.openLobby("recruit"); oddsButton.Activated:Fire()
modules.MenuUI.openLobby("run")
finishTweens()
check(not odds.Visible and menuRoot.RunWindow.Visible, "Teamwahl lässt Wahrscheinlichkeiten offen")
object("Zurück", "TextButton", menuRoot.RunWindow).Activated:Fire()
modules.MenuUI.openLobby("recruit"); oddsButton.Activated:Fire()
modules.MenuUI.setLoading(true)
finishTweens()
check(not odds.Visible, "Laden lässt Wahrscheinlichkeiten offen")
modules.MenuUI.setLoading(false)
modules.MenuUI.openLobby("recruit"); oddsButton.Activated:Fire()
state.mode, state.ownerUserId = "Battle", player.UserId
modules.MenuUI.update(state, profile)
finishTweens()
check(not odds.Visible, "Eigener Kampf lässt Wahrscheinlichkeiten offen")
state.mode, state.ownerUserId = "Lobby", nil
modules.MenuUI.update(state, profile)
modules.MenuUI.showRecruitResults({})
local results = object("Neue Verbündete", "TextLabel", menuRoot).Parent.Parent
modules.MenuUI.closeLobby()
check(results.Visible, "Lobbywechsel verwirft ungelesene Rufergebnisse")
print("OK: " .. count .. " gesamte Lauf-UI-Prüfungen inklusive Levelwahl-/Overlayregressionen. Studio/Handy separat prüfen.")
