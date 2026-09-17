-- Execute client availability and real look-trace identity handling.
local root='gamemodes/legend_of_deborah/gamemode/lod/'
local hooks={};hook={Add=function(_,id,f) hooks[id]=f end}
concommand={Add=function() end};net={Receive=function() end}
local now=1;CurTime=function() return now end
function IsValid(v) return type(v)=='table' and v.valid~=false end
local function player(name,character)
 local p={name=name,character=character,bools={},floats={LOD_Magic=50}}
 function p:IsPlayer() return true end
 function p:Alive() return true end
 function p:Nick() return self.name end
 function p:GetNW2Bool(k,d) return self.bools[k] or d end
 function p:GetNW2Float(k,d) return self.floats[k] or d end
 function p:GetNW2Int(k,d) return d end
 function p:GetNW2String() return self.character end
 return p
end
local owner=player('Observer','Jane');LocalPlayer=function() return owner end
local drawn={};LOD={Equipment={IsActive=function() return false end},UI={Colors={muted={},red={},gold={},blue={}},HUDRoles={identity='username',prose='connector',character='character'},
 HUDText=function(_,text,_,x,y,color) drawn[#drawn+1]={text=text,color=color,x=x,y=y} end}}
ScrW=function() return 640 end;ScrH=function() return 480 end
surface={SetFont=function() end,GetTextSize=function(s) return #s*8 end}
dofile(root..'cl_spellbook.lua');local B=LOD.Spellbook
B.Snapshot={costMultiplier=.5,forms={{selected=true,magicCost=30}},contents={{selected=true,surcharge=10}}}
local form={owned=true,selected=true,magicCost=30}
assert(B:Availability(form,'form')=='READY / SELECTED')
owner.floats.LOD_Magic=19;assert(B:Availability(form,'form')=='NEED MAGIC')
owner.floats.LOD_Magic=20;owner.floats.LOD_MagicNextCast=2;assert(B:Availability(form,'form')=='COOLDOWN')
owner.floats.LOD_MagicNextCast=0;owner.bools.LOD_StatusMuted=true;assert(B:Availability(form,'form')=='BLOCKED')
owner.bools={LOD_StatusIntimidated=true};assert(B:Availability(form,'form')=='BLOCKED')
owner.bools={LOD_StatusHeld=true};assert(B:Availability(form,'form')=='READY / SELECTED','Held does not lock casting')
assert(B:Availability({owned=false},'form')=='LOCKED')
owner.bools={}
local teammate=player('LongTeammateUsername','A Character With A Very Long Name')
function owner:GetEyeTrace() return {Entity=self.look} end
owner.look=teammate
dofile(root..'cl_teammate_identity.lua')
hooks.LOD_TeammateIdentity();local text='';local rows={};local colors={}
for _,span in ipairs(drawn) do text=text..span.text;rows[span.y]=true;colors[span.color]=true end
assert(text==teammate.name..' as '..teammate.character)
assert(colors.username and colors.connector and colors.character)
local n=0;for _ in pairs(rows) do n=n+1 end;assert(n>=2,'Identity must wrap')
owner.look={IsPlayer=function() return false end};drawn={};hooks.LOD_TeammateIdentity();assert(#drawn==0,'Wall trace revealed teammate')
owner.look=teammate;teammate.bools.LOD_IsSoldier=true;hooks.LOD_TeammateIdentity();assert(#drawn==0,'Enemy classified as teammate')
print('REFRESH_UI_PASS: Quantum-adjusted resource/cooldown/status/ownership availability; trace-only identity, semantic colors and wrapping')
