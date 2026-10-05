-- Read-only museum projection of the existing permanent DogDex profile.
local Players=game:GetService('Players');local Rep=game.ReplicatedStorage
local Runtime=require(script.Parent.Runtime);local Catalog=require(Rep.MuseumCatalog)
local S={};local started=false
function S.State(player)
 if not Runtime.Ready(player)then return nil end
 -- Museum reads the authoritative RAM profile. Runtime.Views is a presentation
 -- cache and can briefly trail a fast-path mint (line purchase / Lucky Block).
 local ok,profile=pcall(function()return Runtime.Engine:Get(player.UserId)end)
 if not ok or not profile then profile=Runtime.Views[player.UserId] end
 if not profile then return nil end
 Runtime.Views[player.UserId]=profile
 return Catalog.State(profile,game.ServerStorage.DogTemplates)
end
function S.Start()
 if started then return end;started=true
 local request=Instance.new('RemoteFunction');request.Name='MuseumRead';request.Parent=Rep
 local changed=Instance.new('RemoteEvent');changed.Name='MuseumChanged';changed.Parent=Rep
 local times={};local previous={}
 request.OnServerInvoke=function(player)
  if os.clock()-(times[player]or -10)<.1 then return nil end
  times[player]=os.clock();return S.State(player)
 end
 local function bind(player)
  local function refresh()
   local state=S.State(player);if not state then return end
   local old=previous[player];previous[player]=state.Count
   changed:FireClient(player,state,old~=nil and state.Count>old)
  end
  player:GetAttributeChangedSignal('EconomyReady'):Connect(function()task.defer(refresh)end)
  player:GetAttributeChangedSignal('DogDexCount'):Connect(function()
   -- Defer one scheduler turn so RAM/profile projection and the attribute land together.
   task.defer(refresh)
  end)
  task.defer(refresh)
 end
 Players.PlayerAdded:Connect(bind);for _,p in Players:GetPlayers()do bind(p)end
 Players.PlayerRemoving:Connect(function(p)times[p]=nil;previous[p]=nil end)
end
return S
