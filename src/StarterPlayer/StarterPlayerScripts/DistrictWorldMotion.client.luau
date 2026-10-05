-- Cosmetic animations run locally; all moving props are non-colliding.
local Run=game:GetService("RunService")
local map=workspace:WaitForChild("DOGROTS_District")
local motion={}
local function register(o)
 local kind=o:GetAttribute("Motion")
 if not kind or motion[o] or not (o:IsA("Model") or o:IsA("BasePart")) then return end
 if o:IsA("Model") and not o:FindFirstChildWhichIsA("BasePart",true) then return end
 local cf=o:GetPivot();local lamp=o:FindFirstChildOfClass("PointLight")
 motion[o]={kind=kind,cf=cf,travel=o:GetAttribute("Travel") or Vector3.zero,phase=o:GetAttribute("Phase") or 0,
  speed=o:GetAttribute("AngularSpeed") or .2,period=o:GetAttribute("Period") or 12,
  anchor=o:GetAttribute("Anchor"),cable=o.Parent:FindFirstChild(o:GetAttribute("CableName") or "-"),lamp=lamp,brightness=lamp and lamp.Brightness or 0}
end
for _,o in map:GetDescendants() do register(o) end
map.DescendantAdded:Connect(function(o) task.defer(function() register(o);if o.Parent then register(o.Parent) end end) end)
local elapsed=0
Run.Heartbeat:Connect(function(dt)
 elapsed+=dt;if elapsed<1/30 then return end;elapsed=0
 local t=workspace:GetServerTimeNow();local camera=workspace.CurrentCamera
 for o,d in pairs(motion) do
  if not o:IsDescendantOf(map) then motion[o]=nil;continue end
  if camera and (camera.CFrame.Position-d.cf.Position).Magnitude>800 then continue end
  local nextCF
  if d.kind=="Ring" then
   nextCF=d.cf*CFrame.Angles(0,0,(t*d.speed)%(2*math.pi))
  elseif d.kind=="Belt" then
   nextCF=d.cf+d.travel*((t/d.period+d.phase)%1)
  elseif d.kind=="Hoist" then
   nextCF=d.cf+d.travel*(.5+.5*math.sin(t*2*math.pi/d.period))
   if d.cable and d.cable.Parent and d.anchor then
    local endPos=nextCF.Position+Vector3.new(0,3,0)
    d.cable.Size=Vector3.new(.22,.22,(d.anchor-endPos).Magnitude)
    d.cable.CFrame=CFrame.lookAt((d.anchor+endPos)/2,endPos)
   end
  elseif d.kind=="Float" then
   nextCF=(d.cf+d.travel*math.sin(t*.7+d.phase))*CFrame.Angles(0,math.sin(t*.23+d.phase)*.12,0)
  elseif d.kind=="Drone" then
   nextCF=(d.cf+Vector3.new(math.sin(t*.25+d.phase)*d.travel.X,math.sin(t*.8+d.phase)*d.travel.Y,math.cos(t*.25+d.phase)*d.travel.Z))*CFrame.Angles(0,t*.12,0)
  elseif d.kind=="Pulse" and d.lamp then
   d.lamp.Brightness=d.brightness*(.55+.45*math.sin(t*3+d.phase)^2)
  end
  if nextCF then o:PivotTo(nextCF) end
 end
end)
print("DOGROTS_MOTION_READY")

