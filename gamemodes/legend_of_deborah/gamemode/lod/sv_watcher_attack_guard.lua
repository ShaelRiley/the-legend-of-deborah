LOD = LOD or {}
LOD.Watcher = LOD.Watcher or {}

local Navigator = LOD.MazeNavigator
local cellKey = LOD.MazeGenerator and LOD.MazeGenerator.CellKey

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

            self.LODWatcherGuardTicks = (self.LODWatcherGuardTicks or 0) + 1

            -- Make scan acquisition independent of wrapper/tick ordering while
            -- retaining the existing authored/wanderer target authority. The
            -- Watcher dispatcher can run before generic movement has refreshed
            -- LODTarget, so explicitly give the canonical target refresher its
            -- normal cadence here as well.
            if not self.LODWatcherScan then
                local state = LOD.RunManager and LOD.RunManager.State
                local graph = state and state.Graph
                if graph and state.BuildReady and not state.Failed and not state.LevelCleared then
                    self:_RefreshTarget(graph)
                end
            end

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

-- The production Watcher must ignore players in checkpoint/spawn safe space.
-- The test command exposes that prerequisite so a correct non-scan is not
-- mistaken for a broken scanner.
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
-- uses the same shared LOS helper used by ordinary hostile perception, allowing
-- runtime evidence to distinguish a missing Watcher dispatch from target/LOS
-- rejection without adding telemetry or another gameplay authority.
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
                "#%d ticks=%d target=%s watcherCell=%s targetCell=%s sameFloor=%s targetSafe=%s sharedLOS=%s scanning=%s nextScan=%.2f nextRefresh=%.2f",
                watcher:EntIndex(), watcher.LODWatcherGuardTicks or 0,
                IsValid(target) and ("#" .. target:EntIndex()) or "none",
                wc and keyOf(wc) or "none", tc and keyOf(tc) or "none",
                tostring(sameFloor), tostring(targetSafe), tostring(los),
                tostring(watcher.LODWatcherScan ~= nil), nextScan, nextRefresh)
            print("[LOD:WATCHER-DISPATCH] " .. line)
            if IsValid(ply) then ply:ChatPrint(line) end
        end
    end

    if found == 0 then
        print("[LOD:WATCHER-DISPATCH] no live Watchers")
        if IsValid(ply) then ply:ChatPrint("no live Watchers") end
    end
end)