LOD = LOD or {}

-- The hostile entity owns the visual one-second / eight-blink death presentation.
-- This module owns its audible counterpart so the retro countdown reads clearly
-- even when the corpse is outside the player's central field of view.
local BLINK_INTERVAL = 0.125
local BLINK_COUNT = 8
local BLINK_SOUND = "buttons/button15.wav"
local LEGACY_BLINK_SOUND = "buttons/blip1.wav"
local LEGACY_CONVERT_SOUND = "items/itempickup.wav"

-- The loot handoff needs to read as a small fanfare, not another UI click. These
-- are all base HL2 sounds already used/audited elsewhere in the gamemode. Three
-- staggered notes give the conversion a distinct beginning, lift, and resolve.
local CONVERT_OPEN = "items/suitchargeok1.wav"
local CONVERT_LIFT = "buttons/button9.wav"
local CONVERT_RESOLVE = "buttons/button14.wav"

local function sameLevel(seed)
    local state = LOD.RunManager and LOD.RunManager.State
    return state and not state.Failed and state.LevelSeed == seed
end

-- Suppress the older embedded corpse blips and placeholder pickup sound. The
-- synchronized sequence below supersedes them rather than layering duplicate
-- cues on top of the death presentation.
hook.Add("EntityEmitSound", "LOD_HostileDeathAudio_SuppressLegacy", function(data)
    local ent = data.Entity
    if not IsValid(ent) then return end

    local soundName = string.lower(data.OriginalSoundName or data.SoundName or "")
    if ent:GetClass() == "lod_hostile" and ent.LODDead and soundName == LEGACY_BLINK_SOUND then
        return false
    end
    if ent.LODPlaceholderLoot and soundName == LEGACY_CONVERT_SOUND then
        return false
    end
end)

hook.Add("OnNPCKilled", "LOD_HostileDeathAudio_RetroSequence", function(npc)
    if not IsValid(npc) or not npc.LODHostile then return end

    local origin = npc:WorldSpaceCenter()
    local seed = LOD.RunManager and LOD.RunManager.State and LOD.RunManager.State.LevelSeed or nil

    -- Four unmistakable rising electronic ticks, each synchronized with every
    -- second visual blink. Fewer, stronger notes read more clearly than eight
    -- quiet micro-blips while still making the one-second flicker feel rhythmic.
    for pulse = 1, 4 do
        timer.Simple(BLINK_INTERVAL * (pulse * 2 - 1), function()
            if not seed or not sameLevel(seed) then return end
            local pitch = 104 + pulse * 10
            sound.Play(BLINK_SOUND, origin, 82, pitch, 0.95)
        end)
    end

    -- A three-note conversion fanfare begins immediately after the final blink.
    -- It is deliberately louder and longer than the countdown ticks so the
    -- player hears a categorical transition: corpse gone, loot now available.
    local convertAt = BLINK_INTERVAL * BLINK_COUNT + 0.01
    timer.Simple(convertAt, function()
        if not seed or not sameLevel(seed) then return end
        sound.Play(CONVERT_OPEN, origin, 92, 118, 1.0)
    end)
    timer.Simple(convertAt + 0.11, function()
        if not seed or not sameLevel(seed) then return end
        sound.Play(CONVERT_LIFT, origin, 90, 142, 1.0)
    end)
    timer.Simple(convertAt + 0.24, function()
        if not seed or not sameLevel(seed) then return end
        sound.Play(CONVERT_RESOLVE, origin, 92, 158, 1.0)
    end)
end)
