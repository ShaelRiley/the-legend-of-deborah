-- Death is already voiced by the creature. Administrative blink pulses are
-- silent; only actual loot creation owns the small positive appearance cue.
hook.Add('EntityEmitSound','LOD_HostileDeathAudio_SuppressLegacy',function(data)
    local ent=data.Entity
    if not IsValid(ent) then return end
    local path=string.lower(data.OriginalSoundName or data.SoundName or '')
    if ent.LODDead and (path=='buttons/blip1.wav' or path=='buttons/button15.wav') then return false end
    if ent.LODPlaceholderLoot and path=='items/itempickup.wav' then return false end
end)
