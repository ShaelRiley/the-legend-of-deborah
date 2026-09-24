-- B13 exercises condition commitments through the real roster service, combat and status pipeline.
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
dofile(root..'sv_enemy_roster.lua');dofile(root..'sv_enemy_melee.lua');dofile(root..'sv_enemy_conditions.lua');dofile(root..'sv_enemy_perception.lua');dofile(root..'sv_enemy_spacing.lua');dofile(root..'sv_hostile_motion_v2.lua')
LOD.RPGPerceptionState={IsInvisible=function(_,p) return p.invisible==true end}
local E,D,C,Status,Rules=LOD.EnemyRoster,LOD.EncounterDirector,LOD.CharacterProgressionSystem,LOD.RPGStatusElements,LOD.RPGAbilityRules
local time,serial=200,100
local function at(n) time=n;env.setTime(n) end
at(time)
local s=LOD.RunManager.State
s.BuildReady=true;s.Failed=false;s.LevelCleared=false;s.SimulationFrozen=false;s.Level=8
s.CampaignEpoch=1;s.RunId='b13';s.CampaignSeed=77;s.LevelSeed=123
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
hero.SteamID64=function() return 'b13-tester' end
hero.Nick=function() return 'B13 tester' end
hero.GetNW2Bool=hero.GetNW2Float
LOD.RunManager.IdentityOf=function(_,p) return p==hero and 'b13-tester' or nil end
local priorGetState=LOD.RunManager.GetPlayerState
LOD.RunManager.GetPlayerState=function(self,p)
    if p=='b13-tester' then return {progressionState=hero.LODProgressionState} end
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
    p.SteamID64=function() return 'b13-other-'..p.index end
    return p
end
local function resolve(e,a) advance(e,a.ready+.025) end
local function addPartner(offset)
    local p=extraHero(center()+Vector(90,offset or 40,0));party[#party+1]=p;return p
end
local function linked(setup)
    local other
    local e,a=begin('conductor',function(source) other=addPartner();if setup then setup(source,other) end end)
    return e,a,other
end
local e,a=begin('outrider')
assert(a.spacing=='isolation' and a.melee=='single' and #a.participants==1,'Outrider shares B7 narrow exact Hero strike')
assert(a.ready==time+1.1 and a.deadline==a.ready+.2,'full warning/deadline')
advance(e,a.ready-.01);assert(hero.hits==0,'no early physical damage')
resolve(e,a);assert(hero.hits==1 and receivedContext.physical and not receivedContext.magic,'canonical physical hit')
assert(e.LODMeleeRecovery and math.abs(e.LODMeleeRecovery.expires-time-2.4)<.051,'finite Outrider recovery')
local expiry=e.LODMeleeRecovery.expires;E:Interrupt(e);E:Tick(e);assert(e.LODMeleeRecovery.expires==expiry,'repeated hits do not extend recovery')
for _,move in ipairs({Vector(0,96,0),Vector(180,0,0),Vector(0,0,90)}) do
    e,a=begin('outrider');hero:SetPos(hero:GetPos()+move);resolve(e,a);assert(hero.hits==0,'solo has frozen narrow escape')
end
for _,count in ipairs({1,2,3,4}) do
    e=pair('outrider');for i=2,count do addPartner(i*10) end
    assert(E:BeginSpacing(e,hero,time)==(count==1),'party regroup denies isolation '..count)
end
local other
e,a=begin('outrider');other=addPartner();LOD.FactionManager.NextPerceptionHeroes=0
resolve(e,a);assert(hero.hits==0 and other.hits==0 and not e.LODRosterAttack,'regroup cancels warning')
for _,case in ipairs({'far','floor','cloaked','dead','wall'}) do
    e=pair('outrider');other=addPartner()
    if case=='far' then other:SetPos(center()+Vector(300,0,0))
    elseif case=='floor' then other:SetPos(other:GetPos()+Vector(0,0,384))
    elseif case=='cloaked' then other.invisible=true
    elseif case=='dead' then other.health=0
    else
        util.TraceLine=function(t)
            if t.start==hero:WorldSpaceCenter() then return {Hit=true,HitPos=t.endpos,Entity=NULL} end
            if t.start.x==hero:WorldSpaceCenter().x and t.start.y==hero:WorldSpaceCenter().y and t.endpos.y==other:WorldSpaceCenter().y and t.start.z==hero:WorldSpaceCenter().z then return {Hit=true,HitPos=t.endpos,Entity=NULL} end
            return clearTrace(t)
        end
    end
    assert(E:BeginSpacing(e,hero,time),'ineligible proximity cannot protect '..case)
end
print('BESTIARY_B13_ISOLATION_PASS: B7 canonical physical attack, solo escape, party1–4 regroup, no walls/floors/dead/cloaked false cooperation, finite recovery')

e,a,other=linked()
assert(a.other==other and a.otherLife and a.life and a.ready==time+1.4,'Conductor captures exact paired lives and full warning')
local rolls=0;local realRoll=LOD.CombatRolls.RollHostileAttack
LOD.CombatRolls.RollHostileAttack=function(self,...) rolls=rolls+1;return realRoll(self,...) end
advance(e,a.ready-.01);assert(hero.hits==0 and other.hits==0,'pair warning harmless')
resolve(e,a);LOD.CombatRolls.RollHostileAttack=realRoll
assert(hero.hits==1 and other.hits==1 and rolls==1 and receivedContext.magic and receivedContext.element=='raw','pair canonical shared Raw Magic roll')
assert(e.LODMeleeRecovery and math.abs(e.LODMeleeRecovery.expires-time-3.5)<.051,'fixed Conductor recovery')
for _,case in ipairs({'primary exits','secondary exits','separate','pair cover','secondary hidden','secondary dead','secondary life','secondary progression','secondary removal','secondary floor','primary retarget'}) do
    e,a,other=linked()
    if case=='primary exits' then hero:SetPos(hero:GetPos()+Vector(70,0,0))
    elseif case=='secondary exits' then other:SetPos(other:GetPos()+Vector(70,0,0))
    elseif case=='separate' then hero:SetPos(hero:GetPos()+Vector(0,-62,0));other:SetPos(other:GetPos()+Vector(0,62,0))
    elseif case=='pair cover' then util.TraceLine=function(t)
        if t.start.x==hero:WorldSpaceCenter().x and t.start.y==hero:WorldSpaceCenter().y and t.endpos.y==other:WorldSpaceCenter().y and t.start.z==hero:WorldSpaceCenter().z then return {Hit=true,HitPos=t.endpos,Entity=NULL} end
        return clearTrace(t)
    end
    elseif case=='secondary hidden' then other.invisible=true
    elseif case=='secondary dead' then other.health=0
    elseif case=='secondary life' then Status:ResetActorLife(other)
    elseif case=='secondary progression' then other.LODProgressionState=table.Copy(other.LODProgressionState)
    elseif case=='secondary removal' then other.valid=false
    elseif case=='secondary floor' then other:SetPos(other:GetPos()+Vector(0,0,384))
    else e.LODTarget=addPartner(20);hero:SetPos(hero:GetPos()+Vector(70,0,0)) end
    resolve(e,a);assert(hero.hits==0 and other.hits==0,'either end cancels link '..case)
end
for _,count in ipairs({2,3,4}) do
    local candidates={}
    e,a=begin('conductor',function() for i=2,count do candidates[#candidates+1]=addPartner(40) end end)
    assert(a.other==candidates[1],'nearest distance/ID stable selection '..count)
    resolve(e,a);assert(hero.hits==1 and candidates[1].hits==1,'selected pair only '..count)
    for i=2,#candidates do assert(candidates[i].hits==0,'unselected Hero untouched') end
end
print('BESTIARY_B13_LINK_PASS: frozen pair, Raw shared roll, pair1–4 deterministic selection, separating/exiting/LOS/acquisition/lives and no bystanders')

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
for _,id in ipairs({'outrider','conductor'}) do
 for _,phase in ipairs({'early','deadline'}) do
  for name,mutate in pairs(mutations) do
    if id=='outrider' then e,a=begin(id) else e,a,other=linked() end
    if phase=='deadline' then advance(e,a.ready-.025) end
    mutate(e);service(time+.05)
    assert(hero.hits==0,'exact life cancel '..id..' '..phase..' '..name)
    E:StepSpacing(e,a,time);assert(hero.hits==0,'detached callback inert '..name)
  end
 end
 for _,condition in ipairs({'held','muted','intimidated','morale_flee'}) do
    if id=='outrider' then e,a=begin(id) else e,a,other=linked() end
    if condition=='morale_flee' then assert(Status:AttemptMorale(hero,e,{forceMorale=true,rng={Int=function(_,lo) return lo end}}))
    else assert(Status:Apply(e,condition,hero,{direct=true,duration=5})) end
    resolve(e,a)
    assert(hero.hits==((condition=='held' or condition=='muted' and id=='outrider') and 1 or 0),'status law '..id..' '..condition)
 end
 if id=='outrider' then e,a=begin(id) else e,a=linked() end
 service(time+.251);assert(not e.LODRosterAttack and hero.hits==0,'stalled service cancels '..id)
 if id=='outrider' then e,a=begin(id) else e,a=linked() end
 service(a.deadline+.001);assert(not e.LODRosterAttack and hero.hits==0,'late deadline cancels '..id)
end
print('BESTIARY_B13_LIFETIME_PASS: source/Hero/run/graph/progression/campaign matrix before/deadline, Held/Muted/morale/hitstun, service gaps and finite deadlines')

local geometry={
 cover=function() util.TraceLine=coverTrace end,
 support=function() util.TraceLine=function(t) return {Hit=false,HitPos=t.endpos} end end,
 hull=function() util.TraceHull=function() return {Hit=true,StartSolid=true} end end,
 safe=function() s.Graph.CellTags[key(3,3,0)]={safe=true} end,
 objective=function() s.Graph.CellTags[key(3,3,0)]={objective=true} end,
 transition=function() s.Graph.VerticalEdges={{a=s.Graph.Cells[key(3,3,0)],b=s.Graph.Cells[key(4,3,0)]}} end,
 gate=function() s.Graph.Progression.Gates={{beforeCell=s.Graph.Cells[key(3,3,0)],afterCell=s.Graph.Cells[key(4,3,0)]}} end,
 escapeHole=function() util.TraceLine=function(t)
    if math.abs(t.start.y-center().y)>70 and t.endpos.z<center().z then return {Hit=false,HitPos=t.endpos} end
    return clearTrace(t)
 end end,
}
for _,id in ipairs({'outrider','conductor'}) do
 for name,mutate in pairs(geometry) do
    e=pair(id);if id=='conductor' then addPartner() end;mutate()
    assert(not E:BeginSpacing(e,hero,time),'geometry denies '..id..' '..name)
    if id=='outrider' then e,a=begin(id) else e,a=linked() end
    mutate();resolve(e,a);assert(hero.hits==0,'geometry retires '..id..' '..name)
 end
end
e,a,other=linked();e.nw.LOD_SizeScale=.33;local hulls=0
util.TraceHull=function(t)
    if t.mask==MASK_PLAYERSOLID then hulls=hulls+1;assert(t.mins.x==-16 and t.maxs.x==16 and t.maxs.z==72,'actual Hero collision hull') end
    return {Hit=false,HitPos=t.endpos}
end
resolve(e,a);assert(hulls>=4,'both endpoints lateral escape checked at release')
print('BESTIARY_B13_GEOMETRY_PASS: support/cover/hulls, safe/objective/transition/gate exclusions and both Heroes actual hulls and supported lateral escape')

for _,case in ipairs({'first lethal','second life','source life','source removal','graph','reentrant'}) do
    e,a,other=linked();local native=hero.TakeDamageInfo
    if case=='first lethal' then hero.health=1 end
    hero.TakeDamageInfo=function(self,info)
        if case=='reentrant' then E:StepSpacing(e,a,time) end
        native(self,info)
        if case=='second life' then Status:ResetActorLife(other)
        elseif case=='source life' then Status:ResetActorLife(e)
        elseif case=='source removal' then e.valid=false
        elseif case=='graph' then s.Graph=table.Copy(s.Graph) end
    end
    resolve(e,a);hero.TakeDamageInfo=native
    assert(hero.hits==1,'one first native call '..case)
    assert(other.hits==((case=='first lethal' or case=='reentrant') and 1 or 0),'preadmitted pair with exact callback guard '..case)
    if case=='source life' then service(time+.025);assert(not e.LODRosterAttack,'replaced source cannot retain spent commitment') end
end
print('BESTIARY_B13_CALLBACK_PASS: death does not create order dependence, source/second-life/dungeon replacement stops stale settlement, reentrancy cannot repeat')

reset();for i=1,33 do party[i]=extraHero(center()+Vector(400,0,0)) end;party[1]=hero
for _,id in ipairs({'outrider','conductor'}) do
    local source=actor(id);source:SetPos(center()+Vector(0,0,2));E:Prepare(source)
    assert(not E:BeginSpacing(source,hero,time),'cached overflow fails closed '..id)
end
reset();local sources={}
for i=1,17 do
    local source=actor('outrider');source:SetPos(center()+Vector(0,0,2));E:Prepare(source)
    assert(E:BeginSpacing(source,hero,time)==(i<=16),'global spacing cap16 '..i);sources[#sources+1]=source
end
E:Interrupt(sources[1]);assert(E:BeginSpacing(sources[17],hero,time+.51),'retirement frees spacing slot')
e=pair('conductor');E:Tick(e);a=assert(e.LODRosterAttack)
assert(a.spacingFallback and a.fallbackLife and a.deadline==a.ready+.2 and not a.spacing,'solo warned ordinary Raw bolt')
advance(e,a.ready-.01);assert(#E.Projectiles==0 and hero.hits==0,'solo full fallback warning')
resolve(e,a);assert(#E.Projectiles==1,'one ordinary Raw projectile')
local q=E.Projectiles[1];assert(q.kind=='bolt' and q.fallbackLife,'released fallback exact life')
E:Interrupt(e);assert(#E.Projectiles==1,'ordinary interruption preserves released shot')
Status:ResetActorLife(hero);service(time+.025);assert(#E.Projectiles==0,'released fallback retires Hero replacement')
e=pair('conductor');E:Tick(e);a=e.LODRosterAttack;service(time+.251)
assert(#E.Projectiles==0 and not e.LODRosterAttack,'solo stalled warning forfeits')
e=pair('conductor');E:Tick(e);a=e.LODRosterAttack;service(a.deadline+.001)
assert(#E.Projectiles==0 and not e.LODRosterAttack,'solo late release forfeits')
print('BESTIARY_B13_BOUNDS_PASS: cached32 fail closed, cap16/release, solo full warned finite exact-life Raw projectile and no service/deadline catchup')
-- Native audio callbacks may synchronously service or replace a commitment.
for _,id in ipairs({'outrider','conductor'}) do
 e=pair(id);local emits=0;local activity=0;local replacement={sentinel=true}
 local original=e._SetActivity;e._SetActivity=function(self,...) activity=activity+1;return original(self,...) end
 e.EmitSound=function() emits=emits+1;e.LODRosterAttack=replacement end
 E:BeginSpacing(e,hero,time)
 assert(e.LODRosterAttack==replacement and activity==0,'warning callback preserves replacement '..id)
end
e=pair('conductor');local warningReentry=0
local ordinarySound=e.EmitSound
e.EmitSound=function(self,...)
 warningReentry=warningReentry+1;E:Attack(e,e.LODRosterAttack,time);return ordinarySound(self,...)
end
E:BeginSpacing(e,hero,time);a=e.LODRosterAttack
assert(warningReentry==1 and a and a.sourceGround and a.cell,'fallback entirely initialized before native warning callback')
e.EmitSound=ordinarySound
advance(e,a.ready-.025)
local replacement={sentinel=true};e.EmitSound=function() e.LODRosterAttack=replacement end
-- Direct release/service avoids deliberately invalid sentinel entering next Tick.
at(a.ready);E:Attack(e,a,time)
assert(e.LODRosterAttack==replacement and #E.Projectiles==0,'release callback cannot emit stale shot or finish replacement')
e=pair('conductor');E:Tick(e);a=e.LODRosterAttack;resolve(e,a)
util.TraceHull=function(t) return {Hit=true,HitPos=hero:WorldSpaceCenter(),Entity=hero} end
service(time+.025)
assert(hero.hits==1 and receivedContext.magic and receivedContext.element=='raw','solo projectile uses real Raw Magic damage')
e=pair('conductor');E:Tick(e);a=e.LODRosterAttack;resolve(e,a);other=addPartner()
util.TraceHull=function(t) return {Hit=true,HitPos=other:WorldSpaceCenter(),Entity=other} end
service(time+.025);assert(other.hits==0,'released solo warning cannot transfer to late join')
e=pair('conductor');assert(Status:Apply(e,'muted',hero,{direct=true,duration=5}))
assert(not E:BeginSpacing(e,hero,time),'Muted prevents solo Magic admission')
e=pair('conductor');E:Tick(e);a=e.LODRosterAttack;assert(Status:Apply(e,'muted',hero,{direct=true,duration=5}))
service(time+.025);assert(not e.LODRosterAttack and #E.Projectiles==0,'Muted cancels solo Magic warning')
local flee=Status.HandleAIFlee;local fled=0
for _,id in ipairs({'outrider','conductor'}) do
 e=pair(id);Status.HandleAIFlee=function(_,source) assert(source==e);fled=fled+1;return true end
 E:Tick(e);assert(not e.LODRosterAttack,'canonical morale handling precedes spacing admission '..id)
end
Status.HandleAIFlee=flee;assert(fled==2,'both preserve canonical morale dispatch')
print('BESTIARY_B13_NATIVE_GUARDS_PASS: initialized/reentrant warning, release replacement ownership, real solo Raw hit, no late-join transfer, Muted fallback and canonical morale dispatch')
