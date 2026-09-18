-- Exercise real ownership without a Source audio device.
LOD={};local now,created,stopped=0,0,0;local hooks={}
function CurTime() return now end
function IsValid(e) return type(e)=='table' and e.valid~=false end
local staged=false
function LocalPlayer() return {GetNW2Bool=function() return staged end} end
function EyePos() return 0 end
local function entity(distance)
 return {GetPos=function() return {DistToSqr=function() return distance end} end}
end
hook={Add=function(_,id,fn) hooks[id]=fn end}
function CreateSound()
 created=created+1;local patch={}
 function patch:SetSoundLevel() end
 function patch:PlayEx() end
 function patch:Stop() assert(not self.stopped,'Patch stopped twice');self.stopped=true;stopped=stopped+1 end
 return patch
end
local path='gamemodes/legend_of_deborah/gamemode/lod/cl_loop_audio.lua'
dofile(path);local a,b,c=entity(100),entity(200),entity(300)
local A=LOD.LoopAudio
for i=1,1000 do A:Touch('gas',a,'gas',.2,100,60,.3) end
assert(created==1)
A:Touch('gas',b,'gas',.2,100,60,.3);A:Touch('gas',c,'gas',.2,100,60,.3);assert(created==2)
local close=entity(1);A:Touch('gas',close,'gas',.2,100,60,.3);assert(created==3 and stopped==1)
now=.31;hooks.LOD_LoopAudioLeases();assert(stopped==3)
A:Touch('fuse',a,'fuse',.2,100,60);hooks.LOD_LoopAudioEntityRemoved(a);assert(stopped==4)
A:Touch('watcher',b,'watcher',.2,100,60);b.valid=false;hooks.LOD_LoopAudioLeases();assert(stopped==5)
A:Touch('gas',a,'gas',.2,100,60);staged=true;hooks.LOD_LoopAudioLeases();assert(stopped==6)
assert(not A:Touch('gas',a,'gas',.2,100,60));staged=false
for _,state in ipairs({'failed','levelCleared'}) do
 A:Touch('gas',a,'gas',.2,100,60);LOD.ClientState={[state]=true};hooks.LOD_LoopAudioLeases()
 assert(created==stopped);LOD.ClientState=nil
end
for _,event in ipairs({'LOD_LoopAudioCleanup','LOD_LoopAudioShutdown'}) do
 A:Touch('gas',a,'gas',.2,100,60);hooks[event]();assert(created==stopped)
end
A:Touch('gas',entity(1),'gas',.2,100,60);collectgarbage('collect');dofile(path)
assert(created==stopped,'Reload/GC cannot orphan a native patch')
local f=assert(io.open('gamemodes/legend_of_deborah/gamemode/lod/sv_enemy_roster.lua'))
assert(not f:read('*a'):find('mtov_flame2.wav',1,true));f:close()
print('LOOP_AUDIO_PASS: dedupe, nearest caps, finite leases, owner loss, staging, run end, cleanup, reload and fire one-shot')
