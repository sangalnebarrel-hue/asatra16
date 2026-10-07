local PaidPolicy=require(script.Parent.PaidItemPolicy)
local R=require(script.Parent.Rules)
local Lifetime=require(script.Parent.LifetimeStats)
local C=require(script.Parent.Config)
local D=require(script.Parent.DogDefinitions)
local Market=require(script.Parent.Market)
local I=require(script.Parent.ItemRules)
local Offline=require(script.Parent.OfflineEarnings)
local LuckMath=require(game:GetService('ReplicatedStorage').LuckMath)
local E={};E.__index=E
local function pk(id) return 'p:'..id end
function E.new(tx,options)
 local self=setmetatable({Tx=tx,Now=options.Now,Guid=options.Guid,Random=options.Random,Session=options.Session,
  Connected=options.Connected or function()return true end,AssetReady=options.AssetReady or function(id)return D[id] and D[id].Available end,
  Trades={},TradeByUser={}},E)
 self.Market=Market.new(tx,self.Now,self.Guid,function(p,id)self:Authorize(p,id)end)
 return self
end
function E:Authorize(p,id)
 R.Check(p and p.UserId==id and p.Session and p.Session.Id==self.Session and p.Session.Expires>self.Now(),"Profile session unavailable")
 R.Check(self.Connected(id),"Player disconnected")
end
function E:Join(id)
 return self.Tx:Run({pk(id)},function(v)
  local p=R.Normalize(v[pk(id)],id,self.Now());v[pk(id)]=p
  R.Check(not p.Session or p.Session.Id==self.Session or p.Session.Expires<=self.Now(),"Account is active on another server. Retry shortly.")
  Offline.Join(p,self.Now(),self.Session)
  p.Stats.SessionFinds=0
  p.Session={Id=self.Session,Expires=self.Now()+C.SessionSeconds,StatsAt=self.Now()};p.LastDig=self.Now()
  for _,d in pairs(p.Dogs) do if d.State=="Walking" then d.State="Inventory" end end
  R.Validate(p);return "Loaded"
 end)
end
function E:Leave(id)
 self:CancelTrade(id)
 local ok,result=self.Tx:Run({pk(id)},function(v)
  local p=v[pk(id)];if p and p.Session and p.Session.Id==self.Session then Lifetime.Checkpoint(p,self.Now());Offline.Checkpoint(p,self.Now());p.Session=nil end
  return "Saved"
 end)
 if ok and self.OnProfileReleased then pcall(self.OnProfileReleased,id)end
 return ok,result
end
function E:Get(id) return self.Tx:Read(pk(id)) end
function E:Action(id,action,args,request)
 local now=self.Now()
 return self.Tx:Run({pk(id)},function(v)
  local p=v[pk(id)];self:Authorize(p,id);R.Normalize(p,id,now)
  if action=='BuyPlotSkin'or action=='ClaimPlotSkin'then require(script.Parent.PlotDevelopment).VisitShop(game.Players:GetPlayerByUserId(id))end
  if action=='Upgrade'then require(script.Parent.YardCommerce).UpgradeVisit(game.Players:GetPlayerByUserId(id),args.Kind)end
  local message=R.Action(p,action,args,now,self.Random);Offline.Checkpoint(p,now);R.Validate(p)
  local result={Message=message}
  if action=='SellLoot'then
   local pending,lootCount=0,0
   for _,stack in pairs(p.Loot or{})do pending+=stack.Value or 0;lootCount+=stack.Count or 0 end
   result.FastSale={Cash=p.Cash,ItemCount=I.Count(p.Items),PendingCash=pending,LootCount=lootCount,Loot=R.Copy(p.Loot or{}),Stats=R.Copy(p.Stats),LastSaleAt=p.LastSaleAt}
  end
  return result
 end,request)
end
function E:ClaimOffline(id,args,request)
 local now=self.Now()
 return self.Tx:Run({pk(id)},function(v)
  local p=v[pk(id)];self:Authorize(p,id)
  local result=Offline.Claim(p,args.PendingId,now);R.Validate(p);return result
 end,request)
end
function E:Tick(id)
 local now=self.Now()
 return self.Tx:Run({pk(id)},function(v)
  local p=v[pk(id)];self:Authorize(p,id);R.Normalize(p,id,now)
  Lifetime.Checkpoint(p,now);p.Session.Expires=now+C.SessionSeconds
  local contribution=R.Dig(p,now,self.Random);Offline.Checkpoint(p,now)
  R.Validate(p);return {Contribution=contribution,Week=R.Week(now)}
 end)
end
function E:TickAll(ids)
 -- One RAM transaction per player: a single broken profile can no longer stop
 -- digging (and session renewal) for everybody else on the server.
 local now=self.Now();local contribution,failed=0,{}
 for _,id in ipairs(ids) do
  local ok,result=self.Tx:Run({pk(id)},function(v)
   local p=v[pk(id)]
   -- Renew whenever this server owns the session, even if a stalled tick let it
   -- lapse in RAM; otherwise the player would be locked out until rejoining.
   if not (p and self.Connected(id) and p.Session and p.Session.Id==self.Session) then return 0 end
   R.Normalize(p,id,now);Lifetime.Checkpoint(p,now);p.Session.Expires=now+C.SessionSeconds
   local amount=R.Dig(p,now,self.Random);Offline.Checkpoint(p,now);R.Validate(p)
   return amount
  end)
  if ok then contribution+=tonumber(result)or 0 else failed[id]=tostring(result)end
 end
 return true,{Contribution=contribution,Week=R.Week(now),Failed=failed}
end
function E:EventClaim(id,a,request)
 if require(game.ReplicatedStorage.GlobalDigConfig).Enabled==false then return false,'Global Dig is coming soon'end
 local now=self.Now();local key='event:'..R.Week(now)
 R.Check(R.Int(a.Milestone,1,5),"Invalid milestone")
 return self.Tx:Run({pk(id),key},function(v)
  local p=v[pk(id)];self:Authorize(p,id);R.Normalize(p,id,now)
  local e=v[key] or {Total=0};local i=a.Milestone
  R.Check(e.Total>=C.EventMilestones[i] and p.Event.Contribution>=C.EventPersonal[i],"More community and personal contribution required")
  R.Check(not p.Event.Claims[tostring(i)],"Already claimed")
  p.Event.Claims[tostring(i)]=true;p.Bones+=i*10;p.EventTokens+=i*25;p.Cosmetics['Event'..i]=true
  return {Message="Event reward claimed"}
 end,request)
end
-- A dog's share of its rarity's line budget. Ordinary dogs split it evenly;
-- Secrets carry a LineWeight so the rarest of them (THE DOG) stays the rarest.
local function lineShare(def)return def.LineWeight or 1 end
-- Every rarity can walk the shared line for every player; price is the only gate.
-- maxRank leaves out the rarer groups (their budget is not redistributed).
-- boost (optional, LuckMath): server luck and world events lift the rarer budgets and
-- Common absorbs the difference. A dog in C.LuckPinned (THE DOG) keeps its unboosted
-- weight, so the legend stays the legend however lucky the server is.
function E:LineOdds(maxRank,boost)
 local choices,total,groups={},0,{}
 for id,def in pairs(D) do if def.CanSpawnOnLine==true and def.Rank<=(maxRank or #C.Rarities) and self.AssetReady(id) and R.Available(def,self.Now()) then
  groups[def.Rank]=groups[def.Rank]or{};table.insert(groups[def.Rank],def)
 end end
 local lucky=not LuckMath.IsNeutral(boost)
 local budgets=lucky and LuckMath.Budgets(C.Weights,boost)or C.Weights
 local pinned=lucky and C.LuckPinned or {}
 -- Each rarity owns one probability budget regardless of how many dogs it contains.
 for rank=1,#C.Rarities do
  local members=groups[rank]
  if members then
   table.sort(members,function(a,b)return a.Id<b.Id end)
   local shares,pinnedShares,pinnedWeight=0,0,0;for _,def in ipairs(members)do shares+=lineShare(def)end
   local budget=budgets[rank]or 0
   for _,def in ipairs(members)do if pinned[def.Id]then
    pinnedShares+=lineShare(def);pinnedWeight+=math.min(C.Weights[rank]or 0,budget)*lineShare(def)/shares
   end end
   for _,def in ipairs(members)do
    local weight
    if not lucky then weight=(C.Weights[rank]or 0)*lineShare(def)/shares
    elseif pinned[def.Id]then weight=math.min(C.Weights[rank]or 0,budget)*lineShare(def)/shares
    else weight=math.max(0,budget-pinnedWeight)*lineShare(def)/math.max(1e-9,shares-pinnedShares)end
    if weight>0 then total+=weight;table.insert(choices,{Id=def.Id,Rank=rank,Weight=weight,Ceiling=total})end
   end
  end
 end
 return choices,total
end
function E:Choose(maxRank,boost)
 local choices,total=self:LineOdds(maxRank,boost)
 if total==0 then return nil end
 local roll=self.Random()*total;for _,v in ipairs(choices) do if roll<v.Ceiling then return v.Id end end
 return choices[#choices].Id
end
-- One line dog of the given rarity, for the conveyor's overdue-rarity guarantee.
function E:ChooseRank(rank)
 local members,shares={},0
 for id,def in pairs(D)do if def.Rank==rank and def.CanSpawnOnLine==true and self.AssetReady(id) and R.Available(def,self.Now())then table.insert(members,def);shares+=lineShare(def)end end
 if #members==0 then return nil end
 table.sort(members,function(a,b)return a.Id<b.Id end)
 local roll=self.Random()*shares
 for _,def in ipairs(members)do roll-=lineShare(def);if roll<0 then return def.Id end end
 return members[#members].Id
end
-- Called only by server discovery/arrival orchestration, never by an economy remote action.
-- An arrival's operation ID must remain stable while retrying storage/capacity failures.
function E:GrantSpecial(id,dogId,operation)
 R.Check(dogId=='LongDog'or dogId=='TheDog','Unknown special discovery')
 R.Check(type(operation)=='string'and #operation>0 and #operation<=80,'Invalid special operation')
 R.Check(self.AssetReady(dogId),'Special dog asset unavailable')
 -- Arrival GUIDs are server-wide identities; short prefixes stay within DataStore's 50-character key limit.
 local key=dogId=='TheDog'and'sa:'..operation or'sl:'..id..':'..operation
 R.Check(#key<=50,'Special operation key is too long')
 local uid=self.Guid();local now=self.Now()
 return self.Tx:Run({pk(id),'supply:'..dogId,key},function(v)
  local p=v[pk(id)];self:Authorize(p,id);R.Normalize(p,id,now)
  if v[key]then R.Check(v[key].UserId==id,'This arrival belongs to another player');return v[key]end
  p.SpecialDiscoveries=p.SpecialDiscoveries or{}
  if dogId=='LongDog'then
   R.Check(p.SpecialDiscoveries.LongDogPending==true,'No excavation discovery pending')
  else
   R.Check(p.UnlockedLayers['5']and p.Prestige>=1,'Reach THE VOID and Prestige 1')
   R.Check(now-(p.SpecialDiscoveries.LastArrivalAt or 0)>=C.SpecialAcquisition.TheDog.ClaimCooldown,'Arrival reward cooldown')
  end
  local supply=v['supply:'..dogId]or{};v['supply:'..dogId]=supply
  local dog=R.Mint(p,dogId,uid,supply,now,self.Random,dogId=='LongDog'and'Excavation'or'ServerArrival')
  if dogId=='LongDog'then p.SpecialDiscoveries.LongDogPending=nil
  else p.SpecialDiscoveries.LastArrivalAt=now end
  dog.PricePaid=0
  local result={UserId=id,Dog=R.Copy(dog),DogUid=uid,DogId=dogId,At=now,Message='Discovered '..dog.DisplayName}
  v[key]=result;R.Validate(p);return result
 end)
end
-- opts.Variant: the variant the dog spawned with on the tongue (server-set, validated).
function E:BuyLine(id,dogId,uid,request,opts)
 R.Check(self.AssetReady(dogId),"Dog asset unavailable")
 local key='line:'..uid;local order=self.Tx:Read(key);local old=order and order.Owner
 local keys={pk(id),key,'supply:'..dogId};if old and old~=id then table.insert(keys,pk(old)) end
 local now=self.Now()
 return self.Tx:Run(keys,function(v)
  local p=v[pk(id)];self:Authorize(p,id)
  R.Check(R.Available(D[dogId],now),"This dog is not available")
  local current=v[key];R.Check((current and current.Owner)==old,"Another player bought this dog; try again")
  R.Check(R.Free(p),"Dog storage full")
  local price=current and current.NextPrice or D[dogId].LinePrice or D[dogId].BasePrice;local dog
  if current then
   R.Check(current.State=="Walking" and current.DogId==dogId and old~=id,"Dog cannot be rebought")
   local from=v[pk(old)];dog=from and from.Dogs[uid]
   R.Check(dog and dog.State=="Walking","Dog already delivered")
   R.Pay(p,price);R.Credit(from,math.floor((dog.PricePaid or 0)*.9),false);from.Dogs[uid]=nil;R.Transfer(dog,p,now,"Rebuy")
  else
   R.Pay(p,price);local supply=v['supply:'..dogId] or {};v['supply:'..dogId]=supply
   local variant=opts and opts.Variant
   if variant~=nil then local known=false;for _,v in ipairs(C.Variants)do if v.Name==variant then known=true end end;if not known then variant=nil end end
   dog=R.Mint(p,dogId,uid,supply,now,self.Random,"DogLine",variant)
  end
  dog.State="Walking";dog.PricePaid=price
  v[key]={Owner=id,DogId=dogId,State="Walking",NextPrice=math.min(C.MaxCash,math.ceil(price*1.3))}
  R.Validate(p)
  return {Dog=R.Copy(dog),NextPrice=v[key].NextPrice,PreviousOwner=old}
 end,request)
end
function E:Deliver(id,uid)
 return self.Tx:Run({pk(id),'line:'..uid},function(v)
  local p=v[pk(id)];local d=p and p.Dogs[uid];local order=v['line:'..uid]
  R.Check(order and order.Owner==id and d,"Delivery owner changed")
  d.State="Inventory";order.State="Delivered";return "Delivered"
 end)
end
function E:Roll(id,mode,request)
 R.Check(mode~='LuckyBlock','Visit the tongue or Lucky Blocks in Shop')
 R.Check(mode=="LuckyBlock" or mode=="EventRoll","Invalid roll")
 local current=self:Get(id);self:Authorize(current,id)
 -- Secrets only come from the tongue and blocks, never from a token roll.
 local dogId=self:Choose(5);R.Check(dogId,"No assets available")
 local uid=self.Guid();local now=self.Now()
 return self.Tx:Run({pk(id),'supply:'..dogId},function(v)
  local p=v[pk(id)];self:Authorize(p,id);R.Normalize(p,id,now)
  if mode=="EventRoll" then R.Check(p.EventTokens>=100,"Requires 100 Event Tokens");p.EventTokens-=100
  else R.Pay(p,600,2) end
  local s=v['supply:'..dogId] or {};v['supply:'..dogId]=s
  local d=R.Mint(p,dogId,uid,s,now,self.Random,mode);d.PricePaid=mode=="LuckyBlock" and 600 or 0
  return {Message="Found "..d.DisplayName.." · "..d.Variant,DogUid=uid}
 end,request)
end
function E:CancelTrade(id)
 local tid=self.TradeByUser[id];local t=tid and self.Trades[tid]
 if t and not t.Committing then
  for _,user in ipairs(t.Users) do self.TradeByUser[user]=nil end
  self.Trades[tid]=nil
 end
end
function E:TradeRequest(id,target)
 R.Check(R.Int(target,-9007199254740991,9007199254740991) and target~=0 and target~=id and self.Connected(target),"Choose an online player")
 R.Check(not self.TradeByUser[id] and not self.TradeByUser[target],"A player is already trading")
 local tid=self.Guid()
 local t={Id=tid,Users={id,target},Version=1,Offers={},Ready={},Confirmed={},Expires=self.Now()+180,Inviter=id,Accepted=false}
 self.Trades[tid]=t;self.TradeByUser[id]=tid;self.TradeByUser[target]=tid;return {Message="Trade invitation sent",Trade=t}
end
local function fingerprint(d)
 return table.concat({d.DogUid,d.DogId,d.Variant,d.Edition,tostring(d.SerialNumber),tostring(d.Mastery),tostring(d.AscensionLevel),d.AssignedSlot,d.State},'|')
end
function E:Trade(id,action,a)
 local t=self.Trades[self.TradeByUser[id]];R.Check(t and t.Expires>self.Now(),"Trade expired")
 R.Check(not t.Committing,"Trade is committing")
 if action=="Accept" then R.Check(id~=t.Inviter,"Waiting for the other player");t.Accepted=true;return {Message="Trade accepted"} end
 R.Check(t.Accepted,"Accept the invitation first")
 if action=="Offer" then
  R.Check(type(a.Dogs)=="table" and #a.Dogs<=8 and R.Int(a.Cash,0,C.MaxCash),"Invalid offer")
  local p=self:Get(id);self:Authorize(p,id);R.Check(p.Cash>=a.Cash,"Not enough Cash")
  local seen,prints,details,itemPrints={},{},{},{}
  R.Check(type(a.Items or {})=="table" and #(a.Items or {})<=8,"Maximum eight items")
  for _,uid in ipairs(a.Items or {})do R.Check(not seen[uid],"Duplicate ItemUid");seen[uid]=true;local x=I.Get(p,uid,true);itemPrints[uid]=table.concat({x.ItemUid,x.ItemId,tostring(x.WeightKg),x.Mutation},"|");details[uid]=R.Copy(x)end
  for _,uid in ipairs(a.Dogs) do R.Check(not seen[uid],"Duplicate DogUid");seen[uid]=true;local dog=R.Dog(p,uid,true);R.Check(not dog.PaidRandom or (PaidPolicy.Allowed(t.Users[1])and PaidPolicy.Allowed(t.Users[2])),'Paid-item trading is unavailable for a participant');prints[uid]=fingerprint(dog);details[uid]=R.Copy(dog) end
  t.Offers[tostring(id)]={Dogs=R.Copy(a.Dogs),Cash=a.Cash,Prints=prints,Details=details,Items=R.Copy(a.Items or {}),ItemPrints=itemPrints}
  t.Version+=1;t.Ready={};t.Confirmed={};t.ConfirmAfter=nil;return {Message="Offer changed; confirmations reset"}
 elseif action=="Ready" then
  R.Check(a.Version==t.Version,"Offer changed; review it again")
  R.Check(t.Offers[tostring(t.Users[1])] and t.Offers[tostring(t.Users[2])],"Both players must submit an offer")
  t.Ready[tostring(id)]=true
  if t.Ready[tostring(t.Users[1])] and t.Ready[tostring(t.Users[2])] then t.ConfirmAfter=self.Now()+5 end
  return {Message="Ready. Review both offers before confirming"}
 elseif action=="Confirm" then
  R.Check(a.Version==t.Version and t.ConfirmAfter and self.Now()>=t.ConfirmAfter,"Review the offer; final confirmation unlocks after 5 seconds")
  t.Confirmed[tostring(id)]=true
  if not (t.Confirmed[tostring(t.Users[1])] and t.Confirmed[tostring(t.Users[2])]) then return {Message="Waiting for final confirmation"} end
  local hasPaid=false;for _,offer in pairs(t.Offers)do for _,asset in pairs(offer.Details)do if asset.PaidRandom then hasPaid=true end end end
  R.Check(not hasPaid or (PaidPolicy.Allowed(t.Users[1])and PaidPolicy.Allowed(t.Users[2])),'Paid-item trading is unavailable for a participant')
  t.Committing=true
  local left,right=t.Users[1],t.Users[2];local now=self.Now()
  local ok,result=self.Tx:Run({pk(left),pk(right)},function(v)
   local p,q=v[pk(left)],v[pk(right)];self:Authorize(p,left);self:Authorize(q,right)
   local a,b=t.Offers[tostring(left)],t.Offers[tostring(right)]
   R.Check(R.Count(p.Dogs)-#a.Dogs+#b.Dogs+R.Count(p.Reservations)<=R.Capacity(p),"First player's storage is full")
   R.Check(R.Count(q.Dogs)-#b.Dogs+#a.Dogs+R.Count(q.Reservations)<=R.Capacity(q),"Second player's storage is full")
   for _,side in ipairs({{p,a},{q,b}}) do for _,uid in ipairs(side[2].Dogs) do
    R.Check(fingerprint(R.Dog(side[1],uid,true))==side[2].Prints[uid],"A dog changed; create a fresh offer")
   end end
   I.Normalize(p);I.Normalize(q)
   R.Check(I.Count(p.Items)-#(a.Items or {})+#(b.Items or {})+I.Count(p.ItemReservations)<=I.Capacity(p),"First player's item storage is full")
   R.Check(I.Count(q.Items)-#(b.Items or {})+#(a.Items or {})+I.Count(q.ItemReservations)<=I.Capacity(q),"Second player's item storage is full")
   for _,side in ipairs({{p,a},{q,b}})do for _,uid in ipairs(side[2].Items or {})do local x=I.Get(side[1],uid,true)
    R.Check(table.concat({x.ItemUid,x.ItemId,tostring(x.WeightKg),x.Mutation},"|")==side[2].ItemPrints[uid],"Item changed; review offer")
   end end
   R.Pay(p,a.Cash);R.Pay(q,b.Cash);R.Credit(p,b.Cash,false);R.Credit(q,a.Cash,false)
   local outgoingA,outgoingB={},{}
   for _,uid in ipairs(a.Dogs) do outgoingA[uid]=p.Dogs[uid];p.Dogs[uid]=nil end
   for _,uid in ipairs(b.Dogs) do outgoingB[uid]=q.Dogs[uid];q.Dogs[uid]=nil end
   for uid,d in pairs(outgoingA) do R.Check(not q.Dogs[uid],"Duplicate DogUid");R.Transfer(d,q,now,"Trade") end
   for uid,d in pairs(outgoingB) do R.Check(not p.Dogs[uid],"Duplicate DogUid");R.Transfer(d,p,now,"Trade") end
   local itemsA,itemsB={},{}
   for _,uid in ipairs(a.Items or {})do itemsA[uid]=p.Items[uid];p.Items[uid]=nil end
   for _,uid in ipairs(b.Items or {})do itemsB[uid]=q.Items[uid];q.Items[uid]=nil end
   for _,x in pairs(itemsA)do I.Transfer(q,x)end;for _,x in pairs(itemsB)do I.Transfer(p,x)end
   p.Stats.CompletedTrades+=1;q.Stats.CompletedTrades+=1;R.Validate(p);R.Validate(q);return {Message="Trade completed"}
  end,'trade-'..t.Id)
  t.Committing=false;self:CancelTrade(id)
  R.Check(ok,result);return result
 end
 error("Invalid trade action",0)
end
-- RAM-only: hands this profile's pending record checks to the server batch.
-- Server-session records are decided here against the in-memory server book;
-- global records are merged by Runtime.FlushRecords with one UpdateAsync per depth.
function E:Records(id,serverBook)
 local profile=self:Get(id);if not profile then return true,{Jobs={},Server={}}end
 I.Normalize(profile)
 if not next(profile.RecordJobs)then return true,{Jobs={},Server={}}end
 serverBook=serverBook or {}
 return self.Tx:Run({pk(id)},function(v)
  local p=v[pk(id)];I.Normalize(p);self:Authorize(p,id)
  local jobs,server={},{}
  for itemId,x in pairs(p.RecordJobs)do
   local depth=x.Depth;local mine=server[depth];local book=serverBook[depth]
   local previous=(mine and mine[itemId])or(book and book[itemId])
   if not previous or x.WeightKg>previous.WeightKg then
    server[depth]=mine or {}
    server[depth][itemId]={WeightKg=x.WeightKg,ItemUid=x.ItemUid,Finder=x.OriginalFinderUserId,At=x.FoundAt}
    x.RecordAtCreation=x.RecordAtCreation or {};x.RecordAtCreation.Server=true
    local held=p.Items[x.ItemUid]
    if held then held.RecordAtCreation=held.RecordAtCreation or {};held.RecordAtCreation.Server=true end
   end
   jobs[itemId]=R.Copy(x);p.RecordJobs[itemId]=nil
  end
  return {Jobs=jobs,Server=server}
 end)
end
return E
