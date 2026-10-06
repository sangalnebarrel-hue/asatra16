-- NUCLEAR PUG, "CRITICALITY". The whole island goes critical before the pug does. A Geiger
-- counter starts clicking for every player and will not stop, a radiation alert crosses
-- every screen (saying where, and who set it off), the sky curdles a sickly green, every
-- light in the district turns green (and the giant head's eyes), radioactive motes rise
-- around every player, a colossal radiation trefoil assembles in the sky (out in front of the
-- giant head on the tongue), every dog on the island looks up at it and a countdown runs on
-- every screen: 5 at 1.6 ... 0 at 6.6. At 4.4 every camera is pulled to the stage. At 5 the
-- pug appears in a hiss of steam and the stage act plays as before, 5 s later: a hazard plate
-- lights under it, three hazard rings lift off the belt and spin faster with the clicks, the
-- mouth's runes glow toxic. At 6.2 the reactor on its back lights, green sparks rush into it,
-- a beam of green light punches out of it into the sky and the trefoil spins up and implodes.
-- 6.6, ZERO: every screen goes white, every light dies, a shockwave and a mushroom cloud fill
-- the mouth (up to its roof) while a colossal fireball bursts out of the stage and climbs
-- into a mushroom cloud ~300 studs high, seen from every yard; a blast wave (a shimmering
-- dome, a bright ring on the ground) races across the whole district and shakes each player
-- as it passes them, every dog flinches and looks up at the cloud, the tongue's edges turn
-- green down the line, green fallout rains on every player and a ghostly giant pug grins out
-- of the cap. 9.2: on the stage the cloud lets go, the rings clatter onto the belt among
-- glowing puddles and the pug and the ghost in the sky celebrate together (the card). From 12
-- the cloud, the fallout and the sky ease back before the hold ends (15). Off the tongue (a
-- Lucky pad, open air) toxic runes stand round the stage instead of the mouth's, a green haze
-- creeps over the ground, the small cloud climbs into the open sky and every map-wide thing
-- (cloud, wave, trefoil, cutaway) is aimed at the stage.
local Players=game:GetService('Players')
local SoundService=game:GetService('SoundService')
local C=Color3.fromRGB
local WHITE,BLACK=Color3.new(1,1,1),Color3.new(0,0,0)
local HAZARD,INK,TOXIC,SOOT,PALE=C(255,214,0),C(26,26,20),C(120,255,60),C(40,90,20),C(222,255,190)
-- The colossal cloud's shell, its rolling rim and cooled crown, the dust at its foot.
local CLOUD,CURL,CROWN,DUST=C(104,214,52),C(84,150,46),C(64,118,38),C(132,152,108)
local TICK='rbxasset://sounds/volume_slider.ogg'
-- The map-wide build-up runs PRE seconds before the stage act (whose t=0 it was); then the
-- stage act's beats: the reactor lights, criticality, the cloud lets go.
local PRE=5
local CHARGE,BOOM,CLEAR=PRE+1.2,PRE+1.6,PRE+4.2
-- The trefoil assembles, the countdown shows 5 (a number a second, 0 at the blast), the
-- cutaway's first shot, the ghost pug fades in inside the cap.
local SIGN,COUNT,CUT,GHOST=1.2,BOOM-5,PRE-.6,BOOM+2
-- The blast wave crosses the district in WAVE_T seconds. The trefoil hangs LIFT over the
-- stage (on the tongue AHEAD studs out in front of the giant head, in open sky, where the
-- yards look); R0 is its centre disc's radius and the blades run from 1.5x to 5x it, as on
-- the real sign. BEAM: the reactor's beam into the sky.
local WAVE_T,LIFT,AHEAD,R0,BEAM=6,125,50,11,700
-- The hazard rings: resting height above the belt and spin direction.
local RINGS={{.25,1},{3,-1},{6,1}}
local BONES={'Vent_L','Vent_R','Body'}
local UPRIGHT=CFrame.Angles(0,0,math.pi/2)    -- a cylinder's axis (its X) pointing up
local FACING=CFrame.Angles(0,math.pi/2,0)     -- ... pointing along a frame's look
local function smooth(x)x=math.clamp(x,0,1);return x*x*(3-2*x)end
local function out3(x)x=math.clamp(x,0,1);return 1-(1-x)^3 end
local function backOut(x)x=math.clamp(x,0,1)-1;local c=1.70158;return 1+(c+1)*x*x*x+c*x*x end
-- Transparency a, faded toward invisible by f.
local function veil(a,f)return math.min(1,a+(1-a)*f)end
local function curve(points)
 local k={}
 for i,p in ipairs(points)do k[i]=NumberSequenceKeypoint.new(p[1],p[2])end
 return NumberSequence.new(k)
end
local function setSkin(s,strength,tint)s.EmissiveStrength=strength;s.EmissiveTint=tint end
-- Geiger clicks a second at t: 1 → 5 through the countdown, → 20 as the stage act charges, a
-- crackle into the blast, then thinning.
local function rate(t)
 if t<PRE then return 5^(t/PRE)end
 if t<CHARGE then return 5*4^((t-PRE)/(CHARGE-PRE))end
 if t<BOOM then return 20+12*(t-CHARGE)/(BOOM-CHARGE)end
 if t<CLEAR then return 3+11*math.exp(-(t-BOOM)*1.1)end
 return 1.6
end
-- The colossal cloud u seconds after the blast: the cap's height over the stage, its radius
-- and half-height. A fireball swelling on the ground first, then it climbs (fast, then
-- slower) and flattens into a cap.
local function capAt(u)
 local r=u<.5 and 48*out3(u/.5)or 48+62*out3((u-.5)/3.6)
 local x=math.clamp((u-.2)/4.4,0,1)
 local h=22+210*(1-(1-x)^2)
 if u<.5 then h=math.min(h,4+r*.4)end
 return h,r,r*(.62-.14*x)
end
-- The island's sky: curdling through the countdown, the blast's white-out, then a poisoned
-- dusk the cloud glows in. scope:Sky eases between them (and back after). The haze stays
-- thin (Density): the cloud must still read from the far north, ~800 studs away.
local SKY_DOOM={
 Lighting={ClockTime=17.3,Brightness=1.6,ExposureCompensation=-.1,Ambient=C(84,104,70),OutdoorAmbient=C(120,150,96)},
 Atmosphere={Density=.24,Offset=.08,Color=C(168,214,118),Decay=C(74,104,40),Glare=.6,Haze=2.2},
 Clouds={Cover=.72,Density=.55,Color=C(160,204,110)},
 Grade={TintColor=C(228,255,208),Saturation=-.08,Contrast=.1,Brightness=0},
 Bloom={Intensity=.35,Size=30,Threshold=1.5},
}
local SKY_FLASH={Lighting={ExposureCompensation=2.2,Brightness=5},Grade={TintColor=WHITE,Brightness=.3},Bloom={Intensity=1.5,Threshold=.8}}
local SKY_GLARE={Lighting={ExposureCompensation=.9,Brightness=3},Grade={TintColor=WHITE,Brightness=.1},Bloom={Intensity=.8,Threshold=1.1}}
local SKY_FALLOUT={
 Lighting={ClockTime=18.3,Brightness=1.2,ExposureCompensation=-.25,Ambient=C(70,96,56),OutdoorAmbient=C(104,140,80)},
 Atmosphere={Density=.3,Offset=.1,Color=C(140,206,90),Decay=C(54,84,28),Glare=1.2,Haze=3},
 Clouds={Cover=.84,Density=.7,Color=C(120,170,80)},
 Grade={TintColor=C(216,255,190),Saturation=-.12,Contrast=.18,Brightness=0},
 Bloom={Intensity=.6,Size=36,Threshold=1.2},
}

return function(ctx)
 -- Our own alert (it says where and who set it off); set before the first yield.
 ctx.ManualBanner=true
 ctx.WhisperStyle={Font=Enum.Font.RobotoMono,Color=C(196,255,150),Glitch=.05,Chroma=false,Shake=false,Type=.04}
 local Kit,scope,model,config=ctx.Kit,ctx.Scope,ctx.Model,ctx.Config
 local low,calm,hold,origin=ctx.Low,Kit.ReducedMotion(),config.Hold,ctx.Origin
 local GREEN=config.Color
 local size=Kit.Size(model)
 local joined=ctx:Elapsed()
 -- The sky, the cloud and the fallout ease back over the last 3 s of the hold.
 local FADE=hold-3
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
 -- the cap at BOOM+.3; SHOCK: the blast's reach (the mouth's walls are at x=±15.5).
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
 -- The stage's own grade: only the near players' punch (the island's tint is the sky's).
 local grade=scope:Grade({Brightness=0},.2)
 -- The reactor core rides its Body bone: the dog's light lives here (lights and emitters
 -- parented under the district get throttled).
 local core=scope:Anchor(origin+Vector3.new(0,size.Y*.45,0),'Reactor')
 local glow=scope:Light(core,GREEN,20,0)
 -- The Geiger counter every player hears (2D, wherever they are).
 local clicks={}
 for i=1,low and 3 or 5 do
  local s=Instance.new('Sound');s.Name='Geiger';s.SoundId=TICK;s.Volume=0
  local eq=Instance.new('EqualizerSoundEffect');eq.LowGain=-14;eq.MidGain=2;eq.HighGain=4;eq.Parent=s
  local grit=Instance.new('DistortionSoundEffect');grit.Level=.55;grit.Parent=s
  s.Parent=SoundService;scope:Add(s);clicks[i]=s
 end
 -- A pooled click (no new sounds per click); every click also kicks the glow.
 local turn,kick=0,0
 local function click(volume:number,speed:number?)
  turn=turn%#clicks+1
  local s=clicks[turn]
  s.Volume=volume;s.PlaybackSpeed=speed or Kit.Random(2.5,3.6);s.TimePosition=0;s:Play()
  kick=1
 end

 -- The edges of every screen glow green, building with the countdown.
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
 -- On the tongue the giant head's irises curdle green with the sky (seen from every yard).
 local irises:{BasePart}={}
 local head=factory and factory:FindFirstChild('THE_DOG')
 for _,o in ipairs(head and head:GetChildren()or {})do
  if o.Name=='WarmIris'and o:IsA('BasePart')then table.insert(irises,o)end
 end
 local irisColor=#irises>0 and irises[1].Color or BLACK
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
 -- The cloud in the mouth: an ellipsoid cap with a hot core on a glowing stem, a rolling
 -- skirt below it. (blob also makes the colossal cloud's parts.)
 local function blob(name,color,material:Enum.Material?)
  local p=scope:Part({Name=name,Color=color,Transparency=1,Size=Vector3.one,Material=material or Enum.Material.Neon})
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

 -- Its own skin: the reactor pieces burn green from the charge, everything flares at the blast.
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
 -- Hidden through the build-up: it appears at PRE (in a hiss of steam).
 local vis=joined<PRE and scope:Visibility(model)or nil
 if vis then vis.Set(1)end

 ---------------------------------------------------------------- over the whole island
 -- Where the stage faces (down the line on the tongue): the cutaway and the ghost's fallback.
 local function front():Vector3
  local f=frame().LookVector
  local flat=Vector3.new(f.X,0,f.Z)
  return flat.Magnitude>.1 and flat.Unit or Vector3.zAxis
 end
 -- The trefoil: a centre disc and three blades of radial bars (two up, one down) in its own
 -- plane, turned to this camera every frame and spun about its face.
 local signAt=origin+(onTongue and front()*AHEAD or Vector3.zero)+Vector3.new(0,LIFT,0)
 local signParts:{BasePart}={}
 local signLayout={}
 local signCF:{CFrame}={}
 do
  local r1,r2=1.5*R0,5*R0
  local bars=low and {-1,0,1}or {-2,-1,0,1,2}
  local step=math.rad(low and 18 or 12)
  for b=0,2 do
   for _,k in ipairs(bars)do
    table.insert(signLayout,{Angle=math.rad(30+b*120)+k*step,Mid=(r1+r2)/2,Born=SIGN+b*.18,Disc=false})
    table.insert(signParts,scope:Part({Name='SkySign',Color=HAZARD,Transparency=1,Size=Vector3.new(r2-r1,(low and .33 or .22)*r2,2)}))
   end
  end
  table.insert(signLayout,{Angle=0,Mid=0,Born=SIGN+.54,Disc=true})
  table.insert(signParts,scope:Part({Name='SkySignCore',Shape=Enum.PartType.Cylinder,Color=HAZARD,Transparency=1,Size=Vector3.new(2,2*R0,2*R0)}))
 end
 -- The reactor's beam: out of the vents on its back straight up into the sky while it
 -- charges (through the mouth's roof and out of the giant head on the tongue). ventAt is
 -- kept by the stage act's step.
 local ventAt=origin+Vector3.new(0,size.Y,0)
 local beam=scope:Part({Name='Beam',Shape=Enum.PartType.Cylinder,Color=TOXIC,Transparency=1,Size=Vector3.new(BEAM,1,1)})
 local beamCore=scope:Part({Name='BeamCore',Shape=Enum.PartType.Cylinder,Color=PALE,Transparency=1,Size=Vector3.new(BEAM,.5,.5)})
 -- The colossal cloud: a glowing shell and heart for the cap, a matte crown and a rolling rim,
 -- a stem (hot pith inside), swells along it and the dust at its foot. Posed every frame from
 -- capAt with one BulkMoveTo; the low tier keeps a third.
 local shell,heart=blob('CloudShell',PALE),blob('CloudHeart',WHITE)
 local column=scope:Part({Name='CloudStem',Shape=Enum.PartType.Cylinder,Material=Enum.Material.SmoothPlastic,Color=CLOUD,Transparency=1,Size=Vector3.one})
 local pith=scope:Part({Name='CloudPith',Shape=Enum.PartType.Cylinder,Color=PALE,Transparency=1,Size=Vector3.one})
 local cloudParts:{BasePart}={shell,heart,column,pith}
 local crown=not low and blob('CloudCrown',CROWN,Enum.Material.SmoothPlastic)or nil
 local foot=not low and blob('CloudFoot',DUST,Enum.Material.SmoothPlastic)or nil
 if crown then table.insert(cloudParts,crown)end
 if foot then table.insert(cloudParts,foot)end
 local billows,rim={},{}
 for k=1,low and 0 or 3 do billows[k]=blob('CloudSwell',CLOUD,Enum.Material.SmoothPlastic);table.insert(cloudParts,billows[k])end
 for k=1,low and 4 or 10 do rim[k]=blob('CloudRoll',CURL,Enum.Material.SmoothPlastic);table.insert(cloudParts,rim[k])end
 local cloudCF:{CFrame}={}
 local cloudTop=origin+Vector3.new(0,22,0)
 local base=scope:Anchor(origin+Vector3.new(0,3,0),'CloudFoot')
 local blastLight=scope:Light(base,TOXIC,60,0)
 local plume=scope:Emitter(shell,{Texture=Kit.Textures.Smoke,Color=ColorSequence.new(CLOUD,C(58,104,34)),LightEmission=.25,LightInfluence=.6,
  Shape=Enum.ParticleEmitterShape.Sphere,Lifetime=NumberRange.new(3,5),Speed=NumberRange.new(2,7),Drag=.6,
  Size=curve({{0,30},{1,70}}),Transparency=curve({{0,1},{.15,.45},{.7,.6},{1,1}}),Rotation=NumberRange.new(0,360),RotSpeed=NumberRange.new(-12,12)})
 local chimney=scope:Emitter(column,{Texture=Kit.Textures.Smoke,Color=ColorSequence.new(CLOUD,DUST),LightEmission=.15,LightInfluence=.8,
  Shape=Enum.ParticleEmitterShape.Box,Lifetime=NumberRange.new(2.5,4),Speed=NumberRange.new(2,6),Acceleration=Vector3.new(0,6,0),
  Size=curve({{0,16},{1,36}}),Transparency=curve({{0,1},{.2,.5},{1,1}}),Rotation=NumberRange.new(0,360),RotSpeed=NumberRange.new(-15,15)})
 local surge=scope:Emitter(base,{Texture=Kit.Textures.Smoke,Color=ColorSequence.new(DUST,C(96,112,80)),LightEmission=0,LightInfluence=1,
  EmissionDirection=Enum.NormalId.Top,SpreadAngle=Vector2.new(80,80),Speed=NumberRange.new(30,70),Drag=1.4,
  Acceleration=Vector3.new(0,-4,0),Lifetime=NumberRange.new(2.5,3.5),Size=curve({{0,14},{1,40}}),
  Transparency=curve({{0,.35},{1,1}}),Rotation=NumberRange.new(0,360),RotSpeed=NumberRange.new(-20,20)})
 -- The blast wave: a shimmering dome and a bright ring on the ground racing from the stage
 -- to the far end of the district (both inside WAVE studs).
 local span=0
 for _,x in ipairs({Kit.Map.Min.X,Kit.Map.Max.X})do
  for _,z in ipairs({Kit.Map.Min.Z,Kit.Map.Max.Z})do span=math.max(span,Vector3.new(x-origin.X,0,z-origin.Z).Magnitude)end
 end
 local WAVE=math.clamp(span+60,300,1000)
 local function wave(u:number):number
  local a=math.clamp(u/WAVE_T,0,1)
  return 8+(WAVE-8)*(1-(1-a)^2)
 end
 local dome=scope:Part({Name='BlastWave',Shape=Enum.PartType.Ball,Material=Enum.Material.ForceField,Color=PALE,Transparency=1,
  Size=Vector3.one*16,CFrame=CFrame.new(origin)})
 local segments=low and 14 or 32
 local fronts:{BasePart}={}
 local frontTurn:{CFrame}={}
 local frontCF:{CFrame}={}
 for i=1,segments do
  local a=(i-.5)/segments*math.pi*2
  frontTurn[i]=CFrame.fromMatrix(Vector3.zero,Vector3.new(math.cos(a),0,math.sin(a)),Vector3.yAxis)
  fronts[i]=scope:Part({Name='BlastFront',Color=PALE,Transparency=1,Size=Vector3.new(3,7,1)})
 end

 -- The countdown on every screen: CRITICALITY IN, the number, a dose climbing off the scale.
 local counter:Frame?,counterPop:UIScale?,counterEdge:UIStroke?=nil,nil,nil
 local digit:TextLabel?,dose:TextLabel?=nil,nil
 local counterText:{TextLabel}={}
 if playerGui and joined<BOOM then
  local gui=Instance.new('ScreenGui');gui.Name='DOGROTS_NuclearPugCountdown';gui.ResetOnSpawn=false
  gui.IgnoreGuiInset=true;gui.DisplayOrder=95
  -- (A second pug going critical at the same time counts down under the first.)
  local below=playerGui:FindFirstChild('DOGROTS_NuclearPugCountdown')~=nil
  local box=Instance.new('Frame');box.Name='Countdown';box.AnchorPoint=Vector2.new(.5,.5);box.Position=UDim2.fromScale(.5,below and .86 or .7)
  box.Size=UDim2.fromOffset(250,122);box.BackgroundColor3=C(6,14,4);box.BackgroundTransparency=1;box.BorderSizePixel=0;box.Parent=gui
  local corner=Instance.new('UICorner');corner.CornerRadius=UDim.new(0,10);corner.Parent=box
  local edge=Instance.new('UIStroke');edge.Color=HAZARD;edge.Thickness=2;edge.Transparency=1;edge.Parent=box
  local pop=Instance.new('UIScale');pop.Parent=box
  -- KeepFont before parenting, or the place's typography swaps the face.
  local function text(name:string,font:Enum.Font,color:Color3,y:number,h:number,value:string):TextLabel
   local l=Instance.new('TextLabel');l.Name=name;l:SetAttribute('KeepFont',true)
   l.BackgroundTransparency=1;l.AnchorPoint=Vector2.new(.5,0);l.Position=UDim2.fromScale(.5,y);l.Size=UDim2.fromScale(.92,h)
   l.Font=font;l.TextScaled=true;l.TextColor3=color;l.TextStrokeColor3=C(4,10,2);l.TextStrokeTransparency=1
   l.TextTransparency=1;l.Text=value;l.Parent=box
   table.insert(counterText,l)
   return l
  end
  text('Kicker',Enum.Font.RobotoMono,HAZARD,.05,.17,'☢ CRITICALITY IN ☢')
  digit=text('Digit',Enum.Font.Bangers,GREEN,.2,.58,'5')
  dose=text('Dose',Enum.Font.RobotoMono,PALE,.79,.15,'DOSE 0.05 Sv/h')
  gui.Parent=playerGui
  scope:Add(gui)
  counter,counterPop,counterEdge=box,pop,edge
 end
 -- The countdown's pip (higher each number; a double pip on 1).
 local function pip(n:number)
  local function one()
   Kit.Shot(nil,TICK,.5,2.6+(5-n)*.25,{EqualizerSoundEffect={LowGain=-22,MidGain=4,HighGain=0},ReverbSoundEffect={DecayTime=1.2,WetLevel=-9}})
  end
  one()
  if n==1 then task.delay(.16,function()if scope.Alive then one()end end)end
 end
 -- The blast wave reaching you: a whoomp and a thud.
 local function thump(volume:number)
  Kit.Cue('Whoosh',nil,volume*.8)
  Kit.Shot(nil,TICK,volume,.1,{EqualizerSoundEffect={LowGain=10,MidGain=-4,HighGain=-30},DistortionSoundEffect={Level=.5},
   ReverbSoundEffect={DecayTime=3,WetLevel=-4,DryLevel=0,Density=1,Diffusion=1}})
 end

 -- The island turns: a sickly green sky for this player wherever they are, a low drone under
 -- the music, motes rising off the ground around them.
 local sky=scope:Sky(SKY_DOOM,math.max(.4,3-joined),3)
 local drone=scope:Drone('Drone',low and .14 or .2,.5,math.max(.5,2.5-joined))
 local motes=scope:Rain({Texture=Kit.Textures.Spark,Color=ColorSequence.new(GREEN,PALE),LightEmission=1,
  Size=curve({{0,0},{.2,.32},{1,0}}),Transparency=NumberSequence.new(.1,.6),Speed=NumberRange.new(1.5,4),
  Lifetime=NumberRange.new(3,4.5),SpreadAngle=Vector2.new(25,25),Acceleration=Vector3.new(0,1.5,0),
  EmissionDirection=Enum.NormalId.Top,Rate=26,Area=110,Height=-16})
 local moteRate=motes.Rate
 local rainGlow:ParticleEmitter?,rainAsh:ParticleEmitter?=nil,nil
 local glowRate,ashRate=0,0
 local cutaway=nil
 local glance=nil
 local ghost=nil
 local ghostFace=Vector3.zAxis

 local lookup,nextClick=0,math.max(joined,0)
 local capXZ:Vector3?=nil
 local cleared=false
 -- It trembles while it charges (local only, about its own feet).
 local shiver=(not calm and joined<BOOM)and scope:Offset(model)or nil
 local hl:Highlight?=nil
 local puddles={}
 -- The countdown's pulse (1 on each number, decaying), its number and its dose clock.
 local beat,shown,doseAt,counterAlpha=0,-1,0,-1
 local signSpin,signHot,signDone,beamDone=0,false,false,false
 local cloudDone,cloudCooled,waveDone,hitCam,hitMe=false,false,false,false,false
 local function poseRing(i,ring,el,dt)
  local t0=PRE+.1+(i-1)*.15
  local k=(el-t0)/.5
  local show=smooth((el-t0)/.35)
  local r=9.5-2.5*out3(k)-1.6*smooth((el-CHARGE)/(BOOM-CHARGE))+3.1*out3((el-BOOM)/.35)
  local h=.25+(ring.Height-.25)*backOut(k)
  local spin,tilt,fade=.8+2.7*smooth((el-PRE)/(BOOM-PRE)),0,0
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

 -- The stage act (as before, PRE seconds later).
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
  ventAt=vents
  core.CFrame=CFrame.new(bone('Body')or f:PointToWorldSpace(Vector3.new(0,size.Y*.45,0)))
  jets[1].CFrame=CFrame.new(ventL);jets[2].CFrame=CFrame.new(ventR)
  well.CFrame=CFrame.new(vents-Vector3.new(0,1.2,0))

  -- The Geiger counter: irregular clicks at rate(t), at most two a frame.
  if nextClick<el-.25 then nextClick=el end
  local n=0
  while nextClick<=el and n<2 do
   n+=1
   click(el<CLEAR and .3+.22*math.min(rate(el)/30,1)or .16)
   nextClick+=Kit.Random(.45,1.55)/rate(nextClick)
  end
  local pop=calm and 0 or kick
  kick*=math.exp(-dt*16)
  local charge=smooth((el-CHARGE)/.25)
  local flare=el>=BOOM and math.exp(-(el-BOOM)*2.2)or 0
  local done=smooth((el-CLEAR)/1)
  local out=1-smooth((el-hold+.8)/.8)
  -- It appears at PRE.
  if vis and el>=PRE then
   local v=1-smooth((el-PRE)/.3)
   vis.Set(v)
   if v<=0 then vis=nil end
  end

  -- The light on the dog: a 3 Hz pulse that builds, faster while charging, then the blast
  -- (before it appears, only the clicks flicker in the empty stage).
  local level
  if el<CHARGE then level=6*smooth((el-PRE)/(CHARGE-PRE))*(calm and .7 or .55+.45*math.sin(el*math.pi*6))
  elseif el<BOOM then level=6*(calm and .85 or .6+.4*math.sin(el*math.pi*12))
  else level=(2.5+9*flare)*(1-.6*done)end
  glow.Brightness=(level+1.5*pop)*out
  if #edges>0 then
   local a
   if el<PRE then a=.04+.18*smooth(el/PRE)
   elseif el<CHARGE then a=.22+.04*smooth((el-PRE)/(CHARGE-PRE))
   elseif el<BOOM then a=.26+.1*charge
   else a=.2+.35*flare end
   a=(a+.06*pop+.1*beat)*(1-done)
   local color=GREEN:Lerp(PALE,math.max(flare*.6,beat*.4))
   for _,e in ipairs(edges)do e.BackgroundTransparency=1-a;e.BackgroundColor3=color end
  end
  for i,ring in ipairs(rings)do poseRing(i,ring,el,dt)end
  if #plate>0 then
   local vis=smooth((el-PRE-.05)/.5)*(1-smooth((el-CLEAR-.6)/.9))
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

  -- The mushroom cloud in the mouth: out of the vents at the blast, up to just under the
  -- roof (y 23.5), or in the open straight up over the stage to its virtual ceiling.
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

 -- The map-wide act: the countdown, the head's eyes, the trefoil and the beam, the colossal
 -- cloud, the blast wave reaching each player, the motes and the fallout.
 scope:Every(function(dt)
  local el=ctx:Elapsed()
  local cam=workspace.CurrentCamera
  local eye=cam and cam.CFrame.Position or origin
  beat*=math.exp(-dt*5)
  if counter and counterPop and counterEdge and digit and dose and el<BOOM+1.8 then
   local a=smooth((el-COUNT+.35)/.35)*(1-smooth((el-BOOM-1.1)/.6))
   if a~=counterAlpha then
    counterAlpha=a
    counter.BackgroundTransparency=1-.45*a;counterEdge.Transparency=1-a
    for _,l in ipairs(counterText)do l.TextTransparency=1-a;l.TextStrokeTransparency=1-.7*a end
   end
   if el>=COUNT and el<BOOM then
    local number=math.clamp(math.ceil(BOOM-el),1,5)
    if number~=shown then
     shown=number;digit.Text=tostring(number)
     if fresh(BOOM-number)then
      beat=calm and 0 or 1
      pip(number)
     end
    end
    if os.clock()>=doseAt then
     doseAt=os.clock()+.08
     local d=.05*10^(el*.8)
     dose.Text=d<10 and string.format('DOSE %.2f Sv/h',d)or d<100 and string.format('DOSE %.1f Sv/h',d)
      or string.format('DOSE %d Sv/h',math.floor(d))
    end
   elseif el>=BOOM and shown~=0 then
    shown=0;digit.Text='CRITICAL';dose.Text='DOSE: YES'
    beat=calm and 0 or 1
   end
   counterPop.Scale=1+.4*beat
   digit.TextColor3=GREEN:Lerp(PALE,beat)
  end
  -- The giant head's irises curdle green with the countdown, white-hot at the blast.
  if #irises>0 and el>=.8 and el<hold-.8 then
   local c=irisColor:Lerp(TOXIC,smooth((el-.8)/2.5))
   if el>=BOOM then c=TOXIC:Lerp(PALE,math.exp(-(el-BOOM)*1.8))end
   c=c:Lerp(PALE,beat*.5)
   for _,p in ipairs(irises)do p.Color=c end
  end

  -- The trefoil: its blades fly in one by one, it turns to this camera, spins up as the
  -- reactor charges and implodes into the blast.
  if not signDone and el>=SIGN then
   if el>=BOOM+.05 then
    signDone=true
    for _,p in ipairs(signParts)do p.Transparency=1 end
   else
    signSpin+=dt*(.35+8*smooth((el-CHARGE)/(BOOM-CHARGE)))
    local face=Kit.LookAt(signAt,eye)*CFrame.Angles(0,0,signSpin)
    local crush=1-out3((el-BOOM+.2)/.2)
    local gone=1-smooth((el-BOOM+.1)/.1)
    local pulse=calm and 0 or math.max(beat,kick*.5)
    local heat=smooth((el-CHARGE)/.3)
    local recolour=heat>0 and not signHot
    for i,lay in ipairs(signLayout)do
     if lay.Disc then signCF[i]=face*FACING
     else
      local k=(1+1.4*(1-out3((el-lay.Born)/.6)))*crush
      signCF[i]=face*CFrame.Angles(0,0,lay.Angle)*CFrame.new(lay.Mid*k,0,0)
     end
     local p=signParts[i]
     p.Transparency=1-smooth((el-lay.Born)/.45)*gone*(.8+.18*pulse)
     if recolour then p.Color=HAZARD:Lerp(PALE,heat)end
    end
    if heat>=1 then signHot=true end
    workspace:BulkMoveTo(signParts,signCF,Enum.BulkMoveMode.FireCFrameChanged)
   end
  end
  -- The beam: out of the reactor into the sky from the charge to the blast.
  if not beamDone and el>=CHARGE-.02 then
   if el>=BOOM+.05 then
    beamDone=true;beam.Transparency=1;beamCore.Transparency=1
   else
    local g=out3((el-CHARGE)/.18)*(calm and 1 or .82+.18*math.sin(el*55))
    local cf=CFrame.new(ventAt+Vector3.new(0,BEAM/2,0))*UPRIGHT
    beam.Size=Vector3.new(BEAM,1+5*g,1+5*g);beam.CFrame=cf;beam.Transparency=1-.55*g
    beamCore.Size=Vector3.new(BEAM,.4+1.8*g,.4+1.8*g);beamCore.CFrame=cf;beamCore.Transparency=1-.92*g
   end
  end

  if el>=BOOM then
   local u=el-BOOM
   -- The colossal cloud.
   if not cloudDone then
    local h,r,v=capAt(u)
    r*=1+.15*smooth((u-4.8)/3)
    local fade=smooth((el-FADE+.6)/2.6)
    local thin=smooth((el-FADE+1)/2.4)
    local heat=math.exp(-u*1.1)
    local c=origin+Vector3.new(0,h,0)
    cloudTop=c
    r=math.max(r,.5);v=math.max(v,.5)
    local top=h-v*.6
    local rs=8+14*out3(u/1.5)
    local stemCF=CFrame.new(origin+Vector3.new(0,math.max(top,.5)/2,0))*UPRIGHT
    -- The stem shows once the fireball has lifted off the ground.
    local standing=top>6
    cloudCF[1]=CFrame.new(c)
    shell.Size=Vector3.new(2*r,2*v,2*r);shell.Transparency=veil(.4+.18*smooth((u-1.6)/1.5),fade)
    cloudCF[2]=CFrame.new(c-Vector3.new(0,v*.1,0))
    heart.Size=Vector3.new(1.2*r,1.1*v,1.2*r);heart.Transparency=veil(.1+.6*(1-heat),fade)
    cloudCF[3]=stemCF;cloudCF[4]=stemCF
    column.Size=Vector3.new(math.max(top,.5),2*rs,2*rs);column.Transparency=standing and veil(.45,thin)or 1
    pith.Size=Vector3.new(math.max(top,.5),.8*rs,.8*rs);pith.Transparency=standing and veil(.25+.5*(1-heat),thin)or 1
    local n=4
    if not cloudCooled then
     shell.Color=PALE:Lerp(CLOUD,smooth(u/1.2))
     heart.Color=u<.6 and WHITE:Lerp(PALE,smooth(u/.6))or PALE:Lerp(TOXIC,smooth((u-.6)/3))
     cloudCooled=u>=3.6
    end
    if crown then
     n+=1;cloudCF[n]=CFrame.new(c+Vector3.new(0,v*.38,0))
     -- It thins once the ghost is inside, so the ghost shows through.
     crown.Size=Vector3.new(1.55*r,1.05*v,1.55*r);crown.Transparency=veil(.35+.45*smooth((u-1.8)/1.2),fade)
    end
    if foot then
     local rb=20+70*out3(u/1.4)
     n+=1;cloudCF[n]=CFrame.new(origin+Vector3.new(0,rb*.12,0))
     foot.Size=Vector3.new(2*rb,.45*rb,2*rb);foot.Transparency=math.min(1,.45+.55*smooth(u/3.2))
    end
    for k,p in ipairs(billows)do
     n+=1;cloudCF[n]=CFrame.new(origin+Vector3.new(math.sin(el*.7+k*2)*rs*.25,top*(.05+.25*k),math.cos(el*.6+k*2)*rs*.25))
     p.Size=Vector3.new(2.5*rs,1.7*rs,2.5*rs);p.Transparency=standing and veil(.5,thin)or 1
    end
    for k,p in ipairs(rim)do
     local a=k/#rim*math.pi*2+el*.22
     n+=1;cloudCF[n]=CFrame.new(c+Vector3.new(math.cos(a)*r*.8,-v*.38+math.sin(el*1.3+k)*v*.06,math.sin(a)*r*.8))
     p.Size=Vector3.new(.62*r,.9*v,.62*r);p.Transparency=veil(.42,fade)
    end
    workspace:BulkMoveTo(cloudParts,cloudCF,Enum.BulkMoveMode.FireCFrameChanged)
    blastLight.Brightness=10*heat
    if ghost then
     -- The ghost pug rides in the cap, a little forward so it grins out of it.
     ghost:Pose(CFrame.lookAt(c+ghostFace*r*.25,c+ghostFace*(r*.25+1)))
    end
    if fade>=1 then
     cloudDone=true
     for _,p in ipairs(cloudParts)do p.Transparency=1 end
     blastLight.Brightness=0
    end
   end
   -- The blast wave, and what it does to each player as it passes them.
   if not waveDone then
    local r=wave(u)
    local far=(r-8)/(WAVE-8)
    local a=u/WAVE_T
    dome.Size=Vector3.one*(2*r)
    dome.Transparency=math.min(1,.38+.6*far^.6+smooth((a-.85)/.15))
    local width=2*r*math.sin(math.pi/segments)*1.08
    local mid=r*math.cos(math.pi/segments)
    local alpha=math.min(1,.05+.9*far^1.3)
    for i,p in ipairs(fronts)do
     local t=frontTurn[i]
     frontCF[i]=CFrame.new(origin+t.RightVector*mid+Vector3.new(0,2.5,0))*t
     p.Size=Vector3.new(3,7,width);p.Transparency=alpha
    end
    workspace:BulkMoveTo(fronts,frontCF,Enum.BulkMoveMode.FireCFrameChanged)
    -- Watching the cutaway: it hits the camera. Otherwise it hits you.
    local watching=cutaway~=nil and cutaway.Active
    if watching and not hitCam and r>=(eye-origin).Magnitude then
     hitCam=true;cutaway:Shake(.8,.9);thump(.7)
    end
    if not hitMe then
     local me=Kit.Me()
     local away=Vector3.new(me.X-origin.X,0,me.Z-origin.Z)
     local d=away.Magnitude
     if r>=d then
      hitMe=true
      if not watching then
       local k=1-math.clamp(d/WAVE,0,1)
       Kit.Shake(.3+.45*k,1.2)
       Kit.FOVPunch(4+5*k,.05,.8)
       thump(.55+.4*k)
       -- Dust whipped up around this player, blown away from the blast.
       scope:Burst(me+Vector3.new(0,1.5,0),DUST,30,{Texture=Kit.Textures.Smoke,LightEmission=0,LightInfluence=1,
        Speed=NumberRange.new(8,20),SpreadAngle=Vector2.new(70,70),Drag=2.5,Acceleration=(d>1 and away/d or Vector3.zero)*40,
        Lifetime=NumberRange.new(.8,1.5),Size=NumberSequence.new(2,6),Transparency=NumberSequence.new(.35,1)})
      end
     end
    end
    if a>=1 then
     waveDone=true;dome.Transparency=1
     for _,p in ipairs(fronts)do p.Transparency=1 end
    end
   end
  end
  -- Motes rise around you through the countdown; fallout rains on you after the blast.
  if el<BOOM then motes.Rate=moteRate*(.35+.65*smooth(el/PRE))
  elseif motes.Rate>0 then motes.Rate=0 end
  local thinning=1-smooth((el-FADE)/1.5)
  if rainGlow then rainGlow.Rate=glowRate*thinning end
  if rainAsh then rainAsh.Rate=ashRate*thinning end
  return true
 end)

 -- 0: the counter starts clicking for everyone.
 -- .15: the radiation alert crosses every screen.
 if not ctx:Wait(.15)then return end
 if ctx:Elapsed()<3.2 then
  local by=ctx.By and string.upper(ctx.By)or nil
  local venue=ctx.Venue
  local where=venue=='Yard'and(by and by..' OPENED SOMETHING RADIOACTIVE'or 'A LUCKY BLOCK IS GOING CRITICAL')
   or venue=='Excavation'and(by and by..' DUG UP SOMETHING RADIOACTIVE'or 'SOMETHING RADIOACTIVE WAS DUG UP')
   or venue=='Machine'and 'THE DOG-O-MATIC IS GOING CRITICAL'
   or 'A SECRET DOG IS GOING CRITICAL IN THE MOUTH'
  ctx:Banner({Kicker='☢  RADIATION ALERT  ☢',Title=config.Title,Text=where,Style='Toxic',Color=GREEN,
   Hold=math.max(1.2,3.55-ctx:Elapsed())})
 end
 -- .8: every light in the district turns green, the giant head's eyes start to glow.
 if not ctx:Wait(.8)then return end
 local greenLights=scope:TintLights(C(150,255,90),fresh(.8)and 2.5 or .3)
 local unlit={}
 for _,p in ipairs(irises)do
  local _,release=scope:Override(p,{Material=Enum.Material.Neon})
  table.insert(unlit,release)
  tint(p,{Color=irisColor})
 end
 -- 1.2: the trefoil assembles in the sky over the stage.
 if not ctx:Wait(SIGN)then return end
 if fresh(SIGN)then Kit.Cue('Whoosh',nil,.5)end
 -- 2: every dog on the island looks up at it.
 if not ctx:Wait(2)then return end
 if ctx:Elapsed()<PRE-.6 then glance=scope:Glance(signAt,{Exclude=model,Turn=.8,Ripple=260})end
 -- PRE-1: the cutaway, built once the dog (and its facing) has streamed in. Wide on the
 -- green sky and the trefoil, a dive to the mouth, close on the reactor; at the blast the
 -- side of the island as the wave crosses it, then back to see the cloud over the stage.
 if not ctx:Wait(PRE-1)then return end
 do
  local F=front()
  local S=F:Cross(Vector3.yAxis)
  local function at(a:number,b:number,c:number):Vector3 return origin+F*a+S*b+Vector3.new(0,c,0)end
  cutaway=ctx:Cutaway({
   {At=CUT,CFrame=Kit.Frame(at(150,-70,85),at(0,0,80)),Fov=70},
   {At=PRE+.35,CFrame=Kit.Frame(at(52,-20,26),at(0,0,7)),Fov=62},
   {At=BOOM-.1,CFrame=Kit.Frame(at(13,-5,6),at(0,0,3.6)),Fov=54},
   {At=BOOM+.05,CFrame=Kit.Frame(at(11.4,-4.4,5.6),at(0,0,3.6)),Fov=50,Linear=true},
   {At=BOOM+.08,CFrame=Kit.Frame(at(120,-180,70),at(110,0,25)),Fov=80,Cut=true},
   {At=BOOM+1.15,CFrame=Kit.Frame(at(128,-172,72),at(118,0,40)),Fov=78,Linear=true},
   {At=BOOM+2.55,CFrame=Kit.Frame(at(205,-62,44),at(0,0,150)),Fov=80},
  },{Focus=origin,Bars=.08})
 end
 if not ctx:Wait(PRE-.2)then return end
 if glance then glance:Stop(1);glance=nil end

 -- PRE: the pug appears in a hiss of steam; the rings and the plate come up.
 if not ctx:Wait(PRE)then return end
 if fresh(PRE)then
  Kit.Cue('Glitch',core,.18)
  scope:Burst(origin+Vector3.new(0,1,0),PALE,26,{Texture=Kit.Textures.Smoke,LightEmission=.4,Speed=NumberRange.new(4,10),
   EmissionDirection=Enum.NormalId.Top,SpreadAngle=Vector2.new(60,60),Drag=3,Lifetime=NumberRange.new(.6,1.1),
   Size=NumberSequence.new(1.5,5),Transparency=NumberSequence.new(.3,1)})
 end
 -- CHARGE Radiation_Cloud: the reactor lights, sparks rush in, it trembles; the beam.
 if not ctx:Wait(CHARGE)then return end
 hl=scope:Highlight(model,GREEN,GREEN,1,1)
 inward.Rate=low and 18 or 70
 vent(low and 5 or 14)
 Kit.Tween(grade,.4,{Brightness=-.05,Contrast=.12})
 if cutaway then cutaway:Shake(.35,.5)end
 if fresh(CHARGE)then Kit.Cue('Whoosh',core,.55);Kit.Cue('Glitch',core,.22);Kit.Cue('Whoosh',nil,.45)end

 -- BOOM: criticality. White for everyone, the lights die, the fireball, the wave.
 if not ctx:Wait(BOOM)then return end
 inward.Rate=0
 smoke.Rate=low and 15 or 60;sparks.Rate=low and 5 or 20
 vent(low and 3 or 9)
 local reach=Kit.Near(origin,160)
 local emp=nil
 if fresh(BOOM)then
  Kit.Flash(WHITE,0,1.6)
  Kit.Cue('Impact',nil,1)
  Kit.Shot(nil,TICK,1,.07,{EqualizerSoundEffect={LowGain=10,MidGain=-6,HighGain=-40},DistortionSoundEffect={Level=.7},
   ReverbSoundEffect={DecayTime=8,WetLevel=0,DryLevel=-2,Density=1,Diffusion=1}})
  task.delay(.06,function()if scope.Alive then Kit.Cue('Sting',nil,.8)end end)
  sky:Set(calm and SKY_GLARE or SKY_FLASH,calm and .25 or .06)
  emp=scope:TintLights(BLACK,0)
  if cutaway then cutaway:Shake(1.4,1.2)end
  grade.Brightness=.28*reach
  scope:Ring(origin+Vector3.new(0,.3,0),GREEN,1.5,SHOCK,.9,{Thickness=.5,Segments=24})
  scope:Burst(origin+Vector3.new(0,.4,0),C(170,235,120),18,{Texture=Kit.Textures.Smoke,LightEmission=.2,Drag=4,
   Speed=NumberRange.new(8,16),SpreadAngle=Vector2.new(85,85),Lifetime=NumberRange.new(.6,1),
   Size=NumberSequence.new(1.5,4.5),Transparency=NumberSequence.new(.4,1)})
  surge:Emit(low and 10 or 30)
 end
 surge.Rate=low and 3 or 8
 plume.Rate=low and 4 or 12;chimney.Rate=low and 3 or 9
 Kit.Tween(grade,.7,{Brightness=0,Contrast=.08,Saturation=.15*reach})
 scope:Duck(.12,.3)
 if drone then Kit.Tween(drone,.15,{Volume=low and .3 or .45});Kit.Tween(drone,1.6,{PlaybackSpeed=.3})end
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
 -- BOOM+.15: a poisoned dusk; every dog flinches from the blast, then looks up at the cloud.
 if not ctx:Wait(BOOM+.15)then return end
 sky:Set(SKY_FALLOUT,1.8)
 if ctx:Elapsed()<FADE-1 then
  glance=scope:Glance(function()return cloudTop end,{Exclude=model,Turn=.35,Ripple=420})
  glance:Bow(.45,1.5)
 end
 -- BOOM+.3: a condensation ring rolls out under the cap in the mouth.
 if not ctx:Wait(BOOM+.3)then return end
 if fresh(BOOM+.3)and not low then
  local xz=capXZ or origin
  scope:Ring(Vector3.new(xz.X,origin.Y+ROLL,xz.Z),PALE,3,12.5,1.4,{Thickness=.3,Alpha=.45,Segments=20})
  Kit.Cue('Whoosh',nil,.3)
 end
 -- BOOM+.45: the lights stumble back on, green.
 if not ctx:Wait(BOOM+.45)then return end
 if emp then emp();emp=nil end
 surge.Rate=0
 -- PRE+3: fallout drifts down from the mouth's cloud.
 if not ctx:Wait(PRE+3)then return end
 fallout.Rate=low and 4 or 16
 -- BOOM+1.6 (and +2.3): condensation rings roll out round the colossal stem, over the head.
 if not ctx:Wait(BOOM+1.6)then return end
 if fresh(BOOM+1.6)then scope:Ring(origin+Vector3.new(0,95,0),PALE,28,190,2.6,{Thickness=4,Alpha=.3,Segments=32})end
 -- BOOM+1.8: green fallout starts to rain on every player.
 if not ctx:Wait(BOOM+1.8)then return end
 rainGlow=scope:Rain({Texture=Kit.Textures.Spark,Color=ColorSequence.new(PALE,GREEN),LightEmission=1,
  Size=NumberSequence.new(.45,.15),Transparency=curve({{0,.1},{.8,.3},{1,1}}),Speed=NumberRange.new(14,20),
  Lifetime=NumberRange.new(3.5,4.5),SpreadAngle=Vector2.new(20,20),RotSpeed=NumberRange.new(-90,90),Rate=70,Area=160,Height=60})
 glowRate=rainGlow and rainGlow.Rate or 0
 if not low then
  rainAsh=scope:Rain({Texture=Kit.Textures.Smoke,Color=ColorSequence.new(C(120,140,100),C(70,84,60)),LightEmission=0,LightInfluence=1,
   Size=NumberSequence.new(.9,.5),Transparency=curve({{0,.4},{.8,.5},{1,1}}),Speed=NumberRange.new(10,14),
   Lifetime=NumberRange.new(4.5,6),SpreadAngle=Vector2.new(30,30),RotSpeed=NumberRange.new(-60,60),Rate=40,Area=160,Height=60})
  ashRate=rainAsh and rainAsh.Rate or 0
 end
 -- GHOST (PRE+3.6): the mouth's cloud stops smoking; a ghostly giant pug in the cap, facing you.
 if not ctx:Wait(GHOST)then return end
 smoke.Rate=0;sparks.Rate=0
 if ctx:Elapsed()<FADE then
  local me=Kit.Me()
  local d=Vector3.new(me.X-origin.X,0,me.Z-origin.Z)
  ghostFace=d.Magnitude>20 and d.Unit or front()
  local _,r=capAt(ctx:Elapsed()-BOOM)
  ghost=ctx:Colossus({Style='Ghost',Color=PALE,Alpha=.42,Height=100,FadeIn=1.6,Rise=40,Clip='Idle',
   At=CFrame.lookAt(cloudTop+ghostFace*r*.25,cloudTop+ghostFace*(r*.25+1))})
  if fresh(GHOST)then Kit.Cue('Sting',nil,.45)end
 end
 if not ctx:Wait(BOOM+2.3)then return end
 if fresh(BOOM+2.3)and not low then scope:Ring(origin+Vector3.new(0,140,0),PALE,40,230,2.8,{Thickness=3,Alpha=.45,Segments=28})end

 -- CLEAR Result_Success: the cloud lets go, the rings drop, puddles splash down, the card;
 -- the ghost in the sky celebrates with it.
 if not ctx:Wait(CLEAR)then return end
 ctx.WhisperStyle={Font=Enum.Font.RobotoMono,Color=C(228,255,206),Glitch=.015,Chroma=false,Shake=false,Type=.035}
 ctx:Title({Font=Enum.Font.Bangers,Hold=3.6})
 vent(low and 1 or 3)
 Kit.Tween(grade,1.4,{Brightness=0,Contrast=0,Saturation=0,TintColor=WHITE},Enum.EasingStyle.Sine)
 if ghost then ghost:Play('Result_Success',false)end
 scope:Duck(.35,2.5)
 if drone then Kit.Tween(drone,2,{Volume=low and .16 or .24})end
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
 if not ctx:Wait(PRE+4.4)then return end
 fallout.Rate=0
 -- The colossal cloud stops billowing, the dogs look away, the ghost settles.
 if not ctx:Wait(FADE-.6)then return end
 plume.Rate=0;chimney.Rate=0
 if glance then glance:Stop(1.2);glance=nil end
 if not ctx:Wait(CLEAR+2.4)then return end
 if ghost then ghost:Play('Idle',true)end
 -- FADE: the sky, the cloud and the fallout ease back; the ghost fades with the cloud.
 if not ctx:Wait(FADE)then return end
 sky:Release(3)
 if drone then Kit.Tween(drone,2.5,{Volume=0})end
 if not ctx:Wait(FADE+.4)then return end
 if ghost then ghost:Stop(1.8);ghost=nil end
 if not ctx:Wait(hold-1.4)then return end
 greenLights()
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
 -- The head's irises (their colour eased back) stop glowing.
 for _,release in ipairs(unlit)do release()end
 -- It walks (on a pad it stays); the puddles fade out.
 ctx:Wait(hold+.8)
end
