-- Authored event catalog. Selection never consumes maze, encounter or loot RNG.
LOD = LOD or {}
LOD.EventRegistry = LOD.EventRegistry or {Definitions = {}}
local R = LOD.EventRegistry
R.Contracts = {REWARD = true, BLOCKADE = true, HAZARD = true, UTILITY = true}
-- Authored release gate, independent of catalog size and the server convar.
R.PopulationReady = true
R.EcologyVersion, R.HistoryLimit = 1, 4
local COUNT_CAP = 1000000
local legacy = {
    slot_machine = {name="Debbie Slots", family="games", role="wager", topology="respite", risk="high", persistence="account_dungeon"},
    locked_chest = {name="Locked Loot Chest", family="caches", role="source", topology="dead_end", persistence="account_dungeon"},
    treasure_chest = {name="DFT Treasure", family="caches", role="source", topology="dead_end", persistence="account_dungeon"},
    vending_machine = {name="Debbie Vending", family="services", role="recovery", topology="respite", persistence="account_dungeon"},
    false_floor = {name="False Floor", family="traps", role="risk", topology="optional", scope="party", interactionMode="automatic", risk="high"},
    warp_hole = {name="Warp Hole", family="anomalies", role="traversal", topology="optional", scope="party"},
    skeleton_blockade = {name="Skeleton Blockade", family="blockades", role="challenge", topology="required", scope="party", risk="high"},
    equipment_quiz = {name="Equipment Quiz", family="games", role="information", topology="dead_end", risk="high", persistence="account_dungeon"},
}
local function sorted(t)
    local out = {}; for id in pairs(t or {}) do out[#out+1] = id end
    table.sort(out); return out
end
local function slug(v) return type(v)=="string" and #v<=48 and v:match("^[a-z][a-z0-9_]*$") end
local function contains(t, id)
    for _, v in ipairs(t or {}) do if v==id then return true end end
    return false
end
local function bump(t,id) t[id]=math.min(COUNT_CAP,(t[id] or 0)+1) end
local function choose(rows,rng)
    local total=0;for _,row in ipairs(rows) do total=total+row.weight end
    local roll=rng:Float(0,total)
    for _,row in ipairs(rows) do roll=roll-row.weight;if roll<0 then return row end end
    return rows[#rows]
end

-- Derive is an affine label hash. Equal-length slot labels followed by a
-- single Park-Miller draw have correlated quantiles, which can make some pairs
-- impossible. Different bounded warmups retain isolated named streams while
-- decorrelating the family/identity and slot draw positions.
local function selectionRNG(seed,domain,slot,identity)
    local purpose=identity and "identity" or "family"
    local rng=LOD.RNG.New(LOD.Seeds.Derive(seed,domain..":"..purpose..":"..slot..":ecology-v1"))
    for _=1,slot*2+(identity and 1 or 0) do rng:NextRaw() end
    return rng
end

function R:Register(def)
    assert(type(def) == "table" and slug(def.id), "invalid event archetype")
    assert(self.Contracts[def.contract], "invalid event placement contract")
    assert(def.maxInstances == nil or (type(def.maxInstances) == "number"
        and (def.maxInstances == 1 or def.maxInstances == 2)), "invalid event instance bound")
    assert(def.maxInstances ~= 2 or (def.contract == "REWARD" and def.nonblocking == true),
        "multiple event instances require nonblocking REWARD")
    assert(def.rare == nil or type(def.rare) == "boolean", "invalid event rarity flag")
    assert(not self.Definitions[def.id], "duplicate event archetype")
    assert(type(def.Create) == "function" and type(def.Interact) == "function", "event lifecycle required")
    local defaults=legacy[def.id] or {}
    def.name=def.name or defaults.name or def.id:gsub("_"," ")
    def.family=def.family or defaults.family or string.lower(def.contract)
    def.scope=def.scope or defaults.scope or (def.sharedResolution and "party" or "personal")
    def.persistence=def.persistence or defaults.persistence or "dungeon"
    def.interactionMode=def.interactionMode or defaults.interactionMode or "use"
    def.risk=def.risk or defaults.risk or "low"
    def.role=def.role or defaults.role or (def.contract=="REWARD" and "source" or "utility")
    def.topology=def.topology or defaults.topology or "neutral"
    def.weight=def.weight or 1
    assert(type(def.name)=="string" and #def.name>0 and #def.name<=96,"invalid event name")
    for _,field in ipairs({"family","scope","persistence","interactionMode","risk","role","topology"}) do
        assert(slug(def[field]),"invalid event metadata: "..field)
    end
    assert(type(def.weight)=="number" and def.weight>0 and def.weight<=100 and def.weight==def.weight,"invalid event weight")
    for _,field in ipairs({"themeAffinities"}) do
        assert(def[field]==nil or type(def[field])=="table","invalid event affinities")
        for id,weight in pairs(def[field] or {}) do
            assert(slug(id) and type(weight)=="number" and weight>0 and weight<=4 and weight==weight,"invalid event affinity")
        end
    end
    for _,field in ipairs({"incompatibilities","synergies"}) do
        assert(def[field]==nil or type(def[field])=="table","invalid event relationships")
        for _,id in ipairs(def[field] or {}) do assert(slug(id),"invalid event relationship") end
    end
    self.Definitions[def.id] = def
    return def
end

function R:Catalog(dungeonLevel)
    local ids = {}
    for id, def in pairs(self.Definitions) do
        if def.production == true and (not dungeonLevel or not def.minDungeonLevel
            or dungeonLevel >= def.minDungeonLevel) then ids[#ids + 1] = id end
    end
    table.sort(ids)
    return ids
end

function R:NewHistory()
    return {appearances={},families={},contracts={},lastSeen={},recent={},totalLevels=0}
end
function R:HistoryAfter(before,selected,level,theme)
    local after=table.Copy(before or self:NewHistory())
    local recent={events={},families={},contracts={},level=level,theme=theme}
    for _,id in ipairs(selected) do
        local def=assert(self.Definitions[id])
        bump(after.appearances,id);after.lastSeen[id]=level
        recent.events[id],recent.families[def.family],recent.contracts[def.contract]=true,true,true
    end
    for id in pairs(recent.families) do bump(after.families,id) end
    for id in pairs(recent.contracts) do bump(after.contracts,id) end
    after.totalLevels=math.min(COUNT_CAP,after.totalLevels+1)
    after.recent[#after.recent+1]=recent
    while #after.recent>self.HistoryLimit do table.remove(after.recent,1) end
    return after
end

local complements={source={sink=true,wager=true},sink={source=true},wager={recovery=true,source=true},
    risk={recovery=true,information=true},challenge={recovery=true,information=true},
    recovery={risk=true,challenge=true,wager=true},information={risk=true,challenge=true,traversal=true},traversal={information=true}}
function R:Compatible(def,selected)
    for _,id in ipairs(selected) do
        local prior=self.Definitions[id]
        if contains(def.incompatibilities,id) or contains(def.incompatibilities,prior.family)
            or contains(prior.incompatibilities,def.id) or contains(prior.incompatibilities,def.family) then return false end
    end
    return true
end

-- Family weights are averages, not sums: adding several siblings does not make
-- their family dominate. Identity novelty then chooses the learnable situation.
function R:Select(seed, dungeonLevel, context)
    dungeonLevel=dungeonLevel or 1
    if not context and LOD.EventDirector and LOD.EventDirector.SelectionContext then
        local state=LOD.RunManager and LOD.RunManager.State
        context=LOD.EventDirector:SelectionContext(state and state.Graph,dungeonLevel)
    end
    context=context or {}
    local before=context.history or self:NewHistory()
    local useHistory=context.historyEnabled~=false
    local ids = self:Catalog(dungeonLevel)
    if #ids < 4 then return nil, "production event population gated: at least four archetypes required" end
    local common, rare = {}, {}
    for _, id in ipairs(ids) do
        local pool = self.Definitions[id].rare and rare or common
        pool[#pool + 1] = id
    end
    if #rare > 0 and #common < 3 then
        return nil, "production event population gated: rare catalog requires at least three common archetypes"
    end
    local count = LOD.RNG.New(LOD.Seeds.Derive(seed, "dungeon-events:count:v1")):Int(1, 4)
    local selected,chosen,families,contracts,roles={},{},{},{},{}
    local diagnostic={version=self.EcologyVersion,theme=context.theme,historyEnabled=useHistory,
        historyLevels=useHistory and #(before.recent or {}) or 0,eligible=#ids,eligibleIds=table.Copy(ids),excluded={},count=count,decisions={}}
    for _,id in ipairs(sorted(self.Definitions)) do
        local def=self.Definitions[id]
        if def.production~=true then diagnostic.excluded[#diagnostic.excluded+1]={id=id,reason="not_production"}
        elseif def.minDungeonLevel and dungeonLevel<def.minDungeonLevel then
            diagnostic.excluded[#diagnostic.excluded+1]={id=id,reason="minimum_dungeon_level",minimum=def.minDungeonLevel}
        end
    end
    for slot=1,count do
        local rareSlot=#rare>0 and slot==4
        local pool=rareSlot and rare or (#rare>0 and common or ids)
        local grouped,excluded={},{}
        for _,id in ipairs(pool) do
            local def=self.Definitions[id]
            if not chosen[id] and self:Compatible(def,selected) then
                local factors={base=def.weight,theme=def.themeAffinities and def.themeAffinities[context.theme] or 1,
                    novelty=1,frequency=1,neglect=1,recent=1,previousContract=1,
                    contractDiversity=contracts[def.contract] and .65 or 1,relationship=1}
                local seen=useHistory and (before.appearances[id] or 0) or 0
                if useHistory then
                    factors.novelty=seen==0 and 2 or 1
                    factors.frequency=1/(1+seen*.15)
                    local since=dungeonLevel-(before.lastSeen[id] or dungeonLevel)
                    factors.neglect=1+math.min(8,math.max(0,since-3))*.075
                    for i,old in ipairs(before.recent) do
                        if old.events[id] then factors.recent=factors.recent*(i==#before.recent and .04 or .65) end
                    end
                    local previous=before.recent[#before.recent]
                    if previous and previous.contracts[def.contract] then factors.previousContract=.9 end
                end
                local relation=false
                for role in pairs(roles) do
                    if (complements[role] and complements[role][def.role]) or contains(def.synergies,role) then relation=true end
                end
                if relation then factors.relationship=1.3 end
                local weight=1
                for _,field in ipairs({"base","theme","novelty","frequency","neglect","recent","previousContract","contractDiversity","relationship"}) do
                    weight=weight*factors[field]
                end
                grouped[def.family]=grouped[def.family] or {}
                grouped[def.family][#grouped[def.family]+1]={id=id,weight=weight,seen=seen,relation=relation,factors=factors}
            else
                excluded[#excluded+1]={id=id,reason=chosen[id] and "already_selected" or "incompatible_identity_or_family"}
            end
        end
        local familyRows={}
        for _,family in ipairs(sorted(grouped)) do
            local rows=grouped[family];local weight=0
            for _,row in ipairs(rows) do weight=weight+row.weight end
            weight=weight/#rows
            local factors={diversity=families[family] and .18 or 1,frequency=1,recent=1}
            if useHistory then
                factors.frequency=1/(1+(before.families[family] or 0)*.08)
                local previous=before.recent[#before.recent]
                if previous and previous.families[family] then factors.recent=.6 end
            end
            familyRows[#familyRows+1]={id=family,weight=weight*factors.diversity*factors.frequency*factors.recent,factors=factors}
        end
        if #familyRows==0 then return nil,"event ecology exhausted compatible identities at slot "..slot,diagnostic end
        -- Preserve count and legacy domain names; add purpose-specific suffixes
        -- so no family draw consumes an identity, variant or placement draw.
        local domain=rareSlot and "dungeon-events:rare-catalog:v1" or "dungeon-events:catalog:v1"
        local selectedFamily=choose(familyRows,selectionRNG(seed,domain,slot,false))
        local family=selectedFamily.id
        local row=choose(grouped[family],selectionRNG(seed,domain,slot,true))
        local def=self.Definitions[row.id]
        selected[#selected+1]=row.id;chosen[row.id],families[family],contracts[def.contract],roles[def.role]=true,true,true,true
        diagnostic.decisions[#diagnostic.decisions+1]={slot=slot,id=row.id,family=family,contract=def.contract,
            role=def.role,scope=def.scope,rare=rareSlot,rarityPolicy=rareSlot and "fourth_slot" or "common_slots",
            seen=row.seen,relation=row.relation,familyCandidates=#familyRows,identityCandidates=#grouped[family],
            weight=row.weight,factors=row.factors,familyWeight=selectedFamily.weight,familyFactors=selectedFamily.factors,excluded=excluded}
    end
    return selected, count, diagnostic
end
