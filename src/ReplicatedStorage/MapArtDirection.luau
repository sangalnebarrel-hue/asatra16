-- Subtle saturation pass; preserve authored materials and district palettes.
local M={}
local function has(n,words)
 for _,w in ipairs(words)do if n:find(w,1,true)then return true end end
 return false
end
function M.Apply()
 local map=workspace:WaitForChild('DOGROTS_District')
 local checker=map:FindFirstChild('CandyCheckerGround');if checker then checker:Destroy()end
 local restored,adjusted=0,0
 for _,p in ipairs(map:GetDescendants())do
  if p:IsA('BasePart')then
   local original=p:GetAttribute('ArtOriginalColor')
   local mat=p:GetAttribute('ArtOriginalMaterial')
   if original then p.Color=original;if mat and Enum.Material[mat]then p.Material=Enum.Material[mat]end;local shine=p:GetAttribute('ArtOriginalReflectance');if shine then p.Reflectance=shine end;restored+=1 end
   if p.Transparency<.9 and p.Material~=Enum.Material.Neon then
    local n=p.Name:lower()
    local isGroundGrass=has(n,{'livingground','yardfoundation','uppermeadow','grasslip','infield'})
    local isLandscape=has(n,{'livingground','yardfoundation','uppermeadow','grasslip','leaves','leafcluster','lowbush','lowhedge','voxelcanopy','planting','shrub','hedge','lawn','turf','infield'})
    local isArchitecture=has(n,{'islandmass','endstrata','weatheredbasalt','rockcourse','soil','trunk','kennelroof','kennelwall','pitchedroof','tonguesurface','tonguebed','tonguetip','promenade','boulevard','apron','forecourt'})
    if isLandscape or isArchitecture then
     if not original then original=p.Color;p:SetAttribute('ArtOriginalColor',original);p:SetAttribute('ArtOriginalMaterial',p.Material.Name)end
     if isGroundGrass then
      p.Color=Color3.fromRGB(95,210,47)
     else
      local h,s,v=original:ToHSV()
      p.Color=Color3.fromHSV(h,math.min(1,s+(isLandscape and .055 or .025)),math.min(1,v*1.025))
     end
     adjusted+=1
    end
    if has(n,{'livingground','yardfoundation','uppermeadow','grasslip','apron','promenade','boulevard'})then p:SetAttribute('EventTintSurface',true)end
   end
  end
 end
 map:SetAttribute('ArtDirection','Bright grass palette v3')
 workspace.Terrain.WaterColor=Color3.new(.05,.33,.36)
 print('DOGROTS_BRIGHT_GRASS',restored,adjusted)
 return restored,adjusted
end
return M
