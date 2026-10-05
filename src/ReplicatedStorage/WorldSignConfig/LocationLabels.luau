-- Child module of ReplicatedStorage.WorldSignConfig.
-- Shared Workspace signs; WorldSignController handles per-camera distance fading.
local CollectionService = game:GetService("CollectionService")
local StarterGui = game:GetService("StarterGui")
local Labels = {}
local ANCHOR_NAME = "LocationLabelAnchor"
local GUI_NAME = "LocationLabel"

Labels.Locations = {
    {Path = {"11_Shops", "COSMETICS"}, Text = "Shop", Button = "ShopButton", Roof = "Architecture"},
    {Path = {"06_DogDexMuseum"}, Text = "Museum", Button = "DogDexButton", Roof = "SteppedNavyRoof", Clearance = 24},
    {Path = {"05_MutationLab"}, Text = "Lab", Button = "LabButton", Roof = "TechnicalRoof"},
    {Path = {"32_WelcomeHub", "DogShelter"}, Text = "Shelter", Button = "DogsButton", Roof = "Architecture"},
}

local function child(parent, name, class)
    local object = parent:FindFirstChild(name)
    if object then
        assert(object:IsA(class), "Location labels: unexpected object at " .. object:GetFullName())
        return object
    end
    object = Instance.new(class)
    object.Name = name
    object.Parent = parent
    return object
end

local function roofPosition(roof, clearance)
    local low = Vector3.new(math.huge, math.huge, math.huge)
    local high = Vector3.new(-math.huge, -math.huge, -math.huge)
    local count = 0
    for _, part in ipairs(roof:GetDescendants()) do
        if part:IsA("BasePart") and part.Transparency < 1 then
            count += 1
            -- Transform every corner: pitched/rotated roofs need world-space bounds.
            for _, x in ipairs({-1, 1}) do
                for _, y in ipairs({-1, 1}) do
                    for _, z in ipairs({-1, 1}) do
                        local corner = part.CFrame:PointToWorldSpace(part.Size * Vector3.new(x, y, z) / 2)
                        low = low:Min(corner)
                        high = high:Max(corner)
                    end
                end
            end
        end
    end
    assert(count > 0, "Location labels: no visible roof geometry in " .. roof:GetFullName())
    return Vector3.new((low.X + high.X) / 2, high.Y + clearance, (low.Z + high.Z) / 2)
end

function Labels.createLocationLabel(target, text, iconSource, roof, clearance, captionSource)
    assert(target:IsA("Model"), "Location label target must be a Model")
    assert(iconSource:IsA("ImageLabel") and iconSource.Image ~= "", "Missing existing GUI icon")
    local position = roofPosition(roof, clearance or 8)
    local anchor = child(target, ANCHOR_NAME, "Part")
    anchor:SetAttribute("LocationLabelOwned", true)
    anchor.Size = Vector3.new(0.2, 0.2, 0.2)
    anchor.Transparency = 1
    anchor.Anchored = true -- The district's buildings and roofs are anchored.
    anchor.CanCollide = false
    anchor.CanTouch = false
    anchor.CanQuery = false
    anchor.CastShadow = false
    anchor.CFrame = CFrame.new(position)

    local gui = child(anchor, GUI_NAME, "BillboardGui")
    gui.Adornee = anchor
    gui.Size = UDim2.fromOffset(172, 100)
    gui.SizeOffset = Vector2.new(0, 0.5) -- Keep the whole label above its roof anchor.
    gui.StudsOffset = Vector3.zero
    gui.AlwaysOnTop = true
    gui.LightInfluence = 0
    gui.MaxDistance = 330
    gui.Enabled = true
    gui.Active = false
    gui.ClipsDescendants = false
    gui:SetAttribute("Priority", 3)
    gui:SetAttribute("FadeStartDistance", 220)
    gui:SetAttribute("MaxDistance", 300)
    gui:SetAttribute("AlwaysVisible", false)
    gui:SetAttribute("LocationLabelOwned", true)
    gui:SetAttribute("IconSource", iconSource:GetFullName())

    local icon = child(gui, "Icon", "ImageLabel")
    icon.Image = iconSource.Image
    icon.ImageRectOffset = iconSource.ImageRectOffset
    icon.ImageRectSize = iconSource.ImageRectSize
    icon.ImageColor3 = iconSource.ImageColor3
    icon.ImageTransparency = 0
    icon.ScaleType = Enum.ScaleType.Fit
    icon.BackgroundTransparency = 1
    icon.BorderSizePixel = 0
    icon.AnchorPoint = Vector2.new(0.5, 0)
    icon.Position = UDim2.fromOffset(86, 0)
    icon.Size = UDim2.fromOffset(64, 64)
    icon.Visible = true

    local caption = child(gui, "Caption", "TextLabel")
    caption.Text = text
    caption.FontFace = captionSource.FontFace
    caption.TextColor3 = captionSource.TextColor3
    caption.TextStrokeTransparency = 1
    caption.TextTransparency = 0
    caption.TextSize = 28
    caption.TextScaled = false
    caption.TextWrapped = false
    caption.TextXAlignment = Enum.TextXAlignment.Center
    caption.BackgroundTransparency = 1
    caption.BorderSizePixel = 0
    caption.Position = UDim2.fromOffset(0, 64)
    caption.Size = UDim2.fromOffset(172, 36)
    caption.Visible = true
    local stroke = child(caption, "Outline", "UIStroke")
    stroke.Color = captionSource.TextStrokeColor3
    stroke.Thickness = 2
    stroke.Transparency = 0
    stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual
    -- Register only when the full visual is ready for WorldSignController.capture.
    CollectionService:AddTag(gui, "ManagedWorldSign")
    return gui
end

function Labels.Apply()
    local district = workspace:WaitForChild("DOGROTS_District")
    local sidebar = StarterGui:WaitForChild("ScreenGui"):WaitForChild("MainWindow"):WaitForChild("Sidebar")
    local result = {}
    for _, entry in ipairs(Labels.Locations) do
        local target = district
        for _, name in ipairs(entry.Path) do target = target:WaitForChild(name) end
        local button = sidebar:WaitForChild(entry.Button)
        result[#result + 1] = Labels.createLocationLabel(target, entry.Text,
            button:WaitForChild("CandyIcon"), target:WaitForChild(entry.Roof), entry.Clearance or 8,
            button:WaitForChild("CandyCaption"))
    end
    return result
end

return Labels
