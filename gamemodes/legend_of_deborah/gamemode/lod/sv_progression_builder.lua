LOD = LOD or {}
LOD.MazeBuilder = LOD.MazeBuilder or {}

local MazeBuilder = LOD.MazeBuilder
local PC = LOD.Config.Progression

function MazeBuilder:_SpawnProgressionGate(meta)
    local a = self:CellCenter(meta.beforeCell)
    local b = self:CellCenter(meta.afterCell)
    local delta = b - a
    local height = PC.GateBlockerHeight
    local ent = ents.Create("lod_gate")
    if not IsValid(ent) then return nil end
    ent:SetGateIndex(meta.index)
    ent:SetGateAxis(math.abs(delta.x) > math.abs(delta.y) and 0 or 1)
    ent:SetPos((a + b) * 0.5 + Vector(0, 0, height * 0.5))
    ent:Spawn()
    ent:Activate()
    meta.entity = ent
    return ent
end

function MazeBuilder:_SpawnKeycard(meta)
    local ent = ents.Create("lod_keycard")
    if not IsValid(ent) then return nil end
    ent:SetCardIndex(meta.index)
    ent:SetPos(self:CellCenter(meta.cell) + Vector(0, 0, PC.KeycardHeight))
    ent:Spawn()
    ent:Activate()
    meta.entity = ent
    return ent
end

function MazeBuilder:_SpawnJailDoor(meta)
    local a = self:CellCenter(meta.beforeCell)
    local b = self:CellCenter(meta.afterCell)
    local delta = b - a
    local height = PC.GateBlockerHeight
    local ent = ents.Create("lod_jail_door")
    if not IsValid(ent) then return nil end
    ent:SetDoorAxis(math.abs(delta.x) > math.abs(delta.y) and 0 or 1)
    ent:SetPos((a + b) * 0.5 + Vector(0, 0, height * 0.5))
    ent:Spawn()
    ent:Activate()
    meta.entity = ent
    return ent
end

function MazeBuilder:_SpawnDeborah(meta)
    local ent = ents.Create("lod_deborah")
    if not IsValid(ent) then return nil end
    ent:SetPos(self:CellCenter(meta) + Vector(0, 0, 1))
    ent:SetAngles(Angle(0, 180, 0))
    ent:Spawn()
    ent:Activate()
    return ent
end

function MazeBuilder:_BuildProgressionEntities(graph)
    local progression = graph.Progression
    if not progression then
        self.BuildFailures = (self.BuildFailures or 0) + 1
        return
    end

    for _, gate in ipairs(progression.Gates or {}) do self:_Register(self:_SpawnProgressionGate(gate)) end
    for _, card in ipairs(progression.Keycards or {}) do self:_Register(self:_SpawnKeycard(card)) end
    self:_Register(self:_SpawnJailDoor(progression.JailEdge))
    self:_Register(self:_SpawnDeborah(progression.DeborahCell))
end

local previousBuild = MazeBuilder.Build
function MazeBuilder:Build(graph)
    local ok, report = previousBuild(self, graph)
    if not ok then return false, report end

    local before = #self.Entities
    self:_BuildProgressionEntities(graph)
    if self.BuildFailures > 0 then
        local failures = self.BuildFailures
        self:Cleanup()
        return false, "progression entity creation failed; total required-entity failures=" .. failures
    end

    report.progressionEntities = #self.Entities - before
    report.entityCount = #self.Entities
    report.progression = {
        gates = 3,
        keycards = 3,
        jailDoor = 1,
        deborah = 1
    }
    return true, report
end
