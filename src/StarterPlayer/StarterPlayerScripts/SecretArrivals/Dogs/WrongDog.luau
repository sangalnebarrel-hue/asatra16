-- THE WRONG DOG: "IT IS LOOKING AT YOU". The whole island goes first: every light on it
-- dies, the sun drops away in two seconds and the island sits in a moonless black with a
-- red haze (a red mist hangs around every player). At 1.9 every dog on the island opens
-- red eyes and turns to look at you (each player sees them all looking at them), the
-- giant head's pupils ignite red and eyes blink open in the dark around you; at 2.6 a
-- colossal black silhouette of it, rimmed red, rises in every player's sky beyond the
-- stage as they see it (on the tongue: over the giant head's crown), its back to them.
-- At 5.4 its act: it is on the stage (the only lit place left), facing into the throat,
-- perfectly still. Then the film skips: every 0.4 s it stands some other wrong way, the
-- stage light pops and a black double of it stands where nothing was; on the same skips
-- every player's own black double stands in the dark in front of them, nearer each time,
-- the colossus jumps to another wrong stance (nearer too) and the giant head looks the
-- wrong ways. At 7.15 every camera is pulled out over the island; at 7.4 everything goes
-- out at once (the stage, every eye, the colossus, your double), two red eyes open in the
-- mouth, and at 7.8 it is facing you: a hard cut into its face, its red stare running
-- into the lens, a red flash for everyone, every eye on the island open again and on you,
-- the colossus leaning over the stage with its head turned to you, the giant pupils
-- following your camera. Handed back at 9.7 it is all still looking at you, and at 9.9
-- your double stands right behind you. At 11 everything snaps back as if nothing
-- happened: the lights come on, the sky eases back to day (by 14.2), the name comes up.
-- Off the tongue (a Lucky pad in the open) it faces away from the opener, and lamps of its
-- own stand in for the mouth's runes and lanterns; the cutaway looks out from the island's
-- centre through the stage.
local Players=game:GetService('Players')
local SoundService=game:GetService('SoundService')
local TweenService=game:GetService('TweenService')
local C=Color3.fromRGB
local SICK,PALE,BONE,EMBER,BLACK=C(210,255,200),C(228,255,218),C(226,236,218),C(70,0,6),C(0,0,0)
local WARM=C(255,201,130)
local TICK='rbxasset://sounds/volume_slider.ogg'
-- The island goes first; the act on the stage starts at ACT (its beats are relative to it).
local ACT=5.4
-- The skips: {t, yaw from its line rotation, hover studs, lean}. Hard cuts, never tweened.
local CUTS={{ACT+.4,math.pi/2,.4,0},{ACT+.8,math.pi*1.5,.4,0},{ACT+1.2,0,1.1,0},{ACT+1.6,math.pi,.4,.24}}
local DARK,EYES,STARE,RELEASE,BLINK=ACT+2,ACT+2.2,ACT+2.4,ACT+5.6,ACT+6.15
local BEAT,LAMP=.8,1.3
-- Before the act: the island's lights die (a relay click each), every eye opens, the
-- colossus rises, the heart. The cutaway runs ACT+1.75 to ACT+4.3; then your double.
local DIE={.35,.6,.9,1.2,1.5}
local OPEN,RISE,BEHIND=1.9,2.6,ACT+4.5
local HEART={3.3,4.2,5}
local TALL=270
-- Each skip on the island: your double {studs beyond you, to your right, head tilt}; the
-- colossus {studs from your camera to its eyes, yaw from facing you, lean}: nearer every
-- time; the giant head's pupils {studs across for the left one, for the right one, up}:
-- up-left, cross-eyed, wall-eyed, down at the stage.
local DOUBLE={{34,8,.45},{22,-6,-.55},{13,3.5,.8},{6,-1.5,-.3}}
local STANCE={{470,math.pi/2,0},{420,math.pi*1.5,0},{370,math.pi,.24},{320,0,0}}
local GAZE={{2,2,1.3},{2,-2,-.4},{-2,2,1.5},{0,0,-1.5}}
-- The colossus rises this far off (its back to you) and stares from this near, leaning in.
local RISEN,LEAN=520,250

return function(ctx:any)
 ctx.WhisperStyle={Font=Enum.Font.Garamond,Color=BONE,Glitch=.02,Chroma=false,Shake=false,Type=.05}
 local Kit,scope,model,config=ctx.Kit,ctx.Scope,ctx.Model,ctx.Config
 local low,calm,hold,origin=ctx.Low,Kit.ReducedMotion(),config.Hold,ctx.Origin
 local RED=config.Color
 local size=Kit.Size(model)
 local fresh=ctx.Late<.3
 local UP=Vector3.yAxis
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
 -- From the island's centre out through the stage (on the tongue: south, behind the giant
 -- head): the colossus stands that way, and the cutaway looks that way.
 local away=Vector3.new(origin.X-Kit.Map.Center.X,0,origin.Z-Kit.Map.Center.Z)
 away=away.Magnitude>40 and away.Unit or Vector3.new(0,0,-1)
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
 -- A dull relay click: 2D (every player, wherever they are) unless given a parent.
 local function click(speed,volume,parent:Instance?)
  if not scope.Alive then return end
  local s=Instance.new('Sound');s.SoundId=TICK;s.Volume=volume;s.PlaybackSpeed=speed
  s.RollOffMinDistance=10;s.RollOffMaxDistance=220
  local eq=Instance.new('EqualizerSoundEffect');eq.LowGain=6;eq.MidGain=-2;eq.HighGain=-22;eq.Parent=s
  s.Parent=parent or SoundService;scope:Add(s);s:Play()
  task.delay(3,function()if scope.Alive and s.Parent then s:Destroy()end end)
 end
 -- Everything that belongs to the dark (the island's lights and sky, the music, every red
 -- eye, the colossus, your double, the stare's bars, vignette, gaze and outline) lives in
 -- its own scope, so "nothing happened" is a single Clean at RELEASE.
 local film=Kit.Scope('Arrival_WrongDog_Film')
 scope:Add(function()film:Clean()end)
 -- When the dark ends on the server clock (Scope:Sky keeps clear of world events till then).
 film.EndsAt=ctx.Start+RELEASE
 -- Rays that only see the world (never a player, the dog or anything of ours).
 local function rays():RaycastParams
  local params=RaycastParams.new();params.FilterType=Enum.RaycastFilterType.Exclude;params.RespectCanCollide=true
  local skip:{Instance}={model,scope.Folder,film.Folder}
  for _,p in ipairs(Players:GetPlayers())do if p.Character then table.insert(skip,p.Character)end end
  params.FilterDescendantsInstances=skip
  return params
 end
 -- Open air: the pad is raised over its court, so whatever stands off it finds the real
 -- ground under it, once. The tongue's belt is flat.
 local function settle(at:Vector3):Vector3
  if not open then return at end
  local hit=workspace:Raycast(at+Vector3.new(0,3,0),Vector3.new(0,-6,0),rays())
  return hit and hit.Position or at
 end

 -- The dog itself: local only, about its own feet. It starts facing the wrong way, and
 -- hidden: the island goes first. On the tongue it faces +Z. Elsewhere its facing is only
 -- known once the root streams in: until then the pose waits in a stand-in, so the facing
 -- is read before any offset.
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
 vis.Set(1)
 local function pose(yaw,hover,lean)
  lift.CFrame=CFrame.new(0,hover,0)*CFrame.Angles(0,yaw,0)*CFrame.Angles(0,0,lean)
 end
 pose(math.pi,.4,0)
 film:Letterbox(.075,fresh and .8 or .2)
 -- The music dies all over the island.
 film:Duck(.03,fresh and 1.2 or .3)
 local drone=scope:Drone('Drone',low and .28 or .42,.34,fresh and 1.2 or .3)
 -- A blood-night grade for everyone (the stage's own light stays sick white).
 local grade=scope:Grade({Saturation=-.35,TintColor=C(255,198,192),Contrast=.22,Brightness=-.03},fresh and 1.6 or .15)

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
 -- The lanterns around the stage: dark with the island, lit for its act, out in the dark,
 -- red for the stare, then as they were. Colour only: WorldDetailQuality owns Enabled, and
 -- world-event lighting snapshots and restores Brightness (an event starting mid-stare
 -- would keep ours forever). These layers sit under the island's blackout (made below).
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
 -- All of it waits, unlit, for the act.
 local runes:{BasePart}={}
 local own:{PointLight}={}
 local mist:any=nil
 if open then
  for i=1,8 do
   local angle=(i-.5)/8*math.pi*2
   runes[i]=scope:Part({Name='Rune',Size=Vector3.new(.4,1.6,.4),Color=C(200,30,30),Transparency=1,
    Position=settle(origin+Vector3.new(math.cos(angle)*9,0,math.sin(angle)*9))+Vector3.new(0,.8,0)})
  end
  local bed=scope:Part({Name='Mist',Size=Vector3.new(14,.2,14),Transparency=1,Position=origin+Vector3.new(0,.3,0)})
  mist=scope:Emitter(bed,{Texture=Kit.Textures.Smoke,Rate=0,Color=ColorSequence.new(EMBER,C(6,0,0)),
   LightEmission=0,Lifetime=NumberRange.new(2,3),Speed=NumberRange.new(.3,1),SpreadAngle=Vector2.new(60,60),
   Size=NumberSequence.new(2,5),Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,1),NumberSequenceKeypoint.new(.35,.5),NumberSequenceKeypoint.new(1,1)})})
  local count=low and 2 or 4
  for i=1,count do
   local angle=(i-.5)/count*math.pi*2
   local l=scope:Light(scope:Anchor(origin+Vector3.new(math.cos(angle)*12,8.5,math.sin(angle)*12),'Lamp'),WARM,18,0)
   table.insert(own,l)
   table.insert(lamps,{Object=l,Color=WARM,Off=BLACK})
  end
 end
 local function lampsTo(state)
  for _,lamp in ipairs(lamps)do
   if lamp.Object.Parent then lamp.Object.Color=state=='off'and lamp.Off or state=='red'and RED or lamp.Color end
  end
 end
 local function stageIn(seconds)
  for _,rune in ipairs(runes)do Kit.Tween(rune,seconds,{Transparency=0})end
  if mist then mist.Rate=low and 2 or 5 end
  for _,l in ipairs(own)do Kit.Tween(l,seconds,{Brightness=1.2})end
 end

 -- The island: the sun drops away in two seconds into a moonless black with a blood-red
 -- haze, and comes back over 3.2 s once it is over.
 film:Sky({
  Lighting={ClockTime=0,Brightness=.5,ExposureCompensation=-.45,Ambient=C(16,3,5),OutdoorAmbient=C(54,12,14),
   EnvironmentDiffuseScale=.12,EnvironmentSpecularScale=.12,ColorShift_Top=C(110,16,16)},
  Atmosphere={Density=.44,Offset=.2,Color=C(126,18,18),Decay=C(36,0,4),Glare=0,Haze=2.6},
  Sky={StarCount=0,CelestialBodiesShown=false},
  Clouds={Cover=.8,Density=.5,Color=C(60,8,10)},
  Bloom={Intensity=.9,Size=30,Threshold=.95},
 },fresh and 2.2 or .4,3.2)
 -- Every light in the district goes black (at once on Low: no fade loop over every light)...
 film:TintLights(BLACK,(low or not fresh)and 0 or 1.6)
 -- ...and every warm lamp glass, lantern and tongue guide around the yards dies (the
 -- tongue's guides bleed red instead: a line to the mouth). The tongue and the head now
 -- (before anything of ours turns Neon there: the runes, the giant pupils), the bigger
 -- folders a frame each after.
 task.spawn(function()
  local world=workspace:FindFirstChild('DOGROTS_District')
  for i,name in ipairs(low and {'03_DogLine','02_DogFactory'}or {'03_DogLine','02_DogFactory','04_PlayerYards','01_IslandAndStreets','33_DogExpress'})do
   if not film.Alive then return end
   local folder=world and world:FindFirstChild(name)
   for _,o in ipairs(folder and folder:GetDescendants()or {})do
    if o:IsA('BasePart')and o.Material==Enum.Material.Neon and o.Name~='MouthRune'and o.Name~='Pupil'
     and (o.Position-Kit.Map.Center).Magnitude<280 then
     film:Override(o,{Color=o.Name=='WarmEdgeGuide'and C(70,0,0)or C(16,9,9)})
    end
   end
   if i>=2 then task.wait()end
  end
 end)
 -- A red mist hangs low around every player, wherever they are.
 film:Rain({Texture=Kit.Textures.Smoke,Color=ColorSequence.new(C(110,8,8),C(26,0,2)),LightEmission=.2,LightInfluence=0,
  Size=NumberSequence.new(10,18),Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,1),NumberSequenceKeypoint.new(.35,.86),NumberSequenceKeypoint.new(1,1)}),
  Speed=NumberRange.new(.5,1.4),Lifetime=NumberRange.new(5,7),Rate=9,Area=140,Height=-3,SpreadAngle=Vector2.new(30,30),
  Rotation=NumberRange.new(0,360),RotSpeed=NumberRange.new(-10,10)})

 -- A sick white light straight down on the stage: on for the act, it pops on every skip.
 local top=origin+Vector3.new(0,13,0)
 local stage=scope:Part({Name='StageLamp',Size=Vector3.one*.2,Transparency=1,CFrame=Kit.LookAt(top,origin)})
 local spot=Instance.new('SpotLight')
 spot.Face=Enum.NormalId.Front;spot.Angle=70;spot.Range=22;spot.Color=SICK;spot.Brightness=0;spot.Shadows=not low
 spot.Parent=stage
 -- The fade can outlast its 0.4 for a slightly late client: the first pop cancels it.
 local lampIn:any=nil

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

 -- Its double on the stage: a frozen copy in black Neon (unlit, so a pure silhouette),
 -- shown for two frames per skip. Made on first use, again if the dog had not streamed in.
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

 ---------------------------------------------------------------- the whole island
 -- Glowing red eyes: a BillboardGui on `adornee` (a part, or a bone so they follow a
 -- head), one eye or a pair, w×h studs plus a few pixels so far ones still show; `toward`
 -- pulls them toward the camera, clear of the face they sit on.
 local glows:{BillboardGui}={}
 local function redEyes(adornee:Instance,w:number,h:number,pair:boolean,toward:number,raise:number):BillboardGui
  local gui=Instance.new('BillboardGui');gui.Name='RedEyes';gui.Adornee=adornee
  gui.LightInfluence=0;gui.Brightness=2.5;gui.AlwaysOnTop=false;gui.MaxDistance=low and 200 or 420
  gui.Size=UDim2.new(w,pair and 9 or 3,h,3);gui.StudsOffset=Vector3.new(0,raise,toward)
  for _,x in ipairs(pair and {.17,.83}or {.5})do
   local f=Instance.new('Frame');f.Name='Eye';f.BorderSizePixel=0;f.BackgroundColor3=RED
   f.AnchorPoint=Vector2.new(.5,.5);f.Position=UDim2.fromScale(x,.5);f.Size=UDim2.fromScale(pair and .34 or 1,1)
   local round=Instance.new('UICorner');round.CornerRadius=UDim.new(.5,0);round.Parent=f
   f.Parent=gui
  end
  gui.Parent=film.Folder
  return gui
 end
 -- Eyes opening from a slit, after `delay` seconds.
 local function wake(gui:BillboardGui,delay:number)
  local full=gui.Size
  gui.Size=UDim2.new(full.X.Scale,full.X.Offset,0,0)
  TweenService:Create(gui,TweenInfo.new(.16,Enum.EasingStyle.Quad,Enum.EasingDirection.Out,0,false,delay),{Size=full}):Play()
 end
 -- Every dog on the island (the tongue, the kennels, the yard showcases and best finds,
 -- other Secrets on show) with the bone its eyes ride, nearest this camera first.
 local function islandDogs():{{Head:Bone,Tall:number,Distance:number}}
  local found={}
  local camera=workspace.CurrentCamera
  local from=camera and camera.CFrame.Position or Kit.Me()
  local function add(m:Instance?)
   if not m or m==model or not m:IsA('Model')then return end
   for _,name in ipairs({'Head','head','Head_C'})do
    local bone=m:FindFirstChild(name,true)
    if bone and bone:IsA('Bone')then
     local v=m:GetAttribute('VisualSize')
     table.insert(found,{Head=bone,Tall=typeof(v)=='Vector3'and v.Y or 6,Distance=(bone.TransformedWorldCFrame.Position-from).Magnitude})
     return
    end
   end
  end
  local world=workspace:FindFirstChild('DOGROTS_District')
  local belt=world and world:FindFirstChild('03_DogLine')
  local active=belt and belt:FindFirstChild('ActiveDogs')
  for _,m in ipairs(active and active:GetChildren()or {})do if m:GetAttribute('DogId')then add(m)end end
  local kennels=world and world:FindFirstChild('KennelDogs')
  for _,m in ipairs(kennels and kennels:GetChildren()or {})do add(m)end
  local yards=world and world:FindFirstChild('04_PlayerYards')
  for _,yard in ipairs(yards and yards:GetChildren()or {})do
   local storage=yard:FindFirstChild('DogStorage')
   local slots=storage and storage:FindFirstChild('DisplaySlots')
   for _,slot in ipairs(slots and slots:GetChildren()or {})do add(slot:FindFirstChild('DisplayDog'))end
   local finds=yard:FindFirstChild('BestFinds',true)
   local shelf=finds and finds:FindFirstChild('Slots')
   local exhibit=shelf and shelf:FindFirstChild('Dog')
   add(exhibit and exhibit:FindFirstChild('Exhibit'))
  end
  local reveals=workspace:FindFirstChild('DOGROTS_SecretReveals')
  for _,m in ipairs(reveals and reveals:GetChildren()or {})do add(m)end
  table.sort(found,function(a,b)return a.Distance<b.Distance end)
  return found
 end
 -- 1.9: every dog's eyes open red, nearest you first, and every dog turns to look at you;
 -- eyes blink open in the dark around you; the giant head's pupils ignite.
 local pupils:{any}={}
 local glance:any=nil
 local function wakeIsland(onTime:boolean)
  for i,dog in ipairs(islandDogs())do
   if i>(low and 20 or 60)then break end
   local h=dog.Tall
   local gui=redEyes(dog.Head,h*.19,h*.075,true,h*.32,h*.06)
   table.insert(glows,gui)
   if onTime then wake(gui,dog.Distance/170)end
  end
  local me=Kit.Me()
  local params=rays()
  for _=1,low and 4 or 10 do
   local a,r=Kit.Random(0,math.pi*2),Kit.Random(16,70)
   local at=me+Vector3.new(math.cos(a)*r,0,math.sin(a)*r)
   local hit=workspace:Raycast(at+Vector3.new(0,40,0),Vector3.new(0,-80,0),params)
   local gui=redEyes(film:Anchor((hit and hit.Position or at)+Vector3.new(0,Kit.Random(1.8,3.6),0),'DarkEyes'),.95,.36,true,0,0)
   table.insert(glows,gui)
   if onTime then wake(gui,Kit.Random(.3,4.5))end
  end
  glance=film:Glance(function()
   local camera=workspace.CurrentCamera
   return camera and camera.CFrame.Position
  end,{Exclude=model,Turn=.45,Ripple=180})
  -- The giant head the tongue comes out of opens red eyes too (seen from every yard).
  local world=workspace:FindFirstChild('DOGROTS_District')
  local works=world and world:FindFirstChild('02_DogFactory')
  local giant=works and works:FindFirstChild('THE_DOG')
  for _,o in ipairs(giant and giant:GetChildren()or {})do
   if o:IsA('BasePart')then
    if o.Name=='Pupil'then
     local home,color,material=o.CFrame,o.Color,o.Material
     local _,_,set=film:Override(o,{Color=RED,Material=Enum.Material.Neon,CFrame=home})
     table.insert(pupils,{Set=set,Home=home,Color=color,Material=material,Left=home.Position.X<0})
    elseif o.Name=='WarmIris'then film:Override(o,{Color=C(12,0,0)})
    elseif o.Name=='EyeCatchlight'or o.Name=='EyeSmallLight'then film:Override(o,{Transparency=1})end
   end
  end
 end
 -- The colossus: a black silhouette of it, 270 studs tall and rimmed red, beyond the stage
 -- as each player sees it. A camera only sees ~20 degrees above the horizon, so every
 -- stance is placed from the camera looking: its eyes `reach` studs out on the line from
 -- the camera to the stage, 20 degrees up (on the tongue, clear of the giant head's crown
 -- from there), the rest of it sunk behind the head or below the horizon; yaw from facing
 -- that camera. Its eyes are .49 of its height ahead of its middle and .4 above.
 local colossus:any=nil
 local rim:any=nil
 local giantEyes:{BillboardGui}={}
 local crown=Kit.Map.Head+Vector3.new(0,28,0)
 local function eyePoint():Vector3
  local camera=workspace.CurrentCamera
  return camera and camera.CFrame.Position or Kit.Me()
 end
 local function loom(eye:Vector3,reach:number,yaw:number,lean:number,tilt:number?):CFrame
  local flat=Vector3.new(origin.X-eye.X,0,origin.Z-eye.Z)
  local dir=flat.Magnitude>24 and flat.Unit or away
  local up=math.tan(math.rad(20))
  if not open then
   local d=Vector3.new(crown.X-eye.X,0,crown.Z-eye.Z).Magnitude
   up=math.clamp((crown.Y-eye.Y)/math.max(d,1)+.08,up,math.tan(math.rad(34)))
  end
  local p=eye+dir*(reach+TALL*.49)+UP*(reach*up-TALL*.4)
  return CFrame.lookAt(p,p-dir)*CFrame.Angles(0,yaw,0)*CFrame.Angles(-(tilt or 0),0,lean)
 end
 local function rise(late:boolean)
  colossus=film:Colossus({Ctx=ctx,Height=TALL,At=loom(eyePoint(),RISEN,math.pi,0),Style='Silhouette',Color=C(4,0,0),Clip='EXP_Stare',
   Rise=late and 0 or 160,FadeIn=late and .3 or 2.4})
  if not colossus then return end
  rim=film:Highlight(colossus.Model,BLACK,C(160,0,0),1,.3)
  for _,name in ipairs({'Eye.L','Eye.R'})do
   local bone=colossus.Model:FindFirstChild(name,true)
   if bone then
    local gui=redEyes(bone,TALL*.045,TALL*.045,false,TALL*.03,0)
    gui.MaxDistance=math.huge
    table.insert(giantEyes,gui)
   end
  end
 end
 -- Your double: a black copy of it (from the menu model, so it exists wherever you are),
 -- taller than you, red-eyed, standing in the dark facing your camera.
 local mine:any=nil
 local mineHead:Bone?=nil
 local mineEyes:{BillboardGui}={}
 local function myDouble():any
  if mine then return mine end
  local copy=Kit.DogCopy('WrongDog',model)
  if not copy then return nil end
  local _,box=Kit.Bounds(copy)
  pcall(function()copy:ScaleTo(copy:GetScale()*7.5/math.max(box.Y,.1))end)
  for _,o in ipairs(copy:GetDescendants())do
   if o:IsA('SurfaceAppearance')or o:IsA('Decal')or o:IsA('Texture')then o:Destroy()
   elseif o:IsA('BasePart')then
    o.Material=Enum.Material.Neon;o.Color=BLACK;o.LocalTransparencyModifier=1
    if o:IsA('MeshPart')then local mesh=o::MeshPart;pcall(function()mesh.TextureID=''end)end
   end
  end
  local head=copy:FindFirstChild('Head',true)
  mineHead=if head and head:IsA('Bone')then head else nil
  for _,name in ipairs({'Eye.L','Eye.R'})do
   local bone=copy:FindFirstChild(name,true)
   if bone then
    local gui=redEyes(bone,.42,.42,false,.5,0)
    gui.Enabled=false
    table.insert(mineEyes,gui)
   end
  end
  copy.Parent=film.Folder
  mine=copy
  return copy
 end
 -- cf: where it stands (nil hides it); tilt: its head, about its own line of sight.
 local function showDouble(cf:CFrame?,tilt:number)
  local copy=if cf then myDouble()else mine
  if not copy then return end
  if cf then
   copy:PivotTo(cf)
   local head=mineHead
   if head then
    head.Transform=CFrame.identity
    head.Transform=CFrame.fromAxisAngle(head.TransformedWorldCFrame:VectorToObjectSpace(cf.LookVector),tilt)
   end
  end
  Kit.SetGhostAlpha(copy,cf and 0 or 1)
  for _,gui in ipairs(mineEyes)do gui.Enabled=cf~=nil end
 end
 -- Where your double stands: `ahead` studs beyond you along your camera's view (negative:
 -- between you and your camera), `right` to the side; on the ground, short of any wall,
 -- facing your camera.
 local function stand(ahead:number,right:number):CFrame?
  local camera=workspace.CurrentCamera
  if not camera then return nil end
  local l=camera.CFrame.LookVector
  local forward=Vector3.new(l.X,0,l.Z)
  forward=forward.Magnitude>.01 and forward.Unit or Vector3.zAxis
  local params=rays()
  local from=Kit.Me()+Vector3.new(0,2,0)
  local goal=from+forward*ahead+forward:Cross(UP)*right
  local hit=workspace:Raycast(from,goal-from,params)
  if hit then goal=from+(goal-from).Unit*math.max(hit.Distance-2.5,1.5)end
  local down=workspace:Raycast(goal+Vector3.new(0,5,0),Vector3.new(0,-40,0),params)
  local feet=down and down.Position or goal-Vector3.new(0,5,0)
  local back=camera.CFrame.Position-feet
  back=Vector3.new(back.X,0,back.Z)
  return CFrame.lookAt(feet,feet+(back.Magnitude>.5 and back.Unit or -forward))
 end
 -- A skip on the island: your double nearer, the colossus in another wrong stance (nearer
 -- too), the giant head's pupils looking the wrong ways.
 local function wrongAgain(i:number)
  local d=DOUBLE[i]
  showDouble(stand(d[1],d[2]),d[3])
  local s=STANCE[i]
  if colossus then colossus:Pose(loom(eyePoint(),s[1],s[2],s[3]),0)end
  local g=GAZE[i]
  for _,p in ipairs(pupils)do p.Set('CFrame',p.Home+Vector3.new(p.Left and g[1]or g[2],g[3],0))end
 end
 -- 7.4: every eye on the island shuts at once; the colossus and your double are gone; the
 -- giant pupils die.
 local function lightsOut()
  for _,gui in ipairs(glows)do gui.Enabled=false end
  for _,gui in ipairs(giantEyes)do gui.Enabled=false end
  if colossus then colossus:Fade(1,0)end
  if rim then rim.Enabled=false end
  showDouble(nil,0)
  for _,p in ipairs(pupils)do p.Set('Color',p.Color);p.Set('Material',p.Material)end
 end
 -- 7.8: all of them open again, on you. The colossus is back, nearer than ever, leaning in
 -- over the stage and turning to your camera; the giant pupils follow it (the stare loop
 -- keeps both on you).
 local gazeOf:any=nil
 local function allEyesOnYou()
  for _,gui in ipairs(glows)do gui.Enabled=true end
  for _,gui in ipairs(giantEyes)do gui.Enabled=true end
  if rim then rim.Enabled=true end
  if colossus then
   colossus:Pose(loom(eyePoint(),LEAN,0,0,.22),0);colossus:Fade(0,0);colossus:Play('UnstableEvent',false)
   if colossus.Animator then
    gazeOf={Target=origin,Body=1,Head=1}
    colossus.Animator.Look=gazeOf
   end
  end
  for _,p in ipairs(pupils)do p.Set('Color',RED);p.Set('Material',Enum.Material.Neon)end
 end
 -- 9.9: handed back to your own camera, your double is right behind you.
 local function behindYou()
  local camera=workspace.CurrentCamera
  if not camera then return end
  local me,c=Kit.Me(),camera.CFrame.Position
  local back=Vector3.new(c.X-me.X,0,c.Z-me.Z).Magnitude
  -- Third person: between you and your camera. First person: right in front of you.
  showDouble(stand(back>3 and -math.min(back*.55,7)or 6,0),.3)
 end
 -- The climax pulls every camera (Takeover skips ReducedMotion, busy cameras, open menus):
 -- wide over the dark island toward the stage and the colossus behind it as everything
 -- goes out (high enough to clear the roofs round any venue, with both the stage and the
 -- colossus's head in frame), then a hard cut into its face as it turns to the lens, a
 -- slow push to its eyes; handed back at 9.7.
 local across=away:Cross(UP)
 local level=origin+UP*size.Y*.85
 local wide=origin-away*190+across*40+UP*70
 local cut=ctx:Cutaway({
  {At=ACT+1.75,CFrame=Kit.Frame(wide,origin+away*130+UP*120),Fov=70},
  {At=STARE-.02,CFrame=Kit.Frame(origin-away*174+across*36+UP*66,origin+away*130+UP*116),Fov=64,Linear=true},
  {At=STARE,CFrame=Kit.Frame(origin-away*8.5+UP*size.Y*.7,level),Fov=46,Cut=true},
  {At=ACT+4.3,CFrame=Kit.Frame(origin-away*6+UP*size.Y*.78,level),Fov=40,Linear=true},
 },{Focus=origin,Bars=.11,Shake=.1})

 local phase='film'
 local beatAt=-math.huge
 -- A vignette for everyone that closes in the dark and beats red with the heart during
 -- the stare.
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
  local a,color=.42*math.min((os.clock()-opened)/(fresh and .6 or .1),1),BLACK
  if phase=='dark'then a=.95
  elseif phase=='stare'then a=.55+.35*math.exp(-(os.clock()-beatAt)*4);color=EMBER end
  for _,f in ipairs(edges)do f.BackgroundTransparency=1-a;f.BackgroundColor3=color end
  return true
 end)
 -- From the dark on it faces this client's camera, every frame, without easing. Its
 -- gaze ends just in front of the lens; the heart keeps time; the colossus and the giant
 -- head's pupils follow the camera too.
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
   if camera then
    local at=camera.CFrame.Position
    if gazeOf then gazeOf.Target=at end
    for _,p in ipairs(pupils)do
     local d=(at-p.Home.Position).Unit
     p.Set('CFrame',p.Home+Vector3.new(math.clamp(d.X*3.5,-2,2),math.clamp(d.Y*3.5,-1.5,1.5),0))
    end
   end
  end
  return true
 end)

 -- 0.35-1.5: the island's lights die, one relay at a time.
 for i,t in ipairs(DIE)do
  if not ctx:Wait(t)then return end
  if live(t)then click(.9-i*.08,.5)end
 end
 -- 1.9: every eye on the island opens; every dog turns to look at you.
 if not ctx:Wait(OPEN)then return end
 wakeIsland(live(OPEN))
 if live(OPEN)then Kit.Cue('Heartbeat',nil,.6);Kit.Cue('Sting',nil,.3)end
 -- 2.6: behind the stage something very tall rises, its back to the island.
 if not ctx:Wait(RISE)then return end
 rise(not live(RISE))
 if live(RISE)then Kit.Cue('Impact',nil,.6);Kit.Cue('Sting',nil,.4)end
 for _,t in ipairs(HEART)do
  if not ctx:Wait(t)then return end
  if live(t)then Kit.Cue('Heartbeat',nil,.55)end
 end

 -- 5.4: its act, on the only lit place left on the island, facing into the throat.
 if not ctx:Wait(ACT)then return end
 vis.Set(0)
 lampsTo('home')
 stageIn(live(ACT)and .6 or .1)
 if live(ACT)then lampIn=Kit.Tween(spot,.35,{Brightness=LAMP});Kit.Cue('Sting',nil,.4)else spot.Brightness=LAMP end
 -- 5.8-7.0: the film skips. Each cut: a new wrong stance, the light pops, the double
 -- stands in it (beside, the other side, peeking from behind, then in front of you); and
 -- on the island your own double, the colossus and the giant head skip with it.
 for i,c in ipairs(CUTS)do
  if not ctx:Wait(c[1])then return end
  pose(c[2],c[3],c[4])
  wrongAgain(i)
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
   -- The whole island's film skips: a pale pop for everyone, harder near the stage.
   if not calm then Kit.Flash(PALE,.86-.3*Kit.Near(origin,120),.14)end
   Kit.Cue('Heartbeat',nil,.4+i*.1)
   click(.62+i*.06,.55)
  end
 end
 -- 7.2: those pulled into the cutaway see the colossus from its wide shot.
 if not ctx:Wait(ACT+1.8)then return end
 local pulled=cut~=nil and cut.Active
 if pulled and colossus then colossus:Pose(loom(wide,STANCE[4][1],0,0),0)end

 -- 7.4: lights out everywhere. Silence; it is gone, every eye is gone; it turns to you in
 -- the dark.
 if not ctx:Wait(DARK)then return end
 if live(DARK)then
  phase='dark'
  vis.Set(1)
  spot.Brightness=0
  lampsTo('off')
  lightsOut()
  grade.Brightness=open and -.38 or -.3;grade.Contrast=.3
  -- A tween, so it also cancels a late client's fade-in still running.
  if drone then Kit.Tween(drone,.05,{Volume=0})end
  click(.5,.7)
 end
 -- 7.6: two red eyes open where it was.
 if not ctx:Wait(EYES)then return end
 if phase=='dark'and live(EYES)then
  for _,e in ipairs(eyes)do
   if e.Light then Kit.Tween(e.Light,.15,{Brightness=2.5})end
   e.Glint:Emit(low and 2 or 5)
  end
  Kit.Cue('Heartbeat',nil,.35)
 end

 -- 7.8: it is looking at you. Only you. So is everything else.
 if not ctx:Wait(STARE)then return end
 phase='stare'
 ctx.WhisperStyle={Font=Enum.Font.Garamond,Color=C(255,76,76),Glitch=.12,Chroma=true,Shake=false,Type=.07}
 vis.Set(0)
 spot.Brightness=0
 lampsTo('red')
 grade.Brightness=-.04;grade.Contrast=.26;grade.Saturation=-.3
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
 allEyesOnYou()
 if live(STARE)then
  beatAt=os.clock()
  Kit.Cue('Impact',nil,.85);Kit.Cue('Sting',nil,.75);Kit.Cue('Glitch',eyes[1].Anchor,.35)
  -- The jump, for everyone wherever they stand (the cutaway shakes its own camera).
  Kit.Flash(C(150,0,8),.3,.7)
  Kit.Shake(.35,.35)
  Kit.FOVPunch(-7,math.max(.5,RELEASE-ctx:Elapsed()),.3)
  if cut and cut.Active then cut:Shake(1.2,.45)end
 end
 -- 9.9: back in your own camera, it is standing right behind you (and the colossus is
 -- where you can see it again).
 if not ctx:Wait(BEHIND)then return end
 behindYou()
 if pulled and colossus then colossus:Pose(loom(eyePoint(),LEAN,0,0,.22),0)end
 if live(BEHIND)then Kit.Cue('Heartbeat',nil,.9);click(.45,.6)end

 -- 11.0: as if nothing happened. The lights come back on all over the island, every eye
 -- and your double are gone, the sky eases back to day; it lands, facing down the line
 -- (on a pad: the opener); the name comes up.
 if not ctx:Wait(RELEASE)then return end
 phase='done'
 if colossus then colossus:Stop(0)end
 if glance then glance:Stop(.4)end
 film:Clean()
 pose(0,0,0)
 eyesTo(0)
 for _,e in ipairs(eyes)do e.Glint.Rate=0 end
 lampsTo('home')
 if open then
  -- Our own lamps were never there: they go with the grade.
  if mist then mist.Rate=0 end
  for _,l in ipairs(own)do Kit.Tween(l,.8,{Brightness=0})end
 end
 Kit.Tween(grade,.8,{Brightness=0,Contrast=0,Saturation=0,TintColor=Color3.new(1,1,1)})
 if drone then drone.Volume=0 end
 ctx:Title({Font=Enum.Font.Garamond,Hold=3.8})
 if live(RELEASE)then
  Kit.Cue('Chime',nil,.3);click(1.2,.4)
  if not calm then Kit.Flash(PALE,.6,.3)end
 end
 -- 11.55: its eyes, once more, for two frames.
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
