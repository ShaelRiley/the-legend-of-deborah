-- Headless logical-maze regression test for The Legend of Deborah.
-- Run from the repository root with a Lua interpreter:
--   lua tools/headless_seed_test.lua 1000
-- It executes the production RNG and MazeGenerator with minimal GMod stubs.

LOD = {}

function Vector(x, y, z) return {x = x, y = y, z = z} end
function Color(r, g, b, a) return {r = r, g = g, b = b, a = a or 255} end
function table.Count(t)
    local count = 0
    for _ in pairs(t) do count = count + 1 end
    return count
end

assert(loadfile("gamemodes/legend_of_deborah/gamemode/lod/sh_config.lua"))()
assert(loadfile("gamemodes/legend_of_deborah/gamemode/lod/sh_rng.lua"))()
assert(loadfile("gamemodes/legend_of_deborah/gamemode/lod/sv_maze_generator.lua"))()

local function edgeSignature(edge)
    local a = string.format("%d:%d:%d", edge.a.x, edge.a.y, edge.a.z)
    local b = string.format("%d:%d:%d", edge.b.x, edge.b.y, edge.b.z)
    if a > b then a, b = b, a end
    return a .. ">" .. b
end

local HASH_MOD = 2147483647
local function hashString(value)
    local h = 1
    for i = 1, #value do
        h = (h * 131 + string.byte(value, i)) % HASH_MOD
    end
    return h
end

local function fingerprint(graph)
    local cells = {}
    for key in pairs(graph.Cells) do cells[#cells + 1] = key end
    table.sort(cells)

    local edges = {}
    for _, edge in pairs(graph.Edges) do edges[#edges + 1] = edgeSignature(edge) end
    table.sort(edges)

    return table.concat({
        tostring(graph.Layers),
        table.concat(cells, ","),
        table.concat(edges, ",")
    }, "|")
end

local requested = tonumber(arg and arg[1]) or 1000
local count = math.max(1, math.floor(requested))
local failures = 0
local maximumAttempt = 0
local totalAttempts = 0
local minimumVertical = math.huge
local minimumCells = math.huge
local maximumCells = 0
local layerCounts = {}
local aggregateHash = 1

for seed = 1, count do
    local graph, err = LOD.MazeGenerator:Generate(seed)
    if not graph then
        failures = failures + 1
        io.stderr:write(string.format("seed %d failed: %s\n", seed, tostring(err)))
    else
        -- Re-run a representative prefix to verify exact same-seed topology
        -- without doubling the cost of large generation sweeps.
        if seed <= math.min(count, 25) then
            local replay, replayErr = LOD.MazeGenerator:Generate(seed)
            if not replay or fingerprint(graph) ~= fingerprint(replay) then
                failures = failures + 1
                io.stderr:write(string.format("seed %d is not reproducible: %s\n", seed, tostring(replayErr)))
            end
        end

        aggregateHash = (aggregateHash * 131 + hashString(fingerprint(graph))) % HASH_MOD
        maximumAttempt = math.max(maximumAttempt, graph.Attempt)
        totalAttempts = totalAttempts + graph.Attempt
        minimumVertical = math.min(minimumVertical, graph.Validation.criticalVerticalTransitions)
        minimumCells = math.min(minimumCells, graph.Validation.cellCount)
        maximumCells = math.max(maximumCells, graph.Validation.cellCount)
        layerCounts[graph.Layers] = (layerCounts[graph.Layers] or 0) + 1
    end
end

local successes = count - failures
print(string.format(
    "seeds=%d failures=%d hash=%d maxAttempt=%d avgAttempt=%.3f minVertical=%s cells=%s..%s layers(2/3/4)=%d/%d/%d",
    count,
    failures,
    aggregateHash,
    maximumAttempt,
    successes > 0 and totalAttempts / successes or 0,
    minimumVertical == math.huge and "n/a" or tostring(minimumVertical),
    minimumCells == math.huge and "n/a" or tostring(minimumCells),
    maximumCells == 0 and "n/a" or tostring(maximumCells),
    layerCounts[2] or 0,
    layerCounts[3] or 0,
    layerCounts[4] or 0
))

if failures > 0 then os.exit(1) end
