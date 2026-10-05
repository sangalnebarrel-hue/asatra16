local C=require(game.ReplicatedStorage.LeaderboardConfig)
local Stats=require(script.Parent.LifetimeStats)
local Support=require(script.Parent.SupportReceipts)
local Players=game:GetService('Players')
local S={};S.__index=S
function S.Clean(rows)
 local values={}
 for _,row in ipairs(rows or {})do
  local id=tonumber(row.key);local v=row.value
  if id and id%1==0 and id~=0 and type(v)=='number'and v==v and v>=0 and v<math.huge then
   values[id]=math.max(values[id]or 0,math.floor(v))
  end
 end
 local out={};for id,v in pairs(values)do if v>0 then table.insert(out,{key=tostring(id),value=v})end end
 table.sort(out,function(a,b)return a.value>b.value or a.value==b.value and tonumber(a.key)<tonumber(b.key)end)
 while #out>C.Top do table.remove(out)end;return out
end
function S.new(runtime,adapter,renderer,clock)
 local self=setmetatable({Runtime=runtime,Adapter=adapter,Renderer=renderer,Clock=clock or os.clock,Cache={},Pending={},Written={},Retry={},Names={},NameBusy={},ReadDue={},Status={}},S)
 for _,c in ipairs(C.Categories)do self.Pending[c.Key]={};self.Written[c.Key]={}end
 return self
end
function S:Name(id)
 local online=Players:GetPlayerByUserId(id);if online then return '@'..online.Name end
 local cached=self.Names[id];if cached and cached.Expires>self.Clock()then return cached.Name end
 if id>0 and not self.NameBusy[id]then
  self.NameBusy[id]=true
  task.spawn(function()
   local ok,value=pcall(function()return Players:GetNameFromUserIdAsync(id)end)
   self.Names[id]={Name=ok and '@'..value or 'Player '..id,Expires=self.Clock()+(ok and 3600 or 120)}
   self.NameBusy[id]=nil
  end)
 end
 return cached and cached.Name or 'Player '..id
end
function S:Queue(id,p)
 if not p then return end
 for _,c in ipairs(C.Categories)do
  if c.Key=='Supporters'and not Support.Configured()then continue end
  local v=Stats.Value(p,c.Key)
  if v>(self.Written[c.Key][id]or 0)then self.Pending[c.Key][id]=math.max(v,self.Pending[c.Key][id]or 0)end
 end
end
function S:Allowed(key)
 return not self.Retry[key]or self.Clock()>=self.Retry[key].At
end
function S:Failure(key)
 local previous=self.Retry[key];local delay=math.min(C.MaxRetrySeconds,previous and previous.Delay*2 or C.RetrySeconds)
 self.Retry[key]={Delay=delay,At=self.Clock()+delay}
end
function S:Flush()
 if self.Writing then return end;self.Writing=true
 for _,c in ipairs(C.Categories)do
  if c.Key~='Supporters'or Support.Configured()then
   for id,value in pairs(self.Pending[c.Key])do
    local key=c.Key..':'..id
    if self:Allowed(key)then
     local ok,result=pcall(self.Adapter.Write,c,id,value)
     if ok and result~=false then
      self.Written[c.Key][id]=value;self.Retry[key]=nil
      if self.Pending[c.Key][id]==value then self.Pending[c.Key][id]=nil end
     else self:Failure(key)end
    end
   end
  end
 end
 self.Writing=false
end
function S:Refresh()
 if self.Refreshing then return end;self.Refreshing=true
 for _,c in ipairs(C.Categories)do
  local status;local rows=self.Cache[c.Key]or {};local key='read:'..c.Key
  if c.Key=='Supporters'and not Support.Configured()then status='Coming soon';rows={}
 elseif self:Allowed(key)and self.Clock()>=(self.ReadDue[c.Key]or 0)then
   local ok,result=pcall(self.Adapter.Read,c)
   if ok and type(result)=='table'then
    rows=S.Clean(result);self.Cache[c.Key]=rows;self.Retry[key]=nil;self.ReadDue[c.Key]=self.Clock()+C.RefreshSeconds
    status=self.Adapter.Preview and 'Studio preview · current test session'or (#rows==0 and 'No records yet · all time'or 'All time · updated every 2 min')
   else self:Failure(key);status=#rows>0 and 'Saved standings · refresh pending'or 'Records unavailable · retrying'end
  elseif self.Retry[key]then status=#rows>0 and 'Saved standings · refresh pending'or 'Records unavailable · retrying'
  else status=self.Status[c.Key]or 'Connecting to the records…'end
  self.Status[c.Key]=status
  self.Renderer.Render(c,rows,status,function(id)return self:Name(id)end)
 end
 self.Refreshing=false
end
function S.Start()
 if S.Active then return S.Active end
 local Runtime=require(script.Parent.Runtime);local Renderer=require(script.Parent.LeaderboardRenderer)
 local root=workspace.DOGROTS_District:WaitForChild('09_DogPark'):WaitForChild('LeaderboardPlaza')
 Renderer.Create(root)
 local memory=game:GetService('RunService'):IsStudio()and game.GameId==0
 local DS=game:GetService('DataStoreService');local stores={};local values={}
 for _,c in ipairs(C.Categories)do if memory then values[c.Key]={}else stores[c.Key]=DS:GetOrderedDataStore(c.Store)end end
 local adapter={Preview=memory}
 adapter.Read=function(c)
  if memory then local rows={};for id,value in pairs(values[c.Key])do table.insert(rows,{key=tostring(id),value=value})end;return rows end
  if DS:GetRequestBudgetForRequestType(Enum.DataStoreRequestType.GetSortedAsync)<1 then error('Read budget pending',0)end
  return stores[c.Key]:GetSortedAsync(false,C.Top):GetCurrentPage()
 end
 adapter.Write=function(c,id,value)
  if memory then values[c.Key][id]=math.max(values[c.Key][id]or 0,value);return true end
  if id<=0 then return true end
  if DS:GetRequestBudgetForRequestType(Enum.DataStoreRequestType.SetIncrementSortedAsync)<1 then return false end
  stores[c.Key]:UpdateAsync(tostring(id),function(old)return math.max(tonumber(old)or 0,value)end)
  task.wait(.15);return true
 end
 local self=S.new(Runtime,adapter,Renderer);S.Active=self
 -- Mirror the final committed checkpoint, including the last seconds before leave.
 Runtime.Engine.OnProfileReleased=function(id)
  local p=Runtime.Engine:Get(id);if p then self:Queue(id,p);self:Flush()end
 end
 local function queueAll()for id,p in pairs(Runtime.Views)do self:Queue(id,p)end end
 Players.PlayerRemoving:Connect(function(p)self:Queue(p.UserId,Runtime.Views[p.UserId])end)
 game:BindToClose(function()
  queueAll();local deadline=os.clock()+22
  repeat self:Flush();local pending=false;for _,v in pairs(self.Pending)do if next(v)then pending=true;break end end
   if not pending then break end;task.wait(1)
  until os.clock()>deadline
 end)
 task.spawn(function()
  task.wait(5);local nextWrite=0
  while true do
   local now=os.clock()
   if now>=nextWrite then queueAll();self:Flush();nextWrite=now+C.WriteSeconds end
   -- Each category owns its next read deadline, including recovery after failure.
   self:Refresh()
   if next(self.Retry)then self:Flush()end
   task.wait(C.RetrySeconds)
  end
 end)
 return self
end
return S
