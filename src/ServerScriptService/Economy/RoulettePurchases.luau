-- DOG TOKEN packs (Lucky Spin 1, Lucky Bundle 5, Mega Spin Bundle 15). Selling and spending
-- need PolicyService to allow paid random items; only PurchaseService.ProcessReceipt grants.
local RS=game:GetService('ReplicatedStorage')
local Players=game:GetService('Players')
local Policy=game:GetService('PolicyService')
local C=require(RS.RewardMachineConfig)
local R=require(script.Parent.Rules)
local Tickets=require(script.Parent.RouletteTickets)
local P={PolicyCache={}}
local CACHE=60
function P.Allowed(player)
 if C.FreeOnly then return false end
 local old=P.PolicyCache[player.UserId]
 if old and os.clock()-old.At<CACHE then return old.Allowed end
 local ok,result=pcall(function()return Policy:GetPolicyInfoForPlayerAsync(player)end)
 local allowed=ok and type(result)=='table'and result.ArePaidRandomItemsRestricted==false
 P.PolicyCache[player.UserId]={At=os.clock(),Allowed=allowed==true}
 return allowed==true
end
-- The cached answer without yielding (nil when unknown or stale).
function P.Cached(player)
 if C.FreeOnly then return false end
 local old=P.PolicyCache[player.UserId]
 if old and os.clock()-old.At<CACHE then return old.Allowed end
 return nil
end
P.RestrictedReason='DOG-O-MATIC gives random rewards, and buying or using paid random items is not available for this account. Your free DOG TOKEN still works; tokens you own are kept.'
function P.Catalog(player)
 local allowed=P.Allowed(player);local rows={}
 for _,product in ipairs(C.TicketProducts or{})do
  local configured=R.Int(product.Id,1,9007199254740990)and R.Int(product.Count,1,1000000)
  local active=not C.FreeOnly and configured and product.Enabled==true
  table.insert(rows,{Key=product.Key,Name=product.Name,Count=product.Count,ProductId=product.Id,Route='RewardMachineProduct',
   Configured=configured==true,CanPurchase=active and allowed,
   UnavailableReason=C.FreeOnly and 'DOG TOKEN sales are paused'or not configured and 'Coming soon' or not active and 'Not on sale' or not allowed and 'Unavailable for this account' or nil})
 end
 return rows,allowed
end
function P.Product(player,key)
 R.Check(not C.FreeOnly,'DOG TOKEN sales are paused')
 R.Check(type(key)=='string'and #key<=60,'Choose a DOG TOKEN pack')
 local rows=P.Catalog(player)
 for _,row in ipairs(rows)do if row.Key==key then
  R.Check(row.CanPurchase,row.UnavailableReason)
  return {ProductId=row.ProductId,Key=row.Key,Count=row.Count}
 end end
 error('Unknown DOG TOKEN pack',0)
end
local function message(product)
 return '+'..product.Count..(product.Count==1 and ' DOG TOKEN'or' DOG TOKENS')..' · '..tostring(product.Name or 'DOG-O-MATIC')..' · spin at DOG-O-MATIC'
end
-- A receipt-shaped table: PurchaseId is the idempotency key, so a caller granting a Game Pass
-- version of a pack can pass {PlayerId,ProductId,PurchaseId='pass:<user>:<id>'}.
function P.Receipt(runtime,player,product,receipt)
 R.Check(receipt.PlayerId==player.UserId and receipt.ProductId==product.Id,'Ticket receipt mismatch')
 R.Check(type(receipt.PurchaseId)=='string'and #receipt.PurchaseId>0 and #receipt.PurchaseId<=100,'Invalid ticket receipt')
 R.Check(R.Int(product.Count,1,1000000),'Invalid ticket quantity')
 local key='purchase:'..receipt.PurchaseId
 local fresh=false
 -- Fresh transaction attempt IDs permit retry after a transient abort. The durable
 -- purchase key is the deduplication identity across servers, sessions and retries.
 local ok,result=runtime.Tx:Run({'p:'..player.UserId,key},function(values)
  local old=values[key]
  if old then
   R.Check(old.User==player.UserId and old.Product==product.Id and old.Kind=='RouletteTickets','Receipt mismatch')
   return old.Result
  end
  local p=values['p:'..player.UserId];runtime.Engine:Authorize(p,player.UserId)
  Tickets.GrantPaid(p,product.Count,os.time());R.Validate(p)
  local result={Message=message(product),Count=product.Count,PaidTickets=p.PaidRouletteTickets}
  values[key]={Kind='RouletteTickets',User=player.UserId,Product=product.Id,Count=product.Count,At=os.time(),Result=result}
  fresh=true
  return result
 end)
 -- Receipt fulfillment deliberately ignores present-day policy and sale switches:
 -- a completed purchase always credits the balance; use stays policy-gated.
 if ok then
  runtime.Refresh(player)
  -- A toast for the buyer; RewardMachineTokens makes an open DOG-O-MATIC window refetch.
  local remote=RS:FindFirstChild('RewardPresentation')
  if fresh and remote and player.Parent then
   remote:FireClient(player,{Message=result.Message,RewardMachineTokens={Paid=result.PaidTickets,Added=product.Count}})
  end
 end
 return ok,result
end
Players.PlayerRemoving:Connect(function(player)P.PolicyCache[player.UserId]=nil end)
return P
