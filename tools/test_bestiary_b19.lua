-- B19 exercises ordinary-ally relays and moving endpoint hazards through production AI and damage gates.
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
s.CampaignEpoch=1;s.RunId='b19';s.CampaignSeed=77;s.LevelSeed=123
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
hero.SteamID64=function() return 'b19-tester' end
hero.Nick=function() return 'B19 tester' end
hero.GetNW2Bool=hero.GetNW2Float
LOD.RunManager.IdentityOf=function(_,p) return p==hero and 'b19-tester' or nil end
local priorGetState=LOD.RunManager.GetPlayerState
LOD.RunManager.GetPlayerState=function(self,p)
    if p=='b19-tester' then return {progressionState=hero.LODProgressionState} end
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
    p.SteamID64=function() return 'b19-other-'..p.index end
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


dofile(root..'sv_enemy_companions.lua');dofile(root..'sv_enemy_edicts.lua');dofile(root..'sv_enemy_support.lua');dofile(root..'sv_enemy_links.lua')
-- Source entities/traces are doubles. Tick, shared Think, CommitAttack,
-- life binding, factions, damage authorization and native GM mitigation are real.
MOVETYPE_WALK=2
hero.GetMoveType=function() return MOVETYPE_WALK end
hero.GetBaseVelocity=function() return vector_origin end
hero.OnGround=function() return true end
hero.GetWalkSpeed=function() return 200 end
hero.GetRunSpeed=function() return 400 end
hero.KeyDown=function() return false end
local function sample(p)
    env.hooks.LOD_RPG_DodgeVoluntaryMotion(p,{GetVelocity=function() return Vector() end})
end
local priorPair=pair
pair=function(id)
    local e=priorPair(id)
    hero.LODForcedMovementUntil=nil;hero:SetPos(center()+Vector(90,0,2))
    hero.GetCollisionBounds=function() return Vector(-16,-16,0),Vector(16,16,72) end
    e.LODProgressionState.featIds={};e.LODProgressionState.derivedStats={}
    sample(hero)
    return e
end
local function fresh(id)
    local e=pair(id);E:Tick(e)
    return e,assert(e.LODRosterAttack,'production AI commits '..id)
end
local function step(e,n) at(n);sample(hero);E:Tick(e);service(n) end
advance=function(e,untilTime)
    while time<untilTime-1e-8 do step(e,math.min(untilTime,time+.025)) end
    if time<untilTime then step(e,untilTime) end
end
local function lineFixture(blocker)
    local before=util.TraceLine
    util.TraceLine=function(t)
        if t.mask==MASK_SHOT then
            if blocker then return {Hit=true,Entity=blocker,HitPos=t.endpos} end
            local delta=t.endpos-t.start;local point=hero:WorldSpaceCenter()-t.start
            local along=math.max(0,math.min(1,point:Dot(delta)/delta:LengthSqr()))
            if (point-delta*along):LengthSqr()<=16^2 then return {Hit=true,Entity=hero,HitPos=t.endpos} end
            return {Hit=false,HitPos=t.endpos}
        end
        return before(t)
    end
end
local function linked(id,setup)
    local e=pair(id);local w=actor('soldier');w:SetPos(center()+Vector(180,0,2));w.LODRosterContext=E:Bind({},s)
    D.Entities={e,w};if setup then setup(e,w) end
    E:Tick(e);return e,assert(e.LODRosterAttack,'production Tick commits '..id),w
end
local function shot(e,a)
    lineFixture();advance(e,a.ready+.01)
end
-- Real AI admission, guarded native packet, source attribution and one settlement.
local e,a,w=linked('relay');assert(a.mode==1 and a.ward==w)
local fixed=Vector(a.from.x,a.from.y,a.from.z);local aim=Vector(a.aim.x,a.aim.y,a.aim.z)
shot(e,a);assert(hero.hits==1 and receivedContext.physical and not receivedContext.magic)
assert(not e.LODRosterAttack and e.LODMeleeRecovery and e.LODNextAttack>time)
service(time+.1);assert(hero.hits==1,'one claim across repeated service')
-- Ordinary ward AI is never commandeered; Relay endpoint and aim are frozen.
e,a,w=linked('relay');w:SetPos(w:GetPos()+Vector(0,8,0));hero:SetPos(hero:GetPos()+Vector(0,64,0))
lineFixture();advance(e,a.ready+.01);assert(hero.hits==0 and a.from:DistToSqr(fixed)<.001 and a.aim:DistToSqr(aim)<.001)
-- First unrelated body/world absorbs; no faction exception or friendly-fire damage.
for _,blocker in ipairs({{valid=true},NULL}) do
    e,a,w=linked('relay');lineFixture(blocker);advance(e,a.ready+.01);assert(hero.hits==0)
end
-- Filter excludes exactly the emitter and captured ward, never arbitrary hostiles.
e,a,w=linked('relay');local oldTrace=util.TraceLine
util.TraceLine=function(t)
    if t.mask==MASK_SHOT then assert(not t.filter(e) and not t.filter(w) and t.filter(hero));return {Hit=true,Entity=hero,HitPos=t.endpos} end
    return oldTrace(t)
end
advance(e,a.ready+.01);assert(hero.hits==1)
-- Both identities retain a complete source-shot warning without a qualifying ward.
for _,id in ipairs({'relay','lacemaker'}) do
    e,a=fresh(id);assert(a.mode==3 and math.abs(a.ready-a.started-1.4)<.001)
    advance(e,a.ready-.05);assert(hero.hits==0);lineFixture();advance(e,a.ready+.01);assert(hero.hits==1)
end
-- Ribbon follows a genuinely moving ordinary ally without changing its AI target.
e,a,w=linked('lacemaker',function(source,ward) hero:SetPos(center()+Vector(90,50,2));ward.LODTarget=hero end)
assert(a.mode==2)
-- The captured ally moves during preparation, pauses, then resumes its own chase.
-- Position transport is a native boundary double; the channel never supplies motion.
for i=1,2 do w:SetPos(w:GetPos()+Vector(0,20,0));step(e,time+.15) end
advance(e,a.ready+.01);assert(a.phase=='active' and hero.hits==0)
for i=1,2 do w:SetPos(w:GetPos()+Vector(0,20,0));step(e,time+.15) end
assert(hero.hits==1 and w.LODTarget==hero,'moving endpoint catches captured Hero once')
assert(w:GetPos():DistToSqr(a.wardOrigin)==80^2,'channel never moves ward')
local delta=w:GetPos()-a.origin;local along=(hero:GetPos()-a.origin):Dot(delta)/delta:LengthSqr()
local expectedOrigin=a.origin+delta*along+Vector(0,0,24)
assert(receivedContext.damageContract.sourcePosition:DistToSqr(expectedOrigin)<.001,
    'canonical directional Block/damage contract uses closest ribbon point')
-- No swept/catch-up contacts: crossing between service samples does not hit.
e,a,w=linked('lacemaker',function() hero:SetPos(center()+Vector(90,40,2)) end)
advance(e,a.ready+.01);hero:SetPos(center()+Vector(90,-40,2));step(e,time+.05)
assert(hero.hits==0);advance(e,a.activeEnd+.01);assert(hero.hits==0 and not e.LODRosterAttack)
-- One reserved link per ward; second source falls back, release frees the ward.
e,a,w=linked('relay');local other=actor('relay');other:SetPos(center()+Vector(0,12,2));other.LODTarget=hero
E:Prepare(other);D.Entities={e,w,other};E:Tick(other);assert(other.LODRosterAttack.mode==3)
E:Cancel(e);E:Cancel(other);other.LODNextAttack=0;assert(E:Begin(other,hero,time));assert(other.LODRosterAttack.ward==w)
-- Actual life/status/context gates reject every captured incarnation replacement.
for _,mutate in ipairs({
    function(source,ward) Status:ResetActorLife(ward) end,
    function(source,ward) ward.LODProgressionState=table.Copy(ward.LODProgressionState) end,
    function() Status:ResetActorLife(hero) end,
    function(source) Status:ResetActorLife(source) end,
    function(source,ward) ward.LODDead=true;ward.health=0 end,
    function() s.Graph=table.Copy(s.Graph) end,
    function() s.CampaignEpoch=s.CampaignEpoch+1 end,
    function() s.SimulationFrozen=true end,
    function(source,ward) ward:SetPos(ward:GetPos()+Vector(0,33,0)) end,
    function(source) source:SetPos(source:GetPos()+Vector(5,0,0)) end,
}) do
    e,a,w=linked('relay');mutate(e,w);step(e,time+.05);assert(hero.hits==0 and e.LODRosterAttack~=a)
end
-- Ribbon cannot exploit forced movement, immobility, excessive endpoint speed,
-- unsupported escape geometry or stale service to manufacture unavoidable hits.
for _,mutate in ipairs({
    function() hero.LODForcedMovementUntil=time+3 end,
    function() hero.GetMoveType=function() return 7 end end,
    function(source,ward) ward:SetPos(ward:GetPos()+Vector(0,33,0)) end,
    function() util.TraceHull=function(t) return {Hit=true,HitPos=t.endpos} end end,
    function(source) source.LODHitStunUntil=time+3 end,
}) do
    hero.GetMoveType=function() return MOVETYPE_WALK end
    e,a,w=linked('lacemaker');mutate(e,w);step(e,time+.05);assert(hero.hits==0 and not e.LODRosterAttack)
end
hero.GetMoveType=function() return MOVETYPE_WALK end
e,a,w=linked('lacemaker');step(e,time+.3);assert(hero.hits==0 and not e.LODRosterAttack)
-- Held/Muted permit stationary physical attacks, while morale/prohibition cancel.
for _,id in ipairs({'held','muted'}) do
    e,a,w=linked('relay');assert(Status:Apply(e,id,nil,{duration=5,skipSave=true}));shot(e,a);assert(hero.hits==1)
end
-- Geometry callback replacing the ward at damage time fails closed after rolls.
e,a,w=linked('relay');lineFixture();local originalResolve=LOD.CombatRolls.ResolveActorDamage
LOD.CombatRolls.ResolveActorDamage=function(self,...)
    local result=originalResolve(self,...);Status:ResetActorLife(w);return result
end
advance(e,a.ready+.01);LOD.CombatRolls.ResolveActorDamage=originalResolve;assert(hero.hits==0)
-- Native defense callbacks cannot transfer an already authorized packet to a new life.
for _,id in ipairs({'relay','lacemaker'}) do
    for _,recipient in ipairs({'source','ward','hero'}) do
        e,a,w=linked(id);if id=='relay' then lineFixture() end
        local before=hero:Health();local block=Rules.ApplyBlock
        Rules.ApplyBlock=function(self,p,info)
            Status:ResetActorLife(recipient=='source' and e or recipient=='ward' and w or hero);return false
        end
        advance(e,a.ready);Rules.ApplyBlock=block
        assert(hero:Health()==before,'post-defense '..recipient..' life replacement rejects '..id)
    end
end
-- Publishing cannot erase a replacement action or transfer a tell to a new ward life.
for _,replace in ipairs({false,true}) do
    e=pair('relay');w=actor('soldier');w:SetPos(center()+Vector(180,0,2));D.Entities={e,w}
    local setter=e.SetNW2Int;local newer={}
    e.SetNW2Int=function(self,k,n)
        setter(self,k,n)
        if k=='LOD_LinkMode' then
            if replace then self.LODRosterAttack=newer else Status:ResetActorLife(w) end
        end
    end
    assert(not E:BeginLink(e,hero,time))
    assert(replace and e.LODRosterAttack==newer or not replace and not e.LODRosterAttack)
end
-- Geometry callbacks may admit another valid owner; final preflight preserves it.
do
    e=pair('relay');w=actor('soldier');w:SetPos(center()+Vector(180,0,2))
    local rival=actor('relay');rival:SetPos(e:GetPos());E:Prepare(rival);D.Entities={e,w,rival}
    local space=E.LinkSpace;local entered=false
    E.LinkSpace=function(self,source,attack)
        if source==e and not entered then entered=true;assert(E:BeginLink(rival,hero,time)) end
        return space(self,source,attack)
    end
    assert(not E:BeginLink(e,hero,time));E.LinkSpace=space
    assert(rival.LODRosterAttack.ward==w and E:LinkValid(rival,rival.LODRosterAttack,time))
end
-- Eight candidate geometry preflights bound expensive probes even in a crowded cell.
do
    e=pair('relay');D.Entities={e}
    for i=1,9 do local ward=actor('soldier');ward:SetPos(center()+Vector(180,i,2));D.Entities[#D.Entities+1]=ward end
    local space=E.LinkSpace;local attempts=0
    E.LinkSpace=function(self,source,attack)
        if attack.ward then attempts=attempts+1;return false end
        return space(self,source,attack)
    end
    assert(E:BeginLink(e,hero,time));E.LinkSpace=space
    assert(attempts==8 and e.LODRosterAttack.mode==3,'bounded probes retain solo fallback')
end
-- Geometry callbacks cannot overbook the final service slot.
do
    e=pair('relay');local keep={}
    for i=1,15 do
        local source=actor('relay');source:SetPos(e:GetPos());E:Prepare(source)
        assert(E:BeginLink(source,hero,time));keep[#keep+1]=source
    end
    local inner=actor('relay');inner:SetPos(e:GetPos());E:Prepare(inner)
    local trace=util.TraceHull;local entered=false
    util.TraceHull=function(t)
        if not entered then entered=true;assert(E:BeginLink(inner,hero,time)) end
        return trace(t)
    end
    assert(not E:BeginLink(e,hero,time),'final callback-free cap check rejects seventeenth')
    assert(E:LinkCount(time)==16)
end
-- Reentrant service during damage cannot replay, and replacement attack survives cleanup.
e,a,w=linked('relay');lineFixture();local originalNative=hero.TakeDamageInfo;local newer={kind='future'}
hero.TakeDamageInfo=function(self,info)
    E:StepLink(e,a,time);originalNative(self,info);e.LODRosterAttack=newer
end
advance(e,a.ready-.001);step(e,a.ready);hero.TakeDamageInfo=originalNative
assert(hero.hits==1 and e.LODRosterAttack==newer,'older settlement preserves replacement')
E:Cancel(e)
-- Callback failure leaves one claimed packet and fixed recovery, then retires on deadline.
e,a,w=linked('relay');lineFixture();hero.TakeDamageInfo=function() error('native boundary failure') end
local ok=pcall(function() advance(e,a.ready+.001) end);assert(not ok and a.claimed)
hero.TakeDamageInfo=originalNative;local recovery=a.recoveryUntil
at(a.deadline+.001);E:StepLink(e,a,time)
assert(not e.LODRosterAttack and e.LODNextAttack==recovery and hero.hits==0)
print('PASS Bestiary B19: production AI, moving links, frozen relay, first-body cover, guarded packets, reservations, lifecycle, geometry, reentry and bounded failure')
