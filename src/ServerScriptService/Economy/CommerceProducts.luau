-- Called only by the existing single ProcessReceipt owner.
local C=require(game.ReplicatedStorage.CommerceConfig)
local R=require(script.Parent.Rules)
local Supplies=require(script.Parent.SupplyRules)
local P={}
function P.Product(runtime,player,key)
 R.Check(type(key)=='string'and #key<=60,'Choose an offer')
 local product=C.Find(key)
 R.Check(product and product.Enabled==true and R.Int(product.Id,1,9007199254740990),'Coming soon')
 local p=runtime.Engine:Get(player.UserId)
 if product.Supply then R.Check(Supplies.CanAdd(p,product.Supply,os.time()),'One hour already stored; wait before adding time')end
 if product.Rewards then R.Check(p.Cash+(product.Rewards.Cash or 0)<=require(script.Parent.Config).MaxCash,'Coin storage is full')end
 return {ProductId=product.Id,Key=key}
end
function P.Receipt(runtime,player,product,receipt)
 R.Check(receipt.PlayerId==player.UserId and receipt.ProductId==product.Id,'Receipt mismatch')
 local key='purchase:'..receipt.PurchaseId;local now=os.time()
 local ok,result=runtime.Tx:Run({'p:'..player.UserId,key},function(v)
  local old=v[key]
  if old then R.Check(old.User==player.UserId and old.Product==product.Id and old.Kind=='Commerce','Receipt mismatch');return old.Result end
  local p=v['p:'..player.UserId];runtime.Engine:Authorize(p,player.UserId)
  if product.Supply then Supplies.AddPaid(p,product.Supply,now)
  else
   local rewards=assert(product.Rewards,'Missing rewards')
   R.Check(R.Int(rewards.Cash or 0,0,require(script.Parent.Config).MaxCash)and R.Int(rewards.Bones or 0,0,1000000),'Invalid bundle')
   R.Credit(p,rewards.Cash or 0,false);p.Bones+=(rewards.Bones or 0)
  end
  R.Validate(p)
  local result={Message=product.Name..' added',Key=product.Key}
  v[key]={Kind='Commerce',User=player.UserId,Product=product.Id,At=now,Result=result}
  return result
 end)
 if ok then runtime.Refresh(player)end
 return ok,result
end
return P
