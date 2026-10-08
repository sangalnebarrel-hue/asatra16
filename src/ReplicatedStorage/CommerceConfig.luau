-- Configure Developer Products here. Id=0 / Enabled=false never prompts payment.
-- UI prices always come from Roblox (GetProductInfoAsync); Robux below is a planning note.
-- Keep an old ID and its rewards when retiring an offer: unresolved receipts must work.
-- Rewards:
--   Coins={MinCash,IncomeMinutes}  coins that follow the economy: that many minutes of the
--                                  buyer's team income, never below MinCash (× layer scale)
--   Cash=n / Bones=n               fixed amounts
--   Supplies={Key=seconds}         supply time (anything over the 1-hour cap waits in reserve)
--   Luck={Tier=n,Seconds=s}        personal luck tier time (LUCK tab)
--   ServerLuck={Multiplier=x,Seconds=s}  boosts the tongue for everyone on this server
-- Once=true: one purchase per player (starter packs). Alias rows (older duplicates of an
-- offer) are never shown but still fulfil their receipts.
local Machine=require(game.ReplicatedStorage.RewardMachineConfig)
local C={}
C.Categories={'Starter Packs','Server Luck','DOG-O-MATIC Spins','Boost Kits','Money'}
C.Products={
 -- Starter packs: one each per player.
 {Key='StarterScout',Category='Starter Packs',Name='Scout Kit',Icon='StarterScout',Id=2007039912,Enabled=true,Robux=49,Once=true,
  Blurb='Your first boost',Rewards={Coins={MinCash=6000,IncomeMinutes=20},Bones=30,Supplies={EnergySnack=1200},Luck={Tier=1,Seconds=1200}}},
 {Key='StarterExplorer',Category='Starter Packs',Name='Explorer Kit',Icon='StarterExplorer',Id=2006529843,Enabled=true,Robux=189,Once=true,
  Blurb='Dig deeper, faster',Rewards={Coins={MinCash=30000,IncomeMinutes=60},Bones=120,Supplies={EnergySnack=1800,GoldenBiscuit=1800},Luck={Tier=2,Seconds=1800}}},
 {Key='StarterCaptain',Category='Starter Packs',Name='Pack Captain Kit',Icon='StarterCaptain',Id=2009018487,Enabled=true,Robux=349,Once=true,
  Blurb='Lead the whole pack',Rewards={Coins={MinCash=80000,IncomeMinutes=120},Bones=250,Supplies={EnergySnack=3600,GoldenBiscuit=3600,StorageCrate=3600},Luck={Tier=3,Seconds=1800}}},
 -- Older duplicates of the starter packs (same rewards, same one-per-player slot).
 {Key='StarterScoutAlt',Alias='StarterScout',Category='Starter Packs',Name='Scout Kit',Icon='StarterScout',Id=2007627868,Enabled=true,Robux=67,Once=true,
  Rewards={Coins={MinCash=6000,IncomeMinutes=20},Bones=30,Supplies={EnergySnack=1200},Luck={Tier=1,Seconds=1200}}},
 {Key='StarterExplorerAlt',Alias='StarterExplorer',Category='Starter Packs',Name='Explorer Kit',Icon='StarterExplorer',Id=2008454494,Enabled=true,Robux=199,Once=true,
  Rewards={Coins={MinCash=30000,IncomeMinutes=60},Bones=120,Supplies={EnergySnack=1800,GoldenBiscuit=1800},Luck={Tier=2,Seconds=1800}}},
 -- Server luck: the whole server's tongue brings rarer dogs.
 {Key='LuckyServer',Category='Server Luck',Name='Lucky Server',Icon='Luck',Id=2008376546,Enabled=true,Robux=249,
  Blurb='x2 rare dogs for everyone',Rewards={ServerLuck={Multiplier=2,Seconds=900}}},
 {Key='SuperLuckyServer',Category='Server Luck',Name='Super Lucky Server',Icon='Luck',Id=2009912252,Enabled=true,Robux=699,
  Blurb='x3 rare dogs for everyone',Rewards={ServerLuck={Multiplier=3,Seconds=900}}},
 {Key='UltraLuckyServer',Category='Server Luck',Name='Ultra Lucky Server',Icon='Luck',Id=2008934484,Enabled=true,Robux=1499,
  Blurb='x4 rare dogs for everyone',Rewards={ServerLuck={Multiplier=4,Seconds=900}}},
 {Key='MaxLuck',Category='Server Luck',Name='MAX LUCK',Icon='Luck',Id=2009672253,Enabled=true,Robux=2999,Featured=true,
  Blurb='x5 server luck + your own 5x LUCK',Rewards={ServerLuck={Multiplier=5,Seconds=1800},Luck={Tier=5,Seconds=1800}}},
 -- Boost kits (repeatable).
 {Key='TurboDigKit',Category='Boost Kits',Name='Turbo Dig Kit',Icon='EnergySnack',Id=2006517914,Enabled=true,Robux=249,
  Blurb='Two hours of zoomies',Rewards={Coins={MinCash=20000,IncomeMinutes=30},Supplies={EnergySnack=7200,GoldenBiscuit=3600},Luck={Tier=2,Seconds=3600}}},
 {Key='CollectorKit',Category='Boost Kits',Name='Collector Kit',Icon='StorageCrate',Id=2009390265,Enabled=true,Robux=249,
  Blurb='Bigger hauls, better finds',Rewards={Coins={MinCash=40000,IncomeMinutes=60},Bones=150,Supplies={StorageCrate=7200,GoldenBiscuit=3600},Luck={Tier=2,Seconds=1800}}},
 -- Money.
 {Key='MoneyChange',Category='Money',Name='Pocket Change',Icon='MoneyPocket',Id=2008466495,Enabled=true,Robux=19,
  Rewards={Coins={MinCash=2000,IncomeMinutes=10}}},
 {Key='MoneyPocket',Category='Money',Name='Pocket of Coins',Icon='MoneyPocket',Id=2008538493,Enabled=true,Robux=35,
  Rewards={Coins={MinCash=4500,IncomeMinutes=20}}},
 {Key='MoneyChest',Category='Money',Name='Chest of Coins',Icon='MoneyChest',Id=2006469839,Enabled=true,Robux=139,
  Rewards={Coins={MinCash=25000,IncomeMinutes=90}}},
 {Key='TreasureChest',Category='Money',Name='Treasure Chest',Icon='MoneyChest',Id=2008952474,Enabled=true,Robux=149,
  Rewards={Coins={MinCash=25000,IncomeMinutes=90},Bones=200}},
 {Key='MoneyVault',Category='Money',Name='Vault of Coins',Icon='MoneyVault',Id=2006721809,Enabled=true,Robux=649,
  Rewards={Coins={MinCash=150000,IncomeMinutes=480}}},
 {Key='MegaTreasureHoard',Category='Money',Name='Mega Treasure Hoard',Icon='MoneyVault',Id=2008646489,Enabled=true,Robux=999,Featured=true,
  Rewards={Coins={MinCash=300000,IncomeMinutes=900},Bones=1000}},
 -- Supplies (sold on the SUPPLIES page): 30 minutes per purchase.
 {Key='SupplyEnergySnack',Category='Supplies',Name='Energy Snack',Icon='Dig',Id=2008281885,Enabled=true,Robux=39,Supply='EnergySnack',Seconds=1800},
 {Key='SupplyStorageCrate',Category='Supplies',Name='Storage Crate',Icon='Storage',Id=2006913838,Enabled=true,Robux=39,Supply='StorageCrate',Seconds=1800},
 {Key='SupplyGoldenBiscuit',Category='Supplies',Name='Golden Biscuit',Icon='Coins',Id=0,Enabled=false,Supply='GoldenBiscuit',Seconds=1800},
 -- Retired: luck moved to the LUCK tab (kept for any unresolved receipt).
 {Key='SupplyLuckyTreat',Category='Supplies',Name='Lucky Treat',Icon='Luck',Id=0,Enabled=false,Supply='LuckyTreat'},
}
C.TicketKeys={'TicketSingle','TicketPack5','TicketPack15'}
C.BlockKey='RareBlock'
function C.Find(key)for _,p in ipairs(C.Products)do if p.Key==key then return p end end end
-- Rows for the PAW MARKET (aliases, supplies and switched-off offers are not listed).
function C.Offers()
 local rows={}
 for _,category in ipairs(C.Categories)do
  if category=='DOG-O-MATIC Spins'then
   if not Machine.FreeOnly then
    for _,key in ipairs(C.TicketKeys)do
     for _,p in ipairs(Machine.TicketProducts or {})do if p.Key==key and p.Enabled then
      local row=table.clone(p);row.Category=category;row.Icon=key;row.Route='RewardMachineProduct';table.insert(rows,row)
     end end
    end
   end
  else
   for _,p in ipairs(C.Products)do
    if p.Category==category and not p.Alias and p.Enabled and p.Id>0 then table.insert(rows,p)end
   end
  end
 end
 return rows
end
return C
