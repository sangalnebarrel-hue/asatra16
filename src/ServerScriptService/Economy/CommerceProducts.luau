-- Called only by the existing single ProcessReceipt owner.
local RS=game:GetService('ReplicatedStorage')
local C=require(RS.CommerceConfig)
local Pricing=require(RS.DogEconomy.BoostPricing)
local Config=require(script.Parent.Config)
local R=require(script.Parent.Rules)
local Supplies=require(script.Parent.SupplyRules)
local Luck=require(script.Parent.LuckRules)
local P={}
-- Paid luck may be stored longer than coin luck (never lose Robux time).
local PAID_LUCK_CAP=6*3600
-- Older duplicate offers share their original's one-per-player slot.
local function onceKey(product)return product.Alias or product.Key end
P.OnceKey=onceKey
-- Coins a bundle grants this player right now (fixed Cash plus income-scaled Coins).
function P.Coins(product,p,now)
 local rewards=product.Rewards or {}
 return (rewards.Cash or 0)+(rewards.Coins and Pricing.Coins(rewards.Coins,p,now)or 0)
end
function P.Product(runtime,player,key)
 R.Check(type(key)=='string'and #key<=60,'Choose an offer')
 local product=C.Find(key)
 R.Check(product and product.Enabled==true and R.Int(product.Id,1,9007199254740990),'Coming soon')
 local p=runtime.Engine:Get(player.UserId);local now=os.time()
 if product.Supply then R.Check(Supplies.CanAddPaid(p,product.Supply,now,product.Seconds),'Six hours already stored; use some before adding more')end
 if product.Once then R.Check(not(p.CommercePurchases or {})[onceKey(product)],'You already own this pack')end
 -- Only bundles that grant coins care about a full wallet (server luck never does).
 if product.Rewards and(product.Rewards.Coins or product.Rewards.Cash)then R.Check(p.Cash<Config.MaxCash,'Coin storage is full')end
 return {ProductId=product.Id,Key=key}
end
function P.Receipt(runtime,player,product,receipt)
 R.Check(receipt.PlayerId==player.UserId and receipt.ProductId==product.Id,'Receipt mismatch')
 local key='purchase:'..receipt.PurchaseId;local now=os.time()
 local fresh=false
 local ok,result=runtime.Tx:Run({'p:'..player.UserId,key},function(v)
  fresh=false
  local old=v[key]
  if old then R.Check(old.User==player.UserId and old.Product==product.Id and old.Kind=='Commerce','Receipt mismatch');return old.Result end
  local p=v['p:'..player.UserId];runtime.Engine:Authorize(p,player.UserId);R.Normalize(p,player.UserId,now)
  local result={Message=product.Name..' added',Key=product.Key}
  if product.Supply then Supplies.AddPaid(p,product.Supply,now,product.Seconds)
  else
   local rewards=assert(product.Rewards,'Missing rewards')
   -- A paid receipt never fails on a full wallet: the coins fill it to the brim instead.
   local coins=math.clamp(P.Coins(product,p,now),0,Config.MaxCash-p.Cash)
   R.Check(R.Int(coins,0,Config.MaxCash)and R.Int(rewards.Bones or 0,0,1000000),'Invalid bundle')
   if coins>0 then R.Credit(p,coins,false)end
   p.Bones+=(rewards.Bones or 0)
   for supply,seconds in pairs(rewards.Supplies or {})do Supplies.AddPaid(p,supply,now,seconds)end
   if rewards.Luck then Luck.Add(p,rewards.Luck.Tier,rewards.Luck.Seconds,now,PAID_LUCK_CAP)end
   if product.Once then p.CommercePurchases=p.CommercePurchases or {};p.CommercePurchases[onceKey(product)]=now end
   result.Coins=coins;result.Bones=rewards.Bones
  end
  R.Validate(p)
  v[key]={Kind='Commerce',User=player.UserId,Product=product.Id,At=now,Result=result}
  fresh=true
  return result
 end)
 if ok then
  runtime.Refresh(player)
  -- Server luck lives in this server's memory: applied once, after the receipt is saved.
  local serverLuck=product.Rewards and product.Rewards.ServerLuck
  if fresh and serverLuck then
   require(script.Parent.ServerLuck).Add(serverLuck.Multiplier,serverLuck.Seconds,player.DisplayName,player.UserId)
  end
  RS.RewardPresentation:FireClient(player,{Cue='Reward',Message=type(result)=='table'and result.Message or product.Name..' added'})
 end
 return ok,result
end
return P
