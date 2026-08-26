LOD = LOD or {}
LOD.Watcher = LOD.Watcher or {}

local Watcher = LOD.Watcher
local Navigator = LOD.MazeNavigator
local cellKey = LOD.MazeGenerator and LOD.MazeGenerator.CellKey

local WATCHER_SCAN_SERVICE = "LOD_WatcherScanService"
local WATCHER_SCAN_INTERVAL = 0.10

Watcher.ScanServiceTicks = Watcher.ScanServiceTicks or 0
Watcher.ScanServiceCalls = Watcher.ScanServiceCalls or 0

local function keyOf(cell)
    return cell and cellKey and cellKey(cell.x, cell.y, cell.z) or nil
end

local function safeCell(graph, cell)
    local tag = graph and graph.CellTags and graph.CellTags[keyOf(cell)]
    return tag and tag.safe == true or false
end

local function installWatcherGuards()
    local stored = scripted_ents.GetStored("lod_hostile")
    local class = stored and stored.t
    if not class then return false end

    if not class.LODWatcherAttackGuardInstalled then
        class.LODWatcherAttackGuardInstalled = true
        local baseTryAttack = class._TryAttack
        function class:_TryAttack(target)
            if self.LODArchetypeId == "watcher" then return false end
            return baseTryAttack(self, target)
        end
    end

    if not class.LODWatcherAcquisitionGuardInstalled and class._RunWatcherTick then
        class.LODWatcherAcquisitionGuardInstalled = true
        local baseRunWatcherTick = class._RunWatcherTick
        function class:_RunWatcherTick()
            if self.LODArchetypeId ~= "watcher" then return baseRunWatcherTick(self) end

            local now = CurTime()
            if now < (self.LODWatcherGuardNextTick or 0) then
                return self.LODWatcherScan ~= nil
            end
            self.LODWatcherGuardNextTick = now + 0.045
            self.LODWatcherGuardTicks = (self.LODWatcherGuardTicks or 0) + 1

            -- Make scan acquisition independent of wrapper/coroutine ordering
            -- while retaining the canonical authored/wanderer target authority.
            if not self.LODWatcherScan then
                local state = LOD.RunManager and LOD.RunManager.State
                local graph = state and state.Graph
                if graph and state.BuildReady and not state.Failed and not state.LevelCleared then
                    self:_RefreshTarget(graph)
                end
            end

            -- The original Watcher dispatcher used FrameNumber() as a same-frame
            -- duplicate guard. Runtime evidence showed that this can strand a
            -- scanner after its first dispatch on the server. The bounded CurTime
            -- cadence above now owns de-duplication, so clear that legacy guard
            -- immediately before invoking the original Watcher state machine.
            self.LODWatcherDispatchFrame = nil
            self.LODWatcherGuardTarget = self.LODTarget
            self.LODWatcherGuardFrame = FrameNumber()
            return baseRunWatcherTick(self)
        end
    end

    return true
end

installWatcherGuards()
hook.Add("OnEntityCreated", "LOD_WatcherGuardInstall", function(ent)
    if IsValid(ent) and ent:GetClass() == "lod_hostile" then installWatcherGuards() end
end)

-- Watcher scanning is a support-state machine, not locomotion. Run it from one
-- bounded shared service rather than relying on a specific NextBot coroutine
-- cadence. Motion V2 remains the sole movement authority; _RefreshTarget remains
-- the sole acquisition authority; the Watcher module still owns LOS/scan/alert.
-- At the production hostile ceiling this is at most a few hundred trivial
-- archetype checks per second and allocates no per-Watcher timers.
timer.Create(WATCHER_SCAN_SERVICE, WATCHER_SCAN_INTERVAL, 0, function()
    local state = LOD.RunManager and LOD.RunManager.State
    if not state or not state.Graph or not state.BuildReady or state.Failed or state.LevelCleared
        or state.SimulationFrozen
    then
        return
    end

    Watcher.ScanServiceTicks = (Watcher.ScanServiceTicks or 0) + 1
    for _, hostile in ipairs(LOD.HostileRegistry and LOD.HostileRegistry:List() or {}) do
        if IsValid(hostile) and not hostile.LODDead and hostile.LODArchetypeId == "watcher"
            and hostile._RunWatcherTick
        then
            Watcher.ScanServiceCalls = (Watcher.ScanServiceCalls or 0) + 1
            hostile.LODWatcherServiceCalls = (hostile.LODWatcherServiceCalls or 0) + 1
            hostile:_RunWatcherTick()
        end
    end
end)

-- The production Watcher must ignore players in checkpoint/spawn safe space.
concommand.Add("lod_watcher_preflight", function(ply)
    local cv = GetConVar("lod_developer_mode")
    if cv and not cv:GetBool() then return end
    if not IsValid(ply) or not ply:IsAdmin() then return end

    local state = LOD.RunManager and LOD.RunManager.State
    local graph = state and state.Graph
    if not state or not graph or not state.BuildReady or not Navigator then
        ply:ChatPrint("Watcher preflight requires an active generated dungeon.")
        return
    end

    local cell = Navigator:WorldToCell(graph, ply:GetPos())
    local safe = not cell or safeCell(graph, cell)
    local text = string.format("cell=%s safe=%s result=%s",
        cell and keyOf(cell) or "none", tostring(safe),
        not safe and "PASS" or "MOVE_OUT_OF_SAFE_SPACE")
    print("[LOD:WATCHER-PREFLIGHT] " .. text)
    ply:ChatPrint(text)
end)

-- One-shot diagnosis for the pre-scan gate. It performs no persistent work and
-- uses the same shared LOS helper used by ordinary hostile perception.
concommand.Add("lod_watcher_dispatch_status", function(ply)
    local cv = GetConVar("lod_developer_mode")
    if cv and not cv:GetBool() then return end
    if IsValid(ply) and not ply:IsAdmin() then return end

    local state = LOD.RunManager and LOD.RunManager.State
    local graph = state and state.Graph
    local list = LOD.HostileRegistry and LOD.HostileRegistry:List() or {}
    local found = 0

    for _, watcher in ipairs(list) do
        if IsValid(watcher) and not watcher.LODDead and watcher.LODArchetypeId == "watcher" then
            found = found + 1
            local target = watcher.LODTarget
            local wc = graph and Navigator and Navigator:WorldToCell(graph, watcher:GetPos()) or nil
            local tc = graph and Navigator and IsValid(target) and Navigator:WorldToCell(graph, target:GetPos()) or nil
            local los = IsValid(target) and watcher._HasLineOfSight and watcher:_HasLineOfSight(target) or false
            local sameFloor = wc and tc and wc.z == tc.z or false
            local targetSafe = tc and safeCell(graph, tc) or false
            local nextScan = math.max(0, (watcher.LODNextWatcherScan or 0) - CurTime())
            local nextRefresh = math.max(0, (watcher.LODNextTargetRefresh or 0) - CurTime())
            local line = string.format(
                "#%d ticks=%d service=%d target=%s watcherCell=%s targetCell=%s sameFloor=%s targetSafe=%s sharedLOS=%s scanning=%s nextScan=%.2f nextRefresh=%.2f",
                watcher:EntIndex(), watcher.LODWatcherGuardTicks or 0,
                watcher.LODWatcherServiceCalls or 0,
                IsValid(target) and ("#" .. target:EntIndex()) or "none",
                wc and keyOf(wc) or "none", tc and keyOf(tc) or "none",
                tostring(sameFloor), tostring(targetSafe), tostring(los),
                tostring(watcher.LODWatcherScan ~= nil), nextScan, nextRefresh)
            print("[LOD:WATCHER-DISPATCH] " .. line)
            if IsValid(ply) then ply:ChatPrint(line) end
        end
    end

    local serviceLine = string.format("serviceTicks=%d serviceCalls=%d interval=%.2fs",
        Watcher.ScanServiceTicks or 0, Watcher.ScanServiceCalls or 0, WATCHER_SCAN_INTERVAL)
    print("[LOD:WATCHER-DISPATCH] " .. serviceLine)
    if IsValid(ply) then ply:ChatPrint(serviceLine) end

    if found == 0 then
        print("[LOD:WATCHER-DISPATCH] no live Watchers")
        if IsValid(ply) then ply:ChatPrint("no live Watchers") end
    end
end)
