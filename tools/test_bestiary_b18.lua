-- B18 exercises attack restraint and displaced refuges through production AI and damage gates.
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
s.CampaignEpoch=1;s.RunId='b18';s.CampaignSeed=77;s.LevelSeed=123
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
hero.SteamID64=function() return 'b18-tester' end
hero.Nick=function() return 'B18 tester' end
hero.GetNW2Bool=hero.GetNW2Float
LOD.RunManager.IdentityOf=function(_,p) return p==hero and 'b18-tester' or nil end
local priorGetState=LOD.RunManager.GetPlayerState
LOD.RunManager.GetPlayerState=function(self,p)
    if p=='b18-tester' then return {progressionState=hero.LODProgressionState} end
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
    p.SteamID64=function() return 'b18-other-'..p.index end
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


dofile(root..'sv_enemy_companions.lua');dofile(root..'sv_enemy_edicts.lua')
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
local function violate(e,a)
    advance(e,a.ready)
    assert(a.phase=='watch','Censor enters finite observation')
    Rules:CommitAttack(hero)
    step(e,time+.025)
    assert(a.phase=='shot' and math.abs(a.ready-time-1.2)<1e-7,'commit creates complete fresh warning')
    lineFixture();return a.ready
end
-- The two edicts demand distinct actions, with no passive damage interpretation.
local e,a=fresh('censor');local began=time
Rules:CommitAttack(hero) -- preparation is not an armed restraint window.
advance(e,began+.8)
assert(a.phase=='watch' and not a.trigger and hero.hits==0,'preparation attack is ignored')
local ending=a.ready
advance(e,ending)
assert(not e.LODRosterAttack and hero.hits==0,'restraint expires harmlessly')
e,a=fresh('censor');local ready=violate(e,a);local hp=hero:Health()
advance(e,ready)
assert(hero.hits==1 and hero:Health()<hp,'real canonical physical packet applies')
assert(not e.LODRosterAttack and e.LODNextAttack==ready+3,'shot finishes into fixed recovery')
E:StepEdict(e,a,time);assert(hero.hits==1,'spent commitment cannot replay')
for _,location in ipairs({'initial','refuge','escape'}) do
    e,a=fresh('surveyor');hp=hero:Health()
    assert(math.abs(a.aim:Distance(a.refuge)-96)<.001 and math.abs(a.aim:Distance(a.escape)-160)<.001,'displaced refuge and outer exit')
    if location~='initial' then hero:SetPos(a[location]) end
    advance(e,a.ready)
    assert((hero:Health()<hp)==(location=='initial'),'survey verdict '..location)
    assert(hero.hits==(location=='initial' and 1 or 0) and not e.LODRosterAttack,'one finite survey verdict')
end
print('BESTIARY_B18_ACTION_PASS: production Tick/Think and CommitAttack, preparation ignored, finite restraint, fresh shot warning, refuge/outer exit and canonical HP')

-- Passive/reflected ticks are not commits; only the original Hero can trigger.
e,a=fresh('censor');advance(e,a.ready)
local _,receipt=Rules:CommitAttack(hero,true)
assert(not a.trigger,'deferred unsuccessful attack cannot trigger restraint')
local other=extraHero(hero:GetPos());Rules:CommitAttack(other)
assert(not a.trigger,'other Hero commit cannot inherit restraint')
-- Observers are invoked by CommitAttack, not the incoming damage pipeline.
local d=DamageInfo();d:SetDamage(2);d:SetAttacker(hero);d:SetInflictor(hero)
GM:PostEntityTakeDamage(other,d,true)
assert(not a.trigger,'post-damage effects do not count as attack commits')
Rules:ObserveCommittedAttack(hero,receipt);assert(a.trigger,'successful deferred attack notifies canonical observer');at(time+.251);a.last=time
E:StepEdict(e,a,time)
assert(not e.LODRosterAttack and hero.hits==0,'stale committed action cannot retroactively warn')
e,a=fresh('censor');advance(e,a.ready);Rules:CommitAttack(hero)
Status:ResetActorLife(hero);step(e,time+.025)
assert(not e.LODRosterAttack and hero.hits==0,'replacement life cannot inherit committed trigger')
-- Tick-boundary grace services an on-time attack without enlarging the watch.
do
    e,a=fresh('censor');advance(e,a.ready);local watchEnd=a.ready
    advance(e,watchEnd-.025);at(watchEnd-.01);Rules:CommitAttack(hero)
    assert(a.trigger,'last-window canonical attack is captured')
    step(e,watchEnd+.01)
    assert(a.phase=='shot' and math.abs(a.ready-time-1.2)<1e-7,'on-time attack receives full warning after boundary')
    e,a=fresh('censor');advance(e,a.ready);watchEnd=a.ready
    advance(e,watchEnd-.025);at(watchEnd+.01);Rules:CommitAttack(hero)
    assert(not a.trigger,'post-window attack cannot extend watch')
    step(e,time);assert(not e.LODRosterAttack and hero.hits==0,'quiet watch retires within service grace')
end
-- Deferred success belongs to the exact warning captured before native casts.
do
    e,a=fresh('censor');advance(e,a.ready)
    local _,oldReceipt=Rules:CommitAttack(hero,true)
    assert(oldReceipt and not a.trigger,'deferred receipt captures original watch without observing it')
    Status:ResetActorLife(hero);Rules:ObserveCommittedAttack(hero,oldReceipt)
    assert(not a.trigger,'deferred cast cannot carry attack across Hero life replacement')
    e,a=fresh('censor');advance(e,a.ready);_,oldReceipt=Rules:CommitAttack(hero,true)
    E:Cancel(e)
    local rival=actor('censor');rival:SetPos(e:GetPos());rival.LODTarget=hero;E:Prepare(rival)
    assert(E:BeginEdict(rival,hero,time));local nextOrder=rival.LODRosterAttack
    advance(rival,nextOrder.ready);Rules:ObserveCommittedAttack(hero,oldReceipt)
    assert(not nextOrder.trigger,'old deferred success cannot trigger replacement restraint')
    Rules:ObserveCommittedAttack(hero,nil)
    assert(not nextOrder.trigger,'cast begun outside a watch cannot acquire a later warning')
    local _,newReceipt=Rules:CommitAttack(hero,true)
    Rules:ObserveCommittedAttack(hero,newReceipt);assert(nextOrder.trigger,'fresh successful deferred action does observe')
    e,a=fresh('censor');advance(e,a.ready);_,oldReceipt=Rules:CommitAttack(hero,true)
    advance(e,time+.251);Rules:ObserveCommittedAttack(hero,oldReceipt)
    assert(not a.trigger,'late successful callback discards stale receipt')
    local derived=Rules:Derived(hero);derived.rogueAcePrimeSeconds=2;hero.LODRPGNextAceReadyAt=0
    local primed=Rules:CommitAttack(hero,true)
    assert(primed and hero.LODRPGNextAceReadyAt==time+2,'deferred observation preserves Ace prime scheduling')
    assert(not Rules:CommitAttack(hero,true),'deferred observation preserves Ace cooldown')
    derived.rogueAcePrimeSeconds=nil
end
for _,id in ipairs({'censor','surveyor'}) do
    for _,row in ipairs({
        {'Hero life',function() Status:ResetActorLife(hero) end},
        {'source life',function(x) Status:ResetActorLife(x) end},
        {'Hero progression',function() hero.LODProgressionState=table.Copy(hero.LODProgressionState) end},
        {'source progression',function(x) x.LODProgressionState=table.Copy(x.LODProgressionState) end},
        {'graph',function() s.Graph=table.Copy(s.Graph) end},
        {'graph progression',function() s.Graph.Progression=table.Copy(s.Graph.Progression) end},
        {'campaign epoch',function() s.CampaignEpoch=s.CampaignEpoch+1 end},
        {'campaign seed',function() s.CampaignSeed=s.CampaignSeed+1 end},
        {'run',function() s.RunId=s.RunId..'x' end},
        {'frozen',function() s.SimulationFrozen=true end},
        {'clear',function() s.LevelCleared=true end},
        {'failed',function() s.Failed=true end},
        {'disconnect',function() hero.valid=false end},
        {'source death',function(x) x.LODDead=true end},
        {'Hero death',function() hero.health=0 end},
        {'concealment',function() hero.invisible=true end},
        {'source drift',function(x) x:SetPos(x:GetPos()+Vector(5,0,0)) end},
        {'range',function() hero:SetPos(hero:GetPos()+Vector(370,0,0)) end},
        {'source hit stun',function(x) x.LODHitStunUntil=time+2 end},
        {'world cover',function() util.TraceLine=coverTrace end},
        {'support lost',function() hero:SetPos(hero:GetPos()+Vector(0,0,30)) end},
        {'route blocked',function() util.TraceHull=function() return {Hit=true} end end},
    }) do
        e,a=fresh(id);if id=='censor' and row[1]=='route blocked' then violate(e,a) end;row[2](e,a);step(e,time+.21)
        assert(not e.LODRosterAttack and hero.hits==0,id..' safely cancels '..row[1])
    end
    e,a=fresh(id);step(e,time+.251)
    assert(not e.LODRosterAttack and hero.hits==0,'missed service cancels '..id)
end
print('BESTIARY_B18_LIFE_PASS: exact participants/scopes, original commit source, no passive observer, stale actions, service gaps, visibility/support and geometry')

-- Refuge and outside escape must BOTH be traversable using the actual hull.
for _,route in ipairs({'refuge','escape'}) do
    e=pair('surveyor');local old=util.TraceHull
    util.TraceHull=function(t)
        local length=(t.endpos-t.start):Length2D()
        if (route=='refuge' and math.abs(length-96)<1) or (route=='escape' and math.abs(length-160)<1) then
            return {Hit=true,HitPos=t.endpos}
        end
        return old(t)
    end
    assert(not E:BeginEdict(e,hero,time),'untraversable '..route..' rejects admission')
end
for _,distance in ipairs({96,160}) do
    e=pair('surveyor');local trace=util.TraceLine;local base=hero:GetPos()
    util.TraceLine=function(t)
        if t.start.x==t.endpos.x and t.start.y==t.endpos.y and t.start.z>t.endpos.z
            and math.abs(math.abs(t.start.y-base.y)-distance)<.01 then
            return {Hit=false,HitPos=t.endpos}
        end
        return trace(t)
    end
    assert(not E:BeginEdict(e,hero,time),'unsupported frozen endpoint rejects either refuge sign '..distance)
end
e=pair('surveyor');hero.GetCollisionBounds=function() return Vector(-80,-80,0),Vector(80,80,100) end
util.TraceHull=function(t) return {Hit=t.maxs.x>=80,HitPos=t.endpos} end
assert(not E:BeginEdict(e,hero,time),'actual enlarged Hero hull used')
for _,blocker in ipairs({'world','body','late Hero','off lane'}) do
    e,a=fresh('censor');violate(e,a)
    if blocker=='world' then lineFixture(NULL)
    elseif blocker=='body' then lineFixture(actor('runner'))
    elseif blocker=='late Hero' then lineFixture(extraHero(hero:GetPos()))
    else hero:SetPos(hero:GetPos()+Vector(0,55,0)) end
    advance(e,a.ready)
    assert(hero.hits==0,'fixed shot counterplay '..blocker)
end
-- Physical Censor permits Held/Muted; Raw Magic Surveyor requires speech.
-- Surveyor judges position; forced movement suspends the demand harmlessly.
for _,id in ipairs({'censor','surveyor'}) do
    for _,status in ipairs({'held','muted'}) do
        e,a=fresh(id);Status:Apply(e,status,hero,{direct=true,duration=5})
        if id=='censor' then violate(e,a) end
        advance(e,a.ready);assert(hero.hits==((id=='surveyor' and status=='muted') and 0 or 1),'stationary source status '..status..' '..id)
    end
    e,a=fresh(id);Status:Apply(e,'intimidated',hero,{direct=true,duration=5});step(e,time+.025)
    assert(not e.LODRosterAttack,'attack prohibition cancels '..id)
end
e,a=fresh('surveyor');hero.LODForcedMovementUntil=time+5;hero:SetPos(a.refuge)
advance(e,a.ready);assert(hero.hits==0,'forced movement to refuge still protects Hero')
print('BESTIARY_B18_COUNTERPLAY_PASS: both routes, actual enlarged hull, first collision, fixed aim, Held/Muted distinctions and forced-movement cancellation')

-- Four incompatible demands share exact reservation and release semantics.
for _,id in ipairs({'censor','surveyor'}) do
    e,a=fresh(id)
    for _,otherId in ipairs({'censor','surveyor','halter','pacer'}) do
        local rival=actor(otherId);rival:SetPos(e:GetPos());E:Prepare(rival);sample(hero)
        local admitted=(otherId=='halter' or otherId=='pacer') and E:BeginDiscipline(rival,hero,time)
            or E:BeginEdict(rival,hero,time)
        assert(not admitted,'exclusive Hero demand '..id..'/'..otherId)
    end
    E:Cancel(e);local rival=actor('surveyor');rival:SetPos(e:GetPos());E:Prepare(rival)
    assert(E:BeginEdict(rival,hero,time),'released reservation reusable')
    local current=rival.LODRosterAttack;E:RetireEdict(e,a)
    assert(E:EdictValid(rival,current,time),'stale release cannot steal newer token')
    rival.valid=false;local replacement=actor('censor');replacement:SetPos(e:GetPos());E:Prepare(replacement)
    assert(E:BeginEdict(replacement,hero,time),'removed owner cannot pin Hero')
end
for _,id in ipairs({'halter','pacer'}) do
    e=pair(id);assert(E:BeginDiscipline(e,hero,time),'B16 setup')
    local rival=actor('censor');rival:SetPos(e:GetPos());E:Prepare(rival)
    assert(not E:BeginEdict(rival,hero,time),'B16 reservation excludes B18')
end
do
    e=pair('surveyor');local keep={}
    for i=1,16 do
        local p=extraHero(hero:GetPos());p.GetMoveType=hero.GetMoveType;local source=actor('surveyor');source:SetPos(e:GetPos());E:Prepare(source)
        assert(E:BeginEdict(source,p,time),'bounded capacity setup '..i);keep[#keep+1]=source
    end
    assert(not E:BeginEdict(e,hero,time),'seventeenth edict denied')
    E:Cancel(keep[1]);e.LODNextAttack=0
    assert(E:BeginEdict(e,hero,time),'released capacity reusable')
end
-- Cross-mode native preflight callbacks cannot overwrite an intervening order.
for _,id in ipairs({'halter','pacer'}) do
    e=pair(id);local rival=actor('surveyor');rival:SetPos(e:GetPos());E:Prepare(rival)
    local trace=util.TraceHull;local entered=false
    util.TraceHull=function(t)
        if not entered then entered=true;assert(E:BeginEdict(rival,hero,time),'callback admits B18') end
        return trace(t)
    end
    assert(not E:BeginDiscipline(e,hero,time),'B16 preflight cannot steal fresh B18 token')
    assert(not e.LODRosterAttack and E:EdictValid(rival,rival.LODRosterAttack,time),'fresh B18 order remains owned')
    e=pair(id);local later={};trace=util.TraceHull
    util.TraceHull=function(t) e.LODRosterAttack=later;return trace(t) end
    assert(not E:BeginDiscipline(e,hero,time) and e.LODRosterAttack==later,'B16 preflight preserves newer source attack')
end
for _,id in ipairs({'censor','surveyor'}) do
    e=pair(id);local rival=actor('halter');rival:SetPos(e:GetPos());E:Prepare(rival)
    local trace=util.TraceLine;local entered=false
    util.TraceLine=function(t)
        if not entered then entered=true;assert(E:BeginDiscipline(rival,hero,time),'callback admits B16') end
        return trace(t)
    end
    assert(not E:BeginEdict(e,hero,time),'B18 preflight cannot steal fresh B16 token')
    assert(not e.LODRosterAttack and E:DisciplineValid(rival,rival.LODRosterAttack,time),'fresh B16 order remains owned')
end
do
    e=pair('surveyor');local keep={}
    for i=1,15 do
        local p=extraHero(hero:GetPos());p.GetMoveType=hero.GetMoveType
        local source=actor('surveyor');source:SetPos(e:GetPos());E:Prepare(source)
        assert(E:BeginEdict(source,p,time));keep[#keep+1]=source
    end
    local p=extraHero(hero:GetPos());p.GetMoveType=hero.GetMoveType
    local inner=actor('surveyor');inner:SetPos(e:GetPos());E:Prepare(inner)
    local trace=util.TraceHull;local entered=false
    util.TraceHull=function(t)
        if not entered then entered=true;assert(E:BeginEdict(inner,p,time),'callback admits sixteenth') end
        return trace(t)
    end
    assert(not E:BeginEdict(e,hero,time),'native geometry cannot overbook cap')
end
print('BESTIARY_B18_OWNERSHIP_PASS: cross-B16/B18 exclusivity both directions, exact release, stale removal and bounded capacity')

-- Native callbacks may invalidate geometry/lives after all warning checks.
local function resolveMutation(id,mutate)
    e,a=fresh(id);if id=='censor' then violate(e,a) end
    advance(e,a.ready-.025);local before=hero:Health();local saved=LOD.CombatRolls.QueueDamageReport
    LOD.CombatRolls.QueueDamageReport=function(self,info,callback) mutate(e,a);return saved(self,info,callback) end
    advance(e,a.ready);LOD.CombatRolls.QueueDamageReport=saved
    assert(hero:Health()==before,'callback mutation cannot inherit packet '..id)
end
for _,id in ipairs({'censor','surveyor'}) do
    resolveMutation(id,function() Status:ResetActorLife(hero) end)
    resolveMutation(id,function(x) Status:ResetActorLife(x) end)
    resolveMutation(id,function() s.Graph=table.Copy(s.Graph) end)
    resolveMutation(id,function() hero.LODProgressionState=table.Copy(hero.LODProgressionState) end)
    resolveMutation(id,function(x,attack) hero:SetPos(id=='surveyor' and attack.refuge or hero:GetPos()+Vector(0,55,0)) end)
    e,a=fresh(id);if id=='censor' then violate(e,a) end
    advance(e,a.ready-.025);local before=hero:Health();local auth=E.AuthorizeRosterDamage
    E.AuthorizeRosterDamage=function(self,info,source,target,gate)
        Status:ResetActorLife(target);return auth(self,info,source,target,gate)
    end
    advance(e,a.ready);E.AuthorizeRosterDamage=auth
    assert(hero.hits==0 and hero:Health()==before,'failed final authorization is harmless')
    e,a=fresh(id);if id=='censor' then violate(e,a) end
    local block=Rules.ApplyBlock;before=hero:Health()
    Rules.ApplyBlock=function(self,p,info) Status:ResetActorLife(p);return false end
    advance(e,a.ready);Rules.ApplyBlock=block
    assert(hero:Health()==before,'native post-mitigation validation')
    e,a=fresh(id);if id=='censor' then violate(e,a) end
    before=hero:Health()
    Rules.ApplyBlock=function(self,p,info)
        hero:SetPos(id=='surveyor' and a.refuge or hero:GetPos()+Vector(0,55,0));return false
    end
    advance(e,a.ready);Rules.ApplyBlock=block
    assert(hero:Health()==before,'post-defense position still obeys original warning')
end
-- Replication callbacks may change exact life or install a newer action.
for _,id in ipairs({'censor','surveyor'}) do
    e=pair(id);local setter=e.SetNW2Int
    e.SetNW2Int=function(self,k,n)
        setter(self,k,n);if k=='LOD_EdictMode' then Status:ResetActorLife(hero) end
    end
    assert(not E:BeginEdict(e,hero,time) and not e.LODRosterAttack,'replication replacement aborts old tell')
    e=pair(id);setter=e.SetNW2Int;local later={}
    e.SetNW2Int=function(self,k,n)
        setter(self,k,n);if k=='LOD_EdictMode' then self.LODRosterAttack=later end
    end
    assert(not E:BeginEdict(e,hero,time) and e.LODRosterAttack==later,'replication replacement preserves newer attack')
end
local realTake=hero.TakeDamageInfo
for _,id in ipairs({'censor','surveyor'}) do
    e,a=fresh(id);if id=='censor' then violate(e,a) end
    local calls,packet=0
    hero.TakeDamageInfo=function(self,info) calls=calls+1;packet=info;E:StepEdict(e,a,time);realTake(self,info) end
    advance(e,a.ready);hero.TakeDamageInfo=realTake
    assert(calls==1 and packet,'native reentry emits one packet')
    local hp=hero:Health();realTake(hero,packet);assert(hero:Health()==hp and packet:GetDamage()==0,'spent packet replay inert')
    e,a=fresh(id);if id=='censor' then violate(e,a) end
    local later={};hero.TakeDamageInfo=function(self,info) e.LODRosterAttack=later;realTake(self,info) end
    advance(e,a.ready);hero.TakeDamageInfo=realTake
    assert(e.LODRosterAttack==later and not e.LODMeleeRecovery,'old callback preserves newer attack')
    e,a=fresh(id);if id=='censor' then violate(e,a) end
    advance(e,a.ready-.025);hero.TakeDamageInfo=function() error('intentional native boundary failure') end
    at(a.ready);local ok=pcall(E.StepEdict,E,e,a,time);hero.TakeDamageInfo=realTake
    assert(not ok and a.claimed,'failed native callback remains spent')
    local fixed=a.recoveryUntil;at(a.deadline+.01);E:StepEdict(e,a,time)
    assert(not e.LODRosterAttack and e.LODNextAttack==fixed,'failure cannot pin or extend original recovery')
end
print('BESTIARY_B18_CALLBACK_PASS: final native authorization, current geometry/life after report and defense callbacks, one-shot reentry/replay, newer attack and finite error recovery')
print('BESTIARY_B18_PASS: production behavior with native boundaries doubled; no native Source acceptance implied')
