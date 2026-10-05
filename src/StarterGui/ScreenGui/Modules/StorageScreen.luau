local S={}
function S.Build(c)
 local U,V=c.U,require(script.Parent.PreviewRenderer);local p,s=c.Snapshot.Profile,c.State;local W,H=c.W,c.H;local P=U.Colors
 local sc=U.Scroll(c.Parent,'StorageContent',0,0,W,H)
 U.Text(sc,'YOUR DOGS · YOUR DISPLAY',8,0,W-16,35,25,P.gold,true)
 local instructionH=W<450 and 76 or 48;local slotsTop=37+instructionH+14
 U.Text(sc,'Choose a slot, then place one of your dogs. Displays do not change kennel assignments.',8,37,W-16,instructionH,17,P.muted)
 local slotCols=math.max(1,math.min(3,math.floor((W-8)/220)));local cw=(W-24-(slotCols-1)*10)/slotCols;local chosen=s.DisplaySlot or 1
 for i=1,3 do
  local uid=(p.DisplayDogs or{})[tostring(i)];local d=uid and p.Dogs[uid]
  local b=U.Panel(sc,'DisplaySlot'..i,8+(i-1)%slotCols*(cw+10),slotsTop+math.floor((i-1)/slotCols)*290,cw,278,true)
  if chosen==i then U.Glow(b,P.gold)end
  U.Center(b,'DISPLAY '..i,5,4,cw-10,28,19,P.text,true)
  if d then V.Dog(b,d,6,34,cw-12,109);U.Center(b,d.DisplayName,5,143,cw-10,44,18,P.text,true)
  else U.Center(b,'EMPTY',5,54,cw-10,65,23,P.muted,true);U.Center(b,'Choose your dog below',5,127,cw-10,44,14,P.muted)end
  U.Button(b,'SelectDisplay'..i,chosen==i and'SELECTED'or'SELECT',7,189,cw-14,38,function()s.DisplaySlot=i;c.Draw()end,P.blue)
  U.Button(b,'ClearDisplay'..i,'CLEAR',7,233,cw-14,38,d and function()c.Send('DisplayDog',{Slot=i,Uid=''})end or nil)
 end
 local listTop=slotsTop+math.ceil(3/slotCols)*290+10
 U.Button(sc,'ManageDogs','DOG LIST / ASSIGN TO KENNELS',6,listTop,W-20,44,function()c.Show('Dogs')end,P.blue)
 U.Search(sc,'StorageSearch','Search owned dogs…',s.StorageSearch,6,listTop+56,W-20,function(v)s.StorageSearch=v;c.Draw()end)
 local dogs={};for _,d in pairs(p.Dogs)do if not s.StorageSearch or d.DisplayName:lower():find(s.StorageSearch:lower(),1,true)then table.insert(dogs,d)end end
 table.sort(dogs,function(a,b)return a.DisplayName==b.DisplayName and a.DogUid<b.DogUid or a.DisplayName<b.DisplayName end)
 if #dogs==0 then U.Center(sc,'No dogs here yet. Adopt a dog at DOG LINE.',8,listTop+111,W-24,95,23,P.muted,true)end
 local cols=math.max(1,math.min(3,math.floor((W-8)/280)));local dw=(W-24-(cols-1)*10)/cols
 for i,d in ipairs(dogs)do
  local b=U.Panel(sc,'OwnedDog_'..d.DogUid,((i-1)%cols)*(dw+10),listTop+109+math.floor((i-1)/cols)*232,dw,222,true)
  V.Dog(b,d,6,5,dw*.43,125);U.Text(b,d.DisplayName,dw*.45,10,dw*.53-8,48,18,P.text,true)
  U.Text(b,d.Rarity..' · '..d.Variant..'\n'..(d.AssignedSlot~=''and'Working'or'In storage'),dw*.45,62,dw*.53-8,63,15,P.muted)
  local current;for k,v in pairs(p.DisplayDogs or{})do if v==d.DogUid then current=k end end
  U.Text(b,current and'Displayed in slot '..current or'Not on display',10,133,dw-20,25,15,P.muted)
  U.Button(b,'PlaceDog_'..d.DogUid,'PLACE IN DISPLAY '..chosen,8,168,dw-16,44,d.State~='Walking'and function()c.Send('DisplayDog',{Slot=chosen,Uid=d.DogUid})end or nil,P.green)
 end
end
return S
