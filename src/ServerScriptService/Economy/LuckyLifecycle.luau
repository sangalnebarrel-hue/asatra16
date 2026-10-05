-- Durable ownership/state lives in the existing profile transaction journal.
-- Instances are disposable projections. Placed/Ready reservations survive death, rejoin and server changes; only a manual Open grants a dog.
local RS=game:GetService('ReplicatedStorage');local Players=game:GetService('Players');local Http=game:GetService('HttpService')
local R=require(script.Parent.Rules);local C=require(RS.LuckyLifecycleConfig);local Blocks=require(RS.LuckyBlockConfig);local Dogs=require(script.Parent.DogDefinitions)
local Commerce=require(script.Parent.YardCommerce);local Visual=require(RS.LuckyBlockVisuals)
local L={Models={},Opening={},Retries={},Presented={},ReadyTimers={}};local random=Random.new()
local function rt()return require(script.Parent.Runtime)end
local function rewards()return require(script.Parent.RewardService)end
local function guid()return Http:GenerateGUID(false):gsub('-','')end
function L.Normalize(p)
 p.OwnedBlocks=p.OwnedBlocks or {};p.BlockSchema=C.Version
 p.LuckyCredits=p.LuckyCredits or {};p.LuckyOpened=p.LuckyOpened or {};p.LuckyPity=p.LuckyPity or {};p.RewardHistory=p.RewardHistory or {}
 p.BlockOpenReceipts=p.BlockOpenReceipts or {};p.BlockOpenReceiptOrder=p.BlockOpenReceiptOrder or {}
end
local function owned(p,uid)
 R.Check(type(uid)=='string'and #uid==32,'Invalid block UID');L.Normalize(p)
 local b=p.OwnedBlocks[uid];R.Check(b and b.OwnerUserId==p.UserId and b.Uid==uid,'Block not owned');return b
end
local function alive(player)
 local c=player.Character;local h=c and c:FindFirstChildOfClass('Humanoid');return h and h.Health>0 and c:FindFirstChild('HumanoidRootPart')
end
local function rememberOpen(p,uid,result)
 p.BlockOpenReceipts=p.BlockOpenReceipts or {};p.BlockOpenReceiptOrder=p.BlockOpenReceiptOrder or {}
 if not p.BlockOpenReceipts[uid]then table.insert(p.BlockOpenReceiptOrder,uid)end
 p.BlockOpenReceipts[uid]=R.Copy(result)
 while #p.BlockOpenReceiptOrder>32 do local old=table.remove(p.BlockOpenReceiptOrder,1);p.BlockOpenReceipts[old]=nil end
end
local function serialledDog(id)
 local d=Dogs[id];return d and(d.Rank>=3 or d.SupplyType~='Permanent'or(d.FirstEditionLimit or 0)>0 or(d.LimitedSupply or 0)>0)
end
local function freeze(p,b)
 if b.Pool and b.Variants and b.Seed then return end
 local frozen={};for _,row in ipairs(rewards().Pool(p,b.Tier))do table.insert(frozen,{Id=row.Id,Weight=row.Weight,Rank=row.Rank})end
 b.Pool=frozen;b.Seed=b.Seed or random:NextInteger(1,2147483646)
 b.Variants=R.Copy(require(RS.WorldEvents.WorldEventModifiers).MutationRows(require(script.Parent.Config).Variants,'Name','Weight',os.time()))
end
function L.AddStored(p,tier,count,origin,paid)
 L.Normalize(p);R.Check(Blocks.Rank(tier),'Unknown block tier');R.Check(R.Int(count,1,100),'Invalid block quantity')
 local ids={}
 for _=1,count do
  local uid=guid();p.OwnedBlocks[uid]={Uid=uid,OwnerUserId=p.UserId,Tier=tier,State='Stored',PurchasedAt=os.time(),PaidRandom=paid==true,Origin=origin or'Reward'}
  table.insert(ids,uid)
 end
 return ids
end
-- Server-only entry point for quest/event/admin rewards. Caller supplies a durable operation ID.
function L.Grant(player,tier,count,operation,origin)
 R.Check(type(operation)=='string'and #operation>0 and #operation<=100,'Invalid grant operation')
 local runtime=rt();local key='block-grant:'..player.UserId..':'..operation
 local ok,value=runtime.Tx:Run({'p:'..player.UserId,key},function(v)
  if v[key]then return v[key]end
  local p=v['p:'..player.UserId];runtime.Engine:Authorize(p,player.UserId)
  local ids=L.AddStored(p,tier,count,origin,false);v[key]={Uids=ids,Count=count,Message='Lucky Blocks added to Inventory'};R.Validate(p);return v[key]
 end)
 if ok then runtime.Refresh(player)end;return ok,value
end
function L.Acquire(player,tier,operation,physical,oddsVersion)
 local runtime=rt();if not runtime.Ready(player)or not runtime.Allow(player,2)then return false,'Please wait'end
 R.Check(Blocks.Rank(tier),'Unknown block tier')
 local paid=physical==nil;R.Check(not paid or rewards().Policy(player),'Paid random items unavailable for this account')
 local id=physical and physical:GetAttribute('BlockUid')or operation
 R.Check(type(id)=='string'and #id==32 and id:match('^%x+$'),'Invalid acquisition')
 local key=physical and 'lucky:'..id or 'blockacquire:'..player.UserId..':'..id
 local uid=guid();local seed=random:NextInteger(1,2147483646)
 local ok,result=runtime.Tx:Run({'p:'..player.UserId,key},function(v)
  local p=v['p:'..player.UserId];runtime.Engine:Authorize(p,player.UserId);L.Normalize(p)
  if v[key]then R.Check(v[key].User==player.UserId,'This block belongs to another player');return v[key].Result or v[key].Reward end
  R.Check(R.Count(p.OwnedBlocks)<C.InventoryCapacity,'Lucky Block storage is full')
  R.Check(physical~=nil or oddsVersion==rewards().OddsVersion(p),'Odds changed; refresh the reward list')
  local root=alive(player);R.Check(root,'Wait for your character')
  if physical then
   R.Check(rewards().ValidateOffer(player,physical),'Offer expired or out of reach; view the block again')
   R.Pay(p,Blocks.ConveyorPrices[tier])
  else R.Check((p.LuckyCredits[tier]or 0)>0,'No owned credits');p.LuckyCredits[tier]-=1 end
  local pool=rewards().Pool(p,tier);local frozen={}
  for _,row in ipairs(pool)do table.insert(frozen,{Id=row.Id,Weight=row.Weight,Rank=row.Rank})end
  local variants=require(RS.WorldEvents.WorldEventModifiers).MutationRows(require(script.Parent.Config).Variants,'Name','Weight',os.time())
  local b={Uid=uid,OwnerUserId=player.UserId,Tier=tier,State='Stored',PurchasedAt=os.time(),PaidRandom=paid,Seed=seed,Pool=frozen,Variants=R.Copy(variants),OddsVersion=Blocks.Version}
  p.OwnedBlocks[uid]=b;R.Validate(p)
  local result={Kind='Block',Uid=uid,Tier=tier,State='Stored',Message='Lucky Block added to Inventory'}
  v[key]={User=player.UserId,Result=result,At=os.time()};return result
 end)
 if ok then
  runtime.Refresh(player)
  if physical and physical.Parent then physical:SetAttribute('State','Claimed');physical:Destroy()end
  L.Sync(player) -- Acquisition is silent; the normal inventory projection updates the HUD.
 end
 return ok,result
end
function L.ValidatePad(player,p,a)
 local yard=Commerce.Yard(player)
 R.Check(yard and yard:GetAttribute('OwnerUserId')==player.UserId,'This is not your yard')
 R.Check(a.YardId==yard:GetAttribute('YardId')and a.YardId==player:GetAttribute('YardId'),'Yard changed; use your own pad')
 R.Check(R.Int(a.Slot,1,C.PlacementSlots),'Choose a Lucky pad')
 local pad=yard:FindFirstChild('LuckyPad_'..a.Slot)
 R.Check(pad and pad:IsA('BasePart')and pad.Parent==yard,'Lucky pad unavailable')
 R.Check(Commerce.Near(player,pad,C.InteractionDistance),'Move closer to a Lucky pad in your yard')
 for _,other in pairs(p.OwnedBlocks or{})do R.Check((other.State~='Placed'and other.State~='Ready')or other.Slot~=a.Slot,'This Lucky pad is occupied')end
 return yard,pad
end
function L.Action(player,action,a)
 local runtime=rt();R.Check(runtime.Ready(player)and runtime.Allow(player,1),'Please wait')
 R.Check(action=='PlaceBlock','Use a Lucky pad in your own yard')
 R.Check(type(a)=='table'and type(a.Request)=='string'and #a.Request==32 and a.Request:match('^%x+$'),'Invalid request')
 local credit=a.CreditTier
 local paidAllowed=rewards().Policy(player)
 R.Check((type(a.Uid)=='string')~=(type(credit)=='string'),'Choose exactly one owned block')
 if credit then R.Check(Blocks.Rank(credit),'Unknown block tier');R.Check(paidAllowed,'Paid random items unavailable for this account')end
 local ok,result=runtime.Tx:Run({'p:'..player.UserId},function(v)
  local p=v['p:'..player.UserId];runtime.Engine:Authorize(p,player.UserId);L.Normalize(p)
  L.ValidatePad(player,p,a)
  local b
  if credit then
   -- Historical paid credits are visible Inventory stacks, not an opening entitlement.
   R.Check(R.Int(p.LuckyCredits[credit]or 0,1,1000000),'No owned blocks of this tier')
   local uid=guid();b={Uid=uid,OwnerUserId=player.UserId,Tier=credit,State='Stored',PurchasedAt=os.time(),PaidRandom=true,Origin='InventoryStack'}
  else b=owned(p,a.Uid)end
  R.Check(b.State=='Stored'or b.State=='Carried','This block is already in use')
  R.Check(not L.Opening[b.Uid],'This block is already opening')
  R.Check(not b.PaidRandom or paidAllowed,'Paid random items unavailable for this account')
  freeze(p,b)
  -- Only after all checks: consume one available item by reserving its UID as Placed.
  -- The reservation remains in OwnedBlocks for persistence and is removed at reward commit.
  if credit then p.LuckyCredits[credit]-=1;p.OwnedBlocks[b.Uid]=b end
  b.State='Placed';b.Slot=a.Slot;b.YardId=a.YardId;b.PlacedAt=os.time();b.ReadyAt=b.PlacedAt+C.OpenSeconds[b.Tier]
  R.Validate(p)
  return {Message='Placed · ready in '..C.OpenSeconds[b.Tier]..' seconds',Uid=b.Uid,ReadyAt=b.ReadyAt,State=b.State}
 end,'block-action:'..player.UserId..':'..a.Request)
 if ok then
  runtime.Refresh(player);L.Sync(player)
  if result and result.Uid and result.ReadyAt then L.ScheduleReady(player,result.Uid,result.ReadyAt)end
 end
 return ok,result
end
-- The one-second scan below is only recovery. Normal placements arm an exact
-- server timer so READY and the prompt change on the deadline, not up to 1s later.
function L.ScheduleReady(player,uid,readyAt)
 local key=player.UserId..':'..uid;local stamp=tonumber(readyAt)or 0
 if stamp<=0 or L.ReadyTimers[key]==stamp then return end;L.ReadyTimers[key]=stamp
 local function wake()
  if L.ReadyTimers[key]~=stamp then return end
  if not player.Parent then L.ReadyTimers[key]=nil;return end
  local left=stamp-os.time();if left>0 then task.delay(math.min(left,.25),wake);return end
  L.ReadyTimers[key]=nil
  local good,err=pcall(function()L.MarkReady(player);L.Sync(player)end)
  if not good then warn('Lucky ready projection deferred:',err)end
 end
 task.delay(math.max(0,stamp-os.time()),wake)
end
-- Save readiness separately from reward delivery. A timer is never a reward trigger.
function L.MarkReady(player)
 local runtime=rt();local now=os.time();local view=runtime.Views[player.UserId]
 local due=false
 for _,b in pairs(view and view.OwnedBlocks or{})do if b.State=='Placed'and b.ReadyAt and b.ReadyAt<=now then due=true;break end end
 if not due then return true,0 end
 local ok,result=runtime.Tx:Run({'p:'..player.UserId},function(v)
  local p=v['p:'..player.UserId];runtime.Engine:Authorize(p,player.UserId);L.Normalize(p);local count=0
  for _,b in pairs(p.OwnedBlocks)do if b.State=='Placed'and b.ReadyAt and b.ReadyAt<=now then b.State='Ready';count+=1 end end
  R.Validate(p);return count
 end)
 if ok and result>0 then
  local good,live=pcall(function()return runtime.Engine:Get(player.UserId)end)
  if good and live then runtime.Views[player.UserId]=live end
 end
 return ok,result
end
local function openingPad(player,b,a)
 local yard=Commerce.Yard(player)
 R.Check(yard and yard:GetAttribute('OwnerUserId')==player.UserId,'This is not your yard')
 R.Check(a.YardId==yard:GetAttribute('YardId')and a.YardId==player:GetAttribute('YardId'),'Yard changed; use your own pad')
 R.Check(a.Slot==b.Slot and R.Int(a.Slot,1,C.PlacementSlots),'Block moved; use its Lucky pad')
 local pad=yard:FindFirstChild('LuckyPad_'..b.Slot)
 R.Check(pad and Commerce.Near(player,pad,C.InteractionDistance),'Move closer to your Lucky pad to open this block')
end
function L.Open(player,a)
 local runtime=rt();R.Check(runtime.Ready(player)and runtime.Allow(player,1),'Please wait')
 R.Check(type(a)=='table'and type(a.Uid)=='string'and #a.Uid==32 and a.Uid:match('^%x+$'),'Invalid block UID')
 local uid=a.Uid;local p=runtime.Engine:Get(player.UserId);L.Normalize(p);local b=p.OwnedBlocks[uid]
 if not b then
  local saved=p.BlockOpenReceipts and p.BlockOpenReceipts[uid]
  if saved then return true,R.Copy(saved)end
  return false,'Block already opened or not owned'
 end
 owned(p,uid);openingPad(player,b,a)
 if (b.State~='Placed'and b.State~='Ready')or not b.ReadyAt or b.ReadyAt>os.time()then return false,'Wait for the block timer to finish'end
 -- Only historical paid-random blocks need PolicyService. Normal conveyor/free
 -- Lucky Blocks never yield on PolicyService in their open path.
 R.Check(not b.PaidRandom or rewards().Policy(player),'Paid random items unavailable for this account')
 local pool=b.Pool;local rand=Random.new(b.Seed);local total=0;for _,row in ipairs(pool)do total+=row.Weight end
 local n=rand:NextNumber()*total;local chosen=pool[#pool]
 for _,row in ipairs(pool)do n-=row.Weight;if n<0 then chosen=row;break end end
 R.Check(chosen and runtime.Engine.AssetReady(chosen.Id),'Reward asset unavailable; your block is safe')
 local receipt='block-open:'..uid;local dogUid=guid();local supplyKey='supply:'..chosen.Id
 local keys={'p:'..player.UserId};local needsSupply=serialledDog(chosen.Id);if needsSupply then table.insert(keys,supplyKey)end
 -- The receipt now lives inside the player profile instead of a separate
 -- blockresult:<uid> DataStore key. This keeps retry safety across reconnects
 -- while allowing the overwhelmingly common open to stay on the RAM fast path.
 local ok,result=runtime.Tx:Run(keys,function(v)
  local profile=v['p:'..player.UserId];runtime.Engine:Authorize(profile,player.UserId);L.Normalize(profile)
  local saved=profile.BlockOpenReceipts[uid];if saved then return saved end
  local current=owned(profile,uid);R.Check((current.State=='Placed'or current.State=='Ready')and current.ReadyAt<=os.time(),'Block is not ready');openingPad(player,current,a)
  R.Check(current.Seed==b.Seed,'Block state changed');R.Check(R.Free(profile),'Dog storage full · make room to finish opening')
  local supply=needsSupply and(v[supplyKey]or{})or{Minted=0};if needsSupply then v[supplyKey]=supply end
  local sum=0;for _,row in ipairs(current.Variants)do sum+=row.Weight end
  local roll=rand:NextNumber()*sum;local variant=current.Variants[1].Name
  for _,row in ipairs(current.Variants)do roll-=row.Weight;if roll<0 then variant=row.Name;break end end
  local dog=R.Mint(profile,chosen.Id,dogUid,supply,os.time(),function()return rand:NextNumber()end,'LuckyBlock',variant,true)
  dog.LuckyBlockRarity=current.Tier;dog.PaidRandom=current.PaidRandom
  profile.LuckyOpened[current.Tier]=(profile.LuckyOpened[current.Tier]or 0)+1
  profile.LuckyPity[current.Tier]=chosen.Rank>=Blocks.PitySettings.GoodRank and 0 or (profile.LuckyPity[current.Tier]or 0)+1
  local value={Kind='Dog',UserId=player.UserId,Dog=R.Copy(dog),Tier=current.Tier,At=os.time(),Receipt=receipt,BlockUid=uid}
  table.insert(profile.RewardHistory,1,value);while #profile.RewardHistory>12 do table.remove(profile.RewardHistory)end
  profile.OwnedBlocks[uid]=nil;rememberOpen(profile,uid,value);R.Validate(profile);return value
 end,'bo:'..uid)
 if ok then
  -- Presentation is the critical path: tell the client before doing any full
  -- projection/reconciliation or persistence work.
  local model=L.Models[player.UserId..':'..uid]
  if model then model:SetAttribute('BlockState','Opened');task.delay(.55,function()if model.Parent then model:Destroy()end end);L.Models[player.UserId..':'..uid]=nil end
  if not L.Presented[uid]then L.Presented[uid]=true;RS.RewardPresentation:FireClient(player,{OpenedBlock=result,Cue='Open'})end
  task.defer(function()
   if not player.Parent then return end
   local good,live=pcall(function()return runtime.Engine:Get(player.UserId)end);if good and live then runtime.Views[player.UserId]=live end
   pcall(function()runtime.Refresh(player)end);pcall(function()L.Sync(player)end)
  end)
  task.defer(function()local saved,err=pcall(function()return runtime.Tx:FlushProfile(player.UserId)end);if not saved then warn('Lucky Block async save deferred:',err)end end)
 else local model=L.Models[player.UserId..':'..uid];if model then model:SetAttribute('OpenMessage',tostring(result))end end
 return ok,result
end

local function modelFor(player,b,target)
 local key=player.UserId..':'..b.Uid;local model=L.Models[key]
 if model and model.Parent and model:GetAttribute('BlockState')==b.State then
  return model
 end
 if model then model:Destroy()end
 model=Visual.Build(b.Tier);model.Name='OwnedLuckyBlock';model:ScaleTo(C.VisualScale)
 model:SetAttribute('OwnerUserId',player.UserId);model:SetAttribute('OwnedBlockUid',b.Uid);model:SetAttribute('LuckyBlockTier',b.Tier);model:SetAttribute('LuckySlot',b.Slot);model:SetAttribute('LuckyYardId',b.YardId);model:SetAttribute('BlockState',b.State);model:SetAttribute('ReadyAt',b.ReadyAt);model:SetAttribute('PlacedAt',b.PlacedAt)
 model.Parent=workspace:FindFirstChild('OwnedLuckyBlocks');L.Models[key]=model
 local bb=Instance.new('BillboardGui');bb.Name='BlockTimer';bb.Size=UDim2.fromOffset(180,48);bb.StudsOffset=Vector3.new(0,4,0);bb.MaxDistance=95;bb.Adornee=model.PrimaryPart;bb.Parent=model
 local text=Instance.new('TextLabel');text.Name='TimerText';text.Size=UDim2.fromScale(1,1);text.BackgroundColor3=Color3.fromRGB(17,27,34);text.BackgroundTransparency=.25;text.TextColor3=Color3.fromRGB(255,227,155);text.Font=Enum.Font.FredokaOne;text.TextScaled=true;text.Parent=bb
 model:PivotTo(target.CFrame*CFrame.new(0,target.Size.Y/2+3*C.VisualScale+.1,0))

 return model
end
function L.Sync(player)
 local runtime=rt();local p=runtime.Views[player.UserId];if not p then return end;L.Normalize(p)
 local keep={};local yard=Commerce.Yard(player)
 if yard then
  for slot=1,C.PlacementSlots do
   local pad=yard:FindFirstChild('LuckyPad_'..slot)
   if pad then
    local occupying
    for uid,b in pairs(p.OwnedBlocks)do if (b.State=='Placed'or b.State=='Ready')and b.Slot==slot then occupying=uid;break end end
    pad:SetAttribute('LuckyBlockUid',occupying);pad:SetAttribute('LuckyPadOwner',player.UserId)
    local block=occupying and p.OwnedBlocks[occupying];local ready=block and block.ReadyAt<=os.time()
    pad:SetAttribute('LuckyBlockReady',ready==true)
    local prompt=pad:FindFirstChild('PlaceLuckyBlock');if prompt then prompt.Enabled=occupying==nil or ready==true;prompt.ActionText=ready and 'OPEN BLOCK'or 'CHOOSE BLOCK'end
   end
  end
 end
 for uid,b in pairs(p.OwnedBlocks)do
  if b.State=='Placed'and b.ReadyAt then L.ScheduleReady(player,uid,b.ReadyAt)end
  local target=(b.State=='Placed'or b.State=='Ready')and yard and yard:FindFirstChild('LuckyPad_'..b.Slot)
  if target then local model=modelFor(player,b,target);keep[player.UserId..':'..uid]=true
   if b.State=='Placed'or b.State=='Ready'then model:PivotTo(target.CFrame*CFrame.new(0,target.Size.Y/2+3*C.VisualScale+.1,0))end
  end
 end
 for key,model in pairs(L.Models)do if key:sub(1,#tostring(player.UserId)+1)==player.UserId..':'and not keep[key]then model:Destroy();L.Models[key]=nil end end
end
function L.Start()
 if L.Started then return end;L.Started=true
 local folder=Instance.new('Folder');folder.Name='OwnedLuckyBlocks';folder.Parent=workspace
 for _,y in ipairs(workspace.DOGROTS_District['04_PlayerYards']:GetChildren())do if y:GetAttribute('YardId')then for slot=1,C.PlacementSlots do
  local pad=y:FindFirstChild('LuckyPad_'..slot);assert(pad,'Lucky pad missing')
  local prompt=Instance.new('ProximityPrompt');prompt.Name='PlaceLuckyBlock';prompt.ActionText='CHOOSE BLOCK';prompt.ObjectText='LUCKY PAD '..slot;prompt.RequiresLineOfSight=false;prompt.MaxActivationDistance=11;prompt.Parent=pad
  prompt.Triggered:Connect(function(player)
   local ok,err=pcall(function()
    R.Check(Commerce.Yard(player)==y,'This is not your yard');local p=rt().Views[player.UserId];R.Check(p,'Profile loading');L.Normalize(p)
    local placed
    for _,b in pairs(p.OwnedBlocks)do if (b.State=='Placed'or b.State=='Ready')and b.Slot==slot then placed=b;break end end
    if placed then
     openingPad(player,placed,{Slot=slot,YardId=y:GetAttribute('YardId')})
     R.Check(placed.ReadyAt<=os.time(),'This block is still preparing')
     local opened,value=L.Open(player,{Uid=placed.Uid,Slot=slot,YardId=y:GetAttribute('YardId')})
     if not opened then error(value,0)end
     return
    end
    R.Check(rt().Allow(player,1),'Please wait')
    L.ValidatePad(player,p,{Slot=slot,YardId=y:GetAttribute('YardId')})
    local count=0
    for _,b in pairs(p.OwnedBlocks)do if b.State=='Stored'or b.State=='Carried'then count+=1 end end
    for _,n in pairs(p.LuckyCredits)do count+=n end
    if count==0 then RS.RewardPresentation:FireClient(player,{Message='No Lucky Blocks in Inventory'});return end
    RS.RewardPresentation:FireClient(player,{PadSelector=true,Slot=slot,YardId=y:GetAttribute('YardId')})
   end)
   if not ok then RS.RewardPresentation:FireClient(player,{Message=tostring(err)})end
  end)
 end end end
 Players.PlayerRemoving:Connect(function(p)
  for key,m in pairs(L.Models)do if key:sub(1,#tostring(p.UserId)+1)==p.UserId..':'then m:Destroy();L.Models[key]=nil end end
  for key in pairs(L.ReadyTimers)do if key:sub(1,#tostring(p.UserId)+1)==p.UserId..':'then L.ReadyTimers[key]=nil end end
 end)
 task.spawn(function()while true do task.wait(1)
  for _,p in ipairs(Players:GetPlayers())do if rt().Ready(p)then
   local good,err=pcall(function()
    L.MarkReady(p);L.Sync(p)
   end)
   if not good then warn('Lucky projection deferred:',err)end
  end end
 end end)
end
return L
