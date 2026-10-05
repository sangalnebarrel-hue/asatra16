-- NUCLEAR PUG, "CRITICALITY". A Geiger counter starts clicking and will not stop. The
-- mouth's runes go toxic green, a hazard plate lights under the pug and three hazard rings
-- lift off the belt around it, spinning faster with the clicks while the screen's edges
-- glow. At 1.2 the reactor on its back lights and green sparks rush into it; at 1.6 it
-- goes critical: a flash, a shockwave, the tongue's edges turn green down the line and a
-- mushroom cloud climbs out of its twin vents to the roof of the mouth. Fallout drifts
-- down; at 4.2 the cloud lets go, the rings clatter onto the belt and it stands there,
-- delighted, among glowing puddles. Off the tongue (a Lucky pad, open air) toxic runes
-- stand round it instead of the mouth's, a green haze creeps over the ground, the blast
-- runs on with no walls to stop it and the cloud climbs into the open sky.
local Players=game:GetService('Players')
local C=Color3.fromRGB
local WHITE=Color3.new(1,1,1)
local HAZARD,INK,TOXIC,SOOT,PALE=C(255,214,0),C(26,26,20),C(120,255,60),C(40,90,20),C(222,255,190)
local TICK='rbxasset://sounds/volume_slider.ogg'
local CHARGE,BOOM,CLEAR=1.2,1.6,4.2
-- The hazard rings: resting height above the belt and spin direction.
local RINGS={{.25,1},{3,-1},{6,1}}
local BONES={'Vent_L','Vent_R','Body'}
local function smooth(x)x=math.clamp(x,0,1);return x*x*(3-2*x)end
local function out3(x)x=math.clamp(x,0,1);return 1-(1-x)^3 end
local function backOut(x)x=math.clamp(x,0,1)-1;local c=1.70158;return 1+(c+1)*x*x*x+c*x*x end
local function curve(points)
 local k={}
 for i,p in ipairs(points)do k[i]=NumberSequenceKeypoint.new(p[1],p[2])end
 return NumberSequence.new(k)
end
local function setSkin(s,strength,tint)s.EmissiveStrength=strength;s.EmissiveTint=tint end
-- Geiger clicks a second at t: 2 → 20 while it builds, a crackle into the blast, then thinning.
local function rate(t)
 if t<CHARGE then return 2*10^(t/CHARGE)end
 if t<BOOM then return 20+12*(t-CHARGE)/(BOOM-CHARGE)end
 if t<CLEAR then return 3+11*math.exp(-(t-BOOM)*1.1)end
 return 1.6
end

return function(ctx)
 ctx.WhisperStyle={Font=Enum.Font.RobotoMono,Color=C(196,255,150),Glitch=.05,Chroma=false,Shake=false,Type=.04}
 local Kit,scope,model,config=ctx.Kit,ctx.Scope,ctx.Model,ctx.Config
 local low,calm,hold,origin=ctx.Low,Kit.ReducedMotion(),config.Hold,ctx.Origin
 local GREEN=config.Color
 local size=Kit.Size(model)
 local joined=ctx:Elapsed()
 -- One-shots fire on time only: a late joiner gets the state, not a pile-up of cues.
 local function fresh(t)return ctx:Elapsed()-t<.35 end
 -- Off the tongue (a Lucky pad): open air, no mouth, no roof, no walls, any facing.
 local onTongue=(ctx.Venue or 'Tongue')=='Tongue'
 local ground=model:GetAttribute('GroundLocal')
 ground=typeof(ground)=='Vector3'and ground or Vector3.zero
 -- Its ground frame; until the rig streams in, it faces down the line from its stage (in
 -- the open: toward this player's camera, as a pad dog faces its opener).
 local look=Vector3.zAxis
 local camera=workspace.CurrentCamera
 if not onTongue and camera then
  local d=camera.CFrame.Position-origin
  d=Vector3.new(d.X,0,d.Z)
  if d.Magnitude>.1 then look=d.Unit end
 end
 local home=CFrame.lookAt(origin,origin+look)
 -- Open air: the stage may be a raised pad, so whatever lies off it finds the real ground
 -- under it (never a player, the dog or our own parts). The belt is flat.
 local probe=RaycastParams.new();probe.FilterType=Enum.RaycastFilterType.Exclude;probe.RespectCanCollide=true
 local function settle(at:Vector3):Vector3
  if onTongue then return at end
  local skip:{Instance}={model,scope.Folder}
  for _,p in ipairs(Players:GetPlayers())do if p.Character then table.insert(skip,p.Character)end end
  probe.FilterDescendantsInstances=skip
  local hit=workspace:Raycast(at+Vector3.new(0,3,0),Vector3.new(0,-6,0),probe)
  return hit and hit.Position or at
 end
 -- Where the rings come to rest: on the belt, or in the open on the lowest ground under
 -- their landing circle (r 8.5: a pad stands proud of its court).
 local land=.12
 if not onTongue then
  local floor=origin.Y
  for k=1,6 do
   local a=k/6*math.pi*2
   floor=math.min(floor,settle(origin+Vector3.new(math.cos(a)*8.5,0,math.sin(a)*8.5)).Y)
  end
  land=.12+math.max(floor-origin.Y,-2)
 end
 -- The cap's climb over the stage: to just under the mouth's roof (underside y 23.5), or
 -- in the open to a virtual ceiling ~18 over it. ROLL: the condensation ring's height under
 -- the cap at 1.9; SHOCK: the blast's reach (the mouth's walls are at x=±15.5).
 local RISE,ROLL,SHOCK=6.7,9.2,15
 if not onTongue then RISE,ROLL,SHOCK=8.5,9.9,22 end
 local function frame()
  if model.Parent and Kit.Root(model)then return model:GetPivot()*CFrame.new(ground)end
  return home
 end
 local bones:{[string]:Bone}={}
 local function bone(name):Vector3?
  local b=bones[name]
  if b and b.Parent then return b.TransformedWorldCFrame.Position end
  return nil
 end

 scope:Duck(.4,.6)
 local grade=scope:Grade({TintColor=C(238,255,228),Saturation=.04},joined<.6 and .8 or .2)
 -- The reactor core rides its Body bone: the dog's light and the Geiger counter live here
 -- (lights and emitters parented under the district get throttled).
 local core=scope:Anchor(origin+Vector3.new(0,size.Y*.45,0),'Reactor')
 local glow=scope:Light(core,GREEN,20,0)
 local clicks={}
 for i=1,low and 3 or 5 do
  local s=Instance.new('Sound');s.Name='Geiger';s.SoundId=TICK;s.Volume=0;s.RollOffMinDistance=18;s.RollOffMaxDistance=220
  local eq=Instance.new('EqualizerSoundEffect');eq.LowGain=-14;eq.MidGain=2;eq.HighGain=4;eq.Parent=s
  local grit=Instance.new('DistortionSoundEffect');grit.Level=.55;grit.Parent=s
  s.Parent=core;clicks[i]=s
 end
 -- A pooled click (no new sounds per click); every click also kicks the glow.
 local turn,kick=0,0
 local function click(volume:number,speed:number?)
  turn=turn%#clicks+1
  local s=clicks[turn]
  s.Volume=volume;s.PlaybackSpeed=speed or Kit.Random(2.5,3.6);s.TimePosition=0;s:Play()
  kick=1
 end

 -- The edges of the screen glow green, stronger the closer you stand.
 local edges={}
 local playerGui=Players.LocalPlayer:FindFirstChildOfClass('PlayerGui')
 if playerGui then
  local gui=Instance.new('ScreenGui');gui.Name='DOGROTS_NuclearPugGlow';gui.ResetOnSpawn=false
  gui.IgnoreGuiInset=true;gui.DisplayOrder=93
  for _,e in ipairs({{1,.3,0,0,90},{1,.3,0,.7,-90},{.22,1,0,0,0},{.22,1,.78,0,180}})do
   local f=Instance.new('Frame');f.Name='Edge';f.BorderSizePixel=0;f.BackgroundColor3=GREEN;f.BackgroundTransparency=1
   f.Size=UDim2.fromScale(e[1],e[2]);f.Position=UDim2.fromScale(e[3],e[4])
   local g=Instance.new('UIGradient');g.Rotation=e[5];g.Transparency=curve({{0,0},{.5,.75},{1,1}})
   g.Parent=f;f.Parent=gui;table.insert(edges,f)
  end
  gui.Parent=playerGui
  scope:Add(gui)
 end

 -- The mouth goes toxic: runes from the throat out to the stage, the mist, the nearest
 -- lanterns. The tongue's warm edges follow at the blast. All of it eases back at the end.
 local restore={}
 local function tint(o,props)
  local saved={}
  for k in pairs(props)do saved[k]=(o::any)[k]end
  scope:Override(o,props);table.insert(restore,{o,saved})
 end
 -- A tween on a world object stops with the arrival, so Override's restore has the last word.
 local function ease(o,seconds,props)
  local t=Kit.Tween(o,seconds,props)
  scope:Add(function()t:Cancel()end)
  return t
 end
 local district=onTongue and workspace:FindFirstChild('DOGROTS_District')or nil
 local factory=district and district:FindFirstChild('02_DogFactory')
 local tunnel=factory and factory:FindFirstChild('DarkMouthTunnel')
 local line=district and district:FindFirstChild('03_DogLine')
 local guides={}
 if tunnel then
  local runes={}
  for _,o in ipairs(tunnel:GetDescendants())do
   if o.Name=='MouthRune'and o:IsA('BasePart')then table.insert(runes,o)
   elseif o:IsA('ParticleEmitter')then scope:Override(o,{Color=ColorSequence.new(C(110,220,60),C(30,70,16))})end
  end
  table.sort(runes,function(a,b)return (a.Position-origin).Magnitude>(b.Position-origin).Magnitude end)
  for i,p in ipairs(runes)do
   task.delay(math.max(0,math.floor((i-1)/2)*.09-joined),function()
    if scope.Alive and p.Parent then tint(p,{Color=GREEN})end
   end)
  end
 end
 if line then
  for _,lantern in ipairs(line:GetChildren())do
   local lens=lantern.Name=='PromenadeLantern'and lantern:FindFirstChild('WarmLens')
   if lens and lens:IsA('BasePart')and (lens.Position-origin).Magnitude<30 then
    tint(lens,{Color=C(200,255,140)})
    for _,l in ipairs(lantern:GetDescendants())do
     if l:IsA('PointLight')then tint(l,{Color=GREEN})end
    end
   end
  end
  local skin=line:FindFirstChild('Tongue')
  for _,g in ipairs(skin and skin:GetChildren()or {})do
   if g.Name=='WarmEdgeGuide'and g:IsA('BasePart')and math.abs(g.Position.Z-origin.Z)<70 then table.insert(guides,g)end
  end
 end
 -- In the open the stage brings its own: toxic runes standing round it, lit in pairs from
 -- behind it to its front (as the mouth's light from the throat out), lamps on half of them
 -- for the lanterns and a green ground haze for the mist. Ours, so they burn out after.
 local toxic:{{Part:BasePart,Lamp:PointLight?}}={}
 local haze:ParticleEmitter?=nil
 if not onTongue then
  local f=frame().LookVector
  local fwd=Vector3.new(f.X,0,f.Z)
  fwd=fwd.Magnitude>.1 and fwd.Unit or Vector3.zAxis
  local right=fwd:Cross(Vector3.yAxis)
  local rows=low and 2 or 4
  for k=1,rows do
   local a=(k-.5)/rows*math.pi
   for side=-1,1,2 do
    local p:BasePart=scope:Part({Name='ToxicRune',Color=GREEN,Transparency=1,Size=Vector3.new(.4,1.6,.4),
     Position=settle(origin+(right*side*math.sin(a)-fwd*math.cos(a))*11)+Vector3.new(0,.8,0)})
    local rune={Part=p,Lamp=(not low and side==1)and scope:Light(p,GREEN,12,0)or nil}
    table.insert(toxic,rune)
    task.delay(math.max(0,(k-1)*.09-joined),function()
     if not scope.Alive or not p.Parent then return end
     Kit.Tween(p,joined>.5 and .1 or .25,{Transparency=0})
     if rune.Lamp then Kit.Tween(rune.Lamp,.25,{Brightness=1.2})end
    end)
   end
  end
  local bed=scope:Part({Name='Haze',Size=Vector3.new(14,.2,14),Transparency=1,Position=origin+Vector3.new(0,.3,0)})
  haze=scope:Emitter(bed,{Texture=Kit.Textures.Smoke,Rate=low and 2 or 5,Color=ColorSequence.new(C(110,220,60),C(30,70,16)),
   LightEmission=.3,Lifetime=NumberRange.new(2,3),Speed=NumberRange.new(.3,1),SpreadAngle=Vector2.new(60,60),
   Size=curve({{0,2},{1,5}}),Transparency=curve({{0,1},{.35,.6},{1,1}})})
 end

 -- The hazard plate under it: a trefoil on a black disc.
 local plate={}
 if not low then
  local base=CFrame.new(origin+Vector3.new(0,.1,0))
  -- Radius 6 on the belt; off the tongue it stays on the 8x8 Lucky pad.
  local k=onTongue and 1 or 3.8/6
  plate[1]=scope:Part({Name='HazardPlate',Shape=Enum.PartType.Cylinder,Material=Enum.Material.SmoothPlastic,Color=INK,
   Transparency=1,Size=Vector3.new(.04,12*k,12*k),CFrame=base*CFrame.Angles(0,0,math.pi/2)})
  for b=0,2 do
   for s=-2,2 do
    table.insert(plate,scope:Part({Name='Trefoil',Color=HAZARD,Transparency=1,Size=Vector3.new(3.4*k,.04,1.2*k),
     CFrame=base*CFrame.Angles(0,math.rad(90+b*120+s*12),0)*CFrame.new(3.9*k,.03,0)}))
   end
  end
 end
 -- Three rings of hazard tape (yellow neon, black), posed every frame.
 local count=low and 12 or 18
 local turns={}
 for k=1,count do turns[k]=CFrame.Angles(0,k/count*math.pi*2,0)end
 local rings={}
 for i,def in ipairs(RINGS)do
  local ring={Height=def[1],Dir=def[2],Spin=i*.7,R=0,Landed=false,Parts={},
   Axis=Vector3.new(math.cos(i*2.1),0,math.sin(i*2.1))}
  for k=1,count do
   local stripe=k%2==1
   ring.Parts[k]=scope:Part({Name='HazardTape',Color=stripe and HAZARD or INK,Transparency=1,
    Material=stripe and Enum.Material.Neon or Enum.Material.SmoothPlastic,Size=Vector3.new(.55,.3,1)})
  end
  rings[i]=ring
 end
 -- The cloud: an ellipsoid cap with a hot core on a glowing stem, a rolling skirt below it.
 local function blob(name,color)
  local p=scope:Part({Name=name,Color=color,Transparency=1,Size=Vector3.one})
  local mesh=Instance.new('SpecialMesh');mesh.MeshType=Enum.MeshType.Sphere;mesh.Parent=p
  return p
 end
 local cap,capCore=blob('Cap',TOXIC),blob('CapCore',PALE)
 local stem=scope:Part({Name='Stem',Shape=Enum.PartType.Cylinder,Color=TOXIC,Transparency=1,Size=Vector3.one*.1})
 local spine=scope:Part({Name='StemCore',Shape=Enum.PartType.Cylinder,Color=PALE,Transparency=1,Size=Vector3.one*.1})
 local skirt={}
 if not low then
  for i=1,8 do skirt[i]=scope:Part({Name='Skirt',Shape=Enum.PartType.Ball,Color=C(96,206,44),Transparency=1,Size=Vector3.one})end
 end
 local capLight=scope:Light(cap,TOXIC,30,0)
 local smoke=scope:Emitter(cap,{Texture=Kit.Textures.Smoke,Color=ColorSequence.new(TOXIC,SOOT),LightEmission=.3,
  Shape=Enum.ParticleEmitterShape.Sphere,Lifetime=NumberRange.new(1.4,2.2),Speed=NumberRange.new(.3,1.5),Drag=1,
  Size=curve({{0,2},{1,6}}),Transparency=curve({{0,1},{.15,.35},{.6,.55},{1,1}}),
  Rotation=NumberRange.new(0,360),RotSpeed=NumberRange.new(-40,40)})
 local sparks=scope:Emitter(cap,{Color=ColorSequence.new(PALE,GREEN),Shape=Enum.ParticleEmitterShape.Sphere,
  Lifetime=NumberRange.new(.6,1.2),Speed=NumberRange.new(1,3),Size=NumberSequence.new(.45,0)})
 local fallout=scope:Emitter(cap,{Color=ColorSequence.new(GREEN),Lifetime=NumberRange.new(1.1,1.5),Speed=NumberRange.new(0,1),
  Acceleration=Vector3.new(0,-14,0),Size=NumberSequence.new(.35,.12),Transparency=NumberSequence.new(0,.4)})
 -- Green sparks rushing into the reactor from a sphere around it while it charges.
 local well=scope:Part({Name='ChargeWell',Size=Vector3.one*14,Transparency=1,CFrame=CFrame.new(core.Position)})
 local inward=scope:Emitter(well,{Color=ColorSequence.new(PALE,GREEN),Shape=Enum.ParticleEmitterShape.Sphere,
  ShapeStyle=Enum.ParticleEmitterShapeStyle.Surface,ShapeInOut=Enum.ParticleEmitterShapeInOut.Inward,
  Speed=NumberRange.new(14),Lifetime=NumberRange.new(.48,.5),Size=curve({{0,.2},{.8,.5},{1,0}}),SpreadAngle=Vector2.zero})
 -- Steam from the twin vents.
 local jets,vapour={},{}
 for i=1,2 do
  jets[i]=scope:Anchor(origin,'Vent')
  vapour[i]=scope:Emitter(jets[i],{Texture=Kit.Textures.Smoke,Color=ColorSequence.new(PALE,TOXIC),LightEmission=.5,
   Lifetime=NumberRange.new(.5,.9),Speed=NumberRange.new(5,8),SpreadAngle=Vector2.new(10,10),Drag=2,
   Size=curve({{0,.4},{1,2.2}}),Transparency=curve({{0,.6},{.3,.4},{1,1}})})
 end
 local function vent(n)for _,e in ipairs(vapour)do e.Rate=n end end

 -- Its own skin: the reactor pieces burn green from 1.2, everything flares at the blast.
 local skins,seen={},{}
 local function grab(o)
  if not o:IsA('SurfaceAppearance')or seen[o]then return end
  local ok,strength,hue=pcall(function()return o.EmissiveStrength,o.EmissiveTint end)
  if not ok then return end
  seen[o]=true
  local part=o.Parent
  table.insert(skins,{Look=o,Strength=strength,Reactor=part~=nil and string.find(string.lower(part.Name),'reactor',1,true)~=nil})
  scope:Override(o,{EmissiveStrength=strength,EmissiveTint=hue})
 end
 for _,o in ipairs(model:GetDescendants())do grab(o)end
 scope:Add(model.DescendantAdded:Connect(grab))

 local lookup,nextClick=0,math.max(joined,0)
 local capXZ:Vector3?=nil
 local cleared=false
 -- It trembles while it charges (local only, about its own feet).
 local shiver=(not calm and joined<BOOM)and scope:Offset(model)or nil
 local hl:Highlight?=nil
 local puddles={}
 local function poseRing(i,ring,el,dt)
  local t0=.1+(i-1)*.15
  local k=(el-t0)/.5
  local show=smooth((el-t0)/.35)
  local r=9.5-2.5*out3(k)-1.6*smooth((el-CHARGE)/(BOOM-CHARGE))+3.1*out3((el-BOOM)/.35)
  local h=.25+(ring.Height-.25)*backOut(k)
  local spin,tilt,fade=.8+2.7*smooth(el/BOOM),0,0
  if el>=BOOM then
   spin=1.2+3.3*math.exp(-(el-BOOM)*1.5)
   -- Knocked off level by the blast (the floor ring barely: it would dip into the belt).
   tilt=.16*math.exp(-(el-BOOM)*1.4)*math.sin((el-BOOM)*9+i*2)*math.min(1,(h-.12)/2)
  end
  if el>=CLEAR then
   -- It lets go: the ring drops onto the belt (or the ground), spins down like a coin and fades.
   local t,drop=el-CLEAR,math.sqrt(2*math.max(h-land,0)/45)
   if t<drop then h-=22.5*t*t
   else
    h=land;tilt=0;spin*=math.exp(-(t-drop)*3);fade=smooth((t-drop-.15)/.7)
    if not ring.Landed then
     ring.Landed=true
     if el-(CLEAR+drop)<.3 then click(.5,Kit.Random(1.1,1.5))end
    end
   end
  end
  ring.Spin+=ring.Dir*spin*dt
  local vis=show*(1-fade)
  local cf=CFrame.new(origin+Vector3.new(0,h,0))*CFrame.fromAxisAngle(ring.Axis,tilt)*CFrame.Angles(0,ring.Spin,0)
  local resize=math.abs(r-ring.R)>.005
  if resize then ring.R=r end
  local arc=2*math.pi*r/count*1.03
  local yellow,black=1-(.85+.1*(calm and 0 or kick))*vis,1-.7*vis
  for n,p in ipairs(ring.Parts)do
   if resize then p.Size=Vector3.new(.55,.3,arc)end
   p.CFrame=cf*turns[n]*CFrame.new(r,0,0)
   p.Transparency=n%2==1 and yellow or black
  end
 end

 scope:Every(function(dt)
  local el=ctx:Elapsed()
  local now=os.clock()
  if now>=lookup then
   lookup=now+.5
   for _,name in ipairs(BONES)do
    local b=bones[name]
    -- A streamed-out skin keeps its bones (Parent set) but frozen: look again.
    if not(b and b:IsDescendantOf(model))then
     local found=model:FindFirstChild(name,true)
     if found and found:IsA('Bone')then bones[name]=found else bones[name]=nil end
    end
   end
  end
  local f=frame()
  local ventL=bone('Vent_L')or f:PointToWorldSpace(Vector3.new(size.X*.29,size.Y*.97,size.Z*.185))
  local ventR=bone('Vent_R')or f:PointToWorldSpace(Vector3.new(-size.X*.29,size.Y*.97,size.Z*.185))
  local vents=(ventL+ventR)/2
  core.CFrame=CFrame.new(bone('Body')or f:PointToWorldSpace(Vector3.new(0,size.Y*.45,0)))
  jets[1].CFrame=CFrame.new(ventL);jets[2].CFrame=CFrame.new(ventR)
  well.CFrame=CFrame.new(vents-Vector3.new(0,1.2,0))

  -- The Geiger counter: irregular clicks at rate(t), at most two a frame.
  if nextClick<el-.25 then nextClick=el end
  local n=0
  while nextClick<=el and n<2 do
   n+=1
   click(el<CLEAR and .32+.2*math.min(rate(el)/30,1)or .16)
   nextClick+=Kit.Random(.45,1.55)/rate(nextClick)
  end
  local pop=calm and 0 or kick
  kick*=math.exp(-dt*16)
  local charge=smooth((el-CHARGE)/.25)
  local flare=el>=BOOM and math.exp(-(el-BOOM)*2.2)or 0
  local done=smooth((el-CLEAR)/1)
  local out=1-smooth((el-hold+.8)/.8)

  -- The light on the dog: a 3 Hz pulse that builds, faster while charging, then the blast.
  local level
  if el<CHARGE then level=6*smooth(el/CHARGE)*(calm and .7 or .55+.45*math.sin(el*math.pi*6))
  elseif el<BOOM then level=6*(calm and .85 or .6+.4*math.sin(el*math.pi*12))
  else level=(2.5+9*flare)*(1-.6*done)end
  glow.Brightness=(level+1.5*pop)*out
  if #edges>0 then
   local a
   if el<CHARGE then a=.04+.2*smooth(el/CHARGE)
   elseif el<BOOM then a=.24+.1*charge
   else a=.2+.35*flare end
   a=(a+.06*pop)*(1-done)*(.3+.7*Kit.Near(origin,160))
   local color=GREEN:Lerp(PALE,flare*.6)
   for _,e in ipairs(edges)do e.BackgroundTransparency=1-a;e.BackgroundColor3=color end
  end
  for i,ring in ipairs(rings)do poseRing(i,ring,el,dt)end
  if #plate>0 then
   local vis=smooth((el-.05)/.5)*(1-smooth((el-CLEAR-.6)/.9))
   local color=el>=BOOM and HAZARD:Lerp(WHITE,math.exp(-(el-BOOM)*5))or HAZARD
   plate[1].Transparency=1-.7*vis
   for i=2,#plate do plate[i].Transparency=1-(.8+.15*pop)*vis;plate[i].Color=color end
  end
  if el>=CHARGE-.05 then
   local pulse=calm and .5 or .5+.5*math.sin(el*math.pi*6)
   local hot=charge*(.8+.2*pulse)*(1-.55*done)*out
   for _,s in ipairs(skins)do
    if s.Look.Parent then
     local strength=s.Reactor and s.Strength+(1-s.Strength)*hot+1.2*flare or s.Strength+flare
     pcall(setSkin,s.Look,strength,WHITE:Lerp(GREEN,s.Reactor and math.max(.8*hot,flare)or flare*.85))
    end
   end
  end
  if hl then
   local success=el>=CLEAR and math.exp(-(el-CLEAR)*3)or 0
   local fade=1-smooth((el-CLEAR-.4)/1.2)
   hl.FillColor=GREEN:Lerp(WHITE,math.max(success*.6,flare*.3))
   hl.FillTransparency=1-math.min(.12*charge+.55*flare+.5*success+.08*pop,1)*fade
   hl.OutlineTransparency=1-.8*charge*fade
  end
  if shiver then
   if el<BOOM then
    local a=.1*smooth((el-CHARGE)/(BOOM-CHARGE))
    shiver.CFrame=CFrame.new(Kit.Random(-a,a),Kit.Random(0,a*.6),Kit.Random(-a,a))
   else shiver.CFrame=CFrame.identity;shiver=nil end
  end

  -- The mushroom cloud: out of the vents at 1.6, up to just under the roof (y 23.5), or
  -- in the open straight up over the stage to its virtual ceiling.
  if el>=BOOM and not cleared then
   local xz=capXZ or vents
   capXZ=xz
   local u=el-BOOM
   local fade=smooth((el-CLEAR)/.9)
   local w=(1.5+11.5*out3(u/1.6))*(1+.18*fade)*(1+.03*math.sin(el*7))
   local h=w*.55
   local center=Vector3.new(xz.X,origin.Y+5.8+RISE*out3(u/2),xz.Z)
   cap.Size=Vector3.new(w,h,w);cap.CFrame=CFrame.new(center);cap.Transparency=.5+.5*fade
   capCore.Size=Vector3.new(w,h,w)*.58;capCore.CFrame=CFrame.new(center-Vector3.new(0,h*.08,0))
   capCore.Transparency=.25+.75*math.min(fade*1.4,1)
   local top=center-Vector3.new(0,h*.3,0)
   local thick=3*out3(u/.3)*(1-smooth((el-CLEAR)/.5))
   local length=(top-vents).Magnitude
   if thick>.02 and length>.2 then
    local cf=Kit.LookAt((vents+top)/2,top)*CFrame.Angles(0,math.pi/2,0)
    stem.Size=Vector3.new(length,thick,thick);stem.CFrame=cf;stem.Transparency=.55
    spine.Size=Vector3.new(length,thick*.4,thick*.4);spine.CFrame=cf;spine.Transparency=.15
   else stem.Transparency=1;spine.Transparency=1 end
   for i,p in ipairs(skirt)do
    local a=i/#skirt*math.pi*2+el*.8
    local reach=w*(.42+.25*fade)
    p.Size=Vector3.one*math.max(w*.3,.2)
    p.CFrame=CFrame.new(center+Vector3.new(math.cos(a)*reach,-h*.22,math.sin(a)*reach))
    p.Transparency=.45+.55*fade
   end
   capLight.Brightness=(5*smooth(u/.2)+4*flare)*(1-fade)
   cleared=fade>=1
  end
  for _,pd in ipairs(puddles)do
   local age=el-pd.Born
   if age<0 then pd.Part.Transparency=1
   else
    local d=math.max(pd.D*backOut(age/.25),.05)
    pd.Part.Size=Vector3.new(.05,d,d)
    pd.Part.Transparency=.1+.9*smooth((age-.3)/2.5)
   end
  end
  return true
 end)

 -- 0: the counter starts; the rings and the plate come up.
 if fresh(0)then Kit.Cue('Glitch',core,.18)end
 -- 1.2 Radiation_Cloud: the reactor lights, sparks rush in, it trembles.
 if not ctx:Wait(CHARGE)then return end
 hl=scope:Highlight(model,GREEN,GREEN,1,1)
 inward.Rate=low and 18 or 70
 vent(low and 5 or 14)
 Kit.Tween(grade,.4,{Brightness=-.05,Contrast=.12,TintColor=C(226,255,212)})
 if fresh(CHARGE)then Kit.Cue('Whoosh',core,.55);Kit.Cue('Glitch',core,.22)end

 -- 1.6: criticality.
 if not ctx:Wait(BOOM)then return end
 inward.Rate=0
 smoke.Rate=low and 15 or 60;sparks.Rate=low and 5 or 20
 vent(low and 3 or 9)
 local reach=Kit.Near(origin,160)
 if fresh(BOOM)then
  local n=Kit.Near(origin,120)
  Kit.Cue('Impact',nil,.6+.4*Kit.Near(origin,220))
  task.delay(.06,function()if scope.Alive then Kit.Cue('Sting',nil,.5)end end)
  if n>.05 then
   Kit.Flash(C(230,255,205),1-.55*n,.55)
   Kit.Shake(.3*n,.8)
   if n>.2 then Kit.FOVPunch(5*n,.08,.9)end
  end
  grade.Brightness=.28*reach
  scope:Ring(origin+Vector3.new(0,.3,0),GREEN,1.5,SHOCK,.9,{Thickness=.5,Segments=24})
  scope:Burst(origin+Vector3.new(0,.4,0),C(170,235,120),18,{Texture=Kit.Textures.Smoke,LightEmission=.2,Drag=4,
   Speed=NumberRange.new(8,16),SpreadAngle=Vector2.new(85,85),Lifetime=NumberRange.new(.6,1),
   Size=NumberSequence.new(1.5,4.5),Transparency=NumberSequence.new(.4,1)})
 end
 Kit.Tween(grade,.7,{Brightness=0,Contrast=.08,Saturation=.2,TintColor=WHITE:Lerp(C(200,255,170),.35+.65*reach)})
 local drone=ctx:Elapsed()<CLEAR and scope:Drone('Drone',low and .2 or .3,.3,.25)or nil
 -- The fallout runs down the tongue's warm edges, from the stage outward (in the open it
 -- reaches the runes as the shockwave passes them).
 for _,g in ipairs(guides)do
  local at=BOOM+math.abs(g.Position.Z-origin.Z)/55
  task.delay(math.max(0,at-ctx:Elapsed()),function()
   if not scope.Alive or not g.Parent then return end
   tint(g,{Color=GREEN});g.Color=PALE;ease(g,.5,{Color=GREEN})
  end)
 end
 for _,rune in ipairs(toxic)do
  task.delay(math.max(0,BOOM+11/55-ctx:Elapsed()),function()
   if not scope.Alive or not rune.Part.Parent then return end
   rune.Part.Color=PALE;Kit.Tween(rune.Part,.5,{Color=GREEN})
   if rune.Lamp then rune.Lamp.Brightness=3;Kit.Tween(rune.Lamp,.6,{Brightness=1.2})end
  end)
 end
 -- 1.9: a condensation ring rolls out under the cap.
 if not ctx:Wait(1.9)then return end
 if fresh(1.9)and not low then
  local xz=capXZ or origin
  scope:Ring(Vector3.new(xz.X,origin.Y+ROLL,xz.Z),PALE,3,12.5,1.4,{Thickness=.3,Alpha=.45,Segments=20})
  Kit.Cue('Whoosh',nil,.3)
 end
 if not ctx:Wait(3)then return end
 fallout.Rate=low and 4 or 16
 if not ctx:Wait(3.6)then return end
 smoke.Rate=0;sparks.Rate=0

 -- 4.2 Result_Success: the cloud lets go, the rings drop, puddles splash down, the card.
 if not ctx:Wait(CLEAR)then return end
 ctx.WhisperStyle={Font=Enum.Font.RobotoMono,Color=C(228,255,206),Glitch=.015,Chroma=false,Shake=false,Type=.035}
 ctx:Title({Font=Enum.Font.Bangers,Hold=3.6})
 vent(low and 1 or 3)
 Kit.Tween(grade,1.4,{Brightness=0,Contrast=0,Saturation=0,TintColor=WHITE},Enum.EasingStyle.Sine)
 if drone then Kit.Tween(drone,1.6,{Volume=0})end
 local splashes=low and 3 or 6
 for k=1,splashes do
  local a=k/splashes*math.pi*2+Kit.Random(-.35,.35)
  local at=settle(origin+Vector3.new(math.cos(a),0,math.sin(a))*Kit.Random(3.4,6.4))+Vector3.new(0,.17,0)
  table.insert(puddles,{Born=CLEAR+.07*k+Kit.Random(0,.05),D=Kit.Random(1.5,2.5),Part=scope:Part({Name='Puddle',
   Shape=Enum.PartType.Cylinder,Color=TOXIC,Transparency=1,Size=Vector3.one*.05,CFrame=CFrame.new(at)*CFrame.Angles(0,0,math.pi/2)})})
 end
 if fresh(CLEAR)then
  Kit.Cue('Chime',nil,.45)
  scope:Burst(core.Position,GREEN,30,{Speed=NumberRange.new(6,12),Lifetime=NumberRange.new(.5,1),Drag=2,Size=NumberSequence.new(.5,0)})
 end
 if not ctx:Wait(4.4)then return end
 fallout.Rate=0
 -- The mouth eases back to its own colours as it sets off (in the open our runes, lamps
 -- and haze burn out).
 if not ctx:Wait(hold-.8)then return end
 for _,r in ipairs(restore)do if r[1].Parent then ease(r[1],.8,r[2])end end
 for _,rune in ipairs(toxic)do
  if rune.Part.Parent then Kit.Tween(rune.Part,.8,{Transparency=1})end
  if rune.Lamp then Kit.Tween(rune.Lamp,.8,{Brightness=0})end
 end
 if haze then haze.Rate=0 end
 vent(0)
 if not ctx:Wait(hold)then return end
 -- It walks (on a pad it stays); the puddles fade out.
 ctx:Wait(hold+.8)
end
