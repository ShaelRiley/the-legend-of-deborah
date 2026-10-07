ScrH=function() return 1080 end
-- Exercise the actual HUD renderer, including maps wider than the base grid.
local noop=function() end
local hooks={}
hook={Add=function(event,id,fn) hooks[event]=hooks[event] or {};hooks[event][id]=fn end,
 Remove=function(event,id) if hooks[event] then hooks[event][id]=nil end end}
local circles,lines,rects,color={},{},{},nil
local alpha,alphaReads=1,0
local matrices,matrixBuilds={},0
local function point(x,y)
 local m=matrices[#matrices];if m then return x*m.scale.x+m.pos.x,y*m.scale.y+m.pos.y end;return x,y
end
surface=setmetatable({DrawCircle=function(x,y,r,red,green,blue)
 local m=matrices[#matrices];x,y=point(x,y);circles[#circles+1]={x=x,y=y,r=r*(m and m.scale.x or 1),red=red,green=green,blue=blue,alpha=alpha} end,
 GetAlphaMultiplier=function() alphaReads=alphaReads+1;return alpha end,
 SetAlphaMultiplier=function(n) alpha=n end,
 SetDrawColor=function(c,...) color=type(c)=='table' and c or {r=c,g=select(1,...),b=select(2,...),a=select(3,...)} end,
 DrawRect=function(x,y,w,h) local m=matrices[#matrices];x,y=point(x,y);rects[#rects+1]={x=x,y=y,w=w*(m and m.scale.x or 1),h=h*(m and m.scale.y or 1),color=color,alpha=alpha} end,
 DrawLine=function(...) lines[#lines+1]={color=color,alpha=alpha} end}, {__index=function() return noop end})
function Vector(x,y,z) return {x=x,y=y,z=z} end
function Matrix()
 matrixBuilds=matrixBuilds+1
 return {SetScale=function(self,s) self.scale=s end,SetTranslation=function(self,p) self.pos=p end}
end
cam={PushModelMatrix=function(m,multiply) assert(multiply);matrices[#matrices+1]=m end,
 PopModelMatrix=function() assert(#matrices>0);matrices[#matrices]=nil end}
local peerMarkers,texts,panels={},{},{}
draw={RoundedBox=function(_,x,y,w,h,c)
 local m=matrices[#matrices];x,y=point(x,y)
 if c.r==100 and c.g==235 then peerMarkers[#peerMarkers+1]={x=x,y=y,alpha=alpha}
 elseif c.a==226 then panels[#panels+1]={x=x,y=y,w=w*(m and m.scale.x or 1),h=h*(m and m.scale.y or 1),alpha=alpha} end end,
 SimpleText=function(text,font,x,y,c) x,y=point(x,y);texts[#texts+1]={text=text,x=x,y=y,alpha=alpha} end}
GetRenderTarget=function() return {GetName=function() return 'map' end} end
CreateMaterial=function() return {} end
Color=function(r,g,b,a) return {r=r,g=g,b=b,a=a} end
math.Clamp=function(x,a,b) return math.max(a,math.min(b,x)) end
local commands={}
net={Receive=noop,Start=noop,SendToServer=noop};concommand={Add=function(name,fn) commands[name]=fn end}
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
CLIENT=true
local preferences={}
function CreateClientConVar(name,value)
 preferences[name]=preferences[name] or {value=tonumber(value)}
 local c=preferences[name];function c:GetFloat() return self.value end;function c:GetBool() return self.value~=0 end;return c
end
dofile(root..'sh_player_options.lua')
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
-- Both keyboard keys and the VR command share the real access/cache authority.
KEY_M,KEY_Q=77,81
local covered,focused,down=false,false,{}
gui={IsGameUIVisible=function() return covered end}
vgui={GetKeyboardFocus=function() return focused and player or nil end}
input={IsKeyDown=function(key) return down[key]==true end}
LOD.Audio={Play=noop};notification={AddLegacy=noop};NOTIFY_HINT=1
player.alive=true;player.access=true;M.open=false
commands.lod_minimap_toggle();assert(M.open,'controller command opens owned map')
local reopens=M.stats.mapCacheReopens
commands.lod_minimap_toggle();assert(not M.open)
down[KEY_M]=true;hooks.Think.LOD_MinimapToggleInput();assert(M.open and M.stats.mapCacheReopens==reopens+1)
hooks.Think.LOD_MinimapToggleInput();assert(M.open,'held M must not toggle repeatedly')
down[KEY_Q]=true;hooks.Think.LOD_MinimapToggleInput();assert(not M.open,'Q works while M is held')
hooks.Think.LOD_MinimapToggleInput();assert(not M.open,'held Q/M must not repeat')
down={};hooks.Think.LOD_MinimapToggleInput()
down[KEY_Q]=true;hooks.Think.LOD_MinimapToggleInput();assert(M.open,'released Q can toggle again')
down={};hooks.Think.LOD_MinimapToggleInput()
covered=true;down[KEY_Q]=true;hooks.Think.LOD_MinimapToggleInput();assert(M.open,'Q retains game UI input')
covered=false;hooks.Think.LOD_MinimapToggleInput();assert(M.open,'held UI key cannot leak after close')
down={};hooks.Think.LOD_MinimapToggleInput()
focused=true;down[KEY_M]=true;hooks.Think.LOD_MinimapToggleInput();assert(M.open,'M retains keyboard focus')
focused=false;hooks.Think.LOD_MinimapToggleInput();assert(M.open,'held focused key cannot leak')
covered=true;commands.lod_minimap_toggle();assert(M.open,'covered UI retains control')
covered=false;commands.lod_minimap_toggle();assert(not M.open)
player.access=false;commands.lod_minimap_toggle();assert(not M.open,'VR cannot bypass map ownership')
down={};hooks.Think.LOD_MinimapToggleInput()
down[KEY_Q]=true;hooks.Think.LOD_MinimapToggleInput();assert(not M.open,'Q cannot bypass map ownership')
down={};hooks.Think.LOD_MinimapToggleInput();player.access=true
down[KEY_Q],down[KEY_M]=true,true;hooks.Think.LOD_MinimapToggleInput();assert(M.open,'Simultaneous keys toggle once')
-- Real quadrant overlay must share the complete map transform and alpha.
net.WriteBool=noop
function player:GetNW2Float(_,default) return self.magic or default end
local wall={world={}}
for q=1,4 do wall.world[q]={floor=0,quadrant=q,bodyColor=Color(30*q,40*q,50*q)} end
LOD.WallVisualsClient=wall
dofile(arg[1]=='--quadrant-source' and assert(arg[2]) or root..'cl_minimap_magic_quadrants.lua')
local quadrant=hooks.PostDrawHUD.LOD_MinimapQuadrantPresentation
local function near(a,b,message) assert(math.abs(a-b)<1e-8,message..': '..a..' ~= '..b) end
player.pos={x=0,y=0,z=0};player.alive=true;player.access=true;M.open=true;M.layers=1
M.cells={{x=11,y=11,z=0}};M.byKey={['11:11:0']=M.cells[1]};M.cache.adjacency={['11:11:0']={}}
M.cache.topologyFloor=0;M.cache.reach=nil
local previousLayout
for _,size in ipairs({{1280,800},{640,480},{3840,2160}}) do
 ScrW=function() return size[1] end;ScrH=function() return size[2] end
 for _,scale in ipairs({.5,1,1.5}) do for _,opacity in ipairs({0,.3,1}) do for _,width in ipairs({21,29,37}) do
  preferences.lod_map_scale.value=scale;preferences.lod_map_opacity.value=opacity;M.gridWidth=width
  local layout=M:PresentationLayout()
  assert(layout.x>=20-1e-8 and layout.y>=20-1e-8 and layout.x+layout.width<=size[1]-20+1e-8 and layout.y+layout.height<=size[2]-20+1e-8,'map outside window')
  assert(layout.requested==scale and preferences.lod_map_scale.value==scale,'fit changed saved preference')
  local builds=matrixBuilds
  assert(M:PresentationLayout()==layout and matrixBuilds==builds,'static presentation reallocates a Matrix')
  local revision,reach=M.cache.revision,M.cache.reach
  local topologies,requests=M.stats.topologyBuilds,M.stats.mapRequests
  alpha=.8;circles={};lines={};rects={};panels={};texts={};peerMarkers={}
  hooks.HUDPaint.LOD_MinimapHUD();quadrant()
  assert(alpha==.8 and #matrices==0,'map leaked alpha/model matrix into another HUD')
  assert(M.stats.topologyBuilds==topologies and M.stats.mapRequests==requests and M.cache.revision==revision,'presentation rebuilt/transferred topology')
  if opacity==0 then
   assert(#circles==0 and #rects==0 and #texts==0 and #panels==0,'transparent map still paints')
  else
   assert(#circles==2 and #panels==1 and #rects==5,'map layers duplicated/missing')
   local c=circles[2];local panel=panels[1]
   near(panel.x,layout.x,'panel x');near(panel.y,layout.y,'panel y');near(panel.w,layout.width,'panel width');near(panel.h,layout.height,'panel height')
   near(c.x,layout.x+(26+10.5*layout.gridSize/width)*layout.scale,'scaled marker x')
   near(c.y,layout.y+(68+10.5*layout.gridSize/width)*layout.scale,'scaled marker y')
   near(c.r,3*layout.scale,'marker radius');near(c.alpha,.8*opacity,'marker opacity')
   for _,layer in ipairs({panels,rects,texts,lines,peerMarkers}) do for _,entry in ipairs(layer) do near(entry.alpha,.8*opacity,'overlay opacity') end end
   local a,b,cq,d=rects[2],rects[3],rects[4],rects[5]
   near(a.x,layout.x+26*layout.scale,'quadrant origin x');near(a.y,layout.y+68*layout.scale,'quadrant origin y')
   near(a.w,layout.gridSize*11/width*layout.scale,'odd-grid tie width')
   near(a.h,layout.gridSize*11/width*layout.scale,'odd-grid tie height')
   near(a.x+a.w,b.x,'quadrant x seam');near(a.y+a.h,cq.y,'quadrant y seam')
   near(b.x+b.w,layout.x+(26+layout.gridSize*21/width)*layout.scale,'expanded-grid base footprint')
   near(d.y+d.h,layout.y+(68+layout.gridSize*21/width)*layout.scale,'quadrant base height')
  end
  previousLayout=layout
 end end end
end
-- Early loading/preparation exits and thrown drawing callbacks restore state.
preferences.lod_map_scale.value=1.5;preferences.lod_map_opacity.value=.25;M.open=true;alpha=.7
for _,mode in ipairs({'loading','preparing','throwing'}) do
 local indexed,topology=M.cache.indexedRevision,M.cache.topologyRevision
 if mode=='loading' then M.cache.indexedRevision=-1 elseif mode=='preparing' then M.cache.topologyRevision=-1 end
 local paint=draw.SimpleText
 if mode=='throwing' then draw.SimpleText=function() error('deliberate paint failure') end end
 local ok,err=pcall(hooks.HUDPaint.LOD_MinimapHUD)
 assert(ok==(mode~='throwing') and (ok or tostring(err):find('deliberate paint failure',1,true)),'drawing error lost')
 assert(alpha==.7 and #matrices==0,'early exit/error leaked drawing state')
 draw.SimpleText=paint;M.cache.indexedRevision=indexed;M.cache.topologyRevision=topology
end
-- Closed maps create no presentation work; opacity never bypasses Magic expiry.
M.open=false;local reads,builds=alphaReads,matrixBuilds;quadrant();hooks.HUDPaint.LOD_MinimapHUD()
assert(alphaReads==reads and matrixBuilds==builds,'closed map performs presentation work')
M.open=true;player.magic=0;preferences.lod_map_opacity.value=0
hooks.Think.LOD_MinimapMagicHeartbeat();assert(not M.open,'transparent map bypassed forced zero-Magic close')
print('MINIMAP_PLAYER_PASS: blue marker; expanded topology; Q/M/VR access/focus; shared panel/text/quadrant transforms and alpha; 81 size/opacity/grid/window cases; cached Matrix; no topology rebuild; draw-state cleanup; Magic expiry')
return {hooks=hooks,Map=M,preferences=preferences,player=player,wall=wall}
