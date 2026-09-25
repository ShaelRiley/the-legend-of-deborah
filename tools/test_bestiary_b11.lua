-- B11 exercises mobile commitments through the real roster service, combat and status pipeline.
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
dofile(root..'sv_enemy_roster.lua');dofile(root..'sv_enemy_melee.lua');dofile(root..'sv_faction_manager.lua');dofile(root..'sv_enemy_perception.lua');dofile(root..'sv_hostile_motion_v2.lua')
local E,D,C,Status,Rules=LOD.EnemyRoster,LOD.EncounterDirector,LOD.CharacterProgressionSystem,LOD.RPGStatusElements,LOD.RPGAbilityRules
local time,serial=200,100
local function at(n) time=n;env.setTime(n) end
at(time)
local s=LOD.RunManager.State
s.BuildReady=true;s.Failed=false;s.LevelCleared=false;s.SimulationFrozen=false;s.Level=8
s.CampaignEpoch=1;s.RunId='b11';s.CampaignSeed=77;s.LevelSeed=123
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
hero.SteamID64=function() return 'b11-tester' end
hero.Nick=function() return 'B11 tester' end
hero.GetNW2Bool=hero.GetNW2Float
LOD.RunManager.IdentityOf=function(_,p) return p==hero and 'b11-tester' or nil end
local priorGetState=LOD.RunManager.GetPlayerState
LOD.RunManager.GetPlayerState=function(self,p)
    if p=='b11-tester' then return {progressionState=hero.LODProgressionState} end
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
    p.SteamID64=function() return 'b11-other-'..p.index end
    return p
end
LOD.RunManager.IsActivePlayer=function(_,p) return p.player and not p.spectator end
local F=LOD.FactionManager
LOD.RPGPerceptionState={IsInvisible=function(_,p) return p.invisible==true end}
hero.Crouching=function(self) return self.crouched==true end
local oldPair=pair
pair=function(id)
    local e=oldPair(id)
    F.Footsteps=setmetatable({}, {__mode='k'});F.NextPerceptionHeroes=0;F.PerceptionHeroCache=nil
    hero.invisible=false;hero.crouched=false
    return e
end
local function step(p,volume)
    env.hooks.LOD_BestiaryFootstepReceipt(p or hero,(p or hero):GetPos(),0,'step',volume or 1)
end
local function soundBegin(setup)
    local e=pair('listener');hero:SetPos(center()+Vector(160,0,0))
    if setup then setup(e) end
    step();E:Tick(e)
    return e,assert(e.LODRosterAttack,'Listener starts from real footstep hook')
end
local function sightBegin(setup)
    local e=pair('shy');hero:SetPos(center()+Vector(160,0,0));E:Tick(e)
    assert(e.LODPerceptionMemory and not e.LODRosterAttack,'sight memory, no approach while visible')
    util.TraceLine=coverTrace
    if setup then setup(e) end
    at(time+.11);E:Tick(e)
    return e,assert(e.LODRosterAttack,'Shy starts after LOS break')
end
local e=pair('listener');local origin=e:GetPos()
for i=1,5 do at(time+.2);E:Tick(e) end
assert(not e.LODRosterAttack and e:GetPos():Distance(origin)==0,'silent Hero never triggers ordinary omniscient pursuit')
hero.crouched=true;step();assert(not next(F.Footsteps),'crouch suppresses hearing');hero.crouched=false
F:RecordFootstep(hero,hero:GetPos(),0);assert(not next(F.Footsteps),'silent footstep ignored')
hero.invisible=true;step();assert(not next(F.Footsteps),'invisibility excludes signal');hero.invisible=false
step();local r=assert(F.Footsteps[hero]);local snapshot=Vector(r.position.x,r.position.y,r.position.z)
hero:SetPos(center()+Vector(160,30,0));step();assert(F.Footsteps[hero]==r,'event coalescing')
assert(r.position:Distance(snapshot)==0,'snapshot owns its vector')
assert(F:BestTarget(e,s.Graph,s.Graph.Cells[key(3,3,0)])==hero,'shared targeting uses sensory receipt')
at(r.expires);assert(not F:BestTarget(e,s.Graph,nil),'expired hearing cannot target')
local a;e,a=soundBegin()
assert(a.perception=='sound' and math.abs(a.start:Distance(a.goal)-128)<.001)
assert(a.ready==time+.8 and a.expires==time+2.2,'fixed warning and investigation deadline')
local goal=a.goal;hero:SetPos(center()+Vector(-150,100,0))
advance(e,a.ready-.01);assert(e:GetPos():Distance(a.start)==0 and hero.hits==0,'harmless stationary warning')
advance(e,a.expires)
assert(e:GetPos():Distance(goal)<.1 and not e.LODRosterAttack and hero.hits==0,'actual MotionV2 reaches sound snapshot without damage or tracking')
local recovery=e.LODMeleeRecovery.expires;E:Interrupt(e);assert(e.LODMeleeRecovery.expires==recovery,'nonextending recovery')
at(recovery+.01);E:Tick(e);assert(not e.LODRosterAttack,'consumed receipt cannot start a second investigation')
-- Fresh close hearing enters the existing fully warned melee/combat path.
e=pair('listener');step();E:Tick(e);a=assert(e.LODRosterAttack)
assert(a.melee=='single' and not a.perception and e.nw.LOD_PerceptionMode==0)
advance(e,a.ready-.01);assert(hero.hits==0)
advance(e,a.ready+.025);assert(hero.hits==1 and hero.health<10000 and receivedContext.physical and receivedContext.melee,'canonical physical dice/damage/GM mitigation/HP boundary')
-- A quiet close Hero remains safe from Listener; Shy can strike a visible close Hero.
e=pair('shy');E:Tick(e);a=assert(e.LODRosterAttack);assert(a.melee=='single')
hero:SetPos(center()+Vector(-90,0,0));advance(e,a.ready+.025);assert(hero.hits==0,'fixed melee sector can be escaped')
e,a=sightBegin();local fixed=a.goal
hero:SetPos(center()+Vector(-160,-100,0));advance(e,a.expires)
assert(e:GetPos():Distance(fixed)<.1 and hero.hits==0,'occluded advance never follows hidden movement or damages')
e,a=sightBegin();advance(e,a.ready+.15);util.TraceLine=clearTrace;advance(e,time+.11)
assert(not e.LODRosterAttack and e.LODMeleeRecovery,'renewed ordinary LOS cancels movement')
e=pair('shy');hero:SetPos(center()+Vector(160,0,0));E:Tick(e)
local friend=extraHero(center()+Vector(-150,0,0));party={hero,friend};at(time+.11)
util.TraceLine=function(t)
    local floor=clearTrace(t);if floor.Hit then return floor end
    return {Hit=t.endpos.x>center().x,HitPos=t.endpos,Entity=NULL}
end
E:Tick(e);assert(not e.LODRosterAttack,'second Hero visibility prevents unseen advance')
-- Witness eligibility is geometric and independent of camera facing.
friend.GetAimVector=function() error('camera must never be read') end
assert(F:Witnesses(e,s.Graph,time))
friend.invisible=true;assert(not F:Witnesses(e,s.Graph,time),'concealed Hero cannot be used as an AI witness')
-- Exact source/target/run life retirement at warning and movement, using shared identities.
local mutations={
 function(e) e.valid=false end,
 function(e) e.LODDead=true end,
 function(e) e.health=0 end,
 function(e) e.LODActivated=false end,
 function(e) e.LODProgressionState=table.Copy(e.LODProgressionState) end,
 function(e) Status:ResetActorLife(e) end,
 function() hero.valid=false end,
 function() hero.alive=false end,
 function() hero.invisible=true end,
 function() hero.LODProgressionState=table.Copy(hero.LODProgressionState) end,
 function() Status:ResetActorLife(hero) end,
 function() s.Graph=table.Copy(s.Graph) end,
 function() s.Graph.Progression=table.Copy(s.Graph.Progression) end,
 function() s.CampaignEpoch=s.CampaignEpoch+1 end,
 function() s.CampaignSeed=s.CampaignSeed+1 end,
 function() s.LevelSeed=s.LevelSeed+1 end,
 function() s.RunId=s.RunId..'x' end,
 function() s.SimulationFrozen=true end,
 function() s.Failed=true end,
 function() s.LevelCleared=true end,
 function() s.BuildReady=false end,
 function() LOD.RunManager.State=table.Copy(s) end,
 function(e) e.LODHitStunUntil=time+1 end,
 function(e) e:SetPos(e:GetPos()+Vector(0,8,0)) end,
}
for _,start in ipairs({soundBegin,sightBegin}) do
 for _,released in ipairs({false,true}) do
  for index,mutate in ipairs(mutations) do
   e,a=start();if released then advance(e,a.ready+.1) end
   local pos=e:GetPos();mutate(e);service(time+.11)
   assert(not IsValid(e) or not e.LODRosterAttack,'stale perception retired '..index)
   assert(hero.hits==0,'investigation never settles damage')
  end
 end
end
-- Held and morale cancel even after release; Muted permits physical hearing/actions.
for _,id in ipairs({'held','morale_flee'}) do
 e,a=soundBegin();advance(e,a.ready+.05)
 if id=='morale_flee' then assert(Status:AttemptMorale(hero,e,{forceMorale=true,rng={Int=function(_,lo) return lo end}}))
 else assert(Status:Apply(e,id,hero,{direct=true,duration=2})) end;service(time+.025);assert(not e.LODRosterAttack,id..' retires perception motion')
end
e=pair('listener');Status:Apply(e,'muted',hero,{direct=true,duration=2});step();E:Tick(e);assert(e.LODRosterAttack,'Muted allows physical hearing/melee')
-- Geometry: full scaled native hull, route support (including interior gaps),
-- objective cells, changed gates/Walls, displacement, and missing floor.
for _,start in ipairs({soundBegin,sightBegin}) do
 e,a=start();util.TraceHull=function(t) return {Hit=true,HitPos=t.endpos} end
 service(time+.025);assert(not e.LODRosterAttack,'new solid geometry retires movement')
 e,a=start();local midpoint=a.start+(a.goal-a.start)*.5
 util.TraceLine=function(t)
    local tr=clearTrace(t)
    if tr.Hit and math.abs(t.start.x-midpoint.x)<13 then return {Hit=false,HitPos=t.endpos} end
    if start==sightBegin and not tr.Hit then return {Hit=true,HitPos=t.endpos,Entity=NULL} end
    return tr
 end
 service(time+.025);assert(not e.LODRosterAttack,'interior support gap retires movement')
 e,a=start();s.Graph.CellTags[key(3,3,0)]={objective=true}
 service(time+.025);assert(not e.LODRosterAttack,'changed objective cell retires movement')
 e,a=start();service(a.ready+.21);assert(not e.LODRosterAttack and hero.hits==0,'missed warning never catches up')
 e,a=start();advance(e,a.ready+.05);local pos=e:GetPos();service(time+.21)
 assert(not e.LODRosterAttack and e:GetPos():Distance(pos)==0,'stalled service forfeits motion')
end
-- Receipts are never inherited across activation/life/scope and memory retires on interruption.
e=pair('listener');step();r=F.Footsteps[hero];Status:ResetActorLife(hero)
assert(not F:HeardFootstep(e,s.Graph),'revival cannot inherit hearing')
e=pair('listener');step();r=F.Footsteps[hero];at(time+.01);local late=actor('listener');E:Prepare(late)
assert(not F:HeardFootstep(late,s.Graph),'activation cannot hear a past footstep')
e=pair('shy');hero:SetPos(center()+Vector(160,0,0));E:Tick(e);assert(e.LODPerceptionMemory)
E:Interrupt(e);assert(not e.LODPerceptionMemory,'source interruption forgets sight memory')
e=pair('shy');hero:SetPos(center()+Vector(160,0,0));E:Tick(e);E:ForgetPerception(e,hero)
assert(not e.LODPerceptionMemory,'canonical invisibility forget hook discards memory')
e,a=soundBegin();E:ForgetPerception(e,hero);assert(not e.LODRosterAttack,'instant cloak forget cancels investigation')
-- Bounded active commitments, signals and scanning.
e=pair('listener');hero:SetPos(center()+Vector(160,0,0));step()
for i=1,16 do local other=actor('listener');other.LODRosterAttack={perception='sound'};E.Active[other]=true;D.Entities[#D.Entities+1]=other end
E:Tick(e);assert(not e.LODRosterAttack,'16 global investigations maximum')
e=pair('listener')
for i=1,40 do local p=extraHero();p.Crouching=hero.Crouching;party[#party+1]=p;step(p) end
local count=0;for _ in pairs(F.Footsteps) do count=count+1 end;assert(count==32,'32 bounded hearing receipts')
party={};for i=1,33 do party[i]=extraHero() end;F.NextPerceptionHeroes=0
assert(F:Witnesses(e,s.Graph,time),'oversized party fails closed instead of unseen motion')
print('BESTIARY_B11_PASS: real footstep event/FactionManager acquisition, quiet/crouch/invisible denial, frozen receipts, co-op sight/no-camera rule, real MotionV2 harmless investigations, separate canonical melee, exact lifecycle matrix, finite service/recovery, interruption, full geometry/support and work caps')
-- Cross the actual canonical cloak-forget seam (not just the cohort helper).
dofile(root..'sv_rpg_checkpoint_d_sixth_sense_feat.lua')
LOD.HostileRegistry={List=function() return D.Entities end}
e,a=soundBegin();local perception=LOD.RPGPerceptionState
perception:SetInvisibleSource(hero,'b11-test',{ends=time+1})
perception:ForgetHostileTarget(hero)
assert(not F.Footsteps[hero] and not e.LODRosterAttack and not F:CanAcquirePlayerTarget(hero),'canonical concealment erases sound and active intent immediately')
perception:ClearInvisibleSource(hero,'b11-test',perception.InvisibleSources[hero]['b11-test'])
e=pair('shy');hero:SetPos(center()+Vector(160,0,0));E:Tick(e);assert(e.LODPerceptionMemory)
perception:ForgetHostileTarget(hero);assert(not e.LODPerceptionMemory,'canonical forget reaches cached sight')
print('BESTIARY_B11_CLOAK_PASS: real shared invisibility source and forget dispatch')

-- Perception retirement leaves voluntary morale locomotion to its existing owner.
e=pair('shy');hero:SetPos(center()+Vector(160,0,0));E:Tick(e);assert(e.LODPerceptionMemory)
assert(Status:AttemptMorale(hero,e,{forceMorale=true,rng={Int=function(_,lo) return lo end}}))
local priorFlee=Status.HandleAIFlee;local fleeCalls=0
Status.HandleAIFlee=function(self,actor,graph,motion) fleeCalls=fleeCalls+1;return priorFlee(self,actor,graph,motion) end
E:Tick(e);assert(fleeCalls==1 and not e.LODPerceptionMemory,'morale reaches canonical flee handler after forgetting observation')
Status.HandleAIFlee=priorFlee
print('BESTIARY_B11_MORALE_PASS: preserved canonical flee dispatch')

-- B27: sensory actors may patrol without a target; that route is ambient, not
-- knowledge of hidden Hero coordinates. Witnesses, cues and recovery still win.
local nativeMove=LOD.HostileMotionV2.MoveToward
for _,id in ipairs({'listener','shy'}) do
    local e=pair(id);e.LODWanderer=true;e.LODTarget=nil
    party={};LOD.FactionManager.PerceptionHeroCache={};LOD.FactionManager.NextPerceptionHeroes=0
    LOD.FactionManager.Footsteps={}
    local moved=0;local wp={pos=e:GetPos()+Vector(48,0,0)}
    e._RefreshRoute=function(self,graph) assert(graph==s.Graph);self.LODWaypoints={wp};self.LODWaypointIndex=1 end
    LOD.HostileMotionV2.MoveToward=function(_,actor,waypoint) assert(actor==e and waypoint==wp);moved=moved+1 end
    E:Tick(e);assert(moved==1 and not e.LODTarget and not e.LODRosterAttack,'idle sensory patrol '..id)
    at(time+.05);E:Tick(e);assert(moved==2,'poll cadence stopped ambient locomotion')
    e.LODNextAttack=time+1;E:Tick(e);assert(moved==2,'patrol skipped recovery');e.LODNextAttack=0
    if id=='shy' then
        party={hero};LOD.FactionManager.NextPerceptionHeroes=0
        E:Tick(e);assert(moved==2,'Shy wandered while witnessed between sensory polls')
    end
    e.LODWanderer=false;E:Tick(e);assert(moved==2,'authored sensory actor gained ambient roaming')
end
LOD.HostileMotionV2.MoveToward=nativeMove
print('BESTIARY_B27_SENSORY_PATROL_PASS: actual no-cue patrol dispatch and poll continuity; Shy witness stop, recovery and encounter-only rules retained')
