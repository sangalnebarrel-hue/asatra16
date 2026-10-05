local T={}
function T.Run()
 assert(game:GetService('RunService'):IsStudio()and game.GameId==0,'Only local, unpublished Studio tests')
 local RS=game.ReplicatedStorage;local C=require(RS.PlotCatalog);local A=require(RS.PlotAppearance)
 local rt=require(script.Parent.Runtime);local p=game.Players:GetPlayers()[1];assert(p and rt.Ready(p),'Wait for the local test player')
 local yard=require(script.Parent.YardCommerce).Yard(p);assert(yard)
 local n=0;local function check(ok,message)assert(ok,message);n+=1;print('ESTATE_QA_PASS '..message)end
 local clone=yard:Clone();clone.Name='QAOnly'
 for _,id in ipairs(C.Order)do
  for _,level in ipairs({1,5,9})do
   A.Apply(clone,level,id)
   check(clone:GetAttribute('PlotSkin')==id and clone:GetAttribute('PlotStage')==level,id..' stage '..level)
   check(clone.PlotDevelopment.BestFinds.Slots:FindFirstChild('Relic')~=nil,'Showcase '..id..' '..level)
   local rev=clone:GetAttribute('AppearanceRevision');A.Apply(clone,level,id);assert(clone:GetAttribute('AppearanceRevision')==rev,'Idempotent appearance')
   for i=1,5 do assert(clone['DigSlot_'..i]:GetAttribute('Unlocked')==(i<=C.Stages[level].Slots),'Kennel progression')end
  end
 end
 clone:Destroy()
 local stats=require(script.Parent.RecordStats);local best=require(script.Parent.BestFinds)
 local profile={UserId=p.UserId,Stats=nil,Dogs={},Items={}}
 local item={ItemId='gold_nugget',ItemUid='find_qa',DisplayName='QA Gold',WeightKg=3,TierIndex=2,Class='Treasure',Depth=2,FoundAt=os.time(),SellValue=100,CombinedOdds=5,Mutation='NORMAL'}
 stats.Find(profile,item)
 local relic=table.clone(item);relic.ItemId='golden_bone';relic.ItemUid='relic_qa';relic.Class='Artifact';relic.DisplayName='QA Relic';relic.SellValue=400
 stats.Find(profile,relic)
 local selected=best.Select(profile)
 check(selected.Find.ItemUid=='find_qa'and selected.Relic.ItemUid=='relic_qa','Persistent independent find/relic records')
 local commerce=require(script.Parent.YardCommerce);local access=require(script.Parent.ShopInteriorAccess)
 local shop=workspace.DOGROTS_District['11_Shops'].UPGRADES
 local key='p:'..p.UserId;local original=rt.Engine:Get(p.UserId)
 local function seed(fn)assert(rt.Tx:Run({key},function(v)fn(v[key]);return true end));rt.Refresh(p)end
 seed(function(v)v.Cash=1000000;v.Upgrades.Plot=0;v.Upgrades.Dig=0 end)
 local function move(cf)p.Character:PivotTo(cf);task.wait(.4)end
 local function request(kind,id)
  task.wait(.5)
  return rt.Request(p,'Upgrade',{Kind=kind},id or game.HttpService:GenerateGUID(false):gsub('-',''))
 end
 move(yard.UpgradeAnchor.CFrame)
 check(not pcall(commerce.UpgradeVisit,p,'Plot'),'Yard rejects estate upgrade')
 check(pcall(commerce.UpgradeVisit,p,'Dig'),'Yard accepts dog training')
 check(pcall(commerce.UpgradeVisit,p,'Storage')and pcall(commerce.UpgradeVisit,p,'DogStorage'),'Yard accepts loot and dog capacity')
 local cash=rt.Views[p.UserId].Cash;local ok=request('Plot');check(not ok and rt.Views[p.UserId].Cash==cash,'Rejected plot purchase does not charge')
 ok=request('Dig');check(ok and rt.Views[p.UserId].Upgrades.Dig==1,'Dog training succeeds in yard')
 move(shop.InteractionAnchor.CFrame)
 check(access.Eligible(p,shop),'Player inside physical shop terminal')
 check(not pcall(commerce.UpgradeVisit,p,'Dig'),'Physical shop rejects dog training')
 check(not pcall(commerce.UpgradeVisit,p,'Storage'),'Physical shop rejects local storage upgrades')
 cash=rt.Views[p.UserId].Cash;local id=game.HttpService:GenerateGUID(false):gsub('-','')
 local result;ok,result=request('Plot',id)
 check(ok,'Physical estate purchase '..tostring(result))
 check(rt.Views[p.UserId].Upgrades.Plot==1 and rt.Views[p.UserId].Cash==cash-C.Cost(1),'Estate purchase exact debit and stage')
 ok=request('Plot',id);check(ok and rt.Views[p.UserId].Cash==cash-C.Cost(1),'Receipt retry never charges twice')
 check(yard.PlotDevelopment.BestFinds:GetAttribute('Stage')==2,'Showcase follows purchased stage')
 seed(function(v)v.Upgrades.Plot=8;v.PlotSkins.TheVoid=true;v.EquippedPlotSkin='TheVoid'end)
 check(yard:GetAttribute('PlotSkin')=='TheVoid'and yard.PlotDevelopment:FindFirstChild('VoidRift'),'Equipped Void architecture reconciles')
 best.Reconcile(yard,profile)
 check(yard.PlotDevelopment.BestFinds.Slots.Find:FindFirstChild('Exhibit')~=nil,'Find model displayed')
 check(yard.PlotDevelopment.BestFinds.Slots.Relic:FindFirstChild('Exhibit')~=nil,'Relic model displayed')
 best.Clear(yard)
 check(yard.PlotDevelopment.BestFinds.Slots.Find:FindFirstChild('Exhibit')==nil,'Vacated plot clears previous trophies')
 -- Restore test economy; the local session is memory-only.
 assert(rt.Tx:Run({key},function(v)v[key]=original;return true end));rt.Refresh(p)
 move(shop.InteractionAnchor.CFrame)
 RS.DogEconomyOpen:FireClient(p,'Upgrades')
 print('ESTATE_QA_COMPLETE '..n..' checks')
 return n
end
return T
