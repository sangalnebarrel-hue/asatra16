local RS=game.ReplicatedStorage;local Run=game:GetService('RunService');local Sounds=game:GetService('SoundService')
local C=require(RS.LabConfig);local AC=require(RS.LabAudioConfig);local Access=require(RS.LabAccess)
local Definitions=require(RS.DogEconomy.DogDefinitions)
local P={Seen={}}
local function activeEvent()
 local state=RS.WorldEvents.State;local value=state:GetAttribute('State');return value=='ACTIVE'or value=='ENDING'or value=='WARNING'
end
function P.Cue(key,parent)
 local a=AC[key];if not a then return end
 local uri=require(RS.AudioSource).Resolve(a.Id,'sounds/dogrots-lab2/'..a.File,false)
 if not uri then return end
 local s=Instance.new('Sound');s.Name='Genetics_'..key;s.SoundId=uri;s.Volume=a.Volume*(activeEvent()and .2 or 1);s.RollOffMinDistance=5;s.RollOffMaxDistance=40
 local group=Sounds:FindFirstChild('DOGROTS_AUDIO');s.SoundGroup=group and group:FindFirstChild('SFX');s.Parent=parent or Sounds;s:Play();game:GetService('Debris'):AddItem(s,8);return s
end
local function display(d,anchor)
 local models=RS:FindFirstChild('MenuModels');local source=d and models and models:FindFirstChild(Definitions[d.DogId] and Definitions[d.DogId].VisualAsset or d.DogId)
 if not source then return end
 local m=source:Clone();m.Name='LocalExperimentDog'
 for _,o in m:GetDescendants()do
  if o:IsA('LuaSourceContainer')or o:IsA('ProximityPrompt')or o:IsA('BillboardGui')or o:IsA('Sound')then o:Destroy()
  elseif o:IsA('BasePart')then o.Anchored=true;o.CanCollide=false;o.CanQuery=false;o.CanTouch=false end
 end
 m:PivotTo(CFrame.identity)
 local function bounds()
  local lo,hi=Vector3.one*math.huge,Vector3.one*-math.huge
  for _,o in m:GetDescendants()do if o:IsA('BasePart')and o.Transparency<1 then
   for x=-1,1,2 do for y=-1,1,2 do for z=-1,1,2 do local v=o.CFrame:PointToWorldSpace(o.Size*Vector3.new(x,y,z)/2);lo=lo:Min(v);hi=hi:Max(v)end end end
  end end;return lo,hi
 end
 local lo,hi=bounds();local size=hi-lo
 m:ScaleTo(m:GetScale()*math.min(9/size.Y,8.5/size.X,8.5/size.Z));lo,hi=bounds()
 m:PivotTo(anchor.CFrame*CFrame.new(-(lo.X+hi.X)/2,-lo.Y,-(lo.Z+hi.Z)/2))
 local tint=C.Colors[d.Variant]
 if d.Variant~='Normal'and tint then
  for _,o in m:GetDescendants()do
   if o:IsA('BasePart')then o.Color=o.Color:Lerp(tint,.6)
   elseif o:IsA('SpecialMesh')then o.VertexColor=o.VertexColor*Vector3.new(.3+tint.R*.7,.3+tint.G*.7,.3+tint.B*.7)end
  end
  local glow=Instance.new('Highlight');glow.Name='MutationHue';glow.FillColor=tint;glow.FillTransparency=.42;glow.OutlineColor=tint;glow.OutlineTransparency=.35;glow.DepthMode=Enum.HighlightDepthMode.AlwaysOnTop;glow.Parent=m
 end
 m.Parent=workspace;return m
end
function P.Play(result)
 if P.Seen[result.Token]then return end;P.Seen[result.Token]=true
 local lab=Access.Model();local chamber=lab and lab:FindFirstChild('CentralChamber');local anchor=chamber and chamber:FindFirstChild('DisplayAnchor')
 if not anchor then return end
 local player=game.Players.LocalPlayer;local reduced=player:GetAttribute('ReducedMotion')==true
 local low=reduced or player:GetAttribute('LowFX')or player:GetAttribute('WorldEventFX')=='Low'
 local camera=workspace.CurrentCamera;local oldType,oldSubject,oldCF,oldFocus,oldFov=camera.CameraType,camera.CameraSubject,camera.CFrame,camera.Focus,camera.FieldOfView
 local model,ring;local original={};local localFX=Instance.new('Folder');localFX.Name='LocalGeneticsFX';localFX.Parent=workspace
 local status=chamber:FindFirstChild('StatusText',true);local oldStatus=status and status.Text
 local lights={};for _,o in chamber:GetDescendants()do if o:IsA('PointLight')then lights[o]={Brightness=o.Brightness,Color=o.Color}end end
 local lenses={};for _,o in chamber:GetDescendants()do if o:IsA('BasePart')and(o.Name=='EnergyBase'or o.Name=='CrownEnergy'or o.Name=='MutationNode')then lenses[o]=o.Color end end
 local function cleanup()
  Run:UnbindFromRenderStep('GeneticsCamera')
  camera.CameraType=oldType;camera.CameraSubject=oldSubject;camera.CFrame=oldCF;camera.Focus=oldFocus;camera.FieldOfView=oldFov
  if model then model:Destroy()end;if ring then ring:Destroy()end;localFX:Destroy()
  for o,v in original do if o.Parent then o.LocalTransparencyModifier=v end end
  for o,v in lights do if o.Parent then o.Brightness=v.Brightness;o.Color=v.Color end end
  for o,color in lenses do if o.Parent then o.Color=color end end
  if status and status.Parent then status.Text=oldStatus end
 end
 local ok,e=xpcall(function()
  model=display(result.BeforeDog or result.Dog,anchor)
  local machine=chamber:FindFirstChild('MechanicalRing');local center=anchor.CFrame*CFrame.new(0,7.4,2.3)
  if machine and not reduced then
   ring=machine:Clone();ring.Name='LocalGeneticsRing';ring.Parent=localFX
   for _,o in machine:GetDescendants()do if o:IsA('BasePart')then original[o]=o.LocalTransparencyModifier;o.LocalTransparencyModifier=1 end end
  end
  local ringParts={};if ring then for _,o in ring:GetDescendants()do if o:IsA('BasePart')then ringParts[o]=center:ToObjectSpace(o.CFrame);o.CanCollide=false;o.CanQuery=false;o.CanTouch=false end end end
  local fx={};for i=1,(low and 3 or 8)do
   local o=Instance.new('Part');o.Name='GeneticTrace';o.Anchored=true;o.CanCollide=false;o.CanQuery=false;o.CanTouch=false;o.Size=Vector3.new(.14,low and .3 or .7,.14);o.Material=Enum.Material.Neon;o.Color=C.Colors.Normal;o.Transparency=1;o.Parent=localFX;table.insert(fx,o)
  end
  local start=os.clock();local duration=result.Duration or C.Duration;local phases={}
  P.Cue('Lock',lab.AudioAnchor)
  if not reduced then Run:BindToRenderStep('GeneticsCamera',Enum.RenderPriority.Camera.Value+10,function()
   camera.CameraType=Enum.CameraType.Scriptable;camera.FieldOfView=60;camera.CFrame=CFrame.lookAt(lab.PresentationCamera.Position,anchor.Position+Vector3.new(0,5,0));camera.Focus=CFrame.new(anchor.Position)
  end)end
  while os.clock()-start<duration do
   local t=(os.clock()-start)/duration;local suppress=activeEvent();local outcome=result.Dog and result.Dog.Variant or'Normal';local color=t>.65 and(C.Colors[outcome]or C.Colors.Normal)or C.Colors.Normal
   if status then status.Text=t<.18 and'CHAMBER SEALED'or t<.45 and'ANALYSING DNA'or t<.72 and'GENETIC SEQUENCE'or'RESULT COMMITTED'end
   if t>.18 and not phases.Scan then phases.Scan=true;P.Cue('Scan',lab.AudioAnchor)end
   if t>.35 and not phases.Charge then phases.Charge=true;P.Cue('Charge',lab.AudioAnchor)end
   if t>.72 and not phases.Pulse then
    phases.Pulse=true;P.Cue('Pulse',lab.AudioAnchor)
    if model then model:Destroy();model=nil end
    if result.Dog then model=display(result.Dog,anchor)end
   end
   for o,relative in ringParts do o.CFrame=center*CFrame.Angles(0,0,suppress and 0 or t*math.pi*.6)*relative end
   for i,o in fx do
    local a=i*math.pi*2/#fx+t*4;local y=2+(t*14+i*1.5)%14
    o.CFrame=anchor.CFrame*CFrame.new(math.sin(a)*5.5,y,math.cos(a)*5.5);o.Color=color;o.Transparency=suppress and 1 or(reduced and .65 or .28)
   end
   for o,v in lights do if not suppress then o.Brightness=v.Brightness*(t<.2 and .6 or(outcome=='Void'and t>.65 and .25 or 1));o.Color=color else o.Brightness=v.Brightness;o.Color=v.Color end end
   for o,oldColor in lenses do o.Color=not suppress and t>.65 and color or oldColor end
   local glow=model and model:FindFirstChild('MutationHue');if glow then glow.Enabled=not suppress end
   Run.RenderStepped:Wait()
  end
  P.Cue((result.Secret or(result.Dog and C.HighValueVariants[result.Dog.Variant]))and'Rare'or'Reveal',lab.AudioAnchor)
 end,debug.traceback)
 cleanup();if not ok then error(e)end
end
return P
