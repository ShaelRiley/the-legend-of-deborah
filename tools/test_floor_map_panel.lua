-- Real pickup -> party mirrors -> typed transport -> client HUD -> Magic/movement.
-- Separate realm config/origins catch bootstrap errors hidden by shared fixtures.
local env=dofile('tools/test_enemy_update.lua')
local root='gamemodes/legend_of_deborah/gamemode/lod/'
local noop=function() end
local server=LOD
local realm='server'
local hooks,receivers,commands,timers={server={},client={}},{server={},client={}},{server={},client={}},{server={},client={}}
local now,packets,incoming,readAt,outgoing=100,{},nil,0,nil
CurTime=function() return now end
hook={Add=function(_,id,fn) hooks[realm][id]=fn end,GetTable=function() return {} end}
concommand={Add=function(id,fn) commands[realm][id]=fn end}
timer={Simple=function(_,fn) fn() end,Create=function(id,_,__,fn) timers[realm][id]=fn end}
GetConVar=function(name) return {GetBool=function() return name=='lod_developer_mode' end} end
bit={band=function(a,b) return a&b end,bor=function(a,b) return a|b end,lshift=function(a,b) return a<<b end,rshift=function(a,b) return a>>b end}
local function write(v,kind) outgoing.values[#outgoing.values+1]={v,kind} end
local function read(kind)
 local row=assert(incoming.values[readAt]);readAt=readAt+1
 assert(row[2]==kind,'wire type/width mismatch');return row[1]
end
net={Receive=function(id,fn) receivers[realm][id]=fn end,
 Start=function(id) outgoing={from=realm,id=id,values={}} end,
 Send=function(p) outgoing.target=p;packets[#packets+1]=outgoing end,
 SendToServer=function() packets[#packets+1]=outgoing end}
for _,kind in ipairs({'Double','Bool','Float','String'}) do
 net['Write'..kind]=function(v) write(v,kind) end
 net['Read'..kind]=function() return read(kind) end
end
net.WriteUInt=function(v,width) assert(v>=0 and v<2^width);write(v,width) end
net.ReadUInt=read
local originZ=arg[1]=='--pickup-only-negative' and -12286 or 8192
server.Config.Maze.Origin=Vector(2000,-3000,originZ)
local MC=server.Config.Maze
local online={}
local function hero()
 local p=env.actor(1);p.player=true;p.active=true;p.nw={};p.clientNW={}
 function p:GetNW2Bool(key,default)
  local v=(realm=='server' and self.nw or self.clientNW)[key];if v==nil then return default end;return v
 end
 p.GetNW2Int=p.GetNW2Bool;p.GetNW2Float=p.GetNW2Bool
 p.SetNW2Int=p.SetNW2Bool;p.SetNW2Float=p.SetNW2Bool
 function p:NearestPoint() return self:GetPos()+Vector(0,0,36) end
 function p:ChatPrint() end
 online[#online+1]=p;return p
end
local p,q=hero(),hero()
player.GetAll=function() return online end
local R,B=server.RunManager,server.MazeBuilder
R.IsActivePlayer=function(_,who) return who.active and who.alive end
R._SyncPlayerVars=noop
B.Entities={};B.Build=function(self) self.Entities={};return true,{} end
B._Register=function(self,e) self.Entities[#self.Entities+1]=e end
B.CellCenter=function(_,c) return MC.Origin+Vector((c.x-11)*MC.CellSize,(c.y-11)*MC.CellSize,c.z*MC.LevelHeight) end
ents.Create=function(class)
 local e=env.actor(1);e.class=class;e.Spawn=noop
 function e:SetFloorIndex(z) self.floor=z end
 function e:GetFloorIndex() return self.floor end
 return e
end
dofile(root..'sh_rng.lua');dofile(root..'sv_maze_generator.lua')
local a,b,c,d={x=11,y=11,z=0},{x=12,y=11,z=0},{x=12,y=11,z=1},{x=13,y=11,z=1}
local g={Start=a,Goal=d,Cells={},Edges={},Layers=2,CriticalPath={a,b,c,d},Progression={Gates={}},VerticalEdges={{a=b,b=c}}}
local function key(c) return server.MazeGenerator.CellKey(c.x,c.y,c.z) end
for _,cell in ipairs({a,b,c,d}) do cell.neighbors={};g.Cells[key(cell)]=cell end
for _,pair in ipairs({{a,b},{b,c},{c,d}}) do
 local x,y=key(pair[1]),key(pair[2]);pair[1].neighbors[y]=true;pair[2].neighbors[x]=true
 g.Edges[x<y and x..'|'..y or y..'|'..x]={a=pair[1],b=pair[2]}
end
R.State={Graph=g,Level=1,LevelSeed=42,CampaignEpoch=9,BuildReady=true,RunId='panel-test'}
server.ProgressionDirector={Announce=noop}
server.RPGPresentation={SendFX=noop}
dofile(root..'sv_minimap.lua');dofile(root..'sv_floor_maps.lua');dofile(root..'sv_multiplayer_contracts.lua')
assert(B:Build(g));local maps=R.State.FloorMaps
local S=server.MinimapServer
local pools={}
server.Magic={_EnsureState=function(_,who) pools[who]=pools[who] or {magic=100};return pools[who] end,
 _Sync=function(_,who,pool) who:SetNW2Float('LOD_Magic',pool.magic) end}
dofile(root..'sv_minimap_magic.lua')
server.RPG={IdentityCatalog={OrdinaryFeats={}},FeatEffectSystem={ApplyDerived=noop}}
server.CharacterProgressionSystem={}
server.RPGAbilityRules={MovementMultiplier=function() return 1 end,Derived=function() return {mapOpenMovementMultiplier=1.75} end}
dofile(root..'sv_rpg_gate_e_map_movement.lua')
local function replicate(who) who.clientNW=table.Copy(who.nw);who.clientNW.LOD_Magic=(pools[who] or {}).magic or 100 end
for _,who in ipairs(online) do who:SetPos(MC.Origin+Vector(MC.CellSize,0,MC.LevelHeight));R:_SyncPlayerVars(who);replicate(who) end
local client={Config={Maze=table.Copy(MC),Geometry={}},ClientState={level=1,gates={}},Audio={Play=noop}}
client.Config.Maze.Origin=Vector(0,0,0)
local function switch(side) realm=side;LOD=side=='server' and server or client end
local localPlayer=p
LocalPlayer=function() return localPlayer end
local texts,textures,rects,lines={},0,0,0
Color=function(r,g,b,a) return {r=r,g=g,b=b,a=a or 255} end
surface=setmetatable({GetAlphaMultiplier=function() return 1 end,
 DrawTexturedRect=function() textures=textures+1 end,DrawRect=function() rects=rects+1 end,DrawLine=function() lines=lines+1 end},{__index=function() return noop end})
draw={RoundedBox=noop,SimpleText=function(t) texts[#texts+1]=t end}
cam=setmetatable({},{__index=function() return noop end});render=setmetatable({},{__index=function() return noop end})
GetRenderTarget=function() return {GetName=function() return 'panel-test' end} end;CreateMaterial=function() return {} end
Matrix=function() return {SetScale=noop,SetTranslation=noop} end
ScrW=function() return 1280 end;ScrH=function() return 800 end;EyeAngles=function() return {y=0} end
KEY_Q,KEY_M=81,77
local down={};input={IsKeyDown=function(k) return down[k]==true end}
gui={IsGameUIVisible=function() return false end};vgui={GetKeyboardFocus=function() return nil end}
local notices={};notification={AddLegacy=function(text) notices[#notices+1]=text end}
local function loadClient()
 switch('client');dofile(root..'cl_minimap.lua');dofile(root..'cl_minimap_reliability.lua');dofile(root..'cl_minimap_logical_cell.lua');dofile(root..'cl_minimap_magic_quadrants.lua')
end
loadClient();local M=client.Minimap
local function pump()
 while #packets>0 do
  local batch=packets;packets={}
  for _,packet in ipairs(batch) do
   if packet.from=='client' or packet.target==localPlayer then
    switch(packet.from=='client' and 'server' or 'client');incoming=packet;readAt=1
    local fn=assert(receivers[realm][packet.id],packet.id)
    fn(0,p);assert(readAt==#packet.values+1,'receiver did not consume complete packet')
   end
  end
 end
 switch('client')
end
local function paint(blank)
 texts={};textures=0;rects=0;lines=0
 hooks.client.LOD_MinimapLogicalCellGuard();hooks.client.LOD_MinimapNearestRealCell()
 hooks.client.LOD_MinimapTopologyCache();hooks.client.LOD_MinimapHUD();hooks.client.LOD_MinimapQuadrantPresentation()
 local hasMessage=false;for _,t in ipairs(texts) do if t=='Map not found' then hasMessage=true end end
 assert(M.open,'paint closed the requested panel')
 if blank then assert(hasMessage and textures==0 and lines==0 and rects==1,'blank panel leaked maze/route/quadrant overlays')
 else assert(not hasMessage and textures==1,'collected floor did not render its maze') end
end
if arg[1]=='--pickup-only' or arg[1]=='--pickup-only-negative' then
 switch('server');assert(S:CollectFloorMap(p,maps.plan.maps[1].entity));replicate(p)
 switch('client');commands.client.lod_minimap_toggle()
 assert(M.open,'collected map cannot bootstrap an offset-origin client')
 pump();paint(false);assert(M:HasAccess(p) and client.Config.Maze.Origin.z==originZ)
 print('FLOOR_MAP_PICKUP_BOOTSTRAP_PASS: actual collection, mirrors, offset origin, transfer and maze rendering')
 return
end
down[KEY_Q]=true;hooks.client.LOD_MinimapToggleInput()
assert(M.open and #notices==0,'Q must open an unfound-floor panel without a denial notification')
pump();assert(M:IsReady() and #M.cells==0 and client.Config.Maze.Origin.z==originZ,'empty discovery did not synchronize metadata')
paint(true);local requests=M.stats.mapRequests
now=now+1;paint(true);assert(M.stats.mapRequests==requests,'blank panel retransfers empty topology')
hooks.client.LOD_MinimapMagicHeartbeat();pump()
switch('server');assert(server.MinimapMagic:IsOpen(p),'blank panel lost real Magic admission')
assert(server.RPGAbilityRules:MovementMultiplier(p)==1.75,'blank panel lost map-up movement')
now=now+.1;timers.server.LOD_MinimapMagicDrain();assert(pools[p].magic<100,'blank panel did not drain')
local lease=server.MinimapMagic.Active[p];local budget=pools[p].magic
assert(S:CollectFloorMap(p,maps.plan.maps[1].entity));assert(maps.mask==2 and q.nw.LOD_MapFloorMask==2)
-- The map packet may precede NW2 replication: keep the panel/effects up and
-- display no maze until the two identities agree, then reveal without a reopen.
pump();paint(true);assert(not M:IsReady(),'early map packet ignored the older NW2 discovery mask')
replicate(p);replicate(q);pump();paint(false)
assert(M:HasAccess(p) and #M.cells==2 and M.cells[1].z==1 and M.cells[2].z==1,'party pickup revealed wrong floors')
switch('server');assert(server.MinimapMagic.Active[p]==lease and pools[p].magic==budget,'discovery reset/refunded the open map lease')
-- An unfound-floor transition keeps the same panel/effects/budget, hides layout.
p:SetPos(MC.Origin);switch('client');paint(true);hooks.client.LOD_MinimapMagicHeartbeat();pump()
switch('server');assert(server.MinimapMagic:IsOpen(p) and server.RPGAbilityRules:MovementMultiplier(p)==1.75)
now=now+.1;timers.server.LOD_MinimapMagicDrain();assert(pools[p].magic<budget)
-- Reconnect/late Hero inherits the discovery; no inventory record is involved.
local late=hero();late:SetPos(q:GetPos());R:_SyncPlayerVars(late)
assert(late.nw.LOD_MapFloorMask==2 and S:HasFloor(late))
switch('client');down={};hooks.client.LOD_MinimapToggleInput();down[KEY_M]=true;hooks.client.LOD_MinimapToggleInput()
assert(not M.open,'M did not close the blank panel');hooks.client.LOD_MinimapMagicHeartbeat();pump()
switch('server');assert(not server.MinimapMagic:IsOpen(p) and server.RPGAbilityRules:MovementMultiplier(p)==1)
switch('client');commands.client.lod_minimap_toggle();hooks.client.LOD_MinimapMagicHeartbeat();pump()
switch('server');pools[p].magic=.01;now=now+.1;timers.server.LOD_MinimapMagicDrain();pump()
assert(not M.open,'real exhaustion did not force-close the blank panel')
-- Same-level rebuild retires both discovered topology and personal Magic lease.
switch('server');pools[p].magic=100;assert(B:Build(g));R:_SyncPlayerVars(p);replicate(p)
switch('client');commands.client.lod_minimap_toggle();pump();paint(true)
assert(#M.cells==0 and M.floorMask==0 and M.buildSerial>maps.serial,'rebuild retained old layout')
switch('server');p.alive=false;R:_SyncPlayerVars(p);replicate(p)
switch('client');hooks.client.LOD_MinimapHUD();assert(not M.open,'death kept the panel up')
print('FLOOR_MAP_PANEL_PASS: two realms/offset origins; Q/M/VR panel; blank metadata/no topology leaks or polling; actual party touch/maze transition; unchanged personal Magic lease/drain/movement; exhaustion, late Hero and rebuild/death')
