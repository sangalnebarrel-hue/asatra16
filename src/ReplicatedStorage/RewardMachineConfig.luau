-- A free DOG TOKEN refills five hours after use; extra tokens can be bought (Lucky Spin
-- packs) by accounts that Roblox allows to buy paid random items (PolicyService checks every
-- purchase and every paid activation; free tokens are always spent first).
-- All outcomes occupy integer slots in the same 10,000-slot server pool shown
-- on the odds board. Aurion always owns exactly one slot: 0.01%, or 1 in 10,000.
-- Other eligible prizes share the remaining slots in their existing proportions.
-- PriceRobux is intentionally unset; the UI reads each live Roblox product price.
-- Retain configured IDs/counts for retired products so pending receipts can resolve.
return {
 FreeOnly=false,
Cost=0,TicketCost=1,TicketCapacity=1,StartingTickets=1,TicketRefillSeconds=18000,Cooldown=7,OddsDenominator=10000,
 TicketProducts={
  {Key='TicketSingle',Name='Lucky Spin',Count=1,Id=2006535822,Enabled=true,PriceRobux=nil},
  {Key='TicketPack5',Name='Lucky Bundle',Count=5,Id=2008394530,Enabled=true,PriceRobux=nil},
  {Key='TicketPack15',Name='Mega Spin Bundle',Count=15,Id=2006259883,Enabled=true,PriceRobux=nil},
 },Rewards={
 -- Nine rows, in drum order: each owns a physical sector (Sector_1..9) of the world drum.
 -- Coins={MinCash,IncomeMinutes}: the bag holds that many minutes of the winner's team income
 -- (BoostPricing.Coins), so a spin stays worth it at every stage of the game.
 {Kind='Dog',Id='Breadog',Weight=22,Name='Breadog'},
 {Kind='Dog',Id='CoffeeDog',Weight=6,Name='Coffee Dog'},
 {Kind='Dog',Id='DJDoggo',Weight=.5,Name='DJ DOGGO'},
 {Kind='Item',Id='dog_tag',Weight=12,Name='Dog Tag'},
 {Kind='Item',Id='tiny_treasure_chest',Weight=1.5,Name='Tiny Treasure Chest'},
 {Kind='Cash',Amount=2400,Coins={MinCash=2400,IncomeMinutes=15},Weight=28,Name='Coin Bag'},
 {Kind='Bones',Amount=40,Weight=20,Name='40 Bones'},
 {Kind='Boost',Id='EnergySnack',Duration=900,Weight=10,Name='Energy Snack · 15 min'},
 {Kind='Dog',Id='Aurion',Weight=0,FixedUnits=1,Required=true,Jackpot=true,Name='Aurion'}
}}
