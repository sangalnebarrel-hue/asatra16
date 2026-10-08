-- Night mode, driven by the local Lighting clock (so event nights count too):
--   lights with NightOnly fade in after sunset (WorldDetailQuality still decides which are on);
--   parts with NightNeon become Neon at night (fountain glow) and go back after sunrise;
--   parts with NightOnlyBeam (searchlight and lighthouse beams) only show at night;
--   Ferris wheel bulbs (Spoke = index) chase their colours around the wheel at night.
local Lighting = game:GetService("Lighting")

local M = {}
local lights: { [Light]: number } = {}
local neon: { [BasePart]: Enum.Material } = {}
local currentNight = false
local beams: { [BasePart]: number } = {}
local bulbs: { [BasePart]: number } = {}
local spokeColors: { [number]: Color3 } = {}
local SPOKES = 16

local function add(o: Instance)
	if o:IsA("Light") and o:GetAttribute("NightOnly") then
		local base = o:GetAttribute("NightBrightness")
		if type(base) ~= "number" then
			base = o.Brightness
			o:SetAttribute("NightBrightness", base)
		end
		lights[o] = base :: number
	elseif o:IsA("BasePart") and o:GetAttribute("NightOnlyBeam") then
		-- the first look is remembered on the part, so a part that streams back in after we
		-- changed it does not mistake the changed look for its own
		local base = o:GetAttribute("NightBeamTransparency")
		if type(base) ~= "number" then
			base = o.Transparency
			o:SetAttribute("NightBeamTransparency", base)
		end
		beams[o] = base :: number
		o.Transparency = if currentNight then base :: number else 1
	elseif o:IsA("BasePart") and type(o:GetAttribute("Spoke")) == "number" then
		local spoke = (o:GetAttribute("Spoke") :: number) % SPOKES
		local color = o:GetAttribute("BulbColor")
		if typeof(color) ~= "Color3" then
			color = o.Color
			o:SetAttribute("BulbColor", color)
		end
		spokeColors[spoke] = spokeColors[spoke] or color :: Color3
		bulbs[o] = spoke
	elseif o:IsA("BasePart") and o:GetAttribute("NightNeon") then
		local name = o:GetAttribute("NightDayMaterial")
		if type(name) ~= "string" then
			name = o.Material.Name
			o:SetAttribute("NightDayMaterial", name)
		end
		local ok, material = pcall(function()
			return (Enum.Material :: any)[name :: string]
		end)
		neon[o] = if ok and material then material else Enum.Material.SmoothPlastic
		o.Material = if currentNight then Enum.Material.Neon else neon[o]
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
		-- wheel lights: each spoke takes the colour of the spoke behind it, twice a second
		local step = if night then math.floor(workspace:GetServerTimeNow() * 2) else 0
		for part, spoke in pairs(bulbs) do
			if part.Parent then
				local color = spokeColors[(spoke + step) % SPOKES] or spokeColors[spoke]
				if color and part.Color ~= color then
					part.Color = color
				end
			else
				bulbs[part] = nil
			end
		end
		task.wait(0.5)
	end
end

return M
