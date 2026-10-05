local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Sounds = require(Shared:WaitForChild("Sounds"))
local Config = require(Shared:WaitForChild("Config"))
local SoundPlayer = {}
local currentMusic, currentName
local random = Random.new()

local function create(name)
	local id = Sounds.IDS[name]
	if not id or id == "" then
		return nil
	end
	local sound = Instance.new("Sound")
	sound.SoundId = id
	sound.Volume = (Sounds.VOLUME[name] or 0.6) * Config.FEEL.volume
	sound.Parent = SoundService
	return sound
end

function SoundPlayer.play(name, opts)
	local sound = create(name)
	if not sound then return end
	if opts and opts.varyPitch then
		sound.PlaybackSpeed = random:NextNumber(1 - Config.FEEL.pitchVariation, 1 + Config.FEEL.pitchVariation)
	end
	sound.Ended:Once(function() sound:Destroy() end)
	Debris:AddItem(sound, Config.FEEL.soundLifetime)
	sound:Play()
end

function SoundPlayer.playMusic(name, opts)
	if name == currentName then return end
	currentName = name
	local old = currentMusic
	currentMusic = create(name)
	local fade = TweenInfo.new(Config.FEEL.musicFade)
	if old then
		TweenService:Create(old, fade, { Volume = 0 }):Play()
		Debris:AddItem(old, Config.FEEL.musicFade)
	end
	if currentMusic then
		local volume = currentMusic.Volume
		currentMusic.Volume = 0
		currentMusic.Looped = not opts or opts.loop ~= false
		currentMusic:Play()
		TweenService:Create(currentMusic, fade, { Volume = volume }):Play()
	end
end
return SoundPlayer
