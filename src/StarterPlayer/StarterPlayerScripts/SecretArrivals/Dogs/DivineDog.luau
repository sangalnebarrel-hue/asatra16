-- BIBLICALLY ACCURATE DOG, "BE NOT AFRAID". Heaven opens over the whole island. For every
-- player, wherever they stand, the day turns gold-white (golden clouds, god rays, bloom), a
-- choir rises, the lamps turn gold and a colossal golden wheel draws itself in their own
-- sky, low over the horizon beyond the stage or ahead of them (nobody has to look up): wheels
-- within wheels, their eyes opening one by one and all of them looking at YOU (the wheel
-- turns to face each player), the great eye last. Every dog looks at it, feathers fall
-- around everyone and a seraph of light as tall as the sky rises behind the stage. Pillars
-- of light slam down on the yards one after another, then one finds every player and stays
-- on them. The wheel opens: every camera is pulled to it as its great eye pours a beam of
-- light down onto the stage (every dog bows, a gold shockwave crosses the whole district)
-- and cut in to the stage act, 7 s later than it used to be: the dog comes down inside the
-- light, turning once, to a falling harp. As it touches down its twenty eyes open in a flash
-- and every eye in the sky blinks with it. Six orbs of luck circle it and burst one by one,
-- six suns around the wheel with them, while its halo burns brighter; one of its rays finds
-- you and your light counts you, twice. Then every eye closes, the light goes back up, the
-- seraph sinks, the wheel rises away and the day comes back, all of it gone before the
-- arrival ends. On the tongue the light strikes the giant head and pours through the mouth's
-- roof; off it (a Lucky pad, a dig, the DOG-O-MATIC) it falls on the stage in the open.
local Players=game:GetService('Players')
local SoundService=game:GetService('SoundService')
local C=Color3.fromRGB
local WHITE=Color3.new(1,1,1)
local GOLD,PALE,CREAM,INK,EMBER=C(255,204,96),C(255,250,236),C(255,238,198),C(14,9,4),C(120,72,12)
local TICK='rbxasset://sounds/volume_slider.ogg'
-- Server seconds. The map-wide build-up: the wheel draws itself, its eyes open, the great eye
-- opens, the seraph rises, the yards' pillars fall, every player's light finds them, it opens.
local DRAW,EYES,GREAT,THRONE,PILLARS,FOUND,OPEN=.3,2.4,3.6,4.4,4.8,6.1,6.6
-- The stage act (SecretArrivalConfig clips and whispers match): the light strikes, it
-- descends, lands (Blink), rolls, peaks, closes (Blink). The feathers stop at CALM so the
-- last ones have drifted away before the hold ends.
local SHAFT,DESCEND,LAND,ROLL,PEAK,CLOSE=7.3,7.8,9.8,10.4,13.1,13.6
local CALM=11.6
-- The second whisper's typing speed: its ray locks on as "you" is typed.
local TYPE=.034
-- Where the wheel hangs for each player: SKY_OUT studs from their camera with its hub
-- SKY_RISE degrees over their horizon (its rim spans ~2-21°, inside a default third-person
-- view, which sees only ~15-20° above the horizon).
local SKY_OUT,SKY_RISE=640,11.5
local PENTA={1,9/8,5/4,3/2,5/3,2,9/4,5/2,3,10/3,4}
-- The eight yards' floors (04_PlayerYards/*/GroundThemeArea), from the island's centre.
local FLOORS={}
for _,x in ipairs({-105,105})do for _,z in ipairs({-117,-39,39,117})do table.insert(FLOORS,Vector3.new(x,.12,z))end end
local function smooth(x)x=math.clamp(x,0,1);return x*x*(3-2*x)end
local function out3(x)x=math.clamp(x,0,1);return 1-(1-x)^3 end
local function sineOut(x)return math.sin(math.clamp(x,0,1)*math.pi/2)end
local function backOut(x)x=math.clamp(x,0,1)-1;local c=1.70158;return 1+(c+1)*x*x*x+c*x*x end
local function pulse(el,t)return el>=t and math.exp(-(el-t)*6)or 0 end
-- How open its lids are through a Blink clip started at t0 (shut at t0+.3, open at t0+.6).
local function lids(el,t0)return smooth(math.abs(el-t0-.3)/.3)end
local function curve(points)
 local k={}
 for i,p in ipairs(points)do k[i]=NumberSequenceKeypoint.new(p[1],p[2])end
 return NumberSequence.new(k)
end
local function setSkin(s:SurfaceAppearance,strength:number,tint:Color3)s.EmissiveTint=tint;s.EmissiveStrength=strength end
-- Cylinders lie along X: this stands them up; `along` lays one along a look vector.
local upright=CFrame.Angles(0,0,math.pi/2)
local along=CFrame.Angles(0,math.pi/2,0)

return function(ctx)
 ctx.WhisperStyle={Font=Enum.Font.Garamond,Color=CREAM,Glitch=0,Chroma=false,Shake=true,Type=.085}
 local Kit,scope,model,config=ctx.Kit,ctx.Scope,ctx.Model,ctx.Config
 local low,calm,origin,hold=ctx.Low,Kit.ReducedMotion(),ctx.Origin,config.Hold
 local Map=Kit.Map
 local SUN=config.Color
 local size=Kit.Size(model)
 local up=Vector3.yAxis
 local joined=ctx:Elapsed()
 local player=Players.LocalPlayer
 -- One-shots fire on time only: a late joiner gets the state, not a pile-up of cues.
 local function fresh(t)return ctx:Elapsed()-t<.35 end
 local venue=ctx.Venue or 'Tongue'
 local roofed=venue=='Tongue'and math.abs(origin.X)<10 and origin.Z<-146.5 and origin.Z>-182
 -- Where it faces: down the line on the tongue; a pad dog faces its opener, so off the
 -- tongue this camera stands in until the rig streams in.
 local function facing():Vector3
  local look:Vector3?=Kit.Root(model)and model:GetPivot().LookVector or nil
  local cam=workspace.CurrentCamera
  if not look and venue~='Tongue'and cam then look=cam.CFrame.Position-origin end
  local flat=look and Vector3.new(look.X,0,look.Z)or Vector3.zero
  return flat.Magnitude>.1 and flat.Unit or Vector3.zAxis
 end
 local fwd=facing()
 -- Under the giant head the light opens in the mouth's roof (underside y=23.5, opening at
 -- z=-146); in the open it opens 44 studs over the stage. The spotlight and the opening's
 -- bells hang where a roof would be: in the mouth's, or as high over an open stage (21.3).
 local top=roofed and Vector3.new(origin.X,23.35,origin.Z)or origin+up*44
 local lid=roofed and top-Vector3.new(0,0,1.2)or top
 local roof=roofed and top-up*.4 or origin+up*21.3
 local RISE=roofed and 12 or 15
 -- Map scale. The wheel (rim radius R1) hangs in each player's own sky (HUB, below) and pours
 -- its light down onto the stage's foot: on the tongue the giant head's crown over the
 -- mouth's roof (the shaft below goes on inside), in the open the stage itself. The seraph
 -- stands behind the stage as the island sees it.
 local R1=100
 local foot=roofed and top+up*.6 or origin
 local away=Vector3.new(Map.Center.X-origin.X,0,Map.Center.Z-origin.Z)
 local aud=away.Magnitude>40 and away.Unit or fwd
 -- Shockwaves from the stage run along the floors (never under them, from a dig pit) out to
 -- the farthest corner of the district (the plaza, the museum, the lab, the DOG-O-MATIC).
 local WAVE=Vector3.new(origin.X,math.max(origin.Y,Map.Center.Y),origin.Z)
 local REACH=0
 for _,x in ipairs({Map.Min.X,Map.Max.X})do
  for _,z in ipairs({Map.Min.Z,Map.Max.Z})do REACH=math.max(REACH,Vector3.new(x-origin.X,0,z-origin.Z).Magnitude)end
 end
 REACH=math.clamp(REACH+60,300,1000)
 -- The light columns fall out of the sky from this high (over the yards and every player).
 local SKY_TOP=Map.Center.Y+Map.Sky+140
 -- The second whisper: "...it counted you twice." Its ray finds you on "you", counts on "twice".
 local spoken=config.Whispers and config.Whispers[2]
 local said,text=spoken and spoken[1]or LAND+.2,spoken and spoken[2]or ''
 local function typed(word:string,fallback:number):number
  local i=string.find(text,word,1,true)
  return i and said+(i+#word-1)*TYPE or fallback
 end
 local PING1=math.clamp(typed('you',LAND+2.1),LAND+.8,LAND+2.8)
 local PING2=math.clamp(typed('twice',LAND+2.3),PING1+.32,LAND+3.3)
 local LOCK=PING1-.25

 -- Bones: the rings carry the twenty eyes, Float the body, Halo the crown.
 local bones:{[string]:Bone}={}
 local wanted={'Float','Halo','Ring_1'}
 for i=1,20 do table.insert(wanted,string.format('Eye_%02d',i))end
 local function refresh()
  for _,name in ipairs(wanted)do
   local b=bones[name]
   if not(b and b.Parent)then
    local found=model:FindFirstChild(name,true)
    if found and found:IsA('Bone')then bones[name]=found else bones[name]=nil end
   end
  end
 end
 refresh()
 local function at(name:string):Vector3?
  local b=bones[name]
  if b and b.Parent then return b.TransformedWorldCFrame.Position end
  return nil
 end
 local function ground():Vector3
  if model.Parent then return ctx:Ground()end
  return origin
 end
 local function center():Vector3 return at('Ring_1')or ground()+up*size.Y*.47 end
 local function crown():Vector3 return at('Halo')or ground()+up*size.Y end
 local function target():(Vector3?,boolean)
  local character=player.Character
  local head=character and (character:FindFirstChild('Head')or character:FindFirstChild('HumanoidRootPart'))
  if head and head:IsA('BasePart')and (head.Position-origin).Magnitude<150 then return head.Position,true end
  local camera=workspace.CurrentCamera
  return camera and camera.CFrame.Position or nil,false
 end
 -- A struck bell: the built-in tick, pitched and drowned in reverb. No parent: every player
 -- hears it the same, wherever they are.
 local function bell(speed:number,volume:number,parent:Instance?,decay:number?)
  if not scope.Alive or volume<.01 then return end
  local s=Instance.new('Sound');s.SoundId=TICK;s.Volume=volume;s.PlaybackSpeed=speed
  s.RollOffMinDistance=16;s.RollOffMaxDistance=260
  local r=Instance.new('ReverbSoundEffect');r.DecayTime=decay or 2.6;r.Density=1;r.Diffusion=1;r.WetLevel=0;r.DryLevel=-4;r.Parent=s
  local q=Instance.new('EqualizerSoundEffect');q.LowGain=speed<1 and 6 or -8;q.MidGain=2;q.HighGain=-6;q.Parent=s
  s.Parent=(parent and parent.Parent)and parent or SoundService
  -- Ending the arrival lets a ringing bell fade instead of cutting it off.
  scope:Add(function()if s.Parent then Kit.Tween(s,1,{Volume=0}).Completed:Connect(function()s:Destroy()end)end end)
  s:Play()
  task.delay(5,function()if s.Parent then s:Destroy()end end)
 end
 -- The first solid, visible thing between two points (not the dog, the players or our light).
 local function blocked(from:Vector3,to:Vector3):Vector3?
  local params=RaycastParams.new()
  params.FilterType=Enum.RaycastFilterType.Exclude
  params.IgnoreWater=true
  local skip:{Instance}={model,scope.Folder}
  for _,p in ipairs(Players:GetPlayers())do if p.Character then table.insert(skip,p.Character)end end
  for _=1,6 do
   params.FilterDescendantsInstances=skip
   local hit=workspace:Raycast(from,to-from,params)
   if not hit then return nil end
   if hit.Instance.Transparency<.9 then return hit.Position end
   table.insert(skip,hit.Instance)
  end
  return nil
 end
 -- The wheel's hub in THIS player's sky, where a default camera sees it: SKY_OUT studs from
 -- their camera, SKY_RISE degrees up, beyond the stage as they see it when they face it
 -- (within 70°), else straight ahead of their camera (they stand at the stage or look away
 -- from it), swung up to 50° aside until nothing solid (the giant head, a roof) hides it.
 local HUB:Vector3
 do
  local cam=workspace.CurrentCamera
  local from=cam and cam.CFrame.Position or Kit.Me()
  local look=cam and cam.CFrame.LookVector or fwd
  local ahead=Vector3.new(look.X,0,look.Z)
  ahead=ahead.Magnitude>.05 and ahead.Unit or fwd
  local flat=Vector3.new(origin.X-from.X,0,origin.Z-from.Z)
  flat=(flat.Magnitude>=60 and flat.Unit:Dot(ahead)>.34)and flat.Unit or ahead
  local e=math.rad(SKY_RISE)
  -- The bearing itself first, then the swung ones nearest where they look.
  local turns={0,.44,-.44,.87,-.87}
  local function seen(a:number):number return CFrame.Angles(0,a,0):VectorToWorldSpace(flat):Dot(ahead)end
  table.sort(turns,function(a,b)if a==0 or b==0 then return a==0 and b~=0 end;return seen(a)>seen(b)end)
  for i,a in ipairs(turns)do
   local spot=from+CFrame.Angles(0,a,0):VectorToWorldSpace(flat)*SKY_OUT*math.cos(e)+up*SKY_OUT*math.sin(e)
   local clear=blocked(from,spot)==nil
   if i==1 or clear then HUB=spot end
   if clear then break end
  end
 end

 -- 0: heaven opens over the whole island: a gold-white day, golden clouds, god rays, bloom,
 -- and a choir every player hears. The music bows out.
 scope:Duck(.35,1)
 local drone=scope:Drone('Choir',low and .3 or .42,.72,joined<.5 and 2 or .4)
 local sky=scope:Sky({
  Lighting={ClockTime=15.2,Brightness=3,ExposureCompensation=.24,Ambient=C(166,148,114),OutdoorAmbient=C(214,196,154),
   ColorShift_Top=C(255,214,140)},
  Atmosphere={Density=.17,Offset=.2,Color=C(255,232,186),Decay=C(255,198,126),Glare=1.4,Haze=2},
  Clouds={Cover=.66,Density=.45,Color=C(255,224,160)},
  Sky={SunAngularSize=30},
  Grade={TintColor=C(255,243,218),Saturation=.1,Contrast=.07,Brightness=.03},
  Bloom={Intensity=.6,Size=36,Threshold=1.2},
 },joined<.5 and 2.6 or .6,2.4)
 local camera=workspace.CurrentCamera
 local godRays:SunRaysEffect?=nil
 if camera then
  local r=Instance.new('SunRaysEffect');r.Name='DOGROTS_SecretSunRays';r.Intensity=0;r.Spread=.85;r.Parent=camera
  godRays=r
  Kit.Tween(r,2.6,{Intensity=.16})
  scope:Add(function()Kit.Tween(r,.8,{Intensity=0}).Completed:Connect(function()r:Destroy()end)end)
 end

 -- The wheel: a dashed ring of gold carrying twelve eyes, a second ring turning through it
 -- with eight more, a third tumbling inside them, the great eye in the middle, and six suns
 -- waiting round it for the rolls. It turns to face whoever looks at it, from anywhere.
 local count=low and 16 or 40
 local R2,R3=R1*.78,R1*.6
 local wheel,inner,third={},{},{}
 for i=1,count do
  wheel[i]=scope:Part({Name='Wheel',Color=GOLD,Transparency=1,Size=Vector3.new(3.2,2*math.pi*R1/count*.74,3.2)})
 end
 if not low then
  for i=1,30 do inner[i]=scope:Part({Name='Wheel',Color=CREAM,Transparency=1,Size=Vector3.new(2.2,2*math.pi*R2/30*.62,2.2)})end
  for i=1,24 do third[i]=scope:Part({Name='Wheel',Color=PALE,Transparency=1,Size=Vector3.new(1.6,2*math.pi*R3/24*.6,1.6)})end
 end
 local function ellipsoid(name:string,color:Color3,neon:boolean):Part
  local p=scope:Part({Name=name,Color=color,Transparency=1,Size=Vector3.one*.05,
   Material=neon and Enum.Material.Neon or Enum.Material.SmoothPlastic})
  local m=Instance.new('SpecialMesh');m.MeshType=Enum.MeshType.Sphere;m.Parent=p
  return p
 end
 local function eye(name:string,w:number,h:number,p:number,i:number,ring:number,angle:number,opens:number,span:number,iris:boolean)
  return {White=ellipsoid(name,PALE,true),Iris=iris and ellipsoid('Iris',GOLD,true)or nil,Pupil=ellipsoid('Pupil',INK,false),
   W=w,H=h,P=p,I=i,Ring=ring,Angle=angle,Open=opens,For=span}
 end
 local eyes={}
 local rim=low and 8 or 12
 for k=1,rim do table.insert(eyes,eye('Eye',17,14.5,6.2,9.5,1,(k-.5)/rim*math.pi*2,EYES+((k*5)%rim)*.07,.35,not low))end
 if not low then
  for k=1,8 do table.insert(eyes,eye('Eye',11,9.5,4.2,6,2,(k-.5)/8*math.pi*2,EYES+.45+((k*3)%8)*.08,.35,true))end
 end
 local great=eye('GreatEye',44,28,8.4,18,0,0,GREAT,.7,true)
 local suns={}
 for k=1,6 do suns[k]={Part=scope:Part({Name='Sun',Shape=Enum.PartType.Ball,Color=SUN,Transparency=1,Size=Vector3.one}),At=HUB}end
 -- The light of heaven: from the great eye straight down onto the stage.
 local pour=scope:Part({Name='Heaven',Shape=Enum.PartType.Cylinder,Color=CREAM,Transparency=1,Size=Vector3.one*.1})
 local pourCore=(not low)and scope:Part({Name='HeavenCore',Shape=Enum.PartType.Cylinder,Color=PALE,Transparency=1,Size=Vector3.one*.1})or nil
 -- The sky moves in one BulkMoveTo a frame; sizes and transparencies are only written when
 -- they change (most of the time they hold).
 local moved:{BasePart}={}
 local frames:{CFrame}={}
 local n=0
 local function put(p:BasePart,cf:CFrame)n+=1;moved[n]=p;frames[n]=cf end
 local alphas:{[BasePart]:number}={}
 local sizes:{[BasePart]:Vector3}={}
 local function setAlpha(p:BasePart,a:number)if alphas[p]~=a then alphas[p]=a;p.Transparency=a end end
 local function setSize(p:BasePart,s:Vector3)if sizes[p]~=s then sizes[p]=s;p.Size=s end end
 local function poseEye(e,pos:Vector3,open:number,gaze:Vector3,rotation:CFrame)
  local h=e.H*open
  local hidden=h<.05 and 1 or 0
  setAlpha(e.White,hidden);setAlpha(e.Pupil,hidden)
  if e.Iris then setAlpha(e.Iris,hidden)end
  local look=rotation.LookVector
  local to=gaze-pos
  to=to.Magnitude>.01 and to.Unit or look
  -- The pupil slides toward what it watches (mostly down: the wheel only half tilts to you).
  local shift=rotation.RightVector*to:Dot(rotation.RightVector)*e.W*.17+rotation.UpVector*to:Dot(rotation.UpVector)*h*.24
  if hidden==0 then
   setSize(e.White,Vector3.new(e.W,h,e.W*.04))
   if e.Iris then setSize(e.Iris,Vector3.new(e.I,math.min(e.I,h*.8),e.W*.025))end
   setSize(e.Pupil,Vector3.new(e.P,math.min(e.P,h*.5),e.W*.025))
  end
  put(e.White,rotation+pos)
  if e.Iris then put(e.Iris,rotation+(pos+look*e.W*.03+shift))end
  put(e.Pupil,rotation+(pos+look*e.W*(e.Iris and .05 or .04)+shift))
 end
 -- A dashed ring round `hub` in the plane of the unit axes a,b, each segment lying along it
 -- (one CFrame a part: the sky loop runs every frame).
 local function ring(list:{BasePart},hub:Vector3,radius:number,phase:number,a:Vector3,b:Vector3)
  local parts=#list
  for i,p in ipairs(list)do
   local t=i/parts*math.pi*2+phase
   local c,s=math.cos(t),math.sin(t)
   local radial=a*c+b*s
   put(p,CFrame.fromMatrix(hub+radial*radius,radial,b*c-a*s))
  end
 end

 -- The light: an opening in the roof, a shaft of light to the stage, a spotlight, six
 -- god-rays twisting round it and motes of gold falling through it.
 local length=top.Y-origin.Y
 local mid=origin+up*(length/2)
 local shaft=scope:Part({Name='Shaft',Shape=Enum.PartType.Cylinder,Color=CREAM,Transparency=1,Size=Vector3.new(length,.1,.1),CFrame=CFrame.new(mid)*upright})
 local core=scope:Part({Name='ShaftCore',Shape=Enum.PartType.Cylinder,Color=PALE,Transparency=1,Size=Vector3.new(length,.1,.1),CFrame=CFrame.new(mid)*upright})
 local opening=scope:Part({Name='Opening',Shape=Enum.PartType.Cylinder,Color=PALE,Transparency=1,Size=Vector3.new(.2,8.5,8.5),CFrame=CFrame.new(lid)*upright})
 local corona=scope:Part({Name='Corona',Shape=Enum.PartType.Cylinder,Color=GOLD,Transparency=1,Size=Vector3.new(.1,11,11),CFrame=CFrame.new(lid-up*.08)*upright})
 local heaven=scope:Anchor(roof,'Heaven')
 local spot=Instance.new('SpotLight');spot.Face=Enum.NormalId.Bottom;spot.Angle=50;spot.Range=25
 spot.Brightness=0;spot.Color=CREAM;spot.Shadows=false;spot.Parent=heaven
 local streams={}
 local hubTop,hubLow
 if not low then
  hubTop=scope:Anchor(top-up*.3,'RaysTop');hubLow=scope:Anchor(origin+up*.4,'RaysLow')
  for k=1,6 do
   local a=k/6*math.pi*2
   local t0=Instance.new('Attachment');t0.Position=Vector3.new(math.cos(a)*3.4,0,math.sin(a)*3.4);t0.Parent=hubTop
   local t1=Instance.new('Attachment');t1.Position=Vector3.new(math.cos(a)*3,0,math.sin(a)*3);t1.Parent=hubLow
   streams[k]=scope:Beam(t0,t1,PALE,0,{Color=ColorSequence.new(PALE,SUN),Segments=1,Brightness=1.5,
    Transparency=curve({{0,.4},{.7,.65},{1,.95}})})
  end
 end
 local motes=scope:Part({Name='Motes',Size=Vector3.new(7,math.max(length-2,1),7),CFrame=CFrame.new(mid),Transparency=1})
 local dust=scope:Emitter(motes,{Shape=Enum.ParticleEmitterShape.Box,EmissionDirection=Enum.NormalId.Bottom,
  Color=ColorSequence.new(PALE,SUN),Lifetime=NumberRange.new(2.5,4),Speed=NumberRange.new(.6,1.8),SpreadAngle=Vector2.new(15,15),
  Acceleration=Vector3.new(0,-.4,0),Size=curve({{0,.05},{.3,.28},{1,0}}),Transparency=curve({{0,1},{.2,.15},{1,1}}),
  Rotation=NumberRange.new(0,360),RotSpeed=NumberRange.new(-60,60)})
 -- The open air's taller shaft falls as thick with them as the mouth's.
 local MOTES=(low and 4 or 14)*(roofed and 1 or length/21.3)
 -- Its own light rides the Float bone (lights under the district get throttled).
 local heart=scope:Anchor(origin+up*3,'Heart')
 local warm=scope:Light(heart,SUN,16,0)

 -- The mouth turns gold: runes from the throat outward, the mist, the nearest lanterns;
 -- the tongue's warm edges catch it when it lands. All of it eases back as it closes.
 -- (Only on the tongue: an open stage has none of them.)
 local restore={}
 -- Tweens on world props stop with the arrival, or one in flight would undo the restore.
 local function ease(o:Instance,seconds:number,props:{[string]:any})
  local t=Kit.Tween(o,seconds,props)
  scope:Add(function()t:Cancel()end)
 end
 local function tint(o:Instance,props:{[string]:any},seconds:number?)
  local saved={}
  for k in pairs(props)do saved[k]=(o::any)[k]end
  if seconds then scope:Override(o,saved);ease(o,seconds,props)else scope:Override(o,props)end
  table.insert(restore,{o,saved})
 end
 local district=venue=='Tongue'and workspace:FindFirstChild('DOGROTS_District')or nil
 local factory=district and district:FindFirstChild('02_DogFactory')
 local tunnel=factory and factory:FindFirstChild('DarkMouthTunnel')
 local line=district and district:FindFirstChild('03_DogLine')
 local runes,guides,lamps={},{},{}
 if tunnel then
  for _,o in ipairs(tunnel:GetDescendants())do
   if o.Name=='MouthRune'and o:IsA('BasePart')then table.insert(runes,o)
   elseif o:IsA('ParticleEmitter')then scope:Override(o,{Color=ColorSequence.new(PALE,GOLD)})end
  end
  table.sort(runes,function(a,b)return (a.Position-origin).Magnitude>(b.Position-origin).Magnitude end)
 end
 if line then
  for _,lantern in ipairs(line:GetChildren())do
   local lens=lantern.Name=='PromenadeLantern'and lantern:FindFirstChild('WarmLens')
   if lens and lens:IsA('BasePart')and (lens.Position-origin).Magnitude<30 then
    table.insert(lamps,{lens,{Color=PALE}})
    for _,l in ipairs(lantern:GetDescendants())do
     if l:IsA('PointLight')then table.insert(lamps,{l,{Color=SUN}})end
    end
   end
  end
  local tongue=line:FindFirstChild('Tongue')
  for _,g in ipairs(tongue and tongue:GetChildren()or {})do
   if g.Name=='WarmEdgeGuide'and g:IsA('BasePart')and math.abs(g.Position.Z-origin.Z)<70 then table.insert(guides,g)end
  end
 end

 -- The dog waits in the light until it descends (a client this late sees it landed).
 local vis=joined<LAND and scope:Visibility(model)or nil
 local lift=joined<LAND and scope:Offset(model)or nil
 local hidden=-1
 local function hide(v:number)
  if vis and math.abs(v-hidden)>.004 then hidden=v;vis.Set(v)end
 end
 hide(1)
 if lift then lift.CFrame=CFrame.new(0,RISE,0)end

 -- Its skin: the halo burns brighter through the rolls, everything flares as it lands.
 local skins,seen={},{}
 local function grab(o:Instance)
  if not o:IsA('SurfaceAppearance')or seen[o]then return end
  local ok,strength,hue=pcall(function()return o.EmissiveStrength,o.EmissiveTint end)
  if not ok then return end
  seen[o]=true
  local part=o.Parent
  table.insert(skins,{Look=o,Strength=strength,Hue=hue,Halo=part~=nil and string.find(string.lower(part.Name),'halo',1,true)~=nil})
  scope:Override(o,{EmissiveStrength=strength,EmissiveTint=hue})
 end
 for _,o in ipairs(model:GetDescendants())do grab(o)end
 scope:Add(model.DescendantAdded:Connect(grab))

 -- Six orbs of luck, two on each of three heights, orbiting the opposite ways.
 local orbs={}
 for k=1,6 do
  local level=(k-1)%3
  local p=scope:Part({Name='Luck',Shape=Enum.PartType.Ball,Color=SUN,Transparency=1,Size=Vector3.one*.8})
  orbs[k]={Part=p,Pop=ROLL+.4*k,H=size.Y*(.2+.3*level),Phase=level*2.1+(k>3 and math.pi or 0),Dir=level%2==0 and 1 or -1,
   Spark=(not low)and scope:Emitter(p,{Color=ColorSequence.new(PALE,SUN),Lifetime=NumberRange.new(.3,.6),
    Speed=NumberRange.new(0,1),Size=NumberSequence.new(.3,0)})or nil}
 end
 -- A rising ✦ for every roll (KeepFont before parenting, or the place typography swaps it).
 local function star(from:Vector3)
  local a=scope:Anchor(from,'Roll')
  local g=Instance.new('BillboardGui');g.Name='Roll';g.Adornee=a;g.AlwaysOnTop=true;g.LightInfluence=0
  g.MaxDistance=220;g.Size=UDim2.fromScale(2.6,2.6)
  local l=Instance.new('TextLabel');l.Name='Star';l:SetAttribute('KeepFont',true)
  l.BackgroundTransparency=1;l.AnchorPoint=Vector2.new(.5,.5);l.Position=UDim2.fromScale(.5,.5);l.Size=UDim2.fromScale(0,0)
  l.Font=Enum.Font.Garamond;l.Text='✦';l.TextScaled=true;l.TextColor3=SUN;l.TextStrokeColor3=EMBER;l.TextStrokeTransparency=.4
  l.Parent=g;g.Parent=a
  scope:Life(a,1.3,function(t)
   a.CFrame=CFrame.new(from+up*2.4*out3(t))
   local s=backOut(t/.25)
   l.Size=UDim2.fromScale(s,s)
   local fade=smooth((t-.55)/.45)
   l.TextTransparency=fade;l.TextStrokeTransparency=.4+.6*fade
  end)
 end

 -- Its twenty eyes shine out along the rings (made as it lands); one finds you.
 local rays={}
 local ends:BasePart?=nil
 local mine:any=nil
 local hl:Highlight?=nil
 local function shine()
  if low then return end
  refresh()
  -- The rig has streamed in by now: its real facing.
  fwd=facing()
  local anchor=scope:Anchor(origin,'RayEnds')
  ends=anchor
  for i=1,20 do
   local b=bones[string.format('Eye_%02d',i)]
   if b then
    local tip=Instance.new('Attachment');tip.Parent=anchor
    local beam=scope:Beam(b,tip,SUN,0,{Color=ColorSequence.new(PALE,SUN),Segments=1,Brightness=2,
     Transparency=curve({{0,.05},{.6,.35},{1,1}})})
    table.insert(rays,{Bone=b,Tip=tip,Beam=beam,Dir=fwd})
   end
  end
 end

 -- Columns of light out of the sky: one on each yard (they fall, ring the ground, fade) and
 -- one on every player (it falls on them at FOUND, stays on them, counts them at the pings;
 -- yours is the brightest, and on Low the only one).
 local function column(floor:Vector3,rank:number)
  local glow=scope:Part({Name='Column',Shape=Enum.PartType.Cylinder,Color=CREAM,Transparency=1,Size=Vector3.one*.1})
  local inside=(not low)and scope:Part({Name='ColumnCore',Shape=Enum.PartType.Cylinder,Color=PALE,Transparency=1,
   Size=Vector3.one*.1,Parent=glow})or nil
  scope:Life(glow,2.2,function(a)
   local t=a*2.2
   local f=math.clamp(t/.3,0,1);f*=f
   local bottom=SKY_TOP+(floor.Y-SKY_TOP)*f
   local cf=CFrame.new(floor.X,(SKY_TOP+bottom)/2,floor.Z)*upright
   local long=math.max(SKY_TOP-bottom,.1)
   local out=smooth((t-1.3)/.9)
   local w=18*(1-.7*out)*(1+.25*pulse(t,.3))
   glow.Size=Vector3.new(long,w,w);glow.CFrame=cf;glow.Transparency=.5+.5*out
   if inside then inside.Size=Vector3.new(long,w*.3,w*.3);inside.CFrame=cf;inside.Transparency=.1+.9*out end
  end)
  task.delay(.3,function()
   if not scope.Alive then return end
   bell(.62*PENTA[rank],.34,scope:Anchor(floor+up*2,'Bell'),3)
   if low then return end
   scope:Ring(floor+up*.35,PALE,3,44,1.1,{Thickness=1.4,Segments=16,Alpha=.2})
   scope:Burst(floor+up,PALE,24,{Speed=NumberRange.new(10,24),Lifetime=NumberRange.new(.5,1),Drag=2.5,Size=NumberSequence.new(1.1,0)})
  end)
 end
 local marks={}
 local function mark(root:BasePart?,own:boolean,delay:number)
  local p=scope:Part({Name='Counted',Shape=Enum.PartType.Cylinder,Color=own and PALE or CREAM,Transparency=1,Size=Vector3.one*.1})
  table.insert(marks,{Root=root,Own=own,Delay=delay,Part=p})
 end
 local function markStep()
  local el=ctx:Elapsed()
  local flare=pulse(el,PING1)+pulse(el,PING2)
  local out=smooth((el-PING2-.7)/.8)
  for _,m in ipairs(marks)do
   local p=m.Part
   local root=m.Root
   local feet=(root==nil and Kit.Me()or root.Parent and root.Position or nil)
   local t=el-FOUND-m.Delay
   if not feet or t<0 then p.Transparency=1
   else
    feet-=up*3
    local f=math.clamp(t/.3,0,1);f*=f
    local bottom=SKY_TOP+(feet.Y-SKY_TOP)*f
    local settle=smooth((t-.3)/.7)
    local w=(m.Own and 7 or 4.5)*(1-.55*settle+1.3*flare)*(1-.8*out)
    p.Size=Vector3.new(math.max(SKY_TOP-bottom,.1),w,w)
    p.CFrame=CFrame.new(feet.X,(SKY_TOP+bottom)/2,feet.Z)*upright
    local a=math.clamp((m.Own and .2 or .35)+(m.Own and .45 or .4)*settle-.45*flare,0,1)
    p.Transparency=a+(1-a)*out
   end
  end
  return el<PING2+1.6
 end

 local kick,lookup=0,0
 scope:Every(function(dt)
  local el=ctx:Elapsed()
  local now=os.clock()
  if now>=lookup then lookup=now+.5;refresh()end
  kick*=math.exp(-dt*5)
  local landed=el>=LAND and math.exp(-(el-LAND)*2.5)or 0
  local closing=1-smooth((el-CLOSE)/.7)
  local blink=lids(el,LAND)

  -- The light: in from the strike, the core thins once it has landed, all of it gone by CLOSE+.7.
  local light=out3((el-SHAFT)/.7)*closing
  local w=.3+7.7*light*(1+.025*math.sin(el*7))
  shaft.Size=Vector3.new(length,w,w);shaft.CFrame=CFrame.new(mid)*upright;shaft.Transparency=1-.22*light
  local hot=out3((el-SHAFT)/.4)*(1-smooth((el-LAND)/.6))
  core.Size=Vector3.new(length,2.8*hot+.05,2.8*hot+.05);core.CFrame=CFrame.new(mid)*upright;core.Transparency=1-.45*hot
  local open=out3((el-SHAFT)/.25)*closing
  opening.Transparency=1-.95*open;corona.Transparency=1-.4*open
  spot.Brightness=8*light
  if hubTop and hubLow then
   hubTop.CFrame=CFrame.new(top-up*.3)*CFrame.Angles(0,el*.5,0)
   hubLow.CFrame=CFrame.new(origin+up*.4)*CFrame.Angles(0,el*.5+1.1,0)
   local g=smooth((el-SHAFT-.2)/.6)*closing
   for _,s in ipairs(streams)do s.Width0=1.5*g;s.Width1=.25*g end
  end

  -- It comes down through the light, turning once (Sine Out: no bump at the bottom).
  if lift then
   local u=(el-DESCEND)/(LAND-DESCEND)
   if u<1 then
    lift.CFrame=CFrame.new(0,RISE*(1-sineOut(u)),0)*CFrame.Angles(0,calm and 0 or math.pi*2*out3(u),0)
    hide(1-smooth((el-DESCEND)/.5))
   else
    lift.CFrame=CFrame.identity;hide(0)
   end
  end
  heart.CFrame=CFrame.new(at('Float')or ground()+up*size.Y*.5)
  warm.Brightness=(1.6*smooth((el-DESCEND)/1)+3*landed+1.2*kick)*closing

  -- Its eyes' rays sweep with the turning rings; after the lock only yours is left.
  local anchor=ends
  if anchor and #rays>0 then
   local c=center()
   local grow=out3((el-LAND)/.3)
   local others=1-smooth((el-LOCK)/.6)
   local goal,head=nil,false
   if mine then goal,head=target()end
   for _,r in ipairs(rays)do
    local b=r.Bone
    if b.Parent then
     local p=b.TransformedWorldCFrame.Position
     local dir=p-c
     dir=dir.Magnitude>.05 and (dir.Unit+fwd*.4).Unit or fwd
     r.Dir=dir
     local reach,width=26*grow,others
     if r==mine and goal then
      local lock=out3((el-LOCK)/.22)
      local to=goal-p
      local dist=to.Magnitude
      if dist>.5 then
       local blend=dir:Lerp(to/dist,lock)
       if blend.Magnitude>.05 then dir=blend.Unit end
       reach+=((head and dist or math.min(dist-4,30))-reach)*lock
      end
      width=(1-smooth((el-PING2-.8)/.6))*(1+1.6*(pulse(el,PING1)+pulse(el,PING2)))
     end
     r.Tip.Position=p+dir*math.max(reach,.1)-anchor.Position
     r.Beam.Width0=.1*width*blink*grow;r.Beam.Width1=.42*width*blink*grow
    else
     r.Beam.Width0=0;r.Beam.Width1=0
    end
   end
  end

  -- The orbs come out of its halo into orbit; each swells and goes on its roll.
  if el>=ROLL then
   local g,from=ground(),crown()
   for k,o in ipairs(orbs)do
    local p=o.Part
    local age=el-ROLL-.05*k
    -- Waiting in the halo (its sparks are already on, so it must not sit at its spawn point).
    if age<0 then p.Transparency=1;p.CFrame=CFrame.new(from)
    elseif el<o.Pop then
     local th=o.Phase+o.Dir*1.8*(el-ROLL)
     local orbit=g+Vector3.new(math.cos(th)*5,o.H,math.sin(th)*5)
     p.Size=Vector3.one*.8*(1+.12*math.sin(el*9+k))
     p.CFrame=CFrame.new(from:Lerp(orbit,backOut(age/.5)))
     p.Transparency=.05
    else
     local s=(el-o.Pop)/.16
     if s<1 then p.Size=Vector3.one*(.8+1.4*s);p.CFrame=CFrame.new(p.Position);p.Transparency=.05+.95*s else p.Transparency=1 end
     if o.Spark then o.Spark.Rate=0 end
    end
   end
  end

  -- The halo: warm on the way down, burning through the rolls, out as the eyes close.
  local rise=math.max(.3*smooth((el-DESCEND)/2),smooth((el-ROLL)/(PEAK-ROLL)))
  for _,s in ipairs(skins)do
   if s.Look.Parent then
    local strength=s.Halo and s.Strength+((1-s.Strength)*rise+.8*kick+1.2*landed)*closing
     or s.Strength+(.5*landed+.15*kick)*closing
    local glow=math.min(1,(s.Halo and .8 or .5)*closing*math.max(rise,landed))
    pcall(setSkin,s.Look,strength,s.Hue:Lerp(SUN,glow))
   end
  end
  if hl then
   hl.FillTransparency=1-math.min(.5*landed+.25*kick+.07,1)*closing
   hl.OutlineTransparency=1-.6*closing*smooth((el-LAND)/.3)
  end
  return el<hold+1
 end)

 -- The sky, every frame: the wheel half tilted toward this viewer and turning, its eyes, the
 -- suns and the light of heaven.
 local face:CFrame?=nil
 local spin=0
 scope:Every(function(dt)
  local el=ctx:Elapsed()
  n=0
  local cam=workspace.CurrentCamera
  local view=cam and cam.CFrame.Position or HUB+fwd*220-up*150
  -- It opens as the light comes (spins up, widens, burns brighter) and settles after the
  -- landing; at the end it rises away as it fades.
  local opens=smooth((el-OPEN)/.7)*(1-smooth((el-LAND)/1.6))
  local gone=smooth((el-CLOSE-.1)/1.6)
  local hub=HUB+up*80*smooth((el-CLOSE)/2.4)
  spin+=dt*(.12+1.1*opens)
  local d=view-hub
  local want=Kit.LookAt(hub,hub+Vector3.new(d.X,d.Y*.6,d.Z)).Rotation
  local rotation=face and face:Lerp(want,math.min(1,dt*2.5))or want
  face=rotation
  local R,U,L=rotation.RightVector,rotation.UpVector,rotation.LookVector
  local r1=R1*(1+.1*opens)
  local lit=(.9+.08*opens)*(1-gone)
  ring(wheel,hub,r1,spin,R,U)
  for i,p in ipairs(wheel)do setAlpha(p,1-lit*smooth((el-DRAW-(i-1)/count*1.6)/.2))end
  -- The second ring turns edge-on through the first; the third tumbles inside both.
  local cross=rotation*CFrame.Angles(0,math.pi/2+spin*2.5,0)
  local cR,cU=cross.RightVector,cross.UpVector
  if #inner>0 then
   local a=1-.62*smooth((el-DRAW-1)/.6)*(1-gone)
   ring(inner,hub,R2,-spin*1.5,cR,cU)
   for _,p in ipairs(inner)do setAlpha(p,a)end
   local tumble=rotation*CFrame.Angles(math.pi/3+spin*1.4,0,0)
   local b=1-.5*smooth((el-DRAW-1.5)/.6)*(1-gone)
   ring(third,hub,R3,spin,tumble.RightVector,tumble.UpVector)
   for _,p in ipairs(third)do setAlpha(p,b)end
  end
  -- Its eyes look at you; as it opens they turn down to the stage; at the count back to you.
  -- They blink as it lands and close with its own.
  local down=smooth((el-OPEN)/.5)*(1-smooth((el-LOCK)/.4))
  local gaze=view:Lerp(origin,down)
  local shut=lids(el,LAND)*(1-smooth((el-CLOSE)/.28))
  for _,e in ipairs(eyes)do
   local pos
   if e.Ring==1 then
    local t=e.Angle+spin
    pos=hub+(R*math.cos(t)+U*math.sin(t))*r1+L*3.9
   else
    local t=e.Angle-spin*1.5
    pos=hub+(cR*math.cos(t)+cU*math.sin(t))*R2
   end
   poseEye(e,pos,out3((el-e.Open)/e.For)*shut,gaze,rotation)
  end
  great.H=28*(1+.3*opens);great.P=8.4*(1-.4*opens)
  poseEye(great,hub+L*4,out3((el-GREAT)/.7)*lids(el,LAND+.05)*(1-smooth((el-CLOSE-.15)/.3)),gaze,rotation)
  -- Six suns for the six rolls: they swell out of the rim and burst with the orbs.
  for k,s in ipairs(suns)do
   local t=(k-.5)/6*math.pi*2+spin*.5
   local pos=hub+(R*math.cos(t)+U*math.sin(t))*R1*1.2+L*2
   s.At=pos
   put(s.Part,CFrame.new(pos))
   local age,pop=el-ROLL-.05*k,ROLL+.4*k
   local g=age<0 and 0 or el<pop and backOut(age/.5)or math.max(0,1-(el-pop)/.15)
   setAlpha(s.Part,g<.02 and 1 or .05)
   if g>=.02 then setSize(s.Part,Vector3.one*9*g*(1+.06*math.sin(el*9+k)))end
  end
  -- The light of heaven falls from the great eye across the sky onto the stage at the
  -- strike, thins after the landing and goes back up as it closes.
  local f=math.clamp((el-SHAFT)/.28,0,1)
  local reach=f*f*(1-smooth((el-CLOSE)/1))
  local bottom=hub+(foot-hub)*reach
  local cf=Kit.LookAt((hub+bottom)/2,bottom)*along
  local bw=22*(1-.45*smooth((el-LAND-.2)/.6))*(1+.03*math.sin(el*6))
  local long=math.max((bottom-hub).Magnitude,.1)
  put(pour,cf);setAlpha(pour,reach>.001 and .55+.45*gone or 1)
  if reach>.001 then setSize(pour,Vector3.new(long,bw,bw))end
  if pourCore then
   put(pourCore,cf);setAlpha(pourCore,reach>.001 and .12+.88*gone or 1)
   if reach>.001 then setSize(pourCore,Vector3.new(long,bw*.32,bw*.32))end
  end
  workspace:BulkMoveTo(moved,frames,Enum.BulkMoveMode.FireCFrameChanged)
  -- Everything up there has faded by CLOSE+1.8.
  return el<CLOSE+2
 end)

 -- 0: the island hears it begin; the wheel draws itself to rising bells, a deep one as it closes.
 if fresh(0)then Kit.Cue('Whoosh',nil,.45)end
 task.spawn(function()
  for j=0,7 do
   local t=DRAW+j*.2
   if not ctx:Wait(t)then return end
   if fresh(t)then bell(1.2*PENTA[j+3],.14)end
  end
  if not ctx:Wait(DRAW+1.8)then return end
  if fresh(DRAW+1.8)then bell(.5,.42,nil,4.5)end
 end)

 -- 1: every lamp in the district turns gold.
 if not ctx:Wait(1)then return end
 local unlight=scope:TintLights(C(255,220,150),2.4)

 -- 2.4: its eyes open, one after another, and look at you.
 if not ctx:Wait(EYES)then return end
 if fresh(EYES)then
  Kit.Cue('Chime',nil,.35)
  for j=0,5 do task.delay(j*.14,function()bell(1.8*PENTA[2+j],.08,nil,2)end)end
 end

 -- 3.6: the great eye. Feathers and motes of gold begin to fall around every player.
 if not ctx:Wait(GREAT)then return end
 if fresh(GREAT)then Kit.Cue('Sting',nil,.55);bell(.45,.45,nil,5)end
 local feathers=scope:Rain({Texture=Kit.Textures.Smoke,Rate=34,Area=120,Height=24,Color=ColorSequence.new(WHITE,CREAM),
  LightEmission=.25,LightInfluence=.4,Size=curve({{0,0},{.12,.75},{.85,.6},{1,0}}),Squash=NumberSequence.new(1.2),
  Transparency=curve({{0,1},{.15,.12},{.8,.3},{1,1}}),Speed=NumberRange.new(4,7),SpreadAngle=Vector2.new(28,28),
  Lifetime=NumberRange.new(4,5),Rotation=NumberRange.new(0,360),RotSpeed=NumberRange.new(-50,50),
  Acceleration=Vector3.new(0,-.6,0),Drag=.3})
 local glints=scope:Rain({Rate=22,Area=100,Height=26,Color=ColorSequence.new(GOLD,PALE),Size=curve({{0,0},{.2,.4},{1,0}}),
  Transparency=curve({{0,1},{.2,0},{1,1}}),Speed=NumberRange.new(3,6),Lifetime=NumberRange.new(4,5),SpreadAngle=Vector2.new(20,20)})
 task.delay(math.max(0,CALM-ctx:Elapsed()),function()
  if scope.Alive then feathers.Rate=0;glints.Rate=0 end
 end)

 -- 4: every dog on the island looks at it (and bows when the light strikes).
 if not ctx:Wait(GREAT+.4)then return end
 local glance=scope:Glance(HUB,{Exclude=model,Turn=1.1,Ripple=260})
 task.spawn(function()
  if ctx:Wait(SHAFT+2.1)then glance:Stop(1.2)end
 end)

 -- 4.4: a seraph of light as tall as the sky rises behind the stage (it hovers, bows to the
 -- strike, blinks and rolls with the dog, and sinks again at the end).
 if not ctx:Wait(THRONE)then return end
 local seat=Vector3.new(origin.X,Map.Center.Y+Map.Sky+6,origin.Z)-aud*200
 local throne=CFrame.lookAt(seat,seat+aud)*CFrame.Angles(-.14,0,0)
 local rising=fresh(THRONE)
 local seraph=ctx:Colossus({Height=240,At=throne,Style='Ghost',Color=GOLD,Alpha=.42,
  Clip=(not low)and 'Levitate_Walk'or nil,Rise=rising and 150 or 0,FadeIn=rising and 2.6 or .6})
 if rising then Kit.Cue('Whoosh',nil,.4);bell(.4,.34,nil,5)end
 -- Only full clients animate it (Low keeps it still).
 local function act(clip:string,looped:boolean)
  if seraph and not low then seraph:Play(clip,looped)end
 end

 -- 4.8: the cutaway every player gets is booked (from OPEN: from where they stand onto the
 -- wheel as it opens, panning down its light as it strikes, then a cut in along the light
 -- to the stage for the landing), and pillars of light slam down on the yards, nearest the
 -- stage first.
 if not ctx:Wait(PILLARS)then return end
 fwd=facing()
 local right=fwd:Cross(up)
 local function shot(from:Vector3,look:Vector3,seen:Vector3):CFrame
  -- Pulled in front of anything between it and what it must see.
  local hit=blocked(seen,from)
  if hit then from=hit+(seen-from).Unit*2 end
  return Kit.Frame(from,look)
 end
 local stage=origin+up*4
 -- This player's camera sees the wheel (it was hung where it would); one that has since
 -- moved behind something watches from a third of the way out from the stage instead.
 local cam=workspace.CurrentCamera
 local lens=cam and cam.CFrame.Position+up*3
 local watch=(lens and not blocked(lens,HUB))and lens or origin:Lerp(HUB,.33)+up*20
 local nearer=watch+(HUB-watch).Unit*40
 local cut=ctx:Cutaway({
  {At=OPEN,CFrame=Kit.Frame(watch,HUB),Fov=58},
  {At=SHAFT,CFrame=Kit.Frame(nearer,HUB:Lerp(foot,.5)),Fov=66},
  {At=SHAFT+.45,CFrame=shot(origin+fwd*70+right*14+up*16,origin+up*14,stage),Fov=66,Cut=true},
  {At=DESCEND+.8,CFrame=shot(origin+fwd*52+up*13,origin+up*9,stage),Fov=62},
  {At=LAND-.1,CFrame=shot(origin+fwd*22+right*3.5+up*5,origin+up*4.2,stage),Fov=54},
  {At=LAND+.9,CFrame=shot(origin+fwd*19+right*2.6+up*4.6,origin+up*4.5,stage),Fov=52,Linear=true},
 },{Focus=origin,Bars=.1,Shake=.1})
 local order={}
 for _,f in ipairs(FLOORS)do table.insert(order,Map.Center+f)end
 table.sort(order,function(a,b)return (a-origin).Magnitude<(b-origin).Magnitude end)
 if fresh(PILLARS)then Kit.Cue('Impact',nil,.5)end
 for i,floor in ipairs(order)do
  local t=PILLARS+(i-1)*.15
  task.delay(math.max(0,t-ctx:Elapsed()),function()
   if scope.Alive and ctx:Elapsed()-t<.5 then column(floor,i)end
  end)
 end

 -- 6.1: one finds every player and stays on them.
 if not ctx:Wait(FOUND)then return end
 mark(nil,true,0)
 if not low then
  local others=0
  for _,p in ipairs(Players:GetPlayers())do
   local c=p~=player and p.Character or nil
   local root=c and c:FindFirstChild('HumanoidRootPart')
   if root and root:IsA('BasePart')and others<12 then others+=1;mark(root,false,Kit.Random(.05,.45))end
  end
 end
 scope:Every(markStep)
 if fresh(FOUND)then
  task.delay(.3,function()
   if not scope.Alive then return end
   local feet=Kit.Me()-up*3
   scope:Ring(feet+up*.3,SUN,1,14,.8,{Thickness=.35,Segments=20,Alpha=.2})
   scope:Burst(feet+up*2,PALE,22,{Speed=NumberRange.new(4,10),Lifetime=NumberRange.new(.5,.9),Drag=2,Size=NumberSequence.new(.5,0)})
   bell(.84,.4,nil,3.2);Kit.Cue('Chime',nil,.3)
  end)
 end

 -- 6.6: the wheel opens; the choir swells.
 if not ctx:Wait(OPEN)then return end
 if drone then Kit.Tween(drone,.7,{Volume=low and .4 or .56})end
 if fresh(OPEN)then
  Kit.Cue('Whoosh',nil,.5)
  for i,step in ipairs({1,5/4,3/2,2,5/2})do task.delay((i-1)*.11,function()bell(1.1*step,.2,nil,3)end)end
 end

 -- 7.3: the light strikes. The great eye pours it down onto the stage, a gold shockwave
 -- crosses the island and the sky flares; every dog bows and the seraph bows with them. In
 -- the mouth the roof opens and the light comes down; the runes catch from the throat outward.
 if not ctx:Wait(SHAFT)then return end
 dust.Rate=MOTES
 glance:Bow(math.rad(58),2.2)
 if seraph then seraph:Pose(throne*CFrame.Angles(-.2,0,0),1.2)end
 for _,lamp in ipairs(lamps)do if lamp[1].Parent then tint(lamp[1],lamp[2],.6)end end
 for i,p in ipairs(runes)do
  task.delay(math.max(0,SHAFT+math.floor((i-1)/2)*.08-ctx:Elapsed()),function()
   if not scope.Alive or not p.Parent then return end
   tint(p,{Color=PALE});ease(p,.4,{Color=GOLD})
  end)
 end
 if fresh(SHAFT)then
  Kit.Cue('Whoosh',heaven,.55)
  for i,step in ipairs({1,5/4,3/2})do
   task.delay((i-1)*.05,function()bell(1.2*step,.18,heaven,3)end)
  end
  Kit.Cue('Impact',nil,.9);Kit.Cue('Sting',nil,.6);bell(.5,.5,nil,5)
  scope:Ring(WAVE+up*.4,GOLD,8,REACH,3.4,{Thickness=3,Segments=48,Alpha=.12})
  if face then scope:Ring(HUB,PALE,12,190,1.3,{U=face.RightVector,W=face.UpVector,Thickness=3,Segments=40,Alpha=.25})end
  -- Where it lands: the giant head's crown over the mouth, or the stage itself.
  local struck=blocked(HUB,foot-up*.5)or foot
  task.delay(.26,function()
   if scope.Alive then scope:Burst(struck+up,PALE,50,{Speed=NumberRange.new(24,50),Lifetime=NumberRange.new(.6,1.2),Drag=2,Size=NumberSequence.new(4.5,0)})end
  end)
  if cut then cut:Shake(.6,.6)end
  if not calm then
   sky:Set({Lighting={ExposureCompensation=.6},Bloom={Intensity=1.1}},.25)
   task.delay(.5,function()sky:Set({Lighting={ExposureCompensation=.24},Bloom={Intensity=.6}},1.4)end)
  end
 end

 -- 7.8: it comes down through the light to a falling harp.
 if not ctx:Wait(DESCEND)then return end
 if fresh(DESCEND)then scope:Burst(top-up*1.2,PALE,20,{Speed=NumberRange.new(2,6),Lifetime=NumberRange.new(.6,1.1),Drag=2,Size=NumberSequence.new(.35,0)})end
 task.spawn(function()
  for i=1,11 do
   local t=DESCEND+(i-1)*.17
   if not ctx:Wait(t)then return end
   if fresh(t)then bell(.85*PENTA[12-i],.12+.18*i/11,nil,2.2)end
  end
 end)

 -- 9.8: it touches down. Its eyes open in a flash; every eye in the sky blinks with it and a
 -- second shockwave crosses the island.
 if not ctx:Wait(LAND)then return end
 ctx.WhisperStyle={Font=Enum.Font.Garamond,Color=CREAM,Glitch=0,Chroma=false,Shake=false,Type=TYPE}
 ctx:Title({Font=Enum.Font.Garamond,Hold=4})
 shine()
 hl=scope:Highlight(model,SUN,PALE,1,1)
 act('Blink',false)
 if fresh(LAND)then
  local near=Kit.Near(origin,120)
  Kit.Cue('Sting',nil,.75)
  Kit.Cue('Chime',nil,.5)
  Kit.Cue('Impact',heart,.35)
  if near>.05 then
   Kit.Flash(PALE,1-.55*near,.5)
   Kit.Shake(.18*near,.5)
   Kit.FOVPunch(-4*near,.2,1.1)
  end
  scope:Ring(origin+up*.25,SUN,1.5,22,1.3,{Thickness=.35,Segments=28})
  if not low then scope:Ring(origin+up*.3,PALE,1,13,.9,{Thickness=.18,Alpha=.35,Segments=20})end
  scope:Burst(center(),PALE,36,{Speed=NumberRange.new(8,16),Lifetime=NumberRange.new(.5,1),Drag=3,Size=NumberSequence.new(.45,0)})
  scope:Ring(WAVE+up*.5,PALE,6,REACH,3,{Thickness=2.2,Segments=40,Alpha=.25})
  if cut then cut:Shake(.45,.45)end
  if not calm then
   sky:Set({Lighting={ExposureCompensation=.45},Bloom={Intensity=.95}},.15)
   task.delay(.35,function()sky:Set({Lighting={ExposureCompensation=.24},Bloom={Intensity=.6}},1.2)end)
  end
 end
 for _,g in ipairs(guides)do
  local when=LAND+math.abs(g.Position.Z-origin.Z)/70
  task.delay(math.max(0,when-ctx:Elapsed()),function()
   if not scope.Alive or not g.Parent then return end
   tint(g,{Color=PALE});ease(g,.5,{Color=GOLD})
  end)
 end

 -- As "you" is typed one ray leaves the rest and finds you; it counts you, twice. The light
 -- on every player flares with it, so you are counted wherever you are.
 task.spawn(function()
  if not ctx:Wait(LOCK)then return end
  local goal=target()
  if goal and #rays>0 then
   local best,score=nil,-2
   for _,r in ipairs(rays)do
    if r.Bone.Parent then
     local s=r.Dir:Dot((goal-r.Bone.TransformedWorldCFrame.Position).Unit)
     if s>score then best,score=r,s end
    end
   end
   if best then
    best.Beam.Color=ColorSequence.new(WHITE,PALE);best.Beam.Transparency=NumberSequence.new(0,.2)
    mine=best
   end
  end
  for i,t in ipairs({PING1,PING2})do
   if not ctx:Wait(t)then return end
   if fresh(t)then
    local you,head=target()
    if you and head then
     scope:Burst(you+up*.6,SUN,14,{Speed=NumberRange.new(2,5),Lifetime=NumberRange.new(.4,.7),Drag=2,Size=NumberSequence.new(.35,0)})
    end
    bell(.72,i==1 and .4 or .5,nil,3.4)
    local feet=Kit.Me()-up*3
    scope:Ring(feet+up*.3,SUN,1,10+4*i,.7,{Thickness=.3,Segments=20,Alpha=.2})
    star(feet+up*6.5)
   end
  end
 end)

 -- 10.4 Ability_MultiRoll: six rolls of luck; the seraph rolls with it and each roll's sun
 -- bursts in the sky for the whole island.
 if not ctx:Wait(ROLL)then return end
 for _,o in ipairs(orbs)do if o.Spark then o.Spark.Rate=6 end end
 act('Ability_MultiRoll',false)
 if fresh(ROLL)then Kit.Cue('Whoosh',heart,.3)end
 for k,o in ipairs(orbs)do
  if not ctx:Wait(o.Pop)then return end
  if fresh(o.Pop)then
   local p=o.Part.Position
   scope:Burst(p,SUN,18,{Speed=NumberRange.new(3,8),Lifetime=NumberRange.new(.4,.8),Drag=3,Size=NumberSequence.new(.4,0)})
   star(p)
   bell(1.5*PENTA[k+2],.3,heart,2)
   kick=1
   scope:Burst(suns[k].At,SUN,30,{Speed=NumberRange.new(40,80),Lifetime=NumberRange.new(.6,1.1),Drag=2.5,Size=NumberSequence.new(8,0)})
   bell(1.5*PENTA[k+2],.15,nil,2.6)
  end
 end

 -- 13.1: the halo peaks in a ring of light.
 if not ctx:Wait(PEAK)then return end
 if fresh(PEAK)then
  scope:Ring(crown(),GOLD,.6,9,.9,{Thickness=.25,Segments=24})
  Kit.Cue('Chime',nil,.4)
  kick=1.4
 end

 -- 13.6: every eye closes; the light goes back up, the wheel rises away, the mouth cools.
 if not ctx:Wait(CLOSE)then return end
 dust.Rate=0
 if drone then Kit.Tween(drone,1.4,{Volume=0})end
 for _,r in ipairs(restore)do if r[1].Parent then ease(r[1],.9,r[2])end end
 act('Blink',false)
 if fresh(CLOSE)then
  Kit.Cue('Sting',nil,.3)
  for i,step in ipairs({2,3/2,1})do
   task.delay((i-1)*.12,function()bell(1.2*step,.16,nil,3)end)
  end
 end
 -- 13.8: the day comes back; the seraph sinks behind the stage; the lamps cool.
 if not ctx:Wait(CLOSE+.2)then return end
 sky:Release(2.4)
 if godRays then Kit.Tween(godRays,2.4,{Intensity=0})end
 if not ctx:Wait(CLOSE+.5)then return end
 if seraph then
  act('Levitate_Walk',true)
  seraph:Pose(throne*CFrame.Angles(-.2,0,0)-up*170,2.6)
  seraph:Stop(2.2)
 end
 if not ctx:Wait(CLOSE+1)then return end
 unlight()
 if not ctx:Wait(hold)then return end
 -- It walks away (on a pad: stays) under the last of the light; the arrival ends once the
 -- wheel has risen away and the seraph has sunk (both gone by CLOSE+2.8), never on them.
 ctx:Wait(math.max(hold+.5,CLOSE+2.8))
end
