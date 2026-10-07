-- LONG DOG: "HOW LONG IS A DOG?" Its owner dug it up; it went into the ground in their yard
-- (their pit spits dirt) and comes out of the giant head's mouth, for everyone. The head
-- bursts out of the throat and trots up the whole tongue, through the end portal, down the
-- boulevard to the plaza where players spawn, while its body keeps pouring out of the mouth
-- behind it: one furry sausage lying on the ground from the throat to the spawn pad, its
-- LENGTH on every screen. It turns, looks back and barks; the tail finally pops out of the
-- throat; then the whole dog snaps back into the mouth like a tape measure and a perfectly
-- normal (still long, LongDogBody) Long Dog stands on the stage.
-- The server (Runtime.RevealExcavation) stands the display dog on the tongue's stage, hidden
-- here until the end, and stops the tongue for the hold. Everything here is local.
local Players=game:GetService('Players')
local AssetService=game:GetService('AssetService')
local RS=game:GetService('ReplicatedStorage')
local AnimationPlayer=require(RS:WaitForChild('DogAnimationPlayer'))
local C=Color3.fromRGB
local SAND,DIRT,DUST=C(240,196,120),C(104,72,42),C(206,176,132)
local TAPE,INK,METAL=C(255,204,46),C(30,22,10),C(136,142,150)
-- The fur until the dog's own texture has been sampled (or when it cannot be read).
local FUR=C(198,135,74)
local TICK='rbxasset://sounds/volume_slider.ogg'

-- The runners are local copies of the dog (ReplicatedStorage.MenuModels), in template units:
-- the template is 2.19 tall and 5.9 long, faces -Z and its pivot sits .05 under its soles.
local SCALE=5            -- 11 studs tall: under the mouth's roof (23.5) and the end portal (~17)
local HEIGHT=2.19
local SPINE,SOLE=1.02,.05
local TUBE=.465          -- the body's radius, just over the torso's (~.43): it covers the tucked
                         -- half of each runner
local SEAM=1.44          -- LongSeg3, behind the front legs: where the body meets a runner
local NOSE,TAILTIP=1.585,4.315
local RAMP=3.2           -- the body sags from the spine's height onto the ground over this
local STRIDE=.475*1.5    -- what one Walk cycle covers (DogWalkProfiles: NativeSpeed x Duration)
local REACH=2.1          -- the legs swing this much wider than the Walk clip: a long, low trot
local MAXHZ=3.4          -- strides per second at most (beyond it the paws slide a little)
local M_PER_STUD=.28
-- The route, checked against every part on the map: straight up x=0 from inside the throat
-- (its wall's face is at z -182.5), along the tongue (top 2.08), through the end portal
-- (z 136, opening x +-8.5, 17 high), the portal court, the boulevard and the welcome plaza,
-- then a hook to the west round the spawn pad, so the head ends up looking back down its own
-- body. Nothing stands within 4 studs of x=0 from the throat to the plaza.
local THROAT=-192
local FACE=-182.5
local TURN_Z,TURN_R,TURN_A=372,11,math.rad(120)
local STRAIGHT=TURN_Z-THROAT
local ROUTE=STRAIGHT+TURN_R*TURN_A
local STEP=2
-- The act on the arrival clock (SecretArrivalConfig.Dogs.LongDog: Hold 26, Happy at 22).
local T_BURST=2       -- the head bursts out of the throat
local T_RUN=2.5       -- ...lands and runs
local T_STOP=16.5     -- at the spawn plaza: it looks back down its body and barks
local T_POP=18.5      -- the tail pops out of the throat
local T_TENSE=19.5    -- the tape measure catches...
local T_YANK=19.85    -- ...and snaps back
local T_SHRINK=21.25  -- back to its normal size as it reaches the stage
local T_SETTLE=21.45
local T_JOIN=22       -- the display dog takes over
local T_TITLE=22.6
local RUN_FROM=14     -- where the burst lands (path studs)
local ACC,DEC=1.2,2.8 -- the run eases in and out over these
local START=FACE-NOSE*SCALE-THROAT   -- the head's nose at the throat wall
local TAIL_IN,TAIL_OUT=6,25          -- the tail runner inside the throat / its hind legs out

local function smooth(x)x=math.clamp(x,0,1);return x*x*(3-2*x)end
local function backOut(u)u=math.clamp(u,0,1);local v=u-1;return 1+2.7*v*v*v+1.7*v*v end
-- Where the path is at s (y=0): straight up x=0, then the hook, then on along its end.
local function flat(s)
 if s<=STRAIGHT then return Vector3.new(0,0,THROAT+s)end
 local a=math.min(s-STRAIGHT,TURN_R*TURN_A)/TURN_R
 local p=Vector3.new(-TURN_R+TURN_R*math.cos(a),0,TURN_Z+TURN_R*math.sin(a))
 if s>ROUTE then p+=Vector3.new(-math.sin(TURN_A),0,math.cos(TURN_A))*(s-ROUTE)end
 return p
end
-- The map's own ground along the route (parts.tsv), for whatever is not streamed in.
local function profile(p)
 local z=p.Z
 if z<-168 then return 2 elseif z<136.7 then return 2.08 elseif z<146 then return .36
 elseif z<322 then return .5 elseif z<362 then return .64
 elseif Vector3.new(p.X,0,p.Z-377).Magnitude<7.9 then return .57 end
 return .5
end

-- The average colour of the dog's own fur texture (an EditableImage of its ColorMap), so the
-- body matches the head. Yields; nil when the image cannot be read (asset permissions).
local furCache=nil
local function sampleFur(source)
 if furCache~=nil then return furCache or nil end
 local sa=source and source:FindFirstChildWhichIsA('SurfaceAppearance',true)
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
 furCache=ok and color or false
 return furCache or nil
end

local running=0
return function(ctx)
 ctx.ManualBanner=true
 ctx.WhisperStyle={Font=Enum.Font.Kalam,Color=C(255,230,186),Type=.05}
 local Kit,scope,config=ctx.Kit,ctx.Scope,ctx.Config
 local model=ctx.Model
 local low,calm,hold=ctx.Low,Kit.ReducedMotion(),config.Hold
 local player=Players.LocalPlayer
 local origin=ctx.Origin
 local function live(t)return ctx:Elapsed()-t<.35 end
 running+=1
 scope:Add(function()running-=1 end)
 local district=workspace:FindFirstChild('DOGROTS_District')

 -- The real (display) dog waits, hidden, until the very end: at `at` it appears in a puff
 -- of dust and the reveal card follows.
 local vis=scope:Visibility(model);vis.Set(1)
 local function reveal(at)
  task.spawn(function()
   if not ctx:Wait(at)then return end
   vis.Set(0)
   if live(at)then
    scope:Burst(origin+Vector3.new(0,1.5,0),DUST,30,{Texture=Kit.Textures.Smoke,LightEmission=0,LightInfluence=1,Speed=NumberRange.new(4,10),
     SpreadAngle=Vector2.new(80,80),Drag=3,Lifetime=NumberRange.new(.8,1.4),Size=NumberSequence.new(3,7),Transparency=NumberSequence.new(.35,1)})
    Kit.Cue('Impact',nil,.7);task.delay(.1,function()Kit.Cue('Chime',nil,.6)end)
    local shine=scope:Highlight(model,SAND,C(255,244,214),.35,0)
    Kit.Tween(shine,1.2,{FillTransparency=1,OutlineTransparency=1})
   end
   local card=at+(T_TITLE-T_JOIN)
   if ctx:Wait(card)and ctx:Elapsed()<card+2 then ctx:Title({Hold=3.2})end
  end)
 end
 -- Another Long Dog is already running here (two found at once), or its display dog stands
 -- somewhere other than the giant mouth's stage (the act ends on it): it just appears.
 if running>1 or math.abs(origin.X)>6 or origin.Z<FACE or origin.Z>TURN_Z then reveal(T_BURST);ctx:Wait(hold);return end

 ---------------------------------------------------------------- the ground along the route
 local skip={model}
 for _,name in ipairs({'DOGROTS_SecretArrivalFX','DOGROTS_SecretReveals','DogDexLocalDisplays','DOGROTS_SecretAuraFX'})do
  local o=workspace:FindFirstChild(name);if o then table.insert(skip,o)end
 end
 local line=district and district:FindFirstChild('03_DogLine')
 local conveyor=line and line:FindFirstChild('ActiveDogs')
 if conveyor then table.insert(skip,conveyor)end
 local kennels=district and district:FindFirstChild('KennelDogs')
 if kennels then table.insert(skip,kennels)end
 for _,p in ipairs(Players:GetPlayers())do if p.Character then table.insert(skip,p.Character)end end
 local params=RaycastParams.new();params.FilterType=Enum.RaycastFilterType.Exclude
 -- From under the mouth's roof and the arches (it walks under them), down to the first
 -- visible, solid part. Parts that are not streamed in fall back to the map's profile.
 local function cast(p)
  for _=1,5 do
   params.FilterDescendantsInstances=skip
   local hit=workspace:Raycast(Vector3.new(p.X,14,p.Z),Vector3.new(0,-30,0),params)
   if not hit then return nil end
   local part=hit.Instance
   if part:IsA('Terrain')then return hit.Position.Y end
   if part:IsA('BasePart')and part.Transparency<.95 and part.CanCollide then return hit.Position.Y end
   table.insert(skip,part)
  end
  return nil
 end
 local count=math.ceil((ROUTE+48)/STEP)
 local raw={}
 for i=0,count do
  local p=flat(i*STEP)
  local h=(p.Z>FACE+1 and i%2==0)and cast(p)or nil
  -- Something odd under it (a hole, a prop left on the path): the map knows better.
  if h then h=math.clamp(h,profile(p)-1.5,profile(p)+8)end
  raw[i]=h or false
 end
 for i=0,count do
  if not raw[i]then
   local a,b=raw[i-1],raw[i+1]
   raw[i]=(a and b)and(a+b)/2 or profile(flat(i*STEP))
  end
 end
 -- Over bumps and off steps (the tongue's tip drops 1.7) rather than through their edges:
 -- the highest ground within 4 studs, smoothed, never below the ground itself.
 local heights={}
 for i=0,count do
  local h=raw[i]
  for j=math.max(i-2,0),math.min(i+2,count)do h=math.max(h,raw[j])end
  heights[i]=h
 end
 for _=1,3 do
  local was=table.clone(heights)
  for i=1,count-1 do heights[i]=(was[i-1]+2*was[i]+was[i+1])/4 end
 end
 for i=0,count do heights[i]=math.max(heights[i],raw[i])end
 local function ground(s)
  local f=math.clamp(s/STEP,0,count)
  local i=math.floor(f);local j=math.min(i+1,count)
  return heights[i]+(heights[j]-heights[i])*(f-i)
 end

 ---------------------------------------------------------------- the act's geometry
 -- The display dog the act ends on (VisualSize is its stretched size), on the stage.
 local display=Kit.Size(model)
 local sizeEnd=math.clamp(display.Y/HEIGHT,.4,SCALE)
 local stage=origin.Z-THROAT
 local JOIN_H=stage+display.Z/2-NOSE*sizeEnd
 local JOIN_T=stage-display.Z/2+TAILTIP*sizeEnd
 -- A display dog that is not stretched (or not sized) is shorter than two half dogs.
 if JOIN_T>JOIN_H then JOIN_H=(JOIN_H+JOIN_T)/2;JOIN_T=JOIN_H end
 local S_END=ROUTE
 -- The pose this frame: head and tail runner positions (path studs), their bounce, the scale.
 local pose={H=START,T=nil,S=SCALE,HeadLift=0,TailLift=0}
 -- The body's centre above the ground at s: held up at the spine's height behind each
 -- runner's legs, lying on the ground in between.
 local function lift(s)
  local S=pose.S
  local rt=TUBE*S
  local spine=(SPINE-SOLE)*S
  local ramp=RAMP*S
  local d=(pose.H-SEAM*S)-s
  local k=d<=0 and 1 or 1-smooth(d/ramp)
  local up=k*(spine+pose.HeadLift-rt)
  if pose.T then
   local e=s-(pose.T+(NOSE+.4)*S)
   local q=e<=0 and 1 or 1-smooth(e/ramp)
   up=math.max(up,q*(spine+pose.TailLift-rt))
  end
  return rt+math.max(up,0)
 end
 local function center(s)local p=flat(s);return Vector3.new(p.X,ground(s)+lift(s),p.Z)end
 local function along(s)
  local d=center(s+1.5)-center(s-1.5)
  return d.Magnitude>1e-4 and d.Unit or Vector3.zAxis
 end
 local function frame(s)local p=center(s);return CFrame.lookAt(p,p+along(s))end
 -- A runner's pivot at s, standing on the ground, raised by lift.
 local function pivotAt(s,up,S)
  local p=flat(s)
  local d=flat(s+2)-flat(s-2)
  local level=Vector3.new(d.X,0,d.Z)
  level=level.Magnitude>1e-4 and level.Unit or Vector3.zAxis
  local pitch=math.clamp(math.atan2(ground(s+2)-ground(s-2),4),-.3,.3)
  local at=Vector3.new(p.X,ground(s)+up-SOLE*S,p.Z)
  return CFrame.lookAt(at,at+level)*CFrame.Angles(pitch,0,0)
 end

 ---------------------------------------------------------------- the timeline
 local function runS(t)
  local T=T_STOP-T_RUN
  local V=(S_END-RUN_FROM)/(T-(ACC+DEC)/2)
  local u=t-T_RUN
  if u<=0 then return RUN_FROM,0 end
  if u<ACC then return RUN_FROM+V*u*u/(2*ACC),V*u/ACC end
  local a=RUN_FROM+V*ACC/2
  if u<T-DEC then return a+V*(u-ACC),V end
  local b=a+V*(T-DEC-ACC)
  local w=math.min(u-(T-DEC),DEC)
  return b+V*w-V*w*w/(2*DEC),V*(1-w/DEC)
 end
 local function headS(t)
  if t<T_BURST then return START end
  if t<T_RUN then local u=(t-T_BURST)/(T_RUN-T_BURST);return START+(RUN_FROM-START)*(1-(1-u)^3)end
  if t<T_STOP then return(runS(t))end
  if t<T_TENSE then return S_END end
  if t<T_YANK then return S_END-3*smooth((t-T_TENSE)/(T_YANK-T_TENSE))end
  local from,to=S_END-3,JOIN_H+8
  if t<T_SETTLE then
   -- A tape measure: it picks up speed all the way and clacks home.
   local u=(t-T_YANK)/(T_SETTLE-T_YANK)
   local f=u<.7 and .75*(u/.7)^2 or .75+.25*(1-(1-(u-.7)/.3)^2)
   return from+(to-from)*f
  end
  return JOIN_H+8*(1-backOut((t-T_SETTLE)/(T_JOIN-.15-T_SETTLE)))
 end
 local function tailS(t)
  if t<T_POP then return nil end
  if t<T_POP+.45 then return TAIL_IN+(TAIL_OUT-TAIL_IN)*backOut((t-T_POP)/.45)end
  if t<T_SHRINK then return TAIL_OUT end
  return TAIL_OUT+(JOIN_T-TAIL_OUT)*smooth((t-T_SHRINK)/(T_JOIN-.15-T_SHRINK))
 end
 local function scaleAt(t)
  if t<T_SHRINK then return SCALE end
  return SCALE+(sizeEnd-SCALE)*smooth((t-T_SHRINK)/(T_JOIN-.15-T_SHRINK))
 end

 ---------------------------------------------------------------- the runners
 local PIN={'LongSeg1','LongSeg2','LongSeg3','LongSeg4','LongSeg5','LongSeg6'}
 local function restWorld(bone)
  local parent=bone.Parent
  if parent and parent:IsA('Bone')then
   local up=restWorld(parent)
   return up and up*bone.CFrame
  end
  if parent and parent:IsA('BasePart')then return parent.CFrame*bone.CFrame end
  return nil
 end
 -- role 'Head': the front half shows (head, forelegs, chest); hind legs and tail tuck up into
 -- the body. role 'Tail': the back half shows (hind legs, tail); head and forelegs tuck in.
 local function build(role)
  local menu=RS:FindFirstChild('MenuModels')
  if not menu then return nil end
  local copy=Kit.DogCopy('LongDog')
  if not copy then return nil end
  local m=copy
  local bones={}
  for _,o in ipairs(m:GetDescendants())do if o:IsA('Bone')then bones[o.Name]=bones[o.Name]or o end end
  local pivot=m:GetPivot()
  local base=m:GetScale()
  local rest={}
  for _,name in ipairs(PIN)do
   local bone=bones[name]
   local w=bone and restWorld(bone)
   if not w then m:Destroy();return nil end
   rest[name]={Z=pivot:ToObjectSpace(w).Position.Z/base,Rotation=pivot:ToObjectSpace(w).Rotation}
  end
  local parts={}
  for _,p in ipairs(m:GetDescendants())do
   if p:IsA('BasePart')then
    p.CastShadow=not low
    if p.Name=='RootPart'then p.Transparency=1 else p.LocalTransparencyModifier=1;table.insert(parts,p)end
   end
  end
  local okScale=pcall(function()m:ScaleTo(base*SCALE)end)
  if not okScale then m:Destroy();return nil end
  m.Parent=scope.Folder
  local animator
  pcall(function()animator=AnimationPlayer.new(m,'LongDog')end)
  local r={Model=m,Bones=bones,Animator=animator,Shown=false,Phase=0,Walking=false,S=SCALE}
  -- Tucked bones (template units in the runner's frame) and the legs that trot.
  if role=='Head'then
   r.Tucks={{'Leg.BL',Vector3.new(-.18,.5,0)},{'Leg.BR',Vector3.new(.18,.5,0)},{'Tail',Vector3.new(0,-.32,-.55)}}
   r.Legs={'Leg.FL','Leg.FR'};r.Shins={'Shin.FL','Shin.FR'}
  else
   r.Tucks={{'Chest',Vector3.new(0,-.5,.75)},{'Ear.L',Vector3.new(-.3,-.12,.05)},{'Ear.R',Vector3.new(.3,-.12,.05)},
    {'Leg.FL',Vector3.new(-.18,.5,0)},{'Leg.FR',Vector3.new(.18,.5,0)}}
   r.Legs={'Leg.BL','Leg.BR'};r.Shins={'Shin.BL','Shin.BR'}
  end
  function r.Show(on)
   if on==r.Shown then return end
   r.Shown=on
   for _,p in ipairs(parts)do p.LocalTransparencyModifier=on and 0 or 1 end
  end
  function r.Play(name,looped,fade)
   r.Walking=false
   if animator then pcall(function()animator:Play(name,{Looped=looped==true,FadeTime=fade or .2})end)end
  end
  function r.Walk()
   if r.Walking then return end
   r.Walking=true
   if animator then pcall(function()animator:Play('Walk',{Looped=true,FadeTime=.15})end)end
  end
  function r.Scale(S)
   if math.abs(S-r.S)<1e-3 then return end
   r.S=S
   pcall(function()m:ScaleTo(base*S)end)
  end
  function r.Look(target)
   if animator then animator.Look=target and{Target=target,Body=0,Head=1}or nil end
  end
  -- Pivot at cf, path position s: the clip, then the spine laid along the body, the trot,
  -- and the tucked bones.
  function r.Pose(cf,s,S)
   m:PivotTo(cf)
   if animator and animator.Clip then
    if r.Walking then
     local now=workspace:GetServerTimeNow()
     local blend=1
     if animator.BlendFrom then blend=smooth((now-(animator.BlendStartedAt or now))/math.max(.001,animator.BlendDuration or .001))end
     -- The authored Walk steps backward (DogWalkProfiles: Reverse): play it the other way.
     animator:Sample((1-r.Phase%1)*animator.Clip.Duration,blend)
     if blend>=1 then animator.BlendFrom=nil end
    else
     animator:Step()
    end
   end
   for _,name in ipairs(PIN)do
    local bone=bones[name]
    local parent=bone.Parent
    if parent then
     local R=rest[name]
     local target=frame(s-R.Z*S)*R.Rotation
     local above=parent:IsA('Bone')and parent.TransformedWorldCFrame or(parent::BasePart).CFrame
     bone.Transform=(above*bone.CFrame):Inverse()*target
    end
   end
   if r.Walking then
    for i,list in ipairs({r.Legs,r.Shins})do
     local gain=i==1 and REACH or 1.4
     for _,name in ipairs(list)do
      local bone=bones[name]
      if bone and bone.Parent then
       local t=bone.Transform
       local axis,angle=t:ToAxisAngle()
       bone.Transform=CFrame.new(t.Position)*CFrame.fromAxisAngle(axis,angle*gain)
      end
     end
    end
   end
   for _,tuck in ipairs(r.Tucks)do
    local bone=bones[tuck[1]]
    if bone and bone.Parent then
     bone.Transform*=CFrame.new(bone.TransformedWorldCFrame:VectorToObjectSpace(cf:VectorToWorldSpace(tuck[2]*S)))
    end
   end
  end
  function r.HeadPosition()
   local b=bones.Head
   if b and b.Parent then return b.TransformedWorldCFrame.Position end
   return m:GetPivot().Position
  end
  -- Decode both clips now, not the moment it bursts out.
  if animator then pcall(function()animator:Play('Happy',{FadeTime=0});animator:Play('Walk',{Looped=true,FadeTime=0})end)end
  return r
 end
 local head=build('Head')
 local tail=head and build('Tail')
 if not(head and tail)then
  -- No copy of the dog to run with (MenuModels missing): it simply comes out of the mouth.
  if head then head.Model:Destroy()end
  reveal(T_BURST);ctx:Wait(hold);return
 end
 reveal(T_JOIN)

 ---------------------------------------------------------------- the body
 local SEG=low and 8 or 4
 local BUDGET=low and 6 or 12   -- new segments per frame (a late joiner's body builds up)
 local fur=FUR
 local function stripeOf(c)return c:Lerp(C(46,26,14),.32)end
 local function bellyOf(c)return c:Lerp(C(255,236,206),.45)end
 local body=Instance.new('Folder');body.Name='LongDogBody';body.Parent=scope.Folder
 local function piece(name,shape,color,shadow)
  return scope:Part({Name=name,Shape=shape,Material=Enum.Material.Carpet,Color=color,Transparency=1,CastShadow=shadow,Parent=body})
 end
 local segs={}
 local function make(k)
  local seg={On=false,K=k,Main=piece('LongBody',Enum.PartType.Cylinder,fur,not low)}
  -- A darker stripe down its back and a lighter belly (cylinders poking out of the tube).
  if not low then
   seg.Stripe=piece('LongBack',Enum.PartType.Cylinder,stripeOf(fur),false)
   seg.Belly=piece('LongBelly',Enum.PartType.Cylinder,bellyOf(fur),false)
  end
  segs[k]=seg
  return seg
 end
 local function show(seg,on)
  if seg.On==on then return end
  seg.On=on
  local alpha=on and 0 or 1
  seg.Main.Transparency=alpha
  if seg.Stripe then seg.Stripe.Transparency=alpha end
  if seg.Belly then seg.Belly.Transparency=alpha end
 end
 local function place(seg,a,b,r)
  local pa,pb=center(a),center(b)
  if seg.On and seg.PA and(pa-seg.PA).Magnitude<.01 and(pb-seg.PB).Magnitude<.01 and math.abs(r-seg.R)<.005 then return end
  seg.PA,seg.PB,seg.R=pa,pb,r
  local length=(pb-pa).Magnitude+.5
  local cf=Kit.LookAt((pa+pb)/2,pb)*CFrame.Angles(0,math.pi/2,0)
  seg.Main.Size=Vector3.new(length,r*2,r*2);seg.Main.CFrame=cf
  if seg.Stripe then seg.Stripe.Size=Vector3.new(length,r*1.24,r*1.24);seg.Stripe.CFrame=cf*CFrame.new(0,r*.44,0)end
  if seg.Belly then seg.Belly.Size=Vector3.new(length,r*1.32,r*1.32);seg.Belly.CFrame=cf*CFrame.new(0,-r*.4,0)end
  show(seg,true)
 end
 -- Balls where the body bends hard (the hook) and at each runner's seam.
 local joints={}
 local function ball(name)return piece(name,Enum.PartType.Ball,fur,not low)end
 local capHead,capTail=ball('LongSeamFront'),ball('LongSeamBack')
 local function setBall(p,at,r,on)
  if not on then if p.Transparency<1 then p.Transparency=1 end;return end
  p.Size=Vector3.one*r*2;p.CFrame=CFrame.new(at);p.Transparency=0
 end
 local low0,high0=0,-1
 local function drawBody(rear,front,r,headOn,tailOn)
  local k0,k1=math.floor(rear/SEG),math.floor((front-1e-6)/SEG)
  if front-rear<.2 then k0,k1=0,-1 end
  for k=low0,high0 do
   if(k<k0 or k>k1)and segs[k]then show(segs[k],false)end
  end
  low0,high0=k0,k1
  local made=0
  for k=k0,k1 do
   local a,b=math.max(k*SEG,rear),math.min((k+1)*SEG,front)
   local seg=segs[k]
   if b-a<.15 then
    if seg then show(seg,false)end
   else
    if not seg and made<BUDGET then seg=make(k);made+=1 end
    if seg then place(seg,a,b,r)end
   end
  end
  for k,p in pairs(joints)do
   local s1,s2=segs[k],segs[k+1]
   if not(k>=k0 and k<k1 and s1 and s2 and s1.On and s2.On)then setBall(p,Vector3.zero,r,false)end
  end
  for k=k0,k1-1 do
   local s1,s2=segs[k],segs[k+1]
   if s1 and s2 and s1.On and s2.On then
    local d1,d2=s1.PB-s1.PA,s2.PB-s2.PA
    local bent=d1.Magnitude>1e-3 and d2.Magnitude>1e-3 and d1.Unit:Dot(d2.Unit)<.993
    if bent and not joints[k]then joints[k]=ball('LongJoint')end
    if joints[k]then setBall(joints[k],s1.PB,r,bent)end
   end
  end
  setBall(capHead,center(front),r,headOn and front-rear>.5)
  setBall(capTail,center(rear),r,tailOn and front-rear>.5)
 end
 local function recolor(c)
  fur=c
  for _,seg in pairs(segs)do
   seg.Main.Color=c
   if seg.Stripe then seg.Stripe.Color=stripeOf(c)end
   if seg.Belly then seg.Belly.Color=bellyOf(c)end
  end
  for _,p in pairs(joints)do p.Color=c end
  capHead.Color=c;capTail.Color=c
 end
 task.spawn(function()
  local sampled=sampleFur(head.Model)
  if sampled and scope.Alive then recolor(sampled)end
 end)

 ---------------------------------------------------------------- the stage, the pit, the throat
 -- A dug-up Long Dog went into its owner's pit: it spits dirt as the act starts.
 local pit=model:GetAttribute('ArrivalPit')
 if typeof(pit)=='Vector3'and ctx:Elapsed()<T_BURST then
  local hole=scope:Anchor(pit+Vector3.new(0,.4,0),'ArrivalPit')
  local spit=scope:Emitter(hole,{Color=ColorSequence.new(DIRT),LightEmission=0,LightInfluence=1,Lifetime=NumberRange.new(.6,1.1),
   Speed=NumberRange.new(16,26),SpreadAngle=Vector2.new(22,22),EmissionDirection=Enum.NormalId.Top,Acceleration=Vector3.new(0,-60,0),
   Size=NumberSequence.new(.6,.25),Transparency=NumberSequence.new(0,.2),RotSpeed=NumberRange.new(-200,200),Rate=low and 10 or 30})
  local puff=scope:Emitter(hole,{Texture=Kit.Textures.Smoke,Color=ColorSequence.new(DUST),LightEmission=0,LightInfluence=1,
   Lifetime=NumberRange.new(1,1.8),Speed=NumberRange.new(2,6),SpreadAngle=Vector2.new(40,40),EmissionDirection=Enum.NormalId.Top,
   Size=NumberSequence.new(2.5,6),Transparency=NumberSequence.new(.5,1),Rate=low and 2 or 6})
  if live(0)then Kit.Cue('Impact',hole,.8)end
  local tag=Instance.new('BillboardGui');tag.Name='WentInHere';tag.Size=UDim2.fromOffset(280,54);tag.StudsOffsetWorldSpace=Vector3.new(0,7,0)
  tag.MaxDistance=260;tag.LightInfluence=0;tag.Adornee=hole
  local words=Instance.new('TextLabel');words:SetAttribute('KeepFont',true);words.BackgroundTransparency=1;words.Size=UDim2.fromScale(1,1)
  words.Font=Enum.Font.Kalam;words.TextScaled=true;words.TextColor3=C(255,230,186);words.TextStrokeColor3=C(30,18,8);words.TextStrokeTransparency=.3
  words.Text='it went in here...';words.TextTransparency=1;words.Parent=tag;tag.Parent=hole
  Kit.Tween(words,.4,{TextTransparency=0})
  task.spawn(function()
   if not ctx:Wait(T_BURST+.2)then return end
   spit.Rate=0;puff.Rate=0
   Kit.Tween(words,.8,{TextTransparency=1,TextStrokeTransparency=1})
  end)
 end
 -- The throat: dust pours out of it, the giant mouth rumbles, its runes glow.
 local throatAt=Vector3.new(0,8,FACE+1)
 local throat=scope:Part({Name='Throat',Size=Vector3.new(14,12,1),CFrame=CFrame.lookAt(throatAt,throatAt+Vector3.zAxis),Transparency=1})
 local pour=scope:Emitter(throat,{Texture=Kit.Textures.Smoke,Color=ColorSequence.new(DUST),LightEmission=0,LightInfluence=1,
  Lifetime=NumberRange.new(1.6,2.6),Speed=NumberRange.new(6,16),SpreadAngle=Vector2.new(25,25),EmissionDirection=Enum.NormalId.Front,
  Drag=1.5,Acceleration=Vector3.new(0,1.5,0),Size=NumberSequence.new(4,9),Transparency=NumberSequence.new(.45,1)})
 local POUR=low and 10 or 30
 local rumble
 if ctx:Elapsed()<T_BURST then
  rumble=Kit.Sound(throat,TICK,0,.12,true)
  local eq=Instance.new('EqualizerSoundEffect');eq.LowGain=10;eq.MidGain=-6;eq.HighGain=-40;eq.Parent=rumble
  local grit=Instance.new('DistortionSoundEffect');grit.Level=.6;grit.Parent=rumble
  rumble:Play();Kit.Tween(rumble,1.2,{Volume=.6})
 end
 local tunnel=district and district:FindFirstChild('02_DogFactory')
 tunnel=tunnel and tunnel:FindFirstChild('DarkMouthTunnel')
 local runes={}
 for _,o in ipairs(tunnel and tunnel:GetChildren()or {})do
  if o.Name=='MouthRune'and o:IsA('BasePart')then
   local _,release=scope:Override(o,{Color=SAND,Material=Enum.Material.Neon})
   table.insert(runes,release)
  end
 end
 local mouthCenter=Vector3.new(0,10,-160)

 ---------------------------------------------------------------- every screen
 local sky=scope:Sky({Grade={TintColor=C(255,236,208),Saturation=.12,Contrast=.06},
  Atmosphere={Color=C(236,206,160),Decay=C(196,150,104),Density=.22,Haze=1.6}},2,2.5)
 scope:Duck(.6,1)
 local camera=workspace.CurrentCamera
 local fit=math.clamp((camera and camera.ViewportSize.Y or 720)/720,.62,1.15)
 local function label(parent,font,color,z)
  local l=Instance.new('TextLabel');l:SetAttribute('KeepFont',true)
  l.BackgroundTransparency=1;l.AnchorPoint=Vector2.new(.5,.5);l.Font=font;l.TextColor3=color;l.TextScaled=true;l.ZIndex=z
  l.Parent=parent
  return l
 end
 local function corner(parent,r)local c=Instance.new('UICorner');c.CornerRadius=r;c.Parent=parent end
 -- The alert, as a tape measure unrolling across the screen (it snaps back too).
 local banner=config.Banner or {}
 if ctx:Elapsed()<(banner.At or .15)+1.5 then
  task.spawn(function()
   if not ctx:Wait(banner.At or .15)then return end
   local gui=Instance.new('ScreenGui');gui.Name='DOGROTS_LongDogBanner';gui.ResetOnSpawn=false;gui.IgnoreGuiInset=true
   gui.DisplayOrder=97;gui.ZIndexBehavior=Enum.ZIndexBehavior.Sibling
   local h=math.floor(100*fit)
   local band=Instance.new('Frame');band.Name='Tape';band.AnchorPoint=Vector2.new(0,.5);band.Position=UDim2.new(0,0,.34,0)
   band.Size=UDim2.new(0,0,0,h);band.BackgroundColor3=TAPE;band.BorderSizePixel=0;band.ClipsDescendants=true;band.Parent=gui
   local edge=Instance.new('UIStroke');edge.Color=INK;edge.Thickness=2;edge.Parent=band
   local width=camera and camera.ViewportSize.X or 1920
   local gap=math.max(10,math.floor(24*fit))
   for i=0,math.ceil(width/gap)do
    for _,y in ipairs({0,1})do
     local mark=Instance.new('Frame');mark.BorderSizePixel=0;mark.BackgroundColor3=INK;mark.AnchorPoint=Vector2.new(0,y)
     mark.Position=UDim2.new(0,i*gap+gap,y,0);mark.Size=UDim2.fromOffset(2,i%5==0 and math.floor(h*.24)or math.floor(h*.12));mark.Parent=band
    end
   end
   local kicker=label(band,Enum.Font.GothamBlack,INK,3);kicker.Position=UDim2.fromScale(.5,.27);kicker.Size=UDim2.fromScale(.6,.18)
   kicker.Text=banner.Kicker or '⚠  SOMETHING IS DIGGING  ⚠'
   local title=label(band,Enum.Font.LuckiestGuy,INK,3);title.Position=UDim2.fromScale(.5,.62);title.Size=UDim2.fromScale(.7,.48)
   title.Text=banner.Title or config.Title;title.TextStrokeColor3=C(255,244,214);title.TextStrokeTransparency=.4
   local under=label(gui,Enum.Font.Kalam,C(255,240,214),3);under.Position=UDim2.new(.5,0,.34,math.floor(h*.5+22*fit))
   under.Size=UDim2.new(.7,0,0,math.floor(30*fit));under.TextStrokeColor3=C(30,18,8);under.TextStrokeTransparency=.2;under.Text=banner.Text or '';under.TextTransparency=1
   -- The tape's case, on the left.
   local case=Instance.new('Frame');case.Name='Case';case.AnchorPoint=Vector2.new(0,.5);case.Position=UDim2.new(0,-math.floor(h*.25),.34,0)
   case.Size=UDim2.fromOffset(math.floor(h*1.3),math.floor(h*1.3));case.BackgroundColor3=METAL;case.BorderSizePixel=0;case.ZIndex=4;case.Parent=gui
   corner(case,UDim.new(.24,0))
   local rim=Instance.new('UIStroke');rim.Color=INK;rim.Thickness=3;rim.Parent=case
   local stop=Instance.new('Frame');stop.AnchorPoint=Vector2.new(.5,.5);stop.Position=UDim2.fromScale(.62,.3);stop.Size=UDim2.fromScale(.2,.2)
   stop.BackgroundColor3=C(214,48,40);stop.BorderSizePixel=0;stop.ZIndex=5;stop.Parent=case;corner(stop,UDim.new(.5,0))
   local brand=label(case,Enum.Font.GothamBlack,INK,5);brand.Position=UDim2.fromScale(.6,.68);brand.Size=UDim2.fromScale(.62,.3);brand.Text='LONG\nDOG'
   gui.Parent=player:WaitForChild('PlayerGui')
   local function close()
    if not gui.Parent then return end
    -- Zip: the tape snaps back into its case.
    local zip=Kit.Sound(nil,TICK,.35,2.8,true);zip:Play()
    Kit.Tween(band,.3,{Size=UDim2.new(0,0,0,h)},Enum.EasingStyle.Back,Enum.EasingDirection.In)
    Kit.Tween(under,.25,{TextTransparency=1,TextStrokeTransparency=1})
    Kit.Tween(case,.35,{Position=UDim2.new(0,-math.floor(h*1.6),.34,0)},Enum.EasingStyle.Back,Enum.EasingDirection.In)
    task.delay(.4,function()zip:Destroy();if gui.Parent then gui:Destroy()end end)
   end
   scope:Add(function()if gui.Parent then gui:Destroy()end end)
   Kit.Tween(band,.5,{Size=UDim2.new(1,0,0,h)})
   Kit.Tween(under,.5,{TextTransparency=0})
   if not calm then
    local pop=Instance.new('UIScale');pop.Scale=1.35;pop.Parent=title
    Kit.Tween(pop,.5,{Scale=1},Enum.EasingStyle.Back)
   end
   Kit.Cue('Sting',nil,.9);task.delay(.1,function()Kit.Cue('Impact',nil,.6)end)
   local unroll=Kit.Sound(nil,TICK,.22,1.6,true);unroll:Play()
   task.delay(.5,function()unroll:Destroy()end)
   if ctx:Wait((banner.At or .15)+(banner.Hold or 3.2))then close()end
  end)
 end
 -- LENGTH on a tape measure at the bottom of every screen.
 local tape=Instance.new('ScreenGui');tape.Name='DOGROTS_LongDogLength';tape.ResetOnSpawn=false;tape.IgnoreGuiInset=true;tape.DisplayOrder=95
 tape.ZIndexBehavior=Enum.ZIndexBehavior.Sibling
 local W,H=math.floor(400*fit),math.floor(50*fit)
 local holder=Instance.new('Frame');holder.Name='Holder';holder.AnchorPoint=Vector2.new(.5,1);holder.BackgroundTransparency=1
 holder.Size=UDim2.fromOffset(W,H);holder.Position=UDim2.new(.5,0,1,H*3);holder.Parent=tape
 local strip=Instance.new('Frame');strip.Name='Tape';strip.AnchorPoint=Vector2.new(0,.5);strip.Position=UDim2.new(0,math.floor(H*.6),.5,0)
 strip.Size=UDim2.new(1,-math.floor(H*.6),.82,0);strip.BackgroundColor3=TAPE;strip.BorderSizePixel=0;strip.ClipsDescendants=true;strip.Parent=holder
 corner(strip,UDim.new(0,4))
 local stroke=Instance.new('UIStroke');stroke.Color=INK;stroke.Thickness=2;stroke.Parent=strip
 local ticks=Instance.new('Frame');ticks.Name='Ticks';ticks.BackgroundTransparency=1;ticks.Size=UDim2.new(1,H*2,.3,0);ticks.Parent=strip
 local pitch=math.max(6,math.floor(12*fit))
 for i=0,math.ceil((W+H*2)/pitch)do
  local t=Instance.new('Frame');t.BorderSizePixel=0;t.BackgroundColor3=INK;t.Position=UDim2.new(0,i*pitch,0,0)
  t.Size=UDim2.new(0,2,i%5==0 and 1 or .55,0);t.Parent=ticks
 end
 local readout=label(strip,Enum.Font.RobotoMono,INK,3);readout.Name='Length'
 readout.FontFace=Font.new('rbxasset://fonts/families/RobotoMono.json',Enum.FontWeight.Bold)
 readout.Position=UDim2.fromScale(.5,.64);readout.Size=UDim2.fromScale(.92,.62);readout.Text='LENGTH 0.0 m'
 local case=Instance.new('Frame');case.Name='Case';case.AnchorPoint=Vector2.new(0,.5);case.Position=UDim2.fromScale(0,.5)
 case.Size=UDim2.fromOffset(H,H);case.BackgroundColor3=METAL;case.BorderSizePixel=0;case.ZIndex=4;case.Parent=holder
 corner(case,UDim.new(.24,0))
 local rim=Instance.new('UIStroke');rim.Color=INK;rim.Thickness=2;rim.Parent=case
 local pop=Instance.new('UIScale');pop.Parent=holder
 tape.Parent=player:WaitForChild('PlayerGui')
 scope:Add(tape)
 local shownText=''
 local function say(text)
  if text==shownText then return end
  shownText=text;readout.Text=text
 end
 local tapeOut=false
 local function slide(out)
  if out==tapeOut then return end
  tapeOut=out
  Kit.Tween(holder,out and .4 or .5,{Position=out and UDim2.new(.5,0,1,-math.floor(92*fit))or UDim2.new(.5,0,1,H*3)},
   out and Enum.EasingStyle.Back or Enum.EasingStyle.Quad,out and Enum.EasingDirection.Out or Enum.EasingDirection.In)
 end
 local function bump(scale)
  if calm then return end
  pop.Scale=scale;Kit.Tween(pop,.35,{Scale=1},Enum.EasingStyle.Back)
 end

 ---------------------------------------------------------------- the tongue clears the way
 -- Conveyor dogs and blocks hop aside to the tongue's edges (locally, on top of where the
 -- server holds them; the tongue is frozen) and hop back as the hold ends.
 local aside={}
 local sides=0
 local function clear(m,instant)
  if aside[m]or not m:IsA('Model')or not Kit.Root(m)then return end
  if(m:GetAttribute('ArrivalHoldUntil')or 0)>workspace:GetServerTimeNow()then return end
  if m:GetAttribute('State')~=nil and m:GetAttribute('State')~='OnLine'then return end
  -- Left, right, left...: the tongue parts down the middle.
  sides+=1
  -- (A Secret block's floating shards follow its pivot: LuckyBlockFX places them from it.)
  aside[m]={Side=sides%2==0 and 1 or -1,X=m:GetPivot().Position.X,Instant=instant,Offset=scope:Offset(m)}
 end
 for _,m in ipairs(conveyor and conveyor:GetChildren()or {})do clear(m,ctx:Elapsed()>1.6)end
 if conveyor then
  scope:Add(conveyor.ChildAdded:Connect(function(m)
   task.defer(function()if m.Parent and ctx:Elapsed()<hold-.6 then clear(m,true)end end)
  end))
 end
 scope:Every(function()
  local t=ctx:Elapsed()
  local out=smooth((t-.6)/.9)
  local back=smooth((t-(hold-.1))/.6)
  for m,entry in pairs(aside)do
   if not m.Parent then aside[m]=nil
   else
    local a=entry.Instant and(1-back)or out*(1-back)
    local hop=(t<1.6 and not entry.Instant)and math.sin(math.pi*out)*2.2 or math.sin(math.pi*back)*2.2
    local world=Vector3.new((entry.Side*8-entry.X)*a,hop,0)
    entry.Offset.CFrame=CFrame.new(m:GetPivot():VectorToObjectSpace(world))
   end
  end
 end)

 ---------------------------------------------------------------- the whole island watches
 local headPos=throatAt
 local glance=scope:Glance(function()return headPos end,{Exclude=model,Turn=.5,Ripple=400})
 -- ONE cutaway, mid-run: from the giant mouth, flying up the tongue along the body after the
 -- head as it goes through the end portal and down the boulevard (4.4 s).
 local function zAt(t)return flat(headS(t)).Z end
 ctx:Cutaway({
  {At=7.6,CFrame=Kit.Frame(Vector3.new(24,30,-112),Vector3.new(0,6,zAt(8.4))),Fov=62},
  {At=9.8,CFrame=Kit.Frame(Vector3.new(30,44,zAt(9.8)-95),Vector3.new(0,5,zAt(9.8)+25)),Fov=64,Linear=true},
  {At=12,CFrame=Kit.Frame(Vector3.new(26,36,zAt(12)-60),Vector3.new(0,5,zAt(12)+30)),Fov=66,Linear=true},
 },{Focus=Vector3.new(0,5,zAt(10)),Bars=.08})

 ---------------------------------------------------------------- sound and dust that follow it
 local paws=scope:Part({Name='Paws',Size=Vector3.new(6,1,6),Transparency=1})
 local kick=scope:Emitter(paws,{Texture=Kit.Textures.Smoke,Color=ColorSequence.new(DUST),LightEmission=0,LightInfluence=1,
  Lifetime=NumberRange.new(.8,1.5),Speed=NumberRange.new(2,6),SpreadAngle=Vector2.new(60,60),EmissionDirection=Enum.NormalId.Top,
  Drag=2,Size=NumberSequence.new(2.5,6),Transparency=NumberSequence.new(.45,1)})
 local steps={}
 for i=1,2 do
  local s=Kit.Sound(paws,TICK,.75,.17,false)
  local eq=Instance.new('EqualizerSoundEffect');eq.LowGain=10;eq.MidGain=-4;eq.HighGain=-30;eq.Parent=s
  steps[i]=s
 end
 local ratchet=nil
 local function bark()
  if not head.Shown then return end
  local s=Kit.Shot(paws,TICK,1,.3,{DistortionSoundEffect={Level=.7},EqualizerSoundEffect={LowGain=6,MidGain=3,HighGain=-14}})
  s.RollOffMaxDistance=600
  task.delay(.07,function()Kit.Shot(paws,TICK,.8,.24,{DistortionSoundEffect={Level=.7},EqualizerSoundEffect={LowGain=6,MidGain=3,HighGain=-14}})end)
  local at=scope:Anchor(headPos,'Woof')
  local bb=Instance.new('BillboardGui');bb.Name='Woof';bb.Adornee=at;bb.Size=UDim2.new(0,0,0,0);bb.StudsOffsetWorldSpace=Vector3.new(0,5,0)
  bb.LightInfluence=0;bb.MaxDistance=900
  local w=label(bb,Enum.Font.Bangers,C(255,240,214),1);w.Position=UDim2.fromScale(.5,.5);w.Size=UDim2.fromScale(1,1);w.Text='WOOF!'
  w.TextStrokeColor3=INK;w.TextStrokeTransparency=.1;w.Rotation=Kit.Random(-10,10)
  bb.Parent=at
  Kit.Tween(bb,.25,{Size=UDim2.new(16,0,6,0)},Enum.EasingStyle.Back)
  task.delay(.7,function()if w.Parent then Kit.Tween(w,.4,{TextTransparency=1,TextStrokeTransparency=1})end end)
  task.delay(1.2,function()if at.Parent then at:Destroy()end end)
 end
 local function dust(at,count)
  scope:Burst(at,DUST,count,{Texture=Kit.Textures.Smoke,LightEmission=0,LightInfluence=1,Speed=NumberRange.new(5,12),
   SpreadAngle=Vector2.new(70,70),Drag=3,Lifetime=NumberRange.new(1,1.7),Size=NumberSequence.new(3,7),Transparency=NumberSequence.new(.35,1)})
  scope:Burst(at,DIRT,math.floor(count*1.6),{LightEmission=0,LightInfluence=1,Speed=NumberRange.new(14,26),SpreadAngle=Vector2.new(40,40),
   Acceleration=Vector3.new(0,-60,0),Lifetime=NumberRange.new(.6,1.1),Size=NumberSequence.new(.6,.25),RotSpeed=NumberRange.new(-200,200)})
 end

 ---------------------------------------------------------------- every frame
 local lastT=ctx:Elapsed()
 local lastShake=0
 local lastH=headS(lastT)
 local lastStep=0
 local portalPassed=headS(lastT)>136.5-THROAT
 local snapDust=math.huge
 local looked=false
 scope:Every(function()
  local t=ctx:Elapsed()
  local dt=math.clamp(t-lastT,0,.1);lastT=t
  if t>=T_JOIN then
   head.Show(false);tail.Show(false)
   drawBody(0,0,0,false,false)
   kick.Rate=0
   return false
  end
  local S=scaleAt(t)
  local sH=headS(t)
  local sT=tailS(t)
  local speed=dt>0 and(sH-lastH)/dt or 0
  lastH=sH
  pose.S=S;pose.H=sH;pose.T=sT
  -- The head: out of the throat, a trot, a look back, then dragged home.
  local headOn=t>=T_BURST
  head.Show(headOn)
  if headOn then
   head.Scale(S)
   if t<T_STOP or t>=T_TENSE then
    head.Walk()
    if t<T_STOP then head.Phase+=math.min(math.abs(sH-(head.LastS or sH))/(STRIDE*REACH*S),MAXHZ*dt)
    else head.Phase+=(t<T_YANK and 4.5 or 6)*dt end
    head.Look(nil)
   elseif not looked then
    looked=true
    head.Play('Happy',false,.25)
    -- Back down its own body, at the giant mouth.
    head.Look(Vector3.new(0,12,-170))
   end
   head.LastS=sH
   local bounce=0
   if t<T_RUN then bounce=math.sin(math.pi*math.clamp((t-T_BURST)/(T_RUN-T_BURST),0,1))*3*S/SCALE
   elseif t<T_STOP then bounce=math.abs(math.sin(2*math.pi*head.Phase))*.6*math.clamp(math.abs(speed)/25,0,1)*S/SCALE end
   pose.HeadLift=bounce
   head.Pose(pivotAt(sH,bounce,S),sH,S)
   headPos=head.HeadPosition()
   paws.CFrame=CFrame.new(pivotAt(sH,0,S).Position)
   kick.Rate=(t<T_STOP and math.abs(speed)>4)and(low and 8 or 24)or 0
   -- A paw lands: a thump near it.
   local beat=math.floor(head.Phase*2)
   if t<T_STOP and beat~=lastStep then
    lastStep=beat
    local s=steps[beat%2+1]
    if s then s.PlaybackSpeed=.15+Kit.Random(0,.04);s:Play()end
   end
  end
  -- The tail: out of the throat at last.
  local tailOn=sT~=nil
  tail.Show(tailOn)
  if tailOn and sT then
   tail.Scale(S)
   if t>=T_TENSE then tail.Walk();tail.Phase+=4*dt end
   local hop=t<T_POP+.45 and math.sin(math.pi*math.clamp((t-T_POP)/.45,0,1))*2.6*S/SCALE or 0
   pose.TailLift=hop
   tail.Pose(pivotAt(sT,hop,S),sT,S)
  else
   pose.TailLift=0
  end
  -- The body: from the tail's seam (or inside the throat) to the head's seam.
  local front=sH-SEAM*S
  local rear=sT and(sT-SEAM*S)or 0
  drawBody(rear,front,TUBE*S,headOn,tailOn)
  -- LENGTH.
  if t>=T_BURST+.1 then slide(t<T_JOIN+1.5)end
  local nose=sH+NOSE*S
  local back=sT and(sT-TAILTIP*S)or(FACE-THROAT)
  local length=math.max(0,nose-back)*M_PER_STUD
  if not sT then say(string.format('LENGTH %.1f m%s',length,(t%.6<.3)and' +'or'  '))
  else say(string.format('LENGTH %.1f m',length))end
  ticks.Position=UDim2.new(0,-((length*40)%(pitch*5)),0,0)
  -- Players near it feel it go by (and fly back).
  if not calm and headOn then
   local near=Kit.Near(headPos,85)
   if near>.08 and os.clock()-lastShake>.3 and(t<T_STOP or t>=T_YANK)then
    lastShake=os.clock();Kit.Shake(.05+.28*near,.4)
   end
  end
  if not portalPassed and sH>136.5-THROAT then
   portalPassed=true
   if live(t)then
    scope:Burst(Vector3.new(0,9,136.5),SAND,40,{Speed=NumberRange.new(8,20),Lifetime=NumberRange.new(.6,1.2),Size=NumberSequence.new(1.2,0)})
    Kit.Cue('Whoosh',paws,.6)
   end
  end
  -- The snap leaves dust down the whole route.
  if t>=T_YANK and t<T_SETTLE and sH<snapDust-(low and 80 or 40)then
   snapDust=sH
   dust(center(sH)+Vector3.new(0,-1,0),low and 6 or 14)
  end
  if ratchet then ratchet.PlaybackSpeed=.35+.9*math.clamp((t-T_RUN)/(T_STOP-T_RUN),0,1)end
  return true
 end)

 ---------------------------------------------------------------- the beats
 -- 0: something is digging. The giant mouth rumbles; dust pours out of its throat.
 if live(0)then
  Kit.Cue('Heartbeat',nil,.7);task.delay(.9,function()Kit.Cue('Heartbeat',nil,.8)end)
  if Kit.Near(mouthCenter,260)>.05 then Kit.Shake(.06+.18*Kit.Near(mouthCenter,260),1.8)end
 end
 task.spawn(function()
  local born=os.clock()
  while scope.Alive and ctx:Elapsed()<T_BURST do
   pour.Rate=POUR*smooth(ctx:Elapsed()/T_BURST)
   task.wait(.1)
   if os.clock()-born>4 then break end
  end
 end)
 -- 2: it bursts out of the throat.
 if not ctx:Wait(T_BURST)then return end
 if rumble then Kit.Tween(rumble,.8,{Volume=0})end
 if live(T_BURST)then
  dust(throatAt+Vector3.new(0,-4,3),low and 10 or 26)
  Kit.Cue('Impact',throat,1);Kit.Cue('Whoosh',nil,.5)
  local near=Kit.Near(mouthCenter,200)
  if near>.05 then Kit.Shake(.1+.3*near,.6);if near>.3 then Kit.FOVPunch(-6,.12,.5)end end
 end
 pour.Rate=POUR*.4
 if ctx:Elapsed()<T_STOP-.5 then
  -- A tape measure winding out, for as long as it keeps coming.
  local s=Kit.Sound(nil,TICK,.12,.35,true)
  local eq=Instance.new('EqualizerSoundEffect');eq.LowGain=4;eq.MidGain=0;eq.HighGain=-12;eq.Parent=s
  s:Play();ratchet=s
  scope:Add(s)
 end
 if not ctx:Wait(3.6)then return end
 pour.Rate=0
 for _,release in ipairs(runes)do release()end

 -- 16.5: at the spawn plaza. It looks back down its body and barks.
 if not ctx:Wait(T_STOP)then return end
 if ratchet then ratchet:Destroy();ratchet=nil end
 if live(T_STOP)then bump(1.3)end
 if ctx:Wait(T_STOP+.4)and live(T_STOP+.4)then bark()end
 if ctx:Wait(T_STOP+1.05)and live(T_STOP+1.05)then bark()end

 -- 18.5: the tail. Finally.
 if not ctx:Wait(T_POP)then return end
 if live(T_POP)then
  dust(throatAt+Vector3.new(0,-4,3),low and 8 or 20)
  pour.Rate=POUR*.6
  Kit.Cue('Sting',nil,.7)
  Kit.Shot(nil,TICK,.55,2.2)
  bump(1.4)
 end
 -- It wags.
 tail.Play('Happy',false,.1)
 if not ctx:Wait(T_POP+1)then return end
 pour.Rate=0

 -- 19.5: the tape measure catches, and lets go.
 if not ctx:Wait(T_TENSE)then return end
 if live(T_TENSE)then
  local s=Kit.Sound(nil,TICK,.35,.4,true)
  local flange=Instance.new('FlangeSoundEffect');flange.Depth=.6;flange.Mix=.85;flange.Rate=8;flange.Parent=s
  s:Play()
  Kit.Tween(s,T_JOIN-T_TENSE,{PlaybackSpeed=3.2},Enum.EasingStyle.Quad,Enum.EasingDirection.In)
  task.delay(T_JOIN-T_TENSE,function()if s.Parent then s:Destroy()end end)
 end
 if not ctx:Wait(T_YANK)then return end
 if live(T_YANK)then Kit.Cue('Whoosh',nil,.7);bump(1.2)end
 if not ctx:Wait(T_SETTLE)then return end
 pour.Rate=POUR*.8
 if live(T_SETTLE)then dust(throatAt+Vector3.new(0,-4,3),low and 8 or 18)end

 -- 22: SNAP. One perfectly normal Long Dog (reveal shows it).
 if not ctx:Wait(T_JOIN)then return end
 pour.Rate=0
 glance:Stop(1.2)
 say('LENGTH 1 dog')
 if live(T_JOIN)then
  bump(1.5)
  local near=Kit.Near(origin,160)
  if near>.05 then Kit.Shake(.2*near,.4)end
 end
 -- The runners and the body are done with.
 task.delay(.2,function()
  if head.Model.Parent then head.Model:Destroy()end
  if tail.Model.Parent then tail.Model:Destroy()end
  if body.Parent then body:Destroy()end
 end)
 if not ctx:Wait(T_JOIN+1.6)then return end
 slide(false)
 -- The dust settles before the hold ends; the tongue's dogs hop back as it starts moving
 -- again (the scope lasts until the display dog has gone, so they are not snapped back).
 if not ctx:Wait(hold-2)then return end
 sky:Release(2)
 ctx:Wait(hold+.6)
end
