-- Pure profile accounting, called inside the existing durable transactions.
local C=require(game:GetService('ReplicatedStorage').OfflineEarningsConfig)
local Economy=require(script.Parent.Config)
local R=require(script.Parent.Rules)
local Definitions=require(script.Parent.DogDefinitions)
local Signatures=require(script.Parent.SignatureRules)
local O={}
local function finite(n)return type(n)=='number'and n==n and math.abs(n)<math.huge end
local function bounded(n,limit)return finite(n)and math.clamp(math.floor(n),0,limit)or 0 end
function O.Normalize(p)
 local o=p.OfflineEarnings
 if type(o)~='table'then o={} end
 o.Version=C.Version;o.PendingCoins=bounded(o.PendingCoins,C.MaxPendingCoins);o.PendingSeconds=bounded(o.PendingSeconds,C.MaxAwaySeconds)
 o.Revision=bounded(o.Revision,9007199254740000);o.CheckpointAt=bounded(o.CheckpointAt,9007199254740000)
 o.Rate=finite(o.Rate)and math.clamp(o.Rate,0,C.MaxPendingCoins)or 0
 o.BaseRate=finite(o.BaseRate)and math.clamp(o.BaseRate,0,C.MaxPendingCoins)or 0
 o.Dogs=type(o.Dogs)=='table'and o.Dogs or{};o.Contributors=type(o.Contributors)=='table'and o.Contributors or{}
 p.OfflineEarnings=o;return o
end
function O.Estimate(p)
 -- 41 is a quiet phase for every periodic aura. Clear sale/pulse/map timestamps,
 -- supplies and world events instead of accidentally freezing a temporary bonus.
 local clean={Dogs={},Upgrades=p.Upgrades or{},Supplies={},LastDig=41,LastSaleAt=-100000,TimePulseUntil=0,TreasureMapUntil=0}
 for uid,dog in pairs(p.Dogs or{})do
  if Definitions[dog.DogId]and Signatures.Active(dog)then clean.Dogs[uid]=dog end
 end
 local team=Signatures.Team(clean,41);local sets={}
 for _,dog in pairs(clean.Dogs)do
  local def=Definitions[dog.DogId];local key=def.Set or'Explorers';sets[key]=sets[key]or{};sets[key][dog.DogId]=true
 end
 for _,members in pairs(sets)do local n=R.Count(members);team.SetBonus+=n>=4 and .02 or n>=2 and .01 or 0 end
 team.SetBonus=math.min(.06,team.SetBonus)
 local layer=Economy.Layers[p.CurrentLayer or 1];if not layer then return 0,{},0 end
 local rows,baseTotal={},0
 for uid,dog in pairs(clean.Dogs)do
  local def=Definitions[dog.DogId]
  local multiplier=R.Bonus(dog)*(def.PowerBudget or Economy.Power[def.Rank]or 1)
   *(1+Economy.UpgradeEffects.Ability*(clean.Upgrades.Ability or 0))
   *(1+team.SetBonus+.025*(clean.Upgrades.Plot or 0)+.015*(clean.Upgrades.Kennel or 0)+math.min(.5,team.SellValue or 0))
  local value,weight=0,0
  for _,item in ipairs(layer.Loot)do
   local rare=item[2]=='Artifact'or item[2]=='Treasure'or item[2]=='Rare'or item[2]=='Space'
   local w=item[3]*(rare and(1+(team.Luck or 0)+team.SetBonus)or 1)
   local mult=multiplier
   if item[2]=='Corrupted'then mult*=1-math.max(0,.15-(team.Cleanse or 0))end
   value+=w*math.max(1,math.floor(item[4]*mult));weight+=w
  end
  local cycle=R.Cooldown(clean,dog,team)+Economy.Work.Duration
  local base=weight>0 and C.BaseRolls*(value/weight)/cycle or 0
  baseTotal+=base
  table.insert(rows,{Uid=uid,DogId=dog.DogId,Name=def.DisplayName,BaseRate=base,Rate=base*C.Efficiency})
 end
 table.sort(rows,function(a,b)return a.Uid<b.Uid end)
 return baseTotal*C.Efficiency,rows,baseTotal
end
function O.Checkpoint(p,now)
 local o=O.Normalize(p)
 o.Rate,o.Dogs,o.BaseRate=O.Estimate(p);o.CheckpointAt=now
 return o
end
local function addContributors(o,seconds,coins)
 local allocations,total,left={},0,coins
 for _,dog in ipairs(o.Dogs)do total+=dog.Rate or 0 end
 if total<=0 then return end
 for _,dog in ipairs(o.Dogs)do
  local exact=coins*(dog.Rate or 0)/total;local amount=math.floor(exact);left-=amount
  table.insert(allocations,{Dog=dog,Coins=amount,Fraction=exact-amount})
 end
 table.sort(allocations,function(a,b)if a.Fraction~=b.Fraction then return a.Fraction>b.Fraction end;return a.Dog.Uid<b.Dog.Uid end)
 for i=1,left do allocations[(i-1)%#allocations+1].Coins+=1 end
 for _,row in ipairs(allocations)do
  local dog=row.Dog;local prior=o.Contributors[dog.Uid]or{Uid=dog.Uid,DogId=dog.DogId,Name=dog.Name,Coins=0,Seconds=0}
  prior.Coins+=row.Coins;prior.Seconds+=seconds;o.Contributors[dog.Uid]=prior
 end
end
function O.Join(p,now,sessionId)
 local o=O.Normalize(p);local from=o.CheckpointAt;local prior=p.Session
 -- Same-server Join replays are online time, never another offline reward.
 if prior and prior.Id==sessionId then from=now
 elseif prior then from=math.max(from,prior.Expires or now)end
 local away=from>0 and math.max(0,now-from)or 0
 local seconds,coins=0,0
 if C.Enabled and o.CheckpointAt>0 and away>=C.MinAwaySeconds and o.Rate>0 then
  seconds=math.min(away,math.max(0,C.MaxAwaySeconds-o.PendingSeconds))
  coins=math.min(math.floor(seconds*o.Rate),math.max(0,C.MaxPendingCoins-o.PendingCoins))
  if seconds>0 then o.PendingSeconds+=seconds end
  if coins>0 then addContributors(o,seconds,coins);o.PendingCoins+=coins;o.Revision+=1 end
 end
 o.LastAwaySeconds=away;o.LastCreditedSeconds=seconds;o.LastAddedCoins=coins;o.LastReturnAt=now
 o.WasCapped=away>=C.MinAwaySeconds and o.Rate>0 and(seconds<away or o.PendingCoins>=C.MaxPendingCoins)
 return O.Checkpoint(p,now)
end
function O.Id(p,o)return 'offline:'..p.UserId..':'..o.Revision end
function O.Report(p)
 local o=O.Normalize(p);local dogs={}
 for _,dog in pairs(o.Contributors)do table.insert(dogs,R.Copy(dog))end
 table.sort(dogs,function(a,b)if a.Coins~=b.Coins then return a.Coins>b.Coins end;return a.Uid<b.Uid end)
 return {PendingCoins=o.PendingCoins,PendingId=O.Id(p,o),CanClaim=o.PendingCoins>0,PendingSeconds=o.PendingSeconds,
  AwaySeconds=o.LastAwaySeconds or 0,CreditedSeconds=o.LastCreditedSeconds or 0,AddedCoins=o.LastAddedCoins or 0,WasCapped=o.WasCapped==true,
  BaseRate=o.BaseRate,Rate=o.Rate,Efficiency=C.Efficiency,CapSeconds=C.MaxAwaySeconds,MinAwaySeconds=C.MinAwaySeconds,
  Eligible=#o.Dogs>0,Dogs=dogs,CurrentDogs=R.Copy(o.Dogs),Description=C.Description}
end
function O.Claim(p,pendingId,now)
 local o=O.Normalize(p)
 R.Check(type(pendingId)=='string'and pendingId==O.Id(p,o),'Offline earnings changed; review the new amount')
 R.Check(o.PendingCoins>0,'No offline coins to claim')
 local coins=o.PendingCoins
 -- R.Credit validates wallet capacity before anything pending is cleared.
 R.Credit(p,coins);o.PendingCoins=0;o.PendingSeconds=0;o.Contributors={};o.LastClaimAt=now;o.Revision+=1
 return {Message='Claimed '..coins..' offline Coins',Coins=coins,ClaimedPendingId=pendingId}
end
return O
