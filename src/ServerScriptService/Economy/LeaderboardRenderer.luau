local C=require(game.ReplicatedStorage.LeaderboardConfig)
local R={Panels={}}
local colors={Color3.fromRGB(236,199,114),Color3.fromRGB(190,206,211),Color3.fromRGB(190,142,103)}
local cream=Color3.fromRGB(238,232,213);local muted=Color3.fromRGB(148,170,172)
local function text(parent,name,value,x,y,w,h,size,color)
 local t=Instance.new('TextLabel');t.Name=name;t.Text=value;t.BackgroundTransparency=1
 t.Position=UDim2.fromOffset(x,y);t.Size=UDim2.fromOffset(w,h);t.Font=Enum.Font.FredokaOne
 t.TextSize=size;t.TextColor3=color or cream;t.TextXAlignment=Enum.TextXAlignment.Left
 t.TextTruncate=Enum.TextTruncate.AtEnd;t.ClipsDescendants=true;t.Parent=parent;return t
end
function R.Format(value,format)
 value=math.max(0,math.floor(value or 0))
 if format=='Time'then return string.format('%dh %02dm',math.floor(value/3600),math.floor(value/60)%60)end
 local str=string.format('%.0f',value);local formatted=str:reverse():gsub('(%d%d%d)','%1,'):reverse():gsub('^,','')
 return formatted..({Robux=' R$',Coins=' coins',Discoveries=' finds',Contribution=' points',Dogs=' dogs'})[format]
end
function R.Create(root)
 for _,category in ipairs(C.Categories)do
  local screen=root:FindFirstChild(category.Board,true);assert(screen and screen:IsA('BasePart'),'Missing leaderboard '..category.Board)
  local gui=screen:FindFirstChild(category.Key)
  if gui then gui:Destroy()end
  gui=Instance.new('SurfaceGui');gui.Name=category.Key;gui.Face=Enum.NormalId[category.Face]
  -- New SurfaceGuis default to PixelsPerStud (18x19 studs = 900x950 px), which ignores CanvasSize and
  -- pushes row 10 and the status line off the board. Keep the designed 900x1100 canvas.
  gui.SizingMode=Enum.SurfaceGuiSizingMode.FixedSize;gui.CanvasSize=Vector2.new(900,1100);gui.LightInfluence=0;gui.Brightness=1;gui.MaxDistance=200;gui.Parent=screen
  local bg=Instance.new('Frame');bg.Name='Panel';bg.Size=UDim2.fromScale(1,1);bg.BackgroundColor3=Color3.fromRGB(19,34,39);bg.BorderSizePixel=0;bg.ClipsDescendants=true;bg.Parent=gui
  text(bg,'Icon',category.Icon,32,20,60,60,45,category.Accent)
  text(bg,'Title',category.Title,104,24,770,60,54,category.Accent)
  text(bg,'Scope','ALL TIME  /  TOP 10',36,96,820,38,28,muted)
  local line=Instance.new('Frame');line.BorderSizePixel=0;line.BackgroundColor3=category.Accent;line.Position=UDim2.fromOffset(36,143);line.Size=UDim2.fromOffset(828,2);line.Parent=bg
  local rows={}
  for i=1,C.Top do
   local y=163+(i-1)*82;local accent=colors[i]or muted
   local frame=Instance.new('Frame');frame.Name='Row'..i;frame.BackgroundColor3=i==1 and Color3.fromRGB(62,54,37)or Color3.fromRGB(30,45,49)
   frame.BorderSizePixel=0;frame.ClipsDescendants=true;frame.Position=UDim2.fromOffset(28,y);frame.Size=UDim2.fromOffset(844,76);frame.Parent=bg
   text(frame,'Rank',string.format('%02d',i),12,9,58,52,30,accent)
   text(frame,'AvatarFallback','\226\151\143',78,5,60,60,40,muted)
   local avatar=Instance.new('ImageLabel');avatar.Name='Avatar';avatar.BackgroundTransparency=1;avatar.Size=UDim2.fromOffset(60,60);avatar.Position=UDim2.fromOffset(78,7);avatar.Parent=frame
   local user=text(frame,'Username','\226\128\148',156,4,670,36,32,cream)
   local value=text(frame,'Value','',156,41,670,29,25,accent)
   rows[i]={Frame=frame,Avatar=avatar,Username=user,Value=value}
  end
  local status=text(bg,'Status','Connecting to the records\226\128\166',36,986,828,46,23,muted)
  R.Panels[category.Key]={Gui=gui,Rows=rows,Status=status}
 end
end
function R.Render(category,entries,status,resolve)
 local panel=R.Panels[category.Key];if not panel then return end
 for i,row in ipairs(panel.Rows)do
  local entry=entries[i];local avatarImage=''
  if entry then
   local id=tonumber(entry.key);row.Username.Text=resolve(id);row.Value.Text=R.Format(entry.value,category.Format)
   if id and id>0 then avatarImage='rbxthumb://type=AvatarHeadShot&id='..id..'&w=150&h=150'end
   row.Frame:SetAttribute('UserId',id);row.Frame:SetAttribute('Value',entry.value)
  else
   row.Username.Text=i==1 and (category.Key=='Supporters' and status=='Coming soon' and 'Support the next chapter'or 'Your story belongs here')or '\226\128\148'
   row.Value.Text='';row.Frame:SetAttribute('UserId',nil);row.Frame:SetAttribute('Value',nil)
  end
  if row.Avatar.Image~=avatarImage then row.Avatar.Image=avatarImage end
 end
 panel.Status.Text=status;panel.Gui:SetAttribute('Status',status)
end
return R
