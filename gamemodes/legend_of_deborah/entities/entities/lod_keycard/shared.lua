ENT.Type = "anim"
ENT.Base = "base_anim"
ENT.PrintName = "LOD Keycard"
ENT.Spawnable = false
ENT.AdminOnly = false

function ENT:SetupDataTables()
    self:NetworkVar("Int", 0, "CardIndex")
end
