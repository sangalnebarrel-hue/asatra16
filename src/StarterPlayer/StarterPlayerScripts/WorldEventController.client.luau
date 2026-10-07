local RS=game:GetService('ReplicatedStorage');local Players=game:GetService('Players');local Run=game:GetService('RunService');local UIS=game:GetService('UserInputService');local PromptService=game:GetService('ProximityPromptService')
local package=RS:WaitForChild('WorldEvents');local Config=require(package.WorldEventConfig);local Definitions=require(package.WorldEventDefinitions)
local Lighting=require(package.WorldEventLighting);local Audio=require(package.WorldEventAudio);local FX=require(package.WorldEventFX)
-- What events DO on the client: strikes on kennels, UFO beams, variant sparkles.
local GameplayFX=require(package.WorldEventGameplayFX);local Format=require(RS.PriceFormat)
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
local function cleanup()FX.Stop();GameplayFX.Stop();Audio.Stop(true);Lighting.Stop();activeDef=nil;endingAt=nil end
-- The effect summary of an event (Definitions Effects.Text), shown wherever it is announced.
local function effectText(def)return def and def.Effects and def.Effects.Text or ''end
local function apply(state)
 if type(state)~='table'or not Definitions.ById[state.EventId]then return end
 if current and current.State==state.State and current.Generation==state.Generation and current.EndTimestamp==state.EndTimestamp then return end
 local previous=current;current=state
 local def=Definitions.ById[state.EventId]
 if state.State=='ACTIVE'then
  cleanup();activeDef=def;enteredAt=os.clock();generation=state.Generation;Lighting.Begin()
  local late=workspace:GetServerTimeNow()-state.StartTimestamp>Config.IntroDuration+2
  Audio.Begin(def.Id,late,state.StartTimestamp);FX.Begin(def,state,quality());GameplayFX.Begin(def)
  -- The cinematic title is owned by WorldEventCataclysm.
 elseif state.State=='ENDING'and activeDef then endingAt=os.clock();endingLength=math.max(1,state.EndTimestamp-workspace:GetServerTimeNow());FX.End();Audio.Stop(false);notify('THE WORLD SETTLES',def.DisplayName..' has ended.',def.ColorTheme,3)
 elseif state.State=='WARNING'then
  -- Say what is coming and what it will do: "DOG RUSH IN 60 S" / "x2 TONGUE SPAWNS ...".
  cleanup();local left=math.max(1,math.ceil(state.EndTimestamp-workspace:GetServerTimeNow()))
  notify(def.Id=='NULL_HOUR'and '[ WORLD STATE ERROR ] IN '..left..' S'or def.DisplayName:upper()..' IN '..left..' S',effectText(def)~=''and effectText(def)or 'WORLD EVENT APPROACHING',def.ColorTheme,6)
 else cleanup()end
end
local predictedPickups={};local pickupCooldownUntil=0;local struckGeneration
local REWARD_TITLES={BonePile='BONE PILE!',GiantBone='GIANT BONE CLAIMED!',TreasureSpot='TREASURE!',ChargedCrystal='CHARGED UP!',CursedCache='CURSED CACHE!',AlienDigZone='ALIEN FIND!',AlienCrate='ALIEN CRATE!'}
local TIER_COLORS={Common=Color3.fromRGB(200,202,201),Rare=Color3.fromRGB(37,166,255),Epic=Color3.fromRGB(184,64,255),Legendary=Color3.fromRGB(255,191,48),Mythic=Color3.fromRGB(255,51,100),Secret=Color3.fromRGB(155,58,255)}
-- Everything a pickup gave, in one line: "+12,400 COINS · +4 BONES · FREE RARE LUCKY BLOCK".
local function rewardText(r)
 local parts={}
 if (tonumber(r.Cash)or 0)>0 then table.insert(parts,'+'..Format.Number(r.Cash)..' COINS')end
 if (tonumber(r.Bones)or 0)>0 then table.insert(parts,'+'..Format.Number(r.Bones)..' BONES')end
 if type(r.Block)=='string'then table.insert(parts,'FREE '..r.Block:upper()..' LUCKY BLOCK')end
 if type(r.BlockFull)=='string'then table.insert(parts,'BLOCK STORAGE FULL · PAID IN COINS')end
 if type(r.Supply)=='table'then table.insert(parts,'+'..math.floor((tonumber(r.Supply.Seconds)or 0)/60)..' MIN '..string.upper(tostring(r.Supply.Name or 'SUPPLY')))end
 if type(r.Item)=='table'and r.Item.DisplayName then table.insert(parts,string.upper(tostring(r.Item.DisplayName)))end
 if r.ItemFull then table.insert(parts,'ITEM STORAGE FULL')end
 return table.concat(parts,' · ')
end
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
 local model=pickupModel(prompt);if not model then return end
 -- A shared pickup (the Giant Bone) is not under the personal collect cooldown.
 if os.clock()<pickupCooldownUntil and not model:GetAttribute('Shared')then return end
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
 if data.Kind=='Signature'and activeDef and data.EventId==activeDef.Id then FX.Signature(data.Duration or 10);GameplayFX.Signature(activeDef,data.Duration)
 elseif data.Kind=='Discovered'then local d=Definitions.ById[data.EventId];if d and os.clock()-enteredAt>7 then notify('NEW WORLD EVENT DISCOVERED',d.Id=='NULL_HOUR'and '[REDACTED]'or d.DisplayName,d.ColorTheme,4)end
 elseif data.Kind=='Reward'then
  local reward=type(data.Reward)=='table'and data.Reward or {}
  if data.ObjectId then predictedPickups[data.ObjectId]=nil end
  -- A shared pickup (the Giant Bone) does not start the personal collect cooldown.
  if not reward.Shared then pickupCooldownUntil=os.clock()+(Config.Interactions.Cooldown or 0)end
  Audio.Cue('interaction',data.Position);Audio.Cue('reward',data.Position)
  notify(REWARD_TITLES[reward.Kind]or 'GOOD FIND!',rewardText(reward),reward.Block and(TIER_COLORS[reward.Block]or colors.gold)or colors.gold,3)
 elseif data.Kind=='Hint'then if data.ObjectId then restorePickup(data.ObjectId)end;notify(data.Message,'',colors.gold,2)
 elseif data.Kind=='Strike'then
  local mine=GameplayFX.Strike(data)
  -- Called out on the first strike of the event and on the signature; later ones float
  -- an INSTANT DIG label over the struck kennel.
  if mine and activeDef and(data.Big or struckGeneration~=generation)then
   struckGeneration=generation
   notify(data.Style=='Tremor'and 'TREMOR!'or 'LIGHTNING STRIKE!','YOUR '..(mine.Count or 1)..((mine.Count or 1)==1 and ' KENNEL DOG DIGS'or ' KENNEL DOGS DIG')..' RIGHT NOW',data.Color,2.5)
  end
 elseif data.Kind=='Abduct'then
  GameplayFX.Abduct(data)
  if data.Phase=='Lock'then notify('UFO TARGET: '..string.upper(tostring(data.Rarity or 'TONGUE'))..' DOG',string.upper(tostring(data.Name or 'A DOG'))..' · BUY IT IN '..(data.Seconds or 3)..' S OR IT IS BEAMED UP',data.Color,2.5)
  elseif data.Phase=='Escape'and data.Bought then notify('SAVED!','BOUGHT IN TIME · THE UFO LEFT EMPTY-PAWED',data.Color,1.6)end
 elseif data.Kind=='Notice'or data.Kind=='Perk'then
  notify(tostring(data.Title or ''),tostring(data.Text or ''),typeof(data.Color)=='Color3'and data.Color or colors.gold,tonumber(data.Duration)or 3)
 end
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
  if current.State=='WARNING'and left<=10 and left~=lastTick then lastTick=left;notify(def.Id=='NULL_HOUR'and '[NULL]'or tostring(left),def.Id=='NULL_HOUR'and effectText(def)or def.DisplayName:upper()..(effectText(def)~=''and ' · '..effectText(def)or ''),def.ColorTheme,.8)end
 end
 if activeDef then
  local alpha=endingAt and 1-math.clamp((os.clock()-endingAt)/endingLength,0,1)or math.clamp((os.clock()-enteredAt)/Config.IntroDuration,0,1)
  Lighting.Update(activeDef,alpha)
  if endingAt and alpha<=0 then cleanup()end
 end
end)
gui.Destroying:Connect(cleanup)
print('DOGROTS_WORLD_EVENT_CLIENT_READY')
