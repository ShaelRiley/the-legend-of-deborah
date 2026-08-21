LOD = LOD or {}

-- Source studio hitboxes become unreliable at the extreme low end of our
-- 0.33x-1.33x hostile model scaling. Keep ordinary engine hit detection first,
-- then provide a conservative torso-volume fallback for player hitscan weapons.
-- The fallback never shoots through world geometry because it only considers
-- the already-traced segment up to the engine's original impact point.

local FIREARMS = {
    weapon_pistol = true,
    weapon_357 = true,
    weapon_smg1 = true,
    weapon_shotgun = true,
    weapon_ar2 = true
}

local function qualifyingShooter(ent)
    if not IsValid(ent) or not ent:IsPlayer() or not ent:Alive() then return false end
    local weapon = ent:GetActiveWeapon()
    return IsValid(weapon) and FIREARMS[weapon:GetClass()] == true
end

local function axisValue(v, axis)
    if axis == 1 then return v.x end
    if axis == 2 then return v.y end
    return v.z
end

local function segmentAABB(startPos, endPos, mins, maxs)
    local delta = endPos - startPos
    local tMin, tMax = 0, 1

    for axis = 1, 3 do
        local s = axisValue(startPos, axis)
        local d = axisValue(delta, axis)
        local mn = axisValue(mins, axis)
        local mx = axisValue(maxs, axis)

        if math.abs(d) < 0.0001 then
            if s < mn or s > mx then return nil end
        else
            local inv = 1 / d
            local t1 = (mn - s) * inv
            local t2 = (mx - s) * inv
            if t1 > t2 then t1, t2 = t2, t1 end
            tMin = math.max(tMin, t1)
            tMax = math.min(tMax, t2)
            if tMin > tMax then return nil end
        end
    end

    return tMin, startPos + delta * tMin
end

local function combatBounds(hostile)
    local size = math.Clamp(hostile:GetNW2Float("LOD_SizeScale", 1), 0.33, 1.33)
    local origin = hostile:GetPos()

    -- At normal size this is slightly narrower than the locomotion box and
    -- roughly matches the torso. At very small visual scales, minimum width and
    -- height prevent an apparently centered shot from threading through scaled
    -- studio-hitbox gaps. Larger enemies continue growing proportionally.
    local halfWidth = math.max(8, 14 * size)
    local height = math.max(24, 72 * size)
    return origin + Vector(-halfWidth, -halfWidth, 0),
        origin + Vector(halfWidth, halfWidth, height)
end

local function forwardedDamage(source, attacker, hitPos)
    local out = DamageInfo()
    out:SetAttacker(IsValid(source:GetAttacker()) and source:GetAttacker() or attacker)
    out:SetInflictor(IsValid(source:GetInflictor()) and source:GetInflictor() or attacker)
    out:SetDamage(math.max(0, source:GetDamage()))
    out:SetDamageType(source:GetDamageType())
    out:SetDamageForce(source:GetDamageForce())
    out:SetDamagePosition(hitPos)
    return out
end

hook.Add("EntityFireBullets", "LOD_ScaledHostileCombatHull", function(shooter, bullet)
    if not qualifyingShooter(shooter) then return end

    local previousCallback = bullet.Callback
    bullet.Callback = function(attacker, tr, dmginfo)
        if previousCallback then previousCallback(attacker, tr, dmginfo) end
        if not qualifyingShooter(attacker) then return end
        if not dmginfo or dmginfo:GetDamage() <= 0 then return end

        -- If Source already hit an LOD hostile, preserve the engine result.
        if IsValid(tr.Entity) and tr.Entity.LODHostile then return end

        local startPos = tr.StartPos or bullet.Src or attacker:GetShootPos()
        local endPos = tr.HitPos
        if not startPos or not endPos then return end

        local best, bestT, bestPos

        -- Broad-phase only against entities overlapping the traced shot
        -- segment. The small asymmetric sweep covers the maximum difference
        -- between an LOD hostile's fixed collision bounds and its 1.33x
        -- fallback combat volume. The exact AABB test below remains
        -- authoritative, so nearby entities cannot become false hits.
        local candidates = ents.FindAlongRay(
            startPos,
            endPos,
            Vector(-4, -4, -24),
            Vector(4, 4, 0)
        )
        for _, hostile in ipairs(candidates) do
            if IsValid(hostile) and hostile.LODHostile and not hostile.LODDead then
                local mins, maxs = combatBounds(hostile)
                local t, hitPos = segmentAABB(startPos, endPos, mins, maxs)
                if t and (not bestT or t < bestT) then
                    best, bestT, bestPos = hostile, t, hitPos
                end
            end
        end

        if not IsValid(best) then return end

        -- The fallback target lies before the engine's original impact, so the
        -- bullet should terminate on the hostile rather than damage an object
        -- behind it. World impacts are unaffected by setting DamageInfo to zero.
        local redirected = forwardedDamage(dmginfo, attacker, bestPos)
        dmginfo:SetDamage(0)
        best:TakeDamageInfo(redirected)
    end
end)
