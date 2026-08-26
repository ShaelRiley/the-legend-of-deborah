LOD = LOD or {}
LOD.WatcherScanProgressionFix = LOD.WatcherScanProgressionFix or {advanced = 0}

local Fix = LOD.WatcherScanProgressionFix

-- The committed-retreat wrapper intentionally suppresses generic movement while
-- a Watcher is scanning. Its old early-return also suppressed the Watcher's own
-- scan state-machine tick, leaving a successfully-started scan frozen forever.
-- Keep the movement hold, but explicitly advance _RunWatcherTick once through the
-- normal Behaviour cadence while a scan is active. No timer or second movement
-- authority is introduced.
local function installPatch()
    local stored = scripted_ents.GetStored("lod_hostile")
    local class = stored and stored.t
    if not class or class.LODWatcherScanProgressionFixed or not class._BehaviourTick then return false end
    class.LODWatcherScanProgressionFixed = true

    local baseBehaviourTick = class._BehaviourTick
    function class:_BehaviourTick()
        if self.LODArchetypeId == "watcher" and self.LODWatcherScan then
            if self._RunWatcherTick then
                self:_RunWatcherTick()
                Fix.advanced = (Fix.advanced or 0) + 1
            end
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

    local line = string.format("advanced=%d installed=%s recurringService=false",
        Fix.advanced or 0,
        tostring((scripted_ents.GetStored("lod_hostile") or {}).t
            and (scripted_ents.GetStored("lod_hostile") or {}).t.LODWatcherScanProgressionFixed == true))
    print("[LOD:WATCHER-SCAN-PROGRESSION] " .. line)
    if IsValid(ply) then ply:ChatPrint(line) end
end)
