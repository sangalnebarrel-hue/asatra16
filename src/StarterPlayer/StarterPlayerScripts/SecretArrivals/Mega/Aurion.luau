-- AURION, island-wide: "AURORA PRISM". Night falls over the whole island. A colossal prism
-- crystal descends over the stand where Aurion was won and a thread of white light falls
-- from the zenith onto it (.3, the local prism's strike). At .6 it splits the light: nine
-- coloured beams sweep out to nine points on the island's rim, each landing with a pillar,
-- and above every landing a curtain of that colour unfurls — nine aurora curtains rippling
-- across the entire sky. Prismatic sparkles fall wherever you stand. On PrismEcho (2.3) a
-- rainbow wave rolls across the island and the ten echoes ring out around the prism; at 4.4
-- the prism shatters into the colours it held. The aurora lingers while night lifts.
local C=Color3.fromRGB
local WHITE=Color3.new(1,1,1)
local GLASS=C(205,238,255)
local TICK='rbxasset://sounds/volume_slider.ogg'
-- A cube balanced on a vertex (the local prism's pose), and a cylinder stood upright.
local TILT=CFrame.Angles(-math.atan(1/math.sqrt(2)),0,0)*CFrame.Angles(0,0,math.pi/4)
local UPRIGHT=CFrame.Angles(0,0,math.pi/2)
local STRIKE,FAN,ECHO,SHATTER=.3,.6,2.3,4.4
-- The echo climbs the same pentatonic scale as the stage; the tenth lands two octaves up.
local NOTES={0,2,4,7,9,12,14,16,19,24}
local function smooth(x)x=math.clamp(x,0,1);return x*x*(3-2*x)end
local function out3(x)x=math.clamp(x,0,1);return 1-(1-x)^3 end
local function spectrum(h,s)return Color3.fromHSV(h%1,s or .6,1)end
local function rainbow(s)
 local k={}
 for i=0,6 do k[i+1]=ColorSequenceKeypoint.new(i/6,spectrum(i/6*.83,s))end
 return k
end

return function(m)
 local low=m.Low
 -- Over the stand it was won at (the DOG-O-MATIC), or the factory roof if it ever walks.
 local base=m.Venue=='Tongue'and m.Head or m:Ground(m.Origin)
 local home=base+Vector3.new(0,140,0)
 local zenith=home+Vector3.new(0,760,0)
 local floorY=m:Ground(m.Center).Y
 -- One glassy tick at any pitch, heard by the whole island.
 local function tone(pitch,volume,echo)
  local s=Instance.new('Sound');s.SoundId=TICK;s.Volume=volume;s.PlaybackSpeed=pitch
  local r=Instance.new('ReverbSoundEffect');r.DecayTime=2.4;r.WetLevel=-2;r.Parent=s
  if echo then local e=Instance.new('EchoSoundEffect');e.Delay=.2;e.Feedback=.55;e.DryLevel=0;e.WetLevel=-1;e.Parent=s end
  s.Parent=m.Scope.Folder;s:Play()
  task.delay(4,function()if s.Parent then s:Destroy()end end)
 end

 -- Night falls; the light that is coming is the only colour left.
 local sky=m:Sky({ClockTime=.5,Brightness=.8,Ambient=C(38,50,96),OutdoorAmbient=C(54,72,130),ExposureCompensation=.15},2.5,5)
 local grade=m:Grade({TintColor=C(222,236,255),Saturation=.2,Contrast=.08},1.5,3)
 m:Bloom(.55,36,.95,2,3)
 m:Duck(.5,1)
 if m:Fresh(0,.6)then m:Cue('Whoosh',nil,.4)end

 -- The prism: a neon heart in a glass shell inside a shimmering halo, ~35 studs across.
 local shell=m:Part({Name='PrismShell',Material=Enum.Material.Glass,Color=GLASS,Size=Vector3.one*34,Transparency=1})
 local core=m:Part({Name='PrismCore',Color=WHITE,Size=Vector3.one*16,Transparency=1})
 local halo=m:Part({Name='PrismHalo',Shape=Enum.PartType.Ball,Material=Enum.Material.ForceField,Color=m.Color,Size=Vector3.one*70,Transparency=1})
 local light=m:Light(core,WHITE,60,0)
 local thread=m:Part({Name='Thread',Shape=Enum.PartType.Cylinder,Color=WHITE,Size=Vector3.one,Transparency=1})
 local prismPos=home+Vector3.new(0,300,0)

 -- Nine colours, each bound for a point on the island's rim; a curtain unfurls above each.
 local rays={}
 for i=1,9 do
  local a=(i-1)/9*math.pi*2+.35
  local rim=m.Center+Vector3.new(math.cos(a)*560,0,math.sin(a)*560)
  local color=spectrum((i-1)/9)
  rays[i]={Color=color,Target=m:Ground(rim)+Vector3.new(0,2,0),At=FAN+(i-1)*.09,Landed=false,
   Line=m:Line(home,home+Vector3.new(0,-1,0),color,1,{Name='Ray',Transparency=1})}
 end
 -- The curtains: rows of tall thin slabs along wavy lines high over the island, z -330..860.
 local SLABS,HALF=low and 7 or 13,680
 local width=2*HALF/SLABS*1.18
 local curtains={}
 for i=1,9 do
  local theta=math.rad(((i*53)%50)-25)
  local dir=Vector3.new(math.cos(theta),0,math.sin(theta))
  local c={Color=spectrum((i-1)/9,.55),P=Vector3.new(((i%3)-1)*110,0,-330+(i-1)*148),Dir=dir,Normal=Vector3.new(-dir.Z,0,dir.X),
   Base=250+(i%4)*32,H=150+(i%3)*35,A=45+(i%3)*22,Lambda=210+(i%4)*45,Speed=.3+(i%3)*.11,Phase=i*1.7,
   Unfurl=rays[i].At+.65,Slabs={}}
  for j=1,SLABS do c.Slabs[j]=m:Part({Name='Aurora',Color=c.Color,Size=Vector3.new(width,c.H,1.2),Transparency=1})end
  curtains[i]=c
 end

 -- Every echo tints the prism, the beams and the curtains in its colour for a moment.
 local pulseAt,pulseColor=-math.huge,WHITE
 local function pulse(color)pulseAt,pulseColor=m:Elapsed(),color end
 local shattered=false
 m:Every(function()
  local t=m:Elapsed()
  local p=math.exp(-math.max(t-pulseAt,0)*6)
  -- The prism sinks from high above to hover over the stand, turning slowly.
  if not shattered then
   prismPos=home+Vector3.new(0,(1-out3(t/.6))*300+math.sin(t*1.4)*3,0)
   local appear=smooth(t/.4)
   local struck=smooth((t-STRIKE)/.25)
   shell.CFrame=CFrame.new(prismPos)*CFrame.Angles(0,t*.5,0)*TILT;shell.Transparency=1-appear*.6
   core.CFrame=CFrame.new(prismPos)*CFrame.Angles(0,-t*.9,0)*TILT;core.Transparency=1-appear*(.3+.6*struck)
   core.Color=WHITE:Lerp(pulseColor,p*.85);shell.Color=GLASS:Lerp(pulseColor,p*.5)
   halo.Size=Vector3.one*(70+30*p);halo.CFrame=CFrame.new(prismPos);halo.Transparency=1-appear*struck*(.45+.3*p)
   light.Brightness=3*struck+4*p
  else
   -- The halo blows out with the shards.
   local age=t-SHATTER
   halo.Size=Vector3.one*(70+420*out3(age/.6));halo.CFrame=CFrame.new(prismPos);halo.Transparency=.35+.65*smooth(age/.6)
  end
  -- The thread of white light falls from the zenith in .3 s and is cut when the prism breaks.
  local reach=math.clamp(t/STRIKE,0,1)^2
  local w=10*(1-smooth((t-SHATTER)/.25))
  if reach>0 and w>.05 then
   local bottom=zenith:Lerp(prismPos,reach)
   thread.Size=Vector3.new(math.max((zenith-bottom).Magnitude,.1),w,w);thread.CFrame=CFrame.new((zenith+bottom)/2)*UPRIGHT
   thread.Transparency=.1
  else thread.Transparency=1 end
  -- The fan: each beam races from the prism to its rim point; a pillar marks the landing.
  local gone=smooth((t-SHATTER)/.6)
  for i,r in ipairs(rays)do
   local open=out3((t-r.At)/.5)
   if open>0 and gone<1 then
    m:SetLine(r.Line,prismPos,prismPos:Lerp(r.Target,open),(3+4*p)*(1-gone)+.05)
    r.Line.Color=r.Color:Lerp(WHITE,p*.4);r.Line.Transparency=.15+.85*gone
   else r.Line.Transparency=1 end
   if open>=1 and not r.Landed then
    r.Landed=true
    if m:Fresh(r.At+.5,.5)then
     m:Pillar(r.Target,520,r.Color,22,3.6)
     tone(.9*2^(NOTES[i]/12),.16)
    end
   end
  end
  -- The aurora: every slab sways on its curtain's wave and pulses along it.
  local linger=1-smooth((t-19)/5)
  for _,c in ipairs(curtains)do
   local show=smooth((t-c.Unfurl)/1.6)*linger
   if show<=.001 then
    for _,s in ipairs(c.Slabs)do s.Transparency=1 end
   else
    local color=c.Color:Lerp(pulseColor,p*.4)
    for j,s in ipairs(c.Slabs)do
     local u=(j-.5)/SLABS*2-1
     local x=u*HALF
     local wv=x/c.Lambda+c.Phase+t*c.Speed
     local pos=c.P+c.Dir*x+c.Normal*(c.A*math.sin(wv))
     local tangent=(c.Dir+c.Normal*(c.A/c.Lambda*math.cos(wv))).Unit
     local h=c.H*(.75+.25*math.sin(wv*1.7+t*1.3))
     s.Size=Vector3.new(width,h,1.2)
     s.CFrame=CFrame.fromMatrix(Vector3.new(pos.X,c.Base+h/2+12*math.sin(wv*.8+t*.6),pos.Z),tangent,Vector3.yAxis)
     local glow=.5+.5*math.sin(wv*2.3-t*2.1)
     local edge=math.clamp((1-math.abs(u))*3.5,0,1)
     s.Color=color:Lerp(WHITE,.15*glow)
     s.Transparency=1-show*edge*math.min(.3+.32*glow+.2*p,.85)
    end
   end
  end
  return true
 end)

 -- .3: the thread strikes the prism.
 if not m:Wait(STRIKE)then return end
 if m:Fresh(STRIKE,.5)then
  tone(3,.3);m:Cue('Chime',nil,.45)
  m:Burst(home,WHITE,40,{Speed=NumberRange.new(20,60),Lifetime=NumberRange.new(.6,1.2),Size=NumberSequence.new(4,0)})
 end
 -- 1.2: prismatic sparkles start falling around every player, wherever they are.
 if not m:Wait(1.2)then return end
 local sparkle=m:FollowRain({Rate=45,Texture=m.Kit.Textures.Spark,Color=ColorSequence.new(rainbow(.45)),LightEmission=1,LightInfluence=0,
  Size=NumberSequence.new({NumberSequenceKeypoint.new(0,0),NumberSequenceKeypoint.new(.2,1.1),NumberSequenceKeypoint.new(1,0)}),
  Speed=NumberRange.new(6,12),Lifetime=NumberRange.new(6,9),RotSpeed=NumberRange.new(-90,90),Rotation=NumberRange.new(0,360),
  Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,1),NumberSequenceKeypoint.new(.15,.1),NumberSequenceKeypoint.new(1,1)})},70)

 -- 2.3 PrismEcho: a rainbow wave rolls across the whole island, felt where it reaches you.
 if not m:Wait(ECHO)then return end
 if m:Fresh(ECHO,1)then
  local center=Vector3.new(base.X,floorY,base.Z)
  local wave=m:Shockwave(center,WHITE,{Speed=300,Radius=1150,Height=40,Thickness=2,Alpha=.15,OnPass=function()
   tone(1.6+math.random()*.4,.28,true)
   m:Flash(spectrum(math.random()),.78,.45);m:Shake(.18,.4);m:FOV(-3,.1,.7)
  end})
  -- Each segment wears the colour of its bearing, and the wheel turns as it spreads.
  m:Every(function(_,age)
   if not wave.Parent then return false end
   for _,s in ipairs(wave:GetChildren())do
    local d=s.Position-center
    s.Color=spectrum(math.atan2(d.Z,d.X)/(math.pi*2)+age*.25,.55)
   end
   return true
  end)
 end
 -- The ten echoes ring out around the prism, one every .17 s, each a step higher.
 for i=1,10 do
  local at=ECHO+(i-1)*.17
  if not m:Wait(at)then return end
  if m:Fresh(at,.15)then
   local tenth=i==10
   local color=spectrum((i-1)/10,.62)
   m:Ring(prismPos,color,20,tenth and 300 or 160,tenth and 1.4 or .7,{Thickness=tenth and 4 or 2.2,Alpha=.15,Segments=tenth and 24 or 12})
   tone(.9*2^(NOTES[i]/12),.18+.02*i,tenth)
   pulse(color)
  end
 end

 -- 4.4: the prism shatters into the colours it held.
 if not m:Wait(SHATTER)then return end
 shattered=true
 shell.Transparency=1;core.Transparency=1;light.Brightness=0
 pulse(WHITE)
 if m:Fresh(SHATTER,1.5)then
  local at=prismPos
  m:Burst(at,rainbow(.6),150,{Speed=NumberRange.new(40,120),Lifetime=NumberRange.new(1.5,3),Drag=1.2,Acceleration=Vector3.new(0,-25,0),
   RotSpeed=NumberRange.new(-120,120),Rotation=NumberRange.new(0,360),Size=NumberSequence.new(5,0),
   Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,0),NumberSequenceKeypoint.new(.75,.25),NumberSequenceKeypoint.new(1,1)})})
  -- Nine shards, each thrown out along its own colour's beam.
  local shards={}
  for _,r in ipairs(rays)do
   local d=Vector3.new(r.Target.X-at.X,0,r.Target.Z-at.Z)
   d=d.Magnitude>1 and d.Unit or Vector3.xAxis
   local shard=m:Part({Name='Shard',Shape=Enum.PartType.Wedge,Color=r.Color,Size=Vector3.new(3,30,20),CFrame=CFrame.new(at)})
   table.insert(shards,{Part=shard,Velocity=d*m.Kit.Random(60,90)+Vector3.new(0,m.Kit.Random(40,70),0),
    Spin=Vector3.new(m.Kit.Random(-3,3),m.Kit.Random(-3,3),m.Kit.Random(-3,3))})
  end
  m:Every(function(_,age)
   for _,s in ipairs(shards)do
    s.Part.CFrame=CFrame.new(at+s.Velocity*age-Vector3.new(0,30*age*age,0))*CFrame.Angles(s.Spin.X*age,s.Spin.Y*age,s.Spin.Z*age)
    s.Part.Transparency=smooth((age-1.6)/1.4)
   end
   if age<3 then return true end
   for _,s in ipairs(shards)do s.Part:Destroy()end
   return false
  end)
  for i,step in ipairs({0,4,7,12})do task.delay((i-1)*.09,function()if m:Alive()then tone(1.2*2^(step/12),.3,i==4)end end)end
  m:Cue('Sting',nil,.4)
  m:Flash(WHITE,.55+.3*m:Near(200),.5)
  m:Banner('AURION',{Kicker='✦   T H E   L I G H T   S P L I T   I N T O   N I N E   ✦',Sub=m.VenueText..(m.By and ('  ·  '..string.upper(m.By))or''),
   Font=Enum.Font.JosefinSans,Color=m.Color,Hold=5,Shake=.1})
 end

 -- The sparkles thin out, night lifts, and the curtains fade last.
 if not m:Wait(16)then return end
 sparkle.Rate=0
 if not m:Wait(18)then return end
 if sky then sky.Release()end
 m:Tween(grade,5,{Saturation=0,Contrast=0,TintColor=WHITE})
 m:Wait(m.Config.MegaSeconds or 28)
end
