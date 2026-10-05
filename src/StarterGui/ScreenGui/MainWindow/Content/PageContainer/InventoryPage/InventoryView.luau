-- Pure UI projection of existing profile entries; never grants or saves anything.
local V = {}
function V.Count(t)
 local n = 0
 for _ in pairs(t or {}) do n += 1 end
 return n
end
function V.BlockCount(profile)
 local count=0
 for _ in pairs(profile.OwnedBlocks or{})do count+=1 end
 for _,n in pairs(profile.LuckyCredits or{})do count+=math.max(0,n)end
 return count
end
function V.Number(n)
 if n >= 1e9 then return string.format('%.2fB', n / 1e9) end
 if n >= 1e6 then return string.format('%.2fM', n / 1e6) end
 if n >= 1e3 then return string.format('%.2fK', n / 1e3) end
 return tostring(math.floor(n))
end
function V.Progress(profile, definitions, depth)
 local found, total = 0, 0
 for id, def in pairs(definitions) do
  if not depth or def.Depth == depth then
   total += 1
   if profile.Collection[id] then found += 1 end
  end
 end
 return found, total
end
function V.Rows(profile, definitions, mode, filters, query, favorites, order)
 local rows = {}
 query = string.lower(query or '')
 if mode == 'LuckyBlocks' then
  for tier,quantity in pairs(profile.LuckyCredits or{})do
   if quantity>0 and(not filters.Class or filters.Class==tier)and(tier..' lucky block stored'):lower():find(query,1,true)then
    table.insert(rows,{Key='credit:'..tier,Block={Tier=tier,State='Stored',Quantity=quantity},DisplayName=tier..' LUCKY BLOCK ×'..quantity,FoundAt=0})
   end
  end
  for uid, b in pairs(profile.OwnedBlocks or {}) do
   if (not filters.Class or b.Tier == filters.Class) and (b.Tier..' lucky block '..b.State):lower():find(query, 1, true) then
    table.insert(rows, {Key=uid, Block=b, DisplayName=b.Tier..' LUCKY BLOCK', FoundAt=b.PurchasedAt or 0})
   end
  end
 else
  local source = mode == 'Collection' and definitions or profile.Items or {}
  for key, value in pairs(source) do
   local found = mode ~= 'Collection' or profile.Collection[key] == true
   local row = mode == 'Collection' and {
    Key=key, ItemId=key, DisplayName=found and value.DisplayName or 'UNDISCOVERED',
    Depth=value.Depth, Class=value.Class, Found=found, IsCollection=true,
    BaseDropChance=value.BaseDropChance, Description=value.Description,
   } or table.clone(value)
   row.Key = key
   local searchable = found and (row.DisplayName or ''):lower() or ''
   if (query == '' or searchable:find(query, 1, true))
    and (not favorites or row.Favorite)
    and (not filters.Depth or row.Depth == filters.Depth)
    and (not filters.Class or row.Class == filters.Class)
    and (mode == 'Collection' or not filters.Weight or row.WeightTier == filters.Weight)
    and (mode == 'Collection' or not filters.Mutation or row.Mutation == filters.Mutation) then
    table.insert(rows, row)
   end
  end
 end
 table.sort(rows, function(a, b)
  local av, bv
  if order == 'NAME' then
   av, bv = a.DisplayName, b.DisplayName
   if av ~= bv then return av < bv end
  elseif order == 'HEAVIEST' then av, bv = a.WeightKg or 0, b.WeightKg or 0
  elseif order == 'RAREST' then av, bv = a.CombinedOdds or 0, b.CombinedOdds or 0
  elseif order == 'DEPTH' then
   av, bv = a.Depth or 0, b.Depth or 0
   if av ~= bv then return av < bv end
  else av, bv = a.FoundAt or 0, b.FoundAt or 0 end
  if av ~= bv then return av > bv end
  return a.Key < b.Key
 end)
 return rows
end
function V.Remaining(block, now)
 return math.max(0, math.ceil((block.ReadyAt or now) - now))
end
return V
