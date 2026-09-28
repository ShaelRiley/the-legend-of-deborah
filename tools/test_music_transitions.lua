local e=dofile('tools/music_test_fixture.lua');local M=LOD.Music;local check=e.check
CLIENT=true;CreateConVar('lod_music_enabled','1')
dofile('gamemodes/legend_of_deborah/gamemode/lod/cl_music.lua');local D=LOD.MusicDirector;D.ServerOn=true
local c=e.catalog()
-- Give each of two floor identities genuinely different decoded assets.
for i,role in ipairs({'T0','T1'}) do
 local a=table.Copy(c.assets[c.profiles.default.roles[role]])
 a.hash=string.rep(i==1 and 'a' or 'b',64);a.path='music/blocks/beta/v1/'..role:lower()..'.ogg'
 c.assets[a.hash]=a;c.blocks.beta.roles[role]=a.hash
end
local plan=assert(M.Plan(c,{set='pair',post_victory='auto'},9,'run:1',4,1));D.Plans[plan.id]=plan
D.Current={plan=plan.id,epoch=1,sequence=1,role='T0',targets={{block='alpha',weight=.5},{block='beta',weight=.5}}}
e.step();check(#e.requests==2,'two floor voices, two transfers')
e.complete(1,16);e.complete(2,16);e.step(20)
check(#e.sent==2,'each incoming block announced once')
D.Current.role='T1';e.step();check(#e.requests==4,'simultaneous floor/tension transition fits four slots')
e.complete(3,16);e.complete(4,16);e.step(20)
check(D:Counts()==2 and #e.sent==2,'old tension channels retired without block re-announcement')
local entries=#e.sent;e.set('lod_music',0);e.set('lod_music',1);e.step()
e.complete(5,16);e.complete(6,16);e.step(20)
check(#e.sent==entries,'two-floor Off/On does not invent new block starts')
-- Native failure takes bounded role-specific fallback, never replays a one-shot.
D.Current.targets={{block='beta',weight=1}};D.Current.role='T0';e.step();local n=#e.requests
e.complete(n,0,true);e.step();check(#e.requests==n+1,'failed custom moves to project role default')
e.complete(n+1,16);e.step(20)
check(D.Channels[c.profiles.default.roles.T0].source=='project-default','actual fallback provenance')
local nextPlan=assert(M.Plan(c,{set='pair',post_victory='auto'},10,'run:2',4,1));D.Plans[nextPlan.id]=nextPlan
local function post(policy,id)
 e.receive('LOD_MusicState',util.TableToJSON({plan=plan.id,epoch=1,sequence=id,role='POST',targets={{block='alpha',weight=1}},
  victory='clear:'..id,canVictory=false,endsAt=e.now-1,policy=policy,next=nextPlan.id,nextBlock='alpha'}))
end
post('auto',2);local wanted=D:Desired()
check(wanted[1].plan.id==nextPlan.id and wanted[1].role=='T0','AUTO skips padding when next T0 buffered')
post('interlude',3);wanted=D:Desired();check(wanted[1].role=='INTERLUDE' and wanted[1].plan.id==plan.id,'INTERLUDE policy retains outgoing bridge')
post('off',4);wanted=D:Desired();check(wanted[1].role=='T0','OFF skips dedicated interlude')
D:Stop();D.Plans[plan.id]=plan;D.Plans[nextPlan.id]=nextPlan
post('auto',5);local preload;wanted,preload=D:Desired()
check(wanted[1].role=='INTERLUDE' and preload[1].role=='T0','AUTO uses bridge while next track unready')
e.step();local start=#e.requests;for i=start-1,start do if e.requests[i] and not e.requests[i].channel then e.complete(i,16) end end
e.step(20);wanted=D:Desired();check(wanted[1].plan.id==nextPlan.id,'ready next T0 displaces bridge')
local plays=e.plays
local state={plan=nextPlan.id,epoch=1,sequence=6,role='T0',targets={{block='alpha',weight=1}},staged=true}
e.receive('LOD_MusicState',util.TableToJSON(state));e.step(20)
check(e.plays==plays,'same next T0 transport through staging')
state.sequence=7;state.staged=false;e.receive('LOD_MusicState',util.TableToJSON(state));e.step(20)
check(e.plays==plays,'portal preserves transport')
-- A fully buffered prefetched fanfare stays available beyond the load timeout.
D.Current.preload='VICTORY';e.step();local cached=e.complete(#e.requests,6.5);e.step(250)
check(cached.valid and not cached.played,'prefetched one-shot is retained, never silently played')
state.stop=true;state.sequence=8;e.receive('LOD_MusicState',util.TableToJSON(state));check(not cached.valid,'failure/reset releases prefetched media')
print('MUSIC_TRANSITIONS PASS '..e.checks)
