-- Recover characters after an accidental fall off a floating island.
local Players=game:GetService("Players")
local Run=game:GetService("RunService")
local spawnPoint=workspace:WaitForChild("DistrictSpawn")
local cooldown={}
Players.PlayerRemoving:Connect(function(p) cooldown[p]=nil end)
local elapsed=0
Run.Heartbeat:Connect(function(dt)
 elapsed+=dt;if elapsed<0.25 then return end;elapsed=0
 for _,player in Players:GetPlayers() do
  local char=player.Character
  local root=char and char:FindFirstChild("HumanoidRootPart")
  local hum=char and char:FindFirstChildOfClass("Humanoid")
  if root and hum and hum.Health>0 and root.Position.Y < -85 and os.clock()-(cooldown[player] or -10)>3 then
   cooldown[player]=os.clock()
   local destination=player.RespawnLocation or spawnPoint
   char:PivotTo(destination.CFrame+Vector3.new(0,5,0))
   root.AssemblyLinearVelocity=Vector3.zero;root.AssemblyAngularVelocity=Vector3.zero
  end
 end
end)
print("DOGROTS_FALL_RECOVERY_READY")

