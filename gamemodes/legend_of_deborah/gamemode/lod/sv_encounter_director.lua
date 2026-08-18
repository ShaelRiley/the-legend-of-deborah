LOD = LOD or {}
LOD.EncounterDirector = LOD.EncounterDirector or {}

local EncounterDirector = LOD.EncounterDirector
local EC = LOD.Config.Encounter
local cellKey = LOD.MazeGenerator.CellKey

EncounterDirector.Entities = EncounterDirector.Entities or {}
EncounterDirector.Plan = EncounterDirector.Plan or nil

local function keyOf(cell)
    return cell and cellKey(cell.x, cell.y, cell.z) or nil
end

local function sortedKeys(t)
    local out = {}
    for k in pairs(t or {}) do out[#out + 1] = k end
    table.sort(out)
    return out
end

local function copyComposition(source)
    local out = {}
    for id, count in pairs(source or {}) do out[id] = count end
    return out
end

local function compositionThreat(composition)
    local total = 0
    for id, count in pairs(composition or {}) do
        local cfg = EC.Archetypes[id]
        total = total + (cfg and cfg.threat or 0) * count
    end
    return total
end

local function edgeKey(a, b)
    return LOD.MazeNavigator:EdgeKey(a, b)
end

local function connectedComponent(graph, startCell, blocked)
    local startKey = keyOf(startCell)
    local seen = {[startKey] = true}
    local queue = {startKey}
    local head = 1
    while head <= #queue do
        local currentKey = queue[head]
        head = head + 1
        local current = graph.Cells[currentKey]
        if current then
            for _, neighborKey in ipairs(sortedKeys(current.neighbors)) do
                local ek = edgeKey(currentKey, neighborKey)
                if not seen[neighborKey] and not blocked[ek] then
                    seen[neighborKey] = true
                    queue[#queue + 1] = neighborKey
                end
            end
        end
    end
    return seen
end

local function cellDegree(graph, cell)
    return table.Count(graph.Cells[keyOf(cell)].neighbors or {})
end

local function isCorner(graph, cell)
    local neighbors = {}
    for neighborKey in pairs(graph.Cells[keyOf(cell)].neighbors or {}) do
        local n = graph.Cells[neighborKey]
        if n and n.z == cell.z then neighbors[#neighbors + 1] = n end
    end
    if #neighbors ~= 2 then return false end
    local a, b = neighbors[1], neighbors[2]
    local adx, ady = a.x - cell.x, a.y - cell.y
    local bdx, bdy = b.x - cell.x, b.y - cell.y
    return adx ~= -bdx or ady ~= -bdy
end

function EncounterDirector:_BuildSectorMap(graph)
    local progression = graph.Progression
    local blocked = {}
    for _, gate in ipairs(progression.Gates or {}) do blocked[gate.edgeKey] = true end

    local starts = {
        graph.Start,
        progression.Gates[1] and progression.Gates[1].afterCell,
        progression.Gates[2] and progression.Gates[2].afterCell,
        progression.Gates[3] and progression.Gates[3].afterCell
    }

    local sectorByKey = {}
    for sector = 1, 4 do
        local start = starts[sector]
        if start then
            for k in pairs(connectedComponent(graph, start, blocked)) do
                if not sectorByKey[k] then sectorByKey[k] = sector end
            end
        end
    end

    -- Defensive fallback for any graph cell not assigned due to malformed
    -- progression data. The planner later rejects encounter use of unknown cells.
    return sectorByKey
end

function EncounterDirector:_BuildCellTags(graph, sectorByKey)
    local tags = {}
    for k, cell in pairs(graph.Cells) do
        tags[k] = {sector = sectorByKey[k], role = "travel", safe = false}
        local degree = cellDegree(graph, cell)
        if degree <= 1 then
            tags[k].role = "reward"
        elseif degree >= 3 then
            tags[k].role = degree >= 4 and "arena" or "ambush"
        elseif isCorner(graph, cell) then
            tags[k].role = "ambush"
        end
    end

    local function markSafe(cell, role)
        local k = keyOf(cell)
        if tags[k] then tags[k].safe = true tags[k].role = role or "safe" end
    end

    markSafe(graph.Start, "safe")
    local progression = graph.Progression
    for _, gate in ipairs(progression.Gates or {}) do
        markSafe(gate.afterCell, "safe")
        local after = graph.Cells[keyOf(gate.afterCell)]
        if after then
            for neighborKey in pairs(after.neighbors or {}) do
                if tags[neighborKey] and tags[neighborKey].sector == tags[keyOf(gate.afterCell)].sector then
                    tags[neighborKey].safe = true
                    tags[neighborKey].role = "safe"
                end
            end
        end
        markSafe(gate.beforeCell, "resupply")
    end

    for _, card in ipairs(progression.Keycards or {}) do
        local k = keyOf(card.cell)
        if tags[k] then tags[k].role = "objective" tags[k].objective = true end
    end

    markSafe(progression.CoreCell, "boss")
    markSafe(progression.DeborahCell, "safe")

    graph.CellTags = tags
    return tags
end

function EncounterDirector:_TemplateComposition(templateId, rng, scale)
    local template = EC.Templates[templateId]
    if not template then return nil end
    local composition = copyComposition(template.composition)
    if template.variableShambler and rng:Chance(0.5) then
        composition.shambler = (composition.shambler or 0) + 1
    end

    -- Later campaign levels and larger parties can enrich a template without
    -- changing its tactical identity: only archetypes already present in that
    -- template are duplicated. Budget scaling does most of the difficulty work.
    local targetThreat = compositionThreat(composition) * math.sqrt(math.max(1, scale or 1))
    local ids = sortedKeys(composition)
    local cursor = 1
    while compositionThreat(composition) + 0.01 < targetThreat and #ids > 0 do
        local id = ids[cursor]
        composition[id] = composition[id] + 1
        cursor = cursor % #ids + 1
        if compositionThreat(composition) > targetThreat * 1.15 then break end
    end
    return composition
end

function EncounterDirector:_ThreatScale()
    local level = LOD.RunManager and LOD.RunManager.State.Level or 1
    local party = LOD.RunManager and math.Clamp(LOD.RunManager:_ActiveCount(), 1, LOD.Config.MaxActivePlayers) or 1
    local partyScale = EC.PartyThreatMultiplier[party] or 1
    local campaignScale = 1 + EC.CampaignThreatGrowthPerLevel * math.max(0, level - 1)
    return partyScale * campaignScale
end

function EncounterDirector:_AddEncounter(plan, cell, sector, role, templateId, composition, objective)
    local id = #plan.encounters + 1
    local encounter = {
        id = id,
        cell = {x = cell.x, y = cell.y, z = cell.z},
        cellKey = keyOf(cell),
        sector = sector,
        role = role,
        templateId = templateId,
        templateName = EC.Templates[templateId] and EC.Templates[templateId].name or templateId,
        composition = composition,
        threat = compositionThreat(composition),
        objective = objective == true,
        activated = false,
        cleared = false,
        spawned = false,
        entities = {}
    }
    plan.encounters[id] = encounter
    return encounter
end

function EncounterDirector:_FarEnough(graph, plan, cell)
    for _, encounter in ipairs(plan.encounters) do
        if encounter.cell then
            local distance = LOD.MazeNavigator:Distance(graph, cell, encounter.cell)
            if distance < EC.MajorSpacingCells then return false end
        end
    end
    return true
end

function EncounterDirector:_VisibleFromStart(graph, cell)
    local startPos = LOD.MazeNavigator:CellCenter(graph.Start) + Vector(0, 0, 64)
    local endPos = LOD.MazeNavigator:CellCenter(cell) + Vector(0, 0, 40)
    local tr = util.TraceLine({start = startPos, endpos = endPos, mask = MASK_SOLID_BRUSHONLY})
    return tr.Fraction >= 0.995
end

function EncounterDirector:_EligibleTemplates(sector, role)
    if sector == 1 then
        return role == "ambush" and {"runner_ambush", "rush", "patrol"} or {"patrol", "rush"}
    elseif sector == 2 then
        if role == "arena" then return {"mixed_pressure", "firing_line", "rush"} end
        return {"rush", "mixed_pressure", "runner_ambush", "patrol"}
    elseif sector == 3 then
        if role == "arena" or role == "reward" then return {"arena", "mixed_pressure", "firing_line"} end
        return {"mixed_pressure", "firing_line", "runner_ambush", "rush"}
    end
    if role == "arena" or role == "reward" then return {"arena", "firing_line", "mixed_pressure"} end
    return {"mixed_pressure", "firing_line", "rush", "runner_ambush"}
end

function EncounterDirector:BuildPlan(graph)
    if not graph or not graph.Progression then return false, "encounter planning requires progression graph" end

    self:Cleanup()
    local sectorByKey = self:_BuildSectorMap(graph)
    local tags = self:_BuildCellTags(graph, sectorByKey)
    local seed = LOD.Seeds.Derive(graph.MasterLevelSeed or graph.LevelSeed or 1, "encounters")
    local rng = LOD.RNG.New(seed)
    local scale = self:_ThreatScale()
    local plan = {seed = seed, encounters = {}, sectorBudget = {}, sectorSpent = {}, tags = tags}

    -- Guaranteed keycard encounters are tuned independently of discretionary
    -- wandering encounters, as required by the GDD.
    local objectiveTemplates = {"red_keycard", "blue_keycard", "yellow_keycard"}
    for index, card in ipairs(graph.Progression.Keycards or {}) do
        local cell = graph.Cells[keyOf(card.cell)]
        local sector = sectorByKey[keyOf(card.cell)] or index
        local composition = self:_TemplateComposition(objectiveTemplates[index], rng:Derive("objective:" .. index), scale)
        self:_AddEncounter(plan, cell, sector, "objective", objectiveTemplates[index], composition, true)
    end

    for sector = 1, 4 do
        local budget = (EC.SectorBaseThreat[sector] or 5) * scale
        plan.sectorBudget[sector] = budget
        plan.sectorSpent[sector] = 0

        local candidates = {}
        for k, cell in pairs(graph.Cells) do
            local tag = tags[k]
            if tag and tag.sector == sector and not tag.safe and not tag.objective and tag.role ~= "boss" and tag.role ~= "resupply" then
                local startDistance = LOD.MazeNavigator:Distance(graph, graph.Start, cell)
                if startDistance >= EC.ActivationDistanceCells + 1
                    and self:_FarEnough(graph, plan, cell)
                    and not self:_VisibleFromStart(graph, cell)
                then
                    candidates[#candidates + 1] = cell
                end
            end
        end
        rng:Shuffle(candidates)

        local placed = 0
        local maximum = EC.MaxDiscretionaryPerSector[sector] or 1
        for _, cell in ipairs(candidates) do
            if placed >= maximum then break end
            local role = tags[keyOf(cell)].role
            local choices = self:_EligibleTemplates(sector, role)
            local templateId = rng:Pick(choices)
            local composition = self:_TemplateComposition(templateId, rng:Derive("sector:" .. sector .. ":cell:" .. keyOf(cell)), scale)
            local cost = compositionThreat(composition)
            local remaining = budget - plan.sectorSpent[sector]
            if cost <= remaining + 0.5 or placed == 0 then
                self:_AddEncounter(plan, cell, sector, role, templateId, composition, false)
                plan.sectorSpent[sector] = plan.sectorSpent[sector] + cost
                placed = placed + 1
            end
        end
    end

    graph.EncounterPlan = plan
    self.Plan = plan
    return true, plan
end

function EncounterDirector:GetActiveCount()
    local alive = 0
    local kept = {}
    for _, ent in ipairs(self.Entities or {}) do
        if IsValid(ent) then
            alive = alive + 1
            kept[#kept + 1] = ent
        end
    end
    self.Entities = kept
    return alive
end

function EncounterDirector:_SpawnOffsets(count)
    local base = {
        Vector(0, 0, 0), Vector(52, 0, 0), Vector(-52, 0, 0),
        Vector(0, 52, 0), Vector(0, -52, 0),
        Vector(42, 42, 0), Vector(-42, 42, 0),
        Vector(42, -42, 0), Vector(-42, -42, 0)
    }
    local out = {}
    for i = 1, count do out[i] = base[((i - 1) % #base) + 1] end
    return out
end

function EncounterDirector:_SpawnEncounter(encounter)
    if encounter.spawned or encounter.cleared then return true end
    local total = 0
    for _, count in pairs(encounter.composition or {}) do total = total + count end
    if self:GetActiveCount() + total > EC.ActiveHostileCeiling then return false end

    local center = LOD.MazeNavigator:CellCenter(encounter.cell) + Vector(0, 0, 10)
    local offsets = self:_SpawnOffsets(total)
    local ordinal = 1
    for _, archetypeId in ipairs({"shambler", "runner", "soldier"}) do
        local count = encounter.composition[archetypeId] or 0
        for _ = 1, count do
            local ent = ents.Create("lod_hostile")
            if IsValid(ent) then
                ent.LODArchetypeId = archetypeId
                ent.LODHomeCellKey = encounter.cellKey
                ent.LODEncounterId = encounter.id
                ent.LODActivated = true
                ent:SetPos(center + offsets[ordinal])
                ent:Spawn()
                ent:Activate()
                ent:DropToFloor()
                encounter.entities[#encounter.entities + 1] = ent
                self.Entities[#self.Entities + 1] = ent
            end
            ordinal = ordinal + 1
        end
    end

    encounter.spawned = true
    encounter.activated = true
    return true
end

function EncounterDirector:_AnyPlayerNear(graph, encounter)
    for _, ply in ipairs(LOD.FactionManager:LivingTargets()) do
        local playerCell = LOD.MazeNavigator:WorldToCell(graph, ply:GetPos())
        if playerCell then
            local distance = LOD.MazeNavigator:Distance(graph, playerCell, encounter.cell)
            if distance <= EC.ActivationDistanceCells then return true end
        end
    end
    return false
end

function EncounterDirector:Think()
    local state = LOD.RunManager and LOD.RunManager.State
    local graph = state and state.Graph
    local plan = graph and graph.EncounterPlan
    if not state or not state.BuildReady or state.Failed or state.LevelCleared or not plan then return end

    for _, encounter in ipairs(plan.encounters) do
        if not encounter.spawned and not encounter.cleared and self:_AnyPlayerNear(graph, encounter) then
            self:_SpawnEncounter(encounter)
        elseif encounter.spawned and not encounter.cleared then
            local living = 0
            for _, ent in ipairs(encounter.entities or {}) do if IsValid(ent) then living = living + 1 end end
            if living == 0 then encounter.cleared = true end
        end
    end
end

function EncounterDirector:OnHostileKilled(hostile, dmginfo)
    local plan = self.Plan
    local id = IsValid(hostile) and hostile.LODEncounterId or nil
    local encounter = plan and id and plan.encounters[id]
    if encounter then
        encounter.kills = (encounter.kills or 0) + 1
    end
end

function EncounterDirector:Cleanup()
    for _, ent in ipairs(self.Entities or {}) do if IsValid(ent) then ent:Remove() end end
    self.Entities = {}
    self.Plan = nil
end

hook.Add("Think", "LOD_EncounterDirectorThink", function()
    EncounterDirector:Think()
end)
