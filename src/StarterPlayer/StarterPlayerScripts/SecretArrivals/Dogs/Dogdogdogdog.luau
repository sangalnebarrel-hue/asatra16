-- DOGDOGDOGDOG, "ROLL CALL": the whole island gets counted. Wherever a player stands:
--  0     the sky turns gold; a giant DOGDOGDOGDOG rises in their sky between eight empty
--        slots (it hangs wherever they look, a little above the middle of the view).
--  1.4   it comes apart where it landed (the tongue, or a Lucky pad in open air): the big
--        dog drops through the floor and eight pups scatter onto eight marks. The giant in
--        every sky falls apart the same way, and eight little pups pop out around every
--        player and sprint laps around them.
--  3.0   the roll call, in step with the typed "dog dog dog...": a number over each pup on
--        the stage, a giant number in each slot of every sky, and the matching pup around
--        every player hops (up a major scale everyone hears).
--  5.6   reassemble: leashes reel the stage pups in, the pups around every player leap into
--        the sky toward the giant, and the giant pulls itself back together.
--  6.8   one dog: the eight numbers fold into a single "1" (on the stage and in every sky),
--        DOGDOGDOGDOG crosses every screen, gold confetti falls around every player and a
--        gold ring sweeps the whole district.
--  ~9    "now there are eight.": for a blink all eight are back, on the stage and in the sky.
-- SecretArrivalConfig.Dogs.Dogdogdogdog must agree with T: Hold 10, Split at T.Split,
-- Reassemble at T.Reassemble, Happy at T.Happy. Its first whisper is the roll call (the
-- numbers follow its typing, TYPE a character, as WhisperStyle types it) and the blink
-- lands on the last word of its last whisper.
local Players=game:GetService('Players')
local Lighting=game:GetService('Lighting')
local RS=game:GetService('ReplicatedStorage')
local SoundService=game:GetService('SoundService')
local AnimationPlayer=require(RS:WaitForChild('DogAnimationPlayer'))
local C=Color3.fromRGB
local GOLD,DEEP,CREAM,WHITE=C(255,196,64),C(222,128,16),C(255,226,150),C(255,255,255)
local TICK='rbxasset://sounds/volume_slider.ogg'
local FLAT=CFrame.Angles(0,0,math.pi/2)
-- One note per pup: a major scale up to the octave.
local SCALE={1,9/8,5/4,4/3,3/2,5/3,15/8,2}
-- Typewriter speed: "dog " is four characters, so one pup is called per typed word.
local TYPE=.07
-- The act on the arrival clock. The stage act is the one it always had, T.Split later.
local T={Split=1.4,Pups=1.5,Marks=2.6,Reassemble=5.6,Close=6.0,Dim=6.4,One=6.8,Happy=7.7}
-- In every player's own sky: the giant (studs tall, studs away, turned three-quarters to
-- them) and the row of numbers (studs away, studs tall; degrees left of the giant, 1 to 8).
local GIANT,GIANT_AT,GIANT_TURN=120,560,math.rad(28)
local ROW_AT,ROW_H=330,34
local ROW={28,23,18,12.5,-12.5,-18,-23,-28}
-- It all hangs this far above the middle of the view (a default third-person camera looks
-- ~15 degrees down and sees 35 up), never lower than MIN_UP over the horizon.
local LIFT,MIN_UP,MAX_UP=math.rad(21),math.rad(7),math.rad(45)
-- The pups around each player: studs tall, lap radius, run speed (studs/s), spacing.
local PUP_H,LAP_R,LAP_V,LAP_GAP=2.6,11,26,4.2
local function smooth(x)x=math.clamp(x,0,1);return x*x*(3-2*x)end
-- 0..1 with an overshoot that settles: a pop.
local function backOut(x)x=math.clamp(x,0,1)-1;return 1+2.70158*x*x*x+1.70158*x*x end

-- A big cartoon number; KeepFont before parenting or PlaceTypography swaps the face.
local function number(parent:Instance,text:string,thickness:number)
 local l=Instance.new('TextLabel');l.Name='Number';l:SetAttribute('KeepFont',true)
 l.BackgroundTransparency=1;l.AnchorPoint=Vector2.new(.5,.5);l.Position=UDim2.fromScale(.5,.5);l.Size=UDim2.fromScale(0,0)
 l.Font=Enum.Font.LuckiestGuy;l.Text=text;l.TextScaled=true;l.TextColor3=WHITE;l.TextStrokeTransparency=1
 local s=Instance.new('UIStroke');s.Color=DEEP;s.Thickness=thickness;s.LineJoinMode=Enum.LineJoinMode.Round;s.Parent=l
 l.Parent=parent
 return l,s
end
-- The stage's numbers: in the world (no longer drawn through walls), readable from the yards.
local function billboard(adornee:BasePart,size:UDim2,lift:number)
 local g=Instance.new('BillboardGui');g.Name='RollCall';g.Adornee=adornee;g.AlwaysOnTop=false;g.LightInfluence=0
 g.MaxDistance=220;g.Size=size;g.StudsOffsetWorldSpace=Vector3.new(0,lift,0)
 return g
end
-- A number in the sky: studs across, drawn over everything (it is the sky).
local function skyNumber(adornee:BasePart,studs:number,text:string)
 local g=Instance.new('BillboardGui');g.Name='RollCallSky';g.Adornee=adornee;g.AlwaysOnTop=true;g.LightInfluence=0
 g.Size=UDim2.new(studs,0,studs,0)
 local l,s=number(g,text,5)
 l.TextTransparency=1;s.Transparency=1
 local shade=Instance.new('UIGradient');shade.Rotation=90
 shade.Color=ColorSequence.new(WHITE,CREAM);shade.Parent=l
 g.Parent=adornee
 return g,l,s
end
local function spread(o:{BasePart},alpha:number)for _,p in ipairs(o)do p.LocalTransparencyModifier=alpha end end

return function(ctx)
 ctx.ManualBanner=true
 ctx.WhisperStyle={Font=Enum.Font.PermanentMarker,Color=CREAM,Type=TYPE,Glitch=.025}
 local Kit,scope,model,config=ctx.Kit,ctx.Scope,ctx.Model,ctx.Config
 local low,calm,origin,hold=ctx.Low,Kit.ReducedMotion(),ctx.Origin,config.Hold
 local size=Kit.Size(model)
 local lines=config.Whispers or {}
 local call=lines[1]and lines[1][1]or 3
 local tail=lines[#lines]
 local typed=tail and tail[1]+(utf8.len(tail[2])or #tail[2])*TYPE or hold
 -- The pups are called one per typed "dog"; the blink lands on the last typed word.
 local calls={}
 for i=1,8 do calls[i]=call+(4*i-1)*TYPE end
 local blink=math.min(typed-.25,hold-.6)
 local wrap=blink+.45
 local fresh=ctx.Late<.3
 local joined=ctx:Elapsed()
 -- Off the tongue (a yard pad): no mouth props around, and no flat belt underfoot.
 local open=(ctx.Venue or 'Tongue')~='Tongue'
 local player=Players.LocalPlayer
 local function near()return Kit.Near(origin,120)end
 -- Was this beat on time? (late joiners get the state, not the fanfare)
 local function live(t)return ctx:Elapsed()-t<.35 end
 local function pip(speed,volume)
  if not scope.Alive then return end
  local s=Instance.new('Sound');s.SoundId=TICK;s.Volume=volume;s.PlaybackSpeed=speed
  local r=Instance.new('ReverbSoundEffect');r.DecayTime=1.2;r.WetLevel=-5;r.DryLevel=0;r.Parent=s
  s.Parent=SoundService;scope:Add(s);s:Play()
  task.delay(3,function()if s.Parent then s:Destroy()end end)
 end

 ---------------------------------------------------------------- the island turns gold
 -- Golden hour (whichever is nearer on the dial), a warm haze and gold clouds, for everyone.
 local clock=Lighting.ClockTime
 local function apart(a:number,b:number):number return math.abs(((a-b+12)%24)-12)end
 local SKY={Lighting={ClockTime=apart(clock,17.3)<=apart(clock,6.7)and 17.3 or 6.7,Brightness=2.8,ExposureCompensation=.18,
   Ambient=C(150,112,62),OutdoorAmbient=C(196,146,84),ColorShift_Top=C(255,196,110)},
  Atmosphere={Density=.34,Offset=.2,Color=C(255,200,120),Decay=C(255,138,48),Glare=1.4,Haze=1.8},
  Clouds={Cover=.5,Density=.3,Color=C(255,218,160)},
  Grade={TintColor=C(255,238,206),Saturation=.16,Contrast=.06},
  Bloom={Intensity=.6,Size=34,Threshold=1.15}}
 local sky=joined<wrap and scope:Sky(SKY,fresh and 1.4 or .4,1.6)or nil
 -- The mouth runes (only when it arrives in the mouth, not on a yard pad) warm up; the
 -- music steps back for the count.
 local district=workspace:FindFirstChild('DOGROTS_District')
 local factory=district and district:FindFirstChild('02_DogFactory')
 local tunnel=factory and factory:FindFirstChild('DarkMouthTunnel')
 if tunnel and not open then
  for _,rune in ipairs(tunnel:GetDescendants())do
   if rune.Name=='MouthRune'and rune:IsA('BasePart')then scope:Override(rune,{Color=GOLD})end
  end
 end
 local grade=scope:Grade({Saturation=.06,Contrast=.05},fresh and .8 or .3)
 scope:Duck(.45,.8)
 -- The district-wide ring reaches the farthest corner of the island.
 local span=0
 for _,x in ipairs({Kit.Map.Min.X,Kit.Map.Max.X})do
  for _,z in ipairs({Kit.Map.Min.Z,Kit.Map.Max.Z})do span=math.max(span,Vector3.new(x-origin.X,0,z-origin.Z).Magnitude)end
 end
 local WAVE=math.clamp(span+60,300,1000)

 ---------------------------------------------------------------- the stage
 -- Eight pups: an anchor that rides each pup's head bone, with its spark, light,
 -- leash end and number. Bones stream in late; until then the anchors wait on a ring.
 local stage:{any}={}
 for i=1,8 do
  local angle=(i-.5)/8*math.pi*2
  local a=scope:Anchor(origin+Vector3.new(math.cos(angle)*3.5,2,math.sin(angle)*3.5),'Pup'..i)
  local att=Instance.new('Attachment');att.Parent=a
  local spark=scope:Emitter(a,{Color=ColorSequence.new(GOLD),Lifetime=NumberRange.new(.4,.8),Speed=NumberRange.new(4,9),
   Size=NumberSequence.new(.45,0),Acceleration=Vector3.new(0,-14,0)})
  local gui=billboard(a,UDim2.new(1.6,26,1.6,26),1.4);gui.Enabled=false
  local label,stroke=number(gui,tostring(i),3)
  gui.Parent=a
  stage[i]={Anchor=a,Attachment=att,Spark=spark,Light=not low and scope:Light(a,GOLD,10,0)or nil,Gui=gui,Label=label,
   Stroke=stroke,Bone=nil,Name=string.format('pup_%02d_head',i),Mark=nil}
 end
 local top=scope:Anchor(origin+Vector3.new(0,size.Y,0),'Top')
 local glints=scope:Emitter(top,{Color=ColorSequence.new(CREAM),Lifetime=NumberRange.new(.6,1.1),Speed=NumberRange.new(2,5),
  Size=NumberSequence.new(.35,0),Acceleration=Vector3.new(0,-6,0)})
 local lookup=0
 scope:Every(function()
  local now=os.clock()
  local search=now>=lookup
  if search then lookup=now+.5 end
  for _,p in ipairs(stage)do
   if search and not(p.Bone and p.Bone.Parent)then
    local found=model:FindFirstChild(p.Name,true)
    p.Bone=found and found:IsA('Bone')and found or nil
   end
   if p.Bone and p.Bone.Parent then
    local at=(p.Bone::Bone).TransformedWorldCFrame.Position
    p.Anchor.CFrame=CFrame.new(at)
    if p.Mark and p.Mark.Parent then p.Mark.CFrame=CFrame.new(at.X,origin.Y+.06,at.Z)*FLAT end
   end
  end
  if model.Parent then top.CFrame=CFrame.new(ctx:Ground()+Vector3.new(0,size.Y,0))end
 end)
 -- Gold flakes thrown up from `from`, fluttering down to the ground (found once per flake
 -- in open air, where the floor is not flat).
 local function confetti(from:Vector3,count:number,floor:number,probe:RaycastParams?,reach:number)
  local bits={}
  for i=1,count do
   local angle,speed=Kit.Random(0,math.pi*2),Kit.Random(6,14)*reach
   bits[i]={Part=scope:Part({Name='Confetti',Color=i%5<2 and WHITE or (i%2==0 and GOLD or CREAM),Size=Vector3.new(.34,.04,.2),
    Transparency=.05,CFrame=CFrame.new(from)}),Pos=from,Vel=Vector3.new(math.cos(angle)*speed,Kit.Random(16,27),math.sin(angle)*speed),
    Spin=Vector3.new(Kit.Random(-9,9),Kit.Random(-9,9),Kit.Random(-9,9)),Phase=Kit.Random(0,6)}
  end
  scope:Every(function(dt,age)
   dt=math.min(dt,.05)
   local fade=math.clamp((age-1.7)/.7,0,1)
   for _,b in ipairs(bits)do
    local v=b.Vel
    v=Vector3.new(v.X*(1-1.8*dt),math.max(v.Y-44*dt,-7),v.Z*(1-1.8*dt));b.Vel=v
    local sway=v.Y<0 and math.sin(age*6+b.Phase)*2.2 or 0
    local pos=b.Pos+(v+Vector3.new(sway,0,sway*.6))*dt
    if probe and not b.Floor and v.Y<0 and pos.Y<floor+1.5 then
     local hit=workspace:Raycast(pos+Vector3.new(0,.5,0),Vector3.new(0,-8,0),probe)
     b.Floor=hit and hit.Position.Y+.06 or floor-8
    end
    local ground=b.Floor or floor
    if pos.Y<ground then pos=Vector3.new(pos.X,ground,pos.Z);b.Vel=Vector3.zero end
    b.Pos=pos
    b.Part.CFrame=CFrame.new(pos)*CFrame.fromEulerAnglesXYZ(age*b.Spin.X+b.Phase,age*b.Spin.Y,age*b.Spin.Z)
    b.Part.Transparency=.05+.95*fade
   end
   if age>=2.4 then for _,b in ipairs(bits)do b.Part:Destroy()end;return false end
   return true
  end)
 end

 ---------------------------------------------------------------- every player's sky
 -- This player's view, eased: the giant and its numbers hang ahead of wherever they look.
 local yaw,up=0,0
 local eye=Vector3.zero
 local tracked=false
 local function track(dt:number):boolean
  local cam=workspace.CurrentCamera
  if not cam then return false end
  local cf=cam.CFrame
  eye=cf.Position
  local l=cf.LookVector
  local wantUp=math.clamp(math.asin(math.clamp(l.Y,-1,1))+LIFT,MIN_UP,MAX_UP)
  local wantYaw=(l.X*l.X+l.Z*l.Z)>.0025 and math.atan2(-l.X,-l.Z)or yaw
  if not tracked then tracked=true;yaw,up=wantYaw,wantUp
  else
   local k=1-math.exp(-math.min(dt,.1)*2.4)
   yaw+=(((wantYaw-yaw+math.pi)%(2*math.pi))-math.pi)*k
   up+=(wantUp-up)*k
  end
  return true
 end
 local function ahead(dYaw:number,dUp:number,distance:number):Vector3
  return eye+CFrame.fromEulerAnglesYXZ(up+dUp,yaw+dYaw,0).LookVector*distance
 end
 local function giantFrame():CFrame
  local at=ahead(0,0,GIANT_AT)
  return CFrame.lookAt(at,Vector3.new(eye.X,at.Y,eye.Z))*CFrame.Angles(0,GIANT_TURN,0)
 end
 -- Eight empty slots ("?"), then numbers, either side of the giant; one "1" in front of it.
 local row={}
 for i=1,8 do
  local a=scope:Anchor(origin,'SkyCount'..i)
  local _,label,stroke=skyNumber(a,ROW_H,'?')
  row[i]={Anchor=a,Label=label,Stroke=stroke,Digit=tostring(i),Text='?',Bob=i*.9}
 end
 local oneAt=scope:Anchor(origin,'SkyOne')
 local _,oneLabel,oneStroke=skyNumber(oneAt,ROW_H*2.4,'1')
 local giant,rim=nil,nil
 local giantPhase=nil
 -- The giant's clips run on the server clock, like the dog's own, so a late joiner sees
 -- the frame everyone else sees.
 local function giantPlay(key:string,clip:string,startAt:number,looped:boolean,fade:number)
  if giantPhase==key then return end
  giantPhase=key
  local anim=giant and giant.Animator
  if anim then pcall(function()anim:Play(clip,{StartTime=startAt,FadeTime=fade,Looped=looped})end)end
 end
 -- The blink: "now there are eight" (one steady blink with reduced motion).
 local function split(el:number):boolean
  local u=el-blink
  if u<0 or u>=.37 then return false end
  return calm or u<.08 or u>=.15
 end

 ---------------------------------------------------------------- the pups around you
 -- Eight little copies of it, built a frame apart before they pop out around this player.
 local mine={}
 local character:Model?=nil
 local probe=RaycastParams.new();probe.FilterType=Enum.RaycastFilterType.Exclude;probe.RespectCanCollide=true
 local function refilter()
  character=player.Character
  probe.FilterDescendantsInstances=character and {scope.Folder,character}or {scope.Folder}
 end
 refilter()
 if joined<T.Reassemble-.6 then
  task.spawn(function()
   for i=1,8 do
    if not scope.Alive then return end
    local m=Kit.DogCopy('Dogdogdogdog',model)
    if m then
     scope:Add(m)
     local _,box=Kit.Bounds(m)
     pcall(function()m:ScaleTo(m:GetScale()*PUP_H/math.max(box.Y,.1))end)
     m.Name='Pup'..i
     local parts={}
     for _,p in ipairs(m:GetDescendants())do
      if p:IsA('BasePart')and p.Name~='RootPart'then p.LocalTransparencyModifier=1;table.insert(parts,p)end
     end
     local pup={Model=m,Parts=parts,Alpha=1,State='Waiting'}
     local root=m.PrimaryPart
     if root then
      -- Its number once it is called, and the streak it leaves when it leaps.
      local tag=Instance.new('BillboardGui');tag.Name='PupNumber';tag.Adornee=root;tag.AlwaysOnTop=true;tag.LightInfluence=0
      tag.MaxDistance=150;tag.Size=UDim2.new(1.4,12,1.4,12);tag.StudsOffsetWorldSpace=Vector3.new(0,PUP_H+1,0);tag.Enabled=false
      local label=number(tag,tostring(i),2);label.Size=UDim2.fromScale(1,1)
      tag.Parent=root;pup.Tag=tag
      if not low then
       local a0=Instance.new('Attachment');a0.Position=Vector3.new(0,PUP_H*.75,0);a0.Parent=root
       local a1=Instance.new('Attachment');a1.Position=Vector3.new(0,PUP_H*.2,0);a1.Parent=root
       local trail=Instance.new('Trail');trail.Attachment0=a0;trail.Attachment1=a1;trail.Color=ColorSequence.new(CREAM,GOLD)
       trail.LightEmission=1;trail.Lifetime=.35;trail.FaceCamera=true;trail.Enabled=false
       trail.Transparency=NumberSequence.new(.1,1);trail.WidthScale=NumberSequence.new(1,0);trail.Parent=root
       pup.Trail=trail
      end
     end
     pcall(function()
      local anim=AnimationPlayer.new(m,'Dogdogdogdog')
      -- A sprint, each a little out of step with the next.
      anim:Play('Run',{Looped=true,Speed=1.7,StartTime=ctx.Start-(i-1)*.29})
      pup.Anim=anim
     end)
     mine[i]=pup
    end
    task.wait()
   end
  end)
 end
 local centre:Vector3?=nil
 local spin:number?=nil
 local frame=0
 local function runPups(dt:number,el:number)
  frame+=1
  if player.Character~=character then refilter()end
  local root=character and character:FindFirstChild('HumanoidRootPart')
  local feet
  if root and root:IsA('BasePart')then
   local hit=workspace:Raycast(root.Position,Vector3.new(0,-12,0),probe)
   feet=hit and hit.Position or root.Position-Vector3.new(0,3,0)
  else feet=Kit.Me()end
  centre=centre and centre:Lerp(feet,1-math.exp(-math.min(dt,.1)*7))or feet
  local c=centre::Vector3
  -- Pup 1 comes out in front of the camera; the rest trail it round the lap.
  if not spin then spin=math.atan2(-math.cos(yaw),-math.sin(yaw))end
  local w=LAP_V/LAP_R
  local left=false
  for k=1,8 do
   local pup=mine[k]
   if pup and pup.State~='Gone'then
    left=true
    local m=pup.Model
    local popAt=T.Pups+(k-1)*.07
    local leapAt=T.Reassemble+(k-1)*.05
    if pup.State=='Waiting'and el>=popAt then
     if el>=leapAt then pup.State='Gone';m:Destroy();continue end
     pup.State='Run';pup.Born=el;m.Parent=scope.Folder
     if live(popAt)then pup.Pop=true end
    end
    if pup.State=='Run'then
     local phi=(spin::number)-(k-1)*LAP_GAP/LAP_R+w*math.max(el-T.Pups,0)
     local x,z=c.X+math.cos(phi)*LAP_R,c.Z+math.sin(phi)*LAP_R
     -- The ground under it (a ray every third frame each, eased over steps and kerbs).
     if not pup.Y or (frame+k)%3==0 then
      local hit=workspace:Raycast(Vector3.new(x,c.Y+6,z),Vector3.new(0,-16,0),probe)
      local y=hit and hit.Position.Y or c.Y
      pup.Y=pup.Y and pup.Y+(y-pup.Y)*.5 or y
     end
     local hopT=el-calls[k]
     local hop=(hopT>=0 and hopT<.4)and math.sin(hopT/.4*math.pi)*2.2 or 0
     local drop=(1-smooth((el-pup.Born)/.2))*1.5
     local at=Vector3.new(x,pup.Y+hop+drop,z)
     local dir=Vector3.new(-math.sin(phi),0,math.cos(phi))
     if pup.Pop then
      pup.Pop=nil
      scope:Burst(at+Vector3.new(0,.8,0),GOLD,10,{Speed=NumberRange.new(4,9),Lifetime=NumberRange.new(.3,.6),Size=NumberSequence.new(.4,0)})
      pip(2.4+k*.1,.1)
     end
     if pup.Tag then pup.Tag.Enabled=hopT>=0 end
     if el>=leapAt then
      pup.State='Leap';pup.From=at;pup.Last=at;pup.Dir=dir;pup.LeapAt=leapAt
      if pup.Tag then pup.Tag.Enabled=false end
      if pup.Trail then pup.Trail.Enabled=true elseif live(leapAt)then
       scope:Burst(at+Vector3.new(0,1,0),CREAM,8,{Speed=NumberRange.new(3,7),Lifetime=NumberRange.new(.3,.5),Size=NumberSequence.new(.4,0)})
      end
     else
      m:PivotTo(CFrame.lookAt(at,at+dir))
      local alpha=1-smooth((el-pup.Born)/.15)
      if alpha~=pup.Alpha then pup.Alpha=alpha;spread(pup.Parts,alpha)end
     end
    end
    if pup.State=='Leap'then
     -- Up and away into the sky, straight for the giant, gone in a gold streak.
     local u=math.clamp((el-pup.LeapAt)/.75,0,1)
     local from=pup.From::Vector3
     local hump=from+Vector3.new(0,26,0)+(pup.Dir::Vector3)*8
     local goal=ahead(0,0,GIANT_AT)
     local s=u^1.6
     local p=from*(1-s)^2+hump*(2*s*(1-s))+goal*(s*s)
     local v=p-(pup.Last::Vector3)
     pup.Last=p
     m:PivotTo(v.Magnitude>1e-3 and CFrame.lookAt(p,p+v)or CFrame.new(p))
     local alpha=smooth((u-.5)/.5)
     if alpha~=pup.Alpha then pup.Alpha=alpha;spread(pup.Parts,alpha)end
     if u>=1 then pup.State='Gone';m:Destroy()end
    end
    -- Phones step their pups every other frame.
    if pup.Anim and pup.State~='Gone'and(not low or (frame+k)%2==0)then pcall(pup.Anim.Step,pup.Anim)end
   end
  end
  return left or el<=T.Reassemble
 end
 -- Their own step (a hiccup in one cannot stop the sky), until all have leapt.
 scope:Every(function(dt)
  if not tracked or not next(mine)then return true end
  return runPups(dt,ctx:Elapsed())
 end)

 ---------------------------------------------------------------- one step, every frame
 local ringAt:number?=nil
 local passed=false
 scope:Every(function(dt)
  if not track(dt)then return true end
  local el=ctx:Elapsed()
  -- The giant rises the moment there is a view to hang it in.
  if not giant and giantPhase==nil and el<wrap then
   giantPhase='Rise'
   local ok,made=pcall(function()
    return ctx:Colossus({Height=GIANT,At=giantFrame(),Style='Solid',Clip='Idle',Rise=fresh and 140 or 0,FadeIn=fresh and 1.4 or .4})
   end)
   if not ok then warn('SecretArrivals Dogdogdogdog: no giant',made)end
   giant=ok and made or nil
   if giant then
    rim=scope:Highlight(giant.Model,GOLD,C(255,236,170),1,1)
    Kit.Tween(rim,fresh and 1.4 or .4,{OutlineTransparency=.4})
   end
  end
  local splitting=split(el)
  if giant then
   giant:Pose(giantFrame())
   -- Split and Reassemble with the dog itself; for the blink, all eight at once and back.
   if splitting then giantPlay('Blink','Split',workspace:GetServerTimeNow()-3,false,0)
   elseif el>=blink then giantPlay('After','Happy',ctx.Start+T.Happy,true,0)
   elseif el>=T.Happy then giantPlay('Happy','Happy',ctx.Start+T.Happy,true,.3)
   elseif el>=T.Reassemble then giantPlay('Reassemble','Reassemble',ctx.Start+T.Reassemble,false,.25)
   elseif el>=T.Split then giantPlay('Split','Split',ctx.Start+T.Split,false,.25)end
  end
  -- The row: faint slots, the numbers as they are called, dimmed, folded into the "1".
  local mid=ahead(0,0,ROW_AT)
  local fold=(el>=T.One and not splitting)and smooth((el-T.One)/.35)or 0
  local gone=smooth((el-wrap)/.5)
  local dim=smooth((el-T.Dim)/.35)
  for i,n in ipairs(row)do
   local slot=ahead(math.rad(ROW[i]),0,ROW_AT)
   local bob=calm and 0 or math.sin(el*1.7+n.Bob)*1.6
   n.Anchor.CFrame=CFrame.new(slot:Lerp(mid,fold)+Vector3.new(0,bob,0))
   local called=el>=calls[i]
   local s,a
   if splitting then s,a=1,0
   elseif called then
    s=backOut((el-calls[i])/.3)*(1-.18*dim)*(1-.6*fold)
    a=math.max(.2*dim,fold)
   else s,a=.42,1-.45*smooth((el-.5)/.6)*(1-fold)end
   a=math.max(a,gone)
   local text=(called or splitting)and n.Digit or '?'
   if n.Text~=text then n.Text=text;n.Label.Text=text end
   n.Label.Size=UDim2.fromScale(s,s);n.Label.TextTransparency=a;n.Stroke.Transparency=a
  end
  local oneS=(el>=T.One+.2 and not splitting)and backOut((el-T.One-.2)/.4)or 0
  oneAt.CFrame=CFrame.new(mid+Vector3.new(0,gone*40,0))
  oneLabel.Size=UDim2.fromScale(oneS,oneS)
  oneLabel.TextTransparency=oneS>0 and gone or 1;oneStroke.Transparency=oneS>0 and gone or 1
  -- The gold ring reaching this player.
  if ringAt and not passed then
   local a=math.clamp((el-ringAt)/3.2,0,1)
   local me=Kit.Me()
   local d=Vector3.new(me.X-origin.X,0,me.Z-origin.Z).Magnitude
   if 8+(WAVE-8)*(1-(1-a)^3)>=d then
    passed=true
    if d>60 and el-ringAt-3.2*(1-(1-(d-8)/(WAVE-8))^(1/3))<.4 then
     Kit.Cue('Chime',nil,.3)
     if not calm then Kit.Flash(CREAM,.84,.45)end
     scope:Burst(me+Vector3.new(0,2,0),GOLD,18,{Speed=NumberRange.new(6,14),Lifetime=NumberRange.new(.4,.8),Size=NumberSequence.new(.5,0)})
    end
   end
  end
  return true
 end)

 ---------------------------------------------------------------- the act
 -- 0: the giant rises (above); a fanfare climbs for everyone while the sky turns.
 if live(0)then
  Kit.Cue('Whoosh',nil,.3)
  for k=1,8 do task.delay(.12+.13*k,pip,.75*SCALE[k],.07+.01*k)end
 end
 -- Hidden until it comes apart, then it is already coming apart (the Split clip).
 local vis=scope:Visibility(model)
 local hidden=joined<T.Split+.4
 if hidden then vis.Set(1)end
 -- T.Split: eight pops go off around the spot, one after another.
 for i=1,8 do
  local t=T.Split+(i-1)*.04
  if not ctx:Wait(t)then return end
  if live(t)then
   local angle=(i-.5)/8*math.pi*2
   scope:Burst(origin+Vector3.new(math.cos(angle)*4.5,.3,math.sin(angle)*4.5),GOLD,16,{SpreadAngle=Vector2.new(25,25),
    Speed=NumberRange.new(8,15),Acceleration=Vector3.new(0,-34,0),Lifetime=NumberRange.new(.5,.9),Size=NumberSequence.new(.5,0)})
   pip(2+i*.12,.2)
  end
 end
 if not ctx:Wait(T.Split+.4)then return end
 if hidden then
  if live(T.Split+.4)then
   scope:Every(function(_,age)local a=math.min(age/.18,1);vis.Set(1-a);return a<1 end)
   scope:Ring(origin+Vector3.new(0,.15,0),GOLD,1,8,.5,{Thickness=.3})
   Kit.Cue('Whoosh',nil,.45)
  else vis.Set(0)end
 end
 -- +.56: the big dog drops straight through the belt (or the pad), and out of every sky.
 if not ctx:Wait(T.Split+.56)then return end
 if live(T.Split+.56)then
  scope:Ring(origin+Vector3.new(0,.12,0),CREAM,1.5,9,.6,{Thickness=.22,Alpha=.3})
  scope:Burst(origin+Vector3.new(0,.4,0),C(255,222,150),22,{Texture=Kit.Textures.Smoke,LightEmission=.3,Drag=3,
   Speed=NumberRange.new(3,7),SpreadAngle=Vector2.new(80,80),Lifetime=NumberRange.new(.6,1.1),
   Size=NumberSequence.new({NumberSequenceKeypoint.new(0,1),NumberSequenceKeypoint.new(1,2.6)}),
   Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,.4),NumberSequenceKeypoint.new(1,1)})})
  Kit.Cue('Impact',nil,.45)
  local n=near();if n>.05 then Kit.Shake(.2*n,.35)end
 end
 -- T.Marks: the pups land, each on its own mark.
 if not ctx:Wait(T.Marks)then return end
 for _,p in ipairs(stage)do
  local at=p.Anchor.Position
  local mark=scope:Part({Name='Mark',Shape=Enum.PartType.Cylinder,Color=GOLD,Transparency=.45,Size=Vector3.new(.05,.1,.1),
   CFrame=CFrame.new(at.X,origin.Y+.06,at.Z)*FLAT})
  Kit.Tween(mark,.35,{Size=Vector3.new(.05,1.9,1.9)},Enum.EasingStyle.Back)
  p.Mark=mark
 end
 -- Roll call, in step with the typed "dog dog dog...": one number per pup, up the scale.
 -- (the sky's numbers and the hops around each player follow the same clock, above)
 for i,p in ipairs(stage)do
  local at=calls[i]
  if not ctx:Wait(at)then return end
  p.Gui.Enabled=true
  if live(at)then
   p.Label.Rotation=calm and 0 or (i%2==0 and 14 or -14)
   p.Label.Size=UDim2.fromScale(.15,.15)
   Kit.Tween(p.Label,.3,{Size=UDim2.fromScale(1,1),Rotation=0},Enum.EasingStyle.Back)
   pip(1.25*SCALE[i],.45)
   p.Spark:Emit(low and 4 or 12)
   if p.Light then p.Light.Brightness=4;Kit.Tween(p.Light,.5,{Brightness=0})end
   p.Mark.Transparency=0;Kit.Tween(p.Mark,.45,{Transparency=.35})
   -- A spark where the number lands in this player's sky.
   scope:Burst(row[i].Anchor.Position,CREAM,low and 8 or 18,{Speed=NumberRange.new(14,30),Lifetime=NumberRange.new(.4,.8),
    Size=NumberSequence.new(5,0),Drag=2})
  else p.Label.Size=UDim2.fromScale(1,1)end
 end
 -- T.Reassemble: eight leashes snap taut and reel the pups back in (the pups around every
 -- player leap for the giant, and the giant pulls itself together: above).
 if not ctx:Wait(T.Reassemble)then return end
 local hub=scope:Part({Name='Hub',Shape=Enum.PartType.Ball,Color=CREAM,Size=Vector3.one*.2,Position=ctx:Ground()+Vector3.new(0,size.Y*.5,0)})
 Kit.Tween(hub,.25,{Size=Vector3.one*.9},Enum.EasingStyle.Back)
 local knotLight=not low and scope:Light(hub,GOLD,14,2.5)or nil
 local knot=Instance.new('Attachment');knot.Parent=hub
 local leashes={}
 if not low then
  for i,p in ipairs(stage)do
   leashes[i]=scope:Beam(p.Attachment,knot,GOLD,.14,{Width1=.22,Segments=14,Transparency=NumberSequence.new(1)})
  end
  -- A twang: the slack whips out of each line, alternating sides.
  scope:Every(function(_,age)
   local slack=math.cos(age*28)*math.exp(-age*5)*2.4
   local alpha=NumberSequence.new(math.max(.05,1-age*8))
   for i,b in ipairs(leashes)do
    b.CurveSize0=slack*(i%2==0 and 1 or -1);b.CurveSize1=-b.CurveSize0*.5;b.Transparency=alpha
   end
   return age<1.2
  end)
 end
 if live(T.Reassemble)then Kit.Cue('Whoosh',nil,.55)end
 for _,p in ipairs(stage)do
  local mark=p.Mark
  local t=Kit.Tween(mark,.4,{Size=Vector3.new(.05,.1,.1),Transparency=1},Enum.EasingStyle.Back,Enum.EasingDirection.In)
  t.Completed:Connect(function()mark:Destroy()end)
 end
 -- T.Close: the body climbs back up through the floor; a ring closes in, the pitch winds up.
 if not ctx:Wait(T.Close)then return end
 if live(T.Close)then
  scope:Ring(origin+Vector3.new(0,.2,0),GOLD,8,1.5,.75,{Thickness=.3,Alpha=.25})
  for k=0,5 do task.delay(k*.11,pip,1.4+k*.32,.18+k*.04)end
 end
 if not ctx:Wait(T.Dim)then return end
 for _,p in ipairs(stage)do
  Kit.Tween(p.Label,.35,{TextTransparency=.35,Size=UDim2.fromScale(.75,.75)});Kit.Tween(p.Stroke,.35,{Transparency=.35})
 end
 -- T.One: one dog. The eight numbers fold into a single "1", here and in every sky.
 if not ctx:Wait(T.One)then return end
 for _,b in ipairs(leashes)do b:Destroy()end
 Kit.Tween(hub,.15,{Size=Vector3.one*.1,Transparency=1})
 if knotLight then Kit.Tween(knotLight,.4,{Brightness=0})end
 for _,p in ipairs(stage)do p.Gui.Enabled=false end
 local oneGui=billboard(top,UDim2.new(2.6,40,2.6,40),1.4)
 local one,oneStroke2=number(oneGui,'1',4)
 oneGui.Parent=top
 Kit.Tween(one,.4,{Size=UDim2.fromScale(1,1)},Enum.EasingStyle.Back)
 if ctx:Elapsed()<T.One+1.5 then
  local by=ctx.By and string.upper(ctx.By)or nil
  ctx:Banner({Style='Alert',Color=GOLD,Hold=3.2,Text='there were eight. now there is one.',
   Kicker=open and(by and '⚠  '..by..' FOUND A SECRET DOG  ⚠'or '⚠  A SECRET DOG CAME OUT OF A LUCKY BLOCK  ⚠')
    or '⚠  SECRET DOG ON THE TONGUE  ⚠'})
 else
  -- Too late for the banner: the reveal card instead.
  ctx:Title({Font=Enum.Font.LuckiestGuy,Hold=3.6})
 end
 if live(T.One)then
  -- (The banner brings its own sting and impact.)
  Kit.Cue('Chime',nil,.6)
  local n=near()
  if n>.05 then
   if not calm then Kit.Flash(C(255,232,160),1-.32*n,.5)end
   Kit.Shake(.4*n,.5);Kit.FOVPunch(-5*n,.1,.8)
   grade.Brightness=.12*n;Kit.Tween(grade,.7,{Brightness=0})
  end
  scope:Ring(origin+Vector3.new(0,.2,0),GOLD,1,15,.9,{Thickness=.45})
  if not low then scope:Ring(origin+Vector3.new(0,.25,0),WHITE,1,9,.7,{Thickness=.2,Alpha=.35,Segments=24})end
  -- Gone once faded: an invisible Highlight still takes one of the client's few Highlight slots.
  local glow=scope:Highlight(model,C(255,214,110),C(255,244,200),.5,0)
  Kit.Tween(glow,.9,{FillTransparency=1,OutlineTransparency=1}).Completed:Connect(function()glow:Destroy()end)
  if rim then rim.OutlineTransparency=0;Kit.Tween(rim,.6,{OutlineTransparency=.4})end
  -- A gold ring sweeps the whole district from the stage.
  ringAt=T.One
  scope:Ring(origin+Vector3.new(0,3,0),GOLD,8,WAVE,3.2,{Thickness=2.6,Alpha=.3,Segments=48})
  if not low then scope:Ring(origin+Vector3.new(0,5,0),CREAM,4,WAVE*.96,3.4,{Thickness=1.2,Alpha=.5,Segments=48})end
  -- Confetti off the top of the dog: gold, cream and white flakes that flutter down.
  local from=ctx:Ground()+Vector3.new(0,size.Y*.85,0)
  if low then
   scope:Burst(from,GOLD,24,{Speed=NumberRange.new(10,18),Acceleration=Vector3.new(0,-20,0),Lifetime=NumberRange.new(1,1.6)})
   scope:Burst(from,WHITE,16,{Speed=NumberRange.new(10,18),Acceleration=Vector3.new(0,-20,0),Lifetime=NumberRange.new(1,1.6)})
  else
   -- Open air: the pad is a raised slab, not the flat belt.
   local pad
   if open then
    pad=RaycastParams.new();pad.FilterType=Enum.RaycastFilterType.Exclude;pad.RespectCanCollide=true
    pad.FilterDescendantsInstances=character and {model,character,scope.Folder}or {model,scope.Folder}
   end
   confetti(from,40,origin.Y+.06,pad,1)
   -- ...and a popper over this player's own head, wherever they are.
   local me=Kit.Me()
   if (me-from).Magnitude>30 then confetti(me+Vector3.new(0,5,0),28,me.Y-3,probe,.8)end
  end
 end
 -- Gold confetti falls around every player for a while.
 -- (A short, thick shower: the last flake lands as the hold ends.)
 local flakes
 if ctx:Elapsed()<T.One+1 then
  flakes=scope:Rain({Texture=Kit.Textures.Spark,Rate=64,Area=110,Height=26,Speed=NumberRange.new(6,10),
   Lifetime=NumberRange.new(2,2.6),SpreadAngle=Vector2.new(30,30),Acceleration=Vector3.new(0,-6,0),Drag=1.2,
   Rotation=NumberRange.new(0,360),RotSpeed=NumberRange.new(-220,220),LightEmission=.45,LightInfluence=.5,
   Color=ColorSequence.new({ColorSequenceKeypoint.new(0,GOLD),ColorSequenceKeypoint.new(.5,CREAM),ColorSequenceKeypoint.new(1,WHITE)}),
   Size=NumberSequence.new(.36),Squash=NumberSequence.new({NumberSequenceKeypoint.new(0,0),NumberSequenceKeypoint.new(.25,1.4),
    NumberSequenceKeypoint.new(.5,-1.2),NumberSequenceKeypoint.new(.75,1.3),NumberSequenceKeypoint.new(1,-1)}),
   Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,.1),NumberSequenceKeypoint.new(.8,.2),NumberSequenceKeypoint.new(1,1)})})
 end
 if not ctx:Wait(T.One+1.2)then return end
 if flakes then flakes.Rate=0 end
 -- T.Happy: a little fountain of glints over its head.
 if not ctx:Wait(T.Happy)then return end
 if live(T.Happy)then glints:Emit(low and 4 or 14)end
 -- "...now there are eight." For a blink, all eight are still in there (and in the sky).
 if not ctx:Wait(blink)then return end
 if ctx:Elapsed()<blink+.37 then
  for _,p in ipairs(stage)do
   p.Gui.StudsOffsetWorldSpace=Vector3.zero;p.Label.Size=UDim2.fromScale(.8,.8);p.Label.TextTransparency=.1;p.Stroke.Transparency=.1
  end
  -- Reduced motion: one steady blink instead of the flicker.
  for k,at in ipairs(calm and {0,.37} or {0,.08,.15,.37})do
   if not ctx:Wait(blink+at)then return end
   local on=k%2==1
   for _,p in ipairs(stage)do p.Gui.Enabled=on end
   oneGui.Enabled=not on
   if k==1 then Kit.Cue('Glitch',nil,.22)end
  end
 end
 -- The "1" floats off, the gold lifts and the giant fades out of every sky.
 if not ctx:Wait(wrap)then return end
 Kit.Tween(oneGui,.4,{StudsOffsetWorldSpace=Vector3.new(0,3.2,0)},Enum.EasingStyle.Quad,Enum.EasingDirection.In)
 Kit.Tween(one,.4,{TextTransparency=1});Kit.Tween(oneStroke2,.4,{Transparency=1})
 Kit.Tween(grade,1.2,{TintColor=WHITE,Saturation=0,Contrast=0,Brightness=0})
 if sky then sky:Release(1.6)end
 if giant then giant:Stop(.9)end
 if rim then Kit.Tween(rim,.6,{OutlineTransparency=1})end
 if live(wrap)then Kit.Cue('Chime',nil,.25)end
 -- Let the last line be read, the giant finish fading and the last flakes land, then
 -- everything goes with the scope.
 ctx:Wait(math.max(hold,wrap+1,T.One+1.2+2.6))
end
