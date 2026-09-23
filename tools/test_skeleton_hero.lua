-- Real canonical catalog/generation/combat functions; Source boundaries only.
dofile('tools/test_checkpoint_d_closure.lua')
local root='gamemodes/legend_of_deborah/gamemode/lod/'
CurTime=function() return 100 end
local noop=function() end
ErrorNoHalt=function(message) io.stderr:write(message) end
net.Start=noop;net.Send=noop;net.WriteString=noop;net.WriteBool=noop;net.Broadcast=noop
local vm={};vm.__index=vm
function Vector(x,y,z) return setmetatable({x=x or 0,y=y or 0,z=z or 0},vm) end
function vm.__add(a,b) return Vector(a.x+b.x,a.y+b.y,a.z+b.z) end
function vm.__sub(a,b) return Vector(a.x-b.x,a.y-b.y,a.z-b.z) end
function vm.__mul(a,b) return Vector(a.x*b,a.y*b,a.z*b) end
function vm:LengthSqr() return self.x*self.x+self.y*self.y+self.z*self.z end
function vm:Length() return math.sqrt(self:LengthSqr()) end
function vm:Length2D() return math.sqrt(self.x*self.x+self.y*self.y) end
function vm:GetNormalized() return self*(1/math.max(.001,self:Length())) end
function vm:Dot(b) return self.x*b.x+self.y*b.y+self.z*b.z end
function vm:DistToSqr(b) return (self-b):LengthSqr() end
vector_origin=Vector()
IsValid=function(e) return type(e)=='table' and e.valid==true end
util.TableToJSON=function() return '{}' end
util.IsValidModel=function(model) return model=='models/player/skeleton.mdl' end
util.TraceLine=function(t) return {Hit=false,Fraction=1,HitPos=t.endpos} end
ACT_WALK,ACT_RUN,ACT_IDLE,ACT_RANGE_ATTACK1=1,2,3,4
DMG_ENERGYBEAM,DMG_BURN,DMG_POISON,DMG_SLASH,MASK_SOLID=1,2,4,8,16
LOD.RunManager={State={Level=18,LevelSeed=18181,CampaignSeed=44,BuildReady=true},GetPlayerState=function(_,e) return e.ps end}
dofile(root..'sv_combat_rolls.lua')
dofile(root..'sv_combat_feed_semantics.lua')
game={GetWorld=function() return nil end}
dofile(root..'sv_enemy_melee_dice_balance.lua')
dofile(root..'sv_magic.lua')
dofile(root..'sv_enemy_roster.lua')
local P=LOD.CharacterProgressionSystem
local baseline=P:GenerateMonsterProgression('soldier',8721,8,40,'ai')
dofile(root..'sv_skeleton_hero.lua')
local S=LOD.SkeletonHero
-- The lifecycle suite exercises real EventSkeletonBlockade.Owned. Here its
-- boundary is an exact-entity fixture so combat/generation remain isolated.
LOD.EventDirector={}
LOD.EventSkeletonBlockade={Owned=function(_,i) return i.current and i.hostile.valid end}

local ordinary=P:GenerateMonsterProgression('soldier',8721,8,40,'ai')
assert(ordinary.level==baseline.level and ordinary.classId==baseline.classId)
assert(table.concat(ordinary.featIds,',')==table.concat(baseline.featIds,','),'ordinary enemy draft changed')
local profiles,classes={},{}
for seed=1,60 do
    for _,dungeon in ipairs({1,18,100}) do
        local state=S:Generate(seed,dungeon)
        profiles[state.classId]=state;classes[state.classId]=true
        assert(state.actorType=='ai' and state.skeletonHero and state.level==math.min(20,dungeon+2))
        assert(state.startingHP==100 and state.progressionHitDieSides==LOD.RPG.Classes[state.classId].heroProgressionHitDieSides)
        assert(state.baseAbilityRollAudit.rawTotal>=74 and #state.baseAbilityRollAudit.penalties==3)
        local rolled=LOD.HeroAbilityRolls:Generate(LOD.Seeds.Derive(seed,'skeleton:abilities'))
        for _,ability in ipairs(LOD.RPG.Abilities) do assert(state.baseAbilities[ability]==rolled[ability]) end
        assert(state.skeletonName=='Skeleton of '..state.characterIdentityPackage.fullDisplayName)
        assert(#state.magicFormIds==0,'unusable player form granted')
        assert(state.classId=='wizard' and #state.contentIds==(state.level>=14 and 4 or state.level>=8 and 3 or state.level>=4 and 2 or 1)
            or state.classId~='wizard' and #state.contentIds==0,'Content schedule/controller mismatch')
        for level=2,state.level do assert(state.hitDieRollsByLevel[level] and state.hitDieRollsByLevel[level].sides==state.progressionHitDieSides) end
        if state.level==20 then assert(state.classCapstoneFeatId) end
        for _,id in ipairs(state.featIds) do
            local def=P:_FindFeat(id)
            local supported=#(def.allowedActorTypes or {})==0
            for _,kind in ipairs(def.allowedActorTypes or {}) do supported=supported or kind=='ai' end
            assert(supported,'player-only feat granted: '..id)
        end
        local again=S:Generate(seed,dungeon)
        assert(again.skeletonName==state.skeletonName and table.concat(again.featIds,',')==table.concat(state.featIds,','))
        assert(again.derivedStats.maxHP==state.derivedStats.maxHP)
    end
end
assert(classes.fighter and classes.rogue and classes.wizard)
for class,profile in pairs(profiles) do
    assert(P:_HasCapability({},profile,'firearm')==(class=='rogue'))
    assert(P:_HasCapability({},profile,'magic_pool')==(class=='wizard'))
    assert(not P:_HasCapability({},profile,'magic_form_owned'))
end
local nextID=0
local function actor(profile,hero)
    nextID=nextID+1
    local e={valid=true,nw={},hp=500,maxhp=500,id=nextID,LODProgressionState=profile,
        LODHostile=not hero,LODSkeletonHero=not hero,LODArchetypeId=profile.archetypeId,player=hero}
    if hero then e.ps={progressionState=profile} end
    function e:IsPlayer() return self.player==true end
    function e:EntIndex() return self.id end
    function e:GetCreationID() return self.id end
    function e:GetClass() return self.player and 'player' or 'lod_hostile' end
    function e:Health() return self.hp end
    function e:GetMaxHealth() return self.maxhp end
    function e:SetHealth(v) self.hp=v end
    function e:SetMaxHealth(v) self.maxhp=v end
    function e:Alive() return self.hp>0 end
    function e:GetPos() return self.pos or Vector() end
    function e:SetPos(p) self.pos=p end
    function e:WorldSpaceCenter() return self:GetPos()+Vector(0,0,32) end
    function e:GetForward() return Vector(1,0,0) end
    function e:GetVelocity() return Vector() end
    function e:GetNW2Bool(k,d) return self.nw[k] or d end
    e.GetNW2Float=e.GetNW2Bool;e.GetNW2String=e.GetNW2Bool;e.GetNW2Int=e.GetNW2Bool
    function e:SetNW2Bool(k,v) self.nw[k]=v end
    e.SetNW2Float=e.SetNW2Bool;e.SetNW2Int=e.SetNW2Bool;e.SetNW2String=e.SetNW2Bool;e.SetNW2Vector=e.SetNW2Bool
    e.EmitSound=noop;e._SetActivity=noop
    function e:Nick() return 'Tester' end
    function e:GetModel() return S.Model end
    function e:OnGround() return true end
    function e:GetWalkSpeed() return 200 end
    function e:GetRunSpeed() return 400 end
    function e:GetMoveType() return 2 end
    function e:GetNWString(_,fallback) return fallback end
    return e
end
local wizard=actor(profiles.wizard)
wizard.LODConfig=table.Copy(LOD.Config.Encounter.Archetypes.arccaster)
local targetState=P:NewProgressionState('testHero','hero','hero');targetState.classId='fighter';targetState.baseAbilities=LOD.RPG.NewAbilityBlock(10)
P:_RecomputeProgressionState(targetState)
local target=actor(targetState,true)
target:SetPos(Vector(80,0,0))
local E=LOD.EnemyRoster
wizard.LODEventInstance={hostile=wizard,current=true}
-- The real pool, cost and Arc warning/release transaction.
LOD.Magic:_EnsureState(wizard).magic=100
local first=S:ArcContent(wizard)
E:Begin(wizard,target,100)
local attack=assert(wizard.LODRosterAttack)
assert(attack.skeletonContent==first and not attack.released)
local cost=S:ArcCost(wizard,first)
E:Release(wizard,attack,102)
assert(attack.skeletonPaid and wizard.LODProgressionState.magic==100-cost)
E:Release(wizard,attack,102)
assert(wizard.LODProgressionState.magic==100-cost,'duplicate release double-spent')
assert(wizard.LODSkeletonArcSerial==1)
LOD.Magic:_EnsureState(wizard).magic=0;E:Cancel(wizard)
assert(E:Begin(wizard,target,110)==false and not wizard.LODRosterAttack,'empty pool cast')
LOD.Magic:_EnsureState(wizard).magic=100;E:Begin(wizard,target,112)
local cancelled=wizard.LODRosterAttack
LOD.Magic:_EnsureState(wizard).magic=0
E:Release(wizard,cancelled,114)
assert(not cancelled.released and not wizard.LODRosterAttack,'shield-drained pool released illegally')
-- Native synchronization may reenter release or tear down the exact dungeon.
-- Claiming before it runs prevents a second debit/serial and stale emission.
local sync=LOD.Magic._Sync
LOD.Magic:_EnsureState(wizard).magic=100
E:Begin(wizard,target,116)
local reentrant=wizard.LODRosterAttack
local serial=wizard.LODSkeletonArcSerial
local reentrantCost=S:ArcCost(wizard,reentrant.skeletonContent)
local syncCalls=0
function LOD.Magic:_Sync(ent,pool)
    syncCalls=syncCalls+1
    E:Release(ent,reentrant,118)
    return sync(self,ent,pool)
end
E:Release(wizard,reentrant,118)
assert(syncCalls==1 and reentrant.released and reentrant.skeletonPaid)
assert(wizard.LODProgressionState.magic==100-reentrantCost and wizard.LODSkeletonArcSerial==serial+1)
LOD.Magic._Sync=sync
LOD.Magic:_EnsureState(wizard).magic=100;E:Cancel(wizard)
E:Begin(wizard,target,120)
local tornDown=wizard.LODRosterAttack
function LOD.Magic:_Sync(ent,pool)
    ent.LODEventInstance.current=false -- identical seed is deliberately retained
    E:Cancel(ent)
    return sync(self,ent,pool)
end
E:Release(wizard,tornDown,122)
assert(tornDown.skeletonPaid and not tornDown.released and not wizard.LODRosterAttack)
LOD.Magic._Sync=sync;wizard.LODEventInstance.current=true
LOD.Magic:_EnsureState(wizard).magic=100;E:Begin(wizard,target,124)
local removedDuringSync=wizard.LODRosterAttack
function LOD.Magic:_Sync(ent) ent.valid=false end
E:Release(wizard,removedDuringSync,126)
assert(removedDuringSync.skeletonPaid and not removedDuringSync.released)
LOD.Magic._Sync=sync;wizard.valid=true;E:Cancel(wizard)

-- Resolve generated classes through the actual shared dice/stat authority.
local rolls,rules,status=LOD.CombatRolls,LOD.RPGAbilityRules,LOD.RPGStatusElements
for class,profile in pairs(profiles) do
    local source=actor(profile)
    local damageProfile=rolls:HostileDamageProfile(profile.archetypeId)
    local contract=rolls:RollHostileAttack(source,damageProfile,damageProfile.reference)
    local amount=rolls:ResolveActorDamage(contract,source,target,{physical=class~='wizard',magic=class=='wizard'})
    assert(amount>=0 and contract.feedResolution,'generated class bypassed shared combat')
    assert(rules:Derived(source)==profile.derivedStats)
end
function DamageInfo()
    local info={}
    for _,field in ipairs({'Attacker','Inflictor','Damage','DamageType','DamagePosition'}) do
        info['Set'..field]=function(self,value) self[field]=value end
        info['Get'..field]=function(self) return self[field] end
    end
    function info:IsDamageType(kind) return self.DamageType==kind end
    return info
end
LOD.FactionManager={IsValidPlayerTarget=function(_,e) return e==target end}
local received
function target:TakeDamageInfo(info)
    received=status:DamageContext(info,self)
    self.hp=self.hp-math.min(self.hp,info:GetDamage())
end
-- Arc retains canonical Content tags and saves; no invented status API.
for _,id in ipairs({'fire','dark','ice','light','electric'}) do
    target.hp=500
    local event={skeletonContent=LOD.RPG.MagicContents[id]}
    E:Damage(wizard,target,event,'arc')
    assert(target.hp<500 and received.magic and received.element==id)
    assert(received.actorDamageResolved and received.damageContract and received.attackEvent)
    local rider=LOD.RPG.MagicContents[id].rider
    assert(rider=='morale' and received.forceMorale or received.riderStatusId==rider)
    if rider~='morale' then assert(received.riderDC) end
end
-- DEX changes the native hostile movement target and the same dodge threshold;
-- status/Rogue factors remain separate, and ordinary hostiles retain old speed.
local fighter=actor(profiles.fighter)
fighter.LODConfig={speed=100}
local expected=profiles.fighter.derivedStats.movementSpeedMultiplier
assert(rules:HostileDexMovementMultiplier(fighter)==expected)
local _,walk=rules:DodgeMovement(fighter)
assert(math.abs(walk-100*expected)<.00001)
fighter.LODSkeletonHero=false
assert(rules:HostileDexMovementMultiplier(fighter)==1)
local _,oldWalk=rules:DodgeMovement(fighter);assert(oldWalk==100)
fighter.LODSkeletonHero=true;fighter.hp=1;fighter.LODRPGHealthRegenEligibleAt=0
LOD.RPG.FeatEffectSystem:_TickActor(fighter,1)
assert(fighter.hp>1,'Fighter innate/feat regeneration inert')
-- Stale identities cannot spend or damage even with a reused dungeon seed.
wizard.LODEventInstance.current=false
wizard.LODProgressionState.magic=100
local before=target.hp
E:Damage(wizard,target,{skeletonContent=LOD.RPG.MagicContents.fire},'arc')
assert(target.hp==before and not S:CanBeginArc(wizard,120))
assert(not S:CommitArc(wizard,{event={},skeletonContent=first}))
assert(wizard.LODProgressionState.magic==100)
wizard.LODEventInstance.current=true
local oldHostile=wizard.LODEventInstance.hostile
wizard.LODEventInstance.hostile=actor(profiles.wizard)
assert(not S:Live(wizard),'replacement entity confused ownership')
wizard.LODEventInstance.hostile=oldHostile
-- Actual production Spawn uses only real native APIs, tracks before Spawn, and
-- applies the Hero profile after the native hostile Initialize HP/config writes.
local spawned,trackedBeforeSpawn
local events={Track=function(_,i,e)
    if not i.current then return false end
    e.LODEventInstance=i
    if not i.entities[1] then i.entities[1]=e end
    return true
end}
LOD.MazeBuilder={CellCenter=function(_,c) return Vector(c.x,c.y,c.z) end}
ents={Create=function(class)
    assert(class=='lod_hostile')
    local e=actor(profiles.fighter)
    function e:Spawn()
        trackedBeforeSpawn=self.LODEventInstance and self.LODEventInstance.hostile==self
        assert(trackedBeforeSpawn and self.LODVarianceApplied and self.LODSkeletonHero)
        self.hp,self.maxhp=8,8
    end
    e.Activate=noop
    function e:SetModel(model) self.model=model end
    function e:SetColor(color) self.color=color end
    function e:Remove() self.valid=false end
    spawned=e;return e
end}
local instance={seed=512,level=18,cell={x=0,y=0,z=0},cellKey='0:0:0',id='test',entities={},current=true}
local made=S:Spawn(events,instance,{DungeonLevel=18})
assert(made==spawned and instance.entities[1]==made and made.model==S.Model)
assert(made:Health()==made.LODProgressionState.derivedStats.maxHP and made:GetMaxHealth()==made:Health())
assert(made.nw.LOD_CharacterLevel==20 and made.nw.LOD_MonsterName==made.LODProgressionState.skeletonName)
instance.current=false;instance.entities={}
assert(not S:Spawn(events,instance,{DungeonLevel=18}) and not spawned.valid,'untracked stale creation leaked')
print('SKELETON_HERO_PASS: canonical Hero abilities/identity/classes/hit dice/AI feats, Level-20 cap, content milestones, unchanged ordinary AI, real class damage/Content contexts/Magic spend, DEX motion+dodge, health regen, spawn tracking, stale/replaced ownership')
