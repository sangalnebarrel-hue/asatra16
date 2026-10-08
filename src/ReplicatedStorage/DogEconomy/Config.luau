local C={}
C.Version=3
C.BalanceVersion="2026-10-05.2"
C.StartingCash=750
C.MaxCash=9000000000000000
C.MaxDogs=250
C.TickSeconds=1
C.Work={Duration=4,BaseCooldown=20,MasteryReduction=.12,MinCooldown=6,MaxCooldown=30}
C.UpgradeEffects={Dig=.04,Storage=25,Kennel=.015,Plot=.025,DogStorage=20,Ability=.02}
C.Rarities={"Common","Rare","Epic","Legendary","Mythic","Secret"}
C.Power={1,1.3,1.7,2.3,3.1,4.2}
C.Prices={150,900,7500,45000,300000,2500000}
-- Per-spawn rarity odds on the tongue (sum 100), tuned to Steal a Brainrot's real-time
-- feel at ~5.6 dogs/min: Legendary ~7 min, Mythic ~24 min, a Secret ~2 h per server.
C.Weights={60.5,27,9,2.6,.75,.15}
-- How the Secret budget is shared on the tongue (per mille). THE DOG is the legend:
-- ~1 in 95,000 line dogs, roughly once per 280 hours of one server.
C.SecretLineWeights={Cubedog=240,Dogdogdogdog=210,Spiderdog=160,WrongDog=120,NuclearPug=85,
 LongDog=50,['404Dog']=60,UnfinishedDog=38,DivineDog=30,TheDog=7}
-- What a Secret costs on the tongue (BasePrice stays C.Prices[6] for every other use).
-- Like Steal a Brainrot, the rarer it walks, the more it costs.
C.SecretLinePrices={Cubedog=2500000,Dogdogdogdog=3000000,Spiderdog=3500000,WrongDog=4000000,NuclearPug=4500000,
 LongDog=5000000,['404Dog']=5500000,UnfinishedDog=7000000,DivineDog=8000000,TheDog=16000000}
-- Rarity is not tied to depth: the conveyor is shared by players at every depth.
C.DogMinLayer={1,1,1,1,1,1}
-- rank=seconds: a soft safety net (~3x the natural interval) for a quiet server, not a
-- schedule. Secrets are never guaranteed.
C.LineGuarantee={[4]=1200,[5]=4500}
C.SpecialAcquisition={LongDog={MinLayer=4,Chance=1/20000},TheDog={MinLayer=5,MinPrestige=1,Interval=900,Chance=1/1000,ClaimCooldown=86400}}
-- THE DOG now arrives on the tongue (SecretLineWeights) with its cinematic; the old
-- silent straight-to-inventory server arrival is off (ArrivalChance=0, code kept).
-- LONG DOG walks the tongue too (SecretLineWeights); digging it up is off (LongDogChance=0;
-- a discovery already pending still resolves).
C.SpecialDiscovery={LongDogChance=0,LongDogMinLayer=4,ArrivalInterval=900,ArrivalChance=0}
C.Retire={1,5,20,80,300,1200}
C.Variants={
 {Name="Normal",Weight=9150,Bonus=0},{Name="Shiny",Weight=550,Bonus=.03},
 {Name="Golden",Weight=200,Bonus=.06},{Name="Corrupted",Weight=70,Bonus=.10},
 {Name="Glitched",Weight=25,Bonus=.12},{Name="Void",Weight=5,Bonus=.15},
}
C.Diminishing={1,.35,.10,.03,.01}
C.Ascension={0,.03,.06,.10}
C.Weeks={"Dachshund","Undead","Cyber","Food"}
C.Layers={
 {Name="Backyard",Depth="0–10m",Cost=0,Level=1,Hardness=1,Color={126,169,80},Event="Golden Soil",
  Loot={{"Old Sneaker","Junk",35,6},{"Buried Lunch","Food",24,15},{"Chewed Bone","Bone",20,21},{"Dry Seed Pod","Dry",10,24},{"Golden Tag","Gold",8,60},{"Tiny Treasure Pouch","Treasure",2.7,120},{"Buried Compass","Artifact",.3,750}}},
 {Name="Caverns",Depth="10–50m",Cost=1500,Level=4,Hardness=1.2,Color={176,143,107},Event="Retro Cache",
  Loot={{"Dry Quartz","Dry",22,15},{"Fossil Bone","Bone",20,24},{"Iron Deposit","Heavy",18,38},{"Gold Nugget","Gold",16,52},{"Underground Pearl","Water",12,38},{"Miner Relic","Artifact",8,90},{"Crystal Cache","Treasure",3.5,225},{"Sealed Geode","Unknown",.5,900}}},
 {Name="Ancient Ruins",Depth="50–150m",Cost=10000,Level=9,Hardness=1.5,Color={54,192,231},Event="Data Rain",
  Loot={{"Stone Tablet","Artifact",30,65},{"Royal Cache","Treasure",22,75},{"Ancient Coin","Gold",17,95},{"Sealed Relic","Unknown",12,120},{"Forgotten Memory","Digital",8,100},{"Preserved Feast","Food",5,90},{"Statue Fragment","Heavy",4,150},{"Fallen Star Relic","Space",2,300}}},
 {Name="Cursed Depths",Depth="150–500m",Cost=50000,Level=16,Hardness=2,Color={167,61,210},Event="Cleanse Surge",
  Loot={{"Corrupted Scrap","Corrupted",30,120},{"Cursed Bone","Bone",22,130},{"Contraband Cache","Contraband",18,180},{"Burning Ember","Energy",12,170},{"Obsidian Idol","Artifact",10,250},{"Cursed Vault","Treasure",5,400},{"Unknown Heart","Unknown",2,800},{"Dark Meteor","Space",1,1700}}},
 {Name="THE VOID",Depth="500m+",Cost=300000,Level=28,Hardness=2.5,Color={72,41,124},Event="Void Eclipse",
  Loot={{"Void Dust","Void",30,250},{"Black Star","Space",22,340},{"Reality Data","Digital",15,300},{"Unknown Signal","Unknown",12,400},{"Solar Fragment","Energy",10,450},{"Void Tide Pearl","Water",6,500},{"Lost Planet Cache","Treasure",4,1000},{"First Echo","Artifact",1,3000}}},
}
C.Upgrades={
 Dig={Base=300,Factor=1.8,Max=10},Storage={Base=250,Factor=1.7,Max=10},
 Kennel={Base=500,Factor=1.8,Max=10},Plot={Base=300,Factor=2.2,Max=8},
 DogStorage={Base=450,Factor=1.8,Max=10},Ability={Base=1000,Factor=2,Max=6},
}
-- Coin prices of boosts follow the economy (ReplicatedStorage.DogEconomy.BoostPricing): a share
-- of what the team earns during the boost (IncomeShare × Seconds × income per second), never
-- below Cash × LayerScale[deepest unlocked layer]. Robux bundles scale their coins the same way.
C.BoostPricing={LayerScale={1,3,8,20,50},PeakHalfLife=6*3600}
-- Luck lives in its own tab (LUCK). The Supplies shop sells the other three.
C.SupplyOrder={"GoldenBiscuit","EnergySnack","StorageCrate"}
C.Supplies={
 -- No longer sold: kept so saved timers and Donut Corgi's treats keep working.
 LuckyTreat={Name="Lucky Treat",Order=9,Cash=400,Seconds=600,MaxSeconds=3600,Effect="Luck",Magnitude=.12,Hidden=true,IncomeShare=.05,
  EffectText="+12% base rare-find weight",
  Description="Boosts Artifact, Treasure, Rare and Space weights in ordinary digging."},
 GoldenBiscuit={Name="Golden Biscuit",Order=1,Cash=400,Seconds=600,MaxSeconds=3600,Effect="Value",Magnitude=.20,IncomeShare=.09,
  EffectText="+20% Coins from ordinary loot",
  Description="Ordinary loot your dogs dig is worth 20% more Coins. Stacks on top of every other value bonus."},
 EnergySnack={Name="Energy Snack",Order=2,Cash=300,Seconds=600,MaxSeconds=3600,Effect="Speed",Magnitude=.25,IncomeShare=.09,
  EffectText="+25% digging speed",
  Description="Shorter rests between digs for the whole team. Stacks with other speed bonuses up to the team speed cap."},
 StorageCrate={Name="Storage Crate",Order=3,Cash=200,Seconds=600,MaxSeconds=3600,Effect="Storage",Magnitude=100,IncomeShare=.04,
  EffectText="+100 ordinary-loot spaces",
  Description="Holds more ordinary finds until you sell. Does not add dog or item slots. Existing loot stays safe when it expires."},
}
-- Personal luck (LUCK tab): Nx LUCK = +N×100% weight on rare loot in ordinary digging and a
-- bigger chance of rare discoveries. Every tier has its own timer; the highest active one counts.
C.LuckTiers={
 {Tier=1,Name="1x LUCK",Bonus=1,Cash=500,IncomeShare=.04,Seconds=600,MaxSeconds=3600},
 {Tier=2,Name="2x LUCK",Bonus=2,Cash=1500,IncomeShare=.10,Seconds=600,MaxSeconds=3600},
 {Tier=3,Name="3x LUCK",Bonus=3,Cash=4000,IncomeShare=.20,Seconds=600,MaxSeconds=3600},
 {Tier=4,Name="4x LUCK",Bonus=4,Cash=10000,IncomeShare=.35,Seconds=600,MaxSeconds=3600},
 {Tier=5,Name="5x LUCK",Bonus=5,Cash=25000,IncomeShare=.55,Seconds=600,MaxSeconds=3600},
}
-- Rare discoveries (items under 1% base chance) gain this much chance per luck tier.
C.LuckItemBoost=.4
-- Server luck (Robux): multiplies the tongue's Legendary/Mythic/Secret odds for everyone here.
C.ServerLuck={Ranks={4,5,6},MaxSeconds=7200}
C.Cosmetics={GoldenKennel={Cash=5000},CyberKennel={Cash=25000},VoidAura={Cash=100000,Bones=100},FounderPlaque={Cash=10000}}
C.EventGoal=100000
C.EventMilestones={1000,5000,20000,50000,100000}
C.EventPersonal={25,100,300,700,1500}
C.MaxListingsPerDog=150
C.MaxAuctions=1500
C.SessionSeconds=180
C.AuctionDurations={300,3600,86400}
return C
