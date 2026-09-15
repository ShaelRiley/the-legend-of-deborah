-- LOD-EQUIP-015: Shael-approved first catalog. All values share this economy.
local E = assert(LOD.Equipment)
E.Abilities = {"str", "dex", "con", "int", "wis", "cha"}
E.FamilyOrder = {"headwear", "vest", "trousers", "boots", "ring", "gloves", "shield"}
local families = {
    headwear={name="Cap", slots={"head"}}, vest={name="Vest", slots={"body"}},
    trousers={name="Trousers", slots={"legs"}}, boots={name="Boots", slots={"feet"}},
    ring={name="Ring", slots={"left_hand","right_hand"}},
    gloves={name="Gloves", slots={"left_hand","right_hand"}, occupancy={"left_hand","right_hand"}},
    shield={name="Shield", slots={"left_arm"}}
}
for id, def in pairs(families) do
    def.wearable, def.model = true, "models/props_junk/cardboard_box004a.mdl"
    E.Definitions[id] = def
end
E.Definitions.stink_bomb = {name="Stink Bomb", slots={"throwable"}, throwable=true,
    drinkable=false, effect="poison_cloud", maxStack=3,
    model="models/props_junk/garbage_glassbottle003a.mdl",
    description="Throw a five-second poison cloud. Enemies entering it attempt the normal CON save against Poisoned. Cannot be drunk."}
E.SpecialMoves = {
    quickstep={id="quickstep", name="Quickstep", recipe={"UP","UP","UP"}, glyphs="↑ ↑ ↑",
        magicCost=10, cooldown=2, value=20, family="boots", effect="dash", distance=90, duration=0.2,
        description="Dash forward up to 90 units over 0.2 seconds; walls stop you. Ordinary speed-based Dodge applies."},
    rebuff={id="rebuff", name="Rebuff", recipe={"LEFT","DOWN","RIGHT"}, glyphs="← ↓ →",
        magicCost=20, cooldown=4, value=30, family="ring", effect="burst", cells=1, push=96,
        damageDice=1, damageSides=6,
        description="One-cell burst: 1d6 nonelemental Magic, then a 96-unit Push attempt on surviving damaged enemies."}
}
E.MoveOrder = {"quickstep", "rebuff"}
E.InputTimeout, E.BlockCap = 0.8, 0.33
E.PropertyOrder, E.Properties = {}, {}
local epithets = {str="Might", dex="Finesse", con="Fortitude", int="Insight", wis="Wisdom", cha="Presence"}
for _, ability in ipairs(E.Abilities) do
    local id = "ability_" .. ability
    E.PropertyOrder[#E.PropertyOrder+1] = id
    E.Properties[id] = {ability=ability, cost=10, maximum=6, epithet=epithets[ability]}
end
E.Properties.block = {cost=5, maximum=33, family="shield", epithet="Guarding"}
E.PropertyOrder[#E.PropertyOrder+1] = "block"
for _, id in ipairs(E.MoveOrder) do
    local move = E.SpecialMoves[id]
    local propertyId = "move_" .. id
    E.Properties[propertyId] = {move=id, cost=move.value, maximum=1, family=move.family, epithet=move.name}
    E.PropertyOrder[#E.PropertyOrder+1] = propertyId
end

function E:Budget(level, family)
    local d = math.max(1, math.min(100, math.floor(tonumber(level) or 1)))
    return (10 + 2 * math.floor((d-1)/5)) * (family == "gloves" and 2 or 1)
end

function E:Value(item)
    local positive, refund = 0, 0
    for _, record in ipairs(item and item.properties or {}) do
        local def = self.Properties[record.id]
        if def then
            local cost = def.cost * record.amount
            if cost >= 0 then positive = positive + cost else refund = refund - cost end
        end
    end
    return positive - math.min(refund, (item and item.budget or 0)*0.25)
end

function E:ValidateWearable(item)
    local family = self:Definition(item)
    if not family or not family.wearable or item.count ~= 1 or type(item.id) ~= "string"
        or type(item.properties) ~= "table" or #item.properties == 0 then return false end
    if item.budget ~= self:Budget(item.dungeonLevel, item.definitionId) then return false end
    local seen, positives, negatives = {}, 0, 0
    for _, record in ipairs(item.properties) do
        local def, amount = self.Properties[record.id], tonumber(record.amount)
        if not def or not amount or amount ~= math.floor(amount) or amount == 0
            or math.abs(amount) > def.maximum or seen[record.id]
            or def.family and def.family ~= item.definitionId then return false end
        seen[record.id] = true
        if amount < 0 then
            if not def.ability then return false end
            negatives = negatives + 1
        else positives = positives + 1 end
    end
    return positives >= 1 and positives <= 3 and negatives <= 1 and self:Value(item) <= item.budget
end

function E:Generate(seed, level, requestedFamily)
    local rng = LOD.RNG.New(LOD.Seeds.Derive(seed, "equipment-properties"))
    local family = requestedFamily or rng:Pick(self.FamilyOrder)
    local def = self.Definitions[family]
    if not def or not def.wearable then return nil end
    local item = {id="gear:"..tostring(seed)..":"..family, definitionId=family, count=1,
        dungeonLevel=level, budget=self:Budget(level,family), properties={}}
    local used, refund = {}, 0
    -- Equal choices among no drawback and the six ability drawbacks. A rank-one
    -- drawback can never fund more than 25% of the original opportunity budget.
    local drawback = rng:Int(0, #self.Abilities)
    if drawback > 0 then
        local id = "ability_" .. self.Abilities[drawback]
        item.properties[1] = {id=id, amount=-1}; used[id] = true
        refund = math.min(10, item.budget*0.25)
    end
    local remaining = item.budget + refund
    for _=1,3 do
        local choices = {}
        for _, id in ipairs(self.PropertyOrder) do
            local property = self.Properties[id]
            if not used[id] and (not property.family or property.family == family)
                and property.cost <= remaining then choices[#choices+1] = id end
        end
        local id = rng:Pick(choices)
        if not id then break end
        local property = self.Properties[id]
        local amount = rng:Int(1, math.min(property.maximum, math.floor(remaining/property.cost)))
        item.properties[#item.properties+1] = {id=id, amount=amount}
        used[id], remaining = true, remaining - property.cost*amount
    end
    local names = LOD.RNG.New(LOD.Seeds.Derive(seed, "equipment-names"))
    local signature
    for _, record in ipairs(item.properties) do if record.amount > 0 then signature = self.Properties[record.id].epithet; break end end
    item.name = names:Pick({"Dockyard", "Wayfarer's", "Labyrinth"}) .. " "
        .. names:Pick({"Patched", "Polished", "Weathered"}) .. " " .. def.name .. " of " .. (signature or "Resolve")
    assert(self:ValidateWearable(item), "Invalid generated equipment")
    return item
end

function E:ItemName(item)
    local def = self:Definition(item)
    return item and item.name or def and def.name or "Unknown item"
end

function E:Description(item, compact)
    local def = self:Definition(item)
    if not def then return "" end
    if def.throwable then return def.description end
    local parts = {}
    for _, record in ipairs(item.properties or {}) do
        local property = self.Properties[record.id]
        if property.ability then parts[#parts+1] = string.upper(property.ability) .. string.format(" %+d",record.amount)
        elseif property.move then
            local move = self.SpecialMoves[property.move]
            parts[#parts+1] = string.format("%s %s — %d Magic / %gs cooldown; %s", move.name, move.glyphs,
                move.magicCost, move.cooldown, compact and "" or move.description)
        else parts[#parts+1] = "Block +"..record.amount.."%" end
    end
    return table.concat(parts, "; ")
end

function E:Contributions(state)
    local abilities, moves, block, seen = {}, {}, 0, {}
    for _, ability in ipairs(self.Abilities) do abilities[ability] = 0 end
    for _, slot in ipairs(self.SlotOrder) do
        local item, id = self:Equipped(state, slot)
        if item and not seen[id] then
            seen[id] = true
            for _, record in ipairs(item.properties or {}) do
                local property = self.Properties[record.id]
                if property and property.ability then abilities[property.ability] = abilities[property.ability] + record.amount
                elseif property and property.move then moves[property.move] = true
                elseif record.id == "block" then block = block + record.amount/100 end
            end
        end
    end
    return abilities, moves, math.min(self.BlockCap, math.max(0,block))
end

function E:Placement(state, item, requestedSlot)
    local def = self:Definition(item)
    if not def then return nil end
    local slot = requestedSlot
    if not slot then
        slot = def.slots[1]
        for _, allowed in ipairs(def.slots) do if not self:Equipped(state,allowed) then slot=allowed; break end end
    end
    local allowed = false
    for _, candidate in ipairs(def.slots) do if candidate == slot then allowed=true end end
    if not allowed then return nil end
    local displaced, seen, value = {}, {}, 0
    for _, occupied in ipairs(def.occupancy or {slot}) do
        local old, id = self:Equipped(state,occupied)
        if old and not seen[id] then
            displaced[#displaced+1] = id; seen[id] = true; value=value+self:Value(old)
        end
    end
    return slot, displaced, value
end

function E:AcquireWearable(state, item, accept, requestedSlot)
    if not state or not self:ValidateWearable(item) or state.items[item.id] then return false end
    local slot, displaced = self:Placement(state,item,requestedSlot)
    if not slot or #displaced > 0 and not accept then return false end
    state.items[item.id] = item
    if not self:Equip(state,item.id,slot) then state.items[item.id]=nil; return false end
    -- Displaced equipment remains owned in the bag, including duplicate guns.
    return true
end
