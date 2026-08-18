LOD = LOD or {}

local MazeBuilder = LOD.MazeBuilder
local EncounterDirector = LOD.EncounterDirector

local previousBuild = MazeBuilder.Build
function MazeBuilder:Build(graph)
    -- Hostiles belong to the generated level just as surely as walls and gates.
    -- Remove the previous level's encounter state before new geometry is built.
    EncounterDirector:Cleanup()

    local ok, report = previousBuild(self, graph)
    if not ok then return ok, report end

    -- Geometry now exists, so encounter placement can perform physical LOS
    -- checks. Planning still happens before Build() returns, hence before
    -- RunManager marks the level ready or releases any player.
    local planned, planOrErr = EncounterDirector:BuildPlan(graph)
    if not planned then
        self:Cleanup()
        EncounterDirector:Cleanup()
        return false, "encounter planning failed: " .. tostring(planOrErr)
    end

    report.encounterCount = #(planOrErr.encounters or {})
    report.encounterSeed = planOrErr.seed
    return true, report
end

hook.Add("ShutDown", "LOD_EncounterCleanup", function()
    EncounterDirector:Cleanup()
end)
