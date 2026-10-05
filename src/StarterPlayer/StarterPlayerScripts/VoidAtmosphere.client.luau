-- THE VOID presentation only. All transforms are relative to the portable root.
local Run=game:GetService('RunService')
local Players=game:GetService('Players')
local RS=game:GetService('ReplicatedStorage')
local player=Players.LocalPlayer
local site=workspace:WaitForChild('DOGROTS_District'):WaitForChild('13_TheVoid')
local core=site:WaitForChild('Core')
local origin=core:WaitForChild('SiteOrigin')
local portal=core:WaitForChild('PortalAnchor')
local effects=site:WaitForChild('RiftEffects')
local eventState=RS:WaitForChild('WorldEvents'):WaitForChild('State')
local rotating={}
for i,name in {'OuterRiftRing','InnerRiftRing','InnerVortex','FarVortex'} do
 local m=effects:WaitForChild(name)
 rotating[i]={Model=m,Relative=portal.CFrame:ToObjectSpace(m:GetPivot()),Speed=({.014,-.026,.045,-.065})[i]}
end
local mist={}
for _,o in site.DistantVoidAtmosphere:GetDescendants()do
 if o:IsA('BasePart')and o:GetAttribute('VoidMist')then table.insert(mist,o)end
end
local grade=Instance.new('ColorCorrectionEffect')
grade.Name='DOGROTS_VoidLocalGrade';grade.Enabled=false
local elapsed=0
local visibilityCast=RaycastParams.new()
visibilityCast.FilterType=Enum.RaycastFilterType.Exclude
visibilityCast.RespectCanCollide=true
Run.Heartbeat:Connect(function(dt)
 elapsed+=dt;if elapsed<.1 then return end;elapsed=0
 local camera=workspace.CurrentCamera;if not camera then return end
 if grade.Parent~=camera then grade.Parent=camera end
 local position=camera.CFrame.Position
 local q=origin.CFrame:PointToObjectSpace(position)
 local near=math.clamp(1-math.max(math.abs(q.X)/290,math.abs(q.Z-40)/370,math.abs(q.Y-50)/330),0,1)
 local state=eventState:GetAttribute('State')
 local overridden=state=='WARNING'or state=='ACTIVE'or state=='ENDING'
 local weight=overridden and 0 or near
 grade.Enabled=weight>.005;grade.TintColor=Color3.new(1,1,1):Lerp(Color3.fromRGB(211,193,242),weight*.38)
 grade.Saturation=-weight*.08;grade.Contrast=weight*.045
 local low=player:GetAttribute('WorldEventFX')=='Low'or player:GetAttribute('LowFX')or player:GetAttribute('ReducedMotion')or (player:GetAttribute('WorldEventFX')==nil and game:GetService('UserInputService').TouchEnabled)
 local distance=(position-portal.Position).Magnitude
 local beacon=portal:FindFirstChild('DistantPortalEmission')
 if beacon then
  local facing=portal.CFrame:PointToObjectSpace(position).Z>150
  visibilityCast.FilterDescendantsInstances=player.Character and {site,player.Character}or {site}
  local blocked=distance>1050 and workspace:Raycast(position,portal.Position-position,visibilityCast)
  beacon.Enabled=distance>1050 and facing and not blocked
  beacon.EmissionRing.Glow.Transparency=1-math.clamp((distance-1050)/250,0,1)*(overridden and .42 or .78)
 end
 local t=workspace:GetServerTimeNow()
 if distance<1800 and not low then
  for _,row in rotating do row.Model:PivotTo(portal.CFrame*CFrame.Angles(0,0,t*row.Speed)*row.Relative)end
 end
 -- Geometry haze supplies a cheap distant veil; particles use WorldDetailQuality's shared budget.
 for _,part in mist do part.LocalTransparencyModifier=overridden and .8 or near*.4 end
 local pulse=low and 0 or (.5+.5*math.sin(t*.48))*.14
 effects.VoidPortalCore.Color=Color3.fromRGB(12+math.floor(pulse*22),8,24+math.floor(pulse*35))
 -- Rare stronger inward wave, cosmetic only and disabled for reduced motion / Low.
 local phase=t%47
 local wave=not low and phase<2 and math.sin(phase*math.pi/2)or 0
 for _,row in rotating do
  if row.Model.Name=='InnerRiftRing'then
   for _,part in row.Model:GetChildren()do if part:IsA('BasePart')then part.Transparency=.08+pulse+wave*.3 end end
  end
 end
 site:SetAttribute('VoidLocalWeight',weight)
 site:SetAttribute('VoidEventOverride',overridden)
 site:SetAttribute('VoidLowQuality',not not low)
end)
script.Destroying:Connect(function()grade:Destroy()end)
