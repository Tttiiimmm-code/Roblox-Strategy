-- Thronsaal auf dem Client: Einrichtungen (ProximityPrompts), Thron-Schnellmenü, Deko-Animation,
-- Avatar-Steuerung im Kampf sperren. GRUNDGERÜST – frei erweiterbar.
local Players = game:GetService("Players")
local ProximityPromptService = game:GetService("ProximityPromptService")
local RunService = game:GetService("RunService")

local Hub = {}

local player = Players.LocalPlayer
local callbacks
local controls = nil
local inBattleView = false

local function getControls()
	if not controls then
		local ok, module = pcall(function()
			return require(player:WaitForChild("PlayerScripts"):WaitForChild("PlayerModule"))
		end)
		if ok and module then
			controls = module:GetControls()
		end
	end
	return controls
end

local function humanoid()
	local character = player.Character
	return character and character:FindFirstChildOfClass("Humanoid")
end

-- Im eigenen Kampf: Avatar bleibt stehen, Prompts aus; sonst normal laufen
function Hub.setBattleView(on)
	if on == inBattleView then
		return
	end
	inBattleView = on
	local c = getControls()
	if c then
		if on then
			c:Disable()
		else
			c:Enable()
		end
	end
	ProximityPromptService.Enabled = not on
	local hum = humanoid()
	if on and hum and hum.Sit then
		hum.Sit = false
	end
end

-- Vom Thron aufstehen
function Hub.standUp()
	local hum = humanoid()
	if hum then
		hum.Sit = false
		hum.Jump = true
	end
end

local function watchCharacter(character)
	local hum = character:WaitForChild("Humanoid")
	hum.Seated:Connect(function(active, seat)
		callbacks.onThrone(active and seat ~= nil and seat.Name == "Throne")
	end)
end

-- Langsam drehende Deko (Attribut "Spin" in Grad/s; Modelle drehen um "SpinCenter")
local spinners = {}
local function collectSpinners()
	table.clear(spinners)
	local hubModel = workspace:FindFirstChild("Hub")
	if not hubModel then
		return
	end
	for _, d in hubModel:GetDescendants() do
		if d:GetAttribute("Spin") then
			table.insert(spinners, d)
		end
	end
end

local function spin(dt)
	for _, obj in spinners do
		if obj.Parent then
			local angle = math.rad(obj:GetAttribute("Spin") * dt)
			if obj:IsA("Model") then
				local center = obj:GetAttribute("SpinCenter")
				local pivot = CFrame.new(center)
				obj:PivotTo(pivot * CFrame.Angles(0, angle, 0) * pivot:Inverse() * obj:GetPivot())
			elseif obj:IsA("BasePart") then
				obj.CFrame = obj.CFrame * CFrame.Angles(angle, 0, 0) -- Zylinderachse = X
			end
		end
	end
end

function Hub.init(cbs)
	callbacks = cbs
	ProximityPromptService.PromptTriggered:Connect(function(prompt, who)
		if who == player and not inBattleView then
			local station = prompt:GetAttribute("Station")
			if station then
				callbacks.onStation(station)
			end
		end
	end)
	if player.Character then
		task.spawn(watchCharacter, player.Character)
	end
	player.CharacterAdded:Connect(watchCharacter)

	task.spawn(function()
		workspace:WaitForChild("Hub", 30)
		collectSpinners()
	end)
	RunService.RenderStepped:Connect(spin)
end

return Hub
