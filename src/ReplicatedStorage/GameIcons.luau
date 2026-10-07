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
 'Coins','Bones','Dig','Luck','Records','Star','Settings','RewardMachine',
}
G.Assets={
 Bones=106456990037989,
 RewardMachine=133663422018034,
 Coins=94201445734975,
 Dig=123412341615352,
 EnergySnack=130638937946645,
 Luck=93007710400246,
 LuckyTreat=131273477039573,
 MoneyChest=136773243761002,
 MoneyPocket=84273918963863,
 MoneyVault=78193750556003,
 RareBlock=92340577008007,
 Records=73380484322139,
 Settings=90499724819433,
 Star=112481099136510,
 StarterCaptain=136428025784144,
 StarterExplorer=133663422018034,
 StarterScout=129437057749005,
 StorageCrate=108751430712724,
 TicketPack15=140516949520545,
 TicketPack5=91403734867700,
 TicketSingle=126768083956997,
}
G.Aliases={Ticket='TicketSingle',Supplies='StorageCrate',SupplyLuckyTreat='LuckyTreat',SupplyEnergySnack='EnergySnack',SupplyStorageCrate='StorageCrate',
 -- Shop offers without their own art reuse the closest existing image.
 ServerLuck='Luck',ServerLuck2='Luck',ServerLuck3='Luck',ServerLuck4='Luck',ServerLuck5='Luck',
 MoneyChange='MoneyPocket',MoneyTreasure='MoneyChest',MoneyHoard='MoneyVault',
 StarterScoutAlt='StarterScout',StarterExplorerAlt='StarterExplorer',StarterTurbo='EnergySnack',StarterCollector='TicketPack5'}
local fallback={
 LuckyTreat='Luck',EnergySnack='Dig',StorageCrate='Storage',
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
