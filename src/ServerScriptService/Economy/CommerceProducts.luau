-- Called only by the single ProcessReceipt owner (PurchaseService): Developer Product
-- receipts, and Game Pass grants as synthetic receipts (PurchaseId 'pass:<user>:<pass>').
local RS=game:GetService('ReplicatedStorage');local Run=game:GetService('RunService')
local C=require(RS.CommerceConfig)
local Plans=require(RS.SupplyPricing);local Price=require(RS.PriceFormat)
local Kinds=require(RS.ProductKinds)
local Machine=require(RS.RewardMachineConfig)
local R=require(script.Parent.Rules)
local Supplies=require(script.Parent.SupplyRules)
local Tickets=require(script.Parent.RouletteTickets)
local Config=require(script.Parent.Config)
local P={Presented={}}
local function serverLuck()return require(script.Parent.ServerLuck)end
local function owned(player,p,product)
 return Kinds.Kind(product.Id)=='Pass'and((p.CommercePasses or{})[string.format('%.0f',product.Id)]==true or player:GetAttribute('PassOwned_'..string.format('%.0f',product.Id))==true)
end
-- The pre-prompt check (RewardRequest 'CommerceProduct'): refuse what the receipt could not
-- deliver in full. A receipt itself always grants (it never refuses money already paid).
function P.Product(runtime,player,key)
 R.Check(type(key)=='string'and #key<=60,'Choose an offer')
 local product=C.Find(key)
 R.Check(product and product.Enabled==true and R.Int(product.Id,1,9007199254740990),'Coming soon')
 -- Unpublished Studio simulates purchases (PurchaseService), whatever Roblox says about the Id.
 local studio=Run:IsStudio()and game.GameId==0
 R.Check(studio or Kinds.Status(product.Id)~='Unavailable','This offer is unavailable right now')
 local p=runtime.Engine:Get(player.UserId);local now=os.time()
 R.Check(not owned(player,p,product),'You already own this')
 if product.Supply then
  local def=Config.Supplies[product.Supply];R.Check(def and def.Shop~=false,'Coming soon')
  local stored=math.max(0,Supplies.EndAt(p,product.Supply)-now)
  R.Check(stored+(product.Seconds or def.Seconds)<=C.MaxStoredSupplySeconds,Plans.Duration(C.MaxStoredSupplySeconds)..' of '..def.Name..' already stored; use some first')
 end
 local luck=product.ServerLuck
 if luck then
  local S=serverLuck();local tier=S.Tiers[luck.Multiplier]
  local left=tier and math.max(0,tier.EndsAt-workspace:GetServerTimeNow())or 0
  R.Check(left+luck.Seconds<=S.MaxStackSeconds,'x'..luck.Multiplier..' SERVER LUCK already has '..Price.Clock(left)..' stacked here (max '..Plans.Duration(S.MaxStackSeconds)..')')
 end
 local plan=Plans.Plan(product,Plans.Rate(p,now),true)
 R.Check(p.Cash+plan.Cash<=Config.MaxCash,'Coin storage is full')
 return {ProductId=product.Id,Key=key,Kind=Kinds.Kind(product.Id)or'Product'}
end
-- Paid DOG-O-MATIC spins only help a player who may spend them (tokens on sale and paid
-- random items allowed: the same gate the machine uses); otherwise the row's TokenFallback
-- coins are granted instead. Decided once, before the transaction (never yield inside it).
local function tokensUsable(player,product)
 if not(product.Rewards and(product.Rewards.Tokens or 0)>0)then return true end
 if Machine.FreeOnly==true then return false end
 local ok,allowed=pcall(function()return require(script.Parent.RoulettePurchases).Allowed(player)end)
 return ok and allowed==true
end
function P.Receipt(runtime,player,product,receipt)
 R.Check(receipt.PlayerId==player.UserId and receipt.ProductId==product.Id,'Receipt mismatch')
 local key='purchase:'..receipt.PurchaseId;local now=os.time()
 local usable=tokensUsable(player,product);local fresh,plan=false,nil
 local ok,result=runtime.Tx:Run({'p:'..player.UserId,key},function(v)
  fresh=false
  local old=v[key]
  if old then R.Check(old.User==player.UserId and old.Product==product.Id and old.Kind=='Commerce','Receipt mismatch');return old.Result end
  local p=v['p:'..player.UserId];runtime.Engine:Authorize(p,player.UserId)
  plan=Plans.Plan(product,Plans.Rate(p,now),usable)
  -- Money already paid is never refused: a full wallet only trims the coins.
  plan.Cash=math.clamp(plan.Cash,0,math.max(0,Config.MaxCash-p.Cash))
  R.Check(R.Int(plan.Cash,0,Config.MaxCash)and R.Int(plan.Bones,0,1000000)and R.Int(plan.Tokens,0,1000),'Invalid bundle')
  if plan.Cash>0 then R.Credit(p,plan.Cash,false)end
  if plan.Bones>0 then p.Bones+=plan.Bones end
  for _,supply in ipairs(Config.SupplyOrder)do
   local seconds=plan.Supplies[supply];if seconds and seconds>0 then Supplies.AddPaid(p,supply,now,seconds)end
  end
  if plan.Tokens>0 then Tickets.GrantPaid(p,plan.Tokens,now)end
  R.Validate(p)
  local result={Message=product.Name..' added',Key=product.Key,Cash=plan.Cash,Bones=plan.Bones,Supplies=R.Copy(plan.Supplies),Tokens=plan.Tokens,
   TokenCash=plan.TokenCash,ServerLuck=plan.ServerLuck and R.Copy(plan.ServerLuck)or nil}
  v[key]={Kind='Commerce',User=player.UserId,Product=product.Id,At=now,Result=result}
  fresh=true
  return result
 end)
 if ok then
  runtime.Refresh(player)
  -- Server luck lives in this server's memory: only a FRESH grant switches it on, so a
  -- replayed receipt (here or on another server) never activates it twice.
  local luck=fresh and plan and plan.ServerLuck
  if luck then
   local activated=pcall(function()serverLuck().Activate(luck.Multiplier,luck.Seconds,player.DisplayName)end)
   if not activated then warn('[DOGROTS purchases] server luck activation failed for',receipt.PurchaseId)end
  end
  if not P.Presented[receipt.PurchaseId]and type(result)=='table'then
   P.Presented[receipt.PurchaseId]=true
   local lines=Plans.Lines({Cash=tonumber(result.Cash)or 0,Bones=tonumber(result.Bones)or 0,Supplies=type(result.Supplies)=='table'and result.Supplies or{},
    Tokens=tonumber(result.Tokens)or 0,ServerLuck=result.ServerLuck})
   local reward=RS:FindFirstChild('RewardPresentation')
   if reward then reward:FireClient(player,{Message='THANK YOU! '..product.Name:upper()..(#lines>0 and(' · '..table.concat(lines,' · '))or'')})end
  end
 end
 return ok,result
end
return P
