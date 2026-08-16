ENT.Type = "anim"
ENT.Base = "base_anim"
ENT.PrintName = "LOD Static Box"
ENT.Spawnable = false
ENT.AdminOnly = false

function ENT:SetupDataTables()
    self:NetworkVar("Vector", 0, "BoxMins")
    self:NetworkVar("Vector", 1, "BoxMaxs")
    self:NetworkVar("Int", 0, "BoxKind")
end
