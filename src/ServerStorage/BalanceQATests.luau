-- Run in Studio against the installed production modules; no live profiles touched.
local QA={}
function QA.Run()
 local RS=game:GetService('ReplicatedStorage');local SS=game:GetService('ServerStorage');local E=game:GetService('ServerScriptService').Economy
 local C=require(RS.DogEconomy.Config);local D=require(RS.DogEconomy.DogDefinitions);local R=require(E.Rules);local S=require(E.SignatureRules)
 local I=require(E.ItemRules);local B=require(RS.LuckyBlockConfig);local Reward=require(E.RewardService)
 local checks=0;local function check(ok,msg)assert(ok,'BALANCE_QA: '..msg);checks+=1 end
 local counts={0,0,0,0,0,0};local indices={};local ids={}
 for id,def in pairs(D)do
  check(not indices[def.Index],'duplicate index');indices[def.Index]=true;table.insert(ids,id)
  counts[def.Rank]+=1;check(def.Rarity==C.Rarities[def.Rank],'rarity '..id)
  local model=SS.DogTemplates:FindFirstChild(def.VisualAsset)
  check(model and model:IsA('Model'),'missing model '..id)
  check(RS.DogAnimationClips:FindFirstChild(def.AnimationAsset),'missing animation library '..id)
  check(type(def.Signature)=='string'and #def.Signature>10,'missing signature '..id)
 end
 check(#ids==101,'101 dogs');for i,n in ipairs({20,30,15,15,10,11})do check(counts[i]==n,'rarity count '..i)end
 check(C.StartingCash==750,'starter cash');check(C.StartingCash>=C.Prices[1],'starter affordability')
 for i=1,5 do local sum=0;for _,item in ipairs(C.Layers[i].Loot)do sum+=item[3];check(item[4]>0,'loot value')end;check(math.abs(sum-100)<1e-8,'layer weights')end
 local p=R.Profile(900001,2000000000)
 for _,tier in ipairs(B.Rarities)do
  local pool,total=Reward.Pool(p,tier);local probability=0;local groups={0,0,0,0,0,0}
  for _,row in ipairs(pool)do probability+=row.Chance;groups[row.Rank]+=row.Chance;check(row.Id~='TheDog'and row.Id~='LongDog','special leaked into block')end
  check(math.abs(probability-1)<1e-8,'pool probability '..tier)
  for i,n in ipairs(B.RewardPools[tier])do check(math.abs(groups[i]-n/100)<1e-8,'exact tier chance '..tier..'/'..i)end
 end
 -- The tongue: odds sum to 100 and every rarity keeps its budget; Secrets share theirs by
 -- LineWeight with THE DOG the rarest; no Secret is ever guaranteed or token-rolled; every
 -- line Secret has an arrival whose clips exist.
 local weights=0;for _,w in ipairs(C.Weights)do weights+=w end
 check(math.abs(weights-100)<1e-8,'line weights sum to 100')
 check(C.LineGuarantee[6]==nil,'no secret guarantee')
 check(D.TheDog.CanSpawnOnLine==true and D.TheDog.CanDropFromLuckyBlock==false,'THE DOG walks the tongue only')
 check(not D.LongDog.CanSpawnOnLine and not D.Aurion.CanSpawnOnLine,'excavation and roulette exclusives stay off the tongue')
 local engine=require(E.Engine).new(nil,{Now=os.time,Random=function()return .5 end,AssetReady=function(id)return D[id]~=nil end})
 local choices,total=engine:LineOdds();local share={0,0,0,0,0,0}
 for _,row in ipairs(choices)do share[row.Rank]+=row.Weight/total end
 for rank,w in ipairs(C.Weights)do check(math.abs(share[rank]-w/weights)<1e-9,'line rarity budget '..rank)end
 local tokenChoices=engine:LineOdds(5);for _,row in ipairs(tokenChoices)do check(row.Rank<6,'token roll never mints a secret')end
 local Arrivals=require(RS.SecretArrivalConfig)
 local cinematics=game:GetService('StarterPlayer').StarterPlayerScripts:FindFirstChild('SecretArrivals')
 cinematics=cinematics and cinematics:FindFirstChild('Dogs')
 for id,def in pairs(D)do
  if def.Rank==6 then
   if def.CanSpawnOnLine then
    check(def.LineWeight>=D.TheDog.LineWeight,'THE DOG is the rarest secret '..id)
    check(def.LinePrice and def.LinePrice>=C.Prices[6],'secret line price '..id)
   end
   -- Every Secret has an arrival, on the tongue or wherever it is obtained.
   local arrival=Arrivals.Dogs[id];check(arrival~=nil and arrival.Hold>0,'secret arrival '..id)
   local cinematic=cinematics and cinematics:FindFirstChild(id);check(cinematic~=nil and cinematic:IsA('ModuleScript'),'secret cinematic '..id)
   local library=RS.DogAnimationClips:FindFirstChild(def.AnimationAsset)
   for _,step in ipairs(arrival.Clips)do check(library:FindFirstChild(step[2])~=nil,'arrival clip '..id..'/'..step[2])end
  end
 end
 local rng=Random.new(3092026);local random=function()return rng:NextNumber()end
 local sumIncome={};local now=2000000000
 table.sort(ids)
 for _,id in ipairs(ids)do
  local def=D[id];local profile=R.Profile(900001,now);profile.CurrentLayer=math.min(5,def.MinLayer or 1)
  profile.Upgrades.Storage=10;local d=R.Mint(profile,id,'test-'..id,{},now,random,'Test','Normal',true)
  R.Assign(profile,d.DogUid,'DigSlot_1',now)
  for cycle=1,80 do
   now+=35;d.NextWorkAt=now;profile.Loot={};profile.Items={};profile.RecordJobs={}
   local count=R.Dig(profile,now,random);check(count>=0 and count<=24,'bounded contributions '..id)
   local value=0;for _,loot in pairs(profile.Loot)do value+=loot.Value;check(loot.Value==loot.Value and loot.Value>=0,'finite value')end
   sumIncome[def.Rarity]=(sumIncome[def.Rarity]or 0)+value
   R.Validate(profile)
  end
  check(d.WorkSequence==80,'all dogs complete work '..id)
  d.Rarity='Uncommon';local oldCash=profile.Cash;local uid=d.DogUid
  R.Normalize(profile,profile.UserId,now)
  check(profile.Cash==oldCash and profile.Dogs[uid].Rarity==def.Rarity,'migration preserves wallet and ID '..id)
 end
 local q=R.Profile(1,now);q.Upgrades.Plot=4
 local sampler=function()return .99 end
 for i,id in ipairs({'CoffeeDog','Breadog','Samuriba','Potatodog','KingCorgi'})do local d=R.Mint(q,id,id,{},now,sampler,'Test','Normal',true);R.Assign(q,id,'DigSlot_'..i,now)end
 check(S.Speed(q,q.Dogs.Breadog,now)>1,'coffee neighbor speed')
 check(S.Speed(q,q.Dogs.Potatodog,now)<1,'potato slower')
 q.Dogs.Samuriba.WorkSequence=10;check(S.Context(q,q.Dogs.Samuriba,S.Team(q,now),now,sampler).Value==5,'samurai tenth critical')
 check(S.Team(q,now).SellValue>=.12,'king team sell aura')
 local probabilities={};local n=100000
 for _=1,n do local m,chance=I.Mutation(random,{SignatureMutation='Glitched',SignatureMutationChance=.02});probabilities[m.Name]=(probabilities[m.Name]or 0)+1;check(chance>0 and chance<=1,'mutation probability')end
 check(math.abs((probabilities.GLITCHED or 0)/n-(.02+.98*.0005))<.003,'merged mutation probability')
 print('DOGROTS_BALANCE_QA_PASS',checks,'checks;101 dogs;6 pools;line odds;8000 work cycles;100000 mutation rolls')
 return {Checks=checks,Dogs=#ids,Counts=counts,IncomeSample=sumIncome,MutationCounts=probabilities}
end
return QA
