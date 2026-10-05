-- Kampf-HUD: Phase, Hinweise, Einheiten-Info, Aktionsmenü, Kampfvorschau, Werkzeugleiste, Meldungen
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local UnitData = require(Shared:WaitForChild("UnitData"))
local Config = require(Shared:WaitForChild("Config"))
local Stages = require(Shared:WaitForChild("Stages"))

local SoundPlayer = require(script.Parent:WaitForChild("SoundPlayer"))
local UIKit = require(script.Parent:WaitForChild("UIKit"))
local THEME = UIKit.THEME
local make, label, panel, button, corner, padding =
	UIKit.make, UIKit.label, UIKit.panel, UIKit.button, UIKit.corner, UIKit.padding

local UI = {}

local root, hud, critFlash
local phaseLabel, turnLabel, stageLabel, hintLabel
local info = {}
local menuFrame, attackButton
local forecast = {}
local terrainFrame, terrainLabel
local tools = {}
local toastFrame, toastLabel
local level = {}
local banner = {}

local menuCallbacks, forecastCallbacks = {}, {}
local toastToken, levelToken, bannerToken = 0, 0, 0
local lastPhaseKey = nil
local portraitId = nil

-- Aufbau -------------------------------------------------------------------------
local function buildTop(callbacks)
	local pill = panel({
		AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 10), Size = UDim2.fromOffset(320, 52),
	}, hud)
	turnLabel = label({
		Position = UDim2.fromOffset(0, 4), Size = UDim2.new(1, 0, 0, 14),
		Font = THEME.bold, TextSize = 12, TextColor3 = THEME.gold,
	}, pill)
	phaseLabel = label({
		Position = UDim2.fromOffset(0, 17), Size = UDim2.new(1, 0, 0, 30), Font = THEME.title, TextSize = 26,
	}, pill)
	stageLabel = label({
		AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 66), Size = UDim2.fromOffset(420, 20),
		TextSize = 14, TextColor3 = THEME.dim, TextStrokeTransparency = 0.6,
	}, hud)

	-- Kontext-Hinweis oben links
	hintLabel = label({
		Position = UDim2.fromOffset(12, 12), Size = UDim2.fromOffset(330, 66),
		BackgroundColor3 = Color3.fromRGB(10, 14, 32), BackgroundTransparency = 0.3,
		TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top,
		TextSize = 15, TextWrapped = true,
	}, hud)
	corner(hintLabel, 6)
	padding(hintLabel, 8)

	-- Aufgeben mit Bestätigung
	local forfeit = button("⚑  Aufgeben", hud, "muted")
	forfeit.Position = UDim2.fromOffset(12, 86)
	forfeit.Size = UDim2.fromOffset(150, 34)
	forfeit.TextSize = 15
	local armed = false
	forfeit.Activated:Connect(function()
		if armed then
			armed = false
			forfeit.Text = "⚑  Aufgeben"
			callbacks.onForfeit()
			return
		end
		armed = true
		forfeit.Text = "Wirklich aufgeben?"
		UIKit.setButtonStyle(forfeit, "danger")
		task.delay(3, function()
			armed = false
			forfeit.Text = "⚑  Aufgeben"
			UIKit.setButtonStyle(forfeit, "muted")
		end)
	end)

	terrainFrame = panel({
		AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -12, 0, 12), Size = UDim2.fromOffset(250, 56),
		Visible = false,
	}, hud)
	padding(terrainFrame, 8)
	terrainLabel = label({
		Size = UDim2.fromScale(1, 1), TextXAlignment = Enum.TextXAlignment.Left, TextSize = 14, TextWrapped = true,
	}, terrainFrame)
end

local function buildInfo()
	local f = panel({
		AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, 12, 1, -12), Size = UDim2.fromOffset(400, 176),
		Visible = false,
	}, root)
	info.frame = f

	local frame = make("Frame", {
		Position = UDim2.fromOffset(10, 10), Size = UDim2.fromOffset(112, 156),
		BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0,
	}, f)
	corner(frame, 6)
	info.portraitStroke = UIKit.stroke(frame, THEME.gold, 2)
	info.portraitGradient = make("UIGradient", { Rotation = 90 }, frame)
	local vp = make("ViewportFrame", {
		Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1,
		Ambient = Color3.fromRGB(170, 170, 180), LightColor = Color3.new(1, 1, 1),
		LightDirection = Vector3.new(-1, -1, 1),
	}, frame)
	info.camera = make("Camera", { FieldOfView = 35 }, vp)
	vp.CurrentCamera = info.camera
	info.viewport = vp
	info.rarity = label({
		AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -2), Size = UDim2.new(1, 0, 0, 18),
		TextSize = 15, TextStrokeTransparency = 0.3, ZIndex = 2,
	}, frame)

	local x = 134
	local w = -x - 12
	info.name = label({
		Position = UDim2.fromOffset(x, 6), Size = UDim2.new(1, w, 0, 30), Font = THEME.title, TextSize = 28,
		TextXAlignment = Enum.TextXAlignment.Left,
	}, f)
	info.class = label({
		Position = UDim2.fromOffset(x, 36), Size = UDim2.new(1, w, 0, 16), TextSize = 14, TextColor3 = THEME.dim,
		TextXAlignment = Enum.TextXAlignment.Left,
	}, f)
	label({
		Position = UDim2.fromOffset(x, 58), Size = UDim2.fromOffset(28, 16), Font = THEME.bold, TextSize = 13,
		TextColor3 = THEME.gold, Text = "KP", TextXAlignment = Enum.TextXAlignment.Left,
	}, f)
	info.hp = UIKit.bar(f, UDim2.fromOffset(x + 28, 58), UDim2.new(1, w - 28, 0, 16), UIKit.hpColor(1))
	label({
		Position = UDim2.fromOffset(x, 79), Size = UDim2.fromOffset(28, 10), Font = THEME.bold, TextSize = 10,
		TextColor3 = THEME.gold, Text = "EP", TextXAlignment = Enum.TextXAlignment.Left,
	}, f)
	info.exp = UIKit.bar(f, UDim2.fromOffset(x + 28, 81), UDim2.new(1, w - 28, 0, 6), THEME.gold)
	info.exp.text.Visible = false

	local grid = make("Frame", {
		Position = UDim2.fromOffset(x, 96), Size = UDim2.new(1, w, 0, 44), BackgroundTransparency = 1,
	}, f)
	make("UIGridLayout", {
		CellSize = UDim2.new(0.25, -2, 0.5, -2), CellPadding = UDim2.fromOffset(2, 2),
		SortOrder = Enum.SortOrder.LayoutOrder,
	}, grid)
	info.stats = {}
	for i, stat in { "str", "mag", "skl", "spd", "lck", "def", "res", "mov" } do
		info.stats[stat] = label({ LayoutOrder = i, TextSize = 14, TextXAlignment = Enum.TextXAlignment.Left }, grid)
	end
	info.weapon = label({
		Position = UDim2.fromOffset(x, 146), Size = UDim2.new(1, w, 0, 20), TextSize = 13,
		TextXAlignment = Enum.TextXAlignment.Left,
	}, f)
end

local function buildMenu()
	menuFrame = panel({
		Animated = true,
		AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -16, 0.42, 0), Size = UDim2.fromOffset(200, 212),
		Visible = false,
	}, hud)
	local content = make("Frame", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1 }, menuFrame)
	padding(content, 10)
	make("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder }, content)
	label({
		Size = UDim2.new(1, 0, 0, 24), Font = THEME.title, TextSize = 22, TextColor3 = THEME.gold,
		Text = "Aktion", LayoutOrder = 0,
	}, content)
	attackButton = button("⚔  Angriff", content, "danger", 1)
	local waitButton = button("✓  Warten", content, "default", 2)
	local cancelButton = button("✕  Abbrechen", content, "muted", 3)
	for _, b in { attackButton, waitButton, cancelButton } do
		b.Size = UDim2.new(1, 0, 0, 46)
	end
	attackButton.Activated:Connect(function()
		if attackButton:GetAttribute("Style") ~= "disabled" and menuCallbacks.onAttack then
			menuCallbacks.onAttack()
		end
	end)
	waitButton.Activated:Connect(function()
		if menuCallbacks.onWait then
			menuCallbacks.onWait()
		end
	end)
	cancelButton.Activated:Connect(function()
		if menuCallbacks.onCancel then
			menuCallbacks.onCancel()
		end
	end)
end

local function buildForecast()
	local f = panel({
		Animated = true,
		AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 92), Size = UDim2.fromOffset(470, 256),
		Visible = false,
	}, hud)
	padding(f, 12)
	forecast.frame = f

	local function side(xScale, align, color)
		local s = {}
		s.name = label({
			Position = UDim2.new(xScale, 0, 0, 0), Size = UDim2.new(0.5, -6, 0, 28), Font = THEME.title, TextSize = 26,
			TextColor3 = color, TextXAlignment = align,
		}, f)
		s.weapon = label({
			Position = UDim2.new(xScale, 0, 0, 28), Size = UDim2.new(0.5, -6, 0, 18), TextSize = 14,
			TextColor3 = THEME.dim, TextXAlignment = align,
		}, f)
		s.hp = UIKit.bar(f, UDim2.new(xScale, xScale > 0 and 6 or 0, 0, 52), UDim2.new(0.5, -6, 0, 18), UIKit.hpColor(1))
		return s
	end
	forecast.left = side(0, Enum.TextXAlignment.Left, THEME.player)
	forecast.right = side(0.5, Enum.TextXAlignment.Right, THEME.enemy)

	forecast.rows = {}
	for i, key in { "dmg", "hit", "crit" } do
		local row = make("Frame", {
			Position = UDim2.fromOffset(0, 80 + (i - 1) * 32), Size = UDim2.new(1, 0, 0, 28),
			BackgroundColor3 = Color3.fromRGB(8, 12, 30), BackgroundTransparency = 0.4, BorderSizePixel = 0,
		}, f)
		corner(row, 4)
		local r = {}
		r.left = label({
			Position = UDim2.fromOffset(12, 0), Size = UDim2.new(0.35, -12, 1, 0), Font = THEME.bold, TextSize = 20,
			TextXAlignment = Enum.TextXAlignment.Left,
		}, row)
		label({
			AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.fromScale(0.5, 0), Size = UDim2.new(0.3, 0, 1, 0),
			TextSize = 14, TextColor3 = THEME.gold, Font = THEME.bold,
			Text = ({ dmg = "SCHADEN", hit = "TREFFER", crit = "KRIT" })[key],
		}, row)
		r.right = label({
			AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -12, 0, 0), Size = UDim2.new(0.35, -12, 1, 0),
			Font = THEME.bold, TextSize = 20, TextXAlignment = Enum.TextXAlignment.Right,
		}, row)
		forecast.rows[key] = r
	end

	local confirm = button("⚔  Angreifen!", f, "danger")
	confirm.Position = UDim2.new(0, 0, 1, -44)
	confirm.Size = UDim2.new(0.5, -5, 0, 44)
	local back = button("Zurück", f, "muted")
	back.Position = UDim2.new(0.5, 5, 1, -44)
	back.Size = UDim2.new(0.5, -5, 0, 44)
	confirm.Activated:Connect(function()
		if forecastCallbacks.onConfirm then
			forecastCallbacks.onConfirm()
		end
	end)
	back.Activated:Connect(function()
		if forecastCallbacks.onCancel then
			forecastCallbacks.onCancel()
		end
	end)
end

-- Unten rechts: Zurück · [Rückblende][Gefahr][Tempo] · Zug beenden
local function buildTools(callbacks)
	local col = make("Frame", {
		AnchorPoint = Vector2.new(1, 1), Position = UDim2.new(1, -16, 1, -16), Size = UDim2.fromOffset(210, 160),
		BackgroundTransparency = 1,
	}, hud)

	tools.endTurn = button("Zug beenden  ▸", col, "primary")
	tools.endTurn.AnchorPoint = Vector2.new(0, 1)
	tools.endTurn.Position = UDim2.fromScale(0, 1)
	tools.endTurn.Size = UDim2.new(1, 0, 0, 50)
	tools.endTurn.TextSize = 20
	tools.endTurn.Activated:Connect(callbacks.onEndTurn)

	local row = make("Frame", {
		AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, 0, 1, -58), Size = UDim2.new(1, 0, 0, 44),
		BackgroundTransparency = 1,
	}, col)
	make("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder,
	}, row)
	local function toolButton(text, order, cb)
		local b = button(text, row, "default", order)
		b.Size = UDim2.new(1 / 3, -4, 1, 0)
		b.TextSize = 15
		b.Activated:Connect(function()
			if b:GetAttribute("Style") ~= "disabled" then
				cb()
			end
		end)
		return b
	end
	tools.undo = toolButton("⟲ 0", 1, callbacks.onUndo)
	tools.danger = toolButton("⚠ Gefahr", 2, callbacks.onDanger)
	tools.speed = toolButton("▶ 1×", 3, callbacks.onSpeed)

	tools.skip = button("⏩ Gegnerphase", col, "primary")
	tools.skip.AnchorPoint = Vector2.new(0, 1)
	tools.skip.Position = UDim2.fromScale(0, 1)
	tools.skip.Size = UDim2.new(1, 0, 0, 50)
	tools.skip.Visible = false
	tools.skip.Activated:Connect(callbacks.onSkipEnemy)

	tools.back = button("↶  Zurück", col, "muted")
	tools.back.AnchorPoint = Vector2.new(0, 1)
	tools.back.Position = UDim2.new(0, 0, 1, -110)
	tools.back.Size = UDim2.new(1, 0, 0, 44)
	tools.back.Visible = false
	tools.back.Activated:Connect(callbacks.onBack)
end

local function buildPopups()
	toastFrame = panel({
		Animated = true,
		AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -24), Size = UDim2.fromOffset(460, 44),
		Visible = false, ZIndex = 5,
	}, root)
	toastLabel = label({ Size = UDim2.fromScale(1, 1), Font = THEME.bold, TextSize = 17, ZIndex = 5 }, toastFrame)

	local lf = panel({
		Animated = true,
		AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.45), Size = UDim2.fromOffset(320, 250),
		Visible = false, ZIndex = 6,
	}, root)
	padding(lf, 14)
	level.frame = lf
	label({
		Size = UDim2.new(1, 0, 0, 38), Font = THEME.title, TextSize = 38, TextColor3 = THEME.gold, Text = "Level Up!",
	}, lf)
	level.sub = label({ Position = UDim2.fromOffset(0, 40), Size = UDim2.new(1, 0, 0, 20), TextColor3 = THEME.dim }, lf)
	local grid = make("Frame", {
		Position = UDim2.fromOffset(0, 70), Size = UDim2.new(1, 0, 1, -70), BackgroundTransparency = 1,
	}, lf)
	make("UIGridLayout", {
		CellSize = UDim2.new(0.5, -4, 0.25, -4), CellPadding = UDim2.fromOffset(8, 4),
		SortOrder = Enum.SortOrder.LayoutOrder,
	}, grid)
	level.cells = {}
	for i, stat in UnitData.STAT_ORDER do
		local cell = label({
			LayoutOrder = i, TextSize = 18, TextXAlignment = Enum.TextXAlignment.Left,
			BackgroundColor3 = Color3.fromRGB(8, 12, 30), BackgroundTransparency = 0.4,
		}, grid)
		corner(cell, 4)
		padding(cell, 6)
		level.cells[stat] = cell
	end

	-- Phasen-Banner
	local bf = make("Frame", {
		Position = UDim2.new(-1, 0, 0.4, 0), Size = UDim2.new(1, 0, 0, 100),
		BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0, Visible = false, ZIndex = 8,
	}, root)
	local fade = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.2, 0.1),
		NumberSequenceKeypoint.new(0.8, 0.1), NumberSequenceKeypoint.new(1, 1),
	})
	banner.gradient = make("UIGradient", { Transparency = fade }, bf)
	for _, y in { 0, 1 } do
		local line = make("Frame", {
			AnchorPoint = Vector2.new(0, y), Position = UDim2.fromScale(0, y), Size = UDim2.new(1, 0, 0, 3),
			BackgroundColor3 = THEME.gold, BorderSizePixel = 0, ZIndex = 9,
		}, bf)
		make("UIGradient", { Transparency = fade }, line)
	end
	banner.label = label({
		Size = UDim2.fromScale(1, 1), Font = THEME.title, TextSize = 64, ZIndex = 9, TextStrokeTransparency = 0.5,
	}, bf)
	banner.frame = bf
end

-- Öffentliche API ----------------------------------------------------------------
function UI.init(callbacks)
	local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")
	local gui = make("ScreenGui", { Name = "TacticsUI", ResetOnSpawn = false, IgnoreGuiInset = false }, playerGui)
	root = UIKit.createRoot(gui)
	hud = make("Frame", { Name = "Hud", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Visible = false }, root)
	buildTop(callbacks)
	buildInfo()
	buildMenu()
	buildForecast()
	buildTools(callbacks)
	buildPopups()
	critFlash = make("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(1, 1, 1), BackgroundTransparency = 1, BorderSizePixel = 0, ZIndex = 100, Active = false }, root)
	return root
end

local flashTween
function UI.flashCrit(speed)
	if flashTween then flashTween:Cancel() end
	critFlash.BackgroundTransparency = Config.FEEL.critFlashTransparency
	flashTween = TweenService:Create(critFlash, TweenInfo.new(Config.FEEL.critFlashDuration / speed), { BackgroundTransparency = 1 })
	flashTween:Play()
end

function UI.setHudVisible(visible)
	hud.Visible = visible
end

function UI.setHint(text)
	hintLabel.Text = text
end

-- flags: { back, undoLeft, canUndo, danger, speed, controllable }
function UI.setTools(flags)
	tools.back.Visible = flags.back
	tools.endTurn.Visible = flags.controllable
	tools.skip.Visible = flags.enemyPhase
	UIKit.setButtonStyle(tools.skip, flags.speed == 3 and "disabled" or "primary")
	tools.undo.Text = ("⟲ %d"):format(flags.undoLeft)
	UIKit.setButtonStyle(tools.undo, (flags.controllable and flags.canUndo and flags.undoLeft > 0) and "default" or "disabled")
	UIKit.setButtonStyle(tools.danger, flags.danger and "active" or "default")
	tools.speed.Text = flags.speed == 3 and "⏩ 3×" or flags.speed == 2 and "▶▶ 2×" or "▶ 1×"
	UIKit.setButtonStyle(tools.speed, flags.speed == 2 and "active" or "default")
end

local function playBanner(text, color)
	bannerToken += 1
	local token = bannerToken
	local bf = banner.frame
	banner.label.Text = text
	banner.gradient.Color = ColorSequence.new(color:Lerp(Color3.new(0, 0, 0), 0.55), color:Lerp(Color3.new(0, 0, 0), 0.25))
	bf.Position = UDim2.new(-1, 0, 0.4, 0)
	bf.Visible = true
	TweenService:Create(bf, TweenInfo.new(0.35, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
		Position = UDim2.new(0, 0, 0.4, 0),
	}):Play()
	task.delay(1.2, function()
		if token ~= bannerToken then
			return
		end
		local out = TweenService:Create(bf, TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.In), {
			Position = UDim2.new(1, 0, 0.4, 0),
		})
		out:Play()
		out.Completed:Wait()
		if token == bannerToken then
			bf.Visible = false
		end
	end)
end

function UI.resetPhaseBanner()
	lastPhaseKey = nil
end

function UI.setPhase(state)
	local isPlayer = state.phase == "Player"
	turnLabel.Text = ("RUNDE %d  ·  ZIEL ≤ %d"):format(state.turn, state.turnGoal or 0)
	phaseLabel.Text = isPlayer and "Spielerphase" or "Gegnerphase"
	phaseLabel.TextColor3 = isPlayer and THEME.player or THEME.enemy

	local stage = Stages.get(state.stageId)
	local diff = Stages.getDifficulty(state.difficulty)
	if stage and diff then
		stageLabel.Text = ("%s  ·  <font color='#%s'>%s</font>"):format(stage.name, diff.color:ToHex(), diff.name)
	end

	local key = state.phase .. state.turn
	if key ~= lastPhaseKey and not state.result then
		lastPhaseKey = key
		SoundPlayer.play("phase")
		playBanner(phaseLabel.Text, isPlayer and Color3.fromRGB(60, 110, 230) or Color3.fromRGB(210, 50, 50))
	end
end

function UI.showInfo(unit, terrain)
	local cls = UnitData.Classes[unit.class]
	local w = UnitData.Weapons[unit.weapon]
	local rarity = UnitData.Rarities[unit.rarity or 1]
	if portraitId ~= unit.id then
		UIKit.popIn(info.frame)
		portraitId = unit.id
		local units = workspace:FindFirstChild("Units")
		UIKit.portrait(info.viewport, info.camera, units and units:FindFirstChild(unit.id))
		local team = unit.team == "Player" and rarity.color:Lerp(Color3.new(0, 0, 0), 0.35) or Color3.fromRGB(180, 60, 60)
		info.portraitGradient.Color = ColorSequence.new(team, Color3.fromRGB(16, 20, 40))
		info.portraitStroke.Color = unit.team == "Player" and rarity.color or THEME.gold
	end
	info.rarity.Text = unit.team == "Player" and UIKit.rarityStars(unit.rarity or 1) or ""
	info.name.Text = unit.name
	info.name.TextColor3 = unit.team == "Player" and rarity.color or THEME.enemy
	local status = unit.deployed == false and "  ·  Reserve" or (unit.done and "  ·  fertig" or "")
	info.class.Text = ("%s  ·  Lv %d%s"):format(cls.name, unit.level, status)
	UIKit.setBar(info.hp, unit.hp, unit.maxHp)
	info.hp.fill.BackgroundColor3 = UIKit.hpColor(unit.hp / unit.maxHp)
	UIKit.setBar(info.exp, unit.xp, 100)
	for stat, lbl in info.stats do
		local value = stat == "mov" and cls.mov or unit[stat]
		local name = stat == "mov" and "Bew" or UnitData.STAT_NAMES[stat]
		lbl.Text = ("<font color='%s'>%s</font> <b>%d</b>"):format(UIKit.DIM_HEX, name, value)
	end
	info.weapon.Text = ("<font color='%s'>Waffe</font>  <b>%s</b>  <font color='%s'>Mt %d · Rw %d–%d · %s +%d/+%d</font>"):format(
		UIKit.DIM_HEX, w.name, UIKit.DIM_HEX, w.might, w.minRange, w.maxRange, terrain.name, terrain.avoid, terrain.def)
	UIKit.setVisible(info.frame, true)
end

function UI.hideInfo()
	UIKit.setVisible(info.frame, false)
end

function UI.showTerrain(terrain)
	local extra = terrain.heal and ("   <font color='%s'>Heilung</font>"):format(UIKit.GOOD_HEX) or ""
	terrainLabel.Text = ("<font face='Fondamento' size='20'><b>%s</b></font>\n<font color='%s'>Ausweichen</font> +%d   <font color='%s'>Verteidigung</font> +%d%s")
		:format(terrain.name, UIKit.DIM_HEX, terrain.avoid, UIKit.DIM_HEX, terrain.def, extra)
	UIKit.setVisible(terrainFrame, true)
end

function UI.hideTerrain()
	UIKit.setVisible(terrainFrame, false)
end

function UI.showMenu(canAttack, callbacks)
	menuCallbacks = callbacks
	UIKit.setButtonStyle(attackButton, canAttack and "danger" or "disabled")
	UIKit.popIn(menuFrame)
end

function UI.hideMenu()
	UIKit.setVisible(menuFrame, false)
	menuCallbacks = {}
end

local function triangleText(tri)
	if tri > 0 then
		return (" <font color='%s'>▲</font>"):format(UIKit.GOOD_HEX)
	elseif tri < 0 then
		return (" <font color='%s'>▼</font>"):format(UIKit.BAD_HEX)
	end
	return ""
end

function UI.showForecast(attacker, defender, f, callbacks)
	forecastCallbacks = callbacks
	local a, d = f.attacker, f.defender
	local function fill(sideUi, unit, s, foe)
		sideUi.name.Text = unit.name
		sideUi.weapon.Text = UnitData.Weapons[unit.weapon].name .. triangleText(s.tri)
		local after = math.max(0, unit.hp - foe.dmg * foe.count)
		UIKit.setBar(sideUi.hp, unit.hp, unit.maxHp, after)
		sideUi.hp.fill.BackgroundColor3 = UIKit.hpColor(after / unit.maxHp)
	end
	fill(forecast.left, attacker, a, d)
	fill(forecast.right, defender, d, a)

	local function dmgText(s)
		if s.count == 0 then
			return "–"
		end
		return s.count == 2 and ("%d <font color='%s'>×2</font>"):format(s.dmg, UIKit.GOOD_HEX) or tostring(s.dmg)
	end
	local function pct(s, v)
		return s.count == 0 and "–" or (v .. "%")
	end
	forecast.rows.dmg.left.Text, forecast.rows.dmg.right.Text = dmgText(a), dmgText(d)
	forecast.rows.hit.left.Text, forecast.rows.hit.right.Text = pct(a, a.hit), pct(d, d.hit)
	forecast.rows.crit.left.Text, forecast.rows.crit.right.Text = pct(a, a.crit), pct(d, d.crit)
	UIKit.popIn(forecast.frame)
end

function UI.hideForecast()
	UIKit.setVisible(forecast.frame, false)
	forecastCallbacks = {}
end

function UI.toast(text, duration)
	toastToken += 1
	local token = toastToken
	toastLabel.Text = text
	UIKit.popIn(toastFrame)
	task.delay(duration or 2, function()
		if token == toastToken then
			UIKit.popOut(toastFrame)
		end
	end)
end

function UI.showLevelUp(e)
	SoundPlayer.play("levelUp")
	levelToken += 1
	local token = levelToken
	level.sub.Text = ("%s  ·  Lv %d"):format(e.unitName, e.level)
	for stat, cell in level.cells do
		local gained = e.gains[stat]
		cell.Text = ("<font color='%s'>%s</font>  <b>%d</b>%s"):format(
			UIKit.DIM_HEX, UnitData.STAT_NAMES[stat], e.stats[stat],
			gained and ("  <font color='%s'><b>+1</b></font>"):format(UIKit.GOOD_HEX) or "")
	end
	UIKit.popIn(level.frame)
	task.delay(3.2, function()
		if token == levelToken then
			UIKit.popOut(level.frame)
		end
	end)
end

return UI
