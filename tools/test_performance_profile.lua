-- Execute the production opt-in observer across separate client/server realms.
-- Exact clocks and native boundaries are doubled; no native FPS/GPU claim.
local root='gamemodes/legend_of_deborah/gamemode/lod/'
local auditPath=arg and arg[1]=='--source' and assert(arg[2]) or root..'sh_runtime_audit.lua'
local noop=function() end
local now=100;SysTime=function() return now end;RealTime=SysTime;CurTime=SysTime
function math.Clamp(n,a,b) return math.max(a,math.min(b,n)) end
function IsValid(e) return type(e)=='table' and e.valid~=false end
local realms={client={UI={},WallVisualsClient={world={},models={},batchStats={status='native'}}},
    server={RunManager={State={CampaignSeed=17,Graph={LevelSeed=23}}}}}
local hooks={client={},server={}};local entities={client={},server={}}
local files={client={},server={}};local receivers={client={},server={}}
local deferred={client={},server={}};local writes=0;local scans=0
local function side() return CLIENT and 'client' or 'server' end
local function realm(name,fn)
    CLIENT=name=='client';SERVER=not CLIENT;LOD=realms[name]
    return fn()
end
hook={Add=function(event,id,fn)
    local h=hooks[side()];h[event]=h[event] or {};h[event][id]=fn
end,Remove=function(event,id)
    local h=hooks[side()];if h[event] then h[event][id]=nil end
end,GetTable=function() return hooks[side()] end}
timer={Create=noop,Simple=function(_,fn) local t=deferred[side()];t[#t+1]=fn end}
concommand={Add=noop};game={GetMap=function() return 'gm_flatgrass' end,SinglePlayer=function() return true end}
ScrW=function() return 1280 end;ScrH=function() return 800 end
GetConVar=function(name) return {GetBool=function() return name=='lod_reduced_effects' end,
    GetString=function() return (name=='lod_reduced_effects' or name=='lod_map_scale' or name=='lod_map_opacity') and '1' or '0' end} end
ents={GetCount=function() return #entities[side()] end,GetAll=function() scans=scans+1;return entities[side()] end}
local paths={'gamemodes/legend_of_deborah/entities/entities/lod_hostile/cl_init.lua',
    'gamemodes/legend_of_deborah/entities/entities/lod_static_box/cl_init.lua',
    'gamemodes/legend_of_deborah/entities/entities/lod_static_box/shared.lua',
    root..'cl_textured_box.lua',root..'cl_wall_visuals.lua',root..'cl_wall_batch.lua',
    root..'cl_container_section_recolor.lua',root..'cl_container_wayfinding_projection.lua',
    root..'cl_container_branding.lua',root..'cl_ui_theme.lua',root..'cl_monster_identity.lua',
    root..'cl_combat_roll_feed_semantics.lua',root..'sh_player_options.lua',root..'cl_player_options.lua',
    root..'cl_minimap.lua',root..'cl_minimap_magic_quadrants.lua',root..'sh_runtime_audit.lua'}
local manifest={};for _,path in ipairs(paths) do manifest[#manifest+1]=string.rep('a',64)..'  '..path end
for _,f in pairs(files) do
    f.dev_build='profile-test clean';f['legend_of_deborah/dev_population_sources.txt']=table.concat(manifest,'\n')
end
file={CreateDir=noop,Read=function(path,mode) return mode=='GAME' and 'exact' or files[side()][path] end,
    Write=function(path,text) writes=writes+1;files[side()][path]=text end}
local function copy(v)
    if type(v)~='table' then return v end
    local c={};for k,item in pairs(v) do c[k]=copy(item) end;return c
end
local codec={};local serial=0;local oversized=false;local oversizedBytes=60001
util={SHA256=function() return string.rep('a',64) end,AddNetworkString=function(channel)
    assert(channel=='LOD_PerformanceProfile')
end,TableToJSON=function(v)
    if oversized and v.rows then
        serial=serial+1;local text='{"test_payload":'..serial..',"padding":"'..string.rep('x',oversizedBytes)..'"}'
        codec[text]=copy(v);return text
    end
    serial=serial+1;local text='{"test_payload":'..serial..'}';codec[text]=copy(v);return text
end,JSONToTable=function(text)
    if text=='throw-json' then error('bad codec') end
    return codec[text] and copy(codec[text])
end}
local queue={client={},server={}};local message,incoming
net={Receive=function(channel,fn) receivers[side()][channel]=fn end,
    Start=function(channel) message={channel=channel,bits=0,values={}} end,
    WriteBool=function(v) message.bits=message.bits+1;message.values[#message.values+1]=v end,
    WriteUInt=function(v,bits) message.bits=message.bits+bits;message.values[#message.values+1]=v end,
    WriteData=function(text,size) assert(#text==size);message.bits=message.bits+size*8;message.values[#message.values+1]=text end,
    SendToServer=function() queue.server[#queue.server+1]=message;message=nil end,
    Send=function(owner) message.owner=owner;queue.client[#queue.client+1]=message;message=nil end,
    ReadBool=function() local v=table.remove(incoming.values,1);assert(type(v)=='boolean');return v end,
    ReadUInt=function() return table.remove(incoming.values,1) end,
    ReadData=function() return table.remove(incoming.values,1) end}
local hero={valid=true,admin=true};function hero:IsAdmin() return self.admin end
function hero:Alive() return true end;function hero:GetNW2Bool() return true end
LocalPlayer=function() return hero end
local function fire(name,event,...)
    local args=table.pack(...)
    return realm(name,function()
        local callbacks={};for _,fn in pairs(hooks[name][event] or {}) do callbacks[#callbacks+1]=fn end
        for _,fn in ipairs(callbacks) do fn(table.unpack(args,1,args.n)) end
    end)
end
local function deliver(name,owner)
    local packets=queue[name];queue[name]={}
    for _,packet in ipairs(packets) do
        incoming=copy(packet)
        realm(name,function() receivers[name][packet.channel](packet.bits,owner or packet.owner or hero) end)
    end
end
local function entity(class,methods,id)
    local fields={LODArchetypeId=id}
    local e=setmetatable({valid=true},{__index=function(_,key) return fields[key] or methods[key] end,
        __newindex=function(_,key,value) fields[key]=value end})
    function methods:GetClass() return class end;function methods:GetTable() return fields end
    return e,fields
end
local S=realms.server
local nativeCalls=0
S.MazeNavigator={Distance=function(_,g,a,b) assert(g==23 and a==1 and b==2);now=now+.002;return 2 end,
    FindHostilePath=function() now=now+.004;return nil,'unreachable',nil end}
S.FactionManager={BestTarget=function() now=now+.003;return hero,2 end}
S.EntrySafety={Context=function() now=now+.001;return {BuildReady=false} end}
S.EnemyRoster={TickCloseDefense=function() now=now+.001;return false end}
S.WatcherScanEscapeHandoff={BehaviourTick=function(e) assert(e.LODArchetypeId=='watcher');now=now+.007;return true end}
local tick=function(e,...)
    nativeCalls=nativeCalls+1;assert(e.LODArchetypeId=='soldier');assert(select('#',...)==3)
    assert(LOD.MazeNavigator:Distance(23,1,2)==2);assert(LOD.FactionManager:BestTarget()==hero)
    now=now+.005;return false,nil,'kept',nil
end
local soldier,fields=entity('lod_hostile',{_BehaviourTick=tick,BodyUpdate=function() now=now+.001 end},'soldier')
local watcher,wfields=entity('lod_hostile',{_BehaviourTick=S.WatcherScanEscapeHandoff.BehaviourTick},'watcher')
local watcherTick=S.WatcherScanEscapeHandoff.BehaviourTick
local function read(path) local f=assert(io.open(path));local s=f:read('*a');f:close();return s end
local entry=assert(read(root..'sv_entry_safety.lua'):match('(local function beforeAI.-\nend\nfunction S:BeforeAI.-\nend)'))
assert(load('local S,alive=...\n'..entry,'@production-entry-profile'))(S.EntrySafety,function() return true end)
local entryBinding=S.EntrySafety.BeforeAI
local loop=assert(read(root..'sv_watcher_instance_dispatch.lua'):match('(local function watcherRunLoop.-\nend)'))
local watcherLoop=assert(load('local markWatcherBound,bindFinalMethods,unifiedWatcherTick,stopWatcherSafely=...\n'..loop..'\nreturn watcherRunLoop','@production-watcher-profile'))(noop,noop,function() return S.WatcherScanEscapeHandoff.BehaviourTick end,noop)
local other=entity('prop_physics',{Think=function() error('foreign entity') end})
entities.server={soldier,watcher,other}
local draw=function() now=now+.004;return nil,'draw',nil end
local box,bfields=entity('lod_static_box',{Draw=draw,Think=function() now=now+.0005 end})
entities.client={box}
local think=function(a,b,c) assert(a=='arg' and b==nil and c==7);now=now+.006;return false,nil,7,nil end
realm('server',function() hook.Add('TestEvent','LOD_ProfileReturn',think);hook.Add('TestEvent','ForeignAddon',noop) end)
realm('server',function() dofile(auditPath) end)
realm('client',function() dofile(auditPath) end)
local A=realms.client.RuntimeAudit;local B=realms.server.RuntimeAudit
receivers.server.LOD_PopulationSnapshot=noop
assert(scans==0 and writes==0 and not A.CPUProfile and not B.CPUProfile)
assert(not hooks.client.PreRender and not hooks.server.OnEntityCreated,'idle instrumentation')
-- Default recording retains zero wrappers/scans. Explicit mode begins only
-- after renderer preparation and warmup, then sends one bounded server request.
realm('client',function() A:StartPerformanceCapture(30) end);fire('client','PreRender');now=now+3;fire('client','PreRender')
assert(scans==0 and not A.CPUProfile);realm('client',function() A:StopPerformanceCapture('manual') end)
deliver('server')
realm('client',function() A:StartPerformanceCapture(30,true) end);fire('client','PreRender')
assert(not A.CPUProfile);now=now+3;fire('client','PreRender')
assert(A.CPUProfile and scans==1 and #queue.server==2) -- population + profile
-- The population request has its existing independently tested receiver.
deliver('server')
assert(B.CPUProfile and scans==2 and soldier._BehaviourTick~=tick)
assert(watcher._BehaviourTick==watcherTick and wfields._BehaviourTick==nil,'Watcher final instance identity changed')
assert(S.EntrySafety.BeforeAI==entryBinding and S.WatcherScanEscapeHandoff.BehaviourTick==watcherTick,'timing invalidated authority identity')
local v=realm('server',function() return table.pack(hooks.server.TestEvent.LOD_ProfileReturn('arg',nil,7)) end)
assert(v.n==4 and v[1]==false and v[2]==nil and v[3]==7 and v[4]==nil,'hook returns changed')
v=realm('server',function() return table.pack(soldier:_BehaviourTick('a',nil,'c')) end)
assert(v.n==4 and v[1]==false and v[3]=='kept' and v[4]==nil and nativeCalls==1,'native callback contract changed')
realm('server',function()
    local co=coroutine.create(function() watcherLoop(watcher) end)
    local ok,err=coroutine.resume(co);assert(ok,err);assert(coroutine.status(co)=='suspended')
end)
realm('client',function() v=table.pack(box:Draw()) end);assert(v.n==3 and v[2]=='draw')
fire('client','PreRender');now=now+.02;fire('client','PostRender')
-- New native incarnations bind after Initialize; delayed work becomes inert
-- after stop. A newer authority installed during capture must survive restore.
local new,raw=entity('lod_hostile',{_BehaviourTick=tick},'soldier')
fire('server','OnEntityCreated',new);realm('server',function() for _,fn in ipairs(deferred.server) do fn() end end)
deferred.server={}
assert(raw._BehaviourTick);realm('server',function() new:_BehaviourTick('a',nil,'c') end)
-- A removed entity is not retained by the observer's callback restorations.
local retired=setmetatable({},{__mode='k'})
do
    local transient,transientFields=entity('lod_hostile',{_BehaviourTick=tick},'soldier')
    retired[transientFields]=true
    fire('server','OnEntityCreated',transient)
    realm('server',function() for _,fn in ipairs(deferred.server) do fn() end end)
    assert(transientFields._BehaviourTick)
end
deferred.server={};collectgarbage('collect');collectgarbage('collect')
assert(not next(retired),'observer retained a removed native owner')
local replacement=function() return 'new authority' end;fields.BodyUpdate=replacement
now=now+5;fire('server','Think');assert(#queue.client==1);deliver('client')
assert(A.PerformanceCapture.server_profile.reason=='progress','shutdown-survivable snapshot missing')
local function row(out,name)
    for _,r in ipairs(out.rows) do if r.name==name then return r end end
    error('missing profile row: '..name)
end
local r=row(A.PerformanceCapture.server_profile,'entity/lod_hostile/soldier._BehaviourTick')
assert(r.calls==2 and r.completed==2 and math.abs(r.milliseconds-20)<1e-7 and math.abs(r.maximum_ms-10)<1e-7)
assert(row(A.PerformanceCapture.server_profile,'service/WatcherDirectBehaviour').calls==1)
assert(row(A.PerformanceCapture.server_profile,'service/EntrySafety.BeforeAI').calls==1)
-- An immediate shutdown preserves partial server evidence. Its next-tick final
-- reply merges into the SAME frame file; exact source/settings/windows survive.
local out=realm('client',function() return A:StopPerformanceCapture('shutdown') end)
assert(out.cpu_profile.server_status=='partial' and out.cpu_profile.server.reason=='progress')
assert(bfields.Draw==nil and box.Draw==draw and not A.CPUProfile)
local partial=out.cpu_profile.server;deliver('server');deliver('client')
assert(out.cpu_profile.server_status=='received' and out.cpu_profile.server.reason=='client-stop')
assert(not B.CPUProfile and fields._BehaviourTick==nil and raw._BehaviourTick==nil and soldier._BehaviourTick==tick)
assert(fields.BodyUpdate==replacement and hooks.server.TestEvent.LOD_ProfileReturn==think,'restoration clobbered newer authority')
assert(out.source.verified and out.start_configuration.width==1280 and out.reason=='shutdown')
assert(row(out.cpu_profile.client,'entity/lod_static_box.Draw').calls==1)
assert(row(out.cpu_profile.client,'phase/PreRender-to-PostRender').completed==1)
assert(files.client['legend_of_deborah/performance_client_latest.txt']:find('reason=shutdown',1,true))
-- Stale reports, invalid payloads and a partial reply after the final reply do
-- not rewrite saved state. No one can start/stop another admin's server lease.
local before=writes
local function reply(data)
    incoming={values={#data,data}};realm('client',function() receivers.client.LOD_PerformanceProfile() end)
end
reply(util.TableToJSON(partial));assert(writes==before)
reply('throw-json');reply('not-json');incoming={values={60001}};realm('client',function() receivers.client.LOD_PerformanceProfile() end)
assert(writes==before)
local function request(owner,start,token,duration,length)
    incoming={values={start,token,duration}}
    realm('server',function() receivers.server.LOD_PerformanceProfile(length or 42,owner) end)
end
local guest={valid=true,IsAdmin=function() return false end}
request(guest,true,99,30);request(hero,true,99,301);request(hero,true,0,30);request(hero,true,99,30,41)
assert(not B.CPUProfile)
request(hero,true,99,30,48);assert(B.CPUProfile)
local admin2={valid=true,IsAdmin=function() return true end}
request(admin2,false,99,30);request(hero,false,98,30);assert(B.CPUProfile)
request(admin2,true,100,30);assert(B.CPUProfile)
now=now+34;fire('server','Think');assert(not B.CPUProfile);queue.client={}
-- Errors propagate as originally thrown, counts expose incomplete calls, and
-- reload/map cleanup/deferred work always release instrumentation.
local errorHook=function() error('original failure',0) end
realm('server',function() hook.Add('Failure','LOD_ProfileFailure',errorHook);B:StartCPUProfile() end)
local ok,err=realm('server',function() return pcall(hooks.server.Failure.LOD_ProfileFailure) end)
assert(not ok and err=='original failure','observer changed callback error')
local failed=realm('server',function() return B:StopCPUProfile('error-test') end)
assert(row(failed,'hook/Failure/LOD_ProfileFailure').calls==1 and row(failed,'hook/Failure/LOD_ProfileFailure').completed==0)
assert(hooks.server.Failure.LOD_ProfileFailure==errorHook)
request(hero,true,101,30);oversized=true;now=now+5;fire('server','Think');oversized=false
local packet=table.remove(queue.client);assert(codec[packet.values[2]].error=='profile exceeds transport limit')
fire('server','PostCleanupMap');assert(not B.CPUProfile);queue.client={}
-- The native capture exceeded raw JSON transport. Exercise the production
-- compressed path through binary net data, progress/final merging and every
-- original row/timing, while keeping the old small JSON wire format unchanged.
local compressed={};local packedSerial=0;local packMode
util.Compress=function(text)
    if packMode=='throw' then error('native compression failed') end
    if packMode=='oversize' then return string.rep('x',60000) end
    if packMode=='empty' then return '' end
    packedSerial=packedSerial+1
    local packed=string.pack('<I8',#text)..'native-lzma-boundary\0'..packedSerial
    compressed[packed]=text;return packed
end
util.Decompress=function(packed,limit)
    assert(limit==262144,'native decompression was not bounded')
    local text=compressed[packed]
    return text and #text<=limit and text or nil
end
realm('client',function() A:StartPerformanceCapture(30,true) end);fire('client','PreRender');now=now+3;fire('client','PreRender')
deliver('server');assert(B.CPUProfile)
realm('server',function() soldier:_BehaviourTick('a',nil,'c') end)
oversized=true;now=now+5;fire('server','Think')
local binary=queue.client[1].values[2]
assert(binary:byte(1)==0 and #binary<60000 and #compressed[binary:sub(2)]>60000,'large report was not compressed')
deliver('client')
local received=A.PerformanceCapture.server_profile
assert(received.reason=='progress' and not received.error)
local timed=row(received,'entity/lod_hostile/soldier._BehaviourTick')
assert(timed.calls==1 and math.abs(timed.milliseconds-10)<1e-7,'compression dropped exact timings')
local totalRows=#received.rows;assert(totalRows>5)
-- Invalid codecs/data cannot overwrite the accepted progress snapshot.
reply('\0not-native-lzma');assert(A.PerformanceCapture.server_profile==received)
local unpack=util.Decompress
util.Decompress=function() error('native decode failed') end
reply(binary);assert(A.PerformanceCapture.server_profile==received)
util.Decompress=function() return string.rep('x',262145) end
reply(binary);assert(A.PerformanceCapture.server_profile==received)
util.Decompress=unpack
oversizedBytes=262145;now=now+5;fire('server','Think');oversizedBytes=60001
local tooLarge=table.remove(queue.client);assert(codec[tooLarge.values[2]].error=='profile exceeds transport limit')
for _,mode in ipairs({'throw','oversize','empty'}) do
 packMode=mode;now=now+5;fire('server','Think')
 local failure=table.remove(queue.client);assert(codec[failure.values[2]].error=='profile exceeds transport limit')
end
packMode=nil
local finished=realm('client',function() return A:StopPerformanceCapture('compression-test') end)
deliver('server');deliver('client');oversized=false
assert(finished.cpu_profile.server_status=='received' and #finished.cpu_profile.server.rows==totalRows)
assert(row(finished.cpu_profile.server,'entity/lod_hostile/soldier._BehaviourTick').milliseconds==timed.milliseconds)
assert(not A.CPUProfile and not B.CPUProfile,'compressed final report leaked profiler bindings')
request(hero,true,102,30);realm('server',function() dofile(auditPath) end)
assert(not B.CPUProfile and not hooks.server.Think.LOD_CPUProfileDeadline,'reload leaked server lease')
local refreshed=table.remove(queue.client);assert(codec[refreshed.values[2]].reason=='lua-refresh','reload lost final server evidence')
realm('client',function() A:StartPerformanceCapture(30,true) end);fire('client','PreRender');now=now+3;fire('client','PreRender')
local late=entity('lod_static_box',{Draw=draw});fire('client','OnEntityCreated',late)
local oldSaved=A.LastPerformanceCapture
reply(util.TableToJSON({realm='server',token=oldSaved.cpu_profile.token,reason='client-stop'}));assert(A.LastPerformanceCapture==oldSaved)
fire('client','PostCleanupMap');assert(not A.PerformanceCapture and not A.CPUProfile)
realm('client',function() for _,fn in ipairs(deferred.client) do fn() end end)
assert(late:GetTable().Draw==nil,'retired deferred bind changed an entity')
realm('client',function() A:StartPerformanceCapture(30,true) end);fire('client','PreRender');now=now+3;fire('client','PreRender')
realm('client',function() dofile(auditPath) end)
assert(not A.CPUProfile and not A.PerformanceCapture and A.LastPerformanceCapture.reason=='lua-refresh')
assert(A.LastPerformanceCapture.cpu_profile.client.reason=='lua-refresh','reload lost final client evidence')
print('PERFORMANCE_PROFILE_PASS: opt-in/post-warmup; client/server real observer; exact inclusive timings; vararg/nil/self/error preservation; existing/new native instances; Watcher direct service; weak ownership and guarded restores; partial/final same-file transport; complete compressed reports and bounded malformed/oversized codecs; stale/admin/lease bounds; finite deadline; cleanup/reload/shutdown; no native FPS/GPU measurement')
