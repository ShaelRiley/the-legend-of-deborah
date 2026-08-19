LOD = LOD or {}
LOD.HostileStairRecovery = LOD.HostileStairRecovery or {}

local Recovery = LOD.HostileStairRecovery

local CHECK_INTERVAL = 0.10
local STUCK_SECONDS = 0.70
local MIN_PROGRESS = 5
local RECOVERY_COOLDOWN = 1.00

local function currentStairContext(hostile)
    local waypoints = hostile.LODWaypoints or {}
    local index = hostile.LODWaypointIndex or 1
    local current = waypoints[index]
    if current and current.stair and current.pos then
        return current, "current", current.pos, "current:" .. tostring(index)
    end

    -- At the crest, _AdvanceWaypoint can promote the route to the first ordinary
    -- cell waypoint while the physical hull is still only a few units beyond the
    -- final stair landing. Keep the just-completed stair landing as a short
    -- recovery anchor, but measure successful progress toward the CURRENT route
    -- target rather than toward the old landing.
    local previous = waypoints[index - 1]
    if previous and previous.stair and previous.pos
        and hostile:GetPos():DistToSqr(previous.pos) <= (112 * 112)
    then
        local progressTarget = current and current.pos or previous.pos
        return previous, "crest", progressTarget, "crest:" .. tostring(index)
    end

    return nil, nil, nil, nil
end

local function intentionallyStationary(hostile)
    if hostile.LODDead or hostile.LODActivated == false then return true end
    if CurTime() < (hostile.LODHitStunUntil or 0) then return true end
    if hostile.LODSoldierBurst or hostile.LODBioBlast then return true end
    if hostile.LODDeadcrabState == "latched" or hostile.LODDeadcrabState == "leaping" then return true end

    local target = hostile.LODTarget
    local cfg = hostile.LODConfig
    if IsValid(target) and cfg and (cfg.meleeRange or 0) > 0 then
        local range = cfg.meleeRange
        if hostile:GetPos():DistToSqr(target:GetPos()) <= range * range then return true end
    end

    return false
end

local function ignoredTraceEntities(hostile)
    local ignored = {hostile}
    for _, other in ipairs(ents.FindByClass("lod_hostile")) do
        if IsValid(other) and other ~= hostile then ignored[#ignored + 1] = other end
    end
    return ignored
end

local function safeRecoveryPosition(hostile, anchor)
    if not anchor or not anchor.pos then return nil end
    local mins, maxs = hostile:GetCollisionBounds()
    if not mins or not maxs then return nil end
    local ignored = ignoredTraceEntities(hostile)

    -- Exact stair waypoints are centered over validated tread/landing geometry.
    -- Try a few tiny vertical clearances to avoid treating floor contact itself
    -- as an obstruction. Never displace laterally away from the proven centerline.
    for _, lift in ipairs({4, 8, 12, 16}) do
        local candidate = anchor.pos + Vector(0, 0, lift)
        local tr = util.TraceHull({
            start = candidate,
            endpos = candidate,
            mins = mins,
            maxs = maxs,
            mask = MASK_NPCSOLID,
            filter = ignored
        })
        if not tr.StartSolid and not tr.AllSolid then return candidate end
    end

    return nil
end

function Recovery:Recover(hostile, anchor, context)
    if not IsValid(hostile) or not anchor then return false end
    if CurTime() < (hostile.LODNextStairRecovery or 0) then return false end

    local candidate = safeRecoveryPosition(hostile, anchor)
    if not candidate then return false end

    hostile:SetPos(candidate)
    hostile:SetVelocity(vector_origin)
    if hostile.loco then
        if hostile.loco.SetVelocity then hostile.loco:SetVelocity(vector_origin) end
        hostile.loco:ClearStuck()
        if hostile.LODConfig then hostile.loco:SetDesiredSpeed(hostile.LODConfig.speed or 90) end
    end

    hostile.LODNextStairRecovery = CurTime() + RECOVERY_COOLDOWN
    hostile.LODStairRecoveryCount = (hostile.LODStairRecoveryCount or 0) + 1
    hostile.LODStairRecoveryLastTime = CurTime()
    hostile.LODStairProgressBest = nil
    hostile.LODStairProgressTime = CurTime()

    print(string.format("[LOD:STAIR-RECOVERY] #%d %s context=%s count=%d",
        hostile:EntIndex(), tostring(hostile.LODArchetypeId), tostring(context),
        hostile.LODStairRecoveryCount))
    return true
end

hook.Add("Think", "LOD_HostileStairSelfRecovery", function()
    local now = CurTime()
    if now < (Recovery.NextCheck or 0) then return end
    Recovery.NextCheck = now + CHECK_INTERVAL

    for _, hostile in ipairs(ents.FindByClass("lod_hostile")) do
        if IsValid(hostile) and hostile.LODHostile and not intentionallyStationary(hostile) then
            local anchor, context, progressTarget, progressKey = currentStairContext(hostile)
            if anchor and progressTarget then
                if hostile.LODStairProgressKey ~= progressKey then
                    hostile.LODStairProgressKey = progressKey
                    hostile.LODStairProgressBest = hostile:GetPos():Distance(progressTarget)
                    hostile.LODStairProgressTime = now
                else
                    local distance = hostile:GetPos():Distance(progressTarget)
                    local best = hostile.LODStairProgressBest

                    if not best or distance <= best - MIN_PROGRESS then
                        hostile.LODStairProgressBest = distance
                        hostile.LODStairProgressTime = now
                    elseif now - (hostile.LODStairProgressTime or now) >= STUCK_SECONDS then
                        if Recovery:Recover(hostile, anchor, context) then
                            hostile.LODStairProgressKey = nil
                        end
                    end
                end
            else
                hostile.LODStairProgressKey = nil
                hostile.LODStairProgressBest = nil
                hostile.LODStairProgressTime = nil
            end
        end
    end
end)

concommand.Add("lod_m3_stair_recovery_status", function(ply)
    local cv = GetConVar("lod_developer_mode")
    if cv and not cv:GetBool() then return end
    if IsValid(ply) and not ply:IsAdmin() then return end

    local found = 0
    for _, hostile in ipairs(ents.FindByClass("lod_hostile")) do
        if IsValid(hostile) and hostile.LODHostile then
            found = found + 1
            local _, context = currentStairContext(hostile)
            local text = string.format("#%d %s size=%.3f stairContext=%s recoveryCount=%d",
                hostile:EntIndex(), tostring(hostile.LODArchetypeId),
                hostile:GetNW2Float("LOD_SizeScale", 1), tostring(context or "none"),
                hostile.LODStairRecoveryCount or 0)
            print("[LOD:STAIR-RECOVERY] " .. text)
            if IsValid(ply) then ply:ChatPrint(text) end
        end
    end
    if found == 0 then
        print("[LOD:STAIR-RECOVERY] no live hostiles")
        if IsValid(ply) then ply:ChatPrint("no live hostiles") end
    end
end)
