-- B3 exercises real graph routing, roster commitment, actor progression and spawning.
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
dofile(root..'sv_combat_rolls.lua');dofile(root..'sv_character_progression.lua')
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
s.CampaignEpoch=1;s.RunId='b3';s.CampaignSeed=77;s.LevelSeed=123
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
    E.Active=setmetatable({}, {__mode='k'});D.Entities={};Status.Active=setmetatable({}, {__mode='k'})
    s.Graph=table.Copy(s.Graph);s.Graph.Progression={Gates={}};s.SimulationFrozen=false;s.Failed=false;s.LevelCleared=false
    util.TraceLine=clearTrace;util.TraceHull=clearTrace;hero.valid=true;hero.alive=true;hero.health=hero.maximum
    if LOD.EnemySupport then LOD.EnemySupport.Pending={};LOD.EnemySupport.Recipients={};LOD.EnemySupport.NextService=0 end
end
local ids={'pincer','harrier','waylayer'}
local expected={pincer={die=8,xp=45},harrier={die=6,xp=45},waylayer={die=10,xp=55}}
for _,id in ipairs(ids) do
    local def=expected[id]
    for seed=1,16 do
        local generated=assert(C:GenerateMonsterProgression(id,72000+seed,8,45,'ai'))
        local replay=assert(C:GenerateMonsterProgression(id,72000+seed,8,45,'ai'))
        assert(generated.archetypeId==id and generated.usesMagic==false,'own nonmagical progression identity '..id)
        assert(generated.progressionHitDieSides==def.die and generated.level>=9 and #generated.featIds>0)
        assert(generated.derivedStats.maxHP>45 and generated.derivedStats.maxHP==replay.derivedStats.maxHP
            and generated.classId==replay.classId and table.concat(generated.featIds,',')==table.concat(replay.featIds,','),'independent seeded generation replay')
        assert(generated.classId~='wizard' and C:_HasCapability({},generated,'pushable_weapon'),'physical class and supported attack feats')
        assert(not C:_HasCapability({},generated,'offensive_magic_activation'),'no unusable offensive Magic feats')
    end
    local hostile=actor(id);local awards=0
    C.AwardHeroXP=function(_,identity,amount) assert(identity=='tester');awards=awards+amount;return true end
    local attribution=LOD.CombatAttributionSystem
    attribution.Ledgers[hostile]={effectiveDamageByHeroId={tester=100},killingBlowHeroId='tester'}
    local xp=math.max(5,5*math.floor((def.xp*(1+.05*(hostile.LODProgressionState.level-1)))/5+.5))
    assert(attribution:Settle(hostile) and hostile.LODRPGXPSettlement.value==xp and awards==xp,'shared level-scaled XP')
    assert(not attribution:Settle(hostile) and awards==xp,'single ordinary reward settlement')
end

dofile(root..'sv_hostile_motion_v2.lua')
dofile(root..'sv_enemy_pursuit.lua')
local P,N=LOD.EnemyPursuit,LOD.MazeNavigator
local key=LOD.MazeGenerator.CellKey
local function grid()
    local g={Cells={},CellTags={},VerticalEdges={},Progression={Gates={}},Width=7,Height=5,Layers=1}
    for x=1,7 do for y=1,5 do g.Cells[key(x,y,0)]={x=x,y=y,z=0,neighbors={}} end end
    for _,c in pairs(g.Cells) do
        for _,delta in ipairs({{1,0},{-1,0},{0,1},{0,-1}}) do
            local k=key(c.x+delta[1],c.y+delta[2],0);if g.Cells[k] then c.neighbors[k]=true end
        end
    end
    return g
end
local function center(x,y) return N:CellCenter(s.Graph.Cells[key(x,y,0)]) end
local moves,stops=0,0
LOD.HostileMotionV2.MoveToward=function(_,e,wp) moves=moves+1;e.lastWaypoint=wp end
LOD.HostileMotionV2.Stop=function() stops=stops+1 end
local function pair(id)
    reset();s.Graph=grid();s.GatesOpen={};s.BuildReady=true
    P.Active={};P.NextService=0
    hero:SetPos(center(5,3));hero.LODHitStunUntil=nil
    local source=actor(id);source:SetPos(center(3,3));source.LODHomeCellKey=key(3,3,0)
    source.LODTarget=hero;source.LODConfig.fireRange=1400
    E:Prepare(source);D.Entities={source};moves=0;stops=0
    return source
end

dofile(root..'sv_enemy_variance.lua')
D.LODUnifiedVarianceSpawner=nil;dofile(root..'sv_encounter_spawn_variance.lua')
LOD.WanderingDirector={Config={ArchetypeWeights={}}}
dofile(root..'sv_enemy_roster_placement.lua')
pair('pincer');D.Entities={};D.activeCount=0
local creates=0
ents.Create=function(class)
    assert(class=='lod_hostile');creates=creates+1
    local e=actor('runner');e.LODProgressionState=nil
    e.Spawn=function(self)
        self.LODConfig=table.Copy(LOD.Config.Encounter.Archetypes[self.LODArchetypeId])
        self.maximum=self.LODConfig.baseHP;self.health=self.maximum
        -- Native Initialize is doubled; the real spawner's variance fallback
        -- must attach this actor's actual progression and class/feat/HP state.
    end
    return e
end
local cell=s.Graph.Cells[key(3,3,0)]
local encounter={id=903,cell=cell,cellKey=key(3,3,0),role='arena',sector=2,composition={pincer=1,harrier=1,waylayer=1},entities={}}
D.activeCount=LOD.Config.Encounter.ActiveHostileCeiling-2
assert(not D:_SpawnEncounter(encounter) and creates==0,'preflight cap prevents partial cohort')
D.activeCount=0;assert(D:_SpawnEncounter(encounter) and #encounter.entities==3,'all three appear through actual production spawn order')
for i,e in ipairs(encounter.entities) do
    assert(e.LODArchetypeId==ids[i] and e.LODEncounterOrdinal==i and e.LODVariance,'stable pre-Spawn identity and independent variance stream')
    assert(e.LODProgressionState.archetypeId==ids[i] and e:GetMaxHealth()==e.LODProgressionState.derivedStats.maxHP,'spawner crosses real progression/HP seam')
    assert(e.nw.LOD_CharacterLevel==e.LODProgressionState.level,'normal replicated actor Level')
end
assert(D:_SpawnEncounter(encounter) and creates==3,'spawn retry cannot duplicate cohort')
for _,name in ipairs({'pincer_detail','harrier_screen','waylayer_cutoff'}) do
    assert(table.HasValue(D:_EligibleTemplates(2,'arena'),name) and table.HasValue(D:_EligibleTemplates(2,'ambush'),name))
    assert(not table.HasValue(D:_EligibleTemplates(1,'arena'),name),'sector-one preserves established introductory roster')
end
print('BESTIARY_B3_PRODUCTION_PASS: own nonmagical class/feat/HP identities; seeded replay; capability eligibility; shared XP once; cap; real spawn/variance/progression; idempotence; complementary templates')

local function signature(a)
    local out={};for _,c in ipairs(a.path) do out[#out+1]=E.Key(c) end;return table.concat(out,'|')
end
local function start(id)
    local source=pair(id);assert(P:Start(source,hero,id,time),'legal '..id..' commitment')
    return source,assert(source.LODPursuit)
end
local source=pair('pincer')
local plan=assert(P:Plan(source,hero,'pincer'))
local direct=N:FindPath(s.Graph,s.Graph.Cells[key(3,3,0)],s.Graph.Cells[key(5,3,0)])
assert(E.Key(plan.path[2])~=E.Key(direct[2]) and E.Key(plan.path[#plan.path])==key(5,3,0),'actual alternate graph approach avoids direct first edge')
assert(#plan.path==5 and P:RouteLegal(s.Graph,plan.path),'four legal edges around the observed lane')
local replay=assert(P:Plan(source,hero,'pincer'))
assert(signature(plan)==signature(replay),'unchanged state produces stable route without RNG consumption')
local oldRandom=math.random;math.random=function() error('pursuit must not consume global RNG') end
assert(signature(P:Plan(source,hero,'pincer'))==signature(plan));math.random=oldRandom
assert(P.LastSearchNodes<=P.MaxNodes and #plan.path<=P.MaxDepth+1,'bounded node and route work')
hero:SetPos(source:GetPos()+Vector(60,0,0));plan=assert(P:Plan(source,hero,'pincer'))
assert(E.Key(plan.path[1])==E.Key(plan.path[#plan.path]) and #plan.path==5,'same-cell pressure uses a legal loop, not a numerical variant')
-- A tree-like room has no cycle. The fallback still changes approach with
-- two non-collinear, physically checked legs wholly inside the observed cell.
local function isolatedPincer()
    local e=pair('pincer');local c=s.Graph.Cells[key(3,3,0)]
    for neighbor in pairs(c.neighbors) do s.Graph.Cells[neighbor].neighbors[E.Key(c)]=nil end
    c.neighbors={};hero:SetPos(e:GetPos()+Vector(80,0,0))
    return e
end
source=isolatedPincer();plan=assert(P:Plan(source,hero,'pincer'))
assert(plan.localRoute and #plan.path==1 and #plan.waypoints==2,'cycle-free room gets a real two-leg approach')
local origin=source:GetPos();local one=plan.waypoints[1].pos;local two=plan.waypoints[2].pos
local firstLeg,secondLeg=one-origin,two-one
assert(math.abs(firstLeg.y)>=64 and secondLeg.x>=32 and math.abs(firstLeg.x*secondLeg.y-firstLeg.y*secondLeg.x)>=64*32,'local flank has meaningful lateral then closing motion')
for _,wp in ipairs(plan.waypoints) do assert(E.Key(N:WorldToCell(s.Graph,wp.pos))==key(3,3,0),'both legs remain inside legal room') end
assert(P:Start(source,hero,'pincer',time));local localAttack=source.LODPursuit
local remembered=localAttack.snapshot;hero:SetPos(center(7,5));util.TraceLine=function(t) return {Hit=true,HitPos=t.start} end
at(localAttack.ready);P:Tick(source,hero,time)
assert(source.LODPursuit==localAttack and localAttack.snapshot==remembered,'local flank follows frozen observation after Hero leaves view')
source:SetPos(center(4,3));P:Tick(source,hero,time)
assert(not source.LODPursuit,'forced local-room exit retires route instead of crossing a disconnected wall')
source=isolatedPincer()
s.Graph.Cells[key(3,3,0)].neighbors[key(4,3,0)]=true;s.Graph.Cells[key(4,3,0)].neighbors[key(3,3,0)]=true
hero:SetPos(center(4,3));plan=assert(P:Plan(source,hero,'pincer'))
assert(plan.localRoute,'visible adjacent Hero permits the legal source-room lateral approach')
source=isolatedPincer();util.TraceHull=function(t) return {Hit=true,HitPos=t.start} end
assert(not P:Plan(source,hero,'pincer'),'both obstructed lateral alternatives reject local fallback')
source=isolatedPincer();assert(P:Start(source,hero,'pincer',time));localAttack=source.LODPursuit
at(localAttack.ready);util.TraceHull=function(t) return {Hit=true,HitPos=t.start} end;P:Tick(source,hero,time)
assert(not source.LODPursuit,'new local obstacle cancels at next movement step')

source=pair('pincer');util.TraceLine=function(t) return {Hit=true,HitPos=t.start} end
assert(not P:Plan(source,hero,'pincer'),'unseen Hero cannot seed a flanking route')
util.TraceLine=clearTrace;LOD.RPGPerceptionState={IsInvisible=function(_,p) return p==hero end}
assert(not P:Plan(source,hero,'pincer'),'invisible Hero cannot seed route');LOD.RPGPerceptionState=nil

-- Each role proves actual selected-route collision clearance, gate/safe/objective
-- exclusions and exact same-floor reachability, not just destination scoring.
for _,id in ipairs(ids) do
    source=pair(id);plan=assert(P:Plan(source,hero,id));assert(P:RouteLegal(s.Graph,plan.path))
    util.TraceHull=function(t) return {Hit=true,HitPos=t.start} end
    assert(not P:Plan(source,hero,id),id..' cannot plan through physical solids')
    util.TraceHull=function(t) return {Hit=false,StartSolid=true,HitPos=t.start} end
    assert(not P:Plan(source,hero,id),id..' cannot originate in a solid')
    util.TraceHull=clearTrace
    for _,tag in ipairs({'safe','objective'}) do
        s.Graph.CellTags[key(3,3,0)]={[tag]=true};assert(not P:Plan(source,hero,id),id..' excludes '..tag)
    end
    s.Graph.CellTags={}
    local other={x=5,y=3,z=1,neighbors={}};s.Graph.Cells[key(5,3,1)]=other;s.Graph.Layers=2
    hero:SetPos(N:CellCenter(other));assert(not P:Plan(source,hero,id),'no floor-to-floor shortcut')
end
-- Dense graphs exceed the search budget. Probe actual traversal and native
-- route attempts rather than relying only on constant/config assertions.
source=pair('harrier')
local large={Cells={},CellTags={},VerticalEdges={},Progression={Gates={}},Width=15,Height=15,Layers=1}
for x=1,15 do for y=1,15 do large.Cells[key(x,y,0)]={x=x,y=y,z=0,neighbors={}} end end
for _,c in pairs(large.Cells) do
    for _,delta in ipairs({{1,0},{-1,0},{0,1},{0,-1}}) do
        local k=key(c.x+delta[1],c.y+delta[2],0);if large.Cells[k] then c.neighbors[k]=true end
    end
end
s.Graph=large;source:SetPos(center(7,7));hero:SetPos(center(9,7))
local queue=P:Search(large,large.Cells[key(7,7,0)])
assert(#queue==P.MaxNodes and P.LastSearchNodes==P.MaxNodes,'dense graph traversal actually stops at finite node cap')
local attempts=0;local realWaypoints=P.Waypoints
P.Waypoints=function(self,...) attempts=attempts+1;return realWaypoints(self,...) end
assert(P:Plan(source,hero,'harrier'));P.Waypoints=realWaypoints
assert(attempts>0 and attempts<=P.MaxCandidates,'physical candidate work is independently bounded')

source=pair('pincer');plan=assert(P:Plan(source,hero,'pincer'))
local first,second=plan.path[1],plan.path[2]
s.Graph.Progression.Gates={{edgeKey=N:EdgeKey(first,second)}}
assert(not P:RouteLegal(s.Graph,plan.path),'closed canonical gate invalidates an already selected route')
s.GatesOpen[1]=true;assert(P:RouteLegal(s.Graph,plan.path),'open gate restores traversal legality')
LOD.EventDirector={BlocksEdge=function(_,_,edge) return edge==N:EdgeKey(first,second) end}
assert(not P:RouteLegal(s.Graph,plan.path),'event blockades retain canonical ownership');LOD.EventDirector=nil

-- A clear farther destination is a real retreat fallback; native cover wins
-- among bounded candidates when present. Neither reads future Hero movement.
source=pair('harrier');plan=assert(P:Plan(source,hero,'harrier'))
assert(plan.destination:DistToSqr(plan.snapshot)>source:GetPos():DistToSqr(plan.snapshot),'skirmisher opens distance')
local coveredCell=key(1,2,0)
util.TraceLine=function(t)
    local c=N:WorldToCell(s.Graph,t.start)
    return {Hit=c and E.Key(c)==coveredCell or false,HitPos=t.endpos}
end
plan=assert(P:Plan(source,hero,'harrier'))
assert(E.Key(plan.path[#plan.path])==coveredCell,'reachable covered retreat preferred over farther exposed cell')
assert(P:Covered(source,plan.destination,plan.snapshot),'cover is a native trace decision')
source=pair('waylayer');plan=assert(P:Plan(source,hero,'waylayer'))
assert(#P:Exits(s.Graph,plan.path[#plan.path])>=3 and E.Key(plan.path[#plan.path])~=key(5,3,0),'interceptor chooses alternate reachable escape junction')

-- Commitments expose a warning before movement, then traverse existing graph
-- waypoints through Motion V2. Test transport advances actors only after that
-- production method is called; the pursuit authority never teleports them.
for _,id in ipairs({'pincer','waylayer'}) do
    local a;source,a=start(id);local before=source:GetPos()
    P:Tick(source,hero,a.ready-.001)
    assert(moves==0 and source:GetPos()==before and source.nw.LOD_PursuitMode==P.Profiles[id].mode,'warning is safe and visible')
    at(a.ready);P:Tick(source,hero,time);assert(moves==1 and source:GetPos()==before,'movement delegated, never teleport')
    for i=1,10 do
        if not source.LODPursuit or a.holdUntil then break end
        if source.lastWaypoint then source:SetPos(source.lastWaypoint.pos) end
        at(time+.01);P:Tick(source,hero,time)
    end
    if id=='waylayer' then
        assert(source.LODPursuit==a and a.holdUntil>time,'interceptor holds finite announced junction')
        local n=moves;at(a.holdUntil);P:Tick(source,hero,time)
        assert(not source.LODPursuit and moves==n,'hold expires without an unavoidable damage event')
    else assert(not source.LODPursuit,'flanker returns to canonical attack after completing approach') end
end

-- Service retirement covers outer AI wrappers that return early for hit-stun,
-- freeze or death. Exact object identities distinguish same-seed replacements.
for _,id in ipairs(ids) do
    for _,reason in ipairs({'stun','held','morale','source_dead','source_removed','hero_dead','hero_removed','source_state','hero_state','source_life','hero_life','graph','progression','state','campaign','run_id','freeze','failed','cleared','expiry','closed_gate'}) do
        local a;source,a=start(id)
        if reason=='stun' then source.LODHitStunUntil=time+5
        elseif reason=='held' then Status:Apply(source,'held',hero,{direct=true,duration=5})
        elseif reason=='morale' then local applied,reason=Status:AttemptMorale(hero,source,{forceMorale=true,rng={Int=function() return 1 end}});assert(applied and reason=='flee','canonical morale fixture')
        elseif reason=='source_dead' then source.LODDead=true
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
        elseif reason=='run_id' then s.RunId=s.RunId..'-replacement'
        elseif reason=='freeze' then s.SimulationFrozen=true
        elseif reason=='failed' then s.Failed=true
        elseif reason=='cleared' then s.LevelCleared=true
        elseif reason=='expiry' then at(a.expires)
        elseif reason=='closed_gate' then s.Graph.Progression.Gates={{edgeKey=N:EdgeKey(a.path[1],a.path[2])}} end
        P:Service(time,true)
        assert(not P.Active[source] and (not IsValid(source) or not source.LODPursuit),id..' retirement '..reason)
        LOD.RunManager.State=s
    end
end
source,plan=start('pincer');local remembered=signature(plan);local snapshot=plan.snapshot
hero:SetPos(center(7,5));util.TraceLine=function(t) return {Hit=true,HitPos=t.start} end
at(plan.ready);P:Tick(source,hero,time)
assert(source.LODPursuit==plan and signature(plan)==remembered and plan.snapshot==snapshot,'lost sight preserves only old observed route, never updates unseen Hero position')
util.TraceHull=function(t) return {Hit=true,HitPos=t.start} end
P:Tick(source,hero,time);assert(not source.LODPursuit,'new physical obstruction cancels on the next step')
print('BESTIARY_B3_ROUTE_PASS: alternate/retreat/junction counterplay; bounded deterministic routes; LOS and cover; native-clear legal steps; gates/safes/floors; warning/hold/expiry; exact source/Hero/run/campaign identities; no hidden retarget or teleport')

-- Exercise the actual roster Tick -> Begin -> shared service -> Release seam.
-- Harrier cannot retreat until an emitted, warned projectile has committed.
source=pair('harrier');E.Projectiles={};E.NextService=0;E.LastService=time
assert(not P:Tick(source,hero,time) and not source.LODPursuit,'no skirmish before an actual attack')
E:Tick(source);local shot=assert(source.LODRosterAttack)
assert(shot.pursuitRecord and not shot.shotEmitted and not source.LODPursuit,'roster Begin captures real actor/dungeon identity')
at(shot.ready-.001);env.hooks.LOD_EnemyRosterAttacks()
assert(#E.Projectiles==0 and not source.LODPursuit,'no damage or retreat before telegraph')
at(shot.ready+.03);env.hooks.LOD_EnemyRosterAttacks()
assert(shot.shotEmitted and #E.Projectiles==1 and not source.LODPursuit,'real Release emits projectile before recovery retreat')
E:Tick(source);assert(moves==0,'the canonical attack commitment finishes before retreat movement')
at(shot.finish+.03);env.hooks.LOD_EnemyRosterAttacks();E:Tick(source)
local retreat=assert(source.LODPursuit,'finished successful attack starts retreat')
assert(retreat.record==shot.pursuitRecord and retreat.snapshot==shot.pursuitRecord.snapshot,'retreat uses attack observation, not new hidden knowledge')
assert(not P:AfterAttack(source,shot,time),'same emitted shot cannot restart/refresh retreat')
assert(moves==1 and not source.LODRosterAttack,'shared roster service completes attack and dispatches pursuit')
source=pair('harrier');E.Projectiles={};for i=1,64 do E.Projectiles[i]={} end
E:Begin(source,hero,time);shot=source.LODRosterAttack;E:Release(source,shot,time);E:Finish(source,time+.2)
assert(not shot.shotEmitted and not source.LODPursuit,'projectile budget rejection cannot award a free retreat')
E.Projectiles={}
source=pair('harrier');E:Begin(source,hero,time);shot=source.LODRosterAttack
Status:ResetActorLife(hero);at(shot.ready+.03);E.NextService=0;env.hooks.LOD_EnemyRosterAttacks()
assert(not source.LODRosterAttack and #E.Projectiles==0 and not source.LODPursuit,'replaced Hero life cancels actual ranged commitment before release')
-- Held only forbids voluntary motion. It must not erase legal firearm
-- attacks, and interruption after a projectile release cannot recall the shot.
for _,id in ipairs(ids) do
    source=pair(id);E.Projectiles={};assert(Status:Apply(source,'held',hero,{direct=true,duration=10}))
    E:Tick(source);shot=assert(source.LODRosterAttack,'Held allows ordinary physical attack '..id)
    at(shot.ready+.03);E.NextService=0;env.hooks.LOD_EnemyRosterAttacks()
    assert(shot.shotEmitted and #E.Projectiles==1 and not source.LODPursuit,'Held attack emits normally without granting movement')
end
source=pair('harrier');E.Projectiles={};E:Begin(source,hero,time);shot=source.LODRosterAttack
at(shot.ready+.03);E.NextService=0;env.hooks.LOD_EnemyRosterAttacks()
assert(#E.Projectiles==1);local emitted=E.Projectiles[1]
source.LODHitStunUntil=time+5;at(time+.03);env.hooks.LOD_EnemyRosterAttacks()
assert(#E.Projectiles==1 and E.Projectiles[1]==emitted,'post-release hit-stun cannot recall an emitted projectile')
LOD.RPGPerceptionState={IsInvisible=function(_,p) return p==hero end};at(time+.03);env.hooks.LOD_EnemyRosterAttacks()
assert(#E.Projectiles==1 and E.Projectiles[1]==emitted,'post-release invisibility cannot recall emitted projectile')
LOD.RPGPerceptionState=nil
Status:ResetActorLife(source);at(time+.03);env.hooks.LOD_EnemyRosterAttacks()
assert(#E.Projectiles==0,'new source life still retires old emitted projectile')

for _,id in ipairs(ids) do
    source=pair(id);source.LODNextPursuit=time+20
    local routes=0;source._RefreshRoute=function() routes=routes+1 end
    util.TraceLine=function(t) return {Hit=true,HitPos=t.start} end
    E:Tick(source)
    assert(not source.LODRosterAttack and not source.LODPursuit and routes==0,'ordinary fallback cannot follow hidden Hero coordinates '..id)
end
source,plan=start('waylayer');E:Interrupt(source)
assert(not source.LODPursuit and source.nw.LOD_PursuitMode==0,'canonical hit interruption synchronously clears destination')
source,plan=start('pincer');source:SetPos(center(7,5));at(plan.ready);P:Tick(source,hero,time)
assert(not source.LODPursuit,'forced displacement outside committed segment cannot cut across graph')
print('BESTIARY_B3_ROSTER_PASS: real Tick/Begin/service/Release; warning before projectile; emitted-shot-only retreat; cap/idempotence; Hero-life cancellation; hidden-target fallback; synchronous interruption and displacement')

-- Real physical movement kernel, not the earlier transport spy: a four-edge
-- Pincer loop must finish inside its computed finite deadline at authored speed.
-- Trace results remain native-boundary doubles; Source acceptance is separate.
dofile(root..'sv_hostile_motion_v2.lua')
source=pair('pincer');hero:SetPos(source:GetPos()+Vector(60,0,0))
source.LODConfig.speed=180;source.LODMotionLastUpdate=time
assert(P:Start(source,hero,'pincer',time));local journey=source.LODPursuit
assert(#journey.path==5 and journey.expires-journey.ready>=6 and journey.expires-journey.ready<=16)
local travelled={E.Key(N:WorldToCell(s.Graph,source:GetPos()))};local count=0
while source.LODPursuit and time<journey.expires+.1 do
    at(time+.025);P:Tick(source,hero,time);count=count+1
    local here=E.Key(N:WorldToCell(s.Graph,source:GetPos()))
    if here~=travelled[#travelled] then travelled[#travelled+1]=here end
    assert(count<700,'finite route cannot loop indefinitely')
end
assert(not source.LODPursuit and time<journey.expires,'full four-cell flank reaches destination before expiry')
assert(source:GetPos():DistToSqr(journey.destination)<=18^2,'physical kernel reaches final waypoint')
assert(table.concat(travelled,'|')==signature(journey),'every graph edge traversed in committed order without cutting corners')
assert(source.LODMotionTravel>1400,'authored route covers real path distance')
source=isolatedPincer();source.LODMotionLastUpdate=time
assert(P:Start(source,hero,'pincer',time));journey=source.LODPursuit
assert(journey.localRoute)
while source.LODPursuit and time<journey.expires+.1 do
    at(time+.025);P:Tick(source,hero,time)
    assert(E.Key(N:WorldToCell(s.Graph,source:GetPos()))==key(3,3,0),'real local locomotion stays in source room')
end
assert(not source.LODPursuit and time<journey.expires and source:GetPos():DistToSqr(journey.destination)<=12^2,'actual local two-leg flank completes inside finite deadline')
print('BESTIARY_B3_MOTION_PASS: real Motion V2 completed four-edge and local two-leg routes within finite deadlines; graph cells crossed in order; no teleport or corner cutting; native traces still require Source acceptance')

-- B27: real specialist dispatch must consume an idle roaming route, not return
-- early merely because its tactical pursuit has no currently visible Hero.
local nativeMove=LOD.HostileMotionV2.MoveToward
for _,id in ipairs({'pincer','harrier','waylayer'}) do
    local e=pair(id);e.LODWanderer=true;e.LODTarget=nil
    local travelled=0;local wp={pos=e:GetPos()+Vector(48,0,0)}
    e._RefreshRoute=function(self,graph) assert(graph==s.Graph);self.LODWaypoints={wp};self.LODWaypointIndex=1 end
    LOD.HostileMotionV2.MoveToward=function(_,actor,waypoint) assert(actor==e and waypoint==wp);travelled=travelled+1 end
    E:Tick(e);assert(travelled==1 and not e.LODPursuit and not e.LODTarget,'idle roaming dispatch '..id)
    e.LODWanderer=false;E:Tick(e);assert(travelled==1,'authored pursuit actor gained ambient wandering')
end
LOD.HostileMotionV2.MoveToward=nativeMove
print('BESTIARY_B27_PURSUIT_PATROL_PASS: actual roster dispatch consumes target-free patrols; encounter-only behavior unchanged')
