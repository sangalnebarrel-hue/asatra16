-- Persistent "super rare" look of every Secret dog wherever it is shown (yards, kennels,
-- the tongue, showcases, the DOG-O-MATIC, the museum). StarterPlayerScripts/SecretAuras
-- dresses every model tagged DOGROTS_SecretDog (DogDisplayHooks); this module is data only:
-- per-dog colours and nameplate styles, the LOD distances and the client budgets.
-- Colours start from SecretArrivalConfig.Dogs[id].Color so arrivals and auras match.
local Arrivals=require(script.Parent:WaitForChild('SecretArrivalConfig'))
local C={}
local rgb=Color3.fromRGB
C.Tag='DOGROTS_SecretDog'
-- Client folder for everything that is not attached to the dog itself (outside the
-- district, so WorldDetailQuality, TintLights and WorldEventLighting never touch it).
C.Folder='DOGROTS_SecretAuraFX'
-- Seconds between LOD/budget passes; animation of the near auras runs every frame.
C.Tick=.25
-- Camera distance (studs): full aura inside Full, reduced inside Reduced, beacon only beyond.
-- Hysteresis keeps a dog at the boundary from rebuilding every pass.
C.Lod={High={Full=100,Reduced=250},Medium={Full=100,Reduced=250},Low={Full=60,Reduced=160},Hysteresis=10}
-- Global particle budget (sum of Rate over every aura emitter), handed out nearest first.
C.Budget={High=150,Medium=70,Low=20}
-- Every aura emitter's own rate is scaled by the quality too (Low = a quarter).
C.RateScale={High=1,Medium=.65,Low=.25}
-- Reduced LOD keeps a few emitters at this fraction of their rate.
C.ReducedRate=.35
-- Nearest N get a PointLight / a Highlight / a sky beacon. None of them on Low.
C.Lights={High=4,Medium=4,Low=0}
C.Highlights={High=2,Medium=2,Low=0}
C.Beacons={High=6,Medium=6,Low=0}
-- Fade in once the arrival cinematic lets go of the dog, fade out when it leaves.
C.FadeIn=1.4
C.FadeOut=.6
-- The sky beacon: a thin tall shaft of the dog's colour seen from across the island, so
-- everyone knows where the super-rare dogs are. Never in the museum (that is a private
-- collection) and never on the DOG-O-MATIC drum symbol.
C.Beacon={Height=320,Width=1.1,GlowWidth=4.5,Brightness=2.4,
 Venues={Line=true,Kennel=true,Showcase=true,BestFinds=true,Reveal=true,Machine=true,Static=true}}
-- The "✦ SECRET ✦" nameplate. Where the venue already has a label, the plate shares its
-- anchor (Anchors) and keeps Gap pixels clear under itself for it: the tongue's price
-- board (72 px tall), the kennel's DIGGING sign (44 px) and cosmetic tag just above it.
-- In the museum the exhibits stand in rows with their own plaques: plates only up close.
C.Plate={MaxDistance=120,OnTopDistance=60,Kicker='✦ SECRET ✦',Width=236,Height=58,
 Anchors={Line='DogLabelAnchor',Kennel='SleepLabelAnchor'},Gap={Line=42,Kennel=46},DefaultGap=8,
 VenueDistance={Museum=40}}
-- Models under these never get an aura (arrival copies, world-event sky dogs, our own FX).
C.SkipAncestors={DOGROTS_SecretArrivalFX=true,WorldEventFX=true,DOGROTS_SecretAuraFX=true}
-- Models under these get the small symbol version (sparkles only): the Aurion on the drum.
C.MiniAncestors={SpinningDrum=true}
-- WrongDog turns its head to the local camera inside this distance.
C.WrongLook={Distance=24,Yaw=math.rad(32),Pitch=math.rad(14)}
-- NuclearPug's Geiger counter: clicks inside this camera distance (never on Low/ReducedMotion).
C.Geiger={Distance=15,Volume=.07,MaxPerSecond=7,MinGap=.07}
-- THE DOG darkens the local view a little when the camera is this close.
C.Darken={Distance=26,Brightness=-.06,Contrast=.06,Saturation=-.28}

local function arrival(id,fallback)local a=Arrivals.Dogs[id];return a and a.Color or fallback end
--[[ Per dog:
 Color/Accent/Deep  the palette (Color = the arrival colour)
 Plate              Font, Name (shown under the kicker), NameColor, KickerColor, Back (pill), Stroke, Gradient
 Light              PointLight colour/range factor/brightness (false = no light: THE DOG is darkness)
 Highlight          Fill/Outline for the nearest two
 Ring, NoPool       ground ring colour (defaults to Color); no glow pool inside it ]]
C.Dogs={
 Cubedog={
  Color=arrival('Cubedog',rgb(86,214,255)),Accent=rgb(236,251,255),Deep=rgb(40,130,255),
  Plate={Font=Enum.Font.Michroma,Name='CUBEDOG',NameColor=rgb(236,251,255),KickerColor=rgb(86,214,255),Back=rgb(6,22,38),Stroke=rgb(86,214,255),Gradient={rgb(86,214,255),rgb(236,251,255),rgb(40,130,255)}},
  Light={Range=2.6,Brightness=1.6},
 },
 Dogdogdogdog={
  Color=arrival('Dogdogdogdog',rgb(255,196,64)),Accent=rgb(255,226,150),Deep=rgb(222,128,16),
  Plate={Font=Enum.Font.LuckiestGuy,Name='DOGDOGDOGDOG',NameColor=rgb(255,226,150),KickerColor=rgb(255,196,64),Back=rgb(40,24,4),Stroke=rgb(255,196,64),Gradient={rgb(222,128,16),rgb(255,240,190),rgb(255,196,64)}},
  Light={Range=2.6,Brightness=1.5},
 },
 Spiderdog={
  Color=arrival('Spiderdog',rgb(255,120,40)),Accent=rgb(240,240,240),Deep=rgb(26,16,12),Ember=rgb(255,214,170),
  Plate={Font=Enum.Font.Creepster,Name='SPIDERDOG',NameColor=rgb(255,214,170),KickerColor=rgb(255,120,40),Back=rgb(18,10,6),Stroke=rgb(255,120,40),Gradient={rgb(255,120,40),rgb(240,240,240),rgb(120,40,10)}},
  Light={Range=2.4,Brightness=1.3},
 },
 WrongDog={
  Color=arrival('WrongDog',rgb(255,40,40)),Accent=rgb(210,255,200),Deep=rgb(70,0,6),
  Plate={Font=Enum.Font.GrenzeGotisch,Name='THE WRONG DOG',Glitch='THE RIGHT DOG',NameColor=rgb(255,226,226),KickerColor=rgb(255,40,40),Back=rgb(14,0,2),Stroke=rgb(255,40,40),Gradient={rgb(70,0,6),rgb(255,40,40),rgb(70,0,6)}},
  Light={Range=2.2,Brightness=1.4},
  Highlight={Fill=rgb(70,0,6),Outline=rgb(255,40,40)},
 },
 NuclearPug={
  Color=arrival('NuclearPug',rgb(150,255,60)),Accent=rgb(255,214,0),Deep=rgb(104,214,52),Soot=rgb(26,28,20),
  Plate={Font=Enum.Font.Sarpanch,Name='NUCLEAR PUG',NameColor=rgb(214,255,170),KickerColor=rgb(255,214,0),Back=rgb(14,22,6),Stroke=rgb(150,255,60),Gradient={rgb(255,214,0),rgb(150,255,60),rgb(255,214,0)}},
  Light={Range=3.2,Brightness=1.9},
 },
 ['404Dog']={
  Color=arrival('404Dog',rgb(80,160,255)),Accent=rgb(60,236,255),Deep=rgb(20,60,160),Error=rgb(255,60,96),
  Plate={Font=Enum.Font.Code,Name='404 DOG NOT FOUND',NameColor=rgb(220,240,255),KickerColor=rgb(60,236,255),Back=rgb(4,12,30),Stroke=rgb(80,160,255),Gradient={rgb(80,160,255),rgb(60,236,255),rgb(255,255,255)}},
  Light={Range=2.4,Brightness=1.5},
 },
 UnfinishedDog={
  Color=arrival('UnfinishedDog',rgb(255,0,255)),Accent=rgb(13,105,172),Deep=rgb(10,10,12),Grey=rgb(163,162,165),
  Plate={Font=Enum.Font.RobotoMono,Name='THE UNFINISHED DOG',NameColor=rgb(255,200,255),KickerColor=rgb(255,0,255),Back=rgb(12,4,14),Stroke=rgb(255,0,255),Gradient={rgb(255,0,255),rgb(10,10,12),rgb(255,0,255)}},
  Light={Range=2.4,Brightness=1.4},
 },
 DivineDog={
  Color=arrival('DivineDog',rgb(255,236,170)),Accent=rgb(255,204,96),Deep=rgb(255,250,236),
  Plate={Font=Enum.Font.Fondamento,Name='BIBLICALLY ACCURATE DOG',NameColor=rgb(255,250,236),KickerColor=rgb(255,204,96),Back=rgb(40,30,10),Stroke=rgb(255,204,96),Gradient={rgb(255,204,96),rgb(255,250,236),rgb(255,204,96)}},
  Light={Range=3.4,Brightness=2,Color=rgb(255,214,140)},
  Highlight={Fill=rgb(255,236,170),Outline=rgb(255,204,96)},
 },
 TheDog={
  Color=arrival('TheDog',rgb(255,255,255)),Accent=rgb(255,255,255),Deep=rgb(0,0,0),
  Plate={Font=Enum.Font.Bodoni,Name='THE DOG',NameColor=rgb(255,255,255),KickerColor=rgb(200,200,210),Back=rgb(0,0,0),Stroke=rgb(255,255,255),Gradient={rgb(40,40,48),rgb(255,255,255),rgb(40,40,48)}},
  Light=false,
  Highlight={Fill=rgb(0,0,0),Outline=rgb(255,255,255)},
  Ring=rgb(235,235,255),NoPool=true,
 },
 LongDog={
  Color=arrival('LongDog',rgb(240,196,120)),Accent=rgb(255,214,64),Deep=rgb(64,40,26),Bone=rgb(246,240,224),
  Plate={Font=Enum.Font.FredokaOne,Name='LONG DOG',NameColor=rgb(255,240,214),KickerColor=rgb(255,214,64),Back=rgb(36,24,12),Stroke=rgb(240,196,120),Gradient={rgb(198,135,74),rgb(255,240,214),rgb(198,135,74)}},
  Light={Range=2.4,Brightness=1.2},
 },
 Aurion={
  Color=arrival('Aurion',rgb(150,220,255)),Accent=rgb(205,238,255),Deep=rgb(120,90,255),
  Plate={Font=Enum.Font.Michroma,Name='AURION',NameColor=rgb(240,250,255),KickerColor=rgb(205,238,255),Back=rgb(8,14,30),Stroke=rgb(150,220,255),Rainbow=true},
  Light={Range=3,Brightness=1.8},
 },
}
-- The nine prism colours (Aurion), also used for its UI frame.
C.Prism={rgb(255,70,90),rgb(255,150,40),rgb(255,230,60),rgb(120,255,90),rgb(40,230,200),rgb(60,170,255),rgb(110,110,255),rgb(190,90,255),rgb(255,90,210)}
function C.Get(id)return C.Dogs[id]end
-- UI (PreviewRenderer): the colours of the 2D super-rare frame around a Secret's preview.
function C.Frame(id)
 local d=C.Dogs[id]
 if not d then return nil end
 if d.Plate.Rainbow then return C.Prism end
 return d.Plate.Gradient or {d.Color,d.Accent,d.Color}
end
return C
