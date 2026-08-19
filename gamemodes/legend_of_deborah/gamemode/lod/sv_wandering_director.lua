LOD = LOD or {}
LOD.WanderingDirector = LOD.WanderingDirector or {}

local WanderingDirector = LOD.WanderingDirector
local EC = LOD.Config.Encounter
local Navigator = LOD.MazeNavigator
local cellKey = LOD.MazeGenerator.CellKey

-- Production roaming layer. These enemies exist in addition to the authored
-- encounter plan and deliberately keep ordinary traversal from feeling empty.
-- Values live together here so the population can be tuned without scattering
-- magic numbers through the AI implementation.
local WC = {
    PerFloor = 16,
    RespawnSeconds = 20,
    AcquireCells = 4,
    DisengageCells = 6,
    WanderStepsMin = 3,
    WanderStepsMax = 8,
    SpawnPlayerClearanceCells = 4,
    ThinkInterval = 0.25,
    ArchetypeWeights = {
        shambler = 45,
        runner = 25,
        soldier = 12,
        deadcrab = 10,
        bioblaster = 8
    }
}

WanderingDirector.Config = WC
WanderingDirector.Entities = WanderingDirector.Entities or {}
WanderingDirector.NextRespawn = WanderingDirector.NextRespawn or {}
WanderingDirector.SpawnOrdinal = WanderingDirector.SpawnOrdinal or {}
WanderingDirector.Graph = WanderingDirector.Graph or nil
WanderingDirector.NextThink = WanderingDirector.NextThink or 0

local function keyOf(cell)
    return cell and cellKey(cell.x, cell.y, cell.z) or nil
end

local function sortedKeys(t)
    local out = {}
    for k in pairs(t or {}) do out[#out + 1] = k end
    table.sort(out)
    return out
end

local function livingWanderer(ent)
    return IsValid(ent) and ent.LODHostile and ent.LODWanderer == true and not ent.LODDead
end

local function safeCell(graph, cell)
    local tag = graph and graph.CellTags and graph.CellTags[keyOf(cell)]
    return tag and (tag.safe == true or tag.role == "boss") or false
end

local function eligibleWanderCell(graph, cell)
    return cell and not safeCell(graph, cell)
end

function WanderingDirector:_FloorCells(graph, floor)
    local out = {}
    for _, key in ipairs(sortedKeys(graph and graph.Cells or {})) do
        local cell = graph.Cells[key]
        if cell and cell.z == floor and eligibleWanderCell(graph, cell) then
            out[#out + 1] = cell
        end
    end
    return out
end

function WanderingDirector:_LivingOnFloor(floor)
    local count = 0
    local kept = {}
    for _, ent in ipairs(self.Entities or {}) do
        if IsValid(ent) then
            kept[#kept + 1] = ent
            if livingWanderer(ent) and ent.LODWanderFloor == floor then count = count + 1 end
        end
    end
    self.Entities = kept
    return count
end

function WanderingDirector:GetTargetPopulation(graph)
    graph = graph or (LOD.RunManager and LOD.RunManager.State.Graph)
    if not graph then return 0 end
    return math.max(0, graph.Layers or 0) * WC.PerFloor
end

function WanderingDirector:GetDeficitReservation(graph)
    graph = graph or (LOD.RunManager and LOD.RunManager.State.Graph)
    if not graph then return 0 end
    local deficit = 0
    for floor = 0, math.max(0, (graph.Layers or 1) - 1) do
        deficit = deficit + math.max(0, WC.PerFloor - self:_LivingOnFloor(floor))
    end
    return deficit
end

local function playerCells(graph)
    local out = {}
    for _, ply in ipairs(LOD.FactionManager and LOD.FactionManager:LivingTargets() or {}) do
        local cell = Navigator:WorldToCell(graph, ply:GetPos())
        if cell then out[#out + 1] = cell end
    end
    return out
end

function WanderingDirector:_SpawnCandidates(graph, floor, rng)
    local cells = self:_FloorCells(graph, floor)
    local players = playerCells(graph)
    local preferred = {}
    local fallback = {}

    for _, cell in ipairs(cells) do
        local farEnough = true
        for _, playerCell in ipairs(players) do
            if playerCell.z == floor then
                local distance = Navigator:Distance(graph, playerCell, cell)
                if distance ~= math.huge and distance < WC.SpawnPlayerClearanceCells then
                    farEnough = false
                    break
                end
            end
        end
        if farEnough then preferred[#preferred + 1] = cell end
        fallback[#fallback + 1] = cell
    end

    rng:Shuffle(preferred)
    rng:Shuffle(fallback)
    return #preferred > 0 and preferred or fallback
end

local function weightedArchetype(rng)
    local total = 0
    local candidates = {}
    for id, weight in pairs(WC.ArchetypeWeights) do
        if weight > 0 and EC.Archetypes[id] then
            total = total + weight
            candidates[#candidates + 1] = {id = id, weight = weight}
        end
    end
    table.sort(candidates, function(a, b) return a.id < b.id end)
    if total <= 0 then return EC.Archetypes.shambler and "shambler" or candidates[1] and candidates[1].id end

    local roll = rng:Float(0, total)
    local cursor = 0
    for _, item in ipairs(candidates) do
        cursor = cursor + item.weight
        if roll <= cursor then return item.id end
    end
    return candidates[#candidates] and candidates[#candidates].id or "shambler"
end

function WanderingDirector:_SpawnOne(graph, floor, reason)
    local state = LOD.RunManager and LOD.RunManager.State
    if not state or not state.BuildReady or state.Failed or state.LevelCleared then return false end

    self.SpawnOrdinal[floor] = (self.SpawnOrdinal[floor] or 0) + 1
    local ordinal = self.SpawnOrdinal[floor]
    local seed = LOD.Seeds.Derive(state.LevelSeed or graph.LevelSeed or 1,
        string.format("wanderer:%d:%d", floor, ordinal))
    local rng = LOD.RNG.New(seed)
    local candidates = self:_SpawnCandidates(graph, floor, rng:Derive("spawn-cell"))
    local cell = candidates[1]
    if not cell then return false end

    local archetype = weightedArchetype(rng:Derive("archetype"))
    if not archetype or not EC.Archetypes[archetype] then return false end

    local ent = ents.Create("lod_hostile")
    if not IsValid(ent) then return false end

    local spawnKey = keyOf(cell)
    ent.LODArchetypeId = archetype
    ent.LODHomeCellKey = spawnKey
    ent.LODEncounterId = nil
    ent.LODEncounterOrdinal = 900000 + floor * 10000 + ordinal
    ent.LODWanderer = true
    ent.LODWanderFloor = floor
    ent.LODWanderAnchorCellKey = spawnKey
    ent.LODWanderSeed = seed
    ent.LODActivated = true
    ent:SetPos(Navigator:CellCenter(cell) + Vector(0, 0, 10))
    ent:Spawn()
    ent:Activate()

    self.Entities[#self.Entities + 1] = ent
    if LOD.EncounterDirector then
        LOD.EncounterDirector.Entities = LOD.EncounterDirector.Entities or {}
        LOD.EncounterDirector.Entities[#LOD.EncounterDirector.Entities + 1] = ent
    end

    print(string.format("[LOD:WANDER] spawned #%d floor=%d archetype=%s cell=%s reason=%s",
        ent:EntIndex(), floor + 1, archetype, spawnKey, tostring(reason or "population")))
    return true
end

function WanderingDirector:_InitializeForGraph(graph)
    self.Graph = graph
    self.Entities = {}
    self.NextRespawn = {}
    self.SpawnOrdinal = {}

    for floor = 0, math.max(0, (graph.Layers or 1) - 1) do
        for _ = 1, WC.PerFloor do
            self:_SpawnOne(graph, floor, "initial")
        end
        self.NextRespawn[floor] = nil
    end

    print(string.format("[LOD:WANDER] initialized floors=%d target=%d",
        graph.Layers or 1, self:GetTargetPopulation(graph)))
end

local function currentCellFor(hostile, graph)
    return Navigator:WorldToCell(graph, hostile:GetPos())
end

local function targetCellFor(target, graph)
    return IsValid(target) and Navigator:WorldToCell(graph, target:GetPos()) or nil
end

local function bestNearbyTarget(hostile, graph, maximum)
    local current = currentCellFor(hostile, graph)
    if not current then return nil, math.huge end

    local best, bestDistance, bestWorld
    for _, ply in ipairs(LOD.FactionManager:LivingTargets()) do
        local targetCell = targetCellFor(ply, graph)
        if targetCell and targetCell.z == hostile.LODWanderFloor then
            local distance = Navigator:Distance(graph, current, targetCell)
            if distance ~= math.huge and distance <= maximum then
                local world = hostile:GetPos():DistToSqr(ply:GetPos())
                if not best or distance < bestDistance or (distance == bestDistance and world < bestWorld) then
                    best, bestDistance, bestWorld = ply, distance, world
                end
            end
        end
    end
    return best, bestDistance or math.huge
end

local function installWandererAIPatch()
    local stored = scripted_ents.GetStored("lod_hostile")
    local class = stored and stored.t
    if not class or class.LODWandererAIPatched then return false end
    class.LODWandererAIPatched = true

    local baseRefreshTarget = class._RefreshTarget
    function class:_RefreshTarget(graph)
        if not self.LODWanderer then return baseRefreshTarget(self, graph) end
        if CurTime() < (self.LODNextTargetRefresh or 0) then return end
        self.LODNextTargetRefresh = CurTime() + EC.TargetRefreshSeconds

        local current = currentCellFor(self, graph)
        local existing = self.LODTarget
        if IsValid(existing) and current then
            local targetCell = targetCellFor(existing, graph)
            local distance = targetCell and targetCell.z == self.LODWanderFloor
                and Navigator:Distance(graph, current, targetCell) or math.huge
            if distance <= WC.DisengageCells and not safeCell(graph, targetCell) then
                self.LODReturningHome = false
                return
            end
        end

        if IsValid(existing) then
            self.LODTarget = nil
            self.LODWaypoints = {}
            self.LODWaypointIndex = 1
            self.LODNextRouteRefresh = 0
        end

        local target = bestNearbyTarget(self, graph, WC.AcquireCells)
        local targetCell = IsValid(target) and targetCellFor(target, graph) or nil
        if IsValid(target) and not safeCell(graph, targetCell) then
            self.LODTarget = target
            self.LODReturningHome = false
            self.LODWaypoints = {}
            self.LODWaypointIndex = 1
            self.LODNextRouteRefresh = 0
        else
            self.LODTarget = nil
            self.LODReturningHome = false
        end
    end

    local function chooseWanderPath(hostile, graph, current)
        local rng = hostile.LODWanderRNG
        if not rng then
            rng = LOD.RNG.New(LOD.Seeds.Derive(hostile.LODWanderSeed or 1, "wander-path"))
            hostile.LODWanderRNG = rng
        end

        local steps = rng:Int(WC.WanderStepsMin, WC.WanderStepsMax)
        local path = {}
        local cursor = current
        local previousKey

        for _ = 1, steps do
            local cursorKey = keyOf(cursor)
            local choices = {}
            local fallback = {}
            for _, neighborKey in ipairs(sortedKeys(cursor.neighbors or {})) do
                local neighbor = graph.Cells[neighborKey]
                if neighbor and neighbor.z == hostile.LODWanderFloor
                    and Navigator:CanTraverse(graph, cursorKey, neighborKey)
                    and eligibleWanderCell(graph, neighbor)
                then
                    fallback[#fallback + 1] = neighbor
                    if neighborKey ~= previousKey then choices[#choices + 1] = neighbor end
                end
            end
            if #choices == 0 then choices = fallback end
            if #choices == 0 then break end

            local nextCell = choices[rng:Int(1, #choices)]
            path[#path + 1] = nextCell
            previousKey = cursorKey
            cursor = nextCell
        end
        return path
    end

    local baseRefreshRoute = class._RefreshRoute
    function class:_RefreshRoute(graph)
        if not self.LODWanderer then return baseRefreshRoute(self, graph) end

        local activeWaypoint = self.LODWaypoints and self.LODWaypoints[self.LODWaypointIndex or 1]
        if activeWaypoint and activeWaypoint.stair then
            self.LODNextRouteRefresh = CurTime() + EC.RouteRefreshSeconds
            return
        end
        if CurTime() < (self.LODNextRouteRefresh or 0) then return end
        self.LODNextRouteRefresh = CurTime() + EC.RouteRefreshSeconds

        local current = currentCellFor(self, graph)
        if not current then return end

        if IsValid(self.LODTarget) then
            local targetCell = targetCellFor(self.LODTarget, graph)
            if targetCell and targetCell.z == self.LODWanderFloor then
                self:_RouteToCell(graph, targetCell)
                if #self.LODWaypoints == 0 then
                    self.LODWaypoints = {{pos = self.LODTarget:GetPos(), tolerance = 54}}
                    self.LODWaypointIndex = 1
                end
            end
            return
        end

        -- Wanderers are a literal per-floor population. If some external force
        -- displaced one vertically, route it back to its assigned floor before
        -- resuming its free patrol.
        if current.z ~= self.LODWanderFloor then
            local anchor = graph.Cells[self.LODWanderAnchorCellKey or ""]
            if anchor then self:_RouteToCell(graph, anchor) end
            return
        end

        local waypoint = self.LODWaypoints and self.LODWaypoints[self.LODWaypointIndex or 1]
        if waypoint then return end

        local path = chooseWanderPath(self, graph, current)
        self.LODWaypoints = {}
        self.LODWaypointIndex = 1
        for _, cell in ipairs(path) do
            self.LODWaypoints[#self.LODWaypoints + 1] = {
                pos = Navigator:CellCenter(cell) + Vector(0, 0, 8),
                tolerance = 44,
                stair = false
            }
        end
    end

    return true
end

installWandererAIPatch()
hook.Add("OnEntityCreated", "LOD_WandererInstallBeforeSpawn", function(ent)
    if IsValid(ent) and ent:GetClass() == "lod_hostile" then installWandererAIPatch() end
end)

-- Reserve enough of the global hostile ceiling for dead wanderers to return.
-- This keeps authored encounter activation from consuming the sixteen-per-floor
-- replacement slots while a roaming population is temporarily depleted.
if LOD.EncounterDirector and not LOD.EncounterDirector.LODWandererCeilingWrapped then
    LOD.EncounterDirector.LODWandererCeilingWrapped = true
    local baseSpawnEncounter = LOD.EncounterDirector._SpawnEncounter
    function LOD.EncounterDirector:_SpawnEncounter(encounter)
        local total = 0
        for _, count in pairs(encounter and encounter.composition or {}) do total = total + count end
        local reserve = WanderingDirector:GetDeficitReservation()
        if self:GetActiveCount() + total + reserve > EC.ActiveHostileCeiling then return false end
        return baseSpawnEncounter(self, encounter)
    end
end

function WanderingDirector:Think()
    local state = LOD.RunManager and LOD.RunManager.State
    local graph = state and state.Graph
    local plan = graph and graph.EncounterPlan
    if not state or not graph or not state.BuildReady or state.Failed or state.LevelCleared then return end
    if state.SimulationFrozen then return end

    if self.Graph ~= graph then self:_InitializeForGraph(graph) end

    local now = CurTime()
    if now < (self.NextThink or 0) then return end
    self.NextThink = now + WC.ThinkInterval

    for floor = 0, math.max(0, (graph.Layers or 1) - 1) do
        local living = self:_LivingOnFloor(floor)
        if living < WC.PerFloor then
            if not self.NextRespawn[floor] then
                self.NextRespawn[floor] = now + WC.RespawnSeconds
            elseif now >= self.NextRespawn[floor] then
                if self:_SpawnOne(graph, floor, "replacement") then
                    living = living + 1
                end
                self.NextRespawn[floor] = living < WC.PerFloor and (now + WC.RespawnSeconds) or nil
            end
        else
            self.NextRespawn[floor] = nil
        end
    end
end

hook.Add("Think", "LOD_WanderingDirectorThink", function()
    WanderingDirector:Think()
end)

concommand.Add("lod_m3_wanderers", function(ply)
    local cv = GetConVar("lod_developer_mode")
    if cv and not cv:GetBool() then return end
    if IsValid(ply) and not ply:IsAdmin() then return end

    local state = LOD.RunManager and LOD.RunManager.State
    local graph = state and state.Graph
    if not graph then
        print("[LOD:WANDER] no built graph")
        return
    end

    local now = CurTime()
    for floor = 0, math.max(0, (graph.Layers or 1) - 1) do
        local living = WanderingDirector:_LivingOnFloor(floor)
        local nextAt = WanderingDirector.NextRespawn[floor]
        local wait = nextAt and math.max(0, nextAt - now) or 0
        local text = string.format("floor=%d living=%d target=%d nextRespawn=%.1fs",
            floor + 1, living, WC.PerFloor, wait)
        print("[LOD:WANDER] " .. text)
        if IsValid(ply) then ply:ChatPrint(text) end
    end

    for _, ent in ipairs(WanderingDirector.Entities or {}) do
        if livingWanderer(ent) then
            local stateName = IsValid(ent.LODTarget) and "pursuit" or "wandering"
            local text = string.format("#%d floor=%d %s %s",
                ent:EntIndex(), (ent.LODWanderFloor or 0) + 1,
                tostring(ent.LODArchetypeId), stateName)
            print("[LOD:WANDER] " .. text)
        end
    end
end)
