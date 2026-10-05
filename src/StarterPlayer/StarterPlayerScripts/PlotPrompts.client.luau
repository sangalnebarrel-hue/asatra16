local Player=game.Players.LocalPlayer
local Access=require(game.ReplicatedStorage.PlotInteractionAccess)
local tracked={};local map=workspace:WaitForChild('DOGROTS_District'):WaitForChild('04_PlayerYards')
local function track(o)
 if o:IsA('ProximityPrompt')and o.Name=='YardInteraction'then
  local yard=o.Parent;while yard and yard.Parent~=map do yard=yard.Parent end
  if yard then tracked[o]=yard end
 end
end
for _,o in map:GetDescendants()do track(o)end;map.DescendantAdded:Connect(track)
local elapsed=0
game:GetService('RunService').Heartbeat:Connect(function(dt)
 elapsed+=dt;if elapsed<.15 then return end;elapsed=0
 for prompt,yard in pairs(tracked)do
  if not prompt.Parent then tracked[prompt]=nil else prompt.Enabled=Access.CanUse(Player,yard,prompt.Parent)end
 end
end)
