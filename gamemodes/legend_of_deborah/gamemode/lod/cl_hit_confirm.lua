LOD = LOD or {}

local HIT_CONFIRM_SOUND = "buttons/button14.wav"
local nextConfirm = 0

net.Receive("LOD_HitConfirm", function()
    local now = RealTime()
    if now < nextConfirm then return end
    nextConfirm = now + 0.035

    -- Deliberately non-diegetic: this is player-action confirmation, not a sound
    -- emitted by the victim in the world. It should remain legible in dense fights.
    surface.PlaySound(HIT_CONFIRM_SOUND)
end)
