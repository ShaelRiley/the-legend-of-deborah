-- Authored event catalog. Selection never consumes maze, encounter or loot RNG.
LOD = LOD or {}
LOD.EventRegistry = LOD.EventRegistry or {Definitions = {}}
local R = LOD.EventRegistry
R.Contracts = {REWARD = true, BLOCKADE = true, HAZARD = true, UTILITY = true}
-- Authored release gate, independent of catalog size and the server convar.
-- Enable only in the complete-catalog activation/production rarity checkpoint.
R.PopulationReady = false

function R:Register(def)
    assert(type(def) == "table" and type(def.id) == "string"
        and def.id:match("^[a-z][a-z0-9_]*$") and #def.id <= 48, "invalid event archetype")
    assert(self.Contracts[def.contract], "invalid event placement contract")
    assert(def.maxInstances == nil or (type(def.maxInstances) == "number"
        and (def.maxInstances == 1 or def.maxInstances == 2)), "invalid event instance bound")
    assert(def.maxInstances ~= 2 or (def.contract == "REWARD" and def.nonblocking == true),
        "multiple event instances require nonblocking REWARD")
    assert(not self.Definitions[def.id], "duplicate event archetype")
    assert(type(def.Create) == "function" and type(def.Interact) == "function", "event lifecycle required")
    self.Definitions[def.id] = def
    return def
end

function R:Catalog()
    local ids = {}
    for id, def in pairs(self.Definitions) do
        if def.production == true then ids[#ids + 1] = id end
    end
    table.sort(ids)
    return ids
end

function R:Select(seed)
    local ids = self:Catalog()
    -- Do not truncate d4, repeat an archetype, or pass an incomplete catalog off
    -- as production population. Preview is a separate explicitly unranked path.
    if #ids < 4 then return nil, "production event population gated: at least four archetypes required" end
    local count = LOD.RNG.New(LOD.Seeds.Derive(seed, "dungeon-events:count:v1")):Int(1, 4)
    LOD.RNG.New(LOD.Seeds.Derive(seed, "dungeon-events:catalog:v1")):Shuffle(ids)
    local selected = {}
    for i = 1, count do selected[i] = ids[i] end
    return selected, count
end
