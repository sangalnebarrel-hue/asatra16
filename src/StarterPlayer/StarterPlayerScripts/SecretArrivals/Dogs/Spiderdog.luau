-- SPIDERDOG: "IT CAME FROM THE ROOF". First the whole island: the sun drops out of the sky
-- into an orange night and every light in the district dies with a crackle. A colossal web
-- is shot across the sky, strand by strand from every horizon to a hub high over the island,
-- and spun round, outside in, while little Spiderdogs drop on silk threads all around every
-- player (out of the ceiling, indoors) and hang there upside down, turning. Eight colossal
-- orange eyes open on the web low in each player's own sky, right where they are looking
-- (nobody has to look up), every dog on the island looks at them, and a giant Spiderdog
-- takes shape round them, creeps along its strand (it shivers under it), leaps across the
-- sky to the hub's first strand, runs down it toward the stage, lowers itself on a silk
-- line and drops into the roof; the dogs cower. Every camera follows it in (the cutaway)
-- for the stage act: the mouth is already dark. Eight orange eyes open up in the roof and a
-- web is shot across the tunnel, strand by strand. The dog drops in upside down on a silk
-- line, legs scuttling, and creeps down, swinging. The line snaps: it flips, lands, the web
-- tears down behind it, and its eight legs dig, each kick lighting one of the mouth's eight
-- runes. On the landing the sky web falls and comes down over the whole district as a
-- spreading web of light (to the plaza, the museum and the DOG-O-MATIC): as it passes each
-- player it jolts them and their lights come back on with a crackle; the little ones climb
-- away and the night lifts. Off the tongue the giant drops onto the pad instead of the
-- giant head's roof, the web is a tent over the pad, the eyes open in a knot of shadow at
-- its top and the legs light eight stakes round it.
local SoundService=game:GetService('SoundService')
local Players=game:GetService('Players')
local TweenService=game:GetService('TweenService')
local C=Color3.fromRGB
local SILK,EMBER,DIRT,CLOD,DUST,DARK=C(240,240,240),C(255,214,170),C(120,85,50),C(78,54,32),C(150,128,104),C(26,16,12)
local TICK='rbxasset://sounds/volume_slider.ogg'
-- Map-wide beats on the arrival clock (server seconds): the lights die, the first strand
-- flies, the spiral is spun, the little ones start dropping, the giant's eyes open, it takes
-- shape, crawls, lowers itself on its silk, lets go, and is gone into the roof; every camera
-- is pulled in at CUT.
local OUT,SPIN,SPIRAL,BROOD,OPEN,REVEAL,CRAWL,LOWER,FALL,GONE,CUT=.9,1.1,3.2,2,4.2,4.9,5.3,7.9,8.4,9,7.1
-- The stage act runs on its own clock, STAGE seconds into the arrival (the config's Clips and
-- last whisper are shifted the same way): the drop onto the silk, the snap, the landing, the
-- first dig, and the end of its digging.
local STAGE=9.2
local DROP,SNAP,LAND,DIG,DUG=.7,2.5,2.85,2.9,6.2
-- The giant: studs tall, and how far it lowers itself on its silk before it lets go.
local GIANT,LOWERING=95,22
-- Its eight eyes: the big pair on its own (bones Eye_L/Eye_R), three pairs up its forehead;
-- {across, up, diameter} in eye spacings from between its eyes.
local GIANT_EYES={{-.5,0,.52},{.5,0,.52},{-.3,.42,.3},{.3,.42,.3},{-.95,.3,.26},{.95,.3,.26},{-.62,.68,.22},{.62,.68,.22}}
-- The sky web: how far out its strands reach (flat studs from the hub), and where the spiral
-- crosses them (fractions of the way out; a third as much web on Low).
local REACH=950
local LAPS,LAPS_LOW={.84,.69,.54,.4,.27},{.68,.38}
-- The night the sun drops into (the grade and bloom are camera effects only this client sees).
local NIGHT={
 Lighting={ClockTime=.3,Brightness=.9,ExposureCompensation=-.12,Ambient=C(44,28,20),OutdoorAmbient=C(96,56,32),
  ColorShift_Top=C(255,140,60),EnvironmentDiffuseScale=.25,EnvironmentSpecularScale=.15},
 Atmosphere={Density=.27,Offset=.12,Color=C(160,82,38),Decay=C(54,22,10),Glare=0,Haze=1.6},
 Clouds={Cover=.5,Density=.42,Color=C(70,40,26)},
 Sky={MoonAngularSize=18},
 Grade={TintColor=C(255,206,168),Saturation=-.16,Contrast=.16,Brightness=-.02},
 Bloom={Intensity=.36,Size=28,Threshold=1.05},
}
-- An attachment whose X axis points down: CurveSize0=s with CurveSize1=-s makes a beam sag.
local DOWN=CFrame.Angles(0,0,-math.pi/2)
local FLAT=CFrame.Angles(0,0,math.pi/2)
-- Spiral threads, as fractions along the radial strands (outermost first).
local RINGS={.8,.58,.36}
-- The legs in digging order, and a diminished-seventh ladder: one creepy step per leg.
local PAWS={'Paw_L1','Paw_R1','Paw_L2','Paw_R2','Paw_L3','Paw_R3','Paw_L4','Paw_R4'}
local LADDER={1,1.189,1.414,1.682,2,2.378,2.828,3.364}
-- Eight eyes under the roof: across, down, diameter (the big pair opens first).
local EYES={{-.42,1.15,.62},{.42,1.15,.62},{-1.2,.95,.38},{1.2,.95,.38},{-.72,.45,.32},{.72,.45,.32},{-1.45,.3,.24},{1.45,.3,.24}}
-- Lamps coming back on: {delay, on, ease seconds}.
local FLICKER:{{any}}={{0,true,.04},{.07,false,.03},{.14,true,.3}}
local function backOut(x)local c=1.70158;x-=1;return 1+(c+1)*x*x*x+c*x*x end
local function smooth(x)x=math.clamp(x,0,1);return x*x*(3-2*x)end
local function sine(x)x=math.clamp(x,0,1);return .5-.5*math.cos(x*math.pi)end

return function(ctx)
 ctx.WhisperStyle={Font=Enum.Font.Creepster,Color=C(246,238,230),Glitch=0,Chroma=false,Shake=true,Type=.038}
 local Kit,scope,model,config=ctx.Kit,ctx.Scope,ctx.Model,ctx.Config
 local low,calm,origin,hold=ctx.Low,Kit.ReducedMotion(),ctx.Origin,config.Hold
 local ORANGE=config.Color
 local size=Kit.Size(model)
 local hc=size.Y/2
 local up=Vector3.yAxis
 local fresh=ctx.Late<.3
 local venue=ctx.Venue or 'Tongue'
 -- The stage act's clock (0 is STAGE seconds into the arrival) and a wait on it.
 local function clock()return ctx:Elapsed()-STAGE end
 local function waitStage(t:number)return ctx:Wait(STAGE+t)end
 -- Its rotation on the stage: the hang is posed in this frame. On the tongue it faces +Z;
 -- off it, the opener, known only once its root streams in. Until then this client's
 -- camera stands in, and `placers` re-lay what was laid out by it.
 local rot:CFrame,fwd:Vector3,right:Vector3,base:CFrame
 local placers:{()->()}={}
 local function aim(pivot:CFrame)
  rot=pivot.Rotation
  local flat=Vector3.new(rot.LookVector.X,0,rot.LookVector.Z)
  fwd=flat.Magnitude>.1 and flat.Unit or Vector3.zAxis
  right=fwd:Cross(up);base=CFrame.new(origin)*rot
  for _,place in ipairs(placers)do place()end
 end
 local aimed=venue=='Tongue'or Kit.Root(model)~=nil
 if aimed then aim(Kit.Root(model)and model:GetPivot()or CFrame.lookAt(Vector3.zero,Vector3.zAxis))
 else
  local camera=workspace.CurrentCamera
  local d=camera and camera.CFrame.Position-origin or Vector3.zero
  d=Vector3.new(d.X,0,d.Z)
  aim(CFrame.lookAt(Vector3.zero,d.Magnitude>.1 and d.Unit or Vector3.zAxis))
 end
 -- In the open the pad stands proud of its court: whatever is pinned off it finds the real
 -- ground under it (never a player, the dog or this arrival's FX). The belt is flat.
 local params:RaycastParams?
 local function floored(p:Vector3):Vector3
  if venue=='Tongue'then return p end
  if not params then
   local skip:{any}={model,scope.Folder}
   for _,player in ipairs(Players:GetPlayers())do if player.Character then table.insert(skip,player.Character)end end
   local made=RaycastParams.new();made.FilterType=Enum.RaycastFilterType.Exclude;made.RespectCanCollide=true
   made.FilterDescendantsInstances=skip;params=made
  end
  local hit=workspace:Raycast(p+up*3,-up*6,params)
  return hit and Vector3.new(p.X,hit.Position.Y,p.Z)or p
 end
 -- Was this beat on time? (late joiners get the state, not the fanfare) live() is on the
 -- stage clock, due() on the arrival's.
 local function live(t,slack:number?)return clock()-t<(slack or .35)end
 local function due(t,slack:number?)return ctx:Elapsed()-t<(slack or .35)end
 local function near()return Kit.Near(origin,120)end
 -- A tick: pitched, reverberant, a thud with `thud`; 3D on `parent`, else every player hears it.
 local function pip(speed:number,volume:number,parent:Instance?,thud:boolean?)
  if not scope.Alive then return end
  local s=Instance.new('Sound');s.SoundId=TICK;s.Volume=volume;s.PlaybackSpeed=speed
  s.RollOffMinDistance=14;s.RollOffMaxDistance=240
  local r=Instance.new('ReverbSoundEffect');r.DecayTime=thud and .6 or 1.2;r.WetLevel=-6;r.DryLevel=0;r.Parent=s
  if thud then local q=Instance.new('EqualizerSoundEffect');q.LowGain=8;q.MidGain=-6;q.HighGain=-28;q.Parent=s end
  s.Parent=(parent and parent.Parent)and parent or SoundService
  scope:Add(s);s:Play()
  task.delay(2.5,function()if s.Parent then s:Destroy()end end)
 end

 -- Under the giant head the web hangs from the mouth's roof (underside y=23.5) and walls
 -- (inner faces x=±15.5, opening at z=-146), behind the dog; in the open it is a tent.
 local roofed=venue=='Tongue'and math.abs(origin.X)<10 and origin.Z<-148 and origin.Z>-182
 local R:Vector3,anchors:{Vector3},fan:{number},closed
 if roofed then
  R=Vector3.new(origin.X,23.4,origin.Z)
  local function wall(side,deg,dz)
   local x=side*15.4
   return Vector3.new(x,R.Y-math.abs(x-R.X)*math.tan(math.rad(deg)),origin.Z+dz)
  end
  local function floor(side)
   local y=origin.Y-.05
   return Vector3.new(R.X+side*(R.Y-y)/math.tan(math.rad(64)),y,origin.Z-5)
  end
  -- Shot in this order, alternating sides; `fan` walks round the hub for the spirals.
  anchors={Vector3.new(R.X-3.5,23.5,origin.Z-8.5),wall(1,8,-4),wall(-1,8,-4),wall(1,22,-5),wall(-1,22,-5),
   wall(1,38,-6),wall(-1,38,-6),floor(1),floor(-1),Vector3.new(R.X+2.5,23.5,math.min(origin.Z+3,-146.5))}
  fan={2,4,6,8,9,7,5,3};closed=false
 else
  R=origin+up*18
  anchors,fan={},{}
  -- Pegged round the pad from its facing (re-pegged once the real facing streams in).
  local function pitch()
   for i=1,10 do
    local slot=(i-1)*3%10
    local a=slot/10*math.pi*2
    anchors[i]=floored(origin+(right*math.cos(a)+fwd*math.sin(a))*10.5)+up*.05
    fan[slot+1]=i
   end
  end
  pitch();table.insert(placers,pitch)
  closed=true
 end
 local Rh=R.Y-origin.Y
 -- Head height while it hangs: from 3 studs under the roof down to one body height.
 local TOP,BOTTOM=Rh-size.Y-3,size.Y
 local BELLY=Vector3.new(0,size.Y*.36,0)
 local FACE=Vector3.new(0,size.Y*.7,-size.Z*.8)
 local amp=math.rad(calm and 4 or 8)
 local swing=math.pi*2/1.5
 local function sway(s)
  local env=math.min(s/.35,1)*(1-.3*math.clamp(s/(SNAP-DROP),0,1))
  return amp*env*math.sin(swing*s),amp*.35*env*math.sin(swing*s+1.3)
 end
 -- The dog about its own feet at e: upside down on the silk, a pendulum from the roof
 -- point, turning a little on the line; after the snap it falls and flips upright.
 local function pose(e:number):CFrame
  local s=e-DROP
  local y,roll,side,fore,twist
  if e<SNAP then
   y=TOP+(BOTTOM-TOP)*sine(s/(SNAP-DROP))
   -- The bungee: from its feet on the roof it drops past the line's length and back.
   if not calm then y+=math.exp(-4.5*s)*(3*math.cos(8*s)-.8*math.sin(8*s))end
   side,fore=sway(s)
   twist=math.rad(calm and 8 or 16)*math.sin(s*2.6)*(1-smooth((e-2.05)/.45))
   roll=math.pi
  else
   local u=math.clamp((e-SNAP)/(LAND-SNAP),0,1)
   y=BOTTOM*(1-u*u)
   side,fore=sway(SNAP-DROP)
   side*=1-u;fore*=1-u;twist=0
   roll=math.pi+math.pi*backOut(math.min((e-SNAP)/.3,1))
  end
  return CFrame.new(0,Rh,0)*CFrame.Angles(fore,0,side)*CFrame.new(0,y-Rh,0)*CFrame.Angles(0,twist,0)
   *CFrame.new(0,hc,0)*CFrame.Angles(0,0,roll)*CFrame.new(0,-hc,0)
 end
 local cut=(base*pose(SNAP)):PointToWorldSpace(BELLY)
 table.insert(placers,function()cut=(base*pose(SNAP)):PointToWorldSpace(BELLY)end)

 ---------------------------------------------------------------- the island
 local MAP=Kit.Map
 local island=MAP.Center
 -- Where the giant goes in: the giant head's roof just behind the mouth (~86 high there),
 -- else straight down onto the stage.
 local nest=roofed and Vector3.new(origin.X,86,origin.Z)-fwd*40 or origin+up*20
 -- The web's hub, high over the island, 180-220 studs back from the nest on the line from
 -- the island's centre: the giant always has a long way to crawl, down the first strand.
 local flatNest=Vector3.new(nest.X,island.Y,nest.Z)
 local away=flatNest-island
 local dir=away.Magnitude>1 and away.Unit or Vector3.new(0,0,-1)
 local span=math.clamp(away.Magnitude,180,220)
 local apex=flatNest-dir*span+up*(MAP.Sky*1.75)
 -- The strands' far ends on the horizon all round, the first one out beyond the nest. The
 -- jitter is seeded by the arrival, so every client spins the same web.
 local N=low and 8 or 12
 local laps=low and LAPS_LOW or LAPS
 local seeded=Random.new(math.floor(ctx.Start*10)%1000003)
 local horizon:{Vector3}={}
 for i=1,N do
  local a=(i-1)/N*math.pi*2
  if i~=1 and i~=N/2+1 then a+=seeded:NextNumber(-.14,.14)end
  horizon[i]=Vector3.new(apex.X,island.Y+4,apex.Z)+CFrame.Angles(0,a,0):VectorToWorldSpace(dir)*REACH
 end
 -- A point on strand k, a fraction f of the way out from the hub; the first strand (the one
 -- out beyond the nest) `r` flat studs out.
 local function on(k:number,f:number):Vector3 return apex+(horizon[k]-apex)*f end
 local slope=(horizon[1]-apex).Unit
 local function strand(r:number):Vector3 return on(1,r/REACH)end
 local HALF=GIANT/2
 local perch=strand(span)
 local PERCH=span/REACH
 -- After lowering itself it falls until its back is deep in the roof (or ~30 over the pad).
 local falling=math.max(20,perch.Y-GIANT-LOWERING-(roofed and nest.Y-30 or origin.Y+30))
 -- Can this point be seen from `from`? (Nothing solid and visible between them: not the
 -- dog, the players or this arrival's own parts.)
 local function sees(from:Vector3,to:Vector3):boolean
  local look=RaycastParams.new();look.FilterType=Enum.RaycastFilterType.Exclude;look.IgnoreWater=true
  local skip:{Instance}={model,scope.Folder}
  for _,player in ipairs(Players:GetPlayers())do if player.Character then table.insert(skip,player.Character)end end
  for _=1,6 do
   look.FilterDescendantsInstances=skip
   local hit=workspace:Raycast(from,to-from,look)
   if not hit then return true end
   if hit.Instance.Transparency<.9 then return false end
   table.insert(skip,hit.Instance)
  end
  return true
 end
 -- Where the giant shows itself to THIS player: on the strand most in front of their camera,
 -- as far out as puts it SHOWN degrees over their horizon (inside a default third-person
 -- view, which sees only ~15-20° up), with nothing solid in between; failing that on the
 -- nearest-to-view strand that can be seen, and only if none can, at the hub. It creeps in
 -- along that strand, leaps across the sky to the top of the first strand and runs down it
 -- to its perch over the nest (on the first strand already, it just crawls).
 local SHOWN=14
 local K0,F0=1,0
 do
  local cam=workspace.CurrentCamera
  local eye=cam and cam.CFrame.Position or Kit.Me()
  local look=cam and cam.CFrame.LookVector or fwd
  local ahead=Vector3.new(look.X,0,look.Z)
  ahead=ahead.Magnitude>.05 and ahead.Unit or fwd
  -- Each strand's spot nearest SHOWN degrees up (within 7), scored by how far it is from
  -- where they look and how far off that height.
  local picks={}
  for k=1,N do
   local best
   for step=2,32 do
    local f=step*.03
    local c=on(k,f)-up*HALF
    local d=c-eye
    local flat=Vector3.new(d.X,0,d.Z)
    if flat.Magnitude>80 then
     local miss=math.abs(math.deg(math.atan2(d.Y,flat.Magnitude))-SHOWN)
     local off=math.deg(math.acos(math.clamp(flat.Unit:Dot(ahead),-1,1)))
     local score=off+2*miss
     if miss<7 and(not best or score<best.Score)then best={K=k,F=f,At=c,Score=score}end
    end
   end
   if best then table.insert(picks,best)end
  end
  table.sort(picks,function(a,b)return a.Score<b.Score end)
  for _,p in ipairs(picks)do
   if sees(eye,p.At)then K0,F0=p.K,p.F;break end
  end
 end
 -- The leap (from LEAP0 to LEAP1, ARC studs over the straight line), from FROM on strand K0
 -- (at most 60 studs in from where it showed itself) to ATOP on the first strand, just
 -- under the hub.
 local LEAP0,LEAP1,ARC,ATOP=CRAWL+.45,CRAWL+1.75,80,.04
 local FROM=math.max(ATOP,F0-60/math.max((horizon[K0]-apex).Magnitude,1))
 local inward=(apex-horizon[K0]).Unit
 local function turned(a:Vector3,b:Vector3,u:number):Vector3
  local v=a:Lerp(b,smooth(u))
  return v.Magnitude>.05 and v.Unit or b
 end
 -- The giant at time e (its centre, upside down under the web, facing the way it goes) and
 -- how see-through it is.
 local function giantAt(e:number):(CFrame,number)
  local at,heading
  if K0==1 then
   at=on(1,F0+(PERCH-F0)*sine((e-CRAWL)/(LOWER-CRAWL)))
   heading=PERCH>=F0 and slope or -slope
  elseif e<LEAP0 then
   at=on(K0,F0+(FROM-F0)*sine((e-CRAWL)/(LEAP0-CRAWL)));heading=inward
  elseif e<LEAP1 then
   local u=(e-LEAP0)/(LEAP1-LEAP0)
   local s=smooth(u)
   local a,b=on(K0,FROM),on(1,ATOP)
   at=a:Lerp(b,s)+up*(ARC*4*s*(1-s))
   local tangent=(b-a)+up*(ARC*4*(1-2*s))
   -- Never straight up or down (it would spin about its own back).
   local level=Vector3.new(tangent.X,0,tangent.Z)
   if level.Magnitude<.3*tangent.Magnitude then
    tangent=(level.Magnitude>.05 and level.Unit or slope)+up*(tangent.Y>=0 and 2 or -2)
   end
   tangent=tangent.Magnitude>.05 and tangent.Unit or slope
   heading=turned(turned(inward,tangent,u/.25),slope,(u-.75)/.25)
  else
   at=on(1,ATOP+(PERCH-ATOP)*sine((e-LEAP1)/(LOWER-LEAP1)));heading=slope
  end
  local drop,alpha=0,0
  if e>=FALL then
   local x=math.min((e-FALL)/(GONE-FALL),1)
   drop=LOWERING+falling*x*x;alpha=smooth((x-.3)/.7)
  elseif e>=LOWER then drop=LOWERING*sine((e-LOWER)/(FALL-LOWER))end
  local centre=at-up*(HALF+drop)
  return CFrame.lookAt(centre,centre+heading,-up),alpha
 end

 -- 0: the island goes dark. The sun drops out of the sky; the music sinks under a slowed drone.
 scope:Duck(.25,1)
 scope:Drone('Drone',low and .2 or .3,.45,fresh and 1.5 or .4)
 local sky=scope:Sky(NIGHT,fresh and 2.6 or .6,2)
 if due(0)then Kit.Cue('Whoosh',nil,.45)end
 local film,glance,wisps,blackout=nil,nil,nil,nil
 -- What every dog on the island looks at: the giant's eyes.
 local gaze=apex-up*60

 -- Plays a tween as if it began at `at` on the arrival clock (a late client jumps ahead).
 local function cue(o:Instance,at:number,seconds:number,props:{[string]:any},style:Enum.EasingStyle?)
  local e=ctx:Elapsed()
  if e>=at+seconds then for k,v in pairs(props)do (o::any)[k]=v end;return end
  TweenService:Create(o,TweenInfo.new(math.min(seconds,at+seconds-e),style or Enum.EasingStyle.Quad,Enum.EasingDirection.Out,
   0,false,math.max(at-e,0)),props):Play()
 end
 -- The sky web: every end an Attachment on one anchor at the hub, moved by tweens (nothing
 -- runs per frame). Radial strands fly up from the horizon one after another round the
 -- compass; then the spiral is laid strand to strand, round and round, outside in.
 local canopy:BasePart?=nil
 local rays:{[number]:any},spun:{Beam}={},{}
 local function weave()
  local web=scope:Anchor(apex,'SkyWeb')
  canopy=web
  local function fix(p:Vector3):Attachment
   local a=Instance.new('Attachment');a.CFrame=CFrame.new(p-apex)*DOWN;a.Parent=web
   return a
  end
  local step=N==12 and 5 or 3
  for k=0,N-1 do
   local i=k*step%N+1
   local far,tip=fix(horizon[i]),fix(horizon[i])
   rays[i]={Tip=tip,Beam=scope:Beam(far,tip,SILK,1.8,{Width0=5.5,Width1=1.8,Transparency=NumberSequence.new(.35),LightEmission=.8,Segments=2})}
   cue(tip,SPIN+k*.17,.45,{Position=Vector3.zero})
  end
  for k,u in ipairs(laps)do
   for j=1,N do
    local a,b=apex+(horizon[j]-apex)*u,apex+(horizon[j%N+1]-apex)*u
    local to=fix(a)
    local sag=(b-a).Magnitude*.05
    local beam=scope:Beam(fix(a),to,SILK,1+u*4,{Transparency=NumberSequence.new(.45),LightEmission=.8,Segments=6})
    local at=SPIRAL+(k-1)*.16+(j-1)*.5/N
    cue(to,at,.75/N,{Position=b-apex},Enum.EasingStyle.Linear)
    cue(beam,at,.75/N,{CurveSize0=sag,CurveSize1=-sag},Enum.EasingStyle.Linear)
    table.insert(spun,beam)
   end
  end
 end
 -- The landing: the sky web falls. The spiral lets go first, then every strand's hub end
 -- drops through the island and the strand fades.
 local function tearDown()
  local web=canopy
  if not web then return end
  canopy=nil
  for _,beam in ipairs(spun)do Kit.Tween(beam,.5,{Width0=0,Width1=0})end
  for i,ray in pairs(rays)do
   local under=apex+(horizon[i]-apex)*.3
   TweenService:Create(ray.Tip,TweenInfo.new(1.6,Enum.EasingStyle.Quad,Enum.EasingDirection.In,0,false,(i-1)*.03),
    {Position=Vector3.new(under.X,island.Y-40,under.Z)-apex}):Play()
   TweenService:Create(ray.Beam,TweenInfo.new(1.7,Enum.EasingStyle.Quad,Enum.EasingDirection.In,0,false,.1),{Width0=0,Width1=0}):Play()
  end
  task.delay(2.2,function()
   if not scope.Alive then return end
   web:Destroy()
   for _,ray in pairs(rays)do ray.Beam:Destroy()end
   for _,beam in ipairs(spun)do beam:Destroy()end
  end)
 end

 -- Little Spiderdogs on silk threads round this player. One copy is shrunk once and cloned;
 -- its parts are welded to its root, so a single tween moves each one (no per-frame work).
 local brood:Model?,broodRel,broodBelly=nil,CFrame.identity,Vector3.zero
 local hatched=false
 local mites:{any}={}
 local function hatch():Model?
  if hatched then return brood end
  hatched=true
  local copy=Kit.DogCopy(ctx.DogId)
  local root=copy and copy.PrimaryPart
  if not(copy and root)then return nil end
  local _,raw=Kit.Bounds(copy)
  pcall(function()copy:ScaleTo(copy:GetScale()*2.4/math.max(raw.Y,.1))end)
  local centre,box=Kit.Bounds(copy)
  local pivot=copy:GetPivot()
  broodRel=(pivot*CFrame.new(centre)):ToObjectSpace(root.CFrame)
  broodBelly=root.CFrame:PointToObjectSpace(pivot:PointToWorldSpace(centre-Vector3.new(0,box.Y*.14,0)))
  -- Two glowing eyes on its own (the bones' rest pose).
  for _,name in ipairs({'Eye_L','Eye_R'})do
   local bone=copy:FindFirstChild(name,true)
   if bone and bone:IsA('Bone')then
    local cf,parent=bone.CFrame,bone.Parent
    while parent and parent:IsA('Bone')do cf=parent.CFrame*cf;parent=parent.Parent end
    if parent and parent:IsA('BasePart')then
     scope:Part({Name='Eye',Shape=Enum.PartType.Ball,Color=ORANGE,Size=Vector3.one*.3,Massless=true,
      CFrame=CFrame.new((parent.CFrame*cf).Position+pivot.LookVector*.06),Parent=copy})
    end
   end
  end
  for _,p in ipairs(copy:GetDescendants())do
   if p:IsA('BasePart')and p~=root then
    local w=Instance.new('WeldConstraint');w.Part0=root;w.Part1=p;w.Parent=p
    p.Anchored=false
   end
  end
  root.Anchored=true
  brood=copy;scope:Add(function()copy:Destroy()end)
  return copy
 end
 local probe:RaycastParams?
 -- One drops: the first right in the middle of this player's view (between the camera and
 -- them), the rest within 40 studs ahead of them; from the ceiling if there is one, else
 -- out of the dark.
 local function drop(first:boolean)
  local camera=workspace.CurrentCamera
  local template=hatch()
  if not camera or not template then return end
  if not probe then
   local skip:{any}={model,scope.Folder}
   for _,player in ipairs(Players:GetPlayers())do if player.Character then table.insert(skip,player.Character)end end
   local made=RaycastParams.new();made.FilterType=Enum.RaycastFilterType.Exclude;made.RespectCanCollide=true
   made.FilterDescendantsInstances=skip;probe=made
  end
  local eye=camera.CFrame.Position
  local me=Kit.Me()
  local look=Vector3.new(camera.CFrame.LookVector.X,0,camera.CFrame.LookVector.Z)
  look=look.Magnitude>.05 and look.Unit or Vector3.zAxis
  local at=first and eye+camera.CFrame.LookVector*math.clamp((me-eye).Magnitude*.45,5,9)
   or me+CFrame.Angles(0,Kit.Random(-1.1,1.1),0):VectorToWorldSpace(look)*Kit.Random(9,40)
  local floor=workspace:Raycast(Vector3.new(at.X,math.max(me.Y,at.Y)+6,at.Z),Vector3.new(0,-80,0),probe)
  if not floor then return end
  local ground=floor.Position
  local hang=first and Vector3.new(at.X,math.max(at.Y,ground.Y+2.5),at.Z)or ground+up*Kit.Random(4.5,8)
  local ceiling=workspace:Raycast(hang,up*34,probe)
  local top=ceiling and ceiling.Position-up*.4 or hang+up*Kit.Random(26,34)
  -- Upside down, facing this player.
  local face=Vector3.new(eye.X,hang.Y,eye.Z)
  local hung=((face-hang).Magnitude>.1 and CFrame.lookAt(hang,face)or CFrame.new(hang))*CFrame.Angles(0,0,math.pi)
  local mite=template:Clone()
  local root=mite.PrimaryPart
  if not root then mite:Destroy();return end
  -- Its welds hold only in the workspace: parent it first, then move its root (in the same
  -- frame, so it is never drawn where the template was).
  mite.Parent=scope.Folder
  root.CFrame=(hung-hang+top)*broodRel
  local tip=Instance.new('Attachment');tip.Position=broodBelly;tip.Parent=root
  local anchor=scope:Anchor(top,'Thread')
  local hook=Instance.new('Attachment');hook.Parent=anchor
  local entry:any={Model=mite,Root=root,Top=top,Anchor=anchor,Thread=scope:Beam(hook,tip,SILK,.07,{Transparency=NumberSequence.new(.2),LightEmission=.6,Segments=1})}
  table.insert(mites,entry)
  local fall=TweenService:Create(root,TweenInfo.new(1.1,Enum.EasingStyle.Back,Enum.EasingDirection.Out),{CFrame=hung*broodRel})
  -- Then it turns slowly on its thread.
  fall.Completed:Connect(function(state)
   if state~=Enum.PlaybackState.Completed or entry.Fled or not root.Parent then return end
   local turn=Kit.Random(.5,.9)*(math.random()<.5 and -1 or 1)
   entry.Turn=TweenService:Create(root,TweenInfo.new(Kit.Random(1.4,2.2),Enum.EasingStyle.Sine,Enum.EasingDirection.InOut,-1,true),
    {CFrame=hung*CFrame.Angles(0,turn,0)*broodRel})
   entry.Turn:Play()
  end)
  fall:Play()
  pip(Kit.Random(2.2,3),.1,root)
 end
 -- The landing: they all climb back up their threads, into the dark.
 local function scatter()
  for _,m in ipairs(mites)do
   if not m.Fled and m.Root.Parent then
    m.Fled=true
    if m.Turn then m.Turn:Cancel()end
    local held=m.Root.CFrame*broodRel:Inverse()
    TweenService:Create(m.Root,TweenInfo.new(Kit.Random(.45,.7),Enum.EasingStyle.Quad,Enum.EasingDirection.In),
     {CFrame=(held-held.Position+m.Top)*broodRel}):Play()
   end
  end
  task.delay(.8,function()
   if not scope.Alive then return end
   for _,m in ipairs(mites)do m.Model:Destroy();m.Anchor:Destroy();m.Thread:Destroy()end
   table.clear(mites)
  end)
 end

 -- The giant (a colossal local copy), hidden until it takes shape round its eyes; one
 -- stepper poses it on its strand, keeps its eight eyes on its face, and the silk it hangs
 -- from on its belly. Without a copy its eyes crawl down the web alone.
 local giant,aura:Highlight?=nil,nil
 local function summon()
  local start=giantAt(0)
  giant=ctx:Colossus({Height=GIANT,At=start,Style='Solid',Clip='Run'})
  local frame0,boneL,boneR=CFrame.identity,nil,nil
  if giant then
   giant:Fade(1,0)
   frame0=start:ToObjectSpace(giant.Model:GetPivot())
   local l,r=giant.Model:FindFirstChild('Eye_L',true),giant.Model:FindFirstChild('Eye_R',true)
   if l and r and l:IsA('Bone')and r:IsA('Bone')then boneL,boneR=l,r end
  end
  local eyes:{BasePart},frames:{CFrame},shown:{number}={},{},{}
  for i=1,#GIANT_EYES do
   eyes[i]=scope:Part({Name='GiantEye',Shape=Enum.PartType.Ball,Color=i<=2 and EMBER or ORANGE,Size=Vector3.one*.05,Transparency=1,CFrame=start})
   frames[i]=start;shown[i]=0
  end
  local top,belly=scope:Anchor(perch,'GiantSilk'),scope:Anchor(perch,'GiantSilkEnd')
  local a0,a1=Instance.new('Attachment'),Instance.new('Attachment');a0.Parent=top;a1.Parent=belly
  local line=scope:Beam(a0,a1,SILK,1,{Transparency=NumberSequence.new(1),LightEmission=.8,Segments=2})
  local hanging=false
  local shaking:any=nil
  scope:Every(function()
   local e=ctx:Elapsed()
   if e<OPEN-.05 then return true end
   local cf,alpha=giantAt(e)
   if giant then
    giant:Pose(cf)
    if e>=FALL then giant:Fade(alpha,0)end
   end
   if aura and e>=FALL then aura.FillTransparency=.8+.2*alpha;aura.OutlineTransparency=.3+.7*alpha end
   -- Its eyes: on its own eye bones (as they move this frame), else where they would be.
   local look,crown=cf.LookVector,cf.UpVector
   local mid,across
   if giant and boneL and boneR and boneL.Parent and boneR.Parent then
    local pivot,frame=giant.Model:GetPivot(),cf*frame0
    local l,r=boneL.TransformedWorldCFrame.Position,boneR.TransformedWorldCFrame.Position
    mid=frame:PointToWorldSpace(pivot:PointToObjectSpace((l+r)/2))
    across=frame:VectorToWorldSpace(pivot:VectorToObjectSpace(r-l))
   else
    mid=cf.Position+look*(GIANT*.38)+crown*(GIANT*.23);across=cf.RightVector*(GIANT*.218)
   end
   local s=across.Magnitude
   gaze=mid
   local blink=(e>6.35 and e<6.47)and .12 or 1
   for i=1,#GIANT_EYES do
    local d=GIANT_EYES[i]
    local want=d[3]*s*backOut(math.clamp((e-OPEN-math.floor((i-1)/2)*.1)/.22,0,1))*blink*(1-alpha)
    if math.abs(want-shown[i])>.02 then
     shown[i]=want
     local p=eyes[i]
     p.Size=Vector3.one*math.max(want,.05);p.Transparency=want>.1 and 0 or 1
    end
    frames[i]=CFrame.new(mid+across*d[1]+crown*(d[2]*s)+look*(.12*s))
   end
   workspace:BulkMoveTo(eyes,frames,Enum.BulkMoveMode.FireCFrameChanged)
   -- The strand it crawls on shivers under it (none while it is in the air).
   local ray=nil
   if e>=CRAWL and e<LOWER then
    if K0==1 or e>=LEAP1 then ray=rays[1]elseif e<LEAP0 then ray=rays[K0]end
   end
   if shaking and shaking~=ray then shaking.Beam.CurveSize0=0;shaking.Beam.CurveSize1=0 end
   shaking=ray
   if ray then
    local w=(calm and 2 or 5)*math.sin(e*14)
    ray.Beam.CurveSize0=w;ray.Beam.CurveSize1=-w
   end
   if e>=LOWER then
    belly.CFrame=CFrame.new(cf.Position+up*(HALF-GIANT*.36))
    if not hanging then hanging=true;line.Transparency=NumberSequence.new(.2)end
   end
   if e<GONE then return true end
   -- Gone into the roof: its eyes go with it and the silk it hung from fades.
   for _,p in ipairs(eyes)do p:Destroy()end
   if giant then giant:Stop(.1)end
   if aura then aura:Destroy()end
   Kit.Tween(line,.9,{Width0=0,Width1=0})
   return false
  end)
 end
 local function reveal()
  if giant then
   giant:Fade(0,due(REVEAL,.3)and .9 or .2)
   aura=scope:Highlight(giant.Model,ORANGE,EMBER,1,1)
   if aura then Kit.Tween(aura,.9,{FillTransparency=.8,OutlineTransparency=.3})end
  end
  if due(REVEAL)then Kit.Cue('Whoosh',nil,.6);pip(.24,.45,nil,true)end
 end
 -- Every camera: wide on the giant crawling over the island, closer as it lowers itself, down
 -- with it into the roof, then a cut into the stage for the drop, the snap and the landing.
 local function shots()
  local passing,hanging=giantAt(CUT+.4).Position,giantAt(LOWER+.3).Position
  return {
   {At=CUT,CFrame=Kit.Frame(nest+fwd*235+up*95+right*70,passing),Fov=70},
   {At=LOWER+.3,CFrame=Kit.Frame(nest+fwd*150+up*120+right*40,hanging-up*10),Fov=66},
   {At=GONE-.05,CFrame=Kit.Frame(nest+fwd*120+up*100+right*28,nest+up*10),Fov=60},
   {At=GONE,CFrame=Kit.Frame(origin+fwd*26+up*6,R:Lerp(origin,.45)),Fov=64,Cut=true},
   {At=STAGE+SNAP,CFrame=Kit.Frame(origin+fwd*20+up*5.5+right*1.5,origin+up*7),Fov=58},
   {At=STAGE+LAND+.6,CFrame=Kit.Frame(origin+fwd*24+up*6.5,origin+up*3.5),Fov=62},
  }
 end
 -- The landing's shockwave: the web comes down over the whole district. A lap of orange silk
 -- on the sky web's own bearings (a silk lap trailing it, not on Low) and its threads out
 -- from the stage spread past the farthest corner of the district (SecretArrivalConfig.Map
 -- Min/Max: the yards, the plaza, the museum, the lab, the DOG-O-MATIC) in WAVE_T seconds
 -- along the floors (y 0-4). onPass(distance, watching) runs once when it passes this
 -- player (or the cutaway's camera that is watching for them), or when it has spread all
 -- the way.
 local WAVE_T=3.2
 local WAVE_R=0
 for _,x in ipairs({MAP.Min.X,MAP.Max.X})do
  for _,z in ipairs({MAP.Min.Z,MAP.Max.Z})do WAVE_R=math.max(WAVE_R,Vector3.new(x-origin.X,0,z-origin.Z).Magnitude)end
 end
 WAVE_R=math.clamp(WAVE_R+60,300,1000)
 local function shockwave(onPass:(number,boolean)->())
  local at=Vector3.new(origin.X,math.abs(origin.Y-island.Y)<8 and island.Y+1.5 or origin.Y+.5,origin.Z)
  local spokes:{Vector3}={}
  for i=1,N do
   local d=horizon[i]-Vector3.new(apex.X,horizon[i].Y,apex.Z)
   spokes[i]=d.Magnitude>.05 and d.Unit or Vector3.xAxis
  end
  local parts:{BasePart},frames:{CFrame}={},{}
  local laps={{Color=ORANGE,K=1,Thick=1.8,Tall=3,Alpha=.12}}
  if not low then table.insert(laps,{Color=SILK,K=.8,Thick=.7,Tall=1.2,Alpha=.35})end
  for _,lap in ipairs(laps)do
   lap.Parts={}
   for i=1,N do
    lap.Parts[i]=scope:Part({Name='WebWave',Color=lap.Color,Transparency=1,Size=Vector3.one,CFrame=CFrame.new(at)})
    table.insert(parts,lap.Parts[i])
   end
  end
  local threads={}
  for i=1,N do
   threads[i]=scope:Part({Name='WebThread',Color=SILK,Transparency=1,Size=Vector3.one,CFrame=CFrame.new(at)})
   table.insert(parts,threads[i])
  end
  -- A lap's sides are nearest the stage halfway between threads.
  local inner=math.cos(math.pi/N)
  local passed=false
  scope:Every(function(_,age)
   local a=math.min(age/WAVE_T,1)
   local r=6+(WAVE_R-6)*(1-(1-a)^2)
   local fade=smooth((a-.7)/.3)
   local n=0
   for _,lap in ipairs(laps)do
    local lr=r*lap.K
    local alpha=lap.Alpha+(1-lap.Alpha)*fade
    for i=1,N do
     local p,q=at+spokes[i]*lr,at+spokes[i%N+1]*lr
     local side=lap.Parts[i]
     side.Size=Vector3.new(lap.Thick,lap.Tall,(q-p).Magnitude+lap.Thick);side.Transparency=alpha
     n+=1;frames[n]=CFrame.lookAt((p+q)/2,q)
    end
   end
   for i,t in ipairs(threads)do
    local tip=at+spokes[i]*r
    t.Size=Vector3.new(.45,.35,r);t.Transparency=.3+.7*fade
    n+=1;frames[n]=CFrame.lookAt((at+tip)/2,tip)
   end
   workspace:BulkMoveTo(parts,frames,Enum.BulkMoveMode.FireCFrameChanged)
   if not passed then
    local cam=workspace.CurrentCamera
    local watching=film~=nil and film.Active and cam~=nil
    local p=watching and cam.CFrame.Position or Kit.Me()
    local d=Vector3.new(p.X-at.X,0,p.Z-at.Z).Magnitude
    if r*inner>=d or a>=1 then passed=true;onPass(d,watching)end
   end
   if a<1 then return true end
   for _,p in ipairs(parts)do p:Destroy()end
   return false
  end)
 end

 -- The mouth goes dark with the island (OUT). The runes wait for the legs; the lamps come
 -- back on the landing.
 local saved,dark={},{}
 local function tint(o:Instance,props:{[string]:any})
  local before={}
  for k in pairs(props)do before[k]=(o::any)[k]end
  scope:Override(o,props);saved[o],dark[o]=before,props
 end
 -- Tweens on map objects stop with the arrival, so the overrides' restore has the last word.
 local function ease(o:Instance,seconds:number,props:{[string]:any})
  local t=Kit.Tween(o,seconds,props);scope:Add(function()t:Cancel()end)
 end
 -- Back to its own values (on=true) or to the dark ones, eased over `seconds`.
 local function switch(o:Instance,on:boolean,seconds:number)
  local props=on and saved[o]or dark[o]
  if not props or not o.Parent then return end
  local eased={}
  for k,v in pairs(props)do if typeof(v)=='EnumItem'then (o::any)[k]=v else eased[k]=v end end
  ease(o,seconds,eased)
 end
 local runes,lamps,dims={},{},{}
 if venue=='Tongue'then
  local district=workspace:FindFirstChild('DOGROTS_District')
  local factory=district and district:FindFirstChild('02_DogFactory')
  local tunnel=factory and factory:FindFirstChild('DarkMouthTunnel')
  local line=district and district:FindFirstChild('03_DogLine')
  for _,o in ipairs(tunnel and tunnel:GetChildren()or {})do
   if o.Name=='MouthRune'and o:IsA('BasePart')then table.insert(dims,{o,{Color=DARK}});table.insert(runes,o)end
  end
  -- The light's Color only: WorldDetailQuality owns its Enabled, and the world-event
  -- lighting saves and restores its Brightness (it would keep our dimmed value).
  for _,lantern in ipairs(line and line:GetChildren()or {})do
   local lens=lantern.Name=='PromenadeLantern'and lantern:FindFirstChild('WarmLens')
   if lens and lens:IsA('BasePart')and (lens.Position-origin).Magnitude<26 then
    table.insert(dims,{lens,{Color=C(48,34,26)}});table.insert(lamps,{O=lens,At=lens.Position})
    for _,l in ipairs(lantern:GetDescendants())do
     if l:IsA('PointLight')then table.insert(dims,{l,{Color=C(14,10,7)}});table.insert(lamps,{O=l,At=lens.Position})end
    end
   end
  end
  local strip=line and line:FindFirstChild('Tongue')
  for _,g in ipairs(strip and strip:GetChildren()or {})do
   if g.Name=='WarmEdgeGuide'and g:IsA('BasePart')and math.abs((g.Position-origin):Dot(fwd))<30 then
    table.insert(dims,{g,{Color=C(58,40,36),Material=Enum.Material.SmoothPlastic}});table.insert(lamps,{O=g,At=g.Position})
   end
  end
 end
 local function darken()
  for _,d in ipairs(dims)do if d[1].Parent then tint(d[1],d[2])end end
 end
 -- In the open there are no runes: eight dark stakes ring the pad instead, half a step off
 -- its facing (none stands in front of whoever opened it), for the legs to light.
 local stakes:{BasePart}={}
 if venue~='Tongue'then
  for i=1,8 do
   local p=scope:Part({Name='Stake',Color=DARK,Size=Vector3.new(.4,1.6,.4),Transparency=fresh and 1 or 0,CFrame=CFrame.new(origin)})
   stakes[i]=p;table.insert(runes,p)
   if fresh then Kit.Tween(p,.6,{Transparency=0})end
  end
  local function place()
   for i,p in ipairs(stakes)do
    local a=(i-.5)/#stakes*math.pi*2
    p.CFrame=CFrame.new(floored(origin+(fwd*math.cos(a)+right*math.sin(a))*6.8)+up*.8)
   end
  end
  place();table.insert(placers,place)
 end

 -- The stage web: radial strands shot from the roof point, then spiral threads between them.
 -- Every end is an Attachment on one anchor, moved each frame while the web is alive.
 local webbed=clock()<LAND+1.2
 local hub=webbed and scope:Anchor(R,'Web')or nil
 local function pin(p:Vector3):Attachment
  local a=Instance.new('Attachment');a.CFrame=CFrame.new(p-R)*DOWN;a.Parent=hub
  return a
 end
 local strands:{any},rings:{{Attachment}},spirals:{any}={},{},{}
 if hub then
  for i,to in ipairs(anchors)do
   local s:any={To=to,At=.04+(i-1)*.05,Break=LAND+(i-1)*.03,P0=R,P1=R,Sag=0,Alpha=1,Shown=1,
    Vel=Vector3.new(Kit.Random(-4,4),Kit.Random(0,3),Kit.Random(-4,4))}
   if low then
    s.Part=scope:Part({Name='Strand',Color=SILK,Size=Vector3.one*.1,Transparency=1,CFrame=CFrame.new(R)})
   else
    s.Hub,s.Tip=pin(R),pin(R)
    s.Beam=scope:Beam(s.Hub,s.Tip,SILK,.08,{Transparency=NumberSequence.new(1),Segments=8})
   end
   strands[i]=s
  end
  -- (A tent re-pegged to the real facing moves its strands' far ends with it.)
  table.insert(placers,function()for i,s in ipairs(strands)do s.To=anchors[i]end end)
  if not low then
   for k in ipairs(RINGS)do
    rings[k]={}
    for j in ipairs(fan)do rings[k][j]=pin(R)end
    for j=1,#fan-(closed and 0 or 1)do
     local j2=j%#fan+1
     local a,b=strands[fan[j]],strands[fan[j2]]
     table.insert(spirals,{A=a,B=b,At=math.max(a.At,b.At)+.17+(k-1)*.05,Shown=1,
      Beam=scope:Beam(rings[k][j],rings[k][j2],SILK,.05,{Transparency=NumberSequence.new(1),CurveSize0=.35,CurveSize1=-.35,Segments=6})})
    end
   end
  end
  local floorY=origin.Y+.1
  local settled=false
  scope:Every(function()
   local e=clock()
   -- Nothing to do until the first strand flies (the whole map-wide act before it).
   if e<0 or settled and e<LAND then return true end
   for _,s in ipairs(strands)do
    local go=math.clamp((e-s.At)/.13,0,1)
    if go>0 and not s.Shot then
     s.Shot=true
     if live(s.At,.1)then pip(Kit.Random(2.5,3.3),.16,hub)end
    end
    local p0,sag,alpha=R,go>=1 and 1.5*smooth((e-s.At-.13)/.3)or 0,go>0 and(low and .25 or .12)or 1
    -- Torn down: the hub end falls, the strand droops from its wall and fades.
    local f=e-s.Break
    if f>0 then
     if not s.Torn then s.Torn=true;if live(s.Break,.1)then pip(Kit.Random(3.6,4.6),.09,hub)end end
     p0=R+s.Vel*f-up*(30*f*f)
     if p0.Y<floorY then p0=Vector3.new(p0.X,floorY,p0.Z)end
     sag+=3*math.min(f/.6,1)
     alpha=alpha+(1-alpha)*math.clamp((f-.15)/.6,0,1)
    end
    s.P0,s.P1,s.Sag,s.Alpha=p0,R:Lerp(s.To,1-(1-go)^3),sag,alpha
    if s.Beam then
     s.Hub.Position=p0-R;s.Tip.Position=s.P1-R
     s.Beam.CurveSize0=sag;s.Beam.CurveSize1=-sag
     if math.abs(alpha-s.Shown)>.01 then s.Shown=alpha;s.Beam.Transparency=NumberSequence.new(alpha)end
    elseif s.Part then
     s.Part.Size=Vector3.new(.1,.1,math.max((s.P1-p0).Magnitude,.05))
     s.Part.CFrame=Kit.LookAt((p0+s.P1)/2,s.P1);s.Part.Transparency=alpha
    end
   end
   -- Ring points sit on the radials' curves (the beam's cubic with both controls `sag` down).
   for k,ring in ipairs(rings)do
    local f=RINGS[k]
    local u,dip=f*f*(3-2*f),3*f*(1-f)
    for j,i in ipairs(fan)do
     local s=strands[i]
     ring[j].Position=s.P0:Lerp(s.P1,u)-up*(s.Sag*dip)-R
    end
   end
   for _,g in ipairs(spirals)do
    local alpha=math.max(1-.62*math.clamp((e-g.At)/.15,0,1),g.A.Alpha,g.B.Alpha)
    if math.abs(alpha-g.Shown)>.01 then g.Shown=alpha;g.Beam.Transparency=NumberSequence.new(alpha)end
   end
   if e>1.2 and e<LAND then settled=true end
   if e<LAND+.03*#strands+.9 then return true end
   for _,s in ipairs(strands)do if s.Part then s.Part:Destroy()end;if s.Beam then s.Beam:Destroy()end end
   for _,g in ipairs(spirals)do g.Beam:Destroy()end
   if hub then hub:Destroy()end
   return false
  end)
 end

 -- Stage 0.2: something in the roof opens its eyes. They blink once and close as it drops.
 if clock()<DROP+.2 then
  local eyes={}
  for i,d in ipairs(EYES)do
   local p=scope:Part({Name='Eye',Shape=Enum.PartType.Ball,Color=i<=2 and EMBER or ORANGE,Size=Vector3.one*.05,Transparency=1,
    CFrame=CFrame.new(R+fwd*.5+right*d[1]-up*d[2])})
   eyes[i]={Part=p,Size=d[3],At=.2+math.floor((i-1)/2)*.07}
  end
  local glow=not low and scope:Light(eyes[1].Part,ORANGE,12,0)or nil
  -- No dark roof behind them in the open: they open in a knot of shadow at the web's top,
  -- which thins out as it drops.
  local knotAt=not roofed and scope:Anchor(R-fwd*.9-up*.7,'Knot')or nil
  local knot=knotAt and scope:Emitter(knotAt,{Texture=Kit.Textures.Smoke,Color=ColorSequence.new(DARK),LightEmission=0,
   Lifetime=NumberRange.new(.6,.9),Speed=NumberRange.new(.2,.6),Size=NumberSequence.new(2.4,3.4),Rotation=NumberRange.new(0,360),
   RotSpeed=NumberRange.new(-40,40),Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,1),NumberSequenceKeypoint.new(.2,.15),NumberSequenceKeypoint.new(1,1)})})or nil
  table.insert(placers,function()
   for i,d in ipairs(EYES)do
    local p=eyes[i].Part
    if p.Parent then p.CFrame=CFrame.new(R+fwd*.5+right*d[1]-up*d[2])end
   end
   if knotAt then knotAt.CFrame=CFrame.new(R-fwd*.9-up*.7)end
  end)
  local knotted=false
  scope:Every(function()
   local e=clock()
   if e<0 then return true end
   local close=1-math.clamp((e-DROP)/.12,0,1)
   local blink=(e>.56 and e<.63)and .15 or 1
   for _,eye in ipairs(eyes)do
    local s=backOut(math.clamp((e-eye.At)/.2,0,1))*close*blink
    eye.Part.Size=Vector3.one*math.max(eye.Size*s,.05);eye.Part.Transparency=s>.08 and 0 or 1
   end
   if glow then glow.Brightness=2*close*math.clamp((e-.2)/.3,0,1)end
   if knot then
    local on=e>.05 and e<DROP
    if on~=knotted then knotted=on;knot.Rate=on and(low and 8 or 22)or 0 end
   end
   if e<DROP+.15 then return true end
   for _,eye in ipairs(eyes)do eye.Part:Destroy()end
   return false
  end)
 end

 -- The dog: hidden from the start (the whole map-wide act) until the drop, then on the silk
 -- until it lands.
 local hang=clock()<LAND
 local silkEnd=hub and scope:Anchor(R,'SilkEnd')or nil
 local silk,silkPart,lamp,shadow
 -- Off the tongue, until its root (and with it its facing) streams in, the pose waits in a
 -- stand-in and the dog stays hidden; the facing is read before any offset moves it.
 local lift:any=nil
 if hang then
  local vis=scope:Visibility(model);vis.Set(1)
  lift=aimed and scope:Offset(model)or {CFrame=CFrame.identity,Stand=true}
  if silkEnd then
   if low then
    silkPart=scope:Part({Name='Silk',Color=SILK,Size=Vector3.one*.12,Transparency=1,CFrame=CFrame.new(R)})
   else
    local at=Instance.new('Attachment');at.Parent=silkEnd
    silk=scope:Beam(pin(R),at,SILK,.11,{Transparency=NumberSequence.new(1),Segments=8})
   end
  end
  -- A warm light just under its face, so it reads in the dark of the mouth.
  local face=not low and scope:Anchor(R,'FaceLight')or nil
  lamp=face and scope:Light(face,C(255,160,100),12,0)or nil
  -- Its shadow on the belt grows and darkens as it comes down.
  shadow=scope:Part({Name='Shadow',Shape=Enum.PartType.Cylinder,Material=Enum.Material.SmoothPlastic,Color=C(6,4,8),
   Size=Vector3.new(.05,1,1),Transparency=1,CFrame=CFrame.new(origin+up*.07)*FLAT})
  local shown=1
  scope:Every(function()
   local e=clock()
   -- Up in the roof, hidden, until just before the drop.
   if e<DROP-.15 then return true end
   if e>=LAND then
    lift.CFrame=CFrame.identity
    if shown~=0 then shown=0;vis.Set(0)end
    if silk then silk.Enabled=false end
    if silkPart then silkPart.Transparency=1 end
    if lamp then lamp.Brightness=0 end
    return false
   end
   local v=(e<DROP or lift.Stand)and 1 or 1-math.clamp((e-DROP)/.1,0,1)
   if v~=shown then shown=v;vis.Set(v)end
   local cf=pose(math.max(e,DROP))
   lift.CFrame=cf
   local world=base*cf
   -- The silk: taut to its belly; on the snap it whips back up to the roof and fades.
   local tip,alpha,whip=cut,.05,0
   if e<SNAP then tip=world:PointToWorldSpace(BELLY)
   else
    local u=math.clamp((e-SNAP)/.3,0,1)
    tip=cut:Lerp(R,1-(1-u)^3);alpha=.05+.95*u;whip=math.sin(u*math.pi*3)*(1-u)*1.4
   end
   if e<DROP then alpha=1 end
   if silkEnd then silkEnd.CFrame=CFrame.new(tip)end
   if silk then silk.Transparency=NumberSequence.new(alpha);silk.CurveSize1=whip end
   if silkPart then
    silkPart.Size=Vector3.new(.12,.12,math.max((tip-R).Magnitude,.05))
    silkPart.CFrame=Kit.LookAt((R+tip)/2,tip);silkPart.Transparency=alpha
   end
   if face and lamp then
    face.CFrame=CFrame.new(world:PointToWorldSpace(FACE))
    lamp.Brightness=e<DROP and 0 or 1.2*math.clamp((e-DROP)/.3,0,1)*(1-math.clamp((e-SNAP)/.35,0,1))
   end
   local top=world:PointToWorldSpace(Vector3.new(0,size.Y,0)).Y-origin.Y
   local c=e<DROP and 0 or 1-math.clamp(top/(TOP+1),0,1)
   shadow.Size=Vector3.new(.05,size.X*(.55+.5*c),size.X*(.55+.5*c))
   shadow.Transparency=1-.55*c
   return true
  end)
 end
 -- Its root has streamed in: turn everything to the way it really faces, then hand the
 -- pose to a real offset (it would rotate the pivot this reads).
 if not aimed then
  scope:Every(function()
   if not Kit.Root(model)then return true end
   aim(model:GetPivot())
   if lift and lift.Stand and clock()<LAND then
    local handle=scope:Offset(model);handle.CFrame=lift.CFrame;lift=handle
   end
   return false
  end)
 end

 ---------------------------------------------------------------- the map-wide act
 task.spawn(function()
  if not ctx:Wait(.6)then return end
  weave()
  -- OUT: every light in the district dies with a crackle, the mouth's lamps and runes too.
  if not ctx:Wait(OUT)then return end
  darken()
  blackout=scope:TintLights(Color3.new(0,0,0),.2)
  if due(OUT)then Kit.Cue('Glitch',nil,.3);pip(.3,.4,nil,true);task.delay(.12,pip,.22,.3,nil,true)end
  -- Silk drifts down round every player while the web is spun.
  if not ctx:Wait(1.5)then return end
  wisps=scope:Rain({Texture=Kit.Textures.Spark,Color=ColorSequence.new(SILK),LightEmission=.5,Rate=22,Size=NumberSequence.new(.32,.12),
   Speed=NumberRange.new(4,8),Lifetime=NumberRange.new(6,8),SpreadAngle=Vector2.new(30,30),Rotation=NumberRange.new(0,360),
   RotSpeed=NumberRange.new(-90,90),Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,1),NumberSequenceKeypoint.new(.12,.3),
    NumberSequenceKeypoint.new(.8,.45),NumberSequenceKeypoint.new(1,1)}),Area=140,Height=50})
  -- The giant is made (hidden) a second early, so its eyes can open on its face.
  if not ctx:Wait(OPEN-1)then return end
  summon()
  if not ctx:Wait(OPEN)then return end
  if due(OPEN)then
   Kit.Cue('Sting',nil,.75);Kit.Flash(C(255,150,70),.86,.7)
   task.delay(.25,function()if scope.Alive then Kit.Cue('Heartbeat',nil,.9)end end)
  end
  -- Every dog on the island looks at its eyes, and follows them across the web.
  if not ctx:Wait(OPEN+.15)then return end
  glance=scope:Glance(function()return gaze end,{Exclude=model,Turn=.7,Ripple=600})
  if not ctx:Wait(REVEAL)then return end
  reveal()
  if not ctx:Wait(CUT-.5)then return end
  film=ctx:Cutaway(shots(),{Bars=.09,Shake=.1})
  -- It lowers itself on a silk line over the roof...
  if not ctx:Wait(LOWER)then return end
  if due(LOWER)then for i=0,4 do task.delay(i*.08,pip,1.2+i*.25,.07,nil)end end
  -- ...lets go, and every dog cowers...
  if not ctx:Wait(FALL)then return end
  if due(FALL)then Kit.Cue('Whoosh',nil,.7)end
  if glance then glance:Bow(.5,1.6)end
  -- ...and it is gone into the roof.
  if not ctx:Wait(GONE)then return end
  if due(GONE)then Kit.Cue('Impact',nil,.5);pip(.26,.4,nil,true);Kit.Shake(.18,.4)end
  if not ctx:Wait(STAGE+.4)then return end
  if glance then glance:Stop(1.2)end
  -- After the landing the night lifts.
  if not ctx:Wait(STAGE+LAND+.85)then return end
  sky:Release(3.4)
 end)
 -- The strands fly up with a thwip each (every player hears them); the spiral zips round.
 task.spawn(function()
  for k=0,N-1 do
   local t=SPIN+k*.17
   if not ctx:Wait(t)then return end
   if due(t,.1)then pip(Kit.Random(2.4,3.2),.12,nil)end
  end
  for k=1,#laps do
   local t=SPIRAL+(k-1)*.16
   if not ctx:Wait(t)then return end
   if due(t,.1)then pip(1.5+k*.3,.08,nil)end
  end
 end)
 -- The little ones drop, one by one, round this player.
 task.spawn(function()
  local count,gap=low and 5 or 14,low and .95 or .34
  for i=1,count do
   local t=BROOD+(i-1)*gap
   if not ctx:Wait(t)then return end
   if due(t,1)then drop(i==1)end
  end
 end)
 -- The giant's legs on the web: a skitter every player hears while it crawls; a rush of air
 -- as it leaps and the web's thud as it lands on the first strand.
 local leaps=K0~=1
 task.spawn(function()
  local t,step=CRAWL,low and .14 or .075
  local leapt,landed=false,false
  while t<LOWER do
   if not ctx:Wait(t)then return end
   if leaps and not leapt and t>=LEAP0 then leapt=true;if due(LEAP0,.15)then Kit.Cue('Whoosh',nil,.6)end end
   if leaps and not landed and t>=LEAP1 then landed=true;if due(LEAP1,.15)then pip(.22,.4,nil,true)end end
   if not(leaps and t>=LEAP0 and t<LEAP1)and due(t,.1)then pip(Kit.Random(.5,.9),Kit.Random(.04,.075),nil,true)end
   t+=step
  end
 end)

 ---------------------------------------------------------------- the stage act
 if not waitStage(0)then return end
 if live(0)then Kit.Cue('Whoosh',hub,.3)end
 if not waitStage(.2)then return end
 if live(.2)then Kit.Cue('Glitch',hub,.2)end
 if not waitStage(.56)then return end
 if live(.56,.1)then pip(1.6,.12,hub)end
 -- 0.7: it drops in, upside down, legs going (the Run clip).
 if not waitStage(DROP)then return end
 local hl=hang and scope:Highlight(model,ORANGE,C(255,190,140),.92,.5)or nil
 if hang and live(DROP)then
  Kit.Cue('Whoosh',nil,.5);pip(.8,.2,silkEnd,true)
  local n=near();if n>.25 then Kit.FOVPunch(-2.5*n,.25,.9)end
 end
 if not waitStage(1.25)then return end
 if live(1.25)then Kit.Cue('Heartbeat',nil,.5)end
 if not waitStage(1.95)then return end
 if live(1.95)then Kit.Cue('Heartbeat',nil,.6)end
 -- 2.5: the line snaps.
 if not waitStage(SNAP)then return end
 if hang and live(SNAP)then
  pip(4.4,.32,silkEnd);task.delay(.05,pip,3.2,.2,silkEnd)
  scope:Burst(cut,SILK,12,{Speed=NumberRange.new(4,9),Lifetime=NumberRange.new(.25,.5),Size=NumberSequence.new(.3,0)})
 end
 -- 2.85: it lands. The web tears down (its own stepper) and the mouth's lamps flicker back
 -- on. Map-wide: the sky web falls, the little ones run and the web's shockwave spreads over
 -- the whole district, bringing the power back for each player as it passes them.
 if not waitStage(LAND)then return end
 if wisps then wisps.Rate=0 end
 tearDown();scatter()
 -- The power comes back for this player as the shockwave passes them: every light on the
 -- island (released first, so the mouth's lamps flicker from dark), then the mouth's lamps
 -- flickering on from the stage outward.
 local powered=false
 local function power(flicker:boolean)
  if powered then return end
  powered=true
  if blackout then blackout()end
  for _,entry in ipairs(lamps)do
   local o=entry.O
   if flicker then
    local delay=(entry.At-origin).Magnitude*.012
    for _,step in ipairs(FLICKER)do
     task.delay(delay+step[1],function()if scope.Alive then switch(o,step[2],step[3])end end)
    end
   else switch(o,true,.3)end
  end
 end
 if live(LAND)then
  local n=near()
  Kit.Cue('Impact',nil,.7);Kit.Cue('Sting',nil,.45)
  for i=0,3 do task.delay(.1+i*.09,pip,Kit.Random(3.4,4.4),.08,nil)end
  if film and film.Active then film:Shake(.8,.5)end
  if n>.05 then Kit.Shake(.35*n,.4);if not calm then Kit.Flash(C(255,206,170),1-.22*n,.35)end end
  if n>.25 then Kit.FOVPunch(-4*n,.06,.6)end
  -- Away from the stage it jolts them and the power comes back with a crackle.
  shockwave(function(d:number,watching:boolean)
   power(true)
   if d>24 then
    if watching then film:Shake(.5,.4)else Kit.Shake(.22,.35)end
    Kit.Cue('Glitch',nil,.16);pip(.3,.22,nil,true)
   end
  end)
  scope:Ring(origin+up*.15,DUST,2,14,.6,{Thickness=.32,Alpha=.45})
  if not low then scope:Ring(origin+up*.2,ORANGE,1,9,.45,{Thickness=.18,Alpha=.3,Segments=24})end
  scope:Burst(origin+up*.4,DUST,20,{Texture=Kit.Textures.Smoke,LightEmission=.05,Drag=4,Speed=NumberRange.new(6,12),
   SpreadAngle=Vector2.new(80,80),Lifetime=NumberRange.new(.6,1.1),Size=NumberSequence.new(1.2,3.4),Transparency=NumberSequence.new(.45,1)})
  local flash=hl or scope:Highlight(model,EMBER,ORANGE,.3,.2)
  flash.FillColor=EMBER;flash.FillTransparency=.3;flash.OutlineTransparency=.1
  Kit.Tween(flash,.9,{FillTransparency=1,OutlineTransparency=1})
  task.delay(1,function()if scope.Alive and flash.Parent then flash:Destroy()end end)
 else
  if hl then hl:Destroy()end
  power(false)
 end
 if shadow then Kit.Tween(shadow,.3,{Transparency=1})end
 ctx:Title({Font=Enum.Font.Creepster})

 -- 2.9: Ability_MultiDig. Dirt flies off each paw in turn, every 0.1 s; on the first
 -- round each leg lights the nearest dark rune on its side, up a creepy ladder.
 local digger=scope:Anchor(origin,'Dig')
 local clods=scope:Emitter(digger,{Texture=Kit.Textures.Smoke,Color=ColorSequence.new(DIRT,CLOD),LightEmission=0,
  Lifetime=NumberRange.new(.45,.8),Speed=NumberRange.new(9,16),SpreadAngle=Vector2.new(24,24),Acceleration=Vector3.new(0,-70,0),
  Size=NumberSequence.new(.55,.3),Rotation=NumberRange.new(0,360),RotSpeed=NumberRange.new(-220,220),EmissionDirection=Enum.NormalId.Front,
  Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,0),NumberSequenceKeypoint.new(.75,.1),NumberSequenceKeypoint.new(1,1)})})
 local dust=scope:Emitter(digger,{Texture=Kit.Textures.Smoke,Color=ColorSequence.new(DUST),LightEmission=.05,Drag=3,
  Lifetime=NumberRange.new(.7,1.2),Speed=NumberRange.new(2,5),SpreadAngle=Vector2.new(60,60),Acceleration=Vector3.new(0,1.5,0),
  Size=NumberSequence.new(1,2.8),Transparency=NumberSequence.new(.55,1),EmissionDirection=Enum.NormalId.Front})
 local sparks=not low and scope:Emitter(digger,{Color=ColorSequence.new(ORANGE,EMBER),Lifetime=NumberRange.new(.3,.6),
  Speed=NumberRange.new(6,12),SpreadAngle=Vector2.new(40,40),Acceleration=Vector3.new(0,-30,0),Size=NumberSequence.new(.35,0),
  EmissionDirection=Enum.NormalId.Front})or nil
 local bones:{any}={}
 local function paw(i:number):Vector3
  local b=bones[i]
  if not(b and b.Parent)then
   local found=model:FindFirstChild(PAWS[i],true)
   b=found and found:IsA('Bone')and found or nil;bones[i]=b
  end
  if b then return (b::Bone).TransformedWorldCFrame.Position end
  -- Not streamed in: where its paws stand.
  local pair,side=math.ceil(i/2),i%2==1 and -1 or 1
  return origin+fwd*(({1.9,.65,-.65,-1.9})[pair]*size.Z/6)+right*(side*size.X*.44)+up*.2
 end
 local lit={}
 local function count(n)return low and math.ceil(n*.4)or n end
 -- The runes go back to their own purple as it sets off (the stakes fade away).
 local faded=false
 local function settle()
  faded=true
  for _,r in ipairs(runes)do switch(r,true,.7)end
  for _,p in ipairs(stakes)do ease(p,.7,{Transparency=1})end
 end
 for k=0,29 do
  local t=DIG+k*.1
  if t>DUG-.3 then break end
  if not faded and t>=DUG-.8 then
   if not waitStage(DUG-.8)then return end
   settle()
  end
  if not waitStage(t)then return end
  local i=k%8+1
  local at=paw(i)
  if k<8 then
   local side=(at-origin):Dot(right)>0
   local best,dist=nil,math.huge
   for _,r in ipairs(runes)do
    if not lit[r]and r.Parent then
     local d=(r.Position-at).Magnitude+(((r.Position-origin):Dot(right)>0)~=side and 1000 or 0)
     if d<dist then best,dist=r,d end
    end
   end
   if best then
    lit[best]=true
    if live(t,.15)then
     best.Color=EMBER;ease(best,.45,{Color=ORANGE})
     if not low then scope:Burst(best.Position,ORANGE,8,{Speed=NumberRange.new(2,6),Lifetime=NumberRange.new(.3,.6),Size=NumberSequence.new(.4,0)})end
    else best.Color=ORANGE end
   end
  end
  if live(t,.15)then
   local out=Vector3.new(at.X-origin.X,0,at.Z-origin.Z)
   out=out.Magnitude>.2 and out.Unit or right
   digger.CFrame=Kit.LookAt(at,at+(out*.75+up-fwd*.45).Unit)
   local first=k<8
   clods:Emit(count(first and 10 or 4))
   if first or k%2==0 then dust:Emit(count(first and 3 or 1))end
   if sparks then sparks:Emit(first and 4 or 1)end
   pip(.38,first and .22 or .1,digger,true)
   if first then pip(LADDER[k+1]*1.1,.18,digger)end
  end
 end
 if not faded then
  if not waitStage(DUG-.8)then return end
  settle()
 end
 if not ctx:Wait(hold)then return end
end
