local PlotRules=require(script.Parent.PlotRules)
local PlotCatalog=require(game.ReplicatedStorage.PlotCatalog)
local WorldModifiers=require(game.ReplicatedStorage.WorldEvents.WorldEventModifiers)
local C=require(script.Parent.Config)
local D=require(script.Parent.DogDefinitions)
local I=require(script.Parent.ItemRules)
local Stats=require(script.Parent.RecordStats)
local Lifetime=require(script.Parent.LifetimeStats)
local Display=require(script.Parent.DisplayRules)
local LabState=require(script.Parent.LabState)
local Signatures=require(script.Parent.SignatureRules)
local Tickets=require(script.Parent.RouletteTickets)
local SupplyRules=require(script.Parent.SupplyRules)
local Onboarding=require(script.Parent.OnboardingRules)
local R={Items=I}
function R.Copy(v) if type(v)~="table" then return v end local r={};for k,x in pairs(v) do r[k]=R.Copy(x) end;return r end
function R.Int(n,min,max) return type(n)=="number" and n==n and n%1==0 and n>=min and n<=max end
function R.Check(ok,msg) if not ok then error(msg,0) end end
function R.Count(t) local n=0;for _ in pairs(t) do n+=1 end;return n end
function R.MuseumCount(p)
 local count=0
 for id,known in pairs(p.DogDex or{})do
  local def=D[id]
  if known==true and def and not def.MuseumExcluded and def.Index>=1 and def.Index<=100 then count+=1 end
 end
 return count
end
function R.Week(now) return math.floor((now-345600)/604800) end
function R.Meta(now) return C.Weeks[R.Week(now)%#C.Weeks+1] end
function R.Profile(uid,now)
 local p={Version=C.Version,UserId=uid,Cash=C.StartingCash,Bones=0,EventTokens=0,Dogs={},DogDex={},DexClaims={},
  DisplayDogs={},OwnedBlocks={},Loot={},VariantDex={},XP=0,Level=1,CurrentLayer=1,UnlockedLayers={['1']=true},Upgrades={},Supplies={},Cosmetics={},EquippedCosmetic="",
  Prestige=0,Listings={},Reservations={},Event={Week=R.Week(now),Contribution=0,Claims={}},Pity=0,LastDig=now,Created=now}
 p.Onboarding=Onboarding.New()
 Tickets.Normalize(p,now);I.Normalize(p);Lifetime.Normalize(p);LabState.Normalize(p);PlotRules.Normalize(p);return p
end
function R.Normalize(p,uid,now)
 p=p or R.Profile(uid,now)
 PlotRules.Normalize(p)
 R.Check(p.UserId==uid,"Profile owner mismatch")
 Onboarding.Observe(p,now)
 local defaults=R.Profile(uid,now)
 for k,v in pairs(defaults) do if p[k]==nil then p[k]=v end end
 if p.Event.Week~=R.Week(now) then p.Event={Week=R.Week(now),Contribution=0,Claims={}};p.EventTokens=0 end
 Tickets.Normalize(p,now);I.Normalize(p);Lifetime.Normalize(p);p.Version=C.Version
 p.SpecialDiscoveries=p.SpecialDiscoveries or {};p.TotalExcavations=p.TotalExcavations or 0
 for _,d in pairs(p.Dogs)do
  local def=D[d.DogId]
  if def then d.Rarity=def.Rarity;d.DisplayName=def.DisplayName;d.Ability=def.Ability;d.FoodDog=table.find(def.Tags,'Food')~=nil end
  d.NextWorkAt=d.NextWorkAt or now+C.Work.BaseCooldown+C.Work.Duration;d.WorkSequence=d.WorkSequence or 0
 end
 SupplyRules.Normalize(p,now)
 Display.Normalize(p)
 LabState.Normalize(p)
 return p
end
function R.Capacity(p) return math.min(C.MaxDogs,20+20*(p.Upgrades.DogStorage or 0)) end
function R.Free(p) return R.Count(p.Dogs)+R.Count(p.Reservations or {})<R.Capacity(p) end
function R.Dog(p,uid,unassigned)
 R.Check(type(uid)=="string" and #uid<=100,"Invalid DogUid")
 local d=p.Dogs[uid];R.Check(d and d.DogUid==uid and d.OwnerUserId==p.UserId,"Dog not owned")
 R.Check(d.State~="Walking","Wait for delivery")
 if unassigned then R.Check(not d.Locked,"Unlock this dog first");R.Check((d.AssignedSlot or "")=="","Remove this dog from its kennel first") end
 return d
end
function R.Pay(p,cash,bones)
 R.Check(R.Int(cash,0,C.MaxCash) and R.Int(bones or 0,0,C.MaxCash),"Invalid cost")
 R.Check(p.Cash>=cash and p.Bones>=(bones or 0),"Not enough Cash or Bones")
 p.Cash-=cash;p.Bones-=bones or 0
end
function R.Credit(p,cash,isEarned) R.Check(R.Int(cash,0,C.MaxCash) and p.Cash+cash<=C.MaxCash,"Cash limit reached");p.Cash+=cash;if isEarned~=false then Lifetime.Add(p,"TotalCoinsEarned",cash)end end
function R.Available(def,now,layer)
 if not def or not def.Available or def.Reserved then return false end
 if layer and layer<(def.MinLayer or 1) then return false end
 if def.SupplyType=="Rotating" then return def.Index%4==R.Week(now)%4 end
 if def.SupplyType=="Event" then return R.Week(now)%4==def.Index%4 end
 if def.SupplyType=="Limited" then return def.ReleaseEnd==0 or now<def.ReleaseEnd end
 return true
end
function R.Variant(random)
 local roll=random()*10000;local total=0
 for _,v in ipairs(WorldModifiers.MutationRows(C.Variants,'Name','Weight',os.time())) do total+=v.Weight;if roll<total then return v.Name end end
 return "Normal"
end
function R.Discover(p,d)
 p.DogDex[d.DogId]=true;p.VariantDex=p.VariantDex or {};p.VariantDex[d.DogId]=p.VariantDex[d.DogId] or {}
 p.VariantDex[d.DogId][d.Variant]=true
end
function R.Mint(p,id,uid,supply,now,random,origin,variantOverride,frozenReward)
 local def=D[id];R.Check(def and (frozenReward or R.Available(def,now)),"This dog is not available")
 R.Check(R.Free(p) and not p.Dogs[uid],"Dog storage full or duplicate DogUid")
 supply.Minted=supply.Minted or 0
 R.Check(def.LimitedSupply==0 or supply.Minted<def.LimitedSupply,"Limited supply exhausted")
 supply.Minted+=1
 local d={DogUid=uid,DogId=id,DisplayName=def.DisplayName,Rarity=def.Rarity,Variant=variantOverride or R.Variant(random),
  SerialNumber=(def.Rank>=3 or def.SupplyType~="Permanent") and supply.Minted or 0,
  Edition=(def.FirstEditionLimit>0 and supply.Minted<=def.FirstEditionLimit) and "First Edition" or "Standard",
  OG=def.OG==true,Origin=origin or "DogLine",CreatedAt=now,Mastery=0,MasteryXP=0,AscensionLevel=0,
  OwnerHistory={{UserId=p.UserId,At=now,Type="Mint"}},Ability=def.Ability,PricePaid=def.BasePrice,
  OwnerUserId=p.UserId,State="Inventory",AssignedSlot="",NextWorkAt=now+C.Work.BaseCooldown+C.Work.Duration,WorkSequence=0}
 d.FoodDog=table.find(def.Tags,'Food')~=nil
 p.Dogs[uid]=d;R.Discover(p,d)
 return d
end
function R.Transfer(d,to,now,reason)
 d.OwnerUserId=to.UserId;d.State="Inventory";d.AssignedSlot=""
 table.insert(d.OwnerHistory,{UserId=to.UserId,At=now,Type=reason})
 if #d.OwnerHistory>100 then table.remove(d.OwnerHistory,1);d.EarlierTransfers=(d.EarlierTransfers or 0)+1 end
 to.Dogs[d.DogUid]=d;R.Discover(to,d)
end
function R.Bonus(d)
 local b=0;for _,v in ipairs(C.Variants) do if v.Name==d.Variant then b=v.Bonus end end
 return 1+b+math.min(100,d.Mastery or 0)*.0015+C.Ascension[1+(d.AscensionLevel or 0)]
end
function R.Team(p,now)
 local e=Signatures.Team(p,now);local sets={}
 for _,dog in pairs(p.Dogs)do
  local def=D[dog.DogId]
  if def and Signatures.Active(dog)then
   local key=def.Set or 'Explorers';sets[key]=sets[key]or {};sets[key][dog.DogId]=true
  end
 end
 for _,owned in pairs(sets)do local count=R.Count(owned);e.SetBonus+=count>=4 and .02 or count>=2 and .01 or 0 end
 e.SetBonus=math.min(.06,e.SetBonus)
 return WorldModifiers.Resolve(p,e,now,D)
end
function R.Cooldown(p,d,e)
 local now=p.LastDig or 0;e=e or R.Team(p,now)
 local base=C.Work.BaseCooldown-math.clamp(d.Mastery or 0,0,100)*C.Work.MasteryReduction
 local speed=(1+.04*(p.Upgrades.Dig or 0)+(e.Cooldown or 0)+(e.Recovery or 0)+(e.DigSpeed or 0))*Signatures.Speed(p,d,now)
 if (p.Supplies.EnergySnack or 0)>now then speed+=C.Supplies.EnergySnack.Magnitude end
 return math.clamp(base/math.min(2,speed),C.Work.MinCooldown,C.Work.MaxCooldown)
end
function R.Dig(p,now,random)
 I.Normalize(p);p.LastDig=now;p.SpecialDiscoveries=p.SpecialDiscoveries or {}
 local e=R.Team(p,now);local units=0
 for _,s in pairs(p.Loot)do units+=s.Count end
 local capacity=50+25*(p.Upgrades.Storage or 0)+math.floor(100*(e.Storage or 0))
 if (p.Supplies.StorageCrate or 0)>now then capacity+=C.Supplies.StorageCrate.Magnitude end
 local contributed=0;local ordered={}
 for _,d in pairs(p.Dogs)do table.insert(ordered,d)end
 table.sort(ordered,function(a,b)return a.DogUid<b.DogUid end)
 for _,d in ipairs(ordered)do
  if Signatures.Active(d)and now>=(d.NextWorkAt or now+1)then
   local def=D[d.DogId]
   if not def then continue end
   d.WorkSequence=(d.WorkSequence or 0)+1;Stats.Dig(p,now)
   p.TotalExcavations=(p.TotalExcavations or 0)+1
   local ctx=Signatures.Context(p,d,e,now,random)
   ctx.Value*=1+C.UpgradeEffects.Ability*(p.Upgrades.Ability or 0)
   d.NextWorkAt=now+R.Cooldown(p,d,e)+C.Work.Duration
   d.LastAbility=def.Ability;d.LastAbilityAt=now
   if ctx.Genesis then d.LastAbility='Genesis'elseif ctx.Missing then d.LastAbility='MISSING ITEM'elseif ctx.Triplicate then d.LastAbility='ITEM DUPLICATED x3'elseif ctx.Critical then d.LastAbility='Critical Dig x5'end
   local layer=C.Layers[ctx.Depth]
   local power=def.PowerBudget or C.Power[def.Rank]or 1
   local produced=0
   for rollIndex=1,ctx.Rolls do
    if units>=capacity and not ctx.Orbit and not ctx.AutoDeposit then break end
    local luck=1+(e.Luck or 0)+(e.Artifact or 0)+(e.TreasureMap or 0)+e.SetBonus
    if (p.Supplies.LuckyTreat or 0)>now then luck+=C.Supplies.LuckyTreat.Magnitude end
    if ctx.BadLuckGuard and (d.DryStreak or 0)>=12 then luck+=3 end
    local candidates,total={},0
    for index,item in ipairs(layer.Loot)do
     local rare=item[2]=='Artifact'or item[2]=='Treasure'or item[2]=='Rare'or item[2]=='Space'
     local weight=item[3]*(rare and luck or 1)*(ctx.CategoryLuck[item[2]]or 1)
     if rare and (e.Protection or 0)>0 and p.Pity>=30 then weight*=2 end
     total+=weight;table.insert(candidates,{Item=item,Ceiling=total,Index=index,Rare=rare})
    end
    local pick=random()*total;local chosen=candidates[#candidates]
    for _,candidate in ipairs(candidates)do if pick<candidate.Ceiling then chosen=candidate;break end end
    local item=chosen.Item;local name,category,signatureMult,mutation=Signatures.Modify(ctx,item,d,random,e)
    local mult=R.Bonus(d)*power*signatureMult*(1+e.SetBonus+.025*(p.Upgrades.Plot or 0)+.015*(p.Upgrades.Kennel or 0)+math.min(.5,e.SellValue or 0))
    if category=='Corrupted'then mult*=1-math.max(0,.15-(e.Cleanse or 0)-(ctx.Protection or 0))end
    local value=math.max(1,math.floor(item[4]*mult))
    local key=ctx.Depth..':'..chosen.Index..':'..name
    local stack=p.Loot[key]or {Name=name,Category=category,Count=0,Value=0,Layer=ctx.Depth,Mutation=mutation}
    if ctx.Orbit then
     d.OrbitValue=(d.OrbitValue or 0)+value;d.OrbitCount=(d.OrbitCount or 0)+1
    elseif ctx.AutoDeposit and (units>=capacity or random()<ctx.AutoDeposit)then R.Credit(p,value)
    else stack.Count+=1;stack.Value+=value;p.Loot[key]=stack;units+=1 end
    produced+=1;p.Pity=chosen.Rare and 0 or math.min(100,p.Pity+1)
    d.DryStreak=chosen.Rare and 0 or math.min(100,(d.DryStreak or 0)+1)
    p.XP+=math.max(1,math.floor(2*p.CurrentLayer*ctx.XP*(1+(e.XPBonus or 0))))
    d.MasteryXP=(d.MasteryXP or 0)+2;d.Mastery=math.min(100,math.floor(math.sqrt(d.MasteryXP/5)))
    contributed+=1+math.floor((e.Event or 0)*10)
    if category=='Bone'then p.Bones+=1 end
    if ctx.HatchChance and random()<ctx.HatchChance then p.Bones+=2 end
    if random()<math.min(.25,e.BoneBonus or 0)then p.Bones+=1 end
   end
   if ctx.Orbit and d.WorkSequence%4==0 and (d.OrbitValue or 0)>0 then R.Credit(p,d.OrbitValue);d.OrbitValue=0;d.OrbitCount=0 end
   if ctx.TreatChance and produced>0 and random()<ctx.TreatChance then p.Supplies.LuckyTreat=math.min(now+3600,math.max(now,p.Supplies.LuckyTreat or 0)+30)end
   for attempt=1,ctx.ItemAttempts do
    if not I.Free(p)then break end
    local effects=R.Copy(e);effects.SourceDogUid=d.DogUid
    effects.WeightLuck=ctx.WeightLuck;effects.SignatureMutation=ctx.Mutation;effects.SignatureMutationChance=ctx.MutationChance
    effects.SignatureMutationValue=ctx.MutationValue;effects.DiscoveryScale=ctx.ItemScale
    effects.SellValue=math.min(.5,(effects.SellValue or 0)+.025*(p.Upgrades.Plot or 0)+.015*(p.Upgrades.Kennel or 0)+math.max(0,ctx.Value-1)*.20)
    effects.Artifact=(effects.Artifact or 0)+math.max(0,(ctx.CategoryLuck.Artifact or 1)-1)*.10
    effects.DigitalLuck=(effects.DigitalLuck or 0)+math.max(0,(ctx.CategoryLuck.Digital or 1)-1)*.10
    local found,chance=I.Pick(ctx.Depth,random,effects)
    if found then I.Mint(p,found,chance,d.DogUid..':'..d.WorkSequence..':'..attempt,now,random,effects)end
   end
   local special=C.SpecialDiscovery or {LongDogChance=1/20000,LongDogMinLayer=4}
   if produced>0 and p.CurrentLayer>=special.LongDogMinLayer and not p.DogDex.LongDog and not p.SpecialDiscoveries.LongDogPending and random()<special.LongDogChance*(1+math.max(0,e.LongDogLuck or 0))then
    p.SpecialDiscoveries.LongDogPending=true;p.SpecialDiscoveries.LongDogFoundAt=now
   end
  end
 end
 p.Level=math.min(100,1+math.floor(math.sqrt(p.XP/25)))
 p.Event.Contribution+=contributed;p.EventTokens+=contributed;Lifetime.Add(p,'GlobalDigContribution',contributed)
 return contributed
end

function R.Assign(p,uid,slot,now)
 PlotRules.Assign(p,slot)
 local d=R.Dog(p,uid,false)
 R.Check(type(slot)=="string" and slot:match("^DigSlot_[1-5]$"),"Invalid kennel")
 for _,other in pairs(p.Dogs) do R.Check(other.DogUid==uid or other.AssignedSlot~=slot,"Kennel occupied") end
 d.NextWorkAt=math.max(d.NextWorkAt or 0,(now or p.LastDig)+C.Work.Duration)
 d.AssignedSlot=slot;d.State="Digging";return "Dog assigned to dig"
end
function R.Action(p,action,a,now,random)
 local plotMessage=PlotRules.Action(p,action,a);if plotMessage then return plotMessage end
 if action=="DisplayDog"then return Display.Assign(p,a)end
 local itemMessage,itemCash=I.Action(p,action,a)
 if itemMessage then if itemCash then R.Credit(p,itemCash);p.LastSaleAt=now end;return itemMessage end
 if action=="RecordClaim" then
  local s=Stats.Normalize(p);local key=tostring(a.Count);R.Check(table.find(Stats.Milestones,a.Count) and s.Milestones[key] and not s.Claims[key],"Milestone is locked or already claimed")
  s.Claims[key]=true;p.Bones+=10;p.Cosmetics['Finds'..key]=true;return 'Milestone claimed'
 elseif action=="TrackListing" then
  R.Check(type(a.Id)=='string' and #a.Id<=80 and type(a.Key)=='string' and #a.Key<=80,'Invalid listing');R.Check(type(a.Enabled)=='boolean','Invalid state')
  if a.Enabled then R.Check(R.Count(p.TrackedListings)<50 or p.TrackedListings[a.Id],'Maximum 50 tracked listings');p.TrackedListings[a.Id]=a.Key else p.TrackedListings[a.Id]=nil end;return 'Tracking updated'
 elseif action=="DogFavorite" or action=="DogLock" then
  local dog=R.Dog(p,a.Uid,false);R.Check(type(a.Enabled)=="boolean","Invalid toggle");dog[action=="DogLock" and "Locked" or "Favorite"]=a.Enabled;return "Updated"
 elseif action=="DexFavorite"then R.Check(D[a.Id] and p.DogDex[a.Id] and not D[a.Id].Reserved,"Dog undiscovered");p.DexFavorites[a.Id]=a.Enabled==true;return "Updated"
 elseif action=="Forage" then
  R.Check(R.Count(p.Dogs)==0 and R.Count(p.Listings)==0 and R.Count(p.Reservations)==0 and p.Cash<C.Prices[1],"Foraging is for players without a dog or enough Cash to buy one")
  R.Check(now-(p.LastForage or 0)>=60,"Forage is available once per minute")
  p.LastForage=now;R.Credit(p,math.min(30,C.Prices[1]-p.Cash));return "Found emergency starter Cash"
 elseif action=="Assign" then return R.Assign(p,a.Uid,a.Slot,now)
 elseif action=="Remove" then local d=R.Dog(p,a.Uid,false);d.AssignedSlot="";d.State="Inventory";return "Returned to storage"
 elseif action=="SellLoot" then
  local total=0
  for key,s in pairs(p.Loot) do if not a.Key or key==a.Key then total+=s.Value;p.Loot[key]=nil end end
  R.Check(total>0,"No loot selected");R.Credit(p,total);Stats.Sale(p,total);p.LastSaleAt=now;return "Sold loot for "..total
 elseif action=="Upgrade" then
  local def=C.Upgrades[a.Kind];R.Check(def,"Unknown upgrade")
  local level=p.Upgrades[a.Kind] or 0;R.Check(level<def.Max,"Already at maximum")
  R.Pay(p,math.floor(def.Base*def.Factor^level));p.Upgrades[a.Kind]=level+1;if a.Kind=="Plot"then return "Yard expanded: "..PlotCatalog.Stages[level+2].Name end;return "Upgrade purchased"
 elseif action=="Layer" then
  R.Check(R.Int(a.Layer,1,5),"Invalid layer");local def=C.Layers[a.Layer]
  if not p.UnlockedLayers[tostring(a.Layer)] then
   R.Check(p.UnlockedLayers[tostring(a.Layer-1)] and p.Level>=def.Level,"Unlock the previous layer and reach level "..def.Level)
   if a.Layer==5 then R.Check(p.Prestige>=1,"THE VOID requires Prestige 1") end
   R.Pay(p,def.Cost);p.UnlockedLayers[tostring(a.Layer)]=true
  end
  p.CurrentLayer=a.Layer;return def.Name
 elseif action=="Retire"or action=="Mutation"or action=="Ascend"or action=="Fusion"then
  error("Use the genetics terminal and review the lab preview first",0)
 elseif action=="Supply" then
  local def=C.Supplies[a.Kind];R.Check(def,"Unknown supply")
  local expires=math.max(now,p.Supplies[a.Kind] or 0)+def.Seconds
  -- A purchase always grants its full advertised duration, or charges nothing.
  R.Check(SupplyRules.CanAdd(p,a.Kind,now),"Maximum 60 minutes active; wait before adding another 10 minutes")
  R.Pay(p,def.Cash);p.Supplies[a.Kind]=expires;return def.Name.." active for 10 more minutes"
 elseif action=="Cosmetic" then
  local def=C.Cosmetics[a.Kind]
  if not def and p.Cosmetics[a.Kind] then p.EquippedCosmetic=a.Kind;return "Collection title equipped" end
  R.Check(def,"Unknown cosmetic")
  if not p.Cosmetics[a.Kind] then R.Pay(p,def.Cash,def.Bones or 0);p.Cosmetics[a.Kind]=true end
  p.EquippedCosmetic=a.Kind;return "Cosmetic equipped"
 elseif action=="DexClaim" then
  R.Check(R.Int(a.Count,1,100) and (a.Count==10 or a.Count==25 or a.Count==50 or a.Count==75 or a.Count==100),"Invalid milestone")
  R.Check(R.MuseumCount(p)>=a.Count and not p.DexClaims[tostring(a.Count)],"Reward unavailable")
  p.DexClaims[tostring(a.Count)]=true;p.Bones+=a.Count;p.Cosmetics["Dex"..a.Count]=true;return "Dex reward claimed"
 elseif action=="SetClaim" then
  local total,owned=0,0
  for id,def in pairs(D) do if def.Set==a.Set and not def.Reserved and not def.MuseumExcluded then total+=1;for _,dog in pairs(p.Dogs) do if dog.DogId==id then owned+=1;break end end end end
  R.Check(total>0 and owned==total,"Own the complete set first");R.Check(not p.Cosmetics['Set'..a.Set],"Already claimed")
  p.Cosmetics['Set'..a.Set]=true;return "Set title unlocked; equip it in Cosmetics"
 elseif action=="Prestige" then
  R.Check(p.Level>=25 and p.UnlockedLayers['4'],"Requires level 25 and Corrupted Layer")
  R.Pay(p,250000*(p.Prestige+1));p.Prestige+=1;p.Bones+=100;p.XP=0;p.Level=1;p.CurrentLayer=1
  p.Supplies={};p.SupplyReserve={};p.Cosmetics['Prestige'..p.Prestige]=true;return "Prestige complete; dogs, layers and permanent upgrades retained"
 end
 error("Unknown action",0)
end
function R.Validate(p)
 Onboarding.Observe(p,os.time())
 Tickets.Validate(p)
 PlotRules.Normalize(p);PlotRules.Validate(p)
 LabState.Validate(p)
 Display.Normalize(p)
 I.Validate(p)
 R.Check(R.Int(p.Cash,0,C.MaxCash) and R.Int(p.Bones,0,C.MaxCash),"Invalid wallet")
 R.Check(R.Count(p.Dogs)<=C.MaxDogs,"Inventory hard cap")
 local slots={}
 for uid,d in pairs(p.Dogs) do
  R.Check(d.DogUid==uid and d.OwnerUserId==p.UserId and D[d.DogId],"Invalid inventory record")
  if d.AssignedSlot~="" then R.Check(not slots[d.AssignedSlot],"Duplicate kennel assignment");slots[d.AssignedSlot]=true end
 end
end
return R
