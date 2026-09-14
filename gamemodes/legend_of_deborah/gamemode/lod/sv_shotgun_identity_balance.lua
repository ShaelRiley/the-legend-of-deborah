LOD = LOD or {}

local Rolls = LOD.CombatRolls
local HitFeedback = LOD.M3HitFeedback
if not Rolls or not HitFeedback then return end

-- Damage and pellet rolls now belong to sv_combat_rolls.lua. This module retains
-- the accepted four-times stun presentation; it must never replace the contract.
local SHOTGUN_STUN_MULTIPLIER = 4
local BASE_STUN_SECONDS = 0.30
local BASE_STUN_RETRIGGER_SECONDS = 0.36

-- The original hit-stun authority was authored when 2x was the largest legal
-- multiplier and therefore clamps there. Extend that same authority to 4x so
-- future weapons/effects can request stronger stuns without creating a parallel
-- stun system. The base function still owns cancellation/flinch semantics.
if not HitFeedback.LODFourTimesStunSupported then
    HitFeedback.LODFourTimesStunSupported = true
    local baseApplyHitStun = HitFeedback.ApplyHitStun

    function HitFeedback:ApplyHitStun(hostile, durationMultiplier, attacker)
        local requested = math.Clamp(tonumber(durationMultiplier) or 1, 1, 4)
        local applied = baseApplyHitStun(self, hostile, math.min(requested, 2), attacker)
        if not applied or requested <= 2 then return applied end

        local stamp = IsValid(hostile) and hostile.LODLastHitFeedbackEvent or nil
        attacker = IsValid(attacker) and attacker or (stamp and stamp.attacker or nil)
        local rules = LOD.RPGAbilityRules
        local abilityMultiplier = rules and rules.HitStunMultiplier
            and rules:HitStunMultiplier(attacker, hostile) or 1
        local effectiveRequested = math.Clamp(requested * abilityMultiplier, 0.50, 4)
        local now = CurTime()
        local stunSeconds = BASE_STUN_SECONDS * effectiveRequested
        local retriggerSeconds = BASE_STUN_RETRIGGER_SECONDS
            + BASE_STUN_SECONDS * (effectiveRequested - 1)

        hostile.LODHitStunUntil = math.max(hostile.LODHitStunUntil or 0, now + stunSeconds)
        hostile.LODNextHitStun = math.max(hostile.LODNextHitStun or 0, now + retriggerSeconds)

        -- Preserve the base authority's special-attack cancellation intent for
        -- the full extended stun rather than allowing an attack to become ready
        -- halfway through a 4x control window.
        if hostile.LODArchetypeId == "soldier" or hostile.LODArchetypeId == "blitzer" then
            hostile.LODNextAttack = math.max(hostile.LODNextAttack or 0, now + stunSeconds + 0.10)
        end
        if hostile.LODArchetypeId == "bioblaster" then
            hostile.LODNextBioCharge = math.max(hostile.LODNextBioCharge or 0, now + stunSeconds + 0.35)
        end
        if hostile.LODArchetypeId == "deadcrab" and hostile.LODDeadcrabState ~= "latched" then
            hostile.LODDeadcrabNextLeap = math.max(hostile.LODDeadcrabNextLeap or 0, now + stunSeconds + 0.35)
        end

        return true
    end

    function HitFeedback:ApplyShotgunShellStun(hostile, attacker)
        -- One aggregate stun per damaged target per shell; pellet count never
        -- multiplies control duration.
        return self:ApplyHitStun(hostile, SHOTGUN_STUN_MULTIPLIER, attacker)
    end
end

-- Replace the old 2x developer probe with the current 4x contract so diagnostics
-- remain trustworthy after this balance change.
concommand.Add("lod_dice_shotgun_stun_probe", function(ply)
    local cv = GetConVar("lod_developer_mode")
    if cv and not cv:GetBool() then return end
    if not IsValid(ply) or not ply:IsAdmin() then return end

    local hostile
    for _, candidate in ipairs(ents.FindByClass("lod_hostile")) do
        if IsValid(candidate) and not candidate.LODDead and candidate:Health() > 1
            and candidate.LODDeadcrabState ~= "latched" then
            hostile = candidate
            break
        end
    end
    if not IsValid(hostile) then
        local text = "no eligible live hostile result=FAIL"
        print("[LOD:DICE-SHOTGUN] " .. text)
        ply:ChatPrint(text)
        return
    end

    hostile.LODHitStunUntil = nil
    hostile.LODNextHitStun = nil
    hostile.LODLastHitFeedbackEvent = nil
    local applied = HitFeedback:ApplyShotgunShellStun(hostile)
    local remaining = math.max(0, (hostile.LODHitStunUntil or 0) - CurTime())
    local lockout = math.max(0, (hostile.LODNextHitStun or 0) - CurTime())
    local duplicateRejected = not HitFeedback:ApplyShotgunShellStun(hostile)
    local durationPass = remaining >= 1.18 and remaining <= 1.21
    local lockoutPass = lockout >= 1.24 and lockout <= 1.27
    local passed = applied and duplicateRejected and durationPass and lockoutPass
    local text = string.format(
        "shellApplied=%s duplicateRejected=%s duration=%.2f lockout=%.2f multiplier=4 result=%s",
        tostring(applied), tostring(duplicateRejected), remaining, lockout,
        passed and "PASS" or "FAIL")
    print("[LOD:DICE-SHOTGUN] " .. text)
    ply:ChatPrint(text)
end)
