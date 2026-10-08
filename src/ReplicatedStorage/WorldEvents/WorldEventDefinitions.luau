local rows={
 {Id='BONE_RAIN',DisplayName='Bone Rain',Rarity='Common',Weight=15,Subtitle='THE SKY HAS A BONE TO PICK.',ColorTheme=Color3.fromRGB(225,215,180),GameplayModifiers={BoneBonus=.20,Luck=.05},Clock=15,Brightness=1.8,Tint=Color3.fromRGB(205,211,206),FogEnd=1500,ParticleProfile='Bones',WorldProps='GiantBone',SpecialObjects='BonePile',SignatureSeconds=65,SignatureDuration=22,Depth=1,DepthLuck=.07},
 {Id='GOLDEN_HOUR',DisplayName='Golden Hour',Rarity='Common',Weight=15,Subtitle='EVERY GOOD BOY HAS A GOLDEN MOMENT.',ColorTheme=Color3.fromRGB(255,188,78),GameplayModifiers={SellValue=.15,GoldLoot=.05},Clock=17.8,Brightness=2.5,Tint=Color3.fromRGB(255,216,168),FogEnd=2100,ParticleProfile='Gold',WorldProps='GoldenBeam',SpecialObjects=nil,SignatureSeconds=80,SignatureDuration=25,Mutations={Golden=1.2,GOLDEN=1.2}},
 {Id='DOG_RUSH',DisplayName='Dog Rush',Rarity='Common',Weight=14,Subtitle='GOOD BOYS. GREAT HURRY.',ColorTheme=Color3.fromRGB(238,166,108),GameplayModifiers={DigSpeed=.15,Recovery=.05},Clock=13.5,Brightness=2.5,Tint=Color3.fromRGB(255,241,220),FogEnd=2200,ParticleProfile='Paws',WorldProps='DogCrowd',SignatureSeconds=60,SignatureDuration=18},
 {Id='TREASURE_FEVER',DisplayName='Treasure Fever',Rarity='Common',Weight=14,Subtitle='SOMETHING GOOD IS JUST UNDER YOUR PAWS.',ColorTheme=Color3.fromRGB(250,209,96),GameplayModifiers={TreasureMap=.08,Artifact=.05},Clock=16,Brightness=2.1,Tint=Color3.fromRGB(255,237,192),FogEnd=1800,ParticleProfile='Treasure',WorldProps='TreasureBeams',SpecialObjects='TreasureSpot',SignatureSeconds=70,SignatureDuration=20},
 {Id='CRYSTAL_STORM',DisplayName='Crystal Storm',Rarity='Uncommon',Weight=9,Subtitle='THE CAVERNS ANSWER THE SKY.',ColorTheme=Color3.fromRGB(132,190,255),GameplayModifiers={Luck=.08,DigitalLuck=.05},Clock=20,Brightness=1.4,Tint=Color3.fromRGB(157,175,255),FogEnd=1250,ParticleProfile='Crystals',WorldProps='CrystalStrike',SpecialObjects='ChargedCrystal',SignatureSeconds=55,SignatureDuration=22,Depth=2,DepthLuck=.12},
 {Id='EARTHQUAKE',DisplayName='Earthquake',Rarity='Uncommon',Weight=8,Subtitle='THE WORLD IS DIGGING BACK.',ColorTheme=Color3.fromRGB(243,160,101),GameplayModifiers={EventWeightLuck=.12},Clock=15,Brightness=1.7,Tint=Color3.fromRGB(224,202,174),FogEnd=1400,ParticleProfile='Debris',WorldProps='Fissures',SignatureSeconds=68,SignatureDuration=16},
 {Id='TIME_WARP',DisplayName='Time Warp',Rarity='Uncommon',Weight=8,Subtitle='A GOOD SECOND DESERVES ANOTHER CHANCE.',ColorTheme=Color3.fromRGB(118,224,250),GameplayModifiers={DigSpeed=.10,Recovery=.13},Clock=19,Brightness=1.8,Tint=Color3.fromRGB(181,232,255),FogEnd=1700,ParticleProfile='Time',WorldProps='Clocks',SignatureSeconds=75,SignatureDuration=1},
 {Id='CURSED_FOG',DisplayName='Cursed Fog',Rarity='Rare',Weight=4,Subtitle='THE FOG HAS AWAKENED.',ColorTheme=Color3.fromRGB(176,91,187),GameplayModifiers={Luck=.07,Protection=.05},Clock=0.4,Brightness=.85,Tint=Color3.fromRGB(188,155,200),FogEnd=650,ParticleProfile='Fog',WorldProps='Creature',SpecialObjects='CursedCache',SignatureSeconds=85,SignatureDuration=12,Depth=4,DepthLuck=.10,Mutations={Corrupted=1.25,CURSED=1.25}},
 {Id='BLACKOUT',DisplayName='Blackout',Rarity='Rare',Weight=3.5,Subtitle='GOOD BOYS CAN FIND THEIR WAY IN THE DARK.',ColorTheme=Color3.fromRGB(127,163,223),GameplayModifiers={Night=.08,Protection=.04},Clock=1.3,Brightness=.5,Tint=Color3.fromRGB(150,176,218),FogEnd=1100,ParticleProfile='Sparks',WorldProps='PowerFailure',SignatureSeconds=60,SignatureDuration=14,Depth=4,DepthLuck=.05},
 {Id='UFO_INVASION',DisplayName='UFO Invasion',Rarity='Rare',Weight=3.5,Subtitle='THEY CAME FOR THE GOOD BOYS.',ColorTheme=Color3.fromRGB(131,255,169),GameplayModifiers={AlienArtifact=.08,DigitalLuck=.04},Clock=21,Brightness=1.15,Tint=Color3.fromRGB(175,219,200),FogEnd=1800,ParticleProfile='Alien',WorldProps='UFOFleet',SpecialObjects='AlienDigZone',SignatureSeconds=65,SignatureDuration=15,Depth=5,DepthLuck=.06},
 {Id='RAINBOW_RIFT',DisplayName='Rainbow Rift',Rarity='Rare',Weight=3.5,Subtitle='SAME WORLD. DIFFERENT COLORS.',ColorTheme=Color3.fromRGB(240,137,243),GameplayModifiers={Luck=.06},Clock=18.5,Brightness=2,Tint=Color3.fromRGB(235,208,255),FogEnd=1800,ParticleProfile='Rainbow',WorldProps='Rift',SignatureSeconds=72,SignatureDuration=16,Mutations={Shiny=1.15,Glitched=1.15,RAINBOW=1.15,GLITCHED=1.15}},
 {Id='NULL_HOUR',DisplayName='NULL HOUR',Rarity='Secret',Weight=1.5,Subtitle='[ WORLD STATE ERROR ]',ColorTheme=Color3.fromRGB(182,142,199),GameplayModifiers={SecretLuck=.05,DigitalLuck=.03},Clock=0,Brightness=.65,Tint=Color3.fromRGB(181,168,189),FogEnd=1050,Saturation=-.8,ParticleProfile='Errors',WorldProps='NullCube',SignatureSeconds=90,SignatureDuration=8,Mutations={Glitched=1.18,Void=1.08,GLITCHED=1.18}},
 {Id='THE_VOID_OPENS',DisplayName='The Void Opens',Rarity='Secret',Weight=.1,Enabled=false,Subtitle='SOMETHING REMEMBERS US.',ColorTheme=Color3.fromRGB(111,58,171),GameplayModifiers={SecretLuck=.05},Clock=0,Brightness=.5,Tint=Color3.fromRGB(157,129,187),FogEnd=900,ParticleProfile='Errors',WorldProps='Rift',SignatureSeconds=60,SignatureDuration=20}}
--[[ Perks: what an event does to the world while it is ACTIVE (WorldEventGameplay applies them
 on the server; WorldEventGameplayFX draws them on every client; the EVENTS page lists them).
  Gravity      × workspace gravity (UFO: low gravity)      Walk / Jump  × walk speed / jump power
  LineLuck     × Legendary/Mythic/Secret odds on the tongue SecretLine   × Secret odds once more
  LineSpeed    × tongue speed (more dogs per minute)        BlockChance  × Lucky Block share of the tongue
  BonesPerMinute  bones every online player receives while it lasts
  Reward       paid to everyone who stayed ≥ 60 s of the active window when it ends:
               {MinCash, IncomeMinutes (BoostPricing.Coins), Bones, Luck={Tier,Seconds}}
  Effects      client set pieces: Flashlight, Tractor, Quakes, Trail, Glitch, Zoomies ]]
local perks={
 BONE_RAIN={Jump=1.25,LineLuck=1.25,BonesPerMinute=4,Effects={Trail=true},
  Reward={MinCash=1000,IncomeMinutes=8,Bones=15}},
 GOLDEN_HOUR={Walk=1.1,LineLuck=1.3,Effects={Trail=true},
  Reward={MinCash=1500,IncomeMinutes=12,Bones=10}},
 DOG_RUSH={Walk=1.35,LineSpeed=1.5,LineLuck=1.2,Effects={Zoomies=true,Trail=true},
  Reward={MinCash=1000,IncomeMinutes=8,Bones=10}},
 TREASURE_FEVER={BlockChance=2,LineLuck=1.2,Effects={Trail=true},
  Reward={MinCash=1500,IncomeMinutes=10,Bones=15}},
 CRYSTAL_STORM={Jump=1.15,LineLuck=1.5,Effects={Trail=true},
  Reward={MinCash=2000,IncomeMinutes=12,Bones=20,Luck={Tier=1,Seconds=300}}},
 EARTHQUAKE={LineLuck=1.4,Effects={Quakes=true},
  Reward={MinCash=2000,IncomeMinutes=12,Bones=20,Luck={Tier=1,Seconds=300}}},
 TIME_WARP={Gravity=.75,Walk=1.2,LineSpeed=.6,LineLuck=1.4,Effects={Trail=true},
  Reward={MinCash=2000,IncomeMinutes=12,Bones=20,Luck={Tier=1,Seconds=300}}},
 CURSED_FOG={Walk=.92,LineLuck=1.6,SecretLine=1.5,Effects={Trail=true},
  Reward={MinCash=3000,IncomeMinutes=15,Bones=25,Luck={Tier=2,Seconds=300}}},
 BLACKOUT={LineLuck=1.6,Effects={Flashlight=true},
  Reward={MinCash=3000,IncomeMinutes=15,Bones=25,Luck={Tier=2,Seconds=300}}},
 UFO_INVASION={Gravity=.35,LineLuck=1.6,Effects={Tractor=true},
  Reward={MinCash=3000,IncomeMinutes=15,Bones=25,Luck={Tier=2,Seconds=300}}},
 RAINBOW_RIFT={Jump=1.4,Walk=1.15,LineLuck=1.5,Effects={Trail=true},
  Reward={MinCash=3000,IncomeMinutes=15,Bones=25,Luck={Tier=2,Seconds=300}}},
 NULL_HOUR={Gravity=.6,GravityFlicker=true,LineLuck=2,SecretLine=3,Effects={Glitch=true},
  Reward={MinCash=5000,IncomeMinutes=20,Bones=40,Luck={Tier=3,Seconds=600}}},
 THE_VOID_OPENS={Gravity=.5,LineLuck=2,SecretLine=3,Effects={Glitch=true},
  Reward={MinCash=5000,IncomeMinutes=20,Bones=40,Luck={Tier=3,Seconds=600}}},
}
local D={List=rows,ById={},Perks=perks}
for _,row in ipairs(rows)do
 row.Perks=perks[row.Id]or {}
 if row.Enabled==nil then row.Enabled=true end
 row.Description=row.Subtitle;row.Duration=240;row.WarningDuration=60;row.Icon=row.ParticleProfile
 row.LightingProfile={ClockTime=row.Clock,Brightness=row.Brightness,FogEnd=row.FogEnd,FogColor=row.Tint}
 row.AtmosphereProfile={Density=row.Id=='CURSED_FOG'and .38 or .26,Color=row.Tint}
 row.AudioProfile=row.Id;row.IntroProfile={Duration=5};row.OutroProfile={Duration=15};row.SpecialSpawns=row.SpecialObjects
 D.ById[row.Id]=row
end
-- Readable perk lines (EVENTS page, the warning card), strongest first.
local modifierText={BoneBonus='bones from digging',Luck='rare finds',SellValue='coin value',GoldLoot='gold loot',DigSpeed='digging speed',
 Recovery='dog recovery',TreasureMap='treasure finds',Artifact='artifact finds',DigitalLuck='digital finds',EventWeightLuck='heavier finds',
 Protection='protection',Night='night bonus',AlienArtifact='alien finds',SecretLuck='secret finds'}
function D.PerkLines(def)
 local lines={};local p=def.Perks or {}
 local function pct(x)return string.format('%+d%%',math.floor((x-1)*100+.5))end
 if p.Gravity then table.insert(lines,(p.Gravity<.5 and 'LOW GRAVITY'or 'LIGHTER GRAVITY')..(p.GravityFlicker and ' · IT GLITCHES'or ''))end
 if p.LineLuck then table.insert(lines,string.format('x%.3g RARE DOGS ON THE TONGUE',p.LineLuck))end
 if p.SecretLine then table.insert(lines,string.format('x%.3g SECRET DOGS',(p.LineLuck or 1)*p.SecretLine))end
 if p.LineSpeed then table.insert(lines,p.LineSpeed>1 and string.format('TONGUE x%.3g FASTER',p.LineSpeed)or 'SLOWER TONGUE · MORE TIME TO BUY')end
 if p.BlockChance then table.insert(lines,string.format('x%.3g LUCKY BLOCKS',p.BlockChance))end
 if p.Walk and p.Walk~=1 then table.insert(lines,'WALK SPEED '..pct(p.Walk))end
 if p.Jump and p.Jump~=1 then table.insert(lines,'JUMP '..pct(p.Jump))end
 if p.BonesPerMinute then table.insert(lines,'+'..p.BonesPerMinute..' BONES EVERY MINUTE')end
 local keys={};for key in pairs(def.GameplayModifiers or {})do if modifierText[key]then table.insert(keys,key)end end
 table.sort(keys,function(a,b)return def.GameplayModifiers[a]>def.GameplayModifiers[b]end)
 for _,key in ipairs(keys)do table.insert(lines,string.format('+%d%% %s',math.floor(def.GameplayModifiers[key]*100+.5),modifierText[key]:upper()))end
 if p.Reward then table.insert(lines,p.Reward.Luck and string.format('STAY TILL THE END: COINS + %dx LUCK',p.Reward.Luck.Tier)or 'STAY TILL THE END: COINS + BONES')end
 return lines
end
return D
