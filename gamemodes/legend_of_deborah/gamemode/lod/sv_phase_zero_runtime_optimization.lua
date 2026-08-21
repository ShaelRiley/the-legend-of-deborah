LOD = LOD or {}
LOD.PhaseZeroOptimization = LOD.PhaseZeroOptimization or {}

local PhaseZero = LOD.PhaseZeroOptimization
local Navigator = LOD.MazeNavigator
local FactionManager = LOD.FactionManager
local EncounterDirector = LOD.EncounterDirector
local WanderingDirector = LOD.WanderingDirector
local cellKey = LOD.MazeGenerator.CellKey

-- Phase-Zero runtime optimization pass
--
-- Preserve the canonical graph and Motion V2 exactly as gameplay authorities,
-- while removing repeated table reconstruction / global searches from the hot
-- hostile path. All caches are attached to the current graph or invalidated by
-- short-lived player-state events, so level cleanup naturally drops them.

local NAV_TREE_LIMIT = 72
local ENCOUNTER_THINK_INTERVAL = 0.20
local TARGET_CACHE_SECONDS = 0.05

PhaseZero.Version = 1
PhaseZero.NavStats = PhaseZero.NavStats or {builds = 0, hits = 0, misses = 0}

local function keyOf(cell)
    return cell and cellKey(cell.x, cell.y, cell.z) or nil
end

local function gateSignature()
    local state = LOD.RunManager and LOD.RunManager.State
    local gates = state and state.GatesOpen or nil
    local signature = 0
    if gates and gates[1] then signature = signature + 1 end
    if gates and gates[2] then signature = signature + 2 end
    if gates and gates[3] then signature = signature + 4 end
    return signature
end

local function staticNeighborKeys(graph, sourceKey)
    graph.LODPhaseZeroNeighborKeys = graph.LODPhaseZeroNeighborKeys or {}
    local cached = graph.LODPhaseZeroNeighborKeys[sourceKey]
    if cached then return cached end

    local out = {}
    local cell = graph.Cells and graph.Cells[sourceKey]
    for neighborKey in pairs(cell and cell.neighbors or {}) do
        out[#out + 1] = neighborKey
    end
    table.sort(out)
    graph.LODPhaseZeroNeighborKeys[sourceKey] = out
    return out
end

local function staticGateMap(graph)
    local progression = graph and graph.Progression
    local gates = progression and progression.Gates or {}
    local gateCount = #gates
    if graph.LODPhaseZeroGateIndexByEdge and graph.LODPhaseZeroGateMapCount == gateCount then
        return graph.LODPhaseZeroGateIndexByEdge
    end

    local out = {}
    for index, gate in ipairs(gates) do
        if gate.edgeKey then out[gate.edgeKey] = index end
    end
    graph.LODPhaseZeroGateIndexByEdge = out
    graph.LODPhaseZeroGateMapCount = gateCount
    -- Progression is planned after the raw maze graph exists. If a navigation
    -- query happened before the three gate edges were assigned, discard those
    -- ungated trees rather than letting them leak into runtime traversal.
    graph.LODPhaseZeroNavCache = nil
    return out
end

local function currentNavCache(graph)
    local signature = gateSignature()
    local cache = graph.LODPhaseZeroNavCache
    if cache and cache.signature == signature then return cache end

    cache = {
        signature = signature,
        trees = {},
        order = {}
    }
    graph.LODPhaseZeroNavCache = cache
    return cache
end

local function edgeTraversable(graph, cache, aKey, bKey)
    local edge = Navigator:EdgeKey(aKey, bKey)
    local gateIndex = edge and staticGateMap(graph)[edge] or nil
    if not gateIndex then return true end
    local state = LOD.RunManager and LOD.RunManager.State
    return state and state.GatesOpen and state.GatesOpen[gateIndex] == true or false
end

local function rememberTree(cache, sourceKey, tree)
    cache.trees[sourceKey] = tree
    cache.order[#cache.order + 1] = sourceKey
    if #cache.order <= NAV_TREE_LIMIT then return end

    local evicted = table.remove(cache.order, 1)
    if evicted and evicted ~= sourceKey then cache.trees[evicted] = nil end
end

local function buildTree(graph, cache, sourceKey)
    if not graph.Cells or not graph.Cells[sourceKey] then return nil end

    local queue = {sourceKey}
    local head = 1
    local distance = {[sourceKey] = 0}
    local parent = {}

    while head <= #queue do
        local currentKey = queue[head]
        head = head + 1
        for _, neighborKey in ipairs(staticNeighborKeys(graph, currentKey)) do
            if distance[neighborKey] == nil and edgeTraversable(graph, cache, currentKey, neighborKey) then
                distance[neighborKey] = distance[currentKey] + 1
                parent[neighborKey] = currentKey
                queue[#queue + 1] = neighborKey
            end
        end
    end

    local tree = {source = sourceKey, distance = distance, parent = parent}
    rememberTree(cache, sourceKey, tree)
    PhaseZero.NavStats.builds = (PhaseZero.NavStats.builds or 0) + 1
    return tree
end

local function treeFor(graph, sourceKey)
    local cache = currentNavCache(graph)
    local tree = cache.trees[sourceKey]
    if tree then
        PhaseZero.NavStats.hits = (PhaseZero.NavStats.hits or 0) + 1
        return tree
    end

    PhaseZero.NavStats.misses = (PhaseZero.NavStats.misses or 0) + 1
    return buildTree(graph, cache, sourceKey)
end

if Navigator and not Navigator.LODPhaseZeroPatched then
    Navigator.LODPhaseZeroPatched = true

    function Navigator:SortedNeighborKeys(graph, cellOrKey)
        if not graph then return {} end
        local sourceKey = isstring(cellOrKey) and cellOrKey or keyOf(cellOrKey)
        return sourceKey and staticNeighborKeys(graph, sourceKey) or {}
    end

    function Navigator:CanTraverse(graph, aKey, bKey)
        if not graph or not aKey or not bKey then return false end
        local cache = currentNavCache(graph)
        return edgeTraversable(graph, cache, aKey, bKey)
    end

    function Navigator:Distance(graph, startCell, goalCell)
        if not graph or not startCell or not goalCell then return math.huge end
        local startKey = keyOf(startCell)
        local goalKey = keyOf(goalCell)
        if not startKey or not goalKey or not graph.Cells[startKey] or not graph.Cells[goalKey] then return math.huge end
        if startKey == goalKey then return 0 end

        local tree = treeFor(graph, startKey)
        local distance = tree and tree.distance[goalKey] or nil
        return distance ~= nil and distance or math.huge
    end

    function Navigator:FindPath(graph, startCell, goalCell)
        if not graph or not startCell or not goalCell then return nil end
        local startKey = keyOf(startCell)
        local goalKey = keyOf(goalCell)
        if not startKey or not goalKey or not graph.Cells[startKey] or not graph.Cells[goalKey] then return nil end
        if startKey == goalKey then return {graph.Cells[startKey]} end

        -- Always root the cached BFS at the requested start cell. This preserves
        -- the original deterministic shortest-path tie-breaking regardless of
        -- which other distance queries happened to run earlier in the frame.
        local tree = treeFor(graph, startKey)
        if not tree or tree.distance[goalKey] == nil then return nil end

        local reverse = {goalKey}
        local cursor = goalKey
        while cursor ~= startKey do
            cursor = tree.parent[cursor]
            if not cursor then return nil end
            reverse[#reverse + 1] = cursor
        end

        local path = {}
        for i = #reverse, 1, -1 do
            path[#path + 1] = graph.Cells[reverse[i]]
        end
        return path
    end
end

-- --------------------------------------------------------------------------
-- Stable hostile registry: global entity enumeration is never part of LOS.
-- --------------------------------------------------------------------------
LOD.HostileRegistry = LOD.HostileRegistry or {set = {}, list = {}, dirty = true}
local HostileRegistry = LOD.HostileRegistry

function HostileRegistry:Track(ent)
    if not IsValid(ent) or ent:GetClass() ~= "lod_hostile" or self.set[ent] then return end
    self.set[ent] = true
    self.dirty = true
end

function HostileRegistry:Forget(ent)
    if not self.set[ent] then return end
    self.set[ent] = nil
    self.dirty = true
end

function HostileRegistry:List()
    if not self.dirty then return self.list end
    local out = {}
    for ent in pairs(self.set) do
        if IsValid(ent) and ent:GetClass() == "lod_hostile" then
            out[#out + 1] = ent
        else
            self.set[ent] = nil
        end
    end
    self.list = out
    self.dirty = false
    return out
end

for _, ent in ipairs(ents.FindByClass("lod_hostile")) do HostileRegistry:Track(ent) end

hook.Add("OnEntityCreated", "LOD_PhaseZeroTrackHostile", function(ent)
    if IsValid(ent) and ent:GetClass() == "lod_hostile" then HostileRegistry:Track(ent) end
end)

hook.Add("EntityRemoved", "LOD_PhaseZeroForgetHostile", function(ent)
    HostileRegistry:Forget(ent)
end)

local function installHostileTracePatch()
    local stored = scripted_ents.GetStored("lod_hostile")
    local class = stored and stored.t
    if not class or class.LODPhaseZeroTracePatched then return false end
    class.LODPhaseZeroTracePatched = true

    -- The old path rebuilt ents.FindByClass("lod_hostile") for every LOS trace;
    -- GeneratedGeometryBallistics then performed an additional cover trace. One
    -- MASK_SOLID trace is sufficient: it sees generated walls/floors, while the
    -- shared registry filter makes allied hostiles transparent to perception.
    function class:_IgnoredShotEntities()
        return HostileRegistry:List()
    end

    function class:_HasLineOfSight(target)
        if not IsValid(target) then return false end
        local tr = util.TraceLine({
            start = self:WorldSpaceCenter() + Vector(0, 0, 12),
            endpos = target:WorldSpaceCenter(),
            mask = MASK_SOLID,
            filter = HostileRegistry:List()
        })
        return tr.Entity == target or tr.Fraction >= 0.995
    end

    return true
end

installHostileTracePatch()
hook.Add("OnEntityCreated", "LOD_PhaseZeroInstallHostileTrace", function(ent)
    if IsValid(ent) and ent:GetClass() == "lod_hostile" then installHostileTracePatch() end
end)

-- --------------------------------------------------------------------------
-- Player target snapshots: 20 Hz cache, event-invalidated on life/connect state.
-- --------------------------------------------------------------------------
if FactionManager and not FactionManager.LODPhaseZeroTargetsPatched then
    FactionManager.LODPhaseZeroTargetsPatched = true
    local baseLivingTargets = FactionManager.LivingTargets

    function FactionManager:InvalidateLivingTargets()
        self.LODLivingTargetsUntil = 0
        self.LODLivingTargetsCache = nil
    end

    function FactionManager:LivingTargets()
        local now = CurTime()
        if self.LODLivingTargetsCache and now < (self.LODLivingTargetsUntil or 0) then
            return self.LODLivingTargetsCache
        end
        local targets = baseLivingTargets(self)
        self.LODLivingTargetsCache = targets
        self.LODLivingTargetsUntil = now + TARGET_CACHE_SECONDS
        return targets
    end

    local function invalidateTargets()
        if LOD.FactionManager and LOD.FactionManager.InvalidateLivingTargets then
            LOD.FactionManager:InvalidateLivingTargets()
        end
    end

    hook.Add("PlayerInitialSpawn", "LOD_PhaseZeroTargetJoin", invalidateTargets)
    hook.Add("PlayerSpawn", "LOD_PhaseZeroTargetSpawn", invalidateTargets)
    hook.Add("PlayerDeath", "LOD_PhaseZeroTargetDeath", invalidateTargets)
    hook.Add("PlayerDisconnected", "LOD_PhaseZeroTargetLeave", invalidateTargets)
end

-- --------------------------------------------------------------------------
-- Encounter activation is tactical, not a frame-rate task. Four checks/second
-- still detects a player well before crossing a four-cell activation radius.
-- --------------------------------------------------------------------------
if EncounterDirector and not EncounterDirector.LODPhaseZeroThinkPatched then
    EncounterDirector.LODPhaseZeroThinkPatched = true
    local baseThink = EncounterDirector.Think

    function EncounterDirector:Think()
        local now = CurTime()
        local state = LOD.RunManager and LOD.RunManager.State
        local graph = state and state.Graph
        if graph ~= self.LODPhaseZeroThinkGraph then
            self.LODPhaseZeroThinkGraph = graph
            self.LODPhaseZeroNextThink = 0
        end
        if now < (self.LODPhaseZeroNextThink or 0) then return end
        self.LODPhaseZeroNextThink = now + ENCOUNTER_THINK_INTERVAL
        return baseThink(self)
    end
end

-- Wanderer spawn-cell eligibility is immutable for a generated graph. The
-- original helper rescanned and resorted every cell for every replacement and
-- for each of the 16 initial spawns per floor; memoize the exact original result.
if WanderingDirector and not WanderingDirector.LODPhaseZeroFloorCellsPatched then
    WanderingDirector.LODPhaseZeroFloorCellsPatched = true
    local baseFloorCells = WanderingDirector._FloorCells

    function WanderingDirector:_FloorCells(graph, floor)
        if not graph then return {} end
        graph.LODPhaseZeroWanderFloorCells = graph.LODPhaseZeroWanderFloorCells or {}
        local cached = graph.LODPhaseZeroWanderFloorCells[floor]
        if cached then return cached end
        cached = baseFloorCells(self, graph, floor)
        graph.LODPhaseZeroWanderFloorCells[floor] = cached
        return cached
    end
end

concommand.Add("lod_phase0_perf", function(ply)
    local cv = GetConVar("lod_developer_mode")
    if cv and not cv:GetBool() then return end
    if IsValid(ply) and not ply:IsAdmin() then return end

    local state = LOD.RunManager and LOD.RunManager.State
    local graph = state and state.Graph
    local navCache = graph and graph.LODPhaseZeroNavCache
    local treeCount = navCache and table.Count(navCache.trees or {}) or 0
    local hostileCount = #HostileRegistry:List()
    local stats = PhaseZero.NavStats or {}
    local line = string.format(
        "hostiles=%d navTrees=%d navBuilds=%d navHits=%d navMisses=%d gateState=%d encounterHz=%.1f",
        hostileCount, treeCount, stats.builds or 0, stats.hits or 0, stats.misses or 0,
        gateSignature(), 1 / ENCOUNTER_THINK_INTERVAL
    )
    print("[LOD:PHASE0] " .. line)
    if IsValid(ply) then ply:ChatPrint(line) end
end)


concommand.Add("lod_hostile_registry_status", function(ply)
    local cv = GetConVar("lod_developer_mode")
    if cv and not cv:GetBool() then return end
    if IsValid(ply) and not ply:IsAdmin() then return end

    local registered = #HostileRegistry:List()
    local actual = 0
    for _, hostile in ipairs(ents.FindByClass("lod_hostile")) do
        if IsValid(hostile) and hostile.LODHostile then actual = actual + 1 end
    end

    local passed = registered == actual
    local line = string.format(
        "registered=%d actual=%d consolidatedHotHooks=5 result=%s",
        registered, actual, passed and "PASS" or "FAIL"
    )
    print("[LOD:HOSTILE-REGISTRY] " .. line)
    if IsValid(ply) then ply:ChatPrint(line) end
end)
