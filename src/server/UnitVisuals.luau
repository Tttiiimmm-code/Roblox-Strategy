-- 3D-Darstellung der Einheiten: Figuren platzieren, bewegen, drehen, KP-Anzeige, Tod
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)
local Grid = require(Shared.Grid)

local CharacterBuilder = require(Shared.CharacterBuilder)

local UnitData = require(Shared.UnitData)

local UnitVisuals = {}

local folder
local speed = 1

function UnitVisuals.setSpeed(s)
	speed = s
end

local function rootCFrame(x, y, yaw)
	return CFrame.new(Grid.toWorld(x, y) + Vector3.new(0, 0.1, 0)) * CFrame.Angles(0, yaw, 0)
end

-- Blickrichtung (-Z) von a nach b
local function yawBetween(a, b)
	local d = b - a
	if Vector3.new(d.X, 0, d.Z).Magnitude < 0.01 then
		return nil
	end
	return math.atan2(-d.X, -d.Z)
end

local function tweenAndWait(inst, time, goal, style)
	local tween = TweenService:Create(inst, TweenInfo.new(time, style or Enum.EasingStyle.Quad), goal)
	tween:Play()
	tween.Completed:Wait()
end

local function getModel(id)
	local model = folder:FindFirstChild(id)
	return model, model and model.PrimaryPart
end

function UnitVisuals.init(unitsFolder)
	folder = unitsFolder
end

function UnitVisuals.create(unit)
	local model = CharacterBuilder.build(unit)
	model:SetAttribute("UnitId", unit.id)
	model:PivotTo(rootCFrame(unit.x, unit.y, unit.team == "Player" and 0 or math.pi))
	local root = model.PrimaryPart

	local bb = Instance.new("BillboardGui")
	bb.Name = "Info"
	bb.Size = UDim2.fromOffset(96, 30)
	bb.StudsOffsetWorldSpace = Vector3.new(0, model:GetAttribute("TopY") + 1.2, 0)
	bb.AlwaysOnTop = true
	bb.MaxDistance = 300

	local name = Instance.new("TextLabel")
	name.Name = "NameLabel"
	name.Size = UDim2.new(1, 0, 0.5, 0)
	name.BackgroundTransparency = 1
	name.Font = Enum.Font.GothamBold
	name.TextScaled = true
	name.TextColor3 = unit.team == "Player" and UnitData.Rarities[unit.rarity or 1].color or Color3.fromRGB(255, 150, 150)
	name.TextStrokeTransparency = 0.2
	name.Text = unit.name
	name.Parent = bb

	local bar = Instance.new("Frame")
	bar.Name = "Bar"
	bar.Position = UDim2.new(0.1, 0, 0.58, 0)
	bar.Size = UDim2.new(0.8, 0, 0.38, 0)
	bar.BackgroundColor3 = Color3.fromRGB(16, 18, 30)
	bar.BorderSizePixel = 0
	bar.Parent = bb
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 3)
	corner.Parent = bar
	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(228, 192, 108)
	stroke.Thickness = 1
	stroke.Parent = bar

	local fill = Instance.new("Frame")
	fill.Name = "Fill"
	fill.Size = UDim2.fromScale(1, 1)
	fill.BorderSizePixel = 0
	fill.Parent = bar
	local fillCorner = corner:Clone()
	fillCorner.Parent = fill

	local hpText = Instance.new("TextLabel")
	hpText.Name = "HpLabel"
	hpText.Size = UDim2.fromScale(1, 1)
	hpText.BackgroundTransparency = 1
	hpText.Font = Enum.Font.GothamBold
	hpText.TextScaled = true
	hpText.TextColor3 = Color3.new(1, 1, 1)
	hpText.TextStrokeTransparency = 0.4
	hpText.ZIndex = 2
	hpText.Parent = bar

	bb.Parent = root
	model.Parent = folder
	UnitVisuals.update(unit)
end

function UnitVisuals.setHp(id, hp, maxHp)
	local _, root = getModel(id)
	if not root then
		return
	end
	local ratio = math.clamp(hp / maxHp, 0, 1)
	local fill = root.Info.Bar.Fill
	TweenService:Create(fill, TweenInfo.new(0.25), { Size = UDim2.fromScale(ratio, 1) }):Play()
	if ratio > 0.5 then
		fill.BackgroundColor3 = Color3.fromRGB(90, 210, 110)
	elseif ratio > 0.25 then
		fill.BackgroundColor3 = Color3.fromRGB(235, 190, 60)
	else
		fill.BackgroundColor3 = Color3.fromRGB(225, 65, 65)
	end
	root.Info.Bar.HpLabel.Text = ("%d/%d"):format(hp, maxHp)
end

function UnitVisuals.update(unit)
	local model = getModel(unit.id)
	if not model then
		return
	end
	local grey = unit.done or unit.deployed == false
	local color = grey and Config.DONE_COLOR or Config.TEAM_COLORS[unit.team]
	for _, p in model:GetDescendants() do
		if p:IsA("BasePart") and p:GetAttribute("Tint") then
			p.Color = color
		end
	end
	UnitVisuals.setHp(unit.id, unit.hp, unit.maxHp)
end

-- Läuft den Pfad Feld für Feld ab und schaut dabei in Laufrichtung (blockiert bis zum Ende)
function UnitVisuals.moveAlong(unit, path)
	local model, root = getModel(unit.id)
	if not model or #path < 2 then
		return
	end
	model:SetAttribute("Moving", true)
	for i = 2, #path do
		local from, to = path[i - 1], path[i]
		local yaw = yawBetween(Grid.toWorld(from.x, from.y), Grid.toWorld(to.x, to.y)) or 0
		tweenAndWait(root, Config.MOVE_STEP_TIME / speed, { CFrame = rootCFrame(to.x, to.y, yaw) }, Enum.EasingStyle.Linear)
	end
	model:SetAttribute("Moving", false)
end

-- Dreht die Figur zum Feld (x, y)
function UnitVisuals.face(id, x, y)
	local _, root = getModel(id)
	if not root then
		return
	end
	local yaw = yawBetween(root.Position, Grid.toWorld(x, y))
	if yaw then
		local goal = CFrame.new(root.Position) * CFrame.Angles(0, yaw, 0)
		TweenService:Create(root, TweenInfo.new(0.15), { CFrame = goal }):Play()
	end
end

-- Umfallen und ausblenden
function UnitVisuals.remove(id, immediate)
	local model, root = getModel(id)
	if not model then
		return
	end
	if immediate then
		model:Destroy()
		return
	end
	model.Name = id .. "_gefallen" -- ID sofort frei, falls die Einheit per Rückblende zurückkehrt
	root.Info.Enabled = false
	local info = TweenInfo.new(0.7, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
	TweenService:Create(root, info, { CFrame = root.CFrame * CFrame.Angles(math.rad(85), 0, 0) }):Play()
	for _, d in model:GetDescendants() do
		if (d:IsA("BasePart") or d:IsA("Decal")) and d.Transparency < 1 then
			TweenService:Create(d, info, { Transparency = 1 }):Play()
		end
	end
	task.delay(0.8, function()
		model:Destroy()
	end)
end

return UnitVisuals
