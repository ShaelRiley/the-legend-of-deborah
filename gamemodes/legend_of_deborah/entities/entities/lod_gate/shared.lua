ENT.Type = "anim"
ENT.Base = "base_anim"
ENT.PrintName = "LOD Security Gate"
ENT.Spawnable = false
ENT.AdminOnly = false

function ENT:SetupDataTables()
    self:NetworkVar("Int", 0, "GateIndex")
    self:NetworkVar("Int", 1, "GateAxis")
    self:NetworkVar("Bool", 0, "Opened")
    self:NetworkVar("Float", 0, "OpenedAt")
end
