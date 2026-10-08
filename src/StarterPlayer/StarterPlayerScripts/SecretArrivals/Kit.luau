-- Building blocks for the Secret arrival cinematics. Everything an arrival makes lives
-- in a Scope and is undone by Scope:Clean(): parts, sounds, post effects, music ducks,
-- local dog visibility/offsets. Effects are local to this client and never replicate.
local Players=game:GetService('Players')
local RS=game:GetService('ReplicatedStorage')
local Run=game:GetService('RunService')
local Tween=game:GetService('TweenService')
local SoundService=game:GetService('SoundService')
local UIS=game:GetService('UserInputService')
local Config=require(RS:WaitForChild('SecretArrivalConfig'))
local player=Players.LocalPlayer
local K={}
local rng=Random.new()

-- WorldDetailQuality throttles lights/particles under the district; FX live outside it.
local function fxRoot()
 local root=workspace:FindFirstChild('DOGROTS_SecretArrivalFX')
 if not root then root=Instance.new('Folder');root.Name='DOGROTS_SecretArrivalFX';root.Parent=workspace end
 return root
end
function K.Low()
 local fx=player:GetAttribute('WorldEventFX')
 return fx=='Low'or player:GetAttribute('LowFX')==true or player:GetAttribute('ReducedMotion')==true
  or (fx==nil and UIS.TouchEnabled)
end
function K.ReducedMotion()return player:GetAttribute('ReducedMotion')==true end
function K.Tween(o,seconds,props,style,direction)
 local t=Tween:Create(o,TweenInfo.new(seconds,style or Enum.EasingStyle.Quad,direction or Enum.EasingDirection.Out),props)
 t:Play();return t
end
function K.Random(a,b)return rng:NextNumber(a,b)end
-- CFrame at `from` looking at `to`, safe when the direction is vertical.
function K.LookAt(from,to)
 local d=to-from
 if d.Magnitude<1e-4 then return CFrame.new(from)end
 return CFrame.lookAt(from,to,math.abs(d.Unit.Y)>.99 and Vector3.zAxis or Vector3.yAxis)
end

---------------------------------------------------------------- scope
local Scope={};Scope.__index=Scope
function K.Scope(name)
 local folder=Instance.new('Folder');folder.Name=name;folder.Parent=fxRoot()
 return setmetatable({Folder=folder,Alive=true,Cleanups={},Steps={}},Scope)
end
-- Add(instance | RBXScriptConnection | function): undone/destroyed on Clean, newest first.
function Scope:Add(x)
 table.insert(self.Cleanups,x);return x
end
function Scope:Clean()
 if not self.Alive then return end
 self.Alive=false
 for i=#self.Cleanups,1,-1 do
  local x=self.Cleanups[i]
  local ok,err=pcall(function()
   if typeof(x)=='Instance'then x:Destroy()
   elseif typeof(x)=='RBXScriptConnection'then x:Disconnect()
   elseif type(x)=='function'then x()end
  end)
  if not ok then warn('SecretArrivals cleanup:',err)end
 end
 table.clear(self.Cleanups)
 self.Folder:Destroy()
end
-- Every(fn): fn(dt, age) each rendered frame until it returns false or the scope ends.
function Scope:Every(fn)
 local started=os.clock();local connection
 connection=Run.RenderStepped:Connect(function(dt)
  if not self.Alive then connection:Disconnect();return end
  local ok,keep=pcall(fn,dt,os.clock()-started)
  if not ok then warn('SecretArrivals step:',keep);connection:Disconnect()
  elseif keep==false then connection:Disconnect()end
 end)
 return self:Add(connection)
end
-- Life(instance, seconds, step?): destroy after `seconds`; step(alpha 0..1) each frame.
function Scope:Life(o,seconds,step)
 self:Every(function(_,age)
  local a=math.min(age/seconds,1)
  if step then step(a)end
  if a>=1 then if o.Parent then o:Destroy()end;return false end
  return true
 end)
 return o
end

---------------------------------------------------------------- world parts
function Scope:Part(props)
 local p=Instance.new('Part')
 p.Anchored=true;p.CanCollide=false;p.CanTouch=false;p.CanQuery=false;p.CastShadow=false
 p.Material=Enum.Material.Neon;p.TopSurface=Enum.SurfaceType.Smooth;p.BottomSurface=Enum.SurfaceType.Smooth
 for k,v in pairs(props)do (p::any)[k]=v end
 p.Parent=props.Parent or self.Folder
 return p
end
function Scope:Light(parent,color,range,brightness)
 local l=Instance.new('PointLight');l.Color=color;l.Range=range or 16;l.Brightness=brightness or 2;l.Shadows=false;l.Parent=parent
 return l
end
local SPARK='rbxasset://textures/particles/sparkles_main.dds'
local SMOKE='rbxasset://textures/particles/smoke_main.dds'
local FIRE='rbxasset://textures/particles/fire_main.dds'
K.Textures={Spark=SPARK,Smoke=SMOKE,Fire=FIRE}
function Scope:Emitter(parent,props)
 local e=Instance.new('ParticleEmitter')
 e.Texture=SPARK;e.Rate=0;e.LightEmission=1;e.LightInfluence=0;e.Lifetime=NumberRange.new(.6,1.4)
 e.Speed=NumberRange.new(4,12);e.SpreadAngle=Vector2.new(180,180);e.Size=NumberSequence.new(.6,0)
 e.Transparency=NumberSequence.new(0,1)
 for k,v in pairs(props or {})do (e::any)[k]=v end
 e.Parent=parent
 return e
end
-- An invisible anchor part at `position` for emitters, lights and sounds.
function Scope:Anchor(position,name)
 return self:Part({Name=name or 'Anchor',Size=Vector3.one*.2,Position=position,Transparency=1})
end
function Scope:Burst(position,color,count,props)
 local a=self:Anchor(position,'Burst')
 local e=self:Emitter(a,props or {})
 e.Color=ColorSequence.new(color)
 e:Emit(K.Low()and math.ceil(count*.25)or count)
 task.delay(4,function()if a.Parent then a:Destroy()end end)
 return e
end
-- A shockwave: a flat ring of neon segments that grows from r0 to r1 and fades.
function Scope:Ring(center,color,r0,r1,seconds,props)
 props=props or {}
 local count=K.Low()and 16 or (props.Segments or 32)
 local axisU=props.U or Vector3.xAxis
 local axisW=props.W or Vector3.zAxis
 local thick=props.Thickness or .4
 local m=Instance.new('Model');m.Name='Ring';m.Parent=self.Folder
 local parts={}
 for i=1,count do
  parts[i]=self:Part({Name='Segment',Color=color,Size=Vector3.new(thick,thick,1),Transparency=props.Alpha or .1,Parent=m})
 end
 self:Life(m,seconds,function(a)
  local eased=1-(1-a)^3
  local r=r0+(r1-r0)*eased
  local width=2*math.pi*r/count*1.08
  for i,p in ipairs(parts)do
   local t0,t1=(i-1)/count*math.pi*2,i/count*math.pi*2
   local a0=center+axisU*math.cos(t0)*r+axisW*math.sin(t0)*r
   local a1=center+axisU*math.cos(t1)*r+axisW*math.sin(t1)*r
   p.Size=Vector3.new(thick,thick,width)
   p.CFrame=K.LookAt((a0+a1)/2,a1)
   p.Transparency=(props.Alpha or .1)+(1-(props.Alpha or .1))*a
  end
 end)
 return m
end
-- A pillar of light from `from` to `to`, swelling in then out over `seconds`.
function Scope:Pillar(from,to,color,width,seconds)
 local p=self:Part({Name='Pillar',Color=color,Transparency=.35})
 p.Shape=Enum.PartType.Cylinder
 local length=(to-from).Magnitude
 local base=K.LookAt((from+to)/2,to)*CFrame.Angles(0,math.pi/2,0)
 self:Life(p,seconds,function(a)
  local s=math.min(a*6,1)*math.min((1-a)*3,1)
  p.Size=Vector3.new(length,width*s+.01,width*s+.01);p.CFrame=base
  p.Transparency=1-s*.7
 end)
 return p
end
-- A jittered electric line from a to b that fades in `seconds`.
function Scope:Bolt(a,b,color,width,seconds)
 local m=Instance.new('Model');m.Name='Bolt';m.Parent=self.Folder
 local prev=a;local steps=8
 for i=1,steps do
  local at=a:Lerp(b,i/steps)
  if i<steps then at+=Vector3.new(K.Random(-1,1),K.Random(-1,1),K.Random(-1,1))*(a-b).Magnitude*.06 end
  self:Part({Name='Arc',Color=color,Size=Vector3.new(width,width,(at-prev).Magnitude),CFrame=K.LookAt((at+prev)/2,at),Parent=m})
  prev=at
 end
 self:Life(m,seconds,function(alpha)for _,p in ipairs(m:GetChildren())do (p::BasePart).Transparency=alpha end end)
 return m
end

--[[ Scope:Override(instance, props): set properties on an existing world object (mouth
 runes, the giant head's pupils, a SurfaceAppearance's EmissiveStrength...) for this
 client only; the original values come back on Clean. Overrides are layered per object:
 when one of two overlapping arrivals ends, each property falls back to the newest
 remaining layer that sets it, else to the true original. Returns the instance (nil if
 it is missing) and release(), which drops this layer early the same way. ]]
local layers=setmetatable({},{__mode='k'})
local function set(o,k,v)pcall(function()(o::any)[k]=v end)end
function Scope:Override(o,props)
 if not o then return nil,function()end end
 local entry=layers[o]
 if not entry then entry={Original={},Stack={}};layers[o]=entry end
 for k in pairs(props)do
  if entry.Original[k]==nil then
   local ok,old=pcall(function()return (o::any)[k]end)
   if ok then entry.Original[k]=old end
  end
 end
 local layer={Props=props}
 table.insert(entry.Stack,layer)
 for k,v in pairs(props)do set(o,k,v)end
 local released=false
 local function release()
  if released then return end
  released=true
  local i=table.find(entry.Stack,layer)
  if i then table.remove(entry.Stack,i)end
  if o.Parent then
   for k in pairs(props)do
    local value=entry.Original[k]
    for j=#entry.Stack,1,-1 do
     local v=entry.Stack[j].Props[k]
     if v~=nil then value=v;break end
    end
    set(o,k,value)
   end
  end
  if #entry.Stack==0 and layers[o]==entry then layers[o]=nil end
 end
 self:Add(release)
 return o,release
end
-- Beam between two points. a/b: Attachment or Bone (follows it) or Vector3 (fixed).
function Scope:Beam(a,b,color,width,props)
 local function attach(x)
  if typeof(x)=='Vector3'then
   local anchor=self:Anchor(x,'BeamEnd')
   local at=Instance.new('Attachment');at.Parent=anchor;return at
  end
  return x
 end
 local beam=Instance.new('Beam')
 beam.Attachment0=attach(a);beam.Attachment1=attach(b)
 beam.Color=ColorSequence.new(color);beam.Width0=width;beam.Width1=width
 beam.LightEmission=1;beam.LightInfluence=0;beam.FaceCamera=true;beam.Segments=props and props.Segments or 10
 beam.Transparency=NumberSequence.new(.05)
 for k,v in pairs(props or {})do if k~='Segments'then (beam::any)[k]=v end end
 beam.Parent=self.Folder
 return beam
end
-- 0..1: how close this client's camera is to `position` (1 at it, 0 beyond `radius`).
-- Scale shakes, flashes and FOV punches by it so the far side of the island is calm.
function K.Near(position,radius)
 local c=workspace.CurrentCamera
 if not c then return 0 end
 return math.clamp(1-(c.CFrame.Position-position).Magnitude/radius,0,1)
end

---------------------------------------------------------------- camera & screen
local shakeUntil,shakePower=0,0
local shakeBound=false
function K.Shake(power,seconds)
 if K.ReducedMotion()then return end
 shakeUntil=math.max(shakeUntil,os.clock()+seconds);shakePower=math.max(shakePower,power)
 if shakeBound then return end
 shakeBound=true
 Run:BindToRenderStep('DOGROTS_SecretArrivalCamera',Enum.RenderPriority.Camera.Value+4,function()
  local now=os.clock()
  if now>shakeUntil then shakePower=0;return end
  local c=workspace.CurrentCamera;if not c or c.CameraType==Enum.CameraType.Scriptable then return end
  local g=math.min(shakeUntil-now,1)*shakePower
  c.CFrame*=CFrame.new(math.noise(now*20)*g,math.noise(0,now*23)*g,0)*CFrame.Angles(0,0,math.noise(now*14,1)*g*.03)
 end)
end
-- A camera ColorCorrection only this client sees (the server rewrites Lighting).
function Scope:Grade(props,fadeIn,fadeOut)
 local camera=workspace.CurrentCamera
 local cc=Instance.new('ColorCorrectionEffect');cc.Name='DOGROTS_SecretGrade';cc.Parent=camera
 K.Tween(cc,fadeIn or .6,props)
 self:Add(function()
  local t=K.Tween(cc,fadeOut or .8,{Brightness=0,Contrast=0,Saturation=0,TintColor=Color3.new(1,1,1)})
  t.Completed:Connect(function()cc:Destroy()end)
 end)
 return cc
end
function Scope:Blur(size,fadeIn,fadeOut)
 local b=Instance.new('BlurEffect');b.Name='DOGROTS_SecretBlur';b.Size=0;b.Parent=workspace.CurrentCamera
 K.Tween(b,fadeIn or .4,{Size=size})
 self:Add(function()local t=K.Tween(b,fadeOut or .6,{Size=0});t.Completed:Connect(function()b:Destroy()end)end)
 return b
end
local overlay
local function screen()
 if overlay and overlay.Parent then return overlay end
 overlay=Instance.new('ScreenGui');overlay.Name='DOGROTS_SecretScreen';overlay.ResetOnSpawn=false
 overlay.IgnoreGuiInset=true;overlay.DisplayOrder=94;overlay.Parent=player:WaitForChild('PlayerGui')
 return overlay
end
function K.Flash(color,alpha,seconds)
 if K.ReducedMotion()then alpha=math.max(alpha,.6)end
 local f=Instance.new('Frame');f.Name='Flash';f.BorderSizePixel=0;f.Size=UDim2.fromScale(1,1)
 f.BackgroundColor3=color;f.BackgroundTransparency=alpha;f.Parent=screen()
 K.Tween(f,seconds,{BackgroundTransparency=1}).Completed:Connect(function()f:Destroy()end)
end
-- Cinema bars; the top one sits under the whisper. Removed with the scope.
function Scope:Letterbox(fraction,seconds)
 local bars={}
 for i,anchor in ipairs({0,1})do
  local b=Instance.new('Frame');b.Name='Letterbox';b.BorderSizePixel=0;b.BackgroundColor3=Color3.new(0,0,0)
  b.AnchorPoint=Vector2.new(0,anchor);b.Position=UDim2.fromScale(0,anchor);b.Size=UDim2.fromScale(1,0);b.Parent=screen()
  -- The bottom bar stays thin: Money/XP live there.
  K.Tween(b,seconds or .8,{Size=UDim2.fromScale(1,i==1 and fraction or fraction*.45)})
  bars[i]=b
 end
 self:Add(function()for _,b in ipairs(bars)do K.Tween(b,.7,{Size=UDim2.fromScale(1,0)}).Completed:Connect(function()b:Destroy()end)end end)
end
-- A quick zoom in and back. A scripted camera (DOG-O-MATIC, lab, events) or another punch
-- owns the FOV: never start over one, and let go (without restoring) the moment anything
-- else writes the FOV. While it runs, the camera's SecretZoom attribute holds the true
-- FOV, which the other FOV owners save instead of the punched one.
function K.FOVPunch(delta,inSeconds,outSeconds)
 if K.ReducedMotion()then return end
 local c=workspace.CurrentCamera
 if not c or c:GetAttribute('SecretZoom')or c:GetAttribute('DiscoveryZoom')or c.CameraType==Enum.CameraType.Scriptable then return end
 local base=c.FieldOfView
 c:SetAttribute('SecretZoom',base)
 local peak=math.clamp(base+delta,20,110)
 local written=base
 local started=os.clock()
 local connection
 connection=Run.RenderStepped:Connect(function()
  local age=os.clock()-started
  if math.abs(c.FieldOfView-written)>.01 or c.CameraType==Enum.CameraType.Scriptable then
   connection:Disconnect();c:SetAttribute('SecretZoom',nil);return
  end
  local a
  if age<inSeconds then a=1-(1-age/inSeconds)^2
  else a=1-math.min((age-inSeconds)/outSeconds,1);a=a*a*(3-2*a)end
  written=base+(peak-base)*a
  c.FieldOfView=written
  if age>=inSeconds+outSeconds then
   c.FieldOfView=base;connection:Disconnect();c:SetAttribute('SecretZoom',nil)
  end
 end)
end

---------------------------------------------------------------- sound
local Audio=require(RS:WaitForChild('AudioSource'))
local Assets=require(RS:WaitForChild('WorldEvents'):WaitForChild('AudioAssetIds'))
local TICK='rbxasset://sounds/volume_slider.ogg'
local function uri(id,fallback)
 if type(id)=='number'and id>0 then return 'rbxassetid://'..string.format('%.0f',id)end
 return fallback
end
local function musicUri(key,localFile)
 local asset=Assets[key];if not asset then return nil end
 return Audio.Resolve(asset.Id,asset.LocalFile or localFile,true)
end
local function sound(parent,id,volume,speed,looped)
 local s=Instance.new('Sound');s.SoundId=id;s.Volume=volume;s.PlaybackSpeed=speed or 1;s.Looped=looped==true
 s.RollOffMinDistance=10;s.RollOffMaxDistance=220;s.Parent=parent or SoundService
 return s
end
local function effect(s,class,props)
 local e=Instance.new(class)
 for k,v in pairs(props)do (e::any)[k]=v end
 e.Parent=s;return e
end
-- One-shot: plays, then cleans itself. parent=nil → 2D.
local function shot(parent,id,volume,speed,effects)
 local s=sound(parent,id,volume,speed)
 for class,props in pairs(effects or {})do effect(s,class,props)end
 s:Play()
 task.delay(8,function()if s.Parent then s:Destroy()end end)
 return s
end
--[[ K.Cue(kind, parent?): Heartbeat, Impact, Glitch, Chime, Whoosh, Sting.
 Uses an uploaded asset from SecretArrivalConfig.Sounds when set, otherwise a
 pitched and filtered built-in tick that ships with every Roblox client. ]]
function K.Cue(kind,parent,volume)
 local custom=Config.Sounds[kind]
 if type(custom)=='number'and custom>0 then return shot(parent,uri(custom,TICK),volume or .6,1)end
 if kind=='Heartbeat'then
  local eq={EqualizerSoundEffect={LowGain=10,MidGain=-8,HighGain=-40}}
  shot(parent,TICK,volume or .9,.22,eq)
  task.delay(.19,function()shot(parent,TICK,(volume or .9)*.8,.2,eq)end)
 elseif kind=='Impact'then
  shot(parent,TICK,volume or 1,.12,{EqualizerSoundEffect={LowGain=10,MidGain=0,HighGain=-30},
   DistortionSoundEffect={Level=.55},ReverbSoundEffect={DecayTime=2.4,WetLevel=-2,DryLevel=0,Density=1,Diffusion=1}})
 elseif kind=='Glitch'then
  for i=0,7 do
   task.delay(i*.045+K.Random(0,.02),function()
    shot(parent,TICK,(volume or .5)*K.Random(.5,1),K.Random(1.6,4.2),{DistortionSoundEffect={Level=.8}})
   end)
  end
 elseif kind=='Chime'then
  for i,step in ipairs({1,1.25,1.5,2})do
   task.delay((i-1)*.12,function()shot(parent,TICK,volume or .55,step*1.5,{ReverbSoundEffect={DecayTime=1.8,WetLevel=-4}})end)
  end
 elseif kind=='Whoosh'then
  shot(parent,TICK,volume or .5,.45,{EqualizerSoundEffect={LowGain=-6,MidGain=4,HighGain=2},
   FlangeSoundEffect={Depth=.6,Mix=.85,Rate=6},ReverbSoundEffect={DecayTime=1.4,WetLevel=-6}})
 elseif kind=='Sting'then
  shot(parent,TICK,volume or .8,.16,{ReverbSoundEffect={DecayTime=6,WetLevel=0,DryLevel=-6,Density=1,Diffusion=1},
   EqualizerSoundEffect={LowGain=8,MidGain=-2,HighGain=-18}})
 end
end
--[[ Scope:Drone(key, volume, speed, fade): a slowed, reverberant music bed (the place's own
 NULL_HOUR / THE_VOID_OPENS tracks) or SecretArrivalConfig.Sounds.Drone/Choir if uploaded.
 Fades out with the scope. ]]
function Scope:Drone(kind,volume,speed,fade)
 local custom=Config.Sounds[kind]
 local id=(type(custom)=='number'and custom>0)and uri(custom,nil)
  or (kind=='Choir'and musicUri('THE_VOID_OPENS/music','sounds/dogrots-portable/THE_VOID_OPENS.wav')
   or musicUri('NULL_HOUR/music','sounds/dogrots-portable/NULL_HOUR.wav'))
 if not id then return nil end
 local s=sound(SoundService,id,0,speed or .55,true)
 effect(s,'ReverbSoundEffect',{DecayTime=8,Density=1,Diffusion=1,WetLevel=0,DryLevel=-4})
 effect(s,'EqualizerSoundEffect',{LowGain=4,MidGain=-4,HighGain=-14})
 s:Play()
 K.Tween(s,fade or 1.5,{Volume=volume or .5})
 self:Add(function()K.Tween(s,1.2,{Volume=0}).Completed:Connect(function()s:Destroy()end)end)
 return s
end
--[[ Scope:Duck(level, fade): lower the game's music to `level` (fraction) and bring it back
 on Clean. Several scopes may duck at once; the quietest wins. Only SoundGroup volumes
 move (from a fixed baseline), so the music scripts' own Sound.Volume fades keep working. ]]
local ducks={};local baseline=setmetatable({},{__mode='k'})
local function musicGroups()
 local list={}
 local root=SoundService:FindFirstChild('DOGROTS_AUDIO')
 if root then for _,g in ipairs(root:GetChildren())do if g:IsA('SoundGroup')then table.insert(list,g)end end end
 -- WorldAmbience's background music has no group of its own: give it a neutral one.
 local own=SoundService:FindFirstChild('DOGROTS_SecretDuckBed')
 local bed=SoundService:FindFirstChild('DOGROTS_BackgroundMusic')
 if bed and bed:IsA('Sound')and not bed.SoundGroup then
  if not own then own=Instance.new('SoundGroup');own.Name='DOGROTS_SecretDuckBed';own.Volume=1;own.Parent=SoundService end
  bed.SoundGroup=own
 end
 if own and own:IsA('SoundGroup')then table.insert(list,own)end
 return list
end
local function applyDuck(seconds)
 local level=1;for _,l in pairs(ducks)do level=math.min(level,l)end
 for _,g in ipairs(musicGroups())do
  baseline[g]=baseline[g]or g.Volume
  K.Tween(g,seconds,{Volume=baseline[g]*level})
 end
end
function Scope:Duck(level,fade)
 ducks[self]=level;applyDuck(fade or 1)
 self:Add(function()ducks[self]=nil;applyDuck(1.5)end)
end

---------------------------------------------------------------- the dog itself
function K.Root(model)
 return model.PrimaryPart or model:FindFirstChild('RootPart',true)
end
function K.Pivot(model,fallback)
 local root=K.Root(model)
 if root and root:IsA('BasePart')then return model:GetPivot()end
 return CFrame.new(fallback or model:GetPivot().Position)
end
-- Ground point of a prepared dog (between its feet), from Rig.Prepare's GroundLocal.
function K.Ground(model,fallback)
 local root=K.Root(model)
 if not root then return fallback or model:GetPivot().Position end
 return model:GetPivot():PointToWorldSpace(model:GetAttribute('GroundLocal')or Vector3.zero)
end
function K.Size(model)return model:GetAttribute('VisualSize')or Vector3.new(6,6,6)end
-- Hide/fade the dog for this client only: LocalTransparencyModifier on every part.
function Scope:Visibility(model)
 local handle={Value=0}
 local function apply()
  for _,p in ipairs(model:GetDescendants())do
   if p:IsA('BasePart')then p.LocalTransparencyModifier=handle.Value end
  end
 end
 function handle.Set(v)handle.Value=v;apply()end
 -- Parts can stream in later; keep them in step.
 self:Add(model.DescendantAdded:Connect(function(p)if p:IsA('BasePart')then p.LocalTransparencyModifier=handle.Value end end))
 self:Add(function()handle.Value=0;if model.Parent then apply()end end)
 return handle
end
--[[ Scope:Offset(model): move the dog's visuals locally, e.g. rise out of the ground.
 handle.CFrame is applied around the dog's ground point on top of wherever the server
 puts it, every frame (a new server CFrame is picked up as the new base). ]]
local function movePivot(model,cf)
 local root=model:GetAttribute('RootWelded')and model.PrimaryPart
 if root then root.CFrame=cf*root.PivotOffset:Inverse()else model:PivotTo(cf)end
end
function Scope:Offset(model)
 local handle={CFrame=CFrame.identity}
 local base,written=nil,nil
 local function differs(a,b)
  return (a.Position-b.Position).Magnitude>1e-3 or a.LookVector:Dot(b.LookVector)<.99999 or a.UpVector:Dot(b.UpVector)<.99999
 end
 local name='DOGROTS_SecretOffset_'..tostring(handle):sub(-8)
 Run:BindToRenderStep(name,Enum.RenderPriority.First.Value,function()
  if not model.Parent or not K.Root(model)then return end
  local current=model:GetPivot()
  if not written or differs(current,written)then base=current end
  local ground=model:GetAttribute('GroundLocal')or Vector3.zero
  written=base*CFrame.new(ground)*handle.CFrame*CFrame.new(-ground)
  movePivot(model,written)
 end)
 -- Fully anchored dogs (display dogs) stream in part by part: a part that arrives at
 -- its server place joins the offset pose instead of tearing away from it.
 if not model:GetAttribute('RootWelded')then
  self:Add(model.DescendantAdded:Connect(function(p)
   if p:IsA('BasePart')and base and written and p~=K.Root(model)then p.CFrame=written*base:Inverse()*p.CFrame end
  end))
 end
 self:Add(function()
  Run:UnbindFromRenderStep(name)
  if base and model.Parent and K.Root(model)and written and not differs(model:GetPivot(),written)then movePivot(model,base)end
 end)
 return handle
end
function Scope:Highlight(model,fill,outline,fillAlpha,outlineAlpha)
 local h=Instance.new('Highlight');h.Name='DOGROTS_SecretHighlight';h.Adornee=model
 h.FillColor=fill;h.OutlineColor=outline or fill;h.FillTransparency=fillAlpha or .6;h.OutlineTransparency=outlineAlpha or 0
 h.DepthMode=Enum.HighlightDepthMode.Occluded;h.Parent=self.Folder
 return h
end
--[[ Scope:Ghost(model, cframe?): a frozen local copy of the dog's parts (no rig, no
 prompts), for after-images, duplicates and clones. Returns the Model. ]]
function Scope:Ghost(model,cf)
 local ghost=Instance.new('Model');ghost.Name='Ghost'
 local pivot=model:GetPivot()
 for _,p in ipairs(model:GetDescendants())do
  if p:IsA('BasePart')and p.Transparency<1 and p.Name~='RootPart'then
   local ok,copy=pcall(function()return p:Clone()end)
   if ok and copy then
    for _,c in ipairs(copy:GetChildren())do
     if not(c:IsA('DataModelMesh')or c:IsA('SurfaceAppearance')or c:IsA('Decal')or c:IsA('Texture'))then c:Destroy()end
    end
    copy.Anchored=true;copy.CanCollide=false;copy.CanTouch=false;copy.CanQuery=false;copy.CastShadow=false
    copy.CFrame=p.CFrame;copy.LocalTransparencyModifier=0;copy.Parent=ghost
   end
  end
 end
 ghost.WorldPivot=pivot;ghost.Parent=self.Folder
 if cf then ghost:PivotTo(cf)end
 return ghost
end
function K.SetGhostAlpha(ghost,alpha)
 for _,p in ipairs(ghost:GetDescendants())do if p:IsA('BasePart')then p.LocalTransparencyModifier=alpha end end
end
return K
