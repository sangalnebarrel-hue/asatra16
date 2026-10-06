-- LONG DOG: "IT NEVER ENDS". Dug up in its owner's yard, and it does not stop coming out.
-- The ground splits, the head bursts out and runs a lap of the WHOLE island (up the west
-- lawns, past the plaza, the museum and the DOG-O-MATIC, down the boulevard, through the
-- arches, the east lawns, and over the top of the giant head) while its body keeps pouring
-- out of the hole behind it: one dachshund, two kilometres long, lying across every yard. Every dog on the island
-- turns to follow the head, every screen counts its LENGTH, every camera rides along. Back
-- at the hole the head finds its body still coming out; the tail finally pops free, the
-- whole body snaps back along its path like a tape measure, and a perfectly normal Long Dog
-- stands at the hole.
local Players=game:GetService('Players')
local AssetService=game:GetService('AssetService')
local RS=game:GetService('ReplicatedStorage')
local AnimationPlayer=require(RS:WaitForChild('DogAnimationPlayer'))
local Config=require(RS:WaitForChild('SecretArrivalConfig'))
local C=Color3.fromRGB
local SAND,DIRT,DUST,BONE,VOID,BAND=C(240,196,120),C(104,72,42),C(196,164,120),C(246,240,224),C(0,0,0),C(64,40,26)
-- Until the dog's own texture has been sampled (or if it cannot be).
local FUR=C(198,135,74)
local TICK='rbxasset://sounds/volume_slider.ogg'
-- The runner, in template units (the template is 2.19 tall and 5.9 long): 29.5 studs long
-- and a body 4.2 studs thick, so the far end of the island still sees it.
local SCALE=5
local SPINE=1.02    -- the spine's height above the paws
local RADIUS=.42    -- the body's radius
local SEAM=1.44     -- where the tube meets a runner: LongSeg3, behind the front legs
local REAR=4.1      -- from the front legs to the tip of the tail
local STEP=2        -- path resolution, studs
-- Beats on the arrival clock: out of the hole, back at the hole, the tail pops out, the
-- snap starts, the tail reaches the head (the real dog appears).
local T_OUT,T_STOP,T_POP,T_SNAP,T_JOIN=.9,11,11.6,12.3,13.6
-- The lap: its spine's path (world studs), checked against every visible part of the island
-- with room to spare: up the west lawns, the plaza, past the museum, round the DOG-O-MATIC,
-- down the boulevard and through the arches, the east lawns, then over the giant head.
-- It starts and ends wherever it passes closest to the hole. (SecretArrivalConfig.Map.LongDogLap
-- overrides it.)
local LAP:{Vector3}={
 Vector3.new(-110,6.1,-112),Vector3.new(-110,6.1,-40),Vector3.new(-110,6.1,40),Vector3.new(-110,7.1,112),
 Vector3.new(-118,30.1,205),Vector3.new(-60,23.1,300),Vector3.new(-40,23.1,400),Vector3.new(-35,25.1,470),
 Vector3.new(-48,26.1,530),Vector3.new(-80,19.1,575),Vector3.new(-88,13.1,630),Vector3.new(-80,14.1,676),
 Vector3.new(-52,15.1,690),Vector3.new(-20,17.1,650),Vector3.new(0,17.1,580),Vector3.new(0,17.1,520),
 Vector3.new(0,19.1,440),Vector3.new(20,33.1,405),Vector3.new(50,23.1,330),Vector3.new(40,23.1,240),
 Vector3.new(-25,35.1,190),Vector3.new(-22,39.1,152),Vector3.new(22,39.1,142),Vector3.new(72,23.1,140),
 Vector3.new(110,7.1,112),Vector3.new(110,6.1,40),Vector3.new(110,6.1,-40),Vector3.new(110,6.1,-112),
 Vector3.new(85,44.1,-175),Vector3.new(0,99.1,-205),Vector3.new(-85,44.1,-175),
}
-- High behind the giant head, looking up the whole island.
local OVERVIEW=CFrame.lookAt(Vector3.new(0,150,-280),Vector3.new(0,20,420))
local function smooth(x)x=math.clamp(x,0,1);return x*x*(3-2*x)end

-- Centripetal Catmull-Rom between p1 and p2 (no loops or overshoot at sharp corners).
local function spline(p0:Vector3,p1:Vector3,p2:Vector3,p3:Vector3,t:number):Vector3
 local function knot(k,a,b)return k+math.max((b-a).Magnitude,1e-3)^.5 end
 local t0=0;local t1=knot(t0,p0,p1);local t2=knot(t1,p1,p2);local t3=knot(t2,p2,p3)
 local u=t1+(t2-t1)*t
 local a1=p0*((t1-u)/(t1-t0))+p1*((u-t0)/(t1-t0))
 local a2=p1*((t2-u)/(t2-t1))+p2*((u-t1)/(t2-t1))
 local a3=p2*((t3-u)/(t3-t2))+p3*((u-t2)/(t3-t2))
 local b1=a1*((t2-u)/(t2-t0))+a2*((u-t0)/(t2-t0))
 local b2=a2*((t3-u)/(t3-t1))+a3*((u-t1)/(t3-t1))
 return b1*((t2-u)/(t2-t1))+b2*((u-t1)/(t2-t1))
end

-- The average colour of the dog's own fur texture (an EditableImage of its ColorMap), so
-- the long body matches the head. Yields; falls back to FUR when the image is not readable.
local function sampleFur(model:Model?):Color3?
 local sa=model and model:FindFirstChildWhichIsA('SurfaceAppearance',true)
 if not sa then return nil end
 local ok,color=pcall(function()
  local image=AssetService:CreateEditableImageAsync((sa::any).ColorMapContent)
  local size=image.Size
  local r,g,b,n=0,0,0,0
  local stride=math.max(1,math.floor(size.X/64))
  for row=0,31 do
   local y=math.floor((row+.5)/32*size.Y)
   local line=image:ReadPixelsBuffer(Vector2.new(0,y),Vector2.new(size.X,1))
   for x=0,size.X-1,stride do
    local o=x*4
    local pr,pg,pb,pa=buffer.readu8(line,o),buffer.readu8(line,o+1),buffer.readu8(line,o+2),buffer.readu8(line,o+3)
    local light=(pr+pg+pb)/765
    -- Skip the empty atlas, the eyes, the nose and the highlights.
    if pa>128 and light>.12 and light<.9 then r+=pr;g+=pg;b+=pb;n+=1 end
   end
  end
  image:Destroy()
  if n<40 then return nil end
  return C(r/n,g/n,b/n)
 end)
 return ok and color or nil
end

return function(ctx:any)
 ctx.ManualBanner=true
 ctx.WhisperStyle={Font=Enum.Font.Kalam,Color=C(255,230,186),Type=.05}
 local Kit,scope,config=ctx.Kit,ctx.Scope,ctx.Config
 local model:Model=ctx.Model
 local low,calm,origin,hold=ctx.Low,Kit.ReducedMotion(),ctx.Origin,config.Hold
 local function live(t)return ctx:Elapsed()-t<.35 end
 local player=Players.LocalPlayer

 -- The real (display) dog waits, hidden, until the very end.
 local vis=scope:Visibility(model);vis.Set(1)
 -- A dog already digging in this pit would stand inside the arrival: it steps aside
 -- (hidden here, for this arrival only).
 do
  local district=workspace:FindFirstChild('DOGROTS_District')
  local kennels=district and district:FindFirstChild('KennelDogs')
  for _,m in ipairs(kennels and kennels:GetChildren()or {})do
   if m:IsA('Model')then
    local p=m:GetPivot().Position
    if Vector2.new(p.X-origin.X,p.Z-origin.Z).Magnitude<10 then scope:Visibility(m).Set(1)end
   end
  end
 end

 ---------------------------------------------------------------- the path
 -- Join the lap where it passes closest to the hole, slanting on in its direction of travel,
 -- go all the way round, and slant back off to stop beside the hole (beside the body still
 -- pouring out of it).
 local function flatten(v:Vector3):Vector3 return Vector3.new(v.X,0,v.Z)end
 local here=flatten(origin)
 local route=(Config.Map and Config.Map.LongDogLap)or LAP
 local n=#route
 local along={0}
 for i=1,n do along[i+1]=along[i]+flatten(route[i%n+1]-route[i]).Magnitude end
 local lap=along[n+1]
 local function lapPoint(s:number):Vector3
  s=s%lap
  for i=1,n do
   if s<=along[i+1]then return route[i]:Lerp(route[i%n+1],(s-along[i])/math.max(along[i+1]-along[i],1e-6))end
  end
  return route[1]
 end
 -- Where the lap passes closest to the hole.
 local nearest,best=0,math.huge
 for i=1,n do
  local a,b=flatten(route[i]),flatten(route[i%n+1])
  local ab=b-a
  local u=math.clamp((here-a):Dot(ab)/math.max(ab:Dot(ab),1e-6),0,1)
  local d=(a+ab*u-here).Magnitude
  if d<best then nearest,best=along[i]+ab.Magnitude*u,d end
 end
 local on,off=nearest+30,nearest-40+lap
 local onPoint,offPoint=lapPoint(on),lapPoint(off)
 local out=flatten(onPoint)-here
 if out.Magnitude<1 then out=flatten(onPoint-lapPoint(on-1))end
 local side=Vector3.new(-out.Unit.Z,0,out.Unit.X)
 local back=flatten(offPoint)-here
 local start=Vector3.new(origin.X,onPoint.Y,origin.Z)
 local points:{Vector3}={start,start+out.Unit*math.min(6,out.Magnitude*.3),onPoint}
 -- Every corner of the lap between the two, in its direction of travel.
 for j=1,2*n do
  local i=(j-1)%n+1
  local s=along[i]+(j>n and lap or 0)
  if s>on+4 and s<off-4 then table.insert(points,route[i])end
 end
 table.insert(points,offPoint)
 table.insert(points,Vector3.new(origin.X,offPoint.Y,origin.Z)+back.Unit*math.min(22,back.Magnitude*.5))
 -- The curve through the points, about every 3 studs (its heights are the lap's own).
 local curve:{Vector3}={}
 -- The legs between the hole and the lap cross this yard (kennels, fences): only those are
 -- measured against the ground. The lap's own heights already clear the island.
 local leg:{boolean}={}
 for i=1,#points-1 do
  local p1,p2=points[i],points[i+1]
  local p0=points[i-1]or p1*2-p2
  local p3=points[i+2]or p2*2-p1
  local steps=math.max(2,math.ceil(flatten(p2-p1).Magnitude/3))
  for k=0,steps-1 do
   table.insert(curve,spline(p0,p1,p2,p3,k/steps))
   leg[#curve]=i<=2 or i>=#points-1
  end
 end
 table.insert(curve,points[#points]);leg[#curve]=true
 local flat:{Vector2}={}
 for i,p in ipairs(curve)do flat[i]=Vector2.new(p.X,p.Z)end
 -- Ground under it (roofs, arches and fences included: it goes over them).
 local skip:{Instance}={model}
 for _,name in ipairs({'DOGROTS_SecretArrivalFX','DOGROTS_SecretReveals','DogDexLocalDisplays'})do
  local o=workspace:FindFirstChild(name);if o then table.insert(skip,o)end
 end
 local district=workspace:FindFirstChild('DOGROTS_District')
 for _,path in ipairs({{'03_DogLine','ActiveDogs'},{'KennelDogs'}})do
  local o:Instance?=district
  for _,step in ipairs(path)do o=o and o:FindFirstChild(step)end
  if o then table.insert(skip,o)end
 end
 for _,p in ipairs(Players:GetPlayers())do if p.Character then table.insert(skip,p.Character)end end
 local params=RaycastParams.new();params.FilterType=Enum.RaycastFilterType.Exclude
 local function ground(x:number,z:number,fallback:number):number
  local ignore=table.clone(skip)
  for _=1,4 do
   params.FilterDescendantsInstances=ignore
   local hit=workspace:Raycast(Vector3.new(x,240,z),Vector3.new(0,-320,0),params)
   if not hit then return fallback end
   local part=hit.Instance
   if part:IsA('Terrain')then return hit.Position.Y end
   local size=(part::BasePart).Size
   -- Poles, lamp posts and glass are not ground (walls and signs are: it goes over them).
   if (part::BasePart).Transparency<.9 and math.max(size.X,size.Z)>=2.5 then return hit.Position.Y end
   table.insert(ignore,part)
  end
  return fallback
 end
 local count=#flat
 local spine=SPINE*SCALE
 local radius=RADIUS*SCALE
 -- The spine never dips below the lap's own height, nor below what this client's island
 -- needs (a kennel next to the pit, anything the lap itself does not pass over).
 local floor=table.create(count,0)
 local last=origin.Y
 for i,p in ipairs(flat)do
  if leg[i]then
   -- Across the body's whole width, so it does not graze a wall it runs beside.
   local d=flat[math.min(i+1,count)]-flat[math.max(i-1,1)]
   local across=d.Magnitude>1e-3 and Vector2.new(-d.Y,d.X).Unit*radius or Vector2.zero
   local g=ground(p.X,p.Y,last)
   g=math.max(g,ground(p.X+across.X,p.Y+across.Y,g),ground(p.X-across.X,p.Y-across.Y,g))
   last=g
   floor[i]=math.max(g,curve[i].Y-spine)
  else
   floor[i]=curve[i].Y-spine
  end
 end
 -- Over obstacles in long arcs: widen bumps, cap the slope, then smooth.
 local heights=table.create(count,0)
 for i=1,count do
  local v=floor[i]
  for j=math.max(1,i-2),math.min(count,i+2)do v=math.max(v,floor[j])end
  heights[i]=v
 end
 for i=2,count do heights[i]=math.max(heights[i],heights[i-1]-2.2)end
 for i=count-1,1,-1 do heights[i]=math.max(heights[i],heights[i+1]-2.2)end
 for _=1,3 do
  local was=table.clone(heights)
  for i=2,count-1 do heights[i]=(was[i-1]+2*was[i]+was[i+1])/4 end
 end
 -- Smoothing must not pull it back down into what it is clearing.
 for i=1,count do
  local need=floor[i]
  if i>1 then need=math.max(need,floor[i-1])end
  if i<count then need=math.max(need,floor[i+1])end
  heights[i]=math.max(heights[i],need)
 end
 -- The spine floats at the runner's height (it is only held up at its ends, like every
 -- photo of a long dog), rising out of the hole over the first few studs.
 local raw:{Vector3}={}
 local run=0
 for i,p in ipairs(flat)do
  if i>1 then run+=(p-flat[i-1]).Magnitude end
  local y=heights[i]+spine
  if run<20 then y=origin.Y-radius*2+(y-origin.Y+radius*2)*smooth(run/20)end
  raw[i]=Vector3.new(p.X,y,p.Y)
 end
 -- Even spacing along the 3D curve: point(s) is a table lookup.
 local P:{Vector3}={raw[1]}
 local total=0
 do
  local carry=0
  for i=2,#raw do
   local a,b=raw[i-1],raw[i]
   local d=(b-a).Magnitude
   while carry+d>=STEP do
    local u=(STEP-carry)/d
    a=a:Lerp(b,u);d=(b-a).Magnitude;carry=0
    table.insert(P,a);total+=STEP
   end
   carry+=d
  end
  total+=carry;table.insert(P,raw[#raw])
 end
 local function point(s:number):Vector3
  local f=math.clamp(s,0,total)/STEP
  local i=math.min(math.floor(f),#P-2)
  return P[i+1]:Lerp(P[i+2],math.clamp(f-i,0,1))
 end
 local function tangent(s:number):Vector3
  local d=point(s+3)-point(s-3)
  return d.Magnitude>1e-3 and d.Unit or Vector3.zAxis
 end
 -- A runner's pivot (its paws) with its spine on the path at s, facing along it.
 local function frame(s:number,back:boolean?):CFrame
  local p,d=point(s),tangent(s)
  if back then d=-d end
  local level=Vector3.new(d.X,0,d.Z)
  if level.Magnitude<1e-3 then level=Vector3.zAxis end
  local pitch=math.clamp(math.atan2(d.Y,level.Magnitude),-.6,.6)
  return CFrame.lookAt(p,p+level.Unit)*CFrame.Angles(pitch,0,0)*CFrame.new(0,-spine,0)
 end

 ---------------------------------------------------------------- the head over everything
 -- The head runs from T_OUT to T_STOP; mostly at full tilt.
 local headEnd=total
 local function headAt(t:number):number
  local u=math.clamp((t-T_OUT)/(T_STOP-T_OUT),0,1)
  return headEnd*(.7*u+.3*smooth(u))
 end
 -- The tail sits in the hole until it pops out, then snaps all the way to the head.
 local tailRest=REAR*SCALE+2
 local function tailAt(t:number):number
  if t<T_POP then return REAR*SCALE-8 end
  if t<T_SNAP then return REAR*SCALE-8+(tailRest-REAR*SCALE+8)*smooth((t-T_POP)/.45)end
  local u=math.clamp((t-T_SNAP)/(T_JOIN-T_SNAP),0,1)
  return tailRest+(headEnd-tailRest)*u^2.4
 end

 -- Runners: local copies of the dog that every client has.
 local function runner(tuck:{[string]:Vector3}):(Model?,any)
  local copy=Kit.DogCopy('LongDog',model)
  if not copy then return nil,nil end
  local m:Model=copy
  pcall(function()m:ScaleTo(m:GetScale()*SCALE)end)
  for _,p in ipairs(m:GetDescendants())do
   if p:IsA('BasePart')then p.CastShadow=not low;if p.Name=='RootPart'then p.Transparency=1 end end
  end
  m.Parent=scope.Folder
  local animator
  pcall(function()animator=AnimationPlayer.new(m,'LongDog')end)
  -- Bones pushed (template units, in the runner's own frame) inside the body tube.
  local bones={}
  for name,offset in pairs(tuck)do
   local b=m:FindFirstChild(name,true)
   if b and b:IsA('Bone')then table.insert(bones,{b,offset*SCALE})end
  end
  local r={Model=m,Animator=animator,Bones=bones,Hidden=true}
  function r.Pose(cf:CFrame)
   m:PivotTo(cf)
   if animator and animator.Clip then pcall(function()animator:Step()end)end
   local tracks=animator and animator.Clip and animator.Clip.Tracks or {}
   for _,pair in ipairs(bones)do
    local bone,offset=pair[1],pair[2]
    if bone.Parent then
     -- A bone the clip does not drive keeps its last Transform: start it from rest.
     if not tracks[bone.Name]then bone.Transform=CFrame.identity end
     local world=cf:VectorToWorldSpace(offset)
     bone.Transform*=CFrame.new(bone.TransformedWorldCFrame:VectorToObjectSpace(world))
    end
   end
  end
  function r.Play(name:string,speed:number?,looped:boolean?)
   if animator then pcall(function()animator:Play(name,{Speed=speed,Looped=looped,FadeTime=.15})end)end
  end
  function r.Show(on:boolean)
   r.Hidden=not on
   for _,p in ipairs(m:GetDescendants())do
    if p:IsA('BasePart')and p.Name~='RootPart'then p.LocalTransparencyModifier=on and 0 or 1 end
   end
  end
  return m,r
 end
 -- The head runner hides its hind legs and tail in the tube; the tail runner hides its
 -- head and forelegs (dogs face -Z: +Z is toward the tail).
 local _,head=runner({['Leg.BL']=Vector3.new(0,.52,0),['Leg.BR']=Vector3.new(0,.52,0),Tail=Vector3.new(0,-.42,-.9)})
 local _,tail=runner({Chest=Vector3.new(0,-.5,.75),['Leg.FL']=Vector3.new(0,.5,0),['Leg.FR']=Vector3.new(0,.5,0)})
 if head then head.Show(false);head.Play('Walk',5,true)end
 if tail then tail.Show(false);tail.Play('Walk',5,true)end

 ---------------------------------------------------------------- the body
 local SEG=low and 10 or 5
 local segments:{BasePart}={}
 local fur=FUR
 local function segment(k:number):BasePart
  local p=segments[k]
  if p then return p end
  local a,b=(k-1)*SEG,math.min(k*SEG,total)
  local pa,pb=point(a),point(b)
  local length=(pb-pa).Magnitude+1
  p=scope:Part({Name='LongBody',Shape=Enum.PartType.Cylinder,Material=Enum.Material.SmoothPlastic,Color=fur,
   Size=Vector3.new(length,radius*2,radius*2),CFrame=Kit.LookAt((pa+pb)/2,pb)*CFrame.Angles(0,math.pi/2,0),
   Transparency=1,CastShadow=not low})
  segments[k]=p
  return p
 end
 local pieces=math.ceil(total/SEG)
 for k=1,pieces do segment(k)end
 -- Ball joints where the body bends hard, so the tube shows no gaps on the outside.
 local joints:{[number]:BasePart}={}
 for k=1,pieces-1 do
  local a,b,c=point((k-1)*SEG),point(k*SEG),point(math.min((k+1)*SEG,total))
  local d1,d2=b-a,c-b
  if d1.Magnitude>1e-3 and d2.Magnitude>1e-3 and d1.Unit:Dot(d2.Unit)<.985 then
   joints[k]=scope:Part({Name='LongJoint',Shape=Enum.PartType.Ball,Material=Enum.Material.SmoothPlastic,Color=fur,
    Size=Vector3.one*radius*2,CFrame=CFrame.new(b),Transparency=1,CastShadow=not low})
  end
 end
 -- One more piece reaches from the last whole segment to exactly where a runner begins.
 local function cap(name:string):BasePart
  return scope:Part({Name=name,Shape=Enum.PartType.Cylinder,Material=Enum.Material.SmoothPlastic,Color=fur,
   Size=Vector3.new(1,radius*2,radius*2),Transparency=1,CastShadow=not low})
 end
 local front,rear=cap('LongBodyFront'),cap('LongBodyRear')
 -- A harness band hides each seam between the textured runner and the plain tube.
 local bands={}
 for i=1,2 do
  bands[i]=scope:Part({Name='Harness',Shape=Enum.PartType.Cylinder,Material=Enum.Material.Fabric,Color=BAND,
   Size=Vector3.new(.9,radius*2.25,radius*2.25),Transparency=1})
 end
 task.spawn(function()
  local sampled=sampleFur(model)or sampleFur(head and head.Model or nil)
  if not sampled or not scope.Alive then return end
  fur=sampled
  for _,p in pairs(segments)do p.Color=sampled end
  for _,p in pairs(joints)do p.Color=sampled end
  front.Color=sampled;rear.Color=sampled
 end)
 local shown={}
 local function piece(p:BasePart,a:number,b:number)
  if b-a<.3 then p.Transparency=1;return end
  local pa,pb=point(a),point(b)
  p.Size=Vector3.new((pb-pa).Magnitude+1,radius*2,radius*2)
  p.CFrame=Kit.LookAt((pa+pb)/2,pb)*CFrame.Angles(0,math.pi/2,0)
  p.Transparency=0
 end
 -- Shows the body between s0 (the tail end) and s1 (the head end).
 local function body(s0:number,s1:number)
  local first,lastWhole=math.floor(s0/SEG)+2,math.floor(s1/SEG)
  for k,p in pairs(segments)do
   local on=k>=first and k<=lastWhole
   if shown[k]~=on then shown[k]=on;p.Transparency=on and 0 or 1 end
  end
  for k,p in pairs(joints)do
   local on=k>=first and k<lastWhole
   if (p.Transparency<1)~=on then p.Transparency=on and 0 or 1 end
  end
  if lastWhole>=first then
   piece(rear,s0,(first-1)*SEG);piece(front,lastWhole*SEG,s1)
  else
   piece(rear,s0,s1);front.Transparency=1
  end
 end
 local function band(p:BasePart,s:number,on:boolean)
  if not on then p.Transparency=1;return end
  local pa,pb=point(s-.45),point(s+.45)
  p.CFrame=Kit.LookAt((pa+pb)/2,pb)*CFrame.Angles(0,math.pi/2,0);p.Transparency=0
 end

 ---------------------------------------------------------------- the hole
 local holeY=origin.Y+.06
 local function disc(name:string,y:number,props:{[string]:any}):BasePart
  local p=scope:Part(props);p.Name=name;p.Size=Vector3.new(.1,.04,.1);p.CFrame=CFrame.new(origin.X,holeY+y,origin.Z)
  local mesh=Instance.new('SpecialMesh');mesh.MeshType=Enum.MeshType.Sphere;mesh.Parent=p
  return p
 end
 local across=radius*2+3
 local open:{{any}}={
  {disc('Spoil',0,{Material=Enum.Material.Ground,Color=DIRT}),Vector3.new(across+4,.1,across+4)},
  {disc('HoleEdge',.05,{Color=VOID,Transparency=.45}),Vector3.new(across+1.4,.03,across+1.4)},
  {disc('Hole',.09,{Color=VOID}),Vector3.new(across,.03,across)},
 }
 local mouth=scope:Anchor(origin+Vector3.new(0,.4,0),'Mouth')
 local cracks={}
 for i=1,low and 4 or 8 do
  local a=(i+Kit.Random(-.3,.3))/(low and 4 or 8)*math.pi*2
  local len=Kit.Random(5,9)+across*.5
  local dir=CFrame.new(origin.X,holeY+.02,origin.Z)*CFrame.Angles(0,a,0)
  local p=scope:Part({Name='Crack',Color=VOID,Size=Vector3.new(.35,.06,len),CFrame=dir*CFrame.new(0,0,-len/2)})
  if live(0)then
   p.Size=Vector3.new(.35,.06,.1);p.CFrame=dir
   Kit.Tween(p,.3,{Size=Vector3.new(.35,.06,len),CFrame=dir*CFrame.new(0,0,-len/2)})
  end
  cracks[i]=p
 end
 for i,o in ipairs(open)do
  if live(0)then
   task.delay(.05+(3-i)*.04,function()if o[1].Parent then Kit.Tween(o[1],.45,{Size=o[2]},Enum.EasingStyle.Back)end end)
  else o[1].Size=o[2]end
 end
 local trickle=scope:Emitter(mouth,{Color=ColorSequence.new(DIRT),LightEmission=0,LightInfluence=1,Lifetime=NumberRange.new(.5,.9),
  Speed=NumberRange.new(8,15),SpreadAngle=Vector2.new(30,30),Acceleration=Vector3.new(0,-45,0),Size=NumberSequence.new(.55,.2),
  Transparency=NumberSequence.new(0,.3),RotSpeed=NumberRange.new(-180,180)})
 local haze=not low and scope:Emitter(mouth,{Texture=Kit.Textures.Smoke,Color=ColorSequence.new(DUST),LightEmission=0,LightInfluence=1,
  Lifetime=NumberRange.new(1,1.8),Speed=NumberRange.new(1,4),SpreadAngle=Vector2.new(40,40),Size=NumberSequence.new(2,5),
  Transparency=NumberSequence.new(.6,1)})or nil

 -- Thrown dirt and bones: a little ballistic sim that lands them on the ground.
 local flying:{any}={}
 local function throw(p:BasePart,from:Vector3,velocity:Vector3,rest:number,extra:{any}?)
  table.insert(flying,{Part=p,Pos=from,Vel=velocity,Turn=CFrame.identity,Rest=false,Half=rest,Extra=extra,
   Spin=Vector3.new(Kit.Random(-9,9),Kit.Random(-9,9),Kit.Random(-9,9))})
 end
 scope:Every(function(dt)
  dt=math.min(dt,.05)
  for _,b in ipairs(flying)do
   if not b.Rest and b.Part.Parent then
    local v=b.Vel-Vector3.new(0,60*dt,0)
    local at=b.Pos+v*dt
    b.Turn*=CFrame.fromEulerAnglesXYZ(b.Spin.X*dt,b.Spin.Y*dt,b.Spin.Z*dt)
    if at.Y<holeY+b.Half and v.Y<0 then
     at=Vector3.new(at.X,holeY+b.Half,at.Z)
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
  local s=Kit.Random(.4,.8)
  local p=scope:Part({Name='Clod',Material=Enum.Material.Ground,Color=DIRT:Lerp(Kit.Random(0,1)<.5 and C(60,40,24)or DUST,Kit.Random(0,.4)),
   Size=Vector3.one*s,CFrame=CFrame.new(from)})
  local a=Kit.Random(0,math.pi*2)
  throw(p,from,Vector3.new(math.cos(a)*speed,up,math.sin(a)*speed),s/2)
 end
 local function bone(from:Vector3,speed:number,up:number)
  local shaft=scope:Part({Name='Bone',Shape=Enum.PartType.Cylinder,Material=Enum.Material.SmoothPlastic,Color=BONE,
   Size=Vector3.new(1.1,.24,.24),CFrame=CFrame.new(from)})
  local knobs={}
  for _,x in ipairs({-.55,.55})do
   for _,z in ipairs({-.13,.13})do
    local k=scope:Part({Name='Knob',Shape=Enum.PartType.Ball,Material=Enum.Material.SmoothPlastic,Color=BONE,Size=Vector3.one*.32,CFrame=CFrame.new(from)})
    table.insert(knobs,{k,CFrame.new(x,0,z)})
   end
  end
  local a=Kit.Random(0,math.pi*2)
  throw(shaft,from,Vector3.new(math.cos(a)*speed,up,math.sin(a)*speed),.15,knobs)
 end
 local function burst(at:Vector3,big:boolean)
  scope:Burst(at,DIRT,big and 60 or 30,{LightEmission=0,LightInfluence=1,Speed=NumberRange.new(16,30),SpreadAngle=Vector2.new(35,35),
   Acceleration=Vector3.new(0,-60,0),Lifetime=NumberRange.new(.7,1.3),Size=NumberSequence.new(.7,.3),Transparency=NumberSequence.new(0,.2),
   RotSpeed=NumberRange.new(-200,200)})
  scope:Burst(at,DUST,big and 26 or 14,{Texture=Kit.Textures.Smoke,LightEmission=0,LightInfluence=1,Speed=NumberRange.new(5,12),
   SpreadAngle=Vector2.new(70,70),Drag=3,Lifetime=NumberRange.new(1,1.7),Size=NumberSequence.new(2.5,6),Transparency=NumberSequence.new(.35,1)})
 end

 ---------------------------------------------------------------- every screen
 -- The banner, a dusty sky and the LENGTH every player watches climb.
 if ctx:Elapsed()<3 then
  ctx:Banner({Kicker='⚠  SOMETHING IS DIGGING  ⚠',Title='LONG DOG',Text='it keeps going',Style='Alert',Hold=3})
 end
 local sky=scope:Sky({Grade={TintColor=C(255,236,208),Saturation=.12,Contrast=.06},
  Atmosphere={Color=C(236,206,160),Decay=C(196,150,104),Density=.22,Haze=1.6}},2,2.5)
 local gui=Instance.new('ScreenGui');gui.Name='DOGROTS_LongDogLength';gui.ResetOnSpawn=false;gui.IgnoreGuiInset=true;gui.DisplayOrder=95
 local box=Instance.new('Frame');box.AnchorPoint=Vector2.new(.5,1);box.Position=UDim2.new(.5,0,1,-96);box.Size=UDim2.fromOffset(330,58)
 box.BackgroundColor3=C(26,18,10);box.BackgroundTransparency=1;box.BorderSizePixel=0;box.Parent=gui
 local corner=Instance.new('UICorner');corner.CornerRadius=UDim.new(.3,0);corner.Parent=box
 local edge=Instance.new('UIStroke');edge.Color=SAND;edge.Thickness=2;edge.Transparency=1;edge.Parent=box
 local pop=Instance.new('UIScale');pop.Parent=box
 -- KeepFont before parenting, or the place typography swaps the face.
 local readout=Instance.new('TextLabel');readout.Name='Length';readout:SetAttribute('KeepFont',true)
 readout.BackgroundTransparency=1;readout.AnchorPoint=Vector2.new(.5,.5);readout.Position=UDim2.fromScale(.5,.5)
 readout.Size=UDim2.new(1,-18,1,-10);readout.Font=Enum.Font.RobotoMono;readout.TextScaled=true;readout.TextColor3=SAND
 readout.TextStrokeColor3=C(20,12,6);readout.TextStrokeTransparency=.4;readout.TextTransparency=1;readout.Text='LENGTH: 0 m'
 readout.Parent=box
 gui.Parent=player:WaitForChild('PlayerGui')
 scope:Add(gui)
 local function meters(n:number):string
  local s=tostring(math.floor(n))
  return (s:reverse():gsub('(%d%d%d)','%1,'):reverse():gsub('^,',''))
 end
 local shownText=''
 local function say(text:string)
  if text==shownText then return end
  shownText=text;readout.Text=text
 end

 -- The whole island watches the head go by.
 local glance
 local headPos=origin
 if ctx:Elapsed()<T_JOIN then
  glance=scope:Glance(function()return headPos end,{Exclude=model,Turn=.5,Ripple=400})
 end

 -- Cutaway 1: ride along behind the head as it tears out of the yard, then rise high over
 -- the island to see the body lying across all of it. Cutaway 2: the tail at the hole,
 -- the island as it snaps back, the real dog.
 local overview=OVERVIEW
 local chase={}
 for i=0,8 do
  local t=1.3+i*.4
  local s=headAt(t)
  local d=tangent(s)
  local level=Vector3.new(d.X,0,d.Z);level=level.Magnitude>1e-3 and level.Unit or Vector3.zAxis
  local right=level:Cross(Vector3.yAxis)
  local at=point(s)
  table.insert(chase,{At=t,CFrame=Kit.Frame(at-level*30+right*34+Vector3.new(0,16,0),at+level*18),Fov=66,Linear=i>0})
 end
 table.insert(chase,{At=5.4,CFrame=overview,Fov=70})
 table.insert(chase,{At=6.9,CFrame=overview*CFrame.new(0,0,-25),Fov=68,Linear=true})
 ctx:Cutaway(chase,{Focus=point(headAt(3)),Bars=.08})
 -- From the side: the head on one side of the hole, its body leaving on the other.
 local across3,out3=side,out.Unit
 local holeShot=Kit.Frame(origin+across3*44+out3*-4+Vector3.new(0,13,0),origin+Vector3.new(0,3,0))
 local standShot=Kit.Frame(origin-across3*16+out3*5+Vector3.new(0,5,0),origin+Vector3.new(0,2.5,0))
 ctx:Cutaway({
  {At=T_STOP+.2,CFrame=holeShot,Fov=60},{At=T_SNAP-.05,CFrame=holeShot*CFrame.new(0,0,-4),Fov=56,Linear=true},
  {At=T_SNAP,CFrame=overview,Fov=70,Cut=true},{At=T_JOIN-.1,CFrame=overview*CFrame.new(0,0,-20),Fov=68,Linear=true},
  {At=T_JOIN,CFrame=standShot,Fov=58,Cut=true},{At=T_JOIN+1.1,CFrame=standShot*CFrame.new(0,0,-2.5),Fov=56,Linear=true},
 },{Focus=origin,Bars=.08})

 ---------------------------------------------------------------- the clock
 local ratchet:Sound?=nil
 scope:Every(function()
  local t=ctx:Elapsed()
  local sh=headAt(t)
  local st=tailAt(t)
  -- Runners.
  if head then
   local visible=t>=T_OUT and t<T_JOIN
   if visible==head.Hidden then head.Show(visible)end
   if visible then
    local cf=frame(math.max(sh,6))
    if t<T_OUT+.45 then
     -- Bursting up out of the hole.
     cf=CFrame.new(0,-(1-smooth((t-T_OUT)/.45))*spine*1.6,0)*cf
    end
    head.Pose(cf)
    headPos=cf.Position+Vector3.new(0,spine,0)
   end
  end
  if tail then
   local visible=t>=T_POP and t<T_JOIN
   if visible==tail.Hidden then tail.Show(visible)end
   if visible then
    local cf=frame(st)
    if t<T_SNAP then cf=CFrame.new(0,math.sin(math.clamp((t-T_POP)/.45,0,1)*math.pi)*2.4,0)*cf end
    tail.Pose(cf)
   end
  end
  -- The body: from the tail runner's seam (or the hole) to the head runner's seam.
  if t>=T_OUT and t<T_JOIN then
   local s1=math.max(sh-SEAM*SCALE,0)
   local s0=math.max(st-SEAM*SCALE,0)
   body(s0,s1)
   band(bands[1],s1,head~=nil and s1>2)
   band(bands[2],s0,tail~=nil and t>=T_POP and s1-s0>2)
  elseif t>=T_JOIN then
   body(0,0);band(bands[1],0,false);band(bands[2],0,false)
  end
  -- LENGTH.
  if t>=T_OUT+.1 and t<T_JOIN+1.5 then
   if box.BackgroundTransparency>.5 then
    Kit.Tween(box,.3,{BackgroundTransparency=.2});Kit.Tween(edge,.3,{Transparency=0});Kit.Tween(readout,.3,{TextTransparency=0})
   end
   if t<T_STOP then say('LENGTH: '..meters(math.max(sh-SEAM*SCALE,0)*.28)..' m')
   elseif t<T_STOP+.25 then say('LENGTH: 9,999 m')
   elseif t<T_SNAP then say('LENGTH: ∞')
   elseif t<T_JOIN then say('LENGTH: '..meters(math.max(sh-st,0)*.28)..' m')
   else say('LENGTH: 1 dog')end
  elseif t>=T_JOIN+1.5 and readout.TextTransparency<.5 then
   Kit.Tween(box,.5,{BackgroundTransparency=1});Kit.Tween(edge,.5,{Transparency=1});Kit.Tween(readout,.5,{TextTransparency=1})
  end
  if ratchet then ratchet.PlaybackSpeed=.35+.9*math.clamp((t-T_OUT)/(T_STOP-T_OUT),0,1)end
 end)

 -- 0: the ground splits. Everyone feels it.
 if live(0)then
  Kit.Cue('Impact',nil,.6)
  if not calm then Kit.Shake(.18,.6)end
  burst(origin+Vector3.new(0,.6,0),false)
  if not low then for _=1,8 do clod(origin+Vector3.new(0,.8,0),Kit.Random(6,12),Kit.Random(14,24))end end
 end
 trickle.Rate=low and 6 or 18
 if haze then haze.Rate=4 end

 -- T_OUT: out it comes.
 if not ctx:Wait(T_OUT)then return end
 if live(T_OUT)then
  burst(origin+Vector3.new(0,1,0),true)
  Kit.Cue('Whoosh',nil,.55);Kit.Cue('Impact',mouth,.7)
  if Kit.Near(origin,140)>.05 and not calm then Kit.Shake(.3*Kit.Near(origin,140),.5)end
 end
 if ctx:Elapsed()<T_STOP-.5 then
  -- A ratchet every player hears, winding up for as long as it keeps coming.
  local s=Instance.new('Sound');s.SoundId=TICK;s.Looped=true;s.Volume=.14;s.PlaybackSpeed=.35;s.Parent=scope.Folder
  local eq=Instance.new('EqualizerSoundEffect');eq.LowGain=4;eq.MidGain=0;eq.HighGain=-12;eq.Parent=s
  s:Play();ratchet=s
 end

 -- T_STOP: it is back at the hole, and the hole is still going.
 if not ctx:Wait(T_STOP)then return end
 if ratchet then ratchet:Destroy();ratchet=nil end
 if head then head.Play('EXP_Confused',1,true)end
 if live(T_STOP)then
  Kit.Cue('Glitch',nil,.25)
  if not calm then pop.Scale=1.35;Kit.Tween(pop,.35,{Scale=1},Enum.EasingStyle.Back)end
 end

 -- T_POP: the tail. Finally.
 if not ctx:Wait(T_POP)then return end
 if live(T_POP)then
  burst(origin+Vector3.new(0,1,0),false)
  Kit.Cue('Sting',nil,.7)
  local s=Instance.new('Sound');s.SoundId=TICK;s.Volume=.5;s.PlaybackSpeed=2.2;s.Parent=mouth;s:Play()
  task.delay(1,function()if s.Parent then s:Destroy()end end)
 end
 trickle.Rate=0
 if haze then haze.Rate=0 end

 -- T_SNAP: the tape measure lets go.
 if not ctx:Wait(T_SNAP)then return end
 if live(T_SNAP)then
  local s=Instance.new('Sound');s.SoundId=TICK;s.Volume=.35;s.PlaybackSpeed=.4;s.Looped=true;s.Parent=scope.Folder
  local flange=Instance.new('FlangeSoundEffect');flange.Depth=.6;flange.Mix=.85;flange.Rate=8;flange.Parent=s
  s:Play()
  Kit.Tween(s,T_JOIN-T_SNAP,{PlaybackSpeed=3.2},Enum.EasingStyle.Quad,Enum.EasingDirection.In)
  task.delay(T_JOIN-T_SNAP,function()if s.Parent then s:Destroy()end end)
  Kit.Cue('Whoosh',nil,.6)
 end

 -- T_JOIN: SNAP. One perfectly normal Long Dog.
 if not ctx:Wait(T_JOIN)then return end
 if head then head.Show(false)end
 if tail then tail.Show(false)end
 if glance then glance:Stop(1.2)end
 vis.Set(0)
 if live(T_JOIN)then
  Kit.Cue('Impact',nil,.75);task.delay(.1,function()Kit.Cue('Chime',nil,.6)end)
  Kit.Flash(C(255,248,232),calm and .7 or .3,.6)
  local shine=scope:Highlight(model,SAND,C(255,244,214),.35,0)
  Kit.Tween(shine,1.2,{FillTransparency=1,OutlineTransparency=1})
  burst(headPos,true)
  if not low then
   for _=1,10 do clod(origin+Vector3.new(0,3,0),Kit.Random(4,11),Kit.Random(16,26))end
   for _=1,5 do bone(origin+Vector3.new(0,3,0),Kit.Random(4,10),Kit.Random(18,28))end
  end
  if Kit.Near(origin,160)>.05 and not calm then Kit.Shake(.25*Kit.Near(origin,160),.4)end
 end
 -- The hole shuts behind it.
 for _,o in ipairs(open)do
  local p=o[1]
  Kit.Tween(p,.55,{Size=Vector3.new(.1,o[2].Y,.1)},Enum.EasingStyle.Back,Enum.EasingDirection.In).Completed:Connect(function()p:Destroy()end)
 end
 for _,p in ipairs(cracks)do Kit.Tween(p,.6,{Transparency=1}).Completed:Connect(function()p:Destroy()end)end

 if not ctx:Wait(T_JOIN+.6)then return end
 ctx:Title({Hold=3.4})

 -- The dust settles; the mess fades before the arrival ends.
 if not ctx:Wait(hold-3)then return end
 sky:Release(2.5)
 for _,b in ipairs(flying)do
  local parts={b.Part}
  for _,x in ipairs(b.Extra or {})do table.insert(parts,x[1])end
  for _,p in ipairs(parts)do
   if p.Parent then Kit.Tween(p,.6,{Transparency=1}).Completed:Connect(function()p:Destroy()end)end
  end
 end
 ctx:Wait(hold)
end
