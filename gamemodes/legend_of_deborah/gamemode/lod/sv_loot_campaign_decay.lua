LOD = LOD or {}

local Loot = LOD.LootDirector
local RunManager = LOD.RunManager
if not Loot or not RunManager or Loot.LODCampaignAssistanceDecayInstalled then return end
Loot.LODCampaignAssistanceDecayInstalled = true

-- Dungeon 1 keeps the production LootDirector exactly as tuned. Dungeons 2-10
-- linearly surrender its need-aware assistance. Dungeon 11+ retains only seeded
-- random loot outcomes; there is no pity, objective guarantee, deficit steering,
-- or resource-budget supplementation.
local RANDOM_USEFUL_CHANCE = 0.563
local PITY_USEFUL_CHANCE = 0.90
local OBJECTIVE_USEFUL_CHANCE = 1.00
local GRENADE_CAP = 3

local RANDOM_WEAPON_RESULTS = {
    "weapon_shotgun",
    "weapon_smg1",
    "weapon_357",
    "weapon_ar2",
    "weapon_frag"
}

-- Keep this synchronized with the final production ammo tuning loaded before
-- this module. These values are used only for family eligibility/weighting; the
-- actual grant amounts remain owned by Loot:_GrantAmmo.
local AMMO_PROFILES = {
    weapon_pistol = {ammo = "Pistol", cap = 54},
    weapon_shotgun = {ammo = "Buckshot", cap = 21},
    weapon_smg1 = {ammo = "SMG1", cap = 135},
    weapon_357 = {ammo = "357", cap = 18},
    weapon_ar2 = {ammo = "AR2", cap = 60}
}

local function currentLevel()
    return math.max(1, tonumber(RunManager.State and RunManager.State.Level) or 1)
end

function Loot:CampaignAssistance(level)
    level = math.max(1, tonumber(level) or currentLevel())
    if level <= 1 then return 1 end
    if level >= 11 then return 0 end
    return (11 - level) / 10
end

local function weightedPick(rng, entries)
    local total = 0
    for _, entry in ipairs(entries or {}) do
        total = total + math.max(0, tonumber(entry.weight) or 0)
    end
    if total <= 0 then return nil end

    local roll = rng:Float(0, total)
    local cursor = 0
    for _, entry in ipairs(entries or {}) do
        cursor = cursor + math.max(0, tonumber(entry.weight) or 0)
        if roll <= cursor then return entry.value end
    end
    return entries[#entries] and entries[#entries].value or nil
end

local function blend(randomValue, directedValue, assistance)
    assistance = math.Clamp(tonumber(assistance) or 0, 0, 1)
    return randomValue + (directedValue - randomValue) * assistance
end

local function familyTotal(ply, weaponClass, profile)
    if not IsValid(ply) or not profile then return 0, nil end
    local weapon = ply:GetWeapon(weaponClass)
    if not IsValid(weapon) then return 0, nil end
    return math.max(0, weapon:Clip1()) + math.max(0, ply:GetAmmoCount(profile.ammo)), weapon
end

-- At full assistance this reproduces the final depletion-weighted production
-- selector. As assistance decays, the depletion multiplier fades toward a flat
-- random choice among owned, non-full ammo families. The Magnum's 1.25x weight
-- remains an intrinsic weapon-economy tuning rather than a need-aware rescue.
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

-- Total useful-drop frequency remains the familiar 56.3% base random table.
-- What decays is the director's intervention: objective guarantees, five-kill
-- pity, and category weighting toward the player's current deficits.
function Loot:_DropCategory(ply, lootState, rng, guaranteedUseful)
    local assistance = self:CampaignAssistance()
    local pityEligible = (lootState.dryKills or 0) >= 5 and not guaranteedUseful

    local usefulChance = RANDOM_USEFUL_CHANCE
    if guaranteedUseful then
        usefulChance = blend(RANDOM_USEFUL_CHANCE, OBJECTIVE_USEFUL_CHANCE, assistance)
    elseif pityEligible then
        usefulChance = blend(RANDOM_USEFUL_CHANCE, PITY_USEFUL_CHANCE, assistance)
    end
    if not rng:Chance(usefulChance) then return nil, false end

    local maxHealth = math.max(1, ply:GetMaxHealth())
    local hpRatio = math.Clamp(ply:Health() / maxHealth, 0, 1)
    local ammoNeed = self:_AmmoNeed(ply)
    local weaponMissing = self:_MissingWeaponReward(ply, rng) ~= nil

    local directedAmmo = ammoNeed > 0 and 35 * (0.55 + ammoNeed * 1.85) or 0
    if hpRatio < 0.25 then
        directedAmmo = directedAmmo * 0.72
    elseif hpRatio < 0.55 then
        directedAmmo = directedAmmo * 0.88
    end

    local directedHealth = 0
    if hpRatio < 1 then
        local healthBand = 12 * (hpRatio < 0.25 and 4.5 or (hpRatio < 0.55 and 2.75 or 0.65))
        local formerArmorBand = 5 * (hpRatio < 0.25 and 2.8 or (hpRatio < 0.55 and 1.75 or 0.50))
        directedHealth = healthBand + formerArmorBand
    end

    local directedWeapon = 2.8 * (weaponMissing and 1.8 or 0.75)
    local directedLife = self:_CanUseExtraLife(ply) and 1.5 or 0

    local category = weightedPick(rng, {
        {value = "ammo", weight = blend(35.0, directedAmmo, assistance)},
        {value = "health", weight = blend(17.0, directedHealth, assistance)},
        {value = "weapon", weight = blend(2.8, directedWeapon, assistance)},
        {value = "life", weight = blend(1.5, directedLife, assistance)}
    })

    return category, pityEligible and assistance > 0 and category ~= nil
end

local function randomWeaponResult(rng)
    return RANDOM_WEAPON_RESULTS[rng:Int(1, #RANDOM_WEAPON_RESULTS)]
end

-- Enemy-drop payloads also surrender state-reading. Health's emergency +10 HP
-- bonus fades away, while the weapon band transitions from "missing weapon"
-- rescue toward an inventory-agnostic random firearm/grenade result.
function Loot:_SpawnEnemyResult(ply, hostile, category, rng)
    local ownerIdentity = RunManager:IdentityOf(ply)
    if not ownerIdentity then return false end

    local assistance = self:CampaignAssistance()
    local kind = category
    local payload = {}

    if category == "ammo" then
        local family = self:_ChooseAmmoFamily(ply, rng)
        if not family then return false end
        payload.tier = "small"
        payload.weaponClass = family
    elseif category == "health" then
        local emergencyBonus = ply:Health() <= ply:GetMaxHealth() * 0.30
            and math.floor(10 * assistance + 0.5) or 0
        payload.amount = 25 + emergencyBonus
    elseif category == "armor" then
        -- Armor is retired from production LOD; preserve the legacy adapter.
        kind = "health"
        payload.amount = 20
    elseif category == "weapon" then
        local reward
        if rng:Chance(assistance) then
            reward = self:_MissingWeaponReward(ply, rng)
            if not reward then
                if rng:Chance(0.35) and ply:GetAmmoCount("Grenade") < GRENADE_CAP then
                    reward = "weapon_frag"
                else
                    reward = "__cache"
                end
            end
        else
            reward = randomWeaponResult(rng)
        end

        if reward == "__cache" then
            kind = "cache"
        else
            kind = "weapon"
            payload.weaponClass = reward
        end
    elseif category == "life" then
        if not self:_CanUseExtraLife(ply) then return false end
        kind = "life"
    end

    local basePos = hostile:GetPos() + Vector(0, 0, 12)
    local angle = rng:Float(0, math.pi * 2)
    local radius = rng:Float(8, 18)
    local pos = basePos + Vector(math.cos(angle) * radius, math.sin(angle) * radius, 0)
    local ent = self:SpawnPickup(ownerIdentity, pos, kind, payload, {yaw = rng:Int(0, 359)})
    if IsValid(ent) then
        self.Stats.enemyDrops = (self.Stats.enemyDrops or 0) + 1
        return true
    end
    return false
end

local function randomStaticResult(rng)
    local roll = rng:Float(0, 100)
    if roll < 35.0 then
        return "ammo", {tier = "small"}
    elseif roll < 52.0 then
        return "health", {amount = 25}
    elseif roll < 54.8 then
        local reward = randomWeaponResult(rng)
        return "weapon", {weaponClass = reward}
    elseif roll < 56.3 then
        return "life", {}
    end
    return nil, nil
end

local baseBuildStaticPlan = Loot.BuildStaticPlan
function Loot:BuildStaticPlan(graph)
    local ok, planOrErr = baseBuildStaticPlan(self, graph)
    if not ok then return ok, planOrErr end

    local plan = planOrErr
    local level = math.max(1, tonumber(plan.level) or currentLevel())
    local assistance = self:CampaignAssistance(level)
    plan.campaignAssistance = assistance
    plan.lootMode = assistance <= 0 and "random" or (assistance >= 1 and "directed" or "blended")

    if level <= 1 then
        graph.LootPlan = plan
        self.StaticPlan = plan
        return true, plan
    end

    local kept = {}
    local directedNodes = 0
    local randomizedNodes = 0
    local removedNodes = 0
    local removedSupplements = 0

    for _, node in ipairs(plan.nodes or {}) do
        local rng = LOD.RNG.New(LOD.Seeds.Derive(plan.levelSeed or 1,
            string.format("loot-decay-static:%d", tonumber(node.id) or 0)))

        if node.role == "budget-supplement" then
            -- Budget supplements are pure anti-starvation intervention. Their
            -- existence itself fades to zero; they are never converted into a
            -- replacement random roll after Dungeon 10.
            if rng:Chance(assistance) then
                kept[#kept + 1] = node
                directedNodes = directedNodes + 1
            else
                removedNodes = removedNodes + 1
                removedSupplements = removedSupplements + 1
            end
        elseif rng:Chance(assistance) then
            kept[#kept + 1] = node
            directedNodes = directedNodes + 1
        else
            local kind, payload = randomStaticResult(rng)
            if kind then
                node.kind = kind
                node.payload = payload
                node.role = "random"
                node.directorRole = nil
                node.campaignRandomized = true
                kept[#kept + 1] = node
                randomizedNodes = randomizedNodes + 1
            else
                removedNodes = removedNodes + 1
            end
        end
    end

    plan.nodes = kept
    plan.decay = {
        assistance = assistance,
        directedNodes = directedNodes,
        randomizedNodes = randomizedNodes,
        removedNodes = removedNodes,
        removedSupplements = removedSupplements
    }

    -- The upstream validator may have added supplements before this final decay
    -- pass. Mark its report as pre-decay so diagnostics cannot misrepresent the
    -- actual committed floor as still meeting the old 70% intervention target.
    if plan.resourceBudget then
        plan.resourceBudget.preDecay = true
        plan.resourceBudget.finalAssistance = assistance
        plan.resourceBudget.finalSupplementsRemoved = removedSupplements
    end

    graph.LootPlan = plan
    self.StaticPlan = plan
    return true, plan
end

concommand.Add("lod_loot_decay_status", function(ply)
    local cv = GetConVar("lod_developer_mode")
    if cv and not cv:GetBool() then return end
    if IsValid(ply) and not ply:IsAdmin() then return end

    local level = currentLevel()
    local assistance = Loot:CampaignAssistance(level)
    local plan = Loot.StaticPlan
    local decay = plan and plan.decay or {}
    local mode = assistance <= 0 and "RANDOM" or (assistance >= 1 and "DIRECTED" or "BLENDED")
    local line = string.format(
        "level=%d assistance=%d%% mode=%s directed=%d randomized=%d removed=%d supplementsRemoved=%d",
        level,
        math.floor(assistance * 100 + 0.5),
        mode,
        decay.directedNodes or 0,
        decay.randomizedNodes or 0,
        decay.removedNodes or 0,
        decay.removedSupplements or 0)
    print("[LOD:LOOT-DECAY] " .. line)
    if IsValid(ply) then ply:ChatPrint(line) end
end)
