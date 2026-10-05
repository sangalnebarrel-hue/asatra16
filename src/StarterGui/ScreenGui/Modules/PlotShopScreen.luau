local RS=game:GetService('ReplicatedStorage')
local C=require(RS.PlotCatalog);local A=require(RS.PlotAppearance)
local Screen={}
function Screen.Build(c)
 local U,p,s,root,W,H=c.U,c.Snapshot.Profile,c.State,c.Parent,c.W,c.H;local P=U.Colors
 local owned=p.PlotSkins or {Classic=true};local selected=C.Skins[s.SelectedPlotSkin]and s.SelectedPlotSkin or p.EquippedPlotSkin or 'Classic'
 local d=C.Skins[selected];local accent=C.Color(d.Glow);local level=C.Level(p)
 local count=0;for _,id in ipairs(C.Order)do if owned[id]then count+=1 end end
 local function choose(id)s.SelectedPlotSkin=id;c.Draw()end
 local mobile=c.Mobile or W<640
 local listW=mobile and W or math.floor(W*.30)
 local bodyX=mobile and 0 or listW+14;local bodyW=W-bodyX-8
 local body=U.Scroll(root,'PlotDetails',bodyX,mobile and 62 or 0,bodyW,mobile and H-62 or H)
 if mobile then
  U.Cycle(root,'SkinPicker',d.Name,C.Order,selected,0,0,W,function(id)choose(id)end)
 else
  local list=U.Scroll(root,'PlotSkinCatalog',0,0,listW,H)
  U.Text(list,'PLOT COLLECTION',8,0,listW-16,31,20,P.gold,true)
  U.Text(list,count..' / '..#C.Order..' OWNED',8,33,listW-16,23,14,P.muted)
  for i,id in ipairs(C.Order)do
   local entry=C.Skins[id];local status=id==p.EquippedPlotSkin and 'EQUIPPED'or owned[id]and 'OWNED'or C.Earned(p,id)and 'CLAIM FREE'or entry.Rarity:upper()
   local b=U.Button(list,'Skin_'..id,entry.Name..'\n'..status,5,66+(i-1)*68,listW-16,59,function()choose(id)end,id==selected and C.Color(entry.Glow):Lerp(P.navy,.35)or P.nav)
   b.Caption.TextSize=19
  end
 end
 U.Text(body,d.Name,8,0,bodyW-16,38,27,accent,true)
 U.Text(body,d.Rarity:upper()..'  /  YARD LEVEL '..level,8,38,bodyW-16,24,15,P.muted,true)
 local viewport=Instance.new('ViewportFrame');viewport.Name='LivePlotPreview';viewport.Position=UDim2.fromOffset(8,70);viewport.Size=UDim2.fromOffset(bodyW-16,mobile and 200 or 255)
 viewport.BackgroundColor3=Color3.fromRGB(23,29,39);viewport.BorderSizePixel=0;viewport.Ambient=Color3.fromRGB(175,175,185);viewport.LightColor=Color3.new(1,1,.94);viewport.LightDirection=Vector3.new(-1,-1,-.5);viewport.Parent=body
 local map=workspace:FindFirstChild('DOGROTS_District');local yards=map and map:FindFirstChild('04_PlayerYards');local source
 if yards then for _,yard in ipairs(yards:GetChildren())do if yard:GetAttribute('OwnerUserId')==game.Players.LocalPlayer.UserId then source=yard;break end end
  if not source then for _,yard in ipairs(yards:GetChildren())do if yard:GetAttribute('YardId')then source=yard;break end end end
 end
 if source then
  local model=A.Preview(source,s.PlotPreviewMax and 9 or level,selected);model.Parent=viewport
  local camera=Instance.new('Camera');camera.FieldOfView=35
  local f=A.Frame(model);local target=f.Position+Vector3.new(0,3,0)
  camera.CFrame=CFrame.lookAt(target+f:VectorToWorldSpace(Vector3.new(90,120,140)),target);camera.Parent=viewport;viewport.CurrentCamera=camera
 end
 local y=mobile and 280 or 335
 U.Button(body,'PreviewStage',s.PlotPreviewMax and 'PREVIEW: MEGA ESTATE' or 'PREVIEW: YOUR STAGE',8,y,bodyW-16,34,function()s.PlotPreviewMax=not s.PlotPreviewMax;c.Draw()end,P.blue);y+=43
 U.Text(body,d.Description,8,y,bodyW-16,52,17,P.text);y+=57
 U.Text(body,'Purely cosmetic. Skins never change digging odds or income.',8,y,bodyW-16,38,14,P.muted);y+=42
 local equipped=p.EquippedPlotSkin==selected or selected=='Classic'and not p.EquippedPlotSkin
 if owned[selected]then
  U.Button(body,'EquipSkin',equipped and 'EQUIPPED' or 'EQUIP ON MY YARD',8,y,bodyW-16,44,not equipped and function()c.Send('EquipPlotSkin',{Id=selected})end or nil,P.green);y+=54
 else
  if d.Cash then
   U.Button(body,'PurchaseSkin','BUY · '..U.Fmt(d.Cash)..' CASH',8,y,bodyW-16,44,p.Cash>=d.Cash and function()c.Confirm('BUY '..d.Name,'Unlock permanently for '..U.Fmt(d.Cash)..' Cash and equip on your plot.','BuyPlotSkin',{Id=selected})end or nil,P.green);y+=52
  end
  local earned=C.Earned(p,selected)
  U.Button(body,'ClaimSkin',earned and 'CLAIM FREE EVENT REWARD'or 'EVENT REWARD LOCKED',8,y,bodyW-16,42,earned and function()c.Send('ClaimPlotSkin',{Id=selected})end or nil,earned and P.green or P.nav);y+=49
  U.Text(body,C.Requirement(p,selected),8,y,bodyW-16,57,15,P.muted);y+=63
  U.Text(body,'Buy and claim at the terminal inside COSMETICS. Owned skins can be equipped anywhere.',8,y,bodyW-16,50,15,P.muted);y+=57
 end
 U.Text(body,'YOUR ESTATE / '..C.Stages[level].Name,8,y,bodyW-16,30,19,P.gold,true);y+=34
 U.Text(body,C.Stages[level].Feature..'\n'..C.Slots(p)..' / 5 kennels · +'..((level-1)*2.5)..'% find value',8,y,bodyW-16,58,16,P.text);y+=66
 if level<9 then U.Text(body,'NEXT: '..C.Stages[level+1].Name..' · '..U.Fmt(C.Cost(level))..' Cash\n'..C.Stages[level+1].Feature,8,y,bodyW-16,70,16,P.muted);y+=76 end
 U.Button(body,'Workshop','FIND ESTATE UPGRADES AT PAW MARKET',8,y,bodyW-16,40,function()require(c.Gui.Modules.GUIIntegration).Navigate('Shops')end,P.gold)
 y+=56
 local titles={};local legacy={GoldenKennel=true,CyberKennel=true,VoidAura=true}
 for id,isOwned in pairs(p.Cosmetics or {})do if isOwned and not legacy[id]then table.insert(titles,id)end end
 table.sort(titles)
 if #titles>0 then
  U.Text(body,'YOUR COLLECTION TITLES',8,y,bodyW-16,30,19,P.gold,true);y+=37
  for _,id in ipairs(titles)do
   U.Button(body,'Title_'..id,id..(p.EquippedCosmetic==id and ' / EQUIPPED'or ''),8,y,bodyW-16,38,function()c.Send('Cosmetic',{Kind=id})end,P.nav);y+=46
  end
 end
end
return Screen
