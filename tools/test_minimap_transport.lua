-- Real topology encoder/receiver; only engine transport, time and players doubled.
local noop=function() end
local now, packets, timers, receivers, hooks=10,{}, {}, {}, {}
CurTime=function() return now end
IsValid=function(v) return type(v)=='table' and v.valid==true end
math.Clamp=function(v,a,b) return math.max(a,math.min(b,v)) end
bit={bor=function(a,b) return a|b end,lshift=function(a,b) return a<<b end}
util={AddNetworkString=noop}
hook={Add=function(_,id,fn) hooks[id]=fn end}
timer={Simple=function(delay,fn) timers[#timers+1]={at=now+delay,fn=fn} end}
local packet
net={Receive=function(n,f) receivers[n]=f end,
 Start=function(n) packet={name=n,values={}} end,
 Send=function(p) packet.player=p;packets[#packets+1]=packet end}
for _,name in ipairs({'WriteUInt','WriteDouble','WriteBool','WriteFloat','WriteString'}) do
 net[name]=function(v) packet.values[#packet.values+1]=v end
end
GetConVar=function() return {GetBool=function() return false end} end
local function key(x,y,z) return x..':'..y..':'..z end
LOD={Config={Maze={Origin={x=0,y=0,z=0}}},MazeGenerator={CellKey=key},
 RunManager={State={CampaignEpoch=1,Level=1,LevelSeed=42,BuildReady=true}},
 TopologySyncSafety={BuildSerial=1}}
local function player()
 return {valid=true,IsPlayer=function() return true end,Alive=function() return true end,
 GetNW2Bool=function() return true end,GetNW2Int=function() return 1 end,
 SetNW2Bool=noop,SetNW2Int=noop}
end
local p,q=player(),player()
local function graph(second)
 local cells={['1:1:0']={x=1,y=1,z=0}}
 if second then cells['2:1:0']={x=2,y=1,z=0} end
 return {Cells=cells,Edges={},Layers=1}
end
local function flush()
 now=now+.36
 local due=timers;timers={}
 for _,t in ipairs(due) do if t.at<=now then t.fn() else timers[#timers+1]=t end end
end
dofile('gamemodes/legend_of_deborah/gamemode/lod/sv_minimap.lua')
local M,run=LOD.MinimapServer,LOD.RunManager.State
run.Graph=graph(false)
if not arg[1] or arg[1]=='cache' then
 assert(M:Send(p));assert(packets[1].values[3]==1)
 assert(M:Send(q));assert(M.EncodeBuilds==1 and M.EncodeCacheHits==1)
 local old=setmetatable({run.Graph},{__mode='v'})
 run.Graph=graph(true);packets={}
 assert(M:Send(p))
 assert(packets[1].values[3]==2,'same-seed replacement graph reused retired topology')
 assert(M.EncodeBuilds==2,'replacement topology must encode exactly once')
 -- A rebuild serial also retires a reused graph after an in-place rebuild.
 run.Graph.Cells['2:1:0']=nil;LOD.TopologySyncSafety.BuildSerial=2;packets={}
 assert(M:Send(p));assert(packets[1].values[3]==1,'rebuild serial ignored')
 collectgarbage('collect');collectgarbage('collect')
 assert(old[1]==nil,'map cache retained an entire retired graph')
end
if not arg[1] or arg[1]=='requests' then
 packets={};receivers.LOD_MapRequest(0,p)
 for _=1,100 do receivers.LOD_MapRequest(0,p) end
 assert(#packets==2,'duplicate requests amplify complete map transfers')
 assert(#timers==1,'burst recovery must queue at most one callback')
 receivers.LOD_MapRequest(0,q);assert(#packets==4,'one player throttled another')
 -- Coalescing must deliver the current graph, not lose a rebuild recovery.
 run.Graph=graph(true);flush()
 assert(#packets==6 and packets[5].values[3]==2,'queued resync lost newest topology')
 local n=#packets;receivers.LOD_MapRequest(100000,p)
 assert(#packets==n and #timers==0,'oversized empty request was admitted')
 receivers.LOD_MapRequest(0,p);assert(#timers==1)
 p.valid=false;flush();assert(#packets==n,'disconnected callback sent a map')
end
print('MINIMAP_TRANSPORT_PASS: exact graph/build cache, collection, bounded requests, latest recovery, player isolation')
