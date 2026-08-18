LOD = LOD or {}

local HIT_CONFIRM_OPEN = "buttons/button9.wav"
local HIT_CONFIRM_RESOLVE = "items/suitchargeok1.wav"
local nextConfirm = 0

local function playHitConfirm()
    local now = RealTime()
    if now < nextConfirm then return end
    nextConfirm = now + 0.05

    -- Deliberately non-diegetic and local to the shooter. Two short contrasting
    -- Source cues read as positive confirmation without being mistaken for an
    -- enemy vocalization, footstep, projectile, or world interaction.
    surface.PlaySound(HIT_CONFIRM_OPEN)
    timer.Simple(0.045, function()
        surface.PlaySound(HIT_CONFIRM_RESOLVE)
    end)
end

net.Receive("LOD_HitConfirm", playHitConfirm)

-- Developer sanity check separates client audio problems from server hit-event
-- problems without requiring an enemy or ammunition.
concommand.Add("lod_m3_hitconfirm_audio_test", function()
    playHitConfirm()
end)
