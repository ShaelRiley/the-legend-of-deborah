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

            -- Make scan acquisition independent of wrapper/tick ordering while
            -- retaining the existing authored/wanderer target authority. The
            -- previous Watcher dispatcher could run before generic movement had
            -- refreshed LODTarget, leaving a valid scanner permanently idle.
            if not self.LODWatcherScan then
                local state = LOD.RunManager and LOD.RunManager.State
                local graph = state and state.Graph
                if graph and state.BuildReady and not state.Failed and not state.LevelCleared then
                    self:_RefreshTarget(graph)
                end
            end

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
-- The original test command did not expose that prerequisite, so an otherwise
-- correct non-scan could look like a broken implementation. This preflight makes
-- the graph rule observable without teleporting or mutating the player.
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
