LOD = LOD or {}

local Loot = LOD.LootDirector
if not Loot then return end

local MAX_ARMOR = 100

-- All ordinary firearm upgrades can appear from Dungeon 1. Shotgun and SMG
-- remain the dominant early finds; Magnum is uncommon and AR2 is rarer still.
-- Later dungeons gently improve high-tier weighting without ever making those
-- weapons exclusive to a campaign-level gate.
local WEAPON_RARITY = {
    weapon_shotgun = {base = 1.00, perLevel = 0.00, cap = 1.00},
    weapon_smg1 = {base = 0.90, perLevel = 0.00, cap = 0.90},
    weapon_357 = {base = 0.28, perLevel = 0.06, cap = 0.55},
    weapon_ar2 = {base = 0.12, perLevel = 0.04, cap = 0.40}
}

local WEAPON_ORDER = {
    "weapon_shotgun",
    "weapon_smg1",
    "weapon_357",
    "weapon_ar2"
}

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

function Loot:_AllowedWeaponClasses()
    return table.Copy(WEAPON_ORDER)
end

function Loot:_MissingWeaponReward(ply, rng)
    local level = math.max(1, LOD.RunManager and LOD.RunManager.State and LOD.RunManager.State.Level or 1)
    local choices = {}

    for _, weaponClass in ipairs(WEAPON_ORDER) do
        if not IsValid(ply:GetWeapon(weaponClass)) then
            local rarity = WEAPON_RARITY[weaponClass]
            local weight = math.min(rarity.cap, rarity.base + rarity.perLevel * (level - 1))
            choices[#choices + 1] = {value = weaponClass, weight = weight}
        end
    end

    return weightedPick(rng, choices)
end

-- Contextual weighting is kept separate from the core pickup/grant machinery so
-- it can be tuned from dungeon-run evidence without touching entity ownership,
-- deterministic identity, or collection semantics. A roll that has already
-- entered the GDD's useful 56.3% band must not silently choose a resource that
-- the receiving player cannot currently use.
function Loot:_DropCategory(ply, lootState, rng, guaranteedUseful)
    local pity = (lootState.dryKills or 0) >= 5 and not guaranteedUseful
    local usefulChance = guaranteedUseful and 1.0 or (pity and 0.90 or 0.563)
    if not rng:Chance(usefulChance) then return nil, false end

    local maxHealth = math.max(1, ply:GetMaxHealth())
    local hpRatio = math.Clamp(ply:Health() / maxHealth, 0, 1)
    local armorRatio = math.Clamp(ply:Armor() / MAX_ARMOR, 0, 1)
    local ammoNeed = self:_AmmoNeed(ply)
    local weaponMissing = self:_MissingWeaponReward(ply, rng) ~= nil

    local ammoWeight = ammoNeed > 0 and 35 * (0.55 + ammoNeed * 1.85) or 0
    local healthWeight = hpRatio < 1 and
        12 * (hpRatio < 0.25 and 3.0 or (hpRatio < 0.55 and 2.0 or 0.55)) or 0
    local armorWeight = armorRatio < 1 and
        5 * (armorRatio < 0.25 and 2.2 or (armorRatio < 0.60 and 1.4 or 0.45)) or 0
    local weaponWeight = 2.8 * (weaponMissing and 1.8 or 0.75)
    local lifeWeight = self:_CanUseExtraLife(ply) and 1.5 or 0

    local category = weightedPick(rng, {
        {value = "ammo", weight = ammoWeight},
        {value = "health", weight = healthWeight},
        {value = "armor", weight = armorWeight},
        {value = "weapon", weight = weaponWeight},
        {value = "life", weight = lifeWeight}
    })

    -- A fully stocked player can still receive the weapon/large-cache band, but
    -- if every useful category is genuinely unavailable treat the outcome as an
    -- ordinary no-drop rather than spawning an unusable entity.
    return category, pity and category ~= nil
end
