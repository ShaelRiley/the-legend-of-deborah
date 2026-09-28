local e=dofile('tools/music_test_fixture.lua');local M=LOD.Music;local check=e.check
CLIENT=true;CreateConVar('lod_music_enabled','0')
dofile('gamemodes/legend_of_deborah/gamemode/lod/cl_music.lua')
local D=LOD.MusicDirector
local c=e.catalog();local plan=assert(M.Plan(c,{set='all',post_victory='auto'},1,'run:1',4,1))
D.Plans[plan.id]=plan
local alpha,beta=plan.floors[1],plan.floors[2]
D.Current={plan=plan.id,epoch=1,sequence=1,role='T0',targets={{block=alpha,weight=1}}}
e.step();check(#e.requests==0,'default off has zero URL requests')
e.set('lod_music_enabled',1);D.ServerOn=true;e.step();check(#e.requests==1,'server permission starts one stream')
check(e.requests[1].flags=='noplay noblock','seekable nonautoplay native mode')
local first=e.complete(1,.1);e.step();check(e.plays==0,'callback alone not ready')
first.buffer=16;e.step(3);check(e.plays==1,'buffered stream starts');check(first.loop,'T0 loops')
check(#e.announced==1 and e.announced[1].args[3]==alpha,'one actual start announcement')
e.step(20);check(#e.announced==1,'no frame/loop announcements')
-- Phase-aligned T1 and its fallback preserve the logical block identity.
first.time=7;D.Current.role='T1';e.step();local incoming=e.complete(2,2)
e.step();check(not incoming.played and first.volume>0,'unbuffered seek retains outgoing')
incoming.buffer=16;e.step(3);check(incoming.time==7,'matched phase on tension change')
e.step(20);check(#e.announced==1,'same-block tension has no entry')
-- Same shared file, different logical floor: reuse without new decoding.
D.Current.targets={{block=alpha,weight=.5},{block=beta,weight=.5}};e.step()
check(#e.requests==2 and #e.announced==2,'shared asset reuse, incoming block named in stair mix')
e.step(5);check(#e.announced==2,'stair gain updates deduplicated')
D.Current.targets={{block=beta,weight=1}};e.step(15)
D.Current.targets={{block=alpha,weight=.5},{block=beta,weight=.5}};e.step()
check(#e.announced==3,'genuine later return announced')
-- Stop immediately; pending callbacks are stopped, no retry after disable.
D.Current.role='T2';e.step();local request=#e.requests
e.set('lod_music',0);check(not incoming.valid,'player off releases audio')
local late=e.complete(request,16);check(not late.valid,'late callback discarded')
e.step(20);check(#e.requests==request,'no downloads/retries while off')
e.set('lod_music',1);e.step();check(#e.requests==request+1,'reenable current loop')
e.complete(#e.requests,16);e.step(20)
local receipt={plan=plan.id,epoch=1,sequence=2,role='POST',targets={{block=alpha,weight=1}},victory='clear:1',canVictory=true,startedAt=e.now,endsAt=e.now+6.5,policy='auto'}
e.receive('LOD_MusicState',util.TableToJSON(receipt));e.step()
local v=e.complete(#e.requests,6.5);e.step();check(v.played and not v.loop,'accepted clear plays one nonlooping fanfare')
local count=e.plays;e.receive('LOD_MusicState',util.TableToJSON(receipt));e.step()
check(e.plays==count,'duplicate victory packet does not replay')
e.set('lod_music',0);e.set('lod_music',1);receipt.sequence=3
e.receive('LOD_MusicState',util.TableToJSON(receipt));e.step();check(D.SeenVictory['clear:1'] and D.Victory.finished,'toggle cannot replay fanfare')
-- A delayed clear packet accepted while music was off must not create a fanfare.
D.Victory=nil;e.set('lod_music',0);local oldClear=e.now;e.now=e.now+1;e.set('lod_music',1)
receipt.victory='missed';receipt.startedAt=oldClear;receipt.sequence=4
receipt.endsAt=e.now+4;e.receive('LOD_MusicState',util.TableToJSON(receipt))
check(not D.Victory,'delayed pre-enable victory is skipped')
-- Saturation and obsolete callbacks cannot grow beyond native bounds.
D:Stop();D.Current={plan=plan.id,epoch=1,sequence=4,role='T0',targets={{block=alpha,weight=1}}}
for i=1,40 do
 D.Current.role='T'..(i%4);e.step()
 local slots,transfers=D:Counts();check(slots<=4 and transfers<=2,'hard slot/transfer bound under rapid retargeting')
end
print('MUSIC_CLIENT PASS '..e.checks)
