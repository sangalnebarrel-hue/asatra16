-- Whitelisted travel through the existing economy request channel and world anchors.
local Players=game:GetService('Players')
local RS=game:GetService('ReplicatedStorage')
local Routing=require(RS.MapRouting)
local S={Last={}}
local destinations={Lab={Key='MutationLab',Building='05_MutationLab'},Museum={Key='DogDex',Building='06_DogDexMuseum'}}
function S.Request(player,args)
 if type(args)~='table'or type(args.Destination)~='string'then return false,'Choose a destination'end
 for key in pairs(args)do if key~='Destination'then return false,'Invalid travel request'end end
 local spec=destinations[args.Destination];if not spec then return false,'Unknown destination'end
 local now=os.clock();if now-(S.Last[player.UserId]or -10)<2 then return false,'Please wait before traveling again'end
 S.Last[player.UserId]=now
 local character=player.Character;local humanoid=character and character:FindFirstChildOfClass('Humanoid')
 local root=character and character:FindFirstChild('HumanoidRootPart')
 if not root or not humanoid or humanoid.Health<=0 or root.Anchored or not character:IsDescendantOf(workspace)then return false,'Wait for your character'end
 if humanoid.SeatPart then return false,'Leave your seat before traveling'end
 local map=workspace:FindFirstChild('DOGROTS_District');local building=map and map:FindFirstChild(spec.Building)
 local marker=Routing.Anchor(spec.Key)
 if not building or not marker or not marker:IsA('BasePart')or not marker:IsDescendantOf(building)then return false,'Entrance unavailable'end
 local box,size=character:GetBoundingBox();local relative=root.CFrame:ToObjectSpace(box)
 local ray=RaycastParams.new();ray.FilterType=Enum.RaycastFilterType.Exclude;ray.FilterDescendantsInstances={character};ray.RespectCanCollide=true;ray.IgnoreWater=true
 local overlap=OverlapParams.new();overlap.FilterType=Enum.RaycastFilterType.Exclude;overlap.FilterDescendantsInstances={character};overlap.RespectCanCollide=true
 ray.CollisionGroup=root.CollisionGroup;overlap.CollisionGroup=root.CollisionGroup
 local forward=marker.CFrame.LookVector*Vector3.new(1,0,1);if forward.Magnitude<.1 then forward=Vector3.new(0,0,-1)end
 for _,offset in ipairs({Vector3.zero,Vector3.new(-3,0,0),Vector3.new(3,0,0),Vector3.new(0,0,3),Vector3.new(0,0,-3)})do
  local point=marker.CFrame:PointToWorldSpace(offset)
  local floor=workspace:Raycast(point+Vector3.new(0,8,0),Vector3.new(0,-32,0),ray)
  if floor and floor.Normal.Y>.7 then
   local position=Vector3.new(point.X,floor.Position.Y+size.Y/2-relative.Position.Y+.25,point.Z)
   local arrival=CFrame.lookAt(position,position+forward)
   local obstruction=workspace:GetPartBoundsInBox(arrival*relative,size,overlap)
   if #obstruction==0 and player.Character==character then
    character:PivotTo(arrival*root.CFrame:Inverse()*character:GetPivot())
    root.AssemblyLinearVelocity=Vector3.zero;root.AssemblyAngularVelocity=Vector3.zero
    return true,{Destination=args.Destination,Message='Arrived at '..args.Destination}
   end
  end
 end
 return false,'Entrance is blocked. Please try again.'
end
Players.PlayerRemoving:Connect(function(player)S.Last[player.UserId]=nil end)
return S
