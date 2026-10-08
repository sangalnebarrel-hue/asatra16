-- The playable side of world events, drawn on every client (the server applies gravity,
-- movement, the tongue and rewards: ServerScriptService.WorldEventGameplay). Per the active
-- event's Perks.Effects: flashlights in the BLACKOUT, UFO tractor beams that really lift you
-- in low gravity, EARTHQUAKE jolts, trails behind every player, DOG RUSH speed lines and
-- NULL HOUR glitches. Also celebrates server luck (Lucky Server products) for everyone.
local Players=game:GetService('Players')
local RS=game:GetService('ReplicatedStorage')
local Run=game:GetService('RunService')
local Tween=game:GetService('TweenService')
local TextChat=game:GetService('TextChatService')
local package=RS:WaitForChild('WorldEvents')
local Definitions=require(package:WaitForChild('WorldEventDefinitions'))
local stateFolder=package:WaitForChild('State')
local player=Players.LocalPlayer
local C=Color3.fromRGB
local rng=Random.new()
local active -- {Def, Generation, Folder, Connections, Cleanups}

local function reduced()return player:GetAttribute('ReducedMotion')==true end
local function low()return player:GetAttribute('WorldEventFX')=='Low'end
local function part(props,parent)
 local p=Instance.new('Part');p.Anchored=true;p.CanCollide=false;p.CanTouch=false;p.CanQuery=false;p.CastShadow=false
 p.Material=Enum.Material.Neon;p.TopSurface=Enum.SurfaceType.Smooth;p.BottomSurface=Enum.SurfaceType.Smooth
 for k,v in pairs(props)do (p::any)[k]=v end
 p.Parent=parent;return p
end
local function screen()
 local gui=player:WaitForChild('PlayerGui'):FindFirstChild('DOGROTS_EventGameplay')
 if not gui then gui=Instance.new('ScreenGui');gui.Name='DOGROTS_EventGameplay';gui.ResetOnSpawn=false;gui.IgnoreGuiInset=true;gui.DisplayOrder=90;gui.Parent=player.PlayerGui end
 return gui
end
local function rootOf(character)return character and character:FindFirstChild('HumanoidRootPart')end
local function grounded(character)
 local hum=character and character:FindFirstChildOfClass('Humanoid')
 return hum and hum.FloorMaterial~=Enum.Material.Air
end
local shakeUntil,shakePower=0,0
Run:BindToRenderStep('DOGROTS_EventGameplayShake',Enum.RenderPriority.Camera.Value+3,function()
 local now=os.clock();if now>shakeUntil or reduced()then return end
 local c=workspace.CurrentCamera;if not c or c.CameraType==Enum.CameraType.Scriptable then return end
 local g=math.min(shakeUntil-now,1)*shakePower
 c.CFrame*=CFrame.new(math.noise(now*19)*g,math.noise(0,now*23)*g,0)*CFrame.Angles(0,0,math.noise(now*13,2)*g*.03)
end)
local function shake(power,seconds)shakeUntil=math.max(shakeUntil,os.clock()+seconds);shakePower=math.max(shakePower*.5,power)end

---------------------------------------------------------------- per-character effects
local function eachCharacter(fn)
 local seen={}
 local function bind(p)
  local function apply(character)if character then task.defer(fn,p,character)end end
  table.insert(active.Connections,p.CharacterAdded:Connect(apply))
  apply(p.Character)
 end
 for _,p in ipairs(Players:GetPlayers())do bind(p);seen[p]=true end
 table.insert(active.Connections,Players.PlayerAdded:Connect(bind))
end
-- Deferred per character: the event may have ended (or another begun) before it runs, and a
-- freshly spawned or streamed character may not have its parts yet.
local function trail(p,character,color)
 local mine=active;if not mine then return end
 local root=character:WaitForChild('HumanoidRootPart',5)
 if active~=mine or not root or root:FindFirstChild('DOGROTS_EventTrail')then return end
 local a0=Instance.new('Attachment');a0.Name='DOGROTS_EventTrailTop';a0.Position=Vector3.new(0,1.2,0);a0.Parent=root
 local a1=Instance.new('Attachment');a1.Name='DOGROTS_EventTrailBottom';a1.Position=Vector3.new(0,-1.6,0);a1.Parent=root
 local t=Instance.new('Trail');t.Name='DOGROTS_EventTrail';t.Attachment0=a0;t.Attachment1=a1;t.Lifetime=.55;t.LightEmission=.8;t.FaceCamera=true
 t.MinLength=.2;t.WidthScale=NumberSequence.new(1,0);t.Transparency=NumberSequence.new(.25,1)
 t.Color=color;t.Parent=root
 table.insert(active.Cleanups,function()t:Destroy();a0:Destroy();a1:Destroy()end)
end
local function flashlight(p,character)
 local mine=active;if not mine then return end
 local head=character:WaitForChild('Head',5)or rootOf(character)
 if active~=mine or not head or head:FindFirstChild('DOGROTS_Flashlight')then return end
 local s=Instance.new('SpotLight');s.Name='DOGROTS_Flashlight';s.Face=Enum.NormalId.Front;s.Angle=55;s.Range=58;s.Brightness=p==player and 3.2 or 2
 s.Color=C(255,244,214);s.Shadows=p==player;s.Parent=head
 local glow=Instance.new('PointLight');glow.Name='DOGROTS_FlashlightGlow';glow.Range=10;glow.Brightness=.6;glow.Color=C(200,220,255);glow.Shadows=false;glow.Parent=head
 table.insert(active.Cleanups,function()s:Destroy();glow:Destroy()end)
end

---------------------------------------------------------------- set pieces
local function tractorBeams(def)
 -- Beams sweep down near you; stand in one and the saucer lifts you (you own your character).
 local color=def.ColorTheme
 local nextBeam=os.clock()+3
 local beams={}
 table.insert(active.Connections,Run.Heartbeat:Connect(function(dt)
  local root=rootOf(player.Character)
  if os.clock()>=nextBeam and root then
   nextBeam=os.clock()+rng:NextNumber(7,12)
   local a=rng:NextNumber(0,math.pi*2);local r=rng:NextNumber(6,26)
   local at=root.Position+Vector3.new(math.cos(a)*r,0,math.sin(a)*r)
   local beam=part({Name='TractorBeam',Shape=Enum.PartType.Cylinder,Color=color,Material=Enum.Material.ForceField,Transparency=1,
    Size=Vector3.new(240,1,1),CFrame=CFrame.new(at+Vector3.new(0,100,0))*CFrame.Angles(0,0,math.pi/2)},active.Folder)
   local core=part({Name='TractorCore',Shape=Enum.PartType.Cylinder,Color=color,Transparency=1,Size=Vector3.new(240,1,1),CFrame=beam.CFrame},active.Folder)
   table.insert(beams,{Beam=beam,Core=core,At=at,Born=os.clock(),Life=6,Radius=9})
  end
  for i=#beams,1,-1 do
   local b=beams[i];local age=os.clock()-b.Born
   local s=math.min(age/.6,1)*math.min((b.Life-age)/.6,1)
   if s<=0 and age>1 then b.Beam:Destroy();b.Core:Destroy();table.remove(beams,i)
   else
    s=math.max(s,0)
    b.Beam.Size=Vector3.new(240,b.Radius*2*s+.1,b.Radius*2*s+.1);b.Beam.Transparency=1-.55*s
    b.Core.Size=Vector3.new(240,b.Radius*.5*s+.05,b.Radius*.5*s+.05);b.Core.Transparency=1-.5*s
    if root and s>.5 then
     local d=Vector3.new(root.Position.X-b.At.X,0,root.Position.Z-b.At.Z).Magnitude
     if d<b.Radius then
      local v=root.AssemblyLinearVelocity
      root.AssemblyLinearVelocity=Vector3.new(v.X,math.max(v.Y,14),v.Z)
     end
    end
   end
  end
 end))
 table.insert(active.Cleanups,function()for _,b in ipairs(beams)do b.Beam:Destroy();b.Core:Destroy()end end)
end
local function quakes(def)
 local nextQuake=os.clock()+6
 table.insert(active.Connections,Run.Heartbeat:Connect(function()
  if os.clock()<nextQuake then return end
  nextQuake=os.clock()+rng:NextNumber(18,28)
  shake(.9,1.6)
  local character=player.Character;local root=rootOf(character)
  if root and grounded(character)and not reduced()then
   local v=root.AssemblyLinearVelocity
   root.AssemblyLinearVelocity=v+Vector3.new(rng:NextNumber(-6,6),32,rng:NextNumber(-6,6))
  end
  if root then
   local dust=part({Name='QuakeDust',Size=Vector3.one,Transparency=1,Position=root.Position-Vector3.new(0,3,0)},active.Folder)
   local e=Instance.new('ParticleEmitter');e.Texture='rbxasset://textures/particles/smoke_main.dds';e.Color=ColorSequence.new(def.ColorTheme:Lerp(C(120,96,72),.6))
   e.Size=NumberSequence.new(4,12);e.Transparency=NumberSequence.new(.5,1);e.Lifetime=NumberRange.new(1,2);e.Speed=NumberRange.new(10,24)
   e.SpreadAngle=Vector2.new(80,10);e.Rate=0;e.Parent=dust;e:Emit(low()and 10 or 30)
   task.delay(3,function()dust:Destroy()end)
  end
 end))
end
local function speedLines()
 local gui=screen()
 local frame=Instance.new('Frame');frame.Name='Zoomies';frame.BackgroundTransparency=1;frame.Size=UDim2.fromScale(1,1);frame.Parent=gui
 local lines={}
 for i=1,(low()and 8 or 18)do
  local l=Instance.new('Frame');l.BorderSizePixel=0;l.BackgroundColor3=Color3.new(1,1,1);l.BackgroundTransparency=1;l.AnchorPoint=Vector2.new(.5,.5);l.Parent=frame
  lines[i]={Frame=l,Angle=rng:NextNumber(0,math.pi*2),Phase=rng:NextNumber()}
 end
 table.insert(active.Cleanups,function()frame:Destroy()end)
 table.insert(active.Connections,Run.RenderStepped:Connect(function()
  local hum=player.Character and player.Character:FindFirstChildOfClass('Humanoid')
  local speed=hum and hum.MoveDirection.Magnitude>.1 and hum.WalkSpeed or 0
  local k=math.clamp((speed-24)/16,0,1)*(reduced()and 0 or 1)
  for _,l in ipairs(lines)do
   l.Phase=(l.Phase+.04)%1
   local r=.42+.12*l.Phase
   l.Frame.Position=UDim2.fromScale(.5+math.cos(l.Angle)*r,.5+math.sin(l.Angle)*r)
   l.Frame.Size=UDim2.fromOffset(3,60+80*l.Phase);l.Frame.Rotation=math.deg(l.Angle)+90
   l.Frame.BackgroundTransparency=1-k*.45*(1-l.Phase)
  end
 end))
end
local function glitches()
 local gui=screen()
 local lastGravity=workspace.Gravity
 table.insert(active.Connections,workspace:GetPropertyChangedSignal('Gravity'):Connect(function()
  local g=workspace.Gravity
  if math.abs(g-lastGravity)<1 then return end
  lastGravity=g
  if reduced()then return end
  for i=1,3 do
   local bar=Instance.new('Frame');bar.BorderSizePixel=0;bar.BackgroundColor3=i==1 and C(255,40,70)or i==2 and C(40,230,255)or Color3.new(1,1,1)
   bar.BackgroundTransparency=.55;bar.Size=UDim2.new(1,0,0,rng:NextInteger(6,40));bar.Position=UDim2.fromScale(0,rng:NextNumber(0,.95));bar.Parent=gui
   task.delay(.08+i*.04,function()bar:Destroy()end)
  end
  local text=Instance.new('TextLabel');text:SetAttribute('KeepFont',true);text.BackgroundTransparency=1;text.Font=Enum.Font.Code
  text.Text=g<100 and'[ GRAVITY = '..string.format('%.0f',g)..' ]'or'[ GRAVITY RESTORED ]';text.TextColor3=C(220,210,240);text.TextScaled=true
  text.Size=UDim2.fromScale(.5,.05);text.Position=UDim2.fromScale(.25,.18);text.Parent=gui
  Tween:Create(text,TweenInfo.new(1.2),{TextTransparency=1}).Completed:Connect(function()text:Destroy()end)
  shake(.25,.3)
 end))
end

---------------------------------------------------------------- lifecycle
local function stop()
 if not active then return end
 for _,c in ipairs(active.Connections)do c:Disconnect()end
 for _,fn in ipairs(active.Cleanups)do pcall(fn)end
 active.Folder:Destroy()
 active=nil
end
local function start(def,generation)
 stop()
 local folder=Instance.new('Folder');folder.Name='DOGROTS_EventGameplayFX';folder.Parent=workspace
 active={Def=def,Generation=generation,Folder=folder,Connections={},Cleanups={}}
 local effects=(def.Perks or {}).Effects or {}
 if effects.Flashlight then eachCharacter(flashlight)end
 if effects.Trail then
  local color=def.Id=='RAINBOW_RIFT'and ColorSequence.new({ColorSequenceKeypoint.new(0,C(255,80,80)),ColorSequenceKeypoint.new(.25,C(255,220,60)),
   ColorSequenceKeypoint.new(.5,C(80,255,120)),ColorSequenceKeypoint.new(.75,C(80,170,255)),ColorSequenceKeypoint.new(1,C(220,90,255))})
   or ColorSequence.new(def.ColorTheme,Color3.new(1,1,1))
  eachCharacter(function(p,character)trail(p,character,color)end)
 end
 if effects.Tractor then tractorBeams(def)end
 if effects.Quakes then quakes(def)end
 if effects.Zoomies then speedLines()end
 if effects.Glitch then glitches()end
end
local function sync()
 local phase=stateFolder:GetAttribute('State');local def=Definitions.ById[stateFolder:GetAttribute('EventId')or'']
 local generation=stateFolder:GetAttribute('Generation')
 if phase=='ACTIVE'and def then
  if not active or active.Generation~=generation then start(def,generation)end
 else stop()end
end
stateFolder:GetAttributeChangedSignal('Revision'):Connect(sync)
sync()

---------------------------------------------------------------- server luck celebration
task.spawn(function()
 local state=RS:WaitForChild('ServerLuckState',60);if not state then return end
 local seen=state:GetAttribute('Seq')
 state:GetAttributeChangedSignal('Seq'):Connect(function()
  local seq=state:GetAttribute('Seq');if seq==seen then return end;seen=seq
  local added=state:GetAttribute('LastSeconds')or 0;if added<=0 then return end
  local mult=state:GetAttribute('LastMultiplier')or 2;local by=state:GetAttribute('LastBy')or''
  local gui=screen()
  local holder=Instance.new('Frame');holder.BackgroundTransparency=1;holder.AnchorPoint=Vector2.new(.5,.5);holder.Position=UDim2.fromScale(.5,.32)
  holder.Size=UDim2.new(.8,0,0,120);holder.Parent=gui
  local scale=Instance.new('UIScale');scale.Scale=reduced()and 1 or 1.8;scale.Parent=holder
  local title=Instance.new('TextLabel');title:SetAttribute('KeepFont',true);title.BackgroundTransparency=1;title.Font=Enum.Font.FredokaOne
  title.Text='x'..mult..' SERVER LUCK!';title.TextColor3=C(120,255,120);title.TextScaled=true;title.Size=UDim2.new(1,0,0,80);title.Parent=holder
  local stroke=Instance.new('UIStroke');stroke.Thickness=4;stroke.Color=C(10,40,10);stroke.Parent=title
  local g=Instance.new('UIGradient');g.Color=ColorSequence.new({ColorSequenceKeypoint.new(0,C(120,255,120)),ColorSequenceKeypoint.new(.5,C(255,240,120)),ColorSequenceKeypoint.new(1,C(120,255,200))});g.Parent=title
  local sub=Instance.new('TextLabel');sub:SetAttribute('KeepFont',true);sub.BackgroundTransparency=1;sub.Font=Enum.Font.FredokaOne
  sub.Text=(by~=''and('THANKS TO '..string.upper(by)..'  ·  ')or'')..'RARER DOGS ON THE TONGUE FOR EVERYONE · '..math.floor(added/60)..' MIN';sub.TextColor3=Color3.new(1,1,1)
  sub.TextScaled=true;sub.Size=UDim2.new(1,0,0,30);sub.Position=UDim2.new(0,0,0,84);sub.Parent=holder
  local subStroke=Instance.new('UIStroke');subStroke.Thickness=2;subStroke.Color=C(10,30,10);subStroke.Parent=sub
  Tween:Create(scale,TweenInfo.new(.5,Enum.EasingStyle.Back),{Scale=1}):Play()
  local started=os.clock()
  local con;con=Run.RenderStepped:Connect(function()
   local age=os.clock()-started;g.Offset=Vector2.new(math.sin(age*2)*.5,0)
   if age>4.5 then
    con:Disconnect()
    for _,o in ipairs({title,sub})do Tween:Create(o,TweenInfo.new(.8),{TextTransparency=1}):Play()end
    for _,o in ipairs({stroke,subStroke})do Tween:Create(o,TweenInfo.new(.8),{Transparency=1}):Play()end
    task.delay(.9,function()holder:Destroy()end)
   end
  end)
  -- Clover confetti around this player.
  local root=rootOf(player.Character)
  if root and not low()then
   local anchor=part({Name='LuckConfetti',Size=Vector3.one,Transparency=1,Position=root.Position+Vector3.new(0,14,0)},workspace)
   local e=Instance.new('ParticleEmitter');e.Texture='rbxasset://textures/particles/sparkles_main.dds';e.LightEmission=1
   e.Color=ColorSequence.new(C(120,255,120),C(255,240,120));e.Size=NumberSequence.new(1.2,0);e.Lifetime=NumberRange.new(1.5,3)
   e.Speed=NumberRange.new(14,34);e.SpreadAngle=Vector2.new(180,180);e.Acceleration=Vector3.new(0,-18,0);e.Rate=0;e.Parent=anchor;e:Emit(70)
   task.delay(4,function()anchor:Destroy()end)
  end
  pcall(function()
   local general=TextChat:FindFirstChild('TextChannels')and TextChat.TextChannels:FindFirstChild('RBXGeneral')
   if general then general:DisplaySystemMessage(string.format('<font color="#78FF78"><b>✦ %s activated x%d SERVER LUCK! Rarer dogs for everyone for %d min.</b></font>',by~=''and by or'Someone',mult,math.floor(added/60)))end
  end)
 end)
end)
print('DOGROTS_WORLD_EVENT_GAMEPLAY_FX_READY')
