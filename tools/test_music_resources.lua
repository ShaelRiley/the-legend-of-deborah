-- Production native phrase pool against an asynchronous audio boundary.
local e=dofile('tools/music_test_fixture.lua');local check=e.check
CLIENT=true;dofile('gamemodes/legend_of_deborah/gamemode/lod/cl_music_native.lua');dofile('gamemodes/legend_of_deborah/gamemode/lod/cl_music.lua')
local D,M,N=LOD.MusicDirector,LOD.Music,LOD.MusicNative
local catalog=e.catalog();local bank={bpm=130,clips={},bridge={duration=4}}
for _,a in pairs(catalog.assets) do for _,c in ipairs(a.clips) do bank.clips[c.id]={beats=c.beats,duration=c.beats*60/130+.55} end end
local results={};local serial=0
local function setup()
 N:Configure(catalog,bank,function(token,played) results[token]=played end)
 D.AudibleTargets={{block='alpha',weight=.5,asset='delta-t0'},{block='beta',weight=.5,asset='delta-t0'}}
 N:SyncClock(e.now);N:SetMix('alpha',math.sqrt(.5));N:SetMix('beta',math.sqrt(.5));N:SetVolume(.55)
end
local function prepare(lane,delay,clip)
 serial=serial+1;local token=tostring(serial);N:Prepare(token,lane,clip or 'delta_t0_000',delay,e.now+delay);return token
end
setup();local token=prepare('alpha',1);local channel=e.channels[#e.channels]
check(not channel.played,'asynchronous preparation never autoplays')
e.now=e.now+.99;N:Tick();check(not channel.played,'early readiness waits for the shared boundary')
e.now=e.now+.01;N:Tick();check(channel.played==e.now and results[token]==true,'one intended phrase starts on time')
N:Tick();check(e.plays==1,'repeated frame cannot duplicate phrase start')
check(N:Count()<=3 and N:Bytes()<32*1024*1024,'lazy playback is bounded')
local obsolete=e.now+.5;e.now=e.now+2;local oldStarts=e.plays
N:Prepare('99999','alpha','delta_t0_000',.5,obsolete)
check(results['99999']==false and e.plays==oldStarts,'delayed control-message delivery retains its expired absolute deadline')
e.now=e.now+.2;N:Tick();check(channel.volume>0,'floor weight controls phrase gain')
local starts=e.plays;N:Prepare('bad','alpha','../../bad',0);N:Prepare('55','alpha','missing',0);N:Prepare('56','unknown','delta_t0_000',0)
check(e.plays==starts and N:Count()<=3,'unsafe/unknown IDs never open audio')
-- Native deadlines independently reject late callback and frame-stall starts.
for _,stall in ipairs({.1,.3,1,4,15}) do
 for _,change in ipairs({'none','role','reversal'}) do
  setup();e.deferOpens=true;local before=e.plays;local a=prepare('alpha',.5);local b=prepare('beta',.5)
  if change=='role' then D.AudibleTargets[1].asset='delta-t2';N:Cancel(a)
  elseif change=='reversal' then N:SetMix('alpha',.9);N:SetMix('beta',.1) end
  e.now=e.now+.5+stall;e.completeOpens();N:Tick()
  check(e.plays==before,'stall cannot trigger an overdue phrase cascade: '..stall..' '..change)
  check(results[b]==false,'overdue native preparation is discarded')
  check(table.Count(N.Opens)==0,'late callback disposes its preload')
  D.AudibleTargets[1].asset='delta-t0';e.deferOpens=false
  local fresh=prepare('alpha',1);e.now=e.now+1;N:Tick()
  check(results[fresh]==true,'recovery accepts only a fresh future boundary')
  check(N:Count()<=8 and table.Count(N.Opens)<=2,'stall recovery retains hard pool bounds')
 end
end
-- Cancellation reserves uncancellable opens across repeated Off/On cycles.
setup();e.deferOpens=true;prepare('alpha',1);prepare('beta',1)
for _=1,100 do
 N:Stop();setup();prepare('alpha',1);prepare('beta',1)
 check(table.Count(N.Opens)==2 and N:Count()==2,'Off/On cannot accumulate asynchronous opens')
 check(N:Bytes()<32*1024*1024,'cancelled opens still count toward PCM admission')
end
N:Stop();local before=e.plays;e.completeOpens()
check(e.plays==before and N:Count()==0 and N:Bytes()==0,'stale callbacks stop without starting and release all resources')
for _,c in ipairs(e.channels) do check(not c.valid,'Off releases every opened channel') end
e.deferOpens=false
-- Continuous phrases retain one natural tail, not a permanent clip channel.
setup();local interval=8*60/130
for _=1,200 do
 prepare('alpha',1);prepare('beta',1);e.now=e.now+1;N:Tick();e.now=e.now+.08;N:Tick()
 check(N:Count()<=6,'two lanes retain current/tail/upcoming bounds')
 N:SetMix('alpha',.2);N:SetMix('beta',.95);N:SetMix('alpha',.95);N:SetMix('beta',.2)
 e.now=e.now+interval-1.08;N:Tick()
 check(table.Count(N.Lanes)==2 and N:Bytes()<32*1024*1024,'stair reversal reuses floor lanes and bounded PCM')
end
-- The bridge cannot disguise a persistent failure indefinitely.
setup();e.now=e.now+.01;N:Tick();e.now=e.now+.2;N:Tick()
check(N.Bridge and N:Count()==1,'one quiet local bridge covers a real gap')
for _=1,50 do e.now=e.now+.01;N:Tick();check(N:Count()==1,'bridge never accumulates') end
e.now=e.now+8;N:Tick();check(N.Errors==3 and not N.Bridge,'persistent gap stops bridge and reports failure')
N:Stop();setup();N:SetVolume(0);N:Tick();check(not N.Ready and N:Count()==0,'zero volume tears down playback')
-- Independent admission limits also hold for malformed internal preparations.
setup();local meta=bank.clips.delta_t0_000
local function raw_record()
 serial=serial+1;return {token=tostring(serial),lane='alpha',clip='delta_t0_000',path='sound/lod/ms2_surge/delta_t0_000.ogg',
  due=e.now+1,musical=8*60/130,duration=meta.duration,bytes=math.ceil(meta.duration*44100)*8}
end
for _=1,8 do check(N:Open(raw_record()),'hard pool admits its eight slots') end
check(not N:Open(raw_record()) and N:Count()==8,'ninth channel cannot bypass the hard ceiling')
setup();local oversized=raw_record();oversized.bytes=32*1024*1024+1
check(not N:Open(oversized) and N:Count()==0,'oversized PCM admission is rejected before opening')
local recovery=prepare('alpha',1);N.Error='old open failure';e.now=e.now+1;N:Tick()
check(results[recovery] and not N.Error,'successful playback clears a recovered diagnostic')
e.now=e.now+.1;N:Tick();N:SetMix('alpha',.2);local writes=e.volumeWrites
for _=1,1000 do e.now=e.now+.001;N:Tick() end
check(e.volumeWrites-writes<=31,'gain interpolation does not write to native audio every frame')
-- Client lifecycle and existing chunked-plan admission still exercise production.
e.set('lod_music_enabled',1);D.ServerOn=true;D.Catalog=catalog
local p=M.Plan(catalog,{set='all'},17,'run:1',4,1);D.Plans[p.id]=p
D.Current={sequence=1,epoch=1,plan=p.id,role='T0',targets={{block=p.floors[1],weight=1}}}
D:Tick();e.panel.functions['lodms2.ready']('surge-rendered',e.now);D:Sync()
check(D.Backend=='surge-rendered' and N.Ready,'client identifies the actual backend')
e.frame=.12;for _=1,50 do e.now=e.now+.1;D:Tick() end
check(D.Quality==0,'frame pressure retains cheap orchestration control')
e.set('lod_music_volume',0);check(N:Count()==0 and not D.Ready and D.DemandOn==false,'zero volume disposes channels and suspends demand')
e.set('lod_music_volume',.55);check(D.DemandOn,'restored volume resubscribes')
D.ServerOn=true
local wire=table.Copy(p);wire.id='chunked-plan';local bytes=util.TableToJSON(wire);local total=math.ceil(#bytes/M.Limits.planChunk)
for part=1,total do
 local chunk=bytes:sub((part-1)*M.Limits.planChunk+1,part*M.Limits.planChunk)
 e.receive('LOD_MusicPlan',wire.id,part,total,#chunk,chunk)
 if part<total then check(not D.Plans[wire.id],'partial plan never installed') end
end
check(D.Plans[wire.id],'complete metadata plan installed')
e.receive('LOD_MusicPlan','bad',1,1,2000,'bad');check(not D.Plans.bad,'oversized metadata rejected')
print('MUSIC_RESOURCES PASS '..e.checks..'; 15 native stall cases; peak '..N.Peak..' channels')
