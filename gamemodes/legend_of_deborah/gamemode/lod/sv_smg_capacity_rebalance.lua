LOD = LOD or {}
LOD.SMGCapacityRebalance = LOD.SMGCapacityRebalance or {}

local Balance = LOD.SMGCapacityRebalance
local Ammo = LOD.DiceAmmo
local Loot = LOD.LootDirector
if not Ammo or not Loot then return end

-- Runtime playtest rebalance: tighten the SMG to a 25-round magazine and preserve
-- the production three-reload-equivalent economy at 75 total rounds. The 33%
-- anti-deadlock floor therefore becomes exactly one 25-round magazine. Recovery
-- still takes 120 seconds from empty to that one-mag floor.
local SMG_CLASS = "weapon_smg1"
local SMG_AMMO = "SMG1"
local SMG_MAGAZINE = 25
local SMG_TOTAL_CAP = 75
local SMG_RECOVERY = 120

local MAGNUM_CLASS = "weapon_357"
local MAGNUM_DROP_WEIGHT_MULTIPLIER = 1.25
local MAGNUM_EXTRA_ROUNDS_PER_DROP = 1

local PROFILES = {
    weapon_pistol = {
        label = "Pistol", ammo = "Pistol", load = 18, cap = 54,
        floor = 18, recovery = 60, pickup = 6
    },
    weapon_shotgun = {
        label = "Shotgun", ammo = "Buckshot", load = 7, cap = 21,
        floor = 7, recovery = 90, pickup = 3
    },
    weapon_smg1 = {
        label = "SMG", ammo = SMG_AMMO, load = SMG_MAGAZINE,
        cap = SMG_TOTAL_CAP, floor = SMG_MAGAZINE,
        recovery = SMG_RECOVERY, pickup = 15
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

-- This is the final loaded ordinary-firearm profile table.  Expose it through
-- the shared ammunition authority so later RPG features never recreate weapon
-- capacities, clips, or recovery cadence in a parallel table.
Ammo.RegenerativeProfiles = PROFILES

function Ammo:RegenFloorRounds(ply, weaponClass, profile, derivedOverride)
    profile = profile or self.RegenerativeProfiles and self.RegenerativeProfiles[weaponClass]
    if not profile then return 0 end
    local derived = derivedOverride
    if not derived and IsValid(ply) then
        local rules = LOD.RPGAbilityRules
        derived = rules and rules.Derived and rules:Derived(ply) or nil
    end
    local fraction = math.Clamp(
        tonumber(derived and derived.ammoRegenFloorFraction) or 0.33, 0, 1)
    return math.Clamp(math.ceil(math.max(0, profile.cap or 0) * fraction), 0,
        math.max(0, math.floor(profile.cap or 0)))
end

local SHOTGUN_TIER_AMOUNTS = {small = 3, medium = 5, large = 7}

Balance.Stats = Balance.Stats or {clipClamps = 0, capClamps = 0}

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

function Ammo:RegenProfileSnapshot(ply)
    local result = {}
    for weaponClass, profile in pairs(PROFILES) do
        local total, _, _, weapon = familyTotal(ply, weaponClass, profile)
        if weapon then
            result[#result + 1] = {
                weaponClass = weaponClass,
                label = profile.label,
                total = total,
                cap = profile.cap,
                floor = self:RegenFloorRounds(ply, weaponClass, profile),
                baselineFloor = profile.floor,
                roundIntervalSeconds = profile.recovery / profile.floor
            }
        end
    end
    table.sort(result, function(a, b) return a.weaponClass < b.weaponClass end)
    return result
end

local function configureDefinition()
    local stored = weapons.GetStored and weapons.GetStored(SMG_CLASS) or nil
    if not stored then return false end
    stored.Primary = stored.Primary or {}
    stored.Primary.ClipSize = SMG_MAGAZINE
    stored.Primary.DefaultClip = SMG_MAGAZINE
    return true
end

local function configureInstance(weapon)
    if not IsValid(weapon) or weapon:GetClass() ~= SMG_CLASS then return false end
    weapon.Primary = weapon.Primary or {}
    weapon.Primary.ClipSize = SMG_MAGAZINE
    weapon.Primary.DefaultClip = SMG_MAGAZINE
    return true
end

local function clampSMG(ply)
    if not IsValid(ply) then return false end
    local weapon = familyWeapon(ply, SMG_CLASS)
    if not IsValid(weapon) then return false end
    configureInstance(weapon)

    local changed = false
    local clip = math.max(0, math.floor(weapon:Clip1()))
    local reserve = math.max(0, math.floor(ply:GetAmmoCount(SMG_AMMO)))

    if clip > SMG_MAGAZINE then
        reserve = reserve + (clip - SMG_MAGAZINE)
        clip = SMG_MAGAZINE
        weapon:SetClip1(clip)
        Balance.Stats.clipClamps = (Balance.Stats.clipClamps or 0) + 1
        changed = true
    end

    local allowedReserve = math.max(0, SMG_TOTAL_CAP - clip)
    if reserve > allowedReserve then
        reserve = allowedReserve
        Balance.Stats.capClamps = (Balance.Stats.capClamps or 0) + 1
        changed = true
    end
    if ply:GetAmmoCount(SMG_AMMO) ~= reserve then ply:SetAmmo(reserve, SMG_AMMO) end
    return changed
end

configureDefinition()
hook.Add("InitPostEntity", "LOD_SMGCapacityDefinition", configureDefinition)
hook.Add("OnReloaded", "LOD_SMGCapacityReloadDefinition", configureDefinition)
hook.Add("WeaponEquip", "LOD_SMGCapacityEquip", function(weapon, ply)
    if not IsValid(weapon) or weapon:GetClass() ~= SMG_CLASS then return end
    configureInstance(weapon)
    timer.Simple(0, function()
        if IsValid(ply) then clampSMG(ply) end
    end)
end)

local previousClampFamily = Ammo.ClampFamily
function Ammo:ClampFamily(ply, weaponClass, profile)
    if weaponClass == SMG_CLASS then return clampSMG(ply) end
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
            local floor = self:RegenFloorRounds(ply, weaponClass, profile)
            state.activeRegenFloor = floor

            if not weapon or total >= floor then
                state.nextRoundAt = nil
            else
                -- The feat changes the stopping ceiling only.  This remains the
                -- existing baseline per-round cadence, not a faster recovery.
                local interval = profile.recovery / profile.floor
                state.nextRoundAt = state.nextRoundAt or (now + 3.0 + interval)
                while total < floor and now >= state.nextRoundAt do
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
            if weaponClass == MAGNUM_CLASS then weight = weight * MAGNUM_DROP_WEIGHT_MULTIPLIER end
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
    if weaponClass == "weapon_shotgun" then
        amount = SHOTGUN_TIER_AMOUNTS[tier or "small"] or SHOTGUN_TIER_AMOUNTS.small
    else
        local multiplier = tier == "large" and 3 or (tier == "medium" and 2 or 1)
        amount = math.max(1, profile.pickup * multiplier)
        if weaponClass == MAGNUM_CLASS then amount = amount + MAGNUM_EXTRA_ROUNDS_PER_DROP end
    end

    amount = math.min(headroom, amount)
    if amount <= 0 then return false end
    ply:SetAmmo(ply:GetAmmoCount(profile.ammo) + amount, profile.ammo)
    Ammo:ClampFamily(ply, weaponClass, profile)
    return true, string.format("+%d %s ammo", amount, profile.label), amount, weaponClass
end

local previousGrantWeapon = Loot._GrantWeapon
function Loot:_GrantWeapon(ply, weaponClass, rng)
    local hadSMG = weaponClass == SMG_CLASS and IsValid(ply:GetWeapon(SMG_CLASS))
    local reserveBefore = weaponClass == SMG_CLASS and ply:GetAmmoCount(SMG_AMMO) or 0
    local ok, message = previousGrantWeapon(self, ply, weaponClass, rng)

    if weaponClass == SMG_CLASS and ok then
        local weapon = ply:GetWeapon(SMG_CLASS)
        if IsValid(weapon) then
            configureInstance(weapon)
            if not hadSMG then
                weapon:SetClip1(SMG_MAGAZINE)
                ply:SetAmmo(math.min(math.max(0, reserveBefore), SMG_TOTAL_CAP - SMG_MAGAZINE), SMG_AMMO)
            end
            clampSMG(ply)
        end
    end
    return ok, message
end

concommand.Add("lod_smg_ammo_status", function(ply)
    local cv = GetConVar("lod_developer_mode")
    if cv and not cv:GetBool() then return end
    if IsValid(ply) and not ply:IsAdmin() then return end

    local clip, reserve, total, maxClip = -1, -1, -1, -1
    if IsValid(ply) then
        local weapon = ply:GetWeapon(SMG_CLASS)
        if IsValid(weapon) then
            clip = weapon:Clip1()
            reserve = ply:GetAmmoCount(SMG_AMMO)
            total = clip + reserve
            maxClip = weapon:GetMaxClip1()
        end
    end

    local line = string.format(
        "SMG clip=%d maxClip=%d reserve=%d total=%d targetMag=%d cap=%d floor=%d recovery=%ds pickup=%d",
        clip, maxClip, reserve, total, SMG_MAGAZINE, SMG_TOTAL_CAP,
        SMG_MAGAZINE, SMG_RECOVERY, PROFILES[SMG_CLASS].pickup)
    print("[LOD:SMG-AMMO] " .. line)
    if IsValid(ply) then ply:ChatPrint(line) end
end)
