LOD = LOD or {}
LOD.CombatRolls = LOD.CombatRolls or {}

local Rolls = LOD.CombatRolls
local MAX_CHAIN_DICE = 32
local SHOTGUN_SHARE_COUNT = 6
local GRENADE_REFERENCE_DAMAGE = 150

util.AddNetworkString("LOD_CombatRoll")
util.AddNetworkString("LOD_DiceExplosionFX")

Rolls.Stats = Rolls.Stats or {
    rolls = 0,
    playerAttacks = 0,
    hostileAttacks = 0,
    healthRolls = 0,
    feedMessages = 0
}

local PLAYER_WEAPONS = assert(LOD.RPG.PlayerWeaponDamageProfiles)

Rolls.PlayerDamageProfiles = PLAYER_WEAPONS

-- Initial hostile attack dice preserve the approximate means of the accepted
-- fixed-damage baseline while moving every direction of combat onto one roll
-- authority. Multiple dice deliberately narrow lethal low/high outliers.
local HOSTILE_ATTACKS = {
    shambler = {label = "SHAMBLER", source = "melee", count = 3, sides = 10, bonus = 3, reference = 20},
    runner = {label = "RUNNER", source = "melee", count = 2, sides = 8, bonus = 1, reference = 10},
    soldier = {label = "SOLDIER", source = "soldier bolt", count = 1, sides = 10, bonus = 1, reference = 6},
    blitzer = {label = "BLITZER", source = "Blitzer bolt", count = 1, sides = 8, bonus = 1, reference = 5},
    bioblaster = {label = "BIO BLASTER", source = "bio bolt", count = 8, sides = 8, bonus = 9, reference = 45},
    deadcrab = {label = "DEADCRAB", source = "death blast", count = 8, sides = 10, bonus = 11, reference = 55}
}

Rolls.HostileDamageProfiles = HOSTILE_ATTACKS
function Rolls:HostileDamageProfile(archetypeId)
    return (self.MeleeBalanceProfiles or {})[archetypeId] or self.HostileDamageProfiles[archetypeId]
end

-- Initial health pools are tuned from desired dice-era hit counts rather than
-- inherited fixed HP. Several small dice keep ordinary durability readable;
-- the variance layer subsequently constrains the result beneath visible size.
local ENEMY_HEALTH_PROFILES = {
    deadcrab = {count = 2, sides = 4, bonus = 1},
    runner = {count = 3, sides = 4, bonus = 3},
    shambler = {count = 4, sides = 4, bonus = 5},
    soldier = {count = 4, sides = 4, bonus = 5},
    blitzer = {count = 4, sides = 4, bonus = 5},
    bioblaster = {count = 5, sides = 4, bonus = 6}
}

local grenadeRolls = setmetatable({}, {__mode = "k"})
Rolls.PendingDamageReports = Rolls.PendingDamageReports or setmetatable({}, {__mode = "k"})

function Rolls:QueueDamageReport(info, report)
    self.PendingDamageReports[info] = report
end

function Rolls:ReportResolvedDamage(info)
    local report = self.PendingDamageReports[info]
    self.PendingDamageReports[info] = nil
    if report then report(math.max(0, info:GetDamage())) end
end

local function activeWeaponClass(ply)
    if not IsValid(ply) then return nil end
    local weapon = ply:GetActiveWeapon()
    return IsValid(weapon) and weapon:GetClass() or nil
end

local function diceNotation(profile)
    local text = string.format("%dd%d", profile.count or 1, profile.sides or 1)
    local bonus = profile.bonus or 0
    if bonus > 0 then text = text .. "+" .. bonus end
    if bonus < 0 then text = text .. tostring(bonus) end
    return text
end

function Rolls:_RNG(label)
    local state = LOD.RunManager and LOD.RunManager.State
    local levelSeed = state and state.LevelSeed or 1
    if self.LevelSeed ~= levelSeed then
        self.LevelSeed = levelSeed
        self.Serial = 0
    end
    self.Serial = (self.Serial or 0) + 1
    local seed = LOD.Seeds.Derive(levelSeed,
        string.format("combat-roll:%d:%s", self.Serial, tostring(label or "roll")))
    return LOD.RNG.New(seed)
end

-- DIE-LOGGER transport is installed once by sv_combat_feed_semantics.lua.

-- Exploding dice are a joyful, important combat event. Keep the feedback packet
-- tiny and shooter-local: kind 1 = Magnum, kind 2 = Shotgun, depth identifies a
-- deeper Magnum pierce bonus when applicable.
function Rolls:EmitDiceExplosionFX(ply, weaponClass, explosionCount, depth)
    if not IsValid(ply) or not ply:IsPlayer() then return end
    local count = math.Clamp(math.floor(tonumber(explosionCount) or 0), 0, 63)
    if count <= 0 then return end

    local kind = 0
    if weaponClass == "weapon_357" then kind = 1 end
    if weaponClass == "weapon_shotgun" then kind = 2 end

    net.Start("LOD_DiceExplosionFX")
    net.WriteUInt(kind, 2)
    net.WriteUInt(count, 6)
    net.WriteUInt(math.Clamp(math.floor(tonumber(depth) or 1), 1, 15), 4)
    net.Send(ply)
end

function Rolls:_RollFormula(profile, rng)
    local values = {}
    local total = profile.bonus or 0
    for _ = 1, profile.count or 1 do
        local value = rng:Int(1, profile.sides)
        values[#values + 1] = value
        total = total + value
        self.Stats.rolls = self.Stats.rolls + 1
    end
    return total, values
end

function Rolls:_RollExploding(profile, rng)
    local values = {}
    local contributions = {}
    local thresholds = {}
    local total = profile.bonus or 0
    local derived = profile.rpgDerived
    local sides = math.max(2, math.floor(tonumber(profile.sides) or 2))
    local rules = LOD.RPGAbilityRules
    local parameters = rules and rules.ExplosionParameters
        and rules:ExplosionParameters(derived, sides, profile.classExplosionImmune) or nil
    local freshThreshold = parameters and (parameters.rogue or sides == 6)
        and parameters.fresh or tonumber(profile.exploding)
    freshThreshold = math.Clamp(math.floor(freshThreshold or sides), 2, sides)
    local threshold = freshThreshold
    local natural = rng:Int(1, profile.sides)

    while natural and #values < math.min(MAX_CHAIN_DICE, profile.rollLimit or MAX_CHAIN_DICE) do
        values[#values + 1] = natural
        thresholds[#thresholds + 1] = threshold
        local contribution = math.max(profile.floor or natural, natural)
        contributions[#contributions + 1] = contribution
        total = total + contribution
        self.Stats.rolls = self.Stats.rolls + 1

        local explodes = profile.exploding and natural >= threshold
        if not explodes or #values >= math.min(MAX_CHAIN_DICE, profile.rollLimit or MAX_CHAIN_DICE) then break end
        threshold = parameters and parameters.continuation or threshold
        natural = rng:Int(1, profile.sides)
    end

    return total, values, contributions, #values >= math.min(MAX_CHAIN_DICE, profile.rollLimit or MAX_CHAIN_DICE), thresholds
end

-- Progression dice remain under the one dice authority but are not damage dice:
-- Rogue mastery, damage feats, and combat rerolls never apply. The universal d6
-- natural-6 chain still applies and the result is returned for permanent storage.
function Rolls:RollProgressionHitDie(seed, sides)
    sides = math.max(2, math.floor(tonumber(sides) or 6))
    local rng = LOD.RNG.New(seed or 1)
    local total, values, capped
    local formula = "d" .. sides
    if sides == 6 then
        formula = "d6!"
        total, values = 0, {}
        local limit = math.max(1, math.floor(LOD.RPG
            and LOD.RPG.Constants.MaxDamageDicePerChain or 32))
        local natural = rng:Int(1, 6)
        while natural and #values < limit do
            values[#values + 1] = natural
            total = total + natural
            self.Stats.rolls = self.Stats.rolls + 1
            if natural ~= 6 then break end
            if #values >= limit then
                capped = true
                break
            end
            natural = rng:Int(1, 6)
        end
    else
        total, values = self:_RollFormula({count = 1, sides = sides}, rng)
    end
    return {
        seed = seed,
        sides = sides,
        formula = formula,
        values = values,
        total = total,
        capped = capped == true
    }
end

local function valueList(values)
    local out = {}
    for i, value in ipairs(values or {}) do out[i] = tostring(value) end
    return table.concat(out, ",")
end

function Rolls:RollEnemyHealth(archetypeId, instanceSeed)
    local profile = ENEMY_HEALTH_PROFILES[archetypeId]
    if not profile then return nil end
    local seed = LOD.Seeds.Derive(instanceSeed or 1, "health-dice:" .. archetypeId)
    local total, values = self:_RollFormula(profile, LOD.RNG.New(seed))
    self.Stats.healthRolls = (self.Stats.healthRolls or 0) + 1
    return {
        profile = profile,
        formula = diceNotation(profile),
        total = total,
        values = values,
        expected = (profile.count or 1) * ((profile.sides or 1) + 1) * 0.5
            + (profile.bonus or 0),
        seed = seed
    }
end

local function cleanName(value)
    local text = tostring(value or "Unknown")
    text = string.gsub(text, "[%c]", "")
    text = string.Trim(text)
    if text == "" then text = "Unknown" end
    return string.sub(text, 1, 32)
end

local function titleName(value)
    local text = string.lower(cleanName(value))
    return (string.gsub(text, "(%a)([%w']*)", function(first, rest)
        return string.upper(first) .. rest
    end))
end

local function entityDisplayName(ent, fallback)
    if IsValid(ent) and ent:IsPlayer() then
        local progression = LOD.CharacterProgressionSystem
        if progression and progression.PlayerCharacterText then
            return cleanName(progression:PlayerCharacterText(ent))
        end
        return cleanName(ent:Nick())
    end
    if IsValid(ent) and ent.LODHostile then
        local configured = ent.LODConfig and (ent.LODConfig.name or ent.LODConfig.label)
        return titleName(configured or ent.LODArchetypeId or fallback or "Hostile")
    end
    if IsValid(ent) then return titleName(ent:GetClass()) end
    return titleName(fallback or "Unknown")
end

local function damageText(amount)
    local value = math.max(0, tonumber(amount) or 0)
    if math.abs(value - math.floor(value + 0.5)) < 0.05 then
        return tostring(math.floor(value + 0.5))
    end
    return string.format("%.1f", value)
end

function Rolls:ReportEnemyHealth(hostile, contract, size, campaignPartyScale, finalHealth)
    if not contract then return end
    local raw = contract.total
    local resolved = contract.resolvedBase or raw
    local resolution = math.abs(raw - resolved) > 0.05
        and string.format("%s -> %s", damageText(raw), damageText(resolved))
        or damageText(raw)
    local text = string.format("%s health %s (%s) [rolls %s; size x%.2f; campaign x%.2f] = %d HP",
        entityDisplayName(hostile, "Hostile"), contract.formula, resolution,
        valueList(contract.values), size or 1, campaignPartyScale or 1,
        math.max(1, math.floor((finalHealth or 1) + 0.5)))
    for _, ply in ipairs(player.GetHumans()) do
        self:_Send(ply, 2, text)
    end
end

-- Actor-owned damage dice enter one semantic seam before weapon wrappers add
-- presentation/cylinder behavior. Progression/health/count dice never call this
-- function and therefore remain isolated from Rogue mastery and DEX Boomshift.
function Rolls:RollActorDamage(attacker, profile, rng, bonusDice)
    local rules = LOD.RPGAbilityRules
    local resolvedProfile = rules and rules.CopyDamageProfile
        and rules:CopyDamageProfile(profile, attacker) or table.Copy(profile or {})
    local derived = resolvedProfile.rpgDerived
    local sides = math.max(2, math.floor(tonumber(resolvedProfile.sides) or 2))
    local count = math.max(1, math.floor(tonumber(resolvedProfile.count) or 1))
        + math.max(0, math.floor(tonumber(bonusDice) or 0))
    local values, contributions, thresholds, chainStarts = {}, {}, {}, {}
    local total = tonumber(resolvedProfile.bonus) or 0
    local capped = false
    local rogueExplodes = derived and derived.rogueAllDamageDiceExplode == true
        and resolvedProfile.classExplosionImmune ~= true
    local universalExplodes = sides == 6 or sides == 12
    local authoredExplodes = resolvedProfile.exploding ~= nil

    for _ = 1, count do
        local remaining = (resolvedProfile.rollLimit or math.huge) - #values
        if remaining <= 0 then capped = true; break end
        chainStarts[#chainStarts + 1] = #values + 1
        local dieProfile = table.Copy(resolvedProfile)
        dieProfile.rollLimit = remaining
        dieProfile.count = 1
        dieProfile.bonus = 0
        dieProfile.exploding = authoredExplodes and resolvedProfile.exploding
            or (sides == 6 and 6) or (sides == 12 and 8) or (rogueExplodes and sides) or nil
        local dieTotal, dieValues, dieContributions, dieCapped, dieThresholds
        if universalExplodes or authoredExplodes or rogueExplodes then
            dieTotal, dieValues, dieContributions, dieCapped, dieThresholds = self:_RollExploding(dieProfile, rng)
        else
            dieTotal, dieValues = self:_RollFormula(dieProfile, rng)
            dieContributions = dieValues
        end
        total = total + (tonumber(dieTotal) or 0)
        for index, value in ipairs(dieValues or {}) do
            values[#values + 1] = value
            contributions[#contributions + 1] = tonumber(dieContributions and dieContributions[index]) or value
            thresholds[#thresholds + 1] = dieThresholds and dieThresholds[index] or nil
        end
        capped = capped or dieCapped == true
    end

    local formula = string.format("%dd%d%s", count, sides,
        (universalExplodes or authoredExplodes or rogueExplodes) and "!" or "")
    local formulaBonus = tonumber(resolvedProfile.bonus) or 0
    if formulaBonus > 0 then formula = formula .. "+" .. tostring(formulaBonus) end
    if formulaBonus < 0 then formula = formula .. tostring(formulaBonus) end
    local contract = {
        attackEvent = resolvedProfile.attackEvent or (IsValid(attacker) and attacker.LODCommittedAttackEvent) or {},
        sourcePosition = IsValid(attacker) and attacker.GetPos and attacker:GetPos() or nil,
        profile = resolvedProfile,
        formula = formula,
        total = total,
        values = values,
        contributions = contributions,
        thresholds = thresholds,
        chainStarts = chainStarts,
        bonus = tonumber(resolvedProfile.bonus) or 0,
        capped = capped,
        baseDice = count,
        aceBonusDice = math.max(0, math.floor(tonumber(bonusDice) or 0))
    }
    if LOD.IdentityPerkDirector then LOD.IdentityPerkDirector:SealAttack(contract, attacker, rng) end
    if LOD.RPGCrossFeats then LOD.RPGCrossFeats:RestoreBoomBattery(attacker, contract) end
    return contract
end

function Rolls:ResolveActorDamage(contract, attacker, target, tags)
    tags=tags or {}
    if LOD.Equipment and LOD.Equipment.PrepareDamageTags then LOD.Equipment:PrepareDamageTags(contract,attacker,tags) end
    local rules = LOD.RPGAbilityRules
    if not rules or not rules.ResolveDamageContract then return tonumber(contract and contract.total) or 0 end
    -- Public combat-roll resolution is intentionally a single-value contract.
    -- AbilityRules retains its richer internal tuple for validation/debugging,
    -- but callers may safely pass this result into math helpers without Lua
    -- expanding hidden table-valued returns into additional arguments.
    local effects = LOD.RPG and LOD.RPG.FeatEffectSystem
    local identity = LOD.IdentityPerkDirector
    local targetContract = identity and identity:TargetContract(contract, attacker, target, tags) or contract
    targetContract = effects and effects.BlastProofTargetContract
        and effects:BlastProofTargetContract(targetContract, attacker, target) or targetContract
    local resolved, reduced, resistance = rules:ResolveDamageContract(targetContract, attacker, target, tags)
    local weaponBonus = identity and identity:WeaponBonus(targetContract, tags, tonumber(resolved) or 0) or 0
    resolved = (tonumber(resolved) or 0) + weaponBonus
    if contract then
        contract.feedResolution = {total = tonumber(resolved) or 0, favoredWeaponBonus = weaponBonus,
            reduced = reduced, resistance = tonumber(resistance) or 0,
            resolvedContract = targetContract ~= contract and targetContract or nil}
    end
    return tonumber(resolved) or 0
end

-- Innate physical contacts share actor dice, mitigation, native defenses and
-- feed without masquerading as the currently held gun or a Magic cast.
function Rolls:ApplyEquipmentContact(attacker,target,move,context)
    if not IsValid(target) or target.LODDead or target:Health()<=0 then return false end
    local contract=self:RollActorDamage(attacker,{label=move.displayName,source=move.id,
        count=move.damageDice,sides=move.damageSides,attackEvent=context},self:_RNG("equipment:"..move.id),0)
    local tags={physical=true,melee=true,equipmentContact=true,actorDamageResolved=true,
        attackEvent=context,damageContract=contract}
    local damage=math.max(0,self:ResolveActorDamage(contract,attacker,target,tags))
    local before=target:Health()
    if damage>0 then
        local info=LOD.NewDamageInfo()
        info:SetAttacker(attacker);info:SetInflictor(attacker);info:SetDamage(damage)
        info:SetDamageType(DMG_CLUB);info:SetDamagePosition(target:WorldSpaceCenter());info:SetDamageForce(vector_origin)
        LOD.RPGStatusElements:AttachDamageContext(info,tags)
        target:TakeDamageInfo(info)
    end
    local actual=math.max(0,before-(IsValid(target) and target:Health() or 0))
    self.Stats.playerAttacks=(self.Stats.playerAttacks or 0)+1
    local extra=math.max(0,#(contract.values or {})-contract.baseDice)
    if extra>0 then self:EmitDiceExplosionFX(attacker,move.id,extra,1) end
    self:_Send(attacker,0,self:_DamageEventText(attacker,LOD.DieLogger:DamageFormula(contract),
        actual,target,self:_PlayerRollDetail(contract),nil,"Hostile",move.id))
    return true
end

function Rolls:RollPlayerWeapon(ply, weaponClass, attackEvent)
    if LOD.Equipment and LOD.Equipment.RefreshDerived and LOD.RunManager then
        LOD.Equipment:RefreshDerived(ply,LOD.RunManager:GetPlayerState(ply))
    end
    attackEvent=attackEvent or {}
    if LOD.Equipment and LOD.Equipment.SealWeaponAttack then
        LOD.Equipment:SealWeaponAttack(ply,{attackEvent=attackEvent},weaponClass)
    end
    local profile = PLAYER_WEAPONS[weaponClass]
    if not profile then return nil end
    local rng = self:_RNG("player:" .. weaponClass)
    local rules = LOD.RPGAbilityRules
    local aceBonus = rules and rules.CommitAttack and rules:CommitAttack(ply) and 1 or 0
    local committedProfile = table.Copy(profile)
    committedProfile.attackEvent = attackEvent
    local rolled = self:RollActorDamage(ply, committedProfile, rng, aceBonus)

    local contract = {
        attackEvent = rolled.attackEvent,
        label = profile.label,
        weaponClass = weaponClass,
        profile = rolled.profile,
        formula = rolled.formula,
        total = rolled.total,
        values = rolled.values,
        contributions = rolled.contributions,
        thresholds = rolled.thresholds,
        chainStarts = rolled.chainStarts,
        bonus = rolled.bonus,
        baseDice = rolled.baseDice,
        aceBonusDice = rolled.aceBonusDice,
        wizardFullMagicIntBonus = rolled.wizardFullMagicIntBonus,
        identityWeaponStacks = rolled.identityWeaponStacks, identityEnemyStacks = rolled.identityEnemyStacks,
        identityDieSeed = rolled.identityDieSeed, primaryAuthoredDamageDie = rolled.primaryAuthoredDamageDie,
        identityTargetViews = rolled.identityTargetViews,
        capped = rolled.capped == true,
        ownerState = rules and rules:ProgressionState(ply),
        ownerLife = ply.LODCombatLifeSerial or 0,
        levelSeed = LOD.RunManager and LOD.RunManager.State and LOD.RunManager.State.LevelSeed,
        created = CurTime()
    }

    if weaponClass == "weapon_shotgun" then
        -- Accepted Shotgun identity: eight pellets plus an independent universal
        -- exploding utility d6, capped at 36. Utility rolls never enter damage feats.
        local pelletBonus, pelletValues, _, pelletCapped = self:_RollExploding(
            {count = 1, sides = 6, exploding = 6}, rng)
        contract.pellets = math.min(36, 8 + math.max(1, pelletBonus or 1))
        contract.pelletRollTotal, contract.pelletRollValues = pelletBonus, pelletValues
        contract.pelletRollCapped = pelletCapped == true
        if self.EmitDiceExplosionFX and #pelletValues > 1 then
            self:EmitDiceExplosionFX(ply, "weapon_shotgun", #pelletValues - 1, 1)
        end
        contract.hits = setmetatable({}, {__mode = "k"})
        contract.damageByTarget = setmetatable({}, {__mode = "k"})
        contract.resolutionByTarget = setmetatable({}, {__mode = "k"})
        contract.targetNames = setmetatable({}, {__mode = "k"})
    end

    if LOD.Equipment and LOD.Equipment.SealWeaponAttack then LOD.Equipment:SealWeaponAttack(ply,contract,weaponClass) end
    self.Stats.playerAttacks = self.Stats.playerAttacks + 1
    return contract
end

function Rolls:_PlayerRollDetail(contract)
    if not contract or not contract.values or #contract.values == 0 then return nil end
    local valuesStr = LOD.DieLogger:RollBreakdown(contract)
    return string.format("[rolls %s%s]", valuesStr, contract.capped and "; chain cap" or "")
end

function Rolls:_FinishShotgunFeed(ply, contract)
    if not IsValid(ply) then return end
    for target, hits in pairs(contract.hits or {}) do
        if hits > 0 then
            local damage = contract.damageByTarget[target] or 0
            if IsValid(target) and damage > 0 and LOD.M3HitFeedback and LOD.M3HitFeedback.ApplyShotgunShellStun then
                LOD.M3HitFeedback:ApplyShotgunShellStun(target, ply, contract.attackEvent)
            end
            local targetContract = setmetatable({feedResolution = (contract.resolutionByTarget or {})[target] or false},
                {__index = contract})
            local detail = string.format("[%d/%d pellets; rolls %s; shell share 1/%d per hit]", hits,
                contract.pellets or 6, LOD.DieLogger:RollBreakdown(targetContract), SHOTGUN_SHARE_COUNT)
            contract.feedReported = true
            self:_Send(ply, 0, self:_DamageEventText(ply, LOD.DieLogger:DamageFormula(targetContract) or "1d6!", damage,
                target, detail, nil, (contract.targetNames or {})[target] or "Hostile", "shotgun"))
        end
    end
end

function Rolls:SettleShotgun(ply, contract)
    if not IsValid(ply) or not ply:Alive() or contract.settled then return end
    if contract.ownerLife and contract.ownerLife ~= (ply.LODCombatLifeSerial or 0) then return end
    local rules = LOD.RPGAbilityRules
    if contract.ownerState and rules:ProgressionState(ply) ~= contract.ownerState then return end
    if contract.levelSeed and contract.levelSeed ~= (LOD.RunManager.State or {}).LevelSeed then return end
    contract.settled = true
    local targets = {}
    for target in pairs(contract.hits) do if IsValid(target) then targets[#targets + 1] = target end end
    table.sort(targets, function(a, b) return a:EntIndex() < b:EntIndex() end)
    for _, target in ipairs(targets) do
        if not target.LODDead and target:Health() > 0 then
            local hits = contract.hits[target]
            local tags = {physical = true, shotgunHits = hits, shotgunShares = SHOTGUN_SHARE_COUNT,
                settledShotgun = true, attackEvent = contract.attackEvent, damageContract = contract,
                authoredScale=tonumber(contract.aimMultiplier) or 1, attackMultiplier=tonumber(contract.aimMultiplier) or 1}
            local total = self:ResolveActorDamage(contract, ply, target, tags)
            contract.resolutionByTarget[target] = contract.feedResolution
            local info = LOD.NewDamageInfo()
            info:SetAttacker(ply)
            info:SetInflictor(IsValid(contract.weapon) and contract.weapon or ply)
            info:SetDamage(total)
            info:SetDamageType(DMG_BULLET)
            info:SetDamagePosition(contract.hitPositions[target] or target:WorldSpaceCenter())
            info:SetDamageForce(vector_origin)
            LOD.RPGStatusElements:AttachDamageContext(info, tags)
            local before = target:Health()
            target:TakeDamageInfo(info)
            -- Source armor and native rejection happen after Lua mitigation.
            -- The shell feed/control uses actual HP lost, including overkill.
            local after = IsValid(target) and math.max(0, target:Health()) or 0
            contract.damageByTarget[target] = math.max(0, before - after)
        end
    end
    return true
end

function Rolls:RollHostileAttack(hostile, profile, originalDamage, cacheOwner)
    if not profile then return nil end
    local cached = IsValid(cacheOwner) and cacheOwner.LODCombatRollContract or nil
    local total
    local values
    local contributions
    local rolledContract
    if cached and cached.profile == profile then
        total = cached.total
        values = cached.values
        contributions = cached.contributions
        rolledContract = cached
    else
        local rng = self:_RNG("hostile:" .. tostring(hostile.LODArchetypeId or "unknown"))
        local committedProfile = table.Copy(profile)
        committedProfile.attackEvent = IsValid(cacheOwner) and cacheOwner.LODAttackEvent or nil
        local rolled = self:RollActorDamage(hostile, committedProfile, rng, 0)
        total, values, contributions = rolled.total, rolled.values, rolled.contributions
        rolledContract = rolled
        if IsValid(cacheOwner) then
            cacheOwner.LODCombatRollContract = {
                originContract = rolled,
                attackEvent = rolled.attackEvent,
                profile = profile,
                total = total,
                values = values,
                contributions = contributions,
                formula = rolled.formula, chainStarts = rolled.chainStarts,
                baseDice = rolled.baseDice, capped = rolled.capped, thresholds = rolled.thresholds
            }
        end
        self.Stats.hostileAttacks = self.Stats.hostileAttacks + 1
    end

    -- Shared blasts reuse one rolled base for every victim, then independently
    -- apply the already-authored distance/size multiplier for each damage event.
    local scale = math.max(0, tonumber(originalDamage) or profile.reference or total)
        / math.max(1, profile.reference or total)
    local contract = {
        originContract = rolledContract.originContract or rolledContract,
        attackEvent = rolledContract.attackEvent,
        profile = profile,
        total = total,
        values = values,
        contributions = contributions or values,
        formula = rolledContract.formula, chainStarts = rolledContract.chainStarts,
        baseDice = rolledContract.baseDice, capped = rolledContract.capped, thresholds = rolledContract.thresholds,
        bonus = profile.bonus or 0,
        scale = scale,
        final = math.max(1, math.floor(total * scale + 0.5))
    }
    return contract
end

function Rolls:_HostileRollText(contract, source, target)
    local profile = contract.profile
    local details = string.format("[rolls %s", LOD.DieLogger:RollBreakdown(contract))
    if math.abs((contract.scale or 1) - 1) > 0.01 then
        details = details .. string.format("; base %d x%.2f", contract.total, contract.scale)
    end
    details = details .. "]"
    return self:_DamageEventText(source, contract.formula or diceNotation(profile), contract.final,
        target, details, profile.label, "Player", profile.source)
end

-- Firearm dice commit at fire time. Exploded misses used to show the cue but
-- no formula because only EntityTakeDamage emitted records. Settle once after
-- the engine's synchronous hit callbacks, without inventing a hit or new RNG.
function Rolls:_FinishExplodedMiss(ply, contract)
    if not IsValid(ply) or contract.feedReported then return end
    if #(contract.values or {}) <= (contract.baseDice or 1) then return end
    contract.feedReported = true
    self:_Send(ply, 0, self:_DamageEventText(ply, contract.formula, 0, nil,
        self:_PlayerRollDetail(contract), nil, "no damageable target", contract.label or contract.weaponClass))
end

local function qualifyingPlayerShooter(shooter)
    return IsValid(shooter) and shooter:IsPlayer() and shooter:Alive()
end

hook.Add("EntityFireBullets", "LOD_DicePlayerFirearms", function(shooter, bullet)
    if not qualifyingPlayerShooter(shooter) then return end
    local weaponClass = activeWeaponClass(shooter)
    local profile = PLAYER_WEAPONS[weaponClass]
    if not profile then return end

    bullet.LODAttackEvent = bullet.LODAttackEvent or shooter.LODCommittedAttackEvent or {}
    local contract = Rolls:RollPlayerWeapon(shooter, weaponClass, bullet.LODAttackEvent)
    if not contract then return end

    -- An exploding roll has one or more continuation dice after its first die.
    -- Trigger one concise audiovisual event per attack, with the number of actual
    -- explosion continuations so especially lucky chains feel appropriately big.
    local continuations = math.max(0, #(contract.values or {}) - (contract.baseDice or 1))
    if continuations > 0 then
        Rolls:EmitDiceExplosionFX(shooter, weaponClass, continuations, 1)
    end

    if weaponClass == "weapon_shotgun" then
        bullet.Num = contract.pellets
        -- Every pellet that actually connects is guaranteed to contribute at
        -- least one point of damage. Low shared shell rolls therefore cannot be
        -- diluted into sub-1 pellet hits by the one-sixth share calculation.
        bullet.Damage = math.max(1, contract.total / SHOTGUN_SHARE_COUNT)
        shooter.LODActiveShotgunRoll = contract
        contract.weapon = shooter:GetActiveWeapon()
        contract.sourcePosition = bullet.Src or shooter:GetShootPos()
        contract.hitPositions = setmetatable({}, {__mode = "k"})
        local previousCallback = bullet.Callback
        bullet.Callback = function(attacker, tr, info)
            local result = previousCallback and previousCallback(attacker, tr, info)
            if result and result.damage == false then return result end
            local target, hitPos = tr.Entity, tr.HitPos
            if LOD.HostileCombatHulls then
                target, hitPos = LOD.HostileCombatHulls:Resolve(attacker, bullet, tr)
            end
            if IsValid(target) and (target.LODHostile or target:IsPlayer()) then
                local blocked = LOD.GeneratedGeometryBallistics
                    and LOD.GeneratedGeometryBallistics:SegmentBlocked(contract.sourcePosition, hitPos, attacker, target)
                if not blocked and not contract.settled and not target.LODDead and info:GetDamage() > 0 then
                    contract.targetNames[target] = Rolls:EntityDisplayName(target, "Hostile")
                    contract.hits[target] = math.min(contract.pellets, (contract.hits[target] or 0) + 1)
                    contract.hitPositions[target] = hitPos
                end
                -- Source combines same-target pellet damage. Count before that
                -- merge and suppress the native pellet: one shell/target event.
                info:SetDamage(0)
                return {damage = false, effects = not result or result.effects ~= false}
            end
            return result
        end
        timer.Simple(0, function()
            local settled = Rolls:SettleShotgun(shooter, contract)
            if IsValid(shooter) and shooter.LODActiveShotgunRoll == contract then
                shooter.LODActiveShotgunRoll = nil
            end
            if settled then
                Rolls:_FinishShotgunFeed(shooter, contract)
                Rolls:_FinishExplodedMiss(shooter, contract)
            end
        end)
    else
        bullet.Damage = contract.total
        contract.targets = setmetatable({}, {__mode = "k"})
        shooter.LODActivePlayerRoll = contract
        timer.Simple(0, function()
            if IsValid(shooter) and shooter.LODActivePlayerRoll == contract then
                shooter.LODActivePlayerRoll = nil
            end
            Rolls:_FinishExplodedMiss(shooter, contract)
        end)
    end
end)

local function grenadeAttack(attacker, inflictor, dmginfo)
    if not IsValid(inflictor) or not dmginfo:IsDamageType(DMG_BLAST) then return false end
    local class = inflictor:GetClass()
    return class == "npc_grenade_frag" or class == "grenade_ar2" or class == "prop_combine_ball"
end

local function hostileProfile(attacker, inflictor, dmginfo)
    if not IsValid(attacker) or not attacker.LODHostile then return nil end
    local id = attacker.LODArchetypeId
    local profile = HOSTILE_ATTACKS[id]
    if not profile then return nil end

    if id == "soldier" or id == "blitzer" or id == "bioblaster" or id == "sniper" then
        return profile, IsValid(inflictor) and inflictor or nil
    end
    if id == "deadcrab" and dmginfo:IsDamageType(DMG_BLAST) then
        return profile, attacker
    end
    return profile, nil
end

hook.Add("EntityTakeDamage", "LOD_DiceDamageAuthority", function(target, dmginfo)
    if not IsValid(target) or not dmginfo then return end
    local statusElements = LOD.RPGStatusElements
    local statusContext = statusElements and statusElements:DamageContext(dmginfo, target)
    if statusContext and (statusContext.statusDamage or statusContext.settledShotgun or statusContext.actorDamageResolved) then return end
    local attacker = dmginfo:GetAttacker()
    local inflictor = dmginfo:GetInflictor()

    if (target.LODHostile or target:IsPlayer()) and qualifyingPlayerShooter(attacker) then
        local weaponClass = activeWeaponClass(attacker)
        -- Hero of Legend already enters through the Crowbar-family dice
        -- authority. It is not a firearm event, even if the player switches to
        -- a gun while the visible pulse is still travelling.
        if dmginfo:IsDamageType(DMG_ENERGYBEAM) then return end
        if grenadeAttack(attacker, inflictor, dmginfo) then
            local contract = grenadeRolls[inflictor]
            if not contract then
                local profile = {weaponFamilyId = "grenade", label = "GRENADE", count = 1, sides = 20}
                local rng = Rolls:_RNG("player:grenade")
                contract = Rolls:RollActorDamage(attacker, profile, rng, 0)
                grenadeRolls[inflictor] = contract
                Rolls.Stats.playerAttacks = Rolls.Stats.playerAttacks + 1

                local continuations = math.max(0, #(contract.values or {}) - (contract.baseDice or 1))
                if continuations > 0 then
                    Rolls:EmitDiceExplosionFX(attacker, "grenade", continuations, 1)
                end
            end
            if statusElements then statusElements:AttachDamageContext(dmginfo, {physical = true, attackEvent = contract.attackEvent, damageContract = contract}) end
            local falloff = math.Clamp(dmginfo:GetDamage() / GRENADE_REFERENCE_DAMAGE, 0.05, 1)
            local aimMult = tonumber(inflictor.LODAimMultiplier) or 1
            local final = math.max(1, Rolls:ResolveActorDamage(contract, attacker, target,
                {physical = true, authoredScale = falloff * aimMult, attackMultiplier = aimMult}))
            dmginfo:SetDamage(final)

            local detailStr = string.format("[rolls %s; blast x%.2f]",
                LOD.DieLogger:RollBreakdown(contract), falloff)
            if aimMult > 1 then
                local multText = aimMult == 3 and "x3" or "x2"
                detailStr = string.format("[rolls %s; blast x%.2f; AIM %s]",
                    LOD.DieLogger:RollBreakdown(contract), falloff, multText)
            end

            Rolls:QueueDamageReport(dmginfo, function(finalDamage)
                Rolls:_Send(attacker, 0, Rolls:_DamageEventText(attacker, LOD.DieLogger:DamageFormula(contract) or "1d20",
                    finalDamage, target, detailStr, nil, "Hostile", "grenade"))
            end)
        elseif weaponClass == "weapon_crowbar" and dmginfo:IsDamageType(DMG_CLUB) then
            local effects = LOD.RPG and LOD.RPG.FeatEffectSystem
            local profile = effects and effects.CrowbarDamageProfile
                and effects:CrowbarDamageProfile(attacker)
                or {label = "CROWBAR", source = "crowbar", count = 1, sides = 3}
            local rng = Rolls:_RNG("player:weapon_crowbar")
            local rolled = Rolls:RollActorDamage(attacker, profile, rng, 0)
            if LOD.Equipment and LOD.Equipment.SealWeaponAttack then LOD.Equipment:SealWeaponAttack(attacker,rolled,"weapon_lod_crowbar") end
            if LOD.RPGCrossFeats then LOD.RPGCrossFeats:AugmentMeteor(attacker, rolled, rng) end
            local tags={physical=true,melee=true,attackEvent=rolled.attackEvent,meteor=rolled,damageContract=rolled}
            local total = Rolls:ResolveActorDamage(rolled, attacker, target, tags)
            if statusElements then statusElements:AttachDamageContext(dmginfo,tags) end
            dmginfo:SetDamage(total)
            Rolls.Stats.playerAttacks = Rolls.Stats.playerAttacks + 1

            local continuations = math.max(0, #(rolled.values or {}) - (rolled.baseDice or 1))
            if continuations > 0 then
                Rolls:EmitDiceExplosionFX(attacker, "weapon_crowbar", continuations, 1)
            end
            local detail = Rolls:_PlayerRollDetail(rolled)
            Rolls:QueueDamageReport(dmginfo, function(finalDamage)
                Rolls:_Send(attacker, 0, Rolls:_DamageEventText(attacker, LOD.DieLogger:DamageFormula(rolled),
                    finalDamage, target, detail, nil, "Hostile", "crowbar"))
            end)
        elseif weaponClass == "weapon_shotgun" then
            -- Pellets are collected by their bullet callback, never inferred
            -- from Source's merged CTakeDamageInfo. No second damage path.
            return
        else
            local contract = attacker.LODActivePlayerRoll
            local blocked = LOD.GeneratedGeometryBallistics
                and LOD.GeneratedGeometryBallistics.PlayerBulletBlocked
                and LOD.GeneratedGeometryBallistics:PlayerBulletBlocked(target, dmginfo)
            if not blocked and contract and CurTime() - contract.created < 0.20
                and contract.weaponClass == weaponClass and dmginfo:GetDamage() > 0
                and not contract.targets[target] then
                contract.targets[target] = true

                local pierce = weaponClass == "weapon_357" and LOD.MagnumPiercing
                    and LOD.MagnumPiercing.DamageSegments
                    and LOD.MagnumPiercing.DamageSegments[dmginfo] or nil
                local damageContract = pierce and pierce.rpgContract or contract
                local tags={physical=true,attackEvent=contract.attackEvent,damageContract=contract,
                    authoredScale=tonumber(contract.aimMultiplier) or 1, attackMultiplier=tonumber(contract.aimMultiplier) or 1}
                local resolved = Rolls:ResolveActorDamage(damageContract, attacker, target,tags)
                if statusElements then statusElements:AttachDamageContext(dmginfo,tags) end
                dmginfo:SetDamage(resolved)

                local formula = LOD.DieLogger:DamageFormula(damageContract)
                local detail = Rolls:_PlayerRollDetail(damageContract)
                if pierce and pierce.depth and pierce.depth > 1 then
                    formula = LOD.DieLogger:DamageFormula(damageContract) or string.format("%dd12!", damageContract.baseDice or pierce.depth)
                    detail = string.format("[pierce #%d; rolls %s%s; AIM x%g]", pierce.depth,
                        LOD.DieLogger:RollBreakdown(damageContract),
                        damageContract.capped and "; chain cap" or "", tonumber(contract.aimMultiplier) or 1)
                end

                contract.feedReported = true
                Rolls:QueueDamageReport(dmginfo, function(finalDamage)
                    Rolls:_Send(attacker, 0, Rolls:_DamageEventText(attacker, formula,
                        finalDamage, target, detail, nil, "Hostile", PLAYER_WEAPONS[contract.weaponClass].source))
                end)
            end
        end
        return
    end

    if (target.LODHostile or target:IsPlayer()) and target:Health() > 0
        and IsValid(attacker) and attacker.LODHostile then
        local profile, cacheOwner = hostileProfile(attacker, inflictor, dmginfo)
        if not profile then return end
        local contract = Rolls:RollHostileAttack(attacker, profile, dmginfo:GetDamage(), cacheOwner)
        if not contract then return end
        contract.final = math.max(1, Rolls:ResolveActorDamage(contract, attacker, target,
            {physical = true, authoredScale = contract.scale}))
        dmginfo:SetDamage(contract.final)
        -- Preserve the semantic classification through the later final-defense
        -- seam. Mind Over Matter (and future physical-only defenses) must use
        -- the same physical tag that resolved this hostile attack's contract.
        if statusElements and statusElements.AttachDamageContext then
            statusElements:AttachDamageContext(dmginfo, {physical = true, attackEvent = contract.attackEvent, damageContract = contract})
        end
        Rolls:QueueDamageReport(dmginfo, function(finalDamage)
            contract.final = finalDamage
            if target:IsPlayer() then Rolls:_Send(target, 1, Rolls:_HostileRollText(contract, attacker, target)) end
        end)
    end
end)

concommand.Add("lod_dice_status", function(ply)
    local cv = GetConVar("lod_developer_mode")
    if cv and not cv:GetBool() then return end
    if IsValid(ply) and not ply:IsAdmin() then return end
    local stats = Rolls.Stats
    local pass = stats.rolls > 0 and stats.feedMessages > 0 and (stats.healthRolls or 0) > 0
        and stats.playerAttacks > 0 and stats.hostileAttacks > 0
    local text = string.format(
        "rolls=%d playerAttacks=%d hostileAttacks=%d healthRolls=%d feed=%d serial=%d result=%s",
        stats.rolls or 0, stats.playerAttacks or 0, stats.hostileAttacks or 0,
        stats.healthRolls or 0, stats.feedMessages or 0, Rolls.Serial or 0,
        pass and "PASS" or "WAITING")
    print("[LOD:DICE] " .. text)
    if IsValid(ply) then ply:ChatPrint(text) end
end)

-- Hooks compose changes without returning (which would short-circuit peers).
-- Source requires true from the final gamemode seam to commit those changes.
local baseFireBullets = GM.EntityFireBullets
function GM:EntityFireBullets(shooter, bullet)
    local result = baseFireBullets and baseFireBullets(self, shooter, bullet)
    if result == false then return false end
    return true
end

local function clearPendingFirearms(ply)
    if not IsValid(ply) then return end
    ply.LODCombatLifeSerial = (ply.LODCombatLifeSerial or 0) + 1
    ply.LODActiveShotgunRoll, ply.LODActivePlayerRoll = nil, nil
end
hook.Add("PlayerDeath", "LOD_CombatAttackLife", clearPendingFirearms)
hook.Add("PlayerSpawn", "LOD_CombatAttackLife", clearPendingFirearms)
hook.Add("PlayerDisconnected", "LOD_CombatAttackLife", clearPendingFirearms)
