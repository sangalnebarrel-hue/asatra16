-- Client-side "every dog looks at something" (THE DOG's stare). One look at a time; when two
-- overlap (two THE DOGs) the newer leads and the older resumes once it ends.
-- DogAnimations.client applies it to every animated dog it steps (DogAnimationPlayer
-- .Look → ApplyLook); SecretArrivals/Stare applies it to the static display dogs.
-- Bone transforms only, so nothing replicates and clearing the look is the restore.
local L={Current=nil}
local function smooth(a)a=math.clamp(a,0,1);return a*a*(3-2*a)end
-- Looks still running, oldest first.
local running={}

--[[ L.Begin(spec) → handle
 spec.Target   function() → Vector3? world point to look at (nil keeps the last one)
 spec.Exclude  the model being looked at
 spec.Turn     seconds for a body to turn (default .9); heads lead by .15 s
 spec.Ripple   studs per second the turn spreads out from the target (default 140)
 handle:Stop(seconds) eases every dog back, then ends the look.
 handle:Bow(radians, seconds) every looking head dips by `radians` and comes back. ]]
function L.Begin(spec)
 local look={Target=spec.Target,Exclude=spec.Exclude,Turn=spec.Turn or .9,Ripple=spec.Ripple or 140,
  Started=os.clock(),Focus=nil,FocusAt=-math.huge,StopAt=nil,StopTime=1,BowAt=nil,BowAngle=0,BowTime=1}
 L.Current=look
 table.insert(running,look)
 local handle={}
 function handle:Bow(radians,seconds)look.BowAt,look.BowAngle,look.BowTime=os.clock(),radians,math.max(seconds or 1,.2)end
 function handle:Stop(seconds)
  if look.StopAt then return end
  look.StopTime=math.max(seconds or 1,.05);look.StopAt=os.clock()
  task.delay(look.StopTime+.05,function()
   local i=table.find(running,look)
   if i then table.remove(running,i)end
   if L.Current==look then L.Current=running[#running]end
  end)
 end
 function handle:Focus()return L.Focus(look)end
 return handle
end
-- The target is resolved at most once per frame for all dogs.
function L.Focus(look)
 local now=os.clock()
 if now-look.FocusAt>1/240 then
  look.FocusAt=now
  local ok,t=pcall(look.Target)
  if ok and typeof(t)=='Vector3'then look.Focus=t end
 end
 return look.Focus
end
--[[ L.For(model, state, position?, moving?) → body, head, target, bow   (nil when not looking)
 state is the caller's per-model table (it remembers when this dog joined the look).
 Dogs that are walking turn their body only partly so their feet do not skate. ]]
function L.For(model,state,position,moving)
 local look=L.Current
 if not look or model==look.Exclude then state.LookJoined=nil;return nil end
 local target=L.Focus(look)
 if not target then return nil end
 local now=os.clock()
 if state.LookOf~=look then
  state.LookOf=look
  local distance=position and (position-target).Magnitude or 0
  state.LookDelay=math.min(1.4,distance/look.Ripple)+math.random()*.2
  state.LookJoined=now
  state.MoveScale,state.MoveClock=nil,nil
 end
 local begin=math.max(look.Started+state.LookDelay,state.LookJoined)
 local age=now-begin
 local head=smooth(age/.35)
 local body=smooth((age-.15)/look.Turn)
 -- Walking caps the body turn at .4; the cap eases in and out (the tongue starts and
 -- stops under THE DOG) instead of snapping. state.MoveScale is the current cap.
 local goal=moving and .4 or 1
 local scale=state.MoveScale or goal
 if state.MoveClock then scale+=(goal-scale)*math.min(1,(now-state.MoveClock)*2.5)end
 if math.abs(goal-scale)<1e-3 then scale=goal end
 state.MoveScale,state.MoveClock=scale,now
 body*=scale
 if look.StopAt then
  local release=1-smooth((now-look.StopAt)/look.StopTime)
  head*=release;body*=release
 end
 -- A bow dips in over the first quarter, holds, and rises over the last quarter.
 local bow=0
 if look.BowAt then
  local a=(now-look.BowAt)/look.BowTime
  if a<1 then bow=look.BowAngle*smooth(math.min(a*4,1))*smooth(math.min((1-a)*4,1))end
 end
 return body,head,target,bow
end
return L
