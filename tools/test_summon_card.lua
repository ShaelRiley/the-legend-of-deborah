-- Real graph locks, equipment transactions and relocation; Source traces/net
-- are boundary doubles with independent occupancy/support failure controls.
local env=dofile('tools/test_equipment_economy_runtime.lua')
local root='gamemodes/legend_of_deborah/gamemode/lod/'
local E,R=LOD.Equipment,env.Run
local V=getmetatable(Vector())
V.__add=function(a,b) return Vector(a.x+b.x,a.y+b.y,a.z+b.z) end
V.__sub=function(a,b) return Vector(a.x-b.x,a.y-b.y,a.z-b.z) end
local now=200;CurTime=function() return now end
MOVETYPE_WALK,MASK_PLAYERSOLID,CONTENTS_SLIME,CONTENTS_WATER=2,1,16,32
bit=bit or {};bit.band=function(a,b) return a & b end;bit.bor=function(a,b) return a | b end
LOD.MazeGenerator={CellKey=function(x,y,z) return x..':'..y..':'..z end}
LOD.Config.Maze.Width,LOD.Config.Maze.Height=5,1
LOD.Config.Maze.CellSize,LOD.Config.Maze.LevelHeight,LOD.Config.Maze.Origin=384,384,Vector()
function LOD.MazeBuilder:CellCenter(c) return Vector((c.x-3)*384,(c.y-1)*384,c.z*384) end
LOD.MazeNavigator={};dofile(root..'sv_maze_navigator.lua')
LOD.ProgressionDirector=LOD.ProgressionDirector or {}
dofile(root..'sv_warden_arena.lua') -- actual Warden and jail lock wrapper
local graph={Cells={},Width=5,Height=1,Layers=1,VerticalEdges={},Progression={
 Gates={{edgeKey='2:1:0|3:1:0'}},Warden={lock={edgeKey='3:1:0|4:1:0'}},JailEdge={edgeKey='4:1:0|5:1:0'}}}
for x=1,5 do
 local c={x=x,y=1,z=0,neighbors={}};graph.Cells[x..':1:0']=c
 if x>1 then c.neighbors[(x-1)..':1:0']=true end
 if x<5 then c.neighbors[(x+1)..':1:0']=true end
end
R.State.Graph,R.State.BuildReady,R.State.GatesOpen=graph,true,{true}
R.State.WardenStarted,R.State.JailDoorOpen=false,true
local actors={}
local function hero(id,x)
 local p=env.actor(id);actors[#actors+1]=p
 p.position=Vector(x,0,2);p.ps.lives=3;p.ps.deploymentComplete=true;p.ps.equipmentLifeSerial=1
 function p:GetPos() return self.position end
 function p:SetPos(pos) self.position=pos;self.moves=(self.moves or 0)+1 end
 function p:SetLocalVelocity(v) self.velocity=v end
 function p:GetMoveType() return self.moveType or MOVETYPE_WALK end
 function p:InVehicle() return self.vehicle or false end
 function p:GetHull() return Vector(-16,-16,0),Vector(16,16,self.hullHeight or 72) end
 function p:GetClass() return 'player' end
 function p:Nick() return self.id end
 function p:GetNW2String(k,d) return self.nw[k] or d end
 return p
end
local owner,target=hero('owner',0),hero('target',-700)
player.GetAll=function() return actors end
local callbacks,packet={},nil
net.Receive=function(name,fn) callbacks[name]=fn end
net.Start=function(name) packet={name=name,values={}} end
for _,t in ipairs({'UInt','Bool','Entity','String'}) do net['Write'..t]=function(v) packet.values[#packet.values+1]=v end end
net.Send=function() end
local floor={valid=true,LODGeneratedGeometry=true,GetClass=function() return 'lod_static_box' end,GetBoxKind=function() return 1 end}
local blocked,noFloor,edgeHole,water,hurt,ceiling=false,false,false,false,false,false
local function hit(pos) return {Hit=not noFloor,HitPos=Vector(pos.x,pos.y,0),HitNormal=Vector(0,0,1),Entity=floor} end
util.TraceHull=function(d)
 if d.start.z~=d.endpos.z then return hit(d.start) end
 local occupied=false
 for _,p in ipairs(actors) do
  if p~=d.filter and p:Alive() and math.abs(p.position.x-d.start.x)<32 and math.abs(p.position.y-d.start.y)<32 then occupied=true end
 end
 return {Hit=blocked or occupied or ceiling and d.maxs.z>60,StartSolid=blocked}
end
util.TraceLine=function(d) if edgeHole then return {Hit=false} end;return hit(d.start) end
util.PointContents=function() return water and CONTENTS_SLIME or 0 end
ents={FindInBox=function() return hurt and {{GetClass=function() return 'trigger_hurt' end}} or {} end}
dofile(root..'sv_safe_teleport.lua');dofile(root..'sv_summon_card.lua')
local T,N=LOD.SafeTeleport,LOD.MazeNavigator
assert(E.Definitions.summon_card and E:Prompt(E.Definitions.summon_card):find('SUMMON HERE',1,true))
assert(not T:CellAt(graph,Vector(90000,0,2)) and N:WorldToCell(graph,Vector(90000,0,2)))
local dest=assert(T:Resolve(target,owner,'throw'));assert(T:CellAt(graph,dest).x~=3)
dest=assert(T:Resolve(target,owner,'drink'));assert(T:CellAt(graph,dest).x==3 and dest:DistToSqr(owner.position)>=32^2)
R.State.GatesOpen[1]=false;assert(not T:Resolve(target,owner,'drink'));R.State.GatesOpen[1]=true
target.position=Vector(700,0,2);R.State.WardenStarted=true
assert(not T:Resolve(target,owner,'drink'));R.State.Warden={dead=true};assert(T:Resolve(target,owner,'drink'))
target.position=Vector(768,0,2);R.State.JailDoorOpen=false
assert(not T:Resolve(target,owner,'drink'));R.State.JailDoorOpen=true
target.position=Vector(-700,0,2)
for _,failure in ipairs({'blocked','floor','edge','water','hurt','ceiling'}) do
 blocked=failure=='blocked';noFloor=failure=='floor';edgeHole=failure=='edge';water=failure=='water';hurt=failure=='hurt';ceiling=failure=='ceiling'
 assert(not T:Resolve(target,owner,'drink'),failure..' must fail closed')
end
blocked,noFloor,edgeHole,water,hurt,ceiling=false,false,false,false,false,false
local c=graph.Cells['3:1:0'];graph.VerticalEdges={{a=c,b={x=3,y=1,z=1}}}
assert(not T:Landing(target,graph,c,Vector(64,0,0)),'No stair transition landing')
graph.VerticalEdges={};graph.WardenVoid={['3:1:0']=true}
assert(not T:Landing(target,graph,c,Vector(64,0,0)));graph.WardenVoid=nil
assert(not T:Landing(target,graph,c,Vector(180,0,0)),'Full hull stays inside cell margin')
local originalHull=target.GetHull
target.GetHull=function() return Vector(-200,-200,0),Vector(200,200,100) end
assert(not T:Resolve(target,owner,'drink'),'Oversized Hero cannot fit');target.GetHull=originalHull
floor.LODGeneratedGeometry=false;assert(not T:Resolve(target,owner,'drink'),'Props are not supported landings');floor.LODGeneratedGeometry=true
local state=E:Ensure(owner.ps);assert(E:Grant(owner,'summon_card',3));assert(E:Equip(state,'summon_card','throwable'));assert(E:Activate(owner))
local function count() return state.items.summon_card and state.items.summon_card.count or 0 end
local function begin(mode)
 now=now+2;assert(E:Use(owner,mode or 'drink'))
 local s=assert(E.SummonSessions[owner]);assert(packet.name=='LOD_SummonCardMenu' and packet.values[1]==s.nonce)
 return s
end
local function unchanged(s,t) local n=count();assert(not E:ChooseSummonCard(owner,s.nonce,t or target));assert(count()==n) end
local s=begin();assert(count()==3,'Opening picker spends nothing')
assert(not E:ChooseSummonCard(owner,s.nonce+1,target));assert(E.SummonSessions[owner]==s)
unchanged(s,owner)
s=begin();now=now+15;unchanged(s)
s=begin();target.ps.equipmentLifeSerial=2;unchanged(s)
s=begin();owner.ps.equipmentLifeSerial=2;unchanged(s)
s=begin();R.State.LevelSeed=R.State.LevelSeed+1;unchanged(s)
s=begin();local oldGraph=R.State.Graph;R.State.Graph=table.Copy(graph);unchanged(s);R.State.Graph=oldGraph
s=begin();local oldPS=target.ps;target.ps=table.Copy(oldPS);unchanged(s);target.ps=oldPS
s=begin();target.soldier=true;unchanged(s);target.soldier=false
s=begin();target.active=false;unchanged(s);target.active=true
s=begin();target.ps.deploymentComplete=false;unchanged(s);target.ps.deploymentComplete=true
s=begin();target.hp=0;unchanged(s);target.hp=100
s=begin();target.ps.lives=0;unchanged(s);target.ps.lives=3
s=begin();target.vehicle=true;unchanged(s);target.vehicle=false
s=begin();owner.activeClass='weapon_lod_crowbar';unchanged(s);assert(E:Activate(owner))
s=begin();local item=state.items.summon_card;state.items.summon_card=table.Copy(item);unchanged(s)
s=begin();R.State.GatesOpen[1]=false;unchanged(s);R.State.GatesOpen[1]=true
s=begin();blocked=true;unchanged(s);blocked=false
s=begin();owner.position=Vector(90000,0,2);unchanged(s);owner.position=Vector(0,0,2)
s=begin();R.State.SimulationFrozen=true;unchanged(s);R.State.SimulationFrozen=false
s=begin();E:ClearTransient(owner);unchanged(s)
s=begin('throw');local magic=owner.ps.magic
LOD.RPGAbilityRules.VoluntaryDashes={[target]={}};target.velocity=Vector(100,100,-800);target.LODForcedMovementUntil=now+5
net.ReadUInt=function() return s.nonce end;net.ReadEntity=function() return target end
callbacks.LOD_SummonCardChoose(65,owner);assert(count()==3,'Oversized request ignored')
callbacks.LOD_SummonCardChoose(48,owner)
assert(count()==2 and target.moves==1 and target.velocity:DistToSqr(Vector())==0 and owner.ps.magic==magic)
assert(not LOD.RPGAbilityRules.VoluntaryDashes[target] and not target.LODForcedMovementUntil)
assert(not E:Use(owner,'throw'),'Use cooldown after commit')
assert(not E:ChooseSummonCard(owner,s.nonce,target) and count()==2,'Replay cannot move or spend')
assert(T:CellAt(graph,target.position).x~=3)
for i=1,2 do s=begin('drink');assert(E:ChooseSummonCard(owner,s.nonce,target)) end
assert(count()==0 and not state.slots.throwable and target.moves==3)
assert(not E:Use(owner,'drink'),'Empty stack cannot open picker')
local found=0
for i=1,128 do
 local options={equipmentEligible=true,staticId='card-proof-'..i}
 local _,a=E:PrepareReward('owner','consumable',{itemId='healing_potion'},options)
 local _,b=E:PrepareReward('owner','consumable',{itemId='healing_potion'},options)
 assert(a.itemId==b.itemId,'Natural drop repeatable')
 if a.itemId=='summon_card' then found=found+1 end
 local _,reserved=E:PrepareReward('owner','consumable',{itemId='healing_potion'},{staticId=options.staticId})
 assert(reserved.itemId=='healing_potion','Authored reward preserved')
end
assert(found>0 and found<128)
assert(E:AddConsumable(state,'summon_card',3) and not E:AddConsumable(state,'summon_card',1))
assert(state.items.summon_card.count==3,'Stack overflow remains atomic')
print('SUMMON_CARD_PASS: graph locks, hull/support/hazards, lifecycle, net replay, resource commit, natural rewards')

-- Actual picker callback and lifecycle, with native VGUI/transport boundaries.
local nodes={};local panel={};panel.__index=panel
for _,method in ipairs({'SetTitle','SetFont','SetTextColor','SetWrap','SetTooltip','Dock','DockMargin','SetEnabled'}) do
 panel[method]=function(self,value) self[method]=value end
end
function panel:SetText(t) self.text=t end
function panel:SetPos(x,y) self.x,self.y=x,y end
function panel:SetSize(w,h) self.w,self.h=w,h end
function panel:SetWide(w) self.w=w end
function panel:SetTall(h) self.h=h end
function panel:GetWide() return self.w end
function panel:GetTall() return self.h end
function panel:Center() end;function panel:MakePopup() end
function panel:Remove() self.valid=false end
vgui={Create=function(kind,parent) local n=setmetatable({valid=true,kind=kind,parent=parent},panel);nodes[#nodes+1]=n;return n end}
local close
LOD.UI={Colors={red={},ink={}},Paper=function() end,
 SelectPage=function(self,page) self.ActivePage=page end,
 CloseButton=function(_,_,fn) close=fn end}
local width,height=640,480;ScrW=function() return width end;ScrH=function() return height end
RealTime=CurTime;LocalPlayer=function() return owner end
net.SendToServer=function() end
NULL={};TOP,RIGHT,FILL=1,2,3
E:Equip(state,'summon_card','throwable');E:Activate(owner)
dofile(root..'cl_summon_card.lua')
local function open()
 local reads={111,1};net.ReadUInt=function() return table.remove(reads,1) end
 net.ReadBool=function() return true end;net.ReadEntity=function() return target end
 net.ReadString=function() return 'A Hero With A Long Display Name' end
 nodes={};callbacks.LOD_SummonCardMenu()
 return assert(E.SummonFrame)
end
local frame=open();assert(frame.w<=width-32 and frame.h<=height-32)
local button,label
for _,n in ipairs(nodes) do
 if n.text=='Summon' then button=n end
 if n.text=='A Hero With A Long Display Name' then label=n end
end
assert(label.SetWrap and label.SetTooltip==label.text,'Full Hero name retained')
button.DoClick();assert(not frame.valid and not E.SummonFrame)
assert(packet.name=='LOD_SummonCardChoose' and packet.values[1]==111 and packet.values[2]==target)
frame=open();close();assert(packet.values[2]==NULL and not frame.valid,'Cancel sends no position and spends nothing')
frame=open();now=now+16;frame.Think();assert(not frame.valid,'Expired picker closes')
frame=open();LOD.UI.ActivePage='sheet';frame.Think();assert(not frame.valid and LOD.UI.ActivePage=='sheet')
frame=open();owner.hp=0;frame.Think();assert(not frame.valid);owner.hp=100
width,height=1920,1080;frame=open();assert(frame.w==520 and frame.h==480)
print('SUMMON_CARD_UI_PASS: bounded picker, full-name tooltip, exact target/nonce, cancel, expiry, page/death close')
