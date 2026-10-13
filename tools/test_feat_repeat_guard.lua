-- Real catalogs, human commit/snapshot and automatic selection boundaries.
dofile('tools/test_snapshot_delivery.lua')
local C,RPG=LOD.CharacterProgressionSystem,LOD.RPG
local hero=player.GetAll()[1]
hero.GetWeapon=function() return nil end
local ps=LOD.RunManager:GetPlayerState(hero)
local state=C:NewProgressionState('test','hero','hero')
state.classId='fighter';state.baseAbilities=RPG.NewAbilityBlock(20)
state.startingHP=70;state.level=6
ps.progressionState=state;C:_RecomputeProgressionState(state)
local function hand(level,ids,selected)
    return {earnedAtLevel=level,draftType='ordinary',offerFeatIds=ids,
        offerLimit=4,rngSeed=417+level,selectedFeatId=selected,resolved=selected~=nil}
end
-- A stale/historical higher-rank offer cannot evade the prerequisite.
state.pendingFeatSlots={hand(1,{'CON_REGEN_22','FALLBACK_STR'})}
assert(not C:CommitFeat(hero,'CON_REGEN_22',1),'rank two selected without rank one')
assert(not state.pendingFeatSlots[1].resolved and #state.featIds==0)
state.pendingFeatSlots={hand(1,{'CON_REGEN_11','FALLBACK_STR'})}
assert(C:CommitFeat(hero,'CON_REGEN_11',1))
state.pendingFeatSlots[2]=hand(3,{'CON_REGEN_22','FALLBACK_STR'})
assert(C:CommitFeat(hero,'CON_REGEN_22',3))
assert(state.pendingFeatSlots[1].selectedFeatId=='CON_REGEN_11')
assert(state.pendingFeatSlots[2].selectedFeatId=='CON_REGEN_22')
assert(state.featStackCounts.CON_REGEN_22==1)
assert(not C:_FeatEligible(ps,state,C:_FindFeat('CON_REGEN_11')),'lower rank reoffered after replacement')
assert(not C:_FeatEligible(ps,state,C:_FindFeat('CON_REGEN_22')),'duplicate eligible')
state.pendingFeatSlots[3]=hand(6,{'FALLBACK_STR','CON_REGEN_22','CON_REGEN_11'})
local seed=state.pendingFeatSlots[3].rngSeed
assert(not C:CommitFeat(hero,'CON_REGEN_22',6),'duplicate consumed a later slot')
local repaired=state.pendingFeatSlots[3]
assert(not repaired.resolved and repaired.rngSeed==seed and repaired.offerFeatIds[1]=='FALLBACK_STR')
for _,id in ipairs(repaired.offerFeatIds) do assert(id~='CON_REGEN_22' and id~='CON_REGEN_11') end
assert(state.featStackCounts.CON_REGEN_22==1)
-- Corrupt saved duplicate receipts return the later award to a legal hand.
state.pendingFeatSlots[3]=hand(6,{'CON_REGEN_22','FALLBACK_STR'},'CON_REGEN_22')
state.featStackCounts.CON_REGEN_22=2;state.featSelectionRevision=nil
assert(C:ReconcileFeatOwnership(state))
C:RepairCanonicalDrafts(ps,state)
assert(state.pendingFeatSlots[1].selectedFeatId=='CON_REGEN_11')
assert(state.pendingFeatSlots[2].selectedFeatId=='CON_REGEN_22')
assert(not state.pendingFeatSlots[3].resolved and not state.pendingFeatSlots[3].selectedFeatId)
assert(state.featStackCounts.CON_REGEN_22==1 and not C:ReconcileFeatOwnership(state))
-- Ordinary neutral fallbacks still repeat and award exactly one permanent point.
local before=state.featAbilityDelta.str or 0
assert(C:CommitFeat(hero,'FALLBACK_STR',6))
state.pendingFeatSlots[4]=hand(9,{'FALLBACK_STR'})
assert(C:CommitFeat(hero,'FALLBACK_STR',9))
assert(state.featAbilityDelta.str==before+2 and state.featStackCounts.FALLBACK_STR==2)
-- The automatic selector cannot accept stale duplicate offers either.
local auto=hand(12,{'CON_REGEN_22','FALLBACK_STR'})
assert(C:_CommitAutomaticFeat(ps,state,auto,913) and auto.selectedFeatId=='FALLBACK_STR')
assert(state.featStackCounts.CON_REGEN_22==1)
print('FEAT_REPEAT_GUARD_PASS: real prerequisite/commit and highest-rank eligibility; stale hand preserves valid order/seed; saved duplicate refunded; first receipts retained; repeatable fallbacks and automatic guard')
