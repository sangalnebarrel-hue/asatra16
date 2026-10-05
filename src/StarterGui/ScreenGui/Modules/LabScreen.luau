local S={}
local RS=game.ReplicatedStorage
local C=require(RS.LabConfig)
local Definitions=require(RS.DogEconomy.DogDefinitions)
local Items=require(RS.DogEconomy.ItemDefinitions)
local Access=require(RS.LabAccess)
local Http=game:GetService('HttpService')
local stages={'DOG','PROCEDURE','MATERIALS','PREVIEW','CONFIRM','EXPERIMENT','RESULT'}
local function RCopy(t)local out={};for k,v in pairs(t)do out[k]=v end;return out end
local function mapText(t,names)
 local lines={};for k,n in pairs(t or{})do table.insert(lines,(names and names[k]or k)..' × '..tostring(n))end;table.sort(lines);return #lines>0 and table.concat(lines,' / ')or'None'
end
function S.Build(c)
 local U,V=c.U,require(script.Parent.PreviewRenderer);local P=U.Colors;local p=c.Snapshot.Profile;local l=p.Lab or{DNA={},Tier=1,History={},Recipes={}}
 local s=c.State.LabUI
 if not s then s={Step=1,Uids={},Items={},DNA={},Procedure='Mutation',RecipeId='',StabilizerUid='',Revision=0};c.State.LabUI=s end
 local function redraw()if c.Gui:GetAttribute('OpenMenu')=='Lab'then c.Draw()end end
 local function changed()s.Preview=nil;s.Pending=nil;s.Message=nil;s.Typed='';s.Revision+=1;redraw()end
 local function query(action,args,done,receipt)
  if s.Busy then return end;s.Busy=true;s.Message=nil;redraw()
  local rev=s.Revision
  task.spawn(function()
   local transport,ok,value=pcall(function()return RS.DogEconomyRequest:InvokeServer(action,args,receipt or Http:GenerateGUID(false):gsub('-',''))end)
   s.Busy=false
   if not transport then s.Message='Connection interrupted. Retry the same confirmation safely.'
   elseif not ok then s.Message=tostring(value)
   elseif rev==s.Revision then
    if action=='LabInfo'then require(script.Parent.LabPresentation).Cue('Console',Access.Model():FindFirstChild('AudioAnchor'))end
    done(value)
   end
   if action=='LabCommit'and transport and ok then require(script.Parent.Menus).Active:Fetch(true)end
   redraw()
  end)
 end
 local function reset()
  s.Step=1;s.Uids={};s.Items={};s.DNA={};s.RecipeId='';s.Result=nil;s.Preview=nil;s.Typed='';s.StabilizerUid='';s.Pending=nil;s.Message=nil;s.Revision+=1;redraw()
 end
 local sc=U.Scroll(c.Parent,'GeneticsContent',0,0,c.W,c.H)
 local green=P.green;local purple=P.purple
 U.Text(sc,'GENETICS DIVISION',8,0,c.W-74,34,23,P.text,true)
 U.Button(sc,'LabHelp','?',c.W-50,0,42,34,function()s.HelpOpen=not s.HelpOpen;redraw()end,P.blue)
 s.Archive=nil -- Only archive navigation is retired; saved genetics data remains intact.
 if s.HelpOpen then
  local width=math.min(c.W-16,660);local narrow=width<450
  local rowH=narrow and 132 or 90;local firstY=narrow and 164 or 136;local helpH=firstY+#C.Procedures*rowH+14
  local help=U.Panel(sc,'LabQuickGuide',(c.W-width)/2,49,width,helpH,true)
  U.Text(help,'LAB GUIDE',16,10,width-83,42,23,P.text,true)
  U.Button(help,'CloseHelp','X',width-59,11,42,35,function()s.HelpOpen=false;redraw()end,P.red)
  U.Text(help,'Choose an unlocked dog → choose a procedure → preview the exact chances and costs → confirm.',18,57,width-36,narrow and 90 or 70,19,P.text)
  local y=firstY
  for _,proc in ipairs(C.Procedures)do
   local titleH=narrow and 44 or 25
   U.Text(help,proc.Name..' · LEVEL '..proc.Level,18,y,width-36,titleH,18,P.purple,true)
   U.Text(help,proc.Description,18,y+titleH+6,width-36,narrow and 74 or 49,18,P.muted);y+=rowH
  end
  local notesY=49+helpH+18
  U.Text(sc,'Mutation keeps your dog. Extraction consumes it. Fusion and creation show all consumed dogs before confirmation.',14,notesY,c.W-28,80,18,P.text)
  U.Text(sc,'Locked, favorite, working and displayed dogs must be released first. Optional stabilizers improve stability; the server preview shows the final chances.',14,notesY+88,c.W-28,102,18,P.muted)
  return
 end
 if not Access.CanUse(game.Players.LocalPlayer)then
  U.AssetIcon(sc,'Lab',(c.W-144)/2,48,144)
  local narrow=c.W<450;local title=narrow and 'A LITTLE SCIENCE.\nA BIG UPGRADE.'or'A LITTLE SCIENCE. A BIG UPGRADE.'
  U.Center(sc,title,14,200,c.W-30,narrow and 68 or 46,28,P.text,true)
  U.Center(sc,'Visit the genetics terminal to discover new possibilities for your dogs.',narrow and 16 or 45,narrow and 278 or 251,c.W-(narrow and 32 or 90),narrow and 80 or 56,20,P.muted)
  local buttonW=math.min(300,c.W-24);local buttonY=narrow and 369 or 329
  U.Button(sc,'VisitLab','SHOW THE WAY',(c.W-buttonW)/2,buttonY,buttonW,54,function()c.Go('Mutation lab')end,P.purple)
  if s.Result then U.Center(sc,s.Result.Message,14,buttonY+71,c.W-30,70,20,P.text,true)end
  return
 end
 if not s.Info then
  U.Text(sc,s.Message or'Connecting to the genetics terminal…',14,75,c.W-30,70,23,P.muted)
  U.Button(sc,'ConnectLab','CONNECT',14,160,math.min(320,c.W-30),45,function()query('LabInfo',{},function(v)s.Info=v end)end,green)
  if not s.Busy and not s.Message then task.defer(function()query('LabInfo',{},function(v)s.Info=v end)end)end
  return
 end
 U.Text(sc,'STEP '..s.Step..' OF '..#stages..'  /  '..stages[s.Step],8,43,c.W-18,29,20,P.text,true)
 local bw=(c.W-18)/#stages
 for i in ipairs(stages)do
  local marker=U.Frame(sc,'Stage'..i,8+(i-1)*bw,77,bw-6,7,i<=s.Step and purple or P.secondary)
  U.Round(marker,4)
 end
 local tutorial=not l.TutorialComplete or s.ReplayTutorial
 local tips={'Choose one dog from your inventory.','Choose Mutation for your first experiment.','Your first mutation uses a complimentary starter reagent. Later experiments cost Coins and Bones.','These are the actual server-calculated chances. Your dog always survives a mutation.','Review the changes, then start the experiment.','Watch the chamber. Your result is already saved.','Your result and DNA are saved in your lab inventory.'}
 U.Text(sc,tutorial and tips[s.Step]or('LAB LEVEL '..l.Tier..' · '..(s.Busy and'Processing…'or'Choose, preview, then confirm.')),8,92,c.W-18,54,18,P.text)
 local top=154
 if s.Message then U.Text(sc,s.Message,8,top,c.W-18,62,18,P.gold);top+=70 end
 if s.Step==7 and s.Result then
  local result=s.Result;local panel=U.Panel(sc,'LabResult',6,top,c.W-22,360,true)
  U.Text(panel,result.Success and'EXPERIMENT COMPLETE'or'UNSTABLE RESULT',18,12,c.W-62,38,27,result.Success and green or purple,true)
  if result.Dog then V.Dog(panel,result.Dog,15,62,math.min(240,c.W*.36),190)end
  U.Text(panel,result.Message,c.W*.39,64,c.W*.55-25,100,23,P.text,true)
  U.Text(panel,'DNA: '..mapText(result.DNA,C.DNA)..'\nDogs consumed: '..#result.Consumed,c.W*.39,172,c.W*.55-25,84,18,P.muted)
  U.Button(panel,'NextExperiment','NEW EXPERIMENT',16,286,c.W-54,45,function()s.Info=nil;reset()end,green)

  return
 end
 local mobile=c.Mobile;local leftW=mobile and c.W-20 or math.floor(c.W*.26);local centerW=mobile and c.W-20 or math.floor(c.W*.37);local rightW=mobile and c.W-20 or c.W-leftW-centerW-32
 local left=U.Panel(sc,'LabDogPanel',6,top,leftW,525,true)
 local center=U.Panel(sc,'LabProcedurePanel',mobile and 6 or leftW+16,mobile and top+540 or top,centerW,525,true)
 local right=U.Panel(sc,'LabPreviewPanel',mobile and 6 or leftW+centerW+26,mobile and top+1080 or top,rightW,525,true)
 U.Text(left,'01 / YOUR DOG',12,8,leftW-24,32,21,green,true)
 local d=s.Uids[1]and p.Dogs[s.Uids[1]]
 if d then
  V.Dog(left,d,10,43,leftW-20,153)
  U.Text(left,d.DisplayName,12,199,leftW-24,32,22,P.text,true)
  U.Text(left,d.Rarity..' / '..d.Variant..'\nMastery '..d.Mastery..' / Ascension '..d.AscensionLevel..'\n'..(d.Locked and'LOCKED'or'Unlocked')..' / '..(d.Favorite and'FAVORITE'or'Not favorite'),12,234,leftW-24,80,16,P.muted)
  U.Text(left,'Choose another dog below.',12,324,leftW-24,45,16,P.muted)
 else U.Center(left,'SELECT A DOG',10,70,leftW-20,130,23,P.muted,true)end
 local doglist=U.Scroll(left,'LabDogList',10,d and 386 or 224,leftW-20,d and 128 or 284)
 local dogs={};for _,dog in pairs(p.Dogs)do table.insert(dogs,dog)end;table.sort(dogs,function(a,b)return a.DisplayName==b.DisplayName and a.DogUid<b.DogUid or a.DisplayName<b.DisplayName end)
 for i,dog in dogs do
  local index=table.find(s.Uids,dog.DogUid);local unavailable=dog.Locked or dog.Favorite or dog.State~='Inventory'
  for _,uid in pairs(p.DisplayDogs or{})do if uid==dog.DogUid then unavailable=true end end
  U.Button(doglist,'LabDog_'..dog.DogUid,(index and(index..' · ')or'')..dog.DisplayName..(unavailable and' · REMOVE / UNLOCK'or''),1,(i-1)*58,leftW-28,52,not s.Busy and not unavailable and function()
   local max=(s.Procedure=='Fusion'or s.Procedure=='Creation')and 3 or 1
   if index then table.remove(s.Uids,index)elseif max==1 then s.Uids={dog.DogUid}elseif #s.Uids<max then table.insert(s.Uids,dog.DogUid)end
   s.Step=math.min(s.Step,3);changed()
  end or nil,index and green or nil).Caption.TextSize=17
 end
 if #dogs==0 then U.Text(doglist,'Adopt a dog at DOG LINE first.',5,0,leftW-30,90,19,P.muted)end
 U.Text(center,'02 / '..(s.Step<3 and'PROCEDURE'or'MATERIALS'),12,8,centerW-24,32,21,green,true)
 local body=U.Scroll(center,'LabInputs',10,45,centerW-20,465)
 local cy=0
 if s.Step<=2 then
  for _,proc in C.Procedures do
   local unlocked=l.Tier>=proc.Tier and (not tutorial or proc.Id=='Mutation'or l.TutorialComplete)
   U.Button(body,'Procedure_'..proc.Id,proc.Name..(unlocked and''or' · LV '..proc.Level),3,cy,centerW-32,43,not s.Busy and unlocked and function()s.Procedure=proc.Id;s.Step=2;s.Items={};s.DNA={};s.RecipeId='';s.StabilizerUid='';if #s.Uids>1 then s.Uids={s.Uids[1]}end;changed()end or nil,s.Procedure==proc.Id and green or nil)
   U.Text(body,proc.Description,6,cy+49,centerW-36,62,17,P.muted);cy+=120
  end
 else
  U.Text(body,s.Procedure:upper(),5,0,centerW-34,28,22,green,true);cy=36
  local recipeMode=s.Procedure=='Fusion'or s.Procedure=='Creation'
  if recipeMode then
   for _,recipe in s.Info.Recipes do if recipe.Procedure==s.Procedure then
    U.Button(body,'Recipe_'..recipe.RecipeId,recipe.Name,3,cy,centerW-32,40,not s.Busy and function()s.RecipeId=recipe.RecipeId;s.DNA=recipe.Known and RCopy(recipe.RequiredDNA or{})or{};changed()end or nil,s.RecipeId==recipe.RecipeId and purple or nil);cy+=44
    U.Text(body,recipe.Hint or'',5,cy,centerW-36,64,15,P.muted);cy+=68
    if recipe.Known and s.RecipeId==recipe.RecipeId then
     local req=(recipe.RequiredDogIds and table.concat(recipe.RequiredDogIds,' + ')or recipe.Requirements or'')..'\nDNA: '..mapText(recipe.RequiredDNA,C.DNA)..'\nFinds: '..mapText(recipe.RequiredItems)..'\nMinimum mastery: '..(recipe.MinimumMastery or 0)
     U.Text(body,req,5,cy,centerW-36,105,16,P.text);cy+=111
    end
   end end
   if s.RecipeId=='DISCOVER'then
    U.Text(body,'ADD DNA SAMPLES',5,cy,centerW-36,30,18,purple,true);cy+=36
    local keys={};for key,n in pairs(l.DNA)do if n>0 then table.insert(keys,key)end end;table.sort(keys)
    for _,key in keys do
     U.Text(body,C.DNA[key]..' · '..(s.DNA[key]or 0)..' / '..l.DNA[key],5,cy,centerW-112,36,15,P.text)
     U.Button(body,'LessDNA_'..key,'−',centerW-104,cy,32,32,not s.Busy and function()s.DNA[key]=math.max(0,(s.DNA[key]or 0)-1);changed()end or nil)
     U.Button(body,'AddDNA_'..key,'+',centerW-66,cy,32,32,not s.Busy and function()s.DNA[key]=math.min(100,l.DNA[key],(s.DNA[key]or 0)+1);changed()end or nil,green);cy+=42
    end
   end
  end
  if s.Procedure=='Mutation'then U.Text(body,not l.TutorialComplete and'STARTER REAGENT × 1\nComplimentary first mutation. No dog is consumed.'or('Coins + Bones\nCost scales with your dog’s rarity. No dog is consumed.'),5,cy,centerW-36,105,20,P.text);cy+=112 end
  if s.Procedure=='Extraction'then U.Text(body,'THIS DOG WILL BE CONSUMED\nRemove locks, favorites, kennel and display assignments first. Review the exact DNA yield before confirming.',5,cy,centerW-36,150,20,P.gold,true);cy+=158 end
  if s.Procedure=='Targeting'then U.Text(body,'Select one affinity catalyst. Common DNA × 2 is added automatically.',5,cy,centerW-36,67,18,P.muted);cy+=74 end
  if s.Procedure=='Targeting'or(recipeMode and s.RecipeId~='ASCEND')then
   U.Text(body,'DISCOVERY CATALYSTS',5,cy,centerW-36,30,18,green,true);cy+=36
   local found={};for _,x in pairs(p.Items)do if not x.Favorite then table.insert(found,x)end end;table.sort(found,function(a,b)return a.DisplayName<b.DisplayName end)
   for _,x in found do if recipeMode or C.Affinities[x.ItemId]then
    local index=table.find(s.Items,x.ItemUid)
    U.Button(body,'Catalyst_'..x.ItemUid,(index and'✓ 'or'+ ')..x.DisplayName,3,cy,centerW-32,39,not s.Busy and function()
     if index then table.remove(s.Items,index)elseif s.Procedure=='Targeting'then s.Items={x.ItemUid}elseif #s.Items<4 then table.insert(s.Items,x.ItemUid)end;changed()
    end or nil,index and green or nil);cy+=44
   end end
   if #found==0 then U.Text(body,'Find catalysts by digging. Favorite discoveries are kept out of lab consumption.',5,cy,centerW-36,85,17,P.muted);cy+=92 end
  end
  if s.Procedure~='Extraction'and s.RecipeId~='ASCEND'then
   U.Text(body,'OPTIONAL STABILIZER',5,cy,centerW-36,30,18,purple,true);cy+=36
   U.Button(body,'NoStabilizer','NO STABILIZER',3,cy,centerW-32,36,not s.Busy and function()s.StabilizerUid='';changed()end or nil,s.StabilizerUid==''and purple or nil);cy+=42
   for _,x in pairs(p.Items)do if C.Stabilizers[x.ItemId]and not x.Favorite then
    U.Button(body,'Stabilizer_'..x.ItemUid,x.DisplayName..' +'..C.Stabilizers[x.ItemId]..' stability',3,cy,centerW-32,39,not s.Busy and function()s.StabilizerUid=x.ItemUid;changed()end or nil,s.StabilizerUid==x.ItemUid and purple or nil);cy+=44
   end end
  end
 end
 U.Text(right,'03 / PREVIEW',12,8,rightW-24,32,21,green,true)
 local preview=U.Scroll(right,'LabOdds',10,47,rightW-20,363)
 local q=s.Preview
 if q then
  U.Bar(preview,3,2,rightW-32,28,q.Stability/100,q.Stability>=70 and green or q.Stability>=45 and P.gold or purple,'STABILITY '..string.format('%.0f%%',q.Stability))
  local y=40
  if q.Chances then for _,chance in q.Chances do
   U.Text(preview,chance.Name,5,y,rightW*.5,26,17,C.Colors[chance.Name],true)
   U.Text(preview,string.format('%.3f%%',chance.Percent),rightW*.53,y,rightW*.38-15,26,17,P.text);y+=30
  end
  U.Text(preview,'Strange DNA side result: '..string.format('%.2f%%',q.StrangeChance),5,y,rightW-36,42,15,P.muted);y+=46
  elseif q.Rewards then U.Text(preview,mapText(q.Rewards,C.DNA),5,y,rightW-36,106,18,green);y+=114
  else
   U.Text(preview,(q.Hidden and'UNKNOWN OUTPUT'or((q.OutputDogId or'')..' / '..(q.OutputMutation or'')))..'\nSuccess: '..string.format('%.1f%%',q.SuccessChance),5,y,rightW-36,86,20,purple,true);y+=96
   U.Text(preview,'On failure: all dogs survive, half the DNA returns. Coins, Bones and discovery catalysts are spent.',5,y,rightW-36,90,16,P.muted);y+=99
  end
  if q.Destructive then
   U.Text(preview,'DOGS CONSUMED ON SUCCESS:',5,y,rightW-36,45,18,P.gold,true);y+=50
   for _,uid in q.Consumed do local dog=p.Dogs[uid];U.Text(preview,(dog and dog.DisplayName or uid)..'\n'..uid,5,y,rightW-36,59,14,P.text);y+=64 end
  end
  U.Text(preview,'DNA cost: '..mapText(q.DNA,C.DNA),5,y,rightW-36,68,16,P.muted)
  U.Text(right,U.Fmt(q.Cash)..' COINS / '..q.Bones..' BONES',12,418,rightW-24,35,17,P.gold,true)
  if q.HighValue and s.Step==5 then
   U.Text(preview,'VALUABLE DOGS: type '..q.Confirmation,5,y+75,rightW-36,56,17,P.gold,true)
   U.Search(preview,'TypedLabConfirmation',q.Confirmation,s.Typed,5,y+135,rightW-36,function(v)s.Typed=v;redraw()end)
  end
 else U.Text(preview,'Select your dog, choose a procedure and add materials. Then request the exact server preview.',8,20,rightW-36,155,20,P.muted)end
 local function args()return{Procedure=s.Procedure,Uids=s.Uids,PrimaryUid=s.Uids[1],Items=s.Items,DNA=s.DNA,RecipeId=s.RecipeId,StabilizerUid=s.StabilizerUid}end
 local title,fn='NEXT',nil
 if s.Step==1 then fn=d and function()s.Step=2;redraw()end
 elseif s.Step==2 then fn=d and function()s.Step=3;redraw()end
 elseif not q or s.Step==3 then title='CALCULATE PREVIEW';fn=d and function()query('LabPreview',args(),function(v)s.Preview=v;s.Step=4;s.Typed=''end)end
 elseif s.Step==4 then title='REVIEW & CONFIRM';fn=function()s.Step=5;redraw()end
 elseif s.Step==5 then
  title=s.Pending and'RETRY SAME EXPERIMENT'or'START EXPERIMENT'
  fn=(not q.HighValue or s.Typed==q.Confirmation)and function()
   s.Pending=s.Pending or Http:GenerateGUID(false):gsub('-','')
   query('LabCommit',{Token=q.Token,Confirm=true,Typed=s.Typed or''},function(result)
    s.Pending=nil;s.Result=result;s.Step=6;s.Preview=nil
    local menus=require(script.Parent.Menus).Active;menus:Close()
    task.spawn(function()
     local ok,e=pcall(require(script.Parent.LabPresentation).Play,result)
     if not ok then warn('Lab presentation:',e)end
     s.Step=7;s.Info=nil;menus:Show('Lab');menus:Fetch(true)
    end)
   end,s.Pending)
  end or nil
 end
 U.Button(right,'LabNext',s.Busy and'PLEASE WAIT…'or title,10,465,rightW-20,46,not s.Busy and fn or nil,green)
 local bottom=top+(mobile and 1620 or 540)
 U.Button(sc,'LabBack','BACK',6,bottom,110,39,not s.Busy and s.Step>1 and function()s.Step=math.max(1,s.Step-1);s.Pending=nil;redraw()end or nil)
 local total,types=0,0;for _,n in pairs(l.DNA)do if n>0 then total+=n;types+=1 end end
 U.Text(sc,'DNA: '..total..' samples / '..types..' types · Materials stay saved in your lab',130,bottom,c.W-144,60,16,P.muted)
end
return S
