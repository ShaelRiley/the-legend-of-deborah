LOD = LOD or {}
LOD.M3DenseTesting = LOD.M3DenseTesting or {}

local Dense = LOD.M3DenseTesting
local EncounterDirector = LOD.EncounterDirector
local EC = LOD.Config.Encounter

if not EncounterDirector or EncounterDirector.LODDenseTestingWrapped then return end
EncounterDirector.LODDenseTestingWrapped = true

local DEV_SECTOR_BUDGET_MULTIPLIER = 2.0
local DEV_MAX_DISCRETIONARY = {3, 4, 4, 4}
local DEV_MAJOR_SPACING_CELLS = 2

local function developerModeEnabled()
    local cv = GetConVar("lod_developer_mode")
    return cv and cv:GetBool() or false
end

local function copyArray(source)
    local out = {}
    for i, value in ipairs(source or {}) do out[i] = value end
    return out
end

local baseBuildPlan = EncounterDirector.BuildPlan
function EncounterDirector:BuildPlan(graph)
    if not developerModeEnabled() then
        return baseBuildPlan(self, graph)
    end

    -- Developer-only density boost. Temporarily adjust planner tuning while the
    -- plan is built, then restore production values immediately. The resulting
    -- plan is denser, but normal release balance is never mutated persistently.
    local originalBudgets = copyArray(EC.SectorBaseThreat)
    local originalMaximums = copyArray(EC.MaxDiscretionaryPerSector)
    local originalSpacing = EC.MajorSpacingCells

    local devBudgets = {}
    for i, value in ipairs(originalBudgets) do
        devBudgets[i] = value * DEV_SECTOR_BUDGET_MULTIPLIER
    end

    EC.SectorBaseThreat = devBudgets
    EC.MaxDiscretionaryPerSector = copyArray(DEV_MAX_DISCRETIONARY)
    EC.MajorSpacingCells = DEV_MAJOR_SPACING_CELLS

    -- Garry's Mod is Lua 5.1-family; pack the planner's multiple return values
    -- into one table so xpcall cannot discard the plan value.
    local ok, packedOrError = xpcall(function()
        return {baseBuildPlan(self, graph)}
    end, debug.traceback)

    EC.SectorBaseThreat = originalBudgets
    EC.MaxDiscretionaryPerSector = originalMaximums
    EC.MajorSpacingCells = originalSpacing

    if not ok then
        ErrorNoHalt("[LOD:M3-DENSE] encounter planner error: " .. tostring(packedOrError) .. "\n")
        return false, packedOrError
    end

    local resultA = packedOrError[1]
    local resultB = packedOrError[2]
    local plan = resultB
    if resultA and istable(plan) then
        plan.developerDenseTesting = true
        print(string.format(
            "[LOD:M3-DENSE] dense developer encounter plan enabled: encounters=%d spacing=%d budgets=%.1fx",
            #(plan.encounters or {}), DEV_MAJOR_SPACING_CELLS, DEV_SECTOR_BUDGET_MULTIPLIER
        ))
    end

    return resultA, resultB
end

concommand.Add("lod_m3_dense_status", function(ply)
    local cv = GetConVar("lod_developer_mode")
    if cv and not cv:GetBool() then return end
    if IsValid(ply) and not ply:IsAdmin() then return end

    local state = LOD.RunManager and LOD.RunManager.State
    local plan = state and state.Graph and state.Graph.EncounterPlan
    local total = plan and #(plan.encounters or {}) or 0
    local text = string.format(
        "developerMode=%s densePlan=%s encounters=%d targetDiscretionary=3/4/4/4 spacing=2 budgetMultiplier=2.0",
        tostring(developerModeEnabled()), tostring(plan and plan.developerDenseTesting == true), total
    )
    print("[LOD:M3-DENSE] " .. text)
    if IsValid(ply) then ply:ChatPrint(text) end
end)