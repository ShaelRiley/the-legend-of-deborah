LOD = LOD or {}
LOD.RPGAbilityRules = LOD.RPGAbilityRules or {}
LOD.CombatAttributionSystem = LOD.CombatAttributionSystem or {}

local AbilityRules = LOD.RPGAbilityRules
local Attribution = LOD.CombatAttributionSystem
local RPG = LOD.RPG

local BASE_XP = {
    shambler = 20, runner = 25, soldier = 35, deadcrab = 20,
    bioblaster = 45, blitzer = 40, sniper = 45, flamer = 45,
    bigcrab = 80, big_crab = 80, watcher = 35, seeker = 40, sentry = 50,
    razor = 40, arccaster = 50, arc_caster = 50, lurker = 40,
    beamsweeper = 55, beam_sweeper = 55, neil = 150, brute = 250,
    warden = 500, gordon = 500, gordon_warden = 500
}

AbilityRules.Stats = AbilityRules.Stats or {
    physicalResolutions = 0,
    magicResolutions = 0,
    conDiceReduced = 0,
    evasions = 0,
    divertedHP = 0,
    divertedMagic = 0
}

Attribution.Stats = Attribution.Stats or {
    ledgers = 0,
    effectiveDamage = 0,
    deathsSettled = 0,
    xpAwarded = 0
}
Attribution.Ledgers = Attribution.Ledgers or setmetatable({}, {__mode = "k"})

local function runManager()
    return LOD.RunManager
end

function AbilityRules:ProgressionState(actor)
    if not IsValid(actor) then return nil end
    if actor:IsPlayer() then
        local run = runManager()
        local ps = run and run.GetPlayerState and run:GetPlayerState(actor) or nil
        return ps and ps.progressionState or nil
    end
    return actor.LODProgressionState
end

function AbilityRules:Derived(actor)
    local state = self:ProgressionState(actor)
    return state and state.derivedStats or nil
end

function AbilityRules:CopyDamageProfile(profile, actor)
    local copy = {}
    for key, value in pairs(profile or {}) do copy[key] = value end
    copy.rpgDerived = self:Derived(actor)
    return copy
end

function AbilityRules:ExplosionParameters(derived, sides, classExplosionImmune)
    sides = math.max(2, math.floor(tonumber(sides) or 2))
    local boomShift = math.Clamp(math.floor(tonumber(derived and derived.boomShift) or 0), 0, 2)
    local rogueShift = derived and derived.rogueAllDamageDiceExplode == true
        and classExplosionImmune ~= true and 1 or 0
    local capstoneShift = rogueShift > 0
        and math.max(0, math.floor(tonumber(derived and derived.rogueCapstoneBoomThresholdShift) or 0)) or 0
    if sides == 12 then
        return {
            fresh = math.max(2, 8 - rogueShift - capstoneShift),
            continuationFloor = rogueShift > 0
                and math.max(3, 5 - rogueShift - boomShift - capstoneShift)
                or math.max(4, 5 - boomShift),
            continuationStep = 1 + boomShift,
            boomShift = boomShift,
            rogue = rogueShift > 0
        }
    end
    if sides == 6 then
        return {
            fresh = math.max(rogueShift > 0 and 3 or 4, 6 - rogueShift - capstoneShift),
            continuation = math.max(rogueShift > 0 and 3 or 4,
                6 - rogueShift - capstoneShift - boomShift),
            boomShift = boomShift,
            rogue = rogueShift > 0
        }
    end
    return {
        fresh = math.max(2, sides - capstoneShift),
        continuation = math.max(2, sides - boomShift - capstoneShift),
        boomShift = boomShift,
        rogue = rogueShift > 0
    }
end

function AbilityRules:MovementMultiplier(actor)
    local derived = self:Derived(actor)
    return math.Clamp(tonumber(derived and derived.movementSpeedMultiplier) or 1, 0.85, 1.20)
end

function AbilityRules:AimSpreadMultiplier(actor)
    local derived = self:Derived(actor)
    return math.Clamp(tonumber(derived and derived.aimSpreadMultiplier) or 1, 0.60, 1.40)
end

function AbilityRules:MagicRegenMultiplier(actor)
    local derived = self:Derived(actor)
    local ability = tonumber(derived and derived.magicRegenMultiplier) or 1
    local capstone = tonumber(derived and derived.wizardCapstoneMagicRegenMultiplier) or 1
    return math.Clamp(ability, 0.50, 2.00) * math.max(0, capstone)
end

function AbilityRules:UtilityMagicCostMultiplier(actor)
    local derived = self:Derived(actor)
    return math.Clamp(tonumber(derived and derived.utilityMagicCostMultiplier) or 1, 0.60, 1.40)
end

function AbilityRules:BreadcrumbCells(actor)
    local derived = self:Derived(actor)
    return math.Clamp(math.floor(tonumber(derived and derived.breadcrumbCells) or 6), 2, 24)
end

function AbilityRules:HitStunMultiplier(attacker, defender)
    local attack = self:Derived(attacker)
    local defend = self:Derived(defender)
    local inflicted = math.Clamp(tonumber(attack and attack.chaHitStunInflictMultiplier) or 1, 0.75, 1.30)
    local resisted = math.Clamp(tonumber(defend and defend.chaHitStunResistanceMultiplier) or 1, 0.70, 1.25)
    return inflicted * resisted
end

function AbilityRules:ResolveDamageValues(contract, sourceDerived, targetDerived, tags)
    contract = contract or {}
    tags = tags or {}
    local resistance = tags.ignoreConDamageResistance and 0
        or math.Clamp(math.floor(tonumber(targetDerived and targetDerived.damageResistancePerDie) or 0), 0, 3)
    local total = tonumber(contract.bonus) or 0
    local contributions = contract.contributions or contract.values or {}
    local reduced = {}

    for index, value in ipairs(contributions) do
        local before = math.max(0, tonumber(value) or 0)
        local after = before > 0 and math.max(1, before - resistance) or 0
        reduced[index] = after
        total = total + after
        if after < before then self.Stats.conDiceReduced = (self.Stats.conDiceReduced or 0) + 1 end
    end

    total = total * math.max(0, tonumber(tags.authoredScale) or 1)
    if tags.physical then
        total = total * math.Clamp(tonumber(sourceDerived and sourceDerived.physicalDamageMultiplier) or 1, 0.50, 1.50)
        total = total * math.max(0, tonumber(sourceDerived and sourceDerived.fighterCapstonePhysicalDamageMultiplier) or 1)
        self.Stats.physicalResolutions = (self.Stats.physicalResolutions or 0) + 1
    elseif tags.magic and tags.wisScaled ~= false then
        total = total * math.Clamp(tonumber(sourceDerived and sourceDerived.magicPowerMultiplier) or 1, 0.60, 1.60)
        total = total * math.max(0, tonumber(sourceDerived and sourceDerived.wizardCapstoneMagicPowerMultiplier) or 1)
        self.Stats.magicResolutions = (self.Stats.magicResolutions or 0) + 1
    end

    return math.max(0, total), reduced, resistance
end

function AbilityRules:ResolveDamageContract(contract, attacker, target, tags)
    return self:ResolveDamageValues(contract, self:Derived(attacker), self:Derived(target), tags)
end

function AbilityRules:CommitAttack(actor)
    local derived = self:Derived(actor)
    if not derived or not IsValid(actor) then return false end
    local now = CurTime()
    local primeSeconds = tonumber(derived.rogueAcePrimeSeconds) or 0
    local primed = primeSeconds > 0
        and now >= (actor.LODRPGNextAceReadyAt or 0)
    if primeSeconds > 0 then actor.LODRPGNextAceReadyAt = now + primeSeconds end
    return primed
end

local function eligibleDirectAttack(target, attacker, dmginfo)
    if not IsValid(target) or not target:IsPlayer() or not target:Alive() then return false end
    if not IsValid(attacker) or attacker == target or attacker == game.GetWorld() then return false end
    if dmginfo:IsDamageType(DMG_FALL) or dmginfo:IsDamageType(DMG_CRUSH) then return false end
    return dmginfo:GetDamage() > 0
end

function AbilityRules:ComputeMagicDiversion(resolvedHPDamage, fraction, currentMagic, hpPerMagic)
    local resolved = math.floor(math.max(0, tonumber(resolvedHPDamage) or 0) + 0.5)
    local authoredFraction = math.Clamp(tonumber(fraction) or 0, 0, 1)
    local available = math.max(0, tonumber(currentMagic) or 0)
    local exchange = math.max(0.01, tonumber(hpPerMagic) or 1)
    local desiredHP = math.floor(resolved * authoredFraction + 0.5)
    local fundingMagic = exchange > 1 and available or math.floor(available)
    local divertedHP = math.min(desiredHP, fundingMagic * exchange)
    local spentMagic = divertedHP / exchange
    return divertedHP, spentMagic, math.max(0, resolved - divertedHP)
end

function AbilityRules:ApplyPlayerDefense(target, dmginfo)
    local derived = self:Derived(target)
    if not derived or not dmginfo or dmginfo:GetDamage() <= 0 then return nil end
    local attacker = dmginfo:GetAttacker()
    local resolved = math.max(0, dmginfo:GetDamage())
    local result = {
        resolvedHPDamageBeforeDiversion = resolved,
        actualMagicDiversion = 0,
        finalHPDamage = resolved,
        evaded = false
    }

    local evasionChance = math.Clamp(tonumber(derived.rogueCapstoneEvasionChance) or 0, 0, 1)
    if evasionChance > 0 and eligibleDirectAttack(target, attacker, dmginfo) then
        local rolls = LOD.CombatRolls
        local rng = rolls and rolls._RNG and rolls:_RNG("rogue-evasion:" .. tostring(target:EntIndex())) or nil
        if rng and rng:Float(0, 1) < evasionChance then
            dmginfo:SetDamage(0)
            dmginfo:SetDamageForce(vector_origin)
            result.finalHPDamage = 0
            result.evaded = true
            self.Stats.evasions = (self.Stats.evasions or 0) + 1
            if rolls._Send then rolls:_Send(target, 3, "CAPSTONE EVADE — NO DAMAGE") end
            target.LODRPGEvadedAt = CurTime()
            return result
        end
    end

    local fraction = math.Clamp(tonumber(derived.hpToMagicDiversionFraction) or 0, 0, 1)
    if fraction <= 0 then return result end
    local magic = LOD.Magic
    local ps = magic and magic._EnsureState and magic:_EnsureState(target) or nil
    if not ps or (tonumber(ps.magic) or 0) <= 0 then return result end

    local affordableHP, magicSpent, finalHP = self:ComputeMagicDiversion(resolved, fraction,
        ps.magic, derived.livingAegisHPPerMagic)
    ps.magic = math.max(0, (tonumber(ps.magic) or 0) - magicSpent)
    if magic._Sync then magic:_Sync(target, ps) end
    dmginfo:SetDamage(finalHP)
    result.actualMagicDiversion = affordableHP
    result.magicSpent = magicSpent
    result.finalHPDamage = finalHP
    self.Stats.divertedHP = (self.Stats.divertedHP or 0) + affordableHP
    self.Stats.divertedMagic = (self.Stats.divertedMagic or 0) + magicSpent
    target.LODRPGLastDiversion = {at = CurTime(), hp = affordableHP, magic = magicSpent}
    local rolls = LOD.CombatRolls
    if affordableHP > 0 and rolls and rolls._Send then
        rolls:_Send(target, 3, string.format("ARCANE DIVERSION — %.1f HP -> %.1f MAGIC; %.1f HP REMAINS",
            affordableHP, magicSpent, finalHP))
    end
    return result
end

local function identityForPlayer(ply)
    local run = runManager()
    if not IsValid(ply) or not ply:IsPlayer() or not run or not run.IdentityOf then return nil end
    local identity = run:IdentityOf(ply)
    local ps = identity and run:GetPlayerState(identity) or nil
    return ps and ps.progressionState and identity or nil
end

local function creditedAttacker(target, dmginfo)
    local pending = target.LODPendingDamageAttribution
    if pending and IsValid(pending.attacker) then return pending.attacker end
    local attacker = dmginfo and dmginfo:GetAttacker() or nil
    return IsValid(attacker) and attacker or nil
end

function Attribution:Record(target, dmginfo)
    if not IsValid(target) or not target.LODHostile or target.LODDead or not dmginfo then return end
    local attacker = creditedAttacker(target, dmginfo)
    local identity = identityForPlayer(attacker)
    if not identity then return end
    local damage = math.min(math.max(0, target:Health()), math.max(0, dmginfo:GetDamage()))
    if damage <= 0 then return end

    local ledger = self.Ledgers[target]
    if not ledger then
        ledger = {effectiveDamageByHeroId = {}, totalEligibleEffectiveDamage = 0, resolved = false}
        self.Ledgers[target] = ledger
        self.Stats.ledgers = (self.Stats.ledgers or 0) + 1
    end
    if ledger.resolved then return end
    ledger.effectiveDamageByHeroId[identity] = (ledger.effectiveDamageByHeroId[identity] or 0) + damage
    ledger.totalEligibleEffectiveDamage = ledger.totalEligibleEffectiveDamage + damage
    if damage >= target:Health() then ledger.killingBlowHeroId = identity end
    self.Stats.effectiveDamage = (self.Stats.effectiveDamage or 0) + damage
end

local function xpValue(hostile)
    local base = BASE_XP[string.lower(tostring(hostile.LODArchetypeId or ""))]
    if not base then return 0 end
    local level = math.Clamp(math.floor(tonumber(hostile.LODCharacterLevel) or 1), 1, 20)
    return math.max(5, 5 * math.floor((base * (1 + 0.05 * (level - 1))) / 5 + 0.5))
end

local function replacementAward(identity, amount, hostile)
    if hostile.LODWanderSpawnReason ~= "replacement" then return amount end
    local run = runManager()
    local ps = run and run:GetPlayerState(identity) or nil
    local state = ps and ps.progressionState
    if not state then return 0 end
    local entryLevel = math.Clamp(math.floor(tonumber(state.dungeonEntryLevel) or state.level or 1), 1, 20)
    local nextXP = RPG.HeroXPThresholds[math.min(20, entryLevel + 1)] or RPG.Constants.HeroMaxXP
    local currentXP = RPG.HeroXPThresholds[entryLevel] or 0
    local budget = math.floor(math.max(0, nextXP - currentXP) * 0.25)
    local used = math.max(0, math.floor(tonumber(state.replacementXpEarnedThisDungeon) or 0))
    local granted = math.min(amount, math.max(0, budget - used))
    state.replacementXpEarnedThisDungeon = used + granted
    return granted
end

function Attribution:_Award(identity, amount, hostile)
    amount = replacementAward(identity, math.max(0, math.floor(amount or 0)), hostile)
    if amount <= 0 then return 0 end
    local progression = LOD.CharacterProgressionSystem
    if not progression or not progression.AwardHeroXP then return 0 end
    local ok = progression:AwardHeroXP(identity, amount)
    if not ok then return 0 end
    self.Stats.xpAwarded = (self.Stats.xpAwarded or 0) + amount
    return amount
end

function Attribution:LargestRemainderShares(pool, damageByIdentity)
    pool = math.max(0, math.floor(tonumber(pool) or 0))
    local total = 0
    for _, damage in pairs(damageByIdentity or {}) do total = total + math.max(0, tonumber(damage) or 0) end
    local shares, allocated = {}, 0
    if total <= 0 then return shares end
    for identity, damage in pairs(damageByIdentity or {}) do
        local raw = pool * math.max(0, tonumber(damage) or 0) / total
        local whole = math.floor(raw)
        shares[#shares + 1] = {identity = identity, amount = whole, remainder = raw - whole}
        allocated = allocated + whole
    end
    table.sort(shares, function(a, b)
        if a.remainder ~= b.remainder then return a.remainder > b.remainder end
        return tostring(a.identity) < tostring(b.identity)
    end)
    local leftovers = pool - allocated
    for index = 1, leftovers do
        if shares[index] then shares[index].amount = shares[index].amount + 1 end
    end
    return shares
end

function Attribution:Settle(hostile)
    local ledger = self.Ledgers[hostile]
    if not ledger or ledger.resolved then return false end
    ledger.resolved = true
    local value = xpValue(hostile)
    if value <= 0 then self.Ledgers[hostile] = nil return false end

    local killPool = math.floor(value * 2 / 5)
    local contributionPool = value - killPool
    local shares = self:LargestRemainderShares(contributionPool,
        ledger.effectiveDamageByHeroId or {})

    for _, share in ipairs(shares) do self:_Award(share.identity, share.amount, hostile) end
    if ledger.killingBlowHeroId then self:_Award(ledger.killingBlowHeroId, killPool, hostile) end
    self.Stats.deathsSettled = (self.Stats.deathsSettled or 0) + 1
    hostile.LODRPGXPSettlement = {value = value, killer = ledger.killingBlowHeroId, shares = shares}
    self.Ledgers[hostile] = nil
    return true
end

-- hook.Call invokes the gamemode method after ordinary hooks. Owning the final
-- method seam makes diversion and effective-damage attribution independent of
-- unordered hook-table iteration while preserving every existing damage hook.
local baseEntityTakeDamage = GM.EntityTakeDamage
function GM:EntityTakeDamage(target, dmginfo)
    if baseEntityTakeDamage then baseEntityTakeDamage(self, target, dmginfo) end
    if IsValid(target) and target:IsPlayer() then AbilityRules:ApplyPlayerDefense(target, dmginfo) end
    if IsValid(target) and target.LODHostile then Attribution:Record(target, dmginfo) end
end

hook.Add("OnNPCKilled", "LOD_RPG_GateD_XPSettlement", function(hostile)
    if IsValid(hostile) and hostile.LODHostile then Attribution:Settle(hostile) end
end)

hook.Add("SetupMove", "LOD_RPG_GateD_Movement", function(ply, move)
    if not IsValid(ply) or not ply:Alive() then return end
    local multiplier = AbilityRules:MovementMultiplier(ply)
    move:SetMaxClientSpeed(move:GetMaxClientSpeed() * multiplier)
    move:SetMaxSpeed(move:GetMaxSpeed() * multiplier)
end)

hook.Add("EntityFireBullets", "LOD_RPG_GateD_AimSpread", function(shooter, bullet)
    if not IsValid(shooter) or not shooter:IsPlayer() or not bullet or not bullet.Spread then return end
    bullet.Spread = bullet.Spread * AbilityRules:AimSpreadMultiplier(shooter)
end)

function AbilityRules:SyncPlayer(ply)
    if not IsValid(ply) then return end
    ply:SetNW2Int("LOD_RPGBreadcrumbCells", self:BreadcrumbCells(ply))
    local derived = self:Derived(ply)
    local primeSeconds = tonumber(derived and derived.rogueAcePrimeSeconds) or 0
    if primeSeconds > 0 and ply.LODRPGNextAceReadyAt == nil then
        ply.LODRPGNextAceReadyAt = CurTime() + primeSeconds
    end
end

hook.Add("PlayerSpawn", "LOD_RPG_GateD_SyncDerived", function(ply)
    timer.Simple(0, function() if IsValid(ply) then AbilityRules:SyncPlayer(ply) end end)
end)

concommand.Add("lod_rpg_gate_d_status", function(ply)
    local cv = GetConVar("lod_developer_mode")
    if cv and not cv:GetBool() then return end
    if IsValid(ply) and not ply:IsAdmin() then return end
    local derived = IsValid(ply) and AbilityRules:Derived(ply) or nil
    local line = string.format(
        "class=%s STRx=%.2f aimx=%.2f movex=%.2f DR=%d regenx=%.2f magicx=%.2f mapx=%.2f crumbs=%d stunx=%.2f diversion=%.2f XP=%d",
        tostring(derived and AbilityRules:ProgressionState(ply).classId or "none"),
        tonumber(derived and derived.physicalDamageMultiplier) or 1,
        tonumber(derived and derived.aimSpreadMultiplier) or 1,
        tonumber(derived and derived.movementSpeedMultiplier) or 1,
        math.floor(tonumber(derived and derived.damageResistancePerDie) or 0),
        AbilityRules:MagicRegenMultiplier(ply),
        (tonumber(derived and derived.magicPowerMultiplier) or 1) * (tonumber(derived and derived.wizardCapstoneMagicPowerMultiplier) or 1),
        AbilityRules:UtilityMagicCostMultiplier(ply), AbilityRules:BreadcrumbCells(ply),
        tonumber(derived and derived.chaHitStunInflictMultiplier) or 1,
        tonumber(derived and derived.hpToMagicDiversionFraction) or 0,
        Attribution.Stats.xpAwarded or 0)
    print("[LOD:RPG-D] " .. line)
    if IsValid(ply) then ply:ChatPrint(line) end
end)

function AbilityRules:ValidateGateD(ply)
    local errors = {}
    local function expect(condition, message)
        if not condition then errors[#errors + 1] = message end
    end
    expect(RPG.ImplementationGate == "D", "schema gate")
    expect(RPG.Constants.MaxDamageDicePerChain == 32, "chain cap")
    expect(LOD.CombatRolls and LOD.CombatRolls.RollActorDamage
        and LOD.CombatRolls.ResolveActorDamage, "dice integration")

    -- Regression guard for Lua's multi-return argument expansion. Public combat
    -- resolution must expose exactly one numeric value; richer internal damage
    -- diagnostics stay behind AbilityRules:ResolveDamageContract.
    local resolverReturnCount = 0
    local resolverSample = nil
    local function captureResolverResult(...)
        resolverReturnCount = select("#", ...)
        resolverSample = select(1, ...)
    end
    if LOD.CombatRolls and LOD.CombatRolls.ResolveActorDamage then
        captureResolverResult(LOD.CombatRolls:ResolveActorDamage(
            {contributions = {1}, bonus = 0}, nil, nil, {}))
    end
    expect(resolverReturnCount == 1 and type(resolverSample) == "number",
        "single-value damage resolver contract")

    expect(LOD.CombatRolls and LOD.CombatRolls.LODD12BoomchainInstalled
        and LOD.MagnumPiercing and LOD.MagnumPiercing.DamageSegments,
        "late Magnum dice/piercing chain")
    expect(LOD.Magic and LOD.Pushback and LOD.M3HitFeedback, "semantic authorities")

    local nonRogue = {boomShift = 1}
    local rogue = {boomShift = 0, rogueAllDamageDiceExplode = true}
    local loaded = {boomShift = 2, rogueAllDamageDiceExplode = true,
        rogueCapstoneBoomThresholdShift = 1}
    local d6 = self:ExplosionParameters(nonRogue, 6)
    local d12 = self:ExplosionParameters(nonRogue, 12)
    local rogue6 = self:ExplosionParameters(rogue, 6)
    local rogue12 = self:ExplosionParameters(rogue, 12)
    local loaded6 = self:ExplosionParameters(loaded, 6)
    local loaded12 = self:ExplosionParameters(loaded, 12)
    expect(d6.fresh == 6 and d6.continuation == 5, "non-Rogue d6 Boomshift")
    expect(d12.fresh == 8 and d12.continuationFloor == 4
        and d12.continuationStep == 2, "non-Rogue SUPER-d12 Boomshift")
    expect(rogue6.fresh == 5 and rogue6.continuation == 5, "Rogue d6")
    expect(rogue12.fresh == 7 and rogue12.continuationFloor == 4, "Rogue SUPER-d12")
    expect(loaded6.fresh == 4 and loaded6.continuation == 3, "Loaded Dice d6")
    expect(loaded12.fresh == 6 and loaded12.continuationFloor == 3
        and loaded12.continuationStep == 3, "Loaded Dice SUPER-d12")

    local fighterDamage = self:ResolveDamageValues({contributions = {10, 5}},
        {physicalDamageMultiplier = 1.5, fighterCapstonePhysicalDamageMultiplier = 1.2},
        {damageResistancePerDie = 2}, {physical = true})
    expect(math.abs(fighterDamage - 19.8) < 0.0001, "Fighter/STR/CON order")
    local aimedFighterDamage = self:ResolveDamageValues({contributions = {10, 5}},
        {physicalDamageMultiplier = 1.5, fighterCapstonePhysicalDamageMultiplier = 1.2},
        {damageResistancePerDie = 2}, {physical = true, authoredScale = 2})
    expect(math.abs(aimedFighterDamage - 39.6) < 0.0001, "Magnum aim/source order")
    local wizardDamage = self:ResolveDamageValues({contributions = {6, 4}},
        {magicPowerMultiplier = 1.6, wizardCapstoneMagicPowerMultiplier = 1.2},
        {damageResistancePerDie = 1}, {magic = true})
    expect(math.abs(wizardDamage - 15.36) < 0.0001, "Wizard/WIS/CON order")

    local diverted, spent, remaining = self:ComputeMagicDiversion(50, 0.40, 10, 1)
    expect(diverted == 10 and spent == 10 and remaining == 40, "Wizard diversion budget")
    local flooredDiverted = self:ComputeMagicDiversion(50, 0.40, 10.9, 1)
    expect(flooredDiverted == 10, "ordinary diversion whole Magic")
    local aegisDiverted, aegisSpent, aegisRemaining = self:ComputeMagicDiversion(50, 0.50, 10, 1.25)
    expect(aegisDiverted == 12.5 and aegisSpent == 10 and aegisRemaining == 37.5,
        "Living Aegis exchange")

    local shares = Attribution:LargestRemainderShares(60, {alice = 70, bob = 30})
    local byId = {}
    for _, share in ipairs(shares) do byId[share.identity] = share.amount end
    expect(byId.alice == 42 and byId.bob == 18, "40/60 XP allocation")

    if IsValid(ply) then
        local state = self:ProgressionState(ply)
        local derived = state and state.derivedStats
        expect(state and state.classId ~= nil, "player class")
        expect(derived and ply:GetMaxHealth() == derived.maxHP, "authoritative MaxHP")
        expect(ply:GetNW2Int("LOD_RPGBreadcrumbCells", -1) == self:BreadcrumbCells(ply),
            "breadcrumb sync")
        local ps = LOD.Magic and LOD.Magic._EnsureState and LOD.Magic:_EnsureState(ply) or nil
        expect(ps and ps.magic >= 0 and ps.magic <= 100, "Magic invariant")
    end
    return #errors == 0, errors
end

concommand.Add("lod_rpg_gate_d_validate", function(ply)
    local cv = GetConVar("lod_developer_mode")
    if cv and not cv:GetBool() then return end
    if IsValid(ply) and not ply:IsAdmin() then return end
    local ok, errors = AbilityRules:ValidateGateD(ply)
    local line = string.format("Gate D validation %s — thresholds=%s XPsplit=%s authorities=%s",
        ok and "PASS" or "FAILED", ok and "exact" or "error",
        ok and "42/18+40" or "error", ok and "single-seam" or "error")
    print("[LOD:RPG-D] " .. line)
    if IsValid(ply) then ply:ChatPrint(line) end
    for _, message in ipairs(errors) do
        ErrorNoHalt("[LOD:RPG-D]  - " .. tostring(message) .. "\n")
    end
end)
