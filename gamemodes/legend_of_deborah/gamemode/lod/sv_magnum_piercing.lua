LOD = LOD or {}
LOD.MagnumPiercing = LOD.MagnumPiercing or {}

local Piercing = LOD.MagnumPiercing
local Ballistics = LOD.GeneratedGeometryBallistics
local Rolls = LOD.CombatRolls

local MAX_TOTAL_TARGETS = LOD.RPG.Constants.MaxPenetrationTargetsPerProjectile or 128
local MAX_TRACE_STEPS = 512
local MAX_DISTANCE = 8192
local ADVANCE_EPSILON = 6
local MAGNUM_BONUS_PROFILE = {
    label = "MAGNUM PIERCE BONUS",
    source = ".357 Magnum",
    count = 1,
    sides = 12,
    exploding = 8
}

Piercing.DamageSegments = Piercing.DamageSegments or setmetatable({}, {__mode = "k"})
Piercing.Stats = Piercing.Stats or {shots = 0, extraTargets = 0, maxTargets = 0}

local function activeMagnum(ply)
    if not IsValid(ply) or not ply:IsPlayer() or not ply:Alive() then return nil end
    local weapon = ply:GetActiveWeapon()
    if not IsValid(weapon) or weapon:GetClass() ~= "weapon_357" then return nil end
    return weapon
end

local function combatBody(ent)
    return IsValid(ent) and (ent.LODHostile or ent.LODSummonedSeeker or (ent.IsPlayer and ent:IsPlayer()))
end
local function validHostile(ent, attacker)
    if LOD.FactionManager and LOD.FactionManager.IsOpponent then return LOD.FactionManager:IsOpponent(attacker, ent) end
    return IsValid(ent) and ent.LODHostile and not ent.LODDead and ent:Health() > 0
end

local function impactDirection(bullet, tr, attacker)
    local src = bullet and bullet.Src or (IsValid(attacker) and attacker:GetShootPos()) or vector_origin
    if tr and tr.HitPos and src ~= vector_origin then
        local delta = tr.HitPos - src
        if delta:LengthSqr() > 1 then return delta:GetNormalized() end
    end
    local dir = bullet and bullet.Dir or (IsValid(attacker) and attacker:GetAimVector()) or vector_origin
    return dir:GetNormalized()
end

local function traceNext(startPos, endpoint, ignored)
    return util.TraceLine({
        start = startPos,
        endpos = endpoint,
        -- Use the ordinary bullet mask to reliably discover the next damageable
        -- body. Every candidate segment is separately checked against LOD's
        -- MASK_SOLID generated-geometry authority before damage is applied.
        mask = MASK_SHOT,
        filter = ignored
    })
end

local function copyValues(values)
    local out = {}
    for i, value in ipairs(values or {}) do out[i] = value end
    return out
end

local function copyEntities(entities)
    local out = {}
    for _, ent in ipairs(entities or {}) do
        if IsValid(ent) then out[#out + 1] = ent end
    end
    return out
end

-- Generated-geometry rejection normally re-traces from the player's muzzle. A
-- deliberately piercing round has already passed through earlier hostiles, so
-- subsequent damage events validate only the new segment between bodies. World
-- and generated maze collision remain fully authoritative.
if Ballistics and not Ballistics.LODMagnumPiercingWrapped then
    Ballistics.LODMagnumPiercingWrapped = true
    local basePlayerBulletBlocked = Ballistics.PlayerBulletBlocked

    function Ballistics:PlayerBulletBlocked(hostile, dmginfo)
        local segment = Piercing.DamageSegments[dmginfo]
        if segment and segment.startPos and segment.endPos then
            local attacker = dmginfo:GetAttacker()
            local blocked = self:SegmentBlocked(
                segment.startPos,
                segment.endPos,
                attacker,
                hostile,
                segment.ignore
            )
            return blocked == true
        end
        return basePlayerBulletBlocked(self, hostile, dmginfo)
    end
end

hook.Add("EntityFireBullets", "LOD_MagnumPiercing", function(shooter, bullet)
    local weapon = activeMagnum(shooter)
    if not IsValid(weapon) then return end

    local previousCallback = bullet.Callback
    bullet.Callback = function(attacker, tr, dmginfo)
        -- Capture the impact before the preceding callback can kill/remove it.
        local first = tr and tr.Entity
        local firstBody = combatBody(first)
        local firstHit = firstBody and validHostile(first, attacker)
        local firstPos = tr and tr.HitPos
        local previousResult = previousCallback and previousCallback(attacker, tr, dmginfo)
        if type(previousResult) == "table" and previousResult.damage == false then return previousResult end
        if not IsValid(attacker) or attacker ~= shooter or not firstBody or not firstPos then return previousResult end

        local contract = attacker.LODActivePlayerRoll
        if not contract or contract.weaponClass ~= "weapon_357"
            or CurTime() - (contract.created or 0) >= 0.20
        then
            return
        end

        -- Do not allow Source's occasional scripted-geometry shot-mask mismatch
        -- to turn a visually blocked first impact into a penetration chain.
        if Ballistics then
            local blocked = Ballistics:SegmentBlocked(bullet.Src or attacker:GetShootPos(), firstPos, attacker, first)
            if blocked then return end
        end

        local direction = impactDirection(bullet, {HitPos = firstPos}, attacker)
        if direction == vector_origin then return end

        local origin = bullet.Src or attacker:GetShootPos()
        local maximum = math.min(MAX_DISTANCE, tonumber(bullet.Distance) or MAX_DISTANCE)
        local endpoint = origin + direction * maximum
        local ignored = {attacker, weapon, first}
        local seen = {[first] = true}
        local startPos = firstPos + direction * ADVANCE_EPSILON
        local targets, steps = firstHit and 1 or 0, 0
        local cumulativeTotal = math.max(1, tonumber(contract.total) or tonumber(dmginfo:GetDamage()) or 1)
        local cumulativeValues = copyValues(contract.values)
        local cumulativeStarts = copyValues(contract.chainStarts or {1})
        local cumulativeThresholds = copyValues(contract.thresholds)
        local cumulativeCapped = contract.capped == true
        local cumulativeContributions = copyValues(contract.contributions)
        local cumulativeBonus = tonumber(contract.bonus) or 0
        local cumulativeBaseDice = math.max(1, math.floor(tonumber(contract.baseDice) or 1))
        local aimMultiplier = math.max(1, tonumber(contract.aimMultiplier) or 1)
        Piercing.Stats.shots = (Piercing.Stats.shots or 0) + 1

        while targets < MAX_TOTAL_TARGETS and steps < MAX_TRACE_STEPS and startPos:Distance(origin) < maximum do
            steps = steps + 1
            local nextTrace = traceNext(startPos, endpoint, ignored)
            if not nextTrace.Hit then break end

            local target = nextTrace.Entity
            if not combatBody(target) or seen[target] or not nextTrace.HitPos
                or nextTrace.HitPos:Distance(origin) > maximum then break end
            seen[target] = true

            -- The already-pierced hostile bodies are intentionally transparent
            -- to this segment. Generated/world architecture is not. Previously
            -- the MASK_SOLID safety trace forgot this distinction and could hit
            -- the first enemy's solid hull again only six units beyond impact,
            -- incorrectly terminating an otherwise valid aligned chain.
            if Ballistics then
                local blocked = Ballistics:SegmentBlocked(
                    startPos,
                    nextTrace.HitPos,
                    attacker,
                    target,
                    ignored
                )
                if blocked then break end
            end

            if validHostile(target, attacker) then
                -- Each deeper body adds one fresh independent d12 Boomchain to the
                -- cumulative damage. Earlier chains are carried forward, never
                -- rerolled. The shared d12 authority resets every new chain to 8+,
                -- then lowers continuation thresholds one step per explosion toward
                -- the current Boomchain Floor (default 5). Aim State belongs to the
                -- whole trigger/projectile, so its x2 multiplier also applies to every
                -- fresh pierce chain rather than only the first body's base roll.
                local depth = targets + 1
                local bonusTotal, bonusValues, bonusContributions, bonusContract = 0, {}, {}, nil
                if targets > 0 and Rolls and Rolls._RNG and Rolls.RollActorDamage then
                    local rng = Rolls:_RNG("magnum-pierce-bonus:" .. tostring(depth))
                    local bonusProfile = table.Copy(MAGNUM_BONUS_PROFILE)
                    bonusProfile.attackEvent = contract.attackEvent
                    bonusContract = Rolls:RollActorDamage(attacker, bonusProfile, rng, 0)
                    bonusTotal = bonusContract.total
                    bonusValues = bonusContract.values or {}
                    bonusContributions = bonusContract.contributions or bonusValues
                elseif targets > 0 then
                    bonusTotal = math.random(1, 12)
                    bonusValues = {bonusTotal}
                    bonusContributions = {bonusTotal}
                end

                cumulativeTotal = cumulativeTotal
                    + math.max(0, tonumber(bonusTotal) or 0) * aimMultiplier
                local offset = #cumulativeValues
                for _, start in ipairs(bonusContract and bonusContract.chainStarts or (#bonusValues > 0 and {1} or {})) do
                    cumulativeStarts[#cumulativeStarts+1] = offset+start
                end
                for i, value in ipairs(bonusValues) do
                    cumulativeValues[offset+i] = value
                    cumulativeThresholds[offset+i] = bonusContract and bonusContract.thresholds and bonusContract.thresholds[i]
                end
                cumulativeCapped = cumulativeCapped or (bonusContract and bonusContract.capped == true)
                for _, contribution in ipairs(bonusContributions) do
                    cumulativeContributions[#cumulativeContributions + 1] = contribution
                end
                if targets > 0 then cumulativeBaseDice = cumulativeBaseDice + 1 end

                if Rolls and Rolls.EmitDiceExplosionFX and #bonusValues > 1 then
                    Rolls:EmitDiceExplosionFX(attacker, "weapon_357", #bonusValues - 1, depth)
                end

                local info = LOD.NewDamageInfo()
                info:SetAttacker(attacker)
                info:SetInflictor(weapon)
                info:SetDamage(cumulativeTotal)
                info:SetDamageType(DMG_BULLET)
                info:SetDamagePosition(nextTrace.HitPos)
                info:SetDamageForce(direction * math.max(1, cumulativeTotal) * 30)

                Piercing.DamageSegments[info] = {
                    startPos = startPos,
                    endPos = nextTrace.HitPos,
                    depth = depth,
                    total = cumulativeTotal,
                    rpgContract = {
                        originContract = contract, attackEvent = contract.attackEvent,
                        profile = contract.profile, formula = string.format("%dd12!", cumulativeBaseDice),
                        wizardFullMagicIntBonus = contract.wizardFullMagicIntBonus,
                        identityWeaponStacks = contract.identityWeaponStacks,
                        identityEnemyStacks = contract.identityEnemyStacks,
                        identityDieSeed = contract.identityDieSeed,
                        primaryAuthoredDamageDie = contract.primaryAuthoredDamageDie,
                        identityTargetViews = contract.identityTargetViews and setmetatable({}, {__mode = "k"}),
                        total = cumulativeTotal,
                        values = copyValues(cumulativeValues),
                        chainStarts = copyValues(cumulativeStarts),
                        thresholds = copyValues(cumulativeThresholds),
                        capped = cumulativeCapped,
                        contributions = copyValues(cumulativeContributions),
                        bonus = cumulativeBonus,
                        baseDice = cumulativeBaseDice
                    },
                    ignore = copyEntities(ignored)
                }
                target:TakeDamageInfo(info)

                targets = depth
                Piercing.Stats.extraTargets = (Piercing.Stats.extraTargets or 0) + 1
            end
            ignored[#ignored + 1] = target
            startPos = nextTrace.HitPos + direction * ADVANCE_EPSILON
        end

        Piercing.Stats.maxTargets = math.max(Piercing.Stats.maxTargets or 0, targets)
        return previousResult
    end
end)

concommand.Add("lod_magnum_pierce_status", function(ply)
    local cv = GetConVar("lod_developer_mode")
    if cv and not cv:GetBool() then return end
    if IsValid(ply) and not ply:IsAdmin() then return end

    local floor = Rolls and Rolls.GetD12BoomchainFloor and Rolls:GetD12BoomchainFloor() or 5
    local line = string.format("shots=%d extraTargets=%d maxTargets=%d cap=%d escalatingDice=true boomStart=8 boomFloor=%d geometrySafe=true aimSafe=true",
        Piercing.Stats.shots or 0,
        Piercing.Stats.extraTargets or 0,
        Piercing.Stats.maxTargets or 0,
        MAX_TOTAL_TARGETS,
        floor)
    print("[LOD:MAGNUM-PIERCE] " .. line)
    if IsValid(ply) then ply:ChatPrint(line) end
end)
