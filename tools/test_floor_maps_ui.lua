-- Actual major-FX renderer and keycard audio controller, native draw doubles.
dofile('tools/test_adventure_presentation.lua')
SERVER=false
local root='gamemodes/legend_of_deborah/gamemode/lod/'
local now,width=200,1280
CurTime=function() return now end
ScrW=function() return width end
local hooks,fonts,texts,matrices={}, {}, {}, {}
hook={Add=function(event,id,f) hooks[id]=f end}
net={Receive=function() end}
surface.CreateFont=function(n,spec) fonts[n]=spec end
surface.SetFont=function(n) surface.font=n end
surface.GetTextSize=function(s) return #s*(surface.font=='LOD_RPGMajorFXPrimary' and 32 or 12),58 end
surface.DrawCircle=function() end
draw.RoundedBox=function() end
draw.SimpleTextOutlined=function(s,font,x,y) texts[#texts+1]={text=s,font=font,x=x,y=y} end
function Matrix()
 return {SetScale=function(self,v) self.scale=v end,SetTranslation=function(self,v) self.translation=v end}
end
cam={PushModelMatrix=function(m) matrices[#matrices+1]=m end,
 PopModelMatrix=function() assert(#matrices>0);table.remove(matrices) end}
concommand={Add=function() end}
local A=LOD.AdventurePresentation
local cues={}
local base=A.Play
function A:Play(index,visual,...)
 cues[#cues+1]=index
 return base(self,index,visual,...)
end
dofile(root..'cl_rpg_major_fx.lua')
local FX=LOD.RPGMajorFX
assert(fonts.LOD_RPGMajorFXPrimary.size==58 and fonts.LOD_RPGMajorFXSecondary.size==22)
assert(FX:Trigger(5,'Use map with Q','M works too',9))
assert(cues[#cues]==1,'map did not use the exact keycard discovery cue')
now=200.2;hooks.LOD_RPGMajorFX()
assert(#texts==3)
for i,s in ipairs({'Use map with Q','M works too','Map consumes magic'}) do assert(texts[i].text==s) end
assert(texts[1].font=='LOD_RPGMajorFXPrimary')
assert(texts[2].font=='LOD_RPGMajorFXSecondary' and texts[3].font=='LOD_RPGMajorFXSecondary')
assert(texts[1].y<texts[2].y and texts[2].y<texts[3].y,'notice lines out of order')
width=400;texts={};hooks.LOD_RPGMajorFX();assert(#texts==3 and #matrices==0,'narrow notice leaked its scale')
now=203.99;hooks.LOD_RPGMajorFX();assert(FX.active,'reading window ended too early')
now=204;hooks.LOD_RPGMajorFX();assert(not FX.active)
FX:Trigger(2,'LEVEL UP!','PRESS P TO SEE',10);assert(cues[#cues]==5,'map replaced ordinary level audio')
now=205.81;hooks.LOD_RPGMajorFX();assert(not FX.active,'changed accepted level-up duration')
print('FLOOR_MAPS_UI_PASS: exact keycard ditty; 58/22 fonts; three literal lines/order; narrow-screen scale restored; four-second notice; unchanged level-up sound/timing')
