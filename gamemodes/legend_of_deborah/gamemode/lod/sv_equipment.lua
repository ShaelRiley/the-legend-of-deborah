LOD = LOD or {}
LOD.RuntimeReceipts = LOD.RuntimeReceipts or {}
LOD.RuntimeReceipts["equipment"] = "stability-20260915-05"
local E = assert(LOD.Equipment)
local Run = assert(LOD.RunManager)
E.NextUse = setmetatable({}, {__mode="k"})
E.PreviousWeapon = setmetatable({}, {__mode="k"})
E.Projectiles = setmetatable({}, {__mode="k"})
local requestTimes = setmetatable({}, {__mode="k"})
util.AddNetworkString("LOD_EquipmentRequest")
util.AddNetworkString("LOD_EquipmentSnapshot")

local function heroState(ply)
    if not IsValid(ply) or not ply:IsPlayer() or Run:IsSoldierControl(ply) then return nil end
    return Run:GetPlayerState(ply)
end

local function writeSnapshot(snapshot, previous, equal)
    if not previous then net.WriteTable(snapshot); return end
    -- Reliable, ordered delivery has already established a full baseline. Keep
    -- unchanged rolls client-side; weapon switches normally send just slots and
    -- active class. Explicit snapshot requests always reset to a full baseline.
    local state, removed = {items={}}, {}
    for key, value in pairs(snapshot) do if key ~= "items" then state[key] = value end end
    for id, item in pairs(snapshot.items) do
        if not equal(item, previous.items[id]) then state.items[id] = item end
    end
    for id in pairs(previous.items) do
        if not snapshot.items[id] then removed[#removed+1] = id end
    end
    net.WriteTable({equipmentDelta=true, state=state, removed=removed})
end

function E:CanAct(ply)
    local state = Run.State
    return heroState(ply) ~= nil and ply:Alive() and Run:IsActivePlayer(ply)
        and state and not state.Failed and not state.LevelCleared and not state.SimulationFrozen
end

function E:Sync(ply)
    if not IsValid(ply) then return end
    local ps = heroState(ply)
    local state = ps and self:Ensure(ps)
    if self.RefreshDerived then self:RefreshDerived(ply, ps) end
    if state and LOD.RPGAbilityRules and LOD.RPGAbilityRules.BlockChance then state.blockChance=LOD.RPGAbilityRules:BlockChance(ply) end
    local item = self:Equipped(state, "throwable")
    local def = self:Definition(item)
    ply:SetNW2String("LOD_ThrowableItem", item and item.definitionId or "")
    ply:SetNW2Int("LOD_ThrowableCount", item and item.count or 0)
    if LOD.SnapshotDelivery then
        LOD.SnapshotDelivery:Queue(ply, "LOD_EquipmentSnapshot", function(recipient)
            -- Resolve ownership at dispatch, including Hero/Soldier transitions.
            local current = heroState(recipient)
            return current and E:Ensure(current) or {items={}, slots={}}
        end, writeSnapshot)
    else
        net.Start("LOD_EquipmentSnapshot")
        net.WriteTable(state or {items={}, slots={}})
        net.Send(ply)
    end
    if item and ply:Alive() and Run:IsActivePlayer(ply) and not ply:HasWeapon(self.WeaponClass) then
        ply:Give(self.WeaponClass, true)
    elseif not def then self:Deactivate(ply) end
end

function E:Report(ply, text, event)
    if LOD.RPGPresentation and LOD.RPGPresentation.Event then
        LOD.RPGPresentation:Event(ply, "resource", text, {event=event})
    end
end

function E:Deactivate(ply)
    if not IsValid(ply) then return end
    local weapon = ply:GetActiveWeapon()
    if IsValid(weapon) and weapon:GetClass() == self.WeaponClass then
        local previous = self.PreviousWeapon[ply]
        if not previous or not ply:HasWeapon(previous) then previous = "weapon_lod_crowbar" end
        if ply:HasWeapon(previous) then ply:SelectWeapon(previous) end
    end
    self.PreviousWeapon[ply] = nil
end

function E:Activate(ply)
    if not self:CanAct(ply) then return false end
    local state = self:Ensure(heroState(ply))
    if not self:Equipped(state, "throwable") then return false end
    local weapon = ply:GetActiveWeapon()
    if IsValid(weapon) and weapon:GetClass() ~= self.WeaponClass then self.PreviousWeapon[ply] = weapon:GetClass() end
    self:Sync(ply)
    if not ply:HasWeapon(self.WeaponClass) then return false end
    ply:SelectWeapon(self.WeaponClass)
    return true
end

function E:Grant(ply, definitionId, count, source)
    local staging = LOD.StagingDeployment
    local stagedGift = staging and staging.CanCollectGift and staging:CanCollectGift(ply, source)
    if not self:CanAct(ply) and not stagedGift then return false end
    local state = self:Ensure(heroState(ply))
    if not self:AddConsumable(state, definitionId, count or 1) then return false end
    self:Sync(ply)
    return true, self.Definitions[definitionId].name .. " acquired"
end

function E:Heal(source, target, amount)
    if not self:CanAct(target) then return false end
    local ok, message = LOD.LootDirector:_GrantHealth(target, amount)
    if ok then
        target:EmitSound("items/smallmedkit1.wav", 65, 100, 0.8)
        self:Report(target, "HEALING POTION — " .. message, "potion_heal")
        if source ~= target and IsValid(source) then
            self:Report(source, "HEALING POTION — " .. message .. " to ally", "potion_heal_ally")
        end
    end
    return ok
end

function E:Use(ply, mode)
    if not self:CanAct(ply) or not self:IsActive(ply) then return false end
    if mode ~= "throw" and mode ~= "drink" then return false end
    local state = self:Ensure(heroState(ply))
    local item, id = self:Equipped(state, "throwable")
    local def = self:Definition(item)
    if not def or (mode == "drink" and not def.drinkable) or not def.throwable then return false end
    if CurTime() < (self.NextUse[ply] or 0) then return false end
    -- Unknown effect definitions fail before spending an item.
    if def.effect ~= "heal" and def.effect ~= "poison_cloud" then return false end
    if mode == "drink" and ply:Health() >= ply:GetMaxHealth() then return false end
    local projectile
    if mode == "throw" then
        if IsValid(self.Projectiles[ply]) then return false end
        projectile = ents.Create("lod_potion_projectile")
        if not IsValid(projectile) then return false end
        projectile.LODPotionDefinition = item.definitionId
        projectile.LODPotionState = state
        projectile.LODPotionRun = Run.State
        projectile.LODPotionLevelSeed = Run.State.LevelSeed
        projectile.LODPotionCaster = ply
        projectile:SetOwner(ply)
        projectile:SetPos(ply:GetShootPos())
        projectile:SetAngles(ply:EyeAngles())
        projectile:Spawn()
        if not IsValid(projectile) then return false end
        self.Projectiles[ply] = projectile
    end
    -- No client target/count/effect enters this transaction. No asynchronous
    -- callback can refund, replay or duplicate the committed unit.
    if not self:Consume(state, id) then if IsValid(projectile) then projectile:Remove() end; return false end
    self.NextUse[ply] = CurTime() + self.UseCooldown
    if mode == "drink" then self:Heal(ply, ply, def.amount)
    else ply:EmitSound("weapons/slam/throw.wav", 60, 110, 0.6) end
    self:Report(ply, def.name .. (mode == "drink" and " consumed" or " thrown"), "potion_" .. mode)
    self:Sync(ply)
    return true
end

-- The native gun stays owned: stowing cannot refill a magazine, destroy its
-- roll, or leave its bonuses active. Empty hands has no attack of its own.
function E:InventoryWeapon(ply,id,stow)
    if not self:CanAct(ply) then return false end
    local state=self:Ensure(heroState(ply))
    local def=self:Definition(state.items[id])
    if not def or not def.weapon then return false end
    if not stow and not IsValid(ply:GetWeapon(def.weaponClass)) and self.MaterializeWeapon then
        if not self:MaterializeWeapon(ply,id) then return false end
    end
    if not IsValid(ply:GetWeapon(def.weaponClass)) then return false end
    if stow then
        local active=ply:GetActiveWeapon()
        if state.slots[def.weaponClass]~=id or not IsValid(active) or active:GetClass()~=def.weaponClass then return false end
        if not ply:HasWeapon("weapon_lod_empty_hands") then ply:Give("weapon_lod_empty_hands",true) end
        if not ply:HasWeapon("weapon_lod_empty_hands") then return false end
    end
    if not stow and not self:Equip(state,id,def.weaponClass) then return false end
    ply:SelectWeapon(stow and "weapon_lod_empty_hands" or def.weaponClass)
    self:Sync(ply)
    return true
end

net.Receive("LOD_EquipmentRequest", function(bits, ply)
    if bits > 4096 or not IsValid(ply) then return end
    local now = CurTime()
    if now < (requestTimes[ply] or 0) then return end
    requestTimes[ply] = now + 0.10
    local action, id, slot = net.ReadString(), net.ReadString(), net.ReadString()
    if action == "snapshot" then
        if LOD.SnapshotDelivery then LOD.SnapshotDelivery:Invalidate(ply, "LOD_EquipmentSnapshot") end
        E:Sync(ply)
        return
    end
    if not E:CanAct(ply) then return end
    local state = E:Ensure(heroState(ply))
    if action == "activate" then
        if id=="" or state.slots.throwable==id then E:Activate(ply) end
    elseif action == "select_weapon" then E:InventoryWeapon(ply,id,false)
    elseif action == "stow_weapon" then E:InventoryWeapon(ply,id,true)
    elseif action == "deactivate" then E:Deactivate(ply)
    elseif action == "equip" then
        if E:Equip(state, id, slot) then E:Sync(ply) end
    elseif action == "unequip" then
        if state.slots[slot]==id and E:Unequip(state, slot) then E:Sync(ply) end
    elseif action == "discard" and E.Discard then
        if E.DiscardOwned and E:DiscardOwned(ply,id) then E:Sync(ply) end
    end
end)

-- Lifecycle applies existing identity-owned records. Never replenish on spawn.
local baseApply = Run.ApplyPlayerState
function Run:ApplyPlayerState(ply)
    if E.ClearTransient then E:ClearTransient(ply) end
    if E.RefreshDerived then E:RefreshDerived(ply, heroState(ply)) end
    baseApply(self, ply)
    E:Deactivate(ply)
    E:Sync(ply)
end
-- Staging deployment does not always reapply the full player state. Recreate
-- only the held-item adapter on this seam, without replenishing the item record.
if LOD.StagingDeployment then
    local staging = LOD.StagingDeployment
    local baseDeploy = staging._ExecuteDeploymentTransition
    function staging:_ExecuteDeploymentTransition(ply, ...)
        baseDeploy(self, ply, ...)
        E:Sync(ply)
    end
end
hook.Add("PlayerDeath", "LOD_EquipmentDeath", function(ply)
    if E.ClearTransient then E:ClearTransient(ply) end
    E:Deactivate(ply)
    E:Sync(ply)
end)
hook.Add("PlayerDisconnected", "LOD_EquipmentDisconnect", function(ply)
    if E.ClearTransient then E:ClearTransient(ply) end
    if IsValid(E.Projectiles[ply]) then E.Projectiles[ply]:Remove() end
    E.PreviousWeapon[ply], E.NextUse[ply], requestTimes[ply] = nil, nil, nil
end)

-- Reject obsolete stock pickups even when spawned by a map or external addon.
hook.Add("PlayerCanPickupWeapon", "LOD_NoOrdinaryGrenades", function(ply, weapon)
    if IsValid(ply) and ply.LODStarterNativeGrant then return true end
    if IsValid(weapon) and weapon:GetClass() == "weapon_frag" then return false end
end)
hook.Add("PlayerCanPickupItem", "LOD_NoGrenadeAmmo", function(_, item)
    if IsValid(item) and item:GetClass() == "item_ammo_grenade" then return false end
end)
hook.Add("WeaponEquip", "LOD_RejectOrdinaryGrenadeGrant", function(weapon, ply)
    timer.Simple(0, function()
        if not IsValid(weapon) or weapon:GetClass() ~= "weapon_frag" then return end
        if IsValid(ply) and weapon:GetOwner() == ply then
            ply:SetAmmo(0, "Grenade")
        end
        if IsValid(weapon) then weapon:Remove() end
    end)
end)

concommand.Add("lod_equipment_testkit", function(ply)
    local dev = GetConVar("lod_developer_mode")
    if not dev or not dev:GetBool() or not IsValid(ply) or not ply:IsAdmin() then return end
    if not E:CanAct(ply) then ply:ChatPrint("Deploy into the dungeon as a Hero first."); return end
    Run:MarkUnranked("equipment_testkit")
    local state = E:Ensure(heroState(ply))
    local owned = state.items.healing_potion and state.items.healing_potion.count or 0
    if owned < 3 then E:Grant(ply, "healing_potion", 3-owned) end
    ply:SetHealth(math.max(1, math.floor(ply:GetMaxHealth()*0.5)))
    E:Equip(state, "healing_potion", "throwable")
    E:Activate(ply)
    E:Report(ply, "EQUIPMENT TEST — 3 Healing Potions; LMB throw / RMB drink; switch weapons for Magic.", "equipment_testkit")
    print("[LOD:EQUIPMENT] testkit: identity=" .. tostring(Run:IdentityOf(ply)) .. " count=3")
end)

concommand.Add("lod_equipment_status", function(ply)
    local dev = GetConVar("lod_developer_mode")
    if not dev or not dev:GetBool() or not IsValid(ply) or not ply:IsAdmin() then return end
    local ps = heroState(ply)
    local item = E:Equipped(ps and ps.equipment, "throwable")
    local text = string.format("[LOD:EQUIPMENT] active=%s item=%s count=%d magic=%.2f",
        tostring(E:IsActive(ply)), item and item.definitionId or "none", item and item.count or 0,
        tonumber(ps and ps.magic) or 0)
    print(text); ply:ChatPrint(text)
end)
