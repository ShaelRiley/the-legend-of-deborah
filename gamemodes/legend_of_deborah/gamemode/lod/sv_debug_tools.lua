LOD = LOD or {}

util.AddNetworkString("LOD_DebugGraphBegin")
util.AddNetworkString("LOD_DebugGraphEdge")
util.AddNetworkString("LOD_DebugGraphEnd")

local function allowed(ply)
    return not IsValid(ply) or ply:IsAdmin()
end

local function sendGraph(ply)
    local graph = LOD.RunManager.State.Graph
    if not graph or not IsValid(ply) then return end

    net.Start("LOD_DebugGraphBegin")
    net.WriteUInt(graph.Layers, 3)
    net.WriteUInt(table.Count(graph.Cells), 12)
    net.Send(ply)

    for _, edge in pairs(graph.Edges) do
        net.Start("LOD_DebugGraphEdge")
        net.WriteVector(LOD.MazeBuilder:CellCenter(edge.a) + Vector(0, 0, 40))
        net.WriteVector(LOD.MazeBuilder:CellCenter(edge.b) + Vector(0, 0, 40))
        net.WriteBool(edge.a.z ~= edge.b.z)
        net.Send(ply)
    end

    net.Start("LOD_DebugGraphEnd")
    net.Send(ply)
end

concommand.Add("lod_debug_graph", function(ply)
    if not allowed(ply) then return end
    if IsValid(ply) then sendGraph(ply) end
end)

concommand.Add("lod_regenerate", function(ply, _, args)
    if not allowed(ply) then return end
    local override = tonumber(args[1])
    local ok, result = LOD.RunManager:Regenerate(override)
    local message = ok and "regenerated" or ("failed: " .. tostring(result))
    if IsValid(ply) then ply:ChatPrint("LOD " .. message) else print("[LOD] " .. message) end
end)

concommand.Add("lod_validation", function(ply)
    if not allowed(ply) then return end
    local graph = LOD.RunManager.State.Graph
    if not graph then return end
    local v = graph.Validation
    local line = string.format(
        "valid=%s cells=%d reachable=%d criticalPath=%d vertical=%d attempt=%d",
        tostring(v.valid), v.cellCount, v.reachableCount, v.criticalPathLength,
        v.criticalVerticalTransitions, graph.Attempt
    )
    if IsValid(ply) then ply:ChatPrint(line) else print("[LOD] " .. line) end
end)

concommand.Add("lod_seed_test", function(ply, _, args)
    if not allowed(ply) then return end
    local count = math.Clamp(tonumber(args[1]) or 100, 1, LOD.Config.Debug.SeedTestMax)
    local base = LOD.RunManager.State.LevelSeed or 1
    local failures = 0
    local worstAttempts = 0
    local minVertical = 999

    for i = 1, count do
        local seed = LOD.Seeds.Derive(base, "seed-test:" .. i)
        local graph = LOD.MazeGenerator:Generate(seed)
        if not graph then
            failures = failures + 1
        else
            worstAttempts = math.max(worstAttempts, graph.Attempt)
            minVertical = math.min(minVertical, graph.Validation.criticalVerticalTransitions)
        end
    end

    local report = string.format(
        "seed test: %d generated, %d failures, worst attempts=%d, min critical vertical=%d",
        count, failures, worstAttempts, minVertical == 999 and 0 or minVertical
    )
    print("[LOD] " .. report)
    if IsValid(ply) then ply:ChatPrint(report) end
end)
