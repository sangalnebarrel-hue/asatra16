-- One typeface for district signs, dog labels and player menus, including new clones.
-- A label created with the KeepFont attribute (Secret arrival whispers) keeps its own.
local face=Font.fromEnum(Enum.Font.FredokaOne)
local function attach(o)
 if not(o:IsA('TextLabel')or o:IsA('TextButton')or o:IsA('TextBox'))then return end
 if o:GetAttribute('KeepFont')then return end
 local function apply()if o.FontFace~=face then o.FontFace=face end end
 apply();o:GetPropertyChangedSignal('FontFace'):Connect(apply)
end
for _,root in ipairs({workspace,game.Players.LocalPlayer:WaitForChild('PlayerGui')})do
 for _,o in ipairs(root:GetDescendants())do attach(o)end
 root.DescendantAdded:Connect(attach)
end
