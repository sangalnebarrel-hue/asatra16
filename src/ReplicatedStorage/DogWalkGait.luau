-- Contact fitting on top of the authored Walk. Bind poses and segment lengths
-- stay intact; leg roots can settle vertically by at most 8% of their length.
-- Breadog's authored hop is reduced to fit its rigid feet. Cubedog uses an
-- intentional distance-driven corner roll matching its flip/impact identity.
local Profiles = require(script.Parent.DogWalkProfiles)
local Gait = {}
Gait.__index = Gait
local function vector(v) return Vector3.new(v[1],v[2],v[3]) end
local function finite(n) return type(n)=="number" and n==n and math.abs(n)<math.huge end

local function rotateToward(bone, from, to, limit)
    if from.Magnitude<1e-6 or to.Magnitude<1e-6 then return end
    local a,b=from.Unit,to.Unit
    local axis=a:Cross(b)
    if axis.Magnitude<1e-6 then return end
    local angle=math.min(math.acos(math.clamp(a:Dot(b),-1,1)),limit)
    local localAxis=bone.TransformedWorldCFrame:VectorToObjectSpace(axis.Unit)
    bone.Transform *= CFrame.fromAxisAngle(localAxis,angle)
end

local function twoLink(hip,knee,tip,target)
    local p0,p1=hip.TransformedWorldCFrame.Position,knee.TransformedWorldCFrame.Position
    local p2=tip()
    local l1,l2=(p1-p0).Magnitude,(p2-p1).Magnitude
    if math.min(l1,l2)<1e-5 then return false end
    local delta=target-p0
    if delta.Magnitude<1e-5 then return false end
    local axis=delta.Unit
    local d=math.clamp(delta.Magnitude,math.abs(l1-l2)+1e-5,(l1+l2)*.99999)
    local along=(l1*l1-l2*l2+d*d)/(2*d)
    local height=math.sqrt(math.max(0,l1*l1-along*along))
    -- The original knee defines the bend plane; no mirrored-knee flips.
    local bend=p1-p0-axis*(p1-p0):Dot(axis)
    if bend.Magnitude<1e-5 then
        bend=hip.TransformedWorldCFrame.RightVector:Cross(axis)
        if bend.Magnitude<1e-5 then bend=Vector3.zAxis:Cross(axis) end
    end
    local wantedKnee=p0+axis*along+bend.Unit*height
    rotateToward(hip,p1-p0,wantedKnee-p0,math.rad(55))
    local currentKnee=knee.TransformedWorldCFrame.Position
    rotateToward(knee,tip()-currentKnee,p0+axis*d-currentKnee,math.rad(75))
    return true
end

function Gait.new(player)
    local profile=Profiles[player.DogId]
    if not profile or player.Clip.SourceName~=profile.Clip then return nil end
    if player.DogId=="Cubedog" then
        profile=table.clone(profile)
        profile.Mode,profile.Reverse="cube-roll",false
    end
    local self=setmetatable({Player=player,Profile=profile,Phase=0,Feet={},Speed=0,
        Frequency=0,MaxTargetError=0,MaxLinkError=0,MaxHipShiftRatio=0,StanceSamples=0},Gait)
    for _, definition in ipairs(profile.Feet) do
        local chain={}
        for _,name in ipairs(definition.Chain) do
            local bone=player.Bones[name]
            if bone then table.insert(chain,bone) end
        end
        if #chain==#definition.Chain and #chain>0 then
            table.insert(self.Feet,{Definition=definition,Chain=chain,Bone=chain[#chain]})
        end
    end
    return self
end

function Gait:Advance(now,speed)
    speed=if finite(speed) then math.clamp(speed,0,8) else 0
    local model=self.Player.Model
    self.Scale=model:GetScale()/math.max(model:GetAttribute("AnimationBaseScale") or 1,1e-5)
    self.Speed=speed
    local native=self.Profile.NativeSpeed*self.Scale
    local rate=if native>.001 then speed/native else 1
    -- Preserve the fitted stride as the line speeds up from 4 to 6 studs/sec.
    -- Short-legged dogs use a faster trot instead of stretching their stance.
    local maxFrequency=math.clamp(speed*.75,3,4.5)
    self.Rate=math.clamp(rate,.15,self.Profile.Duration*maxFrequency)
    if self.Player.DogId=="Breadog" then
        self.Rate=math.max(self.Rate,math.min(maxFrequency,speed*.55)*self.Profile.Duration)
    end
    self.Frequency=self.Rate/self.Profile.Duration
    if self.Profile.Mode~="walk" then self.Rate=if speed>0 then 1 else 0;self.Frequency=self.Rate/self.Profile.Duration end
    if speed==0 then self.Rate=0;self.Frequency=0 end
    if speed>0 then self.FitSpeed,self.FitFrequency=speed,self.Frequency end
    local dt=if self.LastTime then math.clamp(now-self.LastTime,0,.15) else 0
    self.LastTime=now
    self.RollDistance=(self.RollDistance or 0)+dt*speed
    self.Phase=(self.Phase+dt*self.Frequency)%1
    local sample=if self.Profile.Reverse and self.Profile.Mode=="walk" then (1-self.Phase)%1 else self.Phase
    return sample*self.Profile.Duration
end

function Gait:ApplyCubeRoll(weight)
    local model=self.Player.Model
    local body=self.Player.Bones.body
    if not body then return end
    local pivot=model:GetPivot()
    local ground=model:GetAttribute("GroundLocal") or Vector3.zero
    local size=model:GetAttribute("VisualSize") or Vector3.new(6,6,6)
    local rest=body.WorldCFrame
    local center=pivot:PointToObjectSpace(rest.Position)
    local hy=math.max(center.Y-ground.Y,ground.Y+size.Y-center.Y,.01)
    local hz=math.max(math.abs(ground.Z-size.Z/2-center.Z),math.abs(ground.Z+size.Z/2-center.Z),.01)
    local quarterLength=hy+hz
    local distance=(self.RollDistance or 0)%(quarterLength*4)
    local quarter=math.floor(distance/quarterLength)
    local within=distance-quarter*quarterLength
    local vertical,horizontal=hy,hz
    if quarter%2==1 then vertical,horizontal=hz,hy end
    -- Invert the corner arc so the supporting corner stays stationary while
    -- the conveyor moves the center at a constant linear speed.
    local radius=math.sqrt(vertical*vertical+horizontal*horizontal)
    local angle=math.acos(math.clamp((horizontal-within)/radius,-1,1))-math.atan2(vertical,horizontal)
    angle+=quarter*math.pi/2
    local height=hy*math.abs(math.cos(angle))+hz*math.abs(math.sin(angle))
    local up=pivot.UpVector
    local offset=up*(ground.Y+height-center.Y)
    local axis=rest:VectorToObjectSpace(pivot.RightVector)
    local fitted=CFrame.new(rest:VectorToObjectSpace(offset))*CFrame.fromAxisAngle(axis,-angle)
    body.Transform=body.Transform:Lerp(fitted,weight or 1)
    for _,foot in ipairs(self.Feet) do foot.Bone.Transform=CFrame.identity;foot.Stance=false end
    local lowest,corner,index=math.huge,nil,0
    local id=0
    for y=-1,1,2 do for z=-1,1,2 do
        id+=1
        local localCorner=rest:VectorToObjectSpace(pivot:VectorToWorldSpace(Vector3.new(0,y*hy,z*hz)))
        local point=body.TransformedWorldCFrame:PointToWorldSpace(localCorner)
        local elevation=(point-pivot:PointToWorldSpace(ground)):Dot(up)
        if elevation<lowest then lowest,corner,index=elevation,point,id end
    end end
    self.RollPoint,self.RollCorner,self.RollGroundError=corner,index,math.abs(lowest)
end

function Gait:Apply(weight)
    if self.Profile.Mode=="cube-roll" then self:ApplyCubeRoll(weight);return end
    if self.Profile.Mode~="walk" or not self.FitSpeed then return end
    local model=self.Player.Model
    local pivot=model:GetPivot()
    if self.Player.DogId=="Breadog" then
        -- Its source Root hop lifts the entire loaf beyond the rigid feet's
        -- reach. Keep 35% of that authored hop; no new body bounce is added.
        local root=self.Player.Bones.Root
        if root then
            local up=root.WorldCFrame:VectorToObjectSpace(pivot.UpVector)
            local original=root.Transform
            root.Transform=CFrame.new(original.Position-up*original.Position:Dot(up)*.65)*original.Rotation
        end
    end
    local phase=self.Phase
    for _,foot in ipairs(self.Feet) do
        local d,chain=foot.Definition,foot.Chain
        local bone=foot.Bone
        local probe=vector(d.Probe)*self.Scale
        local current=bone.TransformedWorldCFrame:PointToWorldSpace(probe)
        local localPoint=pivot:PointToObjectSpace(current)
        local center=vector(d.Center)*self.Scale
        local u=(phase-d.Start)%1
        local stroke=self.FitSpeed*d.Duty/math.max(self.FitFrequency,.001)
        -- Reach is constrained by the physical links in twoLink, never by
        -- translating/stretching a paw to an impossible target.
        local x,z,y,stance
        if u<d.Duty then
            z=center.Z+stroke*(u/d.Duty-.5)
            y=center.Y
            x=center.X
            stance=true
        else
            local swing=(u-d.Duty)/(1-d.Duty)
            z=center.Z+stroke*.5*math.cos(math.pi*swing)
            local lift=math.clamp(d.Lift*self.Scale,.04,d.Length*self.Scale*.65)
            y=math.max(localPoint.Y,center.Y+lift*math.sin(math.pi*swing))
            x=center.X+(localPoint.X-center.X)*math.sin(math.pi*swing)
        end
        local target=pivot:PointToWorldSpace(Vector3.new(x,y,z))
        target=current:Lerp(target,weight or 1)
        local before={}
        for i=1,#chain-1 do before[i]=(chain[i+1].TransformedWorldCFrame.Position-chain[i].TransformedWorldCFrame.Position).Magnitude end
        -- Rigid toy legs have no knee compression; allow their attachment to
        -- settle inside the torso. This is strictly bounded and preserves every
        -- visible leg segment length. Authored body/head/tail motion is intact.
        local hipRoot=chain[1]
        local goal=if #chain>=3 then target-bone.TransformedWorldCFrame.Rotation:VectorToWorldSpace(probe) else target
        local reach=if #chain<3 then probe.Magnitude else 0
        for _,length in ipairs(before) do reach+=length end
        if reach>1e-5 then
            local hipPoint=hipRoot.TransformedWorldCFrame.Position
            local dx,dz=goal.X-hipPoint.X,goal.Z-hipPoint.Z
            local needed=goal.Y+math.sqrt(math.max(0,reach*reach-dx*dx-dz*dz))
            local shift=math.clamp(needed-hipPoint.Y,-reach*.08,reach*.08)
            if #chain>=3 then shift=math.min(shift,0) end
            hipRoot.Transform *= CFrame.new(hipRoot.TransformedWorldCFrame:VectorToObjectSpace(Vector3.new(0,shift,0)))
            self.MaxHipShiftRatio=math.max(self.MaxHipShiftRatio,math.abs(shift)/reach)
            current=bone.TransformedWorldCFrame:PointToWorldSpace(probe)
        end
        if #chain>=3 then
            local hip,knee=chain[#chain-2],chain[#chain-1]
            local rotation=bone.TransformedWorldCFrame.Rotation
            local jointTarget=target-rotation:VectorToWorldSpace(probe)
            twoLink(hip,knee,function() return bone.TransformedWorldCFrame.Position end,jointTarget)
            -- Preserve the authored paw orientation after the knee/hip solve.
            bone.Transform *= bone.TransformedWorldCFrame.Rotation:ToObjectSpace(rotation)
        elseif #chain==2 then
            twoLink(chain[1],bone,function() return bone.TransformedWorldCFrame:PointToWorldSpace(probe) end,target)
        else
            rotateToward(bone,current-bone.TransformedWorldCFrame.Position,target-bone.TransformedWorldCFrame.Position,math.rad(55))
        end
        local actual=bone.TransformedWorldCFrame:PointToWorldSpace(probe)
        foot.Stance,foot.Point=stance==true,actual
        foot.Target=target
        if stance then
            self.StanceSamples+=1
            self.MaxTargetError=math.max(self.MaxTargetError,(actual-target).Magnitude)
        end
        for i=1,#chain-1 do
            local after=(chain[i+1].TransformedWorldCFrame.Position-chain[i].TransformedWorldCFrame.Position).Magnitude
            self.MaxLinkError=math.max(self.MaxLinkError,math.abs(after-before[i]))
        end
    end
end

return Gait
