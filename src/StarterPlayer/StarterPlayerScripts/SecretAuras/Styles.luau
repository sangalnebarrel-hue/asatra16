-- The unique part of each Secret's aura. Per dog:
--   Reduced(a, g)       tier 2 (mid distance): cheap, mostly static pieces
--   Full(a, g)          tier 3 (near): particles and animated pieces
--   Step(a, t, dt, cam) every frame while tier 3 exists (t = os.clock())
--   Tick(a, now)        every manager pass while tier 2 exists
--   Mini(a, g)          tier 3 of the small symbol version (the DOG-O-MATIC drum)
--   Clear(a, key, g)    a group is about to be destroyed
-- Sizes come from a.Geo (S ≈ 1 for a 5-stud dog, R = ground radius); positions are in the
-- dog's frame (A:Local / A:World). a.Low and a.ReducedMotion are set by the manager.
local RS=game:GetService('ReplicatedStorage')
local Config=require(RS:WaitForChild('SecretAuraConfig'))
local DogLook=require(RS:WaitForChild('DogLook'))
local Aura=require(script.Parent:WaitForChild('Aura'))
local Common=require(script.Parent:WaitForChild('Common'))
local T=Aura.Textures
local Flat=Aura.Flat
local rng=Random.new()
local function rand(a,b)return rng:NextNumber(a,b)end
local function ns(...)
 local v={...}
 if #v==1 then return NumberSequence.new(v[1])end
 local keys={}
 for i=1,#v,2 do table.insert(keys,NumberSequenceKeypoint.new(v[i],v[i+1]))end
 return NumberSequence.new(keys)
end
local function cs(a,b)return ColorSequence.new(a,b or a)end
-- The 12 edges of a box (half extents h) on a wireframe adornment.
local function box(o,h)
 local c={}
 for _,x in ipairs({-1,1})do for _,y in ipairs({-1,1})do for _,z in ipairs({-1,1})do table.insert(c,Vector3.new(x,y,z)*h)end end end
 for i=1,8 do for j=i+1,8 do
  local d=c[i]-c[j]
  -- Corners that differ on exactly one axis share an edge.
  local n=(math.abs(d.X)>1e-6 and 1 or 0)+(math.abs(d.Y)>1e-6 and 1 or 0)+(math.abs(d.Z)>1e-6 and 1 or 0)
  if n==1 then o:AddLine(c[i],c[j])end
 end end
end
local function easeBack(k)
 local c1=1.70158;local c3=c1+1
 return 1+c3*(k-1)^3+c1*(k-1)^2
end
local function shownFull(a)
 local g=a.Groups[3]
 return g and g.Alpha*a.Alpha or 0
end
-- A label filling its billboard (studs-sized billboards scale with distance like an object).
local function label(parent,text,font,color,stroke)
 local l=Instance.new('TextLabel');l.BackgroundTransparency=1;l.Size=UDim2.fromScale(1,1);l.TextScaled=true
 l.Font=font;l.Text=text;l.TextColor3=color;l.TextStrokeColor3=stroke or Color3.new(0,0,0);l.TextStrokeTransparency=.25
 l.Parent=parent
 return l
end
local function dot(parent,size,position,color,alpha)
 local f=Instance.new('Frame');f.AnchorPoint=Vector2.new(.5,.5);f.Size=UDim2.fromScale(size,size);f.Position=position
 f.BackgroundColor3=color;f.BackgroundTransparency=alpha or 0;f.BorderSizePixel=0
 local c=Instance.new('UICorner');c.CornerRadius=UDim.new(1,0);c.Parent=f
 f.Parent=parent
 return f
end
local S={}

---------------------------------------------------------------- Cubedog
-- The outline cube stands on the ground around the dog.
local function cubeCenter(G,side)return Vector3.new(G.Center.X,G.Lo.Y+side/2,G.Center.Z)end
-- A cyan wireframe cube around it that snaps a quarter turn, small wire cubes in orbit,
-- voxels popping on the cube's faces, cyan voxel sparkles.
S.Cubedog={
 Reduced=function(a,g)
  local G,cfg=a.Geo,a.Cfg
  local side=math.max(G.Size.X,G.Size.Y,G.Size.Z)*1.12
  g.State.Side=side
  g.State.Outline=a:Adorn(g,'WireframeHandleAdornment',function(o)
   o.Name='CubeOutline';o.Color3=cfg.Color;o.Thickness=2.5;o.Transparency=.2
   box(o,Vector3.one*side/2)
   o.CFrame=a:Local(cubeCenter(G,side))
  end)
  a:Emitter(g,a:BodyPart(),8,function(e)
   Aura.Volume(e);e.Color=cs(cfg.Color,cfg.Accent);e.Size=ns(0,.16*G.S,.7,.1*G.S,1,0)
   e.Lifetime=NumberRange.new(.5,.9);e.Speed=NumberRange.new(.2,.8);e.Brightness=1.6
  end)
 end,
 Full=function(a,g)
  local G,cfg=a.Geo,a.Cfg
  local side=math.max(G.Size.X,G.Size.Y,G.Size.Z)*1.12
  local st=g.State
  st.From,st.To,st.SnapAt,st.NextSnap=0,0,nil,os.clock()+1
  st.Cubes={}
  local colors={cfg.Color,cfg.Accent,cfg.Deep}
  for i=1,a.Low and 1 or 3 do
   local half=side*(.05+.015*i)
   local o=a:Adorn(g,'WireframeHandleAdornment',function(o)
    o.Name='OrbitCube';o.Color3=colors[i];o.Thickness=2;o.Transparency=1
    box(o,Vector3.one*half)
   end,false)
   table.insert(st.Cubes,{O=o,Radius=side*(.72+.1*i),Height=(i-2)*.18*G.Size.Y,Speed=(i%2==0 and -1 or 1)*(.7+.15*i),Phase=i*2.1,Spin=1.1+.4*i})
  end
  st.Voxels={}
  for _=1,a.Low and 2 or 5 do
   local o=a:Adorn(g,'BoxHandleAdornment',function(o)
    o.Name='Voxel';o.Size=Vector3.one*side*.07;o.Color3=cfg.Color;o.Transparency=1
   end,false)
   table.insert(st.Voxels,{O=o,Born=0,Dies=0})
  end
 end,
 Step=function(a,t)
  local G=a.Geo
  local full,reduced=a.Groups[3],a.Groups[2]
  local st=full.State
  local shown=shownFull(a)
  local side=reduced and reduced.State.Side or math.max(G.Size.X,G.Size.Y,G.Size.Z)*1.12
  -- The outline turns a quarter with a snap, then waits.
  if t>=st.NextSnap then
   st.From=st.To;st.To=st.From+math.pi/2;st.SnapAt=t;st.NextSnap=t+1.8+rand(0,.9)
  end
  local k=st.SnapAt and math.clamp((t-st.SnapAt)/(a.ReducedMotion and .9 or .24),0,1)or 1
  local angle=st.From+(st.To-st.From)*(a.ReducedMotion and k*k*(3-2*k)or easeBack(k))
  local outline=reduced and reduced.State.Outline
  if outline and outline.Parent then
   outline.CFrame=a:Local(cubeCenter(G,side),CFrame.Angles(0,angle,0))
   outline.Color3=a.ReducedMotion and a.Cfg.Color or a.Cfg.Accent:Lerp(a.Cfg.Color,math.min(1,k*1.6))
  end
  for _,c in ipairs(st.Cubes)do
   local ang=t*c.Speed+c.Phase
   local p=G.Center+Vector3.new(math.cos(ang)*c.Radius,c.Height+math.sin(t*1.3+c.Phase)*.12*G.Size.Y,math.sin(ang)*c.Radius)
   c.O.CFrame=a:Local(p,CFrame.Angles(t*c.Spin,t*c.Spin*.7,0))
   c.O.Transparency=1-.9*shown
  end
  -- Voxels: a cell on one face of the outline lights up and fades.
  for _,v in ipairs(st.Voxels)do
   if t>=v.Dies then
    local axis=rng:NextInteger(1,3);local sign=rng:NextInteger(0,1)*2-1
    local cells=4;local u,w=(rng:NextInteger(0,cells-1)+.5)/cells-.5,(rng:NextInteger(0,cells-1)+.5)/cells-.5
    local p=axis==1 and Vector3.new(sign*.5,u,w)or axis==2 and Vector3.new(u,sign*.5,w)or Vector3.new(u,w,sign*.5)
    v.Local=p*side;v.Born=t;v.Dies=t+rand(.6,1.1)
   end
   local age=(t-v.Born)/(v.Dies-v.Born)
   v.O.CFrame=a:Local(cubeCenter(G,side),CFrame.Angles(0,angle,0)*CFrame.new(v.Local or Vector3.zero))
   v.O.Transparency=1-.85*(1-age)*math.min(1,age*8)*shown
  end
 end,
}

---------------------------------------------------------------- Dogdogdogdog
-- Eight golden motes run around it like a pack, the leader leaving a sparkle trail;
-- a tiny "×8" tag.
S.Dogdogdogdog={
 Reduced=function(a,g)
  local G,cfg=a.Geo,a.Cfg
  local at=a:Attachment(g,'AuraPackTag',Vector3.new(G.Hi.X-.1*G.Size.X,G.Hi.Y-.05*G.Size.Y,G.Lo.Z+.3*G.Size.Z))
  local gui=a:Billboard(g,at,function(b)b.Name='PackTag';b.Size=UDim2.fromOffset(46,26);b.MaxDistance=90;b.StudsOffset=Vector3.new(0,.4,0)end)
  local pill=Instance.new('Frame');pill.Size=UDim2.fromScale(1,1);pill.BackgroundColor3=cfg.Color;pill.BackgroundTransparency=.05;pill.Rotation=-8;pill.BorderSizePixel=0;pill.Parent=gui
  local c=Instance.new('UICorner');c.CornerRadius=UDim.new(.5,0);c.Parent=pill
  local stroke=Instance.new('UIStroke');stroke.Color=cfg.Accent;stroke.Thickness=1.5;stroke.Parent=pill
  local l=label(pill,'×8',Enum.Font.LuckiestGuy,Color3.fromRGB(60,30,0),cfg.Accent);l.TextStrokeTransparency=.6
  a:FadeGui(g,pill)
  a:Emitter(g,a:BodyPart(),5,function(e)
   Aura.Volume(e);e.Color=cs(cfg.Accent,cfg.Color);e.Size=ns(0,.14*G.S,1,0);e.Lifetime=NumberRange.new(.6,1.1);e.Speed=NumberRange.new(.2,.6);e.Brightness=1.5
  end)
 end,
 Full=function(a,g)
  local G,cfg=a.Geo,a.Cfg
  local st=g.State
  st.Motes={}
  local n=a.Low and 4 or 8
  for i=1,n do
   local size=.24*G.S
   local part=a:Follower(g,function(p)
    p.Name='PackMote';p.Shape=Enum.PartType.Ball;p.Size=Vector3.one*size;p.Color=i%2==0 and cfg.Accent or cfg.Color
   end)
   if not a.Low then
    local a0=Instance.new('Attachment');a0.Position=Vector3.new(0,size*.45,0);a0.Archivable=false;a0.Parent=part
    local a1=Instance.new('Attachment');a1.Position=Vector3.new(0,-size*.45,0);a1.Archivable=false;a1.Parent=part
    local trail=Instance.new('Trail');trail:SetAttribute('SecretAura',true);trail.Archivable=false
    trail.Attachment0=a0;trail.Attachment1=a1;trail.Lifetime=.35;trail.LightEmission=1;trail.LightInfluence=0;trail.FaceCamera=true
    trail.Color=cs(cfg.Color,cfg.Deep);trail.Transparency=ns(0,.25,1,1);trail.WidthScale=ns(0,1,1,0);trail.Brightness=1.5
    trail.Parent=part
    a:Fade(g,trail,'LocalTransparencyModifier','ltm')
   end
   table.insert(st.Motes,{Part=part,Phase=(i-1)/n*math.pi*2+rand(-.12,.12),Wobble=rand(0,6)})
  end
  -- The leader's sparkles stay where it ran: a golden trail around the pack.
  a:Emitter(g,st.Motes[1].Part,10,function(e)
   e.Color=cs(cfg.Accent,cfg.Color);e.Size=ns(0,.16*G.S,1,0);e.Lifetime=NumberRange.new(.5,.9);e.Speed=NumberRange.new(0,.25);e.Brightness=1.8
  end)
 end,
 Step=function(a,t)
  local G=a.Geo
  local st=a.Groups[3].State
  local world=a:WorldFrame()
  local speed=a.ReducedMotion and .55 or .95
  for _,m in ipairs(st.Motes)do
   local ang=t*speed+m.Phase
   local r=G.R*1.32+math.sin(t*1.7+m.Wobble)*.1*G.R
   local hop=math.abs(math.sin(t*7+m.Wobble))*.2*G.S
   local p=Vector3.new(G.Center.X+math.cos(ang)*r,G.Lo.Y+.2*G.S+hop,G.Center.Z+math.sin(ang)*r)
   Aura.Move(m.Part,CFrame.new(world:PointToWorldSpace(p)))
  end
 end,
}

---------------------------------------------------------------- Spiderdog
-- Silk threads up into the sky and down to the ground, a web under its feet, orange
-- glints in its eyes, drifting silk and a dark aura.
S.Spiderdog={
 Reduced=function(a,g)
  local G,cfg=a.Geo,a.Cfg
  local st=g.State
  st.Threads={}
  local silk=cfg.Accent
  local spots={{-.25,.2},{0,-.15},{.25,.3}}
  for i,spot in ipairs(spots)do
   local from=Vector3.new(G.Center.X+spot[1]*G.Size.X,G.Hi.Y-.08*G.Size.Y,G.Center.Z+spot[2]*G.Size.Z)
   local a0=a:Attachment(g,'AuraSilkUp'..i,from)
   local a1=a:Attachment(g,'AuraSilkSky'..i,from+Vector3.new(spot[1]*6*G.S,(46+i*8)*G.S,spot[2]*6*G.S))
   local beam=a:Beam(g,a0,a1,function(b)
    b.Name='SilkThread';b.Width0=.05*G.S;b.Width1=.03*G.S;b.Color=cs(silk);b.LightEmission=.35;b.Brightness=1
    b.Transparency=ns(0,.15,.7,.6,1,1)
   end)
   table.insert(st.Threads,beam)
  end
  for i,side in ipairs({-1,1})do
   local a0=a:Attachment(g,'AuraSilkSide'..i,G.Center+Vector3.new(side*.45*G.Size.X,0,0))
   local a1=a:Attachment(g,'AuraSilkGround'..i,G.Ground+Vector3.new(side*G.R*2.1,0,side*.4*G.R))
   a:Beam(g,a0,a1,function(b)
    b.Name='SilkAnchor';b.Width0=.035*G.S;b.Width1=.035*G.S;b.Color=cs(silk);b.LightEmission=.3;b.Transparency=ns(0,.2,1,.55)
   end)
  end
  a:Emitter(g,a:BodyPart(),3,function(e)
   Aura.Volume(e);e.Texture=T.Smoke;e.Color=cs(cfg.Deep);e.LightEmission=0;e.Transparency=ns(0,.62,1,1)
   e.Size=ns(0,1.1*G.S,1,2*G.S);e.Lifetime=NumberRange.new(2,3);e.Speed=NumberRange.new(.1,.35)
   e.Rotation=NumberRange.new(0,360);e.RotSpeed=NumberRange.new(-20,20)
  end)
 end,
 Full=function(a,g)
  local G,cfg=a.Geo,a.Cfg
  -- The web: eight spokes and three sagging rings.
  local rw=G.R*1.5
  a:Adorn(g,'WireframeHandleAdornment',function(o)
   o.Name='GroundWeb';o.Color3=cfg.Accent;o.Thickness=1.4;o.Transparency=.45
   local spokes=8
   local function at(j,r)local ang=j/spokes*math.pi*2;return Vector3.new(math.cos(ang)*r,0,math.sin(ang)*r)end
   for j=0,spokes-1 do o:AddLine(Vector3.zero,at(j,rw))end
   for _,f in ipairs({.38,.68,1})do
    for j=0,spokes-1 do
     local p0,p1=at(j,rw*f),at(j+1,rw*f)
     local mid=(p0+p1)/2*.88
     o:AddLine(p0,mid);o:AddLine(mid,p1)
    end
   end
   o.CFrame=a:Local(G.Ground+Vector3.new(0,.07,0))
  end)
  for _,name in ipairs({'Eye_L','Eye_R'})do
   local front=Vector3.new(G.Center.X+(name=='Eye_L'and -.12 or .12)*G.Size.X,G.Lo.Y+.75*G.Size.Y,G.Lo.Z+.1*G.Size.Z)
   local parent=a:BoneOr(g,{name,'Head'},front)
   a:Emitter(g,parent,1.6,function(e)
    e.Color=cs(cfg.Ember,cfg.Color);e.Size=ns(0,0,.15,.26*G.S,1,0);e.Lifetime=NumberRange.new(.25,.4);e.Speed=NumberRange.new(0,0)
    e.LockedToPart=true;e.Brightness=2;e.ZOffset=.08*G.S;e.Transparency=ns(0)
   end)
  end
  a:Emitter(g,a:BodyPart(),4,function(e)
   Aura.Volume(e);e.Color=cs(cfg.Accent);e.Size=ns(.07*G.S);e.Lifetime=NumberRange.new(3,5);e.Speed=NumberRange.new(.1,.35)
   e.Drag=1;e.Acceleration=Vector3.new(0,.12,0);e.Transparency=ns(0,.3,1,1);e.RotSpeed=NumberRange.new(-40,40);e.LightEmission=.6
  end)
 end,
 Step=function(a,t)
  local reduced=a.Groups[2]
  if not reduced then return end
  local G=a.Geo
  for i,beam in ipairs(reduced.State.Threads)do
   if beam.Parent then beam.CurveSize0=math.sin(t*.6+i*1.7)*.8*G.S;beam.CurveSize1=math.sin(t*.45+i)*1.6*G.S end
  end
 end,
}

---------------------------------------------------------------- WrongDog
-- Red glowing eyes (its RedEye bones), a red haze, a rare one-frame "wrong" flicker, and
-- up close it slowly turns its head to look at you.
local function restoreHead(st)
 local head=st.Head
 if head and head.Parent and st.Written then
  local cur=head.Transform
  if (cur.Position-st.Written.Position).Magnitude<1e-4 and cur.LookVector:Dot(st.Written.LookVector)>.99999 and cur.UpVector:Dot(st.Written.UpVector)>.99999 then
   head.Transform=st.Base or CFrame.identity
  end
 end
 st.Written=nil;st.Base=nil;st.Weight=0
end
S.WrongDog={
 Reduced=function(a,g)
  local G,cfg=a.Geo,a.Cfg
  local eyes={a:Bone('RedEye.L'),a:Bone('RedEye.R')}
  local parents={}
  for _,b in ipairs(eyes)do if b then table.insert(parents,b)end end
  if #parents==0 then
   local head=a:Bone('Head')
   table.insert(parents,head or a:Attachment(g,'AuraWrongEyes',Vector3.new(G.Center.X,G.Lo.Y+.82*G.Size.Y,G.Lo.Z+.12*G.Size.Z)))
  end
  for _,parent in ipairs(parents)do
   a:Emitter(g,parent,10,function(e)
    e.Color=cs(cfg.Color);e.Size=ns(0,.16*G.S*(#parents==1 and 1.4 or 1),1,.1*G.S);e.Lifetime=NumberRange.new(.18,.26)
    e.Speed=NumberRange.new(0,0);e.LockedToPart=true;e.Brightness=3;e.ZOffset=.04*G.S;e.Transparency=ns(0,.05,1,.6)
   end)
  end
 end,
 Full=function(a,g)
  local G,cfg=a.Geo,a.Cfg
  a:Emitter(g,a:BodyPart(),3,function(e)
   Aura.Volume(e);e.Texture=T.Smoke;e.Color=cs(cfg.Deep,cfg.Color);e.LightEmission=.25;e.Transparency=ns(0,.8,.5,.76,1,1)
   e.Size=ns(0,1.2*G.S,1,2.4*G.S);e.Lifetime=NumberRange.new(2.5,3.5);e.Speed=NumberRange.new(.1,.3)
   e.Rotation=NumberRange.new(0,360);e.RotSpeed=NumberRange.new(-20,20);e.Acceleration=Vector3.new(0,.1,0)
  end)
  local st=g.State
  st.Head=a:Bone('Head');st.Weight=0
  st.NextFlicker=os.clock()+rand(5,11)
  if not a.Low and not a.ReducedMotion then
   -- Used for the flicker when this dog has no steady highlight of its own.
   local h=Instance.new('Highlight');h:SetAttribute('SecretAura',true);h.Archivable=false
   h.Name='WrongFlicker';h.Adornee=a.Model;h.Enabled=false;h.DepthMode=Enum.HighlightDepthMode.Occluded
   h.FillColor=Color3.new(0,0,0);h.FillTransparency=.05;h.OutlineColor=cfg.Color;h.OutlineTransparency=0
   h.Parent=a.Folder
   a:Track(g,h);st.Flash=h
  end
 end,
 Step=function(a,t,dt,cam)
  local full=a.Groups[3]
  local st=full.State
  local cfg=a.Cfg
  -- The flicker: one frame (at least 1/30 s) of a black, red-edged dog and a wrong name.
  local lit=a.Groups.Highlight and a.Groups.Highlight.State.Highlight
  local plate=a.Groups[2]and a.Groups[2].State.Name
  if st.Flash and not a.ReducedMotion then
   if st.FlickUntil and t>=st.FlickUntil then
    st.FlickUntil=nil
    st.Flash.Enabled=false
    if lit and lit.Parent then lit.FillColor=(cfg.Highlight and cfg.Highlight.Fill)or cfg.Color;lit.OutlineColor=(cfg.Highlight and cfg.Highlight.Outline)or cfg.Accent;a.Groups.Highlight.Applied=-1 end
    if plate and plate.Parent then plate.Text=cfg.Plate.Name end
   elseif not st.FlickUntil and t>=st.NextFlicker and shownFull(a)>.9 then
    st.FlickUntil=t+1/30;st.NextFlicker=t+rand(7,15)
    if lit and lit.Parent then lit.FillColor=Color3.new(0,0,0);lit.FillTransparency=.05;lit.OutlineColor=cfg.Color;lit.OutlineTransparency=0
    else st.Flash.Enabled=true end
    if plate and plate.Parent then plate.Text=cfg.Plate.Glitch or cfg.Plate.Name end
   end
  end
  -- The head turns toward this client's camera (bones only, nothing replicates). Animated
  -- dogs rewrite the bone every step; static ones keep our write, so the base is kept.
  local head=st.Head
  if not head or not head.Parent then return end
  -- THE DOG's stare owns every head while it lasts.
  if DogLook.Current then restoreHead(st);return end
  local G=a.Geo
  local frame=a:WorldFrame()
  local spec=Config.WrongLook
  local near=(cam-frame:PointToWorldSpace(G.Center)).Magnitude<spec.Distance and shownFull(a)>.5
  -- About a second to turn, a little faster to look away.
  st.Weight=near and math.min(1,st.Weight+dt*1.1)or math.max(0,st.Weight-dt*1.6)
  local cur=head.Transform
  if st.Written and (cur.Position-st.Written.Position).Magnitude<1e-4 and cur.LookVector:Dot(st.Written.LookVector)>.99999 and cur.UpVector:Dot(st.Written.UpVector)>.99999 then
   cur=st.Base or cur
  else st.Base=cur end
  if st.Weight<=0 then
   if st.Written then head.Transform=st.Base or cur;st.Written=nil end
   return
  end
  local w=st.Weight*st.Weight*(3-2*st.Weight)
  local parent=head.Parent
  local parentCF=parent:IsA('Bone')and parent.TransformedWorldCFrame or(parent::BasePart).CFrame
  local rest=parentCF*head.CFrame
  local baseWorld=rest*cur
  local to=frame:VectorToObjectSpace(cam-baseWorld.Position)
  local flat=math.sqrt(to.X*to.X+to.Z*to.Z)
  local yaw=math.clamp(math.atan2(-to.X,-to.Z),-spec.Yaw,spec.Yaw)*w
  local pitch=math.clamp(math.atan2(to.Y,math.max(flat,1e-3)),-spec.Pitch,spec.Pitch)*w
  local up=frame.UpVector
  local turned=cur*CFrame.fromAxisAngle(baseWorld:VectorToObjectSpace(up),yaw)
  local right=(CFrame.fromAxisAngle(up,yaw)*frame.Rotation).RightVector
  turned=turned*CFrame.fromAxisAngle((rest*turned):VectorToObjectSpace(right),pitch)
  head.Transform=turned;st.Written=turned
 end,
 Clear=function(a,key,g)
  if key==3 then
   restoreHead(g.State)
   local plate=a.Groups[2]and a.Groups[2].State.Name
   if plate and plate.Parent then plate.Text=a.Cfg.Plate.Name end
  end
 end,
}

---------------------------------------------------------------- NuclearPug
-- A slow hazard-striped ring with a radiation trefoil on the ground, rising green motes,
-- glowing vents, a faint Geiger tick very close.
S.NuclearPug={
 Reduced=function(a,g)
  local G,cfg=a.Geo,a.Cfg
  local st=g.State
  st.Stripes,st.Blades={},{}
  local ground=G.Ground+Vector3.new(0,.085,0)
  for k=0,7 do
   table.insert(st.Stripes,a:Adorn(g,'CylinderHandleAdornment',function(o)
    o.Name='HazardStripe';o.Radius=G.R*1.42;o.InnerRadius=G.R*1.2;o.Height=.04;o.Angle=45
    o.Color3=k%2==0 and cfg.Accent or cfg.Soot;o.Transparency=.12
    o.CFrame=a:Local(ground,CFrame.Angles(0,k*math.pi/4,0)*Flat)
   end))
  end
  a:Adorn(g,'CylinderHandleAdornment',function(o)
   o.Name='HazardPlate';o.Radius=G.R*.98;o.InnerRadius=0;o.Height=.03;o.Color3=cfg.Soot;o.Transparency=.45
   o.CFrame=a:Local(G.Ground+Vector3.new(0,.065,0),Flat)
  end)
  for k=0,2 do
   table.insert(st.Blades,a:Adorn(g,'CylinderHandleAdornment',function(o)
    o.Name='Trefoil';o.Radius=G.R*.9;o.InnerRadius=G.R*.22;o.Height=.04;o.Angle=60
    o.Color3=cfg.Accent;o.Transparency=.3
    o.CFrame=a:Local(ground,CFrame.Angles(0,k*math.pi*2/3,0)*Flat)
   end))
  end
  a:Adorn(g,'CylinderHandleAdornment',function(o)
   o.Name='TrefoilCore';o.Radius=G.R*.14;o.InnerRadius=0;o.Height=.045;o.Color3=cfg.Accent;o.Transparency=.3
   o.CFrame=a:Local(ground,Flat)
  end)
  a:Emitter(g,a:BodyPart(),9,function(e)
   Aura.Volume(e);e.Color=cs(cfg.Color,cfg.Deep);e.Size=ns(0,.13*G.S,1,0);e.Lifetime=NumberRange.new(1.6,2.6)
   e.Speed=NumberRange.new(.4,1.2);e.EmissionDirection=Enum.NormalId.Top;e.SpreadAngle=Vector2.new(35,35)
   e.Acceleration=Vector3.new(0,.6,0);e.Brightness=2
  end)
 end,
 Full=function(a,g)
  local G,cfg=a.Geo,a.Cfg
  for _,name in ipairs({'Vent_L','Vent_R'})do
   local back=Vector3.new(G.Center.X+(name=='Vent_L'and -.2 or .2)*G.Size.X,G.Lo.Y+.8*G.Size.Y,G.Center.Z+.2*G.Size.Z)
   local parent=a:BoneOr(g,{name,'Backpack','Tank_L'},back)
   a:Emitter(g,parent,4,function(e)
    e.Texture=T.Smoke;e.Color=cs(cfg.Color,cfg.Deep);e.Size=ns(0,.18*G.S,1,.45*G.S);e.Transparency=ns(0,.35,1,1)
    e.Lifetime=NumberRange.new(.7,1.1);e.Speed=NumberRange.new(.3,.7);e.Acceleration=Vector3.new(0,1.6*G.S,0)
    e.SpreadAngle=Vector2.new(20,20);e.LightEmission=.9;e.Brightness=1.5
   end)
  end
  local st=g.State
  st.NextClick=0
  if not a.Low and not a.ReducedMotion then
   local s=Instance.new('Sound');s:SetAttribute('SecretAura',true);s.Archivable=false
   s.Name='GeigerTick';s.SoundId='rbxasset://sounds/volume_slider.ogg';s.Volume=Config.Geiger.Volume
   s.RollOffMode=Enum.RollOffMode.InverseTapered;s.RollOffMinDistance=3;s.RollOffMaxDistance=Config.Geiger.Distance+6
   local eq=Instance.new('EqualizerSoundEffect');eq.LowGain=-24;eq.MidGain=-6;eq.HighGain=4;eq.Parent=s
   s.Parent=a:BodyPart()
   a:Track(g,s);st.Geiger=s
  end
 end,
 Step=function(a,t,_,cam)
  local G=a.Geo
  local reduced=a.Groups[2]
  if reduced then
   local ground=G.Ground+Vector3.new(0,.085,0)
   local spin=t*(a.ReducedMotion and .1 or .22)
   for k,o in ipairs(reduced.State.Stripes)do o.CFrame=a:Local(ground,CFrame.Angles(0,spin+(k-1)*math.pi/4,0)*Flat)end
   for k,o in ipairs(reduced.State.Blades)do o.CFrame=a:Local(ground,CFrame.Angles(0,-spin*.55+(k-1)*math.pi*2/3,0)*Flat)end
  end
  -- Geiger clicks: random (Poisson) and faster the closer the camera is.
  local st=a.Groups[3].State
  local s=st.Geiger
  if s and s.Parent and t>=st.NextClick then
   local spec=Config.Geiger
   local d=(cam-a:World(G.Center).Position).Magnitude
   if d<spec.Distance and shownFull(a)>.5 then
    local close=1-d/spec.Distance
    local rate=1+(spec.MaxPerSecond-1)*close*close
    s.PlaybackSpeed=rand(2.6,3.6);s.TimePosition=0;s:Play()
    st.NextClick=t+math.max(spec.MinGap,-math.log(math.max(rng:NextNumber(),1e-4))/rate)
   else st.NextClick=t+.25 end
  end
 end,
}

---------------------------------------------------------------- 404Dog
-- Blue square pixels breaking off it, glitch slices (a slow scanline with ReducedMotion),
-- a floating "404".
S['404Dog']={
 Reduced=function(a,g)
  local G,cfg=a.Geo,a.Cfg
  local at=a:Attachment(g,'Aura404',G.Top+Vector3.new(0,.5*G.S+.12*G.Size.Y,0))
  local gui=a:Billboard(g,at,function(b)b.Name='NotFound';b.Size=UDim2.fromScale(2.4*G.S,1.1*G.S);b.MaxDistance=160;b.Brightness=1.6 end)
  local l=label(gui,'404',Enum.Font.Arcade,cfg.Color,Color3.new(1,1,1));l.TextStrokeTransparency=.15
  a:FadeGui(g,gui)
  g.State.Text=l;g.State.Gui=gui
  a:Emitter(g,a:BodyPart(),5,function(e)
   Aura.Volume(e);e.Color=cs(cfg.Color,cfg.Accent);e.Size=ns(0,.12*G.S,1,0);e.Lifetime=NumberRange.new(.5,1);e.Speed=NumberRange.new(.2,.7)
  end)
 end,
 Full=function(a,g)
  local G,cfg=a.Geo,a.Cfg
  local st=g.State
  st.Pixels={}
  for _=1,a.Low and 3 or 8 do
   local o=a:Adorn(g,'BoxHandleAdornment',function(o)o.Name='Pixel';o.Size=Vector3.one*.16*G.S;o.Color3=cfg.Color;o.Transparency=1 end,false)
   table.insert(st.Pixels,{O=o,Born=0,Dies=0,P=Vector3.zero,V=Vector3.zero})
  end
  st.Slices={}
  for _=1,a.ReducedMotion and 1 or 3 do
   local o=a:Adorn(g,'BoxHandleAdornment',function(o)o.Name='GlitchSlice';o.Size=Vector3.new(G.Size.X*1.3,.08*G.Size.Y,G.Size.Z*1.15);o.Color3=cfg.Accent;o.Transparency=1;o.Visible=false end,false)
   table.insert(st.Slices,o)
  end
  st.NextGlitch=os.clock()+rand(1,3);st.GlitchUntil=0
 end,
 Step=function(a,t)
  local G,cfg=a.Geo,a.Cfg
  local st=a.Groups[3].State
  local shown=shownFull(a)
  local grid=.16*G.S
  for _,px in ipairs(st.Pixels)do
   if t>=px.Dies then
    local r=Vector3.new(rand(0,1),rand(.1,1),rand(0,1))
    local p=G.Lo+G.Size*r
    px.P=Vector3.new(math.floor(p.X/grid+.5)*grid,math.floor(p.Y/grid+.5)*grid,math.floor(p.Z/grid+.5)*grid)
    px.V=Vector3.new(rand(-.15,.15),rand(.3,.7),rand(-.15,.15))*G.S
    px.Born=t;px.Dies=t+rand(.8,1.4)
    local pick=rng:NextInteger(1,8)
    px.O.Color3=pick==8 and cfg.Error or pick>=6 and cfg.Accent or pick==5 and Color3.new(1,1,1)or cfg.Color
    px.O.Size=Vector3.one*grid*(rng:NextInteger(1,2)==1 and 1 or .6)
   end
   local age=t-px.Born
   local k=age/(px.Dies-px.Born)
   px.O.CFrame=a:Local(px.P+px.V*age)
   px.O.Transparency=1-(1-k)*.9*shown
  end
  local reduced=a.Groups[2]
  local text=reduced and reduced.State.Text
  if a.ReducedMotion then
   -- One slow scanline instead of flicker.
   local o=st.Slices[1]
   local k=(t*.42)%1
   o.Visible=true;o.Size=Vector3.new(G.Size.X*1.25,.03*G.Size.Y,G.Size.Z*1.12)
   o.CFrame=a:Local(Vector3.new(G.Center.X,G.Lo.Y+G.Size.Y*k,G.Center.Z));o.Transparency=1-.4*shown
  else
   if t>=st.NextGlitch then
    st.GlitchUntil=t+rand(.05,.11);st.NextGlitch=t+rand(1.5,4)
    for _,o in ipairs(st.Slices)do
     o.Size=Vector3.new(G.Size.X*rand(1,1.4),G.Size.Y*rand(.04,.12),G.Size.Z*rand(1,1.2))
     o.CFrame=a:Local(Vector3.new(G.Center.X+rand(-.25,.25)*G.Size.X,G.Lo.Y+G.Size.Y*rand(.1,.95),G.Center.Z))
     local pick=rng:NextInteger(1,3)
     o.Color3=pick==1 and cfg.Color or pick==2 and cfg.Accent or Color3.new(1,1,1)
    end
    if text and text.Parent then text.Text=({'4O4','ERR','4 0 4','404?'})[rng:NextInteger(1,4)]end
   end
   local on=t<st.GlitchUntil
   for _,o in ipairs(st.Slices)do o.Visible=on;o.Transparency=1-.65*shown end
   if not on and text and text.Parent and text.Text~='404'then text.Text='404'end
  end
  local gui=reduced and reduced.State.Gui
  if gui and gui.Parent then gui.StudsOffsetWorldSpace=Vector3.new(0,math.sin(t*1.6)*.15*G.S,0)end
 end,
 Clear=function(a,key)
  local reduced=a.Groups[2]
  if key==3 and reduced and reduced.State.Text and reduced.State.Text.Parent then reduced.State.Text.Text='404'end
 end,
}

---------------------------------------------------------------- UnfinishedDog
-- A flickering selection box and move gizmo (it is still in the editor), magenta/black
-- missing-texture motes, a "-- TODO" note.
local TODO={'-- TODO: finish dog','-- FIXME: legs?','-- placeholder','-- missing texture','// v0.0.1-dev'}
S.UnfinishedDog={
 Reduced=function(a,g)
  local G,cfg=a.Geo,a.Cfg
  g.State.Outline=a:Adorn(g,'WireframeHandleAdornment',function(o)
   o.Name='SelectionBox';o.Color3=cfg.Accent;o.Thickness=2.2;o.Transparency=.1
   box(o,G.Size/2*1.06)
   o.CFrame=a:Local(G.Center)
  end)
  local at=a:Attachment(g,'AuraTodo',G.Top+Vector3.new(0,.45*G.S+.08*G.Size.Y,0))
  local gui=a:Billboard(g,at,function(b)b.Name='TodoNote';b.Size=UDim2.fromScale(3.6*G.S,.62*G.S);b.MaxDistance=110 end)
  local back=Instance.new('Frame');back.Size=UDim2.fromScale(1,1);back.BackgroundColor3=cfg.Deep;back.BackgroundTransparency=.3;back.BorderSizePixel=0;back.Parent=gui
  local l=label(back,TODO[1],Enum.Font.Code,Color3.fromRGB(255,170,255),Color3.new(0,0,0));l.TextStrokeTransparency=.7
  a:FadeGui(g,back)
  g.State.Todo=l;g.State.Line=1;g.State.NextLine=0
 end,
 Full=function(a,g)
  local G,cfg=a.Geo,a.Cfg
  local len=.45*G.Size.Y
  local axes={{CFrame.Angles(0,math.pi/2,0),Vector3.xAxis,Color3.fromRGB(255,70,70)},{CFrame.Angles(-math.pi/2,0,0),Vector3.yAxis,Color3.fromRGB(80,230,80)},{CFrame.identity,Vector3.zAxis,Color3.fromRGB(70,140,255)}}
  for _,axis in ipairs(axes)do
   a:Adorn(g,'CylinderHandleAdornment',function(o)
    o.Name='GizmoShaft';o.Radius=.03*G.S;o.Height=len;o.Color3=axis[3];o.Transparency=.1
    o.CFrame=a:Local(G.Center+axis[2]*len/2,axis[1])
   end)
   a:Adorn(g,'ConeHandleAdornment',function(o)
    o.Name='GizmoTip';o.Radius=.09*G.S;o.Height=.22*G.S;o.Color3=axis[3];o.Transparency=.1
    o.CFrame=a:Local(G.Center+axis[2]*len,axis[1])
   end)
  end
  local st=g.State
  st.Motes={}
  local core=a:Attachment(g,'AuraCore',G.Center)
  for i=1,a.Low and 2 or 4 do
   local gui=a:Billboard(g,core,function(b)b.Name='MissingTexture';b.Size=UDim2.fromScale(.4*G.S,.4*G.S);b.MaxDistance=110 end)
   for x=0,1 do for y=0,1 do
    local f=Instance.new('Frame');f.BorderSizePixel=0;f.Size=UDim2.fromScale(.5,.5);f.Position=UDim2.fromScale(x*.5,y*.5)
    f.BackgroundColor3=(x+y)%2==0 and cfg.Color or cfg.Deep;f.Parent=gui
   end end
   a:FadeGui(g,gui)
   table.insert(st.Motes,{Gui=gui,Phase=i*1.57,Radius=G.R*rand(.9,1.3),Height=rand(.2,.9)*G.Size.Y,Speed=rand(.35,.6)*(i%2==0 and -1 or 1)})
  end
  st.NextFlick=os.clock()+rand(.5,2);st.FlickUntil=0
 end,
 Step=function(a,t)
  local G,cfg=a.Geo,a.Cfg
  local st=a.Groups[3].State
  for _,m in ipairs(st.Motes)do
   local ang=t*m.Speed+m.Phase
   m.Gui.StudsOffsetWorldSpace=Vector3.new(math.cos(ang)*m.Radius,m.Height-G.Size.Y/2+math.sin(t*1.1+m.Phase)*.15*G.S,math.sin(ang)*m.Radius)
  end
  local reduced=a.Groups[2]
  local outline=reduced and reduced.State.Outline
  if outline and outline.Parent then
   local visible=true
   if not a.ReducedMotion then
    if t>=st.NextFlick then
     st.FlickUntil=t+rand(.05,.14);st.NextFlick=t+rand(.6,2.6)
     if rng:NextInteger(1,3)==1 then outline.Color3=outline.Color3==cfg.Accent and cfg.Color or cfg.Accent end
    end
    visible=t>=st.FlickUntil
   end
   outline.Visible=visible
  end
 end,
 Tick=function(a)
  local reduced=a.Groups[2]
  if not reduced or not reduced.State.Todo then return end
  local st=reduced.State
  local now=os.clock()
  if a.Groups[3]and now>=st.NextLine and st.Todo.Parent then
   st.Line=st.Line%#TODO+1;st.Todo.Text=TODO[st.Line];st.NextLine=now+rand(2.5,4.5)
  end
 end,
 Clear=function(a,key)
  local reduced=a.Groups[2]
  if key==3 and reduced and reduced.State.Outline and reduced.State.Outline.Parent then reduced.State.Outline.Visible=true;reduced.State.Outline.Color3=a.Cfg.Accent end
 end,
}

---------------------------------------------------------------- DivineDog
-- A turning golden halo above it, a god-ray from the sky, drifting feathers, warm light.
local function haloAt(a,t)
 local G=a.Geo
 local bob=math.sin(t*1.2)*.04*G.Size.Y
 return G.Top+Vector3.new(0,.14*G.Size.Y+bob,.06*G.Size.Z),CFrame.Angles(-.22+math.sin(t*.7)*.05,0,math.sin(t*.5)*.05)
end
S.DivineDog={
 Reduced=function(a,g)
  local G,cfg=a.Geo,a.Cfg
  local hr=math.clamp(.3*math.max(G.Size.X,G.Size.Z),.5,6)
  local p,tilt=haloAt(a,0)
  local st=g.State
  st.HaloRadius=hr
  st.Halo=a:Adorn(g,'CylinderHandleAdornment',function(o)
   o.Name='Halo';o.Radius=hr;o.InnerRadius=hr*.8;o.Height=.06*G.S;o.Color3=cfg.Accent;o.Transparency=.1
   o.CFrame=a:Local(p,tilt*Flat)
  end)
  st.Glow=a:Adorn(g,'CylinderHandleAdornment',function(o)
   o.Name='HaloGlow';o.Radius=hr*1.18;o.InnerRadius=hr*.66;o.Height=.03*G.S;o.Color3=cfg.Deep;o.Transparency=.72
   o.CFrame=a:Local(p,tilt*Flat)
  end)
  local sky=a:Attachment(g,'AuraGodSky',G.Top+Vector3.new(0,9*G.Size.Y,0))
  local low=a:Attachment(g,'AuraGodLow',G.Top+Vector3.new(0,.1*G.Size.Y,0))
  a:Beam(g,sky,low,function(b)
   b.Name='GodRay';b.Width0=G.Size.X*2.2;b.Width1=G.Size.X*.9;b.Color=cs(cfg.Deep,cfg.Color);b.Brightness=1.4
   b.Transparency=ns(0,.98,.5,.86,1,.74);b.Texture=T.Smoke;b.TextureMode=Enum.TextureMode.Wrap;b.TextureLength=8*G.S;b.TextureSpeed=-.3
  end)
  a:Emitter(g,a:BodyPart(),4,function(e)
   Aura.Volume(e);e.Color=cs(cfg.Deep,cfg.Accent);e.Size=ns(0,.14*G.S,1,0);e.Lifetime=NumberRange.new(.8,1.4);e.Speed=NumberRange.new(.1,.5);e.Brightness=1.8
  end)
 end,
 Full=function(a,g)
  local G,cfg=a.Geo,a.Cfg
  local st=g.State
  st.Beads={}
  for i=1,a.Low and 3 or 6 do
   table.insert(st.Beads,a:Adorn(g,'SphereHandleAdornment',function(o)
    o.Name='HaloBead';o.Radius=.05*G.S;o.Color3=i%2==0 and cfg.Deep or cfg.Accent;o.Transparency=1
   end,false))
  end
  local above=a:Attachment(g,'AuraFeathers',G.Top+Vector3.new(0,.3*G.Size.Y,0))
  a:Emitter(g,above,3,function(e)
   e.Texture=T.Fire;e.Color=cs(Color3.new(1,1,1),cfg.Deep);e.Size=ns(.22*G.S);e.Squash=ns(.6)
   e.Transparency=ns(0,1,.1,.15,.85,.3,1,1);e.Lifetime=NumberRange.new(3.5,5.5);e.Speed=NumberRange.new(.4,1)
   e.SpreadAngle=Vector2.new(50,50);e.EmissionDirection=Enum.NormalId.Top;e.Acceleration=Vector3.new(0,-.6*G.S,0);e.Drag=1.4
   e.Rotation=NumberRange.new(0,360);e.RotSpeed=NumberRange.new(-90,90);e.LightEmission=.7
  end)
 end,
 Step=function(a,t)
  local reduced=a.Groups[2]
  if not reduced then return end
  local rs=reduced.State
  local p,tilt=haloAt(a,t)
  local cf=a:Local(p,tilt)
  if rs.Halo and rs.Halo.Parent then rs.Halo.CFrame=cf*Flat end
  if rs.Glow and rs.Glow.Parent then rs.Glow.CFrame=cf*Flat end
  if not rs.HaloRadius then return end
  local shown=shownFull(a)
  local beads=a.Groups[3].State.Beads
  local r=rs.HaloRadius*.9
  local spin=t*(a.ReducedMotion and .4 or .9)
  for i,o in ipairs(beads)do
   local ang=spin+(i-1)/#beads*math.pi*2
   o.CFrame=cf*CFrame.new(math.cos(ang)*r,0,math.sin(ang)*r)
   o.Transparency=1-.95*shown
  end
 end,
}

---------------------------------------------------------------- TheDog
-- An eclipse: a white corona ring behind it (camera-facing), black void smoke, glowing
-- eyes, a shadow pool, and the view darkens a little up close (manager).
S.TheDog={
 Reduced=function(a,g)
  local G,cfg=a.Geo,a.Cfg
  local core=a:Attachment(g,'AuraCore',G.Center)
  local d=1.35*math.max(G.Size.Y,G.Size.Z*.8)
  local gui=a:Billboard(g,core,function(b)
   b.Name='Corona';b.Size=UDim2.fromScale(d,d);b.MaxDistance=260;b.Brightness=2.5
   -- Camera space: pushed back so the dog stands in front of its own eclipse.
   b.StudsOffset=Vector3.new(0,0,-.6*math.max(G.Size.X,G.Size.Y,G.Size.Z))
  end)
  local spin=Instance.new('Frame');spin.Name='Spin';spin.BackgroundTransparency=1;spin.Size=UDim2.fromScale(1,1);spin.Parent=gui
  local dots={}
  local n=a.Low and 18 or 28
  for i=1,n do
   local ang=(i-1)/n*math.pi*2
   table.insert(dots,dot(spin,.085,UDim2.fromScale(.5+math.cos(ang)*.42,.5+math.sin(ang)*.42),cfg.Accent,.05))
  end
  for i=1,a.Low and 0 or 14 do
   local ang=(i-.5)/14*math.pi*2
   dot(spin,.17,UDim2.fromScale(.5+math.cos(ang)*.44,.5+math.sin(ang)*.44),cfg.Accent,.84)
  end
  a:FadeGui(g,spin)
  g.State.Dots=dots;g.State.Spin=spin
  a:Adorn(g,'CylinderHandleAdornment',function(o)
   o.Name='ShadowPool';o.Radius=G.R*1.55;o.InnerRadius=0;o.Height=.03;o.Color3=Color3.new(0,0,0);o.Transparency=.5
   o.CFrame=a:Local(G.Ground+Vector3.new(0,.055,0),Flat)
  end)
  a:Emitter(g,a:BodyPart(),6,function(e)
   Aura.Volume(e);e.Texture=T.Smoke;e.Color=cs(Color3.new(0,0,0));e.LightEmission=0;e.Transparency=ns(0,.35,1,1)
   e.Size=ns(0,.5*G.S,1,1.6*G.S);e.Lifetime=NumberRange.new(2,3);e.Speed=NumberRange.new(.2,.6);e.EmissionDirection=Enum.NormalId.Top
   e.SpreadAngle=Vector2.new(25,25);e.Rotation=NumberRange.new(0,360);e.RotSpeed=NumberRange.new(-30,30)
  end)
 end,
 Full=function(a,g)
  local G,cfg=a.Geo,a.Cfg
  local front=Vector3.new(G.Center.X,G.Lo.Y+.8*G.Size.Y,G.Lo.Z+.15*G.Size.Z)
  local head=a:BoneOr(g,{'head'},front)
  local w=.9*G.S
  local gui=a:Billboard(g,head,function(b)
   b.Name='Eyes';b.Size=UDim2.fromScale(w,w*.4);b.MaxDistance=120;b.Brightness=4
   -- Camera space, toward the camera: the eyes stay in front of the face.
   b.StudsOffset=Vector3.new(0,.02*G.Size.Y,.16*math.max(G.Size.X,G.Size.Z))
  end)
  for _,x in ipairs({.3,.7})do
   dot(gui,.9,UDim2.fromScale(x,.5),cfg.Accent,.84)
   dot(gui,.34,UDim2.fromScale(x,.5),cfg.Accent,0)
  end
  for _,f in ipairs(gui:GetChildren())do if f:IsA('Frame')then f.SizeConstraint=Enum.SizeConstraint.RelativeYY end end
  a:FadeGui(g,gui)
 end,
 Step=function(a,t)
  local reduced=a.Groups[2]
  local spin=reduced and reduced.State.Spin
  if spin and spin.Parent then spin.Rotation=(t*(a.ReducedMotion and 2 or 6))%360 end
 end,
 Tick=function(a)
  -- The corona boils: every bead's brightness drifts.
  local reduced=a.Groups[2]
  if not reduced or not reduced.State.Dots then return end
  local dots=reduced.State.Dots
  local alpha=reduced.Alpha*a.Alpha
  for _,f in ipairs(dots)do
   if f.Parent then f.BackgroundTransparency=1-(1-rand(0,.4))*alpha end
  end
 end,
}

---------------------------------------------------------------- LongDog
-- A tape measure laid along it on the ground (ticks, case, hook, a sliding mark), an "∞"
-- tag on the case, dust at its feet.
S.LongDog={
 Reduced=function(a,g)
  local G,cfg=a.Geo,a.Cfg
  local L=G.Size.Z
  local w=.34*G.S
  local x=G.Hi.X+.3*G.S
  local y=G.Lo.Y+.04
  local center=Vector3.new(x,y,G.Center.Z)
  a:Adorn(g,'BoxHandleAdornment',function(o)
   o.Name='Tape';o.Size=Vector3.new(w,.03,L);o.Color3=cfg.Accent;o.Transparency=0
   o.CFrame=a:Local(center)
  end)
  a:Adorn(g,'WireframeHandleAdornment',function(o)
   o.Name='TapeTicks';o.Color3=cfg.Deep;o.Thickness=1.3;o.Transparency=0
   local n=math.clamp(math.floor(L/(.25*G.S)),8,120)
   for i=0,n do
    local z=-L/2+i*L/n
    local major=i%4==0
    o:AddLine(Vector3.new(-w/2,.02,z),Vector3.new(-w/2+w*(major and .7 or .38),.02,z))
   end
   o.CFrame=a:Local(center)
  end)
  local caseAt=Vector3.new(x,y+.25*G.S,G.Center.Z+L/2+.28*G.S)
  a:Adorn(g,'BoxHandleAdornment',function(o)
   o.Name='TapeCase';o.Size=Vector3.new(.6*G.S,.5*G.S,.55*G.S);o.Color3=Color3.fromRGB(70,72,80);o.Transparency=0
   o.CFrame=a:Local(caseAt)
  end)
  a:Adorn(g,'BoxHandleAdornment',function(o)
   o.Name='TapeButton';o.Size=Vector3.new(.2*G.S,.08*G.S,.2*G.S);o.Color3=Color3.fromRGB(220,50,40);o.Transparency=0
   o.CFrame=a:Local(caseAt+Vector3.new(0,.28*G.S,0))
  end)
  a:Adorn(g,'BoxHandleAdornment',function(o)
   o.Name='TapeHook';o.Size=Vector3.new(w*1.1,.14*G.S,.05*G.S);o.Color3=Color3.fromRGB(150,40,30);o.Transparency=0
   o.CFrame=a:Local(Vector3.new(x,y+.06*G.S,G.Center.Z-L/2))
  end)
  local tagAt=a:Attachment(g,'AuraInfinity',caseAt+Vector3.new(0,.5*G.S,0))
  local gui=a:Billboard(g,tagAt,function(b)b.Name='Infinity';b.Size=UDim2.fromOffset(64,30);b.MaxDistance=100;b.StudsOffset=Vector3.new(0,.3,0)end)
  local pill=Instance.new('Frame');pill.Size=UDim2.fromScale(1,1);pill.BackgroundColor3=cfg.Plate.Back;pill.BackgroundTransparency=.15;pill.BorderSizePixel=0;pill.Parent=gui
  local c=Instance.new('UICorner');c.CornerRadius=UDim.new(.5,0);c.Parent=pill
  local stroke=Instance.new('UIStroke');stroke.Color=cfg.Accent;stroke.Thickness=1.5;stroke.Parent=pill
  local l=label(pill,'∞',Enum.Font.FredokaOne,cfg.Accent,cfg.Deep)
  a:FadeGui(g,pill)
  g.State.Tag=l;g.State.NextTag=0;g.State.TapeX=x;g.State.TapeY=y;g.State.Width=w
 end,
 Full=function(a,g)
  local G,cfg=a.Geo,a.Cfg
  for i,z in ipairs({G.Lo.Z+.18*G.Size.Z,G.Hi.Z-.2*G.Size.Z})do
   local at=a:Attachment(g,'AuraDust'..i,Vector3.new(G.Center.X,G.Lo.Y+.05,z))
   a:Emitter(g,at,2.5,function(e)
    e.Texture=T.Smoke;e.Color=cs(cfg.Color,cfg.Bone);e.LightEmission=0;e.LightInfluence=1;e.Size=ns(0,.25*G.S,1,.8*G.S)
    e.Transparency=ns(0,.55,1,1);e.Lifetime=NumberRange.new(1,1.6);e.Speed=NumberRange.new(.3,.8);e.SpreadAngle=Vector2.new(60,60)
    e.EmissionDirection=Enum.NormalId.Top;e.Acceleration=Vector3.new(0,.25,0)
   end)
  end
  local reduced=a.Groups[2]
  local w=reduced and reduced.State.Width or .34*G.S
  g.State.Mark=a:Adorn(g,'BoxHandleAdornment',function(o)
   o.Name='TapeMark';o.Size=Vector3.new(w*1.05,.05,.06*G.S);o.Color3=Color3.fromRGB(220,40,30);o.Transparency=1
  end,false)
 end,
 Step=function(a,t)
  local G=a.Geo
  local reduced,full=a.Groups[2],a.Groups[3]
  if not reduced then return end
  local mark=full.State.Mark
  local z=G.Center.Z+math.sin(t*.5)*G.Size.Z*.47
  mark.CFrame=a:Local(Vector3.new(reduced.State.TapeX,reduced.State.TapeY+.03,z))
  mark.Transparency=1-shownFull(a)
 end,
 Tick=function(a)
  local reduced=a.Groups[2]
  if not reduced or not reduced.State.Tag then return end
  local st=reduced.State
  local now=os.clock()
  if a.Groups[3]and now>=st.NextTag and st.Tag.Parent then
   local reading=({'∞','9999 m','∞','??? m','∞','1 dog'})
   st.Index=(st.Index or 0)%#reading+1
   st.Tag.Text=reading[st.Index];st.NextTag=now+(reading[st.Index]=='∞'and 3 or 1.4)
  end
 end,
}

---------------------------------------------------------------- Aurion
-- Rainbow prism sparkles cycling hue, soft aurora curtains rising from it, prismatic
-- light; the drum symbol gets the sparkles only.
local function aurora(a,g,name,phase,widthScale)
 local G=a.Geo
 local base=a:Attachment(g,'Aura'..name..'Base',G.Top+Vector3.new(0,.2*G.Size.Y,0))
 local sky=a:Attachment(g,'Aura'..name..'Sky',G.Top+Vector3.new(0,6.5*G.Size.Y,0))
 local span=math.max(G.Size.X,G.Size.Z)
 return a:Beam(g,base,sky,function(b)
  b.Name=name;b.Width0=.9*span*widthScale;b.Width1=2.6*span*widthScale;b.Color=Common.Rainbow(phase,.5);b.Brightness=1.4
  b.Transparency=ns(0,.86,.3,.72,.75,.85,1,1);b.CurveSize0=1.2*G.Size.Y;b.CurveSize1=-.8*G.Size.Y;b.Segments=16
  b.Texture=T.Smoke;b.TextureMode=Enum.TextureMode.Wrap;b.TextureLength=6*G.S;b.TextureSpeed=.25
 end)
end
local function prism(a,g,parent,rate,size,volume)
 return a:Emitter(g,parent,rate,function(e)
  if volume then Aura.Volume(e)end
  e.Color=Common.Rainbow(0,.6);e.Size=ns(0,size,1,0);e.Lifetime=NumberRange.new(.8,1.5);e.Speed=NumberRange.new(.4,1.4);e.Brightness=2
 end)
end
S.Aurion={
 Reduced=function(a,g)
  local G=a.Geo
  g.State.Auroras={aurora(a,g,'Aurora',0,1)}
  g.State.Prism={prism(a,g,a:BodyPart(),10,.16*G.S,true)}
 end,
 Full=function(a,g)
  local G=a.Geo
  g.State.Auroras={aurora(a,g,'AuroraB',.5,.7)}
  g.State.Prism={prism(a,g,a:BodyPart(),6,.1*G.S,true)}
 end,
 Mini=function(a,g)
  local G=a.Geo
  local at=a:Attachment(g,'AuraPrism',G.Center)
  g.State.Prism={prism(a,g,at,4,.14*G.S,false)}
 end,
 Step=function(a,t)
  local G=a.Geo
  for key,k in pairs({[2]=1,[3]=-1})do
   local grp=a.Groups[key]
   for i,b in ipairs(grp and grp.State.Auroras or {})do
    if b.Parent then b.CurveSize0=(1.2+math.sin(t*.5+i)*.6)*G.Size.Y*k;b.CurveSize1=-(.8+math.sin(t*.37+i*2)*.5)*G.Size.Y*k end
   end
  end
  local light=a.Groups.Light and a.Groups.Light.State.Light
  if light and light.Parent then light.Color=Color3.fromHSV((t*.06)%1,.45,1)end
 end,
 Tick=function(a)
  local offset=(os.clock()*.12)%1
  for _,key in ipairs({2,3})do
   local grp=a.Groups[key]
   if grp then
    for _,e in ipairs(grp.State.Prism or {})do if e.Parent then e.Color=Common.Rainbow(offset,.6)end end
    for i,b in ipairs(grp.State.Auroras or {})do if b.Parent then b.Color=Common.Rainbow(offset+i*.37,.5)end end
   end
  end
 end,
}
return S
