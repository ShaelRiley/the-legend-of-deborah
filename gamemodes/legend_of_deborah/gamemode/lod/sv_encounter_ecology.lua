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
function D:SelectEcologyTemplate(plan, choices, rng, sector)
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
                    weight = weight * (i == #e.before.recent and .2 or .6)
                end
            end
            rows[#rows+1] = {id=id, weight=weight}
        end
    end
    local selected = pickWeighted(rows, rng)
    if selected then
        e.decisions[#e.decisions+1] = {template=selected, fallback=usedFallback,
            candidates=#rows, seen=e.before.templates[selected] or 0}
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
    for _, encounter in ipairs(D.Plan and D.Plan.encounters or {}) do
        print(string.format('[LOD:ECOLOGY] encounter=%d sector=%d cell=%s template=%s threat=%.2f objective=%s',
            encounter.id, encounter.sector, encounter.cellKey, encounter.templateId,
            encounter.threat, tostring(encounter.objective)))
        local decision = encounter.ecologyDecision
        if decision then
            print(string.format("[LOD:ECOLOGY] novelty=%s priorDungeons=%d candidates=%d fallback=%s",
                encounter.templateId, decision.seen, decision.candidates, tostring(decision.fallback)))
        end
    end
end)
