-- Reproduce the final campaign-decay override that production loads after the
-- base LootDirector. This boundary previously erased wearables/consumables.
local env=dofile('tools/test_equipment_economy_runtime.lua')
local root='gamemodes/legend_of_deborah/gamemode/lod/'
local E,Loot,Run=LOD.Equipment,LOD.LootDirector,env.Run
local hero=env.actor('drop-owner')
Run.State.PlayerState={['drop-owner']=hero.ps}
function hero:Armor() return 0 end
function hero:GetMaxHealth() return 100 end
function hero:Health() return 70 end
dofile(root..'sv_loot_campaign_decay.lua')

-- Every final runtime depth keeps both new natural categories, including after
-- deficit assistance has fully decayed.
for _,level in ipairs({1,6,11}) do
    Run.State.Level=level
    local counts={}
    for seed=1,5000 do
        local kind=Loot:_DropCategory(hero,{dryKills=0},LOD.RNG.New(seed*7919+level),false)
        counts[kind or 'none']=(counts[kind or 'none'] or 0)+1
    end
    assert((counts.wearable or 0)>400,'Wearables reachable at dungeon '..level)
    assert((counts.consumable or 0)>180,'Consumables reachable at dungeon '..level)
    assert((counts.weapon or 0)>180,'Procedural weapons remain reachable at dungeon '..level)
    assert((counts.none or 0)>800 and counts.none<1700,'Ordinary useful band remains near 75%')
end

local captured={}
local originalSpawn=Loot.SpawnPickup
local Vec={}
Vec.__index=Vec
function Vec.__add(a,b) return setmetatable({x=a.x+b.x,y=a.y+b.y,z=a.z+b.z},Vec) end
function Vector(x,y,z) return setmetatable({x=x or 0,y=y or 0,z=z or 0},Vec) end
function Loot:SpawnPickup(owner,pos,kind,payload,options)
    kind,payload=E:PrepareReward(owner,kind,payload,options)
    captured[#captured+1]={kind=kind,payload=payload,options=options}
    return {valid=true}
end
local families,potions={},{}
for serial=1,600 do
    local hostile={valid=true,LODInstanceSeed=serial}
    function hostile:GetPos() return Vector() end
    function hostile:EntIndex() return self.LODInstanceSeed end
    assert(Loot:_SpawnEnemyResult(hero,hostile,serial%2==0 and 'wearable' or 'consumable',LOD.RNG.New(serial*37)))
    local result=captured[#captured]
    assert(result.options.equipmentEligible==true and result.options.equipmentSeed==serial,
        'Final spawn path preserves equipment conversion identity')
    if result.kind=='wearable' then
        assert(E:ValidateWearable(result.payload.item))
        families[result.payload.item.definitionId]=true
    else
        assert(result.kind=='consumable')
        potions[result.payload.itemId]=(potions[result.payload.itemId] or 0)+1
    end
end
for _,family in ipairs(E.FamilyOrder) do assert(families[family],'Natural wearable family: '..family) end
for _,family in ipairs(E.InnateFamilyOrder or {}) do assert(families[family],'Natural innate family: '..family) end
-- Cards reserve 1/8, Feathers 1/8 of the remainder, then Hourglasses 1/16.
-- The healing/bomb mix receives 735/1024 of these 300 opportunities. Keys
-- convert 1/16 of healing outcomes only, after bombs have already returned.
-- Keep the existing bomb bound; scale the prior healing bound by 15/16 again.
assert((potions.healing_potion or 0)>120*(15/16)^2 and (potions.stink_bomb or 0)>15*15/16,
    'Eligible potion drops include Healing Potions and Stink Bombs')
assert((potions.summon_card or 0)>10 and (potions.resurrection_feather or 0)>10,
    'Final enemy-drop path exposes both travel and resurrection consumables')
assert((potions.magic_hourglass or 0)>3,'Final enemy-drop path exposes rare Hourglasses')
assert((potions.chest_key or 0)>0,'Final enemy-drop path exposes finite Chest Keys')
Loot.SpawnPickup=originalSpawn

-- Generator or payload failure is contained before a native entity is created.
local creates=0
ents={Create=function() creates=creates+1;return {valid=true} end}
local prepare=E.PrepareReward
E.PrepareReward=function() error('simulated generator failure') end
assert(Loot:SpawnPickup('drop-owner',Vector(),'wearable',{}, {equipmentEligible=true})==nil)
E.PrepareReward=function() return 'wearable',{item=nil} end
assert(Loot:SpawnPickup('drop-owner',Vector(),'wearable',{}, {equipmentEligible=true})==nil)
E.PrepareReward=prepare
assert(creates==0,'Invalid rewards cannot cross the native entity-creation boundary')

print('EQUIPMENT_DROP_MIX_PASS: final override exposes wearables, potions, Cards/Feathers/Hourglasses/Keys, equipment identity and crash-safe rejection')
