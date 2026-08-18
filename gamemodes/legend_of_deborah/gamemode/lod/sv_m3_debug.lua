LOD = LOD or {}

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

local function chooseDebugCell(graph, ply)
    local start = LOD.MazeNavigator:WorldToCell(graph, ply:GetPos())
    if not start then return nil end
    local choices = {}
    for _, cell in pairs(graph.Cells) do
        local distance = LOD.MazeNavigator:Distance(graph, start, cell)
        if distance >= 2 and distance <= 3 then choices[#choices + 1] = cell end
    end
    table.sort(choices, function(a, b)
        local ka = LOD.MazeGenerator.CellKey(a.x, a.y, a.z)
        local kb = LOD.MazeGenerator.CellKey(b.x, b.y, b.z)
        return ka < kb
    end)
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

    local ent = ents.Create("lod_hostile")
    if not IsValid(ent) then tell(ply, "failed to create lod_hostile") return end
    local k = LOD.MazeGenerator.CellKey(cell.x, cell.y, cell.z)
    ent.LODArchetypeId = archetype
    ent.LODHomeCellKey = k
    ent.LODEncounterId = nil
    ent.LODActivated = true
    ent:SetPos(LOD.MazeNavigator:CellCenter(cell) + Vector(0, 0, 10))
    ent:Spawn()
    ent:Activate()
    ent:DropToFloor()
    LOD.EncounterDirector.Entities[#LOD.EncounterDirector.Entities + 1] = ent
    LOD.RunManager:MarkUnranked("Milestone 3 hostile debug spawn")
    tell(ply, string.format("spawned %s at %s, %d graph steps from player", cfg.name, cellText(cell),
        LOD.MazeNavigator:Distance(graph, LOD.MazeNavigator:WorldToCell(graph, ply:GetPos()), cell)))
end)

concommand.Add("lod_m3_tp", function(ply, _, args)
    if not developerAllowed(ply) or not IsValid(ply) then return end
    if string.lower(args[1] or "") ~= "encounter" then tell(ply, "usage: lod_m3_tp encounter <id>") return end
    local id = math.floor(tonumber(args[2]) or 1)
    local graph = LOD.RunManager.State.Graph
    local plan = graph and graph.EncounterPlan
    local encounter = plan and plan.encounters[id]
    if not encounter then tell(ply, "unknown encounter id") return end
    LOD.RunManager:MarkUnranked("Milestone 3 encounter debug teleport")
    ply:SetPos(LOD.MazeNavigator:CellCenter(encounter.cell) + Vector(0, 0, 24))
    ply:SetVelocity(-ply:GetVelocity())
    tell(ply, "teleported to encounter #" .. id .. " " .. tostring(encounter.templateName))
end)

concommand.Add("lod_m3_killall", function(ply)
    if not developerAllowed(ply) then return end
    local count = 0
    for _, ent in ipairs(LOD.EncounterDirector.Entities or {}) do
        if IsValid(ent) then ent:Remove() count = count + 1 end
    end
    LOD.EncounterDirector.Entities = {}
    LOD.RunManager:MarkUnranked("Milestone 3 debug hostile cleanup")
    tell(ply, "removed " .. count .. " active hostiles")
end)
