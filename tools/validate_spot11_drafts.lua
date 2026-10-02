-- SPOT-11: real shipped include graph, catalogs, generation, commits and snapshots.
-- Source/net boundaries are supplied by the retained snapshot suite, not a new
-- copy of the FeatDirector. Its first-class fourth-card transport checks run too.
dofile('tools/test_snapshot_delivery.lua')
local CPS, RPG = LOD.CharacterProgressionSystem, LOD.RPG
local Catalog = RPG.IdentityCatalog
local assertions = 0
local function check(value, message)
    assertions = assertions + 1
    assert(value, 'SPOT11: ' .. message)
end
local function equal(a,b)
    if type(a) ~= type(b) then return false end
    if type(a) ~= 'table' then return a == b end
    for k,v in pairs(a) do if not equal(v,b[k]) then return false end end
    for k in pairs(b) do if a[k] == nil then return false end end
    return true
end
local function fresh(actor, class, seed, score)
    local state = CPS:NewProgressionState('spot11-'..seed, actor=='hero' and 'hero' or 'soldier', actor)
    state.classId, state.startingHP, state.level = class, 100, 1
    state.progressionHitDieSides = RPG.Classes[class].heroProgressionHitDieSides
    state.baseAbilities = RPG.NewAbilityBlock(score or 13)
    state.primaryAbility = RPG.Classes[class].favoredAbilities[1]
    state.secondaryAbilities = {RPG.Classes[class].favoredAbilities[2]}
    state.usesMagic, state.dungeonLevel = class=='wizard', 20
    state.capabilityTags = actor=='hero' and {} or CPS:_AutomaticActorCapabilities('soldier',state.usesMagic,actor)
    CPS:_RecomputeProgressionState(state)
    return {identity=state.actorId,starterWeaponClass='weapon_pistol',progressionState=state},state
end
local function distinctLegal(ps,state,draft,n)
    check(#draft.offerFeatIds==n,'expected '..n..' legal offers')
    local seen={}
    for _,id in ipairs(draft.offerFeatIds) do
        check(not seen[id], 'duplicate '..id); seen[id]=true
        check(CPS:_FeatEligible(ps,state,CPS:_FindFeat(id)), 'ineligible '..id)
    end
    check(draft.resolved==(n==0) and draft.exhausted==(n==0), 'empty/nonempty resolution')
end
check(RPG.OrdinaryFeatOfferCount==4,'authoritative new-hand count')
-- Classes and actor scopes share exactly the same generator, preserve RNG streams
-- unrelated to drafts, and do not resample a stored hand after qualification grows.
for _,actor in ipairs({'hero','ai','human_soldier'}) do
    for _,class in ipairs({'fighter','rogue','wizard'}) do
        for seed=1,4 do
            local ps,state=fresh(actor,class,seed)
            local unrelated=LOD.RNG.New(87654);local first=unrelated:Int(1,100000)
            local draft=CPS:_GenerateOrdinaryDraft(ps,state,seed,1)
            distinctLegal(ps,state,draft,4)
            check(draft.offerLimit==4,'fresh versioned four-card hand')
            local expected=LOD.RNG.New(87654);expected:Int(1,100000)
            check(first and unrelated:Int(1,100000)==expected:Int(1,100000),'independent RNG unchanged')
            local ps2,state2=fresh(actor,class,seed)
            check(equal(draft,CPS:_GenerateOrdinaryDraft(ps2,state2,seed,1)),'deterministic same profile')
            local frozen=table.Copy(draft)
            state.featQualificationAbilities=RPG.NewAbilityBlock(30)
            check(CPS:_GenerateOrdinaryDraft(ps,state,999,1)==draft and equal(draft,frozen),'reopen never rerolls')
        end
    end
end
-- Genuine bounded pools use real repeatable fallback definitions and real gates.
-- No eligibility mocks: cap all but N attributes at 30 and remove ordinary pool.
local ordinary,fallbacks=Catalog.OrdinaryFeats,Catalog.FallbackFeats
Catalog.OrdinaryFeats={}
for n=0,6 do
    local ps,state=fresh('hero','rogue',200+n,13)
    for i,ability in ipairs(RPG.Abilities) do
        local target=i<=n and 29 or 30
        state.baseAbilities[ability]=state.baseAbilities[ability]+target-state.featQualificationAbilities[ability]
    end
    CPS:_RecomputeProgressionState(state)
    local draft=CPS:_GenerateOrdinaryDraft(ps,state,200+n,1)
    distinctLegal(ps,state,draft,math.min(n,4))
    for _,id in ipairs(draft.offerFeatIds) do check(fallbacks[id]~=nil,'only existing neutral fallback') end
    local before=table.Copy(state.featAbilityDelta)
    if n==0 then
        check(CPS:IsDeploymentEligible(ps),'empty legal pool cannot soft-lock staging')
        check(not CPS:_CommitAutomaticFeat(ps,state,draft,33),'empty hand grants nothing automatically')
        check(not draft.selectedFeatId and #state.featIds==0 and equal(state.featAbilityDelta,before),'no fabricated award')
    else
        check(not CPS:IsDeploymentEligible(ps),'nonempty unresolved hand still blocks staging')
        check(CPS:_CommitAutomaticFeat(ps,state,draft,33),'small hand chooses once')
        local committed=table.Copy(state)
        check(not CPS:_CommitAutomaticFeat(ps,state,draft,33) and equal(state,committed),'automatic duplicate cannot grant twice')
    end
end
Catalog.OrdinaryFeats=ordinary
-- Prefer actual ordinary offers before fallbacks. Pool contains two eligible
-- ordinary entries and one deliberately ineligible high-rank entry.
local ps,state=fresh('hero','rogue',300,13)
local chosen={}
for id,def in pairs(ordinary) do
    if CPS:_FeatEligible(ps,state,def) and #chosen<2 then chosen[#chosen+1]=id end
end
table.sort(chosen);check(#chosen==2,'two real eligible ordinary fixtures')
Catalog.OrdinaryFeats={[chosen[1]]=ordinary[chosen[1]],[chosen[2]]=ordinary[chosen[2]],CON_REGEN_33=assert(ordinary.CON_REGEN_33)}
local draft=CPS:_GenerateOrdinaryDraft(ps,state,300,1)
distinctLegal(ps,state,draft,4)
check(Catalog.OrdinaryFeats[draft.offerFeatIds[1]] and Catalog.OrdinaryFeats[draft.offerFeatIds[2]],'ordinary slots precede filler')
check(fallbacks[draft.offerFeatIds[3]] and fallbacks[draft.offerFeatIds[4]],'legal filler only in missing positions')
Catalog.OrdinaryFeats=ordinary
-- Exact old data survives, including resolved results, old seeds and unversioned
-- hands. Existing canonical repair replaces removed IDs only to the saved limit.
for _,resolved in ipairs({false,true}) do
    local p,s=fresh('hero','rogue',400,13)
    local legacy={earnedAtLevel=1,draftType='ordinary',offerFeatIds={'FALLBACK_STR','FALLBACK_DEX','FALLBACK_CON'},rngSeed=45678,resolved=resolved}
    if resolved then legacy.selectedFeatId='FALLBACK_DEX' end
    s.pendingFeatSlots[1]=legacy;s.featCatalogRevision=nil
    local frozen=table.Copy(legacy)
    check(CPS:_GenerateOrdinaryDraft(p,s,999,1)==legacy,'stored hand returned by identity')
    CPS:ReconcileFeatOwnership(s);CPS:RepairCanonicalDrafts(p,s)
    check(equal(legacy,frozen),'legacy pending/resolved data remains exact')
    local nextHand=CPS:_GenerateOrdinaryDraft(p,s,400,3)
    check(#nextHand.offerFeatIds==4 and nextHand.offerLimit==4,'only future slot adopts four')
end
for _,limit in ipairs({3,4}) do
    local p,s=fresh('hero','rogue',500+limit,13)
    local hand={earnedAtLevel=1,draftType='ordinary',offerFeatIds={'FALLBACK_STR','REMOVED_TEST_ID','FALLBACK_DEX'},rngSeed=4242,resolved=false}
    if limit==4 then hand.offerLimit=4 end
    s.pendingFeatSlots[1]=hand;s.featCatalogRevision=nil
    CPS:ReconcileFeatOwnership(s);CPS:RepairCanonicalDrafts(p,s)
    check(#hand.offerFeatIds==limit,'canonical repair obeys original target')
    check(hand.offerFeatIds[1]=='FALLBACK_STR' and hand.offerFeatIds[2]=='FALLBACK_DEX' and hand.rngSeed==4242,'repair preserves valid order and seed')
    local seen={};for _,id in ipairs(hand.offerFeatIds) do
        check(not seen[id] and CPS:_FeatEligible(p,s,CPS:_FindFeat(id)),'repaired offers distinct/legal');seen[id]=true
    end
    local repaired=table.Copy(hand);CPS:RepairCanonicalDrafts(p,s)
    check(equal(hand,repaired),'repair is finite/idempotent')
end
-- Both automatic actor types see the fourth card. Use all four *real* fallback
-- entries; search a finite sequence of independent selector seeds, not fake RNG.
for _,actor in ipairs({'ai','human_soldier'}) do
    local sawFourth=false
    for seed=1,64 do
        local p,s=fresh(actor,'fighter',600+seed,13)
        local hand={earnedAtLevel=1,draftType='ordinary',offerFeatIds={'FALLBACK_STR','FALLBACK_DEX','FALLBACK_CON','FALLBACK_INT'},rngSeed=99,offerLimit=4,resolved=false}
        local clone=table.Copy(s);local hand2=table.Copy(hand)
        check(CPS:_CommitAutomaticFeat(p,s,hand,seed),'automatic selection succeeds')
        check(CPS:_CommitAutomaticFeat(p,clone,hand2,seed) and hand2.selectedFeatId==hand.selectedFeatId,'same actor selection seed')
        local before=table.Copy(s)
        check(not CPS:_CommitAutomaticFeat(p,s,hand,seed) and equal(s,before),'repeat automatic commit is inert')
        if hand.selectedFeatId==hand.offerFeatIds[4] then sawFourth=true;break end
    end
    check(sawFourth,'fourth offer is selectable by '..actor)
end
-- Real Hero snapshot/commit wrappers: fourth-card result, stale double submit,
-- chronological queued drafts and Soldier read-only guard preserve dormant Hero.
local rm=LOD.RunManager
local hero=player.GetAll()[1]
local heroPS=rm.State.PlayerState.test
local savedState=heroPS.progressionState
local p,s=fresh('hero','rogue',700,13)
s.characterIdentityPackage=table.Copy(savedState.characterIdentityPackage)
s.featCatalogRevision='feat-rebalance-20261002-v1'
heroPS.progressionState=s
local hand=CPS:_GenerateOrdinaryDraft(heroPS,s,777,1)
local hand3=CPS:_GenerateOrdinaryDraft(heroPS,s,777,3)
local frozen=table.Copy(hand)
check(not CPS:CommitFeat(hero,hand3.offerFeatIds[4],3),'future-slot request rejected')
check(equal(hand,frozen),'rejected future request preserves current hand')
local oldRole=rm.IsSoldierControl;rm.IsSoldierControl=function() return true end
check(not CPS:CommitFeat(hero,hand.offerFeatIds[4],1),'Soldier may not choose dormant Hero feat')
check(equal(hand,frozen),'Soldier request preserves dormant hand')
rm.IsSoldierControl=oldRole
local snapshot=CPS:BuildClientSnapshot(hero)
check(#snapshot.featDraft.offers==4 and snapshot.featDraft.offerLimit==4,'all four in actual snapshot')
for i,id in ipairs(hand.offerFeatIds) do check(snapshot.featDraft.offers[i].featId==id,'snapshot preserves order') end
check(CPS:CommitFeat(hero,hand.offerFeatIds[4],1),'fourth Hero offer commits')
check(hand.selectedFeatId==hand.offerFeatIds[4] and hand.resolved,'exactly fourth chosen result')
local before=table.Copy(s)
check(not CPS:CommitFeat(hero,hand.offerFeatIds[4],1) and equal(s,before),'stale double submit cannot commit next slot')
check(CPS:_NextPendingOrdinaryDraft(s)==hand3,'next slot chronological')
-- Empty snapshot reports no selected feat and zero committed choices, yet complete
-- initial requirements. No fake capstone/currency/effect is awarded.
local _,empty=fresh('hero','rogue',701,30)
empty.characterIdentityPackage=table.Copy(savedState.characterIdentityPackage)
empty.featCatalogRevision='feat-rebalance-20261002-v1'
empty.pendingFeatSlots[1]={earnedAtLevel=1,draftType='ordinary',offerFeatIds={},rngSeed=123,offerLimit=4,exhausted=true,resolved=true}
empty.featSlotsGranted=1;heroPS.progressionState=empty
local emptySnapshot=CPS:BuildClientSnapshot(hero)
check(emptySnapshot.featDraft.exhausted and #emptySnapshot.featDraft.offers==0,'empty state exposed truthfully')
check(emptySnapshot.ordinaryFeatsCommitted==0 and emptySnapshot.pendingFeatCount==0,'exhaustion is not a chosen feat')
check(CPS:IsDeploymentEligible(heroPS) and not CPS:CommitFeat(hero,'FALLBACK_STR',1),'no impossible choice and no fabricated commit')
-- The actual progression validator accepts migrated and genuinely reduced hands.
-- Gate B shares this shape helper, but its unrelated historical identity-perk
-- inventory check predates the canonical trait catalog and is not claimed here.
-- Use the same Level-1 profile; malformed empties/selected IDs still fail.
for _,n in ipairs({0,1,2,3,4}) do
    local _,v=fresh('hero','rogue',900+n,13)
    v.characterIdentityPackage=table.Copy(savedState.characterIdentityPackage)
    local ids={'FALLBACK_STR','FALLBACK_DEX','FALLBACK_CON','FALLBACK_INT'}
    while #ids>n do table.remove(ids) end
    local h={earnedAtLevel=1,draftType='ordinary',offerFeatIds=ids,rngSeed=33,
        offerLimit=n==3 and nil or 4,exhausted=n==0,resolved=true,
        selectedFeatId=n>0 and ids[n] or nil}
    v.pendingFeatSlots[1]=h;v.featSlotsGranted=1;heroPS.progressionState=v
    for _,name in ipairs({'ValidateGateCPlayer'}) do
        local ok,errors=CPS[name](CPS,hero)
        check(ok,name..' accepts hand '..n..': '..table.concat(errors or {},';'))
        local good=table.Copy(h)
        if n==0 then h.exhausted=false else h.selectedFeatId='NOT_OFFERED' end
        check(not CPS[name](CPS,hero),name..' rejects malformed result')
        v.pendingFeatSlots[1]=good;h=good
    end
end
heroPS.progressionState=savedState
-- Every ordinary slot still exists only at its authored level; capstone is its
-- fixed class trio, never a fourth ordinary choice.
for _,class in ipairs({'fighter','rogue','wizard'}) do
    local p,s=fresh('hero',class,800,13)
    for _,level in ipairs(RPG.OrdinaryFeatLevels) do
        local h=CPS:_GenerateOrdinaryDraft(p,s,800,level)
        check(h.earnedAtLevel==level and #h.offerFeatIds==4,'ordinary cadence level '..level)
    end
    check(not CPS:_GenerateOrdinaryDraft(p,s,800,20),'no ordinary level-20 draft')
    local cap=CPS:_GenerateClassCapstoneDraft(s)
    check(#cap.offerFeatIds==3 and cap.draftType=='classCapstone','fixed capstone trio')
    for _,id in ipairs(cap.offerFeatIds) do check(Catalog.ClassCapstones[class][id]~=nil,'correct class capstone') end
end
print(string.format('SPOT11_DRAFTS_PASS: %d focused production assertions; headless only.',assertions))
