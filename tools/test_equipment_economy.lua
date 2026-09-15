-- Distribution, semantic uniqueness, version migration and invalid-record gates.
local root='gamemodes/legend_of_deborah/gamemode/lod/'
dofile(root..'sh_rng.lua');dofile(root..'sh_equipment.lua');dofile(root..'sh_equipment_catalog.lua')
local E=LOD.Equipment
local legacy=E:Generate(9,26,'ring');local legacyValue=E:Value(legacy)
dofile(root..'sh_equipment_economy.lua')
assert(E:ValidateWearable(legacy) and E:Value(legacy)==legacyValue,'Existing records keep their original economics')
local families={};for _,f in ipairs(E.FamilyOrder) do families[#families+1]=f end
for _,f in ipairs(E.WeaponFamilies) do families[#families+1]=f end
local observed,counts,seen,duplicates={},{0,0,0,0},{},0
local means={}
for _,d in ipairs({1,20,21,100,500,999}) do
    local total=0
    for seed=1,1000 do
        local family=families[seed%#families+1]
        local a=E:Generate(seed,d,family,'test:'..seed)
        local b=E:Generate(seed,d,family,'test:'..seed)
        assert(a.name==b.name and E:Description(a)==E:Description(b))
        assert(E:ValidateWearable(a) and E:Value(a)==a.budget)
        assert(#a.properties==E.Rarities[a.rarity].affixes+1)
        local ids,groups={},{}
        for _,r in ipairs(a.properties) do
            local p=E.EconomyProperties[r.id];observed[r.id]=true
            assert(not ids[r.id]);ids[r.id]=true
            if p.group then assert(not groups[p.group]);groups[p.group]=true end
            assert(math.abs(r.amount)<= (p.maximum or p.fixed))
        end
        total=total+a.budget/(family=='gloves' and 2 or 1)
    end
    means[#means+1]=total/1000
end
for i=2,#means do assert(means[i]>means[i-1],'Deeper loot must increase expected value') end
for _,id in ipairs(E.EconomyOrder) do assert(observed[id],'Unreachable property '..id) end
for seed=1,10000 do
    local a=E:Generate(seed,20,'weapon_357','diversity:'..seed)
    counts[a.rarity]=counts[a.rarity]+1
    local semantic={}
    for _,r in ipairs(a.properties) do semantic[#semantic+1]=r.id..':'..r.amount end
    table.sort(semantic);local key=table.concat(semantic,'|')
    if seen[key] then duplicates=duplicates+1 end;seen[key]=true
end
assert(duplicates<10,'Too many repeated mechanical combinations (names/IDs excluded)')
for i,p in ipairs({.65,.25,.09,.01}) do assert(math.abs(counts[i]/10000-p)<.025,'Rarity distribution drift') end
assert(E:Budget(1000,'ring')==E:Budget(999,'ring'))
assert(E:Budget(999,'gloves')==2*E:Budget(999,'ring'))
local item=E:Generate(300,99,'boots')
local old=item.properties[2].power;item.properties[2].power=old+1
assert(not E:ValidateWearable(item),'Power/magnitude mismatch rejected');item.properties[2].power=old
old=item.quality;item.quality=0/0;assert(not E:ValidateWearable(item));item.quality=old
old=item.properties[3].id;item.properties[3].id=item.properties[2].id
assert(not E:ValidateWearable(item),'Duplicate property rejected');item.properties[3].id=old
assert(E:ValidateWearable(item))
local state={items={},slots={}}
local left=E:Generate(100,100,'ring');local right=E:Generate(101,100,'ring');local gloves=E:Generate(102,100,'gloves')
assert(E:AcquireWearable(state,left,false));assert(E:AcquireWearable(state,right,false))
local _,displaced,value=E:Placement(state,gloves)
assert(#displaced==2 and value==E:Value(left)+E:Value(right))
assert(not E:AcquireWearable(state,gloves,false));assert(E:AcquireWearable(state,gloves,true))
assert(state.items[left.id] and state.items[right.id])
local a,_,_,x=E:Contributions(state)
for _,r in ipairs(gloves.properties) do local p=E.EconomyProperties[r.id]
    if p.ability then assert(a[p.ability]==r.amount,'Gloves must count once')
    elseif not p.move then assert(x[r.id]==r.amount) end
end
print(string.format('PROCEDURAL_ECONOMY_PASS: 16,000 items; %d properties; %d repeated semantic combinations / 10,000 revolvers; rarity counts %d/%d/%d/%d; depth means %s',
    #E.EconomyOrder,duplicates,counts[1],counts[2],counts[3],counts[4],table.concat(means,',')))
