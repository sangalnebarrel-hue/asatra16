-- AURION. Won at the DOG-O-MATIC, it never walks the tongue: a thread of white light falls
-- onto the stand and strikes a floating prism, the prism splits it into nine colours and the
-- dog forms out of them. Its ability (every tenth dig echoes) rings out ten times, the tenth
-- reaching the stage rim, then the prism shatters into the colours it held.
local C=Color3.fromRGB
local WHITE=Color3.new(1,1,1)
local GLASS=C(205,238,255)
local UPRIGHT=CFrame.Angles(0,0,math.pi/2)
local TICK='rbxasset://sounds/volume_slider.ogg'
-- The echo climbs a pentatonic scale; the tenth lands two octaves up.
local NOTES={0,2,4,7,9,12,14,16,19,24}
local function smooth(x)x=math.clamp(x,0,1);return x*x*(3-2*x)end
local function out3(x)x=math.clamp(x,0,1);return 1-(1-x)^3 end
local function spectrum(h,s)return Color3.fromHSV(h%1,s or .6,1)end
local function rainbow(s)
 local k={}
 for i=0,6 do k[i+1]=ColorSequenceKeypoint.new(i/6,spectrum(i/6*.83,s))end
 return k
end
local function setSkin(s,strength,tint)s[1].EmissiveStrength=strength;s[1].EmissiveTint=tint end
local function curve(points)
 local k={}
 for i,p in ipairs(points)do k[i]=NumberSequenceKeypoint.new(p[1],p[2])end
 return NumberSequence.new(k)
end
return function(ctx)
 local Kit,scope,model,config=ctx.Kit,ctx.Scope,ctx.Model,ctx.Config
 ctx.WhisperStyle={Font=Enum.Font.JosefinSans,Color=C(212,240,255),Type=.04}
 local low,origin,hold=ctx.Low,ctx.Origin,config.Hold
 local size=Kit.Size(model)
 -- Compact on purpose: the machine is next to the stand (all within ~20 studs, under 30 up).
 local prismAt=origin+Vector3.new(0,math.max(7,size.Y+1.4),0)
 local top=origin+Vector3.new(0,28,0)
 local function near()return Kit.Near(origin,120)end
 -- One-shots fire on time only: a late joiner gets the state, not a pile-up of cues
 -- (a short hitch still plays them, so the ten echoes stay ten).
 local joined=ctx:Elapsed()
 local function fresh(t,window)return t>joined-(window or .35)and ctx:Elapsed()-t<.6 end
 -- Reduced motion: the echo pulses (~6 a second) only tint, they do not flash.
 local gain=Kit.ReducedMotion()and .35 or 1
 local function cue(kind,volume)local n=near();if n>.05 then Kit.Cue(kind,nil,volume*n)end end
 -- One glassy tick of Kit's Chime at any pitch (2D, by proximity). The tenth echoes.
 local function tone(pitch,volume,echo)
  local v=volume*near()
  if v<.02 then return end
  local s=Instance.new('Sound');s.SoundId=TICK;s.Volume=v;s.PlaybackSpeed=pitch
  local r=Instance.new('ReverbSoundEffect');r.DecayTime=1.8;r.WetLevel=-4;r.Parent=s
  if echo then local e=Instance.new('EchoSoundEffect');e.Delay=.17;e.Feedback=.55;e.DryLevel=0;e.WetLevel=-1;e.Parent=s end
  s.Parent=scope.Folder;s:Play()
  task.delay(3,function()if s.Parent then s:Destroy()end end)
 end
 if near()>.25 then scope:Duck(.5,.8)end
 local vis=scope:Visibility(model)
 local shown
 local function show(v)if v~=shown then shown=v;vis.Set(v)end end
 if ctx:Elapsed()<2 then show(1)end
 -- The prism: a neon heart in a glass shell, both balanced on a vertex.
 local tilt=CFrame.Angles(-math.atan(1/math.sqrt(2)),0,0)*CFrame.Angles(0,0,math.pi/4)
 local core=scope:Part({Name='PrismCore',Size=Vector3.one*.75,Color=WHITE,Transparency=1,CFrame=CFrame.new(prismAt)})
 local shell=scope:Part({Name='Prism',Material=Enum.Material.Glass,Size=Vector3.one*1.45,Color=GLASS,Transparency=1,CFrame=CFrame.new(prismAt)})
 local focus=Instance.new('Attachment');focus.Name='Focus';focus.Parent=core
 local glow=(not low)and scope:Light(core,WHITE,12,0)or nil
 local ray=scope:Part({Name='Ray',Shape=Enum.PartType.Cylinder,Color=WHITE,Transparency=1,Size=Vector3.new(.1,.3,.3),CFrame=CFrame.new(top)})
 -- Nine colours, each a beam from the prism to a pool of light on a radius-7 circle.
 local rays={}
 for i=1,9 do
  local color=spectrum((i-1)/9)
  local spot=scope:Part({Name='Spot',Shape=Enum.PartType.Cylinder,Color=color,Transparency=1,CFrame=CFrame.new(prismAt)})
  spot.Size=Vector3.new(.08,1.3,1.3)
  local land=Instance.new('Attachment');land.Parent=spot
  rays[i]={Spot=spot,Color=color,Light=(not low)and scope:Light(spot,color,7,0)or nil,
   Beam=scope:Beam(focus,land,color,0,{Segments=2,Brightness=2,Color=ColorSequence.new(WHITE:Lerp(color,.35),color),Transparency=NumberSequence.new(.1,.4)})}
 end
 local halo=scope:Highlight(model,WHITE,WHITE,1,1)
 local skins,motes={},{}
 -- At the machine the tenth ring reaches the stage's orbit lights and paints them a colour wheel.
 local rim={}
 if ctx.Venue=='Machine'then
  local district=workspace:FindFirstChild('DOGROTS_District')
  local attraction=district and district:FindFirstChild('37_AttractionRefresh')
  local rig=attraction and attraction:FindFirstChild('RewardMachineRig')
  local orbit=rig and rig:FindFirstChild('OrbitLights')
  for _,p in ipairs(orbit and orbit:GetChildren()or {})do
   if p:IsA('BasePart')then
    local d=p.Position-origin
    local flat=Vector3.new(d.X,0,d.Z).Magnitude
    if flat>6 and flat<16 and math.abs(d.Y)<4 then
     local f=(flat-1.6)/15.4
     table.insert(rim,{Part=p,Color=spectrum(math.atan2(d.Z,d.X)/(math.pi*2),.65),At=3.83+1.2*(1-(1-f)^(1/3))})
    end
   end
  end
 end
 local pulseAt,pulseColor=-math.huge,WHITE
 local function pulse(color)pulseAt,pulseColor=ctx:Elapsed(),color end
 local shattered,settled,lit=false,false,false
 scope:Every(function()
  local el=ctx:Elapsed()
  local p=math.exp(-math.max(el-pulseAt,0)*7)*gain
  -- The thread of light falls in .3 s, holds, and is cut when the prism breaks.
  local reach=math.clamp(el/.3,0,1)^2
  local w=.3*(1-smooth((el-4.4)/.2))
  if reach>0 and w>.01 then
   local bottom=top:Lerp(prismAt+Vector3.new(0,.6,0),reach)
   ray.Size=Vector3.new(math.max((top-bottom).Magnitude,.1),w,w)
   ray.CFrame=CFrame.new((top+bottom)/2)*UPRIGHT
   ray.Transparency=.05
  else ray.Transparency=1 end
  if not shattered then
   local struck=smooth((el-.3)/.25)
   local appear=smooth(el/.25)
   local cf=CFrame.new(prismAt+Vector3.new(0,math.sin(el*2)*.12,0))
   core.CFrame=cf*CFrame.Angles(0,-el*1.9,0)*tilt;shell.CFrame=cf*CFrame.Angles(0,el*1.1,0)*tilt
   core.Transparency=1-appear*(.4+.55*struck);shell.Transparency=1-appear*.55
   core.Color=WHITE:Lerp(pulseColor,p*.85);shell.Color=GLASS:Lerp(pulseColor,p*.6)
   if glow then glow.Brightness=2*struck+2.5*p;glow.Color=WHITE:Lerp(pulseColor,p)end
  end
  -- The fan opens around the circle, turns slowly with the prism, swells on every echo.
  if not settled then
   local gone=smooth((el-4.4)/.4)
   for i,r in ipairs(rays)do
    local open=out3((el-.6-(i-1)*.03)/.42)
    local landed=smooth((open-.7)/.3)*(1-gone)
    local a=(i-1)/9*math.pi*2+el*.22
    local swell=open*(1-gone)*(1+.45*p)
    r.Spot.CFrame=CFrame.new(prismAt:Lerp(origin+Vector3.new(math.cos(a)*7,.06,math.sin(a)*7),open))*UPRIGHT
    r.Spot.Transparency=1-.7*landed
    r.Beam.Width0=.07*swell;r.Beam.Width1=.34*swell
    if r.Light then r.Light.Brightness=1.3*landed*(1+.6*p)end
   end
   settled=gone>=1
  end
  -- The dog forms out of the light: a rainbow sweep that settles into its own colour.
  -- (converges even after a long hitch, so it can never stay hidden)
  if shown~=0 then show(1-smooth((el-1.2)/.8))end
  if el>=1.2 then
   local blend=smooth((el-2)/.4)
   local sweep=spectrum((el-1.2)/.8*.9,.55)
   local fade=smooth((el-5.6)/.7)
   halo.FillColor=sweep:Lerp(pulseColor,blend)
   halo.FillTransparency=math.min(.15+.85*smooth((el-1.6)/.8),1-.4*p)
   halo.OutlineColor=sweep:Lerp(config.Color:Lerp(pulseColor,p),blend)
   halo.OutlineTransparency=(.05+.7*blend-.6*p*blend)*(1-fade)+fade
   -- Its own markings burn bright as it forms, then flare in each echo's colour.
   local k=math.max(p,1-smooth((el-1.7)/.7))
   if #skins>0 and (k>.004 or lit)then
    lit=k>.004
    for _,s in ipairs(skins)do
     pcall(setSkin,s,s[2]+1.4*k,s[3]:Lerp(pulseColor,k))
    end
   end
  end
  for _,r in ipairs(rim)do
   if el>=r.At and el<6.4 then
    if not r.Base then r.Base=r.Part.Color;scope:Override(r.Part,{Color=r.Base})end
    r.Part.Color=r.Base:Lerp(r.Color,smooth((el-r.At)/.12)*(1-smooth((el-5.1)/1.1)))
   end
  end
 end)
 -- 0: a thread of white light falls toward the stand.
 if fresh(0)then cue('Whoosh',.32)end
 if not ctx:Wait(.3)then return end
 -- .3: it strikes the prism.
 if fresh(.3)then
  scope:Pillar(top,prismAt,C(235,245,255),1.4,.8)
  scope:Burst(prismAt,WHITE,14,{Speed=NumberRange.new(1,4),Lifetime=NumberRange.new(.3,.7),Size=NumberSequence.new(.35,0)})
  tone(3,.28)
 end
 if not ctx:Wait(.6)then return end
 -- .6: nine colours fan down onto the stand (the loop opens them).
 if fresh(.6)then cue('Chime',.5)end
 if not ctx:Wait(1.2)then return end
 -- 1.2: the dog materialises; light glitters off its bones while it forms.
 for _,o in ipairs(model:GetDescendants())do
  if o:IsA('SurfaceAppearance')then
   local ok,strength,tint=pcall(function()return o.EmissiveStrength,o.EmissiveTint end)
   if ok then table.insert(skins,{o,strength,tint});scope:Override(o,{EmissiveStrength=strength,EmissiveTint=tint})end
  end
 end
 local bones=low and {'Head','Chest','Body'}or {'Head','Neck','Chest','Body','TailBase','F_Lower.L','F_Lower.R','H_Lower.L','H_Lower.R'}
 local moteProps={Color=ColorSequence.new(rainbow(.45)),Lifetime=NumberRange.new(.4,.8),Speed=NumberRange.new(.4,1.6),Drag=1,
  Size=curve({{0,0},{.25,.3},{1,0}}),Transparency=NumberSequence.new(.1,1)}
 for _,name in ipairs(bones)do
  local bone=model:FindFirstChild(name,true)
  if bone and bone:IsA('Attachment')then table.insert(motes,scope:Add(scope:Emitter(bone,moteProps)))end
 end
 if #motes==0 then
  moteProps.Speed=NumberRange.new(1.5,4)
  table.insert(motes,scope:Emitter(scope:Anchor(origin+Vector3.new(0,size.Y*.5,0),'Motes'),moteProps))
 end
 if fresh(1.2,.6)then
  for _,e in ipairs(motes)do e.Rate=low and 6 or 14 end
  cue('Whoosh',.2)
 end
 if not ctx:Wait(2)then return end
 for _,e in ipairs(motes)do e.Rate=0 end
 -- 2.3 PrismEcho: ten rings, one every .17 s, each its own colour and a step higher.
 for i=1,10 do
  local t=2.3+(i-1)*.17
  if not ctx:Wait(t)then return end
  if fresh(t,.15)then
   local tenth=i==10
   local color=spectrum((i-1)/10,.62)
   scope:Ring(origin+Vector3.new(0,.14,0),color,1.6,tenth and 17 or 12.5,tenth and 1.2 or .66,
    {Thickness=tenth and .42 or .26,Alpha=tenth and .02 or .12,Segments=tenth and 28 or 18})
   tone(.9*2^(NOTES[i]/12),.26+.02*i,tenth)
   pulse(color)
   for _,e in ipairs(motes)do e.Color=ColorSequence.new(color);e:Emit(low and 1 or 2)end
  end
 end
 if not ctx:Wait(4.4)then return end
 -- 4.4 Happy: the card, and the prism shatters into the colours it held.
 ctx:Title()
 shattered=true
 local at=core.Position
 core.Transparency=1;shell.Transparency=1
 if glow then glow.Brightness=0 end
 pulse(WHITE)
 scope:Burst(at,rainbow(.6),70,{Lifetime=NumberRange.new(.8,1.8),Speed=NumberRange.new(5,13),Drag=2.4,Acceleration=Vector3.new(0,-8,0),
  RotSpeed=NumberRange.new(-120,120),Rotation=NumberRange.new(0,360),Size=curve({{0,.5},{1,0}}),Transparency=curve({{0,0},{.75,.25},{1,1}})})
 -- Nine shards, each thrown along its own colour's beam.
 local shards={}
 for i,r in ipairs(rays)do
  local a=(i-1)/9*math.pi*2+ctx:Elapsed()*.22
  local speed=Kit.Random(5,8)
  local shard=scope:Part({Name='Shard',Shape=Enum.PartType.Wedge,Color=r.Color,CFrame=CFrame.new(at)})
  shard.Size=Vector3.new(.08,.42,.3)
  table.insert(shards,{Part=shard,Velocity=Vector3.new(math.cos(a)*speed,Kit.Random(3,6),math.sin(a)*speed),
   Spin=Vector3.new(Kit.Random(-9,9),Kit.Random(-9,9),Kit.Random(-9,9))})
 end
 scope:Every(function(_,age)
  for _,s in ipairs(shards)do
   local pos=at+s.Velocity*age-Vector3.new(0,14*age*age,0)
   s.Part.CFrame=CFrame.new(pos.X,math.max(pos.Y,origin.Y+.15),pos.Z)*CFrame.Angles(s.Spin.X*age,s.Spin.Y*age,s.Spin.Z*age)
   s.Part.Transparency=smooth((age-.55)/.55)
  end
  if age<1.1 then return true end
  for _,s in ipairs(shards)do s.Part:Destroy()end
  return false
 end)
 for _,e in ipairs(motes)do e.Color=ColorSequence.new(config.Color:Lerp(WHITE,.3));e.Rate=low and 1 or 3 end
 local n=near()
 local grade
 if n>.05 then
  cue('Chime',.55);cue('Sting',.4)
  Kit.Flash(WHITE,1-.28*n,.45)
  -- The winner is usually inside the machine's scripted camera, which owns the FOV and
  -- restores it on close; a punch tweening back to its mid-session FOV would stick.
  local camera=workspace.CurrentCamera
  if camera and camera.CameraType~=Enum.CameraType.Scriptable then Kit.FOVPunch(-4*n,.18,1.1)end
  local g=math.min(1,n*1.5)
  grade=scope:Grade({Saturation=.3*g,Brightness=.02*g},.3)
 end
 if not ctx:Wait(4.9)then return end
 if grade then Kit.Tween(grade,1.4,{Saturation=0,Brightness=0},Enum.EasingStyle.Sine)end
 if not ctx:Wait(5.6)then return end
 for _,e in ipairs(motes)do e.Rate=0 end
 ctx:Wait(hold)
end
