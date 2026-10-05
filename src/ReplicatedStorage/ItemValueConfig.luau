-- Versioned, shared coefficients. Only the server can grant sale proceeds.
return {
 Version=4,SecretMultiplier=3.6,
 Rarity={{MaxChance=.000001,Name='Secret',Multiplier=3.6},{MaxChance=.0001,Name='Legendary',Multiplier=2.7},{MaxChance=.001,Name='Epic',Multiplier=2},{MaxChance=.01,Name='Rare',Multiplier=1.5},{MaxChance=.05,Name='Uncommon',Multiplier=1.2},{MaxChance=1,Name='Common',Multiplier=1}},
 Depth={1,1.12,1.26,1.42,1.6},
 WeightTier={.62,.83,1,1.55,2.8,5,9,16,28,45},
 WeightExponent=.18,WeightMin=.65,WeightMax=4,
 Mutation={NORMAL=1,SHINY=1.5,GOLDEN=2.5,RAINBOW=8,CURSED=5,CORRUPTED=5,GLITCHED=15,VOID=18,TOASTED=1.35,BURNED=1.45,SPORE=1.4,FROZEN=1.5,INFERNAL=1.7,SOLAR=1.7,RADIOACTIVE=2,SPOILED=.2},
 EventDefault=1.12,Events={NULL_HOUR=1.35,TREASURE_FEVER=1.2},
 FirstFind=1.08,MaxEarnedBonus=.5,Seasonal=1,
 SoftCapIncomeHours=60,SoftCapStart=.8,
}
