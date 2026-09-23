-- B5 exercises real Block, effective-hit ordering, reaction commitments and roster attacks.
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
dofile(root..'sv_enemy_roster.lua');dofile(root..'sv_enemy_patterns.lua')
local E,D,C,Status,Rules=LOD.EnemyRoster,LOD.EncounterDirector,LOD.CharacterProgressionSystem,LOD.RPGStatusElements,LOD.RPGAbilityRules
local time,serial=200,100
local function at(n) time=n;env.setTime(n) end
at(time)
local s=LOD.RunManager.State
s.BuildReady=true;s.Failed=false;s.LevelCleared=false;s.SimulationFrozen=false;s.Level=8
s.CampaignEpoch=1;s.RunId='b5';s.CampaignSeed=77;s.LevelSeed=123
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
hero.SteamID64=function() return 'b5-tester' end
hero.Nick=function() return 'B5 tester' end
hero.GetNW2Bool=hero.GetNW2Float
LOD.RunManager.IdentityOf=function(_,p) return p==hero and 'b5-tester' or nil end
local priorGetState=LOD.RunManager.GetPlayerState
LOD.RunManager.GetPlayerState=function(self,p)
    if p=='b5-tester' then return {progressionState=hero.LODProgressionState} end
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
local function launch(id,setup)
    local e=pair(id)
    if setup then setup(e) end
    E:Tick(e)
    local a=assert(e.LODRosterAttack,'actual AI dispatch commits '..id)
    service(a.ready-.01);assert(not a.released,'complete warning '..id)
    service(a.ready+.01)
    assert(a.shotEmitted and a.patternLife,'actual roster release '..id)
    return e,a
end
local function steps(n) for i=1,n do service(time+.025) end end
-- Native swept geometry double: exact planar wall + swept Hero AABB.
-- Game planning, motion, damage and service code run unchanged.
local wall,wallX,withHero,traceCount=nil,nil,false,0
local function geometry(t)
    traceCount=traceCount+1
    local delta=t.endpos-t.start;local best=1;local entity,normal
    if wallX and delta.x>0 and t.start.x<=wallX-2 and t.endpos.x>=wallX-2 then
        best=(wallX-2-t.start.x)/delta.x;entity=wall;normal=Vector(-1,0,0)
    end
    if withHero and t.filter(hero) then
        local c=hero:WorldSpaceCenter();local lo=c-Vector(18,18,38);local hi=c+Vector(18,18,38)
        local enter,leave=0,1
        for _,axis in ipairs({'x','y','z'}) do
            local d=delta[axis]
            if math.abs(d)<1e-9 then
                if t.start[axis]<lo[axis] or t.start[axis]>hi[axis] then enter=2 end
            else
                local a,b=(lo[axis]-t.start[axis])/d,(hi[axis]-t.start[axis])/d
                enter=math.max(enter,math.min(a,b));leave=math.min(leave,math.max(a,b))
            end
        end
        if enter<=leave and enter<=best and enter>=0 then best=enter;entity=hero;normal=Vector(-1,0,0) end
    end
    return {Hit=entity~=nil,Entity=entity,HitPos=t.start+delta*best,HitNormal=normal,StartSolid=false,Fraction=best}
end
local function arena(e)
    wall={valid=true,LODHostile=false,IsPlayer=function() return false end};wallX=e:GetPos().x+400
    withHero=false;traceCount=0;util.TraceHull=geometry
end
local source,a=launch('caromer',arena)
local q=assert(E.Projectiles[1]);local bank=assert(q.bank,'vertical wall creates warned bank')
local reflected=assert(q.nextGoal)
assert(traceCount<=5,'bounded planning, release and first flight sweep')
assert(a.paths[1].goal==source.nw.LOD_PatternEnd and reflected==source.nw.LOD_PatternSecondEnd,'replicated tell equals actual bank path')
local ticks=0
while q.bank and ticks<100 do steps(1);ticks=ticks+1 end
assert(ticks<100 and E.Projectiles[1]==q and q.velocity.x<0 and q.goal==reflected,'one physical bank follows reflected leg')
local direction=Vector(q.velocity.x,q.velocity.y,q.velocity.z)
hero:SetPos(hero:GetPos()+Vector(50,150,0));steps(1)
assert(q.velocity:DistToSqr(direction)==0,'bank never tracks hidden/new target coordinates')
local before=traceCount;steps(100)
assert(#E.Projectiles==0 and traceCount-before<=100,'finite bank trace budget and final path expiry')
-- Removed/moved/new cover cannot manufacture a bank or use another reflection.
source,a=launch('caromer',arena);q=E.Projectiles[1];wallX=nil;steps(100)
assert(#E.Projectiles==0,'missing advertised wall retires bank')
source,a=launch('caromer',arena);q=E.Projectiles[1];wallX=source:GetPos().x+100;steps(20)
assert(#E.Projectiles==0,'new earlier cover absorbs bank')
source,a=launch('caromer',arena);q=E.Projectiles[1]
while q.bank do steps(1) end
util.TraceHull=function(t) return {Hit=true,HitPos=t.endpos,HitNormal=Vector(1,0,0),Entity=wall} end
steps(1);assert(#E.Projectiles==0,'second wall absorbs, never rebounds again')
-- A plain miss is finite in open terrain; bank identity is conditional on geometry.
source,a=launch('caromer');assert(not E.Projectiles[1].bank);steps(100);assert(#E.Projectiles==0)
print('BESTIARY_B5_BANK_PASS: production AI warning; one frozen reflected leg; exact replicated path; changed/missing/second cover; no homing; finite swept work')

source,a=launch('reeler');q=E.Projectiles[1]
local launchPos=Vector(a.origin.x,a.origin.y,a.origin.z);local endpoint=q.goal
local initial=Vector(q.velocity.x,q.velocity.y,q.velocity.z)
hero:SetPos(hero:GetPos()+Vector(0,140,0));source:SetPos(source:GetPos()+Vector(0,-100,0))
while not q.resume do steps(1) end
local resume=q.resume
assert(q.pos:DistToSqr(endpoint)<1e-8 and q.velocity:LengthSqr()==0 and resume>time+.74,'arrival pauses at original endpoint')
service(resume-.01);assert(q.velocity:LengthSqr()==0,'pause remains harmless movement-free')
service(resume+.001)
assert(q.velocity:Dot(initial)<0 and q.goal==a.origin,'return aims at original launch point, not moving source or Hero')
steps(100);assert(#E.Projectiles==0,'return ends at origin and never repeats')
source,a=launch('reeler');q=E.Projectiles[1]
while not q.resume do steps(1) end
service(q.resume+.001);util.TraceHull=function(t) return {Hit=true,Entity=wall,HitPos=t.endpos} end
steps(1);assert(#E.Projectiles==0,'new cover on return absorbs without tunneling')
print('BESTIARY_B5_RETURN_PASS: fixed outbound endpoint; 0.75s pause; exact reverse to original source point; no tracking; cover and bounded lifetime')

source,a=launch('forker',function(e) arena(e);wallX=nil;withHero=true end)
assert(#E.Projectiles==2 and a.paths[1].start:Distance(a.paths[2].start)==128,'atomic parallel lanes leave broad center gap')
local velocity=E.Projectiles[1].velocity
assert(velocity:DistToSqr(E.Projectiles[2].velocity)<1e-8,'lanes parallel, never converge')
received=0;steps(100);assert(received==0 and #E.Projectiles==0,'real swept center lane is safe')
source,a=launch('forker',function(e) arena(e);wallX=nil;withHero=true end)
hero:SetPos(hero:GetPos()+Vector(0,-64,0));local hp=hero.health;received=0
steps(100)
assert(received==1 and hero.health<hp and receivedContext.physical and not receivedContext.magic,'entering warned lane uses real combat and one native HP settlement')
assert(receivedContext.attackEvent and receivedContext.damageContract.sourcePosition,'shared attack identity and committed incoming origin')
-- Force both lane contacts with the same Hero at the native boundary: only one settlement.
source,a=launch('forker');received=0;hp=hero.health
local rolls=0;local oldRoll=LOD.CombatRolls.RollHostileAttack
LOD.CombatRolls.RollHostileAttack=function(self,...) rolls=rolls+1;return oldRoll(self,...) end
util.TraceHull=function(t) return {Hit=true,Entity=hero,HitPos=t.endpos} end
steps(1);assert(received==1 and rolls==1 and hero.health<hp and #E.Projectiles==0,'both lanes share one attack and at most one damage packet per Hero')
LOD.CombatRolls.RollHostileAttack=oldRoll
for _,id in ipairs({'caromer','reeler','forker'}) do
    source=pair(id);E:Begin(source,hero,time);a=assert(source.LODRosterAttack)
    for i=1,(id=='forker' and 63 or 64) do E.Projectiles[i]={} end
    at(a.ready);E:Release(source,a,time)
    assert(not a.shotEmitted and #E.Projectiles==(id=='forker' and 63 or 64),'atomic shared capacity '..id)
end
source=pair('forker');util.TraceHull=function(t) return {Hit=true,HitPos=t.endpos} end
E:Begin(source,hero,time);assert(not source.LODRosterAttack and source.LODNextAttack==time+.5,'blocked offset rejects whole warning, bounded retry')
source=pair('forker');E:Begin(source,hero,time);a=source.LODRosterAttack
util.TraceHull=function(t) return {Hit=true,HitPos=t.endpos} end
at(a.ready);E:Release(source,a,time)
assert(not a.shotEmitted and #E.Projectiles==0,'new offset cover aborts whole volley before emission')
print('BESTIARY_B5_SPLIT_PASS: two parallel lanes, actual safe gap, swept side hit, canonical roll/mitigation/HP once; shared atomic capacity and covered offsets')

local reasons={'source_life','hero_life','source_state','hero_state','graph','progression','state','epoch','run','seed','campaign','freeze','clear','failed','death','disconnect','source_dead','source_removed'}
local function invalidate(reason,e)
    if reason=='source_life' then Status:ResetActorLife(e)
    elseif reason=='hero_life' then Status:ResetActorLife(hero)
    elseif reason=='source_state' then e.LODProgressionState=table.Copy(e.LODProgressionState)
    elseif reason=='hero_state' then hero.LODProgressionState=table.Copy(hero.LODProgressionState)
    elseif reason=='graph' then s.Graph=table.Copy(s.Graph)
    elseif reason=='progression' then s.Graph.Progression=table.Copy(s.Graph.Progression)
    elseif reason=='state' then local other={};for k,v in pairs(s) do other[k]=v end;LOD.RunManager.State=other
    elseif reason=='epoch' then s.CampaignEpoch=s.CampaignEpoch+1
    elseif reason=='run' then s.RunId=s.RunId..'-next'
    elseif reason=='seed' then s.LevelSeed=s.LevelSeed+1
    elseif reason=='campaign' then s.CampaignSeed=s.CampaignSeed+1
    elseif reason=='freeze' then s.SimulationFrozen=true
    elseif reason=='clear' then s.LevelCleared=true
    elseif reason=='failed' then s.Failed=true
    elseif reason=='death' then hero.alive=false
    elseif reason=='disconnect' then hero.valid=false
    elseif reason=='source_dead' then e.LODDead=true
    elseif reason=='source_removed' then e.valid=false end
end
for _,id in ipairs({'caromer','reeler','forker'}) do
    for _,reason in ipairs(reasons) do
        for _,released in ipairs({false,true}) do
            source=pair(id);E:Begin(source,hero,time);a=assert(source.LODRosterAttack)
            if released then service(a.ready+.01);assert(#E.Projectiles>0) end
            invalidate(reason,source);service(time+.03)
            assert((not IsValid(source) or not source.LODRosterAttack) and #E.Projectiles==0,'stale work '..id..'/'..reason..'/'..tostring(released))
            LOD.RunManager.State=s
        end
    end
    source=pair(id);E:Begin(source,hero,time);a=source.LODRosterAttack
    service(a.ready+.21);assert(not source.LODRosterAttack and #E.Projectiles==0,'late service cannot release an expired warning')
    source=pair(id);E:Begin(source,hero,time);E:Interrupt(source);steps(60)
    assert(not source.LODRosterAttack and #E.Projectiles==0,'interrupted warning cannot reappear')
    source,a=launch(id);q=E.Projectiles[1];source.LODHitStunUntil=time+5;E:Interrupt(source)
    steps(1);assert(E.Projectiles[1]==q,'emitted shot survives ordinary interruption')
    service(q.expires+.001);assert(#E.Projectiles==0,'wall-clock deadline prevents catchup after stall')
    source=pair(id);assert(Status:Apply(source,'held',hero,{direct=true,duration=3}));assert(Status:Apply(source,'muted',hero,{direct=true,duration=3}))
    E:Tick(source);a=assert(source.LODRosterAttack,'Held/Muted physical attack remains legal')
    service(a.ready+.01);assert(a.shotEmitted)
end
print('BESTIARY_B5_LIFECYCLE_PASS: full cohort charge and released source/Hero progression/status-life; exact same-seed state/graph/progression/campaign; freeze/failure/death/disconnect; warning grace, interruption, Held/Muted and finite expiry')

-- No world discovery, gameplay RNG or extra bodies in the projectile service.
source,a=launch('forker');local oldFind,oldAll,oldRandom=ents.FindByClass,player.GetAll,math.random
ents.FindByClass=function() error('world scan') end;player.GetAll=function() error('Hero rescan') end
math.random=function() error('global RNG') end
local traces=0;util.TraceHull=function(t) traces=traces+1;return clearTrace(t) end
steps(1);assert(traces==2,'at most one sweep per live projectile per tick')
ents.FindByClass,player.GetAll,math.random=oldFind,oldAll,oldRandom
print('BESTIARY_B5_BUDGET_PASS: single existing active service, no scans/RNG/native bodies; <=64 shots; <=one sweep per shot per tick')

-- Exact server snapshots drive the actual client renderer, including reduced effects.
function Material(path) return path end
local low=false;GetConVar=function() return {GetBool=function() return low end} end
local receivers,beams,sprites={},{},{}
function EyePos() return Vector() end
net.Receive=function(name,callback) receivers[name]=callback end
render={SetMaterial=noop,SetColorMaterial=noop,
 DrawBeam=function(from,to,width) beams[#beams+1]={from=from,to=to,width=width} end,
 DrawSprite=function(pos,w,h) sprites[#sprites+1]={pos=pos,w=w,h=h} end}
dofile(root..'cl_enemy_roster.lua')
for _,id in ipairs({'caromer','reeler','forker'}) do
    source=pair(id);source:SetPos(Vector());hero:SetPos(Vector(160,0,0))
    if id=='caromer' then arena(source) end
    E:Begin(source,hero,time);a=assert(source.LODRosterAttack)
    local function read(self,k,default) local v=self.nw[k];if v==nil then return default end;return v end
    source.GetNW2Bool=read;source.GetNW2Entity=read;source.GetNW2Int=read;source.GetNW2Float=read;source.GetNW2Vector=read
    source.GetNW2String=function() return id end
    for _,reduced in ipairs({false,true}) do
        low=reduced;beams={};LOD.EnemyRosterVisual:Draw(source,1)
        assert(#beams==(id=='caromer' and 6 or (id=='reeler' and 4 or 2)),'finite semantic geometry retained at both effect levels')
        assert(beams[1].from==a.paths[1].start and beams[1].to==a.paths[1].goal,'first leg equals production trajectory')
        assert(beams[2].from==(a.paths[2] and a.paths[2].start or a.paths[1].nextStart)
            and beams[2].to==(a.paths[2] and a.paths[2].goal or a.paths[1].nextGoal),'second leg/parallel lane equals production trajectory')
    end
    source.nw.LOD_PatternUntil=time;beams={};LOD.EnemyRosterVisual:Draw(source,1);assert(#beams==0,'warning expires locally')
    source.nw.LOD_PatternUntil=time+2;source.nw.LOD_RosterAlive=false;beams={};LOD.EnemyRosterVisual:Draw(source,1);assert(#beams==0,'dead source hides warning')
    source.nw.LOD_RosterAlive=true;E:Cancel(source);beams={};LOD.EnemyRosterVisual:Draw(source,1);assert(#beams==0,'cancelled warning hides immediately')
end
-- Reserved two-bit type3 retains wire compatibility and shows turnaround diamond.
local uints={1,3};local vectors={Vector(40,0,40),Vector()}
net.ReadUInt=function() return table.remove(uints,1) end;net.ReadVector=function() return table.remove(vectors,1) end
receivers.LOD_RosterProjectiles();beams={};sprites={};env.hooks.LOD_RosterProjectiles(false,false)
assert(#beams==5 and #sprites==1,'paused physical pattern shows a hollow diamond')
at(time+.31);beams={};sprites={};env.hooks.LOD_RosterProjectiles(false,false)
assert(#beams==0 and #sprites==0,'stale projectile packet expires')
print('BESTIARY_B5_VISUAL_PASS: actual frozen polylines and open center; full/reduced geometry; death/cancel/expiry; existing two-bit snapshot and paused-return diamond')
