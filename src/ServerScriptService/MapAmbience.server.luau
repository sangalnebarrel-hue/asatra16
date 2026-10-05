local Players=game:GetService("Players")
local folder=workspace:WaitForChild("DOGROTS_District"):WaitForChild("04_PlayerYards")
local Allocator=require(script.Parent:WaitForChild("YardAllocator"))
local allocation=Allocator.new({4,8,3,7,2,6,1,5})
local yards={};local waiting={};local registered={}

-- Owner billboard settings.
-- Use the actual Yard bounding-box center for X/Z instead of Model:GetPivot(),
-- because a model pivot can be offset from the visual center of the Yard.
-- Height is 1.5x the previous 18-stud offset.
local OWNER_BILLBOARD_HEIGHT=27
local OWNER_BILLBOARD_MAX_DISTANCE=400

local function ensureOwnerBillboard(yard)
 local anchor=yard:FindFirstChild("OwnerBillboardAnchor")
 if not anchor then
  -- At this point the billboard anchor does not exist yet, so GetBoundingBox()
  -- measures only the Yard itself and gives us its true horizontal center.
  local boundsCFrame=yard:GetBoundingBox()
  local pivotY=yard:GetPivot().Position.Y
  local yardCenter=Vector3.new(boundsCFrame.Position.X,pivotY,boundsCFrame.Position.Z)

  anchor=Instance.new("Part")
  anchor.Name="OwnerBillboardAnchor"
  anchor.Size=Vector3.new(1,1,1)
  anchor.Anchored=true
  anchor.CanCollide=false
  anchor.CanTouch=false
  anchor.CanQuery=false
  anchor.CastShadow=false
  anchor.Transparency=1
  anchor.CFrame=CFrame.new(yardCenter+Vector3.new(0,OWNER_BILLBOARD_HEIGHT,0))
  anchor.Parent=yard
 end

 local billboard=anchor:FindFirstChild("OwnerBillboard")
 if not billboard then
  billboard=Instance.new("BillboardGui")
  billboard.Name="OwnerBillboard"
  billboard.Adornee=anchor
  billboard.Size=UDim2.fromOffset(230,118)
  billboard.StudsOffset=Vector3.zero
  billboard.AlwaysOnTop=true
  billboard.LightInfluence=0
  billboard.MaxDistance=OWNER_BILLBOARD_MAX_DISTANCE
  billboard.Enabled=false
  billboard.Parent=anchor

  local avatar=Instance.new("ImageLabel")
  avatar.Name="Avatar"
  avatar.AnchorPoint=Vector2.new(.5,0)
  avatar.Position=UDim2.new(.5,0,0,0)
  avatar.Size=UDim2.fromOffset(76,76)
  avatar.BackgroundColor3=Color3.fromRGB(20,24,31)
  avatar.BorderSizePixel=0
  avatar.ScaleType=Enum.ScaleType.Crop
  avatar.Parent=billboard

  local avatarCorner=Instance.new("UICorner")
  avatarCorner.CornerRadius=UDim.new(1,0)
  avatarCorner.Parent=avatar

  local avatarStroke=Instance.new("UIStroke")
  avatarStroke.Thickness=4
  avatarStroke.Color=Color3.fromRGB(12,14,18)
  avatarStroke.Parent=avatar

  local name=Instance.new("TextLabel")
  name.Name="Username"
  name.AnchorPoint=Vector2.new(.5,0)
  name.Position=UDim2.new(.5,0,0,78)
  name.Size=UDim2.new(1,0,0,34)
  name.BackgroundTransparency=1
  name.Font=Enum.Font.GothamBold
  name.Text=""
  name.TextColor3=Color3.new(1,1,1)
  name.TextSize=24
  name.TextScaled=false
  name.TextStrokeColor3=Color3.fromRGB(20,20,20)
  name.TextStrokeTransparency=0
  name.TextXAlignment=Enum.TextXAlignment.Center
  name.Parent=billboard
 end
 return billboard
end

local function clearOwnerBillboard(yard)
 local billboard=ensureOwnerBillboard(yard)
 billboard.Enabled=false
 local avatar=billboard:FindFirstChild("Avatar")
 local name=billboard:FindFirstChild("Username")
 if avatar then avatar.Image="" end
 if name then name.Text="" end
end

local function updateOwnerBillboard(yard,player)
 local billboard=ensureOwnerBillboard(yard)
 local avatar=billboard:FindFirstChild("Avatar")
 local name=billboard:FindFirstChild("Username")
 if name then name.Text=player.Name end
 if avatar then avatar.Image="" end
 billboard.Enabled=true

 -- Thumbnail loading can yield, so do it asynchronously and verify that the
 -- same player still owns this Yard before applying the image.
 task.spawn(function()
  local ok,image=pcall(function()
   return Players:GetUserThumbnailAsync(player.UserId,Enum.ThumbnailType.HeadShot,Enum.ThumbnailSize.Size420x420)
  end)
  if ok and image and yard.Parent and yard:GetAttribute("OwnerUserId")==player.UserId then
   local current=ensureOwnerBillboard(yard):FindFirstChild("Avatar")
   if current then current.Image=image end
  end
 end)
end

for _,yard in folder:GetChildren() do
 local id=yard:GetAttribute("YardId")
 if id then
  yards[id]=yard
  yard:SetAttribute("OwnerUserId",0)
  yard:SetAttribute("OwnerDisplayName","")
  ensureOwnerBillboard(yard)
  clearOwnerBillboard(yard)
 end
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
 updateOwnerBillboard(yard,player)
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
  yards[id]:SetAttribute("OwnerUserId",0);yards[id]:SetAttribute("OwnerDisplayName","")
  updateSign(yards[id],"AVAILABLE")
  clearOwnerBillboard(yards[id])
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
print("DOGROTS_YARDS_READY: 8 exclusive session yards + centered owner billboards")

