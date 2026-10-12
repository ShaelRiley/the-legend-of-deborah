ENT.Type = "anim"
ENT.Base = "base_anim"
ENT.PrintName = "LOD Floor Map"
ENT.Spawnable = false

function ENT:SetupDataTables()
    self:NetworkVar("Int",0,"FloorIndex")
end
