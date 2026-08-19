LOD = LOD or {}
LOD.EncounterSpawnVariance = LOD.EncounterSpawnVariance or {}

local EncounterDirector = LOD.EncounterDirector
local EnemyVariance = LOD.EnemyVariance
local EC = LOD.Config.Encounter

if not EncounterDirector then return end

local SPAWN_ORDER = {"shambler", "runner", "deadcrab", "bioblaster", "soldier"}

-- Unify the authored encounter spawn path after all archetype planner wrappers
-- have loaded. Every production encounter unit receives a stable ordinal BEFORE
-- Spawn(), so deterministic instance variance never has to depend on entity index
-- or post-spawn position as its primary identity.
if not EncounterDirector.LODUnifiedVarianceSpawner then
    EncounterDirector.LODUnifiedVarianceSpawner = true

    function EncounterDirector:_SpawnEncounter(encounter)
        if not encounter or encounter.spawned or encounter.cleared then return true end

        local total = 0
        for _, count in pairs(encounter.composition or {}) do
            total = total + count
        end
        if self:GetActiveCount() + total > EC.ActiveHostileCeiling then return false end

        local center = LOD.MazeNavigator:CellCenter(encounter.cell) + Vector(0, 0, 10)
        local offsets = self:_SpawnOffsets(total)
        local ordinal = 1

        for _, archetypeId in ipairs(SPAWN_ORDER) do
            local count = encounter.composition and encounter.composition[archetypeId] or 0
            for _ = 1, count do
                local ent = ents.Create("lod_hostile")
                if IsValid(ent) then
                    ent.LODArchetypeId = archetypeId
                    ent.LODHomeCellKey = encounter.cellKey
                    ent.LODEncounterId = encounter.id
                    ent.LODEncounterOrdinal = ordinal
                    ent.LODSpawnSource = "encounter"
                    ent.LODActivated = true
                    ent:SetPos(center + offsets[ordinal])
                    ent:Spawn()
                    ent:Activate()

                    -- Fail-safe: the Initialize wrapper should already have
                    -- applied variance. If another archetype wrapper ever changes
                    -- initialization order, production encounter monsters still
                    -- cannot silently fall back to uniform 1.0x size/stat values.
                    if IsValid(ent) and not ent.LODVariance and EnemyVariance and EnemyVariance.Apply then
                        EnemyVariance:Apply(ent)
                    end

                    if IsValid(ent) then
                        ent:DropToFloor()
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

-- Audits only actual EncounterDirector-spawned monsters, excluding console
-- debug spawns. Useful for proving that the maze population itself is varied.
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
                "encounter=%s ordinal=%s #%d %-10s size=%.4f hp=%d speed=%.1f seed=%s",
                tostring(hostile.LODEncounterId), tostring(hostile.LODEncounterOrdinal),
                hostile:EntIndex(), tostring(hostile.LODArchetypeId), size,
                hostile:Health(), hostile.LODConfig and hostile.LODConfig.speed or 0,
                tostring(hostile.LODInstanceSeed or "none")
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
