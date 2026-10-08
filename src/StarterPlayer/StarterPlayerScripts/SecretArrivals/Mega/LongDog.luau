-- LONG DOG, island-wide: "THE ENDLESS DOG". The island rumbles. As the dog starts sliding out
-- of its owner's pit (0.4), its body erupts from the ground beside it in a fountain of dirt
-- and keeps coming: a colossal sausage of a body that arcs ~350 studs over the island and
-- dives back into the ground on the far side, a wave rolling out from each end. It never
-- stops coming out: the body streams along the arc, and everyone under it feels it go over.
-- Its real head pokes out of the ground beyond the far end, happy, while a sign in the sky
-- measures how long it is. At 14 its tail finally leaves the hole, the last of it streams
-- over and dives in, the head ducks back down and both holes close.
local C=Color3.fromRGB
local SAND,SPOT,DIRT,DUST,DARK,CREAM=C(240,196,120),C(156,108,62),C(104,72,42),C(196,164,120),C(30,20,12),C(255,244,214)
-- Server seconds: the body breaks the ground with the stage slide; its tail leaves at TAIL.
local EMERGE,TAIL=.4,14
-- Studs a second along the arc, and the arc's height over the ground.
local SPEED,APEX=170,350
local function smooth(x)x=math.clamp(x,0,1);return x*x*(3-2*x)end
local function backOut(x)x=math.clamp(x,0,1)-1;local c=1.70158;return 1+(c+1)*x*x*x+c*x*x end

return function(m)
 local Kit=m.Kit
 local low=m.Low
 -- Its pit, and where the arc comes down: the pit mirrored through the island's centre,
 -- kept on the island and a good stretch away.
 local pit=m:Ground(m.Origin)
 local toward=Vector3.new(m.Center.X-pit.X,0,m.Center.Z-pit.Z)
 local dir=toward.Magnitude>1 and toward.Unit or Vector3.zAxis
 local far=Vector3.new(pit.X,0,pit.Z)+dir*math.clamp(toward.Magnitude*2,340,560)
 far=Vector3.new(math.clamp(far.X,-250,250),0,math.clamp(far.Z,-120,740))
 if (far-Vector3.new(pit.X,0,pit.Z)).Magnitude<200 then
  far=Vector3.new(pit.X,0,pit.Z)+Vector3.new(0,0,pit.Z<300 and 340 or -340)
 end
 local flat=Vector3.new(far.X-pit.X,0,far.Z-pit.Z)
 dir=flat.Unit
 -- It erupts a little way off the pit (the stage's own hole stays clear) and ends at B.
 local A=m:Ground(Vector3.new(pit.X,0,pit.Z)+dir*45)
 local B=m:Ground(far)

 -- The arc as a polyline with distances, running underground past both ends.
 local SAMPLES=low and 90 or 150
 local S0,S1=-.075,1.075
 local points,lengths={},{}
 local total,dA,dB=0,nil,nil
 for i=0,SAMPLES do
  local s=S0+(S1-S0)*i/SAMPLES
  local h=A:Lerp(B,s)
  local p=Vector3.new(h.X,h.Y+APEX*4*s*(1-s),h.Z)
  if i>0 then total+=(p-points[i]).Magnitude end
  points[i+1]=p;lengths[i+1]=total
  if not dA and s>=0 then dA=total end
  if not dB and s>=1 then dB=total end
 end
 dA=dA or 0;dB=dB or total
 local function along(d)
  if d<=0 then return points[1]end
  if d>=total then return points[#points]end
  local lo,hi=1,#lengths
  while hi-lo>1 do
   local mid=math.floor((lo+hi)/2)
   if lengths[mid]<d then lo=mid else hi=mid end
  end
  local k=(d-lengths[lo])/math.max(lengths[hi]-lengths[lo],1e-3)
  return points[lo]:Lerp(points[hi],k)
 end
 -- When its front and its tail cross each hole, and when the front has dived in.
 local BODY=SPEED*(TAIL-EMERGE)
 local headA,headB,headIn=EMERGE+dA/SPEED,EMERGE+dB/SPEED,EMERGE+total/SPEED
 local tailA,tailB=TAIL+dA/SPEED,TAIL+dB/SPEED

 -- 0: the island rumbles under everyone's feet; the light turns dusty.
 local sky=m:Sky({Ambient=C(150,124,96),OutdoorAmbient=C(196,168,130),FogColor=C(214,188,150),FogStart=0,FogEnd=2400,ExposureCompensation=.06},1.5,4)
 local grade=m:Grade({TintColor=C(255,242,220),Saturation=.06,Contrast=.06},1,3)
 if m:Fresh(0,.6)then
  m:Cue('Rumble',nil,.45,2.2)
  m:Shake(.08,1.2)
 end

 -- The body: balls along the arc, locked to the stream so they flow with it; every fourth
 -- ring carries a darker spot on its back.
 local SPACING=low and 30 or 21
 local D=low and 34 or 27
 local segments={}
 for j=1,math.ceil(total/SPACING)+1 do
  local p=m:Part({Name='Body',Color=SAND,Material=Enum.Material.SmoothPlastic,Transparency=1});p.Shape=Enum.PartType.Ball;p.Size=Vector3.one*D
  local spot
  if not low then
   spot=m:Part({Name='Spot',Color=SPOT,Material=Enum.Material.SmoothPlastic,Transparency=1});spot.Shape=Enum.PartType.Ball;spot.Size=Vector3.one*D*.5
  end
  segments[j]={Part=p,Spot=spot}
 end

 -- The two holes: a dark crater over a ring of spoil, and a fountain of dirt and dust.
 local function hole(at)
  local spoil=m:Part({Name='Spoil',Color=DIRT,Material=Enum.Material.Ground,Transparency=1});spoil.Shape=Enum.PartType.Cylinder
  local pitPart=m:Part({Name='Crater',Color=DARK,Material=Enum.Material.SmoothPlastic,Transparency=1});pitPart.Shape=Enum.PartType.Cylinder
  local anchor=m:Anchor(at+Vector3.new(0,2,0),'Spray')
  local dirt=m:Emitter(anchor,{Rate=0,Color=ColorSequence.new(DIRT,DUST),LightEmission=0,LightInfluence=1,Lifetime=NumberRange.new(1.2,2),
   Speed=NumberRange.new(30,55),SpreadAngle=Vector2.new(35,35),Acceleration=Vector3.new(0,-70,0),Size=NumberSequence.new(2.2,1),
   Transparency=NumberSequence.new(0,.3),RotSpeed=NumberRange.new(-200,200)})
  local smoke=m:Emitter(anchor,{Rate=0,Texture=Kit.Textures.Smoke,Color=ColorSequence.new(DUST),LightEmission=0,LightInfluence=1,
   Lifetime=NumberRange.new(2.5,4),Speed=NumberRange.new(6,14),SpreadAngle=Vector2.new(60,60),Size=NumberSequence.new(12,30),Transparency=NumberSequence.new(.45,1)})
  return {At=at,Spoil=spoil,Pit=pitPart,Dirt=dirt,Smoke=smoke}
 end
 local holes={hole(A),hole(B)}
 holes[1].Open,holes[1].Close=headA,tailA
 holes[2].Open,holes[2].Close=headB,tailB
 local function erupt(h,color)
  m:Burst(h.At+Vector3.new(0,3,0),DIRT,60,{LightEmission=0,LightInfluence=1,Speed=NumberRange.new(40,80),SpreadAngle=Vector2.new(40,40),
   Acceleration=Vector3.new(0,-80,0),Lifetime=NumberRange.new(1.4,2.2),Size=NumberSequence.new(3,1.5),Transparency=NumberSequence.new(0,.2)})
  m:Burst(h.At+Vector3.new(0,4,0),DUST,26,{Texture=Kit.Textures.Smoke,LightEmission=0,LightInfluence=1,Speed=NumberRange.new(12,30),
   SpreadAngle=Vector2.new(80,80),Drag=2,Lifetime=NumberRange.new(2,3.2),Size=NumberSequence.new(14,40),Transparency=NumberSequence.new(.35,1)})
  m:Cue('Boom',nil,.55)
  m:Shockwave(h.At,color,{Speed=260,Radius=m.Radius+320,Height=12,Thickness=1.4,Alpha=.25,OnPass=function()
   m:Shake(.28,.5);m:Cue('Rumble',nil,.5,1.5)
  end})
 end

 -- Its head pokes out of the ground beyond the far end, tipped up, looking happy.
 local head=m:SkyDog(60,{Clip='Happy',Fill=SAND,Outline=CREAM,FillAlpha=.92})
 local front,peek,pitch=Vector3.zero,0,math.rad(48)
 local E=m:Ground(B+dir*55)
 if head then
  local centre=head.Ground+Vector3.new(0,head.Size.Y/2,0)
  front=centre+Vector3.new(0,0,-head.Size.Z/2)
  peek=math.min(head.Size.Z*.32,85)
  head:SetAlpha(0)
 end

 -- A sign over the arc measures it as it comes out.
 local apex=along((dA+dB)/2)+Vector3.new(0,75,0)
 local side=Vector3.new(-dir.Z,0,dir.X)
 local sign,labels=m:Text3D('LENGTH: 0m',CFrame.lookAt(apex,apex+side),Vector2.new(170,34),{Color=SAND,Font=Enum.Font.Kalam,Alpha=1})
 local strokes={}
 for _,l in ipairs(labels)do local s=l:FindFirstChildOfClass('UIStroke');if s then s.Transparency=1;table.insert(strokes,s)end end
 local shown=''

 -- Anyone under the arc hears and feels it go over.
 local ab=Vector3.new(B.X-A.X,0,B.Z-A.Z)
 local nextShake,nextRumble,passed=0,0,false

 m:Every(function()
  local t=m:Elapsed()
  local o=SPEED*(t-EMERGE)
  local tail=o-BODY
  local base=o%SPACING
  local ring0=math.floor(o/SPACING)
  for j,seg in ipairs(segments)do
   local d=base+(j-1)*SPACING
   local n=ring0-(j-1)
   local p=seg.Part
   if t>=EMERGE and d<=o and d>=tail and d<=total then
    local at=along(d)
    p.Position=at;p.Transparency=0
    p.Color=n%2==0 and SAND or SAND:Lerp(SPOT,.12)
    if seg.Spot then
     if n%4==0 then seg.Spot.Position=at+Vector3.new(0,D*.36,0);seg.Spot.Transparency=0 else seg.Spot.Transparency=1 end
    end
   else
    p.Transparency=1
    if seg.Spot then seg.Spot.Transparency=1 end
   end
  end
  -- The holes open as the body breaks through and close once its tail has passed.
  for _,h in ipairs(holes)do
   local size=60*backOut((t-h.Open)/.35)*(1-smooth((t-h.Close-.6)/.8))
   local live=t>=h.Open and size>.5
   local frame=CFrame.new(h.At+Vector3.new(0,.3,0))*CFrame.Angles(0,0,math.pi/2)
   h.Spoil.Size=Vector3.new(.5,size*1.35+.1,size*1.35+.1);h.Spoil.CFrame=frame;h.Spoil.Transparency=live and 0 or 1
   h.Pit.Size=Vector3.new(.6,size+.1,size+.1);h.Pit.CFrame=frame+Vector3.new(0,.08,0);h.Pit.Transparency=live and 0 or 1
   local flowing=t>=h.Open and t<h.Close
   h.Dirt.Rate=flowing and (low and 10 or 30)or 0
   h.Smoke.Rate=flowing and (low and 2 or 5)or 0
  end
  -- The head: rises once the front has dived in, ducks back down when the tail has gone.
  if head then
   local up=backOut((t-headIn-.3)/1.2)*(1-smooth((t-tailB)/1.5))
   local v=peek*math.max(up,0)
   local look=(dir*math.cos(pitch)+Vector3.yAxis*math.sin(pitch)).Unit
   local turn=CFrame.lookAt(Vector3.zero,look)*CFrame.Angles(0,.22*math.sin(t*1.3),0)
   local tip=E+look*v
   head:Pivot(CFrame.new(tip-turn:VectorToWorldSpace(front))*turn)
   head:SetAlpha(math.clamp(up*3,0,1))
  end
  -- The sign counts while it comes out, and gives up after.
  local fade=smooth((t-EMERGE-.5)/1)*(1-smooth((t-TAIL-6)/1.5))
  local text=t<tailA and ('LENGTH: '..math.floor(math.clamp(o,0,BODY)*.28)..'m')or ('LENGTH: '..math.floor(BODY*.28)..'m (probably)')
  if text~=shown then shown=text;for _,l in ipairs(labels)do l.Text=text end end
  for _,l in ipairs(labels)do l.TextTransparency=1-fade end
  for _,s in ipairs(strokes)do s.Transparency=1-fade end
  -- Under the arc: the body overhead shakes you; the front going over whooshes.
  local cam=m:Camera()
  local u=ab.Magnitude>1 and math.clamp(((cam-A)*Vector3.new(1,0,1)):Dot(ab)/ab:Dot(ab),0,1)or 0
  local below=Vector3.new(A.X+ab.X*u,0,A.Z+ab.Z*u)
  local dist=(Vector3.new(cam.X,0,cam.Z)-below).Magnitude
  local over=dA+(dB-dA)*u
  if dist<150 and over<=o and over>=tail then
   local level=1-dist/150
   local now=os.clock()
   if now>=nextShake then nextShake=now+.3;m:Shake(.12*level,.4)end
   if now>=nextRumble then nextRumble=now+2.2;m:Cue('Rumble',nil,.1+.35*level,1.4)end
   if not passed then passed=true;m:Cue('Whoosh',nil,.6);m:Shake(.25*level,.6)end
  end
  return t<(m.Config.MegaSeconds or 26)
 end)

 -- It breaks the ground beside the pit.
 if not m:Wait(headA)then return end
 if m:Fresh(headA,.8)then erupt(holes[1],SAND)end
 -- The front comes down on the far side and dives in; its head pokes out beyond.
 if not m:Wait(headB)then return end
 if m:Fresh(headB,.8)then erupt(holes[2],SAND)end
 if not m:Wait(headIn+.4)then return end
 if m:Fresh(headIn+.4,1.2)then
  m:Banner(m.Config.Title,{Kicker='✦   T H E   H O L E   K E P T   G O I N G   ✦',Sub=m.VenueText..(m.By and ('  ·  '..string.upper(m.By))or''),
   Font=Enum.Font.Kalam,Color=SAND,Hold=5,Shake=.12})
  m:Cue('Chime',nil,.45)
 end

 -- Its tail leaves the pit at last, streams over and dives in; the holes close.
 if not m:Wait(tailA)then return end
 if m:Fresh(tailA,.8)then m:Cue('Whoosh',nil,.5);m:Cue('Rumble',nil,.35,1.6)end
 if not m:Wait(tailB)then return end
 if m:Fresh(tailB,.8)then
  m:Burst(holes[2].At+Vector3.new(0,4,0),DUST,20,{Texture=Kit.Textures.Smoke,LightEmission=0,LightInfluence=1,Speed=NumberRange.new(8,20),
   SpreadAngle=Vector2.new(80,80),Drag=2,Lifetime=NumberRange.new(1.6,2.6),Size=NumberSequence.new(10,30),Transparency=NumberSequence.new(.4,1)})
  m:Cue('Impact',nil,.5)
 end
 if not m:Wait(tailB+1.6)then return end
 if sky then sky.Release()end
 m:Tween(grade,2.5,{Saturation=0,Contrast=0,TintColor=Color3.new(1,1,1)})
 m:Wait(m.Config.MegaSeconds or 26)
end
