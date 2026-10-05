-- "Every dog on the map turns and stares" at a target (THE DOG).
-- Animated dogs (conveyor, kennels) turn inside their own animation step through
-- ReplicatedStorage.DogLook. Static display dogs (yard showcases, best-finds stands,
-- the reward machine's prize, the museum's near clones) are turned here, with the same
-- bone-only DogAnimationPlayer:ApplyLook. Nothing replicates; Stop() turns everyone back.
local RS=game:GetService('ReplicatedStorage')
local Run=game:GetService('RunService')
local DogLook=require(RS:WaitForChild('DogLook'))
local Player=require(RS:WaitForChild('DogAnimationPlayer'))
local S={}
local district=workspace:WaitForChild('DOGROTS_District')

-- Static dogs: {Model, Body} where Body=false turns the head only (glass cases, niches).
local function statics()
 local list={}
 local function add(model,body)
  if model and model:IsA('Model')then table.insert(list,{Model=model,Body=body})end
 end
 local yards=district:FindFirstChild('04_PlayerYards')
 for _,yard in ipairs(yards and yards:GetChildren()or {})do
  local slots=yard:FindFirstChild('DogStorage')and yard.DogStorage:FindFirstChild('DisplaySlots')
  for _,slot in ipairs(slots and slots:GetChildren()or {})do add(slot:FindFirstChild('DisplayDog'),true)end
  local finds=yard:FindFirstChild('BestFinds',true)
  local dogSlot=finds and finds:FindFirstChild('Slots')and finds.Slots:FindFirstChild('Dog')
  if dogSlot then add(dogSlot:FindFirstChild('Exhibit'),true)end
 end
 local attraction=district:FindFirstChild('37_AttractionRefresh')
 local rig=attraction and attraction:FindFirstChild('RewardMachineRig',true)
 local prize=rig and rig:FindFirstChild('CommittedPrize')
 if prize then add(prize:FindFirstChild('WinningDog'),true)end
 add(attraction and attraction:FindFirstChild('AurionGrandPrize',true),false)
 local museum=workspace:FindFirstChild('DogDexLocalDisplays')
 for _,m in ipairs(museum and museum:GetChildren()or {})do add(m,false)end
 return list
end
-- The point a static dog turns about: GroundLocal, or the bottom of its bounding box once
-- it has parts (nil until then). Museum clones have no RootPart/PrimaryPart, so the box
-- is all they have.
local function groundOf(model)
 local ground=model:GetAttribute('GroundLocal')
 if typeof(ground)=='Vector3'then return ground end
 if not model:FindFirstChildWhichIsA('BasePart',true)then return nil end
 local cf,size=model:GetBoundingBox()
 if size.Magnitude<.01 then return nil end
 return model:GetPivot():PointToObjectSpace(cf.Position-cf.UpVector*size.Y/2)
end
-- The bones the look writes; nothing else animates a static dog, so they are reset to
-- identity (the rest pose) before each turn and when the stare ends.
local function lookBones(p)
 local bones=table.clone(p.LookHeads or {})
 if p.TopBone then table.insert(bones,p.TopBone)end
 if p.LookNeck then table.insert(bones,p.LookNeck)end
 return bones
end
local function rest(display)
 for _,bone in ipairs(display.Bones)do
  if bone.Parent then bone.Transform=CFrame.identity end
 end
end

--[[ S.Begin(target, options) → handle
 target   function() → Vector3? (where to look)
 options  Exclude (the stared-at model), Turn (seconds, default .9), Ripple (studs/s, default 140)
 handle:Bow(radians, seconds) every staring head dips together.
 handle:Stop(seconds) eases every dog back over `seconds`. ]]
function S.Begin(target,options)
 options=options or {}
 local look=DogLook.Begin({Target=target,Exclude=options.Exclude,Turn=options.Turn,Ripple=options.Ripple})
 local displays={}
 local stopped=false
 local function track(entry)
  local model=entry.Model
  if displays[model]or stopped then return end
  local id=model:GetAttribute('DogId')or model:GetAttribute('SourceDogId')or model.Name
  local ok,player=pcall(Player.new,model,id)
  if not ok or not player then return end
  local display={Player=player,Body=entry.Body,Ground=nil,State={},Look={},Phase=math.random(0,7)}
  display.Bones=lookBones(player)
  -- Bones that stream in later join the rig.
  display.Connection=model.DescendantAdded:Connect(function(o)
   if o:IsA('Bone')then player:RefreshRig();rest(display);display.Bones=lookBones(player);display.Applied=nil end
   if o:IsA('BasePart')or o:IsA('Bone')then display.Ground=nil end
  end)
  displays[model]=display
 end
 local function forget(model,display)
  display.Connection:Disconnect()
  pcall(rest,display)
  displays[model]=nil
 end
 for _,entry in ipairs(statics())do track(entry)end
 local frame,rescan=0,os.clock()
 local name='DOGROTS_SecretStare_'..string.sub(tostring(displays),-8)
 Run:BindToRenderStep(name,Enum.RenderPriority.Camera.Value-1,function()
  frame+=1
  local now=os.clock()
  -- Display dogs come and go (museum clones stream with the player, prizes change).
  if now-rescan>1.5 then rescan=now;for _,entry in ipairs(statics())do track(entry)end end
  local camera=workspace.CurrentCamera
  local origin=camera and camera.CFrame.Position
  for model,display in pairs(displays)do
   if not model.Parent then forget(model,display)
   elseif display.Player.TopBone and display.Player.TopBone.Parent then
    display.Ground=display.Ground or groundOf(model)
    local root=model.PrimaryPart
    local body,head,at,bow=DogLook.For(model,display.State,root and root.Position,false)
    if not body or not display.Ground then
     if display.Applied then rest(display);display.Applied=nil end
    else
     body=display.Body and body or 0
     -- Settled and the target barely moved: the pose holds by itself.
     local settled=head>=1 and bow==0 and body>=(display.Body and 1 or 0)
     local moved=not display.Applied or (at-display.Applied).Magnitude>.05
     local interval=1
     if origin and root then
      local distance=(root.Position-origin).Magnitude
      if distance>320 then interval=8 elseif distance>160 then interval=3 end
     end
     if not settled or (moved and (frame+display.Phase)%interval==0) then
      rest(display)
      local l=display.Look
      l.Target,l.Body,l.Head,l.Ground,l.Bow=at,body,head,display.Ground,bow
      display.Player.Look=l
      display.Player:ApplyLook()
      display.Applied=at
     end
    end
   end
  end
 end)
 local handle={}
 function handle:Bow(radians,seconds)look:Bow(radians,seconds)end
 function handle:Stop(seconds)
  if stopped then return end
  stopped=true
  look:Stop(seconds)
  task.delay((seconds or 1)+.1,function()
   Run:UnbindFromRenderStep(name)
   for model,display in pairs(displays)do forget(model,display)end
  end)
 end
 return handle
end
return S
