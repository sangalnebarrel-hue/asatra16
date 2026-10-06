-- The map-wide layer of a Secret arrival: wherever a player stands on the island, the sky
-- turns, something colossal hangs over the map, their camera is pulled to the arrival for
-- its big moment, the district's lights answer, things fall around them and every dog
-- looks. Adds to Kit: K.Map, K.Me, K.Frame, K.Orbit and the scope methods Sky, Colossus,
-- Cutaway, Banner, Rain, TintLights, Glance. All local to this client, undone on Clean.
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
K.Map={
 Center=MAP.Center or Vector3.new(0,1,0),         -- the yards and the tongue, at floor height
 Radius=MAP.Radius or 190,                        -- from Center to the yards' outer fences
 Sky=MAP.Sky or 170,                              -- altitude above Center for colossal things
 Mouth=MAP.Mouth or Vector3.new(0,2,-150),        -- the tongue's stage
 Head=MAP.Head or Vector3.new(0,60,-195),         -- the giant head building
 Backdrop=MAP.Backdrop or Vector3.new(0,1,-420),  -- behind the giant head, where colossi loom
 Min=MAP.Min or Vector3.new(-200,0,-260),         -- the whole district
 Max=MAP.Max or Vector3.new(200,0,720),
 Landmarks=MAP.Landmarks or {},
}
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

---------------------------------------------------------------- sky
-- Objects the sky borrows when the place has none (a neutral Atmosphere, Clouds...).
local made={}
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
  if mine.Users<=0 then
   if made[className]==mine then made[className]=nil end
   mine.Instance:Destroy()
  end
 end
end
-- World events (ReplicatedStorage.WorldEvents) drive Lighting, the Atmosphere, Clouds and the
-- Sky while one runs, and snapshot them when one starts. So the sky only touches those when
-- no event can begin or end before it has let go of them; otherwise it turns the camera
-- grade alone (which nothing else writes).
local eventLighting:any=nil
local function worldFree(seconds:number):boolean
 local events=RS:FindFirstChild('WorldEvents')
 if not events then return true end
 if eventLighting==nil then
  local module=events:FindFirstChild('WorldEventLighting')
  local ok,result=pcall(function()return module and require(module::ModuleScript)end)
  eventLighting=ok and type(result)=='table'and result or false
 end
 if eventLighting and eventLighting.Active then return false end
 local state=events:FindFirstChild('State')
 if not state then return true end
 local kind,ends=state:GetAttribute('State'),state:GetAttribute('EndTimestamp')
 if type(ends)~='number'then return kind==nil end
 local left=ends-workspace:GetServerTimeNow()
 -- NORMAL ends in a 60 s warning before the event itself lights up.
 if kind=='NORMAL'then return left+60>seconds+3 end
 if kind=='WARNING'then return left>seconds+3 end
 return false
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
--[[ scope:Sky(theme, fadeIn?, fadeOut?) → handle
 Turns the whole sky and the island's light for this client. Every field is optional:
  Lighting   = {ClockTime, Brightness, ExposureCompensation, Ambient, OutdoorAmbient,
                FogColor, FogStart, FogEnd, EnvironmentDiffuseScale, EnvironmentSpecularScale,
                ColorShift_Top, ColorShift_Bottom}
  Atmosphere = {Density, Offset, Color, Decay, Glare, Haze}
  Clouds     = {Cover, Density, Color}
  Sky        = {StarCount, CelestialBodiesShown, SunAngularSize, MoonAngularSize}
  Grade      = {TintColor, Saturation, Contrast, Brightness}   (a camera ColorCorrection)
  Bloom      = {Intensity, Size, Threshold}                    (a camera Bloom)
 Eases in over fadeIn (default 1.2 s) and back over fadeOut (default 1.5 s) once the scope
 ends; held meanwhile against the server's day cycle (what it writes is what comes back).
 While a world event runs or could start or end before the arrival is over, only Grade and
 Bloom apply (Lighting/Atmosphere become an approximate grade). handle:Set(patch, seconds)
 eases to new values (same shape as theme); handle:Release(seconds) lets go early. ]]
function Scope:Sky(theme:{[string]:any},fadeIn:number?,fadeOut:number?)
 local tracks={}
 local gives={}
 local function hold(o:Instance,props:{[string]:any}?)
  for k,v in pairs(props or {})do
   local existing
   for _,t in ipairs(tracks)do if t.O==o and t.K==k then existing=t end end
   if existing then existing.To=v
   else
    local ok,now=pcall(function()return (o::any)[k]end)
    if ok and now~=nil then
     local release,update,base=K.Layer(o,{[k]=now},true)
     table.insert(tracks,{O=o,K=k,From=now,To=v,Value=now,Update=update,Release=release,Base=base})
    end
   end
  end
 end
 local camera=workspace.CurrentCamera
 local grade,bloom
 -- Decided once: free of world events until this arrival ends (scope.EndsAt) and fades out.
 local ends=self.EndsAt
 local free=worldFree((type(ends)=='number'and math.max(ends-workspace:GetServerTimeNow(),0)or 20)+(fadeOut or 1.5))
 local function apply(given:{[string]:any})
  local patch=given
  if not free and(given.Lighting or given.Atmosphere or given.Clouds or given.Sky)then
   patch={Grade=given.Grade,Bloom=given.Bloom}
   local extra=fallbackGrade(given)
   if extra then
    local merged=table.clone(patch.Grade or {})
    for k,v in pairs(extra)do
     if k=='Brightness'then merged.Brightness=(merged.Brightness or 0)+v
     elseif merged[k]==nil then merged[k]=v end
    end
    patch.Grade=merged
   end
  end
  if patch.Lighting then hold(Lighting,patch.Lighting)end
  if patch.Atmosphere then
   local o,give=borrow('Atmosphere',Lighting,{Density=0,Offset=0,Glare=0,Haze=0})
   table.insert(gives,give);hold(o,patch.Atmosphere)
  end
  if patch.Clouds then
   local o,give=borrow('Clouds',workspace.Terrain,{Cover=0,Density=0})
   table.insert(gives,give);hold(o,patch.Clouds)
  end
  if patch.Sky then
   local o,give=borrow('Sky',Lighting,{})
   table.insert(gives,give);hold(o,patch.Sky)
  end
  if patch.Grade and camera then
   if not grade then
    grade=Instance.new('ColorCorrectionEffect');grade.Name='DOGROTS_SecretSkyGrade';grade.Parent=camera
    table.insert(gives,function()grade:Destroy()end)
   end
   hold(grade,patch.Grade)
  end
  if patch.Bloom and camera then
   if not bloom then
    bloom=Instance.new('BloomEffect');bloom.Name='DOGROTS_SecretSkyBloom';bloom.Intensity=0;bloom.Size=24;bloom.Threshold=2
    bloom.Parent=camera
    table.insert(gives,function()bloom:Destroy()end)
   end
   hold(bloom,patch.Bloom)
  end
 end
 local handle={}
 local connection:RBXScriptConnection?=nil
 local released=false
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
 function handle:Set(patch:{[string]:any},seconds:number?)
  if released then return end
  apply(patch);run(seconds or 1,false)
 end
 function handle:Release(seconds:number?)
  if released then return end
  released=true
  run(seconds or fadeOut or 1.5,true,function()
   for _,t in ipairs(tracks)do t.Release()end
   for _,give in ipairs(gives)do give()end
  end)
 end
 apply(theme)
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
 handle: Model, Animator, Center() → Vector3, Pose(cframe, seconds?), Play(clip, looped?, speed?),
  Fade(alpha, seconds?), Stop(seconds?) (fades out and removes it; Clean does too). ]]
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
 -- Movement and fading run on one step.
 local moveFrom,moveTo,moveStart,moveSeconds=current,current,0,0
 local fadeFrom,fadeTo,fadeStart,fadeSeconds=1,alpha,os.clock(),options.FadeIn or 1.2
 local riseLeft=rise
 local value=1
 local function applyAlpha(a:number)
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
  if not fixed then current=skyFrame(dt)
  elseif moveSeconds>0 then
   local m=smooth((now-moveStart)/moveSeconds)
   current=moveFrom:Lerp(moveTo,m)
  end
  local lift=riseLeft*(1-f)
  place(current-Vector3.new(0,lift,0))
  if f>=1 then riseLeft=0 end
  if animator and animator.Clip then pcall(function()animator:Step()end)end
  if stopping and f>=1 then connection:Disconnect();model:Destroy()end
 end)
 function handle:Center():Vector3 return current.Position end
 -- Pins it to a world CFrame (gliding there over `seconds`), leaving the sky placement.
 function handle:Pose(cf:CFrame,seconds:number?)
  fixed=true
  moveFrom,moveTo,moveStart,moveSeconds=current,cf,os.clock(),seconds or 0
  if (seconds or 0)<=0 then current=cf;moveSeconds=0 end
 end
 function handle:Play(clip:string,looped:boolean?,speed:number?)
  -- A one-shot clip asked to loop repeats with a short recovery (DogAnimationPlayer).
  if animator then pcall(function()animator:Play(clip,{FadeTime=.25,Looped=looped==true,Speed=speed})end)end
 end
 function handle:Fade(a:number,seconds:number?)
  fadeFrom,fadeTo,fadeStart,fadeSeconds=value,a,os.clock(),seconds or .6
 end
 function handle:Stop(seconds:number?)
  if not live then return end
  live=false;stopping=true
  self:Fade(1,seconds or 1.2)
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
--[[ scope:Cutaway(ctx, shots, options) → handle | nil
 For the arrival's big moment every player's camera leaves them and comes back. shots are
 camera keyframes on the arrival clock: {At=seconds, CFrame=camera, Fov=degrees?, Cut=true
 (jump to it instead of gliding), Linear=true (no easing into it)}. Build CFrames with
 K.Frame(position, lookAt) or K.Orbit(centre, radius, height, angle). The camera glides
 between them and is handed back (with a short dip to black) after the last one; the
 character stands still meanwhile.
 options: Focus (Vector3 to stream in first; default ctx.Origin), Bars (letterbox fraction,
  default .09), Shake (handheld wobble 0..1, default .12).
 Nobody is pulled away when ReducedMotion is on, SecretArrivalConfig.Cutaway is false, the
 camera is busy (see busy above) or the client arrives too late; it gives up the moment the
 player dies, opens a menu or another script takes the camera. Returns nil when skipped up
 front, else a handle (Active, Shake(power, seconds), Stop()). ]]
function Scope:Cutaway(ctx:any,shots:{{[string]:any}},given:{[string]:any}?)
 local options:{[string]:any}=given or {}
 if #shots==0 or Config.Cutaway==false or K.ReducedMotion()then return nil end
 local list=table.clone(shots)
 table.sort(list,function(a,b)return a.At<b.At end)
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
 local shakeUntil,shakePower=0,0
 local base=options.Shake or .12
 local function sample(t:number):(CFrame,number)
  local fov0=saved and saved.Fov or 70
  if t<=first.At or #list==1 then return first.CFrame,first.Fov or fov0 end
  for i=1,#list-1 do
   local a,b=list[i],list[i+1]
   if t<b.At then
    if b.Cut then return a.CFrame,a.Fov or fov0 end
    local u=(t-a.At)/math.max(b.At-a.At,1e-3)
    if not b.Linear then u=smooth(u)end
    return a.CFrame:Lerp(b.CFrame,u),(a.Fov or fov0)+((b.Fov or fov0)-(a.Fov or fov0))*u
   end
  end
  return last.CFrame,last.Fov or fov0
 end
 local function finish(restore:boolean)
  if not handle.Active then return end
  handle.Active=false
  Run:UnbindFromRenderStep(name)
  CAS:UnbindAction(name)
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
--[[ scope:TintLights(color, seconds?) → release: every light in the district turns
 `color` for this client (black is a blackout); only Color, so WorldEventLighting and
 WorldDetailQuality keep owning Enabled and Brightness. Comes back on Clean. ]]
function Scope:TintLights(color:Color3,seconds:number?)
 local district=workspace:FindFirstChild('DOGROTS_District')
 if not district then return function()end end
 local tracks={}
 for _,o in ipairs(district:GetDescendants())do
  if o:IsA('Light')then
   local release,update=K.Layer(o,{Color=o.Color})
   table.insert(tracks,{From=o.Color,Update=update,Release=release})
  end
 end
 local started,span=os.clock(),seconds or .6
 self:Every(function()
  local a=span>0 and smooth((os.clock()-started)/span)or 1
  for _,t in ipairs(tracks)do t.Update('Color',t.From:Lerp(color,a))end
  return a<1
 end)
 local released=false
 local function release()
  if released then return end
  released=true
  for _,t in ipairs(tracks)do t.Release()end
 end
 self:Add(release)
 return release
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
