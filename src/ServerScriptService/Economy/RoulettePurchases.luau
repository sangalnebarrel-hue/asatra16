-- Paid-ticket catalog and fulfillment (Lucky Spin packs). Only PurchaseService.ProcessReceipt grants.
local RS=game:GetService('ReplicatedStorage')
local Players=game:GetService('Players')
local Policy=game:GetService('PolicyService')
local C=require(RS.RewardMachineConfig)
local R=require(script.Parent.Rules)
local Tickets=require(script.Parent.RouletteTickets)
local P={PolicyCache={}}
function P.Allowed(player)
 if C.FreeOnly then return false end
 local old=P.PolicyCache[player.UserId]
 if old and os.clock()-old.At<60 then return old.Allowed end
 local ok,result=pcall(function()return Policy:GetPolicyInfoForPlayerAsync(player)end)
 local allowed=ok and type(result)=='table'and result.ArePaidRandomItemsRestricted==false
 P.PolicyCache[player.UserId]={At=os.clock(),Allowed=allowed==true}
 return allowed==true
end
function P.Catalog(player)
 local allowed=P.Allowed(player);local rows={}
 for _,product in ipairs(C.TicketProducts or{})do
  local configured=R.Int(product.Id,1,9007199254740990)and R.Int(product.Count,1,1000000)
  local active=not C.FreeOnly and configured and product.Enabled==true
  table.insert(rows,{Key=product.Key,Name=product.Name,Count=product.Count,ProductId=product.Id,
   Configured=configured==true,CanPurchase=active and allowed,
   UnavailableReason=C.FreeOnly and 'DOG TOKENS are free and cannot be purchased'or not configured and 'Coming soon' or not active and 'Not on sale' or not allowed and 'Unavailable for this account' or nil})
 end
 return rows,allowed
end
function P.Product(player,key)
 R.Check(not C.FreeOnly,'DOG TOKENS are free and cannot be purchased')
 R.Check(type(key)=='string'and #key<=60,'Choose a ticket pack')
 local rows=P.Catalog(player)
 for _,row in ipairs(rows)do if row.Key==key then
  R.Check(row.CanPurchase,row.UnavailableReason)
  return {ProductId=row.ProductId,Key=row.Key,Count=row.Count}
 end end
 error('Unknown ticket pack',0)
end
function P.Receipt(runtime,player,product,receipt)
 R.Check(receipt.PlayerId==player.UserId and receipt.ProductId==product.Id,'Ticket receipt mismatch')
 R.Check(type(receipt.PurchaseId)=='string'and #receipt.PurchaseId>0 and #receipt.PurchaseId<=100,'Invalid ticket receipt')
 R.Check(R.Int(product.Count,1,1000000),'Invalid ticket quantity')
 local key='purchase:'..receipt.PurchaseId
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
  local result={Message=product.Count..(product.Count==1 and ' DOG TOKEN added'or ' DOG TOKENS added')..' · spin at the DOG-O-MATIC',Count=product.Count,PaidTickets=p.PaidRouletteTickets}
  values[key]={Kind='RouletteTickets',User=player.UserId,Product=product.Id,Count=product.Count,At=os.time(),Result=result}
  return result
 end)
 -- Receipt fulfillment deliberately ignores present-day policy and sale switches:
 -- a completed purchase always credits the balance; use stays policy-gated.
 if ok then runtime.Refresh(player)end
 return ok,result
end
Players.PlayerRemoving:Connect(function(player)P.PolicyCache[player.UserId]=nil end)
return P
