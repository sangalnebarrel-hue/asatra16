local Players=game:GetService("Players")
local folder=workspace:WaitForChild("DOGROTS_District"):WaitForChild("04_PlayerYards")
local Allocator=require(script.Parent:WaitForChild("YardAllocator"))
local allocation=Allocator.new({4,8,3,7,2,6,1,5})
local yards={};local waiting={};local registered={}
for _,yard in folder:GetChildren() do
 local id=yard:GetAttribute("YardId")
 if id then yards[id]=yard;yard:SetAttribute("OwnerUserId",0);yard:SetAttribute("OwnerDisplayName","") end
end
local function updateSign(yard,label)
 local p=yard:FindFirstChild("OwnerPlaque")
 local t=p and p:FindFirstChild("OwnerText",true)
 if t then t.Text=label end
end
local function assign(player,moveExisting)
 if not player.Parent then return false end
 local id=allocation:Claim(player.UserId)
 if not id then
  player:SetAttribute("WaitingForYard",true)
  player.RespawnLocation=workspace:FindFirstChild("DistrictSpawn")
  return false
 end
 local yard=yards[id];local spawn=yard:FindFirstChild("YardSpawn")
 yard:SetAttribute("OwnerUserId",player.UserId);yard:SetAttribute("OwnerDisplayName",player.DisplayName)
 player:SetAttribute("YardId",id);player:SetAttribute("YardSpawnPosition",spawn.Position)
 player:SetAttribute("WaitingForYard",false);player.RespawnLocation=workspace:WaitForChild("DistrictSpawn")
 updateSign(yard,player.DisplayName)

 return true
end
local function added(player)
 if registered[player] then return end;registered[player]=true
 if not assign(player,false) then table.insert(waiting,player) end

end
Players.PlayerAdded:Connect(added)
Players.PlayerRemoving:Connect(function(player)
 registered[player]=nil
 for i=#waiting,1,-1 do if waiting[i]==player then table.remove(waiting,i) end end
 local id=allocation:Release(player.UserId)
 if id and yards[id] then
  yards[id]:SetAttribute("OwnerUserId",0);yards[id]:SetAttribute("OwnerDisplayName","");updateSign(yards[id],"AVAILABLE")
 end
 while id and #waiting>0 do
  local nextPlayer=table.remove(waiting,1)
  if nextPlayer.Parent==Players then
   if not assign(nextPlayer,true) then table.insert(waiting,1,nextPlayer) end
   break
  end
 end
end)
for _,player in Players:GetPlayers() do added(player) end
print("DOGROTS_YARDS_READY: 8 exclusive session yards")

