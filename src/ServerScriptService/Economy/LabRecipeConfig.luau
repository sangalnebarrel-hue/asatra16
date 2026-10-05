-- Server-only. All enabled outputs use existing available production assets.
return {
 {RecipeId='GOLDEN_BREAKFAST',Name='Golden Breakfast',Procedure='Fusion',DiscoveryState='Known',Secret=false,Repeatable=true,
  RequiredDogIds={'Breadog','CoffeeDog'},RequiredDNA={FOOD=4,CommonDNA=4},RequiredItems={golden_bone=1},MinimumMastery=0,MinimumAscension=0,
  StabilityModifiers=76,OutputDogId='Breadog',OutputMutation='Golden',Costs={Cash=5000,Bones=15},Hint='Two familiar breakfast companions, a golden keepsake.'},
 {RecipeId='DIGITAL_ROAST',Name='Digital Roast',Procedure='Creation',DiscoveryState='Discovered',Secret=false,Repeatable=true,
  RequiredDogIds={'CoffeeDog','DJDoggo'},RequiredDNA={FOOD=4,DIGITAL=4,RareDNA=2},RequiredItems={glitched_coin=1},MinimumMastery=5,MinimumAscension=0,
  StabilityModifiers=58,OutputDogId='DJDoggo',OutputMutation='Glitched',Costs={Cash=50000,Bones=35},Hint='A sleepless drink, a rhythm, and a coin that cannot stay still.'},
 {RecipeId='ECLIPSE_BLOODLINE',Name='Eclipse Bloodline',Procedure='Creation',DiscoveryState='Secret',Secret=true,Repeatable=false,
  RequiredGeneticTags={'UNDEAD','ANGELIC'},RequiredDNA={NIGHT=6,ANGELIC=6,StrangeDNA=3},RequiredItems={void_fragment=1},MinimumMastery=10,MinimumAscension=0,
  StabilityModifiers=32,MaximumStability=65,OutputDogId='Vampug',OutputMutation='Void',Costs={Cash=500000,Bones=100},Hint='Night meets a guardian. Three strange traces cross a broken horizon. Too much order seals it shut.'},
}
