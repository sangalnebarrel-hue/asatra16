local RunService=game:GetService("RunService")
local model=workspace:FindFirstChild("DOG_097_SPIDERDOG_MODEL",true)
if not model then return end
local bones={}
for _,d in ipairs(model:GetDescendants()) do if d:IsA("Bone") then table.insert(bones,d) end end
local base={}; for _,b in ipairs(bones) do base[b]=b.Transform end
local mode="IDLE"; local started=0
local function refresh()
 local token=model:GetAttribute("Playback") or "IDLE|0"
 mode=token:match("^([^|]+)") or "IDLE"; started=os.clock()
end
model:GetAttributeChangedSignal("Playback"):Connect(refresh); refresh()
local function leg(n) return string.find(n,"F1_") or string.find(n,"F2_") or string.find(n,"R1_") or string.find(n,"R2_") end
RunService.RenderStepped:Connect(function()
 local t=os.clock()-started
 local speed=(mode=="RUN" and 15) or (mode=="WALK" and 9) or 3
 local amp=(mode=="RUN" and .48) or (mode=="WALK" and .32) or .08
 for i,b in ipairs(bones) do
  local n=b.Name; local pose=CFrame.new()
  local phase=(i%2)*math.pi
  if leg(n) then
   local swing=math.sin(t*speed+phase)*amp
   if mode=="DIG_START" or mode=="DIG_LOOP" or mode=="MULTI_DIG" then
    if string.find(n,"F1_") or string.find(n,"F2_") then swing=math.sin(t*18+phase)*.75 end
   end
   pose=CFrame.Angles(swing,0,0)
  elseif string.find(n,"Head") then
   local nod=(mode=="HAPPY" and math.sin(t*7)*.22) or math.sin(t*3)*.06
   pose=CFrame.Angles(nod,math.sin(t*2)*.05,0)
  elseif string.find(n,"Tail") then
   pose=CFrame.Angles(0,math.sin(t*5+i)*.16,math.cos(t*4+i)*.1)
  elseif string.find(n,"Spine") then
   pose=CFrame.Angles(0,math.sin(t*2)*.035,0)
  end
  b.Transform=base[b]*pose
 end
end)

