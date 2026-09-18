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
        for n=1,7 do P:_GrantDistinct(s,'form','feat'..n,seed) end
        assert(#s.magicFormIds==7 and not has(s.magicFormIds,'summon'))
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
