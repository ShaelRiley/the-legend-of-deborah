LOD = LOD or {}
LOD.Seeker = LOD.Seeker or {}

local Seeker = LOD.Seeker
local EC = LOD.Config and LOD.Config.Encounter
local Navigator = LOD.MazeNavigator
local Motion = LOD.HostileMotionV2
local WanderingDirector = LOD.WanderingDirector
local EncounterDirector = LOD.EncounterDirector
local Rolls = LOD.CombatRolls
local cellKey = LOD.MazeGenerator and LOD.MazeGenerator.CellKey

if not EC or not Navigator or not Motion or not cellKey then return end

local SERVICE_NAME = "LOD_SeekerChargeService"
local SERVICE_INTERVAL = 0.05
local WINDUP_SECONDS = 0.85
local CHARGE_SPEED = 560
local CHARGE_SECONDS = 1.20
local CHARGE_RANGE = 760
local MIN_CHARGE_RANGE = 150
local READY_STANDOFF_DISTANCE = 300
local RETREAT_TARGET_DISTANCE = 320
local RETREAT_SEARCH_DEPTH = 3
local CHARGE_COOLDOWN = 2.80
local IMPACT_STUN_SECONDS = 1.10
local PLAYER_CONTACT_DISTANCE = 58
local IMPACT_FX_SECONDS = 0.28
local WANDER_WEIGHT = 4
local SEEKER_HEALTH_PROFILE = {count = 3, sides = 4, bonus = 3}
local SEEKER_DAMAGE_PROFILE = {
    label = "SEEKER",
    source = "charge",
    count = 2,
    sides = 6,
    bonus = 4,
    reference = 11
}

util.AddNetworkString("LOD_SeekerState")

EC.Archetypes.seeker = EC.Archetypes.seeker or {
    class = "lod_hostile_seeker",
    name = "Seeker",
    model = "models/roller.mdl",
    baseHP = 18,
    speed = 165,
    meleeDamage = 0,
    meleeCooldown = 99,
    meleeRange = 0,
    threat = 1.9,
    activity = ACT_IDLE
}

EC.Templates.incoming = EC.Templates.incoming or {
    name = "Incoming",
    composition = {seeker = 1, shambler = 1}
}

if WanderingDirector and WanderingDirector.Config and WanderingDirector.Config.ArchetypeWeights then
    WanderingDirector.Config.ArchetypeWeights.seeker = WANDER_WEIGHT
end

Seeker.Stats = Seeker.Stats or {}
Seeker.Stats.windups = Seeker.Stats.windups or 0
Seeker.Stats.charges = Seeker.Stats.charges or 0
Seeker.Stats.playerHits = Seeker.Stats.playerHits or 0
Seeker.Stats.wallImpacts = Seeker.Stats.wallImpacts or 0
Seeker.Stats.impactStuns = Seeker.Stats.impactStuns or 0
Seeker.Stats.testSpawns = Seeker.Stats.testSpawns or 0
Seeker.Stats.serviceTicks = Seeker.Stats.serviceTicks or 0
Seeker.Stats.retreatStarts = Seeker.Stats.retreatStarts or 0
Seeker.Stats.retreatCompletes = Seeker.Stats.retreatCompletes or 0
Seeker.Stats.postHitRetreats = Seeker.Stats.postHitRetreats or 0
Seeker.Stats.closeRangeRetreats = Seeker.Stats.closeRangeRetreats or 0
Seeker.Stats.blockedRetreats = Seeker.Stats.blockedRetreats or 0
Seeker.TestEntities = Seeker.TestEntities or {}

local function keyOf(cell)
    return cell and cellKey(cell.x, cell.y, cell.z) or nil
end

local function currentState()
    local state = LOD.RunManager and LOD.RunManager.State
    return state, state and state.Graph or nil
end

local function safeCell(graph, cell)
    local tag = graph and graph.CellTags and graph.CellTags[keyOf(cell)]
    return tag and (tag.safe == true or tag.role == "boss") or false
end

local function livingPlayer(ply)
    if not IsValid(ply) or not ply:IsPlayer() or not ply:Alive() then return false end
    if LOD.RunManager and LOD.RunManager.IsActivePlayer then
        return LOD.RunManager:IsActivePlayer(ply)
    end
    return true
end

local function targetEligible(seeker, graph, target)
    if not livingPlayer(target) then return false end
    local from = Navigator:WorldToCell(graph, seeker:GetPos())
    local to = Navigator:WorldToCell(graph, target:GetPos())
    if not from or not to or from.z ~= to.z then return false end
    if safeCell(graph, to) then return false end
    return true
end

local function horizontalDistanceSqr(a, b)
    if not a or not b then return math.huge end
    local dx = a.x - b.x
    local dy = a.y - b.y
    return dx * dx + dy * dy
end

local function horizontalDistance(a, b)
    return math.sqrt(horizontalDistanceSqr(a, b))
end

local function traceFilter(seeker, target)
    return function(ent)
        if ent == seeker then return false end
        if IsValid(ent) and ent.LODHostile then return false end
        if IsValid(ent) and target and (ent:GetOwner() == target or ent:GetParent() == target) then return false end
        return true
    end
end

local function lineGraphClear(seeker, graph, target)
    if not targetEligible(seeker, graph, target) then return false end

    local startPos = seeker:GetPos() + Vector(0, 0, 14)
    local endPos = target:WorldSpaceCenter()
    local delta = endPos - startPos
    delta.z = 0
    local distance = delta:Length()
    if distance < MIN_CHARGE_RANGE or distance > CHARGE_RANGE then return false end

    local tr = util.TraceHull({
        start = startPos,
        endpos = Vector(endPos.x, endPos.y, startPos.z),
        mins = Vector(-12, -12, -12),
        maxs = Vector(12, 12, 12),
        mask = MASK_SHOT,
        filter = traceFilter(seeker, target)
    })
    if tr.Hit and tr.Entity ~= target then return false end

    local steps = math.max(1, math.ceil(distance / 48))
    local previous = Navigator:WorldToCell(graph, seeker:GetPos())
    if not previous then return false end
    local previousKey = keyOf(previous)

    for i = 1, steps do
        local t = i / steps
        local point = seeker:GetPos() + delta * t
        local cell = Navigator:WorldToCell(graph, point)
        if not cell or cell.z ~= previous.z then return false end
        local k = keyOf(cell)
        if k ~= previousKey then
            if not Navigator:CanTraverse(graph, previousKey, k) then return false end
            previous = cell
            previousKey = k
        end
    end

    return true
end

local function sendState(seeker, phase, duration)
    if not IsValid(seeker) then return end
    net.Start("LOD_SeekerState")
    net.WriteEntity(seeker)
    net.WriteUInt(math.Clamp(phase or 0, 0, 3), 2)
    net.WriteFloat(math.max(0, duration or 0))
    net.Broadcast()
end

local function emitOneShot(seeker, path, level, pitch, volume, channel)
    if not IsValid(seeker) or not path then return end
    seeker:EmitSound(path, level or 72, pitch or 100, volume or 0.9, channel or CHAN_ITEM)
end

local function stopLegacyLoop(seeker)
    if not IsValid(seeker) then return end
    seeker:StopSound("npc/roller/mine/rmine_seek_loop2.wav")
    seeker:StopSound("npc/roller/mine/rmine_seek_loop1.wav")
end

local function restoreTargetAfterSpecial(seeker, target)
    if not IsValid(seeker) then return end
    if livingPlayer(target) then
        seeker.LODTarget = target
        seeker.LODReturningHome = false
        seeker.LODNextTargetRefresh = CurTime() + 0.20
        seeker.LODNextRouteRefresh = 0
    else
        seeker.LODTarget = nil
        seeker.LODNextTargetRefresh = 0
        seeker.LODNextRouteRefresh = 0
    end
end

local function clearSpecialState(seeker, cooldown, fxTail, restoreTarget)
    if not IsValid(seeker) then return nil end
    local state = seeker.LODSeekerState
    local target = state and state.target
    seeker.LODSeekerState = nil
    seeker.LODNextSeekerCharge = CurTime() + (cooldown or CHARGE_COOLDOWN)
    seeker.LODMotionMode = "ground"
    stopLegacyLoop(seeker)
    if restoreTarget ~= false then restoreTargetAfterSpecial(seeker, target) end

    local tail = math.max(0, tonumber(fxTail) or 0)
    if tail <= 0 then
        sendState(seeker, 0, 0)
    else
        timer.Simple(tail, function()
            if IsValid(seeker) and not seeker.LODSeekerState then sendState(seeker, 0, 0) end
        end)
    end
    return target
end

local function beginWindup(seeker, graph, target)
    if seeker.LODSeekerState or seeker.LODSeekerRetreat
        or CurTime() < (seeker.LODNextSeekerCharge or 0)
    then
        return false
    end
    if horizontalDistance(seeker:GetPos(), target:GetPos()) < MIN_CHARGE_RANGE then return false end
    if not lineGraphClear(seeker, graph, target) then return false end

    local origin = seeker:GetPos()
    local aim = target:GetPos()
    local direction = Vector(aim.x - origin.x, aim.y - origin.y, 0)
    if direction:LengthSqr() <= 0.01 then return false end
    direction:Normalize()

    seeker.LODSeekerState = {
        phase = "windup",
        target = target,
        direction = direction,
        aimPos = aim,
        releasesAt = CurTime() + WINDUP_SECONDS,
        distance = 0
    }
    seeker.LODTarget = nil
    seeker.LODWaypoints = {}
    seeker.LODWaypointIndex = 1
    seeker.LODNextRouteRefresh = CurTime() + WINDUP_SECONDS + CHARGE_SECONDS
    seeker.LODNextTargetRefresh = CurTime() + WINDUP_SECONDS + CHARGE_SECONDS
    Motion:Stop(seeker)
    Motion:FaceToward(seeker, aim)
    Seeker.Stats.windups = (Seeker.Stats.windups or 0) + 1
    sendState(seeker, 1, WINDUP_SECONDS)

    emitOneShot(seeker, "buttons/button17.wav", 78, 132, 0.95, CHAN_ITEM)
    local stateRef = seeker.LODSeekerState
    timer.Simple(WINDUP_SECONDS * 0.55, function()
        if IsValid(seeker) and seeker.LODSeekerState == stateRef and stateRef.phase == "windup" then
            emitOneShot(seeker, "ambient/energy/zap1.wav", 76, 122, 0.82, CHAN_WEAPON)
        end
    end)
    return true
end

local function beginCharge(seeker)
    local state = seeker.LODSeekerState
    if not state or state.phase ~= "windup" then return false end
    state.phase = "charge"
    state.endsAt = CurTime() + CHARGE_SECONDS
    state.distance = 0
    Seeker.Stats.charges = (Seeker.Stats.charges or 0) + 1
    sendState(seeker, 2, CHARGE_SECONDS)
    stopLegacyLoop(seeker)
    emitOneShot(seeker, "ambient/energy/zap5.wav", 82, 108, 0.95, CHAN_WEAPON)
    return true
end

local function impactEffect(seeker, hitPos, wall)
    if not IsValid(seeker) then return end
    sendState(seeker, 3, IMPACT_FX_SECONDS)
    if wall then
        emitOneShot(seeker, "physics/metal/metal_solid_impact_hard3.wav", 80, 94, 0.95, CHAN_BODY)
    else
        emitOneShot(seeker, "ambient/energy/zap9.wav", 80, 104, 0.92, CHAN_WEAPON)
    end

    local effect = EffectData()
    effect:SetOrigin(hitPos or seeker:WorldSpaceCenter())
    effect:SetMagnitude(1)
    effect:SetScale(1.2)
    util.Effect("StunstickImpact", effect, true, true)
end

local function damagePlayer(seeker, target)
    if not livingPlayer(target) then return false end
    local size = math.Clamp(seeker:GetNW2Float("LOD_SizeScale", 1), 0.33, 1.33)
    local contract = Rolls and Rolls:RollHostileAttack(seeker, SEEKER_DAMAGE_PROFILE,
        SEEKER_DAMAGE_PROFILE.reference * size) or nil
    local amount = contract and contract.final
        or math.max(1, math.floor(SEEKER_DAMAGE_PROFILE.reference * size + 0.5))

    local info = DamageInfo()
    info:SetAttacker(seeker)
    info:SetInflictor(seeker)
    info:SetDamage(amount)
    info:SetDamageType(DMG_CLUB)
    info:SetDamagePosition(target:WorldSpaceCenter())
    target:TakeDamageInfo(info)

    if contract and Rolls and Rolls._Send and Rolls._HostileRollText then
        Rolls:_Send(target, 1, Rolls:_HostileRollText(contract, seeker, target))
    end

    Seeker.Stats.playerHits = (Seeker.Stats.playerHits or 0) + 1
    return true
end

-- Compile one immutable escape route at retreat start. The live player can keep
-- moving while it executes, but the Seeker never flips between candidate cells
-- every service tick. That makes range recovery read as one deliberate motion
-- rather than two planners tugging the Rollermine back and forth.
local function buildRetreatWaypoints(seeker, graph, anchorPos)
    local startCell = Navigator:WorldToCell(graph, seeker:GetPos())
    local anchorCell = Navigator:WorldToCell(graph, anchorPos)
    if not startCell or not anchorCell or startCell.z ~= anchorCell.z then return nil, 0 end

    local startKey = keyOf(startCell)
    local queue = {{key = startKey, depth = 0}}
    local head = 1
    local seen = {[startKey] = true}
    local previous = {}
    local bestKey = startKey
    local bestDistance = horizontalDistance(Navigator:CellCenter(startCell), anchorPos)
    local bestAtOrBeyond = bestDistance >= RETREAT_TARGET_DISTANCE

    while head <= #queue do
        local item = queue[head]
        head = head + 1
        local cell = graph.Cells[item.key]
        if cell then
            local centerDistance = horizontalDistance(Navigator:CellCenter(cell), anchorPos)
            local atOrBeyond = centerDistance >= RETREAT_TARGET_DISTANCE
            local better = false

            if atOrBeyond and not bestAtOrBeyond then
                better = true
            elseif atOrBeyond and bestAtOrBeyond then
                better = math.abs(centerDistance - RETREAT_TARGET_DISTANCE)
                    < math.abs(bestDistance - RETREAT_TARGET_DISTANCE)
            elseif not bestAtOrBeyond and centerDistance > bestDistance then
                better = true
            end

            if better and not safeCell(graph, cell) then
                bestKey = item.key
                bestDistance = centerDistance
                bestAtOrBeyond = atOrBeyond
            end

            if item.depth < RETREAT_SEARCH_DEPTH then
                local neighborKeys = {}
                for neighborKey in pairs(cell.neighbors or {}) do neighborKeys[#neighborKeys + 1] = neighborKey end
                table.sort(neighborKeys)
                for _, neighborKey in ipairs(neighborKeys) do
                    local neighbor = graph.Cells[neighborKey]
                    if neighbor and neighbor.z == startCell.z and not seen[neighborKey]
                        and not safeCell(graph, neighbor)
                        and Navigator:CanTraverse(graph, item.key, neighborKey)
                    then
                        seen[neighborKey] = true
                        previous[neighborKey] = item.key
                        queue[#queue + 1] = {key = neighborKey, depth = item.depth + 1}
                    end
                end
            end
        end
    end

    if bestKey ~= startKey then
        local reverse = {bestKey}
        local cursor = bestKey
        while cursor ~= startKey do
            cursor = previous[cursor]
            if not cursor then break end
            reverse[#reverse + 1] = cursor
        end
        if cursor == startKey then
            local path = {}
            for i = #reverse, 1, -1 do path[#path + 1] = graph.Cells[reverse[i]] end
            local waypoints = Navigator:PathToWaypoints(graph, path)
            if #waypoints > 0 then return waypoints, bestDistance end
        end
    end

    -- If topology offers no better neighboring cell, take one committed step
    -- inside the current authoritative cell. This cannot cross a wall or gate.
    local seekerPos = seeker:GetPos()
    local away = Vector(seekerPos.x - anchorPos.x, seekerPos.y - anchorPos.y, 0)
    if away:LengthSqr() <= 0.01 then away = seeker:GetForward() * -1 end
    away:Normalize()
    local localGoal = Motion:CellFloorPoint(startCell, seekerPos + away * RETREAT_TARGET_DISTANCE)
    if localGoal and horizontalDistance(localGoal, anchorPos) > horizontalDistance(seekerPos, anchorPos) + 8 then
        return {{pos = localGoal, tolerance = 12, stair = false, seekerRetreat = true}},
            horizontalDistance(localGoal, anchorPos)
    end

    return {}, bestDistance
end

local function beginRetreat(seeker, graph, target, reason)
    if not IsValid(seeker) or not targetEligible(seeker, graph, target) then return false end
    if seeker.LODSeekerState then return false end

    local existing = seeker.LODSeekerRetreat
    if existing and existing.target == target then return true end

    local anchor = Vector(target:GetPos().x, target:GetPos().y, target:GetPos().z)
    local waypoints, plannedDistance = buildRetreatWaypoints(seeker, graph, anchor)
    local resumeChargeAt = seeker.LODNextSeekerCharge or CurTime()

    seeker.LODSeekerRetreat = {
        target = target,
        reason = reason or "range",
        anchor = anchor,
        waypoints = waypoints or {},
        index = 1,
        plannedDistance = plannedDistance or 0,
        resumeChargeAt = resumeChargeAt
    }

    -- Retreat becomes authoritative immediately in this same service tick. Freeze
    -- generic acquisition/routing until the committed escape path completes.
    seeker.LODTarget = nil
    seeker.LODWaypoints = {}
    seeker.LODWaypointIndex = 1
    seeker.LODNextRouteRefresh = math.huge
    seeker.LODNextTargetRefresh = math.huge
    seeker.LODNextSeekerCharge = math.huge

    Seeker.Stats.retreatStarts = (Seeker.Stats.retreatStarts or 0) + 1
    if #(waypoints or {}) == 0 then
        Seeker.Stats.blockedRetreats = (Seeker.Stats.blockedRetreats or 0) + 1
    end
    if reason == "post-hit" then
        Seeker.Stats.postHitRetreats = (Seeker.Stats.postHitRetreats or 0) + 1
    else
        Seeker.Stats.closeRangeRetreats = (Seeker.Stats.closeRangeRetreats or 0) + 1
    end
    return true
end

local function finishRetreat(seeker, retreat)
    if not IsValid(seeker) then return end
    retreat = retreat or seeker.LODSeekerRetreat
    local target = retreat and retreat.target
    local resumeChargeAt = retreat and retreat.resumeChargeAt or 0

    seeker.LODSeekerRetreat = nil
    seeker.LODWaypoints = {}
    seeker.LODWaypointIndex = 1
    seeker.LODTarget = nil
    seeker.LODNextTargetRefresh = 0
    seeker.LODNextRouteRefresh = 0
    seeker.LODNextSeekerCharge = math.max(resumeChargeAt, CurTime() + 0.10)
    Motion:Stop(seeker)
    restoreTargetAfterSpecial(seeker, target)
    if livingPlayer(target) then Motion:FaceToward(seeker, target:GetPos()) end
    Seeker.Stats.retreatCompletes = (Seeker.Stats.retreatCompletes or 0) + 1
end

local function cancelRetreat(seeker, retreat)
    if not IsValid(seeker) then return end
    retreat = retreat or seeker.LODSeekerRetreat
    seeker.LODSeekerRetreat = nil
    seeker.LODWaypoints = {}
    seeker.LODWaypointIndex = 1
    seeker.LODTarget = nil
    seeker.LODNextTargetRefresh = 0
    seeker.LODNextRouteRefresh = 0
    seeker.LODNextSeekerCharge = math.max(retreat and retreat.resumeChargeAt or 0, CurTime() + 0.10)
    Motion:Stop(seeker)
end

local function runRetreatStep(seeker, graph)
    local retreat = seeker.LODSeekerRetreat
    if not retreat then return false end
    local target = retreat.target
    if not targetEligible(seeker, graph, target) then
        cancelRetreat(seeker, retreat)
        return false
    end

    local distance = horizontalDistance(seeker:GetPos(), target:GetPos())
    if distance >= RETREAT_TARGET_DISTANCE then
        finishRetreat(seeker, retreat)
        return true
    end

    local waypoint = retreat.waypoints[retreat.index]
    if not waypoint then
        -- The one committed path is exhausted. If it created enough safety to
        -- satisfy the hard minimum, resume normal charge setup. If topology (or
        -- a chasing player) leaves the Seeker too close, hold instead of
        -- replanning every tick or charging point-blank.
        if distance >= MIN_CHARGE_RANGE then
            finishRetreat(seeker, retreat)
        else
            Motion:Stop(seeker)
            Motion:FaceToward(seeker, target:GetPos())
            seeker.LODMotionMode = "seeker-retreat-blocked"
        end
        return true
    end

    local reached = Motion:MoveToward(seeker, waypoint)
    seeker.LODMotionMode = "seeker-retreat-committed"
    if reached then retreat.index = retreat.index + 1 end
    return true
end

local function resolvePlayerImpact(seeker, graph, target)
    if not IsValid(seeker) or not livingPlayer(target) or not seeker.LODSeekerState then return false end
    Motion:Stop(seeker)
    damagePlayer(seeker, target)
    impactEffect(seeker, seeker:WorldSpaceCenter(), false)

    -- A successful hit transitions directly from charge to committed retreat.
    -- Do not briefly restore pursuit between those two states.
    local impactTarget = clearSpecialState(seeker, CHARGE_COOLDOWN, IMPACT_FX_SECONDS, false) or target
    if not beginRetreat(seeker, graph, impactTarget, "post-hit") then
        restoreTargetAfterSpecial(seeker, impactTarget)
    end
    return true
end

local function impactStun(seeker, hitPos)
    if not IsValid(seeker) then return end
    seeker.LODHitStunUntil = math.max(seeker.LODHitStunUntil or 0, CurTime() + IMPACT_STUN_SECONDS)
    Motion:Stop(seeker)
    seeker.LODMotionMode = "seeker-impact-stun"
    Seeker.Stats.wallImpacts = (Seeker.Stats.wallImpacts or 0) + 1
    Seeker.Stats.impactStuns = (Seeker.Stats.impactStuns or 0) + 1
    impactEffect(seeker, hitPos, true)
    clearSpecialState(seeker, CHARGE_COOLDOWN, IMPACT_FX_SECONDS)
end

local function stepGraphValid(graph, fromPos, toPos)
    local from = Navigator:WorldToCell(graph, fromPos)
    local to = Navigator:WorldToCell(graph, toPos)
    if not from or not to or from.z ~= to.z then return false end
    local a, b = keyOf(from), keyOf(to)
    if a == b then return true end
    return Navigator:CanTraverse(graph, a, b)
end

local function runChargeStep(seeker, graph)
    local state = seeker.LODSeekerState
    if not state or state.phase ~= "charge" then return false end

    if CurTime() < (seeker.LODHitStunUntil or 0) then
        clearSpecialState(seeker, CHARGE_COOLDOWN)
        return true
    end

    if CurTime() >= (state.endsAt or 0) or (state.distance or 0) >= CHARGE_RANGE then
        clearSpecialState(seeker, CHARGE_COOLDOWN)
        return true
    end

    local pos = seeker:GetPos()
    local target = state.target
    if livingPlayer(target)
        and horizontalDistanceSqr(pos, target:GetPos()) <= PLAYER_CONTACT_DISTANCE * PLAYER_CONTACT_DISTANCE
    then
        resolvePlayerImpact(seeker, graph, target)
        return true
    end

    local direction = state.direction
    local probeDistance = math.max(20, CHARGE_SPEED * (SERVICE_INTERVAL + 0.015))
    local probeEnd = pos + direction * probeDistance
    probeEnd.z = pos.z

    local tr = util.TraceHull({
        start = pos + Vector(0, 0, 14),
        endpos = probeEnd + Vector(0, 0, 14),
        mins = Vector(-13, -13, -13),
        maxs = Vector(13, 13, 13),
        mask = MASK_SHOT,
        filter = traceFilter(seeker, target)
    })

    if tr.Hit then
        if IsValid(tr.Entity) and tr.Entity:IsPlayer() and tr.Entity:Alive() then
            resolvePlayerImpact(seeker, graph, tr.Entity)
        else
            impactStun(seeker, tr.HitPos)
        end
        return true
    end

    if not stepGraphValid(graph, pos, probeEnd) then
        impactStun(seeker, probeEnd)
        return true
    end

    local cfg = seeker.LODConfig or {}
    local oldSpeed = cfg.speed
    cfg.speed = CHARGE_SPEED
    local before = seeker:GetPos()
    Motion:MoveToward(seeker, {pos = probeEnd, tolerance = 1, stair = false, seekerCharge = true})
    cfg.speed = oldSpeed
    local travelled = seeker:GetPos():Distance(before)
    state.distance = (state.distance or 0) + travelled
    seeker.LODMotionMode = "seeker-charge"

    if livingPlayer(target)
        and horizontalDistanceSqr(seeker:GetPos(), target:GetPos()) <= PLAYER_CONTACT_DISTANCE * PLAYER_CONTACT_DISTANCE
    then
        resolvePlayerImpact(seeker, graph, target)
    end
    return true
end

local function serviceSeeker(seeker, graph)
    if not IsValid(seeker) or seeker.LODDead or seeker.LODActivated == false then return end

    local state = seeker.LODSeekerState
    if state then
        if state.phase == "windup" then
            Motion:Stop(seeker)
            Motion:FaceToward(seeker, state.aimPos)
            if CurTime() >= (state.releasesAt or 0) then beginCharge(seeker) end
            return
        end
        if state.phase == "charge" then
            runChargeStep(seeker, graph)
            return
        end
    end

    if seeker.LODSeekerRetreat then
        runRetreatStep(seeker, graph)
        return
    end

    if CurTime() < (seeker.LODHitStunUntil or 0) then return end

    seeker:_RefreshTarget(graph)
    local target = seeker.LODTarget
    if not IsValid(target) then return end

    local distance = horizontalDistance(seeker:GetPos(), target:GetPos())
    if distance < MIN_CHARGE_RANGE then
        if beginRetreat(seeker, graph, target, "too-close") then runRetreatStep(seeker, graph) end
        return
    end

    if CurTime() < (seeker.LODNextSeekerCharge or 0) then return end
    beginWindup(seeker, graph, target)
end

timer.Create(SERVICE_NAME, SERVICE_INTERVAL, 0, function()
    local state, graph = currentState()
    if not state or not graph or not state.BuildReady or state.Failed or state.LevelCleared
        or state.SimulationFrozen
    then
        return
    end

    Seeker.Stats.serviceTicks = (Seeker.Stats.serviceTicks or 0) + 1
    for _, hostile in ipairs(LOD.HostileRegistry and LOD.HostileRegistry:List() or {}) do
        if IsValid(hostile) and hostile.LODArchetypeId == "seeker" and not hostile.LODDead then
            serviceSeeker(hostile, graph)
        end
    end
end)

if Rolls and not Rolls.LODSeekerHealthInstalled then
    Rolls.LODSeekerHealthInstalled = true
    local baseRollEnemyHealth = Rolls.RollEnemyHealth
    function Rolls:RollEnemyHealth(archetypeId, instanceSeed)
        if archetypeId ~= "seeker" then return baseRollEnemyHealth(self, archetypeId, instanceSeed) end
        local seed = LOD.Seeds.Derive(instanceSeed or 1, "health-dice:seeker")
        local total, values = self:_RollFormula(SEEKER_HEALTH_PROFILE, LOD.RNG.New(seed))
        self.Stats.healthRolls = (self.Stats.healthRolls or 0) + 1
        return {
            profile = SEEKER_HEALTH_PROFILE,
            formula = "3d4+3",
            total = total,
            values = values,
            expected = 10.5,
            seed = seed
        }
    end
end

local function installHostilePatch()
    local stored = scripted_ents.GetStored("lod_hostile")
    local class = stored and stored.t
    if not class or class.LODSeekerPatched then return false end
    class.LODSeekerPatched = true

    local baseInitialize = class.Initialize
    function class:Initialize()
        baseInitialize(self)
        if self.LODArchetypeId ~= "seeker" or not self.LODConfig then return end
        self.LODSeekerState = nil
        self.LODSeekerRetreat = nil
        self.LODSeekerCommittedRetreat = nil
        self.LODNextSeekerCharge = CurTime() + 0.75
        self:SetNW2Bool("LOD_Seeker", true)
        self:SetCollisionBounds(Vector(-13, -13, 0), Vector(13, 13, 28))
        stopLegacyLoop(self)
    end

    local baseTryAttack = class._TryAttack
    function class:_TryAttack(target)
        if self.LODArchetypeId == "seeker" then return false end
        return baseTryAttack(self, target)
    end

    local baseBehaviourTick = class._BehaviourTick
    function class:_BehaviourTick()
        if self.LODArchetypeId ~= "seeker" then return baseBehaviourTick(self) end
        if self.LODSeekerState or self.LODSeekerRetreat then return end

        local target = self.LODTarget
        if IsValid(target) and self._HasLineOfSight and self:_HasLineOfSight(target)
            and horizontalDistanceSqr(self:GetPos(), target:GetPos())
                <= READY_STANDOFF_DISTANCE * READY_STANDOFF_DISTANCE
        then
            Motion:Stop(self)
            Motion:FaceToward(self, target:GetPos())
            return
        end

        return baseBehaviourTick(self)
    end

    local baseOnRemove = class.OnRemove
    function class:OnRemove()
        if self.LODArchetypeId == "seeker" then
            stopLegacyLoop(self)
            sendState(self, 0, 0)
        end
        if baseOnRemove then return baseOnRemove(self) end
    end

    return true
end

installHostilePatch()
hook.Add("OnEntityCreated", "LOD_SeekerInstallBeforeSpawn", function(ent)
    if IsValid(ent) and ent:GetClass() == "lod_hostile" then installHostilePatch() end
end)

if EncounterDirector and not EncounterDirector.LODSeekerTemplatesInstalled then
    EncounterDirector.LODSeekerTemplatesInstalled = true
    local baseEligibleTemplates = EncounterDirector._EligibleTemplates
    function EncounterDirector:_EligibleTemplates(sector, role)
        local choices = baseEligibleTemplates(self, sector, role) or {}
        if sector >= 2 then choices[#choices + 1] = "incoming" end
        return choices
    end
end

local function cleanupTestEntities()
    for _, ent in ipairs(Seeker.TestEntities or {}) do
        if IsValid(ent) then ent:Remove() end
    end
    Seeker.TestEntities = {}
end

local function testSpawnCell(graph, playerCell, ply)
    local playerKey = keyOf(playerCell)
    local keys = {}
    for neighborKey in pairs(playerCell.neighbors or {}) do keys[#keys + 1] = neighborKey end
    table.sort(keys)

    for _, neighborKey in ipairs(keys) do
        local cell = graph.Cells[neighborKey]
        if cell and cell.z == playerCell.z and not safeCell(graph, cell)
            and Navigator:CanTraverse(graph, playerKey, neighborKey)
        then
            local center = Navigator:CellCenter(cell) + Vector(0, 0, 2)
            local tr = util.TraceHull({
                start = center + Vector(0, 0, 14),
                endpos = ply:WorldSpaceCenter(),
                mins = Vector(-12, -12, -12),
                maxs = Vector(12, 12, 12),
                mask = MASK_SHOT,
                filter = function(ent)
                    if ent == ply then return true end
                    if IsValid(ent) and ent.LODHostile then return false end
                    return true
                end
            })
            if not tr.Hit or tr.Entity == ply then return cell end
        end
    end
    return nil
end

concommand.Add("lod_seeker_test", function(ply)
    local cv = GetConVar("lod_developer_mode")
    if cv and not cv:GetBool() then return end
    if not IsValid(ply) or not ply:IsAdmin() then return end

    local state, graph = currentState()
    if not state or not graph or not state.BuildReady then
        ply:ChatPrint("Seeker test requires an active generated dungeon.")
        return
    end

    local playerCell = Navigator:WorldToCell(graph, ply:GetPos())
    if not playerCell or safeCell(graph, playerCell) then
        ply:ChatPrint("Move into an ordinary non-safe corridor before running lod_seeker_test.")
        return
    end

    local spawnCell = testSpawnCell(graph, playerCell, ply)
    if not spawnCell then
        ply:ChatPrint("No clear adjacent Seeker test lane from this cell; move to another corridor cell.")
        return
    end

    cleanupTestEntities()
    local ent = ents.Create("lod_hostile")
    if not IsValid(ent) then return end
    ent.LODArchetypeId = "seeker"
    ent.LODHomeCellKey = keyOf(spawnCell)
    ent.LODEncounterId = nil
    ent.LODEncounterOrdinal = 981001
    ent.LODActivated = true
    ent:SetPos(Navigator:CellCenter(spawnCell) + Vector(0, 0, 2))
    ent:Spawn()
    ent:Activate()
    ent.LODTarget = ply
    ent.LODReturningHome = false
    ent.LODNextTargetRefresh = CurTime() + 1.0
    ent.LODNextSeekerCharge = 0
    Seeker.TestEntities[#Seeker.TestEntities + 1] = ent
    Seeker.Stats.testSpawns = (Seeker.Stats.testSpawns or 0) + 1

    local line = string.format(
        "seeker=#%d lane=%s->%s windup=%.2fs chargeSpeed=%d damage=2d6+4 minRange=%d retreatRange=%d",
        ent:EntIndex(), keyOf(spawnCell), keyOf(playerCell), WINDUP_SECONDS, CHARGE_SPEED,
        MIN_CHARGE_RANGE, RETREAT_TARGET_DISTANCE)
    print("[LOD:SEEKER-TEST] " .. line)
    ply:ChatPrint(line)
end)

concommand.Add("lod_seeker_status", function(ply)
    local cv = GetConVar("lod_developer_mode")
    if cv and not cv:GetBool() then return end
    if IsValid(ply) and not ply:IsAdmin() then return end

    local live, windup, charging, retreating, blocked = 0, 0, 0, 0, 0
    for _, hostile in ipairs(LOD.HostileRegistry and LOD.HostileRegistry:List() or {}) do
        if IsValid(hostile) and not hostile.LODDead and hostile.LODArchetypeId == "seeker" then
            live = live + 1
            local phase = hostile.LODSeekerState and hostile.LODSeekerState.phase
            if phase == "windup" then windup = windup + 1 end
            if phase == "charge" then charging = charging + 1 end
            if hostile.LODSeekerRetreat then
                retreating = retreating + 1
                if hostile.LODMotionMode == "seeker-retreat-blocked" then blocked = blocked + 1 end
            end
        end
    end

    local resolved = (Seeker.Stats.playerHits or 0) + (Seeker.Stats.wallImpacts or 0)
    local pass = (Seeker.Stats.windups or 0) > 0 and (Seeker.Stats.charges or 0) > 0 and resolved > 0
    local line = string.format(
        "live=%d windup=%d charging=%d retreating=%d blocked=%d windups=%d charges=%d playerHits=%d wallImpacts=%d impactStuns=%d retreatStarts=%d retreatCompletes=%d blockedRetreats=%d postHitRetreats=%d closeRangeRetreats=%d tests=%d authority=single result=%s",
        live, windup, charging, retreating, blocked,
        Seeker.Stats.windups or 0,
        Seeker.Stats.charges or 0,
        Seeker.Stats.playerHits or 0,
        Seeker.Stats.wallImpacts or 0,
        Seeker.Stats.impactStuns or 0,
        Seeker.Stats.retreatStarts or 0,
        Seeker.Stats.retreatCompletes or 0,
        Seeker.Stats.blockedRetreats or 0,
        Seeker.Stats.postHitRetreats or 0,
        Seeker.Stats.closeRangeRetreats or 0,
        Seeker.Stats.testSpawns or 0,
        pass and "PASS" or "WAITING")
    print("[LOD:SEEKER] " .. line)
    if IsValid(ply) then ply:ChatPrint(line) end
end)