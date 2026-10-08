local RS=game:GetService('ReplicatedStorage');local Http=game:GetService('HttpService')
local C=require(RS.RewardMachineConfig);local E=require(RS.DogEconomy.Config)
local Odds=require(RS.RewardMachineOdds)
local R=require(script.Parent.Rules);local I=require(script.Parent.ItemRules);local D=require(script.Parent.DogDefinitions)
local Tickets=require(script.Parent.RouletteTickets)
local Purchases=require(script.Parent.RoulettePurchases)
local Pricing=require(RS.DogEconomy.BoostPricing);local Format=require(RS.PriceFormat)
local S={};local rng=Random.new()
function S.Pool(p,runtime,now)
 local rows,requiredReason={},nil;now=now or os.time()
 for prizeIndex,row in ipairs(C.Rewards)do
  local enabled=true
  if row.Kind=='Dog'then
   local d=D[row.Id]
   enabled=d and d.SupplyType=='Permanent'and not d.OG and d.CanDropFromRoulette~=false and R.Available(d,now,p.CurrentLayer)and runtime.Engine.AssetReady(row.Id)
  elseif row.Kind=='Item'then
   local d=I.Definitions[row.Id];enabled=d and d.Depth<=p.CurrentLayer and d.Class~='Secret'and d.CanDropFromRoulette~=false
  end
  -- A configured fixed ultra rare reward is never silently removed or renormalized.
  -- Keep its honest advertised chance, but stop the spin before spending if
  -- its imported asset is unavailable on this server.
  if not enabled and row.Required then requiredReason='Aurion is preparing to arrive. Please try again shortly.'end
  if (enabled or row.Required)and(row.Weight>0 or(row.FixedUnits or 0)>0)then
   local view=R.Copy(row);view.PrizeIndex=prizeIndex
   -- A coin bag holds minutes of this player's income: the same amount is shown and paid.
   if row.Kind=='Cash'and row.Coins then
    view.Amount=Pricing.Coins(row.Coins,p,now);view.Name=Format.Number(view.Amount)..' Coins'
   end
   if row.Kind=='Dog'and D[row.Id]then view.Rarity=D[row.Id].Rarity;view.Rank=D[row.Id].Rank
   elseif row.Kind=='Item'then view.Rarity=I.Definitions[row.Id].Class end
   table.insert(rows,view)
  end
 end
 if #rows==0 then return {},0,'Rewards are temporarily unavailable'end
 local pool,total=Odds.Build(rows,C.OddsDenominator)
 return pool,total,requiredReason
end
-- Validate every advertised outcome before consuming a ticket. Inventory capacity
-- never secretly changes the weights, and a failed delivery cannot eat a ticket.
local function deliveryReason(p,pool,now)
 for _,row in ipairs(pool)do
  if row.Kind=='Dog'and not R.Free(p)then return 'Make one free space in Dogs first'
  elseif row.Kind=='Item'and not I.Free(p)then return 'Make one free space in Inventory first'
  elseif row.Kind=='Cash'and p.Cash+row.Amount>E.MaxCash then return 'Make room in your coin wallet first'
  elseif row.Kind=='Bones'and p.Bones+row.Amount>E.MaxCash then return 'Make room in your bone wallet first'
  elseif row.Kind=='Boost'then
   local def=E.Supplies[row.Id]
   if not def then return 'A reward is temporarily unavailable'end
   if math.max(now,(p.Supplies or{})[row.Id]or 0)+row.Duration>now+def.MaxSeconds then
    return 'Wait until '..def.Name..' has room for the full '..math.floor(row.Duration/60)..'-minute reward'
   end
  end
 end
end
function S.Info(p,runtime,now,paidAllowed)
 now=now or os.time();local pool,total,requiredReason=S.Pool(p,runtime,now)
 local free,deadline=Tickets.State(p,now);local paid=Tickets.Paid(p);local count=C.FreeOnly and free or free+paid
 local reason=requiredReason or(total<=0 and 'Rewards are temporarily unavailable')or deliveryReason(p,pool,now)
 if not reason and count<C.TicketCost then reason='Your free DOG TOKEN is still recharging'end
 if not reason and not C.FreeOnly and free<C.TicketCost and paidAllowed~=true then reason='Paid random tickets are unavailable for this account; your tickets are kept'end
 if not reason and now<(p.NextRouletteAt or 0)then reason='Please wait for this activation to finish'end
 return {Cost=0,TicketCost=C.TicketCost,Tickets=count,FreeTickets=free,PaidTickets=paid,MaxFreeTickets=C.TicketCapacity,MaxTickets=C.TicketCapacity,
  NextTicketAt=deadline,NextFreeTicketAt=deadline,SpendOrder=C.FreeOnly and 'FreeOnly'or'FreeFirst',FreeOnly=C.FreeOnly==true,PaidRandomAllowed=paidAllowed==true,
  PaidRandomRestrictionReason=paidAllowed~=true and 'Paid tickets are unavailable for this account. Free tickets still work.'or nil,
  TicketRefillSeconds=C.TicketRefillSeconds,ServerNow=now,NextSpinAt=p.NextRouletteAt or 0,
  Rewards=pool,OddsDenominator=C.OddsDenominator,CanSpin=reason==nil,UnavailableReason=reason,
  TicketDescription=C.FreeOnly and 'One free DOG TOKEN every 5 hours after use. Holds one. DOG TOKENS cannot be purchased.'
   or 'One free DOG TOKEN every 5 hours after use (holds one). Extra tokens: Lucky Spin packs in the PAW MARKET. Free tokens are always used first.'}
end
-- Server-only pure transaction body. It can be tested against the existing
-- transaction journal without bypassing the remote/world authorization gates.
function S.Resolve(v,userId,key,uid,now,runtime,paidAllowed,random,forced)
 local p=v['p:'..userId];runtime.Engine:Authorize(p,userId)
 if v[key]then return v[key]end
 R.Normalize(p,userId,now)
 local info=S.Info(p,runtime,now,paidAllowed);R.Check(info.CanSpin,info.UnavailableReason)
 local pool=info.Rewards;local roll=function()return random:NextNumber()end
 -- Exactly one uniformly sampled integer maps to each of the 10,000 slots.
 -- A free activation may preselect the row from the RAM snapshot so the fast
 -- transaction only needs the one supply key that can actually win.
 local slot=random:NextInteger(1,C.OddsDenominator)
 local chosen
 if type(forced)=='table'then
  for _,row in ipairs(pool)do
   if row.PrizeIndex==forced.PrizeIndex and row.Kind==forced.Kind and row.Id==forced.Id and row.Name==forced.Name then chosen=row;break end
  end
  R.Check(chosen,'Reward pool changed; please activate again')
 else chosen=Odds.Pick(pool,slot,C.OddsDenominator)end
 local _,_,ticketType=Tickets.Consume(p,now,paidAllowed)
 local result={Kind=chosen.Kind,Id=chosen.Id,Name=chosen.Name,Receipt=key,At=now,Chance=chosen.Chance,ChanceUnits=chosen.ChanceUnits,ChanceText=chosen.ChanceText,Jackpot=chosen.Jackpot==true,Rarity=chosen.Rarity,PrizeIndex=chosen.PrizeIndex,
  TicketCost=C.TicketCost,TicketType=ticketType,PaidRandom=ticketType=='Paid'}
 if chosen.Kind=='Dog'then
  local supply=v['supply:'..chosen.Id]or {};v['supply:'..chosen.Id]=supply
  local dog=R.Mint(p,chosen.Id,uid,supply,now,roll,'Roulette');dog.PricePaid=0;dog.PaidRandom=ticketType=='Paid';result.Dog=R.Copy(dog)
 elseif chosen.Kind=='Item'then
  local item=I.Mint(p,I.Definitions[chosen.Id],chosen.Chance,uid,now,roll,{})
  item.Origin='Roulette';item.PaidRandom=ticketType=='Paid';result.Item=R.Copy(item)
 elseif chosen.Kind=='Cash'then R.Credit(p,chosen.Amount);result.Amount=chosen.Amount
 elseif chosen.Kind=='Bones'then p.Bones+=chosen.Amount;result.Amount=chosen.Amount
 elseif chosen.Kind=='Boost'then
  p.Supplies[chosen.Id]=math.max(now,p.Supplies[chosen.Id]or 0)+chosen.Duration
  result.Boost=chosen.Id;result.Duration=chosen.Duration
 end
 p.NextRouletteAt=now+C.Cooldown;p.RewardHistory=p.RewardHistory or {}
 result.FreeTickets=p.RouletteTickets;result.PaidTickets=p.PaidRouletteTickets;result.Tickets=C.FreeOnly and p.RouletteTickets or p.RouletteTickets+p.PaidRouletteTickets;result.NextSpinAt=p.NextRouletteAt
 result.NextTicketAt=p.NextRouletteTicketAt;result.NextFreeTicketAt=p.NextRouletteTicketAt
 table.insert(p.RewardHistory,1,result);while #p.RewardHistory>12 do table.remove(p.RewardHistory)end
 R.Validate(p);v[key]=result;return result
end
function S.Request(player,action,a,worldAuthorized)
 action=({RouletteInfo='RewardMachineInfo',RouletteSpin='RewardMachineActivate',RouletteProduct='RewardMachineProduct'})[action]or action
 local runtime=require(script.Parent.Runtime)
 if not runtime.Ready(player)or not runtime.Allow(player,1)then return false,'Please wait'end
 if action=='RewardMachineProduct'then
  if type(a)~='table'then return false,'Choose a ticket pack'end
  return true,Purchases.Product(player,a.Key)
 end
 if action=='RewardMachineInfo'then
  local products,allowed=Purchases.Catalog(player)
  local info=S.Info(runtime.Engine:Get(player.UserId),runtime,os.time(),allowed);info.TicketProducts=products
  if S.WorldEligibility then
   local eligible,reason=S.WorldEligibility(player);info.InRange=eligible==true
   if not info.InRange then info.CanSpin=false;info.UnavailableReason=reason or 'Move closer to DOG-O-MATIC'end
  end
  return true,info
 end
 if action~='RewardMachineActivate'then return false,'Unknown machine action'end
 if not worldAuthorized then return false,'Use the drum at DOG-O-MATIC PLAZA'end
 if type(a)~='table'or type(a.Request)~='string'or #a.Request~=32 or not a.Request:match('^%x+$')then return false,'Invalid activation'end
 -- Release is free-only. Never yield on PolicyService for an activation that
 -- cannot spend a paid random ticket.
 local paidAllowed=false;if not C.FreeOnly then paidAllowed=Purchases.Allowed(player)end
 local now=os.time();local userId=player.UserId;local profile=runtime.Engine:Get(userId)
 runtime.Engine:Authorize(profile,userId);R.Normalize(profile,userId,now)
 local preview=S.Info(profile,runtime,now,paidAllowed);R.Check(preview.CanSpin,preview.UnavailableReason)
 local seed=rng:NextInteger(1,2147483646);local picker=Random.new(seed)
 local chosen=Odds.Pick(preview.Rewards,picker:NextInteger(1,C.OddsDenominator),C.OddsDenominator)
 R.Check(chosen,'Rewards are temporarily unavailable')
 local key='rs:'..userId..':'..a.Request:sub(1,26);local keys={'p:'..userId}
 if chosen.Kind=='Dog'then
  local def=D[chosen.Id]
  -- Rank 1/2 permanent dogs have no serial/edition state, so a global supply
  -- counter would only add latency. Aurion/high-rank rewards keep unique serials.
  local serialled=def and(def.Rank>=3 or def.SupplyType~='Permanent'or(def.FirstEditionLimit or 0)>0 or(def.LimitedSupply or 0)>0)
  if serialled then table.insert(keys,'supply:'..chosen.Id)end
 end
 local uid=Http:GenerateGUID(false):gsub('-','')
 local operation='ra:'..userId..':'..a.Request:sub(1,26)
 local ok,result=runtime.Tx:Run(keys,function(v)
  return S.Resolve(v,userId,key,uid,now,runtime,paidAllowed,Random.new(seed),chosen)
 end,operation)
 if ok then
  -- Return to the client first. Projection and durability happen behind the spin,
  -- not in front of the animation.
  task.defer(function()if player.Parent then runtime.Refresh(player)end end)
  task.defer(function()local saved,err=pcall(function()return runtime.Tx:FlushProfile(userId)end);if not saved then warn('DOG-O-MATIC async save deferred:',err)end end)
 end
 return ok,result
end
return S
