-- Cosmetic animation stays on the client and is distance capped.
local Run=game:GetService('RunService');local yards=workspace:WaitForChild('DOGROTS_District'):WaitForChild('04_PlayerYards')
local active={};local mists={};local tick=0
local function register(p)
 if p:IsA('BasePart')and p:GetAttribute('PlotFloat')then active[p]={Base=p.CFrame,Phase=p.Position.X*.17+p.Position.Z*.13}end
 if p:IsA('ParticleEmitter')and p:GetAttribute('PlotMist')then mists[p]=true end
end
for _,p in ipairs(yards:GetDescendants())do register(p)end
yards.DescendantAdded:Connect(function(p)task.defer(function()if p.Parent then register(p)end end)end)
Run.Heartbeat:Connect(function(dt)
 tick+=dt;if tick<1/30 then return end;tick=0
 local camera=workspace.CurrentCamera;if not camera then return end
 local now=os.clock()
 for p in pairs(mists)do
  if not p:IsDescendantOf(yards)then mists[p]=nil
  else p.Enabled=(camera.CFrame.Position-p.Parent.Position).Magnitude<180 end
 end
 for p,data in pairs(active)do
  if not p:IsDescendantOf(yards)then active[p]=nil
  elseif(camera.CFrame.Position-data.Base.Position).Magnitude<230 then p.CFrame=data.Base+Vector3.new(0,math.sin(now*.75+data.Phase)*.38,0)end
 end
end)
