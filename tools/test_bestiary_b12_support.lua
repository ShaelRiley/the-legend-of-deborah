-- B12 uses production status, support, graph and actor progression; only native
-- entity, trace, registry discovery and transport boundaries are doubled.
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


LOD.HostileRegistry={List=function() return D.Entities end}
dofile(root..'sv_enemy_support.lua')
local S=LOD.EnemySupport
local onClear,onApply
hook.Run=function(event,...)
    if event=='LODStatusCleared' then
        env.hooks.LOD_EnemySupportClear(...)
        if onClear then onClear(...) end
    elseif event=='LODStatusApplied' and onApply then onApply(...) end
end
local function case()
    onClear=nil;onApply=nil
    at(time+10)
    local source,ally=pair('absolver')
    return source,ally
end
local function apply(target,id,duration)
    local ok,_,entry=Status:Apply(target,id,hero,{direct=true,duration=duration or 20})
    assert(ok,'fixture condition: '..id)
    return entry
end
local function begin(source)
    assert(S:Begin(source,hero,time),'eligible cleanse begins')
    return assert(S.Pending[source])
end
local function serviceTo(finish)
    while time<finish do at(math.min(time+.11,finish));S:Service(time,true) end
end
local function finish(source,a)
    serviceTo(a.ready+.11)
    S:Service(time,true)
    assert(not S.Pending[source] and (not IsValid(source) or not source.LODSupportCast),'finite channel retires')
end

local source,ally=case()
assert(not S:Begin(source,hero,time),'healthy condition-free allies are not cleanse targets')
local held=apply(ally,'held');local muted=apply(ally,'muted')
local guard=apply(ally,'support_guard')
local id,entry=Status:FirstNegative(ally)
assert(id=='held' and entry==held,'deterministic lexical condition capture')
id,entry=Status:FirstNegative(ally,{'muted'})
assert(id=='muted' and entry==muted,'optional allowed conditions constrain shared selection')
assert(Status:FirstNegative(ally,{support_guard=true})==nil,'beneficial support is never a negative condition')
local hp=ally.health
local oldHeal=LOD.LootDirector._GrantHealth
LOD.LootDirector._GrantHealth=function() error('cleanse must not heal') end
local oldXP=C.AwardHeroXP
C.AwardHeroXP=function() error('cleanse must not grant XP') end
local clears=0
onClear=function(target,statusId,reason)
    if target==ally and reason=='ally cleanse' then clears=clears+1 end
end
local a=begin(source)
local reserved,reservation=Status:Has(ally,'support_cleansing')
assert(reserved and reservation.expiresAt==time+1.7 and reservation.support==a.records[1])
assert(S:Select(source,'cleanse')[1]==nil,'pending recipient cannot be claimed twice')
local other=actor('absolver',Vector(-20,0,0))
assert(not S:Begin(other,hero,time),'other source cannot stack a pending cleanse')
local start=time
at(a.ready-.001);assert(not S:Resolve(source,a,time) and Status:Has(ally,'held'),'no early release')
at(start);finish(source,a)
assert(not Status:Has(ally,'held') and Status:Has(ally,'muted') and Status:Has(ally,'support_guard'))
assert(not Status:Has(ally,'support_cleansing') and ally.health==hp and clears==1,'one cure only; no HP change; reservation retired')
assert(not S:Resolve(source,a,time) and clears==1,'stale callbacks cannot cleanse again')
assert(not S:Begin(source,hero,time),'fixed cooldown survives release')
LOD.LootDirector._GrantHealth=oldHeal;C.AwardHeroXP=oldXP

-- Exact-entry guard refuses old incarnations and elapsed entries; callbacks can
-- add a replacement without that new condition being consumed by this action.
source,ally=case();held=apply(ally,'held')
Status:Clear(ally,'held','external cure');local replacement=apply(ally,'held')
assert(not Status:ClearExpected(ally,'held',held,'stale cure') and select(2,Status:Has(ally,'held'))==replacement)
assert(Status:ClearExpected(ally,'held',replacement,'current cure') and not Status:Has(ally,'held'))
apply(ally,'held',.01);at(time+.02)
assert(Status:FirstNegative(ally)==nil,'selection expires elapsed negative entries through canonical Has')
source,ally=case();held=apply(ally,'held');a=begin(source)
onClear=function(target,statusId,reason)
    if target==ally and statusId=='support_cleansing' and reason=='cleanse release' then
        Status:Clear(ally,'held','callback replacement');replacement=apply(ally,'held')
    end
end
finish(source,a)
assert(select(2,Status:Has(ally,'held'))==replacement,'reservation callbacks cannot redirect cure to replacement')
source,ally=case();held=apply(ally,'held');a=begin(source);clears=0
onClear=function(target,statusId,reason)
    if target==ally and statusId=='held' and reason=='ally cleanse' then
        clears=clears+1
        assert(not S:Resolve(source,a,time),'release is claimed before removal hook')
        assert(not S:Begin(source,hero,time),'removal callback cannot evade cooldown')
        replacement=apply(ally,'held')
    end
end
finish(source,a)
assert(clears==1 and select(2,Status:Has(ally,'held'))==replacement,'reentrant removal leaves replacement intact')
source,ally=case();apply(ally,'held')
onApply=function(target,statusId)
    if target==ally and statusId=='support_cleansing' then S:Cancel(source) end
end
assert(not S:Begin(source,hero,time) and not S.Pending[source] and not Status:Has(ally,'support_cleansing'),
    'Apply callback cancellation cannot leave an unowned reservation')

-- A nested claim between selection and Apply owns its own reservation; the
-- failed outer Apply returns that entry but must never clear it on cancellation.
source,ally=case();apply(ally,'held');other=actor('absolver',Vector(-20,0,0))
local originalApply=Status.Apply
Status.Apply=function(self,target,statusId,owner,options)
    if statusId=='support_cleansing' and owner==source then
        assert(S:Begin(other,hero,time),'nested source wins reservation before outer Apply')
    end
    return originalApply(self,target,statusId,owner,options)
end
assert(not S:Begin(source,hero,time),'outer duplicate fails')
Status.Apply=originalApply
reserved,reservation=Status:Has(ally,'support_cleansing')
assert(reserved and reservation.source==other and S.Pending[other],'failed outer claim preserves other source reservation')
finish(other,S.Pending[other]);assert(not Status:Has(ally,'held'),'winning nested channel can still resolve')

source,ally=case();apply(ally,'held');a=begin(source)
ally.EmitSound=function(target) assert(IsValid(target),'native cue cannot address a removed recipient') end
onClear=function(target,statusId,reason)
    if target==ally and statusId=='held' and reason=='ally cleanse' then ally.valid=false end
end
finish(source,a)

for _,reason in ipairs({'mute','attack_ban','morale','stun','source_dead','target_dead','source_removed','target_removed',
    'source_life','target_life','hero_life','source_state','target_state','hero_state','hero_dead','freeze','inactive',
    'graph','progression','epoch','run','range','cover','safe','drift','floor','clear','reapply','expire','gap','late'}) do
    source,ally=case();held=apply(ally,'held');muted=apply(ally,'muted');a=begin(source)
    if reason=='mute' then apply(source,'muted')
    elseif reason=='attack_ban' then apply(source,'intimidated')
    elseif reason=='morale' then Status.Active[source]=Status.Active[source] or {};Status.Active[source].morale_flee={id='morale_flee',expiresAt=time+5}
    elseif reason=='stun' then source.LODHitStunUntil=time+5
    elseif reason=='source_dead' then source.LODDead=true
    elseif reason=='target_dead' then ally.LODDead=true
    elseif reason=='source_removed' then source.valid=false
    elseif reason=='target_removed' then ally.valid=false
    elseif reason=='source_life' then Status:ResetActorLife(source)
    elseif reason=='target_life' then Status:ResetActorLife(ally)
    elseif reason=='hero_life' then Status:ResetActorLife(hero)
    elseif reason=='source_state' then source.LODProgressionState=table.Copy(source.LODProgressionState)
    elseif reason=='target_state' then ally.LODProgressionState=table.Copy(ally.LODProgressionState)
    elseif reason=='hero_state' then hero.LODProgressionState=table.Copy(hero.LODProgressionState)
    elseif reason=='hero_dead' then hero.alive=false
    elseif reason=='freeze' then s.SimulationFrozen=true
    elseif reason=='inactive' then source.LODActivated=false
    elseif reason=='graph' then s.Graph=table.Copy(s.Graph)
    elseif reason=='progression' then s.Graph.Progression=table.Copy(s.Graph.Progression)
    elseif reason=='epoch' then s.CampaignEpoch=s.CampaignEpoch+1
    elseif reason=='run' then LOD.RunManager.State=table.Copy(s)
    elseif reason=='range' then ally:SetPos(source:GetPos()+Vector(361,0,0))
    elseif reason=='cover' then util.TraceLine=function(t) return {Hit=true,HitPos=t.start} end
    elseif reason=='safe' then s.Graph.CellTags['3:1:0']={safe=true}
    elseif reason=='drift' then source:SetPos(source:GetPos()+Vector(8.01,0,0))
    elseif reason=='floor' then
        local upper={x=3,y=1,z=1,neighbors={}};s.Graph.Cells['3:1:1']=upper;s.Graph.Layers=2
        source:SetPos(LOD.MazeNavigator:CellCenter(upper));ally:SetPos(source:GetPos()+Vector(100,0,0))
    elseif reason=='clear' then Status:Clear(ally,'held','external cure')
    elseif reason=='reapply' then Status:Clear(ally,'held','external cure');replacement=apply(ally,'held')
    elseif reason=='expire' then held.expiresAt=time+.1
    elseif reason=='gap' then at(time+.251)
    elseif reason=='late' then at(a.ready+.201) end
    clears=0;onClear=function(_,_,why) if why=='ally cleanse' then clears=clears+1 end end
    finish(source,a)
    assert(clears==0 and not S.Pending[source],'invalidated cleanse cannot remove a condition: '..reason)
    assert(not (Status.Active[ally] and Status.Active[ally].support_cleansing),'reservation retired: '..reason)
    if reason=='reapply' then assert(select(2,Status:Has(ally,'held'))==replacement) end
    s.Graph.CellTags={};LOD.RunManager.State=s
end

source,ally=case();apply(source,'held');apply(ally,'muted');a=begin(source);finish(source,a)
assert(not Status:Has(ally,'muted'),'Held permits stationary magical support')
source,ally=case();apply(ally,'muted');source:SetPos(source:GetPos()+Vector(8,0,0));a=begin(source)
source:SetPos(source:GetPos()+Vector(-8,0,0));finish(source,a)
assert(not Status:Has(ally,'muted'),'eight-unit source tolerance is inclusive')

for _,field in ipairs({'LODSkeletonHero','LODHector','LODWardenClone','LODDead'}) do
    source,ally=case();apply(ally,'held');ally[field]=true
    assert(not S:Begin(source,hero,time),'event/corpse exclusion '..field)
end
for _,boss in ipairs({'warden','neil','brute','hector'}) do
    source,ally=case();apply(ally,'held');ally.LODArchetypeId=boss
    assert(not S:Begin(source,hero,time),'boss exclusion '..boss)
end
source,ally=case();apply(ally,'held');ally.player=true
assert(not S:Begin(source,hero,time),'players cannot receive enemy cleanse even with hostile marker')
source,ally=case();ally.health=0
assert(not S:Begin(source,hero,time),'cannot revive corpses')
source,ally=case();apply(source,'held');D.Entities={source}
assert(not S:Begin(source,hero,time),'cannot cleanse itself')
source,ally=case();apply(ally,'held');hero:SetPos(source:GetPos()+Vector(601,0,0))
assert(not S:Begin(source,hero,time),'visible Hero within 600 is required at acquisition')
hero:SetPos(source:GetPos()+Vector(160,0,0))
source,ally=case();apply(ally,'held')
LOD.RPGPerceptionState={IsInvisible=function(_,p) return p==hero end}
assert(not S:Begin(source,hero,time),'invisible Hero cannot trigger support acquisition')
LOD.RPGPerceptionState=nil

source,ally=case();apply(ally,'held')
local sources={}
for i=1,17 do
    local healer=actor('absolver',Vector(-10,0,0));local target=actor('runner',Vector(100,0,0))
    apply(target,'held');D.Entities={healer,target};sources[i]=healer
    if i<=16 then assert(S:Begin(healer,hero,time),'within simultaneous cap')
    else assert(not S:Begin(healer,hero,time),'seventeenth cleanse is rejected before reservation') end
end
S:Cancel(sources[1]);assert(S:Begin(sources[17],hero,time),'retired commitment frees its slot')
local scanned=0;local originalEligible=S.Eligible
S.Eligible=function(self,...) scanned=scanned+1;return originalEligible(self,...) end
D.Entities={};for i=1,180 do D.Entities[i]=ally end
S:Select(source,'cleanse');assert(scanned==128,'cleanse retains bounded cached registry scan');S.Eligible=originalEligible
print('BESTIARY_B12_SUPPORT_PASS: exact one-condition cure; canonical status capture/removal; beneficial preservation; no HP/XP; eligibility; life/run/floor/entry invalidation; strict service gap/deadline; reservation/cap/reentrant cleanup; Held magic')
