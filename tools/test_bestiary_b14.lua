-- B14 exercises condition commitments through the real roster service, combat and status pipeline.
-- Native entities, collision traces, motion transport and networking are doubles.
local env=dofile('tools/test_enemy_update.lua')
local root='gamemodes/legend_of_deborah/gamemode/lod/'
local noop=function() end
local v=getmetatable(Vector())
v.__div=function(a,b) return a*(1/b) end
v.__unm=function(a) return a*-1 end
function v:Dot(b) return self.x*b.x+self.y*b.y+self.z*b.z end
function v:Length2D() return math.sqrt(self.x*self.x+self.y*self.y) end
function v:Normalize() local n=self:GetNormalized();self.x,self.y,self.z=n.x,n.y,n.z end
local am={};am.__index=am
function Angle(p,y,r) return setmetatable({p=p or 0,y=y or 0,r=r or 0},am) end
function am:Forward() local y=math.rad(self.y);return Vector(math.cos(y),math.sin(y),0) end
function am:Right() local y=math.rad(self.y);return Vector(-math.sin(y),math.cos(y),0) end
function v:Angle() return Angle(0,math.deg(math.atan(self.y,self.x)),0) end
function math.AngleDifference(a,b) return (a-b+180)%360-180 end
function istable(x) return type(x)=='table' end
function isfunction(x) return type(x)=='function' end
function string.Trim(x) return x:match('^%s*(.-)%s*$') end
ACT_IDLE,ACT_RUN_AIM_RIFLE,ACT_IDLE_ANGRY_SMG1,ACT_RANGE_ATTACK1,ACT_FLY=4,5,6,7,8
MASK_PLAYERSOLID=4;MASK_SOLID=3;NULL={valid=false};DMG_ENERGYBEAM,DMG_BURN,DMG_POISON,DMG_SLASH=4,5,6,7
DMG_FALL,DMG_CRUSH,DMG_BUCKSHOT,DMG_CLUB=8,9,10,11
net.WriteUInt=noop;net.WriteVector=noop;net.WriteBool=noop;net.Broadcast=noop;net.Receive=noop
hook.Run=noop;timer.Create=noop;timer.Remove=noop
game={GetWorld=function() return NULL end}
function ErrorNoHalt(message) error(message) end
GM={};dofile(root..'sv_damage_info.lua')
dofile(root..'sh_rng.lua');dofile(root..'sh_rpg_schema.lua')
dofile(root..'sv_rpg_gate_b_catalog.lua');dofile(root..'sv_rpg_gate_c_catalog.lua')
dofile(root..'sh_die_logger.lua');dofile(root..'sv_combat_rolls.lua');dofile(root..'sv_combat_feed_semantics.lua');dofile(root..'sv_character_progression.lua')
dofile(root..'sv_rpg_gate_d.lua');dofile(root..'sv_rpg_status_elements.lua')
dofile(root..'sv_rpg_gate_e_feats.lua');dofile(root..'sv_rpg_gate_e_rate_of_fire.lua');dofile(root..'sv_rpg_dodge.lua')
dofile(root..'sh_equipment.lua');dofile(root..'sh_equipment_catalog.lua')
dofile(root..'sv_rpg_block.lua');dofile(root..'sv_loot_director.lua')
dofile(root..'sv_enemy_roster.lua');dofile(root..'sv_enemy_melee.lua');dofile(root..'sv_enemy_conditions.lua');dofile(root..'sv_enemy_perception.lua');dofile(root..'sv_enemy_spacing.lua');dofile(root..'sv_enemy_resources.lua');dofile(root..'sv_hostile_motion_v2.lua')
LOD.RPGPerceptionState={IsInvisible=function(_,p) return p.invisible==true end}
local E,D,C,Status,Rules=LOD.EnemyRoster,LOD.EncounterDirector,LOD.CharacterProgressionSystem,LOD.RPGStatusElements,LOD.RPGAbilityRules
local time,serial=200,100
local function at(n) time=n;env.setTime(n) end
at(time)
local s=LOD.RunManager.State
s.BuildReady=true;s.Failed=false;s.LevelCleared=false;s.SimulationFrozen=false;s.Level=8
s.CampaignEpoch=1;s.RunId='b14';s.CampaignSeed=77;s.LevelSeed=123
local clearTrace=function(t) return {Hit=false,HitPos=t.endpos} end
util.TraceLine=clearTrace;util.TraceHull=clearTrace
LOD.CombatRolls._Send=noop;LOD.CombatRolls.ReportEnemyHealth=noop
LOD.CombatRolls.EntityDisplayName=function(_,e) return e.LODArchetypeId end
local function actor(id,pos)
    local e=env.actor(1);serial=serial+1;e.index=serial;e.LODArchetypeId=id
    e:SetPos(LOD.MazeNavigator:CellCenter(s.Graph.Cells['3:1:0'])+(pos or Vector()))
    e.LODConfig=table.Copy(LOD.Config.Encounter.Archetypes[id] or LOD.Config.Encounter.Archetypes.runner)
    e.health=e.LODConfig.baseHP;e.maximum=e.health
    e.SetNW2Int=e.SetNW2Bool;e.SetNW2Float=e.SetNW2Bool;e.SetNW2String=e.SetNW2Bool
    e.SetNW2Entity=e.SetNW2Bool
    e.GetCollisionBounds=function() return Vector(-16,-16,0),Vector(16,16,72) end
    e.SetColor=noop;e.SetModelScale=noop;e.GetAngles=function() return Angle() end
    e.GetNW2Float=function(self,k,default) return self.nw[k] or default end
    e.GetNW2Int=e.GetNW2Float;e.GetNW2Vector=e.GetNW2Float
    e.Health=function(self) return self.health end;e.GetMaxHealth=function(self) return self.maximum end
    e.SetHealth=function(self,n) self.health=n end;e.SetMaxHealth=function(self,n) self.maximum=n end
    e.EntIndex=function(self) return self.index end
    -- Every actor uses the real archetype template, class, feat, growth and HP path.
    if LOD.RPG.ArchetypeProgressionTemplates[id] then
        assert(C:AttachMonsterProgression(e,72000+serial,8),'real progression attachment')
    end
    return e
end
local hero=actor('runner',Vector(160,0,0));hero.player=true;hero.LODHostile=false
LOD.RunManager.GetPlayerState=function(_,e) return type(e)=='table' and {progressionState=e.LODProgressionState} or nil end
player.GetAll=function() return {hero} end
local function reset()
    if LOD.EnemyReactions then LOD.EnemyReactions.Active={};LOD.EnemyReactions.NextService=0 end
    E.Projectiles={};E.NextService=0;E.LastService=time
    E.Active=setmetatable({}, {__mode='k'});D.Entities={};Status.Active=setmetatable({}, {__mode='k'})
    s.Graph=table.Copy(s.Graph);s.Graph.Progression={Gates={}};s.SimulationFrozen=false;s.Failed=false;s.LevelCleared=false
    util.TraceLine=clearTrace;util.TraceHull=clearTrace;hero.valid=true;hero.alive=true;hero.health=hero.maximum
    if LOD.EnemySupport then LOD.EnemySupport.Pending={};LOD.EnemySupport.Recipients={};LOD.EnemySupport.NextService=0 end
end

dofile(root..'sv_enemy_reactions.lua')
local R=LOD.EnemyReactions
local function pair(id)
    reset();s.BuildReady=true;s.GatesOpen={};LOD.RunManager.State=s
    hero.LODHitStunUntil=nil;hero:SetPos(LOD.MazeNavigator:CellCenter(s.Graph.Cells['3:1:0'])+Vector(160,0,0))
    local source=actor(id);source.LODTarget=hero;E:Prepare(source);D.Entities={source}
    source.LODProgressionState.equipmentBlockChanceContribution=0
    source.LODProgressionState.derivedStats.blockChanceContribution=0
    return source
end
local function service(n)
    at(n);E.NextService=0;env.hooks.LOD_EnemyRosterAttacks()
end
-- Native damage-object and health mutation are the Source boundary. The actual
-- GM mitigation, firearm hit-stun, post-damage reaction observer and cleanup run.
local weapon={valid=true,GetClass=function() return 'weapon_pistol' end}
hero.GetActiveWeapon=function() return weapon end
hero.GetClass=function() return 'player' end
hero.SteamID64=function() return 'b14-tester' end
hero.Nick=function() return 'B14 tester' end
hero.GetNW2Bool=hero.GetNW2Float
LOD.RunManager.IdentityOf=function(_,p) return p==hero and 'b14-tester' or nil end
local priorGetState=LOD.RunManager.GetPlayerState
LOD.RunManager.GetPlayerState=function(self,p)
    if p=='b14-tester' then return {progressionState=hero.LODProgressionState} end
    return priorGetState(self,p)
end
function DamageInfo()
    local d={damage=0,kind=DMG_BULLET}
    function d:GetDamage() return self.damage end
    function d:SetDamage(n) self.damage=n end
    function d:ScaleDamage(n) self.damage=self.damage*n end
    function d:GetAttacker() return self.attacker end
    function d:SetAttacker(e) self.attacker=e end
    function d:GetInflictor() return self.inflictor end
    function d:SetInflictor(e) self.inflictor=e end
    function d:GetDamageType() return self.kind end
    function d:SetDamageType(n) self.kind=n end
    function d:IsDamageType(n) return self.kind==n end
    function d:GetDamagePosition() return self.pos or Vector() end
    function d:SetDamagePosition(p) self.pos=p end
    function d:GetDamageForce() return self.force or Vector() end
    function d:SetDamageForce(p) self.force=p end
    return d
end
local received,receivedContext=0,nil
function hero:TakeDamageInfo(d)
    received=received+1;receivedContext=Status:DamageContext(d,self)
    GM:EntityTakeDamage(self,d);self.health=math.max(0,self.health-d:GetDamage())
    GM:PostEntityTakeDamage(self,d,true)
end
function EffectData() return {SetOrigin=noop} end
util.Effect=noop
unpack=table.unpack
LOD.WanderingDirector={Config={ArchetypeWeights={}}}
dofile(root..'sv_enemy_roster_placement.lua')
dofile(root..'sv_magic_progression.lua');dofile(root..'sv_magic_forms.lua')
local N,key=LOD.MazeNavigator,LOD.MazeGenerator.CellKey
local function grid()
    local g={Cells={},CellTags={},VerticalEdges={},Progression={Gates={}},Width=7,Height=5,Layers=1}
    for x=1,7 do for y=1,5 do g.Cells[key(x,y,0)]={x=x,y=y,z=0,neighbors={}} end end
    for _,c in pairs(g.Cells) do
        for _,d in ipairs({{1,0},{-1,0},{0,1},{0,-1}}) do
            local k=key(c.x+d[1],c.y+d[2],0);if g.Cells[k] then c.neighbors[k]=true end
        end
    end
    return g
end
local party={hero};local scans=0
player.GetAll=function() scans=scans+1;return party end
local function center() return N:CellCenter(s.Graph.Cells[key(3,3,0)]) end
clearTrace=function(t)
    if t.start.x==t.endpos.x and t.start.y==t.endpos.y and t.start.z>center().z and t.endpos.z<center().z then
        return {Hit=true,HitPos=Vector(t.start.x,t.start.y,center().z),HitNormal=Vector(0,0,1)}
    end
    return {Hit=false,HitPos=t.endpos}
end
local function coverTrace(t)
    local floor=clearTrace(t)
    if floor.Hit then return floor end
    return {Hit=true,HitPos=t.endpos,Entity=NULL}
end
local baseReset=reset
reset=function()
    baseReset();util.TraceHull=function(t) return {Hit=false,HitPos=t.endpos} end;s.Graph=grid();s.BuildReady=true;LOD.RunManager.State=s
    s.GatesOpen={};party={hero};LOD.FactionManager.NextPerceptionHeroes=0;received=0;hero.hits=0;hero.negate=false;hero.invisible=false
    hero.LODStatusImmunities=nil;hero.LODHitStunUntil=nil;hero.health=10000
    Status:ResetActorLife(hero)
    hero.LODProgressionState.classId='fighter';hero.LODProgressionState.featIds={}
    hero.LODProgressionState.derivedStats={};hero.LODProgressionState.equipmentBlockChanceContribution=0
    hero:SetPos(center()+Vector(90,0,0))
end
pair=function(id)
    reset();local e=actor(id);e:SetPos(center()+Vector(0,0,2));e.LODTarget=hero
    E:Prepare(e);D.Entities={e};return e
end
local function begin(id,setup)
    local e=pair(id);if setup then setup(e) end
    E:Tick(e);return e,assert(e.LODRosterAttack,'production AI commits '..id)
end
local originalDamage=hero.TakeDamageInfo
function hero:TakeDamageInfo(info)
    if self.negate then info:SetDamage(0) end
    self.hits=self.hits+1;originalDamage(self,info)
end
-- Native health/application and traces remain doubles; real rolls, mitigation,
-- damage context, rider save and final status application execute unchanged.
local saveRoll=1
LOD.CombatRolls._RNG=function() return {Int=function(_,lo,hi) return hi==20 and saveRoll or lo end} end
local function advance(e,untilTime)
    while time<untilTime do
        -- Exercise native actor AI interleaved with the shared roster Think.
        -- MotionV2, policy, geometry, rolls and mitigation are all production.
        E:Tick(e);service(math.min(untilTime,time+.025))
    end
end
local function extraHero(pos)
    local p=actor('runner');p.player=true;p.LODHostile=false;p.hits=0;p.health=10000
    p:SetPos(pos or center()+Vector(90,0,0));p.LODProgressionState=table.Copy(hero.LODProgressionState)
    p.GetActiveWeapon=hero.GetActiveWeapon;p.GetClass=hero.GetClass;p.Nick=hero.Nick
    p.GetNW2Bool=p.GetNW2Float;p.TakeDamageInfo=hero.TakeDamageInfo
    p.SteamID64=function() return 'b14-other-'..p.index end
    return p
end

-- Exercise the actual canonical resource owner, not an enemy-private counter.
local timers={}
timer.Create=function(id,_,__,fn) timers[id]=fn end
dofile(root..'sv_magic.lua');dofile(root..'sv_rpg_gate_e_quantum.lua')
dofile(root..'sv_rpg_wizard_feedback.lua')
local Magic=LOD.Magic
LOD.RunManager.GetPlayerState=function(_,e)
    if e=='b14-tester' then e=hero end
    if type(e)~='table' then return nil end
    e.pool=e.pool or {magic=100};e.pool.progressionState=e.LODProgressionState
    return e.pool
end
local resetB14=reset
reset=function()
    resetB14();hero.pool={magic=100};Magic.ActivePools={}
end
local function resolve(e,a) advance(e,a.ready) end
local function recharge(setup)
    return begin('accumulator',function(e)
        e.LODProgressionState.derivedStats.quantumCostMultiplier=1
        Magic:_EnsureState(e).magic=0
        if setup then setup(e) end
    end)
end
local function fresh(id,setup)
    return begin(id,function(e)
        e.LODProgressionState.derivedStats.quantumCostMultiplier=1
        if setup then setup(e) end
    end)
end
local e,a=fresh('siphoner')
assert(a.mode==1 and a.ready==time+1.25 and a.deadline==a.ready+.2)
advance(e,a.ready-.01);assert(hero.hits==0 and hero.pool.magic==100,'warning harmless')
resolve(e,a)
assert(hero.hits==1 and receivedContext.magic and receivedContext.element=='raw','shared Raw Magic damage')
assert(hero.pool.magic==88 and Magic:_EnsureState(e).magic==100,'bounded drain, no stealing or private pool')
local expiry=e.LODMeleeRecovery.expires
E:Interrupt(e);E:Tick(e);assert(e.LODMeleeRecovery.expires==expiry,'repeated interruption cannot extend recovery')
for _,amount in ipairs({0,.5,5,12,100}) do
    e,a=fresh('siphoner',function() hero.pool.magic=amount end);resolve(e,a)
    assert(hero.pool.magic==math.max(0,amount-12),'low/fractional pools clamp without HP conversion')
end
for _,move in ipairs({Vector(0,96,0),Vector(100,0,0),Vector(0,0,90)}) do
    e,a=fresh('siphoner');hero:SetPos(hero:GetPos()+move);resolve(e,a)
    assert(hero.hits==0 and hero.pool.magic==100,'frozen mark escape')
end
e,a=fresh('siphoner');hero.negate=true;resolve(e,a)
assert(hero.pool.magic==100,'fully negated damage cannot drain')
e,a=fresh('siphoner');hero.health=.01;resolve(e,a)
assert(hero.health==0 and hero.pool.magic==100,'lethal damage cannot drain corpse')
-- Ordinary magical mitigation and Arcane Shield pay before the drain rider.
e,a=fresh('siphoner',function()
    hero.LODProgressionState.classId='wizard'
    hero.LODProgressionState.derivedStats.hpToMagicDiversionFraction=.5
end)
local before=hero.health;resolve(e,a)
assert(hero.health<before and hero.pool.magic<88,'Arcane diversion precedes drain')
print('BESTIARY_B14_DRAIN_PASS: canonical damage and Magic, warning/escape, capped fractional loss, no zero/lethal rider, Arcane Shield order')

e,a=fresh('accumulator');assert(a.mode==2);resolve(e,a)
assert(hero.hits==1 and a.pool.magic==60,'paid cast canonical pool')
e,a=fresh('accumulator',function(e) e.LODProgressionState.derivedStats.quantumCostMultiplier=.67 end)
resolve(e,a);assert(a.pool.magic==73,'canonical Quantum rounds cost to27')
e,a=fresh('accumulator');hero:SetPos(hero:GetPos()+Vector(0,96,0));resolve(e,a)
assert(hero.hits==0 and a.pool.magic==60,'dodge by moving does not refund released attack')
e,a=fresh('accumulator');a.pool.magic=0;resolve(e,a)
assert(hero.hits==0 and a.pool.magic==0,'shield/other depletion during charge forbids unaffordable release')
e,a=recharge();assert(a.mode==3 and a.ready==time+2 and a.aim==a.origin)
advance(e,a.ready-.01);assert(a.pool.magic==0 and hero.hits==0,'recharge no advance credit or attack')
resolve(e,a);assert(a.pool.magic==45 and hero.hits==0,'single self restore, not attack')
E:StepResource(e,a,time);assert(a.pool.magic==45,'detached callback cannot refill twice')
e,a=recharge();a.pool.magic=95;resolve(e,a);assert(a.pool.magic==100,'concurrent regen caps recharge')
e,a=recharge();E:Interrupt(e);advance(e,a.ready+.025)
assert(a.pool.magic==0 and hero.hits==0,'interrupt denies refill')
-- A complete natural burst/recharge cycle uses one pool and no scheduler.
e,a=fresh('accumulator');resolve(e,a)
for _,expected in ipairs({20,65,25,70}) do
    advance(e,e.LODNextAttack+.025);local nextAttack=assert(e.LODRosterAttack)
    resolve(e,nextAttack);assert(a.pool.magic==expected,'natural cast/recharge cycle '..expected)
end
print('BESTIARY_B14_RECHARGE_PASS: paid casts, Quantum, depleted release, harmless channel, cap100, denial, natural cycle')
local mutations={
 sourceDeath=function(source) source.LODDead=true end,
 sourceRemoval=function(source) source.valid=false end,
 sourceHealth=function(source) source.health=0 end,
 sourceInactive=function(source) source.LODActivated=false end,
 sourceProgression=function(source) source.LODProgressionState=table.Copy(source.LODProgressionState) end,
 sourceLife=function(source) Status:ResetActorLife(source) end,
 targetLife=function() Status:ResetActorLife(hero) end,
 targetProgression=function() hero.LODProgressionState=table.Copy(hero.LODProgressionState) end,
 targetDeath=function() hero.alive=false;hero.health=0 end,
 targetRemoval=function() hero.valid=false end,
 run=function() LOD.RunManager.State=table.Copy(s) end,
 graph=function() s.Graph=table.Copy(s.Graph) end,
 progression=function() s.Graph.Progression=table.Copy(s.Graph.Progression) end,
 epoch=function() s.CampaignEpoch=s.CampaignEpoch+1 end,
 campaignSeed=function() s.CampaignSeed=s.CampaignSeed+1 end,
 levelSeed=function() s.LevelSeed=s.LevelSeed+1 end,
 runId=function() s.RunId=s.RunId..'x' end,
 freeze=function() s.SimulationFrozen=true end,
 failure=function() s.Failed=true end,
 clear=function() s.LevelCleared=true end,
 build=function() s.BuildReady=false end,
 interrupt=function(source) E:Interrupt(source) end,
 stun=function(source) source.LODHitStunUntil=time+5 end,
 displacement=function(source) source:SetPos(source:GetPos()+Vector(0,5,0)) end,
 invisible=function() hero.invisible=true end,
}

mutations.sourcePool=function(source) source.LODProgressionState=table.Copy(source.LODProgressionState) end
mutations.targetPool=function() hero.pool={magic=100} end
for _,mode in ipairs({1,2,3}) do
 for _,phase in ipairs({'early','deadline'}) do
  for name,mutate in pairs(mutations) do
    if mode==3 then e,a=recharge() else e,a=fresh(mode==1 and 'siphoner' or 'accumulator') end
    if phase=='deadline' then advance(e,a.ready-.025) end
    local pool,poolValue=a.pool,a.pool.magic;local targetPool,targetValue=a.targetPool,a.targetPool.magic
    mutate(e);service(time+.05);E:StepResource(e,a,time)
    assert(hero.hits==0 and pool.magic==poolValue and targetPool.magic==targetValue,'lifecycle '..mode..' '..phase..' '..name)
  end
 end
 for _,condition in ipairs({'held','muted','intimidated','morale_flee'}) do
    if mode==3 then e,a=recharge() else e,a=fresh(mode==1 and 'siphoner' or 'accumulator') end
    if condition=='morale_flee' then assert(Status:AttemptMorale(hero,e,{forceMorale=true,rng={Int=function(_,lo) return lo end}}))
    else assert(Status:Apply(e,condition,hero,{direct=true,duration=5})) end
    resolve(e,a)
    assert(hero.hits==((condition=='held' and mode~=3) and 1 or 0),'status hit '..mode..condition)
    if mode==3 then assert(a.pool.magic==(condition=='held' and 45 or 0),'status refill '..condition) end
 end
 if mode==3 then e,a=recharge() else e,a=fresh(mode==1 and 'siphoner' or 'accumulator') end
 service(time+.251);assert(not e.LODRosterAttack and hero.hits==0,'missed service retires')
 if mode==3 then e,a=recharge() else e,a=fresh(mode==1 and 'siphoner' or 'accumulator') end
 service(a.deadline+.001);assert(not e.LODRosterAttack and hero.hits==0,'expired service retires')
end
print('BESTIARY_B14_LIFETIME_PASS: all3 modes, early/deadline source/target/resource/dungeon identity matrix, status and stall gates')

for _,id in ipairs({'siphoner','accumulator'}) do
 for _,what in ipairs({'cover','support','hull','safe','objective','gate','transition'}) do
    e=pair(id)
    if what=='cover' then util.TraceLine=coverTrace
    elseif what=='support' then util.TraceLine=function(t) return {Hit=false,HitPos=t.endpos} end
    elseif what=='hull' then util.TraceHull=function() return {Hit=true,StartSolid=true} end
    elseif what=='safe' then s.Graph.CellTags[key(3,3,0)]={safe=true}
    elseif what=='objective' then s.Graph.CellTags[key(3,3,0)]={objective=true}
    elseif what=='gate' then s.Graph.Progression.Gates={{beforeCell=s.Graph.Cells[key(3,3,0)],afterCell=s.Graph.Cells[key(4,3,0)]}}
    else s.Graph.VerticalEdges={{a=s.Graph.Cells[key(3,3,0)],b=s.Graph.Cells[key(4,3,0)]}} end
    assert(not E:BeginResource(e,hero,time),'illegal placement '..id..what)
 end
 e,a=fresh(id);util.TraceHull=function(t)
    assert(t.mins.x==-16 and t.maxs.z==72,'actual Hero collision hull');return {Hit=true,StartSolid=true}
 end
 resolve(e,a);assert(hero.hits==0,'escape lost after warning')
 for _,partyCount in ipairs({1,2,3,4}) do
    e,a=fresh(id)
    for i=2,partyCount do party[#party+1]=extraHero(hero:GetPos()) end
    resolve(e,a);assert(hero.hits==1,'captured Hero hit')
    for i=2,#party do assert(party[i].hits==0,'bystander not captured') end
 end
end
-- Callback boundaries: claim before debit/damage; preserve a replacing attack.
local sync=Magic._Sync
for _,mode in ipairs({1,2,3}) do
 if mode==3 then e,a=recharge() else e,a=fresh(mode==1 and 'siphoner' or 'accumulator') end
 local calls=0
 Magic._Sync=function(self,actor,pool)
    calls=calls+1;E:StepResource(e,a,time);return sync(self,actor,pool)
 end
 resolve(e,a);Magic._Sync=sync
 assert(calls>=1 and calls<=2 and hero.hits==(mode==3 and 0 or 1),'reentrant sync settles once')
end
e,a=fresh('accumulator');local replacement={}
Magic._Sync=function(self,actor,pool) e.LODRosterAttack=replacement;return sync(self,actor,pool) end
resolve(e,a);Magic._Sync=sync
assert(hero.hits==0 and a.pool.magic==60 and e.LODRosterAttack==replacement,'paid retired cast cannot erase newer attack')
e,a=recharge();Magic._Sync=function(self,actor,pool) Status:ResetActorLife(e);return sync(self,actor,pool) end
resolve(e,a);Magic._Sync=sync
assert(not e.LODRosterAttack and a.pool.magic==45,'spent recharge retires after source replacement')
local damage=hero.TakeDamageInfo
e,a=fresh('siphoner');hero.TakeDamageInfo=function(self,info)
    damage(self,info);Status:ResetActorLife(self)
end
resolve(e,a);hero.TakeDamageInfo=damage
assert(hero.pool.magic==100,'native damage cannot drain replacement life')
e,a=fresh('siphoner');hero.TakeDamageInfo=function(self,info)
    E:StepResource(e,a,time);damage(self,info)
end
resolve(e,a);hero.TakeDamageInfo=damage
assert(hero.hits==1 and hero.pool.magic==88,'reentrant native damage claimed once')
-- Shared cap: no extra bodies, no recurring per-actor hook or catch-up burst.
e=pair('siphoner');local retained={}
for i=1,16 do local source=actor('siphoner');retained[i]=source;E.Active[source]=true;source.LODRosterAttack={resource=true} end
assert(not E:BeginResource(e,hero,time),'cap16')
print('BESTIARY_B14_BOUNDARIES_PASS: actual Hero hull, support/cover/progression exclusions, parties1–4, pool/native reentry/replacement, cap16')
-- Native transport is doubled, but recharge/regeneration and eligible cast feats
-- use the same production resource state and functions as Heroes/other AI.
dofile(root..'sv_rpg_gate_e_magic_recovery.lua')
local realRoll=LOD.CombatRolls.RollHostileAttack
LOD.CombatRolls.RollHostileAttack=function(self,...)
    local roll=realRoll(self,...)
    -- Boundary injection: actual damage pipeline still consumes the contract;
    -- supply a known continuation count to prove the resource integration cap.
    roll.values={6,6,6,6,6,6,6,6,1};roll.baseDice=1
    return roll
end
e,a=fresh('accumulator',function(source) source.LODProgressionState.featIds={'INT_FEEDBACK_LOOP'} end)
resolve(e,a);assert(a.pool.magic==66,'canonical Feedback Loop restores at most6 once per committed attack')
LOD.CombatRolls.RollHostileAttack=realRoll
player.GetHumans=function() return {hero} end
LOD.RunManager.IsActivePlayer=function() return true end
e,a=recharge();resolve(e,a);hero.pool.magic=0
local pool=a.pool;timers.LOD_MagicRegen()
assert(pool.magic>45 and hero.pool.magic>0,'same canonical scheduler regenerates both resources')
LOD.MinimapMagic={Active={[hero]={}}};local heldMagic=hero.pool.magic
timers.LOD_MagicRegen();assert(hero.pool.magic==heldMagic,'map-open suppression remains canonical')
LOD.MinimapMagic.Active={}
-- Exactly one cast-spend observer, with a pre-debit full-Magic snapshot; drain
-- and recharge are involuntary/resource restoration, never another activation.
local spent=0;local previousHook=hook.Run
hook.Run=function(name,actor,cost,context)
    if name=='LODDiscreteMagicSpent' then
        spent=spent+1;assert(cost==40 and actor==e and context,'actual committed paid activation')
        E:StepResource(e,a,time)
    end
end
e,a=fresh('accumulator');resolve(e,a)
assert(spent==1 and a.pool.magic==60 and a.event.resourceFullMagicBonus~=nil,'one cast observer, sealed bonus')
e,a=recharge();resolve(e,a);e,a=fresh('siphoner');resolve(e,a)
assert(spent==1,'drain/recharge do not impersonate casts')
hook.Run=previousHook
print('BESTIARY_B14_MAGIC_INTEGRATION_PASS: real shared regeneration/suppression, Quantum, FeedbackLoop cap, full-Magic snapshot and single discrete-spend dispatch')
e,a=fresh('accumulator');advance(e,a.ready-.025)
Magic._Sync=function() error('injected native sync failure') end
local ok=pcall(function() advance(e,a.ready) end);Magic._Sync=sync
assert(not ok and a.pool.magic==60 and hero.hits==0,'failed native callback has one debit and no stale damage')
service(a.deadline+.001)
assert(not e.LODRosterAttack,'claimed failed callback cannot pin actor indefinitely')
print('BESTIARY_B14_NATIVE_FAILURE_PASS: spent callback failure retires at fixed deadline')
-- Real generated Aura Burst is supplemental to the captured resource mark.
-- Load its production preparation/resolution hook; only engine hook dispatch is doubled.
dofile(root..'sv_rpg_checkpoint_d_core_feats.lua')
dofile(root..'sv_rpg_checkpoint_d_aura_burst_feats.lua')
local auraHook=assert(env.hooks.LOD_CheckpointDAuraBurst)
local auraSpends=0
hook.Run=function(name,actor,cost,context)
    if name=='LODDiscreteMagicSpent' then
        auraSpends=auraSpends+1
        return auraHook(actor,cost,context)
    end
end
local function ownAura(source)
    source.LODProgressionState.featIds={'CHA_AURA_BURST_1'}
    source.LODProgressionState.derivedStats.chaMod=3
end
local auraStats=LOD.RPG.CheckpointDAuraBurstStats
local pulses=auraStats.pulses
e,a=fresh('accumulator',ownAura)
local bystander=extraHero(hero:GetPos());party[2]=bystander
-- Escaping the mark avoids its hit; an ordinary generated same-cell aura still applies.
hero:SetPos(hero:GetPos()+Vector(0,96,0))
resolve(e,a)
assert(auraSpends==1 and auraStats.pulses==pulses+1 and a.pool.magic==60,'one real aura for one paid activation')
assert(hero.hits==1 and bystander.hits==1 and receivedContext.auraBurst,'escaped and unmarked Heroes receive only supplemental aura')
assert(hero.pool.magic==100,'supplemental aura does not acquire a drain rider')
pulses=auraStats.pulses
e,a=recharge(ownAura);resolve(e,a)
e,a=fresh('siphoner',ownAura);resolve(e,a)
assert(auraSpends==1 and auraStats.pulses==pulses,'self recharge and involuntary drain never trigger Aura Burst')
-- A real aura damage callback can replace the pending attack or source life.
-- The canonical aura settles, but the old resource mark must not follow it.
for _,replacementKind in ipairs({'attack','sourceLife','targetLife'}) do
    e,a=fresh('accumulator',ownAura)
    local replacementAttack={}
    hero.TakeDamageInfo=function(self,info)
        local aura=Status:DamageContext(info,self).auraBurst
        damage(self,info)
        if aura then
            if replacementKind=='attack' then e.LODRosterAttack=replacementAttack
            elseif replacementKind=='sourceLife' then Status:ResetActorLife(e)
            else Status:ResetActorLife(hero) end
        end
    end
    resolve(e,a);hero.TakeDamageInfo=damage
    assert(hero.hits==1 and a.pool.magic==60,'real aura replacement prevents stale mark '..replacementKind)
    if replacementKind=='attack' then assert(e.LODRosterAttack==replacementAttack,'new attack survives retired mark')
    else assert(not e.LODRosterAttack,'replaced life retires spent mark') end
end
hook.Run=previousHook
print('BESTIARY_B14_AURA_PASS: production Aura Burst hook/preparation/resolution, supplemental escaped/bystander hits, one paid activation, no drain/recharge activation, attack/source/target replacement suppresses stale mark')
