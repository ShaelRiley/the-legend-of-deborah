local e=dofile('tools/music_test_fixture.lua');local check=e.check
local files,requests,digests={},{},{};local reads,scans=0,0
file={CreateDir=function() end,Find=function() scans=scans+1;local names={};for p in pairs(files) do names[#names+1]=p:match('[^/]+$') end;return names end,
 Read=function(p) reads=reads+1;return files[p] end,Write=function(p,s) files[p]=s end,
 Append=function(p,s) files[p]=(files[p] or '')..s end,Size=function(p) return files[p] and #files[p] or -1 end,
 Rename=function(a,b) files[b]=files[a];files[a]=nil end,Delete=function(p) files[p]=nil end,Time=function() return 1 end}
HTTP=function(r) requests[#requests+1]=r;return true end
util.SHA256=function(s) return digests[s] or 'invalid' end
local C=e.realMedia();local L=LOD.Music.Limits;local origin='https://music.example.test'
local function asset(letter,n)
 local a={hash=string.rep(letter,64),bytes=n,delivery=1};local data=string.rep(letter,n);digests[data]=a.hash;return a,data
end
local a,data=asset('a',L.chunkBytes*2+9)
check(scans==0 and #requests==0,'module initialization does no cache/network work')
C:Begin({});C:Get(a,origin,false);C:Pump(false)
check(scans==0 and #requests==0,'congestion does not initialize disk cache or network')
C:Pump(true);check(#requests==1 and C.flight,'one bounded request starts')
check(requests[1].url==origin..'/music/chunks/'..a.hash..'/0.dat','requests immutable chunk URL, never full-file URL')
for i=1,30 do C:Pump(true) end
check(#requests==1,'in-flight HTTP cannot multiply')
requests[1].success(200,data:sub(1,L.chunkBytes));C:Pump(false)
check(C.job.offset==0,'callback defers disk work during congestion')
C:Pump(true);check(C.job.offset==L.chunkBytes and #requests==1,'completed chunk processed without a burst')
e.now=e.now+.5;C:Pump(true);check(#requests==2,'next chunk paced to 32 KiB/s maximum')
requests[2].success(200,data:sub(L.chunkBytes+1,2*L.chunkBytes));e.now=e.now+50;C:Pump(true)
check(#requests==3,'long pause issues only one next chunk')
requests[3].success(200,data:sub(2*L.chunkBytes+1));C:Pump(true)
local ready=C:Get(a,origin,true)
check(ready and C.cache[a.hash].verified and not C.job,'full verified asset published to local playback')
local previousReads=reads;local count=#requests
for i=1,100 do C:Begin({});check(C:Get(a,origin,true)==ready,'cached reuse');C:Pump(true) end
check(#requests==count and reads==previousReads and scans==1,'warm loops need no requests, repeated hash reads or directory scans')
local b,bdata=asset('b',L.chunkBytes*2)
C:Begin({});C:Get(b,origin,true);e.now=e.now+1;C:Pump(true);local late=requests[#requests]
C:Stop();check(C.flight and not C.job,'Off keeps the one uncancellable request counted')
C:Begin({});C:Get(a,origin,true);C:Pump(true)
check(#requests==count+1,'Off/On cannot bypass outstanding transfer accounting')
late.success(200,bdata:sub(1,L.chunkBytes))
check(not C.flight and not C.response,'Off discards stale body without writing or continuation')
local b2,b2data=asset('c',30)
C:Begin({});C:Get(b2,origin,true);e.now=e.now+1;C:Pump(true);requests[#requests].success(200,string.rep('x',30));C:Pump(true)
check(C.failures[b2.hash]=='download hash mismatch' and not C.cache[b2.hash],'tampered media never enters playback cache')
local b3=asset('d',20);C:Begin({});C:Get(b3,origin,true);e.now=e.now+1;C:Pump(true)
requests[#requests].success(200,string.rep('d',21));C:Pump(true)
check(C.failures[b3.hash]=='invalid music chunk','oversized/misconfigured response rejected without retry')
local n=#requests;C:Pump(true);check(#requests==n,'failed source cannot spin retries')
local legacy=asset('e',10);legacy.delivery=nil
local _,why=C:Get(legacy,origin,true);check(why and #requests==n,'legacy media never falls back to uncontrolled URL streaming')
-- A fresh helper discovers and hashes a prior-session cache once.
C=e.realMedia();C:Begin({});local old=reads
check(C:Get(a,origin,true)==ready and reads==old+1,'persistent cache verified once after reload')
C:Get(a,origin,true);check(reads==old+1,'verified warm cache avoids repeated hashing')
files[ready:sub(6)]=string.rep('x',a.bytes);C=e.realMedia();C:Begin({})
check(not C:Get(a,origin,true) and not C.cache[a.hash],'same-size persistent cache corruption is rejected')
-- LRU eviction respects active native channels and the byte/file limits.
C.initialized=true;C.cache={}
for i=1,65 do local h=string.format('%064x',i);C.cache[h]={bytes=1,used=i};files['legend_of_deborah/music_cache/'..h..'.dat']='x' end
local first=string.format('%064x',1);local second=string.format('%064x',2);C.pinned={[first]=true};C:Trim(0)
check(C.cache[first] and not C.cache[second] and table.Count(C.cache)==64,'LRU evicts oldest unpinned entry at file ceiling')
print('MUSIC_MEDIA PASS '..e.checks)
