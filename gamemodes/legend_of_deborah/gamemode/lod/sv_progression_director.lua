LOD = LOD or {}
LOD.ProgressionDirector = LOD.ProgressionDirector or {}

local ProgressionDirector = LOD.ProgressionDirector
local PC = LOD.Config.Progression
local cellKey = LOD.MazeGenerator.CellKey

util.AddNetworkString("LOD_RunState")
util.AddNetworkString("LOD_Announcement")

local function keyForCell(cell)
    return cellKey(cell.x, cell.y, cell.z)
end

local function edgeKey(a, b)
    local ka = keyForCell(a)
    local kb = keyForCell(b)
    if ka < kb then return ka .. "|" .. kb end
    return kb .. "|" .. ka
end

local function sortedKeys(t)
    local keys = {}
    for k in pairs(t) do keys[#keys + 1] = k end
    table.sort(keys)
    return keys
end

local function copyCell(cell)
    return {x = cell.x, y = cell.y, z = cell.z}
end

local function bfs(graph, startCell, blockedEdges)
    local startKey = keyForCell(startCell)
    local queue = {startKey}
    local head = 1
    local distance = {[startKey] = 0}

    while head <= #queue do
        local currentKey = queue[head]
        head = head + 1
        local current = graph.Cells[currentKey]
        if current then
            for _, neighborKey in ipairs(sortedKeys(current.neighbors)) do
                if distance[neighborKey] == nil then
                    local neighbor = graph.Cells[neighborKey]
                    local blocked = neighbor and blockedEdges and blockedEdges[edgeKey(current, neighbor)]
                    if neighbor and not blocked then
                        distance[neighborKey] = distance[currentKey] + 1
                        queue[#queue + 1] = neighborKey
                    end
                end
            end
        end
    end

    return distance
end

local function isBridgeToGoal(graph, a, b)
    local blocked = {[edgeKey(a, b)] = true}
    local reach = bfs(graph, graph.Start, blocked)
    return reach[keyForCell(graph.Goal)] == nil
end

local function collectBridgeCandidates(graph)
    local path = graph.CriticalPath or {}
    local candidates = {}
    local edgeCount = math.max(1, #path - 1)

    for i = 1, #path - 1 do
        local a = path[i]
        local b = path[i + 1]
        if a.z == b.z and isBridgeToGoal(graph, a, b) then
            candidates[#candidates + 1] = {
                pathIndex = i,
                fraction = i / edgeCount,
                edgeKey = edgeKey(a, b),
                beforeCell = copyCell(a),
                afterCell = copyCell(b)
            }
        end
    end

    return candidates, edgeCount
end

local function chooseGateTriple(graph)
    local candidates, edgeCount = collectBridgeCandidates(graph)
    if #candidates < 3 then return nil, "fewer than three progression-safe bridge edges" end

    local spacing = PC.MinimumGateSpacing or 4
    local tail = PC.MinimumTailEdges or 5
    local targets = {0.25, 0.50, 0.75}
    local best
    local bestScore = math.huge

    for i = 1, #candidates - 2 do
        local a = candidates[i]
        if a.pathIndex >= spacing then
            for j = i + 1, #candidates - 1 do
                local b = candidates[j]
                if b.pathIndex - a.pathIndex >= spacing then
                    for k = j + 1, #candidates do
                        local c = candidates[k]
                        if c.pathIndex - b.pathIndex >= spacing and edgeCount - c.pathIndex >= tail then
                            local score = math.abs(a.fraction - targets[1]) +
                                math.abs(b.fraction - targets[2]) +
                                math.abs(c.fraction - targets[3])
                            if score < bestScore then
                                bestScore = score
                                best = {a, b, c}
                            end
                        end
                    end
                end
            end
        end
    end

    if not best then return nil, "could not place three ordered gates with safe spacing" end
    return best
end

local function transitionCellSet(graph)
    local set = {}
    for _, edge in ipairs(graph.VerticalEdges or {}) do
        set[keyForCell(edge.a)] = true
        set[keyForCell(edge.b)] = true
    end
    return set
end

local function criticalPathSet(graph)
    local set = {}
    for _, cell in ipairs(graph.CriticalPath or {}) do set[keyForCell(cell)] = true end
    return set
end

local function gateEndpointSet(gates)
    local set = {}
    for _, gate in ipairs(gates) do
        set[keyForCell(gate.beforeCell)] = true
        set[keyForCell(gate.afterCell)] = true
    end
    return set
end

local function componentDifference(current, previous)
    local result = {}
    for k in pairs(current) do
        if not previous or previous[k] == nil then result[k] = true end
    end
    return result
end

local function blockedFrom(gates, firstLocked)
    local blocked = {}
    for i = firstLocked, #gates do blocked[gates[i].edgeKey] = true end
    return blocked
end

local function candidateDegree(graph, key)
    local cell = graph.Cells[key]
    return cell and table.Count(cell.neighbors) or 99
end

local function chooseKeycardCell(graph, gates, cardIndex, rng, components)
    local currentComponent = components[cardIndex - 1]
    local previousComponent = cardIndex > 1 and components[cardIndex - 2] or nil
    local sector = componentDifference(currentComponent, previousComponent)
    local blocked = blockedFrom(gates, cardIndex)
    local entry = cardIndex == 1 and graph.Start or gates[cardIndex - 1].afterCell
    local distances = bfs(graph, entry, blocked)
    local critical = criticalPathSet(graph)
    local transitions = transitionCellSet(graph)
    local endpoints = gateEndpointSet(gates)
    local excluded = {
        [keyForCell(graph.Start)] = true,
        [keyForCell(graph.Goal)] = true
    }
    for k in pairs(transitions) do excluded[k] = true end
    for k in pairs(endpoints) do excluded[k] = true end

    local preferred = {}
    local fallback = {}
    local minDetour = PC.KeycardDetourMin or 4

    for k in pairs(sector) do
        local distance = distances[k]
        if distance and distance >= minDetour and not excluded[k] then
            local row = {key = k, distance = distance, degree = candidateDegree(graph, k)}
            fallback[#fallback + 1] = row
            if not critical[k] and row.degree <= 2 then preferred[#preferred + 1] = row end
        end
    end

    local pool = #preferred > 0 and preferred or fallback
    if #pool == 0 then return nil, "no keycard objective pocket meets minimum detour" end

    table.sort(pool, function(a, b)
        if a.distance ~= b.distance then return a.distance > b.distance end
        return a.key < b.key
    end)

    local fraction = math.Clamp(PC.KeycardTopBandFraction or 0.35, 0.05, 1)
    local topCount = math.max(1, math.ceil(#pool * fraction))
    local selected = pool[rng:Int(1, topCount)]
    local cell = graph.Cells[selected.key]

    return {
        cell = copyCell(cell),
        graphDistanceFromSectorEntry = selected.distance,
        branchPreferred = #preferred > 0
    }
end

local function simulateProgression(graph, gates, keycards, coreCell, deborahCell)
    local blocked = {}
    for _, gate in ipairs(gates) do blocked[gate.edgeKey] = true end

    for i = 1, 3 do
        local beforeOpen = bfs(graph, graph.Start, blocked)
        if not beforeOpen[keyForCell(keycards[i].cell)] then
            return false, string.format("%s keycard is not reachable before its gate", PC.Cards[i].name)
        end
        if not beforeOpen[keyForCell(gates[i].beforeCell)] then
            return false, string.format("%s gate accessible-side cell is unreachable", PC.Cards[i].name)
        end

        blocked[gates[i].edgeKey] = nil
        local afterOpen = bfs(graph, graph.Start, blocked)
        if not afterOpen[keyForCell(gates[i].afterCell)] then
            return false, string.format("%s gate does not release its next sector", PC.Cards[i].name)
        end
    end

    local finalReach = bfs(graph, graph.Start, blocked)
    if not finalReach[keyForCell(coreCell)] then return false, "core is unreachable after Yellow Gate" end
    if not finalReach[keyForCell(deborahCell)] then return false, "Deborah is unreachable after Yellow Gate" end
    return true
end

function ProgressionDirector:Plan(graph, masterLevelSeed)
    local selected, gateErr = chooseGateTriple(graph)
    if not selected then return false, gateErr end

    local gates = {}
    for i = 1, 3 do
        local source = selected[i]
        gates[i] = {
            index = i,
            id = PC.Cards[i].id,
            edgeKey = source.edgeKey,
            pathIndex = source.pathIndex,
            beforeCell = source.beforeCell,
            afterCell = source.afterCell
        }
    end

    local components = {}
    components[0] = bfs(graph, graph.Start, blockedFrom(gates, 1))
    components[1] = bfs(graph, graph.Start, blockedFrom(gates, 2))
    components[2] = bfs(graph, graph.Start, blockedFrom(gates, 3))
    components[3] = bfs(graph, graph.Start, {})

    local seed = masterLevelSeed or graph.MasterLevelSeed or graph.LevelSeed or 1
    local rng = LOD.RNG.New(LOD.Seeds.Derive(seed, "progression-objectives"))
    local keycards = {}
    for i = 1, 3 do
        local card, cardErr = chooseKeycardCell(graph, gates, i, rng:Derive("card:" .. i), components)
        if not card then return false, string.format("%s keycard: %s", PC.Cards[i].name, cardErr) end
        card.index = i
        card.id = PC.Cards[i].id
        keycards[i] = card
    end

    local path = graph.CriticalPath or {}
    if #path < 2 then return false, "critical path is too short for Core/Deborah reservation" end
    local coreCell = copyCell(path[#path - 1])
    local deborahCell = copyCell(path[#path])
    local valid, validationErr = simulateProgression(graph, gates, keycards, coreCell, deborahCell)
    if not valid then return false, validationErr end

    graph.Progression = {
        Gates = gates,
        Keycards = keycards,
        CoreCell = coreCell,
        DeborahCell = deborahCell,
        Validation = {
            valid = true,
            orderedRoute = "Start>Red Card>Red Gate>Blue Card>Blue Gate>Yellow Card>Yellow Gate>Core>Deborah"
        }
    }

    return true, graph.Progression
end

function ProgressionDirector:ResetLevelState(graph)
    local state = LOD.RunManager.State
    state.Graph = graph
    state.Cards = {false, false, false}
    state.GatesOpen = {false, false, false}
    state.ObjectiveStage = 1
    state.CheckpointIndex = 0
    state.CheckpointPos = nil
    state.LevelCleared = false
    state.IntermissionEnd = nil
end

function ProgressionDirector:CommitBuiltLevel(buildReport)
    local state = LOD.RunManager.State
    state.CheckpointIndex = 0
    state.CheckpointPos = buildReport.startPos
    self:SyncAll()
end

function ProgressionDirector:GetObjectiveText()
    local stage = (LOD.RunManager.State and LOD.RunManager.State.ObjectiveStage) or 1
    local objectives = {
        "FIND RED KEYCARD — R / TRIANGLE",
        "OPEN RED GATE — R / TRIANGLE",
        "FIND BLUE KEYCARD — B / CIRCLE",
        "OPEN BLUE GATE — B / CIRCLE",
        "FIND YELLOW KEYCARD — Y / SQUARE",
        "OPEN YELLOW GATE — Y / SQUARE",
        "RESCUE DEBORAH"
    }
    return objectives[stage] or "EXPEDITION"
end

function ProgressionDirector:GetObjectiveTarget()
    local state = LOD.RunManager.State
    local graph = state.Graph
    if not graph or not graph.Progression then return nil end
    local stage = state.ObjectiveStage or 1
    if stage == 2 or stage == 4 or stage == 6 then
        local gateIndex = math.floor(stage / 2)
        local gate = graph.Progression.Gates[gateIndex]
        local a = LOD.MazeBuilder:CellCenter(gate.beforeCell)
        local b = LOD.MazeBuilder:CellCenter(gate.afterCell)
        return (a + b) * 0.5 + Vector(0, 0, 64)
    end
    return nil
end

function ProgressionDirector:SyncPlayer(ply)
    if not IsValid(ply) then return end
    local state = LOD.RunManager.State
    local target = self:GetObjectiveTarget()

    net.Start("LOD_RunState")
    net.WriteUInt(math.max(1, state.Level or 1), 20)
    net.WriteUInt(math.Clamp(state.ObjectiveStage or 1, 1, 7), 3)
    for i = 1, 3 do net.WriteBool(state.Cards and state.Cards[i] == true) end
    for i = 1, 3 do net.WriteBool(state.GatesOpen and state.GatesOpen[i] == true) end
    net.WriteUInt(math.Clamp(state.CheckpointIndex or 0, 0, 3), 2)
    net.WriteBool(state.Ranked == true)
    net.WriteBool(state.Failed == true)
    net.WriteBool(state.LevelCleared == true)
    net.WriteBool(target ~= nil)
    if target then net.WriteVector(target) end
    net.WriteString(self:GetObjectiveText())
    net.Send(ply)
end

function ProgressionDirector:SyncAll()
    for _, ply in ipairs(player.GetAll()) do self:SyncPlayer(ply) end
end

function ProgressionDirector:Announce(text)
    net.Start("LOD_Announcement")
    net.WriteString(text)
    net.Broadcast()
end

function ProgressionDirector:CollectCard(index, ply)
    local state = LOD.RunManager.State
    if state.Failed or state.LevelCleared then return false end
    if index < 1 or index > 3 or state.Cards[index] then return false end
    if state.ObjectiveStage ~= index * 2 - 1 then return false end
    if IsValid(ply) and (not LOD.RunManager:IsActivePlayer(ply) or not ply:Alive()) then return false end

    state.Cards[index] = true
    state.ObjectiveStage = index * 2
    local card = PC.Cards[index]
    self:Announce(string.format("%s KEYCARD ACQUIRED — %s / %s", string.upper(card.name), card.letter, card.symbol))
    self:SyncAll()
    return true
end

function ProgressionDirector:TryOpenGate(index, ply, gateEnt)
    local state = LOD.RunManager.State
    local card = PC.Cards[index]
    if state.Failed or state.LevelCleared then return false end
    if index < 1 or index > 3 then return false end
    if state.GatesOpen[index] then return true end

    if not state.Cards[index] then
        if IsValid(ply) then
            ply:ChatPrint(string.format("ACCESS DENIED — %s / %s KEYCARD REQUIRED", card.letter, card.symbol))
            ply:EmitSound("buttons/button10.wav", 65, 100, 0.7)
        end
        return false
    end

    if state.ObjectiveStage ~= index * 2 then
        if IsValid(ply) then ply:ChatPrint("ACCESS DENIED — SECURITY SEQUENCE LOCKED") end
        return false
    end

    state.GatesOpen[index] = true
    state.ObjectiveStage = index < 3 and (index * 2 + 1) or 7
    state.CheckpointIndex = index

    local graph = state.Graph
    local meta = graph and graph.Progression and graph.Progression.Gates[index]
    if meta then state.CheckpointPos = LOD.MazeBuilder:CellCenter(meta.afterCell) + Vector(0, 0, 12) end

    if IsValid(gateEnt) and gateEnt.OpenGate then gateEnt:OpenGate() end
    self:Announce(string.format("%s GATE OPEN — CHECKPOINT %d", string.upper(card.name), index))
    self:SyncAll()
    return true
end

function ProgressionDirector:CanRescueDeborah()
    local state = LOD.RunManager.State
    return not state.Failed and not state.LevelCleared and state.GatesOpen and
        state.GatesOpen[1] and state.GatesOpen[2] and state.GatesOpen[3] and state.ObjectiveStage == 7
end

function ProgressionDirector:OnDeborahTouched(ply)
    if not IsValid(ply) or not ply:IsPlayer() or not ply:Alive() then return false end
    if not LOD.RunManager:IsActivePlayer(ply) or not self:CanRescueDeborah() then return false end
    return LOD.RunManager:CompleteLevel(ply)
end
