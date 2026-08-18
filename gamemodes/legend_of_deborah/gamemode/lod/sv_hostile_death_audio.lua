LOD = LOD or {}

-- The hostile entity owns the visual one-second / eight-blink death presentation.
-- This module owns its audible counterpart so the retro countdown reads clearly
-- even when the corpse is outside the player's central field of view.
local BLINK_INTERVAL = 0.125
local BLINK_COUNT = 8
local BLINK_SOUND = "buttons/button15.wav"
local LEGACY_BLINK_SOUND = "buttons/blip1.wav"
local CONVERT_SOUND = "items/itempickup.wav"
local CONVERT_ACCENT = "buttons/button9.wav"

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
    if ent.LODPlaceholderLoot and soundName == CONVERT_SOUND then
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

    -- The final disappearance/loot conversion is intentionally brighter and
    -- louder than the countdown so the handoff is obvious even during combat.
    timer.Simple(BLINK_INTERVAL * BLINK_COUNT + 0.01, function()
        if not seed or not sameLevel(seed) then return end
        sound.Play(CONVERT_SOUND, origin, 84, 145, 1.0)
        sound.Play(CONVERT_ACCENT, origin, 76, 132, 0.80)
    end)
end)
