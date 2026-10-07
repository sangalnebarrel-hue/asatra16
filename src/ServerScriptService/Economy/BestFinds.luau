-- Trophy copies are presentation only; they never consume or create inventory.
local S={}
local RS=game:GetService('ReplicatedStorage')
local Defs=require(RS.DogEconomy.DogDefinitions)
local Hooks=require(RS.DogDisplayHooks)
local Config=require(RS.DogEconomy.Config)
local function rank(d)return (Defs[d.DogId]or{}).Rank or table.find(Config.Rarities,d.Rarity)or 0 end
local function better(a,b,key)
 if not b then return true end
 local av,bv=tonumber(a[key])or 0,tonumber(b[key])or 0
 return av>bv or av==bv and tostring(a.ItemUid or a.DogUid)<tostring(b.ItemUid or b.DogUid)
end
function S.Select(p)
 local stats=p.Stats or {};local find,relic=stats.BestShowcaseFind,stats.BestShowcaseRelic
 local function offer(x)
  if not x or not x.ItemId then return end
  if x.Class=='Artifact'or x.Class=='Special'or x.Class=='Secret'then if better(x,relic,'SellValue')then relic=x end
  elseif better(x,find,'SellValue')then find=x end
 end
 offer(stats.MostValuable);offer(stats.Heaviest);offer(stats.Rarest)
 for _,x in pairs(p.Items or {})do offer(x)end
 for _,x in ipairs(p.DiscoveryFeed or {})do offer(x)end
 local dog
 for _,d in pairs(p.Dogs or {})do if d.OwnerUserId==p.UserId and d.State~='Walking'then
  local dr=rank(d);local br=dog and rank(dog)or -1
  if dr>br or dr==br and(better(d,dog,'Mastery'))then dog=d end
 end end
 return {Find=find,Dog=dog,Relic=relic}
end
local function bounds(model)
 local lo,hi=Vector3.one*math.huge,Vector3.one*-math.huge
 for _,p in ipairs(model:GetDescendants())do if p:IsA('BasePart')and p.Transparency<1 then
  for x=-1,1,2 do for y=-1,1,2 do for z=-1,1,2 do local q=p.CFrame:PointToWorldSpace(p.Size*Vector3.new(x,y,z)/2);lo=lo:Min(q);hi=hi:Max(q)end end end
 end end
 return lo,hi
end
local function clone(row,isDog,slot)
 local model
 if isDog then local def=Defs[row.DogId];local source=def and game.ServerStorage.DogTemplates:FindFirstChild(def.VisualAsset or row.DogId);model=source and source:Clone()
 else local ok,result=pcall(require(RS.DogEconomy.DiscoveryVisuals).Clone,row);model=ok and result or nil end
 if not model then return end
 for _,o in ipairs(model:GetDescendants())do
  if o:IsA('LuaSourceContainer')or o:IsA('LayerCollector')or o:IsA('ProximityPrompt')or o:IsA('Sound')or o:IsA('ParticleEmitter')then o:Destroy()
  elseif o:IsA('BasePart')then o.Anchored=true;o.CanCollide=false;o.CanTouch=false;o.CanQuery=false end
 end
 model:PivotTo(CFrame.identity);local lo,hi=bounds(model);local size=hi-lo
 if size.Y<=0 or size.Y==math.huge or size.X==math.huge then model:Destroy();return end
 model:ScaleTo(model:GetScale()*math.min(4.5/math.max(.01,size.X),4.9/math.max(.01,size.Y),4.5/math.max(.01,size.Z)))
 lo,hi=bounds(model);model:PivotTo(slot.CFrame*CFrame.new(-(lo.X+hi.X)/2,.16-lo.Y,-(lo.Z+hi.Z)/2))
 if isDog then
  local tint={Shiny=Color3.fromRGB(210,235,255),Golden=Color3.fromRGB(255,193,44),Corrupted=Color3.fromRGB(188,56,81),Glitched=Color3.fromRGB(210,87,255),Void=Color3.fromRGB(104,38,164)}
  if tint[row.Variant]then for _,o in model:GetDescendants()do if o:IsA('BasePart')then o.Color=o.Color:Lerp(tint[row.Variant],.38)end end end
 end
 model.Name='Exhibit';model:SetAttribute('PlotShowcase',true)
 if isDog then model:SetAttribute('DogId',row.DogId);model:SetAttribute('Variant',row.Variant);Hooks.Prepared(model,row.DogId,'BestFinds')end
 return model
end
function S.Clear(yard)
 S.Reconcile(yard,{UserId=0,Dogs={},Items={},Stats={}})
end
function S.Reconcile(yard,p)
 local deco=yard:FindFirstChild('PlotDevelopment');local stand=deco and deco:FindFirstChild('BestFinds');if not stand then return end
 local rows=S.Select(p)
 for _,key in ipairs({'Find','Dog','Relic'})do local slot=stand.Slots:FindFirstChild(key);local row=rows[key]
  local token=row and tostring(row.ItemUid or row.DogUid)..':'..tostring(row.Variant or row.Mutation)..':'..tostring(row.WeightKg or 0)or 'empty'
  if slot:GetAttribute('ExhibitToken')~=token then
   local old=slot:FindFirstChild('Exhibit');if old then old:Destroy()end
   local model=row and clone(row,key=='Dog',slot);if model then model.Parent=slot end
   slot:SetAttribute('ExhibitToken',token)
   local sign=stand:FindFirstChild('Name'..key);local label=sign and sign:FindFirstChild('Caption',true)
   if label then label.Text=row and(row.DisplayName or row.DogId or row.ItemId)or(key=='Dog'and 'ADOPT YOUR FIRST DOG'or 'YOUR NEXT RECORD AWAITS')end
  end
 end
end
return S
