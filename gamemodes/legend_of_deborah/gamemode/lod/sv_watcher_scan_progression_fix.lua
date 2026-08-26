LOD = LOD or {}
LOD.WatcherScanProgressionFix = LOD.WatcherScanProgressionFix or {
    dispatches = 0,
    advanced = 0,
    handled = 0,
    escapeDelegations = 0
}

local Fix = LOD.WatcherScanProgressionFix

-- Watcher state authority must run before the standoff wrappers can suppress
-- generic pursuit, otherwise a legal scan can be starved before it starts or
-- completes. Conversely, once retreat/concealment exists, sv_watcher_polish is
-- the unified physical-movement owner and must receive the Behaviour tick.
--
-- The previous revision fixed scan starvation but returned on any handled Watcher
-- state. LODWatcherConcealment deliberately makes _RunWatcherTick return true,
-- so that return also starved the unified retreat/concealment mover. The runtime
-- symptom was exact: scan succeeds, both retreating=1 and concealing=1, then the
-- Scanner stands motionless. This revision separates state progression from
-- escape locomotion instead of allowing either layer to pre-empt the other.
local function installPatch()
    local stored = scripted_ents.GetStored("lod_hostile")
    local class = stored and stored.t
    if not class or class.LODWatcherScanProgressionFixed or not class._BehaviourTick
        or not class._RunWatcherTick
    then
        return false
    end
    class.LODWatcherScanProgressionFixed = true

    local baseBehaviourTick = class._BehaviourTick
    function class:_BehaviourTick()
        if self.LODArchetypeId ~= "watcher" then return baseBehaviourTick(self) end

        -- Escape movement is already mutually exclusive with generic pursuit in
        -- the lower Watcher wrappers. Do not call _RunWatcherTick first here:
        -- concealment intentionally reports handled=true and would swallow the
        -- Behaviour tick before sv_watcher_polish can advance Motion V2.
        if self.LODWatcherConcealment or self.LODWatcherRetreat then
            Fix.escapeDelegations = (Fix.escapeDelegations or 0) + 1
            return baseBehaviourTick(self)
        end

        local hadScan = self.LODWatcherScan ~= nil
        Fix.dispatches = (Fix.dispatches or 0) + 1
        local handled = self:_RunWatcherTick()
        if hadScan then Fix.advanced = (Fix.advanced or 0) + 1 end
        if handled then Fix.handled = (Fix.handled or 0) + 1 end

        -- A scan may complete and arm retreat/concealment synchronously inside
        -- _RunWatcherTick. Hand that same tick to the unified escape layer so the
        -- first retreat step need not wait for another coroutine turn.
        if self.LODWatcherConcealment or self.LODWatcherRetreat then
            Fix.escapeDelegations = (Fix.escapeDelegations or 0) + 1
            return baseBehaviourTick(self)
        end

        -- Active scan owns the actor and keeps it stationary; generic pursuit is
        -- not allowed to run until the scan resolves.
        if handled or self.LODWatcherScan then return end

        return baseBehaviourTick(self)
    end
    return true
end

installPatch()
hook.Add("OnEntityCreated", "LOD_WatcherScanProgressionFixInstall", function(ent)
    if IsValid(ent) and ent:GetClass() == "lod_hostile" then installPatch() end
end)

concommand.Add("lod_watcher_scan_progression_status", function(ply)
    local cv = GetConVar("lod_developer_mode")
    if cv and not cv:GetBool() then return end
    if IsValid(ply) and not ply:IsAdmin() then return end

    local activeScans, retreating, concealing = 0, 0, 0
    for _, hostile in ipairs(LOD.HostileRegistry and LOD.HostileRegistry:List() or {}) do
        if IsValid(hostile) and not hostile.LODDead and hostile.LODArchetypeId == "watcher" then
            if hostile.LODWatcherScan then activeScans = activeScans + 1 end
            if hostile.LODWatcherRetreat then retreating = retreating + 1 end
            if hostile.LODWatcherConcealment then concealing = concealing + 1 end
        end
    end

    local line = string.format(
        "dispatches=%d scanAdvances=%d handled=%d escapeDelegations=%d activeScans=%d retreating=%d concealing=%d installed=%s recurringService=false authority=scan-state->polish-escape->MotionV2",
        Fix.dispatches or 0,
        Fix.advanced or 0,
        Fix.handled or 0,
        Fix.escapeDelegations or 0,
        activeScans,
        retreating,
        concealing,
        tostring((scripted_ents.GetStored("lod_hostile") or {}).t
            and (scripted_ents.GetStored("lod_hostile") or {}).t.LODWatcherScanProgressionFixed == true))
    print("[LOD:WATCHER-SCAN-PROGRESSION] " .. line)
    if IsValid(ply) then ply:ChatPrint(line) end
end)
