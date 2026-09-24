-- B16 exercises discipline commitments through the real roster service, combat and status pipeline.
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
MASK_SHOT=5;MASK_PLAYERSOLID=4;MASK_SOLID=3;NULL={valid=false};DMG_ENERGYBEAM,DMG_BURN,DMG_POISON,DMG_SLASH=4,5,6,7
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
dofile(root..'sv_enemy_roster.lua');dofile(root..'sv_enemy_melee.lua');dofile(root..'sv_enemy_conditions.lua');dofile(root..'sv_enemy_perception.lua');dofile(root..'sv_enemy_spacing.lua');dofile(root..'sv_enemy_crossfire.lua');dofile(root..'sv_enemy_discipline.lua');dofile(root..'sv_hostile_motion_v2.lua')
LOD.RPGPerceptionState={IsInvisible=function(_,p) return p.invisible==true end}
local E,D,C,Status,Rules=LOD.EnemyRoster,LOD.EncounterDirector,LOD.CharacterProgressionSystem,LOD.RPGStatusElements,LOD.RPGAbilityRules
local time,serial=200,100
local function at(n) time=n;env.setTime(n) end
at(time)
local s=LOD.RunManager.State
s.BuildReady=true;s.Failed=false;s.LevelCleared=false;s.SimulationFrozen=false;s.Level=8
s.CampaignEpoch=1;s.RunId='b16';s.CampaignSeed=77;s.LevelSeed=123
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
hero.SteamID64=function() return 'b15-tester' end
hero.Nick=function() return 'B15 tester' end
hero.GetNW2Bool=hero.GetNW2Float
LOD.RunManager.IdentityOf=function(_,p) return p==hero and 'b15-tester' or nil end
local priorGetState=LOD.RunManager.GetPlayerState
LOD.RunManager.GetPlayerState=function(self,p)
    if p=='b15-tester' then return {progressionState=hero.LODProgressionState} end
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
    p.SteamID64=function() return 'b15-other-'..p.index end
    return p
end

LOD.HostileRegistry={List=function() return D.Entities end}
LOD.RunManager.IsActivePlayer=function(_,p) return p.player and not p.LODHostile end
-- Restore actual faction predicates after the common fixture's membership double.
dofile(root..'sv_faction_manager.lua')
-- Execute the real faction hook ahead of the native GM damage seam.
local factionHook=assert(env.hooks.LOD_HostileFactionDamage)
local nativeHero=hero.TakeDamageInfo
function hero:TakeDamageInfo(info)
    if not factionHook(self,info) then nativeHero(self,info) end
end

-- Native FinishMove is the motion boundary; execute its real qualification hook.
MOVETYPE_WALK=2
local speed=0
hero.GetMoveType=function() return MOVETYPE_WALK end
hero.GetBaseVelocity=function() return vector_origin end
hero.OnGround=function() return true end
hero.GetWalkSpeed=function() return 200 end
hero.GetRunSpeed=function() return 400 end
hero.KeyDown=function() return false end
local function sample(p,velocity)
    env.hooks.LOD_RPG_DodgeVoluntaryMotion(p,{GetVelocity=function() return Vector(velocity or speed,0,0) end})
end
local priorPair=pair
pair=function(id)
    local e=priorPair(id);hero.LODForcedMovementUntil=nil;hero.moveType=MOVETYPE_WALK
    hero.GetMoveType=function(self) return self.moveType end
    hero.GetBaseVelocity=function() return vector_origin end
    hero.GetCollisionBounds=function() return Vector(-16,-16,0),Vector(16,16,72) end
    hero:SetPos(center()+Vector(90,0,2));speed=0;sample(hero)
    e.LODProgressionState.featIds={};e.LODProgressionState.derivedStats={}
    return e
end
local function step(e,n,velocity,noSample)
    at(n);if not noSample then sample(hero,velocity) end
    E:Tick(e);service(n)
end
advance=function(e,untilTime,velocity)
    while time<untilTime-1e-8 do step(e,math.min(untilTime,time+.025),velocity) end
    if time<untilTime then step(e,untilTime,velocity) end
end
local function fresh(id,velocity)
    local e=pair(id);sample(hero,velocity or 0);E:Tick(e)
    return e,assert(e.LODRosterAttack,'actual AI discipline commitment '..id)
end
-- Literal contrasting actions, including class-relative threshold boundary.
for _,case in ipairs({{'halter',0,false},{'halter',49,false},{'halter',50,true},
    {'pacer',0,true},{'pacer',49,true},{'pacer',50,false},{'pacer',200,false}}) do
    local e,a=fresh(case[1],case[2]);local hp=hero:Health()
    advance(e,a.ready,case[2])
    assert(hero.hits==(case[3] and 1 or 0),'contrasting verdict '..case[1]..' '..case[2]..' hits '..hero.hits)
    assert((hero:Health()<hp)==case[3],'actual canonical HP settlement')
    assert(not e.LODRosterAttack and e.nw.LOD_DisciplineMode==0,'tell retired')
    assert(e.LODMeleeRecovery and math.abs(e.LODNextAttack-(a.ready+3))<.001,'fixed recovery')
    E:StepDiscipline(e,a,time);assert(hero.hits==(case[3] and 1 or 0),'spent replay inert')
end
for _,id in ipairs({'halter','pacer'}) do
    local obey=id=='halter' and 0 or 70;local violate=id=='halter' and 70 or 0
    local e,a=fresh(id,violate);advance(e,a.window-.05,violate);advance(e,a.ready,obey)
    assert(hero.hits==0,'grace-period motion does not count')
    e,a=fresh(id,obey);advance(e,a.window+.05,obey)
    step(e,time+.025,violate);advance(e,a.ready,obey)
    assert(hero.hits==1,'single final-window violation is not erased by later obedience')
end
print('BESTIARY_B16_VERDICT_PASS: actual Tick/Think and FinishMove qualification; STOP/GO threshold, grace, sustained final window, one canonical HP hit or harmless obedience, finite recovery')

-- An order never occupies a replacement incarnation or coerces impossible motion.
local cases={
    {'Hero life',function(e,a) Status:ResetActorLife(hero) end},
    {'source life',function(e,a) Status:ResetActorLife(e) end},
    {'Hero progression',function() hero.LODProgressionState=table.Copy(hero.LODProgressionState) end},
    {'source progression',function(e) e.LODProgressionState=table.Copy(e.LODProgressionState) end},
    {'graph',function() s.Graph=table.Copy(s.Graph) end},
    {'graph progression',function() s.Graph.Progression=table.Copy(s.Graph.Progression) end},
    {'campaign epoch',function() s.CampaignEpoch=s.CampaignEpoch+1 end},
    {'campaign seed',function() s.CampaignSeed=s.CampaignSeed+1 end},
    {'run ID',function() s.RunId=s.RunId..'x' end},
    {'freeze',function() s.SimulationFrozen=true end},
    {'failure',function() s.Failed=true end},
    {'clear',function() s.LevelCleared=true end},
    {'source death',function(e) e.LODDead=true end},
    {'Hero death',function() hero.health=0 end},
    {'disconnect',function() hero.valid=false end},
    {'cloak',function() hero.invisible=true end},
    {'source drift',function(e) e:SetPos(e:GetPos()+Vector(5,0,0)) end},
    {'range',function() hero:SetPos(hero:GetPos()+Vector(370,0,0)) end},
    {'cover',function() util.TraceLine=coverTrace end},
    {'unsupported Hero',function() hero:SetPos(hero:GetPos()+Vector(0,0,15)) end},
    {'blocked escape',function() util.TraceHull=function() return {Hit=true} end end},
    {'forced push',function() hero.LODForcedMovementUntil=time+2 end},
    {'nonwalk',function() hero.moveType=77 end},
    {'Held Hero',function() Status:Apply(hero,'held',hero,{direct=true,duration=2}) end},
    {'source hit-stun',function(e) e.LODHitStunUntil=time+2 end},
    {'source morale',function(e) assert(Status:AttemptMorale(hero,e,{forceMorale=true,rng={Int=function(_,lo) return lo end}})) end},
}
for _,row in ipairs(cases) do
    local e,a=fresh('pacer');advance(e,a.window+.1,0);row[2](e,a)
    step(e,math.min(a.ready,time+.2),0)
    if e.LODRosterAttack then advance(e,a.ready,0) end
    assert(hero.hits==0 and not e.LODRosterAttack,'safe cancellation: '..row[1])
end
for _,statusId in ipairs({'held','muted'}) do
    local e,a=fresh('pacer');Status:Apply(e,statusId,hero,{direct=true,duration=3});advance(e,a.ready,0)
    assert(hero.hits==1,'stationary physical source permits '..statusId..' claimed='..tostring(a.claimed)..' invalid='..tostring(a.invalidMotion)..' first='..tostring(a.sampleFirst)..' last='..tostring(a.sampleLast)..' ready='..tostring(a.ready)..' active='..tostring(e.LODRosterAttack~=nil))
end
-- Stale/unavailable/NaN motion cannot turn into a harmful GO judgment.
do
    local e,a=fresh('pacer');at(time+.26);E.NextService=0;env.hooks.LOD_EnemyRosterAttacks()
    assert(not e.LODRosterAttack and hero.hits==0,'stale motion and service gap fail closed')
    e,a=fresh('pacer');advance(e,a.window-.01,0)
    at(a.ready);sample(hero,0);E:StepDiscipline(e,a,time)
    assert(not e.LODRosterAttack and hero.hits==0,'missed judgment coverage cannot catch up')
    e=pair('pacer');Rules.DodgeMotion[hero].walk=0;assert(not E:BeginDiscipline(e,hero,time))
    Rules.DodgeMotion[hero].walk=200;Rules.DodgeMotion[hero].speed=0/0;assert(not E:BeginDiscipline(e,hero,time))
    e,a=fresh('pacer');advance(e,a.window+.05,0);at(time+.16);sample(hero,0);E:StepDiscipline(e,a,time)
    assert(not e.LODRosterAttack and hero.hits==0,'final sample hole fails closed')
end
-- Qualification itself subtracts engine base velocity and masks forced motion.
do
    local e=pair('halter');hero.GetBaseVelocity=function() return Vector(90,0,0) end;sample(hero,100)
    assert(E:DisciplineMotion(hero,time)==false,'base velocity cannot create locomotion')
    hero.LODForcedMovementUntil=time+1;sample(hero,100)
    assert(E:DisciplineMotion(hero,time)==nil,'forced movement cancels both requirements')
end
print('BESTIARY_B16_LIFECYCLE_PASS: exact lives/scopes, support/cover/hull, cloak, force/Held/nonwalk, real motion qualifications, stale observations and missed coverage fail closed')

-- One exact ownership token across both modes; stale release never steals it.
do
    local e,a=fresh('halter');local other=actor('pacer');other:SetPos(e:GetPos());E:Prepare(other)
    assert(not E:BeginDiscipline(other,hero,time),'incompatible demand rejected')
    E:Cancel(e);at(time+.6);sample(hero,0)
    assert(E:BeginDiscipline(other,hero,time),'owner release permits fresh demand')
    local current=other.LODRosterAttack;E:RetireDiscipline(e,a)
    assert(E:DisciplineValid(other,current,time),'old token cannot clear newer reservation')
    other.valid=false
    local replacement=actor('pacer');replacement:SetPos(e:GetPos());E:Prepare(replacement)
    assert(E:BeginDiscipline(replacement,hero,time),'removed source cannot pin Hero')
end
-- Fixed cap counts only live demands, without enemy/player scans.
do
    local e=pair('halter');local list={}
    for i=1,16 do
        local p=extraHero(center()+Vector(90,0,2));p.GetMoveType=hero.GetMoveType;p.moveType=MOVETYPE_WALK
        p.GetBaseVelocity=hero.GetBaseVelocity;p.OnGround=hero.OnGround;p.GetWalkSpeed=hero.GetWalkSpeed
        p.GetRunSpeed=hero.GetRunSpeed;p.KeyDown=hero.KeyDown
        local source=actor('halter');source:SetPos(center()+Vector(0,0,2));E:Prepare(source);sample(p,0)
        assert(E:BeginDiscipline(source,p,time),'cap setup '..i);list[#list+1]=source
    end
    assert(not E:BeginDiscipline(e,hero,time),'17th commitment denied')
    E:Cancel(list[1]);at(time+.6)
    -- The old16 have expired observations and must not consume new capacity.
    sample(hero,0);assert(E:BeginDiscipline(e,hero,time),'stale commitments do not exhaust cap')
end
print('BESTIARY_B16_OWNERSHIP_PASS: exclusive Hero token, conditional release, removed-owner recovery and bounded cap')

-- Every FinishMove is observed, even a violation overwritten before Think.
do
    local e,a=fresh('halter');advance(e,a.window+.05,0)
    at(time+.005);sample(hero,100);sample(hero,0)
    advance(e,a.ready,0);assert(hero.hits==1,'inter-service and same-time violation retained')
    e=pair('pacer');hero.LODForcedMovementUntil=time+.01;sample(hero,0);at(time+.02)
    assert(not E:BeginDiscipline(e,hero,time),'sample made while forced remains inadmissible after force expiry')
    sample(hero,0);at(time+.6);sample(hero,0);assert(E:BeginDiscipline(e,hero,time),'fresh unforced sample restores admission')
end
-- Test final authorization failure, exact packet replay and mitigation mutations.
local realTake=hero.TakeDamageInfo
local function resolveMutation(mutate)
    local e,a=fresh('pacer');advance(e,a.ready-.025,0)
    local hp=hero:Health();local saved=LOD.CombatRolls.QueueDamageReport
    LOD.CombatRolls.QueueDamageReport=function(self,info,callback)
        mutate(e,a,info);return saved(self,info,callback)
    end
    advance(e,a.ready,0);LOD.CombatRolls.QueueDamageReport=saved
    assert(hero:Health()==hp,'callback mutation cannot damage replacement/invalid geometry')
    return e,a
end
resolveMutation(function() hero.LODProgressionState=table.Copy(hero.LODProgressionState) end)
resolveMutation(function() Status:ResetActorLife(hero) end)
resolveMutation(function(e) Status:ResetActorLife(e) end)
resolveMutation(function() hero.GetCollisionBounds=function() return Vector(-90,-90,0),Vector(90,90,90) end
    util.TraceHull=function(t) return {Hit=t.maxs.x>=90,HitPos=t.endpos} end end)
resolveMutation(function() s.Graph=table.Copy(s.Graph) end)
do
    local e,a=fresh('pacer');advance(e,a.ready-.025,0)
    local authorize=E.AuthorizeRosterDamage;local hp=hero:Health()
    E.AuthorizeRosterDamage=function(self,info,source,target,gate)
        Status:ResetActorLife(target);return authorize(self,info,source,target,gate)
    end
    advance(e,a.ready,0);E.AuthorizeRosterDamage=authorize
    assert(hero.hits==0 and hero:Health()==hp,'failed final native authorization fails closed')
end
-- Real GM wraps canonical mitigation: life invalidation inside Block is caught
-- before native HP assignment. Reentrant/replayed info can never settle twice.
do
    local e,a=fresh('pacer');advance(e,a.ready-.025,0)
    local block=Rules.ApplyBlock;local hp=hero:Health()
    Rules.ApplyBlock=function(self,p,info) Status:ResetActorLife(p);return false end
    advance(e,a.ready,0);Rules.ApplyBlock=block
    assert(hero:Health()==hp,'post-mitigation life validation guards native HP')
    e,a=fresh('pacer');local packet
    hero.TakeDamageInfo=function(self,info) packet=info;realTake(self,info) end
    advance(e,a.ready,0);hero.TakeDamageInfo=realTake
    assert(packet and packet:GetDamage()>0,'one owned packet applied')
    hp=hero:Health();realTake(hero,packet)
    assert(packet:GetDamage()==0 and hero:Health()==hp,'spent packet replay zeroed')
    e,a=fresh('pacer');advance(e,a.ready-.025,0)
    local call=0;local native=hero.TakeDamageInfo
    hero.TakeDamageInfo=function(self,info)
        call=call+1;E:StepDiscipline(e,a,time);native(self,info)
    end
    advance(e,a.ready,0);hero.TakeDamageInfo=native
    assert(call==1,'claimed reentry cannot generate another packet')
end
-- A native callback may install a newer attack: finishing the old one cannot
-- erase its reservation/warning or install recovery/activity on top of it.
do
    local e,a=fresh('pacer');advance(e,a.ready-.025,0)
    local later={};local take=hero.TakeDamageInfo
    hero.TakeDamageInfo=function(self,info) e.LODRosterAttack=later;take(self,info) end
    advance(e,a.ready,0);hero.TakeDamageInfo=take
    assert(e.LODRosterAttack==later and not e.LODMeleeRecovery,'newer attack survives old settlement')
    e,a=fresh('pacer');local setter=e.SetNW2Int;local replaced=false
    e.SetNW2Int=function(self,k,value)
        setter(self,k,value)
        if k=='LOD_DisciplineMode' and value==0 and not replaced then replaced=true;self.LODRosterAttack=later end
    end
    E:Finish(e,time);assert(e.LODRosterAttack==later and not e.LODMeleeRecovery,'cancel replication cannot erase newer attack')
    e,a=fresh('pacer');local stop=LOD.HostileMotionV2.Stop;local idle=0
    e._SetActivity=function() idle=idle+1 end
    LOD.HostileMotionV2.Stop=function(self,actor) stop(self,actor);actor.LODRosterAttack=later end
    E:Finish(e,time);LOD.HostileMotionV2.Stop=stop
    assert(e.LODRosterAttack==later and idle==0,'Stop callback replacement preserves new activity')
end
-- Throwing native callbacks leave a spent commitment only until its deadline,
-- retaining the first recovery end and releasing its exact Hero token afterward.
do
    local e,a=fresh('pacer');advance(e,a.ready-.025,0)
    hero.TakeDamageInfo=function() error('injected native boundary') end
    local ok=pcall(function() advance(e,a.ready,0) end);hero.TakeDamageInfo=realTake
    assert(not ok and a.claimed and e.LODRosterAttack==a,'failed native call remains claimed')
    local recovery=a.recoveryUntil;at(a.deadline+.01);sample(hero,0);service(time)
    assert(not e.LODRosterAttack and e.LODMeleeRecovery.expires==recovery,'error cannot pin or extend recovery')
    local other=actor('halter');other:SetPos(e:GetPos());E:Prepare(other)
    assert(E:BeginDiscipline(other,hero,time),'claimed failure released Hero token')
end
print('BESTIARY_B16_CALLBACK_PASS: every canonical motion observation, force-expiry, exact authorization/replay/reentry, native mitigation replacements, changed hulls, newer-attack preservation and fixed error expiry')
