LOD = LOD or {}

-- Seeker presentation uses a handful of direct Source WAV paths. Different GMod
-- installs can lack individual loose/VPK sound assets even when the surrounding
-- HL2 sound family exists. Catch only Seeker direct-WAV emissions and substitute
-- a known-good electrical impact cue before Source attempts playback, preventing
-- missing-file console spam or a silent wall-impact tell.
local FALLBACK = "ambient/energy/zap9.wav"

hook.Add("EntityEmitSound", "LOD_SeekerSoundAssetSafety", function(data)
    local ent = data and data.Entity
    if not IsValid(ent) or ent.LODArchetypeId ~= "seeker" then return end

    local soundName = string.lower(tostring(data.SoundName or ""))
    if soundName == "" or not string.EndsWith(soundName, ".wav") then return end

    if not file.Exists("sound/" .. soundName, "GAME") then
        data.SoundName = FALLBACK
        return true
    end
end)
