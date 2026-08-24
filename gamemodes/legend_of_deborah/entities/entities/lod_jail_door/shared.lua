ENT.Type = "anim"
ENT.Base = "base_anim"
ENT.PrintName = "Deborah Jail Door"
ENT.Spawnable = false
ENT.AdminOnly = false

function ENT:SetupDataTables()
    self:NetworkVar("Int", 0, "DoorAxis")
    self:NetworkVar("Bool", 0, "Opened")
    self:NetworkVar("Float", 0, "OpenedAt")
end
