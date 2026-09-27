-- Execute client spell availability. The current SPOT-01 target-identity
-- contract runs separately in tools/tests/player_target_identity.lua.
local root='gamemodes/legend_of_deborah/gamemode/lod/'
local hooks={};hook={Add=function(_,id,f) hooks[id]=f end}
concommand={Add=function() end};net={Receive=function() end}
local now=1;CurTime=function() return now end
function IsValid(v) return type(v)=='table' and v.valid~=false end
local function player(name,character)
 local p={name=name,character=character,bools={},floats={LOD_Magic=50}}
 function p:IsPlayer() return true end
 function p:Alive() return true end
 function p:Health() return 75 end
 function p:GetMaxHealth() return 100 end
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
print('SPELL_AVAILABILITY_PASS: Quantum-adjusted resource/cooldown/status/ownership availability; target identity uses tools/tests/player_target_identity.lua')
