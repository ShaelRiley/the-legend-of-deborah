-- Real catalog/generator/transactions and real RPG recomputation; no copied formulas.
dofile('tools/test_checkpoint_d_closure.lua')
SERVER,CLIENT=true,false
local root='gamemodes/legend_of_deborah/gamemode/lod/'
dofile(root..'sh_rng.lua');dofile(root..'sh_equipment.lua');dofile(root..'sh_equipment_catalog.lua')
local E=LOD.Equipment
local observed={}
for _,d in ipairs({1,6,20,21,26,51,96,100,101,999}) do
    for seed=1,250 do
        local a,b=E:Generate(seed,d),E:Generate(seed,d)
        assert(a.name==b.name and E:Description(a)==E:Description(b),'Generation must reproduce')
        assert(E:ValidateWearable(a) and E:Value(a)<=a.budget)
        for _,p in ipairs(a.properties) do observed[p.id]=true end
    end
end
for _,id in ipairs(E.PropertyOrder) do assert(observed[id],'Unreachable property '..id) end
assert(E:Budget(26,'ring')>E:Budget(20,'ring'),'Progression must continue past Hero cap')
assert(E:Budget(999,'gloves')==E:Budget(100,'gloves'))
assert(E:Budget(51,'gloves')==2*E:Budget(51,'ring'))
local function item(id,family,props)
    local a=E:Generate(id,100,family);a.properties=props;return a
end
local left=item(1,'ring',{{id='ability_str',amount=2}})
local right=item(2,'ring',{{id='move_rebuff',amount=1}})
local gloves=item(3,'gloves',{{id='ability_con',amount=4},{id='ability_str',amount=4}})
local state={items={},slots={}}
assert(E:AcquireWearable(state,left,false))
assert(E:AcquireWearable(state,right,false) and state.slots.left_hand==left.id and state.slots.right_hand==right.id)
local slot,displaced,value=E:Placement(state,gloves)
assert(#displaced==2 and value==50,'Gloves must compare BOTH displaced records')
assert(not E:AcquireWearable(state,gloves,false) and state.items[left.id] and state.items[right.id])
assert(E:AcquireWearable(state,gloves,true))
assert(not state.items[left.id] and not state.items[right.id] and state.slots.left_hand==gloves.id and state.slots.right_hand==gloves.id)
local delta=E:Contributions(state)
assert(delta.con==4 and delta.str==4,'Paired gloves effects count once')
assert(not E:AcquireWearable(state,gloves,true),'No duplicate record')
assert(E:Unequip(state,'left_hand') and not state.slots.right_hand)
assert(E:Contributions(state).con==0)
assert(not E:AcquireWearable(state,item(6,'shield',{{id='move_rebuff',amount=1}}),true),'Wrong family rejected')
assert(not E:AcquireWearable(state,item(7,'ring',{{id='ability_str',amount=1},{id='ability_str',amount=-1}}),true),'Opposing signs rejected')
assert(not E:AcquireWearable(state,item(8,'ring',{{id='ability_str',amount=6},{id='ability_dex',amount=1},{id='ability_con',amount=-6}}),true),'Refund cannot fund over-budget positives')
-- Real character state: gear affects effective scores, never feat qualification or intrinsic data.
local CPS=LOD.CharacterProgressionSystem
local progress=CPS:NewProgressionState('equipment-hero','hero','hero')
progress.classId='fighter';progress.baseAbilities=LOD.RPG.NewAbilityBlock(10)
CPS:_RecomputeProgressionState(progress)
local ps={equipment=state,progressionState=progress}
local before=progress.effectiveAbilities.con
local baseHP=progress.derivedStats.maxHP
local p={valid=true,hp=baseHP,max=baseHP}
IsValid=function(x) return type(x)=='table' and x.valid==true end
function p:SetMaxHealth(v) self.max=v end
function p:Health() return self.hp end
function p:SetHealth(v) self.hp=v end
CPS.SyncPlayer=function() end -- transport only; recomputation remains production
LOD.RunManager={State={LevelSeed=50,Level=51},GetPlayerState=function() return ps end}
dofile(root..'sv_equipment_wearables.lua')
E:RefreshDerived(p,ps)
assert(E:Equip(state,gloves.id,'left_hand'))
E:RefreshDerived(p,ps)
assert(progress.effectiveAbilities.con==before+4)
assert(progress.featQualificationAbilities.con==before,'Temporary equipment cannot qualify permanent feats')
assert(p.hp==baseHP,'Equipping CON must not heal')
E:Unequip(state,'right_hand');E:RefreshDerived(p,ps)
assert(progress.effectiveAbilities.con==before and p.max==baseHP)
-- Conversion uses its own stream and never replaces mandatory starters.
for i=1,100 do
    local kind=E:PrepareReward('owner','weapon',{}, {staticId=i,equipmentEligible=false})
    assert(kind=='weapon')
end
local converted=0
for i=1,1000 do
    local kind,payload=E:PrepareReward('owner','weapon',{}, {staticId=i,equipmentEligible=true})
    if kind=='wearable' then
        converted=converted+1
        local again,copy=E:PrepareReward('owner','weapon',{}, {staticId=i,equipmentEligible=true})
        assert(again==kind and payload.item.id==copy.item.id and payload.item.name==copy.item.name)
    end
end
assert(converted>150 and converted<350,'Independent 25% conversion sanity')
print('EQUIPMENT_CATALOG_PASS: 2500 deterministic items; all properties reachable; bounds, two-hand swap, no duplicate, real derived stats, starter protection')
