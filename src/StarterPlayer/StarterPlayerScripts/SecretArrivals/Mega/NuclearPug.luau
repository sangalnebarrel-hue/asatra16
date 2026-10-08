-- NUCLEAR PUG, island-wide: "MELTDOWN". Air-raid sirens wail over the whole island and the
-- sky turns a sick green while a radar ping sweeps out from the mouth. At 1.6 (the pug's own
-- criticality) the giant head blows its top: a white flash for every player, a mushroom
-- cloud climbs ~300 studs above the factory roof, a condensation ring races out, and a wall
-- of green light rolls across the island, shaking each player the moment it reaches them.
-- A hazard sign hangs over the tongue, glowing ash falls wherever you stand and every
-- Geiger counter on the island crackles. The cloud slowly bleeds away as the pug walks.
-- Off the tongue the blast rises from wherever the pug was opened.
local C=Color3.fromRGB
local HAZARD,INK,TOXIC,SOOT,PALE,HOT=C(255,214,0),C(26,26,20),C(120,255,60),C(46,78,28),C(222,255,190),C(255,240,170)
local BOOM=1.6
local function out3(x)x=math.clamp(x,0,1);return 1-(1-x)^3 end

return function(m)
 local low=m.Low
 local onTongue=m.Venue=='Tongue'
 -- The blast sits on the factory roof (on the tongue) or on the ground where it was opened.
 local base=onTongue and m.Head or m:Ground(m.Origin)
 -- Ground level for the ping and the wave (a raycast under the head would hit its roof).
 local floor=onTongue and m.Stage or m:Ground(base)
 local fresh=m.Late<BOOM+.5

 -- The island holds its breath: sirens, a green sky, a radar ping from ground zero.
 local sky=m:Sky({Ambient=C(70,104,52),OutdoorAmbient=C(96,138,70),FogColor=C(120,168,84),FogStart=0,FogEnd=1500,ExposureCompensation=.12},1.2,5)
 local grade=m:Grade({TintColor=C(228,255,206),Saturation=-.12,Contrast=.1},.8,3)
 if fresh then
  m:Cue('Siren',nil,.32,2.4)
  m:Ring(Vector3.new(base.X,floor.Y+1.5,base.Z),TOXIC,10,m.Radius+260,BOOM,{Thickness=1.6,Alpha=.25,Segments=64,Linear=true})
  m:Duck(.35,.8)
 end
 if not m:Wait(BOOM)then return end

 -- Ground zero.
 if m:Fresh(BOOM,.6)then
  local near=m:Near(260)
  m:Flash(PALE,.15+.45*near,1.2)
  m:Cue('Boom',nil,.9)
  m:Bloom(.9,40,.9,.1,4)
  grade.Brightness=.35;m:Tween(grade,2.4,{Brightness=0})
 end
 local wave=Vector3.new(base.X,floor.Y,base.Z)
 m:Shockwave(wave,TOXIC,{Speed=330,Radius=m.Radius+520,Height=28,Thickness=2,Alpha=.15,OnPass=function()
  m:Shake(.55,.7);m:FOV(-6,.05,.7);m:Cue('Rumble',nil,.7,2);m:Cue('Geiger',nil,.3,3.5)
  m:Flash(PALE,.7,.35)
 end})
 m:Ring(base+Vector3.new(0,140,0),PALE,30,420,3.2,{Thickness=3,Alpha=.35,Segments=56})

 -- The mushroom cloud: a rising stem of smoke over a glowing core, a rolling toroidal cap.
 local cloud=m:Model('MushroomCloud')
 local stem,cores,cap,dome={},{},{},{}
 local STEM,CAP,DOME=low and 6 or 10,low and 8 or 14,low and 4 or 7
 local function smoke(color)return m:Part({Name='Smoke',Shape=Enum.PartType.Ball,Material=Enum.Material.SmoothPlastic,Color=color,Size=Vector3.one,Transparency=1,Parent=cloud})end
 local function glow()return m:Part({Name='Core',Shape=Enum.PartType.Ball,Color=HOT,Size=Vector3.one,Transparency=1,Parent=cloud})end
 for i=1,STEM do stem[i]=smoke(SOOT);if i<=STEM*.6 then cores[i]=glow()end end
 for i=1,CAP do cap[i]=smoke(SOOT:Lerp(TOXIC,.25))end
 for i=1,DOME do dome[i]=smoke(SOOT:Lerp(TOXIC,.15))end
 local heart=glow()
 local heartLight=m:Light(heart,TOXIC,120,3)
 m:Every(function()
  local t=m:Elapsed()-BOOM
  local top=40+270*out3(t/4)+t*1.5
  local capR=18+95*out3(t/4.5)+t*1.2
  local puff=28+52*out3(t/4)+t*.9
  -- The fireball cools into poison: hot white → toxic → soot; then it bleeds away.
  local heat=math.clamp(1-t/3,0,1)
  local fade=math.clamp((t-14)/9,0,1)
  local smokeColor=SOOT:Lerp(TOXIC,.35*heat+.15):Lerp(HOT,heat*.6)
  for i,p in ipairs(stem)do
   local k=(i-1)/(STEM-1)
   local y=top*k*.92
   local wob=math.sin(t*1.3+i)*3
   p.Size=Vector3.one*(puff*(.38+.22*k));p.Position=base+Vector3.new(wob,y,math.cos(t*1.1+i)*3)
   p.Color=smokeColor;p.Transparency=.08+.92*fade
   local core=cores[i]
   if core then core.Size=p.Size*.62;core.Position=p.Position;core.Transparency=1-(.85*heat+.25)*(1-fade);core.Color=HOT:Lerp(TOXIC,1-heat)end
  end
  for i,p in ipairs(cap)do
   local a=i/CAP*math.pi*2+t*.12
   local roll=t*1.6+i*.7
   local r=capR+math.cos(roll)*puff*.18
   p.Size=Vector3.one*puff*(1+.12*math.sin(roll));p.Position=base+Vector3.new(math.cos(a)*r,top+math.sin(roll)*puff*.18,math.sin(a)*r)
   p.Color=smokeColor:Lerp(INK,.15);p.Transparency=.05+.95*fade
  end
  for i,p in ipairs(dome)do
   local a=i/DOME*math.pi*2-t*.08
   p.Size=Vector3.one*puff*1.1;p.Position=base+Vector3.new(math.cos(a)*capR*.45,top+puff*.42,math.sin(a)*capR*.45)
   p.Color=smokeColor;p.Transparency=.05+.95*fade
  end
  heart.Size=Vector3.one*puff*1.3;heart.Position=base+Vector3.new(0,top,0);heart.Color=HOT:Lerp(TOXIC,1-heat)
  heart.Transparency=1-(.55*heat+.3)*(1-fade);heartLight.Brightness=3*(1-fade)
  if fade>=1 then cloud:Destroy();return false end
  return true
 end)

 -- Every Geiger counter on the island, and glowing ash wherever you stand.
 if not m:Wait(BOOM+.8)then return end
 if m:Fresh(BOOM+.8,1)then
  m:Banner('NUCLEAR PUG',{Kicker='✦   C R I T I C A L I T Y   E V E N T   ✦',Sub=m.VenueText..(m.By and ('  ·  '..string.upper(m.By))or''),
   Font=Enum.Font.GothamBlack,Color=TOXIC,Hold=5,Shake=.15})
  m:Cue('Geiger',nil,.28,6)
 end
 local ash=m:FollowRain({Rate=low and 25 or 70,Texture=m.Kit.Textures.Spark,Color=ColorSequence.new(TOXIC,PALE),LightEmission=.9,LightInfluence=0,
  Size=NumberSequence.new({NumberSequenceKeypoint.new(0,.2),NumberSequenceKeypoint.new(.5,.7),NumberSequenceKeypoint.new(1,0)}),
  Speed=NumberRange.new(4,9),Lifetime=NumberRange.new(9,13),Acceleration=Vector3.new(1.5,-1,0),RotSpeed=NumberRange.new(-60,60),
  Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,1),NumberSequenceKeypoint.new(.15,.1),NumberSequenceKeypoint.new(1,1)})},70)

 -- The hazard sign hangs over the tongue, facing the island.
 local sign=m:Model('HazardSign')
 local signAt=CFrame.lookAt(base+Vector3.new(0,215,170),base+Vector3.new(0,215,600))
 local disc=m:Part({Name='SignDisc',Shape=Enum.PartType.Cylinder,Material=Enum.Material.SmoothPlastic,Color=INK,Size=Vector3.new(1,170,170),Transparency=1,Parent=sign})
 local blades={}
 local rings=m:Part({Name='SignHub',Shape=Enum.PartType.Cylinder,Color=HAZARD,Size=Vector3.new(1.4,30,30),Transparency=1,Parent=sign})
 for b=0,2 do
  local mid=b*math.pi*2/3+math.pi/2
  for k=-2,2 do
   local a=mid+k*math.rad(11)
   table.insert(blades,{Part=m:Part({Name='Blade',Color=HAZARD,Size=Vector3.new(1.6,14,52),Transparency=1,Parent=sign}),Angle=a})
  end
 end
 local signStart=os.clock()
 m:Every(function()
  local age=os.clock()-signStart
  local t=m:Elapsed()
  local show=math.clamp(age/1.2,0,1)*(1-math.clamp((t-16)/3,0,1))
  local spin=CFrame.Angles(0,0,age*.25)
  local frame=signAt*spin
  disc.CFrame=signAt*CFrame.Angles(0,math.pi/2,0)*CFrame.new(-.8,0,0);disc.Transparency=1-show*.75
  rings.CFrame=frame*CFrame.Angles(0,math.pi/2,0);rings.Transparency=1-show
  for _,b in ipairs(blades)do
   -- Thin across the sign's face, long along its radius.
   local dir=Vector3.new(math.cos(b.Angle),math.sin(b.Angle),0)
   b.Part.CFrame=frame*CFrame.fromMatrix(dir*48,Vector3.zAxis,dir:Cross(Vector3.zAxis),dir)
   b.Part.Transparency=1-show*(.9+.1*math.sin(age*6))
  end
  if t>19.5 then sign:Destroy();return false end
  return true
 end)

 -- The fallout thins; the sky clears while the pug walks the tongue, delighted.
 if not m:Wait(18)then return end
 ash.Rate=0
 if sky then sky.Release()end
 m:Wait(m.Config.MegaSeconds or 28)
end
