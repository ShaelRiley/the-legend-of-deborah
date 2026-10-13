ENT.Type = "anim"
ENT.Base = "base_anim"
ENT.PrintName = "Neil Release Button"
ENT.Spawnable = false
ENT.AdminOnly = false
ENT.RenderGroup = RENDERGROUP_BOTH
function ENT:SetupDataTables()
    self:NetworkVar("Vector",0,"PickupPosition")
    self:NetworkVar("Bool",0,"Released")
end
