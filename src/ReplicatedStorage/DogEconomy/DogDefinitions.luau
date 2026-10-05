-- Economy v3: canonical ordered roster. IDs and visual assets preserve existing ownership.
local C = require(script.Parent.Config)
local rows = {
 {Index=1,Id="Breadog",DisplayName="Breadog",Rank=1,Ability="FoodFinder",Signature="Sometimes excavates extra Food loot.",Tags={"Food"},VisualAsset="Breadog",LayerAffinity=1,Acquisition="Standard"},
 {Index=2,Id="Sausagedog",DisplayName="Sausagedog",Rank=1,Ability="NarrowPocket",Signature="Reaches narrow pockets for an extra find.",Tags={"Food","Dachshund"},VisualAsset="Sausagedog",LayerAffinity=1,Acquisition="Standard"},
 {Index=3,Id="Potatodog",DisplayName="Potatodog",Rank=1,Ability="SlowQuantity",Signature="Slower excavation with increased quantity.",Tags={"Food"},VisualAsset="POTATO_DOGE_Roblox",LayerAffinity=1,Acquisition="Standard"},
 {Index=4,Id="Bananabull",DisplayName="Bananabull",Rank=1,Ability="BananaCombo",Signature="Banana junk can trigger a bonus combo.",Tags={"Food"},VisualAsset="BANANA_BULL_Roblox",LayerAffinity=1,Acquisition="Standard"},
 {Index=5,Id="Toasterrier",DisplayName="Toasterrier",Rank=1,Ability="ToastedFind",Signature="Can toast a find for extra value.",Tags={"Food"},VisualAsset="Toasterrier",LayerAffinity=1,Acquisition="Standard"},
 {Index=6,Id="Pugsicola",DisplayName="Pugsicola",Rank=1,Ability="SaleBurst",Signature="A short digging speed burst after a sale.",Tags={"Food"},VisualAsset="PUG_SICOLA_Roblox",LayerAffinity=1,Acquisition="Standard"},
 {Index=7,Id="Pizzapup",DisplayName="Pizzapup",Rank=1,Ability="FoodSynergy",Signature="Food dogs improve its excavation rewards.",Tags={"Food"},VisualAsset="PIZA_PUP_Roblox",LayerAffinity=1,Acquisition="Standard"},
 {Index=8,Id="Burgerdog",DisplayName="Burgerdog",Rank=1,Ability="FoodWeight",Signature="Food finds gain extra weight.",Tags={"Food"},VisualAsset="Burgerdog",LayerAffinity=1,Acquisition="Standard"},
 {Index=9,Id="Tacodach",DisplayName="Tacodach",Rank=1,Ability="SmallDouble",Signature="Can excavate a second small find.",Tags={"Food","Dachshund"},VisualAsset="TACO_DACH_Roblox",LayerAffinity=1,Acquisition="Standard"},
 {Index=10,Id="CoffeeDog",DisplayName="Coffee Dog",Rank=1,Ability="NeighborCoffee",Signature="Speeds up neighboring dogs.",Tags={"Food"},VisualAsset="CoffeeDog",LayerAffinity=1,Acquisition="Standard"},
 {Index=11,Id="DonutCorgi",DisplayName="Donut Corgi",Rank=1,Ability="TreatFinder",Signature="Sometimes finds a short Lucky Treat.",Tags={"Food"},VisualAsset="DONUT_CORGI_Roblox",LayerAffinity=1,Acquisition="Standard"},
 {Index=12,Id="Melondog",DisplayName="Melondog",Rank=1,Ability="WeightBoost",Signature="Excavates heavier finds.",Tags={"Food"},VisualAsset="MELON_DOG_Roblox",LayerAffinity=1,Acquisition="Standard"},
 {Index=13,Id="Chipdog",DisplayName="Chipdog",Rank=1,Ability="JunkMerchant",Signature="Junk sells for more coins.",Tags={"Food"},VisualAsset="CHIPI_DOG_Roblox",LayerAffinity=1,Acquisition="Standard"},
 {Index=14,Id="NuggetPup",DisplayName="Nugget Pup",Rank=1,Ability="GoldFinder",Signature="Increases the chance of Gold finds.",Tags={"Food"},VisualAsset="NUGGET_PUP_Roblox",LayerAffinity=1,Acquisition="Standard"},
 {Index=15,Id="MilkyPup",DisplayName="Milky Pup",Rank=1,Ability="Comfort",Signature="Reduces team fatigue and cooldowns.",Tags={"Food"},VisualAsset="MILKY_PUP_Roblox",LayerAffinity=1,Acquisition="Standard"},
 {Index=16,Id="Corndoggo",DisplayName="Corndoggo",Rank=1,Ability="SteadyDigger",Signature="Reliable excavation with stable output.",Tags={"Food"},VisualAsset="CORN_DOGGO_Roblox",LayerAffinity=1,Acquisition="Standard"},
 {Index=17,Id="PancakeBull",DisplayName="Pancake Bull",Rank=1,Ability="WideDig",Signature="A wider excavation can hit an extra pocket.",Tags={"Food"},VisualAsset="PANCAKE_BULL_Roblox",LayerAffinity=1,Acquisition="Standard"},
 {Index=18,Id="Eggdog",DisplayName="Eggdog",Rank=1,Ability="MysteryHatch",Signature="Sometimes excavates a mystery hatch reward.",Tags={"Food"},VisualAsset="EGG_DOG_Roblox",LayerAffinity=1,Acquisition="Standard"},
 {Index=19,Id="Pelmendog",DisplayName="PelmenDog",Rank=1,Ability="BatchRoll",Signature="Rolls into the soil for a batch of finds.",Tags={"Food"},VisualAsset="PELMEN_DOG_Roblox",LayerAffinity=1,Acquisition="Standard"},
 {Index=20,Id="KetchupPup",DisplayName="Ketchup Pup",Rank=1,Ability="FoodCombo",Signature="Food discoveries build a value combo.",Tags={"Food"},VisualAsset="KetchupPup",LayerAffinity=1,Acquisition="Standard"},
 {Index=21,Id="Bulldoger",DisplayName="Bulldoger",Rank=2,Ability="DenseSoil",Signature="Penetrates dense ground more effectively.",Tags={"Explorers"},VisualAsset="BULL_DOGER_Roblox",LayerAffinity=2,Acquisition="Standard"},
 {Index=22,Id="Firepup",DisplayName="Firepup",Rank=2,Ability="BurnedFind",Signature="Can burn finds into valuable Infernal loot.",Tags={"Explorers"},VisualAsset="FIRE_PUP_Roblox",LayerAffinity=2,Acquisition="Standard"},
 {Index=23,Id="DrPug",DisplayName="Dr. Pug",Rank=2,Ability="NeighborSupport",Signature="Supports neighboring dogs and reduces downtime.",Tags={"Explorers"},VisualAsset="DR_PUG_Roblox",LayerAffinity=2,Acquisition="Standard"},
 {Index=24,Id="SheriffShiba",DisplayName="Sheriff Shiba",Rank=2,Ability="SheriffValue",Signature="Contraband and Junk sell for more.",Tags={"Explorers"},VisualAsset="SheriffShiba_Roblox",LayerAffinity=2,Acquisition="Standard"},
 {Index=25,Id="NinjaInu",DisplayName="Ninja Inu",Rank=2,Ability="HiddenDig",Signature="Can make an instant additional excavation.",Tags={"Explorers"},VisualAsset="NINJA_INU_Roblox",LayerAffinity=2,Acquisition="Standard"},
 {Index=26,Id="Barkbeard",DisplayName="Barkbeard",Rank=2,Ability="TreasureFinder",Signature="Improves Treasure discovery chances.",Tags={"Explorers"},VisualAsset="BARKBEARD_Roblox",LayerAffinity=2,Acquisition="Standard"},
 {Index=27,Id="DJDoggo",DisplayName="DJ Doggo",Rank=2,Ability="RhythmAura",Signature="A rhythm buff speeds up neighboring dogs.",Tags={"Explorers"},VisualAsset="DJDoggo",LayerAffinity=2,Acquisition="Standard"},
 {Index=28,Id="Skatehound",DisplayName="Skatehound",Rank=2,Ability="FastDelivery",Signature="Fast delivery improves storage throughput.",Tags={"Explorers"},VisualAsset="SKATE_HOUND_Roblox",LayerAffinity=2,Acquisition="Standard"},
 {Index=29,Id="TaxiDachshund",DisplayName="Taxi Dachshund",Rank=2,Ability="TaxiDelivery",Signature="Transport support improves team storage.",Tags={"Explorers","Dachshund"},VisualAsset="TAXI_DACHSHUND_Roblox",LayerAffinity=2,Acquisition="Standard"},
 {Index=30,Id="GamerDog",DisplayName="Gamer Dog",Rank=2,Ability="DigitalLuck",Signature="Improves Digital discovery luck.",Tags={"Explorers"},VisualAsset="GamerDog",LayerAffinity=2,Acquisition="Standard"},
 {Index=31,Id="PoliceShiba",DisplayName="Police Shiba",Rank=2,Ability="CorruptionGuard",Signature="Reduces harmful corrupted outcomes.",Tags={"Explorers"},VisualAsset="PoliceShiba",LayerAffinity=2,Acquisition="Standard"},
 {Index=32,Id="RappaRotti",DisplayName="Rappa Rotti",Rank=2,Ability="FindCombo",Signature="Consecutive discoveries increase value.",Tags={"Explorers"},VisualAsset="RappaRotti",LayerAffinity=2,Acquisition="Standard"},
 {Index=33,Id="ProfessorBark",DisplayName="Professor Bark",Rank=2,Ability="IdentifyArtifact",Signature="Identifies unknown artifacts for extra value.",Tags={"Explorers"},VisualAsset="ProfessorBark",LayerAffinity=2,Acquisition="Standard"},
 {Index=34,Id="CraneCorgi",DisplayName="Crane Corgi",Rank=2,Ability="HeavyLift",Signature="Lifts heavier discoveries.",Tags={"Explorers"},VisualAsset="CRANE_CORGI_Roblox",LayerAffinity=2,Acquisition="Standard"},
 {Index=35,Id="DonPuglione",DisplayName="Don Puglione",Rank=2,Ability="CategoryDeal",Signature="One rotating category sells for more.",Tags={"Explorers"},VisualAsset="DonPuglione",LayerAffinity=2,Acquisition="Standard"},
 {Index=36,Id="Samuriba",DisplayName="Samuriba",Rank=2,Ability="TenthCritical",Signature="Every tenth excavation has critical power x5.",Tags={"Explorers"},VisualAsset="Samuriba",LayerAffinity=2,Acquisition="Standard"},
 {Index=37,Id="Astrodoggo",DisplayName="AstroDoggo",Rank=2,Ability="SpaceFinder",Signature="Improves Space discovery chances.",Tags={"Cosmic"},VisualAsset="Astrodoggo",LayerAffinity=2,Acquisition="Standard"},
 {Index=38,Id="Sharkshund",DisplayName="Sharkshund",Rank=2,Ability="WetSpecialist",Signature="Specializes in wet excavation pockets.",Tags={"Explorers","Dachshund"},VisualAsset="Sharkshund",LayerAffinity=2,Acquisition="Standard"},
 {Index=39,Id="Crabull",DisplayName="Crabull",Rank=2,Ability="SideDig",Signature="Can dig two adjacent pockets.",Tags={"Explorers"},VisualAsset="Crabull",LayerAffinity=2,Acquisition="Standard"},
 {Index=40,Id="CactusCorgi",DisplayName="Cactus Corgi",Rank=2,Ability="DrySpecialist",Signature="Specializes in dry ground.",Tags={"Explorers"},VisualAsset="CACTUS_CORGI_Roblox",LayerAffinity=2,Acquisition="Standard"},
 {Index=41,Id="Mushpup",DisplayName="Mushpup",Rank=2,Ability="SporeFind",Signature="Can give a find a Spore mutation.",Tags={"Explorers"},VisualAsset="MUSH_PUP_Roblox",LayerAffinity=2,Acquisition="Standard"},
 {Index=42,Id="Bonshiba",DisplayName="Bonshiba",Rank=2,Ability="EcoAura",Signature="A gentle passive team economy buff.",Tags={"Explorers"},VisualAsset="Bonshiba",LayerAffinity=2,Acquisition="Standard"},
 {Index=43,Id="CowboyCorg",DisplayName="Cowboy Corg",Rank=2,Ability="TreasureStreak",Signature="Treasure discoveries build a streak bonus.",Tags={"Explorers"},VisualAsset="CowboyCorg",LayerAffinity=2,Acquisition="Standard"},
 {Index=44,Id="Knightweiler",DisplayName="Knightweiler",Rank=2,Ability="ArmorDig",Signature="Penetrates harder excavation layers.",Tags={"Explorers"},VisualAsset="Knightweiler",LayerAffinity=2,Acquisition="Standard"},
 {Index=45,Id="VikingDoggo",DisplayName="Viking Doggo",Rank=2,Ability="HeavyFinder",Signature="Improves heavy loot rewards.",Tags={"Explorers"},VisualAsset="VikingDoggo",LayerAffinity=2,Acquisition="Standard"},
 {Index=46,Id="FrostHusky",DisplayName="Frost Husky",Rank=2,Ability="FrozenFind",Signature="Can freeze a discovery for extra value.",Tags={"Explorers"},VisualAsset="FROST_HUSKY_Roblox",LayerAffinity=2,Acquisition="Standard"},
 {Index=47,Id="LavaBull",DisplayName="Lava Bull",Rank=2,Ability="VolcanicDig",Signature="Breaks through volcanic and hard ground.",Tags={"Explorers"},VisualAsset="LavaBull",LayerAffinity=2,Acquisition="Standard"},
 {Index=48,Id="BooHound",DisplayName="Boo Hound",Rank=2,Ability="PhaseDig",Signature="Phases through solid obstacles into extra pockets.",Tags={"Undead"},VisualAsset="BooHound",LayerAffinity=2,Acquisition="Standard"},
 {Index=49,Id="Zombark",DisplayName="Zombark",Rank=2,Ability="BoneFinder",Signature="Improves Bone and undead rewards.",Tags={"Undead"},VisualAsset="Zombark_Roblox",LayerAffinity=2,Acquisition="Standard"},
 {Index=50,Id="Vampug",DisplayName="Vampug",Rank=2,Ability="NightHunter",Signature="Earns a bonus at night and during dark events.",Tags={"Undead"},VisualAsset="Vampug",LayerAffinity=2,Acquisition="Standard"},
 {Index=51,Id="NeonHound",DisplayName="Neon Hound",Rank=3,Ability="DigitalValue",Signature="Digital discoveries sell for more.",Tags={"Cyber"},VisualAsset="NeonHound_Roblox",LayerAffinity=3,Acquisition="Standard"},
 {Index=52,Id="Glitchiba",DisplayName="Glitchiba",Rank=3,Ability="GlitchDuplicate",Signature="Can duplicate a discovery or skip a cooldown.",Tags={"Cyber"},VisualAsset="Glitchiba",LayerAffinity=3,Acquisition="Standard"},
 {Index=53,Id="DiscoDoggo",DisplayName="Disco Doggo",Rank=3,Ability="PartyAura",Signature="Periodic party buffs improve team speed.",Tags={"Cyber"},VisualAsset="DiscoDoggo",LayerAffinity=3,Acquisition="Standard"},
 {Index=54,Id="TvTerrier",DisplayName="TV Terrier",Rank=3,Ability="OldInternet",Signature="Improves old Internet discovery rewards.",Tags={"Cyber"},VisualAsset="TvTerrier",LayerAffinity=3,Acquisition="Standard"},
 {Index=55,Id="ArcadeAkita",DisplayName="Arcade Akita",Rank=3,Ability="RetroLuck",Signature="Improves retro artifact discovery luck.",Tags={"Cyber"},VisualAsset="ArcadeAkita",LayerAffinity=3,Acquisition="Standard"},
 {Index=56,Id="CyberCorgi",DisplayName="Cyber Corgi",Rank=3,Ability="DigitalSort",Signature="Automatically sorts finds with Digital synergy.",Tags={"Cyber"},VisualAsset="CyberCorgi",LayerAffinity=3,Acquisition="Standard"},
 {Index=57,Id="Robopug3000",DisplayName="RoboPug 3000",Rank=3,Ability="AlwaysWorking",Signature="Consistently low excavation downtime.",Tags={"Cyber"},VisualAsset="Robopug3000_Roblox",LayerAffinity=3,Acquisition="Standard"},
 {Index=58,Id="MechaShiba",DisplayName="Mecha Shiba",Rank=3,Ability="HeavyImpact",Signature="A heavy impact can uncover extra pockets.",Tags={"Cyber"},VisualAsset="MechaShiba",LayerAffinity=3,Acquisition="Standard"},
 {Index=59,Id="RocketDachshund",DisplayName="Rocket Dachshund",Rank=3,Ability="RocketPocket",Signature="Bursts into a deeper excavation pocket.",Tags={"Cyber","Dachshund"},VisualAsset="RocketDachshund",LayerAffinity=3,Acquisition="Standard"},
 {Index=60,Id="UfoDog",DisplayName="UFO Dog",Rank=3,Ability="AlienFinder",Signature="Improves Alien artifact discovery luck.",Tags={"Cyber"},VisualAsset="UFO_DOG_Roblox",LayerAffinity=3,Acquisition="Standard"},
 {Index=61,Id="AngelDoggo",DisplayName="Angel Doggo",Rank=3,Ability="BadLuckGuard",Signature="Bad streaks improve the next discovery chance.",Tags={"Explorers"},VisualAsset="AngelDoggo",LayerAffinity=3,Acquisition="Standard"},
 {Index=62,Id="DemonDoggo",DisplayName="Demon Doggo",Rank=3,Ability="RiskReward",Signature="Risks a weaker result for a stronger reward.",Tags={"Explorers"},VisualAsset="DemonDoggo",LayerAffinity=3,Acquisition="Standard"},
 {Index=63,Id="WizardWoof",DisplayName="Wizard Woof",Rank=3,Ability="RandomEnchant",Signature="Temporarily enchants excavation rewards.",Tags={"Explorers"},VisualAsset="WizardWoof",LayerAffinity=3,Acquisition="Standard"},
 {Index=64,Id="Necrohound",DisplayName="NecroHound",Rank=3,Ability="SkeletonFind",Signature="Bones can produce special skeleton loot.",Tags={"Undead"},VisualAsset="NECROHOUND_Roblox",LayerAffinity=3,Acquisition="Standard"},
 {Index=65,Id="CaptainBark",DisplayName="Captain Bark",Rank=3,Ability="TreasureMap",Signature="Can trigger a small Treasure Map reward.",Tags={"Explorers"},VisualAsset="CaptainBark",LayerAffinity=3,Acquisition="Standard"},
 {Index=66,Id="KingCorgi",DisplayName="King Corgi",Rank=4,Ability="RoyalValue",Signature="Increases the team's sale value.",Tags={"Explorers"},VisualAsset="KingCorgi",LayerAffinity=4,Acquisition="Standard"},
 {Index=67,Id="Dogzilla",DisplayName="Dogzilla",Rank=4,Ability="MassiveAoE",Signature="A huge area excavation uncovers many pockets.",Tags={"Explorers"},VisualAsset="Dogzilla",LayerAffinity=4,Acquisition="Standard"},
 {Index=68,Id="SharkdogPrime",DisplayName="Sharkdog Prime",Rank=4,Ability="DeepWet",Signature="Reaches deep wet and Void pockets.",Tags={"Explorers"},VisualAsset="SharkdogPrime",LayerAffinity=4,Acquisition="Standard"},
 {Index=69,Id="MechaBark",DisplayName="Mecha Bark-01",Rank=4,Ability="ChargeDig",Signature="Charges before a massive excavation.",Tags={"Cyber"},VisualAsset="MechaBark",LayerAffinity=4,Acquisition="Standard"},
 {Index=70,Id="CaptainCorgi",DisplayName="Captain Corgi",Rank=4,Ability="MoraleAura",Signature="Team morale improves excavation speed.",Tags={"Explorers"},VisualAsset="CaptainCorgi",LayerAffinity=4,Acquisition="Standard"},
 {Index=71,Id="Barkula",DisplayName="Barkula",Rank=4,Ability="VoidNight",Signature="Night and Void discoveries sell for more.",Tags={"Undead"},VisualAsset="Barkula_Roblox",LayerAffinity=4,Acquisition="Standard"},
 {Index=72,Id="Pharaohound",DisplayName="Pharaohound",Rank=4,Ability="AncientLuck",Signature="Improves Ancient artifact discovery luck.",Tags={"Explorers"},VisualAsset="Pharaohound_Roblox",LayerAffinity=4,Acquisition="Standard"},
 {Index=73,Id="Poseidog",DisplayName="Poseidog",Rank=4,Ability="WaterTreasure",Signature="Specializes in Water and Treasure discoveries.",Tags={"Explorers"},VisualAsset="Poseidog_Roblox",LayerAffinity=4,Acquisition="Standard"},
 {Index=74,Id="ThunderHusky",DisplayName="Thunder Husky",Rank=4,Ability="ChainDig",Signature="Chains an excavation into adjacent pockets.",Tags={"Explorers"},VisualAsset="ThunderHusky",LayerAffinity=4,Acquisition="Standard"},
 {Index=75,Id="InfernoBull",DisplayName="Inferno Bull",Rank=4,Ability="MeltLayer",Signature="Melts hard layers for additional rewards.",Tags={"Explorers"},VisualAsset="InfernoBull",LayerAffinity=4,Acquisition="Standard"},
 {Index=76,Id="Sushiba",DisplayName="Sushiba",Rank=4,Ability="RareFood",Signature="Rare Food artifacts sell for more.",Tags={"Food"},VisualAsset="Sushiba",LayerAffinity=4,Acquisition="Standard"},
 {Index=77,Id="Ramendog",DisplayName="RamenDog",Rank=4,Ability="TeamComfort",Signature="Improves team comfort and excavation XP.",Tags={"Food"},VisualAsset="Ramendog",LayerAffinity=4,Acquisition="Standard"},
 {Index=78,Id="DragonShiba",DisplayName="Dragon Shiba",Rank=4,Ability="DragonDepth",Signature="Deeper pockets and improved Treasure luck.",Tags={"Explorers"},VisualAsset="DragonShiba_Roblox",LayerAffinity=4,Acquisition="Standard"},
 {Index=79,Id="Tankweiler",DisplayName="Tankweiler",Rank=4,Ability="ExtremePenetration",Signature="Exceptional penetration of hard ground.",Tags={"Explorers"},VisualAsset="Tankweiler_Roblox",LayerAffinity=4,Acquisition="Standard"},
 {Index=80,Id="DJBarkbeat",DisplayName="DJ Barkbeat",Rank=4,Ability="PlotTempo",Signature="Periodically accelerates the whole plot.",Tags={"Explorers"},VisualAsset="DJBarkbeat_Roblox",LayerAffinity=4,Acquisition="Standard"},
 {Index=81,Id="Cerberdog",DisplayName="Cerberdog",Rank=5,Ability="ThreeHeads",Signature="Three heads improve Coins, XP and rare finds.",Tags={"Explorers"},VisualAsset="Cerberdog",LayerAffinity=5,Acquisition="Standard"},
 {Index=82,Id="GalaxyHusky",DisplayName="Galaxy Husky",Rank=5,Ability="Wormhole",Signature="Can retrieve loot from the next layer.",Tags={"Cosmic"},VisualAsset="GalaxyHusky",LayerAffinity=5,Acquisition="Standard"},
 {Index=83,Id="BlackHolePug",DisplayName="Black Hole Pug",Rank=5,Ability="OrbitalDelivery",Signature="Collects orbital loot for a bulk delivery.",Tags={"Cosmic"},VisualAsset="BlackHolePug_Roblox",LayerAffinity=5,Acquisition="Standard"},
 {Index=84,Id="TimeDog",DisplayName="Time Dog",Rank=5,Ability="TimeRepeat",Signature="Can repeat an excavation or reduce cooldown.",Tags={"Explorers"},VisualAsset="TimeDog",LayerAffinity=5,Acquisition="Standard"},
 {Index=85,Id="GodOfBark",DisplayName="God of Bark",Rank=5,Ability="UniversalAura",Signature="A powerful bounded universal team aura.",Tags={"Explorers"},VisualAsset="GodOfBark_Roblox",LayerAffinity=5,Acquisition="Standard"},
 {Index=86,Id="Moonmoon",DisplayName="Moonmoon",Rank=5,Ability="SatelliteRoll",Signature="A satellite makes an additional discovery roll.",Tags={"Cosmic"},VisualAsset="Moonmoon",LayerAffinity=5,Acquisition="Standard"},
 {Index=87,Id="SunDog",DisplayName="Sun Dog",Rank=5,Ability="SolarLoot",Signature="Focuses on Burn and energy loot.",Tags={"Cosmic"},VisualAsset="SunDog",LayerAffinity=5,Acquisition="Standard"},
 {Index=88,Id="VoidHound",DisplayName="Void Hound",Rank=5,Ability="VoidSpecialist",Signature="Specializes in Void discoveries.",Tags={"Cosmic"},VisualAsset="VoidHound_Roblox",LayerAffinity=5,Acquisition="Standard"},
 {Index=89,Id="GoldenBoi",DisplayName="The Golden Boi",Rank=5,Ability="GoldenWeight",Signature="Finds have much greater value and weight.",Tags={"Explorers"},VisualAsset="GoldenBoi",LayerAffinity=5,Acquisition="Standard"},
 {Index=90,Id="DogeEmperor",DisplayName="Doge Emperor",Rank=5,Ability="ImperialEconomy",Signature="Improves team income and efficiency.",Tags={"Explorers"},VisualAsset="DogeEmperor_Roblox",LayerAffinity=5,Acquisition="Standard"},
 {Index=91,Id="LongDog",DisplayName="Long Dog",Rank=6,Ability="LongExcavation",Signature="Discovered while digging; reaches deeper pockets.",Tags={"Explorers"},VisualAsset="LongDog_Roblox",LayerAffinity=5,Acquisition="Excavation"},
 {Index=92,Id="Cubedog",DisplayName="CubeDog",Rank=6,Ability="CubeImpact",Signature="Flips over and makes a powerful impact dig.",Tags={"Explorers"},VisualAsset="Cubedog",LayerAffinity=5,Acquisition="Standard"},
 {Index=93,Id="Dogdogdogdog",DisplayName="DOGDOGDOGDOG",Rank=6,Ability="MiniPack",Signature="Miniature dogs make many weaker rolls.",Tags={"Explorers"},VisualAsset="Dogdogdogdog",LayerAffinity=5,Acquisition="Standard"},
 {Index=94,Id="WrongDog",DisplayName="The Wrong Dog",Rank=6,Ability="WrongEvent",Signature="Unstable events offer high-risk rewards.",Tags={"Undead"},VisualAsset="WrongDog_Roblox",LayerAffinity=5,Acquisition="Standard"},
 {Index=95,Id="404Dog",DisplayName="404 DOG NOT FOUND",Rank=6,Ability="DepthCollision",Signature="Can retrieve loot from inaccessible depth.",Tags={"Cyber"},VisualAsset="404Dog",LayerAffinity=5,Acquisition="Standard"},
 {Index=96,Id="NuclearPug",DisplayName="Nuclear Pug",Rank=6,Ability="RadioactiveFind",Signature="Can irradiate loot, but sometimes spoils it.",Tags={"Explorers"},VisualAsset="NuclearPug",LayerAffinity=5,Acquisition="Standard"},
 {Index=97,Id="Spiderdog",DisplayName="Spiderdog",Rank=6,Ability="EightLegDig",Signature="Eight legs perform multiple excavations.",Tags={"Explorers"},VisualAsset="Spiderdog",LayerAffinity=5,Acquisition="Standard"},
 {Index=98,Id="DivineDog",DisplayName="Biblically Accurate Dog",Rank=6,Ability="IndependentLuck",Signature="Makes several independent luck rolls.",Tags={"Explorers"},VisualAsset="DivineDog",LayerAffinity=5,Acquisition="Standard"},
 {Index=99,Id="UnfinishedDog",DisplayName="The Unfinished Dog",Rank=6,Ability="MissingOrTriple",Signature="An unfinished result may disappear or duplicate x3.",Tags={"Explorers"},VisualAsset="UnfinishedDog",LayerAffinity=5,Acquisition="Standard"},
 {Index=100,Id="TheDog",DisplayName="THE DOG",Rank=6,Ability="EndgameArrival",Signature="A very rare server arrival with an endgame team ability.",Tags={"Explorers"},VisualAsset="TheDog",LayerAffinity=5,Acquisition="ServerArrival"},
 {Index=101,Id="Aurion",DisplayName="Aurion",Rank=6,Ability="PrismEcho",Signature="Every tenth completed dig makes an extra independent discovery roll.",Tags={"Cosmic"},VisualAsset="Aurion",LayerAffinity=1,Acquisition="RouletteOnly",MuseumExcluded=true},
}
local Definitions = {}
for _,d in ipairs(rows) do
 d.Rarity=C.Rarities[d.Rank];d.PowerBudget=C.Power[d.Rank]
 d.MinLayer=C.DogMinLayer[d.Rank];if d.Id=='LongDog'then d.MinLayer=4 end
 d.BasePrice=C.Prices[d.Rank];d.Price=d.BasePrice
 d.SpawnWeight=C.Weights[d.Rank] -- rarity-group weight; Engine divides by eligible members
 d.AbilityValues={Strength=.12*d.PowerBudget};d.Set=d.Tags[1] or 'Explorers'
 d.SupplyType='Permanent';d.Available=true;d.Reserved=false
 d.AnimationAsset=d.Id;d.AudioProfile=d.Id;d.MutationRules={Enabled=true}
 d.EventId='';d.FirstEditionLimit=d.Rank>=4 and 5000 or 0
 d.LimitedSupply=0;d.ReleaseEnd=0;d.OG=false
 d.CanSpawnOnLine=d.Acquisition=='Standard' and d.Rank<6
 d.CanDropFromLuckyBlock=d.Acquisition=='Standard'
 d.CanDropFromRoulette=d.Acquisition=='Standard' and d.Rank<6
 if d.Id=='Aurion'then
  d.MinLayer=1;d.CanDropFromRoulette=true;d.FirstEditionLimit=0
  d.Jackpot=true;d.AcquisitionDescription='DOG-O-MATIC exclusive · '..require(script.Parent.Parent.RewardMachineText).Aurion()
 end
 Definitions[d.Id]=d
end
local synergies={
 Vampug={BLACKOUT={Night=.12},CURSED_FOG={Protection=.08}},UfoDog={UFO_INVASION={AlienArtifact=.10}},Astrodoggo={UFO_INVASION={TreasureMap=.08}},
 Glitchiba={NULL_HOUR={Recovery=.06,Duplicate=.03}},BooHound={CURSED_FOG={Protection=.07}},DemonDoggo={CURSED_FOG={EventWeightLuck=.05}},
 Necrohound={CURSED_FOG={TreasureMap=.07}},FrostHusky={BLIZZARD={DigSpeed=.08}},Firepup={METEOR={Luck=.06}}}
for id,def in pairs(Definitions)do def.EventSynergies=synergies[id]or{}end
return Definitions
