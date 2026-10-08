-- Shared progression and cosmetic definitions. Currency decisions run on the server.
local C={}
C.Stages={
 {Name='FIRST PAW',Slots=1,Feature='One kennel. Your first digging business.'},
 {Name='DIGGING DUO',Slots=2,Feature='Second kennel and timber fencing.'},
 {Name='BUSY BACKYARD',Slots=3,Feature='Third kennel and garden planters.'},
 {Name='DOG CREW',Slots=4,Feature='Fourth kennel and a lit entrance.'},
 {Name='FULL HOUSE',Slots=5,Feature='All five digging kennels are working.'},
 {Name='STONE ESTATE',Slots=5,Feature='Stone paths, masonry and raised borders.'},
 {Name='GILDED GROUNDS',Slots=5,Feature='Decorated gateway and roof ornaments.'},
 {Name='GRAND RESERVE',Slots=5,Feature='Lantern avenue and a garden pavilion.'},
 {Name='MEGA ESTATE',Slots=5,Feature='Monument, grand gate and premium grounds.'},
}
C.Order={'Classic','BoneRain','GoldenHour','DogRush','TreasureFever','CrystalStorm','Earthquake','TimeWarp','CursedFog','Blackout','UFOInvasion','RainbowRift','NullHour','TheVoid'}
-- Body / roof / trim / glow palettes intentionally match the supplied art direction.
C.Skins={
 Classic={Name='PARADISE VILLA',Rarity='Starter',Cash=0,Color={255,178,152},Roof={204,102,68},Trim={250,248,242},Glow={255,214,135},Motif='Paw',Description='Pastel beach villa, terracotta roofs, white trims and palms.'},
 BoneRain={Name='BONE RAIN',Rarity='Common',Cash=1200,Event='BONE_RAIN',Goal=30,Color={94,59,34},Roof={79,41,25},Trim={246,228,183},Glow={255,203,109},Motif='Bone',Description='Ivory bones, timber rails and a giant bone gateway.'},
 GoldenHour={Name='GOLDEN HOUR',Rarity='Common',Cash=2400,Event='GOLDEN_HOUR',Goal=60,Color={219,202,151},Roof={225,160,28},Trim={255,215,88},Glow={255,195,62},Motif='Sun',Description='Golden roofs, sun crests and warm stone.'},
 DogRush={Name='DOG RUSH',Rarity='Common',Cash=3600,Event='DOG_RUSH',Goal=90,Color={20,89,111},Roof={241,104,28},Trim={235,238,227},Glow={255,153,36},Motif='Race',Description='Racing orange, teal garages and checkered flags.'},
 TreasureFever={Name='TREASURE FEVER',Rarity='Common',Cash=5000,Event='TREASURE_FEVER',Goal=120,Color={100,69,38},Roof={70,83,44},Trim={207,162,74},Glow={255,187,75},Motif='Treasure',Description='Expedition shelters, olive roofs and treasure chests.'},
 CrystalStorm={Name='CRYSTAL STORM',Rarity='Uncommon',Cash=14000,Event='CRYSTAL_STORM',Goal=250,Color={37,43,77},Roof={74,62,132},Trim={90,151,244},Glow={144,80,255},Motif='Crystal',Description='Violet crystal clusters and blue luminous inlays.'},
 Earthquake={Name='EARTHQUAKE',Rarity='Uncommon',Cash=18000,Event='EARTHQUAKE',Goal=300,Color={96,81,68},Roof={75,74,71},Trim={161,113,69},Glow={255,157,67},Motif='Rock',Description='Boulder walls, fault lines and rugged stone roofs.'},
 TimeWarp={Name='TIME WARP',Rarity='Uncommon',Cash=24000,Event='TIME_WARP',Goal=400,Color={31,79,78},Roof={22,91,95},Trim={218,172,77},Glow={255,229,157},Motif='Clock',Description='Clockwork gates, golden clock faces and teal pavilions.'},
 CursedFog={Name='CURSED FOG',Rarity='Rare',Cash=55000,Event='CURSED_FOG',Goal=750,Color={37,44,35},Roof={64,37,83},Trim={86,123,45},Glow={144,234,82},Motif='Curse',Description='Twisted trees, purple rooftops and cursed green lanterns.'},
 Blackout={Name='BLACKOUT',Rarity='Rare',Cash=65000,Event='BLACKOUT',Goal=900,Color={29,35,44},Roof={38,47,60},Trim={211,151,36},Glow={255,205,80},Motif='Moon',Description='Midnight metal, amber strips and a crescent gate.'},
 UFOInvasion={Name='UFO INVASION',Rarity='Rare',Cash=80000,Event='UFO_INVASION',Goal=1100,Color={77,112,110},Roof={153,195,199},Trim={69,110,100},Glow={149,255,75},Motif='UFO',Description='Silver laboratories, alien antennas and a hovering saucer.'},
 RainbowRift={Name='RAINBOW RIFT',Rarity='Rare',Cash=100000,Event='RAINBOW_RIFT',Goal=1400,Color={227,217,239},Roof={157,205,246},Trim={247,175,224},Glow={179,135,255},Motif='Rainbow',Description='Pastel architecture, rainbow arches and prismatic gems.'},
 NullHour={Name='NULL HOUR',Rarity='Secret',Event='NULL_HOUR',Goal=2000,Stage=8,Color={14,14,18},Roof={24,24,28},Trim={219,222,229},Glow={255,47,64},Motif='Glitch',Description='Monochrome blocks, red fractures and a fragmented gate.'},
 TheVoid={Name='THE VOID OPENS',Rarity='Secret',Event='THE_VOID_OPENS',Goal=3000,Stage=9,Prestige=1,Color={28,20,43},Roof={39,25,62},Trim={112,51,171},Glow={188,64,255},Motif='Void',Description='Obsidian ruins, suspended rocks and a violet singularity.'},
}
-- The starter villa gets its own pastel per yard (Yard_01 .. Yard_08).
C.VillaPastels={{255,178,152},{172,230,206},{255,210,164},{208,190,240},{166,216,242},{255,236,166},{250,192,208},{150,222,214}}
function C.Level(p)return math.clamp(1+((p.Upgrades or {}).Plot or 0),1,#C.Stages)end
function C.Slots(p)return C.Stages[C.Level(p)].Slots end
function C.Cost(level)return math.floor(300*2.2^(level-1))end
function C.Color(rgb)return Color3.fromRGB(rgb[1],rgb[2],rgb[3])end
function C.Earned(p,id)
 local d=C.Skins[id];if not d then return false end
 if id=='Classic'then return true end
 if id=='TheVoid'then return C.Level(p)>=9 and (p.Prestige or 0)>=1 and (p.UnlockedLayers or {})['5']==true and ((p.Lifetime or {}).GlobalDigContribution or 0)>=d.Goal end
 return p.WorldEventsSeen and p.WorldEventsSeen[d.Event]~=nil
  and ((p.Lifetime or {}).GlobalDigContribution or 0)>=d.Goal
  and C.Level(p)>=(d.Stage or 1)and (p.Prestige or 0)>=(d.Prestige or 0)
end
function C.Requirement(p,id)
 local d=C.Skins[id];if id=='Classic'then return 'Always owned'end
 local seen=p.WorldEventsSeen and p.WorldEventsSeen[d.Event]
 local digs=((p.Lifetime or {}).GlobalDigContribution or 0)
 if id=='TheVoid'then return 'Unlock THE VOID depth | '..math.min(digs,d.Goal)..'/'..d.Goal..' digs | Yard 9 | Prestige 1'end
 local s=(seen and 'Event seen' or 'Witness '..d.Name)..' | '..math.min(digs,d.Goal)..'/'..d.Goal..' digs'
 if d.Stage then s..=' | Yard '..d.Stage end
 if d.Prestige then s..=' | Prestige '..d.Prestige end
 return s
end
return C
