local Players=game:GetService('Players');local Tween=game:GetService('TweenService')
local C=require(game.ReplicatedStorage.ServerKingConfig)
local P={};P.__index=P
local function tweenAlpha(model,to,seconds)
 for _,o in ipairs(model:GetDescendants())do
  if o:IsA('BasePart')or o:IsA('Decal')or o:IsA('Texture')then
   local target=to==0 and (o:GetAttribute('KingOriginalTransparency')or 0)or 1
   Tween:Create(o,TweenInfo.new(seconds),{Transparency=target}):Play()
  end
 end
end
local function fallback(player)
 local result=Instance.new('Model');local character=player.Character;local head=character and character:FindFirstChild('Head')
 if head then
  local old=head.Archivable;head.Archivable=true;head:Clone().Parent=result;head.Archivable=old
  for _,child in ipairs(character:GetChildren())do if child:IsA('Accessory')then child:Clone().Parent=result end end
 else
  result:Destroy();return nil
 end
 return result
end
-- Align accessories in head-local coordinates before stripping humanoid animation.
function P.Prepare(model,target)
 local head=model:FindFirstChild('Head');if not head or not head:IsA('BasePart')then return nil end
 local attachments={};for _,a in ipairs(head:GetChildren())do if a:IsA('Attachment')then attachments[a.Name]=a end end
 for _,o in ipairs(model:GetChildren())do if o~=head then
  local keep=false
  if o:IsA('Accessory')then local handle=o:FindFirstChild('Handle')
   if handle then for _,a in ipairs(handle:GetChildren())do if a:IsA('Attachment')and attachments[a.Name]then
    handle.CFrame=head.CFrame*attachments[a.Name].CFrame*a.CFrame:Inverse();keep=true;break
   end end end
  end
  if not keep then o:Destroy()end
 end end
 for _,o in ipairs(model:GetDescendants())do
  if o:IsA('LuaSourceContainer')or o:IsA('JointInstance')or o:IsA('Constraint')or o:IsA('WeldConstraint')then o:Destroy()
  elseif o:IsA('BasePart')then o.Anchored=true;o.CanCollide=false;o.CanQuery=false;o.CanTouch=false;o.CastShadow=false end
 end
 model.PrimaryPart=head;model:ScaleTo(C.HeadScale)
 -- Pivot offsets and a tilted live head must not tilt the sky avatar.
 model:PivotTo(target*head.CFrame:Inverse()*model:GetPivot())
 for _,o in ipairs(model:GetDescendants())do if o:IsA('BasePart')or o:IsA('Decal')or o:IsA('Texture')then o:SetAttribute('KingOriginalTransparency',o.Transparency)end end
 return head
end
function P.new(hub,anchor)
 local self=setmetatable({Hub=hub,Anchor=anchor,Version=0,Id=nil,Model=nil},P)
 self.Screen=hub.CommunityCourt.ServerKingMonument.KingInfo
 local gui=self.Screen:FindFirstChild('KingPresentation');if gui then gui:Destroy()end
 gui=Instance.new('SurfaceGui');gui.Name='KingPresentation';gui.Face=Enum.NormalId.Front;gui.CanvasSize=Vector2.new(1100,420);gui.LightInfluence=0;gui.Parent=self.Screen
 local function label(name,value,y,h,size,color)
  local t=Instance.new('TextLabel');t.Name=name;t.BackgroundTransparency=1;t.Size=UDim2.new(1,-60,0,h);t.Position=UDim2.fromOffset(30,y)
  t.Font=Enum.Font.FredokaOne;t.Text=value;t.TextSize=size;t.TextTruncate=Enum.TextTruncate.AtEnd;t.ClipsDescendants=true;t.TextColor3=color;t.Parent=gui;return t
 end
 local gold=Color3.fromRGB(245,207,118);local cream=Color3.fromRGB(239,236,220)
 label('Title','SERVER KING',16,58,52,gold)
 self.NameLabel=label('Username','WAITING FOR A KING',98,62,48,cream)
 self.LevelLabel=label('Level','',164,52,40,gold)
 label('Scope','CURRENT SERVER #1',264,44,28,cream)
 label('Criterion','TOTAL XP  ·  YOUR NEXT CHAPTER',324,42,23,Color3.fromRGB(164,185,185))
 self.Screen:SetAttribute('KingState','Waiting');return self
end
function P:UpdateName(player,level)
 self.NameLabel.Text='@'..player.Name;self.LevelLabel.Text='Lv. '..level
 if self.Model and self.Model:GetAttribute('UserId')==player.UserId then local t=self.Model:FindFirstChild('KingTitle',true);if t then t.Text='SERVER KING  ·  @'..player.Name end end
end
function P:Set(player,level)
 if player and self.Id==player.UserId and (self.Model and self.Model:GetAttribute('UserId')==player.UserId or self.Loading)then self:UpdateName(player,level);return end
 self.Version+=1;local version=self.Version;local previous=self.Model and self.Model:GetAttribute('UserId')
 self.Id=player and player.UserId or nil;self.Loading=player~=nil
 if not player then
  if self.Model then self.Model:Destroy();self.Model=nil end
  self.NameLabel.Text='WAITING FOR A KING';self.LevelLabel.Text='';self.Screen:SetAttribute('KingState','Waiting');return
 end
 task.spawn(function()
  local ok,model=pcall(function()
   local desc=Players:GetHumanoidDescriptionFromUserIdAsync(player.UserId)
   return Players:CreateHumanoidModelFromDescriptionAsync(desc,Enum.HumanoidRigType.R15)
  end)
  if not ok or not model then model=fallback(player)end
  if version~=self.Version or not player.Parent then if model then model:Destroy()end;return end
  if not model then self.Loading=false;self:UpdateName(player,level);self.Screen:SetAttribute('KingState','Avatar pending');return end
  local pos=self.Anchor.Position;local direction=self.Anchor.CFrame.LookVector*Vector3.new(1,0,1)
  if direction.Magnitude<.1 then direction=Vector3.new(0,0,1)end
  local head=P.Prepare(model,CFrame.lookAt(pos,pos+direction.Unit,Vector3.yAxis))
  if not head then model:Destroy();self.Loading=false;return end
  local old=self.Model
  if old then tweenAlpha(old,1,C.FadeSeconds);task.wait(C.FadeSeconds)end
  if version~=self.Version then model:Destroy();return end
  self.Screen.Color=Color3.fromRGB(13,22,25);task.wait(C.SwapPause)
  if version~=self.Version then model:Destroy();return end
  if old then old:Destroy()end
  for _,o in ipairs(model:GetDescendants())do if o:IsA('BasePart')or o:IsA('Decal')or o:IsA('Texture')then o.Transparency=1 end end
  model.Name='ServerKingAvatar';model:SetAttribute('UserId',player.UserId);model.Parent=self.Hub;self.Model=model;self.Loading=false
  local bb=Instance.new('BillboardGui');bb.Name='KingLabel';bb.Size=UDim2.fromOffset(260,28);bb.StudsOffsetWorldSpace=Vector3.new(0,-head.Size.Y/2-9,0)
  bb.MaxDistance=C.SkyLabelDistance;bb.AlwaysOnTop=false;bb.Adornee=head;bb.Parent=model
  local title=Instance.new('TextLabel');title.Name='KingTitle';title.Size=UDim2.fromScale(1,1);title.BackgroundTransparency=1;title.TextColor3=Color3.fromRGB(255,227,160)
  title.TextSize=17;title.TextTruncate=Enum.TextTruncate.AtEnd;title.Font=Enum.Font.FredokaOne;title.TextStrokeTransparency=.7;title.Parent=bb
  local fill=Instance.new('Attachment');fill.Name='KingFillAnchor';fill.Position=Vector3.new(0,0,-head.Size.Z/2-10);fill.Parent=head
  local light=Instance.new('PointLight');light.Name='KingFaceFill';light.Brightness=.6;light.Range=60;light.Shadows=false;light.Color=Color3.fromRGB(255,230,184);light.Parent=fill
  light:SetAttribute('ServerKingLight',true)
  self:UpdateName(player,level);self.Screen:SetAttribute('KingState','Ready');self.Screen:SetAttribute('KingUserId',player.UserId)
  tweenAlpha(model,0,C.FadeSeconds);Tween:Create(self.Screen,TweenInfo.new(.8),{Color=Color3.fromRGB(32,43,48)}):Play()
  if previous and previous~=player.UserId then
   self.Screen:SetAttribute('ChangeCount',(self.Screen:GetAttribute('ChangeCount')or 0)+1)
   local glow=self.Hub.CommunityCourt.ServerKingMonument:FindFirstChild('CrownGlow',true)
   if glow then local original=glow.Color;glow.Color=Color3.fromRGB(255,248,204);Tween:Create(glow,TweenInfo.new(1.2),{Color=original}):Play()end
			local uri = nil
   if uri then local sound=Instance.new('Sound');sound.Name='KingChanged';sound.SoundId=uri;sound.Volume=C.Sting.Volume;sound.RollOffMaxDistance=140;sound.Parent=self.Screen;sound:Play();game:GetService('Debris'):AddItem(sound,5)end
  end
 end)
end
return P
