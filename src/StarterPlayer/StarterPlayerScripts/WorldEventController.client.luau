local RS=game:GetService('ReplicatedStorage');local Players=game:GetService('Players');local Run=game:GetService('RunService');local UIS=game:GetService('UserInputService');local PromptService=game:GetService('ProximityPromptService')
local package=RS:WaitForChild('WorldEvents');local Config=require(package.WorldEventConfig);local Definitions=require(package.WorldEventDefinitions)
local Lighting=require(package.WorldEventLighting);local Audio=require(package.WorldEventAudio);local FX=require(package.WorldEventFX)
local player=Players.LocalPlayer
local playerGui=player:WaitForChild('PlayerGui')
local gui=playerGui:FindFirstChild('ScreenGui')
while not gui do
 local child=playerGui.ChildAdded:Wait()
 if child.Name=='ScreenGui' then gui=child end
end
local U=require(gui.Modules.UITheme);local colors=U.Colors
local notice=U.Panel(gui,'WorldEventNotice',0,0,640,106,true);notice.AnchorPoint=Vector2.new(.5,0);notice.ZIndex=85;notice.Visible=false
-- Event palettes include cream and pastel hues. Keep readable theme ink on
-- the white card; the event's own color belongs in the decorative accent.
local noticeTitle=U.Center(notice,'',16,7,608,44,28,colors.text,true);local noticeSub=U.Center(notice,'',16,52,608,38,20,colors.text)
noticeTitle.Name='Title';noticeSub.Name='Subtitle';noticeTitle.ZIndex=86;noticeSub.ZIndex=86
noticeTitle.TextScaled=true;noticeSub.TextScaled=true
U.New('UITextSizeConstraint',{MinTextSize=18,MaxTextSize=28},noticeTitle)
U.New('UITextSizeConstraint',{MinTextSize=16,MaxTextSize=20},noticeSub)
local noticeAccent=U.Frame(notice,'EventAccent',16,97,608,5,colors.gold);noticeAccent.ZIndex=86;U.Round(noticeAccent,3)
local function layoutNotice()
 local left,top,width=U.SafeArea(gui);local mobile=width<700;local w=math.max(240,math.min(640,width-24));local h=mobile and 120 or 106
 notice.Size=UDim2.fromOffset(w,h);notice.Position=UDim2.fromOffset(left+width/2,math.max(top+12,mobile and 120 or 90))
 noticeTitle.Size=UDim2.fromOffset(w-32,mobile and 56 or 44)
 noticeSub.Position=UDim2.fromOffset(16,mobile and 65 or 52);noticeSub.Size=UDim2.fromOffset(w-32,38)
 noticeAccent.Position=UDim2.fromOffset(16,h-9);noticeAccent.Size=UDim2.fromOffset(w-32,5)
end
gui:GetPropertyChangedSignal('AbsoluteSize'):Connect(layoutNotice);layoutNotice()
local current,activeDef,endingAt,endingLength;local noticeUntil=0;local enteredAt=0;local lastRevision=-1;local lastTick=-1;local generation
-- Phones and tablets start on Medium (Low hid most of every event); the PAWPAD setting
-- still cycles High / Medium / Low and now shows the level actually in use.
if player:GetAttribute('WorldEventFX')==nil then player:SetAttribute('WorldEventFX',(UIS.TouchEnabled and not UIS.KeyboardEnabled)and 'Medium'or 'High')end
local function quality()return Config.FX[player:GetAttribute('WorldEventFX')or 'High']or Config.FX.Medium end
local function notify(text,sub,color,duration)
 if gui:GetAttribute('OpenMenu')~=nil then return end
 noticeTitle.Text=text;noticeSub.Text=sub or '';noticeAccent.BackgroundColor3=color or colors.gold;notice.Visible=true;noticeUntil=os.clock()+(duration or 4)
end
gui:GetAttributeChangedSignal('OpenMenu'):Connect(function()
 if gui:GetAttribute('OpenMenu')~=nil then notice.Visible=false;noticeUntil=0 end
end)
local function cleanup()FX.Stop();Audio.Stop(true);Lighting.Stop();activeDef=nil;endingAt=nil end
local function apply(state)
 if type(state)~='table'or not Definitions.ById[state.EventId]then return end
 if current and current.State==state.State and current.Generation==state.Generation and current.EndTimestamp==state.EndTimestamp then return end
 local previous=current;current=state
 local def=Definitions.ById[state.EventId]
 if state.State=='ACTIVE'then
  cleanup();activeDef=def;enteredAt=os.clock();generation=state.Generation;Lighting.Begin()
  local late=workspace:GetServerTimeNow()-state.StartTimestamp>Config.IntroDuration+2
  Audio.Begin(def.Id,late,state.StartTimestamp);FX.Begin(def,state,quality())
  -- The cinematic title is owned by WorldEventCataclysm.
 elseif state.State=='ENDING'and activeDef then endingAt=os.clock();endingLength=math.max(1,state.EndTimestamp-workspace:GetServerTimeNow());FX.End();Audio.Stop(false);notify('THE WORLD SETTLES',def.DisplayName..' has ended.',def.ColorTheme,3)
 elseif state.State=='WARNING'then cleanup();notify(def.Id=='NULL_HOUR'and '[ WORLD STATE ERROR ]'or 'WORLD EVENT APPROACHING',def.Id=='NULL_HOUR'and 'ERROR' or def.DisplayName:upper(),def.ColorTheme,4)
 else cleanup()end
end
local predictedPickups={};local pickupCooldownUntil=0
local function pickupModel(prompt)
 if not prompt or prompt.Name~='WorldEventPickupPrompt'then return end
 local model=prompt:FindFirstAncestorOfClass('Model')
 if not model or not model:GetAttribute('EventObjectId')then return end
 return model
end
local function restorePickup(id)
 local state=predictedPickups[id];if not state then return end;predictedPickups[id]=nil
 local model=state.Model
 if not model or not model.Parent then return end
 for part,value in pairs(state.Parts)do if part.Parent then part.LocalTransparencyModifier=value end end
 for object,value in pairs(state.Enabled)do if object.Parent then object.Enabled=value end end
 if state.Prompt and state.Prompt.Parent then state.Prompt.Enabled=true end
end
local function predictPickup(prompt)
 if os.clock()<pickupCooldownUntil then return end
 local model=pickupModel(prompt);if not model then return end
 local id=model:GetAttribute('EventObjectId');if predictedPickups[id]then return end
 local state={Model=model,Prompt=prompt,Parts={},Enabled={}};predictedPickups[id]=state;prompt.Enabled=false
 for _,object in ipairs(model:GetDescendants())do
  if object:IsA('BasePart')then state.Parts[object]=object.LocalTransparencyModifier;object.LocalTransparencyModifier=1
  elseif object:IsA('ParticleEmitter')or object:IsA('Trail')or object:IsA('Beam')or object:IsA('BillboardGui')or object:IsA('SurfaceGui')then state.Enabled[object]=object.Enabled;object.Enabled=false end
 end
 model.Destroying:Connect(function()if predictedPickups[id]==state then predictedPickups[id]=nil end end)
end
PromptService.PromptTriggered:Connect(function(prompt,who)
 if who and who~=player then return end
 predictPickup(prompt)
end)
package:WaitForChild('Changed').OnClientEvent:Connect(apply)
package.Signal.OnClientEvent:Connect(function(data)
 if data.Kind=='Signature'and activeDef and data.EventId==activeDef.Id then FX.Signature(data.Duration or 10)
 elseif data.Kind=='Discovered'then local d=Definitions.ById[data.EventId];if d and os.clock()-enteredAt>7 then notify('NEW WORLD EVENT DISCOVERED',d.Id=='NULL_HOUR'and '[REDACTED]'or d.DisplayName,d.ColorTheme,4)end
 elseif data.Kind=='Reward'then if data.ObjectId then predictedPickups[data.ObjectId]=nil end;pickupCooldownUntil=os.clock()+(Config.Interactions.Cooldown or 0);Audio.Cue('interaction',data.Position);Audio.Cue('reward',data.Position);notify('GOOD FIND!','+'..data.Reward.Cash..' Coins · +'..data.Reward.Bones..' Bones',colors.gold,2)
 elseif data.Kind=='Hint'then if data.ObjectId then restorePickup(data.ObjectId)end;notify(data.Message,'',colors.gold,2)end
end)
local stateFolder=package:WaitForChild('State')
local function sync()local attributes=stateFolder:GetAttributes();if attributes.Revision and attributes.Revision~=lastRevision then lastRevision=attributes.Revision;apply(attributes)end end
stateFolder:GetAttributeChangedSignal('Revision'):Connect(sync);sync()
if not current then task.spawn(function()local ok,state=pcall(function()return package.GetState:InvokeServer()end);if ok then apply(state)end end)end
player:GetAttributeChangedSignal('WorldEventFX'):Connect(function()if activeDef then FX.Begin(activeDef,current,quality())end end)
local elapsed=0
Run.Heartbeat:Connect(function(dt)
 elapsed+=dt;if elapsed<.08 then return end;elapsed=0
 -- World state is presented on PAWPAD Extras; no second persistent HUD.
 if notice.Visible and os.clock()>noticeUntil then notice.Visible=false end
 if current then
  local left=math.max(0,math.ceil(current.EndTimestamp-workspace:GetServerTimeNow()));local clock=string.format('%02d:%02d',math.floor(left/60),left%60)
  local def=Definitions.ById[current.EventId]
  if current.State=='WARNING'and left<=10 and left~=lastTick then lastTick=left;notify(def.Id=='NULL_HOUR'and '[NULL]'or tostring(left),def.Id=='NULL_HOUR'and ''or def.DisplayName,def.ColorTheme,.8)end
 end
 if activeDef then
  local alpha=endingAt and 1-math.clamp((os.clock()-endingAt)/endingLength,0,1)or math.clamp((os.clock()-enteredAt)/Config.IntroDuration,0,1)
  Lighting.Update(activeDef,alpha)
  if endingAt and alpha<=0 then cleanup()end
 end
end)
gui.Destroying:Connect(cleanup)
print('DOGROTS_WORLD_EVENT_CLIENT_READY')
