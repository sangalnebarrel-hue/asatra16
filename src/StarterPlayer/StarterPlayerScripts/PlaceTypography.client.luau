-- One typeface for district signs, dog labels and player menus, including new clones.
local face=Font.fromEnum(Enum.Font.FredokaOne)
local function attach(o)
 if not(o:IsA('TextLabel')or o:IsA('TextButton')or o:IsA('TextBox'))then return end
 local function apply()if o.FontFace~=face then o.FontFace=face end end
 apply();o:GetPropertyChangedSignal('FontFace'):Connect(apply)
end
for _,root in ipairs({workspace,game.Players.LocalPlayer:WaitForChild('PlayerGui')})do
 for _,o in ipairs(root:GetDescendants())do attach(o)end
 root.DescendantAdded:Connect(attach)
end
