local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")

local IDs = require(script.Parent.AudioAssetIds)

local audioFolder = SoundService:WaitForChild("DOGROTS_AUDIO")
local musicGroup = audioFolder:WaitForChild("Music")
local eventGroup = audioFolder:WaitForChild("WorldEvents")

local Audio = {
	Current = nil,
	Token = 0,
}

local FADE_TIME = 1.5

local MAIN_VOLUME = 0.35
local EVENT_VOLUME = 0.45


local function getSoundId(data)
	if not data then
		return nil
	end

	local id = tonumber(data.Id)

	if not id or id <= 0 then
		return nil
	end

	return "rbxassetid://" .. id
end


local function createMusic(name, soundGroup)
	local old = SoundService:FindFirstChild(name)

	if old and old:IsA("Sound") then
		old:Destroy()
	end

	local sound = Instance.new("Sound")

	sound.Name = name
	sound.Looped = true
	sound.Volume = 0
	sound.SoundGroup = soundGroup

	sound:SetAttribute("DOGROTS_Music", true)

	sound.Parent = SoundService

	return sound
end


local mainMusic = createMusic(
	"DogrotsMainMusic",
	musicGroup
)

local eventMusic = createMusic(
	"DogrotsEventMusic",
	eventGroup
)


local function tweenVolume(sound, volume)
	local tween = TweenService:Create(
		sound,
		TweenInfo.new(
			FADE_TIME,
			Enum.EasingStyle.Quad,
			Enum.EasingDirection.Out
		),
		{
			Volume = volume
		}
	)

	tween:Play()

	return tween
end


local function playMainMusic(immediate)
	local data = IDs["MAIN/music"]
	local soundId = getSoundId(data)

	if not soundId then
		return
	end

	if mainMusic.SoundId ~= soundId then
		mainMusic:Stop()
		mainMusic.SoundId = soundId
	end

	if not mainMusic.IsPlaying then
		if immediate then
			mainMusic.Volume = MAIN_VOLUME
		else
			mainMusic.Volume = 0
		end

		mainMusic:Play()
	end

	if immediate then
		mainMusic.Volume = MAIN_VOLUME
	else
		tweenVolume(mainMusic, MAIN_VOLUME)
	end
end


local function stopMainMusic(token)
	if not mainMusic.IsPlaying then
		return
	end

	tweenVolume(mainMusic, 0)

	task.delay(FADE_TIME + 0.1, function()
		if token ~= Audio.Token then
			return
		end

		if mainMusic.IsPlaying then
			mainMusic:Stop()
		end
	end)
end


function Audio.Begin(id, late, startTimestamp)
	Audio.Token += 1

	local token = Audio.Token

	Audio.Current = id

	-- На случай моментальной смены одного ивента другим
	eventMusic:Stop()
	eventMusic.Volume = 0
	eventMusic.TimePosition = 0

	local data = IDs[id .. "/music"]
	local soundId = getSoundId(data)

	if not soundId then
		warn("Нет музыки для ивента:", id)

		Audio.Current = nil
		playMainMusic(false)

		return
	end

	-- Плавно выключаем обычную музыку
	stopMainMusic(token)

	-- Запускаем музыку ивента
	eventMusic.SoundId = soundId
	eventMusic.Volume = 0
	eventMusic.TimePosition = 0

	eventMusic:Play()

	local function syncPosition()
		if token ~= Audio.Token then
			return
		end

		if Audio.Current ~= id then
			return
		end

		if late and startTimestamp and eventMusic.TimeLength > 0 then
			local elapsed =
				workspace:GetServerTimeNow() - startTimestamp

			eventMusic.TimePosition =
				math.max(0, elapsed) % eventMusic.TimeLength
		end
	end

	if eventMusic.IsLoaded then
		syncPosition()
	else
		eventMusic.Loaded:Once(syncPosition)
	end

	tweenVolume(eventMusic, EVENT_VOLUME)
end


function Audio.Stop(immediate)
	Audio.Token += 1

	local token = Audio.Token

	Audio.Current = nil

	if eventMusic.IsPlaying then
		if immediate then
			eventMusic:Stop()
			eventMusic.Volume = 0
			eventMusic.TimePosition = 0
		else
			tweenVolume(eventMusic, 0)

			task.delay(FADE_TIME + 0.1, function()
				if token ~= Audio.Token then
					return
				end

				if eventMusic.IsPlaying then
					eventMusic:Stop()
				end

				eventMusic.Volume = 0
				eventMusic.TimePosition = 0
			end)
		end
	end

	playMainMusic(immediate)
end


-- Старые скрипты ивентов вызывают Audio.Cue().
-- Оставляем функцию пустой, чтобы они не выдавали ошибок.
function Audio.Cue()
	-- Нам нужны только музыкальные треки.
end


-- При первом запуске включаем обычную музыку.
task.defer(function()
	if Audio.Current == nil then
		playMainMusic(true)
	end
end)


return Audio