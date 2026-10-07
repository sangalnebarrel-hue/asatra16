-- The Long Dog is long wherever it is shown. Every venue fits a dog into a ~10-stud box (and
-- the length cap binds first for this one), so it used to read as just another dachshund.
-- Apply(model, venue) runs once the venue has sized and placed the model (DogDisplayHooks):
-- the rest positions (Bone.CFrame) of LongSeg2..LongSeg5, the spine between the front and the
-- hind legs, move apart, so the skinned body grows between the legs. Clips write
-- Bone.Transform on top, so every animation keeps working; set on the server, the bone
-- CFrames replicate. The skin grows toward the tail and the Root bone moves the whole skin
-- forward by half of that, so the dog stays centred where the venue put it (its pivot,
-- parts, labels and GroundLocal do not move). VisualSize/GroundLocal describe the result.
-- Per venue (overall length factor; places measured on the map):
--   Kennel    x1.8: 10 -> 18 studs in its 12-stud pit; the head ends 3 studs past the pit
--             edge (the pit rows are 14 studs apart) and the tail tip at the kennel door.
--   Reveal    x1.8: 10 -> 18 studs on the giant mouth's stage (the tongue is 20 wide).
--   Showcase  x1.8, turned side-on in its glass bay (6.75 deep, ~7.7 wide) and scaled to
--             7.4 studs long, so the yard sees its length instead of its face.
--   BestFinds x1.8, side-on on its 5.6-stud pedestal (exhibits stand 7.1 apart), 6.6 long.
--   Preview   x1.8, scaled back to the length the viewport camera was framed for and turned
--             40 degrees so the camera sees its flank.
--   Line, Machine, Static, Museum: unchanged (it never stands there, or the museum's distant
--             clones carry no bones, so a near clone would change shape as you walk up).
local RS=game:GetService('ReplicatedStorage')
local Rig=require(RS:WaitForChild('DogRig'))
local M={}
M.Venues={
 Kennel={Length=1.8},
 Reveal={Length=1.8},
 Showcase={Length=1.8,Max=7.4,Turn=math.pi/2},
 BestFinds={Length=1.8,Max=6.6,Turn=math.pi/2},
 Preview={Length=1.8,Keep=true,Turn=math.rad(40)},
}
-- The gaps that grow (each bone's offset from the one before it).
local SPAN={'LongSeg2','LongSeg3','LongSeg4','LongSeg5'}

-- A bone's rest frame in world space (no Transform), walking up to its part.
local function restWorld(bone)
 local parent=bone.Parent
 if parent and parent:IsA('Bone')then return restWorld(parent)*bone.CFrame end
 if parent and parent:IsA('BasePart')then return parent.CFrame*bone.CFrame end
 return nil
end

function M.Apply(model,venue)
 local spec=M.Venues[venue]
 if not spec or not model or not model:IsA('Model')or model:GetAttribute('LongBody')then return false end
 local bones={}
 for _,o in ipairs(model:GetDescendants())do if o:IsA('Bone')then bones[o.Name]=bones[o.Name]or o end end
 local root=bones.Root
 if not(root and root.Parent and root.Parent:IsA('BasePart'))then return false end
 for _,name in ipairs(SPAN)do if not bones[name]then return false end end
 local low,high=Rig.Bounds(model)
 if not low then return false end
 local size=high-low
 if size.Z<=0 then return false end
 local ground=model:GetAttribute('GroundLocal')
 if typeof(ground)~='Vector3'then ground=Vector3.new((low.X+high.X)/2,low.Y,(low.Z+high.Z)/2)end
 local pivot=model:GetPivot()
 local groundWorld=pivot:PointToWorldSpace(ground)
 -- How far the dog grows along its length (pivot Z: it faces -Z) per unit of gap stretch.
 local function gaps()
  local list,along={},0
  for _,name in ipairs(SPAN)do
   local bone=bones[name]
   local parent=bone.Parent
   local parentRest=parent and(parent:IsA('Bone')and restWorld(parent)or parent:IsA('BasePart')and parent.CFrame)or nil
   if not parentRest then return nil,0 end
   local offset=bone.CFrame.Position
   local v=model:GetPivot():VectorToObjectSpace(parentRest:VectorToWorldSpace(offset))
   table.insert(list,{Bone=bone,Offset=offset,Along=v})
   along+=v.Z
  end
  return list,along
 end
 local list,along=gaps()
 if not list or along<=1e-4 then return false end
 local length=size.Z*spec.Length
 -- Too long for its venue: the whole dog shrinks (it keeps its new proportions).
 local cap=spec.Keep and size.Z or spec.Max
 local shrink=cap and math.min(1,cap/length)or 1
 if shrink<.999 then
  local ok=pcall(function()model:ScaleTo(model:GetScale()*shrink)end)
  if not ok then shrink=1 end
  -- ScaleTo scales about the pivot: put the ground point back where the venue had it.
  local now=model:GetPivot()
  model:PivotTo(now+(groundWorld-now:PointToWorldSpace(ground*shrink)))
  ground*=shrink;size*=shrink;length*=shrink
  list,along=gaps()
  if not list or along<=1e-4 then return false end
 end
 local grow=length-size.Z
 local k=grow/along
 -- The gaps grow toward the tail (+Z); the skin moves forward by half of it.
 local pivotNow=model:GetPivot()
 local total=Vector3.zero
 for _,g in ipairs(list)do
  g.Bone.CFrame+=g.Offset*k
  total+=g.Along*k
 end
 local part=root.Parent::BasePart
 root.CFrame+=part.CFrame:VectorToObjectSpace(pivotNow:VectorToWorldSpace(-total/2))
 if spec.Turn then
  local at=pivotNow:PointToWorldSpace(ground)
  model:PivotTo(CFrame.new(at)*CFrame.Angles(0,spec.Turn,0)*CFrame.new(-at)*pivotNow)
 end
 model:SetAttribute('GroundLocal',ground)
 model:SetAttribute('VisualSize',Vector3.new(size.X,size.Y,size.Z+total.Z))
 model:SetAttribute('LongBody',spec.Length)
 model:SetAttribute('LongBodyLength',size.Z+total.Z)
 return true
end
return M
