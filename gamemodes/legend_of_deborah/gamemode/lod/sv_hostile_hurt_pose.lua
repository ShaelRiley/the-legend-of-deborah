LOD = LOD or {}
LOD.HostileHurtPose = LOD.HostileHurtPose or {}

local HurtPose = LOD.HostileHurtPose

local NAMED_SEQUENCES = {
    "flinch_phys_01", "flinch_phys_02", "flinch_phys_03", "flinch_phys_04",
    "flinch_phys_05", "flinch_phys_06", "flinch_front_01", "flinch_front_02",
    "flinch", "flinch1", "flinch2", "pain", "pain1", "pain2"
}

local ACTIVITIES = {
    ACT_BIG_FLINCH,
    ACT_FLINCH_CHEST,
    ACT_SMALL_FLINCH,
    ACT_FLINCH_HEAD
}

local function validSequence(hostile, sequence)
    return IsValid(hostile) and isnumber(sequence) and sequence >= 0
end

function HurtPose:FindSequence(hostile)
    if not IsValid(hostile) then return nil end

    -- Activity selection is the most portable route across HL2 humanoid/zombie
    -- models. If an archetype lacks those activities, use common named Source
    -- pain/flinch sequences as a second pass.
    if hostile.SelectWeightedSequence then
        for _, activity in ipairs(ACTIVITIES) do
            if isnumber(activity) then
                local sequence = hostile:SelectWeightedSequence(activity)
                if validSequence(hostile, sequence) then return sequence end
            end
        end
    end

    if hostile.LookupSequence then
        for _, name in ipairs(NAMED_SEQUENCES) do
            local sequence = hostile:LookupSequence(name)
            if validSequence(hostile, sequence) then return sequence end
        end
    end

    return nil
end

function HurtPose:Freeze(hostile, cycle)
    if not IsValid(hostile) or not hostile.LODHostile then return false end

    local sequence = self:FindSequence(hostile)
    if not sequence then return false end

    hostile.LODCurrentActivity = nil
    hostile:ResetSequence(sequence)
    hostile:SetCycle(math.Clamp(cycle or 0.44, 0.15, 0.80))
    hostile:SetPlaybackRate(0)
    hostile.LODFrozenHurtSequence = sequence
    return true
end

-- Strengthen the existing hit-stun system: after it stops movement and cancels
-- attacks, freeze the enemy partway through a real pain/flinch pose for the
-- entire stun interval. Behaviour resumes normally when the stun expires.
if LOD.M3HitFeedback and not LOD.M3HitFeedback.LODFrozenHurtPoseWrapped then
    LOD.M3HitFeedback.LODFrozenHurtPoseWrapped = true
    local baseApplyHitStun = LOD.M3HitFeedback.ApplyHitStun

    function LOD.M3HitFeedback:ApplyHitStun(hostile)
        local applied = baseApplyHitStun(self, hostile)
        if applied and IsValid(hostile) then
            hostile.LODHitStunHasFlinch = HurtPose:Freeze(hostile, 0.40)
        end
        return applied
    end
end

-- Replace the earlier death-pose hook with the same stronger pose selector used
-- by hit stun. The death presentation has already set movement/solid state by
-- the next tick; this then freezes a readable hurt pose for every blink frame.
hook.Remove("OnNPCKilled", "LOD_HostileDeathPainPose")
hook.Add("OnNPCKilled", "LOD_HostileDeathPainPose", function(npc)
    if not IsValid(npc) or not npc.LODHostile then return end
    timer.Simple(0, function()
        if not IsValid(npc) or not npc.LODDead then return end
        HurtPose:Freeze(npc, 0.48)
    end)
end)

concommand.Add("lod_m3_hurtpose_status", function(ply)
    local cv = GetConVar("lod_developer_mode")
    if cv and not cv:GetBool() then return end
    if IsValid(ply) and not ply:IsAdmin() then return end

    local count = 0
    for _, hostile in ipairs(ents.FindByClass("lod_hostile")) do
        if IsValid(hostile) then
            count = count + 1
            local text = string.format("#%d %s frozenSequence=%s playback=%.2f cycle=%.2f stunRemaining=%.3f dead=%s",
                hostile:EntIndex(), tostring(hostile.LODArchetypeId),
                tostring(hostile.LODFrozenHurtSequence or "none"), hostile:GetPlaybackRate(),
                hostile:GetCycle(), math.max(0, (hostile.LODHitStunUntil or 0) - CurTime()),
                tostring(hostile.LODDead == true))
            print("[LOD:HURTPOSE] " .. text)
            if IsValid(ply) then ply:ChatPrint(text) end
        end
    end
    if count == 0 then
        print("[LOD:HURTPOSE] no live hostiles")
        if IsValid(ply) then ply:ChatPrint("no live hostiles") end
    end
end)
