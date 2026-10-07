-- The map-wide layer of a Secret arrival: wherever a player stands on the island, the sky
-- turns, something colossal hangs over the map, their camera is pulled to the arrival for
-- its big moment, the district's lights answer, things fall around them and every dog
-- looks. Adds to Kit: K.Map, K.Me, K.Frame, K.Orbit, K.District and the scope methods Sky,
-- Colossus, Cutaway, Banner, Rain, TintLights, Blackout, Shockwave, Glance. All local to
-- this client, undone on Clean.
local Players=game:GetService('Players')
local RS=game:GetService('ReplicatedStorage')
local Run=game:GetService('RunService')
local Lighting=game:GetService('Lighting')
local K=require(script.Parent:WaitForChild('Kit'))
local Stare=require(script.Parent:WaitForChild('Stare'))
local Config=require(RS:WaitForChild('SecretArrivalConfig'))
local AnimationPlayer=require(RS:WaitForChild('DogAnimationPlayer'))
local player=Players.LocalPlayer
local Scope=K.ScopeClass
local function smooth(x)x=math.clamp(x,0,1);return x*x*(3-2*x)end

---------------------------------------------------------------- the island
-- SecretArrivalConfig.Map: where things go at map scale.
local MAP=Config.Map or {}
local landmarks:{[string]:Vector3}={}
for name,at in pairs(MAP.Landmarks or {})do landmarks[name]=at end
K.Map={
 Center=MAP.Center or Vector3.new(0,1,0),         -- the yards and the tongue, at floor height
 Radius=MAP.Radius or 190,                        -- from Center to the yards' outer fences
 Sky=MAP.Sky or 170,                              -- altitude above Center for colossal things
 Mouth=MAP.Mouth or Vector3.new(0,2,-150),        -- the tongue's stage
 Head=MAP.Head or Vector3.new(0,60,-195),         -- the giant head building
 Backdrop=MAP.Backdrop or Vector3.new(0,1,-420),  -- behind the giant head, where colossi loom
 Min=MAP.Min or Vector3.new(-200,0,-260),         -- the whole district
 Max=MAP.Max or Vector3.new(200,0,720),
 Landmarks=landmarks,                             -- named points (SecretArrivalConfig.Map.Landmarks)
}
-- The island's own points replace the configured ones once they stream in: the district's
-- NavigationAnchors (the plaza is WelcomeHub, the museum DogDex, the lab MutationLab; the
-- anchor called RewardMachine is the DOG-O-MATIC's approach) and the machine's prize stand.
local ALIASES={WelcomeHub={'Plaza'},DogDex={'Museum'},MutationLab={'Lab'}}
local RENAME={RewardMachine='MachineApproach'}
local function learn(anchor:Instance)
 if not anchor:IsA('BasePart')then return end
 local name=RENAME[anchor.Name]or anchor.Name
 landmarks[name]=anchor.Position
 for _,alias in ipairs(ALIASES[name]or {})do landmarks[alias]=anchor.Position end
end
task.spawn(function()
 local root=workspace:WaitForChild('DOGROTS_District',60)
 local anchors=root and root:WaitForChild('NavigationAnchors',60)
 if anchors then
  for _,anchor in ipairs(anchors:GetChildren())do learn(anchor)end
  anchors.ChildAdded:Connect(learn)
 end
 local attraction=root and root:WaitForChild('37_AttractionRefresh',60)
 local rig=attraction and attraction:WaitForChild('RewardMachineRig',60)
 local hooks=rig and rig:WaitForChild('CameraHooks',60)
 local stand=hooks and hooks:WaitForChild('RewardSpawn',60)
 if stand and stand:IsA('BasePart')then landmarks.Machine=stand.Position;landmarks.RewardMachine=stand.Position end
end)
-- Where this player is: their character, else what their camera looks at.
function K.Me():Vector3
 local c=player.Character
 local root=c and c:FindFirstChild('HumanoidRootPart')
 if root and root:IsA('BasePart')then return root.Position end
 local cam=workspace.CurrentCamera
 return cam and cam.Focus.Position or K.Map.Center
end
-- Camera CFrames for cutaway shots.
function K.Frame(position:Vector3,lookAt:Vector3):CFrame return K.LookAt(position,lookAt)end
function K.Orbit(center:Vector3,radius:number,height:number,angle:number):CFrame
 return K.LookAt(center+Vector3.new(math.sin(angle)*radius,height,math.cos(angle)*radius),center)
end

---------------------------------------------------------------- world events
-- World events (ReplicatedStorage.WorldEvents) drive Lighting, the Atmosphere, Clouds and the
-- Sky while one runs, and snapshot them when one starts (WorldEventLighting.Begin).
local function worldState():Instance?
 local events=RS:FindFirstChild('WorldEvents')
 return events and events:FindFirstChild('State')
end
local eventLighting:any=nil
local function lightingModule():any
 if eventLighting==nil then
  local events=RS:FindFirstChild('WorldEvents')
  local module=events and events:FindFirstChild('WorldEventLighting')
  if not module then return nil end
  local ok,result=pcall(function()return require(module::ModuleScript)end)
  eventLighting=ok and type(result)=='table'and result or false
 end
 return eventLighting or nil
end
-- Nothing can begin or end before `seconds` from now.
local function worldFree(seconds:number):boolean
 local l=lightingModule()
 if l and l.Active then return false end
 local state=worldState()
 if not state then return true end
 local kind,ends=state:GetAttribute('State'),state:GetAttribute('EndTimestamp')
 if type(ends)~='number'then return kind==nil end
 local left=ends-workspace:GetServerTimeNow()
 -- NORMAL ends in a 60 s warning before the event itself lights up.
 if kind=='NORMAL'then return left+60>seconds+3 end
 if kind=='WARNING'then return left>seconds+3 end
 return false
end
-- An event is coming, running or ending (or its lighting has not let go yet).
local function worldBusy():boolean
 local state=worldState()
 local kind=state and state:GetAttribute('State')
 if kind~=nil and kind~='NORMAL'then return true end
 local l=lightingModule()
 return l~=nil and l.Active==true
end

---------------------------------------------------------------- sky
-- Objects the sky borrows when the place has none (a neutral Atmosphere, Clouds...). A world
-- event adopts the first Clouds/Sky it finds, so a borrowed one is only removed once the
-- world is back to NORMAL.
local made={}
local sweeping=false
local function sweep()
 if sweeping then return end
 sweeping=true
 task.spawn(function()
  repeat
   task.wait(2)
   local waiting=false
   for className,m in pairs(made)do
    if m.Users<=0 then
     if worldBusy()then waiting=true
     else made[className]=nil;m.Instance:Destroy()end
    end
   end
  until not waiting
  sweeping=false
 end)
end
local function borrow(className:string,parent:Instance,neutral:{[string]:any})
 local found=parent:FindFirstChildOfClass(className)
 local m=made[className]
 if found and not(m and m.Instance==found)then return found,function()end end
 if not m or not m.Instance.Parent then
  local o=Instance.new(className)
  o.Name='DOGROTS_Secret'..className
  for k,v in pairs(neutral)do (o::any)[k]=v end
  o.Parent=parent
  m={Instance=o,Users=0};made[className]=m
 end
 local mine=m
 mine.Users+=1
 local given=false
 return mine.Instance,function()
  if given then return end
  given=true;mine.Users-=1
  if mine.Users>0 or made[className]~=mine then return end
  if worldBusy()then sweep()else made[className]=nil;mine.Instance:Destroy()end
 end
end
-- What a theme's Lighting/Atmosphere would have done, approximated with the camera grade.
local function fallbackGrade(patch:{[string]:any}):{[string]:any}?
 local light=patch.Lighting or {}
 local dim=0
 if type(light.ClockTime)=='number'and(light.ClockTime<5.5 or light.ClockTime>19.5)then dim-=.22 end
 if type(light.ExposureCompensation)=='number'then dim+=math.clamp((light.ExposureCompensation-.08)*.2,-.3,.2)end
 if type(light.Brightness)=='number'then dim+=math.clamp((light.Brightness-2.25)*.08,-.2,.1)end
 local grade={}
 if math.abs(dim)>.01 then grade.Brightness=dim end
 local air=patch.Atmosphere
 if air and typeof(air.Color)=='Color3'then grade.TintColor=Color3.new(1,1,1):Lerp(air.Color,.25)end
 return next(grade)and grade or nil
end
local function mix(key:string,a:any,b:any,t:number,out:boolean):any
 local ta=typeof(a)
 if ta~=typeof(b)then return (out and t>=1 or not out and t>0)and b or a end
 if key=='ClockTime'and ta=='number'then
  local d=((b-a+12)%24)-12
  return (a+d*t)%24
 end
 if ta=='number'then return a+(b-a)*t end
 if ta=='Color3'or ta=='Vector3'then return (a::any):Lerp(b,t)end
 -- Booleans and the like switch at the start of a fade in and the end of a fade out.
 return (out and t>=1 or not out and t>0)and b or a
end
-- Skies holding the world's Lighting objects; they let go when a world event approaches.
local holding:{[any]:boolean}={}
local watched:Instance?=nil
local function watchWorld()
 local state=worldState()
 if not state or watched==state then return end
 watched=state
 local function changed()
  local kind=state:GetAttribute('State')
  if kind==nil or kind=='NORMAL'then return end
  -- A warning leaves time to ease out; an event starting at once takes the light now,
  -- before WorldEventLighting snapshots it as its baseline.
  for sky in pairs(holding)do sky.Lose(kind=='WARNING'and 1.5 or 0)end
 end
 state:GetAttributeChangedSignal('State'):Connect(changed)
 state:GetAttributeChangedSignal('EventId'):Connect(changed)
end
task.spawn(function()
 local events=RS:WaitForChild('WorldEvents',60)
 if events and events:WaitForChild('State',60)then watchWorld()end
end)
--[[ scope:Sky(theme, fadeIn?, fadeOut?) → handle
 Turns the whole sky and the island's light for this client. Every field is optional:
  Lighting   = {ClockTime, Brightness, ExposureCompensation, Ambient, OutdoorAmbient,
                FogColor, FogStart, FogEnd, EnvironmentDiffuseScale, EnvironmentSpecularScale,
                ColorShift_Top, ColorShift_Bottom}
  Atmosphere = {Density, Offset, Color, Decay, Glare, Haze}
  Clouds     = {Cover, Density, Color}
  Sky        = {StarCount, CelestialBodiesShown, SunAngularSize, MoonAngularSize}
  Rays       = {Intensity, Spread}   (the place's SunRaysEffect, if it has one)
  Grade      = {TintColor, Saturation, Contrast, Brightness}   (a camera ColorCorrection)
  Bloom      = {Intensity, Size, Threshold}                    (a camera Bloom)
 Eases in over fadeIn (default 1.2 s) and back over fadeOut (default 1.5 s) once the scope
 ends; held meanwhile against the server's day cycle (what it writes is what comes back).
 The world's light (Lighting, Atmosphere, Clouds, Sky, Rays) is only touched while no world
 event can begin or end before the arrival is over (scope.EndsAt, set by the director from
 Hold; a longer act sets its own) and fades out; otherwise those become an approximate
 camera grade. If an event still turns up (a warning, or one forced at once), the world's
 light eases back to the server's at once and the look carries on in the grade alone.
 handle.Free: true while it holds the world's light. handle:Set(patch, seconds) eases to new
 values (same shape as theme); handle:Release(seconds) lets go early. ]]
function Scope:Sky(theme:{[string]:any},fadeIn:number?,fadeOut:number?)
 watchWorld()
 local tracks={}
 local worldGives,ownGives={},{}
 local wanted:{[string]:{[string]:any}}={}
 local function hold(o:Instance,props:{[string]:any}?,world:boolean)
  for k,v in pairs(props or {})do
   local existing
   for _,t in ipairs(tracks)do if t.O==o and t.K==k then existing=t end end
   if existing then existing.To=v
   else
    local ok,now=pcall(function()return (o::any)[k]end)
    if ok and now~=nil then
     local release,update,base=K.Layer(o,{[k]=now},true)
     table.insert(tracks,{O=o,K=k,From=now,To=v,Value=now,Update=update,Release=release,Base=base,World=world})
    end
   end
  end
 end
 local camera=workspace.CurrentCamera
 local grade,bloom
 local function gradeObject():ColorCorrectionEffect?
  if not grade and camera then
   local g=Instance.new('ColorCorrectionEffect');g.Name='DOGROTS_SecretSkyGrade';g.Parent=camera
   grade=g
   table.insert(ownGives,function()g:Destroy()end)
  end
  return grade
 end
 local function bloomObject():BloomEffect?
  if not bloom and camera then
   local b=Instance.new('BloomEffect');b.Name='DOGROTS_SecretSkyBloom';b.Intensity=0;b.Size=24;b.Threshold=2
   b.Parent=camera
   bloom=b
   table.insert(ownGives,function()b:Destroy()end)
  end
  return bloom
 end
 -- Decided up front: free of world events until this arrival ends and fades out.
 local ends=self.EndsAt
 local free=worldFree((type(ends)=='number'and math.max(ends-workspace:GetServerTimeNow(),0)or 20)+(fadeOut or 1.5))
 local handle={Free=free}
 local released=false
 -- The theme as asked so far: the grade it falls back to is worked out from all of it.
 local function remember(given:{[string]:any})
  for section,props in pairs(given)do
   if type(props)=='table'then
    local into=wanted[section]or {}
    wanted[section]=into
    for k,v in pairs(props)do into[k]=v end
   end
  end
 end
 local function apply(given:{[string]:any})
  remember(given)
  if free then
   if given.Lighting then hold(Lighting,given.Lighting,true)end
   if given.Atmosphere then
    local o,give=borrow('Atmosphere',Lighting,{Density=0,Offset=0,Glare=0,Haze=0})
    table.insert(worldGives,give);hold(o,given.Atmosphere,true)
   end
   if given.Clouds then
    local o,give=borrow('Clouds',workspace.Terrain,{Cover=0,Density=0})
    table.insert(worldGives,give);hold(o,given.Clouds,true)
   end
   if given.Sky then
    local o,give=borrow('Sky',Lighting,{})
    table.insert(worldGives,give);hold(o,given.Sky,true)
   end
   if given.Rays then
    local rays=Lighting:FindFirstChildOfClass('SunRaysEffect')
    if rays then hold(rays,given.Rays,true)end
   end
   if given.Grade then local g=gradeObject();if g then hold(g,given.Grade,false)end end
  else
   local merged=table.clone(wanted.Grade or {})
   for k,v in pairs(fallbackGrade(wanted)or {})do
    if k=='Brightness'then merged.Brightness=(merged.Brightness or 0)+v
    elseif merged[k]==nil then merged[k]=v end
   end
   if next(merged)then local g=gradeObject();if g then hold(g,merged,false)end end
  end
  if given.Bloom then local b=bloomObject();if b then hold(b,given.Bloom,false)end end
 end
 local connection:RBXScriptConnection?=nil
 local function run(seconds:number,out:boolean,done:(()->())?)
  for _,t in ipairs(tracks)do t.From=t.Value end
  local started=os.clock()
  if connection then connection:Disconnect()end
  local function step()
   local a=seconds>0 and smooth((os.clock()-started)/seconds)or 1
   for _,t in ipairs(tracks)do
    local to=out and t.Base(t.K)or t.To
    if to~=nil then
     local v=mix(t.K,t.From,to,a,out)
     t.Value=v;t.Update(t.K,v)
    end
   end
   if a>=1 then
    if connection then connection:Disconnect();connection=nil end
    if done then done()end
   end
  end
  connection=Run.RenderStepped:Connect(step)
  step()
 end
 -- A world event turned up: the world's light eases back to what the server has (and is
 -- let go), the rest of the look carries on in the grade.
 function handle.Lose(seconds:number)
  if not free then return end
  free=false;handle.Free=false
  holding[handle]=nil
  local leaving={}
  for i=#tracks,1,-1 do
   if tracks[i].World then table.insert(leaving,table.remove(tracks,i))end
  end
  local gives=worldGives
  worldGives={}
  local function finish()
   for _,t in ipairs(leaving)do t.Release()end
   for _,give in ipairs(gives)do give()end
  end
  if seconds<=0 then finish()
  else
   for _,t in ipairs(leaving)do t.From=t.Value end
   local started=os.clock()
   local easing:RBXScriptConnection
   easing=Run.RenderStepped:Connect(function()
    local a=smooth((os.clock()-started)/seconds)
    for _,t in ipairs(leaving)do
     local to=t.Base(t.K)
     if to~=nil then local v=mix(t.K,t.From,to,a,true);t.Value=v;t.Update(t.K,v)end
    end
    if a>=1 then easing:Disconnect();finish()end
   end)
  end
  if not released then apply({});run(math.max(seconds,.6),false)end
 end
 function handle:Set(patch:{[string]:any},seconds:number?)
  if released then return end
  apply(patch);run(seconds or 1,false)
 end
 function handle:Release(seconds:number?)
  if released then return end
  released=true
  run(seconds or fadeOut or 1.5,true,function()
   holding[handle]=nil
   for _,t in ipairs(tracks)do t.Release()end
   for _,give in ipairs(worldGives)do give()end
   for _,give in ipairs(ownGives)do give()end
  end)
 end
 apply(theme)
 if free then holding[handle]=true end
 run(fadeIn or 1.2,false)
 self:Add(function()handle:Release()end)
 return handle
end

---------------------------------------------------------------- colossus
local definitions
local function visualAsset(dogId:string):string?
 if definitions==nil then
  local ok,result=pcall(function()return require(RS:WaitForChild('DogEconomy'):WaitForChild('DogDefinitions'))end)
  definitions=ok and type(result)=='table'and result or false
 end
 local d=definitions and definitions[dogId]
 return d and d.VisualAsset or nil
end
-- A clean local copy of a dog that every client has, whatever is streamed in.
function K.DogCopy(dogId:string,fallback:Model?):Model?
 local menu=RS:FindFirstChild('MenuModels')
 local name=visualAsset(dogId)
 local source=menu and name and menu:FindFirstChild(name)
 if not(source and source:IsA('Model'))then
  source=fallback and fallback:FindFirstChildWhichIsA('BasePart',true)and fallback or nil
 end
 if not source then return nil end
 local ok,copy=pcall(function()return source:Clone()end)
 if not ok or not copy then return nil end
 for _,o in ipairs(copy:GetDescendants())do
  if o:IsA('LuaSourceContainer')or o:IsA('ProximityPrompt')or o:IsA('BillboardGui')or o:IsA('Sound')
   or o:IsA('ParticleEmitter')or o:IsA('Highlight')or o:IsA('JointInstance')or o:IsA('Constraint')then o:Destroy()
  elseif o:IsA('BasePart')then
   o.Anchored=true;o.CanCollide=false;o.CanTouch=false;o.CanQuery=false;o.CastShadow=false;o.Massless=true
  end
 end
 copy:SetAttribute('DogId',dogId)
 if not copy.PrimaryPart then
  local root=copy:FindFirstChild('RootPart',true)
  if root and root:IsA('BasePart')then copy.PrimaryPart=root end
 end
 return copy::Model
end
-- Visible bounds of a model in its pivot's space (the invisible RootPart left out).
local function bounds(model:Model)
 local pivot=model:GetPivot()
 local lo,hi
 for _,p in ipairs(model:GetDescendants())do
  if p:IsA('BasePart')and p.Transparency<1 and p.Name~='RootPart'then
   local half=p.Size/2
   for _,x in ipairs({-1,1})do for _,y in ipairs({-1,1})do for _,z in ipairs({-1,1})do
    local c=pivot:PointToObjectSpace(p.CFrame:PointToWorldSpace(Vector3.new(half.X*x,half.Y*y,half.Z*z)))
    lo=lo and lo:Min(c)or c;hi=hi and hi:Max(c)or c
   end end end
  end
 end
 if not lo then return Vector3.zero,Vector3.one end
 return (lo+hi)/2,hi-lo
end
K.Bounds=bounds
-- Whatever is fading out after its scope ended lives here until it is gone.
local function afterglow():Folder
 local root=K.FXRoot()
 local folder=root:FindFirstChild('Afterglow')
 if not(folder and folder:IsA('Folder'))then
  local f=Instance.new('Folder');f.Name='Afterglow';f.Parent=root
  folder=f
 end
 return folder::Folder
end
--[[ scope:Colossus(options) → handle | nil
 A colossal copy of a dog over the island, seen from every yard (a local clone of
 ReplicatedStorage.MenuModels, so it does not depend on what is streamed in).
  DogId   the dog (default options.Ctx.DogId)       Ctx   the arrival ctx (for DogId/Origin)
  Height  studs tall (default 160; 180-260 reads best in the sky)
  At      CFrame of its visual centre, fixed in the world. Default: in each player's own sky,
          Distance (480) studs beyond the venue as they see it, Elevation (14) degrees up,
          facing them (a fixed spot over the island is out of every player's shot)
  Face    the venue it hangs beyond (default the arrival's Origin); Tilt radians it leans down
  Style   'Solid' | 'Ghost' (glowing, see-through) | 'Silhouette' (black) | 'Hologram'
  Color   colour for Ghost / Silhouette / Hologram;  Alpha see-through 0..1
  Clip    a clip of DogAnimationClips/<DogId> to play (looped unless Once=true), Speed
  Rise    studs it rises from below while fading in (default 0)
  FadeIn  seconds (default 1.2)
 handle: Model, Animator, Center() → Vector3, Frame() → CFrame, Pose(cframe, seconds?) (pins it
  there; Pose(nil, seconds?) hands it back to the player's own sky), Play(clip, looped?, speed?),
  Fade(alpha, seconds?), Stop(seconds?) (fades out and removes it, and still fades out when
  the scope ends right after; Clean stops it over 1.2 s). ]]
function Scope:Colossus(options:{[string]:any})
 local ctx=options.Ctx
 local dogId=options.DogId or ctx and ctx.DogId
 if not dogId then return nil end
 local copy=K.DogCopy(dogId,ctx and ctx.Model)
 if not copy then return nil end
 local model:Model=copy
 local _,size=bounds(model)
 local height=options.Height or 160
 local factor=height/math.max(size.Y,.1)
 pcall(function()model:ScaleTo(model:GetScale()*factor)end)
 local centre=bounds(model)
 local style=options.Style or 'Solid'
 local alpha=options.Alpha or (style=='Ghost'and .35 or style=='Hologram'and .5 or 0)
 local parts:{BasePart}={}
 for _,o in ipairs(model:GetDescendants())do
  if style~='Solid'and(o:IsA('SurfaceAppearance')or o:IsA('Decal')or o:IsA('Texture'))then o:Destroy()
  elseif o:IsA('BasePart')then
   if o.Name=='RootPart'then o.Transparency=1
   else
    table.insert(parts,o)
    if style~='Solid'then
     pcall(function()(o::any).TextureID=''end)
     o.Color=options.Color or Color3.new(0,0,0)
     o.Material=style=='Silhouette'and Enum.Material.SmoothPlastic or style=='Hologram'and Enum.Material.ForceField or Enum.Material.Neon
    end
    o.LocalTransparencyModifier=1
   end
  end
 end
 local face=options.Face or ctx and ctx.Origin or K.Map.Mouth
 local function place(at:CFrame)model:PivotTo(at*CFrame.new(-centre))end
 -- Where it hangs: a fixed CFrame (options.At), or by default in this player's own sky
 -- beyond the venue: Distance studs out along the bearing from the camera to Face, its
 -- centre Elevation degrees up, facing back at them, so it is on screen whenever they
 -- look toward the arrival (a camera only sees ~15-20 degrees above the horizon, so
 -- anything hung over the island itself is out of shot).
 local fixed=options.At~=nil
 local distance=options.Distance or 480
 local elevation=math.rad(options.Elevation or 14)
 local bearing:Vector3?=nil
 local function skyFrame(dt:number):CFrame
  local cam=workspace.CurrentCamera
  local eye=cam and cam.CFrame.Position or K.Map.Center
  local flat=Vector3.new(face.X-eye.X,0,face.Z-eye.Z)
  local want=flat.Magnitude>24 and flat.Unit or bearing or(cam and Vector3.new(cam.CFrame.LookVector.X,0,cam.CFrame.LookVector.Z))
  if not want or want.Magnitude<1e-3 then want=Vector3.new(0,0,-1)end
  want=want.Unit
  -- Swings round slowly when the player walks round the venue, and never flips.
  bearing=bearing and bearing:Lerp(want,math.min(1,dt*1.5))or want
  local dir=(bearing::Vector3).Magnitude>1e-3 and(bearing::Vector3).Unit or want
  local p=eye+dir*distance*math.cos(elevation)+Vector3.new(0,distance*math.sin(elevation),0)
  return CFrame.lookAt(p,p-dir)*CFrame.Angles(-(options.Tilt or 0),0,0)
 end
 local current:CFrame=fixed and options.At or skyFrame(1)
 local rise=options.Rise or 0
 place(current-Vector3.new(0,rise,0))
 model.Name='Colossus_'..dogId
 model.Parent=self.Folder
 local handle={Model=model,Animator=nil}
 local animator
 pcall(function()animator=AnimationPlayer.new(model,dogId)end)
 handle.Animator=animator
 local live=true
 -- Movement and fading run on one step (its own, so a fade-out outlives the scope).
 local moveFrom,moveTo,moveStart,moveSeconds=current,current,0,0
 local fadeFrom,fadeTo,fadeStart,fadeSeconds=1,alpha,os.clock(),options.FadeIn or 1.2
 local riseLeft=rise
 local value=-1
 local function applyAlpha(a:number)
  if math.abs(a-value)<1e-4 then return end
  value=a
  for _,p in ipairs(parts)do p.LocalTransparencyModifier=a end
 end
 local stopping=false
 local connection
 connection=Run.RenderStepped:Connect(function(dt)
  if not model.Parent then connection:Disconnect();return end
  local now=os.clock()
  local f=fadeSeconds>0 and smooth((now-fadeStart)/fadeSeconds)or 1
  applyAlpha(fadeFrom+(fadeTo-fadeFrom)*f)
  local m=moveSeconds>0 and smooth((now-moveStart)/moveSeconds)or 1
  if not fixed then
   local sky=skyFrame(dt)
   current=m<1 and moveFrom:Lerp(sky,m)or sky
  elseif moveSeconds>0 then
   current=moveFrom:Lerp(moveTo,m)
  end
  local lift=riseLeft*(1-f)
  place(current-Vector3.new(0,lift,0))
  if f>=1 then riseLeft=0 end
  if animator and animator.Clip then pcall(function()animator:Step()end)end
  if stopping and f>=1 then connection:Disconnect();model:Destroy()end
 end)
 function handle:Center():Vector3 return current.Position end
 function handle:Frame():CFrame return current end
 -- Pins it to a world CFrame (gliding there over `seconds`), leaving the sky placement;
 -- nil hands it back to this player's own sky.
 function handle:Pose(cf:CFrame?,seconds:number?)
  moveFrom,moveStart,moveSeconds=current,os.clock(),seconds or 0
  if cf==nil then
   fixed=false;bearing=nil
  else
   fixed=true;moveTo=cf
   if (seconds or 0)<=0 then current=cf;moveSeconds=0 end
  end
 end
 function handle:Play(clip:string,looped:boolean?,speed:number?)
  -- A one-shot clip asked to loop repeats with a short recovery (DogAnimationPlayer).
  if animator then pcall(function()animator:Play(clip,{FadeTime=.25,Looped=looped==true,Speed=speed})end)end
 end
 function handle:Fade(a:number,seconds:number?)
  fadeFrom,fadeTo,fadeStart,fadeSeconds=value<0 and 1 or value,a,os.clock(),seconds or .6
 end
 local owner=self
 function handle:Stop(seconds:number?)
  if not live then return end
  live=false;stopping=true
  local s=seconds or 1.2
  if s<=0 then connection:Disconnect();model:Destroy();return end
  self:Fade(1,s)
  -- It fades out of the afterglow (with its outline), whatever happens to the scope.
  if model.Parent then
   for _,o in ipairs(owner.Folder:GetChildren())do
    if o:IsA('Highlight')and o.Adornee==model then
     o.Parent=model
     K.Tween(o,s,{FillTransparency=1,OutlineTransparency=1})
    end
   end
   model.Parent=afterglow()
   task.delay(s+1,function()if model.Parent then connection:Disconnect();model:Destroy()end end)
  end
 end
 if options.Clip then handle:Play(options.Clip,not options.Once,options.Speed)end
 self:Add(function()handle:Stop(1.2)end)
 return handle
end

---------------------------------------------------------------- cutaway
local CAS=game:GetService('ContextActionService')
-- A fresh character's camera belongs to WelcomeArrival for a few seconds.
local spawnedAt=player.Character and -math.huge or os.clock()
player.CharacterAdded:Connect(function()spawnedAt=os.clock()end)
local function mainGui():Instance?
 local gui=player:FindFirstChild('PlayerGui')
 return gui and gui:FindFirstChild('ScreenGui')
end
-- Someone else owns this player's camera or attention: a scripted camera (DOG-O-MATIC, the
-- lab, events, WelcomeArrival), an FOV zoom, an open menu, a dead or brand-new character.
local function busyMenu(main:Instance):boolean
 return main:GetAttribute('OpenMenu')~=nil or(main:GetAttribute('ModalOwnerCount')or 0)>0
  or main:GetAttribute('RewardMachineWorldOpen')==true
end
-- The touch thumbstick and the gamepad move through the PlayerModule, not through the
-- PlayerActions a CAS sink holds.
local controls:any=nil
local function playerControls():any
 if controls then return controls end
 local ok,result=pcall(function()
  local scripts=player:FindFirstChild('PlayerScripts')
  local module=scripts and scripts:FindFirstChild('PlayerModule')
  return module and require(module::ModuleScript):GetControls()
 end)
 if ok and type(result)=='table'then controls=result end
 return controls
end
-- Turns the controls a cutaway turned off back on, once. A menu that opened over the
-- cutaway found them already off and left them to us, so they come back when it closes
-- (or after two minutes, or with the GUI gone: never stuck).
local function giveBack(c:any)
 local main=mainGui()
 if not(main and busyMenu(main))then pcall(function()c:Enable()end);return end
 local links:{RBXScriptConnection}={}
 local done=false
 local function back(force:boolean)
  if done or(not force and main.Parent and busyMenu(main))then return end
  done=true
  for _,link in ipairs(links)do link:Disconnect()end
  pcall(function()c:Enable()end)
 end
 for _,key in ipairs({'OpenMenu','ModalOwnerCount','RewardMachineWorldOpen'})do
  table.insert(links,main:GetAttributeChangedSignal(key):Connect(function()back(false)end))
 end
 table.insert(links,main.AncestryChanged:Connect(function()if not main.Parent then back(true)end end))
 task.delay(120,back,true)
end
local function busy(camera:Camera):boolean
 if camera.CameraType~=Enum.CameraType.Custom then return true end
 if camera:GetAttribute('DiscoveryZoom')~=nil or camera:GetAttribute('SecretCutaway')~=nil then return true end
 -- An arrival's own FOV punch (SecretPunch) gives way; anyone else's zoom does not.
 if camera:GetAttribute('SecretZoom')~=nil and camera:GetAttribute('SecretPunch')~=true then return true end
 local main=mainGui()
 if main and busyMenu(main)then return true end
 if workspace:FindFirstChild('LocalGeneticsFX')then return true end
 local character=player.Character
 local humanoid=character and character:FindFirstChildOfClass('Humanoid')
 if not humanoid or humanoid.Health<=0 then return true end
 return os.clock()-spawnedAt<5
end
-- Camera and FOV along keyframes at time t (fov nil when no shot around t sets one).
local function sampleShots(list:{{[string]:any}},t:number,fov0:number?):(CFrame,number?)
 local first,last=list[1],list[#list]
 if t<=first.At or #list==1 then return first.CFrame,first.Fov or fov0 end
 for i=1,#list-1 do
  local a,b=list[i],list[i+1]
  if t<b.At then
   if b.Cut then return a.CFrame,a.Fov or fov0 end
   local u=(t-a.At)/math.max(b.At-a.At,1e-3)
   if not b.Linear then u=smooth(u)end
   local fa,fb=a.Fov or fov0,b.Fov or fov0
   return a.CFrame:Lerp(b.CFrame,u),(fa and fb)and fa+(fb-fa)*u or fa or fb
  end
 end
 return last.CFrame,last.Fov or fov0
end
--[[ scope:Cutaway(ctx, shots, options) → handle | nil
 For the arrival's big moment every player's camera leaves them and comes back. shots are
 camera keyframes on the arrival clock: {At=seconds, CFrame=camera, Fov=degrees?, Cut=true
 (jump to it instead of gliding), Linear=true (no easing into it)}. Build CFrames with
 K.Frame(position, lookAt) or K.Orbit(centre, radius, height, angle). The camera glides
 between them and is handed back (with a short dip to black) after the last one; the
 character stands still meanwhile (keyboard, touch thumbstick and gamepad).
 A cutaway is a moment, not a film: shots more than 6 s after the first are cut off (the
 camera stops where it would have been at 6 s) unless options.Long is true.
 options: Focus (Vector3 to stream in first; default ctx.Origin), Bars (letterbox fraction,
  default .09), Shake (handheld wobble 0..1, default .12), Long.
 Nobody is pulled away when ReducedMotion is on, SecretArrivalConfig.Cutaway is false, the
 camera is busy (see busy above) or the client arrives too late; it gives up the moment the
 player dies, opens a menu or another script takes the camera. Returns nil when skipped up
 front, else a handle (Active, Shake(power, seconds), Stop()). ]]
function Scope:Cutaway(ctx:any,shots:{{[string]:any}},given:{[string]:any}?)
 local options:{[string]:any}=given or {}
 if #shots==0 or Config.Cutaway==false or K.ReducedMotion()then return nil end
 local list=table.clone(shots)
 table.sort(list,function(a,b)return a.At<b.At end)
 if not options.Long then
  local cap=list[1].At+6
  if list[#list].At>cap then
   local cf,fov=sampleShots(list,cap,nil)
   local kept={}
   for _,s in ipairs(list)do if s.At<cap then table.insert(kept,s)end end
   table.insert(kept,{At=cap,CFrame=cf,Fov=fov,Linear=true})
   list=kept
  end
 end
 local first,last=list[1],list[#list]
 if ctx:Elapsed()>last.At-.75 then return nil end
 local camera=workspace.CurrentCamera
 if not camera then return nil end
 local focus=options.Focus or ctx.Origin
 if typeof(focus)=='Vector3'then
  task.spawn(function()pcall(function()player:RequestStreamAroundAsync(focus,3)end)end)
 end
 local handle={Active=false}
 local name='DOGROTS_SecretCutaway_'..string.sub(tostring(handle),-8)
 local saved:any=nil
 local bars={}
 local watches:{RBXScriptConnection}={}
 local frozen:any=nil
 local shakeUntil,shakePower=0,0
 local base=options.Shake or .12
 local function sample(t:number):(CFrame,number)
  local fov0=saved and saved.Fov or 70
  local cf,fov=sampleShots(list,t,fov0)
  return cf,fov or fov0
 end
 local function finish(restore:boolean)
  if not handle.Active then return end
  handle.Active=false
  Run:UnbindFromRenderStep(name)
  CAS:UnbindAction(name)
  -- The controls this cutaway turned off come back exactly once.
  if frozen then
   local c=frozen;frozen=nil
   giveBack(c)
  end
  for _,c in ipairs(watches)do c:Disconnect()end
  table.clear(watches)
  local ours=camera:GetAttribute('SecretCutaway')==name
  if ours then camera:SetAttribute('SecretCutaway',nil);camera:SetAttribute('SecretZoom',nil)end
  if restore and ours and camera.CameraType==Enum.CameraType.Scriptable then
   local character=player.Character
   local humanoid=character and character:FindFirstChildOfClass('Humanoid')
   local root=character and character:FindFirstChild('HumanoidRootPart')
   local moved=(root and root:IsA('BasePart')and saved.Root)and root.Position-saved.Root or Vector3.zero
   camera.FieldOfView=saved.Fov
   camera.Focus=saved.Focus+moved
   camera.CFrame=saved.CFrame+moved
   local subject=saved.Subject
   if not subject or not subject.Parent then subject=humanoid end
   if subject then camera.CameraSubject=subject end
   camera.CameraType=saved.Type
   K.Flash(Color3.new(0,0,0),.15,.45)
  end
  for _,b in ipairs(bars)do
   K.Tween(b,.5,{Size=UDim2.fromScale(1,0)}).Completed:Connect(function()b:Destroy()end)
  end
  table.clear(bars)
 end
 local function begin()
  if busy(camera)then return end
  local character=player.Character
  local humanoid=character and character:FindFirstChildOfClass('Humanoid')
  local root=character and character:FindFirstChild('HumanoidRootPart')
  local trueFov=camera:GetAttribute('SecretPunch')and camera:GetAttribute('SecretZoom')
  saved={Type=camera.CameraType,Subject=camera.CameraSubject,Fov=type(trueFov)=='number'and trueFov or camera.FieldOfView,
   CFrame=camera.CFrame,Focus=camera.Focus,
   Root=root and root:IsA('BasePart')and root.Position or nil}
  camera:SetAttribute('SecretCutaway',name)
  -- Other FOV owners save this instead of whatever the cutaway shows.
  camera:SetAttribute('SecretZoom',saved.Fov)
  camera.CameraType=Enum.CameraType.Scriptable
  handle.Active=true
  CAS:BindActionAtPriority(name,function()return Enum.ContextActionResult.Sink end,false,3001,
   Enum.PlayerActions.CharacterForward,Enum.PlayerActions.CharacterBackward,Enum.PlayerActions.CharacterLeft,
   Enum.PlayerActions.CharacterRight,Enum.PlayerActions.CharacterJump)
  -- Touch and gamepad too (left alone if a menu already turned them off).
  local c=playerControls()
  if c and c.controlsEnabled~=false and pcall(function()c:Disable()end)then frozen=c end
  -- Give up the moment the player is needed elsewhere.
  if humanoid then table.insert(watches,humanoid.Died:Connect(function()finish(true)end))end
  if character then
   table.insert(watches,character.AncestryChanged:Connect(function(_,parent)if not parent then finish(true)end end))
  end
  local main=mainGui()
  if main then
   for _,key in ipairs({'OpenMenu','ModalOwnerCount','RewardMachineWorldOpen'})do
    table.insert(watches,main:GetAttributeChangedSignal(key):Connect(function()if busyMenu(main)then finish(true)end end))
   end
  end
  K.Flash(Color3.new(0,0,0),.2,.35)
  local fraction=options.Bars or .09
  for i,anchor in ipairs({0,1})do
   local b=Instance.new('Frame');b.Name='CutawayBar';b.BorderSizePixel=0;b.BackgroundColor3=Color3.new(0,0,0)
   b.AnchorPoint=Vector2.new(0,anchor);b.Position=UDim2.fromScale(0,anchor);b.Size=UDim2.fromScale(1,0);b.ZIndex=2
   b.Parent=K.Screen()
   K.Tween(b,.45,{Size=UDim2.fromScale(1,i==1 and fraction or fraction*.6)})
   bars[i]=b
  end
  -- After every other camera writer (WelcomeArrival, the DOG-O-MATIC, shakes: +1..+4).
  Run:BindToRenderStep(name,Enum.RenderPriority.Camera.Value+6,function()
   if camera.CameraType~=Enum.CameraType.Scriptable or camera:GetAttribute('SecretCutaway')~=name then
    finish(false);return
   end
   local t=ctx:Elapsed()
   if t>=last.At or not self.Alive then finish(true);return end
   local cf,fov=sample(t)
   local now=os.clock()
   local g=base+(now<shakeUntil and shakePower*math.min(shakeUntil-now,1)or 0)
   if g>0 then
    cf*=CFrame.Angles(math.noise(now*1.7,3)*g*.035,math.noise(now*1.3,7)*g*.035,math.noise(now*9,11)*g*.02)
   end
   camera.CFrame=cf;camera.FieldOfView=fov
   camera.Focus=CFrame.new(typeof(focus)=='Vector3'and focus or(cf*CFrame.new(0,0,-40)).Position)
  end)
 end
 function handle:Shake(power:number,seconds:number)
  local now=os.clock()
  shakePower=now<shakeUntil and math.max(shakePower,power)or power
  shakeUntil=math.max(shakeUntil,now+seconds)
 end
 function handle:Stop()finish(true)end
 task.spawn(function()
  if not ctx:Wait(first.At)then return end
  if ctx:Elapsed()>last.At-.75 then return end
  begin()
 end)
 self:Add(function()finish(true)end)
 return handle
end

---------------------------------------------------------------- banner
local STYLE={
 Alert={Font=Enum.Font.LuckiestGuy,Kicker=Enum.Font.GothamBlack,Band=Color3.fromRGB(14,10,6)},
 Glitch={Font=Enum.Font.Arcade,Kicker=Enum.Font.RobotoMono,Band=Color3.fromRGB(6,8,14)},
 Divine={Font=Enum.Font.Fondamento,Kicker=Enum.Font.GothamBold,Band=Color3.fromRGB(40,30,8)},
 Horror={Font=Enum.Font.Creepster,Kicker=Enum.Font.SpecialElite,Band=Color3.fromRGB(8,0,0)},
 Toxic={Font=Enum.Font.Bangers,Kicker=Enum.Font.RobotoMono,Band=Color3.fromRGB(6,14,4)},
 Void={Font=Enum.Font.GrenzeGotisch,Kicker=Enum.Font.SpecialElite,Band=Color3.fromRGB(0,0,0)},
}
local bannerGui:ScreenGui?=nil
local function bannerRoot():ScreenGui
 if bannerGui and bannerGui.Parent then return bannerGui end
 local g=Instance.new('ScreenGui');g.Name='DOGROTS_SecretBanner';g.ResetOnSpawn=false;g.IgnoreGuiInset=true
 g.DisplayOrder=97;g.ZIndexBehavior=Enum.ZIndexBehavior.Sibling;g.Parent=player:WaitForChild('PlayerGui')
 bannerGui=g
 return g
end
local function text(parent:Instance,name:string,font:Enum.Font,color:Color3,z:number):TextLabel
 local l=Instance.new('TextLabel');l.Name=name;l:SetAttribute('KeepFont',true)
 l.BackgroundTransparency=1;l.AnchorPoint=Vector2.new(.5,.5);l.Font=font;l.TextColor3=color;l.TextScaled=true
 l.TextStrokeTransparency=.25;l.TextStrokeColor3=Color3.new(0,0,0);l.ZIndex=z;l.Parent=parent
 return l
end
--[[ scope:Banner(options): a map-wide alert across the middle of every screen.
 options: Title (default ctx.Config.Title), Kicker (line above, default '⚠ SECRET DOG ⚠'),
 Text (line below), Color (default ctx.Config.Color), Style 'Alert' | 'Glitch' | 'Divine' |
 'Horror' | 'Toxic' | 'Void' (fonts and motion), Hold seconds (default 3), Ctx, Sting (true:
 a sound every player hears). It fades out by itself and with the scope. ]]
function Scope:Banner(options:{[string]:any})
 local ctx=options.Ctx
 local config=ctx and ctx.Config or {}
 local color=options.Color or config.Color or Color3.new(1,1,1)
 local style=STYLE[options.Style or 'Alert']or STYLE.Alert
 local calm=K.ReducedMotion()
 local root=bannerRoot()
 local band=Instance.new('Frame');band.Name='Banner';band.AnchorPoint=Vector2.new(.5,.5);band.Position=UDim2.fromScale(.5,.38)
 band.Size=UDim2.new(1,0,0,0);band.BackgroundColor3=style.Band;band.BackgroundTransparency=.3;band.BorderSizePixel=0
 band.ClipsDescendants=true;band.Parent=root
 local fadeEdges=Instance.new('UIGradient')
 fadeEdges.Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,1),NumberSequenceKeypoint.new(.18,0),NumberSequenceKeypoint.new(.82,0),NumberSequenceKeypoint.new(1,1)})
 fadeEdges.Parent=band
 local lines={}
 for i,y in ipairs({0,1})do
  local l=Instance.new('Frame');l.Name='Edge';l.AnchorPoint=Vector2.new(.5,y);l.Position=UDim2.fromScale(.5,y)
  l.Size=UDim2.new(1,0,0,3);l.BackgroundColor3=color;l.BorderSizePixel=0;l.ZIndex=2;l.Parent=band
  local g=Instance.new('UIGradient');g.Transparency=fadeEdges.Transparency;g.Parent=l
  lines[i]=l
 end
 local kicker=text(band,'Kicker',style.Kicker,color:Lerp(Color3.new(1,1,1),.5),3)
 kicker.Position=UDim2.fromScale(.5,.2);kicker.Size=UDim2.fromScale(.7,.16);kicker.Text=options.Kicker or '⚠  SECRET DOG  ⚠'
 local title=text(band,'Title',style.Font,color,4)
 title.Position=UDim2.fromScale(.5,.56);title.Size=UDim2.fromScale(.86,.5);title.Text=options.Title or config.Title or 'SECRET'
 local glow=Instance.new('UIStroke');glow.Color=color;glow.Thickness=2;glow.Transparency=.35;glow.Parent=title
 local under=text(band,'Text',style.Kicker,Color3.fromRGB(235,235,235),3)
 under.Position=UDim2.fromScale(.5,.9);under.Size=UDim2.fromScale(.7,.12);under.Text=options.Text or ''
 local pop=Instance.new('UIScale');pop.Scale=calm and 1 or 1.35;pop.Parent=title
 local ghost:TextLabel?=nil
 if not calm and(options.Style=='Glitch'or options.Style=='Horror'or options.Style=='Void')then
  local g=title:Clone();g.Name='Ghost';g.ZIndex=3;g.TextColor3=Color3.fromRGB(255,40,80);g.TextTransparency=.5
  g:ClearAllChildren();g.Parent=band
  ghost=g
 end
 K.Tween(band,.35,{Size=UDim2.new(1,0,.2,0)},Enum.EasingStyle.Back)
 K.Tween(pop,.5,{Scale=1},Enum.EasingStyle.Back)
 if options.Sting~=false then K.Cue('Sting',nil,.9);task.delay(.1,function()K.Cue('Impact',nil,.7)end)end
 local born=os.clock()
 local hold=options.Hold or 3
 local closing=false
 local function close()
  if closing then return end
  closing=true
  for _,l in ipairs({kicker,title,under})do K.Tween(l,.5,{TextTransparency=1,TextStrokeTransparency=1})end
  if ghost then ghost:Destroy()end
  K.Tween(glow,.5,{Transparency=1})
  K.Tween(band,.6,{Size=UDim2.new(1,0,0,0),BackgroundTransparency=1}).Completed:Connect(function()band:Destroy()end)
 end
 local connection
 connection=Run.RenderStepped:Connect(function()
  if not band.Parent then connection:Disconnect();return end
  local age=os.clock()-born
  if not calm then
   local shake=options.Style=='Horror'and 3 or options.Style=='Glitch'and(math.random()<.2 and 6 or 0)or 0
   title.Position=UDim2.new(.5,math.random(-shake,shake),.56,math.random(-shake,shake)*.5)
   if ghost then
    ghost.Position=UDim2.new(.5,math.random(-5,5),.56,math.random(-2,2))
    ghost.Visible=math.random()<.45
   end
   glow.Transparency=.3+.25*math.sin(age*7)
  end
  if age>=hold then connection:Disconnect();close()end
 end)
 self:Add(close)
 return band
end

---------------------------------------------------------------- around every player
--[[ scope:Rain(options) → ParticleEmitter: something falls on THIS player wherever they are
 (an emitter over their camera that follows it). options: ParticleEmitter properties plus
 Area (square side in studs, default 150) and Height (studs above the camera, default 70).
 Low-quality clients get a third of the Rate (set Rate in options, not afterwards). ]]
function Scope:Rain(options:{[string]:any})
 local props=table.clone(options)
 local area,height=props.Area or 150,props.Height or 70
 props.Area=nil;props.Height=nil
 local cloud=self:Part({Name='Rain',Size=Vector3.new(area,1,area),Transparency=1})
 local rate=props.Rate or 60
 props.Rate=K.Low()and rate/3 or rate
 if props.EmissionDirection==nil then props.EmissionDirection=Enum.NormalId.Bottom end
 if props.Speed==nil then props.Speed=NumberRange.new(30,40)end
 if props.SpreadAngle==nil then props.SpreadAngle=Vector2.new(5,5)end
 if props.Lifetime==nil then props.Lifetime=NumberRange.new(2.4,3)end
 local e=self:Emitter(cloud,props)
 self:Every(function()
  local cam=workspace.CurrentCamera
  if not cam then return end
  local p=cam.CFrame.Position
  cloud.CFrame=CFrame.new(p.X,p.Y+height,p.Z)
 end)
 return e
end
--[[ scope:Shockwave(origin, color, options) → handle: a wall of light racing along the
 ground from origin to the far corners of the whole district (K.Map.Min/Max, the north's
 plaza, museum, lab and DOG-O-MATIC included). Every player it passes is jolted (a shake,
 a flash, a thud), harder the nearer they are to origin; a player watching options.Cutaway
 feels it on that camera when it gets there instead.
  Seconds  to reach the farthest corner (default 5), or Speed in studs/s
  Height (default 3), Thickness (default 2), Alpha (start, default .25), Segments (40; 20 Low)
  Shake    peak shake (default .4; 0 none)   Flash  peak strength 0..1 (default .45; false none)
  FlashColor (default color)   Sound  a thud as it passes (default true)
  OnPass   function(distance) when it reaches this player
 ReducedMotion: no shake and no flash. handle: Radius(), Done, Stop(). ]]
function Scope:Shockwave(origin:Vector3,color:Color3,given:{[string]:any}?)
 local options:{[string]:any}=given or {}
 local calm=K.ReducedMotion()
 local reach=0
 for _,x in ipairs({K.Map.Min.X,K.Map.Max.X})do
  for _,z in ipairs({K.Map.Min.Z,K.Map.Max.Z})do reach=math.max(reach,Vector3.new(x-origin.X,0,z-origin.Z).Magnitude)end
 end
 reach+=40
 local seconds=options.Seconds or(options.Speed and reach/options.Speed)or 5
 local count=K.Low()and 20 or(options.Segments or 40)
 local thick,tall,alpha0=options.Thickness or 2,options.Height or 3,options.Alpha or .25
 local wall=Instance.new('Model');wall.Name='Shockwave';wall.Parent=self.Folder
 local parts:{BasePart}={}
 local frames:{CFrame}={}
 local turns:{CFrame}={}
 for i=1,count do
  parts[i]=self:Part({Name='Front',Color=color,Size=Vector3.new(thick,tall,1),Transparency=1,Parent=wall})
  local angle=(i-.5)/count*math.pi*2
  turns[i]=CFrame.lookAt(Vector3.zero,Vector3.new(-math.sin(angle),0,math.cos(angle)))
 end
 local base=Vector3.new(origin.X,origin.Y+tall*.35,origin.Z)
 local started=os.clock()
 local radius=0
 local hitMe,hitCam=false,false
 local handle={Done=false}
 local connection:RBXScriptConnection?=nil
 local function stop()
  if connection then connection:Disconnect();connection=nil end
  handle.Done=true
  wall:Destroy()
 end
 local function radiusAt(u:number):number
  local a=math.clamp(u/seconds,0,1)
  return 6+(reach-6)*(1-(1-a)^2)
 end
 connection=Run.RenderStepped:Connect(function()
  if not self.Alive then stop();return end
  local u=os.clock()-started
  radius=radiusAt(u)
  local far=(radius-6)/(reach-6)
  local width=2*radius*math.sin(math.pi/count)*1.1
  local mid=radius*math.cos(math.pi/count)
  local alpha=math.min(1,alpha0+(1-alpha0)*far^1.4)
  for i,p in ipairs(parts)do
   local t=turns[i]
   frames[i]=CFrame.new(base-t.RightVector*mid)*t
   p.Size=Vector3.new(thick,tall,width);p.Transparency=alpha
  end
  workspace:BulkMoveTo(parts,frames,Enum.BulkMoveMode.FireCFrameChanged)
  local cut=options.Cutaway
  local watching=cut~=nil and cut.Active
  if watching and not hitCam then
   local cam=workspace.CurrentCamera
   local p=cam and cam.CFrame.Position
   if p and radius>=Vector3.new(p.X-origin.X,0,p.Z-origin.Z).Magnitude then
    hitCam=true;cut:Shake(math.min(1.2,(options.Shake or .4)*2),.9)
   end
  end
  if not hitMe then
   local me=K.Me()
   local d=Vector3.new(me.X-origin.X,0,me.Z-origin.Z).Magnitude
   if radius>=d then
    hitMe=true
    local k=1-math.clamp(d/reach,0,1)
    if not watching and not calm then
     local shake=options.Shake or .4
     if shake>0 then K.Shake(shake*(.35+.65*k),.5+.7*k)end
     if options.Flash~=false then K.Flash(options.FlashColor or color,1-(options.Flash or .45)*(.3+.7*k),.55)end
    end
    if options.Sound~=false then K.Cue('Impact',nil,.3+.5*k)end
    if options.OnPass then task.spawn(options.OnPass,d)end
   end
  end
  if u>=seconds then stop()end
 end)
 self:Add(stop)
 function handle:Radius():number return radius end
 function handle:Stop()stop()end
 return handle
end

---------------------------------------------------------------- the district's lights and neon
-- One index per client of every Light and every Neon part under DOGROTS_District (dogs
-- and Secret auras left out), built once in the background a slice at a time and kept up
-- to date as parts stream in and out, so no arrival ever scans the ~37k instances again.
local district={Lights={},Neon={},Done=false}
K.District=district
local listeners:{[(string,Instance)->()]:boolean}={}
local function onDog(o:Instance):boolean
 local m=o:FindFirstAncestorWhichIsA('Model')
 while m do
  if m:GetAttribute('DogId')~=nil or m:GetAttribute('DogUid')~=nil then return true end
  m=m:FindFirstAncestorWhichIsA('Model')
 end
 return false
end
local function indexAdd(o:Instance)
 local kind
 if o:IsA('Light')then
  if o:GetAttribute('SecretAura')==true then return end
  kind='Light'
 elseif o:IsA('BasePart')and o.Material==Enum.Material.Neon then kind='Neon'
 else return end
 if not o.Parent or onDog(o)then return end
 local set=kind=='Light'and district.Lights or district.Neon
 if set[o]then return end
 set[o]=true
 for fn in pairs(listeners)do
  local ok,err=pcall(fn,kind,o)
  if not ok then warn('SecretArrivals district:',err)end
 end
end
local indexing=false
local function startIndex()
 if indexing then return end
 indexing=true
 task.spawn(function()
  local root=workspace:WaitForChild('DOGROTS_District')
  root.DescendantAdded:Connect(indexAdd)
  root.DescendantRemoving:Connect(function(o)district.Lights[o]=nil;district.Neon[o]=nil end)
  local count=0
  for _,group in ipairs(root:GetChildren())do
   indexAdd(group)
   for _,o in ipairs(group:GetDescendants())do
    indexAdd(o)
    count+=1
    if count%1500==0 then task.wait()end
   end
  end
  district.Done=true
 end)
end
-- Ready before the first arrival, without adding to the joining frames.
task.delay(6,startIndex)
--[[ scope:TintLights(color, seconds?, exclude?) → release, set
 Every light in the district turns `color` for this client (black is a blackout), fading
 over `seconds` (default .6). color may be a function(light, its own colour) → Color3.
 Only Color, so WorldEventLighting and WorldDetailQuality keep owning Enabled and
 Brightness; held against other scripts (a colour one of them writes meanwhile is what
 comes back). Lights that stream in later join it. exclude: a set {[Light]=true} or a
 function(light) → boolean. release() lets them go (Clean does too); set(color, seconds?)
 recolours them without stacking another layer. ]]
function Scope:TintLights(color:any,seconds:number?,exclude:any?):(()->(),(any,number?)->())
 startIndex()
 local paint=color
 local span=seconds or .6
 local started=os.clock()
 local tracks:{[Light]:any}={}
 local released=false
 local function skip(light:Light):boolean
  if exclude==nil then return false end
  if type(exclude)=='function'then return exclude(light)==true end
  return exclude[light]==true
 end
 local function goal(light:Light,t:any):Color3
  if type(paint)=='function'then return paint(light,t.Base('Color')or light.Color)end
  return paint
 end
 local function join(light:Light)
  if released or tracks[light]or not light.Parent or skip(light)then return end
  local now=light.Color
  local release,update,base=K.Layer(light,{Color=now},true)
  local t={From=now,Value=now,Update=update,Release=release,Base=base}
  t.To=goal(light,t)
  tracks[light]=t
  -- Joined after the fade (streamed in): straight to the colour.
  if os.clock()-started>=span then t.Value=t.To;update('Color',t.To)end
 end
 local function listen(kind:string,o:Instance)if kind=='Light'then join(o::Light)end end
 listeners[listen]=true
 for light in pairs(district.Lights)do join(light)end
 local fading=false
 local function fade()
  if fading then return end
  fading=true
  self:Every(function()
   local a=span>0 and smooth((os.clock()-started)/span)or 1
   for light,t in pairs(tracks)do
    if light.Parent then local v=t.From:Lerp(t.To,a);t.Value=v;t.Update('Color',v)end
   end
   if a>=1 then fading=false;return false end
   return true
  end)
 end
 fade()
 local function release()
  if released then return end
  released=true
  listeners[listen]=nil
  for _,t in pairs(tracks)do t.Release()end
  table.clear(tracks)
 end
 local function set(newColor:any,newSeconds:number?)
  if released then return end
  paint=newColor;span=newSeconds or .6;started=os.clock()
  for light,t in pairs(tracks)do t.From=t.Value;t.To=goal(light,t)end
  fade()
 end
 self:Add(release)
 return release,set
end
--[[ scope:Blackout(options) → handle: the district's Neon parts (lamp glass, signs, guides,
 bulbs, the museum's and the lab's glow, the north included) change for this client, in a
 wave out from options.From at options.Speed studs/s, or all at once; a slice per frame
 either way, so nothing hitches.
  Filter    function(part) → boolean, which Neon parts (default all of them)
  Color     Color3, or function(part, its own colour) → Color3 (default near black)
  Material  optional, e.g. SmoothPlastic so lamp glass reads unlit
  From, Speed   the wave (default all at once)   Late  seconds it is already under way
  Budget    parts per frame (default 240; 100 on Low)
 Held against other scripts: a colour one of them writes meanwhile is what comes back.
 Parts that stream in later join it. handle:Set(color) recolours what it holds (nearest the
 camera first); handle:Release(wave?) lights them back (wave: true for a wave out from From
 at Speed, or a number for a wave at that many studs/s); Clean releases it too. ]]
function Scope:Blackout(given:{[string]:any}?)
 startIndex()
 local options:{[string]:any}=given or {}
 local filter=options.Filter
 local paint:any=options.Color or Color3.fromRGB(14,12,16)
 local material=options.Material
 local from:Vector3?=options.From
 local speed:number=options.Speed or 0
 local budget=options.Budget or(K.Low()and 100 or 240)
 local started=os.clock()-(options.Late or 0)
 local held:{[BasePart]:any}={}
 local wave:{any}={}
 local head=1
 local extra:{any}={}
 local recolour:{BasePart}={}
 local released=false
 local handle={}
 local function delay(part:BasePart):number
  if not from or speed<=0 then return 0 end
  return (part.Position-from).Magnitude/speed
 end
 local function goal(part:BasePart,own:Color3):Color3
  if type(paint)=='function'then return paint(part,own)end
  return paint
 end
 local function darken(part:BasePart)
  if released or held[part]or not part.Parent then return end
  local props:{[string]:any}={Color=goal(part,part.Color)}
  if material then props.Material=material end
  local release,update,base=K.Layer(part,props,true)
  held[part]={Release=release,Update=update,Base=base}
 end
 local pumping=false
 local function pump()
  if pumping or released then return end
  pumping=true
  task.spawn(function()
   while not released do
    local t=os.clock()-started
    local n=0
    while wave[head]and wave[head].At<=t and n<budget do darken(wave[head].Part);head+=1;n+=1 end
    for i=#extra,1,-1 do
     if n>=budget then break end
     if extra[i].At<=t then darken(extra[i].Part);table.remove(extra,i);n+=1 end
    end
    while #recolour>0 and n<budget do
     local part=table.remove(recolour)
     local h=held[part]
     if h and part.Parent then h.Update('Color',goal(part,h.Base('Color')or part.Color))end
     n+=1
    end
    if not wave[head]and #extra==0 and #recolour==0 then break end
    task.wait()
   end
   pumping=false
  end)
 end
 local function wanted(part:BasePart):boolean
  return filter==nil or filter(part)==true
 end
 for part in pairs(district.Neon)do
  if wanted(part::BasePart)then table.insert(wave,{Part=part,At=delay(part::BasePart)})end
 end
 table.sort(wave,function(a,b)return a.At<b.At end)
 local function listen(kind:string,o:Instance)
  if kind~='Neon'or released then return end
  local part=o::BasePart
  if not wanted(part)then return end
  table.insert(extra,{Part=part,At=delay(part)})
  pump()
 end
 listeners[listen]=true
 pump()
 function handle:Set(newColor:any)
  if released then return end
  paint=newColor
  local camera=workspace.CurrentCamera
  local eye=camera and camera.CFrame.Position or K.Me()
  table.clear(recolour)
  for part in pairs(held)do table.insert(recolour,part)end
  -- Popped from the end: farthest first in the list, so the nearest change first.
  table.sort(recolour,function(a,b)return (a.Position-eye).Magnitude>(b.Position-eye).Magnitude end)
  pump()
 end
 function handle:Release(rewave:any)
  if released then return end
  released=true
  listeners[listen]=nil
  local back=type(rewave)=='number'and rewave or rewave==true and speed or 0
  local list={}
  for part,h in pairs(held)do
   table.insert(list,{Release=h.Release,At=(from and back>0)and (part.Position-from).Magnitude/back or 0})
  end
  table.clear(held)
  table.sort(list,function(a,b)return a.At<b.At end)
  -- Its own thread: it finishes even when the scope has ended.
  task.spawn(function()
   local began=os.clock()
   local i=1
   while list[i]do
    local t=os.clock()-began
    local n=0
    while list[i]and list[i].At<=t and n<budget do list[i].Release();i+=1;n+=1 end
    if list[i]then task.wait()end
   end
  end)
 end
 self:Add(function()handle:Release()end)
 return handle
end
--[[ scope:Glance(target, options?) → handle: every dog on the island (the tongue, the
 kennels, yard showcases, the museum's) turns to look at target, a Vector3 or a function
 returning one (a colossus in the sky...). options as Stare.Begin (Exclude, Turn, Ripple).
 handle:Bow(radians, seconds), handle:Stop(seconds). Ends with the scope. ]]
function Scope:Glance(target:any,options:{[string]:any}?)
 local fn=typeof(target)=='Vector3'and function()return target end or target
 local stare=Stare.Begin(fn,options)
 local stopped=false
 local handle={}
 function handle:Bow(r:number,s:number)stare:Bow(r,s)end
 function handle:Stop(seconds:number?)
  if stopped then return end
  stopped=true;stare:Stop(seconds or 1)
 end
 self:Add(function()handle:Stop(1)end)
 return handle
end
return K
