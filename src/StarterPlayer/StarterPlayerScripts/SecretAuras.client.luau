-- Persistent "super rare" VFX on every Secret dog wherever it is shown: the tongue,
-- kennels, yard showcases and trophies, reveals, the DOG-O-MATIC, the museum. Every model
-- tagged DOGROTS_SecretDog (ReplicatedStorage/DogDisplayHooks) gets an Aura: a "✦ SECRET ✦"
-- nameplate, a pulsing ground ring, a sky beacon for the nearest few, and its own look
-- (SecretAuras/Styles). Everything is local to this client.
-- Budgets (SecretAuraConfig): full aura near the camera, reduced further out, beacon only
-- beyond; one particle rate budget shared nearest first; lights for the nearest 4,
-- Highlights for the nearest 2, beacons for the nearest 6, none of those on Low. A pass
-- runs every .25 s; only near auras (and fades) are touched every frame.
local Players=game:GetService('Players')
local RS=game:GetService('ReplicatedStorage')
local Run=game:GetService('RunService')
local CS=game:GetService('CollectionService')
local UIS=game:GetService('UserInputService')
local Tween=game:GetService('TweenService')
local Config=require(RS:WaitForChild('SecretAuraConfig'))
local Arrivals=require(RS:WaitForChild('SecretArrivalConfig'))
local Definitions=require(RS:WaitForChild('DogEconomy'):WaitForChild('DogDefinitions'))
local Aura=require(script:WaitForChild('Aura'))
local Common=require(script:WaitForChild('Common'))
local Styles=require(script:WaitForChild('Styles'))
local player=Players.LocalPlayer

-- Outside DOGROTS_District: WorldDetailQuality, TintLights and WorldEventLighting own the
-- district's lights and emitters; this folder is ours alone.
local folder=workspace:FindFirstChild(Config.Folder)
if not folder then
 folder=Instance.new('Folder');folder.Name=Config.Folder;folder.Archivable=false;folder.Parent=workspace
end

-- Kit.Low() semantics (SecretArrivals/Kit): phones and tablets get the light version unless
-- their player chose High effects; ReducedMotion is light too.
local function quality()
 local fx=player:GetAttribute('WorldEventFX')
 if fx=='Low'or player:GetAttribute('LowFX')==true or player:GetAttribute('ReducedMotion')==true
  or(UIS.TouchEnabled and fx~='High')then return 'Low'end
 return fx=='Medium'and 'Medium'or 'High'
end

---------------------------------------------------------------- which models
local tagged={}   -- every tagged model (some not dressable yet: unparented, excluded)
local auras={}    -- model -> Aura
local active={}   -- auras touched every frame (near, or fading)
local retiring={} -- auras fading out after their model left
local function excluded(model)
 local o=model.Parent
 while o and o~=workspace do
  if Config.SkipAncestors[o.Name]or o:IsA('WorldModel')then return true end
  o=o.Parent
 end
 return o~=workspace
end
-- Museum silhouettes keep the real DogId: never dress a locked exhibit (no spoilers).
local function eligible(model)
 if not model.Parent or not model:IsDescendantOf(workspace)then return false end
 if model:GetAttribute('Locked')==true or model.Name=='UnknownSilhouette'then return false end
 local id=model:GetAttribute('DogId')
 local def=type(id)=='string'and Definitions[id]or nil
 if not def or def.Rank~=6 or not Config.Dogs[id]or not Styles[id]then return false end
 return not excluded(model)
end
local function retire(aura)
 aura.Target=0
 -- No new particles; what is in the air fades with the aura.
 aura:SetRates(0,1)
 active[aura]=nil
 retiring[aura]=true
end
local function track(model)
 if model:IsA('Model')then tagged[model]=true end
end
local function untrack(model)
 tagged[model]=nil
 local aura=auras[model]
 if aura then auras[model]=nil;retire(aura)end
end
CS:GetInstanceAddedSignal(Config.Tag):Connect(track)
CS:GetInstanceRemovedSignal(Config.Tag):Connect(untrack)
for _,model in ipairs(CS:GetTagged(Config.Tag))do track(model)end

---------------------------------------------------------------- one pass
local function buildReduced(a,g)Common.Reduced(a,g);a.Style.Reduced(a,g)end
local function buildFull(a,g)Common.Full(a,g);a.Style.Full(a,g)end

-- Visible: placed, not held by its arrival, not leaving, not hidden. Level by distance.
local function evaluate(a,now,cam,lod)
 if a.Dirty then a:Rebuild()end
 local model,G=a.Model,a.Geo
 local visible=G~=nil
 if G then
  local hold=model:GetAttribute('ArrivalHoldUntil')
  local state=model:GetAttribute('State')
  local part=G.Visual
  if not G.Anchor.Parent or not part.Parent then a.Dirty=true;visible=false
  -- The arrival cinematic owns the dog until its hold ends; then the aura fades in.
  elseif type(hold)=='number'and now<hold then visible=false
  elseif state=='Despawning'or state=='Delivered'then visible=false
  -- Dissolving (reveals) or hidden locally by someone else's arrival.
  elseif part.Transparency+(1-part.Transparency)*part.LocalTransparencyModifier>.6 then visible=false end
 end
 a.Target=visible and 1 or 0
 a.Distance=(G and G.Anchor.Parent)and(a:World(G.Center).Position-cam).Magnitude or math.huge
 if visible then
  local h=Config.Lod.Hysteresis
  local full=lod.Full+(a.Level>=3 and h or 0)
  local reduced=lod.Reduced+(a.Level>=2 and h or 0)
  a.Level=a.Distance<full and 3 or a.Distance<reduced and 2 or 1
 end
end
local function apply(a,beacon,light,highlight)
 if not a.Geo then return end
 if a.Target==0 then
  -- Groups fade with the aura's alpha, then go.
  if a.Alpha<=0 then for key in pairs(a.Groups)do a:DestroyGroup(key)end;a.Level=0 end
  return
 end
 if a.Mini then
  if a.Level>=3 and a.Style.Mini then a:Ensure(3,a.Style.Mini)else a:Release(3)end
 else
  if a.Level>=2 then a:Ensure(2,buildReduced)else a:Release(2)end
  if a.Level>=3 then a:Ensure(3,buildFull)else a:Release(3)end
  if beacon then a:Ensure('Beacon',Common.Beacon)else a:Release('Beacon')end
  if light then a:Ensure('Light',Common.Light)else a:Release('Light')end
  if highlight then a:Ensure('Highlight',Common.Highlight)else a:Release('Highlight')end
  local reduced=a.Groups[2]
  local plate=reduced and reduced.State.Plate
  if plate and plate.Parent then plate.AlwaysOnTop=a.Distance<Config.Plate.OnTopDistance end
 end
 -- Near auras follow a moving dog every frame; the rest here.
 if not a.Groups[3]then a:Follow()end
 if a.Style.Tick and(a.Groups[2]or a.Groups[3])then
  local ok,err=pcall(a.Style.Tick,a,os.clock())
  if not ok then warn('[SecretAuras] tick',a.DogId,err)end
 end
end

-- THE DOG darkens the view a little when the camera is close to it.
local grade
local gradeLevel=0
local function darken(list)
 local close=0
 for _,a in ipairs(list)do
  if a.DogId=='TheDog'and a.Target>0 and a.Geo then
   close=math.max(close,math.clamp(1-a.Distance/Config.Darken.Distance,0,1)*a.Alpha)
  end
 end
 close=math.floor(close*20+.5)/20
 local camera=workspace.CurrentCamera
 if close==gradeLevel and(close==0 or(grade and grade.Parent==camera))then return end
 gradeLevel=close
 if not grade then
  grade=Instance.new('ColorCorrectionEffect');grade.Name='DOGROTS_SecretAuraGrade';grade.Archivable=false
 end
 if camera and grade.Parent~=camera then grade.Parent=camera end
 local D=Config.Darken
 Tween:Create(grade,TweenInfo.new(.35),{Brightness=D.Brightness*close,Contrast=D.Contrast*close,Saturation=D.Saturation*close}):Play()
end

-- An arrival can still own a Highlight on its dog after the hold (THE DOG's stare lasts
-- StareSeconds); two on one model fight, so ours waits.
local function arrivalOwnsHighlight(a,now)
 local at=a.Model:GetAttribute('SecretArrivalAt')
 local spec=Arrivals.Dogs[a.DogId]
 return type(at)=='number'and spec~=nil and now<at+(spec.Hold or 0)+(spec.StareSeconds or 0)
end

local lastQuality,lastMotion
local function pass()
 local camera=workspace.CurrentCamera
 if not camera then return end
 local cam=camera.CFrame.Position
 local q=quality()
 local motion=player:GetAttribute('ReducedMotion')==true
 -- A quality switch changes what every aura is made of: rebuild them all.
 if q~=lastQuality or motion~=lastMotion then
  lastQuality,lastMotion=q,motion
  for _,a in pairs(auras)do a:Reset()end
 end
 for model in pairs(tagged)do
  local ok=eligible(model)
  local a=auras[model]
  if ok and not a then
   local id=model:GetAttribute('DogId')
   auras[model]=Aura.new(model,id,folder,Styles[id])
  elseif not ok and a then
   auras[model]=nil;retire(a)
  end
 end
 local now=workspace:GetServerTimeNow()
 local lod=Config.Lod[q]
 local list={}
 for _,a in pairs(auras)do
  a.Low=q=='Low';a.ReducedMotion=motion
  local ok,err=pcall(evaluate,a,now,cam,lod)
  if ok then table.insert(list,a)else warn('[SecretAuras] evaluate',a.DogId,err)end
 end
 table.sort(list,function(x,y)return x.Distance<y.Distance end)
 local beacons,lights,highlights=Config.Beacons[q],Config.Lights[q],Config.Highlights[q]
 local budget,scale=Config.Budget[q],Config.RateScale[q]
 for _,a in ipairs(list)do
  local live=a.Target>0 and a.Geo~=nil and not a.Mini
  local beacon=live and beacons>0 and Config.Beacon.Venues[a.Venue]==true
  if beacon then beacons-=1 end
  local light=live and lights>0 and a.Level>=3 and a.Cfg.Light~=false
  if light then lights-=1 end
  -- A dog that already wears a Highlight (its variant) keeps that one.
  local highlight=live and highlights>0 and a.Level>=3 and a.Model:FindFirstChildWhichIsA('Highlight')==nil
   and not arrivalOwnsHighlight(a,now)
  if highlight then highlights-=1 end
  local ok,err=pcall(apply,a,beacon,light,highlight)
  if not ok then warn('[SecretAuras] apply',a.DogId,err)end
  local demand=a:Demand(scale)
  local grant=math.min(demand,budget)
  budget-=grant
  a:SetRates(demand>0 and grant/demand or 0,scale)
  if next(a.Groups)or a.Alpha~=a.Target then active[a]=true end
 end
 darken(list)
end

local elapsed=Config.Tick
Run.Heartbeat:Connect(function(dt)
 elapsed+=dt
 if elapsed<Config.Tick then return end
 elapsed=0
 pass()
end)

---------------------------------------------------------------- every frame
Run.RenderStepped:Connect(function(dt)
 local camera=workspace.CurrentCamera
 local cam=camera and camera.CFrame.Position or Vector3.zero
 local t=os.clock()
 for a in pairs(active)do
  if a.Removed or auras[a.Model]~=a then active[a]=nil;continue end
  local ok,keep=pcall(a.Frame,a,dt,a.Groups[3]~=nil)
  if not ok then warn('[SecretAuras] frame',a.DogId,keep);keep=false end
  if a.Groups[3]and a.Geo and not a.Failed then
   local stepped,err=pcall(Common.Step,a,t)
   if stepped and a.Style.Step then stepped,err=pcall(a.Style.Step,a,t,dt,cam)end
   if not stepped then a.Failed=true;warn('[SecretAuras] step',a.DogId,err)end
  end
  if not keep then active[a]=nil end
 end
 for a in pairs(retiring)do
  local ok=pcall(a.Frame,a,dt,false)
  if not ok or a.Alpha<=0 or not a.Geo then retiring[a]=nil;a:Destroy()end
 end
 local batch=Aura.Batch
 if #batch.Parts>0 then
  pcall(function()workspace:BulkMoveTo(batch.Parts,batch.CFrames,Enum.BulkMoveMode.FireCFrameChanged)end)
  table.clear(batch.Parts);table.clear(batch.CFrames)
 end
end)
