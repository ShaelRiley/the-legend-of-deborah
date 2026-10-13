ENT.Type = "anim"
ENT.Base = "base_anim"
ENT.PrintName = "LOD Jail Key"
ENT.Spawnable = false
ENT.AdminOnly = false
ENT.RenderGroup = RENDERGROUP_BOTH

-- PickupPosition preserves the canonical touch anchor while the native model
-- pivot is seated on a separately owned low stock block.

function ENT:SetupDataTables()
    self:NetworkVar("String", 0, "KeySource")
    self:NetworkVar("Vector", 0, "PickupPosition")
end

