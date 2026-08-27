LOD = LOD or {}
LOD.ClientTopologyIdentity = LOD.ClientTopologyIdentity or {}
LOD.TopologySyncClient = LOD.TopologySyncClient or {}

local Identity = LOD.ClientTopologyIdentity
local Sync = LOD.TopologySyncClient

local function identityKey(epoch, level, seed, layoutAttempt, mazeAttempt)
    return table.concat({epoch, level, seed, layoutAttempt, mazeAttempt}, ":")
end

local function clearMapCache()
    local Map = LOD.Minimap
    if not Map then return end

    Map.level = nil
    Map.layers = 1
    Map.expectedCells = 0
    Map.expectedChunks = 0
    Map.receivedChunks = 0
    Map.cells = {}
    Map.byKey = {}
    Map.jailA = nil
    Map.jailB = nil
    Map.jailAKey = nil
    Map.jailBKey = nil

    if Map.cache then
        Map.cache.revision = (Map.cache.revision or 0) + 1
        Map.cache.indexedRevision = -1
        Map.cache.floorCells = {}
        Map.cache.floorStairs = {}
        Map.cache.floorGates = {}
        Map.cache.floorJail = {}
        Map.cache.adjacency = {}
        Map.cache.reach = nil
        Map.cache.topologyRevision = -1
        Map.cache.topologyFloor = -1
    end
end

local function clearWallCache()
    local Wall = LOD.WallVisualsClient
    if not Wall then return end

    for _, model in pairs(Wall.models or {}) do
        if IsValid(model) then model:Remove() end
    end

    Wall.logical = {}
    Wall.world = {}
    Wall.models = {}
    Wall.dirty = true
    Wall.nextModel = 1
    Wall.retryQueue = {}
    Wall.retryAttempts = {}
    Wall.failedModels = 0
    Wall.labelBuckets = {}
    Wall.sectionColors = {}
    Wall.seed = 0
    Wall.origin = nil
    Wall.lastOrigin = nil
end

local function requestMapIfOpen()
    local Map = LOD.Minimap
    if not Map or not Map.open then return end
    net.Start("LOD_MapRequest")
    net.SendToServer()
end

local function requestWalls()
    net.Start("LOD_WallVisualsRequest")
    net.SendToServer()
end

local function wallMatches(seed)
    local Wall = LOD.WallVisualsClient
    return Wall and tonumber(Wall.seed or 0) == tonumber(seed or -1)
end

local function verifyWallIdentity(expectedSeed, attempt)
    if Identity.seed ~= expectedSeed then return end
    if wallMatches(expectedSeed) then return end

    if attempt == 1 then clearWallCache() end
    requestWalls()
end

net.Receive("LOD_TopologyIdentity", function()
    local epoch = net.ReadUInt(32)
    local level = net.ReadUInt(20)
    local seed = net.ReadUInt(32)
    local layoutAttempt = net.ReadUInt(8)
    local mazeAttempt = net.ReadUInt(8)
    local key = identityKey(epoch, level, seed, layoutAttempt, mazeAttempt)

    if Identity.key == key then return end

    Identity.key = key
    Identity.epoch = epoch
    Identity.level = level
    Identity.seed = seed
    Identity.layoutAttempt = layoutAttempt
    Identity.mazeAttempt = mazeAttempt
    Identity.changedAt = CurTime()

    -- Level number alone is not a topology identity. A campaign restart, forced
    -- regeneration, or deterministic layout retry may still be "Level 1" while
    -- owning a completely different graph. Discard all old map topology now.
    clearMapCache()
    requestMapIfOpen()

    -- Wall models are clientside-only. If their manifest belongs to any other
    -- graph, remove them immediately so an obsolete container cannot occlude an
    -- otherwise open server corridor and create phantom combat through a wall.
    if not wallMatches(seed) then
        clearWallCache()
        requestWalls()
        timer.Simple(0.25, function() verifyWallIdentity(seed, 2) end)
        timer.Simple(1.00, function() verifyWallIdentity(seed, 3) end)
    end

    print(string.format(
        "[LOD:TOPOLOGY] client identity epoch=%d level=%d seed=%d layoutAttempt=%d mazeAttempt=%d",
        epoch, level, seed, layoutAttempt, mazeAttempt))
end)

concommand.Add("lod_topology_client_status", function()
    local Map = LOD.Minimap
    local Wall = LOD.WallVisualsClient
    local mapCells = Map and #(Map.cells or {}) or 0
    local wallModels = Wall and table.Count(Wall.models or {}) or 0
    local wallSegments = Wall and #(Wall.logical or {}) or 0

    print(string.format(
        "[LOD:TOPOLOGY-CLIENT] identity=%s expectedSeed=%s mapLevel=%s mapCells=%d wallSeed=%s wallSegments=%d wallModels=%d",
        tostring(Identity.key or "none"), tostring(Identity.seed or "none"),
        tostring(Map and Map.level or "none"), mapCells,
        tostring(Wall and Wall.seed or "none"), wallSegments, wallModels))
end)

concommand.Add("lod_client_hostiles", function()
    local ply = LocalPlayer()
    local found = 0
    for _, hostile in ipairs(ents.FindByClass("lod_hostile")) do
        if IsValid(hostile) then
            found = found + 1
            local dist = IsValid(ply) and math.sqrt(ply:GetPos():DistToSqr(hostile:GetPos())) or -1
            print(string.format(
                "[LOD:CLIENT-HOSTILE] #%d archetype=%s model=%s dist=%.0f noDraw=%s alpha=%d watcher=%s blinkUntil=%.2f invisibleUntil=%.2f",
                hostile:EntIndex(),
                tostring(hostile:GetNW2String("LOD_Archetype", "")),
                tostring(hostile:GetModel() or ""),
                dist,
                tostring(hostile:GetNoDraw()),
                hostile:GetColor().a or 255,
                tostring(hostile:GetNW2Bool("LOD_Watcher", false)),
                hostile:GetNW2Float("LOD_WatcherBlinkUntil", 0),
                hostile:GetNW2Float("LOD_WatcherInvisibleUntil", 0)))
        end
    end
    if found == 0 then print("[LOD:CLIENT-HOSTILE] no networked lod_hostile entities") end
end)
