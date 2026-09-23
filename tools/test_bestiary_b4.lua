-- B4 exercises real Block, effective-hit ordering, reaction commitments and roster attacks.
-- Native entities, collision traces, motion transport and networking are doubles.
local env=dofile('tools/test_enemy_update.lua')
local root='gamemodes/legend_of_deborah/gamemode/lod/'
local noop=function() end
local v=getmetatable(Vector())
v.__div=function(a,b) return a*(1/b) end
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
dofile(root..'sv_enemy_roster.lua')
local E,D,C,Status,Rules=LOD.EnemyRoster,LOD.EncounterDirector,LOD.CharacterProgressionSystem,LOD.RPGStatusElements,LOD.RPGAbilityRules
local time,serial=200,100
local function at(n) time=n;env.setTime(n) end
at(time)
local s=LOD.RunManager.State
s.BuildReady=true;s.Failed=false;s.LevelCleared=false;s.SimulationFrozen=false;s.Level=8
s.CampaignEpoch=1;s.RunId='b4';s.CampaignSeed=77;s.LevelSeed=123
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
local function hit(source,context,effective)
    return R:ObserveHit(source,hero,context or {physical=true,attackEvent={}},effective or 1,time)
end

-- Native damage-object and health mutation are the Source boundary. The actual
-- GM mitigation, firearm hit-stun, post-damage reaction observer and cleanup run.
local weapon={valid=true,GetClass=function() return 'weapon_pistol' end}
hero.GetActiveWeapon=function() return weapon end
hero.GetClass=function() return 'player' end
hero.SteamID64=function() return 'b4-tester' end
hero.Nick=function() return 'B4 tester' end
hero.GetNW2Bool=hero.GetNW2Float
LOD.RunManager.IdentityOf=function(_,p) return p==hero and 'b4-tester' or nil end
local priorGetState=LOD.RunManager.GetPlayerState
LOD.RunManager.GetPlayerState=function(self,p)
    if p=='b4-tester' then return {progressionState=hero.LODProgressionState} end
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
local function info(attacker,damage,context)
    local d=LOD.NewDamageInfo();d:SetAttacker(attacker);d:SetInflictor(weapon);d:SetDamage(damage)
    Status:AttachDamageContext(d,context or {physical=true,attackEvent={}})
    return d
end
local function nativeHit(source,damage,context,taken)
    local d=info(hero,damage,context)
    GM:EntityTakeDamage(source,d)
    if taken~=false then source.health=math.max(0,source.health-d:GetDamage()) end
    env.hooks.LOD_EnemyReactionHit(source,d,taken~=false)
    GM:PostEntityTakeDamage(source,d,taken~=false)
    return d
end

local source=pair('pavise')
assert(R:BeginGuard(source,hero,time),'visible Hero starts self guard')
local guard=assert(source.LODReaction)
local facing=guard.yaw
assert(math.abs(guard.ready-time-.65)<1e-8,'full guard warning')
assert(R:GuardContribution(source,hero)==0,'warning grants no protection')
service(guard.ready)
assert(source.LODReaction==guard and guard.stage=='guard','shared service activates guard')
assert(math.abs(R:GuardContribution(source,hero)-.25)<1e-8,'frontal guard contributes canonical Block')
source.LODProgressionState.equipmentBlockChanceContribution=.2
assert(Rules:BlockChance(source,hero)==.33,'guard observes existing hard Block cap')
hero:SetPos(source:GetPos()+Vector(-160,0,0))
assert(R:GuardContribution(source,hero)==0 and Rules:BlockChance(source,hero)==.2,'rear remains exposed')
source:SetAngles(Angle(0,180,0))
assert(guard.yaw==facing and R:GuardContribution(source,hero)==0,'guard does not pivot to follow Hero')
hero:SetPos(source:GetPos()+Vector(80,140,0));assert(R:GuardContribution(source,hero)==0,'outside sixty-degree half-angle')
hero:SetPos(source:GetPos()+Vector(160,0,0))
local rolls=0;local oldRNG=LOD.CombatRolls._RNG
LOD.CombatRolls._RNG=function() return {Float=function() rolls=rolls+1;return .1 end} end
local event={};local damage=info(hero,10,{physical=true,attackEvent=event})
assert(Rules:ApplyBlock(source,damage) and damage:GetDamage()==0,'actual shared Block settles frontal physical hit')
damage=info(hero,10,{physical=true,attackEvent=event})
assert(Rules:ApplyBlock(source,damage) and rolls==1,'same attack rolls once')
damage=info(hero,10,{magic=true,attackEvent={}})
assert(not Rules:ApplyBlock(source,damage) and damage:GetDamage()==10 and rolls==1,'ordinary magic bypass remains')
LOD.CombatRolls._RNG=oldRNG
service(guard.expires)
assert(not source.LODReaction and R:GuardContribution(source,hero)==0,'finite self guard expires')
assert(not R:BeginGuard(source,hero,time),'guard recovery prevents immediate refresh')
print('BESTIARY_B4_GUARD_PASS: real capped Block; 0.65s warning; fixed exposed flank; duplicate event; magic bypass; duration/cooldown')

-- The native callback must capture final positive HP loss after triggering
-- firearm stun. No immediate damage, recursive observer or new private timer.
source=pair('repriser')
local before=source.health
nativeHit(source,1,{physical=true,attackEvent={}})
local reaction=assert(source.LODReaction,'effective native Hero shot queues retaliation')
assert(source.health==before-1 and (source.LODHitStunUntil or 0)>time and reaction.stage=='pending','queue survives its triggering shared hit-stun')
assert(not source.LODRosterAttack and #E.Projectiles==0,'post-damage callback never releases damage')
service(source.LODHitStunUntil-.001)
assert(not source.LODRosterAttack,'pending cannot bypass hit-stun')
service(source.LODHitStunUntil+.01)
local shot=assert(source.LODRosterAttack,'expired triggering stun starts real roster windup')
assert(math.abs(shot.ready-time-1)<1e-8 and shot.kind=='bullet','one-second physical retaliation warning')
local direction=shot.direction
hero:SetPos(hero:GetPos()+Vector(0,90,0))
service(shot.ready-.001);assert(#E.Projectiles==0,'cannot shoot early')
service(shot.ready+.001)
assert(shot.shotEmitted and #E.Projectiles==1,'one shared physical projectile')
local projectile=E.Projectiles[1]
assert(projectile.velocity:GetNormalized():DistToSqr(direction)<1e-12,'retaliation is frozen nonhoming aim')
service(shot.finish+.03)
assert(not source.LODRosterAttack,'shared finish retires attack')
assert(not hit(source),'retaliation cooldown prevents another charge')
print('BESTIARY_B4_REPRISER_PASS: native effective hit follows triggering stun; no immediate damage; shared warned release; nonhoming projectile; cooldown')

-- Finite queue and exact identity retirement, including failures while an
-- outer native AI wrapper is short-circuited by stun/freeze/death.
local reasons={'source_dead','source_removed','hero_dead','hero_removed','source_state','hero_state','source_life','hero_life',
    'graph','progression','state','campaign','seed','run_id','freeze','failed','cleared','expiry','held','intimidated','morale','new_stun','cover'}
for _,id in ipairs({'pavise','repriser','redliner'}) do
    for _,reason in ipairs(reasons) do
        source=pair(id)
        if id=='pavise' then assert(R:BeginGuard(source,hero,time))
        else
            if id=='redliner' then source.health=math.floor(source.maximum*.4) end
            assert(hit(source))
        end
        local a=source.LODReaction
        if reason=='source_dead' then source.LODDead=true
        elseif reason=='source_removed' then source.valid=false
        elseif reason=='hero_dead' then hero.alive=false
        elseif reason=='hero_removed' then hero.valid=false
        elseif reason=='source_state' then source.LODProgressionState=table.Copy(source.LODProgressionState)
        elseif reason=='hero_state' then hero.LODProgressionState=table.Copy(hero.LODProgressionState)
        elseif reason=='source_life' then Status:ResetActorLife(source)
        elseif reason=='hero_life' then Status:ResetActorLife(hero)
        elseif reason=='graph' then s.Graph=table.Copy(s.Graph)
        elseif reason=='progression' then s.Graph.Progression=table.Copy(s.Graph.Progression)
        elseif reason=='state' then local copy={};for k,v in pairs(s) do copy[k]=v end;LOD.RunManager.State=copy
        elseif reason=='campaign' then s.CampaignEpoch=s.CampaignEpoch+1
        elseif reason=='seed' then s.LevelSeed=s.LevelSeed+1
        elseif reason=='run_id' then s.RunId=s.RunId..'-replacement'
        elseif reason=='freeze' then s.SimulationFrozen=true
        elseif reason=='failed' then s.Failed=true
        elseif reason=='cleared' then s.LevelCleared=true
        elseif reason=='expiry' then at(a.expires)
        elseif reason=='new_stun' then source.LODHitStunUntil=time+5
        elseif reason=='cover' then util.TraceLine=function(t) return {Hit=true,HitPos=t.start} end
        elseif reason=='morale' then local applied,why=Status:AttemptMorale(hero,source,{forceMorale=true,rng={Int=function() return 1 end}});assert(applied and why=='flee')
        else assert(Status:Apply(source,reason,hero,{direct=true,duration=10})) end
        service(time)
        local current=R.Active[source]
        local guardCover=id=='pavise' and reason=='cover'
        assert(guardCover or not current or current.stage=='recovery',id..' retirement '..reason)
        assert(not source.LODRosterAttack and #E.Projectiles==0,id..' stale action cannot release '..reason)
        LOD.RunManager.State=s
    end
end

for _,flag in ipairs({'statusDamage','passiveDamage','reactiveDamage','auraBurst','environmental','wallCrush','equipmentContact','scriptedKill'}) do
    source=pair('repriser');local context={physical=true,attackEvent={},[flag]=true}
    nativeHit(source,1,context)
    assert(not source.LODReaction and #E.Projectiles==0,'native secondary damage must not arm '..flag)
end
source=pair('repriser');nativeHit(source,0);assert(not source.LODReaction,'zero effective damage cannot arm')
source=pair('repriser');nativeHit(source,1,nil,false);assert(not source.LODReaction,'rejected native damage cannot arm')
source=pair('repriser');nativeHit(source,source.health);assert(not source.LODReaction,'lethal native damage cannot arm')
source=pair('repriser');nativeHit(source,1);assert(source.LODReaction)
nativeHit(source,1);assert(not source.LODReaction,'second positive hit inside flinch debounce cancels reprisal')
source=pair('repriser');local d=info(hero,1,{physical=true,attackEvent={}})
GM:EntityTakeDamage(source,d);source.health=source.health-d:GetDamage()
env.hooks.LOD_EnemyReactionHit(source,d,true);local once=assert(source.LODReaction)
env.hooks.LOD_EnemyReactionHit(source,d,true)
assert(source.LODReaction==once,'duplicate native post callback cannot cancel or rearm')
GM:PostEntityTakeDamage(source,d,true)
assert(not R.Damage[d] and next(Status:DamageContext(d))==nil,'borrowed native damage state released')
print('BESTIARY_B4_LIFECYCLE_PASS: full cohort source/Hero/status-life and exact dungeon/run/campaign identity; same-seed replacement; freeze/death/disable/expiry; effective-only nonrecursive native observation; second hit and duplicate callback')

-- Redliner spends one wounded episode, may approach through existing routes,
-- then warns a fixed-direction dive and must visibly recover before fallback.
source=pair('redliner');source.health=math.floor(source.maximum*.4)
hero:SetPos(source:GetPos()+Vector(500,0,0));assert(hit(source))
service(time);reaction=assert(source.LODReaction)
assert(reaction.stage=='approach' and math.abs(reaction.expires-time-4)<1e-8,'bounded four-second gap closing')
local moves=0;local savedMove=LOD.HostileMotionV2.MoveToward
LOD.HostileMotionV2.MoveToward=function(_,e,wp) moves=moves+1;e.lastWaypoint=wp end
source._RefreshRoute=function(self) self.LODWaypoints={{pos=self:GetPos()+Vector(64,0,0)}};self.LODWaypointIndex=1 end
R:Tick(source,time);assert(moves==1 and not source.LODRosterAttack,'approach delegates existing graph motion')
source:SetPos(source:GetPos()+Vector(110,0,0));service(time+.01)
shot=assert(source.LODRosterAttack)
assert(shot.kind=='dive' and math.abs(shot.ready-time-1)<1e-8 and shot.range==400,'within 400 begins warned shared dive')
local origin=source:GetPos();direction=shot.direction
hero:SetPos(hero:GetPos()+Vector(0,140,0));service(shot.ready-.001)
assert(source:GetPos()==origin and not shot.released,'full dive warning allows sidestep')
util.DistanceToLine=function(a,b,p)
    local line=b-a;local n=line:LengthSqr();local t=n>0 and math.Clamp((p-a):Dot(line)/n,0,1) or 0
    return p:Distance(a+line*t)
end
service(shot.ready+.001);service(time+.025)
assert(shot.released and (source:GetPos()-origin):GetNormalized():Dot(Vector(direction.x,direction.y,0):GetNormalized())>.999,'dive direction stays fixed')
service(shot.finish+.01)
reaction=assert(source.LODReaction)
assert(reaction.stage=='recovery' and math.abs(reaction.expires-time-3)<1e-8,'three-second exposed recovery follows dive')
assert(source.LODRedlineSpent and not source.LODRosterAttack and not hit(source),'wounded episode cannot repeat')
service(reaction.expires)
assert(not source.LODReaction,'recovery expires')
assert(not hit(source),'remaining below threshold does not rearm')
source.health=math.ceil(source.maximum*.6);R:Tick(source,time)
assert(not source.LODRedlineSpent,'healing to sixty percent rearms one episode')
source.health=math.floor(source.maximum*.4);assert(hit(source),'new healed-then-wounded episode may trigger')
LOD.HostileMotionV2.MoveToward=savedMove
source=pair('redliner');source.health=math.floor(source.maximum*.4);hero:SetPos(source:GetPos()+Vector(500,0,0));assert(hit(source));service(time)
reaction=source.LODReaction;service(reaction.expires)
assert(source.LODReaction.stage=='recovery' and not source.LODRosterAttack,'failed gap closure expires into recovery without remote dive')
source=pair('redliner');source.LODNextAttack=0;E:Tick(source)
shot=assert(source.LODRosterAttack)
assert(shot.kind=='bullet' and not R.Active[source],'healthy Redliner retains ordinary ranged fallback')
print('BESTIARY_B4_REDLINER_PASS: 40/60 hysteresis; existing-route pursuit bounded at four seconds; 400-unit warned nonhoming shared dive; finite recovery; no repeated wounded episode; ordinary ranged fallback')

-- Drive a real shared projectile collision into the ordinary damage authority.
-- Only Source's tracing and engine health application are doubled.
local received,receivedContext=0,nil
function hero:TakeDamageInfo(d)
    received=received+1;receivedContext=Status:DamageContext(d,self)
    GM:EntityTakeDamage(self,d);self.health=math.max(0,self.health-d:GetDamage())
    env.hooks.LOD_EnemyReactionHit(self,d,true);GM:PostEntityTakeDamage(self,d,true)
end
function EffectData() return {SetOrigin=noop} end
util.Effect=noop
source=pair('repriser');assert(hit(source));service(time)
shot=assert(source.LODRosterAttack);service(shot.ready+.01)
local targetHP=hero.health;received=0
util.TraceHull=function(t) return {Hit=true,Entity=hero,HitPos=t.endpos} end
service(time+.03)
assert(#E.Projectiles==0 and received==1 and hero.health<targetHP,'shared projectile collision commits exactly one native HP settlement')
assert(receivedContext.physical and not receivedContext.magic and receivedContext.damageContract and receivedContext.attackEvent,'projectile uses existing physical roll/mitigation contract')
service(time+.03);assert(received==1,'retired projectile cannot deal a repeated hit')

for _,id in ipairs({'pavise','repriser','redliner'}) do
    source=pair(id);source.LODNextGuard=time+100;E:Begin(source,hero,time)
    shot=assert(source.LODRosterAttack)
    assert(shot.reactionRecord,'all cohort ordinary attacks carry exact actor identity')
    Status:ResetActorLife(hero);service(shot.ready+.01)
    assert(not source.LODRosterAttack and #E.Projectiles==0,'ordinary attack cannot cross Hero life '..id)
end
for _,reason in ipairs({'source_life','hero_life','source_state','hero_state','graph','progression','state','epoch','run','expiry','freeze'}) do
    source=pair('repriser');assert(hit(source));service(time);shot=source.LODRosterAttack;service(shot.ready+.01)
    projectile=assert(E.Projectiles[1]);local expiry=projectile.expires
    if reason=='source_life' then Status:ResetActorLife(source)
    elseif reason=='hero_life' then Status:ResetActorLife(hero)
    elseif reason=='source_state' then source.LODProgressionState=table.Copy(source.LODProgressionState)
    elseif reason=='hero_state' then hero.LODProgressionState=table.Copy(hero.LODProgressionState)
    elseif reason=='graph' then s.Graph=table.Copy(s.Graph)
    elseif reason=='progression' then s.Graph.Progression=table.Copy(s.Graph.Progression)
    elseif reason=='state' then local copy={};for k,v in pairs(s) do copy[k]=v end;LOD.RunManager.State=copy
    elseif reason=='epoch' then s.CampaignEpoch=s.CampaignEpoch+1
    elseif reason=='run' then s.RunId=s.RunId..'-next'
    elseif reason=='expiry' then at(expiry)
    elseif reason=='freeze' then s.SimulationFrozen=true end
    service(time+.03);assert(#E.Projectiles==0,'already emitted projectile retires '..reason)
    LOD.RunManager.State=s
end
source=pair('repriser');assert(hit(source));service(time);shot=source.LODRosterAttack;service(shot.ready+.01)
projectile=E.Projectiles[1];source.LODHitStunUntil=time+5;service(time+.03)
assert(E.Projectiles[1]==projectile,'ordinary post-release hit-stun does not recall emitted shot')
source=pair('repriser');assert(hit(source));service(time);shot=source.LODRosterAttack
for i=1,64 do E.Projectiles[i]={} end
at(shot.ready);E:Release(source,shot,time)
assert(not shot.shotEmitted and #E.Projectiles==64,'shared projectile ceiling refuses overflow without private fallback damage')
E.Projectiles={}
-- Service visits exactly committed reactions; no scan of all entities or Heroes.
source=pair('repriser');assert(hit(source))
local oldFind,oldAll,oldRandom=ents.FindByClass,player.GetAll,math.random
ents.FindByClass=function() error('reaction service may not discover the world') end
player.GetAll=function() error('reaction service may not rescan Heroes') end
math.random=function() error('reaction scheduler may not consume global RNG') end
R:Service(time,true)
ents.FindByClass,player.GetAll,math.random=oldFind,oldAll,oldRandom
assert(source.LODRosterAttack,'finite active registry advances without world discovery or random consumption')
print('BESTIARY_B4_PIPELINE_PASS: actual shared projectile -> physical combat roll/contract -> GM mitigation -> native HP once; exact emitted projectile life/reset/expiry; ordinary attack scopes; 64-projectile ceiling; finite scheduler without world scan/global RNG')

-- Dive collisions use the same damage authority as bullets and can strike a
-- given Hero only once during the entire 0.65-second committed movement.
source=pair('redliner');source.health=math.floor(source.maximum*.4)
assert(hit(source));service(time);shot=source.LODRosterAttack;received=0
local diveHP=hero.health
service(shot.ready+.001)
while source.LODRosterAttack do service(time+.025) end
assert(received==1 and hero.health<diveHP and shot.hit[hero],'shared dive applies one actual native HP settlement')
assert(receivedContext.physical and receivedContext.melee and not receivedContext.magic,'dive retains canonical physical melee contract')
reaction=assert(source.LODReaction);local recoveryEnd=reaction.expires
E:Interrupt(source)
assert(source.LODReaction==reaction and reaction.expires==recoveryEnd,'interruption preserves exact recovery deadline')
nativeHit(source,1,{physical=true,attackEvent={},moraleIneligible=true})
assert(source.LODReaction==reaction and reaction.expires==recoveryEnd,'recovery damage neither shortens nor extends movement lock')
service(recoveryEnd-.001);assert(source.LODReaction==reaction,'recovery lasts its full duration')
service(recoveryEnd);assert(not source.LODReaction,'recovery releases exactly at deadline')
source.health=math.ceil(source.maximum*.6)
nativeHit(source,source.health-math.floor(source.maximum*.39),{physical=true,attackEvent={},moraleIneligible=true})
assert(source.LODReaction,'healing and recrossing threshold between AI ticks rearms episode')

source=pair('pavise');assert(R:BeginGuard(source,hero,time));guard=source.LODReaction;service(guard.ready)
local front=source:GetPos()+Vector(160,0,0)
hero:SetPos(source:GetPos()+Vector(-160,0,0))
local committed={equipmentSnapshot={origin=front}}
assert(R:GuardContribution(source,hero,info(hero,10,committed))==.25,'guard reads committed incoming origin after shooter moves behind it')
hero:SetPos(front)
assert(R:GuardContribution(source,hero,info(hero,10,{damageContract={sourcePosition=source:GetPos()+Vector(-160,0,0)}}))==0,'rear committed shot remains flank damage after shooter moves forward')
source.LODProgressionState.equipmentBlockChanceContribution=.2
rolls=0;oldRNG=LOD.CombatRolls._RNG
LOD.CombatRolls._RNG=function() return {Float=function() rolls=rolls+1;return rolls==1 and .1 or .9 end} end
event={};damage=info(hero,10,{physical=true,attackEvent=event});assert(Rules:ApplyBlock(source,damage))
Status:ResetActorLife(source)
damage=info(hero,10,{physical=true,attackEvent=event})
assert(not Rules:ApplyBlock(source,damage) and rolls==2,'Block cache cannot carry success into another status life')
s.Graph=table.Copy(s.Graph)
damage=info(hero,10,{physical=true,attackEvent=event})
assert(not Rules:ApplyBlock(source,damage) and rolls==3,'Block cache cannot carry result into same-seed graph replacement')
LOD.CombatRolls._RNG=oldRNG
print('BESTIARY_B4_DAMAGE_ORDER_PASS: inherited dive real HP once; exact recovery under repeated interruption/damage; between-tick healed episode; committed incoming guard origin; Block cache life and same-seed replacement')

-- Shotgun aggregates damage before its production four-times flinch callback. Preserve only
-- that triggering attack's own late stun, never an unrelated later hit.
dofile(root..'sv_shotgun_identity_balance.lua')
for _,id in ipairs({'repriser','redliner'}) do
    source=pair(id)
    if id=='redliner' then source.health=math.floor(source.maximum*.4) end
    local shell={attackEvent={},hits={[source]=1},damageByTarget={[source]=1},values={1},formula='1d6!',pellets=6}
    nativeHit(source,1,{physical=true,settledShotgun=true,attackEvent=shell.attackEvent,moraleIneligible=true})
    reaction=assert(source.LODReaction,'settled shell actual HP arms '..id)
    local pendingDeadline=reaction.expires
    assert(not source.LODHitStunUntil,'settled shotgun defers its flinch to aggregate feed')
    LOD.CombatRolls:_FinishShotgunFeed(hero,shell)
    assert(source.LODReaction==reaction and reaction.triggerStun==source.LODHitStunUntil and reaction.expires==pendingDeadline,'own late shell stun preserves only initial finite queue '..id)
    local expected=.3*math.Clamp(4*Rules:HitStunMultiplier(hero,source),.5,4)
    assert(math.abs(source.LODHitStunUntil-time-expected)<1e-8,'accepted production four-times final stun adopted '..id)
    service(source.LODHitStunUntil-.001);assert(not source.LODRosterAttack,'late shell stun cannot be bypassed '..id)
    service(source.LODHitStunUntil+.01);assert(source.LODRosterAttack,'reaction starts after its own late shell stun '..id)
    source.LODNextHitStun=0
    LOD.M3HitFeedback:ApplyShotgunShellStun(source,hero,{})
    assert(not source.LODRosterAttack and (not source.LODReaction or source.LODReaction.stage=='recovery'),'different shell cancels '..id)
end
print('BESTIARY_B4_SHOTGUN_ORDER_PASS: actual native HP settlement then real aggregate feed and production four-times stun override; exact triggering attack preserved without extending queue; later different shell interrupts')

-- Actual Wall Form damage owns a post-health stun. Its cast context must reach
-- the same pending reaction without creating an extra interruption event.
unpack=table.unpack
dofile(root..'sv_magic_progression.lua')
LOD.Magic.Stats={};LOD.Magic._EnsureState=function() return nil end
dofile(root..'sv_magic_forms.lua')
source=pair('repriser');source.TakeDamageInfo=hero.TakeDamageInfo
local cast={damageDiceUsed=0,castSerial=901}
local magicHP=source.health
assert(LOD.MagicForms:_ApplyDamage(hero,hero,source,LOD.RPG.MagicForms.wall,nil,cast,Vector(1,0,0)))
reaction=assert(source.LODReaction,'actual Wall damage plus its late stun preserves pending reaction')
assert(source.health<magicHP and reaction.triggerEvent==cast and reaction.triggerStun==source.LODHitStunUntil,'actual Wall preserves exact cast identity and final post-health stun')
service(source.LODHitStunUntil+.01)
assert(source.LODRosterAttack,'Wall-triggered reaction waits then enters existing warned attack')

-- Crowbar's real PrimaryAttack similarly settles damage before applying melee
-- flinch. Only native weapon/lag-compensation/trace methods are doubled.
SWEP={Primary={},Secondary={}};CLIENT=false;SERVER=true
function IsFirstTimePredicted() return true end
hero.GetShootPos=function(self) return self:WorldSpaceCenter() end
hero.GetAimVector=function() return Vector(-1,0,0) end
hero.SetAnimation=noop;hero.LagCompensation=noop
local crowbarFile='gamemodes/legend_of_deborah/entities/weapons/weapon_lod_crowbar/shared.lua'
dofile(crowbarFile)
local crowbar=setmetatable({valid=true},{__index=SWEP})
crowbar.GetOwner=function() return hero end
crowbar.GetClass=function() return 'weapon_lod_crowbar' end
crowbar.SetNextPrimaryFire=noop;crowbar.SendWeaponAnim=noop;crowbar.EmitSound=noop
hero.GetActiveWeapon=function() return crowbar end
source=pair('repriser');source.TakeDamageInfo=hero.TakeDamageInfo
util.TraceHull=function(t) return {Hit=true,Entity=source,HitPos=source:WorldSpaceCenter()} end
local meleeHP=source.health
crowbar:PrimaryAttack()
reaction=assert(source.LODReaction,'actual crowbar HP plus late melee stun preserves pending reaction')
assert(source.health<meleeHP and reaction.triggerEvent==receivedContext.attackEvent and reaction.triggerStun==source.LODHitStunUntil,'actual crowbar preserves exact attack identity and post-health stun')
service(source.LODHitStunUntil+.01)
assert(source.LODRosterAttack,'crowbar-triggered reaction waits then enters warned attack')
print('BESTIARY_B4_MAGIC_MELEE_ORDER_PASS: actual Wall Form and Crowbar PrimaryAttack native HP then late shared stun; exact triggering cast/attack preserved; delayed warned response')
