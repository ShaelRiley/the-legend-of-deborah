-- B20: one bounded, transactional campaign memory owned by RunManager.State.
-- Selection belongs to EncounterDirector; geometry/activation retain their owners.
local D = LOD.EncounterDirector
local EC = LOD.Config.Encounter
local HISTORY_LEVELS = 3
local COUNT_CAP = 1000000
local function sorted(t)
    local out = {}; for id in pairs(t or {}) do out[#out+1] = id end
    table.sort(out); return out
end
local function emptyHistory()
    return {themes={}, templates={}, earlyTemplates={}, enemies={}, families={}, recent={}}
end
local function bump(t, id, n)
    t[id] = math.min(COUNT_CAP, (t[id] or 0) + (n or 1))
end
local function family(id)
    return D.EcologyCatalog.families[id] or id
end
local function pickWeighted(rows, rng)
    local total = 0; for _, row in ipairs(rows) do total = total + row.weight end
    local roll = rng:Float(0, total)
    for _, row in ipairs(rows) do
        roll = roll - row.weight
        if roll < 0 then return row.id end
    end
    return rows[#rows] and rows[#rows].id
end
function D:BeginEcology(plan, graph)
    local state = LOD.RunManager and LOD.RunManager.State
    local receipt = state and state.EncounterEcology
    local level = state and state.Level or 1
    local before = emptyHistory()
    if receipt then
        if level == receipt.level then before = receipt.before
        elseif level > receipt.level then before = receipt.after end
    end
    -- Copies prevent prospective planning from mutating a committed receipt.
    before = table.Copy(before)
    before.earlyTemplates = before.earlyTemplates or {}
    local rows, least = {}, math.huge
    for _, id in ipairs(sorted(self.EcologyCatalog.themes)) do
        local excluded = false
        for i = math.max(1, #before.recent-1), #before.recent do
            if before.recent[i].theme == id then excluded = true end
        end
        if not excluded then
            local seen = before.themes[id] or 0
            if seen < least then rows = {}; least = seen end
            if seen == least then rows[#rows+1] = {id=id, weight=1} end
        end
    end
    local theme = pickWeighted(rows, LOD.RNG.New(LOD.Seeds.Derive(plan.seed, 'ecology:theme')))
    plan.ecology = {theme=theme, name=self.EcologyCatalog.themes[theme].name,
        level=level, before=before, templates={}, earlyTemplates={}, enemies={}, families={},
        roster={}, decisions={}, fallbacks=0}
    -- Only this transient receipt holds identity references. History never does.
    plan.ecologyReceipt = {state=state, previous=receipt, graph=graph,
        level=level, seed=state and state.LevelSeed, campaign=state and state.CampaignSeed,
        epoch=state and state.CampaignEpoch, run=state and state.RunId,
        masterSeed=graph.MasterLevelSeed, layoutSeed=graph.LevelSeed}
end
-- B21: synchronous, lazy geometry facts for a candidate which has passed
-- current-plan spacing. Navigator and EnemyRoster remain traversal/admission
-- authorities; these facts are preferences, never permission to spawn.
function D:EncounterTopology(graph, plan, cell)
    local key = LOD.MazeGenerator.CellKey
    local function cellKey(c) return key(c.x,c.y,c.z) end
    local origin = cellKey(cell)
    local sector = plan.tags[origin] and plan.tags[origin].sector
    local N, E = LOD.MazeNavigator, LOD.EnemyRoster
    local function legal(a, b)
        local tag = plan.tags[b]
        return graph.Cells[b] and tag and tag.sector == sector
            and N:CanTraverse(graph,a,b)
    end
    local exits, vertical = {}, false
    for _, nk in ipairs(sorted(cell.neighbors)) do
        local n = graph.Cells[nk]
        if legal(origin,nk) then
            if n.z == cell.z then exits[#exits+1] = nk else vertical = true end
        end
    end
    -- Height has to be reachable through a real graph edge, not merely a cell
    -- at the same XY on a different floor. Do not place on the landing itself.
    for _, nk in ipairs(exits) do
        for vk in pairs(graph.Cells[nk].neighbors or {}) do
            if legal(nk,vk) and graph.Cells[vk].z ~= cell.z then vertical = true end
        end
    end
    local corner = false
    if #exits == 2 then
        local a,b = graph.Cells[exits[1]],graph.Cells[exits[2]]
        corner = a.x+b.x ~= cell.x*2 or a.y+b.y ~= cell.y*2
    end
    local corridor, firingLane = 0, false
    local center = N:CellCenter(cell)+Vector(0,0,48)
    for _, nk in ipairs(exits) do
        local n = graph.Cells[nk]
        local dx,dy = n.x-cell.x,n.y-cell.y
        local length,current = 1,n
        -- Three edges per direction suffice to identify a usable straight lane;
        -- this is a graph fact, not a promise of uninterrupted native visibility.
        while length < 3 do
            local nextKey = key(current.x+dx,current.y+dy,current.z)
            if not current.neighbors[nextKey] or not legal(cellKey(current),nextKey) then break end
            current=graph.Cells[nextKey];length=length+1
        end
        corridor=math.max(corridor,length)
        local direction=(N:CellCenter(n)-N:CellCenter(cell)):GetNormalized()
        local tr=util.TraceLine({start=center,endpos=center+direction*240,mask=MASK_SOLID,
            filter=player.GetAll()})
        if length>=2 and not tr.StartSolid and not tr.Hit then firingLane=true end
    end
    local objectiveDistance=math.huge
    plan.distanceCache=plan.distanceCache or {}
    for _, enc in ipairs(plan.encounters) do
        if enc.objective then
            local k=cellKey(enc.cell)
            plan.distanceCache[k]=plan.distanceCache[k] or self:_PlanningDistances(graph,enc.cell)
            objectiveDistance=math.min(objectiveDistance,plan.distanceCache[k][origin] or math.huge)
        end
    end
    return {approaches=#exits,corner=corner,junction=#exits>=3,corridor=corridor,
        firingLane=firingLane,alternate=E and E:HasAlternate(graph,cell) or false,
        vertical=vertical,objectiveDistance=objectiveDistance}
end
function D:TopologyPreference(templateId, topology)
    if not topology then return 1, 'neutral' end
    local score,reason=1,'neutral'
    local function prefer(value,label)
        if value>score then score,reason=value,label end
    end
    for _,id in ipairs(sorted(EC.Templates[templateId].composition)) do
        -- Escorts must not determine the tactical niche of a specialist squad.
        if self.EcologyCatalog.common[templateId] or (id~='shambler' and id~='runner' and id~='soldier') then
            local f=family(id)
            if f=='ambush' and topology.corner then prefer(2,'corner') end
            if f=='pursuit' and topology.alternate then prefer(2,'alternate') end
            if id=='climber' and topology.vertical then prefer(2,'vertical') end
            if f=='line_fire' and topology.corridor>=2 and topology.firingLane then prefer(2,'firing_lane') end
            if (f=='area' or f=='trap') and topology.approaches==2 and not topology.alternate then prefer(1.5,'choke_with_retreat') end
            if (f=='support' or f=='companion') and (topology.junction
                or (topology.objectiveDistance>=4 and topology.objectiveDistance<=6)) then prefer(1.5,'support_approach') end
            if (f=='control' or f=='position' or f=='projectile' or f=='reaction' or f=='melee')
                and topology.approaches>=2 then prefer(1.25,'maneuver') end
        end
    end
    return score,reason
end
function D:TemplateFitsCell(templateId, graph, cell, role)
    local E=LOD.EnemyRoster
    if not E then return true end
    for _,id in ipairs(sorted(EC.Templates[templateId].composition)) do
        if E.Definitions[id] and not E:Placement(graph,cell,id,role) then return false end
    end
    return true
end
function D:SelectEcologyTemplate(plan, choices, rng, sector, graph, cell)
    local e = plan.ecology
    local motif = self.EcologyCatalog.themes[e.theme]
    local unique, themed, fallback = {}, {}, {}
    for _, id in ipairs(choices) do
        if not unique[id] and EC.Templates[id] and not EC.Templates[id].objective then
            unique[id] = true
            if motif.templates[id] then themed[#themed+1] = id end
            if self.EcologyCatalog.common[id] then fallback[#fallback+1] = id end
        end
    end
    local topology, rejected
    if graph and cell then
        topology=self:EncounterTopology(graph,plan,cell)
        rejected=0
        local function admitted(ids)
            local out={}
            for _,id in ipairs(ids) do
                if self:TemplateFitsCell(id,graph,cell,plan.tags[LOD.MazeGenerator.CellKey(cell.x,cell.y,cell.z)].role) then
                    out[#out+1]=id
                else rejected=rejected+1 end
            end
            return out
        end
        themed=admitted(themed)
        -- Common fallback cannot supersede a legal motif squad.
        if #themed==0 then fallback=admitted(fallback) end
    end
    local ids = #themed > 0 and themed or fallback
    local usedFallback = #themed == 0
    table.sort(ids)
    local rows, alternative = {}, false
    for _, id in ipairs(ids) do if id ~= e.lastTemplate then alternative = true end end
    for _, id in ipairs(ids) do
        if not alternative or id ~= e.lastTemplate then
            local t = EC.Templates[id]
            local seenTemplates = sector and sector <= 2 and (e.before.earlyTemplates or {}) or e.before.templates
            local weight = (seenTemplates[id] or 0) == 0 and 3 or 1
            weight = weight / (1 + 4 * (e.templates[id] or 0))
            local unseen, recentEnemy, recentFamily = false, false, false
            for enemy in pairs(t.composition) do
                -- Ordinary escort bodies must not make every specialist look
                -- familiar. Common fallback squads still count their whole cast.
                if self.EcologyCatalog.common[id] or (enemy ~= 'shambler' and enemy ~= 'runner' and enemy ~= 'soldier') then
                    if not e.before.enemies[enemy] then unseen = true end
                    for _, old in ipairs(e.before.recent) do
                        if old.enemies[enemy] then recentEnemy = true end
                        if old.families[family(enemy)] then recentFamily = true end
                    end
                end
            end
            if unseen then weight = weight * 2 end
            if recentEnemy then weight = weight * .7 end
            if recentFamily then weight = weight * .8 end
            for i, old in ipairs(e.before.recent) do
                if old.templates[id] then
                    -- B26: more legal fights must not dilute adjacent-dungeon
                    -- variety. Keep repeats possible when geometry limits choices.
                    weight = weight * (i == #e.before.recent and .1 or .6)
                end
            end
            local preference=self:TopologyPreference(id,topology)
            rows[#rows+1] = {id=id, weight=weight*preference}
        end
    end
    local selected = pickWeighted(rows, rng)
    if selected then
        e.decisions[#e.decisions+1] = {template=selected, fallback=usedFallback,
            candidates=#rows, seen=e.before.templates[selected] or 0,
            topology=topology, rejected=rejected or 0,
            preference=self:TopologyPreference(selected,topology)}
        local _,reason=self:TopologyPreference(selected,topology)
        e.decisions[#e.decisions].fit=reason
        if usedFallback then e.fallbacks = e.fallbacks + 1 end
    end
    return selected
end
function D:RecordEcologyEncounter(plan, encounter)
    local e = plan.ecology
    if not e or encounter.objective then return end
    encounter.ecologyDecision = e.decisions[#e.decisions]
    bump(e.templates, encounter.templateId)
    if encounter.sector <= 2 then bump(e.earlyTemplates, encounter.templateId) end
    e.lastTemplate = encounter.templateId
    for id, n in pairs(encounter.composition) do
        bump(e.enemies, id, n); bump(e.families, family(id), n); e.roster[id] = true
    end
end
function D:CommitEcologyPlan(graph)
    local state = LOD.RunManager and LOD.RunManager.State
    local plan = graph and graph.EncounterPlan
    local r = plan and plan.ecologyReceipt
    if not state or not r or not plan.ecology or r.state ~= state or state.Graph ~= graph
        or r.graph ~= graph or self.Plan ~= plan
        or r.masterSeed ~= graph.MasterLevelSeed or r.layoutSeed ~= graph.LevelSeed or r.previous ~= state.EncounterEcology
        or r.level ~= state.Level or r.seed ~= state.LevelSeed
        or r.campaign ~= state.CampaignSeed or r.epoch ~= state.CampaignEpoch or r.run ~= state.RunId
        or (r.previous and r.level < r.previous.level) then return false end
    local e = plan.ecology
    local after = table.Copy(e.before)
    bump(after.themes, e.theme)
    for _, kind in ipairs({'templates','earlyTemplates','enemies','families'}) do
        for id in pairs(e[kind]) do bump(after[kind], id) end
    end
    after.recent[#after.recent+1] = {theme=e.theme, templates=table.Copy(e.templates),
        enemies=table.Copy(e.enemies), families=table.Copy(e.families)}
    while #after.recent > HISTORY_LEVELS do table.remove(after.recent, 1) end
    state.EncounterEcology = {level=r.level, before=table.Copy(e.before), after=after}
    plan.ecologyReceipt = nil
    r.state = nil; r.graph = nil; r.previous = nil
    return true
end
function D:EcologySummary(plan)
    local e = plan and plan.ecology
    if not e then return 'ecology=unavailable' end
    local rows = {}
    for _, id in ipairs(sorted(e.templates)) do rows[#rows+1] = id .. ':' .. e.templates[id] end
    local families = {}
    for _, id in ipairs(sorted(e.families)) do families[#families+1] = id .. ':' .. e.families[id] end
    return string.format('dungeon=%d theme=%s history=%d roster=%s templates=%s families=%s fallbackPicks=%d',
        e.level, e.theme, #e.before.recent, table.concat(sorted(e.roster), ','),
        table.concat(rows, ','), table.concat(families, ','), e.fallbacks)
end
concommand.Add('lod_encounter_ecology', function(ply)
    if IsValid(ply) and not ply:IsAdmin() then return end
    print('[LOD:ECOLOGY] ' .. D:EcologySummary(D.Plan))
    local intensity=D:IntensityProfile(D.Plan)
    print(string.format('[LOD:INTENSITY] targetPerFloor=%d replacementChance=%.2f eliteArrivalCeiling=%.3f phraseWeights=%s tierOdds=60/30/10',
        intensity.wanderTarget,intensity.replacementChance,.30*intensity.replacementChance,table.concat(intensity.phrases,'/')))
    for sector,row in ipairs(D.Plan and D.Plan.pacing and D.Plan.pacing.sectors or {}) do
        local bands,placed={},{}
        for _,beat in ipairs(sorted(row.bands)) do bands[#bands+1]=beat..':'..row.bands[beat] end
        for _,beat in ipairs(sorted(row.placed)) do
            placed[#placed+1]=string.format('%s:%d/%.2f',beat,row.placed[beat],row.threat[beat])
        end
        print(string.format('[LOD:PACING] sector=%d phrase=%s status=%s entry=%s goal=%s routeLength=%s cells=%s squads/threat=%s',
            sector,row.phrase,row.status,tostring(row.entry),tostring(row.goal),tostring(row.length),
            table.concat(bands,','),table.concat(placed,',')))
    end
    for _, encounter in ipairs(D.Plan and D.Plan.encounters or {}) do
        print(string.format('[LOD:ECOLOGY] encounter=%d sector=%d cell=%s template=%s threat=%.2f objective=%s',
            encounter.id, encounter.sector, encounter.cellKey, encounter.templateId,
            encounter.threat, tostring(encounter.objective)))
        local pace=encounter.pacing
        if pace then
            print(string.format('[LOD:PACING] encounter=%d beat=%s progress=%s detour=%s scale=%.3f',
                encounter.id,pace.beat,tostring(pace.progress),tostring(pace.detour),pace.scale))
        end
        local decision = encounter.ecologyDecision
        if decision then
            local t=decision.topology
            if t then
                print(string.format('[LOD:ECOLOGY] approaches=%d corner=%s junction=%s corridor=%d lane=%s alternate=%s vertical=%s objectiveDistance=%s fit=%s weight=%.2f rejected=%d',
                    t.approaches,tostring(t.corner),tostring(t.junction),t.corridor,tostring(t.firingLane),
                    tostring(t.alternate),tostring(t.vertical),tostring(t.objectiveDistance),decision.fit,decision.preference,decision.rejected))
            end
            print(string.format("[LOD:ECOLOGY] novelty=%s priorDungeons=%d candidates=%d fallback=%s",
                encounter.templateId, decision.seen, decision.candidates, tostring(decision.fallback)))
        end
    end
end)

-- Read-only release diagnostic: authored plans are not native sightings. Keep
-- their initial composition separate from spawn-time safety substitutions, and
-- report living actors independently. No developer mode or RNG is involved.
function D:PopulationSnapshot()
    local state=LOD.RunManager and LOD.RunManager.State
    local graph=state and state.Graph
    local plan=graph and graph.EncounterPlan
    if not plan or plan~=self.Plan then return {ready=false} end
    local out={ready=true,revision=plan.populationRevision or "legacy",level=state.Level,
        seed=plan.seed,theme=plan.ecology and plan.ecology.theme,ceiling=LOD.Config.Encounter.ActiveHostileCeiling,
        developerDense=plan.developerDenseTesting==true,planned={},currentComposition={},alive={},
        plannedBodies=0,aliveBodies=0,aliveWanderers=0,sectors={}}
    for sector=1,4 do
        local pace=plan.pacing and plan.pacing.sectors[sector] or {}
        out.sectors[sector]={pacing=pace.status,goal=pace.goal,routeLength=pace.length,
            discretionary=0,objectives=0,spawned=0,budget=plan.sectorBudget[sector],spent=plan.sectorSpent[sector]}
    end
    for _,enc in ipairs(plan.encounters or {}) do
        local row=out.sectors[enc.sector]
        if row then
            local kind=enc.objective and "objectives" or "discretionary"
            row[kind]=row[kind]+1
            if enc.spawned then row.spawned=row.spawned+1 end
        end
        for id,n in pairs(enc.plannedComposition or enc.composition or {}) do
            out.planned[id]=(out.planned[id] or 0)+n;out.plannedBodies=out.plannedBodies+n
        end
        for id,n in pairs(enc.composition or {}) do out.currentComposition[id]=(out.currentComposition[id] or 0)+n end
    end
    local seen={}
    for _,ent in ipairs(self.Entities or {}) do
        if IsValid(ent) and ent.LODHostile and not ent.LODDead and not seen[ent] then
            seen[ent]=true
            local id=ent.LODArchetypeId or "unknown"
            out.alive[id]=(out.alive[id] or 0)+1;out.aliveBodies=out.aliveBodies+1
            if ent.LODWanderer then out.aliveWanderers=out.aliveWanderers+1 end
        end
    end
    return out
end
concommand.Add("lod_population_status",function(ply)
    if IsValid(ply) and not ply:IsAdmin() then return end
    print("[LOD:POPULATION] "..util.TableToJSON(D:PopulationSnapshot()))
end)
