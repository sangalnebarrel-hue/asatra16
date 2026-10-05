local A={Distance=require(game.ReplicatedStorage.LabConfig).Distance}
function A.Model()
 local map=workspace:FindFirstChild('DOGROTS_District');return map and map:FindFirstChild('05_MutationLab')
end
function A.CanUse(player)
 local lab=A.Model();local zone=lab and lab:FindFirstChild('InteriorZone');local target=lab and lab:FindFirstChild('InteractionAnchor')
 local char=player.Character;local hrp=char and char:FindFirstChild('HumanoidRootPart');local hum=char and char:FindFirstChildOfClass('Humanoid')
 if not(zone and target and hrp and hum and hum.Health>0)then return false end
 local p=zone.CFrame:PointToObjectSpace(hrp.Position);local half=zone.Size/2
 if math.abs(p.X)>half.X or math.abs(p.Y)>half.Y or math.abs(p.Z)>half.Z or(hrp.Position-target.Position).Magnitude>A.Distance then return false end
 local origin=char:FindFirstChild('Head')or hrp;local delta=target.Position-origin.Position
 local params=RaycastParams.new();params.FilterType=Enum.RaycastFilterType.Exclude;params.FilterDescendantsInstances={char};params.RespectCanCollide=true
 local hit=workspace:Raycast(origin.Position,delta,params)
 return not hit or(hit.Position-target.Position).Magnitude<.5
end
return A
