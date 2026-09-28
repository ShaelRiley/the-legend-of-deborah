-- Production catalog/generator; signatures, migration and bounded sample.
local root="gamemodes/legend_of_deborah/gamemode/lod/"
function Color(r,g,b) return {r=r,g=g,b=b} end
local function copy(t) local r={};for k,v in pairs(t) do r[k]=type(v)=="table" and copy(v) or v end;return r end
table.Copy=copy
local function equal(a,b)
    if type(a)~=type(b) then return false end
    if type(a)~="table" then return a==b end
    for k,v in pairs(a) do if not equal(v,b[k]) then return false end end
    for k in pairs(b) do if a[k]==nil then return false end end
    return true
end
dofile(root.."sh_rng.lua");dofile(root.."sh_equipment.lua");dofile(root.."sh_equipment_catalog.lua")
local E=LOD.Equipment
local old=E:Generate(77,20,"boots")
dofile(root.."sh_equipment_economy.lua")
dofile(root.."sh_magic_bombs.lua");dofile(root.."sh_travel_items.lua");dofile(root.."sh_damsel_revenge.lua")
local baseline=0;for _ in pairs(E.Definitions) do baseline=baseline+1 end
assert(baseline==45 and #E.EconomyOrder==60,"Freeze identities once, not affix permutations")
local frozen=E:Generate(991,20,"weapon_357","frozen")
dofile(root.."sh_big_loot_catalog.lua")
assert(E.BigLootBaseline==45 and #E.ArchetypeOrder==113)
assert(E:ValidateWearable(old),"Version-1 equipment survives")
assert(equal(frozen,E:Generate(991,20,"weapon_357","frozen")),"Ordinary version-2 rolls do not change")
assert(E:ValidateWearable(frozen),"Existing version-2 records survive")
assert(E:GenerateArchetype(1,1,"missing")==nil)
assert(E:Generate(1,1,"ring",nil,"bulkhead_treads")==nil,"Wrong family rejected")
local byBase,seen,samples,maxValue={}, {},0,0
for _,id in ipairs(E.ArchetypeOrder) do
    local a=E.Archetypes[id];byBase[a.base]=(byBase[a.base] or 0)+1
    assert(a.id==id and #a.motifs>=1 and #a.tags>=2 and a.description and a.weight>0)
    local sig=copy(a.signature);table.sort(sig);local key=table.concat(sig,"|")
    assert(not seen[key],"No signature duplicates hidden behind a different name, slot, element or drawback")
    seen[key]=true
    for _,level in ipairs({1,5,20,100,999}) do for seed=1,12 do
        local context="big-loot-test:"..id..":"..seed
        local item=assert(E:GenerateArchetype(seed,level,id,context))
        assert(item.definitionId==a.base and item.archetypeId==id)
        assert(E:ValidateWearable(item) and E:Value(item)==item.budget)
        assert(item.rarity>=a.minimumRarity and #item.properties==E.Rarities[item.rarity].affixes+1)
        assert(E:Description(item):find(a.description,1,true))
        assert(E:ItemName(item):find(a.name,1,true))
        local positives,negatives={},{}
        for _,r in ipairs(item.properties) do
            assert(r.amount==r.amount and math.abs(r.amount)<math.huge and r.power>0)
            if r.amount>0 then positives[r.id]=true else negatives[r.id]=true end
        end
        assert(positives["element_"..a.element] and negatives[a.drawback])
        for _,pid in ipairs(a.signature) do assert(positives[pid],"Signature missing: "..id..":"..pid) end
        if seed==1 then
            assert(equal(item,E:GenerateArchetype(seed,level,id,context)),"Deterministic replay")
            local state={items={},slots={},activeWeaponClass=a.base}
            assert(E:AcquireWearable(state,item,true),"Legal base-slot admission")
            local abilities,moves,block,extras=E:Contributions(state)
            for _,pid in ipairs(a.signature) do local p=E.EconomyProperties[pid]
                if p.ability then assert(abilities[p.ability]~=0)
                elseif p.move then assert(moves[p.move])
                elseif pid=="block" then assert(block>0)
                else assert(extras[pid] and extras[pid]>0) end
            end
            E:UnequipItem(state,item.id)
            local aa,mm,bb,xx=E:Contributions(state)
            for _,v in pairs(aa) do assert(v==0) end
            assert(next(mm)==nil and bb==0 and next(xx)==nil,"Unequip removes every package effect")
            local bad=copy(item);bad.archetypeId="unknown";assert(not E:ValidateWearable(bad))
            bad=copy(item);bad.archetypeId=E.ArchetypeOrder[id==E.ArchetypeOrder[1] and 2 or 1]
            assert(not E:ValidateWearable(bad),"Wrong package metadata rejected")
        end
        samples=samples+1;maxValue=math.max(maxValue,E:Value(item))
    end end
end
for _,base in ipairs(E.FamilyOrder) do assert((byBase[base] or 0)>=10,"Wearable choice enriched: "..base) end
for _,base in ipairs(E.WeaponFamilies) do assert((byBase[base] or 0)>=5,"Weapon choice enriched: "..base) end
assert(maxValue<2500,"Budget remains bounded, including gloves at level 999")
-- Appearance grammar and packet limits are unchanged because signatures reuse
-- the existing property vocabulary and 4..7-positive-affix count.
dofile(root.."sh_weapon_appearance.lua")
for _,id in ipairs(E.ArchetypeOrder) do local a=E.Archetypes[id]
    if E.Definitions[a.base].weapon then
        local item=E:GenerateArchetype(77,20,id,"appearance")
        local packet=LOD.WeaponAppearance:Encode(item)
        assert(#packet>0 and #packet<=480 and LOD.WeaponAppearance:Decode(packet))
    end
end
print(string.format("BIG_LOOT_CATALOG_PASS: baseline=%d additions=%d total=%d multiplier=%.4f samples=%d maxValue=%d",
    baseline,#E.ArchetypeOrder,baseline+#E.ArchetypeOrder,(baseline+#E.ArchetypeOrder)/baseline,samples,maxValue))
