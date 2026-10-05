-- Authoritative proximity doors. Player proximity is checked on the server.
local Players=game:GetService("Players")
local Run=game:GetService("RunService")
local map=workspace:WaitForChild("DOGROTS_District")
local doors={}
local function register(root)
 if not root:IsA("Model") or not root:GetAttribute("AutomaticDoor") or doors[root] then return end
 local trigger=root:FindFirstChild("DoorTrigger")
 local left=root:FindFirstChild("LeftLeaf");local right=root:FindFirstChild("RightLeaf")
 if not trigger or not left or not right then return end
 local entries={}
 for _,leaf in ipairs({left,right}) do
  local offset=leaf:GetAttribute("OpenOffset")
  if typeof(offset)~="Vector3" then return end
  table.insert(entries,{model=leaf,closed=leaf:GetPivot(),offset=offset})
 end
 doors[root]={trigger=trigger,leaves=entries,alpha=0,holdUntil=0}
 root:SetAttribute("Open",false)
end
for _,d in map:GetDescendants() do register(d) end
map.DescendantAdded:Connect(function(d) task.defer(function() register(d);if d.Parent then register(d.Parent) end end) end)
local acc=0
Run.Heartbeat:Connect(function(dt)
 acc+=dt;if acc<.05 then return end;local step=math.min(acc,.2);acc=0
 local positions={}
 for _,player in Players:GetPlayers() do
  local char=player.Character;local hrp=char and char:FindFirstChild("HumanoidRootPart");local h=char and char:FindFirstChildOfClass("Humanoid")
  if hrp and h and h.Health>0 then table.insert(positions,hrp.Position) end
 end
 local now=os.clock()
 for root,data in pairs(doors) do
  if not root:IsDescendantOf(map) then doors[root]=nil;continue end
  local range=root:GetAttribute("OpenRange") or 15
  for _,pos in ipairs(positions) do
   local delta=pos-data.trigger.Position
   if math.abs(delta.Y)<12 and Vector2.new(delta.X,delta.Z).Magnitude<range then data.holdUntil=now+1.2;break end
  end
  local open=now<data.holdUntil
  local alpha=math.clamp(data.alpha+(open and 1 or -1)*step/0.5,0,1)
  if alpha~=data.alpha then
   data.alpha=alpha;local ease=alpha*alpha*(3-2*alpha)
   for _,leaf in ipairs(data.leaves) do leaf.model:PivotTo(leaf.closed+leaf.offset*ease) end
   root:SetAttribute("Open",alpha>.99)
  end
 end
end)
print("DOGROTS_DOORS_READY")

