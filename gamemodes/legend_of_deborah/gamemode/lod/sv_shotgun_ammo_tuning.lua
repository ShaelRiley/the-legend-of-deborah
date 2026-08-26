LOD = LOD or {}
LOD.ShotgunAmmoTuning = LOD.ShotgunAmmoTuning or {}

local Tuning = LOD.ShotgunAmmoTuning
local Ammo = LOD.DiceAmmo
local Loot = LOD.LootDirector

-- 2026-08-26 Shotgun economy nudge.
-- Integer rounding turns the requested ~15% increase into a 7-shell magazine
-- and 21-shell total family cap (up from 6/18). Loot grants are increased by
-- the same round-up principle per tier: 2/4/6 -> 3/5/7 shells.
local SHOTGUN_CLASS = "weapon_shotgun"
local SHOTGUN_AMMO = "Buckshot"
local SHOTGUN_MAGAZINE = 7
local SHOTGUN_TOTAL_CAP = 21
local SHOTGUN_RECOVERY = 90

local MAGNUM_CLASS = "weapon_357"
local MAGNUM_DROP_WEIGHT_MULTIPLIER = 1.25
local MAGNUM_EXTRA_ROUNDS_PER_DROP = 1

local PROFILES = {
    weapon_pistol = {
        label = "Pistol", ammo = "Pistol", load = 18, cap = 54,
        floor = 18, recovery = 60, pickup = 6
    },
    weapon_shotgun = {
        label = "Shotgun", ammo = SHOTGUN_AMMO, load = SHOTGUN_MAGAZINE,
        cap = SHOTGUN_TOTAL_CAP, floor = SHOTGUN_MAGAZINE,
        recovery = SHOTGUN_RECOVERY, pickup = 3
    },
    weapon_smg1 = {
        label = "SMG", ammo = "SMG1", load = 45, cap = 135,
        floor = 45, recovery = 120, pickup = 15
    },
    weapon_ar2 = {
        label = "AR2", ammo = "AR2", load = 20, cap = 60,
        floor = 20, recovery = 150, pickup = 10
    },
    weapon_357 = {
        label = ".357 Magnum", ammo = "357", load = 6, cap = 18,
        floor = 6, recovery = 180, pickup = 2
    }
}

local SHOTGUN_TIER_AMOUNTS = {small = 3, medium = 5, large = 7}

local function testkitBypass(ply, weaponClass)
    return weaponClass == "weapon_pistol" and IsValid(ply) and ply.LODM3InfiniteTestPistol == true
end

local function familyWeapon(ply, weaponClass)
    if not IsValid(ply) then return nil end
    local weapon = ply:GetWeapon(weaponClass)
    return IsValid(weapon) and weapon or nil
end

local function familyTotal(ply, weaponClass, profile)
    local weapon = familyWeapon(ply, weaponClass)
    local clip = weapon and math.max(0, weapon:Clip1()) or 0
    local reserve = IsValid(ply) and math.max(0, ply:GetAmmoCount(profile.ammo)) or 0
    return clip + reserve, clip, reserve, weapon
end

local function configureShotgunDefinition()
    local stored = weapons.GetStored and weapons.GetStored(SHOTGUN_CLASS) or nil
    if not stored then return false end
    stored.Primary = stored.Primary or {}
    stored.Primary.ClipSize = SHOTGUN_MAGAZINE
    stored.Primary.DefaultClip = SHOTGUN_MAGAZINE
    return true
end

local function configureShotgunInstance(weapon)
    if not IsValid(weapon) or weapon:GetClass() ~= SHOTGUN_CLASS then return false end
    weapon.Primary = weapon.Primary or {}
    weapon.Primary.ClipSize = SHOTGUN_MAGAZINE
    weapon.Primary.DefaultClip = SHOTGUN_MAGAZINE
    return true
end

local function clampShotgun(ply)
    if not IsValid(ply) then return false end
    local weapon = familyWeapon(ply, SHOTGUN_CLASS)
    if not IsValid(weapon) then return false end
    configureShotgunInstance(weapon)

    local changed = false
    local clip = math.max(0, math.floor(weapon:Clip1()))
    local reserve = math.max(0, math.floor(ply:GetAmmoCount(SHOTGUN_AMMO)))

    if clip > SHOTGUN_MAGAZINE then
        reserve = reserve + (clip - SHOTGUN_MAGAZINE)
        clip = SHOTGUN_MAGAZINE
        weapon:SetClip1(clip)
        changed = true
    end

    local allowedReserve = math.max(0, SHOTGUN_TOTAL_CAP - clip)
    if reserve > allowedReserve then
        reserve = allowedReserve
        changed = true
    end
    if ply:GetAmmoCount(SHOTGUN_AMMO) ~= reserve then
        ply:SetAmmo(reserve, SHOTGUN_AMMO)
    end
    return changed
end

configureShotgunDefinition()
hook.Add("InitPostEntity", "LOD_ShotgunAmmoTuningDefinition", configureShotgunDefinition)
hook.Add("OnReloaded", "LOD_ShotgunAmmoTuningReloadDefinition", configureShotgunDefinition)
hook.Add("WeaponEquip", "LOD_ShotgunAmmoTuningEquip", function(weapon, ply)
    if not IsValid(weapon) or weapon:GetClass() ~= SHOTGUN_CLASS then return end
    configureShotgunInstance(weapon)
    timer.Simple(0, function()
        if IsValid(ply) then clampShotgun(ply) end
    end)
end)

if Ammo then
    local previousClampFamily = Ammo.ClampFamily

    function Ammo:ClampFamily(ply, weaponClass, profile)
        if weaponClass == SHOTGUN_CLASS then return clampShotgun(ply) end
        return previousClampFamily(self, ply, weaponClass, profile)
    end

    function Ammo:Interrupt(ply, weaponClass, now)
        local profile = PROFILES[weaponClass]
        if not profile or not IsValid(ply) or testkitBypass(ply, weaponClass) then return end
        local state = self:_FamilyState(ply, weaponClass)
        state.nextRoundAt = (now or CurTime()) + 3.0 + profile.recovery / profile.floor
    end

    function Ammo:TickPlayer(ply, now)
        if not IsValid(ply) or not ply:Alive() then return end
        now = now or CurTime()

        for weaponClass, profile in pairs(PROFILES) do
            if not testkitBypass(ply, weaponClass) then
                self:ClampFamily(ply, weaponClass, profile)
                local total, _, _, weapon = familyTotal(ply, weaponClass, profile)
                local state = self:_FamilyState(ply, weaponClass)

                if not weapon or total >= profile.floor then
                    state.nextRoundAt = nil
                else
                    local interval = profile.recovery / profile.floor
                    state.nextRoundAt = state.nextRoundAt or (now + 3.0 + interval)
                    while total < profile.floor and now >= state.nextRoundAt do
                        ply:SetAmmo(ply:GetAmmoCount(profile.ammo) + 1, profile.ammo)
                        total = total + 1
                        state.nextRoundAt = state.nextRoundAt + interval
                        self.Stats.roundsRegenerated = (self.Stats.roundsRegenerated or 0) + 1
                    end
                    self:ClampFamily(ply, weaponClass, profile)
                end
            end
        end
    end

    function Ammo:GrantTemporaryDrop(ply)
        if not IsValid(ply) or not ply:IsPlayer() or not ply:Alive() then return false end
        local chosenClass, chosenProfile, chosenTotal, chosenRatio

        for weaponClass, profile in pairs(PROFILES) do
            if not testkitBypass(ply, weaponClass) then
                local total, _, _, weapon = familyTotal(ply, weaponClass, profile)
                if weapon and total < profile.cap then
                    local ratio = total / math.max(1, profile.cap)
                    if chosenRatio == nil or ratio < chosenRatio
                        or (ratio == chosenRatio and weaponClass < chosenClass)
                    then
                        chosenClass = weaponClass
                        chosenProfile = profile
                        chosenTotal = total
                        chosenRatio = ratio
                    end
                end
            end
        end

        if not chosenProfile then return false end
        local headroom = math.max(0, chosenProfile.cap - chosenTotal)
        local amount = math.min(headroom, math.max(1, chosenProfile.pickup or 1))
        if amount <= 0 then return false end
        ply:SetAmmo(ply:GetAmmoCount(chosenProfile.ammo) + amount, chosenProfile.ammo)
        self:ClampFamily(ply, chosenClass, chosenProfile)
        self.Stats.pickupsCollected = (self.Stats.pickupsCollected or 0) + 1
        self.Stats.pickupRounds = (self.Stats.pickupRounds or 0) + amount
        return true, chosenProfile.label, amount
    end
end

local function weightedPick(rng, entries)
    local total = 0
    for _, entry in ipairs(entries or {}) do total = total + math.max(0, entry.weight or 0) end
    if total <= 0 then return nil end
    local roll = rng:Float(0, total)
    local cursor = 0
    for _, entry in ipairs(entries or {}) do
        cursor = cursor + math.max(0, entry.weight or 0)
        if roll <= cursor then return entry.value end
    end
    return entries[#entries] and entries[#entries].value or nil
end

if Loot then
    function Loot:_AmmoNeed(ply)
        local need = 0
        for weaponClass, profile in pairs(PROFILES) do
            local total, _, _, weapon = familyTotal(ply, weaponClass, profile)
            if weapon and total < profile.cap then
                need = math.max(need, 1 - total / math.max(1, profile.cap))
            end
        end
        return need
    end

    function Loot:_ChooseAmmoFamily(ply, rng, preferredClass)
        local function usable(weaponClass)
            local profile = PROFILES[weaponClass]
            if not profile then return false end
            local total, _, _, weapon = familyTotal(ply, weaponClass, profile)
            if not weapon or testkitBypass(ply, weaponClass) then return false end
            return total < profile.cap, total
        end

        if preferredClass then
            local ok = usable(preferredClass)
            if ok then return preferredClass end
        end

        local choices = {}
        for weaponClass, profile in pairs(PROFILES) do
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

    function Loot:_GrantAmmo(ply, rng, tier, preferredClass)
        local weaponClass = self:_ChooseAmmoFamily(ply, rng, preferredClass)
        local profile = weaponClass and PROFILES[weaponClass]
        if not profile then return false end

        local total = familyTotal(ply, weaponClass, profile)
        local headroom = math.max(0, profile.cap - total)
        if headroom <= 0 then return false end

        local amount
        if weaponClass == SHOTGUN_CLASS then
            amount = SHOTGUN_TIER_AMOUNTS[tier or "small"] or SHOTGUN_TIER_AMOUNTS.small
        else
            local multiplier = tier == "large" and 3 or (tier == "medium" and 2 or 1)
            amount = math.max(1, profile.pickup * multiplier)
            if weaponClass == MAGNUM_CLASS then
                amount = amount + MAGNUM_EXTRA_ROUNDS_PER_DROP
            end
        end

        amount = math.min(headroom, amount)
        if amount <= 0 then return false end
        ply:SetAmmo(ply:GetAmmoCount(profile.ammo) + amount, profile.ammo)
        if Ammo and Ammo.ClampFamily then Ammo:ClampFamily(ply, weaponClass, profile) end
        return true, string.format("+%d %s ammo", amount, profile.label), amount, weaponClass
    end

    local previousGrantWeapon = Loot._GrantWeapon
    function Loot:_GrantWeapon(ply, weaponClass, rng)
        local hadShotgun = weaponClass == SHOTGUN_CLASS and IsValid(ply:GetWeapon(SHOTGUN_CLASS))
        local ok, message = previousGrantWeapon(self, ply, weaponClass, rng)
        if weaponClass == SHOTGUN_CLASS and ok then
            local weapon = ply:GetWeapon(SHOTGUN_CLASS)
            if IsValid(weapon) then
                configureShotgunInstance(weapon)
                if not hadShotgun then weapon:SetClip1(SHOTGUN_MAGAZINE) end
                clampShotgun(ply)
            end
        end
        return ok, message
    end
end

concommand.Add("lod_shotgun_ammo_status", function(ply)
    local cv = GetConVar("lod_developer_mode")
    if cv and not cv:GetBool() then return end
    if IsValid(ply) and not ply:IsAdmin() then return end

    local clip, reserve, total, maxClip = -1, -1, -1, -1
    if IsValid(ply) then
        local weapon = ply:GetWeapon(SHOTGUN_CLASS)
        if IsValid(weapon) then
            clip = weapon:Clip1()
            reserve = ply:GetAmmoCount(SHOTGUN_AMMO)
            total = clip + reserve
            maxClip = weapon:GetMaxClip1()
        end
    end

    local line = string.format(
        "Shotgun clip=%d maxClip=%d reserve=%d total=%d targetMag=%d cap=%d drops=3/5/7 floor=%d recovery=%ds",
        clip, maxClip, reserve, total, SHOTGUN_MAGAZINE, SHOTGUN_TOTAL_CAP,
        SHOTGUN_MAGAZINE, SHOTGUN_RECOVERY)
    print("[LOD:SHOTGUN-AMMO] " .. line)
    if IsValid(ply) then ply:ChatPrint(line) end
end)
