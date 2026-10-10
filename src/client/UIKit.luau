-- Gemeinsame UI-Bausteine im Fire-Emblem-Stil: Farben, Fenster, Buttons, Balken, Skalierung
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local UnitData = require(Shared:WaitForChild("UnitData"))
local Config = require(Shared:WaitForChild("Config"))

local SoundPlayer = require(script.Parent:WaitForChild("SoundPlayer"))
local UIKit = {}

UIKit.THEME = {
	ink = Color3.fromRGB(20, 26, 51),
	backdrop = Color3.fromRGB(11, 10, 38),
	panelTop = Color3.fromRGB(59, 63, 209),
	panelBottom = Color3.fromRGB(26, 22, 96),
	panelInset = Color3.fromRGB(17, 14, 69),
	panelLine = Color3.fromRGB(127, 134, 255),
	chromeLight = Color3.fromRGB(244, 247, 255),
	chromeMid = Color3.fromRGB(185, 194, 214),
	chromeDark = Color3.fromRGB(95, 104, 132),
	holoCyan = Color3.fromRGB(62, 240, 255),
	holoLilac = Color3.fromRGB(181, 140, 255),
	holoPink = Color3.fromRGB(255, 95, 210),
	holoLime = Color3.fromRGB(198, 255, 74),
	holoShade = Color3.fromRGB(122, 79, 214),
	holoGold = Color3.fromRGB(255, 243, 176),
	gold = Color3.fromRGB(255, 201, 60),
	goldShade = Color3.fromRGB(201, 138, 18),
	goldLight = Color3.fromRGB(255, 246, 208),
	gem = Color3.fromRGB(110, 232, 255),
	starEmpty = Color3.fromRGB(74, 80, 104),
	text = Color3.new(1, 1, 1),
	dim = Color3.fromRGB(210, 217, 245),
	player = Color3.fromRGB(120, 176, 255),
	enemy = Color3.fromRGB(255, 112, 112),
	good = Color3.fromRGB(120, 232, 140),
	bad = Color3.fromRGB(255, 120, 100),
	warn = Color3.fromRGB(255, 180, 80),
	title = Enum.Font.FredokaOne,
	body = Enum.Font.GothamMedium,
	bold = Enum.Font.FredokaOne,
	display = Enum.Font.LuckiestGuy,
	tech = Enum.Font.Michroma,
}
UIKit.THEME.bannerTop = UIKit.THEME.holoShade
UIKit.THEME.bannerBottom = UIKit.THEME.panelBottom
UIKit.THEME.top = UIKit.THEME.panelTop
UIKit.THEME.bottom = UIKit.THEME.panelBottom
UIKit.THEME.barBg = UIKit.THEME.panelInset
UIKit.THEME.goldDark = UIKit.THEME.goldShade
UIKit.DIM_HEX = "#d2d9f5"
UIKit.GOOD_HEX = "#78e88c"
UIKit.BAD_HEX = "#ff7864"
UIKit.GOLD_HEX = "#ffc93c"

local THEME = UIKit.THEME
local lastHoverSound = -math.huge

UIKit.METRICS = {
	smallRadius = 6, buttonRadius = 12, panelRadius = 16, bannerRadius = 24,
	buttonHeight = 48, primaryHeight = 64, buttonEdge = 5, pressedEdge = 1,
	panelBorder = 3, cardBorder = 4, selectedCardBorder = 6, shadowOffset = 8, forecastTop = 120,
}
local METRICS = UIKit.METRICS

local function chromeSequence()
	return ColorSequence.new({
		ColorSequenceKeypoint.new(0, THEME.chromeLight), ColorSequenceKeypoint.new(0.49, THEME.chromeMid),
		ColorSequenceKeypoint.new(0.5, THEME.chromeDark), ColorSequenceKeypoint.new(1, THEME.chromeLight),
	})
end

UIKit.BUTTON_STYLES = {
	default = { Color3.fromRGB(74, 141, 255), Color3.fromRGB(42, 95, 196) },
	primary = { THEME.gold, THEME.goldShade },
	danger = { Color3.fromRGB(255, 77, 77), Color3.fromRGB(194, 45, 54) },
	muted = { Color3.fromRGB(106, 113, 201), Color3.fromRGB(69, 75, 154) },
	active = { Color3.fromRGB(63, 209, 90), Color3.fromRGB(35, 150, 58) },
	disabled = { Color3.fromRGB(138, 144, 166), Color3.fromRGB(138, 144, 166) },
	holo = { THEME.holoCyan, THEME.holoShade },
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


-- Der ?u?ere Rand einer Scrollfl?che liegt au?erhalb ihrer abgeschnittenen Kinder.
function UIKit.bannerBorder(surface)
	local chrome = UIKit.stroke(surface, THEME.text, METRICS.panelBorder)
	make("UIGradient", { Color = chromeSequence(), Rotation = 90 }, chrome)
	local outer = make("Frame", {
		Name = "BannerOuterBorder", BackgroundTransparency = 1, BorderSizePixel = 0,
	}, surface.Parent)
	UIKit.corner(outer, METRICS.bannerRadius + METRICS.panelBorder)
	UIKit.stroke(outer, THEME.ink, METRICS.panelBorder)
	local function update()
		outer.AnchorPoint = surface.AnchorPoint
		outer.Position = surface.Position + UDim2.fromOffset(
			METRICS.panelBorder * (2 * surface.AnchorPoint.X - 1), METRICS.panelBorder * (2 * surface.AnchorPoint.Y - 1))
		outer.Size = surface.Size + UDim2.fromOffset(METRICS.panelBorder * 2, METRICS.panelBorder * 2)
		outer.ZIndex, outer.Visible = surface.ZIndex, surface.Visible
	end
	for _, property in { "Position", "Size", "AnchorPoint", "ZIndex", "Visible" } do
		surface:GetPropertyChangedSignal(property):Connect(update)
	end
	surface.Destroying:Connect(function() outer:Destroy() end)
	update()
	return chrome
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

-- Konturen folgen auch später gesetzten Schriften und Textgrößen.
function UIKit.outline(text, enabled, thickness)
	local outline = make("UIStroke", {
		Name = "TextOutline", Color = THEME.ink, ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual,
	}, text)
	local function update()
		outline.Enabled = enabled ~= false and (text.Font == THEME.bold or text.Font == THEME.display)
		outline.Thickness = thickness or (text.TextSize <= 16 and 1.5 or text.TextSize < 32 and 2 or 3)
		outline.Transparency = text.TextTransparency
	end
	text:GetPropertyChangedSignal("Font"):Connect(update)
	text:GetPropertyChangedSignal("TextSize"):Connect(update)
	text:GetPropertyChangedSignal("TextTransparency"):Connect(update)
	update()
	return outline
end

-- Feste Textfelder passen sich an; nachträgliche TextSize-Werte bleiben die Obergrenze.
function UIKit.fitText(text, minimum, wrap)
	text.TextScaled = true
	local function updateWrapping()
		if text.TextScaled and text.TextWrapped ~= (wrap == true) then
			text.TextWrapped = wrap == true
		end
	end
	-- TextScaled und spätere Zuweisungen dürfen Kurztexte nicht umbrechen.
	text:GetPropertyChangedSignal("TextScaled"):Connect(updateWrapping)
	text:GetPropertyChangedSignal("TextWrapped"):Connect(updateWrapping)
	updateWrapping()
	local constraint = text:FindFirstChildOfClass("UITextSizeConstraint") or make("UITextSizeConstraint", {}, text)
	local function update()
		constraint.MinTextSize = math.min(minimum or 12, text.TextSize)
		constraint.MaxTextSize = text.TextSize
	end
	text:GetPropertyChangedSignal("TextSize"):Connect(update)
	update()
	return text
end

function UIKit.label(props, parent)
	local wrap = props.wrap == true
	props.wrap = nil
	local outline = props.Outline
	props.Outline = nil
	local outlineThickness = props.OutlineThickness
	props.OutlineThickness = nil
	props.BackgroundTransparency = props.BackgroundTransparency or 1
	props.TextColor3 = props.TextColor3 or THEME.text
	props.Font = props.Font or THEME.body
	props.TextSize = props.TextSize or 16
	props.RichText = true
	local text = make("TextLabel", props, parent)
	UIKit.outline(text, outline, outlineThickness)
	if props.AutomaticSize == nil and props.TextScaled ~= false then UIKit.fitText(text, nil, wrap) end
	return text
end

function UIKit.setChromeTitleGold(text, gold)
	text:SetAttribute("Gold", gold == true)
	text.TextColor3 = THEME.text
	text.ChromeGradient.Color = gold and ColorSequence.new({
		ColorSequenceKeypoint.new(0, THEME.goldLight), ColorSequenceKeypoint.new(0.51, THEME.gold),
		ColorSequenceKeypoint.new(0.52, THEME.goldShade), ColorSequenceKeypoint.new(0.75, THEME.gold),
		ColorSequenceKeypoint.new(1, THEME.goldLight),
	}) or chromeSequence()
end

function UIKit.chromeTitle(props, parent)
	local gold = props.Gold
	props.Gold = nil
	props.Font = THEME.display
	props.TextColor3 = THEME.text
	props.OutlineThickness = 3
	props.TextStrokeTransparency = 1
	local text = UIKit.label(props, parent)
	make("UIGradient", { Name = "ChromeGradient", Rotation = 90 }, text)
	UIKit.setChromeTitleGold(text, gold)
	return text
end

function UIKit.tag(props, parent)
	props.Font = THEME.tech
	props.TextColor3 = THEME.holoCyan
	props.TextSize = props.TextSize or 14
	props.Text = string.upper(props.Text or "")
	return UIKit.label(props, parent)
end

-- Fließtext behält seine Schriftgröße und erweitert den Kasten nach unten.
function UIKit.flowLabel(props, parent)
	props.TextWrapped = true
	props.TextScaled = false
	props.AutomaticSize = Enum.AutomaticSize.Y
	props.TextYAlignment = Enum.TextYAlignment.Top
	return UIKit.label(props, parent)
end

function UIKit.textList(props, parent, gap)
	props.BackgroundTransparency = 1
	props.BorderSizePixel = 0
	props.ScrollBarThickness = 6
	props.ScrollingDirection = Enum.ScrollingDirection.Y
	props.AutomaticCanvasSize = Enum.AutomaticSize.Y
	props.CanvasSize = UDim2.new()
	local list = make("ScrollingFrame", props, parent)
	make("UIListLayout", { Padding = UDim.new(0, gap or 8), SortOrder = Enum.SortOrder.LayoutOrder }, list)
	return list
end

-- Dekoration bleibt am Hintergrund, damit padding nur den Inhalt verschiebt.
function UIKit.panel(props, parent)
	local animated = props.Animated
	props.Animated = nil
	local jewel = props.Jewel == true
	props.Jewel = nil
	local transparency = props.BackgroundTransparency or 0
	props.BackgroundTransparency = 1
	props.BorderSizePixel = 0
	local f = make(animated and "CanvasGroup" or "Frame", props, parent)
	UIKit.corner(f, METRICS.panelRadius)
	local chrome = UIKit.stroke(f, THEME.text, METRICS.panelBorder)
	make("UIGradient", { Color = chromeSequence(), Rotation = 90 }, chrome)
	local background = make("Frame", {
		Name = "Background", Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(1, 1, 1),
		BackgroundTransparency = transparency, BorderSizePixel = 0, ZIndex = f.ZIndex,
	}, f)
	UIKit.corner(background, METRICS.panelRadius)
	make("UIGradient", { Color = ColorSequence.new(THEME.top, THEME.bottom), Rotation = 90 }, background)
	local outer = make("Frame", {
		Name = "OuterBorder", Position = UDim2.fromOffset(-3, -3), Size = UDim2.new(1, 6, 1, 6),
		BackgroundTransparency = 1, BorderSizePixel = 0, ZIndex = f.ZIndex,
	}, background)
	UIKit.corner(outer, METRICS.panelRadius + METRICS.panelBorder)
	UIKit.stroke(outer, THEME.ink, METRICS.panelBorder)
	if not animated and (props.AutomaticSize == nil or props.AutomaticSize == Enum.AutomaticSize.None) then
		local shadow = make("Frame", {
			Name = "Shadow", Position = UDim2.fromOffset(0, METRICS.shadowOffset),
			Size = UDim2.fromScale(1, 1), BackgroundColor3 = THEME.ink,
			BackgroundTransparency = 0.55, BorderSizePixel = 0, ZIndex = f.ZIndex,
		}, background)
		UIKit.corner(shadow, METRICS.panelRadius)
		-- Gleicher ZIndex: zuerst zeichnen, dann Glas und Inhalt.
		shadow.Parent = nil
		background.Parent = nil
		shadow.Parent = f
		background.Parent = f
		local function alignShadow()
			local fixed = f.AutomaticSize == Enum.AutomaticSize.None
			shadow.Visible = fixed
			shadow.Position = fixed and background.Position + UDim2.fromOffset(0, METRICS.shadowOffset) or UDim2.new()
			shadow.Size = fixed and background.Size or UDim2.new()
		end
		background:GetPropertyChangedSignal("Position"):Connect(alignShadow)
		background:GetPropertyChangedSignal("Size"):Connect(alignShadow)
		f:GetPropertyChangedSignal("AutomaticSize"):Connect(alignShadow)
	end
	local reflection = make("Frame", {
		Name = "Glass", Size = UDim2.fromScale(1, 1), BackgroundColor3 = THEME.text,
		BorderSizePixel = 0, ZIndex = f.ZIndex,
	}, background)
	UIKit.corner(reflection, METRICS.panelRadius)
	make("UIGradient", {
		Rotation = 90, Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.86), NumberSequenceKeypoint.new(0.33, 1), NumberSequenceKeypoint.new(1, 1),
		}),
	}, reflection)
	make("Frame", {
		Name = "InnerLight", Position = UDim2.fromOffset(16, 3), Size = UDim2.new(1, -32, 0, 1),
		BackgroundColor3 = THEME.panelLine, BorderSizePixel = 0, ZIndex = f.ZIndex,
	}, background)
	if jewel then
		local gem = make("Frame", {
			Name = "CrownJewel", AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.new(0.5, 0, 0, animated and 10 or 0),
			Size = UDim2.fromOffset(animated and 14 or 16, animated and 14 or 16),
			Rotation = 45, BackgroundColor3 = THEME.text, BorderSizePixel = 0,
			ZIndex = f.ZIndex,
		}, background)
		UIKit.corner(gem, 3)
		UIKit.stroke(gem, THEME.ink, 3)
		local face = make("Frame", {
			Size = UDim2.fromScale(1, 1), BackgroundColor3 = THEME.text, BorderSizePixel = 0, ZIndex = gem.ZIndex,
		}, gem)
		UIKit.corner(face, 3)
		UIKit.stroke(face, THEME.chromeLight, 1)
		make("UIGradient", { Color = ColorSequence.new(THEME.gem, THEME.holoLilac), Rotation = 90 }, face)
		local gleam = make("Frame", {
			Position = UDim2.fromOffset(3, 3), Size = UDim2.fromOffset(5, 3),
			BackgroundColor3 = THEME.text, BorderSizePixel = 0, ZIndex = gem.ZIndex,
		}, face)
		UIKit.corner(gleam, 2)
	end
	-- AutomaticSize darf keine R?ckkopplung mit gepolsterter, ?berstehender Deko bilden.
	local automaticGradient = make("UIGradient", {
		Name = "AutomaticGradient", Color = ColorSequence.new(THEME.top, THEME.bottom), Rotation = 90,
	}, f)
	local function updateAutomaticSurface()
		local automatic = f.AutomaticSize ~= Enum.AutomaticSize.None
		background.Visible = not automatic
		f.BackgroundColor3 = THEME.text
		f.BackgroundTransparency = automatic and transparency or 1
		automaticGradient.Enabled = automatic
	end
	f:GetPropertyChangedSignal("AutomaticSize"):Connect(updateAutomaticSurface)
	updateAutomaticSurface()
	-- Eigene Deko teilt die Fensterebene; Inhalt bekommt stets eine Ebene dar?ber.
	local decorations = { [background] = true }
	for _, object in background:GetDescendants() do
		if object:IsA("GuiObject") then decorations[object] = true end
	end
	local shadow = f:FindFirstChild("Shadow")
	if shadow then decorations[shadow] = true end
	local contentConnections = {}
	local function raiseContent(object)
		local minimum = f.ZIndex + (object:IsA("TextButton") and object.Text ~= "" and 2 or 1)
		if object.ZIndex < minimum then object.ZIndex = minimum end
	end
	local function watchContent(object)
		if not object:IsA("GuiObject") or decorations[object] or contentConnections[object] then return end
		raiseContent(object)
		contentConnections[object] = object:GetPropertyChangedSignal("ZIndex"):Connect(function()
			raiseContent(object)
		end)
	end
	local function updateLayers()
		for object in decorations do object.ZIndex = f.ZIndex end
		for object in contentConnections do raiseContent(object) end
	end
	f.DescendantAdded:Connect(function(object)
		watchContent(object)
		for _, child in object:GetDescendants() do watchContent(child) end
	end)
	f.DescendantRemoving:Connect(function(object)
		local connection = contentConnections[object]
		if connection then connection:Disconnect(); contentConnections[object] = nil end
	end)
	f:GetPropertyChangedSignal("ZIndex"):Connect(updateLayers)
	f.Destroying:Connect(function()
		for _, connection in contentConnections do connection:Disconnect() end
	end)
	updateLayers()
	return f
end

local function gloss(parent, z)
	local cap = make("Frame", {
		Name = "Gloss", Position = UDim2.fromScale(0.05, 0.02), Size = UDim2.fromScale(0.9, 0.48),
		BackgroundColor3 = THEME.text, BorderSizePixel = 0, ZIndex = z or 0,
	}, parent)
	make("UICorner", { CornerRadius = UDim.new(1, 0) }, cap)
	make("UIGradient", { Rotation = 90, Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.55), NumberSequenceKeypoint.new(1, 1),
	}) }, cap)
	return cap
end

local buttonStates = setmetatable({}, { __mode = "k" })

local function updateButton(b)
	local state = buttonStates[b]
	if not state then return end
	local style = b:GetAttribute("Style")
	local colors = UIKit.BUTTON_STYLES[style]
	local disabled = style == "disabled"
	if disabled then state.pressed = false end
	local drop = state.pressed and METRICS.buttonEdge - METRICS.pressedEdge or 0
	-- padding verschiebt nur den Text; die Flächen kompensieren dieselben Abstände.
	state.padding.PaddingTop = UDim.new(0, drop * 2)
	state.face.Position = UDim2.fromOffset(-6, -drop)
	state.face.Size = UDim2.new(1, 12, 1, drop * 2)
	state.edge.Position = UDim2.fromOffset(-6, METRICS.buttonEdge - drop * 2)
	state.edge.Size = UDim2.new(1, 12, 1, drop * 2)
	state.edge.Visible = not disabled
	state.edge.BackgroundColor3 = colors[2]
	state.face.BackgroundColor3 = style == "holo" and THEME.text or colors[1]
	if state.hovered and not disabled and style ~= "holo" then
		state.face.BackgroundColor3 = colors[1]:Lerp(THEME.text, 0.08)
	end
	state.gradient.Enabled = style == "holo"
	state.gloss.Visible = not disabled
	for _, decoration in { state.edge, state.face, state.gloss } do decoration.ZIndex = math.max(0, b.ZIndex - 1) end
end

function UIKit.setButtonStyle(b, style)
	b:SetAttribute("Style", style)
	b.BackgroundColor3 = UIKit.BUTTON_STYLES[style][1]
	b.TextTransparency = style == "disabled" and 0.4 or 0
	updateButton(b)
end

function UIKit.button(text, parent, style, order, wrap)
	local b = make("TextButton", {
		Text = text, Size = UDim2.new(1, 0, 0, METRICS.buttonHeight), AutoButtonColor = false,
		TextColor3 = THEME.text, Font = THEME.bold, TextSize = 18,
		BorderSizePixel = 0, LayoutOrder = order or 0, RichText = true, BackgroundTransparency = 1,
	}, parent)
	UIKit.fitText(b, nil, wrap)
	local textPadding = make("UIPadding", { PaddingLeft = UDim.new(0, 6), PaddingRight = UDim.new(0, 6) }, b)
	UIKit.corner(b, METRICS.buttonRadius)
	UIKit.outline(b)
	local edge = make("Frame", { Name = "ButtonEdge", BorderSizePixel = 0, ZIndex = 0 }, b)
	UIKit.corner(edge, METRICS.buttonRadius)
	UIKit.stroke(edge, THEME.ink, 3)
	local face = make("Frame", { Name = "ButtonFace", BorderSizePixel = 0, ZIndex = 0 }, b)
	UIKit.corner(face, METRICS.buttonRadius)
	UIKit.stroke(face, THEME.ink, 3)
	local gradient = make("UIGradient", { Rotation = 15, Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, THEME.holoCyan), ColorSequenceKeypoint.new(0.33, THEME.holoLilac),
		ColorSequenceKeypoint.new(0.67, THEME.holoPink), ColorSequenceKeypoint.new(1, THEME.gold),
	}) }, face)
	local state = { edge = edge, face = face, gradient = gradient, gloss = gloss(face), padding = textPadding, pressed = false, hovered = false }
	buttonStates[b] = state
	b:GetPropertyChangedSignal("ZIndex"):Connect(function() updateButton(b) end)
	UIKit.setButtonStyle(b, style or "default")
	local scale = make("UIScale", { Name = "ButtonScale" }, b)
	local scaleTween
	local hovered = false
	local function hoverScale() return b:GetAttribute("HoverScale") or Config.FEEL.buttonHoverScale end
	local function animateScale(value, duration, easing)
		if scaleTween then scaleTween:Cancel() end
		scaleTween = TweenService:Create(scale, TweenInfo.new(duration, easing or Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Scale = value })
		scaleTween:Play()
	end
	b.InputBegan:Connect(function(input)
		if b:GetAttribute("Style") ~= "disabled" and (input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1) then
			state.pressed = true
			updateButton(b)
			animateScale(Config.FEEL.buttonPressScale, Config.FEEL.buttonPressTime)
		end
	end)
	b.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
			state.pressed = false
			updateButton(b)
			animateScale(hovered and hoverScale() or 1, Config.FEEL.buttonReleaseTime,
				hoverScale() <= 1 and Enum.EasingStyle.Quad or Enum.EasingStyle.Back)
		end
	end)
	b.Activated:Connect(function()
		if b:GetAttribute("Style") ~= "disabled" then SoundPlayer.play("click") end
	end)
	b.MouseEnter:Connect(function()
		if UserInputService.MouseEnabled and b:GetAttribute("Style") ~= "disabled" then
			hovered = true
			state.hovered = true
			updateButton(b)
			animateScale(hoverScale(), Config.FEEL.buttonReleaseTime)
		end
		local now = os.clock()
		if UserInputService.MouseEnabled and b:GetAttribute("Style") ~= "disabled" and now - lastHoverSound >= Config.FEEL.hoverSoundCooldown then
			lastHoverSound = now
			SoundPlayer.play("hover")
		end
	end)
	b.MouseLeave:Connect(function()
		hovered = false
		state.hovered = false
		updateButton(b)
		animateScale(1, Config.FEEL.buttonReleaseTime)
	end)
	return b
end

-- Balken mit optionaler Vorschau (z. B. KP nach dem Kampf)
function UIKit.bar(parent, position, size, color)
	local bg = make("Frame", {
		Position = position, Size = size, BackgroundColor3 = THEME.barBg, BorderSizePixel = 0,
	}, parent)
	make("UICorner", { CornerRadius = UDim.new(1, 0) }, bg)
	UIKit.stroke(bg, THEME.ink, 2)
	local loss = make("Frame", { Size = UDim2.fromScale(0, 1), BackgroundColor3 = THEME.bad, BorderSizePixel = 0 }, bg)
	make("UICorner", { CornerRadius = UDim.new(1, 0) }, loss)
	local fill = make("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = color, BorderSizePixel = 0 }, bg)
	make("UICorner", { CornerRadius = UDim.new(1, 0) }, fill)
	gloss(fill, fill.ZIndex)
	local text = UIKit.label({
		Size = UDim2.fromScale(1, 1), Font = THEME.bold, TextSize = 13, ZIndex = 3,
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
	return ("<font color='%s'>%s</font><font color='#%s'>%s</font>"):format(
		r.hex, string.rep("★", rarity), THEME.starEmpty:ToHex(), string.rep("★", 5 - rarity))
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
	local shadow = clone:FindFirstChild("UnitShadow")
	if shadow then shadow:Destroy() end
	for _, d in clone:GetDescendants() do
		if d:IsA("BillboardGui") or d:IsA("ParticleEmitter") then
			d:Destroy()
		end
	end
	-- Brett-Figuren sind vergrößert (Config.FEEL.boardUnitScale); Porträts zeigen Originalgröße.
	-- BaseScale = Maßstab der aufbereiteten Vorlage (Mesh-Figuren sind auf Zielhöhe normiert)
	local base = source:GetAttribute("BaseScale") or 1
	local scale = source:GetScale() / base
	clone:ScaleTo(base)
	clone:PivotTo(CFrame.new())
	local world = make("WorldModel", {}, viewport)
	clone.Parent = world
	local headY = (source:GetAttribute("HeadY") or 4.8) / scale
	if source:GetAttribute("MeshRig") then
		local topY = (source:GetAttribute("TopY") or headY * scale) / scale
		local ground = (source:GetAttribute("GroundOffset") or 0) / scale
		local height = math.max(topY - headY, 0.1) + math.max(headY + ground, 1) * (zoomOut and 0.6 or 0.4)
		local torso = clone:FindFirstChild("UpperTorso")
		local aspect = viewport.AbsoluteSize.X / math.max(viewport.AbsoluteSize.Y, 1)
		local width = torso and torso.Size.X * 1.3 or height
		local d = math.max(height, width / math.max(aspect, 0.5)) / (2 * math.tan(math.rad(camera.FieldOfView / 2))) * 1.15
		local targetY = topY - height / 2
		camera.CFrame = CFrame.lookAt(Vector3.new(d * 0.3, targetY + height * 0.12, -d), Vector3.new(0, targetY, 0))
		return
	end
	local d = zoomOut and 9 or 6
	camera.CFrame = CFrame.lookAt(Vector3.new(1.8, headY + 0.4, -d), Vector3.new(0, headY - (zoomOut and 1.6 or 0.8), 0))
end

-- Heldenporträts klonen die beim Serverstart erzeugten Figurenvorlagen.
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
	UIKit.corner(card, METRICS.buttonRadius)
	local z = (props.ZIndex or 1) + 1
	local outer = make("Frame", {
		Name = "CardBorder", Position = UDim2.fromOffset(-4, -4), Size = UDim2.new(1, 8, 1, 8),
		BackgroundTransparency = 1, BorderSizePixel = 0, ZIndex = card.ZIndex,
	}, card)
	UIKit.corner(outer, METRICS.buttonRadius + METRICS.cardBorder)
	UIKit.stroke(outer, THEME.ink, 3)
	local stroke = UIKit.stroke(card, rarity.color, METRICS.cardBorder)
	if def.rarity == 5 then
		stroke.Color = THEME.text
		local holo = make("UIGradient", { Rotation = 35, Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, rarity.color), ColorSequenceKeypoint.new(0.33, THEME.holoGold),
			ColorSequenceKeypoint.new(0.67, THEME.holoPink), ColorSequenceKeypoint.new(1, THEME.holoCyan),
		}) }, stroke)
		-- Direkte Rahmenfarben der Aufstellungswahl bleiben kompatibel.
		stroke:GetPropertyChangedSignal("Color"):Connect(function()
			if stroke.Color == rarity.color then stroke.Color = THEME.text end
			holo.Enabled = stroke.Color == THEME.text
		end)
		local halo = make("Frame", {
			Name = "HoloGlow", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1,
			BorderSizePixel = 0, ZIndex = card.ZIndex,
		}, outer)
		UIKit.corner(halo, METRICS.buttonRadius + METRICS.cardBorder)
		local glow = UIKit.stroke(halo, THEME.holoCyan, 8)
		glow.Transparency = 0.88
	end
	local signature = def.chibi and def.chibi.outfit and def.chibi.outfit.primary or rarity.color
	make("UIGradient", {
		Color = ColorSequence.new(signature, THEME.panelBottom), Rotation = 90,
	}, card)
	local vp, cam = UIKit.viewport(card, { Size = UDim2.new(1, 0, 1, -58), ZIndex = z })
	UIKit.heroPortrait(vp, cam, heroId, true)
	local name = UIKit.label({
		Position = UDim2.new(0, 0, 1, -58), Size = UDim2.new(1, 0, 0, 22), Font = THEME.title, TextSize = 20,
		TextColor3 = rarity.color, Text = def.name, ZIndex = z, OutlineThickness = 3,
	}, card)
	local sub = UIKit.label({
		Position = UDim2.new(0, 0, 1, -36), Size = UDim2.new(1, 0, 0, 16), TextSize = 12, TextColor3 = THEME.dim,
		Text = UnitData.Classes[def.class].name, ZIndex = z,
	}, card)
	local stars = UIKit.label({
		Position = UDim2.new(0, 0, 1, -20), Size = UDim2.new(1, 0, 0, 16), TextSize = 14, Font = THEME.bold,
		Text = UIKit.rarityStars(def.rarity), ZIndex = z,
	}, card)
	local badge = UIKit.label({
		Position = UDim2.fromOffset(6, 6), Size = UDim2.fromOffset(84, 20), Font = THEME.bold, TextSize = 12,
		BackgroundTransparency = 0, BackgroundColor3 = THEME.holoPink, Visible = false, ZIndex = z + 1,
	}, card)
	make("UICorner", { CornerRadius = UDim.new(1, 0) }, badge)
	UIKit.stroke(badge, THEME.ink, 2)
	return { card = card, stroke = stroke, badge = badge, name = name, sub = sub, stars = stars, rarity = rarity }
end

-- Ganze Oberfläche skaliert mit der Bildschirmgröße (Designgröße 1280×720)
function UIKit.createRoot(gui, maximumScale)
	local screenGui = gui:IsA("ScreenGui") and gui or gui:FindFirstAncestorOfClass("ScreenGui")
	-- Reihenfolge ist wichtig: IgnoreGuiInset kann ScreenInsets verändern.
	screenGui.IgnoreGuiInset = true
	screenGui.ScreenInsets = Enum.ScreenInsets.None
	screenGui.SafeAreaCompatibility = Enum.SafeAreaCompatibility.None
	screenGui.ClipToDeviceSafeArea = false
	local surface = make("Frame", { Name = "SafeArea", BackgroundTransparency = 1, Active = false }, gui)
	local root = make("Frame", { Name = "Root", BackgroundTransparency = 1, Active = false }, surface)
	local scale = make("UIScale", {}, root)
	local connections = {}
	local viewportConnection
	local destroyed, pendingDiagnostics = false, false
	local lastDiagnostics
	local diagnosticNames = { PhasenBanner = true, HinweisKasten = true, GelaendeKasten = true }
	local function diagnose()
		if not Config.INPUT_DIAGNOSTICS or pendingDiagnostics or destroyed then return end
		pendingDiagnostics = true
		-- AbsolutePosition/Size erst nach den gemeinsamen Layout-Zuweisungen lesen.
		task.defer(function()
			pendingDiagnostics = false
			if destroyed then return end
			local camera = workspace.CurrentCamera
			local insetTop, insetBottom = GuiService:GetGuiInset()
			local parts = {
				("[UI-Diagnose] %s Viewport=%s TopbarInset=%s GuiInset=%s/%s InsetArea(None)=%s InsetArea(Device)=%s UIScale=%.4f"):format(
					screenGui.Name, tostring(camera and camera.ViewportSize), tostring(GuiService.TopbarInset),
					tostring(insetTop), tostring(insetBottom), tostring(GuiService:GetInsetArea(Enum.ScreenInsets.None)),
					tostring(GuiService:GetInsetArea(Enum.ScreenInsets.DeviceSafeInsets)), scale.Scale),
			}
			local function addBounds(object)
				table.insert(parts, ("%s Position=%s Size=%s"):format(object.Name, tostring(object.AbsolutePosition), tostring(object.AbsoluteSize)))
			end
			addBounds(surface)
			addBounds(root)
			for _, name in { "PhasenBanner", "HinweisKasten", "GelaendeKasten" } do
				local object = root:FindFirstChild(name, true)
				if object then addBounds(object) end
			end
			local message = table.concat(parts, " | ")
			if message ~= lastDiagnostics then
				lastDiagnostics = message
				print(message)
			end
		end)
	end
	local function update()
		-- InsetArea-Rechtecke sind relativ zur Core-UI, nicht zu Bildschirmpixel 0.
		local full = GuiService:GetInsetArea(Enum.ScreenInsets.None)
		local device = GuiService:GetInsetArea(Enum.ScreenInsets.DeviceSafeInsets)
		local insetTop = GuiService:GetGuiInset()
		local top = GuiService.TopbarInset.Max.Y
		if top <= 0 then top = insetTop.Y end
		local left = math.max(0, device.Min.X - full.Min.X)
		top = math.max(0, top, device.Min.Y - full.Min.Y)
		local right = math.max(0, full.Max.X - device.Max.X)
		local bottom = math.max(0, full.Max.Y - device.Max.Y)
		local available = Vector2.new(full.Width - left - right, full.Height - top - bottom)
		if available.X <= 0 or available.Y <= 0 then return end
		surface.Position = UDim2.fromOffset(left, top)
		surface.Size = UDim2.fromOffset(available.X, available.Y)
		-- Unter 360 sicheren Punkten Höhe darf die Oberfläche kleiner als 0,5 werden.
		local cap = maximumScale or 1.15
		local s = math.min(available.X / 1280, available.Y / 720, cap)
		if UserInputService.MouseEnabled and not UserInputService.TouchEnabled then
			local settings = Config.UI_SCALE
			s = math.min(s * settings.desktopFactor, available.X / settings.desktopMinWidth,
				available.Y / settings.desktopMinHeight, cap * settings.desktopFactor)
		end
		scale.Scale = s
		root.Size = UDim2.fromOffset(available.X / s, available.Y / s)
		diagnose()
	end
	local function bindCamera()
		if viewportConnection then viewportConnection:Disconnect() end
		local camera = workspace.CurrentCamera
		viewportConnection = camera and camera:GetPropertyChangedSignal("ViewportSize"):Connect(update)
		update()
	end
	table.insert(connections, gui:GetPropertyChangedSignal("AbsoluteSize"):Connect(update))
	table.insert(connections, GuiService:GetPropertyChangedSignal("TopbarInset"):Connect(update))
	table.insert(connections, workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(bindCamera))
	if Config.INPUT_DIAGNOSTICS then
		local function watchBounds(object)
			table.insert(connections, object:GetPropertyChangedSignal("AbsolutePosition"):Connect(diagnose))
			table.insert(connections, object:GetPropertyChangedSignal("AbsoluteSize"):Connect(diagnose))
			diagnose()
		end
		watchBounds(surface)
		watchBounds(root)
		table.insert(connections, scale:GetPropertyChangedSignal("Scale"):Connect(diagnose))
		table.insert(connections, root.DescendantAdded:Connect(function(object)
			if diagnosticNames[object.Name] then watchBounds(object) end
		end))
	end
	surface.Destroying:Connect(function()
		destroyed = true
		if viewportConnection then viewportConnection:Disconnect() end
		for _, connection in connections do connection:Disconnect() end
	end)
	bindCamera()
	return root
end

return UIKit
