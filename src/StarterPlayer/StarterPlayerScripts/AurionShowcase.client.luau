-- Aurion, the DOG-O-MATIC's 0.01% jackpot, shown all around the machine. Everything here is
-- local to this client (nothing replicates, nothing has to stream):
--  * a hero Aurion hovering over the ultra-rare pedestal on the plaza approach, with the
--    pedestal, its gold border and crown restored locally (not the two stone discs: they
--    would z-fight the procession carpet), a prism of coloured light and its name;
--  * a hologram of the jackpot on the reveal stand while the stand is empty and idle;
--  * the drum's AurionRareSymbol and the tower vitrine's AurionGrandPrize brought to life
--    (Idle loop), the vitrine copy first set down on its plinth, behind the glass.
-- The hero is a Secret display (DogDisplayHooks 'Static'), so SecretAuras dresses it like
-- the built-in copies the server tags. The hologram is a projection and is never tagged.
local RS=game:GetService('ReplicatedStorage');local Run=game:GetService('RunService');local UIS=game:GetService('UserInputService')
local player=game:GetService('Players').LocalPlayer
local Rig=require(RS:WaitForChild('DogRig'));local Animation=require(RS:WaitForChild('DogAnimationPlayer'))
local DogLook=require(RS:WaitForChild('DogLook'));local Hooks=require(RS:WaitForChild('DogDisplayHooks'))
local Arrivals=require(RS:WaitForChild('SecretArrivalConfig'))
local district=workspace:WaitForChild('DOGROTS_District')
local rig=district:WaitForChild('37_AttractionRefresh'):WaitForChild('RewardMachineRig')
local hooks=rig:WaitForChild('CameraHooks')
local COLOR=Arrivals.Dogs.Aurion and Arrivals.Dogs.Aurion.Color or Color3.fromRGB(150,220,255)
local GOLD=Color3.fromRGB(255,206,84);local SPARKLE='rbxasset://textures/particles/sparkles_main.dds'
local folder=Instance.new('Folder');folder.Name='DOGROTS_AurionShowcase';folder.Parent=workspace
local chance='0.01%'
pcall(function()chance=require(RS:WaitForChild('RewardMachineText')).Aurion()end)

-- Low quality (SecretArrivals Kit.Low semantics) drops particles; ReducedMotion also stops
-- the turntables, the bobbing and the colour cycling.
local function low()
 local fx=player:GetAttribute('WorldEventFX')
 return fx=='Low'or player:GetAttribute('LowFX')==true or player:GetAttribute('ReducedMotion')==true or(UIS.TouchEnabled and fx~='High')
end
local function reduced()return player:GetAttribute('ReducedMotion')==true end
local emitters={}
local function quality()local on=not low();for emitter in pairs(emitters)do if emitter.Parent then emitter.Enabled=on else emitters[emitter]=nil end end end
for _,name in ipairs({'WorldEventFX','LowFX','ReducedMotion'})do player:GetAttributeChangedSignal(name):Connect(quality)end

local function part(name,size,cframe)
 local p=Instance.new('Part');p.Name=name;p.Anchored=true;p.CanCollide=false;p.CanTouch=false;p.CanQuery=false;p.CastShadow=false
 p.Size=size;p.CFrame=cframe;p.Transparency=1;p.TopSurface=Enum.SurfaceType.Smooth;p.BottomSurface=Enum.SurfaceType.Smooth
 p.Parent=folder;return p
end
local function sparkles(parent,rate,colors)
 local e=Instance.new('ParticleEmitter');e.Name='AurionSparkles';e.Texture=SPARKLE;e.Rate=rate;e.Lifetime=NumberRange.new(1.4,2.4)
 e.Speed=NumberRange.new(.6,1.6);e.SpreadAngle=Vector2.new(180,180);e.Acceleration=Vector3.new(0,.6,0);e.LightEmission=.8;e.LightInfluence=0
 e.Color=colors;e.Size=NumberSequence.new({NumberSequenceKeypoint.new(0,.32),NumberSequenceKeypoint.new(1,0)})
 e.Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,.1),NumberSequenceKeypoint.new(1,1)});e.Enabled=not low();e.Parent=parent
 emitters[e]=true;return e
end
local RAINBOW=ColorSequence.new({ColorSequenceKeypoint.new(0,Color3.fromHSV(0,.45,1)),ColorSequenceKeypoint.new(.25,Color3.fromHSV(.15,.45,1)),
 ColorSequenceKeypoint.new(.5,Color3.fromHSV(.45,.45,1)),ColorSequenceKeypoint.new(.75,Color3.fromHSV(.62,.45,1)),ColorSequenceKeypoint.new(1,Color3.fromHSV(.8,.45,1))})
local function label(parent,title,subtitle,size,offset,maxDistance)
 local gui=Instance.new('BillboardGui');gui.Name='AurionLabel';gui.Size=size;gui.StudsOffsetWorldSpace=offset;gui.MaxDistance=maxDistance;gui.LightInfluence=0;gui.AlwaysOnTop=false
 local frame=Instance.new('Frame');frame.Size=UDim2.fromScale(1,1);frame.BackgroundColor3=Color3.fromRGB(20,18,52);frame.BackgroundTransparency=.25;frame.BorderSizePixel=0;frame.Parent=gui
 local corner=Instance.new('UICorner');corner.CornerRadius=UDim.new(.22,0);corner.Parent=frame
 local stroke=Instance.new('UIStroke');stroke.Color=GOLD;stroke.Thickness=2;stroke.Parent=frame
 local function text(value,y,h,color)
  local t=Instance.new('TextLabel');t.BackgroundTransparency=1;t.Position=UDim2.fromScale(.04,y);t.Size=UDim2.fromScale(.92,h);t.Font=Enum.Font.FredokaOne
  t.TextScaled=true;t.Text=value;t.TextColor3=color;t.TextStrokeTransparency=.4;t.Parent=frame
 end
 text(title,.06,.52,GOLD);text(subtitle,.58,.34,Color3.new(1,1,1))
 gui.Parent=parent;return gui
end
-- A display-only Aurion from the UI model library (no scripts, prompts, sounds or emitters).
local function copyAurion()
 local models=RS:WaitForChild('MenuModels',30);local source=models and models:WaitForChild('Aurion',30)
 if not source or not source:IsA('Model')then warn('[AurionShowcase] ReplicatedStorage.MenuModels.Aurion is missing');return nil end
 local m=source:Clone()
 for _,o in ipairs(m:GetDescendants())do
  if o:IsA('LuaSourceContainer')or o:IsA('ProximityPrompt')or o:IsA('Sound')or o:IsA('BillboardGui')or o:IsA('SurfaceGui')or o:IsA('ParticleEmitter')then o:Destroy()end
 end
 return m
end
local function flat(v)local f=Vector3.new(v.X,0,v.Z);return f.Magnitude>1e-3 and f.Unit or Vector3.new(0,0,-1)end
local function yawOf(direction)return math.atan2(-direction.X,-direction.Z)end

-- Every animated Aurion. Update(now, dt, distance) runs each frame before the bone step;
-- Hidden skips the step. Bones step every frame up close, less often far away. A model
-- whose Idle clip cannot load still gets its Update (it just stands still).
local entries={}
local function track(model,update)
 local ok,animation=pcall(Animation.new,model,'Aurion')
 if not ok or not animation or not animation:Play('Idle',{Looped=true,StartTime=workspace:GetServerTimeNow()-math.random()*3})then animation=nil end
 local entry={Model=model,Player=animation,State={},Phase=math.random(0,7),Update=update,Hidden=false}
 entries[model]=entry
 model.Destroying:Connect(function()if entries[model]==entry then entries[model]=nil;if animation then pcall(function()animation:Destroy()end)end end end)
 return entry
end
local frame=0
-- Stepped just after SecretArrivals/Stare (it binds at Camera-1 and turns the vitrine copy's
-- head as a "static" dog): this pose, Idle plus the same head turn, is the one rendered.
-- While a stare runs every copy steps each frame, so Stare's own writes never show.
Run:BindToRenderStep('DOGROTS_AurionShowcase',Enum.RenderPriority.Camera.Value,function(dt)
 frame+=1
 local now=workspace:GetServerTimeNow();local camera=workspace.CurrentCamera;local origin=camera and camera.CFrame.Position
 for model,entry in pairs(entries)do
  if not model.Parent then entries[model]=nil;continue end
  local at=model:GetPivot().Position;local distance=origin and(at-origin).Magnitude or 0
  if entry.Update then local ok,err=pcall(entry.Update,now,dt,distance);if not ok then warn('[AurionShowcase]',err);entry.Update=nil end end
  local animation=entry.Player
  if entry.Hidden or not animation or distance>520 then continue end
  local interval=distance>320 and 8 or distance>160 and 3 or 1
  -- THE DOG's stare (DogLook): the head turns with every other dog; the body stays put.
  local body,head,target,bow
  if DogLook.Current then body,head,target,bow=DogLook.For(model,entry.State,at,false)end
  if body then
   local look=entry.Look or{};look.Target,look.Body,look.Head,look.Bow=target,0,head,bow;entry.Look=look;animation.Look=look
   interval=1
  elseif animation.Look then animation.Look=nil;interval=1 end
  if interval==1 or(frame+entry.Phase)%interval==0 then animation:Step(now)end
 end
end)

-- World axis-aligned box of some parts (any rotation).
local function box(parts)
 local lo,hi=Vector3.one*math.huge,-Vector3.one*math.huge
 for _,p in ipairs(parts)do
  local cf,s=p.CFrame,p.Size;local r,u,l=cf.RightVector,cf.UpVector,cf.LookVector
  local half=Vector3.new(math.abs(r.X)*s.X+math.abs(u.X)*s.Y+math.abs(l.X)*s.Z,math.abs(r.Y)*s.X+math.abs(u.Y)*s.Y+math.abs(l.Y)*s.Z,math.abs(r.Z)*s.X+math.abs(u.Z)*s.Y+math.abs(l.Z)*s.Z)/2
  lo=lo:Min(cf.Position-half);hi=hi:Max(cf.Position+half)
 end
 return lo,hi
end
local function visible(model)
 local list={}
 for _,p in ipairs(model:GetDescendants())do if p:IsA('BasePart')and p.Transparency<1 and p.Name~='RootPart'then table.insert(list,p)end end
 return list
end

-- 1. The hero over the ultra-rare pedestal (plaza approach, beside the carpet).
local COURT_PARTS={PedestalStep=true,PedestalBase=true,PedestalShadow=true,PedestalCap=true,InnerBorder=true}
local function restore(p,crown)
 if not p:IsA('BasePart')or not(crown or COURT_PARTS[p.Name])then return end
 local t=p:GetAttribute('AttractionRefresh_Transparency');if type(t)~='number'then return end
 local function flag(key,default)local v=p:GetAttribute('AttractionRefresh_'..key);if type(v)=='boolean'then return v end;return default end
 p.Transparency=t;p.CanCollide=flag('CanCollide',p.CanCollide);p.CanQuery=flag('CanQuery',p.CanQuery)
 p.CanTouch=flag('CanTouch',p.CanTouch);p.CastShadow=flag('CastShadow',p.CastShadow)
end
-- WaitForChild without the infinite-yield warning: the court's parts stream in on their own time.
local function child(parent,name)
 while parent.Parent do
  local found=parent:WaitForChild(name,30)
  if found then return found end
 end
 return nil
end
local function buildHero()
 local plaza=child(district,'27_RewardMachinePlaza');local forecourt=plaza and child(plaza,'Forecourt')
 local court=forecourt and child(forecourt,'RareRewardCourt');if not court then return end
 local crown=court:WaitForChild('UltraRareCrown',15)
 local function restoreAll()
  for _,o in ipairs(court:GetDescendants())do restore(o,o:FindFirstAncestor('UltraRareCrown')~=nil)end
 end
 restoreAll()
 -- Parts stream in (and back in) on their own; restore each one as it arrives.
 court.DescendantAdded:Connect(function(o)task.defer(function()if o.Parent then restore(o,o:FindFirstAncestor('UltraRareCrown')~=nil)end end)end)
 local cap=child(court,'PedestalCap');if not cap or not cap:IsA('BasePart')then return end
 local base=Vector3.new(cap.Position.X,cap.Position.Y+cap.Size.Y/2,cap.Position.Z)
 -- The crown streams with the pedestal; give its jewels a moment to arrive with it.
 if crown then crown:WaitForChild('CrownJewel',10);task.wait(.5)end
 -- Hover just above the crown's jewels (8.5 studs up is the authored crown's top).
 local top=base.Y+5.3;local jewels={}
 for _,p in ipairs(crown and crown:GetDescendants()or{})do
  if p:IsA('BasePart')then local _,hi=box({p});top=math.max(top,hi.Y);if p.Name=='CrownJewel'then table.insert(jewels,p.Position+Vector3.new(0,p.Size.Y/2,0))end end
 end
 local m=copyAurion();if not m then return end
 if not Rig.Prepare(m,Vector3.new(12,9,12))then m:Destroy();return end
 local hover=Vector3.new(base.X,top+1.1,base.Z)
 -- Facing the procession carpet players walk in on (when the turntable is still).
 local yaw0=yawOf(flat(Vector3.new(-40,0,630)-hover))
 m.Name='AurionHero';Rig.Place(m,hover,CFrame.Angles(0,yaw0,0))
 Hooks.Prepared(m,'Aurion','Static')
 m.Parent=folder
 local ground=m:GetAttribute('GroundLocal')or Vector3.zero
 local height=(m:GetAttribute('VisualSize')or Vector3.new(4,8,12)).Y
 -- A prism: one coloured ray from every crown jewel converging on the dog's heart.
 local anchor=part('AurionHeroLight',Vector3.new(.2,.2,.2),CFrame.new(hover+Vector3.new(0,height*.45,0)))
 local heart=Instance.new('Attachment');heart.Name='Heart';heart.Parent=anchor
 local light=Instance.new('PointLight');light.Color=COLOR;light.Range=18;light.Brightness=1.8;light.Shadows=false;light.Parent=anchor
 sparkles(heart,5,RAINBOW)
 -- The rays start on our own attachments, so a jewel streaming out later changes nothing.
 for i,at in ipairs(jewels)do
  local foot=Instance.new('Attachment');foot.Name='Jewel'..i;foot.Parent=anchor
  foot.Position=anchor.CFrame:PointToObjectSpace(at)
  local hue=Color3.fromHSV((i-1)/#jewels,.55,1)
  local beam=Instance.new('Beam');beam.Attachment0=foot;beam.Attachment1=heart;beam.FaceCamera=true;beam.Segments=1
  beam.Width0=.45;beam.Width1=.1;beam.LightEmission=1;beam.LightInfluence=0;beam.Color=ColorSequence.new(hue,Color3.new(1,1,1))
  beam.Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,.25),NumberSequenceKeypoint.new(1,.75)});beam.Parent=anchor
 end
 -- The name plaque stands at the pedestal's foot on the carpet side (+Z): above the dog
 -- SecretAuras already floats its "SECRET" nameplate.
 local reach=4.5
 for _,name in ipairs({'PedestalStep','PedestalBase','PedestalCap'})do
  local p=court:FindFirstChild(name)
  if p and p:IsA('BasePart')then local lo,hi=box({p});reach=math.max(reach,hi.Z-base.Z,base.Z-lo.Z)end
 end
 local tag=part('AurionHeroLabel',Vector3.new(.2,.2,.2),CFrame.new(base.X,base.Y+1.6,base.Z+reach+1.2))
 label(tag,'AURION',chance..' · DOG-O-MATIC JACKPOT',UDim2.fromScale(12,2.9),Vector3.zero,170)
 local heartRest=heart.Position
 track(m,function(_,_,distance)
  if distance>300 then return end
  local t=os.clock();local still=reduced()
  local bob=still and 0 or math.sin(t*math.pi*2/5)*.35
  -- A slow turntable: one turn every 36 seconds.
  m:PivotTo(CFrame.new(hover+Vector3.new(0,bob,0))*CFrame.Angles(0,still and yaw0 or yaw0+t*math.pi*2/36,0)*CFrame.new(-ground))
  heart.Position=heartRest+Vector3.new(0,bob,0)
  light.Color=still and COLOR or Color3.fromHSV((t/12)%1,.35,1)
 end)
end

-- 2. The jackpot's hologram on the reveal stand, where a won Aurion would arrive. Shown
-- while no prize stands there and the drum is idle; it fades out as a spin starts.
local function buildHologram()
 local spawn=hooks:WaitForChild('RewardSpawn')
 local m=copyAurion();if not m then return end
 -- The real prize's size on this stand (SecretReveal.Show fits it to 10 x 6 x 10).
 if not Rig.Prepare(m,Vector3.new(10,6,10))then m:Destroy();return end
 local shell={}
 for _,o in ipairs(m:GetDescendants())do
  if o:IsA('SurfaceAppearance')or o:IsA('Decal')or o:IsA('Texture')then o:Destroy()
  elseif o:IsA('BasePart')then
   o.CastShadow=false
   if o.Name~='RootPart'then
    if o:IsA('MeshPart')then o.TextureID=''end
    o.Material=Enum.Material.ForceField;o.Color=COLOR;o.Transparency=1;table.insert(shell,o)
   end
  end
 end
 local ground=m:GetAttribute('GroundLocal')or Vector3.zero
 local stand=spawn.Position;local yaw0=yawOf(Vector3.new(1,0,0))
 m.Name='AurionHologram';Rig.Place(m,stand,CFrame.Angles(0,yaw0,0));m.Parent=folder
 local height=(m:GetAttribute('VisualSize')or Vector3.new(3,6,9)).Y
 local disc=part('AurionHologramProjector',Vector3.new(.05,9.5,9.5),CFrame.new(stand+Vector3.new(0,.02,0))*CFrame.Angles(0,0,math.pi/2))
 disc.Shape=Enum.PartType.Cylinder;disc.Material=Enum.Material.Neon;disc.Color=COLOR
 local light=Instance.new('PointLight');light.Color=COLOR;light.Range=12;light.Brightness=0;light.Shadows=false;light.Parent=disc
 local glow=Instance.new('Attachment');glow.Parent=disc
 local motes=sparkles(glow,4,ColorSequence.new(COLOR,Color3.new(1,1,1)))
 motes.Speed=NumberRange.new(1,2.2);motes.Acceleration=Vector3.new(0,1.2,0);motes.SpreadAngle=Vector2.new(25,25);motes.EmissionDirection=Enum.NormalId.Right
 local tag=part('AurionHologramLabel',Vector3.new(.2,.2,.2),CFrame.new(stand+Vector3.new(0,height+2.2,0)))
 local sign=label(tag,'JACKPOT · AURION',chance..' · WIN IT AT DOG-O-MATIC',UDim2.fromScale(10,2.4),Vector3.zero,110);sign.Enabled=false
 local alpha,shown=0,-1
 local function wanted()
  if rig:FindFirstChild('CommittedPrize')or rig:GetAttribute('Spinning')==true then return false end
  -- This client's own activation starts the drum before the server says so.
  local pending=tonumber(player:GetAttribute('RewardMachinePendingAt'))or 0
  return not(pending>0 and workspace:GetServerTimeNow()-pending<3)
 end
 local entry;entry=track(m,function(_,dt,distance)
  alpha=math.clamp(alpha+(wanted()and dt or -dt)/.45,0,1)
  if alpha~=shown then
   shown=alpha
   for _,p in ipairs(shell)do p.Transparency=1-alpha*.95 end
   disc.Transparency=1-alpha*.4;light.Brightness=1.2*alpha;sign.Enabled=alpha>.5
   motes.Enabled=alpha>.5 and not low()
  end
  entry.Hidden=alpha<=0
  if alpha<=0 or distance>300 then return end
  local t=os.clock();local still=reduced()
  local bob=still and 0 or math.sin(t*math.pi*2/4)*.2
  m:PivotTo(CFrame.new(stand+Vector3.new(0,.25+bob,0))*CFrame.Angles(0,still and yaw0 or yaw0+t*math.pi*2/30,0)*CFrame.new(-ground))
 end)
 -- quality() must not switch the motes on while the hologram is hidden.
 emitters[motes]=nil
 player:GetAttributeChangedSignal('WorldEventFX'):Connect(function()shown=-1 end)
 for _,name in ipairs({'LowFX','ReducedMotion'})do player:GetAttributeChangedSignal(name):Connect(function()shown=-1 end)end
end

-- 3. The built-in copies: the drum's sector symbol and the TreasureTower vitrine.
local function find(name)
 for _=1,60 do
  local model=rig:FindFirstChild(name,true)
  if model and model:IsA('Model')then return model end
  task.wait(1)
 end
 return nil
end
-- The vitrine copy floated 2.8 studs over its plinth with its snout through the glass. Set it
-- on the plinth, looking out toward the reveal stand, shrunk only as much as the case needs.
local function settle(model)
 local tower=model.Parent;local plinth=tower and tower:FindFirstChild('AurionDisplayPlinth')
 local parts=visible(model)
 if not plinth or not plinth:IsA('BasePart')or #parts==0 then return end
 local plo,phi=box({plinth});local floor=phi.Y
 local x0,x1,z0,z1,y1=plo.X,phi.X,plo.Z,phi.Z,floor+10
 for _,p in ipairs(tower:GetChildren())do
  if p:IsA('BasePart')then
   local lo,hi=box({p})
   if p.Name=='ClearVitrine'and lo.Y<floor+2 and hi.Y>floor+2 then x1=math.min(x1,lo.X-.35);y1=math.min(y1,hi.Y-.3)
   elseif p.Name=='TowerInset'and lo.Y<floor+2 and hi.Y>floor+2 then x0=math.max(x0,hi.X+.3)
   elseif p.Name=='AurionPrism'then
    if (lo.Z+hi.Z)/2<(plo.Z+phi.Z)/2 then z0=math.max(z0,hi.Z+.3)else z1=math.min(z1,lo.Z-.3)end
   end
  end
 end
 if x1-x0<1 or z1-z0<1 then x0,x1,z0,z1=plo.X,phi.X,plo.Z,phi.Z end
 local lo,hi=box(parts);local middle=(lo+hi)/2
 local head=model:FindFirstChild('Aurion_Head',true)
 local facing=head and head:IsA('BasePart')and flat(head.Position-middle)or flat(model:GetPivot().LookVector)
 local spawn=hooks:FindFirstChild('RewardSpawn')
 local want=spawn and flat(spawn.Position-middle)or Vector3.new(1,0,0)
 local turn=math.atan2(facing:Cross(want).Y,facing:Dot(want))
 model:PivotTo(CFrame.new(middle)*CFrame.Angles(0,turn,0)*CFrame.new(-middle)*model:GetPivot())
 lo,hi=box(parts);local size=hi-lo
 local scale=math.min(1,(x1-x0)/size.X,(z1-z0)/size.Z,(y1-floor)/size.Y)*.97
 if scale<.999 then model:ScaleTo(model:GetScale()*scale);lo,hi=box(parts)end
 middle=(lo+hi)/2
 model:PivotTo(CFrame.new((x0+x1)/2-middle.X,floor+.02-lo.Y,(z0+z1)/2-middle.Z)*model:GetPivot())
 -- Keep the look (Stare, DogLook) turning it about its real feet.
 local blo,bhi=Rig.Bounds(model)
 if blo then model:SetAttribute('GroundLocal',Vector3.new((blo.X+bhi.X)/2,blo.Y,(blo.Z+bhi.Z)/2));model:SetAttribute('VisualSize',bhi-blo)end
 model:SetAttribute('ShowcaseSettled',true)
end
-- The prism pillars beside both copies cycle through the spectrum.
local glows={}
local function glow(p,offset)if p:IsA('BasePart')then table.insert(glows,{Part=p,Color=p.Color,Offset=offset})end end
local lastGlow=0
Run.Heartbeat:Connect(function()
 local t=os.clock();if t-lastGlow<.1 or #glows==0 then return end;lastGlow=t
 local still=reduced()
 for _,g in ipairs(glows)do if g.Part.Parent then g.Part.Color=still and g.Color or Color3.fromHSV((t/10+g.Offset)%1,.5,1)end end
end)
task.spawn(function()
 local prize=find('AurionGrandPrize')
 if prize then
  local ok,err=pcall(settle,prize);if not ok then warn('[AurionShowcase] vitrine:',err)end
  track(prize)
  for i,p in ipairs(prize.Parent and prize.Parent:GetChildren()or{})do if p.Name=='AurionPrism'then glow(p,i*.17)end end
 end
end)
task.spawn(function()
 local symbol=find('AurionRareSymbol')
 if symbol then
  track(symbol)
  for i,p in ipairs(symbol.Parent and symbol.Parent:GetChildren()or{})do if p.Name=='PrismFlank'then glow(p,.5+i*.17)end end
 end
end)
task.spawn(function()local ok,err=pcall(buildHero);if not ok then warn('[AurionShowcase] hero:',err)end end)
task.spawn(function()local ok,err=pcall(buildHologram);if not ok then warn('[AurionShowcase] hologram:',err)end end)
