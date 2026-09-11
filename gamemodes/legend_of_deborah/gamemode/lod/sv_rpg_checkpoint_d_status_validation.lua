LOD = LOD or {}
LOD.RPG = LOD.RPG or {}
LOD.RPGCheckpointDStatusValidation = LOD.RPGCheckpointDStatusValidation or {}

local Validation = LOD.RPGCheckpointDStatusValidation
local RPG = LOD.RPG
local Catalog = RPG.IdentityCatalog
local CPS = LOD.CharacterProgressionSystem
local System = LOD.RPGStatusElements
local Feats = Catalog and (Catalog.OrdinaryFeats or Catalog.LevelOneOrdinaryFeats)

local function contains(values, wanted)
    for _, value in ipairs(values or {}) do
        if value == wanted then return true end
    end
    return false
end

local function countKeys(tbl)
    local n = 0
    for _ in pairs(tbl or {}) do n = n + 1 end
    return n
end

local function fakeState(actorType, featIds)
    return {
        actorType = actorType or "ai",
        level = 12,
        featIds = featIds or {},
        featStackCounts = {},
        capabilityTags = {"hit_stun_source", "pushable_weapon", "firearm"},
        effectiveAbilities = {str = 18, dex = 18, con = 18, int = 18, wis = 18, cha = 18},
        featQualificationAbilities = {str = 18, dex = 18, con = 18, int = 18, wis = 18, cha = 18},
        derivedStats = {hpToMagicDiversionFraction = 0.25}
    }
end

function Validation:Run(printResult)
    local errors = {}
    local function expect(condition, message)
        if not condition then errors[#errors + 1] = message end
    end

    expect(Feats ~= nil, "ordinary feat registry unavailable")
    expect(CPS ~= nil and CPS._HasCapability ~= nil, "FeatDirector capability authority unavailable")
    expect(System ~= nil and System.ResolveStatusProcFamilies ~= nil,
        "shared status-proc runtime unavailable")

    local canonicalIds = RPG.CheckpointDStatusProcFeatIds or {}
    expect(#canonicalIds == 27, "Checkpoint D status-proc catalog must contain 27 canonical feat IDs")
    local seen = {}
    for _, featId in ipairs(canonicalIds) do
        expect(not seen[featId], "duplicate Checkpoint D status-proc ID " .. tostring(featId))
        seen[featId] = true
        local definition = Feats and Feats[featId]
        expect(definition ~= nil, "missing status-proc definition " .. tostring(featId))
        if definition then
            expect(definition.effectHandlerId == "status_proc_family"
                or definition.effectHandlerId == "arcane_disruption_proc"
                or definition.effectHandlerId == "morale_proc_family",
                "unreachable handler for " .. tostring(featId))
            local chance = tonumber(definition.effectParams and definition.effectParams.procChance)
            local expected = ({0.11, 0.22, 0.33})[tonumber(definition.rankIndex) or 0]
            expect(chance == expected, "proc chance mismatch for " .. tostring(featId))
        end
    end

    for _, family in ipairs(RPG.CheckpointDStatusProcFamilies or {}) do
        local first, second, third = Feats[family.ids[1]], Feats[family.ids[2]], Feats[family.ids[3]]
        expect(first and first.rankIndex == 1 and not first.replacesLowerRank,
            family.familyId .. " rank 1 metadata")
        expect(second and second.rankIndex == 2 and second.replacesLowerRank
            and contains(second.prerequisiteFeatIds, family.ids[1]),
            family.familyId .. " rank 2 prerequisite/replacement")
        expect(third and third.rankIndex == 3 and third.replacesLowerRank
            and contains(third.prerequisiteFeatIds, family.ids[2]),
            family.familyId .. " rank 3 prerequisite/replacement")
    end

    local hero = fakeState("hero")
    local fakePS = {starterWeaponClass = "weapon_pistol"}
    expect(CPS:_HasCapability(fakePS, hero, "attributable_damaging_attack") == true,
        "Hero attributable-damage capability")
    expect(CPS:_HasCapability(fakePS, hero, "attributable_nonmagical_damaging_attack") == true,
        "Hero nonmagical-damage capability")

    local rankState = fakeState("ai", {
        "CON_POISON_PROC_1", "CON_POISON_PROC_2", "CON_POISON_PROC_3"
    })
    local family = RPG.CheckpointDStatusProcFamilies[1]
    local chosenRank = 0
    for rank = 3, 1, -1 do
        if contains(rankState.featIds, family.ids[rank]) then chosenRank = rank break end
    end
    expect(chosenRank == 3, "runtime highest-owned-rank resolution")

    expect(countKeys(System.Registry or {}) >= 9,
        "shared status registry lost canonical condition families")
    for _, statusId in ipairs({
        "clumsy", "immolated", "poisoned", "bleeding", "muted", "held",
        "reckless", "arcane_shattered", "intimidated"
    }) do
        expect(System.Registry[statusId] ~= nil, "missing shared status " .. statusId)
    end

    local ok = #errors == 0
    if printResult ~= false then
        if ok then
            print("[LOD:RPG-D-STATUS] PASS — 27 status-proc feats / 9 ranked families")
        else
            ErrorNoHalt("[LOD:RPG-D-STATUS] FAILED (" .. #errors .. " error(s))\n")
            for _, message in ipairs(errors) do
                ErrorNoHalt("[LOD:RPG-D-STATUS]  - " .. tostring(message) .. "\n")
            end
        end
    end
    return ok, errors
end

concommand.Add("lod_rpg_validate_status_procs", function(ply)
    if IsValid(ply) and not ply:IsAdmin() then return end
    Validation:Run(true)
end)

hook.Add("InitPostEntity", "LOD_RPG_CheckpointDStatusValidation", function()
    local cvDeveloperMode = GetConVar("lod_developer_mode")
    if cvDeveloperMode and cvDeveloperMode:GetBool() then Validation:Run(true) end
end)
