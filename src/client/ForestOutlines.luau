-- Wald-Umrisse teilen das Highlight-Budget mit Tutorial und Kampfeffekten.
local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Config = require(Shared.Config)
local Grid = require(Shared.Grid)
local ForestOutlines = {}
local outlines, foreign = {}, {}
local initialized = false

local function track(object)
	if object:IsA("Highlight") and not object:GetAttribute("ForestOutline") then foreign[object] = true end
end

function ForestOutlines.init()
	if initialized then return end
	initialized = true
	for _, object in workspace:GetDescendants() do track(object) end
	workspace.DescendantAdded:Connect(track)
	workspace.DescendantRemoving:Connect(function(object) foreign[object] = nil end)
end

function ForestOutlines.remove(model)
	local outline = outlines[model]
	if outline then outline:Destroy(); outlines[model] = nil end
end

local function covered(model, look)
	local p = model.PrimaryPart.Position
	local x, y = math.floor(p.X / Config.TILE_SIZE) + 1, math.floor(p.Z / Config.TILE_SIZE) + 1
	if not Grid.inBounds(x, y) then return false end
	if Grid.getMap()[y]:sub(x, x) == "F" then return true end
	-- Das kameranähere Nachbarfeld liegt entgegen der dominanten Blickachse.
	if math.abs(look.X) > math.abs(look.Z) then x -= look.X > 0 and 1 or -1
	else y -= look.Z > 0 and 1 or -1 end
	return Grid.inBounds(x, y) and Grid.getMap()[y]:sub(x, x) == "F"
end

function ForestOutlines.update(models, look, dying, enabled)
	ForestOutlines.init()
	local settings = Config.FOREST_OUTLINES
	local candidates, keep = {}, {}
	if enabled then
		for _, model in models do
			if model.Parent and model.PrimaryPart and model:GetAttribute("UnitId") and not (dying and dying[model])
				and (model:GetAttribute("Hp") or 1) > 0 and covered(model, look) then table.insert(candidates, model) end
		end
	end
	table.sort(candidates, function(a, b)
		local ap, bp = a:GetAttribute("Team") == "Player", b:GetAttribute("Team") == "Player"
		if ap ~= bp then return ap end
		return tostring(a:GetAttribute("UnitId")) < tostring(b:GetAttribute("UnitId"))
	end)
	local count = 0
	for object in foreign do if object.Parent then count += 1 else foreign[object] = nil end end
	local budget = math.max(0, math.min(settings.maxCount, settings.totalBudget - math.max(settings.reserved, count)))
	for i = 1, math.min(budget, #candidates) do keep[candidates[i]] = true end
	-- Freigeben, bevor neue Umrisse entstehen: auch beim Teamwechsel kein Spitzenüberlauf.
	for model in outlines do if not keep[model] then ForestOutlines.remove(model) end end
	for model in keep do
		local outline = outlines[model]
		if not outline then
			outline = Instance.new("Highlight")
			outline.Name = "ForestOutline"
			outline:SetAttribute("ForestOutline", true)
			outline.Adornee = model
			outline.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
			outline.FillTransparency = settings.fillTransparency
			outline.OutlineTransparency = settings.outlineTransparency
			outline.Parent = model
			outlines[model] = outline
		end
		outline.OutlineColor = settings.colors[model:GetAttribute("Team")] or settings.colors.Enemy
	end
end

return ForestOutlines
