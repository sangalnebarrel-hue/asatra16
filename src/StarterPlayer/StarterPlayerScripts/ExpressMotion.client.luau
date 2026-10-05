local root=workspace:WaitForChild('DOGROTS_District'):WaitForChild('33_DogExpress')
local Run=game:GetService('RunService');local Players=game:GetService('Players');local arrows={}
local function add(p)if p.Name=='Arrow'and p:IsA('BasePart')then arrows[p]=p.CFrame end end
for _,p in root:GetChildren()do add(p)end
root.ChildAdded:Connect(add);root.ChildRemoved:Connect(function(p)arrows[p]=nil end)
local elapsed=0
Run.Heartbeat:Connect(function(dt)
 elapsed+=dt;if elapsed<.08 then return end;elapsed=0
 local camera=workspace.CurrentCamera;if not camera then return end
 local reduced=Players.LocalPlayer:GetAttribute('WorldEventFX')=='Low'or Players.LocalPlayer:GetAttribute('ReducedMotion')or Players.LocalPlayer:GetAttribute('LowFX')
 local t=reduced and 0 or workspace:GetServerTimeNow()*3%12
 for p,cf in pairs(arrows)do
  if p.Parent and(camera.CFrame.Position-cf.Position).Magnitude<170 then p.CFrame=cf+Vector3.new(0,0,cf.X<0 and t or -t)end
 end
end)
