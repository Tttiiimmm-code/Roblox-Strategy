-- Taktik-Kamera: WASD/Ziehen verschieben, Q/E/Zwei-Finger drehen, Mausrad/Pinch zoomen
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local Players = game:GetService("Players")
local GuiService = game:GetService("GuiService")

local CameraController = {}

local active = false -- true = Taktik-Kamera (eigener Kampf), false = normale Avatar-Kamera im Thronsaal
local focus = Vector3.zero
local bounds = Vector3.new(100, 0, 100)
local zoom = 75
local yaw = 0
local saved, transition
local shakeTime, shakeDuration, shakeStrength = 0, 0, 0
local random = Random.new()
local controlsWarningShown = false

local function setAvatarControls(on)
	local controlsOk, controlsError = pcall(function()
		local playerModule = Players.LocalPlayer.PlayerScripts:WaitForChild("PlayerModule", 5)
		if not playerModule then error("PlayerModule fehlt") end
		local controls = require(playerModule):GetControls()
		if on then controls:Enable() else controls:Disable() end
	end)
	local touchOk, touchError = pcall(function()
		GuiService.TouchControlsEnabled = on
	end)
	if (not controlsOk or not touchOk) and not controlsWarningShown then
		controlsWarningShown = true
		warn("Avatar-Steuerung konnte nicht umgeschaltet werden: " .. tostring(controlsError or touchError))
	end
end

local function transitionTo(position, distance, duration)
	transition = { from = focus, to = position, zoomFrom = zoom, zoomTo = distance, elapsed = 0, duration = math.max(duration, 0.001) }
end

function CameraController.focusOn(position, distance, duration)
	if not active then return end
	if not saved then saved = { focus = focus, zoom = zoom } end
	transitionTo(position, distance, duration)
end

function CameraController.restore(duration)
	if not active or not saved then return end
	transitionTo(saved.focus, saved.zoom, duration)
	saved = nil
end

function CameraController.shake(strength, duration)
	if not active then return end
	shakeStrength, shakeDuration, shakeTime = strength, math.max(duration, 0.001), 0
end

local function clampFocus()
	focus = Vector3.new(math.clamp(focus.X, 0, bounds.X), focus.Y, math.clamp(focus.Z, 0, bounds.Z))
end

function CameraController.setBounds(center, size)
	saved, transition = nil, nil
	shakeStrength = 0
	focus = center
	bounds = size
	zoom = math.clamp(math.max(size.X, size.Z) * 0.85, 45, 120)
end

-- Bildschirm-Verschiebung in Pixeln ("Karte greifen")
function CameraController.panBy(delta)
	local rotation = CFrame.Angles(0, yaw, 0)
	local k = zoom / 520
	focus += rotation:VectorToWorldSpace(Vector3.new(-delta.X, 0, -delta.Y)) * k
	clampFocus()
end

function CameraController.zoomBy(factor)
	if factor > 0 then
		zoom = math.clamp(zoom / factor, 30, 140)
	end
end

function CameraController.rotateBy(radians)
	yaw += radians
end

function CameraController.isActive()
	return active
end

function CameraController.setActive(on)
	if on == active then
		return
	end
	active = on
	setAvatarControls(not on)
	if not on then saved, transition = nil, nil; shakeStrength = 0 end
	if not on then
		local camera = workspace.CurrentCamera
		camera.CameraType = Enum.CameraType.Custom
		local character = Players.LocalPlayer.Character
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		if humanoid then
			camera.CameraSubject = humanoid
		end
	end
end

function CameraController.start()
	local camera = workspace.CurrentCamera

	UserInputService.InputChanged:Connect(function(input, processed)
		if active and not processed and input.UserInputType == Enum.UserInputType.MouseWheel then
			zoom = math.clamp(zoom - input.Position.Z * 6, 30, 140)
		end
	end)

	RunService.RenderStepped:Connect(function(dt)
		if not active then
			return
		end
		if camera.CameraType ~= Enum.CameraType.Scriptable then
			camera.CameraType = Enum.CameraType.Scriptable
		end

		local move = Vector3.zero
		if not UserInputService:GetFocusedTextBox() then
			if UserInputService:IsKeyDown(Enum.KeyCode.W) then move += Vector3.new(0, 0, -1) end
			if UserInputService:IsKeyDown(Enum.KeyCode.S) then move += Vector3.new(0, 0, 1) end
			if UserInputService:IsKeyDown(Enum.KeyCode.A) then move += Vector3.new(-1, 0, 0) end
			if UserInputService:IsKeyDown(Enum.KeyCode.D) then move += Vector3.new(1, 0, 0) end
			if UserInputService:IsKeyDown(Enum.KeyCode.Q) then yaw += dt * 1.5 end
			if UserInputService:IsKeyDown(Enum.KeyCode.E) then yaw -= dt * 1.5 end
		end

		if transition then
			transition.elapsed += dt
			local alpha = math.clamp(transition.elapsed / transition.duration, 0, 1)
			local eased = (1 - math.cos(alpha * math.pi)) / 2
			focus = transition.from:Lerp(transition.to, eased)
			zoom = transition.zoomFrom + (transition.zoomTo - transition.zoomFrom) * eased
			if alpha == 1 then transition = nil end
		end
		local rotation = CFrame.Angles(0, yaw, 0)
		focus += rotation:VectorToWorldSpace(move) * dt * 45
		clampFocus()

		local offset = rotation:VectorToWorldSpace(Vector3.new(0, 1, 0.75).Unit * zoom)
		local shakeOffset = Vector3.zero
		if shakeStrength > 0 then
			shakeTime += dt
			local decay = math.max(0, 1 - shakeTime / shakeDuration)
			shakeOffset = Vector3.new(random:NextNumber(-1, 1), random:NextNumber(-1, 1), 0) * shakeStrength * decay
			if decay == 0 then shakeStrength = 0 end
		end
		camera.CFrame = CFrame.lookAt(focus + offset, focus) * CFrame.new(shakeOffset)
	end)
end

return CameraController
