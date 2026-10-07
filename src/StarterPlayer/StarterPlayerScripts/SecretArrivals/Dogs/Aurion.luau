-- AURION, "PRISM". Won at the DOG-O-MATIC jackpot (a Studio preview without the machine
-- stages it in front of the tester instead), and the whole island sees it:
--  0     night falls on every sky and an aurora opens over every player; a thread of white
--        light falls out of the heavens onto the machine, seen from every yard.
--  .8    it strikes a prism hanging high over the machine; every dog on the island looks up.
--  1.0   the prism splits it into nine colours that reach across the island: onto the yards,
--        the tongue, the welcome hub, the shops, the lab and the dig site. Every camera that
--        is free is pulled to the machine (the winner is already in the machine's own).
--  1.4   the stand act it always had, 1.4 s later: the thread runs on down to a small prism
--        over the stand, which fans nine colours onto it, and at 2.6 Aurion forms out of
--        them while a hologram Aurion forms in every sky.
--  3.7   PrismEcho: ten rings, each its own colour, ripple out of the stand across the whole
--        island; every lamp on the island takes each colour as it passes, and every player
--        hears its note as it reaches them.
--  5.8   both prisms shatter: ✦ DOG-O-MATIC JACKPOT ✦ AURION across every screen, and the
--        light rains down as rainbow shards around every player.
--  8.4   the aurora, the hologram and the lamps fade; the night lifts by the end of the hold.
-- SecretArrivalConfig.Dogs.Aurion must agree with T: Hold 10, Sniff at T.Local, PrismEcho
-- at T.Echo, Happy at T.Climax.
local Players=game:GetService('Players')
local C=Color3.fromRGB
local WHITE=Color3.new(1,1,1)
local GLASS=C(205,238,255)
local UPRIGHT=CFrame.Angles(0,0,math.pi/2)
local UP=Vector3.yAxis
local TICK='rbxasset://sounds/volume_slider.ogg'
-- The echo climbs a pentatonic scale; the tenth lands two octaves up.
local NOTES={0,2,4,7,9,12,14,16,19,24}
-- The act on the arrival clock. The stand's own act starts at T.Local.
local T={Strike=.8,Fan=1.0,Local=1.4,Form=2.6,Echo=3.7,Climax=5.8,Fade=8.4}
-- Seconds between echoes; island rings grow out to the far corner in RING_T seconds.
local GAP,RING_T,RING_R0=.17,3.2,17
-- The sky prism hangs this high over the stand (clear of the machine's paw crown, seen over
-- the north district from the yards); the thread falls from this high.
local SKY_UP,HEAVEN=150,1150
-- Where the nine colours land, spread round the island as the machine (its north-west
-- corner) sees it, at least 4 degrees apart: Foundry, Lantern, the tongue's stage, Bricklane,
-- Coalhouse, the welcome hub, the shops, the lab and the dig site (yards and
-- NavigationAnchors, studs). The west yards lie in one line from the machine, so only two.
local TARGETS={Vector3.new(-160,1,-110),Vector3.new(-110,1,100),Vector3.new(0,2,-150),Vector3.new(60,1,-110),
 Vector3.new(110,1,40),Vector3.new(0,3,377),Vector3.new(94,3,335),Vector3.new(78,3,477),Vector3.new(38,3,575)}
-- The machine's camera hooks (RewardMachineRig.CameraHooks), if they are not streamed in.
local HOOKS={WideCamera=Vector3.new(-30,47,648),RevealCamera=Vector3.new(-89,14,644),RevealFocus=Vector3.new(-119,7,630)}
-- The island's lamps between colours.
local AURORA=C(120,226,255)
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
-- Every light in the district, gathered a slice per frame (the district is ~37k instances).
local function gather(alive:()->boolean):{Light}
 local found={}
 local district=workspace:FindFirstChild('DOGROTS_District')
 if not district then return found end
 local stack:{Instance}={district}
 local seen=0
 while #stack>0 do
  local o=table.remove(stack)::Instance
  for _,c in ipairs(o:GetChildren())do
   seen+=1
   if c:IsA('Light')then table.insert(found,c)else table.insert(stack,c)end
  end
  if seen>=1500 then seen=0;task.wait();if not alive()then return found end end
 end
 return found
end

return function(ctx)
 ctx.ManualBanner=true
 local Kit,scope,model,config=ctx.Kit,ctx.Scope,ctx.Model,ctx.Config
 ctx.WhisperStyle={Font=Enum.Font.JosefinSans,Color=C(212,240,255),Type=.04}
 local low,origin,hold=ctx.Low,ctx.Origin,config.Hold
 local calm=Kit.ReducedMotion()
 local machine=ctx.Venue=='Machine'
 local size=Kit.Size(model)
 local prismAt=origin+Vector3.new(0,math.max(7,size.Y+1.4),0)
 local skyAt=origin+Vector3.new(0,SKY_UP,0)
 local top=skyAt-Vector3.new(0,9,0)
 local function near()return Kit.Near(origin,120)end
 -- One-shots fire on time only: a late joiner gets the state, not a pile-up of cues
 -- (a short hitch still plays them, so the ten echoes stay ten).
 local joined=ctx:Elapsed()
 local function fresh(t,window)return t>joined-(window or .35)and ctx:Elapsed()-t<.6 end
 -- Reduced motion: the echo pulses (~6 a second) only tint, they do not flash.
 local gain=calm and .35 or 1
 local function cue(kind,volume)local n=near();if n>.05 then Kit.Cue(kind,nil,volume*n)end end
 -- One glassy tick of Kit's Chime at any pitch (2D). The tenth echoes.
 local function tone(pitch,volume,echo)
  if volume<.02 or not scope.Alive then return end
  local s=Instance.new('Sound');s.SoundId=TICK;s.Volume=volume;s.PlaybackSpeed=pitch
  local r=Instance.new('ReverbSoundEffect');r.DecayTime=1.8;r.WetLevel=-4;r.Parent=s
  if echo then local e=Instance.new('EchoSoundEffect');e.Delay=.17;e.Feedback=.55;e.DryLevel=0;e.WetLevel=-1;e.Parent=s end
  s.Parent=scope.Folder;s:Play()
  task.delay(3,function()if s.Parent then s:Destroy()end end)
 end
 -- The island rings reach the farthest corner of the district.
 local span=0
 for _,x in ipairs({Kit.Map.Min.X,Kit.Map.Max.X})do
  for _,z in ipairs({Kit.Map.Min.Z,Kit.Map.Max.Z})do span=math.max(span,Vector3.new(x-origin.X,0,z-origin.Z).Magnitude)end
 end
 local WAVE=math.clamp(span+60,300,1000)
 -- Seconds after its start that an echo ring reaches `d` studs from the stand.
 local function reach(d:number):number
  local x=math.clamp((d-RING_R0)/(WAVE-RING_R0),0,1)
  return RING_T*(1-(1-x)^(1/3))
 end

 ---------------------------------------------------------------- night, for everyone
 -- The night the short way round the dial, a blue haze, and bloom for the light.
 local NIGHT={Lighting={ClockTime=23.5,Brightness=1,ExposureCompensation=.12,Ambient=C(40,52,84),OutdoorAmbient=C(62,82,124),
   EnvironmentSpecularScale=.6},
  Atmosphere={Density=.3,Offset=.15,Color=C(120,160,255),Decay=C(196,120,255),Glare=.5,Haze=1.4},
  Grade={TintColor=C(226,236,255),Saturation=.14,Contrast=.1},
  Bloom={Intensity=1,Size=40,Threshold=.8}}
 local sky=joined<T.Fade and scope:Sky(NIGHT,joined<.4 and 1.6 or .5,1.8)or nil
 scope:Duck(.4,1.2)
 -- The aurora: three slow ribbons of light around this player's sky (two on phones).
 local ribbons={}
 for k=1,low and 2 or 3 do
  local a,b=scope:Anchor(origin,'AuroraA'..k),scope:Anchor(origin,'AuroraB'..k)
  local a0=Instance.new('Attachment');a0.Axis=UP;a0.SecondaryAxis=Vector3.xAxis;a0.Parent=a
  local a1=Instance.new('Attachment');a1.Axis=UP;a1.SecondaryAxis=Vector3.xAxis;a1.Parent=b
  local beam=scope:Beam(a0,a1,AURORA,0,{Segments=28,Brightness=1.6,LightInfluence=0,Transparency=NumberSequence.new(1),
   Color=ColorSequence.new({ColorSequenceKeypoint.new(0,C(90,255,170)),ColorSequenceKeypoint.new(.5,C(80,214,255)),
    ColorSequenceKeypoint.new(1,C(190,120,255))})})
  ribbons[k]={A=a,B=b,Beam=beam,Bearing=math.rad(35+120*(k-1)),Phase=k*1.7}
 end

 ---------------------------------------------------------------- the sky prism
 -- A thread of light from the heavens, a prism high over the stand, nine colours across
 -- the island from it.
 local thread=scope:Part({Name='SkyThread',Shape=Enum.PartType.Cylinder,Color=WHITE,Transparency=1,Size=Vector3.new(.1,1,1),CFrame=CFrame.new(skyAt)})
 local halo=scope:Part({Name='SkyThreadGlow',Shape=Enum.PartType.Cylinder,Color=C(170,220,255),Transparency=1,Size=Vector3.new(.1,1,1),CFrame=CFrame.new(skyAt)})
 local tilt=CFrame.Angles(-math.atan(1/math.sqrt(2)),0,0)*CFrame.Angles(0,0,math.pi/4)
 local skyCore=scope:Part({Name='SkyPrismCore',Size=Vector3.one*9,Color=WHITE,Transparency=1,CFrame=CFrame.new(skyAt)})
 local skyShell=scope:Part({Name='SkyPrism',Material=Enum.Material.Glass,Size=Vector3.one*17,Color=GLASS,Transparency=1,CFrame=CFrame.new(skyAt)})
 local skyGlow=(not low)and scope:Light(skyCore,WHITE,60,0)or nil
 local out=Instance.new('Attachment');out.Name='Out';out.Parent=skyCore
 -- Ordered round the prism, so the colours run round the island as a rainbow.
 local aims={}
 for _,target in ipairs(TARGETS)do
  local flat=Vector3.new(target.X-origin.X,0,target.Z-origin.Z)
  -- (Staged elsewhere, a landmark right next to it is pushed out to a proper distance.)
  if flat.Magnitude<120 then target=origin+(flat.Magnitude>1 and flat.Unit or Vector3.xAxis)*200+Vector3.new(0,target.Y-origin.Y,0)end
  table.insert(aims,{Target=target,Angle=math.atan2(flat.Z,flat.X)})
 end
 table.sort(aims,function(a,b)return a.Angle<b.Angle end)
 local floor=RaycastParams.new();floor.FilterType=Enum.RaycastFilterType.Exclude;floor.RespectCanCollide=true
 local ignore:{Instance}={scope.Folder.Parent or scope.Folder}
 for _,p in ipairs(Players:GetPlayers())do if p.Character then table.insert(ignore,p.Character)end end
 floor.FilterDescendantsInstances=ignore
 local streams={}
 for i,aim in ipairs(aims)do
  local color=spectrum((i-1)/9,.65)
  local tip=scope:Anchor(skyAt,'Reach'..i)
  local land=Instance.new('Attachment');land.Parent=tip
  -- Light pools where they land, flat on the ground (a ray finds it where it is streamed).
  local ground=aim.Target
  local hit=workspace:Raycast(ground+Vector3.new(0,40,0),Vector3.new(0,-90,0),floor)
  if hit then ground=hit.Position end
  local pool=scope:Part({Name='Pool',Shape=Enum.PartType.Cylinder,Color=color,Transparency=1,Size=Vector3.new(.25,24,24),
   CFrame=CFrame.new(ground+Vector3.new(0,.15,0))*UPRIGHT})
  streams[i]={Tip=tip,Target=ground,Pool=pool,Color=color,Light=(not low)and scope:Light(pool,color,32,0)or nil,
   Beam=scope:Beam(out,land,color,0,{Segments=2,Brightness=2,Color=ColorSequence.new(WHITE:Lerp(color,.3),color),
    Transparency=NumberSequence.new(.1,.35)}),Landed=false}
 end

 ---------------------------------------------------------------- every lamp on the island
 -- Each lamp turns to the aurora, then takes every echo's colour as its ring passes it.
 local lamps={}
 if joined<T.Fade then
  task.spawn(function()
   local found=gather(function()return scope.Alive end)
   for _,light in ipairs(found)do
    if not scope.Alive then return end
    local parent=light.Parent
    local at:Vector3?=nil
    if parent and parent:IsA('BasePart')then at=parent.Position
    elseif parent and parent:IsA('Attachment')then at=parent.WorldPosition end
    if at then
     -- Sticky: another script's colour change while it is held becomes what comes back.
     local release,update,base=Kit.Layer(light,{Color=light.Color},true)
     table.insert(lamps,{Light=light,Update=update,Base=base,Release=release,
      Delay=reach(Vector3.new(at.X-origin.X,0,at.Z-origin.Z).Magnitude),Key=nil})
    end
   end
  end)
  scope:Add(function()for _,l in ipairs(lamps)do l.Release()end;table.clear(lamps)end)
 end
 -- A lamp's colour at `el` (nil before the light reaches the island); phones step it per echo.
 local function lampColor(l:any,el:number):(Color3?,any)
  if el<T.Strike then return nil,nil end
  local base=l.Base('Color')
  if typeof(base)~='Color3'then return nil,nil end
  local u=(el-T.Echo-(low and 0 or l.Delay))/GAP
  if low then u=math.floor(u)end
  local fade=smooth((el-T.Fade)/1.4)
  local c
  if u<0 then
   local a=low and 1 or smooth((el-T.Strike)/1)
   c=base:Lerp(AURORA,.85*a)
  else
   c=spectrum(math.min(u,9)/10,.55)
   if not low and u<.5 then c=AURORA:Lerp(c,u*2)end
  end
  c=c:Lerp(base,fade)
  if low then return c,(u<0 and -1 or math.min(u,9))+(fade>0 and math.floor(fade*8)*100 or 0)end
  return c,nil
 end

 ---------------------------------------------------------------- the stand
 local vis=scope:Visibility(model)
 local shown
 local function show(v)if v~=shown then shown=v;vis.Set(v)end end
 if ctx:Elapsed()<T.Form+.8 then show(1)end
 -- The prism: a neon heart in a glass shell, both balanced on a vertex.
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
 local aura=scope:Highlight(model,WHITE,WHITE,1,1)
 local skins,motes={},{}
 -- At the machine the tenth ring reaches the stage's orbit lights and paints them a colour wheel.
 local rim={}
 if machine then
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
 -- The stand, on its own clock (el = seconds since T.Local), as it always was.
 scope:Every(function()
  local now=ctx:Elapsed()
  local el=now-T.Local
  local p=math.exp(-math.max(now-pulseAt,0)*7)*gain
  -- The thread of light runs on down from the sky prism in .3 s, holds, and is cut when
  -- the prism breaks.
  local fall=math.clamp(el/.3,0,1)^2
  local w=.3*(1-smooth((el-4.4)/.2))
  if fall>0 and w>.01 then
   local bottom=top:Lerp(prismAt+Vector3.new(0,.6,0),fall)
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
   aura.FillColor=sweep:Lerp(pulseColor,blend)
   aura.FillTransparency=math.min(.15+.85*smooth((el-1.6)/.8),1-.4*p)
   aura.OutlineColor=sweep:Lerp(config.Color:Lerp(pulseColor,p),blend)
   aura.OutlineTransparency=(.05+.7*blend-.6*p*blend)*(1-fade)+fade
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

 ---------------------------------------------------------------- the island, every frame
 local holo,holoParts,holoKey,holoTint=nil,{},nil,nil
 local passed={}
 local skyShards:{any}={}
 scope:Every(function()
  local el=ctx:Elapsed()
  local cam=workspace.CurrentCamera
  local eye=cam and cam.CFrame.Position or origin
  local p=math.exp(-math.max(el-pulseAt,0)*7)*gain
  local cut=smooth((el-T.Climax)/.3)
  -- The thread falls out of the heavens (accelerating), and climbs back up once the prism
  -- has broken.
  local fall=math.clamp(el/T.Strike,0,1)^2
  local back=smooth((el-T.Climax)/.7)
  local heaven=skyAt+Vector3.new(0,HEAVEN,0)
  local bottom=heaven:Lerp(skyAt,fall):Lerp(heaven,back)
  local length=(heaven-bottom).Magnitude
  if length>1 and back<1 then
   local w=7*(1+.3*p)
   thread.Size=Vector3.new(length,w,w);thread.CFrame=CFrame.new((heaven+bottom)/2)*UPRIGHT;thread.Transparency=.05
   halo.Size=Vector3.new(length,w*3,w*3);halo.CFrame=thread.CFrame;halo.Transparency=.84
  else thread.Transparency=1;halo.Transparency=1 end
  -- The sky prism, lit by the strike, turning, flaring with every echo, until it breaks.
  local struck=smooth((el-(T.Strike-.25))/.3)
  if el<T.Climax and struck>0 then
   local cf=CFrame.new(skyAt+Vector3.new(0,math.sin(el*1.3)*1.5,0))
   skyCore.CFrame=cf*CFrame.Angles(0,-el*.8,0)*tilt;skyShell.CFrame=cf*CFrame.Angles(0,el*.5,0)*tilt
   skyCore.Transparency=1-.95*struck;skyShell.Transparency=1-.5*struck
   skyCore.Color=WHITE:Lerp(pulseColor,p*.85);skyShell.Color=GLASS:Lerp(pulseColor,p*.6)
   if skyGlow then skyGlow.Brightness=2.5*struck+3*p;skyGlow.Color=WHITE:Lerp(pulseColor,p)end
  else
   skyCore.Transparency=1;skyShell.Transparency=1
   if skyGlow then skyGlow.Brightness=0 end
  end
  -- Nine colours run out across the island, land in pools, swell with the echoes and go
  -- out when the prism breaks.
  for i,s in ipairs(streams)do
   local tip=out3((el-T.Fan-(i-1)*.05)/.6)
   local landed=smooth((tip-.85)/.15)
   s.Tip.CFrame=CFrame.new(skyAt:Lerp(s.Target,tip))
   local on=tip*(1-cut)*(1+.5*p)
   s.Beam.Width0=2.4*on;s.Beam.Width1=(3+9*landed)*on
   local pool=landed*(1-smooth((el-T.Climax)/2))
   s.Pool.Transparency=1-.5*pool
   if s.Light then s.Light.Brightness=2*pool*(1+.5*p)end
   if landed>=1 and not s.Landed then
    s.Landed=true
    -- A chime where it lands, heard by whoever is in that yard.
    if fresh(T.Fan+(i-1)*.05+.6,.5)then Kit.Cue('Chime',s.Pool,.5)end
   end
  end
  -- The aurora, around this player wherever they are.
  local open=smooth((el-.3)/1.6)*(1-smooth((el-T.Fade)/1.4))
  for k,r in ipairs(ribbons)do
   local u=Vector3.new(math.sin(r.Bearing),0,math.cos(r.Bearing))
   local side=Vector3.new(u.Z,0,-u.X)
   local mid=Vector3.new(eye.X,0,eye.Z)+u*620+Vector3.new(0,eye.Y+110+30*k,0)
   r.A.CFrame=CFrame.new(mid-side*640);r.B.CFrame=CFrame.new(mid+side*640)
   local wave=el*.6+r.Phase
   r.Beam.CurveSize0=90*math.sin(wave);r.Beam.CurveSize1=70*math.cos(wave*1.3)
   r.Beam.Width0=(80+20*math.sin(wave*1.7))*open;r.Beam.Width1=(110+20*math.cos(wave))*open
   local glimmer={}
   for j,x in ipairs({0,.14,.32,.5,.68,.86,1})do
    local inner=j>1 and j<7
    local v=inner and 1-open*(.42+.2*math.sin(el*1.9+j*1.3+k))or 1
    glimmer[j]=NumberSequenceKeypoint.new(x,math.clamp(v,0,1))
   end
   r.Beam.Transparency=NumberSequence.new(glimmer)
  end
  -- The hologram in this player's sky: Sniff, PrismEcho and Happy with the dog itself,
  -- each echo's colour in turn.
  if holo then
   local key,clip,at,looped
   if el<T.Echo then key,clip,at,looped='Sniff','Sniff',T.Local,false
   elseif el<T.Climax then key,clip,at,looped='Echo','PrismEcho',T.Echo,false
   elseif el<T.Climax+2.1 then key,clip,at,looped='Happy','Happy',T.Climax,false
   else key,clip,at,looped='Idle','Idle',T.Climax+2.1,true end
   if key~=holoKey then
    holoKey=key
    local anim=holo.Animator
    if anim then pcall(function()anim:Play(clip,{StartTime=ctx.Start+at,FadeTime=.25,Looped=looped})end)end
   end
   local echo=(el>=T.Echo and el<T.Climax)and math.min(math.floor((el-T.Echo)/GAP),9)or -1
   if echo~=holoTint then
    holoTint=echo
    local color=echo>=0 and spectrum(echo/10,.62)or config.Color
    for _,part in ipairs(holoParts)do part.Color=color end
   end
  end
  -- Each echo ring sounds its note as it reaches this player (at the stand, the stand's own
  -- tones play instead).
  local d=Vector3.new(eye.X-origin.X,0,eye.Z-origin.Z).Magnitude
  local far=1-near()
  if far>.05 and d<=WAVE then
   local after=reach(d)
   for i=1,10 do
    local at=T.Echo+(i-1)*GAP+after
    if not passed[i]and el>=at then
     passed[i]=true
     if el-at<.3 and at>joined then tone(.9*2^(NOTES[i]/12),(.2+.02*i)*far,i==10)end
    end
   end
  end
  -- The sky prism's shards falling out of the sky.
  for j=#skyShards,1,-1 do
   local s=skyShards[j]
   local age=el-s.Born
   local pos=s.From+s.Velocity*age-Vector3.new(0,30*age*age,0)
   s.Part.CFrame=CFrame.new(pos)*CFrame.Angles(s.Spin.X*age,s.Spin.Y*age,s.Spin.Z*age)
   s.Part.Transparency=smooth((age-1.4)/.8)
   if age>=2.2 or pos.Y<origin.Y then s.Part:Destroy();table.remove(skyShards,j)end
  end
  return true
 end)

 -- Every lamp on the island, on its own step (phones: only when the colour steps; else half
 -- of them a frame, and only the ones the client has lit).
 local turn=0
 scope:Every(function()
  turn+=1
  local el=ctx:Elapsed()
  if el<T.Strike then return true end
  if el>=T.Fade+1.5 then return false end
  for i,l in ipairs(lamps)do
   if low or (i+turn)%2==0 then
    if low or l.Light.Enabled then
     local color,key=lampColor(l,el)
     local last=l.Last
     if color and(if low then key~=l.Key else(not last or math.abs(color.R-last.R)+math.abs(color.G-last.G)+math.abs(color.B-last.B)>.004))then
      l.Key,l.Last=key,color;l.Update('Color',color)
     end
    end
   end
  end
  return true
 end)

 ---------------------------------------------------------------- the cutaway
 -- Every free camera (not the winner's: the machine already holds it) is pulled to the
 -- machine: wide on the falling light and the fan of colours, down onto the stand as Aurion
 -- forms, close for the echoes and the shatter. Off the machine, the same around the spot.
 local shots
 if machine then
  local function hook(name:string):Vector3
   local district=workspace:FindFirstChild('DOGROTS_District')
   local attraction=district and district:FindFirstChild('37_AttractionRefresh')
   local rig=attraction and attraction:FindFirstChild('RewardMachineRig')
   local hooks=rig and rig:FindFirstChild('CameraHooks')
   local part=hooks and hooks:FindFirstChild(name)
   return part and part:IsA('BasePart')and part.Position or HOOKS[name]
  end
  local wide,reveal,focusAt=hook('WideCamera'),hook('RevealCamera'),hook('RevealFocus')
  shots={
   {At=T.Fan,CFrame=Kit.Frame(wide,focusAt+Vector3.new(0,SKY_UP*.6,0)),Fov=72},
   {At=T.Form-.1,CFrame=Kit.Frame(wide:Lerp(reveal,.45)+Vector3.new(0,8,0),focusAt+Vector3.new(0,10,0)),Fov=62},
   {At=T.Echo+.3,CFrame=Kit.Frame(reveal,focusAt),Fov=52},
   {At=T.Climax+.9,CFrame=Kit.Frame(reveal:Lerp(focusAt,.2),focusAt+Vector3.new(0,.6,0)),Fov=48},
  }
 else
  -- A shot that would sit inside a building is pulled in front of it.
  local skip:{Instance}={model,scope.Folder}
  for _,p in ipairs(Players:GetPlayers())do if p.Character then table.insert(skip,p.Character)end end
  local clearance=RaycastParams.new();clearance.FilterType=Enum.RaycastFilterType.Exclude
  clearance.FilterDescendantsInstances=skip
  local function shot(eye:Vector3,target:Vector3):CFrame
   local hit=workspace:Raycast(target,eye-target,clearance)
   if hit and(hit.Position-target).Magnitude>6 then eye=hit.Position+(target-hit.Position).Unit*2 end
   return Kit.Frame(eye,target)
  end
  local cam=workspace.CurrentCamera
  local toward=cam and cam.CFrame.Position-origin or Vector3.new(0,0,30)
  local F=Vector3.new(toward.X,0,toward.Z)
  F=F.Magnitude>1 and F.Unit or Vector3.zAxis
  local chest=origin+UP*size.Y*.55
  shots={
   {At=T.Fan,CFrame=shot(origin+F*80+UP*40,origin+UP*SKY_UP*.55),Fov=72},
   {At=T.Form-.1,CFrame=shot(origin+F*36+UP*16,origin+UP*9),Fov=62},
   {At=T.Echo+.3,CFrame=shot(origin+F*15+UP*5,chest),Fov=52},
   {At=T.Climax+.9,CFrame=shot(origin+F*12.5+UP*4.4,chest),Fov=48},
  }
 end
 local cutaway=ctx:Cutaway(shots,{Focus=origin,Bars=.09,Shake=.05})

 ---------------------------------------------------------------- the act
 -- 0: the thread falls out of the heavens (the loops above draw it).
 if fresh(0)then Kit.Cue('Whoosh',nil,.35)end
 local glance
 if not ctx:Wait(T.Strike)then return end
 -- .8: it strikes the sky prism: a bell over the whole island; every dog looks up at it.
 if fresh(T.Strike)then
  Kit.Shot(nil,TICK,.55,.5,{ReverbSoundEffect={DecayTime=5,WetLevel=-2,DryLevel=-2,Density=1,Diffusion=1},
   EqualizerSoundEffect={LowGain=6,MidGain=-2,HighGain=-10}})
  tone(3,.22)
  scope:Burst(skyAt,WHITE,40,{Speed=NumberRange.new(10,30),Lifetime=NumberRange.new(.5,1),Size=NumberSequence.new(4,0)})
 end
 if ctx:Elapsed()<T.Climax then glance=scope:Glance(skyAt,{Exclude=model,Turn=1,Ripple=320})end
 if not ctx:Wait(T.Fan)then return end
 -- 1.0: nine colours across the island.
 if fresh(T.Fan)then Kit.Cue('Whoosh',nil,.4);Kit.Cue('Chime',nil,.3)end
 if not ctx:Wait(T.Local)then return end
 -- 1.4: the stand's thread starts down (the stand's loop); ...
 if fresh(T.Local)then cue('Whoosh',.32)end
 if not ctx:Wait(T.Local+.3)then return end
 -- ...+.3: it strikes the small prism.
 if fresh(T.Local+.3)then
  scope:Pillar(top,prismAt,C(235,245,255),1.4,.8)
  scope:Burst(prismAt,WHITE,14,{Speed=NumberRange.new(1,4),Lifetime=NumberRange.new(.3,.7),Size=NumberSequence.new(.35,0)})
  tone(3,.28*near())
 end
 if not ctx:Wait(T.Local+.6)then return end
 -- ...+.6: nine colours fan down onto the stand (the loop opens them).
 if fresh(T.Local+.6)then cue('Chime',.5)end
 if not ctx:Wait(T.Form)then return end
 -- T.Form: the dog materialises; light glitters off its bones while it forms. A hologram
 -- of it forms in every player's sky.
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
 if fresh(T.Form,.6)then
  for _,e in ipairs(motes)do e.Rate=low and 6 or 14 end
  cue('Whoosh',.2)
 end
 if ctx:Elapsed()<T.Fade then
  local ok,made=pcall(function()
   return ctx:Colossus({Style='Hologram',Color=config.Color,Alpha=.42,Height=170,Distance=520,Elevation=15,
    FadeIn=fresh(T.Form,.6)and 1.4 or .4,Rise=fresh(T.Form,.6)and 70 or 0})
  end)
  if not ok then warn('SecretArrivals Aurion: no hologram',made)end
  holo=ok and made or nil
  if holo then
   for _,o in ipairs((holo.Model::Model):GetDescendants())do
    if o:IsA('BasePart')and o.Name~='RootPart'then table.insert(holoParts,o)end
   end
  end
 end
 if not ctx:Wait(T.Form+.8)then return end
 for _,e in ipairs(motes)do e.Rate=0 end
 -- T.Echo PrismEcho: ten rings, one every GAP, each its own colour and a step higher. Each
 -- one also ripples out across the whole island.
 for i=1,10 do
  local t=T.Echo+(i-1)*GAP
  if not ctx:Wait(t)then return end
  if fresh(t,.15)then
   local tenth=i==10
   local color=spectrum((i-1)/10,.62)
   scope:Ring(origin+Vector3.new(0,.14,0),color,1.6,tenth and 17 or 12.5,tenth and 1.2 or .66,
    {Thickness=tenth and .42 or .26,Alpha=tenth and .02 or .12,Segments=tenth and 28 or 18})
   scope:Ring(origin+Vector3.new(0,4,0),color,RING_R0,WAVE,RING_T,{Thickness=tenth and 4 or 3,Alpha=tenth and .12 or .22,Segments=32})
   tone(.9*2^(NOTES[i]/12),(.26+.02*i)*near(),tenth)
   pulse(color)
   for _,e in ipairs(motes)do e.Color=ColorSequence.new(color);e:Emit(low and 1 or 2)end
  end
 end
 if not ctx:Wait(T.Climax)then return end
 -- T.Climax Happy: both prisms shatter into the colours they held; the jackpot crosses every
 -- screen and the light rains down as shards around every player.
 shattered=true
 local at=core.Position
 core.Transparency=1;shell.Transparency=1
 if glow then glow.Brightness=0 end
 pulse(WHITE)
 if ctx:Elapsed()<T.Climax+1.5 then
  ctx:Banner({Style='Divine',Kicker='✦  DOG-O-MATIC JACKPOT  ✦',Title='AURION',Color=config.Color,Hold=3.6,
   Text=ctx.By and 'won by '..ctx.By or 'the jackpot has been won'})
 else
  -- Too late for the banner: the reveal card instead.
  ctx:Title()
 end
 local rain
 if fresh(T.Climax,.6)then
  scope:Burst(at,rainbow(.6),70,{Lifetime=NumberRange.new(.8,1.8),Speed=NumberRange.new(5,13),Drag=2.4,Acceleration=Vector3.new(0,-8,0),
   RotSpeed=NumberRange.new(-120,120),Rotation=NumberRange.new(0,360),Size=curve({{0,.5},{1,0}}),Transparency=curve({{0,0},{.75,.25},{1,1}})})
  -- Nine shards, each thrown along its own colour's beam.
  local shards={}
  for i,r in ipairs(rays)do
   local a=(i-1)/9*math.pi*2+(ctx:Elapsed()-T.Local)*.22
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
  -- The sky prism breaks too: a rainbow burst over the machine and big shards along each
  -- of the nine colours, seen from the yards.
  local from=skyCore.Position
  scope:Burst(from,rainbow(.6),low and 60 or 120,{Lifetime=NumberRange.new(1.5,3),Speed=NumberRange.new(30,70),Drag=1.2,
   Acceleration=Vector3.new(0,-20,0),RotSpeed=NumberRange.new(-90,90),Rotation=NumberRange.new(0,360),
   Size=curve({{0,5},{1,0}}),Transparency=curve({{0,0},{.7,.2},{1,1}})})
  for i,s in ipairs(streams)do
   local d=s.Target-from
   local flat=Vector3.new(d.X,0,d.Z)
   local dir=flat.Magnitude>1 and flat.Unit or Vector3.xAxis
   local part=scope:Part({Name='SkyShard',Shape=Enum.PartType.Wedge,Color=s.Color,Size=Vector3.new(1.2,6,4),CFrame=CFrame.new(from)})
   table.insert(skyShards,{Part=part,From=from,Born=ctx:Elapsed(),Velocity=dir*Kit.Random(28,44)+Vector3.new(0,Kit.Random(10,24),0),
    Spin=Vector3.new(Kit.Random(-4,4),Kit.Random(-4,4),Kit.Random(-4,4))})
   if i>5 and low then break end
  end
  -- Heard everywhere (the stand's own chime and sting below for those near it).
  Kit.Cue('Chime',nil,.5*(1-near()))
 end
 if ctx:Elapsed()<T.Climax+2 then
  -- (Short-lived, so the last shard has landed before the hold is over.)
  rain=scope:Rain({Texture=Kit.Textures.Spark,Rate=40,Area=120,Height=45,Speed=NumberRange.new(22,30),
   Lifetime=NumberRange.new(1.6,2.2),SpreadAngle=Vector2.new(12,12),LightEmission=1,LightInfluence=0,
   Orientation=Enum.ParticleOrientation.VelocityParallel,Squash=NumberSequence.new(1.6),
   Color=ColorSequence.new(rainbow(.55)),Size=NumberSequence.new(.4),
   Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,.05),NumberSequenceKeypoint.new(.8,.2),NumberSequenceKeypoint.new(1,1)})})
 end
 for _,e in ipairs(motes)do e.Color=ColorSequence.new(config.Color:Lerp(WHITE,.3));e.Rate=low and 1 or 3 end
 local n=near()
 local grade
 if n>.05 and fresh(T.Climax,.6)then
  -- (The banner brings the sting for everyone.)
  cue('Chime',.55)
  if not calm then Kit.Flash(WHITE,1-.28*n,.45)end
  -- The winner is usually inside the machine's scripted camera, which owns the FOV and
  -- restores it on close; a punch tweening back to its mid-session FOV would stick.
  local camera=workspace.CurrentCamera
  if camera and camera.CameraType~=Enum.CameraType.Scriptable then Kit.FOVPunch(-4*n,.18,1.1)end
  local g=math.min(1,n*1.5)
  grade=scope:Grade({Saturation=.3*g,Brightness=.02*g},.3)
 end
 if cutaway and cutaway.Active then cutaway:Shake(.25,.6)end
 if not ctx:Wait(T.Climax+.5)then return end
 if grade then Kit.Tween(grade,1.4,{Saturation=0,Brightness=0},Enum.EasingStyle.Sine)end
 if not ctx:Wait(T.Climax+1.2)then return end
 for _,e in ipairs(motes)do e.Rate=0 end
 if not ctx:Wait(T.Climax+2.2)then return end
 if rain then rain.Rate=0 end
 -- T.Fade: the aurora, the hologram, the lamps and the night let go (the loop eases them),
 -- all gone by the end of the hold.
 if not ctx:Wait(T.Fade)then return end
 if holo then holo:Stop(1.4)end
 if glance then glance:Stop(1.2)end
 if not ctx:Wait(T.Fade+.2)then return end
 if sky then sky:Release(1.4)end
 if not ctx:Wait(T.Fade+1.5)then return end
 for _,l in ipairs(lamps)do l.Release()end
 table.clear(lamps)
 -- (A moment past the hold for the last shards and fades to finish.)
 ctx:Wait(hold+.4)
end
