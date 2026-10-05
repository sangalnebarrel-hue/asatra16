local Players = game:GetService("Players")
local Storage = game:GetService("ServerStorage")
local Replicated = game:GetService("ReplicatedStorage")
local map = workspace:WaitForChild("DOGROTS_District")
local yards = map:WaitForChild("04_PlayerYards")
local residents = map:WaitForChild("KennelDogs")
local templates = Storage:WaitForChild("DogTemplates")
local remote = Replicated:WaitForChild("DogKennelRequest")
local open = Replicated:WaitForChild("DogKennelOpen")
local Runtime=require(script.Parent.Economy.Runtime)
local Http=game:GetService("HttpService")
local Definitions=require(Replicated.DogEconomy.DogDefinitions)
local Rig=require(Replicated.DogRig)
local Animation=require(Replicated.DogAnimationPlayer)
local Service = {}
local cooldown = {}
local connections = {}

local function yardFor(player)
    for _, yard in ipairs(yards:GetChildren()) do
        if yard:GetAttribute("OwnerUserId") == player.UserId then return yard end
    end
end
local function entryFor(player, uid)
    local inventory = player:FindFirstChild("DogInventory")
    local entry = inventory and inventory:FindFirstChild(uid)
    if entry and entry:IsA("StringValue") and entry:GetAttribute("OwnerUserId") == player.UserId then return entry end
end
local function clearEntry(entry)
    local uid = entry.Name
    local owner = entry:GetAttribute("OwnerUserId")
    for _, dog in ipairs(residents:GetChildren()) do
        if dog:GetAttribute("DogUid") == uid and dog:GetAttribute("OwnerUserId") == owner then dog:Destroy() end
    end
    for _, yard in ipairs(yards:GetChildren()) do
        for _, slot in ipairs(yard:GetChildren()) do
            if slot:GetAttribute("AssignedDogUid") == uid and slot:GetAttribute("AssignedOwnerUserId") == owner then
                slot:SetAttribute("AssignedDogUid", nil)
                slot:SetAttribute("AssignedOwnerUserId", nil)
                slot:SetAttribute("AssignedDogName", nil)
            end
        end
    end
    entry:SetAttribute("AssignedSlot", "")
    entry:SetAttribute("State", "Inventory")
end
local function prepare(entry, slot)
    local id = entry:GetAttribute("DogId")
    local template = templates:FindFirstChild(Definitions[id] and Definitions[id].VisualAsset or id or "")
    local floor = slot:FindFirstChild("KennelFloor")
    local back = slot:FindFirstChild("KennelBack")
    if not template or not template:IsA("Model") or not floor or not back then return nil end
    local dog = template:Clone()
    local digSize=slot:GetAttribute("DigSize") or Vector3.new(12,.4,12)
    local usableWidth=math.max(2, math.min(digSize.X,digSize.Z)-2)
    local prepared=Rig.Prepare(dog, Vector3.new(usableWidth,4.2,usableWidth))
    if not prepared then dog:Destroy();return nil end
    local root,low,high,ground=prepared.Root,prepared.Low,prepared.High,prepared.Ground
    for _,child in ipairs(dog:GetDescendants()) do
        if child:IsA("ProximityPrompt") then child:Destroy() end
    end
    local excavation=slot:FindFirstChild("DarkExcavation")
    local center=slot:GetAttribute("DigCenter") or (excavation and excavation.Position)
    if typeof(center)~="Vector3"then dog:Destroy();return nil end
    local forward=center-floor.Position;forward=Vector3.new(forward.X,0,forward.Z)
    if forward.Magnitude<.01 then forward=floor.Position-back.Position;forward=Vector3.new(forward.X,0,forward.Z)end
    if forward.Magnitude < .01 then forward=Vector3.new(0,0,-1) end
    forward=forward.Unit
    local halfExtent=(math.abs(forward.X)*digSize.X+math.abs(forward.Z)*digSize.Z)/2
    local bodyDepth=high.Z-low.Z
    local inset=math.max(0,halfExtent-bodyDepth/2-1)
    local position=center-forward*inset
    local surface=excavation and (excavation.Position.Y+excavation.Size.Y/2) or (center.Y+digSize.Y/2)
    position=Vector3.new(position.X,surface+.04,position.Z)
    dog:PivotTo(CFrame.new(position)*CFrame.lookAt(Vector3.zero,forward)*CFrame.new(-ground))
    dog.Name=entry.Name
    dog:SetAttribute("DogId",id); dog:SetAttribute("DogUid",entry.Name)
    dog:SetAttribute("OwnerUserId",entry:GetAttribute("OwnerUserId"))
    dog:SetAttribute("AssignedSlot",slot.Name); dog:SetAttribute("State","Resting")
    dog:SetAttribute("GroundLocal",ground)
    dog:SetAttribute("AnimationStartedAt",workspace:GetServerTimeNow())
    dog:SetAttribute("AnimationLooped",true)
    dog:SetAttribute("AnimationName",Animation.ResolveName(id,"Idle") or "")
    local anchor=Instance.new("Attachment");anchor.Name="SleepLabelAnchor"
    anchor.Position=root.CFrame:PointToObjectSpace(position+Vector3.new(0,4.8,0));anchor.Parent=root
    local label=Instance.new("BillboardGui");label.Name="SleepLabel";label.Adornee=anchor
    label.Size=UDim2.fromOffset(150,44);label.MaxDistance=55;label.AlwaysOnTop=false;label.Parent=dog
    local text=Instance.new("TextLabel");text.Size=UDim2.fromScale(1,1);text.BackgroundTransparency=1
    text.Font=Enum.Font.GothamBold;text.TextSize=16;text.TextColor3=Color3.fromRGB(205,230,255)
    local dogName=entry:GetAttribute("DisplayName") or entry.Value
    dog:SetAttribute("DogName",dogName)
    text.TextStrokeTransparency=.4;text.Text=dogName.."\nDIGGING";text.Parent=label
    return dog
end


function Service.Reconcile(player,profile)
    local yard=yardFor(player)
    if not yard then return end
    for _,slot in ipairs(yard:GetChildren()) do
        if slot.Name:match("^DigSlot_%d+$") then
            slot:SetAttribute("AssignedDogUid",nil);slot:SetAttribute("AssignedOwnerUserId",nil);slot:SetAttribute("AssignedDogName",nil)
        end
    end
    for _,model in ipairs(residents:GetChildren()) do
        if model:GetAttribute("OwnerUserId")==player.UserId then
            local dog=profile.Dogs[model:GetAttribute("DogUid")]
            if not dog or dog.AssignedSlot=="" or dog.AssignedSlot~=model:GetAttribute("AssignedSlot") then model:Destroy() end
        end
    end
    for uid,d in pairs(profile.Dogs) do if d.AssignedSlot~="" then
        local slot=yard:FindFirstChild(d.AssignedSlot);local entry=player.DogInventory:FindFirstChild(uid)
        if slot and entry then
            local model=residents:FindFirstChild(uid)
            if not model then
                local ok,result=pcall(prepare,entry,slot)
                if ok and result then model=result;model.Parent=residents else warn("Kennel asset unavailable",d.DogId) end
            end
            if model then
                model:SetAttribute("NextWorkAt",d.NextWorkAt or 0);model:SetAttribute("Variant",d.Variant);model:SetAttribute("Mastery",d.Mastery)
                model:SetAttribute("EquippedCosmetic",profile.EquippedCosmetic)
                slot:SetAttribute("AssignedDogUid",uid);slot:SetAttribute("AssignedOwnerUserId",player.UserId);slot:SetAttribute("AssignedDogName",d.DisplayName)
            end
        end
    end end
end
function Service.Handle(player,action,uid,slotName)
    if not Runtime.Ready(player) then return false,"Profile loading" end
    if not Runtime.Allow(player,.5) then return false,"Please wait" end
    if action~="Assign" and action~="Remove" then return false,"Invalid kennel operation" end
    if action=="Assign" then
        local yard=yardFor(player);local slot=type(slotName)=="string" and yard and yard:FindFirstChild(slotName)
        local entry=type(uid)=="string" and entryFor(player,uid)
        if not slot or not entry then return false,"Dog or kennel unavailable" end
        local ok,probe=pcall(prepare,entry,slot)
        if not ok or not probe then return false,"Dog asset unavailable" end
        probe:Destroy()
    end
    local ok,result=Runtime.Request(player,action,{Uid=uid,Slot=slotName},Http:GenerateGUID(false):gsub("%-",""))
    if ok then Runtime.Refresh(player) end
    return ok,type(result)=="table" and result.Message or result
end
function Service.UpdateWorkVisuals()
 local now=os.time();local duration=require(script.Parent.Economy.Config).Work.Duration
 for _,model in ipairs(residents:GetChildren())do
  local remaining=math.max(0,(model:GetAttribute("NextWorkAt") or now+100)-now)
  local working=remaining<=duration and remaining>0
  local state=working and "DIGGING" or "RESTING"
  local id=model:GetAttribute("DogId") or ""
  local animation=Animation.ResolveName(id,working and "Work" or "Idle") or Animation.ResolveName(id,"Idle") or ""
  model:SetAttribute("AnimationSpeed",working and Animation.GetWorkSpeed(id,animation,duration) or 1)
  -- The saved deadline and GetServerTimeNow both use Unix seconds. Joining or
  -- streaming halfway through work must resume its phase, not restart the dive.
  local started=working and ((model:GetAttribute("NextWorkAt") or now)-duration) or workspace:GetServerTimeNow()
  if model:GetAttribute("AnimationName")~=animation or (working and model:GetAttribute("AnimationStartedAt")~=started) then
   model:SetAttribute("AnimationStartedAt",started);model:SetAttribute("AnimationName",animation)
  end
  model:SetAttribute("WorkState",state)
  local label=model:FindFirstChild("SleepLabel");local text=label and label:FindFirstChildWhichIsA("TextLabel")
  -- Keep the dog's name on the first line; the status used to replace it after one update.
  local name=model:GetAttribute("DogName")
  if text then text.Text=(name and name~="" and name.."\n" or "")..state..(working and "" or string.format(" · READY IN %ds",remaining))end
 end
end
function Service.Start()
    if Service.Started then return end;Service.Started=true
    Runtime.Kennels=Service
    remote.OnServerInvoke=Service.Handle
    Players.PlayerRemoving:Connect(function(player)
        for _,dog in ipairs(residents:GetChildren())do if dog:GetAttribute("OwnerUserId")==player.UserId then dog:Destroy()end end
    end)
    for _,yard in ipairs(yards:GetChildren()) do
        yard:GetAttributeChangedSignal("OwnerUserId"):Connect(function()
            task.defer(function()
                local player=Players:GetPlayerByUserId(yard:GetAttribute("OwnerUserId") or 0)
                if player then Runtime.Refresh(player) end
            end)
        end)
        for _,slot in ipairs(yard:GetChildren()) do
            local floor=slot:FindFirstChild("KennelFloor");local back=slot:FindFirstChild("KennelBack")
            if slot.Name:match("^DigSlot_%d+$") and floor and back then
                local a=Instance.new("Attachment");a.Name="KennelInteraction"
                local direction=(floor.Position-back.Position).Unit
                a.Position=floor.CFrame:PointToObjectSpace(floor.Position+direction*3.8+Vector3.new(0,1.5,0));a.Parent=floor
                local prompt=Instance.new("ProximityPrompt");prompt.ActionText="MANAGE";prompt.ObjectText="DIG KENNEL "..slot.Name:match("%d+$")
                prompt.MaxActivationDistance=10;prompt.RequiresLineOfSight=false;prompt.Parent=a
                prompt.Enabled=slot:GetAttribute("Unlocked")~=false
                prompt.Triggered:Connect(function(player)
                    if slot:GetAttribute("Unlocked")==false then return end
                    local root=player.Character and player.Character:FindFirstChild("HumanoidRootPart")
                    if yard:GetAttribute("OwnerUserId")==player.UserId and root and (root.Position-a.WorldPosition).Magnitude<=14 and Runtime.Allow(player,1) then open:FireClient(player,slot.Name) end
                end)
            end
        end
    end
    Runtime.RefreshAll()
    print("DOGROTS_KENNELS_READY: persistent dig assignments")
end
return Service
