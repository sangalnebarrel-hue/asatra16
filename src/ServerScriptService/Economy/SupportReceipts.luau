-- Only called by the existing ProcessReceipt handler after a successful grant.
local Stats=require(script.Parent.LifetimeStats)
local S={}
function S.Configured(id)
 for _,p in ipairs(require(game.ReplicatedStorage.CommerceConfig).Products)do if p.Id>0 and(id==nil or p.Id==id)then return true end end
 for _,p in ipairs(require(script.Parent.ShopDefinitions))do
  if p.Kind=='Product' and p.Id>0 and (id==nil or p.Id==id)then return true end
 end
 for _,p in ipairs(require(game.ReplicatedStorage.LuckyBlockConfig).RobuxProducts)do
  if p.Id>0 and (id==nil or p.Id==id)then return true end
 end
 for _,p in ipairs(require(game.ReplicatedStorage.RewardMachineConfig).TicketProducts or{})do
  if p.Id>0 and (id==nil or p.Id==id)then return true end
 end
 return false
end
function S.Record(runtime,receipt)
 if not S.Configured(receipt.ProductId)then return false end
 local amount=receipt.CurrencySpent
 if type(amount)~='number'or amount~=amount or amount<0 or amount%1~=0 or amount>9000000000000000 then return false end
 if receipt.CurrencyType~=Enum.CurrencyType.Robux then return false end
 if type(receipt.PurchaseId)~='string'or #receipt.PurchaseId==0 or #receipt.PurchaseId>100 then return false end
 local id=receipt.PlayerId;local key='support-receipt:'..receipt.PurchaseId;local profile='p:'..id
 local transport,ok=pcall(function()
  return runtime.Tx:Run({profile,key},function(v)
   if v[key]then
    assert(v[key].User==id and v[key].Product==receipt.ProductId and v[key].Amount==amount,'Support receipt mismatch')
    return 'Already counted'
   end
   local p=v[profile];runtime.Engine:Authorize(p,id)
   Stats.Add(p,'SupportRobux',amount)
   v[key]={User=id,Product=receipt.ProductId,Amount=amount,At=os.time()}
   return 'Counted'
  end)
 end)
 return transport and ok==true
end
return S
