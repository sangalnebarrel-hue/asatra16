local U=require(script.Parent.UITheme)
local Rep=game:GetService('ReplicatedStorage')
local V=require(Rep.DogEconomy.DiscoveryVisuals)
local Definitions=require(Rep.DogEconomy.DogDefinitions)
local Rig=require(Rep.DogRig)
local RenderProfile=require(Rep.DogRenderProfile)
local Animation=require(Rep.DogAnimationPlayer)
local Content=game:GetService('ContentProvider')
local P={}
local loaded=setmetatable({},{__mode='k'})
local loading=setmetatable({},{__mode='k'})
local function preload(source,done)
 if loaded[source]then done();return end
 if loading[source]then table.insert(loading[source],done);return end
 loading[source]={done}
 task.spawn(function()
  for attempt=1,2 do
   local failed=false
   local ok=pcall(function()Content:PreloadAsync({source},function(_,status)
    if status~=Enum.AssetFetchStatus.Success then failed=true end
   end)end)
   if ok and not failed then loaded[source]=true;break end
   if attempt<2 then task.wait(1)end
  end
  local callbacks=loading[source];loading[source]=nil
  for _,callback in ipairs(callbacks)do callback()end
 end)
end
local function populate(view,source,w,h,kind,variant,dogId,silhouette)
 if not view.Parent then return end
 view:ClearAllChildren()
 local world=U.New('WorldModel',{},view);local model=Instance.new('Model');model.Parent=world
 local copy=source:Clone();copy.Parent=model
 local tints={Shiny=Color3.fromRGB(210,235,255),Golden=Color3.fromRGB(255,193,44),Corrupted=Color3.fromRGB(188,56,81),Glitched=Color3.fromRGB(210,87,255),Void=Color3.fromRGB(104,38,164)}
 for _,d in ipairs(copy:GetDescendants())do
  if d:IsA('LuaSourceContainer')or d:IsA('ProximityPrompt')or d:IsA('Sound')or d:IsA('BillboardGui')or d:IsA('SurfaceGui')or d:IsA('ParticleEmitter')then d:Destroy()
  elseif silhouette and(d:IsA('SurfaceAppearance')or d:IsA('Decal')or d:IsA('Texture'))then d:Destroy()
  elseif silhouette and d:IsA('MeshPart')then d.Anchored=true;d.CanCollide=false;d.CanTouch=false;d.CanQuery=false;d.TextureID=''
  elseif d:IsA('BasePart')then d.Anchored=true;d.CanCollide=false;d.CanTouch=false;d.CanQuery=false;if tints[variant]then d.Color=d.Color:Lerp(tints[variant],.38)end end
 end
 if not model:FindFirstChildWhichIsA('BasePart',true)then U.Center(view,'Preview unavailable',0,0,w,h,16,U.Colors.muted,true);return end
 local cf,size=model:GetBoundingBox()
 if kind=='Dog'and copy:IsA('Model')then
  local prepared=Rig.Prepare(copy,Vector3.new(7,5,8))
  if prepared then
   cf=CFrame.new((prepared.Low+prepared.High)/2);size=prepared.Size
   local idle=Animation.ResolveName(dogId or copy:GetAttribute('DogId')or copy.Name,'Idle')
   if idle then
    local player=Animation.new(copy,dogId)
    if player:Play(idle,{FadeTime=0})then player:Sample(0)end
    -- This is a static posed thumbnail; no RenderStepped connection to leak.
   end
  end
 end
 local camera=U.New('Camera',{FieldOfView=32},view);view.CurrentCamera=camera
 local distance=math.max(size.Y,size.X/math.max(.2,w/h))/(2*math.tan(math.rad(16)))*1.18+size.Z*.5
 local direction=kind=='Location' and Vector3.new(1,1,-1)or Vector3.new(.22,.18,-1)
 camera.CFrame=CFrame.lookAt(cf.Position+direction.Unit*math.max(distance,2),cf.Position)
 view:SetAttribute('PreviewReady',true)
end
function P.Scene(parent,source,x,y,w,h,kind,variant,dogId,silhouette)
 local view=U.New('ViewportFrame',{Name='Preview',Position=UDim2.fromOffset(x,y),Size=UDim2.fromOffset(w,h),BackgroundTransparency=1,ZIndex=3,Ambient=Color3.fromRGB(180,199,225),LightColor=Color3.fromRGB(255,236,204),LightDirection=Vector3.new(-1,-1,-1)},parent)
 if kind=='Dog'then RenderProfile.ApplyViewport(view)end
 -- Undiscovered dogs render as a solid black silhouette of their real model.
 if silhouette then view.ImageColor3=Color3.new(0,0,0);variant=nil end
 if not source then U.Center(view,'?',0,0,w,h,60,U.Colors.muted,true);return view end
 if kind=='Dog'then
  U.Center(view,'Loading…',0,0,w,h,16,U.Colors.muted,true)
  -- Build the clone and camera only after its meshes and textures arrive.
  -- Concurrent cards share a single preload; a transient fetch gets one retry.
  preload(source,function()if view.Parent then populate(view,source,w,h,kind,variant,dogId,silhouette)end end)
 else populate(view,source,w,h,kind,variant,dogId,silhouette)end
 return view
end
function P.Dog(parent,d,x,y,w,h,silhouette)
 local models=Rep:FindFirstChild('MenuModels');local id=type(d)=='table'and d.DogId or d
 return P.Scene(parent,models and models:FindFirstChild(Definitions[id] and Definitions[id].VisualAsset or id or ''),x,y,w,h,'Dog',type(d)=='table'and d.Variant,id,silhouette)
end
function P.Item(parent,d,x,y,w,h)return V.Preview(parent,d,x,y,w,h)end
function P.Place(parent,key,x,y,w,h)
 local map=workspace:FindFirstChild('DOGROTS_District');local source=map and map:FindFirstChild(key)
 if key=='Yard'and map then local yards=map:FindFirstChild('04_PlayerYards');if yards then for _,v in ipairs(yards:GetChildren())do if v:GetAttribute('YardId')==game.Players.LocalPlayer:GetAttribute('YardId')then source=v;break end end end end
 return P.Scene(parent,source,x,y,w,h,'Location')
end
function P.Avatar(parent,id,x,y,size)
 return U.New('ImageLabel',{Name='Avatar',BackgroundTransparency=1,Position=UDim2.fromOffset(x,y),Size=UDim2.fromOffset(size,size),Image='rbxthumb://type=AvatarHeadShot&id='..id..'&w=150&h=150',ScaleType=Enum.ScaleType.Fit},parent)
end
return P
