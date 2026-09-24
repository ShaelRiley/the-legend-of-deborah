-- B17 exercises companion commitments through the real roster service, motion, receipts and combat pipeline.
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
s.CampaignEpoch=1;s.RunId='b17';s.CampaignSeed=77;s.LevelSeed=123
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


dofile(root..'sv_enemy_support.lua');dofile(root..'sv_enemy_remains.lua');dofile(root..'sv_enemy_companions.lua')
local priorPair=pair
pair=function(id)
    local e=priorPair(id);hero:SetPos(center()+Vector(150,0,2))
    e.LODProgressionState.featIds={};e.LODProgressionState.derivedStats={}
    LOD.EnemyRemains.Active={};LOD.EnemyRemains.Pending={};LOD.EnemyRemains.Count=0
    return e
end
local function ward(e,pos)
    local w=actor('shambler');w:SetPos(pos or center()+Vector(-100,0,2));w.LODActivated=true
    Status:BindActorLife(w);D.Entities[#D.Entities+1]=w
    return w
end
local function fresh(id,withWard)
    local e=pair(id);local w=withWard and ward(e)
    E:Tick(e);return e,assert(e.LODRosterAttack,'real AI companion commitment'),w
end
local function step(e,n) at(n);E:Tick(e);service(n) end
advance=function(e,untilTime)
    while time<untilTime-1e-8 do step(e,math.min(untilTime,time+.025)) end
    if time<untilTime then step(e,untilTime) end
end
local shotTrace=clearTrace
util.TraceLine=function(t) return shotTrace(t) end
local function aimAt(p)
    local before=util.TraceLine
    util.TraceLine=function(t)
        if t.mask==MASK_SHOT then return {Hit=true,Entity=p,HitPos=p:WorldSpaceCenter()} end
        return before(t)
    end
end
for _,id in ipairs({'interposer','mourner'}) do
    local e,a=fresh(id,false);assert(a.phase=='shot','no ward uses fallback')
    local hp=hero:Health();aimAt(hero);advance(e,a.ready)
    assert(hero.hits==1 and hero:Health()<hp,'guarded physical packet reaches captured Hero')
    assert(not e.LODRosterAttack and e.LODNextAttack==a.ready+3,'finite recovery')
end
print('BESTIARY_B17_SHOT_PASS: actual Tick/Think, fallback, native faction+mitigation+HP and fixed recovery')
local e,a,w=fresh('interposer',true)
assert(a.ward==w and a.phase=='prep' and a.goal:DistToSqr(w:GetPos())==64^2,'nearest ward and frozen goal')
local goal=Vector(a.goal.x,a.goal.y,a.goal.z);advance(e,a.ready+.8)
assert(e.LODRosterAttack==a and a.phase=='guard' and e:GetPos():DistToSqr(goal)<.01,'real MotionV2 reaches bodyguard position')
local ending=a.ready;advance(e,ending)
assert(not e.LODRosterAttack and hero.hits==0 and e.LODNextAttack==ending+3,'bodyguard expires without damage')
print('BESTIARY_B17_INTERPOSER_PASS: real MotionV2 route, arrival, finite hold, no damage or defense buff')
local function defeat(w)
    w.LODDead=true;w.health=0
    local r=assert(LOD.EnemyRemains:Seal(w),'canonical sealed defeat')
    LOD.EnemyRemains:Open(w,{hostile=w,startedAt=time,finished=false})
    assert(LOD.EnemyRemains:CorpseLive(r),'canonical opened corpse receipt')
    return r
end
e,a,w=fresh('mourner',true);advance(e,a.ready)
assert(a.phase=='oath' and a.armed and a.oathEnd==a.armed+3,'finite armed oath')
local r=defeat(w);step(e,time+.025)
assert(a.phase=='shot' and a.retaliation and not r.consumed,'sealed defeat creates new warning without consuming corpse')
assert(hero.hits==0 and a.ready==time+1.2,'complete retaliation warning')
aimAt(hero);advance(e,a.ready)
assert(hero.hits==1 and not e.LODRosterAttack,'retaliation resolves once')
E:StepCompanion(e,a,time);assert(hero.hits==1,'replay inert')
print('BESTIARY_B17_MOURNER_PASS: production Seal/Open/CorpseLive, full new warning, one original-Hero shot, no corpse/reward consumption')

-- Every participant and scope belongs to the original warning.
local lifecycle={
    {'Hero life',function() Status:ResetActorLife(hero) end},
    {'source life',function(e) Status:ResetActorLife(e) end},
    {'ward life',function(e,a,w) Status:ResetActorLife(w) end},
    {'Hero progression',function() hero.LODProgressionState=table.Copy(hero.LODProgressionState) end},
    {'source progression',function(e) e.LODProgressionState=table.Copy(e.LODProgressionState) end},
    {'ward progression',function(e,a,w) w.LODProgressionState=table.Copy(w.LODProgressionState) end},
    {'ward displacement',function(e,a,w) w:SetPos(w:GetPos()+Vector(0,33,0)) end},
    {'source displacement',function(e) e:SetPos(e:GetPos()+Vector(0,5,0)) end},
    {'ward removal',function(e,a,w) w.valid=false end},
    {'graph replacement',function() s.Graph=table.Copy(s.Graph) end},
    {'progression replacement',function() s.Graph.Progression=table.Copy(s.Graph.Progression) end},
    {'campaign epoch',function() s.CampaignEpoch=s.CampaignEpoch+1 end},
    {'campaign seed',function() s.CampaignSeed=s.CampaignSeed+1 end},
    {'run ID',function() s.RunId=s.RunId..'x' end},
    {'freeze',function() s.SimulationFrozen=true end},
    {'failure',function() s.Failed=true end},
    {'clear',function() s.LevelCleared=true end},
    {'hit stun',function(e) e.LODHitStunUntil=time+1 end},
    {'cover',function() util.TraceLine=coverTrace end},
    {'Hero concealment',function() hero.invisible=true end},
}
for _,case in ipairs(lifecycle) do
    e,a,w=fresh('mourner',true);case[2](e,a,w);step(e,time+.05)
    assert(not e.LODRosterAttack and hero.hits==0,'cancel '..case[1])
end
for _,case in ipairs({'unsealed','fabricated','early','wrong living life','unobserved','expired','replacement corpse life'}) do
    e,a,w=fresh('mourner',true)
    if case~='early' then advance(e,a.ready) end
    if case=='unsealed' then w.LODDead=true;w.health=0
    elseif case=='fabricated' then w.LODDead=true;w.health=0;w.LODRemainsReceipt={source=w,sourceState=a.wardState,livingLife=a.wardLife,sealedAt=time}
    else
        local receipt=defeat(w)
        if case=='wrong living life' then receipt.livingLife={} end
        if case=='replacement corpse life' then Status:ResetActorLife(w) end
        if case=='unobserved' then at(time+.251);a.last=time end
        if case=='expired' then at(receipt.expires+.01);a.last=time end
    end
    step(e,time+.025)
    assert(not e.LODRosterAttack and hero.hits==0,'reject '..case..' receipt')
end
e,a,w=fresh('mourner',true);advance(e,a.ready);local oathEnd=a.oathEnd;advance(e,oathEnd)
assert(not e.LODRosterAttack and hero.hits==0,'oath expires harmlessly')
e,a,w=fresh('mourner',true);step(e,time+.3)
assert(not e.LODRosterAttack,'missed service never catches up oath')
print('BESTIARY_B17_LIFECYCLE_PASS: exact participants/scopes, drift/visibility, legitimate current armed receipts only, finite oath and service gap')

-- Shared exact ward reservations and bounded admissions.
e,a,w=fresh('mourner',true)
local other=actor('interposer');other:SetPos(e:GetPos());E:Prepare(other);D.Entities[#D.Entities+1]=other
assert(E:BeginCompanion(other,hero,time) and other.LODRosterAttack.phase=='shot','reserved ward produces harmless fallback rather than overlapping oath')
E:Cancel(other);E:Cancel(e);other.LODNextAttack=0
assert(E:BeginCompanion(other,hero,time) and other.LODRosterAttack.ward==w,'release allows other mode')
local newer=other.LODRosterAttack;E:RetireCompanion(e,a)
assert(E:CompanionWard(other,newer,false),'stale token cannot release newer ward')
other.valid=false
local replacement=actor('mourner');replacement:SetPos(center()+Vector(0,0,2));E:Prepare(replacement)
assert(E:BeginCompanion(replacement,hero,time) and replacement.LODRosterAttack.ward==w,'removed owner cannot pin ward')
do
    local source=pair('mourner');local list={}
    for i=1,16 do
        local actor=actor('mourner');actor:SetPos(source:GetPos());E:Prepare(actor)
        assert(E:BeginCompanion(actor,hero,time),'cap setup '..i);list[#list+1]=actor
    end
    assert(not E:BeginCompanion(source,hero,time),'17th commitment denied')
    E:Cancel(list[1]);source.LODNextAttack=0
    assert(E:BeginCompanion(source,hero,time),'released capacity reusable')
end
-- Nearest stable entity-ID selection, rejected wards, and actual enlarged hulls.
do
    e=pair('mourner');local first=ward(e,center()+Vector(-90,0,2));local second=ward(e,center()+Vector(0,-90,2))
    D.Entities={e,second,first};assert(E:BeginCompanion(e,hero,time));assert(e.LODRosterAttack.ward==first,'stable distance/ID tie')
    for _,id in ipairs({'interposer','mourner','warden','hector'}) do
        e=pair('mourner');w=ward(e);w.LODArchetypeId=id
        assert(E:BeginCompanion(e,hero,time) and not e.LODRosterAttack.ward,'excluded ward '..id)
    end
    for _,flag in ipairs({'LODFriendlySummon','LODSummonedSeeker','player'}) do
        e=pair('mourner');w=ward(e);w[flag]=true
        assert(E:BeginCompanion(e,hero,time) and not e.LODRosterAttack.ward,'excluded summoned/player ward '..flag)
    end
    e=pair('interposer');w=ward(e)
    w.GetCollisionBounds=function() return Vector(-80,-80,0),Vector(80,80,72) end
    assert(E:BeginCompanion(e,hero,time) and e.LODRosterAttack.phase=='shot','overlapping true endpoint hull rejected')
end
print('BESTIARY_B17_OWNERSHIP_PASS: cross-mode reservations, stale removal, cap, deterministic selection, excluded wards and real endpoint hull')

-- Fixed aim uses native first collision: a body is cover, never a faction permit.
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
for _,case in ipairs({'ordinary body','world','leave lane','late Hero','blocked escape','unsupported escape'}) do
    e,a=fresh('mourner',false)
    if case=='ordinary body' then w=ward(e);lineFixture(w)
    elseif case=='world' then lineFixture(NULL)
    elseif case=='late Hero' then lineFixture(extraHero(hero:GetPos()))
    elseif case=='leave lane' then lineFixture();hero:SetPos(hero:GetPos()+Vector(0,50,0))
    elseif case=='blocked escape' then lineFixture();util.TraceHull=function(t) return {Hit=t.mask==MASK_PLAYERSOLID,HitPos=t.endpos} end
    else
        lineFixture();local before=util.TraceLine
        util.TraceLine=function(t)
            if t.start.z>t.endpos.z and t.start.x==t.endpos.x and t.start.y==t.endpos.y and math.abs(t.start.y-hero:GetPos().y)>20 then
                return {Hit=false,HitPos=t.endpos}
            end
            return before(t)
        end
    end
    advance(e,a.ready);assert(hero.hits==0,'counterplay '..case)
end
local function mutation(fn)
    e,a=fresh('mourner',false);lineFixture();advance(e,a.ready-.025)
    local hp=hero:Health();local saved=LOD.CombatRolls.QueueDamageReport
    LOD.CombatRolls.QueueDamageReport=function(self,info,callback) fn(e,a,info);return saved(self,info,callback) end
    advance(e,a.ready);LOD.CombatRolls.QueueDamageReport=saved
    assert(hero:Health()==hp,'native callback cannot inherit fixed shot')
end
mutation(function() hero:SetPos(hero:GetPos()+Vector(0,60,0)) end)
mutation(function() lineFixture(NULL) end)
mutation(function() Status:ResetActorLife(hero) end)
mutation(function(e) Status:ResetActorLife(e) end)
mutation(function() hero.LODProgressionState=table.Copy(hero.LODProgressionState) end)
mutation(function() s.Graph=table.Copy(s.Graph) end)
e,a=fresh('mourner',false);lineFixture();advance(e,a.ready-.025)
local oldBlock=Rules.ApplyBlock;local hp=hero:Health()
Rules.ApplyBlock=function(self,p,info) hero:SetPos(hero:GetPos()+Vector(0,60,0));return false end
advance(e,a.ready);Rules.ApplyBlock=oldBlock
assert(hero:Health()==hp,'post-mitigation frozen-lane recheck')
print('BESTIARY_B17_COUNTERPLAY_PASS: first body/world, off-lane/late Hero, actual lateral hull/support, native callback and post-defense lane revalidation')

-- Stop, movement, replication, roll and native settlement are callback boundaries.
do
    e,a,w=fresh('interposer',true);advance(e,a.ready+.025)
    local setter=e.SetPos
    e.SetPos=function(self,pos) setter(self,pos+Vector(0,80,0)) end
    step(e,time+.025);e.SetPos=setter
    assert(not e.LODRosterAttack,'native movement teleport invalidates fixed route')
    e=pair('mourner');w=ward(e);local set=e.SetNW2Int
    e.SetNW2Int=function(self,k,n) set(self,k,n);if k=='LOD_CompanionMode' then Status:ResetActorLife(w) end end
    assert(not E:BeginCompanion(e,hero,time) and not e.LODRosterAttack,'replication ward replacement retires tell')
    e=pair('mourner');w=ward(e);local later={};local trace=util.TraceHull
    util.TraceHull=function(t) e.LODRosterAttack=later;return trace(t) end
    -- Force fallback so its actual escape-hull preflight crosses this boundary.
    w.valid=false;E:BeginCompanion(e,hero,time)
    assert(e.LODRosterAttack==later,'preflight preserves newer attack')
end
local realTake=hero.TakeDamageInfo
do
    e,a=fresh('mourner',false);lineFixture();local calls=0;local packet
    hero.TakeDamageInfo=function(self,info) calls=calls+1;packet=info;E:StepCompanion(e,a,time);realTake(self,info) end
    advance(e,a.ready);hero.TakeDamageInfo=realTake
    assert(calls==1 and packet,'reentry cannot emit second packet')
    local hp=hero:Health();realTake(hero,packet);assert(hero:Health()==hp and packet:GetDamage()==0,'spent packet replay inert')
    e,a=fresh('mourner',false);lineFixture();local later={}
    hero.TakeDamageInfo=function(self,info) e.LODRosterAttack=later;realTake(self,info) end
    advance(e,a.ready);hero.TakeDamageInfo=realTake
    assert(e.LODRosterAttack==later and not e.LODMeleeRecovery,'newer attack survives old settlement')
    e,a=fresh('mourner',false);lineFixture();advance(e,a.ready-.025)
    hero.TakeDamageInfo=function() error('intentional native failure') end
    at(a.ready);local ok=pcall(E.StepCompanion,E,e,a,time);hero.TakeDamageInfo=realTake
    assert(not ok and a.claimed,'failed native callback remains spent')
    local fixed=a.recoveryUntil;at(a.deadline+.01);E:StepCompanion(e,a,time)
    assert(not e.LODRosterAttack and e.LODNextAttack==fixed,'failed native callback retains original recovery deadline')
end
print('BESTIARY_B17_CALLBACK_PASS: motion/replication/preflight replacement, native reentry/replay/error and exact newer-attack preservation')
-- Physical actions retain canonical status distinctions and the captured Hero.
for _,statusId in ipairs({'held','muted'}) do
    e,a=fresh('mourner',false);Status:Apply(e,statusId,hero,{direct=true,duration=4});aimAt(hero);advance(e,a.ready)
    assert(hero.hits==1,'stationary physical shot permits '..statusId)
    e,a,w=fresh('mourner',true);Status:Apply(e,statusId,hero,{direct=true,duration=4});advance(e,a.ready)
    assert(a.phase=='oath','stationary oath permits '..statusId)
end
e,a,w=fresh('interposer',true);Status:Apply(e,'held',hero,{direct=true,duration=4});step(e,time+.025)
assert(not e.LODRosterAttack,'Held cancels bodyguard movement')
e,a,w=fresh('interposer',true);Status:Apply(e,'muted',hero,{direct=true,duration=4});advance(e,a.ready+.8)
assert(a.phase=='guard','Muted permits physical bodyguard movement')
for _,statusId in ipairs({'intimidated','morale_flee'}) do
    e,a,w=fresh('mourner',true)
    if statusId=='morale_flee' then assert(Status:AttemptMorale(hero,e,{forceMorale=true,rng={Int=function(_,lo) return lo end}}))
    else Status:Apply(e,statusId,hero,{direct=true,duration=4}) end
    step(e,time+.025);assert(not e.LODRosterAttack,'attack prohibition cancels '..statusId)
end
e,a,w=fresh('mourner',true);advance(e,a.ready)
local killer=extraHero(center()+Vector(0,110,2));party={hero,killer};e.LODTarget=killer
local receipt=defeat(w);receipt.killer=killer;step(e,time+.025)
assert(a.phase=='shot' and a.target==hero and a.aim:DistToSqr(hero:WorldSpaceCenter())==0,'killer/AI-target change cannot transfer oath warning')
-- Another source can enter during the outer source's hull trace; the final
-- callback-free recount must still enforce sixteen simultaneous commitments.
do
    e=pair('mourner');local retained={}
    for i=1,15 do
        local p=actor('mourner');p:SetPos(e:GetPos());E:Prepare(p);assert(E:BeginCompanion(p,hero,time));retained[#retained+1]=p
    end
    local inner=actor('mourner');inner:SetPos(e:GetPos());E:Prepare(inner)
    local trace=util.TraceHull;local called=false
    util.TraceHull=function(t)
        if not called then called=true;assert(E:BeginCompanion(inner,hero,time),'callback admits sixteenth') end
        return trace(t)
    end
    assert(not E:BeginCompanion(e,hero,time) and not e.LODRosterAttack,'callback cannot admit seventeenth')
end
print('BESTIARY_B17_STATUS_CAP_PASS: Held/Muted/attack prohibition, original-Hero retaliation and callback-safe sixteen-commitment cap')
print('BESTIARY_B17_PASS: production behavior with native boundaries doubled; no native Source acceptance implied')
