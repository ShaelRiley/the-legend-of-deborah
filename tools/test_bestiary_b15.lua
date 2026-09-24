-- B15 exercises condition commitments through the real roster service, combat and status pipeline.
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
dofile(root..'sv_enemy_roster.lua');dofile(root..'sv_enemy_melee.lua');dofile(root..'sv_enemy_conditions.lua');dofile(root..'sv_enemy_perception.lua');dofile(root..'sv_enemy_spacing.lua');dofile(root..'sv_enemy_crossfire.lua');dofile(root..'sv_hostile_motion_v2.lua')
LOD.RPGPerceptionState={IsInvisible=function(_,p) return p.invisible==true end}
local E,D,C,Status,Rules=LOD.EnemyRoster,LOD.EncounterDirector,LOD.CharacterProgressionSystem,LOD.RPGStatusElements,LOD.RPGAbilityRules
local time,serial=200,100
local function at(n) time=n;env.setTime(n) end
at(time)
local s=LOD.RunManager.State
s.BuildReady=true;s.Failed=false;s.LevelCleared=false;s.SimulationFrozen=false;s.Level=8
s.CampaignEpoch=1;s.RunId='b15';s.CampaignSeed=77;s.LevelSeed=123
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
local intercepted,shotTraces,escapeTraces
local beforeReset=reset
reset=function()
    beforeReset();intercepted=hero;shotTraces=0;escapeTraces=0
    util.TraceHull=function(t)
        if t.mask==MASK_SHOT then
            shotTraces=shotTraces+1
            assert(t.mins.x==-4 and t.maxs.z==4 and t.filter.LODArchetypeId=='fusilier','actual fixed shot hull')
            return {Hit=true,HitPos=t.endpos,Entity=intercepted}
        end
        escapeTraces=escapeTraces+1;return {Hit=false,HitPos=t.endpos}
    end
end
local function ally(e,id,pos)
    local p=actor(id or 'runner');p:SetPos(pos or center()+Vector(55,0,2));p.hits=0
    p.health=10000;p.maximum=10000;p.GetNW2Bool=p.GetNW2Float
    function p:TakeDamageInfo(info)
        if factionHook(self,info) then return end
        self.hits=self.hits+1;self.lastInfo=info;self.lastContext=Status:DamageContext(info,self)
        GM:EntityTakeDamage(self,info);self.health=math.max(0,self.health-info:GetDamage())
        GM:PostEntityTakeDamage(self,info,true)
    end
    D.Entities[#D.Entities+1]=p
    return p
end
local function fresh(id,setup)
    local e=pair(id);local p=setup and setup(e)
    E:Tick(e);return e,assert(e.LODRosterAttack,'real Tick commits '..id),p
end
local function resolve(e,a) advance(e,a.ready) end
local e,a,p=fresh('fusilier',function(e) local p=ally(e);intercepted=p;return p end)
assert(a.crossfire==1 and a.ready==time+1.25 and a.deadline==a.ready+.2)
advance(e,a.ready-.025);assert(p.hits==0 and hero.hits==0,'warning harmless')
resolve(e,a)
assert(p.hits==1 and hero.hits==0 and shotTraces==1,'first native companion intercepts lane')
assert(p.lastInfo:GetAttacker()==e and p.lastContext.physical and not p.lastContext.magic,'enemy credit, canonical physical context')
assert(p.health<10000 and p.lastContext.actorDamageResolved,'ordinary mitigation path')
assert(factionHook(p,p.lastInfo)==true,'consumed released packet cannot bypass faction twice')
E:StepCrossfire(e,a,time);assert(p.hits==1,'released attack cannot repeat')
local expires=e.LODMeleeRecovery.expires;E:Interrupt(e);E:Tick(e)
assert(e.LODMeleeRecovery.expires==expires,'recovery never extends')
local ordinary=DamageInfo();ordinary:SetAttacker(e);ordinary:SetInflictor(e);ordinary:SetDamage(20)
assert(factionHook(p,ordinary)==true and ordinary:GetDamage()==0,'ordinary allied fire still blocked')
local before=p.hits;E:Damage(e,p,{},'bullet');assert(p.hits==before,'ordinary roster Target gate unchanged')
for _,kind in ipairs({'neil','brute','warden','hector','clone','skeleton','summon','human','replacement','uncaptured','world'}) do
    e,a,p=fresh('fusilier',function(source)
        local other=ally(source);intercepted=other
        if kind=='clone' then other.LODWardenClone=true
        elseif kind=='skeleton' then other.LODSkeletonHero=true
        elseif kind=='summon' then other.LODSummonedSeeker=true
        elseif kind=='human' then other.player=true;other.LODHostile=true;other.alive=true
        elseif kind=='neil' or kind=='brute' or kind=='warden' or kind=='hector' then other.LODArchetypeId=kind end
        return other
    end)
    if kind=='replacement' then Status:ResetActorLife(p)
    elseif kind=='uncaptured' then intercepted=ally(e)
    elseif kind=='world' then intercepted=NULL end
    resolve(e,a)
    assert(hero.hits==0 and p.hits==0,'harmless first blocker '..kind)
end
print('BESTIARY_B15_LINE_PASS: production Tick/service, native first-body interception, excluded/replaced blockers, physical mitigation, packet-only faction exception, single release/recovery')

e,a,p=fresh('bombardier',function(source) return ally(source) end)
assert(a.crossfire==2 and a.ready==time+1.6)
resolve(e,a)
assert(p.hits==1 and hero.hits==1 and shotTraces==0,'blast hits all captured actors, no ally cover')
assert(p.lastContext.damageContract.attackEvent==receivedContext.damageContract.attackEvent,'one shared damage roll')
e,a,p=fresh('bombardier',function(source) return ally(source) end)
hero:SetPos(hero:GetPos()+Vector(0,96,0));resolve(e,a)
assert(hero.hits==0 and p.hits==1,'primary escape baits frozen blast')
e,a=fresh('bombardier');local late=ally(e);resolve(e,a)
assert(hero.hits==1 and late.hits==0,'late arrivals uncaptured')
e,a,p=fresh('bombardier',function(source) return ally(source) end)
local seen=0;local coverBase=util.TraceLine
util.TraceLine=function(t)
    if t.start:DistToSqr(a.aim+Vector(0,0,24))<.01 and t.endpos:DistToSqr(p:WorldSpaceCenter())<.01 then
        seen=seen+1;return {Hit=true,HitPos=t.endpos,Entity=NULL}
    end
    return coverBase(t)
end
resolve(e,a);assert(seen==1 and p.hits==0 and hero.hits==1,'individual world cover')
e,a,p=fresh('bombardier',function(source) return ally(source) end)
coverBase=util.TraceLine
util.TraceLine=function(t)
    if t.start:DistToSqr(a.origin+Vector(0,0,48))<.01 and t.endpos:DistToSqr(a.aim+Vector(0,0,24))<.01 then
        return {Hit=true,HitPos=t.endpos,Entity=NULL}
    end
    return coverBase(t)
end
resolve(e,a);assert(hero.hits==0 and p.hits==0,'source-to-fixed mark world cover')
-- Hero death on first area hit cannot cancel an already admitted companion.
e,a,p=fresh('bombardier',function(source) return ally(source) end)
hero.health=.01;resolve(e,a)
assert(hero.health==0 and p.hits==1,'area admission survives primary death')
print('BESTIARY_B15_BLAST_PASS: shared roll and simultaneous admission, bait, no body cover, target/source cover, late arrivals, primary death')

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

for _,id in ipairs({'fusilier','bombardier'}) do
 for _,phase in ipairs({'early','deadline'}) do
  for name,mutate in pairs(mutations) do
    e,a=fresh(id)
    if phase=='deadline' then advance(e,a.ready-.025) end
    mutate(e);service(time+.05);E:StepCrossfire(e,a,time)
    assert(hero.hits==0,'lifecycle '..id..' '..phase..' '..name)
  end
 end
 for _,condition in ipairs({'held','muted','intimidated','morale_flee'}) do
    e,a=fresh(id)
    if condition=='morale_flee' then assert(Status:AttemptMorale(hero,e,{forceMorale=true,rng={Int=function(_,lo) return lo end}}))
    else assert(Status:Apply(e,condition,hero,{direct=true,duration=5})) end
    resolve(e,a)
    assert(hero.hits==((condition=='held' or condition=='muted') and 1 or 0),'physical status policy '..condition)
 end
 e,a=fresh(id);service(time+.251);assert(not e.LODRosterAttack and hero.hits==0,'service gap')
 e,a=fresh(id);service(a.deadline+.001);assert(not e.LODRosterAttack and hero.hits==0,'late expiry')
 for _,what in ipairs({'cover','support','hull','safe','objective','gate','transition'}) do
    e=pair(id)
    if what=='cover' then util.TraceLine=coverTrace
    elseif what=='support' then util.TraceLine=function(t) return {Hit=false,HitPos=t.endpos} end
    elseif what=='hull' then util.TraceHull=function() return {Hit=true,StartSolid=true} end
    elseif what=='safe' then s.Graph.CellTags[key(3,3,0)]={safe=true}
    elseif what=='objective' then s.Graph.CellTags[key(3,3,0)]={objective=true}
    elseif what=='gate' then s.Graph.Progression.Gates={{beforeCell=s.Graph.Cells[key(3,3,0)],afterCell=s.Graph.Cells[key(4,3,0)]}}
    else s.Graph.VerticalEdges={{a=s.Graph.Cells[key(3,3,0)],b=s.Graph.Cells[key(4,3,0)]}} end
    assert(not E:BeginCrossfire(e,hero,time),'illegal geometry '..id..what)
 end
 e,a=fresh(id);local trace=util.TraceHull
 util.TraceHull=function(t)
    if t.mask==MASK_PLAYERSOLID then
        assert(t.mins.x==-16 and t.maxs.z==72,'actual Hero hull');return {Hit=true}
    end
    return trace(t)
 end
 resolve(e,a);assert(hero.hits==0,'lost escape cancels')
 e=pair(id);party={};for i=1,33 do party[i]=hero end
 assert(not E:BeginCrossfire(e,hero,time),'Hero cap fail closed')
 e=pair(id);for i=1,129 do D.Entities[i]=e end
 assert(not E:BeginCrossfire(e,hero,time),'hostile cap fail closed')
 e=pair(id)
 local held={}
 for i=1,16 do local source=actor(id);held[i]=source;E.Active[source]=true;source.LODRosterAttack={crossfire=1} end
 assert(not E:BeginCrossfire(e,hero,time),'global cap16')
end
-- Diagonal AABB projection must not miss an endangered bystander.
e=pair('fusilier');hero:SetPos(center()+Vector(90,90,0))
local diagonal=extraHero(center()+Vector(45-24/math.sqrt(2),45+24/math.sqrt(2),0));party[2]=diagonal
E:Tick(e);a=assert(e.LODRosterAttack);assert(#a.endangered==2,'diagonal actual hull projection captures side Hero')
local oldBounds=diagonal.GetCollisionBounds
diagonal.GetCollisionBounds=function() return Vector(-28,-28,0),Vector(28,28,96) end
local nativeTrace=util.TraceHull;local largeHull=false
util.TraceHull=function(t)
    if t.mask==MASK_PLAYERSOLID and t.maxs.z==96 then largeHull=true;return {Hit=true} end
    return nativeTrace(t)
end
resolve(e,a);diagonal.GetCollisionBounds=oldBounds
assert(largeHull and hero.hits==0,'current Hero hull rechecked after size change')
print('BESTIARY_B15_LIFETIME_PASS: early/deadline identity matrix, physical Held/Muted policy, stall/expiry, safe/objective/gates/transitions, native/current/diagonal hull, roster and commitment caps')

local nativeDamage=hero.TakeDamageInfo
for _,id in ipairs({'fusilier','bombardier'}) do
 e,a=fresh(id)
 hero.TakeDamageInfo=function(self,info) E:StepCrossfire(e,a,time);nativeDamage(self,info) end
 resolve(e,a);hero.TakeDamageInfo=nativeDamage
 assert(hero.hits==1,'native reentry once')
 e,a=fresh(id);advance(e,a.ready-.025)
 hero.TakeDamageInfo=function() error('injected native failure') end
 local ok=pcall(function() resolve(e,a) end);hero.TakeDamageInfo=nativeDamage
 assert(not ok and a.settling,'claimed before native failure')
 service(a.deadline+.001);assert(not e.LODRosterAttack and hero.hits==0,'failed callback retires')
 assert(e.LODNextAttack==a.recoveryUntil,'callback delay cannot extend fixed recovery')
 for _,boundary in ipairs({'roll','resolve','defense','native'}) do
  for _,kind in ipairs({'source','target','attack'}) do
    e,a=fresh(id);local replacement={};local calls=0
    local function change()
        calls=calls+1
        if kind=='source' then Status:ResetActorLife(e)
        elseif kind=='target' then Status:ResetActorLife(hero)
        else e.LODRosterAttack=replacement end
    end
    local owner=boundary=='defense' and Rules or LOD.CombatRolls
    local name=boundary=='roll' and 'RollHostileAttack' or boundary=='resolve' and 'ResolveActorDamage' or 'ApplyPlayerDefense'
    local old=owner[name]
    if boundary=='native' then hero.TakeDamageInfo=function(self,info) change();nativeDamage(self,info) end
    else owner[name]=function(self,...) local out=old(self,...);change();return out end end
    local hp=hero.health;resolve(e,a)
    hero.TakeDamageInfo=nativeDamage;owner[name]=old
    assert(calls==1 and hero.health==hp,'callback replacement cancels HP '..id..boundary..kind)
    if kind=='attack' then assert(e.LODRosterAttack==replacement,'preserve replacement attack') end
  end
 end
end
-- Source replacement during first native area callback suppresses later bodies;
-- recipient replacement changes only that recipient, without reopening admission.
e,a,p=fresh('bombardier',function(source) return ally(source) end)
hero.TakeDamageInfo=function(self,info) nativeDamage(self,info);Status:ResetActorLife(e) end
resolve(e,a);hero.TakeDamageInfo=nativeDamage
assert(hero.hits==1 and p.hits==0,'source incarnation replacement stops pending area targets')
e,a,p=fresh('bombardier',function(source) return ally(source) end)
hero.TakeDamageInfo=function(self,info) nativeDamage(self,info);Status:ResetActorLife(p) end
resolve(e,a);hero.TakeDamageInfo=nativeDamage
assert(hero.hits==1 and p.hits==0,'recipient incarnation replacement cannot inherit area hit')
print('BESTIARY_B15_CALLBACK_PASS: real roll/resolve/GM mitigation/native callback identity gates, reentry, failure retirement, fixed recovery and preserving newer attacks')
-- Exact native packet recipient and source are sealed, independently of faction.
for _,change in ipairs({'recipient','attacker','inflictor'}) do
    e,a=fresh('fusilier');local other=extraHero(hero:GetPos());local before=hero.health
    hero.TakeDamageInfo=function(self,info)
        if change=='recipient' then
            local hp=other.health;other:TakeDamageInfo(info)
            assert(other.health==hp,'wrong Hero cannot receive the live packet')
        else
            if change=='attacker' then info:SetAttacker(other) else info:SetInflictor(other) end
            nativeDamage(self,info)
        end
    end
    resolve(e,a);hero.TakeDamageInfo=nativeDamage
    assert(hero.health==before,'mutated native packet cannot damage original recipient '..change)
end
for _,recipient in ipairs({'hero','ally'}) do
    e,a,p=fresh('fusilier',recipient=='ally' and function(source)
        local other=ally(source);intercepted=other;return other
    end or nil)
    local victim=recipient=='ally' and p or hero;local hp=victim.health
    local defense=Rules.ApplyPlayerDefense;local enters=0
    Rules.ApplyPlayerDefense=function(self,target,info)
        enters=enters+1
        if enters==1 then target:TakeDamageInfo(info) end
        return defense(self,target,info)
    end
    resolve(e,a);Rules.ApplyPlayerDefense=defense
    assert(enters==1 and victim.health==hp,'same native packet reentry denied '..recipient)
end
print('BESTIARY_B15_PACKET_IDENTITY_PASS: wrong recipient/attacker/inflictor and same-info Hero/ally GM reentry denied')

-- Actual hostile defeat/XP/deferred loot; final native entities and reward
-- spawning remain doubles, with no invented Hero attacker or killing blow.
local timers={};timer.Exists=function(id) return timers[id]~=nil end
timer.Create=function(id,delay,reps,fn) timers[id]=fn end
timer.Adjust=noop;timer.Remove=function(id) timers[id]=nil end
AddCSLuaFile=noop;include=noop;concommand={Add=noop};vector_origin=Vector()
COLLISION_GROUP_DEBRIS,SOLID_NONE,MOVETYPE_NONE=1,2,3
ENT={};dofile('gamemodes/legend_of_deborah/entities/entities/lod_hostile/init.lua')
local Native=ENT;local deaths=LOD.HostileDeathPresentation
local attribution,Loot=LOD.CombatAttributionSystem,LOD.LootDirector
local lootState,spawned,xp,killed={},0,0,0
Loot.TraceStage=noop;Loot._ObjectiveClearDrop=function() return false end
Loot._PlayerLootState=function() return lootState end
Loot._DropCategory=function() return 'ammo',false end
Loot._SpawnEnemyResult=function() spawned=spawned+1;return true end
C.AwardHeroXP=function(_,identity,amount) xp=xp+amount;return true end
hook.Run=function(event,source,attacker)
    if event=='OnNPCKilled' then
        killed=killed+1;assert(attacker==e,'native death retains actual enemy attacker')
        attribution:Settle(source)
    end
end
for _,contributed in ipairs({false,true}) do
    e,a,p=fresh('fusilier',function(source)
        local other=ally(source);intercepted=other
        other.OnKilled=Native.OnKilled;other._BeginDeathPresentation=Native._BeginDeathPresentation
        other._FinishDeathPresentation=Native._FinishDeathPresentation;other._SpawnPlaceholderLoot=Native._SpawnPlaceholderLoot
        other.SetNoDraw=noop;other.SetVelocity=noop;other.SetCollisionGroup=noop;other.SetSolid=noop;other.SetMoveType=noop;other.DrawShadow=noop
        local apply=other.TakeDamageInfo
        other.TakeDamageInfo=function(self,info)
            apply(self,info)
            if self.health<=0 then self:OnKilled(info);self:OnKilled(info) end
        end
        other.health=.01;return other
    end)
    deaths.Active={};deaths.Pending={};spawned=0;xp=0;killed=0;lootState={}
    if contributed then attribution.Ledgers[p]={effectiveDamageByHeroId={['b15-tester']=100},totalEligibleEffectiveDamage=100}
    else attribution.Ledgers[p]=nil end
    resolve(e,a);assert(p.LODDead and killed==1,'ordinary native kill exactly once')
    local ledger=attribution.Ledgers[p]
    assert(not ledger or not ledger.killingBlowHeroId,'crossfire cannot fabricate Hero killing blow')
    if contributed then assert(xp>0 and xp<p.LODRPGXPSettlement.value,'only preexisting contribution pool')
    else assert(xp==0,'no Hero contribution means no Hero XP') end
    local earned=xp
    at(time+.002);deaths:_RunDue();at(time+1.002);deaths:_RunDue()
    Loot:OnHostileLootHandoff(p);attribution:Settle(p)
    assert(spawned==1 and xp==earned and killed==1,'one canonical loot handoff and XP settlement')
end
print('BESTIARY_B15_REWARD_PASS: actual native death, enemy attribution, no synthetic Hero killing blow, existing contribution pool only, one canonical loot handoff and XP settlement')
