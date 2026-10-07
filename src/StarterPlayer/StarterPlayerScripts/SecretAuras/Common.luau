-- What every Secret aura has: the "✦ SECRET ✦" nameplate and a ground ring (reduced and
-- full), a pulsing ripple (full), and the granted sky beacon, light and highlight.
local RS=game:GetService('ReplicatedStorage')
local Config=require(RS:WaitForChild('SecretAuraConfig'))
local Aura=require(script.Parent:WaitForChild('Aura'))
local M={}
local Flat=Aura.Flat

local function sequence(colors)
 local keys={}
 for i,c in ipairs(colors)do table.insert(keys,ColorSequenceKeypoint.new((i-1)/math.max(1,#colors-1),c))end
 if #keys==1 then return ColorSequence.new(colors[1])end
 return ColorSequence.new(keys)
end
M.Sequence=sequence
-- The nine prism colours as one sequence, rotated by `offset` (0..1) for a hue cycle.
function M.Rainbow(offset,saturation)
 local keys={}
 for i=0,6 do
  local h=(offset+i/6)%1
  table.insert(keys,ColorSequenceKeypoint.new(i/6,Color3.fromHSV(h,saturation or .55,1)))
 end
 return ColorSequence.new(keys)
end

-- The venue's own label anchor (an Attachment on the dog's root), when it has one.
local function venueAnchor(a)
 local name=Config.Plate.Anchors[a.Venue]
 local at=name and a.Geo.Anchor:FindFirstChild(name)
 return at and at:IsA('Attachment')and at or nil
end
-- Tier 2: nameplate + ground ring + glow pool.
function M.Reduced(a,g)
 local G,cfg=a.Geo,a.Cfg
 local ringColor=cfg.Ring or cfg.Color
 local r=G.R*1.05
 g.State.Ring=a:Adorn(g,'CylinderHandleAdornment',function(o)
  o.Name='AuraRing';o.Radius=r;o.InnerRadius=r*.9;o.Height=.05;o.Color3=ringColor;o.Transparency=.25
  o.CFrame=a:Local(G.Ground+Vector3.new(0,.09,0),Flat)
 end)
 if not cfg.NoPool then
  a:Adorn(g,'CylinderHandleAdornment',function(o)
   o.Name='AuraPool';o.Radius=r*.9;o.InnerRadius=0;o.Height=.03;o.Color3=ringColor;o.Transparency=.86
   o.CFrame=a:Local(G.Ground+Vector3.new(0,.06,0),Flat)
  end)
 end
 -- The nameplate sits over the venue's own label (Gap pixels under it stay clear).
 local style=cfg.Plate
 local P=Config.Plate
 local crown=venueAnchor(a)
 local gap=crown and P.Gap[a.Venue]or P.DefaultGap
 crown=crown or a:Attachment(g,'AuraCrown',G.Top+Vector3.new(0,.35+.08*G.Size.Y,0))
 local gui=a:Billboard(g,crown,function(b)
  b.Name='SecretPlate_'..a.DogId;b.Size=UDim2.fromOffset(P.Width,2*(P.Height+gap));b.MaxDistance=P.VenueDistance[a.Venue]or P.MaxDistance
 end)
 local plate=Instance.new('Frame');plate.Name='Plate';plate.Size=UDim2.fromOffset(P.Width,P.Height)
 plate.BackgroundColor3=style.Back;plate.BackgroundTransparency=.22;plate.BorderSizePixel=0;plate.Parent=gui
 local corner=Instance.new('UICorner');corner.CornerRadius=UDim.new(0,12);corner.Parent=plate
 local stroke=Instance.new('UIStroke');stroke.Color=Color3.new(1,1,1);stroke.Thickness=2;stroke.Transparency=.05
 stroke.ApplyStrokeMode=Enum.ApplyStrokeMode.Border;stroke.Parent=plate
 local shimmer=Instance.new('UIGradient')
 shimmer.Color=style.Rainbow and sequence(Config.Prism)or sequence(style.Gradient or {cfg.Color,cfg.Accent,cfg.Color})
 shimmer.Parent=stroke
 local kicker=Instance.new('TextLabel');kicker.Name='Kicker';kicker.BackgroundTransparency=1
 kicker.Position=UDim2.fromOffset(8,3);kicker.Size=UDim2.new(1,-16,0,18);kicker.Font=Enum.Font.GothamBlack;kicker.TextSize=13
 kicker.Text=P.Kicker;kicker.TextColor3=style.KickerColor;kicker.TextStrokeTransparency=.6;kicker.TextStrokeColor3=style.Back
 kicker.Parent=plate
 local name=Instance.new('TextLabel');name.Name='DogName';name.BackgroundTransparency=1
 name.Position=UDim2.fromOffset(8,20);name.Size=UDim2.new(1,-16,0,34);name.Font=style.Font;name.TextScaled=true
 name.Text=style.Name;name.TextColor3=style.NameColor;name.TextStrokeTransparency=.35;name.TextStrokeColor3=style.Back
 name.Parent=plate
 local limit=Instance.new('UITextSizeConstraint');limit.MaxTextSize=22;limit.MinTextSize=10;limit.Parent=name
 if style.Rainbow then
  local rainbow=Instance.new('UIGradient');rainbow.Color=sequence(Config.Prism);rainbow.Parent=name
  g.State.NameGradient=rainbow
 end
 a:FadeGui(g,plate)
 g.State.Plate=gui;g.State.Shimmer=shimmer;g.State.Name=name
end

-- Tier 3: the ring pulses and a ripple runs out of it.
function M.Full(a,g)
 local G,cfg=a.Geo,a.Cfg
 local r=G.R*1.05
 g.State.Ripple=a:Adorn(g,'CylinderHandleAdornment',function(o)
  o.Name='AuraRipple';o.Radius=r;o.InnerRadius=r*.94;o.Height=.04;o.Color3=cfg.Ring or cfg.Color;o.Transparency=1
  o.CFrame=a:Local(G.Ground+Vector3.new(0,.1,0),Flat)
 end,false)
end
function M.Step(a,t)
 local reduced,full=a.Groups[2],a.Groups[3]
 if not reduced or not full then return end
 local shown=reduced.Alpha*full.Alpha*a.Alpha
 local G=a.Geo
 local ring=reduced.State.Ring
 if ring and ring.Parent then ring.Transparency=1-(1-(.18+.22*(.5+.5*math.sin(t*2.4))))*shown end
 local ripple=full.State.Ripple
 if ripple and ripple.Parent then
  local p=(t*.45)%1
  local r=G.R*(.7+p*.9)
  ripple.Radius=r;ripple.InnerRadius=r*.94
  ripple.Transparency=1-(1-p)*.75*shown
 end
 local shimmer=reduced.State.Shimmer
 if shimmer and shimmer.Parent then shimmer.Rotation=(t*60)%360 end
 local rainbow=reduced.State.NameGradient
 if rainbow and rainbow.Parent then rainbow.Offset=Vector2.new(math.sin(t*.8)*.5,0)end
end

-- Beacon: a thin shaft of the dog's colour into the sky from above its head.
function M.Beacon(a,g)
 local G,cfg=a.Geo,a.Cfg
 local B=Config.Beacon
 local base=a:Attachment(g,'AuraBeaconBase',G.Top+Vector3.new(0,.4,0))
 local top=a:Attachment(g,'AuraBeaconTop',G.Top+Vector3.new(0,B.Height,0))
 a:Beam(g,base,top,function(b)
  b.Name='AuraBeacon';b.Width0=B.Width;b.Width1=B.Width*.45;b.Brightness=B.Brightness
  b.Color=sequence({cfg.Color,cfg.Accent})
  b.Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,.05),NumberSequenceKeypoint.new(.55,.35),NumberSequenceKeypoint.new(1,1)})
 end)
 a:Beam(g,base,top,function(b)
  b.Name='AuraBeaconGlow';b.Width0=B.GlowWidth;b.Width1=B.GlowWidth*.6;b.Brightness=1.2
  b.Texture=Aura.Textures.Smoke;b.TextureMode=Enum.TextureMode.Wrap;b.TextureLength=30;b.TextureSpeed=.4
  b.Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,.62),NumberSequenceKeypoint.new(.6,.84),NumberSequenceKeypoint.new(1,1)})
 end)
end

function M.Light(a,g)
 local G,cfg=a.Geo,a.Cfg
 local spec=cfg.Light or {}
 local l=Instance.new('PointLight')
 l:SetAttribute('SecretAura',true);l.Archivable=false
 l.Name='AuraLight';l.Color=spec.Color or cfg.Color;l.Range=math.clamp(G.R*(spec.Range or 2.6),6,22)
 l.Brightness=spec.Brightness or 1.5;l.Shadows=false
 l.Parent=a:BodyPart()
 a:Fade(g,l,'Brightness','scale',l.Brightness)
 a:Track(g,l)
 g.State.Light=l
end

function M.Highlight(a,g)
 local cfg=a.Cfg
 local spec=cfg.Highlight or {}
 local h=Instance.new('Highlight')
 h:SetAttribute('SecretAura',true);h.Archivable=false
 h.Name='AuraHighlight';h.Adornee=a.Model;h.DepthMode=Enum.HighlightDepthMode.Occluded
 h.FillColor=spec.Fill or cfg.Color;h.OutlineColor=spec.Outline or cfg.Accent
 h.FillTransparency=.86;h.OutlineTransparency=.4
 h.Parent=a.Folder
 a:Fade(g,h,'FillTransparency','alpha',.86)
 a:Fade(g,h,'OutlineTransparency','alpha',.4)
 a:Track(g,h)
 g.State.Highlight=h
end
return M
