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

local PLAYER_WEAPONS = {
    weapon_pistol = {label = "PISTOL", source = "pistol", count = 1, sides = 4},
    weapon_smg1 = {label = "SMG", source = "SMG", count = 1, sides = 8},
    weapon_ar2 = {label = "AR2", source = "AR2", count = 1, sides = 10},
    weapon_357 = {label = "MAGNUM", source = ".357 Magnum", count = 1, sides = 12, exploding = 8},
    weapon_shotgun = {label = "SHOTGUN", source = "shotgun", count = 1, sides = 6, exploding = 6, floor = 3}
}

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

function Rolls:_Send(ply, category, text)
    if not IsValid(ply) or not ply:IsPlayer() then return end
    net.Start("LOD_CombatRoll")
    net.WriteUInt(math.Clamp(category or 0, 0, 3), 2)
    net.WriteString(string.sub(tostring(text or "ROLL"), 1, 180))
    net.Send(ply)
    self.Stats.feedMessages = self.Stats.feedMessages + 1
end

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

    while natural and #values < MAX_CHAIN_DICE do
        values[#values + 1] = natural
        thresholds[#thresholds + 1] = threshold
        local contribution = math.max(profile.floor or natural, natural)
        contributions[#contributions + 1] = contribution
        total = total + contribution
        self.Stats.rolls = self.Stats.rolls + 1

        local explodes = profile.exploding and natural >= threshold
        if not explodes then break end
        threshold = parameters and parameters.continuation or threshold
        natural = rng:Int(1, profile.sides)
    end

    return total, values, contributions, #values >= MAX_CHAIN_DICE, thresholds
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

function Rolls:_DamageEventText(source, formula, amount, target, detail, fallbackSource, fallbackTarget, damageSource)
    local prefix = string.format("%s dealt %s (%s)",
        entityDisplayName(source, fallbackSource), formula, damageText(amount))
    local suffix = string.format(" damage to %s, via %s",
        entityDisplayName(target, fallbackTarget), cleanName(damageSource or "unknown source"))
    local detailText = detail and detail ~= "" and (" " .. detail) or ""
    local detailBudget = 180 - #prefix - #suffix
    if #detailText > detailBudget then detailText = "" end
    return prefix .. detailText .. suffix
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
    local values, contributions, thresholds = {}, {}, {}
    local total = tonumber(resolvedProfile.bonus) or 0
    local capped = false
    local rogueExplodes = derived and derived.rogueAllDamageDiceExplode == true
        and resolvedProfile.classExplosionImmune ~= true
    local universalExplodes = sides == 6 or sides == 12
    local authoredExplodes = resolvedProfile.exploding ~= nil

    for _ = 1, count do
        local dieProfile = table.Copy(resolvedProfile)
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
    return {
        profile = resolvedProfile,
        formula = formula,
        total = total,
        values = values,
        contributions = contributions,
        thresholds = thresholds,
        bonus = tonumber(resolvedProfile.bonus) or 0,
        capped = capped,
        baseDice = count,
        aceBonusDice = math.max(0, math.floor(tonumber(bonusDice) or 0))
    }
end

function Rolls:ResolveActorDamage(contract, attacker, target, tags)
    local rules = LOD.RPGAbilityRules
    if not rules or not rules.ResolveDamageContract then return tonumber(contract and contract.total) or 0 end
    return rules:ResolveDamageContract(contract, attacker, target, tags)
end

function Rolls:RollPlayerWeapon(ply, weaponClass)
    local profile = PLAYER_WEAPONS[weaponClass]
    if not profile then return nil end
    local rng = self:_RNG("player:" .. weaponClass)
    local rules = LOD.RPGAbilityRules
    local aceBonus = rules and rules.CommitAttack and rules:CommitAttack(ply) and 1 or 0
    local rolled = self:RollActorDamage(ply, profile, rng, aceBonus)

    local contract = {
        label = profile.label,
        weaponClass = weaponClass,
        profile = rolled.profile,
        formula = rolled.formula,
        total = rolled.total,
        values = rolled.values,
        contributions = rolled.contributions,
        thresholds = rolled.thresholds,
        bonus = rolled.bonus,
        baseDice = rolled.baseDice,
        aceBonusDice = rolled.aceBonusDice,
        capped = rolled.capped == true,
        created = CurTime()
    }

    if weaponClass == "weapon_shotgun" then
        contract.pellets = SHOTGUN_SHARE_COUNT
        contract.bonusChecks = {}
        for index = 7, 9 do
            local added = rng:Int(1, 3) == 1
            contract.bonusChecks[#contract.bonusChecks + 1] = added
            if added then contract.pellets = contract.pellets + 1 end
            self.Stats.rolls = self.Stats.rolls + 1
        end
        contract.hits = setmetatable({}, {__mode = "k"})
        contract.damageByTarget = setmetatable({}, {__mode = "k"})
    end

    self.Stats.playerAttacks = self.Stats.playerAttacks + 1
    return contract
end

function Rolls:_PlayerRollDetail(contract)
    if contract.weaponClass == "weapon_357" then
        return string.format("[rolls %s%s]", table.concat(contract.values or {}, ">"),
            contract.capped and "; chain cap" or "")
    end
    return nil
end

function Rolls:_FinishShotgunFeed(ply, contract)
    if not IsValid(ply) then return end
    for target, hits in pairs(contract.hits or {}) do
        if IsValid(target) and hits > 0 then
            local damage = contract.damageByTarget[target] or 0
            if damage > 0 and LOD.M3HitFeedback and LOD.M3HitFeedback.ApplyShotgunShellStun then
                LOD.M3HitFeedback:ApplyShotgunShellStun(target)
            end
            local detail = string.format("[%d/%d pellets; rolls %s]", hits,
                contract.pellets or 6, table.concat(contract.values or {}, ">"))
            self:_Send(ply, 0, self:_DamageEventText(ply, contract.formula or "1d6!", damage,
                target, detail, nil, "Hostile", "shotgun"))
        end
    end
end

function Rolls:RollHostileAttack(hostile, profile, originalDamage, cacheOwner)
    if not profile then return nil end
    local cached = IsValid(cacheOwner) and cacheOwner.LODCombatRollContract or nil
    local total
    local values
    local contributions
    if cached and cached.profile == profile then
        total = cached.total
        values = cached.values
        contributions = cached.contributions
    else
        local rng = self:_RNG("hostile:" .. tostring(hostile.LODArchetypeId or "unknown"))
        local rolled = self:RollActorDamage(hostile, profile, rng, 0)
        total, values, contributions = rolled.total, rolled.values, rolled.contributions
        if IsValid(cacheOwner) then
            cacheOwner.LODCombatRollContract = {
                profile = profile,
                total = total,
                values = values,
                contributions = contributions
            }
        end
        self.Stats.hostileAttacks = self.Stats.hostileAttacks + 1
    end

    -- Shared blasts reuse one rolled base for every victim, then independently
    -- apply the already-authored distance/size multiplier for each damage event.
    local scale = math.max(0, tonumber(originalDamage) or profile.reference or total)
        / math.max(1, profile.reference or total)
    local contract = {
        profile = profile,
        total = total,
        values = values,
        contributions = contributions or values,
        bonus = profile.bonus or 0,
        scale = scale,
        final = math.max(1, math.floor(total * scale + 0.5))
    }
    return contract
end

function Rolls:_HostileRollText(contract, source, target)
    local profile = contract.profile
    local details = string.format("[rolls %s", valueList(contract.values))
    if math.abs((contract.scale or 1) - 1) > 0.01 then
        details = details .. string.format("; base %d x%.2f", contract.total, contract.scale)
    end
    details = details .. "]"
    return self:_DamageEventText(source, diceNotation(profile), contract.final,
        target, details, profile.label, "Player", profile.source)
end

local function qualifyingPlayerShooter(shooter)
    return IsValid(shooter) and shooter:IsPlayer() and shooter:Alive()
end

hook.Add("EntityFireBullets", "LOD_DicePlayerFirearms", function(shooter, bullet)
    if not qualifyingPlayerShooter(shooter) then return end
    local weaponClass = activeWeaponClass(shooter)
    local profile = PLAYER_WEAPONS[weaponClass]
    if not profile then return end

    local contract = Rolls:RollPlayerWeapon(shooter, weaponClass)
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
        timer.Simple(0, function()
            if shooter.LODActiveShotgunRoll == contract then
                shooter.LODActiveShotgunRoll = nil
            end
            Rolls:_FinishShotgunFeed(shooter, contract)
        end)
    else
        bullet.Damage = contract.total
        contract.targets = setmetatable({}, {__mode = "k"})
        shooter.LODActivePlayerRoll = contract
        timer.Simple(0, function()
            if IsValid(shooter) and shooter.LODActivePlayerRoll == contract then
                shooter.LODActivePlayerRoll = nil
            end
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

    if id == "soldier" or id == "blitzer" or id == "bioblaster" then
        return profile, IsValid(inflictor) and inflictor or nil
    end
    if id == "deadcrab" and dmginfo:IsDamageType(DMG_BLAST) then
        return profile, attacker
    end
    return profile, nil
end

hook.Add("EntityTakeDamage", "LOD_DiceDamageAuthority", function(target, dmginfo)
    if not IsValid(target) or not dmginfo then return end
    local attacker = dmginfo:GetAttacker()
    local inflictor = dmginfo:GetInflictor()

    if target.LODHostile and qualifyingPlayerShooter(attacker) then
        local weaponClass = activeWeaponClass(attacker)
        if grenadeAttack(attacker, inflictor, dmginfo) then
            local contract = grenadeRolls[inflictor]
            if not contract then
                local profile = {label = "GRENADE", count = 1, sides = 20}
                local rng = Rolls:_RNG("player:grenade")
                contract = Rolls:RollActorDamage(attacker, profile, rng, 0)
                grenadeRolls[inflictor] = contract
                Rolls.Stats.playerAttacks = Rolls.Stats.playerAttacks + 1
            end
            local falloff = math.Clamp(dmginfo:GetDamage() / GRENADE_REFERENCE_DAMAGE, 0.05, 1)
            local final = math.max(1, Rolls:ResolveActorDamage(contract, attacker, target,
                {physical = true, authoredScale = falloff}))
            dmginfo:SetDamage(final)
            Rolls:_Send(attacker, 0, Rolls:_DamageEventText(attacker, "1d20",
                final, target, string.format("[rolls %s; blast x%.2f]",
                    table.concat(contract.values or {}, ">"), falloff),
                nil, "Hostile", "grenade"))
        elseif weaponClass == "weapon_crowbar" and dmginfo:IsDamageType(DMG_CLUB) then
            local profile = {label = "CROWBAR", count = 1, sides = 8}
            local rng = Rolls:_RNG("player:weapon_crowbar")
            local rolled = Rolls:RollActorDamage(attacker, profile, rng, 0)
            local total = Rolls:ResolveActorDamage(rolled, attacker, target, {physical = true})
            dmginfo:SetDamage(total)
            Rolls.Stats.playerAttacks = Rolls.Stats.playerAttacks + 1
            Rolls:_Send(attacker, 0, Rolls:_DamageEventText(attacker, "1d8",
                total, target, nil, nil, "Hostile", "crowbar"))
        elseif weaponClass == "weapon_shotgun" then
            local contract = attacker.LODActiveShotgunRoll
            local blocked = LOD.GeneratedGeometryBallistics
                and LOD.GeneratedGeometryBallistics.PlayerBulletBlocked
                and LOD.GeneratedGeometryBallistics:PlayerBulletBlocked(target, dmginfo)
            if not blocked and contract and CurTime() - contract.created < 0.20 and dmginfo:GetDamage() > 0 then
                local shellDamage = Rolls:ResolveActorDamage(contract, attacker, target, {physical = true})
                dmginfo:SetDamage(math.max(1, shellDamage / SHOTGUN_SHARE_COUNT))
                contract.hits[target] = (contract.hits[target] or 0) + 1
                contract.damageByTarget[target] = (contract.damageByTarget[target] or 0) + dmginfo:GetDamage()
            end
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
                local resolved = Rolls:ResolveActorDamage(damageContract, attacker, target,
                    {physical = true, authoredScale = tonumber(contract.aimMultiplier) or 1})
                dmginfo:SetDamage(resolved)

                local formula = contract.weaponClass == "weapon_357"
                    and string.format("%dd12!", damageContract.baseDice or contract.baseDice or 1)
                    or contract.formula
                local detail = Rolls:_PlayerRollDetail(contract)
                if pierce and pierce.depth and pierce.depth > 1 then
                    formula = string.format("%dd12!", damageContract.baseDice or pierce.depth)
                    detail = pierce.detail or detail
                end

                Rolls:_Send(attacker, 0, Rolls:_DamageEventText(attacker, formula,
                    dmginfo:GetDamage(), target, detail, nil,
                    "Hostile", PLAYER_WEAPONS[contract.weaponClass].source))
            end
        end
        return
    end

    if target:IsPlayer() and target:Alive() and IsValid(attacker) and attacker.LODHostile then
        local profile, cacheOwner = hostileProfile(attacker, inflictor, dmginfo)
        if not profile then return end
        local contract = Rolls:RollHostileAttack(attacker, profile, dmginfo:GetDamage(), cacheOwner)
        if not contract then return end
        contract.final = math.max(1, Rolls:ResolveActorDamage(contract, attacker, target,
            {physical = true, authoredScale = contract.scale}))
        dmginfo:SetDamage(contract.final)
        Rolls:_Send(target, 1, Rolls:_HostileRollText(contract, attacker, target))
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
