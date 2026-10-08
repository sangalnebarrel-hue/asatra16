-- THE WRONG DOG: "IT IS LOOKING AT YOU". It arrives facing into the throat, hovering a
-- little, perfectly still. Then the film skips: every 0.4 s it stands some other wrong
-- way, the stage light pops for two frames and a black double of it stands where nothing
-- was, nearer each time. The lights go out, two red eyes open in the dark, and when the
-- lights come back it is facing you: every player sees it facing them, its red stare
-- running into their own camera. At 5.6 it snaps back as if nothing happened.
-- Off the tongue (a Lucky pad in the open) it faces away from the opener, and lamps of
-- its own stand in for the mouth's runes and lanterns.
local Players=game:GetService('Players')
local SoundService=game:GetService('SoundService')
local C=Color3.fromRGB
local SICK,PALE,BONE,EMBER,BLACK=C(210,255,200),C(228,255,218),C(226,236,218),C(70,0,6),C(0,0,0)
local WARM=C(255,201,130)
local TICK='rbxasset://sounds/volume_slider.ogg'
-- The skips: {t, yaw from its line rotation, hover studs, lean}. Hard cuts, never tweened.
local CUTS={{.4,math.pi/2,.4,0},{.8,math.pi*1.5,.4,0},{1.2,0,1.1,0},{1.6,math.pi,.4,.24}}
local DARK,EYES,STARE,RELEASE,BLINK=2,2.2,2.4,5.6,6.15
local BEAT,LAMP=.8,1.3

return function(ctx:any)
 ctx.WhisperStyle={Font=Enum.Font.Garamond,Color=BONE,Glitch=.02,Chroma=false,Shake=false,Type=.05}
 local Kit,scope,model,config=ctx.Kit,ctx.Scope,ctx.Model,ctx.Config
 local low,calm,hold,origin=ctx.Low,Kit.ReducedMotion(),config.Hold,ctx.Origin
 local RED=config.Color
 local size=Kit.Size(model)
 local fresh=ctx.Late<.3
 -- Off the tongue (a Lucky pad): open air, no mouth, no lanterns, any facing.
 local open=(ctx.Venue or 'Tongue')~='Tongue'
 -- Was this beat on time? (late joiners get the state, not the scare)
 local function live(t)return ctx:Elapsed()-t<.35 end
 local ground=model:GetAttribute('GroundLocal')
 ground=typeof(ground)=='Vector3'and ground or Vector3.zero
 -- Its own rotation on the line, read before we touch it: every yaw is measured from it.
 local look=Kit.Root(model)and model:GetPivot().LookVector or Vector3.zAxis
 local face=Vector3.new(look.X,0,look.Z)
 face=face.Magnitude>.01 and face.Unit or Vector3.zAxis
 -- Flat direction and distance from `from` to this client's camera.
 local function toCamera(from:Vector3):(Vector3?,number)
  local camera=workspace.CurrentCamera
  if not camera then return nil,0 end
  local d=camera.CFrame.Position-from
  d=Vector3.new(d.X,0,d.Z)
  if d.Magnitude<1 then return nil,d.Magnitude end
  return d.Unit,d.Magnitude
 end
 local function yawTo(dir:Vector3)return math.atan2(face:Cross(dir).Y,face:Dot(dir))end
 local function click(speed,volume,parent)
  if not scope.Alive then return end
  local s=Instance.new('Sound');s.SoundId=TICK;s.Volume=volume;s.PlaybackSpeed=speed
  s.RollOffMinDistance=10;s.RollOffMaxDistance=220
  local eq=Instance.new('EqualizerSoundEffect');eq.LowGain=6;eq.MidGain=-2;eq.HighGain=-22;eq.Parent=s
  s.Parent=parent or SoundService;scope:Add(s);s:Play()
  task.delay(3,function()if scope.Alive and s.Parent then s:Destroy()end end)
 end
 -- Open air: the pad is raised over its court, so whatever stands off it finds the real
 -- ground under it, once (never a player or the dog). The tongue's belt is flat.
 local function settle(at:Vector3):Vector3
  if not open then return at end
  local params=RaycastParams.new();params.FilterType=Enum.RaycastFilterType.Exclude;params.RespectCanCollide=true
  local skip:{Instance}={model,scope.Folder}
  for _,p in ipairs(Players:GetPlayers())do if p.Character then table.insert(skip,p.Character)end end
  params.FilterDescendantsInstances=skip
  local hit=workspace:Raycast(at+Vector3.new(0,3,0),Vector3.new(0,-6,0),params)
  return hit and hit.Position or at
 end

 -- The dog itself: local only, about its own feet. It starts facing the wrong way.
 -- On the tongue it faces +Z. Elsewhere its facing is only known once the root streams
 -- in: until then the pose waits in a stand-in, so the facing is read before any offset.
 local lift:any
 if open and not model.PrimaryPart then
  lift={CFrame=CFrame.identity}
  scope:Every(function()
   if not model.PrimaryPart then return true end
   local l=model:GetPivot().LookVector
   local f=Vector3.new(l.X,0,l.Z)
   if f.Magnitude>.01 then face=f.Unit end
   local handle=scope:Offset(model);handle.CFrame=lift.CFrame;lift=handle
   return false
  end)
 else lift=scope:Offset(model)end
 local vis=scope:Visibility(model)
 local function pose(yaw,hover,lean)
  lift.CFrame=CFrame.new(0,hover,0)*CFrame.Angles(0,yaw,0)*CFrame.Angles(0,0,lean)
 end
 pose(math.pi,.4,0)
 -- Everything that belongs to the stare (bars, vignette, gaze, outline, the music duck)
 -- lives in its own scope, so "nothing happened" is a single Clean at 5.6.
 local film=Kit.Scope('Arrival_WrongDog_Film')
 scope:Add(function()film:Clean()end)
 film:Letterbox(.075,fresh and .8 or .2)
 film:Duck(.15,.6)
 local drone=scope:Drone('Drone',low and .28 or .42,.34,fresh and 1.2 or .3)
 local grade=scope:Grade({Saturation=-.6,TintColor=SICK,Contrast=.15},fresh and .6 or .15)
 if fresh then Kit.Cue('Sting',nil,.4)end

 -- The mouth goes wrong too: blood-red runes, black-red mist. (Only in the mouth: a
 -- Lucky pad may stand near the line, but its lanterns and runes are not this stage.)
 local district=not open and workspace:FindFirstChild('DOGROTS_District')or nil
 local factory=district and district:FindFirstChild('02_DogFactory')
 local tunnel=factory and factory:FindFirstChild('DarkMouthTunnel')
 local line=district and district:FindFirstChild('03_DogLine')
 if tunnel then
  for _,o in ipairs(tunnel:GetDescendants())do
   if o.Name=='MouthRune'and o:IsA('BasePart')then scope:Override(o,{Color=C(200,30,30)})
   elseif o:IsA('ParticleEmitter')then scope:Override(o,{Color=ColorSequence.new(EMBER,C(6,0,0)),LightEmission=0})end
  end
 end
 -- The lanterns around the stage: out in the dark, red for the stare, then as they were.
 -- Colour only: WorldDetailQuality owns Enabled, and world-event lighting snapshots and
 -- restores Brightness (an event starting mid-stare would keep ours forever).
 local lamps:{any}={}
 for _,lantern in ipairs(line and line:GetChildren()or {})do
  local lens=lantern.Name=='PromenadeLantern'and lantern:FindFirstChild('WarmLens')
  if lens and lens:IsA('BasePart')and (lens.Position-origin).Magnitude<32 then
   table.insert(lamps,{Object=lens,Color=lens.Color,Off=C(24,20,22)})
   scope:Override(lens,{Color=lens.Color})
   for _,l in ipairs(lantern:GetDescendants())do
    if l:IsA('PointLight')then
     table.insert(lamps,{Object=l,Color=l.Color,Off=BLACK})
     scope:Override(l,{Color=l.Color})
    end
   end
  end
 end
 -- In the open the stage brings its own: eight red runes standing round it, a black-red
 -- ground mist, and lamps where the lanterns would be (ours, so they fade out after).
 local runes:{BasePart}={}
 local mist:any=nil
 if open then
  for i=1,8 do
   local angle=(i-.5)/8*math.pi*2
   local rune=scope:Part({Name='Rune',Size=Vector3.new(.4,1.6,.4),Color=C(200,30,30),Transparency=1,
    Position=settle(origin+Vector3.new(math.cos(angle)*9,0,math.sin(angle)*9))+Vector3.new(0,.8,0)})
   Kit.Tween(rune,fresh and .6 or .1,{Transparency=0})
   runes[i]=rune
  end
  local bed=scope:Part({Name='Mist',Size=Vector3.new(14,.2,14),Transparency=1,Position=origin+Vector3.new(0,.3,0)})
  mist=scope:Emitter(bed,{Texture=Kit.Textures.Smoke,Rate=low and 2 or 5,Color=ColorSequence.new(EMBER,C(6,0,0)),
   LightEmission=0,Lifetime=NumberRange.new(2,3),Speed=NumberRange.new(.3,1),SpreadAngle=Vector2.new(60,60),
   Size=NumberSequence.new(2,5),Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,1),NumberSequenceKeypoint.new(.35,.5),NumberSequenceKeypoint.new(1,1)})})
  local count=low and 2 or 4
  for i=1,count do
   local angle=(i-.5)/count*math.pi*2
   local l=scope:Light(scope:Anchor(origin+Vector3.new(math.cos(angle)*12,8.5,math.sin(angle)*12),'Lamp'),WARM,18,0)
   Kit.Tween(l,fresh and .6 or .1,{Brightness=1.2})
   table.insert(lamps,{Object=l,Color=WARM,Off=BLACK})
  end
 end
 local function lampsTo(state)
  for _,lamp in ipairs(lamps)do
   if lamp.Object.Parent then lamp.Object.Color=state=='off'and lamp.Off or state=='red'and RED or lamp.Color end
  end
 end

 -- A sick white light straight down on the stage; it pops on every skip.
 local top=origin+Vector3.new(0,13,0)
 local stage=scope:Part({Name='StageLamp',Size=Vector3.one*.2,Transparency=1,CFrame=Kit.LookAt(top,origin)})
 local spot=Instance.new('SpotLight')
 spot.Face=Enum.NormalId.Front;spot.Angle=70;spot.Range=22;spot.Color=SICK;spot.Brightness=0;spot.Shadows=not low
 spot.Parent=stage
 -- The fade can outlast 0.4 for a slightly late client: the first pop cancels it.
 local lampIn=fresh and Kit.Tween(spot,.35,{Brightness=LAMP})or nil
 if not lampIn then spot.Brightness=LAMP end

 -- Red eyes: anchors riding the RedEye bones (lights under the dog would be throttled by
 -- WorldDetailQuality). Until the bones stream in they sit where its eyes should be.
 local eyes:{any}={}
 for i,name in ipairs({'RedEye.L','RedEye.R'})do
  local a=scope:Anchor(origin+Vector3.new(0,size.Y*.9,0),'RedEye')
  local att=Instance.new('Attachment');att.Parent=a
  eyes[i]={Name=name,Anchor=a,Attachment=att,Side=i==1 and 1 or -1,Bone=nil,
   Light=(i==1 or not low)and scope:Light(a,RED,low and 10 or 8,0)or nil,
   Glint=scope:Emitter(a,{Color=ColorSequence.new(RED),Lifetime=NumberRange.new(.18,.34),Speed=NumberRange.new(0,0),
    Size=NumberSequence.new(.6,0),Rotation=NumberRange.new(0,360),LockedToPart=true,ZOffset=.8})}
 end
 local function eyesTo(brightness)
  for _,e in ipairs(eyes)do if e.Light then e.Light.Brightness=brightness end end
 end
 local lookup=0
 scope:Every(function()
  local now=os.clock()
  local search=now>=lookup
  if search then lookup=now+.5 end
  local pivot=model.Parent and Kit.Root(model)and model:GetPivot()
  for _,e in ipairs(eyes)do
   -- A skin that streams out keeps its bones but leaves the model: look again.
   local bone:Bone?=e.Bone
   if bone and not bone:IsDescendantOf(model)then bone=nil end
   if search and not bone then
    local found=model:FindFirstChild(e.Name,true)
    bone=if found and found:IsA('Bone')then found else nil
    e.Bone=bone
   end
   if bone then e.Anchor.CFrame=CFrame.new(bone.TransformedWorldCFrame.Position)
   elseif pivot then e.Anchor.CFrame=CFrame.new(pivot:PointToWorldSpace(ground+Vector3.new(e.Side*.2*size.X,size.Y*.9,-size.Z*.43)))end
  end
 end)

 -- Its double: a frozen copy in black Neon (unlit, so a pure silhouette), shown for two
 -- frames per skip. Made on first use, again if the dog had not streamed in yet.
 local double:any=nil
 local function shade()
  if double and #double:GetChildren()>0 then return double end
  if double then double:Destroy()end
  if not model.Parent then return nil end
  double=scope:Ghost(model)
  for _,o in ipairs(double:GetDescendants())do
   if o:IsA('SurfaceAppearance')or o:IsA('Decal')or o:IsA('Texture')then o:Destroy()
   elseif o:IsA('BasePart')then
    o.Material=Enum.Material.Neon;o.Color=BLACK
    if o:IsA('MeshPart')then local mesh=o::MeshPart;pcall(function()mesh.TextureID=''end)end
   end
  end
  Kit.SetGhostAlpha(double,1)
  return #double:GetChildren()>0 and double or nil
 end

 local phase='film'
 local beatAt=-math.huge
 -- A vignette that closes in the dark and beats red with the heart during the stare.
 local edges:{Frame}={}
 local playerGui=Players.LocalPlayer:FindFirstChildOfClass('PlayerGui')
 if playerGui then
  local gui=Instance.new('ScreenGui');gui.Name='DOGROTS_WrongDogVignette';gui.ResetOnSpawn=false
  gui.IgnoreGuiInset=true;gui.DisplayOrder=93
  for _,e in ipairs({{1,.34,0,0,90},{1,.34,0,.66,-90},{.26,1,0,0,0},{.26,1,.74,0,180}})do
   local f=Instance.new('Frame');f.Name='Edge';f.BorderSizePixel=0;f.BackgroundColor3=BLACK;f.BackgroundTransparency=1
   f.Size=UDim2.fromScale(e[1],e[2]);f.Position=UDim2.fromScale(e[3],e[4])
   local g=Instance.new('UIGradient');g.Rotation=e[5]
   g.Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,0),NumberSequenceKeypoint.new(.55,.7),NumberSequenceKeypoint.new(1,1)})
   g.Parent=f;f.Parent=gui;table.insert(edges,f)
  end
  gui.Parent=playerGui
  film:Add(gui)
 end
 local opened=os.clock()
 film:Every(function()
  local w=.45+.55*Kit.Near(origin,160)
  local a,color=.42*math.min((os.clock()-opened)/(fresh and .6 or .1),1),BLACK
  if phase=='dark'then a=.95
  elseif phase=='stare'then a=.55+.35*math.exp(-(os.clock()-beatAt)*4);color=EMBER end
  for _,f in ipairs(edges)do f.BackgroundTransparency=1-a*w;f.BackgroundColor3=color end
  return true
 end)
 -- From the dark on it faces this client's camera, every frame, without easing. Its
 -- gaze ends just in front of the lens; the heart keeps time.
 local gaze:BasePart?=nil
 local nextBeat=STARE+BEAT/2
 film:Every(function()
  if phase=='film'then return true end
  local dir=toCamera(origin)
  if dir then pose(yawTo(dir),.4,0)end
  local camera=workspace.CurrentCamera
  if gaze and camera then gaze.CFrame=camera.CFrame*CFrame.new(0,-.2,-2)end
  if phase=='stare'then
   local now=ctx:Elapsed()
   if now>=nextBeat then
    if now-nextBeat<.3 and nextBeat<RELEASE-.2 then Kit.Cue('Heartbeat',nil,.7);beatAt=os.clock()end
    while nextBeat<=now do nextBeat+=BEAT end
   end
   eyesTo(4+2.5*math.exp(-(os.clock()-beatAt)*5))
  end
  return true
 end)

 -- 0.4-1.6: the film skips. Each cut: a new wrong stance, the light pops, the double
 -- stands in it (beside, the other side, peeking from behind, then in front of you).
 for i,c in ipairs(CUTS)do
  if not ctx:Wait(c[1])then return end
  pose(c[2],c[3],c[4])
  if live(c[1])then
   local toward,distance=toCamera(origin)
   local dir:Vector3=toward or face
   local side=dir:Cross(Vector3.yAxis)
   local g=shade()
   if g then
    local spots:{Vector3}={side*5.5,-side*5.5,side*2.4-dir*4,dir*math.clamp(distance*.5,2,5.5)}
    local at=settle(origin+spots[i])
    g:PivotTo(CFrame.lookAt(at,at+(toCamera(at)or dir))*CFrame.new(-ground))
    Kit.SetGhostAlpha(g,0)
   end
   if lampIn then lampIn:Cancel();lampIn=nil end
   spot.Brightness=calm and 4 or 9
   local frames=0
   scope:Every(function(_,age)
    frames+=1
    if frames<3 or age<.06 then return true end
    if g and g.Parent then Kit.SetGhostAlpha(g,1)end
    if phase=='film'then spot.Brightness=LAMP end
    return false
   end)
   local n=Kit.Near(origin,120)
   if not calm and n>.05 then Kit.Flash(PALE,1-.3*n,.16)end
   Kit.Cue('Heartbeat',nil,.4+i*.1)
   click(.62+i*.06,.55,stage)
  end
 end

 -- 2.0: lights out. Silence; it is gone; it turns to you in the dark.
 if not ctx:Wait(DARK)then return end
 if live(DARK)then
  phase='dark'
  vis.Set(1)
  spot.Brightness=0
  lampsTo('off')
  -- In open air there is no dark throat round it: the screen does more of the dark.
  local n=Kit.Near(origin,160)
  grade.Brightness=open and -.14-.3*n or -.08-.22*n;grade.Contrast=.3
  -- A tween, so it also cancels a late client's fade-in still running.
  if drone then Kit.Tween(drone,.05,{Volume=0})end
  click(.5,.7,stage)
 end
 -- 2.2: two red eyes open where it was.
 if not ctx:Wait(EYES)then return end
 if phase=='dark'and live(EYES)then
  for _,e in ipairs(eyes)do
   if e.Light then Kit.Tween(e.Light,.15,{Brightness=2.5})end
   e.Glint:Emit(low and 2 or 5)
  end
  Kit.Cue('Heartbeat',nil,.35)
 end

 -- 2.4: it is looking at you. Only you.
 if not ctx:Wait(STARE)then return end
 phase='stare'
 ctx.WhisperStyle={Font=Enum.Font.Garamond,Color=C(255,76,76),Glitch=.12,Chroma=true,Shake=false,Type=.07}
 vis.Set(0)
 spot.Brightness=0
 lampsTo('red')
 grade.Brightness=-.04;grade.Contrast=.24;grade.Saturation=-.5
 film:Highlight(model,EMBER,RED,.86,.2)
 eyesTo(4)
 for _,e in ipairs(eyes)do e.Glint.Rate=low and 3 or 7 end
 if not low then
  gaze=film:Part({Name='Gaze',Size=Vector3.one*.2,Transparency=1,Position=origin})
  local att=Instance.new('Attachment');att.Parent=gaze
  for _,e in ipairs(eyes)do
   film:Beam(e.Attachment,att,RED,.1,{Width1=.025,Segments=1,
    Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,.2),NumberSequenceKeypoint.new(.6,.6),NumberSequenceKeypoint.new(1,1)})})
  end
 end
 if drone then drone.PlaybackSpeed=.27;Kit.Tween(drone,.2,{Volume=low and .34 or .5})end
 if live(STARE)then
  beatAt=os.clock()
  Kit.Cue('Impact',nil,.85);Kit.Cue('Sting',nil,.75);Kit.Cue('Glitch',eyes[1].Anchor,.35)
  local n=Kit.Near(origin,120)
  if n>.05 then
   Kit.Flash(C(120,0,6),1-.45*n,.6)
   Kit.Shake(.3*n,.3)
   Kit.FOVPunch(-6*n,math.max(.5,RELEASE-ctx:Elapsed()),.3)
  end
 end

 -- 5.6: as if nothing happened. It lands, facing down the line (on a pad: the opener);
 -- the name comes up.
 if not ctx:Wait(RELEASE)then return end
 phase='done'
 film:Clean()
 pose(0,0,0)
 eyesTo(0)
 for _,e in ipairs(eyes)do e.Glint.Rate=0 end
 lampsTo('home')
 if open then
  -- Our own lamps were never there: they go with the grade.
  if mist then mist.Rate=0 end
  for _,lamp in ipairs(lamps)do Kit.Tween(lamp.Object,.8,{Brightness=0})end
 end
 Kit.Tween(grade,.8,{Brightness=0,Contrast=0,Saturation=0,TintColor=Color3.new(1,1,1)})
 if drone then drone.Volume=0 end
 ctx:Title({Font=Enum.Font.Garamond,Hold=3.8})
 if live(RELEASE)then Kit.Cue('Chime',nil,.3)end
 -- 6.15: its eyes, once more, for two frames.
 if not ctx:Wait(BLINK)then return end
 if live(BLINK)then
  eyesTo(5)
  for _,e in ipairs(eyes)do e.Glint:Emit(2)end
  click(1.6,.25,eyes[1].Anchor)
  local frames=0
  scope:Every(function(_,age)
   frames+=1
   if frames<3 or age<.07 then return true end
   eyesTo(0);return false
  end)
 end
 if not ctx:Wait(hold)then return end
 -- It walks; the runes stay red a moment longer. (On a pad ours burn out.)
 for _,rune in ipairs(runes)do Kit.Tween(rune,.9,{Transparency=1})end
 ctx:Wait(hold+1)
end
