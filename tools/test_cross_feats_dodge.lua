-- Engine-boundary fakes, production feat/dice/Morale/Dodge implementations.
local registered = {}
hook = {Add=function(event, id, fn) registered[event]=registered[event] or {}; registered[event][id]=fn end}
dofile('tools/test_checkpoint_d_closure.lua')
local base = 'gamemodes/legend_of_deborah/gamemode/lod/'
dofile(base .. 'sv_combat_rolls.lua')
dofile(base .. 'sv_combat_feed_semantics.lua')
local Rules, Cross, Status = LOD.RPGAbilityRules, LOD.RPGCrossFeats, LOD.RPGStatusElements
local Effects, Rolls = LOD.RPG.FeatEffectSystem, LOD.CombatRolls
local now, serial, reports = 100, 0, {}
CurTime = function() return now end
IsValid = function(a) return type(a) == 'table' and a.valid == true end
game = {GetWorld = function() return nil end}
hook.Run = function() end
net.Start, net.Send = function() end, function() end
Rules.ProgressionState = function(_, a) return a and a.state end
Rolls._Send = function(_,actor,kind,text) reports[#reports+1] = text end
Rolls.EntityDisplayName = function(_, a) return 'actor' .. tostring(a.id) end
local function actor(feats, human)
    serial = serial + 1
    local a = {valid=true,id=serial,hp=100,ground=false,LODHostile=not human,
        state={featCatalogRevision="hybrid-stable-150-v1",featIds=feats or {},level=1,effectiveAbilities={cha=10},derivedStats={}},resource={magic=90}}
    function a:IsPlayer() return human == true end
    function a:Alive() return self.hp > 0 end
    function a:Health() return self.hp end
    function a:GetMaxHealth() return 100 end
    function a:EntIndex() return self.id end
    function a:OnGround() return self.ground end
    function a:SetNW2Bool() end
    function a:GetNW2Bool(_,default) return default end
    function a:SetNW2Float() end
    function a:EmitSound() end
    function a:Nick() return "Actor" end
    function a:GetClass() return "lod_hostile" end
    function a:GetPos() return self.cell end
    return a
end
local function near(a,b,label) assert(math.abs(a-b)<1e-8,(label or '')..': '..tostring(a)..' ~= '..tostring(b)) end
local function rng(values)
    local i=0
    return {Int=function(_,low,high) i=i+1; local v=assert(values[i],'unexpected extra RNG draw'); assert(v>=low and v<=high); return v end}
end
LOD.Magic = {_EnsureState=function(_, a) return a.resource end, _Sync=function() end}
LOD.RunManager = {State={LevelSeed=3,Graph={}}}

-- One per-attack continuation budget, across distinct rolls; no Magic farming
-- from copying a contract, Magic rolls, full resources, or shared blast victims.
local source = actor({'CROSS_BOOM_BATTERY'},true)
local event = {}
local first = Rolls:RollActorDamage(source,{sides=6,count=1,attackEvent=event},rng({6,6,1}),0)
near(source.resource.magic,91,'two continuations restore one Magic')
Cross:RestoreBoomBattery(source, first); near(source.resource.magic,91,'same roll cannot refund twice')
local second = Rolls:RollActorDamage(source,{sides=6,count=1,attackEvent=event},rng({6,1}),0)
near(source.resource.magic,91,'odd continuation retained on attack')
Rolls:RollActorDamage(source,{sides=6,count=1,attackEvent=event},rng({6,1}),0)
near(source.resource.magic,92,'continuations accumulate across subprojectiles')
for i=1,8 do Rolls:RollActorDamage(source,{sides=6,count=1,attackEvent=event},rng({6,6,1}),0) end
near(source.resource.magic,95,'five Magic attack cap')
Rolls:RollActorDamage(source,{sides=6,count=1,magicDamage=true},rng({6,6,1}),0)
near(source.resource.magic,95,'Magic excluded')
source.resource.magic=99.5
Rolls:RollActorDamage(source,{sides=6,count=1},rng({6,6,1}),0)
near(source.resource.magic,100,'capacity clamp')

-- A mixed-die Meteor remains two separate chains with truthful arithmetic.
source.state.featIds={'CROSS_METEOR_STRIKE'}
Effects.CloudStepState[source]={used=true}
local strike=Rolls:RollActorDamage(source,{sides=12,count=1},rng({1}),0)
Cross:AugmentMeteor(source,strike,rng({6,2}))
assert(strike.formula=='1d12!+1d6!' and strike.total==9 and strike.baseDice==2)
assert(strike.chainStarts[2]==2 and strike.values[3]==2)
assert(not Effects.CloudStepState[source].meteorUsed,'augmentation is not a committed damaging hit')
Cross:ConsumeMeteor(strike)
local nextStrike=Rolls:RollActorDamage(source,{sides=12,count=1},rng({1}),0)
Cross:AugmentMeteor(source,nextStrike,rng({}))
assert(nextStrike.baseDice==1,'once per airborne cycle')

-- Shared push proc: bridge after Magic distance, existing target cooldown.
source.state.featIds={'CROSS_FORCE_OF_WILL','STR_KNOCKBACK_1'}
source.state.derivedStats={weaponKnockbackProcChance=.25,weaponKnockbackProcDistance=168,pusherProcTargetCooldownSeconds=.5}
local target=actor()
local originalRoll=Effects._PusherRoll
Effects._PusherRoll=function() return 0 end
local options={distance=100,magicPush=true}
near(Cross:BridgeMagicPush(source,target,200,options),368,'Force Multiplier precedes +168')
assert(options.pusherFamilyEligible)
near(Cross:BridgeMagicPush(source,target,200,options),200,'shared target cooldown')
near(Cross:BridgeMagicPush(source,actor(),0,{distance=0,magicPush=true}),0,'non-pushing Magic excluded')
Effects._PusherRoll=originalRoll

-- Canonical caps and contributions, identical for grounded/airborne movement.
local rogue={rogueAllDamageDiceExplode=true,dodgeChanceContribution=.20}
near(Rules:DodgeChance(rogue,49.99,200,400),0)
near(Rules:DodgeChance(rogue,50,200,400),.31)
near(Rules:DodgeChance(rogue,359.99,200,400),.31)
near(Rules:DodgeChance(rogue,360,200,400),.42)
near(Rules:DodgeChance({dodgeChanceContribution=5},100,200,400),.33)
near(Rules:DodgeChance({dodgeChanceContribution=5},400,200,400),.66)
near(Rules:DodgeChance({dodgeChanceContribution=5},0,200,400),0)
target.state.derivedStats=rogue
local rolls=0
local oldRNG=Rolls._RNG
Rolls._RNG=function() return {Float=function() rolls=rolls+1;return .1 end} end
local oldMovement=Rules.DodgeMovement
Rules.DodgeMovement=function() return 360,200,400 end
local function damage(event)
    local info={amount=20}
    function info:GetDamage() return self.amount end
    function info:SetDamage(n) self.amount=n end
    function info:SetDamageForce() end
    function info:GetAttacker() return source end
    function info:IsDamageType() return false end
    Status:AttachDamageContext(info,{attackEvent=event})
    return info
end
event={}
local d1,d2=damage(event),damage(event)
assert(Rules:ApplyDodge(target,d1) and Rules:ApplyDodge(target,d2))
assert(d1.amount==0 and d2.amount==0 and rolls==1,'one roll per attack-target, all pellets cancelled')
local another=actor();another.state.derivedStats=rogue
assert(Rules:ApplyDodge(another,damage(event)) and rolls==2,'different target rolls independently')
local immune=damage({});Status:AttachDamageContext(immune,{ignoreDodge=true})
assert(not Rules:ApplyDodge(target,immune) and immune.amount==20 and rolls==2)
Rules.DodgeMovement,Rolls._RNG=oldMovement,oldRNG

-- Terrifying consumes two naturals only on the first eligible encounter save.
source.state.featIds={'CHA_MENACE_3'};source.state.derivedStats={}
target=actor(); target.state.effectiveAbilities.cha=10
local ok, reason, data=Status:AttemptMorale(source,target,{forceMorale=true,rng=rng({20,1,1,1,1})})
assert(ok and reason=='flee' and data.save==1 and data.dc==14,'Terrifying keeps lower natural; Menace ownership works')
target.LODMoraleCooldownUntil=0
ok,reason,data=Status:AttemptMorale(source,target,{forceMorale=true,rng=rng({20,1,1,1})})
assert(ok and reason=='saved' and data.save==20,'later encounter save rolls once')
target.state={featCatalogRevision="hybrid-stable-150-v1",featIds={},derivedStats={},effectiveAbilities={cha=10}}
assert(Status:FirstTerrifyingSave(source,target),'new incarnation resets first save')

-- Blast-Proof resolves a target-local view of the real shared roll. It ends
-- only one chain, preserves the triggering die, and cannot change another victim.
source.state.featIds={}
local defended=actor({'CON_BLAST_PROOF'})
local bystander=actor()
local shared=Rolls:RollActorDamage(source,{sides=6,count=2},rng({6,6,2,3}),0)
near(Rolls:ResolveActorDamage(shared,source,defended,{}),9,'Blast-Proof ends first chain')
assert(#shared.values==4 and shared.total==17,'shared source roll remains immutable')
near(Rolls:ResolveActorDamage(shared,source,bystander,{}),17,'other victim retains its own result')
near(Rolls:ResolveActorDamage(shared,source,defended,{}),9,'repeated subhit reuses defender view')
local nextAttack=Rolls:RollActorDamage(source,{sides=6,count=2},rng({6,6,2,3}),0)
near(Rolls:ResolveActorDamage(nextAttack,source,defended,{}),17,'two-second suppression cooldown')

-- Deferred scope and correct physical capability gating before candidate weights.
local CPS=LOD.CharacterProgressionSystem
local state={actorType='hero',classId='fighter',featIds={},capabilityTags={}}
local ps={starterWeaponClass='weapon_pistol'}
assert(not CPS:_HasCapability(ps,state,'exploding_nonmagic_damage_dice'),'baseline pistol/crowbar cannot feed battery')
ps.starterWeaponClass='weapon_shotgun'
assert(CPS:_HasCapability(ps,state,'exploding_nonmagic_damage_dice'),'universal d6 source qualifies')
for _,id in ipairs({'INT_CALCULATED_LUCK','CROSS_LUCKY_BOOM','CHA_SPOT_1','CHA_SPOT_2','CHA_SPOT_3','INT_POLYMORPH','INT_AFTERSHOCK','DEX_AR2_SNAP'}) do
    assert(not LOD.RPG.IdentityCatalog.OrdinaryFeats[id],id..' must remain deferred')
end

-- Every ordinary feat must actually be offerable through the shipped director
-- eligibility path. Do not inject capability tags: doing that concealed missing
-- capability consumers (Morale, Summon, grants, Aura Burst and Attunement).
local missing={}
for id, definition in pairs(LOD.RPG.IdentityCatalog.OrdinaryFeats) do
    local feasible={actorType='hero',classId='fighter',level=18,secondaryAbilities={'int','cha'},
        primaryAbility='str',featIds=table.Copy(definition.prerequisiteFeatIds or {}),
        capabilityTags={},featQualificationAbilities={str=30,dex=30,con=30,int=30,wis=30,cha=30},
        magicFormIds={'blast','bomb','beam','cone','aura','summon'}, contentIds={'earth','fire','ice','electric','dark','light'}}
    if id=='INT_MIDDLE_MANAGER' or id=='INT_TASKMASTER' or id=='INT_OVERLORD' then feasible.classId='wizard' end
    if id=='CON_GLOW_UP' then feasible.featIds={'CHA_AGGRESSIVE_PERSONALITY'} end
    if id=='INT_GRAND_UNIFIED_THEORY' then feasible.magicFormIds={'blast'} end
    if id=='INT_EXTRACURRICULAR_ACTIVITY' then feasible.contentIds={'earth'} end
    local inventory={starterWeaponClass='weapon_ar2',inventory={weapons={
        {class='weapon_pistol'},{class='weapon_smg1'},{class='weapon_crowbar'},
        {class='weapon_ar2'},{class='weapon_357'},{class='weapon_shotgun'},{class='weapon_frag'}}}}
    if not CPS:_FeatEligible(inventory,feasible,definition) then missing[#missing+1]=id end
end
table.sort(missing)
assert(#missing==0,'canonical feats cannot enter a legal draft: '..table.concat(missing,','))
assert(CPS:HasFeatPrerequisite({featIds={'STR_CROWBAR_D12'}},'STR_CROWBAR_D6'),
    'replacement ownership still satisfies lower-rank CROSS prerequisites')
assert(not CPS:_HasCapability(nil,{magicFormIds={}},'magic_form_owned'))
assert(not CPS:_HasCapability(nil,{magicFormIds={}},'magic_form_summon'))
assert(not CPS:_HasCapability(nil,{magicFormIds={}},'discrete_magic_activation'))
assert(Effects:HasUsableChaModDamage({featIds={'CHA_ABRASIVE_PERSONALITY_1'}}),'aura source makes Glow Up usable')

-- The final Shotgun damage contract must retain all actor/attack metadata;
-- pellet-count explosions are utility dice and cannot refund Boom Battery.
source.state.featIds={'CROSS_BOOM_BATTERY'}
source.resource.magic=90
local weaponRNG=Rolls._RNG
Rolls.EmitDiceExplosionFX=function() end
Rolls._RNG=function() return rng({6,2,6,1}) end
local token={}
local weaponRoll=Rolls:RollPlayerWeapon(source,'weapon_shotgun',token)
assert(weaponRoll.attackEvent==token and weaponRoll.profile and weaponRoll.chainStarts[1]==1)
assert(weaponRoll.total==9 and weaponRoll.pellets==15 and weaponRoll.resolutionByTarget and weaponRoll.ownerState==source.state)
near(source.resource.magic,90,'pellet-count continuation cannot grant Magic')
Rolls._RNG=weaponRNG

-- Historical ownership and locked offers migrate through the production ingress.
local migrated=CPS:NewProgressionState('legacy','hero','hero')
migrated.featIds={'STR_HERO_OF_LEGEND','DEX_AR2_SNAP','WIS_HERO_OF_LEGEND'}
migrated.featStackCounts={STR_HERO_OF_LEGEND=1,DEX_AR2_SNAP=1}
migrated.pendingFeatSlots={{earnedAtLevel=1,rngSeed=42,resolved=false,
    offerFeatIds={'STR_HERO_OF_LEGEND','DEX_AR2_SNAP','CON_REGEN_11'}}}
assert(CPS:ReconcileFeatOwnership(migrated))
assert(#migrated.featIds==1 and migrated.featIds[1]=='WIS_HERO_OF_LEGEND')
assert(migrated.featStackCounts.DEX_AR2_SNAP==nil)
migrated.featQualificationAbilities={str=20,dex=20,con=20,int=20,wis=20,cha=20}
CPS:RepairCanonicalDrafts({identity='legacy',starterWeaponClass='weapon_pistol'},migrated)
local repaired=migrated.pendingFeatSlots[1]
assert(repaired.rngSeed==42 and repaired.offerFeatIds[1]=='WIS_HERO_OF_LEGEND'
    and repaired.offerFeatIds[2]=='CON_REGEN_11' and #repaired.offerFeatIds==3)
assert(not CPS:ReconcileFeatOwnership(migrated),'migration is idempotent')
assert(not CPS:_HasCapability({}, {actorType='ai',archetypeId='soldier',capabilityTags={'reloadable_firearm'}},'reloadable_firearm'))
assert(not CPS:_HasCapability({}, {actorType='ai',archetypeId='runner'},'d4_damage'),'no inherited Hero pistol')
Rolls.MeleeBalanceProfiles={runner={sides=4}}
assert(CPS:_HasCapability({}, {actorType='ai',archetypeId='runner'},'d4_damage'),'canonical tuned melee dice qualify')
assert(not CPS:_HasCapability({}, {actorType='ai',archetypeId='runner'},'d8_damage'),'obsolete melee dice do not qualify')

-- Settle a real shotgun shell once per target, after per-die mitigation and
-- aggregation but before once-per-target CHA/Glow Up. Cooldown needs actual damage.
function DamageInfo()
    local info={amount=0}
    function info:SetDamage(n) self.amount=n end
    function info:GetDamage() return self.amount end
    function info:SetAttacker(a) self.attacker=a end
    function info:GetAttacker() return self.attacker end
    function info:SetInflictor(a) self.inflictor=a end
    function info:GetInflictor() return self.inflictor end
    function info:SetDamageType(t) self.kind=t end
    function info:IsDamageType(t) return t~=nil and self.kind==t end
    function info:SetDamagePosition() end
    function info:SetDamageForce() end
    return info
end
DMG_BULLET,DMG_ENERGYBEAM,DMG_GENERIC=2,4,0
source=actor({'CHA_AGGRESSIVE_PERSONALITY','CON_GLOW_UP'},true)
source.state.derivedStats={chaMod=4,conMod=2}
local victimA,victimB=actor(),actor()
local function acceptDamage(victim)
    victim.applied=0
    function victim:WorldSpaceCenter() return self.cell end
    function victim:TakeDamageInfo(info)
        self.applied=self.applied+1
        registered.EntityTakeDamage.LOD_DiceDamageAuthority(self,info)
        local context=Status:DamageContext(info,self)
        LOD.RPG:ObserveDirectChaDamage(context.damageContract,info:GetDamage())
        self.hp=self.hp-info:GetDamage()
        Rolls:ReportResolvedDamage(info)
    end
end
acceptDamage(victimA);acceptDamage(victimB)
local shell={values={3},contributions={3},chainStarts={1},baseDice=1,bonus=0,total=3,
    profile={sides=6},attackEvent={},hits={[victimA]=6,[victimB]=2},hitPositions={},
    damageByTarget={},resolutionByTarget={},ownerState=source.state,levelSeed=3}
local callbacks={};local originalSimple=timer.Simple
timer.Simple=function(_,fn) callbacks[#callbacks+1]=fn end
Rolls:SettleShotgun(source,shell)
near(shell.damageByTarget[victimA],12,'full shell plus one CHA and CON contribution')
near(shell.damageByTarget[victimB],8,'partial shell plus one CHA and CON contribution')
assert(victimA.applied==1 and victimB.applied==1,'one defense transaction per victim')
assert(#callbacks==1 and not source.LODCheckpointDAggressiveReadyAt,'attack completion schedules one cooldown')
callbacks[1]()
assert(source.LODCheckpointDAggressiveReadyAt>=now+1 and source.LODCheckpointDAggressiveReadyAt<=now+3)
source.LODCheckpointDAggressiveReadyAt=nil
local cancelled={values={3},contributions={3},chainStarts={1},bonus=0,total=3,profile={sides=6}}
Rolls:ResolveActorDamage(cancelled,source,victimA,{physical=true})
LOD.RPG:ObserveDirectChaDamage(cancelled,0)
LOD.RPG:FinishAggressiveAttack(cancelled,source)
assert(source.LODCheckpointDAggressiveReadyAt==nil,'zero final damage cannot consume readiness')
local stale={values={3},contributions={3},chainStarts={1},bonus=0,total=3,profile={sides=6}}
Rolls:ResolveActorDamage(stale,source,victimA,{physical=true})
LOD.RPG:ObserveDirectChaDamage(stale,1)
Status:ResetActorLife(source)
callbacks[#callbacks]()
assert(source.LODCheckpointDAggressiveReadyAt==nil,'old completion cannot modify a new life')
timer.Simple=originalSimple

-- Graph range is not a world-distance shortcut; gated neighbors remain excluded.
dofile(base .. "sv_maze_generator.lua")
local graph={Cells={}}
local key=LOD.MazeGenerator.CellKey
for x=0,3 do graph.Cells[key(x,0,0)]={x=x,y=0,z=0,neighbors={}} end
for x=0,2 do
    graph.Cells[key(x,0,0)].neighbors[key(x+1,0,0)]=true
    graph.Cells[key(x+1,0,0)].neighbors[key(x,0,0)]=true
end
LOD.RunManager.State.Graph=graph
local blocked=false
LOD.MazeNavigator={WorldToCell=function(_,g,pos) return pos end,
    CanTraverse=function(_,g,a,b) return not (blocked and b==key(2,0,0)) end}
source.cell=graph.Cells[key(0,0,0)];victimA.cell=graph.Cells[key(2,0,0)]
victimB.cell=graph.Cells[key(3,0,0)]
source.state.featIds={'CROSS_TINY_TERROR','DEX_SHRINK'}
near(Cross:MoraleBonus(source,victimA,{}),2,'Tiny Terror at two graph cells')
near(Cross:MoraleBonus(source,victimB,{}),0,'Tiny Terror outside radius')
blocked=true;near(Cross:MoraleBonus(source,victimA,{}),0,'closed graph edge excludes Tiny Terror');blocked=false
source.state.featIds={'CROSS_BIG_SCARY','CON_BIG_GUY'}
near(Cross:MoraleBonus(source,victimA,{physical=true}),0,'ordinary ranged hit gets no Big Scary')
near(Cross:MoraleBonus(source,victimA,{wallCrush=true}),2,'physical wall crush gets Big Scary')
source.state.featIds={'CHA_PANIC'}
local neighbor=actor();neighbor.hp=49;neighbor.cell=source.cell
local healthy=actor();healthy.cell=source.cell
LOD.FactionManager={Opponents=function() return {victimB,neighbor,healthy} end}
local attempts={};local attempt=Status.AttemptMorale
Status.AttemptMorale=function(_,s,t,e) attempts[#attempts+1]={target=t,event=e} end
Status:CascadeMorale(source,victimA,{})
assert(#attempts==1 and attempts[1].target==neighbor and attempts[1].event.cascade)
Status:CascadeMorale(source,victimA,{})
assert(#attempts==1,'three-second per-target cascade immunity')
now=now+3;Status:CascadeMorale(source,victimA,{cascade=true})
assert(#attempts==1,'cascade never recursively triggers another')
Status.AttemptMorale=attempt

-- The real aura listener deals one supplemental event, with Glow Up once and
-- an explicit marker preventing the weapon authority from rerolling an AI aura.
source.state.featIds={'CHA_AURA_BURST_1','CON_GLOW_UP'}
source.state.derivedStats={chaMod=4,conMod=2}
victimA.cell=source.cell
LOD.FactionManager.Opponents=function() return {victimA,victimB} end
local before=victimA.hp
local auraContext={auraBurst=LOD.RPG:PrepareCheckpointDAuraBurst(source)}
victimA.cell=victimB.cell -- spell displacement cannot alter captured aura membership
registered.LODDiscreteMagicSpent.LOD_CheckpointDAuraBurst(source,1,auraContext)
near(before-victimA.hp,6,'Aura Burst consumes CHA and CON through shared source')
local ignored=DamageInfo();ignored:SetDamage(6);ignored:SetAttacker(victimA)
Status:AttachDamageContext(ignored,{actorDamageResolved=true,auraBurst=true})
registered.EntityTakeDamage.LOD_DiceDamageAuthority(source,ignored)
near(ignored:GetDamage(),6,'AI aura cannot become its ordinary weapon roll')

-- Lifecycle reset clears per-life controls; persistent feat/dungeon consumption
-- belongs to progression and must survive the same reset.
target.state.notYetConsumedDungeonLevel=3
target.LODMoraleCooldownUntil=999
target.LODMindOverMatterReadyAt=999
target.LODPersonalityAuraNextAt=999
Effects.CloudStepState[target]={used=true,meteorUsed=true}
Status:ResetActorLife(target)
assert(target.LODMoraleCooldownUntil==nil and target.LODMindOverMatterReadyAt==nil)
assert(target.LODPersonalityAuraNextAt==nil and Effects.CloudStepState[target]==nil)
assert(target.state.notYetConsumedDungeonLevel==3,'no extra Not Yet use from respawn')
-- Execute the shipped custom Crowbar, not just the old stock-weapon hook.
-- Only the engine trace/input/damage boundary is faked.
local vecmt={}
local function v(x,y,z) return setmetatable({x=x,y=y,z=z},vecmt) end
vecmt.__add=function(a,b) return v(a.x+b.x,a.y+b.y,a.z+b.z) end
vecmt.__mul=function(a,n) return v(a.x*n,a.y*n,a.z*n) end
local wielder=actor({'CROSS_METEOR_STRIKE','STR_CROWBAR_D6','INT_CLOUD_STEP'},true)
wielder.state.derivedStats={}
function wielder:GetShootPos() return v(0,0,0) end
function wielder:GetAimVector() return v(1,0,0) end
function wielder:SetAnimation() end
function wielder:LagCompensation() end
local struck=actor();struck.cell=v(20,0,0)
local crowbarContexts={}
function struck:TakeDamageInfo(info)
    local context=Status:DamageContext(info,self)
    assert(context.actorDamageResolved and context.physical and context.melee and context.damageContract)
    registered.EntityTakeDamage.LOD_DiceDamageAuthority(self,info)
    crowbarContexts[#crowbarContexts+1]=context
    -- First hit is dodged by the final-defense boundary. The next hit lands.
    if #crowbarContexts==1 then info:SetDamage(0)
    else self.hp=self.hp-info:GetDamage();Cross:ConsumeMeteor(context.meteor) end
end
util.TraceHull=function() return {Entity=struck,HitPos=struck.cell} end
IsFirstTimePredicted=function() return true end
SWEP={Primary={},Secondary={}}
dofile('gamemodes/legend_of_deborah/entities/weapons/weapon_lod_crowbar/shared.lua')
local club=SWEP
function club:GetOwner() return wielder end
function club:SetNextPrimaryFire() end
function club:SendWeaponAnim() end
function club:EmitSound() end
Effects.CloudStepState[wielder]={used=true}
local beforeRoll=Rolls._RNG
Rolls._RNG=function() return rng({1,6,2}) end
club:PrimaryAttack()
assert(not Effects.CloudStepState[wielder].meteorUsed,'custom Crowbar miss/Dodge preserves Meteor')
club:PrimaryAttack()
assert(Effects.CloudStepState[wielder].meteorUsed and struck.hp==91,'custom Crowbar lands the independent Meteor chain')
assert(crowbarContexts[2].damageContract.formula=='1d6!+1d6!')
Rolls._RNG=beforeRoll

-- Human Soldier targets and AI-vs-AI combat enter the real weapon resolver.
local gunner=actor({},true)
local pistol={valid=true,GetClass=function() return 'weapon_pistol' end}
function gunner:GetActiveWeapon() return pistol end
local soldierTarget=actor({},true)
local gunRNG=Rolls._RNG;Rolls._RNG=function() return rng({3}) end
local shot=Rolls:RollPlayerWeapon(gunner,'weapon_pistol',{})
shot.targets={};gunner.LODActivePlayerRoll=shot
local hit=DamageInfo();hit:SetDamage(25);hit:SetAttacker(gunner);hit:SetInflictor(pistol);hit:SetDamageType(DMG_BULLET)
registered.EntityTakeDamage.LOD_DiceDamageAuthority(soldierTarget,hit)
near(hit:GetDamage(),3,'human player target receives the dice contract')
assert(Status:DamageContext(hit,soldierTarget).attackEvent==shot.attackEvent)
local hostileShooter,hostileVictim=actor(),actor()
hostileShooter.LODArchetypeId='soldier'
local hostileHit=DamageInfo();hostileHit:SetDamage(6);hostileHit:SetAttacker(hostileShooter);hostileHit:SetInflictor(hostileShooter)
registered.EntityTakeDamage.LOD_DiceDamageAuthority(hostileVictim,hostileHit)
near(hostileHit:GetDamage(),4,'AI-vs-AI uses the same 1d10+1 contract')
assert(Status:DamageContext(hostileHit,hostileVictim).physical)
Rolls._RNG=gunRNG

-- Wizard wrappers preserve the complete cast result and take the full-Magic
-- snapshot before a damage roll can restore resources.
LOD.Magic.CastForceShout=function() return nil,"blocked",7 end
local full={marker=true}
dofile(base .. "sv_rpg_wizard_feedback.lua")
local wizard=LOD.RPGWizardOffense
assert(wizard:Install())
wizard.ActiveFullMagicSnapshots[source]=full
local castResult=table.pack(LOD.Magic:CastForceShout(source))
assert(castResult.n==3 and castResult[1]==nil and castResult[2]=="blocked" and castResult[3]==7)
assert(wizard.ActiveFullMagicSnapshots[source]==full)
wizard.ActiveFullMagicSnapshots[source]=nil
source.state.classId='wizard';source.state.featIds={'CROSS_BOOM_BATTERY'}
source.state.derivedStats={intMod=4};source.resource.magic=99
local preRoll=Rolls:RollActorDamage(source,{sides=6,count=1},rng({6,6,1}),0)
near(source.resource.magic,100)
near(preRoll.wizardFullMagicIntBonus,0,'restoration during an attack cannot create a full-Magic start')
-- The real instrumentation observes the preceding Dodge even when the later
-- diversion authority returns nil. Disk/timer boundaries alone are stubbed.
local installLogger
CLIENT=false
isbool=function(value) return type(value)=='boolean' end
engine={ActiveGamemode=function() return 'legend_of_deborah' end}
GetConVar=function() return {GetBool=function() return true end} end
player.GetHumans=function() return {} end
timer.Simple=function(_,fn) installLogger=fn end
dofile('lua/autorun/server/lod_rpg_test_log.lua')
local telemetry, log = {}, LOD.RPGTestLog
log.BeginSession=function() return true end
log.Write=function(_,kind,fields) telemetry[#telemetry+1]={kind=kind,fields=fields} end
assert(installLogger and installLogger(),'production instrumentation installs')
local dodger=actor();dodger.state.derivedStats=rogue
Rules.DodgeMovement=function() return 360,200,400 end
Rolls._RNG=function() return {Float=function() return .1 end} end
local avoided=damage({})
assert(Rules:ApplyDodge(dodger,avoided))
assert(Rules:ApplyPlayerDefense(dodger,avoided)==nil,'observer preserves nil defense result')
local observed=telemetry[#telemetry]
assert(observed.kind=='PLAYER_DEFENSE' and observed.fields.dodged and observed.fields.evaded
    and observed.fields.final==0,'telemetry agrees with canonical Dodge and zero HP damage')
local landed=damage({})
local defense=Rules:ApplyPlayerDefense(dodger,landed)
observed=telemetry[#telemetry]
assert(defense and defense.finalHPDamage==20 and not observed.fields.dodged and not observed.fields.evaded,
    'ordinary undeflected hit cannot inherit a prior attack Dodge')
print('[CROSS_FEATS_DODGE] PASS: production dice/refund/Meteor/bridge/Dodge/Morale and capability seams')

