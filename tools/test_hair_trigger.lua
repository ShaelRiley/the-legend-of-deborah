-- Exercise final production ownership, stock-shot observation and AR2 service.
-- The reused Soldier fixture also checks real finite Hero ammo and lifecycle seams.
local f = dofile('tools/test_spot16_soldier_rifle.lua')
local Effects, Specials = f.Effects, f.Specials
local Rules, CPS = LOD.RPGAbilityRules, LOD.CharacterProgressionSystem
local Catalog = LOD.RPG.IdentityCatalog
local checks = 0
local function check(value, message)
    checks = checks + 1
    assert(value, 'HAIR_TRIGGER: '..message)
end
local function near(actual, expected, message)
    check(math.abs(actual - expected) < .00001, message)
end
local id = 'DEX_RATE_OF_FIRE_1'
check(not Catalog.OrdinaryFeats.DEX_RATE_OF_FIRE_2 and not Catalog.OrdinaryFeats.DEX_RATE_OF_FIRE_3,
    'retired ranks cannot enter any actor draft or prerequisite graph')
check(Catalog.OrdinaryFeats[id].effectParams.description == 'Increase firearm firing rate by 55%.',
    'one concise player-facing description for every fire mode')
check(#Effects.RateOfFireConfig.chain == 1 and not Catalog.OrdinaryFeats[id].replacesLowerRank,
    'singleton, without a replacing or repeatable rank')

-- Stock firearms share the actual post-shot observer. No timing gain is granted
-- before a committed shot; every eligible interval receives the full multiplier.
for _, class in ipairs({'weapon_357', 'weapon_pistol', 'weapon_shotgun', 'weapon_smg1'}) do
    local p, _, _, inc = f.setup(0, 1)
    near(inc.derivedStats.rateOfFireMultiplier, 1.55, class..' derived multiplier')
    near(Rules:RateOfFireMultiplier(p), 1.55, class..' actor resolver is not capped at 1.30')
    local now = CurTime()
    local w = {valid=true, class=class, clip=6, deadline=now, shoot=0}
    function w:GetClass() return self.class end
    function w:Clip1() return self.clip end
    function w:GetNextPrimaryFire() return self.deadline end
    function w:SetNextPrimaryFire(value) self.deadline=value end
    function w:GetLastShootTime() return self.shoot end
    function w:GetInternalVariable() return false end
    function w:SetSaveValue(key, value) self.savedKey=key;self.savedTime=value;return true end
    p.GetActiveWeapon=function() return w end
    check(Effects:BeginAttackRateObservation(p,w), class..' begins ordinary observation')
    local session=Effects.AttackRateSessions[p]
    Effects:ProcessAttackRateObservation(p,session,now)
    near(w.deadline,now,class..' no speculative deadline write')
    w.clip=5;w.shoot=now;w.deadline=now+.8
    Effects:ProcessAttackRateObservation(p,session,now)
    near(w.deadline,now+.8/1.55,class..' committed interval divided once by 1.55')
    check(not Effects.AttackRateSessions[p],class..' transaction ends after one division')
    if class=='weapon_pistol' then
        near(w.savedTime,.8/1.55,'native pistol FIELD_TIME boundary retains relative time')
    end
end

-- AR2 uses the same multiplier for projectile spacing and the complete cycle.
-- Exercise all 3..6-round burst sizes through the final wrapper and real service.
for bonus=0,3 do
    local p,w = f.setup(bonus,1)
    local began=CurTime()
    check(Specials:BeginAR2Burst(p,w,p.aim),'AR2 commits '..(3+bonus)..' projectiles')
    local a=Specials.PlayerState[p].ar2
    local plan=Effects.AR2RateOfFirePlans[p]
    check(plan and plan.ar2==a,'AR2 owns one completion transaction')
    near(plan.multiplier,1.55,'AR2 uses same actor multiplier')
    near(a.fireAt,began+.45,'existing targeting warning remains intact')
    near(a.burstSpacing,.09/1.55,'AR2 projectile spacing divided by 1.55')
    f.step(p,a.fireAt-.001)
    check(#f.shots()==0,'AR2 cannot fire before its warning')
    local first=a.fireAt
    for n=0,2+bonus do
        f.step(p,first+n*.09/1.55+.000001)
        check(#f.shots()==n+1,'one due AR2 projectile, without fabricated completion')
    end
    check(not a.active,'complete AR2 burst genuinely resolved')
    f.cadence()
    local authored=.45+(2+bonus)*.09+.25
    near(a.readyAt,began+authored/1.55,'AR2 completed-cycle interval divided once by 1.55')
    near(w:GetNextPrimaryFire(),a.readyAt,'native AR2 deadline matches shared cycle')
    check(not Effects.AR2RateOfFirePlans[p],'AR2 completion cannot divide twice')
end

-- Finite Hero cost still applies to the faster AR2, exactly once per burst.
f.fixture.reset()
local hero=f.fixture.actor('hair-trigger-hero')
local rifle=hero:Give('weapon_ar2');hero:SelectWeapon('weapon_ar2')
rifle.clip=5;rifle.next=0
hero.ps.progressionState.featIds={id}
CPS:_RecomputeProgressionState(hero.ps.progressionState)
check(Specials:BeginAR2Burst(hero,rifle,hero.aim),'Hero AR2 uses same firing authority')
local burst=Specials.PlayerState[hero].ar2
near(burst.burstSpacing,.09/1.55,'Hero AR2 spacing matches Soldier')
local fireAt=burst.fireAt
for n=0,2 do f.step(hero,fireAt+n*.09/1.55+.000001) end
f.cadence()
check(rifle:Clip1()==4 and not burst.active,'faster Hero burst still costs exactly one round')

-- Old ranks collapse at canonical ingress, not in future candidate registries.
local migrated=table.Copy(hero.ps.progressionState)
migrated.featCatalogRevision='feat-rebalance-20261002-v1'
migrated.featIds={'DEX_RATE_OF_FIRE_2','DEX_RATE_OF_FIRE_3',id,'CON_REGEN_11'}
migrated.featStackCounts={DEX_RATE_OF_FIRE_2=2,DEX_RATE_OF_FIRE_3=3,[id]=1}
migrated.pendingFeatSlots={
    {resolved=true,selectedFeatId='DEX_RATE_OF_FIRE_3',offerFeatIds={'DEX_RATE_OF_FIRE_3','CON_REGEN_11'},rngSeed=42},
    {resolved=false,offerFeatIds={'DEX_RATE_OF_FIRE_2','WIS_HERO_OF_LEGEND','CON_REGEN_11'},rngSeed=83,offerLimit=4}
}
check(CPS:ReconcileFeatOwnership(migrated),'earlier rebalance revision still migrates')
check(#migrated.featIds==2 and migrated.featIds[1]==id and migrated.featIds[2]=='CON_REGEN_11',
    'all prior ranks collapse once while unrelated ownership remains')
check(migrated.featStackCounts[id]==1 and not migrated.featStackCounts.DEX_RATE_OF_FIRE_3,
    'historical stacks cannot multiply Hair Trigger')
local settled, pending=migrated.pendingFeatSlots[1],migrated.pendingFeatSlots[2]
check(settled.resolved and settled.selectedFeatId==id and settled.rngSeed==42,
    'resolved historical choice preserves its result without a new award')
check(#pending.offerFeatIds==2 and pending.offerFeatIds[1]=='WIS_HERO_OF_LEGEND'
    and pending.offerFeatIds[2]=='CON_REGEN_11' and pending.rngSeed==83 and pending.offerLimit==4
    and pending.needsCanonicalRepair,'unchosen retired offer uses existing deterministic repair')
check(not CPS:ReconcileFeatOwnership(migrated),'migration is idempotent')
near(Effects:RateOfFireProfile(migrated).rateOfFireMultiplier,1.55,'migrated profile never stacks ranks')
CPS:RepairCanonicalDrafts({identity='hair-trigger-legacy',starterWeaponClass='weapon_pistol'},migrated)
check(#pending.offerFeatIds==4 and pending.offerFeatIds[1]=='WIS_HERO_OF_LEGEND'
    and pending.offerFeatIds[2]=='CON_REGEN_11' and pending.rngSeed==83 and pending.offerLimit==4
    and not pending.needsCanonicalRepair,'canonical repair fills only retired gaps in the same stored hand')
for _, offered in ipairs(pending.offerFeatIds) do
    check(offered~='DEX_RATE_OF_FIRE_2' and offered~='DEX_RATE_OF_FIRE_3','no retired compatibility offers')
end
check(settled.resolved and settled.selectedFeatId==id,'repair never reopens a resolved historical choice')

-- A Workshop base with hard-coded shot spacing must receive the same correction.
-- Reload the real service with only that historical boundary restored, then bind
-- the same final wrappers. This catches double scaling in both current and mixed
-- source configurations rather than testing a separate toy burst implementation.
local sourceFile=assert(io.open('gamemodes/legend_of_deborah/gamemode/lod/sv_player_weapon_specials.lua','r'))
local source=sourceFile:read('*a');sourceFile:close()
local current='ar2.nextShotAt = ar2.nextShotAt + (tonumber(ar2.burstSpacing) or AR2_BURST_SPACING)'
local from,to=source:find(current,1,true)
check(from~=nil,'current native spacing boundary exists')
source=source:sub(1,from-1)..'ar2.nextShotAt = ar2.nextShotAt + AR2_BURST_SPACING'..source:sub(to+1)
assert(load(source,'legacy-hardcoded-ar2-spacing'))()
Specials.AR2UsesRateOfFireSpacing=nil
Effects.InstallAR2RateOfFireAuthorityWrappers()
local p,w=f.setup(0,1)
local started=CurTime()
check(Specials:BeginAR2Burst(p,w,p.aim),'legacy base binds final Hair Trigger plan')
local a=Specials.PlayerState[p].ar2
local initial=a.fireAt
for n=0,2 do
    f.step(p,initial+n*.09/1.55+.000001)
    check(#f.shots()==n+1,'legacy base releases each due shot at divided spacing')
end
f.cadence()
near(a.readyAt,started+.88/1.55,'legacy base shares the exact completed cycle')
print('HAIR_TRIGGER_PASS '..checks..' focused assertions; native engine acceptance pending')
