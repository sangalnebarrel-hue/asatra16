local Players=game:GetService('Players');local Run=game:GetService('RunService');local StarterPlayer=game:GetService('StarterPlayer')
local S={States={},Modifiers={},Jumps={}};local laneRoot=workspace:WaitForChild('DOGROTS_District'):WaitForChild('33_DogExpress')
function S.Set(player,key,multiplier)
 S.Modifiers[player]=S.Modifiers[player]or {};S.Modifiers[player][key]=multiplier and math.clamp(multiplier,.5,3)or nil
end
-- Jump power multipliers work the same way (world events: bouncy bones, rainbow rift).
function S.SetJump(player,key,multiplier)
 S.Jumps[player]=S.Jumps[player]or {};S.Jumps[player][key]=multiplier and math.clamp(multiplier,.5,3)or nil
end
function S.InLane(position)
 for _,lane in ipairs(laneRoot:GetChildren())do if lane:IsA('BasePart')and lane:GetAttribute('ExpressLane')then
  local p=lane.CFrame:PointToObjectSpace(position);local s=lane.Size/2
  if math.abs(p.X)<=s.X and math.abs(p.Z)<=s.Z and p.Y>=0 and p.Y<=7 then return lane end
 end end
 return nil
end
function S.Update(player)
 local hum=player.Character and player.Character:FindFirstChildOfClass('Humanoid');local root=player.Character and player.Character:FindFirstChild('HumanoidRootPart')
 local state=S.States[player]
 if not hum or not root or hum.Health<=0 then S.States[player]=nil;S.Set(player,'Express',nil);return end
 if not state or state.Humanoid~=hum then state={Humanoid=hum,Base=hum:GetAttribute('BaseWalkSpeed')or 24,Applied=hum.WalkSpeed};S.States[player]=state
 elseif math.abs(hum.WalkSpeed-state.Applied)>.01 then state.Base=hum.WalkSpeed end
 local lane=not hum.Sit and S.InLane(root.Position)
 S.Set(player,'Express',lane and lane:GetAttribute('SpeedMultiplier')or nil)
 local multiplier=1;for _,n in pairs(S.Modifiers[player]or {})do multiplier*=n end
 multiplier=math.clamp(multiplier,.5,3)
 local target=math.clamp((hum:GetAttribute('BaseWalkSpeed')or state.Base)*multiplier,0,72)
 if math.abs(hum.WalkSpeed-target)>.01 then hum.WalkSpeed=target end;state.Applied=target
 local jump=1;for _,n in pairs(S.Jumps[player]or {})do jump*=n end
 jump=math.clamp(jump,.5,3)
 if hum.UseJumpPower then
  local power=(hum:GetAttribute('BaseJumpPower')or StarterPlayer.CharacterJumpPower)*jump
  if math.abs(hum.JumpPower-power)>.01 then hum.JumpPower=power end
 else
  local height=(hum:GetAttribute('BaseJumpHeight')or StarterPlayer.CharacterJumpHeight)*jump*jump
  if math.abs(hum.JumpHeight-height)>.01 then hum.JumpHeight=height end
 end
 player:SetAttribute('OnDogExpress',lane~=nil and lane~=false);player:SetAttribute('ExpressDirection',lane and lane.Name or '')
end
function S.Start()
 local elapsed=0;Run.Heartbeat:Connect(function(dt)elapsed+=dt;if elapsed<.1 then return end;elapsed=0;for _,p in ipairs(Players:GetPlayers())do S.Update(p)end end)
 Players.PlayerRemoving:Connect(function(p)S.States[p]=nil;S.Modifiers[p]=nil;S.Jumps[p]=nil end)
 print('DOGROTS_MOVEMENT_READY')
end
return S
