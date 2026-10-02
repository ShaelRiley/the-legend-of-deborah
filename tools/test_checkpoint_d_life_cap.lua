-- Actual RunManager cap, ordinary extra-life pickup and overflow revival paths.
local f=dofile('tools/test_spot15_soldier_queue.lua')
local R,L,E=f.Run,LOD.LootDirector,LOD.RPG.FeatEffectSystem
f.reset();local owner=f.actor('cap-owner');local queued=f.actor('cap-queued')
owner.ps.lives=4
assert(R:PersonalLifeCap(owner)==4 and R:PersonalLifeCap(owner.ps)==4)
local state=owner.ps.progressionState
state.featIds={'CON_NOT_YET'}
state.derivedStats={};E:ApplyDerived(state,state.derivedStats)
assert(R:PersonalLifeCap(owner)==5 and owner.ps.lives==4,'acquiring Not Yet raises cap only')
assert(L:_CanUseExtraLife(owner) and L:_GrantExtraLife(owner) and owner.ps.lives==5)
assert(not L:_GrantExtraLife(owner) and owner.ps.lives==5,'full cap without eligible queue is inert')
-- A future independent additive authority composes rather than being overwritten.
state.derivedStats={personalLifeCapBonus=2};E:ApplyDerived(state,state.derivedStats)
assert(R:PersonalLifeCap(owner)==7 and owner.ps.lives==5)
assert(L:_GrantExtraLife(owner) and owner.ps.lives==6)
queued.hp=0;queued.ps.lives=0;queued.ps.eliminated=true;queued.ps.eliminatedSince=900;queued.ps.queue='hero'
R.State.ActiveIdentity[queued.id]=nil
assert(L:_GrantExtraLife(owner) and owner.ps.lives==7 and queued.ps.lives==0,'below current cap does not overflow early')
assert(L:_GrantExtraLife(owner) and owner.ps.lives==7 and queued.ps.lives==1,'overflow at current additive cap revives queued Hero')
assert(not queued.ps.eliminated)
f.flush()
print('NOT_YET_LIFE_CAP_PASS: actual baseline4, feat+1, future+2, no acquisition life, bounded pickups and current-cap overflow revival')
