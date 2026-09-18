-- Character-owned item records; slots describe occupancy, never weapon ownership.
LOD = LOD or {}
LOD.Equipment = LOD.Equipment or {}
local E = LOD.Equipment
E.MaximumStoredEquipment = 32
-- Capacity is a character rule, shared by admission, exchange and presentation.
-- No current authored perk/affix adds slots; future grants use this same delta.
function E:StorageCapacity(state)
    if CLIENT and state and state.storageCapacity then return state.storageCapacity end
    return math.max(0,math.min(256,math.floor(self.MaximumStoredEquipment+(tonumber(state and state.capacityBonus) or 0))))
end

E.SlotOrder = {"head", "body", "legs", "feet", "left_hand", "right_hand", "left_arm", "throwable"}
E.SlotLabels = {head="Head", body="Body", legs="Legs", feet="Feet", left_hand="Left Hand",
    right_hand="Right Hand", left_arm="Left Arm Accessory", throwable="Throwable"}
E.WeaponClass = "weapon_lod_throwable"
E.Definitions = {
    healing_potion = {name="Healing Potion", slots={"throwable"}, throwable=true, drinkable=true,
        effect="heal", amount=25, maxStack=3, model="models/props_junk/garbage_glassbottle003a.mdl",
        description="Drink to restore up to 25 HP, or throw to heal the first living allied Hero hit. One use; no Magic cost."}
}
-- Transport/impact choices from the equipment handoff; no explosive grenade damage.
E.ThrowSpeed, E.ThrowLift, E.ProjectileLifetime, E.UseCooldown = 700, 120, 5, 0.6

function E:Ensure(ps)
    if not ps then return nil end
    ps.equipment = ps.equipment or {items={}, slots={}}
    return ps.equipment
end

function E:Definition(item)
    return item and self.Definitions[item.definitionId]
end

function E:Equipped(state, slot)
    local id = state and state.slots[slot]
    local item = id and state.items[id]
    if item and (item.count or 0) > 0 then return item, id end
end

function E:AddConsumable(state, definitionId, count)
    local def = self.Definitions[definitionId]
    if not state or not def or not def.throwable then return false end
    count = tonumber(count)
    if not count or count < 1 or count ~= math.floor(count) then return false end
    local item = state.items[definitionId]
    local before = item and item.count or 0
    -- Pickups are atomic: a full stack leaves the pickup available to its owner.
    if before + count > def.maxStack then return false end
    state.items[definitionId] = {definitionId=definitionId, count=before + count}
    if not self:Equipped(state, "throwable") then self:Equip(state, definitionId, "throwable") end
    return true
end

function E:Unequip(state, slot)
    local id = state and state.slots[slot]
    if not id then return false end
    -- A paired item is removed from every occupied position in one transaction.
    for occupied, value in pairs(state.slots) do if value == id then state.slots[occupied] = nil end end
    return true
end

function E:Equip(state, id, slot)
    local item = state and state.items[id]
    local def = self:Definition(item)
    if not def or (item.count or 0) <= 0 or not self.SlotLabels[slot] then return false end
    local mask = def.occupancy or {slot}
    local compatible = false
    for _, allowed in ipairs(def.slots or {}) do if allowed == slot then compatible = true end end
    if not compatible then return false end
    for _, occupied in ipairs(mask) do if not self.SlotLabels[occupied] then return false end end
    -- Validate the entire mask before displacing any existing item. A displaced
    -- glove pair vacates both hands, including the hand outside the new mask.
    self:UnequipItem(state, id)
    for _, occupied in ipairs(mask) do self:Unequip(state, occupied) end
    for _, occupied in ipairs(mask) do state.slots[occupied] = id end
    return true
end

function E:UnequipItem(state, id)
    for slot, value in pairs(state.slots) do if value == id then state.slots[slot] = nil end end
end

function E:Consume(state, id)
    local item = state and state.items[id]
    if not item or (item.count or 0) < 1 then return false end
    item.count = item.count - 1
    if item.count == 0 then self:UnequipItem(state, id); state.items[id] = nil end
    return true
end

function E:Prompt(def)
    if not def or not def.throwable then return "" end
    return def.drinkable and "LMB: THROW   RMB: DRINK" or "LMB: THROW"
end

function E:IsActive(ply)
    if not IsValid(ply) or not ply:Alive() then return false end
    local weapon = ply:GetActiveWeapon()
    if not IsValid(weapon) or weapon:GetClass() ~= self.WeaponClass then return false end
    if CLIENT then return ply:GetNW2Int("LOD_ThrowableCount", 0) > 0 end
    local run = LOD.RunManager
    if not run or not run:IsActivePlayer(ply) or run:IsSoldierControl(ply) then return false end
    local ps = run:GetPlayerState(ply)
    return self:Equipped(ps and ps.equipment, "throwable") ~= nil
end
