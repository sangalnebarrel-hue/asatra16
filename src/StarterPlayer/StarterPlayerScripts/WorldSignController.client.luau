local Players=game:GetService("Players")
local RunService=game:GetService("RunService")
local CollectionService=game:GetService("CollectionService")
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local Config=require(ReplicatedStorage:WaitForChild("WorldSignConfig"))
local TAG="ManagedWorldSign"
local player=Players.LocalPlayer
local entries={}
local function priorityData(p)
 p=math.clamp(tonumber(p) or 2,1,4)
 return p,Config.Defaults[p]
end
local function findGui(inst)
 if inst:IsA("BillboardGui") or inst:IsA("SurfaceGui") then return inst end
 return inst:FindFirstChildWhichIsA("BillboardGui",true) or inst:FindFirstChildWhichIsA("SurfaceGui",true)
end
local function findPart(inst,gui)
 if gui.Adornee and gui.Adornee:IsA("BasePart") then return gui.Adornee end
 if inst:IsA("BasePart") then return inst end
 if gui.Parent and gui.Parent:IsA("BasePart") then return gui.Parent end
 return inst:FindFirstChildWhichIsA("BasePart",true) or gui.Parent and gui.Parent:FindFirstChildWhichIsA("BasePart",true)
end
local function addProp(list,obj,prop)
 table.insert(list,{obj=obj,prop=prop,base=obj[prop]})
end
local function capture(gui)
 local list={}
 local function scan(obj)
  if obj:IsA("TextLabel") or obj:IsA("TextButton") or obj:IsA("TextBox") then addProp(list,obj,"TextTransparency") end
  if obj:IsA("ImageLabel") or obj:IsA("ImageButton") then addProp(list,obj,"ImageTransparency") end
  if obj:IsA("Frame") or obj:IsA("ScrollingFrame") or obj:IsA("ViewportFrame") then addProp(list,obj,"BackgroundTransparency") end
  if obj:IsA("UIStroke") then addProp(list,obj,"Transparency") end
  if obj:IsA("CanvasGroup") then addProp(list,obj,"GroupTransparency") end
 end
 scan(gui)
 for _,d in ipairs(gui:GetDescendants()) do scan(d) end
 return list
end
local function getDebug(entry)
 if not Config.DebugMode then return nil end
 local part=entry.part
 if not part then return nil end
 local pg=player:FindFirstChildOfClass("PlayerGui")
 if not pg then return nil end
 local g=entry.debug
 if not g then
  g=Instance.new("BillboardGui");g.Name="WorldSignDebug";g.Size=UDim2.fromOffset(230,42);g.StudsOffset=Vector3.new(0,4,0);g.AlwaysOnTop=true;g.MaxDistance=1200;g.Adornee=part;g.Parent=pg
  local t=Instance.new("TextLabel");t.Name="Info";t.Size=UDim2.fromScale(1,1);t.BackgroundColor3=Color3.fromRGB(15,18,25);t.BackgroundTransparency=0.2;t.TextColor3=Color3.new(1,1,1);t.TextStrokeTransparency=0.35;t.TextScaled=true;t.Font=Enum.Font.Gotham;t.Parent=g
  entry.debug=g;entry.debugText=t
 end
 return entry.debugText
end
local function register(inst)
 if entries[inst] then return end
 local gui=findGui(inst)
 if not gui then return end
 local p,defaults=priorityData(inst:GetAttribute("Priority"))
 local max=tonumber(inst:GetAttribute("MaxDistance")) or defaults.MaxDistance
 local fade=tonumber(inst:GetAttribute("FadeStartDistance")) or defaults.FadeStartDistance
 if max<=fade then max=fade+1 end
 local part=findPart(inst,gui)
 local originalMax=gui:IsA("BillboardGui") and gui.MaxDistance or nil
 if originalMax and originalMax<max+30 then gui.MaxDistance=max+30 end
 gui.Enabled=true
 entries[inst]={inst=inst,gui=gui,part=part,props=capture(gui),priority=p,max=max,fade=fade,always=inst:GetAttribute("AlwaysVisible")==true,alpha=0,debug=nil,debugText=nil,originalMax=originalMax}
end
local function unregister(inst)
 local e=entries[inst]
 if not e then return end
 for _,x in ipairs(e.props) do if x.obj and x.obj.Parent then x.obj[x.prop]=x.base end end
 if e.originalMax and e.gui and e.gui.Parent then e.gui.MaxDistance=e.originalMax end
 if e.debug then e.debug.Parent=nil end
 entries[inst]=nil
end
for _,inst in ipairs(CollectionService:GetTagged(TAG)) do register(inst) end
CollectionService:GetInstanceAddedSignal(TAG):Connect(register)
CollectionService:GetInstanceRemovedSignal(TAG):Connect(unregister)
local accumulator=0
local interval=1/math.max(1,Config.UpdateHz or 8)
RunService.RenderStepped:Connect(function(dt)
 accumulator+=dt
 if accumulator<interval then return end
 local step=accumulator;accumulator=0
 local cam=workspace.CurrentCamera
 if not cam then return end
 for inst,e in pairs(entries) do
  if not inst.Parent or not e.gui.Parent then unregister(inst) else
   local distance=e.part and (cam.CFrame.Position-e.part.Position).Magnitude or math.huge
   local target=1
   if not e.always then
    if distance<=e.fade then target=1 elseif distance>=e.max then target=0 else target=1-(distance-e.fade)/(e.max-e.fade) end
   end
   local blend=1-math.exp(-step*10)
   e.alpha+=(target-e.alpha)*blend
   if e.alpha<0.002 then e.alpha=0 end
   for _,x in ipairs(e.props) do if x.obj and x.obj.Parent then x.obj[x.prop]=x.base+(1-x.base)*(1-e.alpha) end end
   local t=getDebug(e)
   if t then t.Text=string.format("%s\n%.0f studs | alpha %.2f | P%d",inst.Name,distance,e.alpha,e.priority) end
  end
 end
end)
print("WORLD_SIGN_CONTROLLER_READY")