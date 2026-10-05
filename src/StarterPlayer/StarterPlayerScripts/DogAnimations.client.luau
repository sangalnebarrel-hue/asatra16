local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local AnimationPlayer = require(ReplicatedStorage:WaitForChild("DogAnimationPlayer"))
local DogLook = require(ReplicatedStorage:WaitForChild("DogLook"))
local library = ReplicatedStorage:WaitForChild("DogAnimationClips")
local active = workspace:WaitForChild("DOGROTS_District"):WaitForChild("03_DogLine"):WaitForChild("ActiveDogs")
local tracked = {}

local function detach(model)
    local entry = tracked[model]
    if not entry then return end
    tracked[model] = nil
    for _, connection in ipairs(entry.Connections) do connection:Disconnect() end
    entry.Player:Destroy()
end

local function attach(model)
    if not model:IsA("Model") or tracked[model] then return end
    local dogId = model:GetAttribute("DogId") or model.Name
    if not library:FindFirstChild(dogId) then return end
    local animation = AnimationPlayer.new(model,dogId)
    local entry = {Player=animation,Connections={},Phase=math.random(0,7)}
    tracked[model] = entry
    local function sync()
        local name = model:GetAttribute("AnimationName")
        if typeof(name) ~= "string" or name == "" then
            if animation.Name then animation:Stop() end
            return
        end
        local started = model:GetAttribute("AnimationStartedAt") or workspace:GetServerTimeNow()
        if animation.Name ~= name or animation.StartTime ~= started then
            animation:Play(name,{StartTime=started,Speed=model:GetAttribute("AnimationSpeed") or 1,
                Looped=model:GetAttribute("AnimationLooped")})
        elseif animation.Clip then
            animation:SetOptions({Speed=model:GetAttribute("AnimationSpeed") or 1,
                Looped=model:GetAttribute("AnimationLooped")})
        end
    end
    local pending = false
    local function scheduleSync()
        if pending then return end
        pending = true
        task.defer(function()
            pending = false
            if tracked[model] == entry then sync() end
        end)
    end
    for _, attribute in ipairs({"AnimationName","AnimationStartedAt","AnimationSpeed","AnimationLooped","LocomotionSpeed"}) do
        table.insert(entry.Connections,model:GetAttributeChangedSignal(attribute):Connect(scheduleSync))
    end
    table.insert(entry.Connections,model.DescendantAdded:Connect(function(child)
        if child:IsA("Bone") then animation:RefreshRig(); scheduleSync() end
    end))
    table.insert(entry.Connections,model.DescendantRemoving:Connect(function(child)
        if child:IsA("Bone") then
            task.defer(function() if tracked[model] == entry then animation:RefreshRig() end end)
        end
    end))
    table.insert(entry.Connections,model.Destroying:Connect(function() detach(model) end))
    sync()
end

local kennels = workspace.DOGROTS_District:WaitForChild("KennelDogs")
local function watch(folder)
    folder.ChildAdded:Connect(attach)
    folder.ChildRemoved:Connect(detach)
    for _, model in ipairs(folder:GetChildren()) do attach(model) end
end
for _, folder in ipairs({active, kennels}) do watch(folder) end
-- Secret arrivals staged off the tongue (SecretReveal); the server creates the folder.
local reveals = workspace:FindFirstChild("DOGROTS_SecretReveals")
if reveals then watch(reveals) else
    local waiting
    waiting = workspace.ChildAdded:Connect(function(child)
        if child.Name == "DOGROTS_SecretReveals" and child:IsA("Folder") then waiting:Disconnect(); watch(child) end
    end)
end
-- Bone animation for every kennel and conveyor dog each frame is the heaviest client
-- loop in the game. Distant dogs update at a lower rate (gait time stays continuous).
local frame = 0
RunService.PreSimulation:Connect(function()
    frame += 1
    local now = workspace:GetServerTimeNow()
    local camera = workspace.CurrentCamera
    local origin = camera and camera.CFrame.Position
    for model, entry in pairs(tracked) do
        local interval = 1
        local root = origin and model.PrimaryPart
        if root then
            local distance = (root.Position - origin).Magnitude
            if distance > 320 then interval = 8 elseif distance > 160 then interval = 3 end
        end
        -- THE DOG's stare (DogLook): dogs turn on every frame, then hold at the usual rate.
        local body, head, target, bow, moving
        if DogLook.Current then
            local position = model.PrimaryPart and model.PrimaryPart.Position
            moving = (model:GetAttribute("LocomotionSpeed") or 0) > .1
            body, head, target, bow = DogLook.For(model, entry, position, moving)
        end
        if body then
            local look = entry.Look or {}
            look.Target, look.Body, look.Head, look.Bow = target, body, head, bow
            entry.Look = look
            entry.Player.Look = look
            -- Settled once the turn is done and the walking cap (DogLook's MoveScale) has eased.
            local cap = entry.MoveScale or 1
            if head < 1 or bow ~= 0 or body < cap - 1e-3 or cap ~= (moving and .4 or 1) then interval = 1 end
        elseif entry.Player.Look then
            entry.Player.Look = nil
            interval = 1
        end
        if interval == 1 or (frame + entry.Phase) % interval == 0 then entry.Player:Step(now) end
    end
end)
