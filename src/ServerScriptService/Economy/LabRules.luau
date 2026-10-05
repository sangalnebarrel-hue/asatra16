local C=require(game.ReplicatedStorage.LabConfig)
local State=require(script.Parent.LabState)
local Recipes=require(script.Parent.LabRecipeConfig)
local R=require(script.Parent.Rules)
local Defs=require(script.Parent.DogDefinitions)
local I=require(script.Parent.ItemRules)
local World=require(game.ReplicatedStorage.WorldEvents.WorldEventModifiers)
local Base=require(script.Parent.Config)
local L={}
local function check(v,s)R.Check(v,s)end
local function sorted(t)local a={};for k in pairs(t)do table.insert(a,k)end;table.sort(a,function(a,b)return tostring(a)<tostring(b)end);return a end
function L.Canonical(v)
 if type(v)~='table'then return type(v)..':'..tostring(v)end
 local s={};for _,k in sorted(v)do table.insert(s,L.Canonical(k)..'='..L.Canonical(v[k]))end;return '{'..table.concat(s,';')..'}'
end
local function exactKeys(a,allowed)
 check(type(a)=='table','Invalid lab request')
 for k in pairs(a)do check(allowed[k],'Unsupported lab parameter')end
end
local function list(a,limit,label)
 check(type(a)=='table'and #a<=limit,label..' limit exceeded')
 local result,seen={},{}
 for k,v in pairs(a)do check(type(k)=='number'and k%1==0 and k>=1 and k<=#a,'Invalid '..label);check(type(v)=='string'and #v<=100 and not seen[v],'Duplicate or invalid '..label);seen[v]=true;table.insert(result,v)end
 table.sort(result);return result
end
local function dna(a)
 local result={};check(type(a)=='table','Invalid DNA selection')
 for k,n in a do check(C.DNA[k]and R.Int(n,0,100),'Invalid DNA amount');if n>0 then result[k]=n end end;return result
end
function L.HighValue(d)
 local def=Defs[d.DogId]
 return def.Rank>=(table.find(Base.Rarities,'Legendary')or 4) or def.SupplyType=='Limited'or d.Edition=='First Edition'or d.OG==true or(d.SerialNumber or 0)>0 or C.HighValueVariants[d.Variant]==true
end
function L.Tags(d)
 if C.Genetics[d.DogId]then return C.Genetics[d.DogId]end
 local tags={};local aliases={CYBER='DIGITAL',EXPLORERS='NORMAL',DACHSHUND='NORMAL'}
 for _,tag in (Defs[d.DogId]or{}).Tags or{}do
  local key=tostring(tag):upper();key=aliases[key]or key
  if C.DNA[key]and not table.find(tags,key)then table.insert(tags,key)end
 end
 return #tags>0 and tags or{'NORMAL'}
end
function L.Dog(p,uid)
 local d=R.Dog(p,uid,true)
 check(d.State=='Inventory','Return this dog to storage first')
 check(not d.Favorite,'Remove this dog from favorites before a procedure')
 for _,v in p.DisplayDogs or{}do check(v~=uid,'Remove this dog from its display first')end
 check(Defs[d.DogId].Available and Defs[d.DogId].MutationRules.Enabled,'This dog is not available for laboratory procedures')
 return d
end
local function item(p,uid)
 local x=I.Get(p,uid,true);check(not x.Favorite,'Remove catalyst from favorites first');return x
end
local function available(recipe,now)
 local def=Defs[recipe.OutputDogId];local template=def and game.ServerStorage.DogTemplates:FindFirstChild(def.VisualAsset or '')
 return R.Available(def,now)and template and template:FindFirstChild('RootPart',true)
end
local function sameCounts(got,need)
 for k,n in need or{}do if(got[k]or 0)~=n then return false end end
 for k,n in got do if(need or{})[k]~=n then return false end end;return true
end
local function matches(recipe,dogs,selectedDNA,itemCounts)
 if not sameCounts(selectedDNA,recipe.RequiredDNA)or not sameCounts(itemCounts,recipe.RequiredItems)then return false end
 if recipe.RequiredDogIds then
  local a,b={},{};for _,d in dogs do a[d.DogId]=(a[d.DogId]or 0)+1 end;for _,id in recipe.RequiredDogIds do b[id]=(b[id]or 0)+1 end
  if not sameCounts(a,b)then return false end
 elseif recipe.RequiredGeneticTags then
  if #dogs~=#recipe.RequiredGeneticTags then return false end
  local used={}
  local function match(i)
   if i>#recipe.RequiredGeneticTags then return true end
   for k,d in dogs do if not used[k]and table.find(L.Tags(d),recipe.RequiredGeneticTags[i])then used[k]=true;if match(i+1)then return true end;used[k]=nil end end
   return false
  end
  if not match(1)then return false end
 end
 for _,d in dogs do
  if(d.Mastery or 0)<(recipe.MinimumMastery or 0)or(d.AscensionLevel or 0)<(recipe.MinimumAscension or 0)or(recipe.RequiredMutation and d.Variant~=recipe.RequiredMutation)then return false end
 end
 return true
end
function L.Catalog(p,now)
 local l=State.Normalize(p);local result={}
 if l.Tier>=4 then table.insert(result,{RecipeId='ASCEND',Name='Ascend existing dog',Procedure='Fusion',Known=true,Hint='Main dog + two identical DogIds at matching or higher Ascension. Main UID and provenance survive.',Requirements='2 duplicates / same DogId / same or higher Ascension'})end
 for _,recipe in Recipes do
  if available(recipe,now)and l.Tier>=(recipe.Procedure=='Creation'and 5 or 4)then
   local known=recipe.DiscoveryState=='Known'or l.Recipes[recipe.RecipeId]~=nil
   local row={RecipeId=known and recipe.RecipeId or'DISCOVER',Name=known and recipe.Name or(recipe.Secret and'CLASSIFIED BLOODLINE'or'UNIDENTIFIED RECIPE'),Procedure=recipe.Procedure,Known=known,Secret=recipe.Secret,Hint=recipe.Hint,Repeatable=recipe.Repeatable,Discovered=l.Recipes[recipe.RecipeId]~=nil}
   if known then for _,k in {'RequiredDogIds','RequiredGeneticTags','RequiredDNA','RequiredItems','MinimumMastery','MinimumAscension','RequiredMutation','OutputDogId','OutputMutation','Costs','StabilityModifiers'}do row[k]=R.Copy(recipe[k])end end
   table.insert(result,row)
  end
 end
 return result
end
function L.Preview(p,a,now)
 exactKeys(a,{Procedure=true,Uids=true,Items=true,DNA=true,RecipeId=true,StabilizerUid=true,PrimaryUid=true})
 local l=State.Normalize(p);local proc
 for _,v in C.Procedures do if v.Id==a.Procedure then proc=v end end
 check(proc and l.Tier>=proc.Tier,'Reach the required lab level first')
 local uids=list(a.Uids or{},3,'dogs');local items=list(a.Items or{},4,'catalysts');local selectedDNA=dna(a.DNA or{})
 local dogs,prints,itemPrints,itemCounts={},{},{},{}
 for _,uid in uids do local d=L.Dog(p,uid);table.insert(dogs,d);prints[uid]=R.Copy(d)end
 local stabilizer=a.StabilizerUid or'';check(type(stabilizer)=='string'and #stabilizer<=100,'Invalid stabilizer')
 local stabBonus=0
 if stabilizer~=''then
  check(not table.find(items,stabilizer),'A material cannot occupy two slots');local x=item(p,stabilizer)
  stabBonus=C.Stabilizers[x.ItemId];check(stabBonus,'Choose a stabilizer crystal');itemPrints[stabilizer]=R.Copy(x)
 end
 for _,uid in items do local x=item(p,uid);itemPrints[uid]=R.Copy(x);itemCounts[x.ItemId]=(itemCounts[x.ItemId]or 0)+1 end
 local plan={Procedure=a.Procedure,Uids=uids,Items=items,StabilizerUid=stabilizer,DNA={},Consumed={},Dogs={},Cash=0,Bones=0,Stability=100,SuccessChance=100,Duration=C.Duration}
 for _,d in dogs do table.insert(plan.Dogs,{DogUid=d.DogUid,DogId=d.DogId,DisplayName=d.DisplayName,Variant=d.Variant,Rarity=d.Rarity,Mastery=d.Mastery,AscensionLevel=d.AscensionLevel,Edition=d.Edition,SerialNumber=d.SerialNumber,Locked=d.Locked==true,Favorite=d.Favorite==true})end
 local primary
 if a.PrimaryUid then check(table.find(uids,a.PrimaryUid),'Main dog is missing');primary=p.Dogs[a.PrimaryUid]else primary=dogs[1]end
 plan.PrimaryUid=primary and primary.DogUid
 local rank=primary and Defs[primary.DogId].Rank or 1
 if a.Procedure=='Mutation'or a.Procedure=='Targeting'then
  check(#dogs==1,'Select one dog');check(a.RecipeId==nil or a.RecipeId=='','A mutation does not use a recipe')
  local costs=C.Costs[a.Procedure];plan.Cash=costs.Cash+costs.RankCash*rank;plan.Bones=costs.RankBones*rank;plan.DNA=R.Copy(costs.DNA or{})
  check(next(selectedDNA)==nil,'This procedure uses its displayed DNA cost automatically')
  plan.Stability=math.clamp(C.Stability[a.Procedure]+primary.Mastery*C.Stability.MasteryPer+primary.AscensionLevel*C.Stability.AscensionPer+stabBonus,C.Stability.Minimum,C.Stability.Maximum)
  if a.Procedure=='Mutation'then check(#items==0,'Choose Gene Targeting to add an affinity catalyst')
   if not l.TutorialComplete then plan.Cash=0;plan.Bones=0;plan.StarterReagent=true end
  else check(#items==1,'Choose one affinity catalyst');plan.Target=C.Affinities[p.Items[items[1]].ItemId];check(plan.Target,'This find has no mutation affinity')end
  local weights,total={},0
  for _,v in World.MutationRows(Base.Variants,'Name','Weight',now)do
   local weight=v.Weight
   if plan.Target and v.Name==plan.Target.Mutation then weight+=(C.TargetWeights.Base+plan.Stability*C.TargetWeights.PerStability+(stabBonus>0 and C.TargetWeights.StabilizerBonus or 0))*plan.Target.Power end
   if stabBonus>0 and v.Name~= (plan.Target and plan.Target.Mutation)and(v.Name=='Void'or v.Name=='Glitched')then weight*=.55 end
   table.insert(weights,{Name=v.Name,Weight=weight});total+=weight
  end
  plan.Chances={};for _,v in weights do table.insert(plan.Chances,{Name=v.Name,Percent=v.Weight/total*100})end
  plan.StrangeChance=(100-plan.Stability)/100*C.Stability.StrangeRate*100
 elseif a.Procedure=='Extraction'then
  check(#dogs==1 and #items==0 and stabilizer==''and not next(selectedDNA),'Extraction requires one dog and no extra materials')
  plan.Cash=C.Costs.Extraction.Cash+C.Costs.Extraction.RankCash*rank;plan.Consumed=R.Copy(uids)
  local bonus=math.floor(primary.Mastery/C.Extraction.MasteryStep)+primary.AscensionLevel*C.Extraction.AscensionBonus
  plan.Rewards={CommonDNA=C.Extraction.CommonByRank[rank]+bonus}
  local rare=C.Extraction.RareByRank[rank];if rare>0 then plan.Rewards.RareDNA=rare end
  local shards=C.Extraction.VariantShards[primary.Variant]or 0;if shards>0 then plan.Rewards.MutationShards=shards end
  for _,tag in L.Tags(primary)do plan.Rewards[tag]=C.Extraction.SamplesByRank[rank]+math.min(bonus,4)end
  if rank>=C.Extraction.CoreMinimumRank then plan.Rewards.CoreFragment=1 end
 else
  check(#dogs>=2,'Select two or three dogs')
  if a.RecipeId=='ASCEND'then
   check(a.Procedure=='Fusion'and #dogs==3 and #items==0 and stabilizer==''and not next(selectedDNA),'Ascension needs a main dog and exactly two duplicates')
   check(primary.AscensionLevel<3,'Maximum Ascension')
   for _,d in dogs do check(d.DogId==primary.DogId and d.AscensionLevel>=primary.AscensionLevel,'Duplicates need the same DogId and matching Ascension');if d~=primary then table.insert(plan.Consumed,d.DogUid)end end
   plan.RecipeId='ASCEND';plan.RecipeName='Ascension';plan.Cash=C.Costs.Ascend.Cash*(primary.AscensionLevel+1);plan.Bones=C.Costs.Ascend.Bones*(primary.AscensionLevel+1);plan.OutputDogId=primary.DogId;plan.OutputMutation=primary.Variant;plan.OutputAscension=primary.AscensionLevel+1
  else
   local recipe
   for _,v in Recipes do if v.Procedure==a.Procedure and(a.RecipeId=='DISCOVER'or a.RecipeId==v.RecipeId)and matches(v,dogs,selectedDNA,itemCounts)and available(v,now)then recipe=v;break end end
   check(recipe,'No compatible recipe: check bloodlines, DNA, finds and mastery')
   check(a.RecipeId=='DISCOVER'or recipe.DiscoveryState=='Known'or l.Recipes[recipe.RecipeId],'This recipe is still classified')
   check(recipe.Repeatable or not l.Recipes[recipe.RecipeId],'This discovery is one-time only')
   plan.RecipeId=recipe.RecipeId;plan.RecipeName=recipe.Name;plan.Hidden=recipe.DiscoveryState~='Known'and not l.Recipes[recipe.RecipeId]
   plan.Secret=recipe.Secret;plan.Cash=recipe.Costs.Cash;plan.Bones=recipe.Costs.Bones or 0;plan.DNA=R.Copy(recipe.RequiredDNA)
   plan.OutputDogId=recipe.OutputDogId;plan.OutputMutation=recipe.OutputMutation
   plan.Stability=math.clamp(recipe.StabilityModifiers+stabBonus,C.Stability.Minimum,C.Stability.Maximum)
   check(not recipe.MaximumStability or plan.Stability<=recipe.MaximumStability,'This bloodline requires a less stable experiment')
   plan.SuccessChance=math.min(98,60+plan.Stability*.4);plan.Consumed=R.Copy(uids)
   check(R.Count(p.Dogs)-#plan.Consumed+1+R.Count(p.Reservations)<=R.Capacity(p),'Dog storage is full')
  end
 end
 check(p.Cash>=plan.Cash and p.Bones>=plan.Bones,'Not enough Coins or Bones')
 for k,n in plan.DNA do check((l.DNA[k]or 0)>=n,'Not enough '..C.DNA[k])end
 for k,n in plan.Rewards or{}do check((l.DNA[k]or 0)+n<=C.MaxMaterial,'DNA storage limit reached')end
 plan.Destructive=#plan.Consumed>0;plan.HighValue=false
 for _,uid in plan.Consumed do if L.HighValue(p.Dogs[uid])then plan.HighValue=true end end
 plan.Confirmation=plan.HighValue and('CONSUME '..#plan.Consumed..' DOG'..(#plan.Consumed>1 and'S'or''))or''
 -- A reroll usually lands on Normal, so replacing a rare variant (Golden and above) needs the typed confirmation too.
 if(a.Procedure=='Mutation'or a.Procedure=='Targeting')and primary and C.HighValueVariants[primary.Variant]then
  plan.HighValue=true;plan.Confirmation='REROLL '..string.upper(primary.Variant)
 end
 plan.Signature=L.Canonical({Plan=plan,Dogs=prints,Items=itemPrints})
 return plan
end
function L.Public(plan)
 local p=R.Copy(plan);p.Signature=nil;p.Target=p.Target and p.Target.Mutation
 if p.Hidden then p.OutputDogId=nil;p.OutputMutation=nil;p.RecipeId='CLASSIFIED';p.RecipeName='Unknown bloodline'end
 return p
end
local function award(l,key,n,now)
 check((l.DNA[key]or 0)+n<=C.MaxMaterial,'DNA storage limit reached');l.DNA[key]=(l.DNA[key]or 0)+n;l.DiscoveredDNA[key]=true
 l.FirstDiscoveries['DNA:'..key]=l.FirstDiscoveries['DNA:'..key]or now
end
function L.Apply(p,plan,now,random,newUid,supply,token)
 local l=State.Normalize(p);check(now-l.LastAt>=C.Cooldown,'Chamber cooling down')
 R.Pay(p,plan.Cash,plan.Bones)
 for k,n in plan.DNA do check((l.DNA[k]or 0)>=n,'DNA changed');l.DNA[k]-=n end
 for _,uid in plan.Items do p.Items[uid]=nil end
 if plan.StabilizerUid~=''then p.Items[plan.StabilizerUid]=nil end
 local primary=p.Dogs[plan.PrimaryUid];local before=primary and R.Copy(primary);local paid=l.PaidDNA==true
 for _,uid in plan.Uids do paid=paid or p.Dogs[uid].PaidRandom==true end
 local result={Token=token,At=now,Procedure=plan.Procedure,RecipeId=plan.RecipeId,Secret=plan.Secret,Stability=plan.Stability,Consumed={},DNA={},Success=true,BeforeDog=before,Duration=plan.Duration}
 if plan.Procedure=='Mutation'or plan.Procedure=='Targeting'then
  local roll=random()*100;local sum=0;local variant='Normal'
  for _,v in plan.Chances do sum+=v.Percent;if roll<sum then variant=v.Name;break end end
  primary.Variant=variant;primary.PaidRandom=paid or primary.PaidRandom;R.Discover(p,primary)
  result.Dog=R.Copy(primary);result.Message=primary.DisplayName..' · '..variant
  if random()*100<plan.StrangeChance then award(l,'StrangeDNA',1,now);result.DNA.StrangeDNA=1 end
  l.TutorialComplete=true
 elseif plan.Procedure=='Extraction'then
  p.Dogs[plan.PrimaryUid]=nil;result.Consumed=R.Copy(plan.Consumed)
  for k,n in plan.Rewards do award(l,k,n,now);result.DNA[k]=n end
  if paid then l.PaidDNA=true end
  result.Message='DNA extraction complete. '..before.DisplayName..' was consumed.'
 elseif plan.RecipeId=='ASCEND'then
  for _,uid in plan.Consumed do p.Dogs[uid]=nil end
  primary.AscensionLevel=plan.OutputAscension;primary.PaidRandom=paid or primary.PaidRandom
  result.Dog=R.Copy(primary);result.Consumed=R.Copy(plan.Consumed);result.Message='Ascension '..primary.AscensionLevel..' · main dog retained'
 else
  result.Success=random()*100<plan.SuccessChance
  if result.Success then
   for _,uid in plan.Consumed do p.Dogs[uid]=nil end
   local d=R.Mint(p,plan.OutputDogId,newUid,supply,now,random,plan.Procedure=='Fusion'and'LAB_FUSION'or'LAB_EXPERIMENT',plan.OutputMutation)
   d.PaidRandom=paid or nil;d.LabRecipe=plan.RecipeId;d.PricePaid=0
   result.Dog=R.Copy(d);result.Consumed=R.Copy(plan.Consumed);result.Message='Created '..d.DisplayName..' · '..d.Variant
   result.FirstDiscovery=l.Recipes[plan.RecipeId]==nil;l.Recipes[plan.RecipeId]=l.Recipes[plan.RecipeId]or now
   l.FirstDiscoveries['RECIPE:'..plan.RecipeId]=l.FirstDiscoveries['RECIPE:'..plan.RecipeId]or now
  else
   for k,n in plan.DNA do local refund=math.floor(n*C.Stability.FailedRefund);if refund>0 then award(l,k,refund,now);result.DNA[k]=refund end end
   award(l,'StrangeDNA',1,now);result.DNA.StrangeDNA=1;result.Dog=before
   if plan.Hidden then result.RecipeId=nil end;result.Secret=false
   result.Message='Unstable result. All dogs survived and half the DNA was recovered; coins, bones and catalysts were used.'
  end
 end
 l.LastAt=now;l.Experiments+=1
 local stored=R.Copy(result);stored.BeforeDog=nil;table.insert(l.History,1,stored);while #l.History>C.MaxHistory do table.remove(l.History)end
 if result.Dog then l.FirstDiscoveries['MUTATION:'..result.Dog.Variant]=l.FirstDiscoveries['MUTATION:'..result.Dog.Variant]or now end
 State.Validate(p);R.Validate(p);return result
end
return L
