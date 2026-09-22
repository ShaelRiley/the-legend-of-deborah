-- Shared production progression -> equipment -> damage -> status -> reaction.
local env=dofile('tools/test_equipment_economy_runtime.lua')
local C,R,S,W=LOD.CharacterProgressionSystem,LOD.RPGAbilityRules,LOD.RPGStatusElements,LOD.RPGWizardOffense
local function near(a,b,label) assert(math.abs(a-b)<.000001,(label or 'value')..': '..tostring(a)..' ~= '..tostring(b)) end
local hero,monster,soldier=env.actor('defense-hero'),env.actor('defense-monster',true),env.actor('defense-soldier',true)
soldier.LODProgressionState.actorType='human_soldier'
for _,actor in ipairs({hero,monster,soldier}) do
 local state=actor.LODProgressionState
 state.classId='wizard';state.level=20;state.baseAbilities.con=30
 C:_RecomputeProgressionState(state)
 local enemy=actor~=hero
 assert(state.derivedStats.enemyDefense==enemy)
 near(state.derivedStats.damageResistancePerDie,enemy and 1 or 3)
 near(state.derivedStats.hpToMagicDiversionFraction,enemy and .30 or .50)
 near(W:FeedbackChanceFromDerived(state.derivedStats),enemy and .15 or .50)
end
local notices={}
LOD.RPGPresentation={FeedbackName=function(_,a) return a.id end,
 Event=function(_,recipient,family,text,fields,key)
    notices[#notices+1]={recipient=recipient,text=text,event=fields.event,key=key}
 end}
LOD.Magic._EnsureState=function(_,a) return a.ps end;LOD.Magic._Sync=function() end
local function damage(value,source)
 return {damage=value,GetDamage=function(self) return self.damage end,SetDamage=function(self,v) self.damage=v end,
 GetAttacker=function() return source or hero end,IsDamageType=function() return false end}
end
local hit=damage(1)
local result=R:ApplyPlayerDefense(monster,hit)
near(result.actualMagicDiversion,.3);near(hit:GetDamage(),.7,'Enemy small hits leak HP');near(monster.ps.magic,99.7)
assert(notices[#notices].recipient==hero and notices[#notices].text:find('Poison bypasses',1,true))
local heroHit=damage(1,monster)
R:ApplyPlayerDefense(hero,heroHit);near(heroHit:GetDamage(),0,'Hero Wizard upward rounding preserved')
monster.ps.magic=.1;hit=damage(10);result=R:ApplyPlayerDefense(monster,hit)
near(result.actualMagicDiversion,.1);near(hit:GetDamage(),9.9);near(monster.ps.magic,0)
monster.ps.magic=100;hit=damage(10);S:AttachDamageContext(hit,{element='poison'})
R:ApplyPlayerDefense(monster,hit);near(hit:GetDamage(),10);near(monster.ps.magic,100)
-- Stronger shatter save pressure and longer window, without changing Hero saves.
local oldDC,oldSave=S.ConditionDC,S.ConditionSave
S.ConditionDC=function() return 10 end;S.ConditionSave=function() return 12 end
local ok,why,entry=S:Apply(monster,'arcane_shattered',hero,{duration=10})
assert(ok and entry.dc==14 and entry.expiresAt-entry.appliedAt==24)
assert(notices[#notices].event=='enemy_shatter_break' and notices[#notices].key=='enemy_defense:shatter_break')
local denied,reason=S:Apply(hero,'arcane_shattered',monster,{duration=10})
assert(not denied and reason=='saved','Hero retains unmodified DC')
local exact=S:Apply(hero,'arcane_shattered',monster,{direct=true,duration=10})
assert(exact);local _,hs=S:Has(hero,'arcane_shattered')
assert(hs.expiresAt-hs.appliedAt==10,'Hero duration unchanged')
S:CureNegative(hero)
local magicBefore=monster.ps.magic;hit=damage(10);R:ApplyPlayerDefense(monster,hit)
near(hit:GetDamage(),10);near(monster.ps.magic,magicBefore,'Shatter disables diversion')
assert(not W:TryFeedback(monster,hit,{finalHPDamage=10}),'Shatter disables Feedback')
S:CureNegative(monster)
S.ConditionSave=function() return 20 end
local saved,reason=S:Apply(monster,'arcane_shattered',hero,{duration=10})
assert(not saved and reason=='saved' and notices[#notices].event=='enemy_shatter_save')
assert(notices[#notices].text:find('Poison',1,true))
S.ConditionDC,S.ConditionSave=oldDC,oldSave
S:Apply(monster,'arcane_shattered',hero,{direct=true,duration=30})
_,entry=S:Has(monster,'arcane_shattered');assert(entry.expiresAt-entry.appliedAt==45)
S:CureNegative(monster)
-- The actual post-damage deferred reaction rechecks a shield broken by this hit.
local oldRNG,oldApply=LOD.CombatRolls._RNG,W.ApplyFeedback
LOD.CombatRolls._RNG=function() return {Float=function() return 0 end} end
local queued={};timer.Simple=function(_,fn) queued[#queued+1]=fn end
local retaliation=0;W.ApplyFeedback=function() retaliation=retaliation+1 end
hit=damage(10);S:AttachDamageContext(hit,{magic=true,damageContract={values={3,3}}})
monster.LODWizardFeedbackNextReadyAt=nil
assert(W:TryFeedback(monster,hit,{finalHPDamage=7}));near(monster.LODWizardFeedbackNextReadyAt-CurTime(),2)
assert(not W:TryFeedback(monster,hit,{finalHPDamage=7}) and #queued==1,'Enemy cooldown prevents duplicate returns')
S:Apply(monster,'arcane_shattered',hero,{direct=true,duration=10});queued[1]()
assert(retaliation==0,'A shield broken by the same hit cancels its pending Feedback')
S:CureNegative(monster);monster.LODWizardFeedbackNextReadyAt=nil
assert(W:TryFeedback(monster,hit,{finalHPDamage=7}));queued[2]();assert(retaliation==1)
monster.LODWizardFeedbackNextReadyAt=nil
assert(W:TryFeedback(monster,hit,{finalHPDamage=7}));monster.LODDead=true;queued[3]()
assert(retaliation==1,'A defeated Wizard cannot execute its pending retaliation');monster.LODDead=nil
LOD.CombatRolls._RNG,W.ApplyFeedback=oldRNG,oldApply
local resolved=R:ResolveDamageContract({contributions={8,4},bonus=0},hero,monster,{physical=true})
assert(notices[#notices].event=='enemy_con_resistance' and notices[#notices].text:find('Backstabs',1,true))
print('MONSTER_DEFENSE_PASS: AI/possessed parity; Hero caps/rounding preserved; small-hit HP leakage; low-Magic/Poison; easier 24/45s breaks; attacker tactics; enemy cooldown; same-hit break cancels deferred Feedback')

monster.LODProgressionState.baseAbilities.wis=30
monster.LODProgressionState.featIds={'WIS_TRUE_FAITH','WIS_MIND_OVER_MATTER'}
C:_RecomputeProgressionState(monster.LODProgressionState)
hit=damage(4);S:AttachDamageContext(hit,{magic=true});R:ApplyWisDefense(monster,hit)
assert(hit:GetDamage()==0 and notices[#notices].event=='enemy_true_faith')
assert(notices[#notices].text:find('physical attacks',1,true))
hit=damage(4);S:AttachDamageContext(hit,{physical=true});R:ApplyWisDefense(monster,hit)
assert(hit:GetDamage()==0 and notices[#notices].event=='enemy_mind_over_matter')
hit=damage(4);S:AttachDamageContext(hit,{physical=true});R:ApplyWisDefense(monster,hit)
assert(hit:GetDamage()==4,'Mind Over Matter follow-up tactic works during recovery')
print('DEFENSE_TACTICS_PASS: True Faith names physical attacks; Mind Over Matter names and exposes its recovery window')
