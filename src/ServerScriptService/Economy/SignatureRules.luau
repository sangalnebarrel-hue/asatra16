-- Server-only dog signatures. Per-dog work cannot multiply another dog's roll count.
local S={}
local function active(d)return type(d.AssignedSlot)=='string' and d.AssignedSlot~='' and d.State~='Walking'end
local function slot(d)return tonumber((d.AssignedSlot or ''):match('%d+')) or 0 end
local function near(a,b)return a~=b and math.abs(slot(a)-slot(b))==1 end
local function add(t,k,n)t[k]=(t[k]or 0)+n end
function S.Team(p,now)
 local e={SetBonus=0,FoodCount=0,ById={}};local groups={}
 for _,d in pairs(p.Dogs)do if active(d)then
  local id=d.DogId;groups[id]=(groups[id]or 0)+1;e.ById[id]=true
  if d.FoodDog then e.FoodCount+=1 end
 end end
 for id,n in pairs(groups)do
  local strength=1+(n>1 and .25 or 0)+(n>2 and .1 or 0)
  if id=='KingCorgi'then add(e,'SellValue',.12*strength)
  elseif id=='CaptainCorgi'then add(e,'DigSpeed',.12*strength)
  elseif id=='Bonshiba'then add(e,'Recovery',.05*strength);add(e,'Luck',.04*strength)
  elseif id=='DiscoDoggo'and now%90<15 then add(e,'DigSpeed',.18*strength)
  elseif id=='DJBarkbeat'and now%120<20 then add(e,'DigSpeed',.30*strength)
  elseif id=='Ramendog'then add(e,'XPBonus',.20*strength);add(e,'Recovery',.05*strength)
  elseif id=='GodOfBark'then add(e,'SellValue',.08*strength);add(e,'DigSpeed',.08*strength);add(e,'Luck',.08*strength)
  elseif id=='DogeEmperor'then add(e,'SellValue',.15*strength)
  elseif id=='MilkyPup'then add(e,'Recovery',.05*strength)
  elseif id=='PoliceShiba'then add(e,'Cleanse',.15*strength)
  elseif id=='AngelDoggo'then add(e,'Protection',.10*strength)
  elseif id=='BlackHolePug'then add(e,'Storage',.30*strength)
  elseif id=='TaxiDachshund'then add(e,'Storage',.15*strength)
  elseif id=='TheDog'then add(e,'SellValue',.10*strength);add(e,'Luck',.10*strength)end
 end
 for _,k in ipairs({'SellValue','DigSpeed','Recovery','Luck','Cleanse','Protection','XPBonus'})do e[k]=math.min(.30,e[k]or 0)end
 e.Storage=math.min(.75,e.Storage or 0)
 return e
end
function S.Speed(p,d,now)
 local speed=1;local id=d.DogId
 if id=='Potatodog'then speed=.8 elseif id=='Robopug3000'then speed=1.22 elseif id=='Skatehound'then speed=1.16 elseif id=='MechaBark'then speed=.8 end
 if id=='Pugsicola'and now<(p.LastSaleAt or 0)+30 then speed+=.25 end
 for _,other in pairs(p.Dogs)do if active(other)and near(d,other)then
  if other.DogId=='CoffeeDog'then speed+=.10 elseif other.DogId=='DJDoggo'and now%60<15 then speed+=.18 elseif other.DogId=='DrPug'then speed+=.08 end
 end end
 if now<(p.TimePulseUntil or 0)then speed+=.15 end
 return math.clamp(speed,.65,1.6)
end
function S.Context(p,d,e,now,random)
 local id=d.DogId;local seq=d.WorkSequence or 1
 local c={Rolls=2,Value=1,XP=1,Depth=p.CurrentLayer,CategoryLuck={},CategoryValue={},WeightLuck=0,ItemAttempts=1,ItemScale=1,MutationChance=0,MutationValue=1}
 local function luck(cat,n)c.CategoryLuck[cat]=n end
 local function value(cat,n)c.CategoryValue[cat]=n end
 local function extra(chance,n)if random()<chance then c.Rolls+=n or 1 end end
 local function mutation(name,chance,mult)c.Mutation=name;c.MutationChance=chance;c.MutationValue=mult end
 local function deeper(chance)if random()<chance then c.Depth=math.min(5,p.CurrentLayer+1);c.Value*=.65 end end
 if id=='Breadog'then luck('Food',2)
 elseif id=='Sausagedog'then extra(.18);c.Pocket='Narrow'
 elseif id=='Potatodog'then c.Rolls=3;c.Value=.8
 elseif id=='Bananabull'then c.BananaCombo=true
 elseif id=='Toasterrier'then mutation('Toasted',.12,1.35)
 elseif id=='Pugsicola'then c.SaleBurst=true
 elseif id=='Pizzapup'then value('Food',1+math.min(.30,(e.FoodCount or 0)*.06))
 elseif id=='Burgerdog'then value('Food',1.22);c.WeightLuck=.06
 elseif id=='Tacodach'then extra(.18);c.Value=.95
 elseif id=='CoffeeDog'then c.NeighborSupport=true
 elseif id=='DonutCorgi'then c.TreatChance=.025
 elseif id=='Melondog'then c.WeightLuck=.12;c.Value=1.08
 elseif id=='Chipdog'then value('Junk',1.30)
 elseif id=='NuggetPup'then luck('Gold',1.8)
 elseif id=='MilkyPup'then c.Comfort=true
 elseif id=='Corndoggo'then c.Value=1.12
 elseif id=='PancakeBull'then extra(.16);c.Area=1.25
 elseif id=='Eggdog'then c.HatchChance=.03
 elseif id=='Pelmendog'then if seq%3==0 then c.Rolls=4;c.Value=.85 end
 elseif id=='KetchupPup'then value('Food',1+math.min(.30,(d.FoodStreak or 0)*.05))
 elseif id=='Bulldoger'then c.Hardness=.35
 elseif id=='Firepup'then mutation('Burned',.15,1.45);luck('Energy',1.5)
 elseif id=='DrPug'then c.NeighborSupport=true
 elseif id=='SheriffShiba'then value('Junk',1.25);value('Contraband',1.35)
 elseif id=='NinjaInu'then extra(.20)
 elseif id=='Barkbeard'then luck('Treasure',1.8);value('Treasure',1.15)
 elseif id=='DJDoggo'then c.NeighborSupport=true
 elseif id=='Skatehound'then c.AutoDeposit=.20
 elseif id=='TaxiDachshund'then c.AutoDeposit=.10;value('Heavy',1.1)
 elseif id=='GamerDog'then luck('Digital',2)
 elseif id=='PoliceShiba'then c.Protection=.20
 elseif id=='RappaRotti'then c.Value=1+math.min(.25,seq%6*.05)
 elseif id=='ProfessorBark'then value('Unknown',1.5);c.Identify=true
 elseif id=='CraneCorgi'then luck('Heavy',1.8);c.WeightLuck=.10
 elseif id=='DonPuglione'then local cats={'Food','Junk','Gold','Artifact','Heavy'};value(cats[math.floor(now/300)%#cats+1],1.40)
 elseif id=='Samuriba'then if seq%10==0 then c.Value=5;c.Critical=true end
 elseif id=='Astrodoggo'then luck('Space',2)
 elseif id=='Sharkshund'then luck('Water',2);value('Water',1.25)
 elseif id=='Crabull'then c.Rolls=4;c.Value=.56
 elseif id=='CactusCorgi'then luck('Dry',2);if p.CurrentLayer==1 or p.CurrentLayer==3 then c.Value=1.2 end
 elseif id=='Mushpup'then mutation('Spore',.15,1.4)
 elseif id=='Bonshiba'then c.Comfort=true
 elseif id=='CowboyCorg'then luck('Treasure',1.6);value('Treasure',1+math.min(.45,(d.TreasureStreak or 0)*.10))
 elseif id=='Knightweiler'then c.Hardness=.55
 elseif id=='VikingDoggo'then luck('Heavy',1.5);value('Heavy',1.40)
 elseif id=='FrostHusky'then mutation('Frozen',.15,1.5)
 elseif id=='LavaBull'then c.Hardness=.6;luck('Energy',1.6)
 elseif id=='BooHound'then c.Hardness=.45;extra(.1)
 elseif id=='Zombark'then luck('Bone',2);value('Bone',1.35)
 elseif id=='Vampug'then if now%86400>=64800 or e.EventId then c.Value=1.25 end
 elseif id=='NeonHound'then value('Digital',1.5)
 elseif id=='Glitchiba'then extra(.22);mutation('Glitched',.02,1.8)
 elseif id=='DiscoDoggo'then c.Party=true
 elseif id=='TvTerrier'then luck('Digital',2);value('Digital',1.18)
 elseif id=='ArcadeAkita'then luck('Artifact',1.8);luck('Digital',1.4)
 elseif id=='CyberCorgi'then value('Junk',1.4);value('Digital',1.30);c.AutoDeposit=.12
 elseif id=='Robopug3000'then c.Value=1.05
 elseif id=='MechaShiba'then c.Hardness=.7;extra(.2)
 elseif id=='RocketDachshund'then deeper(.12)
 elseif id=='UfoDog'then luck('Space',2);luck('Artifact',1.6)
 elseif id=='AngelDoggo'then c.Protection=.25;c.BadLuckGuard=true
 elseif id=='DemonDoggo'then c.Value=random()<.18 and .3 or 1.35;c.Risk=true
 elseif id=='WizardWoof'then local n=random();if n<.33 then c.Value=1.3 elseif n<.66 then c.WeightLuck=.15 else c.Rolls=3;c.Value=.85 end
 elseif id=='Necrohound'then c.SkeletonChance=.2;luck('Bone',1.8)
 elseif id=='CaptainBark'then if seq%15==0 then p.TreasureMapUntil=now+45 end;luck('Treasure',1.6)
 elseif id=='KingCorgi'then c.Royal=true
 elseif id=='Dogzilla'then c.Rolls=6;c.Value=.42;c.Area=3
 elseif id=='SharkdogPrime'then luck('Water',2.2);luck('Void',1.6);deeper(.08)
 elseif id=='MechaBark'then if seq%3==0 then c.Rolls=6;c.Value=.7 else c.Value=.7 end
 elseif id=='CaptainCorgi'then c.Morale=true
 elseif id=='Barkula'then value('Void',1.45);if now%86400>=64800 or(e.Night or 0)>0 then c.Value=1.2 end
 elseif id=='Pharaohound'then luck('Artifact',2.2);if p.CurrentLayer==3 then c.Value=1.25 end
 elseif id=='Poseidog'then luck('Water',2);luck('Treasure',1.8);value('Water',1.3)
 elseif id=='ThunderHusky'then extra(.4,2);c.Value=.9
 elseif id=='InfernoBull'then c.Hardness=.85;mutation('Infernal',.18,1.7)
 elseif id=='Sushiba'then luck('Food',1.8);value('Food',1.6);value('Artifact',1.2)
 elseif id=='Ramendog'then c.Comfort=true
 elseif id=='DragonShiba'then deeper(.12);luck('Treasure',1.8)
 elseif id=='Tankweiler'then c.Hardness=1;value('Heavy',1.2)
 elseif id=='DJBarkbeat'then c.Party=true
 elseif id=='Cerberdog'then c.Value=1.15;c.XP=1.5;luck('Artifact',1.4)
 elseif id=='GalaxyHusky'then deeper(.20)
 elseif id=='BlackHolePug'then c.Orbit=true;c.AutoDeposit=1
 elseif id=='TimeDog'then if random()<.15 then p.TimePulseUntil=now+12;c.Rolls=4;c.Value=.7 end
 elseif id=='GodOfBark'then c.Aura=true
 elseif id=='Moonmoon'then c.Rolls=3;c.Value=.8;c.ItemAttempts=2;c.ItemScale=.60
 elseif id=='SunDog'then luck('Energy',2.2);mutation('Solar',.15,1.7)
 elseif id=='VoidHound'then luck('Void',2.3);if p.CurrentLayer==5 then c.Value=1.3 end
 elseif id=='GoldenBoi'then c.WeightLuck=.15;c.Value=1.45
 elseif id=='DogeEmperor'then c.EconomyAura=true
 elseif id=='LongDog'then deeper(.3);c.Hardness=.7
 elseif id=='Cubedog'then if seq%4==0 then c.Rolls=6;c.Value=.8 else c.Value=.9 end
 elseif id=='Dogdogdogdog'then c.Rolls=8;c.Value=.30;c.ItemAttempts=4;c.ItemScale=.30
 elseif id=='WrongDog'then local n=random();c.Value=n<.15 and .15 or n<.25 and 4 or 1;c.Risk=true;mutation('Cursed',.08,1.5)
 elseif id=='404Dog'then deeper(1);c.Value*=1.15
 elseif id=='NuclearPug'then mutation('Radioactive',.25,2);c.SpoilChance=.08
 elseif id=='Spiderdog'then c.Rolls=8;c.Value=.32;c.ItemAttempts=2;c.ItemScale=.6
 elseif id=='DivineDog'then c.Rolls=6;c.Value=.42;c.ItemAttempts=3;c.ItemScale=.45;luck('Artifact',1.3)
 elseif id=='UnfinishedDog'then local n=random();if n<.12 then c.Rolls=0;c.ItemAttempts=0;c.Missing=true elseif n<.32 then c.Rolls=6;c.Value=.9;c.Triplicate=true end
 elseif id=='TheDog'then if seq%20==0 then c.Rolls=10;c.Value=.8;c.Depth=5;c.ItemAttempts=3;c.ItemScale=.5;c.Genesis=true else c.Value=1.2 end
 elseif id=='Aurion'then
  -- WorkSequence advances only inside the existing persistent server dig.
  -- One extra independent item roll every tenth dig; no cloned reward and no
  -- separate animation callback can mint loot or reset the progression.
  if seq%10==0 then c.ItemAttempts=2;c.PrismEcho=true end
 end
 if now<(p.TreasureMapUntil or 0)then luck('Treasure',(c.CategoryLuck.Treasure or 1)*1.3)end
 if c.Hardness then c.Value*=1+c.Hardness*.15*math.max(0,p.CurrentLayer-1)/4 end
 c.Rolls=math.clamp(c.Rolls,0,12);c.WeightLuck=math.min(.15,c.WeightLuck)
 return c
end
function S.Modify(c,item,d,random,e)
 local name,category=item[1],item[2];local mult=c.Value*(c.CategoryValue[category]or 1);local mutation
 if category=='Food'then d.FoodStreak=math.min(6,(d.FoodStreak or 0)+1)else d.FoodStreak=0 end
 if category=='Treasure'or category=='Artifact'then d.TreasureStreak=math.min(5,(d.TreasureStreak or 0)+1)else d.TreasureStreak=0 end
 if c.BananaCombo and category=='Junk'and random()<.18 then name='Banana Combo';category='Food';mult*=2 end
 if c.Identify and category=='Unknown'then name='Identified '..name;category='Artifact'end
 if c.SkeletonChance and category=='Bone'and random()<c.SkeletonChance then name='Ancient Skeleton';mult*=2 end
 if c.Mutation and random()<c.MutationChance then mutation=c.Mutation;name=mutation..' '..name;mult*=c.MutationValue end
 if c.SpoilChance and random()<c.SpoilChance*(1-math.min(.8,(e.Cleanse or 0)+(e.Protection or 0)))then name='Spoiled '..item[1];mult*=.2;mutation='Spoiled'end
 return name,category,math.max(.05,mult),mutation
end
S.Active=active
return S
