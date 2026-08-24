LOD = LOD or {}
LOD.CombatRolls = LOD.CombatRolls or {}

local Rolls = LOD.CombatRolls
local MAX_CHAIN_DICE = 64
local SHOTGUN_SHARE_COUNT = 6
local GRENADE_REFERENCE_DAMAGE = 150

util.AddNetworkString("LOD_CombatRoll")

Rolls.Stats = Rolls.Stats or {
    rolls = 0,
    playerAttacks = 0,
    hostileAttacks = 0,
    feedMessages = 0
}

local PLAYER_WEAPONS = {
    weapon_pistol = {label = "PISTOL", count = 1, sides = 4},
    weapon_smg1 = {label = "SMG", count = 1, sides = 8},
    weapon_ar2 = {label = "AR2", count = 1, sides = 10},
    weapon_357 = {label = "MAGNUM", count = 1, sides = 12, exploding = 10},
    weapon_shotgun = {label = "SHOTGUN", count = 1, sides = 6, exploding = 6, floor = 3}
}

-- Initial hostile attack dice preserve the approximate means of the accepted
-- fixed-damage baseline while moving every direction of combat onto one roll
-- authority. Multiple dice deliberately narrow lethal low/high outliers.
local HOSTILE_ATTACKS = {
    shambler = {label = "SHAMBLER", count = 3, sides = 10, bonus = 3, reference = 20},
    runner = {label = "RUNNER", count = 2, sides = 8, bonus = 1, reference = 10},
    soldier = {label = "SOLDIER", count = 1, sides = 10, bonus = 1, reference = 6},
    blitzer = {label = "BLITZER", count = 1, sides = 8, bonus = 1, reference = 5},
    bioblaster = {label = "BIO BLASTER", count = 8, sides = 8, bonus = 9, reference = 45},
    deadcrab = {label = "DEADCRAB", count = 8, sides = 10, bonus = 11, reference = 55}
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
    local total = profile.bonus or 0
    local natural = rng:Int(1, profile.sides)

    while natural and #values < MAX_CHAIN_DICE do
        values[#values + 1] = natural
        local contribution = math.max(profile.floor or natural, natural)
        contributions[#contributions + 1] = contribution
        total = total + contribution
        self.Stats.rolls = self.Stats.rolls + 1

        local explodes = profile.exploding and natural >= profile.exploding
        if not explodes then break end
        natural = rng:Int(1, profile.sides)
    end

    return total, values, contributions, #values >= MAX_CHAIN_DICE
end

local function valueList(values)
    local out = {}
    for i, value in ipairs(values or {}) do out[i] = tostring(value) end
    return table.concat(out, ",")
end

function Rolls:RollPlayerWeapon(ply, weaponClass)
    local profile = PLAYER_WEAPONS[weaponClass]
    if not profile then return nil end
    local rng = self:_RNG("player:" .. weaponClass)
    local total, values, contributions, capped
    if profile.exploding then
        total, values, contributions, capped = self:_RollExploding(profile, rng)
    else
        total, values = self:_RollFormula(profile, rng)
    end

    local contract = {
        label = profile.label,
        weaponClass = weaponClass,
        formula = diceNotation(profile),
        total = total,
        values = values,
        contributions = contributions,
        capped = capped == true,
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

function Rolls:_PlayerRollText(contract)
    if contract.weaponClass == "weapon_357" then
        local parts = {}
        for index, value in ipairs(contract.values or {}) do
            parts[#parts + 1] = string.format("d12=%d%s", value,
                index < #(contract.values or {}) and " EXPLODE" or "")
        end
        return string.format("MAGNUM %s; TOTAL=%d%s", table.concat(parts, "; "),
            contract.total, contract.capped and " [CHAIN CAP]" or "")
    end

    if contract.weaponClass == "weapon_shotgun" then
        return string.format("SHOTGUN d6[%s]=%d; PELLETS %d",
            valueList(contract.values), contract.total, contract.pellets or 6)
    end

    return string.format("%s %s=%d", contract.label, contract.formula, contract.total)
end

function Rolls:_FinishShotgunFeed(ply, contract)
    if not IsValid(ply) then return end
    local bestTarget
    local bestHits = 0
    for target, hits in pairs(contract.hits or {}) do
        if IsValid(target) and hits > bestHits then
            bestTarget = target
            bestHits = hits
        end
    end
    local damage = bestTarget and (contract.damageByTarget[bestTarget] or 0) or 0
    local text = string.format("%s; LANDED %d/%d; DAMAGE %.1f",
        self:_PlayerRollText(contract), bestHits, contract.pellets or 6, damage)
    self:_Send(ply, 0, text)
end

function Rolls:RollHostileAttack(hostile, profile, originalDamage, cacheOwner)
    if not profile then return nil end
    local cached = IsValid(cacheOwner) and cacheOwner.LODCombatRollContract or nil
    local total
    local values
    if cached and cached.profile == profile then
        total = cached.total
        values = cached.values
    else
        local rng = self:_RNG("hostile:" .. tostring(hostile.LODArchetypeId or "unknown"))
        total, values = self:_RollFormula(profile, rng)
        if IsValid(cacheOwner) then
            cacheOwner.LODCombatRollContract = {
                profile = profile,
                total = total,
                values = values
            }
        end
        self.Stats.hostileAttacks = self.Stats.hostileAttacks + 1
    end

    -- Shared blasts reuse one rolled base for every victim, then independently
    -- apply the already-authored distance/size multiplier for each damage event.
    local scale = math.max(0, tonumber(originalDamage) or profile.reference or total)
        / math.max(1, profile.reference or total)
    local final = math.max(1, math.floor(total * scale + 0.5))
    local contract = {
        profile = profile,
        total = total,
        values = values,
        scale = scale,
        final = final
    }
    return contract
end

function Rolls:_HostileRollText(contract)
    local profile = contract.profile
    local text = string.format("%s %s [%s]=%d", profile.label,
        diceNotation(profile), valueList(contract.values), contract.total)
    if math.abs((contract.scale or 1) - 1) > 0.01 then
        text = text .. string.format(" x%.2f=%d", contract.scale, contract.final)
    end
    return text .. " -> YOU"
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

    if weaponClass == "weapon_shotgun" then
        bullet.Num = contract.pellets
        bullet.Damage = contract.total / SHOTGUN_SHARE_COUNT
        shooter.LODActiveShotgunRoll = contract
        timer.Simple(0, function()
            if shooter.LODActiveShotgunRoll == contract then
                shooter.LODActiveShotgunRoll = nil
            end
            Rolls:_FinishShotgunFeed(shooter, contract)
        end)
    else
        bullet.Damage = contract.total
        Rolls:_Send(shooter, 0, Rolls:_PlayerRollText(contract))
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
        if weaponClass == "weapon_crowbar" and dmginfo:IsDamageType(DMG_CLUB) then
            local profile = {label = "CROWBAR", count = 1, sides = 8}
            local rng = Rolls:_RNG("player:weapon_crowbar")
            local total = Rolls:_RollFormula(profile, rng)
            dmginfo:SetDamage(total)
            Rolls.Stats.playerAttacks = Rolls.Stats.playerAttacks + 1
            Rolls:_Send(attacker, 0, string.format("CROWBAR 1d8=%d", total))
        elseif weaponClass == "weapon_shotgun" then
            local contract = attacker.LODActiveShotgunRoll
            local blocked = LOD.GeneratedGeometryBallistics
                and LOD.GeneratedGeometryBallistics.PlayerBulletBlocked
                and LOD.GeneratedGeometryBallistics:PlayerBulletBlocked(target, dmginfo)
            if not blocked and contract and CurTime() - contract.created < 0.20 and dmginfo:GetDamage() > 0 then
                contract.hits[target] = (contract.hits[target] or 0) + 1
                contract.damageByTarget[target] = (contract.damageByTarget[target] or 0) + dmginfo:GetDamage()
            end
        elseif grenadeAttack(attacker, inflictor, dmginfo) then
            local contract = grenadeRolls[inflictor]
            if not contract then
                local profile = {label = "GRENADE", count = 1, sides = 20}
                local rng = Rolls:_RNG("player:grenade")
                local total, values = Rolls:_RollFormula(profile, rng)
                contract = {total = total, values = values}
                grenadeRolls[inflictor] = contract
                Rolls.Stats.playerAttacks = Rolls.Stats.playerAttacks + 1
                Rolls:_Send(attacker, 0, string.format("GRENADE 1d20=%d", total))
            end
            local falloff = math.Clamp(dmginfo:GetDamage() / GRENADE_REFERENCE_DAMAGE, 0.05, 1)
            dmginfo:SetDamage(math.max(1, contract.total * falloff))
        end
        return
    end

    if target:IsPlayer() and target:Alive() and IsValid(attacker) and attacker.LODHostile then
        local profile, cacheOwner = hostileProfile(attacker, inflictor, dmginfo)
        if not profile then return end
        local contract = Rolls:RollHostileAttack(attacker, profile, dmginfo:GetDamage(), cacheOwner)
        if not contract then return end
        dmginfo:SetDamage(contract.final)
        Rolls:_Send(target, 1, Rolls:_HostileRollText(contract))
    end
end)

concommand.Add("lod_dice_status", function(ply)
    local cv = GetConVar("lod_developer_mode")
    if cv and not cv:GetBool() then return end
    if IsValid(ply) and not ply:IsAdmin() then return end
    local stats = Rolls.Stats
    local pass = stats.rolls > 0 and stats.feedMessages > 0
        and stats.playerAttacks > 0 and stats.hostileAttacks > 0
    local text = string.format(
        "rolls=%d playerAttacks=%d hostileAttacks=%d feed=%d serial=%d result=%s",
        stats.rolls or 0, stats.playerAttacks or 0, stats.hostileAttacks or 0,
        stats.feedMessages or 0, Rolls.Serial or 0, pass and "PASS" or "WAITING")
    print("[LOD:DICE] " .. text)
    if IsValid(ply) then ply:ChatPrint(text) end
end)
