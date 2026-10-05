-- SPIDERDOG: "IT CAME FROM THE ROOF". The lights in the mouth die. Eight orange eyes open
-- up in the roof and a web is shot across the tunnel, strand by strand. The dog drops in
-- upside down on a silk line, legs scuttling, and creeps down, swinging. The line snaps:
-- it flips, lands, the web tears down behind it, and its eight legs dig, each kick
-- lighting one of the mouth's eight runes. Off the tongue the web is a tent over the pad,
-- the eyes open in a knot of shadow at its top and the legs light eight stakes round it.
local SoundService=game:GetService('SoundService')
local Players=game:GetService('Players')
local C=Color3.fromRGB
local SILK,EMBER,DIRT,CLOD,DUST,DARK=C(240,240,240),C(255,214,170),C(120,85,50),C(78,54,32),C(150,128,104),C(26,16,12)
local TICK='rbxasset://sounds/volume_slider.ogg'
-- Server seconds: the drop onto the silk, the snap, the landing, the first dig.
local DROP,SNAP,LAND,DIG=.7,2.5,2.85,2.9
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
 -- Was this beat on time? (late joiners get the state, not the fanfare)
 local function live(t,slack:number?)return ctx:Elapsed()-t<(slack or .35)end
 local function near()return Kit.Near(origin,120)end
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
  for i=1,10 do
   local slot=(i-1)*3%10
   local a=slot/10*math.pi*2
   anchors[i]=floored(origin+(right*math.cos(a)+fwd*math.sin(a))*10.5)+up*.05
   fan[slot+1]=i
  end
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

 -- 0: the mouth goes dark. The runes wait for the legs; the lamps come back on the landing.
 scope:Duck(.35,.6)
 scope:Drone('Drone',low and .16 or .24,.5,fresh and 1.2 or .3)
 local grade=scope:Grade({Brightness=-.1,Contrast=.12,Saturation=-.3,TintColor=C(226,232,255)},fresh and .7 or .2)
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
 local runes,lamps={},{}
 if venue=='Tongue'then
  local district=workspace:FindFirstChild('DOGROTS_District')
  local factory=district and district:FindFirstChild('02_DogFactory')
  local tunnel=factory and factory:FindFirstChild('DarkMouthTunnel')
  local line=district and district:FindFirstChild('03_DogLine')
  for _,o in ipairs(tunnel and tunnel:GetChildren()or {})do
   if o.Name=='MouthRune'and o:IsA('BasePart')then tint(o,{Color=DARK});table.insert(runes,o)end
  end
  -- The light's Color only: WorldDetailQuality owns its Enabled, and the world-event
  -- lighting saves and restores its Brightness (it would keep our dimmed value).
  for _,lantern in ipairs(line and line:GetChildren()or {})do
   local lens=lantern.Name=='PromenadeLantern'and lantern:FindFirstChild('WarmLens')
   if lens and lens:IsA('BasePart')and (lens.Position-origin).Magnitude<26 then
    tint(lens,{Color=C(48,34,26)});table.insert(lamps,{O=lens,At=lens.Position})
    for _,l in ipairs(lantern:GetDescendants())do
     if l:IsA('PointLight')then tint(l,{Color=C(14,10,7)});table.insert(lamps,{O=l,At=lens.Position})end
    end
   end
  end
  local strip=line and line:FindFirstChild('Tongue')
  for _,g in ipairs(strip and strip:GetChildren()or {})do
   if g.Name=='WarmEdgeGuide'and g:IsA('BasePart')and math.abs((g.Position-origin):Dot(fwd))<30 then
    tint(g,{Color=C(58,40,36),Material=Enum.Material.SmoothPlastic});table.insert(lamps,{O=g,At=g.Position})
   end
  end
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

 -- The web: radial strands shot from the roof point, then spiral threads between them.
 -- Every end is an Attachment on one anchor, moved each frame while the web is alive.
 local webbed=ctx:Elapsed()<LAND+1.2
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
   local e=ctx:Elapsed()
   if settled and e<LAND then return true end
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

 -- 0.2: something in the roof opens its eyes. They blink once and close as it drops.
 if ctx:Elapsed()<DROP+.2 then
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
   local e=ctx:Elapsed()
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

 -- The dog: hidden in the roof until the drop, then on the silk until it lands.
 local hang=ctx:Elapsed()<LAND
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
   local e=ctx:Elapsed()
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
   if lift and lift.Stand and ctx:Elapsed()<LAND then
    local handle=scope:Offset(model);handle.CFrame=lift.CFrame;lift=handle
   end
   return false
  end)
 end

 if live(0)then Kit.Cue('Whoosh',hub,.3)end
 if not ctx:Wait(.2)then return end
 if live(.2)then Kit.Cue('Glitch',hub,.2)end
 if not ctx:Wait(.56)then return end
 if live(.56,.1)then pip(1.6,.12,hub)end
 -- 0.7: it drops in, upside down, legs going (the Run clip).
 if not ctx:Wait(DROP)then return end
 local hl=hang and scope:Highlight(model,ORANGE,C(255,190,140),.92,.5)or nil
 if hang and live(DROP)then
  Kit.Cue('Whoosh',nil,.5);pip(.8,.2,silkEnd,true)
  local n=near();if n>.25 then Kit.FOVPunch(-2.5*n,.25,.9)end
 end
 if not ctx:Wait(1.25)then return end
 if live(1.25)then Kit.Cue('Heartbeat',nil,.5)end
 if not ctx:Wait(1.95)then return end
 if live(1.95)then Kit.Cue('Heartbeat',nil,.6)end
 -- 2.5: the line snaps.
 if not ctx:Wait(SNAP)then return end
 if hang and live(SNAP)then
  pip(4.4,.32,silkEnd);task.delay(.05,pip,3.2,.2,silkEnd)
  scope:Burst(cut,SILK,12,{Speed=NumberRange.new(4,9),Lifetime=NumberRange.new(.25,.5),Size=NumberSequence.new(.3,0)})
 end
 -- 2.85: it lands. The web tears down (its own stepper) and the lamps flicker back on.
 if not ctx:Wait(LAND)then return end
 if live(LAND)then
  local n=near()
  Kit.Cue('Impact',nil,.7);Kit.Cue('Sting',nil,.45)
  if n>.05 then Kit.Shake(.35*n,.4);Kit.Flash(C(255,206,170),1-.22*n,.35)end
  if n>.25 then Kit.FOVPunch(-4*n,.06,.6)end
  scope:Ring(origin+up*.15,DUST,2,14,.6,{Thickness=.32,Alpha=.45})
  if not low then scope:Ring(origin+up*.2,ORANGE,1,9,.45,{Thickness=.18,Alpha=.3,Segments=24})end
  scope:Burst(origin+up*.4,DUST,20,{Texture=Kit.Textures.Smoke,LightEmission=.05,Drag=4,Speed=NumberRange.new(6,12),
   SpreadAngle=Vector2.new(80,80),Lifetime=NumberRange.new(.6,1.1),Size=NumberSequence.new(1.2,3.4),Transparency=NumberSequence.new(.45,1)})
  -- A warm pulse on the grade, like the flash: only near the stage.
  grade.TintColor=C(226,232,255):Lerp(C(255,214,182),n);grade.Brightness=-.1+.15*n
  local flash=hl or scope:Highlight(model,EMBER,ORANGE,.3,.2)
  flash.FillColor=EMBER;flash.FillTransparency=.3;flash.OutlineTransparency=.1
  Kit.Tween(flash,.9,{FillTransparency=1,OutlineTransparency=1})
  task.delay(1,function()if scope.Alive and flash.Parent then flash:Destroy()end end)
 elseif hl then hl:Destroy()end
 Kit.Tween(grade,1.4,{Brightness=-.03,Contrast=.07,Saturation=-.12,TintColor=C(250,242,236)})
 if shadow then Kit.Tween(shadow,.3,{Transparency=1})end
 for _,entry in ipairs(lamps)do
  local o=entry.O
  if live(LAND)then
   local delay=(entry.At-origin).Magnitude*.012
   for _,step in ipairs(FLICKER)do
    task.delay(delay+step[1],function()if scope.Alive then switch(o,step[2],step[3])end end)
   end
  else switch(o,true,.3)end
 end
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
  Kit.Tween(grade,.8,{Brightness=0,Contrast=0,Saturation=0,TintColor=C(255,255,255)})
 end
 for k=0,29 do
  local t=DIG+k*.1
  if t>hold-.3 then break end
  if not faded and t>=hold-.8 then
   if not ctx:Wait(hold-.8)then return end
   settle()
  end
  if not ctx:Wait(t)then return end
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
  if not ctx:Wait(hold-.8)then return end
  settle()
 end
 if not ctx:Wait(hold)then return end
end
