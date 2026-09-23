-- B8 exercises melee commitments through the real roster service, combat and status pipeline.
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
s.CampaignEpoch=1;s.RunId='b8';s.CampaignSeed=77;s.LevelSeed=123
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
hero.SteamID64=function() return 'b8-tester' end
hero.Nick=function() return 'B8 tester' end
hero.GetNW2Bool=hero.GetNW2Float
LOD.RunManager.IdentityOf=function(_,p) return p==hero and 'b8-tester' or nil end
local priorGetState=LOD.RunManager.GetPlayerState
LOD.RunManager.GetPlayerState=function(self,p)
    if p=='b8-tester' then return {progressionState=hero.LODProgressionState} end
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

dofile(root..'sv_enemy_remains.lua')
local R=LOD.EnemyRemains
LOD.HostileRegistry={List=function() return D.Entities end}
local basePair=pair
pair=function(id) R.Active={};R.Pending={};R.Count=0;return basePair(id) end
local deaths=LOD.HostileDeathPresentation
-- Load actual lethal callback, deferred native presentation and one-second handoff.
local timers={};timer.Exists=function(id) return timers[id]~=nil end
timer.Create=function(id,delay,reps,fn) timers[id]=fn end
timer.Adjust=noop;timer.Remove=function(id) timers[id]=nil end
AddCSLuaFile=noop;include=noop;concommand={Add=noop};vector_origin=Vector()
COLLISION_GROUP_DEBRIS,SOLID_NONE,MOVETYPE_NONE=1,2,3
ENT={};dofile('gamemodes/legend_of_deborah/entities/entities/lod_hostile/init.lua')
local Native=ENT;deaths=LOD.HostileDeathPresentation
local kills,drops=0,0
local function native(e)
    e.OnKilled=Native.OnKilled;e._BeginDeathPresentation=Native._BeginDeathPresentation
    e._FinishDeathPresentation=Native._FinishDeathPresentation
    e.SetNoDraw=function(self,b) self.hidden=b end
    e.SetVelocity=noop;e.SetCollisionGroup=noop;e.SetSolid=noop;e.SetMoveType=noop;e.DrawShadow=noop
    e._SpawnPlaceholderLoot=function() drops=drops+1 end
    return e
end
local baseNew=actor
actor=function(...) return native(baseNew(...)) end
-- Existing pair closure observes the rebound actor factory.
local realKilled=D.OnHostileKilled
D.OnHostileKilled=function(_,e,info) kills=kills+1;e:OnKilled(info) end
local function kill(e)
    e.health=0
    local info=DamageInfo();info:SetAttacker(hero);info:SetInflictor(hero)
    e:OnKilled(info)
    local r=assert(e.LODRemainsReceipt,'canonical callback seals receipt')
    assert(not r.record,'no native mutations/claims in damage callback')
    at(time+.002);deaths:_RunDue()
    return r
end
local function burstPair()
    local e=pair('afterburst');deaths.Active={};deaths.Pending={};drops=0;kills=0
    return e,kill(e)
end
local function fire(r) service(r.ready+.01) end
local e,r=burstPair()
assert(r.record and r.corpseLife and e.nw.LOD_RemainsBurstUntil==r.deadline)
local hp=hero.health;fire(r)
assert(hero.hits==1 and hero.health<hp and receivedContext.physical and not receivedContext.melee,'corpse burst crosses real dice/GM/HP seam')
R:Burst(r,time);e:OnKilled(DamageInfo());assert(hero.hits==1 and kills==1 and drops==0,'one native defeat and one burst')
E:Damage(e,hero,{},'burst');assert(hero.hits==1,'ordinary damage rejects the dead source')
at(r.record.startedAt+1.002);deaths:_RunDue()
assert(drops==1 and not IsValid(e) and R.Count==0,'one ordinary deferred loot handoff with no extra body')
for _,case in ipairs({'range','cover','height','cell'}) do
    e,r=burstPair()
    if case=='range' then hero:SetPos(center()+Vector(140,0,0))
    elseif case=='height' then hero:SetPos(center()+Vector(60,0,80))
    elseif case=='cell' then hero:SetPos(N:CellCenter(s.Graph.Cells[key(4,3,0)]))
    else util.TraceLine=coverTrace end
    fire(r);assert(hero.hits==0,'burst answer '..case)
end
e,r=burstPair();service(r.deadline+.01);assert(hero.hits==0,'missed burst cannot catch up')
local mutations={
 sourceRemoval=function(e) e.valid=false end,sourceRevival=function(e) e.health=1 end,
 sourceLife=function(e) Status:ResetActorLife(e) end,sourceProgression=function(e) e.LODProgressionState=table.Copy(e.LODProgressionState) end,
 receipt=function(e) e.LODRemainsReceipt={} end,
 targetDeath=function() hero.health=0;hero.alive=false end,targetRemoval=function() hero.valid=false end,
 targetLife=function() Status:ResetActorLife(hero) end,targetProgression=function() hero.LODProgressionState=table.Copy(hero.LODProgressionState) end,
 run=function() LOD.RunManager.State=table.Copy(s) end,graph=function() s.Graph=table.Copy(s.Graph) end,
 progression=function() s.Graph.Progression=table.Copy(s.Graph.Progression) end,
 epoch=function() s.CampaignEpoch=s.CampaignEpoch+1 end,seed=function() s.LevelSeed=s.LevelSeed+1 end,
 campaignSeed=function() s.CampaignSeed=s.CampaignSeed+1 end,runId=function() s.RunId=s.RunId..'x' end,
 freeze=function() s.SimulationFrozen=true end,failure=function() s.Failed=true end,clear=function() s.LevelCleared=true end,
 support=function() util.TraceLine=function(t) return {Hit=false,HitPos=t.endpos} end end,
 displaced=function(e) e:SetPos(e:GetPos()+Vector(0,10,0)) end,
 objective=function() s.Graph.CellTags[key(3,3,0)]={objective=true} end,
 gate=function() s.Graph.Progression.Gates={{beforeCell=s.Graph.Cells[key(3,3,0)],afterCell=s.Graph.Cells[key(4,3,0)]}} end,
}
for name,mutate in pairs(mutations) do
    e,r=burstPair();mutate(e);fire(r);assert(hero.hits==0,'burst lifetime '..name)
end
print('BESTIARY_B8_BURST_PASS: actual lethal/deferred corpse path; one packet/reward; living gate preserved; finite escape/cover/support and exact lifetimes')

local function feedPair(id)
    local source=pair('carrion');deaths.Active={};deaths.Pending={};drops=0;kills=0
    source.health=source.maximum-50
    source:SetPos(center()+Vector(0,0,2));source.LODTarget=hero
    local body=actor(id or 'shambler');body:SetPos(center()+Vector(60,0,2));if E.Definitions[body.LODArchetypeId] then E:Prepare(body) end
    D.Entities={source,body};LOD.HostileRegistry.List=function() return D.Entities end
    local receipt=kill(body)
    return source,receipt,assert(R.Pending[source],'production death offers remains to injured Carrion')
end
local c,a
c,r,a=feedPair();hp=c.health;local targetHP=c.maximum
E:Tick(c);assert(c.LODMotionSpeed==0 and not c.LODRosterAttack,'feeding freezes ordinary AI')
service(a.ready+.01)
assert(r.consumed and r.source.hidden and c.health==math.min(targetHP,hp+math.min(30,math.ceil(targetHP*.2))),'one capped shared health grant')
assert(not R:Feed(c,a,time) and not R.Pending[c] and drops==0,'claim is final before callbacks and does not hand out loot')
at(r.record.startedAt+1.002);deaths:_RunDue();assert(drops==1,'consumption preserves normal loot timing')
c,r,a=feedPair('afterburst');service(a.ready+.01);fire(r)
assert(r.consumed and hero.hits==0,'consume volatile corpse before burst')
for name,mutate in pairs(mutations) do
    c,r,a=feedPair();local before=c.health
    -- source mutations here exercise the corpse; Carrion source cases below.
    mutate(r.source);service(a.ready+.01)
    assert(c.health==before and not r.consumed,'feeding corpse/Hero scope '..name)
end
for _,case in ipairs({'interrupt','sourceLife','sourceProgression','death','stun','morale','cover','drift','late','removed'}) do
    c,r,a=feedPair();hp=c.health
    if case=='interrupt' then E:Interrupt(c)
    elseif case=='sourceLife' then Status:ResetActorLife(c)
    elseif case=='sourceProgression' then c.LODProgressionState=table.Copy(c.LODProgressionState)
    elseif case=='death' then c.LODDead=true;c.health=0;hp=0
    elseif case=='stun' then c.LODHitStunUntil=time+5
    elseif case=='morale' then assert(Status:AttemptMorale(hero,c,{forceMorale=true,rng={Int=function(_,lo) return lo end}}))
    elseif case=='cover' then util.TraceLine=coverTrace
    elseif case=='drift' then c:SetPos(c:GetPos()+Vector(10,0,0))
    elseif case=='removed' then c.valid=false end
    service(a.ready+(case=='late' and .11 or .01))
    assert(c.health==hp and not r.consumed and not R.Pending[c],'feed interrupted '..case)
    R:Offer(r);assert(not R.Pending[c],'spent claim never recycled '..case)
end
for _,id in ipairs({'held','muted'}) do
    c,r,a=feedPair();hp=c.health;assert(Status:Apply(c,id,hero,{direct=true,duration=5}))
    service(a.ready+.01);assert(c.health>hp and r.consumed,'stationary physical feed allowed '..id)
end
-- Competing Carrions: exactly one proximity/ID-sorted claim, even on repeat Open/Offer.
c,r,a=feedPair();local other=actor('carrion');other:SetPos(c:GetPos());other.health=1;other.LODTarget=hero;E:Prepare(other)
D.Entities={other,c,r.source};R:Offer(r);R:Open(r.source,r.record)
assert(not R.Pending[other] and R.Pending[c]==a)
service(a.ready+.01);assert(other.health==1 and r.consumed)
print('BESTIARY_B8_FEED_PASS: event-driven single claims; ordinary AI hold; capped healing; consumption suppresses burst; exact lives; interruption/Held/Muted; loot unchanged')

-- Neither a bare death hook nor an unsealed presentation may mint a receipt.
e=pair('afterburst');e.health=0;e.LODDead=true
if env.hooks.LOD_RosterDeath then env.hooks.LOD_RosterDeath(e) end
e:_BeginDeathPresentation();assert(not e.LODRemainsReceipt)
-- Bound candidate scanning and gameplay corpses without body proliferation.
e=pair('afterburst');deaths.Active={};deaths.Pending={}
local list={};for i=1,129 do list[i]=actor('runner') end
LOD.HostileRegistry.List=function() return list end
local checked=0;local oldCan=R.CanFeed
R.CanFeed=function(self,...) checked=checked+1;return oldCan(self,...) end
r=kill(e);assert(checked==128,'fixed cached candidate work cap');R.CanFeed=oldCan
R.Active={};R.Count=0
for i=1,97 do local body=actor('shambler');body.health=0;body.LODDead=true;R:Seal(body) end
assert(R.Count==96,'receipt budget does not grow with corpse bursts')
-- A delayed presentation cannot restart an unseen warning after its sealed deadline.
e=pair('afterburst');e.health=0;e:OnKilled(DamageInfo());at(time+.2);deaths:_RunDue()
assert(R.Count==0 and not e.nw.LOD_RemainsBurstReady)
print('BESTIARY_B8_OWNERSHIP_PASS: bare hooks/cleanup cannot arm; 128 candidates/96 receipts; late presentation forfeits')

-- Ordinary attacks still work; the new identity is not only a death tag.
for _,id in ipairs({'afterburst','carrion'}) do
    local source,attack=begin(id);assert(attack.melee=='single' and source.nw.LOD_MeleeMode==4)
    assert(strike(source,attack)==1 and not source.LODRosterAttack,'ordinary physical fallback '..id)
end
local function extraHero()
    local p=actor('runner');p.player=true;p.LODHostile=false;p.hits=0;p.health=10000
    p:SetPos(center()+Vector(80,0,0));p.LODProgressionState=table.Copy(hero.LODProgressionState)
    p.GetActiveWeapon=hero.GetActiveWeapon;p.GetClass=hero.GetClass;p.Nick=hero.Nick
    p.GetNW2Bool=p.GetNW2Float;p.TakeDamageInfo=hero.TakeDamageInfo
    p.SteamID64=function() return 'b8-other-'..p.index end
    return p
end
for _,case in ipairs({'eligible','late join','revival','progression','disconnect'}) do
    e=pair('afterburst');deaths.Active={};deaths.Pending={}
    local other=extraHero();party=case=='late join' and {hero} or {hero,other}
    r=kill(e)
    if case=='late join' then party={hero,other}
    elseif case=='revival' then Status:ResetActorLife(other)
    elseif case=='progression' then other.LODProgressionState=table.Copy(other.LODProgressionState)
    elseif case=='disconnect' then other.valid=false end
    player.GetAll=function() error('no recurring global Hero search') end
    fire(r);assert(hero.hits==1 and other.hits==(case=='eligible' and 1 or 0),'captured warning admission '..case)
    player.GetAll=function() return party end
end
e=pair('afterburst');deaths.Active={};deaths.Pending={}
local other=extraHero();hero.health=1;party={hero,other};r=kill(e)
local rollCount=0;local realRoll=LOD.CombatRolls.RollHostileAttack
LOD.CombatRolls.RollHostileAttack=function(self,...) rollCount=rollCount+1;return realRoll(self,...) end
fire(r);LOD.CombatRolls.RollHostileAttack=realRoll
assert(hero.health==0 and other.hits==1 and rollCount==1,'one shared roll survives lethal first Hero without chaining onto allies')
print('BESTIARY_B8_PARTY_PASS: physical fallback; frozen participants; no revival/late join inheritance; one contract; lethal-first order independence')

-- Exercise real death -> XP hook -> corpse scheduler -> LootDirector handoff.
-- Only final reward spawning and native health/collision/entity methods are doubled.
LOD.RunManager.IsActivePlayer=function(_,p) return p==hero end
local Loot=LOD.LootDirector;local lootState={};local spawned=0;local xpAwards=0
Loot.TraceStage=noop;Loot._ObjectiveClearDrop=function() return false end
Loot._PlayerLootState=function() return lootState end
Loot._DropCategory=function() return 'ammo',false end
Loot._SpawnEnemyResult=function() spawned=spawned+1;return true end
local attribution=LOD.CombatAttributionSystem
C.AwardHeroXP=function(_,identity,amount) xpAwards=xpAwards+amount;return true end
hook.Run=function(event,source)
    if event=='OnNPCKilled' then attribution:Settle(source) end
end
local function realReward(consumed,change)
    e=pair('afterburst');deaths.Active={};deaths.Pending={};lootState={};spawned=0;xpAwards=0
    e._SpawnPlaceholderLoot=Native._SpawnPlaceholderLoot
    attribution.Ledgers[e]={effectiveDamageByHeroId={tester=100},killingBlowHeroId='tester'}
    r=kill(e);assert(xpAwards==e.LODRPGXPSettlement.value,'canonical death XP hook once')
    r.consumed=consumed
    if change then change(e) end
    at(r.record.startedAt+1.002);deaths:_RunDue()
    Loot:OnHostileLootHandoff(e);attribution:Settle(e)
    assert(xpAwards==e.LODRPGXPSettlement.value,'consumption never re-awards XP')
    return spawned
end
assert(realReward(false)==1 and realReward(true)==1,'ordinary and consumed corpses settle one identical loot roll')
for _,case in ipairs({'graph','progression','epoch','run','sourceProgression','sourceLife','sourceRevival'}) do
    assert(realReward(false,mutations[case])==0,'stale corpse cannot drop into replacement scope '..case)
end
-- Interruption and missing support retire gameplay only, preserving earned loot.
assert(realReward(false,function() R:Retire(r) end)==1,'retired warning keeps ordinary reward')
print('BESTIARY_B8_REWARD_PASS: actual native kill/XP and scheduled canonical loot; consumed/ordinary one settlement; same-seed and actor replacement guards')
