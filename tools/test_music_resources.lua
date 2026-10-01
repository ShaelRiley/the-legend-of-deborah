local e=dofile('tools/music_test_fixture.lua');local check=e.check
CLIENT=true;dofile('gamemodes/legend_of_deborah/gamemode/lod/cl_music_native.lua');dofile('gamemodes/legend_of_deborah/gamemode/lod/cl_music.lua')
local D=LOD.MusicDirector;local M=LOD.Music;local N=LOD.MusicNative
e.set('lod_music_enabled',1);D.ServerOn=true;D.Catalog=e.catalog()
local p=M.Plan(e.catalog(),{set='all'},17,'run:1',4,1);D.Plans[p.id]=p
D.Current={sequence=1,epoch=1,plan=p.id,role='T0',targets={{block=p.floors[1],weight=1}}}
D:Tick();e.panel.functions['lodms2.ready']('native');D:Sync()
N:SetMix('alpha',1,0);check(N.Ready,'finite native bank initialized')
local generated=table.Count(e.generated)
for i=1,200 do
 N:Note({lane='alpha',inst=i%9,pitch=i%9>=5 and 45 or 62,velocity=90,duration=.2})
 check(table.Count(N.Voices)<=25,'native polyphony plus bridge remains bounded')
end
check(table.Count(e.generated)==generated,'note playback never creates a fresh sample identifier')
N:SetMix('unknown',1,0);check(table.Count(e.generated)==generated,'unknown lane cannot grow native bank')
e.frame=.12;for i=1,100 do e.now=e.now+.1;D:Tick() end
check(D.Quality==0 and D.Ready,'frame pressure reduces orchestration without silencing cached score')
e.set('lod_music_volume',0);check(not next(N.Voices) and not next(N.Queue) and not D.Ready,'zero volume releases both backends')
check(D.DemandOn==false,'zero volume suspends server state demand')
e.set('lod_music_volume',.55);check(D.DemandOn,'restored volume resubscribes')
D.ServerOn=true
local wire=table.Copy(p);wire.id='chunked-plan';local bytes=util.TableToJSON(wire)
local total=math.ceil(#bytes/M.Limits.planChunk)
for part=1,total do
 local chunk=bytes:sub((part-1)*M.Limits.planChunk+1,part*M.Limits.planChunk)
 e.receive('LOD_MusicPlan',wire.id,part,total,#chunk,chunk)
 if part<total then check(not D.Plans[wire.id],'partial plan never installed') end
end
check(D.Plans[wire.id],'complete metadata plan installed')
e.receive('LOD_MusicPlan','bad',1,1,2000,'bad');check(not D.Plans.bad,'oversized metadata rejected')
print('MUSIC_RESOURCES PASS '..e.checks)
