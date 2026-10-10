-- Rekrutierung (Banner, Wahrscheinlichkeiten, Enthüllung) und Kaserne (Heldensammlung)
-- GRUNDGERÜST – Layout und Texte sind bewusst einfach gehalten und können frei umgebaut werden.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local UnitData = require(Shared:WaitForChild("UnitData"))
local Recruit = require(Shared:WaitForChild("Recruit"))

local SoundPlayer = require(script.Parent:WaitForChild("SoundPlayer"))
local UIKit = require(script.Parent:WaitForChild("UIKit"))
local THEME = UIKit.THEME
local make, label, panel, button, corner, padding =
	UIKit.make, UIKit.label, UIKit.panel, UIKit.button, UIKit.corner, UIKit.padding

local CollectionUI = {}

local BANNER = Recruit.Banners[1]
local callbacks
local profile = nil
local recruit, barracks, odds, results = {}, {}, {}, {}
local selectedHero = nil
local barracksFrame, barracksHome, barracksPosition, barracksSize
local campRun, campSelect

local function pct(value)
	local text = (value >= 1 and "%.1f" or "%.3f"):format(value)
	return (text:gsub("%.", ",")) .. " %"
end

local function ownedHeroes()
	local list = {}
	for id in (profile and profile.heroes or {}) do
		if UnitData.Heroes[id] then
			table.insert(list, id)
		end
	end
	table.sort(list, function(a, b)
		local ra, rb = UnitData.Heroes[a].rarity, UnitData.Heroes[b].rarity
		if ra ~= rb then
			return ra > rb
		end
		return UnitData.Heroes[a].name < UnitData.Heroes[b].name
	end)
	return list
end

local function totalHeroes()
	local n = 0
	for _ in UnitData.Heroes do
		n += 1
	end
	return n
end

-- Rekrutierung --------------------------------------------------------------------------
local function buildRecruit(frame)
	local art = UIKit.textList({
		Size = UDim2.new(1, -320, 1, 0), BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0,
	}, frame)
	art.BackgroundTransparency = 0
	corner(art, UIKit.METRICS.bannerRadius)
	UIKit.stroke(art, THEME.gold, 2)
	make("UIGradient", {
		Color = ColorSequence.new(THEME.bannerTop, THEME.bannerBottom), Rotation = 120,
	}, art)
	padding(art, 16)
	UIKit.chromeTitle({
		Size = UDim2.new(1, -12, 0, 44), TextSize = 44, Gold = true, LayoutOrder = 1,
		Text = BANNER.name, TextXAlignment = Enum.TextXAlignment.Left,
	}, art)
	UIKit.flowLabel({
		Size = UDim2.new(1, -12, 0, 0), TextSize = 15, TextColor3 = THEME.dim, LayoutOrder = 2,
		Text = BANNER.description, TextXAlignment = Enum.TextXAlignment.Left,
	}, art)
	UIKit.flowLabel({
		Size = UDim2.new(1, -12, 0, 0), Font = THEME.bold, TextSize = 14, LayoutOrder = 3,
		Text = ("<font color='%s'>Im Fokus</font>  (gleiche Chance wie alle Helden ihrer Seltenheit)"):format(UIKit.GOLD_HEX),
		TextXAlignment = Enum.TextXAlignment.Left,
	}, art)
	local row = make("Frame", {
		Size = UDim2.new(1, -12, 0, 320), BackgroundTransparency = 1, LayoutOrder = 4,
	}, art)
	make("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 16), SortOrder = Enum.SortOrder.LayoutOrder,
	}, row)
	for i, heroId in BANNER.featured do
		local c = UIKit.heroCard(row, heroId, { Size = UDim2.new(0, 190, 1, 0), LayoutOrder = i })
		c.card.Active = false
	end

	local side = make("Frame", {
		AnchorPoint = Vector2.new(1, 0), Position = UDim2.fromScale(1, 0), Size = UDim2.new(0, 300, 1, 0),
		BackgroundTransparency = 1,
	}, frame)
	recruit.gems = label({
		Size = UDim2.new(1, 0, 0, 30), Font = THEME.bold, TextSize = 22,
		BackgroundTransparency = 0, BackgroundColor3 = THEME.panelInset,
	}, side)
	make("UICorner", { CornerRadius = UDim.new(1, 0) }, recruit.gems)
	UIKit.stroke(recruit.gems, THEME.ink, 2)
	local rateLines = { ("<font color='%s'><b>Chancen pro Ruf</b></font>"):format(UIKit.GOLD_HEX) }
	for rarity = 5, 1, -1 do
		table.insert(rateLines, ("%s  %s  <b>%s</b>"):format(UIKit.rarityStars(rarity), UnitData.Rarities[rarity].name,
			pct(Recruit.RATES[rarity])))
	end
	local rateDetails = UIKit.textList({ Position = UDim2.fromOffset(0, 38), Size = UDim2.new(1, 0, 1, -216) }, side)
	UIKit.flowLabel({
		Size = UDim2.new(1, -12, 0, 0), TextSize = 15, LayoutOrder = 1,
		Text = table.concat(rateLines, "\n"), TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Top,
	}, rateDetails)
	recruit.pity = UIKit.flowLabel({
		Size = UDim2.new(1, -12, 0, 0), TextSize = 14, TextColor3 = THEME.dim, LayoutOrder = 2,
		TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top, TextWrapped = true,
	}, rateDetails)

	local buttons = make("Frame", {
		AnchorPoint = Vector2.new(0, 1), Position = UDim2.fromScale(0, 1), Size = UDim2.new(1, 0, 0, 190),
		BackgroundTransparency = 1,
	}, side)
	make("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder }, buttons)
	recruit.single = button(("1× rufen   <font color='#6ee8ff'>♦</font> %d"):format(BANNER.costSingle), buttons, "default", 1)
	recruit.multi = button(("10× rufen   <font color='#6ee8ff'>♦</font> %d"):format(BANNER.costMulti), buttons, "holo", 2)
	local oddsButton = button("ⓘ  Alle Wahrscheinlichkeiten", buttons, "muted", 3)
	for _, b in { recruit.single, recruit.multi, oddsButton } do
		b.Size = UDim2.new(1, 0, 0, 50)
	end
	recruit.multi.Size = UDim2.new(1, 0, 0, UIKit.METRICS.primaryHeight)
	recruit.single.Activated:Connect(function()
		if recruit.single:GetAttribute("Style") ~= "disabled" then
			callbacks.onRecruit(BANNER.id, 1)
		end
	end)
	recruit.multi.Activated:Connect(function()
		if recruit.multi:GetAttribute("Style") ~= "disabled" then
			callbacks.onRecruit(BANNER.id, 10)
		end
	end)
	oddsButton.Activated:Connect(function()
		UIKit.popIn(odds.box)
		UIKit.setVisible(odds.frame, true)
	end)
end

-- Vollständige Liste aller Ergebnisse mit Prozentwerten (Pflicht bei Zufallsitems gegen Robux)
local function buildOdds(root)
	local overlay = make("Frame", {
		Size = UDim2.fromScale(1, 1), BackgroundColor3 = THEME.backdrop, BackgroundTransparency = 0.35,
		Visible = false, ZIndex = 20,
	}, root)
	odds.frame = overlay
	local box = panel({
		Animated = true,
		AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(520, 560),
		ZIndex = 21,
	}, overlay)
	padding(box, 16)
	odds.box = box
	UIKit.chromeTitle({
		Size = UDim2.new(1, 0, 0, 34), TextSize = 32,
		Text = "Wahrscheinlichkeiten", ZIndex = 22,
	}, box)
	local list = make("ScrollingFrame", {
		Position = UDim2.fromOffset(0, 42), Size = UDim2.new(1, 0, 1, -94), BackgroundTransparency = 1,
		BorderSizePixel = 0, ScrollBarThickness = 6, AutomaticCanvasSize = Enum.AutomaticSize.Y,
		CanvasSize = UDim2.new(), ZIndex = 22,
	}, box)
	make("UIListLayout", { Padding = UDim.new(0, 2), SortOrder = Enum.SortOrder.LayoutOrder }, list)
	local order = 0
	local function row(text, size, bold)
		order += 1
		UIKit.flowLabel({
			Size = UDim2.new(1, -10, 0, size), Text = text, TextSize = bold and 17 or 15, LayoutOrder = order,
			Font = bold and THEME.bold or THEME.body, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 22,
		}, list)
	end
	for _, entry in Recruit.odds() do
		row(("%s  %s  —  %s"):format(UIKit.rarityStars(entry.rarity), UnitData.Rarities[entry.rarity].name, pct(entry.percent)),
			28, true)
		for _, h in entry.heroes do
			local def = UnitData.Heroes[h.id]
			row(("    %s  <font color='%s'>(%s)</font>   %s"):format(def.name, UIKit.DIM_HEX,
				UnitData.Classes[def.class].name, pct(h.percent)), 20, false)
		end
	end
	UIKit.flowLabel({
		Size = UDim2.new(1, -10, 0, 0), LayoutOrder = order + 1,
		TextSize = 13, TextColor3 = THEME.dim, TextWrapped = true, ZIndex = 22,
		TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top,
		Text = ("Garantie: Spätestens der %d. Ruf ohne ★4 oder besser bringt ★4 oder besser, spätestens der %d. Ruf ohne ★5 bringt ★5. Doppelte Helden werden verschmolzen (+%d KP, max. %d×)."):format(
			Recruit.PITY_4, Recruit.PITY_5, Recruit.MERGE_HP, Recruit.MAX_MERGES),
	}, list)
	local close = button("Schließen", box, "muted")
	close.AnchorPoint = Vector2.new(0, 1)
	close.Position = UDim2.fromScale(0, 1)
	close.Size = UDim2.new(1, 0, 0, 48)
	close.ZIndex = 22
	close.Activated:Connect(function()
		UIKit.setVisible(overlay, false)
	end)
end

-- Enthüllung nach dem Ruf
local function buildResults(root)
	local overlay = make("Frame", {
		Size = UDim2.fromScale(1, 1), BackgroundColor3 = THEME.backdrop, BackgroundTransparency = 0.35,
		Visible = false, ZIndex = 30,
	}, root)
	results.frame = overlay
	local box = panel({
		Animated = true,
		AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(940, 560),
		ZIndex = 31,
	}, overlay)
	padding(box, 16)
	results.box = box
	UIKit.chromeTitle({
		Size = UDim2.new(1, 0, 0, 40), TextSize = 38,
		Text = "Neue Verbündete", ZIndex = 32,
	}, box)
	results.grid = make("ScrollingFrame", {
		Position = UDim2.fromOffset(0, 50), Size = UDim2.new(1, 0, 1, -110), BackgroundTransparency = 1, ZIndex = 32,
		BorderSizePixel = 0, ScrollBarThickness = 6, ScrollingDirection = Enum.ScrollingDirection.Y,
		AutomaticCanvasSize = Enum.AutomaticSize.Y, CanvasSize = UDim2.new(),
	}, box)
	make("UIGridLayout", {
		CellSize = UDim2.fromOffset(170, 210), CellPadding = UDim2.fromOffset(10, 10),
		HorizontalAlignment = Enum.HorizontalAlignment.Center, SortOrder = Enum.SortOrder.LayoutOrder,
	}, results.grid)
	results.flash = make("Frame", {
		Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.fromRGB(255, 220, 120), BackgroundTransparency = 1,
		ZIndex = 40,
	}, overlay)
	local done = button("Weiter", box, "primary")
	done.AnchorPoint = Vector2.new(0.5, 1)
	done.Position = UDim2.fromScale(0.5, 1)
	done.Size = UDim2.fromOffset(260, 48)
	done.ZIndex = 32
	done.Activated:Connect(function()
		UIKit.setVisible(overlay, false)
	end)
end

function CollectionUI.showResults(list)
	for _, child in results.grid:GetChildren() do
		if child:IsA("GuiObject") then
			child:Destroy()
		end
	end
	UIKit.setVisible(results.frame, true)
	UIKit.popIn(results.box)
	for i, r in list do
		local c = UIKit.heroCard(results.grid, r.heroId, { LayoutOrder = i, ZIndex = 33 })
		c.badge.Visible = true
		c.badge.Text = r.isNew and "NEU!" or "+1 Verschm."
		c.badge.BackgroundColor3 = r.isNew and THEME.holoPink or THEME.panelInset
		local scale = make("UIScale", { Scale = 0 }, c.card)
		task.delay(0.15 + i * 0.22, function()
			TweenService:Create(scale, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()
			SoundPlayer.play(r.rarity >= 5 and "recruitLegendary" or r.rarity >= 4 and "recruitRare" or "recruit")
			if r.rarity >= 5 then
				results.flash.BackgroundTransparency = 0.2
				TweenService:Create(results.flash, TweenInfo.new(0.6), { BackgroundTransparency = 1 }):Play()
			end
		end)
	end
end

-- Kaserne ------------------------------------------------------------------------------
local function buildBarracks(frame)
	barracks.count = label({
		Size = UDim2.new(1, -320, 0, 24), Font = THEME.bold, TextSize = 16, TextXAlignment = Enum.TextXAlignment.Left,
	}, frame)
	barracks.list = make("ScrollingFrame", {
		Position = UDim2.fromOffset(0, 30), Size = UDim2.new(1, -320, 1, -30), BackgroundTransparency = 1,
		BorderSizePixel = 0, ScrollBarThickness = 6, AutomaticCanvasSize = Enum.AutomaticSize.Y, CanvasSize = UDim2.new(),
	}, frame)
	make("UIGridLayout", {
		CellSize = UDim2.fromOffset(122, 168), CellPadding = UDim2.fromOffset(8, 8), SortOrder = Enum.SortOrder.LayoutOrder,
	}, barracks.list)
	barracks.cards = {}

	local d = make("Frame", {
		AnchorPoint = Vector2.new(1, 0), Position = UDim2.fromScale(1, 0), Size = UDim2.new(0, 300, 1, 0),
		BackgroundColor3 = Color3.fromRGB(8, 12, 30), BackgroundTransparency = 0.35, BorderSizePixel = 0,
	}, frame)
	corner(d, 8)
	padding(d, 12)
	barracks.vp, barracks.cam = UIKit.viewport(d, { Size = UDim2.new(1, 0, 0, 170) })
	barracks.name = label({
		Position = UDim2.fromOffset(0, 172), Size = UDim2.new(1, 0, 0, 30), Font = THEME.title, TextSize = 28,
	}, d)
	local heroDetails = UIKit.textList({ Position = UDim2.fromOffset(0, 206), Size = UDim2.new(1, 0, 1, -206) }, d)
	barracks.sub = UIKit.flowLabel({
		Size = UDim2.new(1, -12, 0, 0), TextSize = 14, TextColor3 = THEME.dim, LayoutOrder = 1,
	}, heroDetails)
	barracks.exp = UIKit.bar(heroDetails, UDim2.new(), UDim2.new(1, -12, 0, 18), THEME.gold)
	barracks.exp.bg.LayoutOrder = 2
	barracks.stats = UIKit.flowLabel({
		Size = UDim2.new(1, -12, 0, 0), TextSize = 15, LayoutOrder = 3,
		TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top,
	}, heroDetails)
	barracks.extra = UIKit.flowLabel({
		Size = UDim2.new(1, -12, 0, 0), TextSize = 13, TextColor3 = THEME.dim, LayoutOrder = 4,
		TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top,
	}, heroDetails)
end

local function showHeroDetail(heroId)
	selectedHero = heroId
	local def = UnitData.Heroes[heroId]
	local entry = profile.heroes[heroId] or {}
	local rarity = UnitData.Rarities[def.rarity]
	local stats = entry.stats or def.stats
	local merges = entry.merges or 0
	UIKit.heroPortrait(barracks.vp, barracks.cam, heroId, true)
	barracks.name.Text = def.name
	barracks.name.TextColor3 = rarity.color
	barracks.sub.Text = ("%s  %s\n%s  ·  %s  ·  Lv %d"):format(UIKit.rarityStars(def.rarity), rarity.name,
		UnitData.Classes[def.class].name, UnitData.Weapons[def.weapon].name, entry.level or 1)
	UIKit.setBar(barracks.exp, entry.xp or 0, 100)
	barracks.exp.text.Text = ("EP %d / 100"):format(entry.xp or 0)
	local function s(stat)
		local value = stats[stat] + (stat == "hp" and merges * Recruit.MERGE_HP or 0)
		return ("<font color='%s'>%s</font> <b>%d</b>"):format(UIKit.DIM_HEX, UnitData.STAT_NAMES[stat], value)
	end
	barracks.stats.Text = ("%s     %s\n%s     %s\n%s     %s\n%s     %s"):format(
		s("hp"), s("str"), s("mag"), s("skl"), s("spd"), s("lck"), s("def"), s("res"))
	barracks.extra.Text = ("Verschmelzungen: <b>%d / %d</b>  (+%d KP)\nDoppelte Rekrutierungen verschmelzen automatisch."):format(
		merges, Recruit.MAX_MERGES, merges * Recruit.MERGE_HP)
	for id, c in barracks.cards do
		c.stroke.Thickness = id == heroId and 5 or 3
	end
end

local function updateBarracks()
	local heroes = ownedHeroes()
	barracks.count.Text = ("Helden gesammelt: <b>%d / %d</b>"):format(#heroes, totalHeroes())
	local key = table.concat(heroes, ",")
	if key ~= barracks.key then
		barracks.key = key
		for _, c in barracks.cards do
			c.card:Destroy()
		end
		barracks.cards = {}
		for i, heroId in heroes do
			local c = UIKit.heroCard(barracks.list, heroId, { LayoutOrder = i })
			c.card.Activated:Connect(function()
				showHeroDetail(heroId)
				if campSelect then campSelect(heroId) end
			end)
			barracks.cards[heroId] = c
		end
	end
	for heroId, c in barracks.cards do
		local entry = profile.heroes[heroId]
		c.badge.Visible = true
		local member = campRun and campRun.team[heroId]
		c.sub.Text = campRun and (member and not member.alive and "Gefallen in diesem Lauf"
			or table.find(campRun.order, heroId) and "Im Laufteam" or "Für Tausch verfügbar")
			or UnitData.Classes[UnitData.Heroes[heroId].class].name
		c.badge.Text = ("Lv %d%s"):format(entry.level or 1, (entry.merges or 0) > 0 and ("+" .. entry.merges) or "")
	end
	if not selectedHero or not profile.heroes[selectedHero] then
		selectedHero = heroes[1]
	end
	if selectedHero then
		showHeroDetail(selectedHero)
	end
end

-- Öffentliche API ----------------------------------------------------------------------
function CollectionUI.build(recruitFrame, collectionFrame, overlayRoot, cbs)
	callbacks = cbs
	barracksFrame, barracksHome = collectionFrame, collectionFrame.Parent
	barracksPosition, barracksSize = collectionFrame.Position, collectionFrame.Size
	buildRecruit(recruitFrame)
	buildBarracks(collectionFrame)
	buildOdds(overlayRoot)
	buildResults(overlayRoot)
end

function CollectionUI.restoreBarracks()
	if not campRun then return end
	campRun, campSelect = nil, nil
	barracksFrame.Parent = barracksHome
	barracksFrame.Position, barracksFrame.Size = barracksPosition, barracksSize
	barracksFrame.Visible = false
	updateBarracks()
end

function CollectionUI.mountCamp(parent, newProfile, onSelect)
	profile, campRun, campSelect = newProfile, newProfile.run, onSelect
	barracksFrame.Parent = parent
	barracksFrame.Position, barracksFrame.Size = UDim2.new(), UDim2.fromScale(1, 1)
	barracksFrame.Visible = true
	updateBarracks()
	if selectedHero then onSelect(selectedHero) end
end

function CollectionUI.update(newProfile)
	profile = newProfile
	if not profile or not profile.heroes then
		return
	end
	recruit.gems.Text = ("<font color='#6ee8ff'>♦</font> %d Edelsteine"):format(profile.gems)
	UIKit.setButtonStyle(recruit.single, profile.gems >= BANNER.costSingle and "default" or "disabled")
	UIKit.setButtonStyle(recruit.multi, profile.gems >= BANNER.costMulti and "holo" or "disabled")
	local to4, to5 = Recruit.pityRemaining(profile.pity or {})
	recruit.pity.Text = ("★4 oder besser garantiert in <b>%d</b> Rufen\n★5 garantiert in <b>%d</b> Rufen"):format(to4, to5)
	updateBarracks()
end

return CollectionUI
