local rows={
 {Id='BONE_RAIN',DisplayName='Bone Rain',Rarity='Common',Weight=15,Subtitle='THE SKY HAS A BONE TO PICK.',ColorTheme=Color3.fromRGB(225,215,180),GameplayModifiers={BoneBonus=.25,Luck=.05},Clock=15,Brightness=1.8,Tint=Color3.fromRGB(205,211,206),FogEnd=1500,ParticleProfile='Bones',WorldProps='GiantBone',SpecialObjects='BonePile',SignatureSeconds=65,SignatureDuration=22,Depth=1,DepthLuck=.07},
 {Id='GOLDEN_HOUR',DisplayName='Golden Hour',Rarity='Common',Weight=15,Subtitle='EVERY GOOD BOY HAS A GOLDEN MOMENT.',ColorTheme=Color3.fromRGB(255,188,78),GameplayModifiers={SellValue=.25,GoldLoot=.05},Clock=17.8,Brightness=2.5,Tint=Color3.fromRGB(255,216,168),FogEnd=2100,ParticleProfile='Gold',WorldProps='GoldenBeam',SpecialObjects=nil,SignatureSeconds=80,SignatureDuration=60,Mutations={Golden=1.2,GOLDEN=1.2}},
 {Id='DOG_RUSH',DisplayName='Dog Rush',Rarity='Common',Weight=14,Subtitle='GOOD BOYS. GREAT HURRY.',ColorTheme=Color3.fromRGB(238,166,108),GameplayModifiers={DigSpeed=.15,Recovery=.05},Clock=13.5,Brightness=2.5,Tint=Color3.fromRGB(255,241,220),FogEnd=2200,ParticleProfile='Paws',WorldProps='DogCrowd',SignatureSeconds=60,SignatureDuration=18},
 {Id='TREASURE_FEVER',DisplayName='Treasure Fever',Rarity='Common',Weight=14,Subtitle='SOMETHING GOOD IS JUST UNDER YOUR PAWS.',ColorTheme=Color3.fromRGB(250,209,96),GameplayModifiers={TreasureMap=.08,Artifact=.05},Clock=16,Brightness=2.1,Tint=Color3.fromRGB(255,237,192),FogEnd=1800,ParticleProfile='Treasure',WorldProps='TreasureBeams',SpecialObjects='TreasureSpot',SignatureSeconds=70,SignatureDuration=20},
 {Id='CRYSTAL_STORM',DisplayName='Crystal Storm',Rarity='Uncommon',Weight=9,Subtitle='THE CAVERNS ANSWER THE SKY.',ColorTheme=Color3.fromRGB(132,190,255),GameplayModifiers={Luck=.08,DigitalLuck=.05},Clock=20,Brightness=1.4,Tint=Color3.fromRGB(157,175,255),FogEnd=1250,ParticleProfile='Crystals',WorldProps='CrystalStrike',SpecialObjects='ChargedCrystal',SignatureSeconds=55,SignatureDuration=22,Depth=2,DepthLuck=.12},
 {Id='EARTHQUAKE',DisplayName='Earthquake',Rarity='Uncommon',Weight=8,Subtitle='THE WORLD IS DIGGING BACK.',ColorTheme=Color3.fromRGB(243,160,101),GameplayModifiers={EventWeightLuck=.12,LongDogLuck=9},Clock=15,Brightness=1.7,Tint=Color3.fromRGB(224,202,174),FogEnd=1400,ParticleProfile='Debris',WorldProps='Fissures',SignatureSeconds=68,SignatureDuration=16},
 {Id='TIME_WARP',DisplayName='Time Warp',Rarity='Uncommon',Weight=8,Subtitle='A GOOD SECOND DESERVES ANOTHER CHANCE.',ColorTheme=Color3.fromRGB(118,224,250),GameplayModifiers={DigSpeed=.10,Recovery=.13},Clock=19,Brightness=1.8,Tint=Color3.fromRGB(181,232,255),FogEnd=1700,ParticleProfile='Time',WorldProps='Clocks',SignatureSeconds=75,SignatureDuration=10},
 {Id='CURSED_FOG',DisplayName='Cursed Fog',Rarity='Rare',Weight=4,Subtitle='THE FOG HAS AWAKENED.',ColorTheme=Color3.fromRGB(176,91,187),GameplayModifiers={Luck=.07,Protection=.05},Clock=0.4,Brightness=.85,Tint=Color3.fromRGB(188,155,200),FogEnd=650,ParticleProfile='Fog',WorldProps='Creature',SpecialObjects='CursedCache',SignatureSeconds=85,SignatureDuration=12,Depth=4,DepthLuck=.10,Mutations={Corrupted=1.25,CURSED=1.25}},
 {Id='BLACKOUT',DisplayName='Blackout',Rarity='Rare',Weight=3.5,Subtitle='GOOD BOYS CAN FIND THEIR WAY IN THE DARK.',ColorTheme=Color3.fromRGB(127,163,223),GameplayModifiers={Night=.15,Protection=.04},Clock=1.3,Brightness=.5,Tint=Color3.fromRGB(150,176,218),FogEnd=1100,ParticleProfile='Sparks',WorldProps='PowerFailure',SignatureSeconds=60,SignatureDuration=14,Depth=4,DepthLuck=.05},
 {Id='UFO_INVASION',DisplayName='UFO Invasion',Rarity='Rare',Weight=3.5,Subtitle='THEY CAME FOR THE GOOD BOYS.',ColorTheme=Color3.fromRGB(131,255,169),GameplayModifiers={AlienArtifact=.08,DigitalLuck=.04},Clock=21,Brightness=1.15,Tint=Color3.fromRGB(175,219,200),FogEnd=1800,ParticleProfile='Alien',WorldProps='UFOFleet',SpecialObjects='AlienDigZone',SignatureSeconds=65,SignatureDuration=15,Depth=5,DepthLuck=.06},
 {Id='RAINBOW_RIFT',DisplayName='Rainbow Rift',Rarity='Rare',Weight=3.5,Subtitle='SAME WORLD. DIFFERENT COLORS.',ColorTheme=Color3.fromRGB(240,137,243),GameplayModifiers={Luck=.06},Clock=18.5,Brightness=2,Tint=Color3.fromRGB(235,208,255),FogEnd=1800,ParticleProfile='Rainbow',WorldProps='Rift',SignatureSeconds=72,SignatureDuration=30,Mutations={Shiny=1.15,Glitched=1.15,RAINBOW=1.15,GLITCHED=1.15}},
 {Id='NULL_HOUR',DisplayName='NULL HOUR',Rarity='Secret',Weight=1.5,Subtitle='[ WORLD STATE ERROR ]',ColorTheme=Color3.fromRGB(182,142,199),GameplayModifiers={SecretLuck=.05,DigitalLuck=.03},Clock=0,Brightness=.65,Tint=Color3.fromRGB(181,168,189),FogEnd=1050,Saturation=-.8,ParticleProfile='Errors',WorldProps='NullCube',SignatureSeconds=90,SignatureDuration=8,Mutations={Glitched=1.18,Void=1.08,GLITCHED=1.18}},
 {Id='THE_VOID_OPENS',DisplayName='The Void Opens',Rarity='Secret',Weight=.1,Enabled=false,Subtitle='SOMETHING REMEMBERS US.',ColorTheme=Color3.fromRGB(111,58,171),GameplayModifiers={SecretLuck=.05},Clock=0,Brightness=.5,Tint=Color3.fromRGB(157,129,187),FogEnd=900,ParticleProfile='Errors',WorldProps='Rift',SignatureSeconds=60,SignatureDuration=20}}
-- What each event DOES (server: Economy/WorldEventEffects + WorldEventService; UI: banner,
-- warning notice, BuffHUD chip via State.EffectsText). One source for both sides.
--  Text       short summary shown to players
--  Line       the tongue (Economy/LineModifiers): RankBoost/BlockRankBoost {[rank]=x},
--             SpawnRate, BlockChance, SpeedScale, VariantShare {Variant=share of new dogs}
--  Walk       players' walk speed multiplier (MovementModifiers 'WorldEvent')
--  Pulse      timed effect every Every s (first at First s): Lightning/Tremor make every
--             online player's kennel dogs dig now; Abduct beams a tongue dog (rank<=MaxRank)
--  Perk       once per event per player ('Token': the free DOG-O-MATIC token is ready)
--  HatchSpeed placed Lucky Blocks hatch this many times faster
--  PickupEvery seconds between pickups (Config.Interactions.SpawnSeconds otherwise)
--  Sparkle    variants whose tongue dogs sparkle on clients during the event
--  Signature  the event's big moment (at SignatureSeconds): Name/Text for the banner;
--             Seconds+Force (every new tongue dog gets that variant) or Freeze (tongue
--             stops); Queue={Spec,Count,Expire} forced spawns (LineModifiers.QueueSpawn);
--             Pulse=true fires the event's pulse at once; Spawn={{Kind,Special,Count}} pickups
local EPIC_UP={[3]=2,[4]=2,[5]=2,[6]=2}
local effects={
 BONE_RAIN={Text='BONE PILES EVERYWHERE · ~1 MIN OF COINS + BONES EACH',PickupEvery=8,
  Signature={Name='GIANT BONE',Text='A GIANT BONE HIT MAIN STREET · EVERYONE WHO REACHES IT GETS A FREE RARE LUCKY BLOCK',Spawn={{Kind='GiantBone',Special=true}}}},
 GOLDEN_HOUR={Text='25% GOLDEN DOGS ON THE TONGUE · LOOT SELLS +25%',Line={VariantShare={Golden=.25}},Sparkle={'Golden'},
  Signature={Name='GOLDEN MINUTE',Text='FOR 60 SECONDS EVERY NEW TONGUE DOG IS GOLDEN',Seconds=60,Force='Golden'}},
 DOG_RUSH={Text='x2 TONGUE SPAWNS · FASTER TONGUE · +30% WALK SPEED',Line={SpawnRate=2,SpeedScale=1.25},Walk=1.3,
  Signature={Name='STAMPEDE',Text='THE NEXT 6 TONGUE DOGS ARE EPIC OR BETTER',Queue={Spec={MinRank=3,MaxRank=5},Count=6,Expire=true}}},
 TREASURE_FEVER={Text='x2.5 LUCKY BLOCKS ON THE TONGUE · TREASURE = FREE BLOCKS',Line={BlockChance=.6,BlockRankBoost=EPIC_UP},PickupEvery=14,
  Signature={Name='THE VAULT BREAKS',Text='3 VAULT TREASURES WITH EPIC LUCKY BLOCKS ARE ON THE MAP',Spawn={{Kind='TreasureSpot',Special=true,Count=3}}}},
 CRYSTAL_STORM={Text='EPIC+ TONGUE LUCK x2 · LIGHTNING MAKES KENNELS DIG NOW',Line={RankBoost=EPIC_UP},Pulse={Kind='Lightning',Every=20,First=8},PickupEvery=20,
  Signature={Name='SUPERCHARGE',Text='A MEGA STRIKE: EVERY KENNEL DIGS NOW · A CHARGED CRYSTAL FELL',Pulse=true,Spawn={{Kind='ChargedCrystal',Special=true}}}},
 EARTHQUAKE={Text='LONG DOG CHANCE x10 · TREMORS MAKE KENNELS DIG NOW',Pulse={Kind='Tremor',Every=30,First=12},
  Signature={Name='CORE BREACH',Text='A GIANT TREMOR: EVERY KENNEL DIGS NOW',Pulse=true}},
 TIME_WARP={Text='LUCKY BLOCKS HATCH 4x FASTER · FREE DOG-O-MATIC TOKEN',HatchSpeed=4,Perk='Token',
  Signature={Name='TIME COLLAPSE',Text='THE TONGUE IS FROZEN FOR 10 SECONDS · BUY ANYTHING ON IT',Seconds=10,Freeze=true}},
 CURSED_FOG={Text='25% CORRUPTED DOGS · MYTHIC LUCK x2 · DEEPER CACHE FINDS',Line={RankBoost={[5]=2},VariantShare={Corrupted=.25}},Sparkle={'Corrupted'},
  Signature={Name='THE GUARDIAN AWAKENS',Text='2 MORE CURSED CACHES ROSE FROM THE FOG',Spawn={{Kind='CursedCache',Special=true,Count=2}}}},
 -- Half speed with twice the spawn rate: the same dogs per minute, each on the tongue twice as long.
 BLACKOUT={Text='LEGENDARY & MYTHIC LUCK x3 · SLOW TONGUE · NIGHT LOOT +15%',Line={RankBoost={[4]=3,[5]=3},SpeedScale=.5,SpawnRate=2},
  Signature={Name='TOTAL ECLIPSE',Text='THE NEXT 2 TONGUE DOGS ARE LEGENDARY OR BETTER',Queue={Spec={MinRank=4,MaxRank=5},Count=2,Expire=true}}},
 UFO_INVASION={Text='UFOS BEAM DOGS OFF THE TONGUE · GRAB THEIR ALIEN CRATES',Pulse={Kind='Abduct',Every=30,First=10,MaxRank=4},
  Signature={Name='MOTHERSHIP ARRIVAL',Text='AN ALIEN DIG ZONE LANDED AT THE PLAZA · ANOTHER DOG IS BEING BEAMED UP',Pulse=true,Spawn={{Kind='AlienDigZone',Special=true}}}},
 RAINBOW_RIFT={Text='30% SHINY / GLITCHED DOGS · EPIC+ TONGUE LUCK x2',Line={RankBoost=EPIC_UP,VariantShare={Shiny=.2,Glitched=.1}},Sparkle={'Shiny','Glitched'},
  Signature={Name='CHROMATIC OVERLOAD',Text='FOR 30 SECONDS EVERY NEW TONGUE DOG IS GLITCHED',Seconds=30,Force='Glitched'}},
 -- THE DOG is excluded from the guaranteed Secret (and luck never moves its odds anyway).
 NULL_HOUR={Text='SECRET LUCK x5 ON THE TONGUE · A SECRET WILL WALK OUT',Line={RankBoost={[6]=5},VariantShare={Glitched=.08,Void=.03}},Sparkle={'Glitched','Void'},
  Signature={Name='REALITY DELETED',Text='A SECRET DOG IS WALKING OUT OF THE MOUTH',Queue={Spec={Rank=6,Exclude={TheDog=true}},Count=1}}},
 THE_VOID_OPENS={Text='SECRET LUCK x3 ON THE TONGUE',Line={RankBoost={[6]=3}}},
}
local D={List=rows,ById={}}
for _,row in ipairs(rows)do
 if row.Enabled==nil then row.Enabled=true end
 row.Effects=effects[row.Id]
 row.Description=row.Subtitle;row.Duration=240;row.WarningDuration=60;row.Icon=row.ParticleProfile
 row.LightingProfile={ClockTime=row.Clock,Brightness=row.Brightness,FogEnd=row.FogEnd,FogColor=row.Tint}
 row.AtmosphereProfile={Density=row.Id=='CURSED_FOG'and .38 or .26,Color=row.Tint}
 row.AudioProfile=row.Id;row.IntroProfile={Duration=5};row.OutroProfile={Duration=15};row.SpecialSpawns=row.SpecialObjects
 D.ById[row.Id]=row
end
return D
