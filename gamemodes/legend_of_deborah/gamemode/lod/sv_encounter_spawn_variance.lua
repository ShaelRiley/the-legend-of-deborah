LOD = LOD or {}
LOD.EncounterSpawnVariance = LOD.EncounterSpawnVariance or {}

local EncounterDirector = LOD.EncounterDirector
local EnemyVariance = LOD.EnemyVariance
local EC = LOD.Config.Encounter

if not EncounterDirector then return end

local SPAWN_ORDER = {"shambler", "runner", "deadcrab", "bioblaster", "soldier"}

local function cellKey(cell)
    return cell and LOD.MazeGenerator.CellKey(cell.x, cell.y, cell.z) or nil
end

local function stairCellSet(graph)
    graph.LODEncounterStairCellSet = graph.LODEncounterStairCellSet or nil
    if graph.LODEncounterStairCellSet then return graph.LODEncounterStairCellSet end

    local out = {}
    for _, edge in ipairs(graph.VerticalEdges or {}) do
        out[cellKey(edge.a)] = true
        out[cellKey(edge.b)] = true
    end
    graph.LODEncounterStairCellSet = out
    return out
end

local function safeEncounterSpawnCell(encounter)
    local state = LOD.RunManager and LOD.RunManager.State
    local graph = state and state.Graph
    if not graph or not encounter or not encounter.cell then return encounter and encounter.cell end

    local stairs = stairCellSet(graph)
    if not stairs[encounter.cellKey] then return encounter.cell end

    -- Encounters may pursue across stairs, but they should not originate on a
    -- stair endpoint. Move the authored spawn origin into the first deterministic
    -- same-level non-stair neighbor while preserving encounter bookkeeping.
    local origin = graph.Cells[encounter.cellKey]
    if not origin then return encounter.cell end

    local candidates = {}
    for neighborKey in pairs(origin.neighbors or {}) do
        local neighbor = graph.Cells[neighborKey]
        if neighbor and neighbor.z == origin.z and not stairs[neighborKey] then
            candidates[#candidates + 1] = neighbor
        end
    end
    table.sort(candidates, function(a, b) return cellKey(a) < cellKey(b) end)
    return candidates[1] or encounter.cell
end

-- Unify the authored encounter spawn path after all archetype planner wrappers
-- have loaded. Every production encounter unit receives a stable ordinal BEFORE
-- Spawn(), so deterministic instance variance never depends on entity index.
if not EncounterDirector.LODUnifiedVarianceSpawner then
    EncounterDirector.LODUnifiedVarianceSpawner = true

    function EncounterDirector:_SpawnEncounter(encounter)
        if not encounter or encounter.spawned or encounter.cleared then return true end

        local total = 0
        for _, count in pairs(encounter.composition or {}) do total = total + count end
        if self:GetActiveCount() + total > EC.ActiveHostileCeiling then return false end

        local spawnCell = safeEncounterSpawnCell(encounter)
        local spawnCellKey = cellKey(spawnCell) or encounter.cellKey
        local relocatedFromStair = spawnCellKey ~= encounter.cellKey
        local center = LOD.MazeNavigator:CellCenter(spawnCell) + Vector(0, 0, 2)
        local offsets = self:_SpawnOffsets(total)
        local ordinal = 1

        for _, archetypeId in ipairs(SPAWN_ORDER) do
            local count = encounter.composition and encounter.composition[archetypeId] or 0
            for _ = 1, count do
                local ent = ents.Create("lod_hostile")
                if IsValid(ent) then
                    ent.LODArchetypeId = archetypeId
                    ent.LODHomeCellKey = spawnCellKey
                    ent.LODEncounterId = encounter.id
                    ent.LODEncounterOrdinal = ordinal
                    ent.LODSpawnSource = "encounter"
                    ent.LODSpawnRelocatedFromStair = relocatedFromStair
                    ent.LODActivated = true
                    ent:SetPos(center + offsets[ordinal])
                    ent:Spawn()
                    ent:Activate()

                    -- Fail-safe: Initialize should already have applied variance.
                    if IsValid(ent) and not ent.LODVariance and EnemyVariance and EnemyVariance.Apply then
                        EnemyVariance:Apply(ent)
                    end

                    if IsValid(ent) then
                        -- Motion V2 owns spawn settlement. Do not call DropToFloor
                        -- or ClearStuck here: those belong to the retired Source
                        -- ground-locomotion architecture.
                        if LOD.HostileMotionV2 and LOD.HostileMotionV2.SnapSpawn then
                            LOD.HostileMotionV2:SnapSpawn(ent)
                        end
                        ent.LODNextRouteRefresh = 0
                        encounter.entities[#encounter.entities + 1] = ent
                        self.Entities[#self.Entities + 1] = ent
                    end
                end
                ordinal = ordinal + 1
            end
        end

        encounter.spawned = true
        encounter.activated = true
        return true
    end
end

local function developerAllowed(ply)
    local cv = GetConVar("lod_developer_mode")
    if cv and not cv:GetBool() then return false end
    return not IsValid(ply) or ply:IsAdmin()
end

local function tell(ply, text)
    print("[LOD:MAP-VARIANCE] " .. text)
    if IsValid(ply) then ply:ChatPrint(text) end
end

concommand.Add("lod_m3_map_variance", function(ply)
    if not developerAllowed(ply) then return end

    local total, missing, missingOrdinal = 0, 0, 0
    local distinct = {}
    for _, hostile in ipairs(ents.FindByClass("lod_hostile")) do
        if IsValid(hostile) and hostile.LODEncounterId then
            total = total + 1
            if not hostile.LODVariance then missing = missing + 1 end
            if not hostile.LODEncounterOrdinal then missingOrdinal = missingOrdinal + 1 end

            local size = hostile:GetNW2Float("LOD_SizeScale", 1)
            distinct[string.format("%.4f", size)] = true
            tell(ply, string.format(
                "encounter=%s ordinal=%s #%d %-10s size=%.4f hp=%d speed=%.1f seed=%s stairRelocated=%s",
                tostring(hostile.LODEncounterId), tostring(hostile.LODEncounterOrdinal),
                hostile:EntIndex(), tostring(hostile.LODArchetypeId), size,
                hostile:Health(), hostile.LODConfig and hostile.LODConfig.speed or 0,
                tostring(hostile.LODInstanceSeed or "none"),
                tostring(hostile.LODSpawnRelocatedFromStair == true)
            ))
        end
    end

    if total == 0 then
        tell(ply, "no active authored encounter monsters; approach an encounter and run again")
        return
    end

    local unique = table.Count(distinct)
    local passed = missing == 0 and missingOrdinal == 0
    tell(ply, string.format("%s total=%d uniqueSizes=%d missingVariance=%d missingOrdinal=%d",
        passed and "PASS" or "FAIL", total, unique, missing, missingOrdinal))
end)
