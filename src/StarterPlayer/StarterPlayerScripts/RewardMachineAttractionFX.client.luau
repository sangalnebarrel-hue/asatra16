local RS=game:GetService('ReplicatedStorage');local Run=game:GetService('RunService');local Tween=game:GetService('TweenService');local Debris=game:GetService('Debris');local Http=game:GetService('HttpService')
local player=game.Players.LocalPlayer;local touch=game:GetService('UserInputService').TouchEnabled
local motion=require(RS:WaitForChild('RewardMachineMotion'))
local rig=workspace:WaitForChild('DOGROTS_District'):WaitForChild('37_AttractionRefresh'):WaitForChild('RewardMachineRig')
local hooks=rig:WaitForChild('CameraHooks');local drum=rig:WaitForChild('SpinningDrum')
local center=hooks:WaitForChild('DrumCenter',60).CFrame;local focus=hooks:WaitForChild('RevealFocus',60)
local cue;local lastReceipt;local lastTick=-1;local lastSound=-1;local revealed={};local cameraSession
-- The winner's camera frames the prize until returnAt. A Secret prize (the Aurion jackpot)
-- keeps it framed for its whole arrival on the stand: its Hold + 1 s after the drum lands.
local returnAt=0;local ownFinish,ownReturn=0,0
local function revealUntil(finish)return math.abs(finish-ownFinish)<1.5 and math.max(finish+5,ownReturn)or finish+5 end
local lights={};for _,o in ipairs(rig:GetDescendants())do if o:IsA('PointLight')or o:IsA('SurfaceLight')then table.insert(lights,{o,o.Color,o.Brightness})end end
local function reduced()return touch or player:GetAttribute('ReducedMotion')==true or player:GetAttribute('WorldEventFX')=='Low'end
local function audible()local camera=workspace.CurrentCamera;return cameraSession~=nil or camera and(camera.CFrame.Position-focus.Position).Magnitude<105 end
local function tone(pitch,volume)
 if not audible()then return end
 local sound=Instance.new('Sound');sound.Name='RewardMachineChime';sound.SoundId='rbxasset://sounds/volume_slider.ogg';sound.Volume=volume or .12;sound.PlaybackSpeed=pitch;sound.RollOffMinDistance=8;sound.RollOffMaxDistance=100;sound.Parent=cameraSession and game:GetService('SoundService')or focus;sound:Play();Debris:AddItem(sound,3)
end
local function burst(result)
 if revealed[result.Receipt]then return end;revealed[result.Receipt]=true
 if not audible()then return end
 local rare=motion.UltraRare(result);local color=motion.Color(result);local low=reduced()
 for i,pitch in ipairs(rare and {1,1.25,1.5,2}or {1,1.25,1.5})do task.delay((i-1)*.12,function()tone(pitch,rare and .18 or .12)end)end
 local attachment=Instance.new('Attachment');attachment.Position=Vector3.new(0,2,0);attachment.Parent=focus
 local particles=Instance.new('ParticleEmitter');particles.Name='PrizeConfetti';particles.Texture='rbxasset://textures/particles/sparkles_main.dds';particles.Rate=0;particles.Lifetime=NumberRange.new(.7,1.5);particles.Speed=NumberRange.new(8,rare and 24 or 15);particles.Drag=3
 particles.SpreadAngle=Vector2.new(55,55);particles.Acceleration=Vector3.new(0,-14,0);particles.LightEmission=.55;particles.Color=ColorSequence.new(color);particles.Size=NumberSequence.new({NumberSequenceKeypoint.new(0,.35),NumberSequenceKeypoint.new(1,0)});particles.Parent=attachment
 particles:Emit(low and 12 or rare and 70 or 30);Debris:AddItem(attachment,2)
 for i=1,(low and 1 or rare and 3 or 2)do
  local ring=Instance.new('Part');ring.Name='PrizeRing';ring.Shape=Enum.PartType.Cylinder;ring.Anchored=true;ring.CanCollide=false;ring.CanTouch=false;ring.CanQuery=false;ring.CastShadow=false;ring.Material=Enum.Material.Neon;ring.Color=color;ring.Transparency=.55;ring.Size=Vector3.new(.08,3,3)
  ring.CFrame=CFrame.new(focus.Position+Vector3.new(0,.2+i*.07,0))*CFrame.Angles(0,0,math.pi/2);ring.Parent=rig
  Tween:Create(ring,TweenInfo.new(.75+i*.15,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{Size=Vector3.new(.03,rare and 30 or 19,rare and 30 or 19),Transparency=1}):Play();Debris:AddItem(ring,1.5)
 end
 for _,row in ipairs(lights)do if row[1].Parent then row[1].Color=color;row[1].Brightness=math.min(3,row[3]+1.3);Tween:Create(row[1],TweenInfo.new(2),{Color=row[2],Brightness=row[3]}):Play()end end
end
local function receive(value)
 if type(value)~='table'or type(value.Presentation)~='table'or not value.Receipt or value.Receipt==lastReceipt then return end
 -- Do not replay old celebrations for a player arriving long after the spin.
 if workspace:GetServerTimeNow()>value.Presentation.StartedAt+value.Presentation.Duration+2 then return end
 cue=value;lastReceipt=value.Receipt;lastTick=-1
 if value.WinnerUserId==player.UserId then
  player:SetAttribute('RewardMachinePendingAt',nil);player:SetAttribute('RewardMachinePendingRequest',nil)
  local hold=motion.UltraRare(value)and motion.ArrivalHold(value)or 0
  ownFinish=value.Presentation.StartedAt+value.Presentation.Duration;ownReturn=ownFinish+(hold>0 and hold+1 or 5)
  returnAt=math.max(returnAt,ownReturn)
 end
end
RS:WaitForChild('RewardMachinePresentation').OnClientEvent:Connect(receive)
local function readSnapshot()local raw=rig:GetAttribute('SpinInfo');if raw then local ok,value=pcall(Http.JSONDecode,Http,raw);if ok then receive(value)end end end
rig:GetAttributeChangedSignal('SpinInfo'):Connect(readSnapshot);readSnapshot()
local accumulator=0
Run.Heartbeat:Connect(function(dt)
 accumulator+=dt;if accumulator<(touch and 1/30 or 1/60)then return end;accumulator=0
 local camera=workspace.CurrentCamera;if not camera then return end
 if not cameraSession and(camera.CFrame.Position-center.Position).Magnitude>190 then return end
 local now=workspace:GetServerTimeNow()
 if cue then
  local p=cue.Presentation;local t=math.clamp((now-p.StartedAt)/p.Duration,0,1)
  local a=motion.Angle(p.StartAngle,p.PrizeIndex,t);drum:PivotTo(center*CFrame.Angles(0,0,a))
  local tick=math.floor(a/(math.pi*2/motion.PrizeCount))
  if t>0 and t<1 and tick~=lastTick and os.clock()-lastSound>(touch and .18 or .09)then lastSound=os.clock();tone(.7+math.sin(math.pi*t)*.8,.07)end;lastTick=tick
  if t>=1 then burst(cue);cue=nil end
 else
  local pending=tonumber(player:GetAttribute('RewardMachinePendingAt'))or 0
  if pending>0 and now>=pending and now-pending<2 then
   -- Prize index is not known yet. Use only the common six-turn component for
   -- the first network frames; the authoritative cue then lands on the real prize.
   local t=math.clamp((now-pending)/motion.Duration,0,.35);local start=tonumber(rig:GetAttribute('RestAngle'))or 0
   local a=start+math.pi*2*motion.Turns*motion.Progress(t);drum:PivotTo(center*CFrame.Angles(0,0,a))
  elseif not reduced()then
   for i,row in ipairs(lights)do if row[1].Parent then row[1].Brightness=row[3]*(.9+.1*math.sin(now*1.8+i*.75))end end
  end
 end
end)

-- The wheel is the presentation: a small control rail never covers it.
local playerGui=player:WaitForChild('PlayerGui')
local gui=playerGui:FindFirstChild('ScreenGui')
while not gui do
 local child=playerGui.ChildAdded:Wait()
 if child.Name=='ScreenGui' then gui=child end
end
local GuiService=game:GetService('GuiService')
local function boxPoints(points,cf,size)
 for _,x in ipairs({-1,1})do for _,y in ipairs({-1,1})do for _,z in ipairs({-1,1})do
  table.insert(points,cf:PointToWorldSpace(Vector3.new(size.X*x,size.Y*y,size.Z*z)/2))
 end end end
end
local function cameraGeometry()
 local main,wheel,prize,boards={},{},{},{}
 for _,name in ipairs({'ArchitecturalBase','GrandArch','WinningFrame','PawCrown','RewardVitrines','WorldResult','CapsuleHousing'})do
  local model=rig:FindFirstChild(name)
  if model then
   if model:IsA('BasePart')then boxPoints(main,model.CFrame,model.Size)
   else local cf,size=model:GetBoundingBox();boxPoints(main,cf,size);if name=='WinningFrame'then boxPoints(wheel,cf,size)end end
  end
 end
 -- A fixed envelope prevents the camera breathing as an eight-sector wheel rotates.
 local radius=(rig:GetAttribute('WheelRadius')or 24)+2.5
 for _,points in ipairs({main,wheel})do
  boxPoints(points,center,Vector3.new(radius*2,radius*2,8.2))
  boxPoints(points,center*CFrame.new(0,0,-3.5),Vector3.new(36,36,7))
 end
 local stage=rig:FindFirstChild('RevealStage')
 if stage then for _,part in ipairs(stage:GetDescendants())do
  if part:IsA('BasePart')and part.Transparency<1 and part.Name~='ProcessionCarpet'and part.Name~='CarpetGoldEdge'then
   boxPoints(main,part.CFrame,part.Size);boxPoints(prize,part.CFrame,part.Size)
  end
 end end
 local spawn=hooks:FindFirstChild('RewardSpawn')
 boxPoints(prize,(spawn and spawn.CFrame or focus.CFrame)*CFrame.new(0,6,0),Vector3.new(12,12,12))
 table.insert(prize,focus.Position+Vector3.new(0,15,0))
 for _,name in ipairs({'StatusBoard','TicketRules'})do local board=rig:FindFirstChild(name);if board then boxPoints(boards,board.CFrame,board.Size)end end
 return {Main=main,Wheel=wheel,Prize=prize,Boards=boards}
end
local function cameraRect(camera)
 local w,h=math.max(1,camera.ViewportSize.X),math.max(1,camera.ViewportSize.Y)
 local originX,originY,left,top,right,bottom=0,0,0,58,w,h
 local ok,full,safe=pcall(function()return GuiService:GetInsetArea(Enum.ScreenInsets.None),GuiService:GetInsetArea(Enum.ScreenInsets.CoreUISafeInsets)end)
 if ok then
  -- AbsolutePosition and these rectangles use the same Core UI origin. FOV
  -- uses the full render area, which can be wider than Camera.ViewportSize.
  originX,originY=full.Min.X,full.Min.Y;w,h=full.Max.X-originX,full.Max.Y-originY
  left,top,right,bottom=safe.Min.X-originX,safe.Min.Y-originY,safe.Max.X-originX,safe.Max.Y-originY
 end
 local controls=gui:FindFirstChild('RewardMachineWorldPanel')
 if controls and controls.Visible~=false and controls.AbsoluteSize.Y>0 then bottom=math.min(bottom,controls.AbsolutePosition.Y-originY-12)
 else bottom-=((right-left)>=628 and 94 or 132)+26 end
 -- The centered compact toast occupies the same horizontal space as the prize.
 local toast=gui:FindFirstChild('RewardMachineRewardToast')
 if toast and toast.Visible~=false then bottom=math.min(bottom,toast.AbsolutePosition.Y-originY-12)end
 left+=12;right-=12;top+=12
 bottom=math.max(top+80,bottom)
 return {W=w,H=h,Left=left,Right=right,Top=top,Bottom=bottom}
end
local function fitCamera(points,rect,origin,elevated)
 local low,high=Vector3.new(math.huge,math.huge,math.huge),Vector3.new(-math.huge,-math.huge,-math.huge)
 for _,point in ipairs(points)do low=low:Min(point);high=high:Max(point)end
 origin=origin or(low+high)/2
 -- A low stage must be viewed from above. Merely moving a horizontal camera
 -- down to reserve the bottom UI can put that camera beneath the terrain.
 local outward=Vector3.new(1,elevated and .65 or .055,.04).Unit
 local basis=CFrame.lookAt(Vector3.zero,-outward);local right,up=basis.RightVector,basis.UpVector
 local tangent=math.tan(math.rad(52/2));local horizontal=tangent*rect.W/rect.H
 local xmin,xmax=2*rect.Left/rect.W-1,2*rect.Right/rect.W-1
 local ymin,ymax=1-2*rect.Bottom/rect.H,1-2*rect.Top/rect.H
 local cx,cy=(xmin+xmax)/2,(ymin+ymax)/2;local distance=1
 for _,point in ipairs(points)do
  local q=point-origin;local x,y,z=q:Dot(right),q:Dot(up),q:Dot(outward)
  distance=math.max(distance,z+1,
   (x/horizontal+xmax*z)/math.max(.01,xmax-cx),(-x/horizontal-xmin*z)/math.max(.01,cx-xmin),
   (y/tangent+ymax*z)/math.max(.01,ymax-cy),(-y/tangent-ymin*z)/math.max(.01,cy-ymin))
 end
 distance*=1.02
 local target=origin-right*(cx*distance*horizontal)-up*(cy*distance*tangent)
 return {CFrame=CFrame.lookAt(target+outward*distance,target),Target=target,Distance=distance,Origin=origin}
end
local function showInformationBoards(visible)
 if not cameraSession or cameraSession.BoardsVisible==visible then return end
 cameraSession.BoardsVisible=visible;cameraSession.BoardRestore=cameraSession.BoardRestore or{}
 for _,name in ipairs({'StatusBoard','TicketRules'})do
  local board=rig:FindFirstChild(name)
  if board then
   if not cameraSession.BoardRestore[board]then cameraSession.BoardRestore[board]={LocalTransparencyModifier=board.LocalTransparencyModifier}end
   board.LocalTransparencyModifier=visible and cameraSession.BoardRestore[board].LocalTransparencyModifier or 1
   for _,child in ipairs(board:GetDescendants())do if child:IsA('SurfaceGui')then
    if not cameraSession.BoardRestore[child]then cameraSession.BoardRestore[child]={Enabled=child.Enabled}end
    child.Enabled=visible and cameraSession.BoardRestore[child].Enabled or false
   end end
  end
 end
end
local function hidePrizeLabel(object)
 if not cameraSession or not object:IsA('BillboardGui')then return end
 local anchor=object.Parent;local prize=anchor and anchor.Parent
 if not anchor or anchor.Name~='RewardLabel'or not prize or prize.Name~='CommittedPrize'or prize.Parent~=rig then return end
 local saved=cameraSession.LabelRestore
 if not saved[object]then saved[object]={Enabled=object.Enabled}end
 object.Enabled=false
end
rig.DescendantAdded:Connect(hidePrizeLabel)
rig.DescendantRemoving:Connect(function(object)
 local saved=cameraSession and cameraSession.LabelRestore[object]
 if saved then object.Enabled=saved.Enabled;cameraSession.LabelRestore[object]=nil end
end)
local function cameraOpen()
 if not gui:GetAttribute('RewardMachineWorldOpen') then return end
 local camera=workspace.CurrentCamera;if not camera or cameraSession then return end
 cameraSession={Camera=camera,Type=camera.CameraType,Subject=camera.CameraSubject,FieldOfView=camera:GetAttribute('SecretZoom')or camera.FieldOfView,CFrame=camera.CFrame,Focus=camera.Focus,Geometry=cameraGeometry(),Snap=true,LabelRestore={}}
 local prize=rig:FindFirstChild('CommittedPrize');if prize then for _,object in ipairs(prize:GetDescendants())do hidePrizeLabel(object)end end
 -- Keep a reveal that is still running for this player (a Studio preview opens the machine
 -- after its cue arrived); anything older is over.
 camera.CameraType=Enum.CameraType.Scriptable;returnAt=ownReturn>workspace:GetServerTimeNow()and ownReturn or 0
end
local function cameraClose()
 local previous=cameraSession;if not previous then return end;cameraSession=nil
 for object,properties in pairs(previous.BoardRestore or{})do if object.Parent then for key,value in pairs(properties)do object[key]=value end end end
 for object,properties in pairs(previous.LabelRestore)do if object.Parent then object.Enabled=properties.Enabled end end
 local camera=workspace.CurrentCamera
 if camera==previous.Camera then
  camera.FieldOfView=previous.FieldOfView;camera.Focus=previous.Focus;camera.CFrame=previous.CFrame
  local hum=player.Character and player.Character:FindFirstChildOfClass('Humanoid')
  camera.CameraSubject=hum or previous.Subject;camera.CameraType=hum and Enum.CameraType.Custom or previous.Type
 end
end
gui:GetAttributeChangedSignal('RewardMachineWorldOpen'):Connect(function()
 if gui:GetAttribute('RewardMachineWorldOpen')then cameraOpen()else cameraClose()end
end)
gui:GetAttributeChangedSignal('RewardMachineActiveUntil'):Connect(function()
 local finish=gui:GetAttribute('RewardMachineActiveUntil')
 if type(finish)=='number'and finish>workspace:GetServerTimeNow()-1 then returnAt=revealUntil(finish)
 elseif finish==0 then returnAt=0 end -- A failed activation: back to the wheel.
end)
player.CharacterRemoving:Connect(cameraClose)
cameraOpen()
Run:BindToRenderStep('RewardMachineWorldCamera',Enum.RenderPriority.Camera.Value+1,function(dt)
 if not cameraSession then return end
 local camera=workspace.CurrentCamera;if camera~=cameraSession.Camera then cameraClose();return end
 -- ownFinish also covers a cue this client did not request (a Studio preview).
 local now=workspace:GetServerTimeNow();local finish=math.max(tonumber(gui:GetAttribute('RewardMachineActiveUntil'))or 0,ownFinish)
 local revealing=finish>0 and now>finish+.45 and now<returnAt
 local rect=cameraRect(camera)
 local rectKey=table.concat({rect.W,rect.H,rect.Left,rect.Right,rect.Top,rect.Bottom},':')
 local key=rectKey..tostring(revealing)
 if cameraSession.FitKey~=key then
  if cameraSession.RectKey~=rectKey then cameraSession.Snap=true end
  local geometry=cameraSession.Geometry
  -- The close view owns smaller screens. Architecture remains visible during
  -- normal play; only spacious desktops can show it all without shrinking the wheel.
  local wideView=rect.H>=900 and rect.Right-rect.Left>=900
  local points=revealing and geometry.Prize or wideView and geometry.Main or geometry.Wheel
  local fit=fitCamera(points,rect,nil,revealing);local includeBoards=false
  if not revealing and wideView then
   local withBoards=table.clone(points);for _,point in ipairs(geometry.Boards)do table.insert(withBoards,point)end
   local wide=fitCamera(withBoards,rect,fit.Origin)
   if wide.Distance<=fit.Distance*1.12 then fit=wide;includeBoards=true end
  end
  showInformationBoards(includeBoards)
  cameraSession.Fit=fit;cameraSession.FitKey=key;cameraSession.RectKey=rectKey
 end
 local fit=cameraSession.Fit;local alpha=(cameraSession.Snap or reduced())and 1 or 1-math.exp(-dt*3.5);cameraSession.Snap=false
 camera.CFrame=camera.CFrame:Lerp(fit.CFrame,alpha);camera.Focus=CFrame.new(fit.Target)
 camera.FieldOfView=camera.FieldOfView+(52-camera.FieldOfView)*alpha
end)
