-- DOGROTS Paradise lighting: a tropical day with long golden-hour sunsets and neon nights.
-- LightingController (server) advances the clock and blends the Moods below by ClockTime;
-- world events (WorldEventLighting, client) take over while they run and blend back after.
local M = {}
local C = Color3.fromRGB

-- Minutes: one full day. Speed: how fast each part of the day passes (1 = normal);
-- the golden hour and the sunset run slower so everyone gets to see them.
M.DayCycle = {
	Enabled = true,
	Minutes = 24,
	StartClock = 16.4,
	Speed = { { 0, 1.15 }, { 5, 1 }, { 7, 1.2 }, { 15.5, 1 }, { 16.5, 0.55 }, { 19.4, 0.6 }, { 20.2, 1.1 }, { 24, 1.15 } },
}

-- Static values applied once (ApplyPreset); the Moods drive the rest over the day.
M.Preset = {
	ClockTime = 16.4,
	GlobalShadows = true,
	ShadowSoftness = 0.25,
	EnvironmentDiffuseScale = 0.75,
	EnvironmentSpecularScale = 0.6,
	FogStart = 0,
	FogEnd = 100000,
	FogColor = C(255, 210, 170),
	GeographicLatitude = 22,
	Brightness = 2.6,
	Ambient = C(140, 124, 116),
	OutdoorAmbient = C(198, 172, 150),
	ExposureCompensation = 0.06,
}

-- Keyframes by ClockTime. Every field is blended (Color3 / number) between neighbours.
M.Moods = {
	{ Clock = 0, Brightness = 0.75, Ambient = C(62, 70, 118), Outdoor = C(84, 98, 156), Exposure = 0.32,
		Atmo = { Density = 0.27, Offset = 0.08, Color = C(70, 86, 150), Decay = C(34, 38, 84), Glare = 0, Haze = 1.2 },
		Grade = { Tint = C(226, 232, 255), Saturation = 0.12, Contrast = 0.12 },
		Bloom = { Intensity = 0.95, Size = 30, Threshold = 1.02 }, Rays = 0,
		Clouds = { Cover = 0.34, Density = 0.22, Color = C(96, 108, 164) } },
	{ Clock = 5.3, Brightness = 0.9, Ambient = C(78, 82, 132), Outdoor = C(100, 108, 168), Exposure = 0.3,
		Atmo = { Density = 0.28, Offset = 0.08, Color = C(110, 112, 176), Decay = C(52, 48, 110), Glare = 0.1, Haze = 1.3 },
		Grade = { Tint = C(232, 232, 255), Saturation = 0.12, Contrast = 0.1 },
		Bloom = { Intensity = 0.85, Size = 30, Threshold = 1.05 }, Rays = 0.02,
		Clouds = { Cover = 0.36, Density = 0.24, Color = C(140, 132, 186) } },
	{ Clock = 6.4, Brightness = 1.7, Ambient = C(154, 122, 132), Outdoor = C(204, 156, 156), Exposure = 0.14,
		Atmo = { Density = 0.3, Offset = 0.1, Color = C(255, 192, 176), Decay = C(188, 112, 126), Glare = 0.7, Haze = 1.6 },
		Grade = { Tint = C(255, 236, 228), Saturation = 0.18, Contrast = 0.1 },
		Bloom = { Intensity = 0.55, Size = 28, Threshold = 1.3 }, Rays = 0.14,
		Clouds = { Cover = 0.38, Density = 0.26, Color = C(255, 202, 196) } },
	{ Clock = 9, Brightness = 2.6, Ambient = C(124, 132, 144), Outdoor = C(170, 180, 196), Exposure = 0.04,
		Atmo = { Density = 0.22, Offset = 0.06, Color = C(206, 228, 246), Decay = C(126, 164, 204), Glare = 0.25, Haze = 0.85 },
		Grade = { Tint = C(255, 252, 246), Saturation = 0.16, Contrast = 0.08 },
		Bloom = { Intensity = 0.32, Size = 24, Threshold = 1.55 }, Rays = 0.06,
		Clouds = { Cover = 0.4, Density = 0.28, Color = C(255, 255, 255) } },
	{ Clock = 13, Brightness = 2.9, Ambient = C(128, 134, 144), Outdoor = C(176, 184, 196), Exposure = 0.02,
		Atmo = { Density = 0.2, Offset = 0.05, Color = C(214, 232, 248), Decay = C(132, 170, 210), Glare = 0.2, Haze = 0.75 },
		Grade = { Tint = C(255, 253, 248), Saturation = 0.16, Contrast = 0.08 },
		Bloom = { Intensity = 0.3, Size = 24, Threshold = 1.6 }, Rays = 0.05,
		Clouds = { Cover = 0.42, Density = 0.3, Color = C(255, 255, 255) } },
	{ Clock = 15.8, Brightness = 2.7, Ambient = C(144, 130, 120), Outdoor = C(204, 180, 156), Exposure = 0.05,
		Atmo = { Density = 0.24, Offset = 0.08, Color = C(255, 226, 190), Decay = C(206, 152, 112), Glare = 0.45, Haze = 1.1 },
		Grade = { Tint = C(255, 244, 228), Saturation = 0.2, Contrast = 0.09 },
		Bloom = { Intensity = 0.38, Size = 26, Threshold = 1.45 }, Rays = 0.1,
		Clouds = { Cover = 0.42, Density = 0.28, Color = C(255, 236, 214) } },
	{ Clock = 17.5, Brightness = 2.5, Ambient = C(178, 132, 98), Outdoor = C(238, 174, 120), Exposure = 0.08,
		Atmo = { Density = 0.28, Offset = 0.1, Color = C(255, 198, 142), Decay = C(222, 112, 80), Glare = 1, Haze = 1.8 },
		Grade = { Tint = C(255, 234, 208), Saturation = 0.26, Contrast = 0.1 },
		Bloom = { Intensity = 0.5, Size = 28, Threshold = 1.3 }, Rays = 0.18,
		Clouds = { Cover = 0.44, Density = 0.28, Color = C(255, 198, 162) } },
	{ Clock = 18.6, Brightness = 1.7, Ambient = C(156, 98, 112), Outdoor = C(214, 124, 124), Exposure = 0.12,
		Atmo = { Density = 0.31, Offset = 0.12, Color = C(255, 152, 122), Decay = C(166, 72, 112), Glare = 1.2, Haze = 2 },
		Grade = { Tint = C(255, 222, 216), Saturation = 0.3, Contrast = 0.11 },
		Bloom = { Intensity = 0.68, Size = 30, Threshold = 1.18 }, Rays = 0.22,
		Clouds = { Cover = 0.46, Density = 0.3, Color = C(255, 150, 146) } },
	{ Clock = 19.6, Brightness = 1, Ambient = C(96, 84, 138), Outdoor = C(118, 106, 178), Exposure = 0.24,
		Atmo = { Density = 0.29, Offset = 0.1, Color = C(136, 112, 196), Decay = C(74, 52, 136), Glare = 0.3, Haze = 1.5 },
		Grade = { Tint = C(236, 228, 255), Saturation = 0.22, Contrast = 0.12 },
		Bloom = { Intensity = 0.88, Size = 30, Threshold = 1.08 }, Rays = 0.05,
		Clouds = { Cover = 0.4, Density = 0.26, Color = C(156, 124, 196) } },
	{ Clock = 21, Brightness = 0.78, Ambient = C(64, 72, 122), Outdoor = C(86, 100, 160), Exposure = 0.32,
		Atmo = { Density = 0.27, Offset = 0.08, Color = C(72, 88, 154), Decay = C(36, 40, 88), Glare = 0, Haze = 1.2 },
		Grade = { Tint = C(226, 232, 255), Saturation = 0.12, Contrast = 0.12 },
		Bloom = { Intensity = 0.95, Size = 30, Threshold = 1.02 }, Rays = 0,
		Clouds = { Cover = 0.34, Density = 0.22, Color = C(96, 108, 164) } },
}

M.Sky = { SunAngularSize = 16, MoonAngularSize = 13, StarCount = 4200, CelestialBodiesShown = true }

-- Kept for the architectural light tags (ArchitecturalLightController).
M.Architectural = {
	PrimaryArchitectureLight = { Enabled = true, Multiplier = 1 },
	SecondaryArchitectureLight = { Enabled = true, Multiplier = 0.7 },
	PathLight = { Enabled = true, Multiplier = 0.5 },
	DecorativeLight = { Enabled = true, Multiplier = 0.3 },
}

-- Legacy tables (other scripts may read them): the noon look.
M.Atmosphere = { Density = 0.2, Offset = 0.05, Color = C(214, 232, 248), Decay = C(132, 170, 210), Glare = 0.2, Haze = 0.75 }
M.BloomEffect = { Enabled = true, Intensity = 0.3, Size = 24, Threshold = 1.6 }
M.ColorCorrectionEffect = { Enabled = true, Brightness = 0, Contrast = 0.08, Saturation = 0.16, TintColor = C(255, 253, 248) }
M.SunRaysEffect = { Enabled = true, Intensity = 0.05, Spread = 0.6 }
M.Clouds = { Enabled = true, Cover = 0.42, Density = 0.3, Color = C(255, 255, 255) }
M.DepthOfFieldEffect = { Enabled = false, FarIntensity = 0, FocusDistance = 80, InFocusRadius = 80, NearIntensity = 0 }

local function blend(a, b, t)
	if typeof(a) == "Color3" then
		return a:Lerp(b, t)
	end
	return a + (b - a) * t
end

local function smooth(t)
	return t * t * (3 - 2 * t)
end

-- The two keyframes around `clock` and the blend factor between them.
local function around(clock: number)
	local moods = M.Moods
	for i = 1, #moods do
		local a = moods[i]
		local b = moods[i + 1] or moods[1]
		local t0 = a.Clock
		local t1 = if b == moods[1] then b.Clock + 24 else b.Clock
		local c = clock
		if c < t0 and i == #moods then
			c += 24
		end
		if c >= t0 and c < t1 then
			return a, b, smooth((c - t0) / (t1 - t0))
		end
	end
	return moods[1], moods[1], 0
end

-- Mood at a ClockTime, blended: {Brightness, Ambient, Outdoor, Exposure, Atmo={}, Grade={}, Bloom={}, Rays, Clouds={}}
function M.MoodAt(clock: number)
	local a, b, t = around(clock % 24)
	local out = {}
	for k, v in pairs(a) do
		if k ~= "Clock" then
			if type(v) == "table" then
				local row = {}
				for kk, vv in pairs(v) do
					row[kk] = blend(vv, b[k][kk], t)
				end
				out[k] = row
			else
				out[k] = blend(v, b[k], t)
			end
		end
	end
	return out
end

-- Day speed multiplier at a ClockTime (piecewise linear).
function M.SpeedAt(clock: number): number
	local s = M.DayCycle.Speed
	for i = 1, #s - 1 do
		local a, b = s[i], s[i + 1]
		if clock >= a[1] and clock <= b[1] then
			return blend(a[2], b[2], (clock - a[1]) / math.max(1e-3, b[1] - a[1]))
		end
	end
	return 1
end

local function effect(L: Lighting, class: string)
	local e = L:FindFirstChild("DOGROTS_" .. class)
	if not e then
		e = Instance.new(class)
		e.Name = "DOGROTS_" .. class
		e.Parent = L
	end
	return e
end

-- Writes the blended mood for `clock` into Lighting and the DOGROTS_ effects.
function M.ApplyMood(clock: number)
	local L = game:GetService("Lighting")
	local m = M.MoodAt(clock)
	L.Brightness = m.Brightness
	L.Ambient = m.Ambient
	L.OutdoorAmbient = m.Outdoor
	L.ExposureCompensation = m.Exposure
	L.FogColor = m.Atmo.Color
	local atmo = effect(L, "Atmosphere") :: Atmosphere
	for k, v in pairs(m.Atmo) do
		(atmo :: any)[k] = v
	end
	local grade = effect(L, "ColorCorrectionEffect") :: ColorCorrectionEffect
	grade.Enabled = true
	grade.TintColor = m.Grade.Tint
	grade.Saturation = m.Grade.Saturation
	grade.Contrast = m.Grade.Contrast
	local bloom = effect(L, "BloomEffect") :: BloomEffect
	bloom.Enabled = true
	bloom.Intensity = m.Bloom.Intensity
	bloom.Size = m.Bloom.Size
	bloom.Threshold = m.Bloom.Threshold
	local rays = effect(L, "SunRaysEffect") :: SunRaysEffect
	rays.Enabled = true
	rays.Intensity = m.Rays
	rays.Spread = 0.62
	local clouds = workspace.Terrain:FindFirstChildOfClass("Clouds")
	if clouds then
		clouds.Cover = m.Clouds.Cover
		clouds.Density = m.Clouds.Density
		clouds.Color = m.Clouds.Color
	end
end

function M.ApplyPreset()
	local L = game:GetService("Lighting")
	for k, v in pairs(M.Preset) do
		-- the clock belongs to the day cycle: only the very first apply sets it
		if k ~= "ClockTime" or not M.Started then
			(L :: any)[k] = v
		end
	end
	M.Started = true
	for _, class in ipairs({ "Atmosphere", "BloomEffect", "ColorCorrectionEffect", "DepthOfFieldEffect", "SunRaysEffect" }) do
		local e = effect(L, class)
		for k, v in pairs(M[class]) do
			(e :: any)[k] = v
		end
	end
	local sky = L:FindFirstChildOfClass("Sky")
	if not sky then
		sky = Instance.new("Sky")
		sky.Name = "DOGROTS_Sky"
		sky.Parent = L
	end
	for k, v in pairs(M.Sky) do
		(sky :: any)[k] = v
	end
	local clouds = workspace.Terrain:FindFirstChildOfClass("Clouds") or Instance.new("Clouds")
	clouds.Name = "DOGROTS_Clouds"
	for k, v in pairs(M.Clouds) do
		(clouds :: any)[k] = v
	end
	clouds.Parent = workspace.Terrain
	M.ApplyMood(L.ClockTime)
end

function M.ResetToDefault()
	M.ApplyPreset()
end

return M
