-- Shared sizing contract for conveyor, kennels, previews and the Studio audit.
-- Preserve imported mesh offsets, Motor6Ds and every Bone.CFrame bind pose.
local Rig = {}
local RenderProfile=require(script.Parent.DogRenderProfile)

function Rig.Bounds(model)
    local low, high = Vector3.one * math.huge, Vector3.one * -math.huge
    local pivot = model:GetPivot()
    for _, part in ipairs(model:GetDescendants()) do
        if part:IsA("BasePart") and part.Transparency < 1 and part.Name ~= "RootPart" then
            local localFrame = pivot:ToObjectSpace(part.CFrame)
            for x = -1, 1, 2 do for y = -1, 1, 2 do for z = -1, 1, 2 do
                local point = localFrame:PointToWorldSpace(part.Size * Vector3.new(x, y, z) / 2)
                low, high = low:Min(point), high:Max(point)
            end end end
        end
    end
    if low.Y == math.huge then return nil end
    return low, high
end

function Rig.Prepare(model, limits)
    if not model:IsA("Model") then return nil end
    local root = model:FindFirstChild("RootPart", true) or model.PrimaryPart
        or model:FindFirstChildWhichIsA("BasePart", true)
    if not root or not root:IsA("BasePart") then return nil end
    model.PrimaryPart = root
    RenderProfile.Apply(model)
    if not model:GetAttribute("AnimationBaseScale") then
        model:SetAttribute("AnimationBaseScale", model:GetScale())
    end
    for _, item in ipairs(model:GetDescendants()) do
        if item:IsA("BasePart") then
            item.Anchored, item.CanCollide, item.CanTouch, item.CanQuery = true, false, false, false
            item.Massless = true
        elseif item:IsA("Bone") then
            item.Transform = CFrame.identity
        elseif item:IsA("BaseScript") then
            item:Destroy()
        end
    end
    model:PivotTo(CFrame.identity)
    local low, high = Rig.Bounds(model)
    if not low then return nil end
    local size = high - low
    if math.min(size.X, size.Y, size.Z) <= 0 then return nil end
    if limits then
        local factor = math.min(limits.X / size.X, limits.Y / size.Y, limits.Z / size.Z)
        if factor <= 0 or factor == math.huge then return nil end
        model:ScaleTo(model:GetScale() * factor)
        low, high = Rig.Bounds(model)
        size = high - low
    end
    local ground = Vector3.new((low.X + high.X) / 2, low.Y, (low.Z + high.Z) / 2)
    model:SetAttribute("GroundLocal", ground)
    model:SetAttribute("VisualSize", size)
    return {Root = root, Low = low, High = high, Size = size, Ground = ground}
end

function Rig.Place(model, position, rotation)
    model:PivotTo(CFrame.new(position) * (rotation or CFrame.identity)
        * CFrame.new(-(model:GetAttribute("GroundLocal") or Vector3.zero)))
end

return Rig
