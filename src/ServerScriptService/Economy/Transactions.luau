-- DOGROTS RAM-first transaction layer.
-- Player profiles and server-local objects are mutated in memory during a live
-- session. Durable/global operations keep the original journaled transaction path.
local Transactions = {}
Transactions.__index = Transactions

local function copy(v)
 if type(v)~="table" then return v end
 local r={};for k,x in pairs(v) do r[k]=copy(x) end;return r
end
Transactions.Copy=copy

local function starts(k,prefix)return type(k)=="string" and k:sub(1,#prefix)==prefix end
local function isProfile(k)return starts(k,"p:")end
local function isLine(k)return starts(k,"line:")end
local function isSupply(k)return starts(k,"supply:")end
-- lucky:<uid> identifies a physical conveyor block that only exists on this server.
-- eventobject:<guid> is a world-event pickup spawned by this server; its claim never
-- needs DataStore (the object disappears with the server anyway).
local function isEphemeral(k)return isLine(k) or starts(k,"lucky:") or starts(k,"eventobject:")end
local function isFastKey(k)return isProfile(k) or isEphemeral(k) or isSupply(k)end

function Transactions.new(store,clock,guid,options)
 options=options or {}
 return setmetatable({
  Store=store,Clock=clock,Guid=guid,Lease=120,
  Cache={},Loaded={},Dirty={},Versions={},Owners={},Busy={},
  Receipts={},ReceiptOrder={},SupplyPools={},DurableRevisions={},
  SupplyBatch=options.SupplyBatch or function()return 16 end,
  SupplyLimit=options.SupplyLimit or function()return 0 end,
 },Transactions)
end

function Transactions:_rememberReceipt(id,result)
 if not id then return end
 if self.Receipts[id]==nil then
  table.insert(self.ReceiptOrder,id)
  if #self.ReceiptOrder>2048 then
   local old=table.remove(self.ReceiptOrder,1);self.Receipts[old]=nil
  end
 end
 self.Receipts[id]=copy(result)
end

function Transactions:_acquire(keys)
 local token=self.Guid();local deadline=os.clock()+12
 while true do
  local free=true
  for _,k in ipairs(keys)do if self.Busy[k]and self.Busy[k]~=token then free=false;break end end
  if free then for _,k in ipairs(keys)do self.Busy[k]=token end;return token end
  if os.clock()>=deadline then error("Account is busy; retry shortly",0)end
  task.wait()
 end
end
function Transactions:_release(keys,token)
 for _,k in ipairs(keys)do if self.Busy[k]==token then self.Busy[k]=nil end end
end

function Transactions:Recover(id)
 local key="tx:"..id
 local tx=self.Store:Read(key)
 if not tx then error("Missing transaction journal; refusing to unlock") end
 if tx.State=="Preparing" and tx.Deadline<=self.Clock() then
  tx=self.Store:Update(key,function(v)
   if v and v.State=="Preparing" and v.Deadline<=self.Clock() then v.State="Aborted";v.Error="Interrupted transaction" end
   return v
  end)
 end
 if tx.State=="Preparing" then return false end
 for _,k in ipairs(tx.Keys) do
  local updated=self.Store:Update(k,function(record)
   if record and record.Lock==id then
    if tx.State=="Committed" then
     if not tx.Writes then error("Unexpected lock on compacted committed transaction") end
     record.Value=copy(tx.Writes[k])
    end
    record.Lock=nil;record.Revision=(record.Revision or 0)+1
   end
   return record
  end)
  if isProfile(k)and updated then self.DurableRevisions[k]=updated.Revision or 0 end
 end
 if tx.Materialized then return true,tx end
 local receipt=self.Store:Update(key,function(v)
  if v and v.State~="Preparing" then v.Materialized=true;v.Writes=nil end
  return v
 end)
 return true,receipt
end

function Transactions:_readDurableValue(key)
 local record=self.Store:Read(key)
 if record and record.Lock then
  local done=self:Recover(record.Lock)
  if not done then error("Account is busy; retry shortly",0)end
  record=self.Store:Read(key)
 end
 if isProfile(key)and record then self.DurableRevisions[key]=record.Revision or 0 end
 return copy(record and record.Value)
end

function Transactions:Read(key)
 if isEphemeral(key) then return copy(self.Cache[key]) end
 if isProfile(key) and self.Loaded[key] then return copy(self.Cache[key]) end
 if isSupply(key) and self.SupplyPools[key] then return {Minted=self.SupplyPools[key].Current} end
 return self:_readDurableValue(key)
end

function Transactions:_captureProfile(key,value,dirty)
 self.Cache[key]=copy(value);self.Loaded[key]=true
 self.Versions[key]=(self.Versions[key]or 0)+1
 self.Dirty[key]=dirty==true or nil
 if value and value.Session and value.Session.Id then self.Owners[key]=value.Session.Id end
end

function Transactions:_reserveSupplyUnlocked(key)
 local pool=self.SupplyPools[key]
 if pool and pool.Current<pool.Limit then return pool end
 local batch=math.max(1,math.floor(tonumber(self.SupplyBatch(key))or 1))
 local hardLimit=math.max(0,math.floor(tonumber(self.SupplyLimit(key))or 0))
 for _=1,4 do
  local current=self.Store:Read(key)
  if current and current.Lock then
   local done=self:Recover(current.Lock)
   if not done then task.wait(.05);continue end
  end
  local blocked,reservedStart,reservedEnd
  local saved=self.Store:Update(key,function(record)
   blocked=nil;reservedStart=nil;reservedEnd=nil
   record=record or {Revision=0}
   if record.Lock then blocked=record.Lock;return record end
   local value=copy(record.Value)or{};local minted=math.max(0,math.floor(tonumber(value.Minted)or 0))
   if hardLimit>0 and minted>=hardLimit then reservedStart=minted;reservedEnd=minted;return record end
   local take=batch;if hardLimit>0 then take=math.min(take,hardLimit-minted)end
   reservedStart=minted;reservedEnd=minted+take;value.Minted=reservedEnd
   record.Value=value;record.Revision=(record.Revision or 0)+1
   return record
  end)
  if blocked then local ok=pcall(function()self:Recover(blocked)end);if not ok then task.wait(.05)end;continue end
  if reservedStart==nil then reservedEnd=(saved and saved.Value and saved.Value.Minted)or 0;reservedStart=reservedEnd end
  if reservedEnd<=reservedStart then error("Limited supply exhausted",0)end
  pool={Current=reservedStart,Limit=reservedEnd};self.SupplyPools[key]=pool;return pool
 end
 error("Supply allocator is busy; retry shortly",0)
end

function Transactions:_flushProfileUnlocked(key,abortOnStale)
 if not self.Loaded[key]or not self.Dirty[key]then return true end
 local snapshot=copy(self.Cache[key]);local version=self.Versions[key]or 0;local expected=self.Owners[key]
 local expectedRevision=self.DurableRevisions[key]
 for _=1,5 do
  local current=self.Store:Read(key)
  if current and current.Lock then
   local done=self:Recover(current.Lock);if not done then task.wait(.05);continue end
   current=self.Store:Read(key)
  end
  if expectedRevision==nil and current then expectedRevision=current.Revision or 0 end
  local blocked,conflict,stale,observedRevision
  local saved=self.Store:Update(key,function(record)
   blocked=nil;conflict=nil;stale=nil;observedRevision=nil
   record=record or {Revision=0}
   if record.Lock then blocked=record.Lock;return record end
   local live=record.Value
   if live and live.Session and expected and live.Session.Id~=expected and (live.Session.Expires or 0)>self.Clock() then
    conflict=true;return record
   end
   if expectedRevision~=nil and (record.Revision or 0)~=expectedRevision then
    stale=true;observedRevision=record.Revision or 0;return record
   end
   record.Value=copy(snapshot);record.Revision=(record.Revision or 0)+1;return record
  end)
  if blocked then local ok=pcall(function()self:Recover(blocked)end);if not ok then task.wait(.05)end;continue end
  if conflict then error("Profile session ownership changed; save refused",0)end
  if stale then
   local newer=observedRevision or(saved and saved.Revision)or expectedRevision
   if abortOnStale then
    -- Never let a routine autosave adopt an unknown external revision and then
    -- overwrite it on the next pass. A normal live session should have sole
    -- ownership of its profile; a mismatch is treated as a safety conflict.
    return false,"Profile revision conflict; refusing to overwrite newer saved data"
   end
   self.DurableRevisions[key]=newer;expectedRevision=newer;continue
  end
  if not saved then error("Profile save returned no record",0)end
  self.DurableRevisions[key]=saved.Revision or((expectedRevision or 0)+1)
  if (self.Versions[key]or 0)==version then self.Dirty[key]=nil end
  return true
 end
 error("Profile save is busy; retry shortly",0)
end
function Transactions:FlushProfile(userId)
 local key=type(userId)=="string"and starts(userId,"p:")and userId or("p:"..tostring(userId))
 if not self.Loaded[key]or not self.Dirty[key]then return true end
 -- Autosave snapshots do not hold the gameplay lock while DataStore yields.
 -- If gameplay mutates the profile during the save, Versions keeps it dirty and
 -- the newer state is picked up by the next autosave. Slow/global transactions
 -- call _flushProfileUnlocked while already holding the profile lock.
 local ok,result=pcall(function()return self:_flushProfileUnlocked(key,true)end)
 if not ok then return false,tostring(result)end
 return true,result
end

function Transactions:FlushAllProfiles()
 local saved,failed=0,{}
 local keys={};for key in pairs(self.Loaded)do if isProfile(key)and self.Dirty[key]then table.insert(keys,key)end end;table.sort(keys)
 for _,key in ipairs(keys)do
  local ok,err=self:FlushProfile(key)
  if ok then saved+=1 else failed[key]=err end
 end
 return {Saved=saved,Failed=failed}
end

function Transactions:UnloadProfile(userId)
 local key=type(userId)=="string"and starts(userId,"p:")and userId or("p:"..tostring(userId))
 if self.Dirty[key]then return false,"Profile still has unsaved changes"end
 self.Cache[key]=nil;self.Loaded[key]=nil;self.Dirty[key]=nil;self.Versions[key]=nil;self.Owners[key]=nil;self.DurableRevisions[key]=nil;self.Busy[key]=nil
 return true
end

-- Atomic batched counter for cross-server totals. Used by Global Dig so a mining
-- tick never has to transact the whole player profile through DataStore.
function Transactions:AddCounter(key,field,delta)
 field=field or "Total";delta=math.floor(tonumber(delta)or 0)
 if delta==0 then return self:_readDurableValue(key)or{} end
 for _=1,4 do
  -- One UpdateAsync per flush. A journal lock (rare: milestone claims) cancels the
  -- write, gets recovered, and the loop retries.
  local blocked
  local saved=self.Store:Update(key,function(record)
   blocked=nil
   record=record or {Revision=0}
   if record.Lock then blocked=record.Lock;return nil end
   local value=copy(record.Value)or{};value[field]=math.max(0,math.floor(tonumber(value[field])or 0)+delta)
   record.Value=value;record.Revision=(record.Revision or 0)+1;return record
  end)
  if blocked then pcall(function()self:Recover(blocked)end);task.wait(.05);continue end
  return copy(saved and saved.Value)or{}
 end
 error("Global counter is busy; retry shortly",0)
end

-- Merge best-weight candidates into a global record book with a single UpdateAsync.
-- Returns improvements ({[itemId]={Previous=row|nil}}) and the merged book.
function Transactions:MergeRecords(key,candidates)
 for _=1,4 do
  local blocked,improved,book
  self.Store:Update(key,function(record)
   blocked=nil;improved={};book=nil
   record=record or {Revision=0}
   if record.Lock then blocked=record.Lock;return nil end
   book=copy(record.Value)or{}
   for itemId,row in pairs(candidates)do
    local previous=book[itemId]
    if type(row)=="table" and tonumber(row.WeightKg) and (not previous or row.WeightKg>(tonumber(previous.WeightKg)or 0))then
     book[itemId]=copy(row);improved[itemId]={Previous=previous and copy(previous)or nil}
    end
   end
   if next(improved)==nil then return nil end
   record.Value=copy(book);record.Revision=(record.Revision or 0)+1;return record
  end)
  if blocked then pcall(function()self:Recover(blocked)end);task.wait(.05);continue end
  return improved or {},book or {}
 end
 error("Record book is busy; retry shortly",0)
end

function Transactions:_canFast(sorted)
 local supplies=0;local hasEphemeral=false
 for _,k in ipairs(sorted)do if isEphemeral(k)then hasEphemeral=true end end
 for _,k in ipairs(sorted)do
  if not isFastKey(k)then return false end
  if isProfile(k)and not self.Loaded[k]then return false end
  if isSupply(k)then
   -- Strict limited mints use the durable path. Dog-line state is intentionally
   -- server-local, so that one path keeps a one-at-a-time reserved serial instead
   -- of trying to journal an ephemeral line:<uid> key into DataStore.
   if not hasEphemeral and math.max(0,math.floor(tonumber(self.SupplyLimit(k))or 0))>0 then return false end
   supplies+=1
  end
 end
 return supplies<=1
end

function Transactions:_runFast(sorted,transform,id)
 if id and self.Receipts[id]~=nil then return true,copy(self.Receipts[id]),id end
 local token=self:_acquire(sorted)
 local ok,a,b=pcall(function()
  if id and self.Receipts[id]~=nil then return true,copy(self.Receipts[id])end
  local values={};local initialSupply={};local hasLiveLine=false
  for _,k in ipairs(sorted)do if isEphemeral(k)and isLine(k)and self.Cache[k]~=nil then hasLiveLine=true end end
  for _,k in ipairs(sorted)do
   if isProfile(k)or isEphemeral(k)then values[k]=copy(self.Cache[k])
   elseif isSupply(k)then
    local pool=self.SupplyPools[k]
    if not hasLiveLine then pool=self:_reserveSupplyUnlocked(k)end
    if pool then values[k]={Minted=pool.Current};initialSupply[k]=pool.Current else values[k]={Minted=0};initialSupply[k]=0 end
   end
  end
  local result=transform(values)
  -- Validate reserved serial ranges before publishing any profile mutation.
  for _,k in ipairs(sorted)do if isSupply(k)then
   local before=initialSupply[k]or 0;local after=math.max(0,math.floor(tonumber(values[k]and values[k].Minted)or before))
   local pool=self.SupplyPools[k]
   if after~=before then
    if not pool or after<before or after>pool.Limit then error("Supply reservation exhausted; retry",0)end
   end
  end end
  for _,k in ipairs(sorted)do
   if isProfile(k)then self:_captureProfile(k,values[k],true)
   elseif isEphemeral(k)then self.Cache[k]=copy(values[k]);self.Loaded[k]=true
   elseif isSupply(k)then
    local pool=self.SupplyPools[k];if pool then pool.Current=math.max(pool.Current,math.floor(tonumber(values[k]and values[k].Minted)or pool.Current))end
   end
  end
  self:_rememberReceipt(id,result)
  return true,copy(result)
 end)
 self:_release(sorted,token)
 if not ok then return false,tostring(a),id end
 return a,b,id
end

function Transactions:_runDurableCore(sorted,transform,id)
 id=id or self.Guid();local txKey="tx:"..id;local attempt=self.Guid();local finalProfiles={}
 local ok,result=pcall(function()
  local journal=self.Store:Update(txKey,function(v)
   if v then return v end
   return {State="Preparing",Keys=sorted,Deadline=self.Clock()+self.Lease,Attempt=attempt}
  end)
  if journal.Attempt~=attempt then
   local done,receipt=self:Recover(id)
   if not done then error("Transaction pending; retry with the same request ID") end
   if receipt.State~="Committed" then error(receipt.Error or "Transaction aborted") end
   return receipt.Result
  end
  local values={}
  for _,key in ipairs(sorted) do
   local current=self.Store:Read(key)
   if current and current.Lock and current.Lock~=id then self:Recover(current.Lock) end
   local locked=self.Store:Update(key,function(v)
    v=v or {Revision=0};if not v.Lock or v.Lock==id then v.Lock=id end;return v
   end)
   if locked.Lock~=id then error("Account busy; please retry") end
   values[key]=copy(locked.Value)
   if isProfile(key)and not self.Loaded[key]then
    local profile=values[key]
    if profile and profile.Session and profile.Session.Id and (profile.Session.Expires or 0)>self.Clock()then
     error("Player data is active on another server; retry later",0)
    end
   end
  end
  local output=transform(values)
  for _,key in ipairs(sorted)do if isProfile(key)then finalProfiles[key]=copy(values[key])end end
  local decided=self.Store:Update(txKey,function(v)
   if v.State=="Preparing" and v.Deadline>self.Clock() then
    v.State="Committed";v.Writes=copy(values);v.Result=copy(output);v.CommittedAt=self.Clock()
   end
   return v
  end)
  if decided.State~="Committed" then error("Transaction expired before commit") end
  self:Recover(id);return decided.Result
 end)
 if ok then return true,result,id,finalProfiles end
 local recovered,receipt=pcall(function()
  local tx=self.Store:Update(txKey,function(v)
   if v and v.State=="Preparing" and v.Attempt==attempt then v.State="Aborted";v.Error=tostring(result) end
   return v
  end)
  if tx then self:Recover(id) end
  return tx
 end)
 if recovered and receipt and receipt.State=="Committed" then return true,receipt.Result,id,finalProfiles end
 if not recovered then return false,"Storage unavailable. Operation pending; retry the same request.",id,finalProfiles end
 return false,tostring(result),id,finalProfiles
end

function Transactions:_runDurable(sorted,transform,id)
 local lockKeys,wasLoaded={},{}
 for _,k in ipairs(sorted)do
  if isProfile(k)then wasLoaded[k]=self.Loaded[k]==true end
  if isProfile(k)or isSupply(k)then table.insert(lockKeys,k)end
 end
 local token=#lockKeys>0 and self:_acquire(lockKeys)or nil
 local outerOk,success,result,receipt,finalProfiles=pcall(function()
  for _,k in ipairs(sorted)do if isProfile(k)and self.Loaded[k]and self.Dirty[k]then self:_flushProfileUnlocked(k)end end
  return self:_runDurableCore(sorted,transform,id)
 end)
 if token then self:_release(lockKeys,token)end
 if not outerOk then return false,tostring(success),id end
 if success then
  for _,k in ipairs(sorted)do if isProfile(k)then
   local final=finalProfiles and finalProfiles[k]
   local joining=(#sorted==1 and sorted[1]==k and final and final.Session and final.Session.Id)
   if wasLoaded[k]or joining then
    if final==nil then final=self:_readDurableValue(k)end
    if final~=nil then self:_captureProfile(k,final,false)end
   end
  end end
 end
 return success,result,receipt
end

function Transactions:Run(keys,transform,id)
 local seen,sorted={},{}
 for _,k in ipairs(keys)do if not seen[k]then seen[k]=true;table.insert(sorted,k)end end
 table.sort(sorted)
 -- Background ticks and other naturally idempotent RAM actions do not need to
 -- consume receipt-cache slots. Durable transactions allocate an ID internally.
 if self:_canFast(sorted)then return self:_runFast(sorted,transform,id)end
 return self:_runDurable(sorted,transform,id)
end

return Transactions
