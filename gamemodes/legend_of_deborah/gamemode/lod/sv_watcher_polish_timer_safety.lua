LOD = LOD or {}

-- sv_watcher_polish retires the old concealment movement service in favor of the
-- entity's ordinary Behaviour + Motion V2 cadence. timer.Remove is deferred by
-- Garry's Mod until the following frame, so reassert the paused sentinel once
-- after startup as well as immediately. This prevents the retired concealment
-- module from recreating its 10 Hz physical mover when the first scan completes.
local LEGACY_CONCEAL_TIMER = "LOD_WatcherConcealmentService"

local function ensurePausedSentinel()
    if not timer.Exists(LEGACY_CONCEAL_TIMER) then
        timer.Create(LEGACY_CONCEAL_TIMER, 1, 0, function() end)
    end
    timer.Pause(LEGACY_CONCEAL_TIMER)
end

ensurePausedSentinel()
timer.Simple(0.25, ensurePausedSentinel)

concommand.Add("lod_watcher_timer_authority", function(ply)
    local cv = GetConVar("lod_developer_mode")
    if cv and not cv:GetBool() then return end
    if IsValid(ply) and not ply:IsAdmin() then return end

    local line = string.format(
        "legacyConcealExists=%s legacyConcealPaused=%s authority=Behaviour+MotionV2",
        tostring(timer.Exists(LEGACY_CONCEAL_TIMER)),
        tostring(timer.Exists(LEGACY_CONCEAL_TIMER) and timer.IsPaused(LEGACY_CONCEAL_TIMER)))
    print("[LOD:WATCHER-TIMER] " .. line)
    if IsValid(ply) then ply:ChatPrint(line) end
end)