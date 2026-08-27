ENT.Type = "anim"
ENT.Base = "base_anim"
ENT.PrintName = "LOD Staging Prop"
ENT.Spawnable = false
ENT.AdminOnly = false

ENT.KIND_GUIDE = 1
ENT.KIND_PORTAL = 2
ENT.KIND_WEAPON = 3

function ENT:SetupDataTables()
    self:NetworkVar("Int", 0, "StageKind")
    self:NetworkVar("String", 0, "StageLabel")
end
