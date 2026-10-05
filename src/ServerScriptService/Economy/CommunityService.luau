local Players=game:GetService('Players');local DS=game:GetService('DataStoreService');local Text=game:GetService('TextService');local RS=game:GetService('ReplicatedStorage');local Run=game:GetService('RunService')
local C=require(RS.CommunityConfig);local Runtime=require(script.Parent.Runtime);local R=require(script.Parent.Rules)
local S={SessionCounts={},Names={},Busy={},PendingScores={}};local memory=Run:IsStudio()and game.GameId==0
local hub=workspace:WaitForChild('DOGROTS_District'):WaitForChild('32_WelcomeHub');local board=hub:FindFirstChild('AllTimeLeaderboard',true);local kingAnchor=hub:WaitForChild('ServerKingAnchor');local mailbox=hub:WaitForChild('Mailbox')
local store=not memory and DS:GetOrderedDataStore(C.Leaderboard.OrderedStore)
local lastScores={}
local function score(p)return math.max(0,math.floor(p[C.Leaderboard.Metric]or 0))end
local function displayName(id)
 if S.Names[id]then return S.Names[id]end
 local p=Players:GetPlayerByUserId(id);if p then S.Names[id]=p.DisplayName;return p.DisplayName end
 local ok,name=pcall(function()return Players:GetNameFromUserIdAsync(id)end);if ok then S.Names[id]=name end;return ok and name or ('Player '..id)
end
local function guiText(parent,name,text,pos,size,color)
 local t=Instance.new('TextLabel');t.Name=name;t.BackgroundTransparency=1;t.Position=pos;t.Size=size;t.Text=text;t.TextColor3=color or Color3.fromRGB(248,235,204);t.Font=Enum.Font.GothamBold;t.TextScaled=true;t.Parent=parent;return t
end
function S.RefreshBoard()
 -- The rebuilt plaza has its own LeaderboardService; the legacy board is optional.
 if not board then return false end
 local entries={}
 if memory then for _,player in ipairs(Players:GetPlayers())do local p=Runtime.Views[player.UserId];if p then table.insert(entries,{key=tostring(player.UserId),value=score(p)})end end;table.sort(entries,function(a,b)return a.value>b.value end)
 else
  local ok,page=pcall(function()return store:GetSortedAsync(false,C.Leaderboard.Top)end)
  if not ok then board:SetAttribute('Status','Cached · refresh pending');return false end;entries=page:GetCurrentPage()
 end
 local panel=board:FindFirstChild('LeaderboardRows');if panel then panel:Destroy()end
 panel=Instance.new('SurfaceGui');panel.Name='LeaderboardRows';panel.Face=Enum.NormalId.Back;panel.CanvasSize=Vector2.new(950,1150);panel.LightInfluence=0;panel.Parent=board
 guiText(panel,'Title','ALL-TIME TOP PLAYERS',UDim2.fromOffset(20,14),UDim2.fromOffset(910,76),Color3.fromRGB(255,211,115))
 guiText(panel,'Metric','PERSONAL BEST XP',UDim2.fromOffset(20,92),UDim2.fromOffset(910,40),Color3.fromRGB(179,199,199))
 for i=1,10 do
  local entry=entries[i];local y=147+(i-1)*91
  guiText(panel,'Rank'..i,'#'..i,UDim2.fromOffset(12,y),UDim2.fromOffset(76,65))
  if entry then local id=tonumber(entry.key)
   local image=Instance.new('ImageLabel');image.BackgroundTransparency=1;image.Position=UDim2.fromOffset(100,y);image.Size=UDim2.fromOffset(74,74);image.Image='rbxthumb://type=AvatarHeadShot&id='..id..'&w=150&h=150';image.Parent=panel
   guiText(panel,'Player'..i,displayName(id),UDim2.fromOffset(194,y),UDim2.fromOffset(466,35))
   guiText(panel,'Score'..i,'Lv. '..math.min(100,1+math.floor(math.sqrt(entry.value/25)))..' · '..entry.value..' XP',UDim2.fromOffset(194,y+38),UDim2.fromOffset(680,32),Color3.fromRGB(179,199,199))
  else guiText(panel,'Empty'..i,'Your journey starts here',UDim2.fromOffset(194,y+10),UDim2.fromOffset(660,48),Color3.fromRGB(139,159,159))end
 end
 local oldFront=board:FindFirstChild('LeaderboardRowsFront');if oldFront then oldFront:Destroy()end
 local front=panel:Clone();front.Name='LeaderboardRowsFront';front.Face=Enum.NormalId.Front;front.Parent=board
 board:SetAttribute('Status',memory and 'Studio preview' or 'Live');return true
end
function S.QueueScore(player)
 if not player:GetAttribute('EconomyReady')then return end
 local p=Runtime.Views[player.UserId]
 local value=p and score(p)or math.max(0,(player:GetAttribute('XP')or 0)+25*((player:GetAttribute('Level')or 1)-1)^2)
 if value>(lastScores[player.UserId]or -1)then S.PendingScores[player.UserId]=math.max(S.PendingScores[player.UserId]or 0,value)end
end
function S.WriteScores()
 for _,player in ipairs(Players:GetPlayers())do S.QueueScore(player)end
 if S.Writing then return end;S.Writing=true
 for id,value in pairs(S.PendingScores)do
  local ok=memory or pcall(function()store:UpdateAsync(tostring(id),function(old)return math.max(old or 0,value)end)end)
  if ok then lastScores[id]=value;if S.PendingScores[id]==value then S.PendingScores[id]=nil end end
 end
 S.Writing=false
end
local KingPresentation=require(script.Parent.ServerKingPresentation)
local presentation=KingPresentation.new(hub,kingAnchor)
S.KingPresentation=presentation
function S.RefreshKing()
 local best,bestScore
 for _,player in ipairs(Players:GetPlayers())do local p=Runtime.Views[player.UserId]
  if p and Runtime.Ready(player)and not player:GetAttribute('EconomyLeaving')then local s=score(p);if not best or s>bestScore or s==bestScore and player.UserId<best.UserId then best,bestScore=player,s end end
 end
 presentation:Set(best,best and (best:GetAttribute('Level')or 1)or 1)
end
function S.Submit(player,a)
 if not Runtime.Ready(player)or not Runtime.Allow(player,2)or S.Busy[player]then return false,'Please wait'end
 if type(a)~='table' or type(a.Text)~='string' or type(a.Category)~='string' or not table.find(C.Mailbox.Categories,a.Category)or type(a.Request)~='string' or #a.Request~=32 or not a.Request:match('^%x+$')then return false,'Invalid message'end
 local length=utf8.len(a.Text);if not length or length<1 or length>C.Mailbox.MaxCharacters or #a.Text>1200 then return false,'Use 1–300 characters'end
 local char=player.Character;local root=char and char:FindFirstChild('HumanoidRootPart');if not root or (root.Position-mailbox.Position).Magnitude>22 then return false,'Visit the mailbox to send a message'end
 local now=os.time();local day=math.floor(now/86400);local hour=math.floor(now/3600);local quota='mailquota:'..player.UserId..':'..day;local index='feedback:'..hour..':'..player.UserId%16
 local readOK,saved=pcall(function()return Runtime.Tx:Read(quota)end)
 if not readOK then return false,'Could not load the mailbox. Please try again later.'end
 if saved and saved.Requests and saved.Requests[a.Request]then return true,'THANKS FOR HELPING DOGROTS! 🐾'end
 if saved and (saved.NextAt>now or saved.Count>=C.Mailbox.DailyLimit)or (S.SessionCounts[player]or 0)>=C.Mailbox.SessionLimit then return false,'Message limit reached. Please come back later.'end
 S.Busy[player]=true
 local filtered,text=pcall(function()
  local clean=a.Text:gsub('%c',' '):match('^%s*(.-)%s*$');R.Check(#clean>0,'Write a message first')
  return Text:FilterStringAsync(clean,player.UserId):GetNonChatStringForBroadcastAsync()
 end)
 if not filtered then S.Busy[player]=nil;return false,'Filtering is unavailable. Please try again later.'end
 local transport,ok,result=pcall(function()return Runtime.Tx:Run({quota,index},function(v)
  local q=v[quota]or{Count=0,NextAt=0,Requests={}};v[quota]=q
  if q.Requests[a.Request]then return 'THANKS FOR HELPING DOGROTS! 🐾'end
  R.Check(player.Parent and q.NextAt<=now and q.Count<C.Mailbox.DailyLimit,'Please wait before sending another message')
  local rows=v[index]or{};v[index]=rows;R.Check(#rows<256,'Mailbox is busy. Please try again later.')
  table.insert(rows,{UserId=player.UserId,At=now,Category=a.Category,FilteredText=text,PlaceId=game.PlaceId,JobId=game.JobId,Request=a.Request})
  q.Count+=1;q.NextAt=now+C.Mailbox.Cooldown;q.Requests[a.Request]=true;return 'THANKS FOR HELPING DOGROTS! 🐾'
 end,'mail-attempt:'..game:GetService('HttpService'):GenerateGUID(false))end)
 S.Busy[player]=nil;if transport and ok then S.SessionCounts[player]=(S.SessionCounts[player]or 0)+1;return true,result end
 return false,'Could not save your message. Retry with the same message.'
end
function S.Start()
 local prompt=Instance.new('ProximityPrompt');prompt.ActionText='LEAVE A MESSAGE';prompt.ObjectText='DOGROTS MAILBOX';prompt.RequiresLineOfSight=false;prompt.MaxActivationDistance=12;prompt.Parent=mailbox
 prompt.Triggered:Connect(function(player)RS.DogEconomyOpen:FireClient(player,'Feedback')end)
 RS.FeedbackRequest.OnServerInvoke=S.Submit
 Players.PlayerRemoving:Connect(function(p)S.QueueScore(p);S.SessionCounts[p]=nil;S.Busy[p]=nil;task.defer(S.WriteScores);task.defer(S.RefreshKing)end)
 game:BindToClose(function()
  for _,p in Players:GetPlayers()do S.QueueScore(p)end
  local untilTime=os.clock()+25
  repeat if not S.Writing then S.WriteScores()end;if not next(S.PendingScores)then break end;task.wait(.5)until os.clock()>=untilTime
 end)
 task.spawn(function()while true do task.wait(8);S.RefreshKing();task.wait(C.Leaderboard.KingSeconds-8)end end)
 task.spawn(function()while true do task.wait(12);S.WriteScores();task.wait(C.Leaderboard.WriteSeconds-12)end end)
 task.spawn(function()while true do task.wait(15);S.RefreshBoard();task.wait(C.Leaderboard.RefreshSeconds-15)end end)
 task.spawn(function()
  for _=1,100 do
   for _,p in Players:GetPlayers()do if Runtime.Ready(p)then S.RefreshKing();return end end
   task.wait(.1)
  end
 end)
 require(script.Parent.LeaderboardService).Start()
 print('DOGROTS_COMMUNITY_READY')
end
return S
