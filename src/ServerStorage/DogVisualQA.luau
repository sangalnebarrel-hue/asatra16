-- Studio-only diagnostics. Nothing runs unless a developer calls this module.
local QA = {}
local Rep = game:GetService("ReplicatedStorage")
local Storage = game:GetService("ServerStorage")
local Rig = require(Rep.DogRig)
local Animation = require(Rep.DogAnimationPlayer)
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
function QA.Run()
    assert(game:GetService("RunService"):IsStudio(),"Studio only")
    local results={Dogs=0,Clips=0,Bones=0,Failures={},RecoveredWorkLoops={},FittedWorkClips={},MissingRoles={}}
    local workDuration=require(Rep.DogEconomy.Config).Work.Duration
    for _,entry in ipairs(ordered()) do
        local clone,player
        local ok,err=pcall(function()
            local template=assert(Storage.DogTemplates:FindFirstChild(entry.Definition.VisualAsset),"missing model")
            clone=template:Clone()
            local prepared=assert(Rig.Prepare(clone,Vector3.new(8,5,8)),"invalid visible bounds")
            assert(prepared.Size.Y<=5.001 and prepared.Size.X<=8.001 and prepared.Size.Z<=8.001,"size outside envelope")
            player=Animation.new(clone,entry.Id)
            assert(#player.AllBones>0,"missing skeleton")
            results.Bones+=#player.AllBones
            for _,role in ipairs({"Idle","Walk","Work"}) do
                if not Animation.ResolveName(entry.Id,role) then table.insert(results.MissingRoles,entry.Id.."/"..role) end
            end
            for _,name in ipairs(player:GetClipNames()) do
                assert(player:Play(name,{FadeTime=0}),"invalid clip "..name)
                for bone in pairs(player.Clip.Tracks) do assert(player.Bones[bone],"unbound track "..name.."/"..bone) end
                for _,fraction in ipairs({0,.17,.51,.91,1}) do player:Sample(player.Clip.Duration*fraction) end
                results.Clips+=1
            end
            local work=Animation.ResolveName(entry.Id,"Work")
            if work then
                local speed=Animation.GetWorkSpeed(entry.Id,work,workDuration)
                assert(player:Play(work,{Looped=true,FadeTime=0,Speed=speed}),"work cannot play")
                if player.Recovery>0 then
                    local completionSeconds=(player.Clip.Duration+player.Recovery)/player.Speed
                    assert(completionSeconds<=workDuration+.0001,"authored work action is interrupted before recovery")
                    table.insert(results.FittedWorkClips,{Dog=entry.Id,Speed=player.Speed,CompletionSeconds=completionSeconds})
                    player:Sample(.0001);local first=pose(player)
                    player:Sample(player.Clip.Duration+player.Recovery-.0001)
                    local p,a=gap(first,pose(player))
                    assert(p<.015 and a<.015,"work loop teleports at seam")
                    table.insert(results.RecoveredWorkLoops,{Dog=entry.Id,Clip=work,PositionGap=p,AngleGap=a})
                end
            end
            -- A state change must preserve the current pose at the start of its fade.
            local walk=assert(Animation.ResolveName(entry.Id,"Walk"),"walk unavailable")
            player:Play(walk,{FadeTime=0});player:Sample(player.Clip.Duration*.3)
            local before=pose(player)
            local hidden=table.clone(player.HiddenBones)
            local idle=assert(Animation.ResolveName(entry.Id,"Idle"),"idle unavailable")
            player:Play(idle,{FadeTime=.2});player:Sample(0,0)
            for bone in pairs(player.HiddenBones) do hidden[bone]=true end
            local p,a=gap(before,pose(player),hidden)
            assert(p<.001 and a<.002,"transition resets bind pose")
            player:Stop()
            for _,bone in ipairs(player.AllBones) do assert(bone.Transform==CFrame.identity,"stop did not reset") end
            results.Dogs+=1
        end)
        if player then player:Destroy() end
        if clone then clone:Destroy() end
        if not ok then table.insert(results.Failures,{Dog=entry.Id,Error=tostring(err)}) end
        if entry.Definition.Index%10==0 then task.wait() end
    end
    print("DOG_VISUAL_QA "..game:GetService("HttpService"):JSONEncode(results))
    return results
end
function QA.ClearGallery()
    for _,player in pairs(players) do player:Destroy() end
    table.clear(players)
    if gallery then gallery:Destroy();gallery=nil end
end
function QA.Gallery(ids,role)
    assert(game:GetService("RunService"):IsStudio(),"Studio only")
    QA.ClearGallery()
    gallery=Instance.new("Folder");gallery.Name="DogVisualQAGallery";gallery.Parent=workspace
    local cameras={}
    for i,entry in ipairs(ordered(ids)) do
        local model=assert(Storage.DogTemplates:FindFirstChild(entry.Definition.VisualAsset)):Clone()
        model.Name=entry.Id
        local prepared=assert(Rig.Prepare(model,Vector3.new(8,5,8)))
        local point=Vector3.new(((i-1)%10)*13,1000,math.floor((i-1)/10)*15)
        Rig.Place(model,point);model:SetAttribute("DogId",entry.Id);model.Parent=gallery
        local plate=Instance.new("Part");plate.Name=entry.Id.."_Stage";plate.Size=Vector3.new(11,.25,12)
        plate.Anchored=true;plate.Position=point-Vector3.new(0,.15,0);plate.Color=Color3.fromRGB(48,55,66);plate.Parent=gallery
        local text=Instance.new("BillboardGui");text.Size=UDim2.fromOffset(240,42)
        text.Adornee=model.PrimaryPart;text.StudsOffsetWorldSpace=Vector3.new(0,6,0);text.AlwaysOnTop=true;text.Parent=model
        local label=Instance.new("TextLabel");label.Size=UDim2.fromScale(1,1);label.BackgroundTransparency=1
        label.Text=entry.Definition.Index.." · "..entry.Id;label.TextColor3=Color3.new(1,1,1);label.TextSize=18;label.Parent=text
        local player=Animation.new(model,entry.Id);players[entry.Id]=player
        local clip=Animation.ResolveName(entry.Id,role or "Walk") or Animation.ResolveName(entry.Id,"Idle")
        player:Play(clip,{Looped=true,FadeTime=0});player:Sample(player.Clip.Duration*.35)
        cameras[entry.Id]=CFrame.lookAt(point+Vector3.new(8,5,-12),point+Vector3.new(0,2.5,0))
    end
    return cameras
end
function QA.Sample(seconds,role)
    for id,player in pairs(players) do
        if role then
            local name=Animation.ResolveName(id,role)
            if name and player.Name~=name then player:Play(name,{Looped=true,FadeTime=0}) end
        end
        player:Sample(seconds)
    end
end
function QA.RunGait(ids,speed)
    return require(Storage.DogGaitQA).Run(ids,speed)
end
function QA.WalkSample(seconds,speed)
    speed=speed or 4
    for i,entry in ipairs(ordered()) do
        local player=players[entry.Id]
        if player and player.Gait then
            local model=player.Model
            local point=Vector3.new(((i-1)%10)*13,1000,math.floor((i-1)/10)*15)
            -- Keep a selected gallery's own stage as its travel origin.
            local plate=gallery:FindFirstChild(entry.Id.."_Stage")
            if plate then point=plate.Position+Vector3.new(0,.15,0) end
            Rig.Place(model,point+Vector3.new(0,0,-speed*seconds))
            model:SetAttribute("LocomotionSpeed",speed)
            local gait=player.Gait
            gait.LastTime=seconds;gait:Advance(seconds,speed)
            gait.Phase=(seconds*gait.Frequency)%1
            gait.RollDistance=seconds*speed
            local phase=if gait.Profile.Reverse and gait.Profile.Mode=="walk" then (1-gait.Phase)%1 else gait.Phase
            player:Sample(phase*player.Clip.Duration)
            gait:Apply(1)
        end
    end
end
return QA
