LOD = LOD or {}

local MazeBuilder = LOD.MazeBuilder
local EncounterDirector = LOD.EncounterDirector

-- Encounter placement is evaluated after the maze exists. LOS therefore needs
-- to see generated container props and static collision, not only Flatgrass's
-- world brushes. Ignore held/spectating players during the build check.
function EncounterDirector:_VisibleFromStart(graph, cell)
    local startPos = LOD.MazeNavigator:CellCenter(graph.Start) + Vector(0, 0, 64)
    local endPos = LOD.MazeNavigator:CellCenter(cell) + Vector(0, 0, 40)
    local tr = util.TraceLine({
        start = startPos,
        endpos = endPos,
        mask = MASK_SOLID,
        filter = player.GetAll()
    })
    local stats=self.VisibilityProbeStats or {checked=0,lineBlocked=0,bboxBlocked=0,visible=0}
    self.VisibilityProbeStats=stats;stats.checked=stats.checked+1
    if tr.Hit and tr.Fraction < 0.995 then stats.lineBlocked=stats.lineBlocked+1;return false end
    -- The static-box compiler deliberately creates no VPhysics meshes. Preserve
    -- every ordinary ray occluder, then test the actual generated collision
    -- bounds with a narrow hull. Only an authoritative generated solid may
    -- correct a clear ray; a grazing world/prop hit cannot manufacture cover.
    local box=util.TraceHull({start=startPos,endpos=endPos,mins=Vector(-1,-1,-1),maxs=Vector(1,1,1),
        mask=MASK_SOLID,filter=player.GetAll()})
    local ent=box.Entity
    local class=IsValid(ent) and ent.GetClass and ent:GetClass()
    local generated=class=="lod_static_box" or class=="lod_gate" or class=="lod_jail_door"
    if generated and box.Hit and not box.StartSolid and (box.Fraction or 1)<0.995 then
        stats.bboxBlocked=stats.bboxBlocked+1
        if not stats.example then stats.example={cell=LOD.MazeGenerator.CellKey(cell.x,cell.y,cell.z),class=class} end
        return false
    end
    stats.visible=stats.visible+1
    return true
end
EncounterDirector.NativeVisibilityRevision="b28-generated-bounds"
EncounterDirector.NativeVisibilityFunction=EncounterDirector._VisibleFromStart

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
