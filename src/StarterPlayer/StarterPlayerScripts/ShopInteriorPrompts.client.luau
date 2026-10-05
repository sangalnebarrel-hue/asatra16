-- A client visibility gate complements, but never replaces, the server volume check.
local Players=game:GetService('Players');local Run=game:GetService('RunService')
local player=Players.LocalPlayer;local shops=workspace:WaitForChild('DOGROTS_District'):WaitForChild('11_Shops')
local prompts={};local elapsed=0
local function register(o)
 if o:IsA('ProximityPrompt')and o:GetAttribute('ShopInteriorPrompt')then prompts[o]=true;o.Enabled=false end
end
for _,o in shops:GetDescendants()do register(o)end
shops.DescendantAdded:Connect(function(o)task.defer(function()if o.Parent then register(o)end end)end)
Run.Heartbeat:Connect(function(dt)
 elapsed+=dt;if elapsed<.1 then return end;elapsed=0
 local char=player.Character;local root=char and char:FindFirstChild('HumanoidRootPart');local hum=char and char:FindFirstChildOfClass('Humanoid')
 for prompt in pairs(prompts)do
  if not prompt:IsDescendantOf(shops)then prompts[prompt]=nil;continue end
  local shop=prompt.Parent and prompt.Parent.Parent;local zone=shop and shop:FindFirstChild('ShopInteriorZone')
  local enabled=false
  if root and hum and hum.Health>0 and zone and zone:IsA('BasePart')then
   local p=zone.CFrame:PointToObjectSpace(root.Position);local h=zone.Size*.5
   enabled=math.abs(p.X)<=h.X and math.abs(p.Y)<=h.Y and math.abs(p.Z)<=h.Z
    and(root.Position-prompt.Parent.Position).Magnitude<=prompt.MaxActivationDistance
  end
  prompt.Enabled=enabled
 end
end)
