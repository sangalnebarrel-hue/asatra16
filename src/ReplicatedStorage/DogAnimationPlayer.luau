-- Sampled source motion in the imported Bone.CFrame bind space.
-- Clips are shared; playback, transitions and recovery belong to each model.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Library = ReplicatedStorage:WaitForChild("DogAnimationClips")
local WalkGait = require(ReplicatedStorage:WaitForChild("DogWalkGait"))
local Player = {}
Player.__index = Player
local cache = {}
local roleCandidates = {
    Idle = {"Idle", "IDLE", "Sleep", "Idle_Day", "Idle_Night"},
    Walk = {"Walk", "WALK", "Waddle", "Levitate_Walk"},
    Work = {"DigLoop", "DIG_LOOP", "Dig_Loop", "Dig", "DIG_WAVE", "Dig_Cast", "Drinking"},
}
local function finite(n) return type(n) == "number" and n == n and math.abs(n) < math.huge end
local function smooth(a) a = math.clamp(a, 0, 1); return a * a * (3 - 2 * a) end
local liftCache = setmetatable({}, {__mode = "k"})

function Player.ResolveName(dogId, role)
    local folder = Library:FindFirstChild(dogId)
    if not folder then return nil end
    local mapped = folder:GetAttribute(role .. "Clip")
    if mapped and folder:FindFirstChild(mapped) then return mapped end
    for _, name in ipairs(roleCandidates[role] or {role}) do
        local source = folder:FindFirstChild(name)
        if source and source:IsA("ModuleScript") then return name end
    end
    return nil
end

local function loadClip(dogId, name)
    local folder = Library:FindFirstChild(dogId)
    if not folder then return nil end
    local resolved = Player.ResolveName(dogId, name) or name
    local source = folder:FindFirstChild(resolved)
    if not source or not source:IsA("ModuleScript") then return nil end
    if cache[source] then return cache[source] end
    local ok, raw = pcall(require, source)
    if not ok or type(raw) ~= "table" or not finite(raw.duration) or raw.duration <= 0
        or not finite(raw.fps) or raw.fps <= 0 or type(raw.tracks) ~= "table" then
        warn("Invalid dog clip", dogId, resolved)
        return nil
    end
    local clip = {Duration = raw.duration, Looped = raw.loop == true, FPS = raw.fps,
        Tracks = {}, Hidden = raw.hidden, SourceName = resolved}
    for bone, values in pairs(raw.tracks) do
        local frames = table.create(#values)
        for i, value in ipairs(values) do
            if #value ~= 7 then return nil end
            for _, n in ipairs(value) do if not finite(n) then return nil end end
            local q = math.sqrt(value[4]^2 + value[5]^2 + value[6]^2 + value[7]^2)
            if q < .00001 then return nil end
            frames[i] = CFrame.new(value[1], value[2], value[3], value[4]/q, value[5]/q, value[6]/q, value[7]/q)
        end
        if #frames > 0 then clip.Tracks[bone] = frames end
    end
    cache[source] = clip
    return clip
end

function Player.GetWorkSpeed(dogId, name, workDuration)
    local clip = loadClip(dogId, name)
    if not clip or clip.Looped or not finite(workDuration) or workDuration <= 0 then return 1 end
    local recovery = math.clamp(clip.Duration * .2, .2, .6)
    -- Complete the authored action AND its recovery before the work window ends.
    -- Shorter actions keep their original cadence; true loops keep their speed.
    return math.max(1, (clip.Duration + recovery) / workDuration)
end

function Player.new(model, dogId)
    local self = setmetatable({Model = model, DogId = dogId or model:GetAttribute("DogId") or model.Name,
        Bones = {}, BoneGroups = {}, AllBones = {}, HiddenBones = {}}, Player)
    self:RefreshRig()
    return self
end

function Player:RefreshRig()
    table.clear(self.Bones); table.clear(self.BoneGroups); table.clear(self.AllBones)
    for _, child in ipairs(self.Model:GetDescendants()) do
        if child:IsA("Bone") then
            self.Bones[child.Name] = self.Bones[child.Name] or child
            local group = self.BoneGroups[child.Name] or {}
            self.BoneGroups[child.Name] = group
            table.insert(group, child); table.insert(self.AllBones, child)
        end
    end
    local depths = {}
    for _, bone in ipairs(self.AllBones) do
        local ancestor, depth = bone.Parent, 0
        while ancestor and ancestor ~= self.Model do depth += 1; ancestor = ancestor.Parent end
        depths[bone] = depth
    end
    table.sort(self.AllBones, function(a,b) return depths[a] < depths[b] end)
    -- Bones can stream in after the first measurement; measure again with the full rig.
    liftCache[self.Model] = nil
    if self.Clip and Player.ResolveName(self.DogId, "Work") == self.Clip.SourceName then self.Lift = self:ComputeLift(self.Clip) end
    if self.Clip then
        local previous=self.Gait
        self.Gait=WalkGait.new(self)
        if self.Gait and previous then
            for _,key in ipairs({"Phase","LastTime","FitSpeed","FitFrequency","RollDistance"}) do self.Gait[key]=previous[key] end
        end
    end
end

function Player:GetClipNames()
    local names = {}
    local folder = Library:FindFirstChild(self.DogId)
    if folder then
        for _, source in ipairs(folder:GetChildren()) do
            if source:IsA("ModuleScript") then table.insert(names, source.Name) end
        end
    end
    table.sort(names)
    return names
end

function Player:Stop()
    self.Clip, self.Name, self.BlendFrom = nil, nil, nil
    self.Gait = nil
    table.clear(self.HiddenBones)
    for _, bone in ipairs(self.AllBones) do
        if bone.Parent then bone.Transform = CFrame.identity end
    end
end

function Player:SetOptions(options)
    local speed = finite(options.Speed) and math.clamp(options.Speed, .05, 5) or 1
    if self.Speed and self.Speed ~= speed then
        local elapsed = math.max(0, workspace:GetServerTimeNow() - self.StartTime)
        self.PhaseOffset = (self.PhaseOffset or 0) + elapsed * (self.Speed - speed)
    end
    self.Speed = speed
    self.Looped = if options.Looped == nil then self.Clip.Looped else options.Looped == true
    -- A one-shot has an authored exit pose. Preserve the entire action, then
    -- recover smoothly before repeating it in a kennel (never teleport at wrap).
    self.Recovery = if self.Looped and not self.Clip.Looped then math.clamp(self.Clip.Duration * .2, .2, .6) else 0
end

-- Some dig clips lower the whole rig (root and hind paws) below the bind pose, which
-- pushed those dogs into the ground while digging. Measure, per frame, how far the hind
-- paws drop below their resting height and lift the rig by that amount. Deliberate
-- dives (sharks swimming through the dirt) drop far deeper and are left untouched.
function Player:ComputeLift(clip)
    local byModel = liftCache[self.Model]
    if byModel and byModel[clip] ~= nil then return byModel[clip] or nil end
    byModel = byModel or {}; liftCache[self.Model] = byModel
    local ok, lift = pcall(function()
        local pivot = self.Model:GetPivot()
        local baseScale = self.Model:GetAttribute("AnimationBaseScale") or 1
        local scale = self.Model:GetScale() / math.max(baseScale, .00001)
        local bones = {}
        for _, bone in ipairs(self.AllBones) do if bone.Parent then table.insert(bones, bone) end end
        if #bones < 4 then return false end
        local function pose(frame)
            local world = {}
            for _, bone in ipairs(bones) do
                local parent = bone.Parent
                local parentFrame = world[parent] or (parent:IsA("BasePart") and parent.CFrame) or nil
                if not parentFrame then return nil end
                local transform = CFrame.identity
                local frames = frame and clip.Tracks[bone.Name]
                if frames then
                    local p = frames[math.min(frame, #frames)]
                    transform = CFrame.new(p.Position * scale) * p.Rotation
                end
                world[bone] = parentFrame * bone.CFrame * transform
            end
            return world
        end
        local rest = pose(nil)
        if not rest then return false end
        local low, high = math.huge, -math.huge
        local candidates = {}
        for _, bone in ipairs(bones) do
            local p = pivot:PointToObjectSpace(rest[bone].Position)
            low, high = math.min(low, p.Y), math.max(high, p.Y)
            if bone.Parent:IsA("Bone") then table.insert(candidates, {Bone = bone, Y = p.Y, Z = p.Z}) end
        end
        local height = math.max((self.Model:GetAttribute("VisualSize") or Vector3.new(0, high - low, 0)).Y, .1)
        if #candidates < 4 then return false end
        table.sort(candidates, function(a, b) return a.Y < b.Y end)
        local paws = {candidates[1], candidates[2], candidates[3], candidates[4]}
        table.sort(paws, function(a, b) return a.Z > b.Z end)
        local hind = {paws[1], paws[2]}
        local frameCount = 0
        for _, frames in pairs(clip.Tracks) do frameCount = math.max(frameCount, #frames) end
        local values, worst = table.create(frameCount, 0), 0
        for f = 1, frameCount do
            local world = pose(f)
            if not world then return false end
            -- Both hind paws must be below rest: one paw scooping dirt is a normal dig.
            local drop = math.huge
            for _, paw in ipairs(hind) do
                drop = math.min(drop, paw.Y - pivot:PointToObjectSpace(world[paw.Bone].Position).Y)
            end
            values[f] = math.max(0, drop - height * .01)
            worst = math.max(worst, values[f])
        end
        if worst < height * .02 or worst > height * .25 then return false end
        return values
    end)
    byModel[clip] = ok and lift or false
    return byModel[clip] or nil
end

function Player:Play(name, options)
    options = options or {}
    local clip = loadClip(self.DogId, name)
    if not clip then return false end
    local previous = self.Clip ~= nil
    local blend = {}
    for _, bone in ipairs(self.AllBones) do
        if bone.Parent and not self.HiddenBones[bone] then blend[bone] = bone.Transform end
    end
    self.Clip, self.Name = clip, name
    self.StartTime = finite(options.StartTime) and options.StartTime or workspace:GetServerTimeNow()
    self.Speed, self.PhaseOffset = nil, 0
    self.BlendStartedAt = workspace:GetServerTimeNow()
    self.BlendDuration = if options.FadeTime == nil then (previous and .18 or 0) else math.max(0, options.FadeTime)
    self.BlendFrom = if self.BlendDuration > 0 then blend else nil
    self:SetOptions(options)
    self.Gait = WalkGait.new(self)
    self.Lift = nil
    if Player.ResolveName(self.DogId, "Work") == clip.SourceName then self.Lift = self:ComputeLift(clip) end
    self:Step()
    return true
end

function Player:Sample(seconds, blendAlpha)
    local clip = self.Clip
    if not clip then return end
    seconds = math.max(0, seconds)
    local period = clip.Duration + self.Recovery
    local t = if self.Looped then seconds % period else math.min(seconds, clip.Duration)
    local recovery = if t > clip.Duration then smooth((t - clip.Duration) / self.Recovery) else 0
    local f = math.min(t, clip.Duration) * clip.FPS
    local index, alpha = math.floor(f) + 1, f % 1
    local baseScale = self.Model:GetAttribute("AnimationBaseScale") or 1
    local scale = self.Model:GetScale() / math.max(baseScale, .00001)
    local blend = blendAlpha or 1
    local hide = {}
    -- Clear omitted tracks during a transition as well; old jaw/prop poses must
    -- not leak into the next clip. Missing streamed bones are safely skipped.
    for name, group in pairs(self.BoneGroups) do
        local frames = clip.Tracks[name]
        local pose = CFrame.identity
        local hidden = false
        if frames then
            local a, b = frames[math.min(index, #frames)], frames[math.min(index + 1, #frames)]
            pose = a:Lerp(b, alpha)
            if recovery > 0 then pose = pose:Lerp(frames[1], recovery) end
            local visibility = clip.Hidden and clip.Hidden[name]
            hidden = visibility and visibility[math.min(index, #visibility)] == true
            if recovery > .5 and visibility then hidden = visibility[1] == true end
            pose = CFrame.new(pose.Position * scale) * pose.Rotation
        end
        for _, bone in ipairs(group) do
            if bone.Parent then
                if hidden then
                    bone.Transform = pose
                    hide[bone] = true
                    self.HiddenBones[bone] = true
                else
                    local old = self.BlendFrom and self.BlendFrom[bone]
                    bone.Transform = if old and blend < 1 then old:Lerp(pose, blend) else pose
                    self.HiddenBones[bone] = nil
                end
            end
        end
    end
    if self.Lift then
        local a, b = self.Lift[math.min(index, #self.Lift)], self.Lift[math.min(index + 1, #self.Lift)]
        local lift = (a + (b - a) * alpha) * (1 - recovery) * blend
        if lift > 0 then
            local up = self.Model:GetPivot().UpVector * lift
            for _, bone in ipairs(self.AllBones) do
                local parent = bone.Parent
                if parent and parent:IsA("BasePart") then
                    bone.Transform = CFrame.new((parent.CFrame * bone.CFrame):VectorToObjectSpace(up)) * bone.Transform
                end
            end
        end
    end
    -- Apply visibility after every animated parent has reached this frame.
    -- Bone transforms have no scale channel. Park independent FX beneath the
    -- model in world-up space, without a 100,000-stud skinned render envelope.
    for _, bone in ipairs(self.AllBones) do
        if hide[bone] and bone.Parent then
            local height = (self.Model:GetAttribute("VisualSize") or Vector3.new(6, 6, 6)).Y
            local target = self.Model:GetPivot().Position - Vector3.yAxis * math.max(12, height * 3)
            local parent = bone.Parent
            local parentFrame = if parent:IsA("Bone") then parent.TransformedWorldCFrame else parent.CFrame
            local restWorld = parentFrame * bone.CFrame
            bone.Transform = CFrame.new(restWorld:PointToObjectSpace(target)) * bone.Transform.Rotation
        end
    end
end

function Player:Step(now)
    if not self.Clip then return end
    now = now or workspace:GetServerTimeNow()
    local blend = if self.BlendFrom then smooth((now - self.BlendStartedAt) / math.max(.001, self.BlendDuration)) else 1
    local locomotion=self.Model:GetAttribute("LocomotionSpeed")
    if self.Gait and finite(locomotion) then
        self:Sample(self.Gait:Advance(now,locomotion),blend)
        self.Gait:Apply(blend)
    else
        self:Sample(math.max(0, (now - self.StartTime) * self.Speed + (self.PhaseOffset or 0)), blend)
    end
    if blend >= 1 then self.BlendFrom = nil end
    local events = ReplicatedStorage:FindFirstChild("WorldEvents")
    local state = events and events:FindFirstChild("State")
    if not state or state:GetAttribute("State") ~= "ACTIVE" or self.Model:GetAttribute("WorkState") == "DIGGING" then return end
    local camera = workspace.CurrentCamera
    if camera and (camera.CFrame.Position - self.Model:GetPivot().Position).Magnitude > 180 then return end
    local phase = now % 9
    if phase > 1.2 then return end
    local head = self.Bones.Head or self.Bones.head
    if head and head.Parent then
        local eventId = state:GetAttribute("EventId")
        local amount = math.sin(phase / 1.2 * math.pi) * .10
        -- Use actual bind-space directions; imported Z-up and authored Y-up
        -- skeletons should both look up, rather than roll sideways.
        local modelFrame = self.Model:GetPivot()
        local rest = head.WorldCFrame
        local right = rest:VectorToObjectSpace(modelFrame.RightVector)
        local up = rest:VectorToObjectSpace(modelFrame.UpVector)
        if eventId == "BONE_RAIN" or eventId == "UFO_INVASION" then
            head.Transform *= CFrame.fromAxisAngle(right, -amount)
        elseif eventId == "BLACKOUT" or eventId == "NULL_HOUR" then
            head.Transform *= CFrame.fromAxisAngle(up, amount)
        elseif eventId == "DOG_RUSH" then
            head.Transform *= CFrame.fromAxisAngle(rest:VectorToObjectSpace(-modelFrame.LookVector), amount)
        end
    end
end

function Player:Destroy()
    self:Stop()
    table.clear(self.Bones); table.clear(self.BoneGroups); table.clear(self.AllBones)
end
return Player
