local Players=game:GetService('Players')
local Replicated=game:GetService('ReplicatedStorage')
local Runtime=require(script.Parent.Runtime)
local Definitions=require(script.Parent.DogDefinitions)
local ShopAccess=require(script.Parent.ShopInteriorAccess)
local World={}
function World.TryOpenShop(player,shop)
 return ShopAccess.Open(player,shop,Runtime,Replicated.DogEconomyOpen)
end
function World.Start()
 require(script.Parent.PlotDevelopment).Start()
 require(script.Parent.LabService).Start()
 require(script.Parent.MuseumService).Start()
 local map=workspace:WaitForChild('DOGROTS_District')
 local interactions=Instance.new('Folder');interactions.Name='EconomyInteractions';interactions.Parent=map
 local Routing=require(Replicated:WaitForChild('MapRouting'))
 local targets={
 {'DOGDEX','DogDex',map['06_DogDexMuseum'].NavigationAndReception.InteractionAnchor},
 {'GLOBAL DIG','Events',Routing.Anchor('GlobalDigSite')}, {'COLLECTION','Collection',map['06_DogDexMuseum'].NavigationAndReception.CollectionAnchor},
 {'DIGGING LAYERS','Layers',Routing.Anchor('PortalRuins')},
 }
 local shops=map:WaitForChild('11_Shops');local points=shops:WaitForChild('InteractionAnchors')
 table.insert(targets,{'MARKETPLACE','Marketplace',points.Marketplace})
 -- Ordinary loot and unique finds are sold at the collector in the owner's yard.
 for _,key in ipairs({'UPGRADES','COSMETICS','SUPPLIES'})do table.insert(targets,{key,key:sub(1,1)..key:sub(2):lower(),shops[key].InteractionAnchor,nil,shops[key]})end
 for _,row in ipairs(targets)do
  local anchor=Instance.new('Part');anchor.Name=row[1];anchor.Size=Vector3.one;anchor.Anchored=true;anchor.CanCollide=false;anchor.CanTouch=false;anchor.CanQuery=false;anchor.Transparency=1;local target=row[3];if not target then anchor:Destroy();continue end;local offset=CFrame.new(row[4]or Vector3.zero);anchor.CFrame=target.CFrame*offset;anchor.Parent=target.Parent
  target:GetPropertyChangedSignal('CFrame'):Connect(function()anchor.CFrame=target.CFrame*offset end)
  local prompt=Instance.new('ProximityPrompt');prompt.ActionText='OPEN';prompt.ObjectText=row[1];prompt.MaxActivationDistance=14;prompt.RequiresLineOfSight=false;prompt.Parent=anchor
  if row[5]then
   prompt.Name='ShopTerminalPrompt';prompt.ActionText='OPEN '..row[1];prompt.ObjectText='SERVICE TERMINAL';prompt.MaxActivationDistance=ShopAccess.Distance;prompt.RequiresLineOfSight=true
   prompt:SetAttribute('ShopInteriorPrompt',true)
   prompt.Triggered:Connect(function(player)World.TryOpenShop(player,row[5])end)
  else
   prompt.Triggered:Connect(function(player)
    local root=player.Character and player.Character:FindFirstChild('HumanoidRootPart')
    if Runtime.Ready(player) and root and (root.Position-anchor.Position).Magnitude<=18 and Runtime.Allow(player,1) then Replicated.DogEconomyOpen:FireClient(player,row[2])end
   end)
  end
 end
end
return World
