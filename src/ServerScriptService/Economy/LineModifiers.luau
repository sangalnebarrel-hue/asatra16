-- The one place that decides how the tongue behaves right now. DogLineSpawner asks
-- Current(now) on every spawn and every frame; providers are modules in this folder that
-- export LineModifiers(now) -> a partial table (or nil). Today: ServerLuck (Robux server
-- luck) and WorldEventEffects (the world event's gameplay). They combine here, so server
-- luck and an event stack in exactly one way.
-- Fields a provider may return (all optional):
--  RankBoost      {[2..6]=x}  multiplies a rarity's tongue budget (LuckMath.Budgets)
--  BlockRankBoost {[2..6]=x}  the same for the tier of lucky blocks on the tongue
--  SpawnRate      x           entities per minute (2 = twice as many; product, .5..3)
--  BlockChance    0..1        share of spawns that are lucky blocks (highest wins)
--  SpeedScale     x           tongue speed (product, .25..2)
--  Variants       {Name=x}    weight multiplier per dog variant rolled at spawn (product)
--  ForceVariant   string      every dog spawned now gets this variant (first provider wins)
--  Freeze         bool        the tongue stops (every dog on it idles)
--  Labels         {string}    short texts describing what is active (logs, debug)
local RS=game:GetService('ReplicatedStorage')
local LuckMath=require(RS.LuckMath)
local M={}
M.ProviderNames={'ServerLuck','WorldEventEffects'}
local providers
local function load()
 if providers then return providers end
 providers={}
 for _,name in ipairs(M.ProviderNames)do
  local module=script.Parent:FindFirstChild(name)
  if module then
   local ok,mod=pcall(require,module)
   if ok and type(mod)=='table'and type(mod.LineModifiers)=='function'then table.insert(providers,{Name=name,Get=mod.LineModifiers})
   elseif not ok then warn('[LineModifiers]',name,mod)end
  end
 end
 return providers
end
local cache,cachedAt=nil,-1
function M.Current(now)
 now=now or workspace:GetServerTimeNow()
 if cache and math.abs(now-cachedAt)<.25 then return cache end
 local out={RankBoost=LuckMath.Combine(),BlockRankBoost=LuckMath.Combine(),SpawnRate=1,BlockChance=nil,SpeedScale=1,
  Variants={},ForceVariant=nil,Freeze=false,Labels={}}
 for _,provider in ipairs(load())do
  local ok,mods=pcall(provider.Get,now)
  if not ok then warn('[LineModifiers]',provider.Name,mods)
  elseif type(mods)=='table'then
   if mods.RankBoost then out.RankBoost=LuckMath.Combine(out.RankBoost,mods.RankBoost)end
   if mods.BlockRankBoost then out.BlockRankBoost=LuckMath.Combine(out.BlockRankBoost,mods.BlockRankBoost)end
   if type(mods.SpawnRate)=='number'then out.SpawnRate*=mods.SpawnRate end
   if type(mods.BlockChance)=='number'then out.BlockChance=math.max(out.BlockChance or 0,mods.BlockChance)end
   if type(mods.SpeedScale)=='number'then out.SpeedScale*=mods.SpeedScale end
   for name,x in pairs(mods.Variants or {})do if type(x)=='number'then out.Variants[name]=(out.Variants[name]or 1)*x end end
   if type(mods.ForceVariant)=='string'and not out.ForceVariant then out.ForceVariant=mods.ForceVariant end
   if mods.Freeze==true then out.Freeze=true end
   for _,label in ipairs(mods.Labels or {})do table.insert(out.Labels,label)end
  end
 end
 out.SpawnRate=math.clamp(out.SpawnRate,.5,3)
 out.SpeedScale=math.clamp(out.SpeedScale,.25,2)
 if out.BlockChance then out.BlockChance=math.clamp(out.BlockChance,0,.9)end
 cache,cachedAt=out,now
 return out
end
-- Forget the cached combination (a provider changed state this frame).
function M.Invalidate()cache=nil end
-- Spawns queued by providers (an event's "the next 5 dogs are Epic+", a guaranteed
-- Secret). DogLineSpawner takes one per spawn slot, before rolling.
-- spec: {DogId=id} | {Rank=n} | {MinRank=n} | {Block=tier}; optional Exclude={[id]=true}.
M.Queue={}
function M.QueueSpawn(spec,count)
 for _=1,math.max(1,math.floor(count or 1))do table.insert(M.Queue,table.clone(spec))end
end
function M.NextForced()return table.remove(M.Queue,1)end
-- The live tongue, published by DogLineSpawner once it runs (nil before that):
--  Entities() -> {Model}  everything walking the tongue (dogs and lucky blocks)
--  Remove(model, how?) -> bool  takes an entity off the tongue ('dissolve' by default)
--  SpawnDog(id) -> Model?, SpawnBlock(tier) -> Model?
--  Spawn, Stage, End : Vector3 (the throat, the Secret stage, the far end)
M.Line=nil
return M
