-- Set the first arrival view, then immediately hand camera control back to Roblox.
local Players=game:GetService('Players')
local Run=game:GetService('RunService')
local player=Players.LocalPlayer
local spawnPoint=workspace:FindFirstChild('DistrictSpawn')
while not spawnPoint do
 local child=workspace.ChildAdded:Wait()
 if child.Name=='DistrictSpawn' then spawnPoint=child end
end
local binding='WelcomeArrivalCamera'
local generation=0
local arrivalFOV=workspace.CurrentCamera.FieldOfView
local function orient(character)
 generation+=1;local current=generation
 local camera=workspace.CurrentCamera
 if not camera or player.RespawnLocation and player.RespawnLocation~=spawnPoint then return end
 local direction=spawnPoint:GetAttribute('ArrivalDirection')or Vector3.new(0,0,-1)
 local function frame(position)
  return CFrame.lookAt(position+Vector3.new(5,7,17),position+Vector3.new(-125,100,-122))
 end
 Run:UnbindFromRenderStep(binding)
 camera.CameraType=Enum.CameraType.Scriptable;camera.FieldOfView=84
 camera.CFrame=frame(spawnPoint.Position+Vector3.new(0,3,0))
 local started=os.clock();local readyFrames=0;local aligned=false
 Run:BindToRenderStep(binding,Enum.RenderPriority.Camera.Value+1,function()
  if generation~=current or not character.Parent then Run:UnbindFromRenderStep(binding);camera.CameraType=Enum.CameraType.Custom;return end
  local root=character:FindFirstChild('HumanoidRootPart');local humanoid=character:FindFirstChildOfClass('Humanoid')
  local target=character:GetAttribute('WelcomeArrivalCFrame')
  local ready=root and humanoid and character:GetAttribute('WelcomeArrivalReady')and typeof(target)=='CFrame'
  if ready and not aligned then
   -- The owning client may receive the replicated readiness flag before the physics pose.
   character:PivotTo(target*root.CFrame:Inverse()*character:GetPivot())
   root.AssemblyLinearVelocity=Vector3.zero;root.AssemblyAngularVelocity=Vector3.zero;aligned=true
  end
  local position=ready and root.Position or spawnPoint.Position+Vector3.new(0,3,0)
  camera.CFrame=frame(position);camera.Focus=CFrame.new(position+Vector3.new(0,9.5,0))
  if ready then
   readyFrames+=1;camera.CameraSubject=humanoid
   if readyFrames==1 then
    local saved=humanoid.CameraOffset;humanoid.CameraOffset=Vector3.new(0,8,0)
    task.spawn(function()
     while character.Parent and generation==current and humanoid.MoveDirection.Magnitude<.05 and (root.Position-spawnPoint.Position).Magnitude<12 do
      if game:GetService('UserInputService'):IsMouseButtonPressed(Enum.UserInputType.MouseButton2)then break end
      task.wait(.05)
     end
     if humanoid.Parent then game:GetService('TweenService'):Create(humanoid,TweenInfo.new(.6),{CameraOffset=saved}):Play()end
     if generation==current then game:GetService('TweenService'):Create(camera,TweenInfo.new(.6),{FieldOfView=arrivalFOV}):Play()end
    end)
   end
  end
  if readyFrames==2 then camera.CameraType=Enum.CameraType.Custom end
  if readyFrames>=12 or os.clock()-started>12 then
   Run:UnbindFromRenderStep(binding);camera.CameraType=Enum.CameraType.Custom
  end
 end)
end
player.CharacterAdded:Connect(orient)
if player.Character then orient(player.Character) end
