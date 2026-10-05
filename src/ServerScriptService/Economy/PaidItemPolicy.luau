-- Consult Roblox before a paid-random asset enters a player-to-player transfer.
local Players=game:GetService('Players');local Policy=game:GetService('PolicyService')
local P={Cache={}}
function P.Allowed(user)
 local old=P.Cache[user];if old and os.clock()-old.At<60 then return old.Allowed end
 local player=Players:GetPlayerByUserId(user);if not player then return false end
 local ok,value=pcall(function()return Policy:GetPolicyInfoForPlayerAsync(player)end)
 local allowed=ok and value.IsPaidItemTradingAllowed==true
 P.Cache[user]={At=os.clock(),Allowed=allowed};return allowed
end
Players.PlayerRemoving:Connect(function(player)P.Cache[player.UserId]=nil end)
return P
