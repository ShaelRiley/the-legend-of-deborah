dofile('tools/test_checkpoint_d_closure.lua')
local M,P,C=LOD.MagicProgression,LOD.CharacterProgressionSystem,LOD.RPG.IdentityCatalog.OrdinaryFeats
local checks=0
local function check(ok,msg) checks=checks+1;assert(ok,msg) end
for _,class in ipairs({'fighter','rogue','wizard'}) do
 for _,kind in ipairs({'form','content'}) do
  local id=kind=='form' and 'INT_GRAND_UNIFIED_THEORY' or 'INT_EXTRACURRICULAR_ACTIVITY'
  local field=kind=='form' and 'magicFormIds' or 'contentIds'
  local order=kind=='form' and M.FormOrder or M.ContentOrder
  for remaining=0,3 do
   local s=P:NewProgressionState('rebalance-grants','hero','hero');s.classId=class
   s.baseAbilities=LOD.RPG.NewAbilityBlock(20);s.featQualificationAbilities=LOD.RPG.NewAbilityBlock(20)
   s.featIds={};s.magicFormIds={};s.contentIds={};s.magicGrantMilestones={}
   local allowed={};for _,x in ipairs(order) do if kind~='form' or M:FormAllowed(s,x) then allowed[#allowed+1]=x end end
   for i=1,#allowed-remaining do s[field][#s[field]+1]=allowed[i] end
   check(P:_FeatEligible({},s,C[id])==(remaining>0),class..kind..remaining..' real draft gate')
   local same=table.Copy(s);local before=#s[field]
   local changed,grants=M:ApplyCheckpointDMagicGrantFeat(s,id,719)
   check(changed==(remaining>0) and #grants==math.min(2,remaining),'two, one, zero remaining grants')
   check(#s[field]==before+math.min(2,remaining),'correct ownership size')
   local seen={};for _,x in ipairs(s[field]) do check(not seen[x],'distinct ownership');seen[x]=true end
   local _,again=M:ApplyCheckpointDMagicGrantFeat(same,id,719)
   check(table.concat(again,',')==table.concat(grants,','),'dedicated deterministic selection')
   check(not M:ApplyCheckpointDMagicGrantFeat(s,id,719),'persistent acquisition retry cannot duplicate')
   local prior=#s[field];local scheduled=M:_GrantDistinct(s,kind,'level_later',719)
   check(scheduled==(remaining>2) and #s[field]==prior+(remaining>2 and 1 or 0),'later scheduled grant uses only remainder')
  end
 end
end
print('MAGIC_GRANT_FEATS_PASS '..checks..' real class-eligible deterministic distinct two/one/zero grants, eligibility, persisted retries, later scheduled grants')
