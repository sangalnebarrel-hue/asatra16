
local nav=workspace:WaitForChild('DOGROTS_District'):WaitForChild('NavigationAnchors')
while true do
 for _,mirror in ipairs(nav:GetChildren())do local ref=mirror:FindFirstChild('Target');if mirror:IsA('BasePart')and ref and ref.Value then mirror.CFrame=ref.Value.CFrame end end
 task.wait(1)
end
