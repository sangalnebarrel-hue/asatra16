local Players=game:GetService('Players')
local Replicated=game:GetService('ReplicatedStorage')
local Lighting=game:GetService('Lighting')
local Config=require(Replicated.DogEconomy.Config)
local player=Players.LocalPlayer
local map=workspace:WaitForChild('DOGROTS_District')
local colors={Shiny=Color3.fromRGB(220,245,255),Golden=Color3.fromRGB(255,199,54),Corrupted=Color3.fromRGB(184,67,233),Glitched=Color3.fromRGB(40,239,213),Void=Color3.fromRGB(88,41,165)}
local tint=Instance.new('ColorCorrectionEffect');tint.Name='DogrotsLayerTint';tint.Parent=Lighting
local audio=Instance.new('Sound');audio.Name='DogrotsDigFind';audio.SoundId='';audio.Volume=.10;audio.Parent=workspace.CurrentCamera
local function layer()
 local i=player:GetAttribute('CurrentLayer')or 1;local c=Config.Layers[i].Color
 tint.TintColor=Color3.new(1,1,1):Lerp(Color3.fromRGB(c[1],c[2],c[3]),.06)
 audio.PlaybackSpeed=({1,.85,1.2,.65,.45})[i]
end
player:GetAttributeChangedSignal('CurrentLayer'):Connect(layer);layer()
local lastLoot=player:GetAttribute('LootCount')or 0
player:GetAttributeChangedSignal('LootCount'):Connect(function()
 local current=player:GetAttribute('LootCount')or 0
 if current>lastLoot then audio:Play()end;lastLoot=current
end)
local function decorate(dog)
 if not dog:IsA('Model')then return end
 local function update()
  local old=dog:FindFirstChild('EconomyVariant');if old then old:Destroy()end
  local color=colors[dog:GetAttribute('Variant')]
  if color then local h=Instance.new('Highlight');h.Name='EconomyVariant';h.FillColor=color;h.OutlineColor=color;h.FillTransparency=.85;h.OutlineTransparency=.2;h.DepthMode=Enum.HighlightDepthMode.Occluded;h.Parent=dog end
 end
 update();dog:GetAttributeChangedSignal('Variant'):Connect(update)
 local function cosmetic()
  local old=dog:FindFirstChild('EconomyCosmetic');if old then old:Destroy()end
  local name=dog:GetAttribute('EquippedCosmetic')
  local root=dog.PrimaryPart
  if name and name~='' and root then
   local b=Instance.new('BillboardGui');b.Name='EconomyCosmetic';b.Adornee=root;b.StudsOffsetWorldSpace=Vector3.new(0,5.6,0);b.Size=UDim2.fromOffset(170,28);b.MaxDistance=40;b.Parent=dog
   local t=Instance.new('TextLabel');t.Size=UDim2.fromScale(1,1);t.BackgroundColor3=name=='VoidAura' and colors.Void or name=='CyberKennel' and colors.Glitched or colors.Golden
   t.BackgroundTransparency=.2;t.Text=name;t.Font=Enum.Font.GothamBold;t.TextSize=14;t.TextColor3=Color3.new(1,1,1);t.TextStrokeTransparency=.4;t.Parent=b
  end
 end
 cosmetic();dog:GetAttributeChangedSignal('EquippedCosmetic'):Connect(cosmetic)
end
for _,f in ipairs({map:WaitForChild('KennelDogs'),map['03_DogLine']:WaitForChild('ActiveDogs')})do f.ChildAdded:Connect(decorate);for _,dog in ipairs(f:GetChildren())do decorate(dog)end end

-- Findings are cosmetic projections of committed server instances. No client rolls.
local V=require(Replicated.DogEconomy.DiscoveryVisuals)
local Tween=game:GetService('TweenService')
local Debris=game:GetService('Debris')
local playerGui=player:WaitForChild('PlayerGui')
local gui=playerGui:FindFirstChild('ScreenGui')
while not gui do
 local child=playerGui.ChildAdded:Wait()
 if child.Name=='ScreenGui' then gui=child end
end
local banner=Instance.new('TextLabel');banner.Name='DiscoveryToast';banner.AnchorPoint=Vector2.new(.5,0)
banner.Position=UDim2.fromScale(.5,.17);banner.Size=UDim2.fromScale(.55,.115);banner.BackgroundColor3=Color3.fromRGB(32,23,40)
banner.BackgroundTransparency=.12;banner.TextColor3=Color3.fromRGB(255,225,139);banner.TextStrokeTransparency=.5
banner.Font=Enum.Font.GothamBold;banner.TextScaled=true;banner.TextWrapped=true;banner.Visible=false;banner.ZIndex=80;banner.Parent=gui
local corner=Instance.new('UICorner');corner.CornerRadius=UDim.new(0,12);corner.Parent=banner
local constraint=Instance.new('UITextSizeConstraint');constraint.MaxTextSize=24;constraint.MinTextSize=12;constraint.Parent=banner
local token=0;local active={};local recent={}
local function toast(message,seconds)
 if gui:GetAttribute('OpenMenu')then return end
 token+=1;local version=token;banner.Text=message;banner.Visible=true
 task.delay(seconds or 4,function()if version==token then banner.Visible=false end end)
end
gui:GetAttributeChangedSignal('OpenMenu'):Connect(function()if gui:GetAttribute('OpenMenu')then token+=1;banner.Visible=false end end)
Replicated:WaitForChild('DiscoveryReveal').OnClientEvent:Connect(function(x)
 if recent[x.ItemUid]then return end;recent[x.ItemUid]=true;task.delay(60,function()recent[x.ItemUid]=nil end)
 local model=V.Clone(x);if not model then return end
 local spawn=x.LootSpawn
 if type(spawn)~='table'or spawn.OwnerUserId~=player.UserId or typeof(spawn.CFrame)~='CFrame' then model:Destroy();return end
 -- This transform was resolved on the server from the current dog/kennel binding.
 -- Never fall back to the player's character, direction or camera.
 local yard
 for _,candidate in ipairs(map['04_PlayerYards']:GetChildren())do
  if candidate:GetAttribute('YardId')==spawn.YardId and candidate:GetAttribute('OwnerUserId')==player.UserId then yard=candidate;break end
 end
 if not yard or not yard:FindFirstChild(spawn.Slot)then model:Destroy();return end
 local bbox,size=model:GetBoundingBox();local offset=model:GetPivot():ToObjectSpace(bbox)
 model.Parent=workspace
 model:PivotTo(spawn.CFrame*CFrame.new(0,size.Y/2,0)*offset:Inverse())
 table.insert(active,model);while #active>4 do local old=table.remove(active,1);old:Destroy()end
 Debris:AddItem(model,x.TierIndex>=7 and 14 or 6)
 local glow=Instance.new('Highlight');glow.FillTransparency=.85;glow.OutlineColor=Color3.fromRGB(255,220,90);glow.Parent=model
 local attachment=Instance.new('Attachment');attachment.Position=Vector3.new(0,size.Y/2+1,0)
 local part=model:FindFirstChildWhichIsA('BasePart');if part then attachment.Parent=part end
 local label=Instance.new('BillboardGui');label.Size=UDim2.fromOffset(230,66);label.StudsOffsetWorldSpace=Vector3.new(0,size.Y/2+1,0);label.MaxDistance=90;label.Adornee=part;label.Parent=model
 local text=Instance.new('TextLabel');text.Size=UDim2.fromScale(1,1);text.BackgroundTransparency=1;text.TextColor3=Color3.fromRGB(255,234,157);text.Font=Enum.Font.GothamBold;text.TextSize=18;text.TextStrokeTransparency=.2
 text.Text=x.DisplayName..'\n'..string.format('%.6g kg',x.WeightKg)..' · '..x.WeightTier;text.Parent=label
 if x.TierIndex>=4 or x.Mutation~='NORMAL' or x.Class=='Secret'then
  toast(x.Mutation..' '..x.DisplayName..'\n'..string.format('%.6g kg',x.WeightKg)..' · '..x.WeightTier..'\nCombined: 1 / '..string.format('%.4g',x.CombinedOdds),x.TierIndex>=7 and 7 or 4)
 end
 if not gui:GetAttribute('OpenMenu')and(x.TierIndex>=5 or x.Class=='Secret')then
  local sound=audio:Clone();sound.PlaybackSpeed=x.TierIndex>=9 and .45 or .7;sound.Volume=.22;sound.Parent=workspace.CurrentCamera;sound:Play();Debris:AddItem(sound,4)
  -- One short zoom, with no change to camera position or player controls.
  local camera=workspace.CurrentCamera
  if camera and x.TierIndex>=6 and not player:GetAttribute('ReducedMotion') and not camera:GetAttribute('DiscoveryZoom')then
   camera:SetAttribute('DiscoveryZoom',true);local original=camera.FieldOfView
   Tween:Create(camera,TweenInfo.new(.25),{FieldOfView=math.min(90,original+6)}):Play()
   task.delay(.4,function()if camera.Parent then Tween:Create(camera,TweenInfo.new(.5),{FieldOfView=original}):Play();task.delay(.6,function()camera:SetAttribute('DiscoveryZoom',nil)end)end end)
  end
  if x.TierIndex>=7 and not player:GetAttribute('ReducedMotion')then
   local humanoid=player.Character and player.Character:FindFirstChildOfClass('Humanoid')
   if humanoid then task.spawn(function()
    local original=humanoid.CameraOffset
    for index=1,10 do if not humanoid.Parent then break end;humanoid.CameraOffset=original+Vector3.new(math.sin(index*4)*.09,math.cos(index*5)*.07,0)*(1-index/11);task.wait(.04)end
    if humanoid.Parent then humanoid.CameraOffset=original end
   end)end
  end
  if x.TierIndex>=9 then
   local bars={};for _,top in ipairs({true,false})do local b=Instance.new('Frame');b.BackgroundColor3=Color3.new();b.BorderSizePixel=0;b.Size=UDim2.fromScale(1,.07);b.Position=UDim2.fromScale(0,top and 0 or .93);b.ZIndex=75;b.Parent=gui;table.insert(bars,b)end
   task.delay(2,function()for _,b in ipairs(bars)do b:Destroy()end end)
  end
 end
end)
Replicated:WaitForChild('DiscoveryAnnouncement').OnClientEvent:Connect(function(x,global)
 toast((global and 'GLOBAL RECORD · ' or 'INCREDIBLE FIND · ')..x.DisplayName..'\n'..string.format('%.6g kg',x.WeightKg)..' · finder '..x.OriginalFinderUserId,6)
end)
