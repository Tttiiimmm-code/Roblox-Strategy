-- Eingabefilter und Markierung für die vom Server vorgegebenen Tutorial-Schritte.
local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Tutorial = require(Shared.Tutorial)
local Config = require(Shared.Config)
local Grid = require(Shared.Grid)
local TweenService = game:GetService("TweenService")
local TutorialGuide = {}
local state, ui, send, fxFolder
local pending = false
local marker, pulse, markerKey

local function clearMarker()
	if pulse then pulse:Cancel(); pulse = nil end
	if marker then marker:Destroy(); marker = nil end
	markerKey = nil
end

function TutorialGuide.init(hud, sendCommand, folder)
	ui, send, fxFolder = hud, sendCommand, folder
end

function TutorialGuide.update(newState)
	state, pending = newState, false
end

function TutorialGuide.active()
	return state ~= nil and state.tutorial ~= nil and not state.result
end

function TutorialGuide.guided()
	local step = TutorialGuide.active() and Tutorial.step(state.tutorial)
	return step and step.kind ~= "Free" or false
end

-- Lokale Schritte werden erst nach dem nächsten Snapshot freigegeben.
function TutorialGuide.allow(action, data)
	if not TutorialGuide.active() then return true end
	if pending or state.busy or state.phase ~= "Player" then return false end
	local step = Tutorial.step(state.tutorial)
	if step.kind == "Free" then return true end
	data = data or {}
	if step.kind ~= action then ui.toast("Folge bitte der goldenen Markierung."); return false end
	local hero = Tutorial.hero(state, step.hero)
	if not hero or hero.id ~= data.unitId then ui.toast("Tippe auf die markierte Figur."); return false end
	if step.position then
		local pos = Tutorial.position(state, step)
		if pos.x ~= data.x or pos.y ~= data.y then ui.toast("Tippe auf das goldene Feld."); return false end
	end
	if step.target then
		local target = Tutorial.target(state, step.target)
		if not target or target.id ~= data.targetId then ui.toast("Tippe auf den markierten Gegner."); return false end
	end
	return true
end

function TutorialGuide.checkpoint(action, data)
	if not TutorialGuide.guided() then return end
	pending = true
	local cmd = table.clone(data or {})
	cmd.type, cmd.action = "TutorialStep", action
	cmd.tutorialId, cmd.step = state.tutorial.id, state.tutorial.step
	send(cmd)
end

function TutorialGuide.render()
	if not ui then return end
	if not TutorialGuide.active() then ui.setTutorialMark(nil); clearMarker(); return end
	local step = Tutorial.step(state.tutorial)
	ui.setTutorialMark(step.mark)
	ui.setHint(("<b>Tutorial %d</b> · %s"):format(state.tutorial.mission, step.text))
	local unit, pos
	if step.mark == "hero" then unit = Tutorial.hero(state, step.hero) end
	if step.mark == "target" then unit = Tutorial.target(state, step.target) end
	if step.mark == "tile" then pos = Tutorial.position(state, step) end
	if unit then pos = { x = unit.x, y = unit.y } end
	if not pos then clearMarker(); return end
	local key = state.tutorial.id .. ":" .. state.tutorial.step
	if key == markerKey and marker then return end
	clearMarker()
	markerKey = key
	marker = Instance.new("Part")
	marker.Name = "TutorialZiel"
	marker.Size = Vector3.new(Config.TILE_SIZE * 0.9, 0.14, Config.TILE_SIZE * 0.9)
	marker.Position = Grid.toWorld(pos.x, pos.y) + Vector3.new(0, 0.12, 0)
	marker.Anchored, marker.CanCollide, marker.CanTouch, marker.CanQuery = true, false, false, false
	marker.Transparency = 1
	marker.Parent = fxFolder
	local outline = Instance.new("SelectionBox")
	outline.Adornee, outline.Color3, outline.LineThickness = marker, Config.OVERLAY.Cursor, 0.1
	outline.SurfaceTransparency = 1
	outline.Parent = marker
	pulse = TweenService:Create(outline, TweenInfo.new(0.7, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), { Transparency = 0.65 })
	pulse:Play()
	if unit then
		local model = workspace:FindFirstChild("Units")
		model = model and model:FindFirstChild(unit.id)
		if model then
			local highlight = Instance.new("Highlight")
			highlight.Adornee, highlight.FillTransparency = model, 0.8
			highlight.FillColor, highlight.OutlineColor = Config.OVERLAY.Cursor, Config.OVERLAY.Cursor
			highlight.Parent = marker
		end
	end
end

return TutorialGuide
