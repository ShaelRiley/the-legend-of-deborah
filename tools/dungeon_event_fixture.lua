-- Real maze/progression/event authorities and SQLite wallet transactions.
-- Native entities, traces and packet transport are the only engine doubles.
assert(WalletSQLQuery, 'Run through python3 tools/test_crypto_sqlite.py tools/test_dungeon_events.lua')
return function(options)
options=options or {}
local F={}
local root='gamemodes/legend_of_deborah/gamemode/lod/'
local noop=function() end
SERVER,CLIENT=true,false
F.now=100
CurTime=function() return F.now end
RealTime,SysTime=CurTime,CurTime
function IsValid(v) return type(v)=='table' and v.valid==true end
function isnumber(v) return type(v)=='number' end
function isstring(v) return type(v)=='string' end
function istable(v) return type(v)=='table' end
function Color(...) return {...} end
function Angle(...) return {...} end
function math.Clamp(v,a,b) return math.max(a,math.min(b,v)) end
function table.Copy(t,seen)
 if type(t)~='table' then return t end
 seen=seen or {};if seen[t] then return seen[t] end
 local r={};seen[t]=r
 for k,v in pairs(t) do r[table.Copy(k,seen)]=table.Copy(v,seen) end
 return setmetatable(r,getmetatable(t))
end
function table.Count(t) local n=0;for _ in pairs(t) do n=n+1 end;return n end
local V={};V.__index=V
function Vector(x,y,z) return setmetatable({x=x or 0,y=y or 0,z=z or 0},V) end
V.__add=function(a,b) return Vector(a.x+b.x,a.y+b.y,a.z+b.z) end
V.__sub=function(a,b) return Vector(a.x-b.x,a.y-b.y,a.z-b.z) end
V.__mul=function(a,b) return Vector(a.x*b,a.y*b,a.z*b) end
function V:LengthSqr() return self.x*self.x+self.y*self.y+self.z*self.z end
function V:DistToSqr(b) return (self-b):LengthSqr() end
vector_origin,angle_zero=Vector(),Angle()
MASK_SOLID, MASK_SOLID_BRUSHONLY, SOLID_NONE, MOVETYPE_NONE, SIMPLE_USE = 1,2,0,0,3
local hooks,commands,timers,packets,receivers={},{},{},{},{}
hook={Add=function(event,id,f) hooks[id]=f end,Run=noop}
concommand={Add=function(id,f) commands[id]=f end}
timer={Simple=function(_,f) timers[#timers+1]=f end}
local currentPacket
net={Start=function(id) currentPacket={id=id};packets[#packets+1]=currentPacket end,
 WriteTable=function(v) currentPacket.body=table.Copy(v) end,
 Send=function(p) currentPacket.recipient=p end,Broadcast=noop,
 Receive=function(id,f) receivers[id]=f end}
F.traceBlocked=false
util={AddNetworkString=noop,TraceLine=function() return {Hit=F.traceBlocked} end,
 TraceHull=function() return {Hit=false,StartSolid=false} end,
 TableToJSON=WalletJSONEncode,JSONToTable=function(s) return WalletJSONDecode(s) end}
local convars={}
function CreateConVar(name,default) local c={value=default};function c:GetBool() return self.value=='1' or self.value==true end;function c:GetString() return tostring(self.value) end;convars[name]=c;return c end
function GetConVar(name) return convars[name] end
ErrorNoHalt=noop
sql={Query=WalletSQLQuery,LastError=WalletSQLError,SQLStr=function(s,noQuotes) local escaped=tostring(s):gsub("'","''");return noQuotes and escaped or "'"..escaped.."'" end}
local created={}
ents={Create=function(class)
 local e={valid=true,class=class,pos=Vector(),nw={}}
 function e:GetPos() return self.pos end
 function e:SetPos(v) self.pos=v end
 function e:WorldSpaceCenter() return self.pos end
 function e:EntIndex() return self.index end
 function e:Remove() self.valid=false end
 function e:SetNW2String(k,v) self.nw[k]=v end
 e.SetNW2Bool,e.SetNW2Int=e.SetNW2String,e.SetNW2String
 function e:GetNW2String(k,default) return self.nw[k] or default end
 for _,m in ipairs({'SetModel','SetAngles','SetMoveType','SetSolid','SetUseType','DrawShadow','Spawn','Activate','EmitSound','SetNotSolid','SetCollisionGroup'}) do e[m]=noop end
 e.index=#created+1;created[#created+1]=e;return e
end}
LOD=options.lod or {}
dofile(root..'sh_config.lua');dofile(root..'sh_rng.lua');dofile(root..'sv_maze_generator.lua');dofile(root..'sv_graph_integrity.lua');dofile(root..'sv_progression_director.lua')
local G=LOD.MazeGenerator
local key=function(c) return G.CellKey(c.x,c.y,c.z) end
local Run=options.run or {State={}}
function Run:IdentityOf(p) return p.id end
function Run:GetPlayerState(p) return p.ps end
function Run:IsActivePlayer(p) return p.active~=false end
function Run:IsSoldierControl(p) return p.soldier==true end
function Run:MarkUnranked() self.State.Ranked=false end
LOD.RunManager=Run
LOD.MazeBuilder={CellCenter=function(_,c) return Vector(c.x*384,c.y*384,c.z*384) end,_Register=noop}
LOD.Equipment=LOD.Equipment or {ValidateWearable=function() return true end}
local online={}
player={GetAll=function() return online end}
local function actor(id)
 local p={valid=true,id=id,pos=Vector(),active=true,ps={identity=id,deploymentComplete=true,lives=3}}
 function p:IsPlayer() return true end
 function p:SteamID64() return self.id end
 function p:IsAdmin() return true end
 function p:Alive() return not self.dead end
 function p:GetPos() return self.pos end
 p.EyePos,p.WorldSpaceCenter=p.GetPos,p.GetPos
 function p:ChatPrint(text) self.lastChat=text end
 p.EmitSound=noop
 online[#online+1]=p;return p
end
local a,b=actor('76561198000000001'),actor('76561198000000002')
dofile(root..'sv_crypto_store.lua')
local Store=LOD.CryptoStore
assert(Store.Ready)
local function generate(seed)
 for attempt=1,64 do
  local n=seed*7919+attempt
  local graph=assert(G:Generate(n))
  if LOD.ProgressionDirector:Plan(graph,n) then
   graph.MasterLevelSeed=n
   assert(G:Validate(graph) and graph.Progression.Validation.valid)
   return graph
  end
 end
 error('Canonical generation retry budget exhausted')
end
local graph=generate(1)
Run.State={RunId='events:test',CampaignSeed=41,CampaignEpoch=1,Level=1,LevelSeed=graph.MasterLevelSeed,Graph=graph,BuildReady=true,Ranked=true}
-- Load the actual native entity callbacks while retaining engine method doubles.
AddCSLuaFile,include=noop,noop
ENT={};dofile('gamemodes/legend_of_deborah/entities/entities/lod_dungeon_event/init.lua')
local entityClass=ENT
local nativeCreate=ents.Create
ents.Create=function(class)
 local e=nativeCreate(class)
 if class=='lod_dungeon_event' then
  setmetatable(e,{__index=entityClass})
  function e:SetEventID(id) self.eventID=id end
  function e:GetEventID() return self.eventID end
  function e:GetClass() return class end
  e.SetCollisionBounds,e.SetColor=noop,noop
  function e:Spawn() self:Initialize() end
 end
 return e
end
local feedback={}
LOD.CryptoDirector={Sync=function(_,p) p.walletSynced=true end}
LOD.Audio={Emit=noop}
LOD.CombatRolls={_Send=function(_,p,kind,text,family,fields) feedback[#feedback+1]=fields end}
local function graphSignature(g)
 local edges,cells={},{ }
 for k in pairs(g.Edges) do edges[#edges+1]=k end
 for k in pairs(g.Cells) do cells[#cells+1]=k end
 table.sort(edges);table.sort(cells)
 return table.concat(cells,',')..'/'..table.concat(edges,',')..'/'..WalletJSONEncode(g.Progression)
end
local originalGraph=graphSignature(graph)
-- Actual RunManager generation/commit path, with only native geometry and
-- player-release effects isolated. All progression and event wrappers execute.
local oldGet,oldActive,oldSoldier=Run.GetPlayerState,Run.IsActivePlayer,Run.IsSoldierControl
dofile(root..'sv_run_manager.lua')
Run.GetPlayerState,Run.IsActivePlayer,Run.IsSoldierControl=oldGet,oldActive,oldSoldier
Run.HoldPlayersForBuild=noop;Run._SortedConnectedPlayers=function() return {} end
Run.PromoteWaitingSpectators=noop
LOD.ProgressionDirector.SyncPlayer=noop
F.nativeBuilds,F.nativeCleanups=0,0
LOD.MazeBuilder.Build=function(_,g)
 F.nativeBuilds=F.nativeBuilds+1
 return true,{startPos=LOD.MazeBuilder:CellCenter(g.Start),entityCount=1}
end
LOD.MazeBuilder.Cleanup=function() F.nativeCleanups=F.nativeCleanups+1 end
game={GetMap=function() return 'gm_flatgrass' end}
for _,p in ipairs(online) do p.SteamID64=function(self) return self.id end end
dofile(root..'sh_event_registry.lua');dofile(root..'sv_event_director.lua');dofile(root..'sv_event_slot_machine.lua')
local D,R,Slot=LOD.EventDirector,LOD.EventRegistry,LOD.EventSlotMachine
F.root,F.noop,F.G,F.key,F.Run,F.Store=root,noop,G,key,Run,Store
F.D,F.R,F.Slot,F.graph=D,R,Slot,graph
F.a,F.b,F.actor,F.online=a,b,actor,online
F.created,F.feedback,F.commands,F.hooks,F.timers=created,feedback,commands,hooks,timers
F.packets,F.receivers,F.convars=packets,receivers,convars
F.graphSignature,F.originalGraph,F.generate=graphSignature,originalGraph,generate
return F
end
