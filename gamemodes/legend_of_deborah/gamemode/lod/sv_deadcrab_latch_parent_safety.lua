LOD = LOD or {}
LOD.DeadcrabLatchSafety = LOD.DeadcrabLatchSafety or {}

local Safety = LOD.DeadcrabLatchSafety

-- Source warns when player movement attempts to push any entity that is parented
-- to that player. Deadcrab face-latches are therefore represented as a manual
-- local transform only; the engine never receives a deadcrab->player parent.
Safety.ByPlayer = Safety.ByPlayer or setmetatable({}, {__mode = "k"})
Safety.Stats = Safety.Stats or {adopted = 0, intercepted = 0, updates = 0}

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

function Safety:RegisterLatch(crab, ply, localPos, localAng)
    if not isLatchedDeadcrab(crab, ply) then return false end
    crab.LODDeadcrabManualLatchTarget = ply
    crab.LODDeadcrabManualLatchLocalPos = localPos or crab.LODDeadcrabManualLatchLocalPos or DEFAULT_LOCAL_POS
    crab.LODDeadcrabManualLatchLocalAngles = localAng or crab.LODDeadcrabManualLatchLocalAngles or DEFAULT_LOCAL_ANG
    playerBucket(ply)[crab] = true
    updateTransform(ply, crab)
    return true
end

local function adoptParentedLatch(ply, crab)
    if not isLatchedDeadcrab(crab, ply) or crab:GetParent() ~= ply then return false end

    local localPos = crab:GetLocalPos()
    local localAng = crab:GetLocalAngles()
    crab:SetParent(nil)
    Safety:RegisterLatch(crab, ply, localPos, localAng)

    Safety.Stats.adopted = (Safety.Stats.adopted or 0) + 1
    return true
end

-- sv_deadcrab.lua historically calls SetParent(player), SetLocalPos, then
-- SetLocalAngles when the latch lands. Intercept only that exact relationship so
-- no frame exists in which Source sees a hostile parented to player movement.
-- All other entity parenting/local-transform calls pass straight through.
local entityMeta = FindMetaTable("Entity")
if entityMeta and not Safety.LODDeadcrabMetaWrapped then
    Safety.LODDeadcrabMetaWrapped = true

    local baseSetParent = entityMeta.SetParent
    local baseSetLocalPos = entityMeta.SetLocalPos
    local baseSetLocalAngles = entityMeta.SetLocalAngles

    function entityMeta:SetParent(parent, ...)
        if IsValid(self)
            and self.LODHostile
            and self.LODArchetypeId == "deadcrab"
            and self.LODDeadcrabState == "latched"
            and IsValid(parent)
            and parent:IsPlayer()
        then
            Safety:RegisterLatch(self, parent)
            Safety.Stats.intercepted = (Safety.Stats.intercepted or 0) + 1
            return
        end
        return baseSetParent(self, parent, ...)
    end

    function entityMeta:SetLocalPos(pos)
        local ply = self.LODDeadcrabManualLatchTarget
        if IsValid(ply) and isLatchedDeadcrab(self, ply) and self:GetParent() ~= ply then
            self.LODDeadcrabManualLatchLocalPos = pos
            self:SetPos(ply:LocalToWorld(pos))
            return
        end
        return baseSetLocalPos(self, pos)
    end

    function entityMeta:SetLocalAngles(ang)
        local ply = self.LODDeadcrabManualLatchTarget
        if IsValid(ply) and isLatchedDeadcrab(self, ply) and self:GetParent() ~= ply then
            self.LODDeadcrabManualLatchLocalAngles = ang
            self:SetAngles(ply:LocalToWorldAngles(ang))
            return
        end
        return baseSetLocalAngles(self, ang)
    end
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

-- Fallback migration for any pre-existing/stale parented latch created before
-- this module installed (for example after Lua refresh during development).
hook.Add("SetupMove", "LOD_DeadcrabLatchParentSafety_PreMove", function(ply)
    if not IsValid(ply) or not ply:IsPlayer() then return end

    for _, child in ipairs(ply:GetChildren()) do
        if isLatchedDeadcrab(child, ply) then
            adoptParentedLatch(ply, child)
        end
    end
end)

-- Re-apply the stored local transform after movement so the latch remains visually
-- attached with bounded work only for that player's actually latched Deadcrabs.
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

    local line = string.format("intercepted=%d adopted=%d active=%d updates=%d playerParenting=false",
        Safety.Stats.intercepted or 0, Safety.Stats.adopted or 0, active, Safety.Stats.updates or 0)
    print("[LOD:DEADCRAB-LATCH-SAFETY] " .. line)
    if IsValid(ply) then ply:ChatPrint(line) end
end)
