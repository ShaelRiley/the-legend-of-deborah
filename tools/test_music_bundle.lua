-- Reproduce nested GMod include resolution and exercise the real startup seams.
local e=dofile('tools/music_test_fixture.lua');local check=e.check
local root='legend_of_deborah/gamemode/lod/ms2/'
local ok=pcall(include,'lod/ms2/catalog.lua')
check(not ok,'old root-relative path fails from the nested music module')
for _,directory in ipairs({'legend_of_deborah/gamemode/','legend_of_deborah/gamemode/lod/',''}) do
 e.luaDirectory=directory
 check(LOD.Music.LoadBundled(),'catalog loads during startup and rootless callbacks')
end
e.luaDirectory='legend_of_deborah/gamemode/lod/'
SERVER=true;CLIENT=false
LOD.RunManager={State={},GetPlayerState=function() return {} end}
player={GetAll=function() return {} end}
dofile('gamemodes/legend_of_deborah/gamemode/lod/sv_music.lua')
check(LOD.MusicDirector.Catalog,'server startup admits the bundled catalog')
CLIENT=true;SERVER=false
e.cacheOnly=true
check(not file.Exists(root..'catalog.lua','LUA'),'remote client has no loose catalog file')
dofile('gamemodes/legend_of_deborah/gamemode/lod/cl_music_native.lua')
dofile('gamemodes/legend_of_deborah/gamemode/lod/cl_music.lua')
local D=LOD.MusicDirector
e.set('lod_music_enabled',1);D.ServerOn=true
local plan=assert(LOD.Music.Plan(e.catalog(),{set='all'},17,'bundle-run',4,1))
D.Plans[plan.id]=plan
D.Current={sequence=1,epoch=1,plan=plan.id,role='T0',staged=true,targets={{block=plan.floors[1],weight=1}}}
D:Tick()
check(e.panel and e.panel.html:find('MS2',1,true),'client loads the actual phrase-control engine')
e.panel.functions['lodms2.ready']('surge-rendered',e.now);D:Sync()
check(D.Ready and D.Synced and next(D.Payloads),'client hands phrase metadata and state to playback')
e.realBundle=true
local files=assert(LOD.Music.IncludeBundled('files.lua'))
for _,name in ipairs(files) do
 local raw=assert(LOD.Music.IncludeBundled(name))
 check(type(raw)=='string' and #raw>0,'real distributed score file loads: '..name)
end
e.realBundle=false
SERVER=true;CLIENT=false
local missing=root..'catalog.lua';e.missingLua[missing]=true
local calls=#e.includeCalls
local catalog,err=LOD.Music.LoadBundled()
check(not catalog and err:find(missing,1,true),'missing mount reports its exact virtual path')
check(#e.includeCalls==calls,'missing catalog skips the noisy engine include')
e.missingLua[missing]=nil
check(LOD.Music.LoadBundled(),'a complete mount can recover')
print('MUSIC_BUNDLE PASS '..e.checks)
