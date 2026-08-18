LOD = LOD or {}

local DIR_VECTOR = {
    E = Vector(1, 0, 0), W = Vector(-1, 0, 0),
    N = Vector(0, 1, 0), S = Vector(0, -1, 0)
}

local function developerAllowed(ply)
    local cv = GetConVar("lod_developer_mode")
    if cv and not cv:GetBool() then return false end
    return not IsValid(ply) or ply:IsAdmin()
end

local function tell(ply, text)
    print("[LOD:M3] " .. text)
    if IsValid(ply) then ply:ChatPrint(text) end
end

local function cellText(cell)
    if not cell then return "nil" end
    return string.format("(%d,%d,%d)", cell.x, cell.y, cell.z)
end

local function keyOf(cell)
    return cell and LOD.MazeGenerator.CellKey(cell.x, cell.y, cell.z) or nil
end

local function sortedCells(graph)
    local cells = {}
    for _, cell in pairs(graph and graph.Cells or {}) do cells[#cells + 1] = cell end
    table.sort(cells, function(a, b) return keyOf(a) < keyOf(b) end)
    return cells
end

local function removeActiveHostiles()
    local count = 0
    for _, ent in ipairs(LOD.EncounterDirector.Entities or {}) do
        if IsValid(ent) then ent:Remove() count = count + 1 end
    end
    LOD.EncounterDirector.Entities = {}
    return count
end

local function spawnDebugHostile(ply, archetype, cell, pos)
    local cfg = LOD.Config.Encounter.Archetypes[archetype]
    if not cfg then return nil, "unknown hostile archetype" end
    local ent = ents.Create("lod_hostile")
    if not IsValid(ent) then return nil, "failed to create lod_hostile" end

    ent.LODArchetypeId = archetype
    ent.LODHomeCellKey = keyOf(cell)
    ent.LODEncounterId = nil
    ent.LODActivated = true
    ent:SetPos(pos or (LOD.MazeNavigator:CellCenter(cell) + Vector(0, 0, 10)))
    ent:Spawn()
    ent:Activate()
    ent:DropToFloor()
    LOD.EncounterDirector.Entities[#LOD.EncounterDirector.Entities + 1] = ent
    LOD.RunManager:MarkUnranked("Milestone 3 hostile debug spawn")
    return ent
end

concommand.Add("lod_m3_status", function(ply)
    if not developerAllowed(ply) then return end
    local graph = LOD.RunManager.State.Graph
    local plan = graph and graph.EncounterPlan
    if not plan then tell(ply, "no encounter plan active") return end

    local activated, cleared, dormant = 0, 0, 0
    for _, encounter in ipairs(plan.encounters or {}) do
        if encounter.cleared then cleared = cleared + 1
        elseif encounter.spawned then activated = activated + 1
        else dormant = dormant + 1 end
    end
    tell(ply, string.format(
        "level=%d encounters=%d dormant=%d activeEncounters=%d cleared=%d activeHostiles=%d ceiling=%d seed=%s",
        LOD.RunManager.State.Level or -1,
        #(plan.encounters or {}), dormant, activated, cleared,
        LOD.EncounterDirector:GetActiveCount(), LOD.Config.Encounter.ActiveHostileCeiling,
        tostring(plan.seed)
    ))
end)

concommand.Add("lod_m3_plan", function(ply)
    if not developerAllowed(ply) then return end
    local graph = LOD.RunManager.State.Graph
    local plan = graph and graph.EncounterPlan
    if not plan then tell(ply, "no encounter plan active") return end

    for _, encounter in ipairs(plan.encounters or {}) do
        local parts = {}
        for _, id in ipairs({"shambler", "runner", "soldier"}) do
            local count = encounter.composition and encounter.composition[id] or 0
            if count > 0 then parts[#parts + 1] = id .. "x" .. count end
        end
        tell(ply, string.format(
            "#%d sector=%d role=%s cell=%s template=%s threat=%.1f [%s] state=%s",
            encounter.id, encounter.sector or -1, tostring(encounter.role), cellText(encounter.cell),
            tostring(encounter.templateName), encounter.threat or 0, table.concat(parts, ","),
            encounter.cleared and "cleared" or (encounter.spawned and "active" or "dormant")
        ))
    end
end)

concommand.Add("lod_m3_encounter", function(ply, _, args)
    if not developerAllowed(ply) then return end
    local id = math.floor(tonumber(args[1]) or 1)
    local graph = LOD.RunManager.State.Graph
    local plan = graph and graph.EncounterPlan
    local encounter = plan and plan.encounters[id]
    if not encounter then tell(ply, "usage: lod_m3_encounter <id>") return end
    local living = 0
    for _, ent in ipairs(encounter.entities or {}) do if IsValid(ent) then living = living + 1 end end
    tell(ply, string.format("encounter #%d %s cell=%s state=%s living=%d kills=%d",
        id, tostring(encounter.templateName), cellText(encounter.cell),
        encounter.cleared and "cleared" or (encounter.spawned and "active" or "dormant"),
        living, encounter.kills or 0))
end)

local function chooseDebugCell(graph, ply)
    local start = LOD.MazeNavigator:WorldToCell(graph, ply:GetPos())
    if not start then return nil end
    local choices = {}
    for _, cell in ipairs(sortedCells(graph)) do
        local distance = LOD.MazeNavigator:Distance(graph, start, cell)
        if distance >= 2 and distance <= 3 then choices[#choices + 1] = cell end
    end
    return choices[1]
end

concommand.Add("lod_m3_spawn", function(ply, _, args)
    if not developerAllowed(ply) or not IsValid(ply) then return end
    local archetype = string.lower(args[1] or "shambler")
    local cfg = LOD.Config.Encounter.Archetypes[archetype]
    if not cfg then tell(ply, "usage: lod_m3_spawn shambler|runner|soldier") return end

    local graph = LOD.RunManager.State.Graph
    if not graph or not LOD.RunManager.State.BuildReady then tell(ply, "no built level active") return end
    local cell = chooseDebugCell(graph, ply)
    if not cell then tell(ply, "could not find an accessible debug spawn cell 2-3 graph steps away") return end

    local ent, err = spawnDebugHostile(ply, archetype, cell)
    if not ent then tell(ply, err) return end
    tell(ply, string.format("spawned %s at %s, %d graph steps from player", cfg.name, cellText(cell),
        LOD.MazeNavigator:Distance(graph, LOD.MazeNavigator:WorldToCell(graph, ply:GetPos()), cell)))
end)

local function findApproachCell(graph, encounter, wantedDistance)
    local wantedSector = graph.CellTags and graph.CellTags[encounter.cellKey] and graph.CellTags[encounter.cellKey].sector
    local fallback
    for _, cell in ipairs(sortedCells(graph)) do
        local distance = LOD.MazeNavigator:Distance(graph, cell, encounter.cell)
        if distance == wantedDistance then
            local tag = graph.CellTags and graph.CellTags[keyOf(cell)]
            if wantedSector and tag and tag.sector == wantedSector then return cell end
            fallback = fallback or cell
        end
    end
    return fallback
end

concommand.Add("lod_m3_tp", function(ply, _, args)
    if not developerAllowed(ply) or not IsValid(ply) then return end
    local mode = string.lower(args[1] or "")
    local id = math.floor(tonumber(args[2]) or 1)
    local graph = LOD.RunManager.State.Graph
    local plan = graph and graph.EncounterPlan
    local encounter = plan and plan.encounters[id]
    if not encounter then tell(ply, "usage: lod_m3_tp encounter <id> OR lod_m3_tp approach <id> <distance>") return end

    local destination
    if mode == "encounter" then
        destination = encounter.cell
    elseif mode == "approach" then
        local distance = math.max(0, math.floor(tonumber(args[3]) or LOD.Config.Encounter.ActivationDistanceCells))
        destination = findApproachCell(graph, encounter, distance)
        if not destination then tell(ply, "no traversable cell at exactly " .. distance .. " graph steps from encounter #" .. id) return end
    else
        tell(ply, "usage: lod_m3_tp encounter <id> OR lod_m3_tp approach <id> <distance>")
        return
    end

    LOD.RunManager:MarkUnranked("Milestone 3 encounter debug teleport")
    ply:SetPos(LOD.MazeNavigator:CellCenter(destination) + Vector(0, 0, 24))
    ply:SetVelocity(-ply:GetVelocity())
    tell(ply, string.format("teleported to %s for encounter #%d %s; distance=%d",
        cellText(destination), id, tostring(encounter.templateName),
        LOD.MazeNavigator:Distance(graph, destination, encounter.cell)))
end)

local function lowerUpper(edge)
    if edge.a.z < edge.b.z then return edge.a, edge.b end
    return edge.b, edge.a
end

local function sortedVerticalEdges(graph)
    local edges = {}
    for _, edge in ipairs(graph.VerticalEdges or {}) do edges[#edges + 1] = edge end
    table.sort(edges, function(a, b)
        local al, au = lowerUpper(a)
        local bl, bu = lowerUpper(b)
        local ak = keyOf(al) .. ">" .. keyOf(au)
        local bk = keyOf(bl) .. ">" .. keyOf(bu)
        return ak < bk
    end)
    return edges
end

local function nearestEncounterDistance(graph, cell)
    local best = math.huge
    local plan = graph.EncounterPlan
    for _, encounter in ipairs(plan and plan.encounters or {}) do
        local d = LOD.MazeNavigator:Distance(graph, cell, encounter.cell)
        if d < best then best = d end
    end
    return best
end

concommand.Add("lod_m3_stairs", function(ply)
    if not developerAllowed(ply) then return end
    local graph = LOD.RunManager.State.Graph
    if not graph then tell(ply, "no built level active") return end
    for index, edge in ipairs(sortedVerticalEdges(graph)) do
        local lower, upper = lowerUpper(edge)
        tell(ply, string.format("stair #%d lower=%s upper=%s uphill=%s nearestEncounter=%s",
            index, cellText(lower), cellText(upper), tostring(edge.LODStairDirection or "?"),
            nearestEncounterDistance(graph, lower) == math.huge and "inf" or tostring(nearestEncounterDistance(graph, lower))))
    end
end)

local function stairTestPositions(edge, direction)
    local lower, upper = lowerUpper(edge)
    local dir = DIR_VECTOR[edge.LODStairDirection or "E"] or DIR_VECTOR.E
    local run = LOD.Config.Geometry.StairRun
    local lowerCenter = LOD.MazeNavigator:CellCenter(lower)
    local upperCenter = LOD.MazeNavigator:CellCenter(upper)
    local lowerApproach = lowerCenter - dir * (run - 32) + Vector(0, 0, 18)
    local upperLanding = upperCenter + dir * 96 + Vector(0, 0, 20)

    if direction == "down" then
        return upper, upperLanding, lowerApproach
    end
    return lower, lowerApproach, upperLanding
end

concommand.Add("lod_m3_stair", function(ply, _, args)
    if not developerAllowed(ply) or not IsValid(ply) then return end
    local archetype = string.lower(args[1] or "shambler")
    if not LOD.Config.Encounter.Archetypes[archetype] then
        tell(ply, "usage: lod_m3_stair shambler|runner|soldier [index] [up|down]")
        return
    end
    local graph = LOD.RunManager.State.Graph
    if not graph or not LOD.RunManager.State.BuildReady then tell(ply, "no built level active") return end
    local edges = sortedVerticalEdges(graph)
    if #edges == 0 then tell(ply, "current level has no vertical edges") return end

    local index = math.Clamp(math.floor(tonumber(args[2]) or 1), 1, #edges)
    local direction = string.lower(args[3] or "up")
    if direction ~= "up" and direction ~= "down" then direction = "up" end
    local edge = edges[index]
    local homeCell, hostilePos, playerPos = stairTestPositions(edge, direction)

    removeActiveHostiles()
    LOD.RunManager:MarkUnranked("Milestone 3 stair traversal test")
    ply:SetHealth(100)
    ply:SetPos(playerPos)
    ply:SetVelocity(-ply:GetVelocity())

    local ent, err = spawnDebugHostile(ply, archetype, homeCell, hostilePos)
    if not ent then tell(ply, err) return end
    LOD.M3DebugStairHostile = ent
    LOD.M3DebugStairIndex = index
    tell(ply, string.format("stair test #%d %s: %s must traverse %s toward player; home=%s",
        index, direction, archetype, direction == "up" and "UP the stair" or "DOWN the stair", cellText(homeCell)))
end)

concommand.Add("lod_m3_hostiles", function(ply)
    if not developerAllowed(ply) then return end
    local graph = LOD.RunManager.State.Graph
    if not graph then tell(ply, "no built level active") return end
    local found = 0
    for _, ent in ipairs(ents.FindByClass("lod_hostile")) do
        if IsValid(ent) then
            found = found + 1
            local current = LOD.MazeNavigator:WorldToCell(graph, ent:GetPos())
            local home = ent:GetLODHomeCell(graph)
            local homeDistance = current and home and LOD.MazeNavigator:Distance(graph, home, current) or math.huge
            tell(ply, string.format("hostile #%d %s cell=%s home=%s homeDistance=%s returning=%s target=%s",
                ent:EntIndex(), tostring(ent.LODArchetypeId), cellText(current), cellText(home),
                homeDistance == math.huge and "inf" or tostring(homeDistance),
                tostring(ent.LODReturningHome == true),
                IsValid(ent.LODTarget) and ent.LODTarget:Nick() or "none"))
        end
    end
    if found == 0 then tell(ply, "no active lod_hostile entities") end
end)

concommand.Add("lod_m3_leash", function(ply, _, args)
    if not developerAllowed(ply) or not IsValid(ply) then return end
    local archetype = string.lower(args[1] or "shambler")
    if not LOD.Config.Encounter.Archetypes[archetype] then tell(ply, "usage: lod_m3_leash shambler|runner|soldier") return end
    local graph = LOD.RunManager.State.Graph
    if not graph or not LOD.RunManager.State.BuildReady then tell(ply, "no built level active") return end

    local home = chooseDebugCell(graph, ply)
    if not home then tell(ply, "could not find a leash-test home cell 2-3 steps away") return end
    removeActiveHostiles()
    local ent, err = spawnDebugHostile(ply, archetype, home)
    if not ent then tell(ply, err) return end
    LOD.M3DebugLeash = {hostile = ent, home = home}
    tell(ply, string.format("leash test armed: %s home=%s. Let it approach, then run lod_m3_leash_retreat.", archetype, cellText(home)))
end)

concommand.Add("lod_m3_leash_retreat", function(ply)
    if not developerAllowed(ply) or not IsValid(ply) then return end
    local graph = LOD.RunManager.State.Graph
    local test = LOD.M3DebugLeash
    if not graph or not test or not IsValid(test.hostile) or not test.home then tell(ply, "run lod_m3_leash <archetype> first") return end

    local wanted = LOD.Config.Encounter.LeashCells + 2
    local destination, destinationDistance
    for _, cell in ipairs(sortedCells(graph)) do
        local d = LOD.MazeNavigator:Distance(graph, test.home, cell)
        if d ~= math.huge and d >= wanted and (not destinationDistance or d < destinationDistance) then
            destination, destinationDistance = cell, d
        end
    end
    if not destination then tell(ply, "could not find a currently traversable cell beyond leash distance") return end

    ply:SetPos(LOD.MazeNavigator:CellCenter(destination) + Vector(0, 0, 24))
    ply:SetVelocity(-ply:GetVelocity())
    LOD.RunManager:MarkUnranked("Milestone 3 leash test")
    tell(ply, string.format("retreated to %s, %d graph cells from hostile home; leash=%d. Hostile should disengage and return home.",
        cellText(destination), destinationDistance, LOD.Config.Encounter.LeashCells))
end)

concommand.Add("lod_m3_leash_status", function(ply)
    if not developerAllowed(ply) then return end
    local graph = LOD.RunManager.State.Graph
    local test = LOD.M3DebugLeash
    if not graph or not test or not IsValid(test.hostile) then tell(ply, "no active leash test") return end
    local ent = test.hostile
    local current = LOD.MazeNavigator:WorldToCell(graph, ent:GetPos())
    local d = current and LOD.MazeNavigator:Distance(graph, test.home, current) or math.huge
    tell(ply, string.format("leash hostile cell=%s home=%s homeDistance=%s returning=%s target=%s",
        cellText(current), cellText(test.home), d == math.huge and "inf" or tostring(d),
        tostring(ent.LODReturningHome == true), IsValid(ent.LODTarget) and ent.LODTarget:Nick() or "none"))
end)

concommand.Add("lod_m3_killall", function(ply)
    if not developerAllowed(ply) then return end
    local count = removeActiveHostiles()
    LOD.M3DebugLeash = nil
    LOD.M3DebugStairHostile = nil
    LOD.RunManager:MarkUnranked("Milestone 3 debug hostile cleanup")
    tell(ply, "removed " .. count .. " active hostiles")
end)

-- Temporary Milestone-3 test aid only. The real starting kit and ammunition
-- economy belong to Milestone 4; this command keeps combat testing from
-- silently implementing those systems early.
concommand.Add("lod_m3_testkit", function(ply)
    if not developerAllowed(ply) or not IsValid(ply) or not ply:Alive() then return end
    local pistol = ply:Give("weapon_pistol", true)
    ply:Give("weapon_crowbar", true)
    ply:GiveAmmo(90, "Pistol", true)
    if IsValid(pistol) then ply:SelectWeapon("weapon_pistol") end
    LOD.RunManager:MarkUnranked("Milestone 3 developer combat kit")
    tell(ply, "developer combat kit granted: crowbar + pistol + 90 pistol rounds")
end)
