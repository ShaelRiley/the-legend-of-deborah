LOD = LOD or {}

local function freezeInPainPose(hostile)
    if not IsValid(hostile) or not hostile.LODHostile or not hostile.LODDead then return end

    -- Share the same full-body safety checks as living hit-stun. Selecting a
    -- weighted NPC flinch here could otherwise reintroduce a sinking delta pose
    -- on the lethal hit, before the deferred hurt-pose hook runs next tick.
    local hurtPose = LOD.HostileHurtPose
    if hurtPose and hurtPose:Freeze(hostile, 0.48, "death") then return end
    hostile:SetPlaybackRate(0)
end

hook.Add("LOD_HostileDeathApplyPose", "LOD_HostileDeathPainPose", function(hostile)
    freezeInPainPose(hostile)
end)
