LOD = LOD or {}
LOD.WatcherScanProgressionFix = LOD.WatcherScanProgressionFix or {
    dispatches = 0,
    advanced = 0,
    handled = 0
}

local Fix = LOD.WatcherScanProgressionFix

-- Watcher state authority must run before any of the later presentation/range
-- wrappers are allowed to hold ordinary movement. The committed-standoff layer
-- quite correctly stops generic pursuit inside the scan envelope, but because it
-- used to return before _RunWatcherTick it could also starve the scan state
-- machine itself: a Watcher would reach useful range, stand still, and never
-- start/advance a scan.
--
-- Dispatch _RunWatcherTick once at the outer edge of the normal Behaviour tick.
-- The Watcher core already carries a per-frame dispatch guard, so wrappers lower
-- in the chain cannot advance it twice in one server frame. No timer, Think hook,
-- alternate pathfinder, or second locomotion authority is introduced.
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

        local hadScan = self.LODWatcherScan ~= nil
        Fix.dispatches = (Fix.dispatches or 0) + 1
        local handled = self:_RunWatcherTick()
        if hadScan then Fix.advanced = (Fix.advanced or 0) + 1 end
        if handled then Fix.handled = (Fix.handled or 0) + 1 end

        -- A Watcher state transition owns this behaviour tick. In particular,
        -- never let generic pursuit run after a scan starts/completes or a retreat
        -- / concealment is armed in the same frame.
        if handled or self.LODWatcherScan or self.LODWatcherRetreat or self.LODWatcherConcealment then
            return
        end

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
        "dispatches=%d scanAdvances=%d handled=%d activeScans=%d retreating=%d concealing=%d installed=%s recurringService=false authority=outer-behaviour+RunWatcherTick",
        Fix.dispatches or 0,
        Fix.advanced or 0,
        Fix.handled or 0,
        activeScans,
        retreating,
        concealing,
        tostring((scripted_ents.GetStored("lod_hostile") or {}).t
            and (scripted_ents.GetStored("lod_hostile") or {}).t.LODWatcherScanProgressionFixed == true))
    print("[LOD:WATCHER-SCAN-PROGRESSION] " .. line)
    if IsValid(ply) then ply:ChatPrint(line) end
end)
