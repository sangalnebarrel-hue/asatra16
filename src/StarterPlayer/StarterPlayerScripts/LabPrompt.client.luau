local player=game.Players.LocalPlayer;local Access=require(game.ReplicatedStorage.LabAccess)
local elapsed=0
game:GetService('RunService').Heartbeat:Connect(function(dt)
 elapsed+=dt;if elapsed<.15 then return end;elapsed=0
 local lab=Access.Model();local anchor=lab and lab:FindFirstChild('InteractionAnchor');local prompt=anchor and anchor:FindFirstChild('GeneticsPrompt')
 if prompt then prompt.Enabled=Access.CanUse(player)end
end)
