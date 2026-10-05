-- Secret dogs arriving: every client plays the dog's arrival cinematic
-- (SecretArrivals/Dogs/<DogId>) from the server's SecretArrivalAt timestamp, so all
-- players see the same moment. On the tongue the server holds the dog on its stage for
-- SecretArrivalConfig.Dogs[id].Hold seconds while it plays; Secrets obtained elsewhere
-- arrive as display dogs in DOGROTS_SecretReveals (ServerScriptService/SecretReveal).
local RS=game:GetService('ReplicatedStorage')
local Run=game:GetService('RunService')
-- Studio's preview panel (★ SECRETS / F7) starts first, so nothing below can hold it up.
if Run:IsStudio()then
 local panel=script:FindFirstChild('StudioPanel')
 if panel then task.spawn(require,panel)else warn('[SecretArrivals] StudioPanel module is missing')end
end
local Config=require(RS:WaitForChild('SecretArrivalConfig'))
local Kit=require(script:WaitForChild('Kit'))
local Whisper=require(script:WaitForChild('Whisper'))
local Stare=require(script:WaitForChild('Stare'))
local Dogs=require(script:WaitForChild('Dogs'))
local line=workspace:WaitForChild('DOGROTS_District'):WaitForChild('03_DogLine')
local active=line:WaitForChild('ActiveDogs')
local played={}

local function now()return workspace:GetServerTimeNow()end
local function play(model)
 if not model:IsA('Model')then return end
 local at,id,uid=model:GetAttribute('SecretArrivalAt'),model:GetAttribute('DogId'),model:GetAttribute('DogUid')
 if type(at)~='number'or type(id)~='string'or not uid or played[uid]then return end
 local config,run=Config.Dogs[id],Dogs[id]
 if not config then return end
 -- A dog whose module failed to load still gets its whispers and reveal card.
 run=run or function(c)if c:Wait(c.Config.Hold*.55)then c:Title()end;c:Wait(c.Config.Hold)end
 local late=now()-at
 -- Too late for this arrival (joined or streamed in afterwards). THE DOG is the
 -- exception: its stare lasts as long as it is around.
 if late>Config.LateGrace and not config.StareSeconds then return end
 if late>(config.StareSeconds or 0)+config.Hold then return end
 played[uid]=true
 local scope=Kit.Scope('Arrival_'..id)
 local origin=model:GetAttribute('ArrivalOrigin')
 -- Venue: 'Tongue' (the conveyor), or off it: 'Yard' (a Lucky Block pad), 'Excavation'
 -- (a dig pit), 'Machine' (the DOG-O-MATIC stand). By: who got it (off-tongue only).
 local venue=model:GetAttribute('RevealVenue')
 local by=model:GetAttribute('RevealBy')
 local ctx={Model=model,DogId=id,Config=config,Start=at,Late=late,Scope=scope,Kit=Kit,Whisper=Whisper,Stare=Stare,
  Low=Kit.Low(),Origin=typeof(origin)=='Vector3'and origin or model:GetPivot().Position,
  Venue=type(venue)=='string'and venue or 'Tongue',By=type(by)=='string'and by~=''and by or nil,
  WhisperStyle=nil,ManualWhispers=false}
 -- Wait(t): yield until Start+t on the server clock; false once the arrival is over.
 function ctx:Wait(t)
  while scope.Alive do
   local remaining=at+t-now()
   if remaining<=0 then return true end
   task.wait(math.min(remaining,.1))
  end
  return false
 end
 function ctx:Elapsed()return now()-at end
 function ctx:Alive()return scope.Alive and model.Parent~=nil end
 function ctx:Ground()return Kit.Ground(model,ctx.Origin)end
 function ctx:Pivot()return Kit.Pivot(model,ctx.Origin)end
 -- Say(text, options): a whisper owned by this arrival; it fades when the arrival ends.
 local said
 function ctx:Say(text,options)said=Whisper.Say(text,options);return said end
 scope:Add(function()if said then Whisper.Clear(said,1.2)end end)
 -- Title(options): the reveal card with the dog's name in its colour.
 function ctx:Title(options)
  options=options or {}
  options.Color=options.Color or config.Color
  if ctx.By and not options.Tier then options.Tier='SECRET · '..string.upper(ctx.By)end
  Whisper.Title(config.Title,options)
 end
 -- The config's whispers are typed on schedule in ctx.WhisperStyle (Font, Color, Glitch,
 -- Chroma, Shake, Type), unless the arrival sets ctx.ManualWhispers before it first yields.
 task.defer(function()
  if ctx.ManualWhispers then return end
  for _,whisper in ipairs(config.Whispers or {})do
   if not ctx:Wait(whisper[1])then return end
   local style=table.clone(ctx.WhisperStyle or {})
   style.Color=style.Color or config.Color:Lerp(Color3.new(1,1,1),.55)
   ctx:Say(whisper[2],style)
  end
 end)
 -- The cinematic ends with the dog: sold and delivered, dissolved, or gone.
 local home=model.Parent
 scope:Add(model.AncestryChanged:Connect(function()if not home or not model:IsDescendantOf(home)then scope:Clean()end end))
 task.spawn(function()
  local ok,err=xpcall(run,debug.traceback,ctx)
  if not ok then warn('SecretArrivals '..id..':',err)end
  scope:Clean()
 end)
end

local function watch(model)
 play(model)
 if model:IsA('Model')and model:GetAttribute('SecretArrivalAt')==nil then
  -- Attributes can land just after the instance on a busy connection.
  local connection
  connection=model:GetAttributeChangedSignal('SecretArrivalAt'):Connect(function()connection:Disconnect();play(model)end)
  task.delay(5,function()if connection.Connected then connection:Disconnect()end end)
 end
end
local function follow(folder)
 folder.ChildAdded:Connect(watch)
 for _,model in ipairs(folder:GetChildren())do task.spawn(watch,model)end
 -- Drop remembered arrivals once their dogs are gone.
 folder.ChildRemoved:Connect(function(model)
  local uid=model:GetAttribute('DogUid')
  if uid then task.delay(5,function()played[uid]=nil end)end
 end)
end
follow(active)
-- Secrets obtained off the tongue arrive in DOGROTS_SecretReveals (server-made folder).
local reveals=workspace:FindFirstChild('DOGROTS_SecretReveals')
if reveals then follow(reveals)else
 local waiting
 waiting=workspace.ChildAdded:Connect(function(child)
  if child.Name=='DOGROTS_SecretReveals'and child:IsA('Folder')then waiting:Disconnect();follow(child)end
 end)
end
print('DOGROTS_SECRET_ARRIVALS_READY')
