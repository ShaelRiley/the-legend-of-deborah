-- Engine-boundary fakes, production feat/dice/Morale/Dodge implementations.
dofile('tools/test_checkpoint_d_closure.lua')
local base = 'gamemodes/legend_of_deborah/gamemode/lod/'
dofile(base .. 'sv_combat_rolls.lua')
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
        state={featIds=feats or {},level=1,effectiveAbilities={cha=10},derivedStats={}},resource={magic=90}}
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
target.state={featIds={},derivedStats={},effectiveAbilities={cha=10}}
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
print('[CROSS_FEATS_DODGE] PASS: production dice/refund/Meteor/bridge/Dodge/Morale and capability seams')
