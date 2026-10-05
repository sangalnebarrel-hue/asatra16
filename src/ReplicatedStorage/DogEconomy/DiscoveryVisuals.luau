local V={}
local Replicated=game:GetService('ReplicatedStorage')
local colors={GOLDEN=Color3.fromRGB(255,195,40),RAINBOW=Color3.fromRGB(80,230,240),CURSED=Color3.fromRGB(194,40,62),GLITCHED=Color3.fromRGB(207,49,255)}
function V.Clone(x)
 local source=Replicated:WaitForChild('DiscoveryModels'):FindFirstChild(x.ItemId)
 if not source then return nil end
 local m=source:Clone();local color=colors[x.Mutation]
 for index,part in ipairs(m:GetDescendants())do if part:IsA('BasePart')then
  part.Anchored=true;part.CanCollide=false;part.CanTouch=false;part.CanQuery=false
  if color then part.Color=x.Mutation=='RAINBOW' and Color3.fromHSV((index*.077)%1,.8,1) or part.Color:Lerp(color,.65);part.Material=Enum.Material.Neon end
 end end
 local d=require(Replicated.DogEconomy.ItemDefinitions)[x.ItemId]
 local scale=math.clamp(((x.WeightKg or d.BaseWeightKg)/d.BaseWeightKg)^(1/3),.25,d.ScaleCap)
 m:ScaleTo(m:GetScale()*scale);return m
end
function V.Preview(parent,x,px,py,w,h)
 local frame=Instance.new('ViewportFrame');frame.Name='DiscoveryPreview';frame.Position=UDim2.fromOffset(px,py);frame.Size=UDim2.fromOffset(w,h)
 frame.BackgroundColor3=Color3.fromRGB(13,24,39);frame.BorderSizePixel=0;frame.Ambient=Color3.fromRGB(190,192,215);frame.LightColor=Color3.new(1,1,.95);frame.Parent=parent
 local model=V.Clone(x);if not model then return frame end;model.Parent=frame
 local cf,size=model:GetBoundingBox();local camera=Instance.new('Camera');camera.FieldOfView=38
 camera.CFrame=CFrame.lookAt(cf.Position+Vector3.new(1,.65,-1.3).Unit*size.Magnitude*1.65/math.min(1,math.max(.2,w/h)),cf.Position);camera.Parent=frame;frame.CurrentCamera=camera
 return frame
end
return V
