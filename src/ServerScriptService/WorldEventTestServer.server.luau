-- The remote exists only inside Studio; live servers never expose test controls.
local Run=game:GetService('RunService')
if not Run:IsStudio() then return end
local RS=game:GetService('ReplicatedStorage')
local Players=game:GetService('Players')
local package=RS:WaitForChild('WorldEvents')
local Config=require(package.WorldEventConfig)
if not Config.Debug.EnabledInStudio then return end
local Service=require(script.Parent.WorldEventService)
local Definitions=require(package.WorldEventDefinitions)
local remote=Instance.new('RemoteFunction');remote.Name='StudioEventControl';remote.Parent=package
local last={}
Players.PlayerRemoving:Connect(function(p)last[p]=nil end)
remote.OnServerInvoke=function(player,action,id,duration,warning)
 if not Run:IsStudio() or not Config.Debug.EnabledInStudio then return false,'Studio only' end
 if type(action)~='string' then return false,'Invalid action' end
 if os.clock()-(last[player] or -10)<.45 then return false,'Please wait a moment' end
 last[player]=os.clock()
 if action=='start' then
  if type(id)~='string' or not Definitions.ById[id] then return false,'Unknown event' end
  if type(duration)~='number' or duration~=duration then return false,'Invalid duration' end
  duration=math.clamp(math.floor(duration),15,600)
  local ok,err=pcall(Service.Force,id,duration,warning==true and 5 or 0)
  return ok,ok and ('Started '..Definitions.ById[id].DisplayName) or tostring(err)
 elseif action=='stop' then
  Service.Force('stop');return true,'Stopped. Schedule paused.'
 elseif action=='resume' then
  Service.DebugState=nil;Service.Tick();return true,'Automatic schedule resumed'
 elseif action=='signature' then
  -- The full signature: cinematic, pickups and its gameplay (Effects.Signature).
  local ok,success,message=pcall(Service.Signature)
  if not ok then return false,tostring(success) end
  return success,message
 end
 return false,'Unknown action'
end
print('DOGROTS_STUDIO_EVENT_PANEL_READY')
