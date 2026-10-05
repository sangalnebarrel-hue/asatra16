-- Client-only event mood: Lighting, Atmosphere, post effects, clouds and sky blend toward
-- a per-event profile and return to the live day cycle afterwards.
local Lighting=game:GetService('Lighting')
local L={Baseline={},Last={},Active=false,Lights={}}
local C=Color3.fromRGB
local props={'ClockTime','Brightness','Ambient','OutdoorAmbient','ExposureCompensation'}
-- Clock: time of day. Atmo/Grade/Bloom/Rays/Clouds/Sky are optional per event.
-- Sky tweaks are used only at night, where a temporary Sky object cannot visibly change the skybox.
local moods={
 BONE_RAIN={Clock=18.1,Brightness=1.9,Ambient=C(114,106,124),Outdoor=C(160,148,162),Exposure=0,
  Atmo={Density=.2,Offset=.12,Color=C(228,206,182),Decay=C(128,98,112),Glare=.35,Haze=1.3},
  Grade={Tint=C(255,243,230),Saturation=-.04,Contrast=.12},Bloom={Intensity=.3,Size=24,Threshold=1.45},Rays=.05,
  Clouds={Cover=.58,Density=.32,Color=C(232,206,198)}},
 GOLDEN_HOUR={Clock=17.6,Brightness=2.8,Ambient=C(172,132,84),Outdoor=C(232,178,112),Exposure=.08,
  Atmo={Density=.22,Offset=.1,Color=C(255,206,142),Decay=C(204,122,72),Glare=.9,Haze=1.6},
  Grade={Tint=C(255,237,208),Saturation=.2,Contrast=.1},Bloom={Intensity=.42,Size=28,Threshold=1.3},Rays=.16,
  Clouds={Cover=.42,Density=.25,Color=C(255,214,170)}},
 DOG_RUSH={Clock=13.6,Brightness=3,Ambient=C(136,128,118),Outdoor=C(188,172,152),Exposure=.04,
  Atmo={Density=.14,Offset=.06,Color=C(255,228,196),Decay=C(166,124,92),Glare=.45,Haze=.85},
  Grade={Tint=C(255,246,236),Saturation=.24,Contrast=.12},Bloom={Intensity=.24,Size=22,Threshold=1.55},Rays=.06,
  Clouds={Cover=.3,Density=.18,Color=C(255,250,245)}},
 TREASURE_FEVER={Clock=16.7,Brightness=2.6,Ambient=C(162,132,92),Outdoor=C(218,182,124),Exposure=.05,
  Atmo={Density=.16,Offset=.08,Color=C(255,226,164),Decay=C(184,132,72),Glare=.6,Haze=.9},
  Grade={Tint=C(255,243,218),Saturation=.18,Contrast=.1},Bloom={Intensity=.34,Size=26,Threshold=1.38},Rays=.09,
  Clouds={Cover=.36,Density=.22,Color=C(255,232,196)}},
 CRYSTAL_STORM={Clock=20.4,Brightness=1.35,Ambient=C(72,82,142),Outdoor=C(104,124,192),Exposure=.12,
  Atmo={Density=.26,Offset=.15,Color=C(122,152,222),Decay=C(62,72,142),Glare=.2,Haze=1.4},
  Grade={Tint=C(226,236,255),Saturation=.1,Contrast=.15},Bloom={Intensity=.5,Size=28,Threshold=1.2},Rays=.02,
  Clouds={Cover=.86,Density=.5,Color=C(92,102,152)}},
 EARTHQUAKE={Clock=18.25,Brightness=1.65,Ambient=C(152,88,58),Outdoor=C(184,118,82),Exposure=.04,
  Atmo={Density=.24,Offset=.16,Color=C(216,152,108),Decay=C(142,72,42),Glare=.4,Haze=1.6},
  Grade={Tint=C(255,228,204),Saturation=.05,Contrast=.16},Bloom={Intensity=.4,Size=24,Threshold=1.3},Rays=.04,
  Clouds={Cover=.62,Density=.36,Color=C(184,124,94)}},
 TIME_WARP={Clock=19.2,Brightness=1.6,Ambient=C(82,132,152),Outdoor=C(112,172,192),Exposure=.08,
  Atmo={Density=.2,Offset=.1,Color=C(152,222,242),Decay=C(72,112,152),Glare=.3,Haze=1.4},
  Grade={Tint=C(222,246,255),Saturation=.08,Contrast=.12},Bloom={Intensity=.5,Size=30,Threshold=1.2},Rays=.03,
  Clouds={Cover=.45,Density=.28,Color=C(150,210,232)}},
 CURSED_FOG={Clock=.3,Brightness=1,Ambient=C(88,68,108),Outdoor=C(114,92,138),Exposure=.15,
  Atmo={Density=.34,Offset=.25,Color=C(142,122,166),Decay=C(72,42,92),Glare=0,Haze=2.4},
  Grade={Tint=C(236,222,255),Saturation=-.15,Contrast=.1},Bloom={Intensity=.45,Size=26,Threshold=1.25},Rays=0,
  Clouds={Cover=.9,Density=.6,Color=C(82,62,102)},Sky={MoonAngularSize=24,StarCount=600}},
 BLACKOUT={Clock=0,Brightness=.6,Ambient=C(40,50,86),Outdoor=C(60,76,122),Exposure=.2,
  Atmo={Density=.22,Offset=.1,Color=C(72,92,142),Decay=C(32,42,82),Glare=0,Haze=1},
  Grade={Tint=C(216,226,255),Saturation=-.2,Contrast=.2},Bloom={Intensity=.55,Size=28,Threshold=1.15},Rays=0,
  Clouds={Cover=.7,Density=.42,Color=C(42,48,70)},Sky={MoonAngularSize=18}},
 UFO_INVASION={Clock=.6,Brightness=1.2,Ambient=C(56,106,92),Outdoor=C(82,142,122),Exposure=.12,
  Atmo={Density=.2,Offset=.1,Color=C(112,202,162),Decay=C(42,92,82),Glare=.2,Haze=1.2},
  Grade={Tint=C(216,255,236),Saturation=.1,Contrast=.14},Bloom={Intensity=.55,Size=30,Threshold=1.15},Rays=0,
  Clouds={Cover=.5,Density=.3,Color=C(70,120,104)},Sky={StarCount=4500}},
 RAINBOW_RIFT={Clock=18.4,Brightness=2.2,Ambient=C(152,112,172),Outdoor=C(202,152,216),Exposure=.06,
  Atmo={Density=.18,Offset=.1,Color=C(242,182,255),Decay=C(152,92,202),Glare=.6,Haze=1.4},
  Grade={Tint=C(255,236,255),Saturation=.32,Contrast=.1},Bloom={Intensity=.5,Size=30,Threshold=1.2},Rays=.06,
  Clouds={Cover=.45,Density=.3,Color=C(255,192,240)}},
 NULL_HOUR={Clock=0,Brightness=.9,Ambient=C(112,102,122),Outdoor=C(132,122,142),Exposure=.1,
  Atmo={Density=.22,Offset=.1,Color=C(152,142,162),Decay=C(62,52,72),Glare=0,Haze=1},
  Grade={Tint=C(236,226,246),Saturation=-.82,Contrast=.25},Bloom={Intensity=.45,Size=24,Threshold=1.2},Rays=0,
  Clouds={Cover=.2,Density=.1,Color=C(120,112,128)},Sky={CelestialBodiesShown=false,StarCount=0}},
 THE_VOID_OPENS={Clock=0,Brightness=.8,Ambient=C(72,48,102),Outdoor=C(96,70,132),Exposure=.12,
  Atmo={Density=.24,Offset=.12,Color=C(122,82,182),Decay=C(52,22,92),Glare=0,Haze=1.4},
  Grade={Tint=C(236,222,255),Saturation=-.1,Contrast=.2},Bloom={Intensity=.5,Size=28,Threshold=1.2},Rays=0,
  Clouds={Cover=.7,Density=.4,Color=C(62,40,92)},Sky={StarCount=5000}},
}
L.Moods=moods
local function smooth(a)a=math.clamp(a,0,1);return a*a*(3-2*a)end
local function blend(a,b,t)
 if typeof(a)=='Color3'then return a:Lerp(b,t)end
 if typeof(a)=='number'and typeof(b)=='number'then return a+(b-a)*t end
 return t>=.5 and b or a
end
-- ClockTime wraps at 24; always travel the short way round the dial.
local function clock(a,b,t)local d=(b-a)%24;if d>12 then d-=24 end;return (a+d*t)%24 end
local function remember(object,keys)
 local row={};for _,k in ipairs(keys)do row[k]=object[k]end;return row
end
-- Writes a property only if nobody else changed it since our previous write; otherwise the
-- new external value becomes the baseline so a live writer is never fought.
local function drive(object,base,last,key,target,alpha,custom)
 if object[key]~=last[key]then base[key]=object[key]end
 local value=custom and custom(base[key],target,alpha)or blend(base[key],target,alpha)
 object[key]=value;last[key]=object[key]
end
function L.Begin()
 if L.Active then return end;L.Active=true
 for _,k in ipairs(props)do L.Baseline[k]=Lighting[k];L.Last[k]=Lighting[k]end
 L.Atmosphere=Lighting:FindFirstChildOfClass('Atmosphere');L.CreatedAtmosphere=not L.Atmosphere
 if not L.Atmosphere then L.Atmosphere=Instance.new('Atmosphere');L.Atmosphere.Name='DOGROTS_EventAtmosphere';L.Atmosphere.Density=0;L.Atmosphere.Parent=Lighting end
 L.AtmoKeys={'Density','Offset','Color','Decay','Glare','Haze'};L.AtmosphereBase=remember(L.Atmosphere,L.AtmoKeys);L.AtmosphereLast=table.clone(L.AtmosphereBase)
 L.Correction=Instance.new('ColorCorrectionEffect');L.Correction.Name='DOGROTS_EventGrade';L.Correction.Parent=Lighting
 L.Bloom=Lighting:FindFirstChild('DOGROTS_BloomEffect');if L.Bloom and not L.Bloom:IsA('BloomEffect')then L.Bloom=nil end
 L.CreatedBloom=not L.Bloom
 if not L.Bloom then L.Bloom=Instance.new('BloomEffect');L.Bloom.Name='DOGROTS_EventBloom';L.Bloom.Intensity=0;L.Bloom.Size=20;L.Bloom.Threshold=2;L.Bloom.Parent=Lighting end
 L.BloomKeys={'Intensity','Size','Threshold'};L.BloomBase=remember(L.Bloom,L.BloomKeys);L.BloomLast=table.clone(L.BloomBase)
 L.BloomWasEnabled=L.Bloom.Enabled;L.Bloom.Enabled=true
 L.Rays=Lighting:FindFirstChildOfClass('SunRaysEffect');L.CreatedRays=not L.Rays
 if not L.Rays then L.Rays=Instance.new('SunRaysEffect');L.Rays.Name='DOGROTS_EventRays';L.Rays.Intensity=0;L.Rays.Spread=.75;L.Rays.Parent=Lighting end
 L.RaysBase=remember(L.Rays,{'Intensity','Spread'});L.RaysLast=table.clone(L.RaysBase)
 L.Clouds=workspace.Terrain:FindFirstChildOfClass('Clouds');L.CreatedClouds=not L.Clouds
 if not L.Clouds then L.Clouds=Instance.new('Clouds');L.Clouds.Name='DOGROTS_EventClouds';L.Clouds.Cover=0;L.Clouds.Density=0;L.Clouds.Parent=workspace.Terrain end
 L.CloudKeys={'Cover','Density','Color'};L.CloudBase=remember(L.Clouds,L.CloudKeys);L.CloudLast=table.clone(L.CloudBase)
 L.Sky=Lighting:FindFirstChildOfClass('Sky');L.CreatedSky=false;L.SkyBase=nil
 local district=workspace:FindFirstChild('DOGROTS_District')
 if district then for _,o in ipairs(district:GetDescendants())do if o:IsA('Light')then
  L.Lights[o]={Enabled=o.Enabled,Brightness=o.Brightness,Navigation=o.Parent and (o.Parent.Name=='WarmLens'or o.Parent.Name=='PortalEnergy')}
 end end end
end
local function sky(mood,alpha)
 local want=mood.Sky
 if not want then
  if L.Sky and L.SkyBase then for k,v in pairs(L.SkyBase)do L.Sky[k]=v end end
  return
 end
 if not L.Sky then L.Sky=Instance.new('Sky');L.Sky.Name='DOGROTS_EventSky';L.Sky.Parent=Lighting;L.CreatedSky=true end
 if not L.SkyBase then L.SkyBase=remember(L.Sky,{'SunAngularSize','MoonAngularSize','StarCount','CelestialBodiesShown'})end
 for k,v in pairs(want)do
  if k=='CelestialBodiesShown'then L.Sky[k]=alpha<.5 and L.SkyBase[k]or v
  elseif k=='StarCount'then L.Sky[k]=math.floor(blend(L.SkyBase[k],v,alpha))
  else L.Sky[k]=blend(L.SkyBase[k],v,alpha)end
 end
end
function L.Update(def,alpha)
 if not L.Active then return end
 local mood=moods[def.Id]or{}
 local a=smooth(alpha)
 local target={ClockTime=mood.Clock or def.Clock,Brightness=mood.Brightness or def.Brightness,
  Ambient=mood.Ambient or def.Tint:Lerp(C(40,45,57),.7),OutdoorAmbient=mood.Outdoor or def.Tint:Lerp(C(60,70,84),.65),
  ExposureCompensation=mood.Exposure}
 for _,k in ipairs(props)do
  if target[k]~=nil then drive(Lighting,L.Baseline,L.Last,k,target[k],a,k=='ClockTime'and clock or nil)end
 end
 local atmo=mood.Atmo or{Density=def.AtmosphereProfile.Density,Color=def.Tint,Haze=.6}
 for _,k in ipairs(L.AtmoKeys)do if atmo[k]~=nil then drive(L.Atmosphere,L.AtmosphereBase,L.AtmosphereLast,k,atmo[k],a)end end
 local grade=mood.Grade or{}
 L.Correction.TintColor=Color3.new(1,1,1):Lerp(grade.Tint or def.Tint:Lerp(Color3.new(1,1,1),.78),a)
 L.Correction.Saturation=(grade.Saturation or def.Saturation or .07)*a;L.Correction.Contrast=(grade.Contrast or .1)*a;L.Correction.Brightness=(grade.Brightness or 0)*a
 local bloom=mood.Bloom or{Intensity=.2,Size=22,Threshold=1.5}
 for _,k in ipairs(L.BloomKeys)do drive(L.Bloom,L.BloomBase,L.BloomLast,k,bloom[k],a)end
 drive(L.Rays,L.RaysBase,L.RaysLast,'Intensity',mood.Rays or .01,a)
 local clouds=mood.Clouds or{Cover=.35,Density=.18,Color=def.Tint}
 for _,k in ipairs(L.CloudKeys)do drive(L.Clouds,L.CloudBase,L.CloudLast,k,clouds[k],a)end
 sky(mood,a)
 if def.Id=='BLACKOUT'then for light,row in pairs(L.Lights)do if light.Parent then
  local p=light.Parent;local x=p:IsA('BasePart')and p.Position.X or (p:IsA('Attachment')and p.WorldPosition.X)or 0
  local flicker=alpha>.08 and alpha<.72 and math.sin(alpha*85+x*.1)>-.15
  light.Enabled=row.Enabled and (row.Navigation or alpha<.75 and not flicker);light.Brightness=row.Brightness*(row.Navigation and .65 or 1)
 end end end
end
function L.Stop()
 if not L.Active then return end
 for _,k in ipairs(props)do if Lighting[k]==L.Last[k]then Lighting[k]=L.Baseline[k]end end
 for light,row in pairs(L.Lights)do if light.Parent then light.Enabled=row.Enabled;light.Brightness=row.Brightness end end;L.Lights={}
 if L.Atmosphere then
  if L.CreatedAtmosphere then L.Atmosphere:Destroy()
  else for k,v in pairs(L.AtmosphereBase)do if L.Atmosphere[k]==L.AtmosphereLast[k]then L.Atmosphere[k]=v end end end
 end
 if L.Bloom then
  if L.CreatedBloom then L.Bloom:Destroy()
  else for k,v in pairs(L.BloomBase)do if L.Bloom[k]==L.BloomLast[k]then L.Bloom[k]=v end end;L.Bloom.Enabled=L.BloomWasEnabled end
 end
 if L.Rays then if L.CreatedRays then L.Rays:Destroy()else for k,v in pairs(L.RaysBase)do L.Rays[k]=v end end end
 if L.Clouds then if L.CreatedClouds then L.Clouds:Destroy()else for k,v in pairs(L.CloudBase)do if L.Clouds[k]==L.CloudLast[k]then L.Clouds[k]=v end end end end
 if L.Sky then if L.CreatedSky then L.Sky:Destroy()elseif L.SkyBase then for k,v in pairs(L.SkyBase)do L.Sky[k]=v end end end
 if L.Correction then L.Correction:Destroy()end
 L.Atmosphere,L.Bloom,L.Rays,L.Clouds,L.Sky,L.Correction,L.SkyBase=nil,nil,nil,nil,nil,nil,nil
 L.Active=false
end
return L
