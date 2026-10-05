local O=require(script.Parent.OnboardingRules)
local R=require(script.Parent.Rules)
local S={}
function S.Request(runtime,player,args,receiptId)
 R.Check(type(args)=='table'and(args.Action=='Start'or args.Action=='Skip'or args.Action=='Finish'),'Invalid tutorial action')
 local key='p:'..player.UserId
 return runtime.Tx:Run({key},function(values)
  local p=values[key];runtime.Engine:Authorize(p,player.UserId)
  local result=O.Apply(p,args.Action,os.time())
  R.Validate(p)
  return result
 end,receiptId)
end
return S
