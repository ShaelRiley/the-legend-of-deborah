-- Existing server census -> bounded opt-in client mirror. Native net/DATA/JSON
-- boundaries are doubled; no alternate population implementation or native FPS.
CLIENT=false;SERVER=true
local root='gamemodes/legend_of_deborah/gamemode/lod/'
local noop=function() end
local now=100;CurTime=function() return now end;SysTime=CurTime;RealTime=CurTime
function IsValid(v) return type(v)=='table' and v.valid~=false end
function math.Clamp(n,a,b) return math.max(a,math.min(b,n)) end
local serverLOD={RunManager={State={CampaignSeed=17,Graph={LevelSeed=23},
    GatesOpen={true,false,false,false}}},EncounterDirector={}}
local censusCalls=0
serverLOD.EncounterDirector.PopulationSnapshot=function()
    censusCalls=censusCalls+1
    return {ready=true,revision='b28',live=64,roaming=20,developerDense=true,
        sectors={{resident=12,roaming=5},{resident=12,roaming=5}}}
end
serverLOD.EntrySafety={Snapshot=function()
    local cells={};for i=1,500 do cells[i]=i end
    return {ready=true,version='entry-test',eventSerial=8,cells=cells,
        bindings={ai=true,damage=true,spawn=true},stats={exits=1,contacts=3},
        heroes={{entity=1,depth=23,completed=true,nearby=8,engaged=3,sources={resident=3}}}}
end}
local clientLOD={UI={},WallVisualsClient={world={},models={},batchStats={status='ready'}}}
local function realm(name,fn)
    CLIENT=name=='client';SERVER=not CLIENT;LOD=CLIENT and clientLOD or serverLOD
    return fn()
end
local files={server={},client={}};local writes={server=0,client=0};local hashes={server=0,client=0}
local drop={server=false,client=false};local function side() return CLIENT and 'client' or 'server' end
local function readBytes(path)
    local f=assert(io.open(path,'rb'));local bytes=f:read('*a');f:close();return bytes
end
local production=readBytes('lua/autorun/server/lod_population_observability.lua')
local watched=assert(production:match('local watched=(%b{})'));local manifest={}
for path in watched:gmatch('"([^"]+)"') do manifest[#manifest+1]=string.rep('a',64)..'  '..path end
assert(#manifest==47,'installer/runtime source coverage changed without transport review')
for _,name in ipairs({'server','client'}) do
    files[name]['legend_of_deborah/dev_population_sources.txt']=table.concat(manifest,'\n')
    files[name]['legend_of_deborah/dev_build.txt']='test-checkout clean'
end
file={CreateDir=noop,Read=function(path,mode)
    return mode=='GAME' and readBytes(path) or files[side()][path]
end,Write=function(path,text)
    local name=side();writes[name]=writes[name]+1
    if not drop[name] then files[name][path]=text end
end}
local function copy(v)
    if type(v)~='table' then return v end
    local out={};for k,item in pairs(v) do out[k]=copy(item) end;return out
end
-- A deterministic JSON boundary double emits actual JSON for length limits;
-- decoding returns the serialized copy and rejects unknown/malformed bytes.
local codec={}
local function json(v)
    local t=type(v)
    if t=='string' then return string.format('%q',v) end
    if t=='number' or t=='boolean' then return tostring(v) end
    if t=='nil' then return 'null' end
    assert(t=='table')
    local n,count=#v,0;for _ in pairs(v) do count=count+1 end
    local parts={}
    if n>0 and n==count then
        for i=1,n do parts[i]=json(v[i]) end
        return '['..table.concat(parts,',')..']'
    end
    local keys={};for key in pairs(v) do keys[#keys+1]=key end
    table.sort(keys,function(a,b) return tostring(a)<tostring(b) end)
    for i,key in ipairs(keys) do parts[i]=json(tostring(key))..':'..json(v[key]) end
    return '{'..table.concat(parts,',')..'}'
end
local tooLarge=false
util={SHA256=function()
    local name=side();hashes[name]=hashes[name]+1;return string.rep('a',64)
end,TableToJSON=function(out)
    if tooLarge and out.source and out.source.modules then return string.rep('x',60001) end
    local encoded=json(out);codec[encoded]=copy(out);return encoded
end,JSONToTable=function(encoded)
    if encoded=='throw-json' then error('injected decoder failure') end
    return codec[encoded] and copy(codec[encoded])
end,AddNetworkString=function(name) assert(name=='LOD_PopulationSnapshot') end}
local receivers={server={},client={}};local requests,responses={},{};local message,incoming
local requestCount,dataReads=0,0
local admin={valid=true,admin=true};function admin:IsAdmin() return self.admin end
local nonAdmin={valid=true,admin=false};function nonAdmin:IsAdmin() return self.admin end
net={Receive=function(name,fn) receivers[side()][name]=fn end,
    Start=function(name) message={channel=name} end,
    WriteUInt=function(size,bits) assert(bits==16 and size<=60000);message.size=size end,
    WriteData=function(text,size) assert(#text==size);message.text=text end,
    Send=function(ply) assert(SERVER and ply==admin);responses[#responses+1]=message;message=nil end,
    SendToServer=function()
        assert(CLIENT);requestCount=requestCount+1;requests[#requests+1]=message;message=nil
    end,
    ReadUInt=function(bits) assert(bits==16);return incoming.size end,
    ReadData=function() dataReads=dataReads+1;return incoming.text end}
local hooks={server={},client={}};local timers={server={},client={}}
hook={Add=function(event,id,fn)
    local h=hooks[side()];h[event]=h[event] or {};h[event][id]=fn
end,Remove=function(event,id)
    local h=hooks[side()];if h[event] then h[event][id]=nil end
end,GetTable=function() return hooks[side()] end}
timer={Create=function(id,seconds,reps,fn) timers[side()][id]={seconds=seconds,reps=reps,fn=fn} end,Simple=noop}
concommand={Add=noop};local map='gm_flatgrass'
game={GetMap=function() return map end,SinglePlayer=function() return true end}
GetConVar=function(name)
    if name=='lod_reduced_effects' then return {GetBool=function() return true end,GetString=function() return '1' end} end
    return {GetBool=function() return false end,GetString=function() return '0' end}
end
ScrW=function() return 1280 end;ScrH=function() return 800 end
ents={GetCount=function() return 3000 end}
LocalPlayer=function() return nil end
local printed={};local nativePrint=print;print=function(line) printed[#printed+1]=line end
realm('server',function() dofile('lua/autorun/server/lod_population_observability.lua') end)
realm('client',function() dofile(root..'sh_runtime_audit.lua') end)
local A,Audit=serverLOD.PopulationObservability,clientLOD.RuntimeAudit
assert(timers.server.LOD_PopulationEvidence.seconds==10 and timers.server.LOD_PopulationEvidence.reps==0)
assert(not hooks.client.PreRender and censusCalls==0 and requestCount==0,'idle transport performed a census')
local function request(ply)
    realm('server',function() receivers.server.LOD_PopulationSnapshot(0,ply) end)
end
local function receive()
    local queued=responses;responses={}
    for _,packet in ipairs(queued) do
        incoming=packet
        realm('client',function() receivers.client.LOD_PopulationSnapshot(16+packet.size*8) end)
    end
end
realm('client',function() Audit:StartPerformanceCapture(30) end)
assert(requestCount==1 and #requests==1 and Audit.PopulationEvidenceStatus.state=='requested')
request(nonAdmin);request(nil);assert(censusCalls==0 and writes.server==0)
request(admin);receive()
assert(censusCalls==1 and hashes.server==47 and A.LastWrite.ok)
assert(Audit.LastPopulationEvidence.live==64 and Audit.LastPopulationEvidence.entry.heroes[1].depth==23)
assert(Audit.PopulationEvidenceStatus.state=='received' and Audit.PopulationEvidenceStatus.client_write)
assert(Audit.LastPopulationEvidence.server_write.ok and Audit.LastPopulationEvidence.source.checked==47)
assert(#Audit.LastPopulationEvidence.source.modules==47,'full source manifest lost in transport')
local saved=assert(files.client['legend_of_deborah/population_latest.txt'])
assert(saved:sub(1,17)=='[LOD:POPULATION] ' and #saved>4095,'full client record unexpectedly compacted')
local checkedConsole=0
for _,line in ipairs(printed) do
    if line:sub(1,17)=='[LOD:POPULATION] ' and line:sub(18,18)=='{' then
        assert(#line<4095,'native console ceiling exceeded')
        local summary=assert(codec[line:sub(18)])
        assert(summary.source.verified and not summary.source.modules and summary.entry.stats.exits==1)
        assert(summary.entry.heroes[1].depth==23 and summary.entry.cells==500)
        checkedConsole=checkedConsole+1
    end
end
assert(checkedConsole==1 and #A.Source.modules==47,'console compaction mutated cached identity')
request(admin);assert(censusCalls==1 and writes.server==1,'request rate bound failed')
local out=realm('client',function() return Audit:StopPerformanceCapture('manual') end)
assert(out.population.live==64 and out.population_status.client_write and out.saved)
-- Server DATA silently dropping a write does not lose the client mirror.
now=102;drop.server=true;request(admin);receive()
assert(not A.LastWrite.ok and A.LastWrite.error:find('did not persist',1,true))
assert(Audit.PopulationEvidenceStatus.client_write and not Audit.LastPopulationEvidence.server_write.ok)
drop.server=false;now=104;drop.client=true;request(admin);receive()
assert(A.LastWrite.ok and not Audit.PopulationEvidenceStatus.client_write)
assert(Audit.LastPopulationEvidence.live==64,'client disk failure discarded in-memory census')
drop.client=false
-- Bad packets cannot create a file or replace the latest valid evidence.
local clientWrites=writes.client;local oldEvidence=Audit.LastPopulationEvidence
for _,packet in ipairs({{size=60001,text='x'},{size=99,text='{}'},
    {size=10,text='throw-json'},{size=2,text='{}'}}) do
    responses={packet};receive()
end
assert(writes.client==clientWrites and Audit.LastPopulationEvidence==oldEvidence)
-- Missing graph/run, wrong map, and oversized payloads remain finite failures.
now=106;map='gm_construct';request(admin);assert(censusCalls==3)
map='gm_flatgrass';local run=serverLOD.RunManager;serverLOD.RunManager=nil
request(admin);assert(censusCalls==3);serverLOD.RunManager=run
now=108;tooLarge=true;request(admin);assert(#responses==0 and censusCalls==4)
tooLarge=false
assert(hashes.server==47,'transport rehashed gameplay on every request')
-- Throwing DATA failure is contained as well as a silent failure.
local oldWrite=file.Write
file.Write=function(path,text) if SERVER then error('injected disk failure') end;return oldWrite(path,text) end
now=110;request(admin);receive()
assert(not A.LastWrite.ok and A.LastWrite.error:find('injected',1,true))
assert(Audit.PopulationEvidenceStatus.client_write and #A.Records<=64)
file.Write=oldWrite
print=nativePrint
print('POPULATION_TRANSPORT_PASS: one automatic opt-in request; existing census/source cache; admin/rate/map/payload bounds; complete client mirror and performance embedding; valid bounded console; native DATA silent/throwing failures; malformed packets; no second census or timer')
