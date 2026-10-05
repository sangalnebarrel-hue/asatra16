local RS=game:GetService('ReplicatedStorage');local Players=game:GetService('Players');local Policy=game:GetService('PolicyService');local Http=game:GetService('HttpService')
local C=require(RS.LuckyBlockConfig);local D=require(script.Parent.DogDefinitions);local R=require(script.Parent.Rules)
local S={Blocks={},Policies={},PresentedReceipts={},Offers={}};local rng=Random.new();local Runtime
local function rt()Runtime=Runtime or require(script.Parent.Runtime);return Runtime end
local function normalize(p)p.LuckyCredits=p.LuckyCredits or {};p.LuckyOpened=p.LuckyOpened or {};p.LuckyPity=p.LuckyPity or {};p.RewardHistory=p.RewardHistory or {} end
function S.Policy(player)
 local old=S.Policies[player.UserId];if old and os.clock()-old.At<120 then return old.Allowed end
 local ok,result=pcall(function()return Policy:GetPolicyInfoForPlayerAsync(player)end)
 local allowed=ok and result.ArePaidRandomItemsRestricted==false
 S.Policies[player.UserId]={At=os.clock(),Allowed=allowed};return allowed
end
function S.Pool(p,tier)
 local weights=C.RewardPools[tier];R.Check(weights,'Unknown block rarity');local pool,total,groups={},0,{}
 for id,def in pairs(D)do
  -- Acquisition is gated by block tier; its rewards retain the advertised odds at every depth.
  if def.CanDropFromLuckyBlock==true and not def.OG and R.Available(def,os.time()) and rt().Engine.AssetReady(id)then
   groups[def.Rank]=groups[def.Rank]or{};table.insert(groups[def.Rank],def)
  end
 end
 for rank,members in pairs(groups)do
  local groupWeight=weights[rank]or 0
  if groupWeight>0 then
   local weight=groupWeight/#members
   for _,def in ipairs(members)do table.insert(pool,{Id=def.Id,Name=def.DisplayName,Rarity=def.Rarity,Rank=rank,Weight=weight})end
   total+=groupWeight
  end
 end
 table.sort(pool,function(a,b)return a.Id<b.Id end)
 R.Check(total>0,'No released rewards at your current layer')
 for _,row in ipairs(pool)do row.Chance=row.Weight/total end
 return pool,total
end
local function choose(pool,total,random)
 local n=random()*total;for _,r in ipairs(pool)do n-=r.Weight;if n<0 then return r end end;return pool[#pool]
end
local function keys(user,extra)
 local k={'p:'..user,extra};for id,def in pairs(D)do if def.Available and def.SupplyType=='Permanent' and not def.OG then table.insert(k,'supply:'..id)end end;return k
end
local function remember(p,result)
 table.insert(p.RewardHistory,1,result);while #p.RewardHistory>12 do table.remove(p.RewardHistory)end
end
function S.OddsVersion(p)return tostring(C.Version)..':'..tostring(p.CurrentLayer)..':'..(require(RS.WorldEvents.WorldEventModifiers).Current or 'NORMAL')end
function S.Acquire(player,tier,operation,block,oddsVersion)
 return require(script.Parent.LuckyLifecycle).Acquire(player,tier,operation,block,oddsVersion)
end
function S.CancelOffer(player,uid)
 local current=S.Offers[player.UserId]
 if not current or(uid and current~=uid)then return end
 local block=S.Blocks[current]
 if block and block:GetAttribute('OfferUserId')==player.UserId and not block:GetAttribute('PurchaseBusy')then
  block:SetAttribute('OfferUserId',nil);block:SetAttribute('OfferUntil',nil);block:SetAttribute('OfferOrigin',nil)
 end
 S.Offers[player.UserId]=nil
end
-- Physical ownership is checked again inside the durable acquisition transaction.
function S.ValidateOffer(player,block)
 local uid=block and block:GetAttribute('BlockUid')
 if not uid or S.Blocks[uid]~=block or not block.Parent or block:GetAttribute('State')~='OnLine'then return false end
 local c=player.Character;local root=c and c:FindFirstChild('HumanoidRootPart');local hum=c and c:FindFirstChildOfClass('Humanoid')
 return root~=nil and hum~=nil and hum.Health>0 and(root.Position-block:GetPivot().Position).Magnitude<=18
end
S.Buying={};S.NextBuy={}
function S.PurchaseAtPrompt(player,block)
 local runtime=rt();local user=player.UserId
 if not runtime.Ready(player)then return false,'LOADING INVENTORY'end
 if S.Buying[user]or os.clock()<(S.NextBuy[user]or 0)then return false,'PLEASE WAIT'end
 if not S.ValidateOffer(player,block)then return false,'MOVE CLOSER'end
 if block:GetAttribute('PurchaseBusy')then return false,'PLEASE WAIT'end
 local uid=block:GetAttribute('BlockUid');local tier=block:GetAttribute('LuckyBlockRarity')
 S.Buying[user]=true;S.NextBuy[user]=os.clock()+.8;block:SetAttribute('PurchaseBusy',true)
 local transport,ok,value=pcall(function()return S.Acquire(player,tier,uid,block,nil)end)
 S.Buying[user]=nil
 if block.Parent then block:SetAttribute('PurchaseBusy',false)end
 if not transport then return false,'TRY AGAIN'end
 if not ok then
  local message=tostring(value):lower()
  if message:find('cash',1,true)then return false,'NOT ENOUGH COINS'
  elseif message:find('full',1,true)then return false,'INVENTORY FULL'
  else return false,'PLEASE WAIT'end
 end
 return true,value
end
function S.Register(block,tier)
 if block:GetAttribute('BlockUid')and S.Blocks[block:GetAttribute('BlockUid')]==block then return block end
 local uid=Http:GenerateGUID(false):gsub('-','');block:SetAttribute('BlockUid',uid);block:SetAttribute('LuckyBlockRarity',tier);block:SetAttribute('State','OnLine');S.Blocks[uid]=block
 block.Destroying:Connect(function()S.Blocks[uid]=nil end)
 local pr=Instance.new('ProximityPrompt');pr.Name='LuckyPrompt';pr.ActionText='BUY BLOCK';pr.ObjectText=tier:upper()..' BLOCK · '..require(RS.PriceFormat).Coins(C.ConveyorPrices[tier]);pr.MaxActivationDistance=12;pr.RequiresLineOfSight=false;pr.HoldDuration=0;pr.Parent=block.PrimaryPart
 pr.Triggered:Connect(function(player)
  local ok,message=S.PurchaseAtPrompt(player,block)
  if not ok and block.Parent then RS.RewardPresentation:FireClient(player,{PromptFeedback={BlockUid=uid,Text=message}})end
 end)
 if C.Rank(tier)>=C.AnnouncementSettings.MinimumRank and os.clock()-(S.LastAnnouncement or -60)>C.AnnouncementSettings.Cooldown then
  S.LastAnnouncement=os.clock();RS.RewardPresentation:FireAllClients({Announcement=tier:upper()..' LUCKY BLOCK ON THE TONGUE',Tier=tier})
 end
 return block
end
function S.Receipt(runtime,player,product,receipt)
 local key='purchase:'..receipt.PurchaseId
 local ok,result=runtime.Tx:Run({'p:'..player.UserId,key},function(v)
  local p=v['p:'..player.UserId];runtime.Engine:Authorize(p,player.UserId);normalize(p)
  if v[key]then R.Check(v[key].User==player.UserId and v[key].Product==product.Id,'Receipt mismatch');return 'Already granted'end
  require(script.Parent.LuckyLifecycle).AddStored(p,product.Tier,product.Count,'Purchase',true)
  v[key]={User=player.UserId,Product=product.Id,At=os.time()};R.Validate(p);return 'Blocks added'
 end)
 if ok then
  runtime.Refresh(player)
  if not S.PresentedReceipts[receipt.PurchaseId]then S.PresentedReceipts[receipt.PurchaseId]=true;RS.RewardPresentation:FireClient(player,{Credits=true,Tier=product.Tier,Count=product.Count})end
 end
 return ok,result
end
function S.Start()
 if S.Started then return end;S.Started=true
 local remote=RS.RewardRequest
 remote.OnServerInvoke=function(player,action,a)
  local runtime=rt();if not runtime.Ready(player)then return false,'Loading your profile'end
  if type(action)~='string' or type(a)~='table'then return false,'Invalid request'end
  action=({RouletteInfo='RewardMachineInfo',RouletteSpin='RewardMachineActivate',RouletteProduct='RewardMachineProduct'})[action]or action
  local ok,success,result=pcall(function()
   if action=='Catalog'then
    if not runtime.Allow(player,1)then return false,'Please wait'end
    local p=runtime.Engine:Get(player.UserId);normalize(p);local odds={}
    for _,tier in ipairs(C.Rarities)do odds[tier]=S.Pool(p,tier)end
    return true,{Odds=odds,Credits=p.LuckyCredits,Opened=p.LuckyOpened,History=p.RewardHistory,PaidAllowed=S.Policy(player),Variants=require(RS.WorldEvents.WorldEventModifiers).MutationRows(require(script.Parent.Config).Variants,'Name','Weight',os.time()),OddsVersion=S.OddsVersion(p)}
   elseif action=='CancelBlockOffer'then
    R.Check(type(a.BlockUid)=='string'and #a.BlockUid==32,'Invalid block');S.CancelOffer(player,a.BlockUid);return true,{Message='Offer closed'}
   elseif action=='BuyBlock'then
    R.Check(type(a.BlockUid)=='string'and #a.BlockUid==32 and a.BlockUid:match('^%x+$'),'Invalid block')
    -- The server resolves the current price and pool at the prompt.
    return S.PurchaseAtPrompt(player,S.Blocks[a.BlockUid],a.OddsVersion)
   elseif action=='OpenBlock'then return require(script.Parent.LuckyLifecycle).Open(player,a)
   elseif action=='PlaceBlock'then return require(script.Parent.LuckyLifecycle).Action(player,action,a)
   elseif action=='CommerceProduct'then
    R.Check(runtime.Allow(player,1),'Please wait');return true,require(script.Parent.CommerceProducts).Product(runtime,player,a.Key)
   elseif action=='PaidProduct'then
    if not runtime.Allow(player,1)or not S.Policy(player)then return false,'Unavailable for this account'end
    for _,p in ipairs(C.RobuxProducts)do if p.Key==a.Key and p.Id>0 then return true,{ProductId=p.Id}end end
    return false,'This offer is not on sale'
   elseif action=='RewardMachineInfo'or action=='RewardMachineProduct'then return require(script.Parent.RewardMachineService).Request(player,action,a)
   elseif action=='RewardMachineActivate'then
    local machine=require(script.Parent.RewardMachineService)
    if not machine.RequestWorldSpin then return false,'DOG-O-MATIC is loading; please retry'end
    return machine.RequestWorldSpin(player,a)
   end
   return false,'Unknown action'
  end)
  if not ok then return false,tostring(success)end;return success,result
 end
 Players.PlayerRemoving:Connect(function(p)S.CancelOffer(p);S.Policies[p.UserId]=nil;S.Buying[p.UserId]=nil;S.NextBuy[p.UserId]=nil end)
 print('DOGROTS_REWARD_SERVICE_READY')
end
return S
