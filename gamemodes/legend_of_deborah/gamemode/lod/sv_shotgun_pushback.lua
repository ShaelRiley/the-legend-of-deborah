LOD = LOD or {}

local HitFeedback = LOD.M3HitFeedback
local Motion = LOD.HostileMotionV2
local Navigator = LOD.MazeNavigator
if not HitFeedback or not Motion or not Navigator then return end

local PUSH_DISTANCE = 42

local function shooterFor(hostile)
    local stamp = IsValid(hostile) and hostile.LODLastHitFeedbackEvent or nil
    local attacker = stamp and stamp.attacker or nil
    return IsValid(attacker) and attacker:IsPlayer() and attacker or nil
end

local function pushWithinCurrentCell(hostile, attacker)
    if not IsValid(hostile) or hostile.LODDead or not IsValid(attacker) then return 0 end
    if hostile.LODDeadcrabState == "latched" then return 0 end

    local run = LOD.RunManager
    local graph = run and run.State and run.State.Graph
    if not graph then return 0 end

    local cell = Navigator:WorldToCell(graph, hostile:GetPos())
    if not cell then return 0 end

    local startPos = hostile:GetPos()
    local away = startPos - attacker:GetPos()
    away.z = 0
    if away:LengthSqr() <= 0.01 then
        away = attacker:GetAimVector()
        away.z = 0
    end
    if away:LengthSqr() <= 0.01 then return 0 end
    away:Normalize()

    -- Shotgun knockback is intentionally not Source physics. Motion V2 remains
    -- the only physical authority: move the hostile a modest distance away from
    -- the shooter, then clamp the destination to the guaranteed interior of its
    -- current canonical cell. This prevents knockback from crossing a closed wall,
    -- gate, or unauthored elevation transition.
    local desired = startPos + away * PUSH_DISTANCE
    local destination = Motion:CellFloorPoint(cell, desired)
    local moved = destination - startPos
    moved.z = 0
    local distance = moved:Length()
    if distance <= 0.05 then return 0 end

    local yaw = hostile:GetAngles().y
    hostile:SetPos(destination)
    hostile:SetAngles(Angle(0, yaw, 0))
    hostile.LODMotionLastPos = destination
    hostile.LODMotionLastUpdate = CurTime()
    hostile.LODMotionVelocity = vector_origin
    hostile.LODMotionSpeed = 0
    hostile.LODMotionMode = "shotgun-push"
    hostile.LODNextRouteRefresh = 0
    hostile.LODNextTargetRefresh = 0
    hostile.LODLastShotgunPush = {
        distance = distance,
        at = CurTime(),
        attacker = attacker
    }
    return distance
end

if not HitFeedback.LODShotgunPushbackWrapped then
    HitFeedback.LODShotgunPushbackWrapped = true
    local baseApplyShotgunShellStun = HitFeedback.ApplyShotgunShellStun

    function HitFeedback:ApplyShotgunShellStun(hostile)
        -- Preserve the accepted one-stun-per-shell contract. Pushback only occurs
        -- if that same shell-level stun was accepted, so nine pellets can never
        -- become nine movement impulses and the existing 0.66 s retrigger guard
        -- also bounds repeated knockback.
        local applied = baseApplyShotgunShellStun(self, hostile)
        if not applied then return false end

        local attacker = shooterFor(hostile)
        pushWithinCurrentCell(hostile, attacker)
        return true
    end
end

concommand.Add("lod_shotgun_push_status", function(ply)
    local cv = GetConVar("lod_developer_mode")
    if cv and not cv:GetBool() then return end
    if IsValid(ply) and not ply:IsAdmin() then return end

    local recent = 0
    local maxDistance = 0
    for _, hostile in ipairs(ents.FindByClass("lod_hostile")) do
        local push = IsValid(hostile) and hostile.LODLastShotgunPush or nil
        if push and CurTime() - (push.at or 0) <= 10 then
            recent = recent + 1
            maxDistance = math.max(maxDistance, push.distance or 0)
        end
    end

    local line = string.format("recent=%d maxPush=%.1f nominal=%d cellClamped=true",
        recent, maxDistance, PUSH_DISTANCE)
    print("[LOD:SHOTGUN-PUSH] " .. line)
    if IsValid(ply) then ply:ChatPrint(line) end
end)
