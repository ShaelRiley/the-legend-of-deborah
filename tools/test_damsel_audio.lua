-- Production feedback dispatch/lifecycle with realm and native sound boundaries.
local root='gamemodes/legend_of_deborah/gamemode/lod/'
local now,globalSilent=100,true
local hooks,timers,packets,resources={},{},{},{}
local function noop() end
function CurTime() return now end
function IsValid(e) return type(e)=='table' and e.valid~=false end
function math.Clamp(n,a,b) return math.max(a,math.min(b,n)) end
function SetGlobalBool(_,v) globalSilent=v end
function GetGlobalBool(_,fallback) return globalSilent end
hook={Add=function(_,id,fn) hooks[id]=fn end}
timer={Simple=function(_,fn) timers[#timers+1]=fn end}
util={AddNetworkString=noop};resource={AddFile=function(p) resources[#resources+1]=p end}
local packet
net={Start=function(name) packet={name=name} end,WriteUInt=function(v,bits) assert(bits==6);packet.id=v end,
 WriteFloat=function(v) packet.volume=v end,Send=function(p) packet.p=p;packets[#packets+1]=packet end}
local a={GetPos=function() return {Distance=function() return 20 end} end}
local b={GetPos=a.GetPos}
player={GetAll=function() return {a,b} end}
SERVER=true;CLIENT=false
LOD={RunManager={State={BuildReady=false},BuildCurrentLevel=function(self,success)
    assert(LOD.Audio:Muted() and hooks.LOD_GenerationSoundBarrier({})==false)
    assert(not LOD.Audio:ToPlayer(a,'loot_spawn'))
    self.State.BuildReady=success~=false;return success~=false,'built'
end}}
function LOD.RunManager:NewCampaign() return self:BuildCurrentLevel() end
dofile(root..'sh_audio.lua');local A=LOD.Audio
assert(#resources==60 and A.Cues.statue_transform.index<64)
local paths={};for id,c in pairs(A.Cues) do assert(not paths[c.path]);paths[c.path]=id end
assert(not A:ToPlayer(a,'hit_confirm') and hooks.LOD_GenerationSoundBarrier({})==false)
dofile(root..'sv_audio_lifecycle.lua')
assert(LOD.RunManager:NewCampaign())
local first=timers[#timers]
assert(LOD.RunManager:BuildCurrentLevel())
first();assert(A:Muted(),'stale build callback cannot release a later generation')
timers[#timers]();assert(not A:Muted() and hooks.LOD_GenerationSoundBarrier({})==nil)
assert(#packets==0,'startup must produce no cues')
for i=1,100 do A:At({},'loot_spawn') end
assert(#packets==2 and packets[1].p~=packets[2].p,'one cue per recipient, not per loot entity')
now=now+.23;A:At({},'loot_spawn');assert(#packets==4)
local beforeDefeat=#packets
for i=1,100 do A:At({},'enemy_defeated') end
assert(#packets==beforeDefeat+2,'simultaneous defeats coalesce per listener')
now=now+.13;A:At({},'enemy_defeated');assert(#packets==beforeDefeat+4)
assert(A:ToPlayer(a,'hit_confirm') and A:ToPlayer(a,'spatial_awareness'))
assert(not A:ToPlayer(a,'hit_confirm'))
now=now+.05;assert(A:ToPlayer(a,'hit_confirm') and not A:ToPlayer(a,'spatial_awareness'))
hooks.LOD_AudioCleanupBarrier();assert(A:Muted())
hooks.LOD_AudioCleanupRelease();timers[#timers]();assert(not A:Muted())
assert(not LOD.RunManager:BuildCurrentLevel(false));assert(A:Muted())
LOD.RunManager:BuildCurrentLevel();timers[#timers]();assert(not A:Muted())
-- Client default suppresses sound, then receives one local voice per packet.
SERVER=false;CLIENT=true
LOD.Audio=nil;globalSilent=true;local receiver,sounds={},{}
net.Receive=function(name,fn) receiver[name]=fn end
local ply={EmitSound=function(_,path,level,pitch,volume,channel)
    assert(level==0 and pitch==100 and volume<=.65);sounds[#sounds+1]=path
end}
function LocalPlayer() return ply end
CHAN_AUTO=0
dofile(root..'sh_audio.lua');A=LOD.Audio
assert(not A:Play('hit_confirm') and #sounds==0)
globalSilent=false
local received=packets[1]
net.ReadUInt=function() return received.id end;net.ReadFloat=function() return received.volume end
receiver.LOD_AudioCue();receiver.LOD_AudioCue();assert(#sounds==1)
assert(A:Play('hit_confirm') and A:Play('spatial_awareness'))
assert(sounds[2]~=sounds[3] and not A:Play('spatial_awareness'))
-- Actual death cleanup owns no new non-diegetic sound/timer path.
dofile(root..'sv_hostile_death_audio.lua')
assert(hooks.LOD_HostileDeathAudio_SuppressLegacy({Entity={LODDead=true},SoundName='buttons/blip1.wav'})==false)
assert(hooks.LOD_HostileDeathAudio_SuppressLegacy({Entity={LODDead=true},SoundName='npc/zombie/zombie_die1.wav'})==nil)
assert(hooks.LOD_GenerationSoundBarrier({SoundName='Weapon_AR2.Single'})==nil)
print('DAMSEL_AUDIO_PASS: initialization/cleanup silence, stale-build isolation, post-cleanup recovery, per-recipient coalescing, unique identities and preserved diegetic playback')
