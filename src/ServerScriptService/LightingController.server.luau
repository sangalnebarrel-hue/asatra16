local RS=game:GetService('ReplicatedStorage');local L=game:GetService('Lighting');local C=require(RS.LightingConfig)
C.ApplyPreset();local ev=RS:FindFirstChild('LightingRefreshEvent')or Instance.new('BindableEvent');ev.Name='LightingRefreshEvent';ev.Parent=RS;ev.Event:Connect(C.ApplyPreset)
task.spawn(function()while true do task.wait(1)
 local event=RS.WorldEvents.State:GetAttribute('State')
 if C.DayCycle.Enabled and (event==nil or event=='NORMAL')then
  L.ClockTime=(L.ClockTime+24/(C.DayCycle.Minutes*60))%24
  local day=math.clamp((math.cos((L.ClockTime-13)*math.pi/12)+.2)*1.2,0,1)
  L.Brightness=.85+day*1.4;L.Ambient=Color3.fromRGB(68,79,112):Lerp(C.Preset.Ambient,day);L.OutdoorAmbient=Color3.fromRGB(84,98,132):Lerp(C.Preset.OutdoorAmbient,day)
 end
end end)
print('DOGROTS_LIGHTING_APPLIED',L.ClockTime)
