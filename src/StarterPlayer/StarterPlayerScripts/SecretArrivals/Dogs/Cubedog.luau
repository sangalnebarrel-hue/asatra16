-- CUBEDOG, "THE PERFECT CUBE", for the whole island. The day dims to a cyan dusk for
-- everyone and a colossal wireframe cube draws itself edge by edge over the yards around a
-- glowing ghost of Cubedog; every dog on the island looks up at it, voxels rain around every
-- player and a few blocks fall and shatter right next to each of them. The cube snaps
-- through three hard quarter-turns (a CLACK everyone hears, every lamp on the island blinks
-- cyan), collapses and dives into the stage, where it stops dead with the dog inside: a
-- shockwave rolls across the map and every camera is pulled in for the stage act. There
-- (the mouth lit cyan, a landing square blinking on the belt) the little cube snaps three
-- times like a puzzle being solved, drops and shatters into voxels; confetti on the flip,
-- sparkles on the happy spin, and the sky eases back. Off the tongue (a Lucky Block pad,
-- open air) a ring of voxel runes marks the stage instead of the mouth's lanterns.
local Players=game:GetService('Players')
local C=Color3.fromRGB
local WHITE,DEEP,BLINK=C(236,251,255),C(40,130,255),C(130,238,255)
local LIFT,DROP,LAND,SNAP=12,2,2.3,.14
-- Quarter-turns about world X, then Y, then Z: the cube ends upright but a quarter-turn
-- off, which it unwinds while it falls.
local SNAPS={{.8,Vector3.xAxis},{1.2,Vector3.yAxis},{1.6,Vector3.zAxis}}
-- The map-wide act comes first: the stage act runs PRE seconds into the arrival (keep
-- SecretArrivalConfig.Dogs.Cubedog's Hold, Clips and Whispers in step with it).
local PRE=7.2
-- The colossal cube: side and edge thickness; the strokes that draw it, {from, to, start,
-- seconds} on the corners of a unit cube (the floor one edge at a time, four pillars, the
-- lid from two opposite corners); its three CLACKs (quarter-turns about its right, up and
-- forward axes, TURN seconds each); then it collapses (SHRINK) and dives (DIVE) to stop
-- dead around the dog at PRE+.5.
local SIDE,THICK,TURN=260,3.2,.32
local function v3(x,y,z)return Vector3.new(x,y,z)end
local STROKES={
 {v3(-1,-1,-1),v3(1,-1,-1),.9,.28},{v3(1,-1,-1),v3(1,-1,1),1.15,.28},
 {v3(1,-1,1),v3(-1,-1,1),1.4,.28},{v3(-1,-1,1),v3(-1,-1,-1),1.65,.28},
 {v3(-1,-1,-1),v3(-1,1,-1),1.95,.45},{v3(1,-1,-1),v3(1,1,-1),1.95,.45},
 {v3(1,-1,1),v3(1,1,1),1.95,.45},{v3(-1,-1,1),v3(-1,1,1),1.95,.45},
 {v3(-1,1,-1),v3(1,1,-1),2.45,.3},{v3(1,1,1),v3(-1,1,1),2.45,.3},
 {v3(1,1,-1),v3(1,1,1),2.75,.3},{v3(-1,1,1),v3(-1,1,-1),2.75,.3},
}
local DRAWN=3.05
local CLACKS={4.4,5.2,6}
local SHRINK,DIVE=6.6,7.1
-- Each corner appears when a stroke first starts from it, or rides the tip of the stroke
-- that first reaches it (the pen).
local CORNERS={}
for _,x in ipairs({-1,1})do for _,y in ipairs({-1,1})do for _,z in ipairs({-1,1})do
 local p=v3(x,y,z)
 local at,by=math.huge,nil
 for i,s in ipairs(STROKES)do
  if s[1]==p and s[3]<at then at,by=s[3],nil end
  if s[2]==p and s[3]<at then at,by=s[3],i end
 end
 table.insert(CORNERS,{P=p,At=at,By=by})
end end end
-- Every face ruled in thirds like a puzzle cube: 24 lines on the surface.
local GRID={}
local THIRDS={-1,-1/3,1/3,1}
for axis=1,3 do
 for _,a in ipairs(THIRDS)do for _,b in ipairs(THIRDS)do
  local outer,inner=math.abs(a)==1 and math.abs(b)==1,math.abs(a)<1 and math.abs(b)<1
  if not outer and not inner then
   if axis==1 then table.insert(GRID,{v3(-1,a,b),v3(1,a,b)})
   elseif axis==2 then table.insert(GRID,{v3(a,-1,b),v3(a,1,b)})
   else table.insert(GRID,{v3(a,b,-1),v3(a,b,1)})end
  end
 end end
end
-- The CLACK everyone hears: a deep click, then a bright one.
local CLACK={ReverbSoundEffect={DecayTime=2.6,WetLevel=-2,DryLevel=0,Density=1,Diffusion=1},
 EqualizerSoundEffect={LowGain=8,MidGain=0,HighGain=-6}}
local CLICK={ReverbSoundEffect={DecayTime=1.6,WetLevel=-5}}
local function backOut(x)local c=1.70158;x-=1;return 1+(c+1)*x*x*x+c*x*x end
local function smooth(x)x=math.clamp(x,0,1);return x*x*(3-2*x)end
local function across(a:Vector3,b:Vector3):number return Vector3.new(a.X-b.X,0,a.Z-b.Z).Magnitude end
-- When the edge of a Kit ring growing r0→r1 over `seconds` (easing out) reaches distance d.
local function reach(d:number,r0:number,r1:number,seconds:number):number?
 if d>r1 then return nil end
 return seconds*(1-(1-math.clamp((d-r0)/(r1-r0),0,1))^(1/3))
end
-- A bar from local point a to b of a cube posed at cf (its edges and lines are axis-aligned).
local function bar(cf:CFrame,a:Vector3,b:Vector3,w:number):(CFrame,Vector3)
 local d=b-a
 return cf*CFrame.new((a+b)/2),Vector3.new(math.abs(d.X)+w,math.abs(d.Y)+w,math.abs(d.Z)+w)
end
-- Hover height of the dog's feet, the cube's turn (world, about its centre) and scale at e
-- (seconds into the stage act). The colossal cube's dive delivers it at .5 a size too big
-- and it clamps down on the dog.
local function pose(e)
 local turn=CFrame.identity
 for _,s in ipairs(SNAPS)do
  local u=math.clamp((e-s[1])/SNAP,0,1)
  if u>0 then turn=CFrame.fromAxisAngle(s[2],math.pi/2*backOut(u))*turn end
 end
 local y,scale=LIFT,e<.5 and 0 or 1+.3*(1-smooth((e-.5)/.22))
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
-- Overlapping Cubedog arrivals hang their colossal cubes one above the other.
local slots={}

return function(ctx)
 ctx.WhisperStyle={Font=Enum.Font.Michroma,Color=C(200,242,255),Glitch=0,Chroma=false,Shake=false,Type=.035}
 local Kit,scope,model,config=ctx.Kit,ctx.Scope,ctx.Model,ctx.Config
 local low,hold,origin,map=ctx.Low,config.Hold,ctx.Origin,ctx.Kit.Map
 local calm=Kit.ReducedMotion()
 local CYAN=config.Color
 local CYANL=CYAN:Lerp(WHITE,.35)
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
 local intro=ctx.Late<PRE+DROP
 local function fresh(t)return ctx:Elapsed()-t<.35 end
 local stage=scope:Anchor(origin+Vector3.new(0,hc,0),'CubeStage')
 -- Where the little cube hangs with the dog inside (its centre).
 local hover=origin+Vector3.new(0,LIFT+hc,0)
 -- In open air the stage light stands in for the mouth's cyan lanterns.
 local shine=tongue and 0 or .8
 local glow=not low and scope:Light(stage,CYAN,20,shine)or nil
 -- The dog stays hidden until the cube brings it.
 local vis=intro and scope:Visibility(model)or nil
 if vis then vis.Set(1)end

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
 scope:Duck(.3,1)
 -- Brightness pulses on the big beats (the colours come from the sky's grade).
 local grade=scope:Grade({Brightness=0},.1,.4)

 local function voxel(at,s,color,material)
  return scope:Part({Name='Voxel',Size=Vector3.one*s,Color=color,Material=material,CFrame=CFrame.new(at)})
 end
 -- Open air: the stage can be a raised pad, so each piece finds the real ground under it
 -- once, just before it would reach the stage's level.
 local probe
 if not tongue then
  probe=RaycastParams.new();probe.FilterType=Enum.RaycastFilterType.Exclude;probe.RespectCanCollide=true
  local me=Players.LocalPlayer.Character
  probe.FilterDescendantsInstances=me and {model,me}or {model}
 end
 -- Ballistic voxels: one stepper per batch. They bounce on the belt (or the ground in open
 -- air, or their own Floor), stay inside the mouth walls on the tongue (x=±15.5 until the
 -- opening, 4 studs ahead; Free pieces fall elsewhere on the island) and fade at the end.
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
     if tongue and not v.Free and rel.Z<4 and math.abs(rel.X)>wall then
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

 ---------------------------------------------------------------- the whole island
 -- The colossal cube hangs over the yards (a little north, clear of the giant head's nose)
 -- when the stage is on the island, else above a far stage (the DOG-O-MATIC), toward the
 -- island and over the roofs there.
 local slot=1
 while slots[slot]do slot+=1 end
 slots[slot]=true
 scope:Add(function()slots[slot]=nil end)
 local flat=Vector3.new(origin.X-map.Center.X,0,origin.Z-map.Center.Z)
 local G=flat.Magnitude<260 and map.Center+Vector3.new(0,44+SIDE/2,15)
  or origin-flat.Unit*70+Vector3.new(0,100+SIDE/2,0)
 G+=Vector3.new(0,(slot-1)*(SIDE+60),0)
 -- A cyan dusk: the sun goes down, the haze and the clouds turn cyan, neon blooms.
 local sky=scope:Sky({
  Lighting={ClockTime=18.6,Brightness=1.25,ExposureCompensation=-.04,Ambient=C(58,92,120),OutdoorAmbient=C(74,124,156),
   ColorShift_Top=C(110,214,255)},
  Atmosphere={Density=.3,Offset=.12,Color=C(118,214,255),Decay=C(26,70,136),Glare=.3,Haze=1.4},
  Clouds={Cover=.6,Density=.4,Color=C(150,228,255)},
  Grade={TintColor=C(214,244,255),Saturation=.12,Contrast=.12},
  Bloom={Intensity=.8,Size=30,Threshold=1.15},
 },math.max(.4,2.6-ctx:Elapsed()),2.4)
 local cut,giant,glance,drone,trail=nil,nil,nil,nil,nil
 -- Where the colossal cube is now (every dog looks at it, the CLACK rings start there).
 local bigAt=G
 -- Shakes go to the cutaway's camera while it has this player's (Kit.Shake does nothing there).
 local function shake(power,seconds)
  if cut and cut.Active then cut:Shake(power,seconds)else Kit.Shake(power,seconds)end
 end
 local function bump(amount,seconds)
  if calm then return end
  grade.Brightness=amount;Kit.Tween(grade,seconds,{Brightness=0})
 end

 -- Every lamp on the island (its lights, the tongue's lantern lenses and edge guides), found
 -- once a few thousand instances a frame: the CLACKs blink them all cyan, the shockwaves
 -- blink them as they pass.
 local lamps={}
 task.spawn(function()
  if not district then return end
  for i,o in ipairs(district:GetDescendants())do
   if o:IsA('Light')then
    local p=o.Parent
    if p and p:IsA('BasePart')then table.insert(lamps,{Lamp=o,At=p.Position})
    elseif p and p:IsA('Attachment')then table.insert(lamps,{Lamp=o,At=p.WorldPosition})end
   elseif (o.Name=='WarmLens'or o.Name=='WarmEdgeGuide')and o:IsA('BasePart')then table.insert(lamps,{Lamp=o,At=o.Position})end
   if i%3000==0 then task.wait();if not scope.Alive then return end end
  end
 end)
 -- center: a wave from there (a Kit ring r0→r1 over span), else all at once.
 local function blink(seconds:number,center:Vector3?,r0:number?,r1:number?,span:number?)
  for _,l in ipairs(lamps)do
   local o=l.Lamp
   local delay:number?=0
   if center then delay=reach(across(l.At,center),r0 or 0,r1 or 1,span or 1)end
   if delay and o.Parent then
    task.delay(delay,function()
     if not scope.Alive or not o.Parent then return end
     local _,release=scope:Override(o,{Color=BLINK})
     task.delay(seconds,release)
    end)
   end
  end
 end

 -- The colossal cube: 12 edges, 8 corners and (not on Low) its ruled faces, moved together
 -- with BulkMoveTo. Between its beats it hangs still and is left alone.
 local bigParts,bigCF,edges,corners,grid={},{},{},{},{}
 local function piece(name,color)
  local p=scope:Part({Name=name,Color=color,Transparency=1,Size=Vector3.one,CFrame=CFrame.new(G)})
  table.insert(bigParts,p);table.insert(bigCF,p.CFrame)
  return p
 end
 for _,s in ipairs(STROKES)do table.insert(edges,{Part=piece('GiantEdge',CYAN),A=s[1],B=s[2],At=s[3],For=s[4]})end
 for _,c in ipairs(CORNERS)do table.insert(corners,{Part=piece('GiantCorner',WHITE),P=c.P,At=c.At,By=c.By})end
 if not low then for _,g in ipairs(GRID)do table.insert(grid,{Part=piece('GiantGrid',CYANL),A=g[1],B=g[2]})end end
 local small=half*1.3
 -- The cube's pose at t: CFrame (about its centre), half side, and how white it burns.
 local function bigPose(t)
  local turn=CFrame.identity
  for i,c in ipairs(CLACKS)do
   local u=math.clamp((t-c)/TURN,0,1)
   if u>0 then
    local axis=i==1 and face.RightVector or i==2 and Vector3.yAxis or face.LookVector
    turn=CFrame.fromAxisAngle(axis,math.pi/2*backOut(u))*turn
   end
  end
  local at,h,white=G,SIDE/2,0
  if t>=SHRINK then
   -- It swells a little, then collapses to a 16-stud cube...
   local u=math.min((t-SHRINK)/(DIVE-SHRINK),1)
   h=SIDE/2*(u<.3 and 1+.05*smooth(u/.3)or 1.05-(1.05-16/SIDE)*smooth((u-.3)/.7))
   white=u
  end
  if t>=DIVE then
   -- ...and dives, faster and faster, to stop dead around the dog a size too big.
   local u=math.clamp((t-DIVE)/(PRE+.5-DIVE),0,1)
   at=G:Lerp(hover,u*u);h=8+(small-8)*u;white=1
  end
  return CFrame.new(at)*turn*face,h,white
 end
 local function still(t)
  if t<DRAWN+.45 or t>=SHRINK then return false end
  for _,c in ipairs(CLACKS)do if t>=c-.05 and t<c+.45 then return false end end
  return true
 end
 local placed,sized=false,false
 scope:Every(function()
  local t=ctx:Elapsed()
  if t>=PRE+.5 then
   for _,p in ipairs(bigParts)do p:Destroy()end
   return false
  end
  local quiet=still(t)
  if quiet and placed then return true end
  placed=quiet
  local cf,h,white=bigPose(t)
  bigAt=cf.Position
  if giant and t<SHRINK then giant:Pose(cf)end
  if trail then trail.CFrame=CFrame.new(bigAt)end
  local resize=not sized or t<DRAWN+.45 or t>=SHRINK
  sized=true
  local k=h/(SIDE/2)
  local w=math.max(THICK*k,.3)
  local flash=white
  local d=t-DRAWN
  if d>=0 and d<.4 then flash=math.max(flash,1-d/.4)end
  for _,c in ipairs(CLACKS)do d=t-c;if d>=0 and d<.3 then flash=math.max(flash,1-d/.3)end end
  local color=CYAN:Lerp(WHITE,flash)
  local n=0
  for _,e in ipairs(edges)do
   n+=1
   local u=math.clamp((t-e.At)/e.For,0,1)
   local p=e.Part
   if u>0 then
    local a=e.A*h
    local at,box=bar(cf,a,a+(e.B-e.A)*h*u,w)
    bigCF[n]=at
    if resize then p.Size=box end
    p.Color=color;p.Transparency=.05
   else bigCF[n]=cf end
  end
  local node=math.max(9*k,.5)*(1+.5*flash)
  for _,c in ipairs(corners)do
   n+=1
   local p=c.Part
   local at,s=c.P*h,0
   if c.By then
    local e=edges[c.By]
    local u=math.clamp((t-e.At)/e.For,0,1)
    if u>0 then at=(e.A+(e.B-e.A)*u)*h;s=node*(u<1 and 1.35 or 1)end
   elseif t>=c.At then s=node*backOut(math.min((t-c.At)/.2,1))end
   if s>0 then p.Size=Vector3.one*s;p.Transparency=0;p.Color=WHITE:Lerp(CYAN,white*.5)else p.Transparency=1 end
   bigCF[n]=cf*CFrame.new(at)
  end
  local alpha=1
  if t>=SHRINK then alpha=math.min(.55+(t-SHRINK)/.3*.45,1)
  elseif t>=DRAWN then alpha=.55*math.min((t-DRAWN)/.4,1)end
  for _,g in ipairs(grid)do
   n+=1
   local at,box=bar(cf,g.A*h,g.B*h,w*.4)
   bigCF[n]=at
   if resize then g.Part.Size=box end
   g.Part.Transparency=alpha
  end
  workspace:BulkMoveTo(bigParts,bigCF,Enum.BulkMoveMode.FireCFrameChanged)
  return true
 end)

 -- Around this player, wherever they are: a point ahead of their camera on the ground plan.
 local ground=RaycastParams.new();ground.FilterType=Enum.RaycastFilterType.Exclude
 do
  local me=Players.LocalPlayer.Character
  ground.FilterDescendantsInstances=me and {model,me}or {model}
 end
 local function around(near:number,far:number,spread:number):Vector3
  local cam=workspace.CurrentCamera
  local look=cam and cam.CFrame.LookVector or fwd
  local f=Vector3.new(look.X,0,look.Z)
  f=f.Magnitude>.1 and f.Unit or Vector3.zAxis
  return Kit.Me()+f*Kit.Random(near,far)+f:Cross(Vector3.yAxis)*Kit.Random(-spread,spread)
 end
 -- Voxels tumbling out of the sky in front of this player (moved together with BulkMoveTo);
 -- each pops where it lands and falls again until the rain stops. Cyan glitter over their
 -- camera too. Returns stop().
 local function rain()
  local glitter=scope:Rain({Rate=36,Color=ColorSequence.new(CYAN,WHITE),Size=NumberSequence.new(.4,.12),
   Speed=NumberRange.new(24,34),Lifetime=NumberRange.new(2.2,2.8),Transparency=NumberSequence.new(.1,.6),Area=160,Height=65})
  local parts,cfs,drops={},{},{}
  local colors={CYAN,CYAN,WHITE,DEEP}
  for i=1,low and 12 or 36 do
   local s=Kit.Random(.5,1.3)
   parts[i]=scope:Part({Name='Voxel',Size=Vector3.one*s,Color=colors[(i-1)%4+1],Transparency=1,
    Material=i%4==3 and Enum.Material.SmoothPlastic or Enum.Material.Neon})
   cfs[i]=parts[i].CFrame
   drops[i]={Size=s,Wait=Kit.Random(0,1.4),Pos=parts[i].Position,Floor=0,Speed=0,Rot=CFrame.identity,Axis=Vector3.xAxis,Pop=-1}
  end
  local raining=true
  local function fall(d,p)
   local at=around(-10,70,55)
   local top=at.Y+Kit.Random(40,75)
   local hit=workspace:Raycast(Vector3.new(at.X,top,at.Z),Vector3.new(0,at.Y-top-60,0),ground)
   d.Floor=(hit and hit.Position.Y or at.Y-40)+d.Size/2
   d.Pos=Vector3.new(at.X,top,at.Z);d.Speed=Kit.Random(26,40);d.Pop=-1
   local axis=Vector3.new(Kit.Random(-1,1),Kit.Random(-1,1),Kit.Random(-1,1))
   d.Axis=axis.Magnitude>.05 and axis.Unit or Vector3.xAxis
   p.Size=Vector3.one*d.Size;p.Transparency=.05
  end
  scope:Every(function(dt)
   local busy=false
   for i,d in ipairs(drops)do
    local p=parts[i]
    if d.Wait>0 then
     d.Wait-=dt
     if d.Wait<=0 then if raining then fall(d,p)else d.Wait=math.huge end end
    elseif d.Pop>=0 then
     d.Pop+=dt
     if d.Pop>=.25 then p.Transparency=1;d.Wait=raining and Kit.Random(.05,.5)or math.huge
     else p.Size=Vector3.one*d.Size*(1-d.Pop/.25)end
    else
     d.Pos-=Vector3.new(0,d.Speed*dt,0)
     d.Rot*=CFrame.fromAxisAngle(d.Axis,5*dt)
     if d.Pos.Y<=d.Floor then d.Pos=Vector3.new(d.Pos.X,d.Floor,d.Pos.Z);d.Pop=0 end
    end
    cfs[i]=CFrame.new(d.Pos)*d.Rot
    busy=busy or d.Wait~=math.huge
   end
   workspace:BulkMoveTo(parts,cfs,Enum.BulkMoveMode.FireCFrameChanged)
   if busy then return true end
   for _,p in ipairs(parts)do p:Destroy()end
   return false
  end)
  return function()raining=false;glitter.Rate=0 end
 end
 -- A block breaks off the sky and shatters on the ground right in front of this player.
 local function shatter(at:Vector3,s:number)
  local pieces={}
  for i=1,low and 4 or 8 do
   local k=Kit.Random(.5,1)
   local out=Vector3.new(Kit.Random(-1,1),0,Kit.Random(-1,1))
   out=out.Magnitude>.05 and out.Unit or Vector3.xAxis
   local from=at+Vector3.new(0,s/2,0)+out*s*.3
   local white=i%3==0
   table.insert(pieces,{Part=voxel(from,k,white and WHITE or CYAN,white and Enum.Material.SmoothPlastic or Enum.Material.Neon),
    Pos=from,Size=k,Rot=CFrame.identity,Vel=out*Kit.Random(8,16)+Vector3.new(0,Kit.Random(14,24),0),
    Spin=Vector3.new(Kit.Random(-10,10),Kit.Random(-10,10),Kit.Random(-10,10)),Floor=at.Y+k/2,Free=true})
  end
  throw(pieces,80,1.2)
  scope:Ring(at+Vector3.new(0,.3,0),CYAN,.5,8,.4,{Thickness=.3,Segments=20})
  local a=scope:Anchor(at+Vector3.new(0,1,0),'Clack')
  Kit.Cue('Impact',a,.55)
  Kit.Shot(a,Kit.Tick,.8,1.5,CLICK)
  task.delay(4,function()if a.Parent then a:Destroy()end end)
  if not(cut and cut.Active)then Kit.Shake(.12,.2)end
 end
 local function drop()
  local spot=around(14,30,16)
  local hit=workspace:Raycast(spot+Vector3.new(0,60,0),Vector3.new(0,-140,0),ground)
  if not hit then return end
  local at=hit.Position
  local s=Kit.Random(2.4,3.4)
  local top=at.Y+70
  local cube=scope:Part({Name='SkyBlock',Size=Vector3.one*s,Color=CYANL,CFrame=CFrame.new(at.X,top,at.Z)})
  local axis=Vector3.new(Kit.Random(-1,1),Kit.Random(-1,1),Kit.Random(-1,1))
  axis=axis.Magnitude>.05 and axis.Unit or Vector3.xAxis
  local born=os.clock()
  scope:Every(function()
   local t=os.clock()-born
   local y=top-55*t*t
   if y>at.Y+s/2 then cube.CFrame=CFrame.new(at.X,y,at.Z)*CFrame.fromAxisAngle(axis,t*7);return true end
   cube:Destroy()
   shatter(at,s)
   return false
  end)
 end
 -- CLACK: the colossal cube snaps a quarter-turn. A ring flies off it in the plane it turns
 -- in, the ghost inside flinches, every lamp blinks, every screen pulses.
 local function clack(i)
  Kit.Shot(nil,Kit.Tick,1,.5,CLACK)
  task.delay(.05,function()if scope.Alive then Kit.Shot(nil,Kit.Tick,.7,1.2,CLICK)end end)
  Kit.Cue('Impact',nil,.45)
  blink(.3)
  local U=i==1 and Vector3.yAxis or face.RightVector
  local W=i==3 and Vector3.yAxis or face.LookVector
  scope:Ring(bigAt,CYANL,SIDE*.62,SIDE*1.25,.9,{Thickness=3,Alpha=.2,U=U,W=W})
  if giant and ctx:Elapsed()<SHRINK-.2 then
   giant:Play('Impact')
   giant:Fade(.15,.05)
   task.delay(.12,function()if giant and scope.Alive and ctx:Elapsed()<SHRINK then giant:Fade(.5,.5)end end)
  end
  bump(.16,.45)
  shake(.18,.25)
 end
 -- Every camera is pulled to the stage for the dive and the stage act: wide on the sky (the
 -- cube collapsing over the island), down with the dive, then in close for the little
 -- cube's snaps, the drop and the shatter. Each spot is pulled in front of anything solid
 -- between it and what it looks at.
 local function cutaway()
  local sight=RaycastParams.new();sight.FilterType=Enum.RaycastFilterType.Exclude
  local me=Players.LocalPlayer.Character
  sight.FilterDescendantsInstances=me and {model,me,scope.Folder}or {model,scope.Folder}
  local function shot(at:number,pos:Vector3,look:Vector3,fov:number)
   local d=pos-look
   local hit=d.Magnitude>1 and workspace:Raycast(look,d,sight)
   if hit then pos=hit.Position-d.Unit*1.5 end
   return {At=at,CFrame=Kit.Frame(pos,look),Fov=fov}
  end
  local up=Vector3.yAxis
  local side=fwd:Cross(up)
  if side:Dot(map.Center-origin)<0 then side=-side end
  local mid=(G+hover)/2
  return ctx:Cutaway({
   shot(6.45,mid+side*390+fwd*120+up*30,mid+up*25,64),
   shot(DIVE,mid+side*230+fwd*90+up*10,mid,56),
   shot(PRE+.55,hover+fwd*58+side*16+up*10,hover,50),
   shot(PRE+1.5,hover+fwd*30+side*6-up*2,hover-up,46),
   shot(PRE+LAND,origin+fwd*24+side*4+up*6.5,origin+up*3,50),
   shot(PRE+2.95,origin+fwd*21+side*3+up*5.5,origin+up*3.5,56),
  },{Focus=origin,Shake=.1})
 end
 -- It stops dead around the dog: a shockwave rolls across the map (the lamps blink as it
 -- passes, and it shakes each player as it reaches them) and light shoots up from the stage.
 local function slam()
  if glance then glance:Stop(1.2)end
  if trail then
   for _,o in ipairs(trail:GetChildren())do
    if o:IsA('ParticleEmitter')then o.Rate=0 elseif o:IsA('PointLight')then Kit.Tween(o,.5,{Brightness=0})end
   end
  end
  if not fresh(PRE+.5)then return end
  Kit.Cue('Impact',nil,1)
  Kit.Shot(nil,Kit.Tick,1,.42,CLACK)
  local R=map.Radius*1.3
  scope:Ring(origin+Vector3.new(0,.6,0),CYAN,6,R,1.8,{Thickness=3.5,Alpha=.1})
  if not low then scope:Ring(origin+Vector3.new(0,1.4,0),WHITE,3,map.Radius*1.05,1.3,{Thickness=1.4,Alpha=.3,Segments=40})end
  scope:Pillar(origin,origin+Vector3.new(0,260,0),CYAN,10,1.3)
  blink(1.2,origin,6,R,1.8)
  if cut and cut.Active then cut:Shake(.9,.5)
  else
   local t=reach(across(Kit.Me(),origin),6,R,1.8)
   if t then task.delay(t,function()if scope.Alive and not(cut and cut.Active)then Kit.Shake(.3,.35)end end)end
  end
  Kit.Flash(C(220,250,255),.55,.45)
  bump(.2,.5)
 end

 -- The pen: a rising tick as each stroke starts (the four pillars rise with a whoosh).
 task.spawn(function()
  local last=-1
  for i,s in ipairs(STROKES)do
   if s[3]~=last then
    last=s[3]
    if not ctx:Wait(s[3])then return end
    if fresh(s[3])then
     if s[4]>.4 then Kit.Cue('Whoosh',nil,.55)
     else Kit.Shot(nil,Kit.Tick,.34,.95+.12*i,CLICK)end
    end
   end
  end
 end)
 -- The map-wide beats, on the server clock (late clients skip what they missed).
 task.spawn(function()
  if not ctx:Wait(.4)then return end
  drone=scope:Drone('Drone',low and .18 or .28,.72,2.5)
  if not ctx:Wait(1.3)then return end
  -- The ghost of Cubedog rises into the cube while it is drawn.
  if ctx:Elapsed()<SHRINK-.6 then
   giant=ctx:Colossus({Height=SIDE*.55,At=CFrame.new(G)*face,Style='Ghost',Color=CYAN,Alpha=.5,Clip='Idle',
    Rise=36,FadeIn=math.max(.6,3.3-ctx:Elapsed())})
  end
  if not ctx:Wait(2.6)then return end
  -- Every dog on the island looks up at it (and follows it down the dive).
  if ctx:Elapsed()<PRE then glance=scope:Glance(function()return bigAt end,{Exclude=model,Turn=1,Ripple=500})end
  if not ctx:Wait(DRAWN)then return end
  if fresh(DRAWN)then
   Kit.Cue('Chime',nil,.5)
   scope:Ring(bigAt,WHITE,SIDE*.62,SIDE*1.4,1.1,{Thickness=2.5,Alpha=.25})
  end
  if not ctx:Wait(3.1)then return end
  local stopRain=ctx:Elapsed()<SHRINK and rain()or nil
  if not ctx:Wait(3.5)then return end
  if fresh(3.5)and not low then drop()end
  if not ctx:Wait(CLACKS[1])then return end
  if fresh(CLACKS[1])then clack(1);drop()end
  if not ctx:Wait(CLACKS[2])then return end
  if fresh(CLACKS[2])then clack(2);if not low then drop()end end
  if not ctx:Wait(5.6)then return end
  cut=cutaway()
  if not ctx:Wait(CLACKS[3])then return end
  if fresh(CLACKS[3])then clack(3)end
  if not ctx:Wait(SHRINK)then return end
  -- It collapses; the ghost goes with it and the rain stops.
  if fresh(SHRINK)then Kit.Cue('Whoosh',nil,.6)end
  if giant then giant:Stop(.45)end
  if stopRain then stopRain()end
  if not ctx:Wait(DIVE)then return end
  -- The dive: a comet of cyan sparks lighting up what it passes.
  if fresh(DIVE)then Kit.Cue('Whoosh',nil,.75);Kit.Shot(nil,Kit.Tick,.6,2.4,CLICK)end
  if ctx:Elapsed()<PRE+.4 then
   trail=scope:Anchor(bigAt,'Dive')
   scope:Emitter(trail,{Rate=low and 60 or 180,Color=ColorSequence.new(WHITE,CYAN),Lifetime=NumberRange.new(.35,.7),
    Speed=NumberRange.new(0,3),Size=NumberSequence.new(2.2,0)})
   if not low then scope:Light(trail,CYAN,40,3)end
  end
  if not ctx:Wait(PRE+.5)then return end
  slam()
  if not ctx:Wait(PRE+LAND)then return end
  if drone then Kit.Tween(drone,1.8,{Volume=0})end
  if not ctx:Wait(PRE+3.6)then return end
  -- The aftermath: the sky eases back before the dog sets off.
  sky:Release(2.6)
 end)

 ---------------------------------------------------------------- the stage
 local landed,lift,hl,motes,coreLight=false,nil,nil,nil,nil
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
 -- pairs from behind the dog to its front as the sky dims. They snap with the little cube,
 -- flash on the landing and fade as the dog sets off.
 if not tongue then
  local runes={}
  for i=1,8 do runes[i]=scope:Part({Name='CubeRune',Color=CYAN,Size=Vector3.one*.05,Transparency=1})end
  scope:Every(function()
   settle()
   local t=ctx:Elapsed()
   local e=t-PRE
   local _,turn=pose(e)
   local out=math.clamp((t-(hold-.8))/.8,0,1)
   local flash=e>=LAND and math.max(0,1-(e-LAND)/.4)or 0
   for _,s in ipairs(SNAPS)do local d=e-s[1];if d>=0 and d<.25 then flash=math.max(flash,1-d/.25)end end
   local right=fwd:Cross(Vector3.yAxis)
   for i,p in ipairs(runes)do
    local k=math.floor((i-1)/2)
    local a=math.rad(157.5-45*k)*(i%2==0 and -1 or 1)
    local u=intro and math.clamp((t-.3-k*.07)/.25,0,1)or 1
    p.Size=Vector3.one*math.max(.8*backOut(u),.05)
    p.CFrame=CFrame.new(origin+(fwd*math.cos(a)+right*math.sin(a))*6.5+Vector3.new(0,1.3+.15*math.sin(t*2.4+i),0))*turn*face
    p.Color=CYAN:Lerp(WHITE,flash);p.Transparency=u>0 and .05+.95*out or 1
   end
   return out<1
  end)
 end
 if intro then
  if fresh(0)then Kit.Cue('Chime',nil,.45)end
  if aimed then lift=scope:Offset(model)end
  -- The landing square on the belt, square to the dog (and the cube) as they land.
  for _,o in ipairs(SIDES)do
   table.insert(square,scope:Part({Name='LandingSquare',Color=CYAN,Transparency=1,
    CFrame=CFrame.new(origin+face:VectorToWorldSpace(o*sq)+Vector3.new(0,.06,0))*face,
    Size=o.X==0 and Vector3.new(sq*2+.15,.1,.15)or Vector3.new(.15,.1,sq*2+.15)}))
  end
  -- The little wireframe: 12 edges and 8 corner nodes, posed every frame with the dog.
  local cube={}
  for _,a in ipairs({-1,1})do for _,b in ipairs({-1,1})do
   for _,e in ipairs({{Vector3.new(0,a,b),Vector3.xAxis},{Vector3.new(a,0,b),Vector3.yAxis},{Vector3.new(a,b,0),Vector3.zAxis}})do
    table.insert(frame,{Part=scope:Part({Name='CubeEdge',Color=CYAN,Transparency=1,Size=Vector3.one*.1}),At=e[1],Axis=e[2]})
   end
   for _,c in ipairs({-1,1})do table.insert(cube,Vector3.new(a,b,c))end
  end end
  if not low then for i=1,8 do nodes[i]=scope:Part({Name='CubeCorner',Color=WHITE,Transparency=1,Size=Vector3.one*.1})end end
  local core=scope:Anchor(hover,'CubeCore')
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
   local e=ctx:Elapsed()-PRE
   -- Nothing on the stage until the colossal cube is about to come down.
   if e<-1.3 then return true end
   settle()
   local y,turn,scale=pose(e)
   if lift then lift.CFrame=CFrame.new(0,y+hc,0)*unface*turn*face*CFrame.new(0,-hc,0)end
   local v=lift and 1-math.clamp((e-.5)/.25,0,1)or 1
   if v~=shown and vis then shown=v;vis.Set(v)end
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
    p.Size=Vector3.one*math.max(.55*(1+.8*flash)*math.min(scale,1),.05);p.CFrame=cf*CFrame.new(cube[i]*a);p.Transparency=alpha
   end
   core.CFrame=CFrame.new(cf.Position)
   for _,g in ipairs(guides)do
    local best,most=Vector3.zero,-math.huge
    for _,c in ipairs(cube)do local w=cf:VectorToWorldSpace(c);local d=w:Dot(g.Dir);if d>most then best,most=w,d end end
    g.Top.CFrame=CFrame.new(cf.Position+best*a)
   end
   -- The square shows as the colossal cube collapses, blinks faster once the little one
   -- has stopped turning, and holds for the drop.
   local hz=e<1.6 and 4 or 9
   local mark=e<-1.2 and 1 or e>=DROP and 0 or ((e*hz)%1<.5 and .2 or .7)
   for _,p in ipairs(square)do p.Transparency=mark end
   return true
  end)

  if not ctx:Wait(PRE+.5)then return end
  -- The dive delivers the little cube around the dog.
  if fresh(PRE+.5)then
   scope:Burst(core.Position,CYAN,24,{Speed=NumberRange.new(5,12),Lifetime=NumberRange.new(.3,.7),Size=NumberSequence.new(.4,0)})
  end
  hl=scope:Highlight(model,CYAN,WHITE,.3,.15)
  Kit.Tween(hl,.6,{FillTransparency=.82})
  if motes then motes.Rate=10 end
  for _,g in ipairs(guides)do g.Beam.Transparency=NumberSequence.new(.3,.85)end
  for _,s in ipairs(SNAPS)do
   if not ctx:Wait(PRE+s[1])then return end
   if fresh(PRE+s[1])then
    Kit.Cue('Glitch',stage,.28)
    local n=Kit.Near(origin,120)
    if n>.05 then shake(.12*n,.12)end
   end
  end
  if not ctx:Wait(PRE+1.8)then return end
  if fresh(PRE+1.8)then Kit.Cue('Heartbeat',nil,.55)end
  if not ctx:Wait(PRE+DROP)then return end
  if fresh(PRE+DROP)then Kit.Cue('Whoosh',nil,.4)end
 end

 if not ctx:Wait(PRE+LAND)then return end
 -- It lands.
 landed=true
 if lift then lift.CFrame=CFrame.identity end
 if vis then vis.Set(0)end
 if fresh(PRE+LAND)then
  local n=Kit.Near(origin,120)
  Kit.Cue('Impact',nil,.95)
  task.delay(.1,function()if scope.Alive then Kit.Cue('Chime',nil,.4)end end)
  if n>.05 then shake(.6*n,.45);Kit.Flash(C(200,242,255),1-.3*n,.35)end
  if n>.25 then Kit.FOVPunch(-4*n,.05,.5)end
  scope:Ring(origin+Vector3.new(0,.2,0),CYAN,1,13,.45,{Thickness=.35})
  if not low then scope:Ring(origin+Vector3.new(0,.25,0),WHITE,.6,8,.3,{Thickness=.18,Alpha=.35,Segments=24})end
  -- A second, softer wave across the whole map; the lamps answer it as it passes.
  scope:Ring(origin+Vector3.new(0,.4,0),WHITE,4,map.Radius,1.4,{Thickness=2,Alpha=.2})
  blink(.8,origin,4,map.Radius,1.4)
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

 if not ctx:Wait(PRE+3.2)then return end
 -- The flip: voxel confetti pops off the top.
 if fresh(PRE+3.2)then
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
 if not ctx:Wait(PRE+4.2)then return end
 -- The happy spin sheds sparkles from its body.
 if fresh(PRE+4.2)and not low then
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
