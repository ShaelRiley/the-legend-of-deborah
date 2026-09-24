-- B10 exercises mobile commitments through the real roster service, combat and status pipeline.
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
MASK_SOLID=3;NULL={valid=false};DMG_ENERGYBEAM,DMG_BURN,DMG_POISON,DMG_SLASH=4,5,6,7
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
dofile(root..'sv_enemy_roster.lua');dofile(root..'sv_enemy_melee.lua');dofile(root..'sv_enemy_mobile.lua');dofile(root..'sv_hostile_motion_v2.lua')
local E,D,C,Status,Rules=LOD.EnemyRoster,LOD.EncounterDirector,LOD.CharacterProgressionSystem,LOD.RPGStatusElements,LOD.RPGAbilityRules
local time,serial=200,100
local function at(n) time=n;env.setTime(n) end
at(time)
local s=LOD.RunManager.State
s.BuildReady=true;s.Failed=false;s.LevelCleared=false;s.SimulationFrozen=false;s.Level=8
s.CampaignEpoch=1;s.RunId='b10';s.CampaignSeed=77;s.LevelSeed=123
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
hero.SteamID64=function() return 'b10-tester' end
hero.Nick=function() return 'B10 tester' end
hero.GetNW2Bool=hero.GetNW2Float
LOD.RunManager.IdentityOf=function(_,p) return p==hero and 'b10-tester' or nil end
local priorGetState=LOD.RunManager.GetPlayerState
LOD.RunManager.GetPlayerState=function(self,p)
    if p=='b10-tester' then return {progressionState=hero.LODProgressionState} end
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
    s.GatesOpen={};party={hero};received=0;hero.hits=0;hero.negate=false
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
    p.SteamID64=function() return 'b10-other-'..p.index end
    return p
end
local function release(e,a)
    advance(e,a.ready+.025)
end
local function placeForHit(id,e,a,p)
    if id=='trailmaker' then p:SetPos(a.start-Vector(0,0,2))
    else p:SetPos(e:GetPos()+Vector(20,0,-2)) end
end
local function firstHit(id,e,a)
    release(e,a);placeForHit(id,e,a,hero)
    advance(e,id=='trailmaker' and a.ready+.9 or time+.1)
end
local e,a=begin('censer')
assert(a.mobile=='carrier' and a.start:Distance(a.goal)==144 and a.direction.x==1,'fixed observed 144-unit carrier route')
assert(math.abs(a.ready-time-1.2)<.000001 and a.moveEnd==a.ready+1.8 and a.expires==a.moveEnd,'fixed finite carrier schedule')
assert(e.nw.LOD_MobileStart==a.start and e.nw.LOD_MobileGoal==a.goal
    and e.nw.LOD_MobileReady==a.ready and e.nw.LOD_MobileUntil==a.expires,'server tell publishes committed geometry and time')
local before=e:GetPos()
advance(e,a.ready-.01)
assert(hero.hits==0 and e:GetPos():DistToSqr(before)==0,'warning has neither damage nor movement')
advance(e,a.moveEnd)
assert(e:GetPos():Distance(before)>130 and e:GetPos():Distance(a.goal)<=4,'real MotionV2 carries danger to frozen goal')
assert(hero.hits==1 and hero.health<10000 and receivedContext.physical,'one real physical settlement across moving carrier')
assert(not receivedContext.magic,'carrier remains physical')
service(a.expires+.01)
assert(not e.LODRosterAttack and e.LODMeleeRecovery,'carrier expires into canonical recovery')
local recovery=e.LODMeleeRecovery.expires
E:Interrupt(e);E:Tick(e);assert(e.LODMeleeRecovery.expires==recovery and e.LODMotionSpeed==0,'repeat interrupt never extends stationary recovery')
at(recovery+.01);E:Tick(e);assert(not e.LODMeleeRecovery,'recovery ends on original deadline')

e,a=begin('trailmaker');assert(a.mobile=='trail' and a.goal.x<a.start.x and a.start:Distance(a.goal)==144,'trail retreats from frozen observation')
assert(a.moveEnd==a.ready+1.8 and a.expires==a.ready+3.8,'fixed trail movement and global expiration')
advance(e,a.ready-.01);assert(hero.hits==0 and #a.patches==0,'no unwarned trail patch')
release(e,a)
assert(#a.patches==1 and a.patches[1].origin:Distance(a.start)<=4,'first patch requires actual start occupancy')
local first=a.patches[1];assert(math.abs(first.ready-time-.8)<.051 and math.abs(first.expires-first.ready-1.2)<.001,'patch delay and lifetime use actual placement')
assert(e.nw.LOD_MobilePatchReady1==first.ready and e.nw.LOD_MobilePatchUntil1==first.expires,'patch timing reaches native tell')
hero:SetPos(a.start-Vector(0,0,2));advance(e,first.ready-.01);assert(hero.hits==0,'patch warning cannot damage')
advance(e,first.ready+.025);assert(hero.hits==1,'armed trail settles through real combat')
advance(e,a.moveEnd)
assert(#a.patches==3 and e:GetPos():Distance(a.goal)<=4,'exactly three reached trail patches')
assert(a.patches[2].origin:Distance((a.start+a.goal)*.5)<=4 and a.patches[3].origin:Distance(a.goal)<=4,'fixed midpoint and endpoint trail positions')
for _,patch in ipairs(a.patches) do
    assert(patch.expires-patch.ready<=1.200001 and patch.expires<=a.expires,'every patch finite within global deadline')
end
hero:SetPos(a.goal-Vector(0,0,2));advance(e,a.expires+.025)
assert(hero.hits==1 and not e.LODRosterAttack,'one Hero cannot farm repeated damage by entering later patches')
print('BESTIARY_B10_MOTION_PASS: real interleaved Tick/Think, frozen carrier/retreat, warning exclusion, three reached patches, native tells, finite recovery')

for _,id in ipairs({'censer','trailmaker'}) do
    e,a=begin(id);local goal=Vector(a.goal.x,a.goal.y,a.goal.z)
    hero:SetPos(center()+Vector(90,112,0));advance(e,a.expires+.025)
    assert(hero.hits==0 and a.goal:DistToSqr(goal)==0,'sidestep escapes without homing '..id)
    e,a=begin(id);e.LODConfig.speed=1
    advance(e,a.moveEnd+.025)
    assert(not e.LODRosterAttack and e:GetPos():Distance(a.start)<10,'slow motion forfeits instead of teleporting '..id)
    if id=='trailmaker' then assert(#a.patches<=1,'unreached midpoint/end never materialize') end
    e,a=begin(id);service(a.moveEnd+.025)
    assert(not e.LODRosterAttack and hero.hits==0 and e:GetPos():Distance(a.start)==0,'missed service deadline cannot catch up '..id)
    E:StepMobile(e,a,time);assert(hero.hits==0,'detached callback cannot settle '..id)
    e,a=begin(id);e.nw.LOD_SizeScale=1.33;local hulls=0
    util.TraceHull=function(t)
        if math.abs(t.maxs.x-16)>.001 then
            hulls=hulls+1;assert(math.abs(t.maxs.x-21.28)<.001 and math.abs(t.maxs.z-95.76)<.001,'scaled actor hull')
        else assert(t.maxs.z==72,'Hero escape pocket uses Hero hull') end
        return {Hit=false,HitPos=t.endpos}
    end
    release(e,a);assert(hulls>0,'dynamic scaled geometry revalidated '..id)
    e,a=begin(id);release(e,a);service(time+.201)
    assert(not e.LODRosterAttack and hero.hits==0,'postrelease service stall forfeits without catchup '..id)
    e,a=begin(id)
    local direction=id=='censer' and 1 or -1
    util.TraceLine=function(t)
        if math.abs(t.start.x-(a.start.x+36*direction))<13 and t.endpos.z<center().z then
            return {Hit=false,HitPos=t.endpos}
        end
        return clearTrace(t)
    end
    release(e,a)
    assert(not e.LODRosterAttack and e:GetPos():DistToSqr(a.start)==0,'between-anchor floor gap prevents travel '..id)
end
local function lateralHole(t)
    -- Route anchors and the advertised 112-unit pocket stay supported; only
    -- the interior of each lateral route loses its floor.
    if math.abs(math.abs(t.start.y-center().y)-45)<4 and t.endpos.z<center().z then
        return {Hit=false,HitPos=t.endpos}
    end
    return clearTrace(t)
end
for _,id in ipairs({'censer','trailmaker'}) do
    for _,case in ipairs({'cover','floor','hull','safe','objective','transition','gate','outside','escapeFloor','escapeInterior','escapeHull'}) do
        e=pair(id)
        if case=='cover' then util.TraceLine=coverTrace
        elseif case=='floor' then util.TraceLine=function(t) return {Hit=false,HitPos=t.endpos} end
        elseif case=='hull' then util.TraceHull=function() return {Hit=true,StartSolid=true} end
        elseif case=='safe' then s.Graph.CellTags[key(3,3,0)]={safe=true}
        elseif case=='objective' then s.Graph.CellTags[key(3,3,0)]={objective=true}
        elseif case=='transition' then s.Graph.VerticalEdges={{a=s.Graph.Cells[key(3,3,0)],b=s.Graph.Cells[key(4,3,0)]}}
        elseif case=='gate' then s.Graph.Progression.Gates={{beforeCell=s.Graph.Cells[key(3,3,0)],afterCell=s.Graph.Cells[key(4,3,0)]}}
        elseif case=='outside' then hero:SetPos(center()+Vector(400,0,0))
        elseif case=='escapeFloor' then util.TraceLine=function(t)
            if math.abs(t.start.y-center().y)>100 then return {Hit=false,HitPos=t.endpos} end
            return clearTrace(t)
        end
        elseif case=='escapeInterior' then util.TraceLine=lateralHole
        elseif case=='escapeHull' then util.TraceHull=function(t)
            return {Hit=math.abs(t.endpos.y-center().y)>100,HitPos=t.endpos}
        end end
        assert(not E:BeginMobile(e,hero,time),'unsafe admission refused '..id..' '..case)
    end
    e,a=begin(id);release(e,a)
    if id=='trailmaker' then advance(e,a.patches[1].ready+.025) end
    service(math.max(time,a.nextGeometry)+.001)
    assert(hero.hits==0 and a.nextGeometry>time+.001,'armed use falls between periodic geometry checks '..id)
    placeForHit(id,e,a,hero);util.TraceLine=lateralHole
    service(time+.001)
    assert(hero.hits==0 and not e.LODRosterAttack,'armed use rejects newly opened interior lateral escape hole '..id)
end
print('BESTIARY_B10_GEOMETRY_PASS: fixed escape answers, no stall teleport/catchup, scaled swept hull, cover/support/safe/objective/transition/gate/escape-pocket admission')

local mutations={
    sourceDeath=function(e) e.LODDead=true end,
    sourceRemoval=function(e) e.valid=false end,
    sourceHealth=function(e) e.health=0 end,
    sourceInactive=function(e) e.LODActivated=false end,
    sourceProgression=function(e) e.LODProgressionState=table.Copy(e.LODProgressionState) end,
    sourceLife=function(e) Status:ResetActorLife(e) end,
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
    interrupt=function(e) E:Interrupt(e) end,
    stun=function(e) e.LODHitStunUntil=time+5 end,
    support=function() util.TraceLine=function(t) return {Hit=false,HitPos=t.endpos} end end,
    cover=function() util.TraceLine=coverTrace end,
    hull=function() util.TraceHull=function() return {Hit=true,StartSolid=true} end end,
    objective=function() s.Graph.CellTags[key(3,3,0)]={objective=true} end,
    safe=function() s.Graph.CellTags[key(3,3,0)]={safe=true} end,
    transition=function() s.Graph.VerticalEdges={{a=s.Graph.Cells[key(3,3,0)],b=s.Graph.Cells[key(4,3,0)]}} end,
    gate=function() s.Graph.Progression.Gates={{beforeCell=s.Graph.Cells[key(3,3,0)],afterCell=s.Graph.Cells[key(4,3,0)]}} end,
    displaced=function(e) e:SetPos(e:GetPos()+Vector(0,10,0)) end,
    teleported=function(e) e:SetPos(e:GetPos()+Vector(160,0,0)) end,
}
for _,id in ipairs({'censer','trailmaker'}) do
    for _,phase in ipairs(id=='trailmaker' and {'warning','moving','lingering'} or {'warning','moving'}) do
        for name,mutate in pairs(mutations) do
            e,a=begin(id)
            if phase=='moving' then release(e,a) end
            if phase=='lingering' then advance(e,a.ready+1.1);assert(a.arrived,'lingering trail geometry remains life-bound') end
            local hits=hero.hits;mutate(e);service(time+.125)
            if phase~='warning' and name=='cover' then advance(e,a.expires+.025) end
            assert(hero.hits==hits and (not e.LODRosterAttack or not IsValid(e) and not E.Active[e]),'retire '..id..' '..phase..' '..name)
        end
    end
    for _,statusId in ipairs({'held','muted','morale_flee','intimidated'}) do
        e,a=begin(id)
        if statusId=='morale_flee' then
            assert(Status:AttemptMorale(hero,e,{forceMorale=true,rng={Int=function(_,lo) return lo end}}))
        else assert(Status:Apply(e,statusId,hero,{direct=true,duration=5})) end
        service(time+.025)
        if statusId=='muted' then firstHit(id,e,a);assert(hero.hits==1,'Muted permits physical mobile attack '..id)
        else assert(not e.LODRosterAttack,'canonical control cancels '..id..' '..statusId) end
    end
end
print('BESTIARY_B10_LIFETIME_PASS: exact source/Hero/run/graph/progression/campaign lifetimes before/after release, geometry changes/displacement, Held/Muted/morale/attack prohibition')

for _,id in ipairs({'censer','trailmaker'}) do
    for _,case in ipairs({'inside','outside','above','otherFloor','rear'}) do
        e,a=begin(id);release(e,a)
        local origin=id=='censer' and e:GetPos() or a.start
        local radius=id=='censer' and 64 or 44
        local offset=({inside=Vector(0,radius-4,-2),outside=Vector(0,radius+4,-2),
            above=Vector(0,0,76),otherFloor=Vector(0,0,384),rear=Vector(-20,0,-2)})[case]
        hero:SetPos(origin+offset)
        advance(e,id=='trailmaker' and a.ready+.9 or time+.025)
        assert(hero.hits==((case=='inside' or case=='rear') and 1 or 0),'actual hazard radius/height '..id..' '..case)
    end
    for _,case in ipairs({'eligible','late join','revival','progression','disconnect'}) do
        local other
        e,a=begin(id,function() other=extraHero();party=case=='late join' and {hero} or {hero,other} end)
        if case=='late join' then party={hero,other}
        elseif case=='revival' then Status:ResetActorLife(other)
        elseif case=='progression' then other.LODProgressionState=table.Copy(other.LODProgressionState)
        elseif case=='disconnect' then other.valid=false end
        player.GetAll=function() error('mobile service must not rescan players') end
        release(e,a);placeForHit(id,e,a,hero);placeForHit(id,e,a,other)
        advance(e,id=='trailmaker' and a.ready+.9 or time+.1)
        assert(hero.hits==1 and other.hits==(case=='eligible' and 1 or 0),'frozen multiplayer participants '..id..' '..case)
        player.GetAll=function() return party end
    end
    for _,primaryFirst in ipairs({true,false}) do
        local other
        e,a=begin(id,function() other=extraHero();hero.health=1;party=primaryFirst and {hero,other} or {other,hero} end)
        release(e,a);placeForHit(id,e,a,hero);placeForHit(id,e,a,other)
        advance(e,id=='trailmaker' and a.ready+.9 or time+.1)
        assert(hero.health==0 and other.hits==1,'same-service lethal-primary party order independence '..id)
    end
    e,a=begin(id);local contractCount=0;local realRoll=LOD.CombatRolls.RollHostileAttack
    LOD.CombatRolls.RollHostileAttack=function(self,...) contractCount=contractCount+1;return realRoll(self,...) end
    firstHit(id,e,a);advance(e,a.expires+.025)
    assert(contractCount==1 and hero.hits==1,'one roll and native settlement for one Hero per commitment '..id)
    LOD.CombatRolls.RollHostileAttack=realRoll
    e,a=begin(id);local native=hero.TakeDamageInfo
    hero.TakeDamageInfo=function(self,info) E:StepMobile(e,a,time);native(self,info) end
    firstHit(id,e,a);assert(hero.hits==1,'reentrant native callback cannot repeat hit '..id)
    hero.TakeDamageInfo=native
    local other
    e,a=begin(id,function() other=extraHero();party={hero,other} end)
    hero.TakeDamageInfo=function(self,info) native(self,info);Status:ResetActorLife(e) end
    release(e,a);placeForHit(id,e,a,hero);placeForHit(id,e,a,other)
    advance(e,id=='trailmaker' and a.ready+.9 or time+.1)
    assert(hero.hits==1 and other.hits==0,'native callback source-incarnation replacement cancels remaining settlement '..id)
    hero.TakeDamageInfo=native
end
e,a=begin('censer',function() party={hero};for i=1,40 do party[#party+1]=extraHero() end end)
assert(#a.participants==32,'one admission captures at most 32 party lives')
reset();local committed={}
for i=1,17 do
    local source=actor('censer');source:SetPos(center()+Vector(0,0,2));source.LODTarget=hero
    E:Prepare(source);D.Entities[#D.Entities+1]=source
    local allowed=E:BeginMobile(source,hero,time)
    assert(allowed==(i<=16),'global mobile admission cap at 16')
    if allowed then committed[#committed+1]=source end
end
E:Interrupt(committed[1]);local replacement=actor('censer');replacement:SetPos(center()+Vector(0,0,2));E:Prepare(replacement)
assert(E:BeginMobile(replacement,hero,time),'retirement releases mobile budget')
print('BESTIARY_B10_MULTIPLAYER_PASS: captured party lives/no rescans, one canonical roll/settlement, callback reentrancy, 32-player/16-commitment bounds')
