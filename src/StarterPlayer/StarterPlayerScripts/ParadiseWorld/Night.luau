-- Night mode, driven by the local Lighting clock (so event nights count too):
--   lights with NightOnly fade in after sunset (WorldDetailQuality still decides which are on);
--   parts with NightNeon become Neon at night (windows, signs) and go back after sunrise;
--   parts with NightOnlyBeam (searchlight and lighthouse beams) only show at night.
local Lighting = game:GetService("Lighting")

local M = {}
local lights: { [Light]: number } = {}
local neon: { [BasePart]: Enum.Material } = {}
local currentNight = false
local beams: { [BasePart]: number } = {}

local function add(o: Instance)
	if o:IsA("Light") and o:GetAttribute("NightOnly") then
		local base = o:GetAttribute("NightBrightness")
		if type(base) ~= "number" then
			base = o.Brightness
			o:SetAttribute("NightBrightness", base)
		end
		lights[o] = base :: number
	elseif o:IsA("BasePart") and o:GetAttribute("NightOnlyBeam") then
		beams[o] = o.Transparency
		o.Transparency = if currentNight then beams[o] else 1
	elseif o:IsA("BasePart") and o:GetAttribute("NightNeon") then
		neon[o] = o.Material
		if currentNight then
			o.Material = Enum.Material.Neon
		end
	end
end

-- 0 by day, 1 at night, smooth around dusk and dawn
function M.Factor(clock: number): number
	local function ramp(a: number, b: number, x: number): number
		local t = math.clamp((x - a) / (b - a), 0, 1)
		return t * t * (3 - 2 * t)
	end
	if clock >= 12 then
		return ramp(18.1, 19.3, clock)
	end
	return 1 - ramp(5.4, 6.6, clock)
end

function M.Start()
	local map = workspace:WaitForChild("DOGROTS_District")
	for _, d in ipairs(map:GetDescendants()) do
		add(d)
	end
	map.DescendantAdded:Connect(add)
	local wasNight: boolean? = nil
	while true do
		local f = M.Factor(Lighting.ClockTime)
		for light, base in pairs(lights) do
			if light.Parent then
				light.Brightness = base * f
			else
				lights[light] = nil
			end
		end
		local night = f > 0.5
		if night ~= wasNight then
			wasNight = night
			currentNight = night
			for part, material in pairs(neon) do
				if part.Parent then
					part.Material = if night then Enum.Material.Neon else material
				else
					neon[part] = nil
				end
			end
			for part, base in pairs(beams) do
				if part.Parent then
					part.Transparency = if night then base else 1
				else
					beams[part] = nil
				end
			end
		end
		task.wait(0.5)
	end
end

return M
