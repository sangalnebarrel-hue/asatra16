local map=workspace:WaitForChild('DOGROTS_District');local Players=game:GetService('Players');local Run=game:GetService('RunService')
local lights,emitters={},{};local elapsed=0
local function ownedByLucky(p)
 local o=p.Parent
 while o and o~=map do if o:GetAttribute('LuckyVisual')then return true end;o=o.Parent end
 return false
end
local function position(p)
 local o=p.Parent
 if o and o:IsA('Attachment')then return o.WorldPosition end
 return o and o:IsA('BasePart')and o.Position or nil
end
local function add(p)
 -- SecretAura: the persistent Secret dog VFX manage their own budget (SecretAuras).
 if ownedByLucky(p)or p:GetAttribute('MuseumLight')or p:GetAttribute('SecretAura')then return end
 if p:IsA('PointLight')or p:IsA('SpotLight')or p:IsA('SurfaceLight')then lights[p]=true;p.Shadows=false
 elseif p:IsA('ParticleEmitter')then emitters[p]=p.Rate end
end
for _,o in map:GetDescendants()do add(o)end
map.DescendantAdded:Connect(add)
Run.Heartbeat:Connect(function(dt)
 elapsed+=dt;if elapsed<.4 then return end;elapsed=0
 local camera=workspace.CurrentCamera;if not camera then return end
 local player=Players.LocalPlayer;local choice=player:GetAttribute('WorldEventFX');local low=choice=='Low'or(choice==nil and game:GetService('UserInputService').TouchEnabled)or player:GetAttribute('LowFX')or player:GetAttribute('ReducedMotion')
 local event=game.ReplicatedStorage.WorldEvents.State
 local blackout=event:GetAttribute('State')=='ACTIVE'and event:GetAttribute('EventId')=='BLACKOUT'
 local candidates={}
 for p in pairs(lights)do
  if not p:IsDescendantOf(map)then lights[p]=nil;continue end
  local pos=position(p);local d=pos and(pos-camera.CFrame.Position).Magnitude or math.huge
  p.Enabled=false
  local navigation=p.Parent and (p.Parent.Name=='WarmLens'or p.Parent.Name=='PortalEnergy')
  local king=p:GetAttribute('ServerKingLight')==true
  if d<(king and 260 or (low and 85 or 160))and (not blackout or navigation)then table.insert(candidates,{p,d,king})end
 end
 table.sort(candidates,function(a,b)if a[3]~=b[3]then return a[3]end;return a[2]<b[2]end)
 for i=1,math.min(#candidates,low and 8 or 24)do candidates[i][1].Enabled=true end
 local remaining=low and 8 or 50
 for p,rate in pairs(emitters)do
  if not p:IsDescendantOf(map)then emitters[p]=nil;continue end
  local pos=position(p);local near=pos and(pos-camera.CFrame.Position).Magnitude<(low and 90 or 210)
  local amount=near and math.min(rate,low and 2 or 8,remaining)or 0
  p.Rate=amount;p.Enabled=amount>0;remaining-=amount
 end
end)
