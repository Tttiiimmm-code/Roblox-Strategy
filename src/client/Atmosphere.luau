-- Lokal erzeugte Effekte; Presets und Übergangsdauer stehen zentral in Config.FEEL.
local Lighting = game:GetService("Lighting")
local TweenService = game:GetService("TweenService")
local Config = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("Config"))
local Atmosphere = {}
local effects, tweens = {}, {}
local preset
local classes = { bloom = "BloomEffect", color = "ColorCorrectionEffect", rays = "SunRaysEffect", haze = "Atmosphere", depth = "DepthOfFieldEffect" }

function Atmosphere.set(name)
	if preset == name then return end
	preset = name
	for _, tween in tweens do tween:Cancel() end
	table.clear(tweens)
	for key, class in classes do
		local goal = Config.FEEL.atmosphere[name][key]
		if key == "haze" and name == "battle" and Config.ISLAND.enabled then
			goal = table.clone(goal)
			goal.Color, goal.Decay = Config.ISLAND.skyColor, Config.ISLAND.horizonColor
		end
		-- Neue Effekte und Unschärfe sofort setzen: Standardwerte (z. B. 75 % Tiefenunschärfe)
		-- bzw. ein Überblenden der Unschärfe ließen Text und Szene kurz verschwommen wirken.
		if not effects[key] or key == "depth" then
			local effect = effects[key] or Instance.new(class)
			for prop, value in goal do effect[prop] = value end
			effect.Name = "GameFeel_" .. key
			effect.Parent = Lighting
			effects[key] = effect
		else
			local tween = TweenService:Create(effects[key], TweenInfo.new(Config.FEEL.atmosphereFade), goal)
			table.insert(tweens, tween)
			tween:Play()
		end
	end
	-- Helligkeit/Belichtung je Ort: der Saal ist gedämpft, das Schlachtfeld hell.
	local lighting = Config.FEEL.atmosphere[name].lighting
	if lighting then
		local tween = TweenService:Create(Lighting, TweenInfo.new(Config.FEEL.atmosphereFade), lighting)
		table.insert(tweens, tween)
		tween:Play()
	end
end
return Atmosphere
