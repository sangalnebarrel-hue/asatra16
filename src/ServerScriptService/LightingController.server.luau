-- Day cycle of DOGROTS Paradise: advances the clock (slower through the golden hour and the
-- sunset) and blends LightingConfig.Moods. Paused while a world event drives the lighting.
local RS = game:GetService("ReplicatedStorage")
local L = game:GetService("Lighting")
local C = require(RS.LightingConfig)

C.ApplyPreset()
local ev = RS:FindFirstChild("LightingRefreshEvent") or Instance.new("BindableEvent")
ev.Name = "LightingRefreshEvent"
ev.Parent = RS
ev.Event:Connect(C.ApplyPreset)

local state = RS:WaitForChild("WorldEvents"):WaitForChild("State")
L:SetAttribute("DayPhase", "")
local STEP = 0.5
task.spawn(function()
	while true do
		task.wait(STEP)
		local event = state:GetAttribute("State")
		if C.DayCycle.Enabled and (event == nil or event == "NORMAL") then
			local rate = 24 / (C.DayCycle.Minutes * 60)
			L.ClockTime = (L.ClockTime + rate * STEP * C.SpeedAt(L.ClockTime)) % 24
			C.ApplyMood(L.ClockTime)
			local t = L.ClockTime
			local phase = if t >= 19.3 or t < 5.6 then "Night" elseif t >= 16.6 then "Sunset" elseif t < 7 then "Dawn" else "Day"
			if L:GetAttribute("DayPhase") ~= phase then
				L:SetAttribute("DayPhase", phase)
			end
		end
	end
end)
print("DOGROTS_LIGHTING_APPLIED", L.ClockTime)
