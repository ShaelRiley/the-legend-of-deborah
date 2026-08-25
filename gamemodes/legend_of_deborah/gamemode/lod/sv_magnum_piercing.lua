LOD = LOD or {}
LOD.MagnumPiercing = LOD.MagnumPiercing or {}

local Piercing = LOD.MagnumPiercing
local Ballistics = LOD.GeneratedGeometryBallistics

local MAX_TOTAL_TARGETS = 8
local MAX_DISTANCE = 8192
local ADVANCE_EPSILON = 6

Piercing.DamageSegments = Piercing.DamageSegments or setmetatable({}, {__mode = "k"})
Piercing.Stats = Piercing.Stats or {shots = 0, extraTargets = 0, maxTargets = 0}

local function activeMagnum(ply)
    if not IsValid(ply) or not ply:IsPlayer() or not ply:Alive() then return nil end
    local weapon = ply:GetActiveWeapon()
    if not IsValid(weapon) or weapon:GetClass() ~= "weapon_357" then return nil end
    return weapon
end

local function validHostile(ent)
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

local function traceNext(startPos, direction, ignored)
    return util.TraceLine({
        start = startPos,
        endpos = startPos + direction * MAX_DISTANCE,
        -- Use the ordinary bullet mask to reliably discover the next damageable
        -- body. Every candidate segment is separately checked against LOD's
        -- MASK_SOLID generated-geometry authority before damage is applied.
        mask = MASK_SHOT,
        filter = ignored
    })
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
            local blocked = self:SegmentBlocked(segment.startPos, segment.endPos, attacker, hostile)
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
        if previousCallback then previousCallback(attacker, tr, dmginfo) end
        if not IsValid(attacker) or attacker ~= shooter or not tr or not validHostile(tr.Entity) then return end

        local contract = attacker.LODActivePlayerRoll
        if not contract or contract.weaponClass ~= "weapon_357"
            or CurTime() - (contract.created or 0) >= 0.20
        then
            return
        end

        -- Do not allow Source's occasional scripted-geometry shot-mask mismatch
        -- to turn a visually blocked first impact into a penetration chain.
        if Ballistics then
            local blocked = Ballistics:SegmentBlocked(attacker:GetShootPos(), tr.HitPos, attacker, tr.Entity)
            if blocked then return end
        end

        local direction = impactDirection(bullet, tr, attacker)
        if direction == vector_origin then return end

        local ignored = {attacker, weapon, tr.Entity}
        local startPos = tr.HitPos + direction * ADVANCE_EPSILON
        local targets = 1
        Piercing.Stats.shots = (Piercing.Stats.shots or 0) + 1

        while targets < MAX_TOTAL_TARGETS do
            local nextTrace = traceNext(startPos, direction, ignored)
            if not nextTrace.Hit then break end

            local target = nextTrace.Entity
            if not validHostile(target) then break end

            -- MASK_SHOT can intentionally ignore some scripted maze slabs. Stop
            -- the chain if the authoritative generated/world collision trace says
            -- there is real cover between the previous body and this candidate.
            if Ballistics then
                local blocked = Ballistics:SegmentBlocked(startPos, nextTrace.HitPos, attacker, target)
                if blocked then break end
            end

            local info = DamageInfo()
            info:SetAttacker(attacker)
            info:SetInflictor(weapon)
            info:SetDamage(contract.total or dmginfo:GetDamage())
            info:SetDamageType(DMG_BULLET)
            info:SetDamagePosition(nextTrace.HitPos)
            info:SetDamageForce(direction * math.max(1, contract.total or 1) * 30)

            Piercing.DamageSegments[info] = {
                startPos = startPos,
                endPos = nextTrace.HitPos
            }
            target:TakeDamageInfo(info)

            targets = targets + 1
            Piercing.Stats.extraTargets = (Piercing.Stats.extraTargets or 0) + 1
            ignored[#ignored + 1] = target
            startPos = nextTrace.HitPos + direction * ADVANCE_EPSILON
        end

        Piercing.Stats.maxTargets = math.max(Piercing.Stats.maxTargets or 0, targets)
    end
end)

concommand.Add("lod_magnum_pierce_status", function(ply)
    local cv = GetConVar("lod_developer_mode")
    if cv and not cv:GetBool() then return end
    if IsValid(ply) and not ply:IsAdmin() then return end

    local line = string.format("shots=%d extraTargets=%d maxTargets=%d cap=%d geometrySafe=true",
        Piercing.Stats.shots or 0,
        Piercing.Stats.extraTargets or 0,
        Piercing.Stats.maxTargets or 0,
        MAX_TOTAL_TARGETS)
    print("[LOD:MAGNUM-PIERCE] " .. line)
    if IsValid(ply) then ply:ChatPrint(line) end
end)
