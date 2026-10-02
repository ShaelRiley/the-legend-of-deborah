-- Final author ledger: real catalog, saved-hand repair, proc and save authorities.
dofile('tools/test_checkpoint_d_closure.lua')
local P,R,E,S=LOD.CharacterProgressionSystem,LOD.RPGAbilityRules,LOD.RPG.FeatEffectSystem,LOD.RPGStatusElements
local C=LOD.RPG.IdentityCatalog.OrdinaryFeats
local checks=0
local function check(ok,msg) checks=checks+1;assert(ok,msg) end
local retired={"DEX_FAST_RELOAD_2","DEX_FAST_RELOAD_3","DEX_SIDELER_2","DEX_LATERAL_MOVER_3","CON_STEADFAST","DEX_SMG_COLD_HANDS_1","DEX_SMG_COLD_HANDS_2","DEX_SMG_COLD_HANDS_3","INT_SIZE_SHIFTER","INT_HASTE_2","INT_HASTE_3","INT_CALCULATED_LUCK","WIS_SURVEYOR","WIS_SPELLBREAKER","WIS_SPELLBANE","WIS_FORCEFUL_MAGIC","CHA_NERVE_1","CHA_NERVE_2","CROSS_METEOR_STRIKE","CROSS_TINY_TERROR","CROSS_BIG_SCARY","CROSS_CRUSH_PANIC","CROSS_BOOM_BATTERY","CROSS_FORCE_OF_WILL","CROSS_LUCKY_BOOM"}

local gone={};for _,id in ipairs(retired) do gone[id]=true;check(C[id]==nil,'retired registration '..id) end
for id,def in pairs(C) do
 check(not id:match('^CROSS_'),'cross-attribute category cannot survive')
 for _,p in ipairs(def.prerequisiteFeatIds or {}) do check(C[p]~=nil and not gone[p],'no dangling prerequisite '..id..'/'..p) end
end
for _,kind in ipairs({'hero','human_soldier','ai'}) do
 local state=P:NewProgressionState('rebalance-retired-'..kind,'shambler',kind)
 state.classId='fighter';state.baseAbilities=LOD.RPG.NewAbilityBlock(20);state.featQualificationAbilities=LOD.RPG.NewAbilityBlock(20)
 state.magicFormIds={'beam'};state.contentIds={'fire'};state.usesMagic=true;state.featIds={}
 local ps={identity=state.actorId,starterWeaponClass='weapon_smg1',progressionState=state}
 for _,id in ipairs(retired) do check(not P:_FeatEligible(ps,state,C[id]),'removed eligibility '..kind..id) end
 -- Ask for the complete available catalog, not only a fortunate four-card sample.
 for _,def in ipairs(P:_DrawOrdinaryOffers(ps,state,LOD.RNG.New(313),999)) do check(not gone[def.featId],'no retired candidate reaches '..kind..' director') end
 for _,id in ipairs(retired) do
  local s=table.Copy(state);s.featIds={id,'DEX_FAST_RELOAD'};s.featStackCounts={[id]=1,DEX_FAST_RELOAD=1}
  s.featCatalogRevision='ordinary4-20260927';s.notYetConsumedDungeonLevel=3
  s.pendingFeatSlots={{offerFeatIds={id,'DEX_STRAFER_1'},selectedFeatId=id,resolved=true,rngSeed=777,earnedAtLevel=1,offerLimit=4}}
  check(P:ReconcileFeatOwnership(s),'historical revision must migrate')
  check(#s.featIds==1 and s.featIds[1]=='DEX_FAST_RELOAD' and s.featStackCounts[id]==nil,'old ownership becomes inert')
  local draft=s.pendingFeatSlots[1]
  check(not draft.resolved and not draft.selectedFeatId and draft.offerFeatIds[1]=='DEX_STRAFER_1' and draft.rngSeed==777,'valid stored choice/seed kept, retired result reopened')
  P:RepairCanonicalDrafts(ps,s)
  for _,offered in ipairs(draft.offerFeatIds) do check(not gone[offered],'repaired hand cannot retain removed IDs') end
  check(draft.offerFeatIds[1]=='DEX_STRAFER_1' and s.notYetConsumedDungeonLevel==nil,'stable order and finite Not Yet migration')
  check(not P:ReconcileFeatOwnership(s),'migration is idempotent')
 end
end
-- Actual pure square routing authority proves complete neighborhoods, not spheres.
for rank,id in ipairs({'CHA_ABRASIVE_PERSONALITY_1','CHA_NARCISSISM_2','CHA_MEGALOMANIA_3'}) do
 local radius=LOD.RPG:CheckpointDPersonalityAuraProfile({featIds={id}});check(radius==rank,'aura radius')
 local n=0;for x=-4,4 do for y=-4,4 do
  if LOD.RPG:CheckpointDCellRadiusIncludes({x=0,y=0,z=0},{x=x,y=y,z=0},radius) then n=n+1 end
  check(not LOD.RPG:CheckpointDCellRadiusIncludes({x=0,y=0,z=0},{x=x,y=y,z=1},radius),'other floors excluded')
 end end
 check(n==(2*rank+1)^2,'complete 3x3 / 5x5 / 7x7 square')
end
check(LOD.RPG:CheckpointDAuraBurstProfile({featIds={'CHA_AURA_BURST_1'}})==1,'Aura Burst rank one covers 3x3')
local d={};E:ApplyDerived({featIds={'WIS_CARTOGRAPHER'}},d);check(d.breadcrumbFeatBonusCells==8 and d.breadcrumbCells==14,'Cartographer adds 8 to ordinary 6')
-- Only actor/profile and target response boundaries are doubled below.
function IsValid(x) return type(x)=='table' and x.valid~=false end
function CurTime() return 500 end
R.ProgressionState=function(_,a) return a.state end;R.Derived=function(_,a) return a.state.derivedStats end
local function actor(id)
 local a={valid=true,id=id,LODHostile=true,state={actorType='hero',actorId=tostring(id),level=9,featIds={},effectiveAbilities=LOD.RPG.NewAbilityBlock(16),derivedStats={}}}
 function a:EntIndex() return self.id end;function a:IsPlayer() return true end;function a:Alive() return true end
 function a:Health() return 100 end;function a:GetNW2Bool(_,d) return d end
 return a
end
local source,target=actor(1),actor(2)
target.state.featIds={'WIS_SPELLWARD'}
local function dice(values)
 local rng={n=0};function rng:Int(lo,hi) check(lo==1 and hi==20,'Magic Save is a sealed d20');self.n=self.n+1;return assert(values[self.n],'unexpected save draw') end
 return rng
end
for _,pair in ipairs({{1,20},{20,1},{7,7}}) do
 local rng=dice(pair);local total,natural,rolls=S:ConditionSave(target,'wis',rng)
 check(rng.n==2 and natural==math.max(pair[1],pair[2]) and #rolls==2,'one legal Magic Save uses exactly two naturals, highest kept')
 check(total==natural+3+2,'ordinary WIS and level added once after choosing natural')
end
for _,ability in ipairs({'str','dex','con','int','cha'}) do local rng=dice({8});S:ConditionSave(target,ability,rng);check(rng.n==1,'Spellward does not manufacture advantage on other saves') end
target.state.featIds={};local rng=dice({8});S:ConditionSave(target,'wis',rng);check(rng.n==1,'ordinary Magic Save remains one die')
-- Each family executes its actual highest-rank runtime path at both exact boundaries.
local roll,draws,attempts=0,0,0
S._StatusProcRNG=function() return {Float=function() draws=draws+1;return roll end} end
S.IsArcaneShieldOnline=function() return true end
S.ConditionDC=function() return 12 end
S.Apply=function() attempts=attempts+1;return true end
S.AttemptMorale=function() attempts=attempts+1;return true end
for _,family in ipairs(LOD.RPG.CheckpointDStatusProcFamilies) do
 for rank,chance in ipairs({.55,.75,.95}) do
  source.state.featIds={};for n=1,rank do table.insert(source.state.featIds,family.ids[n]) end
  for _,success in ipairs({true,false}) do
   roll=chance-(success and .000001 or 0);draws=0;attempts=0
   local ok=S:_ResolveOneStatusProcFamily(family,source,target,{}, {physical=true},{hpBefore=100,maxHP=100,finalHPDamage=10})
   check(draws==1 and ok==success and attempts==(success and 1 or 0),'highest-only '..family.familyId..rank..' exact boundary')
  end
 end
end
for rank,chance in ipairs({.55,.75,.95}) do
 source.state.featIds={};for n=1,rank do table.insert(source.state.featIds,'STR_KNOCKBACK_'..n) end
 local p=E:PusherProfile(source.state);check(p.weaponKnockbackProcChance==chance and p.weaponKnockbackProcDistance==168,'Pusher probability changed, distance retained')
 E.PusherCooldowns[source]=nil
 local distance,ok=E:TryPusherProc(source,target,500,chance);check(not ok and distance==0,'Pusher exact probability fails')
 distance,ok=E:TryPusherProc(source,target,500,chance-.000001);check(ok and distance==168,'Pusher below probability succeeds')
 distance,ok=E:TryPusherProc(source,target,500.49,0);check(not ok,'existing per-target success cooldown retained')
end
print('FEAT_REBALANCE_20261002_PASS '..checks..' catalog/removal/AI/draft repair, exact nine-family+Pusher 55/75/95, Spellward 2d20, Cartographer and full square auras')
