LOD = LOD or {}
LOD.DeadcrabLatchSafety = LOD.DeadcrabLatchSafety or {}

local Safety = LOD.DeadcrabLatchSafety

-- Source warns when player movement attempts to push any entity that is parented
-- to that player. Deadcrab face-latches previously used Entity:SetParent(player),
-- which made an otherwise harmless visual attachment participate in that engine
-- path. Keep the authored latch/fuse behavior, but convert the attachment to a
-- tiny manual local transform before the player's next movement simulation.
Safety.ByPlayer = Safety.ByPlayer or setmetatable({}, {__mode = "k"})
Safety.Stats = Safety.Stats or {adopted = 0, updates = 0}

local DEFAULT_LOCAL_POS = Vector(8, 0, 62)
local DEFAULT_LOCAL_ANG = Angle(0, 180, 0)

local function isLatchedDeadcrab(ent, ply)
    return IsValid(ent)
        and ent.LODHostile
        and ent.LODArchetypeId == "deadcrab"
        and ent.LODDeadcrabState == "latched"
        and ent.LODDeadcrabTarget == ply
        and not ent.LODDead
end

local function playerBucket(ply)
    local bucket = Safety.ByPlayer[ply]
    if not bucket then
        bucket = setmetatable({}, {__mode = "k"})
        Safety.ByPlayer[ply] = bucket
    end
    return bucket
end

local function updateTransform(ply, crab)
    if not isLatchedDeadcrab(crab, ply) then return false end

    local localPos = crab.LODDeadcrabManualLatchLocalPos or DEFAULT_LOCAL_POS
    local localAng = crab.LODDeadcrabManualLatchLocalAngles or DEFAULT_LOCAL_ANG
    crab:SetPos(ply:LocalToWorld(localPos))
    crab:SetAngles(ply:LocalToWorldAngles(localAng))
    Safety.Stats.updates = (Safety.Stats.updates or 0) + 1
    return true
end

local function adoptParentedLatch(ply, crab)
    if not isLatchedDeadcrab(crab, ply) or crab:GetParent() ~= ply then return false end

    -- Capture exactly the local transform authored by sv_deadcrab.lua before
    -- detaching. The fuse, target reference, collision state, activity and death
    -- path remain untouched; only the engine parent relationship is retired.
    crab.LODDeadcrabManualLatchLocalPos = crab:GetLocalPos()
    crab.LODDeadcrabManualLatchLocalAngles = crab:GetLocalAngles()
    crab:SetParent(nil)
    crab.LODDeadcrabManualLatchTarget = ply
    playerBucket(ply)[crab] = true
    updateTransform(ply, crab)

    Safety.Stats.adopted = (Safety.Stats.adopted or 0) + 1
    return true
end

local function pruneAndUpdate(ply)
    local bucket = Safety.ByPlayer[ply]
    if not bucket then return end

    for crab in pairs(bucket) do
        if not updateTransform(ply, crab) then
            bucket[crab] = nil
            if IsValid(crab) then
                crab.LODDeadcrabManualLatchTarget = nil
                crab.LODDeadcrabManualLatchLocalPos = nil
                crab.LODDeadcrabManualLatchLocalAngles = nil
            end
        end
    end
end

-- SetupMove runs before Source applies this player's movement. Convert any newly
-- parented latch here, before the engine reaches its parented-entity push path.
hook.Add("SetupMove", "LOD_DeadcrabLatchParentSafety_PreMove", function(ply)
    if not IsValid(ply) or not ply:IsPlayer() then return end

    for _, child in ipairs(ply:GetChildren()) do
        if isLatchedDeadcrab(child, ply) then
            adoptParentedLatch(ply, child)
        end
    end
end)

-- Re-apply the stored local transform after movement so the latch remains visually
-- attached with at most one command-tick of work and without a global entity scan.
hook.Add("FinishMove", "LOD_DeadcrabLatchParentSafety_PostMove", function(ply)
    if not IsValid(ply) or not ply:IsPlayer() then return end
    pruneAndUpdate(ply)
end)

hook.Add("PlayerDisconnected", "LOD_DeadcrabLatchParentSafety_Disconnect", function(ply)
    Safety.ByPlayer[ply] = nil
end)

concommand.Add("lod_deadcrab_latch_safety_status", function(ply)
    local cv = GetConVar("lod_developer_mode")
    if cv and not cv:GetBool() then return end
    if IsValid(ply) and not ply:IsAdmin() then return end

    local active = 0
    for owner, bucket in pairs(Safety.ByPlayer) do
        if IsValid(owner) then
            for crab in pairs(bucket) do
                if isLatchedDeadcrab(crab, owner) then active = active + 1 end
            end
        end
    end

    local line = string.format("adopted=%d active=%d updates=%d playerParenting=false",
        Safety.Stats.adopted or 0, active, Safety.Stats.updates or 0)
    print("[LOD:DEADCRAB-LATCH-SAFETY] " .. line)
    if IsValid(ply) then ply:ChatPrint(line) end
end)
