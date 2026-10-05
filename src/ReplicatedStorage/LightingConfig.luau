local M={}
M.DayCycle={Enabled=true,Minutes=30}
M.Preset={ClockTime=15.6,Brightness=2.25,ExposureCompensation=.08,GlobalShadows=true,
 Ambient=Color3.fromRGB(108,121,137),OutdoorAmbient=Color3.fromRGB(148,159,173),
 EnvironmentDiffuseScale=.55,EnvironmentSpecularScale=.35,ShadowSoftness=.35,FogStart=0,FogEnd=100000,FogColor=Color3.fromRGB(199,216,229)}
M.Atmosphere={Density=.12,Offset=.06,Color=Color3.fromRGB(199,216,229),Decay=Color3.fromRGB(111,135,157),Glare=.12,Haze=.55}
M.BloomEffect={Enabled=true,Intensity=.2,Size=24,Threshold=1.7}
M.ColorCorrectionEffect={Enabled=true,Brightness=0,Contrast=.08,Saturation=.07,TintColor=Color3.fromRGB(255,252,246)}
M.SunRaysEffect={Enabled=true,Intensity=.035,Spread=.55}
-- Soft daytime clouds; Roblox lights them by the sun, so nights darken on their own.
M.Clouds={Enabled=true,Cover=.42,Density=.3,Color=Color3.fromRGB(255,255,255)}
M.DepthOfFieldEffect={Enabled=false,FarIntensity=0,FocusDistance=80,InFocusRadius=80,NearIntensity=0}
M.Architectural={PrimaryArchitectureLight={Enabled=true,Multiplier=1},SecondaryArchitectureLight={Enabled=true,Multiplier=.7},PathLight={Enabled=true,Multiplier=.5},DecorativeLight={Enabled=true,Multiplier=.3}}
function M.ApplyPreset()
 local L=game:GetService('Lighting')
 for k,v in pairs(M.Preset)do L[k]=v end
 for _,class in ipairs({'Atmosphere','BloomEffect','ColorCorrectionEffect','DepthOfFieldEffect','SunRaysEffect'})do
  local e=L:FindFirstChild('DOGROTS_'..class)or Instance.new(class);e.Name='DOGROTS_'..class;e.Parent=L
  for k,v in pairs(M[class])do e[k]=v end
 end
 local clouds=workspace.Terrain:FindFirstChildOfClass('Clouds')or Instance.new('Clouds');clouds.Name='DOGROTS_Clouds'
 for k,v in pairs(M.Clouds)do clouds[k]=v end;clouds.Parent=workspace.Terrain
end
function M.ResetToDefault()M.ApplyPreset()end
return M
