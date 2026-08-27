LOD = LOD or {}

local Loot = LOD.LootDirector
if not Loot or not Loot.CampaignAssistance then return end

-- Final post-decay ammo-family selector. This is intentionally the same campaign
-- assistance logic as sv_loot_campaign_decay.lua with only the SMG's final
-- 75-round family ceiling substituted, so a full SMG cannot remain falsely
-- eligible for contextual ammo drops above the production cap.
local AMMO_PROFILES = {
    weapon_pistol = {ammo = "Pistol", cap = 54},
    weapon_shotgun = {ammo = "Buckshot", cap = 21},
    weapon_smg1 = {ammo = "SMG1", cap = 75},
    weapon_357 = {ammo = "357", cap = 18},
    weapon_ar2 = {ammo = "AR2", cap = 60}
}

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
            local intrinsicWeight = weaponClass == "weapon_357" and 1.25 or 1.00
            choices[#choices + 1] = {
                value = weaponClass,
                weight = blend(intrinsicWeight, directedWeight * intrinsicWeight, assistance)
            }
        end
    end
    table.sort(choices, function(a, b) return a.value < b.value end)
    return weightedPick(rng, choices)
end
