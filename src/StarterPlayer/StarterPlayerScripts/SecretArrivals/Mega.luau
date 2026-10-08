-- The island-wide layer of every Secret arrival. Mega/<DogId> returns function(m) and runs
-- on every client on the server, near the dog or across the map (the server broadcasts
-- each arrival, so even a player whose stream never held the dog sees it). The dog's own
-- cinematic (Dogs/<DogId>) stays at the stage; this layer owns the sky, colossal set
-- pieces, shockwaves that reach every player where they stand, the banner, the compass
-- to the arrival and the chat line. Everything is local, lives in m.Scope and is undone
-- on Clean (a hard ceiling cleans it even if a module errors or never returns).
local Players=game:GetService('Players')
local RS=game:GetService('ReplicatedStorage')
local Run=game:GetService('RunService')
local Lighting=game:GetService('Lighting')
local TextChat=game:GetService('TextChatService')
local SoundService=game:GetService('SoundService')
local Kit=require(script.Parent:WaitForChild('Kit'))
local Config=require(RS:WaitForChild('SecretArrivalConfig'))
local Definitions=require(RS:WaitForChild('DogEconomy'):WaitForChild('DogDefinitions'))
local player=Players.LocalPlayer
local C=Color3.fromRGB
local M={Running={},Modules={}}
-- The playable island (streaming makes the district's live bounding box unreliable).
-- The giant head (02_DogFactory/THE_DOG, x ±64, z -238..-120, roof y 86) looks down its
-- tongue toward +Z: the yards (z ±152), the Welcome Hub (z ~340) and the DOG-O-MATIC
-- (z ~650) all face it, so colossal set pieces rise above and behind the head.
M.Center=Vector3.new(0,0,240)
M.Radius=640
M.SkyHeight=320
M.Head=Vector3.new(0,86,-180)
M.Stage=Vector3.new(0,2,-150)
M.Hub=Vector3.new(0,1,342)
M.Machine=Vector3.new(-145,30,650)

local function smooth(x)x=math.clamp(x,0,1);return x*x*(3-2*x)end
local function backOut(x)local c=1.70158;x-=1;return 1+(c+1)*x*x*x+c*x*x end
M.Smooth=smooth;M.BackOut=backOut

---------------------------------------------------------------- screen
local screen
local function overlay()
 if screen and screen.Parent then return screen end
 screen=Instance.new('ScreenGui');screen.Name='DOGROTS_SecretMega';screen.ResetOnSpawn=false
 screen.IgnoreGuiInset=true;screen.DisplayOrder=95;screen.ZIndexBehavior=Enum.ZIndexBehavior.Sibling
 screen.Parent=player:WaitForChild('PlayerGui')
 return screen
end
M.Overlay=overlay
local function label(parent,props)
 local l=Instance.new('TextLabel');l:SetAttribute('KeepFont',true)
 l.BackgroundTransparency=1;l.TextScaled=true;l.Font=Enum.Font.FredokaOne;l.TextColor3=Color3.new(1,1,1)
 for k,v in pairs(props)do (l::any)[k]=v end
 l.Parent=parent
 return l
end
M.Label=label

---------------------------------------------------------------- sound
local TICK='rbxasset://sounds/volume_slider.ogg'
local function sound(parent,volume,speed,looped,effects)
 local s=Instance.new('Sound');s.SoundId=TICK;s.Volume=volume;s.PlaybackSpeed=speed or 1;s.Looped=looped==true
 s.RollOffMinDistance=40;s.RollOffMaxDistance=900;s.Parent=parent or SoundService
 for class,props in pairs(effects or {})do
  local e=Instance.new(class);for k,v in pairs(props)do (e::any)[k]=v end;e.Parent=s
 end
 return s
end

---------------------------------------------------------------- context
local Context={};Context.__index=Context
function Context:Wait(t)
 while self.Scope.Alive do
  local remaining=self.Start+t-workspace:GetServerTimeNow()
  if remaining<=0 then return true end
  task.wait(math.min(remaining,.1))
 end
 return false
end
function Context:Elapsed()return workspace:GetServerTimeNow()-self.Start end
function Context:Alive()return self.Scope.Alive end
-- True while the beat at t is happening now (a late joiner skips one-shot stingers).
function Context:Fresh(t,window)return math.abs(self:Elapsed()-t)<(window or .4)end
function Context:Camera()local c=workspace.CurrentCamera;return c and c.CFrame.Position or self.Origin end
function Context:CameraCFrame()local c=workspace.CurrentCamera;return c and c.CFrame or CFrame.new(self.Origin)end
-- 0..1 how close this player's camera is to the arrival.
function Context:Near(radius)return Kit.Near(self.Origin,radius or 180)end
local groundParams
function Context:Ground(at)
 if not groundParams then
  groundParams=RaycastParams.new();groundParams.FilterType=Enum.RaycastFilterType.Include
  local district=workspace:FindFirstChild('DOGROTS_District')
  groundParams.FilterDescendantsInstances={district or workspace.Terrain,workspace.Terrain}
  groundParams.RespectCanCollide=true
 end
 local hit=workspace:Raycast(Vector3.new(at.X,(at.Y or 0)+400,at.Z),Vector3.new(0,-900,0),groundParams)
 return hit and hit.Position or Vector3.new(at.X,0,at.Z)
end
function Context:Every(fn)return self.Scope:Every(fn)end
function Context:Add(x)return self.Scope:Add(x)end
function Context:Tween(o,seconds,props,style,direction)
 local t=Kit.Tween(o,seconds,props,style,direction)
 self.Scope:Add(function()t:Cancel()end)
 return t
end
function Context:Part(props)return self.Scope:Part(props)end
function Context:Ball(props)local p=self.Scope:Part(props);p.Shape=Enum.PartType.Ball;return p end
function Context:Anchor(position,name)return self.Scope:Anchor(position,name)end
function Context:Light(parent,color,range,brightness)return self.Scope:Light(parent,color,range,brightness)end
function Context:Emitter(parent,props)return self.Scope:Emitter(parent,props)end
function Context:Burst(position,color,count,props)return self.Scope:Burst(position,color,count,props)end
function Context:Beam(a,b,color,width,props)return self.Scope:Beam(a,b,color,width,props)end
function Context:Bolt(a,b,color,width,seconds)return self.Scope:Bolt(a,b,color,width,seconds)end
function Context:Model(name)
 local m=Instance.new('Model');m.Name=name or 'Piece';m.WorldPivot=CFrame.identity;m.Parent=self.Scope.Folder
 return m
end
-- A straight neon bar from a to b (rods, web threads, cube edges, light rays).
function Context:Line(a,b,color,width,props)
 local p=self.Scope:Part({Name='Line',Color=color,Size=Vector3.new(width,width,math.max((b-a).Magnitude,.05)),CFrame=Kit.LookAt((a+b)/2,b)})
 for k,v in pairs(props or {})do (p::any)[k]=v end
 return p
end
function Context:SetLine(p,a,b,width)
 p.Size=Vector3.new(width or p.Size.X,width or p.Size.Y,math.max((b-a).Magnitude,.05));p.CFrame=Kit.LookAt((a+b)/2,b)
end
function Context:Grade(props,fadeIn,fadeOut)return self.Scope:Grade(props,fadeIn,fadeOut)end
function Context:Blur(size,fadeIn,fadeOut)return self.Scope:Blur(size,fadeIn,fadeOut)end
function Context:Bloom(intensity,size,threshold,fadeIn,fadeOut)
 local camera=workspace.CurrentCamera;if not camera then return nil end
 local b=Instance.new('BloomEffect');b.Name='DOGROTS_MegaBloom';b.Intensity=0;b.Size=size or 30;b.Threshold=threshold or 1;b.Parent=camera
 Kit.Tween(b,fadeIn or .8,{Intensity=intensity or .6})
 self.Scope:Add(function()local t=Kit.Tween(b,fadeOut or 1,{Intensity=0});t.Completed:Connect(function()b:Destroy()end)end)
 return b
end
function Context:Shake(power,seconds)if not self.Reduced then Kit.Shake(power,seconds)end end
function Context:Flash(color,alpha,seconds)Kit.Flash(color,alpha,seconds)end
function Context:FOV(delta,inSeconds,outSeconds)Kit.FOVPunch(delta,inSeconds,outSeconds)end
function Context:Duck(level,fade)return self.Scope:Duck(level,fade)end
function Context:Drone(kind,volume,speed,fade)return self.Scope:Drone(kind,volume,speed,fade)end
--[[ Context:Cue(kind, parent?, volume?): every Kit cue (Heartbeat, Impact, Glitch, Chime, Whoosh,
 Sting) plus island-scale ones built from the same built-in tick:
 Siren (a rising/falling alarm for `seconds`), Rumble (a long low roll), Geiger (crackle for
 `seconds`), Boom (a huge distant detonation), Static (a burst of broken signal). ]]
function Context:Cue(kind,parent,volume,seconds)
 if kind=='Siren'then
  local s=sound(parent,volume or .35,1,true,{DistortionSoundEffect={Level=.45},ReverbSoundEffect={DecayTime=3,WetLevel=-4}})
  s:Play();local started=os.clock();local life=seconds or 4
  self.Scope:Every(function()
   local age=os.clock()-started
   s.PlaybackSpeed=.55+.35*(.5+.5*math.sin(age*math.pi*1.1))
   if age>life then s.Volume=math.max(0,s.Volume-.02)end
   if age>life+1.5 then s:Destroy();return false end
   return true
  end)
  self.Scope:Add(s)
  return s
 elseif kind=='Rumble'then
  local s=sound(parent,volume or .8,.08,true,{EqualizerSoundEffect={LowGain=10,MidGain=-12,HighGain=-40},ReverbSoundEffect={DecayTime=5,WetLevel=0}})
  s:Play();self.Scope:Add(s)
  task.delay(seconds or 3,function()if s.Parent then Kit.Tween(s,1.2,{Volume=0}).Completed:Connect(function()s:Destroy()end)end end)
  return s
 elseif kind=='Geiger'then
  local life=seconds or 4
  task.spawn(function()
   local started=os.clock()
   while self.Scope.Alive and os.clock()-started<life do
    local s=sound(parent,(volume or .35)*Kit.Random(.5,1),Kit.Random(2.6,4),false,{DistortionSoundEffect={Level=.6}})
    s:Play();task.delay(1,function()s:Destroy()end)
    task.wait(Kit.Random(.02,.18))
   end
  end)
 elseif kind=='Boom'then
  Kit.Cue('Impact',parent,volume or 1)
  local s=sound(parent,(volume or 1)*.9,.06,false,{EqualizerSoundEffect={LowGain=10,MidGain=-6,HighGain=-40},DistortionSoundEffect={Level=.7},
   ReverbSoundEffect={DecayTime=8,WetLevel=0,DryLevel=-2,Density=1,Diffusion=1}})
  s:Play();task.delay(9,function()s:Destroy()end)
 elseif kind=='Static'then
  for i=0,14 do
   task.delay(i*.03,function()
    local s=sound(parent,(volume or .4)*Kit.Random(.4,1),Kit.Random(.6,5),false,{DistortionSoundEffect={Level=.9}})
    s:Play();task.delay(1,function()s:Destroy()end)
   end)
  end
 else Kit.Cue(kind,parent,volume)end
end

--[[ Context:Sky(target, fadeIn, fadeOut) → handle (handle.Release() fades back early).
 Blends this client's Lighting toward target ({ClockTime, Brightness, Ambient, OutdoorAmbient,
 ExposureCompensation, FogColor, FogStart, FogEnd}) and back. The server's day cycle writes
 Lighting once a second: every frame, just before rendering, the blend re-applies on top of
 the newest server value, so nothing flickers. An active world event drives Lighting
 itself (also while it fades out, and if one starts mid-arrival the blend hands Lighting
 back at once); then the module's camera grade carries the mood. ]]
function Context:Sky(target,fadeIn,fadeOut)
 local events=RS:FindFirstChild('WorldEvents');local state=events and events:FindFirstChild('State')
 local function eventOwns()local phase=state and state:GetAttribute('State');return phase=='ACTIVE'or phase=='ENDING'end
 if eventOwns()then return nil end
 local keys,base,written={}, {}, {}
 for k in pairs(target)do table.insert(keys,k);base[k]=(Lighting::any)[k]end
 local handle={Current=0}
 local started,releasing,from=os.clock(),nil,1
 local function apply(a)
  for _,k in ipairs(keys)do
   local current=(Lighting::any)[k]
   if written[k]~=nil and current~=written[k]then base[k]=current end
   local b,t=base[k],target[k];local v
   if k=='ClockTime'then local d=(t-b)%24;if d>12 then d-=24 end;v=(b+d*a)%24
   elseif typeof(b)=='Color3'then v=b:Lerp(t,a)
   else v=b+(t-b)*a end
   (Lighting::any)[k]=v;written[k]=(Lighting::any)[k]
  end
 end
 local function restore()
  for _,k in ipairs(keys)do if written[k]~=nil and (Lighting::any)[k]==written[k]then (Lighting::any)[k]=base[k]end end
  table.clear(written)
 end
 local name='DOGROTS_MegaSky_'..string.sub(tostring(handle),-8)
 Run:BindToRenderStep(name,Enum.RenderPriority.First.Value,function()
  if eventOwns()then restore();Run:UnbindFromRenderStep(name);return end
  local a
  if releasing then a=from*(1-smooth((os.clock()-releasing)/(fadeOut or 2.5)))
  else a=smooth((os.clock()-started)/(fadeIn or 1.5))end
  handle.Current=a;apply(a)
  if releasing and a<=0 then Run:UnbindFromRenderStep(name)end
 end)
 function handle.Release()if not releasing then from=handle.Current;releasing=os.clock()end end
 self.Scope:Add(function()Run:UnbindFromRenderStep(name);restore()end)
 return handle
end

--[[ Context:Banner(title, options): the island-wide reveal banner in the lower third of every
 screen. options: Kicker (default "SECRET ARRIVAL"), Sub, Color, Font, Hold (4.5 s),
 Glitch (true: chromatic jitter), Shake (0..1 punch). Returns the frame. ]]
function Context:Banner(title,options)
 options=options or {}
 local color=options.Color or self.Color
 local gui=overlay()
 local holder=Instance.new('Frame');holder.Name='MegaBanner';holder.BackgroundTransparency=1;holder.AnchorPoint=Vector2.new(.5,.5)
 holder.Position=UDim2.fromScale(.5,.7);holder.Size=UDim2.new(.9,0,0,170);holder.ZIndex=20;holder.Parent=gui
 local limit=Instance.new('UISizeConstraint');limit.MaxSize=Vector2.new(980,170);limit.Parent=holder
 local scale=Instance.new('UIScale');scale.Scale=self.Reduced and 1 or 1.7;scale.Parent=holder
 local streak=Instance.new('Frame');streak.Name='Streak';streak.BorderSizePixel=0;streak.AnchorPoint=Vector2.new(.5,.5)
 streak.Position=UDim2.fromScale(.5,.5);streak.Size=UDim2.new(0,0,0,3);streak.BackgroundColor3=color;streak.ZIndex=19;streak.Parent=holder
 local g=Instance.new('UIGradient');g.Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,1),NumberSequenceKeypoint.new(.5,0),NumberSequenceKeypoint.new(1,1)});g.Parent=streak
 local font=options.Font or Enum.Font.FredokaOne
 local kicker=label(holder,{Name='Kicker',Text=options.Kicker or '✦   S E C R E T   A R R I V A L   ✦',Font=Enum.Font.GothamBlack,
  TextColor3=color:Lerp(Color3.new(1,1,1),.45),TextTransparency=1,Size=UDim2.new(1,0,0,26),Position=UDim2.new(0,0,0,6),ZIndex=21})
 local glow=label(holder,{Name='TitleGlow',Text=title,Font=font,TextColor3=color,TextTransparency=1,Size=UDim2.new(1,0,0,92),Position=UDim2.new(0,0,0,36),ZIndex=20})
 local glowStroke=Instance.new('UIStroke');glowStroke.Color=color;glowStroke.Thickness=9;glowStroke.Transparency=1;glowStroke.Parent=glow
 local main=label(holder,{Name='Title',Text=title,Font=font,TextTransparency=1,Size=UDim2.new(1,0,0,92),Position=UDim2.new(0,0,0,36),ZIndex=22})
 local stroke=Instance.new('UIStroke');stroke.Color=C(10,8,18);stroke.Thickness=3;stroke.Transparency=1;stroke.Parent=main
 local shine=Instance.new('UIGradient')
 shine.Color=ColorSequence.new({ColorSequenceKeypoint.new(0,color),ColorSequenceKeypoint.new(.45,Color3.new(1,1,1)),ColorSequenceKeypoint.new(.55,Color3.new(1,1,1)),ColorSequenceKeypoint.new(1,color)})
 shine.Parent=main
 local sub=label(holder,{Name='Sub',Text=options.Sub or '',TextColor3=Color3.new(1,1,1),TextTransparency=1,Size=UDim2.new(1,0,0,30),Position=UDim2.new(0,0,0,132),ZIndex=21})
 local subStroke=Instance.new('UIStroke');subStroke.Color=C(10,8,18);subStroke.Thickness=2;subStroke.Transparency=1;subStroke.Parent=sub
 for _,l in ipairs({kicker,glow,main,sub})do local s=Instance.new('UITextSizeConstraint');s.MaxTextSize=l==kicker and 22 or l==sub and 26 or 86;s.Parent=l end
 Kit.Tween(streak,.35,{Size=UDim2.new(1,0,0,3)})
 Kit.Tween(scale,.55,{Scale=1},Enum.EasingStyle.Back)
 Kit.Tween(main,.3,{TextTransparency=0});Kit.Tween(stroke,.3,{Transparency=0})
 Kit.Tween(glow,.5,{TextTransparency=.35});Kit.Tween(glowStroke,.5,{Transparency=.55})
 task.delay(.25,function()if holder.Parent then Kit.Tween(kicker,.4,{TextTransparency=0});Kit.Tween(sub,.5,{TextTransparency=0});Kit.Tween(subStroke,.5,{Transparency=.2})end end)
 local started=os.clock();local hold=options.Hold or 4.5
 local connection;connection=Run.RenderStepped:Connect(function()
  if not holder.Parent then connection:Disconnect();return end
  local age=os.clock()-started
  shine.Offset=Vector2.new(-1+((age*.6)%2),0)
  if options.Glitch and not self.Reduced then
   local j=math.random()<.18 and math.random(-6,6)or 0
   main.Position=UDim2.new(0,j,0,36);glow.Position=UDim2.new(0,-j*2,0,36+(j~=0 and math.random(-2,2)or 0))
  end
  if age>hold then
   connection:Disconnect()
   for _,o in ipairs({kicker,glow,main,sub})do Kit.Tween(o,.8,{TextTransparency=1})end
   for _,o in ipairs({glowStroke,stroke,subStroke})do Kit.Tween(o,.8,{Transparency=1})end
   Kit.Tween(streak,.8,{Size=UDim2.new(0,0,0,3)})
   task.delay(.9,function()holder:Destroy()end)
  end
 end)
 self.Scope:Add(function()if holder.Parent then task.delay(.9,function()holder:Destroy()end)end end)
 if options.Shake and not self.Reduced then Kit.Shake(options.Shake,.5)end
 return holder
end

--[[ Context:Compass(text, seconds): a marker that follows the arrival on screen, or clings to
 the screen edge and points at it while it is behind you. Hidden once you are close. ]]
function Context:Compass(text,seconds)
 local gui=overlay()
 local frame=Instance.new('Frame');frame.Name='MegaCompass';frame.BackgroundTransparency=1;frame.AnchorPoint=Vector2.new(.5,.5)
 frame.Size=UDim2.fromOffset(220,64);frame.ZIndex=15;frame.Parent=gui
 local arrow=label(frame,{Name='Arrow',Text='▲',TextColor3=self.Color,Size=UDim2.fromOffset(34,34),Position=UDim2.fromOffset(93,0),ZIndex=16})
 local arrowStroke=Instance.new('UIStroke');arrowStroke.Color=C(10,8,18);arrowStroke.Thickness=2;arrowStroke.Parent=arrow
 local name=label(frame,{Name='Name',Text=text,Size=UDim2.fromOffset(220,24),Position=UDim2.fromOffset(0,36),ZIndex=16,TextColor3=self.Color:Lerp(Color3.new(1,1,1),.5)})
 local nameStroke=Instance.new('UIStroke');nameStroke.Color=C(10,8,18);nameStroke.Thickness=2;nameStroke.Parent=name
 local started=os.clock()
 self.Scope:Add(frame)
 self.Scope:Every(function()
  local camera=workspace.CurrentCamera;if not camera then return true end
  local age=os.clock()-started
  local fade=math.clamp((age-(seconds or 12))/1,0,1)
  local target=self.Origin+Vector3.new(0,14,0)
  local distance=(camera.CFrame.Position-target).Magnitude
  local hidden=distance<70
  local alpha=hidden and 1 or fade
  arrow.TextTransparency=alpha;name.TextTransparency=alpha;arrowStroke.Transparency=alpha;nameStroke.Transparency=alpha
  name.Text=text..'  ·  '..math.floor(distance*.28)..'m'
  local view=camera.ViewportSize
  local point,onScreen=camera:WorldToViewportPoint(target)
  local x,y=point.X,point.Y
  if point.Z<0 then x,y=view.X-x,view.Y-y end
  local margin=60
  if onScreen and x>margin and x<view.X-margin and y>margin and y<view.Y-margin then
   frame.Position=UDim2.fromOffset(x,y-30);arrow.Rotation=180
  else
   local cx,cy=view.X/2,view.Y/2;local dx,dy=x-cx,y-cy
   if math.abs(dx)<1e-3 and math.abs(dy)<1e-3 then dy=-1 end
   local k=math.min((cx-margin)/math.max(math.abs(dx),1e-3),(cy-margin)/math.max(math.abs(dy),1e-3))
   frame.Position=UDim2.fromOffset(cx+dx*k,cy+dy*k);arrow.Rotation=math.deg(math.atan2(dy,dx))+90
  end
  if fade>=1 then frame:Destroy();return false end
  return true
 end)
 return frame
end

-- A line in every player's chat (system message), coloured.
function Context:Chat(text,color)
 pcall(function()
  local channels=TextChat:FindFirstChild('TextChannels');local general=channels and channels:FindFirstChild('RBXGeneral')
  if general then general:DisplaySystemMessage(string.format('<font color="#%s"><b>%s</b></font>',(color or self.Color):ToHex(),text))end
 end)
end

--[[ Context:SkyDog(height, options) → handle | nil: a colossal local clone of the arriving dog
 (its MenuModels preview) for the sky. options: Clip (default 'Idle'), Speed, Fill/Outline
 (Highlight colours; nil = no highlight), FillAlpha. handle:Place(feet, look) stands it with
 its feet at `feet` facing `look`; handle:Pivot(cframe); handle:SetAlpha(0..1 visible). The
 clip steps every frame until the scope ends. ]]
function Context:SkyDog(height,options)
 options=options or {}
 local def=Definitions[options.DogId or self.DogId]
 local folder=RS:FindFirstChild('MenuModels')
 local template=folder and def and folder:FindFirstChild(def.VisualAsset)
 if not template or not template:IsA('Model')then return nil end
 local ok,m=pcall(function()return template:Clone()end)
 if not ok or not m then return nil end
 local parts={}
 for _,o in ipairs(m:GetDescendants())do
  if o:IsA('BasePart')then
   o.Anchored=true;o.CanCollide=false;o.CanTouch=false;o.CanQuery=false;o.CastShadow=false
   if o.Name~='RootPart'and o.Transparency<1 then table.insert(parts,o)end
  elseif o:IsA('LuaSourceContainer')or o:IsA('ProximityPrompt')or o:IsA('BillboardGui')or o:IsA('Sound')or o:IsA('ParticleEmitter')then o:Destroy()end
 end
 if not m:GetAttribute('AnimationBaseScale')then m:SetAttribute('AnimationBaseScale',m:GetScale())end
 m:PivotTo(CFrame.identity)
 -- Measured like Rig.Bounds: visible meshes only (the 2x2x1 RootPart would dwarf tiny rigs).
 local function bounds()
  local low,high=Vector3.one*math.huge,-Vector3.one*math.huge
  for _,p in ipairs(parts)do
   for x=-1,1,2 do for y=-1,1,2 do for z=-1,1,2 do
    local point=p.CFrame:PointToWorldSpace(p.Size*Vector3.new(x,y,z)/2)
    low,high=low:Min(point),high:Max(point)
   end end end
  end
  return low,high
 end
 local low,high=bounds()
 if low.Y==math.huge then m:Destroy();return nil end
 if high.Y-low.Y>.01 then m:ScaleTo(m:GetScale()*height/(high.Y-low.Y));low,high=bounds()end
 local box=high-low
 local ground=Vector3.new((low.X+high.X)/2,low.Y,(low.Z+high.Z)/2)
 m.Name='MegaDog';m.Parent=self.Scope.Folder
 local handle={Model=m,Parts=parts,Size=box,Ground=ground,Alpha=1}
 if options.Fill or options.Outline then
  local h=Instance.new('Highlight');h.FillColor=options.Fill or self.Color;h.OutlineColor=options.Outline or self.Color
  h.FillTransparency=options.FillAlpha or .55;h.OutlineTransparency=.1;h.DepthMode=Enum.HighlightDepthMode.Occluded;h.Adornee=m;h.Parent=m
  handle.Highlight=h
 end
 local okPlayer,Anim=pcall(require,RS:FindFirstChild('DogAnimationPlayer'))
 if okPlayer and Anim then
  local okNew,a=pcall(Anim.new,m,options.DogId or self.DogId)
  if okNew and a then
   local clip=options.Clip or 'Idle'
   if a:Play(clip,{Looped=options.Looped~=false,Speed=options.Speed or 1})or a:Play('Idle',{Looped=true})then handle.Anim=a end
  end
 end
 function handle:Pivot(frame)m:PivotTo(frame)end
 function handle:Place(feet,look)
  local flat=Vector3.new(look.X,0,look.Z)
  if flat.Magnitude<1e-3 then flat=Vector3.zAxis end
  m:PivotTo(CFrame.lookAt(feet,feet+flat)*CFrame.new(-ground))
 end
 function handle:SetAlpha(a)
  handle.Alpha=a
  for _,p in ipairs(parts)do p.LocalTransparencyModifier=1-a end
  if handle.Highlight then handle.Highlight.FillTransparency=1-(1-(options.FillAlpha or .55))*a;handle.Highlight.OutlineTransparency=1-.9*a end
 end
 function handle:Play(clip,looped)if handle.Anim then handle.Anim:Play(clip,{Looped=looped~=false})end end
 if handle.Anim then
  self.Scope:Every(function()if m.Parent then handle.Anim:Step()end;return m.Parent~=nil end)
  self.Scope:Add(function()pcall(function()handle.Anim:Destroy()end)end)
 end
 return handle
end

--[[ Context:FollowRain(props, height?): a ParticleEmitter on a wide invisible slab that stays
 above this player's camera, so the island-wide "it is raining X" is everywhere you go. ]]
function Context:FollowRain(props,height)
 local slab=self.Scope:Part({Name='MegaRain',Size=Vector3.new(220,1,220),Transparency=1})
 local e=self.Scope:Emitter(slab,{Rate=0,EmissionDirection=Enum.NormalId.Bottom,SpreadAngle=Vector2.new(4,4),Speed=NumberRange.new(30,50),
  Lifetime=NumberRange.new(3,5),Size=NumberSequence.new(1.2),Transparency=NumberSequence.new(.1),LightInfluence=.4,LightEmission=.4})
 e.Shape=Enum.ParticleEmitterShape.Box;e.ShapeInOut=Enum.ParticleEmitterShapeInOut.Outward;e.ShapeStyle=Enum.ParticleEmitterShapeStyle.Volume
 for k,v in pairs(props or {})do (e::any)[k]=v end
 if self.Low then e.Rate=e.Rate*.35 end
 local h=height or 80
 self.Scope:Every(function()
  local c=workspace.CurrentCamera
  if c then slab.CFrame=CFrame.new(c.CFrame.Position+Vector3.new(0,h,0))end
  return slab.Parent~=nil
 end)
 return e,slab
end

--[[ Context:Fall(options): physical-looking local debris raining down around this player:
 cubes, feathers, bones, ash. options: Count, Radius (around the camera), Height, Make(i) →
 BasePart, Gravity (studs/s²), Life, Spin, Bounce (true = bounce on the ground). ]]
function Context:Fall(options)
 local count=math.max(1,math.floor((options.Count or 24)*(self.Low and .4 or 1)))
 local center=options.Around or self:Camera()
 local pieces={}
 for i=1,count do
  local p=options.Make(i)
  local a=Kit.Random(0,math.pi*2);local r=math.sqrt(Kit.Random(0,1))*(options.Radius or 160)
  local at=center+Vector3.new(math.cos(a)*r,(options.Height or 140)+Kit.Random(0,60),math.sin(a)*r)
  local floor=self:Ground(at).Y+p.Size.Y/2
  table.insert(pieces,{Part=p,Pos=at,Vel=Vector3.new(Kit.Random(-6,6),-Kit.Random(10,40),Kit.Random(-6,6))+(options.Velocity or Vector3.zero),
   Rot=CFrame.Angles(Kit.Random(0,6),Kit.Random(0,6),Kit.Random(0,6)),Spin=Vector3.new(Kit.Random(-1,1),Kit.Random(-1,1),Kit.Random(-1,1))*(options.Spin or 4),
   Floor=floor,Delay=Kit.Random(0,options.Spread or 1.5),Drag=options.Drag or 0})
  p.CFrame=CFrame.new(at);p.Transparency=1
 end
 local gravity=options.Gravity or 90;local life=options.Life or 6
 self.Scope:Every(function(dt,age)
  for _,v in ipairs(pieces)do
   if v.Part.Parent and age>=v.Delay then
    if not v.Shown then v.Shown=true;v.Part.Transparency=options.Alpha or 0 end
    v.Vel-=Vector3.new(0,gravity*dt,0)
    if v.Drag>0 then v.Vel*=math.max(0,1-v.Drag*dt)end
    local pos=v.Pos+v.Vel*dt
    if pos.Y<v.Floor then
     pos=Vector3.new(pos.X,v.Floor,pos.Z)
     if options.Bounce~=false then v.Vel=Vector3.new(v.Vel.X*.6,math.abs(v.Vel.Y)*.32,v.Vel.Z*.6)else v.Vel=Vector3.zero end
     v.Spin*=.5
    end
    v.Pos=pos;v.Rot*=CFrame.Angles(v.Spin.X*dt,v.Spin.Y*dt,v.Spin.Z*dt)
    v.Part.CFrame=CFrame.new(pos)*v.Rot
    local f=math.clamp((age-v.Delay-(life-1))/1,0,1)
    if f>0 then v.Part.Transparency=(options.Alpha or 0)+(1-(options.Alpha or 0))*f end
   end
  end
  if age<life+(options.Spread or 1.5)then return true end
  for _,v in ipairs(pieces)do if v.Part.Parent then v.Part:Destroy()end end
  return false
 end)
 return pieces
end

--[[ Context:Shockwave(center, color, options): a wall of light that sweeps out across the whole
 island at options.Speed studs/s (default 260) to options.Radius (default M.Radius+300). When
 it passes this player's camera it calls options.OnPass() (shake, flash, sound) — so every
 player feels it at the moment it reaches them. options.Height, Thickness, Segments, Alpha. ]]
function Context:Shockwave(center,color,options)
 options=options or {}
 local count=math.clamp(options.Segments or (self.Low and 32 or 56),12,72)
 local height=options.Height or 16;local thick=options.Thickness or 1.2
 local maxR=options.Radius or (M.Radius+300);local speed=options.Speed or 260
 local alpha0=options.Alpha or .2
 local m=self:Model('Shockwave')
 local parts={}
 for i=1,count do parts[i]=self.Scope:Part({Name='Wave',Color=color,Size=Vector3.new(thick,height,1),Transparency=alpha0,Parent=m})end
 local passed=false
 local start=os.clock()
 self.Scope:Every(function()
  local age=os.clock()-start
  local r=math.max(1,age*speed)
  local life=math.clamp(r/maxR,0,1)
  local h=height*(1-life*.6)
  local width=2*math.pi*r/count*1.04
  for i,p in ipairs(parts)do
   local t0,t1=(i-1)/count*math.pi*2,i/count*math.pi*2
   local a0=center+Vector3.new(math.cos(t0)*r,0,math.sin(t0)*r)
   local a1=center+Vector3.new(math.cos(t1)*r,0,math.sin(t1)*r)
   local mid=(a0+a1)/2+Vector3.new(0,h/2,0)
   p.Size=Vector3.new(thick,h,width);p.CFrame=Kit.LookAt(mid,mid+(a1-a0))
   p.Transparency=alpha0+(1-alpha0)*life*life
  end
  if not passed then
   local cam=self:Camera()
   local d=Vector3.new(cam.X-center.X,0,cam.Z-center.Z).Magnitude
   if d<=r then passed=true;if options.OnPass then task.spawn(options.OnPass,d)end end
  end
  if r>=maxR then m:Destroy();return false end
  return true
 end)
 return m
end

-- A flat ring of neon segments growing from r0 to r1 (any size up to the whole island).
function Context:Ring(center,color,r0,r1,seconds,props)
 props=props or {}
 local count=math.clamp(props.Segments or 48,8,96);if self.Low then count=math.max(8,math.floor(count/2))end
 local U,W=props.U or Vector3.xAxis,props.W or Vector3.zAxis
 local thick=props.Thickness or 1;local alpha0=props.Alpha or .1
 local m=self:Model('MegaRing')
 local parts={}
 for i=1,count do parts[i]=self.Scope:Part({Name='Segment',Color=color,Size=Vector3.new(thick,thick,1),Transparency=alpha0,Parent=m})end
 local start=os.clock()
 self.Scope:Every(function()
  local a=math.min((os.clock()-start)/seconds,1)
  local e=props.Linear and a or 1-(1-a)^3
  local r=r0+(r1-r0)*e
  local width=2*math.pi*r/count*1.06
  for i,p in ipairs(parts)do
   local t0,t1=(i-1)/count*math.pi*2,i/count*math.pi*2
   local a0=center+U*math.cos(t0)*r+W*math.sin(t0)*r
   local a1=center+U*math.cos(t1)*r+W*math.sin(t1)*r
   p.Size=Vector3.new(thick,thick,width);p.CFrame=Kit.LookAt((a0+a1)/2,a1)
   p.Transparency=props.Hold and alpha0 or alpha0+(1-alpha0)*a
  end
  if a>=1 and not props.Hold then m:Destroy();return false end
  return a<1 or props.Hold==true
 end)
 return m
end

-- A colossal pillar of light from `base` straight up, swelling in and out over `seconds`.
function Context:Pillar(base,height,color,width,seconds)
 local p=self.Scope:Part({Name='MegaPillar',Color=color,Transparency=1,Shape=Enum.PartType.Cylinder})
 local glow=self.Scope:Part({Name='MegaPillarGlow',Color=color,Transparency=1,Shape=Enum.PartType.Cylinder,Material=Enum.Material.ForceField})
 local frame=CFrame.new(base+Vector3.new(0,height/2,0))*CFrame.Angles(0,0,math.pi/2)
 local start=os.clock()
 self.Scope:Every(function()
  local a=math.min((os.clock()-start)/seconds,1)
  local s=math.min(a*5,1)*math.min((1-a)*3,1)
  p.Size=Vector3.new(height,width*s+.05,width*s+.05);p.CFrame=frame;p.Transparency=1-s*.75
  glow.Size=Vector3.new(height,width*2.4*s+.05,width*2.4*s+.05);glow.CFrame=frame;glow.Transparency=1-s*.6
  if a>=1 then p:Destroy();glow:Destroy();return false end
  return true
 end)
 return p
end

--[[ Context:Text3D(text, cframe, size (Vector2 studs), options): a giant sign hanging in the
 sky, readable from both sides. options: Color, Font, Stroke, Alpha. Returns part, labels. ]]
function Context:Text3D(text,frame,size,options)
 options=options or {}
 local p=self.Scope:Part({Name='MegaSign',Size=Vector3.new(size.X,size.Y,.2),CFrame=frame,Transparency=1})
 local labels={}
 for _,face in ipairs({Enum.NormalId.Front,Enum.NormalId.Back})do
  local sg=Instance.new('SurfaceGui');sg.Face=face;sg.LightInfluence=0;sg.Brightness=options.Brightness or 2.5
  sg.SizingMode=Enum.SurfaceGuiSizingMode.PixelsPerStud;sg.PixelsPerStud=math.clamp(900/math.max(size.X,1),2,40);sg.AlwaysOnTop=false;sg.Parent=p
  local l=label(sg,{Text=text,Font=options.Font or Enum.Font.FredokaOne,TextColor3=options.Color or self.Color,Size=UDim2.fromScale(1,1),TextTransparency=options.Alpha or 0})
  if options.Stroke~=false then local s=Instance.new('UIStroke');s.Color=options.StrokeColor or C(10,8,18);s.Thickness=options.StrokeThickness or 4;s.Parent=l end
  table.insert(labels,l)
 end
 return p,labels
end

-- Map parts around this player's camera (for local material/colour overrides), at most `limit`.
function Context:MapParts(radius,limit)
 local district=workspace:FindFirstChild('DOGROTS_District');if not district then return {}end
 local params=OverlapParams.new();params.FilterType=Enum.RaycastFilterType.Include;params.FilterDescendantsInstances={district}
 params.MaxParts=limit or 600
 local ok,parts=pcall(function()return workspace:GetPartBoundsInRadius(self:Camera(),radius,params)end)
 if not ok then return {}end
 local out={}
 for _,p in ipairs(parts)do if p.Transparency<.95 and not p:IsA('Terrain')then table.insert(out,p)end end
 return out
end

-- Screen tint/flash layer only this mega owns (fades out with the scope).
function Context:Tint(color,alpha,fadeIn)
 local f=Instance.new('Frame');f.Name='MegaTint';f.BorderSizePixel=0;f.Size=UDim2.fromScale(1,1);f.BackgroundColor3=color
 f.BackgroundTransparency=1;f.ZIndex=1;f.Parent=overlay()
 Kit.Tween(f,fadeIn or .6,{BackgroundTransparency=alpha})
 self.Scope:Add(function()Kit.Tween(f,.8,{BackgroundTransparency=1}).Completed:Connect(function()f:Destroy()end)end)
 return f
end

---------------------------------------------------------------- runner
for _,module in ipairs(script:GetChildren())do
 if module:IsA('ModuleScript')then
  local ok,run=pcall(require,module)
  if ok and type(run)=='function'then M.Modules[module.Name]=run
  else warn('SecretArrivals Mega: '..module.Name..' unavailable',run)end
 end
end

local venues={Tongue='ON THE DOG LINE',Yard='FROM A LUCKY BLOCK',Machine='AT THE DOG-O-MATIC',Excavation='DUG UP FROM THE DEEP'}
--[[ M.Run(info): info = {DogId, Start, Origin, Venue, By, Uid, Model?}. Safe to call more than
 once per arrival (the broadcast and the streamed dog both call it): the first call wins. ]]
function M.Run(info)
 local id=info.DogId
 local config=Config.Dogs[id]
 if not config or type(info.Start)~='number'then return end
 local uid=info.Uid or (id..':'..tostring(info.Start))
 if M.Running[uid]then
  -- The dog streamed in after the broadcast started this arrival: hand it the model.
  if info.Model and M.Running[uid]~=true then M.Running[uid].Model=info.Model end
  return
 end
 local late=workspace:GetServerTimeNow()-info.Start
 if late>(config.MegaSeconds or 30)then return end
 local scope=Kit.Scope('Mega_'..id)
 local def=Definitions[id]
 local m=setmetatable({DogId=id,Config=config,Color=config.Color,Start=info.Start,Origin=info.Origin or M.Center,
  Venue=info.Venue or 'Tongue',By=info.By,Model=info.Model,Uid=uid,Scope=scope,Kit=Kit,Mega=M,Late=late,
  Low=Kit.Low(),Reduced=Kit.ReducedMotion(),Center=M.Center,Radius=M.Radius,SkyHeight=M.SkyHeight,
  Head=M.Head,Stage=M.Stage,Hub=M.Hub,Machine=M.Machine,
  DisplayName=def and def.DisplayName or config.Title,VenueText=venues[info.Venue or 'Tongue']or ''},Context)
 M.Running[uid]=m
 -- Every player learns about it, wherever they are: the chat line and the compass.
 if late<3 then
  local who=m.By and (' · '..string.upper(m.By))or ''
  m:Chat('✦ SECRET ✦ '..string.upper(config.Title)..' IS ARRIVING '..m.VenueText..who..'!',config.Color)
 end
 if late<8 then m:Compass(string.upper(config.Title),(config.Hold or 6)+8)end
 local run=M.Modules[id]
 task.spawn(function()
  if run then
   local ok,err=xpcall(run,debug.traceback,m)
   if not ok then warn('SecretArrivals Mega '..id..':',err)end
  else
   -- No mega module: still a banner for the whole island.
   if m:Wait(config.Hold*.55)then m:Banner(config.Title,{Sub=m.VenueText})end
   m:Wait(config.Hold+4)
  end
  scope:Clean()
  task.delay(90,function()if M.Running[uid]==m then M.Running[uid]=nil end end)
 end)
 -- Hard ceiling: a stuck module can never leave the sky dark.
 task.delay(math.max(5,(config.MegaSeconds or 30)-late)+6,function()scope:Clean()end)
 return m
end

return M
