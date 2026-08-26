LOD = LOD or {}
LOD.Watcher = LOD.Watcher or {}

local Watcher = LOD.Watcher
local Navigator = LOD.MazeNavigator
local cellKey = LOD.MazeGenerator and LOD.MazeGenerator.CellKey

if not Navigator or not cellKey then return end

local function keyOf(cell)
    return cell and cellKey(cell.x, cell.y, cell.z) or nil
end

local function safeCell(graph, cell)
    local tag = graph and graph.CellTags and graph.CellTags[keyOf(cell)]
    return tag and tag.safe == true or false
end

local function installWatcherAcquisitionGuard()
    local stored = scripted_ents.GetStored("lod_hostile")
    local class = stored and stored.t
    if not class or class.LODWatcherAcquisitionGuardInstalled then return false end
    if not class._RunWatcherTick then return false end
    class.LODWatcherAcquisitionGuardInstalled = true

    local baseRunWatcherTick = class._RunWatcherTick
    function class:_RunWatcherTick()
        if self.LODArchetypeId ~= "watcher" then return baseRunWatcherTick(self) end

        -- The Watcher owns its target-refresh dependency explicitly. Previously
        -- it could enter its scan dispatcher before the generic movement tick had
        -- refreshed LODTarget, making scan start depend on wrapper/tick ordering.
        -- Reusing _RefreshTarget preserves the established authored/wanderer
        -- acquisition, safe-zone, same-floor, and leash rules rather than adding
        -- a second perception authority.
        if not self.LODWatcherScan then
            local state = LOD.RunManager and LOD.RunManager.State
            local graph = state and state.Graph
            if graph and state.BuildReady and not state.Failed and not state.LevelCleared then
                self:_RefreshTarget(graph)
            end
        end

        return baseRunWatcherTick(self)
    end

    return true
end

installWatcherAcquisitionGuard()
hook.Add("OnEntityCreated", "LOD_WatcherAcquisitionGuardInstall", function(ent)
    if IsValid(ent) and ent:GetClass() == "lod_hostile" then installWatcherAcquisitionGuard() end
end)

-- The original test command deliberately refuses to alter/teleport the player.
-- Add a preflight diagnostic that makes the GDD safe-zone rule explicit so a
-- valid non-scanning result is never mistaken for a Watcher implementation bug.
concommand.Add("lod_watcher_preflight", function(ply)
    local cv = GetConVar("lod_developer_mode")
    if cv and not cv:GetBool() then return end
    if not IsValid(ply) or not ply:IsAdmin() then return end

    local state = LOD.RunManager and LOD.RunManager.State
    local graph = state and state.Graph
    if not state or not graph or not state.BuildReady then
        ply:ChatPrint("Watcher preflight requires an active generated dungeon.")
        return
    end

    local cell = Navigator:WorldToCell(graph, ply:GetPos())
    local safe = cell and safeCell(graph, cell) or true
    local text = string.format("cell=%s safe=%s result=%s",
        cell and keyOf(cell) or "none", tostring(safe),
        cell and not safe and "PASS" or "MOVE_OUT_OF_SAFE_SPACE")
    print("[LOD:WATCHER-PREFLIGHT] " .. text)
    ply:ChatPrint(text)
end)
