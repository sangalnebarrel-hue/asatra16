-- The gameplay side of world events: what the active event does to the tongue, digging,
-- lucky blocks and players, beyond its visuals. The numbers live on the event's
-- WorldEventDefinitions row (Effects), so the UI and the server read one source.
--  LineModifiers(now)   the tongue; Economy/LineModifiers combines it with server luck.
--  Start(service)       timed effects keyed to the global schedule (StartTimestamp):
--                       lightning / tremor pulses (every kennel digs now), UFO abductions,
--                       once-per-event perks, Time Warp hatching, Dog Rush walk speed.
--  Signature(def,state) the event's big moment (called by WorldEventService.Signature).
--  Describe(state)      the effect attributes WorldEventService publishes on State.
local RS=game:GetService('ReplicatedStorage');local Players=game:GetService('Players');local Run=game:GetService('RunService')
local package=RS:WaitForChild('WorldEvents');local stateFolder=package:WaitForChild('State')
local Modifiers=require(package.WorldEventModifiers);local D=require(package.WorldEventDefinitions);local WC=require(package.WorldEventConfig)
local Economy=require(script.Parent.Config);local Dogs=require(script.Parent.DogDefinitions);local Blocks=require(RS.LuckyBlockConfig)
local LineModifiers=require(script.Parent.LineModifiers)
local E={Window=nil,Generation=nil,PulseIndex=-1}
local rng=Random.new()
-- The economy runtime loads on first use: LineModifiers requires this module from the
-- tongue's first spawn.
local function runtime()return require(script.Parent.Runtime)end

-- VariantShare {Golden=.25} -> the weight multiplier that makes that share of new tongue
-- dogs that variant, on top of the event's own Mutations rows (as DogLineSpawner rolls).
local variantTotal,variantWeight=0,{}
for _,row in ipairs(Economy.Variants)do variantTotal+=row.Weight;variantWeight[row.Name]=row.Weight end
local function variantBoost(def,shares)
 local out={}
 for name,share in pairs(shares)do
  local weight=variantWeight[name]
  if weight and weight>0 then
   local mutation=math.clamp((def.Mutations or {})[name]or 1,1,WC.ModifierCaps.Mutation)
   out[name]=math.max(1,share*variantTotal/(weight*mutation))
  end
 end
 return out
end
-- The static tongue modifiers of every event, built once (LineModifiers asks every frame).
local static={}
for _,def in ipairs(D.List)do
 local line=def.Effects and def.Effects.Line
 if line then
  static[def.Id]={RankBoost=line.RankBoost,BlockRankBoost=line.BlockRankBoost,SpawnRate=line.SpawnRate,BlockChance=line.BlockChance,
   SpeedScale=line.SpeedScale,Variants=line.VariantShare and variantBoost(def,line.VariantShare)or nil,Labels={def.DisplayName:upper()}}
 end
end
-- LineModifiers provider. A signature window (GOLDEN MINUTE, TIME COLLAPSE...) adds a
-- forced variant or a frozen tongue on top of the event's own modifiers.
function E.LineModifiers(now)
 local def=Modifiers.Active(os.time());if not def then return nil end
 local base=static[def.Id];local window=E.Window
 now=now or workspace:GetServerTimeNow()
 if not window or window.Generation~=Modifiers.Generation or now>=window.Until then return base end
 local out=table.clone(base or {})
 out.Labels={def.DisplayName:upper(),window.Name}
 if window.Force then out.ForceVariant=window.Force end
 if window.Freeze then out.Freeze=true end
 return out
end
-- A Studio session of a PUBLISHED place uses the real DataStore: an event started from the
-- F6 lab there shows everything but grants nothing (no profile writes, no forced Secret).
function E.Preview(state)
 return Run:IsStudio()and game.GameId~=0 and type(state)=='table'and type(state.Generation)=='string'and state.Generation:sub(1,4)=='dev:'
end
-- C3: what the active event does, for ReplicatedStorage.WorldEvents.State (BuffHUD chip,
-- banners). Empty text / 0 when no event is active.
function E.Describe(state)
 local def=type(state)=='table'and state.State=='ACTIVE'and D.ById[state.EventId]or nil
 local fx=def and def.Effects
 return {EffectsTitle=fx and def.DisplayName:upper()or '',EffectsText=fx and fx.Text or '',
  EffectsColor=def and def.ColorTheme or Color3.new(1,1,1),EffectsEndsAt=fx and state.ActiveEndTimestamp or 0}
end
-- Profile-only transaction: the RAM fast path, never a DataStore key per grant. A profile
-- that is not resident (player leaving) is skipped instead of taking the durable path.
local function tx(player,fn)
 local Runtime=runtime();local id=player.UserId;local key='p:'..id
 if not Runtime.Tx.Loaded[key]then return false,'Profile not loaded'end
 return Runtime.Tx:Run({key},function(v)local p=v[key];Runtime.Engine:Authorize(p,id);return fn(p)end)
end
local function active(d)return type(d.AssignedSlot)=='string'and d.AssignedSlot~=''and d.State~='Walking'end
local function kennelPosition(player,slotName)
 local yard=require(script.Parent.YardCommerce).Yard(player)
 local slot=yard and yard:FindFirstChild(slotName)
 if not slot then return nil end
 local center=slot:GetAttribute('DigCenter')
 if typeof(center)=='Vector3'then return center end
 local floor=slot:FindFirstChild('KennelFloor')
 return floor and floor:IsA('BasePart')and floor.Position or nil
end
-- Lightning / tremor: every dog in the player's kennels starts digging now; its dig lands
-- Work.Duration later with the usual loot and finds. Returns the struck kennel.
local function charge(player,preview)
 local Runtime=runtime();local view=Runtime.Views[player.UserId];if not view then return nil end
 local slots={}
 for _,d in pairs(view.Dogs or {})do if active(d)then table.insert(slots,d.AssignedSlot)end end
 if #slots==0 then return nil end
 local count=#slots
 if not preview then
  local ok,result=tx(player,function(p)
   local soon=os.time()+Economy.Work.Duration;local n=0
   for _,d in pairs(p.Dogs)do if active(d)then
    n+=1;if (d.NextWorkAt or math.huge)>soon then d.NextWorkAt=soon end
   end end
   return n
  end)
  if not ok or result==0 then return nil end
  count=result;Runtime.Refresh(player)
 end
 local at=kennelPosition(player,slots[rng:NextInteger(1,#slots)])
 return at and {UserId=player.UserId,Position=at,Count=count}or nil
end
-- UFO abduction: lock on a tongue dog (anyone can still buy it for LOCK seconds), beam it
-- up, and drop an Alien Crate: a free Lucky Block of the dog's rarity, capped at Epic.
local LOCK,LIFT=3,2.6
local function pivotTo(model,cf)
 local root=model:GetAttribute('RootWelded')and model.PrimaryPart
 if root then root.CFrame=cf*root.PivotOffset:Inverse()else model:PivotTo(cf)end
end
function E.Lift(def,state,dog,data)
 local line=LineModifiers.Line
 -- Bought during the lock (or the event ended): the dog stays.
 if not dog.Parent or dog:GetAttribute('State')~='OnLine'or dog:GetAttribute('PurchaseBusy')or Modifiers.Generation~=state.Generation
  or not line or not line.Remove(dog,'keep')then
  if dog.Parent then dog:SetAttribute('UFOLockedAt',nil)end
  local bought=dog.Parent~=nil and(dog:GetAttribute('State')~='OnLine'or dog:GetAttribute('PurchaseBusy')==true)
  package.Signal:FireAllClients({Kind='Abduct',Phase='Escape',Target=dog.Parent and dog or nil,Bought=bought,Color=def.ColorTheme})
  return
 end
 -- Off the tongue: no one can buy it any more; it rises into the saucer.
 dog:SetAttribute('PurchaseBusy',true);dog:SetAttribute('LocomotionSpeed',0)
 for _,o in ipairs(dog:GetDescendants())do if o:IsA('ProximityPrompt')or o:IsA('BillboardGui')then o.Enabled=false end end
 local start=dog:GetPivot();local born=os.clock();local connection
 package.Signal:FireAllClients({Kind='Abduct',Phase='Lift',Target=dog,Position=start.Position,Seconds=LIFT,Color=def.ColorTheme})
 connection=Run.Heartbeat:Connect(function()
  if not dog.Parent then connection:Disconnect();return end
  local u=math.clamp((os.clock()-born)/LIFT,0,1)
  pivotTo(dog,CFrame.new(start.Position+Vector3.new(0,u*u*55,0))*start.Rotation*CFrame.Angles(0,u*u*math.pi*4,0))
  if u>=1 then connection:Disconnect();dog:Destroy()end
 end)
 local tier=Blocks.Rarities[math.clamp(data.Rank or 1,1,3)]
 task.delay(LIFT*.6,function()
  if Modifiers.Generation~=state.Generation or not E.Service then return end
  local crate=E.Service.SpawnObject('AlienCrate',false,{Tier=tier,Near=start.Position,Force=true})
  if crate then
   package.Signal:FireAllClients({Kind='Notice',Title='ALIEN CRATE DROPPED',Text=string.upper(tier)..' LUCKY BLOCK INSIDE · FIRST TO GRAB IT WINS',
    Color=def.ColorTheme,Position=crate:GetPivot().Position,Duration=3})
  end
 end)
end
function E.Abduct(def,state,pulse)
 local line=LineModifiers.Line;if not line or not line.Entities then return false end
 local now=workspace:GetServerTimeNow();local axis=line.End-line.Spawn;local length=axis.Magnitude
 if length<1 then return false end;axis=axis.Unit
 local candidates={}
 for _,dog in ipairs(line.Entities())do
  local id=dog:GetAttribute('DogId');local data=id and Dogs[id]
  if data and(data.Rank or 1)<=(pulse.MaxRank or 4)and dog:GetAttribute('State')=='OnLine'and not dog:GetAttribute('PurchaseBusy')
   and not dog:GetAttribute('StudioPreview')and not dog:GetAttribute('UFOLockedAt')and (dog:GetAttribute('ArrivalHoldUntil')or 0)<=now then
   -- Well inside the tongue, so it is still on it when the beam lands.
   local along=(dog:GetPivot().Position-line.Spawn):Dot(axis)
   if along>40 and along<length-70 then table.insert(candidates,dog)end
  end
 end
 if #candidates==0 then return false end
 local dog=candidates[rng:NextInteger(1,#candidates)];local data=Dogs[dog:GetAttribute('DogId')]
 dog:SetAttribute('UFOLockedAt',now)
 package.Signal:FireAllClients({Kind='Abduct',Phase='Lock',Target=dog,Position=dog:GetPivot().Position,Seconds=LOCK,
  Rarity=data.Rarity,Name=data.DisplayName,Color=def.ColorTheme})
 task.delay(LOCK,function()
  local ok,err=pcall(E.Lift,def,state,dog,data)
  if not ok then warn('[WorldEventEffects] abduction',err)end
 end)
 return true
end
-- One pulse of the event (Effects.Pulse): Lightning / Tremor charge every online player's
-- kennels at once; Abduct beams one tongue dog. big = the signature's mega pulse.
function E.Pulse(def,state,big)
 local pulse=def.Effects and def.Effects.Pulse;if not pulse then return end
 if pulse.Kind=='Abduct'then
  -- No dog in reach right now (an empty or frozen tongue): look again a few times.
  for _=1,4 do
   if Modifiers.Generation~=state.Generation or E.Abduct(def,state,pulse)then return end
   task.wait(4)
  end
  return
 end
 local preview=E.Preview(state);local strikes={};local pending=0
 for _,player in ipairs(Players:GetPlayers())do
  if runtime().Ready(player)then
   pending+=1
   task.spawn(function()
    local ok,strike=pcall(charge,player,preview)
    if ok and strike then table.insert(strikes,strike)elseif not ok then warn('[WorldEventEffects] charge',player.UserId,strike)end
    pending-=1
   end)
  end
 end
 local deadline=os.clock()+2
 while pending>0 and os.clock()<deadline do task.wait(.05)end
 if Modifiers.Generation~=state.Generation then return end
 package.Signal:FireAllClients({Kind='Strike',Style=pulse.Kind,EventId=def.Id,Strikes=strikes,Big=big==true,Color=def.ColorTheme})
end
-- Time Warp: the free DOG-O-MATIC token is ready (once per event per player; the dedupe
-- lives in the profile, keyed by the event Generation).
local function grantToken(player,state)
 local Tickets=require(script.Parent.RouletteTickets);local Machine=require(RS.RewardMachineConfig);local R=require(script.Parent.Rules)
 local generation=state.Generation
 local ok,result=tx(player,function(p)
  local perks=p.WorldEventPerks
  if type(perks)~='table'or perks.Generation~=generation then perks={Generation=generation,Done={}};p.WorldEventPerks=perks end
  if perks.Done.Token then return 'Done'end
  perks.Done.Token=true
  -- The free wallet holds TicketCapacity; a full wallet must have no recharge deadline.
  local count=Tickets.Normalize(p,os.time());local outcome='Ready'
  if count<Machine.TicketCapacity then p.RouletteTickets=Machine.TicketCapacity;p.NextRouletteTicketAt=0;outcome='Granted'end
  R.Validate(p);return outcome
 end)
 if not ok then return false end
 if result~='Done'then
  runtime().Refresh(player)
  local def=D.ById[state.EventId]
  package.Signal:FireClient(player,{Kind='Perk',Title=result=='Granted'and 'FREE DOG TOKEN!'or 'YOUR DOG TOKEN IS READY',
   Text=result=='Granted'and 'TIME WARP RECHARGED YOUR DOG-O-MATIC TOKEN · SPIN IT AT THE PLAZA'or 'TIME WARP: YOUR FREE DOG-O-MATIC SPIN IS WAITING AT THE PLAZA',
   Color=def and def.ColorTheme,Duration=4})
 end
 return true
end
-- Time Warp: blocks already on a pad hatch HatchSpeed times faster (remaining time divided
-- once per event). Blocks placed during the event get the short timer at placement
-- (LuckyLifecycle) and carry the same Warp mark, so they are not divided twice.
local function warp(player,state,speed)
 local Runtime=runtime();local view=Runtime.Views[player.UserId];if not view then return end
 local generation=state.Generation;local due=false
 for _,b in pairs(view.OwnedBlocks or {})do
  if b.State=='Placed'and type(b.ReadyAt)=='number'and b.ReadyAt>os.time()+1 and b.Warp~=generation then due=true;break end
 end
 if not due then return end
 local ok,count=tx(player,function(p)
  local now=os.time();local n=0
  for _,b in pairs(p.OwnedBlocks or {})do
   if b.State=='Placed'and type(b.ReadyAt)=='number'and b.ReadyAt>now and b.Warp~=generation then
    b.ReadyAt=now+math.max(1,math.ceil((b.ReadyAt-now)/speed));b.Warp=generation;n+=1
   end
  end
  return n
 end)
 if not ok or count==0 then return end
 Runtime.Refresh(player)
 local synced,err=pcall(function()require(script.Parent.LuckyLifecycle).Sync(player)end)
 if not synced then warn('[WorldEventEffects] hatch sync',err)end
 local def=D.ById[state.EventId]
 package.Signal:FireClient(player,{Kind='Perk',Title='TIME WARP',Text=count..(count==1 and ' LUCKY BLOCK HATCHES'or ' LUCKY BLOCKS HATCH')..' '..speed..'x FASTER',
  Color=def and def.ColorTheme,Duration=3})
end
-- Dog Rush: everyone walks faster while it lasts (MovementModifiers, key 'WorldEvent').
local walking={}
local function walk(multiplier)
 local Movement=require(script.Parent.Parent.MovementModifiers)
 for _,player in ipairs(Players:GetPlayers())do
  if multiplier then walking[player]=true;Movement.Set(player,'WorldEvent',multiplier)
  elseif walking[player]then walking[player]=nil;Movement.Set(player,'WorldEvent',nil)end
 end
end
function E.Signature(def,state)
 local sig=def.Effects and def.Effects.Signature;if not sig then return end
 local now=workspace:GetServerTimeNow()
 if sig.Seconds and(sig.Force or sig.Freeze)then
  E.Window={Generation=state.Generation,Name=sig.Name,Until=now+sig.Seconds,Force=sig.Force,Freeze=sig.Freeze}
  LineModifiers.Invalidate()
 end
 local queue=sig.Queue
 -- A forced Secret is a grant: never in a Studio preview of a published place.
 if queue and not(E.Preview(state)and math.max(queue.Spec.Rank or 0,queue.Spec.MaxRank or 0)>=6)then
  local spec=table.clone(queue.Spec)
  -- Expiring spawns (STAMPEDE) are dropped if the event ends before they walk out.
  if queue.Expire then spec.Source='WorldEvent:'..tostring(state.Generation)end
  LineModifiers.QueueSpawn(spec,queue.Count)
 end
 if sig.Pulse then task.spawn(function()local ok,err=pcall(E.Pulse,def,state,true);if not ok then warn('[WorldEventEffects] signature pulse',err)end end)end
 stateFolder:SetAttribute('EffectsSignature',sig.Name..' · '..sig.Text)
 stateFolder:SetAttribute('EffectsSignatureEndsAt',now+(sig.Seconds or def.SignatureDuration or 10))
end
local function begin(state)
 E.Generation=state.Generation;E.PulseIndex=-1;E.Window=nil;LineModifiers.Invalidate()
end
local function finish()
 E.Window=nil;E.Generation=nil;walk(nil)
 local queue=LineModifiers.Queue
 for i=#queue,1,-1 do
  local spec=queue[i]
  if type(spec)=='table'and type(spec.Source)=='string'and spec.Source:sub(1,11)=='WorldEvent:'then table.remove(queue,i)end
 end
 LineModifiers.Invalidate()
 stateFolder:SetAttribute('EffectsSignature','');stateFolder:SetAttribute('EffectsSignatureEndsAt',0)
end
local perkMarks={};local warpBusy={};local lastPerks=0
-- One tick of the effects loop (Start runs it every .5 s).
function E.Step()
 local service=E.Service;local state=service and service.Current
 local def=state and state.State=='ACTIVE'and Modifiers.Active(os.time())or nil
 if def and(def.Id~=state.EventId or Modifiers.Generation~=state.Generation)then def=nil end
 local generation=def and state.Generation or nil
 if generation~=E.Generation then
  if E.Generation then finish()end
  if generation then begin(state)end
 end
 if not def then return end
 local fx=def.Effects or {};local now=workspace:GetServerTimeNow()
 if E.Window and now>=E.Window.Until then E.Window=nil;LineModifiers.Invalidate()end
 walk(fx.Walk)
 local pulse=fx.Pulse
 if pulse then
  local since=now-state.StartTimestamp-(pulse.First or 0)
  if since>=0 and now<state.ActiveEndTimestamp-3 then
   local index=math.floor(since/pulse.Every)
   if index>E.PulseIndex then
    E.PulseIndex=index
    task.spawn(function()local ok,err=pcall(E.Pulse,def,state,false);if not ok then warn('[WorldEventEffects] pulse',err)end end)
   end
  end
 end
 if(fx.Perk or fx.HatchSpeed)and os.clock()-lastPerks>=2 and not E.Preview(state)then
  lastPerks=os.clock()
  for _,player in ipairs(Players:GetPlayers())do if runtime().Ready(player)then
   local mark=perkMarks[player.UserId]
   if fx.Perk=='Token'and not(mark and mark.Generation==generation and(mark.Done or mark.Busy or mark.Tries>=3))then
    mark=mark and mark.Generation==generation and mark or {Generation=generation,Tries=0};perkMarks[player.UserId]=mark
    mark.Busy=true;mark.Tries+=1
    task.spawn(function()
     local ok,done=pcall(grantToken,player,state)
     if not ok then warn('[WorldEventEffects] token',player.UserId,done)end
     mark.Busy=false;mark.Done=ok and done==true
    end)
   end
   if fx.HatchSpeed and not warpBusy[player]then
    warpBusy[player]=true
    task.spawn(function()
     local ok,err=pcall(warp,player,state,fx.HatchSpeed)
     if not ok then warn('[WorldEventEffects] hatch',player.UserId,err)end
     warpBusy[player]=nil
    end)
   end
  end end
 end
end
function E.Start(service)
 if E.Started then return end;E.Started=true;E.Service=service
 Players.PlayerRemoving:Connect(function(player)walking[player]=nil;warpBusy[player]=nil;perkMarks[player.UserId]=nil end)
 task.spawn(function()
  while true do
   task.wait(.5)
   local ok,err=pcall(E.Step)
   if not ok then warn('[WorldEventEffects]',err)end
  end
 end)
end
return E
