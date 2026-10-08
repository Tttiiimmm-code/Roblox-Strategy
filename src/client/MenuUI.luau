-- Thronsaal, Sammlung und Tutorial-Ergebnis
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Stages = require(Shared:WaitForChild("Stages"))
local Tutorial = require(Shared.Tutorial)

local SoundPlayer = require(script.Parent:WaitForChild("SoundPlayer"))
local UIKit = require(script.Parent:WaitForChild("UIKit"))
local CollectionUI = require(script.Parent:WaitForChild("CollectionUI"))
local RunUI = require(script.Parent:WaitForChild("RunUI"))
local THEME = UIKit.THEME
local make, label, panel, button, corner, padding =
	UIKit.make, UIKit.label, UIKit.panel, UIKit.button, UIKit.corner, UIKit.padding

local MenuUI = {}

local callbacks
local lobby = {}
local result = {}

local lastState, lastProfile = nil, nil
local resultKey = nil
local lobbyTab = "barracks" -- recruit | barracks
local lobbyOpen = false -- Menü wird im Thronsaal über Einrichtungen/Thron geöffnet
local loadingMission = false
local throneSeated = false
local hubHud = {}
local throne = {}
local welcome = {}
local skipConfirmation = false

-- Kampf dieses Spielers? (Andere Spieler bleiben während eines fremden Kampfes im Thronsaal)
local function isMine(state)
	return state ~= nil and state.mode == "Battle" and state.ownerUserId == Players.LocalPlayer.UserId
end

local function otherBattle(state)
	return state ~= nil and state.mode == "Battle" and not isMine(state)
end

local EMPTY_PROFILE = { gold = 0, gems = 0, saveOk = true }

local function updateCurrency(textLabel, profile)
	local gold, gems = profile.gold or 0, profile.gems or 0
	if textLabel:GetAttribute("TargetGold") == gold and textLabel:GetAttribute("TargetGems") == gems then return end
	local fromGold = textLabel:GetAttribute("CurrentGold") or gold
	local fromGems = textLabel:GetAttribute("CurrentGems") or gems
	textLabel:SetAttribute("TargetGold", gold)
	textLabel:SetAttribute("TargetGems", gems)
	UIKit.countUp(textLabel, 0, 1, function(alpha)
		local shownGold = math.floor(fromGold + (gold - fromGold) * alpha + 0.5)
		local shownGems = math.floor(fromGems + (gems - fromGems) * alpha + 0.5)
		textLabel:SetAttribute("CurrentGold", shownGold)
		textLabel:SetAttribute("CurrentGems", shownGems)
		return ("<font color='%s'>◆</font> %d Gold     <font color='#6ee8ff'>♦</font> %d Edelsteine"):format(UIKit.GOLD_HEX, shownGold, shownGems)
	end)
end

local function buildLobby(root)
	local f = panel({
		Animated = true,
		AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(1000, 640),
		Visible = false,
	}, root)
	padding(f, 18)
	lobby.frame = f

	lobby.title = label({
		Size = UDim2.new(0.5, 0, 0, 40), Font = THEME.title, TextSize = 38, TextColor3 = THEME.gold,
		Text = "Kaserne", TextXAlignment = Enum.TextXAlignment.Left,
	}, f)
	lobby.currency = label({
		AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -56, 0, 0), Size = UDim2.new(0.5, -56, 0, 40),
		Font = THEME.bold, TextSize = 20, TextXAlignment = Enum.TextXAlignment.Right,
	}, f)
	local close = button("X", f, "muted")
	close.AnchorPoint = Vector2.new(1, 0)
	close.Position = UDim2.fromScale(1, 0)
	close.Size = UDim2.fromOffset(44, 40)
	close.TextSize = 22
	close.Activated:Connect(function()
		MenuUI.closeLobby()
	end)
	lobby.saveWarning = label({
		Position = UDim2.fromOffset(0, 40), Size = UDim2.new(1, 0, 0, 32), TextSize = 13, TextColor3 = THEME.warn, TextWrapped = true, TextScaled = false,
		TextXAlignment = Enum.TextXAlignment.Left, Visible = false,
		Text = "⚠ Speichern nicht verfügbar – Fortschritt gilt nur für diese Sitzung (Studio: Game Settings → Security → API-Zugriff aktivieren).",
	}, f)

	-- Reiter: Rekrutieren · Kaserne
	local tabBar = make("Frame", {
		Position = UDim2.fromOffset(0, 80), Size = UDim2.new(1, 0, 0, 42), BackgroundTransparency = 1,
	}, f)
	make("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder,
	}, tabBar)
	lobby.tabButtons = {}
	lobby.pages = {}
	for i, tab in { { "recruit", "Rekrutieren" }, { "barracks", "Kaserne" } } do
		local b = button(tab[2], tabBar, "default", i)
		b.Size = UDim2.fromOffset(200, 42)
		b.Activated:Connect(function()
			lobbyTab = tab[1]
			MenuUI.update(lastState, lastProfile)
		end)
		lobby.tabButtons[tab[1]] = b
		lobby.pages[tab[1]] = make("Frame", {
			Position = UDim2.fromOffset(0, 132), Size = UDim2.new(1, 0, 1, -132), BackgroundTransparency = 1,
			Visible = false,
		}, f)
	end
end

local function updateLobby(profile)
	updateCurrency(lobby.currency, profile)
	lobby.saveWarning.Visible = not profile.saveOk
end

-- Ergebnis ---------------------------------------------------------------------------
local function buildResult(root)
	local overlay = make("Frame", {
		Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(0, 0, 0), BackgroundTransparency = 0.45,
		Visible = false, ZIndex = 10,
	}, root)
	result.frame = overlay
	local box = panel({
		Animated = true,
		AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(480, 540),
		ZIndex = 11,
	}, overlay)
	padding(box, 18)
	result.box = box
	result.title = label({
		Size = UDim2.new(1, 0, 0, 64), Font = THEME.title, TextSize = 64, ZIndex = 12,
	}, box)
	result.sub = label({
		Position = UDim2.fromOffset(0, 64), Size = UDim2.new(1, 0, 0, 20), TextColor3 = THEME.dim, ZIndex = 12,
	}, box)

	local resultDetails = UIKit.textList({
		Position = UDim2.fromOffset(0, 108), Size = UDim2.new(1, 0, 1, -264), ZIndex = 12,
	}, box)
	result.goals = UIKit.flowLabel({
		Size = UDim2.new(1, -12, 0, 0), TextSize = 17, ZIndex = 12, LayoutOrder = 1,
		TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top,
	}, resultDetails)
	result.rewards = UIKit.flowLabel({
		Size = UDim2.new(1, -12, 0, 0), Font = THEME.bold, TextSize = 19, ZIndex = 12, LayoutOrder = 2,
	}, resultDetails)

	local buttons = make("Frame", {
		AnchorPoint = Vector2.new(0, 1), Position = UDim2.fromScale(0, 1), Size = UDim2.new(1, 0, 0, 148),
		BackgroundTransparency = 1, ZIndex = 12,
	}, box)
	make("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder }, buttons)
	result.next = button("Nächste Mission", buttons, "primary", 1)
	result.retry = button("Nochmal", buttons, "default", 2)
	result.lobby = button("Zum Thronsaal", buttons, "muted", 3)
	for _, b in { result.next, result.retry, result.lobby } do
		b.Size = UDim2.new(1, 0, 0, 44)
		b.ZIndex = 12
	end
	result.retry.Activated:Connect(function()
		if lastState and lastState.tutorial then
			callbacks.onStartTutorial(lastState.tutorial.mission, lastState.tutorial.replay)
		end
	end)
	result.next.Activated:Connect(function()
		if lastState and lastState.tutorial then callbacks.onStartTutorial(2, lastState.tutorial.replay) end
	end)
	result.lobby.Activated:Connect(function()
		lobbyOpen = false
		callbacks.onLobby()
	end)
end

local function updateResult(state, _profile)
	local info = state.resultInfo
	if not info then return end
	local key = state.stageId .. tostring(info.victory) .. state.turn
	if key ~= resultKey then resultKey = key; UIKit.popIn(result.box) end
	result.title.Text = info.victory and "Sieg!" or "Niederlage"
	result.title.TextColor3 = info.victory and THEME.gold or THEME.enemy
	result.sub.Text = Stages.get(state.stageId).name
	result.goals.Text = not info.victory and "Leon ist gefallen. Versuche die Mission erneut."
		or state.tutorial.mission == 1 and "Gut gemacht! In Mission 2 lernst du Magierin und Ritter kennen."
		or "Tutorial geschafft! Im Thronsaal kannst du jetzt einen Lauf starten."
	result.rewards.Text = info.gold and info.gold > 0 and ("◆ +%d Gold"):format(info.gold)
		or state.tutorial.replay and "Wiederholung – ohne Belohnung" or ""
	result.next.Visible = info.victory and state.tutorial.mission == 1
	result.next.Text = "Weiter zu Mission 2"
	result.retry.Visible = not info.victory
end

-- Thronsaal: kleine Anzeige oben + Hinweis unten ---------------------------------------
local function buildHubHud(root)
	local f = make("Frame", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Visible = false }, root)
	hubHud.frame = f
	local pill = panel({
		AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 10), Size = UDim2.fromOffset(460, 66),
	}, f)
	label({
		Position = UDim2.fromOffset(0, 4), Size = UDim2.new(1, 0, 0, 28), Font = THEME.title, TextSize = 26,
		TextColor3 = THEME.gold, Text = "Thronsaal",
	}, pill)
	hubHud.currency = label({
		Position = UDim2.fromOffset(8, 32), Size = UDim2.new(1, -16, 0, 28), Font = THEME.bold, TextSize = 15,
	}, pill)
	hubHud.notice = UIKit.flowLabel({
		AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 84), Size = UDim2.fromOffset(460, 26),
		BackgroundColor3 = Color3.fromRGB(10, 14, 32), BackgroundTransparency = 0.3, TextSize = 15,
		TextColor3 = THEME.warn, Visible = false,
	}, f)
	corner(hubHud.notice, 6)
	local touch = UserInputService.TouchEnabled and not UserInputService.MouseEnabled
	local hint = UIKit.flowLabel({
		AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -16), Size = UDim2.fromOffset(640, 30),
		BackgroundColor3 = Color3.fromRGB(10, 14, 32), BackgroundTransparency = 0.35, TextSize = 15,
		Text = touch and "Geh zu einer Einrichtung und tippe auf das Symbol – oder spring auf den <b>Thron</b>."
			or "Geh zu einer Einrichtung und drücke <b>E</b> – oder spring auf den <b>Thron</b> für das Schnellmenü.",
	}, f)
	corner(hint, 6)
end

-- Schnellmenü auf dem Thron ----------------------------------------------------------------
local function buildThroneMenu(root)
	local f = panel({
		Animated = true,
		AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -24, 0.5, 0), Size = UDim2.fromOffset(300, 410),
		Visible = false,
	}, root)
	throne.frame = f
	local content = make("Frame", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1 }, f)
	padding(content, 14)
	make("UIListLayout", { Padding = UDim.new(0, 10), SortOrder = Enum.SortOrder.LayoutOrder }, content)
	label({
		Size = UDim2.new(1, 0, 0, 36), Font = THEME.title, TextSize = 32, TextColor3 = THEME.gold,
		Text = "★  Thron", LayoutOrder = 0,
	}, content)
	local entries = {
		{ "run", "Lauf starten", "primary" },
		{ "tutorial", "Tutorial wiederholen", "default" },
		{ "recruit", "Rekrutieren", "default" },
		{ "barracks", "Kaserne", "default" },
	}
	for i, e in entries do
		local b = button(e[2], content, e[3], i)
		b.Size = UDim2.new(1, 0, 0, 52)
		b.TextSize = 20
		throne[e[1]] = b
		b.Activated:Connect(function()
			if b:GetAttribute("Style") == "disabled" then return end
			if e[1] == "run" then RunUI.openTeam()
			elseif e[1] == "tutorial" then callbacks.onStartTutorial(1, true)
			else MenuUI.openLobby(e[1]) end
		end)
	end
	local stand = button("Aufstehen", content, "muted", 10)
	stand.Size = UDim2.new(1, 0, 0, 44)
	stand.Activated:Connect(function()
		callbacks.onStandUp()
	end)
end

-- Erste Wahl mit ausdrücklicher Bestätigung beim Überspringen.
local function buildWelcome(root)
	welcome.frame = make("Frame", {
		Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(0, 0, 0),
		BackgroundTransparency = 0.35, Active = true, Visible = false, ZIndex = 60,
	}, root)
	local box = panel({ AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(760, 400), ZIndex = 61 }, welcome.frame)
	welcome.title = label({ Position = UDim2.fromOffset(24, 24), Size = UDim2.new(1, -48, 0, 60),
		Text = "Willkommen im Thronsaal!", Font = THEME.title, TextSize = 38, TextColor3 = THEME.gold, ZIndex = 62 }, box)
	welcome.text = label({ Position = UDim2.fromOffset(24, 100), Size = UDim2.new(1, -48, 0, 164),
		Text = "Lerne in zwei kurzen Missionen, wie du dein Team bewegst und angreifst. Danach kannst du deinen ersten Lauf starten.",
		TextSize = 25, TextWrapped = true, TextScaled = false, ZIndex = 62 }, box)
	welcome.play = button("Tutorial spielen", box, "primary")
	welcome.play.Position, welcome.play.Size, welcome.play.ZIndex = UDim2.fromOffset(24, 302), UDim2.fromOffset(344, 68), 62
	welcome.play.TextSize = 24
	welcome.play.Activated:Connect(function()
		if welcome.play:GetAttribute("Style") == "disabled" then return end
		if skipConfirmation then skipConfirmation = false; MenuUI.update(lastState, lastProfile)
		else callbacks.onTutorialChoice(true) end
	end)
	welcome.skip = button("Überspringen", box, "muted")
	welcome.skip.Position, welcome.skip.Size, welcome.skip.ZIndex = UDim2.fromOffset(392, 302), UDim2.fromOffset(344, 68), 62
	welcome.skip.TextSize = 24
	welcome.skip.Activated:Connect(function()
		if welcome.skip:GetAttribute("Style") == "disabled" then return end
		if skipConfirmation then callbacks.onTutorialChoice(false)
		else skipConfirmation = true; MenuUI.update(lastState, lastProfile) end
	end)
end

-- Öffentliche API --------------------------------------------------------------------
function MenuUI.init(root, cbs)
	callbacks = cbs
	buildHubHud(root)
	buildLobby(root)
	buildResult(root)
	buildThroneMenu(root)
	buildWelcome(root)
	CollectionUI.build(lobby.pages.recruit, lobby.pages.barracks, root, { onRecruit = cbs.onRecruit })
	local runCallbacks = table.clone(cbs)
	runCallbacks.onChanged = function() MenuUI.update(lastState, lastProfile) end
	RunUI.init(root, runCallbacks)
end

function MenuUI.openLobby(tab)
	if tab == "run" then RunUI.openTeam(); return end
	if lastProfile and lastProfile.tutorial and lastProfile.tutorial.state == "new" then return end
	if not lobbyOpen then SoundPlayer.play("open") end
	lobbyTab = (tab == "recruit" or tab == "barracks") and tab or lobbyTab
	lobbyOpen = true
	MenuUI.update(lastState, lastProfile)
end

function MenuUI.closeLobby()
	if lobbyOpen then SoundPlayer.play("close") end
	lobbyOpen = false
	MenuUI.update(lastState, lastProfile)
end

function MenuUI.setLoading(active)
	loadingMission = active
	MenuUI.update(lastState, lastProfile)
end

function MenuUI.setThrone(seated)
	throneSeated = seated
	MenuUI.update(lastState, lastProfile)
end

function MenuUI.showRecruitResults(list)
	CollectionUI.showResults(list)
end

local TAB_TITLES = { recruit = "Rekrutierung", barracks = "Kaserne" }

function MenuUI.update(state, profile)
	if not state then
		return
	end
	profile = profile or EMPTY_PROFILE
	lastState, lastProfile = state, profile

	local runActive = RunUI.update(state, profile, loadingMission)
	local mine = isMine(state)
	if mine or runActive then
		lobbyOpen = false -- eigener Kampf läuft: Thronsaal-Menüs zu
	end
	local needsChoice = profile.tutorial and profile.tutorial.state == "new"
	local showWelcome = needsChoice and not mine and not loadingMission
	welcome.frame.Visible = showWelcome == true
	if not needsChoice then skipConfirmation = false end
	if showWelcome then
		lobbyOpen = false
		welcome.title.Text = skipConfirmation and "Tutorial überspringen?" or "Willkommen im Thronsaal!"
		welcome.text.Text = skipConfirmation and "Du kannst das Tutorial später im Thronmenü ohne Belohnung wiederholen. Möchtest du es jetzt überspringen?"
			or "Lerne in zwei kurzen Missionen, wie du dein Team bewegst und angreifst. Danach kannst du deinen ersten Lauf starten."
		welcome.play.Text = skipConfirmation and "Zurück" or "Tutorial spielen"
		welcome.skip.Text = skipConfirmation and "Ja, überspringen" or "Überspringen"
		local blocked = state.busy or otherBattle(state)
		UIKit.setButtonStyle(welcome.play, blocked and "disabled" or "primary")
		UIKit.setButtonStyle(welcome.skip, blocked and "disabled" or "muted")
	end
	local inHall = not mine and not runActive and not showWelcome and not loadingMission
	local available = Tutorial.unlocked(profile) and not profile.run and not otherBattle(state) and not state.busy
	UIKit.setButtonStyle(throne.run, available and "primary" or "disabled")
	UIKit.setButtonStyle(throne.tutorial, available and "default" or "disabled")

	-- Thronsaal-Anzeige
	hubHud.frame.Visible = inHall and not lobbyOpen
	updateCurrency(hubHud.currency, profile)
	hubHud.notice.Visible = otherBattle(state)
	if otherBattle(state) then
		local stage = Stages.get(state.stageId)
		hubHud.notice.Text = ("⚔ %s kämpft gerade: %s"):format(state.ownerName or "Jemand", stage and stage.name or "")
	end
	UIKit.setVisible(throne.frame, inHall and throneSeated and not lobbyOpen)

	UIKit.setVisible(lobby.frame, inHall and lobbyOpen)
	if inHall and lobbyOpen then
		lobby.title.Text = TAB_TITLES[lobbyTab]
		for tab, page in lobby.pages do
			UIKit.fadePage(page, tab == lobbyTab)
			UIKit.setButtonStyle(lobby.tabButtons[tab], tab == lobbyTab and "active" or "default")
		end
		updateLobby(profile)
		CollectionUI.update(profile)
	end

	local showResult = not loadingMission and not runActive and mine and state.result ~= nil
	UIKit.setVisible(result.frame, showResult)
	if showResult then
		updateResult(state, profile)
	else
		resultKey = nil
	end
end

return MenuUI
