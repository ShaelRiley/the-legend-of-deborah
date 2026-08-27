LOD = LOD or {}

local Loot = LOD.LootDirector
local Ammo = LOD.DiceAmmo
if not Loot or not Loot.CampaignAssistance or not Ammo then return end

-- Final post-decay ammo-family and pickup authority. Keep the campaign assistance
-- selector aligned with the production SMG cap, and apply the current playtest
-- pickup rebalance after every earlier ammo-tuning layer has loaded.
local AMMO_PROFILES = {
    weapon_pistol = {label = "Pistol", ammo = "Pistol", cap = 54, pickup = 6},
    weapon_shotgun = {label = "Shotgun", ammo = "Buckshot", cap = 21, pickup = 3},
    weapon_smg1 = {label = "SMG", ammo = "SMG1", cap = 75, pickup = 9},
    weapon_357 = {label = ".357 Magnum", ammo = "357", cap = 18, pickup = 2},
    weapon_ar2 = {label = "AR2", ammo = "AR2", cap = 60, pickup = 6}
}

local SMG_MAGAZINE = 25
local SMG_RECOVERY = 120
local MAGNUM_DROP_WEIGHT_MULTIPLIER = 1.25

local function familyTotal(ply, weaponClass, profile)
    if not IsValid(ply) or not profile then return 0, nil end
    local weapon = ply:GetWeapon(weaponClass)
    if not IsValid(weapon) then return 0, nil end
    return math.max(0, weapon:Clip1()) + math.max(0, ply:GetAmmoCount(profile.ammo)), weapon
end

local function blend(randomValue, directedValue, assistance)
    assistance = math.Clamp(tonumber(assistance) or 0, 0, 1)
    return randomValue + (directedValue - randomValue) * assistance
end

local function weightedPick(rng, entries)
    local total = 0
    for _, entry in ipairs(entries or {}) do total = total + math.max(0, tonumber(entry.weight) or 0) end
    if total <= 0 then return nil end
    local roll = rng:Float(0, total)
    local cursor = 0
    for _, entry in ipairs(entries or {}) do
        cursor = cursor + math.max(0, tonumber(entry.weight) or 0)
        if roll <= cursor then return entry.value end
    end
    return entries[#entries] and entries[#entries].value or nil
end

function Loot:_ChooseAmmoFamily(ply, rng, preferredClass)
    local assistance = self:CampaignAssistance()

    local function usable(weaponClass)
        local profile = AMMO_PROFILES[weaponClass]
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
    for weaponClass, profile in pairs(AMMO_PROFILES) do
        local ok, total = usable(weaponClass)
        if ok then
            local ratio = total / math.max(1, profile.cap)
            local directedWeight = 0.35 + (1 - ratio) * 1.65
            if ratio < 0.50 then directedWeight = directedWeight * 2.25 end
            local intrinsicWeight = weaponClass == "weapon_357" and MAGNUM_DROP_WEIGHT_MULTIPLIER or 1.00
            choices[#choices + 1] = {
                value = weaponClass,
                weight = blend(intrinsicWeight, directedWeight * intrinsicWeight, assistance)
            }
        end
    end
    table.sort(choices, function(a, b) return a.value < b.value end)
    return weightedPick(rng, choices)
end

-- The previous production grant routine still owns Pistol, Shotgun and Magnum
-- special handling. Intercept only the two families whose pickup size changed,
-- after selecting the family once so this wrapper never rerolls the reward.
local previousGrantAmmo = Loot._GrantAmmo
function Loot:_GrantAmmo(ply, rng, tier, preferredClass)
    local weaponClass = self:_ChooseAmmoFamily(ply, rng, preferredClass)
    if not weaponClass then return false end

    if weaponClass ~= "weapon_smg1" and weaponClass ~= "weapon_ar2" then
        return previousGrantAmmo(self, ply, rng, tier, weaponClass)
    end

    local profile = AMMO_PROFILES[weaponClass]
    local total = familyTotal(ply, weaponClass, profile)
    local headroom = math.max(0, profile.cap - total)
    if headroom <= 0 then return false end

    local multiplier = tier == "large" and 3 or (tier == "medium" and 2 or 1)
    local amount = math.min(headroom, math.max(1, profile.pickup * multiplier))
    if amount <= 0 then return false end

    ply:SetAmmo(ply:GetAmmoCount(profile.ammo) + amount, profile.ammo)
    Ammo:ClampFamily(ply, weaponClass, profile)
    return true, string.format("+%d %s ammo", amount, profile.label), amount, weaponClass
end

-- Keep the old temporary/death-pickup scaffold numerically consistent as well,
-- even though production enemy loot is now owned by LootDirector.
function Ammo:GrantTemporaryDrop(ply)
    if not IsValid(ply) or not ply:IsPlayer() or not ply:Alive() then return false end

    local chosenClass, chosenProfile, chosenTotal, chosenRatio
    for weaponClass, profile in pairs(AMMO_PROFILES) do
        if not (weaponClass == "weapon_pistol" and ply.LODM3InfiniteTestPistol == true) then
            local total, weapon = familyTotal(ply, weaponClass, profile)
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
    local amount = math.min(headroom, math.max(1, chosenProfile.pickup))
    if amount <= 0 then return false end

    ply:SetAmmo(ply:GetAmmoCount(chosenProfile.ammo) + amount, chosenProfile.ammo)
    self:ClampFamily(ply, chosenClass, chosenProfile)
    self.Stats.pickupsCollected = (self.Stats.pickupsCollected or 0) + 1
    self.Stats.pickupRounds = (self.Stats.pickupRounds or 0) + amount
    return true, chosenProfile.label, amount
end

-- Replace the earlier SMG status callback so it cannot continue advertising the
-- retired 15-round pickup after this final tuning layer has taken authority.
if concommand.Remove then concommand.Remove("lod_smg_ammo_status") end
concommand.Add("lod_smg_ammo_status", function(ply)
    local cv = GetConVar("lod_developer_mode")
    if cv and not cv:GetBool() then return end
    if IsValid(ply) and not ply:IsAdmin() then return end

    local clip, reserve, total, maxClip = -1, -1, -1, -1
    if IsValid(ply) then
        local weapon = ply:GetWeapon("weapon_smg1")
        if IsValid(weapon) then
            clip = weapon:Clip1()
            reserve = ply:GetAmmoCount("SMG1")
            total = clip + reserve
            maxClip = weapon:GetMaxClip1()
        end
    end

    local line = string.format(
        "SMG clip=%d maxClip=%d reserve=%d total=%d targetMag=%d cap=%d floor=%d recovery=%ds pickup=%d AR2pickup=%d",
        clip, maxClip, reserve, total, SMG_MAGAZINE, AMMO_PROFILES.weapon_smg1.cap,
        SMG_MAGAZINE, SMG_RECOVERY, AMMO_PROFILES.weapon_smg1.pickup,
        AMMO_PROFILES.weapon_ar2.pickup)
    print("[LOD:SMG-AMMO] " .. line)
    if IsValid(ply) then ply:ChatPrint(line) end
end)

concommand.Add("lod_ammo_pickup_status", function(ply)
    local cv = GetConVar("lod_developer_mode")
    if cv and not cv:GetBool() then return end
    if IsValid(ply) and not ply:IsAdmin() then return end

    local line = string.format(
        "SMG=%d/%d/%d AR2=%d/%d/%d (small/medium/large)",
        AMMO_PROFILES.weapon_smg1.pickup,
        AMMO_PROFILES.weapon_smg1.pickup * 2,
        AMMO_PROFILES.weapon_smg1.pickup * 3,
        AMMO_PROFILES.weapon_ar2.pickup,
        AMMO_PROFILES.weapon_ar2.pickup * 2,
        AMMO_PROFILES.weapon_ar2.pickup * 3)
    print("[LOD:AMMO-PICKUPS] " .. line)
    if IsValid(ply) then ply:ChatPrint(line) end
end)
