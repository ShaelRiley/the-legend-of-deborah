LOD = LOD or {}

-- The hostile entity owns the visual one-second / eight-blink death presentation.
-- This module owns its audible counterpart so the retro countdown reads clearly
-- even when the corpse is outside the player's central field of view.
local BLINK_INTERVAL = 0.125
local BLINK_COUNT = 8
local BLINK_SOUND = "buttons/blip1.wav"
local CONVERT_SOUND = "items/itempickup.wav"
local CONVERT_ACCENT = "buttons/button9.wav"

local function sameLevel(seed)
    local state = LOD.RunManager and LOD.RunManager.State
    return state and not state.Failed and state.LevelSeed == seed
end

-- Suppress the earlier, deliberately restrained embedded pulses and placeholder
-- pickup sound. The synchronized sequence below supersedes them rather than
-- layering duplicate cues on top of the presentation.
hook.Add("EntityEmitSound", "LOD_HostileDeathAudio_SuppressLegacy", function(data)
    local ent = data.Entity
    if not IsValid(ent) then return end

    local soundName = string.lower(data.OriginalSoundName or data.SoundName or "")
    if ent:GetClass() == "lod_hostile" and ent.LODDead and soundName == BLINK_SOUND then
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

    -- One audible tick per visual visibility toggle. Pitch rises across the
    -- sequence, giving the player an intuitive countdown to the loot handoff.
    for tick = 1, BLINK_COUNT do
        timer.Simple(BLINK_INTERVAL * tick, function()
            if not seed or not sameLevel(seed) then return end
            local pitch = math.min(154, 104 + tick * 6)
            local volume = 0.48 + tick * 0.025
            sound.Play(BLINK_SOUND, origin, 68, pitch, volume)
        end)
    end

    -- The conversion has a different timbre from the blink ticks: a bright
    -- pickup pop plus a short confirmation accent. Milestone 4 can keep this
    -- handoff while replacing the placeholder object with real LootDirector data.
    timer.Simple(BLINK_INTERVAL * BLINK_COUNT + 0.01, function()
        if not seed or not sameLevel(seed) then return end
        sound.Play(CONVERT_SOUND, origin, 72, 142, 0.78)
        sound.Play(CONVERT_ACCENT, origin, 64, 128, 0.42)
    end)
end)
