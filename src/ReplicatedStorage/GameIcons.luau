-- Generated DOGROTS icon registry. Upload the PNGs as Roblox IMAGE assets first.
-- Fill Assets with real numeric IDs or rbxassetid:// URLs from that upload.
-- These are image asset IDs, not Developer Product IDs. An omitted key uses
-- the existing UI artwork/procedural glyph; no placeholder ID is sent to Roblox.
local G={}
G.Keys={
 'LuckyTreat','EnergySnack','StorageCrate',
 'StarterScout','StarterExplorer','StarterCaptain',
 'MoneyPocket','MoneyChest','MoneyVault',
 'TicketSingle','TicketPack5','TicketPack15','RareBlock',
 'Coins','Bones','Dig','Luck','Records','Star','Settings','RewardMachine','Casino',
}
G.Assets={
 Bones=129995934323766,
 RewardMachine=84437688048552,
 Casino=84437688048552,
 Coins=139025872961174,
 Dig=105611091036304,
 EnergySnack=127406708171535,
 Luck=122590036998546,
 LuckyTreat=122307561862274,
 MoneyChest=116475895037957,
 MoneyPocket=131935619872409,
 MoneyVault=88843807854981,
 RareBlock=71153549086548,
 Records=118723087724327,
 Settings=96164701307895,
 Star=112093659795914,
 StarterCaptain=72303024099622,
 StarterExplorer=79770125783485,
 StarterScout=113694878621001,
 StorageCrate=94084817763688,
 TicketPack15=73436913967818,
 TicketPack5=140097198258054,
 TicketSingle=105854491216231,
}
G.Aliases={Ticket='TicketSingle',Supplies='StorageCrate',SupplyLuckyTreat='LuckyTreat',SupplyEnergySnack='EnergySnack',SupplyStorageCrate='StorageCrate',
 -- Newer offers use uploaded artwork; every PAW MARKET offer gets a picture of its own.
 GoldenBiscuit='Coins',SupplyGoldenBiscuit='Coins',MoneyChange='Coins',TreasureChest='Bones',MegaTreasureHoard='Records',
 LuckyServer='Luck',SuperLuckyServer='LuckyTreat',UltraLuckyServer='Star',MaxLuck='Casino',TurboDigKit='Dig',CollectorKit='StorageCrate'}
local fallback={
 LuckyTreat='Luck',EnergySnack='Dig',StorageCrate='Storage',GoldenBiscuit='Coins',
 StarterScout='Yard',StarterExplorer='Dogs',StarterCaptain='Shop',
 MoneyPocket='Coins',MoneyChest='Coins',MoneyVault='Coins',
 TicketSingle='Ticket',TicketPack5='Ticket',TicketPack15='Ticket',RareBlock='Events',
 Settings='Lab',RewardMachine='Dogs',
}
function G.AssetUrl(value)
 if type(value)=='number'then
  if value>0 and value==math.floor(value)and value<math.huge then return 'rbxassetid://'..string.format('%.0f',value)end
 elseif type(value)=='string'then
  local id=value:match('^rbxassetid://(%d+)$')or value:match('^(%d+)$')
  if id and tonumber(id)and tonumber(id)>0 then return 'rbxassetid://'..id end
 end
 return nil
end
function G.Resolve(key)
 local canonical=G.Aliases[key]or key
 return G.AssetUrl(G.Assets[canonical]),canonical
end
function G.FallbackKey(key)
 local canonical=G.Aliases[key]or key
 return fallback[canonical]or canonical
end
function G.Apply(assets)
 for _,key in ipairs(G.Keys)do local asset=G.Resolve(key);if asset then assets[key]=asset end end
 for key in pairs(G.Aliases)do local asset=G.Resolve(key);if asset then assets[key]=asset end end
 return assets
end
local preloadState={}
local PRELOAD_TIMEOUT=14
local RETRY_DELAYS={2,8}
local FAILED_COOLDOWN=60
function G.Preload(assets)
 -- Called after the screen has been built. Asset fetches never block input,
 -- navigation, tutorial startup or the first frame of the HUD.
 local records={};local now=os.clock();local batch={Finished=false}
 for _,value in pairs(assets or{})do
  local asset=G.AssetUrl(value)
  local state=asset and preloadState[asset]
  if asset and(not state or(state.Status=='Failed'and now>=state.RetryAt))then
   if not state or state.Attempts>=3 then state={Attempts=0};preloadState[asset]=state end
   state.Attempts+=1;state.Status='Pending';state.Batch=batch
   table.insert(records,{Asset=asset,State=state})
  end
 end
 if #records==0 then return end
 local statuses={}
 local function finish()
  if batch.Finished then return end
  batch.Finished=true
  local retry={};local retryDelay=0
  for _,record in ipairs(records)do
   local state=record.State;local label=record.Label
   local loaded=statuses[record.Asset]==Enum.AssetFetchStatus.Success or(label and label.IsLoaded)
   if state.Batch==batch then
    state.Batch=nil
    if loaded then state.Status='Success'
    else
     state.Status='Failed';local delay=RETRY_DELAYS[state.Attempts]
     state.RetryAt=os.clock()+(delay or FAILED_COOLDOWN)
     if delay then retry[record.Asset]=record.Asset;retryDelay=math.max(retryDelay,delay)end
    end
   end
   if label then label:Destroy();record.Label=nil end
  end
  if next(retry)then task.delay(retryDelay,function()G.Preload(retry)end)end
 end
 -- A stalled fetch cannot retain temporary instances or a permanent Pending entry.
 task.delay(PRELOAD_TIMEOUT,finish)
 task.defer(function()
  if batch.Finished then return end
  pcall(function()
   local instances={}
   for _,record in ipairs(records)do
    local label=Instance.new('ImageLabel');record.Label=label
    label.Name='DOGROTS_IconPreload';label.Image=record.Asset;label.BackgroundTransparency=1
    table.insert(instances,label)
   end
   game:GetService('ContentProvider'):PreloadAsync(instances,function(content,status)
    if batch.Finished then return end
    local asset=G.AssetUrl(content)or G.AssetUrl(tostring(content):match('[?&]id=(%d+)'))
    if asset then statuses[asset]=status end
   end)
  end)
  -- Per-asset failures do not throw; callback status / IsLoaded decide success.
  finish()
 end)
end
return G
