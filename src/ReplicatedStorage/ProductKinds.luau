-- Is a configured Robux Id a Developer Product or a Game Pass? The Creator Hub column said
-- "Pass ID", so the server asks Roblox about each Id both ways and keeps the kind whose
-- returned Name matches the configured row (the configured Robux price breaks a tie); when
-- only one lookup answers it is used if its name or price matches (a warning names anything
-- doubtful in the server Output). A row's Kind ('Product'|'Pass') always wins.
-- Published on ReplicatedStorage.DOGROTS_ProductKinds (server writes, everyone reads):
--  Kind_<id>   'Product' | 'Pass' | 'Unavailable'   (missing = still resolving)
--  Price_<id>  live Robux price, ForSale_<id> false when Roblox says it is off sale
--  Resolved (the first pass finished), Revision
-- Kind/Status/Price/InfoType/Prompt work on the server and the client.
local RS=game:GetService('ReplicatedStorage')
local Marketplace=game:GetService('MarketplaceService')
local Run=game:GetService('RunService')
local K={FolderName='DOGROTS_ProductKinds',Refresh=900,Retry=45,Retries=6,Started=false}
local function folder()return RS:FindFirstChild(K.FolderName)end
local function attribute(name,id)local f=folder();return f and f:GetAttribute(name..'_'..string.format('%.0f',id))end
-- 'Product' | 'Pass' | 'Unavailable' | 'Pending'
function K.Status(id)
 if type(id)~='number'or id<=0 then return 'Unavailable'end
 local v=attribute('Kind',id)
 if v=='Product'or v=='Pass'or v=='Unavailable'then return v end
 return 'Pending'
end
function K.Kind(id)local s=K.Status(id);if s=='Product'or s=='Pass'then return s end;return nil end
function K.Price(id)local v=type(id)=='number'and id>0 and attribute('Price',id);return type(v)=='number'and v or nil end
function K.ForSale(id)return type(id)=='number'and id>0 and attribute('ForSale',id)~=false end
function K.InfoType(id)return K.Kind(id)=='Pass'and Enum.InfoType.GamePass or Enum.InfoType.Product end
-- Shows the right Roblox purchase prompt. Returns ok, error.
function K.Prompt(player,id)
 local kind=K.Kind(id)
 if kind=='Pass'then return pcall(function()Marketplace:PromptGamePassPurchase(player,id)end)end
 if kind=='Product'then return pcall(function()Marketplace:PromptProductPurchase(player,id)end)end
 return false,'This offer is unavailable right now'
end
function K.Override(row)if row.Kind=='Product'or row.Kind=='Pass'then return row.Kind end end
-- The Creator Hub list (name, Robux) the products were made with: what Roblox should answer
-- for each Id, whatever a catalog row is called in the shop (row Name/Robux otherwise).
K.CreatorHub={
 [2009672253]={'MAX LUCK',2999},[2008934484]={'Ultra Lucky Server',1499},[2009912252]={'Super Lucky Server',699},
 [2008376546]={'Lucky Server',249},[2006913838]={'Storage Crate',39},[2008281885]={'Energy Snack',39},
 [2006259883]={'Mega Spin Bundle',499},[2008394530]={'Lucky Bundle',199},[2006535822]={'Lucky Spin',49},
 [2006517914]={'Turbo Dig Kit',249},[2006529843]={'Explorer Kit',189},[2009390265]={'Collector Kit',249},
 [2007039912]={'Scout Kit',49},[2008646489]={'Mega Treasure Hoard',999},[2008952474]={'Treasure Chest',149},
 [2008466495]={'Pocket Change',19},[2006721809]={'Vault of Coins',649},[2006469839]={'Chest of Coins',139},
 [2008538493]={'Pocket of Coins',35},[2009018487]={'Pack Captain Kit',349},[2008454494]={'Explorer Kit',199},
 [2007627868]={'Scout Kit',67},
}
local function norm(s)return type(s)=='string'and(s:lower():gsub('[^%w]',''))or''end
-- Pure decision (also run by the Lune harness). product/pass: GetProductInfoAsync results or
-- nil when that lookup failed. Returns kind or nil, and a reason worth a warning (or nil).
function K.Decide(row,product,pass)
 local override=K.Override(row);if override then return override,nil end
 local hub=K.CreatorHub[row.Id];local name,robux=hub and hub[1]or row.Name,hub and hub[2]or row.Robux
 local function named(info)return info~=nil and norm(info.Name)==norm(name)end
 local function priced(info)return info~=nil and robux~=nil and info.PriceInRobux==robux end
 -- One answer: trust it when its name (or, renamed, its price) matches; an unrelated item
 -- that merely shares the number in the other namespace is never sold.
 local single=product and not pass and{'Product',product}or pass and not product and{'Pass',pass}or nil
 if single then
  local info=single[2]
  if named(info)then return single[1],nil end
  if priced(info)then return single[1],'only the '..single[1]..' lookup answered; its name "'..tostring(info.Name)..'" differs, its price matches'end
  return nil,'only the '..single[1]..' lookup answered and it is "'..tostring(info.Name)..'" for '..tostring(info.PriceInRobux)..' Robux (set Kind on the row if this is right)'
 end
 if not product and not pass then return nil,'neither lookup answered'end
 if named(product)~=named(pass)then return named(product)and'Product'or'Pass',nil end
 if priced(product)~=priced(pass)then return priced(product)and'Product'or'Pass','both lookups answered; chose by price'end
 return nil,'both lookups answered and neither name nor price tells them apart'
end
-- Server only ------------------------------------------------------------------------------
K.Changed=Run:IsServer()and Instance.new('BindableEvent')or nil -- fires after each resolution pass
local function lookup(id,infoType)
 local ok,info=pcall(function()return Marketplace:GetProductInfoAsync(id,infoType)end)
 if ok and type(info)=='table'then return info end
 return nil
end
local function rows()
 -- Every distinct positive Id with the row that configures it (C.Check reports duplicates).
 local out,seen={},{}
 for _,entry in ipairs(require(RS.CommerceConfig).AllRows())do
  local row=entry.Row
  if type(row.Id)=='number'and row.Id>0 and not seen[row.Id]then
   seen[row.Id]=true
   -- ShopDefinitions rows always state their kind; their Name is a display name.
   table.insert(out,{Id=row.Id,Row=row,Catalog=entry.Catalog})
  end
 end
 return out
end
function K.ResolveOnce(entry)
 local row,id=entry.Row,entry.Id;local override=K.Override(row)
 local product=override~='Pass'and lookup(id,Enum.InfoType.Product)or nil
 local pass=override~='Product'and lookup(id,Enum.InfoType.GamePass)or nil
 local kind,reason=K.Decide(row,product,pass)
 local info=kind=='Pass'and pass or kind=='Product'and product or nil
 -- Confident: the kind is settled and Roblox answered for it.
 return kind,info,reason,kind~=nil and info~=nil and(reason==nil or override~=nil)
end
function K.Start()
 if K.Started or not Run:IsServer()then return end;K.Started=true
 local f=folder()
 if not f then f=Instance.new('Folder');f.Name=K.FolderName;f.Parent=RS end
 local revision,retries=0,0;local warned={}
 task.spawn(function()
  while true do
   local unsure=false
   for _,entry in ipairs(rows())do
    local kind,info,reason,confident=K.ResolveOnce(entry)
    local key=string.format('%.0f',entry.Id)
    local old=f:GetAttribute('Kind_'..key)
    -- A transient failure never downgrades a kind that was already settled.
    if kind or old==nil or old=='Unavailable'then f:SetAttribute('Kind_'..key,kind or'Unavailable')end
    if info then
     f:SetAttribute('Price_'..key,type(info.PriceInRobux)=='number'and info.PriceInRobux or nil)
     f:SetAttribute('ForSale_'..key,not(kind=='Pass'and info.IsForSale==false))
    end
    if not confident then unsure=true end
    local message=reason and(entry.Row.Name or entry.Row.Key)..' ('..key..'): '..reason
    if message and not warned[message]then warned[message]=true;warn('[DOGROTS products]',message,'->',kind or'unavailable')end
    task.wait(.1)
   end
   revision+=1;f:SetAttribute('Resolved',true);f:SetAttribute('Revision',revision)
   K.Changed:Fire()
   -- Unsure answers are asked again soon a few times, then with the regular price refresh.
   retries=unsure and retries+1 or 0
   task.wait(unsure and retries<=K.Retries and K.Retry or K.Refresh)
  end
 end)
end
return K
