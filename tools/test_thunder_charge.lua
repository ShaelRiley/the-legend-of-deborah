-- Real dispatcher, generated items, graph gates, safe travel, movement, Magic
-- damage/status and hit-stun. Only native traces/transport/entities are doubles.
local env=dofile('tools/test_equipment_economy_runtime.lua')
local root='gamemodes/legend_of_deborah/gamemode/lod/'
local E,R,S,Rules=LOD.Equipment,env.Run,LOD.RPGStatusElements,LOD.RPGAbilityRules
local V=getmetatable(Vector())
V.__add=function(a,b) return Vector(a.x+b.x,a.y+b.y,a.z+b.z) end
V.__sub=function(a,b) return Vector(a.x-b.x,a.y-b.y,a.z-b.z) end
V.__mul=function(a,b) return Vector(a.x*b,a.y*b,a.z*b) end
function V:Length() return math.sqrt(self:DistToSqr(Vector())) end
function V:Distance(b) return (self-b):Length() end
function V:GetNormalized() return self*(1/math.max(self:Length(),.001)) end
function V:Normalize() local n=self:GetNormalized();self.x,self.y,self.z=n.x,n.y,n.z end
local now=200;CurTime=function() return now end
MOVETYPE_WALK,MASK_PLAYERSOLID,CONTENTS_SLIME,CONTENTS_WATER,DMG_ENERGYBEAM=2,1,16,32,8
bit=bit or {};bit.band=function(a,b) return a & b end;bit.bor=function(a,b) return a | b end
engine={TickInterval=function() return .015 end}
LOD.MazeGenerator={CellKey=function(x,y,z) return x..':'..y..':'..z end}
LOD.Config.Maze.Width,LOD.Config.Maze.Height=9,1
LOD.Config.Maze.CellSize,LOD.Config.Maze.LevelHeight,LOD.Config.Maze.Origin=384,384,Vector()
function LOD.MazeBuilder:CellCenter(c) return Vector((c.x-5)*384,0,c.z*384) end
LOD.MazeNavigator={};dofile(root..'sv_maze_navigator.lua')
LOD.ProgressionDirector=LOD.ProgressionDirector or {}
dofile(root..'sv_warden_arena.lua')
local graph={Cells={},Width=9,Height=1,Layers=1,VerticalEdges={},Progression={
 Gates={{edgeKey='5:1:0|6:1:0'}},Warden={lock={edgeKey='6:1:0|7:1:0'}},JailEdge={edgeKey='7:1:0|8:1:0'}}}
for x=1,9 do
 local c={x=x,y=1,z=0,neighbors={}};graph.Cells[x..':1:0']=c
 if x>1 then c.neighbors[(x-1)..':1:0']=true end
 if x<9 then c.neighbors[(x+1)..':1:0']=true end
end
R.State.Graph,R.State.BuildReady,R.State.GatesOpen=graph,true,{true}
R.State.WardenStarted,R.State.JailDoorOpen=false,true
local p,enemy,ally=env.actor('thunder'),env.actor('enemy',true),env.actor('ally')
for _,a in ipairs({p,enemy,ally}) do
 a.position=Vector(0,0,2);a.ps.lives=3;a.ps.deploymentComplete=true;a.ps.equipmentLifeSerial=1
 function a:GetPos() return self.position end
 function a:GetMoveType() return self.moveType or MOVETYPE_WALK end
 function a:GetHull() return Vector(-16,-16,0),Vector(16,16,72) end
 function a:InVehicle() return self.vehicle or false end
 function a:OnGround() return not self.airborne end
 function a:GetClass() return self.LODHostile and 'lod_hostile' or 'player' end
 function a:WorldSpaceCenter() return self.position+Vector(0,0,36) end
 function a:GetOwner() end
 function a:SetVelocity(v) self.velocity=v end
 a.SetLocalVelocity=a.SetVelocity
 function a:TakeDamageInfo(info)
  if self.defended then info:SetDamage(0) end
  S:ObserveDamage(self,info);self.hp=self.hp-info:GetDamage();self.lastInfo=info
 end
end
local aim=Vector(1,0,0);p.GetAimVector=function() return aim end
local floor={valid=true,LODGeneratedGeometry=true,GetClass=function() return 'lod_static_box' end,GetBoxKind=function() return 1 end}
local wall,contact,holes,water,hurt,ceiling=false,nil,false,false,false,false
util.TraceLine=function(d)
 return {Hit=not holes or math.abs(d.start.y)<1,HitPos=Vector(d.start.x,d.start.y,0),HitNormal=Vector(0,0,1),Entity=floor}
end
util.TraceHull=function(d)
 if ceiling then return {StartSolid=true} end
 local fraction=1;local target
 if wall and d.endpos.x>=wall then fraction=math.max(0,(wall-d.start.x)/math.max(.001,d.endpos.x-d.start.x)) end
 if contact and d.endpos.x>=contact.position.x-32 then
  local f=math.max(0,(contact.position.x-32-d.start.x)/math.max(.001,d.endpos.x-d.start.x))
  if f<fraction then fraction,target=f,contact end
 end
 return {Hit=fraction<1,Fraction=fraction,Entity=target}
end
util.PointContents=function() return water and CONTENTS_WATER or 0 end
ents={FindInBox=function() return hurt and {{GetClass=function() return 'trigger_hurt' end}} or {} end}
net.Broadcast=function() end
for _,name in ipairs({'Entity','String','UInt','Float','Vector'}) do net['Write'..name]=function() end end
game={GetWorld=function() end}
DamageInfo=function()
 local info={}
 for _,n in ipairs({'Attacker','Inflictor','Damage','DamageType','DamagePosition','DamageForce'}) do
  info['Set'..n]=function(self,v) self[n]=v end;info['Get'..n]=function(self) return self[n] end
 end
 return info
end
LOD.Magic._EnsureState=function(_,actor) return actor.ps end
LOD.Magic._Sync=function() end;LOD.Magic.Stats={targets=0,damage=0}
LOD.CombatRolls._Send=function() end
LOD.CombatRolls._DamageEventText=function() return 'damage' end
LOD.CombatRolls._RNG=function() return {Int=function(_,lo) return lo end,Float=function() return 1 end} end
LOD.FactionManager.IsOpponent=function(_,a,b) return a==p and b==enemy end
dofile(root..'sv_magic_forms.lua');dofile(root..'sv_equipment_moves.lua')
dofile(root..'sv_safe_teleport.lua');dofile(root..'sv_equipment_thunder.lua')
dofile(root..'sv_m3_hit_feedback.lua')
local T=LOD.SafeTeleport
local state=E:Ensure(p.ps)
local item=E:NewItem(p,'thunder_hat','proof')
assert(E:ValidateWearable(item) and item.rarity>=2 and E:InnateValue('thunder_hat',100)==60)
assert(E:AcquireWearable(state,item,false));assert(E:Equip(state,item.id,'head'))
local seen={}
for seed=1,400 do
 local g=E:Generate(seed,seed,'thunder_hat','thunder:'..seed)
 assert(E:ValidateWearable(g) and E:Value(g)==g.budget and g.rarity>=2)
 seen[E:RewardWearableFamily(seed) or 'generic']=true
end
assert(seen.thunder_hat and seen.generic and seen.fighting_gloves and seen.invisibility_ring and seen.psychic_crown)
local forged=table.Copy(item);forged.version=1;assert(not E:ValidateWearable(forged))
assert(E:Description(item):find('↑ ↓ ↑',1,true))
local function cast()
 local ok
 for _,t in ipairs({'UP','DOWN','UP'}) do now=now+.1;ok=E:DirectionToken(p,t) end
 return ok
end
local function reset()
 E:ClearTransient(p);now=now+7;p.position=Vector(0,0,2);p.ps.magic=100
 enemy.hp=100;enemy.LODHitStunUntil=nil;enemy.LODNextHitStun=nil;enemy.defended=false
 contact=nil;wall=false;holes=false;water=false;hurt=false;ceiling=false;aim=Vector(1,0,0)
 p.airborne=false;p.vehicle=false;p.moveType=nil;p.LODForcedMovementUntil=nil
 S:CureNegative(p);S:CureNegative(enemy);assert(E:Equip(state,item.id,'head'))
end
local function move(dt)
 now=now+(dt or .015)
 local data={velocity=p.velocity,max=520}
 function data:GetVelocity() return self.velocity end
 function data:SetVelocity(v) self.velocity=v end
 function data:GetMaxSpeed() return self.max end
 function data:SetMaxSpeed(v) self.max=v end
 data.GetMaxClientSpeed=data.GetMaxSpeed;data.SetMaxClientSpeed=data.SetMaxSpeed
 function data:SetForwardSpeed(v) assert(v==0) end
 data.SetSideSpeed=data.SetForwardSpeed
 Rules:ApplyVoluntaryDash(p,data)
 p.velocity=data.velocity;p.position=p.position+p.velocity*.015
 return data
end
reset();assert(cast() and p.ps.magic==76)
local dash=assert(Rules.VoluntaryDashes[p]);assert(dash.remaining==1152)
assert(not cast() and p.ps.magic==76,'Cooldown cannot spend twice')
-- Separate warning check (a second recipe itself advances the harness clock).
reset();assert(cast());move(.1);assert(p.position.x==0 and p.velocity.x==0)
aim=Vector(0,1,0);move(.16);assert(p.velocity.x==1440 and p.velocity.y==0,'Aim is frozen')
for i=1,60 do move() end
assert(not Rules.VoluntaryDashes[p] and p.position.x<=1152 and p.position.x>1000 and p.nw.LOD_ThunderUntil==0)
-- Native solid cover, every graph lock, full footprint and hazard support.
reset();wall=100;assert(T:ChargePath(p,graph,p.position,aim,1152)<100)
for _,kind in ipairs({'normal','warden','jail'}) do
 reset()
 if kind=='normal' then R.State.GatesOpen[1]=false
 elseif kind=='warden' then R.State.WardenStarted=true
 else R.State.JailDoorOpen=false end
 local distance=T:ChargePath(p,graph,p.position,aim,1152)
 assert(distance<(kind=='normal' and 176 or kind=='warden' and 560 or 944),kind)
 R.State.GatesOpen[1]=true;R.State.WardenStarted=false;R.State.JailDoorOpen=true
end
for _,kind in ipairs({'holes','water','hurt','ceiling','stair','void','air','vehicle','forced','edge','fakefloor'}) do
 reset()
 if kind=='holes' then holes=true elseif kind=='water' then water=true elseif kind=='hurt' then hurt=true
 elseif kind=='ceiling' then ceiling=true elseif kind=='air' then p.airborne=true
 elseif kind=='vehicle' then p.vehicle=true elseif kind=='forced' then p.LODForcedMovementUntil=now+10
 elseif kind=='stair' then graph.VerticalEdges={{a=graph.Cells['5:1:0'],b={x=5,y=1,z=1}}}
 elseif kind=='void' then graph.WardenVoid={['5:1:0']=true}
 elseif kind=='edge' then p.position=Vector(0,190,2)
 elseif kind=='fakefloor' then floor.LODGeneratedGeometry=false end
 assert(not cast() and p.ps.magic==100,kind)
 graph.VerticalEdges={};graph.WardenVoid=nil;floor.LODGeneratedGeometry=true
end
reset();wall=16;assert(not cast() and p.ps.magic==100,'Insufficient safe distance is free')
reset();assert(cast());R.State.GatesOpen[1]=false
for i=1,40 do move() end
assert(not Rules.VoluntaryDashes[p] and p.position.x<176,'Gate closing during warning stops full hull')
R.State.GatesOpen[1]=true
-- Actual shared electric packet, one surviving effective hit, native stun authority.
for _,kind in ipairs({'enemy','ally','defended','dead','retrigger','latched','weakness'}) do
 reset();contact=kind=='ally' and ally or enemy;contact.position=Vector(100,0,2)
 enemy.defended=kind=='defended';if kind=='dead' then enemy.hp=1 end
 if kind=='retrigger' then enemy.LODNextHitStun=now+20 end
 if kind=='latched' then enemy.LODDeadcrabState='latched' end
 if kind=='weakness' then enemy.LODElement='earth' end
 assert(cast())
 for i=1,35 do move() end
 assert(not Rules.VoluntaryDashes[p] and p.ps.magic==76,kind)
 if kind=='enemy' or kind=='weakness' then
  assert(enemy.hp<100 and enemy.LODHitStunUntil,'Effective survivor must stun')
  assert(S:DamageContext(enemy.lastInfo).element=='electric' and enemy.lastInfo:GetAttacker()==p)
  if kind=='weakness' then assert(S:DamageContext(enemy.lastInfo).elementResolution.hitStunMultiplier==2.5) end
 else assert(not enemy.LODHitStunUntil,kind..' cannot stun') end
 if kind=='ally' or kind=='defended' then assert(enemy.hp==100 and ally.hp==100) end
 local hp=enemy.hp;for i=1,10 do move() end;assert(enemy.hp==hp,'Only one hit')
 enemy.LODDeadcrabState=nil;enemy.LODElement=nil
end
-- Delayed work rejects ownership, identity and every relevant lifecycle change.
for _,kind in ipairs({'source','record','life','identity','state','run','graph','seed','soldier','dead','inactive',
 'freeze','cleared','deployment','muted','held','air','teleport','expiry'}) do
 reset();assert(cast());local old=Rules.VoluntaryDashes[p]
 local ps,run,oldGraph,seed,identity=p.ps,R.State,R.State.Graph,R.State.LevelSeed,p.ps.identity
 if kind=='source' then E:UnequipItem(state,item.id);assert(not Rules.VoluntaryDashes[p]);E:Equip(state,item.id,'head')
 elseif kind=='record' then state.items[item.id]=table.Copy(item)
 elseif kind=='life' then p.ps.equipmentLifeSerial=p.ps.equipmentLifeSerial+1
 elseif kind=='identity' then p.ps.identity={}
 elseif kind=='state' then p.ps=table.Copy(p.ps)
 elseif kind=='run' then R.State=table.Copy(R.State)
 elseif kind=='graph' then R.State.Graph=table.Copy(graph)
 elseif kind=='seed' then R.State.LevelSeed=seed+1
 elseif kind=='soldier' then p.soldier=true elseif kind=='dead' then p.hp=0
 elseif kind=='inactive' then p.active=false elseif kind=='freeze' then R.State.SimulationFrozen=true
 elseif kind=='cleared' then R.State.LevelCleared=true elseif kind=='deployment' then p.ps.deploymentComplete=false
 elseif kind=='muted' or kind=='held' then S:Apply(p,kind,p,{direct=true,duration=5})
 elseif kind=='air' then p.airborne=true elseif kind=='teleport' then p.position=Vector(500,0,2)
 elseif kind=='expiry' then now=old.ends end
 move();assert(not Rules.VoluntaryDashes[p],kind);assert(p.ps.magic==76,kind..' no refund')
 p.ps=ps;R.State=run;R.State.Graph=oldGraph;R.State.LevelSeed=seed;p.ps.identity=identity
 state.items[item.id]=item;p.hp=100;p.soldier=false;p.active=true;p.ps.deploymentComplete=true
 R.State.SimulationFrozen=nil;R.State.LevelCleared=nil
 reset();assert(cast());local fresh=Rules.VoluntaryDashes[p]
 assert(not Rules:StopVoluntaryDash(p,old) and Rules.VoluntaryDashes[p]==fresh,'Stale end cannot cancel fresh charge')
end
reset();E:UnequipItem(state,item.id);assert(not cast() and p.ps.magic==100,'Backpack is not ownership')
reset();p.ps.magic=23;assert(not cast() and p.ps.magic==23)
reset();S:Apply(p,'muted',p,{direct=true,duration=5});assert(not cast() and p.ps.magic==100)
reset();S:Apply(p,'held',p,{direct=true,duration=5});assert(not cast() and p.ps.magic==100)
print('THUNDER_CHARGE_PASS: generated grants, cost/cooldown, warning, straight bounded motion, native/graph/floor safety, actual electric damage/stun, ally/defense exclusion, ownership/lifecycle/stale rejection')

-- Real client decoder/draw hook: bounded, depth tested, cancellation and expiry.
local receivers={};net.Receive=function(name,fn) receivers[name]=fn end
Material=function(path) return path end;Color=function(...) return {...} end
local eye=Vector();EyePos=function() return eye end
local beams,sprites=0,0
render={SetMaterial=function() end,DrawBeam=function(a,b,width)
 beams=beams+1;assert(width==6 or width==12)
end,DrawSprite=function() sprites=sprites+1 end}
dofile(root..'cl_equipment_thunder.lua')
local function packet()
 local values={Vector(0,0,2),Vector(100,0,2)}
 local times={now+.25,now+1.05}
 net.ReadEntity=function() return p end
 net.ReadVector=function() return table.remove(values,1) end
 net.ReadFloat=function() return table.remove(times,1) end
 p:SetNW2Float('LOD_ThunderUntil',now+1.05)
 receivers.LOD_ThunderChargeFX()
end
local draw=assert(env.hooks.LOD_ThunderCharge)
packet();draw(true,false);draw(false,true);assert(beams==0)
draw(false,false);assert(beams==1 and sprites==1)
now=now+.3;draw(false,false);assert(beams==2 and sprites==2)
eye=Vector(5000,0,0);draw(false,false);assert(beams==2)
eye=Vector();p:SetNW2Float('LOD_ThunderUntil',0);draw(false,false);assert(beams==2)
packet();now=now+2;draw(false,false);assert(beams==2)
print('THUNDER_FX_PASS: native packet decode, bounded warning/trail, depth/sky/distance exclusions, cancellation and expiry')
