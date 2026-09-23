-- Production equipment/contact/combat/safe-bounce test; native boundaries only.
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
local p,enemy,ally=env.actor('plumber'),env.actor('enemy',true),env.actor('ally')
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
local floor={valid=true,LODGeneratedGeometry=true,GetClass=function() return 'lod_static_box' end,
 GetBoxKind=function() return 1 end,IsPlayer=function() return false end,IsNPC=function() return false end}
local contact,holes,water,hurt,ceiling,side,cover=enemy,false,false,false,false,false,false
local clearance=60
util.TraceLine=function(d)
 return {Hit=not holes or math.abs(d.start.y)<1,HitPos=Vector(d.start.x,d.start.y,0),HitNormal=Vector(0,0,1),Entity=floor}
end
util.TraceHull=function(d)
 if d.endpos.z>d.start.z then
  return {Hit=clearance<60,Fraction=clearance/60,StartSolid=ceiling}
 end
 return {Hit=true,Entity=cover and floor or contact,HitNormal=side and Vector(1,0,0) or Vector(0,0,1)}
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
dofile(root..'sv_safe_teleport.lua');dofile(root..'sv_equipment_stomp.lua')
dofile(root..'sv_m3_hit_feedback.lua')
local T=LOD.SafeTeleport
DMG_CLUB=128
NULL={}
for _,a in ipairs({p,enemy,ally}) do
 function a:IsNPC() return self.LODHostile==true end
 function a:WorldSpaceAABB() return self.position+Vector(-16,-16,0),self.position+Vector(16,16,72) end
 function a:GetGroundEntity() return self.ground end
 function a:SetGroundEntity(g) self.ground=g;self.airborne=g==NULL end
 function a:Crouching() return false end
 function a:GetGravity() return self.gravity or 0 end
end
local nativeCV=GetConVar
GetConVar=function(name) if name=='sv_gravity' then return {GetFloat=function() return 600 end} end;return nativeCV(name) end

local state=E:Ensure(p.ps)
local item=E:NewItem(p,'plumber_boots','proof')
assert(E:ValidateWearable(item) and item.rarity>=2 and E:InnateValue('plumber_boots',100)==50)
assert(E:AcquireWearable(state,item,false) and E:Equip(state,item.id,'feet'))
assert(E:Description(item):find('passive',1,true) and E:Description(item):find('Landing from above',1,true))
local seen={}
for seed=1,400 do
 local g=E:Generate(seed,seed,'plumber_boots','plumber:'..seed)
 assert(E:ValidateWearable(g) and E:Value(g)==g.budget)
 seen[E:RewardWearableFamily(seed) or 'generic']=true
end
assert(seen.plumber_boots and seen.thunder_hat and seen.fighting_gloves and seen.psychic_crown and seen.invisibility_ring and seen.generic)
local forged=table.Copy(item);forged.version=1;assert(not E:ValidateWearable(forged))
for _,id in ipairs(E.MoveOrder) do assert(id~='heavy_stomp','No input recipe for a passive') end
local function data(pos,vel)
 local d={pos=pos,velocity=vel or Vector()}
 function d:GetOrigin() return self.pos end
 function d:GetVelocity() return self.velocity end
 function d:SetVelocity(v) self.velocity=v end
 return d
end
local function reset()
 E:ClearTransient(p);now=now+1;p.hp=100;p.ps.magic=47;p.active=true;p.soldier=false
 p.position=Vector(0,0,2);p.ground=floor;p.airborne=false;p.LODForcedMovementUntil=nil
 enemy.position=Vector(0,0,2);enemy.hp=100;enemy.defended=false;enemy.LODDead=nil
 contact=enemy;holes=false;water=false;hurt=false;ceiling=false;side=false;cover=false;clearance=60
 S:CureNegative(p);S:CureNegative(enemy);E:Equip(state,item.id,'feet')
end
local function arm()
 p.ground=floor;p.airborne=false
 E:ObserveStomp(p,data(p.position))
 assert(E.StompFlights[p] and not E.StompFlights[p].invalid)
end
local function descending(z,velocity)
 p.airborne=true;p.ground=NULL;p.position=Vector(0,0,z or 80)
 local d=data(p.position,Vector(25,0,velocity or -200))
 E:ObserveStomp(p,d)
 d.pos=Vector(0,0,74);d.velocity=Vector(25,0,0)
 return d
end
local revealed=0;E.EndCloak=function() revealed=revealed+1 end
reset();arm();local d=descending();assert(E:ResolveStomp(p,d))
assert(enemy.hp<100 and d.velocity.z>250 and d.velocity.z<260 and d.velocity.x==25)
assert(p.ps.magic==47 and revealed>0 and p.ground==NULL,'Free self-bounce, no lateral launch')
local tags=S:DamageContext(enemy.lastInfo)
assert(tags.physical and tags.melee and not tags.magic and tags.equipmentContact and tags.actorDamageResolved)
assert(enemy.lastInfo:GetAttacker()==p and enemy.lastInfo:GetDamageType()==DMG_CLUB)
local hp=enemy.hp;assert(not E:ResolveStomp(p,d) and enemy.hp==hp,'Duplicate FinishMove')
now=now+1;d=descending();assert(not E:ResolveStomp(p,d) and enemy.hp==hp,'Bounce cannot rearm')
p.ground=enemy;p.airborne=false;E:ObserveStomp(p,data(Vector(0,0,74)));d=descending()
assert(not E:ResolveStomp(p,d) and enemy.hp==hp,'Standing on an actor cannot rearm')
E:UnequipItem(state,item.id);E:Equip(state,item.id,'feet');d=descending()
assert(not E:ResolveStomp(p,d),'Removing/re-equipping in midair cannot rearm')
arm();d=descending();assert(E:ResolveStomp(p,d) and enemy.hp<hp,'Real ground landing rearms')
hp=enemy.hp;arm();d=descending();assert(not E:ResolveStomp(p,d) and enemy.hp==hp,'Rapid new flight retains cooldown')

for _,kind in ipairs({'ally','side','rising','slow','below','cover','dead','ceiling','low','holes','water','hurt','stair','void','otherfloor'}) do
 reset();arm()
 if kind=='ally' then contact=ally elseif kind=='side' then side=true elseif kind=='cover' then cover=true
 elseif kind=='dead' then enemy.LODDead=true elseif kind=='ceiling' then ceiling=true elseif kind=='low' then clearance=10
 elseif kind=='holes' then holes=true elseif kind=='water' then water=true elseif kind=='hurt' then hurt=true
 elseif kind=='stair' then graph.VerticalEdges={{a=graph.Cells['5:1:0'],b={x=5,y=1,z=1}}}
 elseif kind=='void' then graph.WardenVoid={['5:1:0']=true}
 elseif kind=='otherfloor' then enemy.position.z=386 end
 d=descending(kind=='below' and 70 or nil,kind=='rising' and 200 or kind=='slow' and -80 or nil)
 assert(not E:ResolveStomp(p,d) and enemy.hp==100 and p.ps.magic==47,kind)
 graph.VerticalEdges={};graph.WardenVoid=nil
end
-- Shared graph support blocks even a footprint corner across a locked edge.
for _,kind in ipairs({'normal','warden','jail'}) do
 reset();local x=kind=='normal' and 180 or kind=='warden' and 564 or 948
 enemy.position=Vector(x,0,2)
 if kind=='normal' then R.State.GatesOpen[1]=false elseif kind=='warden' then R.State.WardenStarted=true else R.State.JailDoorOpen=false end
 assert(not T:ContactBounce(p,enemy,graph,Vector(x,0,74),56),kind)
 enemy.position.x=x+50
 assert(not T:ContactBounce(p,enemy,graph,Vector(x+50,0,74),56,Vector(x-40,0,80)),kind..' swept crossing')
 R.State.GatesOpen[1]=true;R.State.WardenStarted=false;R.State.JailDoorOpen=true
end
reset();arm();clearance=20;d=descending();assert(E:ResolveStomp(p,d))
assert(math.abs(d.velocity.z-math.sqrt(2*600*16))<.001,'Ceiling clips rebound height')
reset();arm();enemy.defended=true;d=descending();assert(E:ResolveStomp(p,d))
assert(enemy.hp==100 and d.velocity.z>0 and p.ps.magic==47,'Defended contact still self-bounces once')
-- Actual native firearm feedback cannot reinterpret a stomp as the held gun.
p.activeClass='weapon_pistol';p:Give('weapon_pistol')
enemy.lastInfo.IsDamageType=function(self,t) return self.DamageType==t end
enemy.lastInfo:SetDamage(3)
assert(not LOD.M3HitFeedback:HandleDamageEvent(enemy,enemy.lastInfo,'probe'))
p.activeClass=nil
reset();arm();S:Apply(p,'muted',p,{direct=true,duration=10});d=descending();assert(E:ResolveStomp(p,d),'Muted does not block physical contact')
reset();assert(E:Grant(p,'healing_potion',1));p.activeClass=E.WeaponClass
p:Give(E.WeaponClass)
arm();d=descending();assert(E:ResolveStomp(p,d) and p.ps.magic==47,'Held throwable does not disable physical boots')
p.activeClass=nil

for _,kind in ipairs({'source','record','life','identity','state','run','seed','graph','dead','soldier','inactive','freeze','clear','held','forced','stale','teleport','cleanup'}) do
 reset();arm();d=descending()
 local ps,run,oldGraph,seed,identity=p.ps,R.State,R.State.Graph,R.State.LevelSeed,p.ps.identity
 if kind=='source' then E:UnequipItem(state,item.id);E:Equip(state,item.id,'feet')
 elseif kind=='record' then state.items[item.id]=table.Copy(item)
 elseif kind=='life' then p.ps.equipmentLifeSerial=p.ps.equipmentLifeSerial+1
 elseif kind=='identity' then p.ps.identity={}
 elseif kind=='state' then p.ps=table.Copy(p.ps)
 elseif kind=='run' then R.State=table.Copy(R.State)
 elseif kind=='seed' then R.State.LevelSeed=seed+1
 elseif kind=='graph' then R.State.Graph=table.Copy(graph)
 elseif kind=='dead' then p.hp=0 elseif kind=='soldier' then p.soldier=true
 elseif kind=='inactive' then p.active=false elseif kind=='freeze' then R.State.SimulationFrozen=true
 elseif kind=='clear' then R.State.LevelCleared=true elseif kind=='held' then S:Apply(p,'held',p,{direct=true,duration=10})
 elseif kind=='forced' then p.LODForcedMovementUntil=now+1
 elseif kind=='stale' then now=now+.2 elseif kind=='teleport' then d.pos=Vector(500,0,74)
 elseif kind=='cleanup' then E:ClearTransient(p) end
 assert(not E:ResolveStomp(p,d) and enemy.hp==100,kind)
 p.ps=ps;R.State=run;R.State.Graph=oldGraph;R.State.LevelSeed=seed;p.ps.identity=identity
 state.items[item.id]=item;R.State.SimulationFrozen=nil;R.State.LevelCleared=nil
end
reset();E:UnequipItem(state,item.id);E:ObserveStomp(p,data(p.position));d=descending()
assert(not E:ResolveStomp(p,d),'Backpack does not grant stomp')
reset();d=descending();assert(not E:ResolveStomp(p,d),'Equipping midair cannot arm a descent')
print('HEAVY_PLUMBER_PASS: generated ownership/value, native top-contact, shared physical combat, free ceiling-safe bounce, graph/floor/hazard rejection, one-per-flight/cooldown, source and lifecycle guards')
