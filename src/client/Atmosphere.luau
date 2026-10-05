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
		if not effects[key] then
			local effect = Instance.new(class)
			effect.Name = "GameFeel_" .. key
			effect.Parent = Lighting
			effects[key] = effect
		end
		local tween = TweenService:Create(effects[key], TweenInfo.new(Config.FEEL.atmosphereFade), Config.FEEL.atmosphere[name][key])
		table.insert(tweens, tween)
		tween:Play()
	end
end
return Atmosphere
