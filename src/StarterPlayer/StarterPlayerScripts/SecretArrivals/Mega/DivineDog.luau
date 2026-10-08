-- BIBLICALLY ACCURATE DOG, island-wide: "THE HEAVENS OPEN". The clouds over the island part
-- and a ring of light ~400 studs across opens in the sky, its god rays sweeping slowly over
-- the yards and the hub. Above the giant head three colossal golden rings turn through each
-- other on three axes, studded with eyes that open one by one and look at you, wherever you
-- stand, around one great eye; a choir rises. At 2.8 (the dog's Blink) every eye in the sky
-- blinks with it. At 3.4 (Ability_MultiRoll) a pillar of holy light slams down from heaven
-- onto the stage, a golden wave rolls across the island, every player wears a halo for
-- twenty seconds and feathers drift down around them. At 6.6 every eye closes; the rings rise
-- into the light, the rays fade and the clouds close over heaven again.
-- Off the tongue it all hangs straight over the spot where the dog was opened.
local Players=game:GetService('Players')
local C=Color3.fromRGB
local GOLD,PALE,CREAM,INK,CLOUD=C(255,204,96),C(255,250,236),C(255,238,198),C(14,9,4),C(238,234,226)
-- Server seconds, as the stage cinematic: lands (Blink), the rolls, every eye closes (Blink).
local LAND,ROLL,CLOSE=2.8,3.4,6.6
-- When the pillar reaches the ground, and how long every player keeps their halo.
local SLAM,HALO=ROLL+.22,20
local function smooth(x)x=math.clamp(x,0,1);return x*x*(3-2*x)end
local function out3(x)x=math.clamp(x,0,1);return 1-(1-x)^3 end
-- How open the lids are through a Blink clip started at t0 (shut at t0+.3, open at t0+.6).
local function lids(el,t0)return smooth(math.abs(el-t0-.3)/.3)end

return function(m)
 local Kit=m.Kit
 local low=m.Low
 local SUN=m.Color
 local onTongue=m.Venue=='Tongue'
 -- The stage sits in the head's mouth (its floor is the belt); off the tongue, on the ground.
 local stage=onTongue and m.Stage or m:Ground(m.Origin)
 local floorY=stage.Y
 -- Heaven opens over the island (shifted toward the yards from the head on the tongue);
 -- the wheel of rings turns above and behind the head, over the stage's own small wheel.
 local HEAVEN=Vector3.new(stage.X,360,stage.Z+(onTongue and 140 or 0))
 local ANGEL=onTongue and Vector3.new(0,245,-205)or stage+Vector3.new(0,215,0)

 -- 0: the light warms, a choir answers the stage's own (quieter for those beside it).
 local near=m:Near(260)
 local sky=m:Sky({Brightness=3.2,Ambient=C(178,160,128),OutdoorAmbient=C(214,196,156),FogColor=C(255,242,212),FogStart=0,FogEnd=2600,ExposureCompensation=.3},1.6,5)
 local grade=m:Grade({TintColor=C(255,246,224),Saturation=.12,Contrast=.05,Brightness=.03},1.2,4)
 m:Bloom(.45,34,1.05,1.4,4)
 local choir=m:Drone('Choir',(low and .12 or .2)*(1-.7*near)+.04,.72,2)
 if m:Fresh(0,.6)then m:Cue('Chime',nil,.4);m:Cue('Whoosh',nil,.35)end

 -- Heaven: a band of light, the glow inside it and the clouds it pushes apart.
 local SEG=low and 20 or 36
 local band={}
 for i=1,SEG do band[i]=m:Part({Name='HeavenBand',Color=PALE,Transparency=1})end
 local disc=m:Part({Name='HeavenLight',Color=CREAM,Transparency=1});disc.Shape=Enum.PartType.Cylinder
 local clouds={}
 for i=1,low and 6 or 10 do
  local p=m:Part({Name='Cloud',Color=CLOUD,Material=Enum.Material.SmoothPlastic,Transparency=1});p.Shape=Enum.PartType.Ball
  clouds[i]={Part=p,Size=110+(i*53)%50,Out=(i*29)%60,Phase=i*.9}
 end
 -- Opens 60 → 420 over 3.2 s; closes again from 14 s.
 local function radius(el)return (60+360*out3(el/3.2))*(1-.85*smooth((el-14)/6))end

 -- God rays: light shafts from the inside of the ring down onto the island, sweeping slowly.
 local rays={}
 for i=1,low and 6 or 10 do
  local beam=m:Beam(HEAVEN,Vector3.new(HEAVEN.X,floorY,HEAVEN.Z),PALE,0,{Segments=1,Brightness=2,Color=ColorSequence.new(PALE,SUN),
   Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,.45),NumberSequenceKeypoint.new(.8,.72),NumberSequenceKeypoint.new(1,1)})})
  rays[i]={Beam=beam,Top=beam.Attachment0.Parent,Bottom=beam.Attachment1.Parent,Reach=140+(i%3)*125,Phase=i/(low and 6 or 10)*math.pi*2}
 end

 -- The wheel of rings: three golden rings turning through each other on three axes, each
 -- carrying eyes, around one great eye.
 local RINGS={
  {R=84,Turn=function(el)return CFrame.Angles(0,el*.22,0)end},
  {R=72,Turn=function(el)return CFrame.Angles(el*.3,0,0)*CFrame.Angles(0,math.pi/2,0)end},
  {R=60,Turn=function(el)return CFrame.Angles(0,0,el*.17)*CFrame.Angles(math.pi/2,.5,0)end},
 }
 local RN,EYES=low and 12 or 18,low and 3 or 4
 -- A sphere mesh in a box part: an eye that can squash shut.
 local function ellipsoid(name,color,neon)
  local p=m:Part({Name=name,Color=color,Transparency=1,Size=Vector3.one,Material=neon and Enum.Material.Neon or Enum.Material.SmoothPlastic})
  local mesh=Instance.new('SpecialMesh');mesh.MeshType=Enum.MeshType.Sphere;mesh.Parent=p
  return p
 end
 for k,r in ipairs(RINGS)do
  r.Parts={};r.Eyes={}
  for i=1,RN do r.Parts[i]=m:Part({Name='Wheel',Color=GOLD,Transparency=1})end
  for j=1,EYES do
   r.Eyes[j]={White=ellipsoid('Eye',PALE,true),Pupil=ellipsoid('Pupil',INK,false),Angle=(j-.5)/EYES*math.pi*2+k*.7,Open=.5+(k*EYES+j)*.05}
  end
 end
 local great={White=ellipsoid('GreatEye',PALE,true),Iris=ellipsoid('Iris',GOLD,true),Pupil=ellipsoid('Pupil',INK,false)}
 -- An eye at pos turned to this player's camera, open 0..1, w wide and h tall when open.
 local function pose(eye,pos,open,cam,w,h)
  if open<.03 then
   eye.White.Transparency=1;eye.Pupil.Transparency=1
   if eye.Iris then eye.Iris.Transparency=1 end
   return
  end
  local to=cam-pos
  local dir=to.Magnitude>.1 and to.Unit or Vector3.zAxis
  local face=Kit.LookAt(pos,pos+dir)
  eye.White.Size=Vector3.new(w,h*open,w*.45);eye.White.CFrame=face;eye.White.Transparency=0
  local p=w*.42
  if eye.Iris then
   eye.Iris.Size=Vector3.new(p,math.min(p,h*open*.85),w*.16);eye.Iris.CFrame=face+dir*w*.16;eye.Iris.Transparency=0
   p=w*.18
  end
  eye.Pupil.Size=Vector3.new(p,math.min(p,h*open*.5),w*.08);eye.Pupil.CFrame=face+dir*w*(eye.Iris and .24 or .2);eye.Pupil.Transparency=0
 end

 m:Every(function()
  local el=m:Elapsed()
  local cam=m:Camera()
  -- Heaven opens: the band, the glow and the clouds rolling back from it.
  local R=radius(el)
  local open=smooth(el/1.2)*(1-smooth((el-18)/3))
  local chord=2*math.pi*R/SEG*1.06
  for i,p in ipairs(band)do
   local t0,t1=(i-1)/SEG*math.pi*2,i/SEG*math.pi*2
   local a0=HEAVEN+Vector3.new(math.cos(t0)*R,0,math.sin(t0)*R)
   local a1=HEAVEN+Vector3.new(math.cos(t1)*R,0,math.sin(t1)*R)
   p.Size=Vector3.new(9,2,chord);p.CFrame=Kit.LookAt((a0+a1)/2,a1);p.Transparency=1-.85*open
  end
  local across=math.min(R*1.96,2040)
  disc.Size=Vector3.new(1.5,across,across);disc.CFrame=CFrame.new(HEAVEN+Vector3.new(0,6,0))*CFrame.Angles(0,0,math.pi/2)
  disc.Transparency=1-.2*open
  local mist=1-smooth((el-19)/3)
  for i,c in ipairs(clouds)do
   local a=i/#clouds*math.pi*2+el*.02
   local r=R+70+c.Out
   c.Part.Size=Vector3.one*c.Size*(1+.06*math.sin(el*.5+c.Phase))
   c.Part.Position=HEAVEN+Vector3.new(math.cos(a)*r,-12+8*math.sin(el*.4+c.Phase),math.sin(a)*r)
   c.Part.Transparency=1-.75*smooth(el/.8)*mist
  end
  -- The rays sweep slowly round, from inside the ring down onto the island.
  local glow=smooth((el-.6)/1.5)*(1-smooth((el-12)/5))
  for _,r in ipairs(rays)do
   local a=r.Phase+el*.035
   r.Top.CFrame=CFrame.new(HEAVEN+Vector3.new(math.cos(a)*R*.72,0,math.sin(a)*R*.72))
   r.Bottom.CFrame=CFrame.new(HEAVEN.X+math.cos(a+.45)*r.Reach,floorY,HEAVEN.Z+math.sin(a+.45)*r.Reach)
   r.Beam.Width0=34*glow;r.Beam.Width1=80*glow
  end
  -- The rings draw themselves, turn, and after the eyes close rise into the light.
  local show=out3((el-.3)/1.2)*(1-smooth((el-9)/5))
  local centre=ANGEL+Vector3.new(0,200*smooth((el-9)/5)+4*math.sin(el*.8),0)
  local blink=lids(el,LAND)*(1-smooth((el-CLOSE)/.3))
  for _,r in ipairs(RINGS)do
   local frame=CFrame.new(centre)*r.Turn(el)
   local piece=2*math.pi*r.R/RN*1.05
   for i,p in ipairs(r.Parts)do
    local t0,t1=(i-1)/RN*math.pi*2,i/RN*math.pi*2
    local a0=frame*Vector3.new(math.cos(t0)*r.R,math.sin(t0)*r.R,0)
    local a1=frame*Vector3.new(math.cos(t1)*r.R,math.sin(t1)*r.R,0)
    p.Size=Vector3.new(4.5,4.5,piece);p.CFrame=Kit.LookAt((a0+a1)/2,a1)
    p.Transparency=1-.92*show*smooth((el-.3-i/RN*.8)/.2)
   end
   for _,e in ipairs(r.Eyes)do
    pose(e,frame*Vector3.new(math.cos(e.Angle)*r.R,math.sin(e.Angle)*r.R,0),out3((el-e.Open)/.3)*blink*show,cam,15,15)
   end
  end
  pose(great,centre,out3((el-1.1)/.35)*lids(el,LAND+.05)*(1-smooth((el-CLOSE-.15)/.3))*show,cam,46,30)
  return el<(m.Config.MegaSeconds or 28)
 end)

 -- 2.8: it lands below; every eye in the sky blinks with its own.
 if not m:Wait(LAND)then return end
 if m:Fresh(LAND,.5)then
  m:Cue('Chime',nil,.45)
  m:Flash(PALE,.82,.4)
 end

 -- 3.4: a pillar of holy light slams down from heaven onto the stage.
 if not m:Wait(ROLL)then return end
 local top=HEAVEN.Y
 if m:Elapsed()<ROLL+4 then
  if m:Fresh(ROLL,.5)then m:Cue('Whoosh',nil,.6)end
  local column=m:Part({Name='HolyPillar',Color=PALE,Transparency=1});column.Shape=Enum.PartType.Cylinder
  local sheath=m:Part({Name='HolyGlow',Color=SUN,Material=Enum.Material.ForceField,Transparency=1});sheath.Shape=Enum.PartType.Cylinder
  m:Every(function()
   local age=m:Elapsed()-ROLL
   local bottom=top-(top-floorY)*out3(age/(SLAM-ROLL))
   local length=math.max(top-bottom,.2)
   local fade=smooth((age-2.4)/2)
   local w=(30+18*math.exp(-math.max(age-(SLAM-ROLL),0)*3))*(1-fade)+.1
   local frame=CFrame.new(stage.X,(top+bottom)/2,stage.Z)*CFrame.Angles(0,0,math.pi/2)
   column.Size=Vector3.new(length,w,w);column.CFrame=frame;column.Transparency=.08+.92*fade
   sheath.Size=Vector3.new(length,w*2.3,w*2.3);sheath.CFrame=frame;sheath.Transparency=.5+.5*fade
   if age>4.5 then column:Destroy();sheath:Destroy();return false end
   return true
  end)
 end

 -- It hits: a golden wave rolls across the island and reaches every player.
 if not m:Wait(SLAM)then return end
 local hit=Vector3.new(stage.X,floorY,stage.Z)
 if m:Fresh(SLAM,.6)then
  m:Cue('Boom',nil,.5);m:Cue('Sting',nil,.4)
  m:Flash(PALE,.35+.4*(1-m:Near(260)),.9)
  m:Ring(hit+Vector3.new(0,1,0),PALE,8,260,1.6,{Thickness=3,Alpha=.2,Segments=28})
  grade.Brightness=.25;m:Tween(grade,1.6,{Brightness=.03})
 end
 if m:Elapsed()<SLAM+1.5 then
  m:Shockwave(hit,GOLD,{Speed=300,Radius=m.Radius+380,Height=22,Thickness=1.6,Alpha=.18,OnPass=function()
   m:Shake(.22,.45);m:Flash(PALE,.78,.35);m:Cue('Chime',nil,.3)
  end})
 end
 if m:Fresh(SLAM,1.2)then
  m:Banner(m.Config.Title,{Kicker='✦   B E   N O T   A F R A I D   ✦',Sub=m.VenueText..(m.By and ('  ·  '..string.upper(m.By))or''),
   Font=Enum.Font.Antique,Color=GOLD,Hold=5.5,Shake=.08})
 end

 -- Every player wears a halo: a gold ring on an anchor that follows their head each frame.
 local halos={}
 local function crown(character)
  local head=character:FindFirstChild('Head')
  if not head or not head:IsA('BasePart')or halos[head]then return end
  local anchor=m:Part({Name='Halo',Transparency=1,Size=Vector3.one*.2})
  local ring=Instance.new('CylinderHandleAdornment')
  ring.Name='HaloRing';ring.Adornee=anchor;ring.Radius=1.05;ring.Height=.16;ring.CFrame=CFrame.Angles(math.pi/2,0,0)
  ring.Color3=GOLD;ring.Transparency=1;ring.AlwaysOnTop=false
  -- A hollow ring where supported; a thin disc of gold otherwise.
  pcall(function()ring.InnerRadius=.78 end)
  ring.Parent=anchor
  if character==Players.LocalPlayer.Character and not low then
   m:Light(anchor,SUN,10,1.2)
   m:Emitter(anchor,{Rate=4,Color=ColorSequence.new(PALE,SUN),Speed=NumberRange.new(.3,1),Lifetime=NumberRange.new(.6,1.2),Size=NumberSequence.new(.18,0)})
  end
  halos[head]={Anchor=anchor,Ring=ring,Born=os.clock(),Phase=math.random()*6}
 end
 local scanned=0
 m:Every(function()
  local el=m:Elapsed()
  if el>SLAM+HALO+2 then
   for _,h in pairs(halos)do h.Anchor:Destroy()end
   table.clear(halos)
   return false
  end
  -- Players who respawn or join meanwhile get theirs too.
  if el<SLAM+HALO and os.clock()-scanned>.5 then
   scanned=os.clock()
   for _,p in ipairs(Players:GetPlayers())do if p.Character then crown(p.Character)end end
  end
  local out=smooth((el-SLAM-HALO)/1.5)
  for head,h in pairs(halos)do
   if not head.Parent then h.Anchor:Destroy();halos[head]=nil
   else
    local a=smooth((os.clock()-h.Born)/.5)*(1-out)
    h.Anchor.CFrame=CFrame.new(head.Position+Vector3.new(0,head.Size.Y*.5+1+.12*math.sin(os.clock()*2+h.Phase),0))
    h.Ring.Transparency=1-.9*a
   end
  end
  return true
 end)

 -- Feathers drift down around every player, and motes of light fall wherever you go.
 local function feathers()
  m:Fall({Count=16,Radius=140,Height=40,Gravity=12,Drag=1,Bounce=false,Life=9,Spread=4,Spin=2.5,Velocity=Vector3.new(2,0,1),
   Make=function(i)return m:Part({Name='Feather',Color=i%3==0 and CREAM or PALE,Material=Enum.Material.SmoothPlastic,Size=Vector3.new(.55,.08,2.3)})end})
 end
 if m:Elapsed()<SLAM+3 then feathers()end
 local motes=m:FollowRain({Rate=36,Texture=Kit.Textures.Spark,Color=ColorSequence.new(PALE,SUN),LightEmission=1,LightInfluence=0,
  Size=NumberSequence.new({NumberSequenceKeypoint.new(0,.1),NumberSequenceKeypoint.new(.4,.5),NumberSequenceKeypoint.new(1,0)}),
  Speed=NumberRange.new(3,7),Lifetime=NumberRange.new(7,10),RotSpeed=NumberRange.new(-40,40),
  Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,1),NumberSequenceKeypoint.new(.15,.15),NumberSequenceKeypoint.new(1,1)})},60)

 -- 6.6: every eye closes.
 if not m:Wait(CLOSE)then return end
 if m:Fresh(CLOSE,.5)then m:Cue('Sting',nil,.3)end
 if not m:Wait(SLAM+5)then return end
 if m:Elapsed()<SLAM+7 then feathers()end

 -- The light goes back up; the clouds close over heaven; the choir falls silent.
 if not m:Wait(18)then return end
 motes.Rate=0
 if choir then m:Tween(choir,4,{Volume=0})end
 if not m:Wait(19)then return end
 if sky then sky.Release()end
 m:Tween(grade,3,{Brightness=0,Contrast=0,Saturation=0,TintColor=Color3.new(1,1,1)})
 m:Wait(m.Config.MegaSeconds or 28)
end
