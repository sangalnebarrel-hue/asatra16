-- The server creates static reward visuals. Only nearby clients spend light/particle/animation work.
local Players=game:GetService('Players');local Run=game:GetService('RunService');local rows={};local player=Players.LocalPlayer
local function add(m)
 if not m:IsA('Model')or not m:GetAttribute('LuckyVisual')or rows[m]then return end
 local row={Emitters={},Lights={},Shards={},Rank=m:GetAttribute('LuckyRank')or 1};rows[m]=row
 task.defer(function()
  if not m.Parent then rows[m]=nil;return end
  for _,p in m:GetDescendants()do
   if p:IsA('ParticleEmitter')then table.insert(row.Emitters,{p,p.Rate})
   elseif p:IsA('PointLight')then table.insert(row.Lights,p)
   elseif p:IsA('BasePart')and p:GetAttribute('LuckyFloat')then table.insert(row.Shards,{p,m:GetPivot():ToObjectSpace(p.CFrame),p:GetAttribute('LuckyFloat')})end
  end
 end)
end
for _,p in workspace:GetDescendants()do add(p)end
workspace.DescendantAdded:Connect(add)
local elapsed=0
Run.Heartbeat:Connect(function(dt)
 elapsed+=dt;if elapsed<.1 then return end;elapsed=0
 local camera=workspace.CurrentCamera;if not camera then return end
 local choice=player:GetAttribute('WorldEventFX');local low=choice=='Low'or(choice==nil and game:GetService('UserInputService').TouchEnabled)or player:GetAttribute('LowFX')==true or player:GetAttribute('ReducedMotion')==true
 local t=workspace:GetServerTimeNow()
 for m,row in pairs(rows)do
  if not m:IsDescendantOf(workspace)then rows[m]=nil;continue end
  local pivot=m:GetPivot();local near=(camera.CFrame.Position-pivot.Position).Magnitude<(low and 55 or 120)
  for _,e in row.Emitters do if e[1].Parent then e[1].Enabled=near and not low;e[1].Rate=math.min(6,e[2])end end
  for _,l in row.Lights do if l.Parent then l.Enabled=near and not low end end
  if near and m:GetAttribute('BlockState')~='Carried'then for _,s in row.Shards do if s[1].Parent then s[1].CFrame=pivot*s[2]*CFrame.new(0,low and 0 or math.sin(t*1.3+s[3])*.27,0)end end end
 end
end)
