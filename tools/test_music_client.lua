local e=dofile('tools/music_test_fixture.lua');local check=e.check
CLIENT=true;dofile('gamemodes/legend_of_deborah/gamemode/lod/cl_music_native.lua');dofile('gamemodes/legend_of_deborah/gamemode/lod/cl_music.lua')
local D=LOD.MusicDirector;local M=LOD.Music;e.set('lod_music_enabled',1);D.ServerOn=true
local p=M.Plan(e.catalog(),{set='all'},17,'run:1',4,1);D.Plans[p.id]=p
D.Current={sequence=1,epoch=1,plan=p.id,role='INTERLUDE',staged=true,targets={{block=p.floors[1],weight=1}},remaining=-1}
D:Tick();local panel=e.panel;check(panel.visible and panel.allowLua==false,'invisible painting retains JS processing without arbitrary Lua')
D.Error='old startup failure';panel.functions['lodms2.ready']('surge-rendered',e.now);D:Sync()
check(D.Ready and D.Synced,'actual local phrase metadata and current state handed to renderer')
check(table.Count(D.Payloads)==1,'one current arrangement loaded')
check(not D.Error,'valid phrases accepted')
local calls=#panel.calls;D:Sync();check(#panel.calls==calls,'unchanged state adds no JS work')
D:Announce(p.floors[1]);local n=#e.announced
D.Current.role='T3';D.Synced=nil;D:Sync();D:Announce(p.floors[1]);check(#e.announced==n,'tension change does not repeat block name')
D.Current.targets={{block=p.floors[1],weight=.5},{block=p.floors[2],weight=.5}};D.Synced=nil;D:Sync()
D:Announce(p.floors[2]);check(#e.announced==n+1,'incoming stairs block announced once')
D:Announce('unassigned');check(#e.announced==n+1,'unknown callback cannot announce a block')
local oldReady=panel.functions['lodms2.ready'];e.set('lod_music',0)
check(not D.Ready and not panel.valid and not next(D.Payloads),'Off destroys renderer and releases metadata caches')
oldReady('surge-rendered',e.now);check(not D.Ready,'stale browser callback cannot resurrect playback')
local decoded=0;util.Decompress=function() decoded=decoded+1 end
e.receive('LOD_MusicPlan','ignored',1,1,4,'data');check(decoded==0,'Off skips plan decoding')
print('MUSIC_CLIENT PASS '..e.checks)
