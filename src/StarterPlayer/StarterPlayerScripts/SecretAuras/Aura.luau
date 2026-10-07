-- One Secret dog's persistent aura (SecretAuras). Its geometry is measured once per build
-- in the dog's own frame: the yaw of its pivot, X right, Y up, -Z forward, origin at the
-- pivot. Everything it shows lives in a group: tier 2 (reduced, mid distance), tier 3
-- (full, near) and the granted Beacon, Light and Highlight. A group fades in when it is
-- made and fades out before it is destroyed; the whole aura fades with Alpha.
-- Nothing visible is ever put inside the dog model (bounds code reads its parts): only
-- Attachments and emitters on its root and bones (attribute SecretAura, set before they
-- are parented). Parts, lights, adornments and billboards live in the client FX folder.
local RS=game:GetService('ReplicatedStorage')
local Config=require(RS:WaitForChild('SecretAuraConfig'))
local A={};A.__index=A
A.Textures={Spark='rbxasset://textures/particles/sparkles_main.dds',Smoke='rbxasset://textures/particles/smoke_main.dds',Fire='rbxasset://textures/particles/fire_main.dds'}
-- A cylinder adornment (axis Z) turned to lie flat on the ground.
A.Flat=CFrame.Angles(math.pi/2,0,0)
-- Follower parts moved this frame: the manager sends them in one BulkMoveTo.
A.Batch={Parts={},CFrames={}}
local GROUP_FADE=.45
local huge=math.huge

local function mark(o)
 o:SetAttribute('SecretAura',true);o.Archivable=false
 return o
end
function A.new(model,id,folder,style)
 local self=setmetatable({Model=model,DogId=id,Cfg=Config.Dogs[id],Style=style,Folder=folder,
  Venue=model:GetAttribute('DisplayVenue')or 'Unknown',Mini=false,Groups={},Alpha=0,Target=0,Level=0,
  Distance=huge,Dirty=true,Geo=nil,Body=nil,Connections={},Removed=false},A)
 local o=model.Parent
 while o and o~=workspace do
  if Config.MiniAncestors[o.Name]then self.Mini=true end
  o=o.Parent
 end
 -- Parts and bones stream in and out (and the Long Dog may grow): measure again.
 table.insert(self.Connections,model.DescendantAdded:Connect(function(d)
  if d:IsA('BasePart')or d:IsA('Bone')then self.Dirty=true end
 end))
 table.insert(self.Connections,model.DescendantRemoving:Connect(function(d)
  local G=self.Geo
  if G and(d==G.Anchor or d==G.Visual)then self.Dirty=true end
 end))
 return self
end

---------------------------------------------------------------- geometry
-- Bounds of the visible parts in the dog's frame; the anchor is the root (it carries the
-- whole welded dog on the tongue), else the largest visible part (museum clones).
function A:Measure()
 local model=self.Model
 local pivot=model:GetPivot()
 local look=pivot.LookVector
 local flat=Vector3.new(look.X,0,look.Z)
 if flat.Magnitude<1e-3 then flat=-pivot.UpVector;flat=Vector3.new(flat.X,0,flat.Z)end
 if flat.Magnitude<1e-3 then flat=Vector3.new(0,0,-1)end
 local frame=CFrame.lookAt(pivot.Position,pivot.Position+flat.Unit)
 local lo,hi=Vector3.one*huge,-Vector3.one*huge
 local visual,volume=nil,-1
 local bones={}
 for _,d in ipairs(model:GetDescendants())do
  if d:IsA('BasePart')then
   if d.Transparency<1 and d.Name~='RootPart'then
    local cf,half=frame:ToObjectSpace(d.CFrame),d.Size/2
    for x=-1,1,2 do for y=-1,1,2 do for z=-1,1,2 do
     local p=cf:PointToWorldSpace(half*Vector3.new(x,y,z))
     lo=lo:Min(p);hi=hi:Max(p)
    end end end
    local v=d.Size.X*d.Size.Y*d.Size.Z
    if v>volume then visual,volume=d,v end
   end
  elseif d:IsA('Bone')then
   local key=string.lower(d.Name)
   if not bones[key]then bones[key]=d end
  end
 end
 if not visual then return nil end
 -- The Long Dog's length lives in its spine bones too (LongDogBody may stretch them).
 if self.DogId=='LongDog'then
  for _,key in ipairs({'head','tailtip','tail','longseg6'})do
   local b=bones[key]
   if b then local p=frame:PointToObjectSpace(b.WorldPosition);lo=lo:Min(p);hi=hi:Max(p)end
  end
 end
 local root=model.PrimaryPart or model:FindFirstChild('RootPart',true)
 local anchor=(root and root:IsA('BasePart'))and root or visual
 local size=hi-lo
 local G={Frame=frame,Anchor=anchor,Visual=visual,FrameInAnchor=anchor.CFrame:ToObjectSpace(frame),Bones=bones,
  Lo=lo,Hi=hi,Size=size,Center=(lo+hi)/2,Ground=Vector3.new((lo.X+hi.X)/2,lo.Y,(lo.Z+hi.Z)/2),
  Top=Vector3.new((lo.X+hi.X)/2,hi.Y,(lo.Z+hi.Z)/2)}
 -- S: 1 for a typical 5-stud dog; R: ground radius around it.
 G.S=math.clamp(size.Y/5,.35,3)
 G.R=math.clamp(math.max(size.X,size.Z)*.5,.8,14)
 return G
end
-- A point/orientation in the dog's frame, as a CFrame in its anchor's space (attachments,
-- adornments) or in world space (follower parts).
function A:Local(p,rotation)
 return self.Geo.FrameInAnchor*CFrame.new(p)*(rotation or CFrame.identity)
end
function A:WorldFrame()
 local G=self.Geo
 return G.Anchor.CFrame*G.FrameInAnchor
end
function A:World(p,rotation)
 return self:WorldFrame()*CFrame.new(p)*(rotation or CFrame.identity)
end
-- First existing bone of `names` (case-insensitive).
function A:Bone(...)
 local G=self.Geo
 for _,name in ipairs({...})do
  local b=G.Bones[string.lower(name)]
  if b and b.Parent and b:IsDescendantOf(self.Model)then return b end
 end
 return nil
end

---------------------------------------------------------------- groups
local function newGroup(key)
 return {Key=key,Items={},Fades={},Emitters={},State={},Alpha=0,Target=1,Applied=-1}
end
function A:Track(g,o)
 table.insert(g.Items,o)
 return o
end
-- Fades: kind 'ltm' (LocalTransparencyModifier = 1-a), 'alpha' (prop = 1-(1-base)*a),
-- 'scale' (prop = base*a).
function A:Fade(g,o,prop,kind,base)
 table.insert(g.Fades,{o,prop,kind,base})
end
function A:ApplyFades(g)
 local a=g.Alpha*self.Alpha
 if math.abs(a-g.Applied)<1e-3 then return end
 g.Applied=a
 for _,f in ipairs(g.Fades)do
  local o,prop,kind,base=f[1],f[2],f[3],f[4]
  if o.Parent then
   if kind=='ltm'then (o::any).LocalTransparencyModifier=1-a
   elseif kind=='alpha'then (o::any)[prop]=1-(1-base)*a
   else (o::any)[prop]=base*a end
  end
 end
end

---------------------------------------------------------------- builders (styles use these)
function A:Attachment(g,name,p,rotation)
 local at=mark(Instance.new('Attachment'))
 at.Name=name;at.CFrame=self:Local(p,rotation)
 at.Parent=self.Geo.Anchor
 return self:Track(g,at)
end
-- A bone when the rig has one (follows the clip pose), else an attachment at `p`.
function A:BoneOr(g,names,p)
 local b=self:Bone(table.unpack(names))
 if b then return b,true end
 return self:Attachment(g,'Aura'..names[1],p),false
end
--[[ Emitter(g, parent, rate, setup): a ParticleEmitter (sparkle defaults) that setup(e)
 adjusts. rate is its full-aura rate at High quality; the manager scales it. ]]
function A:Emitter(g,parent,rate,setup)
 local e=mark(Instance.new('ParticleEmitter'))
 e.Name='AuraEmitter';e.Texture=A.Textures.Spark;e.Rate=0;e.Enabled=false
 e.LightEmission=1;e.LightInfluence=0;e.Lifetime=NumberRange.new(.8,1.4);e.Speed=NumberRange.new(.4,1.2)
 e.SpreadAngle=Vector2.new(180,180);e.Size=NumberSequence.new(.3,0);e.Transparency=NumberSequence.new(.1,1)
 e.Color=ColorSequence.new(self.Cfg.Color)
 setup(e)
 e.Parent=parent
 table.insert(g.Emitters,{e,rate})
 self:Fade(g,e,'LocalTransparencyModifier','ltm')
 return self:Track(g,e)
end
--[[ Adorn(g, class, setup, fade?): a HandleAdornment in the FX folder that rides the dog's
 anchor (follows the tongue for free). Its CFrame is in the anchor's space (A:Local).
 fade=false: the style animates its Transparency itself (times the group's alpha). ]]
function A:Adorn(g,class,setup,fade)
 local o=mark(Instance.new(class))::any
 o.Adornee=self.Geo.Anchor;o.AlwaysOnTop=false;o.ZIndex=1
 setup(o)
 o.Parent=self.Folder
 if fade~=false then self:Fade(g,o,'Transparency','alpha',o.Transparency)end
 return self:Track(g,o)
end
function A:Beam(g,a0,a1,setup)
 local b=mark(Instance.new('Beam'))
 b.Attachment0=a0;b.Attachment1=a1;b.LightEmission=1;b.LightInfluence=0;b.FaceCamera=true;b.Segments=1
 b.Color=ColorSequence.new(self.Cfg.Color)
 setup(b)
 b.Parent=self.Folder
 self:Fade(g,b,'LocalTransparencyModifier','ltm')
 return self:Track(g,b)
end
-- A billboard in the FX folder; register its labels' fades with A:FadeGui.
function A:Billboard(g,adornee,setup)
 local gui=mark(Instance.new('BillboardGui'))
 gui.Adornee=adornee;gui.LightInfluence=0;gui.AlwaysOnTop=false;gui.ResetOnSpawn=false;gui.ClipsDescendants=false
 setup(gui)
 gui.Parent=self.Folder
 return self:Track(g,gui)
end
-- Every TextLabel / Frame / UIStroke under `root` fades with the group.
function A:FadeGui(g,root)
 local list=root:GetDescendants();table.insert(list,root)
 for _,o in ipairs(list)do
  if o:IsA('TextLabel')then
   self:Fade(g,o,'TextTransparency','alpha',o.TextTransparency)
   self:Fade(g,o,'TextStrokeTransparency','alpha',o.TextStrokeTransparency)
   self:Fade(g,o,'BackgroundTransparency','alpha',o.BackgroundTransparency)
  elseif o:IsA('Frame')then self:Fade(g,o,'BackgroundTransparency','alpha',o.BackgroundTransparency)
  elseif o:IsA('UIStroke')then self:Fade(g,o,'Transparency','alpha',o.Transparency)end
 end
end
-- An anchored, unclickable part in the FX folder that the style moves (A.Move).
function A:Follower(g,setup)
 local p=mark(Instance.new('Part'))
 p.Anchored=true;p.CanCollide=false;p.CanTouch=false;p.CanQuery=false;p.CastShadow=false
 p.Material=Enum.Material.Neon;p.TopSurface=Enum.SurfaceType.Smooth;p.BottomSurface=Enum.SurfaceType.Smooth
 p.Size=Vector3.one*.2
 setup(p)
 p.CFrame=self:World(self.Geo.Center)
 p.Parent=self.Folder
 self:Fade(g,p,'LocalTransparencyModifier','ltm')
 return self:Track(g,p)
end
function A.Move(part,cf)
 table.insert(A.Batch.Parts,part);table.insert(A.Batch.CFrames,cf)
end
-- The invisible part around the dog's body: volume emitters, the light, sounds. Owned by
-- the aura (not a group) and moved with the dog.
function A:BodyPart()
 local G=self.Geo
 if self.Body and self.Body.Parent then return self.Body end
 local p=mark(Instance.new('Part'))
 p.Name='AuraBody_'..self.DogId;p.Anchored=true;p.CanCollide=false;p.CanTouch=false;p.CanQuery=false;p.CastShadow=false
 p.Transparency=1;p.Size=G.Size:Max(Vector3.one*.4)
 p.CFrame=self:World(G.Center)
 p.Parent=self.Folder
 self.Body=p;self.BodyAt=G.Anchor.CFrame
 return p
end
-- Volume emission from the body box (an emitter on an attachment is a point).
function A.Volume(e)
 e.Shape=Enum.ParticleEmitterShape.Box;e.ShapeStyle=Enum.ParticleEmitterShapeStyle.Volume
end

---------------------------------------------------------------- particle budget
-- Sum of this aura's emitter rates at the current LOD (tier 2's emitters run at
-- Config.ReducedRate while it is the only tier), before the global budget.
function A:Demand(scale)
 local total=0
 if self.Target<=0 then return 0 end
 for key,g in pairs(self.Groups)do
  if g.Target>0 then
   local factor=(key==2 and self.Level<3)and Config.ReducedRate or 1
   for _,row in ipairs(g.Emitters)do total+=row[2]*factor*scale end
  end
 end
 return total
end
function A:SetRates(fraction,scale)
 for key,g in pairs(self.Groups)do
  local on=g.Target>0 and self.Target>0
  local factor=(key==2 and self.Level<3)and Config.ReducedRate or 1
  for _,row in ipairs(g.Emitters)do
   local e=row[1]
   local rate=on and row[2]*factor*scale*fraction or 0
   if e.Parent then e.Rate=rate;e.Enabled=rate>=.05 end
  end
 end
end

---------------------------------------------------------------- lifecycle
function A:DestroyGroup(key)
 local g=self.Groups[key]
 if not g then return end
 self.Groups[key]=nil
 if self.Style.Clear then pcall(self.Style.Clear,self,key,g)end
 for i=#g.Items,1,-1 do local o=g.Items[i];if o.Parent then o:Destroy()end end
 table.clear(g.Items);table.clear(g.Fades);table.clear(g.Emitters)
 -- Tier 2's ring and plate are animated by tier 3: show them at rest again.
 if key==3 and self.Groups[2]then self.Groups[2].Applied=-1 end
end
-- Everything goes, now (streaming, a quality change); measured again on the next pass.
function A:Reset()
 for key in pairs(self.Groups)do self:DestroyGroup(key)end
 if self.Body then self.Body:Destroy();self.Body=nil end
 self.Geo=nil;self.Dirty=true;self.Level=0
end
function A:Rebuild()
 self:Reset()
 self.Dirty=false
 local ok,G=pcall(self.Measure,self)
 if ok then self.Geo=G else warn('[SecretAuras] measure',self.DogId,G)end
end
function A:Ensure(key,build)
 local g=self.Groups[key]
 if g then g.Target=1;return g end
 g=newGroup(key);self.Groups[key]=g
 local ok,err=pcall(build,self,g)
 if not ok then warn('[SecretAuras]',self.DogId,key,err)end
 -- Nothing of ours may be copied with the dog (arrival copies, menu previews clone it).
 for _,o in ipairs(g.Items)do
  if o:IsA('Bone')then continue end
  for _,d in ipairs(o:GetDescendants())do d.Archivable=false end
 end
 self:ApplyFades(g)
 return g
end
function A:Release(key)
 local g=self.Groups[key]
 if g then g.Target=0 end
end
function A:Destroy()
 self.Removed=true
 for _,c in ipairs(self.Connections)do c:Disconnect()end
 table.clear(self.Connections)
 self:Reset()
end

---------------------------------------------------------------- per frame
-- Fades the aura and its groups, moves the body with a moving dog. Returns false once
-- nothing is left to animate (the manager then skips it until the next pass).
function A:Frame(dt,full)
 local G=self.Geo
 if not G then return false end
 local busy=false
 local goal=self.Target
 if self.Alpha~=goal then
  local rate=dt/(goal>self.Alpha and Config.FadeIn or Config.FadeOut)
  self.Alpha=goal>self.Alpha and math.min(goal,self.Alpha+rate)or math.max(goal,self.Alpha-rate)
  busy=true
 end
 for key,g in pairs(self.Groups)do
  if g.Alpha~=g.Target then
   local rate=dt/GROUP_FADE
   g.Alpha=g.Target>g.Alpha and math.min(g.Target,g.Alpha+rate)or math.max(g.Target,g.Alpha-rate)
   busy=true
  end
  if g.Target==0 and g.Alpha<=0 then self:DestroyGroup(key)
  else self:ApplyFades(g)end
 end
 -- The body follows every frame up close, at the manager's pass otherwise.
 local body=self.Body
 if full and body and G.Anchor.Parent then
  local at=G.Anchor.CFrame
  if at~=self.BodyAt then self.BodyAt=at;A.Move(body,at*G.FrameInAnchor*CFrame.new(G.Center))end
 end
 return busy or self.Groups[3]~=nil
end
function A:Follow()
 local G,body=self.Geo,self.Body
 if not G or not body or not G.Anchor.Parent then return end
 local at=G.Anchor.CFrame
 if at~=self.BodyAt then self.BodyAt=at;body.CFrame=at*G.FrameInAnchor*CFrame.new(G.Center)end
end
return A
