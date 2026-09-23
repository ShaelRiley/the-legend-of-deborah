-- B2 executes shared progression, healing, status, mitigation, target selection,
-- and encounter spawning. Only native entities/traces/transport are doubled.
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
dofile(root..'sh_equipment.lua');dofile(root..'sh_equipment_catalog.lua')
dofile(root..'sv_rpg_block.lua');dofile(root..'sv_loot_director.lua')
dofile(root..'sv_enemy_roster.lua')
local E,D,C,Status,Rules=LOD.EnemyRoster,LOD.EncounterDirector,LOD.CharacterProgressionSystem,LOD.RPGStatusElements,LOD.RPGAbilityRules
local time,serial=200,100
local function at(n) time=n;env.setTime(n) end
at(time)
local s=LOD.RunManager.State
s.BuildReady=true;s.Failed=false;s.LevelCleared=false;s.SimulationFrozen=false;s.Level=8
s.CampaignEpoch=1;s.RunId='b2';s.CampaignSeed=77;s.LevelSeed=123
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
local function pair(id)
    reset();local source=actor(id);local ally=actor('runner',Vector(100,0,0))
    E:Prepare(source);D.Entities={source,ally};source.LODTarget=hero
    return source,ally
end

-- B2 behavior cases follow below; the progression/spawn boundary is exercised
-- with the same production actor state instead of replacing it with a fixture.
local ids={'stitcher','bulwark','cantor'}
local expected={stitcher={die=6,xp=50,magic=true},bulwark={die=10,xp=60,magic=true},cantor={die=8,xp=50,magic=false}}
for _,id in ipairs(ids) do
    local def=expected[id]
    for seed=1,16 do
        local generated=assert(C:GenerateMonsterProgression(id,72000+seed,8,45,'ai'))
        local replay=assert(C:GenerateMonsterProgression(id,72000+seed,8,45,'ai'))
        assert(generated.archetypeId==id and generated.usesMagic==def.magic,'must not silently fall back to a legacy archetype')
        assert(generated.progressionHitDieSides==def.die and generated.level>=9 and #generated.featIds>0)
        assert(generated.derivedStats.maxHP>45 and generated.derivedStats.maxHP==replay.derivedStats.maxHP
            and generated.classId==replay.classId and table.concat(generated.featIds,',')==table.concat(replay.featIds,','),'independent seeded generation replay')
        assert(C:_HasCapability({},generated,'pushable_weapon'),'weak physical fallback retains applicable attack feats')
        assert(not C:_HasCapability({},generated,'offensive_magic_activation'),'support-only powers cannot unlock unusable offensive Magic feats')
        if id=='cantor' then assert(generated.classId~='wizard','nonmagical Cantor must not roll Wizard') end
    end
    local hostile=actor(id);local awards=0
    C.AwardHeroXP=function(_,identity,amount) assert(identity=='tester');awards=awards+amount;return true end
    local attribution=LOD.CombatAttributionSystem
    attribution.Ledgers[hostile]={effectiveDamageByHeroId={tester=100},killingBlowHeroId='tester'}
    local xp=math.max(5,5*math.floor((def.xp*(1+.05*(hostile.LODProgressionState.level-1)))/5+.5))
    assert(attribution:Settle(hostile) and hostile.LODRPGXPSettlement.value==xp and awards==xp,'shared level-scaled XP')
    assert(not attribution:Settle(hostile) and awards==xp,'single reward settlement')
end
dofile(root..'sv_enemy_variance.lua')
D.LODUnifiedVarianceSpawner=nil;dofile(root..'sv_encounter_spawn_variance.lua')
LOD.WanderingDirector={Config={ArchetypeWeights={}}}
dofile(root..'sv_enemy_roster_placement.lua')
D.Entities={};D.activeCount=0
local creates=0
ents.Create=function(class)
    assert(class=='lod_hostile');creates=creates+1
    local e=actor('runner');e.LODProgressionState=nil
    e.Spawn=function(self)
        self.LODConfig=table.Copy(LOD.Config.Encounter.Archetypes[self.LODArchetypeId])
        self.maximum=self.LODConfig.baseHP;self.health=self.maximum
        -- Native Initialize is the engine boundary; production spawner's real
        -- variance fallback must attach the actual canonical progression.
    end
    return e
end
local cell=s.Graph.Cells['3:1:0']
local encounter={id=902,cell=cell,cellKey='3:1:0',role='arena',sector=2,composition={stitcher=1,bulwark=1,cantor=1},entities={}}
D.activeCount=LOD.Config.Encounter.ActiveHostileCeiling-2
assert(not D:_SpawnEncounter(encounter) and creates==0,'preflight cap prevents partial cohort')
D.activeCount=0;assert(D:_SpawnEncounter(encounter) and #encounter.entities==3,'all three appear through actual production spawn order')
for i,e in ipairs(encounter.entities) do
    assert(e.LODArchetypeId==ids[i] and e.LODEncounterOrdinal==i and e.LODVariance,'stable pre-Spawn identity and independent variance stream')
    assert(e.LODProgressionState.archetypeId==ids[i] and e:GetMaxHealth()==e.LODProgressionState.derivedStats.maxHP,'spawner crosses real progression/HP seam')
    assert(e.nw.LOD_CharacterLevel==e.LODProgressionState.level,'normal replicated actor Level')
end
assert(D:_SpawnEncounter(encounter) and creates==3,'spawn retry cannot duplicate cohort')
for _,name in ipairs({'stitcher_detail','bulwark_line','cantor_charge'}) do
    assert(table.HasValue(D:_EligibleTemplates(2,'arena'),name) and table.HasValue(D:_EligibleTemplates(2,'ambush'),name))
    assert(not table.HasValue(D:_EligibleTemplates(1,'arena'),name),'sector-one preserves established introductory roster')
end
print('BESTIARY_B2_PRODUCTION_PASS: own class/feat/HP identities; deterministic replay; capability eligibility; shared XP; cap; production spawn/variance/progression; idempotence; canonical templates')

-- Cached registry enumeration is the engine discovery boundary; all eligibility,
-- sorting, graph distances, status ownership and health changes remain real.
LOD.HostileRegistry={List=function() return D.Entities end}
dofile(root..'sv_enemy_support.lua')
local S=LOD.EnemySupport
hook.Run=function(event,...)
    if event=='LODStatusCleared' then env.hooks.LOD_EnemySupportClear(...) end
end
local function start(source)
    assert(S:Begin(source,hero,time),'eligible support must create a playable commitment')
    return assert(source.LODSupportCast)
end
local function resolve(source,a)
    at(a.ready+.01);S:Service(time,true)
    assert(not S.Pending[source] and (not IsValid(source) or not source.LODSupportCast),'one release retires commitment/warning')
end
local source,ally=pair('stitcher');ally.health=math.floor(ally.maximum/2)
local hp=ally.health;local a=start(source)
local secondStitcher=actor('stitcher',Vector(-20,0,0))
assert(not S:Begin(secondStitcher,hero,time),'mending reservation prevents simultaneous heal stacking')
at(a.ready-.001);S:Resolve(source,a,time);assert(ally.health==hp,'cannot bypass healing windup')
resolve(source,a)
assert(ally.health==hp+math.min(24,math.ceil(ally.maximum*.12)),'bounded actual restoration through canonical Loot health authority')
local restored=ally.health;S:Resolve(source,a,time);assert(ally.health==restored,'repeat release cannot repeat heal')
assert(not S:Begin(source,hero,time),'recovery cooldown cannot be bypassed')
source,ally=pair('stitcher');ally.health=ally.maximum-1;a=start(source);resolve(source,a)
assert(ally.health==ally.maximum,'near-full healing never exceeds canonical maximum')
source,ally=pair('stitcher');ally.health=0;assert(not S:Begin(source,hero,time),'corpses cannot be revived')
source,ally=pair('stitcher');assert(not S:Begin(source,hero,time),'full-health allies do not waste healing casts')

-- Interrupt every role before release, with distinct Mute semantics for a voice
-- rally versus magical healing/protection; no delayed effect may survive.
for _,id in ipairs(ids) do
    for _,reason in ipairs({'stun','dead','removed','recipient_dead','recipient_removed','freeze','same_seed_graph','same_seed_progression','source_identity','recipient_identity','reset'}) do
        source,ally=pair(id);ally.health=math.floor(ally.maximum/2);hp=ally.health;a=start(source)
        if reason=='stun' then source.LODHitStunUntil=time+5
        elseif reason=='dead' then source.LODDead=true
        elseif reason=='removed' then source.valid=false
        elseif reason=='recipient_dead' then ally.LODDead=true
        elseif reason=='recipient_removed' then ally.valid=false
        elseif reason=='freeze' then s.SimulationFrozen=true
        elseif reason=='same_seed_graph' then s.Graph=table.Copy(s.Graph)
        elseif reason=='same_seed_progression' then s.Graph.Progression=table.Copy(s.Graph.Progression)
        elseif reason=='source_identity' then source.LODProgressionState=table.Copy(source.LODProgressionState)
        elseif reason=='recipient_identity' then ally.LODProgressionState=table.Copy(ally.LODProgressionState)
        elseif reason=='reset' then s.CampaignEpoch=s.CampaignEpoch+1 end
        resolve(source,a)
        assert(ally.health==hp and not Status:Has(ally,'support_guard') and not Status:Has(ally,'support_rally'),id..' stale commitment: '..reason)
    end
    source,ally=pair(id);ally.health=math.floor(ally.maximum/2);a=start(source)
    Status:Apply(source,'muted',hero,{direct=true,duration=10})
    resolve(source,a)
    if id=='cantor' then assert(Status:Has(ally,'support_rally'),'nonmagical rally keeps its distinct Mute behavior')
    else assert(not Status:Has(ally,'support_guard') and ally.health<ally.maximum/2+1,'Mute interrupts magical support') end
end

-- Selection is bounded, stable, living, faction-safe, same-floor, graph/cover
-- checked, and recovery chooses injury fraction rather than raw HP.
source,ally=pair('stitcher');ally.health=math.floor(ally.maximum*.7)
local injured=actor('runner',Vector(110,0,0));injured.health=math.floor(injured.maximum*.2)
D.Entities={source,ally,injured};assert(S:Select(source,'recovery')[1]==injured)
assert(not S:Eligible(source,source,360),'no self support')
for _,field in ipairs({'LODDead','LODSkeletonHero','LODHector','LODWardenClone'}) do
    ally[field]=true;assert(not S:Eligible(source,ally,360),'excluded lifecycle/event role '..field);ally[field]=nil
end
for _,id in ipairs({'warden','neil','brute','hector'}) do
    local old=ally.LODArchetypeId;ally.LODArchetypeId=id;assert(not S:Eligible(source,ally,360),'boss exclusion '..id);ally.LODArchetypeId=old
end
ally.LODActivated=false;assert(not S:Eligible(source,ally,360));ally.LODActivated=true
ally.LODHostile=false;assert(not S:Eligible(source,ally,360));ally.LODHostile=true
local original=ally:GetPos();ally:SetPos(source:GetPos()+Vector(361,0,0));assert(not S:Eligible(source,ally,360),'range cutoff');ally:SetPos(original)
util.TraceLine=function(t) return {Hit=true,HitPos=t.start} end;assert(not S:Eligible(source,ally,360),'physical cover');util.TraceLine=clearTrace
local from=LOD.MazeNavigator:WorldToCell(s.Graph,source:GetPos())
local to=s.Graph.Cells['4:1:0'];ally:SetPos(LOD.MazeNavigator:CellCenter(to))
assert(S:Eligible(source,ally,1000),'neighbor geometry valid')
s.Graph.Progression.Gates={{edgeKey=LOD.MazeNavigator:EdgeKey(from,to)}};s.GatesOpen={}
assert(not S:Eligible(source,ally,1000),'closed progression gate blocks support even if native trace says clear')
s.Graph.Progression.Gates={};ally:SetPos(original)
local upper={x=3,y=1,z=1,neighbors={}};s.Graph.Cells['3:1:1']=upper;s.Graph.Layers=2
ally:SetPos(LOD.MazeNavigator:CellCenter(upper))
assert(not S:Eligible(source,ally,1000),'open trace cannot heal through another floor');ally:SetPos(original)
local scanned=0;local originalEligible=S.Eligible
S.Eligible=function(self,...) scanned=scanned+1;return originalEligible(self,...) end
D.Entities={};for i=1,180 do D.Entities[i]=ally end
S:Select(source,'recovery');assert(scanned==128,'support cannot scan an unbounded registry');S.Eligible=originalEligible

-- Protection enters the existing block resolver and its cap, deduplicates an
-- attack event, and does not alter the canonical magical bypass.
source,ally=pair('bulwark');a=start(source);resolve(source,a)
local applied,entry=Status:Has(ally,'support_guard');assert(applied and entry.source==source)
local expires=entry.expiresAt
local other=actor('bulwark',Vector(-50,0,0));D.Entities[#D.Entities+1]=other
D.Entities={ally}
assert(not S:Begin(other,hero,time),'active guard cannot stack/refresh from another source')
ally.LODProgressionState.equipmentBlockChanceContribution=.2
assert(Rules:BlockChance(ally)==.33,'support respects production 33 percent Block cap')
local count=0;local oldRNG=LOD.CombatRolls._RNG
LOD.CombatRolls._RNG=function() return {Float=function() count=count+1;return .1 end} end
local function info()
    return {damage=10,GetDamage=function(self) return self.damage end,SetDamage=function(self,n) self.damage=n end,
        GetAttacker=function() return hero end,SetDamageForce=noop,IsDamageType=function(_,kind) return kind==DMG_BULLET end}
end
local event={};local hit=info();Status:AttachDamageContext(hit,{physical=true,attackEvent=event})
assert(Rules:ApplyBlock(ally,hit) and hit.damage==0)
hit=info();Status:AttachDamageContext(hit,{physical=true,attackEvent=event})
assert(Rules:ApplyBlock(ally,hit) and count==1,'one defender roll per shared attack event')
hit=info();Status:AttachDamageContext(hit,{magic=true})
assert(not Rules:ApplyBlock(ally,hit) and hit.damage==10 and count==1,'magic remains unblockable')
LOD.CombatRolls._RNG=oldRNG
Status:Apply(ally,'muted',hero,{direct=true,duration=10})
assert(Status:CureNegative(ally)==1 and Status:Has(ally,'support_guard'),'remedy preserves beneficial entries')
at(expires);assert(not Status:Has(ally,'support_guard') and Rules:BlockChance(ally)==.2,'shared expiry removes protection exactly')

for _,id in ipairs({'bulwark','cantor'}) do
    local statusId=id=='bulwark' and 'support_guard' or 'support_rally'
    for _,reason in ipairs({'source_dead','source_removed','recipient_dead','recipient_removed','source_identity','recipient_identity','graph','progression','epoch','source_life','recipient_life','range','cover','stun'}) do
        source,ally=pair(id);a=start(source);resolve(source,a);assert(Status:Has(ally,statusId))
        if reason=='source_dead' then source.LODDead=true
        elseif reason=='source_removed' then source.valid=false
        elseif reason=='recipient_dead' then ally.LODDead=true
        elseif reason=='recipient_removed' then ally.valid=false
        elseif reason=='source_identity' then source.LODProgressionState=table.Copy(source.LODProgressionState)
        elseif reason=='recipient_identity' then ally.LODProgressionState=table.Copy(ally.LODProgressionState)
        elseif reason=='graph' then s.Graph=table.Copy(s.Graph)
        elseif reason=='progression' then s.Graph.Progression=table.Copy(s.Graph.Progression)
        elseif reason=='epoch' then s.CampaignEpoch=s.CampaignEpoch+1
        elseif reason=='source_life' then Status:ResetActorLife(source)
        elseif reason=='recipient_life' then Status:ResetActorLife(ally)
        elseif reason=='range' then ally:SetPos(source:GetPos()+Vector(500,0,0))
        elseif reason=='cover' then util.TraceLine=function(t) return {Hit=true,HitPos=t.start} end
        elseif reason=='stun' then source.LODHitStunUntil=time+5 end
        assert(not Status:Has(ally,statusId),id..' expired ownership '..reason)
    end
end

source,ally=pair('cantor');local allies={ally}
for i=2,6 do allies[i]=actor('runner',Vector(50+i*10,0,0));D.Entities[#D.Entities+1]=allies[i] end
a=start(source);assert(#a.records==3,'rally has exactly three recipients at most');resolve(source,a)
local recipient=a.records[1].target
local nearer=actor('runner',Vector(20,0,0));nearer.player=true;nearer.LODHostile=false
player.GetAll=function() return {nearer,hero} end
local home=LOD.MazeNavigator:WorldToCell(s.Graph,recipient:GetPos())
assert(LOD.FactionManager:BestTarget(recipient,s.Graph,home)==hero,'rally changes real group targeting from closer Hero to marked Hero')
hero.LODProgressionState=table.Copy(hero.LODProgressionState)
assert(not Status:Has(recipient,'support_rally'),'replaced Hero identity cannot remain a rally target')
assert(LOD.FactionManager:BestTarget(recipient,s.Graph,home)==nearer,'normal acquisition resumes when rally retires')
player.GetAll=function() return {hero} end
source,ally=pair('cantor');a=start(source);resolve(source,a)
local _,rally=Status:Has(ally,'support_rally');at(rally.expiresAt)
assert(not Status:Has(ally,'support_rally'),'rally uses exact shared expiry')
source,ally=pair('cantor');a=start(source);resolve(source,a);Status:ResetActorLife(hero)
assert(not Status:Has(ally,'support_rally'),'same Hero entity in a new life retires rally')
print('BESTIARY_B2_SUPPORT_PASS: bounded recovery; canonical heal/block/status/targeting; interruption; range/LOS/gates; capped selection; nonstack; exact expiry; source/recipient/Hero life identity; same-seed dungeon replacement')
