LOD = LOD or {}

local Rolls = LOD.CombatRolls
if not Rolls then return end

LOD.MagnumSuperExplosive = LOD.MagnumSuperExplosive or {}
local Magnum = LOD.MagnumSuperExplosive

local D12_START_THRESHOLD = 8
local D12_DEFAULT_BOOMCHAIN_FLOOR = 5
local MAGNUM_FALLBACK_CLIP = 6
local BURST_SPACING = 0.085
local MAX_CHAIN_DICE = 64
local EXTRA_ROUND_HEALTH_THRESHOLD = 60
local FINAL_PRESERVE_HEALTH_PERCENT = 34

-- Public tuning seam for future Magic/items. The default game-wide Boomchain
-- Floor is 5; later systems may lower this value or supply a lower per-profile
-- boomchainFloor without replacing the dice authority.
Rolls.D12BoomchainFloor = tonumber(Rolls.D12BoomchainFloor) or D12_DEFAULT_BOOMCHAIN_FLOOR

function Rolls:GetD12BoomchainFloor(profile)
    local requested = profile and tonumber(profile.boomchainFloor) or nil
    return math.Clamp(math.floor(requested or self.D12BoomchainFloor or D12_DEFAULT_BOOMCHAIN_FLOOR), 1, D12_START_THRESHOLD)
end

-- Global d12 rule: every fresh d12 chain starts at 8+. Every successful
-- explosion lowers the next d12 threshold by one until the Boomchain Floor is
-- reached. At the default floor the sequence is 8+, 7+, 6+, 5+, 5+... .
-- Non-d12 exploding dice continue through the established shared implementation.
if not Rolls.LODD12BoomchainInstalled then
    Rolls.LODD12BoomchainInstalled = true
    local baseRollExploding = Rolls._RollExploding

    function Rolls:_RollExploding(profile, rng)
        if not profile or tonumber(profile.sides) ~= 12 then
            return baseRollExploding(self, profile, rng)
        end

        local values = {}
        local contributions = {}
        local thresholds = {}
        local total = profile.bonus or 0
        local threshold = D12_START_THRESHOLD
        local boomchainFloor = self:GetD12BoomchainFloor(profile)
        local natural = rng:Int(1, 12)

        while natural and #values < MAX_CHAIN_DICE do
            values[#values + 1] = natural
            thresholds[#thresholds + 1] = threshold
            local contribution = math.max(profile.floor or natural, natural)
            contributions[#contributions + 1] = contribution
            total = total + contribution
            self.Stats.rolls = (self.Stats.rolls or 0) + 1

            if natural < threshold then break end
            threshold = math.max(boomchainFloor, threshold - 1)
            natural = rng:Int(1, 12)
        end

        return total, values, contributions, #values >= MAX_CHAIN_DICE, thresholds
    end
end

-- Enforce the already-authored global d6/d12 explosion invariants even when a
-- future caller uses the ordinary formula helper rather than explicitly asking
-- for _RollExploding. Each base die starts its own independent explosion chain;
-- bonuses are added once after all base dice resolve.
if not Rolls.LODGlobalExplodingFormulaInstalled then
    Rolls.LODGlobalExplodingFormulaInstalled = true
    local baseRollFormula = Rolls._RollFormula

    function Rolls:_RollFormula(profile, rng)
        local sides = profile and tonumber(profile.sides) or 0
        if sides ~= 6 and sides ~= 12 then
            return baseRollFormula(self, profile, rng)
        end

        local total = profile.bonus or 0
        local values = {}
        local count = math.max(1, math.floor(tonumber(profile.count) or 1))
        for _ = 1, count do
            local explodingProfile = {
                count = 1,
                sides = sides,
                exploding = sides == 6 and 6 or D12_START_THRESHOLD,
                floor = profile.floor,
                boomchainFloor = profile.boomchainFloor,
                bonus = 0
            }
            local dieTotal, dieValues = self:_RollExploding(explodingProfile, rng)
            total = total + (tonumber(dieTotal) or 0)
            for _, value in ipairs(dieValues or {}) do values[#values + 1] = value end
        end
        return total, values
    end
end

local function activeMagnum(ply)
    if not IsValid(ply) or not ply:IsPlayer() or not ply:Alive() then return nil end
    local weapon = ply:GetActiveWeapon()
    if not IsValid(weapon) or weapon:GetClass() ~= "weapon_357" then return nil end
    return weapon
end

local function magnumClipSize(weapon)
    local maximum = IsValid(weapon) and weapon:GetMaxClip1() or 0
    if not maximum or maximum <= 0 then maximum = MAGNUM_FALLBACK_CLIP end
    return math.max(1, math.floor(maximum))
end

-- Source's stock weapon_357 decrements Clip1 before Entity:FireBullets. Thus,
-- while resolving a real Magnum projectile, maxClip - Clip1 is the 1-based
-- trigger/chamber number and maxClip - Clip1 - 1 is the number of chambers that
-- were already empty before the current trigger pull.
local function cylinderState(weapon)
    if not IsValid(weapon) then return 0, 1, 0, MAGNUM_FALLBACK_CLIP end
    local maximum = magnumClipSize(weapon)
    local clipAfterTrigger = math.Clamp(math.floor(weapon:Clip1()), 0, maximum)
    local shotIndex = math.Clamp(maximum - clipAfterTrigger, 1, maximum)
    local emptyBefore = math.Clamp(shotIndex - 1, 0, maximum - 1)
    return emptyBefore, shotIndex, clipAfterTrigger, maximum
end

local function rollPercent(label, chance)
    chance = math.Clamp(math.floor(tonumber(chance) or 0), 0, 100)
    if chance <= 0 then return false end
    if chance >= 100 then return true end
    local rng = Rolls:_RNG(label)
    return rng:Int(1, 100) <= chance
end

-- One percentage point per whole HP below 60. This can add at most one projectile
-- to a trigger pull, regardless of the chamber's normal burst size.
local function lowHealthExtraRoundChance(ply)
    if not IsValid(ply) then return 0 end
    local hp = math.max(0, math.floor(tonumber(ply:Health()) or 0))
    return math.Clamp(EXTRA_ROUND_HEALTH_THRESHOLD - hp, 0, 100)
end

-- One percentage point per full percentage point of health below 34%.
-- Example: exactly 33% health => 1%; 20% => 14%; 1% => 33%.
local function finalRoundPreserveChance(ply)
    if not IsValid(ply) then return 0 end
    local maximum = math.max(1, tonumber(ply:GetMaxHealth()) or 100)
    local percent = math.Clamp((math.max(0, ply:Health()) / maximum) * 100, 0, 100)
    return math.Clamp(math.floor(FINAL_PRESERVE_HEALTH_PERCENT - percent + 0.0001), 0, 100)
end

-- Preserve every existing weapon wrapper (including the Shotgun identity pass),
-- then add the Magnum's cylinder bonus after its d12 Boomchain has resolved.
if not Rolls.LODMagnumCylinderDamageInstalled then
    Rolls.LODMagnumCylinderDamageInstalled = true
    local baseRollPlayerWeapon = Rolls.RollPlayerWeapon

    function Rolls:RollPlayerWeapon(ply, weaponClass)
        local contract = baseRollPlayerWeapon(self, ply, weaponClass)
        if weaponClass ~= "weapon_357" or not contract then return contract end

        local weapon = activeMagnum(ply)
        local bonus, shotIndex, clipAfter, maximum = cylinderState(weapon)
        contract.cylinderBonus = bonus
        contract.chamberShot = shotIndex
        contract.clipAfterTrigger = clipAfter
        contract.cylinderSize = maximum
        contract.boomchainFloor = self:GetD12BoomchainFloor()
        contract.total = (tonumber(contract.total) or 0) + bonus
        contract.formula = bonus > 0 and ("1d12!+" .. tostring(bonus)) or "1d12!"

        local thresholds = {}
        for i = 1, #(contract.values or {}) do
            thresholds[i] = math.max(contract.boomchainFloor, D12_START_THRESHOLD - (i - 1))
        end
        contract.boomThresholds = thresholds
        return contract
    end
end

-- Keep the combat feed's formula truthful without duplicating the central feed
-- authority. The core service asks for 1d12!/2d12!/3d12! text; this wrapper adds
-- the one cylinder bonus exactly once while the live Magnum contract is active.
if not Rolls.LODMagnumCylinderFeedInstalled then
    Rolls.LODMagnumCylinderFeedInstalled = true
    local baseDamageEventText = Rolls._DamageEventText

    function Rolls:_DamageEventText(source, formula, amount, target, detail,
        fallbackSource, fallbackTarget, damageSource)
        if IsValid(source) and source:IsPlayer() then
            local contract = source.LODActivePlayerRoll
            local bonus = contract and contract.weaponClass == "weapon_357"
                and math.max(0, math.floor(tonumber(contract.cylinderBonus) or 0)) or 0
            if bonus > 0 and isstring(formula) and string.find(formula, "d12!", 1, true)
                and not string.find(formula, "+", 1, true)
            then
                formula = formula .. "+" .. tostring(bonus)
            end
        end
        return baseDamageEventText(self, source, formula, amount, target, detail,
            fallbackSource, fallbackTarget, damageSource)
    end

    local basePlayerRollDetail = Rolls._PlayerRollDetail
    function Rolls:_PlayerRollDetail(contract)
        if contract and contract.weaponClass == "weapon_357" then
            local values = {}
            for i, value in ipairs(contract.values or {}) do
                local threshold = contract.boomThresholds and contract.boomThresholds[i] or D12_START_THRESHOLD
                values[#values + 1] = string.format("%d@%d+", value, threshold)
            end
            return string.format("[chamber %d/%d; +%d empty; boom %s%s]",
                contract.chamberShot or 1,
                contract.cylinderSize or MAGNUM_FALLBACK_CLIP,
                contract.cylinderBonus or 0,
                table.concat(values, ">"),
                contract.capped and "; chain cap" or "")
        end
        return basePlayerRollDetail(self, contract)
    end
end

Magnum.Bursts = Magnum.Bursts or setmetatable({}, {__mode = "k"})
Magnum.Stats = Magnum.Stats or {
    triggerShots = 0,
    twoRoundBursts = 0,
    threeRoundBursts = 0,
    injectedRounds = 0,
    lowHealthExtraRolls = 0,
    lowHealthExtraProcs = 0,
    finalPreserveRolls = 0,
    finalPreserveProcs = 0,
    finalPreserveApplied = 0
}

local function fireInjectedRound(ply, burst)
    local weapon = burst.weapon
    if not IsValid(ply) or not ply:Alive() or not IsValid(weapon) then return false end
    if ply:GetActiveWeapon() ~= weapon or weapon:GetClass() ~= "weapon_357" then return false end
    -- A reload changes Clip1. If it occurs before the short burst finishes, cancel
    -- stale follow-up rounds instead of applying an old chamber bonus to a new cylinder.
    if weapon:Clip1() ~= burst.clipAfterTrigger then return false end

    weapon:SendWeaponAnim(ACT_VM_PRIMARYATTACK)
    ply:SetAnimation(PLAYER_ATTACK1)
    ply:MuzzleFlash()
    weapon:EmitSound("Weapon_357.Single", 72, 100, 0.90, CHAN_WEAPON)
    ply:ViewPunch(Angle(-1.25, math.Rand(-0.35, 0.35), 0))

    local bullet = {
        Num = 1,
        Src = ply:GetShootPos(),
        Dir = burst.direction,
        Spread = vector_origin,
        Tracer = 1,
        Force = 8,
        Damage = 1,
        AmmoType = weapon:GetPrimaryAmmoType(),
        Attacker = ply,
        Inflictor = weapon
    }

    weapon.LODMagnumInjectedBurst = true
    ply:LagCompensation(true)
    ply:FireBullets(bullet)
    ply:LagCompensation(false)
    weapon.LODMagnumInjectedBurst = nil

    Magnum.Stats.injectedRounds = (Magnum.Stats.injectedRounds or 0) + 1
    return true
end

local function finishBurst(ply, burst)
    if burst and burst.preserveFinal and IsValid(burst.weapon) and burst.weapon:Clip1() == 0 then
        -- Apply preservation only after every injected projectile has rolled, so
        -- all bullets in the final-chamber burst continue to see chamber 6/+5.
        burst.weapon:SetClip1(1)
        Magnum.Stats.finalPreserveApplied = (Magnum.Stats.finalPreserveApplied or 0) + 1
    end
    Magnum.Bursts[ply] = nil
end

-- Stock Magnum trigger pulls remain authoritative for chamber/ammo consumption.
-- The fifth cartridge schedules one free follow-up projectile; the sixth/final
-- cartridge schedules two. Low health can add exactly one more free projectile to
-- any trigger. At very low percentage health, the final cartridge can be restored
-- after its whole burst, allowing the player to attempt another final-chamber shot.
hook.Add("EntityFireBullets", "LOD_MagnumCylinderBurst", function(shooter, bullet)
    local weapon = activeMagnum(shooter)
    if not IsValid(weapon) or weapon.LODMagnumInjectedBurst then return end

    local bonus, shotIndex, clipAfter, maximum = cylinderState(weapon)
    Magnum.Stats.triggerShots = (Magnum.Stats.triggerShots or 0) + 1

    local extraRounds = 0
    if maximum >= 2 and shotIndex == maximum - 1 and clipAfter == 1 then
        extraRounds = 1
        Magnum.Stats.twoRoundBursts = (Magnum.Stats.twoRoundBursts or 0) + 1
    elseif shotIndex == maximum and clipAfter == 0 then
        extraRounds = 2
        Magnum.Stats.threeRoundBursts = (Magnum.Stats.threeRoundBursts or 0) + 1
    end

    local extraChance = lowHealthExtraRoundChance(shooter)
    local lowHealthExtra = false
    if extraChance > 0 then
        Magnum.Stats.lowHealthExtraRolls = (Magnum.Stats.lowHealthExtraRolls or 0) + 1
        lowHealthExtra = rollPercent("magnum-low-health-extra:" .. tostring(shotIndex), extraChance)
        if lowHealthExtra then
            extraRounds = extraRounds + 1
            Magnum.Stats.lowHealthExtraProcs = (Magnum.Stats.lowHealthExtraProcs or 0) + 1
        end
    end

    local preserveFinal = false
    local preserveChance = 0
    if shotIndex == maximum and clipAfter == 0 then
        preserveChance = finalRoundPreserveChance(shooter)
        if preserveChance > 0 then
            Magnum.Stats.finalPreserveRolls = (Magnum.Stats.finalPreserveRolls or 0) + 1
            preserveFinal = rollPercent("magnum-final-preserve", preserveChance)
            if preserveFinal then
                Magnum.Stats.finalPreserveProcs = (Magnum.Stats.finalPreserveProcs or 0) + 1
            end
        end
    end

    if extraRounds <= 0 then return end

    local direction = bullet and bullet.Dir or shooter:GetAimVector()
    direction = direction and direction:GetNormalized() or vector_origin
    if direction == vector_origin then
        if preserveFinal and weapon:Clip1() == 0 then
            weapon:SetClip1(1)
            Magnum.Stats.finalPreserveApplied = (Magnum.Stats.finalPreserveApplied or 0) + 1
        end
        return
    end

    Magnum.Bursts[shooter] = {
        weapon = weapon,
        direction = direction,
        remaining = extraRounds,
        nextAt = CurTime() + BURST_SPACING,
        spacing = BURST_SPACING,
        cylinderBonus = bonus,
        clipAfterTrigger = clipAfter,
        lowHealthExtra = lowHealthExtra,
        extraChance = extraChance,
        preserveFinal = preserveFinal,
        preserveChance = preserveChance
    }
end)

hook.Add("Think", "LOD_MagnumCylinderBurstThink", function()
    local now = CurTime()
    for ply, burst in pairs(Magnum.Bursts) do
        if not IsValid(ply) or not burst or not IsValid(burst.weapon)
            or not ply:Alive() or ply:GetActiveWeapon() ~= burst.weapon
        then
            finishBurst(ply, burst)
        elseif now >= (burst.nextAt or math.huge) then
            if not fireInjectedRound(ply, burst) then
                finishBurst(ply, burst)
            else
                burst.remaining = (burst.remaining or 1) - 1
                if burst.remaining <= 0 then
                    finishBurst(ply, burst)
                else
                    burst.nextAt = burst.nextAt + (burst.spacing or BURST_SPACING)
                end
            end
        end
    end
end)

concommand.Add("lod_magnum_super_status", function(ply)
    local cv = GetConVar("lod_developer_mode")
    if cv and not cv:GetBool() then return end
    if IsValid(ply) and not ply:IsAdmin() then return end

    local validated = (Magnum.Stats.twoRoundBursts or 0) > 0
        and (Magnum.Stats.threeRoundBursts or 0) > 0
        and (Magnum.Stats.injectedRounds or 0) >= 3
    local hpExtraChance = IsValid(ply) and lowHealthExtraRoundChance(ply) or 0
    local preserveChance = IsValid(ply) and finalRoundPreserveChance(ply) or 0
    local line = string.format(
        "boomStart=%d boomFloor=%d cylinder=+0..+5 triggerShots=%d twoBursts=%d threeBursts=%d injected=%d lowHPChance=%d%% lowHPProcs=%d/%d finalKeepChance=%d%% finalKeepProcs=%d/%d applied=%d result=%s",
        D12_START_THRESHOLD,
        Rolls:GetD12BoomchainFloor(),
        Magnum.Stats.triggerShots or 0,
        Magnum.Stats.twoRoundBursts or 0,
        Magnum.Stats.threeRoundBursts or 0,
        Magnum.Stats.injectedRounds or 0,
        hpExtraChance,
        Magnum.Stats.lowHealthExtraProcs or 0,
        Magnum.Stats.lowHealthExtraRolls or 0,
        preserveChance,
        Magnum.Stats.finalPreserveProcs or 0,
        Magnum.Stats.finalPreserveRolls or 0,
        Magnum.Stats.finalPreserveApplied or 0,
        validated and "PASS" or "WAITING")
    print("[LOD:MAGNUM-SUPER] " .. line)
    if IsValid(ply) then ply:ChatPrint(line) end
end)
