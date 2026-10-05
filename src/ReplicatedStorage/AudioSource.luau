-- Shared audio resolution. Local files are an explicit Studio-only portable pack.
-- Published experiences still use their configured audio assets and permissions.
local Run=game:GetService('RunService')
local Manifest=require(script.Parent.LocalAudioManifest)
local A={}
function A.Resolve(id,path,loop,fallback)
 if Run:IsStudio()and game.GameId==0 then
  if path and Manifest.Files[path]then return 'rbxasset://'..path end
  if loop then
   local event=path and path:match('/WorldEvents/([^/]+)/')
   if not event then
    event=path and path:find('void')and'THE_VOID_OPENS'or path and path:find('lab')and'CRYSTAL_STORM'or'GOLDEN_HOUR'
   end
   local ambient=Manifest.Ambient[event]or Manifest.Ambient.GOLDEN_HOUR
   if ambient then return 'rbxasset://'..ambient end
  elseif path then
   -- Original local one-shot files are absent from this machine's current Studio
   -- installation. Keep cues audible using Roblox's bundled, portable chime.
   return fallback or 'rbxasset://sounds/volume_slider.ogg'
  end
 end
 if type(id)=='number'and id>0 then return 'rbxassetid://'..string.format('%.0f',id)end
 return fallback
end
return A
