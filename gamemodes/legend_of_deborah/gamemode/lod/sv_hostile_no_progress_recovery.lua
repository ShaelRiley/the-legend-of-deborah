LOD = LOD or {}
LOD.HostileNoProgressRecovery = LOD.HostileNoProgressRecovery or {}

local Recovery = LOD.HostileNoProgressRecovery
local CHECK_INTERVAL = 0.25
local STALL_SECONDS = 1.10
local MIN_PROGRESS_2D = 8
local RECOVERY_COOLDOWN = 1.25
local nextCheck = 0

local function currentWaypoint(hostile)
    local waypoints = hostile.LODWaypoints or {}
    return waypoints[hostile.LODWaypointIndex or 1]
end

local function intentionalStationary(hostile)
    if hostile.LODDead or hostile.LODActivated == false then return true end
    if hostile.LODHitStunnedUntil and CurTime() < hostile.LODHitStunnedUntil then return true end
    if hostile.LODSoldierBurst then return true end
    if hostile.LODBioBlastState or hostile.LODBioBlasterState then return true end
    if hostile.LODDeadcrabState == "leaping"
        or hostile.LODDeadcrabState == "latched"
        or hostile.LODDeadcrabState == "detonated"
    then
        return true
    end

    local waypoint = currentWaypoint(hostile)
    if waypoint and waypoint.stair then return true end

    local target = hostile.LODTarget
    local cfg = hostile.LODConfig or {}
    if IsValid(target) and (cfg.meleeRange or 0) > 0 then
        local stopRange = (cfg.meleeRange or 0) + 18
        if hostile:GetPos():DistToSqr(target:GetPos()) <= stopRange * stopRange then
            return true
        end
    end
    return false
end

local function shouldBeMoving(hostile)
    if not IsValid(hostile) or not hostile.LODHostile or intentionalStationary(hostile) then return false end
    if currentWaypoint(hostile) then return true end
    if IsValid(hostile.LODTarget) then return true end
    return false
end

local function dist2D(a, b)
    local dx = a.x - b.x
    local dy = a.y - b.y
    return math.sqrt(dx * dx + dy * dy)
end

local function recover(hostile)
    if not IsValid(hostile) or hostile.LODDead then return end

    -- Never choose a guessed graph coordinate or force a Z value. Source owns
    -- ground settlement. Re-drop in place, clear native stuck state, and rebuild
    -- the existing authoritative route from the entity's real current location.
    hostile:DropToFloor()
    if hostile.loco then hostile.loco:ClearStuck() end
    hostile.LODNextRouteRefresh = 0
    hostile.LODNextTargetRefresh = 0
    hostile.LODNoProgressRecoveries = (hostile.LODNoProgressRecoveries or 0) + 1
    hostile.LODNoProgressRecoveryUntil = CurTime() + RECOVERY_COOLDOWN

    print(string.format(
        "[LOD:NO-PROGRESS] #%d %s recovered in place count=%d",
        hostile:EntIndex(), tostring(hostile.LODArchetypeId),
        hostile.LODNoProgressRecoveries
    ))
end

hook.Add("Think", "LOD_HostileNoProgressRecovery", function()
    local now = CurTime()
    if now < nextCheck then return end
    nextCheck = now + CHECK_INTERVAL

    for _, hostile in ipairs(ents.FindByClass("lod_hostile")) do
        if shouldBeMoving(hostile) then
            local pos = hostile:GetPos()
            local sample = hostile.LODProgressSamplePos
            local sampleTime = hostile.LODProgressSampleTime or now

            if not sample then
                hostile.LODProgressSamplePos = pos
                hostile.LODProgressSampleTime = now
            elseif dist2D(pos, sample) >= MIN_PROGRESS_2D then
                hostile.LODProgressSamplePos = pos
                hostile.LODProgressSampleTime = now
            elseif now - sampleTime >= STALL_SECONDS
                and now >= (hostile.LODNoProgressRecoveryUntil or 0)
            then
                recover(hostile)
                hostile.LODProgressSamplePos = hostile:GetPos()
                hostile.LODProgressSampleTime = now
            end
        else
            hostile.LODProgressSamplePos = nil
            hostile.LODProgressSampleTime = nil
        end
    end
end)

concommand.Add("lod_m3_no_progress_status", function(ply)
    local cv = GetConVar("lod_developer_mode")
    if cv and not cv:GetBool() then return end
    if IsValid(ply) and not ply:IsAdmin() then return end

    for _, hostile in ipairs(ents.FindByClass("lod_hostile")) do
        if IsValid(hostile) and hostile.LODHostile then
            print(string.format(
                "[LOD:NO-PROGRESS-STATUS] #%d %s recoveries=%d movingExpected=%s waypoint=%s",
                hostile:EntIndex(), tostring(hostile.LODArchetypeId),
                hostile.LODNoProgressRecoveries or 0,
                tostring(shouldBeMoving(hostile)),
                tostring(currentWaypoint(hostile) ~= nil)
            ))
        end
    end
end)
