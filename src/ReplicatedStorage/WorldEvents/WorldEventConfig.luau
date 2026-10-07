return {NormalInterval=600,WarningDuration=60,EventDuration=240,TransitionDuration=15,IntroDuration=5,
 Epoch=1704067200,Seed=104729,ScheduleBlock=128,
 Diversity={RareAfter=4,Step=.20,Cap=1.5},
 ModifierCaps={DigSpeed=1,Recovery=.5,Luck=1.5,SellValue=.5,WeightLuck=.15,EventWeightLuck=.15,Mutation=4,SecretLuck=.08},
 Interactions={Cooldown=10,PerEvent=10,Distance=17,ObjectLifetime=50,MaxActive=16,SpawnSeconds=18,Cash=40,Bones=2},
 -- What each pickup gives. Coins scale with the collector's own progress: Income seconds of
 -- their dig income (p.OfflineEarnings.BaseRate, coins/s), never less than Floor coins per
 -- minute for their layer (a player with no dog still gets something worth picking up).
 -- Block/Blocks: a free stored Lucky Block (never paid-random). Shared: everyone may claim
 -- it once. Groups: where it appears (Site = the event stage plaza, Street = between the
 -- yards, Tongue = beside the tongue).
 Pickups={Floor={100,300,600,1500,4000},
  BonePile={Income=90,Bones=4,Item=true,Action='COLLECT',Title='Bone Pile',Label='COINS + BONES'},
  GiantBone={Income=150,Bones=12,Block='Rare',Shared=true,Lifetime=45,Reach=28,Scale=3,Central=true,Groups={'Street'},Action='CLAIM',Title='Giant Bone',Label='FREE RARE LUCKY BLOCK · FOR EVERYONE'},
  TreasureSpot={Income=40,Blocks={{'Common',65},{'Rare',35}},SpecialBlock='Epic',SpecialLifetime=45,Action='DIG',Title='Treasure',Label='FREE LUCKY BLOCK',SpecialLabel='EPIC LUCKY BLOCK'},
  ChargedCrystal={Income=40,Supply='EnergySnack',SupplySeconds=300,SpecialLifetime=45,Groups={'Street','Tongue'},Action='CHARGE',Title='Charged Crystal',Label='+5 MIN ENERGY SNACK'},
  CursedCache={Income=60,Deeper=1,SpecialLifetime=45,Action='OPEN',Title='Cursed Cache',Label='FIND FROM A DEEPER LAYER'},
  AlienDigZone={Income=60,ItemDepth=5,Lifetime=30,SpecialLifetime=40,Groups={'Site'},Action='DIG',Title='Alien Dig Zone',Label='THE VOID-DEPTH FIND'},
  AlienCrate={Income=30,Lifetime=40,Groups={'Street','Tongue'},Action='GRAB',Title='Alien Crate',Label='LUCKY BLOCK · FIRST TO GRAB'}},
 FX={High={Particles=64,Debris=52,Dogs=14},Medium={Particles=28,Debris=24,Dogs=8},Low={Particles=4,Debris=8,Dogs=3}},
 Debug={EnabledInStudio=true},Audio={MusicVolume=.55,AmbientVolume=.18,SFXVolume=.35,Crossfade=4,MaxSFX=5}}
