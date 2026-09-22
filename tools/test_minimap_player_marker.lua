ScrH=function() return 1080 end
-- Exercise the actual HUD renderer, including maps wider than the base grid.
local noop=function() end
local hooks={}
hook={Add=function(event,id,fn) hooks[event]=hooks[event] or {};hooks[event][id]=fn end,
 Remove=function(event,id) if hooks[event] then hooks[event][id]=nil end end}
local circles,lines,color={},{},nil
surface=setmetatable({DrawCircle=function(x,y,r,red,green,blue) circles[#circles+1]={x=x,y=y,r=r,red=red,green=green,blue=blue} end,
 SetDrawColor=function(c) color=c end,DrawLine=function(...) lines[#lines+1]={color=color} end}, {__index=function() return noop end})
local peerMarkers={}
draw={RoundedBox=function(_,x,y,w,h,c) if c.r==100 and c.g==235 then peerMarkers[#peerMarkers+1]={x=x,y=y} end end,SimpleText=noop}
GetRenderTarget=function() return {GetName=function() return 'map' end} end
CreateMaterial=function() return {} end
Color=function(r,g,b,a) return {r=r,g=g,b=b,a=a} end
math.Clamp=function(x,a,b) return math.max(a,math.min(b,x)) end
net={Receive=noop,Start=noop,SendToServer=noop};concommand={Add=noop}
CurTime=function() return 10 end;ScrW=function() return 1280 end
EyeAngles=function() return {y=0} end
local player={pos={x=0,y=0,z=0},alive=true,access=true}
function player:Alive() return self.alive end
function player:GetPos() return self.pos end
function player:GetNW2Bool(key) if key=='LOD_IsSoldier' then return false end;return self.access end
function player:GetNW2Int(_,default) return default end
LocalPlayer=function() return player end
IsValid=function(p) return p==player end
LOD={Config={Maze={Width=21,Height=21,CellSize=384,LevelHeight=384,Origin={x=0,y=0,z=0}},Geometry={}},ClientState={level=1,gates={}}}
local root='gamemodes/legend_of_deborah/gamemode/lod/'
dofile(root..'cl_minimap.lua')
hook.Add('PostDrawHUD','LOD_MinimapComplementaryPlayerMarker',function() error('duplicate marker survived refresh') end)
dofile(root..'cl_minimap_player_contrast.lua')
assert(not hooks.PostDrawHUD.LOD_MinimapComplementaryPlayerMarker)
local M=LOD.Minimap
M.level=1;M.layers=4;M.expectedChunks=1;M.receivedChunks=1
M.cache.revision=1;M.cache.indexedRevision=1;M.cache.topologyRevision=1
for _,width in ipairs({21,29,37}) do
 M.gridWidth=width
 for _,cell in ipairs({{x=11,y=11,z=0},{x=19,y=4,z=2},{x=width,y=21,z=3}}) do
  local key=cell.x..':'..cell.y..':'..cell.z
  M.cells={cell};M.byKey={[key]=cell};M.cache.adjacency={[key]={}}
  M.cache.reach=nil;M.cache.topologyFloor=cell.z;M.open=true
  player.pos={x=(cell.x-11)*384,y=(cell.y-11)*384,z=cell.z*384}
  circles={};lines={};hooks.HUDPaint.LOD_MinimapHUD()
  assert(#circles==2,'expected one marker with one outline, no gold player')
  local c=circles[2]
  assert(c.red==72 and c.green==132 and c.blue==255 and c.r==3,'player must be blue')
  local scale=284/width
  assert(math.abs(c.x-(1280-336-20+26+(cell.x-.5)*scale))<1e-8,'wrong expanded-grid x')
  assert(math.abs(c.y-(96+68+(21-cell.y+.5)*scale))<1e-8,'wrong expanded-grid y')
  assert(#lines==5 and lines[5].color.b==255,'one outlined blue direction needle')
 end
end
local peer={pos={x=0,y=0,z=384},Alive=function() return true end,GetPos=function(self) return self.pos end,
 GetNW2Bool=function(_,key) return key=='LOD_Deployed' end}
_G.player={GetAll=function() return {player,peer} end}
IsValid=function(p) return p==player or p==peer end
M.gridWidth=21;M.layers=2;M.open=true;M.cache.topologyFloor=0;M.cache.reach=nil
M.byKey={['11:11:0']={x=11,y=11,z=0},['11:11:1']={x=11,y=11,z=1}}
M.cells={M.byKey['11:11:0'],M.byKey['11:11:1']}
player.pos={x=0,y=0,z=0}
peerMarkers={};hooks.HUDPaint.LOD_MinimapHUD();assert(#peerMarkers==0,'Other floors must stay hidden')
peer.pos.z=0
peerMarkers={};hooks.HUDPaint.LOD_MinimapHUD();assert(#peerMarkers==1,'Current-floor Hero must appear once')
ScrH=function() return 2160 end;ScrW=function() return 3840 end
circles={};hooks.HUDPaint.LOD_MinimapHUD()
local grid=568
assert(math.abs(circles[2].x-(3840-(grid+52)-20+26+10.5*grid/21))<1e-8,'4K map must scale its grid')
for _,state in ipairs({'closed','dead','no-access'}) do
 M.open=state~='closed';player.alive=state~='dead';player.access=state~='no-access'
 circles={};hooks.HUDPaint.LOD_MinimapHUD();assert(#circles==0,'marker bypassed map/player access')
end
print('MINIMAP_PLAYER_PASS: one blue marker; standard/expanded topology, extended cells, floors, movement, reload and access')
