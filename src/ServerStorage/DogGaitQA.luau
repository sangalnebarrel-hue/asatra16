-- Studio-only diagnostics. Nothing runs unless a developer calls this module.
local QA = {}
local Rep = game:GetService("ReplicatedStorage")
local Storage = game:GetService("ServerStorage")
local Rig = require(Rep.DogRig)
local Animation = require(Rep.DogAnimationPlayer:Clone())
local Definitions = require(Rep.DogEconomy.DogDefinitions)
local gallery, players = nil, {}
local function ordered(ids)
    local list={}
    if ids then
        for _,id in ipairs(ids) do table.insert(list,{Id=id,Definition=assert(Definitions[id],id)}) end
    else
        for id,definition in pairs(Definitions) do table.insert(list,{Id=id,Definition=definition}) end
        table.sort(list,function(a,b)return a.Definition.Index<b.Definition.Index end)
    end
    return list
end
local function pose(player)
    local result={}
    for _,bone in ipairs(player.AllBones) do result[bone]=bone.Transform end
    return result
end
local function gap(a,b,excluded)
    local position,angle=0,0
    for bone,first in pairs(a) do
        local last=b[bone]
        if last and not (excluded and excluded[bone]) then
            position=math.max(position,(first.Position-last.Position).Magnitude)
            local _,r=(first:Inverse()*last):ToAxisAngle();angle=math.max(angle,math.abs(r))
        end
    end
    return position,angle
end
function QA.RunGait(ids,speed)
    assert(game:GetService("RunService"):IsStudio(),"Studio only")
    speed=speed or 4
    local result={Dogs=0,Speed=speed,Rows={},Failures={},Exemptions={},MaxLinkError=0,MaxPauseGap=0,
        WalkingDogs=0,RollingDogs=0,SlipBelowPointOne=0,SlipBelowPointFive=0,MaxHipShiftRatio=0,MaxMeanSlip=0,MaxTargetError=0}
    for _,entry in ipairs(ordered(ids)) do
        local model,player
        local ok,err=pcall(function()
            model=assert(Storage.DogTemplates:FindFirstChild(entry.Definition.VisualAsset)):Clone()
            assert(Rig.Prepare(model,Vector3.new(10,6,10)))
            model.Parent=workspace;model:SetAttribute("LocomotionSpeed",speed);model:SetAttribute("WorkState","DIGGING")
            player=Animation.new(model,entry.Id)
            assert(player:Play(assert(Animation.ResolveName(entry.Id,"Walk")),{Looped=true,FadeTime=0}))
            local gait=assert(player.Gait,"walk profile missing")
            assert(#gait.Feet==#gait.Profile.Feet,"walk contact bone missing")
            local base=workspace:GetServerTimeNow()
            gait.LastTime=base
            local last,slips,horizontal={}, {}, {}
            local previousRoll,maxRollGround=nil,0
            local stepTime=1/120
            for step=0,240 do
                local t=step*stepTime
                Rig.Place(model,Vector3.new(0,0,-speed*t))
                player:Step(base+t)
                if gait.RollPoint then
                    if previousRoll and previousRoll.Corner==gait.RollCorner then
                        local velocity=(gait.RollPoint-previousRoll.Point)/stepTime
                        table.insert(slips,velocity.Magnitude)
                        table.insert(horizontal,Vector3.new(velocity.X,0,velocity.Z).Magnitude)
                    end
                    maxRollGround=math.max(maxRollGround,gait.RollGroundError or 0)
                    previousRoll={Corner=gait.RollCorner,Point=gait.RollPoint}
                end
                for _,foot in ipairs(gait.Feet) do
                    local d=foot.Definition
                    local u=(gait.Phase-d.Start)%1
                    local previous=last[foot]
                    if foot.Stance and foot.Point and previous and previous.Stance and u>previous.U
                        and u>.08 and u<d.Duty-.08 then
                        local velocity=(foot.Point-previous.Point)/stepTime
                        assert(velocity.Magnitude==velocity.Magnitude,"nonfinite contact")
                        table.insert(slips,velocity.Magnitude)
                        table.insert(horizontal,Vector3.new(velocity.X,0,velocity.Z).Magnitude)
                    end
                    last[foot]={Point=foot.Point,Stance=foot.Stance,U=u}
                end
            end
            local before=pose(player)
            model:SetAttribute("LocomotionSpeed",0)
            player:Step(base+2.02);player:Step(base+2.08)
            local pauseGap,pauseAngle=gap(before,pose(player))
            assert(pauseGap<.001 and pauseAngle<.001,"pause drops contact fitting")
            player:RefreshRig()
            player:Step(base+2.1)
            local refreshedGap,refreshedAngle=gap(before,pose(player))
            assert(refreshedGap<.001 and refreshedAngle<.001,"streamed rig rebuild resets gait")
            model:SetAttribute("LocomotionSpeed",speed)
            Rig.Place(model,Vector3.new(0,0,-speed*2.02));player:Step(base+2.12)
            assert(player.Gait.Phase~=gait.Phase,"resume did not advance gait")
            local sum,hSum=0,0
            for _,n in ipairs(slips) do sum+=n end
            for _,n in ipairs(horizontal) do hSum+=n end
            table.sort(slips)
            local row={Dog=entry.Id,Mode=gait.Profile.Mode,CyclesPerSecond=gait.FitFrequency or 0,
                Reversed=gait.Profile.Reverse,MeanSlip=sum/math.max(1,#slips),MeanHorizontalSlip=hSum/math.max(1,#slips),
                P95Slip=slips[math.max(1,math.ceil(#slips*.95))] or 0,MaxTargetError=gait.MaxTargetError,
                MaxLinkError=gait.MaxLinkError,MaxHipShiftRatio=gait.MaxHipShiftRatio or 0,PauseGap=pauseGap,Contacts=#gait.Feet,
                RollGroundError=maxRollGround}
            table.insert(result.Rows,row)
            print("DOG_GAIT_ROW "..game:GetService("HttpService"):JSONEncode(row))
            assert(gait.MaxLinkError<.0001,"leg segment length changed: "..tostring(gait.MaxLinkError))
            assert(row.MaxHipShiftRatio<=.080001,"hip compensation exceeded eight percent")
            if gait.Profile.Mode~="walk" and gait.Profile.Mode~="cube-roll" then
                table.insert(result.Exemptions,entry.Id..":"..gait.Profile.Mode)
            else
                if gait.Profile.Mode=="cube-roll" then result.RollingDogs+=1 else result.WalkingDogs+=1 end
                if row.MeanSlip<.1 then result.SlipBelowPointOne+=1 end
                if row.MeanSlip<.5 then result.SlipBelowPointFive+=1 end
                result.MaxMeanSlip=math.max(result.MaxMeanSlip,row.MeanSlip)
                result.MaxTargetError=math.max(result.MaxTargetError,row.MaxTargetError)
            end
            result.MaxHipShiftRatio=math.max(result.MaxHipShiftRatio,row.MaxHipShiftRatio)
            result.MaxLinkError=math.max(result.MaxLinkError,gait.MaxLinkError)
            result.MaxPauseGap=math.max(result.MaxPauseGap,pauseGap)
            result.Dogs+=1
        end)
        if player then player:Destroy() end
        if model then model:Destroy() end
        if not ok then table.insert(result.Failures,{Dog=entry.Id,Error=tostring(err)}) end
        task.wait()
    end
    local summary=table.clone(result);summary.Rows=nil
    print("DOG_GAIT_QA "..game:GetService("HttpService"):JSONEncode(summary))
    return result
end
QA.Run=QA.RunGait
return QA
