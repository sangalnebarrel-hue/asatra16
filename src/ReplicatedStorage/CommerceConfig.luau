-- The Robux shop. Ids are the experience's own Creator Hub products. Whether an Id is a
-- Developer Product or a Game Pass is resolved at runtime (ReplicatedStorage.ProductKinds);
-- Kind='Product'|'Pass' on a row overrides that lookup. Robux is the Creator Hub price at
-- setup (it only breaks a name tie while resolving kinds); the UI always shows the live price.
-- Keep an old ID and its rewards when retiring an offer: unresolved receipts must still work.
-- Every Id lives on exactly ONE row across this file, ShopDefinitions, LuckyBlockConfig and
-- RewardMachineConfig (C.Check): ProcessReceipt refuses an Id it finds twice.
-- Rewards: Cash (fixed), CashMinutes+CashFloor (coins = max(floor, minutes of the buyer's
-- income), worked out at receipt time), Bones, Supplies={Key=seconds}, Tokens (paid DOG-O-MATIC
-- spins; TokenFallback coins when the buyer cannot use them), ServerLuck={Multiplier,Seconds}.
local RS=game:GetService('ReplicatedStorage')
local Machine=require(RS.RewardMachineConfig)
local C={}
-- Shop order. 'Server Luck' is the SERVER LUCK panel; the rest are offer cards. There is no
-- Lucky Block product, so that category is gone (its rows stay in LuckyBlockConfig).
C.Categories={'Server Luck','Starter Packs','Money','Spins','Supplies'}
C.ShortNames={['Server Luck']='LUCK',['Starter Packs']='PACKS',Money='MONEY',Spins='SPINS',Supplies='BUFFS'}
-- A Robux supply refuses to stack beyond this much stored time (active + reserve).
C.MaxStoredSupplySeconds=12*3600
local SCOUT={CashMinutes=15,CashFloor=3000,Bones=10,Supplies={EnergySnack=1800}}
local EXPLORER={CashMinutes=60,CashFloor=12000,Bones=40,Supplies={EnergySnack=3600,StorageCrate=3600}}
C.Products={
 -- SERVER LUCK: rarer dogs, lucky blocks and variants on the tongue for everyone on this
 -- server (ServerLuck.Activate, 30 min per purchase, time stacks per tier).
 {Key='ServerLuck2',Category='Server Luck',Name='Lucky Server',Icon='Luck',Id=2008376546,Enabled=true,Robux=249,ServerLuck={Multiplier=2,Seconds=1800}},
 {Key='ServerLuck3',Category='Server Luck',Name='Super Lucky Server',Icon='Luck',Id=2009912252,Enabled=true,Robux=699,ServerLuck={Multiplier=3,Seconds=1800}},
 {Key='ServerLuck4',Category='Server Luck',Name='Ultra Lucky Server',Icon='Luck',Id=2008934484,Enabled=true,Robux=1499,ServerLuck={Multiplier=4,Seconds=1800}},
 {Key='ServerLuck5',Category='Server Luck',Name='MAX LUCK',Icon='Luck',Id=2009672253,Enabled=true,Robux=2999,ServerLuck={Multiplier=5,Seconds=1800}},
 -- STARTER PACKS. The Creator Hub has two Scout Kits and two Explorer Kits: the second of
 -- each is a hidden alias with the same contents, so either receipt is honoured.
 {Key='StarterScout',Category='Starter Packs',Name='Scout Kit',Id=2007039912,Enabled=true,Robux=49,Rewards=SCOUT},
 {Key='StarterScoutAlt',Category='Starter Packs',Name='Scout Kit',Icon='StarterScout',Id=2007627868,Enabled=true,Hidden=true,Robux=67,Rewards=SCOUT},
 {Key='StarterExplorer',Category='Starter Packs',Name='Explorer Kit',Id=2006529843,Enabled=true,Robux=189,Rewards=EXPLORER},
 {Key='StarterExplorerAlt',Category='Starter Packs',Name='Explorer Kit',Icon='StarterExplorer',Id=2008454494,Enabled=true,Hidden=true,Robux=199,Rewards=EXPLORER},
 {Key='StarterTurbo',Category='Starter Packs',Name='Turbo Dig Kit',Id=2006517914,Enabled=true,Robux=249,
  Rewards={CashMinutes=30,CashFloor=6000,Supplies={EnergySnack=10800,StorageCrate=10800}}},
 {Key='StarterCollector',Category='Starter Packs',Name='Collector Kit',Id=2009390265,Enabled=true,Robux=249,
  Rewards={CashMinutes=60,CashFloor=12000,Bones=150,Supplies={StorageCrate=7200},Tokens=3,TokenFallback={Minutes=30,Floor=6000}}},
 {Key='StarterCaptain',Category='Starter Packs',Name='Pack Captain Kit',Id=2009018487,Enabled=true,Robux=349,
  Rewards={CashMinutes=120,CashFloor=25000,Bones=150,Supplies={EnergySnack=7200,StorageCrate=7200},ServerLuck={Multiplier=2,Seconds=600}}},
 -- MONEY: coins scale with the buyer's income (value per Robux rises with the pack).
 {Key='MoneyChange',Category='Money',Name='Pocket Change',Id=2008466495,Enabled=true,Robux=19,Rewards={CashMinutes=10,CashFloor=1000}},
 {Key='MoneyPocket',Category='Money',Name='Pocket of Coins',Id=2008538493,Enabled=true,Robux=35,Rewards={CashMinutes=20,CashFloor=2000}},
 {Key='MoneyChest',Category='Money',Name='Chest of Coins',Id=2006469839,Enabled=true,Robux=139,Rewards={CashMinutes=90,CashFloor=9000}},
 {Key='MoneyTreasure',Category='Money',Name='Treasure Chest',Id=2008952474,Enabled=true,Robux=149,Rewards={CashMinutes=100,CashFloor=10000,Bones=25}},
 {Key='MoneyVault',Category='Money',Name='Vault of Coins',Id=2006721809,Enabled=true,Robux=649,Rewards={CashMinutes=480,CashFloor=50000}},
 {Key='MoneyHoard',Category='Money',Name='Mega Treasure Hoard',Id=2008646489,Enabled=true,Robux=999,Rewards={CashMinutes=840,CashFloor=90000,Bones=100}},
 -- SUPPLIES for Robux: 30 minutes each; time above the 1 hour active cap waits in the reserve.
 {Key='SupplyEnergySnack',Category='Supplies',Name='Energy Snack',Id=2008281885,Enabled=true,Robux=39,Supply='EnergySnack',Seconds=1800},
 {Key='SupplyStorageCrate',Category='Supplies',Name='Storage Crate',Id=2006913838,Enabled=true,Robux=39,Supply='StorageCrate',Seconds=1800},
 -- Retired (SERVER LUCK replaced it); kept so a legacy receipt could still resolve.
 {Key='SupplyLuckyTreat',Category='Supplies',Name='Lucky Treat',Icon='Luck',Id=0,Enabled=false,Hidden=true,Supply='LuckyTreat'},
}
-- Reuse the existing ticket balances, quantities, IDs, odds and lucky-block receipts.
C.TicketKeys={'TicketSingle','TicketPack5','TicketPack15'}
-- Paid DOG-O-MATIC spins are on sale only once RewardMachineConfig.FreeOnly is false; the shop
-- also hides them for accounts where paid random items are restricted.
function C.SpinsOnSale()return Machine.FreeOnly~=true end
-- Every offer the shop can show (hidden aliases and retired rows left out), in catalog order.
function C.Offers()
 local rows={}
 for _,p in ipairs(C.Products)do if not p.Hidden and p.Enabled~=false then table.insert(rows,p)end end
 if C.SpinsOnSale()then
  for _,key in ipairs(C.TicketKeys)do
   for _,p in ipairs(Machine.TicketProducts or{})do if p.Key==key then
    local row=table.clone(p);row.Category='Spins';row.Icon=p.Key;row.Route='RewardMachineProduct';table.insert(rows,row)
   end end
  end
 end
 return rows
end
function C.Find(key)for _,p in ipairs(C.Products)do if p.Key==key then return p end end end
function C.ServerLuckRow(multiplier)
 for _,p in ipairs(C.Products)do if p.Category=='Server Luck'and p.ServerLuck and p.ServerLuck.Multiplier==multiplier then return p end end
end
-- Every Robux row of every catalog ProcessReceipt reads: {Catalog=, Row=}.
function C.AllRows()
 local out={}
 for _,row in ipairs(C.Products)do table.insert(out,{Catalog='Commerce',Row=row})end
 for _,row in ipairs(require(RS.DogEconomy.ShopDefinitions))do table.insert(out,{Catalog='Cosmetic',Row=row})end
 for _,row in ipairs(require(RS.LuckyBlockConfig).RobuxProducts)do table.insert(out,{Catalog='Block',Row=row})end
 for _,row in ipairs(Machine.TicketProducts or{})do table.insert(out,{Catalog='Tickets',Row=row})end
 return out
end
-- Configuration problems (empty when healthy): an Id on two rows is never granted.
function C.Check()
 local problems,keys,ids={},{},{}
 for _,entry in ipairs(C.AllRows())do
  local row=entry.Row;local key=entry.Catalog..':'..tostring(row.Key)
  if keys[key]then table.insert(problems,'Duplicate key '..key)end;keys[key]=true
  if type(row.Id)~='number'or row.Id<0 or row.Id%1~=0 then table.insert(problems,'Invalid Id on '..key)
  elseif row.Id>0 then
   if ids[row.Id]then table.insert(problems,string.format('Id %d is on two rows: %s and %s',row.Id,ids[row.Id],key))end
   ids[row.Id]=ids[row.Id]or key
  end
  if row.Kind~=nil and row.Kind~='Product'and row.Kind~='Pass'then table.insert(problems,'Kind must be Product or Pass on '..key)end
  if entry.Catalog=='Commerce'then
   if not table.find(C.Categories,row.Category)then table.insert(problems,'Unknown category on '..key)end
   if row.Supply==nil and row.Rewards==nil and row.ServerLuck==nil then table.insert(problems,'Nothing to grant on '..key)end
   local luck=row.ServerLuck or(row.Rewards and row.Rewards.ServerLuck)
   if luck and(type(luck.Multiplier)~='number'or luck.Multiplier<2 or luck.Multiplier>5 or luck.Multiplier%1~=0 or type(luck.Seconds)~='number'or luck.Seconds<=0)then
    table.insert(problems,'Invalid ServerLuck on '..key)
   end
  end
 end
 return problems
end
return C
