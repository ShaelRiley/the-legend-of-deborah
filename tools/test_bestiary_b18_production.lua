-- B18 production gate exercises progression, rewards, placement and canonical spawning.
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
s.CampaignEpoch=1;s.RunId='b18';s.CampaignSeed=77;s.LevelSeed=123
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
local ids={'censor','surveyor'}
local normal,named=0,0
local bosses={neil=true,brute=true,warden=true,hector=true}
for id in pairs(LOD.RPG.ArchetypeProgressionTemplates) do
    if bosses[id] then named=named+1 else normal=normal+1 end
end
assert(normal==61 and named==4,'61 ordinary archetypes and four separately counted named bosses')

local spawnSource=assert(io.open(root..'sv_encounter_spawn_variance.lua','r'))
local spawnText=spawnSource:read('*a');spawnSource:close()
local order={}
for id in assert(spawnText:match('local SPAWN_ORDER = {(.-)}')):gmatch('"([^"]+)"') do order[#order+1]=id end
assert(#order==59 and order[56]=='interposer' and order[57]=='mourner'
    and order[58]=='censor' and order[59]=='surveyor','append-only production spawn ordinals58/59')
local expected={
    censor={die=8,xp=50,magic=false,abilities={11,12,12,13,12,10},fighter=50,rogue=50,wizard=0,morale=5},
    surveyor={die=8,xp=55,magic=true,abilities={9,11,11,15,14,10},fighter=0,rogue=0,wizard=100,morale=5}
}
for _,id in ipairs(ids) do
    local def=expected[id]
    local template=LOD.RPG.ArchetypeProgressionTemplates[id]
    for i,ability in ipairs({'str','dex','con','int','wis','cha'}) do
        assert(template.baseAbilities[ability]==def.abilities[i],'authored base ability '..id..':'..ability)
    end
    assert(template.aiClassWeights.fighter==def.fighter and template.aiClassWeights.rogue==def.rogue
        and template.aiClassWeights.wizard==def.wizard and template.moraleBonus==def.morale,'authored class distribution/morale')
    for seed=1,16 do
        local generated=assert(C:GenerateMonsterProgression(id,72000+seed,8,45,'ai'))
        assert(C:GenerateMonsterProgression('runner',99900+seed,12,25,'ai'))
        local replay=assert(C:GenerateMonsterProgression(id,72000+seed,8,45,'ai'))
        assert(generated.archetypeId==id and generated.usesMagic==def.magic,'own progression identity '..id)
        assert(generated.progressionHitDieSides==def.die and generated.level>=9 and #generated.featIds>0)
        assert(generated.derivedStats.maxHP>45 and generated.derivedStats.maxHP==replay.derivedStats.maxHP
            and generated.classId==replay.classId and table.concat(generated.featIds,',')==table.concat(replay.featIds,','),'independent seeded generation replay')
        assert((def.magic and generated.classId=='wizard') or (not def.magic and (generated.classId=='fighter' or generated.classId=='rogue')),'authored class identity')
        assert(C:_HasCapability({},generated,'offensive_magic_activation')==def.magic,'authored offensive Magic capability')
        assert(not C:_HasCapability({},generated,'discrete_magic_activation'),'no discrete Magic capability')
        assert(C:_HasCapability({},generated,'pushable_weapon'),'ordinary actor weapon capability')
        assert(not C:_HasCapability({},generated,'firearm'),'no Soldier-only gun capability')
        for _,featId in ipairs(generated.featIds) do
            local feat=C:_FindFeat(featId)
            for _,capability in ipairs(feat and feat.requiredCapabilityTags or {}) do
                assert(C:_HasCapability({},generated,capability),'selected feat has a usable capability: '..featId)
            end
        end
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
local N=LOD.MazeNavigator
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
    hero:SetPos(center(5,3));hero.LODHitStunUntil=nil
    local source=actor(id);source:SetPos(center(3,3));source.LODHomeCellKey=key(3,3,0)
    source.LODTarget=hero
    E:Prepare(source);D.Entities={source};moves=0;stops=0
    return source
end

-- Production actors capture the canonical status incarnation and exact dungeon.
-- These assertions use real progression/status binding, not custom life doubles.
for _,id in ipairs(ids) do
    local source=pair(id)
    local function capture() local life=E:CaptureLife(source,hero);assert(E:ValidLife(life));return life end
    local life=capture()
    local original=hero.LODProgressionState;hero.LODProgressionState=table.Copy(original)
    assert(not E:ValidLife(life),'target progression replacement retires commitment')
    hero.LODProgressionState=original
    life=capture();original=source.LODProgressionState;source.LODProgressionState=table.Copy(original)
    assert(not E:ValidLife(life),'source progression replacement retires commitment')
    source.LODProgressionState=original
    life=capture();local oldGraph=s.Graph;s.Graph=table.Copy(oldGraph)
    assert(not E:ValidLife(life),'same-seed graph replacement retires commitment');s.Graph=oldGraph
    life=capture();local oldProgression=s.Graph.Progression;s.Graph.Progression=table.Copy(oldProgression)
    assert(not E:ValidLife(life),'same-graph progression replacement retires commitment');s.Graph.Progression=oldProgression
    life=capture();s.CampaignEpoch=s.CampaignEpoch+1
    assert(not E:ValidLife(life),'campaign reset retires commitment');s.CampaignEpoch=s.CampaignEpoch-1
    life=capture();s.SimulationFrozen=true
    assert(not E:ValidLife(life),'freeze suspends commitment');s.SimulationFrozen=false
    life=capture();source.LODDead=true
    assert(not E:ValidLife(life),'source death retires commitment');source.LODDead=false
    life=capture();hero.valid=false
    assert(not E:ValidLife(life),'disconnect retires commitment');hero.valid=true
end

dofile(root..'sv_enemy_variance.lua')
D.LODUnifiedVarianceSpawner=nil;dofile(root..'sv_encounter_spawn_variance.lua')
LOD.WanderingDirector={Config={ArchetypeWeights={}}}
dofile(root..'sv_enemy_roster_placement.lua')
pair('censor');D.Entities={};D.activeCount=0
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
local encounter={id=903,cell=cell,cellKey=key(3,3,0),role='arena',sector=2,composition={censor=1,surveyor=1},entities={}}
D.activeCount=LOD.Config.Encounter.ActiveHostileCeiling-1
assert(not D:_SpawnEncounter(encounter) and creates==0,'preflight cap prevents partial cohort')
D.activeCount=0;assert(D:_SpawnEncounter(encounter) and #encounter.entities==2,'both appear through actual production spawn order')
for i,e in ipairs(encounter.entities) do
    assert(e.LODArchetypeId==ids[i] and e.LODEncounterOrdinal==i and e.LODVariance,'stable pre-Spawn identity and independent variance stream')
    assert(e.LODProgressionState.archetypeId==ids[i] and e:GetMaxHealth()==e.LODProgressionState.derivedStats.maxHP,'spawner crosses real progression/HP seam')
    assert(e.nw.LOD_CharacterLevel==e.LODProgressionState.level,'normal replicated actor Level')
end
assert(D:_SpawnEncounter(encounter) and creates==2,'spawn retry cannot duplicate cohort')
for _,name in ipairs({'censor_detail','surveyor_detail'}) do
    assert(table.HasValue(D:_EligibleTemplates(2,'arena'),name) and table.HasValue(D:_EligibleTemplates(2,'ambush'),name))
    assert(not table.HasValue(D:_EligibleTemplates(1,'arena'),name),'sector-one preserves established introductory roster')
    assert(not table.HasValue(D:_EligibleTemplates(3,'reward'),name),'spatial-edict specialist does not enter reward-only path')
    for seed=1,16 do
        local composition=D:_TemplateComposition(name,LOD.RNG.New(seed),4)
        local companion=name=='censor_detail' and 'shambler' or 'soldier'
        assert((composition[companion] or 0)>=1,'authored complementary ordinary body survives enrichment')
        for _,id in ipairs(ids) do
            if composition[id] then assert(composition[id]==1,'party/depth enrichment caps spatial-edict source') end
        end
    end
end
for _,id in ipairs(ids) do
    assert(E:Placement(s.Graph,cell,id,'arena'),'ordinary legal room admits spatial-edict source')
    s.Graph.CellTags[key(3,3,0)]={safe=true}
    assert(not E:Placement(s.Graph,cell,id,'arena'),'safe room rejects spatial-edict source')
    s.Graph.CellTags[key(3,3,0)]={objective=true}
    assert(not E:Placement(s.Graph,cell,id,'arena'),'objective room rejects spatial-edict source')
    s.Graph.CellTags[key(3,3,0)]={}
    s.Graph.VerticalEdges={{a=cell,b=s.Graph.Cells[key(4,3,0)]}}
    assert(not E:Placement(s.Graph,cell,id,'arena'),'vertical transition rejects spatial-edict source')
    s.Graph.VerticalEdges={}
    s.Graph.Progression.Gates={{beforeCell=cell,afterCell=s.Graph.Cells[key(4,3,0)]}}
    assert(not E:Placement(s.Graph,cell,id,'arena'),'progression transition rejects spatial-edict source')
    s.Graph.Progression.Gates={}
    util.TraceHull=function() return {Hit=true,StartSolid=true} end
    assert(not E:Placement(s.Graph,cell,id,'arena'),'blocked native hull rejects spatial-edict source')
    util.TraceHull=clearTrace
end
-- Both spatial-edict identities require lateral room and a legal same-floor exit.
for _,id in ipairs(ids) do
    local c=s.Graph.Cells[key(3,3,0)]
    local neighbors=c.neighbors;c.neighbors={}
    assert(not E:Placement(s.Graph,c,id,'arena'),'no isolated spatial-edict spawn')
    c.neighbors=neighbors
    util.TraceHull=function(t) return {Hit=t.start:Distance(t.endpos)>0,StartSolid=false,HitPos=t.endpos} end
    assert(not E:Placement(s.Graph,c,id,'arena'),'no body-blocked lateral pocket')
    util.TraceHull=clearTrace
end
-- Surveyor requires enough room for the authored refuge/opposing escape,
-- while Censor's fixed line requires only the ordinary lateral pockets.
util.TraceHull=function(t)
    return {Hit=t.start:Distance(t.endpos)>120,StartSolid=false,HitPos=t.endpos}
end
assert(E:Placement(s.Graph,cell,'censor','arena'),'Censor ordinary lateral pocket')
assert(not E:Placement(s.Graph,cell,'surveyor','arena'),'Surveyor cannot trap the Hero within its outer ring')
-- One long escape orientation is enough; requiring both would reject safe rooms.
util.TraceHull=function(t)
    local delta=t.endpos-t.start
    return {Hit=delta.y>120,StartSolid=false,HitPos=t.endpos}
end
assert(E:Placement(s.Graph,cell,'surveyor','arena'),'one refuge/opposite escape orientation suffices')
util.TraceHull=clearTrace
-- An unsafe authored composition becomes the same number of ordinary bodies
-- through the actual shared placement/spawn/progression path.
s.Graph.CellTags[key(3,3,0)]={objective=true}
local fallback={id=904,cell=cell,cellKey=key(3,3,0),role='arena',sector=2,
    composition={censor=1,surveyor=1},entities={}}
assert(D:_SpawnEncounter(fallback) and #fallback.entities==2 and fallback.composition.shambler==2,'illegal spatial-edict sources fall back without body proliferation')
for i,e in ipairs(fallback.entities) do
    assert(e.LODArchetypeId=='shambler' and e.LODEncounterOrdinal==i and e.LODProgressionState.archetypeId=='shambler','fallback keeps ordinary canonical identity')
end
assert(D:_SpawnEncounter(fallback) and creates==4,'fallback retry cannot duplicate bodies')
-- Existing actors retain their earlier ordinals in mixed encounters.
s.Graph.CellTags[key(3,3,0)]={}
local mixed={id=905,cell=cell,cellKey=key(3,3,0),role='arena',sector=2,
    composition={runner=1,wirewright=1,afterburst=1,carrion=1,towline=1,screenwright=1,listener=1,shy=1,absolver=1,exactor=1,outrider=1,conductor=1,siphoner=1,accumulator=1,fusilier=1,bombardier=1,halter=1,pacer=1,interposer=1,mourner=1,censor=1,surveyor=1},entities={}}
assert(D:_SpawnEncounter(mixed) and #mixed.entities==22)
for i,id in ipairs({'runner','wirewright','afterburst','carrion','towline','screenwright','listener','shy','absolver','exactor','outrider','conductor','siphoner','accumulator','fusilier','bombardier','halter','pacer','interposer','mourner','censor','surveyor'}) do
    assert(mixed.entities[i].LODArchetypeId==id and mixed.entities[i].LODEncounterOrdinal==i,'new cohorts append without changing accepted ordinals')
end
print('BESTIARY_B18_PRODUCTION_PASS: physical/Magic class-feat-HP identities; seeded replay; exact-life/graph/progression/campaign/freeze/death/disconnect; shared XP once; cap; production spawn/variance/progression; idempotence; complementary templates; safe/objective/transitions/blocked hull; spatial-edict admission and escape pockets; bounded fallback')
