-- Real progression, public damage dispatch and committed equipment snapshots.
local env=dofile('tools/test_equipment_economy_runtime.lua')
local R,C,E=LOD.RPGAbilityRules,LOD.CharacterProgressionSystem,LOD.Equipment
local function near(a,b,label) assert(math.abs(a-b)<.000001,(label or 'damage')..': '..a..' ~= '..b) end
local source=env.actor('fighter');local target=env.actor('defender',true)
local state=source.LODProgressionState
state.baseAbilities.str=30;C:_RecomputeProgressionState(state)
target.LODProgressionState.baseAbilities.con=16;C:_RecomputeProgressionState(target.LODProgressionState)
local contract={contributions={10,5},bonus=0}
assert(state.derivedStats.fighterStrengthBypassesCon==true)
-- One +10 modifier, despite two dice. CON remains per original contribution.
near(LOD.CombatRolls:ResolveActorDamage(contract,source,target,{physical=true}),19)
assert(contract.feedResolution.reduced[1]==12 and contract.feedResolution.reduced[2]==2)
for _,class in ipairs({'rogue','wizard'}) do
    state.classId=class;C:_RecomputeProgressionState(state)
    assert(state.derivedStats.fighterStrengthBypassesCon==false)
    near(LOD.CombatRolls:ResolveActorDamage(contract,source,target,{physical=true}),19,class)
end
state.classId='fighter';state.baseAbilities.str=20;state.baseAbilities.wis=20
C:_RecomputeProgressionState(state)
assert(state.derivedStats.physicalDamageBonus==5 and state.derivedStats.magicDamageBonus==5)
local low={contributions={1}}
near(LOD.CombatRolls:ResolveActorDamage(low,source,target,{physical=true}),4,'STR20 low roll protects 3')
near(LOD.CombatRolls:ResolveActorDamage(low,source,target,{magic=true}),3,'WIS20 receives CON even on Fighter')
for _,class in ipairs({'rogue','wizard'}) do
    state.classId=class;C:_RecomputeProgressionState(state)
    near(LOD.CombatRolls:ResolveActorDamage(low,source,target,{physical=true}),3,'no other class penetrates')
end
-- Exploding chains receive one bonus, including odd bonuses and penalties;
-- leading zero contributions cannot consume it or create an extra hit.
for _,case in ipairs({
    {{0,1,2,6,6,4},5,true,3,12},
    {{0,1,2,6,6,4},5,false,3,11},
    {{6,6,4},5,false,0,21},
    {{6,6,4},-2,true,3,5},
    {{6,6,4},0,true,3,7},
    {{1},1,true,3,2},
    {{1},2,true,3,2},
    {{1},3,true,3,3},
    {{1},-4,true,3,1},
    {{0,0},5,true,3,0},
    {{},5,true,3,0},
}) do
    local dice,modifier,fighter,resistance,expected=table.unpack(case)
    near(R:ResolveDamageValues({contributions=dice},
        {physicalDamageBonus=modifier,fighterStrengthBypassesCon=fighter},
        {damageResistancePerDie=resistance},{physical=true}),expected,'flat matrix')
end
state.classId='fighter';state.baseAbilities.str=30;C:_RecomputeProgressionState(state)
local d={physicalDamageBonus=10,fighterStrengthBypassesCon=true,
    fighterCapstonePhysicalDamageMultiplier=1.2,magicDamageBonus=5}
local defense={damageResistancePerDie=3,equipmentExtras={defense=20}}
near(R:ResolveDamageValues(contract,d,defense,{physical=true,authoredScale=2}),19*1.2*2*.8)
near(R:ResolveDamageValues(contract,d,defense,{physical=true,shotgunHits=2,shotgunShares=7}),19*1.2*2/7*.8)
near(R:ResolveDamageValues(contract,d,defense,{physical=true,ignoreConDamageResistance=true}),25*1.2*.8)
near(R:ResolveDamageValues(contract,d,defense,{magic=true}),14,'flat WIS, no Fighter penetration')
near(R:ResolveDamageValues(contract,d,defense,{magic=true,wisScaled=false}),9,'unscaled magic unchanged')
near(R:ResolveDamageValues(contract,d,defense,{physical=true,authoredScale=0}),0,'no resurrection of suppressed damage')
near(R:ResolveDamageValues({contributions={10,5},bonus=3},d,{damageResistancePerDie=3},{physical=true}),22*1.2,'existing flat bonuses retained')
local stats=R.Stats.conDiceReduced
near(R:ResolveBaseDamageValues(contract,d,{damageResistancePerDie=3},{physical=true}),19)
assert(R.Stats.conDiceReduced==stats,'informational helper cannot mutate live telemetry')

-- Capture the actual attack's class/STR, then change live equipment/derived state.
local shot={attackEvent={}}
E:SealWeaponAttack(source,shot,nil)
local snapshot=assert(shot.equipmentSnapshot)
assert(snapshot.derived.fighterStrengthBypassesCon)
state.classId='wizard';state.baseAbilities.str=10;C:_RecomputeProgressionState(state)
local tags={physical=true};E:PrepareDamageTags(shot,source,tags)
near(R:ResolveDamageValues(contract,state.derivedStats,{damageResistancePerDie=3},tags),19,'sealed Fighter')
local wizardShot={attackEvent={}};E:SealWeaponAttack(source,wizardShot,nil)
state.classId='fighter';state.baseAbilities.str=30;C:_RecomputeProgressionState(state)
local wizardTags={physical=true};E:PrepareDamageTags(wizardShot,source,wizardTags)
near(R:ResolveDamageValues(contract,state.derivedStats,{damageResistancePerDie=3},wizardTags),9,'sealed non-Fighter')

-- WIS is also sealed at cast time and carries no class penetration.
local magicTags={magic=true,equipmentSnapshot=snapshot}
state.baseAbilities.wis=10;C:_RecomputeProgressionState(state)
near(R:ResolveDamageValues(low,state.derivedStats,{damageResistancePerDie=3},magicTags),3,'sealed WIS20')
-- Existing authored aim/backstab additive multiples apply to the flat addition.
local originalBackstab=R.Backstab
R.Backstab=function() return true end
state.classId='rogue';state.baseAbilities.str=20;C:_RecomputeProgressionState(state)
near(R:ResolveDamageContract(low,source,target,{physical=true,authoredScale=1,attackMultiplier=1}),12,'backstab includes one STR bonus')
near(R:ResolveDamageContract(low,source,target,{physical=true,authoredScale=2,attackMultiplier=2}),18,'aim plus backstab x3')
near(R:ResolveDamageContract(low,source,target,{physical=true,authoredScale=3,attackMultiplier=3}),24,'Deadeye plus backstab x4')
R.Backstab=originalBackstab
state.classId='fighter';state.baseAbilities.str=30;C:_RecomputeProgressionState(state)

-- Element resistance remains downstream of the bypass. Use the production
-- element resolver with a fixed RNG result, replacing the fixture's save stub.
LOD.RPGStatusElements._RNG=function(_,_,rng) return rng end
target.LODProgressionState.currentElement='fire'
local elementTags={physical=true,element='fire',rng={Int=function() return 2 end}}
near(LOD.CombatRolls:ResolveActorDamage(contract,source,target,elementTags),19*.78,'element resistance retained')
elementTags.element='ice'
near(LOD.CombatRolls:ResolveActorDamage(contract,source,target,elementTags),19*1.22,'element weakness retained')
-- Shared derived authority includes monster and disposable Human Soldier Fighters.
for _,actorType in ipairs({'ai','human_soldier'}) do
    local s=C:NewProgressionState('class-test','soldier',actorType)
    s.classId='fighter';s.baseAbilities.str=30;C:_RecomputeProgressionState(s)
    assert(s.derivedStats.fighterStrengthBypassesCon)
    near(R:ResolveDamageValues(contract,s.derivedStats,{damageResistancePerDie=3},{physical=true}),19)
end
print('FIGHTER_STRENGTH_PASS: flat STR/WIS once per attack, rounded-half class-only penetration, CON floors, exploding/shotgun/scaling, committed identity, Hero/AI/Soldier parity')
