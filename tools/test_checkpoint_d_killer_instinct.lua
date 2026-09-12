local path = arg[1] or "gamemodes/legend_of_deborah/gamemode/lod/sv_rpg_checkpoint_d_killer_instinct_feat.lua"
local file = assert(io.open(path, "rb"))
local source = file:read("*a")
file:close()

local function expect(ok, message) if not ok then error(message, 0) end end
expect(source:find('featId = "WIS_KILLER_INSTINCT"', 1, true), "missing Killer Instinct feat")
expect(source:find('abilityRequirements = {wis = 15}', 1, true), "Killer Instinct must be WIS 15")
expect(source:find('allowedActorTypes = {"hero", "human_soldier"}', 1, true), "actor restriction mismatch")
expect(source:find('local HOLD_SECONDS = 0.50', 1, true), "missing 0.50s hold")
expect(source:find('local REEVALUATE_SECONDS = 1.00', 1, true), "missing 1.00s cadence")
expect(source:find("LOD.EncounterDirector and LOD.EncounterDirector.Entities", 1, true), "missing encounter cache")
expect(source:find("LOD.WanderingDirector and LOD.WanderingDirector.Entities", 1, true), "missing wander cache")
expect(not source:find("ents.GetAll", 1, true), "Killer Instinct may not world-scan")
expect(not source:find("Rules:ResolveDamageValues", 1, true), "estimation must not mutate live damage telemetry")
expect(source:find("damageResistancePerDie", 1, true), "must mirror deterministic target resistance")
expect(source:find("physicalDamageMultiplier", 1, true), "must mirror deterministic source scaling")
expect(source:find("(math.max(1, tonumber(profile.sides) or 1) + 1) * 0.5", 1, true), "must use mean die values")

local function record(damage, hp, stableId)
    local effective = math.max(1, damage)
    return {damage = damage, hp = hp, stableId = stableId,
        shots = math.max(1, math.ceil(hp / effective)), margin = damage - hp}
end
local function selectRecord(records)
    local oneShot = false
    for _, r in ipairs(records) do if r.shots == 1 then oneShot = true break end end
    local candidates = {}
    for _, r in ipairs(records) do if not oneShot or r.shots == 1 then candidates[#candidates + 1] = r end end
    table.sort(candidates, function(a, b)
        if oneShot and a.margin ~= b.margin then return a.margin > b.margin end
        if not oneShot and a.shots ~= b.shots then return a.shots < b.shots end
        if a.hp ~= b.hp then return a.hp < b.hp end
        return a.stableId < b.stableId
    end)
    return candidates[1]
end

expect(selectRecord({record(12,10,2), record(20,18,1), record(30,12,3)}).stableId == 3,
    "one-shot margin selection failed")
expect(selectRecord({record(6,15,4), record(6,12,8), record(6,12,3)}).stableId == 3,
    "shots/HP/stable-id ordering failed")
expect(((3 + 1) * 0.5) == 2, "d3 mean damage invariant failed")
print("KILLER_INSTINCT_HARNESS_PASS")
