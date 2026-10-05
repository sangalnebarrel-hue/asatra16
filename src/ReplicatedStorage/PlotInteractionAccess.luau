local A={Distance=9}
local zones={StorageAnchor='StorageInteractionZone',SellAnchor='SellInteractionZone',UpgradeAnchor='UpgradeInteractionZone'}
function A.CanUse(player,yard,target)
 local root=player.Character and player.Character:FindFirstChild('HumanoidRootPart')
 local hum=player.Character and player.Character:FindFirstChildOfClass('Humanoid')
 if not(target and yard and target:IsDescendantOf(yard)and root and hum and hum.Health>0)then return false end
 if yard:GetAttribute('OwnerUserId')~=player.UserId then return false end
 local zone=yard:FindFirstChild(zones[target.Name]or'')
 if not zone then return false end
 local p=zone.CFrame:PointToObjectSpace(root.Position);local half=zone.Size/2
 return math.abs(p.X)<=half.X and math.abs(p.Y)<=half.Y and math.abs(p.Z)<=half.Z and (root.Position-target.Position).Magnitude<=A.Distance
end
return A
