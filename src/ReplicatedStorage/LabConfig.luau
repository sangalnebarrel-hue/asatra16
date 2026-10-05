-- Public, balanceable genetics settings. Secret recipe ingredients stay on the server.
local C={Version=2,QuoteSeconds=120,Cooldown=7,Duration=5.5,MaxHistory=40,MaxMaterial=1000000,Distance=7.5}
C.Procedures={
 {Id='Mutation',Name='MUTATION',Tier=1,Level=1,Description='Reroll the variant. Your dog always survives.'},
 {Id='Targeting',Name='GENE TARGETING',Tier=2,Level=5,Description='A discovery catalyst changes the odds.'},
 {Id='Extraction',Name='DNA EXTRACTION',Tier=3,Level=8,Description='Permanently recycle one dog into DNA.'},
 {Id='Fusion',Name='FUSION / ASCEND',Tier=4,Level=12,Description='Combine bloodlines or ascend with duplicates.'},
 {Id='Creation',Name='EXPERIMENTAL CREATION',Tier=5,Level=18,Description='Discover classified genetic combinations.'},
}
C.Costs={Mutation={Cash=500,RankCash=100,RankBones=5},Targeting={Cash=900,RankCash=160,RankBones=7,DNA={CommonDNA=2}},Extraction={Cash=100,RankCash=50},Ascend={Cash=1000,Bones=10}}
C.Stability={Mutation=65,Targeting=48,MasteryPer=0.12,AscensionPer=3,Maximum=98,Minimum=10,StrangeRate=0.22,FailedRefund=.5}
C.TargetWeights={Base=1100,PerStability=60,StabilizerBonus=1800}
C.Affinities={
 golden_bone={Mutation='Golden',Power=1},golden_scarab={Mutation='Golden',Power=1.15},
 glitched_coin={Mutation='Glitched',Power=1},void_fragment={Mutation='Void',Power=.85},
 cursed_idol={Mutation='Corrupted',Power=1},cursed_bone={Mutation='Corrupted',Power=.7},
 shiny_marble={Mutation='Shiny',Power=.65},red_crystal={Mutation='Shiny',Power=1},
}
C.Stabilizers={quartz_crystal=18,living_crystal=28,crystal_of_time=34}
C.DNA={CommonDNA='Common DNA',RareDNA='Rare DNA',MutationShards='Mutation Shards',StrangeDNA='Strange DNA',CoreFragment='Lab Core Fragment',NORMAL='Normal sample',FOOD='Food sample',NIGHT='Night sample',UNDEAD='Undead sample',DIGITAL='Digital sample',GLITCH='Glitch sample',ANGELIC='Angelic sample',ARCANE='Arcane sample',FIRE='Fire sample',ICE='Ice sample',ALIEN='Alien sample',SPACE='Space sample',MECHANICAL='Mechanical sample',ROYAL='Royal sample',DEMONIC='Demonic sample',TREASURE='Treasure sample'}
C.Genetics={Breadog={'FOOD','NORMAL'},CoffeeDog={'FOOD','NORMAL'},DJDoggo={'DIGITAL','NORMAL'},Vampug={'NIGHT','UNDEAD'},AngelDoggo={'ANGELIC','ARCANE'},DivineDog={'ANGELIC','ARCANE'},Glitchiba={'DIGITAL','GLITCH'},Firepup={'FIRE'},FrostHusky={'ICE'},LavaBull={'FIRE'},UfoDog={'ALIEN','SPACE'},Astrodoggo={'SPACE'},BooHound={'UNDEAD'},Zombark={'UNDEAD'},DemonDoggo={'DEMONIC'},KingCorgi={'ROYAL'},CaptainBark={'TREASURE'},MechaShiba={'MECHANICAL'},CyberCorgi={'DIGITAL','MECHANICAL'}}
-- Common / Rare / Epic / Legendary / Mythic / Secret, matching the dog catalog.
C.Extraction={CommonByRank={2,4,6,8,10,14},RareByRank={0,1,1,2,3,5},SamplesByRank={1,2,2,3,4,6},MasteryStep=25,AscensionBonus=1,VariantShards={Normal=0,Shiny=1,Golden=2,Corrupted=3,Glitched=4,Void=5},CoreMinimumRank=5}
C.HighValueVariants={Golden=true,Corrupted=true,Glitched=true,Void=true}
C.Colors={Normal=Color3.fromRGB(151,231,155),Shiny=Color3.fromRGB(168,220,255),Golden=Color3.fromRGB(255,200,63),Corrupted=Color3.fromRGB(209,64,83),Glitched=Color3.fromRGB(211,92,248),Void=Color3.fromRGB(106,49,184)}
return C
