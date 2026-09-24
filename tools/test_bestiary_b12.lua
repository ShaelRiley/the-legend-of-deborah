-- B12 exercises condition commitments through the real roster service, combat and status pipeline.
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
dofile(root..'sv_enemy_roster.lua');dofile(root..'sv_enemy_melee.lua');dofile(root..'sv_enemy_conditions.lua');dofile(root..'sv_hostile_motion_v2.lua')
LOD.RPGPerceptionState={IsInvisible=function(_,p) return p.invisible==true end}
local E,D,C,Status,Rules=LOD.EnemyRoster,LOD.EncounterDirector,LOD.CharacterProgressionSystem,LOD.RPGStatusElements,LOD.RPGAbilityRules
local time,serial=200,100
local function at(n) time=n;env.setTime(n) end
at(time)
local s=LOD.RunManager.State
s.BuildReady=true;s.Failed=false;s.LevelCleared=false;s.SimulationFrozen=false;s.Level=8
s.CampaignEpoch=1;s.RunId='b12';s.CampaignSeed=77;s.LevelSeed=123
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
hero.SteamID64=function() return 'b12-tester' end
hero.Nick=function() return 'B12 tester' end
hero.GetNW2Bool=hero.GetNW2Float
LOD.RunManager.IdentityOf=function(_,p) return p==hero and 'b12-tester' or nil end
local priorGetState=LOD.RunManager.GetPlayerState
LOD.RunManager.GetPlayerState=function(self,p)
    if p=='b12-tester' then return {progressionState=hero.LODProgressionState} end
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
    s.GatesOpen={};party={hero};received=0;hero.hits=0;hero.negate=false;hero.invisible=false
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
    local e=pair(id);assert(Status:Apply(hero,'bleeding',e,{direct=true,duration=8}));if setup then setup(e) end
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
    p.SteamID64=function() return 'b12-other-'..p.index end
    return p
end
local function resolve(e,a) advance(e,a.ready+.025) end
local e,a=begin('exactor')
assert(a.condition and a.life and a.statusId=='bleeding','production AI captures a canonical ailment')
local _,entry=Status:Has(hero,'bleeding')
assert(a.statusEntry==entry and math.abs(a.ready-time-1.25)<.000001 and a.deadline==a.ready+.2,'one exact status entry and finite warning')
local mark=Vector(a.aim.x,a.aim.y,a.aim.z)
local sourceHP=e:Health()
advance(e,a.ready-.01)
assert(hero.hits==0 and Status:Has(hero,'bleeding'),'no warning damage or early cleansing')
resolve(e,a)
assert(hero.hits==1 and hero.health<10000 and receivedContext.physical and not receivedContext.magic,'one canonical physical settlement')
assert(not Status:Has(hero,'bleeding') and e:Health()==sourceHP,'positive HP loss consumes exactly one ailment without healing source')
assert(not e.LODRosterAttack and e.LODMeleeRecovery,'release finishes into canonical recovery')
local recovery=e.LODMeleeRecovery.expires
assert(math.abs(recovery-time-3)<.051,'fixed three-second recovery')
E:Interrupt(e);E:Tick(e);assert(e.LODMeleeRecovery.expires==recovery and e.LODMotionSpeed==0,'interrupt cannot extend recovery')
at(recovery+.01);E:Tick(e);assert(not e.LODMeleeRecovery,'recovery ends on original deadline')
for _,id in ipairs({'bleeding','immolated','poisoned'}) do
    e,a=begin('exactor',function(source)
        Status:CureNegative(hero);assert(Status:Apply(hero,id,source,{direct=true,duration=8}))
    end)
    resolve(e,a);assert(hero.hits==1 and not Status:Has(hero,id),'canonical consumable ailment '..id)
end
e,a=begin('exactor',function(source)
    assert(Status:Apply(hero,'poisoned',source,{direct=true,duration=8}))
    assert(Status:Apply(hero,'immolated',source,{direct=true,duration=8}))
end)
assert(a.statusId=='bleeding','deterministic lexical selection')
resolve(e,a)
assert(not Status:Has(hero,'bleeding') and Status:Has(hero,'immolated') and Status:Has(hero,'poisoned'),'only captured ailment is cleared')
for _,case in ipairs({'remedy','natural expiry','clear reapply','refresh'}) do
    e,a=begin('exactor',function(source)
        if case=='natural expiry' then Status:CureNegative(hero);assert(Status:Apply(hero,'bleeding',source,{direct=true,duration=.1})) end
    end);local captured=a.statusEntry
    if case=='remedy' then assert(Status:CureNegative(hero)==1)
    elseif case=='natural expiry' then assert(captured.expiresAt==time+.1)
    elseif case=='clear reapply' then
        Status:Clear(hero,'bleeding','test remedy');assert(Status:Apply(hero,'bleeding',e,{direct=true,duration=8}))
        local _,replacement=Status:Has(hero,'bleeding');assert(replacement~=captured)
    else
        local ok,_,refreshed=Status:Apply(hero,'bleeding',e,{direct=true,duration=15})
        assert(ok and refreshed==captured,'canonical refresh retains exact entry')
    end
    resolve(e,a)
    assert(hero.hits==(case=='refresh' and 1 or 0),'exact entry controls release '..case)
    if case=='clear reapply' then assert(Status:Has(hero,'bleeding'),'old commitment preserves replacement') end
end
print('BESTIARY_B12_EXACTOR_CONDITION_PASS: real production warning/combat/status, all three ailments, deterministic single removal, remedy/expiry/reapplication/refresh and fixed recovery')

for _,case in ipairs({'inside','outside','above','below','other room','other floor'}) do
    e,a=begin('exactor')
    local displacement=({inside=Vector(0,60,0),outside=Vector(0,68,0),above=Vector(0,0,76),below=Vector(0,0,-8),
        ['other room']=Vector(400,0,0),['other floor']=Vector(0,0,384)})[case]
    hero:SetPos(hero:GetPos()+displacement)
    resolve(e,a)
    assert(hero.hits==(case=='inside' and 1 or 0),'frozen mark radius/height '..case)
    assert(a.aim:DistToSqr(mark)==0,'mark never tracks Hero '..case)
end
local other
e,a=begin('exactor',function() other=extraHero();party={hero,other} end)
hero:SetPos(hero:GetPos()+Vector(0,96,0));e.LODTarget=other
resolve(e,a)
assert(hero.hits==0 and other.hits==0,'no retarget and no co-op bystander settlement')
e,a=begin('exactor',function() other=extraHero();party={hero,other} end)
resolve(e,a);assert(hero.hits==1 and other.hits==0,'overlapping co-op Hero remains untouched')
local function lateralHole(t)
    if math.abs(math.abs(t.start.y-center().y)-48)<3 and t.endpos.z<center().z then
        return {Hit=false,HitPos=t.endpos}
    end
    return clearTrace(t)
end
local geometry={
    cover=function() util.TraceLine=coverTrace end,
    support=function() util.TraceLine=function(t) return {Hit=false,HitPos=t.endpos} end end,
    hull=function() util.TraceHull=function() return {Hit=true,StartSolid=true} end end,
    safe=function() s.Graph.CellTags[key(3,3,0)]={safe=true} end,
    objective=function() s.Graph.CellTags[key(3,3,0)]={objective=true} end,
    transition=function() s.Graph.VerticalEdges={{a=s.Graph.Cells[key(3,3,0)],b=s.Graph.Cells[key(4,3,0)]}} end,
    gate=function() s.Graph.Progression.Gates={{beforeCell=s.Graph.Cells[key(3,3,0)],afterCell=s.Graph.Cells[key(4,3,0)]}} end,
    escapeInterior=function() util.TraceLine=lateralHole end,
    escapeFloor=function() util.TraceLine=function(t)
        if math.abs(t.start.y-center().y)>90 then return {Hit=false,HitPos=t.endpos} end
        return clearTrace(t)
    end end,
    escapeHull=function() util.TraceHull=function(t) return {Hit=math.abs(t.endpos.y-center().y)>90,HitPos=t.endpos} end end,
}
for name,mutate in pairs(geometry) do
    e=pair('exactor');assert(Status:Apply(hero,'bleeding',e,{direct=true,duration=8}));mutate()
    assert(not E:BeginCondition(e,hero,time),'unsafe mark admission denied '..name)
    e,a=begin('exactor');mutate();resolve(e,a)
    assert(hero.hits==0 and not e.LODRosterAttack,'geometry invalidation retires mark '..name)
end
e,a=begin('exactor');e.nw.LOD_SizeScale=.33
local escapeHulls=0
util.TraceHull=function(t)
    escapeHulls=escapeHulls+1
    assert(t.mins.x==-16 and t.maxs.x==16 and t.maxs.z==72 and t.mask==MASK_PLAYERSOLID,'small source preserves full Hero escape hull')
    return {Hit=false,HitPos=t.endpos}
end
resolve(e,a);assert(escapeHulls>=2 and hero.hits==1,'full Hero escape hull revalidated at release')
print('BESTIARY_B12_EXACTOR_GEOMETRY_PASS: frozen single-Hero mark, radius/height/room constraints, support/hull/cover, legal room and sampled lateral escape routes')

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
for _,phase in ipairs({'early warning','release'}) do
    for name,mutate in pairs(mutations) do
        e,a=begin('exactor')
        if phase=='release' then advance(e,a.ready-.025) end
        mutate(e);service(time+.05)
        assert(hero.hits==0 and (not e.LODRosterAttack or not IsValid(e) and not E.Active[e]),'retire '..phase..' '..name)
        E:StepCondition(e,a,time);assert(hero.hits==0,'detached callback cannot settle '..name)
        hero.invisible=false
    end
end
for _,id in ipairs({'held','muted','intimidated','morale_flee'}) do
    e,a=begin('exactor')
    if id=='morale_flee' then assert(Status:AttemptMorale(hero,e,{forceMorale=true,rng={Int=function(_,lo) return lo end}}))
    else assert(Status:Apply(e,id,hero,{direct=true,duration=5})) end
    resolve(e,a)
    assert(hero.hits==((id=='held' or id=='muted') and 1 or 0),'canonical physical initiation '..id)
end
e,a=begin('exactor');service(time+.251)
assert(not e.LODRosterAttack and hero.hits==0,'service gap forfeits warning without catchup')
e,a=begin('exactor');service(a.deadline+.001)
assert(not e.LODRosterAttack and hero.hits==0,'missed deadline never catches up')
print('BESTIARY_B12_EXACTOR_LIFETIME_PASS: exact source/Hero/run/graph/progression/campaign lifetimes, interruption/displacement/acquisition, Held/Muted/morale and finite service/deadline')

for _,case in ipairs({'zero','lethal','sourceLife','targetLife','sourceProgression','targetProgression','sourceDeath','sourceRemoval','targetRemoval','graph','replacement','reentrant'}) do
    e,a=begin('exactor');local expected=a.statusEntry;local native=hero.TakeDamageInfo
    local clearExpected=Status.ClearExpected;local cleared=0
    Status.ClearExpected=function(self,...) cleared=cleared+1;return clearExpected(self,...) end
    if case=='zero' then hero.negate=true end
    if case=='lethal' then hero.health=1 end
    hero.TakeDamageInfo=function(self,info)
        if case=='reentrant' then E:StepCondition(e,a,time) end
        native(self,info)
        if mutations[case] then mutations[case](e) end
        if case=='replacement' then
            Status:Clear(self,'bleeding','callback');assert(Status:Apply(self,'bleeding',e,{direct=true,duration=8}))
        end
    end
    resolve(e,a);hero.TakeDamageInfo=native;Status.ClearExpected=clearExpected
    assert(cleared==(case=='reentrant' and 1 or 0),'no invalid consumption callback '..case)
    assert(hero.hits==1,'one native settlement under callback '..case)
    local stored=Status.Active[hero] and Status.Active[hero].bleeding
    if case=='reentrant' then assert(not stored,'one valid callback consumes once')
    elseif case=='replacement' then assert(stored and stored~=expected,'callback replacement is preserved')
    elseif case~='targetLife' and case~='lethal' then assert(stored==expected,'no stale/zero/lethal cure '..case) end
end
e,a=begin('exactor');hero.LODProgressionState.equipmentBlockChanceContribution=.33
local rng=LOD.CombatRolls._RNG;local blocks=0
LOD.CombatRolls._RNG=function(_,channel)
    if channel:find('block:') then blocks=blocks+1;return {Float=function() return 0 end} end
    return rng()
end
resolve(e,a);LOD.CombatRolls._RNG=rng
assert(hero.health==10000 and Status:Has(hero,'bleeding') and blocks==1,'canonical single-roll Block prevents ailment consumption')
local rolls=0;local realRoll=LOD.CombatRolls.RollHostileAttack
LOD.CombatRolls.RollHostileAttack=function(self,...) rolls=rolls+1;return realRoll(self,...) end
e,a=begin('exactor');resolve(e,a);E:StepCondition(e,a,time)
LOD.CombatRolls.RollHostileAttack=realRoll
assert(rolls==1 and hero.hits==1,'one canonical roll and one native damage per mark')
print('BESTIARY_B12_EXACTOR_SETTLEMENT_PASS: positive surviving HP loss only, real single-roll Block, callback replacement and reentrancy, no extra roll/damage/heal')

reset();assert(Status:Apply(hero,'bleeding',hero,{direct=true,duration=8}))
local sources={}
for i=1,17 do
    local source=actor('exactor');source:SetPos(center()+Vector(0,0,2));source.LODTarget=hero;E:Prepare(source);D.Entities[#D.Entities+1]=source
    local ok=E:BeginCondition(source,hero,time)
    assert(ok==(i<=16),'global condition mark cap16 '..i)
    if ok then sources[#sources+1]=source end
end
E:Interrupt(sources[1]);local replacement=actor('exactor');replacement:SetPos(center()+Vector(0,0,2));replacement.LODTarget=hero;E:Prepare(replacement)
assert(E:BeginCondition(replacement,hero,time),'retirement releases condition budget')
e=pair('exactor');E:Tick(e);a=assert(e.LODRosterAttack,'no-ailment production fallback')
assert(not a.condition and a.fallbackLife and a.deadline==a.ready+.2,'fallback warned and incarnation-bound')
advance(e,a.ready-.01);assert(#E.Projectiles==0 and hero.hits==0,'fallback has a real warning')
resolve(e,a);assert(#E.Projectiles==1,'one ordinary physical projectile on fallback release')
local q=E.Projectiles[1];assert(q.expires>time and q.expires<time+10,'finite canonical projectile')
Status:ResetActorLife(hero);service(time+.025);assert(#E.Projectiles==0,'fallback projectile cannot follow replacement Hero life')
e=pair('exactor');E:Tick(e);a=e.LODRosterAttack;service(a.deadline+.001)
assert(#E.Projectiles==0 and not e.LODRosterAttack,'late fallback release forfeits')
print('BESTIARY_B12_EXACTOR_PASS: cached16-mark bound, budget release, canonical finite warned fallback and exact fallback life')
