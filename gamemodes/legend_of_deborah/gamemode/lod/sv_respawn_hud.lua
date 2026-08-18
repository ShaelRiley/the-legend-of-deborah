LOD = LOD or {}

local RunManager = LOD.RunManager
local nextSync = 0
local SYNC_INTERVAL = 0.20

-- Publish the authoritative server-side respawn countdown for the local HUD.
-- This intentionally derives from RunManager player state instead of starting a
-- client stopwatch, so reconnects, pauses/freeze adjustments, and delayed state
-- changes cannot leave the visible timer lying to the player.
hook.Add("Think", "LOD_RespawnHUDSync", function()
    if CurTime() < nextSync then return end
    nextSync = CurTime() + SYNC_INTERVAL

    for _, ply in ipairs(player.GetAll()) do
        if IsValid(ply) then
            local ps = RunManager:GetPlayerState(ply)
            local remaining = 0
            if ps and not ps.eliminated and ps.lives > 0 and ps.respawnAt then
                remaining = math.max(0, ps.respawnAt - CurTime())
            end

            ply:SetNW2Float("LOD_RespawnRemaining", remaining)
        end
    end
end)
