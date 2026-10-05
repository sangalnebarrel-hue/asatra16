-- Shared clock/easing keeps the world drum and personal prize strip in sync.
local Config=require(script.Parent.RewardMachineConfig)
local M={Duration=6.2,Turns=6,PrizeCount=#Config.Rewards}
function M.Progress(t)
 t=math.clamp(t,0,1)
 -- Immediate launch, then a long smooth brake. The old curve spent the first
 -- ~1.4 seconds easing in, which made a successful activation look stalled.
 return 1-(1-t)^2.25
end
function M.Target(index)return (-(index-1)*math.pi*2/M.PrizeCount)%(math.pi*2)end
function M.Angle(start,index,t)return start+(math.pi*2*M.Turns+(M.Target(index)-start)%(math.pi*2))*M.Progress(t)end
M.Colors={Common=Color3.fromRGB(44,201,255),Rare=Color3.fromRGB(52,113,255),Epic=Color3.fromRGB(174,56,255),Legendary=Color3.fromRGB(255,181,22),Mythic=Color3.fromRGB(255,46,122),Secret=Color3.fromRGB(36,255,170),Treasure=Color3.fromRGB(255,184,23),Artifact=Color3.fromRGB(186,61,255),Coins=Color3.fromRGB(255,202,28),Boost=Color3.fromRGB(108,245,41)}
function M.Rarity(result)return result.Rarity or (result.Kind=='Cash'and 'Coins'or result.Kind=='Boost'and 'Boost'or 'Common')end
function M.Color(result)return M.Colors[M.Rarity(result)]or M.Colors.Common end
function M.UltraRare(result)return result.Jackpot==true or result.Id=='Aurion'or(result.Dog and result.Dog.DogId=='Aurion')or result.Name=='Aurion'end
return M
