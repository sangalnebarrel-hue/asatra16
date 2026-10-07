local RS=game:GetService('ReplicatedStorage');local Players=game:GetService('Players');local Http=game:GetService('HttpService');local Run=game:GetService('RunService')
local package=RS:WaitForChild('WorldEvents');local C=require(package.WorldEventConfig);local D=require(package.WorldEventDefinitions);local Schedule=require(package.WorldEventSchedule);local Modifiers=require(package.WorldEventModifiers);local Visuals=require(package.WorldEventObjects)
local Runtime=require(script.Parent.Economy.Runtime);local R=require(script.Parent.Economy.Rules);local I=require(script.Parent.Economy.ItemRules)
local Lucky=require(script.Parent.Economy.LuckyLifecycle);local Supplies=require(script.Parent.Economy.SupplyRules);local Effects=require(script.Parent.Economy.WorldEventEffects)
local Economy=require(script.Parent.Economy.Config);local Blocks=require(RS.LuckyBlockConfig);local LuckyConfig=require(RS.LuckyLifecycleConfig)
local stateFolder=package:WaitForChild('State');local fx=workspace:WaitForChild('WorldEventFX');local map=workspace:WaitForChild('DOGROTS_District');local rng=Random.new()
local S={Current=nil,Objects={},DebugState=nil};local serial=0
local DigConfig=require(RS:WaitForChild('GlobalDigConfig'))
-- Where pickups appear. A spot is {Part=BasePart} (a placed WorldEventSpawnPoints part that
-- moves with its district) or {CFrame=CFrame} (a runtime spot). Groups:
--  Site   the event stage: the Global Dig quarry when it is open; while it sits behind its
--         closed COMING SOON cover, the Welcome Hub plaza and the back district beside it.
--  Street every other placed point plus runtime spots on the crossings between the yards.
--  Tongue runtime spots on the paths beside the tongue, where players wait for dogs.
local spots={Site={},Street={},Tongue={}}
local function spotFrame(spot)return spot.Part and spot.Part.CFrame or spot.CFrame end
local function spotAlive(spot)return spot.CFrame~=nil or(spot.Part~=nil and spot.Part.Parent~=nil)end
-- The placed points, found once in chunks (the district is ~37k instances).
local function scanPlaced()
 local site=map:FindFirstChild('08_GlobalDigSite');local siteOpen=DigConfig.Enabled~=false
 local hub,back=map:FindFirstChild('32_WelcomeHub'),map:FindFirstChild('31_BackDistrictExpansion')
 local found={Site={},Street={}}
 for i,o in ipairs(map:GetDescendants())do
  if i%1500==0 then task.wait()end
  if o.Name=='WorldEventSpawnPoints'then
   local inSite=site~=nil and o:IsDescendantOf(site)
   if siteOpen or not inSite then
    local group=(inSite or(not siteOpen and((hub and o:IsDescendantOf(hub))or(back and o:IsDescendantOf(back)))))and 'Site'or 'Street'
    for _,a in ipairs(o:GetChildren())do if a:IsA('BasePart')then table.insert(found[group],{Part=a})end end
   end
  end
 end
 for group,list in pairs(found)do for _,spot in ipairs(list)do table.insert(spots[group],spot)end end
end
-- Runtime spots on the open paths around the yards and the tongue: a ground hit and a clear
-- box above it (no lamp posts or bollards), nudged along the path when blocked.
local function addRuntimeSpots()
 local cast=RaycastParams.new();cast.FilterType=Enum.RaycastFilterType.Include;cast.FilterDescendantsInstances={map};cast.RespectCanCollide=true
 local probe=OverlapParams.new();probe.FilterType=Enum.RaycastFilterType.Include;probe.FilterDescendantsInstances={map};probe.RespectCanCollide=true
 local function try(group,at)
  local hit=workspace:Raycast(at+Vector3.new(0,6,0),Vector3.new(0,-14,0),cast)
  if not hit or hit.Normal.Y<.65 then return false end
  if #workspace:GetPartBoundsInBox(CFrame.new(hit.Position+Vector3.new(0,3.3,0)),Vector3.new(6,5,6),probe)>0 then return false end
  table.insert(spots[group],{CFrame=CFrame.new(hit.Position+Vector3.new(0,1,0))});return true
 end
 local function along(part,group,fractions)
  local long=part.Size.X>=part.Size.Z and part.CFrame.RightVector*part.Size.X or part.CFrame.LookVector*part.Size.Z
  for _,f in ipairs(fractions)do
   local center=part.Position+long*(f-.5)
   for _,nudge in ipairs({0,3,-3,6,-6,9,-9})do if try(group,center+long.Unit*nudge)then break end end
  end
 end
 local gardens=map:FindFirstChild('02_DogFactory');gardens=gardens and gardens:FindFirstChild('TheDogArrivalGardens')
 for _,p in ipairs(gardens and gardens:GetChildren()or {})do if p.Name=='TongueSidePath'and p:IsA('BasePart')then along(p,'Tongue',{.2,.36,.52,.68,.84})end end
 local paths=map:FindFirstChild('01_IslandAndStreets');paths=paths and paths:FindFirstChild('PrimaryPaths')
 for _,p in ipairs(paths and paths:GetChildren()or {})do if p:IsA('BasePart')then
  if p.Name=='YardCrossing'and math.abs(p.Position.Z)<120 then along(p,'Street',{.3,.7})
  elseif p.Name=='InnerYardPromenade'then along(p,'Street',{.37,.63})end
 end end
 -- A remodelled map without these paths: beside the tongue itself.
 local line=map:FindFirstChild('03_DogLine');local a,b=line and line:FindFirstChild('DogSpawn'),line and line:FindFirstChild('DogEnd')
 if #spots.Tongue==0 and a and b then
  local side=(b.Position-a.Position):Cross(Vector3.yAxis).Unit
  for _,f in ipairs({.3,.5,.7})do for _,s in ipairs({-1,1})do try('Tongue',a.Position:Lerp(b.Position,f)+side*16*s)end end
 end
 S.LineCenter=a and b and a.Position:Lerp(b.Position,.5)or Vector3.zero
end
local function candidates(kind,special)
 local P=C.Pickups[kind]or {}
 local list={}
 for _,group in ipairs(P.Groups or {'Site','Street','Tongue'})do for _,spot in ipairs(spots[group])do if spotAlive(spot)then table.insert(list,spot)end end end
 return list
end
-- Coins worth `seconds` of this player's own dig income, at least the layer's floor.
local function income(p,seconds)
 if not seconds or seconds<=0 then return 0 end
 local o=type(p.OfflineEarnings)=='table'and p.OfflineEarnings;local rate=o and tonumber(o.BaseRate)or 0
 if rate~=rate or rate<0 or rate==math.huge then rate=0 end
 local floors=C.Pickups.Floor;local floor=floors[math.clamp(math.floor(p.CurrentLayer or 1),1,#floors)]
 return math.floor(math.max(floor*seconds/60,rate*seconds))
end
local function rollTier(rows,random)
 local total=0;for _,row in ipairs(rows)do total+=row[2]end
 local n=random()*total
 for _,row in ipairs(rows)do n-=row[2];if n<0 then return row[1]end end
 return rows[#rows][1]
end
-- The pickup's reward, applied to the profile inside the claim transaction.
local function payout(p,info,current,random,uid)
 local P=C.Pickups[info.Kind]or {};local now=os.time()
 local reward={Kind=info.Kind,Cash=0,Bones=P.Bones or(P.Income and 0 or C.Interactions.Bones)}
 local cash=P.Income and income(p,P.Income)or C.Interactions.Cash
 -- A free Lucky Block, stored in the inventory (never paid-random). Full storage pays its
 -- tongue price in coins instead.
 local tier=info.Tier or(info.Special and P.SpecialBlock)or P.Block or(P.Blocks and rollTier(P.Blocks,random))
 if tier and Blocks.Rank(tier)then
  Lucky.Normalize(p)
  if R.Count(p.OwnedBlocks)<LuckyConfig.InventoryCapacity then Lucky.AddStored(p,tier,1,'WorldEvent:'..current.EventId,false);reward.Block=tier
  else cash+=Blocks.ConveyorPrices[tier]or 0;reward.BlockFull=tier end
 end
 -- Supply minutes, on the same timer (and one-hour cap with reserve) as a bought supply.
 local supply=P.Supply and Economy.Supplies[P.Supply]
 if supply then
  Supplies.Normalize(p,now)
  local finish=math.max(now,Supplies.EndAt(p,P.Supply))+P.SupplySeconds
  p.Supplies[P.Supply]=math.min(finish,now+(supply.MaxSeconds or 3600))
  p.SupplyReserve[P.Supply]=math.max(0,finish-p.Supplies[P.Supply])
  reward.Supply={Kind=P.Supply,Name=supply.Name,Seconds=P.SupplySeconds}
 end
 -- A find: the collector's layer, one deeper (Cursed Cache) or THE VOID (Alien Dig Zone).
 -- The special ones retry so they are (almost) never empty.
 if P.Item or P.Deeper or P.ItemDepth then
  if I.Free(p)then
   local depth=math.clamp(P.ItemDepth or math.floor(p.CurrentLayer or 1)+(P.Deeper or 0),1,5)
   local team=R.Team(p,now)
   for _=1,(P.Deeper or P.ItemDepth)and 10 or 1 do
    local def,chance=I.Pick(depth,random,team)
    if def then local found=I.Mint(p,def,chance,uid,now,random,team);found.Origin='WorldEvent:'..current.EventId;reward.Item=R.Copy(found);break end
   end
  else reward.ItemFull=true end
 end
 cash=math.clamp(math.floor(cash),0,math.max(0,Economy.MaxCash-p.Cash))
 if cash>0 then R.Credit(p,cash)end
 reward.Cash=cash;p.Bones+=reward.Bones
 return reward
end
function S.Interact(player,model)
 local current=S.Current;local info=S.Objects[model];local uid=player.UserId
 if not info or not current or current.State~='ACTIVE'or os.time()>=current.ActiveEndTimestamp or not model.Parent or os.time()>=info.Expires then return false,'This event opportunity has ended'end
 if info.Shared then if info.ClaimedBy[uid]or info.Claiming[uid]then return false,'You already claimed this'end
 elseif info.Claimed or info.Claiming then return false,'This object has already been collected'end
 if not Runtime.Ready(player)or not Runtime.Allow(player,2)then return false,'Please wait'end
 if Effects.Preview(current)then return false,'Studio preview of a published place: event rewards are off'end
 local P=C.Pickups[info.Kind]or {};local reach=P.Reach or C.Interactions.Distance
 local root=player.Character and player.Character:FindFirstChild('HumanoidRootPart');local hum=player.Character and player.Character:FindFirstChildOfClass('Humanoid')
 if not root or not hum or hum.Health<=0 or (root.Position-model:GetPivot().Position).Magnitude>reach then return false,'Move closer'end
 -- The physical event object only exists on this server. Claim it in server RAM
 -- before the profile transaction so two players can never collect it twice,
 -- without paying for a global DataStore eventobject:<id> lock. Shared objects (the Giant
 -- Bone) lock per player instead: everyone may claim them once.
 if info.Shared then info.Claiming[uid]=true else info.Claiming=true end
 local generation=current.Generation;local seed=rng:NextInteger(1,2147483646);local itemUid=Http:GenerateGUID(false):gsub('-','')
 local ok,result=Runtime.Tx:Run({'p:'..uid},function(v)
  local p=v['p:'..uid];Runtime.Engine:Authorize(p,uid)
  R.Check(S.Current and S.Current.State=='ACTIVE'and S.Current.Generation==generation and os.time()<info.Expires and model.Parent and S.Objects[model]==info and not(info.Shared and info.ClaimedBy[uid]or not info.Shared and info.Claimed),'This event opportunity has ended')
  local claims=p.WorldEventClaims
  if not claims or claims.Generation~=generation then claims={Generation=generation,Count=0,Objects={}};p.WorldEventClaims=claims end
  R.Check(not claims.Objects[info.Id],'You already collected this reward')
  -- A shared object is the event's gift to everyone: no cooldown, not counted in the limit.
  if not info.Shared then R.Check(os.time()>=(p.NextWorldEventCollect or 0)and claims.Count<C.Interactions.PerEvent,'Take a break from collecting')end
  R.Check((root.Position-model:GetPivot().Position).Magnitude<=reach,'Move closer')
  claims.Objects[info.Id]=true
  if not info.Shared then claims.Count+=1;p.NextWorldEventCollect=os.time()+C.Interactions.Cooldown end
  local random=Random.new(seed)
  local reward=payout(p,info,current,function()return random:NextNumber()end,itemUid)
  R.Validate(p);return reward
 end,'eventcollect:'..uid..':'..info.Id)
 if ok then
  local objectId=info.Id;local position=model:GetPivot().Position
  if info.Shared then info.ClaimedBy[uid]=true;info.Claiming[uid]=nil
  else
   info.Claimed=true;info.Claiming=false
   -- Remove the pickup before any heavier profile/world projection. The reward is
   -- already committed to the RAM profile at this point.
   if model.Parent then model:Destroy()end;S.Objects[model]=nil
  end
  if type(result)=='table'then result.Shared=info.Shared==true end
  package.Signal:FireClient(player,{Kind='Reward',EventId=current.EventId,Reward=result,Position=position,ObjectId=objectId})
  RS.RewardPresentation:FireClient(player,{Cue='Reward'})
  task.defer(function()if player.Parent and Runtime.Ready(player)then Runtime.Refresh(player)end end)
 else
  if info.Shared then info.Claiming[uid]=nil else info.Claiming=false end
 end
 return ok,result
end
-- A short line over the pickup saying what it gives, readable from across the street.
local function label(model,text,color)
 local core=model.PrimaryPart;if not core or not text then return end
 local _,size=model:GetBoundingBox()
 local board=Instance.new('BillboardGui');board.Name='PickupLabel';board.Adornee=core;board.Size=UDim2.fromOffset(220,30)
 board.StudsOffsetWorldSpace=Vector3.new(0,size.Y+1.5,0);board.MaxDistance=160;board.LightInfluence=0;board.Parent=model
 local t=Instance.new('TextLabel');t.Size=UDim2.fromScale(1,1);t.BackgroundTransparency=1;t.Text=text;t.Font=Enum.Font.GothamBlack;t.TextScaled=true
 t.TextColor3=Color3.new(1,1,1);t.TextStrokeColor3=color:Lerp(Color3.new(0,0,0),.55);t.TextStrokeTransparency=0;t.Parent=board
end
-- opts: Tier (the block inside), Near (choose among the spots closest to it), Force (ignore
-- the active-pickup cap, like signature pickups).
function S.SpawnObject(kind,special,opts)
 opts=opts or {}
 local current=S.Current;if not current or current.State~='ACTIVE'then return end
 local def=D.ById[current.EventId];local P=C.Pickups[kind]or {};local count=0;for model in pairs(S.Objects)do if model.Parent then count+=1 end end
 if count>=C.Interactions.MaxActive and not special and not opts.Force then return end
 local all=candidates(kind,special);if #all==0 then return end
 local cast=RaycastParams.new();cast.FilterType=Enum.RaycastFilterType.Include;cast.FilterDescendantsInstances={map};cast.RespectCanCollide=true
 -- Anchors move with their district. Verify their current floor before placing a reward.
 local function choose(list)
  for _=1,#list do
   local candidate=table.remove(list,rng:NextInteger(1,#list));local frame=spotFrame(candidate)
   local hit=workspace:Raycast(frame.Position+Vector3.new(0,3,0),Vector3.new(0,-15,0),cast)
   local occupied=false
   for object,info in pairs(S.Objects)do if object.Parent and info.Anchor==candidate then occupied=true;break end end
   if hit and hit.Normal.Y>.65 and not occupied then return candidate,hit.Position end
  end
 end
 -- The Giant Bone lands near the middle of the yards; a UFO drops its crate near the tongue
 -- (anywhere else when those spots are taken).
 local point,surface
 local focus=opts.Near or(P.Central and S.LineCenter)
 if focus then
  local near=table.clone(all)
  table.sort(near,function(a,b)return(spotFrame(a).Position-focus).Magnitude<(spotFrame(b).Position-focus).Magnitude end)
  for i=#near,(P.Central and 3 or 6)+1,-1 do table.remove(near,i)end
  point,surface=choose(near)
 end
 if not point then point,surface=choose(all)end
 if not point then return end
 local tierColor=opts.Tier and Blocks.VisualConfig.Colors[Blocks.Rank(opts.Tier)or 1]
 local model=Visuals.Build(kind,tierColor or def.ColorTheme)
 if P.Scale then model:ScaleTo(P.Scale)end
 local frame=spotFrame(point)
 model:PivotTo(frame+Vector3.new(0,1,0))
 local box,size=model:GetBoundingBox();local bottom=box.Position.Y-size.Y/2
 model:PivotTo(model:GetPivot()+Vector3.new(0,surface.Y+.06-bottom,0));model.Parent=fx
 model:SetAttribute('Grounded',true)
 local lifetime=special and(P.SpecialLifetime or P.Lifetime or 25)or P.Lifetime or C.Interactions.ObjectLifetime
 local id=Http:GenerateGUID(false):gsub('-','');local expires=math.min(current.ActiveEndTimestamp,os.time()+lifetime)
 S.Objects[model]={Id=id,Expires=expires,Anchor=point,Local=frame:ToObjectSpace(model:GetPivot()),Kind=kind,Special=special==true,Tier=opts.Tier,
  Shared=P.Shared==true,ClaimedBy={},Claiming=P.Shared and {}or false}
 model:SetAttribute('EventObjectId',id);model:SetAttribute('ExpiresAt',expires);model:SetAttribute('PickupKind',kind)
 if P.Shared then model:SetAttribute('Shared',true)end
 local text=opts.Tier and string.upper(opts.Tier)..' '..(P.Label or 'LUCKY BLOCK')or special and P.SpecialLabel or P.Label
 label(model,text,tierColor or def.ColorTheme)
 local prompt=Instance.new('ProximityPrompt');prompt.Name='WorldEventPickupPrompt';prompt.ActionText=P.Action or 'COLLECT'
 prompt.ObjectText=(P.Title or kind:gsub('(%l)(%u)','%1 %2'))..(text and ' · '..text:lower()or '');prompt.HoldDuration=0;prompt.RequiresLineOfSight=false
 prompt.MaxActivationDistance=math.max(12,(P.Reach or C.Interactions.Distance)-5);prompt.Parent=model.PrimaryPart
 prompt.Triggered:Connect(function(player)local objectId=model:GetAttribute('EventObjectId');local ok,msg=S.Interact(player,model);if not ok then package.Signal:FireClient(player,{Kind='Hint',Message=tostring(msg),ObjectId=objectId})end end)
 model.Destroying:Connect(function()S.Objects[model]=nil end)
 return model
end
local function journal(player,current)
 if not Runtime.Ready(player)then return end
 local p=Runtime.Views[player.UserId];if p and p.WorldEventsSeen and p.WorldEventsSeen[current.EventId]then return end
 local ok,new=Runtime.Tx:Run({'p:'..player.UserId},function(v)
  local p=v['p:'..player.UserId];Runtime.Engine:Authorize(p,player.UserId);p.WorldEventsSeen=p.WorldEventsSeen or {}
  if p.WorldEventsSeen[current.EventId]then return false end
  p.WorldEventsSeen[current.EventId]={FirstSeen=os.time(),Rarity=D.ById[current.EventId].Rarity};R.Validate(p);return true
 end)
 if ok then Runtime.Refresh(player);if new then package.Signal:FireClient(player,{Kind='Discovered',EventId=current.EventId})end end
end
function S.Apply(nextState)
 local old=S.Current;local changed=not old or old.State~=nextState.State or old.Cycle~=nextState.Cycle or old.EventId~=nextState.EventId
 if not changed then return end
 local generation=nextState.Generation or tostring(nextState.Cycle)..':'..nextState.EventId
 if old and old.Generation~=generation then for model in pairs(S.Objects)do model:Destroy()end;S.Objects={}end
 nextState.Generation=generation;S.Current=nextState
 if nextState.State=='ACTIVE'then Modifiers.Set(nextState.EventId,nextState.ActiveEndTimestamp,generation)
 else Modifiers.Set(nil);for model in pairs(S.Objects)do model:Destroy()end;fx:ClearAllChildren();S.Objects={}end
 -- C3: what the event does (empty when none is active), part of the state clients receive.
 local described=Effects.Describe(nextState)
 for k,v in pairs(described)do nextState[k]=v end
 stateFolder:SetAttribute('EffectsColor',described.EffectsColor)
 if old and old.Generation~=generation or nextState.State~='ACTIVE'then stateFolder:SetAttribute('EffectsSignature','');stateFolder:SetAttribute('EffectsSignatureEndsAt',0)end
 for k,v in pairs(nextState)do if type(v)=='string'or type(v)=='number'then stateFolder:SetAttribute(k,v)end end
 serial+=1;stateFolder:SetAttribute('Revision',serial)
 if nextState.State=='ACTIVE'then
  local def=D.ById[nextState.EventId];S.NextSpawn=0;S.SignatureAt=nextState.StartTimestamp+def.SignatureSeconds;S.SignatureDone=false
  for _,p in ipairs(Players:GetPlayers())do task.spawn(journal,p,nextState)end
 end
 package:WaitForChild('Changed'):FireAllClients(nextState)
end
-- The event's big moment: the client cinematic, its signature pickups and its gameplay
-- (Effects.Signature). Runs once per event from Tick; the F6 lab can fire it again.
function S.Signature()
 local current=S.Current
 if not current or current.State~='ACTIVE'then return false,'Start an event first'end
 local def=D.ById[current.EventId];S.SignatureDone=true
 package.Signal:FireAllClients({Kind='Signature',EventId=def.Id,Duration=def.SignatureDuration})
 local sig=def.Effects and def.Effects.Signature
 for _,row in ipairs(sig and sig.Spawn or {})do for _=1,row.Count or 1 do S.SpawnObject(row.Kind,row.Special==true)end end
 local ok,err=pcall(Effects.Signature,def,current)
 if not ok then warn('WORLD EVENT signature effect failed:',err)end
 return true,(sig and sig.Name or def.DisplayName)..' triggered'
end
function S.Force(id,duration,warning)
 assert(Run:IsStudio() and C.Debug.EnabledInStudio,'Studio-only event controls')
 serial+=1;local now=os.time();local start=now+(warning or 0);local finish=start+(duration or C.EventDuration)
 if id=='stop'then S.DebugState={State='NORMAL',EventId='BONE_RAIN',Cycle=-serial,StartTimestamp=now+600,EndTimestamp=now+600,NextEventTimestamp=now+660,ActiveEndTimestamp=now+900,Hold=true};S.Apply(S.DebugState);return end
 assert(D.ById[id],'Unknown event');S.DebugState={State=(warning or 0)>0 and 'WARNING'or 'ACTIVE',EventId=id,Cycle=-serial,StartTimestamp=start,EndTimestamp=(warning or 0)>0 and start or finish,NextEventTimestamp=start,ActiveEndTimestamp=finish,Generation='dev:'..serial}
 S.Apply(R.Copy(S.DebugState))
end
function S.Tick()
 local now=os.time();local state
 if S.DebugState then
  state=R.Copy(S.DebugState)
  if not state.Hold then
   if now<state.StartTimestamp then state.State='WARNING';state.EndTimestamp=state.StartTimestamp
   elseif now<state.ActiveEndTimestamp then state.State='ACTIVE';state.EndTimestamp=state.ActiveEndTimestamp
   elseif now<state.ActiveEndTimestamp+C.TransitionDuration then state.State='ENDING';state.EndTimestamp=state.ActiveEndTimestamp+C.TransitionDuration
   else S.DebugState=nil;state=Schedule.At(now)end
  end
 else state=Schedule.At(now)end
 S.Apply(state)
 for model,info in pairs(S.Objects)do
  if not model.Parent or now>=info.Expires then if model.Parent then model:Destroy()else S.Objects[model]=nil end
  elseif info.Anchor.Part and info.Anchor.Part.Parent then model:PivotTo(info.Anchor.Part.CFrame*info.Local)end
 end
 if S.Current.State=='ACTIVE'then
  local def=D.ById[S.Current.EventId]
  if now>=(S.NextSpawn or 0)then S.NextSpawn=now+(def.Effects and def.Effects.PickupEvery or C.Interactions.SpawnSeconds);if def.SpecialObjects then S.SpawnObject(def.SpecialObjects)end end
  if not S.SignatureDone and now>=(S.SignatureAt or math.huge)then S.Signature()end
 end
end
function S.Start()
 if S.Started then return end;S.Started=true
 local okSpots,spotError=pcall(addRuntimeSpots);if not okSpots then warn('WORLD EVENT runtime spots unavailable:',spotError)end
 task.spawn(function()local ok,err=pcall(scanPlaced);if not ok then warn('WORLD EVENT spawn point scan failed:',err)end end)
 package.GetState.OnServerInvoke=function(player)if Runtime.Allow(player,1)then return S.Current end end
 Players.PlayerAdded:Connect(function(p)task.spawn(function()for i=1,60 do if not p.Parent then return end;if Runtime.Ready(p)then if S.Current.State=='ACTIVE'then journal(p,S.Current)end;return end;task.wait(1)end end)end)
 if Run:IsStudio() then
  local control=Instance.new('BindableFunction');control.Name='WorldEventDebug';control.Parent=script;control.OnInvoke=S.Force
 end
 S.Tick();task.spawn(function()while true do task.wait(1);local ok,err=pcall(S.Tick);if not ok then warn('WORLD EVENT scheduler retry:',err)end end end)
 Effects.Start(S)
 game:BindToClose(function()Modifiers.Set(nil);fx:ClearAllChildren()end)
 print('DOGROTS_WORLD_EVENTS_READY')
end
return S
