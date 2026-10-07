-- DOG TOKENS: one free token refills five hours after use (it holds one), and extra tokens
-- are sold for Robux (Lucky Spin 1, Lucky Bundle 5, Mega Spin Bundle 15; GET SPINS at the
-- machine and the shop's Spins tab).
-- The free token is always spent first; paid tokens never expire and are spent only by
-- accounts whose PolicyService allows paid random items (others keep them).
-- All outcomes occupy integer slots in the same 10,000-slot server pool shown
-- on the odds board. Aurion always owns exactly one slot: 0.01%, or 1 in 10,000,
-- for a free or a paid token alike.
-- Other eligible prizes share the remaining slots in their existing proportions.
-- PriceRobux is intentionally unset; the UI reads each live Roblox product price.
-- Retain configured IDs/counts for retired products so pending receipts can resolve.
return {
 -- Kill switch. true = no token sales and paid balances are kept but never spent;
 -- receipts still credit (a completed purchase is never lost).
 FreeOnly=false,
 -- Cooldown is the per-player gap between activations: the drum's 6.2 s spin rounded up to
 -- whole seconds (profiles keep whole seconds). A gap is never shorter than the spin itself,
 -- so this is already the shortest one and paid tokens use it too: 15 tokens = 15 spins.
Cost=0,TicketCost=1,TicketCapacity=1,StartingTickets=1,TicketRefillSeconds=18000,Cooldown=7,OddsDenominator=10000,
 TicketProducts={
  -- The shop's spins (Creator Hub: Lucky Spin, Lucky Bundle, Mega Spin Bundle).
  {Key='TicketSingle',Name='Lucky Spin',Count=1,Id=2006535822,Enabled=true,PriceRobux=nil},
  {Key='TicketPack5',Name='Lucky Bundle',Count=5,Id=2008394530,Enabled=true,PriceRobux=nil},
  {Key='TicketPack15',Name='Mega Spin Bundle',Count=15,Id=2006259883,Enabled=true,PriceRobux=nil},
 },Rewards={
 {Kind='Dog',Id='Breadog',Weight=22,Name='Breadog'},
 {Kind='Dog',Id='CoffeeDog',Weight=6,Name='Coffee Dog'},
 {Kind='Dog',Id='DJDoggo',Weight=.5,Name='DJ DOGGO'},
 {Kind='Item',Id='dog_tag',Weight=12,Name='Dog Tag'},
 {Kind='Item',Id='tiny_treasure_chest',Weight=1.5,Name='Tiny Treasure Chest'},
 {Kind='Cash',Amount=240,Weight=28,Name='240 Coins'},
 {Kind='Bones',Amount=3,Weight=20,Name='3 Bones'},
 {Kind='Boost',Id='EnergySnack',Duration=300,Weight=10,Name='Energy Snack · 5 min'},
 {Kind='Dog',Id='Aurion',Weight=0,FixedUnits=1,Required=true,Jackpot=true,Name='Aurion'}
}}
