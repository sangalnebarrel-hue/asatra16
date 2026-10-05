local C=require(game.ReplicatedStorage.LabConfig)
local Access=require(game.ReplicatedStorage.LabAccess)
local R=require(script.Parent.Rules)
local L=require(script.Parent.LabRules)
local State=require(script.Parent.LabState)
local S={Quotes={}}
local function runtime()return require(script.Parent.Runtime)end
function S.Visit(player)
 R.Check(Access.CanUse(player),'Enter Mutation Lab and approach the genetics terminal')
end
function S.Info(player)
 S.Visit(player);local rt=runtime();local p=rt.Engine:Get(player.UserId);rt.Engine:Authorize(p,player.UserId)
 local l=State.Normalize(p)
 return {Tier=l.Tier,Recipes=L.Catalog(p,os.time()),Cooldown=math.max(0,C.Cooldown-(os.time()-l.LastAt))}
end
function S.Request(player,action,a,receipt)
 local rt=runtime();S.Visit(player)
 R.Check(not rt.Engine.TradeByUser[player.UserId],'Finish or cancel your trade before using the lab')
 if action=='LabInfo'then return true,S.Info(player)end
 if action=='LabPreview'then
  local p=rt.Engine:Get(player.UserId);rt.Engine:Authorize(p,player.UserId)
  local plan=L.Preview(p,a,os.time());local token=rt.Engine.Guid()
  S.Quotes[player.UserId]={Token=token,Args=R.Copy(a),Plan=plan,Expires=os.time()+C.QuoteSeconds}
  local public=L.Public(plan);public.Token=token;public.Expires=os.time()+C.QuoteSeconds
  return true,public
 end
 R.Check(action=='LabCommit','Unknown lab action')
 for k in a do R.Check(k=='Token'or k=='Confirm'or k=='Typed','Unsupported confirmation parameter')end
 R.Check(type(a.Token)=='string'and #a.Token==32 and a.Confirm==true,'Review and confirm the experiment')
 local p=rt.Engine:Get(player.UserId);rt.Engine:Authorize(p,player.UserId);State.Normalize(p)
 for _,r in p.Lab.History do if r.Token==a.Token then return true,R.Copy(r)end end
 local quote=S.Quotes[player.UserId]
 R.Check(quote and quote.Token==a.Token and quote.Expires>os.time(),'Preview expired; review a fresh experiment')
 local keys={'p:'..player.UserId};local output=quote.Plan.RecipeId~='ASCEND'and quote.Plan.OutputDogId
 if output then table.insert(keys,'supply:'..output)end
 local uid=rt.Engine.Guid();local now=os.time()
 local ok,result=rt.Tx:Run(keys,function(v)
  local p=v['p:'..player.UserId];rt.Engine:Authorize(p,player.UserId);R.Normalize(p,player.UserId,now)
  S.Visit(player)
  R.Check(not rt.Engine.TradeByUser[player.UserId],'Finish your trade first')
  for _,r in p.Lab.History do if r.Token==a.Token then return R.Copy(r)end end
  R.Check(quote.Expires>now,'Preview expired')
  local plan=L.Preview(p,quote.Args,now)
  R.Check(plan.Signature==quote.Plan.Signature,'Dog, material or odds changed. Review a fresh preview.')
  R.Check(not plan.HighValue or a.Typed==plan.Confirmation,'Type the confirmation for these valuable dogs')
  local supply={}
  if output then supply=v['supply:'..output]or{};v['supply:'..output]=supply end
  return L.Apply(p,plan,now,rt.Engine.Random,uid,supply,a.Token)
 end,receipt)
 if ok then S.Quotes[player.UserId]=nil end
 return ok,result
end
function S.TryOpen(player)
 local rt=runtime()
 if not rt.Ready(player)or not Access.CanUse(player)or not rt.Allow(player,1)then return false end
 game.ReplicatedStorage.DogEconomyOpen:FireClient(player,'Lab');return true
end
function S.Start()
 if S.Started then return end;S.Started=true
 local lab=Access.Model();local anchor=lab:WaitForChild('InteractionAnchor')
 local p=Instance.new('ProximityPrompt');p.Name='GeneticsPrompt';p.ActionText='USE GENETICS LAB';p.ObjectText='GENETICS TERMINAL';p.HoldDuration=.15;p.MaxActivationDistance=C.Distance;p.RequiresLineOfSight=true;p.Parent=anchor
 p.Triggered:Connect(S.TryOpen)
 game.Players.PlayerRemoving:Connect(function(player)S.Quotes[player.UserId]=nil end)
end
return S
