-- Taktik-Kamera: WASD/Ziehen verschieben, Q/E/Zwei-Finger drehen, Mausrad/Pinch zoomen
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local Players = game:GetService("Players")
local GuiService = game:GetService("GuiService")

local Config = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("Config"))
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

local function setAvatarControls()
	local controlsOk, controlsError = pcall(function()
		local playerModule = Players.LocalPlayer.PlayerScripts:WaitForChild("PlayerModule", 5)
		if not playerModule then error("PlayerModule fehlt") end
		local controls = require(playerModule):GetControls()
		if active then controls:Disable() else controls:Enable() end
	end)
	local touchOk, touchError = pcall(function()
		-- Ein früherer wartender PlayerModule-Aufruf darf keinen neueren Kamerawechsel überschreiben.
		GuiService.TouchControlsEnabled = not active
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

local function maximumZoom()
	local camera, c = workspace.CurrentCamera, Config.CAMERA
	local viewport = camera.ViewportSize
	local aspect = viewport.Y > 0 and viewport.X / viewport.Y or c.aspectMin
	return Config.overviewZoom(bounds, camera.FieldOfView, aspect)
end

local function defaultZoom()
	return math.clamp(math.max(bounds.X, bounds.Z) * Config.CAMERA.zoomDefaultScale, Config.CAMERA.zoomDefaultMin,
		math.min(Config.CAMERA.zoomDefaultMax, maximumZoom()))
end

local function clampFocus()
	local inset = 0
	if Config.ISLAND.enabled then
		-- Erst beim Herauszoomen wird der Fokus Richtung Brettmitte begrenzt.
		local normal = defaultZoom()
		inset = Config.ISLAND.panInset * math.clamp((zoom - normal) / math.max(0.001, maximumZoom() - normal), 0, 1)
	end
	focus = Vector3.new(math.clamp(focus.X, bounds.X * inset, bounds.X * (1 - inset)), focus.Y,
		math.clamp(focus.Z, bounds.Z * inset, bounds.Z * (1 - inset)))
end

function CameraController.setBounds(center, size, startFocus)
	saved, transition = nil, nil
	shakeStrength = 0
	focus = startFocus or center
	bounds = size
	zoom = defaultZoom()
	clampFocus()
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
		zoom = math.clamp(zoom / factor, Config.CAMERA.zoomMin, maximumZoom())
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
	-- TouchGui sofort sperren, auch wenn PlayerModule erst später verfügbar wird.
	pcall(function() GuiService.TouchControlsEnabled = not on end)
	-- Im Hintergrund: das Warten auf PlayerModule darf applyState nicht blockieren
	task.spawn(setAvatarControls)
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
			zoom = math.clamp(zoom - input.Position.Z * 6, Config.CAMERA.zoomMin, maximumZoom())
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

		-- Auch nach Fensterwechseln und Kamerafahrten gilt derselbe sichtbare Ausschnitt.
		camera.FieldOfView = math.clamp(camera.FieldOfView, Config.CAMERA.fovMin, Config.CAMERA.fovMax)
		zoom = math.clamp(zoom, Config.CAMERA.zoomMin, maximumZoom())
		local offset = rotation:VectorToWorldSpace(Vector3.new(0, 1, Config.CAMERA.tilt).Unit * zoom)
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
