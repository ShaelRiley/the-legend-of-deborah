local path = arg[1] or "gamemodes/legend_of_deborah/gamemode/lod/sv_rpg_checkpoint_d_sixth_sense_feat.lua"
local file = assert(io.open(path, "rb"))
local source = file:read("*a")
file:close()

local function expect(ok, message)
    if not ok then error(message, 0) end
end

expect(source:find('featId = "WIS_SIXTH_SENSE"', 1, true), "missing Sixth Sense feat")
expect(source:find('abilityRequirements = {wis = 13}', 1, true), "Sixth Sense must be WIS 13")
expect(source:find('allowedActorTypes = {"hero"}', 1, true), "Sixth Sense must be Hero-only")
expect(not source:find("ents.GetAll", 1, true), "Sixth Sense may not world-scan hostiles")
expect(source:find("LOD.EncounterDirector and LOD.EncounterDirector.Entities", 1, true), "missing encounter hostile cache")
expect(source:find("LOD.WanderingDirector and LOD.WanderingDirector.Entities", 1, true), "missing wandering hostile cache")
expect(source:find("LODMotionSpeed", 1, true), "Watcher audio must use authoritative motion state")
expect(source:find("RPGPerceptionState", 1, true), "missing shared invisibility primitive")

local function distance(a, b)
    if not a or not b or a.z ~= b.z then return math.huge end
    return math.max(math.abs(a.x - b.x), math.abs(a.y - b.y))
end
local c = {x = 0, y = 0, z = 2}
expect(distance(c, {x = 2, y = -2, z = 2}) == 2, "Chebyshev corner must be inside")
expect(distance(c, {x = 3, y = 0, z = 2}) == 3, "3 cells must be outside")
expect(distance(c, {x = 0, y = 0, z = 3}) == math.huge, "floor mismatch must be excluded")

print("SIXTH_SENSE_HARNESS_PASS")
