LOD = LOD or {}

local function addActivity(out, activity)
    if isnumber(activity) then out[#out + 1] = activity end
end

local function freezeInPainPose(hostile)
    if not IsValid(hostile) or not hostile.LODHostile or not hostile.LODDead then return end

    local activities = {}
    addActivity(activities, ACT_BIG_FLINCH)
    addActivity(activities, ACT_FLINCH_CHEST)
    addActivity(activities, ACT_SMALL_FLINCH)
    addActivity(activities, ACT_FLINCH_HEAD)

    for _, activity in ipairs(activities) do
        if hostile.SelectWeightedSequence then
            local sequence = hostile:SelectWeightedSequence(activity)
            if isnumber(sequence) and sequence >= 0 then
                hostile:ResetSequence(sequence)
                -- Freeze halfway through the flinch so the one-second blink reads
                -- like a wounded 16-bit death pose rather than a normal ragdoll.
                hostile:SetCycle(0.48)
                hostile:SetPlaybackRate(0)
                return
            end
        end
    end

    -- Defensive fallback for a model lacking ordinary flinch activities.
    -- Preserve whatever sequence the entity has but freeze it immediately.
    hostile:SetPlaybackRate(0)
end

hook.Add("LOD_HostileDeathApplyPose", "LOD_HostileDeathPainPose", function(hostile)
    freezeInPainPose(hostile)
end)
