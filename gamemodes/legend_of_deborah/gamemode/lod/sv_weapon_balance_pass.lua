LOD = LOD or {}
LOD.WeaponBalancePass = LOD.WeaponBalancePass or {}

local Balance = LOD.WeaponBalancePass
local Ammo = LOD.DiceAmmo
local Loot = LOD.LootDirector
local Rolls = LOD.CombatRolls
local Magnum = LOD.MagnumSuperExplosive

-- Runtime balance pass from the 2026-08-26 full-run review.
-- AR2 keeps its authored one-cartridge three-projectile burst identity, but its
-- carried economy is reduced by one third: 30 -> 20 magazine, 90 -> 60 total.
-- Magnum gains an independent 25% chance for a trigger pull to conserve the
-- cartridge it would otherwise consume. Existing conditional conservation rolls
-- remain independent; two successful keep rolls never duplicate the same round.

local AR2_CLASS = "weapon_ar2"
local AR2_AMMO = "AR2"
local AR2_MAGAZINE = 20
local AR2_TOTAL_CAP = 60
local MAGNUM_CLASS = "weapon_357"
local MAGNUM_AMMO = "357"
local MAGNUM_TOTAL_CAP = 18
local MAGNUM_BASE_KEEP_CHANCE = 25
local MAGNUM_REFUND_DELAY = 0.40

local PROFILES = {
    weapon_pistol = {
        label = "Pistol", ammo = "Pistol", load = 18, cap = 54,
        floor = 18, recovery = 60, pickup = 6
    },
    weapon_shotgun = {
        label = "Shotgun", ammo = "Buckshot", load = 6, cap = 18,
        floor = 6, recovery = 90, pickup = 2
    },
    weapon_smg1 = {
        label = "SMG", ammo = "SMG1", load = 45, cap = 135,
        floor = 45, recovery = 120, pickup = 15
    },
    weapon_ar2 = {
        label = "AR2", ammo = AR2_AMMO, load = AR2_MAGAZINE,
        cap = AR2_TOTAL_CAP, floor = AR2_MAGAZINE, recovery = 150, pickup = 10
    },
    weapon_357 = {
        label = ".357 Magnum", ammo = MAGNUM_AMMO, load = 6, cap = 18,
        floor = 6, recovery = 180, pickup = 2
    }
}

Balance.Stats = Balance.Stats or {
    ar2ClipClamps = 0,
    ar2CapClamps = 0,
    magnumKeepRolls = 0,
    magnumKeepProcs = 0,
    magnumKeepApplied = 0,
    magnumKeepAlreadySatisfied = 0
}
Balance.MagnumPending = Balance.MagnumPending or setmetatable({}, {__mode = "k"})

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

local function configureAR2Definition()
    local stored = weapons.GetStored and weapons.GetStored(AR2_CLASS) or nil
    if not stored then return false end
    stored.Primary = stored.Primary or {}
    stored.Primary.ClipSize = AR2_MAGAZINE
    stored.Primary.DefaultClip = AR2_MAGAZINE
    return true
end

local function configureAR2Instance(weapon)
    if not IsValid(weapon) or weapon:GetClass() ~= AR2_CLASS then return false end
    weapon.Primary = weapon.Primary or {}
    weapon.Primary.ClipSize = AR2_MAGAZINE
    weapon.Primary.DefaultClip = AR2_MAGAZINE
    return true
end

-- Preserve ammunition when correcting an overfilled magazine (for example, if a
-- stock reload had already begun before this module saw the weapon): move excess
-- rounds to reserve, then enforce the 60-round family ceiling. New weapon grants
-- separately restore their pre-grant reserve so the authored starting load is 20.
local function clampAR2(ply)
    if not IsValid(ply) then return false end
    local weapon = familyWeapon(ply, AR2_CLASS)
    if not IsValid(weapon) then return false end
    configureAR2Instance(weapon)

    local changed = false
    local clip = math.max(0, math.floor(weapon:Clip1()))
    local reserve = math.max(0, math.floor(ply:GetAmmoCount(AR2_AMMO)))

    if clip > AR2_MAGAZINE then
        local overflow = clip - AR2_MAGAZINE
        clip = AR2_MAGAZINE
        reserve = reserve + overflow
        weapon:SetClip1(clip)
        Balance.Stats.ar2ClipClamps = (Balance.Stats.ar2ClipClamps or 0) + 1
        changed = true
    end

    local allowedReserve = math.max(0, AR2_TOTAL_CAP - clip)
    if reserve > allowedReserve then
        reserve = allowedReserve
        Balance.Stats.ar2CapClamps = (Balance.Stats.ar2CapClamps or 0) + 1
        changed = true
    end
    if ply:GetAmmoCount(AR2_AMMO) ~= reserve then ply:SetAmmo(reserve, AR2_AMMO) end
    return changed
end

configureAR2Definition()
hook.Add("InitPostEntity", "LOD_AR2BalanceDefinition", configureAR2Definition)
hook.Add("OnReloaded", "LOD_AR2BalanceReloadDefinition", configureAR2Definition)
hook.Add("WeaponEquip", "LOD_AR2BalanceEquip", function(weapon, ply)
    if not IsValid(weapon) or weapon:GetClass() ~= AR2_CLASS then return end
    configureAR2Instance(weapon)
    timer.Simple(0, function()
        if IsValid(ply) then clampAR2(ply) end
    end)
end)

if Ammo and not Ammo.LODWeaponBalancePassInstalled then
    Ammo.LODWeaponBalancePassInstalled = true
    local baseClampFamily = Ammo.ClampFamily

    function Ammo:ClampFamily(ply, weaponClass, profile)
        if weaponClass ~= AR2_CLASS then
            return baseClampFamily(self, ply, weaponClass, profile)
        end
        return clampAR2(ply)
    end

    function Ammo:Interrupt(ply, weaponClass, now)
        local profile = PROFILES[weaponClass]
        if not profile or not IsValid(ply) or testkitBypass(ply, weaponClass) then return end
        local state = self:_FamilyState(ply, weaponClass)
        state.nextRoundAt = (now or CurTime()) + 3.0 + profile.recovery / profile.floor
    end

    -- Keep the established passive-ammo semantics, with the AR2 floor following
    -- its new one-magazine load (20 rather than 30).
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

if Loot and not Loot.LODWeaponBalancePassInstalled then
    Loot.LODWeaponBalancePassInstalled = true

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
            if not weapon then return false end
            if testkitBypass(ply, weaponClass) then return false end
            return total < profile.cap, total, profile
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
        local multiplier = tier == "large" and 3 or (tier == "medium" and 2 or 1)
        local amount = math.min(headroom, math.max(1, profile.pickup * multiplier))
        if amount <= 0 then return false end
        ply:SetAmmo(ply:GetAmmoCount(profile.ammo) + amount, profile.ammo)
        if Ammo and Ammo.ClampFamily then Ammo:ClampFamily(ply, weaponClass, profile) end
        return true, string.format("+%d %s ammo", amount, profile.label), amount, weaponClass
    end

    local baseGrantWeapon = Loot._GrantWeapon
    function Loot:_GrantWeapon(ply, weaponClass, rng)
        local hadAR2 = weaponClass == AR2_CLASS and IsValid(ply:GetWeapon(AR2_CLASS))
        local ar2ReserveBefore = weaponClass == AR2_CLASS and ply:GetAmmoCount(AR2_AMMO) or 0
        local ok, message = baseGrantWeapon(self, ply, weaponClass, rng)
        if weaponClass == AR2_CLASS and ok then
            local weapon = ply:GetWeapon(AR2_CLASS)
            if IsValid(weapon) then
                configureAR2Instance(weapon)
                if not hadAR2 then
                    weapon:SetClip1(AR2_MAGAZINE)
                    ply:SetAmmo(math.min(math.max(0, ar2ReserveBefore), AR2_TOTAL_CAP - AR2_MAGAZINE), AR2_AMMO)
                end
                clampAR2(ply)
            end
        end
        return ok, message
    end
end

local function activeMagnum(ply)
    if not IsValid(ply) or not ply:IsPlayer() or not ply:Alive() then return nil end
    local weapon = ply:GetActiveWeapon()
    return IsValid(weapon) and weapon:GetClass() == MAGNUM_CLASS and weapon or nil
end

local function magnumTotal(ply, weapon)
    if not IsValid(ply) or not IsValid(weapon) then return 0 end
    return math.max(0, weapon:Clip1()) + math.max(0, ply:GetAmmoCount(MAGNUM_AMMO))
end

local function rollMagnumKeep()
    if not Rolls or not Rolls._RNG then return math.random(1, 100) <= MAGNUM_BASE_KEEP_CHANCE end
    local rng = Rolls:_RNG("magnum-base-ammo-conserve")
    return rng:Int(1, 100) <= MAGNUM_BASE_KEEP_CHANCE
end

hook.Add("EntityFireBullets", "LOD_MagnumBaseAmmoConserve", function(shooter)
    local weapon = activeMagnum(shooter)
    if not IsValid(weapon) or weapon.LODMagnumInjectedBurst then return end

    Balance.Stats.magnumKeepRolls = (Balance.Stats.magnumKeepRolls or 0) + 1
    if not rollMagnumKeep() then return end
    Balance.Stats.magnumKeepProcs = (Balance.Stats.magnumKeepProcs or 0) + 1

    -- Source has already consumed the cartridge when EntityFireBullets runs.
    -- Defer restitution beyond the Magnum's short free-projectile burst so its
    -- chamber bonus and existing final-round preservation see the unchanged
    -- post-trigger cylinder state. If another conservation mechanic has already
    -- restored the spent round, the target total is already satisfied and this
    -- independent proc does not manufacture a second cartridge.
    Balance.MagnumPending[shooter] = {
        weapon = weapon,
        targetTotal = math.min(MAGNUM_TOTAL_CAP, magnumTotal(shooter, weapon) + 1),
        applyAt = CurTime() + MAGNUM_REFUND_DELAY
    }
end)

hook.Add("Think", "LOD_MagnumBaseAmmoConserveApply", function()
    local now = CurTime()
    for ply, pending in pairs(Balance.MagnumPending) do
        if not IsValid(ply) or not ply:Alive() or not pending or not IsValid(pending.weapon) then
            Balance.MagnumPending[ply] = nil
        elseif now >= (pending.applyAt or math.huge)
            and not (Magnum and Magnum.Bursts and Magnum.Bursts[ply])
        then
            local weapon = pending.weapon
            local current = magnumTotal(ply, weapon)
            local target = math.min(MAGNUM_TOTAL_CAP, pending.targetTotal or current)
            if current < target then
                local needed = math.min(1, target - current)
                local maximum = weapon:GetMaxClip1()
                if not maximum or maximum <= 0 then maximum = 6 end
                if weapon:Clip1() < maximum then
                    weapon:SetClip1(math.min(maximum, weapon:Clip1() + needed))
                else
                    ply:SetAmmo(math.min(MAGNUM_TOTAL_CAP - weapon:Clip1(),
                        ply:GetAmmoCount(MAGNUM_AMMO) + needed), MAGNUM_AMMO)
                end
                Balance.Stats.magnumKeepApplied = (Balance.Stats.magnumKeepApplied or 0) + 1
            else
                Balance.Stats.magnumKeepAlreadySatisfied =
                    (Balance.Stats.magnumKeepAlreadySatisfied or 0) + 1
            end
            Balance.MagnumPending[ply] = nil
        end
    end
end)

hook.Add("PlayerDeath", "LOD_WeaponBalanceClearMagnumPending", function(ply)
    Balance.MagnumPending[ply] = nil
end)

concommand.Add("lod_weapon_balance_status", function(ply)
    local cv = GetConVar("lod_developer_mode")
    if cv and not cv:GetBool() then return end
    if IsValid(ply) and not ply:IsAdmin() then return end

    local clip, reserve, total, maxClip = -1, -1, -1, -1
    if IsValid(ply) then
        local ar2 = ply:GetWeapon(AR2_CLASS)
        if IsValid(ar2) then
            clip = ar2:Clip1()
            reserve = ply:GetAmmoCount(AR2_AMMO)
            total = clip + reserve
            maxClip = ar2:GetMaxClip1()
        end
    end

    local line = string.format(
        "AR2 clip=%d maxClip=%d reserve=%d total=%d targetMag=%d cap=%d | Magnum keep=%d%% procs=%d/%d applied=%d alreadySatisfied=%d",
        clip, maxClip, reserve, total, AR2_MAGAZINE, AR2_TOTAL_CAP,
        MAGNUM_BASE_KEEP_CHANCE,
        Balance.Stats.magnumKeepProcs or 0,
        Balance.Stats.magnumKeepRolls or 0,
        Balance.Stats.magnumKeepApplied or 0,
        Balance.Stats.magnumKeepAlreadySatisfied or 0)
    print("[LOD:WEAPON-BALANCE] " .. line)
    if IsValid(ply) then ply:ChatPrint(line) end
end)
