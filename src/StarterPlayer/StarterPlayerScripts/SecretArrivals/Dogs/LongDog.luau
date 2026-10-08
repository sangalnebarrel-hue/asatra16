-- LONG DOG: "THE HOLE KEPT GOING". Dug up in its owner's yard: the pit cracks open and
-- the dog slides out of it nose-first, steeply, and keeps sliding, and keeps sliding,
-- a fan of glowing after-images trailing back down the hole. It flops out and lands; a
-- depth gauge over the hole runs out of numbers; dirt and bones rain down, the hole shuts.
local Players=game:GetService('Players')
local C=Color3.fromRGB
local SAND,DIRT,DUST,BONE,VOID=C(240,196,120),C(104,72,42),C(196,164,120),C(246,240,224),C(0,0,0)
local TICK='rbxasset://sounds/volume_slider.ogg'
-- Pitch while it slides out: steep at first, flatter the more of it there is.
local P0,P1=math.rad(58),math.rad(34)
-- Starts sliding; the last of it leaves the hole; it lands.
local T0,T1,T2=.4,2.75,3.1
-- After-images {appear, start fading}: they fade one by one, oldest first.
local TRAIL={{.95,2.45},{1.4,2.9},{1.85,3.35},{2.3,3.8},{2.7,4.25}}
local TRAIL_LOW={{1.4,2.9},{2.3,3.8}}
-- The depth gauge after DepthCharge (3.4) speeds up until it runs out of numbers.
local DEPTH:{{any}}={{3.45,'10m'},{3.62,'40m'},{3.78,'150m'},{3.91,'320m'},{4.02,'500m'},{4.11,'1200m'},{4.19,'99999m'},{4.32,'∞'}}
local function smooth(x)x=math.clamp(x,0,1);return x*x*(3-2*x)end

return function(ctx:any)
 ctx.WhisperStyle={Font=Enum.Font.Kalam,Color=C(255,230,186),Type=.06}
 local Kit,scope,config=ctx.Kit,ctx.Scope,ctx.Config
 local model:Model=ctx.Model
 local low,calm,origin,hold=ctx.Low,Kit.ReducedMotion(),ctx.Origin,config.Hold
 local size=Kit.Size(model)
 local length,height=size.Z,size.Y
 local spine=height*.46
 -- Where its spine crosses the ground while it slides out: toward its tail, so that once
 -- it is all out it lands centred on the spot the server holds it at.
 local back=math.min(length*.3,3.2)
 local groundLocal=model:GetAttribute('GroundLocal')
 local unground=CFrame.new(-(typeof(groundLocal)=='Vector3'and groundLocal or Vector3.zero))
 local function near()return Kit.Near(origin,120)end
 local function live(t)return ctx:Elapsed()-t<.35 end

 -- The pit's visible top (the stand point can sit a little under it): the hole goes
 -- there and the dog is lifted onto it for the cinematic.
 local surface=origin.Y
 do
  local skip:{Instance}={model}
  if model.Parent then table.insert(skip,model.Parent)end
  local fx=workspace:FindFirstChild('DOGROTS_SecretArrivalFX');if fx then table.insert(skip,fx)end
  for _,p in ipairs(Players:GetPlayers())do if p.Character then table.insert(skip,p.Character)end end
  local params=RaycastParams.new();params.FilterType=Enum.RaycastFilterType.Exclude
  for _=1,4 do
   params.FilterDescendantsInstances=skip
   local hit=workspace:Raycast(origin+Vector3.new(0,3,0),Vector3.new(0,-6,0),params)
   if not hit then break end
   if hit.Instance.Transparency<.95 then surface=hit.Position.Y;break end
   table.insert(skip,hit.Instance)
  end
 end
 local lift=math.clamp(surface-origin.Y,0,1.5)
 surface=origin.Y+lift

 -- Everything is laid out in the dog's own frame (Origin, its heading). Its pivot only
 -- ever pitches about its right axis here, so the heading can be read at any time;
 -- until the dog streams in, pinned parts wait facing world -Z and are re-laid after.
 local frame,framed=CFrame.new(origin),false
 local pins:{[BasePart]:CFrame}={}
 local function pin(p:BasePart,at:CFrame):BasePart pins[p]=at;p.CFrame=frame*at;return p end
 local function reframe()
  if framed or not Kit.Root(model)then return end
  local r=model:GetPivot().RightVector;r=Vector3.new(r.X,0,r.Z)
  if r.Magnitude<.01 then return end
  frame=CFrame.fromMatrix(origin,r.Unit,Vector3.yAxis);framed=true
  for p,at in pairs(pins)do if p.Parent then p.CFrame=frame*at end end
 end
 reframe()

 -- Its pose: spine point `s` (studs, + toward the tail) sits in the hole, pitched up `p`.
 local function through(s:number,p:number)return CFrame.new(0,lift,back)*CFrame.Angles(p,0,0)*CFrame.new(0,-spine,-s)end
 local s0=-length/2-(height-spine)/math.tan(P0)-.4
 local s1=length/2-.6
 local function slide(t:number)
  local u=math.clamp((t-T0)/(T1-T0),0,1)
  return s0+(s1-s0)*(.65*u+.35*smooth(u)),P0+(P1-P0)*smooth(u)
 end
 local stand=CFrame.new(0,lift,0)
 local function pose(t:number)
  if t<T1 then
   local s,p=slide(t)
   -- A wriggle on the way out (sideways and a nod only: the heading stays readable).
   local w=calm and 0 or smooth((t-T0)/.3)*(1-smooth((t-T1+.4)/.4))
   return CFrame.new(.12*w*math.sin(t*13),0,0)*through(s,p+math.rad(1.5)*w*math.sin(t*9))
  elseif t<T2 then
   -- The tail pops free and it tips over onto its feet.
   local u=(t-T1)/(T2-T1)
   return CFrame.new(0,math.sin(u*math.pi)*.9,0)*through(s1,P1):Lerp(stand,u*u)
  end
  local bounce=t<T2+.3 and .22*math.sin((t-T2)/.3*math.pi)or 0
  -- Back down to the server's stand point before the arrival lets go of it.
  return CFrame.new(0,lift*(1-smooth((t-hold+.6)/.5))+bounce,0)
 end
 local vis=scope:Visibility(model);vis.Set(1)
 local offset=scope:Offset(model);offset.CFrame=pose(ctx:Elapsed())

 local grade=Kit.Near(origin,160)>0 and scope:Grade({TintColor=C(255,241,218),Saturation=.08,Contrast=.06},.6)or nil
 if grade then scope:Duck(.55,.8)end

 -- The hole: loose spoil, a soft dark edge and the black. Oval along the dog's slant.
 local across,along=size.X+3.2,height/math.sin(P1)+.8
 local mid=CFrame.new(0,lift,back+(height-2*spine)/(2*math.sin(P1)))
 -- Cylinder parts are always round (the smaller of Y/Z), so each disc is a sphere mesh
 -- squashed flat: a true oval. Stacked so the black always reads on top of the spoil.
 local function disc(name,y,thick,props)
  local p=scope:Part(props);p.Name=name;p.Size=Vector3.new(.1,thick,.1)
  local mesh=Instance.new('SpecialMesh');mesh.MeshType=Enum.MeshType.Sphere;mesh.Parent=p
  return pin(p,mid*CFrame.new(0,y,0))
 end
 local rim=disc('Spoil',.01,.1,{Material=Enum.Material.Ground,Color=DIRT})
 local shade=disc('HoleEdge',.075,.03,{Color=VOID,Transparency=.45})
 local pit=disc('Hole',.11,.03,{Color=VOID})
 local open:{{Part:BasePart,Size:Vector3}}={
  {Part=rim,Size=Vector3.new(across+1.8,.1,along+1.8)},{Part=shade,Size=Vector3.new(across+.7,.03,along+.7)},
  {Part=pit,Size=Vector3.new(across,.03,along)},
 }
 local mouth=pin(scope:Anchor(origin,'Mouth'),CFrame.new(0,lift+.25,back))
 local glow=not low and scope:Light(mouth,SAND,18,0)or nil
 local trickle=scope:Emitter(mouth,{Color=ColorSequence.new(DIRT),LightEmission=0,LightInfluence=1,Lifetime=NumberRange.new(.5,.9),
  Speed=NumberRange.new(6,12),SpreadAngle=Vector2.new(28,28),Acceleration=Vector3.new(0,-45,0),Size=NumberSequence.new(.4,.15),
  Transparency=NumberSequence.new(0,.3),RotSpeed=NumberRange.new(-180,180)})
 local haze=not low and scope:Emitter(mouth,{Texture=Kit.Textures.Smoke,Color=ColorSequence.new(DUST),LightEmission=0,LightInfluence=1,
  Lifetime=NumberRange.new(1,1.8),Speed=NumberRange.new(1,3),SpreadAngle=Vector2.new(40,40),Size=NumberSequence.new(1.5,3.5),
  Transparency=NumberSequence.new(.6,1)})or nil

 -- Thrown dirt and bones: a little ballistic sim that lands them on the pit.
 local flying:{any}={}
 local function throw(p:BasePart,from:Vector3,velocity:Vector3,rest:number,extra:{any}?)
  local b={Part=p,Pos=from,Vel=velocity,Turn=CFrame.identity,Rest=false,Half=rest,Extra=extra,
   Spin=Vector3.new(Kit.Random(-9,9),Kit.Random(-9,9),Kit.Random(-9,9))}
  table.insert(flying,b);return b
 end
 scope:Every(function(dt)
  dt=math.min(dt,.05)
  for _,b in ipairs(flying)do
   if not b.Rest and b.Part.Parent then
    local v=b.Vel-Vector3.new(0,60*dt,0)
    local at=b.Pos+v*dt
    b.Turn*=CFrame.fromEulerAnglesXYZ(b.Spin.X*dt,b.Spin.Y*dt,b.Spin.Z*dt)
    if at.Y<surface+b.Half and v.Y<0 then
     at=Vector3.new(at.X,surface+b.Half,at.Z)
     if v.Y<-9 then v=Vector3.new(v.X*.45,-v.Y*.3,v.Z*.45)
     else v=Vector3.zero;b.Rest=true;b.Turn=CFrame.Angles(0,Kit.Random(0,math.pi*2),0)end
    end
    b.Vel=v;b.Pos=at
    local cf=CFrame.new(at)*b.Turn
    b.Part.CFrame=cf
    if b.Extra then for _,x in ipairs(b.Extra)do x[1].CFrame=cf*x[2]end end
   end
  end
 end)
 local function clod(from:Vector3,speed:number,up:number)
  local s=Kit.Random(.3,.55)
  local p=scope:Part({Name='Clod',Material=Enum.Material.Ground,Color=DIRT:Lerp(Kit.Random(0,1)<.5 and C(60,40,24)or DUST,Kit.Random(0,.4)),
   Size=Vector3.one*s,CFrame=CFrame.new(from)})
  local a=Kit.Random(0,math.pi*2)
  return throw(p,from,Vector3.new(math.cos(a)*speed,up,math.sin(a)*speed),s/2)
 end
 local function bone(from:Vector3,speed:number,up:number)
  local shaft=scope:Part({Name='Bone',Shape=Enum.PartType.Cylinder,Material=Enum.Material.SmoothPlastic,Color=BONE,
   Size=Vector3.new(.72,.15,.15),CFrame=CFrame.new(from)})
  local knobs={}
  for _,x in ipairs({-.36,.36})do
   for _,z in ipairs({-.08,.08})do
    local k=scope:Part({Name='Knob',Shape=Enum.PartType.Ball,Material=Enum.Material.SmoothPlastic,Color=BONE,Size=Vector3.one*.2,CFrame=CFrame.new(from)})
    table.insert(knobs,{k,CFrame.new(x,0,z)})
   end
  end
  local a=Kit.Random(0,math.pi*2)
  return throw(shaft,from,Vector3.new(math.cos(a)*speed,up,math.sin(a)*speed),.1,knobs)
 end
 local function sweep(list:{any},seconds:number)
  for _,b in ipairs(list)do
   local parts={b.Part}
   for _,x in ipairs(b.Extra or {})do table.insert(parts,x[1])end
   for _,p in ipairs(parts)do
    if p.Parent then Kit.Tween(p,seconds,{Transparency=1}).Completed:Connect(function()p:Destroy()end)end
   end
  end
 end

 -- After-images: frozen glowing copies of the dog at the poses it slid through.
 local ghosts:{any}={}
 local trail=low and TRAIL_LOW or TRAIL
 local function ghost(k)
  local at,fade=trail[k][1],trail[k][2]
  if ctx:Elapsed()>fade+.4 or not Kit.Root(model)then return end
  local g=scope:Ghost(model)
  local parts:{BasePart}={}
  for _,o in ipairs(g:GetDescendants())do
   if o:IsA('SurfaceAppearance')then o:Destroy()
   elseif o:IsA('BasePart')then
    local part=o::BasePart
    part.Material=Enum.Material.Neon;part.Color=SAND;part.LocalTransparencyModifier=1
    if part:IsA('MeshPart')then pcall(function()(part::any).TextureID=''end)end
    table.insert(parts,part)
   end
  end
  local s,p=slide(at)
  table.insert(ghosts,{Model=g,Parts=parts,S=s,P=p,At=at,Fade=fade,Alpha=.45+.06*(#trail-k)})
 end

 -- Every frame, on the server clock: the dog's pose and the after-images, which keep
 -- creeping out of the hole after it has landed (it is still coming out).
 scope:Every(function()
  reframe()
  local t=ctx:Elapsed()
  offset.CFrame=pose(t)
  for i=#ghosts,1,-1 do
   local g=ghosts[i]
   -- Removed when its fade-out ends (it is also fully clear at the instant it appears).
   if t>=g.Fade+.5 or not g.Model.Parent then
    g.Model:Destroy();table.remove(ghosts,i)
   else
    local a=g.Alpha+(1-g.Alpha)*math.max(1-math.clamp((t-g.At)/.12,0,1),smooth((t-g.Fade)/.5))
    g.Model:PivotTo(frame*through(g.S+math.max(t-T2,0)*.9,g.P)*unground)
    for _,part in ipairs(g.Parts)do part.LocalTransparencyModifier=a end
   end
  end
 end)

 -- 0: the ground cracks, the hole opens, dirt spurts. Nothing has come out yet.
 local fresh=live(0)
 local cracks={}
 for i=1,low and 3 or 6 do
  local n=low and 3 or 6
  local dir=mid*CFrame.Angles(0,(i+Kit.Random(-.3,.3))/n*math.pi*2,0)
  local len=Kit.Random(2.2,3.6)+along*.4
  local p=pin(scope:Part({Name='Crack',Color=VOID,Size=Vector3.new(.2,.06,len)}),dir*CFrame.new(0,0,-len/2))
  if fresh then
   p.Size=Vector3.new(.2,.06,.1);p.CFrame=frame*dir
   Kit.Tween(p,.22,{Size=Vector3.new(.2,.06,len),CFrame=frame*dir*CFrame.new(0,0,-len/2)})
  end
  cracks[i]=p
 end
 for i,o in ipairs(open)do
  if fresh then
   task.delay(.04+(3-i)*.03,function()if o.Part.Parent then Kit.Tween(o.Part,.45,{Size=o.Size},Enum.EasingStyle.Back)end end)
  else o.Part.Size=o.Size end
 end
 local spoil={}
 if fresh then
  local at=frame*Vector3.new(0,lift+.3,back)
  scope:Burst(at,DIRT,40,{LightEmission=0,LightInfluence=1,Speed=NumberRange.new(14,26),SpreadAngle=Vector2.new(30,30),
   Acceleration=Vector3.new(0,-60,0),Lifetime=NumberRange.new(.7,1.2),Size=NumberSequence.new(.5,.25),Transparency=NumberSequence.new(0,.2),
   RotSpeed=NumberRange.new(-200,200)})
  scope:Burst(at,DUST,18,{Texture=Kit.Textures.Smoke,LightEmission=0,LightInfluence=1,Speed=NumberRange.new(4,10),
   SpreadAngle=Vector2.new(70,70),Drag=3,Lifetime=NumberRange.new(.9,1.5),Size=NumberSequence.new(1.6,4),Transparency=NumberSequence.new(.35,1)})
  if not low then for _=1,8 do table.insert(spoil,clod(at,Kit.Random(5,10),Kit.Random(14,22)))end end
  Kit.Cue('Impact',mouth,.45)
  local n=near();if n>.05 then Kit.Shake(.22*n,.35)end
 end

 -- 0.4: here it comes. And comes. Dirt trickles off it the whole way.
 if not ctx:Wait(T0)then return end
 vis.Set(0)
 local sliding=ctx:Elapsed()<T1-.2
 if sliding then
  trickle.Rate=low and 6 or 22
  if haze then haze.Rate=5 end
  -- A ratchet that winds up for as long as it keeps coming.
  local ratchet=Instance.new('Sound');ratchet.SoundId=TICK;ratchet.Looped=true;ratchet.Volume=.16;ratchet.PlaybackSpeed=.35
  ratchet.RollOffMinDistance=10;ratchet.RollOffMaxDistance=180;ratchet.Parent=mouth;ratchet:Play()
  Kit.Tween(ratchet,T1-ctx:Elapsed(),{PlaybackSpeed=.85},Enum.EasingStyle.Sine,Enum.EasingDirection.In)
  task.delay(math.max(T1-ctx:Elapsed(),0),function()if ratchet.Parent then ratchet:Destroy()end end)
  if live(T0)then Kit.Cue('Whoosh',mouth,.3)end
 end
 local crumbs={}
 if not low and sliding then
  for _,name in ipairs({'Head','LongSeg3','LongSeg6'})do
   local b=model:FindFirstChild(name,true)
   if b and b:IsA('Bone')then
    table.insert(crumbs,scope:Add(scope:Emitter(b,{Color=ColorSequence.new(DIRT),LightEmission=0,LightInfluence=1,Rate=9,
     Lifetime=NumberRange.new(.5,.9),Speed=NumberRange.new(1,3),Acceleration=Vector3.new(0,-40,0),Size=NumberSequence.new(.3,.12),
     Transparency=NumberSequence.new(0,.3)})))
   end
  end
 end
 for k in ipairs(trail)do
  if not ctx:Wait(trail[k][1])then return end
  ghost(k)
 end

 -- 2.75: the tail pops free; 3.1: it lands on its feet.
 if not ctx:Wait(T1)then return end
 if live(T1)then
  scope:Burst(frame*Vector3.new(0,lift+.3,back),DIRT,20,{LightEmission=0,LightInfluence=1,Speed=NumberRange.new(8,16),
   SpreadAngle=Vector2.new(45,45),Acceleration=Vector3.new(0,-50,0),Lifetime=NumberRange.new(.5,.9),Size=NumberSequence.new(.4,.2)})
  Kit.Cue('Whoosh',mouth,.35)
 end
 if not ctx:Wait(T2)then return end
 trickle.Rate=0
 if haze then haze.Rate=0 end
 for _,e in ipairs(crumbs)do e.Rate=0 end
 if live(T2)then
  scope:Burst(frame*Vector3.new(0,lift+.3,0),DUST,16,{Texture=Kit.Textures.Smoke,LightEmission=0,LightInfluence=1,
   Speed=NumberRange.new(5,9),SpreadAngle=Vector2.new(85,85),Drag=4,Lifetime=NumberRange.new(.7,1.2),Size=NumberSequence.new(1.2,3),
   Transparency=NumberSequence.new(.4,1)})
  Kit.Cue('Impact',mouth,.3)
  local n=near();if n>.05 then Kit.Shake(.12*n,.25)end
 end

 -- 3.4: DepthCharge. A deep boom from far down; the gauge over the hole starts counting.
 if not ctx:Wait(3.4)then return end
 local hole=frame*Vector3.new(0,lift,back)
 if live(3.4)then
  Kit.Cue('Sting',mouth,.75);Kit.Cue('Impact',mouth,.8)
  scope:Ring(hole+Vector3.new(0,.25,0),DUST,2,15,1.1,{Thickness=.45,Alpha=.3})
  scope:Burst(hole+Vector3.new(0,.5,0),DUST,30,{Texture=Kit.Textures.Smoke,LightEmission=0,LightInfluence=1,Speed=NumberRange.new(8,16),
   SpreadAngle=Vector2.new(80,80),Drag=3,Lifetime=NumberRange.new(1,1.6),Size=NumberSequence.new(1.5,4),Transparency=NumberSequence.new(.3,1)})
  local goal=open[3].Size
  Kit.Tween(pit,.12,{Size=Vector3.new(goal.X*1.15,goal.Y,goal.Z*1.15)}).Completed:Connect(function()
   if pit.Parent then Kit.Tween(pit,.4,{Size=goal},Enum.EasingStyle.Back)end
  end)
  if glow then glow.Brightness=4;Kit.Tween(glow,1.3,{Brightness=0})end
  if grade then grade.Brightness=-.1;Kit.Tween(grade,.9,{Brightness=0})end
  local n=near()
  if n>.05 then Kit.Shake(.35*n,.6);Kit.FOVPunch(6*n,.12,.9)end
 end
 local stake=pin(scope:Anchor(origin,'Gauge'),CFrame.new(0,lift+height+2.4,back))
 local board=Instance.new('BillboardGui');board.Name='DepthGauge';board.AlwaysOnTop=true;board.LightInfluence=0
 board.MaxDistance=260;board.Size=UDim2.new(5.5,36,1.3,10);board.Adornee=stake
 local box=Instance.new('Frame');box.AnchorPoint=Vector2.new(.5,.5);box.Position=UDim2.fromScale(.5,.5);box.Size=UDim2.fromScale(1,1)
 box.BackgroundColor3=C(26,18,10);box.BackgroundTransparency=.2;box.BorderSizePixel=0;box.Parent=board
 local corner=Instance.new('UICorner');corner.CornerRadius=UDim.new(.3,0);corner.Parent=box
 local edge=Instance.new('UIStroke');edge.Color=SAND;edge.Thickness=2;edge.Parent=box
 local pop=Instance.new('UIScale');pop.Scale=live(3.4)and not calm and .2 or 1;pop.Parent=box
 -- KeepFont before it is parented, or the place typography swaps the face.
 local readout=Instance.new('TextLabel');readout.Name='Depth';readout:SetAttribute('KeepFont',true)
 readout.BackgroundTransparency=1;readout.AnchorPoint=Vector2.new(.5,.5);readout.Position=UDim2.fromScale(.5,.5)
 readout.Size=UDim2.new(1,-14,1,-6);readout.Font=Enum.Font.RobotoMono;readout.TextScaled=true;readout.TextColor3=SAND
 readout.TextStrokeColor3=C(20,12,6);readout.TextStrokeTransparency=.4;readout.Text='DEPTH: 0m';readout.Parent=box
 board.Parent=stake
 Kit.Tween(pop,.3,{Scale=1},Enum.EasingStyle.Back)
 for i,step in ipairs(DEPTH)do
  if not ctx:Wait(step[1])then return end
  readout.Text='DEPTH: '..step[2]
  if live(step[1])then
   local s=Instance.new('Sound');s.SoundId=TICK;s.Volume=.3;s.PlaybackSpeed=.8+i*.16
   s.RollOffMinDistance=10;s.RollOffMaxDistance=200;s.Parent=stake;s:Play()
   task.delay(1,function()if s.Parent then s:Destroy()end end)
   if not calm then pop.Scale=1.08;Kit.Tween(pop,.1,{Scale=1})end
  end
 end
 -- It ran out of numbers.
 readout.TextColor3=C(255,255,255);Kit.Tween(readout,.6,{TextColor3=SAND})
 edge.Color=C(255,255,255);Kit.Tween(edge,.6,{Color=SAND})
 if live(DEPTH[#DEPTH][1])then
  if not calm then pop.Scale=1.5;Kit.Tween(pop,.35,{Scale=1},Enum.EasingStyle.Back)end
  Kit.Cue('Glitch',stake,.22)
 end

 -- 4.6: Happy. The card, dirt and bones everywhere, and the hole shuts behind it.
 if not ctx:Wait(4.6)then return end
 ctx:Title({Hold=3.2})
 sweep(spoil,.5)
 for _,o in ipairs(open)do
  local p=o.Part
  Kit.Tween(p,.55,{Size=Vector3.new(.1,o.Size.Y,.1)},Enum.EasingStyle.Back,Enum.EasingDirection.In).Completed:Connect(function()p:Destroy()end)
 end
 for _,p in ipairs(cracks)do Kit.Tween(p,.5,{Transparency=1}).Completed:Connect(function()p:Destroy()end)end
 local party={}
 if live(4.6)then
  Kit.Cue('Chime',mouth,.55)
  local n=near()
  if n>.05 then Kit.Flash(SAND,1-.25*n,.5)end
  local shine=scope:Highlight(model,SAND,C(255,244,214),.5,0)
  Kit.Tween(shine,.9,{FillTransparency=1,OutlineTransparency=1})
  if grade then grade.Brightness=.1;Kit.Tween(grade,.7,{Brightness=0})end
  scope:Burst(hole+Vector3.new(0,.4,0),DUST,14,{Texture=Kit.Textures.Smoke,LightEmission=0,LightInfluence=1,Speed=NumberRange.new(3,7),
   SpreadAngle=Vector2.new(80,80),Drag=3,Lifetime=NumberRange.new(.6,1),Size=NumberSequence.new(1,2.6),Transparency=NumberSequence.new(.4,1)})
  local from=frame*Vector3.new(0,lift+height*.85,0)
  if low then
   scope:Burst(from,DIRT,36,{LightEmission=0,LightInfluence=1,Speed=NumberRange.new(10,18),Acceleration=Vector3.new(0,-30,0),
    Lifetime=NumberRange.new(1,1.5),Size=NumberSequence.new(.45,.3),Transparency=NumberSequence.new(0,.3)})
   scope:Burst(from,BONE,20,{LightEmission=.3,Speed=NumberRange.new(10,18),Acceleration=Vector3.new(0,-30,0),
    Lifetime=NumberRange.new(1,1.5),Size=NumberSequence.new(.5,.3)})
  else
   for _=1,14 do table.insert(party,clod(from,Kit.Random(4,11),Kit.Random(16,26)))end
   for _=1,5 do table.insert(party,bone(from,Kit.Random(4,10),Kit.Random(18,28)))end
  end
 end

 -- The gauge floats off; the mess fades before the arrival ends.
 if not ctx:Wait(5.5)then return end
 Kit.Tween(board,.6,{StudsOffsetWorldSpace=Vector3.new(0,2,0)})
 Kit.Tween(box,.6,{BackgroundTransparency=1});Kit.Tween(edge,.6,{Transparency=1})
 Kit.Tween(readout,.6,{TextTransparency=1,TextStrokeTransparency=1})
 if not ctx:Wait(6.2)then return end
 sweep(party,.6)
 ctx:Wait(hold)
end
