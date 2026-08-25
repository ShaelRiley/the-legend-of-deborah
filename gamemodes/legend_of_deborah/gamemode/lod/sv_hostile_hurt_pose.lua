LOD = LOD or {}
LOD.HostileHurtPose = LOD.HostileHurtPose or {}

local HurtPose = LOD.HostileHurtPose

-- Prefer explicit sequence names first. Some Source models return a generic
-- weighted sequence for unsupported activities; named pain/flinch sequences are
-- less likely to silently resolve to an idle/walk animation.
local NAMED_SEQUENCES = {
    "flinch_phys_01", "flinch_phys_02", "flinch_phys_03", "flinch_phys_04",
    "flinch_phys_05", "flinch_phys_06", "flinch_front_01", "flinch_front_02",
    "flinch_head", "flinch_chest", "flinch_stomach",
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

local function sequenceName(hostile, sequence)
    if not IsValid(hostile) or not validSequence(hostile, sequence) or not hostile.GetSequenceName then return "" end
    return string.lower(hostile:GetSequenceName(sequence) or "")
end

function HurtPose:FindSequence(hostile)
    if not IsValid(hostile) then return nil end

    if hostile.LookupSequence then
        for _, name in ipairs(NAMED_SEQUENCES) do
            local sequence = hostile:LookupSequence(name)
            if validSequence(hostile, sequence) then
                local actual = sequenceName(hostile, sequence)
                if actual ~= "" and (string.find(actual, "flinch", 1, true) or string.find(actual, "pain", 1, true)) then
                    return sequence
                end
            end
        end
    end

    if hostile.SelectWeightedSequence then
        for _, activity in ipairs(ACTIVITIES) do
            if isnumber(activity) then
                local sequence = hostile:SelectWeightedSequence(activity)
                if validSequence(hostile, sequence) then
                    local actual = sequenceName(hostile, sequence)
                    -- Reject obvious locomotion/idle fallbacks. If the model does
                    -- not expose a descriptive sequence name, still accept a
                    -- nonzero sequence selected for a real flinch activity.
                    if not string.find(actual, "idle", 1, true)
                        and not string.find(actual, "walk", 1, true)
                        and not string.find(actual, "run", 1, true)
                    then
                        return sequence
                    end
                end
            end
        end
    end

    return nil
end

local function applySequence(hostile, sequence, cycle)
    if not IsValid(hostile) or not validSequence(hostile, sequence) then return false end
    hostile.LODCurrentActivity = nil
    if hostile:GetSequence() ~= sequence then
        hostile:SetSequence(sequence)
    end
    hostile:SetCycle(math.Clamp(cycle or 0.44, 0.15, 0.80))
    hostile:SetPlaybackRate(0)
    return true
end

function HurtPose:Freeze(hostile, cycle, mode)
    if not IsValid(hostile) or not hostile.LODHostile then return false end

    local sequence = self:FindSequence(hostile)
    if not sequence then
        -- Last-resort presentation fallback: freeze the current sequence rather
        -- than letting locomotion continue during a state that is mechanically
        -- supposed to be stunned. Most production HL2 models should resolve a
        -- real flinch above; the diagnostic command exposes any fallback case.
        sequence = hostile:GetSequence()
        if not validSequence(hostile, sequence) then return false end
    end

    hostile.LODFrozenHurtSequence = sequence
    hostile.LODFrozenHurtCycle = math.Clamp(cycle or 0.44, 0.15, 0.80)
    hostile.LODFrozenHurtMode = mode or "stun"
    return applySequence(hostile, sequence, hostile.LODFrozenHurtCycle)
end

function HurtPose:Clear(hostile)
    if not IsValid(hostile) then return end
    hostile.LODFrozenHurtSequence = nil
    hostile.LODFrozenHurtCycle = nil
    hostile.LODFrozenHurtMode = nil
    hostile:SetPlaybackRate(1)
    hostile.LODCurrentActivity = nil
end

-- Strengthen hit-stun presentation after the authoritative damage system has
-- actually established the stun. This wrapper owns the pose; the Think hook
-- below then reasserts it every frame for the entire stun interval so engine or
-- NextBot animation updates cannot immediately overwrite it.
if LOD.M3HitFeedback and not LOD.M3HitFeedback.LODFrozenHurtPoseWrapped then
    LOD.M3HitFeedback.LODFrozenHurtPoseWrapped = true
    local baseApplyHitStun = LOD.M3HitFeedback.ApplyHitStun

    function LOD.M3HitFeedback:ApplyHitStun(hostile, durationMultiplier)
        local applied = baseApplyHitStun(self, hostile, durationMultiplier)
        if applied and IsValid(hostile) then
            hostile.LODHitStunHasFlinch = HurtPose:Freeze(hostile, 0.44, "stun")
        end
        return applied
    end
end

hook.Add("Think", "LOD_HostileHurtPoseAuthoritative", function()
    local now = CurTime()
    for _, hostile in ipairs(LOD.HostileRegistry and LOD.HostileRegistry:List() or {}) do
        if IsValid(hostile) and hostile.LODFrozenHurtSequence then
            local dead = hostile.LODDead == true
            local stunned = now < (hostile.LODHitStunUntil or 0)

            if dead or stunned then
                -- Mechanical stun must be unambiguous as well as visual. Repeat
                -- the zero-speed command here so archetype-specific wrappers
                -- cannot restore movement during the stun window.
                if hostile.loco then
                    hostile.loco:SetDesiredSpeed(0)
                    if hostile.loco.SetVelocity then hostile.loco:SetVelocity(vector_origin) end
                end
                hostile:SetVelocity(vector_origin)
                applySequence(hostile, hostile.LODFrozenHurtSequence, hostile.LODFrozenHurtCycle)
            elseif hostile.LODFrozenHurtMode == "stun" then
                HurtPose:Clear(hostile)
                hostile.LODNextRouteRefresh = 0
                hostile.LODNextTargetRefresh = 0
                if hostile.loco and hostile.LODConfig then
                    hostile.loco:SetDesiredSpeed(hostile.LODConfig.speed or 90)
                end
            end
        end
    end
end)

-- Death presentation fires OnNPCKilled before _BeginDeathPresentation marks the
-- hostile dead. Run next tick, then hold exactly the same readable hurt pose for
-- every frame of the one-second blink/dematerialization sequence.
hook.Remove("OnNPCKilled", "LOD_HostileDeathPainPose")
hook.Add("OnNPCKilled", "LOD_HostileDeathPainPose", function(npc)
    if not IsValid(npc) or not npc.LODHostile then return end
    timer.Simple(0, function()
        if not IsValid(npc) or not npc.LODDead then return end
        HurtPose:Freeze(npc, 0.50, "death")
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
            local sequence = hostile.LODFrozenHurtSequence
            local text = string.format("#%d %s frozenSequence=%s name=%s mode=%s playback=%.2f cycle=%.2f stunRemaining=%.3f dead=%s",
                hostile:EntIndex(), tostring(hostile.LODArchetypeId),
                tostring(sequence or "none"), sequence and sequenceName(hostile, sequence) or "none",
                tostring(hostile.LODFrozenHurtMode or "none"), hostile:GetPlaybackRate(),
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
