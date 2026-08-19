LOD = LOD or {}

local HIT_CONFIRM_SOUND = "buttons/blip1.wav"
local nextConfirm = 0

local function playHitConfirm()
    local now = RealTime()
    if now < nextConfirm then return end
    nextConfirm = now + 0.04

    -- Deliberately non-diegetic and local to the shooter. Keep this to one
    -- extremely short transient so rapid gunfire confirms hits without creating
    -- a sustained synth tone or masking enemy/world audio.
    surface.PlaySound(HIT_CONFIRM_SOUND)
end

net.Receive("LOD_HitConfirm", playHitConfirm)

-- Developer sanity check separates client audio problems from server hit-event
-- problems without requiring an enemy or ammunition.
concommand.Add("lod_m3_hitconfirm_audio_test", function()
    playHitConfirm()
end)
