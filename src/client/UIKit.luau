-- Gemeinsame UI-Bausteine im Fire-Emblem-Stil: Farben, Fenster, Buttons, Balken, Skalierung
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local UnitData = require(Shared:WaitForChild("UnitData"))
local Config = require(Shared:WaitForChild("Config"))

local SoundPlayer = require(script.Parent:WaitForChild("SoundPlayer"))
local UIKit = {}

UIKit.THEME = {
	top = Color3.fromRGB(42, 60, 118),
	bottom = Color3.fromRGB(14, 20, 48),
	gold = Color3.fromRGB(228, 192, 108),
	goldDark = Color3.fromRGB(130, 102, 54),
	text = Color3.fromRGB(246, 242, 230),
	dim = Color3.fromRGB(170, 178, 204),
	player = Color3.fromRGB(120, 176, 255),
	enemy = Color3.fromRGB(255, 112, 112),
	good = Color3.fromRGB(120, 232, 140),
	bad = Color3.fromRGB(255, 120, 100),
	warn = Color3.fromRGB(255, 180, 80),
	barBg = Color3.fromRGB(8, 10, 24),
	title = Enum.Font.Fondamento,
	body = Enum.Font.GothamMedium,
	bold = Enum.Font.GothamBold,
}
UIKit.DIM_HEX = "#aab2cc"
UIKit.GOOD_HEX = "#78e88c"
UIKit.BAD_HEX = "#ff7864"
UIKit.GOLD_HEX = "#e4c06c"

local THEME = UIKit.THEME
local lastHoverSound = -math.huge

UIKit.BUTTON_STYLES = {
	default = { Color3.fromRGB(50, 68, 128), Color3.fromRGB(76, 100, 172) },
	primary = { Color3.fromRGB(176, 132, 40), Color3.fromRGB(214, 166, 60) },
	danger = { Color3.fromRGB(150, 48, 48), Color3.fromRGB(198, 70, 62) },
	muted = { Color3.fromRGB(56, 58, 76), Color3.fromRGB(82, 86, 108) },
	active = { Color3.fromRGB(60, 130, 90), Color3.fromRGB(80, 166, 116) },
	disabled = { Color3.fromRGB(38, 40, 52), Color3.fromRGB(38, 40, 52) },
}

function UIKit.make(className, props, parent)
	local inst = Instance.new(className)
	for k, v in props do
		inst[k] = v
	end
	inst.Parent = parent
	return inst
end
local make = UIKit.make

function UIKit.corner(parent, radius)
	return make("UICorner", { CornerRadius = UDim.new(0, radius) }, parent)
end

function UIKit.stroke(parent, color, thickness)
	return make("UIStroke", {
		Color = color, Thickness = thickness, ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
	}, parent)
end

function UIKit.padding(parent, px)
	local background = parent:FindFirstChild("Background")
	if background then
		-- Innenabstände sollen nur den Inhalt, nicht den Fensterhintergrund verkleinern.
		background.Position = UDim2.fromOffset(-px, -px)
		background.Size = UDim2.new(1, px * 2, 1, px * 2)
	end
	return make("UIPadding", {
		PaddingTop = UDim.new(0, px), PaddingBottom = UDim.new(0, px),
		PaddingLeft = UDim.new(0, px), PaddingRight = UDim.new(0, px),
	}, parent)
end

function UIKit.label(props, parent)
	props.BackgroundTransparency = props.BackgroundTransparency or 1
	props.TextColor3 = props.TextColor3 or THEME.text
	props.Font = props.Font or THEME.body
	props.TextSize = props.TextSize or 16
	props.RichText = true
	return make("TextLabel", props, parent)
end

-- Blaues Fenster mit Verlauf und Goldrand
function UIKit.panel(props, parent)
	local animated = props.Animated
	props.Animated = nil
	local transparency = props.BackgroundTransparency or 0.04
	props.BackgroundTransparency = 1
	props.BorderSizePixel = 0
	local f = make(animated and "CanvasGroup" or "Frame", props, parent)
	local background = make("Frame", {
		Name = "Background", Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(1, 1, 1),
		BackgroundTransparency = transparency, BorderSizePixel = 0, ZIndex = 0,
	}, f)
	UIKit.corner(background, 8)
	make("UIGradient", { Color = ColorSequence.new(THEME.top, THEME.bottom), Rotation = 90 }, background)
	UIKit.corner(f, 8)
	UIKit.stroke(f, THEME.gold, 2)
	return f
end

function UIKit.setButtonStyle(b, style)
	b:SetAttribute("Style", style)
	b.BackgroundColor3 = UIKit.BUTTON_STYLES[style][1]
	b.TextTransparency = style == "disabled" and 0.55 or 0
end

function UIKit.button(text, parent, style, order)
	local b = make("TextButton", {
		Text = text, Size = UDim2.new(1, 0, 0, 40), AutoButtonColor = false,
		TextColor3 = THEME.text, Font = THEME.bold, TextSize = 18,
		BorderSizePixel = 0, LayoutOrder = order or 0, RichText = true,
	}, parent)
	UIKit.corner(b, 6)
	local s = UIKit.stroke(b, THEME.goldDark, 1.5)
	UIKit.setButtonStyle(b, style or "default")
	local scale = make("UIScale", { Name = "ButtonScale" }, b)
	local scaleTween
	local hovered = false
	local function animateScale(value, duration, easing)
		if scaleTween then scaleTween:Cancel() end
		scaleTween = TweenService:Create(scale, TweenInfo.new(duration, easing or Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Scale = value })
		scaleTween:Play()
	end
	b.InputBegan:Connect(function(input)
		if b:GetAttribute("Style") ~= "disabled" and (input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1) then
			animateScale(Config.FEEL.buttonPressScale, Config.FEEL.buttonPressTime)
		end
	end)
	b.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
			animateScale(hovered and Config.FEEL.buttonHoverScale or 1, Config.FEEL.buttonReleaseTime, Enum.EasingStyle.Back)
		end
	end)
	b.Activated:Connect(function()
		if b:GetAttribute("Style") ~= "disabled" then SoundPlayer.play("click") end
	end)
	b.MouseEnter:Connect(function()
		if UserInputService.MouseEnabled and b:GetAttribute("Style") ~= "disabled" then
			hovered = true
			animateScale(Config.FEEL.buttonHoverScale, Config.FEEL.buttonReleaseTime)
		end
		local now = os.clock()
		if UserInputService.MouseEnabled and b:GetAttribute("Style") ~= "disabled" and now - lastHoverSound >= Config.FEEL.hoverSoundCooldown then
			lastHoverSound = now
			SoundPlayer.play("hover")
		end
		local colors = UIKit.BUTTON_STYLES[b:GetAttribute("Style")]
		TweenService:Create(b, TweenInfo.new(0.12), { BackgroundColor3 = colors[2] }):Play()
		s.Color = THEME.gold
	end)
	b.MouseLeave:Connect(function()
		hovered = false
		animateScale(1, Config.FEEL.buttonReleaseTime)
		local colors = UIKit.BUTTON_STYLES[b:GetAttribute("Style")]
		TweenService:Create(b, TweenInfo.new(0.12), { BackgroundColor3 = colors[1] }):Play()
		s.Color = THEME.goldDark
	end)
	return b
end

-- Balken mit optionaler Vorschau (z. B. KP nach dem Kampf)
function UIKit.bar(parent, position, size, color)
	local bg = make("Frame", {
		Position = position, Size = size, BackgroundColor3 = THEME.barBg, BorderSizePixel = 0,
	}, parent)
	UIKit.corner(bg, 4)
	UIKit.stroke(bg, THEME.goldDark, 1)
	local loss = make("Frame", { Size = UDim2.fromScale(0, 1), BackgroundColor3 = THEME.bad, BorderSizePixel = 0 }, bg)
	UIKit.corner(loss, 4)
	local fill = make("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = color, BorderSizePixel = 0 }, bg)
	UIKit.corner(fill, 4)
	make("UIGradient", {
		Color = ColorSequence.new(Color3.new(1, 1, 1), Color3.fromRGB(170, 170, 170)), Rotation = 90,
	}, fill)
	local text = UIKit.label({
		Size = UDim2.fromScale(1, 1), Font = THEME.bold, TextSize = 13, ZIndex = 3, TextStrokeTransparency = 0.4,
	}, bg)
	return { bg = bg, fill = fill, loss = loss, text = text }
end

function UIKit.setBar(b, value, max, after)
	local ratio = math.clamp(value / max, 0, 1)
	local afterRatio = math.clamp((after or value) / max, 0, 1)
	b.fill.Size = UDim2.fromScale(afterRatio, 1)
	b.loss.Size = UDim2.fromScale(ratio, 1)
	if after and after < value then
		b.text.Text = ("%d → %d"):format(value, after)
	else
		b.text.Text = ("%d / %d"):format(value, max)
	end
end

function UIKit.hpColor(ratio)
	if ratio > 0.5 then
		return Color3.fromRGB(96, 214, 116)
	elseif ratio > 0.25 then
		return Color3.fromRGB(235, 190, 60)
	end
	return Color3.fromRGB(225, 65, 65)
end

local windowStates = setmetatable({}, { __mode = "k" })
local counts = setmetatable({}, { __mode = "k" })

local function windowState(frame)
	local state = windowStates[frame]
	if not state then
		local background
		if not frame:IsA("CanvasGroup") then background = frame.BackgroundTransparency end
		state = { position = frame.Position, background = background, scale = frame:FindFirstChild("PopScale") or make("UIScale", { Name = "PopScale" }, frame), tweens = {}, token = 0, visible = frame.Visible }
		windowStates[frame] = state
	end
	return state
end

local function cancelWindow(state)
	state.token += 1
	for _, tween in state.tweens do tween:Cancel() end
	table.clear(state.tweens)
end

local function animateWindow(frame, visible, duration, slide, scaleTarget)
	local state = windowState(frame)
	cancelWindow(state)
	state.visible = visible
	local token = state.token
	-- CanvasGroups blenden auch ihre Texte und Porträts gemeinsam aus.
	local function tween(object, goal, easing)
		local animation = TweenService:Create(object, TweenInfo.new(duration, easing or Enum.EasingStyle.Quad, Enum.EasingDirection.Out), goal)
		table.insert(state.tweens, animation)
		animation:Play()
		return animation
	end
	tween(state.scale, { Scale = scaleTarget }, visible and Enum.EasingStyle.Back or Enum.EasingStyle.Quad)
	local goal = { Position = state.position + UDim2.fromOffset(0, slide) }
	if frame:IsA("CanvasGroup") then
		goal.GroupTransparency = visible and 0 or 1
	end
	local movement = tween(frame, goal)
	if not visible then
		movement.Completed:Once(function(status)
			if status == Enum.PlaybackState.Completed and state.token == token then frame.Visible = false end
		end)
	end
end

function UIKit.popIn(frame)
	local state = windowState(frame)
	state.scale.Scale = Config.FEEL.menuOpenScale
	frame.Position = state.position + UDim2.fromOffset(0, Config.FEEL.menuSlide)
	if not frame.Visible then
		if frame:IsA("CanvasGroup") then frame.GroupTransparency = 1 end
	end
	frame.Visible = true
	animateWindow(frame, true, Config.FEEL.menuOpenTime, 0, 1)
end

function UIKit.popOut(frame)
	if not frame.Visible then return end
	animateWindow(frame, false, Config.FEEL.menuCloseTime, Config.FEEL.menuSlide, Config.FEEL.menuCloseScale)
end

function UIKit.setVisible(frame, visible)
	local state = windowState(frame)
	if state.visible == visible then return end
	if visible then UIKit.popIn(frame) else UIKit.popOut(frame) end
end

function UIKit.fadePage(frame, visible)
	if not frame:IsA("CanvasGroup") then
		frame.Visible = visible
		return
	end
	local state = windowState(frame)
	if state.visible == visible then return end
	if visible then
		frame.Visible = true
		if frame:IsA("CanvasGroup") then frame.GroupTransparency = 1 end
	end
	animateWindow(frame, visible, Config.FEEL.tabFadeTime, 0, 1)
	frame.Active = visible
end

function UIKit.countUp(textLabel, from, to, formatFn)
	local previous = counts[textLabel]
	if previous then previous.tween:Cancel(); previous.value:Destroy() end
	local value = Instance.new("NumberValue")
	value.Value = from
	local function update()
		textLabel.Text = formatFn and formatFn(value.Value) or tostring(math.floor(value.Value + 0.5))
	end
	update()
	value.Changed:Connect(update)
	local animation = TweenService:Create(value, TweenInfo.new(Config.FEEL.countUpTime, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Value = to })
	local record = { tween = animation, value = value }
	counts[textLabel] = record
	animation.Completed:Once(function(status)
		if counts[textLabel] ~= record then return end
		if status == Enum.PlaybackState.Completed then value.Value = to; update() end
		counts[textLabel] = nil
		value:Destroy()
	end)
	animation:Play()
end

-- "★★★☆☆" in Seltenheitsfarbe
function UIKit.rarityStars(rarity)
	local r = UnitData.Rarities[rarity or 1]
	return ("<font color='%s'>%s</font><font color='#4a5068'>%s</font>"):format(
		r.hex, string.rep("★", rarity), string.rep("★", 5 - rarity))
end

-- Sterne einer Mission: gefüllt gold, leer dunkel
function UIKit.goalStars(count, max)
	max = max or 3
	return ("<font color='%s'>%s</font><font color='#4a5068'>%s</font>"):format(
		UIKit.GOLD_HEX, string.rep("★", count), string.rep("★", max - count))
end

-- 3D-Kopie einer Figur in einem ViewportFrame (Porträt)
function UIKit.portrait(viewport, camera, source, zoomOut)
	for _, child in viewport:GetChildren() do
		if child:IsA("Model") or child:IsA("WorldModel") then
			child:Destroy()
		end
	end
	if not source then
		return
	end
	local clone = source:Clone()
	for _, d in clone:GetDescendants() do
		if d:IsA("BillboardGui") or d:IsA("ParticleEmitter") then
			d:Destroy()
		end
	end
	clone:PivotTo(CFrame.new())
	local world = make("WorldModel", {}, viewport)
	clone.Parent = world
	local headY = source:GetAttribute("HeadY") or 4.8
	local d = zoomOut and 9 or 6
	camera.CFrame = CFrame.lookAt(Vector3.new(1.8, headY + 0.4, -d), Vector3.new(0, headY - (zoomOut and 1.6 or 0.8), 0))
end

-- Heldenporträts klonen die beim Serverstart erzeugten R15-Vorlagen.
function UIKit.heroPortrait(viewport, camera, heroId, zoomOut)
	viewport:SetAttribute("PortraitHero", heroId)
	local templates = ReplicatedStorage:FindFirstChild("HeroTemplates")
	local template = templates and templates:FindFirstChild(heroId)
	UIKit.portrait(viewport, camera, template, zoomOut)
	if template then return end
	task.spawn(function()
		local available = templates or ReplicatedStorage:WaitForChild("HeroTemplates", 10)
		if not available then return end
		local loaded = available:WaitForChild(heroId, 10)
		if loaded and viewport.Parent and viewport:GetAttribute("PortraitHero") == heroId then
			UIKit.portrait(viewport, camera, loaded, zoomOut)
		end
	end)
end

-- ViewportFrame mit Kamera für Porträts
function UIKit.viewport(parent, props)
	local vp = make("ViewportFrame", {
		Size = props.Size or UDim2.fromScale(1, 1), Position = props.Position or UDim2.new(),
		BackgroundTransparency = 1, Ambient = Color3.fromRGB(170, 170, 180),
		LightColor = Color3.new(1, 1, 1), LightDirection = Vector3.new(-1, -1, 1),
		ZIndex = props.ZIndex or 1,
	}, parent)
	local cam = make("Camera", { FieldOfView = props.FieldOfView or 40 }, vp)
	vp.CurrentCamera = cam
	return vp, cam
end

-- Karte mit Seltenheitsrahmen (für Kaserne, Aufstellung, Rekrutierung)
function UIKit.heroCard(parent, heroId, props)
	local def = UnitData.Heroes[heroId]
	local rarity = UnitData.Rarities[def.rarity]
	local card = make("TextButton", {
		Size = props.Size or UDim2.fromOffset(150, 200), Text = "", AutoButtonColor = false,
		LayoutOrder = props.LayoutOrder or 0, BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0,
		ZIndex = props.ZIndex or 1,
	}, parent)
	UIKit.corner(card, 8)
	local stroke = UIKit.stroke(card, rarity.color, 3)
	make("UIGradient", {
		Color = ColorSequence.new(rarity.color:Lerp(Color3.new(0, 0, 0), 0.35), Color3.fromRGB(14, 18, 40)), Rotation = 90,
	}, card)
	local z = (props.ZIndex or 1) + 1
	local vp, cam = UIKit.viewport(card, { Size = UDim2.new(1, 0, 1, -58), ZIndex = z })
	UIKit.heroPortrait(vp, cam, heroId, true)
	local name = UIKit.label({
		Position = UDim2.new(0, 0, 1, -58), Size = UDim2.new(1, 0, 0, 22), Font = THEME.title, TextSize = 20,
		TextColor3 = rarity.color, Text = def.name, ZIndex = z,
	}, card)
	local sub = UIKit.label({
		Position = UDim2.new(0, 0, 1, -36), Size = UDim2.new(1, 0, 0, 16), TextSize = 12, TextColor3 = THEME.dim,
		Text = UnitData.Classes[def.class].name, ZIndex = z,
	}, card)
	local stars = UIKit.label({
		Position = UDim2.new(0, 0, 1, -20), Size = UDim2.new(1, 0, 0, 16), TextSize = 14,
		Text = UIKit.rarityStars(def.rarity), ZIndex = z,
	}, card)
	local badge = UIKit.label({
		Position = UDim2.fromOffset(6, 6), Size = UDim2.fromOffset(84, 20), Font = THEME.bold, TextSize = 12,
		BackgroundTransparency = 0.15, BackgroundColor3 = Color3.fromRGB(30, 34, 54), Visible = false, ZIndex = z + 1,
	}, card)
	UIKit.corner(badge, 4)
	return { card = card, stroke = stroke, badge = badge, name = name, sub = sub, stars = stars, rarity = rarity }
end

-- Ganze Oberfläche skaliert mit der Bildschirmgröße (Designgröße 1280×720)
function UIKit.createRoot(gui)
	local root = make("Frame", { Name = "Root", BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1) }, gui)
	local scale = make("UIScale", {}, root)
	local camera = workspace.CurrentCamera
	local function update()
		local vp = camera.ViewportSize
		local s = math.clamp(math.min(vp.X / 1280, vp.Y / 720), 0.5, 1.15)
		scale.Scale = s
		root.Size = UDim2.fromScale(1 / s, 1 / s)
	end
	camera:GetPropertyChangedSignal("ViewportSize"):Connect(update)
	update()
	return root
end

return UIKit
