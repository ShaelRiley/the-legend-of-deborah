LOD = LOD or {}

local Loot = LOD.LootDirector
if not Loot or Loot.LODMagnumAmmoDropTuningInstalled then return end
Loot.LODMagnumAmmoDropTuningInstalled = true

-- Small post-balance nudge for the Magnum's daily-driver economy.
-- Depletion remains the dominant ammo-family selector, but an equivalently
-- depleted Magnum receives 25% more selection weight than its peers. Whenever
-- a real LootDirector ammo grant resolves to .357, add one extra cartridge,
-- subject to the existing 18-round loaded-plus-reserve cap.
local MAGNUM_CLASS = "weapon_357"
local MAGNUM_AMMO = "357"
local MAGNUM_TOTAL_CAP = 18
local MAGNUM_DROP_WEIGHT_MULTIPLIER = 1.25
local MAGNUM_EXTRA_ROUNDS_PER_DROP = 1

local AMMO_FAMILIES = {
    weapon_pistol = {ammo = "Pistol", cap = 54},
    weapon_shotgun = {ammo = "Buckshot", cap = 18},
    weapon_smg1 = {ammo = "SMG1", cap = 135},
    weapon_357 = {ammo = MAGNUM_AMMO, cap = MAGNUM_TOTAL_CAP},
    weapon_ar2 = {ammo = "AR2", cap = 60}
}

local function familyTotal(ply, weaponClass, profile)
    if not IsValid(ply) then return 0, nil end
    local weapon = ply:GetWeapon(weaponClass)
    if not IsValid(weapon) then return 0, nil end
    return math.max(0, weapon:Clip1()) + math.max(0, ply:GetAmmoCount(profile.ammo)), weapon
end

local function weightedPick(rng, entries)
    local total = 0
    for _, entry in ipairs(entries or {}) do
        total = total + math.max(0, entry.weight or 0)
    end
    if total <= 0 then return nil end

    local roll = rng:Float(0, total)
    local cursor = 0
    for _, entry in ipairs(entries) do
        cursor = cursor + math.max(0, entry.weight or 0)
        if roll <= cursor then return entry.value end
    end
    return entries[#entries] and entries[#entries].value or nil
end

-- This replaces only the current balance-pass selector. Explicitly preferred
-- ammo remains authoritative; otherwise every owned, non-full family participates
-- under the same depletion curve, with the Magnum receiving a modest 1.25x bias.
function Loot:_ChooseAmmoFamily(ply, rng, preferredClass)
    local function usable(weaponClass)
        local profile = AMMO_FAMILIES[weaponClass]
        if not profile then return false end
        if weaponClass == "weapon_pistol" and ply.LODM3InfiniteTestPistol == true then return false end
        local total, weapon = familyTotal(ply, weaponClass, profile)
        if not weapon then return false end
        return total < profile.cap, total, profile
    end

    if preferredClass then
        local ok = usable(preferredClass)
        if ok then return preferredClass end
    end

    local choices = {}
    for weaponClass, profile in pairs(AMMO_FAMILIES) do
        local ok, total = usable(weaponClass)
        if ok then
            local ratio = total / math.max(1, profile.cap)
            local weight = 0.35 + (1 - ratio) * 1.65
            if ratio < 0.50 then weight = weight * 2.25 end
            if weaponClass == MAGNUM_CLASS then
                weight = weight * MAGNUM_DROP_WEIGHT_MULTIPLIER
            end
            choices[#choices + 1] = {value = weaponClass, weight = weight}
        end
    end
    return weightedPick(rng, choices)
end

local baseGrantAmmo = Loot._GrantAmmo
function Loot:_GrantAmmo(ply, rng, tier, preferredClass)
    local ok, message, amount, weaponClass = baseGrantAmmo(self, ply, rng, tier, preferredClass)
    if not ok or weaponClass ~= MAGNUM_CLASS or not IsValid(ply) then
        return ok, message, amount, weaponClass
    end

    local profile = AMMO_FAMILIES[MAGNUM_CLASS]
    local total, weapon = familyTotal(ply, MAGNUM_CLASS, profile)
    if not weapon then return ok, message, amount, weaponClass end

    local headroom = math.max(0, MAGNUM_TOTAL_CAP - total)
    local bonus = math.min(MAGNUM_EXTRA_ROUNDS_PER_DROP, headroom)
    if bonus > 0 then
        ply:SetAmmo(ply:GetAmmoCount(MAGNUM_AMMO) + bonus, MAGNUM_AMMO)
        amount = math.max(0, tonumber(amount) or 0) + bonus
        message = string.format("+%d .357 Magnum ammo", amount)
    end

    return ok, message, amount, weaponClass
end

concommand.Add("lod_magnum_ammo_drop_status", function(ply)
    local cv = GetConVar("lod_developer_mode")
    if cv and not cv:GetBool() then return end
    if IsValid(ply) and not ply:IsAdmin() then return end

    local total = -1
    if IsValid(ply) then
        local weapon = ply:GetWeapon(MAGNUM_CLASS)
        if IsValid(weapon) then
            total = math.max(0, weapon:Clip1()) + math.max(0, ply:GetAmmoCount(MAGNUM_AMMO))
        end
    end

    local line = string.format(
        "Magnum dropWeight=%.2fx extraPerDrop=+%d total=%d/%d",
        MAGNUM_DROP_WEIGHT_MULTIPLIER,
        MAGNUM_EXTRA_ROUNDS_PER_DROP,
        total,
        MAGNUM_TOTAL_CAP)
    print("[LOD:MAGNUM-AMMO] " .. line)
    if IsValid(ply) then ply:ChatPrint(line) end
end)
