local e=dofile('tools/music_test_fixture.lua');local check=e.check
CLIENT=true;CreateConVar('lod_music_enabled','1')
dofile('gamemodes/legend_of_deborah/gamemode/lod/cl_music.lua')
local D,M=LOD.MusicDirector,LOD.Music;D.ServerOn=true
local c=e.catalog();local p=M.Plan(c,{set='all'},1,'resources',4,1);D.Plans[p.id]=p
D.Current={plan=p.id,epoch=1,sequence=1,role='INTERLUDE',staged=true,targets={{block=p.floors[1],weight=1}}}
e.step();check(#e.requests==1,'Chill selected for staged listener')
local ch=e.complete(1,16);e.step(30)
check(D.Channels[c.profiles.default.roles.INTERLUDE] and ch.played,'staging plays the dedicated interlude')
local reconcile,mix=0,0;local original,originalMix=D.Reconcile,D.Mix
function D:Reconcile() reconcile=reconcile+1;return original(self) end
function D:Mix(dt) mix=mix+1;return originalMix(self,dt) end
local writes=e.volumeWrites
for i=1,120 do e.now=e.now+1/120;D:Tick() end
check(reconcile<=6 and mix<=31,'120 FPS has at most 5 Hz selection and 30 Hz envelope work')
check(e.volumeWrites==writes,'steady native gain causes zero redundant volume writes')
local steadyReconcile,steadyMix=reconcile,mix
local requests=#e.requests
local localPlayer={valid=true,ping=20};function localPlayer:Ping() return self.ping end
LocalPlayer=function() return localPlayer end
D.NextBudget=0;D:Tick();localPlayer.ping=130;D.NextBudget=0;D:Tick()
check(D.WorkBlocked,'ping rise above baseline pauses optional music work')
D.Current.role='T3';e.step(20)
check(#e.requests==requests and ch.valid,'congestion retains cached audio without opening another decoder')
localPlayer.ping=20;e.step(40);check(D.WorkBlocked,'recovery hysteresis does not flap immediately')
e.step(30);check(not D.WorkBlocked and #e.requests==requests+1,'healthy interval resumes current musical demand')
e.complete(#e.requests,16);e.step(20)
e.frame=.12;e.step(100)
check(D.Emergency and D:Counts()==0 and D.DemandOn==false,'sustained severe frame pressure releases playback and opts out of state service')
D.ServerOn=false;e.frame=1/60;e.step(220)
check(not D.Emergency and D.DemandOn==true,'recovery can resubscribe while server permission acknowledgement is off')
D.ServerOn=true;e.step();e.complete(#e.requests,16);e.step(20)
e.set('lod_music_volume',0);requests=#e.requests;e.step(100)
check(D:Counts()==0 and D.DemandOn==false and #e.requests==requests,'zero volume releases playback, state demand and native work')
e.set('lod_music_volume',.55);e.step();check(D.DemandOn,'raising volume requests current role again')
-- A cold/stale plan packet received after opt-out is never decompressed.
e.set('lod_music',0);local decompressed=0;local old=util.Decompress
util.Decompress=function(...) decompressed=decompressed+1;return old(...) end
e.receive('LOD_MusicPlan','ignored',1,1,10,'irrelevant')
check(decompressed==0,'Off skips music metadata decoding')
-- Silent library fallback is allowed only within the quiet class.
D.Failures={};local b=p.blocks[p.floors[1]];b.roles.INTERLUDE={}
check(D:Candidate(p,p.floors[1],'INTERLUDE').asset==c.profiles.default.roles.T0,'missing Chill falls back to that block calm role')
-- Plan pieces assemble once, with no partial installation or oversized work.
e.set('lod_music',1);D.ServerOn=true
local wire=table.Copy(p);wire.id='chunked-plan';local data=util.TableToJSON(wire)
local total=math.ceil(#data/M.Limits.planChunk)
for part=1,total do
 local chunk=data:sub((part-1)*M.Limits.planChunk+1,part*M.Limits.planChunk)
 e.receive('LOD_MusicPlan',wire.id,part,total,#chunk,chunk)
 if part<total then check(not D.Plans[wire.id],'partial plan never becomes playable') end
end
check(D.Plans[wire.id] and decompressed==1,'one complete bounded plan decoded once')
e.receive('LOD_MusicPlan','bad-plan',1,1,M.Limits.planChunk+1,'bad')
check(not D.Plans['bad-plan'] and decompressed==1,'oversized metadata rejected before decompression')
LOD.MusicMedia.failures.stale='old transfer failed'
e.receive('LOD_MusicState',util.TableToJSON({plan=p.id,epoch=2,sequence=100,role='INTERLUDE',targets={{block=p.floors[1],weight=1}}}))
check(not next(LOD.MusicMedia.failures),'new campaign permits a bounded retry after an old media failure')
print('MUSIC_RESOURCES PASS '..e.checks..' reconcile='..steadyReconcile..' mix='..steadyMix)
