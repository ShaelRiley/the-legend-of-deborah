-- B7 exercises melee commitments through the real roster service, combat and status pipeline.
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
dofile(root..'sv_enemy_roster.lua');dofile(root..'sv_enemy_melee.lua');dofile(root..'sv_hostile_motion_v2.lua')
local E,D,C,Status,Rules=LOD.EnemyRoster,LOD.EncounterDirector,LOD.CharacterProgressionSystem,LOD.RPGStatusElements,LOD.RPGAbilityRules
local time,serial=200,100
local function at(n) time=n;env.setTime(n) end
at(time)
local s=LOD.RunManager.State
s.BuildReady=true;s.Failed=false;s.LevelCleared=false;s.SimulationFrozen=false;s.Level=8
s.CampaignEpoch=1;s.RunId='b7';s.CampaignSeed=77;s.LevelSeed=123
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
hero.SteamID64=function() return 'b7-tester' end
hero.Nick=function() return 'B7 tester' end
hero.GetNW2Bool=hero.GetNW2Float
LOD.RunManager.IdentityOf=function(_,p) return p==hero and 'b7-tester' or nil end
local priorGetState=LOD.RunManager.GetPlayerState
LOD.RunManager.GetPlayerState=function(self,p)
    if p=='b7-tester' then return {progressionState=hero.LODProgressionState} end
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
local function strike(e,a,second)
    service((second and a.second or a.ready)-.01)
    local hits=hero.hits;service((second and a.second or a.ready)+.01)
    return hero.hits-hits
end
local e,a=begin('reaper')
assert(a.direction.x==1 and e.nw.LOD_MeleeMode==1 and e.nw.LOD_MeleeOrigin==a.origin)
assert(strike(e,a)==1 and receivedContext.physical and receivedContext.melee,'real physical melee damage and one native-doubled HP settlement')
assert(hero.health<10000 and not e.LODRosterAttack,'one sweep settles')
local recovery=e.LODMeleeRecovery.expires
E:Interrupt(e);E:Tick(e);assert(e.LODMeleeRecovery.expires==recovery and e.LODMotionSpeed==0,'repeat interruption cannot extend stationary recovery')
at(recovery+.01);E:Tick(e);assert(not e.LODMeleeRecovery,'finite recovery returns AI')
for _,case in ipairs({'rear','range','cover','height','floor'}) do
    e,a=begin('reaper')
    local offset=({rear=Vector(-60,0,0),range=Vector(150,0,0),height=Vector(90,0,80),floor=Vector(90,0,384)})[case]
    if offset then hero:SetPos(center()+offset) else util.TraceLine=coverTrace end
    assert(strike(e,a)==0,'sweep escape '..case)
end
e,a=begin('reaper');hero:SetPos(center()+Vector(10,110,0));assert(strike(e,a)==1,'wide lateral sweep distinguishes narrow strikes')
e,a=begin('drubber');local frozen=Vector(a.direction.x,a.direction.y,a.direction.z)
assert(a.second==a.ready+.85 and e.nw.LOD_MeleeSecond==a.second,'fixed visible two-beat schedule')
assert(strike(e,a)==1 and e.LODRosterAttack==a,'first strike leaves an escape interval')
hero:SetPos(center()+Vector(140,110,0));assert(strike(e,a,true)==0,'sidestep during escape interval avoids second strike')
assert(a.direction:DistToSqr(frozen)==0 and not e.LODRosterAttack,'no second-beat homing')
e,a=begin('drubber');assert(strike(e,a)==1);local firstContract=receivedContext.attackEvent
hero:SetPos(center()+Vector(160,0,0));assert(strike(e,a,true)==1,'second farther strike punishes straight re-entry')
assert(firstContract~=receivedContext.attackEvent,'each beat has its own canonical attack contract')
for _,id in ipairs({'reaper','drubber'}) do
    e,a=begin(id);service(a.ready+.21)
    assert(hero.hits==0 and not e.LODRosterAttack,'missed first deadline forfeits '..id)
    E:StepMelee(e,a,time);assert(hero.hits==0,'detached callback cannot settle')
end
e,a=begin('drubber');strike(e,a);service(a.second+.21)
assert(hero.hits==1 and not e.LODRosterAttack,'missed second deadline cannot catch up')
print('BESTIARY_B7_SPACING_PASS: canonical physical melee, broad flank/rear/range/height/cover answers, two distinct beat contracts, frozen escape interval, deadlines/recovery')

-- Real MotionV2 moves the Fencer; only Source hull/floor traces are doubled.
local function retreat(e,a)
    local deadline=a.retreatEnd
    while time<deadline do
        E:Tick(e) -- native actor AI also holds the active commitment between service steps
        service(math.min(deadline,time+.025))
    end
    assert(e:GetPos():Distance(a.origin)<=4 and not a.retreatEnd,'canonical retreat reaches frozen endpoint')
end
e,a=begin('fencer');local start=e:GetPos();retreat(e,a)
assert(start:Distance(e:GetPos())>=64 and hero.hits==0,'backstep is real bounded nondamaging locomotion')
local origin=a.origin;assert(strike(e,a)==1 and a.origin==origin,'fixed thrust from committed endpoint')
e,a=begin('fencer');retreat(e,a);hero:SetPos(center()+Vector(90,30,0));assert(strike(e,a)==0,'narrow thrust sidestep')
e,a=begin('fencer');e.LODConfig.speed=1
service(a.retreatEnd+.01);assert(not e.LODRosterAttack and hero.hits==0,'slow or unserviced retreat forfeits rather than teleporting')
e,a=begin('fencer');local heldAt=e:GetPos()
util.TraceHull=function() return {Hit=true,HitPos=heldAt} end
service(time+.025);assert(e:GetPos()==heldAt and not e.LODRosterAttack,'new obstruction stops before canonical movement')
e,a=begin('fencer');local expectedHull=0
e.nw.LOD_SizeScale=1.33
util.TraceHull=function(t) expectedHull=expectedHull+1;assert(math.abs(t.maxs.x-21.28)<.001 and math.abs(t.maxs.z-95.76)<.001);return {Hit=false,HitPos=t.endpos} end
service(time+.025);assert(expectedHull==1,'one scaled full remaining-route hull per service')
print('BESTIARY_B7_MOTION_PASS: real MotionV2, fixed non-damaging backstep, narrow thrust, no stall teleport/deadline extension, swept scaled obstruction')

local mutations={
    sourceDeath=function(e) e.LODDead=true end,
    sourceRemoval=function(e) e.valid=false end,
    sourceHealth=function(e) e.health=0 end,
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
    runId=function() s.RunId=s.RunId..'x' end,
    freeze=function() s.SimulationFrozen=true end,
    failure=function() s.Failed=true end,
    clear=function() s.LevelCleared=true end,
    interrupt=function(e) E:Interrupt(e) end,
    stun=function(e) e.LODHitStunUntil=time+5 end,
    support=function() util.TraceLine=function(t) return {Hit=false,HitPos=t.endpos} end end,
    objective=function() s.Graph.CellTags[key(3,3,0)]={objective=true} end,
    transition=function() s.Graph.VerticalEdges={{a=s.Graph.Cells[key(3,3,0)],b=s.Graph.Cells[key(4,3,0)]}} end,
    gate=function() s.Graph.Progression.Gates={{beforeCell=s.Graph.Cells[key(3,3,0)],afterCell=s.Graph.Cells[key(4,3,0)]}} end,
    displaced=function(e) e:SetPos(e:GetPos()+Vector(0,10,0)) end,
}
for _,id in ipairs({'reaper','drubber','fencer'}) do
    for name,mutate in pairs(mutations) do
        e,a=begin(id);mutate(e);service(a.ready+.01)
        assert(hero.hits==0 and (not e.LODRosterAttack or not IsValid(e) and not E.Active[e]),'retire '..id..' '..name)
    end
end
for _,id in ipairs({'reaper','drubber','fencer'}) do
    e=pair(id);util.TraceLine=function(t) return {Hit=false,HitPos=t.endpos} end
    assert(not E:BeginMelee(e,hero,time),'missing floor blocks admission')
    e=pair(id);hero:SetPos(center()+Vector(400,0,0));assert(not E:BeginMelee(e,hero,time),'another cell blocks admission')
end
e=pair('fencer');util.TraceHull=function() return {Hit=true,StartSolid=true} end
assert(not E:BeginMelee(e,hero,time),'blocked backstep never commits')
for _,id in ipairs({'reaper','drubber','fencer'}) do
    for _,statusId in ipairs({'held','muted','morale_flee'}) do
        e,a=begin(id)
        if statusId=='morale_flee' then
            assert(Status:AttemptMorale(hero,e,{forceMorale=true,rng={Int=function(_,lo) return lo end}}))
            assert(Status:Has(e,'morale_flee'),'forced failed ordinary morale save')
        else assert(Status:Apply(e,statusId,hero,{direct=true,duration=5})) end
        service(time+.025)
        if statusId=='morale_flee' or statusId=='held' and id=='fencer' then
            assert(not e.LODRosterAttack,'canonical control cancels '..id..' '..statusId)
        elseif id~='fencer' then assert(e.LODRosterAttack==a and strike(e,a)==1,'stationary physical strike remains available '..statusId)
        else retreat(e,a);assert(strike(e,a)==1,'Muted permits physical thrust') end
    end
end
print('BESTIARY_B7_LIFETIME_PASS: exact source/Hero/run/graph/progression/campaign scopes; same-seed replacement; cover/support/gates; freeze/death/stun; canonical Held/Muted/morale')

local function extraHero()
    local p=actor('runner');p.player=true;p.LODHostile=false;p.hits=0;p.health=10000
    p:SetPos(center()+Vector(90,0,0));p.LODProgressionState=table.Copy(hero.LODProgressionState)
    p.GetActiveWeapon=hero.GetActiveWeapon;p.GetClass=hero.GetClass;p.Nick=hero.Nick
    p.GetNW2Bool=p.GetNW2Float;p.TakeDamageInfo=hero.TakeDamageInfo
    p.SteamID64=function() return 'b7-other-'..p.index end
    return p
end
for _,case in ipairs({'eligible','late join','revival','progression','disconnect'}) do
    local other
    e,a=begin('reaper',function()
        other=extraHero();party=case=='late join' and {hero} or {hero,other}
    end)
    if case=='late join' then party={hero,other}
    elseif case=='revival' then Status:ResetActorLife(other)
    elseif case=='progression' then other.LODProgressionState=table.Copy(other.LODProgressionState)
    elseif case=='disconnect' then other.valid=false end
    player.GetAll=function() error('service must not rescan players') end
    strike(e,a)
    assert(hero.hits==1 and other.hits==(case=='eligible' and 1 or 0),'frozen multiplayer participants '..case)
    player.GetAll=function() return party end
end
for _,primaryFirst in ipairs({true,false}) do
    local other
    e,a=begin('reaper',function()
        other=extraHero();hero.health=1;party=primaryFirst and {hero,other} or {other,hero}
    end)
    strike(e,a);assert(hero.health==0 and other.hits==1,'same beat lethal-primary order independence')
end
e,a=begin('reaper');local contractCount=0;local realRoll=LOD.CombatRolls.RollHostileAttack
LOD.CombatRolls.RollHostileAttack=function(self,...) contractCount=contractCount+1;return realRoll(self,...) end
strike(e,a);service(time+.025);assert(contractCount==1 and hero.hits==1,'one roll and settlement per beat')
LOD.CombatRolls.RollHostileAttack=realRoll
print('BESTIARY_B7_MULTIPLAYER_PASS: captured lives, no unseen tell inheritance/rescans, lethal-primary order independence, canonical one-roll settlement')
