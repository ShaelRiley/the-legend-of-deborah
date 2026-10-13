ENT.Type = "anim"
ENT.Base = "base_anim"
ENT.PrintName = "LOD Keycard"
ENT.Spawnable = false
ENT.AdminOnly = false
ENT.RenderGroup = RENDERGROUP_BOTH

function ENT:SetupDataTables()
    self:NetworkVar("Int", 0, "CardIndex")
    self:NetworkVar("Vector", 0, "PickupPosition")
end

