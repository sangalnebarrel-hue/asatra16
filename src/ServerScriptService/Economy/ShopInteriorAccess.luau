-- Authoritative entry policy for the three existing service-shop UI routes.
local Players=game:GetService('Players')
local A={Distance=7,Routes={UPGRADES='Upgrades',COSMETICS='Cosmetics',SUPPLIES='Supplies'}}
function A.Contains(zone,position)
 if not zone or not zone:IsA('BasePart')then return false end
 local q=zone.CFrame:PointToObjectSpace(position);local h=zone.Size*.5
 return math.abs(q.X)<=h.X and math.abs(q.Y)<=h.Y and math.abs(q.Z)<=h.Z
end
function A.Eligible(player,shop)
 local map=workspace:FindFirstChild('DOGROTS_District');local shops=map and map:FindFirstChild('11_Shops')
 if not shop or shop.Parent~=shops or shops:FindFirstChild(shop.Name)~=shop or not A.Routes[shop.Name]then return false end
 if not player or player.Parent~=Players then return false end
 local character=player.Character;local root=character and character:FindFirstChild('HumanoidRootPart');local hum=character and character:FindFirstChildOfClass('Humanoid')
 local target=shop:FindFirstChild('InteractionAnchor');local zone=shop:FindFirstChild('ShopInteriorZone')
 if not root or not hum or hum.Health<=0 or not target or not target:IsA('BasePart')or not A.Contains(zone,root.Position)then return false end
 if(root.Position-target.Position).Magnitude>A.Distance then return false end
 local params=RaycastParams.new();params.FilterType=Enum.RaycastFilterType.Exclude;params.FilterDescendantsInstances={character};params.RespectCanCollide=true
 if workspace:Raycast(root.Position,target.Position-root.Position,params)then return false end
 return true,A.Routes[shop.Name]
end
function A.Open(player,shop,runtime,event)
 if not runtime.Ready(player)then return false end
 local valid,route=A.Eligible(player,shop);if not valid or not runtime.Allow(player,1)then return false end
 event:FireClient(player,route);return true
end
return A
