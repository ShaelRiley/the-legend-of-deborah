-- Real ordinary and modular-boss registrations; engine boundaries use the
-- existing integration fixture. No enemy population or combat tuning changes.
local F = dofile('tools/boss_framework_fixture.lua')
local root = F.root
for _, module in ipairs({'sv_deadcrab', 'sv_bioblaster', 'sv_watcher', 'sv_seeker',
    'sv_enemy_roster_placement', 'sv_encounter_ecology_catalog'}) do
    dofile(root .. module .. '.lua')
end
dofile(arg and arg[1] or root .. 'sv_identity_perks.lua')
local D, EC = LOD.IdentityPerkDirector, LOD.Config.Encounter
local expected = {
    ZOMBIE=true, FAST_ZOMBIE=true, SOLDIER=true, HEADCRAB=true, ROLLER=true,
    ['models/combine_scanner.mdl']=true, ['models/combine_super_soldier.mdl']=true,
    ['models/combine_turrets/floor_turret.mdl']=true, ['models/manhack.mdl']=true,
    ['models/police.mdl']=true, ['models/stalker.mdl']=true, ['models/antlion.mdl']=true,
    ['models/vortigaunt.mdl']=true, ['models/vortigaunt_slave.mdl']=true
}
local function fresh()
    D.FavoredWeaponTargetRegistry, D.EnemyModelFamilyRegistry = nil, nil
    return D:TargetRegistries()
end
local weapons, enemies = fresh()
assert(table.Count(enemies)==14, 'recurring model family count drift')
for family in pairs(expected) do assert(enemies[family], 'missing recurring family '..family) end
for family in pairs(enemies) do assert(expected[family], 'nonrecurring family admitted '..family) end
assert(D:ModelFamily(EC.Archetypes.nodule)==D:ModelFamily(EC.Archetypes.lurker))
assert(not enemies[D:ModelFamily(EC.Archetypes.nodule)], 'Lurker reintroduced Nodule/Barnacle')
local excluded, shared = 0, 0
for id, config in pairs(EC.Archetypes) do
    local family = D:ModelFamily(config)
    if LOD.BossRegistry.Primary[id] or LOD.BossEncounter.Support[id] or id=='neil' or id=='brute' or id=='hector' then
        if expected[family] then assert(enemies[family]); shared=shared+1
        else assert(not enemies[family], 'unique/boss model admitted '..id); excluded=excluded+1 end
    end
end
assert(excluded>=20, 'actual boss and unique registrations were not inspected')
local cachedWeapons, cachedEnemies = D:TargetRegistries()
assert(cachedWeapons==weapons and cachedEnemies==enemies, 'registry cache changed')

-- Ordinary enrollment, not registration alone, controls eligibility. Objective
-- guards and zero-body compositions cannot admit a new unique model family.
EC.Archetypes.test_unique={model='models/test_unique.mdl'}
EC.Archetypes.test_zero={model='models/test_zero.mdl'}
EC.Archetypes.test_wander={model='models/test_wander.mdl'}
EC.Archetypes.test_shared_boss={modelLineage='MODELS/ZOMBIE/CLASSIC.MDL',model='models/test_unique.mdl'}
EC.Templates.test_objective={objective=true,composition={test_unique=1}}
EC.Templates.test_zero={composition={test_zero=0}}
LOD.WanderingDirector.Config.AutonomousTypes.test_wander=true
local _, probe = fresh()
assert(not probe['models/test_unique.mdl'] and not probe['models/test_zero.mdl'])
assert(probe['models/test_wander.mdl'] and probe.ZOMBIE
    and D:ModelFamily(EC.Archetypes.test_shared_boss)=='ZOMBIE', 'shared boss lineage excluded recurring models')
EC.Archetypes.test_unique, EC.Archetypes.test_zero, EC.Archetypes.test_wander, EC.Archetypes.test_shared_boss=nil,nil,nil,nil
EC.Templates.test_objective, EC.Templates.test_zero=nil,nil
LOD.WanderingDirector.Config.AutonomousTypes.test_wander=nil
weapons, enemies = fresh()

-- All three slots still independently select the same three handlers. Only
-- newly generated enemy targets change; deterministic rolls never escape pool.
local seen, rolled = {}, 0
for seed=1,1500 do
    local p={rosterSeed=seed,heroIdentityId='pool-test',originIndex=1,backgroundIndex=2,motiveIndex=3}
    local q=table.Copy(p)
    assert(D:EnsurePackage(p) and D:EnsurePackage(q))
    for i, record in ipairs(p.identityPerkRecords) do
        assert(record.handlerId==q.identityPerkRecords[i].handlerId and record.targetId==q.identityPerkRecords[i].targetId)
        if record.handlerId=='FAVORED_ENEMY' then
            assert(expected[record.targetId], 'new identity rolled excluded target')
            seen[record.targetId]=true;rolled=rolled+1
        end
    end
    local records=p.identityPerkRecords
    assert(not D:EnsurePackage(p) and p.identityPerkRecords==records, 'saved identity rerolled')
end
for family in pairs(expected) do assert(seen[family], 'eligible family never rolled '..family) end
local records = {
    {traitSlot='origin',handlerId='FAVORED_ENEMY',targetId='models/barnacle.mdl',targetName='Barnacle'},
    {traitSlot='background',handlerId='FAVORED_ENEMY',targetId='models/pigeon.mdl',targetName='Pigeon'},
    {traitSlot='motive',handlerId='ABILITY_BONUS',targetId='str',abilityBonuses={str=2}}
}
local saved={identityPerkVersion=D.Version,identityPerkRecords=records}
saved.favoredWeaponStacks,saved.favoredEnemyStacks,saved.identityAbilityDelta=D:Aggregate(records)
assert(not D:EnsurePackage(saved) and saved.identityPerkRecords==records)
assert(saved.favoredEnemyStacks['models/barnacle.mdl']==1 and saved.favoredEnemyStacks['models/pigeon.mdl']==1 and saved.identityAbilityDelta.str==2)
local legacy={identityPerkVersion='identity-three-handlers-v1',identityPerkRecords=table.Copy(records),
    rosterSeed=3,heroIdentityId='legacy',originIndex=1,backgroundIndex=2,motiveIndex=3}
assert(D:EnsurePackage(legacy))
for i, record in ipairs(records) do
    assert(legacy.identityPerkRecords[i].handlerId==record.handlerId and legacy.identityPerkRecords[i].targetId==record.targetId)
end
assert(legacy.favoredEnemyStacks['models/barnacle.mdl']==1 and legacy.favoredEnemyStacks['models/pigeon.mdl']==1 and legacy.identityAbilityDelta.str==2)
print('IDENTITY_ENEMY_POOL_PASS: 14 recurring families; '..excluded..' boss/unique archetypes excluded; '..shared..' shared boss models retained; '..rolled..' seeded enemy perks; immutable saved/legacy targets')
