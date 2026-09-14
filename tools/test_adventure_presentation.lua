-- Actual cosmetic policy/render/audio controller, with Source boundary fakes.
local root='gamemodes/legend_of_deborah/gamemode/lod/'
local now=100
function CurTime() return now end
function isstring(v) return type(v)=="string" end
function IsValid(v) return type(v)=='table' and v.valid==true end
function Color(r,g,b,a) return {r=r,g=g,b=b,a=a or 255} end
function math.Clamp(v,a,b) return math.max(a,math.min(b,v)) end
local cvs={}
function CreateClientConVar(name,value)
    local c={value=tonumber(value),GetFloat=function(self) return self.value end,GetBool=function(self) return self.value~=0 end}
    cvs[name]=c;return c
end
local material, hooks, sounds, stops, draws, timers, receivers = nil,{}, {},{}, {},{},{}
function CreateMaterial(_,_,params) material=params;return params end
surface={CreateFont=function() end,SetDrawColor=function() end,DrawLine=function(...) draws[#draws+1]={...} end,
    DrawOutlinedRect=function(...) draws[#draws+1]={...} end}
draw={SimpleTextOutlined=function(...) draws[#draws+1]={...} end,SimpleText=function(...) draws[#draws+1]={...} end}
file={Exists=function() return true end}
hook={Add=function(event,id,fn) hooks[id]=fn end}
local ply={valid=true,alive=true}
function ply:Alive() return self.alive end
function ply:EmitSound(path,level,pitch,volume,channel) sounds[#sounds+1]={path=path,volume=volume} end
function ply:StopSound(path) stops[#stops+1]=path end
function LocalPlayer() return ply end
function ScrW() return 1280 end
function ScrH() return 800 end
TEXT_ALIGN_CENTER,TEXT_ALIGN_TOP,CHAN_AUTO=1,2,0
LOD={Config={Progression={Cards={{color=Color(240,80,80),letter='R'},{color=Color(80,190,110),letter='G'}}}}}
dofile(root..'sh_feedback_language.lua')
dofile(root..'cl_adventure_presentation.lua')
local A=LOD.AdventurePresentation
assert(material['$ignorez']=='0','glints must obey scene depth')
assert(LOD.AdventureCueForEvent({event='keycard_acquired'})==1)
assert(LOD.AdventureCueForEvent({event='objective_denied'})==0)
assert(LOD.AdventureCueForEvent({event='loot_collected',kind='health'})==0)
assert(LOD.AdventureCueForEvent({event='loot_collected',kind='weapon'})==4)
assert(not A:Play(99,true) and #sounds==0)
assert(A:OnFeedback({cue=1,cueVariant=2}))
assert(#sounds==1 and sounds[1].path:find('discovery.wav') and A.active.variant==2)
assert(not A:OnFeedback({cue=1,cueVariant=2}) and #sounds==1,'same accent cooldown')
now=100.2
assert(not A:Play(4,true) and A.active.index==1,'lesser event cannot displace discovery or soundtrack')
assert(A:Play(6,false) and #stops==1,'rescue preempts with one new audio voice')
hooks.LOD_AdventureAccent()
assert(#draws>0,'actual HUD path draws the small card ornament')
now=104;hooks.LOD_AdventureAccent();assert(not A.active)
cvs.lod_adventure_volume.value=0
assert(not A:Play(2,true) and #sounds==2,'mute affects new music but permits visual confirmation')
cvs.lod_reduced_effects.value=1
assert(A:Reduced())
hooks.LOD_AdventureAccent()
A:Reset();assert(not A.active and not A.soundPath and next(A.nextCue)==nil)
cvs.lod_adventure_volume.value=.65
now=110;A:Play(1,true);ply.alive=false;hooks.LOD_AdventureAccent()
assert(not A.active and not A.soundPath,'death cannot retain a flourish or playing music')
ply.alive=true
for i=1,1000 do now=now+1;A:Play((i%7)+1,true) end
local count=0;for _ in pairs(A.nextCue) do count=count+1 end
assert(count<=7,'constant-size cooldown state')
hooks.LOD_AdventureReset();assert(not A.active and next(A.nextCue)==nil)

-- Rescue callbacks are invalidated by map cleanup or a replacement celebration.
function Vector(x,y,z)
    return setmetatable({x=x or 0,y=y or 0,z=z or 0},{__add=function(a,b) return Vector(a.x+b.x,a.y+b.y,a.z+b.z) end})
end
function ply:GetPos() return Vector(0,0,0) end
function ParticleEmitter() return {Add=function() return nil end,Finish=function() end} end
function math.Rand(a,b) return (a+b)/2 end
surface.PlaySound=function(path) sounds[#sounds+1]={path=path} end
local particleBursts=0
function ParticleEmitter() particleBursts=particleBursts+1;return {Add=function() return nil end,Finish=function() end} end
timer={Simple=function(_,fn) timers[#timers+1]=fn end}
net={Receive=function(name,fn) receivers[name]=fn end,ReadVector=function() return Vector(0,0,0) end,
    ReadFloat=function() return 6.5 end,ReadEntity=function() return nil end}
concommand={Add=function() end}
dofile(root..'cl_victory_celebration.lua')
receivers.LOD_VictoryCelebration()
assert(particleBursts==1)
local immediate=#sounds
hooks.LOD_VictoryPresentationReset();hooks.LOD_AdventureReset()
for _,fn in ipairs(timers) do fn() end
assert(particleBursts==1 and #sounds==immediate,'stale confetti/voices do not cross map cleanup')
print('ADVENTURE_PRESENTATION_PASS — event policy, priority, mute, bounded effects, visible ornament, depth and lifecycle')
