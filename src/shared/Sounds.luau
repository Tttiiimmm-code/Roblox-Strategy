-- IDs aus Studio → Toolbox → Audio als "rbxassetid://123456" eintragen.
-- Leere IDs bleiben absichtlich stumm; Lautstärken sind pro Klang einstellbar.
local Sounds = {}
Sounds.IDS = {
	musicHub = "", musicBattle = "", musicVictory = "", musicDefeat = "",
	click = "", hover = "", open = "", close = "", hit = "", crit = "",
	miss = "", death = "", levelUp = "", phase = "", recruit = "",
	recruitRare = "", recruitLegendary = "", coin = "", step = "",
}
Sounds.VOLUME = {}
for name in Sounds.IDS do
	Sounds.VOLUME[name] = string.sub(name, 1, 5) == "music" and 0.35 or 0.6
end
return Sounds
