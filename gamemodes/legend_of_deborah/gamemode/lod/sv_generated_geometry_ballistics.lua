LOD = LOD or {}
LOD.GeneratedGeometryBallistics = LOD.GeneratedGeometryBallistics or {}

local Ballistics = LOD.GeneratedGeometryBallistics

local function damagePoint(target, dmginfo)
    local pos = dmginfo and dmginfo.GetDamagePosition and dmginfo:GetDamagePosition() or vector_origin
    if pos == vector_origin or not pos then
        return IsValid(target) and target:WorldSpaceCenter() or vector_origin
    end
    return pos
end

local function traceIgnore(attacker)
    local ignored = {}
    if IsValid(attacker) then
        ignored[#ignored + 1] = attacker
        if attacker:IsPlayer() then
            local weapon = attacker:GetActiveWeapon()
            if IsValid(weapon) then ignored[#ignored + 1] = weapon end
        end
    end
    return ignored
end

-- Generated lod_static_box geometry is intentionally world-like, but Source's
-- stock MASK_SHOT path does not reliably treat our scripted SOLID_BBOX floor
-- slabs as bullet/LOS occluders. Use MASK_SOLID as the authoritative cover test.
-- A clear segment may terminate on the intended target; any earlier solid hit is
-- real cover and must prevent cross-floor/cross-wall combat.
function Ballistics:SegmentBlocked(startPos, endPos, attacker, intendedTarget)
    if not startPos or not endPos then return false, nil end
    local tr = util.TraceLine({
        start = startPos,
        endpos = endPos,
        mask = MASK_SOLID,
        filter = traceIgnore(attacker)
    })

    if not tr.Hit or tr.Fraction >= 0.995 then return false, tr end
    if IsValid(intendedTarget) and tr.Entity == intendedTarget then return false, tr end
    return true, tr
end

function Ballistics:PlayerBulletBlocked(hostile, dmginfo)
    if not IsValid(hostile) or not dmginfo or not dmginfo:IsDamageType(DMG_BULLET) then return false end
    local attacker = dmginfo:GetAttacker()
    if not IsValid(attacker) or not attacker:IsPlayer() then return false end

    local startPos = attacker:GetShootPos()
    local endPos = damagePoint(hostile, dmginfo)
    local blocked = self:SegmentBlocked(startPos, endPos, attacker, hostile)
    return blocked == true
end

-- Damage-time fail-safe. This is deliberately independent of the weapon class:
-- any player-originated bullet damage must respect the generated maze as solid
-- cover. The hit-feedback module asks the same predicate before playing its cue,
-- so a blocked shot cannot produce a false confirmation beep or hit stun.
hook.Add("EntityTakeDamage", "LOD_GeneratedGeometryBlocksPlayerBullets", function(target, dmginfo)
    if not IsValid(target) or not target.LODHostile then return end
    if Ballistics:PlayerBulletBlocked(target, dmginfo) then
        return true
    end
end)

local function installHostileLOSPatch()
    local stored = scripted_ents.GetStored("lod_hostile")
    local class = stored and stored.t
    if not class or class.LODGeneratedGeometryLOSPatched then return false end
    class.LODGeneratedGeometryLOSPatched = true

    local baseHasLineOfSight = class._HasLineOfSight
    function class:_HasLineOfSight(target)
        if not IsValid(target) then return false end

        local startPos = self:WorldSpaceCenter() + Vector(0, 0, 12)
        local endPos = target:WorldSpaceCenter()
        local blocked = Ballistics:SegmentBlocked(startPos, endPos, self, target)
        if blocked then return false end

        return baseHasLineOfSight and baseHasLineOfSight(self, target) or true
    end
    return true
end

installHostileLOSPatch()
hook.Add("OnEntityCreated", "LOD_GeneratedGeometryLOSInstall", function(ent)
    if IsValid(ent) and ent:GetClass() == "lod_hostile" then installHostileLOSPatch() end
end)

concommand.Add("lod_m3_cover_probe", function(ply)
    local cv = GetConVar("lod_developer_mode")
    if cv and not cv:GetBool() then return end
    if not IsValid(ply) then return end

    local tr = ply:GetEyeTrace()
    local target = IsValid(tr.Entity) and tr.Entity or nil
    local endPos = target and target:WorldSpaceCenter() or tr.HitPos
    local blocked, coverTrace = Ballistics:SegmentBlocked(ply:GetShootPos(), endPos, ply, target)
    print(string.format("[LOD:COVER-PROBE] blocked=%s hit=%s fraction=%.3f",
        tostring(blocked),
        coverTrace and IsValid(coverTrace.Entity) and coverTrace.Entity:GetClass() or (coverTrace and coverTrace.HitWorld and "world" or "none"),
        coverTrace and coverTrace.Fraction or 1))
end)
