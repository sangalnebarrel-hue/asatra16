-- CUBEDOG, "the perfect cube". The mouth wakes up in cyan and a landing square blinks
-- on the belt. A wireframe cube draws itself high in the mouth with the dog inside,
-- snaps through three hard quarter-turns like a puzzle being solved, then drops and
-- shatters into voxels on the square. Confetti on the flip, sparkles on the happy spin.
-- Off the tongue (a Lucky Block pad, open air) a ring of voxel runes wakes up instead.
local C=Color3.fromRGB
local WHITE,DEEP=C(236,251,255),C(40,130,255)
local LIFT,DROP,LAND,SNAP=12,2,2.3,.14
-- Quarter-turns about world X, then Y, then Z: the cube ends upright but a quarter-turn
-- off, which it unwinds while it falls.
local SNAPS={{.8,Vector3.xAxis},{1.2,Vector3.yAxis},{1.6,Vector3.zAxis}}
local function backOut(x)local c=1.70158;x-=1;return 1+(c+1)*x*x*x+c*x*x end
local function smooth(x)x=math.clamp(x,0,1);return x*x*(3-2*x)end
-- Hover height of the dog's feet, the cube's turn (world, about its centre) and scale at e.
local function pose(e)
 local turn=CFrame.identity
 for _,s in ipairs(SNAPS)do
  local u=math.clamp((e-s[1])/SNAP,0,1)
  if u>0 then turn=CFrame.fromAxisAngle(s[2],math.pi/2*backOut(u))*turn end
 end
 local y,scale=LIFT,e<.5 and 0 or backOut(math.min((e-.5)/.25,1))
 if e<1.8 then y+=.22*math.sin((e-.5)*4.4)*math.clamp((1.8-e)/.4,0,1)
 elseif e<DROP then
  -- Anticipation: a small lift while the cube tightens.
  local k=smooth((e-1.8)/(DROP-1.8))
  y+=.6*k;scale*=1-.08*k
 else
  local u=math.min((e-DROP)/(LAND-DROP),1)
  y=(LIFT+.6)*(1-u*u);scale*=.92;turn=turn:Lerp(CFrame.identity,u*u)
 end
 return y,turn,scale
end

return function(ctx)
 ctx.WhisperStyle={Font=Enum.Font.Michroma,Color=C(200,242,255),Glitch=0,Chroma=false,Shake=false,Type=.035}
 local Kit,scope,model,config=ctx.Kit,ctx.Scope,ctx.Model,ctx.Config
 local low,hold,origin=ctx.Low,config.Hold,ctx.Origin
 local CYAN=config.Color
 local size=Kit.Size(model)
 local hc=size.Y/2
 local half=math.clamp(math.max(size.X,size.Y,size.Z)+1,6,8)/2
 -- Off the tongue (a Lucky Block pad) there is no mouth to light, no walls to bounce off
 -- and no flat belt underfoot.
 local tongue=(ctx.Venue or 'Tongue')=='Tongue'
 -- Dogs face their pivot's look vector: +Z on the tongue, the opener on a Lucky Block pad.
 -- face is the dog's own rotation, so its turns match the cube's world turns.
 local fwd,face,unface=Vector3.zAxis,CFrame.identity,CFrame.identity
 local function aim(pivot:CFrame)
  local f=Vector3.new(pivot.LookVector.X,0,pivot.LookVector.Z)
  fwd=f.Magnitude>.1 and f.Unit or Vector3.zAxis
  face=pivot.Rotation;unface=face:Inverse()
 end
 aim(Kit.Root(model)and model:GetPivot()or CFrame.lookAt(Vector3.zero,Vector3.zAxis))
 -- The tongue always faces +Z; elsewhere the facing is only known once the root has
 -- streamed in, often a few frames after the arrival starts.
 local aimed=tongue or Kit.Root(model)~=nil
 local intro=ctx.Late<DROP
 local function fresh(t)return ctx:Elapsed()-t<.35 end
 local stage=scope:Anchor(origin+Vector3.new(0,hc,0),'CubeStage')
 -- In open air the stage light stands in for the mouth's cyan lanterns.
 local shine=tongue and 0 or .8
 local glow=not low and scope:Light(stage,CYAN,20,shine)or nil

 -- The mouth lights up cyan, from the throat out to the stage.
 local restore={}
 local function tint(o,props)
  local saved={}
  for k in pairs(props)do saved[k]=(o::any)[k]end
  scope:Override(o,props);table.insert(restore,{o,saved})
 end
 local district=workspace:FindFirstChild('DOGROTS_District')
 local factory=district and district:FindFirstChild('02_DogFactory')
 local tunnel=factory and factory:FindFirstChild('DarkMouthTunnel')
 local line=district and district:FindFirstChild('03_DogLine')
 if tunnel and tongue then
  local runes={}
  for _,o in ipairs(tunnel:GetChildren())do
   if o.Name=='MouthRune'and o:IsA('BasePart')then table.insert(runes,o)
   elseif o.Name=='MouthMist'then
    for _,e in ipairs(o:GetChildren())do
     if e:IsA('ParticleEmitter')then scope:Override(e,{Color=ColorSequence.new(C(90,170,215))})end
    end
   end
  end
  table.sort(runes,function(a,b)return (a.Position-origin).Magnitude>(b.Position-origin).Magnitude end)
  for i,p in ipairs(runes)do
   task.delay(intro and math.floor((i-1)/2)*.07 or 0,function()
    if scope.Alive and p.Parent then tint(p,{Color=CYAN})end
   end)
  end
 end
 if line and tongue then
  for _,lantern in ipairs(line:GetChildren())do
   local lens=lantern.Name=='PromenadeLantern'and lantern:FindFirstChild('WarmLens')
   if lens and lens:IsA('BasePart')and (lens.Position-origin).Magnitude<20 then
    tint(lens,{Color=CYAN})
    for _,l in ipairs(lantern:GetDescendants())do
     if l:IsA('PointLight')then tint(l,{Color=CYAN})end
    end
   end
  end
 end
 scope:Duck(.45,.6)
 local grade=scope:Grade({Saturation=-.1,Contrast=.08,TintColor=C(230,247,255)},.8)

 local function voxel(at,s,color,material)
  return scope:Part({Name='Voxel',Size=Vector3.one*s,Color=color,Material=material,CFrame=CFrame.new(at)})
 end
 -- Open air: the stage can be a raised pad, so each piece finds the real ground under it
 -- once, just before it would reach the stage's level.
 local probe
 if not tongue then
  probe=RaycastParams.new();probe.FilterType=Enum.RaycastFilterType.Exclude;probe.RespectCanCollide=true
  local me=game:GetService('Players').LocalPlayer.Character
  probe.FilterDescendantsInstances=me and {model,me}or {model}
 end
 -- Ballistic voxels: one stepper per batch. They bounce on the belt (or the ground in open
 -- air), stay inside the mouth walls on the tongue (x=±15.5 until the opening, 4 studs
 -- ahead) and fade at the end.
 local function throw(pieces,gravity,life)
  scope:Every(function(dt,age)
   local fade=math.clamp((age-(life-.35))/.35,0,1)
   for _,v in ipairs(pieces)do
    if v.Part.Parent then
     v.Vel-=Vector3.new(0,gravity*dt,0)
     local pos=v.Pos+v.Vel*dt
     local floor=v.Floor or origin.Y+v.Size/2
     if probe and not v.Floor and v.Vel.Y<0 and pos.Y<floor+1.5 then
      local hit=workspace:Raycast(pos+Vector3.new(0,.5,0),Vector3.new(0,-8,0),probe)
      v.Floor=(hit and hit.Position.Y or origin.Y-8)+v.Size/2;floor=v.Floor
     end
     if pos.Y<floor and v.Vel.Y<0 then
      pos=Vector3.new(pos.X,floor,pos.Z);v.Vel=Vector3.new(v.Vel.X*.5,-v.Vel.Y*.3,v.Vel.Z*.5);v.Spin*=.5
     end
     local rel=pos-origin
     local wall=15.5-v.Size/2
     if tongue and rel.Z<4 and math.abs(rel.X)>wall then
      pos=Vector3.new(origin.X+math.sign(rel.X)*wall,pos.Y,pos.Z);v.Vel=Vector3.new(-v.Vel.X*.4,v.Vel.Y,v.Vel.Z)
     end
     v.Pos=pos;v.Rot*=CFrame.Angles(v.Spin.X*dt,v.Spin.Y*dt,v.Spin.Z*dt)
     v.Part.CFrame=CFrame.new(pos)*v.Rot;v.Part.Transparency=fade
    end
   end
   if age<life then return true end
   for _,v in ipairs(pieces)do if v.Part.Parent then v.Part:Destroy()end end
   return false
  end)
 end

 local landed,lift,vis,hl,motes,coreLight=false,nil,nil,nil,nil,nil
 local square,frame,nodes,guides={},{},{},{}
 local SIDES={Vector3.zAxis,-Vector3.zAxis,Vector3.xAxis,-Vector3.xAxis}
 local sq=math.max(6,math.max(size.X,size.Z)+.4)/2
 -- Off the tongue: once the root is in, turn the square and the guides to the dog's real
 -- facing and only then lift it (the dog stays hidden until it can sit in the cube).
 local function settle()
  if aimed or not Kit.Root(model)then return end
  aimed=true;aim(model:GetPivot())
  for i,p in ipairs(square)do p.CFrame=CFrame.new(origin+face:VectorToWorldSpace(SIDES[i]*sq)+Vector3.new(0,.06,0))*face end
  for _,g in ipairs(guides)do
   g.Dir=face:VectorToWorldSpace(Vector3.new(g.X,-1,g.Z))
   local foot=g.Beam.Attachment1 and g.Beam.Attachment1.Parent
   if foot and foot:IsA('BasePart')then foot.CFrame=CFrame.new(origin+face:VectorToWorldSpace(Vector3.new(g.X*sq,0,g.Z*sq))+Vector3.new(0,.12,0))end
  end
  if vis and not landed then lift=scope:Offset(model)end
 end
 -- Open air has no mouth to wake: eight voxel runes hover around the stage instead, lit in
 -- pairs from behind the dog to its front. They snap with the cube, flash on the landing
 -- and fade as the dog sets off.
 if not tongue then
  local runes={}
  for i=1,8 do runes[i]=scope:Part({Name='CubeRune',Color=CYAN,Size=Vector3.one*.05,Transparency=1})end
  scope:Every(function()
   settle()
   local e=ctx:Elapsed()
   local _,turn=pose(e)
   local out=math.clamp((e-(hold-.8))/.8,0,1)
   local flash=e>=LAND and math.max(0,1-(e-LAND)/.4)or 0
   for _,s in ipairs(SNAPS)do local d=e-s[1];if d>=0 and d<.25 then flash=math.max(flash,1-d/.25)end end
   local right=fwd:Cross(Vector3.yAxis)
   for i,p in ipairs(runes)do
    local k=math.floor((i-1)/2)
    local a=math.rad(157.5-45*k)*(i%2==0 and -1 or 1)
    local u=intro and math.clamp((e-k*.07)/.25,0,1)or 1
    p.Size=Vector3.one*math.max(.8*backOut(u),.05)
    p.CFrame=CFrame.new(origin+(fwd*math.cos(a)+right*math.sin(a))*6.5+Vector3.new(0,1.3+.15*math.sin(e*2.4+i),0))*turn*face
    p.Color=CYAN:Lerp(WHITE,flash);p.Transparency=u>0 and .05+.95*out or 1
   end
   return out<1
  end)
 end
 if intro then
  if fresh(0)then Kit.Cue('Chime',nil,.45)end
  vis=scope:Visibility(model);vis.Set(1)
  if aimed then lift=scope:Offset(model)end
  -- The landing square on the belt, square to the dog (and the cube) as they land.
  for _,o in ipairs(SIDES)do
   table.insert(square,scope:Part({Name='LandingSquare',Color=CYAN,Transparency=1,
    CFrame=CFrame.new(origin+face:VectorToWorldSpace(o*sq)+Vector3.new(0,.06,0))*face,
    Size=o.X==0 and Vector3.new(sq*2+.15,.1,.15)or Vector3.new(.15,.1,sq*2+.15)}))
  end
  -- The wireframe: 12 edges and 8 corner nodes, posed every frame with the dog.
  local corners={}
  for _,a in ipairs({-1,1})do for _,b in ipairs({-1,1})do
   for _,e in ipairs({{Vector3.new(0,a,b),Vector3.xAxis},{Vector3.new(a,0,b),Vector3.yAxis},{Vector3.new(a,b,0),Vector3.zAxis}})do
    table.insert(frame,{Part=scope:Part({Name='CubeEdge',Color=CYAN,Transparency=1,Size=Vector3.one*.1}),At=e[1],Axis=e[2]})
   end
   for _,c in ipairs({-1,1})do table.insert(corners,Vector3.new(a,b,c))end
  end end
  if not low then for i=1,8 do nodes[i]=scope:Part({Name='CubeCorner',Color=WHITE,Transparency=1,Size=Vector3.one*.1})end end
  local core=scope:Anchor(origin+Vector3.new(0,LIFT+hc,0),'CubeCore')
  if not low then
   coreLight=scope:Light(core,CYAN,16,1.8)
   motes=scope:Emitter(core,{Color=ColorSequence.new(CYAN,WHITE),Speed=NumberRange.new(1,3),Lifetime=NumberRange.new(.5,1),Size=NumberSequence.new(.3,0)})
   -- Guide beams from the cube's lower corners down to the square.
   for _,x in ipairs({-1,1})do for _,z in ipairs({-1,1})do
    local top=scope:Anchor(core.Position,'GuideTop')
    local at=Instance.new('Attachment');at.Parent=top
    local beam=scope:Beam(at,origin+face:VectorToWorldSpace(Vector3.new(x*sq,0,z*sq))+Vector3.new(0,.12,0),CYAN,.14,
     {Width1=.05,Transparency=NumberSequence.new(1)})
    table.insert(guides,{Top=top,Beam=beam,Dir=face:VectorToWorldSpace(Vector3.new(x,-1,z)),X=x,Z=z})
   end end
  end
  local shown=1
  scope:Every(function()
   if landed then return false end
   settle()
   local e=ctx:Elapsed()
   local y,turn,scale=pose(e)
   if lift then lift.CFrame=CFrame.new(0,y+hc,0)*unface*turn*face*CFrame.new(0,-hc,0)end
   local v=lift and 1-math.clamp((e-.5)/.25,0,1)or 1
   if v~=shown then shown=v;vis.Set(v)end
   local cf=CFrame.new(origin+Vector3.new(0,y+hc,0))*turn*face
   local a=math.max(half*scale,.05)
   local flash=0
   for _,s in ipairs(SNAPS)do local d=e-s[1];if d>=0 and d<.25 then flash=math.max(flash,1-d/.25)end end
   local color,alpha=CYAN:Lerp(WHITE,flash),scale>0 and .05 or 1
   for _,f in ipairs(frame)do
    local p=f.Part
    p.Size=f.Axis*(2*a+.22)+(Vector3.one-f.Axis)*.22;p.CFrame=cf*CFrame.new(f.At*a)
    p.Color=color;p.Transparency=alpha
   end
   for i,p in ipairs(nodes)do
    p.Size=Vector3.one*math.max(.55*(1+.8*flash)*math.min(scale,1),.05);p.CFrame=cf*CFrame.new(corners[i]*a);p.Transparency=alpha
   end
   core.CFrame=CFrame.new(cf.Position)
   for _,g in ipairs(guides)do
    local best,most=Vector3.zero,-math.huge
    for _,c in ipairs(corners)do local w=cf:VectorToWorldSpace(c);local d=w:Dot(g.Dir);if d>most then best,most=w,d end end
    g.Top.CFrame=CFrame.new(cf.Position+best*a)
   end
   -- The square blinks faster once the cube has stopped turning, and holds for the drop.
   local hz=e<1.6 and 4 or 9
   local blink=e>=DROP and 0 or ((e*hz)%1<.5 and .2 or .7)
   for _,p in ipairs(square)do p.Transparency=blink end
   return true
  end)

  if not ctx:Wait(.5)then return end
  -- The cube draws itself around the dog.
  if fresh(.5)then
   Kit.Cue('Whoosh',stage,.55)
   scope:Burst(core.Position,CYAN,24,{Speed=NumberRange.new(5,12),Lifetime=NumberRange.new(.3,.7),Size=NumberSequence.new(.4,0)})
  end
  hl=scope:Highlight(model,CYAN,WHITE,.3,.15)
  Kit.Tween(hl,.6,{FillTransparency=.82})
  if motes then motes.Rate=10 end
  for _,g in ipairs(guides)do g.Beam.Transparency=NumberSequence.new(.3,.85)end
  for _,s in ipairs(SNAPS)do
   if not ctx:Wait(s[1])then return end
   if fresh(s[1])then
    Kit.Cue('Glitch',stage,.28)
    local n=Kit.Near(origin,120)
    if n>.05 then Kit.Shake(.12*n,.12)end
   end
  end
  if not ctx:Wait(1.8)then return end
  if fresh(1.8)then Kit.Cue('Heartbeat',nil,.55)end
  if not ctx:Wait(DROP)then return end
  if fresh(DROP)then Kit.Cue('Whoosh',nil,.4)end
 end

 if not ctx:Wait(LAND)then return end
 -- It lands.
 landed=true
 if lift then lift.CFrame=CFrame.identity end
 if vis then vis.Set(0)end
 if fresh(LAND)then
  local n=Kit.Near(origin,120)
  Kit.Cue('Impact',nil,.95)
  task.delay(.1,function()if scope.Alive then Kit.Cue('Chime',nil,.4)end end)
  if n>.05 then Kit.Shake(.6*n,.45);Kit.Flash(C(200,242,255),1-.3*n,.35)end
  if n>.25 then Kit.FOVPunch(-4*n,.05,.5)end
  scope:Ring(origin+Vector3.new(0,.2,0),CYAN,1,13,.45,{Thickness=.35})
  if not low then scope:Ring(origin+Vector3.new(0,.25,0),WHITE,.6,8,.3,{Thickness=.18,Alpha=.35,Segments=24})end
  if n>.05 then grade.Brightness=.22*n;Kit.Tween(grade,.35,{Brightness=0})end
  if glow then glow.Brightness=5;Kit.Tween(glow,1.4,{Brightness=shine})end
  scope:Burst(origin+Vector3.new(0,.4,0),C(214,240,255),16,{Texture=Kit.Textures.Smoke,LightEmission=.2,Drag=5,
   Speed=NumberRange.new(6,12),SpreadAngle=Vector2.new(85,85),Lifetime=NumberRange.new(.5,.9),
   Size=NumberSequence.new(1.2,3.5),Transparency=NumberSequence.new(.45,1)})
  if low then
   scope:Burst(origin+Vector3.new(0,hc,0),CYAN,28,{Speed=NumberRange.new(10,18),Lifetime=NumberRange.new(.4,.8),Size=NumberSequence.new(.5,0)})
  else
   local pieces={}
   for i=1,16 do
    local s=Kit.Random(.5,1.1)
    local out=Vector3.new(Kit.Random(-1,1),0,Kit.Random(-1,1))
    out=out.Magnitude>.05 and out.Unit or Vector3.xAxis
    local at=origin+Vector3.new(0,Kit.Random(.8,size.Y*.8),0)+out*Kit.Random(1.5,2.5)
    local speed,white=Kit.Random(10,20),i%3==0
    table.insert(pieces,{Part=voxel(at,s,white and WHITE or CYAN,white and Enum.Material.SmoothPlastic or Enum.Material.Neon),
     Pos=at,Size=s,Rot=CFrame.identity,Vel=Vector3.new(out.X*speed*.6,Kit.Random(18,32),out.Z*speed),
     Spin=Vector3.new(Kit.Random(-10,10),Kit.Random(-10,10),Kit.Random(-10,10))})
   end
   throw(pieces,80,1.25)
  end
  hl=hl or scope:Highlight(model,WHITE,CYAN,.12,.2)
  hl.FillColor=WHITE;hl.FillTransparency=.12
 end
 -- The hologram lets go of the dog (also when the landing beat was missed).
 if hl then
  local flashed=hl
  Kit.Tween(flashed,.8,{FillTransparency=1,OutlineTransparency=1})
  task.delay(.9,function()if scope.Alive and flashed.Parent then flashed:Destroy()end end)
 end
 -- The cube lets go: its edges fly off and fade; the square flashes out.
 local loose={}
 for _,f in ipairs(frame)do table.insert(loose,f.Part)end
 for _,p in ipairs(nodes)do table.insert(loose,p)end
 if #loose>0 then
  local center=origin+Vector3.new(0,hc,0)
  local from={}
  for i,p in ipairs(loose)do
   local d=p.Position-center
   from[i]={p.CFrame,(d.Magnitude>.05 and d.Unit or Vector3.yAxis)*Kit.Random(7,11),CFrame.Angles(Kit.Random(-3,3),Kit.Random(-3,3),Kit.Random(-3,3))}
  end
  scope:Every(function(_,age)
   local a=math.min(age/.5,1);local k=1-(1-a)^3
   for i,p in ipairs(loose)do
    local f=from[i]
    p.CFrame=(f[1]+f[2]*k)*CFrame.identity:Lerp(f[3],k)
    p.Color=WHITE:Lerp(CYAN,a);p.Transparency=.05+.95*a
   end
   if a<1 then return true end
   for _,p in ipairs(loose)do p:Destroy()end
   return false
  end)
 end
 for _,p in ipairs(square)do p.Color=WHITE;p.Transparency=0;Kit.Tween(p,.6,{Transparency=1,Color=CYAN})end
 for _,g in ipairs(guides)do g.Beam:Destroy()end
 if motes then motes.Rate=0 end
 if coreLight then Kit.Tween(coreLight,.5,{Brightness=0})end
 ctx:Title({Font=Enum.Font.Michroma})

 if not ctx:Wait(3.2)then return end
 -- The flip: voxel confetti pops off the top.
 if fresh(3.2)then
  settle()
  Kit.Cue('Whoosh',stage,.35)
  task.delay(.12,function()if scope.Alive then Kit.Cue('Chime',nil,.3)end end)
  local top=origin+Vector3.new(0,size.Y+.4,0)+fwd*1.2
  if low then
   scope:Burst(top,CYAN,16,{Speed=NumberRange.new(6,12),Lifetime=NumberRange.new(.5,.9),Size=NumberSequence.new(.4,0)})
  else
   local pieces={}
   local colors={CYAN,WHITE,DEEP}
   for i=1,6 do
    local s=Kit.Random(.35,.6)
    local angle=i/6*math.pi*2+Kit.Random(-.3,.3)
    table.insert(pieces,{Part=voxel(top,s,colors[(i-1)%3+1],Enum.Material.Neon),Pos=top,Size=s,Rot=CFrame.identity,
     Vel=Vector3.new(math.cos(angle),0,math.sin(angle))*Kit.Random(3,7)+Vector3.new(0,Kit.Random(14,20),0),
     Spin=Vector3.new(Kit.Random(-8,8),Kit.Random(-8,8),Kit.Random(-8,8))})
   end
   throw(pieces,60,1.3)
  end
 end
 if not ctx:Wait(4.2)then return end
 -- The happy spin sheds sparkles from its body.
 if fresh(4.2)and not low then
  local body=model:FindFirstChild('body',true)
  if body and body:IsA('Bone')then
   -- On a scope anchor that follows the bone: emitters under the district are throttled
   -- by WorldDetailQuality, which would also undo the Rate=0 below.
   local anchor=scope:Anchor(body.TransformedWorldCFrame.Position,'Sparkle')
   local sparkle=scope:Emitter(anchor,{Rate=18,Color=ColorSequence.new(CYAN,WHITE),Speed=NumberRange.new(2,5),
    Lifetime=NumberRange.new(.5,.9),Size=NumberSequence.new(.35,0)})
   scope:Every(function()
    if not body.Parent or not anchor.Parent then return false end
    anchor.CFrame=CFrame.new(body.TransformedWorldCFrame.Position)
    return sparkle.Rate>0
   end)
   task.delay(1.1,function()if scope.Alive and sparkle.Parent then sparkle.Rate=0 end end)
  end
 end
 -- The mouth eases back to its own colours as the dog sets off (in open air the stage
 -- light goes out with the runes). The tweens only write overridden props and stop with
 -- the scope (Override restores the rest).
 if not ctx:Wait(hold-.8)then return end
 for _,r in ipairs(restore)do
  if r[1].Parent then local t=Kit.Tween(r[1],.8,r[2]);scope:Add(function()t:Cancel()end)end
 end
 if glow and not tongue then Kit.Tween(glow,.8,{Brightness=0})end
 if not ctx:Wait(hold)then return end
end
