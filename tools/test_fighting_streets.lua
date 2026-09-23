-- Production paired gloves, native projectile adapter, combo, combat and lifecycle.
local env=dofile('tools/test_equipment_economy_runtime.lua')
local root='gamemodes/legend_of_deborah/gamemode/lod/'
local E,F,R,S,C=LOD.Equipment,LOD.MagicForms,env.Run,LOD.RPGStatusElements,LOD.CharacterProgressionSystem
local V=getmetatable(Vector())
V.__add=function(a,b) return Vector(a.x+b.x,a.y+b.y,a.z+b.z) end
V.__sub=function(a,b) return Vector(a.x-b.x,a.y-b.y,a.z-b.z) end
V.__mul=function(a,b) return Vector(a.x*b,a.y*b,a.z*b) end
function V:GetNormalized() local d=math.sqrt(self:DistToSqr(Vector()));return self*(1/math.max(d,.001)) end
local now=200;CurTime=function() return now end
local p,a,b,ally=env.actor('crown'),env.actor('far',true),env.actor('near',true),env.actor('ally')
for i,actor in ipairs({p,a,b,ally}) do
 actor.position=Vector((i==1 and 0 or i==2 and 600 or i==3 and 400 or 10),0,2)
 actor.GetPos=function(self) return self.position end
 actor.WorldSpaceCenter=function(self) return self.position+Vector(0,0,36) end
 actor.GetShootPos=actor.WorldSpaceCenter
 actor.GetOwner=function() end
 actor.GetClass=function(self) return self.LODHostile and 'lod_hostile' or 'player' end
 actor.EntIndex=function() return i end
 actor.TakeDamageInfo=function(self,info) self.hp=self.hp-info:GetDamage();self.lastInfo=info end
end
p.ps.progressionState.baseAbilities.wis=20;C:_RecomputeProgressionState(p.ps.progressionState)
LOD.Magic._EnsureState=function(_,actor) return actor.ps end
LOD.Magic._Sync=function() end
LOD.Magic.Stats={targets=0,damage=0}
LOD.MazeGenerator={CellKey=function(x,y,z) return x..':'..y..':'..z end}
LOD.Config.Maze.Width,LOD.Config.Maze.Height=3,1
LOD.Config.Maze.CellSize,LOD.Config.Maze.LevelHeight,LOD.Config.Maze.Origin=384,300,Vector()
function LOD.MazeBuilder:CellCenter(c) return Vector((c.x-2)*384,0,c.z*300) end
LOD.MazeNavigator={};dofile(root..'sv_maze_navigator.lua')
local c0={x=2,y=1,z=0,neighbors={['3:1:0']=true}}
local c1={x=3,y=1,z=0,neighbors={['2:1:0']=true}}
R.State.Graph={Cells={['2:1:0']=c0,['3:1:0']=c1},Width=3,Height=1,Layers=1,
 Progression={Gates={{edgeKey='2:1:0|3:1:0'}}}}
R.State.GatesOpen={true}
LOD.FactionManager.Opponents=function() return {a,b} end
LOD.FactionManager.IsOpponent=function(_,source,target) return source==p and IsValid(target) and (target==a or target==b) and target:Health()>0 end
local blocked={}
util.TraceLine=function(d) local hit=blocked[d.endpos.x];return {Hit=hit,Fraction=hit and .5 or 1} end
MASK_SOLID,DMG_ENERGYBEAM=1,2
game={GetWorld=function() return nil end}
net.WriteEntity=function() end;net.WriteString=function() end;net.Broadcast=function() end
DamageInfo=function()
 local out={}
 for _,name in ipairs({'Attacker','Inflictor','Damage','DamageType','DamagePosition','DamageForce'}) do
  out['Set'..name]=function(self,value) self[name]=value end
  out['Get'..name]=function(self) return self[name] end
 end
 return out
end
-- Reload only to bind the real navigator in the shared closure.
dofile(root..'sv_magic_forms.lua')
dofile(root..'sv_equipment_moves.lua')

V.__unm=function(a) return a*-1 end
function V:Length() return math.sqrt(self:DistToSqr(Vector())) end
function V:LengthSqr() return self:DistToSqr(Vector()) end
function V:Angle() return {p=0,y=0} end
function V:Distance(b) return (self-b):Length() end
p.GetAimVector=function() return Vector(1,0,0) end
net.WriteVector=function() end;net.WriteUInt=function() end;net.WriteFloat=function() end
AddCSLuaFile=function() end;include=function() end
ENT={};dofile('gamemodes/legend_of_deborah/entities/entities/lod_magic_projectile/init.lua')
local projectileMethods=ENT
local spawnFail,muzzleBlocked,hit,created=false,false,nil,nil
util.TraceHull=function(data)
    if data.start:DistToSqr(data.endpos)==0 then return {StartSolid=muzzleBlocked} end
    if hit then return {Hit=true,HitPos=hit:GetPos(),HitNormal=Vector(-1,0,0),Entity=hit} end
    return {Hit=false}
end
ents={}
ents.Create=function(class)
    assert(class=='lod_magic_projectile')
    if spawnFail then return nil end
    local ent=setmetatable({valid=true},{__index=projectileMethods})
    for _,method in ipairs({'SetMagicForm','SetModel','SetMoveType','SetSolid','SetCollisionGroup','DrawShadow','SetRenderMode','SetColor','Activate','NextThink'}) do ent[method]=function() end end
    function ent:SetPos(value) self.position=value end
    function ent:GetPos() return self.position end
    function ent:SetAngles(value) self.angles=value end
    function ent:Spawn() self:Initialize() end
    function ent:Remove() self.valid=false end
    function ent:GetOwner() return self.LODCaster end
    function ent:IsPlayer() return false end
    created=ent
    return ent
end
util.SpriteTrail=nil
local item=E:NewItem(p,'fighting_gloves','proof')
assert(E:ValidateWearable(item) and item.rarity>=2)
assert(E:InnateValue('fighting_gloves',100)==80)
assert(E:Budget(1,'fighting_gloves',2,100)==E:Budget(1,'gloves',2,100)+80)
local seen={}
for seed=1,300 do
    local g=E:Generate(seed,seed%999+1,'fighting_gloves','streets:'..seed)
    assert(E:ValidateWearable(g) and E:Value(g)==g.budget and g.rarity>=2)
    seen[E:RewardWearableFamily(seed) or 'generic']=true
end
assert(seen.psychic_crown and seen.fighting_gloves and seen.generic)
local forged=table.Copy(item);forged.version=1;assert(not E:ValidateWearable(forged))
assert(E:Description(item):find('← ↓ →',1,true) and E:Description(item):find('→ ↓ →',1,true))
local state=E:Ensure(p.ps)
assert(E:AcquireWearable(state,item,false) and E:Equip(state,item.id,'left_hand'))
assert(E:Equipped(state,'left_hand')==item and E:Equipped(state,'right_hand')==item)
local _,grants=E:Contributions(state)
assert(grants.ember_fist and grants.cinder_rise and not grants.rebuff)
assert(#p.ps.progressionState.featIds==0)
E:RefreshDerived(p,p.ps)
local logs={};LOD.CombatRolls._Send=function(_,_,_,text) logs[#logs+1]=text end
LOD.CombatRolls._DamageEventText=function(_,_,_,amount,target,detail) return target.id..':'..amount..':'..detail end
LOD.CombatRolls._RNG=function() return {Int=function(_,lo) return lo end,Float=function() return 1 end} end
local rolled={}
local originalRoll=F._RollDamage
F._RollDamage=function(self,attacker,form,context)
    rolled[#rolled+1]=form.id
    assert(context.castSerial and context.equipmentSnapshot and context.deliveryContent)
    return originalRoll(self,attacker,form,context)
end
-- Source invokes the shared status observer after its defense decision.
for _,actor in ipairs({a,b,ally}) do
 actor.TakeDamageInfo=function(self,info)
    if self.cancelDamage then info:SetDamage(0) end
    S:ObserveDamage(self,info)
    self.hp=self.hp-info:GetDamage();self.lastInfo=info
 end
end
local function cast(id)
    local ok
    for _,t in ipairs(E.SpecialMoves[id].recipe) do now=now+.1;ok=E:DirectionToken(p,t) end
    return ok
end
local function reset()
    if IsValid(created) then created:Remove() end
    now=now+5;p.ps.magic=100;a.hp=100;b.hp=100;ally.hp=100
    E:ClearTransient(p);blocked={};muzzleBlocked=false;spawnFail=false;hit=nil
    S:CureNegative(p);S:CureNegative(a);S:CureNegative(b)
end
assert(cast('ember_fist') and p.ps.magic==88)
local projectile=created
assert(projectile.LODFormId=='bolt' and projectile:GetPos():DistToSqr(p:GetShootPos())==0)
assert(projectile.LODSpeed==1200 and projectile.LODMaximumTravel==1920)
assert(not cast('ember_fist') and p.ps.magic==88)
local sealed=projectile.LODCastContext.deliveryContent
hit=b;now=now+.05;projectile:Think()
assert(not IsValid(projectile) and b.hp<100 and a.hp==100 and ally.hp==100, 'impact valid='..tostring(IsValid(projectile))..' b='..b.hp..' a='..a.hp..' ally='..ally.hp..' rolls='..#rolled..' binding='..tostring(E:MoveAttackValid(p,projectile.LODCastContext)))
assert(rolled[#rolled]=='ember_fist' and b.lastInfo:GetAttacker()==p)
assert(S:DamageContext(b.lastInfo).element==sealed.element)
local after=b.hp;F:ProjectileImpact(projectile,{Entity=b});assert(b.hp==after)
reset();spawnFail=true;assert(not cast('ember_fist') and p.ps.magic==100)
spawnFail=false;muzzleBlocked=true;assert(not cast('ember_fist') and p.ps.magic==100 and not IsValid(created))
reset();assert(cast('ember_fist'));local before=#rolled
F:ProjectileImpact(created,{Hit=true,HitPos=Vector(10,0,0),HitNormal=Vector(-1,0,0)})
assert(#rolled==before and p.ps.magic==88,'Wall/miss spends once without splash')
-- Local square only: same-cell exposed enemy, covered enemy, adjacent enemy, ally.
reset();b.position=Vector(40,0,2);a.position=Vector(500,0,2)
assert(cast('cinder_rise') and p.ps.magic==82 and b.hp<100 and a.hp==100 and ally.hp==100)
assert(S:DamageContext(b.lastInfo).riderStatusId=='immolated')
assert(S:Has(b,'immolated'),'Uppercut uses the real shared save/status authority')
assert(not cast('cinder_rise') and p.ps.magic==82)
reset();blocked[40]=true;before=#rolled
assert(cast('cinder_rise') and #rolled==before and p.ps.magic==82,'Covered/empty square is a committed miss')
reset();b.cancelDamage=true;assert(cast('cinder_rise') and not S:Has(b,'immolated'));b.cancelDamage=false
-- Reject all stale delayed ownership/lifecycle states both in Think and impact.
for _,kind in ipairs({'life','state','run','level','graph','source','soldier','dead','inactive','cleared','frozen','expiry'}) do
 reset();assert(E:Equip(state,item.id,'left_hand'));assert(cast('ember_fist'))
 local oldPS,oldRun,oldGraph,oldLevel=p.ps,R.State,R.State.Graph,R.State.LevelSeed
 if kind=='life' then p.ps.equipmentLifeSerial=(p.ps.equipmentLifeSerial or 0)+1
 elseif kind=='state' then p.ps=table.Copy(p.ps)
 elseif kind=='run' then R.State=table.Copy(R.State)
 elseif kind=='level' then R.State.LevelSeed=oldLevel+1
 elseif kind=='graph' then R.State.Graph=table.Copy(oldGraph)
 elseif kind=='source' then E:UnequipItem(state,item.id)
 elseif kind=='soldier' then p.soldier=true
 elseif kind=='dead' then p.hp=0
 elseif kind=='inactive' then p.active=false
 elseif kind=='cleared' then R.State.LevelCleared=true
 elseif kind=='frozen' then R.State.SimulationFrozen=true
 elseif kind=='expiry' then now=now+2 end
 before=#rolled
 assert(not F:ProjectileContextValid(created),kind)
 hit=b;now=now+.01;created:Think();assert(not IsValid(created) and #rolled==before,kind)
 p.ps=oldPS;R.State=oldRun;R.State.Graph=oldGraph;R.State.LevelSeed=oldLevel
 p.soldier=nil;p.hp=100;p.active=true;R.State.LevelCleared=nil;R.State.SimulationFrozen=nil
end
reset();assert(E:Equip(state,item.id,'left_hand'))
p.ps.magic=0;assert(not cast('ember_fist') and p.ps.magic==0)
reset();assert(S:Apply(p,'muted',p,{direct=true,duration=5}));assert(not cast('cinder_rise') and p.ps.magic==100)
reset();assert(S:Apply(p,'held',p,{direct=true,duration=5}));assert(cast('ember_fist') and p.ps.magic==88,'Held stops movement, not stationary casting')
reset();assert(E:Grant(p,'healing_potion',1));p.activeClass=E.WeaponClass
p.weapons[E.WeaponClass]={valid=true,GetClass=function() return E.WeaponClass end}
assert(not cast('ember_fist') and p.ps.magic==100);p.activeClass=nil
-- Rebuff ownership and recipe collision: equipping a ring evicts both gloves.
reset();local ring
for seed=1,1000 do local r=E:Generate(seed,10,'ring');for _,prop in ipairs(r.properties) do if prop.id=='move_rebuff' then ring=r;break end end;if ring then break end end
assert(ring,'No Rebuff ring generated');assert(E:AcquireWearable(state,ring,true),'Rebuff admission');assert(E:Equip(state,ring.id,'right_hand'),'Rebuff equip')
_,grants=E:Contributions(state);assert(grants.rebuff and not grants.ember_fist and not grants.cinder_rise)
assert(not E:Equipped(state,'left_hand'))
assert(E:Equip(state,item.id,'left_hand'));_,grants=E:Contributions(state);assert(not grants.rebuff)
assert(cast('ember_fist') and p.ps.magic==88,'Unowned Rebuff must not intercept the same recipe')
print('FIGHTING_STREETS_PASS: paired economy, natural rewards, shared recipes, native projectile preflight/Think/impact, canonical damage/status, source and lifecycle rejection')
