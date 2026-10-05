-- Configure new Developer Products here. Id=0 / Enabled=false never prompts payment.
-- SuggestedRobux is a planning value only; UI prices always come from Roblox.
-- Keep an old ID and its rewards when retiring an offer: unresolved receipts must work.
local Machine=require(game.ReplicatedStorage.RewardMachineConfig)
local C={Categories=Machine.FreeOnly and {'Starter Packs','Money','Lucky Block'}or {'Starter Packs','Money','Tickets','Lucky Block'}}
C.Products={
 {Key='StarterScout',Category='Starter Packs',Name='Scout Kit',Icon='Yard',Id=0,Enabled=false,SuggestedRobux=29,Rewards={Cash=500,Bones=5}},
 {Key='StarterExplorer',Category='Starter Packs',Name='Explorer Kit',Icon='Dogs',Id=0,Enabled=false,SuggestedRobux=79,Rewards={Cash=2000,Bones=15}},
 {Key='StarterCaptain',Category='Starter Packs',Name='Pack Captain Kit',Icon='Shop',Id=0,Enabled=false,SuggestedRobux=149,Rewards={Cash=5000,Bones=40}},
 {Key='MoneyPocket',Category='Money',Name='Pocket of Coins',Icon='Coins',Id=0,Enabled=false,SuggestedRobux=19,Rewards={Cash=500}},
 {Key='MoneyChest',Category='Money',Name='Chest of Coins',Icon='Coins',Id=0,Enabled=false,SuggestedRobux=69,Rewards={Cash=2500}},
 {Key='MoneyVault',Category='Money',Name='Vault of Coins',Icon='Coins',Id=0,Enabled=false,SuggestedRobux=179,Rewards={Cash=10000}},
 {Key='SupplyLuckyTreat',Category='Supplies',Name='Lucky Treat',Icon='Luck',Id=0,Enabled=false,SuggestedRobux=9,Supply='LuckyTreat'},
 {Key='SupplyEnergySnack',Category='Supplies',Name='Energy Snack',Icon='Dig',Id=0,Enabled=false,SuggestedRobux=9,Supply='EnergySnack'},
 {Key='SupplyStorageCrate',Category='Supplies',Name='Storage Crate',Icon='Storage',Id=0,Enabled=false,SuggestedRobux=7,Supply='StorageCrate'},
}
-- Reuse the existing ticket balances, quantities, IDs, odds and lucky-block receipts.
C.TicketKeys={'TicketSingle','TicketPack5','TicketPack15'}
C.BlockKey='RareBlock'
C.SuggestedLegacyRobux={TicketSingle=19,TicketPack5=79,TicketPack15=199,RareBlock=49}
function C.Offers()
 local rows={}
 for _,p in ipairs(C.Products)do if p.Category~='Supplies'then table.insert(rows,p)end end
 for _,key in ipairs(Machine.FreeOnly and {}or C.TicketKeys)do
  for _,p in ipairs(require(game.ReplicatedStorage.RewardMachineConfig).TicketProducts)do if p.Key==key then
   local row=table.clone(p);row.Category='Tickets';row.Icon='Ticket';row.Route='RewardMachineProduct';table.insert(rows,row)
  end end
 end
 for _,p in ipairs(require(game.ReplicatedStorage.LuckyBlockConfig).RobuxProducts)do if p.Key==C.BlockKey then
  local row=table.clone(p);row.Category='Lucky Block';row.Name=p.Name or(p.Tier..' Lucky Block');row.Icon='Events';row.Route='PaidProduct';table.insert(rows,row)
 end end
 assert(#rows==(Machine.FreeOnly and 7 or 10),'Unexpected main shop offer count')
 return rows
end
function C.Find(key)for _,p in ipairs(C.Products)do if p.Key==key then return p end end end
return C
