LOD = LOD or {}

-- The hostile entity owns the visual one-second / eight-blink death presentation.
-- This module owns its audible counterpart so the retro countdown reads clearly
-- even when the corpse is outside the player's central field of view.
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

hook.Add("LOD_HostileDeathBlinkPulse", "LOD_HostileDeathAudio_RetroPulse",
    function(origin, seed, pulse)
        if not seed or not sameLevel(seed) then return end
        local pitch = 104 + pulse * 10
        sound.Play(BLINK_SOUND, origin, 82, pitch, 0.95)
    end)

local CONVERT_NOTES = {
    {sound = CONVERT_OPEN, level = 92, pitch = 118},
    {sound = CONVERT_LIFT, level = 90, pitch = 142},
    {sound = CONVERT_RESOLVE, level = 92, pitch = 158}
}

hook.Add("LOD_HostileDeathConvertNote", "LOD_HostileDeathAudio_ConvertNote",
    function(origin, seed, step)
        if not seed or not sameLevel(seed) then return end
        local note = CONVERT_NOTES[step]
        if not note then return end
        sound.Play(note.sound, origin, note.level, note.pitch, 1.0)
    end)
