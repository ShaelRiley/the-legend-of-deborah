ENT.Type = "anim"
ENT.Base = "base_anim"
ENT.PrintName = "LOD Jail Key"
ENT.Spawnable = false
ENT.AdminOnly = false

function ENT:SetupDataTables()
    self:NetworkVar("String", 0, "KeySource")
end
