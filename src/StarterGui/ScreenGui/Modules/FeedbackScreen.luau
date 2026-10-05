local RS=game:GetService('ReplicatedStorage');local Http=game:GetService('HttpService');local S={}
function S.Build(c)
 local U,s,W,H=c.U,c.State,c.W,c.H;local P=U.Colors;local sc=U.Scroll(c.Parent,'MailboxForm',0,0,W,H)
 U.Center(sc,'DOGROTS MAILBOX',12,8,W-32,50,28,P.gold,true)
 U.Text(sc,'Ideas, bugs and feedback help us make DOGROTS better. Your message is sent privately to the developers.',16,70,W-40,75,20,P.muted)
 local category=s.FeedbackCategory or 'IDEA';U.Cycle(sc,'Category',category,{'IDEA','BUG','FEEDBACK','OTHER'},category,12,158,W-32,function(v)s.FeedbackCategory=v;s.FeedbackRequest=nil;c.Draw()end)
 local input=U.New('TextBox',{Name='FeedbackMessage',Position=UDim2.fromOffset(12,215),Size=UDim2.fromOffset(W-32,210),BackgroundColor3=P.navy,TextColor3=P.text,Text=s.FeedbackText or '',PlaceholderText='Write your message…',PlaceholderColor3=P.muted,FontFace=U.FontFace,TextSize=20,TextWrapped=true,MultiLine=true,ClearTextOnFocus=false,TextXAlignment=Enum.TextXAlignment.Left,TextYAlignment=Enum.TextYAlignment.Top},sc)
 U.New('UIPadding',{PaddingLeft=UDim.new(0,12),PaddingRight=UDim.new(0,12),PaddingTop=UDim.new(0,12)},input)
 local counter=U.Text(sc,tostring(utf8.len(input.Text)or 0)..'/300',16,435,W-40,30,17,P.muted)
 input:GetPropertyChangedSignal('Text'):Connect(function()s.FeedbackText=input.Text;s.FeedbackRequest=nil;counter.Text=tostring(utf8.len(input.Text)or 0)..'/300'end)
 U.Button(sc,'SendFeedback',s.FeedbackBusy and 'SENDING…'or 'SEND MESSAGE',12,479,W-32,49,not s.FeedbackBusy and function()
  local length=utf8.len(s.FeedbackText or '');if not length or length<1 or length>300 then s.FeedbackStatus='Use 1–300 characters.';c.Draw();return end
  s.FeedbackRequest=s.FeedbackRequest or Http:GenerateGUID(false):gsub('-','');s.FeedbackBusy=true;c.Draw()
  task.spawn(function()
   local transport,ok,result=pcall(function()return RS.FeedbackRequest:InvokeServer({Text=s.FeedbackText,Category=category,Request=s.FeedbackRequest})end)
   s.FeedbackBusy=false;s.FeedbackStatus=transport and tostring(result)or 'Connection interrupted. Retry to check delivery.'
   if transport and ok then s.FeedbackText='';s.FeedbackRequest=nil end;if c.Parent.Parent then c.Draw()end
  end)
 end or nil,P.green)
 U.Text(sc,s.FeedbackStatus or 'Up to 300 characters · One message per minute',16,545,W-40,90,20,P.gold)
end
return S
