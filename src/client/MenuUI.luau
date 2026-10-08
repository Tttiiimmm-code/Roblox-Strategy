-- Menüs außerhalb des Kampfes: Kartenauswahl (mit Schwierigkeit), Aufstellung, Ergebnis
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local UnitData = require(Shared:WaitForChild("UnitData"))
local Stages = require(Shared:WaitForChild("Stages"))

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
local prep = {}
local result = {}

local selectedIndex, selectedDiff = nil, nil
local lastState, lastProfile = nil, nil
local resultKey = nil
local lobbyTab = "missions" -- missions | recruit | barracks
local lastSquad = nil -- zuletzt gewählte Helden (bleibt für "Nochmal" erhalten)
local lobbyOpen = false -- Menü wird im Thronsaal über Einrichtungen/Thron geöffnet
local loadingMission = false
local throneSeated = false
local hubHud = {}
local throne = {}

-- Kampf dieses Spielers? (Andere Spieler bleiben während eines fremden Kampfes im Thronsaal)
local function isMine(state)
	return state ~= nil and state.mode == "Battle" and state.ownerUserId == Players.LocalPlayer.UserId
end

local function otherBattle(state)
	return state ~= nil and state.mode == "Battle" and not isMine(state)
end

local EMPTY_PROFILE = { gold = 0, gems = 0, stars = {}, saveOk = true }

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

-- Kartenauswahl ---------------------------------------------------------------------
local MAP_SIZE = Vector2.new(1200, 720)

local function focusSelectedStage()
	if not lobby.mapFocusPending or not selectedIndex then return end
	local view = lobby.map.AbsoluteWindowSize
	if view.X <= 0 or view.Y <= 0 then return end
	local canvas = lobby.map.AbsoluteCanvasSize
	local pos = Stages.List[selectedIndex].mapPos
	lobby.map.CanvasPosition = Vector2.new(
		math.clamp(pos.X * canvas.X - view.X / 2, 0, math.max(0, canvas.X - view.X)),
		math.clamp(pos.Y * canvas.Y - view.Y / 2, 0, math.max(0, canvas.Y - view.Y)))
	lobby.mapFocusPending = false
end

local function buildWorldMap(missions)
	for _, entry in lobby.stageButtons or {} do
		if entry.pulse then entry.pulse:Cancel() end
	end
	if lobby.map then lobby.map:Destroy() end
	local map = make("ScrollingFrame", {
		Size = UDim2.new(0.6, -12, 1, 0), CanvasSize = UDim2.fromOffset(MAP_SIZE.X, MAP_SIZE.Y),
		ScrollingDirection = Enum.ScrollingDirection.XY, ScrollBarThickness = 6,
		ScrollBarImageColor3 = THEME.gold, BackgroundColor3 = THEME.barBg,
		BackgroundTransparency = 0.15, BorderSizePixel = 0, ClipsDescendants = true, Active = true,
	}, missions)
	lobby.map = map
	map:GetPropertyChangedSignal("AbsoluteWindowSize"):Connect(focusSelectedStage)
	local canvas = make("Frame", {
		Size = UDim2.fromOffset(MAP_SIZE.X, MAP_SIZE.Y), BackgroundTransparency = 1,
	}, map)
	for _, region in Stages.Regions do
		local area = region.area
		local color = region.comingSoon and Color3.fromRGB(110, 115, 125) or region.color
		local land = make("Frame", {
			Position = UDim2.fromOffset(area[1] * MAP_SIZE.X, area[2] * MAP_SIZE.Y),
			Size = UDim2.fromOffset(area[3] * MAP_SIZE.X, area[4] * MAP_SIZE.Y),
			BackgroundColor3 = Color3.new(1, 1, 1), BackgroundTransparency = region.comingSoon and 0.45 or 0.2,
			BorderSizePixel = 0, ZIndex = 1,
		}, canvas)
		corner(land, 40)
		make("UIGradient", { Color = ColorSequence.new(color:Lerp(Color3.new(1, 1, 1), 0.2), color), Rotation = 90 }, land)
		label({
			Position = UDim2.fromOffset(24, 18), Size = UDim2.new(1, -48, 0, 36),
			Font = THEME.title, TextSize = 30, Text = region.name, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 2,
		}, land)
		if region.comingSoon then
			label({ Position = UDim2.fromOffset(24, 58), Size = UDim2.new(1, -48, 0, 24),
				Text = "Bald verfügbar", TextColor3 = THEME.dim, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 2 }, land)
		end
	end
	lobby.paths = {}
	for _, stage in Stages.List do
		for _, requiredId in stage.requires do
			local from = Stages.get(requiredId).mapPos * MAP_SIZE
			local to = stage.mapPos * MAP_SIZE
			local delta = to - from
			local path = make("Frame", {
				AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromOffset((from.X + to.X) / 2, (from.Y + to.Y) / 2),
				Size = UDim2.fromOffset(delta.Magnitude, 8), Rotation = math.deg(math.atan2(delta.Y, delta.X)),
				BackgroundColor3 = THEME.goldDark, BackgroundTransparency = 0.5, BorderSizePixel = 0, ZIndex = 3,
			}, canvas)
			corner(path, 4)
			table.insert(lobby.paths, { frame = path, fromId = requiredId })
		end
	end
	lobby.stageButtons = {}
	for i, stage in Stages.List do
		local pos = stage.mapPos * MAP_SIZE
		local b = make("TextButton", {
			AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromOffset(pos.X, pos.Y), Size = UDim2.fromOffset(72, 72),
			BackgroundColor3 = THEME.barBg, TextColor3 = THEME.text, Text = tostring(i),
			Font = THEME.title, TextSize = 30, AutoButtonColor = false, BorderSizePixel = 0, ZIndex = 5,
		}, canvas)
		corner(b, 36)
		local stroke = UIKit.stroke(b, THEME.goldDark, 3)
		local ring = make("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(86, 86),
			BackgroundTransparency = 1, Visible = false, ZIndex = 6,
		}, b)
		corner(ring, 43)
		UIKit.stroke(ring, THEME.text, 2)
		local title = label({
			AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.fromOffset(pos.X, pos.Y + 44), Size = UDim2.fromOffset(220, 30),
			Font = THEME.title, TextSize = 24, ZIndex = 5,
		}, canvas)
		local stars = label({
			AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.fromOffset(pos.X, pos.Y + 76), Size = UDim2.fromOffset(220, 22),
			TextSize = 13, ZIndex = 5,
		}, canvas)
		local entry = { button = b, title = title, stars = stars, stroke = stroke, ring = ring }
		b.Activated:Connect(function()
			if b:GetAttribute("Unlocked") then
				SoundPlayer.play("click")
				selectedIndex = i
				MenuUI.update(lastState, lastProfile)
			end
		end)
		b.Destroying:Connect(function()
			if entry.pulse then entry.pulse:Cancel(); entry.pulse = nil end
		end)
		lobby.stageButtons[i] = entry
	end
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
		Text = "Weltkarte", TextXAlignment = Enum.TextXAlignment.Left,
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
		Position = UDim2.fromOffset(0, 40), Size = UDim2.new(1, 0, 0, 18), TextSize = 13, TextColor3 = THEME.warn,
		TextXAlignment = Enum.TextXAlignment.Left, Visible = false,
		Text = "⚠ Speichern nicht verfügbar – Fortschritt gilt nur für diese Sitzung (Studio: Game Settings → Security → API-Zugriff aktivieren).",
	}, f)

	-- Reiter: Missionen · Rekrutieren · Kaserne
	local tabBar = make("Frame", {
		Position = UDim2.fromOffset(0, 62), Size = UDim2.new(1, 0, 0, 42), BackgroundTransparency = 1,
	}, f)
	make("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder,
	}, tabBar)
	lobby.tabButtons = {}
	lobby.pages = {}
	for i, tab in { { "missions", "⚔  Weltkarte" }, { "recruit", "Rekrutieren" }, { "barracks", "Kaserne" } } do
		local b = button(tab[2], tabBar, "default", i)
		b.Size = UDim2.fromOffset(200, 42)
		b.Activated:Connect(function()
			lobbyTab = tab[1]
			MenuUI.update(lastState, lastProfile)
		end)
		lobby.tabButtons[tab[1]] = b
		lobby.pages[tab[1]] = make("Frame", {
			Position = UDim2.fromOffset(0, 114), Size = UDim2.new(1, 0, 1, -114), BackgroundTransparency = 1,
			Visible = false,
		}, f)
	end
	local missions = lobby.pages.missions

	buildWorldMap(missions)

	-- Details rechts
	local d = make("Frame", {
		Position = UDim2.fromScale(0.6, 0), Size = UDim2.new(0.4, 0, 1, 0),
		BackgroundColor3 = Color3.fromRGB(8, 12, 30), BackgroundTransparency = 0.35, BorderSizePixel = 0,
	}, missions)
	corner(d, 8)
	padding(d, 16)
	lobby.name = label({
		Size = UDim2.new(1, 0, 0, 36), Font = THEME.title, TextSize = 30, TextXAlignment = Enum.TextXAlignment.Left,
	}, d)
	lobby.desc = label({
		Position = UDim2.fromOffset(0, 40), Size = UDim2.new(1, 0, 0, 60), TextSize = 15, TextColor3 = THEME.dim,
		TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top,
	}, d)

	local tabs = make("Frame", {
		Position = UDim2.fromOffset(0, 110), Size = UDim2.new(1, 0, 0, 46), BackgroundTransparency = 1,
	}, d)
	make("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder,
	}, tabs)
	lobby.tabs = {}
	for i, diff in Stages.Difficulties do
		local t = button(diff.name, tabs, "default", i)
		t.Size = UDim2.new(1 / 3, -6, 1, 0)
		t.Activated:Connect(function()
			selectedDiff = diff.id
			MenuUI.update(lastState, lastProfile)
		end)
		lobby.tabs[diff.id] = t
	end

	lobby.rules = label({
		Position = UDim2.fromOffset(0, 166), Size = UDim2.new(1, 0, 0, 78), TextSize = 14,
		TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top,
	}, d)
	lobby.goals = label({
		Position = UDim2.fromOffset(0, 252), Size = UDim2.new(1, 0, 0, 86), TextSize = 14,
		TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top,
	}, d)
	lobby.rewards = label({
		Position = UDim2.fromOffset(0, 344), Size = UDim2.new(1, 0, 0, 50), TextSize = 14,
		TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left,
	}, d)
	lobby.start = button("⚔  Mission starten", d, "primary")
	lobby.start.AnchorPoint = Vector2.new(0, 1)
	lobby.start.Position = UDim2.fromScale(0, 1)
	lobby.start.Size = UDim2.new(1, 0, 0, 56)
	lobby.start.TextSize = 22
	lobby.start.TextWrapped = true
	lobby.start.TextScaled = true
	make("UITextSizeConstraint", { MinTextSize = 12, MaxTextSize = 22 }, lobby.start)
	lobby.start.Activated:Connect(function()
		if lobby.start:GetAttribute("Style") ~= "disabled" then
			callbacks.onStart(Stages.List[selectedIndex].id, selectedDiff)
		end
	end)
end

local function updateLobby(profile)
	updateCurrency(lobby.currency, profile)
	lobby.saveWarning.Visible = not profile.saveOk

	-- Standard: erste offene Mission, sonst letzte freigeschaltete Mission.
	if not selectedIndex then
		selectedIndex = 1
		for i in Stages.List do
			if Stages.isUnlocked(profile, i, "Easy") then
				selectedIndex = i
				if not Stages.isCleared(profile, Stages.List[i].id) then break end
			end
		end
		lobby.mapFocusPending = true
	end
	if lobby.mapFocusPending then task.defer(focusSelectedStage) end

	for _, path in lobby.paths do
		local cleared = Stages.isCleared(profile, path.fromId)
		path.frame.BackgroundColor3 = cleared and THEME.gold or THEME.goldDark
		path.frame.BackgroundTransparency = cleared and 0 or 0.5
	end

	for i, stage in Stages.List do
		local entry = lobby.stageButtons[i]
		local unlocked = Stages.isUnlocked(profile, i, "Easy")
		local cleared = Stages.isCleared(profile, stage.id)
		local status = not unlocked and "locked" or (cleared and "cleared" or "open")
		entry.button:SetAttribute("Unlocked", unlocked)
		entry.button.Active = unlocked
		entry.button.Selectable = unlocked
		entry.button.Text = unlocked and tostring(i) or "???"
		entry.button.BackgroundColor3 = unlocked and Stages.getRegion(stage.region).color or Color3.fromRGB(70, 72, 80)
		entry.title.Text = unlocked and stage.name or "???"
		entry.title.TextColor3 = unlocked and THEME.text or THEME.dim
		entry.ring.Visible = i == selectedIndex
		if entry.status ~= status then
			if entry.pulse then entry.pulse:Cancel(); entry.pulse = nil end
			entry.stroke.Color = cleared and THEME.gold or (unlocked and THEME.text or THEME.dim)
			entry.stroke.Transparency = 0
			if status == "open" then
				entry.pulse = TweenService:Create(entry.stroke,
					TweenInfo.new(1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), { Transparency = 0.6 })
				entry.pulse:Play()
			end
			entry.status = status
		end
		local parts = {}
		for _, diff in Stages.Difficulties do
			table.insert(parts, ("<font color='#%s'>%s</font> %s"):format(
				diff.color:ToHex(), string.sub(diff.name, 1, 1), UIKit.goalStars(Stages.bestStars(profile, stage.id, diff.id))))
		end
		entry.stars.Text = table.concat(parts, " ")
		entry.stars.Visible = unlocked
	end

	local stage = Stages.List[selectedIndex]
	if not selectedDiff then
		selectedDiff = Stages.isCleared(profile, stage.id) and "Normal" or "Easy"
	end
	local diff = Stages.getDifficulty(selectedDiff)
	lobby.name.Text = stage.name
	lobby.desc.Text = stage.description

	for id, tab in lobby.tabs do
		local d = Stages.getDifficulty(id)
		local unlocked = Stages.isUnlocked(profile, selectedIndex, id)
		tab.Text = d.name
		UIKit.setButtonStyle(tab, id == selectedDiff and "active" or (unlocked and "default" or "muted"))
	end

	local lines = { ("<font color='#%s'><b>%s</b></font>"):format(diff.color:ToHex(), diff.name) }
	for _, rule in diff.rules do
		table.insert(lines, "•  " .. rule)
	end
	lobby.rules.Text = table.concat(lines, "\n")

	local best = Stages.bestStars(profile, stage.id, diff.id)
	local goalLines = { ("<font color='%s'><b>Bestes Ergebnis</b></font>  %s"):format(UIKit.GOLD_HEX, UIKit.goalStars(best)) }
	for _, text in Stages.goalTexts(Stages.turnGoal(stage, diff)) do
		table.insert(goalLines, "★  " .. text)
	end
	lobby.goals.Text = table.concat(goalLines, "\n")

	local minGold = stage.baseGold * diff.rewardMul
	local maxGold = math.floor(minGold * 1.5)
	lobby.rewards.Text = ("<font color='%s'>Belohnung</font>   ◆ %d–%d Gold   ·   ♦ %d pro neuem Stern  (noch %d offen)"):format(
		UIKit.DIM_HEX, minGold, maxGold, diff.gemsPerStar, 3 - best)

	if otherBattle(lastState) then
		lobby.start.Text = ("%s kämpft gerade – bitte warten"):format(lastState.ownerName or "Jemand")
		UIKit.setButtonStyle(lobby.start, "disabled")
	elseif Stages.isUnlocked(profile, selectedIndex, diff.id) then
		lobby.start.Text = "⚔  Mission starten"
		UIKit.setButtonStyle(lobby.start, "primary")
	else
		lobby.start.Text = ("Zuerst auf %s schaffen"):format(Stages.getDifficulty(diff.requires).name)
		UIKit.setButtonStyle(lobby.start, "disabled")
	end
end

-- Aufstellung: Helden aus der eigenen Sammlung wählen ---------------------------------
local function buildPrep(root)
	local f = panel({
		AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -12), Size = UDim2.fromOffset(1140, 300),
		Visible = false,
	}, root)
	padding(f, 14)
	prep.frame = f
	prep.title = label({
		Size = UDim2.new(0.6, 0, 0, 32), Font = THEME.title, TextSize = 30, TextXAlignment = Enum.TextXAlignment.Left,
	}, f)
	prep.counter = label({
		AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -230, 0, 0), Size = UDim2.new(0.4, -230, 0, 32),
		Font = THEME.bold, TextSize = 18, TextXAlignment = Enum.TextXAlignment.Right,
	}, f)
	prep.cards = make("ScrollingFrame", {
		Position = UDim2.fromOffset(0, 40), Size = UDim2.new(1, -230, 1, -40), BackgroundTransparency = 1,
		BorderSizePixel = 0, ScrollBarThickness = 6, ScrollingDirection = Enum.ScrollingDirection.X,
		AutomaticCanvasSize = Enum.AutomaticSize.X, CanvasSize = UDim2.new(),
	}, f)
	make("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 10), SortOrder = Enum.SortOrder.LayoutOrder,
	}, prep.cards)

	local side = make("Frame", {
		AnchorPoint = Vector2.new(1, 0), Position = UDim2.fromScale(1, 0), Size = UDim2.new(0, 214, 1, 0),
		BackgroundTransparency = 1,
	}, f)
	prep.info = label({
		Size = UDim2.new(1, 0, 1, -120), TextSize = 14, TextWrapped = true, TextColor3 = THEME.dim,
		TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top,
	}, side)
	local begin = button("⚔  Kampf starten", side, "primary")
	begin.AnchorPoint = Vector2.new(0, 1)
	begin.Position = UDim2.new(0, 0, 1, -54)
	begin.Size = UDim2.new(1, 0, 0, 56)
	begin.TextSize = 20
	begin.Activated:Connect(function()
		lastSquad = table.clone(prep.selected)
		callbacks.onBegin(prep.selected)
	end)
	local back = button("Zurück", side, "muted")
	back.AnchorPoint = Vector2.new(0, 1)
	back.Position = UDim2.fromScale(0, 1)
	back.Size = UDim2.new(1, 0, 0, 44)
	back.Activated:Connect(function()
		lobbyOpen = true
		lobbyTab = "missions"
		callbacks.onLobby()
	end)
	prep.cardsById = {}
	prep.key = nil
	prep.selected = {}
end

local function isSelected(heroId)
	return table.find(prep.selected, heroId) ~= nil
end

local function refreshPrepCards(state)
	local limit = state.maxUnits or 0
	for heroId, c in prep.cardsById do
		local selected = isSelected(heroId)
		c.badge.Visible = true
		if heroId == "leon" then
			c.badge.Text = "★ Anführer"
			c.badge.BackgroundColor3 = Color3.fromRGB(150, 110, 30)
		elseif selected then
			c.badge.Text = " Dabei"
			c.badge.BackgroundColor3 = Color3.fromRGB(50, 130, 80)
		else
			c.badge.Text = "Reserve"
			c.badge.BackgroundColor3 = Color3.fromRGB(70, 70, 86)
		end
		c.card.BackgroundTransparency = selected and 0 or 0.5
		c.stroke.Transparency = selected and 0 or 0.6
	end
	prep.counter.Text = ("Einheiten  %d / %d"):format(#prep.selected, limit)
end

-- Vorauswahl: letzter Trupp, sonst Leon + stärkste Helden (Level, dann Seltenheit)
local function defaultSquad(owned, limit)
	local squad = { "leon" }
	local source = lastSquad or {}
	if #source == 0 then
		source = table.clone(owned)
		table.sort(source, function(a, b)
			local ea, eb = lastProfile.heroes[a], lastProfile.heroes[b]
			if (ea.level or 1) ~= (eb.level or 1) then
				return (ea.level or 1) > (eb.level or 1)
			end
			return UnitData.Heroes[a].rarity > UnitData.Heroes[b].rarity
		end)
	end
	for _, id in source do
		if #squad < limit and id ~= "leon" and lastProfile.heroes[id] then
			table.insert(squad, id)
		end
	end
	return squad
end

local function updatePrep(state, profile)
	local stage = Stages.get(state.stageId)
	local diff = Stages.getDifficulty(state.difficulty)
	prep.title.Text = ("Aufstellung  ·  %s  <font color='#%s'>(%s)</font>"):format(stage.name, diff.color:ToHex(), diff.name)
	local limit = state.maxUnits or 1

	local owned = {}
	for id in profile.heroes or {} do
		if UnitData.Heroes[id] then
			table.insert(owned, id)
		end
	end
	table.sort(owned, function(a, b)
		if a == "leon" or b == "leon" then
			return a == "leon"
		end
		local ra, rb = UnitData.Heroes[a].rarity, UnitData.Heroes[b].rarity
		if ra ~= rb then
			return ra > rb
		end
		return UnitData.Heroes[a].name < UnitData.Heroes[b].name
	end)

	-- Karten nur neu bauen, wenn Mission oder Sammlung sich geändert haben
	local key = state.stageId .. state.difficulty .. table.concat(owned, ",")
	if key ~= prep.key then
		prep.key = key
		for _, c in prep.cardsById do
			c.card:Destroy()
		end
		prep.cardsById = {}
		prep.selected = defaultSquad(owned, limit)
		for i, heroId in owned do
			local c = UIKit.heroCard(prep.cards, heroId, { LayoutOrder = i, Size = UDim2.new(0, 150, 1, -8) })
			local entry = profile.heroes[heroId]
			c.sub.Text = ("%s  ·  Lv %d"):format(UnitData.Classes[UnitData.Heroes[heroId].class].name, entry.level or 1)
			c.card.Activated:Connect(function()
				if heroId == "leon" then
					return
				end
				local index = table.find(prep.selected, heroId)
				if index then
					table.remove(prep.selected, index)
				elseif #prep.selected < limit then
					table.insert(prep.selected, heroId)
				end
				refreshPrepCards(lastState)
			end)
			prep.cardsById[heroId] = c
		end
	end
	refreshPrepCards(state)

	local enemies = 0
	for _, u in state.units do
		if u.team == "Enemy" then
			enemies += 1
		end
	end
	local lines = {
		("<font color='%s'><b>Gegner:</b></font> %d"):format(UIKit.GOLD_HEX, enemies),
		("<font color='%s'><b>Rundenziel:</b></font> %d"):format(UIKit.GOLD_HEX, state.turnGoal),
	}
	for _, rule in diff.rules do
		table.insert(lines, "•  " .. rule)
	end
	table.insert(lines, ("\nKarte antippen = aufstellen / Reserve (max. %d)"):format(limit))
	prep.info.Text = table.concat(lines, "\n")
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
		AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(480, 470),
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

	local starRow = make("Frame", {
		Position = UDim2.fromOffset(0, 92), Size = UDim2.new(1, 0, 0, 70), BackgroundTransparency = 1, ZIndex = 12,
	}, box)
	make("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal, HorizontalAlignment = Enum.HorizontalAlignment.Center,
		Padding = UDim.new(0, 14), SortOrder = Enum.SortOrder.LayoutOrder,
	}, starRow)
	result.stars = {}
	for i = 1, 3 do
		local s = label({
			Size = UDim2.fromOffset(70, 70), Text = "★", TextSize = 64, LayoutOrder = i, ZIndex = 12,
			Font = Enum.Font.GothamBlack,
		}, starRow)
		make("UIScale", {}, s)
		result.stars[i] = s
	end

	result.goals = label({
		Position = UDim2.fromOffset(20, 172), Size = UDim2.new(1, -40, 0, 90), TextSize = 17, ZIndex = 12,
		TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top,
	}, box)
	result.rewards = label({
		Position = UDim2.fromOffset(0, 268), Size = UDim2.new(1, 0, 0, 30), Font = THEME.bold, TextSize = 19, ZIndex = 12,
	}, box)

	local buttons = make("Frame", {
		AnchorPoint = Vector2.new(0, 1), Position = UDim2.fromScale(0, 1), Size = UDim2.new(1, 0, 0, 148),
		BackgroundTransparency = 1, ZIndex = 12,
	}, box)
	make("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder }, buttons)
	result.next = button("Nächste Mission", buttons, "primary", 1)
	result.retry = button("Nochmal", buttons, "default", 2)
	result.lobby = button("Kartenauswahl", buttons, "muted", 3)
	for _, b in { result.next, result.retry, result.lobby } do
		b.Size = UDim2.new(1, 0, 0, 44)
		b.ZIndex = 12
	end
	result.retry.Activated:Connect(function()
		callbacks.onRetry()
	end)
	result.lobby.Activated:Connect(function()
		lobbyOpen = true
		lobbyTab = "missions"
		callbacks.onLobby()
	end)
	result.next.Activated:Connect(function()
		if result.nextStage then
			selectedIndex = Stages.indexOf(result.nextStage)
			callbacks.onStart(result.nextStage, lastState.difficulty)
		end
	end)
end

local function animateStars(count)
	for i, s in result.stars do
		local scale = s:FindFirstChildOfClass("UIScale")
		s.TextColor3 = Color3.fromRGB(60, 64, 84)
		scale.Scale = 1
		if i <= count then
			task.delay(0.35 + i * 0.35, function()
				SoundPlayer.play("coin")
				s.TextColor3 = THEME.gold
				scale.Scale = 1.8
				TweenService:Create(scale, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
					Scale = 1,
				}):Play()
			end)
		end
	end
end

local function updateResult(state, profile)
	local info = state.resultInfo
	if not info then
		return
	end
	local stage = Stages.get(state.stageId)
	local diff = Stages.getDifficulty(state.difficulty)

	local key = state.stageId .. state.difficulty .. tostring(info.victory) .. state.turn .. tostring(state.lost)
	if key ~= resultKey then
		resultKey = key
		UIKit.popIn(result.box)
		animateStars(info.stars)
	end

	result.title.Text = info.victory and "Sieg!" or "Niederlage"
	result.title.TextColor3 = info.victory and THEME.gold or THEME.enemy
	result.sub.Text = ("%s  ·  <font color='#%s'>%s</font>  ·  Runde %d"):format(
		stage.name, diff.color:ToHex(), diff.name, state.turn)

	local lines = {}
	for i, text in Stages.goalTexts(state.turnGoal) do
		local mark = info.done[i] and ("<font color='%s'></font>"):format(UIKit.GOOD_HEX)
			or ("<font color='%s'>✗</font>"):format(UIKit.BAD_HEX)
		table.insert(lines, mark .. "" .. text)
	end
	result.goals.Text = table.concat(lines, "\n")

	local reward = profile.reward
	if reward then
		local gems = reward.gems > 0
			and ("  <font color='#6ee8ff'>♦</font> +%d  <font color='%s'>(%d neue Sterne)</font>"):format(
				reward.gems, UIKit.DIM_HEX, reward.newStars)
			or ""
		local hero = reward.newHero and UnitData.Heroes[reward.newHero]
		local heroText = hero and ("\n<font color='%s'>Neuer Held: %s</font>"):format(
			UnitData.Rarities[hero.rarity].hex, hero.name) or ""
		result.rewards.Text = ("<font color='%s'>◆</font> +%d Gold%s%s"):format(UIKit.GOLD_HEX, reward.gold, gems, heroText)
	else
		result.rewards.Text = ""
	end

	local index = Stages.indexOf(state.stageId)
	local nextStage = Stages.List[index + 1]
	result.nextStage = nil
	if info.victory and nextStage and Stages.isUnlocked(profile, index + 1, state.difficulty) then
		result.nextStage = nextStage.id
	end
	result.next.Visible = result.nextStage ~= nil
end

-- Thronsaal: kleine Anzeige oben + Hinweis unten ---------------------------------------
local function buildHubHud(root)
	local f = make("Frame", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Visible = false }, root)
	hubHud.frame = f
	local pill = panel({
		AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 10), Size = UDim2.fromOffset(380, 56),
	}, f)
	label({
		Position = UDim2.fromOffset(0, 4), Size = UDim2.new(1, 0, 0, 28), Font = THEME.title, TextSize = 26,
		TextColor3 = THEME.gold, Text = "Thronsaal",
	}, pill)
	hubHud.currency = label({
		Position = UDim2.fromOffset(0, 32), Size = UDim2.new(1, 0, 0, 18), Font = THEME.bold, TextSize = 15,
	}, pill)
	hubHud.notice = label({
		AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 72), Size = UDim2.fromOffset(460, 26),
		BackgroundColor3 = Color3.fromRGB(10, 14, 32), BackgroundTransparency = 0.3, TextSize = 15,
		TextColor3 = THEME.warn, Visible = false,
	}, f)
	corner(hubHud.notice, 6)
	local touch = UserInputService.TouchEnabled and not UserInputService.MouseEnabled
	local hint = label({
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
		AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -24, 0.5, 0), Size = UDim2.fromOffset(280, 392),
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
		{ "missions", "⚔  Weltkarte", "primary" },
		{ "recruit", "Rekrutieren", "default" },
		{ "barracks", "Kaserne", "default" },
	}
	for i, e in entries do
		local b = button(e[2], content, e[3], i)
		b.Size = UDim2.new(1, 0, 0, 52)
		b.TextSize = 20
		b.Activated:Connect(function()
			if e[1] == "run" then RunUI.openTeam() else MenuUI.openLobby(e[1]) end
		end)
	end
	local stand = button("Aufstehen", content, "muted", 10)
	stand.Size = UDim2.new(1, 0, 0, 44)
	stand.Activated:Connect(function()
		callbacks.onStandUp()
	end)
end

-- Öffentliche API --------------------------------------------------------------------
function MenuUI.init(root, cbs)
	callbacks = cbs
	buildHubHud(root)
	buildLobby(root)
	buildPrep(root)
	buildResult(root)
	buildThroneMenu(root)
	CollectionUI.build(lobby.pages.recruit, lobby.pages.barracks, root, { onRecruit = cbs.onRecruit })
	local runCallbacks = table.clone(cbs)
	runCallbacks.onChanged = function() MenuUI.update(lastState, lastProfile) end
	RunUI.init(root, runCallbacks)
end

function MenuUI.openLobby(tab)
	if not lobbyOpen then SoundPlayer.play("open") end
	lobbyTab = tab or lobbyTab
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

local TAB_TITLES = { missions = "Weltkarte", recruit = "Rekrutierung", barracks = "Kaserne" }

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
	local inHall = not mine and not runActive

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

	local showPrep = not loadingMission and not runActive and mine and state.phase == "Prep" and profile.heroes ~= nil
	UIKit.setVisible(prep.frame, showPrep)
	if showPrep then
		updatePrep(state, profile)
	else
		prep.key = nil
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
