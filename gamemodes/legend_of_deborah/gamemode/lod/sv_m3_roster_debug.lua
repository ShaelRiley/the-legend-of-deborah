LOD = LOD or {}

local function developerAllowed(ply)
    local cv = GetConVar("lod_developer_mode")
    if cv and not cv:GetBool() then return false end
    return not IsValid(ply) or ply:IsAdmin()
end

local function tell(ply, text)
    print("[LOD:M3-ROSTER] " .. text)
    if IsValid(ply) then ply:ChatPrint(text) end
end

local function sortedArchetypes()
    local preferred = {"shambler", "runner", "soldier", "blitzer", "deadcrab", "bioblaster"}
    local out, seen = {}, {}
    for _, id in ipairs(preferred) do
        if LOD.Config.Encounter.Archetypes[id] then
            out[#out + 1] = id
            seen[id] = true
        end
    end
    for id in pairs(LOD.Config.Encounter.Archetypes or {}) do
        if not seen[id] then out[#out + 1] = id end
    end
    return out
end

local function cellText(cell)
    if not cell then return "nil" end
    return string.format("(%d,%d,%d)", cell.x, cell.y, cell.z)
end

concommand.Add("lod_m3_roster", function(ply)
    if not developerAllowed(ply) then return end
    for _, id in ipairs(sortedArchetypes()) do
        local cfg = LOD.Config.Encounter.Archetypes[id]
        tell(ply, string.format("%-10s name=%s baseHP=%s speed=%s threat=%s",
            id, tostring(cfg.name), tostring(cfg.baseHP), tostring(cfg.speed), tostring(cfg.threat)))
    end
    tell(ply, "spawn syntax: lod_m3_spawn <shambler|runner|soldier|deadcrab|bioblaster>")
end)

concommand.Add("lod_m3_plan_full", function(ply)
    if not developerAllowed(ply) then return end
    local graph = LOD.RunManager and LOD.RunManager.State and LOD.RunManager.State.Graph
    local plan = graph and graph.EncounterPlan
    if not plan then tell(ply, "no encounter plan active") return end

    local ids = sortedArchetypes()
    for _, encounter in ipairs(plan.encounters or {}) do
        local parts = {}
        for _, id in ipairs(ids) do
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
