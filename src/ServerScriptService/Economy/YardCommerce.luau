local RS=game:GetService('ReplicatedStorage');local Http=game:GetService('HttpService')
local R=require(script.Parent.Rules);local I=require(script.Parent.ItemRules);local Stats=require(script.Parent.RecordStats);local Value=require(RS.ItemValuation)
local Access=require(RS.PlotInteractionAccess)
local S={Quotes={}};local function runtime()return require(script.Parent.Runtime)end
function S.Yard(player)
 local id=player:GetAttribute('YardId');local map=workspace:FindFirstChild('DOGROTS_District')
 if not map then return end
 for _,yard in ipairs(map['04_PlayerYards']:GetChildren())do if yard:GetAttribute('YardId')==id and yard:GetAttribute('OwnerUserId')==player.UserId then return yard end end
end
function S.Near(player,target,distance)
 local root=player.Character and player.Character:FindFirstChild('HumanoidRootPart');local hum=player.Character and player.Character:FindFirstChildOfClass('Humanoid')
 return target and root and hum and hum.Health>0 and (root.Position-target.Position).Magnitude<=(distance or 18)
end
function S.Visit(player)
 local yard=S.Yard(player);R.Check(yard and Access.CanUse(player,yard,yard:FindFirstChild('SellAnchor')),'Visit the collector in your own yard')
 return yard
end
function S.StorageVisit(player)
 local yard=S.Yard(player);R.Check(yard and Access.CanUse(player,yard,yard:FindFirstChild('StorageAnchor')),'Visit DOG STORAGE in your own yard');return yard
end
function S.UpgradeVisit(player,kind)
 local training=kind=='Dig'or kind=='Kennel'or kind=='Ability'or kind=='Storage'or kind=='DogStorage'
 if training then
  local yard=S.Yard(player)
  R.Check(yard and Access.CanUse(player,yard,yard:FindFirstChild('UpgradeAnchor')),'Visit DOG TRAINING in your own yard for dog improvements')
 else
  local shop=workspace.DOGROTS_District['11_Shops'].UPGRADES
  R.Check(require(script.Parent.ShopInteriorAccess).Eligible(player,shop),'Visit the terminal inside UPGRADES to develop your estate')
 end
end
-- Inventory discoveries are unique ItemUid entries, not client-controlled quantities.
function S.ValidBulkArgs(a)
 if type(a)~='table'or type(a.Uids)~='table'then return false end
 for k in pairs(a)do if k~='Uids'then return false end end
 local n=#a.Uids;if n<1 or n>1000 then return false end
 local seen,count={},0
 for k,uid in pairs(a.Uids)do
  if not R.Int(k,1,n)or type(uid)~='string'or #uid<1 or #uid>100 or seen[uid]then return false end
  seen[uid]=true;count+=1
 end
 return count==n
end
function S.CanSell(p,uid)
 local x=p.Items and p.Items[uid]
 return x~=nil and x.ItemUid==uid and x.OwnerUserId==p.UserId
end
function S.BulkSell(player,a,receipt)
 R.Check(S.ValidBulkArgs(a),'Choose unique item IDs (up to 1000)')
 local rt=runtime()
 return rt.Tx:Run({'p:'..player.UserId},function(v)
  S.Visit(player)
  local p=v['p:'..player.UserId];rt.Engine:Authorize(p,player.UserId)
  R.Check(not rt.Engine.TradeByUser[player.UserId],'Finish your trade before selling')
  local total,sold=0,{}
  for _,uid in ipairs(a.Uids)do
   if S.CanSell(p,uid)then
    local item=I.Get(p,uid,false)
    local price=Value.Price(item) -- Server is authoritative for price.
    total+=price
    local job=p.RecordJobs and p.RecordJobs[item.ItemId]
    if job and job.ItemUid==uid then p.RecordJobs[item.ItemId]=nil end
    p.Items[uid]=nil
    table.insert(sold,uid)
   end
  end
  R.Check(#sold>0,'No items selected')
  R.Credit(p,total);Stats.Sale(p,total);p.LastSaleAt=os.time();R.Validate(p)
  return {Count=#sold,Cash=total,SoldUids=sold,Message='Sold '..#sold..' items for '..total..' Coins',
   FastSale={Cash=p.Cash,ItemCount=I.Count(p.Items),SoldUids=R.Copy(sold),Stats=R.Copy(p.Stats),LastSaleAt=p.LastSaleAt}}
 end,receipt)
end

function S.Request(player,action,a,receipt)
 if action=='BulkSell'then return S.BulkSell(player,a,receipt)end
 local rt=runtime();local yard=S.Visit(player)
 if action=='SellQuote'then
  local p=rt.Engine:Get(player.UserId);local rows,total={},0;local seen={}
  if a.All then
   for uid in pairs(p.Items)do if #rows<20 then table.insert(rows,{Uid=uid})end end
  else
   R.Check(type(a.Uids)=='table'and #a.Uids>0 and #a.Uids<=20,'Choose 1–20 finds')
   for _,uid in ipairs(a.Uids)do R.Check(type(uid)=='string'and not seen[uid],'Duplicate item');seen[uid]=true;table.insert(rows,{Uid=uid})end
  end
  R.Check(#rows>0,'No items selected')
  for _,row in ipairs(rows)do
   R.Check(S.CanSell(p,row.Uid),'Item no longer exists')
   local x=I.Get(p,row.Uid,false)
   row.Price,row.Breakdown=Value.Price(x);row.Name=x.DisplayName;total+=row.Price
  end
  local token=Http:GenerateGUID(false):gsub('-','');S.Quotes[player.UserId]={Token=token,Rows=rows,Total=total,Expires=os.time()+60,Yard=yard}
  return true,{Token=token,Rows=rows,Total=total,Expires=os.time()+60}
 end
 if action=='NPCSell'then
  local quote=S.Quotes[player.UserId]
  R.Check(quote and quote.Token==a.Token and os.time()<quote.Expires and quote.Yard==yard,'Quote expired; request a new appraisal')
  local ok,result=rt.Tx:Run({'p:'..player.UserId},function(v)
   S.Visit(player);local p=v['p:'..player.UserId];rt.Engine:Authorize(p,player.UserId)
   local total=0
   for _,row in ipairs(quote.Rows)do
    R.Check(S.CanSell(p,row.Uid),'Item no longer exists')
    local x=I.Get(p,row.Uid,false);local price=Value.Price(x)
    R.Check(price==row.Price,'Find changed; request a new appraisal')
    total+=price;p.Items[row.Uid]=nil
   end
   R.Credit(p,total);Stats.Sale(p,total);p.LastSaleAt=os.time();R.Validate(p)
   return {Message='Sold '..#quote.Rows..' finds for '..total..' Coins',Cash=total,Count=#quote.Rows}
  end,receipt)
  if ok then S.Quotes[player.UserId]=nil;RS.RewardPresentation:FireClient(player,{Cue='Sell',Message=result.Message})end
  return ok,result
 end
 return false,'Unknown collector action'
end
function S.TryOpen(player,yard,target,page)
 local rt=runtime()
 if not rt.Ready(player)or not Access.CanUse(player,yard,target)or not rt.Allow(player,1)then return false end
 RS.DogEconomyOpen:FireClient(player,page);return true
end
function S.Start()
 require(script.Parent.PlotShowcase).Start()
 local function prompt(yard,target,title,page,action)
  if not target then return end
  local p=Instance.new('ProximityPrompt');p.Name='YardInteraction';p.ActionText=action;p.ObjectText=title
  p.MaxActivationDistance=Access.Distance;p.RequiresLineOfSight=true;p.HoldDuration=.15;p.Parent=target
  p.Triggered:Connect(function(player)S.TryOpen(player,yard,target,page)end)
 end
 for _,yard in workspace.DOGROTS_District['04_PlayerYards']:GetChildren()do if yard:GetAttribute('YardId')then
  prompt(yard,yard:FindFirstChild('SellAnchor'),'SELL · YOUR FINDS','Collector','SELL FINDS')
  prompt(yard,yard:FindFirstChild('UpgradeAnchor'),'DOG TRAINING','DogTraining','TRAIN DOGS')
  prompt(yard,yard:FindFirstChild('StorageAnchor'),'DOG STORAGE','Storage','MANAGE DOGS')
 end end
 game.Players.PlayerRemoving:Connect(function(p)S.Quotes[p.UserId]=nil end)
end
return S
