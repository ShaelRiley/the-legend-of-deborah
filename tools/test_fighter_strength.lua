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
-- 15 raw, 9 after CON; retain full +7.5 STR rather than the old +4.5.
near(LOD.CombatRolls:ResolveActorDamage(contract,source,target,{physical=true}),16.5)
assert(contract.feedResolution.reduced[1]==7 and contract.feedResolution.reduced[2]==2)
for _,class in ipairs({'rogue','wizard'}) do
    state.classId=class;C:_RecomputeProgressionState(state)
    assert(state.derivedStats.fighterStrengthBypassesCon==false)
    near(LOD.CombatRolls:ResolveActorDamage(contract,source,target,{physical=true}),13.5,class)
end
state.classId='fighter';C:_RecomputeProgressionState(state)
-- Test low/zero dice, exploding chains, flat bonuses and CON caps against an
-- independent decomposition of reduced base plus unreduced positive STR bonus.
local dice={0,1,2,6,6,4};local bonus=3
for resistance=0,3 do
    for _,str in ipairs({.8,1,1.1,1.5}) do
        local raw,base=bonus,bonus
        for _,v in ipairs(dice) do raw=raw+v;base=base+(v>0 and math.max(1,v-resistance) or 0) end
        local expected=str>1 and base+raw*(str-1) or base*str
        local d={physicalDamageMultiplier=str,fighterStrengthBypassesCon=true}
        near(R:ResolveDamageValues({contributions=dice,bonus=bonus},d,
            {damageResistancePerDie=resistance},{physical=true}),expected)
    end
end
local d={physicalDamageMultiplier=1.5,fighterStrengthBypassesCon=true,
    fighterCapstonePhysicalDamageMultiplier=1.2,magicPowerMultiplier=1.3}
local defense={damageResistancePerDie=3,equipmentExtras={defense=20}}
near(R:ResolveDamageValues(contract,d,defense,{physical=true,authoredScale=2}),16.5*1.2*2*.8)
near(R:ResolveDamageValues(contract,d,defense,{physical=true,shotgunHits=2,shotgunShares=7}),16.5*1.2*2/7*.8)
near(R:ResolveDamageValues(contract,d,defense,{physical=true,ignoreConDamageResistance=true}),15*1.5*1.2*.8)
near(R:ResolveDamageValues(contract,d,defense,{magic=true}),9*1.3,'Magic unchanged')
near(R:ResolveDamageValues(contract,d,defense,{physical=true,authoredScale=0}),0,'no resurrection of suppressed damage')

-- Capture the actual attack's class/STR, then change live equipment/derived state.
local shot={attackEvent={}}
E:SealWeaponAttack(source,shot,nil)
local snapshot=assert(shot.equipmentSnapshot)
assert(snapshot.derived.fighterStrengthBypassesCon)
state.classId='wizard';state.baseAbilities.str=10;C:_RecomputeProgressionState(state)
local tags={physical=true};E:PrepareDamageTags(shot,source,tags)
near(R:ResolveDamageValues(contract,state.derivedStats,{damageResistancePerDie=3},tags),16.5,'sealed Fighter')
local wizardShot={attackEvent={}};E:SealWeaponAttack(source,wizardShot,nil)
state.classId='fighter';state.baseAbilities.str=30;C:_RecomputeProgressionState(state)
local wizardTags={physical=true};E:PrepareDamageTags(wizardShot,source,wizardTags)
near(R:ResolveDamageValues(contract,state.derivedStats,{damageResistancePerDie=3},wizardTags),9,'sealed non-Fighter')

-- Element resistance remains downstream of the bypass. Use the production
-- element resolver with a fixed RNG result, replacing the fixture's save stub.
LOD.RPGStatusElements._RNG=function(_,_,rng) return rng end
target.LODProgressionState.currentElement='fire'
local elementTags={physical=true,element='fire',rng={Int=function() return 2 end}}
near(LOD.CombatRolls:ResolveActorDamage(contract,source,target,elementTags),16.5*.78,'element resistance retained')
elementTags.element='ice'
near(LOD.CombatRolls:ResolveActorDamage(contract,source,target,elementTags),16.5*1.22,'element weakness retained')
-- Shared derived authority includes monster and disposable Human Soldier Fighters.
for _,actorType in ipairs({'ai','human_soldier'}) do
    local s=C:NewProgressionState('class-test','soldier',actorType)
    s.classId='fighter';s.baseAbilities.str=30;C:_RecomputeProgressionState(s)
    assert(s.derivedStats.fighterStrengthBypassesCon)
    near(R:ResolveDamageValues(contract,s.derivedStats,{damageResistancePerDie=3},{physical=true}),16.5)
end
print('FIGHTER_STRENGTH_PASS: class-only positive STR penetration, base CON floors, Magic/gear/element defenses, shotgun/scaling, committed identity, Hero/AI/Soldier parity')
