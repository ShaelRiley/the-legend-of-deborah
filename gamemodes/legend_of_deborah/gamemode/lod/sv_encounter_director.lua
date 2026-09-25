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

    for k in pairs(progression.Warden and progression.Warden.cells or {}) do
        tags[k] = {sector = sectorByKey[k], role = "boss", safe = true}
    end
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
        plannedComposition = copyComposition(composition),
        threat = compositionThreat(composition),
        objective = objective == true,
        activated = false,
        cleared = false,
        spawned = false,
        entities = {}
    }
    plan.encounters[id] = encounter
    if self.RecordEcologyEncounter then self:RecordEcologyEncounter(plan, encounter) end
    return encounter
end

-- A plan evaluates hundreds of candidate cells against a handful of anchors.
-- One bounded BFS per anchor replaces repeated full path reconstruction. The
-- cache exists only inside this synchronous plan, so gate changes cannot stale it.
function EncounterDirector:_PlanningDistances(graph, startCell, tags, sector)
    local start=keyOf(startCell)
    if sector and (not tags[start] or tags[start].sector~=sector) then return {} end
    local distances={[start]=0};local queue={start};local head=1
    while queue[head] do
        local current=queue[head];head=head+1
        for _,nextKey in ipairs(sortedKeys(graph.Cells[current].neighbors)) do
            if distances[nextKey]==nil and (not sector or (tags[nextKey] and tags[nextKey].sector==sector))
                and LOD.MazeNavigator:CanTraverse(graph,current,nextKey) then
                distances[nextKey]=distances[current]+1;queue[#queue+1]=nextKey
            end
        end
    end
    return distances
end

-- B22: spatial phrases over real sector routes. These reserve encounter homes,
-- not live combat-free zones: pursuit and the independent wanderer still exist.
local pacingPhrases = {
    {id="surge", quiet=.10, probe=.35, pressure=.80},
    {id="ambush", quiet=.20, probe=.45, pressure=.85},
    {id="gauntlet", quiet=.10, probe=.25, pressure=.85}
}

function EncounterDirector:BeginPacing(plan, graph)
    local progression = graph.Progression
    plan.pacing = {sectors={}}
    for sector=1,4 do
        local entry = sector==1 and graph.Start or (progression.Gates[sector-1] or {}).afterCell
        -- Sector four ends on the approachable side of Black, not at Gordon's
        -- Core behind it. The sector map deliberately excludes that reservation;
        -- targeting Core made the entire production hunt sector "disconnected".
        -- Keep the old Core endpoint for genuine three-gate/legacy graphs.
        local finalGoal = progression.Gates[4] and progression.Gates[4].beforeCell or progression.CoreCell
        local goal = sector==4 and finalGoal or (progression.Keycards[sector] or {}).cell
        local rng = LOD.RNG.New(LOD.Seeds.Derive(plan.seed,"pacing:sector:"..sector))
        local weights = self.IntensityProfile and self:IntensityProfile(plan).phrases or {1,1,1}
        local roll = rng:Float(0,weights[1]+weights[2]+weights[3])
        local index = roll<weights[1] and 1 or roll<weights[1]+weights[2] and 2 or 3
        local phrase = pacingPhrases[index]
        local row = {phrase=phrase.id, bands={quiet=0,probe=0,pressure=0,recovery=0,spike=0},
            placed={}, threat={}, status="unavailable"}
        plan.pacing.sectors[sector] = row
        if entry and goal and graph.Cells[keyOf(entry)] and graph.Cells[keyOf(goal)] then
            local fromEntry = self:_PlanningDistances(graph,entry,plan.tags,sector)
            local fromGoal = self:_PlanningDistances(graph,goal,plan.tags,sector)
            local length = fromEntry[keyOf(goal)]
            row.entry, row.goal, row.length = keyOf(entry),keyOf(goal),length
            row.status = length==0 and "coincident" or length and "ready" or "disconnected"
            for k,tag in pairs(plan.tags) do
                if tag.sector==sector then
                    local a,b = fromEntry[k],fromGoal[k]
                    local beat,progress,detour = "unreachable",nil,nil
                    if row.status=="ready" and a and b then
                        progress = math.Clamp((a-b+length)/2,0,length)/length
                        detour = math.max(0,(a+b-length)/2)
                        -- Respite is a short route segment, not a percentage
                        -- which can empty dozens of cells on a long route.
                        local quiet = math.min(phrase.quiet, 2 / length)
                        local recovery = math.max(phrase.pressure, 1 - 2 / length)
                        beat = progress<quiet and "quiet" or progress<phrase.probe and "probe"
                            or progress<recovery and "pressure" or "recovery"
                        -- A distant branch is not a sanctuary just because its
                        -- junction projects onto the entrance/recovery band.
                        if detour>=4 then beat="spike" end
                    end
                    tag.pacing = {beat=beat, progress=progress, detour=detour}
                    row.bands[beat] = (row.bands[beat] or 0)+1
                end
            end
        end
    end
end

function EncounterDirector:PacingAllows(plan, cell)
    local tag = plan.tags[keyOf(cell)]
    local beat = tag and tag.pacing and tag.pacing.beat
    return not beat or beat=="probe" or beat=="pressure" or beat=="spike"
end

-- Preserve seeded order inside each band, but offer an affordable probe first,
-- then pressure/branch spikes before additional probes. No reservation fallback.
-- B27: distribute homes along the route rather than exhausting a random deep
-- branch first. Stable progress-bin cycling preserves the incoming seeded order
-- inside each bin. Two route-near homes alternate with a deeper branch; neither
-- group bypasses admission, protected cells, spacing or the outer pacing passes.
function EncounterDirector:RouteCandidates(plan, candidates)
    local near, branch = {{},{},{},{}}, {}
    for _,cell in ipairs(candidates) do
        local tag = plan.tags[keyOf(cell)]
        local pace = tag and tag.pacing
        if pace and pace.progress and (pace.detour or 0)<=3 then
            local bin = math.Clamp(math.floor(pace.progress*4)+1,1,4)
            near[bin][#near[bin]+1] = cell
        else branch[#branch+1] = cell end
    end
    local route, cursor = {}, 1
    while true do
        local any=false
        for bin=1,4 do
            if near[bin][cursor] then route[#route+1]=near[bin][cursor];any=true end
        end
        if not any then break end
        cursor=cursor+1
    end
    local out,a,b={},1,1
    while route[a] or branch[b] do
        for _=1,2 do if route[a] then out[#out+1]=route[a];a=a+1 end end
        if branch[b] then out[#out+1]=branch[b];b=b+1 end
    end
    return out
end

function EncounterDirector:PacingCandidates(plan, candidates)
    local probes,pressure,other = {},{},{}
    for _,cell in ipairs(candidates) do
        local pacing = plan.tags[keyOf(cell)].pacing
        local pool = not pacing and other or pacing.beat=="probe" and probes or pressure
        pool[#pool+1]=cell
    end
    return self:RouteCandidates(plan,probes),self:RouteCandidates(plan,pressure),other
end

function EncounterDirector:_FarEnough(graph, plan, cell)
    for _, encounter in ipairs(plan.encounters) do
        if encounter.cell then
            plan.distanceCache=plan.distanceCache or {}
            local anchor=keyOf(encounter.cell)
            plan.distanceCache[anchor]=plan.distanceCache[anchor] or self:_PlanningDistances(graph,encounter.cell)
            local distance=plan.distanceCache[anchor][keyOf(cell)] or math.huge
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
    local plan = {seed = seed, populationRevision = "b27", encounters = {}, sectorBudget = {}, sectorSpent = {}, tags = tags}
    if self.BeginEcology then self:BeginEcology(plan, graph) end

    -- Guaranteed keycard encounters are tuned independently of discretionary
    -- wandering encounters, as required by the GDD.
    local objectiveTemplates = {"red_keycard", "blue_keycard", "yellow_keycard"}
    for index, card in ipairs(graph.Progression.Keycards or {}) do
        local cell = graph.Cells[keyOf(card.cell)]
        local sector = sectorByKey[keyOf(card.cell)] or index
        local composition = self:_TemplateComposition(objectiveTemplates[index], rng:Derive("objective:" .. index), scale)
        self:_AddEncounter(plan, cell, sector, "objective", objectiveTemplates[index], composition, true)
    end

    self:BeginPacing(plan,graph)
    local startDistances=self:_PlanningDistances(graph,graph.Start)
    for sector = 1, 4 do
        local budget = (EC.SectorBaseThreat[sector] or 5) * scale
        plan.sectorBudget[sector] = budget
        plan.sectorSpent[sector] = 0

        local candidates = {}
        for k, cell in pairs(graph.Cells) do
            local tag = tags[k]
            if tag and tag.sector == sector and not tag.safe and not tag.objective and tag.role ~= "boss" and tag.role ~= "resupply" then
                local startDistance = startDistances[keyOf(cell)] or math.huge
                if self:PacingAllows(plan,cell) and startDistance >= EC.ActivationDistanceCells + 1
                    and self:_FarEnough(graph, plan, cell)
                    and not self:_VisibleFromStart(graph, cell)
                then
                    candidates[#candidates + 1] = cell
                end
            end
        end
        table.sort(candidates,function(a,b) return keyOf(a)<keyOf(b) end)
        rng:Shuffle(candidates)
        -- Most authored specialists require a tactical corner/junction. Let
        -- those homes compete before travel/dead-end fallback squads consume
        -- the sector's finite slots and threat. Preserve seeded order inside
        -- each group and the probe/pressure bands below; physical admission is
        -- still checked by SelectEcologyTemplate and again at native spawn.
        local tactical, fallback = {}, {}
        for _, cell in ipairs(candidates) do
            local role = tags[keyOf(cell)].role
            local pool = (role=="arena" or role=="ambush") and tactical or fallback
            pool[#pool+1] = cell
        end
        candidates = tactical
        for _, cell in ipairs(fallback) do candidates[#candidates+1] = cell end

        local placed = 0
        local maximum = EC.MaxDiscretionaryPerSector[sector] or 1
        local probes,pressure,other = self:PacingCandidates(plan,candidates)
        -- First pass stops after one admitted probe; rejected/unaffordable probes
        -- do not consume the slot. The final pass may use remaining legal probes.
        local passes = {{cells=probes,limit=1},{cells=pressure,limit=maximum},
            {cells=other,limit=maximum},{cells=probes,limit=maximum}}
        for _,pass in ipairs(passes) do
            for _, cell in ipairs(pass.cells) do
                if placed >= pass.limit or placed >= maximum then break end
                -- Candidates were collected before this sector's first placement.
                -- Revalidate against the now-current plan before choosing or spending.
                if self:_FarEnough(graph, plan, cell) then
                    local role = tags[keyOf(cell)].role
                    local choices = self:_EligibleTemplates(sector, role)
                    local templateId
                    if self.SelectEcologyTemplate then
                        templateId = self:SelectEcologyTemplate(plan, choices, LOD.RNG.New(LOD.Seeds.Derive(seed,
                            "ecology:sector:" .. sector .. ":cell:" .. keyOf(cell))), sector, graph, cell)
                    else
                        templateId = rng:Pick(choices)
                    end
                    local pacing = tags[keyOf(cell)].pacing
                    local compositionScale = pacing and pacing.beat=="probe" and 1 or scale
                    local composition = self:_TemplateComposition(templateId, rng:Derive("sector:" .. sector .. ":cell:" .. keyOf(cell)), compositionScale)
                    local cost = compositionThreat(composition)
                    local remaining = budget - plan.sectorSpent[sector]
                    if composition and (cost <= remaining + 0.5 or placed == 0) then
                        local encounter = self:_AddEncounter(plan, cell, sector, role, templateId, composition, false)
                        encounter.pacing = pacing and table.Copy(pacing) or {beat="unavailable"}
                        encounter.pacing.scale = compositionScale
                        local row = plan.pacing.sectors[sector]
                        local beat = encounter.pacing.beat
                        row.placed[beat] = (row.placed[beat] or 0)+1
                        row.threat[beat] = (row.threat[beat] or 0)+cost
                        plan.sectorSpent[sector] = plan.sectorSpent[sector] + cost
                        placed = placed + 1
                    end
                end
            end
        end
    end

    plan.distanceCache=nil
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
