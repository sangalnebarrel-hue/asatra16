local Run=game:GetService('RunService');local Players=game:GetService('Players');local PPS=game:GetService('ProximityPromptService');local Sound=require(game.ReplicatedStorage.WorldSound)
local player=Players.LocalPlayer;local rows={};local elapsed=0
PPS.PromptTriggered:Connect(function(prompt)
 if prompt.Name~='PlaceLuckyBlock'or prompt.ActionText~='OPEN BLOCK'then return end
 local pad=prompt.Parent;local uid=pad and pad:GetAttribute('LuckyBlockUid')
 if type(uid)=='string'and uid~=''then player:SetAttribute('LuckyBlockOpeningUid',uid);player:SetAttribute('LuckyBlockOpeningAt',workspace:GetServerTimeNow())end
end)
local function watch(m)
 if not m:IsA('Model')or not m:GetAttribute('OwnedBlockUid')or rows[m]then return end
 rows[m]={Parts={},Phase=0}
end
for _,m in workspace:GetDescendants()do watch(m)end;workspace.DescendantAdded:Connect(watch)
Run.Heartbeat:Connect(function(dt)
 elapsed+=dt;if elapsed<.12 then return end;elapsed=0
 local camera=workspace.CurrentCamera;if not camera then return end
 local now=workspace:GetServerTimeNow();local low=player:GetAttribute('ReducedMotion')or player:GetAttribute('WorldEventFX')=='Low'or game:GetService('UserInputService').TouchEnabled
 for m,row in pairs(rows)do
  if not m.Parent then rows[m]=nil;continue end
  local ready=m:GetAttribute('ReadyAt');local placed=m:GetAttribute('PlacedAt');local state=m:GetAttribute('BlockState');local text=m:FindFirstChild('TimerText',true)
  local pendingUid=player:GetAttribute('LuckyBlockOpeningUid');local pendingAt=tonumber(player:GetAttribute('LuckyBlockOpeningAt'))or 0
  local predicted=pendingUid==m:GetAttribute('OwnedBlockUid')and pendingAt>0 and now-pendingAt<6
  local progress=ready and math.clamp((now-placed)/math.max(1,ready-placed),0,1)or 0
  if text then text.Text=predicted and 'OPENING…'or state=='Carried'and 'CARRY TO YOUR YARD'or state=='Opened'and 'GOOD FIND!'or m:GetAttribute('OpenMessage')or (state=='Ready'or ready and ready<=now)and 'READY · PRESS E TO OPEN'or ('PREPARING · '..math.max(0,math.ceil((ready or now)-now))..'s')end
  if predicted and not row.Predicted then row.Predicted=true;Sound.Cue('Crack',m.PrimaryPart)elseif not predicted then row.Predicted=nil end
  local near=(camera.CFrame.Position-m:GetPivot().Position).Magnitude<100
  if near and (state=='Placed'or state=='Ready')then
   local phase=math.floor(progress*4)
   if phase>=2 and not row.Cracks then
    row.Cracks={};local scale=m:GetScale()
    for face=0,(low and 1 or 3)do for i=1,3 do
     local crack=Instance.new('Part');crack.Name='OpeningCrackFX';crack.Anchored=true;crack.CanCollide=false;crack.CanTouch=false;crack.CanQuery=false;crack.CastShadow=false
     crack.Material=Enum.Material.Neon;crack.Color=Color3.fromRGB(255,216,123);crack.Size=Vector3.new(.06,1.1,.035)*scale
     crack.CFrame=m:GetPivot()*CFrame.Angles(0,face*math.pi/2,0)*CFrame.new((i%2)*.3*scale,(i-2)*.85*scale,-2.86*scale)*CFrame.Angles(0,0,i%2==0 and -.4 or .4)
     crack.Parent=m;table.insert(row.Cracks,crack)
    end end
   end
   if row.Cracks then for _,crack in row.Cracks do crack.Transparency=math.clamp(1-progress,0,.8)end end
   if phase>row.Phase then row.Phase=phase;if m:GetAttribute('OwnerUserId')==player.UserId then Sound.Cue('Crack',m.PrimaryPart)end end
   for _,p in m:GetDescendants()do if p:IsA('BasePart')and (p.Name=='InsetPanel'or p.Name=='Lid')then
    row.Parts[p]=row.Parts[p]or {CFrame=p.CFrame,Color=p.Color}
    local original=row.Parts[p];p.Color=original.Color:Lerp(Color3.fromRGB(255,220,146),math.max(0,progress-.55)*.8)
    if not low and(state=='Placed'or state=='Ready')and p.Name=='Lid'then local shake=predicted and math.sin(now*48)*.14 or math.sin(now*12)*progress*.035;p.CFrame=original.CFrame*CFrame.new(0,math.max(0,progress-.85)*2+shake,0)end
   end end
  elseif state=='Opened'and not row.Opened then
   row.Opened=true;Sound.Cue('Open',m.PrimaryPart)
   for _,p in m:GetDescendants()do if p:IsA('BasePart')then game:GetService('TweenService'):Create(p,TweenInfo.new(.45),{Transparency=1,Size=p.Size*.3}):Play()end end
  end
 end
end)
