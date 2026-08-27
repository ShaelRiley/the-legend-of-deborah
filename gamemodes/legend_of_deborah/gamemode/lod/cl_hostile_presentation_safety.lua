LOD = LOD or {}
LOD.HostilePresentationSafety = LOD.HostilePresentationSafety or {}

local Safety = LOD.HostilePresentationSafety
Safety.FirstSeen = Safety.FirstSeen or setmetatable({}, {__mode = "k"})
Safety.ForcedFreshDraws = Safety.ForcedFreshDraws or 0

local FRESH_ENTITY_GUARD_SECONDS = 0.75

local function installDrawGuard()
    local stored = scripted_ents.GetStored("lod_hostile")
    local class = stored and stored.t
    if not class or class.LODFreshPresentationGuardInstalled or not class.Draw then return false end
    class.LODFreshPresentationGuardInstalled = true

    local baseDraw = class.Draw
    function class:Draw()
        local now = CurTime()
        local firstSeen = Safety.FirstSeen[self]
        if not firstSeen then
            firstSeen = now
            Safety.FirstSeen[self] = now
        end

        -- GMod can recycle entity indexes before every NW2 field from the new
        -- hostile has arrived. A Runner inheriting one frame of an old Watcher's
        -- cloak timestamps was previously enough for the global Watcher Draw
        -- wrapper to suppress it. A real Watcher cannot legitimately enter cloak
        -- during its first 0.75 seconds (the scan alone lasts 1.25 seconds), so
        -- force a raw model draw only when a brand-new entity carries apparently
        -- active cloak/blink state. Once replication settles, normal rendering,
        -- size variance, device lift, and Watcher presentation regain authority.
        local fresh = now - firstSeen < FRESH_ENTITY_GUARD_SECONDS
        local staleCloakCandidate = self:GetNW2Float("LOD_WatcherInvisibleUntil", 0) > now
            or self:GetNW2Float("LOD_WatcherBlinkUntil", 0) > now

        if fresh and staleCloakCandidate then
            Safety.ForcedFreshDraws = (Safety.ForcedFreshDraws or 0) + 1
            self:DrawModel()
            return
        end

        return baseDraw(self)
    end
    return true
end

installDrawGuard()
hook.Add("OnEntityCreated", "LOD_FreshHostilePresentationGuard", function(ent)
    if not IsValid(ent) or ent:GetClass() ~= "lod_hostile" then return end
    Safety.FirstSeen[ent] = CurTime()
    installDrawGuard()
end)

hook.Add("EntityRemoved", "LOD_FreshHostilePresentationCleanup", function(ent)
    Safety.FirstSeen[ent] = nil
end)

concommand.Add("lod_hostile_presentation_status", function()
    print(string.format(
        "[LOD:HOSTILE-PRESENTATION] freshGuard=%.2fs forcedFreshDraws=%d installed=%s",
        FRESH_ENTITY_GUARD_SECONDS,
        Safety.ForcedFreshDraws or 0,
        tostring(((scripted_ents.GetStored("lod_hostile") or {}).t or {}).LODFreshPresentationGuardInstalled == true)))
end)
