-- Imported emission masks were enabled at full strength even on ordinary fur/food.
-- Keep the authored albedo, PBR maps, colors, materials and visible geometry intact.
local Definitions=require(script.Parent.DogEconomy.DogDefinitions)
local P={Version=1}
local assets={}
for id,def in pairs(Definitions)do assets[def.VisualAsset]=id end

-- Intentional luminous designs retain a restrained masked glow. Rarity alone
-- never enables emission; ordinary dogs (including Potato and Zombark) use zero.
P.EmissionCaps={
 Firepup=.32,GamerDog=.12,Astrodoggo=.15,Mushpup=.10,FrostHusky=.14,
 LavaBull=.32,BooHound=.15,NeonHound=.30,Glitchiba=.20,DiscoDoggo=.18,
 TvTerrier=.16,ArcadeAkita=.18,CyberCorgi=.18,Robopug3000=.12,MechaShiba=.12,
 RocketDachshund=.15,UfoDog=.24,AngelDoggo=.20,DemonDoggo=.20,WizardWoof=.20,
 Necrohound=.12,MechaBark=.14,Poseidog=.14,ThunderHusky=.28,InfernoBull=.35,
 DragonShiba=.15,DJBarkbeat=.20,Cerberdog=.12,GalaxyHusky=.30,BlackHolePug=.25,
 TimeDog=.16,GodOfBark=.22,Moonmoon=.18,SunDog=.35,VoidHound=.22,
 DogeEmperor=.12,Dogzilla=.14,WrongDog=.10,['404Dog']=.20,NuclearPug=.25,
 DivineDog=.22,UnfinishedDog=.12,TheDog=.18,Aurion=.24,
}
P.PartEmissionCaps={
 Vampug={ruby=.12},SharkdogPrime={eyes=.16},KingCorgi={ruby=.10},
}
-- Explicitly named light-bearing mesh pieces keep stronger highlights while
-- their body/fur pieces use the per-dog cap. These tokens do not match plain eyes/feet.
P.LuminousPartTokens={'neon','emissive','glow','reactor','screen','display','flame','hellfire','plasma','halo','lightning','energy'}

function P.ResolveId(model,id)
 if id and Definitions[id]then return id end
 local tagged=model:GetAttribute('DogId')
 if tagged and Definitions[tagged]then return tagged end
 if Definitions[model.Name]then return model.Name end
 return assets[model.Name]
end

function P.EmissionCap(id,partName)
 local cap=P.EmissionCaps[id]or 0
 local name=string.lower(partName or '')
 for token,strength in pairs(P.PartEmissionCaps[id]or{})do
  if string.find(name,token,1,true)then cap=math.max(cap,strength)end
 end
 for _,token in ipairs(P.LuminousPartTokens)do
  if string.find(name,token,1,true)then return math.max(cap,.40)end
 end
 return cap
end

function P.Apply(model,id)
 id=P.ResolveId(model,id)
 if not id then return 0 end
 local changed=0
 for _,appearance in ipairs(model:GetDescendants())do
  if appearance:IsA('SurfaceAppearance')then
   local part=appearance.Parent
   local preserved=appearance:GetAttribute('PreserveDogEmission')==true
    or(part and part:GetAttribute('PreserveDogEmission')==true)
    or model:GetAttribute('PreserveDogEmission')==true
   if not preserved then
    local cap=P.EmissionCap(id,part and part.Name)
    local explicit=appearance:GetAttribute('DogEmissionCap')
    if type(explicit)=='number'then cap=math.clamp(explicit,0,1)end
    local ok,current=pcall(function()return appearance.EmissiveStrength end)
    if ok then
     local original=appearance:GetAttribute('DogRenderOriginalEmission')
     if type(original)~='number'then original=current;appearance:SetAttribute('DogRenderOriginalEmission',original)end
     local target=math.min(original,cap)
     -- Roblox stores this property as float32; Lua caps are doubles.
     -- Ignore roundoff so an already repaired template is not rewritten.
     if math.abs(current-target)>1e-6 then appearance.EmissiveStrength=target;changed+=1 end
     appearance:SetAttribute('DogRenderVersion',P.Version)
    end
   end
  end
 end
 model:SetAttribute('DogRenderVersion',P.Version)
 return changed
end

function P.ApplyViewport(view)
 -- Directional key + moderate fill restores shape to bright textured dogs.
 view.Ambient=Color3.fromRGB(92,103,120)
 view.LightColor=Color3.fromRGB(212,216,225)
 view.LightDirection=Vector3.new(-.65,-1,-.8)
end

function P.ApplyTemplates()
 -- Explicit edit-time repair. Rig.Prepare also applies the same profile to live clones.
 -- Template persistence covers display/lab clones that do not use the rig-size helper.
 local report={Version=P.Version,Models=0,TemplateModels=0,Appearances=0,EmissionChanges=0}
 local seen={}
 local function scan(container,isTemplate)
  if not container then return end
  for _,model in ipairs(container:GetDescendants())do
   if model:IsA('Model')and not seen[model]and P.ResolveId(model)then
    seen[model]=true;report.Models+=1
    if isTemplate then report.TemplateModels+=1 end
    for _,node in ipairs(model:GetDescendants())do if node:IsA('SurfaceAppearance')then report.Appearances+=1 end end
    report.EmissionChanges+=P.Apply(model)
   end
  end
 end
 scan(game:GetService('ServerStorage'):FindFirstChild('DogTemplates'),true)
 scan(game:GetService('StarterGui'),false)
 scan(game:GetService('ReplicatedStorage'),false)
 scan(workspace,false)
 return report
end

return P
