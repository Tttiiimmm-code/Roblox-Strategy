-- Offizielle Asset-IDs aus PLAN.md: vom Nutzer in Studio probehören.
-- IDs aus Studio → Toolbox → Audio als "rbxassetid://123456" eintragen.
-- Leere IDs bleiben absichtlich stumm; Lautstärken sind pro Klang einstellbar.
local Sounds = {}
Sounds.IDS = {
	musicHub = "rbxassetid://1839906422", musicBattle = "rbxassetid://1837301451", musicVictory = "rbxassetid://9041812129", musicDefeat = "rbxassetid://9048278630",
	click = "rbxassetid://9119717523", hover = "", open = "rbxassetid://9120709477", close = "rbxassetid://9113842150", hit = "rbxassetid://9119746592", crit = "rbxassetid://9116673678",
	miss = "rbxassetid://9119749145", death = "rbxassetid://9113480915", levelUp = "rbxassetid://1836860398", phase = "", recruit = "rbxassetid://9116394545",
	recruitRare = "rbxassetid://9116395089", recruitLegendary = "rbxassetid://9116395085", coin = "rbxassetid://127645268874265", step = "",
}
Sounds.VOLUME = {}
for name in Sounds.IDS do
	Sounds.VOLUME[name] = string.sub(name, 1, 5) == "music" and 0.3 or 0.6
end
Sounds.VOLUME.click = 0.4
Sounds.VOLUME.hit = 0.6
Sounds.VOLUME.miss = 0.6
Sounds.VOLUME.crit = 0.8
return Sounds
