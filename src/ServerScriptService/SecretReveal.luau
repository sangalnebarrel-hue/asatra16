-- A Secret dog obtained off the tongue (a Lucky Block opened on a pad, the Long Dog dug
-- up, Aurion won at the DOG-O-MATIC) still gets its arrival: a display-only clone acts
-- out the arrival on a stage in workspace.DOGROTS_SecretReveals, and every client plays
-- SecretArrivals/Dogs/<DogId> on it, exactly like a Secret arriving on the tongue.
-- Ownership is already committed by the caller; this is presentation only.
local RS=game:GetService('ReplicatedStorage');local SS=game:GetService('ServerStorage')
local Http=game:GetService('HttpService');local Tween=game:GetService('TweenService')
local Rig=require(RS.DogRig);local Arrivals=require(RS.SecretArrivalConfig)
local Definitions=require(RS.DogEconomy.DogDefinitions)
local M={}
local folder=workspace:FindFirstChild('DOGROTS_SecretReveals')
if not folder then folder=Instance.new('Folder');folder.Name='DOGROTS_SecretReveals';folder.Parent=workspace end
M.Folder=folder

function M.Has(dogId)return Arrivals.Dogs[dogId]~=nil and Definitions[dogId]~=nil end
-- Seconds the arrival lasts (the caller may wait this long before its own reveal UI).
function M.Hold(dogId)local a=Arrivals.Dogs[dogId];return a and a.Hold or 0 end

local function dissolve(model)
 for _,p in ipairs(model:GetDescendants())do
  if p:IsA('BasePart')then Tween:Create(p,TweenInfo.new(.65),{Transparency=1}):Play()end
 end
 task.delay(.7,function()if model.Parent then model:Destroy()end end)
end
--[[ M.Show(dogId, ground, facing, options) → Model?
 ground   Vector3 where the dog's feet stand
 facing   Vector3 direction it faces (flattened)
 options.Venue  'Yard' | 'Machine' | 'Excavation' (tells the cinematic it is not on the tongue)
 options.By     display name of the player who got it (shown on the reveal card)
 options.Linger seconds it stays after the arrival (default 6); false = until destroyed
 options.Parent destroy the display dog together with this instance ]]
function M.Show(dogId,ground,facing,options)
 options=options or {}
 local arrival,def=Arrivals.Dogs[dogId],Definitions[dogId]
 if not arrival or not def then return nil end
 local template=SS.DogTemplates:FindFirstChild(def.VisualAsset)
 if not template or not template:IsA('Model')then return nil end
 local model=template:Clone()
 for _,o in ipairs(model:GetDescendants())do
  if o:IsA('ProximityPrompt')or o:IsA('BillboardGui')or o:IsA('LuaSourceContainer')then o:Destroy()end
 end
 if not Rig.Prepare(model,Vector3.new(10,6,10))then model:Destroy();return nil end
 local flat=Vector3.new(facing.X,0,facing.Z)
 if flat.Magnitude<.01 then flat=Vector3.new(0,0,1)end
 Rig.Place(model,ground,CFrame.lookAt(Vector3.zero,flat.Unit))
 local now=workspace:GetServerTimeNow()
 model.Name=dogId
 model:SetAttribute('DogId',dogId);model:SetAttribute('DogUid','reveal-'..Http:GenerateGUID(false))
 model:SetAttribute('DisplayName',def.DisplayName);model:SetAttribute('Rarity',def.Rarity)
 model:SetAttribute('State','Reveal');model:SetAttribute('SecretReveal',true)
 model:SetAttribute('RevealVenue',options.Venue or 'Yard');model:SetAttribute('RevealBy',options.By or '')
 model:SetAttribute('SecretArrivalAt',now);model:SetAttribute('ArrivalHoldUntil',now+arrival.Hold)
 model:SetAttribute('ArrivalOrigin',ground);model:SetAttribute('LocomotionSpeed',0)
 local function clip(name,looped,at)
  model:SetAttribute('AnimationName',name);model:SetAttribute('AnimationLooped',looped==true);model:SetAttribute('AnimationStartedAt',at)
 end
 clip('Idle',true,now)
 for _,step in ipairs(arrival.Clips or {})do
  local at,name,looped=step[1],step[2],step[3]
  if at<=0 then clip(name,looped,now)
  else task.delay(at,function()if model.Parent then clip(name,looped,now+at)end end)end
 end
 -- After the arrival it stands there, happy, until it fades.
 task.delay(arrival.Hold,function()if model.Parent then clip('Idle',true,now+arrival.Hold)end end)
 model.Parent=folder
 if options.Parent then
  options.Parent.Destroying:Connect(function()if model.Parent then model:Destroy()end end)
 end
 if options.Linger~=false then
  task.delay(arrival.Hold+(options.Linger or 6),function()if model.Parent then dissolve(model)end end)
 end
 return model
end
return M
