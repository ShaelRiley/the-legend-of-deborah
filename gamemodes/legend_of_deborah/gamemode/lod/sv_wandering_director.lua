LOD = LOD or {}
LOD.WanderingDirector = LOD.WanderingDirector or {}

local WanderingDirector = LOD.WanderingDirector
local EC = LOD.Config.Encounter
local Navigator = LOD.MazeNavigator
local cellKey = LOD.MazeGenerator.CellKey

-- Production roaming layer. These enemies exist in addition to the authored
-- encounter plan and deliberately keep ordinary traversal from feeling empty.
local WC = {
    PerFloor = 16,
    RespawnSeconds = 20,
    AcquireCells = 4,
    DisengageCells = 6,
    WanderStepsMin = 3,
    WanderStepsMax = 8,
    SpawnPlayerClearanceCells = 4,
    ThinkInterval = 0.25,
    CandidateLimit = 24,
    SpecialistPerFloor = 4,
    Pools = {
        corruption = {shambler=20,runner=10,deadcrab=30,bioblaster=25,siphoner=10,flamer=5},
        crossfire = {soldier=40,bioblaster=25,runner=15,seeker=10,caromer=10},
        hunting = {runner=50,deadcrab=30,watcher=10,reaper=10},
        occupation = {soldier=60,runner=20,redliner=20},
        quarantine = {shambler=30,soldier=30,runner=20,drubber=20},
        retinue = {shambler=60,deadcrab=20,afterburst=20}
    },
    ArchetypeWeights = {
        shambler = 45,
        runner = 25,
        soldier = 12,
        deadcrab = 10,
        bioblaster = 8
    }
}

local basics = {shambler=true,runner=true,soldier=true,deadcrab=true,bioblaster=true}
local additions = {siphoner=true,caromer=true,reaper=true,redliner=true,drubber=true,afterburst=true}
local eligible = {watcher=true,seeker=true,flamer=true}
for id in pairs(basics) do eligible[id]=true end
for id in pairs(additions) do eligible[id]=true end

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

local function stairCellSet(graph)
    if not graph then return {} end
    if graph.LODWanderStairCellSet then return graph.LODWanderStairCellSet end
    local out = {}
    for _, edge in ipairs(graph.VerticalEdges or {}) do
        out[keyOf(edge.a)] = true
        out[keyOf(edge.b)] = true
    end
    graph.LODWanderStairCellSet = out
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
    if not cell or safeCell(graph, cell) then return false end
    -- A vertical endpoint contains authored stair/aperture geometry. Wanderers
    -- do not need to use those cells as random same-floor patrol destinations;
    -- keeping them out of the roaming pool prevents a patrol from selecting a
    -- cell-center target that lies inside the stair volume. Pursuit can still use
    -- the canonical graph/stair compiler when a player actually requires it.
    return not stairCellSet(graph)[keyOf(cell)]
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
    return math.max(0, graph.WanderLayers or graph.Layers or 0) * WC.PerFloor
end

function WanderingDirector:GetDeficitReservation(graph)
    graph = graph or (LOD.RunManager and LOD.RunManager.State.Graph)
    if not graph then return 0 end
    local deficit = 0
    for floor = 0, math.max(0, (graph.WanderLayers or graph.Layers or 1) - 1) do
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

-- Local population facts are ephemeral. Campaign receipts remain EncounterDirector's.
function WanderingDirector:_Population(floor)
    local counts, homes, specialists = {}, {}, 0
    for _, ent in ipairs(self.Entities or {}) do
        if livingWanderer(ent) and ent.LODWanderFloor == floor then
            local id=ent.LODArchetypeId
            counts[id]=(counts[id] or 0)+1
            homes[ent.LODWanderAnchorCellKey]=true
            if not basics[id] then specialists=specialists+1 end
        end
    end
    return counts, homes, specialists
end

function WanderingDirector:_Owns(graph)
    local s=LOD.RunManager and LOD.RunManager.State
    local o=self.Owner
    return s and o and o.state==s and o.graph==graph and s.Graph==graph
        and o.level==s.Level and o.seed==s.LevelSeed
        and o.campaign==s.CampaignSeed and o.epoch==s.CampaignEpoch and o.run==s.RunId
end

function WanderingDirector:Cleanup()
    for _,ent in ipairs(self.Entities or {}) do if IsValid(ent) then ent:Remove() end end
    self.Entities={};self.NextRespawn={};self.SpawnOrdinal={};self.LastArchetype={}
    self.Diagnostics={};self.Graph=nil;self.Owner=nil;self.NextThink=0
end

function WanderingDirector:_SpawnCandidates(graph, floor, rng)
    local cells = self:_FloorCells(graph, floor)
    local players = playerCells(graph)
    local _, homes = self:_Population(floor)
    -- Dormant squads have no native hull yet. Reserve their authored homes as
    -- well as living roaming anchors; read the current plan on every attempt so
    -- rebuilds cannot leave stale exclusions. This does not constrain pursuit.
    local encounterHomes = {}
    for _, encounter in ipairs((graph.EncounterPlan or {}).encounters or {}) do
        if encounter.cellKey then encounterHomes[encounter.cellKey] = true end
    end
    local out = {}
    local roster, director = LOD.EnemyRoster, LOD.EncounterDirector
    for _, cell in ipairs(cells) do
        local key=keyOf(cell)
        local tag=(graph.CellTags or {})[key] or {}
        local admitted=not homes[key] and not encounterHomes[key] and not tag.objective
            and (not roster or not roster:IsTransition(graph,cell))
            and (not director or not director.PacingAllows or not graph.EncounterPlan
                or director:PacingAllows(graph.EncounterPlan,cell))
        for _, playerCell in ipairs(players) do
            if admitted and playerCell.z == floor then
                local distance = Navigator:Distance(graph, playerCell, cell)
                if distance < WC.SpawnPlayerClearanceCells then admitted=false end
            end
        end
        if admitted then out[#out+1]=cell end
    end
    rng:Shuffle(out)
    return out
end

function WanderingDirector:_Pool(graph)
    local theme=graph.EncounterPlan and graph.EncounterPlan.ecology and graph.EncounterPlan.ecology.theme
    return WC.Pools[theme] or WC.ArchetypeWeights, WC.Pools[theme] and theme or "legacy"
end

function WanderingDirector:_Choices(graph, cell, floor)
    local pool=self:_Pool(graph)
    local counts, _, specialists=self:_Population(floor)
    local tag=(graph.CellTags or {})[keyOf(cell)] or {}
    local choices={}
    local state=LOD.RunManager and LOD.RunManager.State
    local pressure=LOD.Damsels and LOD.Damsels:EndlessPressure(state and state.Level).specialistWeight or 1
    for _,id in ipairs(sortedKeys(pool)) do
        local weight=pool[id]
        local specialist=not basics[id]
        local allowed=eligible[id] and EC.Archetypes[id] and weight>0
            and (not specialist or specialists<WC.SpecialistPerFloor and not counts[id])
        if additions[id] then
            allowed=allowed and (tag.sector or 0)>=2 and (tag.role=="arena" or tag.role=="ambush")
        elseif id=="flamer" then allowed=allowed and (tag.sector or 0)>=2 end
        local placement
        if allowed and LOD.EnemyRoster and LOD.EnemyRoster.Definitions[id] then
            placement=LOD.EnemyRoster:Placement(graph,cell,id,tag.role)
            allowed=placement~=nil
        end
        if allowed then
            if id~="shambler" and id~="runner" then weight=weight*pressure end
            choices[#choices+1]={id=id,weight=weight/(1+(counts[id] or 0)),placement=placement}
        end
    end
    if #choices>1 then
        for i=#choices,1,-1 do
            if choices[i].id==(self.LastArchetype or {})[floor] then table.remove(choices,i) end
        end
    end
    return choices
end

local function weightedChoice(rng, choices)
    local total=0
    for _,item in ipairs(choices) do total=total+item.weight end
    if total<=0 then return nil end
    local roll=rng:Float(0,total)
    for _,item in ipairs(choices) do
        roll=roll-item.weight
        if roll<=0 then return item end
    end
    return choices[#choices]
end

-- Native admission is deliberately not cached. A previously legal cell can be
-- obstructed by a Wall, event, false floor or another body before replacement.
function WanderingDirector:_SupportedSpawn(cell)
    local center=Navigator:CellCenter(cell)+Vector(0,0,2)
    local hull=util.TraceHull({start=center,endpos=center,mins=Vector(-16,-16,0)*1.33,
        maxs=Vector(16,16,72)*1.33,mask=MASK_NPCSOLID})
    if hull.Hit or hull.StartSolid or hull.AllSolid then return nil end
    local floor=util.TraceLine({start=center+Vector(0,0,16),endpos=center-Vector(0,0,12),mask=MASK_SOLID,
        filter=function(v) return not v.LODHostile and not v:IsPlayer() end})
    if not floor.Hit or floor.StartSolid or floor.AllSolid or not floor.HitNormal
        or floor.HitNormal.z<.7 or math.abs(floor.HitPos.z-(center.z-2))>4 then return nil end
    return center
end

function WanderingDirector:_SpawnOne(graph, floor, reason)
    local state = LOD.RunManager and LOD.RunManager.State
    if not self:_Owns(graph) or not state.BuildReady or state.Failed or state.LevelCleared
        or state.SimulationFrozen or floor<0 or floor>=(graph.WanderLayers or graph.Layers or 0)
        or self:_LivingOnFloor(floor)>=WC.PerFloor then return false end
    local owner=self.Owner
    local director=LOD.EncounterDirector
    if not director or director:GetActiveCount()>=EC.ActiveHostileCeiling then
        self.Diagnostics[floor]="ceiling";return false
    end

    self.SpawnOrdinal[floor] = (self.SpawnOrdinal[floor] or 0) + 1
    local ordinal = self.SpawnOrdinal[floor]
    local seed = LOD.Seeds.Derive(state.LevelSeed or graph.LevelSeed or 1,
        string.format("wanderer:%d:%d", floor, ordinal))
    local rng = LOD.RNG.New(seed)
    local candidates = self:_SpawnCandidates(graph, floor, rng:Derive("spawn-cell"))
    local cell, selected, spawnPos
    for i=1,math.min(#candidates,WC.CandidateLimit) do
        local candidate=candidates[i]
        local pos=self:_SupportedSpawn(candidate)
        if pos then
            local choice=weightedChoice(rng:Derive("archetype:"..keyOf(candidate)),self:_Choices(graph,candidate,floor))
            if choice then cell,selected,spawnPos=candidate,choice,pos;break end
        end
    end
    if not cell then self.Diagnostics[floor]="no_legal_home";return false end
    local archetype=selected.id

    local ent = ents.Create("lod_hostile")
    if not IsValid(ent) then self.Diagnostics[floor]="native_create";return false end

    local spawnKey = keyOf(cell)
    ent.LODArchetypeId = archetype
    ent.LODHomeCellKey = spawnKey
    ent.LODEncounterId = nil
    ent.LODEncounterOrdinal = 900000 + floor * 10000 + ordinal
    ent.LODWanderer = true
    ent.LODWanderFloor = floor
    ent.LODWanderAnchorCellKey = spawnKey
    ent.LODWanderSeed = seed
    ent.LODWanderSpawnReason = tostring(reason or "population")
    ent.LODActivated = true
    ent.LODSpawnSource="wanderer"
    ent.LODRosterPlacement=selected.placement
    ent.LODWanderTheme=select(2,self:_Pool(graph))
    ent:SetPos(spawnPos)
    ent:Spawn()
    if not IsValid(ent) then self.Diagnostics[floor]="native_spawn";return false end
    if LOD.HostileMotionV2 and LOD.HostileMotionV2.SnapSpawn
        and LOD.HostileMotionV2:SnapSpawn(ent)==false then
        if IsValid(ent) then ent:Remove() end
        self.Diagnostics[floor]="native_settlement";return false
    end
    if not IsValid(ent) then self.Diagnostics[floor]="native_settlement";return false end
    ent:Activate()
    if not IsValid(ent) then self.Diagnostics[floor]="native_activate";return false end
    -- Native initialization/activation may invoke arbitrary hooks. Never register
    -- a body across a cleanup/rebuild or a newly exhausted shared reservation.
    if self.Owner~=owner or not self:_Owns(graph) or not state.BuildReady
        or state.Failed or state.LevelCleared or state.SimulationFrozen
        or director:GetActiveCount()>=EC.ActiveHostileCeiling
        or self:_LivingOnFloor(floor)>=WC.PerFloor then
        ent:Remove();return false
    end

    -- Initializing every wanderer with refresh time zero made the full roaming
    -- population acquire targets and rebuild routes on the same frames forever.
    -- Seed-derived phase offsets preserve the exact refresh cadences and replay
    -- determinism while distributing their work across those intervals.
    local scheduleRng = rng:Derive("refresh-phase")
    local targetInterval = math.max(0.01, EC.TargetRefreshSeconds or 0.25)
    local routeInterval = math.max(0.01, EC.RouteRefreshSeconds or 0.35)
    local now = CurTime()
    ent.LODWanderTargetPhase = scheduleRng:Float(0, targetInterval)
    ent.LODWanderRoutePhase = scheduleRng:Float(0, routeInterval)
    ent.LODNextTargetRefresh = now + ent.LODWanderTargetPhase
    ent.LODNextRouteRefresh = now + ent.LODWanderRoutePhase

    self.Entities[#self.Entities + 1] = ent
    if LOD.EncounterDirector then
        LOD.EncounterDirector.Entities = LOD.EncounterDirector.Entities or {}
        LOD.EncounterDirector.Entities[#LOD.EncounterDirector.Entities + 1] = ent
    end

    self.LastArchetype[floor]=archetype
    self.Diagnostics[floor]="spawned"
    print(string.format("[LOD:WANDER] spawned #%d floor=%d archetype=%s cell=%s reason=%s",
        ent:EntIndex(), floor + 1, archetype, spawnKey, tostring(reason or "population")))
    return true
end

function WanderingDirector:_InitializeForGraph(graph)
    self:Cleanup()
    local s=LOD.RunManager and LOD.RunManager.State
    if not s or s.Graph~=graph then return end
    self.Graph = graph
    self.Owner={state=s,graph=graph,level=s.Level,seed=s.LevelSeed,
        campaign=s.CampaignSeed,epoch=s.CampaignEpoch,run=s.RunId}

    for floor = 0, math.max(0, (graph.WanderLayers or graph.Layers or 1) - 1) do
        for _ = 1, WC.PerFloor do self:_SpawnOne(graph, floor, "initial") end
        self.NextRespawn[floor] = nil
    end

    print(string.format("[LOD:WANDER] initialized floors=%d target=%d",
        graph.WanderLayers or graph.Layers or 1, self:GetTargetPopulation(graph)))
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

    local statusElements = LOD.RPGStatusElements
    if statusElements and statusElements.ChooseRecklessTarget then
        local ally, distance = statusElements:ChooseRecklessTarget(
            hostile, graph, current, maximum)
        if ally then return ally, distance end
    end

    local best, bestDistance, bestWorld
    for _, ply in ipairs(LOD.FactionManager:LivingTargets()) do
        local targetCell = targetCellFor(ply, graph)
        if targetCell and targetCell.z == hostile.LODWanderFloor
            and LOD.FactionManager:CanAcquirePlayerTarget(ply) then
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
        if IsValid(existing) and current and LOD.FactionManager:CanAcquirePlayerTarget(existing) then
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
                    local safe = LOD.HostileMotionV2 and LOD.HostileMotionV2:SafeEngagementPoint(graph, self.LODTarget)
                    self.LODWaypoints = {{pos = safe or self.LODTarget:GetPos(), tolerance = 18}}
                    self.LODWaypointIndex = 1
                end
            end
            return
        end

        if current.z ~= self.LODWanderFloor then
            local anchor = graph.Cells[self.LODWanderAnchorCellKey or ""]
            if anchor then self:_RouteToCell(graph, anchor) end
            return
        end

        local waypoint = self.LODWaypoints and self.LODWaypoints[self.LODWaypointIndex or 1]
        if waypoint then return end

        -- One route compiler for every hostile. The former wanderer-specific
        -- CellCenter+8 loop duplicated MazeNavigator policy and could diverge
        -- from stair/height fixes. Build a real graph path beginning at the live
        -- current cell and let PathToWaypoints own all world-space coordinates.
        local chosen = chooseWanderPath(self, graph, current)
        local graphPath = {current}
        for _, cell in ipairs(chosen) do graphPath[#graphPath + 1] = cell end
        self.LODWaypoints = Navigator:PathToWaypoints(graph, graphPath) or {}
        self.LODWaypointIndex = 1
    end

    return true
end

installWandererAIPatch()
hook.Add("OnEntityCreated", "LOD_WandererInstallBeforeSpawn", function(ent)
    if IsValid(ent) and ent:GetClass() == "lod_hostile" then installWandererAIPatch() end
end)

-- Reserve enough of the global hostile ceiling for dead wanderers to return.
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
    if self.Owner and not self:_Owns(graph) then self:Cleanup() end
    if not state or not graph or not state.BuildReady or state.Failed or state.LevelCleared then return end
    if state.SimulationFrozen then return end

    if not self:_Owns(graph) then self:_InitializeForGraph(graph) end

    local now = CurTime()
    if now < (self.NextThink or 0) then return end
    self.NextThink = now + WC.ThinkInterval

    local respawnSeconds=WC.RespawnSeconds*(LOD.Damsels and LOD.Damsels:EndlessPressure(state.Level).reinforcement or 1)
    for floor = 0, math.max(0, (graph.WanderLayers or graph.Layers or 1) - 1) do
        local living = self:_LivingOnFloor(floor)
        if living < WC.PerFloor then
            if not self.NextRespawn[floor] then
                self.NextRespawn[floor] = now + respawnSeconds
            elseif now >= self.NextRespawn[floor] then
                if self:_SpawnOne(graph, floor, "replacement") then living = living + 1 end
                self.NextRespawn[floor] = living < WC.PerFloor and (now + respawnSeconds) or nil
            end
        else
            self.NextRespawn[floor] = nil
        end
    end
end

-- Follow the canonical dungeon cleanup rather than adding a second lifecycle hook.
if LOD.EncounterDirector and not LOD.EncounterDirector.LODWanderCleanupWrapped then
    LOD.EncounterDirector.LODWanderCleanupWrapped=true
    local baseCleanup=LOD.EncounterDirector.Cleanup
    function LOD.EncounterDirector:Cleanup(...)
        WanderingDirector:Cleanup()
        return baseCleanup(self,...)
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
    for floor = 0, math.max(0, (graph.WanderLayers or graph.Layers or 1) - 1) do
        local living = WanderingDirector:_LivingOnFloor(floor)
        local nextAt = WanderingDirector.NextRespawn[floor]
        local wait = nextAt and math.max(0, nextAt - now) or 0
        local counts,_,specialists=WanderingDirector:_Population(floor)
        local identities={}
        for _,id in ipairs(sortedKeys(counts)) do identities[#identities+1]=id..":"..counts[id] end
        local text = string.format("floor=%d living=%d target=%d nextRespawn=%.1fs theme=%s specialists=%d/%d result=%s roster=%s",
            floor + 1, living, WC.PerFloor, wait, select(2,WanderingDirector:_Pool(graph)),
            specialists,WC.SpecialistPerFloor,tostring((WanderingDirector.Diagnostics or {})[floor]),table.concat(identities,","))
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


concommand.Add("lod_wander_schedule_status", function(ply)
    local cv = GetConVar("lod_developer_mode")
    if cv and not cv:GetBool() then return end
    if IsValid(ply) and not ply:IsAdmin() then return end

    local targetInterval = math.max(0.01, EC.TargetRefreshSeconds or 0.25)
    local routeInterval = math.max(0.01, EC.RouteRefreshSeconds or 0.35)
    local binCount = 8
    local targetBins = {}
    local routeBins = {}
    local living = 0

    local function addBin(bins, phase, interval)
        if not phase then return end
        local index = math.Clamp(math.floor((phase / interval) * binCount), 0, binCount - 1)
        bins[index] = true
    end

    for _, ent in ipairs(WanderingDirector.Entities or {}) do
        if livingWanderer(ent) then
            living = living + 1
            addBin(targetBins, ent.LODWanderTargetPhase, targetInterval)
            addBin(routeBins, ent.LODWanderRoutePhase, routeInterval)
        end
    end

    local targetSpread = table.Count(targetBins)
    local routeSpread = table.Count(routeBins)
    local required = math.min(4, living)
    local passed = living > 0 and targetSpread >= required and routeSpread >= required
    local line = string.format(
        "wanderers=%d targetBins=%d/%d routeBins=%d/%d cadence=%.2fs/%.2fs result=%s",
        living, targetSpread, binCount, routeSpread, binCount,
        targetInterval, routeInterval, passed and "PASS" or "FAIL"
    )
    print("[LOD:WANDER-SCHEDULE] " .. line)
    if IsValid(ply) then ply:ChatPrint(line) end
end)
