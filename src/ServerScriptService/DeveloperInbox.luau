-- Messages stay inside Roblox. Read access is limited to the experience owner or configured developers.
local Run=game:GetService('RunService')
local Data=game:GetService('DataStoreService')
local Text=game:GetService('TextService')
local S={DeveloperUserIds={},Memory={}}
local preview=Run:IsStudio()and game.GameId==0
local db=not preview and Data:GetDataStore('DOGROTS_DEVELOPER_INBOX_V1')
local last,busy={},{}
function S.IsDeveloper(p)
 if preview then return true end
 if table.find(S.DeveloperUserIds,p.UserId)then return true end
 if game.CreatorType==Enum.CreatorType.User then return p.UserId==game.CreatorId end
 local ok,rank=pcall(function()return p:GetRankInGroupAsync(game.CreatorId)end)
 return ok and rank>=254
end
local function key(day,shard)return 'day:'..day..':'..shard end
local function read(k)
 if preview then return S.Memory[k]end
 return db:GetAsync(k)
end
local function update(k,fn)
 if preview then local v=fn(S.Memory[k]);if v then S.Memory[k]=v end;return S.Memory[k]end
 return db:UpdateAsync(k,fn)
end
function S.Request(player,action,a)
 assert(type(a)=='table','Invalid request')
 if action=='Access'then return true,{Developer=S.IsDeveloper(player),Preview=preview}end
 if action=='Read'then
  assert(S.IsDeveloper(player),'Developer access only')
  assert(not busy[player],'Please wait')
  local day=a.Day or 0;assert(type(day)=='number'and day%1==0 and day>=0 and day<=6,'Choose a recent day')
  local throttle='read:'..player.UserId;assert(os.clock()-(last[throttle]or -10)>=5,'Please wait');last[throttle]=os.clock()
  busy[player]=true
  local ok,rows=pcall(function()
   local all={};local date=os.date('!%Y-%m-%d',os.time()-day*86400)
   for shard=0,15 do local v=read(key(date,shard));for _,m in ipairs(v and v.Messages or{})do table.insert(all,m)end end
   table.sort(all,function(a,b)return a.At>b.At end)
   while #all>200 do table.remove(all)end
   return {Rows=all,Date=date,Preview=preview}
  end)
  busy[player]=nil;if not ok then warn('Inbox read failed:',rows);return false,'Inbox unavailable; try again'end
  return true,rows
 end
 assert(action=='Send','Unknown action')
 assert(type(a.Text)=='string'and #a.Text<=2000,'Maximum 500 characters')
 local n=utf8.len(a.Text);assert(n and n>=10 and n<=500,'Write 10–500 characters')
 assert(type(a.Token)=='string'and #a.Token==32 and a.Token:match('^%x+$'),'Invalid message ID')
 assert(not busy[player],'Please wait')
 assert(os.clock()-(last[player]or -5)>=3,'Please wait');last[player]=os.clock();busy[player]=true
 local ok,result=pcall(function()
  local filtered
  if preview then filtered='[LOCAL PREVIEW] '..a.Text
  else
   local f=Text:FilterStringAsync(a.Text,player.UserId,Enum.TextFilterContext.PublicChat)
   filtered=f:GetNonChatStringForBroadcastAsync()
  end
  local now=os.time();local k=key(os.date('!%Y-%m-%d',now),player.UserId%16);local receipt=tostring(player.UserId)..':'..a.Token
  local stored=update(k,function(v)
   v=v or{Messages={},Last={}}
   for _,m in ipairs(v.Messages)do if m.Id==receipt then return v end end
   assert(now-(v.Last[tostring(player.UserId)]or 0)>=60,'One message per minute; please wait')
   assert(#v.Messages<1000,'The mailbox is full today; please try tomorrow')
   table.insert(v.Messages,{Id=receipt,UserId=player.UserId,At=now,Text=filtered})
   v.Last[tostring(player.UserId)]=now;return v
  end)
  assert(stored,'Message was not saved')
  return {Message=preview and 'Saved in this Studio test only. Live servers save messages for the developers.'or 'Thank you! Your message has been saved for the developers.',Preview=preview}
 end)
 busy[player]=nil
 if not ok then
  local message=tostring(result)
  if message:find('One message per minute',1,true)then return false,'One message per minute; please wait'end
  warn('Developer inbox save failed:',message);return false,'Could not save your message. Your draft is kept; try again.'
 end
 return true,result
end
game.Players.PlayerRemoving:Connect(function(p)last[p]=nil;busy[p]=nil;last['read:'..p.UserId]=nil end)
return S
