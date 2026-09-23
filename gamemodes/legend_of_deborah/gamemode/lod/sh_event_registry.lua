-- Authored event catalog. Selection never consumes maze, encounter or loot RNG.
LOD = LOD or {}
LOD.EventRegistry = LOD.EventRegistry or {Definitions = {}}
local R = LOD.EventRegistry
R.Contracts = {REWARD = true, BLOCKADE = true, HAZARD = true, UTILITY = true}
-- Authored release gate, independent of catalog size and the server convar.
-- Approved production population; catalog completeness still fails closed.
R.PopulationReady = true

function R:Register(def)
    assert(type(def) == "table" and type(def.id) == "string"
        and def.id:match("^[a-z][a-z0-9_]*$") and #def.id <= 48, "invalid event archetype")
    assert(self.Contracts[def.contract], "invalid event placement contract")
    assert(def.maxInstances == nil or (type(def.maxInstances) == "number"
        and (def.maxInstances == 1 or def.maxInstances == 2)), "invalid event instance bound")
    assert(def.maxInstances ~= 2 or (def.contract == "REWARD" and def.nonblocking == true),
        "multiple event instances require nonblocking REWARD")
    assert(def.rare == nil or type(def.rare) == "boolean", "invalid event rarity flag")
    assert(not self.Definitions[def.id], "duplicate event archetype")
    assert(type(def.Create) == "function" and type(def.Interact) == "function", "event lifecycle required")
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

function R:Select(seed, dungeonLevel)
    local ids = self:Catalog(dungeonLevel or 1)
    -- Do not truncate d4, repeat an archetype, or pass an incomplete catalog off
    -- as production population. Preview is a separate explicitly unranked path.
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
    -- Exact d4 remains authoritative. A rare archetype occupies only the fourth
    -- slot: the sole rare treasure entry therefore appears on 25% of rolls.
    -- Future rare entries share that slot instead of multiplying it.
    local pool = #rare > 0 and common or ids
    LOD.RNG.New(LOD.Seeds.Derive(seed, "dungeon-events:catalog:v1")):Shuffle(pool)
    local selected = {}
    for i = 1, math.min(count, #rare > 0 and 3 or count) do selected[i] = pool[i] end
    if #rare > 0 and count == 4 then
        LOD.RNG.New(LOD.Seeds.Derive(seed, "dungeon-events:rare-catalog:v1")):Shuffle(rare)
        selected[4] = rare[1]
    end
    return selected, count
end
