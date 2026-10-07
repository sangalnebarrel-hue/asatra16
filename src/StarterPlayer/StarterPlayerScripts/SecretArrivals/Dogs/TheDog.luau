-- THE DOG, "THE ECLIPSE". The rarest arrival (about 1 in 95,000 line dogs), so the whole
-- island stops, wherever each player stands (the far north's plaza, museum, lab and
-- DOG-O-MATIC included):
--  0     the music dies and a heartbeat starts; TOTAL ECLIPSE crosses every screen while
--        something black slides over the sun (the moon at night) and the light thins.
--  1     every light and every lamp's glass in the district dies, in a wave out from the
--        stage (it reaches the DOG-O-MATIC about 5 s later).
--  4.4   totality: the sun is swallowed, the sky goes black with a red horizon, only the
--        corona is left and pale motes rise around every player.
--  4.9   every dog on the island turns to the mouth (the giant head's own eyes roll down).
--  6     the black sun opens: it is an eye, and it drifts across the sky to stay in front
--        of each camera ("do not look away.") until it blinks shut.
--  7.4   a colossal black THE DOG rises over the horizon behind the stage (behind the giant
--        head, seen from the yards; players far up north see it rise in their own sky over
--        the island, toward the stage); something invisible walks past each player to the
--        stage, leaving glowing pawprints and thuds.
--  10.4  the colossus opens its eyes and follows each camera; every camera is pulled from
--        the sky down into the mouth (the one cutaway, 10.6-15.5) while the ground opens
--        (11.4) and THE DOG rises: candles, glints, the hole, the pillar.
--  14.2  THE DOG across every screen; a wall of white light races out from the stage over
--        the whole district and jolts every player it passes; every dog bows (15.4).
--  18.6  dawn: the colossus sinks, the corona burns back into the sun, and from 20.8 the
--        lights come back in a wave out from the stage; it walks at 24 (Hold).
-- While a world event is near, the sky stays the server's: no black sun, the eclipse is a
-- darkening of each camera's picture instead (Scope:Sky).
-- Every dog keeps staring while it walks the tongue (StareSeconds), as before.
-- SecretArrivalConfig.Dogs.TheDog agrees with T: Hold 24, Ground_Opens at T.Ground (11.4),
-- Pet_Reaction 2.6 s later (14.0), Stand_Idle 2.8 s after that (16.8); its whispers sit on
-- the beats below and its Banner is the first one (TOTAL ECLIPSE).
local C=Color3.fromRGB
local Players=game:GetService('Players')
local Lighting=game:GetService('Lighting')
local RS=game:GetService('ReplicatedStorage')
-- How far each part of a giant eye rolls with the gaze (the iris half as far).
local EYE={Pupil=1,EyeCatchlight=1,EyeSmallLight=1,WarmIris=.5}
-- Shared by overlapping THE DOGs: the eyes' true rest (first CFrame ever seen), and the
-- arrivals still watching (the newest one drives the eyes).
local homes,easing=setmetatable({},{__mode='k'}),setmetatable({},{__mode='k'})
local watchers={}
-- The act on the arrival clock (seconds after SecretArrivalAt).
local T={Fall=.3,Banner=.4,Blackout=1,Total=4.4,Stare=4.9,Open=6,Watch=6.7,Rise=7.4,Candles=7.6,Steps=7.8,
 Glint=9.2,Shut=9.4,Gaze=10.4,Cut=10.6,Ground=11.4,Arrive=14.2,Bow=15.4,Dawn=18.6}
-- Lamp glass that goes dark with the lights, anywhere in the district (lanterns, lenses,
-- bulbs, the museum's display and step lights, the lab's lenses, the DOG-O-MATIC's
-- marquee...): Neon parts with one of these in their name. The tongue's guides and the
-- mouth's runes go dark their own way below; the portal and signs stay lit.
local LAMP_WORDS={'Lamp','Lantern','Light','Glass','Lens','Bulb','Glow','Warm','Canopy','Diffuser','Sconce'}
local NOT_LAMPS={WarmEdgeGuide=true,MouthRune=true,Pupil=true}
local lampNames={}
local function isLamp(part:BasePart):boolean
 local name=part.Name
 local known=lampNames[name]
 if known==nil then
  known=false
  if not NOT_LAMPS[name]and string.sub(name,1,6)~='Portal'then
   for _,word in ipairs(LAMP_WORDS)do if string.find(name,word,1,true)then known=true;break end end
  end
  lampNames[name]=known
 end
 return known
end
-- Players this far (studs, flat) from the stage see the colossus in their own sky; nearer
-- ones see it stand behind the giant head (with some slack so walking does not flip it).
local FAR,NEAR=400,320
local UP=Vector3.yAxis
-- Turns a cylinder's axis (X) toward the camera (Z).
local FACING=CFrame.Angles(0,math.pi/2,0)
-- The black sun hangs this far from each camera, this big (12 degrees across).
local SUN,SUN_R=300,32
-- The colossus: studs tall; its face stands this far beyond the stage.
local GIANT,GIANT_OUT=320,250
local function smooth(x)x=math.clamp(x,0,1);return x*x*(3-2*x)end
-- "1 IN 95,000" from the tongue's odds (nil when they cannot be read).
local function odds():string?
 local ok,n=pcall(function()
  local econ=require((RS:FindFirstChild('DogEconomy')::any).Config)
  return 100/econ.Weights[#econ.Weights]*1000/econ.SecretLineWeights.TheDog
 end)
 if not ok or type(n)~='number'or n~=n or n==math.huge or n<2 then return nil end
 local s=string.format('%d',n>=10000 and math.floor(n/1000+.5)*1000 or math.floor(n+.5))
 repeat local k;s,k=string.gsub(s,'^(%d+)(%d%d%d)','%1,%2')until k==0
 return '1 IN '..s
end
return function(ctx)
 ctx.ManualWhispers=true
 ctx.ManualBanner=true
 local Kit,W,scope,model,config=ctx.Kit,ctx.Whisper,ctx.Scope,ctx.Model,ctx.Config
 local low=ctx.Low
 -- ReducedMotion: no flashes (Kit already drops shakes, FOV punches and the cutaway).
 local calm=Kit.ReducedMotion()
 local lines=config.Whispers
 local size=Kit.Size(model)
 local hold=config.Hold
 local origin=ctx.Origin
 local onTongue=(ctx.Venue or 'Tongue')=='Tongue'
 local near=Kit.Near(origin,160)
 local function live(t)return ctx:Elapsed()-t<.35 end
 -- Joined before the ground opened: sees it rise. Later: it is already standing there.
 local intro=ctx.Late<T.Ground-.5
 local start=ctx:Elapsed()
 -- Map scale: `away` points from the island's centre out through the stage (into the
 -- giant head on the tongue). The colossus stands out there, facing back.
 local hub=Kit.Map.Center
 local away=Vector3.new(origin.X-hub.X,0,origin.Z-hub.Z)
 away=away.Magnitude>20 and away.Unit or Vector3.new(0,0,-1)
 -- The rise (cinema bars, the hidden dog, candles, the hole) ends when it starts to walk.
 local act=Kit.Scope('Arrival_TheDog_Rise')
 scope:Add(function()act:Clean()end)
 local function where()
  if not model.Parent then return nil end
  return ctx:Ground()+Vector3.new(0,size.Y*.6,0)
 end

 -- The whispers: a late client gets the line of the moment at once, the rest on schedule.
 -- "do not look away." (3) is typed slowly and breathes; "it was never a pet." (5)
 -- glitches; the last line stays, breathing, while it walks.
 local STYLE={[3]={Type=.09,Breathe=2.2},[5]={Glitch=.08}}
 local LAST={Type=.12,Breathe=3}
 task.spawn(function()
  local first=1
  for i,l in ipairs(lines)do if l[1]<=ctx:Elapsed()then first=i end end
  for i=first,#lines do
   if not ctx:Wait(lines[i][1])then return end
   if not(lines[i+1]and ctx:Elapsed()>=lines[i+1][1])then
    local style=table.clone(STYLE[i]or {})
    if i==#lines then for k,v in pairs(LAST)do style[k]=v end end
    local said=ctx:Say(lines[i][2],{Font=Enum.Font.SpecialElite,Color=C(240,236,250),Glitch=style.Glitch,
     Type=live(lines[i][1])and(style.Type or .06)or 0})
    if style.Breathe then W.Breathe(said,style.Breathe)end
   end
  end
 end)

 -- The whole island holds its breath.
 scope:Duck(0,2.5)
 local drone=scope:Drone('Drone',low and .35 or .55,.42,3)
 local grade=scope:Grade({Saturation=-.5,Contrast=.28,Brightness=-.04,TintColor=C(240,232,236)},intro and 3 or .5)
 -- Every dog on the island turns to it (from totality on).
 local stare
 local function turnAll()
  if stare then return end
  stare=ctx.Stare.Begin(where,{Exclude=model,Turn=1.1,Ripple=140})
  scope:Add(function()stare:Stop(1.4)end)
 end

 -- The giant head's pupils roll down to its own tongue and follow THE DOG. Every part of
 -- one eye rolls about the same centre (its pupil's, a stud inward).
 local eyes,centre={},{}
 local function adopt(part)
  local share=EYE[part.Name]
  if not share or not part:IsA('BasePart')then return end
  for _,e in ipairs(eyes)do if e.Part==part then return end end
  if easing[part]then easing[part]:Cancel();easing[part]=nil end
  local home=homes[part]or part.CFrame
  homes[part]=home
  local side=home.Position.X<0 and -1 or 1
  if part.Name=='Pupil'then centre[side]=home.Position-Vector3.new(side,0,0)end
  table.insert(eyes,{Part=part,Home=home,Share=share,Side=side})
 end
 table.insert(watchers,scope)
 -- They roll back as the stare lets go (unless another THE DOG still holds them).
 scope:Add(function()
  local i=table.find(watchers,scope)
  if i then table.remove(watchers,i)end
  if #watchers>0 then return end
  for _,e in ipairs(eyes)do
   if e.Part.Parent then easing[e.Part]=Kit.Tween(e.Part,1.4,{CFrame=e.Home},Enum.EasingStyle.Sine,Enum.EasingDirection.InOut)
   else e.Part.CFrame=e.Home end
  end
 end)
 local look=0
 scope:Every(function(dt)
  if not stare then return true end
  look=math.min(1,look+dt/2.5)
  local target=where()
  if not target or watchers[#watchers]~=scope then return true end
  local eased=look*look*(3-2*look)
  for _,e in ipairs(eyes)do
   if e.Part.Parent then
    local d=(target-(centre[e.Side]or e.Home.Position-Vector3.new(e.Side,0,0))).Unit
    local offset=Vector3.new(d.X,d.Y,0)*3.2
    if offset.Magnitude>3 then offset=offset.Unit*3 end
    e.Part.CFrame=e.Home+offset*e.Share*eased+Vector3.new(0,0,.05)
   end
  end
  return true
 end)

 -- The tongue's warm lights die from the mouth outward with the rest of the island; each
 -- comes back once THE DOG has passed it (its own layer released, so an overlapping
 -- arrival's tint still shows).
 local seen,dark,reach={},{},-math.huge
 local function darken(g)
  if not scope.Alive or dark[g]or g.Position.Z<reach then return end
  local _,release=scope:Override(g,{Color=C(40,40,46),Material=Enum.Material.SmoothPlastic})
  dark[g]=release
 end
 -- The head, the tongue and the mouth stream in on their own (a late joiner's first
 -- seconds): whatever was missing is picked up on the next look.
 local function scan(first)
  local district=workspace:FindFirstChild('DOGROTS_District')
  local factory=district and district:FindFirstChild('02_DogFactory')
  local head=factory and factory:FindFirstChild('THE_DOG')
  -- (A Studio "here" preview stages it off the tongue: the tongue and mouth stay lit.)
  local mouth=onTongue and factory and factory:FindFirstChild('DarkMouthTunnel')or nil
  local line=onTongue and district and district:FindFirstChild('03_DogLine')or nil
  local tongue=line and line:FindFirstChild('Tongue')
  for _,o in ipairs(head and head:GetChildren()or {})do if EYE[o.Name]then adopt(o)end end
  for _,o in ipairs(mouth and mouth:GetDescendants()or {})do
   if not seen[o]then
    if o.Name=='MouthRune'and o:IsA('BasePart')then seen[o]=true;scope:Override(o,{Color=C(10,10,12)})
    -- WorldDetailQuality owns Enabled and Rate: the mist goes invisible instead.
    elseif o:IsA('ParticleEmitter')then seen[o]=true;scope:Override(o,{Transparency=NumberSequence.new(1)})end
   end
  end
  local fresh={}
  for _,g in ipairs(tongue and tongue:GetChildren()or {})do
   if not seen[g]and g.Name=='WarmEdgeGuide'and g:IsA('BasePart')then seen[g]=true;table.insert(fresh,g)end
  end
  table.sort(fresh,function(a,b)return a.Position.Z<b.Position.Z end)
  for i,g in ipairs(fresh)do
   if first and live(T.Blackout)then task.delay((i-1)*.04,darken,g)else darken(g)end
  end
 end
 task.spawn(function()
  if not ctx:Wait(T.Blackout)then return end
  scan(true)
  while scope.Alive do
   task.wait(2)
   if scope.Alive then scan(false)end
  end
 end)

 ---------------------------------------------------------------- the sky
 -- What gets eclipsed: the sun, else the moon (chosen once, before the clock turns, so a
 -- body near the horizon cannot flip between them), else a spot high over the stage.
 local daylight=Lighting:GetSunDirection().Y>.05
 local eclipsed=daylight and 'Sun'or Lighting:GetMoonDirection().Y>.05 and 'Moon'or nil
 local function body():Vector3
  if eclipsed=='Sun'then return Lighting:GetSunDirection()end
  if eclipsed=='Moon'then return Lighting:GetMoonDirection()end
  return (away+UP*.7).Unit
 end
 local clock=Lighting.ClockTime
 -- Totality: a day goes to deep twilight (the short way round the dial), a night stays.
 -- (Rays: a SunRaysEffect, if the place has one, dies with the sun.)
 local DARK={Lighting={ClockTime=daylight and(clock<12 and 5.1 or 18.9)or clock,Brightness=0,ExposureCompensation=-.3,
   Ambient=C(22,18,26),OutdoorAmbient=C(30,22,30),EnvironmentDiffuseScale=.12,EnvironmentSpecularScale=0},
  Atmosphere={Density=.2,Offset=.3,Color=C(92,14,12),Decay=C(10,3,6),Glare=0,Haze=2.2},
  Clouds={Cover=.55,Density=.4,Color=C(18,12,14)},
  Sky={CelestialBodiesShown=false,StarCount=5000},
  Rays={Intensity=0},
  Bloom={Intensity=1,Size=40,Threshold=.9}}
 -- Until then the light only thins (a borrowed Sky object would show against a bright sky).
 local DIM={Lighting={Brightness=daylight and 1.1 or .45,ExposureCompensation=-.12,Ambient=C(70,70,82),
   OutdoorAmbient=C(86,84,98),EnvironmentSpecularScale=.15},
  Atmosphere={Glare=0,Haze=1.3,Density=.16,Color=C(150,134,136),Decay=C(72,56,62)},
  Clouds={Color=C(118,110,116)},
  Rays={Intensity=0},
  Bloom={Intensity=.45,Size=32,Threshold=1.25}}
 -- (Its world light lets go by itself if a world event turns up: sky.Free goes false.)
 local sky
 if start<T.Dawn then sky=start<T.Total and scope:Sky(DIM,math.max(.6,T.Total-start),4.6)or scope:Sky(DARK,1.2,4.6)end

 ---------------------------------------------------------------- the black sun
 -- A disc slides over the sun from this camera; at totality only the corona is left. It
 -- opens as an eye that drifts across the sky to stay in front of the camera, blinks shut,
 -- and at dawn burns back into the sun right where the real one is about to reappear.
 -- Only while the sky is this arrival's (sky.Free): over the server's own sky (a world
 -- event near) a black disc would hang on a bright day, so it is not made, and it fades
 -- away if an event turns up meanwhile.
 local function ahead(view:CFrame):Vector3
  local l=view.LookVector
  local flat=Vector3.new(l.X,0,l.Z)
  flat=flat.Magnitude>.05 and flat.Unit or away
  local e=math.clamp(math.asin(math.clamp(l.Y,-1,1))+math.rad(13),math.rad(7),math.rad(34))
  return flat*math.cos(e)+UP*math.sin(e)
 end
 if start<T.Dawn+5 and sky and sky.Free then
  local R=SUN_R
  local function disc(name,d,color)
   return scope:Part({Name=name,Shape=Enum.PartType.Cylinder,Size=Vector3.new(.4,d,d),Color=color,Transparency=1})
  end
  local function oval(name,color)
   local p=scope:Part({Name=name,Size=Vector3.new(1,.05,.4),Color=color,Transparency=1})
   local mesh=Instance.new('SpecialMesh');mesh.MeshType=Enum.MeshType.Sphere;mesh.Parent=p
   return p
  end
  local glow,corona,black=disc('SunGlow',R*3.4,C(255,244,232)),disc('Corona',R*2.2,C(255,252,246)),disc('BlackSun',R*2,C(0,0,0))
  local eye,pupil=oval('SkyEye',C(255,255,255)),oval('SkyPupil',C(0,0,0))
  local parts,frames={glow,corona,black,eye,pupil},{}
  -- held: the sun at totality. The day clock keeps turning under the eclipse, so its drift
  -- (measured while the disc slides over it) tells where it will be at dawn.
  local held,dir,gaze=body(),body(),Vector3.zero
  local first,firstAt,drift,axis=nil,0,0,UP
  -- 0..1 once the sky is no longer this arrival's: everything fades out.
  local gone=0
  local function show(g,c,b,e)
   local function v(x)return 1-(1-x)*(1-gone)end
   glow.Transparency=v(g);corona.Transparency=v(c);black.Transparency=v(b);eye.Transparency=v(e);pupil.Transparency=v(e)
  end
  local function place(camera:Camera):CFrame
   local p=camera.CFrame.Position
   local f=Kit.LookAt(p+dir*SUN,p)
   frames[1]=f*CFrame.new(0,0,8)*FACING
   frames[2]=f*CFrame.new(0,0,4)*FACING
   frames[3]=f*FACING
   frames[4]=f*CFrame.new(0,0,-3)
   frames[5]=f*CFrame.new(gaze.X,gaze.Y,-5)
   workspace:BulkMoveTo(parts,frames,Enum.BulkMoveMode.FireCFrameChanged)
   return f
  end
  scope:Every(function(dt)
   local camera=workspace.CurrentCamera
   if not camera then return true end
   local t=ctx:Elapsed()
   if not sky.Free then
    gone=math.min(1,gone+dt/1.2)
    if gone>=1 then show(1,1,1,1);return false end
   end
   if t>=T.Dawn+5 then show(1,1,1,1);return false end
   if t<T.Fall or(t>=T.Shut+1 and t<T.Dawn)then show(1,1,1,1);return true end
   if t<T.Total then
    -- The moon slides in from the side and covers the sun.
    held=body()
    if not first then first,firstAt=held,t
    elseif t-firstAt>1 then
     local turn=first:Cross(held)
     if turn.Magnitude>1e-6 then axis=turn.Unit;drift=math.asin(math.min(turn.Magnitude,1))/(t-firstAt)end
    end
    dir=CFrame.fromAxisAngle(UP,.3*(1-smooth((t-T.Fall)/(T.Total-T.Fall)))):VectorToWorldSpace(held)
    show(1,1,1-smooth((t-T.Fall)/.6),1)
    place(camera)
   elseif t<T.Dawn then
    -- Totality (the corona flares in), then the eye opens, follows, blinks once and shuts.
    local a=t<T.Shut and smooth((t-T.Open)/.7)*math.clamp(math.abs(t-8.3)/.14,0,1)or 1-smooth((t-T.Shut)/.35)
    local fade=smooth((t-T.Shut-.4)/.6)
    show(.86+.14*fade,math.max(1-smooth((t-T.Total)/.25),fade),fade,a>.01 and 0 or 1)
    eye.Size=Vector3.new(R*1.6,math.max(.05,R*.8*a),.4)
    pupil.Size=Vector3.new(R*.2,math.max(.05,R*.64*a),.4)
    if t<T.Watch then dir=held;place(camera)
    else
     local want=ahead(camera.CFrame)
     local v=dir:Lerp(want,1-math.exp(-dt*2.4*smooth((t-T.Watch)/1.2)))
     dir=(v.Magnitude>.3 and v or dir+UP*.3).Unit
     -- The pupil leads toward where this player is looking.
     local lead=place(camera):VectorToObjectSpace(want-dir)*SUN*.6
     local goal=Vector3.new(lead.X,lead.Y,0)
     if goal.Magnitude>R*.3 then goal=goal.Unit*R*.3 end
     gaze=gaze:Lerp(goal,1-math.exp(-dt*8))
    end
   else
    -- Dawn: the black sun is back where the sun now is; the black burns away and the
    -- corona becomes the sun, then hands over to the real one.
    local u=t-T.Dawn
    local into,burn,out=smooth(u/.5),smooth((u-1)/2.4),smooth((u-4.2)/.8)
    dir=CFrame.fromAxisAngle(axis,drift*(t-T.Total)):VectorToWorldSpace(held)
    gaze=Vector3.zero
    glow.Size=Vector3.new(.4,R*3.4*(1+.35*burn),R*3.4*(1+.35*burn))
    show(1-into*(1-out)*(.14+.3*burn),1-into*(1-out),1-into*(1-burn),1)
    place(camera)
   end
   return true
  end)
 end

 ---------------------------------------------------------------- the colossus
 -- A black THE DOG over the horizon beyond the stage (behind the giant head on the
 -- tongue, its eyes above the head's roofline from the yards). A thin white rim keeps it
 -- readable against the black sky; its eyes open for the cutaway and its head follows
 -- each camera; at dawn it sinks back. Up north (the plaza, museum, lab, DOG-O-MATIC) the
 -- giant head's horizon is a kilometre off, so there it stands in the player's own sky,
 -- out over the island toward the stage; the cutaway always sees it behind the head.
 local foot=origin+away*(GIANT_OUT+GIANT*.59)
 local mid=Vector3.new(foot.X,GIANT/2-5,foot.Z)
 local hang=CFrame.lookAt(mid,mid-away)
 -- Its eyes once risen: THE DOG's face is .58 of its height ahead of its middle, its eyes
 -- .8 of the way up (for the cutaway's first shot).
 local giantEyesAt=mid-away*GIANT*.58+UP*GIANT*.3
 local giant,rim
 local glare={}
 local giantLook={Target=origin,Body=0,Head=0}
 local cut:any=nil
 local sinking=false
 local function farAway(was:boolean):boolean
  local me=Kit.Me()
  local d=Vector3.new(me.X-origin.X,0,me.Z-origin.Z).Magnitude
  if was then return d>NEAR end
  return d>FAR
 end
 local function raise(late:boolean)
  giant=ctx:Colossus({Height=GIANT,At=hang,Style='Silhouette',Color=C(0,0,0),Clip='Stand_Idle',
   Rise=late and 0 or 210,FadeIn=late and 1 or 4,Distance=560,Elevation=12})
  if not giant then return end
  -- Where it stands for this player: behind the giant head (pinned), or in their own sky.
  local far,pinned,placed=false,true,false
  scope:Every(function()
   if sinking or not giant.Model.Parent then return false end
   far=farAway(far)
   local wantPinned=not far or(cut~=nil and cut.Active)
   if wantPinned~=pinned then
    pinned=wantPinned
    -- It rises where this player first sees it; a cut (into or out of the cutaway)
    -- jumps; walking past the line glides.
    local jump=not placed or cut~=nil and(cut.Active or ctx:Elapsed()>=T.Cut and ctx:Elapsed()<T.Cut+5.4)
    giant:Pose(pinned and hang or nil,jump and 0 or 2.5)
   end
   placed=true
   return true
  end)
  local m:Model=giant.Model
  rim=scope:Highlight(m,C(255,255,255),C(255,255,255),1,1)
  Kit.Tween(rim,late and 1 or 4,{OutlineTransparency=.35})
  if giant.Animator then giant.Animator.Look=giantLook end
  -- Its eyes sit just in front of the face, as far apart as its brows, carried by the head.
  local bones={}
  for _,b in ipairs(m:GetDescendants())do if b:IsA('Bone')then bones[b.Name]=b end end
  local head=bones.head
  local pivot=m:GetPivot()
  local carry=head and head.TransformedWorldCFrame or pivot
  local face=bones.eyes and pivot:PointToObjectSpace(bones.eyes.TransformedWorldCFrame.Position)or Vector3.new(0,GIANT*.8,-GIANT*.44)
  for i,brow in ipairs({bones['brow.L']or false,bones['brow.R']or false})do
   local x=brow and pivot:PointToObjectSpace(brow.TransformedWorldCFrame.Position).X*.85 or(i==1 and 1 or -1)*GIANT*.095
   local spot=pivot:PointToWorldSpace(Vector3.new(x,face.Y,face.Z-GIANT*.026))
   glare[i]={Part=scope:Part({Name='GiantEye',Shape=Enum.PartType.Ball,Size=Vector3.one*.2,Color=C(255,255,255),Transparency=1}),
    Local=carry:PointToObjectSpace(spot)}
  end
  scope:Every(function()
   if not m.Parent then return false end
   local frame=head and head.TransformedWorldCFrame or m:GetPivot()
   for _,e in ipairs(glare)do e.Part.CFrame=CFrame.new(frame:PointToWorldSpace(e.Local))end
   local t=ctx:Elapsed()
   local camera=workspace.CurrentCamera
   if camera then giantLook.Target=camera.CFrame.Position end
   giantLook.Head=smooth((t-T.Gaze)/1.4)*(1-smooth((t-T.Dawn)/1.5))
   return true
  end)
 end

 ---------------------------------------------------------------- the cutaway
 -- Every camera: wide on the colossus over the stage, down into the mouth as the ground
 -- opens and it rises, handed back as every dog bows. A shot that would sit inside a
 -- building (off the tongue) is pulled in front of it.
 local skip:{Instance}={model}
 local fx=workspace:FindFirstChild('DOGROTS_SecretArrivalFX')
 if fx then table.insert(skip,fx)end
 for _,p in ipairs(Players:GetPlayers())do if p.Character then table.insert(skip,p.Character)end end
 local clearance=RaycastParams.new()
 clearance.FilterType=Enum.RaycastFilterType.Exclude
 clearance.FilterDescendantsInstances=skip
 local function shot(eye:Vector3,target:Vector3):CFrame
  local hit=workspace:Raycast(target,eye-target,clearance)
  if hit and(hit.Position-target).Magnitude>6 then eye=hit.Position+(target-hit.Position).Unit*2 end
  return Kit.Frame(eye,target)
 end
 local mouth=origin+UP*3.6
 cut=ctx:Cutaway({
  {At=T.Cut,CFrame=shot(origin-away*200+UP*55,origin:Lerp(giantEyesAt,.45)),Fov=56},
  {At=T.Cut+1.6,CFrame=shot(origin-away*95+UP*30,origin+UP*14),Fov=50},
  {At=T.Cut+3.3,CFrame=shot(origin-away*24+UP*7,mouth),Fov=44},
  {At=T.Cut+4.9,CFrame=shot(origin-away*20.5+UP*6.3,mouth+UP*.3),Fov=42},
 },{Bars=.1,Shake=.08})

 ---------------------------------------------------------------- around every player
 -- Something invisible and heavy walks past this player to the stage: glowing pawprints
 -- and thuds, from just behind them to well ahead.
 local function pawprints()
  local me=Kit.Me()
  local to=Vector3.new(origin.X-me.X,0,origin.Z-me.Z)
  if to.Magnitude<30 then return end
  local toward=to.Unit
  local side=toward:Cross(UP)
  local ground=RaycastParams.new()
  ground.FilterType=Enum.RaycastFilterType.Exclude
  local character=Players.LocalPlayer.Character
  ground.FilterDescendantsInstances=character and {scope.Folder,character}or {scope.Folder}
  local turn=CFrame.lookAt(Vector3.zero,toward)
  local white=C(236,236,246)
  for i=1,low and 4 or 10 do
   if not scope.Alive then return end
   local step=me+toward*(-16+(i-1)*6.5)+side*(i%2==0 and 7.5 or 4.5)
   local hit=workspace:Raycast(step+UP*30,Vector3.new(0,-70,0),ground)
   if hit then
    local at=CFrame.new(hit.Position+UP*.06)*turn
    local mark=Instance.new('Model');mark.Name='Pawprint';mark.Parent=scope.Folder
    local pads={scope:Part({Name='Pad',Shape=Enum.PartType.Cylinder,Size=Vector3.new(.12,2.8,2.8),
     CFrame=at*CFrame.Angles(0,0,math.pi/2),Color=white,Transparency=.15,Parent=mark})}
    if not low then
     for _,toe in ipairs({Vector3.new(-1.15,0,-2),Vector3.new(0,0,-2.45),Vector3.new(1.15,0,-2)})do
      table.insert(pads,scope:Part({Name='Toe',Shape=Enum.PartType.Cylinder,Size=Vector3.new(.12,1.1,1.1),
       CFrame=at*CFrame.new(toe)*CFrame.Angles(0,0,math.pi/2),Color=white,Transparency=.15,Parent=mark}))
     end
    end
    Kit.Cue('Impact',pads[1],.55)
    if (hit.Position-me).Magnitude<24 then Kit.Shake(.1,.22)end
    scope:Life(mark,3.6,function(a)for _,p in ipairs(pads)do p.Transparency=.15+.85*a*a end end)
   end
   task.wait(.27)
  end
 end
 ---------------------------------------------------------------- the eclipse, map-wide
 local unlit,unlitTo,motes,lampsOut
 task.spawn(function()
  local kicker=odds()
  -- The first banner (SecretArrivalConfig.Dogs.TheDog.Banner), with the odds as its kicker.
  local first=type(config.Banner)=='table'and table.clone(config.Banner)or {Title='TOTAL ECLIPSE',Text='do not look at the sun.'}
  local at=first.At or T.Banner
  first.At=nil
  if ctx:Elapsed()<at+2.5 then
   if not ctx:Wait(at)then return end
   first.Style=first.Style or 'Void';first.Color=first.Color or C(255,255,255);first.Hold=first.Hold or 3.4
   if kicker and not first.Kicker then first.Kicker='⚠  SECRET DOG  ·  '..kicker..'  ⚠'end
   ctx:Banner(first)
  end
  if not ctx:Wait(T.Blackout)then return end
  if ctx:Elapsed()<T.Dawn then
   unlit,unlitTo=scope:TintLights(C(0,0,0),live(T.Blackout)and 3.2 or .5)
   -- Every lamp's glass in the district dies in a wave out from the stage (170 studs/s:
   -- the yards at once, the plaza ~4 s later, the DOG-O-MATIC ~5 s), a slice per frame.
   lampsOut=scope:Blackout({Filter=isLamp,Color=C(30,28,32),Material=Enum.Material.SmoothPlastic,
    From=origin,Speed=170,Late=math.max(0,ctx:Elapsed()-T.Blackout)})
  end
  if not ctx:Wait(T.Total)then return end
  if ctx:Elapsed()<T.Dawn then
   if sky then sky:Set(DARK,live(T.Total)and 1.4 or .6)end
   if live(T.Total)then Kit.Cue('Impact',nil,1);if not calm then Kit.Flash(C(255,255,255),.55,.9)end end
   -- Pale motes rise around every player.
   motes=scope:Rain({Texture=Kit.Textures.Spark,Rate=34,Area=120,Height=-12,EmissionDirection=Enum.NormalId.Top,
    Speed=NumberRange.new(1,3),Acceleration=Vector3.new(0,1.6,0),Lifetime=NumberRange.new(4,6.5),SpreadAngle=Vector2.new(25,25),
    Color=ColorSequence.new(C(236,236,246)),LightEmission=.7,
    Size=NumberSequence.new({NumberSequenceKeypoint.new(0,.08),NumberSequenceKeypoint.new(.5,.2),NumberSequenceKeypoint.new(1,0)}),
    Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,1),NumberSequenceKeypoint.new(.2,.3),NumberSequenceKeypoint.new(1,1)})})
  end
  if not ctx:Wait(T.Stare)then return end
  turnAll()
  if not ctx:Wait(T.Open)then return end
  if live(T.Open)then Kit.Cue('Sting',nil,.75)end
  if not ctx:Wait(T.Rise)then return end
  if ctx:Elapsed()<T.Dawn then
   -- A groan from under the horizon as it rises.
   if live(T.Rise)then
    Kit.Shot(nil,Kit.Tick,1,.05,{EqualizerSoundEffect={LowGain=10,MidGain=-12,HighGain=-40},DistortionSoundEffect={Level=.35},
     ReverbSoundEffect={DecayTime=6,WetLevel=0,DryLevel=-4,Density=1,Diffusion=1}})
   end
   raise(ctx:Elapsed()>T.Rise+2)
  end
  if not ctx:Wait(T.Steps)then return end
  if live(T.Steps)then task.spawn(pawprints)end
  if not ctx:Wait(T.Gaze)then return end
  if ctx:Elapsed()<T.Dawn then
   for _,e in ipairs(glare)do Kit.Tween(e.Part,live(T.Gaze)and .3 or 0,{Size=Vector3.one*GIANT*.04,Transparency=0},Enum.EasingStyle.Back)end
  end
  -- (A beat after the cutaway's own start, so Active is settled.)
  if not ctx:Wait(T.Cut+.15)then return end
  if cut and cut.Active and live(T.Cut+.15)then Kit.Cue('Whoosh',nil,.6)end
  if not ctx:Wait(T.Arrive)then return end
  if ctx:Elapsed()<T.Arrive+1 then
   ctx:Banner({Style='Void',Kicker='✦  ? ? ?  ✦',Title='THE DOG',Color=C(255,255,255),Hold=3.2,Sting=false,
    Text=ctx.By and 'it chose '..string.lower(ctx.By)..'.'or onTongue and 'it is waiting on the tongue.'or 'it has arrived.'})
   -- A wall of white light races out over the whole district (the north included, ~4.2 s
   -- to the far corner) and jolts every player as it passes them.
   scope:Shockwave(origin+UP*.4,C(255,255,255),{Seconds=4.2,Height=4,Thickness=2.2,Alpha=.3,Segments=48,
    Shake=.3,Flash=.35,Cutaway=cut})
  end
  if not ctx:Wait(T.Dawn)then return end
  -- Dawn: it closes its eyes and sinks back under the horizon (from wherever this player
  -- sees it).
  for _,e in ipairs(glare)do Kit.Tween(e.Part,.35,{Size=Vector3.one*.2,Transparency=1})end
  sinking=true
  if giant then giant:Pose(giant:Frame()-UP*240,4.4);giant:Stop(4.4)end
  if rim then Kit.Tween(rim,2.5,{OutlineTransparency=1})end
  if not ctx:Wait(T.Dawn+.4)then return end
  -- The light comes back (the real sun with it, at the end of the fade).
  if sky then sky:Release(4.6)end
  if motes then motes.Rate=0 end
  if live(T.Dawn+.4)then Kit.Cue('Chime',nil,.45)end
  if not ctx:Wait(T.Dawn+2.2)then return end
  -- The lights warm back to their own colours, the lamps relight in a wave out from the
  -- stage (the whole district by ~23.4 s, before it walks).
  if unlitTo then unlitTo(function(_,own)return own end,1.6)end
  if lampsOut then lampsOut:Release(340)end
  if live(T.Dawn+2.2)then Kit.Cue('Impact',nil,.35)end
  if not ctx:Wait(T.Dawn+3.9)then return end
  if unlit then unlit()end
 end)

 ---------------------------------------------------------------- the stage
 if intro then
  act:Letterbox(.1,1.6)
  -- Hidden under the stage until the ground opens.
  local vis=act:Visibility(model);vis.Set(1)
  local lift=act:Offset(model)
  lift.CFrame=CFrame.new(0,-size.Y*1.2,0)
  -- A heartbeat every player hears, quickening until it arrives.
  task.spawn(function()
   local beat=1.7
   if not ctx:Wait(.8)then return end
   while scope.Alive and ctx:Elapsed()<T.Arrive-.4 do
    Kit.Cue('Heartbeat',nil,.8);task.wait(beat);beat=math.max(.55,beat*.88)
   end
  end)
  if not ctx:Wait(T.Candles)then return end
  -- A ring of cold white lights around the stage, lit one at a time.
  local candles={}
  for i=1,12 do
   local angle=i/12*math.pi*2
   local p=act:Part({Name='Candle',Size=Vector3.new(.35,1.2,.35),Position=origin+Vector3.new(math.cos(angle)*8.5,.6,math.sin(angle)*8.5),
    Color=C(255,255,255),Transparency=1})
   candles[i]=p
   task.delay(i*.24,function()
    if not scope.Alive or not p.Parent then return end
    Kit.Tween(p,.25,{Transparency=.05})
    if not low and i%3==0 then act:Light(p,C(220,225,255),9,1.1)end
    if i%4==0 then Kit.Cue('Glitch',p,.08)end
   end)
  end
  -- Black motes drifting up out of the belt.
  local motesUp=act:Anchor(origin+Vector3.new(0,.5,0),'Motes')
  local smoke=act:Emitter(motesUp,{Texture=Kit.Textures.Smoke,Rate=low and 6 or 20,Color=ColorSequence.new(C(8,6,12)),
   LightEmission=0,Lifetime=NumberRange.new(2,3.5),Speed=NumberRange.new(1,3),SpreadAngle=Vector2.new(35,35),
   Size=NumberSequence.new({NumberSequenceKeypoint.new(0,1.2),NumberSequenceKeypoint.new(1,3.5)}),
   Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,1),NumberSequenceKeypoint.new(.3,.35),NumberSequenceKeypoint.new(1,1)})})
  if not ctx:Wait(T.Glint)then return end
  -- Something in the dark blinks, right where its eyes will be once it has risen.
  if live(T.Glint)then
   local face=Kit.Root(model)and model:GetPivot().LookVector or Vector3.zAxis
   face=Vector3.new(face.X,0,face.Z)
   face=face.Magnitude>.1 and face.Unit or Vector3.zAxis
   local across=face:Cross(Vector3.yAxis)
   local glints={}
   for side=-1,1,2 do
    glints[#glints+1]=act:Part({Name='Glint',Shape=Enum.PartType.Ball,Size=Vector3.one*.24,Color=C(255,255,255),Transparency=1,
     Position=origin+across*side*.32+face*size.Z*.3+Vector3.new(0,size.Y*.78,0)})
   end
   local function blink(on)for _,g in ipairs(glints)do g.Transparency=on and 0 or 1 end end
   blink(true)
   task.delay(.3,function()if scope.Alive then blink(false)end end)
   task.delay(.7,function()if scope.Alive then blink(true)end end)
   task.delay(1.4,function()if scope.Alive then blink(false)end end)
  end
  if not ctx:Wait(T.Ground-.4)then return end
  if near>0 then Kit.FOVPunch(-3*near,.6,1.4)end
  if not ctx:Wait(T.Ground)then return end
  -- The ground opens (the dog's own Ground_Opens clip plays on the server clock).
  local hole=act:Part({Name='Hole',Shape=Enum.PartType.Cylinder,Material=Enum.Material.SmoothPlastic,Color=C(0,0,0),
   Size=Vector3.new(.2,.1,.1),CFrame=CFrame.new(origin+Vector3.new(0,.08,0))*CFrame.Angles(0,0,math.pi/2)})
  Kit.Tween(hole,1.2,{Size=Vector3.new(.2,size.X*1.6+2,size.X*1.6+2)})
  act:Pillar(origin,origin+Vector3.new(0,90,0),C(255,255,255),size.X*.9,4.2)
  -- The light pours up out of the hole (a light at the pillar's middle sits inside the head).
  local lamp=act:Light(act:Anchor(origin+Vector3.new(0,3,0),'HoleLight'),C(235,240,255),28,3)
  Kit.Tween(lamp,4.2,{Brightness=0},Enum.EasingStyle.Quad,Enum.EasingDirection.In)
  Kit.Cue('Impact',nil,1)
  if near>0 then Kit.Shake(.55*near,1.6)end
  if cut and cut.Active then cut:Shake(.7,1.4)end
  smoke.Rate=0
  vis.Set(.85)
  local rise=os.clock()
  act:Every(function()
   local a=math.min((os.clock()-rise)/2.2,1)
   local e=1-(1-a)^3
   lift.CFrame=CFrame.new(0,-size.Y*1.2*(1-e),0)
   vis.Set(.85*(1-math.min(a*1.6,1)))
   return a<1
  end)
  if not ctx:Wait(T.Ground+1.8)then return end
  if near>0 then Kit.FOVPunch(-7*near,1.6,2.4)end
  if not ctx:Wait(T.Arrive)then return end
  -- It has arrived (its name crosses every screen: see the eclipse above).
  if near>0 and not calm then Kit.Flash(C(255,255,255),1-.75*near,1.1)end
  Kit.Cue('Sting',nil,.9)
  if cut and cut.Active then cut:Shake(.35,.8)end
  act:Ring(origin+Vector3.new(0,.3,0),C(255,255,255),2,60,1.6,{Thickness=.5})
  if not low then act:Ring(origin+Vector3.new(0,.3,0),C(200,210,255),1,38,2.2,{Thickness=.25,Alpha=.4})end
  scope:Highlight(model,C(255,255,255),C(255,255,255),.92,.15)
  scope:Drone('Choir',low and .2 or .32,.8,2.5)
  for _,p in ipairs(candles)do if p.Parent then Kit.Tween(p,1.5,{Transparency=1})end end
  Kit.Tween(hole,2.5,{Size=Vector3.new(.2,.1,.1)})
 else
  -- Late: no rise, it is already standing there, marked as everyone else saw it land
  -- (the reveal card unless its name is still to cross the screen).
  scope:Highlight(model,C(255,255,255),C(255,255,255),.92,.15)
  if ctx:Elapsed()>=T.Arrive+1 then ctx:Title({Tier='? ? ?',Color=C(255,255,255),Hold=4.5,Font=Enum.Font.SpecialElite})end
 end
 -- Every dog on the island bows its head.
 if ctx:Elapsed()<T.Bow+.5 then
  if not ctx:Wait(T.Bow)then return end
  if stare then stare:Bow(math.rad(28),1.8)end
 end
 if not ctx:Wait(hold)then return end

 -- It walks. Everything keeps watching; the bars lift, the screen and the music breathe
 -- back a little.
 act:Clean()
 Kit.Tween(grade,2.5,{Saturation=-.35,Contrast=.16,Brightness=-.02})
 if drone then Kit.Tween(drone,3,{Volume=low and .22 or .35})end
 scope:Duck(.04,3)
 -- The tongue lights up again behind it. Once it steps off (bought, or gone through the
 -- portal) the rest wakes up from there.
 local sweep
 scope:Every(function(dt)
  local at=model.Parent and ctx:Ground()
  if not at then return true end
  if model:GetAttribute('State')~='OnLine'then sweep=math.max(sweep or at.Z,at.Z)+dt*60 end
  reach=math.max(reach,at.Z,sweep or at.Z)
  for g,release in pairs(dark)do
   if g.Position.Z<reach then dark[g]=nil;release()end
  end
  return true
 end)
 local ownerSeen=model:GetAttribute('OwnerName')
 scope:Add(model:GetAttributeChangedSignal('OwnerName'):Connect(function()
  local owner=model:GetAttribute('OwnerName')
  if type(owner)=='string'and owner~=''and owner~=ownerSeen then
   ownerSeen=owner
   local mine=model:GetAttribute('OwnerUserId')==Players.LocalPlayer.UserId
   local chosen=ctx:Say(mine and 'it chose you.'or 'it chose '..string.lower(owner)..'.',
    {Font=Enum.Font.SpecialElite,Color=C(255,255,255),Type=.08,Chroma=true})
   W.Breathe(chosen,3)
   Kit.Cue('Sting',nil,.6)
  end
 end))
 -- Until it is gone (delivered or dissolved) or the stare times out.
 ctx:Wait(hold+(config.StareSeconds or 120))
end
