-- B6 exercises trap commitments through the real roster service, combat and status pipeline.
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
dofile(root..'sv_enemy_roster.lua');dofile(root..'sv_enemy_traps.lua')
local E,D,C,Status,Rules=LOD.EnemyRoster,LOD.EncounterDirector,LOD.CharacterProgressionSystem,LOD.RPGStatusElements,LOD.RPGAbilityRules
local time,serial=200,100
local function at(n) time=n;env.setTime(n) end
at(time)
local s=LOD.RunManager.State
s.BuildReady=true;s.Failed=false;s.LevelCleared=false;s.SimulationFrozen=false;s.Level=8
s.CampaignEpoch=1;s.RunId='b6';s.CampaignSeed=77;s.LevelSeed=123
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
hero.SteamID64=function() return 'b6-tester' end
hero.Nick=function() return 'B6 tester' end
hero.GetNW2Bool=hero.GetNW2Float
LOD.RunManager.IdentityOf=function(_,p) return p==hero and 'b6-tester' or nil end
local priorGetState=LOD.RunManager.GetPlayerState
LOD.RunManager.GetPlayerState=function(self,p)
    if p=='b6-tester' then return {progressionState=hero.LODProgressionState} end
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
    reset();local e=actor(id);e:SetPos(center());e.LODTarget=hero
    E:Prepare(e);D.Entities={e};return e
end
local function begin(id,setup)
    local e=pair(id);if setup then setup(e) end
    E:Tick(e);return e,assert(e.LODRosterAttack,'production AI commits '..id)
end
local function arm(e,a)
    service(a.ready-.01);assert(not a.released,'full warning before arming')
    service(a.ready+.01);assert(a.released,'production service arms')
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
local e,a=begin('wirewright')
hero:SetPos(center()+Vector(-20,0,0));service(a.ready-.01)
hero:SetPos(center()+Vector(20,0,0));service(a.ready+.01)
assert(hero.hits==0,'warning-period crossing cannot retroactively hit on arming')
hero:SetPos(center()+Vector(-20,0,0));service(time+.05)
assert(hero.hits==1 and receivedContext.physical,'armed swept crossing enters canonical physical damage')
local hp=hero.health;hero:SetPos(center()+Vector(20,0,0));service(time+.05)
assert(hero.hits==1 and hero.health==hp,'one settlement per Hero per wire')
for _,case in ipairs({'endpoint','jump','cover'}) do
    e,a=begin('wirewright');arm(e,a)
    local y=case=='endpoint' and 140 or 0;local z=case=='jump' and 60 or 0
    hero:SetPos(center()+Vector(20,y,z));service(time+.05)
    if case=='cover' then util.TraceLine=coverTrace end
    hero:SetPos(center()+Vector(-20,y,z));service(time+.05)
    assert(hero.hits==0,'wire escape '..case)
end
e,a=begin('wirewright');arm(e,a);local committedScans=scans
player.GetAll=function() error('trap service scanned players after commit') end
service(time+.05);service(a.expires)
assert(not e.LODRosterAttack,'finite live wire expiry')
player.GetAll=function() scans=scans+1;return party end
assert(scans==committedScans,'no fresh participant scan')
print('BESTIARY_B6_WIRE_PASS: full warning, no warning-tail hit, swept crossing, endpoint/jump/cover escape, one physical settlement, fixed expiry and no participant rescan')

for _,distance in ipairs({0,70,90,180}) do
    e,a=begin('cordon',function() hero:SetPos(center()+Vector(distance,0,0)) end)
    arm(e,a)
    assert(hero.hits==(distance==90 and 1 or 0),'ring safe center and exterior')
    assert(not e.LODRosterAttack,'ring is a single pulse followed by recovery')
    local nextAttack=e.LODNextAttack;service(time+.05)
    assert(e.LODNextAttack==nextAttack,'recovery does not extend on service')
end
e,a=begin('cordon');util.TraceLine=coverTrace
service(a.ready+.01);assert(hero.hits==0 and not e.LODRosterAttack,'new cover prevents pulse')
print('BESTIARY_B6_RING_PASS: safe center/exterior, one pulse, canonical recovery and cover')

local function snare(setup)
    local source,attack=begin('snarer',setup);arm(source,attack)
    assert(attack.snap and attack.snap>attack.ready+1.25,'arming and proximity snap are separate deadlines')
    return source,attack
end
e,a=snare();local mark=a.origin;local snap=a.snap;local expiry=a.expires
service(snap-.01);assert(hero.hits==0,'complete snap escape window')
hero:SetPos(center()+Vector(-120,0,0));service(snap+.01)
assert(hero.hits==0 and not e.LODRosterAttack and a.origin==mark,'bait escape leaves one frozen empty snap')
e,a=snare();snap=a.snap;expiry=a.expires
service(time+.1);service(time+.1)
assert(a.snap==snap and a.expires==expiry,'repeated proximity never extends either deadline')
service(snap+.01)
assert(hero.hits==1 and receivedContext.magic and receivedContext.element=='ice'
    and receivedContext.riderStatusId=='held','snare enters canonical Ice damage contract')
assert(Status:Has(hero,'held'),'failed Wisdom save applies canonical Held')
for _,case in ipairs({'save','immune','zero','lethal'}) do
    saveRoll=case=='save' and 20 or 1
    e,a=snare(function()
        if case=='immune' then hero.LODStatusImmunities={'held'} end
        if case=='zero' then hero.negate=true end
        if case=='lethal' then hero.health=1 end
    end)
    service(a.snap+.01);assert(not Status:Has(hero,'held'),'canonical rider suppression '..case)
    if case=='lethal' then assert(hero.health==0,'lethal snap') end
end
saveRoll=1
e,a=snare();service(a.snap+.21)
assert(hero.hits==0 and not e.LODRosterAttack,'missed snap cannot catch up damage')
E:StepTrap(e,a,time)
assert(hero.hits==0,'detached expired commitment cannot settle through a stale callback')
e,a=begin('snarer',function() hero:SetPos(center()+Vector(140,0,0)) end)
hero:SetPos(center()+Vector(-100,0,0));arm(e,a);assert(not a.snap,'no proximity outside frozen circle')
service(a.expires-1.3);hero:SetPos(a.origin-Vector(0,0,3));service(time+.05)
assert(not a.snap,'too-late proximity cannot compress escape warning or extend expiry')
service(a.expires);assert(not e.LODRosterAttack,'untriggered snare expires')
print('BESTIARY_B6_SNARE_PASS: separate fixed arm/snap deadlines, bait escape, no tracking/extension, real Ice/Held save/immunity/zero/lethal rules')

local invalidations={
    {'source progression',function(source) source.LODProgressionState=table.Copy(source.LODProgressionState) end},
    {'Hero progression',function() hero.LODProgressionState=table.Copy(hero.LODProgressionState) end},
    {'source life',function(source) Status:ResetActorLife(source) end},
    {'Hero revival',function() Status:ResetActorLife(hero) end},
    {'same-seed state',function() LOD.RunManager.State=table.Copy(s) end},
    {'same-seed graph',function() s.Graph=table.Copy(s.Graph) end},
    {'progression',function() s.Graph.Progression=table.Copy(s.Graph.Progression) end},
    {'campaign',function() s.CampaignEpoch=s.CampaignEpoch+1 end},
    {'seed',function() s.LevelSeed=s.LevelSeed+1 end},
    {'campaign seed',function() s.CampaignSeed=s.CampaignSeed+1 end},
    {'run',function() s.RunId=s.RunId..'x' end},
    {'freeze',function() s.SimulationFrozen=true end},
    {'failure',function() s.Failed=true end},
    {'clear',function() s.LevelCleared=true end},
    {'source removal',function(source) source.valid=false end},
    {'source death',function(source) source.LODDead=true end},
    {'Hero death',function() hero.alive=false end},
    {'disconnect',function() hero.valid=false end},
    {'source displacement',function(source) source:SetPos(source:GetPos()+Vector(33,0,0)) end},
    {'hit stun',function(source) source.LODHitStunUntil=time+2 end},
}
for _,id in ipairs({'wirewright','snarer','cordon'}) do
    for _,armed in ipairs({false,true}) do
        for _,row in ipairs(invalidations) do
            e,a=begin(id)
            if armed and id~='cordon' then arm(e,a) end
            row[2](e);service(time+.05)
            assert(not e.LODRosterAttack or not e.valid,'cancel '..id..' '..row[1]..' armed='..tostring(armed))
            assert(hero.hits==0,'no invalid-lifetime damage '..id..' '..row[1])
        end
    end
end
for _,id in ipairs({'wirewright','snarer','cordon'}) do
    e,a=begin(id);E:Interrupt(e);assert(not e.LODRosterAttack,'explicit interruption')
    e,a=begin(id);service(a.armDeadline+.01);assert(not e.LODRosterAttack,'missed arming deadline cannot fire late')
    e,a=begin(id);assert(Status:Apply(e,'held',hero,{skipSave=true}));service(a.ready+.01)
    assert(a.released,'Held permits stationary physical and Ice attack')
    e,a=begin(id);assert(Status:Apply(e,'muted',hero,{skipSave=true}));service(a.ready+.01)
    assert((id=='snarer' and not e.LODRosterAttack) or (id~='snarer' and a.released),'Mute cancels only Ice')
end
print('BESTIARY_B6_LIFE_PASS: exact source/primary Hero incarnation and state/graph/progression/campaign/seed boundaries, displacement, interruption, Held/Mute and fixed arm deadline')

for _,case in ipairs({'safe','objective','stair','gate','cover','escape'}) do
    e=pair('wirewright');local c=s.Graph.Cells[key(3,3,0)]
    if case=='safe' then s.Graph.CellTags[E.Key(c)]={safe=true}
    elseif case=='objective' then s.Graph.CellTags[E.Key(c)]={objective=true}
    elseif case=='stair' then s.Graph.VerticalEdges={{a=c,b={x=3,y=3,z=1}}}
    elseif case=='gate' then s.Graph.Progression.Gates={{beforeCell=c,afterCell=s.Graph.Cells[key(4,3,0)]}}
    elseif case=='cover' then util.TraceLine=coverTrace
    elseif case=='escape' then util.TraceHull=function(t) return {Hit=true,HitPos=t.endpos} end end
    assert(not E:BeginTrap(e,hero,time) and not e.LODRosterAttack,'reject unsafe trap placement '..case)
end
reset()
local admitted={}
for i=1,17 do
    e=actor('wirewright');e:SetPos(center());E:Prepare(e)
    admitted[#admitted+1]=e
    local ok=E:BeginTrap(e,hero,time)
    assert(ok==(i<=16),'shared max16 commitment admission '..i..' '..tostring(ok))
end
print('BESTIARY_B6_BUDGET_PASS: max16 commitments; safe/objective/stair/gate/cover/escape rejection')

local function extraHero(offset)
    local p=actor('runner');p.player=true;p.LODHostile=false;p.hits=0;p.health=10000
    p:SetPos(center()+(offset or Vector(90,0,0)))
    p.LODProgressionState=table.Copy(hero.LODProgressionState)
    p.GetActiveWeapon=hero.GetActiveWeapon;p.GetClass=hero.GetClass;p.Nick=hero.Nick
    p.GetNW2Bool=p.GetNW2Float;p.TakeDamageInfo=hero.TakeDamageInfo
    p.SteamID64=function() return 'b6-other-'..p.index end
    return p
end
for _,id in ipairs({'cordon','snarer'}) do
    for _,primaryFirst in ipairs({true,false}) do
        local other
        e,a=begin(id,function()
            other=extraHero();hero.health=1
            party=primaryFirst and {hero,other} or {other,hero}
        end)
        arm(e,a);if id=='snarer' then service(a.snap+.01) end
        assert(hero.health==0 and other.hits==1,'lethal primary target does not skip the other Hero '..id)
        assert(not e.LODRosterAttack,'multiplayer single pulse ends')
    end
end
for _,case in ipairs({'eligible','late join','revival','progression','disconnect'}) do
    local other
    e,a=begin('wirewright',function()
        other=extraHero(Vector(20,0,0));hero:SetPos(center()+Vector(20,0,0))
        party=case=='late join' and {hero} or {hero,other}
    end)
    arm(e,a)
    if case=='late join' then party={hero,other}
    elseif case=='revival' then Status:ResetActorLife(other)
    elseif case=='progression' then other.LODProgressionState=table.Copy(other.LODProgressionState)
    elseif case=='disconnect' then other.valid=false end
    hero:SetPos(center()+Vector(-20,0,0));other:SetPos(center()+Vector(-20,0,0));service(time+.05)
    assert(hero.hits==1 and other.hits==(case=='eligible' and 1 or 0),'captured eligible incarnations only: '..case)
    hero:SetPos(center()+Vector(20,0,0));other:SetPos(center()+Vector(20,0,0));service(time+.05)
    assert(hero.hits==1 and other.hits==(case=='eligible' and 1 or 0),'multiplayer dedup: '..case)
end
print('BESTIARY_B6_MULTIPLAYER_PASS: one hit each; lethal-primary order independent; no late join, revival, progression replacement or disconnect inheritance')

for _,id in ipairs({'wirewright','snarer','cordon'}) do
    e=pair(id);util.TraceLine=function(t) return {Hit=false,HitPos=t.endpos} end
    assert(not E:BeginTrap(e,hero,time),'missing native floor rejects '..id)
    e,a=begin(id)
    if id~='cordon' then arm(e,a) end
    util.TraceLine=function(t) return {Hit=false,HitPos=t.endpos} end
    service(time+.05);assert(not e.LODRosterAttack and hero.hits==0,'removed native floor cancels '..id)
end
e,a=begin('wirewright');arm(e,a)
local traceCount=0
util.TraceLine=function(t) traceCount=traceCount+1;return clearTrace(t) end
service(time+.05)
assert(traceCount<=3+#a.participants,'bounded support and captured-Hero LOS work')
print('BESTIARY_B6_SUPPORT_PASS: missing/removed native floors reject/cancel and support/LOS work is bounded')
