local S={}
local Templates=game.ServerStorage:WaitForChild('DogTemplates')
local Defs=require(game.ReplicatedStorage.DogEconomy.DogDefinitions)
local Hooks=require(game.ReplicatedStorage.DogDisplayHooks)
local function visibleBounds(model)
 local low,high=Vector3.one*math.huge,Vector3.one*-math.huge
 for _,part in model:GetDescendants()do if part:IsA('BasePart')and part.Transparency<1 then
  for x=-1,1,2 do for y=-1,1,2 do for z=-1,1,2 do
   local p=part.CFrame:PointToWorldSpace(part.Size*Vector3.new(x,y,z)/2);low=low:Min(p);high=high:Max(p)
  end end end
 end end
 return low,high
end
local function create(d,slot)
 local def=Defs[d.DogId];local source=def and Templates:FindFirstChild(def.VisualAsset or d.DogId)
 if not source then return end
 local m=source:Clone();local root=m:FindFirstChild('RootPart',true)
 if not root then m:Destroy();return end;m.PrimaryPart=root
 for _,o in m:GetDescendants()do
  if o:IsA('LuaSourceContainer')or o:IsA('ProximityPrompt')or o:IsA('Sound')or o:IsA('BillboardGui')or o:IsA('ParticleEmitter')then o:Destroy()
  elseif o:IsA('BasePart')then o.Anchored=true;o.CanCollide=false;o.CanQuery=false;o.CanTouch=false end
 end
 m:PivotTo(CFrame.identity)
 local lo,hi=visibleBounds(m);local size=hi-lo
 if size.Y<=0 or size.Y==math.huge then m:Destroy();return end
 m:ScaleTo(m:GetScale()*math.min(5.7/size.Y,6.4/size.X,6.4/size.Z))
 lo,hi=visibleBounds(m)
 m:PivotTo(slot.CFrame*CFrame.new(-(lo.X+hi.X)/2,-lo.Y,-(lo.Z+hi.Z)/2))
 local tint={Shiny=Color3.fromRGB(210,235,255),Golden=Color3.fromRGB(255,193,44),Corrupted=Color3.fromRGB(188,56,81),Glitched=Color3.fromRGB(210,87,255),Void=Color3.fromRGB(104,38,164)}
 if tint[d.Variant]then for _,o in m:GetDescendants()do if o:IsA('BasePart')then o.Color=o.Color:Lerp(tint[d.Variant],.38)end end end
 m.Name='DisplayDog';m:SetAttribute('DogUid',d.DogUid);m:SetAttribute('DogId',d.DogId);m:SetAttribute('Variant',d.Variant)
 m:SetAttribute('OwnerUserId',d.OwnerUserId);m:SetAttribute('PlotShowcase',true)
 Hooks.Prepared(m,d.DogId,'Showcase')
 return m
end
function S.Clear(yard)
 local storage=yard:FindFirstChild('DogStorage');local slots=storage and storage:FindFirstChild('DisplaySlots')
 if not slots then return end
 for _,slot in slots:GetChildren()do
  local m=slot:FindFirstChild('DisplayDog');if m then m:Destroy()end
  slot:SetAttribute('DogUid',nil)
  local label=slot:FindFirstChild('DisplayName',true);if label then label.Text='EMPTY' end
 end
end
function S.Reconcile(player,p)
 local yard=require(script.Parent.YardCommerce).Yard(player);if not yard then return end
 local slots=yard.DogStorage:FindFirstChild('DisplaySlots');if not slots then return end
 for i=1,3 do
  local slot=slots:FindFirstChild('Slot'..i)
  if slot then
   local uid=p.DisplayDogs and p.DisplayDogs[tostring(i)];local d=uid and p.Dogs[uid]
   if d and(d.OwnerUserId~=player.UserId or d.State=='Walking')then d=nil end
   local old=slot:FindFirstChild('DisplayDog')
   if old and(not d or old:GetAttribute('DogUid')~=uid or old:GetAttribute('Variant')~=d.Variant)then old:Destroy();old=nil end
   if d and not old then local m=create(d,slot);if m then m.Parent=slot;old=m end end
   slot:SetAttribute('DogUid',old and uid or nil)
   local label=slot:FindFirstChild('DisplayName',true);if label then label.Text=old and d.DisplayName or'EMPTY'end
  end
 end
end
function S.Start()
 if S.Started then return end;S.Started=true
 for _,yard in workspace.DOGROTS_District['04_PlayerYards']:GetChildren()do if yard:GetAttribute('YardId')then
  S.Clear(yard)
  yard:GetAttributeChangedSignal('OwnerUserId'):Connect(function()
   S.Clear(yard);local player=game.Players:GetPlayerByUserId(yard:GetAttribute('OwnerUserId')or 0)
   local rt=require(script.Parent.Runtime);if player and rt.Views[player.UserId]then S.Reconcile(player,rt.Views[player.UserId])end
  end)
 end end
end
return S
