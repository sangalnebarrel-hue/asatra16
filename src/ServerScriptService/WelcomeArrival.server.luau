-- Arrival placement is scoped to DistrictSpawn; the yard allocation/economy stay independent.
local Players=game:GetService('Players')
local Physics=game:GetService('PhysicsService')
local Run=game:GetService('RunService')
local spawnPoint=workspace:WaitForChild('DistrictSpawn')
local group='WelcomeArrival'
if not Physics:IsCollisionGroupRegistered(group) then Physics:RegisterCollisionGroup(group) end
Physics:CollisionGroupSetCollidable(group,group,false)
local slots={Vector3.zero}
for i=0,7 do local a=i*math.pi/4;table.insert(slots,Vector3.new(math.cos(a)*5.8,0,math.sin(a)*5.8)) end
local function arrive(player,character)
 local root=character:WaitForChild('HumanoidRootPart',15)
 local humanoid=character:WaitForChild('Humanoid',15)
 if not root or not humanoid or player.Character~=character then return end
 if player.RespawnLocation and player.RespawnLocation~=spawnPoint then return end
 -- CharacterAdded can run before Roblox finishes parenting/scaling/placing the avatar.
 local deadline=os.clock()+12
 while player.Character==character and os.clock()<deadline and (not character:IsDescendantOf(workspace)or not player:HasAppearanceLoaded()) do Run.Heartbeat:Wait() end
 Run.Heartbeat:Wait()
 if player.Character~=character or not character:IsDescendantOf(workspace)then return end
 local point=spawnPoint.Position
 local best,bestDistance=slots[1],-1
 for _,offset in ipairs(slots) do
  local distance=math.huge
  for _,other in ipairs(Players:GetPlayers()) do
   local otherRoot=other~=player and other.Character and other.Character:FindFirstChild('HumanoidRootPart')
   if otherRoot then distance=math.min(distance,((point+offset-otherRoot.Position)*Vector3.new(1,0,1)).Magnitude) end
  end
  if distance>bestDistance then best,bestDistance=offset,distance end
 end
 local y=(spawnPoint:GetAttribute('SurfaceY')or .71)+humanoid.HipHeight+root.Size.Y/2+.15
 if humanoid.RigType==Enum.HumanoidRigType.R6 then y+=2 end
 local pos=Vector3.new(point.X,y,point.Z)+best
 local direction=spawnPoint:GetAttribute('ArrivalDirection')or Vector3.new(0,0,-1)
 local arrival=CFrame.lookAt(pos,pos+direction)
 character:PivotTo(arrival*root.CFrame:Inverse()*character:GetPivot())
 root.AssemblyLinearVelocity=Vector3.zero;root.AssemblyAngularVelocity=Vector3.zero
 -- Temporary arrival-only overlap protection, including late-loaded avatar accessories.
 local originals={}
 local function protect(part)
  if part:IsA('BasePart') then originals[part]=part.CollisionGroup;part.CollisionGroup=group end
 end
 for _,part in ipairs(character:GetDescendants()) do protect(part) end
 local added=character.DescendantAdded:Connect(protect)
 character:SetAttribute('WelcomeArrivalCFrame',arrival)
 character:SetAttribute('WelcomeArrivalReady',true)
 local started=os.clock()
 repeat Run.Heartbeat:Wait() until not character.Parent or humanoid.Health<=0 or os.clock()-started>8 or ((root.Position-point)*Vector3.new(1,0,1)).Magnitude>12
 added:Disconnect()
 for part,previous in pairs(originals) do if part.Parent and part.CollisionGroup==group then part.CollisionGroup=previous end end
end
local function connect(player)
 player.CharacterAdded:Connect(function(character)task.spawn(arrive,player,character)end)
 if player.Character then task.spawn(arrive,player,player.Character) end
end
Players.PlayerAdded:Connect(connect)
for _,player in ipairs(Players:GetPlayers()) do connect(player) end
