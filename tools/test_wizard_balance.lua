-- Reuse the production progression fixture; exercise every grant path.
dofile('tools/test_checkpoint_d_closure.lua')
local P,CPS=LOD.MagicProgression,LOD.CharacterProgressionSystem
local function has(xs,id) for _,v in ipairs(xs or {}) do if v==id then return true end end return false end
for seed=1,300 do
    for _,class in ipairs({'fighter','rogue','unselected'}) do
        local s=CPS:NewProgressionState('balance:'..seed,'hero','hero')
        s.classId=class~='unselected' and class or nil
        s.level=1;P:ApplyScheduledGrants(s,seed)
        assert(#s.contentIds==0 and not has(s.magicFormIds,'summon'))
        s.level=20;P:ApplyScheduledGrants(s,seed)
        for n=1,10 do P:_GrantDistinct(s,'form','feat'..n,seed) end
        assert(#s.magicFormIds==8 and not has(s.magicFormIds,'summon'))
        assert(not P:GrantForm(s,'wall') and not P:SelectForm(s,'wall'))
        assert(not P:GrantForm(s,'summon') and not P:SelectForm(s,'summon'))
        assert(not CPS:_HasCapability({},s,'magic_form_grant_available'))
        s.capabilityTags={'magic_form_summon'}
        assert(not CPS:_HasCapability({},s,'magic_form_summon'),'Legacy capability cannot bypass class law')
    end
    local s=CPS:NewProgressionState('wizard:'..seed,'hero','hero')
    P:ApplyScheduledGrants(s,seed);assert(#s.contentIds==0)
    s.classId='wizard';P:ApplyScheduledGrants(s,seed)
    assert(#s.contentIds==1);local first=s.contentIds[1]
    P:ApplyScheduledGrants(s,seed+1);assert(#s.contentIds==1 and s.contentIds[1]==first)
    s.level=14;P:ApplyScheduledGrants(s,seed);assert(#s.contentIds==4)
    local unique={};for _,id in ipairs(s.contentIds) do assert(not unique[id]);unique[id]=true end
    assert(P:GrantForm(s,'summon') and P:SelectForm(s,'summon'))
    assert(CPS:_HasCapability({},s,'magic_form_summon'))
end
local legacy={actorId='legacy',classId='rogue',magicFormIds={'beam','summon'},selectedMagicFormId='summon'}
P:EnsureState(legacy)
assert(#legacy.magicFormIds==2 and not has(legacy.magicFormIds,'summon'))
local replacement=legacy.selectedMagicFormId
P:EnsureState(legacy);assert(legacy.selectedMagicFormId==replacement and #legacy.magicFormIds==2)
assert(LOD.RPG.MagicForms.summon.magicCost==12)
local F=assert(LOD.MagicForms)
assert(F:TotalBaseCost(LOD.RPG.MagicForms.summon,nil)==12)
assert(F:TotalBaseCost(LOD.RPG.MagicForms.summon,LOD.RPG.MagicContents.fire)==27)
print('WIZARD_BALANCE_PASS: 300 seeds, class-only acquisition, legacy migration, distinct starting Content and cost 12')
-- Class may already be selected when restoring/creating a Hero. The old tests
-- only granted Level 1 before class selection and missed Wizard utility starts.
local later={summon=0,wall=0}
for seed=1,3000 do
 local s={actorId='starter:'..seed,actorType='hero',classId='wizard',level=1}
 P:ApplyScheduledGrants(s,seed)
 assert(#s.magicFormIds==1 and not LOD.RPG.MagicForms[s.magicFormIds[1]].utility)
 local first=s.magicFormIds[1]
 P:ApplyScheduledGrants(s,seed+1);assert(#s.magicFormIds==1 and s.magicFormIds[1]==first)
 s.level=14;P:ApplyScheduledGrants(s,seed)
 for _,id in ipairs(s.magicFormIds) do if later[id] then later[id]=later[id]+1 end end
end
assert(later.summon>100 and later.wall>100,'Utility Forms remain available in later grants')
for _,utility in ipairs({'summon','wall'}) do
 local old={actorId='utility-start:'..utility,actorType='hero',classId='wizard',level=1,
  magicFormIds={utility},selectedMagicFormId=utility,magicGrantMilestones={['form:level_1_all']=true}}
 assert(P:ApplyScheduledGrants(old,99));assert(has(old.magicFormIds,utility) and #old.magicFormIds==2)
 assert(not LOD.RPG.MagicForms[old.selectedMagicFormId].utility)
 local selected=old.selectedMagicFormId;P:ApplyScheduledGrants(old,100)
 assert(#old.magicFormIds==2 and old.selectedMagicFormId==selected,'Repair is idempotent without utility confiscation')
end
print('OFFENSIVE_STARTER_PASS: 3000 preselected Wizards, deterministic first damage Form, later Summon='..later.summon..' Wall='..later.wall..', utility-only save repair')
