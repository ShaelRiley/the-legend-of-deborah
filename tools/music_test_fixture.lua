-- Minimal engine boundary; all catalog/planning/mixing logic comes from production.
local E={now=10,callbacks={},hooks={},commands={},wire={},read={},requests={},stops=0,plays=0,cv={}}
function CurTime() return E.now end;SysTime=CurTime
function FrameTime() return .1 end
function IsValid(x) return type(x)=='table' and x.valid~=false end
function isstring(x) return type(x)=='string' end
function Color(...) return {...} end
function math.Clamp(n,a,b) return math.min(b,math.max(a,n)) end
function math.Approach(n,t,s) return n<t and math.min(t,n+s) or math.max(t,n-s) end
function table.Copy(t) if type(t)~='table' then return t end local n={};for k,v in pairs(t) do n[k]=table.Copy(v) end;return n end
function table.Count(t) local n=0;for _ in pairs(t) do n=n+1 end;return n end
local V={};V.__index=V
function Vector(x,y,z) return setmetatable({x=x or 0,y=y or 0,z=z or 0},V) end
function V.__add(a,b) return Vector(a.x+b.x,a.y+b.y,a.z+b.z) end
function V.__sub(a,b) return Vector(a.x-b.x,a.y-b.y,a.z-b.z) end
function V.__mul(a,b) return Vector(a.x*b,a.y*b,a.z*b) end
function V:DistToSqr(b) local d=self-b;return d.x*d.x+d.y*d.y+d.z*d.z end
FCVAR_ARCHIVE,FCVAR_REPLICATED,FCVAR_NOTIFY=1,2,4
IN_SPEED,MOVETYPE_WALK=131072,2
bit={bor=function(a,b,c) return a|b|(c or 0) end}
local function cv(name,value)
 E.cv[name]=E.cv[name] or {value=tostring(value)};local c=E.cv[name]
 function c:GetBool() return self.value~='0' end
 function c:GetFloat() return tonumber(self.value) end
 function c:GetInt() return tonumber(self.value) end
 return c
end
CreateConVar=cv;CreateClientConVar=cv;GetConVar=function(name) return E.cv[name] end
cvars={AddChangeCallback=function(name,fn,id) E.callbacks[name]=E.callbacks[name] or {};E.callbacks[name][id]=fn end}
function E.set(name,v) E.cv[name].value=tostring(v);for _,f in pairs(E.callbacks[name] or {}) do f() end end
hook={Add=function(event,id,fn) E.hooks[id]=fn end}
concommand={Add=function(name,fn) E.commands[name]=fn end}
file={Read=function() end,CreateDir=function() end,Write=function() end}
local json={}
local function stable(v)
 if type(v)~='table' then return tostring(v) end
 local keys={};for k in pairs(v) do keys[#keys+1]=k end;table.sort(keys,function(a,b) return tostring(a)<tostring(b) end)
 local out={};for _,k in ipairs(keys) do out[#out+1]=tostring(k)..'='..stable(v[k]) end
 return '{'..table.concat(out,',')..'}'
end
util={AddNetworkString=function() end,TableToJSON=function(v) local s=stable(v);json[s]=table.Copy(v);return s end,
 JSONToTable=function(s) return table.Copy(json[s]) end,Compress=function(s) return s end,Decompress=function(s) return s end}
net={Receive=function(name,fn) E.wire[name]=fn end,Start=function(name) E.packet={name=name,args={}} end}
for _,name in ipairs({'String','UInt','Data','Bool'}) do
 net['Write'..name]=function(v) table.insert(E.packet.args,v) end
 net['Read'..name]=function() return table.remove(E.read,1) end
end
net.Send=function(p) E.sent=E.sent or {};E.sent[#E.sent+1]=E.packet end
net.SendToServer=net.Send
function E.receive(name,...) E.read={...};E.wire[name](1024,E.player) end
sound={PlayURL=function(url,flags,fn) E.requests[#E.requests+1]={url=url,flags=flags,fn=fn} end}
function E.complete(index,buffer,fail)
 local req=E.requests[index];assert(req,'request missing')
 if fail then req.fn(nil,2,'test failure');return end
 local c={valid=true,buffer=buffer or 16,time=0,volume=0}
 function c:Stop() self.valid=false;E.stops=E.stops+1 end
 function c:GetBufferedTime() assert(self.valid,'buffer queried after native Stop');return self.buffer end
 function c:GetTime() assert(self.valid,'position queried after native Stop');return self.time end
 function c:SetTime(v) assert(self.valid,'seek after native Stop');assert(v<=self.buffer,'unbuffered native seek');self.time=v end
 function c:SetVolume(v) self.volume=v end
 function c:EnableLooping(v) self.loop=v end
 function c:Play() E.plays=E.plays+1;self.played=true end
 function c:Pause() self.played=false end
 req.channel=c;req.fn(c);return c
end
LOD={Config={Maze={Width=1,Height=1,CellSize=384,LevelHeight=384,Origin=Vector(),LayerOccupancy={{},{},{},{}}},Geometry={StairRun=320,StairSteps=24,StairWidth=96}},
 MazeGenerator={CellKey=function(x,y,z) return x..':'..y..':'..z end},MazeBuilder={CellCenter=function(_,c) return Vector(0,0,c.z*384) end}}
dofile('gamemodes/legend_of_deborah/gamemode/lod/sh_rng.lua')
dofile('gamemodes/legend_of_deborah/gamemode/lod/sv_maze_navigator.lua')
dofile('gamemodes/legend_of_deborah/gamemode/lod/sh_music.lua')
function E.catalog()
 local c={schema=1,revision='v1',origin='https://music.example.test',assets={},blocks={},profiles={},sets={}}
 for i,role in ipairs(LOD.Music.Roles) do
  local hash=string.rep(string.format('%x',i),64)
  c.assets[hash]={hash=hash,path='music/blocks/default/v1/'..role:lower()..'.ogg',bytes=1000,duration=role=='VICTORY' and 6.5 or 16,
   codec='vorbis',rate=44100,channels=2,loop=role~='VICTORY',bpm=120,beats=role=='VICTORY' and 13 or 32,phase=0,gain=1,headroom=6,
   grid='grid',handoff='envelope',loopStart=0,loopEnd=role=='VICTORY' and 6.5 or 16,credits='Test',source='Authored fixture'}
 end
 local defaults={};for i,role in ipairs(LOD.Music.Roles) do defaults[role]=string.rep(string.format('%x',i),64) end
 c.profiles.default={version='v1',roles=defaults};c.projectDefault='default'
 for _,id in ipairs({'alpha','beta','gamma','delta'}) do c.blocks[id]={version='v1',title=id,credits='Test',roles={}} end
 c.sets.pair={revision='v1',title='Two',members={'beta','alpha','alpha'}}
 return c
end
E.checks=0
function E.check(ok,msg) E.checks=E.checks+1;assert(ok,msg) end
function E.step(n) for _=1,n or 1 do E.now=E.now+.1;LOD.MusicDirector:Tick() end end
return E
